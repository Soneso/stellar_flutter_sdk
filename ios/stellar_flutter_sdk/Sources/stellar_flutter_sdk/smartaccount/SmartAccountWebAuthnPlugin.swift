//
//  SmartAccountWebAuthnPlugin.swift
//  stellar_flutter_sdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import AuthenticationServices
import Flutter
import Foundation
import UIKit

// SmartAccountWebAuthnPlugin

/// Method-channel handler that wraps Apple's `AuthenticationServices`
/// `ASAuthorizationController` for WebAuthn passkey registration and
/// assertion.
///
/// Wire contract (matches the Dart `PlatformWebAuthnProvider` bridge):
///
/// - Channel: `com.soneso.stellar_flutter_sdk/smartaccount/webauthn`
/// - Methods: `register`, `authenticate`
/// - Argument types: byte arrays are `FlutterStandardTypedData` (Dart
///   `Uint8List`); strings, numbers, and booleans use the standard Flutter
///   codec mapping.
///
/// Error contract — `FlutterError.code` strings:
/// - `WEBAUTHN_CANCELLED` (4004 in the Dart numeric domain)
/// - `WEBAUTHN_REGISTRATION_FAILED` (4001)
/// - `WEBAUTHN_AUTHENTICATION_FAILED` (4002)
/// - `WEBAUTHN_NOT_SUPPORTED` (4003)
///
/// Required iOS / macOS API levels: iOS 16.0+ and macOS 13.0+. On lower OS
/// versions every call returns a `WEBAUTHN_NOT_SUPPORTED` `FlutterError`.
///
/// Required platform configuration: the consumer app must declare an
/// `Associated Domains` entitlement entry such as
/// `webcredentials:example.com`, and serve a matching Apple App Site
/// Association file at
/// `https://example.com/.well-known/apple-app-site-association`. Without
/// that linkage, registration fails on-device with a system error that is
/// surfaced as `WEBAUTHN_REGISTRATION_FAILED` (code 4001).
@objc public final class SmartAccountWebAuthnPlugin: NSObject {

    // State

    /// Strong reference to the active authorization delegate.
    ///
    /// `ASAuthorizationController` holds a weak reference to its delegate,
    /// so the delegate must be retained by this handler for the duration of
    /// each authorization operation. Cleared in the delegate callback after
    /// the result has been forwarded to Flutter.
    private var activeDelegate: AuthorizationDelegate?

    /// Strong reference to the active controller, kept alive for the
    /// duration of an authorization request. The system needs it to display
    /// the system passkey sheet anchored to the foreground window.
    private var activeController: ASAuthorizationController?

    /// Window provider used to anchor the system passkey sheet on macOS.
    /// On iOS the system handles anchoring automatically.
    private let presentationContextProvider: AuthorizationPresentationProvider

    public override init() {
        self.presentationContextProvider = AuthorizationPresentationProvider()
        super.init()
    }

    // Method-channel dispatch

    public func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "register":
            handleRegister(call: call, result: result)
        case "authenticate":
            handleAuthenticate(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // register

    private func handleRegister(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            result(notSupportedError(message: "WebAuthn requires iOS 16.0+ or macOS 13.0+"))
            return
        }

        guard let args = call.arguments as? [String: Any?] else {
            result(registrationError(message: "Invalid arguments: expected map"))
            return
        }

        guard
            let rpId = args["rpId"] as? String,
            !rpId.isEmpty
        else {
            result(registrationError(message: "Missing required argument: rpId"))
            return
        }
        guard
            let rpName = args["rpName"] as? String,
            !rpName.isEmpty
        else {
            result(registrationError(message: "Missing required argument: rpName"))
            return
        }
        guard let challenge = bytes(args["challenge"]) else {
            result(registrationError(message: "Missing required argument: challenge"))
            return
        }
        guard let userId = bytes(args["userId"]) else {
            result(registrationError(message: "Missing required argument: userId"))
            return
        }
        guard let userName = args["userName"] as? String else {
            result(registrationError(message: "Missing required argument: userName"))
            return
        }
        let timeout = (args["timeout"] as? NSNumber)?.doubleValue ?? 60_000.0

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: userName,
            userID: userId
        )
        // userVerificationPreference and attestationPreference are intentionally
        // left at their system defaults on registration. The on-chain OZ WebAuthn
        // verifier inspects the UV bit only at signature verification time, so
        // forcing .required here is unnecessary. Requesting .direct attestation
        // is also unnecessary (no attestation-statement verification happens in
        // the SDK) and would break iOS Simulator registration, which cannot
        // produce attestation statements.

