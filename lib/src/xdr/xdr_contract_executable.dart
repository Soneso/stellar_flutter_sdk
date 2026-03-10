// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'xdr_contract_executable_base.dart';
import 'xdr_contract_executable_type.dart';
import 'xdr_data_io.dart';
import 'xdr_hash.dart';

class XdrContractExecutable extends XdrContractExecutableBase {
  XdrContractExecutable(super.type);

  static void encode(XdrDataOutputStream stream, XdrContractExecutable val) {
    XdrContractExecutableBase.encode(stream, val);
  }

  static XdrContractExecutable decode(XdrDataInputStream stream) {
    return XdrContractExecutableBase.decodeAs(
      stream,
      XdrContractExecutable.new,
    );
  }

  static XdrContractExecutable forWasm(Uint8List wasmHash) {
    var result = XdrContractExecutable(
      XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM,
    );
    result.wasmHash = XdrHash(wasmHash);
    return result;
  }

  static XdrContractExecutable forAsset() {
    return XdrContractExecutable(
      XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET,
    );
  }
}
