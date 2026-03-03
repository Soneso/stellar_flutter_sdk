// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_inner_transaction_result_pair.dart';
import 'xdr_operation_result.dart';
import 'xdr_transaction_result_code.dart';

class XdrTransactionResultResult {
  XdrTransactionResultCode _code;

  XdrTransactionResultCode get discriminant => this._code;

  set discriminant(XdrTransactionResultCode value) => this._code = value;

  XdrInnerTransactionResultPair? _innerResultPair;

  XdrInnerTransactionResultPair? get innerResultPair => this._innerResultPair;

  List<XdrOperationResult>? _results;

  List<XdrOperationResult>? get results => this._results;

  XdrTransactionResultResult(this._code);

  set innerResultPair(XdrInnerTransactionResultPair? value) =>
      this._innerResultPair = value;

  set results(List<XdrOperationResult>? value) => this._results = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionResultResult encodedTransactionResultResult,
  ) {
    stream.writeInt(encodedTransactionResultResult.discriminant.value);
    switch (encodedTransactionResultResult.discriminant) {
      case XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS:
      case XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED:
        XdrInnerTransactionResultPair.encode(
          stream,
          encodedTransactionResultResult._innerResultPair!,
        );
        break;
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultssize = encodedTransactionResultResult._results!.length;
        stream.writeInt(resultssize);
        for (int i = 0; i < resultssize; i++) {
          XdrOperationResult.encode(
            stream,
            encodedTransactionResultResult._results![i],
          );
        }
        break;
      default:
        break;
    }
  }

  static XdrTransactionResultResult decode(XdrDataInputStream stream) {
    XdrTransactionResultResult decodedTransactionResultResult =
        XdrTransactionResultResult(XdrTransactionResultCode.decode(stream));
    switch (decodedTransactionResultResult.discriminant) {
      case XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS:
      case XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED:
        decodedTransactionResultResult._innerResultPair =
            XdrInnerTransactionResultPair.decode(stream);
        break;
      case XdrTransactionResultCode.txSUCCESS:
      case XdrTransactionResultCode.txFAILED:
        int resultssize = stream.readInt();
        decodedTransactionResultResult._results =
            List<XdrOperationResult>.empty(growable: true);
        for (int i = 0; i < resultssize; i++) {
          decodedTransactionResultResult._results!.add(
            XdrOperationResult.decode(stream),
          );
        }
        break;
      default:
        break;
    }
    return decodedTransactionResultResult;
  }
}
