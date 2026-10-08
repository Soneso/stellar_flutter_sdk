// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'key_pair.dart';
import 'soroban/soroban_auth.dart';
import 'xdr/xdr.dart';

/// A contract paired with a 64-bit multiplexing id.
///
/// The pair renders as a muxed contract address, a W strkey whose payload is
/// the 32-byte contract hash followed by the big-endian id. Instances are
/// immutable; every constructor holds the id to the unsigned 64-bit range.
///
/// Protocol specification:
/// - [CAP-84](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0084.md)
///
/// Example:
/// ```dart
/// MuxedContract muxed = MuxedContract(
///     'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
///     BigInt.from(123456));
/// print(muxed.muxedContractId);
/// // WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG
///
/// MuxedContract parsed =
///     MuxedContract.fromMuxedContractId(muxed.muxedContractId);
/// print(parsed.contractId); // CA3D5KRY...
/// print(parsed.id); // 123456
/// ```
class MuxedContract {
  /// The contract strkey (C...).
  final String contractId;

  /// The multiplexing id, an unsigned 64-bit value.
  final BigInt id;

  /// Pairs [contractId], given as a contract strkey (C...) or as the hex of
  /// its 32 byte hash, with the multiplexing [id].
  ///
  /// Throws [ArgumentError] if [contractId] is neither form or [id] is
  /// outside the unsigned 64-bit range.
  factory MuxedContract(String contractId, BigInt id) {
    final XdrHash contractHash;
    try {
      contractHash = XdrSCAddress.forContractId(contractId).contractId!;
    } on FormatException catch (e) {
      throw ArgumentError.value(contractId, 'contractId', e.message);
    }
    return MuxedContract._(contractHash.hash, id);
  }

  MuxedContract._(Uint8List contractHash, this.id)
      : contractId = StrKey.encodeContractId(contractHash) {
    if (id.isNegative || id.bitLength > 64) {
      throw ArgumentError.value(id, 'id', 'must be an unsigned 64-bit value');
    }
  }

  /// Decodes the muxed contract address [muxedContractId] (W...).
  ///
  /// Throws [FormatException] if [muxedContractId] is not a valid muxed
  /// contract strkey.
  static MuxedContract fromMuxedContractId(String muxedContractId) =>
      fromXdr(XdrMuxedContract.forMuxedContractId(muxedContractId));

  /// Reads the pair from its XDR form.
  ///
  /// Throws [ArgumentError] if the id is outside the unsigned 64-bit range.
  static MuxedContract fromXdr(XdrMuxedContract xdr) =>
      MuxedContract._(xdr.contractId.hash, xdr.id.uint64);

  /// The muxed contract address (W...).
  String get muxedContractId => toXdr().muxedContractId;

  /// Converts the pair to its XDR form.
  XdrMuxedContract toXdr() => XdrMuxedContract(
      XdrUint64(id), XdrHash(StrKey.decodeContractId(contractId)));

  /// Returns the [Address] of type [Address.TYPE_MUXED_CONTRACT] for this
  /// pair.
  Address toAddress() => Address.forMuxedContractId(muxedContractId);
}
