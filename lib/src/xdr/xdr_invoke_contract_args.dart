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
    XdrInvokeContractArgs encodedInvokeContractArgs,
  ) {
    XdrSCAddress.encode(stream, encodedInvokeContractArgs.contractAddress);
    stream.writeString(encodedInvokeContractArgs.functionName);
    int argssize = encodedInvokeContractArgs.args.length;
    stream.writeInt(argssize);
    for (int i = 0; i < argssize; i++) {
      XdrSCVal.encode(stream, encodedInvokeContractArgs.args[i]);
    }
  }

  static XdrInvokeContractArgs decode(XdrDataInputStream stream) {
    XdrSCAddress contractAddress = XdrSCAddress.decode(stream);
    String functionName = stream.readString();
    int argssize = stream.readInt();
    List<XdrSCVal> args = List<XdrSCVal>.empty(growable: true);
    for (int i = 0; i < argssize; i++) {
      args.add(XdrSCVal.decode(stream));
    }
    return XdrInvokeContractArgs(contractAddress, functionName, args);
  }
}
