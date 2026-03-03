// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_int64.dart';

class XdrContractCostParamEntry {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrInt64 _constTerm;
  XdrInt64 get constTerm => this._constTerm;
  set constTerm(XdrInt64 value) => this._constTerm = value;

  XdrInt64 _linearTerm;
  XdrInt64 get linearTerm => this._linearTerm;
  set linearTerm(XdrInt64 value) => this._linearTerm = value;

  XdrContractCostParamEntry(this._ext, this._constTerm, this._linearTerm);

  static void encode(
    XdrDataOutputStream stream,
    XdrContractCostParamEntry encodedContractCostParamEntry,
  ) {
    XdrExtensionPoint.encode(stream, encodedContractCostParamEntry.ext);
    XdrInt64.encode(stream, encodedContractCostParamEntry.constTerm);
    XdrInt64.encode(stream, encodedContractCostParamEntry.linearTerm);
  }

  static XdrContractCostParamEntry decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrInt64 constTerm = XdrInt64.decode(stream);
    XdrInt64 linearTerm = XdrInt64.decode(stream);
    return XdrContractCostParamEntry(ext, constTerm, linearTerm);
  }
}
