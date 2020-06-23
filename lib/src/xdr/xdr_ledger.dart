// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

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
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrLedgerEntryType value) {
    stream.writeInt(value.value);
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
  XdrLedgerHeader();
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
    XdrLedgerHeader decodedLedgerHeader = XdrLedgerHeader();
    decodedLedgerHeader.ledgerVersion = XdrUint32.decode(stream);
    decodedLedgerHeader.previousLedgerHash = XdrHash.decode(stream);
    decodedLedgerHeader.scpValue = XdrStellarValue.decode(stream);
    decodedLedgerHeader.txSetResultHash = XdrHash.decode(stream);
    decodedLedgerHeader.bucketListHash = XdrHash.decode(stream);
    decodedLedgerHeader.ledgerSeq = XdrUint32.decode(stream);
    decodedLedgerHeader.totalCoins = XdrInt64.decode(stream);
    decodedLedgerHeader.feePool = XdrInt64.decode(stream);
    decodedLedgerHeader.inflationSeq = XdrUint32.decode(stream);
    decodedLedgerHeader.idPool = XdrUint64.decode(stream);
    decodedLedgerHeader.baseFee = XdrUint32.decode(stream);
    decodedLedgerHeader.baseReserve = XdrUint32.decode(stream);
    decodedLedgerHeader.maxTxSetSize = XdrUint32.decode(stream);
    int skipListsize = 4;
    decodedLedgerHeader.skipList = List<XdrHash>(skipListsize);
    for (int i = 0; i < skipListsize; i++) {
      decodedLedgerHeader.skipList[i] = XdrHash.decode(stream);
    }
    decodedLedgerHeader.ext = XdrLedgerHeaderExt.decode(stream);
    return decodedLedgerHeader;
  }
}

class XdrLedgerHeaderExt {
  XdrLedgerHeaderExt();
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
    XdrLedgerHeaderExt decodedLedgerHeaderExt = XdrLedgerHeaderExt();
    int discriminant = stream.readInt();
    decodedLedgerHeaderExt.discriminant = discriminant;
    switch (decodedLedgerHeaderExt.discriminant) {
      case 0:
        break;
    }
    return decodedLedgerHeaderExt;
  }
}

class XdrLedgerKey {
  XdrLedgerKey();
  XdrLedgerEntryType _type;
  XdrLedgerEntryType get discriminant => this._type;
  set discriminant(XdrLedgerEntryType value) => this._type = value;

  XdrLedgerKeyAccount _account;
  XdrLedgerKeyAccount get account => this._account;
  set account(XdrLedgerKeyAccount value) => this._account = value;

  XdrLedgerKeyTrustLine _trustLine;
  XdrLedgerKeyTrustLine get trustLine => this._trustLine;
  set trustLine(XdrLedgerKeyTrustLine value) => this._trustLine = value;

  XdrLedgerKeyOffer _offer;
  XdrLedgerKeyOffer get offer => this._offer;
  set offer(XdrLedgerKeyOffer value) => this._offer = value;

  XdrLedgerKeyData _data;
  XdrLedgerKeyData get data => this._data;
  set data(XdrLedgerKeyData value) => this._data = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKey encodedLedgerKey) {
    stream.writeInt(encodedLedgerKey.discriminant.value);
    switch (encodedLedgerKey.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        XdrLedgerKeyAccount.encode(stream, encodedLedgerKey.account);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        XdrLedgerKeyTrustLine.encode(stream, encodedLedgerKey.trustLine);
        break;
      case XdrLedgerEntryType.OFFER:
        XdrLedgerKeyOffer.encode(stream, encodedLedgerKey.offer);
        break;
      case XdrLedgerEntryType.DATA:
        XdrLedgerKeyData.encode(stream, encodedLedgerKey.data);
        break;
    }
  }

  static XdrLedgerKey decode(XdrDataInputStream stream) {
    XdrLedgerKey decodedLedgerKey = XdrLedgerKey();
    XdrLedgerEntryType discriminant = XdrLedgerEntryType.decode(stream);
    decodedLedgerKey.discriminant = discriminant;
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
    }
    return decodedLedgerKey;
  }
}

class XdrLedgerKeyAccount {
  XdrLedgerKeyAccount();
  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerKeyAccount encodedLedgerKeyAccount) {
    XdrAccountID.encode(stream, encodedLedgerKeyAccount.accountID);
  }

  static XdrLedgerKeyAccount decode(XdrDataInputStream stream) {
    XdrLedgerKeyAccount decodedLedgerKeyAccount = XdrLedgerKeyAccount();
    decodedLedgerKeyAccount.accountID = XdrAccountID.decode(stream);
    return decodedLedgerKeyAccount;
  }
}

