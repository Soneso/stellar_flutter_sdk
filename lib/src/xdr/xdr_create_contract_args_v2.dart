// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_executable.dart';
import 'xdr_contract_id_preimage.dart';
import 'xdr_data_io.dart';
import 'xdr_sc_val.dart';

class XdrCreateContractArgsV2 {
  XdrContractIDPreimage _contractIDPreimage;
  XdrContractIDPreimage get contractIDPreimage => this._contractIDPreimage;
  set contractIDPreimage(XdrContractIDPreimage value) =>
      this._contractIDPreimage = value;

  XdrContractExecutable _executable;
  XdrContractExecutable get executable => this._executable;
  set executable(XdrContractExecutable value) => this._executable = value;

  List<XdrSCVal> _constructorArgs;
  List<XdrSCVal> get constructorArgs => this._constructorArgs;
  set constructorArgs(List<XdrSCVal> value) => this._constructorArgs = value;

  XdrCreateContractArgsV2(
    this._contractIDPreimage,
    this._executable,
    this._constructorArgs,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrCreateContractArgsV2 encoded,
  ) {
    XdrContractIDPreimage.encode(stream, encoded.contractIDPreimage);
    XdrContractExecutable.encode(stream, encoded.executable);
    int argsSize = encoded.constructorArgs.length;
    stream.writeInt(argsSize);
    for (int i = 0; i < argsSize; i++) {
      XdrSCVal.encode(stream, encoded.constructorArgs[i]);
    }
  }

  static XdrCreateContractArgsV2 decode(XdrDataInputStream stream) {
    var preimage = XdrContractIDPreimage.decode(stream);
    var exec = XdrContractExecutable.decode(stream);
    int constructorArgsSize = stream.readInt();
    List<XdrSCVal> constructorArgs = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < constructorArgsSize; i++) {
      constructorArgs.add(XdrSCVal.decode(stream));
    }

    return XdrCreateContractArgsV2(preimage, exec, constructorArgs);
  }
}
