// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_base.dart';

class XdrLedgerEntry extends XdrLedgerEntryBase {
  XdrLedgerEntry(super.lastModifiedLedgerSeq, super.data, super.ext);

  static void encode(XdrDataOutputStream stream, XdrLedgerEntry val) {
    XdrLedgerEntryBase.encode(stream, val);
  }

  static XdrLedgerEntry decode(XdrDataInputStream stream) {
    var b = XdrLedgerEntryBase.decode(stream);
    return XdrLedgerEntry(b.lastModifiedLedgerSeq, b.data, b.ext);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerEntry.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerEntry fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerEntry.decode(XdrDataInputStream(bytes));
  }
}