        performAuthorizationRequest(
            request: request,
            isRegistration: true,
            timeout: timeout,
            rpId: rpId,
            result: result,
            onSuccess: { [weak self] authorization in
                self?.handleRegistrationSuccess(
                    rpName: rpName,
                    authorization: authorization,
                    result: result
                )
            }
        )
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func handleRegistrationSuccess(
        rpName: String,
        authorization: ASAuthorization,
        result: @escaping FlutterResult
    ) {
        guard let registration =
            authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration
        else {
            result(registrationError(
                message: "Unexpected credential type: \(type(of: authorization.credential))"
            ))
            return
        }

        let credentialId = registration.credentialID
        guard let attestationObject = registration.rawAttestationObject else {
            result(registrationError(message: "Attestation object is null"))
            return
        }

        let attestationBytes = [UInt8](attestationObject)
        guard let publicKey = WebAuthnAttestationParser.extractUncompressedPublicKey(
            fromAttestation: attestationBytes
        ) else {
            result(registrationError(
                message: "Failed to extract public key from attestation"
            ))
            return
        }

        let authenticatorData = WebAuthnAttestationParser.extractAuthenticatorData(
            fromAttestation: attestationBytes
        )
        let flags = WebAuthnAttestationParser.parseAuthenticatorFlags(authenticatorData)

        var resultMap: [String: Any?] = [
            "credentialId": FlutterStandardTypedData(bytes: credentialId),
            "publicKey": FlutterStandardTypedData(bytes: Data(publicKey)),
            "attestationObject": FlutterStandardTypedData(bytes: attestationObject),
            "transports": ["internal"],
            "deviceType": flags.deviceType as Any?,
            "backedUp": flags.backedUp as Any?,
        ]
        // Strip nil entries; Dart treats absent keys and explicit null
        // identically for the optional metadata fields.
        resultMap = resultMap.filter { _, value in value != nil }
        result(resultMap)
    }

    // authenticate

