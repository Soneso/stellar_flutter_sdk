// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_public_key.dart';

class XdrAccountIDBase {
  XdrAccountIDBase(this._accountID);

  XdrPublicKey _accountID;
  XdrPublicKey get accountID => this._accountID;
  set accountID(XdrPublicKey value) => this._accountID = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrAccountIDBase encodedAccountID,
  ) {
    XdrPublicKey.encode(stream, encodedAccountID.accountID);
  }

  static XdrAccountIDBase decode(XdrDataInputStream stream) {
    return XdrAccountIDBase(XdrPublicKey.decode(stream));
  }
}
