// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

import 'xdr/xdr_ledger.dart';
import 'xdr/xdr_account.dart';
import 'key_pair.dart';

class Claimant {
  String destination;
  XdrClaimPredicate predicate;

  Claimant(this.destination, this.predicate);

  static XdrClaimPredicate predicateUnconditional() {
    return XdrClaimPredicate(
        XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL);
  }

  static XdrClaimPredicate predicateAnd(
      XdrClaimPredicate left, XdrClaimPredicate right) {
    XdrClaimPredicate pred =
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_AND);
    pred.andPredicates = [];
    pred.andPredicates!.add(left);
    pred.andPredicates!.add(right);
    return pred;
  }

  static XdrClaimPredicate predicateOr(
      XdrClaimPredicate left, XdrClaimPredicate right) {
    XdrClaimPredicate pred =
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_OR);
    pred.orPredicates = [];
    pred.orPredicates!.add(left);
    pred.orPredicates!.add(right);
    return pred;
  }

  static XdrClaimPredicate predicateNot(XdrClaimPredicate predicate) {
    XdrClaimPredicate pred =
        XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_NOT);
    pred.notPredicate = predicate;
    return pred;
  }

  static XdrClaimPredicate predicateBeforeAbsoluteTime(int unixEpoch) {
    XdrClaimPredicate pred = XdrClaimPredicate(
        XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME);
    XdrInt64 i = XdrInt64();
    i.int64 = unixEpoch;
    pred.absBefore = i;
    return pred;
  }

  static XdrClaimPredicate predicateBeforeRelativeTime(int seconds) {
    XdrClaimPredicate pred = XdrClaimPredicate(
        XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME);
    XdrInt64 i = XdrInt64();
    i.int64 = seconds;
    pred.relBefore = i;
    return pred;
  }

  XdrClaimant toXdr() {
    XdrClaimant xdrClaimant = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0);

    XdrAccountID xDestination =
        XdrAccountID(KeyPair.fromAccountId(destination).xdrPublicKey);

    XdrClaimantV0 xdrClaimantV0 = XdrClaimantV0(xDestination, this.predicate);

    xdrClaimant.v0 = xdrClaimantV0;

    return xdrClaimant;
  }

  static Claimant fromXdr(XdrClaimant xdrClaimant) {
    KeyPair acc =
        KeyPair.fromXdrPublicKey(xdrClaimant.v0!.destination.accountID);
    String destination = acc.accountId;

    Claimant claimant = Claimant(destination, xdrClaimant.v0!.predicate);
    return claimant;
  }
}
