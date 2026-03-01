// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_set_trust_line_flags_result_code.dart';

class XdrSetTrustLineFlagsResult {
  XdrSetTrustLineFlagsResult(this._code);

  XdrSetTrustLineFlagsResultCode _code;
  XdrSetTrustLineFlagsResultCode get discriminant => this._code;
  set discriminant(XdrSetTrustLineFlagsResultCode value) => this._code = value;

  static void encode(XdrDataOutputStream stream,
      XdrSetTrustLineFlagsResult encodedSetTrustLineFlagsResult) {
    stream.writeInt(encodedSetTrustLineFlagsResult.discriminant.value);
    switch (encodedSetTrustLineFlagsResult.discriminant) {
      case XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrSetTrustLineFlagsResult decode(XdrDataInputStream stream) {
    XdrSetTrustLineFlagsResult decodedSetTrustLineFlagsResult =
        XdrSetTrustLineFlagsResult(
            XdrSetTrustLineFlagsResultCode.decode(stream));
    switch (decodedSetTrustLineFlagsResult.discriminant) {
      case XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS:
        break;
      default:
        break;
    }
    return decodedSetTrustLineFlagsResult;
  }
}
