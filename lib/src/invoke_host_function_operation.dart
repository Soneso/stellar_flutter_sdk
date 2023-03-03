// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:pinenacl/tweetnacl.dart';
import 'operation.dart';
import 'muxed_account.dart';
import 'util.dart';
import 'assets.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_data_entry.dart';
import 'xdr/xdr_data_io.dart';
import 'xdr/xdr_contract.dart';
import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_transaction.dart';
import 'soroban/soroban_auth.dart';

class InvokeHostFuncOpBuilder {
  // common
  XdrHostFunctionType _hostFunctionType;
  XdrLedgerFootprint? _footprint;
  MuxedAccount? _mSourceAccount;

  // for invoking contracts
  String? _contractID;
  String? _functionName;
  List<XdrSCVal>? _arguments;

  // for installing contracts
  Uint8List? _contractCode;

  // for creating contracts
  String? _wasmId;
  XdrUint256? _salt;
  Asset? _asset;

  List<ContractAuth> contractAuth = List<ContractAuth>.empty(growable: true);

  InvokeHostFuncOpBuilder(this._hostFunctionType);

  static InvokeHostFuncOpBuilder forInvokingContract(
      String contractID, String functionName,
      {List<XdrSCVal>? functionArguments,
      XdrLedgerFootprint? footprint,
      List<ContractAuth>? contractAuth}) {
    InvokeHostFuncOpBuilder builder = InvokeHostFuncOpBuilder(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
    builder._contractID = contractID;
    builder._functionName = functionName;
    builder._arguments = functionArguments;
    builder._footprint = footprint;
    if (contractAuth != null) {
      builder.contractAuth = contractAuth;
    }
    return builder;
  }

  static InvokeHostFuncOpBuilder forInstallingContractCode(
      Uint8List contractCode,
      {XdrLedgerFootprint? footprint}) {
    InvokeHostFuncOpBuilder builder = InvokeHostFuncOpBuilder(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE);
    builder._contractCode = contractCode;
    builder._footprint = footprint;
    return builder;
  }

  static InvokeHostFuncOpBuilder forCreatingContract(String wasmId,
      {XdrUint256? salt, XdrLedgerFootprint? footprint}) {
    InvokeHostFuncOpBuilder builder = InvokeHostFuncOpBuilder(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    builder._wasmId = wasmId;
    builder._salt = salt;
    builder._footprint = footprint;
    return builder;
  }

  static InvokeHostFuncOpBuilder forDeploySACWithSourceAccount(
      {XdrUint256? salt, XdrLedgerFootprint? footprint}) {
    InvokeHostFuncOpBuilder builder = InvokeHostFuncOpBuilder(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    builder._salt = salt;
    builder._footprint = footprint;
    return builder;
  }

  static InvokeHostFuncOpBuilder forDeploySACWithAsset(Asset asset,
      {XdrLedgerFootprint? footprint}) {
    InvokeHostFuncOpBuilder builder = InvokeHostFuncOpBuilder(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    builder._asset = asset;
    builder._footprint = footprint;
    return builder;
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

  InvokeHostFuncOpBuilder setContractAuth(List<ContractAuth> contractAuth) {
    this.contractAuth = contractAuth;
    return this;
  }

  ///Builds an operation
  InvokeHostFunctionOperation build() {
    InvokeHostFunctionOperation? operation;
    if (this._hostFunctionType ==
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT) {
      // build invoke contract op
      operation = InvokeContractOp(_contractID!, _functionName!,
          arguments: _arguments,
          footprint: _footprint,
          contractAuth: ContractAuth.toXdrList(contractAuth));
    } else if (this._hostFunctionType ==
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE) {
      // build install contract code op
      operation = InstallContractCodeOp(_contractCode!, footprint: _footprint);
    } else if (this._hostFunctionType ==
            XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT &&
        _wasmId != null) {
      // build create contract op
      operation =
          CreateContractOp(_wasmId!, salt: _salt, footprint: _footprint);
    } else if (this._hostFunctionType ==
            XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT &&
        this._asset != null) {
      // build deploy create token contract with asset op
      operation = DeploySACWithAssetOp(this._asset!, footprint: _footprint);
    } else if (this._hostFunctionType ==
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT) {
      // build deploy create token contract with account op
      operation =
          DeploySACWithSourceAccountOp(salt: _salt, footprint: _footprint);
    }

    if (operation != null) {
      operation.sourceAccount = _mSourceAccount;
      return operation;
    } else {
      throw UnimplementedError();
    }
  }
}

abstract class InvokeHostFunctionOperation extends Operation {
  XdrHostFunctionType _functionType;
  XdrLedgerFootprint? footprint;
  List<XdrContractAuth> contractAuth =
      List<XdrContractAuth>.empty(growable: true);

  InvokeHostFunctionOperation(this._functionType,
      {this.footprint, List<XdrContractAuth>? contractAuth}) {
    if (contractAuth != null) {
      this.contractAuth = contractAuth;
    }
  }

  XdrHostFunctionType get functionType => this._functionType;

  setContractAuth(List<XdrContractAuth> contractAuth) {
    this.contractAuth = contractAuth;
  }

  setFootprintBase64(String base64XdrFootprint) {
    Uint8List bytes = base64Decode(base64XdrFootprint);
    this.footprint = XdrLedgerFootprint.decode(XdrDataInputStream(bytes));
  }

  String? getFootprintBase64() {
    if (footprint != null) {
      XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
      XdrLedgerFootprint.encode(xdrOutputStream, footprint!);
      return base64Encode(xdrOutputStream.bytes);
    }
    return null;
  }

  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    if (op.function.discriminant ==
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT) {
      // use builder of invoke contract op
      return InvokeContractOp.builder(op);
    } else if (op.function.discriminant ==
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE) {
      // use builder of install contract code op
      return InstallContractCodeOp.builder(op);
    } else if (op.function.discriminant ==
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT) {
      if (op.function.createContractArgs != null &&
          op.function.createContractArgs!.contractID.discriminant ==
              XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT) {
        if (op.function.createContractArgs!.source.discriminant ==
            XdrSCContractCodeType.SCCONTRACT_CODE_WASM_REF) {
          // use builder of create contract op
          return CreateContractOp.builder(op);
        } else if (op.function.createContractArgs!.source.discriminant ==
            XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN) {
          // use builder of deploy stellar asset contract with account op
          return DeploySACWithSourceAccountOp.builder(op);
        }
      } else if (op.function.createContractArgs != null &&
          op.function.createContractArgs!.contractID.discriminant ==
              XdrContractIDType.CONTRACT_ID_FROM_ASSET) {
        // use builder of deploy stellar asset contract with asset op
        return DeploySACWithAssetOp.builder(op);
      }
    }

    throw UnimplementedError();
  }

  XdrLedgerFootprint getXdrFootprint() {
    XdrLedgerFootprint xdrFootprint = this.footprint != null
        ? this.footprint!
        : XdrLedgerFootprint(
            List<XdrLedgerKey>.empty(), List<XdrLedgerKey>.empty());
    return xdrFootprint;
  }
}

class InvokeContractOp extends InvokeHostFunctionOperation {
  String _contractID;
  String _functionName;
  List<XdrSCVal>? _arguments;

  InvokeContractOp(this._contractID, this._functionName,
      {List<XdrSCVal>? arguments,
      XdrLedgerFootprint? footprint,
      List<XdrContractAuth>? contractAuth})
      : super(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT,
            footprint: footprint, contractAuth: contractAuth) {
    this._arguments = arguments;
  }

  String get contractID => _contractID;
  String get functionName => _functionName;
  List<XdrSCVal>? get arguments => _arguments;

  @override
  XdrOperationBody toOperationBody() {
    List<XdrSCVal> invokeArgsList = List<XdrSCVal>.empty(growable: true);

    // contract id
    XdrSCVal contractIDScVal = XdrSCVal(XdrSCValType.SCV_OBJECT);
    XdrSCObject contractIDSCObject = XdrSCObject(XdrSCObjectType.SCO_BYTES);
    contractIDSCObject.bin = XdrDataValue(Util.hexToBytes(this._contractID));
    contractIDScVal.obj = contractIDSCObject;
    invokeArgsList.add(contractIDScVal);

    // function name
    XdrSCVal functionNameScVal = XdrSCVal(XdrSCValType.SCV_SYMBOL);
    functionNameScVal.sym = this._functionName;
    invokeArgsList.add(functionNameScVal);

    // arguments for the function call
    if (this._arguments != null) {
      invokeArgsList.addAll(this._arguments!);
    }

    // prepare function
    XdrHostFunction xdrHostFunction =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
    xdrHostFunction.invokeArgs = invokeArgsList;

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = XdrInvokeHostFunctionOp(
        xdrHostFunction, getXdrFootprint(), contractAuth);
    return body;
  }

  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    XdrHostFunction xdrHostFunction = op.function;
    if (xdrHostFunction.discriminant !=
            XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT ||
        xdrHostFunction.invokeArgs == null) {
      throw new Exception("invalid argument");
    }

    List<XdrSCVal> invokeArgsList = xdrHostFunction.invokeArgs!;
    if (invokeArgsList.length < 2 ||
        invokeArgsList.elementAt(0).discriminant != XdrSCValType.SCV_OBJECT ||
        invokeArgsList.elementAt(0).obj == null ||
        invokeArgsList.elementAt(1).discriminant != XdrSCValType.SCV_SYMBOL ||
        invokeArgsList.elementAt(1).sym == null) {
      throw new Exception("invalid argument");
    }

    XdrSCObject contractIDSCObject = invokeArgsList.elementAt(0).obj!;
    if (contractIDSCObject.discriminant != XdrSCObjectType.SCO_BYTES ||
        contractIDSCObject.bin == null) {
      throw new Exception("invalid argument");
    }
    String contractID = Util.bytesToHex(contractIDSCObject.bin!.dataValue);
    String functionName = invokeArgsList.elementAt(1).sym!;

    List<XdrSCVal>? funcArgs;
    if (invokeArgsList.length > 2) {
      funcArgs = List<XdrSCVal>.empty(growable: true);
      for (int i = 2; i < invokeArgsList.length; i++) {
        funcArgs.add(invokeArgsList[i]);
      }
    }

    List<ContractAuth> contractAuth = ContractAuth.fromXdrList(op.contractAuth);

    return InvokeHostFuncOpBuilder.forInvokingContract(contractID, functionName,
        functionArguments: funcArgs,
        footprint: op.footprint,
        contractAuth: contractAuth);
  }
}

class InstallContractCodeOp extends InvokeHostFunctionOperation {
  Uint8List _contractBytes;

  InstallContractCodeOp(this._contractBytes, {XdrLedgerFootprint? footprint})
      : super(XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE,
            footprint: footprint);

  Uint8List get contractBytes => _contractBytes;

  @override
  XdrOperationBody toOperationBody() {
    XdrHostFunction xdrHostFunction = XdrHostFunction(
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE);
    xdrHostFunction.installContractCodeArgs =
        XdrInstallContractCodeArgs(XdrDataValue(_contractBytes));

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = XdrInvokeHostFunctionOp(
        xdrHostFunction, getXdrFootprint(), contractAuth);
    return body;
  }

  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    XdrHostFunction xdrHostFunction = op.function;
    if (xdrHostFunction.discriminant !=
            XdrHostFunctionType.HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE ||
        xdrHostFunction.installContractCodeArgs == null) {
      throw new Exception("invalid argument");
    }

    return InvokeHostFuncOpBuilder.forInstallingContractCode(
        xdrHostFunction.installContractCodeArgs!.code.dataValue,
        footprint: op.footprint);
  }
}

class CreateContractOp extends InvokeHostFunctionOperation {
  String _wasmId;
  late XdrUint256 _salt;

  CreateContractOp(this._wasmId,
      {XdrUint256? salt, XdrLedgerFootprint? footprint})
      : super(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT,
            footprint: footprint) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  String get wasmId => _wasmId;
  XdrUint256 get salt => _salt;

  @override
  XdrOperationBody toOperationBody() {
    XdrHostFunction xdrHostFunction =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractID contractId =
        XdrContractID(XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT);
    contractId.salt = this._salt;

    XdrSCContractCode code =
        XdrSCContractCode(XdrSCContractCodeType.SCCONTRACT_CODE_WASM_REF);
    code.wasmId = XdrHash(Util.hexToBytes(wasmId));

    xdrHostFunction.createContractArgs =
        XdrCreateContractArgs(contractId, code);

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = XdrInvokeHostFunctionOp(
        xdrHostFunction, getXdrFootprint(), contractAuth);
    return body;
  }

  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    XdrHostFunction xdrHostFunction = op.function;
    if (xdrHostFunction.discriminant !=
            XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT ||
        xdrHostFunction.createContractArgs == null ||
        xdrHostFunction.createContractArgs!.contractID.discriminant !=
            XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT ||
        xdrHostFunction.createContractArgs!.source.discriminant !=
            XdrSCContractCodeType.SCCONTRACT_CODE_WASM_REF ||
        xdrHostFunction.createContractArgs!.source.wasmId == null) {
      throw new Exception("invalid argument");
    }

    XdrLedgerFootprint? footprint;
    if (op.footprint.readOnly.isNotEmpty && op.footprint.readWrite.isNotEmpty) {
      footprint = op.footprint;
    }
    String wasmId = Util.bytesToHex(
        xdrHostFunction.createContractArgs!.source.wasmId!.hash);
    return InvokeHostFuncOpBuilder.forCreatingContract(wasmId,
        salt: xdrHostFunction.createContractArgs!.contractID.salt,
        footprint: footprint);
  }
}

class DeploySACWithSourceAccountOp extends InvokeHostFunctionOperation {
  late XdrUint256 _salt;

