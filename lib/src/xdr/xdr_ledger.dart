// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'xdr_contract.dart';
import '../key_pair.dart';
import '../util.dart';
import 'xdr_type.dart';
import 'xdr_trustline.dart';
import 'xdr_offer.dart';
import 'xdr_data_entry.dart';
import 'xdr_data_io.dart';
import 'xdr_other.dart';
import 'xdr_asset.dart';
import 'xdr_scp.dart';
import 'xdr_account.dart';

class XdrLedgerEntryChangeType {
  final _value;

  const XdrLedgerEntryChangeType._internal(this._value);

  toString() => 'LedgerEntryChangeType.$_value';

  XdrLedgerEntryChangeType(this._value);

  get value => this._value;

  static const LEDGER_ENTRY_CREATED =
      const XdrLedgerEntryChangeType._internal(0);
  static const LEDGER_ENTRY_UPDATED =
      const XdrLedgerEntryChangeType._internal(1);
  static const LEDGER_ENTRY_REMOVED =
      const XdrLedgerEntryChangeType._internal(2);
  static const LEDGER_ENTRY_STATE = const XdrLedgerEntryChangeType._internal(3);

  static XdrLedgerEntryChangeType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return LEDGER_ENTRY_CREATED;
      case 1:
        return LEDGER_ENTRY_UPDATED;
      case 2:
        return LEDGER_ENTRY_REMOVED;
      case 3:
        return LEDGER_ENTRY_STATE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrLedgerEntryChangeType value) {
    stream.writeInt(value.value);
  }
}

class XdrLedgerEntryType {
  final _value;

  const XdrLedgerEntryType._internal(this._value);

  toString() => 'LedgerEntryType.$_value';

  XdrLedgerEntryType(this._value);

  get value => this._value;

  static const ACCOUNT = const XdrLedgerEntryType._internal(0);
  static const TRUSTLINE = const XdrLedgerEntryType._internal(1);
  static const OFFER = const XdrLedgerEntryType._internal(2);
  static const DATA = const XdrLedgerEntryType._internal(3);
  static const CLAIMABLE_BALANCE = const XdrLedgerEntryType._internal(4);
  static const LIQUIDITY_POOL = const XdrLedgerEntryType._internal(5);
  static const CONTRACT_DATA = const XdrLedgerEntryType._internal(6);
  static const CONTRACT_CODE = const XdrLedgerEntryType._internal(7);
  static const CONFIG_SETTING = const XdrLedgerEntryType._internal(8);

  static XdrLedgerEntryType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ACCOUNT;
      case 1:
        return TRUSTLINE;
      case 2:
        return OFFER;
      case 3:
        return DATA;
      case 4:
        return CLAIMABLE_BALANCE;
      case 5:
        return LIQUIDITY_POOL;
      case 6:
        return CONTRACT_DATA;
      case 7:
        return CONTRACT_CODE;
      case 8:
        return CONFIG_SETTING;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryType value) {
    stream.writeInt(value.value);
  }
}

class XdrClaimPredicateType {
  final _value;

  const XdrClaimPredicateType._internal(this._value);

  toString() => 'ClaimPredicateType.$_value';

  XdrClaimPredicateType(this._value);

  get value => this._value;

  static const CLAIM_PREDICATE_UNCONDITIONAL =
      const XdrClaimPredicateType._internal(0);
  static const CLAIM_PREDICATE_AND = const XdrClaimPredicateType._internal(1);
  static const CLAIM_PREDICATE_OR = const XdrClaimPredicateType._internal(2);
  static const CLAIM_PREDICATE_NOT = const XdrClaimPredicateType._internal(3);
  static const CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME =
      const XdrClaimPredicateType._internal(4);
  static const CLAIM_PREDICATE_BEFORE_RELATIVE_TIME =
      const XdrClaimPredicateType._internal(5);

