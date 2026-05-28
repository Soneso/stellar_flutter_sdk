//
//  SmartAccountWebAuthnPlugin.kt
//  stellar_flutter_sdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

package com.soneso.stellar_flutter_sdk.smartaccount

import android.app.Activity
import android.content.Context
import android.os.Build
import android.util.Base64
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.lang.ref.WeakReference

/**
 * Method-channel handler that wraps the AndroidX Credential Manager API
 * (`androidx.credentials.CredentialManager`) for WebAuthn passkey
 * registration and assertion.
 *
 * Wire contract (matches the Dart `PlatformWebAuthnProvider` bridge):
 *
 * - Channel: `com.soneso.stellar_flutter_sdk/smartaccount/webauthn`
 * - Methods: `register`, `authenticate`
 * - Argument types: byte arrays arrive as `ByteArray` (Dart `Uint8List`);
 *   strings, numbers, and booleans use the standard Flutter codec mapping.
 *
 * Error contract — `MethodChannel.Result.error` codes:
 * - `WEBAUTHN_CANCELLED` (4004 in the Dart numeric domain)
 * - `WEBAUTHN_REGISTRATION_FAILED` (4001)
 * - `WEBAUTHN_AUTHENTICATION_FAILED` (4002)
 * - `WEBAUTHN_NOT_SUPPORTED` (4003)
 *
 * Required platform configuration: the consumer app must host a Digital
 * Asset Links file at `https://<rpId>/.well-known/assetlinks.json` linking
 * the relying-party domain to the consumer app's signing certificate.
 *
 * Sample `assetlinks.json` template (NOT shipped — consumers host it on
 * their own domain):
 * ```
 * [
 *   {
 *     "relation": ["delegate_permission/common.handle_all_urls"],
 *     "target": {
 *       "namespace": "android_app",
 *       "package_name": "REPLACE_WITH_YOUR_APP_PACKAGE_NAME",
 *       "sha256_cert_fingerprints": [
 *         "REPLACE_WITH_YOUR_RELEASE_SHA256_FINGERPRINT",
 *         "REPLACE_WITH_YOUR_DEBUG_SHA256_FINGERPRINT"
 *       ]
 *     }
 *   }
 * ]
 * ```
 *
 * Notes for consumers:
 * - The `package_name` MUST match the consumer app's `applicationId`.
 * - During development include both release and debug keystore fingerprints.
 * - Serve the file over HTTPS with `Content-Type: application/json`.
 * - Verify deployment via
 *   `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://<your-domain>`.
 */
