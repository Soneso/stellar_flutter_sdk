// Copyright (c) 2026 Soneso. All rights reserved.

package com.soneso.stellar_flutter_sdk.smartaccount

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.unmockkAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class AndroidStorageAdapterTest {

    private lateinit var context: Context
    private lateinit var prefs: SharedPreferences
    private lateinit var editor: SharedPreferences.Editor
    private val storage = mutableMapOf<String, String?>()

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    @Before
    fun setUp() {
        Dispatchers.setMain(UnconfinedTestDispatcher())
        context = mockk(relaxed = true)
        editor = mockk(relaxed = true)
        prefs = mockk(relaxed = true)

        // Backing-store behaviour for the mock SharedPreferences.
        every { prefs.getString(any(), any()) } answers {
            val key = it.invocation.args[0] as String
            val default = it.invocation.args[1] as String?
            storage[key] ?: default
        }
        every { prefs.all } answers {
            // SharedPreferences.all returns Map<String, *> (Object on the JVM).
            storage.toMap()
        }
        every { prefs.edit() } returns editor
        every { editor.putString(any(), any()) } answers {
            val key = it.invocation.args[0] as String
            val value = it.invocation.args[1] as String?
            storage[key] = value
            editor
        }
        every { editor.remove(any()) } answers {
            val key = it.invocation.args[0] as String
            storage.remove(key)
            editor
        }
        every { editor.commit() } returns true
        every { editor.apply() } returns Unit

        // Bypass EncryptedSharedPreferences.create to return our mock.
        mockkStatic(EncryptedSharedPreferences::class)
        every {
            EncryptedSharedPreferences.create(
                any<Context>(),
                any<String>(),
                any<MasterKey>(),
                any(),
                any()
            )
        } returns prefs

        // Bypass MasterKey.Builder by mocking the class.
        mockkStatic(MasterKey::class)
        val masterKey = mockk<MasterKey>(relaxed = true)
        val builder = mockk<MasterKey.Builder>(relaxed = true)
        every { builder.setKeyScheme(any()) } returns builder
        every { builder.build() } returns masterKey
        // The Builder ctor is invoked as `MasterKey.Builder(context)`; mockk
        // intercepts it via the mockkConstructor approach.
        io.mockk.mockkConstructor(MasterKey.Builder::class)
        every { anyConstructed<MasterKey.Builder>().setKeyScheme(any()) } returns builder
        every { anyConstructed<MasterKey.Builder>().build() } returns masterKey
    }

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    @After
    fun tearDown() {
        storage.clear()
        unmockkAll()
        Dispatchers.resetMain()
    }

    private fun newAdapter(): AndroidStorageAdapter = AndroidStorageAdapter(context)

    private fun captureResult(): Pair<MethodChannel.Result, () -> CapturedResponse> {
        val captured = mutableListOf<CapturedResponse>()
        val result = object : MethodChannel.Result {
            override fun success(value: Any?) {
                captured.add(CapturedResponse.Success(value))
            }
            override fun error(code: String, message: String?, details: Any?) {
                captured.add(CapturedResponse.Failure(code, message, details))
            }
            override fun notImplemented() {
                captured.add(CapturedResponse.NotImplemented)
            }
        }
        return result to { captured.first() }
    }

    private fun credentialMap(
        id: String = "cred-001",
        contractId: String? = "CBCD0",
    ): Map<String, Any?> = buildMap {
        put("credentialId", id)
        put("publicKeyHex", "0401020304")
        if (contractId != null) put("contractId", contractId)
        put("deploymentStatus", "pending")
        put("createdAt", 1_700_000_000_000L)
        put("isPrimary", true)
        put("transports", listOf("internal"))
    }

    private suspend fun call(
        adapter: AndroidStorageAdapter,
        method: String,
        args: Map<String, Any?>? = null
    ): CapturedResponse {
        val (result, get) = captureResult()
        adapter.onMethodCall(MethodCall(method, args), result)
        // Allow the launched coroutine to resolve under the unconfined test dispatcher.
        return get()
    }

    @Test
    fun save_and_get_credential_round_trip() = runBlocking {
        val adapter = newAdapter()
        val saved = call(adapter, "storage.save", mapOf("credential" to credentialMap()))
        assertTrue("save should succeed but was $saved", saved is CapturedResponse.Success)

        val loaded = call(adapter, "storage.get", mapOf("credentialId" to "cred-001"))
        @Suppress("UNCHECKED_CAST")
        val map = (loaded as CapturedResponse.Success).value as Map<String, Any?>
        assertEquals("cred-001", map["credentialId"])
    }

    @Test
    fun save_and_get_session_round_trip() = runBlocking {
        val adapter = newAdapter()
        val sessionMap = mapOf<String, Any?>(
            "credentialId" to "cred-001",
            "contractId" to "CBCD0",
            "connectedAt" to 1_700_000_000_000L,
            "expiresAt" to 9_999_999_999_000L
        )
        val saved = call(adapter, "storage.saveSession", mapOf("session" to sessionMap))
        assertTrue(saved is CapturedResponse.Success)

        val loaded = call(adapter, "storage.getSession")
        @Suppress("UNCHECKED_CAST")
        val map = (loaded as CapturedResponse.Success).value as Map<String, Any?>
        assertEquals("cred-001", map["credentialId"])
    }

    @Test
    fun get_by_contract_id_filters() = runBlocking {
        val adapter = newAdapter()
        call(adapter, "storage.save", mapOf("credential" to credentialMap(id = "c1", contractId = "A")))
        call(adapter, "storage.save", mapOf("credential" to credentialMap(id = "c2", contractId = "B")))
        call(adapter, "storage.save", mapOf("credential" to credentialMap(id = "c3", contractId = "A")))

        val resp = call(adapter, "storage.getByContract", mapOf("contractId" to "A"))
        @Suppress("UNCHECKED_CAST")
        val list = (resp as CapturedResponse.Success).value as List<Map<String, Any?>>
        assertEquals(2, list.size)
        assertTrue(list.all { it["contractId"] == "A" })
    }

    @Test
    fun clear_removes_only_credential_and_session_prefixes() = runBlocking {
        val adapter = newAdapter()
        call(adapter, "storage.save", mapOf("credential" to credentialMap(id = "c1")))
        // Inject an unrelated key directly into the backing store.
        storage["unrelated_key"] = "preserved"

        val cleared = call(adapter, "storage.clear")
        assertTrue(cleared is CapturedResponse.Success)
        assertNull(storage["cred_c1"])
        assertEquals("preserved", storage["unrelated_key"])
    }

    @Test
    fun get_corrupted_credential_returns_null_logged() = runBlocking {
        val adapter = newAdapter()
        // Inject a corrupt entry directly so the parser fails.
        storage["cred_corrupt"] = "not-valid-json"

        val resp = call(adapter, "storage.get", mapOf("credentialId" to "corrupt"))
        assertTrue(resp is CapturedResponse.Success)
        assertNull((resp as CapturedResponse.Success).value)
    }

    @Test
    fun get_all_skips_corrupted_credentials_logged() = runBlocking {
        val adapter = newAdapter()
        call(adapter, "storage.save", mapOf("credential" to credentialMap(id = "good")))
        storage["cred_corrupt"] = "not-valid-json"

        val resp = call(adapter, "storage.getAll")
        @Suppress("UNCHECKED_CAST")
        val list = (resp as CapturedResponse.Success).value as List<Map<String, Any?>>
        assertEquals(1, list.size)
        assertEquals("good", list.first()["credentialId"])
    }

    @Test
    fun update_corrupted_credential_throws_storage_read_failed() = runBlocking {
        val adapter = newAdapter()
        storage["cred_corrupt"] = "not-valid-json"

        val resp = call(
            adapter,
            "storage.update",
            mapOf(
                "credentialId" to "corrupt",
                "updates" to mapOf<String, Any?>("nickname" to "x")
            )
        )
        val failure = resp as CapturedResponse.Failure
        assertEquals("STORAGE_READ_FAILED", failure.code)
    }

    @Test
    fun update_credential_atomic_under_mutex() = runBlocking {
        val adapter = newAdapter()
        call(adapter, "storage.save", mapOf("credential" to credentialMap()))

        val updateResp = call(
            adapter,
            "storage.update",
            mapOf(
                "credentialId" to "cred-001",
                "updates" to mapOf<String, Any?>(
                    "nickname" to "Updated",
                    "lastUsedAt" to 1_700_001_000_000L
                )
            )
        )
        assertTrue(updateResp is CapturedResponse.Success)

        val loaded = call(adapter, "storage.get", mapOf("credentialId" to "cred-001"))
        @Suppress("UNCHECKED_CAST")
        val map = (loaded as CapturedResponse.Success).value as Map<String, Any?>
        assertEquals("Updated", map["nickname"])
        assertEquals(1_700_001_000_000L, (map["lastUsedAt"] as Number).toLong())
    }

    @Test
    fun test_concurrent_writes_10_parallel_no_partial_state() = runBlocking {
        val adapter = newAdapter()

        // Launch 10 concurrent save invocations on the default dispatcher; the
        // adapter's internal Mutex must serialise writes so every credential
        // lands in the backing store exactly once.
        val responseLock = Mutex()
        val savedResponses = mutableListOf<CapturedResponse>()
        val pending = (0 until 10).map { idx ->
            async(Dispatchers.Default) {
                val deferredResult = kotlinx.coroutines.CompletableDeferred<CapturedResponse>()
                val result = object : MethodChannel.Result {
                    override fun success(value: Any?) {
                        deferredResult.complete(CapturedResponse.Success(value))
                    }
                    override fun error(code: String, message: String?, details: Any?) {
                        deferredResult.complete(CapturedResponse.Failure(code, message, details))
                    }
                    override fun notImplemented() {
                        deferredResult.complete(CapturedResponse.NotImplemented)
                    }
                }
                adapter.onMethodCall(
                    MethodCall(
                        "storage.save",
                        mapOf("credential" to credentialMap(id = "cred-$idx"))
                    ),
                    result
                )
                val captured = deferredResult.await()
                responseLock.withLock { savedResponses.add(captured) }
            }
        }
        pending.awaitAll()

        // Every write must have succeeded.
        assertEquals(10, savedResponses.size)
        assertTrue(
            "Every concurrent save must succeed",
            savedResponses.all { it is CapturedResponse.Success }
        )

        // The aggregate view via getAll() must enumerate exactly the 10
        // credential ids we wrote — no missing entries (lost update) and no
        // duplicates (HashMap corruption).
        val getAllResp = call(adapter, "storage.getAll")
        @Suppress("UNCHECKED_CAST")
        val list = (getAllResp as CapturedResponse.Success).value as List<Map<String, Any?>>
        assertEquals(10, list.size)
        val ids = list.map { it["credentialId"] as String }.toSet()
        assertEquals(10, ids.size)
        assertEquals(
            (0 until 10).map { "cred-$it" }.toSet(),
            ids
        )
    }

    @Test
    fun test_save_throws_storage_write_failed_when_commit_returns_false() = runBlocking {
        val adapter = newAdapter()

        // Override the editor so commit() returns false on this single
        // invocation — the adapter must surface STORAGE_WRITE_FAILED.
        every { editor.commit() } returns false

        val resp = call(
            adapter,
            "storage.save",
            mapOf("credential" to credentialMap(id = "cred-fail"))
        )
        val failure = resp as CapturedResponse.Failure
        assertEquals("STORAGE_WRITE_FAILED", failure.code)
        assertNotNull(failure.message)
    }

    @Test
    fun update_missing_credential_returns_credential_not_found() = runBlocking {
        val adapter = newAdapter()
        val resp = call(
            adapter,
            "storage.update",
            mapOf(
                "credentialId" to "absent",
                "updates" to mapOf<String, Any?>("nickname" to "x")
            )
        )
        val failure = resp as CapturedResponse.Failure
        assertEquals("CREDENTIAL_NOT_FOUND", failure.code)
        assertNotNull(failure.message)
    }

    private sealed class CapturedResponse {
        data class Success(val value: Any?) : CapturedResponse()
        data class Failure(
            val code: String,
            val message: String?,
            val details: Any?
        ) : CapturedResponse()
        object NotImplemented : CapturedResponse()
    }
}