  static XdrClaimPredicateType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAIM_PREDICATE_UNCONDITIONAL;
      case 1:
        return CLAIM_PREDICATE_AND;
      case 2:
        return CLAIM_PREDICATE_OR;
      case 3:
        return CLAIM_PREDICATE_NOT;
      case 4:
        return CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME;
      case 5:
        return CLAIM_PREDICATE_BEFORE_RELATIVE_TIME;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrClaimPredicateType value) {
    stream.writeInt(value.value);
  }
}

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
      XdrDataOutputStream stream, XdrClaimPredicate encodedClaimPredicate) {
    stream.writeInt(encodedClaimPredicate.discriminant.value);
    switch (encodedClaimPredicate.discriminant) {
      case XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL:
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_AND:
        int pSize = encodedClaimPredicate.andPredicates!.length;
        stream.writeInt(pSize);
        for (int i = 0; i < pSize; i++) {
          XdrClaimPredicate.encode(
              stream, encodedClaimPredicate.andPredicates![i]);
        }
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_OR:
        int pSize = encodedClaimPredicate.orPredicates!.length;
        stream.writeInt(pSize);
        for (int i = 0; i < pSize; i++) {
          XdrClaimPredicate.encode(
              stream, encodedClaimPredicate.orPredicates![i]);
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
        XdrInt64.encode(stream, encodedClaimPredicate.absBefore);
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME:
        XdrInt64.encode(stream, encodedClaimPredicate.relBefore);
        break;
    }
  }

  static XdrClaimPredicate decode(XdrDataInputStream stream) {
    XdrClaimPredicate decoded =
        XdrClaimPredicate(XdrClaimPredicateType.decode(stream));
    switch (decoded.discriminant) {
      case XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL:
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_AND:
        int predicatesSize = stream.readInt();

        List<XdrClaimPredicate> andPredicates =
            List<XdrClaimPredicate>.empty(growable: true);
        for (int i = 0; i < predicatesSize; i++) {
          andPredicates.add(XdrClaimPredicate.decode(stream));
        }
        decoded.andPredicates = andPredicates;
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_OR:
        int predicatesSize = stream.readInt();
        List<XdrClaimPredicate> orPredicates =
            List<XdrClaimPredicate>.empty(growable: true);
        for (int i = 0; i < predicatesSize; i++) {
          orPredicates.add(XdrClaimPredicate.decode(stream));
        }
        decoded.orPredicates = orPredicates;
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_NOT:
        int predicatesSize = stream.readInt();
        List<XdrClaimPredicate> notPredicates =
            List<XdrClaimPredicate>.empty(growable: true);
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

class XdrClaimantType {
  final _value;

  const XdrClaimantType._internal(this._value);

  toString() => 'ClaimantType.$_value';

  XdrClaimantType(this._value);

  get value => this._value;

  static const CLAIMANT_TYPE_V0 = const XdrClaimantType._internal(0);

  static XdrClaimantType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAIMANT_TYPE_V0;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrClaimantType value) {
    stream.writeInt(value.value);
  }
}

class XdrClaimant {
  XdrClaimantType _type;

  XdrClaimantType get discriminant => this._type;

  set discriminant(XdrClaimantType value) => this._type = value;

  XdrClaimantV0? _v0;

  XdrClaimantV0? get v0 => this._v0;

  set v0(XdrClaimantV0? value) => this._v0 = value;

  XdrClaimant(this._type);

  static void encode(XdrDataOutputStream stream, XdrClaimant encodedClaimant) {
    stream.writeInt(encodedClaimant.discriminant.value);
    switch (encodedClaimant.discriminant) {
      case XdrClaimantType.CLAIMANT_TYPE_V0:
        XdrClaimantV0.encode(stream, encodedClaimant.v0!);
        break;
    }
  }

  static XdrClaimant decode(XdrDataInputStream stream) {
    XdrClaimant decoded = XdrClaimant(XdrClaimantType.decode(stream));
    switch (decoded.discriminant) {
      case XdrClaimantType.CLAIMANT_TYPE_V0:
        decoded.v0 = XdrClaimantV0.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrClaimantV0 {
  XdrAccountID _destination;

  XdrAccountID get destination => this._destination;

  set destination(XdrAccountID value) => this._destination = value;

  XdrClaimPredicate _predicate;

  XdrClaimPredicate get predicate => this._predicate;

  set predicate(XdrClaimPredicate value) => this._predicate = value;

  XdrClaimantV0(this._destination, this._predicate);

  static void encode(
      XdrDataOutputStream stream, XdrClaimantV0 encodedClaimantV0) {
    XdrAccountID.encode(stream, encodedClaimantV0.destination);
    XdrClaimPredicate.encode(stream, encodedClaimantV0.predicate);
  }

  static XdrClaimantV0 decode(XdrDataInputStream stream) {
    return XdrClaimantV0(
        XdrAccountID.decode(stream), XdrClaimPredicate.decode(stream));
  }
}

class XdrClaimableBalanceIDType {
  final _value;

  const XdrClaimableBalanceIDType._internal(this._value);

  toString() => 'ClaimableBalanceIDType.$_value';

  XdrClaimableBalanceIDType(this._value);

  get value => this._value;

  static const CLAIMABLE_BALANCE_ID_TYPE_V0 =
      const XdrClaimableBalanceIDType._internal(0);

  static XdrClaimableBalanceIDType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAIMABLE_BALANCE_ID_TYPE_V0;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceIDType value) {
    stream.writeInt(value.value);
  }
}

class XdrClaimableBalanceID {
  XdrClaimableBalanceIDType _type;

  XdrClaimableBalanceIDType get discriminant => this._type;

  set discriminant(XdrClaimableBalanceIDType value) => this._type = value;

  XdrHash? _v0;

  XdrHash? get v0 => this._v0;

  set v0(XdrHash? value) => this._v0 = value;

  XdrClaimableBalanceID(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceID encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0:
        XdrHash.encode(stream, encoded.v0!);
        break;
    }
  }

  static XdrClaimableBalanceID decode(XdrDataInputStream stream) {
    XdrClaimableBalanceID decoded =
        XdrClaimableBalanceID(XdrClaimableBalanceIDType.decode(stream));
    switch (decoded.discriminant) {
      case XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0:
        decoded.v0 = XdrHash.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrClaimableBalanceEntry {
  XdrClaimableBalanceID _balanceID;

  XdrClaimableBalanceID get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID value) => this._balanceID = value;

  List<XdrClaimant> _claimants;

  List<XdrClaimant> get claimants => this._claimants;

  set claimants(List<XdrClaimant> value) => this._claimants = value;

  XdrAsset _asset;

  XdrAsset get asset => this._asset;

  set asset(XdrAsset value) => this._asset = value;

  XdrInt64 _amount;

  XdrInt64 get amount => this._amount;

  set amount(XdrInt64 value) => this._amount = value;

  XdrClaimableBalanceEntryExt _ext;

  XdrClaimableBalanceEntryExt get ext => this._ext;

  set ext(XdrClaimableBalanceEntryExt value) => this._ext = value;

  XdrClaimableBalanceEntry(
      this._balanceID, this._claimants, this._asset, this._amount, this._ext);

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceEntry encoded) {
    XdrClaimableBalanceID.encode(stream, encoded.balanceID);
    int pSize = encoded.claimants.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      XdrClaimant.encode(stream, encoded.claimants[i]);
    }
    XdrAsset.encode(stream, encoded.asset);
    XdrInt64.encode(stream, encoded.amount);
    XdrClaimableBalanceEntryExt.encode(stream, encoded.ext);
  }

  static XdrClaimableBalanceEntry decode(XdrDataInputStream stream) {
    XdrClaimableBalanceID xBalanceID = XdrClaimableBalanceID.decode(stream);
    int pSize = stream.readInt();
    List<XdrClaimant> xClaimants = List<XdrClaimant>.empty(growable: true);
    for (int i = 0; i < pSize; i++) {
      xClaimants.add(XdrClaimant.decode(stream));
    }
    XdrAsset xAsset = XdrAsset.decode(stream);
    XdrInt64 xAmount = XdrInt64.decode(stream);
    XdrClaimableBalanceEntryExt xExt =
        XdrClaimableBalanceEntryExt.decode(stream);

    return XdrClaimableBalanceEntry(
        xBalanceID, xClaimants, xAsset, xAmount, xExt);
  }
}

class XdrClaimableBalanceEntryExt {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrClaimableBalanceEntryExtV1? _v1;

  XdrClaimableBalanceEntryExtV1? get v1 => this._v1;

  set v1(XdrClaimableBalanceEntryExtV1? value) => this._v1 = value;

  XdrClaimableBalanceEntryExt(this._v);

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceEntryExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrClaimableBalanceEntryExtV1.encode(stream, encoded.v1!);
        break;
    }
  }

  static XdrClaimableBalanceEntryExt decode(XdrDataInputStream stream) {
    XdrClaimableBalanceEntryExt decoded =
        XdrClaimableBalanceEntryExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.v1 = XdrClaimableBalanceEntryExtV1.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrClaimableBalanceEntryExtV1 {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrUint32 _flags;
  XdrUint32 get flags => this._flags;
  set flags(XdrUint32 value) => this._flags = value;

  XdrClaimableBalanceEntryExtV1(this._v, this._flags);

  static void encode(
      XdrDataOutputStream stream, XdrClaimableBalanceEntryExtV1 encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
    }
    XdrUint32.encode(stream, encoded.flags);
  }

  static XdrClaimableBalanceEntryExtV1 decode(XdrDataInputStream stream) {
    int v = stream.readInt();
    switch (v) {
      case 0:
        break;
    }
    XdrUint32 flags = XdrUint32.decode(stream);
    return XdrClaimableBalanceEntryExtV1(v,flags);
  }
}

class XdrLedgerUpgradeType {
  final _value;

  const XdrLedgerUpgradeType._internal(this._value);

  toString() => 'LedgerUpgradeType.$_value';

  XdrLedgerUpgradeType(this._value);

  get value => this._value;

  static const LEDGER_UPGRADE_VERSION = const XdrLedgerUpgradeType._internal(1);
  static const LEDGER_UPGRADE_BASE_FEE =
      const XdrLedgerUpgradeType._internal(2);
  static const LEDGER_UPGRADE_MAX_TX_SET_SIZE =
      const XdrLedgerUpgradeType._internal(3);
  static const LEDGER_UPGRADE_BASE_RESERVE =
      const XdrLedgerUpgradeType._internal(4);

  static XdrLedgerUpgradeType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return LEDGER_UPGRADE_VERSION;
      case 2:
        return LEDGER_UPGRADE_BASE_FEE;
      case 3:
        return LEDGER_UPGRADE_MAX_TX_SET_SIZE;
      case 4:
        return LEDGER_UPGRADE_BASE_RESERVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrLedgerUpgradeType value) {
    stream.writeInt(value.value);
  }
}

class XdrLedgerHeader {
  XdrUint32 _ledgerVersion;

  XdrUint32 get ledgerVersion => this._ledgerVersion;

  set ledgerVersion(XdrUint32 value) => this._ledgerVersion = value;

  XdrHash _previousLedgerHash;

  XdrHash get previousLedgerHash => this._previousLedgerHash;

  set previousLedgerHash(XdrHash value) => this._previousLedgerHash = value;

  XdrStellarValue _scpValue;

  XdrStellarValue get scpValue => this._scpValue;

  set scpValue(XdrStellarValue value) => this._scpValue = value;

  XdrHash _txSetResultHash;

  XdrHash get txSetResultHash => this._txSetResultHash;

  set txSetResultHash(XdrHash value) => this._txSetResultHash = value;

  XdrHash _bucketListHash;

  XdrHash get bucketListHash => this._bucketListHash;

  set bucketListHash(XdrHash value) => this._bucketListHash = value;

  XdrUint32 _ledgerSeq;

  XdrUint32 get ledgerSeq => this._ledgerSeq;

  set ledgerSeq(XdrUint32 value) => this._ledgerSeq = value;

  XdrInt64 _totalCoins;

  XdrInt64 get totalCoins => this._totalCoins;

  set totalCoins(XdrInt64 value) => this._totalCoins = value;

  XdrInt64 _feePool;

  XdrInt64 get feePool => this._feePool;

  set feePool(XdrInt64 value) => this._feePool = value;

  XdrUint32 _inflationSeq;

  XdrUint32 get inflationSeq => this._inflationSeq;

  set inflationSeq(XdrUint32 value) => this._inflationSeq = value;

  XdrUint64 _idPool;

  XdrUint64 get idPool => this._idPool;

  set idPool(XdrUint64 value) => this._idPool = value;

  XdrUint32 _baseFee;

  XdrUint32 get baseFee => this._baseFee;

  set baseFee(XdrUint32 value) => this._baseFee = value;

  XdrUint32 _baseReserve;

  XdrUint32 get baseReserve => this._baseReserve;

  set baseReserve(XdrUint32 value) => this._baseReserve = value;

  XdrUint32 _maxTxSetSize;

  XdrUint32 get maxTxSetSize => this._maxTxSetSize;

  set maxTxSetSize(XdrUint32 value) => this._maxTxSetSize = value;

  List<XdrHash> _skipList;

  List<XdrHash> get skipList => this._skipList;

  set skipList(List<XdrHash> value) => this._skipList = value;

  XdrLedgerHeaderExt _ext;

  XdrLedgerHeaderExt get ext => this._ext;

  set ext(XdrLedgerHeaderExt value) => this._ext = value;

  XdrLedgerHeader(
      this._ledgerVersion,
      this._previousLedgerHash,
      this._scpValue,
      this._txSetResultHash,
      this._bucketListHash,
      this._ledgerSeq,
      this._totalCoins,
      this._feePool,
      this._inflationSeq,
      this._idPool,
      this._baseFee,
      this._baseReserve,
      this._maxTxSetSize,
      this._skipList,
      this._ext);

  static void encode(
      XdrDataOutputStream stream, XdrLedgerHeader encodedLedgerHeader) {
    XdrUint32.encode(stream, encodedLedgerHeader.ledgerVersion);
    XdrHash.encode(stream, encodedLedgerHeader.previousLedgerHash);
    XdrStellarValue.encode(stream, encodedLedgerHeader.scpValue);
    XdrHash.encode(stream, encodedLedgerHeader.txSetResultHash);
    XdrHash.encode(stream, encodedLedgerHeader.bucketListHash);
    XdrUint32.encode(stream, encodedLedgerHeader.ledgerSeq);
    XdrInt64.encode(stream, encodedLedgerHeader.totalCoins);
    XdrInt64.encode(stream, encodedLedgerHeader.feePool);
    XdrUint32.encode(stream, encodedLedgerHeader.inflationSeq);
    XdrUint64.encode(stream, encodedLedgerHeader.idPool);
    XdrUint32.encode(stream, encodedLedgerHeader.baseFee);
    XdrUint32.encode(stream, encodedLedgerHeader.baseReserve);
    XdrUint32.encode(stream, encodedLedgerHeader.maxTxSetSize);

    int skipListsize = encodedLedgerHeader.skipList.length;
    for (int i = 0; i < skipListsize; i++) {
      XdrHash.encode(stream, encodedLedgerHeader.skipList[i]);
    }
    XdrLedgerHeaderExt.encode(stream, encodedLedgerHeader.ext);
  }

  static XdrLedgerHeader decode(XdrDataInputStream stream) {
    XdrUint32 ledgerVersion = XdrUint32.decode(stream);
    XdrHash previousLedgerHash = XdrHash.decode(stream);
    XdrStellarValue scpValue = XdrStellarValue.decode(stream);
    XdrHash txSetResultHash = XdrHash.decode(stream);
    XdrHash bucketListHash = XdrHash.decode(stream);
    XdrUint32 ledgerSeq = XdrUint32.decode(stream);
    XdrInt64 totalCoins = XdrInt64.decode(stream);
    XdrInt64 feePool = XdrInt64.decode(stream);
    XdrUint32 inflationSeq = XdrUint32.decode(stream);
    XdrUint64 idPool = XdrUint64.decode(stream);
    XdrUint32 baseFee = XdrUint32.decode(stream);
    XdrUint32 baseReserve = XdrUint32.decode(stream);
    XdrUint32 maxTxSetSize = XdrUint32.decode(stream);

    List<XdrHash> skipList = List<XdrHash>.empty(growable: true);
    for (int i = 0; i < 4; i++) {
      skipList.add(XdrHash.decode(stream));
    }

    XdrLedgerHeaderExt ext = XdrLedgerHeaderExt.decode(stream);
    XdrLedgerHeader decodedLedgerHeader = XdrLedgerHeader(
        ledgerVersion,
        previousLedgerHash,
        scpValue,
        txSetResultHash,
        bucketListHash,
        ledgerSeq,
        totalCoins,
        feePool,
        inflationSeq,
        idPool,
        baseFee,
        baseReserve,
        maxTxSetSize,
        skipList,
        ext);
    return decodedLedgerHeader;
  }
}

class XdrLedgerHeaderExt {
  XdrLedgerHeaderExt(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerHeaderExt encodedLedgerHeaderExt) {
    stream.writeInt(encodedLedgerHeaderExt.discriminant);
    switch (encodedLedgerHeaderExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrLedgerHeaderExt decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrLedgerHeaderExt decodedLedgerHeaderExt =
        XdrLedgerHeaderExt(discriminant);
    switch (decodedLedgerHeaderExt.discriminant) {
      case 0:
        break;
    }
    return decodedLedgerHeaderExt;
  }
}

class XdrLedgerKey {
  XdrLedgerKey(this._type);
  XdrLedgerEntryType _type;
  XdrLedgerEntryType get discriminant => this._type;

  set discriminant(XdrLedgerEntryType value) => this._type = value;

  XdrLedgerKeyAccount? _account;
  XdrLedgerKeyAccount? get account => this._account;
  set account(XdrLedgerKeyAccount? value) => this._account = value;

  XdrLedgerKeyTrustLine? _trustLine;
  XdrLedgerKeyTrustLine? get trustLine => this._trustLine;
  set trustLine(XdrLedgerKeyTrustLine? value) => this._trustLine = value;

  XdrLedgerKeyOffer? _offer;
  XdrLedgerKeyOffer? get offer => this._offer;
  set offer(XdrLedgerKeyOffer? value) => this._offer = value;

  XdrLedgerKeyData? _data;
  XdrLedgerKeyData? get data => this._data;
  set data(XdrLedgerKeyData? value) => this._data = value;

  XdrClaimableBalanceID? _balanceID;
  XdrClaimableBalanceID? get balanceID => this._balanceID;
  set balanceID(XdrClaimableBalanceID? value) => this._balanceID = value;

  XdrHash? _liquidityPoolID;
  XdrHash? get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash? value) => this._liquidityPoolID = value;

  XdrHash? _contractID;
  XdrHash? get contractID => this._contractID;
  set contractID(XdrHash? value) => this._contractID = value;

  XdrSCVal? _contractDataKey;
  XdrSCVal? get contractDataKey => this._contractDataKey;
  set contractDataKey(XdrSCVal? value) => this._contractDataKey = value;

  XdrHash? _contractCodeHash;
  XdrHash? get contractCodeHash => this._contractCodeHash;
  set contractCodeHash(XdrHash? value) => this._contractCodeHash = value;

  XdrConfigSettingID? _configSetting;
  XdrConfigSettingID? get configSetting => this._configSetting;
  set configSetting(XdrConfigSettingID? value) => this._configSetting = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKey encodedLedgerKey) {
    stream.writeInt(encodedLedgerKey.discriminant.value);
    switch (encodedLedgerKey.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        XdrLedgerKeyAccount.encode(stream, encodedLedgerKey.account!);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        XdrLedgerKeyTrustLine.encode(stream, encodedLedgerKey.trustLine!);
        break;
      case XdrLedgerEntryType.OFFER:
        XdrLedgerKeyOffer.encode(stream, encodedLedgerKey.offer!);
        break;
      case XdrLedgerEntryType.DATA:
        XdrLedgerKeyData.encode(stream, encodedLedgerKey.data!);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        XdrClaimableBalanceID.encode(stream, encodedLedgerKey.balanceID!);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        XdrHash.encode(stream, encodedLedgerKey.liquidityPoolID!);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        XdrHash.encode(stream, encodedLedgerKey.contractID!);
        XdrSCVal.encode(stream, encodedLedgerKey.contractDataKey!);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        XdrHash.encode(stream, encodedLedgerKey.contractCodeHash!);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        XdrConfigSettingID.encode(stream, encodedLedgerKey.configSetting!);
    }
  }

  static XdrLedgerKey decode(XdrDataInputStream stream) {
    XdrLedgerEntryType discriminant = XdrLedgerEntryType.decode(stream);
    XdrLedgerKey decodedLedgerKey = XdrLedgerKey(discriminant);
    switch (decodedLedgerKey.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        decodedLedgerKey.account = XdrLedgerKeyAccount.decode(stream);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        decodedLedgerKey.trustLine = XdrLedgerKeyTrustLine.decode(stream);
        break;
      case XdrLedgerEntryType.OFFER:
        decodedLedgerKey.offer = XdrLedgerKeyOffer.decode(stream);
        break;
      case XdrLedgerEntryType.DATA:
        decodedLedgerKey.data = XdrLedgerKeyData.decode(stream);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        decodedLedgerKey.balanceID = XdrClaimableBalanceID.decode(stream);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        decodedLedgerKey.liquidityPoolID = XdrHash.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        decodedLedgerKey.contractID = XdrHash.decode(stream);
        decodedLedgerKey.contractDataKey = XdrSCVal.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        decodedLedgerKey.contractCodeHash = XdrHash.decode(stream);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        decodedLedgerKey.configSetting = XdrConfigSettingID.decode(stream);
        break;
    }
    return decodedLedgerKey;
  }

  String? getAccountAccountId() {
    if (_account != null) {
      return KeyPair.fromXdrPublicKey(_account!.accountID.accountID).accountId;
    }
    return null;
  }

  String? getTrustlineAccountId() {
    if (_trustLine != null) {
      return KeyPair.fromXdrPublicKey(_trustLine!.accountID.accountID)
          .accountId;
    }
    return null;
  }

  String? getDataAccountId() {
    if (_data != null) {
      return KeyPair.fromXdrPublicKey(_data!.accountID.accountID).accountId;
    }
    return null;
  }

  String? getOfferSellerId() {
    if (_offer != null) {
      return KeyPair.fromXdrPublicKey(_offer!.sellerID.accountID).accountId;
    }
    return null;
  }

  int? getOfferOfferId() {
    if (_offer != null) {
      return _offer!.offerID.uint64;
    }
    return null;
  }

  String? getClaimableBalanceId() {
    if (_balanceID != null && _balanceID!.v0 != null) {
      return Util.bytesToHex(_balanceID!.v0!.hash);
    }
    return null;
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerKey.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerKey fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerKey.decode(XdrDataInputStream(bytes));
  }
}