class SmartAccountWebAuthnPlugin(
    private val applicationContext: Context
) : MethodChannel.MethodCallHandler {

    // State

    private val json = Json { ignoreUnknownKeys = true }

    private val supervisorJob: Job = SupervisorJob()
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Main + supervisorJob)

    /**
     * Weak reference to the foreground Activity. The Credential Manager
     * requires an Activity context to display the system passkey sheet;
     * holding a strong reference would leak the Activity across
     * configuration changes.
     */
    private var activityRef: WeakReference<Activity>? = null

    /**
     * Lazily-initialised Credential Manager instance. Construction is
     * deferred until the first call so that consumers running on API < 28
     * do not pay the cost of instantiating the manager (and so that the
     * `Build.VERSION.SDK_INT` check fires before we touch the API).
     */
    private var credentialManager: CredentialManager? = null

    // Lifecycle hooks invoked by the parent plugin

    fun attachActivity(activity: Activity) {
        activityRef = WeakReference(activity)
    }

    fun detachActivity() {
        activityRef = null
    }

    fun dispose() {
        scope.cancel()
        activityRef = null
        credentialManager = null
    }

    // Method-channel dispatch

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "register" -> handleRegister(call, result)
            "authenticate" -> handleAuthenticate(call, result)
            else -> result.notImplemented()
        }
    }

    // register

    private fun handleRegister(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.error(
                "WEBAUTHN_NOT_SUPPORTED",
                "Credential Manager requires Android API 28 (Pie) or higher. " +
                    "Current API level: ${Build.VERSION.SDK_INT}",
                null
            )
            return
        }

        val rpId = call.argument<String>("rpId")
        if (rpId.isNullOrEmpty()) {
            result.error(
                "WEBAUTHN_REGISTRATION_FAILED",
                "Missing required argument: rpId",
                null
            )
            return
        }
        val rpName = call.argument<String>("rpName")
        if (rpName.isNullOrEmpty()) {
            result.error(
                "WEBAUTHN_REGISTRATION_FAILED",
                "Missing required argument: rpName",
                null
            )
            return
        }
        val challenge = byteArgument(call, "challenge")
        if (challenge == null) {
            result.error(
                "WEBAUTHN_REGISTRATION_FAILED",
                "Missing required argument: challenge",
                null
            )
            return
        }
        val userId = byteArgument(call, "userId")
        if (userId == null) {
            result.error(
                "WEBAUTHN_REGISTRATION_FAILED",
                "Missing required argument: userId",
                null
            )
            return
        }
        val userName = call.argument<String>("userName")
        if (userName.isNullOrEmpty()) {
            result.error(
                "WEBAUTHN_REGISTRATION_FAILED",
                "Missing required argument: userName",
                null
            )
            return
        }
        val timeout = call.argument<Number>("timeout")?.toLong() ?: 60_000L
        val authenticatorAttachment = call.argument<String>("authenticatorAttachment")

        val activity = activityRef?.get()
        if (activity == null) {
            result.error(
                "WEBAUTHN_REGISTRATION_FAILED",
                "Activity not attached; WebAuthn requires the foreground activity context",
                null
            )
            return
        }

        val requestJson = buildRegistrationRequestJson(
            rpId = rpId,
            rpName = rpName,
            challenge = challenge,
            userId = userId,
            userName = userName,
            timeout = timeout,
            authenticatorAttachment = authenticatorAttachment
        )

        val createRequest = CreatePublicKeyCredentialRequest(requestJson = requestJson)

        val manager = ensureCredentialManager(activity)
        scope.launch {
            try {
                val credential = manager.createCredential(activity, createRequest)
                val response = credential as? CreatePublicKeyCredentialResponse
                    ?: throw IllegalStateException(
                        "Unexpected credential type: ${credential::class.simpleName}"
                    )
                val mapped = parseRegistrationResponse(response)
                result.success(mapped)
            } catch (e: CreateCredentialCancellationException) {
                result.error(
                    "WEBAUTHN_CANCELLED",
                    "User cancelled WebAuthn operation",
                    e.message
                )
            } catch (e: CreateCredentialException) {
                result.error(
                    "WEBAUTHN_REGISTRATION_FAILED",
                    "Credential creation failed: ${e.type} - ${e.message}",
                    e.message
                )
            } catch (e: Exception) {
                result.error(
                    "WEBAUTHN_REGISTRATION_FAILED",
                    "Unexpected error during credential creation: ${e.message}",
                    e.message
                )
            }
        }
    }

    // authenticate

    private fun handleAuthenticate(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.error(
                "WEBAUTHN_NOT_SUPPORTED",
                "Credential Manager requires Android API 28 (Pie) or higher. " +
                    "Current API level: ${Build.VERSION.SDK_INT}",
                null
            )
            return
        }

        val rpId = call.argument<String>("rpId")
        if (rpId.isNullOrEmpty()) {
            result.error(
                "WEBAUTHN_AUTHENTICATION_FAILED",
                "Missing required argument: rpId",
                null
            )
            return
        }
        val challenge = byteArgument(call, "challenge")
        if (challenge == null) {
            result.error(
                "WEBAUTHN_AUTHENTICATION_FAILED",
                "Missing required argument: challenge",
                null
            )
            return
        }
        val timeout = call.argument<Number>("timeout")?.toLong() ?: 60_000L
        val allowCredentials = call.argument<List<*>>("allowCredentials")

        val activity = activityRef?.get()
        if (activity == null) {
            result.error(
                "WEBAUTHN_AUTHENTICATION_FAILED",
                "Activity not attached; WebAuthn requires the foreground activity context",
                null
            )
            return
        }

        val parsedAllowCredentials = allowCredentials?.mapNotNull { entry ->
            val map = entry as? Map<*, *> ?: return@mapNotNull null
            val rawId = map["id"]
            val idBytes: ByteArray = when (rawId) {
                is ByteArray -> rawId
                is List<*> -> ByteArray(rawId.size) { i -> (rawId[i] as Number).toByte() }
                else -> return@mapNotNull null
            }
            val transports = (map["transports"] as? List<*>)
                ?.mapNotNull { it as? String }
            AllowCredentialEntry(idBytes, transports)
        }

        val requestJson = buildAuthenticationRequestJson(
            rpId = rpId,
            challenge = challenge,
            timeout = timeout,
            allowCredentials = parsedAllowCredentials
        )

        val getRequest = GetCredentialRequest(
            credentialOptions = listOf(
                GetPublicKeyCredentialOption(requestJson = requestJson)
            )
        )

        val manager = ensureCredentialManager(activity)
        scope.launch {
            try {
                val response = manager.getCredential(activity, getRequest)
                val credential = response.credential as? PublicKeyCredential
                    ?: throw IllegalStateException(
                        "Unexpected credential type: ${response.credential::class.simpleName}"
                    )
                val mapped = parseAuthenticationResponse(credential)
                result.success(mapped)
            } catch (e: NoCredentialException) {
                result.error(
                    "WEBAUTHN_AUTHENTICATION_FAILED",
                    "No matching credential found for this relying party ($rpId)",
                    e.message
                )
            } catch (e: GetCredentialCancellationException) {
                result.error(
                    "WEBAUTHN_CANCELLED",
                    "User cancelled WebAuthn operation",
                    e.message
                )
            } catch (e: GetCredentialException) {
                result.error(
                    "WEBAUTHN_AUTHENTICATION_FAILED",
                    "Credential assertion failed: ${e.type} - ${e.message}",
                    e.message
                )
            } catch (e: Exception) {
                result.error(
                    "WEBAUTHN_AUTHENTICATION_FAILED",
                    "Unexpected error during credential assertion: ${e.message}",
                    e.message
                )
            }
        }
    }

    // JSON request building

    private fun buildRegistrationRequestJson(
        rpId: String,
        rpName: String,
        challenge: ByteArray,
        userId: ByteArray,
        userName: String,
        timeout: Long,
        authenticatorAttachment: String?
    ): String {
        val challengeB64 = base64UrlEncode(challenge)
        val userIdB64 = base64UrlEncode(userId)

        val authenticatorSelection = buildMap<String, JsonElement> {
            if (authenticatorAttachment != null) {
                put("authenticatorAttachment", JsonPrimitive(authenticatorAttachment))
            }
            put("residentKey", JsonPrimitive("preferred"))
            put("requireResidentKey", JsonPrimitive(false))
            // The OZ WebAuthn verifier contract checks the UV flag in
            // authenticator data and rejects assertions with UV=false.
            put("userVerification", JsonPrimitive("required"))
        }

        val jsonObject = JsonObject(
            mapOf(
                "challenge" to JsonPrimitive(challengeB64),
                "rp" to JsonObject(
                    mapOf(
                        "id" to JsonPrimitive(rpId),
                        "name" to JsonPrimitive(rpName)
                    )
                ),
                "user" to JsonObject(
                    mapOf(
                        "id" to JsonPrimitive(userIdB64),
                        "name" to JsonPrimitive(userName),
                        "displayName" to JsonPrimitive(userName)
                    )
                ),
                "pubKeyCredParams" to JsonArray(
                    listOf(
                        JsonObject(
                            mapOf(
                                "type" to JsonPrimitive("public-key"),
                                "alg" to JsonPrimitive(ES256_ALGORITHM_ID)
                            )
                        )
                    )
                ),
                "timeout" to JsonPrimitive(timeout),
                "attestation" to JsonPrimitive("direct"),
                "authenticatorSelection" to JsonObject(authenticatorSelection)
            )
        )
        return jsonObject.toString()
    }

    private fun buildAuthenticationRequestJson(
        rpId: String,
        challenge: ByteArray,
        timeout: Long,
        allowCredentials: List<AllowCredentialEntry>?
    ): String {
        val challengeB64 = base64UrlEncode(challenge)
        val allowCredentialsJson = if (!allowCredentials.isNullOrEmpty()) {
            JsonArray(
                allowCredentials.map { entry ->
                    JsonObject(
                        buildMap {
                            put("type", JsonPrimitive("public-key"))
                            put("id", JsonPrimitive(base64UrlEncode(entry.id)))
                            if (entry.transports != null) {
                                put(
                                    "transports",
                                    JsonArray(entry.transports.map { JsonPrimitive(it) })
                                )
                            }
                        }
                    )
                }
            )
        } else {
            JsonArray(emptyList())
        }

        val jsonObject = JsonObject(
            mapOf(
                "challenge" to JsonPrimitive(challengeB64),
                "rpId" to JsonPrimitive(rpId),
                "timeout" to JsonPrimitive(timeout),
                "userVerification" to JsonPrimitive("required"),
                "allowCredentials" to allowCredentialsJson
            )
        )
        return jsonObject.toString()
    }

    // Response parsing

    private fun parseRegistrationResponse(
        response: CreatePublicKeyCredentialResponse
    ): Map<String, Any?> {
        val responseJson: JsonObject = try {
            json.parseToJsonElement(response.registrationResponseJson).jsonObject
        } catch (e: Exception) {
            throw IllegalStateException(
                "Failed to parse registration response JSON: ${e.message}",
                e
            )
        }

        val rawIdB64 = responseJson["rawId"]?.jsonPrimitive?.contentOrNull
            ?: throw IllegalStateException("Missing rawId in registration response")
        val credentialId = base64UrlDecode(rawIdB64)

        val responseObj = responseJson["response"]?.jsonObject
            ?: throw IllegalStateException(
                "Missing response object in registration response"
            )

        val attestationObjectB64 =
            responseObj["attestationObject"]?.jsonPrimitive?.contentOrNull
                ?: throw IllegalStateException(
                    "Missing attestationObject in registration response"
                )
        val attestationObject = base64UrlDecode(attestationObjectB64)

        val publicKey = extractPublicKey(responseObj, attestationObject)
        val transports = extractTransports(responseObj)

        val authenticatorData = responseObj["authenticatorData"]?.jsonPrimitive?.contentOrNull
            ?.let { base64UrlDecode(it) }
            ?: WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestationObject)

        val flags = WebAuthnCborParser.parseAuthenticatorFlags(authenticatorData)
        return buildMap {
            put("credentialId", credentialId)
            put("publicKey", publicKey)
            put("attestationObject", attestationObject)
            if (transports != null) put("transports", transports)
            if (flags.deviceType != null) put("deviceType", flags.deviceType)
            if (flags.backedUp != null) put("backedUp", flags.backedUp)
        }
    }

    private fun parseAuthenticationResponse(
        credential: PublicKeyCredential
    ): Map<String, Any?> {
        val responseJson: JsonObject = try {
            json.parseToJsonElement(credential.authenticationResponseJson).jsonObject
        } catch (e: Exception) {
            throw IllegalStateException(
                "Failed to parse authentication response JSON: ${e.message}",
                e
            )
        }

        val rawIdB64 = responseJson["rawId"]?.jsonPrimitive?.contentOrNull
            ?: throw IllegalStateException("Missing rawId in authentication response")
        val credentialId = base64UrlDecode(rawIdB64)

        val responseObj = responseJson["response"]?.jsonObject
            ?: throw IllegalStateException(
                "Missing response object in authentication response"
            )

        val authenticatorDataB64 =
            responseObj["authenticatorData"]?.jsonPrimitive?.contentOrNull
                ?: throw IllegalStateException(
                    "Missing authenticatorData in authentication response"
                )
        val authenticatorData = base64UrlDecode(authenticatorDataB64)

        val clientDataJsonB64 = responseObj["clientDataJSON"]?.jsonPrimitive?.contentOrNull
            ?: throw IllegalStateException(
                "Missing clientDataJSON in authentication response"
            )
        val clientDataJson = base64UrlDecode(clientDataJsonB64)

        val signatureB64 = responseObj["signature"]?.jsonPrimitive?.contentOrNull
            ?: throw IllegalStateException("Missing signature in authentication response")
        val signature = base64UrlDecode(signatureB64)

        return mapOf(
            "credentialId" to credentialId,
            "authenticatorData" to authenticatorData,
            "clientDataJSON" to clientDataJson,
            "signature" to signature
        )
    }

    private fun extractPublicKey(
        responseObj: JsonObject,
        attestationObject: ByteArray
    ): ByteArray {
        // Two-strategy extraction (intentional; no third fallback):
        //
        //   Strategy 1: PublicKeyCredential.AuthenticatorAttestationResponse
        //               .getPublicKey() (SPKI/DER), available on every
        //               authenticator that satisfies the OZ smart-account
        //               contract's ES256 floor.
        //
        //   Strategy 2: parse the COSE_Key structure out of the attestation
        //               object's authenticator data. Required for the small
        //               number of authenticators that omit getPublicKey().
        //
        // Both strategies cover the full set of conforming authenticators
        // permitted by the contract; deeper fallbacks would only mask a
        // genuine non-conforming authenticator rather than recover usable
        // key material.
        val publicKeyB64 = responseObj["publicKey"]?.jsonPrimitive?.contentOrNull
        if (publicKeyB64 != null) {
            try {
                val spkiKey = base64UrlDecode(publicKeyB64)
                val extracted = WebAuthnCborParser.extractPublicKeyFromSpki(spkiKey)
                if (extracted != null) return extracted
            } catch (_: Exception) {
                // Fall through to attestation-object parsing.
            }
        }
        return extractPublicKeyFromAttestationCbor(attestationObject)
    }

    private fun extractPublicKeyFromAttestationCbor(
        attestationObject: ByteArray
    ): ByteArray {
        val authData = WebAuthnCborParser.extractAuthenticatorDataFromAttestation(attestationObject)
            ?: throw IllegalStateException(
                "Could not extract authenticator data from attestation object"
            )
        if (authData.size < WebAuthnCborParser.AUTH_DATA_MIN_LENGTH) {
            throw IllegalStateException(
                "Authenticator data too short: ${authData.size} bytes (minimum ${WebAuthnCborParser.AUTH_DATA_MIN_LENGTH})"
            )
        }
        val flags = authData[WebAuthnCborParser.FLAGS_OFFSET].toInt() and 0xFF
        if (flags and 0x40 == 0) {
            throw IllegalStateException(
                "Authenticator data does not contain attested credential data (AT flag not set)"
            )
        }
        if (authData.size < WebAuthnCborParser.ATTESTED_CRED_DATA_HEADER_SIZE) {
            throw IllegalStateException(
                "Authenticator data too short for attested credential data: ${authData.size} bytes"
            )
        }
        val credIdLen = ((authData[53].toInt() and 0xFF) shl 8) or
            (authData[54].toInt() and 0xFF)
        val coseKeyStart = WebAuthnCborParser.ATTESTED_CRED_DATA_HEADER_SIZE + credIdLen
        if (coseKeyStart >= authData.size) {
            throw IllegalStateException(
                "COSE key data not found in authenticator data (credentialId length: $credIdLen)"
            )
        }
        val coseKey = authData.copyOfRange(coseKeyStart, authData.size)
        val key = WebAuthnCborParser.extractPublicKeyFromCoseKey(coseKey)
        return key
            ?: throw IllegalStateException(
                "Could not find COSE key structure in authenticator data"
            )
    }

    private fun extractTransports(responseObj: JsonObject): List<String>? {
        val arr = responseObj["transports"]?.jsonArray ?: return null
        return arr.map { it.jsonPrimitive.content }
    }

    // Helpers

    private fun ensureCredentialManager(context: Context): CredentialManager {
        val current = credentialManager
        if (current != null) return current
        val created = CredentialManager.create(context)
        credentialManager = created
        return created
    }

    private fun byteArgument(call: MethodCall, key: String): ByteArray? {
        return when (val value = call.argument<Any>(key)) {
            is ByteArray -> value
            is List<*> -> ByteArray(value.size) { i -> (value[i] as Number).toByte() }
            else -> null
        }
    }

    private fun base64UrlEncode(data: ByteArray): String {
        return Base64.encodeToString(
            data,
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )
    }

    private fun base64UrlDecode(encoded: String): ByteArray {
        return Base64.decode(
            encoded,
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )
    }

    private data class AllowCredentialEntry(
        val id: ByteArray,
        val transports: List<String>?
    )

    companion object {
        /** COSE algorithm identifier for ES256 (ECDSA with SHA-256 on P-256). */
        private const val ES256_ALGORITHM_ID = -7
    }
}
