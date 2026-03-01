// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_invoke_host_function_result_code.dart';

class XdrInvokeHostFunctionResult {
  XdrInvokeHostFunctionResultCode _code;
  XdrInvokeHostFunctionResultCode get discriminant => this._code;
  set discriminant(XdrInvokeHostFunctionResultCode value) => this._code = value;

  XdrHash? _success; // sha256(XdrInvokeHostFunctionSuccessPreImage)
  XdrHash? get success => this._success;
  set success(XdrHash? value) => this._success = value;

  XdrInvokeHostFunctionResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrInvokeHostFunctionResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS:
        XdrHash.encode(stream, encoded.success!);
        break;
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED:
      case XdrInvokeHostFunctionResultCode
            .INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED:
      case XdrInvokeHostFunctionResultCode
            .INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE:
        break;
      default:
        break;
    }
  }

  static XdrInvokeHostFunctionResult decode(XdrDataInputStream stream) {
    XdrInvokeHostFunctionResult decoded = XdrInvokeHostFunctionResult(
        XdrInvokeHostFunctionResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS:
        decoded.success = XdrHash.decode(stream);
        break;
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED:
      case XdrInvokeHostFunctionResultCode
            .INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED:
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED:
      case XdrInvokeHostFunctionResultCode
            .INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE:
        break;
      default:
        break;
    }
    return decoded;
  }
}
