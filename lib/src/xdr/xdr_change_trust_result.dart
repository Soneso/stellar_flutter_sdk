// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_change_trust_result_code.dart';
import 'xdr_data_io.dart';

class XdrChangeTrustResult {
  XdrChangeTrustResult(this._code);

  XdrChangeTrustResultCode _code;
  XdrChangeTrustResultCode get discriminant => this._code;
  set discriminant(XdrChangeTrustResultCode value) => this._code = value;

  static void encode(XdrDataOutputStream stream,
      XdrChangeTrustResult encodedChangeTrustResult) {
    stream.writeInt(encodedChangeTrustResult.discriminant.value);
    switch (encodedChangeTrustResult.discriminant) {
      case XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrChangeTrustResult decode(XdrDataInputStream stream) {
    XdrChangeTrustResult decodedChangeTrustResult =
        XdrChangeTrustResult(XdrChangeTrustResultCode.decode(stream));
    switch (decodedChangeTrustResult.discriminant) {
      case XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS:
        break;
      default:
        break;
    }
    return decodedChangeTrustResult;
  }
}
