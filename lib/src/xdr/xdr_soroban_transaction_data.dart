// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_soroban_transaction_data_base.dart';

class XdrSorobanTransactionData extends XdrSorobanTransactionDataBase {
  XdrSorobanTransactionData(super.ext, super.resources, super.resourceFee);

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanTransactionData val,
  ) {
    XdrSorobanTransactionDataBase.encode(stream, val);
  }

  static XdrSorobanTransactionData decode(XdrDataInputStream stream) {
    var b = XdrSorobanTransactionDataBase.decode(stream);
    return XdrSorobanTransactionData(b.ext, b.resources, b.resourceFee);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrSorobanTransactionData.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrSorobanTransactionData fromBase64EncodedXdrString(
    String base64Encoded,
  ) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrSorobanTransactionData.decode(XdrDataInputStream(bytes));
  }
}
