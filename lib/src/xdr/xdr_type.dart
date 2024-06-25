// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "dart:typed_data";
import 'package:stellar_flutter_sdk/src/key_pair.dart';

import 'xdr_data_io.dart';

class XdrInt32 {
  XdrInt32(this._int32);

  int _int32;
  int get int32 => this._int32;
  set int32(int value) => this._int32 = value;

  static encode(XdrDataOutputStream stream, XdrInt32 encodedInt32) {
    stream.writeInt(encodedInt32.int32);
  }

  static XdrInt32 decode(XdrDataInputStream stream) {
    return XdrInt32(stream.readInt());
  }
}

class XdrInt64 {
  XdrInt64(this._int64);

  int _int64;
  int get int64 => this._int64;
  set int64(int value) => this._int64 = value;

  static encode(XdrDataOutputStream stream, XdrInt64? encodedInt64) {
    stream.writeLong(encodedInt64!.int64);
  }

  static XdrInt64 decode(XdrDataInputStream stream) {
    return XdrInt64(stream.readLong());
  }
}

class XdrBigInt64 {
  XdrBigInt64(this._bigInt);

  BigInt _bigInt;
  BigInt get bigInt => this._bigInt;
  set bigInt(BigInt value) => this._bigInt = value;

  static encode(XdrDataOutputStream stream, XdrBigInt64 encodedInt64) {
    stream.writeBigInt64(encodedInt64.bigInt);
  }

  static XdrBigInt64 decode(XdrDataInputStream stream) {
    return XdrBigInt64(stream.readBigInt64());
  }
}

class XdrUint32 {
  XdrUint32(this._uint32);

  int _uint32;
  int get uint32 => this._uint32;
  set uint32(int value) => this._uint32 = value;

  static encode(XdrDataOutputStream stream, XdrUint32? encodedUint32) {
    stream.writeInt(encodedUint32!.uint32);
  }

  static XdrUint32 decode(XdrDataInputStream stream) {
    return XdrUint32(stream.readInt());
  }
}

class XdrUint64 {
  XdrUint64(this._uint64);

  int _uint64;
  int get uint64 => this._uint64;
  set uint64(int value) => this._uint64 = value;

  static encode(XdrDataOutputStream stream, XdrUint64 encodedUint64) {
    stream.writeLong(encodedUint64.uint64);
  }

  static XdrUint64 decode(XdrDataInputStream stream) {
    return XdrUint64(stream.readLong());
  }
}

class XdrUint256 {
  XdrUint256(this._uint256);

  Uint8List _uint256;
  Uint8List get uint256 => this._uint256;
  set uint256(Uint8List value) => this._uint256 = value;

  static encode(XdrDataOutputStream stream, XdrUint256? encodedUint256) {
    stream.write(encodedUint256!.uint256);
  }

  static XdrUint256 decode(XdrDataInputStream stream) {
    int uint256size = 32;
    return XdrUint256(stream.readBytes(uint256size));
  }
}

class XdrString32 {
  XdrString32(this._string32);

  String _string32;
  String get string32 => this._string32;
  set string32(String value) => this._string32 = value;

  static encode(XdrDataOutputStream stream, XdrString32? encodedString32) {
    stream.writeString(encodedString32!.string32);
  }

  static XdrString32 decode(XdrDataInputStream stream) {
    return XdrString32(stream.readString());
  }
}

class XdrString64 {
  XdrString64(this._string64);
  String _string64;
  String get string64 => this._string64;
  set string64(String value) => this._string64 = value;

  static encode(XdrDataOutputStream stream, XdrString64 encodedString64) {
    stream.writeString(encodedString64.string64);
  }

  static XdrString64 decode(XdrDataInputStream stream) {
    return XdrString64(stream.readString());
  }
}

class XdrHash {
  XdrHash(this._hash);
  Uint8List _hash;
  Uint8List get hash => this._hash;
  set hash(Uint8List value) => this._hash = value;

  static encode(XdrDataOutputStream stream, XdrHash encodedHash) {
    stream.write(encodedHash.hash);
  }

  static XdrHash decode(XdrDataInputStream stream) {
    int hashSize = 32;
    return XdrHash(stream.readBytes(hashSize));
  }
}

class XdrCurve25519Public {
  XdrCurve25519Public(this._key);
  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrCurve25519Public encodedCurve25519Public) {
    stream.write(encodedCurve25519Public.key);
  }

  static XdrCurve25519Public decode(XdrDataInputStream stream) {
    int keySize = 32;
    return XdrCurve25519Public(stream.readBytes(keySize));
  }
}

class XdrHmacSha256Key {
  XdrHmacSha256Key(this._key);
  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrHmacSha256Key encodedHmacSha256Key) {
    stream.write(encodedHmacSha256Key.key);
  }

  static XdrHmacSha256Key decode(XdrDataInputStream stream) {
    int keySize = 32;
    return XdrHmacSha256Key(stream.readBytes(keySize));
  }
}

class XdrHmacSha256Mac {
  XdrHmacSha256Mac(this._key);

  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrHmacSha256Mac encodedHmacSha256Mac) {
    stream.write(encodedHmacSha256Mac.key);
  }

  static XdrHmacSha256Mac decode(XdrDataInputStream stream) {
    int keySize = 32;
    return XdrHmacSha256Mac(stream.readBytes(keySize));
  }
}

