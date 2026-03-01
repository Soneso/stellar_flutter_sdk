// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_address.dart';
import 'xdr_sc_val.dart';

class XdrInvokeContractArgs {
  XdrSCAddress _contractAddress;
  XdrSCAddress get contractAddress => this._contractAddress;
  set contractAddress(XdrSCAddress value) => this._contractAddress = value;

  String _functionName;
  String get functionName => this._functionName;
  set functionName(String value) => this._functionName = value;

  List<XdrSCVal> _args;
  List<XdrSCVal> get args => this._args;
  set args(List<XdrSCVal> value) => this._args = value;

  XdrInvokeContractArgs(this._contractAddress, this._functionName, this._args);

  static void encode(
    XdrDataOutputStream stream,
    XdrInvokeContractArgs encoded,
  ) {
    XdrSCAddress.encode(stream, encoded.contractAddress);
    stream.writeString(encoded.functionName);
    int argsSize = encoded.args.length;
    stream.writeInt(argsSize);
    for (int i = 0; i < argsSize; i++) {
      XdrSCVal.encode(stream, encoded.args[i]);
    }
  }

  static XdrInvokeContractArgs decode(XdrDataInputStream stream) {
    XdrSCAddress cAddress = XdrSCAddress.decode(stream);
    String fName = stream.readString();
    int argsSize = stream.readInt();
    List<XdrSCVal> args = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < argsSize; i++) {
      args.add(XdrSCVal.decode(stream));
    }

    return XdrInvokeContractArgs(cAddress, fName, args);
  }
}
