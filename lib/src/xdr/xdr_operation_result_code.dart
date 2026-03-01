// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrOperationResultCode {
  final _value;
  const XdrOperationResultCode._internal(this._value);
  toString() => 'OperationResultCode.$_value';
  XdrOperationResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrOperationResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Inner object result is valid.
  static const opINNER = const XdrOperationResultCode._internal(0);

  /// Too few valid signatures / wrong network.
  static const opBAD_AUTH = const XdrOperationResultCode._internal(-1);

  /// Source account was not found.
  static const opNO_ACCOUNT = const XdrOperationResultCode._internal(-2);

  /// Operation not supported at this time.
  static const opNOT_SUPPORTED = const XdrOperationResultCode._internal(-3);

  /// Max number of subentries already reached.
  static const opTOO_MANY_SUBENTRIES = const XdrOperationResultCode._internal(
    -4,
  );

  /// Operation did too much work.
  static const opEXCEEDED_WORK_LIMIT = const XdrOperationResultCode._internal(
    -5,
  );

  static XdrOperationResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return opINNER;
      case -1:
        return opBAD_AUTH;
      case -2:
        return opNO_ACCOUNT;
      case -3:
        return opNOT_SUPPORTED;
      case -4:
        return opTOO_MANY_SUBENTRIES;
      case -5:
        return opEXCEEDED_WORK_LIMIT;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrOperationResultCode value) {
    stream.writeInt(value.value);
  }
}
