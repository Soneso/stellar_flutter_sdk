// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id.dart';
import 'xdr_data_io.dart';

class XdrBeginSponsoringFutureReservesOp {
  XdrAccountID _sponsoredID;
  XdrAccountID get sponsoredID => this._sponsoredID;
  set sponsoredID(XdrAccountID value) => this._sponsoredID = value;

  XdrBeginSponsoringFutureReservesOp(this._sponsoredID);

  static void encode(
    XdrDataOutputStream stream,
    XdrBeginSponsoringFutureReservesOp encodedBeginSponsoringFutureReservesOp,
  ) {
    XdrAccountID.encode(
      stream,
      encodedBeginSponsoringFutureReservesOp.sponsoredID,
    );
  }

  static XdrBeginSponsoringFutureReservesOp decode(XdrDataInputStream stream) {
    XdrAccountID sponsoredID = XdrAccountID.decode(stream);
    return XdrBeginSponsoringFutureReservesOp(sponsoredID);
  }
}
