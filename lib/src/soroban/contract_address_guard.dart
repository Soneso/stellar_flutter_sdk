// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../constants/stellar_protocol_constants.dart';
import '../key_pair.dart';
import '../util.dart';
import '../xdr/xdr.dart';

/// Throws an [ArgumentError] led by [subject] unless [address] is a contract
/// (C...) strkey or the 64-character hex of a contract id; the message names
/// the kind of address given and never repeats a secret seed.
void checkContractAddress(String address, String subject) {
  if (StrKey.isValidContractId(address) ||
      (address.length == StellarProtocolConstants.HEX_STRING_256BIT_LENGTH &&
          isHexString(address))) {
    return;
  }
  if (StrKey.isValidStellarSecretSeed(address)) {
    throw ArgumentError(
      '$subject must be a contract (C...) address, got a secret seed (S...) '
      'instead of an address',
    );
  }
  for (final (isKind, kind) in _kinds) {
    if (isKind(address)) {
      final hint = kind == _muxedContract
          ? '; use its base contract (C...) address'
          : '';
      throw ArgumentError(
        '$subject must be a contract (C...) address, got $kind address: '
        '$address$hint',
      );
    }
  }
  throw ArgumentError('$subject must be a contract (C...) address: $address');
}

/// Throws the rejection [checkContractAddress] gives a contract data owner
/// as a [FormatException], the type the contract id codec throws for a
/// malformed id, for callers whose error handling rests on that type.
void checkContractDataOwnerAsFormat(String address) {
  try {
    checkContractAddress(address, 'The contract data owner');
  } on ArgumentError catch (e) {
    throw FormatException('${e.message}');
  }
}

const String _muxedContract = 'a muxed contract (W...)';

/// The strkey kinds other than a contract, each with its article.
const List<(bool Function(String), String)> _kinds = [
  (StrKey.isValidStellarAccountId, 'an account (G...)'),
  (StrKey.isValidStellarMuxedAccountId, 'a muxed account (M...)'),
  (StrKey.isValidMuxedContractId, _muxedContract),
  (StrKey.isValidClaimableBalanceId, 'a claimable balance (B...)'),
  (StrKey.isValidLiquidityPoolId, 'a liquidity pool (L...)'),
];

/// Throws an [ArgumentError] when the contract data [key] holds a muxed
/// account or muxed contract address as itself, a `Vec` element or a `Map`
/// key or value, at any depth; the host refuses both in storage keys.
void checkContractDataKey(XdrSCVal key) {
  final XdrSCAddressType? addressType = key.address?.discriminant;
  if (key.discriminant == XdrSCValType.SCV_ADDRESS &&
      (addressType == XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT ||
          addressType == XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_CONTRACT)) {
    throw ArgumentError(
      'Contract data keys cannot contain muxed account (M...) or muxed '
      'contract (W...) addresses',
    );
  }
  if (key.discriminant == XdrSCValType.SCV_VEC) {
    key.vec?.forEach(checkContractDataKey);
  }
  if (key.discriminant == XdrSCValType.SCV_MAP) {
    for (final XdrSCMapEntry entry in key.map ?? const <XdrSCMapEntry>[]) {
      checkContractDataKey(entry.key);
      checkContractDataKey(entry.val);
    }
  }
}
