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

class VersionByte {
  final _value;

  const VersionByte._internal(this._value);

  toString() => 'VersionByte.$_value';

  VersionByte(this._value);

  getValue() => this._value;

  static const ACCOUNT_ID = const VersionByte._internal((6 << 3)); // G
  static const MUXED_ACCOUNT_ID = const VersionByte._internal((12 << 3)); // M
  static const SEED = const VersionByte._internal((18 << 3)); // S
  static const PRE_AUTH_TX = const VersionByte._internal((19 << 3)); // T
  static const SHA256_HASH = const VersionByte._internal((23 << 3)); // X
  static const SIGNED_PAYLOAD = const VersionByte._internal((15 << 3)); // P
  static const CONTRACT_ID = const VersionByte._internal((2 << 3)); // C
}

class StrKey {
  static String encodeStellarAccountId(Uint8List data) {
    return encodeCheck(VersionByte.ACCOUNT_ID, data);
  }

  static Uint8List decodeStellarAccountId(String data) {
    return decodeCheck(VersionByte.ACCOUNT_ID, data);
  }

  static String encodeStellarMuxedAccountId(Uint8List data) {
    return encodeCheck(VersionByte.MUXED_ACCOUNT_ID, data);
  }

  static Uint8List decodeStellarMuxedAccountId(String data) {
    return decodeCheck(VersionByte.MUXED_ACCOUNT_ID, data);
  }

  static String encodeStellarSecretSeed(Uint8List data) {
    return encodeCheck(VersionByte.SEED, data);
  }

  static Uint8List decodeStellarSecretSeed(String data) {
    return decodeCheck(VersionByte.SEED, data);
  }

  static String encodePreAuthTx(Uint8List data) {
    return encodeCheck(VersionByte.PRE_AUTH_TX, data);
  }

  static Uint8List decodePreAuthTx(String data) {
    return decodeCheck(VersionByte.PRE_AUTH_TX, data);
  }

  static String encodeSha256Hash(Uint8List data) {
    return encodeCheck(VersionByte.SHA256_HASH, data);
  }

  static Uint8List decodeSha256Hash(String data) {
    return decodeCheck(VersionByte.SHA256_HASH, data);
  }

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

  static String encodeXdrSignedPayload(XdrSignedPayload xdrPayloadSigner) {
    var xdrOutputStream = XdrDataOutputStream();
    XdrSignedPayload.encode(xdrOutputStream, xdrPayloadSigner);
    return encodeCheck(
        VersionByte.SIGNED_PAYLOAD, xdrOutputStream.data.toUint8List());
  }

  static SignedPayloadSigner decodeSignedPayload(String data) {
    Uint8List signedPayloadRaw = decodeCheck(VersionByte.SIGNED_PAYLOAD, data);
    XdrSignedPayload xdrPayloadSigner =
        XdrSignedPayload.decode(XdrDataInputStream(signedPayloadRaw));

    SignedPayloadSigner result = SignedPayloadSigner.fromPublicKey(
        xdrPayloadSigner.ed25519.uint256, xdrPayloadSigner.payload.dataValue);
    return result;
  }

  static XdrSignedPayload decodeXdrSignedPayload(String data) {
    Uint8List signedPayloadRaw = decodeCheck(VersionByte.SIGNED_PAYLOAD, data);
    return XdrSignedPayload.decode(XdrDataInputStream(signedPayloadRaw));
  }

  static String encodeContractId(Uint8List data) {
    return encodeCheck(VersionByte.CONTRACT_ID, data);
  }

  static String encodeContractIdHex(String contractId) {
    return encodeCheck(VersionByte.CONTRACT_ID, Util.hexToBytes(contractId));
  }

  static Uint8List decodeContractId(String data) {
    return decodeCheck(VersionByte.CONTRACT_ID, data);
  }

  static String decodeContractIdHex(String data) {
    return Util.bytesToHex(decodeCheck(VersionByte.CONTRACT_ID, data));
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

    XdrSignatureHint signatureHint = new XdrSignatureHint();
    signatureHint.signatureHint = signatureHintBytes;
    return signatureHint;
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

    //  static void copyRange<T>(List<T> target, int at, List<T> source,
    //       [int? start, int? end]) {
    Uint8List hint = Uint8List(4);
    if (signerPayload.length > hint.length) {
      List.copyRange(hint, 0, signerPayload, signerPayload.length - hint.length,
          signerPayload.length);
    } else {
      List.copyRange(hint, 0, signerPayload, 0, signerPayload.length);
    }

    for (var i = 0; i < hint.length; i++) {
      hint[i] ^= payloadSignature.hint!.signatureHint![i];
    }

    XdrSignatureHint newHint = XdrSignatureHint();
    newHint.signatureHint = hint;
    payloadSignature.hint = newHint;
    return payloadSignature;
  }

  /// Sign the provided [data] with the keypair's private key.
  XdrDecoratedSignature signDecorated(Uint8List data) {
    Uint8List signatureBytes = this.sign(data);

    XdrSignature signature = XdrSignature();
    signature.signature = signatureBytes;

    XdrDecoratedSignature decoratedSignature = new XdrDecoratedSignature();
    decoratedSignature.hint = this.signatureHint;
    decoratedSignature.signature = signature;
    return decoratedSignature;
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
  static const SIGNED_PAYLOAD_MAX_PAYLOAD_LENGTH = 64;

  XdrAccountID _signerAccountID;
  Uint8List _payload;

  SignedPayloadSigner(this._signerAccountID, this._payload) {
    if (_payload.length > SIGNED_PAYLOAD_MAX_PAYLOAD_LENGTH) {
      throw Exception("invalid payload length, must be less than " +
          SIGNED_PAYLOAD_MAX_PAYLOAD_LENGTH.toString());
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
    if (hash.length != 32) {
      throw new Exception("hash must be 32 bytes long");
    }
    return new XdrUint256(hash);
  }
}
