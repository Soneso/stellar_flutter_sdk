// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/util.dart';

import 'xdr_asset.dart';
import 'xdr_contract_executable.dart';
import 'xdr_contract_executable_type.dart';
import 'xdr_contract_id_preimage.dart';
import 'xdr_contract_id_preimage_type.dart';
import 'xdr_create_contract_args.dart';
import 'xdr_create_contract_args_v2.dart';
import 'xdr_data_io.dart';
import 'xdr_data_value.dart';
import 'xdr_hash.dart';
import 'xdr_host_function_base.dart';
import 'xdr_host_function_type.dart';
import 'xdr_invoke_contract_args.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_val.dart';
import 'xdr_uint256.dart';

class XdrHostFunction extends XdrHostFunctionBase {
  XdrHostFunction(super.type);

  /// Alias for [discriminant] — backward compatibility with hand-written API.
  XdrHostFunctionType get type => discriminant;
  set type(XdrHostFunctionType value) => discriminant = value;

  static void encode(XdrDataOutputStream stream, XdrHostFunction val) {
    XdrHostFunctionBase.encode(stream, val);
  }

  static XdrHostFunction decode(XdrDataInputStream stream) {
    return XdrHostFunctionBase.decodeAs(stream, XdrHostFunction.new);
  }

  static XdrHostFunction forUploadContractWasm(Uint8List contractCode) {
    XdrHostFunction result = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM,
    );
    result.wasm = XdrDataValue(contractCode);
    return result;
  }

  static XdrHostFunction forCreatingContract(
    XdrSCAddress address,
    XdrUint256 salt,
    String wasmId,
  ) {
    XdrHostFunction result = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT,
    );
    XdrContractIDPreimage cId = XdrContractIDPreimage(
      XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
    );
    cId.address = address;
    cId.salt = salt;
    XdrContractExecutable cCode = XdrContractExecutable(
      XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM,
    );
    cCode.wasmHash = XdrHash(Util.hexToBytes(wasmId));
    result.createContract = XdrCreateContractArgs(cId, cCode);
    return result;
  }

  static XdrHostFunction forCreatingContractV2(
    XdrSCAddress address,
    XdrUint256 salt,
    String wasmId,
    List<XdrSCVal> constructorArgs,
  ) {
    XdrHostFunction result = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2,
    );
    XdrContractIDPreimage cId = XdrContractIDPreimage(
      XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
    );
    cId.address = address;
    cId.salt = salt;
    XdrContractExecutable cCode = XdrContractExecutable(
      XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM,
    );
    cCode.wasmHash = XdrHash(Util.hexToBytes(wasmId));
    result.createContractV2 = XdrCreateContractArgsV2(
      cId,
      cCode,
      constructorArgs,
    );
    return result;
  }

  static XdrHostFunction forDeploySACWithAsset(XdrAsset fromAsset) {
    XdrHostFunction result = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT,
    );
    XdrContractIDPreimage cId = XdrContractIDPreimage(
      XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET,
    );
    cId.fromAsset = fromAsset;
    XdrContractExecutable cCode = XdrContractExecutable(
      XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET,
    );
    result.createContract = XdrCreateContractArgs(cId, cCode);
    return result;
  }

  static XdrHostFunction forInvokingContractWithArgs(
    XdrInvokeContractArgs args,
  ) {
    XdrHostFunction result = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT,
    );
    result.invokeContract = args;
    return result;
  }

  static XdrHostFunction forCreatingContractWithArgs(
    XdrCreateContractArgs args,
  ) {
    XdrHostFunction result = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT,
    );
    result.createContract = args;
    return result;
  }

  static XdrHostFunction forCreatingContractV2WithArgs(
    XdrCreateContractArgsV2 args,
  ) {
    XdrHostFunction result = XdrHostFunction(
      XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2,
    );
    result.createContractV2 = args;
    return result;
  }
}
