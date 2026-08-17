// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:pinenacl/ed25519.dart' as ed25519;
import 'muxed_account.dart';
import 'dart:convert';
import 'dart:typed_data';
import "util.dart";
import 'network.dart';
import 'transaction.dart';
import 'xdr/xdr.dart';
import 'package:collection/collection.dart';
import 'constants/stellar_protocol_constants.dart';
import 'constants/bit_constants.dart';

/// Version byte constants for different Stellar address types.
///
/// Each Stellar address type (account IDs, seeds, contracts, etc.) uses a specific
/// version byte prefix that determines the first character of the encoded string.
/// These version bytes ensure that different address types cannot be confused with
/// each other and enable validation of address formats.
///
/// Address prefixes:
/// - G: Standard account ID (ACCOUNT_ID)
/// - M: Muxed account ID (MUXED_ACCOUNT_ID)
/// - S: Secret seed/private key (SEED)
/// - T: Pre-authorized transaction hash (PRE_AUTH_TX)
/// - X: SHA256 hash for hash-x signers (SHA256_HASH)
/// - P: Signed payload signer (SIGNED_PAYLOAD)
/// - C: Smart contract ID (CONTRACT_ID)
/// - L: Liquidity pool ID (LIQUIDITY_POOL)
/// - B: Claimable balance ID (CLAIMABLE_BALANCE)
///
/// Example usage:
/// ```dart
/// // Encoding a public key to an account ID (G...)
/// String accountId = StrKey.encodeCheck(VersionByte.ACCOUNT_ID, publicKeyBytes);
///
/// // Encoding a secret seed (S...)
/// String secretSeed = StrKey.encodeCheck(VersionByte.SEED, secretSeedBytes);
/// ```
///
/// See also:
/// - [StrKey] for encoding and decoding Stellar addresses
/// - [KeyPair] for working with keypairs and account IDs
class VersionByte {
  final int _value;

  const VersionByte._internal(this._value);

  /// Returns a string representation of this instance for debugging.
  @override
  toString() => 'VersionByte.$_value';

  /// Creates a version byte with the specified value for Stellar address encoding.
  VersionByte(this._value);

  /// Returns the internal version byte value for address encoding.
  int getValue() => this._value;

  /// Version byte for standard account IDs (G...).
  static const ACCOUNT_ID = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_ACCOUNT_ID);

  /// Version byte for muxed account IDs (M...).
  static const MUXED_ACCOUNT_ID = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_MUXED_ACCOUNT);

  /// Version byte for secret seeds/private keys (S...).
  static const SEED = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_SEED);

  /// Version byte for pre-authorized transaction hashes (T...).
  static const PRE_AUTH_TX = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_PRE_AUTH_TX);

  /// Version byte for SHA256 hash signers (X...).
  static const SHA256_HASH = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_SHA256_HASH);

  /// Version byte for signed payload signers (P...).
  static const SIGNED_PAYLOAD = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_SIGNED_PAYLOAD);

  /// Version byte for smart contract IDs (C...).
  static const CONTRACT_ID = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_CONTRACT_ID);

  /// Version byte for liquidity pool IDs (L...).
  static const LIQUIDITY_POOL = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_LIQUIDITY_POOL);

  /// Version byte for claimable balance IDs (B...).
  static const CLAIMABLE_BALANCE = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_CLAIMABLE_BALANCE);
}

/// The lengths one strkey type admits.
///
/// [encodedMin] and [encodedMax] bound the base32 string; [payloadMin] and
/// [payloadMax] bound the bytes it carries once the version byte and the
/// checksum are removed. A type of a single width has both ends of a range
/// equal.
class _StrKeyLengths {
  final int encodedMin;
  final int encodedMax;
  final int payloadMin;
  final int payloadMax;

  const _StrKeyLengths(
      {required this.encodedMin,
      required this.encodedMax,
      required this.payloadMin,
      required this.payloadMax});

  /// Lengths of a type whose encoded string and payload each have one width.
  const _StrKeyLengths.fixed(int encoded, int payload)
      : encodedMin = encoded,
        encodedMax = encoded,
        payloadMin = payload,
        payloadMax = payload;

  /// The encoded-length bound, worded for an error message.
  String get encodedRange => _describe(encodedMin, encodedMax);

  /// The payload-length bound, worded for an error message.
  String get payloadRange => _describe(payloadMin, payloadMax);

  static String _describe(int min, int max) =>
      min == max ? '$min' : '$min to $max';
}

