// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSetOptionsResultCode {
  final _value;

  const XdrSetOptionsResultCode._internal(this._value);

  toString() => 'SetOptionsResultCode.$_value';

  XdrSetOptionsResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrSetOptionsResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success.
  static const SET_OPTIONS_SUCCESS = const XdrSetOptionsResultCode._internal(0);

  /// Not enough funds to add a signer.
  static const SET_OPTIONS_LOW_RESERVE =
      const XdrSetOptionsResultCode._internal(-1);

  /// Max number of signers already reached.
  static const SET_OPTIONS_TOO_MANY_SIGNERS =
      const XdrSetOptionsResultCode._internal(-2);

  /// Invalid combination of clear/set flags.
  static const SET_OPTIONS_BAD_FLAGS =
      const XdrSetOptionsResultCode._internal(-3);

  /// Inflation account does not exist.
  static const SET_OPTIONS_INVALID_INFLATION =
      const XdrSetOptionsResultCode._internal(-4);

  /// Can no longer change this option.
  static const SET_OPTIONS_CANT_CHANGE =
      const XdrSetOptionsResultCode._internal(-5);

  /// Can't set an unknown flag.
  static const SET_OPTIONS_UNKNOWN_FLAG =
      const XdrSetOptionsResultCode._internal(-6);

  /// Bad value for weight/threshold.
  static const SET_OPTIONS_THRESHOLD_OUT_OF_RANGE =
      const XdrSetOptionsResultCode._internal(-7);

  /// Signer cannot be masterkey.
  static const SET_OPTIONS_BAD_SIGNER =
      const XdrSetOptionsResultCode._internal(-8);

  /// Malformed home domain.
  static const SET_OPTIONS_INVALID_HOME_DOMAIN =
      const XdrSetOptionsResultCode._internal(-9);

  static XdrSetOptionsResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SET_OPTIONS_SUCCESS;
      case -1:
        return SET_OPTIONS_LOW_RESERVE;
      case -2:
        return SET_OPTIONS_TOO_MANY_SIGNERS;
      case -3:
        return SET_OPTIONS_BAD_FLAGS;
      case -4:
        return SET_OPTIONS_INVALID_INFLATION;
      case -5:
        return SET_OPTIONS_CANT_CHANGE;
      case -6:
        return SET_OPTIONS_UNKNOWN_FLAG;
      case -7:
        return SET_OPTIONS_THRESHOLD_OUT_OF_RANGE;
      case -8:
        return SET_OPTIONS_BAD_SIGNER;
      case -9:
        return SET_OPTIONS_INVALID_HOME_DOMAIN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSetOptionsResultCode value) {
    stream.writeInt(value.value);
  }
}
