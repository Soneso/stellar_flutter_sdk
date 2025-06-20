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
import 'xdr_transaction.dart';

class XdrLedgerEntryChangeType {
  final _value;

  const XdrLedgerEntryChangeType._internal(this._value);

  toString() => 'LedgerEntryChangeType.$_value';

  XdrLedgerEntryChangeType(this._value);

  get value => this._value;

  // entry was added to the ledger
  static const LEDGER_ENTRY_CREATED =
      const XdrLedgerEntryChangeType._internal(0);

  // entry was modified in the ledger
  static const LEDGER_ENTRY_UPDATED =
      const XdrLedgerEntryChangeType._internal(1);

  // entry was removed from the ledger
  static const LEDGER_ENTRY_REMOVED =
      const XdrLedgerEntryChangeType._internal(2);

  // value of the entry
  static const LEDGER_ENTRY_STATE = const XdrLedgerEntryChangeType._internal(3);

  // archived entry was restored in the ledger
  static const LEDGER_ENTRY_RESTORED =
      const XdrLedgerEntryChangeType._internal(4);

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
      case 4:
        return LEDGER_ENTRY_RESTORED;
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
  static const TTL = const XdrLedgerEntryType._internal(9);

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
      case 9:
        return TTL;
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
        XdrInt64.encode(stream, encodedClaimPredicate.absBefore!);
        break;
      case XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME:
        XdrInt64.encode(stream, encodedClaimPredicate.relBefore!);
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

  static XdrClaimableBalanceID forId(String claimableBalanceId) {
    XdrClaimableBalanceID bId = XdrClaimableBalanceID(
        XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);

    Uint8List bytes = Util.hexToBytes(claimableBalanceId.toUpperCase());
    if (bytes.length < 32) {
      bytes = Util.paddedByteArray(bytes, 32);
    } else if (bytes.length > 32) {
      bytes = bytes.sublist(bytes.length - 32, bytes.length);
    }

    bId.v0 = XdrHash(bytes);
    return bId;
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
    return XdrClaimableBalanceEntryExtV1(v, flags);
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
  static const LEDGER_UPGRADE_FLAGS = const XdrLedgerUpgradeType._internal(5);
  static const LEDGER_UPGRADE_CONFIG = const XdrLedgerUpgradeType._internal(6);
  static const LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE =
      const XdrLedgerUpgradeType._internal(7);

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
      case 5:
        return LEDGER_UPGRADE_FLAGS;
      case 6:
        return LEDGER_UPGRADE_CONFIG;
      case 7:
        return LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE;
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

class XdrLedgerKeyContractData {
  XdrSCAddress _contract;
  XdrSCAddress get contract => this._contract;
  set contract(XdrSCAddress value) => this._contract = value;

  XdrSCVal _key;
  XdrSCVal get key => this._key;
  set key(XdrSCVal value) => this._key = value;

  XdrContractDataDurability _durability;
  XdrContractDataDurability get durability => this._durability;
  set durability(XdrContractDataDurability value) => this._durability = value;

  XdrLedgerKeyContractData(this._contract, this._key, this._durability);

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyContractData encoded) {
    XdrSCAddress.encode(stream, encoded.contract);
    XdrSCVal.encode(stream, encoded.key);
    XdrContractDataDurability.encode(stream, encoded.durability);
  }

  static XdrLedgerKeyContractData decode(XdrDataInputStream stream) {
    XdrLedgerKeyContractData decodedLedgerKeyContractData =
        XdrLedgerKeyContractData(XdrSCAddress.decode(stream),
            XdrSCVal.decode(stream), XdrContractDataDurability.decode(stream));
    return decodedLedgerKeyContractData;
  }
}

class XdrLedgerKeyContractCode {
  XdrHash _hash;
  XdrHash get hash => this._hash;
  set hash(XdrHash value) => this._hash = value;

  XdrLedgerKeyContractCode(this._hash);

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyContractCode encoded) {
    XdrHash.encode(stream, encoded.hash);
  }

  static XdrLedgerKeyContractCode decode(XdrDataInputStream stream) {
    XdrLedgerKeyContractCode decodedLedgerKeyContractCode =
        XdrLedgerKeyContractCode(XdrHash.decode(stream));
    return decodedLedgerKeyContractCode;
  }
}

class XdrLedgerKeyTTL {
  XdrHash _hashKey;
  XdrHash get hashKey => this._hashKey;
  set hash(XdrHash value) => this._hashKey = value;

  XdrLedgerKeyTTL(this._hashKey);

  static void encode(XdrDataOutputStream stream, XdrLedgerKeyTTL encoded) {
    XdrHash.encode(stream, encoded.hashKey);
  }

  static XdrLedgerKeyTTL decode(XdrDataInputStream stream) {
    XdrLedgerKeyTTL decoded = XdrLedgerKeyTTL(XdrHash.decode(stream));
    return decoded;
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

  XdrConfigSettingID? _configSetting;
  XdrConfigSettingID? get configSetting => this._configSetting;
  set configSetting(XdrConfigSettingID? value) => this._configSetting = value;

  XdrLedgerKeyContractData? _contractData;
  XdrLedgerKeyContractData? get contractData => this._contractData;
  set contractData(XdrLedgerKeyContractData? value) =>
      this._contractData = value;

  XdrLedgerKeyContractCode? _contractCode;
  XdrLedgerKeyContractCode? get contractCode => this._contractCode;
  set contractCode(XdrLedgerKeyContractCode? value) =>
      this._contractCode = value;

  XdrLedgerKeyTTL? _ttl;
  XdrLedgerKeyTTL? get ttl => this._ttl;
  set ttl(XdrLedgerKeyTTL? value) => this._ttl = value;

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
        XdrLedgerKeyContractData.encode(stream, encodedLedgerKey.contractData!);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        XdrLedgerKeyContractCode.encode(stream, encodedLedgerKey.contractCode!);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        XdrConfigSettingID.encode(stream, encodedLedgerKey.configSetting!);
        break;
      case XdrLedgerEntryType.TTL:
        XdrLedgerKeyTTL.encode(stream, encodedLedgerKey.ttl!);
        break;
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
        decodedLedgerKey.contractData = XdrLedgerKeyContractData.decode(stream);
        break;
      case XdrLedgerEntryType.CONTRACT_CODE:
        decodedLedgerKey.contractCode = XdrLedgerKeyContractCode.decode(stream);
        break;
      case XdrLedgerEntryType.CONFIG_SETTING:
        decodedLedgerKey.configSetting = XdrConfigSettingID.decode(stream);
        break;
      case XdrLedgerEntryType.TTL:
        decodedLedgerKey.ttl = XdrLedgerKeyTTL.decode(stream);
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

  static XdrLedgerKey forAccountId(String accountId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
    result.account = XdrLedgerKeyAccount(XdrAccountID.forAccountId(accountId));
    return result;
  }

  static XdrLedgerKey forTrustLine(String accountId, XdrAsset asset) {
    var result = XdrLedgerKey(XdrLedgerEntryType.TRUSTLINE);
    var trustLine = XdrLedgerKeyTrustLine(XdrAccountID.forAccountId(accountId),
        XdrTrustlineAsset.fromXdrAsset(asset));
    result.trustLine = trustLine;
    return result;
  }

  static XdrLedgerKey forOffer(String sellerId, int offerId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.OFFER);
    result.offer = XdrLedgerKeyOffer.forOfferId(sellerId, offerId);
    return result;
  }

  static XdrLedgerKey forData(String accountId, String dataName) {
    var result = XdrLedgerKey(XdrLedgerEntryType.DATA);
    result.data = XdrLedgerKeyData.forDataName(accountId, dataName);
    return result;
  }