  DeploySACWithSourceAccountOp(
      {XdrUint256? salt, XdrLedgerFootprint? footprint})
      : super(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT,
            footprint: footprint) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  XdrUint256 get salt => _salt;

  @override
  XdrOperationBody toOperationBody() {
    XdrHostFunction xdrHostFunction =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractID contractId =
        XdrContractID(XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT);
    contractId.salt = this._salt;

    XdrSCContractCode code =
        XdrSCContractCode(XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN);

    xdrHostFunction.createContractArgs =
        XdrCreateContractArgs(contractId, code);

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = XdrInvokeHostFunctionOp(
        xdrHostFunction, getXdrFootprint(), contractAuth);
    return body;
  }

  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    XdrHostFunction xdrHostFunction = op.function;
    if (xdrHostFunction.discriminant !=
            XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT ||
        xdrHostFunction.createContractArgs == null ||
        xdrHostFunction.createContractArgs!.contractID.discriminant !=
            XdrContractIDType.CONTRACT_ID_FROM_SOURCE_ACCOUNT ||
        xdrHostFunction.createContractArgs!.source.discriminant !=
            XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN) {
      throw new Exception("invalid argument");
    }

    return InvokeHostFuncOpBuilder.forDeploySACWithSourceAccount(
        salt: xdrHostFunction.createContractArgs!.contractID.salt,
        footprint: op.footprint);
  }
}

