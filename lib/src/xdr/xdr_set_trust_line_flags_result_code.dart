// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSetTrustLineFlagsResultCode {
  final _value;

  const XdrSetTrustLineFlagsResultCode._internal(this._value);

  toString() => 'XdrSetTrustLineFlagsResultCode.$_value';

  XdrSetTrustLineFlagsResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrSetTrustLineFlagsResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const SET_TRUST_LINE_FLAGS_SUCCESS =
      const XdrSetTrustLineFlagsResultCode._internal(0);

  static const SET_TRUST_LINE_FLAGS_MALFORMED =
      const XdrSetTrustLineFlagsResultCode._internal(-1);

  static const SET_TRUST_LINE_FLAGS_NO_TRUST_LINE =
      const XdrSetTrustLineFlagsResultCode._internal(-2);

  static const SET_TRUST_LINE_FLAGS_CANT_REVOKE =
      const XdrSetTrustLineFlagsResultCode._internal(-3);

  static const SET_TRUST_LINE_FLAGS_INVALID_STATE =
      const XdrSetTrustLineFlagsResultCode._internal(-4);

  static const SET_TRUST_LINE_FLAGS_LOW_RESERVE =
      const XdrSetTrustLineFlagsResultCode._internal(-5);

  static XdrSetTrustLineFlagsResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SET_TRUST_LINE_FLAGS_SUCCESS;
      case -1:
        return SET_TRUST_LINE_FLAGS_MALFORMED;
      case -2:
        return SET_TRUST_LINE_FLAGS_NO_TRUST_LINE;
      case -3:
        return SET_TRUST_LINE_FLAGS_CANT_REVOKE;
      case -4:
        return SET_TRUST_LINE_FLAGS_INVALID_STATE;
      case -5:
        return SET_TRUST_LINE_FLAGS_LOW_RESERVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrSetTrustLineFlagsResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