  static XdrLedgerKey forClaimableBalance(String claimableBalanceId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CLAIMABLE_BALANCE);
    result.balanceID = XdrClaimableBalanceID.forId(claimableBalanceId);
    return result;
  }

  static XdrLedgerKey forLiquidityPool(String liquidityPoolId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.LIQUIDITY_POOL);
    result.liquidityPoolID = XdrHash(Util.hexToBytes(liquidityPoolId));
    return result;
  }

  static XdrLedgerKey forContractData(XdrSCAddress contractAddress,
      XdrSCVal key, XdrContractDataDurability durability) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
    result.contractData =
        XdrLedgerKeyContractData(contractAddress, key, durability);
    return result;
  }

  static XdrLedgerKey forContractCode(Uint8List code) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
    result.contractCode = XdrLedgerKeyContractCode(XdrHash(code));
    return result;
  }

  static XdrLedgerKey forConfigSetting(XdrConfigSettingID configSettingId) {
    var result = XdrLedgerKey(XdrLedgerEntryType.CONFIG_SETTING);
    result.configSetting = configSettingId;
    return result;
  }

  static XdrLedgerKey forTTL(Uint8List keyHash) {
    var result = XdrLedgerKey(XdrLedgerEntryType.TTL);
    result.ttl = XdrLedgerKeyTTL(XdrHash(keyHash));
    return result;
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

  static XdrLedgerKeyOffer forOfferId(String sellerAccountId, int offerId) {
    return XdrLedgerKeyOffer(
        XdrAccountID.forAccountId(sellerAccountId), XdrUint64(offerId));
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

  static XdrLedgerKeyData forDataName(String accountId, String dataName) {
    return XdrLedgerKeyData(
        XdrAccountID.forAccountId(accountId), XdrString64(dataName));
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

  XdrUint32? _newFlags;
  XdrUint32? get newFlags => this._newFlags;
  set newFlags(XdrUint32? value) => this._newFlags = value;

  XdrConfigUpgradeSetKey? _newConfig;
  XdrConfigUpgradeSetKey? get newConfig => this._newConfig;
  set newConfig(XdrConfigUpgradeSetKey? value) => this._newConfig = value;

  XdrUint32? _newMaxSorobanTxSetSize;
  XdrUint32? get newMaxSorobanTxSetSize => this._newMaxSorobanTxSetSize;
  set newMaxSorobanTxSetSize(XdrUint32? value) =>
      this._newMaxSorobanTxSetSize = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerUpgrade encodedLedgerUpgrade) {
    stream.writeInt(encodedLedgerUpgrade.discriminant.value);
    switch (encodedLedgerUpgrade.discriminant) {
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_VERSION:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newLedgerVersion!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_FEE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newBaseFee!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_TX_SET_SIZE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newMaxTxSetSize!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_BASE_RESERVE:
        XdrUint32.encode(stream, encodedLedgerUpgrade._newBaseReserve!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_FLAGS:
        XdrUint32.encode(stream, encodedLedgerUpgrade.newFlags!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_CONFIG:
        XdrConfigUpgradeSetKey.encode(stream, encodedLedgerUpgrade.newConfig!);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE:
        XdrUint32.encode(stream, encodedLedgerUpgrade.newMaxSorobanTxSetSize!);
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
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_FLAGS:
        decodedLedgerUpgrade.newFlags = XdrUint32.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_CONFIG:
        decodedLedgerUpgrade.newConfig = XdrConfigUpgradeSetKey.decode(stream);
        break;
      case XdrLedgerUpgradeType.LEDGER_UPGRADE_MAX_SOROBAN_TX_SET_SIZE:
        decodedLedgerUpgrade.newMaxSorobanTxSetSize = XdrUint32.decode(stream);
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
  set contractData(XdrContractDataEntry? value) => this._contractData = value;

  XdrContractCodeEntry? _contractCode;
  XdrContractCodeEntry? get contractCode => this._contractCode;
  set contractCode(XdrContractCodeEntry? value) => this._contractCode = value;

  XdrConfigSettingEntry? _configSetting;
  XdrConfigSettingEntry? get configSetting => this._configSetting;
  set configSetting(XdrConfigSettingEntry? value) =>
      this._configSetting = value;

  XdrTTLEntry? _expiration;
  XdrTTLEntry? get expiration => this._expiration;
  set expiration(XdrTTLEntry? value) => this._expiration = value;

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
      case XdrLedgerEntryType.TTL:
        XdrTTLEntry.encode(stream, encodedLedgerEntryData.expiration!);
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
      case XdrLedgerEntryType.TTL:
        decodedLedgerEntryData.expiration = XdrTTLEntry.decode(stream);
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

  XdrLedgerEntry? _restored;
  XdrLedgerEntry? get restored => this._restored;
  set restored(XdrLedgerEntry? value) => this._restored = value;

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
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.restored!);
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
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED:
        decodedLedgerEntryChange.restored = XdrLedgerEntry.decode(stream);
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

  static XdrLedgerEntryChanges fromBase64EncodedXdrString(String xdr) {
    Uint8List bytes = base64Decode(xdr);
    return XdrLedgerEntryChanges.decode(XdrDataInputStream(bytes));
  }

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerEntryChanges.encode(xdrOutputStream, this);
    return base64Encode(xdrOutputStream.bytes);
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

class XdrContractDataDurability {
  final _value;
  const XdrContractDataDurability._internal(this._value);
  toString() => 'ContractDataDurability.$_value';
  XdrContractDataDurability(this._value);
  get value => this._value;

  static const TEMPORARY = const XdrContractDataDurability._internal(0);
  static const PERSISTENT = const XdrContractDataDurability._internal(1);

  static XdrContractDataDurability decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return TEMPORARY;
      case 1:
        return PERSISTENT;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrContractDataDurability value) {
    stream.writeInt(value.value);
  }
}

class XdrContractDataEntry {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrSCAddress _contract;
  XdrSCAddress get contract => this._contract;
  set contract(XdrSCAddress value) => this._contract = value;

  XdrSCVal _key;
  XdrSCVal get key => this._key;
  set key(XdrSCVal value) => this._key = value;

  XdrContractDataDurability _durability;
  XdrContractDataDurability get durability => this._durability;
  set durability(XdrContractDataDurability value) => this._durability = value;

  XdrSCVal _val;
  XdrSCVal get val => this._val;
  set val(XdrSCVal value) => this._val = value;

  XdrContractDataEntry(
      this._ext, this._contract, this._key, this._durability, this._val);

  static void encode(XdrDataOutputStream stream, XdrContractDataEntry encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrSCAddress.encode(stream, encoded.contract);
    XdrSCVal.encode(stream, encoded.key);
    XdrContractDataDurability.encode(stream, encoded.durability);
    XdrSCVal.encode(stream, encoded.val);
  }

  static XdrContractDataEntry decode(XdrDataInputStream stream) {
    return XdrContractDataEntry(
        XdrExtensionPoint.decode(stream),
        XdrSCAddress.decode(stream),
        XdrSCVal.decode(stream),
        XdrContractDataDurability.decode(stream),
        XdrSCVal.decode(stream));
  }
}

class XdrTTLEntry {
  XdrHash _keyHash;
  XdrHash get keyHash => this._keyHash;
  set keyHash(XdrHash value) => this._keyHash = value;

  XdrUint32 _liveUntilLedgerSeq;
  XdrUint32 get liveUntilLedgerSeq => this._liveUntilLedgerSeq;
  set liveUntilLedgerSeq(XdrUint32 value) => this._liveUntilLedgerSeq = value;

  XdrTTLEntry(this._keyHash, this._liveUntilLedgerSeq);

  static void encode(XdrDataOutputStream stream, XdrTTLEntry encoded) {
    XdrHash.encode(stream, encoded.keyHash);
    XdrUint32.encode(stream, encoded.liveUntilLedgerSeq);
  }

  static XdrTTLEntry decode(XdrDataInputStream stream) {
    return XdrTTLEntry(XdrHash.decode(stream), XdrUint32.decode(stream));
  }
}

class XdrContractCodeCostInputs {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrInt32 _nInstructions;
  XdrInt32 get nInstructions => this._nInstructions;
  set nInstructions(XdrInt32 value) => this._nInstructions = value;

  XdrInt32 _nFunctions;
  XdrInt32 get nFunctions => this._nFunctions;
  set nFunctions(XdrInt32 value) => this._nFunctions = value;

  XdrInt32 _nGlobals;
  XdrInt32 get nGlobals => this._nGlobals;
  set nGlobals(XdrInt32 value) => this._nGlobals = value;

  XdrInt32 _nTableEntries;
  XdrInt32 get nTableEntries => this._nTableEntries;
  set nTableEntries(XdrInt32 value) => this._nTableEntries = value;

  XdrInt32 _nTypes;
  XdrInt32 get nTypes => this._nTypes;
  set nTypes(XdrInt32 value) => this._nTypes = value;

  XdrInt32 _nDataSegments;
  XdrInt32 get nDataSegments => this._nDataSegments;
  set nDataSegments(XdrInt32 value) => this._nDataSegments = value;

  XdrInt32 _nElemSegments;
  XdrInt32 get nElemSegments => this._nElemSegments;
  set nElemSegments(XdrInt32 value) => this._nElemSegments = value;

  XdrInt32 _nImports;
  XdrInt32 get nImports => this._nImports;
  set nImports(XdrInt32 value) => this._nImports = value;

  XdrInt32 _nExports;
  XdrInt32 get nExports => this._nExports;
  set nExports(XdrInt32 value) => this._nExports = value;

  XdrInt32 _nDataSegmentBytes;
  XdrInt32 get nDataSegmentBytes => this._nDataSegmentBytes;
  set nDataSegmentBytes(XdrInt32 value) => this._nDataSegmentBytes = value;

  XdrContractCodeCostInputs(
      this._ext,
      this._nInstructions,
      this._nFunctions,
      this._nGlobals,
      this._nTableEntries,
      this._nTypes,
      this._nDataSegments,
      this._nElemSegments,
      this._nImports,
      this._nExports,
      this._nDataSegmentBytes);

  static void encode(
      XdrDataOutputStream stream, XdrContractCodeCostInputs encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrInt32.encode(stream, encoded.nInstructions);
    XdrInt32.encode(stream, encoded.nFunctions);
    XdrInt32.encode(stream, encoded.nGlobals);
    XdrInt32.encode(stream, encoded.nTableEntries);
    XdrInt32.encode(stream, encoded.nTypes);
    XdrInt32.encode(stream, encoded.nDataSegments);
    XdrInt32.encode(stream, encoded.nElemSegments);
    XdrInt32.encode(stream, encoded.nImports);
    XdrInt32.encode(stream, encoded.nExports);
    XdrInt32.encode(stream, encoded.nDataSegmentBytes);
  }

  static XdrContractCodeCostInputs decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrInt32 nInstructions = XdrInt32.decode(stream);
    XdrInt32 nFunctions = XdrInt32.decode(stream);
    XdrInt32 nGlobals = XdrInt32.decode(stream);
    XdrInt32 nTableEntries = XdrInt32.decode(stream);
    XdrInt32 nTypes = XdrInt32.decode(stream);
    XdrInt32 nDataSegments = XdrInt32.decode(stream);
    XdrInt32 nElemSegments = XdrInt32.decode(stream);
    XdrInt32 nImports = XdrInt32.decode(stream);
    XdrInt32 nExports = XdrInt32.decode(stream);
    XdrInt32 nDataSegmentBytes = XdrInt32.decode(stream);

    return XdrContractCodeCostInputs(
        ext,
        nInstructions,
        nFunctions,
        nGlobals,
        nTableEntries,
        nTypes,
        nDataSegments,
        nElemSegments,
        nImports,
        nExports,
        nDataSegmentBytes);
  }
}

class XdrContractCodeEntryExtV1 {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrContractCodeCostInputs _costInputs;
  XdrContractCodeCostInputs get costInputs => this._costInputs;
  set costInputs(XdrContractCodeCostInputs value) => this._costInputs = value;

  XdrContractCodeEntryExtV1(this._ext, this._costInputs);

  static void encode(
      XdrDataOutputStream stream, XdrContractCodeEntryExtV1 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrContractCodeCostInputs.encode(stream, encoded.costInputs);
  }

  static XdrContractCodeEntryExtV1 decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrContractCodeCostInputs costInputs =
        XdrContractCodeCostInputs.decode(stream);

    return XdrContractCodeEntryExtV1(ext, costInputs);
  }
}

class XdrContractCodeEntryExt {
  XdrContractCodeEntryExt(this._v);
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrContractCodeEntryExtV1? _v1;
  XdrContractCodeEntryExtV1? get v1 => this._v1;
  set v1(XdrContractCodeEntryExtV1? value) => this._v1 = value;

  static void encode(
      XdrDataOutputStream stream, XdrContractCodeEntryExt encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 1:
        XdrContractCodeEntryExtV1.encode(stream, encoded.v1!);
        break;
    }
  }

  static XdrContractCodeEntryExt decode(XdrDataInputStream stream) {
    XdrContractCodeEntryExt decoded = XdrContractCodeEntryExt(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 1:
        decoded.v1 = XdrContractCodeEntryExtV1.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrContractCodeEntry {
  XdrContractCodeEntryExt _ext;
  XdrContractCodeEntryExt get ext => this._ext;
  set ext(XdrContractCodeEntryExt value) => this._ext = value;

  XdrHash _cHash;
  XdrHash get cHash => this._cHash;
  set cHash(XdrHash value) => this._cHash = value;

  XdrDataValue _code;
  XdrDataValue get code => this._code;
  set code(XdrDataValue value) => this._code = value;

  XdrContractCodeEntry(this._ext, this._cHash, this._code);

  static void encode(XdrDataOutputStream stream, XdrContractCodeEntry encoded) {
    XdrContractCodeEntryExt.encode(stream, encoded.ext);
    XdrHash.encode(stream, encoded.cHash);
    XdrDataValue.encode(stream, encoded.code);
  }

  static XdrContractCodeEntry decode(XdrDataInputStream stream) {
    return XdrContractCodeEntry(XdrContractCodeEntryExt.decode(stream),
        XdrHash.decode(stream), XdrDataValue.decode(stream));
  }
}

class XdrConfigSettingID {
  final _value;
  const XdrConfigSettingID._internal(this._value);
  toString() => 'ConfigSettingID..$_value';

  XdrConfigSettingID(this._value);
  get value => this._value;

  static const CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES =
      const XdrConfigSettingID._internal(0);
  static const CONFIG_SETTING_CONTRACT_COMPUTE_V0 =
      const XdrConfigSettingID._internal(1);
  static const CONFIG_SETTING_CONTRACT_LEDGER_COST_V0 =
      const XdrConfigSettingID._internal(2);
  static const CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0 =
      const XdrConfigSettingID._internal(3);
  static const CONFIG_SETTING_CONTRACT_EVENTS_V0 =
      const XdrConfigSettingID._internal(4);
  static const CONFIG_SETTING_CONTRACT_BANDWIDTH_V0 =
      const XdrConfigSettingID._internal(5);
  static const CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS =
      const XdrConfigSettingID._internal(6);
  static const CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES =
      const XdrConfigSettingID._internal(7);
  static const CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES =
      const XdrConfigSettingID._internal(8);
  static const CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES =
      const XdrConfigSettingID._internal(9);
  static const CONFIG_SETTING_STATE_ARCHIVAL =
      const XdrConfigSettingID._internal(10);
  static const CONFIG_SETTING_CONTRACT_EXECUTION_LANES =
      const XdrConfigSettingID._internal(11);
  static const CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW =
      const XdrConfigSettingID._internal(12);
  static const CONFIG_SETTING_EVICTION_ITERATOR =
      const XdrConfigSettingID._internal(13);
  static const CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0 =
      const XdrConfigSettingID._internal(14);
  static const CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0 =
      const XdrConfigSettingID._internal(15);
  static const CONFIG_SETTING_SCP_TIMING =
      const XdrConfigSettingID._internal(16);

  static XdrConfigSettingID decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES;
      case 1:
        return CONFIG_SETTING_CONTRACT_COMPUTE_V0;
      case 2:
        return CONFIG_SETTING_CONTRACT_LEDGER_COST_V0;
      case 3:
        return CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0;
      case 4:
        return CONFIG_SETTING_CONTRACT_EVENTS_V0;
      case 5:
        return CONFIG_SETTING_CONTRACT_BANDWIDTH_V0;
      case 6:
        return CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS;
      case 7:
        return CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES;
      case 8:
        return CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES;
      case 9:
        return CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES;
      case 10:
        return CONFIG_SETTING_STATE_ARCHIVAL;
      case 11:
        return CONFIG_SETTING_CONTRACT_EXECUTION_LANES;
      case 12:
        return CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW;
      case 13:
        return CONFIG_SETTING_EVICTION_ITERATOR;
      case 14:
        return CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0;
      case 15:
        return CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0;
      case 16:
        return CONFIG_SETTING_SCP_TIMING;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrConfigSettingID value) {
    stream.writeInt(value.value);
  }
}

class XdrStateArchivalSettings {
  XdrUint32 _maxEntryTTL;
  XdrUint32 get maxEntryTTL => this._maxEntryTTL;
  set maxEntryTTL(XdrUint32 value) => this.maxEntryTTL = value;

  XdrUint32 _minTemporaryTTL;
  XdrUint32 get minTemporaryTTL => this._minTemporaryTTL;
  set minTemporaryTTL(XdrUint32 value) => this._minTemporaryTTL = value;

  XdrUint32 _minPersistentTTL;
  XdrUint32 get minPersistentTTL => this._minPersistentTTL;
  set minPersistentTTL(XdrUint32 value) => this.minPersistentTTL = value;

  // rent_fee = wfee_rate_average / rent_rate_denominator_for_type
  XdrInt64 _persistentRentRateDenominator;
  XdrInt64 get persistentRentRateDenominator =>
      this._persistentRentRateDenominator;
  set persistentRentRateDenominator(XdrInt64 value) =>
      this._persistentRentRateDenominator = value;

  XdrInt64 _tempRentRateDenominator;
  XdrInt64 get tempRentRateDenominator => this._tempRentRateDenominator;
  set tempRentRateDenominator(XdrInt64 value) =>
      this._tempRentRateDenominator = value;

  // max number of entries that emit archival meta in a single ledger
  XdrUint32 _maxEntriesToArchive;
  XdrUint32 get maxEntriesToArchive => this._maxEntriesToArchive;
  set maxEntriesToArchive(XdrUint32 value) => this._maxEntriesToArchive = value;

  // Number of snapshots to use when calculating average live Soroban State size
  XdrUint32 _liveSorobanStateSizeWindowSampleSize;
  XdrUint32 get liveSorobanStateSizeWindowSampleSize =>
      this._liveSorobanStateSizeWindowSampleSize;
  set liveSorobanStateSizeWindowSampleSize(XdrUint32 value) =>
      this._liveSorobanStateSizeWindowSampleSize = value;

  // How often to sample the live Soroban State size for the average, in ledgers
  XdrUint32 _liveSorobanStateSizeWindowSamplePeriod;
  XdrUint32 get liveSorobanStateSizeWindowSamplePeriod =>
      this._liveSorobanStateSizeWindowSamplePeriod;
  set liveSorobanStateSizeWindowSamplePeriod(XdrUint32 value) =>
      this._liveSorobanStateSizeWindowSamplePeriod = value;

  // Maximum number of bytes that we scan for eviction per ledger
  XdrUint32 _evictionScanSize;
  XdrUint32 get evictionScanSize => this._evictionScanSize;
  set evictionScanSize(XdrUint32 value) => this._evictionScanSize = value;

  // Lowest BucketList level to be scanned to evict entries
  XdrUint32 _startingEvictionScanLevel;
  XdrUint32 get startingEvictionScanLevel => this._startingEvictionScanLevel;
  set startingEvictionScanLevel(XdrUint32 value) =>
      this._startingEvictionScanLevel = value;

  XdrStateArchivalSettings(
      this._maxEntryTTL,
      this._minTemporaryTTL,
      this._minPersistentTTL,
      this._persistentRentRateDenominator,
      this._tempRentRateDenominator,
      this._maxEntriesToArchive,
      this._liveSorobanStateSizeWindowSampleSize,
      this._liveSorobanStateSizeWindowSamplePeriod,
      this._evictionScanSize,
      this._startingEvictionScanLevel);

  static void encode(
      XdrDataOutputStream stream, XdrStateArchivalSettings encoded) {
    XdrUint32.encode(stream, encoded.maxEntryTTL);
    XdrUint32.encode(stream, encoded.minTemporaryTTL);
    XdrUint32.encode(stream, encoded.minPersistentTTL);
    XdrInt64.encode(stream, encoded.persistentRentRateDenominator);
    XdrInt64.encode(stream, encoded.tempRentRateDenominator);
    XdrUint32.encode(stream, encoded.maxEntriesToArchive);
    XdrUint32.encode(stream, encoded.liveSorobanStateSizeWindowSampleSize);
    XdrUint32.encode(stream, encoded.liveSorobanStateSizeWindowSamplePeriod);
    XdrUint32.encode(stream, encoded.evictionScanSize);
    XdrUint32.encode(stream, encoded.startingEvictionScanLevel);
  }

  static XdrStateArchivalSettings decode(XdrDataInputStream stream) {
    XdrUint32 maxEntryTTL = XdrUint32.decode(stream);
    XdrUint32 minTemporaryTTL = XdrUint32.decode(stream);
    XdrUint32 minPersistentTTL = XdrUint32.decode(stream);
    XdrInt64 persistentRentRateDenominator = XdrInt64.decode(stream);
    XdrInt64 tempRentRateDenominator = XdrInt64.decode(stream);
    XdrUint32 maxEntriesToArchive = XdrUint32.decode(stream);
    XdrUint32 liveSorobanStateSizeWindowSampleSize = XdrUint32.decode(stream);
    XdrUint32 liveSorobanStateSizeWindowSamplePeriod = XdrUint32.decode(stream);
    XdrUint32 evictionScanSize = XdrUint32.decode(stream);
    XdrUint32 startingEvictionScanLevel = XdrUint32.decode(stream);

    return XdrStateArchivalSettings(
        maxEntryTTL,
        minTemporaryTTL,
        minPersistentTTL,
        persistentRentRateDenominator,
        tempRentRateDenominator,
        maxEntriesToArchive,
        liveSorobanStateSizeWindowSampleSize,
        liveSorobanStateSizeWindowSamplePeriod,
        evictionScanSize,
        startingEvictionScanLevel);
  }
}

class XdrEvictionIterator {
  XdrUint32 _bucketListLevel;
  XdrUint32 get bucketListLevel => this._bucketListLevel;
  set bucketListLevel(XdrUint32 value) => this.bucketListLevel = value;

  bool _isCurrBucket;
  bool get isCurrBucket => this._isCurrBucket;
  set isCurrBucket(bool value) => this._isCurrBucket = value;

  XdrUint64 _bucketFileOffset;
  XdrUint64 get bucketFileOffset => this._bucketFileOffset;
  set bucketFileOffset(XdrUint64 value) => this._bucketFileOffset = value;

  XdrEvictionIterator(
      this._bucketListLevel, this._isCurrBucket, this._bucketFileOffset);

  static void encode(XdrDataOutputStream stream, XdrEvictionIterator encoded) {
    XdrUint32.encode(stream, encoded.bucketListLevel);
    stream.writeBoolean(encoded.isCurrBucket);
    XdrUint64.encode(stream, encoded.bucketFileOffset);
  }

  static XdrEvictionIterator decode(XdrDataInputStream stream) {
    XdrUint32 bucketListLevel = XdrUint32.decode(stream);
    bool isCurrBucket = stream.readBoolean();
    XdrUint64 bucketFileOffset = XdrUint64.decode(stream);

    return XdrEvictionIterator(bucketListLevel, isCurrBucket, bucketFileOffset);
  }
}

class XdrConfigSettingSCPTiming {
  XdrUint32 _ledgerTargetCloseTimeMilliseconds;
  XdrUint32 get ledgerTargetCloseTimeMilliseconds =>
      this._ledgerTargetCloseTimeMilliseconds;
  set ledgerTargetCloseTimeMilliseconds(XdrUint32 value) =>
      this.ledgerTargetCloseTimeMilliseconds = value;

  XdrUint32 _nominationTimeoutInitialMilliseconds;
  XdrUint32 get nominationTimeoutInitialMilliseconds =>
      this._nominationTimeoutInitialMilliseconds;
  set nominationTimeoutInitialMilliseconds(XdrUint32 value) =>
      this.nominationTimeoutInitialMilliseconds = value;

  XdrUint32 _nominationTimeoutIncrementMilliseconds;
  XdrUint32 get nominationTimeoutIncrementMilliseconds =>
      this._nominationTimeoutIncrementMilliseconds;
  set nominationTimeoutIncrementMilliseconds(XdrUint32 value) =>
      this.nominationTimeoutIncrementMilliseconds = value;

  XdrUint32 _ballotTimeoutInitialMilliseconds;
  XdrUint32 get ballotTimeoutInitialMilliseconds =>
      this._ballotTimeoutInitialMilliseconds;
  set ballotTimeoutInitialMilliseconds(XdrUint32 value) =>
      this.ballotTimeoutInitialMilliseconds = value;

  XdrUint32 _ballotTimeoutIncrementMilliseconds;
  XdrUint32 get ballotTimeoutIncrementMilliseconds =>
      this._ballotTimeoutIncrementMilliseconds;
  set ballotTimeoutIncrementMilliseconds(XdrUint32 value) =>
      this.ballotTimeoutIncrementMilliseconds = value;

  XdrConfigSettingSCPTiming(
      this._ledgerTargetCloseTimeMilliseconds,
      this._nominationTimeoutInitialMilliseconds,
      this._nominationTimeoutIncrementMilliseconds,
      this._ballotTimeoutInitialMilliseconds,
      this._ballotTimeoutIncrementMilliseconds);

  static void encode(
      XdrDataOutputStream stream, XdrConfigSettingSCPTiming encoded) {
    XdrUint32.encode(stream, encoded.ledgerTargetCloseTimeMilliseconds);
    XdrUint32.encode(stream, encoded.nominationTimeoutInitialMilliseconds);
    XdrUint32.encode(stream, encoded.nominationTimeoutIncrementMilliseconds);
    XdrUint32.encode(stream, encoded.ballotTimeoutInitialMilliseconds);
    XdrUint32.encode(stream, encoded.ballotTimeoutIncrementMilliseconds);
  }

  static XdrConfigSettingSCPTiming decode(XdrDataInputStream stream) {
    final ledgerTargetCloseTimeMilliseconds = XdrUint32.decode(stream);
    final nominationTimeoutInitialMilliseconds = XdrUint32.decode(stream);
    final nominationTimeoutIncrementMilliseconds = XdrUint32.decode(stream);
    final ballotTimeoutInitialMilliseconds = XdrUint32.decode(stream);
    final ballotTimeoutIncrementMilliseconds = XdrUint32.decode(stream);

    return XdrConfigSettingSCPTiming(
        ledgerTargetCloseTimeMilliseconds,
        nominationTimeoutInitialMilliseconds,
        nominationTimeoutIncrementMilliseconds,
        ballotTimeoutInitialMilliseconds,
        ballotTimeoutIncrementMilliseconds);
  }
}

// General “Soroban execution lane” settings
class XdrConfigSettingContractExecutionLanesV0 {
  // maximum number of Soroban transactions per ledger
  XdrUint32 _ledgerMaxTxCount;
  XdrUint32 get ledgerMaxTxCount => this._ledgerMaxTxCount;
  set ledgerMaxTxCount(XdrUint32 value) => this.ledgerMaxTxCount = value;

  XdrConfigSettingContractExecutionLanesV0(this._ledgerMaxTxCount);

  static void encode(XdrDataOutputStream stream,
      XdrConfigSettingContractExecutionLanesV0 encoded) {
    XdrUint32.encode(stream, encoded.ledgerMaxTxCount);
  }

  static XdrConfigSettingContractExecutionLanesV0 decode(
      XdrDataInputStream stream) {
    XdrUint32 ledgerMaxTxCount = XdrUint32.decode(stream);
    return XdrConfigSettingContractExecutionLanesV0(ledgerMaxTxCount);
  }
}

// Bandwidth related data settings for contracts.
// We consider bandwidth to only be consumed by the transaction envelopes, hence
// this concerns only transaction sizes.
class XdrConfigSettingContractBandwidthV0 {
  // Maximum sum of all transaction sizes in the ledger in bytes
  XdrUint32 _ledgerMaxTxsSizeBytes;
  XdrUint32 get ledgerMaxTxsSizeBytes => this._ledgerMaxTxsSizeBytes;
  set ledgerMaxTxsSizeBytes(XdrUint32 value) =>
      this._ledgerMaxTxsSizeBytes = value;

  // Maximum size in bytes for a transaction
  XdrUint32 _txMaxSizeBytes;
  XdrUint32 get txMaxSizeBytes => this._txMaxSizeBytes;
  set txMaxSizeBytes(XdrUint32 value) => this._txMaxSizeBytes = value;

  // Fee for 1 KB of transaction size
  XdrInt64 _feeTxSize1KB;
  XdrInt64 get feeTxSize1KB => this._feeTxSize1KB;
  set feeTxSize1KB(XdrInt64 value) => this._feeTxSize1KB = value;

  XdrConfigSettingContractBandwidthV0(
      this._ledgerMaxTxsSizeBytes, this._txMaxSizeBytes, this._feeTxSize1KB);

  static void encode(
      XdrDataOutputStream stream, XdrConfigSettingContractBandwidthV0 encoded) {
    XdrUint32.encode(stream, encoded.ledgerMaxTxsSizeBytes);
    XdrUint32.encode(stream, encoded.txMaxSizeBytes);
    XdrInt64.encode(stream, encoded.feeTxSize1KB);
  }

  static XdrConfigSettingContractBandwidthV0 decode(XdrDataInputStream stream) {
    XdrUint32 ledgerMaxTxsSizeBytes = XdrUint32.decode(stream);
    XdrUint32 txMaxSizeBytes = XdrUint32.decode(stream);
    XdrInt64 feeTxSize1KB = XdrInt64.decode(stream);
    return XdrConfigSettingContractBandwidthV0(
        ledgerMaxTxsSizeBytes, txMaxSizeBytes, feeTxSize1KB);
  }
}

// "Compute" settings for contracts (instructions and memory).
class XdrConfigSettingContractComputeV0 {
  // Maximum instructions per ledger
  XdrInt64 _ledgerMaxInstructions;
  XdrInt64 get ledgerMaxInstructions => this._ledgerMaxInstructions;
  set ledgerMaxInstructions(XdrInt64 value) =>
      this._ledgerMaxInstructions = value;

  // Maximum instructions per transaction
  XdrInt64 _txMaxInstructions;
  XdrInt64 get txMaxInstructions => this._txMaxInstructions;
  set txMaxInstructions(XdrInt64 value) => this._txMaxInstructions = value;

  // Cost of 10000 instructions
  XdrInt64 _feeRatePerInstructionsIncrement;
  XdrInt64 get feeRatePerInstructionsIncrement =>
      this._feeRatePerInstructionsIncrement;
  set feeRatePerInstructionsIncrement(XdrInt64 value) =>
      this._feeRatePerInstructionsIncrement = value;

  // Memory limit per transaction. Unlike instructions, there is no fee
  // for memory, just the limit.
  XdrUint32 _txMemoryLimit;
  XdrUint32 get txMemoryLimit => this._txMemoryLimit;
  set txMemoryLimit(XdrUint32 value) => this._txMemoryLimit = value;

  XdrConfigSettingContractComputeV0(
      this._ledgerMaxInstructions,
      this._txMaxInstructions,
      this._feeRatePerInstructionsIncrement,
      this._txMemoryLimit);

  static void encode(
      XdrDataOutputStream stream, XdrConfigSettingContractComputeV0 encoded) {
    XdrInt64.encode(stream, encoded.ledgerMaxInstructions);
    XdrInt64.encode(stream, encoded.txMaxInstructions);
    XdrInt64.encode(stream, encoded.feeRatePerInstructionsIncrement);
    XdrUint32.encode(stream, encoded.txMemoryLimit);
  }

  static XdrConfigSettingContractComputeV0 decode(XdrDataInputStream stream) {
    XdrInt64 ledgerMaxInstructions = XdrInt64.decode(stream);
    XdrInt64 txMaxInstructions = XdrInt64.decode(stream);
    XdrInt64 feeRatePerInstructionsIncrement = XdrInt64.decode(stream);
    XdrUint32 txMemoryLimit = XdrUint32.decode(stream);
    return XdrConfigSettingContractComputeV0(ledgerMaxInstructions,
        txMaxInstructions, feeRatePerInstructionsIncrement, txMemoryLimit);
  }
}

// Settings for running the contract transactions in parallel.
class XdrConfigSettingContractParallelComputeV0 {
  // Maximum number of clusters with dependent transactions allowed in a
  // stage of parallel tx set component.
  // This effectively sets the lower bound on the number of physical threads
  // necessary to effectively apply transaction sets in parallel.
  XdrUint32 _ledgerMaxDependentTxClusters;
  XdrUint32 get ledgerMaxDependentTxClusters =>
      this._ledgerMaxDependentTxClusters;
  set ledgerMaxDependentTxClusters(XdrUint32 value) =>
      this._ledgerMaxDependentTxClusters = value;

  XdrConfigSettingContractParallelComputeV0(this._ledgerMaxDependentTxClusters);

  static void encode(XdrDataOutputStream stream,
      XdrConfigSettingContractParallelComputeV0 encoded) {
    XdrUint32.encode(stream, encoded.ledgerMaxDependentTxClusters);
  }

  static XdrConfigSettingContractParallelComputeV0 decode(
      XdrDataInputStream stream) {
    XdrUint32 ledgerMaxDependentTxClusters = XdrUint32.decode(stream);
    return XdrConfigSettingContractParallelComputeV0(
        ledgerMaxDependentTxClusters);
  }
}

// Historical data (pushed to core archives) settings for contracts.
class XdrConfigSettingContractHistoricalDataV0 {
  // Fee for storing 1KB in archives
  XdrInt64 _feeHistorical1KB;
  XdrInt64 get feeHistorical1KB => this._feeHistorical1KB;
  set feeHistorical1KB(XdrInt64 value) => this._feeHistorical1KB = value;

  XdrConfigSettingContractHistoricalDataV0(this._feeHistorical1KB);

  static void encode(XdrDataOutputStream stream,
      XdrConfigSettingContractHistoricalDataV0 encoded) {
    XdrInt64.encode(stream, encoded.feeHistorical1KB);
  }

  static XdrConfigSettingContractHistoricalDataV0 decode(
      XdrDataInputStream stream) {
    XdrInt64 feeHistorical1KB = XdrInt64.decode(stream);
    return XdrConfigSettingContractHistoricalDataV0(feeHistorical1KB);
  }
}

// Ledger access settings for contracts.
class XdrConfigSettingContractLedgerCostV0 {
  // Maximum number of disk entry read operations per ledger
  XdrUint32 _ledgerMaxDiskReadEntries;
  XdrUint32 get ledgerMaxDiskReadEntries => this._ledgerMaxDiskReadEntries;
  set ledgerMaxDiskReadEntries(XdrUint32 value) =>
      this._ledgerMaxDiskReadEntries = value;

  // Maximum number of bytes of disk reads that can be performed per ledger
  XdrUint32 _ledgerMaxDiskReadBytes;
  XdrUint32 get ledgerMaxDiskReadBytes => this._ledgerMaxDiskReadBytes;
  set ledgerMaxDiskReadBytes(XdrUint32 value) =>
      this._ledgerMaxDiskReadBytes = value;

  // Maximum number of ledger entry write operations per ledger
  XdrUint32 _ledgerMaxWriteLedgerEntries;
  XdrUint32 get ledgerMaxWriteLedgerEntries =>
      this._ledgerMaxWriteLedgerEntries;
  set ledgerMaxWriteLedgerEntries(XdrUint32 value) =>
      this._ledgerMaxWriteLedgerEntries = value;

  // Maximum number of bytes that can be written per ledger
  XdrUint32 _ledgerMaxWriteBytes;
  XdrUint32 get ledgerMaxWriteBytes => this._ledgerMaxWriteBytes;
  set ledgerMaxWriteBytes(XdrUint32 value) => this._ledgerMaxWriteBytes = value;

  // Maximum number of disk entry read operations per transaction
  XdrUint32 _txMaxDiskReadEntries;
  XdrUint32 get txMaxDiskReadEntries => this._txMaxDiskReadEntries;
  set txMaxDiskReadEntries(XdrUint32 value) =>
      this._txMaxDiskReadEntries = value;

  // Maximum number of bytes of disk reads that can be performed per transaction
  XdrUint32 _txMaxDiskReadBytes;
  XdrUint32 get txMaxDiskReadBytes => this._txMaxDiskReadBytes;
  set txMaxDiskReadBytes(XdrUint32 value) => this._txMaxDiskReadBytes = value;

  // Maximum number of ledger entry write operations per transaction
  XdrUint32 _txMaxWriteLedgerEntries;
  XdrUint32 get txMaxWriteLedgerEntries => this._txMaxWriteLedgerEntries;
  set txMaxWriteLedgerEntries(XdrUint32 value) =>
      this._txMaxWriteLedgerEntries = value;

  // Maximum number of bytes that can be written per transaction
  XdrUint32 _txMaxWriteBytes;
  XdrUint32 get txMaxWriteBytes => this._txMaxWriteBytes;
  set txMaxWriteBytes(XdrUint32 value) => this._txMaxWriteBytes = value;

  // Fee per disk ledger entry read
  XdrInt64 _feeDiskReadLedgerEntry;
  XdrInt64 get feeDiskReadLedgerEntry => this._feeDiskReadLedgerEntry;
  set feeDiskReadLedgerEntry(XdrInt64 value) =>
      this._feeDiskReadLedgerEntry = value;

  // Fee per ledger entry write
  XdrInt64 _feeWriteLedgerEntry;
  XdrInt64 get feeWriteLedgerEntry => this._feeWriteLedgerEntry;
  set feeWriteLedgerEntry(XdrInt64 value) => this._feeWriteLedgerEntry = value;

  // Fee for reading 1KB disk
  XdrInt64 _feeDiskRead1KB;
  XdrInt64 get feeDiskRead1KB => this._feeDiskRead1KB;
  set feeDiskRead1KB(XdrInt64 value) => this._feeDiskRead1KB = value;

  // The following parameters determine the write fee per 1KB.

  // Rent fee grows linearly until soroban state reaches this size
  XdrInt64 _sorobanStateTargetSizeBytes;
  XdrInt64 get sorobanStateTargetSizeBytes => this._sorobanStateTargetSizeBytes;
  set sorobanStateTargetSizeBytes(XdrInt64 value) =>
      this._sorobanStateTargetSizeBytes = value;

  // Fee per 1KB rent when the soroban state is empty
  XdrInt64 _rentFee1KBSorobanStateSizeLow;
  XdrInt64 get rentFee1KBSorobanStateSizeLow =>
      this._rentFee1KBSorobanStateSizeLow;
  set rentFee1KBSorobanStateSizeLow(XdrInt64 value) =>
      this._rentFee1KBSorobanStateSizeLow = value;

  // Fee per 1KB rent when the soroban state has reached `sorobanStateTargetSizeBytes`
  XdrInt64 _rentFee1KBSorobanStateSizeHigh;
  XdrInt64 get rentFee1KBSorobanStateSizeHigh =>
      this._rentFee1KBSorobanStateSizeHigh;
  set rentFee1KBSorobanStateSizeHigh(XdrInt64 value) =>
      this._rentFee1KBSorobanStateSizeHigh = value;

  // Rent fee multiplier for any additional data past the first `sorobanStateTargetSizeBytes`
  XdrUint32 _sorobanStateRentFeeGrowthFactor;
  XdrUint32 get sorobanStateRentFeeGrowthFactor =>
      this._sorobanStateRentFeeGrowthFactor;
  set sorobanStateRentFeeGrowthFactor(XdrUint32 value) =>
      this._sorobanStateRentFeeGrowthFactor = value;

  XdrConfigSettingContractLedgerCostV0(
      this._ledgerMaxDiskReadEntries,
      this._ledgerMaxDiskReadBytes,
      this._ledgerMaxWriteLedgerEntries,
      this._ledgerMaxWriteBytes,
      this._txMaxDiskReadEntries,
      this._txMaxDiskReadBytes,
      this._txMaxWriteLedgerEntries,
      this._txMaxWriteBytes,
      this._feeDiskReadLedgerEntry,
      this._feeWriteLedgerEntry,
      this._feeDiskRead1KB,
      this._sorobanStateTargetSizeBytes,
      this._rentFee1KBSorobanStateSizeLow,
      this._rentFee1KBSorobanStateSizeHigh,
      this._sorobanStateRentFeeGrowthFactor);

  static void encode(XdrDataOutputStream stream,
      XdrConfigSettingContractLedgerCostV0 encoded) {
    XdrUint32.encode(stream, encoded.ledgerMaxDiskReadEntries);
    XdrUint32.encode(stream, encoded.ledgerMaxDiskReadBytes);
    XdrUint32.encode(stream, encoded.ledgerMaxWriteLedgerEntries);
    XdrUint32.encode(stream, encoded.ledgerMaxWriteBytes);
    XdrUint32.encode(stream, encoded.txMaxDiskReadEntries);
    XdrUint32.encode(stream, encoded.txMaxDiskReadBytes);
    XdrUint32.encode(stream, encoded.txMaxWriteLedgerEntries);
    XdrUint32.encode(stream, encoded.txMaxWriteBytes);

    XdrInt64.encode(stream, encoded.feeDiskReadLedgerEntry);
    XdrInt64.encode(stream, encoded.feeWriteLedgerEntry);
    XdrInt64.encode(stream, encoded.feeDiskRead1KB);
    XdrInt64.encode(stream, encoded.sorobanStateTargetSizeBytes);
    XdrInt64.encode(stream, encoded.rentFee1KBSorobanStateSizeLow);
    XdrInt64.encode(stream, encoded.rentFee1KBSorobanStateSizeHigh);

    XdrUint32.encode(stream, encoded.sorobanStateRentFeeGrowthFactor);
  }

  static XdrConfigSettingContractLedgerCostV0 decode(
      XdrDataInputStream stream) {
    XdrUint32 ledgerMaxDiskReadEntries = XdrUint32.decode(stream);
    XdrUint32 ledgerMaxDiskReadBytes = XdrUint32.decode(stream);
    XdrUint32 ledgerMaxWriteLedgerEntries = XdrUint32.decode(stream);
    XdrUint32 ledgerMaxWriteBytes = XdrUint32.decode(stream);
    XdrUint32 txMaxDiskReadEntries = XdrUint32.decode(stream);
    XdrUint32 txMaxDiskReadBytes = XdrUint32.decode(stream);
    XdrUint32 txMaxWriteLedgerEntries = XdrUint32.decode(stream);
    XdrUint32 txMaxWriteBytes = XdrUint32.decode(stream);

    XdrInt64 feeDiskReadLedgerEntry = XdrInt64.decode(stream);
    XdrInt64 feeWriteLedgerEntry = XdrInt64.decode(stream);
    XdrInt64 feeDiskRead1KB = XdrInt64.decode(stream);
    XdrInt64 sorobanStateTargetSizeBytes = XdrInt64.decode(stream);
    XdrInt64 rentFee1KBSorobanStateSizeLow = XdrInt64.decode(stream);
    XdrInt64 rentFee1KBSorobanStateSizeHigh = XdrInt64.decode(stream);
    XdrUint32 sorobanStateRentFeeGrowthFactor = XdrUint32.decode(stream);

    return XdrConfigSettingContractLedgerCostV0(
        ledgerMaxDiskReadEntries,
        ledgerMaxDiskReadBytes,
        ledgerMaxWriteLedgerEntries,
        ledgerMaxWriteBytes,
        txMaxDiskReadEntries,
        txMaxDiskReadBytes,
        txMaxWriteLedgerEntries,
        txMaxWriteBytes,
        feeDiskReadLedgerEntry,
        feeWriteLedgerEntry,
        feeDiskRead1KB,
        sorobanStateTargetSizeBytes,
        rentFee1KBSorobanStateSizeLow,
        rentFee1KBSorobanStateSizeHigh,
        sorobanStateRentFeeGrowthFactor);
  }
}

// Ledger access settings for contracts.
class XdrConfigSettingContractLedgerCostExtV0 {
  // Maximum number of RO+RW entries in the transaction footprint.
  XdrUint32 _txMaxFootprintEntries;
  XdrUint32 get txMaxFootprintEntries => this._txMaxFootprintEntries;
  set txMaxFootprintEntries(XdrUint32 value) =>
      this._txMaxFootprintEntries = value;

  // Fee per 1 KB of data written to the ledger.
  // Unlike the rent fee, this is a flat fee that is charged for any ledger
  // write, independent of the type of the entry being written.
  XdrInt64 _feeWrite1KB;
  XdrInt64 get feeWrite1KB => this._feeWrite1KB;
  set feeWrite1KB(XdrInt64 value) => this._feeWrite1KB = value;

  XdrConfigSettingContractLedgerCostExtV0(
      this._txMaxFootprintEntries, this._feeWrite1KB);

  static void encode(XdrDataOutputStream stream,
      XdrConfigSettingContractLedgerCostExtV0 encoded) {
    XdrUint32.encode(stream, encoded.txMaxFootprintEntries);
    XdrInt64.encode(stream, encoded.feeWrite1KB);
  }

  static XdrConfigSettingContractLedgerCostExtV0 decode(
      XdrDataInputStream stream) {
    final txMaxFootprintEntries = XdrUint32.decode(stream);
    final feeWrite1KB = XdrInt64.decode(stream);
    return XdrConfigSettingContractLedgerCostExtV0(
        txMaxFootprintEntries, feeWrite1KB);
  }
}

// Contract event-related settings.
class XdrConfigSettingContractEventsV0 {
  // Maximum size of events that a contract call can emit.
  XdrUint32 _txMaxContractEventsSizeBytes;
  XdrUint32 get txMaxContractEventsSizeBytes =>
      this._txMaxContractEventsSizeBytes;
  set txMaxContractEventsSizeBytes(XdrUint32 value) =>
      this._txMaxContractEventsSizeBytes = value;

  // Fee for generating 1KB of contract events.
  XdrInt64 _feeContractEvents1KB;
  XdrInt64 get feeContractEvents1KB => this._feeContractEvents1KB;
  set feeContractEvents1KB(XdrInt64 value) =>
      this._feeContractEvents1KB = value;

  XdrConfigSettingContractEventsV0(
      this._txMaxContractEventsSizeBytes, this._feeContractEvents1KB);

  static void encode(
      XdrDataOutputStream stream, XdrConfigSettingContractEventsV0 encoded) {
    XdrUint32.encode(stream, encoded.txMaxContractEventsSizeBytes);
    XdrInt64.encode(stream, encoded.feeContractEvents1KB);
  }

  static XdrConfigSettingContractEventsV0 decode(XdrDataInputStream stream) {
    XdrUint32 txMaxExtendedMetaDataSizeBytes = XdrUint32.decode(stream);
    XdrInt64 feeExtendedMetaData1KB = XdrInt64.decode(stream);
    return XdrConfigSettingContractEventsV0(
        txMaxExtendedMetaDataSizeBytes, feeExtendedMetaData1KB);
  }
}

class XdrContractCostType {
  final _value;
  const XdrContractCostType._internal(this._value);
  toString() => 'ContractCostType.$_value';

  XdrContractCostType(this._value);

  get value => this._value;

  // Cost of running 1 wasm instruction
  static const WasmInsnExec = const XdrContractCostType._internal(0);

  // Cost of allocating a slice of memory (in bytes)
  static const MemAlloc = const XdrContractCostType._internal(1);

  // Cost of copying a slice of bytes into a pre-allocated memory
  static const MemCpy = const XdrContractCostType._internal(2);

  // Cost of comparing two slices of memory
  static const MemCmp = const XdrContractCostType._internal(3);

  // Cost of a host function dispatch, not including the actual work done by
  // the function nor the cost of VM invocation machinary
  static const DispatchHostFunction = const XdrContractCostType._internal(4);

  // Cost of visiting a host object from the host object storage. Exists to
  // make sure some baseline cost coverage, i.e. repeatly visiting objects
  // by the guest will always incur some charges.
  static const VisitObject = const XdrContractCostType._internal(5);

  // Cost of serializing an xdr object to bytes
  static const ValSer = const XdrContractCostType._internal(6);

  // Cost of deserializing an xdr object from bytes
  static const ValDeser = const XdrContractCostType._internal(7);

  // Cost of computing the sha256 hash from bytes
  static const ComputeSha256Hash = const XdrContractCostType._internal(8);

  // Cost of computing the ed25519 pubkey from bytes
  static const ComputeEd25519PubKey = const XdrContractCostType._internal(9);

  // Cost of verifying ed25519 signature of a payload.
  static const VerifyEd25519Sig = const XdrContractCostType._internal(10);

  // Cost of instantiation a VM from wasm bytes code.
  static const VmInstantiation = const XdrContractCostType._internal(11);

  // Cost of instantiation a VM from a cached state.
  static const VmCachedInstantiation = const XdrContractCostType._internal(12);

  // Cost of invoking a function on the VM. If the function is a host function,
  // additional cost will be covered by `DispatchHostFunction`.
  static const InvokeVmFunction = const XdrContractCostType._internal(13);

  // Cost of computing a keccak256 hash from bytes.
  static const ComputeKeccak256Hash = const XdrContractCostType._internal(14);

  // Cost of decoding an ECDSA signature computed from a 256-bit prime modulus
  // curve (e.g. secp256k1 and secp256r1)
  static const DecodeEcdsaCurve256Sig = const XdrContractCostType._internal(15);

  // Cost of recovering an ECDSA secp256k1 key from a signature.
  static const RecoverEcdsaSecp256k1Key =
      const XdrContractCostType._internal(16);

  // Cost of int256 addition (`+`) and subtraction (`-`) operations
  static const Int256AddSub = const XdrContractCostType._internal(17);

  // Cost of int256 multiplication (`*`) operation
  static const Int256Mul = const XdrContractCostType._internal(18);

  // Cost of int256 division (`/`) operation
  static const Int256Div = const XdrContractCostType._internal(19);

  // Cost of int256 power (`exp`) operation
  static const Int256Pow = const XdrContractCostType._internal(20);

  // Cost of int256 shift (`shl`, `shr`) operation
  static const Int256Shift = const XdrContractCostType._internal(21);

  // Cost of drawing random bytes using a ChaCha20 PRNG
  static const ChaCha20DrawBytes = const XdrContractCostType._internal(22);

  // Cost of parsing wasm bytes that only encode instructions.
  static const ParseWasmInstructions = const XdrContractCostType._internal(23);

  // Cost of parsing a known number of wasm functions.
  static const ParseWasmFunctions = const XdrContractCostType._internal(24);

  // Cost of parsing a known number of wasm globals.
  static const ParseWasmGlobals = const XdrContractCostType._internal(25);

  // Cost of parsing a known number of wasm table entries.
  static const ParseWasmTableEntries = const XdrContractCostType._internal(26);

  // Cost of parsing a known number of wasm types.
  static const ParseWasmTypes = const XdrContractCostType._internal(27);

  // Cost of parsing a known number of wasm data segments.
  static const ParseWasmDataSegments = const XdrContractCostType._internal(28);

  // Cost of parsing a known number of wasm element segments.
  static const ParseWasmElemSegments = const XdrContractCostType._internal(29);

  // Cost of parsing a known number of wasm imports.
  static const ParseWasmImports = const XdrContractCostType._internal(30);

  // Cost of parsing a known number of wasm exports.
  static const ParseWasmExports = const XdrContractCostType._internal(31);

  // Cost of parsing a known number of data segment bytes.
  static const ParseWasmDataSegmentBytes =
      const XdrContractCostType._internal(32);

  // Cost of instantiating wasm bytes that only encode instructions.
  static const InstantiateWasmInstructions =
      const XdrContractCostType._internal(33);

  // Cost of instantiating a known number of wasm functions.
  static const InstantiateWasmFunctions =
      const XdrContractCostType._internal(34);

  // Cost of instantiating a known number of wasm globals.
  static const InstantiateWasmGlobals = const XdrContractCostType._internal(35);

  // Cost of instantiating a known number of wasm table entries.
  static const InstantiateWasmTableEntries =
      const XdrContractCostType._internal(36);

  // Cost of instantiating a known number of wasm types.
  static const InstantiateWasmTypes = const XdrContractCostType._internal(37);

  // Cost of instantiating a known number of wasm data segments.
  static const InstantiateWasmDataSegments =
      const XdrContractCostType._internal(38);

  // Cost of instantiating a known number of wasm element segments.
  static const InstantiateWasmElemSegments =
      const XdrContractCostType._internal(39);

  // Cost of instantiating a known number of wasm imports.
  static const InstantiateWasmImports = const XdrContractCostType._internal(40);

  // Cost of instantiating a known number of wasm exports.
  static const InstantiateWasmExports = const XdrContractCostType._internal(41);

  // Cost of instantiating a known number of data segment bytes.
  static const InstantiateWasmDataSegmentBytes =
      const XdrContractCostType._internal(42);

  // Cost of decoding a bytes array representing an uncompressed SEC-1 encoded point on a 256-bit elliptic curve
  static const Sec1DecodePointUncompressed =
      const XdrContractCostType._internal(43);

  // Cost of verifying an ECDSA Secp256r1 signature
  static const VerifyEcdsaSecp256r1Sig =
      const XdrContractCostType._internal(44);

  // Cost of encoding a BLS12-381 Fp (base field element)
  static const Bls12381EncodeFp = const XdrContractCostType._internal(45);

  // Cost of decoding a BLS12-381 Fp (base field element)
  static const Bls12381DecodeFp = const XdrContractCostType._internal(46);

  // Cost of checking a G1 point lies on the curve
  static const Bls12381G1CheckPointOnCurve =
      const XdrContractCostType._internal(47);

  // Cost of checking a G1 point belongs to the correct subgroup
  static const Bls12381G1CheckPointInSubgroup =
      const XdrContractCostType._internal(48);

  // Cost of checking a G2 point lies on the curve
  static const Bls12381G2CheckPointOnCurve =
      const XdrContractCostType._internal(49);

  // Cost of checking a G2 point belongs to the correct subgroup
  static const Bls12381G2CheckPointInSubgroup =
      const XdrContractCostType._internal(50);

  // Cost of converting a BLS12-381 G1 point from projective to affine coordinates
  static const Bls12381G1ProjectiveToAffine =
      const XdrContractCostType._internal(51);

  // Cost of converting a BLS12-381 G2 point from projective to affine coordinates
  static const Bls12381G2ProjectiveToAffine =
      const XdrContractCostType._internal(52);

  // Cost of performing BLS12-381 G1 point addition
  static const Bls12381G1Add = const XdrContractCostType._internal(53);

  // Cost of performing BLS12-381 G1 scalar multiplication
  static const Bls12381G1Mul = const XdrContractCostType._internal(54);

  // Cost of performing BLS12-381 G1 multi-scalar multiplication (MSM)
  static const Bls12381G1Msm = const XdrContractCostType._internal(55);

  // Cost of mapping a BLS12-381 Fp field element to a G1 point
  static const Bls12381MapFpToG1 = const XdrContractCostType._internal(56);

  // Cost of hashing to a BLS12-381 G1 point
  static const Bls12381HashToG1 = const XdrContractCostType._internal(57);

  // Cost of performing BLS12-381 G2 point addition
  static const Bls12381G2Add = const XdrContractCostType._internal(58);

  // Cost of performing BLS12-381 G2 scalar multiplication
  static const Bls12381G2Mul = const XdrContractCostType._internal(59);

  // Cost of performing BLS12-381 G2 multi-scalar multiplication (MSM)
  static const Bls12381G2Msm = const XdrContractCostType._internal(60);

  // Cost of mapping a BLS12-381 Fp2 field element to a G2 point
  static const Bls12381MapFp2ToG2 = const XdrContractCostType._internal(61);

  // Cost of hashing to a BLS12-381 G2 point
  static const Bls12381HashToG2 = const XdrContractCostType._internal(62);

  // Cost of performing BLS12-381 pairing operation
  static const Bls12381Pairing = const XdrContractCostType._internal(63);

  // Cost of converting a BLS12-381 scalar element from U256
  static const Bls12381FrFromU256 = const XdrContractCostType._internal(64);

  // Cost of converting a BLS12-381 scalar element to U256
  static const Bls12381FrToU256 = const XdrContractCostType._internal(65);

  // Cost of performing BLS12-381 scalar element addition/subtraction
  static const Bls12381FrAddSub = const XdrContractCostType._internal(66);

  // Cost of performing BLS12-381 scalar element multiplication
  static const Bls12381FrMul = const XdrContractCostType._internal(67);

  // Cost of performing BLS12-381 scalar element exponentiation
  static const Bls12381FrPow = const XdrContractCostType._internal(68);

  // Cost of performing BLS12-381 scalar element inversion
  static const Bls12381FrInv = const XdrContractCostType._internal(69);

  static XdrContractCostType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return WasmInsnExec;
      case 1:
        return MemAlloc;
      case 2:
        return MemCpy;
      case 3:
        return MemCmp;
      case 4:
        return DispatchHostFunction;
      case 5:
        return VisitObject;
      case 6:
        return ValSer;
      case 7:
        return ValDeser;
      case 8:
        return ComputeSha256Hash;
      case 9:
        return ComputeEd25519PubKey;
      case 10:
        return VerifyEd25519Sig;
      case 11:
        return VmInstantiation;
      case 12:
        return VmCachedInstantiation;
      case 13:
        return InvokeVmFunction;
      case 14:
        return ComputeKeccak256Hash;
      case 15:
        return DecodeEcdsaCurve256Sig;
      case 16:
        return RecoverEcdsaSecp256k1Key;
      case 17:
        return Int256AddSub;
      case 18:
        return Int256Mul;
      case 19:
        return Int256Div;
      case 20:
        return Int256Pow;
      case 21:
        return Int256Shift;
      case 22:
        return ChaCha20DrawBytes;
      case 23:
        return ParseWasmInstructions;
      case 24:
        return ParseWasmFunctions;
      case 25:
        return ParseWasmGlobals;
      case 26:
        return ParseWasmTableEntries;
      case 27:
        return ParseWasmTypes;
      case 28:
        return ParseWasmDataSegments;
      case 29:
        return ParseWasmElemSegments;
      case 30:
        return ParseWasmImports;
      case 31:
        return ParseWasmExports;
      case 32:
        return ParseWasmDataSegmentBytes;
      case 33:
        return InstantiateWasmInstructions;
      case 34:
        return InstantiateWasmFunctions;
      case 35:
        return InstantiateWasmGlobals;
      case 36:
        return InstantiateWasmTableEntries;
      case 37:
        return InstantiateWasmTypes;
      case 38:
        return InstantiateWasmDataSegments;
      case 39:
        return InstantiateWasmElemSegments;
      case 40:
        return InstantiateWasmImports;
      case 41:
        return InstantiateWasmExports;
      case 42:
        return InstantiateWasmDataSegmentBytes;
      case 43:
        return Sec1DecodePointUncompressed;
      case 44:
        return VerifyEcdsaSecp256r1Sig;
      case 45:
        return Bls12381EncodeFp;
      case 46:
        return Bls12381DecodeFp;
      case 47:
        return Bls12381G1CheckPointOnCurve;
      case 48:
        return Bls12381G1CheckPointInSubgroup;
      case 49:
        return Bls12381G2CheckPointOnCurve;
      case 50:
        return Bls12381G2CheckPointInSubgroup;
      case 51:
        return Bls12381G1ProjectiveToAffine;
      case 52:
        return Bls12381G2ProjectiveToAffine;
      case 53:
        return Bls12381G1Add;
      case 54:
        return Bls12381G1Mul;
      case 55:
        return Bls12381G1Msm;
      case 56:
        return Bls12381MapFpToG1;
      case 57:
        return Bls12381HashToG1;
      case 58:
        return Bls12381G2Add;
      case 59:
        return Bls12381G2Mul;
      case 60:
        return Bls12381G2Msm;
      case 61:
        return Bls12381MapFp2ToG2;
      case 62:
        return Bls12381HashToG2;
      case 63:
        return Bls12381Pairing;
      case 64:
        return Bls12381FrFromU256;
      case 65:
        return Bls12381FrToU256;
      case 66:
        return Bls12381FrAddSub;
      case 67:
        return Bls12381FrMul;
      case 68:
        return Bls12381FrPow;
      case 69:
        return Bls12381FrInv;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrContractCostType value) {
    stream.writeInt(value.value);
  }
}

class XdrContractCostParamEntry {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrInt64 _constTerm;
  XdrInt64 get constTerm => this._constTerm;
  set constTerm(XdrInt64 value) => this._constTerm = value;

  XdrInt64 _linearTerm;
  XdrInt64 get linearTerm => this._linearTerm;
  set linearTerm(XdrInt64 value) => this._linearTerm = value;

  XdrContractCostParamEntry(this._ext, this._constTerm, this._linearTerm);

  static void encode(
      XdrDataOutputStream stream, XdrContractCostParamEntry encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrInt64.encode(stream, encoded.constTerm);
    XdrInt64.encode(stream, encoded.linearTerm);
  }

  static XdrContractCostParamEntry decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrInt64 constTerm = XdrInt64.decode(stream);
    XdrInt64 linearTerm = XdrInt64.decode(stream);

    return XdrContractCostParamEntry(ext, constTerm, linearTerm);
  }
}

class XdrContractCostParams {
  List<XdrContractCostParamEntry> _entries;
  List<XdrContractCostParamEntry> get entries => this._entries;
  set entries(List<XdrContractCostParamEntry> value) => this._entries = value;

  XdrContractCostParams(this._entries);

  static void encode(
      XdrDataOutputStream stream, XdrContractCostParams encoded) {
    int pSize = encoded.entries.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      XdrContractCostParamEntry.encode(stream, encoded.entries[i]);
    }
  }

  static XdrContractCostParams decode(XdrDataInputStream stream) {
    int pSize = stream.readInt();
    List<XdrContractCostParamEntry> xEntries =
        List<XdrContractCostParamEntry>.empty(growable: true);
    for (int i = 0; i < pSize; i++) {
      xEntries.add(XdrContractCostParamEntry.decode(stream));
    }
    return XdrContractCostParams(xEntries);
  }
}

