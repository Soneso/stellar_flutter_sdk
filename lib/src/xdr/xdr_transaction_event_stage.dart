// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrTransactionEventStage {
  final _value;
  const XdrTransactionEventStage._internal(this._value);
  toString() => 'TransactionEventStage.$_value';
  XdrTransactionEventStage(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrTransactionEventStage && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  // The event has happened before any one of the transactions has its operations applied.
  static const TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS =
      const XdrTransactionEventStage._internal(0);

  // The event has happened immediately after operations of the transaction have been applied.
  static const TRANSACTION_EVENT_STAGE_AFTER_TX =
      const XdrTransactionEventStage._internal(1);

  // The event has happened after every transaction had its operations applied.
  static const TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS =
      const XdrTransactionEventStage._internal(2);

  static XdrTransactionEventStage decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return TRANSACTION_EVENT_STAGE_BEFORE_ALL_TXS;
      case 1:
        return TRANSACTION_EVENT_STAGE_AFTER_TX;
      case 2:
        return TRANSACTION_EVENT_STAGE_AFTER_ALL_TXS;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrTransactionEventStage value) {
    stream.writeInt(value.value);
  }
}
