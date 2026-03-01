// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_transaction_result_base.dart';

class XdrTransactionResult extends XdrTransactionResultBase {
  XdrTransactionResult(super.feeCharged, super.result, super.ext);

  static void encode(XdrDataOutputStream stream, XdrTransactionResult val) {
    XdrTransactionResultBase.encode(stream, val);
  }

  static XdrTransactionResult decode(XdrDataInputStream stream) {
    var b = XdrTransactionResultBase.decode(stream);
    return XdrTransactionResult(b.feeCharged, b.result, b.ext);
  }

  static XdrTransactionResult fromBase64EncodedXdrString(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return XdrTransactionResult.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrTransactionResult.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }
}
