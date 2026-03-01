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
import 'xdr_host_function_type.dart';
import 'xdr_invoke_contract_args.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_val.dart';
import 'xdr_uint256.dart';

class XdrHostFunction {
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

  XdrHostFunction(this._type);

  static void encode(XdrDataOutputStream stream, XdrHostFunction encoded) {
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

  static XdrHostFunction decode(XdrDataInputStream stream) {
    XdrHostFunction decoded =
        XdrHostFunction(XdrHostFunctionType.decode(stream));
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

  static XdrHostFunction forUploadContractWasm(Uint8List contractCode) {
    XdrHostFunction result = XdrHostFunction(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM);
    result.wasm = XdrDataValue(contractCode);
    return result;
  }

  static XdrHostFunction forCreatingContract(
      XdrSCAddress address, XdrUint256 salt, String wasmId) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractIDPreimage cId = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
    cId.address = address;
    cId.salt = salt;
    XdrContractExecutable cCode = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
    cCode.wasmHash = XdrHash(Util.hexToBytes(wasmId));
    result.createContract = XdrCreateContractArgs(cId, cCode);
    return result;
  }

  static XdrHostFunction forCreatingContractV2(XdrSCAddress address,
      XdrUint256 salt, String wasmId, List<XdrSCVal> constructorArgs) {
    XdrHostFunction result = XdrHostFunction(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2);
    XdrContractIDPreimage cId = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
    cId.address = address;
    cId.salt = salt;
    XdrContractExecutable cCode = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
    cCode.wasmHash = XdrHash(Util.hexToBytes(wasmId));
    result.createContractV2 =
        XdrCreateContractArgsV2(cId, cCode, constructorArgs);
    return result;
  }

  static XdrHostFunction forDeploySACWithAsset(XdrAsset fromAsset) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractIDPreimage cId = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
    cId.fromAsset = fromAsset;
    XdrContractExecutable cCode = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);
    result.createContract = XdrCreateContractArgs(cId, cCode);
    return result;
  }

  static XdrHostFunction forInvokingContractWithArgs(
      XdrInvokeContractArgs args) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
    result.invokeContract = args;
    return result;
  }

  static XdrHostFunction forCreatingContractWithArgs(
      XdrCreateContractArgs args) {
    XdrHostFunction result =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    result.createContract = args;
    return result;
  }

  static XdrHostFunction forCreatingContractV2WithArgs(
      XdrCreateContractArgsV2 args) {
    XdrHostFunction result = XdrHostFunction(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2);
    result.createContractV2 = args;
    return result;
  }
}
