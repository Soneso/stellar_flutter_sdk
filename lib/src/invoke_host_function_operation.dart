// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:pinenacl/tweetnacl.dart';
import 'xdr/xdr_transaction.dart';
import 'operation.dart';
import 'muxed_account.dart';
import 'util.dart';
import 'assets.dart';
import 'xdr/xdr_operation.dart';
import 'xdr/xdr_contract.dart';
import 'xdr/xdr_type.dart';
import 'soroban/soroban_auth.dart';

abstract class HostFunction {
  HostFunction();

  XdrHostFunction toXdr();

  factory HostFunction.fromXdr(XdrHostFunction xdr) {
    XdrHostFunctionType type = xdr.type;
    switch (type) {
      // Account effects
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM:
        if (xdr.wasm != null) {
          return UploadContractWasmHostFunction(xdr.wasm!.dataValue);
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT:
        if (xdr.invokeContract != null) {
          XdrInvokeContractArgs invokeArgs = xdr.invokeContract!;
          if (invokeArgs.contractAddress.contractId == null) {
            throw UnimplementedError();
          }
          String contractID =
              Util.bytesToHex(invokeArgs.contractAddress.contractId!.hash);
          String functionName = invokeArgs.functionName;
          List<XdrSCVal> funcArgs = invokeArgs.args;
          return InvokeContractHostFunction(contractID, functionName,
              arguments: funcArgs);
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT:
        if (xdr.createContract != null) {
          if (xdr.createContract!.contractIDPreimage.type ==
              XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS) {
            if (xdr.createContract!.executable.type ==
                    XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM &&
                xdr.createContract!.executable.wasmHash != null) {
              String wasmId = Util.bytesToHex(
                  xdr.createContract!.executable.wasmHash!.hash);
              return CreateContractHostFunction(
                  Address.fromXdr(
                      xdr.createContract!.contractIDPreimage.address!),
                  wasmId,
                  salt: xdr.createContract!.contractIDPreimage.salt!);
            } else if (xdr.createContract!.executable.type ==
                XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
              return DeploySACWithSourceAccountHostFunction(
                  Address.fromXdr(
                      xdr.createContract!.contractIDPreimage.address!),
                  salt: xdr.createContract!.contractIDPreimage.salt!);
            }
          } else if (xdr.createContract!.contractIDPreimage.type ==
                  XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET &&
              xdr.createContract!.executable.type ==
                  XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
            return DeploySACWithAssetHostFunction(Asset.fromXdr(
                xdr.createContract!.contractIDPreimage.fromAsset!));
          }
        }
        break;
      case XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2:
        if (xdr.createContractV2 != null) {
          if (xdr.createContractV2!.contractIDPreimage.type ==
              XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS) {
            if (xdr.createContractV2!.executable.type ==
                XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM &&
                xdr.createContractV2!.executable.wasmHash != null) {
              String wasmId = Util.bytesToHex(
                  xdr.createContractV2!.executable.wasmHash!.hash);
              return CreateContractWithConstructorHostFunction(
                  Address.fromXdr(
                      xdr.createContractV2!.contractIDPreimage.address!),
                  wasmId, xdr.createContractV2!.constructorArgs,
                  salt: xdr.createContractV2!.contractIDPreimage.salt!);
            } else if (xdr.createContractV2!.executable.type ==
                XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
              return DeploySACWithSourceAccountHostFunction(
                  Address.fromXdr(
                      xdr.createContractV2!.contractIDPreimage.address!),
                  salt: xdr.createContractV2!.contractIDPreimage.salt!);
            }
          } else if (xdr.createContractV2!.contractIDPreimage.type ==
              XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET &&
              xdr.createContractV2!.executable.type ==
                  XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET) {
            return DeploySACWithAssetHostFunction(Asset.fromXdr(
                xdr.createContractV2!.contractIDPreimage.fromAsset!));
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

  UploadContractWasmHostFunction(this._contractCode);

  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forUploadContractWasm(contractCode);
  }
}

class CreateContractHostFunction extends HostFunction {
  Address _address;
  Address get address => this._address;
  set address(Address value) => this._address = value;

  String _wasmId;
  String get wasmId => this._wasmId;
  set wasmId(String value) => this._wasmId = value;

  late XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  CreateContractHostFunction(this._address, this._wasmId, {XdrUint256? salt}) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forCreatingContract(address.toXdr(), salt, wasmId);
  }
}

class CreateContractWithConstructorHostFunction extends HostFunction {
  Address _address;
  Address get address => this._address;
  set address(Address value) => this._address = value;

  String _wasmId;
  String get wasmId => this._wasmId;
  set wasmId(String value) => this._wasmId = value;

  List<XdrSCVal> _constructorArgs;
  List<XdrSCVal> get constructorArgs => this._constructorArgs;
  set constructorArgs(List<XdrSCVal> value) => this._constructorArgs = value;

  late XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  CreateContractWithConstructorHostFunction(this._address, this._wasmId, this._constructorArgs, {XdrUint256? salt}) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forCreatingContractV2(address.toXdr(), salt, wasmId, constructorArgs);
  }
}

class DeploySACWithSourceAccountHostFunction extends HostFunction {
  Address _address;
  Address get address => this._address;
  set address(Address value) => this._address = value;

  late XdrUint256 _salt;
  XdrUint256 get salt => this._salt;
  set salt(XdrUint256 value) => this._salt = value;

  DeploySACWithSourceAccountHostFunction(this._address, {XdrUint256? salt}) {
    if (salt != null) {
      this._salt = salt;
    } else {
      this._salt = new XdrUint256(TweetNaCl.randombytes(32));
    }
  }

  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forDeploySACWithSourceAccount(address.toXdr(), salt);
  }
}

class DeploySACWithAssetHostFunction extends HostFunction {
  Asset _asset;
  Asset get asset => this._asset;
  set asset(Asset value) => this._asset = value;

  DeploySACWithAssetHostFunction(this._asset);

  @override
  XdrHostFunction toXdr() {
    return XdrHostFunction.forDeploySACWithAsset(asset.toXdr());
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
      {this.arguments});

  @override
  XdrHostFunction toXdr() {
    List<XdrSCVal> fcArgs = List<XdrSCVal>.empty(growable: true);

    if (this.arguments != null) {
      fcArgs.addAll(this.arguments!);
    }
    XdrInvokeContractArgs args = XdrInvokeContractArgs(
        Address.forContractId(this._contractID).toXdr(),
        this._functionName,
        fcArgs);
    return XdrHostFunction.forInvokingContractWithArgs(args);
  }
}

class InvokeHostFuncOpBuilder {
  MuxedAccount? _mSourceAccount;

  HostFunction _function;
  HostFunction get function => this._function;
  set function(HostFunction value) => this._function = value;

  List<SorobanAuthorizationEntry> auth =
      List<SorobanAuthorizationEntry>.empty(growable: true);

  InvokeHostFuncOpBuilder(this._function,
      {List<SorobanAuthorizationEntry>? auth}) {
    if (auth != null) {
      this.auth = auth;
    }
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

  ///Builds an operation
  InvokeHostFunctionOperation build() {
    InvokeHostFunctionOperation op =
        InvokeHostFunctionOperation(function, auth: auth);
    op.sourceAccount = _mSourceAccount;
    return op;
  }
}

class InvokeHostFunctionOperation extends Operation {
  HostFunction _function;
  HostFunction get function => this._function;
  set function(HostFunction value) => this._function = value;

  List<SorobanAuthorizationEntry> auth =
      List<SorobanAuthorizationEntry>.empty(growable: true);

  InvokeHostFunctionOperation(this._function,
      {List<SorobanAuthorizationEntry>? auth}) {
    if (auth != null) {
      this.auth = auth;
    }
  }

  static InvokeHostFuncOpBuilder builder(XdrInvokeHostFunctionOp op) {
    List<SorobanAuthorizationEntry> auth =
        List<SorobanAuthorizationEntry>.empty(growable: true);
    for (XdrSorobanAuthorizationEntry aXdr in op.auth) {
      auth.add(SorobanAuthorizationEntry.fromXdr(aXdr));
    }
    return InvokeHostFuncOpBuilder(HostFunction.fromXdr(op.function),
        auth: auth);
  }

  @override
  XdrOperationBody toOperationBody() {
    List<XdrSorobanAuthorizationEntry> xdrAuth =
        List<XdrSorobanAuthorizationEntry>.empty(growable: true);
    for (SorobanAuthorizationEntry a in auth) {
      xdrAuth.add(a.toXdr());
    }
    XdrInvokeHostFunctionOp xdrOp =
        XdrInvokeHostFunctionOp(function.toXdr(), xdrAuth);
    XdrOperationBody body =
        XdrOperationBody(XdrOperationType.INVOKE_HOST_FUNCTION);
    body.invokeHostFunctionOp = xdrOp;
    return body;
  }
}
