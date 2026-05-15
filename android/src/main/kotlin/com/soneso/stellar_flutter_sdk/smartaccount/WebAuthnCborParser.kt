//
//  WebAuthnCborParser.kt
//  stellar_flutter_sdk
//
//  Copyright (c) 2026 Soneso. All rights reserved.
//

package com.soneso.stellar_flutter_sdk.smartaccount

/**
 * Pure-Kotlin CBOR parsing utilities for WebAuthn attestation and
 * authenticator data.
 *
 * Self-contained; does not depend on any other module so the Flutter
 * Android plugin can ship without a transitive dependency on a separate
 * SDK common module. Cross-language byte-identity with the Dart
 * `WebAuthnCborParser` (used by the web target) and the Swift
 * `WebAuthnAttestationParser` (used by the iOS plugin) is verified by the
 * integration smoke tests.
 *
 * All methods are designed to be resilient to malformed or truncated input:
 * they return `null` instead of throwing when data cannot be parsed, so
 * callers can implement graceful fallback strategies.
 *
 * Authenticator data structure (WebAuthn specification):
 * ```
 * [0..31]      rpIdHash         (32 bytes, SHA-256 of the relying party ID)
 * [32]         flags            (1 byte, bit field)
 * [33..36]     signCount        (4 bytes, big-endian)
 * [37..52]     aaguid           (16 bytes, if AT flag set)
 * [53..54]     credentialIdLen  (2 bytes, big-endian uint16, if AT flag set)
 * [55..55+N-1] credentialId     (N bytes, if AT flag set)
 * [55+N..]     COSE public key  (variable, if AT flag set)
 * ```
 *
 * Flag bits at offset 32:
 * - Bit 6 (0x40): AT — Attested credential data included
 * - Bit 3 (0x08): BE — Backup Eligibility
 * - Bit 4 (0x10): BS — Backup State
 */
internal object WebAuthnCborParser {

    /** Minimum length of valid authenticator data. */
    const val AUTH_DATA_MIN_LENGTH: Int = 37

    /** Byte offset of the flags field within authenticator data. */
    const val FLAGS_OFFSET: Int = 32

    /** Backup-eligibility flag (multi-device credential). */
    const val FLAG_BE: Int = 0x08

    /** Backup-state flag (currently backed up). */
    const val FLAG_BS: Int = 0x10

    /** Minimum size of the attested credential data header. */
    const val ATTESTED_CRED_DATA_HEADER_SIZE: Int = 55

    /** Size of an uncompressed secp256r1 public key (`0x04 || X || Y`). */
    const val UNCOMPRESSED_KEY_SIZE: Int = 65

    /** Uncompressed EC point prefix byte (SEC 1). */
    const val UNCOMPRESSED_KEY_PREFIX: Byte = 0x04

    /** Single-device credential (hardware-bound) sentinel string. */
    const val DEVICE_TYPE_SINGLE: String = "singleDevice"

    /** Multi-device (cloud-synced) credential sentinel string. */
    const val DEVICE_TYPE_MULTI: String = "multiDevice"

    /**
     * 10-byte CBOR map prefix that begins an ES256 COSE key for secp256r1.
     * Encodes:
     * - 1 (kty): 2 (EC2)
     * - 3 (alg): -7 (ES256)
     * - -1 (crv): 1 (P-256)
     * - -2 (x): bstr of length 32 (header only)
     */
    private val COSE_ES256_KEY_PREFIX: ByteArray = byteArrayOf(
        0xa5.toByte(), 0x01, 0x02, 0x03, 0x26.toByte(),
        0x20.toByte(), 0x01, 0x21, 0x58, 0x20.toByte()
    )

    data class AuthenticatorFlags(
        val deviceType: String?,
        val backedUp: Boolean?
    )

    // ========================================================================
    // 1. Attestation object parsing
    // ========================================================================

