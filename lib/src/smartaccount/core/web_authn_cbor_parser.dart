// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Parsed authenticator flags from WebAuthn authenticator data.
///
/// `deviceType` is `"singleDevice"` if the credential is device-bound or
/// `"multiDevice"` if it is eligible for cloud sync. It is `null` when the
/// flags byte cannot be read.
///
/// `backedUp` is `true` if the credential is currently backed up or synced
/// to a cloud provider, `false` if not, and `null` when the flags byte
/// cannot be read.
class AuthenticatorFlags {
  /// Device-binding indicator derived from the BE (Backup Eligibility) flag.
  ///
  /// Returns `"singleDevice"` or `"multiDevice"`, or `null` when the flags
  /// byte cannot be read.
  final String? deviceType;

  /// Whether the credential is currently backed up (BS flag set).
  ///
  /// `null` when the flags byte cannot be read.
  final bool? backedUp;

  /// Constructs an [AuthenticatorFlags] with the given device type and
  /// backup state.
  const AuthenticatorFlags({this.deviceType, this.backedUp});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthenticatorFlags) return false;
    return deviceType == other.deviceType && backedUp == other.backedUp;
  }

  @override
  int get hashCode => Object.hash(deviceType, backedUp);
}

/// Pure-Dart CBOR parsing utilities for WebAuthn attestation and authenticator
/// data.
///
/// Consolidates CBOR parsing logic shared by the platform WebAuthn provider
/// implementations. Has no platform dependencies and may be called from any
/// build target supported by the SDK.
///
/// All methods are designed to be resilient to malformed or truncated input.
/// They return `null` instead of throwing when data cannot be parsed, allowing
/// callers to implement graceful fallback strategies.
///
/// Authenticator data structure (WebAuthn specification):
/// ```
/// [0..31]      rpIdHash         (32 bytes, SHA-256 of the relying party ID)
/// [32]         flags            (1 byte, bit field)
/// [33..36]     signCount        (4 bytes, big-endian)
/// [37..52]     aaguid           (16 bytes, if AT flag set)
/// [53..54]     credentialIdLen  (2 bytes, big-endian uint16, if AT flag set)
/// [55..55+N-1] credentialId     (N bytes, if AT flag set)
/// [55+N..]     COSE public key  (variable, if AT flag set)
/// ```
///
/// Flag bits at offset 32 (relevant to this parser):
/// - Bit 6 (`0x40`): AT — Attested credential data included
/// - Bit 3 ([flagBE] = `0x08`): BE — Backup Eligibility (multi-device credential)
/// - Bit 4 ([flagBS] = `0x10`): BS — Backup State (currently backed up)
///
/// This class is library-private: it is not exported from
/// `package:stellar_flutter_sdk/stellar_flutter_sdk.dart`. Instantiation is
/// disabled; all entry points are static.
@internal
class WebAuthnCborParser {
  WebAuthnCborParser._();

  // Named constants

  /// Minimum length of valid authenticator data (rpIdHash + flags + signCount).
  static const int authDataMinLength = 37;

  /// Byte offset of the flags field within authenticator data.
  static const int flagsOffset = 32;

  /// Flag bit indicating Backup Eligibility (multi-device credential).
  static const int flagBE = 0x08;

  /// Flag bit indicating Backup State (credential is currently backed up).
  static const int flagBS = 0x10;

  /// Minimum size of the attested credential data header within authenticator
  /// data: rpIdHash (32) + flags (1) + signCount (4) + aaguid (16) +
  /// credentialIdLen (2) = 55.
  static const int attestedCredDataHeaderSize = 55;

  /// Size in bytes of an uncompressed secp256r1 public key (`0x04` prefix +
  /// 32-byte X + 32-byte Y).
  static const int uncompressedKeySize = 65;

  /// Uncompressed EC point prefix byte (SEC 1).
  static const int uncompressedKeyPrefix = 0x04;

  /// String constant for single-device credential type.
  static const String deviceTypeSingle = 'singleDevice';

  /// String constant for multi-device (cloud-synced) credential type.
  static const String deviceTypeMulti = 'multiDevice';

