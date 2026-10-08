// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';

import 'xdr_data_io.dart';
import 'xdr_hash.dart';
import 'xdr_json_helper.dart';
import 'xdr_muxed_contract_base.dart';
import 'xdr_uint64.dart';

/// A contract paired with a 64-bit multiplexing [id] (CAP-0084).
///
/// Its strkey rendering is the W strkey [muxedContractId], whose payload is
/// the 32-byte contract hash followed by the big-endian [id].
class XdrMuxedContract extends XdrMuxedContractBase {
  XdrMuxedContract(super.id, super.contractId);

  static void encode(XdrDataOutputStream stream, XdrMuxedContract val) {
    XdrMuxedContractBase.encode(stream, val);
  }

  static XdrMuxedContract decode(XdrDataInputStream stream) {
    var b = XdrMuxedContractBase.decode(stream);
    return XdrMuxedContract(b.id, b.contractId);
  }

  static XdrMuxedContract fromBase64EncodedXdrString(String base64Encoded) =>
      decode(XdrDataInputStream(base64Decode(base64Encoded)));

  static XdrMuxedContract fromTxRep(Map<String, String> map, String prefix) {
    var b = XdrMuxedContractBase.fromTxRep(map, prefix);
    return XdrMuxedContract(b.id, b.contractId);
  }

  /// Parses the SEP-0051 XDR-JSON rendering of a XdrMuxedContract.
  static XdrMuxedContract fromXdrJson(String json) => fromXdrJsonValue(
    XdrJsonHelper.decodeDocument(json, type: 'XdrMuxedContract'),
  );

  /// Reads a XdrMuxedContract from its SEP-0051 rendering.
  static XdrMuxedContract fromXdrJsonValue(Object? value) {
    var b = XdrMuxedContractBase.fromXdrJsonValue(value);
    return XdrMuxedContract(b.id, b.contractId);
  }

  /// Builds a muxed contract from its strkey rendering [muxedContractId]
  /// (W...).
  ///
  /// Throws:
  /// - [FormatException]: if [muxedContractId] is not a valid muxed contract
  ///   strkey
  static XdrMuxedContract forMuxedContractId(String muxedContractId) {
    final XdrDataInputStream stream = XdrDataInputStream(
      StrKey.decodeMuxedContractId(muxedContractId),
    );
    final XdrHash contractId = XdrHash.decode(stream);
    return XdrMuxedContract(XdrUint64.decode(stream), contractId);
  }

  /// The strkey rendering of this muxed contract (W...).
  String get muxedContractId {
    final XdrDataOutputStream stream = XdrDataOutputStream();
    XdrHash.encode(stream, contractId);
    XdrUint64.encode(stream, id);
    return StrKey.encodeMuxedContractId(Uint8List.fromList(stream.bytes));
  }
}
