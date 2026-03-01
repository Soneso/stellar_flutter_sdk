// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_event.dart';
import 'xdr_data_io.dart';
import 'xdr_transaction_event_stage.dart';

class XdrTransactionEventBase {
  // Stage at which an event has occurred.
  XdrTransactionEventStage _stage;
  XdrTransactionEventStage get stage => this._stage;
  set ext(XdrTransactionEventStage value) => this._stage = value;

  // The contract event that has occurred.
  XdrContractEvent _event;
  XdrContractEvent get event => this._event;
  set event(XdrContractEvent value) => this._event = value;

  XdrTransactionEventBase(this._stage, this._event);

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionEventBase encoded,
  ) {
    XdrTransactionEventStage.encode(stream, encoded.stage);
    XdrContractEvent.encode(stream, encoded.event);
  }

  static XdrTransactionEventBase decode(XdrDataInputStream stream) {
    final stage = XdrTransactionEventStage.decode(stream);
    final event = XdrContractEvent.decode(stream);

    return XdrTransactionEventBase(stage, event);
  }
}