  /// Maximum CBOR nesting depth that [skipCborValue] will descend into.
  ///
  /// WebAuthn attestation objects have shallow CBOR structure (typically
  /// 2-3 levels). Capping recursion protects against pathological inputs
  /// that would exhaust the call stack.
  static const int _maxCborDepth = 64;

  /// 10-byte CBOR map prefix that begins an ES256 COSE key for secp256r1.
  ///
  /// Encodes the first four CBOR map entries:
  /// - `1` (kty): `2` (EC2)
  /// - `3` (alg): `-7` (ES256)
  /// - `-1` (crv): `1` (P-256)
  /// - `-2` (x): bstr of length 32 (header only)
  static final Uint8List _coseEs256KeyPrefix = Uint8List.fromList(<int>[
    0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20,
  ]);

  // Attestation object parsing

  /// Extracts the raw authenticator data from a CBOR-encoded WebAuthn
  /// attestation object.
  ///
  /// The attestation object is a CBOR map with the following structure:
  /// ```
  /// {
  ///   "fmt":      text string  (attestation format, e.g. "none", "packed")
  ///   "attStmt":  map          (attestation statement, may be empty)
  ///   "authData": bstr         (raw authenticator data bytes)
  /// }
  /// ```
  ///
  /// This method performs a full CBOR map iteration to locate the `"authData"`
  /// key and return its byte string value. Iteration handles variable-length
  /// values correctly, unlike pattern matching, which breaks on variable-length
  /// preceding map entries (such as non-empty attestation statements).
  ///
  /// - [attestationObject] Raw CBOR-encoded attestation object bytes.
  ///
  /// Returns the authenticator data bytes, or `null` if the attestation object
  /// is malformed, empty, not a CBOR map, or does not contain an `"authData"`
  /// key.
  static Uint8List? extractAuthenticatorDataFromAttestation(
      Uint8List attestationObject) {
    if (attestationObject.isEmpty) return null;

    var offset = 0;
    final firstByte = attestationObject[offset] & 0xFF;

    // Verify top-level CBOR type is a map (major type 5).
    final majorType = firstByte >> 5;
    if (majorType != 5) return null;

    final additionalInfo = firstByte & 0x1F;
    final int mapSize;

    if (additionalInfo < 24) {
      mapSize = additionalInfo;
      offset = 1;
    } else if (additionalInfo == 24) {
      if (offset + 1 >= attestationObject.length) return null;
      mapSize = attestationObject[offset + 1] & 0xFF;
      offset = 2;
    } else {
      // Maps with more than 255 entries are not expected in attestation.
      return null;
    }

    // Iterate through map key-value pairs looking for "authData".
    for (var i = 0; i < mapSize; i++) {
      if (offset >= attestationObject.length) return null;

      final keyResult = readCborTextString(attestationObject, offset);
      if (keyResult == null) return null;
      final key = keyResult.$1;
      offset = keyResult.$2;

      if (key == 'authData') {
        final valueResult = readCborByteString(attestationObject, offset);
        if (valueResult == null) return null;
        return valueResult.$1;
      } else {
        // Skip the value for this key to advance to the next map entry.
        final next = skipCborValue(attestationObject, offset);
        if (next == null) return null;
        offset = next;
      }
    }

    return null;
  }

  // COSE key extraction

