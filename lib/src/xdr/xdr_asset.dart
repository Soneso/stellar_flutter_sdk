// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import "dart:typed_data";
import 'xdr_account.dart';
import 'xdr_data_io.dart';

class XdrAssetType {
  final _value;
  const XdrAssetType._internal(this._value);
  toString() => 'AssetType.$_value';
  XdrAssetType(this._value);
  get value => this._value;

  static const ASSET_TYPE_NATIVE = const XdrAssetType._internal(0);
  static const ASSET_TYPE_CREDIT_ALPHANUM4 = const XdrAssetType._internal(1);
  static const ASSET_TYPE_CREDIT_ALPHANUM12 = const XdrAssetType._internal(2);

  static XdrAssetType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ASSET_TYPE_NATIVE;
      case 1:
        return ASSET_TYPE_CREDIT_ALPHANUM4;
      case 2:
        return ASSET_TYPE_CREDIT_ALPHANUM12;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAssetType value) {
    stream.writeInt(value.value);
  }
}

class XdrAsset {
  XdrAsset();
  XdrAssetType _type;
  XdrAssetType get discriminant => this._type;
  set discriminant(XdrAssetType value) => this._type = value;

  XdrAssetAlphaNum4 _alphaNum4;
  XdrAssetAlphaNum4 get alphaNum4 => this._alphaNum4;
  set alphaNum4(XdrAssetAlphaNum4 value) => this._alphaNum4 = value;

  XdrAssetAlphaNum12 _alphaNum12;
  XdrAssetAlphaNum12 get alphaNum12 => this._alphaNum12;
  set alphaNum12(XdrAssetAlphaNum12 value) => this._alphaNum12 = value;

  static void encode(XdrDataOutputStream stream, XdrAsset encodedAsset) {
    stream.writeInt(encodedAsset.discriminant.value);
    switch (encodedAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        XdrAssetAlphaNum4.encode(stream, encodedAsset.alphaNum4);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        XdrAssetAlphaNum12.encode(stream, encodedAsset.alphaNum12);
        break;
    }
  }

  static XdrAsset decode(XdrDataInputStream stream) {
    XdrAsset decodedAsset = XdrAsset();
    XdrAssetType discriminant = XdrAssetType.decode(stream);
    decodedAsset.discriminant = discriminant;
    switch (decodedAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        decodedAsset.alphaNum4 = XdrAssetAlphaNum4.decode(stream);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        decodedAsset.alphaNum12 = XdrAssetAlphaNum12.decode(stream);
        break;
    }
    return decodedAsset;
  }
}

class XdrAssetAlphaNum4 {
  XdrAssetAlphaNum4();
  Uint8List _assetCode;
  Uint8List get assetCode => this._assetCode;
  set assetCode(Uint8List value) => this._assetCode = value;

  XdrAccountID _issuer;
  XdrAccountID get issuer => this._issuer;
  set issuer(XdrAccountID value) => this._issuer = value;

  static void encode(
      XdrDataOutputStream stream, XdrAssetAlphaNum4 encodedAssetAlphaNum4) {
    stream.write(encodedAssetAlphaNum4.assetCode);
    XdrAccountID.encode(stream, encodedAssetAlphaNum4.issuer);
  }

  static XdrAssetAlphaNum4 decode(XdrDataInputStream stream) {
    XdrAssetAlphaNum4 decodedAssetAlphaNum4 = XdrAssetAlphaNum4();
    int assetCodesize = 4;
    decodedAssetAlphaNum4.assetCode = stream.readBytes(assetCodesize);
    decodedAssetAlphaNum4.issuer = XdrAccountID.decode(stream);
    return decodedAssetAlphaNum4;
  }
}

class XdrAssetAlphaNum12 {
  XdrAssetAlphaNum12();
  Uint8List _assetCode;
  Uint8List get assetCode => this._assetCode;
  set assetCode(Uint8List value) => this._assetCode = value;

  XdrAccountID _issuer;
  XdrAccountID get issuer => this._issuer;
  set issuer(XdrAccountID value) => this._issuer = value;

  static void encode(
      XdrDataOutputStream stream, XdrAssetAlphaNum12 encodedAssetAlphaNum12) {
    stream.write(encodedAssetAlphaNum12.assetCode);
    XdrAccountID.encode(stream, encodedAssetAlphaNum12.issuer);
  }

  static XdrAssetAlphaNum12 decode(XdrDataInputStream stream) {
    XdrAssetAlphaNum12 decodedAssetAlphaNum12 = XdrAssetAlphaNum12();
    int assetCodesize = 12;
    decodedAssetAlphaNum12.assetCode = stream.readBytes(assetCodesize);
    decodedAssetAlphaNum12.issuer = XdrAccountID.decode(stream);
    return decodedAssetAlphaNum12;
  }
}