    private func handleAuthenticate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            result(notSupportedError(message: "WebAuthn requires iOS 16.0+ or macOS 13.0+"))
            return
        }

        guard let args = call.arguments as? [String: Any?] else {
            result(authenticationError(message: "Invalid arguments: expected map"))
            return
        }

        guard
            let rpId = args["rpId"] as? String,
            !rpId.isEmpty
        else {
            result(authenticationError(message: "Missing required argument: rpId"))
            return
        }
        guard let challenge = bytes(args["challenge"]) else {
            result(authenticationError(message: "Missing required argument: challenge"))
            return
        }
        let timeout = (args["timeout"] as? NSNumber)?.doubleValue ?? 60_000.0

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        request.userVerificationPreference = .required

        if let allowList = args["allowCredentials"] as? [Any?] {
            var descriptors: [ASAuthorizationPlatformPublicKeyCredentialDescriptor] = []
            for entry in allowList {
                guard let map = entry as? [String: Any?] else { continue }
                guard let id = bytes(map["id"]) else { continue }
                descriptors.append(
                    ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: id)
                )
            }
            if !descriptors.isEmpty {
                request.allowedCredentials = descriptors
            }
        }

        performAuthorizationRequest(
            request: request,
            isRegistration: false,
            timeout: timeout,
            rpId: rpId,
            result: result,
            onSuccess: { [weak self] authorization in
                self?.handleAuthenticationSuccess(
                    authorization: authorization,
                    result: result
                )
            }
        )
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func handleAuthenticationSuccess(
        authorization: ASAuthorization,
        result: @escaping FlutterResult
    ) {
        guard let assertion =
            authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion
        else {
            result(authenticationError(
                message: "Unexpected credential type: \(type(of: authorization.credential))"
            ))
            return
        }

        guard let authenticatorData = assertion.rawAuthenticatorData else {
            result(authenticationError(message: "Authenticator data is null"))
            return
        }
        guard let signature = assertion.signature else {
            result(authenticationError(message: "Signature is null"))
            return
        }

        let resultMap: [String: Any] = [
            "credentialId": FlutterStandardTypedData(bytes: assertion.credentialID),
            "authenticatorData": FlutterStandardTypedData(bytes: authenticatorData),
            "clientDataJSON": FlutterStandardTypedData(bytes: assertion.rawClientDataJSON),
            "signature": FlutterStandardTypedData(bytes: signature),
        ]
        result(resultMap)
    }

    // Authorization-controller bridge

    @available(iOS 16.0, macOS 13.0, *)
    private func performAuthorizationRequest(
        request: ASAuthorizationRequest,
        isRegistration: Bool,
        timeout: Double,
        rpId: String,
        result: @escaping FlutterResult,
        onSuccess: @escaping (ASAuthorization) -> Void
    ) {
        var hasCompleted = false
        let completionLock = NSLock()
        let cleanup: () -> Void = { [weak self] in
            self?.activeDelegate = nil
            self?.activeController = nil
        }

        let delegate = AuthorizationDelegate(
            onSuccess: { authorization in
                completionLock.lock()
                let alreadyDone = hasCompleted
                hasCompleted = true
                completionLock.unlock()
                if alreadyDone { return }
                cleanup()
                onSuccess(authorization)
            },
            onError: { [weak self] error in
                completionLock.lock()
                let alreadyDone = hasCompleted
                hasCompleted = true
                completionLock.unlock()
                if alreadyDone { return }
                cleanup()
                guard let self else {
                    // Plugin was deallocated before the delegate fired; still
                    // surface a Flutter error to unblock the awaiting caller.
                    result(FlutterError(
                        code: "WEBAUTHN_AUTHENTICATION_FAILED",
                        message: "Plugin deallocated before WebAuthn callback completed",
                        details: nil
                    ))
                    return
                }
                result(self.mapAuthorizationError(
                    error: error,
                    isRegistration: isRegistration,
                    rpId: rpId
                ))
            }
        )
        activeDelegate = delegate

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.presentationContextProvider = presentationContextProvider
        activeController = controller

        // Dispatch to the main thread because `ASAuthorizationController`
        // requires presentation on the main UI thread.
        let dispatchBlock: () -> Void = {
            controller.performRequests()
        }
        if Thread.isMainThread {
            dispatchBlock()
        } else {
            DispatchQueue.main.async(execute: dispatchBlock)
        }

        // Schedule a timeout fallback. The system itself enforces a fairly
        // generous internal timeout, but consumers expect the configurable
        // value to apply, so we surface a synthetic error if the delegate
        // has not been called by then.
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout / 1000.0) { [weak self] in
            completionLock.lock()
            let alreadyDone = hasCompleted
            hasCompleted = true
            completionLock.unlock()
            if alreadyDone { return }
            cleanup()
            let message = "WebAuthn operation timed out after \(Int(timeout))ms"
            guard let self else {
                // Plugin was deallocated before the timeout fired; surface a
                // generic Flutter error so the awaiting caller is not left
                // hanging.
                result(FlutterError(
                    code: isRegistration
                        ? "WEBAUTHN_REGISTRATION_FAILED"
                        : "WEBAUTHN_AUTHENTICATION_FAILED",
                    message: message,
                    details: nil
                ))
                return
            }
            if isRegistration {
                result(self.registrationError(message: message))
            } else {
                result(self.authenticationError(message: message))
            }
        }
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func mapAuthorizationError(
        error: Error,
        isRegistration: Bool,
        rpId: String
    ) -> FlutterError {
        let nsError = error as NSError
        let domain = nsError.domain
        let code = nsError.code
        let description = nsError.localizedDescription

        // ASAuthorizationError codes (ASAuthorizationErrorDomain). Numeric
        // values match the documented `ASAuthorizationError.Code` cases:
        // 1000 unknown, 1001 canceled, 1002 invalidResponse,
        // 1003 notHandled, 1004 failed, 1005 notInteractive (macOS).
        if domain == ASAuthorizationError.errorDomain {
            switch code {
            case ASAuthorizationError.canceled.rawValue:
                return cancelledError(message: "User cancelled WebAuthn operation")
            case ASAuthorizationError.invalidResponse.rawValue:
                let message = "Invalid response from authenticator: \(description)"
                return isRegistration
                    ? registrationError(message: message)
                    : authenticationError(message: message)
            case ASAuthorizationError.notHandled.rawValue:
                return notSupportedError(message: "Passkey operation not handled: \(description)")
            case ASAuthorizationError.failed.rawValue:
                let message = "Authenticator operation failed: \(description)"
                return isRegistration
                    ? registrationError(message: message)
                    : authenticationError(message: message)
            default:
                let message = "Authorization error (code \(code)): \(description)"
                return isRegistration
                    ? registrationError(message: message)
                    : authenticationError(message: message)
            }
        }

        let message =
            "Unexpected error in domain \(domain) (code \(code)): \(description)"
        return isRegistration
            ? registrationError(message: message)
            : authenticationError(message: message)
    }

    // Argument helpers

    private func bytes(_ value: Any?) -> Data? {
        if let typed = value as? FlutterStandardTypedData {
            return typed.data
        }
        if let data = value as? Data {
            return data
        }
        if let array = value as? [UInt8] {
            return Data(array)
        }
        if let array = value as? [NSNumber] {
            return Data(array.map { $0.uint8Value })
        }
        return nil
    }

    // FlutterError factories

    private func registrationError(message: String) -> FlutterError {
        FlutterError(code: "WEBAUTHN_REGISTRATION_FAILED", message: message, details: nil)
    }

    private func authenticationError(message: String) -> FlutterError {
        FlutterError(code: "WEBAUTHN_AUTHENTICATION_FAILED", message: message, details: nil)
    }

    private func cancelledError(message: String) -> FlutterError {
        FlutterError(code: "WEBAUTHN_CANCELLED", message: message, details: nil)
    }

    private func notSupportedError(message: String) -> FlutterError {
        FlutterError(code: "WEBAUTHN_NOT_SUPPORTED", message: message, details: nil)
    }
}