  /// Extracts the uncompressed secp256r1 public key from a CBOR-encoded COSE
  /// key.
  ///
  /// A COSE key for ES256 (secp256r1) is a CBOR map. The relevant entries are:
  /// - Key label `-2` (CBOR `0x21`): X coordinate (32-byte bstr)
  /// - Key label `-3` (CBOR `0x22`): Y coordinate (32-byte bstr)
  ///
  /// CBOR encodes negative integers as `-(n+1)`, so `-2` is encoded as major
  /// type 1 with additional info 1 (byte `0x21`), and `-3` as major type 1
  /// with additional info 2 (byte `0x22`).
  ///
  /// If the data does not begin with a CBOR map header, or if either
  /// coordinate cannot be found via map iteration, this method falls back to
  /// pattern matching using the well-known ES256 COSE key prefix to locate
  /// the key structure directly.
  ///
  /// - [coseKeyData] Raw CBOR-encoded COSE key bytes, starting at the first
  ///   byte of the COSE map.
  ///
  /// Returns the uncompressed secp256r1 public key (65 bytes,
  /// `0x04 || X || Y`), or `null` if neither map iteration nor the
  /// pattern-matching fallback can locate valid 32-byte X and Y coordinates.
  static Uint8List? extractPublicKeyFromCoseKey(Uint8List coseKeyData) {
    if (coseKeyData.isEmpty) return null;

    final firstByte = coseKeyData[0] & 0xFF;
    final majorType = firstByte >> 5;

    if (majorType == 5) {
      // Full CBOR map iteration.
      final result = _extractCoseKeyByMapIteration(coseKeyData);
      if (result != null) return result;
    }

    // Fallback: pattern matching for the well-known ES256 key prefix.
    return _extractPublicKeyByPattern(coseKeyData);
  }

  /// Iterates the CBOR map in the given data to find key labels `-2` (X) and
  /// `-3` (Y).
  ///
  /// Returns the uncompressed 65-byte public key, or `null` if X or Y are
  /// not found or the map header is malformed.
  static Uint8List? _extractCoseKeyByMapIteration(Uint8List coseKeyData) {
    final firstByte = coseKeyData[0] & 0xFF;
    final additionalInfo = firstByte & 0x1F;

    final int mapSize;
    int offset;

    if (additionalInfo < 24) {
      mapSize = additionalInfo;
      offset = 1;
    } else if (additionalInfo == 24) {
      if (coseKeyData.length < 2) return null;
      mapSize = coseKeyData[1] & 0xFF;
      offset = 2;
    } else {
      return null;
    }

    Uint8List? x;
    Uint8List? y;

    for (var i = 0; i < mapSize; i++) {
      if (offset >= coseKeyData.length) break;

      final keyByte = coseKeyData[offset] & 0xFF;
      final keyMajorType = keyByte >> 5;
      final keyInfo = keyByte & 0x1F;

      if (keyMajorType == 1 && keyInfo == 1) {
        // CBOR negative integer 0x21 = -2 => X coordinate.
        offset++;
        final result = readCborByteString(coseKeyData, offset);
        if (result != null) {
          x = result.$1;
          offset = result.$2;
        } else {
          final next = skipCborValue(coseKeyData, offset);
          if (next == null) return null;
          offset = next;
        }
      } else if (keyMajorType == 1 && keyInfo == 2) {
        // CBOR negative integer 0x22 = -3 => Y coordinate.
        offset++;
        final result = readCborByteString(coseKeyData, offset);
        if (result != null) {
          y = result.$1;
          offset = result.$2;
        } else {
          final next = skipCborValue(coseKeyData, offset);
          if (next == null) return null;
          offset = next;
        }
      } else {
        // Skip this key-value pair.
        final afterKey = skipCborHead(coseKeyData, offset);
        if (afterKey == null) return null;
        final afterValue = skipCborValue(coseKeyData, afterKey);
        if (afterValue == null) return null;
        offset = afterValue;
      }

      if (x != null && y != null) break;
    }

    if (x == null || y == null || x.length != 32 || y.length != 32) return null;

    return _buildUncompressedKey(x, y);
  }

