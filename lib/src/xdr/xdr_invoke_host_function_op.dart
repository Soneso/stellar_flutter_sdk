// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_host_function.dart';
import 'xdr_soroban_authorization_entry.dart';

class XdrInvokeHostFunctionOp {
  XdrHostFunction _function;
  XdrHostFunction get function => this._function;
  set function(XdrHostFunction value) => this._function = value;

  List<XdrSorobanAuthorizationEntry> _auth;
  List<XdrSorobanAuthorizationEntry> get auth => this._auth;
  set auth(List<XdrSorobanAuthorizationEntry> value) => this._auth = value;

  XdrInvokeHostFunctionOp(this._function, this._auth);

  static void encode(
      XdrDataOutputStream stream, XdrInvokeHostFunctionOp encoded) {
    XdrHostFunction.encode(stream, encoded.function);
    int authSize = encoded.auth.length;
    stream.writeInt(authSize);
    for (int i = 0; i < authSize; i++) {
      XdrSorobanAuthorizationEntry.encode(stream, encoded.auth[i]);
    }
  }

  static XdrInvokeHostFunctionOp decode(XdrDataInputStream stream) {
    XdrHostFunction function = XdrHostFunction.decode(stream);
    int authSize = stream.readInt();
    List<XdrSorobanAuthorizationEntry> auth =
        List<XdrSorobanAuthorizationEntry>.empty(growable: true);
    for (int i = 0; i < authSize; i++) {
      auth.add(XdrSorobanAuthorizationEntry.decode(stream));
    }
    return XdrInvokeHostFunctionOp(function, auth);
  }
}
