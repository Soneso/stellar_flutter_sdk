//
//  AndroidStorageAdapter.kt
//  stellar_flutter_sdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

package com.soneso.stellar_flutter_sdk.smartaccount

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * Method-channel handler for the Dart `PlatformStorageAdapter` bridge on
 * Android.
 *
 * Persists serialised credential and session payloads as
 * `EncryptedSharedPreferences` entries (AES-256-GCM for values,
 * AES-256-SIV for keys, master key in the Android Keystore).
 *
 * Wire contract (matches the Dart `PlatformStorageAdapter` bridge):
 *
 * - Channel: `com.soneso.stellar_flutter_sdk/smartaccount/storage`
 * - Methods (10): `storage.save`, `storage.get`, `storage.getByContract`,
 *   `storage.getAll`, `storage.delete`, `storage.update`, `storage.clear`,
 *   `storage.saveSession`, `storage.getSession`, `storage.clearSession`.
 *
 * Error contract — `MethodChannel.Result.error` codes:
 * - `STORAGE_READ_FAILED`
 * - `STORAGE_WRITE_FAILED`
 * - `CREDENTIAL_NOT_FOUND` (only emitted by `storage.update`)
 *
 * ### Asymmetric corruption handling
 *
 * - `storage.get` returns `null` if the stored entry cannot be decoded; the
 *   corruption is logged via `Log.w` but not surfaced.
 * - `storage.getAll` skips corrupted entries (logged) and returns the
 *   valid subset.
 * - `storage.update` emits `STORAGE_READ_FAILED` when the entry is corrupt
 *   because the read-modify-write sequence cannot proceed safely without
 *   a known prior state.
 *
 * ### Storage layout
 *
 * The on-disk JSON shape is stable and documented under the keys below so
 * consumers can interoperate across implementations without re-onboarding.
 *
 * - Prefs file: `stellar_smart_account_prefs`
 * - Credential key prefix: `cred_`
 * - Session key: `session_current` (`session_` + `current`)
 */
