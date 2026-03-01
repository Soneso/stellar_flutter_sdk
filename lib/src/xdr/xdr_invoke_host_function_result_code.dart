// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrInvokeHostFunctionResultCode {
  final _value;
  const XdrInvokeHostFunctionResultCode._internal(this._value);
  toString() => 'InvokeHostFunctionResultCode.$_value';
  XdrInvokeHostFunctionResultCode(this._value);
  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrInvokeHostFunctionResultCode && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Success
  static const INVOKE_HOST_FUNCTION_SUCCESS =
      const XdrInvokeHostFunctionResultCode._internal(0);

  /// Invalid
  static const INVOKE_HOST_FUNCTION_MALFORMED =
      const XdrInvokeHostFunctionResultCode._internal(-1);

  /// Trapped
  static const INVOKE_HOST_FUNCTION_TRAPPED =
      const XdrInvokeHostFunctionResultCode._internal(-2);

  static const INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED =
      const XdrInvokeHostFunctionResultCode._internal(-3);

  static const INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED =
      const XdrInvokeHostFunctionResultCode._internal(-4);

  static const INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE =
      const XdrInvokeHostFunctionResultCode._internal(-5);

  static XdrInvokeHostFunctionResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return INVOKE_HOST_FUNCTION_SUCCESS;
      case -1:
        return INVOKE_HOST_FUNCTION_MALFORMED;
      case -2:
        return INVOKE_HOST_FUNCTION_TRAPPED;
      case -3:
        return INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED;
      case -4:
        return INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED;
      case -5:
        return INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
    XdrDataOutputStream stream,
    XdrInvokeHostFunctionResultCode value,
  ) {
    stream.writeInt(value.value);
  }
}
