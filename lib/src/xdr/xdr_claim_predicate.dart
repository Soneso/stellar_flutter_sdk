// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_claim_predicate_type.dart';
import 'xdr_data_io.dart';
import 'xdr_int64.dart';

class XdrClaimPredicate {
  XdrClaimPredicateType _type;

  XdrClaimPredicateType get discriminant => this._type;

  set discriminant(XdrClaimPredicateType value) => this._type = value;

  List<XdrClaimPredicate>? _andPredicates;

  List<XdrClaimPredicate>? get andPredicates => this._andPredicates;

  set andPredicates(List<XdrClaimPredicate>? value) =>
      this._andPredicates = value;

  List<XdrClaimPredicate>? _orPredicates;

  List<XdrClaimPredicate>? get orPredicates => this._orPredicates;

  set orPredicates(List<XdrClaimPredicate>? value) =>
      this._orPredicates = value;

  XdrClaimPredicate? _notPredicate;

  XdrClaimPredicate? get notPredicate => this._notPredicate;

  set notPredicate(XdrClaimPredicate? value) => this._notPredicate = value;

  XdrInt64? _absBefore; // Predicate will be true if closeTime < absBefore
  XdrInt64? get absBefore => this._absBefore;

  set absBefore(XdrInt64? value) => this._absBefore = value;

  XdrInt64? _relBefore; // Seconds since closeTime of the ledger in
  // which the ClaimableBalanceEntry was created
  XdrInt64? get relBefore => this._relBefore;

  set relBefore(XdrInt64? value) => this._relBefore = value;

  XdrClaimPredicate(this._type);

  static void encode(
    XdrDataOutputStream stream,
    XdrClaimPredicate encodedClaimPredicate,
  ) {
    stream.writeInt(encodedClaimPredicate.discriminant.value);
    switch (encodedClaimPredicate.discriminant) {
      case XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL:
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_AND:
        int pSize = encodedClaimPredicate.andPredicates!.length;
        stream.writeInt(pSize);
        for (int i = 0; i < pSize; i++) {
          XdrClaimPredicate.encode(
            stream,
            encodedClaimPredicate.andPredicates![i],
          );
        }
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_OR:
        int pSize = encodedClaimPredicate.orPredicates!.length;
        stream.writeInt(pSize);
        for (int i = 0; i < pSize; i++) {
          XdrClaimPredicate.encode(
            stream,
            encodedClaimPredicate.orPredicates![i],
          );
        }
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_NOT:
        if (encodedClaimPredicate.notPredicate != null) {
          stream.writeInt(1);
          XdrClaimPredicate.encode(stream, encodedClaimPredicate.notPredicate!);
        } else {
          stream.writeInt(0);
        }
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME:
        XdrInt64.encode(stream, encodedClaimPredicate.absBefore!);
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME:
        XdrInt64.encode(stream, encodedClaimPredicate.relBefore!);
        break;
    }
  }

  static XdrClaimPredicate decode(XdrDataInputStream stream) {
    XdrClaimPredicate decoded = XdrClaimPredicate(
      XdrClaimPredicateType.decode(stream),
    );
    switch (decoded.discriminant) {
      case XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL:
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_AND:
        int predicatesSize = stream.readInt();

        List<XdrClaimPredicate> andPredicates = List<XdrClaimPredicate>.empty(
          growable: true,
        );
        for (int i = 0; i < predicatesSize; i++) {
          andPredicates.add(XdrClaimPredicate.decode(stream));
        }
        decoded.andPredicates = andPredicates;
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_OR:
        int predicatesSize = stream.readInt();
        List<XdrClaimPredicate> orPredicates = List<XdrClaimPredicate>.empty(
          growable: true,
        );
        for (int i = 0; i < predicatesSize; i++) {
          orPredicates.add(XdrClaimPredicate.decode(stream));
        }
        decoded.orPredicates = orPredicates;
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_NOT:
        int predicatesSize = stream.readInt();
        List<XdrClaimPredicate> notPredicates = List<XdrClaimPredicate>.empty(
          growable: true,
        );
        for (int i = 0; i < predicatesSize; i++) {
          notPredicates.add(XdrClaimPredicate.decode(stream));
        }
        decoded.notPredicate = notPredicates.first;
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME:
        decoded.absBefore = XdrInt64.decode(stream);
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME:
        decoded.relBefore = XdrInt64.decode(stream);
        break;
    }
    return decoded;
  }
}
