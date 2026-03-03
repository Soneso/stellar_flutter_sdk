// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_big_int64.dart';
import 'xdr_data_io.dart';

class XdrCreateAccountOp {

  XdrAccountID _destination;
  XdrAccountID get destination => this._destination;
  set destination(XdrAccountID value) => this._destination = value;

  XdrBigInt64 _startingBalance;
  XdrBigInt64 get startingBalance => this._startingBalance;
  set startingBalance(XdrBigInt64 value) => this._startingBalance = value;

  XdrCreateAccountOp(this._destination, this._startingBalance);

  static void encode(XdrDataOutputStream stream, XdrCreateAccountOp encodedCreateAccountOp) {
    XdrAccountID.encode(stream, encodedCreateAccountOp.destination);
    XdrBigInt64.encode(stream, encodedCreateAccountOp.startingBalance);
  }

  static XdrCreateAccountOp decode(XdrDataInputStream stream) {
    XdrAccountID destination = XdrAccountID.decode(stream);
    XdrBigInt64 startingBalance = XdrBigInt64.decode(stream);
    return XdrCreateAccountOp(destination, startingBalance);
  }
}