class DeploySACWithAssetOp extends InvokeHostFunctionOperation {
  Asset _asset;

  DeploySACWithAssetOp(this._asset, {XdrLedgerFootprint? footprint})
      : super(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT,
            footprint: footprint);

  Asset get asset => _asset;

  @override
  XdrOperationBody toOperationBody() {
    XdrHostFunction xdrHostFunction =
        XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
    XdrContractID contractId =
        XdrContractID(XdrContractIDType.CONTRACT_ID_FROM_ASSET);
    contractId.asset = this._asset.toXdr();

    XdrSCContractCode code =
        XdrSCContractCode(XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN);

    xdrHostFunction.createContractArgs =
        XdrCreateContractArgs(contractId, code);

    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = XdrInvokeHostFunctionOp(
        xdrHostFunction, getXdrFootprint(), contractAuth);
    return body;
  }

  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    XdrHostFunction xdrHostFunction = op.function;
    if (xdrHostFunction.discriminant !=
            XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT ||
        xdrHostFunction.createContractArgs == null ||
        xdrHostFunction.createContractArgs!.contractID.discriminant !=
            XdrContractIDType.CONTRACT_ID_FROM_ASSET ||
        xdrHostFunction.createContractArgs!.contractID.asset == null ||
        xdrHostFunction.createContractArgs!.source.discriminant !=
            XdrSCContractCodeType.SCCONTRACT_CODE_TOKEN) {
      throw new Exception("invalid argument");
    }

    return InvokeHostFuncOpBuilder.forDeploySACWithAsset(
        Asset.fromXdr(xdrHostFunction.createContractArgs!.contractID.asset!),
        footprint: op.footprint);
  }
}