    fun extractAuthenticatorDataFromAttestation(attestationObject: ByteArray): ByteArray? {
        if (attestationObject.isEmpty()) return null
        var offset = 0
        val firstByte = attestationObject[offset].toInt() and 0xFF
        if (firstByte shr 5 != 5) return null
        val info = firstByte and 0x1F
        val mapSize: Int
        when {
            info < 24 -> {
                mapSize = info
                offset = 1
            }
            info == 24 -> {
                if (offset + 1 >= attestationObject.size) return null
                mapSize = attestationObject[offset + 1].toInt() and 0xFF
                offset = 2
            }
            else -> return null
        }
        for (i in 0 until mapSize) {
            if (offset >= attestationObject.size) return null
            val keyResult = readCborTextString(attestationObject, offset) ?: return null
            offset = keyResult.second
            if (keyResult.first == "authData") {
                val valueResult =
                    readCborByteString(attestationObject, offset) ?: return null
                return valueResult.first
            } else {
                offset = skipCborValue(attestationObject, offset) ?: return null
            }
        }
        return null
    }

    // ========================================================================
    // 2. COSE key extraction
    // ========================================================================

    fun extractPublicKeyFromCoseKey(coseKeyData: ByteArray): ByteArray? {
        if (coseKeyData.isEmpty()) return null
        val firstByte = coseKeyData[0].toInt() and 0xFF
        if ((firstByte shr 5) == 5) {
            val result = extractCoseKeyByMapIteration(coseKeyData)
            if (result != null) return result
        }
        return extractPublicKeyByPattern(coseKeyData)
    }

    private fun extractCoseKeyByMapIteration(coseKeyData: ByteArray): ByteArray? {
        val firstByte = coseKeyData[0].toInt() and 0xFF
        val info = firstByte and 0x1F
        val mapSize: Int
        var offset: Int
        when {
            info < 24 -> {
                mapSize = info
                offset = 1
            }
            info == 24 -> {
                if (coseKeyData.size < 2) return null
                mapSize = coseKeyData[1].toInt() and 0xFF
                offset = 2
            }
            else -> return null
        }
        var x: ByteArray? = null
        var y: ByteArray? = null
        for (i in 0 until mapSize) {
            if (offset >= coseKeyData.size) break
            val keyByte = coseKeyData[offset].toInt() and 0xFF
            val keyMajor = keyByte shr 5
            val keyInfo = keyByte and 0x1F
            when {
                keyMajor == 1 && keyInfo == 1 -> {
                    offset++
                    val r = readCborByteString(coseKeyData, offset)
                    if (r != null) {
                        x = r.first
                        offset = r.second
                    } else {
                        offset = skipCborValue(coseKeyData, offset) ?: return null
                    }
                }
                keyMajor == 1 && keyInfo == 2 -> {
                    offset++
                    val r = readCborByteString(coseKeyData, offset)
                    if (r != null) {
                        y = r.first
                        offset = r.second
                    } else {
                        offset = skipCborValue(coseKeyData, offset) ?: return null
                    }
                }
                else -> {
                    offset = skipCborHead(coseKeyData, offset) ?: return null
                    offset = skipCborValue(coseKeyData, offset) ?: return null
                }
            }
            if (x != null && y != null) break
        }
        if (x == null || y == null || x.size != 32 || y.size != 32) return null
        return buildUncompressedKey(x, y)
    }

    private fun extractPublicKeyByPattern(data: ByteArray): ByteArray? {
        val prefixIndex = findSubarray(data, COSE_ES256_KEY_PREFIX)
        if (prefixIndex < 0) return null
        val xStart = prefixIndex + COSE_ES256_KEY_PREFIX.size
        val yStart = xStart + 32 + 3
        val required = yStart + 32
        if (data.size < required) return null
        val x = data.copyOfRange(xStart, xStart + 32)
        val y = data.copyOfRange(yStart, yStart + 32)
        return buildUncompressedKey(x, y)
    }

