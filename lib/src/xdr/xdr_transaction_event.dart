// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_transaction_event_base.dart';

class XdrTransactionEvent extends XdrTransactionEventBase {
  XdrTransactionEvent(super.stage, super.event);

  static void encode(XdrDataOutputStream stream, XdrTransactionEvent val) {
    XdrTransactionEventBase.encode(stream, val);
  }

  static XdrTransactionEvent decode(XdrDataInputStream stream) {
    var b = XdrTransactionEventBase.decode(stream);
    return XdrTransactionEvent(b.stage, b.event);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionEvent.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrTransactionEvent fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrTransactionEvent.decode(XdrDataInputStream(bytes));
  }
}
