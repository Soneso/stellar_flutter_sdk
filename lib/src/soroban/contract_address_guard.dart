// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../asset_type_credit_alphanum.dart';
import '../assets.dart';
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
  final display = secretSeedLikeKind(address) ?? redactSecretSeeds(address);
  if (display != address) {
    throw ArgumentError(
      '$subject must be a contract (C...) address, got $display '
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
        '$display$hint',
      );
    }
  }
  throw ArgumentError('$subject must be a contract (C...) address: $display');
}

/// The wording a message uses in place of a valid secret seed.
const String _secretSeed = 'a secret seed (S...)';

/// The wording a message uses in place of any other value that starts with
/// `S` or `s`.
const String _seedLikeValue =
    'a value starting with S (not shown, it may be a secret seed)';

/// The shortest run of letters and digits [redactSecretSeeds] replaces; a
/// secret seed has 56 characters, so a seed with a few characters missing
/// is still replaced.
const int _seedLikeRunMinLength = 40;

/// Returns the wording that stands for [value] in a message when [value],
/// trimmed, starts with `S` or `s`, the first letter of a secret seed, and
/// `null` otherwise.
///
/// A valid secret seed in either letter case is named `a secret seed (S...)`;
/// any other such value is named without being shown. No account id,
/// contract id, muxed address, pool id, claimable balance id or other strkey
/// of a valid kind starts with this letter, so a valid input never matches.
String? secretSeedLikeKind(String value) {
  final String trimmed = value.trim();
  if (!trimmed.startsWith('S') && !trimmed.startsWith('s')) {
    return null;
  }
  return StrKey.isValidStellarSecretSeed(trimmed.toUpperCase())
      ? _secretSeed
      : _seedLikeValue;
}

/// Returns [value], an input meant as an address, an account id, another
/// strkey or an id, the way a message shows it: the value itself, or the
/// wording of [secretSeedLikeKind] when it starts with `S` or `s`.
String keyForMessage(String value) => secretSeedLikeKind(value) ?? value;

/// The length of a secret seed strkey.
const int _secretSeedLength = 56;

/// Matches, without consuming it, each position where `S` and 55 more
/// base32 characters start, in any letter case, overlapping candidates
/// included.
final RegExp _secretSeedCandidate = RegExp(
  r'(?=S[A-Z2-7]{55})',
  caseSensitive: false,
);

/// Replaces secret seeds in diagnostic [text] with `a secret seed (S...)`.
///
/// Each maximal run of ASCII letters and digits that starts with `S` or `s`
/// and has at least 40 characters is replaced, so a secret seed is left out
/// even with a changed, missing or added character. In addition each valid
/// secret seed in any letter case is replaced wherever it stands, also
/// inside a longer run, such as a seed glued to a preceding letter or digit.
String redactSecretSeeds(String text) {
  final String runsReplaced = text.replaceAllMapped(RegExp(r'[A-Za-z0-9]+'), (
    match,
  ) {
    final String run = match[0]!;
    return run.length >= _seedLikeRunMinLength &&
            (run.startsWith('S') || run.startsWith('s'))
        ? _secretSeed
        : run;
  });
  final StringBuffer result = StringBuffer();
  int copied = 0;
  for (final Match candidate in _secretSeedCandidate.allMatches(runsReplaced)) {
    final int start = candidate.start;
    final int end = start + _secretSeedLength;
    if (start >= copied &&
        StrKey.isValidStellarSecretSeed(
          runsReplaced.substring(start, end).toUpperCase(),
        )) {
      result
        ..write(runsReplaced.substring(copied, start))
        ..write(_secretSeed);
      copied = end;
    }
  }
  result.write(runsReplaced.substring(copied));
  return result.toString();
}

/// Returns `parse(value)`; a [FormatException] it throws for a [value] that
/// starts with `S` or `s` is rethrown with the wording of
/// [secretSeedLikeKind] as its source, so the exception does not carry the
/// value.
T parseHidingSecretSeed<T>(String value, T Function(String value) parse) =>
    _parseWithSafeSource(value, parse, secretSeedLikeKind);

/// Returns `parse(value)`; a [FormatException] it throws for a [value] in
/// which [redactSecretSeeds] replaces something is rethrown with the
/// redacted value as its source, for a value that may be free text.
T parseRedactingSecretSeeds<T>(String value, T Function(String value) parse) =>
    _parseWithSafeSource(value, parse, (String value) {
      final String redacted = redactSecretSeeds(value);
      return redacted == value ? null : redacted;
    });

/// Returns `parse(value)`. A [FormatException] it throws is rethrown
/// unchanged when [safeSource] returns `null` for [value], and otherwise as a
/// [FormatException] with the same message and the returned text as its
/// source, without the offset into the value, and the original stack trace.
T _parseWithSafeSource<T>(
  String value,
  T Function(String value) parse,
  String? Function(String value) safeSource,
) {
  try {
    return parse(value);
  } on FormatException catch (e, stackTrace) {
    final String? source = safeSource(value);
    if (source == null) {
      rethrow;
    }
    Error.throwWithStackTrace(FormatException(e.message, source), stackTrace);
  }
}

/// Throws an [ArgumentError] for the parameter [name] when [value] starts
/// with `S` or `s`, before the value is put into a Horizon request; the
/// error names the kind of value without showing it.
void checkNotSecretSeed(String value, String name) {
  final String? kind = secretSeedLikeKind(value);
  if (kind != null) {
    throw ArgumentError('got $kind, which is not sent to Horizon', name);
  }
}

/// Throws the [ArgumentError] of [checkNotSecretSeed] for the issuer of
/// [asset], reported as `name.issuerId`, when [asset] is a credit asset.
void checkAssetIssuerNotSecretSeed(Asset asset, String name) {
  if (asset is AssetTypeCreditAlphaNum) {
    checkNotSecretSeed(asset.issuerId, '$name.issuerId');
  }
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
