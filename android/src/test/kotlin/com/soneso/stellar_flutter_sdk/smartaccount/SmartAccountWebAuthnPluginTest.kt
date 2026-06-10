// Copyright (c) 2026 Soneso. All rights reserved.

package com.soneso.stellar_flutter_sdk.smartaccount

import android.app.Activity
import android.content.Context
import android.os.Build
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialResponse
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.coEvery
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.mockkStatic
import io.mockk.slot
import io.mockk.unmockkAll
import io.mockk.verify
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue

class SmartAccountWebAuthnPluginTest {

    private lateinit var context: Context
    private lateinit var activity: Activity
    private lateinit var credentialManager: CredentialManager
    private lateinit var plugin: SmartAccountWebAuthnPlugin

    @Suppress("DEPRECATION")
    private fun setSdkInt(value: Int) {
        val field = Build.VERSION::class.java.getField("SDK_INT")
        val modifiersField = java.lang.reflect.Field::class.java.getDeclaredField("modifiers")
        modifiersField.isAccessible = true
        modifiersField.setInt(field, field.modifiers and java.lang.reflect.Modifier.FINAL.inv())
        field.isAccessible = true
        field.setInt(null, value)
    }

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    @Before
    fun setUp() {
        Dispatchers.setMain(UnconfinedTestDispatcher())
        context = mockk(relaxed = true)
        activity = mockk(relaxed = true)
        credentialManager = mockk(relaxed = true)

        mockkStatic(CredentialManager::class)
        every { CredentialManager.create(any()) } returns credentialManager

        // Default to API 28 (Pie) so WebAuthn is supported.
        setSdkInt(28)

        plugin = SmartAccountWebAuthnPlugin(context)
        plugin.attachActivity(activity)
    }

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    @After
    fun tearDown() {
        plugin.dispose()
        unmockkAll()
        Dispatchers.resetMain()
    }

    private fun makeRegistrationCall(): MethodCall {
        return MethodCall(
            "register",
            mapOf(
                "rpId" to "example.com",
                "rpName" to "Example",
                "challenge" to byteArrayOf(0x01, 0x02, 0x03),
                "userId" to byteArrayOf(0x10, 0x11),
                "userName" to "alice",
                "timeout" to 60_000L
            )
        )
    }

    private fun makeAuthenticationCall(): MethodCall {
        return MethodCall(
            "authenticate",
            mapOf(
                "rpId" to "example.com",
                "challenge" to byteArrayOf(0x20, 0x21),
                "timeout" to 60_000L
            )
        )
    }

    private fun captureResult(): Pair<MethodChannel.Result, () -> CapturedResponse> {
        val successSlot = slot<Any?>()
        val errorCode = slot<String>()
        val errorMessage = slot<String>()
        val errorDetails = slot<Any?>()
        val notImplemented = slot<Boolean>()
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

    @Test
    fun register_apiBelow28_throwsNotSupported() {
        setSdkInt(27)
        val (result, getCaptured) = captureResult()

        plugin.onMethodCall(makeRegistrationCall(), result)

        val response = getCaptured() as CapturedResponse.Failure
        assertEquals("WEBAUTHN_NOT_SUPPORTED", response.code)
        assertTrue(response.message!!.contains("API 28"))
    }

    @Test
    fun register_happyPath_callsCredentialManager_returnsResultMap() = runBlocking {
        val response = mockk<CreatePublicKeyCredentialResponse>()
        every { response.registrationResponseJson } returns SAMPLE_REGISTRATION_JSON
        coEvery { credentialManager.createCredential(any<Context>(), any()) } returns response

        val (result, getCaptured) = captureResult()
        plugin.onMethodCall(makeRegistrationCall(), result)

        val captured = getCaptured()
        assertTrue(
            "Expected success but got $captured",
            captured is CapturedResponse.Success
        )
        @Suppress("UNCHECKED_CAST")
        val map = (captured as CapturedResponse.Success).value as Map<String, Any?>
        assertNotNull(map["credentialId"])
        assertNotNull(map["publicKey"])
        assertNotNull(map["attestationObject"])
    }

    @Test
    fun register_credentialManagerCancellation_returnsCancelledPlatformException() =
        runBlocking {
            val cancellation = mockk<CreateCredentialCancellationException>(relaxed = true)
            coEvery {
                credentialManager.createCredential(any<Context>(), any())
            } throws cancellation

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeRegistrationCall(), result)

            val response = getCaptured() as CapturedResponse.Failure
            assertEquals("WEBAUTHN_CANCELLED", response.code)
        }

    @Test
    fun register_credentialManagerGenericException_returnsRegistrationFailedPlatformException() =
        runBlocking {
            val genericFailure = mockk<CreateCredentialException>(relaxed = true) {
                every { type } returns "create_failure_type"
                every { message } returns "Authenticator unreachable"
            }
            coEvery {
                credentialManager.createCredential(any<Context>(), any())
            } throws genericFailure

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeRegistrationCall(), result)