class AndroidStorageAdapter(
    context: Context
) : MethodChannel.MethodCallHandler {

    // ========================================================================
    // State
    // ========================================================================

    private val mutex = Mutex()
    private val supervisorJob: Job = SupervisorJob()
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.IO + supervisorJob)
    private val prefs: SharedPreferences

    init {
        try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            prefs = EncryptedSharedPreferences.create(
                context,
                PREFS_FILE_NAME,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Cannot construct the adapter without encrypted storage; the
            // Flutter plugin treats this as a fatal initialisation error and
            // surfaces it on the first call via STORAGE_WRITE_FAILED.
            throw IllegalStateException(
                "Failed to initialize encrypted storage: ${e.message}",
                e
            )
        }
    }

    fun dispose() {
        scope.cancel()
    }

    // ========================================================================
    // Method-channel dispatch
    // ========================================================================

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                when (call.method) {
                    "storage.save" -> handleSave(call, result)
                    "storage.get" -> handleGet(call, result)
                    "storage.getByContract" -> handleGetByContract(call, result)
                    "storage.getAll" -> handleGetAll(result)
                    "storage.delete" -> handleDelete(call, result)
                    "storage.update" -> handleUpdate(call, result)
                    "storage.clear" -> handleClear(result)
                    "storage.saveSession" -> handleSaveSession(call, result)
                    "storage.getSession" -> handleGetSession(result)
                    "storage.clearSession" -> handleClearSession(result)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unhandled storage error", e)
                result.error(
                    "STORAGE_WRITE_FAILED",
                    "Storage operation failed: ${e.message}",
                    e.message
                )
            }
        }
    }

    // ========================================================================
    // Credential operations
    // ========================================================================

    private suspend fun handleSave(call: MethodCall, result: MethodChannel.Result) {
        val map = mapArgument(call, "credential")
            ?: return result.error(
                "STORAGE_WRITE_FAILED",
                "Storage write failed for key: credential (Missing 'credential' argument)",
                null
            )
        val credentialId = map["credentialId"] as? String
        if (credentialId.isNullOrEmpty()) {
            result.error(
                "STORAGE_WRITE_FAILED",
                "Storage write failed for key: credential (Missing 'credentialId')",
                null
            )
            return
        }
        mutex.withLock {
            try {
                val key = credentialKey(credentialId)
                val payload = mapToJsonObject(map).toString()
                val ok = prefs.edit().putString(key, payload).commit()
                if (!ok) {
                    result.error(
                        "STORAGE_WRITE_FAILED",
                        "Storage write failed for key: credential:$credentialId",
                        null
                    )
                    return@withLock
                }
                result.success(null)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_WRITE_FAILED",
                    "Storage write failed for key: credential:$credentialId (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleGet(call: MethodCall, result: MethodChannel.Result) {
        val credentialId = call.argument<String>("credentialId")
        if (credentialId.isNullOrEmpty()) {
            result.error(
                "STORAGE_READ_FAILED",
                "Storage read failed for key: credential (Missing 'credentialId')",
                null
            )
            return
        }
        mutex.withLock {
            try {
                val raw = prefs.getString(credentialKey(credentialId), null)
                if (raw == null) {
                    result.success(null)
                    return@withLock
                }
                val map = decodeCredential(raw, credentialId)
                if (map == null) {
                    // Corruption surfaces as `null` for `get`; the asymmetry
                    // versus `update` is documented on the Dart bridge.
                    result.success(null)
                    return@withLock
                }
                result.success(map)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_READ_FAILED",
                    "Storage read failed for key: credential:$credentialId (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleGetByContract(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val contractId = call.argument<String>("contractId")
        if (contractId == null) {
            result.error(
                "STORAGE_READ_FAILED",
                "Storage read failed for key: credentials:contract (Missing 'contractId')",
                null
            )
            return
        }
        mutex.withLock {
            try {
                val matches = collectAllCredentials()
                    .filter { (it["contractId"] as? String) == contractId }
                result.success(matches)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_READ_FAILED",
                    "Storage read failed for key: credentials:contract:$contractId (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleGetAll(result: MethodChannel.Result) {
        mutex.withLock {
            try {
                result.success(collectAllCredentials())
            } catch (e: Exception) {
                result.error(
                    "STORAGE_READ_FAILED",
                    "Storage read failed for key: credentials:all (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleDelete(call: MethodCall, result: MethodChannel.Result) {
        val credentialId = call.argument<String>("credentialId")
        if (credentialId.isNullOrEmpty()) {
            result.error(
                "STORAGE_WRITE_FAILED",
                "Storage write failed for key: credential (Missing 'credentialId')",
                null
            )
            return
        }
        mutex.withLock {
            try {
                val ok = prefs.edit().remove(credentialKey(credentialId)).commit()
                if (!ok) {
                    result.error(
                        "STORAGE_WRITE_FAILED",
                        "Storage write failed for key: credential:$credentialId",
                        null
                    )
                    return@withLock
                }
                result.success(null)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_WRITE_FAILED",
                    "Storage write failed for key: credential:$credentialId (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleUpdate(call: MethodCall, result: MethodChannel.Result) {
        val credentialId = call.argument<String>("credentialId")
        if (credentialId.isNullOrEmpty()) {
            result.error(
                "STORAGE_WRITE_FAILED",
                "Storage write failed for key: credential (Missing 'credentialId')",
                null
            )
            return
        }
        val updates = mapArgument(call, "updates")
            ?: return result.error(
                "STORAGE_WRITE_FAILED",
                "Storage write failed for key: credential:$credentialId (Missing 'updates' argument)",
                null
            )
        mutex.withLock {
            try {
                val key = credentialKey(credentialId)
                val raw = prefs.getString(key, null)
                if (raw == null) {
                    result.error(
                        "CREDENTIAL_NOT_FOUND",
                        "Credential not found: $credentialId",
                        null
                    )
                    return@withLock
                }
                val existing = decodeCredentialOrNull(raw)
                if (existing == null) {
                    // Corruption surfaces as STORAGE_READ_FAILED on update —
                    // the read-modify-write sequence is not safe to continue.
                    result.error(
                        "STORAGE_READ_FAILED",
                        "Storage read failed for key: credential:$credentialId (corrupt entry)",
                        null
                    )
                    return@withLock
                }
                val merged = existing.toMutableMap()
                for ((updateKey, updateValue) in updates) {
                    if (updateValue != null) merged[updateKey] = updateValue
                }
                val payload = mapToJsonObject(merged).toString()
                val ok = prefs.edit().putString(key, payload).commit()
                if (!ok) {
                    result.error(
                        "STORAGE_WRITE_FAILED",
                        "Storage write failed for key: credential:$credentialId",
                        null
                    )
                    return@withLock
                }
                result.success(null)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_WRITE_FAILED",
                    "Storage write failed for key: credential:$credentialId (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleClear(result: MethodChannel.Result) {
        mutex.withLock {
            try {
                val editor = prefs.edit()
                val keys = prefs.all.keys
                for (key in keys) {
                    if (key.startsWith(CREDENTIAL_KEY_PREFIX) ||
                        key.startsWith(SESSION_KEY_PREFIX)
                    ) {
                        editor.remove(key)
                    }
                }
                val ok = editor.commit()
                if (!ok) {
                    result.error(
                        "STORAGE_WRITE_FAILED",
                        "Storage write failed for key: clear:all",
                        null
                    )
                    return@withLock
                }
                result.success(null)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_WRITE_FAILED",
                    "Storage write failed for key: clear:all (${e.message})",
                    e.message
                )
            }
        }
    }

    // ========================================================================
    // Session operations
    // ========================================================================

    private suspend fun handleSaveSession(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        val map = mapArgument(call, "session")
            ?: return result.error(
                "STORAGE_WRITE_FAILED",
                "Storage write failed for key: session (Missing 'session' argument)",
                null
            )
        mutex.withLock {
            try {
                val payload = mapToJsonObject(map).toString()
                val ok = prefs.edit().putString(SESSION_KEY, payload).commit()
                if (!ok) {
                    result.error(
                        "STORAGE_WRITE_FAILED",
                        "Storage write failed for key: session",
                        null
                    )
                    return@withLock
                }
                result.success(null)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_WRITE_FAILED",
                    "Storage write failed for key: session (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleGetSession(result: MethodChannel.Result) {
        mutex.withLock {
            try {
                val raw = prefs.getString(SESSION_KEY, null)
                if (raw == null) {
                    result.success(null)
                    return@withLock
                }
                val map = decodeSession(raw)
                if (map == null) {
                    result.success(null)
                    return@withLock
                }
                val expiresAt = (map["expiresAt"] as? Number)?.toLong()
                if (expiresAt != null && System.currentTimeMillis() >= expiresAt) {
                    val removed = prefs.edit().remove(SESSION_KEY).commit()
                    if (!removed) {
                        Log.w(TAG, "Failed to remove expired session from storage")
                    }
                    result.success(null)
                    return@withLock
                }
                result.success(map)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_READ_FAILED",
                    "Storage read failed for key: session (${e.message})",
                    e.message
                )
            }
        }
    }

    private suspend fun handleClearSession(result: MethodChannel.Result) {
        mutex.withLock {
            try {
                val ok = prefs.edit().remove(SESSION_KEY).commit()
                if (!ok) {
                    result.error(
                        "STORAGE_WRITE_FAILED",
                        "Storage write failed for key: session",
                        null
                    )
                    return@withLock
                }
                result.success(null)
            } catch (e: Exception) {
                result.error(
                    "STORAGE_WRITE_FAILED",
                    "Storage write failed for key: session (${e.message})",
                    e.message
                )
            }
        }
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    private fun collectAllCredentials(): List<Map<String, Any?>> {
        val all = mutableListOf<Map<String, Any?>>()
        val keys = prefs.all.keys
        for (key in keys) {
            if (!key.startsWith(CREDENTIAL_KEY_PREFIX)) continue
            val raw = prefs.getString(key, null) ?: continue
            val credentialId = key.removePrefix(CREDENTIAL_KEY_PREFIX)
            val decoded = decodeCredential(raw, credentialId)
            if (decoded != null) all.add(decoded)
        }
        return all
    }

    private fun decodeCredential(raw: String, credentialId: String): Map<String, Any?>? {
        return try {
            jsonObjectToMap(JSONObject(raw))
        } catch (e: JSONException) {
            Log.w(TAG, "Failed to deserialize credential $credentialId: ${e.message}")
            null
        }
    }

    private fun decodeCredentialOrNull(raw: String): Map<String, Any?>? {
        return try {
            jsonObjectToMap(JSONObject(raw))
        } catch (_: Exception) {
            null
        }
    }

    private fun decodeSession(raw: String): Map<String, Any?>? {
        return try {
            jsonObjectToMap(JSONObject(raw))
        } catch (e: JSONException) {
            Log.w(TAG, "Failed to deserialize session: ${e.message}")
            null
        }
    }

    private fun credentialKey(credentialId: String): String {
        return "$CREDENTIAL_KEY_PREFIX$credentialId"
    }

    private fun mapToJsonObject(map: Map<String, Any?>): JSONObject {
        val obj = JSONObject()
        for ((k, v) in map) {
            if (v == null) continue
            obj.put(k, encodeJsonValue(v))
        }
        return obj
    }

    // why: callers (`mapToJsonObject` and the nested map branch below)
    // already strip nulls before invoking, so the parameter is non-null;
    // tighten the signature to make that contract explicit.
    private fun encodeJsonValue(value: Any): Any {
        return when (value) {
            is Map<*, *> -> {
                val obj = JSONObject()
                for ((k, v) in value) {
                    if (k !is String || v == null) continue
                    obj.put(k, encodeJsonValue(v))
                }
                obj
            }
            is List<*> -> {
                val arr = JSONArray()
                for (item in value) {
                    if (item == null) continue
                    arr.put(encodeJsonValue(item))
                }
                arr
            }
            else -> value
        }
    }

    private fun jsonObjectToMap(obj: JSONObject): Map<String, Any?> {
        val out = mutableMapOf<String, Any?>()
        val keys = obj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = obj.get(key)
            out[key] = decodeJsonValue(value)
        }
        return out
    }

    private fun decodeJsonValue(value: Any?): Any? {
        return when (value) {
            is JSONObject -> jsonObjectToMap(value)
            is JSONArray -> {
                val list = mutableListOf<Any?>()
                for (i in 0 until value.length()) {
                    list.add(decodeJsonValue(value.get(i)))
                }
                list
            }
            JSONObject.NULL -> null
            else -> value
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun mapArgument(call: MethodCall, key: String): Map<String, Any?>? {
        val raw = call.argument<Any>(key) ?: return null
        if (raw is Map<*, *>) {
            val out = mutableMapOf<String, Any?>()
            for ((k, v) in raw) {
                if (k is String) out[k] = v
            }
            return out
        }
        return null
    }

    companion object {
        const val TAG: String = "AndroidStorageAdapter"
        const val PREFS_FILE_NAME: String = "stellar_smart_account_prefs"
        const val CREDENTIAL_KEY_PREFIX: String = "cred_"
        const val SESSION_KEY_PREFIX: String = "session_"
        const val SESSION_KEY: String = "${SESSION_KEY_PREFIX}current"
    }
}
