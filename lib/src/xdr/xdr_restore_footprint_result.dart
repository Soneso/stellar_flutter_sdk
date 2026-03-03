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
    XdrDataOutputStream stream,
    XdrRestoreFootprintResult encodedRestoreFootprintResult,
  ) {
    stream.writeInt(encodedRestoreFootprintResult.discriminant.value);
    switch (encodedRestoreFootprintResult.discriminant) {
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrRestoreFootprintResult decode(XdrDataInputStream stream) {
    XdrRestoreFootprintResult decodedRestoreFootprintResult =
        XdrRestoreFootprintResult(XdrRestoreFootprintResultCode.decode(stream));
    switch (decodedRestoreFootprintResult.discriminant) {
      case XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS:
        break;
      default:
        break;
    }
    return decodedRestoreFootprintResult;
  }
}
