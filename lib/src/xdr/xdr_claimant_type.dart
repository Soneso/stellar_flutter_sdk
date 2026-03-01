// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrClaimantType {
  final _value;

  const XdrClaimantType._internal(this._value);

  toString() => 'ClaimantType.$_value';

  XdrClaimantType(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrClaimantType && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const CLAIMANT_TYPE_V0 = const XdrClaimantType._internal(0);

  static XdrClaimantType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAIMANT_TYPE_V0;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrClaimantType value) {
    stream.writeInt(value.value);
  }
}
