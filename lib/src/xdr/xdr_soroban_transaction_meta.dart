// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_event.dart';
import 'xdr_data_io.dart';
import 'xdr_diagnostic_event.dart';
import 'xdr_sc_val.dart';
import 'xdr_soroban_transaction_meta_ext.dart';

class XdrSorobanTransactionMeta {
  XdrSorobanTransactionMetaExt _ext;
  XdrSorobanTransactionMetaExt get ext => this._ext;
  set ext(XdrSorobanTransactionMetaExt value) => this._ext = value;

  List<XdrContractEvent> _events;
  List<XdrContractEvent> get events => this._events;
  set events(List<XdrContractEvent> value) => this._events = value;

  XdrSCVal _returnValue;
  XdrSCVal get returnValue => this._returnValue;
  set returnValue(XdrSCVal value) => this._returnValue = value;

  List<XdrDiagnosticEvent> _diagnosticEvents;
  List<XdrDiagnosticEvent> get diagnosticEvents => this._diagnosticEvents;
  set diagnosticEvents(List<XdrDiagnosticEvent> value) =>
      this._diagnosticEvents = value;

  XdrSorobanTransactionMeta(
    this._ext,
    this._events,
    this._returnValue,
    this._diagnosticEvents,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanTransactionMeta encoded,
  ) {
    XdrSorobanTransactionMetaExt.encode(stream, encoded.ext);

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrContractEvent.encode(stream, encoded._events[i]);
    }

    XdrSCVal.encode(stream, encoded.returnValue);

    int diagnosticEventsSize = encoded.diagnosticEvents.length;
    stream.writeInt(diagnosticEventsSize);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      XdrDiagnosticEvent.encode(stream, encoded.diagnosticEvents[i]);
    }
  }

  static XdrSorobanTransactionMeta decode(XdrDataInputStream stream) {
    XdrSorobanTransactionMetaExt ext = XdrSorobanTransactionMetaExt.decode(
      stream,
    );

    int eventsSize = stream.readInt();
    List<XdrContractEvent> events = List<XdrContractEvent>.empty(
      growable: true,
    );
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrContractEvent.decode(stream));
    }

    XdrSCVal returnValue = XdrSCVal.decode(stream);

    int diagnosticEventsSize = stream.readInt();
    List<XdrDiagnosticEvent> diagnosticEvents = List<XdrDiagnosticEvent>.empty(
      growable: true,
    );
    for (int i = 0; i < diagnosticEventsSize; i++) {
      diagnosticEvents.add(XdrDiagnosticEvent.decode(stream));
    }

    return XdrSorobanTransactionMeta(
      ext,
      events,
      returnValue,
      diagnosticEvents,
    );
  }
}