class XdrConfigSettingEntry {
  XdrConfigSettingID _configSettingID;
  XdrConfigSettingID get configSettingID => this._configSettingID;
  set configSettingID(XdrConfigSettingID value) =>
      this._configSettingID = value;

  XdrUint32? _contractMaxSizeBytes;
  XdrUint32? get contractMaxSizeBytes => this._contractMaxSizeBytes;
  set contractMaxSizeBytes(XdrUint32? value) =>
      this._contractMaxSizeBytes = value;

  XdrConfigSettingContractComputeV0? _contractCompute;
  XdrConfigSettingContractComputeV0? get contractCompute =>
      this._contractCompute;
  set contractCompute(XdrConfigSettingContractComputeV0? value) =>
      this._contractCompute = value;

  XdrConfigSettingContractLedgerCostV0? _contractLedgerCost;
  XdrConfigSettingContractLedgerCostV0? get contractLedgerCost =>
      this._contractLedgerCost;
  set contractLedgerCost(XdrConfigSettingContractLedgerCostV0? value) =>
      this._contractLedgerCost = value;

  XdrConfigSettingContractHistoricalDataV0? _contractHistoricalData;
  XdrConfigSettingContractHistoricalDataV0? get contractHistoricalData =>
      this._contractHistoricalData;
  set contractHistoricalData(XdrConfigSettingContractHistoricalDataV0? value) =>
      this._contractHistoricalData = value;

