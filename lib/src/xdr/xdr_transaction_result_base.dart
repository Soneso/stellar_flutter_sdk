// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_transaction_result_ext.dart';
import 'xdr_transaction_result_result.dart';

class XdrTransactionResultBase {
  XdrTransactionResultBase(this._feeCharged, this._result, this._ext);
  XdrInt64 _feeCharged;
  XdrInt64 get feeCharged => this._feeCharged;
  set feeCharged(XdrInt64 value) => this._feeCharged = value;

  XdrTransactionResultResult _result;
  XdrTransactionResultResult get result => this._result;
  set result(XdrTransactionResultResult value) => this._result = value;

  XdrTransactionResultExt _ext;
  XdrTransactionResultExt get ext => this._ext;
  set ext(XdrTransactionResultExt value) => this._ext = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrTransactionResultBase encodedTransactionResult,
  ) {
    XdrInt64.encode(stream, encodedTransactionResult._feeCharged);
    XdrTransactionResultResult.encode(stream, encodedTransactionResult._result);
    XdrTransactionResultExt.encode(stream, encodedTransactionResult._ext);
  }

  static XdrTransactionResultBase decode(XdrDataInputStream stream) {
    XdrInt64 feeCharged = XdrInt64.decode(stream);
    XdrTransactionResultResult result = XdrTransactionResultResult.decode(
      stream,
    );
    XdrTransactionResultExt ext = XdrTransactionResultExt.decode(stream);
    return XdrTransactionResultBase(feeCharged, result, ext);
  }
}