class XdrLedgerKeyAccount {
  XdrLedgerKeyAccount(this._accountID);

  XdrAccountID _accountID;

  XdrAccountID get accountID => this._accountID;

  set accountID(XdrAccountID value) => this._accountID = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyAccount encodedLedgerKeyAccount) {
    XdrAccountID.encode(stream, encodedLedgerKeyAccount.accountID);
  }

  static XdrLedgerKeyAccount decode(XdrDataInputStream stream) {
    XdrLedgerKeyAccount decodedLedgerKeyAccount =
        XdrLedgerKeyAccount(XdrAccountID.decode(stream));
    return decodedLedgerKeyAccount;
  }
}

class XdrLedgerKeyTrustLine {
  XdrLedgerKeyTrustLine(this._accountID, this._asset);

  XdrAccountID _accountID;

  XdrAccountID get accountID => this._accountID;

  set accountID(XdrAccountID value) => this._accountID = value;

  XdrTrustlineAsset _asset;

  XdrTrustlineAsset get asset => this._asset;

  set asset(XdrTrustlineAsset value) => this._asset = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerKeyTrustLine encodedLedgerKeyTrustLine) {
    XdrAccountID.encode(stream, encodedLedgerKeyTrustLine.accountID);
    XdrTrustlineAsset.encode(stream, encodedLedgerKeyTrustLine.asset);
  }

  static XdrLedgerKeyTrustLine decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    XdrTrustlineAsset asset = XdrTrustlineAsset.decode(stream);
    return XdrLedgerKeyTrustLine(accountID, asset);
  }
}