// AuthorizationDelegate

/// Internal delegate that bridges `ASAuthorizationController`'s callback
/// API to closure-based success / error continuations.
@available(iOS 16.0, macOS 13.0, *)
private final class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {

    private let onSuccess: (ASAuthorization) -> Void
    private let onError: (Error) -> Void

    init(
        onSuccess: @escaping (ASAuthorization) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        onSuccess(authorization)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        onError(error)
    }
}

// AuthorizationPresentationProvider

/// Presentation-anchor provider used so the system can display the passkey
/// sheet over the foreground window. On iOS this returns the active
/// `UIWindow`; on macOS the SDK consumer is responsible for setting a
/// custom presentation context provider via a SwiftUI bridge if the default
/// `NSApplication.shared.keyWindow` lookup is insufficient.
private final class AuthorizationPresentationProvider: NSObject,
    ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            for scene in scenes {
                if let windowScene = scene as? UIWindowScene {
                    if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                        return keyWindow
                    }
                    if let firstWindow = windowScene.windows.first {
                        return firstWindow
                    }
                }
            }
            return UIWindow()
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
        }
        #else
        // Fallback on platforms outside iOS. Consumers running macOS apps
        // should provide their own presentation anchor through a custom
        // overlay if this default does not match their window topology.
        return ASPresentationAnchor()
        #endif
    }
}

// WebAuthnAttestationParser

/// Self-contained parser for WebAuthn attestation objects and authenticator
/// data. Handles only the slices required by Apple's
/// `ASAuthorizationPlatformPublicKeyCredentialRegistration.rawAttestationObject`
/// payload: extracting the `authData` bstr from the top-level CBOR map and
/// pulling the uncompressed secp256r1 public key out of the attested
/// credential data.
///
/// This duplicates logic that is implemented in pure Dart for the web
/// target and in pure Kotlin for Android; cross-language byte-identity is
/// verified by the integration smoke test on testnet.
private enum WebAuthnAttestationParser {

    /// Minimum length of valid authenticator data (rpIdHash + flags + signCount).
    static let authDataMinLength: Int = 37

    /// Byte offset of the flags field within authenticator data.
    static let flagsOffset: Int = 32

    /// Backup-eligibility flag (multi-device credential).
    static let flagBE: UInt8 = 0x08

    /// Backup-state flag (currently backed up).
    static let flagBS: UInt8 = 0x10