/// Provides encoding and decoding for Stellar strkey addresses.
///
/// StrKey is responsible for converting between binary data and the
/// human-readable string representations used throughout Stellar. All
/// Stellar addresses use a strkey format with checksums to prevent
/// errors and version bytes to identify the address type.
///
/// Supported address types:
/// - Account IDs (G...): Standard Stellar accounts
/// - Muxed Account IDs (M...): Multiplexed accounts for payment routing
/// - Secret Seeds (S...): Private keys for signing
/// - Pre-authorized Transaction (T...): Pre-authorized transaction hashes
/// - SHA256 Hash (X...): Hash for hash-x signers
/// - Signed Payload (P...): Signed payload signers (CAP-40)
/// - Contract IDs (C...): Soroban smart contracts
/// - Liquidity Pool IDs (L...): AMM liquidity pools
/// - Claimable Balance IDs (B...): Claimable balance identifiers
///
/// All encoding/decoding operations include CRC16 checksum verification
/// to detect transcription errors.
///
/// Example:
/// ```dart
/// // Encode a public key to account ID
/// Uint8List publicKey = myKeyPair.publicKey;
/// String accountId = StrKey.encodeStellarAccountId(publicKey);
///
/// // Decode an account ID back to bytes
/// Uint8List decoded = StrKey.decodeStellarAccountId(accountId);
///
/// // Validate an address
/// bool isValid = StrKey.isValidStellarAccountId("GBRPYHIL...");
///
/// // Work with contract IDs
/// String contractId = StrKey.encodeContractId(contractBytes);
/// bool validContract = StrKey.isValidContractId(contractId);
/// ```
///
/// See also:
/// - [KeyPair] for generating and managing keypairs
/// - [VersionByte] for address type prefixes
/// - [Stellar SEP-0023](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md) for strkey specification
class StrKey {
  /// The lengths each strkey type admits, keyed by version byte.
  ///
  /// A version byte absent from this table names no type this codec knows.
  /// [decodeCheck] describes how it applies the two ranges a type holds here.
  static const Map<int, _StrKeyLengths> _lengthsByVersionByte = {
    StellarProtocolConstants.VERSION_BYTE_ACCOUNT_ID: _StrKeyLengths.fixed(
        StellarProtocolConstants.STRKEY_ACCOUNT_ID_LENGTH,
        StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES),
    StellarProtocolConstants.VERSION_BYTE_MUXED_ACCOUNT: _StrKeyLengths.fixed(
        StellarProtocolConstants.STRKEY_MUXED_ACCOUNT_ID_LENGTH,
        StellarProtocolConstants.MUXED_ACCOUNT_DECODED_LENGTH),
    StellarProtocolConstants.VERSION_BYTE_SEED: _StrKeyLengths.fixed(
        StellarProtocolConstants.STRKEY_SECRET_SEED_LENGTH,
        StellarProtocolConstants.ED25519_PRIVATE_KEY_LENGTH_BYTES),
    StellarProtocolConstants.VERSION_BYTE_PRE_AUTH_TX: _StrKeyLengths.fixed(
        StellarProtocolConstants.STRKEY_PRE_AUTH_TX_LENGTH,
        StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES),
    StellarProtocolConstants.VERSION_BYTE_SHA256_HASH: _StrKeyLengths.fixed(
        StellarProtocolConstants.STRKEY_SHA256_HASH_LENGTH,
        StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES),
    StellarProtocolConstants.VERSION_BYTE_SIGNED_PAYLOAD: _StrKeyLengths(
        encodedMin: StellarProtocolConstants.STRKEY_SIGNED_PAYLOAD_MIN_LENGTH,
        encodedMax: StellarProtocolConstants.STRKEY_SIGNED_PAYLOAD_MAX_LENGTH,
        payloadMin: StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES +
            StellarProtocolConstants.SIGNED_PAYLOAD_LENGTH_PREFIX_BYTES +
            StellarProtocolConstants.SIGNED_PAYLOAD_MIN_PADDED_LENGTH_BYTES,
        payloadMax: StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES +
            StellarProtocolConstants.SIGNED_PAYLOAD_LENGTH_PREFIX_BYTES +
            StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES),
    StellarProtocolConstants.VERSION_BYTE_CONTRACT_ID: _StrKeyLengths.fixed(
        StellarProtocolConstants.STRKEY_CONTRACT_ID_LENGTH,
        StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES),
    StellarProtocolConstants.VERSION_BYTE_LIQUIDITY_POOL: _StrKeyLengths.fixed(
        StellarProtocolConstants.STRKEY_LIQUIDITY_POOL_LENGTH,
        StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES),
    StellarProtocolConstants.VERSION_BYTE_CLAIMABLE_BALANCE:
        _StrKeyLengths.fixed(
            StellarProtocolConstants.STRKEY_CLAIMABLE_BALANCE_LENGTH,
            StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_BYTES +
                StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES),
  };

  /// Encodes [data] to strkey account id (G...).
  static String encodeStellarAccountId(Uint8List data) {
    return encodeCheck(VersionByte.ACCOUNT_ID, data);
  }

  /// Decodes strkey [accountId] (G...) to raw data.
  static Uint8List decodeStellarAccountId(String accountId) {
    return decodeCheck(VersionByte.ACCOUNT_ID, accountId);
  }

