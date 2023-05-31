// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:pinenacl/tweetnacl.dart';
import 'operation.dart';
import 'muxed_account.dart';
import 'util.dart';
import 'assets.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_contract.dart';
import 'xdr/xdr_type.dart';
import 'soroban/soroban_auth.dart';

abstract class HostFunction {
  late List<ContractAuth> _auth;
  List<ContractAuth> get auth => this._auth;
  set auth(List<ContractAuth> value) => this._auth = value;

  HostFunction(List<ContractAuth>? auth) {
    this._auth = auth == null ? List<ContractAuth>.empty(growable: true) : auth;
  }

  XdrHostFunction toXdr();

  factory HostFunction.fromXdr(XdrHostFunction xdr) {
    XdrHostFunctionType type = xdr.args.type;
    switch (type) {
      // Account effects
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
        if (xdr.args.uploadContractWasm != null) {
          return UploadContractWasmHostFunction(
              xdr.args.uploadContractWasm!.code.dataValue,
              auth: ContractAuth.fromXdrList(xdr.auth));
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        if (xdr.args.invokeContract != null) {
          List<XdrSCVal> invokeArgsList = xdr.args.invokeContract!;
          if (invokeArgsList.length < 2 ||
              invokeArgsList.elementAt(0).discriminant !=
                  XdrSCValType.SCV_BYTES ||
              invokeArgsList.elementAt(0).bytes == null ||
              invokeArgsList.elementAt(1).discriminant !=
                  XdrSCValType.SCV_SYMBOL ||
              invokeArgsList.elementAt(1).sym == null) {
            throw UnimplementedError();
          }
          String contractID =
              Util.bytesToHex(invokeArgsList.elementAt(0).bytes!.dataValue);
          String functionName = invokeArgsList.elementAt(1).sym!;
          List<XdrSCVal>? funcArgs;
          if (invokeArgsList.length > 2) {
            funcArgs = List<XdrSCVal>.empty(growable: true);
            for (int i = 2; i < invokeArgsList.length; i++) {
              funcArgs.add(invokeArgsList[i]);
            }
          }
          return InvokeContractHostFunction(contractID, functionName,
              arguments: funcArgs,
              auth: ContractAuth.fromXdrList(xdr.auth));
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        if (xdr.args.createContract != null) {
          if (xdr.args.createContract!.contractID.discriminant ==
              XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT) {
            if (xdr.args.createContract!.executable.discriminant ==
                    XdrSCContractExecutableType
                        .SCCONTRACT_EXECUTABLE_WASM_REF &&
                xdr.args.createContract!.executable.wasmId != null) {
              String wasmId = Util.bytesToHex(
                  xdr.args.createContract!.executable.wasmId!.hash);
              return CreateContractHostFunction(
                  wasmId, salt: xdr.args.createContract!.contractID.salt!,
                  auth: ContractAuth.fromXdrList(xdr.auth));
            } else if (xdr.args.createContract!.executable.discriminant ==
                XdrSCContractExecutableType.SCCONTRACT_EXECUTABLE_TOKEN) {
              return DeploySACWithSourceAccountHostFunction(
                  salt: xdr.args.createContract!.contractID.salt!,
                  auth: ContractAuth.fromXdrList(xdr.auth));
            }
          } else if (xdr.args.createContract!.contractID.discriminant ==
                  XdrContractIDType.CONTRACT_ID_FROM_ASSET &&
              xdr.args.createContract!.executable.discriminant ==
                  XdrSCContractExecutableType.SCCONTRACT_EXECUTABLE_TOKEN) {
            return DeploySACWithAssetHostFunction(
                Asset.fromXdr(xdr.args.createContract!.contractID.asset!),
                auth: ContractAuth.fromXdrList(xdr.auth));
          }
        }
        break;
    }
    throw UnimplementedError();
  }
}

class UploadContractWasmHostFunction extends HostFunction {
  Uint8List _contractCode;
  Uint8List get contractCode => this._contractCode;
  set contractCode(Uint8List value) => this._contractCode = value;

  UploadContractWasmHostFunction(this._contractCode, {List<ContractAuth>? auth})
      : super(auth);

  @override
  XdrHostFunction toXdr() {
    XdrHostFunctionArgs args =
        XdrHostFunctionArgs.forUploadContractWasm(contractCode);
    return XdrHostFunction(args, ContractAuth.toXdrList(auth));
  }
}

class CreateContractHostFunction extends HostFunction {
  String _wasmId;
  String get wasmId => this._wasmId;
  set wasmId(String value) => this._wasmId = value;

  late XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  CreateContractHostFunction(this._wasmId,
      {XdrUint256? salt, List<ContractAuth>? auth})
      : super(auth) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  @override
  XdrHostFunction toXdr() {
    XdrHostFunctionArgs args =
        XdrHostFunctionArgs.forCreatingContract(wasmId, salt);
    return XdrHostFunction(args, ContractAuth.toXdrList(auth));
  }
}

class DeploySACWithSourceAccountHostFunction extends HostFunction {
  late XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  DeploySACWithSourceAccountHostFunction(
      {XdrUint256? salt, List<ContractAuth>? auth})
      : super(auth) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  @override
  XdrHostFunction toXdr() {
    XdrHostFunctionArgs args =
        XdrHostFunctionArgs.forDeploySACWithSourceAccount(salt);
    return XdrHostFunction(args, ContractAuth.toXdrList(auth));
  }
}

class DeploySACWithAssetHostFunction extends HostFunction {
  Asset _asset;
  Asset get asset => this._asset;
  set asset(Asset value) => this._asset = value;

  DeploySACWithAssetHostFunction(this._asset, {List<ContractAuth>? auth})
      : super(auth);

  @override
  XdrHostFunction toXdr() {
    XdrHostFunctionArgs args =
        XdrHostFunctionArgs.forDeploySACWithAsset(asset.toXdr());
    return XdrHostFunction(args, ContractAuth.toXdrList(auth));
  }
}

class InvokeContractHostFunction extends HostFunction {
  String _contractID;
  String get contractID => this._contractID;
  set contractID(String value) => this._contractID = value;

  String _functionName;
  String get functionName => this._functionName;
  set functionName(String value) => this._functionName = value;

  List<XdrSCVal>? arguments;

  InvokeContractHostFunction(this._contractID, this._functionName,
      {this.arguments, List<ContractAuth>? auth})
      : super(auth);

  @override
  XdrHostFunction toXdr() {
    List<XdrSCVal> invokeArgsList = List<XdrSCVal>.empty(growable: true);

    // contract id
    XdrSCVal contractIDScVal =
        XdrSCVal.forBytes(Util.hexToBytes(this._contractID));
    invokeArgsList.add(contractIDScVal);

    // function name
    XdrSCVal functionNameScVal = XdrSCVal(XdrSCValType.SCV_SYMBOL);
    functionNameScVal.sym = this._functionName;
    invokeArgsList.add(functionNameScVal);

    // arguments for the function call
    if (this.arguments != null) {
      invokeArgsList.addAll(this.arguments!);
    }

    XdrHostFunctionArgs args =
        XdrHostFunctionArgs.forInvokingContractWithArgs(invokeArgsList);
    return XdrHostFunction(args, ContractAuth.toXdrList(auth));
  }
}

class InvokeHostFuncOpBuilder {
  MuxedAccount? _mSourceAccount;

  late List<HostFunction> _functions;
  List<HostFunction> get functions => this._functions;
  set functions(List<HostFunction> value) => this._functions = value;

  InvokeHostFuncOpBuilder({List<HostFunction>? functions}) {
    this._functions = functions == null
        ? List<HostFunction>.empty(growable: true)
        : functions;
  }

  /// Sets the source account for this operation represented by [sourceAccountId].
  InvokeHostFuncOpBuilder setSourceAccount(String sourceAccountId) {
    MuxedAccount? sa = MuxedAccount.fromAccountId(sourceAccountId);
    _mSourceAccount = checkNotNull(sa, "invalid sourceAccountId");
    return this;
  }

  /// Sets the muxed source account for this operation represented by [sourceAccount].
  InvokeHostFuncOpBuilder setMuxedSourceAccount(MuxedAccount sourceAccount) {
    _mSourceAccount = sourceAccount;
    return this;
  }

  InvokeHostFuncOpBuilder addFunction(HostFunction function) {
    this.functions.add(function);
    return this;
  }

  ///Builds an operation
  InvokeHostFunctionOperation build() {
    InvokeHostFunctionOperation op = InvokeHostFunctionOperation(functions);
    op.sourceAccount = _mSourceAccount;
    return op;
  }
}

class InvokeHostFunctionOperation extends Operation {
  List<HostFunction> _functions;
  List<HostFunction> get functions => this._functions;
  set functions(List<HostFunction> value) => this._functions = value;

  InvokeHostFunctionOperation(this._functions);

  static InvokeHostFuncOpBuilder builder(
      XdrInvokeHostFunctionOp op) {
    List<HostFunction> functions = List<HostFunction>.empty(growable: true);
    for (int i = 0; i < op.functions.length; i++) {
      functions.add(HostFunction.fromXdr(op.functions[i]));
    }
    return InvokeHostFuncOpBuilder(functions: functions);
  }

  @override
  XdrOperationBody toOperationBody() {
    List<XdrHostFunction> xdrFunctions =
        List<XdrHostFunction>.empty(growable: true);
    for (int i = 0; i < functions.length; i++) {
      xdrFunctions.add(functions[i].toXdr());
    }
    XdrInvokeHostFunctionOp xdrOp = XdrInvokeHostFunctionOp(xdrFunctions);
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = xdrOp;
    return body;
  }
}
