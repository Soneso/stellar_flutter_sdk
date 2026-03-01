// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_changes_base.dart';

class XdrLedgerEntryChanges extends XdrLedgerEntryChangesBase {
  XdrLedgerEntryChanges(super.ledgerEntryChanges);

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryChanges val) {
    XdrLedgerEntryChangesBase.encode(stream, val);
  }

  static XdrLedgerEntryChanges decode(XdrDataInputStream stream) {
    var b = XdrLedgerEntryChangesBase.decode(stream);
    return XdrLedgerEntryChanges(b.ledgerEntryChanges);
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
