// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrContractIDPreimageType {
  final _value;
  const XdrContractIDPreimageType._internal(this._value);
  toString() => 'ContractIDPreimageType.$_value';
  XdrContractIDPreimageType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrContractIDPreimageType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const CONTRACT_ID_PREIMAGE_FROM_ADDRESS =
      const XdrContractIDPreimageType._internal(0);
  static const CONTRACT_ID_PREIMAGE_FROM_ASSET =
      const XdrContractIDPreimageType._internal(1);

  static XdrContractIDPreimageType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONTRACT_ID_PREIMAGE_FROM_ADDRESS;
      case 1:
        return CONTRACT_ID_PREIMAGE_FROM_ASSET;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrContractIDPreimageType value,
  ) {
    stream.writeInt(value.value);
  }
}