class XdrLedgerKeyOffer {
  XdrLedgerKeyOffer(this._sellerID, this._offerID);

  XdrAccountID _sellerID;

  XdrAccountID get sellerID => this._sellerID;

  set sellerID(XdrAccountID value) => this._sellerID = value;

  XdrUint64 _offerID;

  XdrUint64 get offerID => this._offerID;

  set offerID(XdrUint64 value) => this._offerID = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyOffer encodedLedgerKeyOffer) {
    XdrAccountID.encode(stream, encodedLedgerKeyOffer.sellerID);
    XdrUint64.encode(stream, encodedLedgerKeyOffer.offerID);
  }

  static XdrLedgerKeyOffer decode(XdrDataInputStream stream) {
    return XdrLedgerKeyOffer(
        XdrAccountID.decode(stream), XdrUint64.decode(stream));
  }
}

class XdrLedgerKeyData {
  XdrLedgerKeyData(this._accountID, this._dataName);

  XdrAccountID _accountID;

  XdrAccountID get accountID => this._accountID;

  set accountID(XdrAccountID value) => this._accountID = value;

  XdrString64 _dataName;

  XdrString64 get dataName => this._dataName;

  set dataName(XdrString64 value) => this._dataName = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyData encodedLedgerKeyData) {
    XdrAccountID.encode(stream, encodedLedgerKeyData.accountID);
    XdrString64.encode(stream, encodedLedgerKeyData.dataName);
  }

  static XdrLedgerKeyData decode(XdrDataInputStream stream) {
    return XdrLedgerKeyData(
        XdrAccountID.decode(stream), XdrString64.decode(stream));
  }
}

