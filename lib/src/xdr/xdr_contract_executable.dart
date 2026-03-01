// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_contract_executable_type.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrContractExecutable {
  XdrContractExecutable(this._type);
  XdrContractExecutableType _type;
  XdrContractExecutableType get type => this._type;
  set type(XdrContractExecutableType value) => this._type = value;

  XdrHash? _wasmHash;
  XdrHash? get wasmHash => this._wasmHash;
  set wasmHash(XdrHash? value) => this._wasmHash = value;

  static void encode(
      XdrDataOutputStream stream, XdrContractExecutable encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM:
        XdrHash.encode(stream, encoded.wasmHash!);
        break;
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET:
        break;
    }
  }

  static XdrContractExecutable decode(XdrDataInputStream stream) {
    XdrContractExecutable decoded =
        XdrContractExecutable(XdrContractExecutableType.decode(stream));
    switch (decoded.type) {
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM:
        decoded.wasmHash = XdrHash.decode(stream);
        break;
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET:
        break;
    }
    return decoded;
  }

  static XdrContractExecutable forWasm(Uint8List wasmHash) {
    var result = XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
    result.wasmHash = XdrHash(wasmHash);
    return result;
  }

  static XdrContractExecutable forAsset() {
    return XdrContractExecutable(
        XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);
  }
}
