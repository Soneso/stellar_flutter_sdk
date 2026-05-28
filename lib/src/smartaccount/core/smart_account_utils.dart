// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:meta/meta.dart';

import '../../key_pair.dart';
import '../../xdr/xdr.dart';
import 'smart_account_constants.dart';
import 'smart_account_errors.dart';

/// Cryptographic helpers for smart-account operations.
///
/// Provides utilities for WebAuthn signature processing, public-key
/// extraction, and contract-address derivation. All members operate on
/// raw byte material and do not depend on any platform-specific WebAuthn
/// API.
///
/// For general-purpose helpers (hex, stroops, constant-time comparison) see
/// [Util]; this class focuses on cryptographic and WebAuthn-specific
/// operations.
///
/// All entry points are pure static functions over their arguments; safe to
/// call concurrently from any isolate.
abstract class SmartAccountUtils {
  /// Private constructor prevents instantiation; the class is used as a
  /// namespace for static methods.
  SmartAccountUtils._();

  // ==========================================================================
  // Signature normalisation
  // ==========================================================================

  /// Parses a DER-encoded secp256r1 signature and returns its `(r, s)`
  /// components as [BigInt] values.
  ///
  /// Validates the full DER structure, strips leading `0x00` padding bytes
  /// from both components, and enforces secp256r1-specific constraints:
  ///
  /// - `r` and `s` must each be at most 32 bytes after stripping.
  /// - `r` and `s` must not be all-zero (invalid ECDSA values).
  /// - `r` and `s` must each be strictly less than the curve order.
  ///
  /// DER format:
  /// `0x30 [total_len] 0x02 [r_len] [r_bytes] 0x02 [s_len] [s_bytes]`.
  ///
  /// Throws [InvalidInput] when the DER structure is malformed or the
  /// `r`/`s` values violate the secp256r1 constraints.
  @internal
  static List<BigInt> parseDerSignature(Uint8List derSignature) {
    if (derSignature.length < 8 || derSignature[0] != 0x30) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature format',
      );
    }

    final totalLength = derSignature[1] & 0xFF;
    if (2 + totalLength != derSignature.length) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature format: declared length does not match '
            'actual size',
      );
    }

    var offset = 2;
    if (offset + 1 >= derSignature.length || derSignature[offset] != 0x02) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature format: missing r component marker',
      );
    }

    final rLength = derSignature[offset + 1] & 0xFF;
    if (rLength == 0 || offset + 2 + rLength > derSignature.length) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature format: truncated r component',
      );
    }

    var r = Uint8List.sublistView(
      derSignature,
      offset + 2,
      offset + 2 + rLength,
    );

    while (r.length > 1 && r[0] == 0x00) {
      r = Uint8List.sublistView(r, 1);
    }

    offset = offset + 2 + rLength;
    if (offset + 1 >= derSignature.length || derSignature[offset] != 0x02) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature format: missing s component marker',
      );
    }

    final sLength = derSignature[offset + 1] & 0xFF;
    if (sLength == 0 || offset + 2 + sLength > derSignature.length) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature format: truncated s component',
      );
    }

    var s = Uint8List.sublistView(
      derSignature,
      offset + 2,
      offset + 2 + sLength,
    );

    while (s.length > 1 && s[0] == 0x00) {
      s = Uint8List.sublistView(s, 1);
    }

    final endOffset = offset + 2 + sLength;
    if (endOffset != derSignature.length) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature format: trailing bytes after s component',
      );
    }

    if (r.length > 32) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature: r component exceeds 32 bytes after '
            'stripping (${r.length} bytes)',
      );
    }
    if (s.length > 32) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature: s component exceeds 32 bytes after '
            'stripping (${s.length} bytes)',
      );
    }

    if (r.length == 1 && r[0] == 0x00) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature: r component is zero (invalid ECDSA value)',
      );
    }
    if (s.length == 1 && s[0] == 0x00) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature: s component is zero (invalid ECDSA value)',
      );
    }

    final rBigInt = _bytesToUnsignedBigInteger(r);
    if (rBigInt >= _curveOrder) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature: r component exceeds curve order',
      );
    }
    final sBigInt = _bytesToUnsignedBigInteger(s);
    if (sBigInt >= _curveOrder) {
      throw ValidationException.invalidInput(
        'derSignature',
        'Invalid DER signature: s component exceeds curve order',
      );
    }

    return <BigInt>[rBigInt, sBigInt];
  }

  /// Normalises a DER-encoded secp256r1 signature to compact format with
  /// low-S normalisation.
  ///
  /// Steps:
  ///
  /// 1. Parse the DER format via [parseDerSignature].
  /// 2. Normalise `s` to its low-S form (`s = n - s`) when `s > n/2`.
  /// 3. Pad both `r` and `s` to exactly 32 bytes.
  /// 4. Return concatenated `r || s` (64 bytes total).
  ///
  /// Low-S normalisation ensures that signatures with `s` values greater
  /// than half the curve order are converted to their complement, which
  /// the Stellar/Soroban verifier requires.
  ///
  /// Throws [InvalidInput] when the DER format is invalid.
  static Uint8List normalizeSignature(Uint8List derSignature) {
    final parts = parseDerSignature(derSignature);
    final rBigInt = parts[0];
    var sBigInt = parts[1];

    if (sBigInt > _halfCurveOrder) {
      sBigInt = _curveOrder - sBigInt;
    }

    final rPadded = _bigIntegerToUnsignedBytes(rBigInt, 32);
    final sPadded = _bigIntegerToUnsignedBytes(sBigInt, 32);

    final result = Uint8List(64);
    result.setRange(0, 32, rPadded);
    result.setRange(32, 64, sPadded);
    return result;
  }

  // ==========================================================================
  // Public key extraction
  // ==========================================================================

  /// Extracts the secp256r1 public key from a WebAuthn registration
  /// response using multiple fallback strategies.
  ///
  /// The method tries three strategies in order:
  ///
  /// 1. **Direct public key**: when [publicKey] is provided, validate it
  ///    as a 65-byte uncompressed secp256r1 key (`0x04` prefix) and verify
  ///    the point is on the curve.
  /// 2. **Authenticator data parsing**: when [authenticatorData] is
  ///    provided, parse the attested credential data structure to extract
  ///    `X`/`Y` coordinates from the COSE key.
  /// 3. **Attestation object pattern matching**: when [attestationObject]
  ///    is provided, search for the COSE key prefix pattern and extract
  ///    `X`/`Y` coordinates.
  ///
  /// At least one of the three parameters must be non-null. Compressed
  /// keys (`0x02`/`0x03` prefix) are not supported and cause the method
  /// to throw immediately rather than fall through to other strategies.
  ///
  /// Throws [InvalidInput] when a compressed-key prefix is detected, when
  /// no extraction source is provided, or when all strategies fail.
  static Uint8List extractPublicKeyFromRegistration({
    Uint8List? publicKey,
    Uint8List? authenticatorData,
    Uint8List? attestationObject,
  }) {
    if (publicKey != null && publicKey.isNotEmpty) {
      final candidate =
          publicKey.length > SmartAccountConstants.secp256r1PublicKeySize
              ? Uint8List.fromList(publicKey.sublist(
                  publicKey.length -
                      SmartAccountConstants.secp256r1PublicKeySize,
                  publicKey.length,
                ))
              : Uint8List.fromList(publicKey);

      if (candidate.length ==
              SmartAccountConstants.secp256r1PublicKeySize &&
          candidate[0] == SmartAccountConstants.uncompressedPubkeyPrefix) {
        _validatePointOnCurve(
          Uint8List.sublistView(candidate, 1, 33),
          Uint8List.sublistView(candidate, 33, 65),
        );
        return candidate;
      }

      if (candidate[0] == 0x02 || candidate[0] == 0x03) {
        final prefixHex = candidate[0].toRadixString(16).padLeft(2, '0');
        throw ValidationException.invalidInput(
          'publicKey',
          'Compressed secp256r1 key format (prefix 0x$prefixHex) is not '
              'supported; the platform must provide an uncompressed key '
              '(0x04 prefix)',
        );
      }

      // Non-key data (e.g. CBOR/attestation bytes); fall through to the
      // remaining strategies.
    }

    if (authenticatorData != null) {
      final extracted =
          extractPublicKeyFromAuthenticatorData(authenticatorData);
      if (extracted != null) {
        return extracted;
      }
    }

    if (attestationObject != null) {
      return extractPublicKeyFromAttestationObject(attestationObject);
    }

    throw ValidationException.invalidInput(
      'registration',
      'Could not extract public key from attestation response: no valid '
          'publicKey, authenticatorData, or attestationObject provided',
    );
  }

  /// Extracts the secp256r1 public key from WebAuthn authenticator data.
  ///
  /// Parses the attested credential data structure defined by the WebAuthn
  /// specification to locate and extract the COSE public key.
  ///
  /// The authenticator data layout is:
  ///
  /// ```text
  /// [0..31]   rpIdHash          (32 bytes)
  /// [32]      flags             (1 byte)
  /// [33..36]  signCount         (4 bytes, big-endian)
  /// [37..52]  aaguid            (16 bytes) -- if AT flag set
  /// [53..54]  credentialIdLen   (2 bytes, big-endian) -- if AT flag set
  /// [55..55+N-1] credentialId   (N bytes) -- if AT flag set
  /// [55+N..]  COSE public key   (variable) -- if AT flag set
  /// ```
  ///
  /// The COSE ES256 key prefix is
  /// `[0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]`,
  /// followed by 32 bytes of `X`, then `[0x22, 0x58, 0x20]`, then 32 bytes
  /// of `Y`.
  ///
  /// Returns the 65-byte uncompressed public key or `null` when the data
  /// is too short, when the `AT` flag is not set, or when the COSE prefix
  /// does not match. Throws [InvalidInput] when the `Y` marker is
  /// malformed or when the extracted point is not on the secp256r1 curve.
  @internal
  static Uint8List? extractPublicKeyFromAuthenticatorData(
    Uint8List authenticatorData,
  ) {
    if (authenticatorData.length < 55) {
      return null;
    }

    final flags = authenticatorData[32] & 0xFF;
    if ((flags & 0x40) == 0) {
      return null;
    }

    final credentialIdLength =
        ((authenticatorData[53] & 0xFF) << 8) | (authenticatorData[54] & 0xFF);

    final coseKeyStart = 55 + credentialIdLength;

    final expectedCosePrefix = Uint8List.fromList(<int>[
      0xA5,
      0x01,
      0x02,
      0x03,
      0x26,
      0x20,
      0x01,
      0x21,
      0x58,
      0x20,
    ]);

    if (authenticatorData.length < coseKeyStart + 10) {
      return null;
    }
    final actualPrefix = Uint8List.sublistView(
      authenticatorData,
      coseKeyStart,
      coseKeyStart + 10,
    );
    if (!_byteListEquals(actualPrefix, expectedCosePrefix)) {
      return null;
    }

    final xStart = coseKeyStart + 10;
    final separatorStart = xStart + 32;
    final yStart = separatorStart + 3;
    final requiredLength = yStart + 32;

    if (authenticatorData.length < requiredLength) {
      return null;
    }

    _validateCoseYMarker(authenticatorData, separatorStart, 'authenticatorData');

    final x = Uint8List.fromList(
      authenticatorData.sublist(xStart, xStart + 32),
    );
    final y = Uint8List.fromList(
      authenticatorData.sublist(yStart, yStart + 32),
    );

    _validatePointOnCurve(x, y);

    final publicKey =
        Uint8List(SmartAccountConstants.secp256r1PublicKeySize);
    publicKey[0] = SmartAccountConstants.uncompressedPubkeyPrefix;
    publicKey.setRange(1, 33, x);
    publicKey.setRange(33, 65, y);
    return publicKey;
  }

  /// Extracts the secp256r1 public key from a raw WebAuthn attestation
  /// object.
  ///
  /// Pattern-matches the 10-byte COSE key prefix in raw attestation data
  /// and extracts the `X`/`Y` coordinates of the public key. Returns the
  /// 65-byte uncompressed public key (`0x04` prefix + `X` + `Y`).
  ///
  /// Throws [InvalidInput] when the COSE prefix is not found, when there
  /// is insufficient data after the prefix, when the `Y` marker does not
  /// match `[0x22, 0x58, 0x20]`, or when the extracted point is not on
  /// the secp256r1 curve.
  @internal
  static Uint8List extractPublicKeyFromAttestationObject(
    Uint8List attestationObject,
  ) {
    final prefix = Uint8List.fromList(<int>[
      0xA5,
      0x01,
      0x02,
      0x03,
      0x26,
      0x20,
      0x01,
      0x21,
      0x58,
      0x20,
    ]);

    final prefixIndex = findSubarray(attestationObject, prefix);
    if (prefixIndex < 0) {
      throw ValidationException.invalidInput(
        'attestationObject',
        'COSE key prefix not found in attestation',
      );
    }

    final xStart = prefixIndex + prefix.length;
    final separatorStart = xStart + 32;
    final yStart = separatorStart + 3;

    final requiredLength = yStart + 32;
    if (attestationObject.length < requiredLength) {
      throw ValidationException.invalidInput(
        'attestationObject',
        'Insufficient data after COSE key prefix',
      );
    }

    _validateCoseYMarker(
      attestationObject,
      separatorStart,
      'attestationObject',
    );

    final x = Uint8List.fromList(
      attestationObject.sublist(xStart, xStart + 32),
    );
    final y = Uint8List.fromList(
      attestationObject.sublist(yStart, yStart + 32),
    );

    _validatePointOnCurve(x, y);

    final publicKey =
        Uint8List(SmartAccountConstants.secp256r1PublicKeySize);
    publicKey[0] = SmartAccountConstants.uncompressedPubkeyPrefix;
    publicKey.setRange(1, 33, x);
    publicKey.setRange(33, 65, y);
    return publicKey;
  }

  // ==========================================================================
  // Contract salt and address derivation
  // ==========================================================================

  /// Computes the contract salt from a WebAuthn credential ID.
  ///
  /// The salt is used during contract-address derivation so that each
  /// credential ID maps to a unique smart-account contract address. The
  /// salt is the SHA-256 hash of the credential ID.
  static Uint8List getContractSalt(Uint8List credentialId) {
    return Uint8List.fromList(
      crypto.sha256.convert(credentialId).bytes,
    );
  }

  /// Derives the smart-account contract address from a credential ID and
  /// deployer.
  ///
  /// Computes the deterministic contract address that will be created
  /// when deploying a smart-account contract with the given credential ID
  /// from the specified deployer account on the specified network. The
  /// algorithm is:
  ///
  /// ```text
  /// salt = SHA-256(credentialId)
  /// deployerAddress = SCAddress::Account(deployerPublicKey)
  /// networkId = SHA-256(networkPassphrase as UTF-8)
  /// preimage = HashIDPreimage::ContractID {
  ///   networkId,
  ///   contractIDPreimage: ContractIDPreimage::FromAddress {
  ///     address: deployerAddress,
  ///     salt: Uint256(salt),
  ///   }
  /// }
  /// contractIdBytes = SHA-256(XDR_encode(preimage))
  /// contractId = StrKey.encodeContractId(contractIdBytes)
  /// ```
  ///
  /// Throws [InvalidAddress] when [deployerPublicKey] is invalid,
  /// [InvalidInput] when contract-ID encoding fails, and
  /// [TransactionSigningFailed] when XDR encoding fails.
  static String deriveContractAddress({
    required Uint8List credentialId,
    required String deployerPublicKey,
    required String networkPassphrase,
  }) {
    final contractSalt = getContractSalt(credentialId);

    XdrSCAddress deployerAddress;
    try {
      // KeyPair.fromAccountId validates the strkey form for us; reuse
      // it so smart-account derivation matches the rest of the SDK.
      KeyPair.fromAccountId(deployerPublicKey);
      deployerAddress = XdrSCAddress.forAccountId(deployerPublicKey);
    } catch (e) {
      throw ValidationException.invalidAddress(
        deployerPublicKey,
        cause: e,
      );
    }

    final networkIdBytes = Uint8List.fromList(
      crypto.sha256.convert(utf8.encode(networkPassphrase)).bytes,
    );

    final fromAddress = XdrContractIDPreimageFromAddress(
      deployerAddress,
      XdrUint256(contractSalt),
    );

    final contractIdPreimage = XdrContractIDPreimage(
      XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
    );
    contractIdPreimage.fromAddress = fromAddress;

    final hashIdPreimageContractId = XdrHashIDPreimageContractID(
      XdrHash(networkIdBytes),
      contractIdPreimage,
    );

    final preimage = XdrHashIDPreimage(
      XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID,
    );
    preimage.contractID = hashIdPreimageContractId;

    Uint8List encodedPreimage;
    try {
      final stream = XdrDataOutputStream();
      XdrHashIDPreimage.encode(stream, preimage);
      encodedPreimage = Uint8List.fromList(stream.bytes);
    } catch (e) {
      throw TransactionException.signingFailed(
        'Failed to XDR encode contract ID preimage',
        cause: e,
      );
    }

    final contractIdBytes = Uint8List.fromList(
      crypto.sha256.convert(encodedPreimage).bytes,
    );

    try {
      return StrKey.encodeContractId(contractIdBytes);
    } catch (e) {
      throw ValidationException.invalidInput(
        'contractId',
        'Failed to encode contract ID: $e',
        cause: e,
      );
    }
  }

  // ==========================================================================
  // Hash helpers
  // ==========================================================================

  /// Mixes the bytes of [data] into [seed] using a 31× polynomial accumulator
  /// and returns the resulting hash code value.
  ///
  /// Suitable for Dart `hashCode` implementations over `List<int>` / `Uint8List`
  /// fields. The algorithm is identical to the one used by `Object.hashAll`
  /// internals and is safe for use as a `Map` / `Set` key hash — not suitable
  /// for cryptographic purposes.
  ///
  /// Usage in a `hashCode` getter that accumulates multiple fields:
  /// ```dart
  /// @override
  /// int get hashCode => SmartAccountUtils.hashBytes(field1.hashCode, field2Bytes);
  /// ```
  @internal
  static int hashBytes(int seed, List<int> data) {
    var h = seed;
    for (final b in data) {
      h = 0x1fffffff & (31 * h + b);
    }
    return h;
  }

  /// Returns the first 8 characters of [address] for human-friendly log lines,
  /// or the full string when shorter.
  ///
  /// Used for contract address truncation in error messages where printing the
  /// full 56-character strkey would be noisy. The 8-character prefix is long
  /// enough to distinguish addresses in a typical log trace.
  @internal
  static String truncateForLog(String address) {
    const int prefixLength = 8;
    return address.length > prefixLength
        ? address.substring(0, prefixLength)
        : address;
  }

  // ==========================================================================
  // Internal helpers
  // ==========================================================================

  /// Finds the first occurrence of [subarray] within [array] using a
  /// sliding-window scan; returns `-1` when not found, when [subarray] is
  /// empty, or when [array] is shorter than [subarray].
  ///
  /// The method is exposed at library scope so tests can exercise it
  /// directly; consumers of the public API typically use
  /// [extractPublicKeyFromRegistration] instead.
  @internal
  static int findSubarray(Uint8List array, Uint8List subarray) {
    if (subarray.isEmpty || array.length < subarray.length) {
      return -1;
    }
    final maxStart = array.length - subarray.length;
    for (var i = 0; i <= maxStart; i++) {
      var found = true;
      for (var j = 0; j < subarray.length; j++) {
        if (array[i + j] != subarray[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  // --------------------------------------------------------------------------
  // Private helpers and curve constants
  // --------------------------------------------------------------------------

  /// secp256r1 curve order `n`.
  static final BigInt _curveOrder = BigInt.parse(
    'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551',
    radix: 16,
  );

  /// Half of the secp256r1 curve order `n / 2`, used for low-S
  /// normalisation.
  static final BigInt _halfCurveOrder = _curveOrder >> 1;

  /// secp256r1 field prime `p` (FIPS 186-4 / SEC 2).
  static final BigInt _curveP = BigInt.parse(
    'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff',
    radix: 16,
  );

  /// secp256r1 curve coefficient `a = p - 3`.
  static final BigInt _curveA = BigInt.parse(
    'ffffffff00000001000000000000000000000000fffffffffffffffffffffffc',
    radix: 16,
  );

  /// secp256r1 curve coefficient `b`.
  static final BigInt _curveB = BigInt.parse(
    '5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b',
    radix: 16,
  );

  /// Validates the 3-byte COSE Y-coordinate separator at the given offset.
  ///
  /// The separator bytes `[0x22, 0x58, 0x20]` are the CBOR encoding of map
  /// key `-3`, a byte string of length 32. Their presence at the exact
  /// offset after the X coordinate confirms the surrounding structure is a
  /// valid ES256 COSE key and not a coincidental byte match elsewhere in
  /// the attestation data.
  static void _validateCoseYMarker(
    Uint8List data,
    int offset,
    String sourceName,
  ) {
    final sep0 = data[offset] & 0xFF;
    final sep1 = data[offset + 1] & 0xFF;
    final sep2 = data[offset + 2] & 0xFF;
    if (sep0 != 0x22 || sep1 != 0x58 || sep2 != 0x20) {
      final hex0 = sep0.toRadixString(16).padLeft(2, '0');
      final hex1 = sep1.toRadixString(16).padLeft(2, '0');
      final hex2 = sep2.toRadixString(16).padLeft(2, '0');
      throw ValidationException.invalidInput(
        sourceName,
        'COSE key structure is invalid: Y-coordinate marker '
            '[0x22, 0x58, 0x20] not found at expected offset $offset '
            '(found [0x$hex0, 0x$hex1, 0x$hex2])',
      );
    }
  }

  /// Validates that the point `(x, y)` lies on the secp256r1 curve.
  ///
  /// Verifies the short Weierstrass equation
  /// `y^2 ≡ x^3 + a·x + b (mod p)` and rejects coordinates with a zero
  /// component or coordinates outside the field prime. Used to guard
  /// against accepting garbage byte sequences that happen to follow a
  /// COSE-prefix pattern.
  static void _validatePointOnCurve(Uint8List x, Uint8List y) {
    final xBig = _bytesToUnsignedBigInteger(x);
    final yBig = _bytesToUnsignedBigInteger(y);

    if (xBig == BigInt.zero || yBig == BigInt.zero) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Extracted secp256r1 coordinates contain a zero component; the '
            'point is not a valid curve point',
      );
    }

    if (xBig >= _curveP || yBig >= _curveP) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Extracted secp256r1 coordinates exceed the field prime',
      );
    }

    final lhs = (yBig * yBig) % _curveP;
    final x3 = (xBig * xBig * xBig) % _curveP;
    final ax = (_curveA * xBig) % _curveP;
    final rhs = (x3 + ax + _curveB) % _curveP;

    if (lhs != rhs) {
      throw ValidationException.invalidInput(
        'publicKey',
        'Extracted secp256r1 public key coordinates are not on the P-256 '
            'curve; the attestation data may be malformed or corrupted',
      );
    }
  }

  /// Converts an unsigned big-endian byte array to a [BigInt].
  static BigInt _bytesToUnsignedBigInteger(Uint8List bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b & 0xFF);
    }
    return result;
  }

  /// Converts a non-negative [BigInt] to an unsigned big-endian byte array
  /// of length [byteCount], left-padded with zeros.
  ///
  /// Throws [ArgumentError] when [value] is negative or requires more than
  /// [byteCount] bytes.
  static Uint8List _bigIntegerToUnsignedBytes(BigInt value, int byteCount) {
    if (value < BigInt.zero) {
      throw ArgumentError.value(
        value,
        'value',
        'Cannot convert negative BigInt to unsigned bytes',
      );
    }

    var hex = value.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      final c0 = _hexNibble(hex.codeUnitAt(i * 2));
      final c1 = _hexNibble(hex.codeUnitAt(i * 2 + 1));
      bytes[i] = (c0 << 4) | c1;
    }

    if (bytes.length == byteCount) return bytes;
    if (bytes.length < byteCount) {
      final padded = Uint8List(byteCount);
      padded.setRange(byteCount - bytes.length, byteCount, bytes);
      return padded;
    }
    throw ArgumentError.value(
      value,
      'value',
      'BigInteger value requires ${bytes.length} bytes, exceeds target '
          'size of $byteCount',
    );
  }

  /// Decodes a single ASCII hex digit; the input is always lowercase
  /// because [_bigIntegerToUnsignedBytes] uses [BigInt.toRadixString].
  static int _hexNibble(int codeUnit) {
    if (codeUnit >= 0x30 && codeUnit <= 0x39) return codeUnit - 0x30;
    if (codeUnit >= 0x61 && codeUnit <= 0x66) return codeUnit - 0x61 + 10;
    if (codeUnit >= 0x41 && codeUnit <= 0x46) return codeUnit - 0x41 + 10;
    return -1;
  }

  /// Plain (non-constant-time) byte equality used by COSE-prefix
  /// comparisons where the bytes are not secret material.
  static bool _byteListEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
