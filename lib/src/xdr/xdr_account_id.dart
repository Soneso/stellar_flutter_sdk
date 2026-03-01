// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_public_key.dart';

class XdrAccountID {
  XdrPublicKey _accountID;

  XdrPublicKey get accountID => this._accountID;

  set accountID(XdrPublicKey value) => this._accountID = value;

  XdrAccountID(this._accountID);

  static void encode(
      XdrDataOutputStream stream, XdrAccountID? encodedAccountID) {
    XdrPublicKey.encode(stream, encodedAccountID!.accountID);
  }

  static XdrAccountID decode(XdrDataInputStream stream) {
    return XdrAccountID(XdrPublicKey.decode(stream));
  }

  static XdrAccountID forAccountId(String accountId) {
    return XdrAccountID(XdrPublicKey.forAccountId(accountId));
  }
}
