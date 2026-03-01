// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_asset.dart';
import 'xdr_data_io.dart';
import 'xdr_path_payment_result_success.dart';
import 'xdr_path_payment_strict_receive_result_code.dart';

class XdrPathPaymentStrictReceiveResult {
  XdrPathPaymentStrictReceiveResult(this._code);
  XdrPathPaymentStrictReceiveResultCode _code;
  XdrPathPaymentStrictReceiveResultCode get discriminant => this._code;
  set discriminant(XdrPathPaymentStrictReceiveResultCode value) =>
      this._code = value;

  XdrPathPaymentResultSuccess? _success;
  XdrPathPaymentResultSuccess? get success => this._success;
  set success(XdrPathPaymentResultSuccess? value) => this._success = value;

  XdrAsset? _noIssuer;
  XdrAsset? get noIssuer => this._noIssuer;
  set noIssuer(XdrAsset? value) => this._noIssuer = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrPathPaymentStrictReceiveResult encodedPathPaymentResult,
  ) {
    stream.writeInt(encodedPathPaymentResult.discriminant.value);
    switch (encodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_SUCCESS:
        XdrPathPaymentResultSuccess.encode(
          stream,
          encodedPathPaymentResult.success!,
        );
        break;
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER:
        XdrAsset.encode(stream, encodedPathPaymentResult.noIssuer!);
        break;
      default:
        break;
    }
  }

  static XdrPathPaymentStrictReceiveResult decode(XdrDataInputStream stream) {
    XdrPathPaymentStrictReceiveResult decodedPathPaymentResult =
        XdrPathPaymentStrictReceiveResult(
          XdrPathPaymentStrictReceiveResultCode.decode(stream),
        );
    switch (decodedPathPaymentResult.discriminant) {
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_SUCCESS:
        decodedPathPaymentResult.success = XdrPathPaymentResultSuccess.decode(
          stream,
        );
        break;
      case XdrPathPaymentStrictReceiveResultCode
          .PATH_PAYMENT_STRICT_RECEIVE_NO_ISSUER:
        decodedPathPaymentResult.noIssuer = XdrAsset.decode(stream);
        break;
      default:
        break;
    }
    return decodedPathPaymentResult;
  }
}
