// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_ledger_entry_data_base.dart';

class XdrLedgerEntryData extends XdrLedgerEntryDataBase {
  XdrLedgerEntryData(super.type);

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryData val) {
    XdrLedgerEntryDataBase.encode(stream, val);
  }

  static XdrLedgerEntryData decode(XdrDataInputStream stream) {
    return XdrLedgerEntryDataBase.decodeAs(stream, XdrLedgerEntryData.new);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerEntryData.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerEntryData fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerEntryData.decode(XdrDataInputStream(bytes));
  }
}