  /// Pattern-matching fallback that searches for the ES256 COSE key prefix
  /// and extracts X and Y coordinates from the fixed offsets that follow
  /// the prefix.
  ///
  /// Searches for the 10-byte ES256 COSE key prefix anywhere in [data]. If
  /// found:
  /// - X is the 32 bytes immediately after the prefix.
  /// - Y is the 32 bytes starting 3 bytes after X (the 3 bytes are the
  ///   CBOR-encoded map key `-3` followed by a 32-byte bstr header:
  ///   `0x22 0x58 0x20`).
  ///
  /// Returns the uncompressed 65-byte public key, or `null` if the prefix
  /// is not found or there is insufficient data following it.
  static Uint8List? _extractPublicKeyByPattern(Uint8List data) {
    final prefixIndex = _findSubarray(data, _coseEs256KeyPrefix);
    if (prefixIndex < 0) return null;

    final xStart = prefixIndex + _coseEs256KeyPrefix.length;
    // 3 bytes: CBOR key -3 (0x22) + bstr header (0x58 0x20).
    final yStart = xStart + 32 + 3;
    final requiredLength = yStart + 32;

    if (data.length < requiredLength) return null;

    final x = Uint8List.fromList(data.sublist(xStart, xStart + 32));
    final y = Uint8List.fromList(data.sublist(yStart, yStart + 32));

    return _buildUncompressedKey(x, y);
  }

  // SPKI key extraction

  /// Extracts an uncompressed secp256r1 public key from SubjectPublicKeyInfo
  /// (SPKI) bytes.
  ///
  /// The SPKI structure for a P-256 key (RFC 5480 / SEC 1) is:
  /// ```
  /// SEQUENCE {
  ///   SEQUENCE {
  ///     OID 1.2.840.10045.2.1   (id-ecPublicKey)
  ///     OID 1.2.840.10045.3.1.7 (secp256r1 / prime256v1)
  ///   }
  ///   BIT STRING { 0x04 || X (32 bytes) || Y (32 bytes) }
  /// }
  /// ```
  ///
  /// The total SPKI encoding is typically 91 bytes. The uncompressed public
  /// key (65 bytes) occupies the last 65 bytes of the structure and always
  /// starts with the `0x04` uncompressed point prefix.
  ///
  /// This method uses pure byte slicing: if [spkiBytes] is at least 65 bytes
  /// long and the byte at `length - 65` equals `0x04`, the last 65 bytes are
  /// returned.
  ///
  /// - [spkiBytes] Raw SPKI/DER-encoded public key bytes.
  ///
  /// Returns the uncompressed 65-byte secp256r1 public key
  /// (`0x04 || X || Y`), or `null` if the input is shorter than 65 bytes or
  /// does not have the expected `0x04` prefix at the computed offset.
  static Uint8List? extractPublicKeyFromSpki(Uint8List spkiBytes) {
    if (spkiBytes.length < uncompressedKeySize) return null;

    final candidateStart = spkiBytes.length - uncompressedKeySize;
    if ((spkiBytes[candidateStart] & 0xFF) != uncompressedKeyPrefix) {
      return null;
    }

    return Uint8List.fromList(
      spkiBytes.sublist(candidateStart, spkiBytes.length),
    );
  }

  // Authenticator flags parsing

  /// Parses the flags byte from raw authenticator data and extracts device
  /// type and backup state.
  ///
  /// The flags byte is located at offset [flagsOffset] (32) within
  /// authenticator data. Two bits are relevant:
  /// - Bit 3 ([flagBE] = `0x08`): BE — Backup Eligibility. When set, the
  ///   credential is eligible for cloud synchronisation across devices
  ///   (device type = [deviceTypeMulti]). When clear, the credential is
  ///   bound to a single device ([deviceTypeSingle]).
  /// - Bit 4 ([flagBS] = `0x10`): BS — Backup State. When set, the credential
  ///   is currently backed up or synced to a cloud provider.
  ///
  /// If [authenticatorData] is `null` or shorter than `flagsOffset + 1` bytes,
  /// both [AuthenticatorFlags.deviceType] and [AuthenticatorFlags.backedUp]
  /// are `null`, indicating that the device type and backup state are
  /// genuinely unknown.
  ///
  /// - [authenticatorData] Raw authenticator data bytes (directly from the
  ///   authenticator response, not CBOR-wrapped). May be `null`.
  ///
  /// Returns the parsed [AuthenticatorFlags] containing device type and
  /// backup status. Fields are `null` when the flags byte cannot be read.
  static AuthenticatorFlags parseAuthenticatorFlags(
      Uint8List? authenticatorData) {
    if (authenticatorData == null || authenticatorData.length <= flagsOffset) {
      return const AuthenticatorFlags(deviceType: null, backedUp: null);
    }

    final flags = authenticatorData[flagsOffset] & 0xFF;

    final deviceType =
        (flags & flagBE) != 0 ? deviceTypeMulti : deviceTypeSingle;
    final backedUp = (flags & flagBS) != 0;

    return AuthenticatorFlags(deviceType: deviceType, backedUp: backedUp);
  }

