// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrExtendFootprintTTLResultCode {
  final _value;
  const XdrExtendFootprintTTLResultCode._internal(this._value);
  toString() => 'ExtendFootprintTTLResultCode.$_value';
  XdrExtendFootprintTTLResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrExtendFootprintTTLResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success
  static const EXTEND_FOOTPRINT_TTL_SUCCESS =
      const XdrExtendFootprintTTLResultCode._internal(0);

  // codes considered as "failure" for the operation
  static const EXTEND_FOOTPRINT_TTL_MALFORMED =
      const XdrExtendFootprintTTLResultCode._internal(-1);
  static const EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED =
      const XdrExtendFootprintTTLResultCode._internal(-2);
  static const EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE =
      const XdrExtendFootprintTTLResultCode._internal(-3);

  static XdrExtendFootprintTTLResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return EXTEND_FOOTPRINT_TTL_SUCCESS;
      case -1:
        return EXTEND_FOOTPRINT_TTL_MALFORMED;
      case -2:
        return EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED;
      case -3:
        return EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrExtendFootprintTTLResultCode value) {
    stream.writeInt(value.value);
  }
}
