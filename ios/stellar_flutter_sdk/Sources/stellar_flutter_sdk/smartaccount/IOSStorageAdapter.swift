//
//  IOSStorageAdapter.swift
//  stellar_flutter_sdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Flutter
import Foundation
import Security

// ============================================================================
// IOSStorageAdapter
// ============================================================================

/// Method-channel handler for the Dart `PlatformStorageAdapter` bridge on
/// iOS and macOS.
///
/// Persists serialised credential and session payloads as
/// `kSecClassGenericPassword` items in the platform Keychain, keyed by an
/// account name composed of a fixed prefix and the credential identifier.
///
/// Wire contract (matches the Dart `PlatformStorageAdapter` bridge):
///
/// - Channel: `com.soneso.stellar_flutter_sdk/smartaccount/storage`
/// - Methods (10): `storage.save`, `storage.get`, `storage.getByContract`,
///   `storage.getAll`, `storage.delete`, `storage.update`, `storage.clear`,
///   `storage.saveSession`, `storage.getSession`, `storage.clearSession`.
///
/// Error contract — `FlutterError.code` strings:
/// - `STORAGE_READ_FAILED`
/// - `STORAGE_WRITE_FAILED`
/// - `CREDENTIAL_NOT_FOUND` (only emitted by `storage.update`)
///
/// All entries are written with `kSecAttrAccessibleAfterFirstUnlock` so they
/// survive app restarts but become inaccessible until the device is unlocked
/// after a reboot. The persisted material is public-key data; biometric
/// `SecAccessControl` flags are intentionally not configured.
///
/// ### Asymmetric corruption handling
///
/// - `get` returns `null` if the stored payload cannot be decoded; the
///   corruption is treated as "entry absent".
/// - `getAll` skips corrupted entries and returns the valid subset.
/// - `update` surfaces a `STORAGE_READ_FAILED` `FlutterError` when the
///   entry is corrupt because the read-modify-write sequence cannot proceed
///   without a known prior state.
@objc public final class IOSStorageAdapter: NSObject {

    // ========================================================================
    // Constants
    // ========================================================================

    /// Default `kSecAttrService` value used for every Keychain query.
    public static let defaultServiceName: String = "com.soneso.stellar.smartaccount"

    private static let credentialKeyPrefix: String = "cred_"
    private static let credentialIndexKey: String = "credential_index"
    private static let sessionKey: String = "session_current"

    // ========================================================================
    // State
    // ========================================================================