class XdrLedgerSCPMessages {
  XdrLedgerSCPMessages(this._ledgerSeq, this._messages);

  XdrUint32 _ledgerSeq;

  XdrUint32 get ledgerSeq => this._ledgerSeq;

  set ledgerSeq(XdrUint32 value) => this._ledgerSeq = value;

  List<XdrSCPEnvelope> _messages;

  List<XdrSCPEnvelope> get messages => this._messages;

  set messages(List<XdrSCPEnvelope> value) => this._messages = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerSCPMessages encodedLedgerSCPMessages) {
    XdrUint32.encode(stream, encodedLedgerSCPMessages.ledgerSeq);
    int messagessize = encodedLedgerSCPMessages.messages.length;
    stream.writeInt(messagessize);
    for (int i = 0; i < messagessize; i++) {
      XdrSCPEnvelope.encode(stream, encodedLedgerSCPMessages.messages[i]);
    }
  }

  static XdrLedgerSCPMessages decode(XdrDataInputStream stream) {
    XdrUint32 ledgerSeq = XdrUint32.decode(stream);
    int messagessize = stream.readInt();
    List<XdrSCPEnvelope> messages = List<XdrSCPEnvelope>.empty(growable: true);
    for (int i = 0; i < messagessize; i++) {
      messages.add(XdrSCPEnvelope.decode(stream));
    }
    return XdrLedgerSCPMessages(ledgerSeq, messages);
  }
}

class XdrLedgerUpgrade {
  XdrLedgerUpgrade(this._type);

  XdrLedgerUpgradeType _type;

  XdrLedgerUpgradeType get discriminant => this._type;

  set discriminant(XdrLedgerUpgradeType value) => this._type = value;

  XdrUint32? _newLedgerVersion;

  XdrUint32? get newLedgerVersion => this._newLedgerVersion;

  set newLedgerVersion(XdrUint32? value) => this._newLedgerVersion = value;

  XdrUint32? _newBaseFee;

  XdrUint32? get newBaseFee => this._newBaseFee;

  set newBaseFee(XdrUint32? value) => this._newBaseFee = value;

  XdrUint32? _newMaxTxSetSize;

  XdrUint32? get newMaxTxSetSize => this._newMaxTxSetSize;

  set newMaxTxSetSize(XdrUint32? value) => this._newMaxTxSetSize = value;

  XdrUint32? _newBaseReserve;

  XdrUint32? get newBaseReserve => this._newBaseReserve;

  set newBaseReserve(XdrUint32? value) => this._newBaseReserve = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerUpgrade encodedLedgerUpgrade) {
    stream.writeInt(encodedLedgerUpgrade.discriminant.value);
    switch (encodedLedgerUpgrade.discriminant) {
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newLedgerVersion);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newBaseFee);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newMaxTxSetSize);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newBaseReserve);
        break;
    }
  }

  static XdrLedgerUpgrade decode(XdrDataInputStream stream) {
    XdrLedgerUpgrade decodedLedgerUpgrade =
        XdrLedgerUpgrade(XdrLedgerUpgradeType.decode(stream));
    switch (decodedLedgerUpgrade.discriminant) {
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION:
        decodedLedgerUpgrade._newLedgerVersion = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE:
        decodedLedgerUpgrade._newBaseFee = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE:
        decodedLedgerUpgrade._newMaxTxSetSize = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE:
        decodedLedgerUpgrade._newBaseReserve = XdrUint32.decode(stream);
        break;
    }
    return decodedLedgerUpgrade;
  }
}

class XdrLedgerEntry {
  XdrLedgerEntry(this._lastModifiedLedgerSeq, this._data, this._ext);

  XdrUint32 _lastModifiedLedgerSeq;

  XdrUint32 get lastModifiedLedgerSeq => this._lastModifiedLedgerSeq;

  set lastModifiedLedgerSeq(XdrUint32 value) =>
      this._lastModifiedLedgerSeq = value;

  XdrLedgerEntryData _data;

  XdrLedgerEntryData get data => this._data;

  set data(XdrLedgerEntryData value) => this._data = value;

  XdrLedgerEntryExt _ext;

  XdrLedgerEntryExt get ext => this._ext;

  set ext(XdrLedgerEntryExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerEntry encodedLedgerEntry) {
    XdrUint32.encode(stream, encodedLedgerEntry.lastModifiedLedgerSeq);
    XdrLedgerEntryData.encode(stream, encodedLedgerEntry.data);
    XdrLedgerEntryExt.encode(stream, encodedLedgerEntry.ext);
  }

  static XdrLedgerEntry decode(XdrDataInputStream stream) {
    XdrUint32 lastModifiedLedgerSeq = XdrUint32.decode(stream);
    XdrLedgerEntryData data = XdrLedgerEntryData.decode(stream);
    XdrLedgerEntryExt ext = XdrLedgerEntryExt.decode(stream);
    return XdrLedgerEntry(lastModifiedLedgerSeq, data, ext);
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerEntry.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerEntry fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerEntry.decode(XdrDataInputStream(bytes));
  }
}

class XdrLedgerEntryData {
  XdrLedgerEntryData(this._type);

  XdrLedgerEntryType _type;
  XdrLedgerEntryType get discriminant => this._type;
  set discriminant(XdrLedgerEntryType value) => this._type = value;

  XdrAccountEntry? _account;
  XdrAccountEntry? get account => this._account;
  set account(XdrAccountEntry? value) => this._account = value;

  XdrTrustLineEntry? _trustLine;
  XdrTrustLineEntry? get trustLine => this._trustLine;
  set trustLine(XdrTrustLineEntry? value) => this._trustLine = value;

  XdrOfferEntry? _offer;
  XdrOfferEntry? get offer => this._offer;
  set offer(XdrOfferEntry? value) => this._offer = value;

  XdrDataEntry? _data;
  XdrDataEntry? get data => this._data;
  set data(XdrDataEntry? value) => this._data = value;

  XdrClaimableBalanceEntry? _claimableBalance;
  XdrClaimableBalanceEntry? get claimableBalance => this._claimableBalance;
  set claimableBalance(XdrClaimableBalanceEntry? value) =>
      this._claimableBalance = value;

  XdrLiquidityPoolEntry? _liquidityPool;
  XdrLiquidityPoolEntry? get liquidityPool => this._liquidityPool;
  set liquidityPool(XdrLiquidityPoolEntry? value) =>
      this._liquidityPool = value;

  XdrContractDataEntry? _contractData;
  XdrContractDataEntry? get contractData => this._contractData;
  set contractData(XdrContractDataEntry? value) =>
      this._contractData= value;

  XdrContractCodeEntry? _contractCode;
  XdrContractCodeEntry? get contractCode => this._contractCode;
  set contractCode(XdrContractCodeEntry? value) =>
      this._contractCode = value;

