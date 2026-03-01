// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrAssetType {
  final _value;
  const XdrAssetType._internal(this._value);
  toString() => 'AssetType.$_value';
  XdrAssetType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrAssetType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const ASSET_TYPE_NATIVE = const XdrAssetType._internal(0);
  static const ASSET_TYPE_CREDIT_ALPHANUM4 = const XdrAssetType._internal(1);
  static const ASSET_TYPE_CREDIT_ALPHANUM12 = const XdrAssetType._internal(2);
  static const ASSET_TYPE_POOL_SHARE = const XdrAssetType._internal(3);

  static XdrAssetType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ASSET_TYPE_NATIVE;
      case 1:
        return ASSET_TYPE_CREDIT_ALPHANUM4;
      case 2:
        return ASSET_TYPE_CREDIT_ALPHANUM12;
      case 3:
        return ASSET_TYPE_POOL_SHARE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAssetType value) {
    stream.writeInt(value.value);
  }
}
