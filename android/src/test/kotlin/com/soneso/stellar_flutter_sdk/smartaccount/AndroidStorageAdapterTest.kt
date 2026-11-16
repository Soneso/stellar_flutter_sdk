// Copyright (c) 2026 Soneso. All rights reserved.

package com.soneso.stellar_flutter_sdk.smartaccount

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkConstructor
import io.mockk.mockkStatic
import io.mockk.unmockkAll
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.json.JSONException
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

// The adapter has no API-level gate; API 28 matches the WebAuthn tests, so
// both classes run on one Robolectric runtime.
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class AndroidStorageAdapterTest {

    private lateinit var context: Context
    private lateinit var prefs: SharedPreferences
    private lateinit var editor: SharedPreferences.Editor
    private val storage = mutableMapOf<String, String?>()
    private val adapters = mutableListOf<AndroidStorageAdapter>()
    private val gates = mutableListOf<ContentionGate>()
    private val replies = mutableListOf<CompletableDeferred<CapturedResponse>>()

    @Before
    fun setUp() {
        context = mockk(relaxed = true)
        editor = mockk(relaxed = true)
        prefs = mockk(relaxed = true)

        // Backing-store behaviour for the mock SharedPreferences.
        every { prefs.getString(any(), any()) } answers {
            storage[firstArg<String>()] ?: secondArg<String?>()
        }
        every { prefs.all } answers {
            // SharedPreferences.all returns Map<String, *> (Object on the JVM).
            storage.toMap()
        }
        every { prefs.edit() } returns editor
        every { editor.putString(any(), any()) } answers {
            storage[firstArg<String>()] = secondArg<String?>()
            editor
        }
        every { editor.remove(any()) } answers {
            storage.remove(firstArg<String>())
            editor
        }
        every { editor.commit() } returns true

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

        // The adapter calls `MasterKey.Builder(context).setKeyScheme(...).build()`;
        // the constructed builder hands over to a mock whose build() returns
        // the master key.
        val masterKey = mockk<MasterKey>(relaxed = true)
        val builder = mockk<MasterKey.Builder>(relaxed = true)
        every { builder.build() } returns masterKey
        mockkConstructor(MasterKey.Builder::class)
        every { anyConstructed<MasterKey.Builder>().setKeyScheme(any()) } returns builder
    }

    @After
    fun tearDown() {
        // dispose() cancels the adapter's scope without joining it, and a
        // worker held at a gate does not see the cancellation. Release the
        // gates and wait for every started call to reply, so no worker
        // touches the storage or the mocks after they are reset.
        gates.forEach { it.release() }
        try {
            runBlocking { withTimeout(RESULT_TIMEOUT_MS) { replies.awaitAll() } }
        } finally {
            adapters.forEach { it.dispose() }
            storage.clear()
            unmockkAll()
        }
    }

    private fun newAdapter(): AndroidStorageAdapter =
        AndroidStorageAdapter(context).also { adapters.add(it) }

    private fun deferredResult(): Pair<MethodChannel.Result, CompletableDeferred<CapturedResponse>> {
        val response = CompletableDeferred<CapturedResponse>()
        val result = object : MethodChannel.Result {
            override fun success(value: Any?) {
                response.complete(CapturedResponse.Success(value))
            }
            override fun error(code: String, message: String?, details: Any?) {
                response.complete(CapturedResponse.Failure(code, message, details))
            }
            override fun notImplemented() {
                response.complete(CapturedResponse.NotImplemented)
            }
        }
        return result to response
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

    // Starts the call and returns its pending reply; the adapter answers from
    // its own coroutine on Dispatchers.IO.
    private fun start(
        adapter: AndroidStorageAdapter,
        method: String,
        args: Map<String, Any?>? = null
    ): CompletableDeferred<CapturedResponse> {
        val (result, response) = deferredResult()
        replies.add(response)
        adapter.onMethodCall(MethodCall(method, args), result)
        return response
    }

    private suspend fun call(
        adapter: AndroidStorageAdapter,
        method: String,
        args: Map<String, Any?>? = null
    ): CapturedResponse {
        val response = start(adapter, method, args)
        return withTimeout(RESULT_TIMEOUT_MS) { response.await() }
    }

    private fun warningsLogged(): List<String> =
        ShadowLog.getLogsForTag(AndroidStorageAdapter.TAG)
            .filter { it.type == Log.WARN }
            .map { it.msg }

    private fun jsonParseError(raw: String): String =
        try {
            JSONObject(raw)
            throw AssertionError("$raw parses as a JSON object")
        } catch (e: JSONException) {
            e.message!!
        }

    @Test
    fun save_and_get_credential_round_trip() = runBlocking {
        val adapter = newAdapter()
        val saved = call(adapter, "storage.save", mapOf("credential" to credentialMap()))
        assertEquals(CapturedResponse.Success(null), saved)

        val loaded = call(adapter, "storage.get", mapOf("credentialId" to "cred-001"))
        assertEquals(CapturedResponse.Success(credentialMap()), loaded)
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
        assertEquals(CapturedResponse.Success(null), saved)

        val loaded = call(adapter, "storage.getSession")
        assertEquals(CapturedResponse.Success(sessionMap), loaded)
    }

    @Test
    fun get_by_contract_id_filters() = runBlocking {
        val adapter = newAdapter()
        val c1 = credentialMap(id = "c1", contractId = "A")
        val c2 = credentialMap(id = "c2", contractId = "B")
        val c3 = credentialMap(id = "c3", contractId = "A")
        for (credential in listOf(c1, c2, c3)) {
            val saved = call(adapter, "storage.save", mapOf("credential" to credential))
            assertEquals(CapturedResponse.Success(null), saved)
        }

        val resp = call(adapter, "storage.getByContract", mapOf("contractId" to "A"))
        @Suppress("UNCHECKED_CAST")
        val list = (resp as CapturedResponse.Success).value as List<Map<String, Any?>>
        // SharedPreferences does not order its entries, so the result is
        // compared as a set; the size check rules out duplicates.
        assertEquals(2, list.size)
        assertEquals(setOf(c1, c3), list.toSet())
    }

    @Test
    fun clear_removes_only_credential_and_session_prefixes() = runBlocking {
        val adapter = newAdapter()
        val session = mapOf<String, Any?>("credentialId" to "c1", "expiresAt" to 9_999_999_999_000L)
        assertEquals(
            CapturedResponse.Success(null),
            call(adapter, "storage.save", mapOf("credential" to credentialMap(id = "c1")))
        )
        assertEquals(
            CapturedResponse.Success(null),
            call(adapter, "storage.saveSession", mapOf("session" to session))
        )
        // Inject an unrelated key directly into the backing store.
        storage["unrelated_key"] = "preserved"
        assertEquals(setOf("cred_c1", "session_current", "unrelated_key"), storage.keys)

        val cleared = call(adapter, "storage.clear")
        assertEquals(CapturedResponse.Success(null), cleared)
        assertEquals(mapOf("unrelated_key" to "preserved"), storage.toMap())
    }

    @Test
    fun get_corrupted_credential_returns_null_logged() = runBlocking {
        val adapter = newAdapter()
        // Inject a corrupt entry directly so the parser fails.
        storage["cred_corrupt"] = "not-valid-json"

        val resp = call(adapter, "storage.get", mapOf("credentialId" to "corrupt"))
        assertEquals(CapturedResponse.Success(null), resp)
        assertEquals(
            listOf("Failed to deserialize credential corrupt: ${jsonParseError("not-valid-json")}"),
            warningsLogged()
        )
    }

    @Test
    fun get_all_skips_corrupted_credentials_logged() = runBlocking {
        val adapter = newAdapter()
        val good = credentialMap(id = "good")
        assertEquals(
            CapturedResponse.Success(null),
            call(adapter, "storage.save", mapOf("credential" to good))
        )
        storage["cred_corrupt"] = "not-valid-json"

        val resp = call(adapter, "storage.getAll")
        assertEquals(CapturedResponse.Success(listOf(good)), resp)
        assertEquals(
            listOf("Failed to deserialize credential corrupt: ${jsonParseError("not-valid-json")}"),
            warningsLogged()
        )
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
        assertEquals(
            CapturedResponse.Failure(
                "STORAGE_READ_FAILED",
                "Storage read failed for key: credential:corrupt (corrupt entry)",
                null
            ),
            resp
        )
        assertEquals("not-valid-json", storage["cred_corrupt"])
    }

    @Test
    fun update_merges_updates_into_stored_credential() = runBlocking {
        val adapter = newAdapter()
        assertEquals(
            CapturedResponse.Success(null),
            call(adapter, "storage.save", mapOf("credential" to credentialMap()))
        )

        val updates = mapOf<String, Any?>(
            "nickname" to "Updated",
            "lastUsedAt" to 1_700_001_000_000L
        )
        val updateResp = call(
            adapter,
            "storage.update",
            mapOf("credentialId" to "cred-001", "updates" to updates)
        )
        assertEquals(CapturedResponse.Success(null), updateResp)

        val loaded = call(adapter, "storage.get", mapOf("credentialId" to "cred-001"))
        assertEquals(CapturedResponse.Success(credentialMap() + updates), loaded)
    }

    @Test
    fun update_credential_atomic_under_mutex() = runBlocking {
        val adapter = newAdapter()
        assertEquals(
            CapturedResponse.Success(null),
            call(adapter, "storage.save", mapOf("credential" to credentialMap()))
        )

        // Each update reads the stored credential, merges and writes it back.
        // A read takes the stored value before it enters the gate, so two
        // updates whose read-modify-write sequences are not serialised both
        // merge into the old entry and the later write drops the other
        // update's field.
        val gate = ContentionGate().also { gates.add(it) }
        every { prefs.getString("cred_cred-001", any()) } answers {
            val stored = storage[firstArg<String>()] ?: secondArg<String?>()
            gate.enter()
            stored
        }

        val nickname = start(
            adapter,
            "storage.update",
            gate.track(
                mapOf(
                    "credentialId" to "cred-001",
                    "updates" to mapOf<String, Any?>("nickname" to "Updated")
                )
            )
        )
        val lastUsedAt = start(
            adapter,
            "storage.update",
            gate.track(
                mapOf(
                    "credentialId" to "cred-001",
                    "updates" to mapOf<String, Any?>("lastUsedAt" to 1_700_001_000_000L)
                )
            )
        )
        val responses = withTimeout(RESULT_TIMEOUT_MS) { listOf(nickname, lastUsedAt).awaitAll() }
        gate.assertCoordinated()
        assertEquals(List(2) { CapturedResponse.Success(null) }, responses)

        val loaded = call(adapter, "storage.get", mapOf("credentialId" to "cred-001"))
        assertEquals(
            CapturedResponse.Success(
                credentialMap() + mapOf("nickname" to "Updated", "lastUsedAt" to 1_700_001_000_000L)
            ),
            loaded
        )
    }

    @Test
    fun test_concurrent_writes_10_parallel_no_partial_state() = runBlocking {
        val adapter = newAdapter()

        // A write section runs from putString to commit. The first writer
        // waits inside its section for a second writer, so writes that are
        // not serialised overlap and raise maxConcurrentWrites above 1.
        val gate = ContentionGate().also { gates.add(it) }
        val concurrentWrites = AtomicInteger(0)
        val maxConcurrentWrites = AtomicInteger(0)
        every { editor.putString(any(), any()) } answers {
            val active = concurrentWrites.incrementAndGet()
            maxConcurrentWrites.accumulateAndGet(active) { a, b -> maxOf(a, b) }
            gate.enter()
            storage[firstArg<String>()] = secondArg<String?>()
            editor
        }
        every { editor.commit() } answers {
            concurrentWrites.decrementAndGet()
            true
        }

        // Start 10 saves at once; the adapter's internal Mutex must serialise
        // the writes so every credential lands in the backing store exactly
        // once.
        val pending = (0 until 10).map { idx ->
            start(
                adapter,
                "storage.save",
                gate.track(mapOf("credential" to credentialMap(id = "cred-$idx")))
            )
        }
        val saved = withTimeout(RESULT_TIMEOUT_MS) { pending.awaitAll() }
        gate.assertCoordinated()

        assertEquals(List(10) { CapturedResponse.Success(null) }, saved)
        assertEquals("Write sections must not overlap", 1, maxConcurrentWrites.get())

        // The aggregate view via getAll() must enumerate exactly the 10
        // credentials we wrote: no missing entries (lost update) and no
        // duplicates (HashMap corruption).
        val getAllResp = call(adapter, "storage.getAll")
        @Suppress("UNCHECKED_CAST")
        val list = (getAllResp as CapturedResponse.Success).value as List<Map<String, Any?>>
        assertEquals(10, list.size)
        assertEquals((0 until 10).map { credentialMap(id = "cred-$it") }.toSet(), list.toSet())
    }

    @Test
    fun test_save_throws_storage_write_failed_when_commit_returns_false() = runBlocking {
        val adapter = newAdapter()

        // commit() reports a failed write; the adapter must surface
        // STORAGE_WRITE_FAILED.
        every { editor.commit() } returns false

        val resp = call(
            adapter,
            "storage.save",
            mapOf("credential" to credentialMap(id = "cred-fail"))
        )
        assertEquals(
            CapturedResponse.Failure(
                "STORAGE_WRITE_FAILED",
                "Storage write failed for key: credential:cred-fail",
                null
            ),
            resp
        )
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
        assertEquals(
            CapturedResponse.Failure("CREDENTIAL_NOT_FOUND", "Credential not found: absent", null),
            resp
        )
    }

    // Holds the first caller of enter() inside its section until a second
    // operation is in flight. An operation reports its start on the first
    // read of the arguments from track(), which the adapter does on its
    // worker before it takes the lock. Once a second operation has started,
    // the first gives it ENTRY_WAIT_MS to call enter() too: code that
    // serialises the section keeps it out, code that does not lets it in.
    // If no second operation starts within START_TIMEOUT_MS, the first goes
    // on alone and assertCoordinated() fails the test.
    private class ContentionGate {
        private val startedOperations = AtomicInteger(0)
        private val secondStarted = CountDownLatch(1)
        private val firstEntered = AtomicBoolean(false)
        private val secondEntered = CountDownLatch(1)
        @Volatile private var stalled = false

        fun track(args: Map<String, Any?>): Map<String, Any?> =
            object : HashMap<String, Any?>(args) {
                private val reported = AtomicBoolean(false)

                override fun get(key: String): Any? {
                    if (reported.compareAndSet(false, true) &&
                        startedOperations.incrementAndGet() == 2
                    ) {
                        secondStarted.countDown()
                    }
                    return super.get(key)
                }
            }

        fun enter() {
            if (!firstEntered.compareAndSet(false, true)) {
                secondEntered.countDown()
                return
            }
            if (!secondStarted.await(START_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
                stalled = true
                return
            }
            secondEntered.await(ENTRY_WAIT_MS, TimeUnit.MILLISECONDS)
        }

        fun assertCoordinated() {
            assertFalse(
                "Stalled coordination: no second operation started within $START_TIMEOUT_MS ms",
                stalled
            )
        }

        fun release() {
            secondStarted.countDown()
            secondEntered.countDown()
        }
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

    private companion object {
        const val RESULT_TIMEOUT_MS = 5_000L
        const val START_TIMEOUT_MS = 2_000L
        const val ENTRY_WAIT_MS = 500L
    }
}
