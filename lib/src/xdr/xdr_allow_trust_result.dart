// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_allow_trust_result_code.dart';
import 'xdr_data_io.dart';

class XdrAllowTrustResult {
  XdrAllowTrustResultCode _code;

  XdrAllowTrustResultCode get discriminant => this._code;

  set discriminant(XdrAllowTrustResultCode value) => this._code = value;

  XdrAllowTrustResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrAllowTrustResult encodedAllowTrustResult,
  ) {
    stream.writeInt(encodedAllowTrustResult.discriminant.value);
    switch (encodedAllowTrustResult.discriminant) {
      case XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrAllowTrustResult decode(XdrDataInputStream stream) {
    XdrAllowTrustResult decodedAllowTrustResult = XdrAllowTrustResult(
      XdrAllowTrustResultCode.decode(stream),
    );
    switch (decodedAllowTrustResult.discriminant) {
      case XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS:
        break;
      default:
        break;
    }
    return decodedAllowTrustResult;
  }
}
