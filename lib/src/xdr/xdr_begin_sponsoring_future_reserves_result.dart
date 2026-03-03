// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_begin_sponsoring_future_reserves_result_code.dart';
import 'xdr_data_io.dart';

class XdrBeginSponsoringFutureReservesResult {
  XdrBeginSponsoringFutureReservesResultCode _code;

  XdrBeginSponsoringFutureReservesResultCode get discriminant => this._code;

  set discriminant(XdrBeginSponsoringFutureReservesResultCode value) =>
      this._code = value;

  XdrBeginSponsoringFutureReservesResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrBeginSponsoringFutureReservesResult
    encodedBeginSponsoringFutureReservesResult,
  ) {
    stream.writeInt(
      encodedBeginSponsoringFutureReservesResult.discriminant.value,
    );
    switch (encodedBeginSponsoringFutureReservesResult.discriminant) {
      case XdrBeginSponsoringFutureReservesResultCode
          .BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrBeginSponsoringFutureReservesResult decode(
    XdrDataInputStream stream,
  ) {
    XdrBeginSponsoringFutureReservesResult
    decodedBeginSponsoringFutureReservesResult =
        XdrBeginSponsoringFutureReservesResult(
          XdrBeginSponsoringFutureReservesResultCode.decode(stream),
        );
    switch (decodedBeginSponsoringFutureReservesResult.discriminant) {
      case XdrBeginSponsoringFutureReservesResultCode
          .BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
    return decodedBeginSponsoringFutureReservesResult;
  }
}
