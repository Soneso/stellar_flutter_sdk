// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_int64.dart';

class XdrInflationPayout {

  XdrAccountID _destination;
  XdrAccountID get destination => this._destination;
  set destination(XdrAccountID value) => this._destination = value;

  XdrInt64 _amount;
  XdrInt64 get amount => this._amount;
  set amount(XdrInt64 value) => this._amount = value;

  XdrInflationPayout(this._destination, this._amount);

  static void encode(XdrDataOutputStream stream, XdrInflationPayout encodedInflationPayout) {
    XdrAccountID.encode(stream, encodedInflationPayout.destination);
    XdrInt64.encode(stream, encodedInflationPayout.amount);
  }

  static XdrInflationPayout decode(XdrDataInputStream stream) {
    XdrAccountID destination = XdrAccountID.decode(stream);
    XdrInt64 amount = XdrInt64.decode(stream);
    return XdrInflationPayout(destination, amount);
  }
}