  // Low-level CBOR helpers (accessible for testing)

  /// Reads a CBOR byte string (major type 2) at the given offset.
  ///
  /// Supports byte strings with lengths encoded as:
  /// - 0 to 23 bytes (inline additional info)
  /// - 1-byte length prefix (additional info 24)
  /// - 2-byte big-endian length prefix (additional info 25)
  /// - 4-byte big-endian length prefix (additional info 26, with overflow
  ///   guard)
  ///
  /// - [data] The CBOR-encoded byte array.
  /// - [offset] Byte offset of the CBOR byte string header.
  ///
  /// Returns a record of `(decoded bytes, offset after the byte string)`, or
  /// `null` if the data is truncated, the major type is not 2, or a 4-byte
  /// length overflows the platform's signed 32-bit integer range.
  static (Uint8List, int)? readCborByteString(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final firstByte = data[offset] & 0xFF;
    final majorType = firstByte >> 5;

    if (majorType != 2) return null; // Not a byte string.

    final additionalInfo = firstByte & 0x1F;
    final int length;
    final int dataStart;

    if (additionalInfo < 24) {
      length = additionalInfo;
      dataStart = offset + 1;
    } else if (additionalInfo == 24) {
      if (offset + 1 >= data.length) return null;
      length = data[offset + 1] & 0xFF;
      dataStart = offset + 2;
    } else if (additionalInfo == 25) {
      if (offset + 2 >= data.length) return null;
      length = ((data[offset + 1] & 0xFF) << 8) | (data[offset + 2] & 0xFF);
      dataStart = offset + 3;
    } else if (additionalInfo == 26) {
      if (offset + 4 >= data.length) return null;
      // Cap the 4-byte length at 0x7FFFFFFF: a value with the high bit set would
      // declare a >2 GiB byte string, far beyond any legitimate WebAuthn payload
      // size and almost certainly malformed or hostile input. Reject defensively.
      final raw = ((data[offset + 1] & 0xFF) << 24) |
          ((data[offset + 2] & 0xFF) << 16) |
          ((data[offset + 3] & 0xFF) << 8) |
          (data[offset + 4] & 0xFF);
      if (raw > 0x7FFFFFFF) return null;
      length = raw;
      dataStart = offset + 5;
    } else {
      // Indefinite-length or 8-byte length not supported.
      return null;
    }

    if (dataStart + length > data.length) return null;

    final bytes = Uint8List.fromList(data.sublist(dataStart, dataStart + length));
    return (bytes, dataStart + length);
  }

  /// Reads a CBOR text string (major type 3) at the given offset.
  ///
  /// Supports text strings with lengths encoded as:
  /// - 0 to 23 bytes (inline additional info)
  /// - 1-byte length prefix (additional info 24)
  /// - 2-byte big-endian length prefix (additional info 25)
  ///
  /// The raw bytes are decoded as UTF-8.
  ///
  /// - [data] The CBOR-encoded byte array.
  /// - [offset] Byte offset of the CBOR text string header.
  ///
  /// Returns a record of `(decoded string, offset after the text string)`, or
  /// `null` if the data is truncated or the major type is not 3.
  static (String, int)? readCborTextString(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final firstByte = data[offset] & 0xFF;
    final majorType = firstByte >> 5;

    if (majorType != 3) return null; // Not a text string.

    final additionalInfo = firstByte & 0x1F;
    final int length;
    final int dataStart;

    if (additionalInfo < 24) {
      length = additionalInfo;
      dataStart = offset + 1;
    } else if (additionalInfo == 24) {
      if (offset + 1 >= data.length) return null;
      length = data[offset + 1] & 0xFF;
      dataStart = offset + 2;
    } else if (additionalInfo == 25) {
      if (offset + 2 >= data.length) return null;
      length = ((data[offset + 1] & 0xFF) << 8) | (data[offset + 2] & 0xFF);
      dataStart = offset + 3;
    } else {
      return null;
    }

    if (dataStart + length > data.length) return null;

    final text = utf8.decode(data.sublist(dataStart, dataStart + length));
    return (text, dataStart + length);
  }