    // ========================================================================
    // 3. SPKI key extraction
    // ========================================================================

    fun extractPublicKeyFromSpki(spkiBytes: ByteArray): ByteArray? {
        if (spkiBytes.size < UNCOMPRESSED_KEY_SIZE) return null
        val candidateStart = spkiBytes.size - UNCOMPRESSED_KEY_SIZE
        if (spkiBytes[candidateStart] != UNCOMPRESSED_KEY_PREFIX) return null
        return spkiBytes.copyOfRange(candidateStart, spkiBytes.size)
    }

    // ========================================================================
    // 4. Authenticator flags parsing
    // ========================================================================

    fun parseAuthenticatorFlags(authenticatorData: ByteArray?): AuthenticatorFlags {
        if (authenticatorData == null || authenticatorData.size <= FLAGS_OFFSET) {
            return AuthenticatorFlags(deviceType = null, backedUp = null)
        }
        val flags = authenticatorData[FLAGS_OFFSET].toInt() and 0xFF
        val deviceType = if (flags and FLAG_BE != 0) DEVICE_TYPE_MULTI else DEVICE_TYPE_SINGLE
        val backedUp = (flags and FLAG_BS) != 0
        return AuthenticatorFlags(deviceType, backedUp)
    }

    // ========================================================================
    // 5. Low-level CBOR helpers
    // ========================================================================

    fun readCborByteString(data: ByteArray, offset: Int): Pair<ByteArray, Int>? {
        if (offset >= data.size) return null
        val firstByte = data[offset].toInt() and 0xFF
        if (firstByte shr 5 != 2) return null
        val info = firstByte and 0x1F
        val length: Int
        val dataStart: Int
        when {
            info < 24 -> {
                length = info
                dataStart = offset + 1
            }
            info == 24 -> {
                if (offset + 1 >= data.size) return null
                length = data[offset + 1].toInt() and 0xFF
                dataStart = offset + 2
            }
            info == 25 -> {
                if (offset + 2 >= data.size) return null
                length = ((data[offset + 1].toInt() and 0xFF) shl 8) or
                    (data[offset + 2].toInt() and 0xFF)
                dataStart = offset + 3
            }
            info == 26 -> {
                if (offset + 4 >= data.size) return null
                val raw = ((data[offset + 1].toInt() and 0xFF) shl 24) or
                    ((data[offset + 2].toInt() and 0xFF) shl 16) or
                    ((data[offset + 3].toInt() and 0xFF) shl 8) or
                    (data[offset + 4].toInt() and 0xFF)
                if (raw < 0) return null
                length = raw
                dataStart = offset + 5
            }
            else -> return null
        }
        if (dataStart + length > data.size) return null
        return Pair(data.copyOfRange(dataStart, dataStart + length), dataStart + length)
    }

    fun readCborTextString(data: ByteArray, offset: Int): Pair<String, Int>? {
        if (offset >= data.size) return null
        val firstByte = data[offset].toInt() and 0xFF
        if (firstByte shr 5 != 3) return null
        val info = firstByte and 0x1F
        val length: Int
        val dataStart: Int
        when {
            info < 24 -> {
                length = info
                dataStart = offset + 1
            }
            info == 24 -> {
                if (offset + 1 >= data.size) return null
                length = data[offset + 1].toInt() and 0xFF
                dataStart = offset + 2
            }
            info == 25 -> {
                if (offset + 2 >= data.size) return null
                length = ((data[offset + 1].toInt() and 0xFF) shl 8) or
                    (data[offset + 2].toInt() and 0xFF)
                dataStart = offset + 3
            }
            else -> return null
        }
        if (dataStart + length > data.size) return null
        val text = data.copyOfRange(dataStart, dataStart + length).decodeToString()
        return Pair(text, dataStart + length)
    }