  XdrConfigSettingContractEventsV0? _contractEvents;
  XdrConfigSettingContractEventsV0? get contractEvents => this._contractEvents;
  set contractEvents(XdrConfigSettingContractEventsV0? value) =>
      this._contractEvents = value;

  XdrConfigSettingContractBandwidthV0? _contractBandwidth;
  XdrConfigSettingContractBandwidthV0? get contractBandwidth =>
      this._contractBandwidth;
  set contractBandwidth(XdrConfigSettingContractBandwidthV0? value) =>
      this._contractBandwidth = value;

  XdrContractCostParams? _contractCostParamsCpuInsns;
  XdrContractCostParams? get contractCostParamsCpuInsns =>
      this._contractCostParamsCpuInsns;
  set contractCostParamsCpuInsns(XdrContractCostParams? value) =>
      this._contractCostParamsCpuInsns = value;

  XdrContractCostParams? _contractCostParamsMemBytes;
  XdrContractCostParams? get contractCostParamsMemBytes =>
      this._contractCostParamsMemBytes;
  set contractCostParamsMemBytes(XdrContractCostParams? value) =>
      this._contractCostParamsMemBytes = value;

  XdrUint32? _contractDataKeySizeBytes;
  XdrUint32? get contractDataKeySizeBytes => this._contractDataKeySizeBytes;
  set contractDataKeySizeBytes(XdrUint32? value) =>
      this._contractDataKeySizeBytes = value;