  /// Reads the length value from a CBOR item head (applicable to major types
  /// 2, 3, 4, 5).
  ///
  /// Does not read the actual content — only the length field and the header
  /// bytes.
  ///
  /// Supports lengths encoded as:
  /// - Inline (0..23)
  /// - 1-byte (additional info 24)
  /// - 2-byte big-endian (additional info 25)
  /// - 4-byte big-endian (additional info 26, with overflow guard)
  ///
  /// - [data] The CBOR-encoded byte array.
  /// - [offset] Byte offset of the CBOR item head.
  ///
  /// Returns a record of `(length value, offset immediately after the head
  /// bytes)`, or `null` if the data is truncated or the additional info
  /// encodes an unsupported or overflowing length.
  static (int, int)? readCborLength(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final firstByte = data[offset] & 0xFF;
    final additionalInfo = firstByte & 0x1F;

    if (additionalInfo < 24) {
      return (additionalInfo, offset + 1);
    } else if (additionalInfo == 24) {
      if (offset + 1 >= data.length) return null;
      return (data[offset + 1] & 0xFF, offset + 2);
    } else if (additionalInfo == 25) {
      if (offset + 2 >= data.length) return null;
      return (
        ((data[offset + 1] & 0xFF) << 8) | (data[offset + 2] & 0xFF),
        offset + 3,
      );
    } else if (additionalInfo == 26) {
      if (offset + 4 >= data.length) return null;
      final raw = ((data[offset + 1] & 0xFF) << 24) |
          ((data[offset + 2] & 0xFF) << 16) |
          ((data[offset + 3] & 0xFF) << 8) |
          (data[offset + 4] & 0xFF);
      if (raw > 0x7FFFFFFF) return null;
      return (raw, offset + 5);
    } else {
      return null;
    }
  }

  /// Skips a single CBOR value at the given offset and returns the offset of
  /// the next value.
  ///
  /// Handles all standard CBOR major types:
  /// - 0 (unsigned int): skip head only
  /// - 1 (negative int): skip head only
  /// - 2 (byte string): skip head + content
  /// - 3 (text string): skip head + content
  /// - 4 (array): skip head + N recursively skipped items
  /// - 5 (map): skip head + N recursively skipped key-value pairs
  /// - 6 (tag): skip tag head + 1 recursively skipped tagged value
  /// - 7 (float/simple): skip head only (1, 2, 3, 5, or 9 bytes depending on
  ///   additional info)
  ///
  /// Recursion is bounded by an internal max-depth cap to defend against
  /// pathologically nested inputs.
  ///
  /// - [data] The CBOR-encoded byte array.
  /// - [offset] Byte offset of the CBOR value to skip.
  ///
  /// Returns the byte offset immediately after the skipped value, or `null`
  /// if the data is truncated, an unsupported encoding is encountered, or
  /// the recursion depth cap is exceeded.
  static int? skipCborValue(Uint8List data, int offset) {
    return _skipCborValueWithDepth(data, offset, 0);
  }

