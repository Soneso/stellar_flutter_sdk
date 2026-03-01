// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_path_payment_result_success.dart';
import 'xdr_path_payment_strict_send_result_code.dart';

class XdrPathPaymentStrictSendResult {
  XdrPathPaymentStrictSendResult(this._code);
  XdrPathPaymentStrictSendResultCode _code;
  XdrPathPaymentStrictSendResultCode get discriminant => this._code;
  set discriminant(XdrPathPaymentStrictSendResultCode value) =>
      this._code = value;

  XdrPathPaymentResultSuccess? _success;
  XdrPathPaymentResultSuccess? get success => this._success;
  set success(XdrPathPaymentResultSuccess? value) => this._success = value;

  XdrAsset? _noIssuer;
  XdrAsset? get noIssuer => this._noIssuer;
  set noIssuer(XdrAsset? value) => this._noIssuer = value;

  static void encode(XdrDataOutputStream stream,
      XdrPathPaymentStrictSendResult encodedPathPaymentResult) {
    stream.writeInt(encodedPathPaymentResult.discriminant.value);
    switch (encodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SUCCESS:
        XdrPathPaymentResultSuccess.encode(
            stream, encodedPathPaymentResult.success!);
        break;
      case XdrPathPaymentStrictSendResultCode
          .PATH_PAYMENT_STRICT_SEND_NO_ISSUER:
        XdrAsset.encode(stream, encodedPathPaymentResult.noIssuer!);
        break;
      default:
        break;
    }
  }

  static XdrPathPaymentStrictSendResult decode(XdrDataInputStream stream) {
    XdrPathPaymentStrictSendResult decodedPathPaymentResult =
        XdrPathPaymentStrictSendResult(
            XdrPathPaymentStrictSendResultCode.decode(stream));
    switch (decodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictSendResultCode.PATH_PAYMENT_STRICT_SEND_SUCCESS:
        decodedPathPaymentResult.success =
            XdrPathPaymentResultSuccess.decode(stream);
        break;
      case XdrPathPaymentStrictSendResultCode
          .PATH_PAYMENT_STRICT_SEND_NO_ISSUER:
        decodedPathPaymentResult.noIssuer = XdrAsset.decode(stream);
        break;
      default:
        break;
    }
    return decodedPathPaymentResult;
  }
}
