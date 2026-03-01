// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_create_contract_args.dart';
import 'xdr_create_contract_args_v2.dart';
import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_host_function_type.dart';
import 'xdr_invoke_contract_args.dart';

class XdrHostFunctionBase {
  XdrHostFunctionType _type;
  XdrHostFunctionType get type => this._type;
  set type(XdrHostFunctionType value) => this._type = value;

  XdrInvokeContractArgs? _invokeContract;
  XdrInvokeContractArgs? get invokeContract => this._invokeContract;
  set invokeContract(XdrInvokeContractArgs? value) =>
      this._invokeContract = value;

  XdrCreateContractArgs? _createContract;
  XdrCreateContractArgs? get createContract => this._createContract;
  set createContract(XdrCreateContractArgs? value) =>
      this._createContract = value;

  XdrCreateContractArgsV2? _createContractV2;
  XdrCreateContractArgsV2? get createContractV2 => this._createContractV2;
  set createContractV2(XdrCreateContractArgsV2? value) =>
      this._createContractV2 = value;

  XdrDataValue? _wasm;
  XdrDataValue? get wasm => this._wasm;
  set wasm(XdrDataValue? value) => this._wasm = value;

  XdrHostFunctionBase(this._type);

  static void encode(XdrDataOutputStream stream, XdrHostFunctionBase encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        XdrInvokeContractArgs.encode(stream, encoded.invokeContract!);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        XdrCreateContractArgs.encode(stream, encoded.createContract!);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
        XdrDataValue.encode(stream, encoded.wasm!);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2:
        XdrCreateContractArgsV2.encode(stream, encoded.createContractV2!);
        break;
    }
  }

  static XdrHostFunctionBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrHostFunctionBase.new);
  }

  static T decodeAs<T extends XdrHostFunctionBase>(
    XdrDataInputStream stream,
    T Function(XdrHostFunctionType) constructor,
  ) {
    T decoded = constructor(XdrHostFunctionType.decode(stream));
    switch (decoded.type) {
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        decoded.invokeContract = XdrInvokeContractArgs.decode(stream);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        decoded.createContract = XdrCreateContractArgs.decode(stream);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
        decoded.wasm = XdrDataValue.decode(stream);
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2:
        decoded.createContractV2 = XdrCreateContractArgsV2.decode(stream);
        break;
    }
    return decoded;
  }
}
