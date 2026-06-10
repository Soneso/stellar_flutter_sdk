//
//  SwiftStellarFlutterSdkPlugin.swift
//  stellar_flutter_sdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

import Flutter
import UIKit

// ============================================================================
// StellarFlutterSdkPlugin
// ============================================================================

/// Top-level Flutter plugin entry for the Stellar Flutter SDK.
///
/// Registered via the `pluginClass: StellarFlutterSdkPlugin` entry in
/// `pubspec.yaml.flutter.plugin.platforms.ios`. The Swift convention prefixes
/// the file name with `Swift`; the class symbol exposed to Flutter is
/// `StellarFlutterSdkPlugin`.
///
/// The plugin owns lifetime of two singleton method-channel handlers:
/// - `SmartAccountWebAuthnPlugin` on
///   `com.soneso.stellar_flutter_sdk/smartaccount/webauthn`
/// - `IOSStorageAdapter` on
///   `com.soneso.stellar_flutter_sdk/smartaccount/storage`
///
/// Both handlers retain their own state (the WebAuthn handler holds a strong
/// reference to the active `ASAuthorizationController` delegate; the storage
/// handler holds a `JSONEncoder` / `JSONDecoder` pair).
@objc public class StellarFlutterSdkPlugin: NSObject, FlutterPlugin {

    // ========================================================================
    // FlutterPlugin
    // ========================================================================

    /// Channel name for WebAuthn (passkey) operations.
    public static let webAuthnChannelName: String =
        "com.soneso.stellar_flutter_sdk/smartaccount/webauthn"

    /// Channel name for secure-storage operations.
    public static let storageChannelName: String =
        "com.soneso.stellar_flutter_sdk/smartaccount/storage"

    /// Strong reference to the WebAuthn handler. Released when the plugin is
    /// unregistered.
    private static var webAuthnHandler: SmartAccountWebAuthnPlugin?

    /// Strong reference to the storage handler. Released when the plugin is
    /// unregistered.
    private static var storageHandler: IOSStorageAdapter?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()

        let webAuthnChannel = FlutterMethodChannel(
            name: webAuthnChannelName,
            binaryMessenger: messenger
        )
        let webAuthnHandler = SmartAccountWebAuthnPlugin()
        webAuthnChannel.setMethodCallHandler { call, result in
            webAuthnHandler.handle(call: call, result: result)
        }
        Self.webAuthnHandler = webAuthnHandler

        let storageChannel = FlutterMethodChannel(
            name: storageChannelName,
            binaryMessenger: messenger
        )
        let storageHandler = IOSStorageAdapter()
        storageChannel.setMethodCallHandler { call, result in
            storageHandler.handle(call: call, result: result)
        }
        Self.storageHandler = storageHandler
    }
}
