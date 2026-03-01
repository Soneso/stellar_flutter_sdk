// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_restore_footprint_result_code.dart';

class XdrRestoreFootprintResult {
  XdrRestoreFootprintResultCode _code;
  XdrRestoreFootprintResultCode get discriminant => this._code;
  set discriminant(XdrRestoreFootprintResultCode value) => this._code = value;

  XdrRestoreFootprintResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrRestoreFootprintResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS:
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_MALFORMED:
      case XdrRestoreFootprintResultCode
            .RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED:
      case XdrRestoreFootprintResultCode
            .RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE:
        break;
      default:
        break;
    }
  }

  static XdrRestoreFootprintResult decode(XdrDataInputStream stream) {
    XdrRestoreFootprintResult decoded =
        XdrRestoreFootprintResult(XdrRestoreFootprintResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS:
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_MALFORMED:
      case XdrRestoreFootprintResultCode
            .RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED:
      case XdrRestoreFootprintResultCode
            .RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE:
        break;
      default:
        break;
    }
    return decoded;
  }
}
