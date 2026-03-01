// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_inflation_payout.dart';
import 'xdr_inflation_result_code.dart';

class XdrInflationResult {
  XdrInflationResultCode _code;

  XdrInflationResultCode get discriminant => this._code;

  set discriminant(XdrInflationResultCode value) => this._code = value;

  List<XdrInflationPayout>? _payouts;

  List<XdrInflationPayout>? get payouts => this._payouts;

  set payouts(List<XdrInflationPayout>? value) => this._payouts = value;

  XdrInflationResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrInflationResult encodedInflationResult) {
    stream.writeInt(encodedInflationResult.discriminant.value);
    switch (encodedInflationResult.discriminant) {
      case XdrInflationResultCode.INFLATION_SUCCESS:
        int payoutssize = encodedInflationResult.payouts!.length;
        stream.writeInt(payoutssize);
        for (int i = 0; i < payoutssize; i++) {
          XdrInflationPayout.encode(stream, encodedInflationResult.payouts![i]);
        }
        break;
      default:
        break;
    }
  }

  static XdrInflationResult decode(XdrDataInputStream stream) {
    XdrInflationResult decodedInflationResult =
        XdrInflationResult(XdrInflationResultCode.decode(stream));
    switch (decodedInflationResult.discriminant) {
      case XdrInflationResultCode.INFLATION_SUCCESS:
        int payoutssize = stream.readInt();
        List<XdrInflationPayout> payouts =
            List<XdrInflationPayout>.empty(growable: true);
        for (int i = 0; i < payoutssize; i++) {
          payouts.add(XdrInflationPayout.decode(stream));
        }
        decodedInflationResult.payouts = payouts;
        break;
      default:
        break;
    }
    return decodedInflationResult;
  }
}
