// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_payment_result_code.dart';

class XdrPaymentResult {
  XdrPaymentResultCode _code;

  XdrPaymentResultCode get discriminant => this._code;

  set discriminant(XdrPaymentResultCode value) => this._code = value;

  XdrPaymentResult(this._code);

  static void encode(XdrDataOutputStream stream, XdrPaymentResult encodedPaymentResult) {
    stream.writeInt(encodedPaymentResult.discriminant.value);
    switch (encodedPaymentResult.discriminant) {
      case XdrPaymentResultCode.PAYMENT_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrPaymentResult decode(XdrDataInputStream stream) {
    XdrPaymentResult decodedPaymentResult = XdrPaymentResult(XdrPaymentResultCode.decode(stream));
    switch (decodedPaymentResult.discriminant) {
      case XdrPaymentResultCode.PAYMENT_SUCCESS:
        break;
      default:
        break;
    }
    return decodedPaymentResult;
  }
}
