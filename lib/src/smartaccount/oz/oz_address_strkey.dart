// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../key_pair.dart';
import '../../soroban/soroban_auth.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';

/// Internal helpers for translating Soroban [XdrSCAddress] values into
/// canonical Stellar StrKey strings.
///
/// The OZ smart-account managers need to compare auth-entry addresses
/// against user-supplied wallet G-addresses (`G…`) and contract
/// C-addresses (`C…`). The Flutter SDK's [Address.fromXdr] returns a
/// hex string for contracts (which sometimes already comes back as a
/// StrKey when the source was a StrKey-encoded value) and an account
/// id (`G…`) for accounts. This helper unifies both shapes into the
/// canonical StrKey form so downstream comparisons can use plain string
/// equality.
@internal
abstract final class OZAddressStrKey {
  /// Returns the canonical StrKey representation of [addressXdr], or
  /// `null` when the XDR carries neither an account ID nor a contract
  /// ID (defensive against malformed payloads). Contract IDs already in
  /// StrKey form pass through unchanged; raw hex contract IDs are
  /// re-encoded through [StrKey.encodeContractId].
  static String? fromXdr(XdrSCAddress addressXdr) {
    try {
      final addr = Address.fromXdr(addressXdr);
      final contractHex = addr.contractId;
      if (contractHex != null) {
        if (contractHex.startsWith('C')) return contractHex;
        return StrKey.encodeContractId(
          Util.hexToBytes(contractHex.toUpperCase()),
        );
      }
      final accountId = addr.accountId;
      if (accountId != null) return accountId;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Like [fromXdr] but returns the empty string in place of `null`.
  /// Matches the previous inlined fall-through behaviour in the
  /// context-rule parser where a missing address produced `''` rather
  /// than a sentinel — kept as a separate entry point to make the
  /// substitution at call sites a strict no-op.
  static String fromXdrOrEmpty(XdrSCAddress addressXdr) {
    return fromXdr(addressXdr) ?? '';
  }
}