  XdrConfigSettingEntry? _configSetting;
  XdrConfigSettingEntry? get configSetting => this._configSetting;
  set configSetting(XdrConfigSettingEntry? value) =>
      this._configSetting = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerEntryData encodedLedgerEntryData) {
    stream.writeInt(encodedLedgerEntryData.discriminant.value);
    switch (encodedLedgerEntryData.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        XdrAccountEntry.encode(stream, encodedLedgerEntryData.account!);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        XdrTrustLineEntry.encode(stream, encodedLedgerEntryData.trustLine!);
        break;
      case XdrLedgerEntryType.OFFER:
        XdrOfferEntry.encode(stream, encodedLedgerEntryData.offer!);
        break;
      case XdrLedgerEntryType.DATA:
        XdrDataEntry.encode(stream, encodedLedgerEntryData.data!);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        XdrClaimableBalanceEntry.encode(
            stream, encodedLedgerEntryData.claimableBalance!);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        XdrLiquidityPoolEntry.encode(
            stream, encodedLedgerEntryData.liquidityPool!);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        XdrContractDataEntry.encode(
            stream, encodedLedgerEntryData.contractData!);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        XdrContractCodeEntry.encode(
            stream, encodedLedgerEntryData.contractCode!);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        XdrConfigSettingEntry.encode(
            stream, encodedLedgerEntryData.configSetting!);
        break;
    }
  }

  static XdrLedgerEntryData decode(XdrDataInputStream stream) {
    XdrLedgerEntryData decodedLedgerEntryData =
        XdrLedgerEntryData(XdrLedgerEntryType.decode(stream));
    switch (decodedLedgerEntryData.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        decodedLedgerEntryData.account = XdrAccountEntry.decode(stream);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        decodedLedgerEntryData.trustLine = XdrTrustLineEntry.decode(stream);
        break;
      case XdrLedgerEntryType.OFFER:
        decodedLedgerEntryData.offer = XdrOfferEntry.decode(stream);
        break;
      case XdrLedgerEntryType.DATA:
        decodedLedgerEntryData.data = XdrDataEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CLAIMABLE_BALANCE:
        decodedLedgerEntryData.claimableBalance =
            XdrClaimableBalanceEntry.decode(stream);
        break;
      case XdrLedgerEntryType.LIQUIDITY_POOL:
        decodedLedgerEntryData.liquidityPool =
            XdrLiquidityPoolEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_DATA:
        decodedLedgerEntryData.contractData =
            XdrContractDataEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        decodedLedgerEntryData.contractCode =
            XdrContractCodeEntry.decode(stream);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        decodedLedgerEntryData.configSetting =
            XdrConfigSettingEntry.decode(stream);
        break;
    }
    return decodedLedgerEntryData;
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerEntryData.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
  }

  static XdrLedgerEntryData fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return XdrLedgerEntryData.decode(XdrDataInputStream(bytes));
  }
}

class XdrLedgerEntryExt {
  XdrLedgerEntryExt(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrLedgerEntryV1? _ledgerEntryExtensionV1;
  XdrLedgerEntryV1? get ledgerEntryExtensionV1 => this._ledgerEntryExtensionV1;
  set ledgerEntryExtensionV1(XdrLedgerEntryV1? value) =>
      this._ledgerEntryExtensionV1 = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerEntryExt encodedLedgerEntryExt) {
    stream.writeInt(encodedLedgerEntryExt.discriminant);
    switch (encodedLedgerEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrLedgerEntryV1.encode(
            stream, encodedLedgerEntryExt.ledgerEntryExtensionV1!);
        break;
    }
  }

  static XdrLedgerEntryExt decode(XdrDataInputStream stream) {
    XdrLedgerEntryExt decodedLedgerEntryExt =
        XdrLedgerEntryExt(stream.readInt());
    switch (decodedLedgerEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedLedgerEntryExt.ledgerEntryExtensionV1 =
            XdrLedgerEntryV1.decode(stream);
        break;
    }
    return decodedLedgerEntryExt;
  }
}

class XdrLedgerEntryV1 {
  XdrLedgerEntryV1(this._ext);

  XdrAccountID? _sponsoringID;

  XdrAccountID? get sponsoringID => this._sponsoringID;

  set sponsoringID(XdrAccountID? value) => this._sponsoringID = value;

  XdrLedgerEntryV1Ext _ext;

  XdrLedgerEntryV1Ext get ext => this._ext;

  set ext(XdrLedgerEntryV1Ext value) => this._ext = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryV1 encoded) {
    if (encoded.sponsoringID != null) {
      stream.writeInt(1);
      XdrAccountID.encode(stream, encoded.sponsoringID);
    } else {
      stream.writeInt(0);
    }
    XdrLedgerEntryV1Ext.encode(stream, encoded.ext);
  }

  static XdrLedgerEntryV1 decode(XdrDataInputStream stream) {
    int sponsoringIDPresent = stream.readInt();
    XdrAccountID? sponsoringID;
    if (sponsoringIDPresent != 0) {
      sponsoringID = XdrAccountID.decode(stream);
    }
    XdrLedgerEntryV1 decoded =
        XdrLedgerEntryV1(XdrLedgerEntryV1Ext.decode(stream));
    decoded.sponsoringID = sponsoringID;
    return decoded;
  }
}

class XdrLedgerEntryV1Ext {
  XdrLedgerEntryV1Ext(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryV1Ext encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
    }
  }

  static XdrLedgerEntryV1Ext decode(XdrDataInputStream stream) {
    XdrLedgerEntryV1Ext decoded = XdrLedgerEntryV1Ext(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
    }
    return decoded;
  }
}

class XdrLedgerEntryChange {
  XdrLedgerEntryChange(this._type);

  XdrLedgerEntryChangeType _type;

  XdrLedgerEntryChangeType get discriminant => this._type;

  set discriminant(XdrLedgerEntryChangeType value) => this._type = value;

  XdrLedgerEntry? _created;

  XdrLedgerEntry? get created => this._created;

  set created(XdrLedgerEntry? value) => this._created = value;

  XdrLedgerEntry? _updated;

  XdrLedgerEntry? get updated => this._updated;

  set updated(XdrLedgerEntry? value) => this._updated = value;

  XdrLedgerKey? _removed;

  XdrLedgerKey? get removed => this._removed;

  set removed(XdrLedgerKey? value) => this._removed = value;

  XdrLedgerEntry? _state;

  XdrLedgerEntry? get state => this._state;

  set state(XdrLedgerEntry? value) => this._state = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerEntryChange encodedLedgerEntryChange) {
    stream.writeInt(encodedLedgerEntryChange.discriminant.value);
    switch (encodedLedgerEntryChange.discriminant) {
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.created!);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.updated!);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED:
        XdrLedgerKey.encode(stream, encodedLedgerEntryChange.removed!);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.state!);
        break;
    }
  }

  static XdrLedgerEntryChange decode(XdrDataInputStream stream) {
    XdrLedgerEntryChange decodedLedgerEntryChange =
        XdrLedgerEntryChange(XdrLedgerEntryChangeType.decode(stream));
    switch (decodedLedgerEntryChange.discriminant) {
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED:
        decodedLedgerEntryChange.created = XdrLedgerEntry.decode(stream);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED:
        decodedLedgerEntryChange.updated = XdrLedgerEntry.decode(stream);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED:
        decodedLedgerEntryChange.removed = XdrLedgerKey.decode(stream);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE:
        decodedLedgerEntryChange.state = XdrLedgerEntry.decode(stream);
        break;
    }
    return decodedLedgerEntryChange;
  }
}

