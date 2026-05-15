//
//  StellarFlutterSdkPlugin.kt
//  stellar_flutter_sdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

package com.soneso.stellar_flutter_sdk

import android.app.Activity
import android.content.Context
import com.soneso.stellar_flutter_sdk.smartaccount.AndroidStorageAdapter
import com.soneso.stellar_flutter_sdk.smartaccount.SmartAccountWebAuthnPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

/**
 * Top-level Flutter plugin entry for the Stellar Flutter SDK on Android.
 *
 * Registered via the `pluginClass: StellarFlutterSdkPlugin` entry under
 * `flutter.plugin.platforms.android` in `pubspec.yaml`. The plugin owns
 * lifetime of two singleton method-channel handlers:
 *
 * - [SmartAccountWebAuthnPlugin] on
 *   `com.soneso.stellar_flutter_sdk/smartaccount/webauthn` — wraps the
 *   AndroidX Credential Manager API for passkey registration / assertion.
 * - [AndroidStorageAdapter] on
 *   `com.soneso.stellar_flutter_sdk/smartaccount/storage` — wraps
 *   `EncryptedSharedPreferences` for credential and session persistence.
 *
 * The plugin is `ActivityAware` because the Credential Manager API requires
 * an Activity context to display the system passkey sheet. The Activity
 * reference is forwarded to the WebAuthn handler whenever the activity
 * lifecycle changes.
 */
class StellarFlutterSdkPlugin : FlutterPlugin, ActivityAware {

    /** Channel name for WebAuthn (passkey) operations. */
    companion object {
        const val WEB_AUTHN_CHANNEL_NAME: String =
            "com.soneso.stellar_flutter_sdk/smartaccount/webauthn"

        const val STORAGE_CHANNEL_NAME: String =
            "com.soneso.stellar_flutter_sdk/smartaccount/storage"
    }

    private var webAuthnChannel: MethodChannel? = null
    private var storageChannel: MethodChannel? = null

    private var webAuthnHandler: SmartAccountWebAuthnPlugin? = null
    private var storageHandler: AndroidStorageAdapter? = null

    private var applicationContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        val webAuthnHandler = SmartAccountWebAuthnPlugin(binding.applicationContext)
        val storageHandler = AndroidStorageAdapter(binding.applicationContext)

        val webAuthnChannel = MethodChannel(binding.binaryMessenger, WEB_AUTHN_CHANNEL_NAME)
        webAuthnChannel.setMethodCallHandler(webAuthnHandler)

        val storageChannel = MethodChannel(binding.binaryMessenger, STORAGE_CHANNEL_NAME)
        storageChannel.setMethodCallHandler(storageHandler)

        this.webAuthnHandler = webAuthnHandler
        this.storageHandler = storageHandler
        this.webAuthnChannel = webAuthnChannel
        this.storageChannel = storageChannel
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        webAuthnChannel?.setMethodCallHandler(null)
        storageChannel?.setMethodCallHandler(null)
        webAuthnHandler?.dispose()
        storageHandler?.dispose()
        webAuthnHandler = null
        storageHandler = null
        webAuthnChannel = null
        storageChannel = null
        applicationContext = null
    }

    // ========================================================================
    // ActivityAware
    // ========================================================================

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        webAuthnHandler?.attachActivity(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        webAuthnHandler?.detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        webAuthnHandler?.attachActivity(binding.activity)
    }

    override fun onDetachedFromActivity() {
        webAuthnHandler?.detachActivity()
    }
}
