// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extend_footprint_ttl_result_code.dart';

class XdrExtendFootprintTTLResult {
  XdrExtendFootprintTTLResultCode _code;

  XdrExtendFootprintTTLResultCode get discriminant => this._code;

  set discriminant(XdrExtendFootprintTTLResultCode value) => this._code = value;

  XdrExtendFootprintTTLResult(this._code);

  static void encode(
    XdrDataOutputStream stream,
    XdrExtendFootprintTTLResult encodedExtendFootprintTTLResult,
  ) {
    stream.writeInt(encodedExtendFootprintTTLResult.discriminant.value);
    switch (encodedExtendFootprintTTLResult.discriminant) {
      case XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrExtendFootprintTTLResult decode(XdrDataInputStream stream) {
    XdrExtendFootprintTTLResult decodedExtendFootprintTTLResult =
        XdrExtendFootprintTTLResult(
          XdrExtendFootprintTTLResultCode.decode(stream),
        );
    switch (decodedExtendFootprintTTLResult.discriminant) {
      case XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS:
        break;
      default:
        break;
    }
    return decodedExtendFootprintTTLResult;
  }
}
