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

class VersionByte {
  final _value;

  const VersionByte._internal(this._value);

  toString() => 'VersionByte.$_value';

  VersionByte(this._value);

  getValue() => this._value;

  static const ACCOUNT_ID = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_ACCOUNT_ID); // G
  static const MUXED_ACCOUNT_ID = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_MUXED_ACCOUNT); // M
  static const SEED = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_SEED); // S
  static const PRE_AUTH_TX = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_PRE_AUTH_TX); // T
  static const SHA256_HASH = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_SHA256_HASH); // X
  static const SIGNED_PAYLOAD = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_SIGNED_PAYLOAD); // P
  static const CONTRACT_ID = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_CONTRACT_ID); // C
  static const LIQUIDITY_POOL = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_LIQUIDITY_POOL); // L
  static const CLAIMABLE_BALANCE = const VersionByte._internal(StellarProtocolConstants.VERSION_BYTE_CLAIMABLE_BALANCE); // B
}

/// StrKey is a helper class that allows encoding and decoding Stellar keys
/// to/from strings, i.e. between their binary (Uint8List) and
/// string (i.e. "GABCD...", etc.) representations.
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

  static Uint8List calculateChecksum(Uint8List bytes) {
    fixNum.Int32 crc = fixNum.Int32(0x0000);
    int count = bytes.length;
    int i = 0;
    fixNum.Int32 code;

    while (count > 0) {
      code = crc.shiftRightUnsigned(8) & 0xFF;
      code ^= bytes[i++] & 0xFF;
      code ^= code.shiftRightUnsigned(4);
      crc = crc << 8 & 0xFFFF;
      crc ^= code;
      code = code << 5 & 0xFFFF;
      crc ^= code;
      code = code << 7 & 0xFFFF;
      crc ^= code;
      count--;
    }

    // little-endian
    return Uint8List.fromList([crc.toInt(), crc.shiftRightUnsigned(8).toInt()]);
  }
}

/// Holds a Stellar keypair.
class KeyPair {
  Uint8List _mPublicKey;
  Uint8List? _mPrivateKey;

  /// Creates a new KeyPair from the given [publicKey] and [privateKey].
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

  /// Sign the provided data with the keypair's private key [data].
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
  /// Per the <a href="https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md#signature-hint" CAP-40 Signature spec</a>
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

  /// Sign the provided [data] with the keypair's private key.
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

/// Data model for the <a href="https://github.com/stellar/stellar-protocol/blob/master/core/cap-0040.md#xdr-changes">signed payload signer </a>
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

  XdrAccountID get signerAccountID => _signerAccountID;
  Uint8List get payload => _payload;
}

/// SignerKey is a helper class that creates XdrSignerKey objects.
class SignerKey {
  /// Create <code>ed25519PublicKey</code> XdrSignerKey from the given [keyPair].
  static XdrSignerKey ed25519PublicKey(KeyPair keyPair) {
    return keyPair.xdrSignerKey;
  }

  /// Create <code>sha256Hash</code> XdrSignerKey from a sha256 [hash] of a preimage.
  static XdrSignerKey sha256Hash(Uint8List hash) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
    XdrUint256 value = SignerKey._createUint256(hash);
    signerKey.hashX = value;
    return signerKey;
  }

  /// Create <code>preAuthTx</code> XdrSignerKey from a Transaction [tx].
  static XdrSignerKey preAuthTx(Transaction tx, Network network) {
    XdrSignerKey signerKey =
        new XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
    XdrUint256 value = SignerKey._createUint256(tx.hash(network));
    signerKey.preAuthTx = value;
    return signerKey;
  }

  /// Create <code>preAuthTxHash</code> XdrSignerKey from a preAuthTxHash[hash].
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
