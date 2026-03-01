// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'xdr_data_io.dart';
import 'xdr_int64.dart';
import 'xdr_soroban_resources.dart';
import 'xdr_soroban_transaction_data_ext.dart';

class XdrSorobanTransactionData {
  XdrSorobanTransactionDataExt _ext;
  XdrSorobanTransactionDataExt get ext => this._ext;
  set ext(XdrSorobanTransactionDataExt value) => this._ext = value;

  XdrSorobanResources _resources;
  XdrSorobanResources get resources => this._resources;
  set resources(XdrSorobanResources value) => this._resources = value;

  // Amount of the transaction `fee` allocated to the Soroban resource fees.
  // The fraction of `resourceFee` corresponding to `resources` specified
  // above is *not* refundable (i.e. fees for instructions, ledger I/O), as
  // well as fees for the transaction size.
  // The remaining part of the fee is refundable and the charged value is
  // based on the actual consumption of refundable resources (events, ledger
  // rent bumps).
  // The `inclusionFee` used for prioritization of the transaction is defined
  // as `tx.fee - resourceFee`.
  XdrInt64 _resourceFee;
  XdrInt64 get resourceFee => this._resourceFee;
  set resourceFee(XdrInt64 value) => this._resourceFee = value;

  XdrSorobanTransactionData(this._ext, this._resources, this._resourceFee);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanTransactionData encoded) {
    XdrSorobanTransactionDataExt.encode(stream, encoded.ext);
    XdrSorobanResources.encode(stream, encoded.resources);
    XdrInt64.encode(stream, encoded.resourceFee);
  }

  static XdrSorobanTransactionData decode(XdrDataInputStream stream) {
    final ext = XdrSorobanTransactionDataExt.decode(stream);
    final resources = XdrSorobanResources.decode(stream);
    final resourceFee = XdrInt64.decode(stream);
    return XdrSorobanTransactionData(ext, resources, resourceFee);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrSorobanTransactionData.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrSorobanTransactionData fromBase64EncodedXdrString(
      String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrSorobanTransactionData.decode(XdrDataInputStream(bytes));
  }
}
