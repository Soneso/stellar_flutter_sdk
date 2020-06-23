// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_data_entry.dart';
import 'xdr_other.dart';
import 'xdr_signing.dart';

class XdrMuxedAccount {
  XdrMuxedAccount();

  XdrCryptoKeyType _type;
  XdrCryptoKeyType get discriminant => this._type;
  set discriminant(XdrCryptoKeyType value) => this._type = value;

  XdrUint256 _ed25519;
  XdrUint256 get ed25519 => this._ed25519;
  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrMuxedAccountMed25519 _med25519;
  XdrMuxedAccountMed25519 get med25519 => this._med25519;
  set med25519(XdrMuxedAccountMed25519 value) => this._med25519 = value;

  static void encode(XdrDataOutputStream stream, XdrMuxedAccount muxedAccount) {
    stream.writeInt(muxedAccount.discriminant.value);
    switch (muxedAccount.discriminant.value) {
      case XdrCryptoKeyType.KEY_TYPE_ED25519:
        XdrUint256.encode(stream, muxedAccount.ed25519);
        break;
      case XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519:
        XdrMuxedAccountMed25519.encode(stream, muxedAccount.med25519);
        break;
    }
  }

  static XdrMuxedAccount decode(XdrDataInputStream stream) {
    XdrMuxedAccount decoded = XdrMuxedAccount();
    decoded.discriminant = XdrCryptoKeyType.decode(stream);
    switch (decoded.discriminant.value) {
      case XdrCryptoKeyType.KEY_TYPE_ED25519:
        decoded.ed25519 = XdrUint256.decode(stream);
        break;
      case XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519:
        decoded.med25519 = XdrMuxedAccountMed25519.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrMuxedAccountMed25519 {
  XdrMuxedAccountMed25519();

  XdrUint64 _id;
  XdrUint64 get id => this._id;
  set id(XdrUint64 value) => this._id = value;

  XdrUint256 _ed25519;
  XdrUint256 get ed25519 => this._ed25519;
  set ed25519(XdrUint256 value) => this._ed25519 = value;

  static void encode(XdrDataOutputStream stream,
      XdrMuxedAccountMed25519 muxedAccountMed25519Entry) {
    XdrUint64.encode(stream, muxedAccountMed25519Entry.id);
    XdrUint256.encode(stream, muxedAccountMed25519Entry.ed25519);
  }

  static XdrMuxedAccountMed25519 decode(XdrDataInputStream stream) {
    XdrMuxedAccountMed25519 decoded = XdrMuxedAccountMed25519();
    decoded.id = XdrUint64.decode(stream);
    decoded.ed25519 = XdrUint256.decode(stream);
    return decoded;
  }
}

class XdrAccountEntry {
  XdrAccountEntry();
  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrInt64 _balance;
  XdrInt64 get balance => this._balance;
  set balance(XdrInt64 value) => this._balance = value;

  XdrSequenceNumber _seqNum;
  XdrSequenceNumber get seqNum => this._seqNum;
  set seqNum(XdrSequenceNumber value) => this._seqNum = value;

  XdrUint32 _numSubEntries;
  XdrUint32 get numSubEntries => this._numSubEntries;
  set numSubEntries(XdrUint32 value) => this._numSubEntries = value;

  XdrAccountID _inflationDest;
  XdrAccountID get inflationDest => this._inflationDest;
  set inflationDest(XdrAccountID value) => this._inflationDest = value;

  XdrUint32 _flags;
  XdrUint32 get flags => this._flags;
  set flags(XdrUint32 value) => this._flags = value;

  XdrString32 _homeDomain;
  XdrString32 get homeDomain => this._homeDomain;
  set homeDomain(XdrString32 value) => this._homeDomain = value;

  XdrThresholds _thresholds;
  XdrThresholds get thresholds => this._thresholds;
  set thresholds(XdrThresholds value) => this._thresholds = value;

  List<XdrSigner> _signers;
  List<XdrSigner> get signers => this._signers;
  set signers(List<XdrSigner> value) => this._signers = value;

  XdrAccountEntryExt _ext;
  XdrAccountEntryExt get ext => this._ext;
  set ext(XdrAccountEntryExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrAccountEntry encodedAccountEntry) {
    XdrAccountID.encode(stream, encodedAccountEntry.accountID);
    XdrInt64.encode(stream, encodedAccountEntry.balance);
    XdrSequenceNumber.encode(stream, encodedAccountEntry.seqNum);
    XdrUint32.encode(stream, encodedAccountEntry.numSubEntries);
    if (encodedAccountEntry.inflationDest != null) {
      stream.writeInt(1);
      XdrAccountID.encode(stream, encodedAccountEntry.inflationDest);
    } else {
      stream.writeInt(0);
    }
    XdrUint32.encode(stream, encodedAccountEntry.flags);
    XdrString32.encode(stream, encodedAccountEntry.homeDomain);
    XdrThresholds.encode(stream, encodedAccountEntry.thresholds);
    int signersSize = encodedAccountEntry.signers.length;
    stream.writeInt(signersSize);
    for (int i = 0; i < signersSize; i++) {
      XdrSigner.encode(stream, encodedAccountEntry.signers[i]);
    }
    XdrAccountEntryExt.encode(stream, encodedAccountEntry.ext);
  }

  static XdrAccountEntry decode(XdrDataInputStream stream) {
    XdrAccountEntry decodedAccountEntry = XdrAccountEntry();
    decodedAccountEntry.accountID = XdrAccountID.decode(stream);
    decodedAccountEntry.balance = XdrInt64.decode(stream);
    decodedAccountEntry.seqNum = XdrSequenceNumber.decode(stream);
    decodedAccountEntry.numSubEntries = XdrUint32.decode(stream);
    int inflationDestPresent = stream.readInt();
    if (inflationDestPresent != 0) {
      decodedAccountEntry.inflationDest = XdrAccountID.decode(stream);
    }
    decodedAccountEntry.flags = XdrUint32.decode(stream);
    decodedAccountEntry.homeDomain = XdrString32.decode(stream);
    decodedAccountEntry.thresholds = XdrThresholds.decode(stream);
    int signersSize = stream.readInt();
    decodedAccountEntry.signers = List<XdrSigner>(signersSize);
    for (int i = 0; i < signersSize; i++) {
      decodedAccountEntry.signers[i] = XdrSigner.decode(stream);
    }
    decodedAccountEntry.ext = XdrAccountEntryExt.decode(stream);
    return decodedAccountEntry;
  }
}

class XdrAccountEntryExt {
  XdrAccountEntryExt();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrAccountEntryV1 _v1;
  XdrAccountEntryV1 get v1 => this._v1;
  set v1(XdrAccountEntryV1 value) => this._v1 = value;

  static void encode(
      XdrDataOutputStream stream, XdrAccountEntryExt encodedAccountEntryExt) {
    stream.writeInt(encodedAccountEntryExt.discriminant);
    switch (encodedAccountEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrAccountEntryV1.encode(stream, encodedAccountEntryExt.v1);
        break;
    }
  }

  static XdrAccountEntryExt decode(XdrDataInputStream stream) {
    XdrAccountEntryExt decodedAccountEntryExt = XdrAccountEntryExt();
    int discriminant = stream.readInt();
    decodedAccountEntryExt.discriminant = discriminant;
    switch (decodedAccountEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedAccountEntryExt.v1 = XdrAccountEntryV1.decode(stream);
        break;
    }
    return decodedAccountEntryExt;
  }
}

class XdrAccountEntryV1 {
  XdrAccountEntryV1();
  XdrLiabilities _liabilities;
  XdrLiabilities get liabilities => this._liabilities;
  set liabilities(XdrLiabilities value) => this._liabilities = value;

  XdrAccountEntryV1Ext _ext;
  XdrAccountEntryV1Ext get ext => this._ext;
  set ext(XdrAccountEntryV1Ext value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrAccountEntryV1 encodedAccountEntryV1) {
    XdrLiabilities.encode(stream, encodedAccountEntryV1.liabilities);
    XdrAccountEntryV1Ext.encode(stream, encodedAccountEntryV1.ext);
  }

  static XdrAccountEntryV1 decode(XdrDataInputStream stream) {
    XdrAccountEntryV1 decodedAccountEntryV1 = XdrAccountEntryV1();
    decodedAccountEntryV1.liabilities = XdrLiabilities.decode(stream);
    decodedAccountEntryV1.ext = XdrAccountEntryV1Ext.decode(stream);
    return decodedAccountEntryV1;
  }
}

class XdrAccountEntryV1Ext {
  XdrAccountEntryV1Ext();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrAccountEntryV1Ext encodedAccountEntryV1Ext) {
    stream.writeInt(encodedAccountEntryV1Ext.discriminant);
    switch (encodedAccountEntryV1Ext.discriminant) {
      case 0:
        break;
    }
  }

  static XdrAccountEntryV1Ext decode(XdrDataInputStream stream) {
    XdrAccountEntryV1Ext decodedAccountEntryV1Ext = XdrAccountEntryV1Ext();
    int discriminant = stream.readInt();
    decodedAccountEntryV1Ext.discriminant = discriminant;
    switch (decodedAccountEntryV1Ext.discriminant) {
      case 0:
        break;
    }
    return decodedAccountEntryV1Ext;
  }
}

class XdrThresholdIndexes {
  final _value;
  const XdrThresholdIndexes._internal(this._value);
  toString() => 'ThresholdIndexes.$_value';
  XdrThresholdIndexes(this._value);
  get value => this._value;

  static const THRESHOLD_MASTER_WEIGHT = const XdrThresholdIndexes._internal(0);
  static const THRESHOLD_LOW = const XdrThresholdIndexes._internal(1);
  static const THRESHOLD_MED = const XdrThresholdIndexes._internal(2);
  static const THRESHOLD_HIGH = const XdrThresholdIndexes._internal(3);

  static XdrThresholdIndexes decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return THRESHOLD_MASTER_WEIGHT;
      case 1:
        return THRESHOLD_LOW;
      case 2:
        return THRESHOLD_MED;
      case 3:
        return THRESHOLD_HIGH;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrThresholdIndexes value) {
    stream.writeInt(value.value);
  }
}

class XdrAccountID {
  XdrPublicKey _accountID;
  XdrPublicKey get accountID => this._accountID;
  set accountID(XdrPublicKey value) => this._accountID = value;

