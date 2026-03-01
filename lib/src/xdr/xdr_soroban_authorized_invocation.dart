// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_authorized_function.dart';

class XdrSorobanAuthorizedInvocation {
  XdrSorobanAuthorizedFunction _function;
  XdrSorobanAuthorizedFunction get function => this._function;
  set function(XdrSorobanAuthorizedFunction value) => this._function = value;

  List<XdrSorobanAuthorizedInvocation> _subInvocations;
  List<XdrSorobanAuthorizedInvocation> get subInvocations =>
      this._subInvocations;
  set subInvocations(List<XdrSorobanAuthorizedInvocation> value) =>
      this._subInvocations = value;

  XdrSorobanAuthorizedInvocation(this._function, this._subInvocations);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanAuthorizedInvocation encoded) {
    XdrSorobanAuthorizedFunction.encode(stream, encoded.function);
    int subSize = encoded.subInvocations.length;
    stream.writeInt(subSize);
    for (int i = 0; i < subSize; i++) {
      XdrSorobanAuthorizedInvocation.encode(stream, encoded.subInvocations[i]);
    }
  }

  static XdrSorobanAuthorizedInvocation decode(XdrDataInputStream stream) {
    XdrSorobanAuthorizedFunction function =
        XdrSorobanAuthorizedFunction.decode(stream);

    int subSize = stream.readInt();
    List<XdrSorobanAuthorizedInvocation> subs =
        List<XdrSorobanAuthorizedInvocation>.empty(growable: true);
    for (int i = 0; i < subSize; i++) {
      subs.add(XdrSorobanAuthorizedInvocation.decode(stream));
    }
    return XdrSorobanAuthorizedInvocation(function, subs);
  }
}
