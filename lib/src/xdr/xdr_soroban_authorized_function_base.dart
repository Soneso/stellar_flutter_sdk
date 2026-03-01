// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_create_contract_args.dart';
import 'xdr_create_contract_args_v2.dart';
import 'xdr_data_io.dart';
import 'xdr_invoke_contract_args.dart';
import 'xdr_soroban_authorized_function_type.dart';

class XdrSorobanAuthorizedFunctionBase {
  XdrSorobanAuthorizedFunctionBase(this._type);
  XdrSorobanAuthorizedFunctionType _type;
  XdrSorobanAuthorizedFunctionType get type => this._type;
  set type(XdrSorobanAuthorizedFunctionType value) => this._type = value;

  XdrInvokeContractArgs? _contractFn;
  XdrInvokeContractArgs? get contractFn => this._contractFn;
  set contractFn(XdrInvokeContractArgs? value) => this._contractFn = value;

  XdrCreateContractArgs? _createContractHostFn;
  XdrCreateContractArgs? get createContractHostFn => this._createContractHostFn;
  set createContractHostFn(XdrCreateContractArgs? value) =>
      this._createContractHostFn = value;

  XdrCreateContractArgsV2? _createContractV2HostFn;
  XdrCreateContractArgsV2? get createContractV2HostFn =>
      this._createContractV2HostFn;
  set createContractV2HostFn(XdrCreateContractArgsV2? value) =>
      this._createContractV2HostFn = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanAuthorizedFunctionBase encoded,
  ) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN:
        XdrInvokeContractArgs.encode(stream, encoded.contractFn!);
        break;
      case XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN:
        XdrCreateContractArgs.encode(stream, encoded.createContractHostFn!);
        break;
      case XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN:
        XdrCreateContractArgsV2.encode(stream, encoded.createContractV2HostFn!);
        break;
    }
  }

  static XdrSorobanAuthorizedFunctionBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrSorobanAuthorizedFunctionBase.new);
  }

  static T decodeAs<T extends XdrSorobanAuthorizedFunctionBase>(
    XdrDataInputStream stream,
    T Function(XdrSorobanAuthorizedFunctionType) constructor,
  ) {
    T decoded = constructor(XdrSorobanAuthorizedFunctionType.decode(stream));
    switch (decoded.type) {
      case XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN:
        decoded.contractFn = XdrInvokeContractArgs.decode(stream);
        break;
      case XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN:
        decoded.createContractHostFn = XdrCreateContractArgs.decode(stream);
        break;
      case XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN:
        decoded.createContractV2HostFn = XdrCreateContractArgsV2.decode(stream);
        break;
    }
    return decoded;
  }
}
