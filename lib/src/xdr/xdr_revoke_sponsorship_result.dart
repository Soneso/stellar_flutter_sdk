// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_revoke_sponsorship_result_code.dart';

class XdrRevokeSponsorshipResult {
  XdrRevokeSponsorshipResultCode _code;

  XdrRevokeSponsorshipResultCode get discriminant => this._code;

  set discriminant(XdrRevokeSponsorshipResultCode value) => this._code = value;

  XdrRevokeSponsorshipResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrRevokeSponsorshipResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrRevokeSponsorshipResult decode(XdrDataInputStream stream) {
    XdrRevokeSponsorshipResult decoded = XdrRevokeSponsorshipResult(
        XdrRevokeSponsorshipResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}