class XdrCurve25519Secret {
  XdrCurve25519Secret(this._key);

  Uint8List _key;
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrCurve25519Secret encodedCurve25519Secret) {
    stream.write(encodedCurve25519Secret.key);
  }

  static XdrCurve25519Secret decode(XdrDataInputStream stream) {
    int keySize = 32;
    return XdrCurve25519Secret(stream.readBytes(keySize));
  }
}

class XdrThresholds {
  XdrThresholds(this._thresholds);

  Uint8List _thresholds;
  Uint8List get thresholds => this._thresholds;
  set thresholds(Uint8List value) => this._thresholds = value;

  static encode(XdrDataOutputStream stream, XdrThresholds encodedThresholds) {
    stream.write(encodedThresholds.thresholds);
  }

  static XdrThresholds decode(XdrDataInputStream stream) {
    int thresholdsSize = 4;
    return XdrThresholds(stream.readBytes(thresholdsSize));
  }
}

class XdrUpgradeType {
  XdrUpgradeType(this._upgradeType);
  Uint8List _upgradeType;
  Uint8List get upgradeType => this._upgradeType;
  set upgradeType(Uint8List value) => this._upgradeType = value;

  static encode(XdrDataOutputStream stream, XdrUpgradeType encodedUpgradeType) {
    int upgradeTypeSize = encodedUpgradeType.upgradeType.length;
    stream.writeInt(upgradeTypeSize);
    stream.write(encodedUpgradeType.upgradeType);
  }

  static XdrUpgradeType decode(XdrDataInputStream stream) {
    int upgradeTypeSize = stream.readInt();
    return XdrUpgradeType(stream.readBytes(upgradeTypeSize));
  }
}

class XdrPublicKeyType {
  final _value;
  const XdrPublicKeyType._internal(this._value);
  toString() => 'PublicKeyType.$_value';
  XdrPublicKeyType(this._value);
  get value => this._value;

  static const PUBLIC_KEY_TYPE_ED25519 = const XdrPublicKeyType._internal(0);

  static XdrPublicKeyType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return PUBLIC_KEY_TYPE_ED25519;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrPublicKeyType value) {
    stream.writeInt(value.value);
  }
}

class XdrPublicKey {
  XdrPublicKey(this._type);

  XdrPublicKeyType _type;
  XdrPublicKeyType getDiscriminant() => this._type;
  void setDiscriminant(XdrPublicKeyType value) => this._type = value;

  XdrUint256? _ed25519;
  XdrUint256? getEd25519() => this._ed25519;
  void setEd25519(XdrUint256? value) => this._ed25519 = value;

  static void encode(
      XdrDataOutputStream stream, XdrPublicKey encodedPublicKey) {
    stream.writeInt(encodedPublicKey.getDiscriminant().value);
    switch (encodedPublicKey.getDiscriminant()) {
      case XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519:
        XdrUint256.encode(stream, encodedPublicKey._ed25519);
        break;
    }
  }

  static XdrPublicKey decode(XdrDataInputStream stream) {
    XdrPublicKey decodedPublicKey =
        XdrPublicKey(XdrPublicKeyType.decode(stream));
    switch (decodedPublicKey.getDiscriminant()) {
      case XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519:
        decodedPublicKey._ed25519 = XdrUint256.decode(stream);
        break;
    }
    return decodedPublicKey;
  }

  static XdrPublicKey forAccountId(String accountId) {
    var keyPair = KeyPair.fromAccountId(accountId);
    var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
    pk.setEd25519(XdrUint256(keyPair.publicKey));
    return pk;
  }
}

class XdrValue {
  XdrValue(this._value);
  Uint8List _value;
  Uint8List get value => this._value;
  set value(Uint8List value) => this._value = value;

  static encode(XdrDataOutputStream stream, XdrValue encodedValue) {
    int valueSize = encodedValue.value.length;
    stream.writeInt(valueSize);
    stream.write(encodedValue.value);
  }

  static XdrValue decode(XdrDataInputStream stream) {
    int valueSize = stream.readInt();
    return XdrValue(stream.readBytes(valueSize));
  }
}

class XdrCryptoKeyType {
  final _value;
  const XdrCryptoKeyType._internal(this._value);
  toString() => 'CryptoKeyType.$_value';
  XdrCryptoKeyType(this._value);
  get value => this._value;

  static const KEY_TYPE_ED25519 = const XdrCryptoKeyType._internal(0);
  static const KEY_TYPE_PRE_AUTH_TX = const XdrCryptoKeyType._internal(1);
  static const KEY_TYPE_HASH_X = const XdrCryptoKeyType._internal(2);

  /// MUXED enum values for supported type are derived from the enum values above by ORing them with 0x100.
  static const KEY_TYPE_MUXED_ED25519 = const XdrCryptoKeyType._internal(256);

  static XdrCryptoKeyType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return KEY_TYPE_ED25519;
      case 1:
        return KEY_TYPE_PRE_AUTH_TX;
      case 2:
        return KEY_TYPE_HASH_X;
      case 256:
        return KEY_TYPE_MUXED_ED25519;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrCryptoKeyType value) {
    stream.writeInt(value.value);
  }
}