    /// Header size of the attested credential data block within authenticator data.
    /// rpIdHash (32) + flags (1) + signCount (4) + aaguid (16) + credIdLen (2) = 55.
    static let attestedCredDataHeaderSize: Int = 55

    /// Size of an uncompressed secp256r1 public key (`0x04 || X || Y`).
    static let uncompressedKeySize: Int = 65

    /// 10-byte CBOR map prefix that begins an ES256 COSE key for secp256r1.
    /// Encodes: `1:2, 3:-7, -1:1, -2: bstr(32)` header.
    static let coseEs256KeyPrefix: [UInt8] = [
        0xa5, 0x01, 0x02, 0x03, 0x26,
        0x20, 0x01, 0x21, 0x58, 0x20,
    ]

    /// CBOR-encoded `"authData"` text-string key (text string len 8 + ASCII).
    static let authDataKey: [UInt8] = [
        0x68, 0x61, 0x75, 0x74, 0x68, 0x44, 0x61, 0x74, 0x61,
    ]

    static func extractAuthenticatorData(
        fromAttestation attestation: [UInt8]
    ) -> [UInt8]? {
        guard !attestation.isEmpty else { return nil }
        var offset = 0
        let firstByte = Int(attestation[offset])
        let majorType = firstByte >> 5
        guard majorType == 5 else { return nil }
        let info = firstByte & 0x1f
        let mapSize: Int
        switch info {
        case 0..<24:
            mapSize = info
            offset = 1
        case 24:
            guard offset + 1 < attestation.count else { return nil }
            mapSize = Int(attestation[offset + 1])
            offset = 2
        default:
            return nil
        }

        for _ in 0..<mapSize {
            guard offset < attestation.count else { return nil }
            guard let keyResult = readTextString(attestation, at: offset) else {
                return nil
            }
            offset = keyResult.nextOffset
            if keyResult.value == "authData" {
                guard let valueResult = readByteString(attestation, at: offset) else {
                    return nil
                }
                return valueResult.value
            } else {
                guard let next = skipValue(attestation, at: offset) else {
                    return nil
                }
                offset = next
            }
        }
        return nil
    }

    static func extractUncompressedPublicKey(
        fromAttestation attestation: [UInt8]
    ) -> [UInt8]? {
        guard let authData = extractAuthenticatorData(fromAttestation: attestation) else {
            return nil
        }
        guard authData.count >= attestedCredDataHeaderSize else { return nil }
        let flags = authData[flagsOffset]
        // Bit 6 (0x40) is the AT (attested credential data) flag.
        guard flags & 0x40 != 0 else { return nil }

        let credIdLenHi = Int(authData[53])
        let credIdLenLo = Int(authData[54])
        let credIdLen = (credIdLenHi << 8) | credIdLenLo
        let coseStart = attestedCredDataHeaderSize + credIdLen
        guard coseStart < authData.count else { return nil }
        let coseSlice = Array(authData[coseStart..<authData.count])

        if let key = extractByMapIteration(coseSlice) {
            return key
        }
        return extractByPattern(coseSlice)
    }

    static func parseAuthenticatorFlags(
        _ authData: [UInt8]?
    ) -> (deviceType: String?, backedUp: Bool?) {
        guard let authData, authData.count > flagsOffset else {
            return (nil, nil)
        }
        let flagByte = authData[flagsOffset]
        let deviceType = (flagByte & flagBE) != 0 ? "multiDevice" : "singleDevice"
        let backedUp = (flagByte & flagBS) != 0
        return (deviceType, backedUp)
    }

    // ------------------------------------------------------------------------
    // CBOR helpers (private)
    // ------------------------------------------------------------------------

    private struct StringRead {
        let value: String
        let nextOffset: Int
    }

    private struct BytesRead {
        let value: [UInt8]
        let nextOffset: Int
    }

