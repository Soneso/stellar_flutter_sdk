// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_fee_bump_transaction_ext.dart';
import 'xdr_fee_bump_transaction_inner_tx.dart';
import 'xdr_int64.dart';
import 'xdr_muxed_account.dart';

class XdrFeeBumpTransaction {
  XdrFeeBumpTransaction(this._feeSource, this._fee, this._innerTx, this._ext);
  XdrMuxedAccount _feeSource;
  XdrMuxedAccount get feeSource => this._feeSource;
  set feeSource(XdrMuxedAccount value) => this._feeSource = value;

  XdrInt64 _fee;
  XdrInt64 get fee => this._fee;
  set fee(XdrInt64 value) => this._fee = value;

  XdrFeeBumpTransactionInnerTx _innerTx;
  XdrFeeBumpTransactionInnerTx get innerTx => this._innerTx;
  set innerTx(XdrFeeBumpTransactionInnerTx value) => this._innerTx = value;

  XdrFeeBumpTransactionExt _ext;
  XdrFeeBumpTransactionExt get ext => this._ext;
  set ext(XdrFeeBumpTransactionExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrFeeBumpTransaction encodedTransaction) {
    XdrMuxedAccount.encode(stream, encodedTransaction._feeSource);
    XdrInt64.encode(stream, encodedTransaction._fee);
    XdrFeeBumpTransactionInnerTx.encode(stream, encodedTransaction._innerTx);
    XdrFeeBumpTransactionExt.encode(stream, encodedTransaction._ext);
  }

  static XdrFeeBumpTransaction decode(XdrDataInputStream stream) {
    XdrMuxedAccount feeSource = XdrMuxedAccount.decode(stream);
    XdrInt64 fee = XdrInt64.decode(stream);
    XdrFeeBumpTransactionInnerTx innerTx =
        XdrFeeBumpTransactionInnerTx.decode(stream);
    XdrFeeBumpTransactionExt ext = XdrFeeBumpTransactionExt.decode(stream);

    return XdrFeeBumpTransaction(feeSource, fee, innerTx, ext);
  }
}
