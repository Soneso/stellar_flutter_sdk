// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_muxed_account.dart';

class XdrSimplePaymentResult {
  XdrSimplePaymentResult(this._destination, this._asset, this._amount);
  XdrMuxedAccount _destination;
  XdrMuxedAccount get destination => this._destination;
  set destination(XdrMuxedAccount value) => this._destination = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrInt64 _amount;
  XdrInt64 get amount => this._amount;
  set amount(XdrInt64 value) => this._amount = value;

  static void encode(XdrDataOutputStream stream,
      XdrSimplePaymentResult encodedSimplePaymentResult) {
    XdrMuxedAccount.encode(stream, encodedSimplePaymentResult.destination);
    XdrAsset.encode(stream, encodedSimplePaymentResult.asset);
    XdrInt64.encode(stream, encodedSimplePaymentResult.amount);
  }

  static XdrSimplePaymentResult decode(XdrDataInputStream stream) {
    XdrMuxedAccount destination = XdrMuxedAccount.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    XdrInt64 amount = XdrInt64.decode(stream);
    return XdrSimplePaymentResult(destination, asset, amount);
  }
}