    private static func readTextString(
        _ data: [UInt8],
        at offset: Int
    ) -> StringRead? {
        guard offset < data.count else { return nil }
        let firstByte = Int(data[offset])
        guard firstByte >> 5 == 3 else { return nil }
        let info = firstByte & 0x1f
        let length: Int
        let dataStart: Int
        switch info {
        case 0..<24:
            length = info
            dataStart = offset + 1
        case 24:
            guard offset + 1 < data.count else { return nil }
            length = Int(data[offset + 1])
            dataStart = offset + 2
        case 25:
            guard offset + 2 < data.count else { return nil }
            length = (Int(data[offset + 1]) << 8) | Int(data[offset + 2])
            dataStart = offset + 3
        default:
            return nil
        }
        guard dataStart + length <= data.count else { return nil }
        let bytes = Array(data[dataStart..<(dataStart + length)])
        guard let text = String(bytes: bytes, encoding: .utf8) else { return nil }
        return StringRead(value: text, nextOffset: dataStart + length)
    }

    private static func readByteString(
        _ data: [UInt8],
        at offset: Int
    ) -> BytesRead? {
        guard offset < data.count else { return nil }
        let firstByte = Int(data[offset])
        guard firstByte >> 5 == 2 else { return nil }
        let info = firstByte & 0x1f
        let length: Int
        let dataStart: Int
        switch info {
        case 0..<24:
            length = info
            dataStart = offset + 1
        case 24:
            guard offset + 1 < data.count else { return nil }
            length = Int(data[offset + 1])
            dataStart = offset + 2
        case 25:
            guard offset + 2 < data.count else { return nil }
            length = (Int(data[offset + 1]) << 8) | Int(data[offset + 2])
            dataStart = offset + 3
        case 26:
            guard offset + 4 < data.count else { return nil }
            let raw = (Int(data[offset + 1]) << 24)
                | (Int(data[offset + 2]) << 16)
                | (Int(data[offset + 3]) << 8)
                | Int(data[offset + 4])
            if raw < 0 { return nil }
            length = raw
            dataStart = offset + 5
        default:
            return nil
        }
        guard dataStart + length <= data.count else { return nil }
        let bytes = Array(data[dataStart..<(dataStart + length)])
        return BytesRead(value: bytes, nextOffset: dataStart + length)
    }

    private static func skipValue(
        _ data: [UInt8],
        at offset: Int
    ) -> Int? {
        guard offset < data.count else { return nil }
        let firstByte = Int(data[offset])
        let major = firstByte >> 5
        let info = firstByte & 0x1f
        switch major {
        case 0, 1:
            return skipHead(data, at: offset)
        case 2, 3:
            guard let lengthInfo = readLength(data, at: offset) else { return nil }
            let total = lengthInfo.dataStart + lengthInfo.length
            guard total <= data.count else { return nil }
            return total
        case 4:
            guard let lengthInfo = readLength(data, at: offset) else { return nil }
            var pos = lengthInfo.dataStart
            for _ in 0..<lengthInfo.length {
                guard let next = skipValue(data, at: pos) else { return nil }
                pos = next
            }
            return pos
        case 5:
            guard let lengthInfo = readLength(data, at: offset) else { return nil }
            var pos = lengthInfo.dataStart
            for _ in 0..<lengthInfo.length {
                guard let nextKey = skipValue(data, at: pos) else { return nil }
                pos = nextKey
                guard let nextValue = skipValue(data, at: pos) else { return nil }
                pos = nextValue
            }
            return pos
        case 6:
            guard let next = skipHead(data, at: offset) else { return nil }
            return skipValue(data, at: next)
        case 7:
            switch info {
            case 0..<24:
                return offset + 1
            case 24:
                return offset + 2 <= data.count ? offset + 2 : nil
            case 25:
                return offset + 3 <= data.count ? offset + 3 : nil
            case 26:
                return offset + 5 <= data.count ? offset + 5 : nil
            case 27:
                return offset + 9 <= data.count ? offset + 9 : nil
            default:
                return nil
            }
        default:
            return nil
        }
    }

    private struct LengthInfo {
        let length: Int
        let dataStart: Int
    }

    private static func readLength(_ data: [UInt8], at offset: Int) -> LengthInfo? {
        guard offset < data.count else { return nil }
        let firstByte = Int(data[offset])
        let info = firstByte & 0x1f
        switch info {
        case 0..<24:
            return LengthInfo(length: info, dataStart: offset + 1)
        case 24:
            guard offset + 1 < data.count else { return nil }
            return LengthInfo(length: Int(data[offset + 1]), dataStart: offset + 2)
        case 25:
            guard offset + 2 < data.count else { return nil }
            let len = (Int(data[offset + 1]) << 8) | Int(data[offset + 2])
            return LengthInfo(length: len, dataStart: offset + 3)
        case 26:
            guard offset + 4 < data.count else { return nil }
            let len = (Int(data[offset + 1]) << 24)
                | (Int(data[offset + 2]) << 16)
                | (Int(data[offset + 3]) << 8)
                | Int(data[offset + 4])
            return len < 0 ? nil : LengthInfo(length: len, dataStart: offset + 5)
        default:
            return nil
        }
    }