  /// Checks if the given [accountId] is a valid stellar account id.
  /// Must start with "G". If it starts with "M" use [isValidStellarMuxedAccountId].
  static bool isValidStellarAccountId(String accountId) {
    try {
      decodeStellarAccountId(accountId);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Encodes [data] to strkey muxed account id (M...).
  static String encodeStellarMuxedAccountId(Uint8List data) {
    return encodeCheck(VersionByte.MUXED_ACCOUNT_ID, data);
  }

  /// Decodes strkey muxed [accountId] (M...) to raw data.
  static Uint8List decodeStellarMuxedAccountId(String accountId) {
    return decodeCheck(VersionByte.MUXED_ACCOUNT_ID, accountId);
  }

  /// Checks if the given [accountId] is a valid stellar muxed account id.
  /// Must start with "M". If it starts with "G" use [isValidStellarAccountId].
  static bool isValidStellarMuxedAccountId(String accountId) {
    try {
      decodeStellarMuxedAccountId(accountId);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Encodes [data] to strkey secret seed (S...).
  static String encodeStellarSecretSeed(Uint8List data) {
    return encodeCheck(VersionByte.SEED, data);
  }

  /// Decodes strkey [secretSeed] (S...) to raw data.
  static Uint8List decodeStellarSecretSeed(String secretSeed) {
    return decodeCheck(VersionByte.SEED, secretSeed);
  }

  /// Checks if the given [secretSeed] is a valid stellar secret seed.
  /// Must start with "S".
  static bool isValidStellarSecretSeed(String secretSeed) {
    try {
      decodeStellarSecretSeed(secretSeed);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Encodes [data] to strkey preAuthTx (T...).
  static String encodePreAuthTx(Uint8List data) {
    return encodeCheck(VersionByte.PRE_AUTH_TX, data);
  }

  /// Decodes strkey [preAuthTx] (T...) to raw data.
  static Uint8List decodePreAuthTx(String preAuthTx) {
    return decodeCheck(VersionByte.PRE_AUTH_TX, preAuthTx);
  }

  /// Checks if the given [preAuthTx] is a valid strkey PreAuthTx.
  /// Must start with "T".
  static bool isValidPreAuthTx(String preAuthTx) {
    try {
      decodePreAuthTx(preAuthTx);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Encodes [data] to strkey sha256 hash (X...).
  static String encodeSha256Hash(Uint8List data) {
    return encodeCheck(VersionByte.SHA256_HASH, data);
  }

  /// Decodes strkey [sha256Hash] (X...) to raw data.
  static Uint8List decodeSha256Hash(String sha256Hash) {
    return decodeCheck(VersionByte.SHA256_HASH, sha256Hash);
  }

  /// Checks if the given [sha256Hash] is a valid strkey sha256 hash.
  /// Must start with "X".
  static bool isValidSha256Hash(String sha256Hash) {
    try {
      decodeSha256Hash(sha256Hash);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Encodes [signedPayloadSigner] to strkey signed payload (P...).
  static String encodeSignedPayload(SignedPayloadSigner signedPayloadSigner) {
    XdrDataValue payloadDataValue =
        new XdrDataValue(signedPayloadSigner.payload);

    XdrSignedPayload xdrPayloadSigner = new XdrSignedPayload(
        signedPayloadSigner.signerAccountID.accountID.getEd25519()!,
        payloadDataValue);

    var xdrOutputStream = XdrDataOutputStream();
    XdrSignedPayload.encode(xdrOutputStream, xdrPayloadSigner);

    return encodeCheck(
        VersionByte.SIGNED_PAYLOAD, xdrOutputStream.data.toUint8List());
  }

  /// Encodes [xdrPayloadSigner] to strkey signed payload (P...).
  static String encodeXdrSignedPayload(XdrSignedPayload xdrPayloadSigner) {
    var xdrOutputStream = XdrDataOutputStream();
    XdrSignedPayload.encode(xdrOutputStream, xdrPayloadSigner);
    return encodeCheck(
        VersionByte.SIGNED_PAYLOAD, xdrOutputStream.data.toUint8List());
  }

  /// Decodes strkey [signedPayload] (P...) to [SignedPayloadSigner].
  static SignedPayloadSigner decodeSignedPayload(String signedPayload) {
    Uint8List signedPayloadRaw =
        decodeCheck(VersionByte.SIGNED_PAYLOAD, signedPayload);
    XdrSignedPayload xdrPayloadSigner =
        XdrSignedPayload.decode(XdrDataInputStream(signedPayloadRaw));

    SignedPayloadSigner result = SignedPayloadSigner.fromPublicKey(
        xdrPayloadSigner.ed25519.uint256, xdrPayloadSigner.payload.dataValue);
    return result;
  }

  /// Decodes strkey [signedPayload] (P...) to [XdrSignedPayload].
  static XdrSignedPayload decodeXdrSignedPayload(String signedPayload) {
    Uint8List signedPayloadRaw =
        decodeCheck(VersionByte.SIGNED_PAYLOAD, signedPayload);
    return XdrSignedPayload.decode(XdrDataInputStream(signedPayloadRaw));
  }

  /// Checks if the given str key [signedPayload] (P...) is a valid signed payload.
  /// Must start with "P".
  static bool isValidSignedPayload(String signedPayload) {
    try {
      decodeSignedPayload(signedPayload);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Describes how a payload of [length] bytes falls outside the widths a
  /// signed payload admits, or returns null when it is within them.
  ///
  /// The payload is bounded above by its own declaration at
  /// [StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES] bytes and
  /// bounded below by the strkey form, which has no encoding for an empty
  /// payload. The description names the violation and is worded to follow the
  /// value it is reported about, so a caller supplies its own subject.
  static String? signedPayloadLengthViolation(int length) {
    if (length < StellarProtocolConstants.SIGNED_PAYLOAD_MIN_LENGTH_BYTES) {
      return 'carries an empty payload, which has no strkey rendering';
    }
    if (length > StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES) {
      return 'carries a $length-byte payload, more than the declared '
          'maximum of '
          '${StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES}';
    }
    return null;
  }

  /// Describes how [region] disagrees with the framing a signed payload
  /// carries, or returns null when it agrees with it.
  ///
  /// The region is the payload of a signed payload strkey: the XDR encoding of
  /// a 32-byte signer key, a 4-byte big-endian payload length, and the payload
  /// padded with NUL bytes to a multiple of four. A region too short to hold
  /// the signer key and the length, one declaring a length
  /// [signedPayloadLengthViolation] refuses, one whose total width is not the
  /// width the declared length occupies, or one padding its payload with a
  /// byte other than NUL is described.
  ///
  /// The description names the violation and is worded to follow the value it
  /// is reported about, so a caller supplies its own subject.
  static String? signedPayloadFramingViolation(Uint8List region) {
    const int keyWidth =
        StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES;
    const int lengthWidth =
        StellarProtocolConstants.SIGNED_PAYLOAD_LENGTH_PREFIX_BYTES;
    const int prefix = keyWidth + lengthWidth;

    if (region.length < prefix) {
      return 'is ${region.length} bytes, too short to hold a signer key '
          'and a payload length';
    }

    final int length =
        ByteData.sublistView(region).getUint32(keyWidth, Endian.big);
    final String? bound = signedPayloadLengthViolation(length);
    if (bound != null) {
      return bound;
    }

    final int padded = length + (-length) % 4;
    if (region.length != prefix + padded) {
      return 'is ${region.length} bytes, but a $length-byte payload '
          'occupies ${prefix + padded}';
    }
    for (int i = prefix + length; i < region.length; i++) {
      if (region[i] != 0) {
        return 'pads its payload with a byte that is not NUL';
      }
    }
    return null;
  }

  /// Encodes [data] to strkey contract id (C...).
  static String encodeContractId(Uint8List data) {
    return encodeCheck(VersionByte.CONTRACT_ID, data);
  }

  /// Encodes hex [contractIdHex] to strkey contract id (C...).
  static String encodeContractIdHex(String contractIdHex) {
    return encodeCheck(VersionByte.CONTRACT_ID, Util.hexToBytes(contractIdHex));
  }

  /// Decodes strkey [contractId] (C...) to raw data.
  static Uint8List decodeContractId(String contractId) {
    return decodeCheck(VersionByte.CONTRACT_ID, contractId);
  }

  /// Checks if the given [contractId] is a valid soroban contract id.
  /// Must start with "C".
  static bool isValidContractId(String contractId) {
    try {
      decodeContractId(contractId);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Checks if the given [strKeyContractId] is a valid soroban contract id.
  /// Must start with "C". The name carries the hex rendering that
  /// [decodeContractIdHex] returns; the id it accepts is the same strkey
  /// [isValidContractId] accepts.
  static bool isValidContractIdHex(String strKeyContractId) {
    return isValidContractId(strKeyContractId);
  }

  /// Decodes [strKeyContractId] (C...) to raw bytes and returns the
  /// hex representation of the raw bytes.
  static String decodeContractIdHex(String strKeyContractId) {
    return Util.bytesToHex(
        decodeCheck(VersionByte.CONTRACT_ID, strKeyContractId));
  }

  /// Describes how the [discriminant] a claimable balance id leads with names
  /// no balance id type, or returns null when it names one.
  ///
  /// The description names the violation and is worded to follow the value it
  /// is reported about, so a caller supplies its own subject.
  static String? _claimableBalanceDiscriminantViolation(int discriminant) {
    if (discriminant ==
        XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0.value) {
      return null;
    }
    return 'carries the discriminant $discriminant, which names no '
        'claimable balance id type';
  }

  /// Encodes raw [data] to strkey claimable balance (B...).
  ///
  /// [data] is the 32-byte hash naming the balance, which is encoded behind
  /// the discriminant of the balance id type the protocol defines, that hash
  /// already carrying its own discriminant, or the 36-byte XDR encoding of the
  /// balance id opening with the four byte union discriminant, the shape
  /// Horizon reports.
  ///
  /// Throws:
  /// - [Exception]: if [data] is none of those widths, or if it carries a
  ///   discriminant that names no claimable balance id type. Such a value has
  ///   no strkey rendering.
  static String encodeClaimableBalanceId(Uint8List data) {
    const int hashWidth = StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES;
    const int taggedWidth =
        StellarProtocolConstants.CLAIMABLE_BALANCE_DISCRIMINANT_BYTES +
            hashWidth;
    const int xdrDiscriminantWidth =
        StellarProtocolConstants.XDR_UNION_DISCRIMINANT_BYTES;
    const int xdrWidth = xdrDiscriminantWidth + hashWidth;

    if (data.length == hashWidth) {
      return encodeCheck(
          VersionByte.CLAIMABLE_BALANCE,
          Uint8List.fromList([
            XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0.value,
            ...data
          ]));
    }
    if (data.length == xdrWidth) {
      final v0 = XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0.value;
      if (data[0] != 0 || data[1] != 0 || data[2] != 0 || data[3] != v0) {
        throw new Exception(
            "claimable balance id carries an XDR discriminant that names no "
            "claimable balance id type");
      }
      return encodeCheck(
          VersionByte.CLAIMABLE_BALANCE,
          Uint8List.fromList([v0, ...data.sublist(xdrDiscriminantWidth)]));
    }
    if (data.length != taggedWidth) {
      throw new Exception(
          "claimable balance id must be $hashWidth bytes (the hash), "
          "$taggedWidth bytes (the hash behind its discriminant), "
          "or $xdrWidth bytes (its XDR encoding), "
          "got ${data.length}");
    }
    // Fires ahead of encodeCheck's copy of this rule on purpose: this arm's
    // message and plain-Exception type are pinned by tests.
    final String? discriminant =
        _claimableBalanceDiscriminantViolation(data[0]);
    if (discriminant != null) {
      throw new Exception("claimable balance id $discriminant");
    }
    return encodeCheck(VersionByte.CLAIMABLE_BALANCE, data);
  }

  /// Encodes hex [claimableBalanceIdHex] to strkey claimable balance (B...).
  static String encodeClaimableBalanceIdHex(String claimableBalanceIdHex) {
    return encodeClaimableBalanceId(Util.hexToBytes(claimableBalanceIdHex));
  }

  /// Decodes [claimableBalanceId] claimable balance id (B...) to raw data.
  static Uint8List decodeClaimableBalanceId(String claimableBalanceId) {
    return decodeCheck(VersionByte.CLAIMABLE_BALANCE, claimableBalanceId);
  }

  /// Checks validity of alleged [claimableBalanceId] (B...) strkey address.
  static bool isValidClaimableBalanceId(String claimableBalanceId) {
    try {
      decodeClaimableBalanceId(claimableBalanceId);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Encodes raw [data] to strkey liquidity pool (L...).
  static String encodeLiquidityPoolId(Uint8List data) {
    return encodeCheck(VersionByte.LIQUIDITY_POOL, data);
  }

  /// Encodes hex [liquidityPoolIdHex] to strkey liquidity pool (L...).
  static String encodeLiquidityPoolIdHex(String liquidityPoolIdHex) {
    return encodeCheck(
        VersionByte.LIQUIDITY_POOL, Util.hexToBytes(liquidityPoolIdHex));
  }

  /// Decodes [liquidityPoolId] liquidity pool id (L...) to raw data.
  static Uint8List decodeLiquidityPoolId(String liquidityPoolId) {
    return decodeCheck(VersionByte.LIQUIDITY_POOL, liquidityPoolId);
  }

  /// Checks validity of alleged [liquidityPoolId] (L...) strkey address.
  static bool isValidLiquidityPoolId(String liquidityPoolId) {
    try {
      decodeLiquidityPoolId(liquidityPoolId);
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Encodes binary data to a strkey address with checksum.
  ///
  /// This is the core encoding method used by all strkey encoding functions.
  /// It verifies that [data] is a width the type of [versionByte] admits,
  /// prepends the version byte, calculates a CRC16 checksum, and encodes
  /// the result using Base32. For a signed payload (P...) it also verifies the
  /// framing of that payload, and for a claimable balance (B...) the
  /// discriminant the payload leads with, so every address this encoder mints
  /// is one [decodeCheck] reads back.
  ///
  /// Parameters:
  /// - [versionByte]: The version byte identifying the address type
  /// - [data]: The binary data to encode
  ///
  /// Returns: Base32-encoded strkey address with checksum
  ///
  /// Throws:
  /// - [FormatException]: if [versionByte] names no strkey type this codec
  ///   knows, if a signed payload disagrees with the framing
  ///   [signedPayloadFramingViolation] describes, or if a claimable balance id
  ///   carries a discriminant that names no balance id type
  /// - [Exception]: if [data] is not a width the type admits
  ///
  /// Example:
  /// ```dart
  /// Uint8List publicKey = keyPair.publicKey;
  /// String accountId = StrKey.encodeCheck(VersionByte.ACCOUNT_ID, publicKey);
  /// ```
  static String encodeCheck(VersionByte versionByte, Uint8List data) {
    final _StrKeyLengths? lengths =
        _lengthsByVersionByte[versionByte.getValue()];

    if (lengths == null) {
      throw new FormatException(
          "Unrecognized version byte ${versionByte.getValue()}");
    }

    if (data.length < lengths.payloadMin || data.length > lengths.payloadMax) {
      throw new Exception("Payload must be ${lengths.payloadRange} bytes, "
          "got ${data.length}");
    }

    if (versionByte.getValue() ==
        StellarProtocolConstants.VERSION_BYTE_SIGNED_PAYLOAD) {
      final String? framing = signedPayloadFramingViolation(data);
      if (framing != null) {
        throw new FormatException("Signed payload $framing");
      }
    }

    if (versionByte.getValue() ==
        StellarProtocolConstants.VERSION_BYTE_CLAIMABLE_BALANCE) {
      final String? discriminant =
          _claimableBalanceDiscriminantViolation(data[0]);
      if (discriminant != null) {
        throw new FormatException("Claimable balance id $discriminant");
      }
    }

    List<int> output = [];
    output.add(versionByte.getValue());
    output.addAll(data);

    Uint8List payload = Uint8List.fromList(output);
    Uint8List checksum = StrKey.calculateChecksum(payload);
    output.addAll(checksum);
    Uint8List unencoded = Uint8List.fromList(output);

    String charsEncoded = Base32.encode(unencoded);

    return charsEncoded;
  }

  /// Decodes a strkey address and verifies its checksum.
  ///
  /// This is the core decoding method used by all strkey decoding functions.
  /// It verifies the length of the encoded string, the Base32 encoding, the
  /// version byte, the CRC16 checksum and the width of the decoded payload
  /// before returning that payload. For a signed payload (P...) it also
  /// verifies the framing of that payload, and for a claimable balance (B...)
  /// the discriminant the payload leads with.
  ///
  /// The encoded string is measured before it is decoded: that bound settles
  /// the width of the payload returned and bounds the work an oversized input
  /// can cause. The payload is measured again after the checksum, holding the
  /// decoder to that width whatever the Base32 step returns, and placing the
  /// measurement where a corrupted address is reported as a checksum failure
  /// rather than as a width failure.
  ///
  /// Parameters:
  /// - [versionByte]: Expected version byte for validation
  /// - [encData]: The strkey-encoded address to decode
  ///
  /// Returns: Decoded binary data
  ///
  /// Throws:
  /// - [FormatException]: if [versionByte] names no strkey type this codec
  ///   knows, if [encData] is not a length that type admits, if [encData] is
  ///   not the Base32 rendering of the bytes it decodes to, if the leading
  ///   decoded byte is not [versionByte], if the CRC16 checksum does not match
  ///   the payload, if the payload is not a width that type admits, if a
  ///   signed payload disagrees with the framing
  ///   [signedPayloadFramingViolation] describes, or if a claimable balance id
  ///   carries a discriminant that names no balance id type
  ///
  /// Example:
  /// ```dart
  /// Uint8List publicKey = StrKey.decodeCheck(
  ///   VersionByte.ACCOUNT_ID,
  ///   "GBRPYHIL..."
  /// );
  /// ```
  static Uint8List decodeCheck(VersionByte versionByte, String encData) {
    final _StrKeyLengths? lengths =
        _lengthsByVersionByte[versionByte.getValue()];

    if (lengths == null) {
      throw new FormatException(
          "Unrecognized version byte ${versionByte.getValue()}");
    }

    if (encData.length < lengths.encodedMin ||
        encData.length > lengths.encodedMax) {
      throw new FormatException("Encoded string must be "
          "${lengths.encodedRange} characters, got ${encData.length}");
    }

    Uint8List decoded = Base32.decode(encData);
    int decodedVersionByte = decoded[0];
    Uint8List payload =
        Uint8List.fromList(decoded.getRange(0, decoded.length - 2).toList());
    Uint8List data =
        Uint8List.fromList(payload.getRange(1, payload.length).toList());
    Uint8List checksum = Uint8List.fromList(
        decoded.getRange(decoded.length - 2, decoded.length).toList());

    if (encData != Base32.encode(decoded)) {
      throw new FormatException("Invalid encoded string");
    }

    if (decodedVersionByte != versionByte.getValue()) {
      throw new FormatException("Version byte is invalid");
    }

    Uint8List expectedChecksum = StrKey.calculateChecksum(payload);

    if (!ListEquality().equals(expectedChecksum, checksum)) {
      throw new FormatException("Checksum invalid");
    }

    // The encoded-length bound above already fixes this width for every type
    // the table names. This backs that invariant rather than replacing it.
    if (data.length < lengths.payloadMin || data.length > lengths.payloadMax) {
      throw new FormatException("Decoded payload must be "
          "${lengths.payloadRange} bytes, got ${data.length}");
    }

    if (versionByte.getValue() ==
        StellarProtocolConstants.VERSION_BYTE_SIGNED_PAYLOAD) {
      final String? framing = signedPayloadFramingViolation(data);
      if (framing != null) {
        throw new FormatException("Decoded signed payload $framing");
      }
    }

    if (versionByte.getValue() ==
        StellarProtocolConstants.VERSION_BYTE_CLAIMABLE_BALANCE) {
      final String? discriminant =
          _claimableBalanceDiscriminantViolation(data[0]);
      if (discriminant != null) {
        throw new FormatException("Decoded claimable balance id $discriminant");
      }
    }

    return data;
  }

  /// Calculates the CRC16 checksum for strkey encoding.
  ///
  /// Computes a 2-byte CRC16 checksum used to verify the integrity
  /// of strkey addresses. The checksum helps detect transcription
  /// errors when addresses are manually copied or typed.
  ///
  /// This uses the CRC16-XMODEM algorithm with polynomial 0x1021.
  ///
  /// Parameters:
  /// - [bytes]: The data to checksum (version byte + payload)
  ///
  /// Returns: 2-byte checksum in little-endian format
  ///
  /// Example:
  /// ```dart
  /// Uint8List data = Uint8List.fromList([0x30, ...]);
  /// Uint8List checksum = StrKey.calculateChecksum(data);
  /// ```
  static Uint8List calculateChecksum(Uint8List bytes) {
    int crc = BitConstants.CRC16_INITIAL;
    int count = bytes.length;
    int i = 0;
    int code;

    while (count > 0) {
      code = (crc >> 8) & BitConstants.BYTE_MASK;
      code ^= bytes[i++] & BitConstants.BYTE_MASK;
      code ^= (code >> 4);
      crc = (crc << 8) & BitConstants.CRC16_MASK;
      crc ^= code;
      code = (code << 5) & BitConstants.CRC16_MASK;
      crc ^= code;
      code = (code << 7) & BitConstants.CRC16_MASK;
      crc ^= code;
      count--;
    }

    // little-endian
    return Uint8List.fromList([crc & BitConstants.BYTE_MASK, (crc >> 8) & BitConstants.BYTE_MASK]);
  }
}

/// Represents a Stellar Ed25519 keypair consisting of a public and optional private key.
///
/// A KeyPair is the fundamental cryptographic identity in Stellar. It consists of:
/// - Public key (32 bytes): Used to derive the account ID (G... address)
/// - Private key (64 bytes, optional): Used to sign transactions and authorize operations
///
/// Key management patterns:
/// - Use [random] to generate a new keypair
/// - Use [fromSecretSeed] to restore from a secret seed (S...)
/// - Use [fromAccountId] to create a signing-incapable keypair for verification
///
/// Security considerations:
/// - NEVER expose or log private keys or secret seeds
/// - Store secret seeds securely (encrypted storage, hardware wallets, etc.)
/// - Use [canSign] to verify a keypair has the private key before signing
/// - Generate keypairs in a secure environment
/// - Back up secret seeds safely - they cannot be recovered if lost
///
/// Example usage:
/// ```dart
/// // Generate a new random keypair
/// KeyPair newKeyPair = KeyPair.random();
/// print('Account ID: ${newKeyPair.accountId}'); // G...
/// print('Secret Seed: ${newKeyPair.secretSeed}'); // S...
///
/// // Restore keypair from secret seed
/// KeyPair restoredKeyPair = KeyPair.fromSecretSeed('SXXX...');
///
/// // Create verification-only keypair (no private key)
/// KeyPair publicKeyPair = KeyPair.fromAccountId('GXXX...');
/// print('Can sign: ${publicKeyPair.canSign()}'); // false
///
/// // Sign a transaction
/// if (keyPair.canSign()) {
///   transaction.sign(keyPair, Network.TESTNET);
/// }
/// ```
///
/// See also:
/// - [Transaction.sign] for signing transactions
/// - [StrKey] for address encoding/decoding
/// - [Network] for network-specific signing
/// - [Stellar developer docs](https://developers.stellar.org)
class KeyPair {
  Uint8List _mPublicKey;
  Uint8List? _mPrivateKey;

  /// Creates a new KeyPair from raw public and private key bytes.
  ///
  /// Parameters:
  /// - [_mPublicKey]: 32-byte Ed25519 public key
  /// - [privateKey]: Optional 64-byte Ed25519 private key (signing key)
  ///
  /// Note: Most applications should use factory methods instead:
  /// - [random] to generate new keypairs
  /// - [fromSecretSeed] to restore from secret seed
  /// - [fromAccountId] to create verification-only keypairs
  KeyPair(this._mPublicKey, Uint8List? privateKey) {
    _mPrivateKey = privateKey;
  }

  /// Returns true if this Keypair is capable of signing.
  bool canSign() {
    return _mPrivateKey != null;
  }

  /// Creates a new KeyPair object from a Stellar secret [seed] ("S...").
  static KeyPair fromSecretSeed(String seed) {
    Uint8List decoded = StrKey.decodeStellarSecretSeed(seed);
    KeyPair keypair = fromSecretSeedList(decoded);
    return keypair;
  }

  /// Creates a new KeyPair object from a raw 32 byte secret [seed].
  ///
  /// Throws:
  /// - [ArgumentError]: if [seed] is not
  ///   [StellarProtocolConstants.ED25519_PRIVATE_KEY_LENGTH_BYTES] bytes, the
  ///   only width an Ed25519 seed has
  static KeyPair fromSecretSeedList(Uint8List seed) {
    if (seed.length !=
        StellarProtocolConstants.ED25519_PRIVATE_KEY_LENGTH_BYTES) {
      throw ArgumentError("Secret seed must be "
          "${StellarProtocolConstants.ED25519_PRIVATE_KEY_LENGTH_BYTES} bytes, "
          "got ${seed.length}");
    }
    ed25519.SigningKey sk = ed25519.SigningKey.fromSeed(seed);
    return new KeyPair(sk.publicKey.asTypedList, sk.asTypedList);
  }

  /// Creates a new KeyPair object from a stellar [accountId].
  static KeyPair fromAccountId(String accountId) {
    String toDecode = accountId;

    if (toDecode.startsWith('M')) {
      MuxedAccount m = MuxedAccount.fromMed25519AccountId(toDecode);
      toDecode = m.ed25519AccountId;
    }
    Uint8List decoded = StrKey.decodeStellarAccountId(toDecode);
    return fromPublicKey(decoded);
  }

  /// Creates a new KeyPair object from a 32 byte [publicKey] address.
  ///
  /// Throws:
  /// - [ArgumentError]: if [publicKey] is not
  ///   [StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES] bytes, the
  ///   only width an Ed25519 public key has
  static KeyPair fromPublicKey(Uint8List publicKey) {
    if (publicKey.length !=
        StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES) {
      throw ArgumentError("Public key must be "
          "${StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES} bytes, "
          "got ${publicKey.length}");
    }
    return new KeyPair(publicKey, null);
  }

  /// Generates a random Stellar KeyPair object.
  static KeyPair random() {
    ed25519.SigningKey sk = ed25519.SigningKey.generate();
    return new KeyPair(sk.publicKey.asTypedList, sk.asTypedList);
  }

  /// Returns the human readable account ID of this key pair.
  String get accountId => StrKey.encodeStellarAccountId(_mPublicKey);

  ///Returns the human readable secret seed of this key pair.
  String get secretSeed => StrKey.encodeStellarSecretSeed(
      ed25519.SigningKey.fromValidBytes(_mPrivateKey!).seed.asTypedList);

  Uint8List get publicKey => _mPublicKey;

  Uint8List? get privateKey => _mPrivateKey;

  XdrSignatureHint get signatureHint {
    XdrDataOutputStream xdrOutputStream = new XdrDataOutputStream();
    XdrPublicKey.encode(xdrOutputStream, this.xdrPublicKey);
    Uint8List publicKeyBytes = Uint8List.fromList(xdrOutputStream.bytes);
    Uint8List signatureHintBytes = Uint8List.fromList(publicKeyBytes
        .getRange(publicKeyBytes.length - 4, publicKeyBytes.length)
        .toList());

    return new XdrSignatureHint(signatureHintBytes);
  }

  XdrMuxedAccount get xdrMuxedAccount {
    XdrMuxedAccount xdrMuxAccount =
        XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
    xdrMuxAccount.ed25519 = xdrPublicKey.getEd25519();
    return xdrMuxAccount;
  }

  XdrPublicKey get xdrPublicKey {
    XdrPublicKey publicKey =
        new XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
    publicKey.setEd25519(new XdrUint256(this.publicKey));
    return publicKey;
  }

  XdrSignerKey get xdrSignerKey {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
    signerKey.ed25519 = new XdrUint256(this.publicKey);
    return signerKey;
  }

  /// Creates a KeyPair from an XDR public key.
  ///
  /// Returns: Verification-only keypair (no private key)
  static KeyPair fromXdrPublicKey(XdrPublicKey key) {
    return KeyPair.fromPublicKey(key.getEd25519()!.uint256);
  }

  /// Creates a KeyPair from an XDR account ID.
  ///
  /// Returns: Verification-only keypair (no private key)
  static KeyPair fromXdrAccountId(XdrAccountID accountId) {
    return KeyPair.fromPublicKey(accountId.accountID.getEd25519()!.uint256);
  }

  /// Creates a KeyPair from an XDR signer key.
  ///
  /// Returns: Verification-only keypair (no private key)
  static KeyPair fromXdrSignerKey(XdrSignerKey key) {
    return KeyPair.fromPublicKey(key.ed25519!.uint256);
  }

  /// Signs the provided data with this keypair's private key.
  ///
  /// Creates an Ed25519 signature over the provided [data] using this keypair's
  /// private key. This method requires the keypair to have a private key
  /// (check with [canSign] first).
  ///
  /// Parameters:
  /// - [data]: The raw bytes to sign (typically a transaction hash)
  ///
  /// Returns: 64-byte Ed25519 signature as Uint8List.
  ///
  /// Throws:
  /// - [Exception]: If the keypair does not contain a private key
  ///
  /// Example:
  /// ```dart
  /// KeyPair keyPair = KeyPair.fromSecretSeed(secretSeed);
  /// Uint8List dataToSign = Uint8List.fromList([1, 2, 3, 4]);
  /// Uint8List signature = keyPair.sign(dataToSign);
  /// ```
  ///
  /// Security notes:
  /// - Only sign data you trust and understand
  /// - Signatures are deterministic for the same input
  /// - Never sign arbitrary data from untrusted sources
  ///
  /// See also:
  /// - [signDecorated] for creating decorated signatures for transactions
  /// - [signPayloadDecorated] for signed payload signers (CAP-40)
  /// - [verify] to verify signatures
  Uint8List sign(Uint8List data) {
    if (_mPrivateKey == null) {
      throw new Exception(
          "KeyPair does not contain secret key. Use KeyPair.fromSecretSeed method to create a new KeyPair with a secret key.");
    }

    ed25519.SigningKey sk = ed25519.SigningKey.fromValidBytes(_mPrivateKey!);
    ed25519.SignedMessage sm = sk.sign(data);
    return sm.signature.asTypedList;
  }

  /// Sign the provided payload data for payload signer where the input is the data being signed.
  /// Per the [CAP-40 Signature spec](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md#signature-hint)
  ///
  /// @param signerPayload the payload signers raw data to sign
  /// @return XdrDecoratedSignature
  XdrDecoratedSignature signPayloadDecorated(Uint8List signerPayload) {
    XdrDecoratedSignature payloadSignature = signDecorated(signerPayload);

    Uint8List hint = Uint8List(4);
    if (signerPayload.length > hint.length) {
      List.copyRange(hint, 0, signerPayload, signerPayload.length - hint.length,
          signerPayload.length);
    } else {
      List.copyRange(hint, 0, signerPayload, 0, signerPayload.length);
    }

    for (var i = 0; i < hint.length; i++) {
      hint[i] ^= payloadSignature.hint.signatureHint[i];
    }

    payloadSignature.hint = XdrSignatureHint(hint);
    return payloadSignature;
  }

  /// Creates a decorated signature for the provided data.
  ///
  /// A decorated signature combines the signature with a hint (last 4 bytes of
  /// the public key) that helps identify which key was used for signing. This is
  /// the format used for transaction signatures in Stellar.
  ///
  /// Parameters:
  /// - [data]: The raw bytes to sign (typically transaction hash)
  ///
  /// Returns: [XdrDecoratedSignature] containing the signature and hint.
  ///
  /// Throws:
  /// - [Exception]: If the keypair does not contain a private key
  ///
  /// Example:
  /// ```dart
  /// KeyPair keyPair = KeyPair.fromSecretSeed(secretSeed);
  /// Uint8List txHash = transaction.hash(Network.TESTNET);
  /// XdrDecoratedSignature decoratedSig = keyPair.signDecorated(txHash);
  /// ```
  ///
  /// Note: This method is typically used internally by [Transaction.sign].
  /// For normal transaction signing, use [Transaction.sign] instead.
  ///
  /// See also:
  /// - [Transaction.sign] for the standard way to sign transactions
  /// - [signPayloadDecorated] for signed payload signers
  XdrDecoratedSignature signDecorated(Uint8List data) {
    Uint8List signatureBytes = this.sign(data);
    XdrSignature signature = XdrSignature(signatureBytes);
    return new XdrDecoratedSignature(this.signatureHint, signature);
  }

  /// Verify the provided [data] and [signature] match this keypair's public key.
  bool verify(Uint8List data, Uint8List signature) {
    try {
      ed25519.VerifyKey vk = new ed25519.VerifyKey(_mPublicKey);
      var sigLength = signature.length;
      var dataLength = data.length;
      Uint8List sd = Uint8List(sigLength + dataLength);
      for (int i = 0; i < sigLength; i++) sd[i] = signature[i];
      for (int i = 0; i < dataLength; i++) sd[i + sigLength] = data[i];

      ed25519.SignedMessage sm =
          ed25519.SignedMessage.fromList(signedMessage: sd);
      return vk.verifySignedMessage(signedMessage: sm);
    } catch (e) {
      return false;
    }
  }

  /// UTF-8 encoded prefix prepended to all messages before hashing,
  /// as defined by [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
  static final Uint8List _messagePrefix =
      Uint8List.fromList(utf8.encode('Stellar Signed Message:\n'));

  /// Computes the SHA-256 hash of the SEP-53 prefixed message.
  ///
  /// Concatenates the [_messagePrefix] with [message] and returns the
  /// SHA-256 digest. This is the canonical message hash used for both
  /// signing and verification as specified by SEP-53.
  static Uint8List _calculateMessageHash(Uint8List message) {
    Uint8List payload = Uint8List(_messagePrefix.length + message.length);
    payload.setRange(0, _messagePrefix.length, _messagePrefix);
    payload.setRange(_messagePrefix.length, payload.length, message);
    return Util.hash(payload);
  }

  /// Signs an arbitrary binary [message] according to
  /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
  ///
  /// The message is prefixed with `"Stellar Signed Message:\n"`, hashed with
  /// SHA-256, and the resulting digest is signed with this keypair's Ed25519
  /// private key.
  ///
  /// Parameters:
  /// - [message]: The raw bytes of the message to sign.
  ///
  /// Returns: A 64-byte Ed25519 signature as [Uint8List]. To transmit the
  /// signature as a string, encode it using base64 (`base64.encode(signature)`)
  /// or hex (`Util.bytesToHex(signature)`). SEP-53 does not mandate a specific
  /// string encoding.
  ///
  /// Throws:
  /// - [Exception]: If this keypair does not contain a private key.
  ///   Use [canSign] to check before calling this method.
  ///
  /// Applications should display the message content to the user for
  /// confirmation before signing.
  ///
  /// See also:
  /// - [signMessageString] for signing a UTF-8 string message
  /// - [verifyMessage] for verifying a signed message
  Uint8List signMessage(Uint8List message) {
    Uint8List messageHash = _calculateMessageHash(message);
    return sign(messageHash);
  }

  /// Signs an arbitrary UTF-8 string [message] according to
  /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
  ///
  /// The [message] is encoded to UTF-8 bytes, prefixed with
  /// `"Stellar Signed Message:\n"`, hashed with SHA-256, and the resulting
  /// digest is signed with this keypair's Ed25519 private key.
  ///
  /// Parameters:
  /// - [message]: The string message to sign (will be UTF-8 encoded).
  ///
  /// Returns: A 64-byte Ed25519 signature as [Uint8List]. To transmit the
  /// signature as a string, encode it using base64 (`base64.encode(signature)`)
  /// or hex (`Util.bytesToHex(signature)`). SEP-53 does not mandate a specific
  /// string encoding.
  ///
  /// Throws:
  /// - [Exception]: If this keypair does not contain a private key.
  ///   Use [canSign] to check before calling this method.
  ///
  /// Applications should display the message content to the user for
  /// confirmation before signing.
  ///
  /// See also:
  /// - [signMessage] for signing raw binary messages
  /// - [verifyMessageString] for verifying a signed string message
  Uint8List signMessageString(String message) {
    Uint8List messageBytes = Uint8List.fromList(utf8.encode(message));
    return signMessage(messageBytes);
  }

  /// Verifies a binary [message] and its [signature] according to
  /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
  ///
  /// The [message] is prefixed with `"Stellar Signed Message:\n"`, hashed with
  /// SHA-256, and the resulting digest is verified against the provided
  /// [signature] using this keypair's Ed25519 public key.
  ///
  /// Parameters:
  /// - [message]: The raw bytes of the original message.
  /// - [signature]: The 64-byte Ed25519 signature to verify. If the signature
  ///   was received as a string, decode it first using `base64.decode(str)`
  ///   or `Util.hexToBytes(str)` depending on the encoding used by the sender.
  ///
  /// Returns: `true` if the signature is valid for the given message and this
  /// keypair's public key, `false` otherwise.
  ///
  /// See also:
  /// - [verifyMessageString] for verifying a UTF-8 string message
  /// - [signMessage] for signing binary messages
  bool verifyMessage(Uint8List message, Uint8List signature) {
    Uint8List messageHash = _calculateMessageHash(message);
    return verify(messageHash, signature);
  }

  /// Verifies a UTF-8 string [message] and its [signature] according to
  /// [SEP-53](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0053.md).
  ///
  /// The [message] is encoded to UTF-8 bytes, prefixed with
  /// `"Stellar Signed Message:\n"`, hashed with SHA-256, and the resulting
  /// digest is verified against the provided [signature] using this keypair's
  /// Ed25519 public key.
  ///
  /// Parameters:
  /// - [message]: The original string message (will be UTF-8 encoded).
  /// - [signature]: The 64-byte Ed25519 signature to verify. If the signature
  ///   was received as a string, decode it first using `base64.decode(str)`
  ///   or `Util.hexToBytes(str)` depending on the encoding used by the sender.
  ///
  /// Returns: `true` if the signature is valid for the given message and this
  /// keypair's public key, `false` otherwise.
  ///
  /// See also:
  /// - [verifyMessage] for verifying raw binary messages
  /// - [signMessageString] for signing string messages
  bool verifyMessageString(String message, Uint8List signature) {
    Uint8List messageBytes = Uint8List.fromList(utf8.encode(message));
    return verifyMessage(messageBytes, signature);
  }
}

/// Data model for the [signed payload signer ](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md#xdr-changes)
class SignedPayloadSigner {
  XdrAccountID _signerAccountID;
  Uint8List _payload;

  /// Creates a signed payload signer with account ID and payload data.
  ///
  /// This constructor validates that the payload length is within the range the
  /// wire format carries and that the signer account uses an ED25519 public key.
  ///
  /// Parameters:
  /// - [_signerAccountID] The XDR account ID of the signer (must be ED25519)
  /// - [_payload] The binary payload data to be signed (1 to 64 bytes)
  ///
  /// Throws:
  /// - [Exception] If payload is empty, exceeds 64 bytes, or account is not ED25519
  SignedPayloadSigner(this._signerAccountID, this._payload) {
    if (_payload.length <
        StellarProtocolConstants.SIGNED_PAYLOAD_MIN_LENGTH_BYTES) {
      throw Exception("invalid payload length, must be at least " +
          StellarProtocolConstants.SIGNED_PAYLOAD_MIN_LENGTH_BYTES.toString());
    }
    if (_payload.length > StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES) {
      throw Exception("invalid payload length, must be at most " +
          StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES.toString());
    }
    if (_signerAccountID.accountID.getEd25519() == null) {
      throw Exception(
          "invalid payload signer, only ED25519 public key accounts are supported currently");
    }
  }

  /// Creates a signed payload signer from an account ID.
  ///
  /// A signed payload signer names the ed25519 key that signs, so [accountId]
  /// is an account id (G...). A muxed account id (M...) names a subaccount of
  /// one rather than a key, and is refused rather than read as the key it
  /// multiplexes.
  ///
  /// Parameters:
  /// - [accountId] The Stellar account ID (G... format)
  /// - [payload] Binary payload data to be signed
  ///
  /// Returns: SignedPayloadSigner instance
  ///
  /// Throws:
  /// - [ArgumentError]: if [accountId] is a muxed account id
  /// - [FormatException]: if [accountId] is not an account id this codec reads
  /// - [Exception]: if [payload] is not a width a signed payload carries
  static SignedPayloadSigner fromAccountId(
      String accountId, Uint8List payload) {
    if (accountId.startsWith('M')) {
      throw ArgumentError("A signed payload signer takes an ed25519 account id "
          "(G...), not a muxed account id (M...)");
    }
    XdrAccountID accId = XdrAccountID(
        KeyPair.fromPublicKey(StrKey.decodeStellarAccountId(accountId))
            .xdrPublicKey);
    return SignedPayloadSigner(accId, payload);
  }

  /// Creates a signed payload signer from a public key.
  ///
  /// Parameters:
  /// - [signerED25519PublicKey] Raw ED25519 public key bytes
  /// - [payload] Binary payload data to be signed
  ///
  /// Returns: SignedPayloadSigner instance
  static SignedPayloadSigner fromPublicKey(
      Uint8List signerED25519PublicKey, Uint8List payload) {
    XdrAccountID accId = XdrAccountID(
        KeyPair.fromPublicKey(signerED25519PublicKey).xdrPublicKey);
    return SignedPayloadSigner(accId, payload);
  }

  /// Gets the signer account ID.
  ///
  /// Returns: The [XdrAccountID] of the signer account
  XdrAccountID get signerAccountID => _signerAccountID;

  /// Gets the payload data.
  ///
  /// Returns: The raw payload bytes
  Uint8List get payload => _payload;
}

/// SignerKey is a helper class that creates XdrSignerKey objects.
class SignerKey {
  /// Create `ed25519PublicKey` XdrSignerKey from the given [keyPair].
  static XdrSignerKey ed25519PublicKey(KeyPair keyPair) {
    return keyPair.xdrSignerKey;
  }

  /// Create `sha256Hash` XdrSignerKey from a sha256 [hash] of a preimage.
  static XdrSignerKey sha256Hash(Uint8List hash) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
    XdrUint256 value = SignerKey._createUint256(hash);
    signerKey.hashX = value;
    return signerKey;
  }

  /// Create `preAuthTx` XdrSignerKey from a Transaction [tx].
  static XdrSignerKey preAuthTx(Transaction tx, Network network) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
    XdrUint256 value = SignerKey._createUint256(tx.hash(network));
    signerKey.preAuthTx = value;
    return signerKey;
  }

  /// Create `preAuthTxHash` XdrSignerKey from a preAuthTxHash [hash].
  static XdrSignerKey preAuthTxHash(Uint8List hash) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
    XdrUint256 value = SignerKey._createUint256(hash);
    signerKey.preAuthTx = value;
    return signerKey;
  }

  /// Create `signedPayload` XdrSignerKey from a SignedPayloadSigner.
  ///
  /// Parameters:
  /// - [signedPayloadSigner] The signed payload signer containing account and payload
  ///
  /// Returns: XdrSignerKey configured for signed payload (CAP-40)
  static XdrSignerKey signedPayload(SignedPayloadSigner signedPayloadSigner) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD);
    XdrDataValue payloadDataValue =
        new XdrDataValue(signedPayloadSigner.payload);

    XdrSignedPayload payloadSigner = new XdrSignedPayload(
        signedPayloadSigner.signerAccountID.accountID.getEd25519()!,
        payloadDataValue);

    signerKey.signedPayload = payloadSigner;
    return signerKey;
  }

  static XdrUint256 _createUint256(Uint8List hash) {
    if (hash.length != StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      throw new Exception("hash must be ${StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES} bytes long");
    }
    return new XdrUint256(hash);
  }
}
