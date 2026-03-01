// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';
import 'xdr_muxed_account.dart';

class XdrPathPaymentStrictSendOp {
  XdrPathPaymentStrictSendOp(this._sendAsset, this._sendMax, this._destination,
      this._destAsset, this._destAmount, this._path);
  XdrAsset _sendAsset;
  XdrAsset get sendAsset => this._sendAsset;
  set sendAsset(XdrAsset value) => this._sendAsset = value;

  XdrBigInt64 _sendMax;
  XdrBigInt64 get sendMax => this._sendMax;
  set sendMax(XdrBigInt64 value) => this._sendMax = value;

  XdrMuxedAccount _destination;
  XdrMuxedAccount get destination => this._destination;
  set destination(XdrMuxedAccount value) => this._destination = value;

  XdrAsset _destAsset;
  XdrAsset get destAsset => this._destAsset;
  set destAsset(XdrAsset value) => this._destAsset = value;

  XdrBigInt64 _destAmount;
  XdrBigInt64 get destAmount => this._destAmount;
  set destAmount(XdrBigInt64 value) => this._destAmount = value;

  List<XdrAsset> _path;
  List<XdrAsset> get path => this._path;
  set path(List<XdrAsset> value) => this._path = value;

  static void encode(XdrDataOutputStream stream,
      XdrPathPaymentStrictSendOp encodedPathPaymentOp) {
    XdrAsset.encode(stream, encodedPathPaymentOp.sendAsset);
    XdrBigInt64.encode(stream, encodedPathPaymentOp.sendMax);
    XdrMuxedAccount.encode(stream, encodedPathPaymentOp.destination);
    XdrAsset.encode(stream, encodedPathPaymentOp.destAsset);
    XdrBigInt64.encode(stream, encodedPathPaymentOp.destAmount);
    int pathSize = encodedPathPaymentOp.path.length;
    stream.writeInt(pathSize);
    for (int i = 0; i < pathSize; i++) {
      XdrAsset.encode(stream, encodedPathPaymentOp.path[i]);
    }
  }

  static XdrPathPaymentStrictSendOp decode(XdrDataInputStream stream) {
    XdrAsset sendAsset = XdrAsset.decode(stream);
    XdrBigInt64 sendMax = XdrBigInt64.decode(stream);
    XdrMuxedAccount destination = XdrMuxedAccount.decode(stream);
    XdrAsset destAsset = XdrAsset.decode(stream);
    XdrBigInt64 destAmount = XdrBigInt64.decode(stream);

    int pathsize = stream.readInt();
    List<XdrAsset> path = List<XdrAsset>.empty(growable: true);
    for (int i = 0; i < pathsize; i++) {
      path.add(XdrAsset.decode(stream));
    }

    return XdrPathPaymentStrictSendOp(
        sendAsset, sendMax, destination, destAsset, destAmount, path);
  }
}