  /// Internal recursive worker for [skipCborValue] that enforces a depth cap.
  static int? _skipCborValueWithDepth(Uint8List data, int offset, int depth) {
    if (depth >= _maxCborDepth) return null;
    if (offset >= data.length) return null;

    final firstByte = data[offset] & 0xFF;
    final majorType = firstByte >> 5;
    final additionalInfo = firstByte & 0x1F;

    switch (majorType) {
      case 0:
      case 1:
        // Unsigned integer or negative integer: head only.
        return skipCborHead(data, offset);
      case 2:
      case 3:
        // Byte string or text string: head + content.
        final lengthResult = readCborLength(data, offset);
        if (lengthResult == null) return null;
        final length = lengthResult.$1;
        final contentStart = lengthResult.$2;
        if (contentStart + length > data.length) return null;
        return contentStart + length;
      case 4:
        // Array: head + N items.
        final lengthResult = readCborLength(data, offset);
        if (lengthResult == null) return null;
        final count = lengthResult.$1;
        var pos = lengthResult.$2;
        for (var j = 0; j < count; j++) {
          final next = _skipCborValueWithDepth(data, pos, depth + 1);
          if (next == null) return null;
          pos = next;
        }
        return pos;
      case 5:
        // Map: head + N key-value pairs.
        final lengthResult = readCborLength(data, offset);
        if (lengthResult == null) return null;
        final count = lengthResult.$1;
        var pos = lengthResult.$2;
        for (var j = 0; j < count; j++) {
          final keyEnd = _skipCborValueWithDepth(data, pos, depth + 1);
          if (keyEnd == null) return null;
          pos = keyEnd;
          final valueEnd = _skipCborValueWithDepth(data, pos, depth + 1);
          if (valueEnd == null) return null;
          pos = valueEnd;
        }
        return pos;
      case 6:
        // Tag: skip tag head + tagged value.
        final headEnd = skipCborHead(data, offset);
        if (headEnd == null) return null;
        return _skipCborValueWithDepth(data, headEnd, depth + 1);
      case 7:
        // Simple value or float.
        if (additionalInfo <= 23) return offset + 1;
        if (additionalInfo == 24) return offset + 1 < data.length ? offset + 2 : null;
        if (additionalInfo == 25) return offset + 2 < data.length ? offset + 3 : null;
        if (additionalInfo == 26) return offset + 4 < data.length ? offset + 5 : null;
        if (additionalInfo == 27) return offset + 8 < data.length ? offset + 9 : null;
        return null;
      default:
        return null;
    }
  }

  /// Skips the initial byte (and any additional-info bytes) of a CBOR item
  /// head.
  ///
  /// This advances past the type/length header without reading or skipping
  /// the content. Used for integer types (major types 0 and 1) where there
  /// is no subsequent content, and internally within [skipCborValue] for
  /// tags.
  ///
  /// - [data] The CBOR-encoded byte array.
  /// - [offset] Byte offset of the CBOR item head.
  ///
  /// Returns the byte offset immediately after the head, or `null` if the
  /// data is truncated.
  static int? skipCborHead(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final firstByte = data[offset] & 0xFF;
    final additionalInfo = firstByte & 0x1F;

    if (additionalInfo < 24) return offset + 1;
    if (additionalInfo == 24) return offset + 1 < data.length ? offset + 2 : null;
    if (additionalInfo == 25) return offset + 2 < data.length ? offset + 3 : null;
    if (additionalInfo == 26) return offset + 4 < data.length ? offset + 5 : null;
    if (additionalInfo == 27) return offset + 8 < data.length ? offset + 9 : null;
    return null;
  }

  // Private helpers

  /// Constructs an uncompressed secp256r1 public key byte array from X and Y
  /// coordinates.
  ///
  /// Returns a 65-byte array: `[uncompressedKeyPrefix, ...x, ...y]`.
  static Uint8List _buildUncompressedKey(Uint8List x, Uint8List y) {
    final publicKey = Uint8List(uncompressedKeySize);
    publicKey[0] = uncompressedKeyPrefix;
    publicKey.setRange(1, 33, x);
    publicKey.setRange(33, 65, y);
    return publicKey;
  }

  /// Searches for the first occurrence of [needle] within [haystack].
  ///
  /// Uses a naive linear scan. WebAuthn attestation objects are small
  /// (typically a few hundred bytes), so the performance of a naive scan is
  /// acceptable.
  ///
  /// Returns the index of the first occurrence, or `-1` if [needle] is not
  /// found or is longer than [haystack].
  static int _findSubarray(Uint8List haystack, Uint8List needle) {
    if (needle.isEmpty || needle.length > haystack.length) return -1;
    final lastStart = haystack.length - needle.length;
    outer:
    for (var i = 0; i <= lastStart; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}
