// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_create_contract_args.dart';
import 'xdr_create_contract_args_v2.dart';
import 'xdr_data_io.dart';
import 'xdr_invoke_contract_args.dart';
import 'xdr_soroban_authorized_function_base.dart';
import 'xdr_soroban_authorized_function_type.dart';

class XdrSorobanAuthorizedFunction extends XdrSorobanAuthorizedFunctionBase {
  XdrSorobanAuthorizedFunction(super.type);

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanAuthorizedFunction val,
  ) {
    XdrSorobanAuthorizedFunctionBase.encode(stream, val);
  }

  static XdrSorobanAuthorizedFunction decode(XdrDataInputStream stream) {
    return XdrSorobanAuthorizedFunctionBase.decodeAs(
      stream,
      XdrSorobanAuthorizedFunction.new,
    );
  }

  static XdrSorobanAuthorizedFunction forInvokeContractArgs(
    XdrInvokeContractArgs args,
  ) {
    var result = XdrSorobanAuthorizedFunction(
      XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
    );
    result.contractFn = args;
    return result;
  }

  static XdrSorobanAuthorizedFunction forCreateContractArgs(
    XdrCreateContractArgs args,
  ) {
    var result = XdrSorobanAuthorizedFunction(
      XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN,
    );
    result.createContractHostFn = args;
    return result;
  }

  static XdrSorobanAuthorizedFunction forCreateContractArgsV2(
    XdrCreateContractArgsV2 args,
  ) {
    var result = XdrSorobanAuthorizedFunction(
      XdrSorobanAuthorizedFunctionType
          .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN,
    );
    result.createContractV2HostFn = args;
    return result;
  }
}
