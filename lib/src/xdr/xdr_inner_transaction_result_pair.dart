// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_inner_transaction_result.dart';

class XdrInnerTransactionResultPair {
  XdrInnerTransactionResultPair(this._transactionHash, this._result);
  XdrHash _transactionHash;
  XdrHash get transactionHash => this._transactionHash;
  set transactionHash(XdrHash value) => this._transactionHash = value;

  XdrInnerTransactionResult _result;
  XdrInnerTransactionResult get result => this._result;
  set result(XdrInnerTransactionResult value) => this._result = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrInnerTransactionResultPair encoded,
  ) {
    XdrHash.encode(stream, encoded._transactionHash);
    XdrInnerTransactionResult.encode(stream, encoded._result);
  }

  static XdrInnerTransactionResultPair decode(XdrDataInputStream stream) {
    XdrHash transactionHash = XdrHash.decode(stream);
    XdrInnerTransactionResult result = XdrInnerTransactionResult.decode(stream);
    return XdrInnerTransactionResultPair(transactionHash, result);
  }
}
