// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrCreateAccountResultCode {
  final _value;

  const XdrCreateAccountResultCode._internal(this._value);

  toString() => 'CreateAccountResultCode.$_value';

  XdrCreateAccountResultCode(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrCreateAccountResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Account was created.
  static const CREATE_ACCOUNT_SUCCESS =
      const XdrCreateAccountResultCode._internal(0);

  /// Invalid destination.
  static const CREATE_ACCOUNT_MALFORMED =
      const XdrCreateAccountResultCode._internal(-1);

  /// Not enough funds in source account.
  static const CREATE_ACCOUNT_UNDERFUNDED =
      const XdrCreateAccountResultCode._internal(-2);

  /// Would create an account below the min reserve.
  static const CREATE_ACCOUNT_LOW_RESERVE =
      const XdrCreateAccountResultCode._internal(-3);

  /// Account already exists.
  static const CREATE_ACCOUNT_ALREADY_EXIST =
      const XdrCreateAccountResultCode._internal(-4);

  static XdrCreateAccountResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CREATE_ACCOUNT_SUCCESS;
      case -1:
        return CREATE_ACCOUNT_MALFORMED;
      case -2:
        return CREATE_ACCOUNT_UNDERFUNDED;
      case -3:
        return CREATE_ACCOUNT_LOW_RESERVE;
      case -4:
        return CREATE_ACCOUNT_ALREADY_EXIST;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrCreateAccountResultCode value) {
    stream.writeInt(value.value);
  }
}
