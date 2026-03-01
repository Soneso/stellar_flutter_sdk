// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_ledger_footprint_base.dart';

class XdrLedgerFootprint extends XdrLedgerFootprintBase {
  XdrLedgerFootprint(super.readOnly, super.readWrite);

  static void encode(XdrDataOutputStream stream, XdrLedgerFootprint val) {
    XdrLedgerFootprintBase.encode(stream, val);
  }

  static XdrLedgerFootprint decode(XdrDataInputStream stream) {
    var b = XdrLedgerFootprintBase.decode(stream);
    return XdrLedgerFootprint(b.readOnly, b.readWrite);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerFootprint.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerFootprint fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerFootprint.decode(XdrDataInputStream(bytes));
  }
}
