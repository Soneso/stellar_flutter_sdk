// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_operation_result_code.dart';
import 'xdr_operation_result_tr.dart';

class XdrOperationResult {
  XdrOperationResult(this._code);
  XdrOperationResultCode _code;
  XdrOperationResultCode get discriminant => this._code;
  set discriminant(XdrOperationResultCode value) => this._code = value;

  XdrOperationResultTr? _tr;
  XdrOperationResultTr? get tr => this._tr;
  set tr(XdrOperationResultTr? value) => this._tr = value;

  static void encode(
      XdrDataOutputStream stream, XdrOperationResult encodedOperationResult) {
    stream.writeInt(encodedOperationResult.discriminant.value);
    switch (encodedOperationResult.discriminant) {
      case XdrOperationResultCode.opINNER:
        XdrOperationResultTr.encode(stream, encodedOperationResult.tr!);
        break;
      default:
        break;
    }
  }

  static XdrOperationResult decode(XdrDataInputStream stream) {
    XdrOperationResult decodedOperationResult =
        XdrOperationResult(XdrOperationResultCode.decode(stream));
    switch (decodedOperationResult.discriminant) {
      case XdrOperationResultCode.opINNER:
        decodedOperationResult.tr = XdrOperationResultTr.decode(stream);
        break;
      default:
        break;
    }
    return decodedOperationResult;
  }
}
