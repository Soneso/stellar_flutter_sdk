// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_account.dart';
import 'key_pair.dart';

/// Represents an account that can claim a claimable balance with conditions.
///
/// A Claimant specifies who can claim a claimable balance and under what conditions
/// using claim predicates. Predicates can be simple (unconditional) or complex
/// (time-based, logical combinations). This is part of the claimable balances
/// feature introduced in Protocol 14 via CAP-23.
///
/// Claim Predicate Types:
/// - **Unconditional**: Can be claimed immediately
/// - **Time-based**: Can be claimed before/after a specific time
/// - **Logical**: Combinations using AND, OR, NOT operations
///
/// Example - Simple Unconditional Claimant:
/// ```dart
/// var claimant = Claimant(
///   recipientAccountId,
///   Claimant.predicateUnconditional()
/// );
/// ```
///
/// Example - Time-based Claimant:
/// ```dart
/// // Can only claim after January 1, 2026
/// var futureTime = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
/// var claimant = Claimant(
///   recipientAccountId,
///   Claimant.predicateNot(
///     Claimant.predicateBeforeAbsoluteTime(futureTime)
///   )
/// );
/// ```
///
/// Example - Complex Logic:
/// ```dart
/// // Can claim if (before time X) OR (after time Y)
/// var claimant = Claimant(
///   recipientAccountId,
///   Claimant.predicateOr(
///     Claimant.predicateBeforeAbsoluteTime(timeX),
///     Claimant.predicateNot(
///       Claimant.predicateBeforeAbsoluteTime(timeY)
///     )
///   )
/// );
/// ```
///
/// See also:
/// - [CreateClaimableBalanceOperation] to create claimable balances with claimants
/// - [ClaimClaimableBalanceOperation] to claim a balance
/// - [CAP-23](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0023.md)
class Claimant {
  /// The destination account ID that can claim the balance.
  String destination;

  /// The predicate that must be satisfied to claim the balance.
  XdrClaimPredicate predicate;

  /// Creates a new Claimant.
  ///
  /// Parameters:
  /// - [destination] The account ID that can claim the balance.
  /// - [predicate] The claim predicate conditions.
  Claimant(this.destination, this.predicate);

  /// Creates an unconditional predicate - can be claimed immediately.
  ///
  /// Returns: A predicate that always allows claiming.
  static XdrClaimPredicate predicateUnconditional() {
    return XdrClaimPredicate(
        XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
  }

  /// Creates an AND predicate - both conditions must be true.
  ///
  /// Parameters:
  /// - [left] The first predicate condition.
  /// - [right] The second predicate condition.
  ///
  /// Returns: A predicate that requires both conditions to be satisfied.
  static XdrClaimPredicate predicateAnd(
      XdrClaimPredicate left, XdrClaimPredicate right) {
    XdrClaimPredicate pred =
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
    pred.andPredicates = [];
    pred.andPredicates!.add(left);
    pred.andPredicates!.add(right);
    return pred;
  }

  /// Creates an OR predicate - either condition can be true.
  ///
  /// Parameters:
  /// - [left] The first predicate condition.
  /// - [right] The second predicate condition.
  ///
  /// Returns: A predicate that requires at least one condition to be satisfied.
  static XdrClaimPredicate predicateOr(
      XdrClaimPredicate left, XdrClaimPredicate right) {
    XdrClaimPredicate pred =
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
    pred.orPredicates = [];
    pred.orPredicates!.add(left);
    pred.orPredicates!.add(right);
    return pred;
  }

  /// Creates a NOT predicate - inverts the condition.
  ///
  /// Parameters:
  /// - [predicate] The predicate to negate.
  ///
  /// Returns: A predicate that inverts the input predicate.
  static XdrClaimPredicate predicateNot(XdrClaimPredicate predicate) {
    XdrClaimPredicate pred =
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
    pred.notPredicate = predicate;
    return pred;
  }

  /// Creates a predicate that is true before an absolute time.
  ///
  /// Parameters:
  /// - [unixEpoch] Unix timestamp in seconds. Balance can be claimed before this time.
  ///
  /// Returns: A time-based predicate for claiming before the specified time.
  ///
  /// Example:
  /// ```dart
  /// // Can claim before January 1, 2026
  /// var deadline = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
  /// var predicate = Claimant.predicateBeforeAbsoluteTime(deadline);
  /// ```
  static XdrClaimPredicate predicateBeforeAbsoluteTime(int unixEpoch) {
    XdrClaimPredicate pred = XdrClaimPredicate(
        XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
    pred.absBefore = XdrInt64(BigInt.from(unixEpoch));
    return pred;
  }

  /// Creates a predicate based on relative time from the close time of the ledger.
  ///
  /// Parameters:
  /// - [seconds] Number of seconds relative to when the balance was created.
  ///   Balance can be claimed before this many seconds have elapsed.
  ///
  /// Returns: A relative time-based predicate.
  ///
  /// Example:
  /// ```dart
  /// // Can claim within 7 days (604800 seconds) of creation
  /// var predicate = Claimant.predicateBeforeRelativeTime(604800);
  /// ```
  static XdrClaimPredicate predicateBeforeRelativeTime(int seconds) {
    XdrClaimPredicate pred = XdrClaimPredicate(
        XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
    pred.relBefore = XdrInt64(BigInt.from(seconds));
    return pred;
  }

  /// Converts this claimant to XDR format.
  ///
  /// Used for serializing claimants to include in transactions.
  ///
  /// Returns: The XDR representation of this claimant.
  XdrClaimant toXdr() {
    XdrClaimant xdrClaimant = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);

    XdrAccountID xDestination =
        XdrAccountID(KeyPair.fromAccountId(destination).xdrPublicKey);

    XdrClaimantV0 xdrClaimantV0 = XdrClaimantV0(xDestination, this.predicate);

    xdrClaimant.v0 = xdrClaimantV0;

    return xdrClaimant;
  }

  /// Creates a [Claimant] from XDR format.
  ///
  /// Used for deserializing claimants from XDR data.
  ///
  /// Parameters:
  /// - [xdrClaimant] The XDR claimant data.
  ///
  /// Returns: A claimant instance with destination and predicate from the XDR.
  static Claimant fromXdr(XdrClaimant xdrClaimant) {
    KeyPair acc =
        KeyPair.fromXdrPublicKey(xdrClaimant.v0!.destination.accountID);
    String destination = acc.accountId;

    Claimant claimant = Claimant(destination, xdrClaimant.v0!.predicate);
    return claimant;
  }
}
