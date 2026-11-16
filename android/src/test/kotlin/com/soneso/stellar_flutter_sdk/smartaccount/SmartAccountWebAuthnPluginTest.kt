// Copyright (c) 2026 Soneso. All rights reserved.

package com.soneso.stellar_flutter_sdk.smartaccount

import android.app.Activity
import android.content.Context
import androidx.credentials.CreateCredentialRequest
import androidx.credentials.CreatePasswordResponse
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.exceptions.NoCredentialException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.mockk.coEvery
import io.mockk.every
import io.mockk.mockk
import io.mockk.mockkObject
import io.mockk.slot
import io.mockk.unmockkAll
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import kotlinx.serialization.json.Json
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.Base64

// API 28 (Pie) is the lowest level on which the plugin supports WebAuthn.
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class SmartAccountWebAuthnPluginTest {

    private lateinit var context: Context
    private lateinit var activity: Activity
    private lateinit var credentialManager: CredentialManager
    private lateinit var plugin: SmartAccountWebAuthnPlugin

    @OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
    @Before
    fun setUp() {
        Dispatchers.setMain(UnconfinedTestDispatcher())
        context = mockk(relaxed = true)
        activity = mockk(relaxed = true)
        credentialManager = mockk(relaxed = true)

        mockkObject(CredentialManager.Companion)
        every { CredentialManager.create(any()) } returns credentialManager

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

    // The plugin answers on Dispatchers.Main, which runs unconfined here, so
    // the single reply is recorded before onMethodCall returns.
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
        return result to { captured.single() }
    }

    private fun assertJsonEquals(expected: String, actual: String) {
        assertEquals(Json.parseToJsonElement(expected), Json.parseToJsonElement(actual))
    }

    @Test
    @Config(sdk = [27])
    fun register_apiBelow28_throwsNotSupported() {
        val (result, getCaptured) = captureResult()

        plugin.onMethodCall(makeRegistrationCall(), result)

        assertEquals(
            CapturedResponse.Failure(
                "WEBAUTHN_NOT_SUPPORTED",
                "Credential Manager requires Android API 28 (Pie) or higher. " +
                    "Current API level: 27",
                null
            ),
            getCaptured()
        )
    }

    @Test
    fun register_happyPath_callsCredentialManager_returnsResultMap() = runBlocking {
        val response = mockk<CreatePublicKeyCredentialResponse>()
        every { response.registrationResponseJson } returns SAMPLE_REGISTRATION_JSON
        val contextSlot = slot<Context>()
        val requestSlot = slot<CreateCredentialRequest>()
        coEvery {
            credentialManager.createCredential(capture(contextSlot), capture(requestSlot))
        } returns response

        val (result, getCaptured) = captureResult()
        plugin.onMethodCall(makeRegistrationCall(), result)

        assertSame(activity, contextSlot.captured)
        assertJsonEquals(
            EXPECTED_REGISTRATION_REQUEST_JSON,
            (requestSlot.captured as CreatePublicKeyCredentialRequest).requestJson
        )

        val captured = getCaptured()
        assertTrue(
            "Expected success but got $captured",
            captured is CapturedResponse.Success
        )
        @Suppress("UNCHECKED_CAST")
        val map = (captured as CapturedResponse.Success).value as Map<String, Any?>
        assertEquals(
            setOf("credentialId", "publicKey", "attestationObject", "deviceType", "backedUp"),
            map.keys
        )
        assertArrayEquals(byteArrayOf(0x01, 0x02, 0x03), map["credentialId"] as ByteArray)
        assertArrayEquals(SAMPLE_UNCOMPRESSED_PUBLIC_KEY, map["publicKey"] as ByteArray)
        assertArrayEquals(
            Base64.getUrlDecoder().decode(SAMPLE_ATTESTATION_OBJECT),
            map["attestationObject"] as ByteArray
        )
        assertEquals("singleDevice", map["deviceType"])
        assertEquals(false, map["backedUp"])
    }

    @Test
    fun register_credentialManagerCancellation_returnsCancelledPlatformException() =
        runBlocking {
            coEvery {
                credentialManager.createCredential(any<Context>(), any())
            } throws CreateCredentialCancellationException("User dismissed the passkey sheet")

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeRegistrationCall(), result)

            assertEquals(
                CapturedResponse.Failure(
                    "WEBAUTHN_CANCELLED",
                    "User cancelled WebAuthn operation",
                    "User dismissed the passkey sheet"
                ),
                getCaptured()
            )
        }

    @Test
    fun register_credentialManagerGenericException_returnsRegistrationFailedPlatformException() =
        runBlocking {
            val failure = CreateCredentialUnknownException("Authenticator unreachable")
            coEvery {
                credentialManager.createCredential(any<Context>(), any())
            } throws failure

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeRegistrationCall(), result)

            assertEquals(
                CapturedResponse.Failure(
                    "WEBAUTHN_REGISTRATION_FAILED",
                    "Credential creation failed: ${failure.type} - Authenticator unreachable",
                    "Authenticator unreachable"
                ),
                getCaptured()
            )
        }

    @Test
    fun register_unexpectedCredentialType_returnsRegistrationFailedPlatformException() =
        runBlocking {
            // A password response is a CreateCredentialResponse of another
            // credential type; the plugin rejects it.
            coEvery {
                credentialManager.createCredential(any<Context>(), any())
            } returns CreatePasswordResponse()

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeRegistrationCall(), result)

            assertEquals(
                CapturedResponse.Failure(
                    "WEBAUTHN_REGISTRATION_FAILED",
                    "Unexpected error during credential creation: " +
                        "Unexpected credential type: CreatePasswordResponse",
                    "Unexpected credential type: CreatePasswordResponse"
                ),
                getCaptured()
            )
        }

    @Test
    fun authenticate_happyPath_returnsResultMap() = runBlocking {
        val publicKey = mockk<PublicKeyCredential>()
        every { publicKey.authenticationResponseJson } returns SAMPLE_AUTHENTICATION_JSON
        val response = mockk<GetCredentialResponse>()
        every { response.credential } returns publicKey
        val contextSlot = slot<Context>()
        val requestSlot = slot<GetCredentialRequest>()
        coEvery {
            credentialManager.getCredential(capture(contextSlot), capture(requestSlot))
        } returns response

        val (result, getCaptured) = captureResult()
        plugin.onMethodCall(makeAuthenticationCall(), result)

        assertSame(activity, contextSlot.captured)
        val option = requestSlot.captured.credentialOptions.single() as GetPublicKeyCredentialOption
        assertJsonEquals(EXPECTED_AUTHENTICATION_REQUEST_JSON, option.requestJson)

        val captured = getCaptured()
        assertTrue(
            "Expected success but got $captured",
            captured is CapturedResponse.Success
        )
        @Suppress("UNCHECKED_CAST")
        val map = (captured as CapturedResponse.Success).value as Map<String, Any?>
        assertEquals(
            setOf("credentialId", "authenticatorData", "clientDataJSON", "signature"),
            map.keys
        )
        assertArrayEquals(byteArrayOf(0x01, 0x02, 0x03), map["credentialId"] as ByteArray)
        assertArrayEquals(byteArrayOf(0x0a, 0x0b, 0x0c), map["authenticatorData"] as ByteArray)
        assertArrayEquals(byteArrayOf(0x04, 0x05, 0x06), map["clientDataJSON"] as ByteArray)
        assertArrayEquals(byteArrayOf(0x07, 0x08, 0x09), map["signature"] as ByteArray)
    }

    @Test
    fun authenticate_noCredentialException_returnsAuthenticationFailedWithRpIdInMessage() =
        runBlocking {
            coEvery {
                credentialManager.getCredential(any<Context>(), any<GetCredentialRequest>())
            } throws NoCredentialException("No passkey matches the request")

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeAuthenticationCall(), result)

            assertEquals(
                CapturedResponse.Failure(
                    "WEBAUTHN_AUTHENTICATION_FAILED",
                    "No matching credential found for this relying party (example.com)",
                    "No passkey matches the request"
                ),
                getCaptured()
            )
        }

    @Test
    fun authenticate_cancellationException_returnsCancelledPlatformException() =
        runBlocking {
            coEvery {
                credentialManager.getCredential(any<Context>(), any<GetCredentialRequest>())
            } throws GetCredentialCancellationException("User dismissed the passkey sheet")

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeAuthenticationCall(), result)

            assertEquals(
                CapturedResponse.Failure(
                    "WEBAUTHN_CANCELLED",
                    "User cancelled WebAuthn operation",
                    "User dismissed the passkey sheet"
                ),
                getCaptured()
            )
        }

    @Test
    fun authenticate_genericGetException_returnsAuthenticationFailedPlatformException() =
        runBlocking {
            val failure = GetCredentialUnknownException("Reader error")
            coEvery {
                credentialManager.getCredential(any<Context>(), any<GetCredentialRequest>())
            } throws failure

            val (result, getCaptured) = captureResult()
            plugin.onMethodCall(makeAuthenticationCall(), result)

            assertEquals(
                CapturedResponse.Failure(
                    "WEBAUTHN_AUTHENTICATION_FAILED",
                    "Credential assertion failed: ${failure.type} - Reader error",
                    "Reader error"
                ),
                getCaptured()
            )
        }

    @Test
    fun authenticate_noActivityAttached_returnsAuthenticationFailedPlatformException() {
        plugin.detachActivity()
        val (result, getCaptured) = captureResult()

        plugin.onMethodCall(makeAuthenticationCall(), result)

        assertEquals(
            CapturedResponse.Failure(
                "WEBAUTHN_AUTHENTICATION_FAILED",
                "Activity not attached; WebAuthn requires the foreground activity context",
                null
            ),
            getCaptured()
        )
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
        // A base64url CBOR attestation object in the "none" format, built by
        // hand so the test is hermetic. Its authenticator data holds the
        // SHA-256 of "example.com", the flags UP, UV and AT, the credential ID
        // 0x010203 (rawId "AQID") and an ES256 COSE key whose x and y are the
        // P-256 base point (SEC 2, secp256r1), which the plugin reads with its
        // CBOR parser.
        private const val SAMPLE_ATTESTATION_OBJECT: String =
            "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViHo3mm9u6vuaVeN4wRgDTidR5oL6ufLTCrE9IS" +
                "VYbOGUdFAAAAALraVWanqkAfvZZFYZpVEg0AAwECA6UBAgMmIAEhWCBrF9Hy4SxCR_i85uVjpEDy" +
                "dwN9gS3rM6D0oTlF2JjCliJYIE_jQuL-Gn-bjufrSnwPnhYrzjNXazFezsu2QGg3v1H1"

        // The uncompressed point 0x04 || x || y of the sample COSE key.
        private val SAMPLE_UNCOMPRESSED_PUBLIC_KEY: ByteArray = hexToBytes(
            "04" +
                "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296" +
                "4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5"
        )

        private const val SAMPLE_REGISTRATION_JSON: String =
            "{\"id\":\"AQID\",\"rawId\":\"AQID\",\"type\":\"public-key\",\"response\":{" +
                "\"attestationObject\":\"" + SAMPLE_ATTESTATION_OBJECT +
                "\",\"clientDataJSON\":\"eyJ0eXBlIjoiYmxhaCJ9\"}}"
        private const val SAMPLE_AUTHENTICATION_JSON: String =
            "{\"id\":\"AQID\",\"rawId\":\"AQID\",\"type\":\"public-key\",\"response\":{" +
                "\"authenticatorData\":\"CgsM\",\"clientDataJSON\":\"BAUG\",\"signature\":\"BwgJ\"}}"

        // The request JSON the plugin builds from makeRegistrationCall():
        // challenge 0x010203, user ID 0x1011, both base64url without padding.
        private const val EXPECTED_REGISTRATION_REQUEST_JSON: String =
            "{\"challenge\":\"AQID\"," +
                "\"rp\":{\"id\":\"example.com\",\"name\":\"Example\"}," +
                "\"user\":{\"id\":\"EBE\",\"name\":\"alice\",\"displayName\":\"alice\"}," +
                "\"pubKeyCredParams\":[{\"type\":\"public-key\",\"alg\":-7}]," +
                "\"timeout\":60000," +
                "\"attestation\":\"direct\"," +
                "\"authenticatorSelection\":{\"residentKey\":\"preferred\"," +
                "\"requireResidentKey\":false,\"userVerification\":\"required\"}}"

        // The request JSON the plugin builds from makeAuthenticationCall():
        // challenge 0x2021 as base64url without padding.
        private const val EXPECTED_AUTHENTICATION_REQUEST_JSON: String =
            "{\"challenge\":\"ICE\",\"rpId\":\"example.com\",\"timeout\":60000," +
                "\"userVerification\":\"required\",\"allowCredentials\":[]}"

        private fun hexToBytes(hex: String): ByteArray =
            ByteArray(hex.length / 2) { hex.substring(2 * it, 2 * it + 2).toInt(16).toByte() }
    }
}
