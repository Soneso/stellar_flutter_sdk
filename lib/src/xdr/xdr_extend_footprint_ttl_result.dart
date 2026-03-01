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
    XdrExtendFootprintTTLResult encoded,
  ) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS:
      case XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_MALFORMED:
      case XdrExtendFootprintTTLResultCode
          .EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED:
      case XdrExtendFootprintTTLResultCode
          .EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE:
        break;
      default:
        break;
    }
  }

  static XdrExtendFootprintTTLResult decode(XdrDataInputStream stream) {
    XdrExtendFootprintTTLResult decoded = XdrExtendFootprintTTLResult(
      XdrExtendFootprintTTLResultCode.decode(stream),
    );
    switch (decoded.discriminant) {
      case XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS:
      case XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_MALFORMED:
      case XdrExtendFootprintTTLResultCode
          .EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED:
      case XdrExtendFootprintTTLResultCode
          .EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE:
        break;
      default:
        break;
    }
    return decoded;
  }
}
