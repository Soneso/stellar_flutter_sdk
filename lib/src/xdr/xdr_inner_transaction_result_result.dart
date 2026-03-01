// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_operation_result.dart';
import 'xdr_transaction_result_code.dart';

class XdrInnerTransactionResultResult {
  XdrInnerTransactionResultResult(this._code, this._results);

  XdrTransactionResultCode _code;

  XdrTransactionResultCode get discriminant => this._code;

  set discriminant(XdrTransactionResultCode value) => this._code = value;

  List<XdrOperationResult>? _results;

  get results => this._results;

  set results(value) => this._results = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrInnerTransactionResultResult encoded,
  ) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultsSize = encoded.results.length;
        stream.writeInt(resultsSize);
        for (int i = 0; i < resultsSize; i++) {
          XdrOperationResult.encode(stream, encoded._results![i]);
        }
        break;
      default:
        break;
    }
  }

  static XdrInnerTransactionResultResult decode(XdrDataInputStream stream) {
    List<XdrOperationResult>? results;
    XdrTransactionResultCode discriminant = XdrTransactionResultCode.decode(
      stream,
    );
    switch (discriminant) {
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultsSize = stream.readInt();
        results = List<XdrOperationResult>.empty(growable: true);
        for (int i = 0; i < resultsSize; i++) {
          results.add(XdrOperationResult.decode(stream));
        }
        break;
      default:
        break;
    }
    return XdrInnerTransactionResultResult(discriminant, results);
  }
}
