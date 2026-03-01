// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_changes.dart';

class XdrOperationMeta {
  XdrOperationMeta(this._changes);
  XdrLedgerEntryChanges _changes;
  XdrLedgerEntryChanges get changes => this._changes;
  set changes(XdrLedgerEntryChanges value) => this._changes = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperationMeta encodedOperationMeta) {
    XdrLedgerEntryChanges.encode(stream, encodedOperationMeta.changes);
  }

  static XdrOperationMeta decode(XdrDataInputStream stream) {
    return XdrOperationMeta(XdrLedgerEntryChanges.decode(stream));
  }
}
