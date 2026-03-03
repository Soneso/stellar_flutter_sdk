// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_change.dart';

class XdrLedgerEntryChangesBase {
  XdrLedgerEntryChangesBase(this._ledgerEntryChanges);

  List<XdrLedgerEntryChange> _ledgerEntryChanges;
  List<XdrLedgerEntryChange> get ledgerEntryChanges => this._ledgerEntryChanges;
  set ledgerEntryChanges(List<XdrLedgerEntryChange> value) => this._ledgerEntryChanges = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryChangesBase encodedLedgerEntryChanges) {
    int size = encodedLedgerEntryChanges.ledgerEntryChanges.length;
    stream.writeInt(size);
    for (int i = 0; i < size; i++) {
      XdrLedgerEntryChange.encode(stream, encodedLedgerEntryChanges.ledgerEntryChanges[i]);
    }
  }

  static XdrLedgerEntryChangesBase decode(XdrDataInputStream stream) {
    int size = stream.readInt();
    List<XdrLedgerEntryChange> items = List<XdrLedgerEntryChange>.empty(growable: true);
    for (int i = 0; i < size; i++) {
      items.add(XdrLedgerEntryChange.decode(stream));
    }
    return XdrLedgerEntryChangesBase(items);
  }
}
