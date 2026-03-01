// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_inner_transaction_result_result.dart';
import 'xdr_int64.dart';
import 'xdr_transaction_result_ext.dart';

class XdrInnerTransactionResult {
  XdrInnerTransactionResult(this._feeCharged, this._result, this._ext);
  XdrInt64 _feeCharged;
  XdrInt64 get feeCharged => this._feeCharged;
  set feeCharged(XdrInt64 value) => this._feeCharged = value;

  XdrInnerTransactionResultResult _result;
  XdrInnerTransactionResultResult get result => this._result;
  set result(XdrInnerTransactionResultResult value) => this._result = value;

  XdrTransactionResultExt _ext;
  XdrTransactionResultExt get ext => this._ext;
  set ext(XdrTransactionResultExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrInnerTransactionResult encoded) {
    XdrInt64.encode(stream, encoded._feeCharged);
    XdrInnerTransactionResultResult.encode(stream, encoded._result);
    XdrTransactionResultExt.encode(stream, encoded._ext);
  }

  static XdrInnerTransactionResult decode(XdrDataInputStream stream) {
    XdrInt64 feeCharged = XdrInt64.decode(stream);
    XdrInnerTransactionResultResult result =
        XdrInnerTransactionResultResult.decode(stream);
    XdrTransactionResultExt ext = XdrTransactionResultExt.decode(stream);
    return XdrInnerTransactionResult(feeCharged, result, ext);
  }
}