  XdrUint32? _contractDataEntrySizeBytes;
  XdrUint32? get contractDataEntrySizeBytes => this._contractDataEntrySizeBytes;
  set contractDataEntrySizeBytes(XdrUint32? value) =>
      this._contractDataEntrySizeBytes = value;

  XdrStateArchivalSettings? _stateArchivalSettings;
  XdrStateArchivalSettings? get stateArchivalSettings =>
      this._stateArchivalSettings;
  set stateArchivalSettings(XdrStateArchivalSettings? value) =>
      this._stateArchivalSettings = value;

  XdrConfigSettingContractExecutionLanesV0? _contractExecutionLanes;
  XdrConfigSettingContractExecutionLanesV0? get contractExecutionLanes =>
      this._contractExecutionLanes;
  set contractExecutionLanes(XdrConfigSettingContractExecutionLanesV0? value) =>
      this._contractExecutionLanes = value;

  List<XdrUint64>? _liveSorobanStateSizeWindow;
  List<XdrUint64>? get liveSorobanStateSizeWindow =>
      this._liveSorobanStateSizeWindow;
  set liveSorobanStateSizeWindow(List<XdrUint64>? value) =>
      this._liveSorobanStateSizeWindow = value;

  XdrEvictionIterator? _evictionIterator;
  XdrEvictionIterator? get evictionIterator => this._evictionIterator;
  set evictionIterator(XdrEvictionIterator? value) =>
      this._evictionIterator = value;

