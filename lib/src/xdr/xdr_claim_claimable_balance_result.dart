// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claim_claimable_balance_result_code.dart';
import 'xdr_data_io.dart';

class XdrClaimClaimableBalanceResult {
  XdrClaimClaimableBalanceResultCode _code;

  XdrClaimClaimableBalanceResultCode get discriminant => this._code;

  set discriminant(XdrClaimClaimableBalanceResultCode value) => this._code = value;

  XdrClaimClaimableBalanceResult(this._code);

  static void encode(XdrDataOutputStream stream, XdrClaimClaimableBalanceResult encodedClaimClaimableBalanceResult) {
    stream.writeInt(encodedClaimClaimableBalanceResult.discriminant.value);
    switch (encodedClaimClaimableBalanceResult.discriminant) {
      case XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrClaimClaimableBalanceResult decode(XdrDataInputStream stream) {
    XdrClaimClaimableBalanceResult decodedClaimClaimableBalanceResult = XdrClaimClaimableBalanceResult(XdrClaimClaimableBalanceResultCode.decode(stream));
    switch (decodedClaimClaimableBalanceResult.discriminant) {
      case XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
    return decodedClaimClaimableBalanceResult;
  }
}