class XdrLedgerKeyTrustLine {
  XdrLedgerKeyTrustLine();
  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerKeyTrustLine encodedLedgerKeyTrustLine) {
    XdrAccountID.encode(stream, encodedLedgerKeyTrustLine.accountID);
    XdrAsset.encode(stream, encodedLedgerKeyTrustLine.asset);
  }

  static XdrLedgerKeyTrustLine decode(XdrDataInputStream stream) {
    XdrLedgerKeyTrustLine decodedLedgerKeyTrustLine = XdrLedgerKeyTrustLine();
    decodedLedgerKeyTrustLine.accountID = XdrAccountID.decode(stream);
    decodedLedgerKeyTrustLine.asset = XdrAsset.decode(stream);
    return decodedLedgerKeyTrustLine;
  }
}

class XdrLedgerKeyOffer {
  XdrLedgerKeyOffer();
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
    XdrLedgerKeyOffer decodedLedgerKeyOffer = XdrLedgerKeyOffer();
    decodedLedgerKeyOffer.sellerID = XdrAccountID.decode(stream);
    decodedLedgerKeyOffer.offerID = XdrUint64.decode(stream);
    return decodedLedgerKeyOffer;
  }
}

class XdrLedgerKeyData {
  XdrLedgerKeyData();
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
    XdrLedgerKeyData decodedLedgerKeyData = XdrLedgerKeyData();
    decodedLedgerKeyData.accountID = XdrAccountID.decode(stream);
    decodedLedgerKeyData.dataName = XdrString64.decode(stream);
    return decodedLedgerKeyData;
  }
}

class XdrLedgerSCPMessages {
  XdrLedgerSCPMessages();
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
    XdrLedgerSCPMessages decodedLedgerSCPMessages = XdrLedgerSCPMessages();
    decodedLedgerSCPMessages.ledgerSeq = XdrUint32.decode(stream);
    int messagessize = stream.readInt();
    decodedLedgerSCPMessages.messages = List<XdrSCPEnvelope>(messagessize);
    for (int i = 0; i < messagessize; i++) {
      decodedLedgerSCPMessages.messages[i] = XdrSCPEnvelope.decode(stream);
    }
    return decodedLedgerSCPMessages;
  }
}

class XdrLedgerUpgrade {
  XdrLedgerUpgrade();
  XdrLedgerUpgradeType _type;
  XdrLedgerUpgradeType get discriminant => this._type;
  set discriminant(XdrLedgerUpgradeType value) => this._type = value;

  XdrUint32 _newLedgerVersion;
  XdrUint32 get newLedgerVersion => this._newLedgerVersion;
  set newLedgerVersion(XdrUint32 value) => this._newLedgerVersion = value;

  XdrUint32 _newBaseFee;
  XdrUint32 get newBaseFee => this._newBaseFee;
  set newBaseFee(XdrUint32 value) => this._newBaseFee = value;

  XdrUint32 _newMaxTxSetSize;
  XdrUint32 get newMaxTxSetSize => this._newMaxTxSetSize;
  set newMaxTxSetSize(XdrUint32 value) => this._newMaxTxSetSize = value;

  XdrUint32 _newBaseReserve;
  XdrUint32 get newBaseReserve => this._newBaseReserve;
  set newBaseReserve(XdrUint32 value) => this._newBaseReserve = value;

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
    XdrLedgerUpgrade decodedLedgerUpgrade = XdrLedgerUpgrade();
    XdrLedgerUpgradeType discriminant = XdrLedgerUpgradeType.decode(stream);
    decodedLedgerUpgrade.discriminant = discriminant;
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
  XdrLedgerEntry();
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
    XdrLedgerEntry decodedLedgerEntry = XdrLedgerEntry();
    decodedLedgerEntry.lastModifiedLedgerSeq = XdrUint32.decode(stream);
    decodedLedgerEntry.data = XdrLedgerEntryData.decode(stream);
    decodedLedgerEntry.ext = XdrLedgerEntryExt.decode(stream);
    return decodedLedgerEntry;
  }
}

class XdrLedgerEntryData {
  XdrLedgerEntryData();
  XdrLedgerEntryType _type;
  XdrLedgerEntryType get discriminant => this._type;
  set discriminant(XdrLedgerEntryType value) => this._type = value;

  XdrAccountEntry _account;
  XdrAccountEntry get account => this._account;
  set account(XdrAccountEntry value) => this._account = value;

  XdrTrustLineEntry _trustLine;
  XdrTrustLineEntry get trustLine => this._trustLine;
  set trustLine(XdrTrustLineEntry value) => this._trustLine = value;

  XdrOfferEntry _offer;
  XdrOfferEntry get offer => this._offer;
  set offer(XdrOfferEntry value) => this._offer = value;