  XdrConfigSettingContractParallelComputeV0? _contractParallelCompute;
  XdrConfigSettingContractParallelComputeV0? get contractParallelCompute =>
      this._contractParallelCompute;
  set contractParallelCompute(
          XdrConfigSettingContractParallelComputeV0? value) =>
      this._contractParallelCompute = value;

  XdrConfigSettingContractLedgerCostExtV0? _contractLedgerCostExt;
  XdrConfigSettingContractLedgerCostExtV0? get contractLedgerCostExt =>
      this._contractLedgerCostExt;
  set contractLedgerCostExt(XdrConfigSettingContractLedgerCostExtV0? value) =>
      this._contractLedgerCostExt = value;

  XdrConfigSettingSCPTiming? _contractSCPTiming;
  XdrConfigSettingSCPTiming? get contractSCPTiming => this._contractSCPTiming;
  set contractSCPTiming(XdrConfigSettingSCPTiming? value) =>
      this._contractSCPTiming = value;

  XdrConfigSettingEntry(this._configSettingID);

  static void encode(
      XdrDataOutputStream stream, XdrConfigSettingEntry encoded) {
    stream.writeInt(encoded.configSettingID.value);
    switch (encoded.configSettingID) {
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES:
        XdrUint32.encode(stream, encoded.contractMaxSizeBytes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0:
        XdrConfigSettingContractComputeV0.encode(
            stream, encoded.contractCompute!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0:
        XdrConfigSettingContractLedgerCostV0.encode(
            stream, encoded.contractLedgerCost!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0:
        XdrConfigSettingContractHistoricalDataV0.encode(
            stream, encoded.contractHistoricalData!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0:
        XdrConfigSettingContractEventsV0.encode(
            stream, encoded.contractEvents!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0:
        XdrConfigSettingContractBandwidthV0.encode(
            stream, encoded.contractBandwidth!);
        break;
      case XdrConfigSettingID
            .CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS:
        XdrContractCostParams.encode(
            stream, encoded.contractCostParamsCpuInsns!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES:
        XdrContractCostParams.encode(
            stream, encoded.contractCostParamsMemBytes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES:
        XdrUint32.encode(stream, encoded.contractDataKeySizeBytes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES:
        XdrUint32.encode(stream, encoded.contractDataEntrySizeBytes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL:
        XdrStateArchivalSettings.encode(stream, encoded.stateArchivalSettings!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES:
        XdrConfigSettingContractExecutionLanesV0.encode(
            stream, encoded.contractExecutionLanes!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW:
        int pSize = encoded.liveSorobanStateSizeWindow!.length;
        stream.writeInt(pSize);
        for (int i = 0; i < pSize; i++) {
          XdrUint64.encode(stream, encoded.liveSorobanStateSizeWindow![i]);
        }
        break;
      case XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR:
        XdrEvictionIterator.encode(stream, encoded.evictionIterator!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0:
        XdrConfigSettingContractParallelComputeV0.encode(
            stream, encoded.contractParallelCompute!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0:
        XdrConfigSettingContractLedgerCostExtV0.encode(
            stream, encoded.contractLedgerCostExt!);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_SCP_TIMING:
        XdrConfigSettingSCPTiming.encode(stream, encoded.contractSCPTiming!);
        break;
    }
  }

  static XdrConfigSettingEntry decode(XdrDataInputStream stream) {
    XdrConfigSettingEntry decoded =
        XdrConfigSettingEntry(XdrConfigSettingID.decode(stream));
    switch (decoded.configSettingID) {
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES:
        decoded.contractMaxSizeBytes = XdrUint32.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0:
        decoded.contractCompute =
            XdrConfigSettingContractComputeV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0:
        decoded.contractLedgerCost =
            XdrConfigSettingContractLedgerCostV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0:
        decoded.contractHistoricalData =
            XdrConfigSettingContractHistoricalDataV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0:
        decoded.contractEvents =
            XdrConfigSettingContractEventsV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0:
        decoded.contractBandwidth =
            XdrConfigSettingContractBandwidthV0.decode(stream);
        break;
      case XdrConfigSettingID
            .CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS:
        decoded.contractCostParamsCpuInsns =
            XdrContractCostParams.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES:
        decoded.contractCostParamsMemBytes =
            XdrContractCostParams.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES:
        decoded.contractDataKeySizeBytes = XdrUint32.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES:
        decoded.contractDataEntrySizeBytes = XdrUint32.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL:
        decoded.stateArchivalSettings = XdrStateArchivalSettings.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES:
        decoded.contractExecutionLanes =
            XdrConfigSettingContractExecutionLanesV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW:
        int pSize = stream.readInt();
        List<XdrUint64> liveSorobanStateSizeWindow =
            List<XdrUint64>.empty(growable: true);
        for (int i = 0; i < pSize; i++) {
          liveSorobanStateSizeWindow.add(XdrUint64.decode(stream));
        }
        decoded.liveSorobanStateSizeWindow = liveSorobanStateSizeWindow;
        break;
      case XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR:
        decoded.evictionIterator = XdrEvictionIterator.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0:
        decoded.contractParallelCompute =
            XdrConfigSettingContractParallelComputeV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0:
        decoded.contractLedgerCostExt =
            XdrConfigSettingContractLedgerCostExtV0.decode(stream);
        break;
      case XdrConfigSettingID.CONFIG_SETTING_SCP_TIMING:
        decoded.contractSCPTiming = XdrConfigSettingSCPTiming.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrConfigUpgradeSetKey {
  XdrConfigUpgradeSetKey(this._contractID, this._contentHash);

  XdrHash _contractID;
  XdrHash get contractID => this._contractID;
  set contractID(XdrHash value) => this._contractID = value;

  XdrHash _contentHash;
  XdrHash get contentHash => this._contentHash;
  set contentHash(XdrHash value) => this._contentHash = value;

  static void encode(
      XdrDataOutputStream stream, XdrConfigUpgradeSetKey encoded) {
    XdrHash.encode(stream, encoded.contractID);
    XdrHash.encode(stream, encoded.contentHash);
  }

  static XdrConfigUpgradeSetKey decode(XdrDataInputStream stream) {
    return XdrConfigUpgradeSetKey(
        XdrHash.decode(stream), XdrHash.decode(stream));
  }
}

class XdrInvokeHostFunctionSuccessPreImage {
  XdrSCVal _returnValue;
  XdrSCVal get returnValue => this._returnValue;
  set returnValue(XdrSCVal value) => this._returnValue = value;

  List<XdrContractEvent> _events;
  List<XdrContractEvent> get events => this._events;
  set events(List<XdrContractEvent> value) => this._events = value;

  XdrInvokeHostFunctionSuccessPreImage(this._returnValue, this._events);

  static void encode(XdrDataOutputStream stream,
      XdrInvokeHostFunctionSuccessPreImage encoded) {
    XdrSCVal.encode(stream, encoded.returnValue);

    int eventsSize = encoded.events.length;
    stream.writeInt(eventsSize);
    for (int i = 0; i < eventsSize; i++) {
      XdrContractEvent.encode(stream, encoded._events[i]);
    }
  }

  static XdrInvokeHostFunctionSuccessPreImage decode(
      XdrDataInputStream stream) {
    XdrSCVal returnValue = XdrSCVal.decode(stream);

    int eventsSize = stream.readInt();
    List<XdrContractEvent> events =
        List<XdrContractEvent>.empty(growable: true);
    for (int i = 0; i < eventsSize; i++) {
      events.add(XdrContractEvent.decode(stream));
    }

    return XdrInvokeHostFunctionSuccessPreImage(returnValue, events);
  }
}
