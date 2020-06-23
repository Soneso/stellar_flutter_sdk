// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "dart:typed_data";
import 'xdr_data_io.dart';

class XdrInt32 {
  int _int32;
  XdrInt32();
  int get int32 => this._int32;
  set int32(int value) => this._int32 = value;

  static encode(XdrDataOutputStream stream, XdrInt32 encodedInt32) {
    stream.writeInt(encodedInt32.int32);
  }

  static XdrInt32 decode(XdrDataInputStream stream) {
    XdrInt32 decodedInt32 = XdrInt32();
    decodedInt32.int32 = stream.readInt();
    return decodedInt32;
  }
}

class XdrInt64 {
  int _int64;
  XdrInt64();
  int get int64 => this._int64;
  set int64(int value) => this._int64 = value;

  static encode(XdrDataOutputStream stream, XdrInt64 encodedInt64) {
    stream.writeLong(encodedInt64.int64);
  }

  static XdrInt64 decode(XdrDataInputStream stream) {
    XdrInt64 decodedInt64 = XdrInt64();
    decodedInt64.int64 = stream.readLong();
    return decodedInt64;
  }
}

class XdrUint32 {
  int _uint32;
  XdrUint32();
  int get uint32 => this._uint32;
  set uint32(int value) => this._uint32 = value;

  static encode(XdrDataOutputStream stream, XdrUint32 encodedUint32) {
    stream.writeInt(encodedUint32.uint32);
  }

  static XdrUint32 decode(XdrDataInputStream stream) {
    XdrUint32 decodedUint32 = XdrUint32();
    decodedUint32.uint32 = stream.readInt();
    return decodedUint32;
  }
}

class XdrUint64 {
  int _uint64;
  XdrUint64();
  int get uint64 => this._uint64;
  set uint64(int value) => this._uint64 = value;

  static encode(XdrDataOutputStream stream, XdrUint64 encodedUint64) {
    stream.writeLong(encodedUint64.uint64);
  }

  static XdrUint64 decode(XdrDataInputStream stream) {
    XdrUint64 decodedUint64 = XdrUint64();
    decodedUint64.uint64 = stream.readLong();
    return decodedUint64;
  }
}

class XdrUint256 {
  Uint8List _uint256;
  XdrUint256();
  Uint8List get uint256 => this._uint256;
  set uint256(Uint8List value) => this._uint256 = value;

  static encode(XdrDataOutputStream stream, XdrUint256 encodedUint256) {
    stream.write(encodedUint256.uint256);
  }

  static XdrUint256 decode(XdrDataInputStream stream) {
    XdrUint256 decodedUint256 = XdrUint256();
    int uint256size = 32;
    decodedUint256.uint256 = stream.readBytes(uint256size);
    return decodedUint256;
  }
}

class XdrString32 {
  String _string32;
  XdrString32();
  String get string32 => this._string32;
  set string32(String value) => this._string32 = value;

  static encode(XdrDataOutputStream stream, XdrString32 encodedString32) {
    stream.writeString(encodedString32.string32);
  }

  static XdrString32 decode(XdrDataInputStream stream) {
    XdrString32 decodedString32 = XdrString32();
    decodedString32.string32 = stream.readString();
    return decodedString32;
  }
}

class XdrString64 {
  String _string64;
  XdrString64();
  String get string64 => this._string64;
  set string64(String value) => this._string64 = value;

  static encode(XdrDataOutputStream stream, XdrString64 encodedString64) {
    stream.writeString(encodedString64.string64);
  }

  static XdrString64 decode(XdrDataInputStream stream) {
    XdrString64 decodedString64 = XdrString64();
    decodedString64.string64 = stream.readString();
    return decodedString64;
  }
}

class XdrHash {
  Uint8List _hash;
  XdrHash();
  Uint8List get hash => this._hash;
  set hash(Uint8List value) => this._hash = value;

  static encode(XdrDataOutputStream stream, XdrHash encodedHash) {
    stream.write(encodedHash.hash);
  }

  static XdrHash decode(XdrDataInputStream stream) {
    XdrHash decodedHash = XdrHash();
    int hashSize = 32;
    decodedHash.hash = stream.readBytes(hashSize);
    return decodedHash;
  }
}

class XdrCurve25519Public {
  Uint8List _key;
  XdrCurve25519Public();
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrCurve25519Public encodedCurve25519Public) {
    stream.write(encodedCurve25519Public.key);
  }

  static XdrCurve25519Public decode(XdrDataInputStream stream) {
    XdrCurve25519Public decodedCurve25519Public = XdrCurve25519Public();
    int keysize = 32;
    decodedCurve25519Public.key = stream.readBytes(keysize);
    return decodedCurve25519Public;
  }
}

