// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_manage_offer_result_code.dart';
import 'xdr_manage_offer_success_result.dart';

class XdrManageOfferResult {
  XdrManageOfferResultCode _code;
  XdrManageOfferResultCode get discriminant => this._code;
  set discriminant(XdrManageOfferResultCode value) => this._code = value;

  XdrManageOfferSuccessResult? _success;
  XdrManageOfferSuccessResult? get success => this._success;
  set success(XdrManageOfferSuccessResult? value) => this._success = value;

  XdrManageOfferResult(this._code, this._success);

  static void encode(
    XdrDataOutputStream stream,
    XdrManageOfferResult encodedManageOfferResult,
  ) {
    stream.writeInt(encodedManageOfferResult.discriminant.value);
    switch (encodedManageOfferResult.discriminant) {
      case XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS:
        XdrManageOfferSuccessResult.encode(
          stream,
          encodedManageOfferResult.success!,
        );
        break;
      default:
        break;
    }
  }

  static XdrManageOfferResult decode(XdrDataInputStream stream) {
    XdrManageOfferResult decodedManageOfferResult = XdrManageOfferResult(
      XdrManageOfferResultCode.decode(stream),
      null,
    );
    switch (decodedManageOfferResult.discriminant) {
      case XdrManageOfferResultCode.MANAGE_SELL_OFFER_SUCCESS:
        decodedManageOfferResult.success = XdrManageOfferSuccessResult.decode(
          stream,
        );
        break;
      default:
        break;
    }
    return decodedManageOfferResult;
  }
}
