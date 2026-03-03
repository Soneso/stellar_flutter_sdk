// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_clawback_claimable_balance_result_code.dart';
import 'xdr_data_io.dart';

class XdrClawbackClaimableBalanceResult {
  XdrClawbackClaimableBalanceResultCode _code;

  XdrClawbackClaimableBalanceResultCode get discriminant => this._code;

  set discriminant(XdrClawbackClaimableBalanceResultCode value) =>
      this._code = value;

  XdrClawbackClaimableBalanceResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrClawbackClaimableBalanceResult encodedClawbackClaimableBalanceResult,
  ) {
    stream.writeInt(encodedClawbackClaimableBalanceResult.discriminant.value);
    switch (encodedClawbackClaimableBalanceResult.discriminant) {
      case XdrClawbackClaimableBalanceResultCode
          .CLAWBACK_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrClawbackClaimableBalanceResult decode(XdrDataInputStream stream) {
    XdrClawbackClaimableBalanceResult decodedClawbackClaimableBalanceResult =
        XdrClawbackClaimableBalanceResult(
          XdrClawbackClaimableBalanceResultCode.decode(stream),
        );
    switch (decodedClawbackClaimableBalanceResult.discriminant) {
      case XdrClawbackClaimableBalanceResultCode
          .CLAWBACK_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
    return decodedClawbackClaimableBalanceResult;
  }
}
