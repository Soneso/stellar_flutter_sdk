// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_contract_event.dart';
import 'xdr_data_io.dart';
import 'xdr_transaction_event_stage.dart';

class XdrTransactionEvent {
  // Stage at which an event has occurred.
  XdrTransactionEventStage _stage;
  XdrTransactionEventStage get stage => this._stage;
  set ext(XdrTransactionEventStage value) => this._stage = value;

  // The contract event that has occurred.
  XdrContractEvent _event;
  XdrContractEvent get event => this._event;
  set event(XdrContractEvent value) => this._event = value;

  XdrTransactionEvent(this._stage, this._event);

  static void encode(XdrDataOutputStream stream, XdrTransactionEvent encoded) {
    XdrTransactionEventStage.encode(stream, encoded.stage);
    XdrContractEvent.encode(stream, encoded.event);
  }

  static XdrTransactionEvent decode(XdrDataInputStream stream) {
    final stage = XdrTransactionEventStage.decode(stream);
    final event = XdrContractEvent.decode(stream);

    return XdrTransactionEvent(stage, event);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionEvent.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrTransactionEvent fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrTransactionEvent.decode(XdrDataInputStream(bytes));
  }
}
