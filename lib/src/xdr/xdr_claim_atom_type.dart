// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrClaimAtomType {
  final _value;
  const XdrClaimAtomType._internal(this._value);
  toString() => 'ClaimAtomType.$_value';
  XdrClaimAtomType(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrClaimAtomType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const CLAIM_ATOM_TYPE_V0 = const XdrClaimAtomType._internal(0);
  static const CLAIM_ATOM_TYPE_ORDER_BOOK = const XdrClaimAtomType._internal(1);
  static const CLAIM_ATOM_TYPE_LIQUIDITY_POOL =
      const XdrClaimAtomType._internal(2);

  static XdrClaimAtomType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAIM_ATOM_TYPE_V0;
      case 1:
        return CLAIM_ATOM_TYPE_ORDER_BOOK;
      case 2:
        return CLAIM_ATOM_TYPE_LIQUIDITY_POOL;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrClaimAtomType value) {
    stream.writeInt(value.value);
  }
}
