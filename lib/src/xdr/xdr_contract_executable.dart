// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_contract_executable_base.dart';
import 'xdr_contract_executable_external_ref.dart';
import 'xdr_contract_executable_type.dart';
import 'xdr_data_io.dart';
import 'xdr_json_helper.dart';
import 'xdr_hash.dart';
import 'xdr_sc_address.dart';

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

  static XdrContractExecutable fromTxRep(
    Map<String, String> map,
    String prefix,
  ) {
    var b = XdrContractExecutableBase.fromTxRep(map, prefix);
    var result = XdrContractExecutable(b.discriminant);
    result.wasmHash = b.wasmHash;
    result.externalRef = b.externalRef;
    return result;
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

  /// Builds an external reference executable over the raw bytes of [tag].
  ///
  /// An executable tag is an XDR string, which carries arbitrary bytes.
  static XdrContractExecutable forExternalRefBytes(
    XdrSCAddress executableOwner,
    Uint8List tag,
  ) {
    var result = XdrContractExecutable(
      XdrContractExecutableType.CONTRACT_EXECUTABLE_EXTERNAL_REF,
    );
    result.externalRef = XdrContractExecutableExternalRef(executableOwner, tag);
    return result;
  }

  /// Builds an external reference executable over the UTF-8 encoding of [tag].
  static XdrContractExecutable forExternalRef(
    XdrSCAddress executableOwner,
    String tag,
  ) {
    return forExternalRefBytes(
      executableOwner,
      Uint8List.fromList(utf8.encode(tag)),
    );
  }

  /// Parses the SEP-0051 XDR-JSON rendering of a XdrContractExecutable.
  ///
  /// Dart does not inherit statics, so this narrows the base class rendering to
  /// this type rather than relying on the one the base declares.
  static XdrContractExecutable fromXdrJson(String json) => fromXdrJsonValue(
    XdrJsonHelper.decodeDocument(json, type: 'XdrContractExecutable'),
  );

  static XdrContractExecutable fromXdrJsonValue(Object? value) =>
      XdrContractExecutableBase.fromXdrJsonValueAs(
        value,
        XdrContractExecutable.new,
      );
}
