// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_event.dart';
import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_ledger_entry_changes.dart';

class XdrOperationMetaV2 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrLedgerEntryChanges _changes;
  XdrLedgerEntryChanges get changes => this._changes;
  set changes(XdrLedgerEntryChanges value) => this._changes = value;

  List<XdrContractEvent> _events;
  List<XdrContractEvent> get events => this._events;
  set events(List<XdrContractEvent> value) => this._events = value;

  XdrOperationMetaV2(this._ext, this._changes, this._events);

  static void encode(XdrDataOutputStream stream, XdrOperationMetaV2 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrLedgerEntryChanges.encode(stream, encoded.changes);

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrContractEvent.encode(stream, encoded.events[i]);
    }
  }

  static XdrOperationMetaV2 decode(XdrDataInputStream stream) {
    final ext = XdrExtensionPoint.decode(stream);
    final changes = XdrLedgerEntryChanges.decode(stream);
    int eventsSize = stream.readInt();
    List<XdrContractEvent> events =
        List<XdrContractEvent>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrContractEvent.decode(stream));
    }
    return XdrOperationMetaV2(ext, changes, events);
  }
}