class XdrHmacSha256Key {
  Uint8List _key;
  XdrHmacSha256Key();
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrHmacSha256Key encodedHmacSha256Key) {
    stream.write(encodedHmacSha256Key.key);
  }

  static XdrHmacSha256Key decode(XdrDataInputStream stream) {
    XdrHmacSha256Key decodedHmacSha256Key = XdrHmacSha256Key();
    int keysize = 32;
    decodedHmacSha256Key.key = stream.readBytes(keysize);
    return decodedHmacSha256Key;
  }
}

class XdrHmacSha256Mac {
  Uint8List _key;
  XdrHmacSha256Mac();
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrHmacSha256Mac encodedHmacSha256Mac) {
    stream.write(encodedHmacSha256Mac.key);
  }

  static XdrHmacSha256Mac decode(XdrDataInputStream stream) {
    XdrHmacSha256Mac decodedHmacSha256Mac = XdrHmacSha256Mac();
    int keysize = 32;
    decodedHmacSha256Mac.key = stream.readBytes(keysize);
    return decodedHmacSha256Mac;
  }
}

class XdrCurve25519Secret {
  Uint8List _key;
  XdrCurve25519Secret();
  Uint8List get key => this._key;
  set key(Uint8List value) => this._key = value;

  static encode(
      XdrDataOutputStream stream, XdrCurve25519Secret encodedCurve25519Secret) {
    stream.write(encodedCurve25519Secret.key);
  }

  static XdrCurve25519Secret decode(XdrDataInputStream stream) {
    XdrCurve25519Secret decodedCurve25519Secret = XdrCurve25519Secret();
    int keysize = 32;
    decodedCurve25519Secret.key = stream.readBytes(keysize);
    return decodedCurve25519Secret;
  }
}

class XdrThresholds {
  Uint8List _thresholds;
  XdrThresholds();
  Uint8List get thresholds => this._thresholds;
  set thresholds(Uint8List value) => this._thresholds = value;

  static encode(XdrDataOutputStream stream, XdrThresholds encodedThresholds) {
    stream.write(encodedThresholds.thresholds);
  }

  static XdrThresholds decode(XdrDataInputStream stream) {
    XdrThresholds decodedThresholds = XdrThresholds();
    int thresholdssize = 4;
    decodedThresholds.thresholds = stream.readBytes(thresholdssize);
    return decodedThresholds;
  }
}

class XdrUpgradeType {
  Uint8List _upgradeType;
  XdrUpgradeType();
  Uint8List get upgradeType => this._upgradeType;
  set upgradeType(Uint8List value) => this._upgradeType = value;

  static encode(XdrDataOutputStream stream, XdrUpgradeType encodedUpgradeType) {
    int upgradeTypesize = encodedUpgradeType.upgradeType.length;
    stream.writeInt(upgradeTypesize);
    stream.write(encodedUpgradeType.upgradeType);
  }

  static XdrUpgradeType decode(XdrDataInputStream stream) {
    XdrUpgradeType decodedUpgradeType = XdrUpgradeType();
    int upgradeTypesize = stream.readInt();
    decodedUpgradeType.upgradeType = stream.readBytes(upgradeTypesize);
    return decodedUpgradeType;
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
  XdrPublicKey();
  XdrPublicKeyType _type;
  XdrPublicKeyType getDiscriminant() => this._type;
  void setDiscriminant(XdrPublicKeyType value) => this._type = value;

  XdrUint256 _ed25519;
  XdrUint256 getEd25519() => this._ed25519;
  void setEd25519(XdrUint256 value) => this._ed25519 = value;

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
    XdrPublicKey decodedPublicKey = XdrPublicKey();
    XdrPublicKeyType discriminant = XdrPublicKeyType.decode(stream);
    decodedPublicKey.setDiscriminant(discriminant);
    switch (decodedPublicKey.getDiscriminant()) {
      case XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519:
        decodedPublicKey._ed25519 = XdrUint256.decode(stream);
        break;
    }
    return decodedPublicKey;
  }
}

class XdrValue {
  Uint8List _value;
  XdrValue();
  Uint8List get value => this._value;
  set value(Uint8List value) => this._value = value;

  static encode(XdrDataOutputStream stream, XdrValue encodedValue) {
    int valuesize = encodedValue.value.length;
    stream.writeInt(valuesize);
    stream.write(encodedValue.value);
  }

  static XdrValue decode(XdrDataInputStream stream) {
    XdrValue decodedValue = XdrValue();
    int valuesize = stream.readInt();
    decodedValue.value = stream.readBytes(valuesize);
    return decodedValue;
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
