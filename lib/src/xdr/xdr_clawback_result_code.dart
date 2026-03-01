// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrClawbackResultCode {
  final _value;

  const XdrClawbackResultCode._internal(this._value);

  toString() => 'ClawbackResultCode.$_value';

  XdrClawbackResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrClawbackResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Clawback successfully completed.
  static const CLAWBACK_SUCCESS = const XdrClawbackResultCode._internal(0);

  /// Bad input.
  static const CLAWBACK_MALFORMED = const XdrClawbackResultCode._internal(-1);

  static const CLAWBACK_NOT_ENABLED = const XdrClawbackResultCode._internal(-2);

  static const CLAWBACK_NO_TRUST = const XdrClawbackResultCode._internal(-3);

  /// Not enough funds in source account.
  static const CLAWBACK_UNDERFUNDED = const XdrClawbackResultCode._internal(-4);

  static XdrClawbackResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAWBACK_SUCCESS;
      case -1:
        return CLAWBACK_MALFORMED;
      case -2:
        return CLAWBACK_NOT_ENABLED;
      case -3:
        return CLAWBACK_NO_TRUST;
      case -4:
        return CLAWBACK_UNDERFUNDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrClawbackResultCode value) {
    stream.writeInt(value.value);
  }
}