class XdrLedgerEntryChanges {
  XdrLedgerEntryChanges(this._ledgerEntryChanges);

  List<XdrLedgerEntryChange> _ledgerEntryChanges;

  List<XdrLedgerEntryChange> get ledgerEntryChanges => this._ledgerEntryChanges;

  set ledgerEntryChanges(List<XdrLedgerEntryChange> value) =>
      this._ledgerEntryChanges = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerEntryChanges encodedLedgerEntryChanges) {
    int ledgerEntryChangesSize =
        encodedLedgerEntryChanges.ledgerEntryChanges.length;
    stream.writeInt(ledgerEntryChangesSize);
    for (int i = 0; i < ledgerEntryChangesSize; i++) {
      XdrLedgerEntryChange.encode(
          stream, encodedLedgerEntryChanges.ledgerEntryChanges[i]);
    }
  }

  static XdrLedgerEntryChanges decode(XdrDataInputStream stream) {
    int ledgerEntryChangesSize = stream.readInt();
    List<XdrLedgerEntryChange> ledgerEntryChanges =
        List<XdrLedgerEntryChange>.empty(growable: true);
    for (int i = 0; i < ledgerEntryChangesSize; i++) {
      ledgerEntryChanges.add(XdrLedgerEntryChange.decode(stream));
    }
    return XdrLedgerEntryChanges(ledgerEntryChanges);
  }
}

class XdrLedgerHeaderHistoryEntry {
  XdrLedgerHeaderHistoryEntry(this._hash, this._header, this._ext);

  XdrHash _hash;

  XdrHash get hash => this._hash;

  set hash(XdrHash value) => this._hash = value;

  XdrLedgerHeader _header;

  XdrLedgerHeader get header => this._header;

  set header(XdrLedgerHeader value) => this._header = value;

  XdrLedgerHeaderHistoryEntryExt _ext;

  XdrLedgerHeaderHistoryEntryExt get ext => this._ext;

  set ext(XdrLedgerHeaderHistoryEntryExt value) => this._ext = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerHeaderHistoryEntry encodedLedgerHeaderHistoryEntry) {
    XdrHash.encode(stream, encodedLedgerHeaderHistoryEntry.hash);
    XdrLedgerHeader.encode(stream, encodedLedgerHeaderHistoryEntry.header);
    XdrLedgerHeaderHistoryEntryExt.encode(
        stream, encodedLedgerHeaderHistoryEntry.ext);
  }

  static XdrLedgerHeaderHistoryEntry decode(XdrDataInputStream stream) {
    XdrHash hash = XdrHash.decode(stream);
    XdrLedgerHeader header = XdrLedgerHeader.decode(stream);
    XdrLedgerHeaderHistoryEntryExt ext =
        XdrLedgerHeaderHistoryEntryExt.decode(stream);
    return XdrLedgerHeaderHistoryEntry(hash, header, ext);
  }
}