    private let serviceName: String
    private let queue: DispatchQueue
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public override init() {
        self.serviceName = IOSStorageAdapter.defaultServiceName
        self.queue = DispatchQueue(
            label: "com.soneso.stellar_flutter_sdk.smartaccount.storage",
            qos: .userInitiated
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    // ========================================================================
    // Method-channel dispatch
    // ========================================================================

    public func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Dispatch to a serial queue so concurrent calls observe a strict
        // FIFO order matching the Dart-side method-channel guarantee.
        queue.async { [weak self] in
            guard let self else {
                result(FlutterError(
                    code: "STORAGE_READ_FAILED",
                    message: "Storage handler released",
                    details: nil
                ))
                return
            }
            self.dispatch(call: call, result: result)
        }
    }

    private func dispatch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any?]
        switch call.method {
        case "storage.save":
            handleSave(arguments: arguments, result: result)
        case "storage.get":
            handleGet(arguments: arguments, result: result)
        case "storage.getByContract":
            handleGetByContract(arguments: arguments, result: result)
        case "storage.getAll":
            handleGetAll(result: result)
        case "storage.delete":
            handleDelete(arguments: arguments, result: result)
        case "storage.update":
            handleUpdate(arguments: arguments, result: result)
        case "storage.clear":
            handleClear(result: result)
        case "storage.saveSession":
            handleSaveSession(arguments: arguments, result: result)
        case "storage.getSession":
            handleGetSession(result: result)
        case "storage.clearSession":
            handleClearSession(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ========================================================================
    // Credential operations
    // ========================================================================

    private func handleSave(
        arguments: [String: Any?]?,
        result: @escaping FlutterResult
    ) {
        guard let map = arguments?["credential"] as? [String: Any?] else {
            result(writeError(key: "credential", reason: "Missing 'credential' argument"))
            return
        }
        guard
            let credentialId = map["credentialId"] as? String,
            !credentialId.isEmpty
        else {
            result(writeError(key: "credential", reason: "Missing 'credentialId'"))
            return
        }

        do {
            let payload = try encodeJsonMap(map)
            try keychainUpsert(
                account: Self.credentialKeyPrefix + credentialId,
                data: payload
            )

            // Maintain a credential-id index so `getAll` and `getByContract`
            // can enumerate without relying on `kSecMatchLimitAll`, which has
            // platform-dependent quirks for `kSecAttrService`-scoped queries.
            var index = (try? readIndex()) ?? CredentialIndex(ids: [])
            if !index.ids.contains(credentialId) {
                index = CredentialIndex(ids: index.ids + [credentialId])
                try writeIndex(index)
            }
            result(nil)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(writeError(key: "credential:\(credentialId)", reason: error.localizedDescription))
        }
    }

    private func handleGet(
        arguments: [String: Any?]?,
        result: @escaping FlutterResult
    ) {
        guard let credentialId = arguments?["credentialId"] as? String else {
            result(readError(key: "credential", reason: "Missing 'credentialId'"))
            return
        }
        do {
            guard let bytes = try keychainRead(
                account: Self.credentialKeyPrefix + credentialId
            ) else {
                result(nil)
                return
            }
            guard let map = try? decodeJsonMap(bytes) else {
                // Corrupt / undecodable entries surface as "absent" to the
                // bridge; the asymmetry with `update` is documented in the
                // Dart `PlatformStorageAdapter` dartdoc.
                result(nil)
                return
            }
            result(map)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(readError(
                key: "credential:\(credentialId)",
                reason: error.localizedDescription
            ))
        }
    }

    private func handleGetByContract(
        arguments: [String: Any?]?,
        result: @escaping FlutterResult
    ) {
        guard let contractId = arguments?["contractId"] as? String else {
            result(readError(key: "credentials:contract", reason: "Missing 'contractId'"))
            return
        }
        do {
            let index = try readIndex()
            var matches: [[String: Any?]] = []
            for credentialId in index.ids {
                if
                    let bytes = try keychainRead(
                        account: Self.credentialKeyPrefix + credentialId
                    ),
                    let map = try? decodeJsonMap(bytes),
                    map["contractId"] as? String == contractId
                {
                    matches.append(map)
                }
            }
            result(matches)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(readError(
                key: "credentials:contract:\(contractId)",
                reason: error.localizedDescription
            ))
        }
    }

    private func handleGetAll(result: @escaping FlutterResult) {
        do {
            let index = try readIndex()
            var entries: [[String: Any?]] = []
            for credentialId in index.ids {
                if
                    let bytes = try keychainRead(
                        account: Self.credentialKeyPrefix + credentialId
                    ),
                    let map = try? decodeJsonMap(bytes)
                {
                    entries.append(map)
                }
            }
            result(entries)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(readError(
                key: "credentials:all",
                reason: error.localizedDescription
            ))
        }
    }

    private func handleDelete(
        arguments: [String: Any?]?,
        result: @escaping FlutterResult
    ) {
        guard let credentialId = arguments?["credentialId"] as? String else {
            result(writeError(key: "credential", reason: "Missing 'credentialId'"))
            return
        }
        do {
            try keychainDelete(account: Self.credentialKeyPrefix + credentialId)
            // Best-effort index update; absence in the index is non-fatal.
            if var index = try? readIndex() {
                if let removeAt = index.ids.firstIndex(of: credentialId) {
                    var ids = index.ids
                    ids.remove(at: removeAt)
                    index = CredentialIndex(ids: ids)
                    try writeIndex(index)
                }
            }
            result(nil)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(writeError(
                key: "credential:\(credentialId)",
                reason: error.localizedDescription
            ))
        }
    }

    private func handleUpdate(
        arguments: [String: Any?]?,
        result: @escaping FlutterResult
    ) {
        guard let credentialId = arguments?["credentialId"] as? String else {
            result(writeError(key: "credential", reason: "Missing 'credentialId'"))
            return
        }
        guard let updates = arguments?["updates"] as? [String: Any?] else {
            result(writeError(
                key: "credential:\(credentialId)",
                reason: "Missing 'updates' argument"
            ))
            return
        }

        do {
            guard let existingBytes = try keychainRead(
                account: Self.credentialKeyPrefix + credentialId
            ) else {
                result(notFoundError(credentialId: credentialId))
                return
            }
            guard var existing = try? decodeJsonMap(existingBytes) else {
                // Cannot proceed safely; surface the corruption rather than
                // overwriting an undecodable record.
                result(readError(
                    key: "credential:\(credentialId)",
                    reason: "Corrupted credential cannot be updated"
                ))
                return
            }

            for (key, value) in updates {
                if let v = value {
                    existing[key] = v
                }
            }

            let payload = try encodeJsonMap(existing)
            try keychainUpsert(
                account: Self.credentialKeyPrefix + credentialId,
                data: payload
            )
            result(nil)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(writeError(
                key: "credential:\(credentialId)",
                reason: error.localizedDescription
            ))
        }
    }

    private func handleClear(result: @escaping FlutterResult) {
        do {
            // Iterate the index so we delete only entries this adapter
            // manages, leaving unrelated Keychain items in the same service
            // untouched.
            if let index = try? readIndex() {
                for credentialId in index.ids {
                    try? keychainDelete(account: Self.credentialKeyPrefix + credentialId)
                }
            }
            try keychainDelete(account: Self.credentialIndexKey)
            try keychainDelete(account: Self.sessionKey)
            result(nil)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(writeError(key: "clear:all", reason: error.localizedDescription))
        }
    }

    // ========================================================================
    // Session operations
    // ========================================================================

    private func handleSaveSession(
        arguments: [String: Any?]?,
        result: @escaping FlutterResult
    ) {
        guard let map = arguments?["session"] as? [String: Any?] else {
            result(writeError(key: "session", reason: "Missing 'session' argument"))
            return
        }
        do {
            let payload = try encodeJsonMap(map)
            try keychainUpsert(account: Self.sessionKey, data: payload)
            result(nil)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(writeError(key: "session", reason: error.localizedDescription))
        }
    }

    private func handleGetSession(result: @escaping FlutterResult) {
        do {
            guard let bytes = try keychainRead(account: Self.sessionKey) else {
                result(nil)
                return
            }
            guard let map = try? decodeJsonMap(bytes) else {
                result(nil)
                return
            }
            // Auto-clear expired sessions so callers always observe "valid
            // session or none". Matches the contract documented on the
            // `StorageAdapter` interface and the Dart `InMemoryStorageAdapter`.
            if let expiresAt = numericValue(map["expiresAt"]) {
                let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)
                if nowMs >= expiresAt {
                    try? keychainDelete(account: Self.sessionKey)
                    result(nil)
                    return
                }
            }
            result(map)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(readError(key: "session", reason: error.localizedDescription))
        }
    }

    private func handleClearSession(result: @escaping FlutterResult) {
        do {
            try keychainDelete(account: Self.sessionKey)
            result(nil)
        } catch let storageError as StorageError {
            result(storageError.toFlutterError())
        } catch {
            result(writeError(key: "session", reason: error.localizedDescription))
        }
    }

    // ========================================================================
    // Index helpers
    // ========================================================================

    private func readIndex() throws -> CredentialIndex {
        guard let bytes = try keychainRead(account: Self.credentialIndexKey) else {
            return CredentialIndex(ids: [])
        }
        do {
            let index = try decoder.decode(CredentialIndex.self, from: bytes)
            return index
        } catch {
            // Corrupt index is treated as empty; subsequent writes will
            // rebuild the index from the saves that follow.
            return CredentialIndex(ids: [])
        }
    }

    private func writeIndex(_ index: CredentialIndex) throws {
        let bytes = try encoder.encode(index)
        try keychainUpsert(account: Self.credentialIndexKey, data: bytes)
    }

    // ========================================================================
    // Keychain primitives
    // ========================================================================

    private func keychainUpsert(account: String, data: Data) throws {
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: account,
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecSuccess { return }
        if updateStatus == errSecItemNotFound {
            var addQuery = baseQuery
            for (key, value) in attributes {
                addQuery[key] = value
            }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus == errSecSuccess { return }
            throw StorageError.write(
                key: account,
                reason: "SecItemAdd OSStatus: \(addStatus)"
            )
        }
        throw StorageError.write(
            key: account,
            reason: "SecItemUpdate OSStatus: \(updateStatus)"
        )
    }

    private func keychainRead(account: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: account,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess {
            return item as? Data
        }
        if status == errSecItemNotFound {
            return nil
        }
        throw StorageError.read(
            key: account,
            reason: "SecItemCopyMatching OSStatus: \(status)"
        )
    }

    private func keychainDelete(account: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { return }
        throw StorageError.write(
            key: account,
            reason: "SecItemDelete OSStatus: \(status)"
        )
    }

    // ========================================================================
    // JSON helpers
    // ========================================================================

    private func encodeJsonMap(_ map: [String: Any?]) throws -> Data {
        let nonNullMap = map.compactMapValues { $0 }
        do {
            return try JSONSerialization.data(
                withJSONObject: nonNullMap,
                options: [.sortedKeys]
            )
        } catch {
            throw StorageError.write(
                key: "json",
                reason: "JSON encode failed: \(error.localizedDescription)"
            )
        }
    }

    private func decodeJsonMap(_ data: Data) throws -> [String: Any?] {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let map = object as? [String: Any?] else {
            throw StorageError.read(
                key: "json",
                reason: "Decoded JSON is not an object"
            )
        }
        return map
    }

    private func numericValue(_ value: Any?) -> Int64? {
        if let n = value as? NSNumber { return n.int64Value }
        if let i = value as? Int { return Int64(i) }
        if let i = value as? Int64 { return i }
        if let s = value as? String { return Int64(s) }
        return nil
    }

    // ========================================================================
    // FlutterError factories
    // ========================================================================

    private func readError(key: String, reason: String) -> FlutterError {
        FlutterError(
            code: "STORAGE_READ_FAILED",
            message: "Storage read failed for key: \(key) (\(reason))",
            details: nil
        )
    }

    private func writeError(key: String, reason: String) -> FlutterError {
        FlutterError(
            code: "STORAGE_WRITE_FAILED",
            message: "Storage write failed for key: \(key) (\(reason))",
            details: nil
        )
    }

    private func notFoundError(credentialId: String) -> FlutterError {
        FlutterError(
            code: "CREDENTIAL_NOT_FOUND",
            message: "Credential not found: \(credentialId)",
            details: nil
        )
    }
}

// ============================================================================
// CredentialIndex
// ============================================================================

/// JSON-encoded list of credential IDs maintained alongside the
/// per-credential Keychain entries to support `getAll` / `getByContract`
/// enumeration.
private struct CredentialIndex: Codable {
    let ids: [String]
}

// ============================================================================
// StorageError
// ============================================================================

private enum StorageError: Error {
    case read(key: String, reason: String)
    case write(key: String, reason: String)

    func toFlutterError() -> FlutterError {
        switch self {
        case .read(let key, let reason):
            return FlutterError(
                code: "STORAGE_READ_FAILED",
                message: "Storage read failed for key: \(key) (\(reason))",
                details: nil
            )
        case .write(let key, let reason):
            return FlutterError(
                code: "STORAGE_WRITE_FAILED",
                message: "Storage write failed for key: \(key) (\(reason))",
                details: nil
            )
        }
    }
}