    private static func skipHead(_ data: [UInt8], at offset: Int) -> Int? {
        guard offset < data.count else { return nil }
        let info = Int(data[offset]) & 0x1f
        switch info {
        case 0..<24:
            return offset + 1
        case 24:
            return offset + 2 <= data.count ? offset + 2 : nil
        case 25:
            return offset + 3 <= data.count ? offset + 3 : nil
        case 26:
            return offset + 5 <= data.count ? offset + 5 : nil
        case 27:
            return offset + 9 <= data.count ? offset + 9 : nil
        default:
            return nil
        }
    }

    private static func extractByMapIteration(_ coseKey: [UInt8]) -> [UInt8]? {
        guard !coseKey.isEmpty else { return nil }
        let firstByte = Int(coseKey[0])
        guard firstByte >> 5 == 5 else { return nil }
        let info = firstByte & 0x1f
        let mapSize: Int
        var offset: Int
        switch info {
        case 0..<24:
            mapSize = info
            offset = 1
        case 24:
            guard coseKey.count >= 2 else { return nil }
            mapSize = Int(coseKey[1])
            offset = 2
        default:
            return nil
        }
        var x: [UInt8]?
        var y: [UInt8]?
        for _ in 0..<mapSize {
            guard offset < coseKey.count else { break }
            let keyByte = Int(coseKey[offset])
            let keyMajor = keyByte >> 5
            let keyInfo = keyByte & 0x1f
            if keyMajor == 1 && keyInfo == 1 {
                offset += 1
                if let bs = readByteString(coseKey, at: offset) {
                    x = bs.value
                    offset = bs.nextOffset
                } else {
                    guard let next = skipValue(coseKey, at: offset) else { return nil }
                    offset = next
                }
            } else if keyMajor == 1 && keyInfo == 2 {
                offset += 1
                if let bs = readByteString(coseKey, at: offset) {
                    y = bs.value
                    offset = bs.nextOffset
                } else {
                    guard let next = skipValue(coseKey, at: offset) else { return nil }
                    offset = next
                }
            } else {
                guard let head = skipHead(coseKey, at: offset) else { return nil }
                offset = head
                guard let next = skipValue(coseKey, at: offset) else { return nil }
                offset = next
            }
            if x != nil && y != nil { break }
        }
        guard let xv = x, let yv = y, xv.count == 32, yv.count == 32 else {
            return nil
        }
        return buildUncompressedKey(x: xv, y: yv)
    }

    private static func extractByPattern(_ data: [UInt8]) -> [UInt8]? {
        guard let prefixIndex = findSubarray(data, needle: coseEs256KeyPrefix) else {
            return nil
        }
        let xStart = prefixIndex + coseEs256KeyPrefix.count
        let yStart = xStart + 32 + 3
        let required = yStart + 32
        guard data.count >= required else { return nil }
        let xv = Array(data[xStart..<(xStart + 32)])
        let yv = Array(data[yStart..<(yStart + 32)])
        return buildUncompressedKey(x: xv, y: yv)
    }

    private static func buildUncompressedKey(x: [UInt8], y: [UInt8]) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: uncompressedKeySize)
        out[0] = 0x04
        for i in 0..<32 {
            out[1 + i] = x[i]
        }
        for i in 0..<32 {
            out[33 + i] = y[i]
        }
        return out
    }

    private static func findSubarray(_ haystack: [UInt8], needle: [UInt8]) -> Int? {
        guard !needle.isEmpty, needle.count <= haystack.count else { return nil }
        for i in 0...(haystack.count - needle.count) {
            var match = true
            for j in 0..<needle.count {
                if haystack[i + j] != needle[j] {
                    match = false
                    break
                }
            }
            if match { return i }
        }
        return nil
    }
}