class XdrLedgerHeaderHistoryEntryExt {
  XdrLedgerHeaderHistoryEntryExt(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerHeaderHistoryEntryExt encodedLedgerHeaderHistoryEntryExt) {
    stream.writeInt(encodedLedgerHeaderHistoryEntryExt.discriminant);
    switch (encodedLedgerHeaderHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrLedgerHeaderHistoryEntryExt decode(XdrDataInputStream stream) {
    XdrLedgerHeaderHistoryEntryExt decodedLedgerHeaderHistoryEntryExt =
        XdrLedgerHeaderHistoryEntryExt(stream.readInt());
    switch (decodedLedgerHeaderHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedLedgerHeaderHistoryEntryExt;
  }
}

class XdrLiquidityPoolType {
  final _value;

  const XdrLiquidityPoolType._internal(this._value);

  toString() => 'XdrLiquidityPoolType.$_value';

  XdrLiquidityPoolType(this._value);

  get value => this._value;

  static const LIQUIDITY_POOL_CONSTANT_PRODUCT =
      const XdrLiquidityPoolType._internal(0);

  static XdrLiquidityPoolType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return LIQUIDITY_POOL_CONSTANT_PRODUCT;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrLiquidityPoolType value) {
    stream.writeInt(value.value);
  }
}

class XdrLiquidityPoolConstantProductParameters {
  XdrLiquidityPoolConstantProductParameters(
      this._assetA, this._assetB, this._fee);

  XdrAsset _assetA;
  XdrAsset get assetA => this._assetA;
  set assetA(XdrAsset value) => this._assetA = value;

  XdrAsset _assetB;
  XdrAsset get assetB => this._assetB;
  set assetB(XdrAsset value) => this._assetB = value;

  XdrInt32 _fee;
  XdrInt32 get fee => this._fee;
  set fee(XdrInt32 value) => this._fee = value;

  static XdrInt32 LIQUIDITY_POOL_FEE_V18 = XdrInt32(30);

  static void encode(XdrDataOutputStream stream,
      XdrLiquidityPoolConstantProductParameters params) {
    XdrAsset.encode(stream, params.assetA);
    XdrAsset.encode(stream, params.assetB);
    XdrInt32.encode(stream, params.fee);
  }

  static XdrLiquidityPoolConstantProductParameters decode(
      XdrDataInputStream stream) {
    XdrAsset assetA = XdrAsset.decode(stream);
    XdrAsset assetB = XdrAsset.decode(stream);
    XdrInt32 fee = XdrInt32.decode(stream);
    return XdrLiquidityPoolConstantProductParameters(assetA, assetB, fee);
  }
}

class XdrConstantProduct {
  XdrConstantProduct(this._params, this._reserveA, this._reserveB,
      this._totalPoolShares, this._poolSharesTrustLineCount);

  XdrLiquidityPoolConstantProductParameters _params;
  XdrLiquidityPoolConstantProductParameters get params => this._params;
  set params(XdrLiquidityPoolConstantProductParameters value) =>
      this._params = value;

  XdrInt64 _reserveA;
  XdrInt64 get reserveA => this._reserveA;
  set reserveA(XdrInt64 value) => this._reserveA = value;

  XdrInt64 _reserveB;
  XdrInt64 get reserveB => this._reserveB;
  set reserveB(XdrInt64 value) => this._reserveB = value;

  XdrInt64 _totalPoolShares;
  XdrInt64 get totalPoolShares => this._totalPoolShares;
  set totalPoolShares(XdrInt64 value) => this._totalPoolShares = value;

  XdrInt64 _poolSharesTrustLineCount;
  XdrInt64 get poolSharesTrustLineCount => this._poolSharesTrustLineCount;
  set poolSharesTrustLineCount(XdrInt64 value) =>
      this._poolSharesTrustLineCount = value;

  static void encode(XdrDataOutputStream stream, XdrConstantProduct prod) {
    XdrLiquidityPoolConstantProductParameters.encode(stream, prod.params);
    XdrInt64.encode(stream, prod.reserveA);
    XdrInt64.encode(stream, prod.reserveB);
    XdrInt64.encode(stream, prod.totalPoolShares);
    XdrInt64.encode(stream, prod.poolSharesTrustLineCount);
  }

  static XdrConstantProduct decode(XdrDataInputStream stream) {
    XdrLiquidityPoolConstantProductParameters params =
        XdrLiquidityPoolConstantProductParameters.decode(stream);
    XdrInt64 reserveA = XdrInt64.decode(stream);
    XdrInt64 reserveB = XdrInt64.decode(stream);
    XdrInt64 totalPoolShares = XdrInt64.decode(stream);
    XdrInt64 poolSharesTrustLineCount = XdrInt64.decode(stream);
    return XdrConstantProduct(
        params, reserveA, reserveB, totalPoolShares, poolSharesTrustLineCount);
  }
}

class XdrLiquidityPoolBody {
  XdrLiquidityPoolBody(this._type);

  XdrLiquidityPoolType _type;
  XdrLiquidityPoolType get discriminant => this._type;
  set discriminant(XdrLiquidityPoolType value) => this._type = value;

  XdrConstantProduct? _constantProduct;
  XdrConstantProduct? get constantProduct => this._constantProduct;
  set constantProduct(XdrConstantProduct? value) =>
      this._constantProduct = value;

  static void encode(XdrDataOutputStream stream, XdrLiquidityPoolBody encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        XdrConstantProduct.encode(stream, encoded.constantProduct!);
        break;
    }
  }

  static XdrLiquidityPoolBody decode(XdrDataInputStream stream) {
    XdrLiquidityPoolBody decoded =
        XdrLiquidityPoolBody(XdrLiquidityPoolType.decode(stream));
    switch (decoded.discriminant) {
      case XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT:
        decoded.constantProduct = XdrConstantProduct.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrLiquidityPoolEntry {
  XdrLiquidityPoolEntry(this._liquidityPoolID, this._body);

  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrLiquidityPoolBody _body;
  XdrLiquidityPoolBody get body => this._body;
  set body(XdrLiquidityPoolBody value) => this._body = value;

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolEntry encoded) {
    XdrHash.encode(stream, encoded.liquidityPoolID);
    XdrLiquidityPoolBody.encode(stream, encoded.body);
  }

  static XdrLiquidityPoolEntry decode(XdrDataInputStream stream) {
    return XdrLiquidityPoolEntry(
        XdrHash.decode(stream), XdrLiquidityPoolBody.decode(stream));
  }
}

class XdrContractDataEntry {
  XdrContractDataEntry(this._contractID, this._key, this._val);

  XdrHash _contractID;
  XdrHash get contractID => this._contractID;
  set contractID(XdrHash value) => this._contractID = value;

  XdrSCVal _key;
  XdrSCVal get key => this._key;
  set key(XdrSCVal value) => this._key = value;

  XdrSCVal _val;
  XdrSCVal get val => this._val;
  set val(XdrSCVal value) => this._val = value;

  static void encode(XdrDataOutputStream stream, XdrContractDataEntry encoded) {
    XdrHash.encode(stream, encoded.contractID);
    XdrSCVal.encode(stream, encoded.key);
    XdrSCVal.encode(stream, encoded.val);
  }

  static XdrContractDataEntry decode(XdrDataInputStream stream) {
    return XdrContractDataEntry(XdrHash.decode(stream), XdrSCVal.decode(stream),
        XdrSCVal.decode(stream));
  }
}

class XdrContractCodeEntry {
  XdrContractCodeEntry(this._ext, this._cHash, this._code);

  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrHash _cHash;
  XdrHash get cHash => this._cHash;
  set cHash(XdrHash value) => this._cHash = value;

  XdrDataValue _code;
  XdrDataValue get code => this._code;
  set code(XdrDataValue value) => this._code = value;

  static void encode(XdrDataOutputStream stream, XdrContractCodeEntry encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrHash.encode(stream, encoded.cHash);
    XdrDataValue.encode(stream, encoded.code);
  }

  static XdrContractCodeEntry decode(XdrDataInputStream stream) {
    return XdrContractCodeEntry(XdrExtensionPoint.decode(stream),
        XdrHash.decode(stream), XdrDataValue.decode(stream));
  }
}

class XdrConfigSettingType {
  final _value;
  const XdrConfigSettingType._internal(this._value);
  toString() => 'ConfigSettingType..$_value';

  XdrConfigSettingType(this._value);

  get value => this._value;

  static const CONFIG_SETTING_TYPE_UINT32 =
      const XdrConfigSettingType._internal(0);

  static XdrConfigSettingType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONFIG_SETTING_TYPE_UINT32;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrConfigSettingType value) {
    stream.writeInt(value.value);
  }
}

class XdrConfigSettingID {
  final _value;
  const XdrConfigSettingID._internal(this._value);
  toString() => 'ConfigSettingID..$_value';

  XdrConfigSettingID(this._value);

  get value => this._value;

  static const CONFIG_SETTING_CONTRACT_MAX_SIZE =
      const XdrConfigSettingID._internal(0);

  static XdrConfigSettingID decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONFIG_SETTING_CONTRACT_MAX_SIZE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrConfigSettingID value) {
    stream.writeInt(value.value);
  }
}

class XdrConfigSetting {
  XdrConfigSettingType _type;
  XdrConfigSettingType get discriminant => this._type;
  set discriminant(XdrConfigSettingType value) => this._type = value;

  XdrUint32? _uint32Val;
  XdrUint32? get uint32Val => this._uint32Val;
  set uint32Val(XdrUint32? value) => this._uint32Val = value;

  XdrConfigSetting(this._type);

  static void encode(XdrDataOutputStream stream, XdrConfigSetting encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrConfigSettingType.CONFIG_SETTING_TYPE_UINT32:
        XdrUint32.encode(stream, encoded.uint32Val);
        break;
    }
  }

  static XdrConfigSetting decode(XdrDataInputStream stream) {
    XdrConfigSetting decoded =
        XdrConfigSetting(XdrConfigSettingType.decode(stream));
    switch (decoded.discriminant) {
      case XdrConfigSettingType.CONFIG_SETTING_TYPE_UINT32:
        decoded.uint32Val = XdrUint32.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrConfigSettingEntry {
  XdrConfigSettingEntry(this._ext, this._configSettingID, this._configSetting);

  XdrConfigSettingEntryExt _ext;
  XdrConfigSettingEntryExt get ext => this._ext;
  set ext(XdrConfigSettingEntryExt value) => this._ext = value;

  XdrConfigSettingID _configSettingID;
  XdrConfigSettingID get configSettingID => this._configSettingID;
  set configSettingID(XdrConfigSettingID value) => this._configSettingID = value;

  XdrConfigSetting _configSetting;
  XdrConfigSetting get configSetting => this._configSetting;
  set configSetting(XdrConfigSetting value) => this._configSetting = value;

  static void encode(XdrDataOutputStream stream, XdrConfigSettingEntry encoded) {

    XdrConfigSettingEntryExt.encode(stream, encoded.ext);
    XdrConfigSettingID.encode(stream, encoded.configSettingID);
    XdrConfigSetting.encode(stream, encoded.configSetting);
  }

  static XdrConfigSettingEntry decode(XdrDataInputStream stream) {
    return XdrConfigSettingEntry(XdrConfigSettingEntryExt.decode(stream),
        XdrConfigSettingID.decode(stream), XdrConfigSetting.decode(stream));
  }
}

class XdrConfigSettingEntryExt {
  XdrConfigSettingEntryExt(this._v);

  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream, XdrConfigSettingEntryExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
    }
  }

  static XdrConfigSettingEntryExt decode(XdrDataInputStream stream) {
    XdrConfigSettingEntryExt decoded = XdrConfigSettingEntryExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
    }
    return decoded;
  }
}