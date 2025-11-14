// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart' as fixNum;
import 'package:pinenacl/ed25519.dart' as ed25519;
import 'muxed_account.dart';
import 'dart:typed_data';
import "util.dart";
import 'network.dart';
import 'transaction.dart';
import 'xdr/xdr_data_io.dart';
import 'xdr/xdr_signing.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_data_entry.dart';
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
  final _value;

  const VersionByte._internal(this._value);

  toString() => 'VersionByte.$_value';

  /// Creates a version byte with the specified value for Stellar address encoding.
  VersionByte(this._value);

  getValue() => this._value;

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
    if (accountId.length != StellarProtocolConstants.STRKEY_ACCOUNT_ID_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodeStellarAccountId(accountId);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
    if (decoded.length != StellarProtocolConstants.ED25519_PUBLIC_KEY_LENGTH_BYTES) {
      return false;
    }
    return true;
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
    if (accountId.length != StellarProtocolConstants.STRKEY_MUXED_ACCOUNT_ID_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodeStellarMuxedAccountId(accountId);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }

    if (decoded.length != StellarProtocolConstants.MUXED_ACCOUNT_DECODED_LENGTH) {
      return false;
    }
    return true;
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
    if (secretSeed.length != StellarProtocolConstants.STRKEY_SECRET_SEED_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodeStellarSecretSeed(secretSeed);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }

    if (decoded.length != StellarProtocolConstants.ED25519_PRIVATE_KEY_LENGTH_BYTES) {
      return false;
    }
    return true;
  }

  /// Encodes [data] to strkey preAuthTx (T...).
  static String encodePreAuthTx(Uint8List data) {
    return encodeCheck(VersionByte.PRE_AUTH_TX, data);
  }

  /// Decodes strkey [secretSeed] (S...) to raw data.
  static Uint8List decodePreAuthTx(String preAuthTx) {
    return decodeCheck(VersionByte.PRE_AUTH_TX, preAuthTx);
  }

  /// Checks if the given [preAuthTx] is a valid strkey PreAuthTx.
  /// Must start with "T".
  static bool isValidPreAuthTx(String preAuthTx) {
    if (preAuthTx.length != StellarProtocolConstants.STRKEY_PRE_AUTH_TX_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodePreAuthTx(preAuthTx);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }

    if (decoded.length != StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      return false;
    }
    return true;
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
    if (sha256Hash.length != StellarProtocolConstants.STRKEY_SHA256_HASH_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodeSha256Hash(sha256Hash);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
    if (decoded.length != StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      return false;
    }
    return true;
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
    if (signedPayload.length < StellarProtocolConstants.STRKEY_SIGNED_PAYLOAD_MIN_LENGTH ||
        signedPayload.length > StellarProtocolConstants.STRKEY_SIGNED_PAYLOAD_MAX_LENGTH) {
      return false;
    }
    try {
      decodeSignedPayload(signedPayload);
      return true;
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
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
    if (contractId.length != StellarProtocolConstants.STRKEY_CONTRACT_ID_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodeContractId(contractId);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
    if (decoded.length != StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      return false;
    }
    return true;
  }

  /// Checks if the given [contractIdHex] is a valid soroban contract id.
  /// Must be in hex format.
  static bool isValidContractIdHex(String contractIdHex) {
    try {
      decodeContractIdHex(contractIdHex);
      return true;
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
  }

  /// Decodes [strKeyContractId] (C...) to raw bytes and returns the
  /// hex representation of the raw bytes.
  static String decodeContractIdHex(String strKeyContractId) {
    return Util.bytesToHex(
        decodeCheck(VersionByte.CONTRACT_ID, strKeyContractId));
  }

  /// Encodes raw [data] to strkey claimable balance (B...).
  static String encodeClaimableBalanceId(Uint8List data) {
    if (data.length == StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      // type is missing so let's append it
      return encodeCheck(VersionByte.CLAIMABLE_BALANCE, Uint8List.fromList([0, ...data]));
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
    if (claimableBalanceId.length != StellarProtocolConstants.STRKEY_CLAIMABLE_BALANCE_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodeClaimableBalanceId(claimableBalanceId);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
    if (decoded.length != StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES + 1) {
      // +1 byte for discriminant
      return false;
    }
    return true;
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
    if (liquidityPoolId.length != StellarProtocolConstants.STRKEY_LIQUIDITY_POOL_LENGTH) {
      return false;
    }
    Uint8List decoded;
    try {
      decoded = decodeLiquidityPoolId(liquidityPoolId);
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
    if (decoded.length != StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      return false;
    }
    return true;
  }

  /// Encodes binary data to a strkey address with checksum.
  ///
  /// This is the core encoding method used by all strkey encoding functions.
  /// It prepends the version byte, calculates a CRC16 checksum, and encodes
  /// the result using Base32.
  ///
  /// Parameters:
  /// - [versionByte]: The version byte identifying the address type
  /// - [data]: The binary data to encode
  ///
  /// Returns: Base32-encoded strkey address with checksum
  ///
  /// Example:
  /// ```dart
  /// Uint8List publicKey = keyPair.publicKey;
  /// String accountId = StrKey.encodeCheck(VersionByte.ACCOUNT_ID, publicKey);
  /// ```
  static String encodeCheck(VersionByte versionByte, Uint8List data) {
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
  /// It verifies the Base32 encoding, version byte, and CRC16 checksum before
  /// returning the decoded data.
  ///
  /// Parameters:
  /// - [versionByte]: Expected version byte for validation
  /// - [encData]: The strkey-encoded address to decode
  ///
  /// Returns: Decoded binary data
  ///
  /// Throws:
  /// - [FormatException]: If encoding, version byte, or checksum is invalid
  ///
  /// Example:
  /// ```dart
  /// Uint8List publicKey = StrKey.decodeCheck(
  ///   VersionByte.ACCOUNT_ID,
  ///   "GBRPYHIL..."
  /// );
  /// ```
  static Uint8List decodeCheck(VersionByte versionByte, String encData) {
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
    fixNum.Int32 crc = fixNum.Int32(BitConstants.CRC16_INITIAL);
    int count = bytes.length;
    int i = 0;
    fixNum.Int32 code;

    while (count > 0) {
      code = crc.shiftRightUnsigned(8) & BitConstants.BYTE_MASK;
      code ^= bytes[i++] & BitConstants.BYTE_MASK;
      code ^= code.shiftRightUnsigned(4);
      crc = crc << 8 & BitConstants.CRC16_MASK;
      crc ^= code;
      code = code << 5 & BitConstants.CRC16_MASK;
      crc ^= code;
      code = code << 7 & BitConstants.CRC16_MASK;
      crc ^= code;
      count--;
    }

    // little-endian
    return Uint8List.fromList([crc.toInt(), crc.shiftRightUnsigned(8).toInt()]);
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
  static KeyPair fromSecretSeedList(Uint8List seed) {
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
  static KeyPair fromPublicKey(Uint8List publicKey) {
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

  static KeyPair fromXdrPublicKey(XdrPublicKey key) {
    return KeyPair.fromPublicKey(key.getEd25519()!.uint256);
  }

  static KeyPair fromXdrAccountId(XdrAccountID accountId) {
    return KeyPair.fromPublicKey(accountId.accountID.getEd25519()!.uint256);
  }

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
}

/// Data model for the [signed payload signer ](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md#xdr-changes)
class SignedPayloadSigner {
  XdrAccountID _signerAccountID;
  Uint8List _payload;

  SignedPayloadSigner(this._signerAccountID, this._payload) {
    if (_payload.length > StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES) {
      throw Exception("invalid payload length, must be less than " +
          StellarProtocolConstants.SIGNED_PAYLOAD_MAX_LENGTH_BYTES.toString());
    }
    if (_signerAccountID.accountID.getEd25519() == null) {
      throw Exception(
          "invalid payload signer, only ED25519 public key accounts are supported currently");
    }
  }

  static SignedPayloadSigner fromAccountId(
      String accountId, Uint8List payload) {
    XdrAccountID accId =
        XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey);
    return SignedPayloadSigner(accId, payload);
  }

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

  /// Create `preAuthTxHash` XdrSignerKey from a preAuthTxHash[hash].
  static XdrSignerKey preAuthTxHash(Uint8List hash) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
    XdrUint256 value = SignerKey._createUint256(hash);
    signerKey.preAuthTx = value;
    return signerKey;
  }

  static XdrSignerKey signedPayload(SignedPayloadSigner signedPayloadSigner) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD);
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
