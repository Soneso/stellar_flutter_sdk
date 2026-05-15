//
//  SmartAccountWebAuthnPluginTests.swift
//  stellar_flutter_sdkTests
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//
//  Tests for the argument-validation paths and the publicly observable
//  behaviour of `SmartAccountWebAuthnPlugin`. These tests exercise the
//  Flutter method-channel handler with synthetic `FlutterMethodCall`
//  inputs and verify the resulting `FlutterError` codes match the wire
//  contract documented on the plugin class.
//
//  The tests deliberately stop short of invoking
//  `ASAuthorizationController.performRequests()`, which would require a
//  real authenticator and an interactive system passkey sheet. The
//  argument-validation surface, the unsupported-OS branch, and the
//  dispatch surface are all reachable without driving the
//  AuthenticationServices runtime.
//
//  Run procedure:
//    These tests link against the `Flutter` framework, so `swift test`
//    from the SwiftPM package directory will not resolve the import.
//    Run them via `xcodebuild test` against the example app's
//    `RunnerTests` target, which is configured with the framework
//    search paths Flutter injects at build time.
//

import Flutter
import XCTest
@testable import stellar_flutter_sdk

final class SmartAccountWebAuthnPluginTests: XCTestCase {

    // ========================================================================
    // Helpers
    // ========================================================================

    /// Invokes `handle()` synchronously and returns the value passed to
    /// the `FlutterResult` callback. Uses an `XCTestExpectation` so a
    /// missing callback fails the test instead of hanging the suite.
    private func invoke(
        _ plugin: SmartAccountWebAuthnPlugin,
        method: String,
        arguments: Any?,
        timeout: TimeInterval = 1.0
    ) -> Any? {
        let expectation = self.expectation(description: "FlutterResult for \(method)")
        var captured: Any?
        let call = FlutterMethodCall(methodName: method, arguments: arguments)
        plugin.handle(call: call) { value in
            captured = value
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        return captured
    }

    // ========================================================================
    // register: argument validation
    // ========================================================================

    func test_register_missing_arguments_map_returns_registration_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let result = invoke(plugin, method: "register", arguments: "not a map")
        let error = result as? FlutterError
        XCTAssertNotNil(error, "Expected FlutterError, got: \(String(describing: result))")
        XCTAssertEqual(error?.code, "WEBAUTHN_REGISTRATION_FAILED")
        XCTAssertTrue(
            error?.message?.contains("Invalid arguments") == true,
            "Expected message to mention invalid arguments, got: \(String(describing: error?.message))"
        )
    }

    func test_register_missing_rpId_returns_registration_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpName": "Test RP",
            "challenge": FlutterStandardTypedData(bytes: Data([0x01, 0x02, 0x03])),
            "userId": FlutterStandardTypedData(bytes: Data([0x10, 0x11])),
            "userName": "alice",
        ]
        let result = invoke(plugin, method: "register", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_REGISTRATION_FAILED")
        XCTAssertTrue(error?.message?.contains("rpId") == true)
    }

    func test_register_empty_rpId_returns_registration_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpId": "",
            "rpName": "Test RP",
            "challenge": FlutterStandardTypedData(bytes: Data([0x01])),
            "userId": FlutterStandardTypedData(bytes: Data([0x10])),
            "userName": "alice",
        ]
        let result = invoke(plugin, method: "register", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_REGISTRATION_FAILED")
        XCTAssertTrue(error?.message?.contains("rpId") == true)
    }

    func test_register_missing_rpName_returns_registration_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpId": "example.com",
            "challenge": FlutterStandardTypedData(bytes: Data([0x01])),
            "userId": FlutterStandardTypedData(bytes: Data([0x10])),
            "userName": "alice",
        ]
        let result = invoke(plugin, method: "register", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_REGISTRATION_FAILED")
        XCTAssertTrue(error?.message?.contains("rpName") == true)
    }

    func test_register_missing_challenge_returns_registration_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpId": "example.com",
            "rpName": "Test RP",
            "userId": FlutterStandardTypedData(bytes: Data([0x10])),
            "userName": "alice",
        ]
        let result = invoke(plugin, method: "register", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_REGISTRATION_FAILED")
        XCTAssertTrue(error?.message?.contains("challenge") == true)
    }

    func test_register_missing_userId_returns_registration_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpId": "example.com",
            "rpName": "Test RP",
            "challenge": FlutterStandardTypedData(bytes: Data([0x01])),
            "userName": "alice",
        ]
        let result = invoke(plugin, method: "register", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_REGISTRATION_FAILED")
        XCTAssertTrue(error?.message?.contains("userId") == true)
    }

    func test_register_missing_userName_returns_registration_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpId": "example.com",
            "rpName": "Test RP",
            "challenge": FlutterStandardTypedData(bytes: Data([0x01])),
            "userId": FlutterStandardTypedData(bytes: Data([0x10])),
        ]
        let result = invoke(plugin, method: "register", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_REGISTRATION_FAILED")
        XCTAssertTrue(error?.message?.contains("userName") == true)
    }

    // ========================================================================
    // authenticate: argument validation
    // ========================================================================

    func test_authenticate_missing_arguments_map_returns_authentication_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let result = invoke(plugin, method: "authenticate", arguments: 42)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_AUTHENTICATION_FAILED")
        XCTAssertTrue(
            error?.message?.contains("Invalid arguments") == true
        )
    }

    func test_authenticate_missing_rpId_returns_authentication_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "challenge": FlutterStandardTypedData(bytes: Data([0x01])),
        ]
        let result = invoke(plugin, method: "authenticate", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_AUTHENTICATION_FAILED")
        XCTAssertTrue(error?.message?.contains("rpId") == true)
    }

    func test_authenticate_empty_rpId_returns_authentication_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpId": "",
            "challenge": FlutterStandardTypedData(bytes: Data([0x01])),
        ]
        let result = invoke(plugin, method: "authenticate", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_AUTHENTICATION_FAILED")
        XCTAssertTrue(error?.message?.contains("rpId") == true)
    }

    func test_authenticate_missing_challenge_returns_authentication_failed() {
        let plugin = SmartAccountWebAuthnPlugin()
        let args: [String: Any?] = [
            "rpId": "example.com",
        ]
        let result = invoke(plugin, method: "authenticate", arguments: args)
        let error = result as? FlutterError
        XCTAssertEqual(error?.code, "WEBAUTHN_AUTHENTICATION_FAILED")
        XCTAssertTrue(error?.message?.contains("challenge") == true)
    }

    // ========================================================================
    // dispatch: unknown methods
    // ========================================================================

    func test_unknown_method_returns_method_not_implemented() {
        let plugin = SmartAccountWebAuthnPlugin()
        let result = invoke(plugin, method: "no.such.method", arguments: nil)
        // FlutterMethodNotImplemented is a sentinel singleton; identity
        // comparison is the contract Flutter callers rely on.
        XCTAssertTrue(
            (result as AnyObject) === FlutterMethodNotImplemented as AnyObject,
            "Expected FlutterMethodNotImplemented, got: \(String(describing: result))"
        )
    }
}