            val response = getCaptured() as CapturedResponse.Failure
            assertEquals("WEBAUTHN_REGISTRATION_FAILED", response.code)
            assertTrue(response.message!!.contains("create_failure_type"))
        }

    @Test
    fun register_unexpectedCredentialType_returnsRegistrationFailedPlatformException() =
        runBlocking {
            // Returning a non-CreatePublicKeyCredentialResponse from the
            // mock causes the cast to fail in the plugin and emit a
            // registration-failed error.
            val somethingElse = mockk<androidx.credentials.Credential>(relaxed = true)
            coEvery {
                credentialManager.createCredential(any<Context>(), any())
            } returns somethingElse

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeRegistrationCall(), result)

            val response = getCaptured() as CapturedResponse.Failure
            assertEquals("WEBAUTHN_REGISTRATION_FAILED", response.code)
        }

    @Test
    fun authenticate_happyPath_returnsResultMap() = runBlocking {
        val publicKey = mockk<PublicKeyCredential>()
        every { publicKey.authenticationResponseJson } returns SAMPLE_AUTHENTICATION_JSON
        val response = mockk<GetCredentialResponse>()
        every { response.credential } returns publicKey
        coEvery { credentialManager.getCredential(any<Context>(), any()) } returns response

        val (result, getCaptured) = captureResult()
        plugin.onMethodCall(makeAuthenticationCall(), result)

        val captured = getCaptured()
        assertTrue(
            "Expected success but got $captured",
            captured is CapturedResponse.Success
        )
        @Suppress("UNCHECKED_CAST")
        val map = (captured as CapturedResponse.Success).value as Map<String, Any?>
        assertNotNull(map["credentialId"])
        assertNotNull(map["authenticatorData"])
        assertNotNull(map["clientDataJSON"])
        assertNotNull(map["signature"])
    }

    @Test
    fun authenticate_noCredentialException_returnsAuthenticationFailedWithRpIdInMessage() =
        runBlocking {
            val noCred = mockk<NoCredentialException>(relaxed = true)
            coEvery {
                credentialManager.getCredential(any<Context>(), any())
            } throws noCred

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeAuthenticationCall(), result)

            val response = getCaptured() as CapturedResponse.Failure
            assertEquals("WEBAUTHN_AUTHENTICATION_FAILED", response.code)
            assertTrue(response.message!!.contains("example.com"))
        }

    @Test
    fun authenticate_cancellationException_returnsCancelledPlatformException() =
        runBlocking {
            val cancellation =
                mockk<GetCredentialCancellationException>(relaxed = true)
            coEvery {
                credentialManager.getCredential(any<Context>(), any())
            } throws cancellation

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeAuthenticationCall(), result)

            val response = getCaptured() as CapturedResponse.Failure
            assertEquals("WEBAUTHN_CANCELLED", response.code)
        }

    @Test
    fun authenticate_genericGetException_returnsAuthenticationFailedPlatformException() =
        runBlocking {
            val genericFailure = mockk<GetCredentialException>(relaxed = true) {
                every { type } returns "get_failure_type"
                every { message } returns "Reader error"
            }
            coEvery {
                credentialManager.getCredential(any<Context>(), any())
            } throws genericFailure

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeAuthenticationCall(), result)

            val response = getCaptured() as CapturedResponse.Failure
            assertEquals("WEBAUTHN_AUTHENTICATION_FAILED", response.code)
            assertTrue(response.message!!.contains("get_failure_type"))
        }

    @Test
    fun authenticate_noActivityAttached_returnsAuthenticationFailedPlatformException() {
        plugin.detachActivity()
        val (result, getCaptured) = captureResult()

        plugin.onMethodCall(makeAuthenticationCall(), result)

        val response = getCaptured() as CapturedResponse.Failure
        assertEquals("WEBAUTHN_AUTHENTICATION_FAILED", response.code)
        assertTrue(response.message!!.contains("Activity"))
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

    companion object {
        // Synthetic registration response with a known attestation object
        // that contains an embedded ES256 COSE key. The attestation object
        // is base64url-encoded plain text — the plugin parses it with the
        // self-contained CBOR parser. Constructed by hand rather than
        // captured from a real device so the test is hermetic.
        private const val SAMPLE_REGISTRATION_JSON: String =
            "{\"id\":\"AQID\",\"rawId\":\"AQID\",\"type\":\"public-key\",\"response\":{" +
                "\"attestationObject\":\"" +
                "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YVilSZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzu" +
                "oMdl21FAAAAALraVWanqkAfvZZFYZpVEg0AIAECA6UBAgMmIAEhWCABAgMEBQYHCAkKCwwNDg8QER" +
                "ITFBUWFxgZGhscHR4fIlgggIGCg4SFhoeIiYqLjI2Oj5CRkpOUlZaXmJmam5ydnp8" +
                "\",\"clientDataJSON\":\"eyJ0eXBlIjoiYmxhaCJ9\"}}"
        private const val SAMPLE_AUTHENTICATION_JSON: String =
            "{\"id\":\"AQID\",\"rawId\":\"AQID\",\"type\":\"public-key\",\"response\":{" +
                "\"authenticatorData\":\"AQID\",\"clientDataJSON\":\"BAUG\",\"signature\":\"BwgJ\"}}"
    }
}