  static void encode(
      XdrDataOutputStream stream, XdrAccountID encodedAccountID) {
    XdrPublicKey.encode(stream, encodedAccountID.accountID);
  }

  static XdrAccountID decode(XdrDataInputStream stream) {
    XdrAccountID decodedAccountID = XdrAccountID();
    decodedAccountID.accountID = XdrPublicKey.decode(stream);
    return decodedAccountID;
  }
}

class XdrAccountFlags {
  final _value;
  const XdrAccountFlags._internal(this._value);
  toString() => 'AccountFlags.$_value';
  XdrAccountFlags(this._value);
  get value => this._value;

  /// Flags set on issuer accounts
  /// TrustLines are created with authorized set to "false" requiring
  /// the issuer to set it for each TrustLine.
  static const AUTH_REQUIRED_FLAG = const XdrAccountFlags._internal(1);

  /// If set, the authorized flag in TrustLines can be cleared
  /// otherwise, authorization cannot be revoked.
  static const AUTH_REVOCABLE_FLAG = const XdrAccountFlags._internal(2);

  /// Once set, causes all AUTH_* flags to be read-only.
  static const AUTH_IMMUTABLE_FLAG = const XdrAccountFlags._internal(4);

  static XdrAccountFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return AUTH_REQUIRED_FLAG;
      case 2:
        return AUTH_REVOCABLE_FLAG;
      case 4:
        return AUTH_IMMUTABLE_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAccountFlags value) {
    stream.writeInt(value.value);
  }
}

