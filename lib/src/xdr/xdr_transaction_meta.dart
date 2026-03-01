// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_operation_meta.dart';
import 'xdr_transaction_meta_v1.dart';
import 'xdr_transaction_meta_v2.dart';
import 'xdr_transaction_meta_v3.dart';
import 'xdr_transaction_meta_v4.dart';

class XdrTransactionMeta {
  XdrTransactionMeta(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  List<XdrOperationMeta>? _operations;
  List<XdrOperationMeta>? get operations => this._operations;
  set operations(List<XdrOperationMeta>? value) => this._operations = value;

  XdrTransactionMetaV1? _v1;
  XdrTransactionMetaV1? get v1 => this._v1;
  set v1(XdrTransactionMetaV1? value) => this._v1 = value;

  XdrTransactionMetaV2? _v2;
  XdrTransactionMetaV2? get v2 => this._v2;
  set v2(XdrTransactionMetaV2? value) => this._v2 = value;

  XdrTransactionMetaV3? _v3;
  XdrTransactionMetaV3? get v3 => this._v3;
  set v3(XdrTransactionMetaV3? value) => this._v3 = value;

  XdrTransactionMetaV4? _v4;
  XdrTransactionMetaV4? get v4 => this._v4;
  set v4(XdrTransactionMetaV4? value) => this._v4 = value;

  static void encode(
      XdrDataOutputStream stream, XdrTransactionMeta encodedTransactionMeta) {
    stream.writeInt(encodedTransactionMeta.discriminant);
    switch (encodedTransactionMeta.discriminant) {
      case 0:
        int operationsSize = encodedTransactionMeta.operations!.length;
        stream.writeInt(operationsSize);
        for (int i = 0; i < operationsSize; i++) {
          XdrOperationMeta.encode(
              stream, encodedTransactionMeta._operations![i]);
        }
        break;
      case 1:
        XdrTransactionMetaV1.encode(stream, encodedTransactionMeta._v1!);
        break;
      case 2:
        XdrTransactionMetaV2.encode(stream, encodedTransactionMeta._v2!);
        break;
      case 3:
        XdrTransactionMetaV3.encode(stream, encodedTransactionMeta._v3!);
        break;
      case 4:
        XdrTransactionMetaV4.encode(stream, encodedTransactionMeta._v4!);
        break;
    }
  }

  static XdrTransactionMeta decode(XdrDataInputStream stream) {
    XdrTransactionMeta decodedTransactionMeta =
        XdrTransactionMeta(stream.readInt());
    switch (decodedTransactionMeta.discriminant) {
      case 0:
        int operationsSize = stream.readInt();
        List<XdrOperationMeta> operations =
            List<XdrOperationMeta>.empty(growable: true);
        for (int i = 0; i < operationsSize; i++) {
          operations.add(XdrOperationMeta.decode(stream));
        }
        decodedTransactionMeta._operations = operations;
        break;
      case 1:
        decodedTransactionMeta._v1 = XdrTransactionMetaV1.decode(stream);
        break;
      case 2:
        decodedTransactionMeta._v2 = XdrTransactionMetaV2.decode(stream);
        break;
      case 3:
        decodedTransactionMeta._v3 = XdrTransactionMetaV3.decode(stream);
        break;
      case 4:
        decodedTransactionMeta._v4 = XdrTransactionMetaV4.decode(stream);
        break;
    }
    return decodedTransactionMeta;
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
