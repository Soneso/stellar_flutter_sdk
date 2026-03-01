// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_end_sponsoring_future_reserves_result_code.dart';

class XdrEndSponsoringFutureReservesResult {
  XdrEndSponsoringFutureReservesResultCode _code;

  XdrEndSponsoringFutureReservesResultCode get discriminant => this._code;

  set discriminant(XdrEndSponsoringFutureReservesResultCode value) =>
      this._code = value;

  XdrEndSponsoringFutureReservesResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrEndSponsoringFutureReservesResult encoded,
  ) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrEndSponsoringFutureReservesResultCode
          .END_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrEndSponsoringFutureReservesResult decode(
    XdrDataInputStream stream,
  ) {
    XdrEndSponsoringFutureReservesResult decoded =
        XdrEndSponsoringFutureReservesResult(
          XdrEndSponsoringFutureReservesResultCode.decode(stream),
        );
    switch (decoded.discriminant) {
      case XdrEndSponsoringFutureReservesResultCode
          .END_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}
