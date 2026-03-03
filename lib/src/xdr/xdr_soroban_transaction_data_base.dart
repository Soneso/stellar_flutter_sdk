// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_soroban_resources.dart';
import 'xdr_soroban_transaction_data_ext.dart';

class XdrSorobanTransactionDataBase {

  XdrSorobanTransactionDataExt _ext;
  XdrSorobanTransactionDataExt get ext => this._ext;
  set ext(XdrSorobanTransactionDataExt value) => this._ext = value;

  XdrSorobanResources _resources;
  XdrSorobanResources get resources => this._resources;
  set resources(XdrSorobanResources value) => this._resources = value;

  XdrInt64 _resourceFee;
  XdrInt64 get resourceFee => this._resourceFee;
  set resourceFee(XdrInt64 value) => this._resourceFee = value;

  XdrSorobanTransactionDataBase(this._ext, this._resources, this._resourceFee);

  static void encode(XdrDataOutputStream stream, XdrSorobanTransactionDataBase encodedSorobanTransactionData) {
    XdrSorobanTransactionDataExt.encode(stream, encodedSorobanTransactionData.ext);
    XdrSorobanResources.encode(stream, encodedSorobanTransactionData.resources);
    XdrInt64.encode(stream, encodedSorobanTransactionData.resourceFee);
  }

  static XdrSorobanTransactionDataBase decode(XdrDataInputStream stream) {
    XdrSorobanTransactionDataExt ext = XdrSorobanTransactionDataExt.decode(stream);
    XdrSorobanResources resources = XdrSorobanResources.decode(stream);
    XdrInt64 resourceFee = XdrInt64.decode(stream);
    return XdrSorobanTransactionDataBase(ext, resources, resourceFee);
  }
}