  XdrDataEntry _data;
  XdrDataEntry get data => this._data;
  set data(XdrDataEntry value) => this._data = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerEntryData encodedLedgerEntryData) {
    stream.writeInt(encodedLedgerEntryData.discriminant.value);
    switch (encodedLedgerEntryData.discriminant) {
      case XdrLedgerEntryType.ACCOUNT:
        XdrAccountEntry.encode(stream, encodedLedgerEntryData.account);
        break;
      case XdrLedgerEntryType.TRUSTLINE:
        XdrTrustLineEntry.encode(stream, encodedLedgerEntryData.trustLine);
        break;
      case XdrLedgerEntryType.OFFER:
        XdrOfferEntry.encode(stream, encodedLedgerEntryData.offer);
        break;
      case XdrLedgerEntryType.DATA:
        XdrDataEntry.encode(stream, encodedLedgerEntryData.data);
        break;
    }
  }

  static XdrLedgerEntryData decode(XdrDataInputStream stream) {
    XdrLedgerEntryData decodedLedgerEntryData = XdrLedgerEntryData();
    XdrLedgerEntryType discriminant = XdrLedgerEntryType.decode(stream);
    decodedLedgerEntryData.discriminant = discriminant;
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
    }
    return decodedLedgerEntryData;
  }
}

class XdrLedgerEntryExt {
  XdrLedgerEntryExt();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream, XdrLedgerEntryExt encodedLedgerEntryExt) {
    stream.writeInt(encodedLedgerEntryExt.discriminant);
    switch (encodedLedgerEntryExt.discriminant) {
      case 0:
        break;
    }
  }

  static XdrLedgerEntryExt decode(XdrDataInputStream stream) {
    XdrLedgerEntryExt decodedLedgerEntryExt = XdrLedgerEntryExt();
    int discriminant = stream.readInt();
    decodedLedgerEntryExt.discriminant = discriminant;
    switch (decodedLedgerEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedLedgerEntryExt;
  }
}

class XdrLedgerEntryChange {
  XdrLedgerEntryChange();
  XdrLedgerEntryChangeType _type;
  XdrLedgerEntryChangeType get discriminant => this._type;
  set discriminant(XdrLedgerEntryChangeType value) => this._type = value;

  XdrLedgerEntry _created;
  XdrLedgerEntry get created => this._created;
  set created(XdrLedgerEntry value) => this._created = value;

  XdrLedgerEntry _updated;
  XdrLedgerEntry get updated => this._updated;
  set updated(XdrLedgerEntry value) => this._updated = value;

  XdrLedgerKey _removed;
  XdrLedgerKey get removed => this._removed;
  set removed(XdrLedgerKey value) => this._removed = value;

  XdrLedgerEntry _state;
  XdrLedgerEntry get state => this._state;
  set state(XdrLedgerEntry value) => this._state = value;

  static void encode(XdrDataOutputStream stream,
      XdrLedgerEntryChange encodedLedgerEntryChange) {
    stream.writeInt(encodedLedgerEntryChange.discriminant.value);
    switch (encodedLedgerEntryChange.discriminant) {
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.created);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.updated);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED:
        XdrLedgerKey.encode(stream, encodedLedgerEntryChange.removed);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.state);
        break;
    }
  }

  static XdrLedgerEntryChange decode(XdrDataInputStream stream) {
    XdrLedgerEntryChange decodedLedgerEntryChange = XdrLedgerEntryChange();
    XdrLedgerEntryChangeType discriminant =
    XdrLedgerEntryChangeType.decode(stream);
    decodedLedgerEntryChange.discriminant = discriminant;
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
    XdrLedgerEntryChanges decodedLedgerEntryChanges = XdrLedgerEntryChanges();
    int ledgerEntryChangesSize = stream.readInt();
    decodedLedgerEntryChanges.ledgerEntryChanges =
        List<XdrLedgerEntryChange>(ledgerEntryChangesSize);
    for (int i = 0; i < ledgerEntryChangesSize; i++) {
      decodedLedgerEntryChanges.ledgerEntryChanges[i] =
          XdrLedgerEntryChange.decode(stream);
    }
    return decodedLedgerEntryChanges;
  }
}

class XdrLedgerHeaderHistoryEntry {
  XdrLedgerHeaderHistoryEntry();
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
    XdrLedgerHeaderHistoryEntry decodedLedgerHeaderHistoryEntry =
    XdrLedgerHeaderHistoryEntry();
    decodedLedgerHeaderHistoryEntry.hash = XdrHash.decode(stream);
    decodedLedgerHeaderHistoryEntry.header = XdrLedgerHeader.decode(stream);
    decodedLedgerHeaderHistoryEntry.ext =
        XdrLedgerHeaderHistoryEntryExt.decode(stream);
    return decodedLedgerHeaderHistoryEntry;
  }
}

class XdrLedgerHeaderHistoryEntryExt {
  XdrLedgerHeaderHistoryEntryExt();
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
    XdrLedgerHeaderHistoryEntryExt();
    int discriminant = stream.readInt();
    decodedLedgerHeaderHistoryEntryExt.discriminant = discriminant;
    switch (decodedLedgerHeaderHistoryEntryExt.discriminant) {
      case 0:
        break;
    }
    return decodedLedgerHeaderHistoryEntryExt;
  }
}