    fun readCborLength(data: ByteArray, offset: Int): Pair<Int, Int>? {
        if (offset >= data.size) return null
        val firstByte = data[offset].toInt() and 0xFF
        val info = firstByte and 0x1F
        return when {
            info < 24 -> Pair(info, offset + 1)
            info == 24 -> {
                if (offset + 1 >= data.size) null
                else Pair(data[offset + 1].toInt() and 0xFF, offset + 2)
            }
            info == 25 -> {
                if (offset + 2 >= data.size) null
                else Pair(
                    ((data[offset + 1].toInt() and 0xFF) shl 8) or
                        (data[offset + 2].toInt() and 0xFF),
                    offset + 3
                )
            }
            info == 26 -> {
                if (offset + 4 >= data.size) null
                else {
                    val raw = ((data[offset + 1].toInt() and 0xFF) shl 24) or
                        ((data[offset + 2].toInt() and 0xFF) shl 16) or
                        ((data[offset + 3].toInt() and 0xFF) shl 8) or
                        (data[offset + 4].toInt() and 0xFF)
                    if (raw < 0) null else Pair(raw, offset + 5)
                }
            }
            else -> null
        }
    }

    fun skipCborValue(data: ByteArray, offset: Int): Int? {
        if (offset >= data.size) return null
        val firstByte = data[offset].toInt() and 0xFF
        val major = firstByte shr 5
        val info = firstByte and 0x1F
        return when (major) {
            0, 1 -> skipCborHead(data, offset)
            2, 3 -> {
                val l = readCborLength(data, offset) ?: return null
                val end = l.second + l.first
                if (end > data.size) null else end
            }
            4 -> {
                val l = readCborLength(data, offset) ?: return null
                var pos = l.second
                for (j in 0 until l.first) {
                    pos = skipCborValue(data, pos) ?: return null
                }
                pos
            }
            5 -> {
                val l = readCborLength(data, offset) ?: return null
                var pos = l.second
                for (j in 0 until l.first) {
                    pos = skipCborValue(data, pos) ?: return null
                    pos = skipCborValue(data, pos) ?: return null
                }
                pos
            }
            6 -> {
                val headEnd = skipCborHead(data, offset) ?: return null
                skipCborValue(data, headEnd)
            }
            7 -> when (info) {
                in 0..23 -> offset + 1
                24 -> if (offset + 1 < data.size) offset + 2 else null
                25 -> if (offset + 2 < data.size) offset + 3 else null
                26 -> if (offset + 4 < data.size) offset + 5 else null
                27 -> if (offset + 8 < data.size) offset + 9 else null
                else -> null
            }
            else -> null
        }
    }

    fun skipCborHead(data: ByteArray, offset: Int): Int? {
        if (offset >= data.size) return null
        val firstByte = data[offset].toInt() and 0xFF
        val info = firstByte and 0x1F
        return when {
            info < 24 -> offset + 1
            info == 24 -> if (offset + 1 < data.size) offset + 2 else null
            info == 25 -> if (offset + 2 < data.size) offset + 3 else null
            info == 26 -> if (offset + 4 < data.size) offset + 5 else null
            info == 27 -> if (offset + 8 < data.size) offset + 9 else null
            else -> null
        }
    }

    private fun buildUncompressedKey(x: ByteArray, y: ByteArray): ByteArray {
        val out = ByteArray(UNCOMPRESSED_KEY_SIZE)
        out[0] = UNCOMPRESSED_KEY_PREFIX
        x.copyInto(out, 1)
        y.copyInto(out, 33)
        return out
    }

    private fun findSubarray(haystack: ByteArray, needle: ByteArray): Int {
        if (needle.isEmpty() || needle.size > haystack.size) return -1
        outer@ for (i in 0..haystack.size - needle.size) {
            for (j in needle.indices) {
                if (haystack[i + j] != needle[j]) continue@outer
            }
            return i
        }
        return -1
    }
}
