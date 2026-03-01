// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_clawback_result_code.dart';
import 'xdr_data_io.dart';

class XdrClawbackResult {
  XdrClawbackResult(this._code);

  XdrClawbackResultCode _code;
  XdrClawbackResultCode get discriminant => this._code;
  set discriminant(XdrClawbackResultCode value) => this._code = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrClawbackResult encodedClawbackResult,
  ) {
    stream.writeInt(encodedClawbackResult.discriminant.value);
    switch (encodedClawbackResult.discriminant) {
      case XdrClawbackResultCode.CLAWBACK_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrClawbackResult decode(XdrDataInputStream stream) {
    XdrClawbackResult decodedClawbackResult = XdrClawbackResult(
      XdrClawbackResultCode.decode(stream),
    );
    switch (decodedClawbackResult.discriminant) {
      case XdrClawbackResultCode.CLAWBACK_SUCCESS:
        break;
      default:
        break;
    }
    return decodedClawbackResult;
  }
}
