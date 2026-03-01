// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_change.dart';

class XdrLedgerEntryChanges {
  XdrLedgerEntryChanges(this._ledgerEntryChanges);

  List<XdrLedgerEntryChange> _ledgerEntryChanges;

  List<XdrLedgerEntryChange> get ledgerEntryChanges => this._ledgerEntryChanges;

  set ledgerEntryChanges(List<XdrLedgerEntryChange> value) =>
      this._ledgerEntryChanges = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerEntryChanges encodedLedgerEntryChanges) {
    int ledgerEntryChangesSize =
        encodedLedgerEntryChanges.ledgerEntryChanges.length;
    stream.writeInt(ledgerEntryChangesSize);
    for (int i = 0; i < ledgerEntryChangesSize; i++) {
      XdrLedgerEntryChange.encode(
          stream, encodedLedgerEntryChanges.ledgerEntryChanges[i]);
    }
  }

  static XdrLedgerEntryChanges decode(XdrDataInputStream stream) {
    int ledgerEntryChangesSize = stream.readInt();
    List<XdrLedgerEntryChange> ledgerEntryChanges =
        List<XdrLedgerEntryChange>.empty(growable: true);
    for (int i = 0; i < ledgerEntryChangesSize; i++) {
      ledgerEntryChanges.add(XdrLedgerEntryChange.decode(stream));
    }
    return XdrLedgerEntryChanges(ledgerEntryChanges);
  }

  static XdrLedgerEntryChanges fromBase64EncodedXdrString(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return XdrLedgerEntryChanges.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerEntryChanges.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
}