class XdrAccountMergeResult {
  XdrAccountMergeResult();
  XdrAccountMergeResultCode _code;
  XdrAccountMergeResultCode get discriminant => this._code;
  set discriminant(XdrAccountMergeResultCode value) => this._code = value;

  XdrInt64 _sourceAccountBalance;
  XdrInt64 get sourceAccountBalance => this._sourceAccountBalance;
  set sourceAccountBalance(XdrInt64 value) =>
      this._sourceAccountBalance = value;

  static void encode(XdrDataOutputStream stream,
      XdrAccountMergeResult encodedAccountMergeResult) {
    stream.writeInt(encodedAccountMergeResult.discriminant.value);
    switch (encodedAccountMergeResult.discriminant) {
      case XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS:
        XdrInt64.encode(
            stream, encodedAccountMergeResult._sourceAccountBalance);
        break;
      default:
        break;
    }
  }

  static XdrAccountMergeResult decode(XdrDataInputStream stream) {
    XdrAccountMergeResult decodedAccountMergeResult = XdrAccountMergeResult();
    XdrAccountMergeResultCode discriminant =
        XdrAccountMergeResultCode.decode(stream);
    decodedAccountMergeResult.discriminant = discriminant;
    switch (decodedAccountMergeResult.discriminant) {
      case XdrAccountMergeResultCode.ACCOUNT_MERGE_SUCCESS:
        decodedAccountMergeResult._sourceAccountBalance =
            XdrInt64.decode(stream);
        break;
      default:
        break;
    }
    return decodedAccountMergeResult;
  }
}

class XdrAccountMergeResultCode {
  final _value;
  const XdrAccountMergeResultCode._internal(this._value);
  toString() => 'AccountMergeResultCode.$_value';
  XdrAccountMergeResultCode(this._value);
  get value => this._value;

  /// Considered as "success" for the operation.
  static const ACCOUNT_MERGE_SUCCESS =
      const XdrAccountMergeResultCode._internal(0);

  // Codes considered as "failure" for the operation.

