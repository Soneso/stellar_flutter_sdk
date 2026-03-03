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

  XdrHash? _success;

  XdrHash? get success => this._success;

  XdrInvokeHostFunctionResult(this._code);

  set success(XdrHash? value) => this._success = value;

  static void encode(XdrDataOutputStream stream, XdrInvokeHostFunctionResult encodedInvokeHostFunctionResult) {
    stream.writeInt(encodedInvokeHostFunctionResult.discriminant.value);
    switch (encodedInvokeHostFunctionResult.discriminant) {
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS:
        XdrHash.encode(stream, encodedInvokeHostFunctionResult._success!);
        break;
      default:
        break;
    }
  }

  static XdrInvokeHostFunctionResult decode(XdrDataInputStream stream) {
    XdrInvokeHostFunctionResult decodedInvokeHostFunctionResult = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.decode(stream));
    switch (decodedInvokeHostFunctionResult.discriminant) {
      case XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS:
        decodedInvokeHostFunctionResult._success = XdrHash.decode(stream);
        break;
      default:
        break;
    }
    return decodedInvokeHostFunctionResult;
  }
}
