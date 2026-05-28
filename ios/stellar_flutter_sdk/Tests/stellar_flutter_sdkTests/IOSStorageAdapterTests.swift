//
//  IOSStorageAdapterTests.swift
//  stellar_flutter_sdkTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Run procedure: link via the example app's `RunnerTests` target so the
//  `Flutter` framework resolves at link time.
//

import Flutter
import Foundation
import Security
import XCTest
@testable import stellar_flutter_sdk

final class IOSStorageAdapterTests: XCTestCase {

    // ========================================================================
    // Setup / teardown
    // ========================================================================

    /// Credential IDs created during the current test, so `tearDown`
    /// can delete them deterministically.
    private var createdCredentialIds: [String] = []

    /// Adapter under test. Reinstantiated per test so the internal
    /// JSON encoder / decoder pair never carries state between cases.
    private var adapter: IOSStorageAdapter!

    override func setUp() {
        super.setUp()
        adapter = IOSStorageAdapter()
        createdCredentialIds = []
    }

    override func tearDown() {
        // Delete every credential the test created (best-effort) and
        // wipe the session entry so the next test starts from empty.
        for credentialId in createdCredentialIds {
            _ = invoke(method: "storage.delete", arguments: ["credentialId": credentialId])
        }
        _ = invoke(method: "storage.clearSession", arguments: nil)
        adapter = nil
        super.tearDown()
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    private func uniqueCredentialId(_ tag: String = "test") -> String {
        let id = "\(tag)_\(UUID().uuidString)"
        createdCredentialIds.append(id)
        return id
    }

    /// Issues a synchronous call into the adapter and returns the
    /// value passed to the `FlutterResult` callback. Hops onto the
    /// adapter's internal serial queue, so the wait timeout must
    /// be generous enough to cover Keychain round-trip latency.
    @discardableResult
    private func invoke(
        method: String,
        arguments: Any?,
        timeout: TimeInterval = 5.0
    ) -> Any? {
        let expectation = self.expectation(description: "FlutterResult for \(method)")
        var captured: Any?
        let call = FlutterMethodCall(methodName: method, arguments: arguments)
        adapter.handle(call: call) { value in
            captured = value
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        return captured
    }

    /// Writes raw bytes directly into the adapter's Keychain service
    /// for the supplied account name. Used by tests that need to
    /// stage corrupt payloads the adapter would never produce.
    private func keychainWriteRaw(account: String, data: Data) {
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: IOSStorageAdapter.defaultServiceName,
            kSecAttrAccount: account,
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]
        // Try update first, fall back to add. Mirrors the adapter's
        // own upsert logic so the resulting Keychain item has
        // identical attributes.
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecSuccess { return }
        var addQuery = baseQuery
        for (key, value) in attributes {
            addQuery[key] = value
        }
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func sampleCredential(id: String, contractId: String? = nil) -> [String: Any?] {
        return [
            "credentialId": id,
            "publicKey": [0x04, 0x10, 0x20] as [UInt8],
            "contractId": contractId as Any?,
            "createdAt": NSNumber(value: Int64(1_700_000_000_000)),
        ]
    }

    private func sampleSession(expiresAt: Int64) -> [String: Any?] {
        return [
            "credentialId": "cred_\(UUID().uuidString)",
            "contractId": "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM",
            "connectedAt": NSNumber(value: Int64(Date().timeIntervalSince1970 * 1000.0)),
            "expiresAt": NSNumber(value: expiresAt),
        ]
    }

    // ========================================================================
    // Credential CRUD
    // ========================================================================

    func test_save_then_get_round_trip() {
        let credentialId = uniqueCredentialId("round_trip")
        let credential = sampleCredential(id: credentialId, contractId: "C123")

        let saveResult = invoke(method: "storage.save", arguments: ["credential": credential])
        XCTAssertNil(saveResult, "Save should return nil on success, got: \(String(describing: saveResult))")

        let getResult = invoke(method: "storage.get", arguments: ["credentialId": credentialId])
        let map = getResult as? [String: Any?]
        XCTAssertNotNil(map, "Expected credential map, got: \(String(describing: getResult))")
        XCTAssertEqual(map?["credentialId"] as? String, credentialId)
        XCTAssertEqual(map?["contractId"] as? String, "C123")
    }

    func test_get_nonexistent_returns_nil() {
        let credentialId = uniqueCredentialId("missing")
        let result = invoke(method: "storage.get", arguments: ["credentialId": credentialId])
        XCTAssertNil(result, "Expected nil for missing credential, got: \(String(describing: result))")
    }

    func test_delete_nonexistent_does_not_throw() {
        let credentialId = uniqueCredentialId("missing_delete")
        let result = invoke(method: "storage.delete", arguments: ["credentialId": credentialId])
        XCTAssertNil(result, "Delete of nonexistent credential should return nil, got: \(String(describing: result))")
    }

    func test_save_existing_credential_overwrites_and_does_not_duplicate_index() {
        let credentialId = uniqueCredentialId("overwrite")

        let first = sampleCredential(id: credentialId, contractId: "C_FIRST")
        XCTAssertNil(invoke(method: "storage.save", arguments: ["credential": first]))

        let second = sampleCredential(id: credentialId, contractId: "C_SECOND")
        XCTAssertNil(invoke(method: "storage.save", arguments: ["credential": second]))

        // getByContract for C_FIRST must return zero results — the
        // overwrite replaced the contract id.
        let firstMatches = invoke(
            method: "storage.getByContract",
            arguments: ["contractId": "C_FIRST"]
        ) as? [[String: Any?]]
        XCTAssertEqual(firstMatches?.contains(where: { $0["credentialId"] as? String == credentialId }), false)

        // getByContract for C_SECOND must return exactly one match
        // for this credential id; if the index were duplicated we'd
        // see it twice.
        let secondMatches = invoke(
            method: "storage.getByContract",
            arguments: ["contractId": "C_SECOND"]
        ) as? [[String: Any?]]
        let thisCred = secondMatches?.filter { $0["credentialId"] as? String == credentialId }
        XCTAssertEqual(thisCred?.count, 1, "Expected exactly one index entry for the overwritten credential")
    }

    func test_corrupted_payload_returns_nil_on_get() {
        let credentialId = uniqueCredentialId("corrupt_get")
        // Write garbage bytes that will never decode as JSON.
        keychainWriteRaw(
            account: "cred_" + credentialId,
            data: Data([0xff, 0xfe, 0xfd, 0xfc])
        )
        let result = invoke(method: "storage.get", arguments: ["credentialId": credentialId])
        XCTAssertNil(result, "Get of corrupted entry must return nil, got: \(String(describing: result))")
    }

    func test_corrupted_payload_throws_storage_read_failed_on_update() {
        let credentialId = uniqueCredentialId("corrupt_update")
        keychainWriteRaw(
            account: "cred_" + credentialId,
            data: Data([0x00, 0x01, 0x02])
        )
        let result = invoke(
            method: "storage.update",
            arguments: [
                "credentialId": credentialId,
                "updates": ["contractId": "C_NEW"] as [String: Any?],
            ]
        )
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "STORAGE_READ_FAILED")
        XCTAssertTrue(
            error?.message?.contains("Corrupted") == true,
            "Expected message to mention corruption, got: \(String(describing: error?.message))"
        )
    }

    // ========================================================================
    // clear
    // ========================================================================

    func test_clear_removes_all_credentials_and_session() {
        let credentialId = uniqueCredentialId("clear_target")
        XCTAssertNil(invoke(
            method: "storage.save",
            arguments: ["credential": sampleCredential(id: credentialId)]
        ))
        XCTAssertNil(invoke(
            method: "storage.saveSession",
            arguments: ["session": sampleSession(expiresAt: Int64.max)]
        ))

        XCTAssertNil(invoke(method: "storage.clear", arguments: nil))

        XCTAssertNil(invoke(method: "storage.get", arguments: ["credentialId": credentialId]))
        XCTAssertNil(invoke(method: "storage.getSession", arguments: nil))
    }

    // ========================================================================
    // Session
    // ========================================================================

    func test_save_session_then_get_session_round_trip() {
        let session = sampleSession(expiresAt: Int64.max)
        XCTAssertNil(invoke(method: "storage.saveSession", arguments: ["session": session]))

        let result = invoke(method: "storage.getSession", arguments: nil) as? [String: Any?]
        XCTAssertNotNil(result, "Expected session map, got: \(String(describing: result))")
        XCTAssertEqual(result?["credentialId"] as? String, session["credentialId"] as? String)
        XCTAssertEqual(result?["contractId"] as? String, session["contractId"] as? String)
    }

    func test_get_session_returns_nil_when_expired() {
        // ExpiresAt one second ago.
        let expired = Int64(Date().timeIntervalSince1970 * 1000.0) - 1000
        XCTAssertNil(invoke(
            method: "storage.saveSession",
            arguments: ["session": sampleSession(expiresAt: expired)]
        ))
        let result = invoke(method: "storage.getSession", arguments: nil)
        XCTAssertNil(result, "Expired session must auto-clear and return nil, got: \(String(describing: result))")

        // Calling getSession a second time must also return nil; the
        // first call should have purged the entry.
        let second = invoke(method: "storage.getSession", arguments: nil)
        XCTAssertNil(second)
    }

    func test_clear_session_removes_session_only_not_credentials() {
        let credentialId = uniqueCredentialId("preserved_after_session_clear")
        XCTAssertNil(invoke(
            method: "storage.save",
            arguments: ["credential": sampleCredential(id: credentialId)]
        ))
        XCTAssertNil(invoke(
            method: "storage.saveSession",
            arguments: ["session": sampleSession(expiresAt: Int64.max)]
        ))

        XCTAssertNil(invoke(method: "storage.clearSession", arguments: nil))

        XCTAssertNil(invoke(method: "storage.getSession", arguments: nil))
        let stillThere = invoke(method: "storage.get", arguments: ["credentialId": credentialId])
        XCTAssertNotNil(stillThere, "clearSession must not delete credential entries")
    }

    // ========================================================================
    // dispatch: unknown methods
    // ========================================================================

    func test_unknown_method_returns_method_not_implemented() {
        let result = invoke(method: "storage.no_such_method", arguments: nil)
        XCTAssertTrue(
            (result as AnyObject) === FlutterMethodNotImplemented as AnyObject,
            "Expected FlutterMethodNotImplemented, got: \(String(describing: result))"
        )
    }
}