  /// Can't merge onto itself.
  static const ACCOUNT_MERGE_MALFORMED =
      const XdrAccountMergeResultCode._internal(-1);

  /// Destination does not exist.
  static const ACCOUNT_MERGE_NO_ACCOUNT =
      const XdrAccountMergeResultCode._internal(-2);

  /// Source account has AUTH_IMMUTABLE set.
  static const ACCOUNT_MERGE_IMMUTABLE_SET =
      const XdrAccountMergeResultCode._internal(-3);

  /// Account has trust lines/offers.
  static const ACCOUNT_MERGE_HAS_SUB_ENTRIES =
      const XdrAccountMergeResultCode._internal(-4);

  /// Sequence number is over max allowed.
  static const ACCOUNT_MERGE_SEQNUM_TOO_FAR =
      const XdrAccountMergeResultCode._internal(-5);

  /// Can't add source balance to destination balance.
  static const ACCOUNT_MERGE_DEST_FULL =
      const XdrAccountMergeResultCode._internal(-6);

  static XdrAccountMergeResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ACCOUNT_MERGE_SUCCESS;
      case -1:
        return ACCOUNT_MERGE_MALFORMED;
      case -2:
        return ACCOUNT_MERGE_NO_ACCOUNT;
      case -3:
        return ACCOUNT_MERGE_IMMUTABLE_SET;
      case -4:
        return ACCOUNT_MERGE_HAS_SUB_ENTRIES;
      case -5:
        return ACCOUNT_MERGE_SEQNUM_TOO_FAR;
      case -6:
        return ACCOUNT_MERGE_DEST_FULL;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrAccountMergeResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrBumpSequenceResultCode {
  final _value;
  const XdrBumpSequenceResultCode._internal(this._value);
  toString() => 'BumpSequenceResultCode.$_value';
  XdrBumpSequenceResultCode(this._value);
  get value => this._value;

  /// Success.
  static const BUMP_SEQUENCE_SUCCESS =
      const XdrBumpSequenceResultCode._internal(0);

  /// `bumpTo` is not within bounds.
  static const BUMP_SEQUENCE_BAD_SEQ =
      const XdrBumpSequenceResultCode._internal(-1);

  static XdrBumpSequenceResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return BUMP_SEQUENCE_SUCCESS;
      case -1:
        return BUMP_SEQUENCE_BAD_SEQ;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrBumpSequenceResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrBumpSequenceOp {
  XdrBumpSequenceOp();
  XdrSequenceNumber _bumpTo;
  XdrSequenceNumber get bumpTo => this._bumpTo;
  set bumpTo(XdrSequenceNumber value) => this._bumpTo = value;

  static void encode(
      XdrDataOutputStream stream, XdrBumpSequenceOp encodedBumpSequenceOp) {
    XdrSequenceNumber.encode(stream, encodedBumpSequenceOp.bumpTo);
  }

  static XdrBumpSequenceOp decode(XdrDataInputStream stream) {
    XdrBumpSequenceOp decodedBumpSequenceOp = XdrBumpSequenceOp();
    decodedBumpSequenceOp.bumpTo = XdrSequenceNumber.decode(stream);
    return decodedBumpSequenceOp;
  }
}

class XdrBumpSequenceResult {
  XdrBumpSequenceResult();
  XdrBumpSequenceResultCode _code;
  XdrBumpSequenceResultCode get discriminant => this._code;
  set discriminant(XdrBumpSequenceResultCode value) => this._code = value;

  static void encode(XdrDataOutputStream stream,
      XdrBumpSequenceResult encodedBumpSequenceResult) {
    stream.writeInt(encodedBumpSequenceResult.discriminant.value);
    switch (encodedBumpSequenceResult.discriminant) {
      case XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrBumpSequenceResult decode(XdrDataInputStream stream) {
    XdrBumpSequenceResult decodedBumpSequenceResult = XdrBumpSequenceResult();
    XdrBumpSequenceResultCode discriminant =
        XdrBumpSequenceResultCode.decode(stream);
    decodedBumpSequenceResult.discriminant = discriminant;
    switch (decodedBumpSequenceResult.discriminant) {
      case XdrBumpSequenceResultCode.BUMP_SEQUENCE_SUCCESS:
        break;
      default:
        break;
    }
    return decodedBumpSequenceResult;
  }
}

class XdrCreateAccountResultCode {
  final _value;
  const XdrCreateAccountResultCode._internal(this._value);
  toString() => 'CreateAccountResultCode.$_value';
  XdrCreateAccountResultCode(this._value);
  get value => this._value;

  /// Account was created.
  static const CREATE_ACCOUNT_SUCCESS =
      const XdrCreateAccountResultCode._internal(0);

  /// Invalid destination.
  static const CREATE_ACCOUNT_MALFORMED =
      const XdrCreateAccountResultCode._internal(-1);

  /// Not enough funds in source account.
  static const CREATE_ACCOUNT_UNDERFUNDED =
      const XdrCreateAccountResultCode._internal(-2);

  /// Would create an account below the min reserve.
  static const CREATE_ACCOUNT_LOW_RESERVE =
      const XdrCreateAccountResultCode._internal(-3);

  /// Account already exists.
  static const CREATE_ACCOUNT_ALREADY_EXIST =
      const XdrCreateAccountResultCode._internal(-4);

  static XdrCreateAccountResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CREATE_ACCOUNT_SUCCESS;
      case -1:
        return CREATE_ACCOUNT_MALFORMED;
      case -2:
        return CREATE_ACCOUNT_UNDERFUNDED;
      case -3:
        return CREATE_ACCOUNT_LOW_RESERVE;
      case -4:
        return CREATE_ACCOUNT_ALREADY_EXIST;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrCreateAccountResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrCreateAccountOp {
  XdrCreateAccountOp();
  XdrAccountID _destination;
  XdrAccountID get destination => this._destination;
  set destination(XdrAccountID value) => this._destination = value;

  XdrInt64 _startingBalance;
  XdrInt64 get startingBalance => this._startingBalance;
  set startingBalance(XdrInt64 value) => this._startingBalance = value;

  static void encode(
      XdrDataOutputStream stream, XdrCreateAccountOp encodedCreateAccountOp) {
    XdrAccountID.encode(stream, encodedCreateAccountOp.destination);
    XdrInt64.encode(stream, encodedCreateAccountOp.startingBalance);
  }

  static XdrCreateAccountOp decode(XdrDataInputStream stream) {
    XdrCreateAccountOp decodedCreateAccountOp = XdrCreateAccountOp();
    decodedCreateAccountOp.destination = XdrAccountID.decode(stream);
    decodedCreateAccountOp.startingBalance = XdrInt64.decode(stream);
    return decodedCreateAccountOp;
  }
}

class XdrCreateAccountResult {
  XdrCreateAccountResult();
  XdrCreateAccountResultCode _code;
  XdrCreateAccountResultCode get discriminant => this._code;
  set discriminant(XdrCreateAccountResultCode value) => this._code = value;

  static void encode(XdrDataOutputStream stream,
      XdrCreateAccountResult encodedCreateAccountResult) {
    stream.writeInt(encodedCreateAccountResult.discriminant.value);
    switch (encodedCreateAccountResult.discriminant) {
      case XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrCreateAccountResult decode(XdrDataInputStream stream) {
    XdrCreateAccountResult decodedCreateAccountResult =
        XdrCreateAccountResult();
    XdrCreateAccountResultCode discriminant =
        XdrCreateAccountResultCode.decode(stream);
    decodedCreateAccountResult.discriminant = discriminant;
    switch (decodedCreateAccountResult.discriminant) {
      case XdrCreateAccountResultCode.CREATE_ACCOUNT_SUCCESS:
        break;
      default:
        break;
    }
    return decodedCreateAccountResult;
  }
}

class XdrInflationPayout {
  XdrInflationPayout();
  XdrAccountID _destination;
  XdrAccountID get destination => this._destination;
  set destination(XdrAccountID value) => this._destination = value;

  XdrInt64 _amount;
  XdrInt64 get amount => this._amount;
  set amount(XdrInt64 value) => this._amount = value;

  static void encode(
      XdrDataOutputStream stream, XdrInflationPayout encodedInflationPayout) {
    XdrAccountID.encode(stream, encodedInflationPayout.destination);
    XdrInt64.encode(stream, encodedInflationPayout.amount);
  }

  static XdrInflationPayout decode(XdrDataInputStream stream) {
    XdrInflationPayout decodedInflationPayout = XdrInflationPayout();
    decodedInflationPayout.destination = XdrAccountID.decode(stream);
    decodedInflationPayout.amount = XdrInt64.decode(stream);
    return decodedInflationPayout;
  }
}

class XdrInflationResult {
  XdrInflationResult();
  XdrInflationResultCode _code;
  XdrInflationResultCode get discriminant => this._code;
  set discriminant(XdrInflationResultCode value) => this._code = value;

  List<XdrInflationPayout> _payouts;
  List<XdrInflationPayout> get payouts => this._payouts;
  set payouts(List<XdrInflationPayout> value) => this._payouts = value;

  static void encode(
      XdrDataOutputStream stream, XdrInflationResult encodedInflationResult) {
    stream.writeInt(encodedInflationResult.discriminant.value);
    switch (encodedInflationResult.discriminant) {
      case XdrInflationResultCode.INFLATION_SUCCESS:
        int payoutssize = encodedInflationResult.payouts.length;
        stream.writeInt(payoutssize);
        for (int i = 0; i < payoutssize; i++) {
          XdrInflationPayout.encode(stream, encodedInflationResult.payouts[i]);
        }
        break;
      default:
        break;
    }
  }

  static XdrInflationResult decode(XdrDataInputStream stream) {
    XdrInflationResult decodedInflationResult = XdrInflationResult();
    XdrInflationResultCode discriminant = XdrInflationResultCode.decode(stream);
    decodedInflationResult.discriminant = discriminant;
    switch (decodedInflationResult.discriminant) {
      case XdrInflationResultCode.INFLATION_SUCCESS:
        int payoutssize = stream.readInt();
        decodedInflationResult.payouts = List<XdrInflationPayout>(payoutssize);
        for (int i = 0; i < payoutssize; i++) {
          decodedInflationResult.payouts[i] = XdrInflationPayout.decode(stream);
        }
        break;
      default:
        break;
    }
    return decodedInflationResult;
  }
}

class XdrInflationResultCode {
  final _value;
  const XdrInflationResultCode._internal(this._value);
  toString() => 'InflationResultCode.$_value';
  XdrInflationResultCode(this._value);
  get value => this._value;

  /// Success.
  static const INFLATION_SUCCESS = const XdrInflationResultCode._internal(0);

  /// Failure.
  static const INFLATION_NOT_TIME = const XdrInflationResultCode._internal(-1);

  static XdrInflationResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return INFLATION_SUCCESS;
      case -1:
        return INFLATION_NOT_TIME;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrInflationResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrManageDataOp {
  XdrManageDataOp();
  XdrString64 _dataName;
  XdrString64 get dataName => this._dataName;
  set dataName(XdrString64 value) => this._dataName = value;

  XdrDataValue _dataValue;
  XdrDataValue get dataValue => this._dataValue;
  set dataValue(XdrDataValue value) => this._dataValue = value;

  static void encode(
      XdrDataOutputStream stream, XdrManageDataOp encodedManageDataOp) {
    XdrString64.encode(stream, encodedManageDataOp.dataName);
    if (encodedManageDataOp.dataValue != null) {
      stream.writeInt(1);
      XdrDataValue.encode(stream, encodedManageDataOp.dataValue);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrManageDataOp decode(XdrDataInputStream stream) {
    XdrManageDataOp decodedManageDataOp = XdrManageDataOp();
    decodedManageDataOp.dataName = XdrString64.decode(stream);
    int dataValuePresent = stream.readInt();
    if (dataValuePresent != 0) {
      decodedManageDataOp.dataValue = XdrDataValue.decode(stream);
    }
    return decodedManageDataOp;
  }
}

class XdrManageDataResult {
  XdrManageDataResult();
  XdrManageDataResultCode _code;
  XdrManageDataResultCode get discriminant => this._code;
  set discriminant(XdrManageDataResultCode value) => this._code = value;

  static void encode(
      XdrDataOutputStream stream, XdrManageDataResult encodedManageDataResult) {
    stream.writeInt(encodedManageDataResult.discriminant.value);
    switch (encodedManageDataResult.discriminant) {
      case XdrManageDataResultCode.MANAGE_DATA_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrManageDataResult decode(XdrDataInputStream stream) {
    XdrManageDataResult decodedManageDataResult = XdrManageDataResult();
    XdrManageDataResultCode discriminant =
        XdrManageDataResultCode.decode(stream);
    decodedManageDataResult.discriminant = discriminant;
    switch (decodedManageDataResult.discriminant) {
      case XdrManageDataResultCode.MANAGE_DATA_SUCCESS:
        break;
      default:
        break;
    }
    return decodedManageDataResult;
  }
}

class XdrManageDataResultCode {
  final _value;
  const XdrManageDataResultCode._internal(this._value);
  toString() => 'ManageDataResultCode.$_value';
  XdrManageDataResultCode(this._value);
  get value => this._value;

  /// Success.
  static const MANAGE_DATA_SUCCESS = const XdrManageDataResultCode._internal(0);

  /// The network hasn't moved to this protocol change yet.
  static const MANAGE_DATA_NOT_SUPPORTED_YET =
      const XdrManageDataResultCode._internal(-1);

  /// Trying to remove a Data Entry that isn't there.
  static const MANAGE_DATA_NAME_NOT_FOUND =
      const XdrManageDataResultCode._internal(-2);

  /// Not enough funds to create a new Data Entry.
  static const MANAGE_DATA_LOW_RESERVE =
      const XdrManageDataResultCode._internal(-3);

  /// Name not a valid string.
  static const MANAGE_DATA_INVALID_NAME =
      const XdrManageDataResultCode._internal(-4);

  static XdrManageDataResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return MANAGE_DATA_SUCCESS;
      case -1:
        return MANAGE_DATA_NOT_SUPPORTED_YET;
      case -2:
        return MANAGE_DATA_NAME_NOT_FOUND;
      case -3:
        return MANAGE_DATA_LOW_RESERVE;
      case -4:
        return MANAGE_DATA_INVALID_NAME;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrManageDataResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSetOptionsResult {
  XdrSetOptionsResult();
  XdrSetOptionsResultCode _code;
  XdrSetOptionsResultCode get discriminant => this._code;
  set discriminant(XdrSetOptionsResultCode value) => this._code = value;

  static void encode(
      XdrDataOutputStream stream, XdrSetOptionsResult encodedSetOptionsResult) {
    stream.writeInt(encodedSetOptionsResult.discriminant.value);
    switch (encodedSetOptionsResult.discriminant) {
      case XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrSetOptionsResult decode(XdrDataInputStream stream) {
    XdrSetOptionsResult decodedSetOptionsResult = XdrSetOptionsResult();
    XdrSetOptionsResultCode discriminant =
        XdrSetOptionsResultCode.decode(stream);
    decodedSetOptionsResult.discriminant = discriminant;
    switch (decodedSetOptionsResult.discriminant) {
      case XdrSetOptionsResultCode.SET_OPTIONS_SUCCESS:
        break;
      default:
        break;
    }
    return decodedSetOptionsResult;
  }
}

class XdrSetOptionsResultCode {
  final _value;
  const XdrSetOptionsResultCode._internal(this._value);
  toString() => 'SetOptionsResultCode.$_value';
  XdrSetOptionsResultCode(this._value);
  get value => this._value;

  /// Success.
  static const SET_OPTIONS_SUCCESS = const XdrSetOptionsResultCode._internal(0);

  /// Not enough funds to add a signer.
  static const SET_OPTIONS_LOW_RESERVE =
      const XdrSetOptionsResultCode._internal(-1);

  /// Max number of signers already reached.
  static const SET_OPTIONS_TOO_MANY_SIGNERS =
      const XdrSetOptionsResultCode._internal(-2);

  /// Invalid combination of clear/set flags.
  static const SET_OPTIONS_BAD_FLAGS =
      const XdrSetOptionsResultCode._internal(-3);

  /// Inflation account does not exist.
  static const SET_OPTIONS_INVALID_INFLATION =
      const XdrSetOptionsResultCode._internal(-4);

  /// Can no longer change this option.
  static const SET_OPTIONS_CANT_CHANGE =
      const XdrSetOptionsResultCode._internal(-5);

  /// Can't set an unknown flag.
  static const SET_OPTIONS_UNKNOWN_FLAG =
      const XdrSetOptionsResultCode._internal(-6);

  /// Bad value for weight/threshold.
  static const SET_OPTIONS_THRESHOLD_OUT_OF_RANGE =
      const XdrSetOptionsResultCode._internal(-7);

  /// Signer cannot be masterkey.
  static const SET_OPTIONS_BAD_SIGNER =
      const XdrSetOptionsResultCode._internal(-8);

  /// Malformed home domain.
  static const SET_OPTIONS_INVALID_HOME_DOMAIN =
      const XdrSetOptionsResultCode._internal(-9);

  static XdrSetOptionsResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SET_OPTIONS_SUCCESS;
      case -1:
        return SET_OPTIONS_LOW_RESERVE;
      case -2:
        return SET_OPTIONS_TOO_MANY_SIGNERS;
      case -3:
        return SET_OPTIONS_BAD_FLAGS;
      case -4:
        return SET_OPTIONS_INVALID_INFLATION;
      case -5:
        return SET_OPTIONS_CANT_CHANGE;
      case -6:
        return SET_OPTIONS_UNKNOWN_FLAG;
      case -7:
        return SET_OPTIONS_THRESHOLD_OUT_OF_RANGE;
      case -8:
        return SET_OPTIONS_BAD_SIGNER;
      case -9:
        return SET_OPTIONS_INVALID_HOME_DOMAIN;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSetOptionsResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSetOptionsOp {
  XdrSetOptionsOp();
  XdrAccountID _inflationDest;
  XdrAccountID get inflationDest => this._inflationDest;
  void set inflationDest(XdrAccountID value) => this._inflationDest = value;

  XdrUint32 _clearFlags;
  XdrUint32 get clearFlags => this._clearFlags;
  set clearFlags(XdrUint32 value) => this._clearFlags = value;

  XdrUint32 _setFlags;
  XdrUint32 get setFlags => this._setFlags;
  set setFlags(XdrUint32 value) => this._setFlags = value;

  XdrUint32 _masterWeight;
  XdrUint32 get masterWeight => this._masterWeight;
  set masterWeight(XdrUint32 value) => this._masterWeight = value;

  XdrUint32 _lowThreshold;
  XdrUint32 get lowThreshold => this._lowThreshold;
  set lowThreshold(XdrUint32 value) => this._lowThreshold = value;

  XdrUint32 _medThreshold;
  XdrUint32 get medThreshold => this._medThreshold;
  set medThreshold(XdrUint32 value) => this._medThreshold = value;

  XdrUint32 _highThreshold;
  XdrUint32 get highThreshold => this._highThreshold;
  set highThreshold(XdrUint32 value) => this._highThreshold = value;

  XdrString32 _homeDomain;
  XdrString32 get homeDomain => this._homeDomain;
  set homeDomain(XdrString32 value) => this._homeDomain = value;

  XdrSigner _signer;
  XdrSigner get signer => this._signer;
  set signer(XdrSigner value) => this._signer = value;

  static void encode(
      XdrDataOutputStream stream, XdrSetOptionsOp encodedSetOptionsOp) {
    if (encodedSetOptionsOp.inflationDest != null) {
      stream.writeInt(1);
      XdrAccountID.encode(stream, encodedSetOptionsOp.inflationDest);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.clearFlags != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.clearFlags);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.setFlags != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.setFlags);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.masterWeight != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.masterWeight);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.lowThreshold != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.lowThreshold);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.medThreshold != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.medThreshold);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.highThreshold != null) {
      stream.writeInt(1);
      XdrUint32.encode(stream, encodedSetOptionsOp.highThreshold);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.homeDomain != null) {
      stream.writeInt(1);
      XdrString32.encode(stream, encodedSetOptionsOp.homeDomain);
    } else {
      stream.writeInt(0);
    }
    if (encodedSetOptionsOp.signer != null) {
      stream.writeInt(1);
      XdrSigner.encode(stream, encodedSetOptionsOp.signer);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrSetOptionsOp decode(XdrDataInputStream stream) {
    XdrSetOptionsOp decodedSetOptionsOp = XdrSetOptionsOp();
    int inflationDestPresent = stream.readInt();
    if (inflationDestPresent != 0) {
      decodedSetOptionsOp.inflationDest = XdrAccountID.decode(stream);
    }
    int clearFlagsPresent = stream.readInt();
    if (clearFlagsPresent != 0) {
      decodedSetOptionsOp.clearFlags = XdrUint32.decode(stream);
    }
    int setFlagsPresent = stream.readInt();
    if (setFlagsPresent != 0) {
      decodedSetOptionsOp.setFlags = XdrUint32.decode(stream);
    }
    int masterWeightPresent = stream.readInt();
    if (masterWeightPresent != 0) {
      decodedSetOptionsOp.masterWeight = XdrUint32.decode(stream);
    }
    int lowThresholdPresent = stream.readInt();
    if (lowThresholdPresent != 0) {
      decodedSetOptionsOp.lowThreshold = XdrUint32.decode(stream);
    }
    int medThresholdPresent = stream.readInt();
    if (medThresholdPresent != 0) {
      decodedSetOptionsOp.medThreshold = XdrUint32.decode(stream);
    }
    int highThresholdPresent = stream.readInt();
    if (highThresholdPresent != 0) {
      decodedSetOptionsOp.highThreshold = XdrUint32.decode(stream);
    }
    int homeDomainPresent = stream.readInt();
    if (homeDomainPresent != 0) {
      decodedSetOptionsOp.homeDomain = XdrString32.decode(stream);
    }
    int signerPresent = stream.readInt();
    if (signerPresent != 0) {
      decodedSetOptionsOp.signer = XdrSigner.decode(stream);
    }
    return decodedSetOptionsOp;
  }
}

class XdrSequenceNumber {
  XdrInt64 _sequenceNumber;
  XdrInt64 get sequenceNumber => this._sequenceNumber;
  set sequenceNumber(XdrInt64 value) => this._sequenceNumber = value;

  static void encode(
      XdrDataOutputStream stream, XdrSequenceNumber encodedSequenceNumber) {
    XdrInt64.encode(stream, encodedSequenceNumber._sequenceNumber);
  }

  static XdrSequenceNumber decode(XdrDataInputStream stream) {
    XdrSequenceNumber decodedSequenceNumber = XdrSequenceNumber();
    decodedSequenceNumber._sequenceNumber = XdrInt64.decode(stream);
    return decodedSequenceNumber;
  }
}
