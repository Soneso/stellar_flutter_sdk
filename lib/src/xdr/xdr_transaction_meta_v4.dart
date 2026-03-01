// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_diagnostic_event.dart';
import 'xdr_extension_point.dart';
import 'xdr_ledger_entry_changes.dart';
import 'xdr_operation_meta_v2.dart';
import 'xdr_soroban_transaction_meta_v2.dart';
import 'xdr_transaction_event.dart';

class XdrTransactionMetaV4 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  // tx level changes before operations are applied if any
  XdrLedgerEntryChanges _txChangesBefore;
  XdrLedgerEntryChanges get txChangesBefore => this._txChangesBefore;
  set txChangesBefore(XdrLedgerEntryChanges value) =>
      this._txChangesBefore = value;

  // meta for each operation
  List<XdrOperationMetaV2> _operations;
  List<XdrOperationMetaV2> get operations => this._operations;
  set operations(List<XdrOperationMetaV2> value) => this._operations = value;

  // tx level changes after operations are applied if any
  XdrLedgerEntryChanges _txChangesAfter;
  XdrLedgerEntryChanges get txChangesAfter => this._txChangesAfter;
  set txChangesAfter(XdrLedgerEntryChanges value) =>
      this._txChangesAfter = value;

  // Soroban-specific meta (only for Soroban transactions).
  XdrSorobanTransactionMetaV2? _sorobanMeta;
  XdrSorobanTransactionMetaV2? get sorobanMeta => this._sorobanMeta;
  set sorobanMeta(XdrSorobanTransactionMetaV2? value) =>
      this._sorobanMeta = value;

  // Used for transaction-level events (like fee payment)
  List<XdrTransactionEvent> _events;
  List<XdrTransactionEvent> get events => this._events;
  set events(List<XdrTransactionEvent> value) => this._events = value;

  // Used for all diagnostic information
  List<XdrDiagnosticEvent> _diagnosticEvents;
  List<XdrDiagnosticEvent> get diagnosticEvents => this._diagnosticEvents;
  set diagnosticEvents(List<XdrDiagnosticEvent> value) =>
      this._diagnosticEvents = value;

  XdrTransactionMetaV4(
      this._ext,
      this._txChangesBefore,
      this._operations,
      this._txChangesAfter,
      this._sorobanMeta,
      this._events,
      this._diagnosticEvents);

  static void encode(XdrDataOutputStream stream, XdrTransactionMetaV4 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrLedgerEntryChanges.encode(stream, encoded.txChangesBefore);
    int operationsSize = encoded.operations.length;
    stream.writeInt(operationsSize);
    for (int i = 0; i < operationsSize; i++) {
      XdrOperationMetaV2.encode(stream, encoded.operations[i]);
    }

    XdrLedgerEntryChanges.encode(stream, encoded.txChangesAfter);

    if (encoded.sorobanMeta != null) {
      stream.writeInt(1);
      XdrSorobanTransactionMetaV2.encode(stream, encoded.sorobanMeta!);
    } else {
      stream.writeInt(0);
    }

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrTransactionEvent.encode(stream, encoded.events[i]);
    }

    int diagnosticEventsSize = encoded.diagnosticEvents.length;
    stream.writeInt(diagnosticEventsSize);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      XdrDiagnosticEvent.encode(stream, encoded.diagnosticEvents[i]);
    }
  }

  static XdrTransactionMetaV4 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrLedgerEntryChanges txChangesBefore =
        XdrLedgerEntryChanges.decode(stream);

    int operationsSize = stream.readInt();
    List<XdrOperationMetaV2> operations =
        List<XdrOperationMetaV2>.empty(growable: true);
    for (int i = 0; i < operationsSize; i++) {
      operations.add(XdrOperationMetaV2.decode(stream));
    }
    XdrLedgerEntryChanges txChangesAfter = XdrLedgerEntryChanges.decode(stream);

    XdrSorobanTransactionMetaV2? sorobanMeta;
    int present = stream.readInt();
    if (present != 0) {
      sorobanMeta = XdrSorobanTransactionMetaV2.decode(stream);
    }

    int eventsSize = stream.readInt();
    List<XdrTransactionEvent> events =
        List<XdrTransactionEvent>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrTransactionEvent.decode(stream));
    }

    int diagnosticEventsSize = stream.readInt();
    List<XdrDiagnosticEvent> diagnosticEvents =
        List<XdrDiagnosticEvent>.empty(growable: true);
    for (int i = 0; i < diagnosticEventsSize; i++) {
      diagnosticEvents.add(XdrDiagnosticEvent.decode(stream));
    }

    return XdrTransactionMetaV4(ext, txChangesBefore, operations,
        txChangesAfter, sorobanMeta, events, diagnosticEvents);
  }
}
