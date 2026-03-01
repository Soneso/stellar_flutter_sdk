// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_transaction_meta_base.dart';

class XdrTransactionMeta extends XdrTransactionMetaBase {
  XdrTransactionMeta(super.v);

  static void encode(XdrDataOutputStream stream, XdrTransactionMeta val) {
    XdrTransactionMetaBase.encode(stream, val);
  }

  static XdrTransactionMeta decode(XdrDataInputStream stream) {
    return XdrTransactionMetaBase.decodeAs(stream, XdrTransactionMeta.new);
  }

  static XdrTransactionMeta fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrTransactionMeta.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionMeta.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
}
