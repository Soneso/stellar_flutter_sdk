// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_id_base.dart';
import 'xdr_data_io.dart';
import 'xdr_public_key.dart';

class XdrAccountID extends XdrAccountIDBase {
  XdrAccountID(super.accountID);

  static void encode(XdrDataOutputStream stream, XdrAccountID? val) {
    XdrAccountIDBase.encode(stream, val!);
  }

  static XdrAccountID decode(XdrDataInputStream stream) {
    var b = XdrAccountIDBase.decode(stream);
    return XdrAccountID(b.accountID);
  }

  static XdrAccountID forAccountId(String accountId) {
    return XdrAccountID(XdrPublicKey.forAccountId(accountId));
  }
}
