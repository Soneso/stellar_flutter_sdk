// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_transaction_result_pair.dart';

class XdrTransactionResultSet {
  XdrTransactionResultSet(this._results);
  List<XdrTransactionResultPair> _results;
  List<XdrTransactionResultPair> get results => this._results;
  set results(List<XdrTransactionResultPair> value) => this._results = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionResultSet encodedTransactionResultSet,
  ) {
    int resultsSize = encodedTransactionResultSet.results.length;
    stream.writeInt(resultsSize);
    for (int i = 0; i < resultsSize; i++) {
      XdrTransactionResultPair.encode(
        stream,
        encodedTransactionResultSet._results[i],
      );
    }
  }

  static XdrTransactionResultSet decode(XdrDataInputStream stream) {
    int resultsSize = stream.readInt();
    List<XdrTransactionResultPair> results =
        List<XdrTransactionResultPair>.empty(growable: true);
    for (int i = 0; i < resultsSize; i++) {
      results.add(XdrTransactionResultPair.decode(stream));
    }
    return XdrTransactionResultSet(results);
  }
}
