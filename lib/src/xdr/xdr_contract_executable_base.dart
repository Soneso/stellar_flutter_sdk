// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_executable_type.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrContractExecutableBase {
  XdrContractExecutableBase(this._type);
  XdrContractExecutableType _type;
  XdrContractExecutableType get type => this._type;
  set type(XdrContractExecutableType value) => this._type = value;

  XdrHash? _wasmHash;
  XdrHash? get wasmHash => this._wasmHash;
  set wasmHash(XdrHash? value) => this._wasmHash = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrContractExecutableBase encoded,
  ) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM:
        XdrHash.encode(stream, encoded.wasmHash!);
        break;
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET:
        break;
    }
  }

  static XdrContractExecutableBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrContractExecutableBase.new);
  }

  static T decodeAs<T extends XdrContractExecutableBase>(
    XdrDataInputStream stream,
    T Function(XdrContractExecutableType) constructor,
  ) {
    T decoded = constructor(XdrContractExecutableType.decode(stream));
    switch (decoded.type) {
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM:
        decoded.wasmHash = XdrHash.decode(stream);
        break;
      case XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET:
        break;
    }
    return decoded;
  }
}
