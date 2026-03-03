// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTransactionResultCode {
  final _value;
  const XdrTransactionResultCode._internal(this._value);
  toString() => 'TransactionResultCode.$_value';
  XdrTransactionResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrTransactionResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const txFEE_BUMP_INNER_SUCCESS =
      const XdrTransactionResultCode._internal(1);
  static const txSUCCESS = const XdrTransactionResultCode._internal(0);
  static const txFAILED = const XdrTransactionResultCode._internal(-1);
  static const txTOO_EARLY = const XdrTransactionResultCode._internal(-2);
  static const txTOO_LATE = const XdrTransactionResultCode._internal(-3);
  static const txMISSING_OPERATION = const XdrTransactionResultCode._internal(
    -4,
  );
  static const txBAD_SEQ = const XdrTransactionResultCode._internal(-5);
  static const txBAD_AUTH = const XdrTransactionResultCode._internal(-6);
  static const txINSUFFICIENT_BALANCE =
      const XdrTransactionResultCode._internal(-7);
  static const txNO_ACCOUNT = const XdrTransactionResultCode._internal(-8);
  static const txINSUFFICIENT_FEE = const XdrTransactionResultCode._internal(
    -9,
  );
  static const txBAD_AUTH_EXTRA = const XdrTransactionResultCode._internal(-10);
  static const txINTERNAL_ERROR = const XdrTransactionResultCode._internal(-11);
  static const txNOT_SUPPORTED = const XdrTransactionResultCode._internal(-12);
  static const txFEE_BUMP_INNER_FAILED =
      const XdrTransactionResultCode._internal(-13);
  static const txBAD_SPONSORSHIP = const XdrTransactionResultCode._internal(
    -14,
  );
  static const txBAD_MIN_SEQ_AGE_OR_GAP =
      const XdrTransactionResultCode._internal(-15);
  static const txMALFORMED = const XdrTransactionResultCode._internal(-16);
  static const txSOROBAN_INVALID = const XdrTransactionResultCode._internal(
    -17,
  );

  static XdrTransactionResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return txFEE_BUMP_INNER_SUCCESS;
      case 0:
        return txSUCCESS;
      case -1:
        return txFAILED;
      case -2:
        return txTOO_EARLY;
      case -3:
        return txTOO_LATE;
      case -4:
        return txMISSING_OPERATION;
      case -5:
        return txBAD_SEQ;
      case -6:
        return txBAD_AUTH;
      case -7:
        return txINSUFFICIENT_BALANCE;
      case -8:
        return txNO_ACCOUNT;
      case -9:
        return txINSUFFICIENT_FEE;
      case -10:
        return txBAD_AUTH_EXTRA;
      case -11:
        return txINTERNAL_ERROR;
      case -12:
        return txNOT_SUPPORTED;
      case -13:
        return txFEE_BUMP_INNER_FAILED;
      case -14:
        return txBAD_SPONSORSHIP;
      case -15:
        return txBAD_MIN_SEQ_AGE_OR_GAP;
      case -16:
        return txMALFORMED;
      case -17:
        return txSOROBAN_INVALID;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
