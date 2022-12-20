// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/src/xdr/xdr_asset.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_ledger.dart';

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_data_entry.dart';
import 'xdr_other.dart';
import 'xdr_signing.dart';

class XdrMuxedAccount {
  XdrCryptoKeyType _type;

  XdrCryptoKeyType get discriminant => this._type;

  set discriminant(XdrCryptoKeyType value) => this._type = value;

  XdrUint256? _ed25519;

  XdrUint256? get ed25519 => this._ed25519;

  set ed25519(XdrUint256? value) => this._ed25519 = value;

  XdrMuxedAccountMed25519? _med25519;

  XdrMuxedAccountMed25519? get med25519 => this._med25519;

  set med25519(XdrMuxedAccountMed25519? value) => this._med25519 = value;

  XdrMuxedAccount(this._type);

  static void encode(XdrDataOutputStream stream, XdrMuxedAccount muxedAccount) {
    stream.writeInt(muxedAccount.discriminant.value);
    switch (muxedAccount.discriminant) {
      case XdrCryptoKeyType.KEY_TYPE_ED25519:
        XdrUint256.encode(stream, muxedAccount.ed25519);
        break;
      case XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519:
        XdrMuxedAccountMed25519.encode(stream, muxedAccount.med25519!);
        break;
    }
  }

  static XdrMuxedAccount decode(XdrDataInputStream stream) {
    XdrMuxedAccount decoded = XdrMuxedAccount(XdrCryptoKeyType.decode(stream));
    switch (decoded.discriminant) {
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
  XdrUint64 _id;

  XdrUint64 get id => this._id;

  set id(XdrUint64 value) => this._id = value;

  XdrUint256 _ed25519;

  XdrUint256 get ed25519 => this._ed25519;

  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrMuxedAccountMed25519(this._id, this._ed25519);

  static void encode(XdrDataOutputStream stream,
      XdrMuxedAccountMed25519 muxedAccountMed25519Entry) {
    XdrUint64.encode(stream, muxedAccountMed25519Entry.id);
    XdrUint256.encode(stream, muxedAccountMed25519Entry.ed25519);
  }

  static void encodeInverted(XdrDataOutputStream stream,
      XdrMuxedAccountMed25519 muxedAccountMed25519Entry) {
    XdrUint256.encode(stream, muxedAccountMed25519Entry.ed25519);
    XdrUint64.encode(stream, muxedAccountMed25519Entry.id);
  }

  static XdrMuxedAccountMed25519 decode(XdrDataInputStream stream) {
    return XdrMuxedAccountMed25519(
        XdrUint64.decode(stream), XdrUint256.decode(stream));
  }

  static XdrMuxedAccountMed25519 decodeInverted(XdrDataInputStream stream) {
    XdrUint256 dEd25519 = XdrUint256.decode(stream);
    XdrUint64 dId = XdrUint64.decode(stream);
    return XdrMuxedAccountMed25519(dId, dEd25519);
  }
}

class XdrAccountEntry {
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

  XdrAccountID? _inflationDest;

  XdrAccountID? get inflationDest => this._inflationDest;

  set inflationDest(XdrAccountID? value) => this._inflationDest = value;

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

  XdrAccountEntry(
      this._accountID,
      this._balance,
      this._seqNum,
      this._numSubEntries,
      this._inflationDest,
      this._flags,
      this._homeDomain,
      this._thresholds,
      this._signers,
      this._ext);

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
    XdrAccountID xAccountID = XdrAccountID.decode(stream);
    XdrInt64 xBalance = XdrInt64.decode(stream);
    XdrSequenceNumber xSeqNum = XdrSequenceNumber.decode(stream);
    XdrUint32 xNumSubEntries = XdrUint32.decode(stream);
    XdrAccountID? xInflationDest;
    int inflationDestPresent = stream.readInt();
    if (inflationDestPresent != 0) {
      xInflationDest = XdrAccountID.decode(stream);
    }
    XdrUint32 xFlags = XdrUint32.decode(stream);
    XdrString32 xHomeDomain = XdrString32.decode(stream);
    XdrThresholds xThresholds = XdrThresholds.decode(stream);
    int signersSize = stream.readInt();
    List<XdrSigner> xSigners = List<XdrSigner>.empty(growable: true);
    for (int i = 0; i < signersSize; i++) {
      xSigners.add(XdrSigner.decode(stream));
    }
    XdrAccountEntryExt xExt = XdrAccountEntryExt.decode(stream);
    return XdrAccountEntry(xAccountID, xBalance, xSeqNum, xNumSubEntries,
        xInflationDest, xFlags, xHomeDomain, xThresholds, xSigners, xExt);
  }
}

class XdrAccountEntryExt {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrAccountEntryV1? _v1;

  XdrAccountEntryV1? get v1 => this._v1;

  set v1(XdrAccountEntryV1? value) => this._v1 = value;

  XdrAccountEntryExt(this._v);

  static void encode(
      XdrDataOutputStream stream, XdrAccountEntryExt encodedAccountEntryExt) {
    stream.writeInt(encodedAccountEntryExt.discriminant);
    switch (encodedAccountEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrAccountEntryV1.encode(stream, encodedAccountEntryExt.v1!);
        break;
    }
  }

  static XdrAccountEntryExt decode(XdrDataInputStream stream) {
    XdrAccountEntryExt decodedAccountEntryExt =
        XdrAccountEntryExt(stream.readInt());
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
  XdrLiabilities _liabilities;

  XdrLiabilities get liabilities => this._liabilities;

  set liabilities(XdrLiabilities value) => this._liabilities = value;

  XdrAccountEntryV1Ext _ext;

  XdrAccountEntryV1Ext get ext => this._ext;

  set ext(XdrAccountEntryV1Ext value) => this._ext = value;

  XdrAccountEntryV1(this._liabilities, this._ext);

  static void encode(
      XdrDataOutputStream stream, XdrAccountEntryV1 encodedAccountEntryV1) {
    XdrLiabilities.encode(stream, encodedAccountEntryV1.liabilities);
    XdrAccountEntryV1Ext.encode(stream, encodedAccountEntryV1.ext);
  }

  static XdrAccountEntryV1 decode(XdrDataInputStream stream) {
    return XdrAccountEntryV1(
        XdrLiabilities.decode(stream), XdrAccountEntryV1Ext.decode(stream));
  }
}

class XdrAccountEntryV1Ext {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrAccountEntryV2? _v2;

  XdrAccountEntryV2? get v2 => this._v2;

  set v2(XdrAccountEntryV2? value) => this._v2 = value;

  XdrAccountEntryV1Ext(this._v);

  static void encode(XdrDataOutputStream stream,
      XdrAccountEntryV1Ext encodedAccountEntryV1Ext) {
    stream.writeInt(encodedAccountEntryV1Ext.discriminant);
    switch (encodedAccountEntryV1Ext.discriminant) {
      case 0:
        break;
      case 2:
        XdrAccountEntryV2.encode(stream, encodedAccountEntryV1Ext.v2!);
        break;
    }
  }

  static XdrAccountEntryV1Ext decode(XdrDataInputStream stream) {
    XdrAccountEntryV1Ext decodedAccountEntryV1Ext =
        XdrAccountEntryV1Ext(stream.readInt());
    switch (decodedAccountEntryV1Ext.discriminant) {
      case 0:
        break;
      case 2:
        decodedAccountEntryV1Ext.v2 = XdrAccountEntryV2.decode(stream);
        break;
    }
    return decodedAccountEntryV1Ext;
  }
}

class XdrAccountEntryV2 {
  XdrUint32 _numSponsored;

  XdrUint32 get numSponsored => this._numSponsored;

  set numSponsored(XdrUint32 value) => this._numSponsored = value;

  XdrUint32 _numSponsoring;

  XdrUint32 get numSponsoring => this._numSponsoring;

  set numSponsoring(XdrUint32 value) => this._numSponsoring = value;

  List<XdrAccountID?> _signerSponsoringIDs;

  List<XdrAccountID?> get signerSponsoringIDs => this._signerSponsoringIDs;

  set signerSponsoringIDs(List<XdrAccountID?> value) =>
      this._signerSponsoringIDs = value;

  XdrAccountEntryV2Ext _ext;

  XdrAccountEntryV2Ext get ext => this._ext;

  set ext(XdrAccountEntryV2Ext value) => this._ext = value;

  XdrAccountEntryV2(this._numSponsored, this._numSponsoring,
      this._signerSponsoringIDs, this._ext);

  static void encode(XdrDataOutputStream stream, XdrAccountEntryV2 encoded) {
    XdrUint32.encode(stream, encoded.numSponsored);
    XdrUint32.encode(stream, encoded.numSponsoring);

    int pSize = encoded.signerSponsoringIDs.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      if (encoded.signerSponsoringIDs[i] != null) {
        stream.writeInt(1);
        XdrAccountID.encode(stream, encoded.signerSponsoringIDs[i]);
      } else {
        stream.writeInt(0);
      }
    }

    XdrAccountEntryV2Ext.encode(stream, encoded.ext);
  }

  static XdrAccountEntryV2 decode(XdrDataInputStream stream) {
    XdrUint32 xNumSponsored = XdrUint32.decode(stream);
    XdrUint32 xNumSponsoring = XdrUint32.decode(stream);
    int pSize = stream.readInt();
    List<XdrAccountID?> xSignerSponsoringIDs = <XdrAccountID?>[]..length =
        pSize;
    for (int i = 0; i < pSize; i++) {
      int sponsoringIDPresent = stream.readInt();
      if (sponsoringIDPresent != 0) {
        xSignerSponsoringIDs[i] = XdrAccountID.decode(stream);
      }
    }
    XdrAccountEntryV2Ext xExt = XdrAccountEntryV2Ext.decode(stream);

    return XdrAccountEntryV2(
        xNumSponsored, xNumSponsoring, xSignerSponsoringIDs, xExt);
  }
}

class XdrAccountEntryV2Ext {
  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrAccountEntryV3? _v3;

  XdrAccountEntryV3? get v3 => this._v3;

  set v3(XdrAccountEntryV3? value) => this._v3 = value;

  XdrAccountEntryV2Ext(this._v);

  static void encode(XdrDataOutputStream stream, XdrAccountEntryV2Ext encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      case 3:
        XdrAccountEntryV3.encode(stream, encoded.v3!);
        break;
    }
  }

  static XdrAccountEntryV2Ext decode(XdrDataInputStream stream) {
    XdrAccountEntryV2Ext decoded = XdrAccountEntryV2Ext(stream.readInt());
    switch (decoded.discriminant) {
      case 0:
        break;
      case 3:
        decoded.v3 = XdrAccountEntryV3.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrAccountEntryV3 {
  XdrAccountEntryV3(this._ext, this._seqLedger, this._seqTime);

  XdrUint32 _seqLedger;

  XdrUint32 get seqLedger => this._seqLedger;

  set seqLedger(XdrUint32 value) => this._seqLedger = value;

  XdrUint64 _seqTime;

  XdrUint64 get seqTime => this._seqTime;

  set seqTime(XdrUint64 value) => this._seqTime = value;

  XdrExtensionPoint _ext;

  XdrExtensionPoint get ext => this._ext;

  set ext(XdrExtensionPoint value) => this._ext = value;

  static void encode(XdrDataOutputStream stream, XdrAccountEntryV3 encoded) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrUint32.encode(stream, encoded.seqLedger);
    XdrUint64.encode(stream, encoded.seqTime);
  }

  static XdrAccountEntryV3 decode(XdrDataInputStream stream) {
    XdrAccountEntryV3 decoded = XdrAccountEntryV3(
        XdrExtensionPoint.decode(stream),
        XdrUint32.decode(stream),
        XdrUint64.decode(stream));
    return decoded;
  }
}

class XdrExtensionPoint {
  XdrExtensionPoint(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream, XdrExtensionPoint encoded) {
    stream.writeInt(encoded.discriminant);
    switch (encoded.discriminant) {
      case 0:
        break;
      default:
        break;
    }
  }

  static XdrExtensionPoint decode(XdrDataInputStream stream) {
    int discriminant = stream.readInt();
    XdrExtensionPoint decoded = XdrExtensionPoint(discriminant);
    switch (decoded.discriminant) {
      case 0:
        break;
    }
    return decoded;
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

  XdrAccountID(this._accountID);

  static void encode(
      XdrDataOutputStream stream, XdrAccountID? encodedAccountID) {
    XdrPublicKey.encode(stream, encodedAccountID!.accountID);
  }

  static XdrAccountID decode(XdrDataInputStream stream) {
    return XdrAccountID(XdrPublicKey.decode(stream));
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

  /// Clawback enabled (0x8): trust lines are created with clawback enabled set to "true", and claimable balances created from those trustlines are created with clawback enabled set to "true"
  static const AUTH_CLAWBACK_ENABLED_FLAG = const XdrAccountFlags._internal(8);

  static XdrAccountFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return AUTH_REQUIRED_FLAG;
      case 2:
        return AUTH_REVOCABLE_FLAG;
      case 4:
        return AUTH_IMMUTABLE_FLAG;
      case 8:
        return AUTH_CLAWBACK_ENABLED_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAccountFlags value) {
    stream.writeInt(value.value);
  }
}

class XdrAccountMergeResult {
  XdrAccountMergeResultCode _code;

  XdrAccountMergeResultCode get discriminant => this._code;

  set discriminant(XdrAccountMergeResultCode value) => this._code = value;

  XdrInt64? _sourceAccountBalance;

  XdrInt64? get sourceAccountBalance => this._sourceAccountBalance;

  XdrAccountMergeResult(this._code);

  set sourceAccountBalance(XdrInt64? value) =>
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
    XdrAccountMergeResult decodedAccountMergeResult =
        XdrAccountMergeResult(XdrAccountMergeResultCode.decode(stream));
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

  /// Can't merge account that is a sponsor.
  static const ACCOUNT_MERGE_IS_SPONSOR =
      const XdrAccountMergeResultCode._internal(-7);

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
      case -7:
        return ACCOUNT_MERGE_IS_SPONSOR;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrAccountMergeResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrBeginSponsoringFutureReservesResultCode {
  final _value;

  const XdrBeginSponsoringFutureReservesResultCode._internal(this._value);

  toString() => 'BeginSponsoringFutureReservesResultCode.$_value';

  XdrBeginSponsoringFutureReservesResultCode(this._value);

  get value => this._value;

  /// Success.
  static const BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS =
      const XdrBeginSponsoringFutureReservesResultCode._internal(0);

  static const BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED =
      const XdrBeginSponsoringFutureReservesResultCode._internal(-1);

  static const BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED =
      const XdrBeginSponsoringFutureReservesResultCode._internal(-2);

  static const BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE =
      const XdrBeginSponsoringFutureReservesResultCode._internal(-3);

  static XdrBeginSponsoringFutureReservesResultCode decode(
      XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS;
      case -1:
        return BEGIN_SPONSORING_FUTURE_RESERVES_MALFORMED;
      case -2:
        return BEGIN_SPONSORING_FUTURE_RESERVES_ALREADY_SPONSORED;
      case -3:
        return BEGIN_SPONSORING_FUTURE_RESERVES_RECURSIVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream,
      XdrBeginSponsoringFutureReservesResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrBeginSponsoringFutureReservesResult {
  XdrBeginSponsoringFutureReservesResultCode _code;

  XdrBeginSponsoringFutureReservesResultCode get discriminant => this._code;

  set discriminant(XdrBeginSponsoringFutureReservesResultCode value) =>
      this._code = value;

  XdrBeginSponsoringFutureReservesResult(this._code);

  static void encode(XdrDataOutputStream stream,
      XdrBeginSponsoringFutureReservesResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrBeginSponsoringFutureReservesResultCode
          .BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrBeginSponsoringFutureReservesResult decode(
      XdrDataInputStream stream) {
    XdrBeginSponsoringFutureReservesResult decoded =
        XdrBeginSponsoringFutureReservesResult(
            XdrBeginSponsoringFutureReservesResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrBeginSponsoringFutureReservesResultCode
          .BEGIN_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrBeginSponsoringFutureReservesOp {
  XdrAccountID _sponsoredID;

  XdrAccountID get sponsoredID => this._sponsoredID;

  set sponsoredID(XdrAccountID value) => this._sponsoredID = value;

  XdrBeginSponsoringFutureReservesOp(this._sponsoredID);

  static void encode(
      XdrDataOutputStream stream, XdrBeginSponsoringFutureReservesOp encoded) {
    XdrAccountID.encode(stream, encoded.sponsoredID);
  }

  static XdrBeginSponsoringFutureReservesOp decode(XdrDataInputStream stream) {
    return XdrBeginSponsoringFutureReservesOp(XdrAccountID.decode(stream));
  }
}

class XdrEndSponsoringFutureReservesResultCode {
  final _value;

  const XdrEndSponsoringFutureReservesResultCode._internal(this._value);

  toString() => 'EndSponsoringFutureReservesResultCode.$_value';

  XdrEndSponsoringFutureReservesResultCode(this._value);

  get value => this._value;

  /// Success.
  static const END_SPONSORING_FUTURE_RESERVES_SUCCESS =
      const XdrEndSponsoringFutureReservesResultCode._internal(0);

  static const END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED =
      const XdrEndSponsoringFutureReservesResultCode._internal(-1);

  static XdrEndSponsoringFutureReservesResultCode decode(
      XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return END_SPONSORING_FUTURE_RESERVES_SUCCESS;
      case -1:
        return END_SPONSORING_FUTURE_RESERVES_NOT_SPONSORED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream,
      XdrEndSponsoringFutureReservesResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrEndSponsoringFutureReservesResult {
  XdrEndSponsoringFutureReservesResultCode _code;

  XdrEndSponsoringFutureReservesResultCode get discriminant => this._code;

  set discriminant(XdrEndSponsoringFutureReservesResultCode value) =>
      this._code = value;

  XdrEndSponsoringFutureReservesResult(this._code);

  static void encode(XdrDataOutputStream stream,
      XdrEndSponsoringFutureReservesResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrEndSponsoringFutureReservesResultCode
          .END_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrEndSponsoringFutureReservesResult decode(
      XdrDataInputStream stream) {
    XdrEndSponsoringFutureReservesResult decoded =
        XdrEndSponsoringFutureReservesResult(
            XdrEndSponsoringFutureReservesResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrEndSponsoringFutureReservesResultCode
          .END_SPONSORING_FUTURE_RESERVES_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrRevokeSponsorshipResultCode {
  final _value;

  const XdrRevokeSponsorshipResultCode._internal(this._value);

  toString() => 'RevokeSponsorshipResultCode.$_value';

  XdrRevokeSponsorshipResultCode(this._value);

  get value => this._value;

  /// Success.
  static const REVOKE_SPONSORSHIP_SUCCESS =
      const XdrRevokeSponsorshipResultCode._internal(0);

  static const REVOKE_SPONSORSHIP_DOES_NOT_EXIST =
      const XdrRevokeSponsorshipResultCode._internal(-1);

  static const REVOKE_SPONSORSHIP_NOT_SPONSOR =
      const XdrRevokeSponsorshipResultCode._internal(-2);

  static const REVOKE_SPONSORSHIP_LOW_RESERVE =
      const XdrRevokeSponsorshipResultCode._internal(-3);

  static const REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE =
      const XdrRevokeSponsorshipResultCode._internal(-4);

  static const REVOKE_SPONSORSHIP_MALFORMED =
      const XdrRevokeSponsorshipResultCode._internal(-5);

  static XdrRevokeSponsorshipResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return REVOKE_SPONSORSHIP_SUCCESS;
      case -1:
        return REVOKE_SPONSORSHIP_DOES_NOT_EXIST;
      case -2:
        return REVOKE_SPONSORSHIP_NOT_SPONSOR;
      case -3:
        return REVOKE_SPONSORSHIP_LOW_RESERVE;
      case -4:
        return REVOKE_SPONSORSHIP_ONLY_TRANSFERABLE;
      case -5:
        return REVOKE_SPONSORSHIP_MALFORMED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrRevokeSponsorshipResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrRevokeSponsorshipResult {
  XdrRevokeSponsorshipResultCode _code;

  XdrRevokeSponsorshipResultCode get discriminant => this._code;

  set discriminant(XdrRevokeSponsorshipResultCode value) => this._code = value;

  XdrRevokeSponsorshipResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrRevokeSponsorshipResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrRevokeSponsorshipResult decode(XdrDataInputStream stream) {
    XdrRevokeSponsorshipResult decoded = XdrRevokeSponsorshipResult(
        XdrRevokeSponsorshipResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrRevokeSponsorshipResultCode.REVOKE_SPONSORSHIP_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrRevokeSponsorshipType {
  final _value;

  const XdrRevokeSponsorshipType._internal(this._value);

  toString() => 'RevokeSponsorshipType.$_value';

  XdrRevokeSponsorshipType(this._value);

  get value => this._value;

  static const REVOKE_SPONSORSHIP_LEDGER_ENTRY =
      const XdrRevokeSponsorshipType._internal(0);
  static const REVOKE_SPONSORSHIP_SIGNER =
      const XdrRevokeSponsorshipType._internal(1);

  static XdrRevokeSponsorshipType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return REVOKE_SPONSORSHIP_LEDGER_ENTRY;
      case 1:
        return REVOKE_SPONSORSHIP_SIGNER;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrRevokeSponsorshipType value) {
    stream.writeInt(value.value);
  }
}

class XdrRevokeSponsorshipOp {
  XdrRevokeSponsorshipType _type;

  XdrRevokeSponsorshipType get discriminant => this._type;

  set discriminant(XdrRevokeSponsorshipType value) => this._type = value;

  XdrLedgerKey? _ledgerKey;

  XdrLedgerKey? get ledgerKey => this._ledgerKey;

  set ledgerKey(XdrLedgerKey? value) => this._ledgerKey = value;

  XdrRevokeSponsorshipSigner? _signer;

  XdrRevokeSponsorshipSigner? get signer => this._signer;

  set signer(XdrRevokeSponsorshipSigner? value) => this._signer = value;

  XdrRevokeSponsorshipOp(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrRevokeSponsorshipOp encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY:
        XdrLedgerKey.encode(stream, encoded.ledgerKey!);
        break;
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER:
        XdrRevokeSponsorshipSigner.encode(stream, encoded.signer!);
        break;
    }
  }

  static XdrRevokeSponsorshipOp decode(XdrDataInputStream stream) {
    XdrRevokeSponsorshipOp decoded =
        XdrRevokeSponsorshipOp(XdrRevokeSponsorshipType.decode(stream));
    switch (decoded.discriminant) {
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_LEDGER_ENTRY:
        decoded.ledgerKey = XdrLedgerKey.decode(stream);
        break;
      case XdrRevokeSponsorshipType.REVOKE_SPONSORSHIP_SIGNER:
        decoded.signer = XdrRevokeSponsorshipSigner.decode(stream);
        break;
    }
    return decoded;
  }
}

class XdrRevokeSponsorshipSigner {
  XdrAccountID _accountId;

  XdrAccountID get accountId => this._accountId;

  set accountId(XdrAccountID value) => this._accountId = value;

  XdrSignerKey _signerKey;

  XdrSignerKey get signerKey => this._signerKey;

  set signerKey(XdrSignerKey value) => this._signerKey = value;

  XdrRevokeSponsorshipSigner(this._accountId, this._signerKey);

  static void encode(
      XdrDataOutputStream stream, XdrRevokeSponsorshipSigner encoded) {
    XdrAccountID.encode(stream, encoded.accountId);
    XdrSignerKey.encode(stream, encoded.signerKey);
  }

  static XdrRevokeSponsorshipSigner decode(XdrDataInputStream stream) {
    return XdrRevokeSponsorshipSigner(
        XdrAccountID.decode(stream), XdrSignerKey.decode(stream));
  }
}

class XdrCreateClaimableBalanceResultCode {
  final _value;

  const XdrCreateClaimableBalanceResultCode._internal(this._value);

  toString() => 'CreateClaimableBalanceResultCode.$_value';

  XdrCreateClaimableBalanceResultCode(this._value);

  get value => this._value;

  /// Success.
  static const CREATE_CLAIMABLE_BALANCE_SUCCESS =
      const XdrCreateClaimableBalanceResultCode._internal(0);

  static const CREATE_CLAIMABLE_BALANCE_MALFORMED =
      const XdrCreateClaimableBalanceResultCode._internal(-1);

  static const CREATE_CLAIMABLE_BALANCE_LOW_RESERVE =
      const XdrCreateClaimableBalanceResultCode._internal(-2);

  static const CREATE_CLAIMABLE_BALANCE_NO_TRUST =
      const XdrCreateClaimableBalanceResultCode._internal(-3);

  static const CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED =
      const XdrCreateClaimableBalanceResultCode._internal(-4);

  static const CREATE_CLAIMABLE_BALANCE_UNDERFUNDED =
      const XdrCreateClaimableBalanceResultCode._internal(-5);

  static XdrCreateClaimableBalanceResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CREATE_CLAIMABLE_BALANCE_SUCCESS;
      case -1:
        return CREATE_CLAIMABLE_BALANCE_MALFORMED;
      case -2:
        return CREATE_CLAIMABLE_BALANCE_LOW_RESERVE;
      case -3:
        return CREATE_CLAIMABLE_BALANCE_NO_TRUST;
      case -4:
        return CREATE_CLAIMABLE_BALANCE_NOT_AUTHORIZED;
      case -5:
        return CREATE_CLAIMABLE_BALANCE_UNDERFUNDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrCreateClaimableBalanceResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrCreateClaimableBalanceOp {
  XdrAsset _asset;

  XdrAsset get asset => this._asset;

  set asset(XdrAsset value) => this._asset = value;

  XdrInt64 _amount;

  XdrInt64 get amount => this._amount;

  set amount(XdrInt64 value) => this._amount = value;

  List<XdrClaimant> _claimants;

  List<XdrClaimant> get claimants => this._claimants;

  set claimants(List<XdrClaimant> value) => this._claimants = value;

  XdrCreateClaimableBalanceOp(this._asset, this._amount, this._claimants);

  static void encode(
      XdrDataOutputStream stream, XdrCreateClaimableBalanceOp encoded) {
    XdrAsset.encode(stream, encoded.asset);
    XdrInt64.encode(stream, encoded.amount);
    int pSize = encoded.claimants.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      XdrClaimant.encode(stream, encoded.claimants[i]);
    }
  }

  static XdrCreateClaimableBalanceOp decode(XdrDataInputStream stream) {
    XdrAsset xAsset = XdrAsset.decode(stream);
    XdrInt64 xAmount = XdrInt64.decode(stream);
    int pSize = stream.readInt();
    List<XdrClaimant> xClaimants = List<XdrClaimant>.empty(growable: true);
    for (int i = 0; i < pSize; i++) {
      xClaimants.add(XdrClaimant.decode(stream));
    }
    return XdrCreateClaimableBalanceOp(xAsset, xAmount, xClaimants);
  }
}

class XdrCreateClaimableBalanceResult {
  XdrCreateClaimableBalanceResultCode _code;

  XdrCreateClaimableBalanceResultCode get discriminant => this._code;

  set discriminant(XdrCreateClaimableBalanceResultCode value) =>
      this._code = value;

  XdrClaimableBalanceID? _balanceID;

  XdrClaimableBalanceID? get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID? value) => this._balanceID = value;

  XdrCreateClaimableBalanceResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrCreateClaimableBalanceResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_SUCCESS:
        XdrClaimableBalanceID.encode(stream, encoded.balanceID!);
        break;
      default:
        break;
    }
  }

  static XdrCreateClaimableBalanceResult decode(XdrDataInputStream stream) {
    XdrCreateClaimableBalanceResult decoded = XdrCreateClaimableBalanceResult(
        XdrCreateClaimableBalanceResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrCreateClaimableBalanceResultCode.CREATE_CLAIMABLE_BALANCE_SUCCESS:
        decoded.balanceID = XdrClaimableBalanceID.decode(stream);
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrClaimClaimableBalanceResultCode {
  final _value;

  const XdrClaimClaimableBalanceResultCode._internal(this._value);

  toString() => 'ClaimClaimableBalanceResultCode.$_value';

  XdrClaimClaimableBalanceResultCode(this._value);

  get value => this._value;

  /// Success.
  static const CLAIM_CLAIMABLE_BALANCE_SUCCESS =
      const XdrClaimClaimableBalanceResultCode._internal(0);

  static const CLAIM_CLAIMABLE_BALANCE_DOES_NOT_EXIST =
      const XdrClaimClaimableBalanceResultCode._internal(-1);

  static const CLAIM_CLAIMABLE_BALANCE_CANNOT_CLAIM =
      const XdrClaimClaimableBalanceResultCode._internal(-2);

  static const CLAIM_CLAIMABLE_BALANCE_LINE_FULL =
      const XdrClaimClaimableBalanceResultCode._internal(-3);

  static const CLAIM_CLAIMABLE_BALANCE_NO_TRUST =
      const XdrClaimClaimableBalanceResultCode._internal(-4);

  static const CLAIM_CLAIMABLE_BALANCE_NOT_AUTHORIZED =
      const XdrClaimClaimableBalanceResultCode._internal(-5);

  static XdrClaimClaimableBalanceResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAIM_CLAIMABLE_BALANCE_SUCCESS;
      case -1:
        return CLAIM_CLAIMABLE_BALANCE_DOES_NOT_EXIST;
      case -2:
        return CLAIM_CLAIMABLE_BALANCE_CANNOT_CLAIM;
      case -3:
        return CLAIM_CLAIMABLE_BALANCE_LINE_FULL;
      case -4:
        return CLAIM_CLAIMABLE_BALANCE_NO_TRUST;
      case -5:
        return CLAIM_CLAIMABLE_BALANCE_NOT_AUTHORIZED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrClaimClaimableBalanceResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrClaimClaimableBalanceOp {
  XdrClaimableBalanceID _balanceID;

  XdrClaimableBalanceID get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID value) => this._balanceID = value;

  XdrClaimClaimableBalanceOp(this._balanceID);

  static void encode(
      XdrDataOutputStream stream, XdrClaimClaimableBalanceOp encoded) {
    XdrClaimableBalanceID.encode(stream, encoded.balanceID);
  }

  static XdrClaimClaimableBalanceOp decode(XdrDataInputStream stream) {
    return XdrClaimClaimableBalanceOp(XdrClaimableBalanceID.decode(stream));
  }
}

class XdrClaimClaimableBalanceResult {
  XdrClaimClaimableBalanceResultCode _code;

  XdrClaimClaimableBalanceResultCode get discriminant => this._code;

  set discriminant(XdrClaimClaimableBalanceResultCode value) =>
      this._code = value;

  XdrClaimClaimableBalanceResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrClaimClaimableBalanceResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrClaimClaimableBalanceResult decode(XdrDataInputStream stream) {
    XdrClaimClaimableBalanceResult decoded = XdrClaimClaimableBalanceResult(
        XdrClaimClaimableBalanceResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrClaimClaimableBalanceResultCode.CLAIM_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrClawbackClaimableBalanceOp {
  XdrClaimableBalanceID _balanceID;

  XdrClaimableBalanceID get balanceID => this._balanceID;

  set balanceID(XdrClaimableBalanceID value) => this._balanceID = value;

  XdrClawbackClaimableBalanceOp(this._balanceID);

  static void encode(
      XdrDataOutputStream stream, XdrClawbackClaimableBalanceOp encoded) {
    XdrClaimableBalanceID.encode(stream, encoded.balanceID);
  }

  static XdrClawbackClaimableBalanceOp decode(XdrDataInputStream stream) {
    return XdrClawbackClaimableBalanceOp(XdrClaimableBalanceID.decode(stream));
  }
}

class XdrClawbackClaimableBalanceResultCode {
  final _value;

  const XdrClawbackClaimableBalanceResultCode._internal(this._value);

  toString() => 'ClawbackClaimableBalanceResultCode.$_value';

  XdrClawbackClaimableBalanceResultCode(this._value);

  get value => this._value;

  /// Success.
  static const CLAWBACK_CLAIMABLE_BALANCE_SUCCESS =
      const XdrClawbackClaimableBalanceResultCode._internal(0);

  static const CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST =
      const XdrClawbackClaimableBalanceResultCode._internal(-1);

  static const CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER =
      const XdrClawbackClaimableBalanceResultCode._internal(-2);

  static const CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED =
      const XdrClawbackClaimableBalanceResultCode._internal(-3);

  static XdrClawbackClaimableBalanceResultCode decode(
      XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAWBACK_CLAIMABLE_BALANCE_SUCCESS;
      case -1:
        return CLAWBACK_CLAIMABLE_BALANCE_DOES_NOT_EXIST;
      case -2:
        return CLAWBACK_CLAIMABLE_BALANCE_NOT_ISSUER;
      case -3:
        return CLAWBACK_CLAIMABLE_BALANCE_NOT_CLAWBACK_ENABLED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrClaimClaimableBalanceResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrClawbackClaimableBalanceResult {
  XdrClawbackClaimableBalanceResultCode _code;

  XdrClawbackClaimableBalanceResultCode get discriminant => this._code;

  set discriminant(XdrClawbackClaimableBalanceResultCode value) =>
      this._code = value;

  XdrClawbackClaimableBalanceResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrClawbackClaimableBalanceResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrClawbackClaimableBalanceResultCode
          .CLAWBACK_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrClawbackClaimableBalanceResult decode(XdrDataInputStream stream) {
    XdrClawbackClaimableBalanceResult decoded =
        XdrClawbackClaimableBalanceResult(
            XdrClawbackClaimableBalanceResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrClawbackClaimableBalanceResultCode
          .CLAWBACK_CLAIMABLE_BALANCE_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
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
  XdrSequenceNumber _bumpTo;

  XdrSequenceNumber get bumpTo => this._bumpTo;

  set bumpTo(XdrSequenceNumber value) => this._bumpTo = value;

  XdrBumpSequenceOp(this._bumpTo);

  static void encode(
      XdrDataOutputStream stream, XdrBumpSequenceOp encodedBumpSequenceOp) {
    XdrSequenceNumber.encode(stream, encodedBumpSequenceOp.bumpTo);
  }

  static XdrBumpSequenceOp decode(XdrDataInputStream stream) {
    return XdrBumpSequenceOp(XdrSequenceNumber.decode(stream));
  }
}

class XdrBumpSequenceResult {
  XdrBumpSequenceResultCode _code;

  XdrBumpSequenceResultCode get discriminant => this._code;

  set discriminant(XdrBumpSequenceResultCode value) => this._code = value;

  XdrBumpSequenceResult(this._code);

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
    XdrBumpSequenceResult decodedBumpSequenceResult =
        XdrBumpSequenceResult(XdrBumpSequenceResultCode.decode(stream));
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
  XdrAccountID _destination;

  XdrAccountID get destination => this._destination;

  set destination(XdrAccountID value) => this._destination = value;

  XdrInt64 _startingBalance;

  XdrInt64 get startingBalance => this._startingBalance;

  set startingBalance(XdrInt64 value) => this._startingBalance = value;

  XdrCreateAccountOp(this._destination, this._startingBalance);

  static void encode(
      XdrDataOutputStream stream, XdrCreateAccountOp encodedCreateAccountOp) {
    XdrAccountID.encode(stream, encodedCreateAccountOp.destination);
    XdrInt64.encode(stream, encodedCreateAccountOp.startingBalance);
  }

  static XdrCreateAccountOp decode(XdrDataInputStream stream) {
    return XdrCreateAccountOp(
        XdrAccountID.decode(stream), XdrInt64.decode(stream));
  }
}

class XdrCreateAccountResult {
  XdrCreateAccountResultCode _code;

  XdrCreateAccountResultCode get discriminant => this._code;

  set discriminant(XdrCreateAccountResultCode value) => this._code = value;

  XdrCreateAccountResult(this._code);

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
        XdrCreateAccountResult(XdrCreateAccountResultCode.decode(stream));
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
  XdrAccountID _destination;

  XdrAccountID get destination => this._destination;

  set destination(XdrAccountID value) => this._destination = value;

  XdrInt64 _amount;

  XdrInt64 get amount => this._amount;

  set amount(XdrInt64 value) => this._amount = value;

  XdrInflationPayout(this._destination, this._amount);

  static void encode(
      XdrDataOutputStream stream, XdrInflationPayout encodedInflationPayout) {
    XdrAccountID.encode(stream, encodedInflationPayout.destination);
    XdrInt64.encode(stream, encodedInflationPayout.amount);
  }

  static XdrInflationPayout decode(XdrDataInputStream stream) {
    return XdrInflationPayout(
        XdrAccountID.decode(stream), XdrInt64.decode(stream));
  }
}

class XdrInflationResult {
  XdrInflationResultCode _code;

  XdrInflationResultCode get discriminant => this._code;

  set discriminant(XdrInflationResultCode value) => this._code = value;

  List<XdrInflationPayout>? _payouts;

  List<XdrInflationPayout>? get payouts => this._payouts;

  set payouts(List<XdrInflationPayout>? value) => this._payouts = value;

  XdrInflationResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrInflationResult encodedInflationResult) {
    stream.writeInt(encodedInflationResult.discriminant.value);
    switch (encodedInflationResult.discriminant) {
      case XdrInflationResultCode.INFLATION_SUCCESS:
        int payoutssize = encodedInflationResult.payouts!.length;
        stream.writeInt(payoutssize);
        for (int i = 0; i < payoutssize; i++) {
          XdrInflationPayout.encode(stream, encodedInflationResult.payouts![i]);
        }
        break;
      default:
        break;
    }
  }

  static XdrInflationResult decode(XdrDataInputStream stream) {
    XdrInflationResult decodedInflationResult =
        XdrInflationResult(XdrInflationResultCode.decode(stream));
    switch (decodedInflationResult.discriminant) {
      case XdrInflationResultCode.INFLATION_SUCCESS:
        int payoutssize = stream.readInt();
        List<XdrInflationPayout> payouts =
            List<XdrInflationPayout>.empty(growable: true);
        for (int i = 0; i < payoutssize; i++) {
          payouts.add(XdrInflationPayout.decode(stream));
        }
        decodedInflationResult.payouts = payouts;
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
  XdrString64 _dataName;

  XdrString64 get dataName => this._dataName;

  set dataName(XdrString64 value) => this._dataName = value;

  XdrDataValue? _dataValue;

  XdrDataValue? get dataValue => this._dataValue;

  set dataValue(XdrDataValue? value) => this._dataValue = value;

  XdrManageDataOp(this._dataName, this._dataValue);

  static void encode(
      XdrDataOutputStream stream, XdrManageDataOp encodedManageDataOp) {
    XdrString64.encode(stream, encodedManageDataOp.dataName);
    if (encodedManageDataOp.dataValue != null) {
      stream.writeInt(1);
      XdrDataValue.encode(stream, encodedManageDataOp.dataValue!);
    } else {
      stream.writeInt(0);
    }
  }

  static XdrManageDataOp decode(XdrDataInputStream stream) {
    XdrString64 xDataName = XdrString64.decode(stream);
    XdrDataValue? xDataValue;
    int dataValuePresent = stream.readInt();
    if (dataValuePresent != 0) {
      xDataValue = XdrDataValue.decode(stream);
    }
    return XdrManageDataOp(xDataName, xDataValue);
  }
}

class XdrManageDataResult {
  XdrManageDataResultCode _code;

  XdrManageDataResultCode get discriminant => this._code;

  set discriminant(XdrManageDataResultCode value) => this._code = value;

  XdrManageDataResult(this._code);

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
    XdrManageDataResult decodedManageDataResult =
        XdrManageDataResult(XdrManageDataResultCode.decode(stream));
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
  XdrSetOptionsResultCode _code;

  XdrSetOptionsResultCode get discriminant => this._code;

  set discriminant(XdrSetOptionsResultCode value) => this._code = value;

  XdrSetOptionsResult(this._code);

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
    XdrSetOptionsResult decodedSetOptionsResult =
        XdrSetOptionsResult(XdrSetOptionsResultCode.decode(stream));
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

  XdrAccountID? _inflationDest;

  XdrAccountID? get inflationDest => this._inflationDest;

  set inflationDest(XdrAccountID? value) => this._inflationDest = value;

  XdrUint32? _clearFlags;

  XdrUint32? get clearFlags => this._clearFlags;

  set clearFlags(XdrUint32? value) => this._clearFlags = value;

  XdrUint32? _setFlags;

  XdrUint32? get setFlags => this._setFlags;

  set setFlags(XdrUint32? value) => this._setFlags = value;

  XdrUint32? _masterWeight;

  XdrUint32? get masterWeight => this._masterWeight;

  set masterWeight(XdrUint32? value) => this._masterWeight = value;

  XdrUint32? _lowThreshold;

  XdrUint32? get lowThreshold => this._lowThreshold;

  set lowThreshold(XdrUint32? value) => this._lowThreshold = value;

  XdrUint32? _medThreshold;

  XdrUint32? get medThreshold => this._medThreshold;

  set medThreshold(XdrUint32? value) => this._medThreshold = value;

  XdrUint32? _highThreshold;

  XdrUint32? get highThreshold => this._highThreshold;

  set highThreshold(XdrUint32? value) => this._highThreshold = value;

  XdrString32? _homeDomain;

  XdrString32? get homeDomain => this._homeDomain;

  set homeDomain(XdrString32? value) => this._homeDomain = value;

  XdrSigner? _signer;

  XdrSigner? get signer => this._signer;

  set signer(XdrSigner? value) => this._signer = value;

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

  XdrSequenceNumber(this._sequenceNumber);

  static void encode(
      XdrDataOutputStream stream, XdrSequenceNumber encodedSequenceNumber) {
    XdrInt64.encode(stream, encodedSequenceNumber._sequenceNumber);
  }

  static XdrSequenceNumber decode(XdrDataInputStream stream) {
    return XdrSequenceNumber(XdrInt64.decode(stream));
  }
}

class XdrLiquidityPoolDepositOp {
  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrInt64 _maxAmountA;
  XdrInt64 get maxAmountA => this._maxAmountA;
  set maxAmountA(XdrInt64 value) => this._maxAmountA = value;

  XdrInt64 _maxAmountB;
  XdrInt64 get maxAmountB => this._maxAmountB;
  set maxAmountB(XdrInt64 value) => this._maxAmountB = value;

  XdrPrice _minPrice;
  XdrPrice get minPrice => this._minPrice;
  set minPrice(XdrPrice value) => this._minPrice = value;

  XdrPrice _maxPrice;
  XdrPrice get maxPrice => this._maxPrice;
  set maxPrice(XdrPrice value) => this._maxPrice = value;

  XdrLiquidityPoolDepositOp(this._liquidityPoolID, this._maxAmountA,
      this._maxAmountB, this._minPrice, this._maxPrice);

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolDepositOp encoded) {
    XdrHash.encode(stream, encoded.liquidityPoolID);
    XdrInt64.encode(stream, encoded.maxAmountA);
    XdrInt64.encode(stream, encoded.maxAmountB);
    XdrPrice.encode(stream, encoded.minPrice);
    XdrPrice.encode(stream, encoded.maxPrice);
  }

  static XdrLiquidityPoolDepositOp decode(XdrDataInputStream stream) {
    XdrHash xLiquidityPoolID = XdrHash.decode(stream);
    XdrInt64 xMaxAmountA = XdrInt64.decode(stream);
    XdrInt64 xMaxAmountB = XdrInt64.decode(stream);
    XdrPrice xMinPrice = XdrPrice.decode(stream);
    XdrPrice xMaxPrice = XdrPrice.decode(stream);
    return XdrLiquidityPoolDepositOp(
        xLiquidityPoolID, xMaxAmountA, xMaxAmountB, xMinPrice, xMaxPrice);
  }
}

class XdrLiquidityPoolDepositResult {
  XdrLiquidityPoolDepositResultCode _code;

  XdrLiquidityPoolDepositResultCode get discriminant => this._code;

  set discriminant(XdrLiquidityPoolDepositResultCode value) =>
      this._code = value;

  XdrLiquidityPoolDepositResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolDepositResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrLiquidityPoolDepositResult decode(XdrDataInputStream stream) {
    XdrLiquidityPoolDepositResult decoded = XdrLiquidityPoolDepositResult(
        XdrLiquidityPoolDepositResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrLiquidityPoolDepositResultCode.LIQUIDITY_POOL_DEPOSIT_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrLiquidityPoolDepositResultCode {
  final _value;

  const XdrLiquidityPoolDepositResultCode._internal(this._value);

  toString() => 'XdrLiquidityPoolDepositResultCode.$_value';

  XdrLiquidityPoolDepositResultCode(this._value);

  get value => this._value;

  /// Success.
  static const LIQUIDITY_POOL_DEPOSIT_SUCCESS =
      const XdrLiquidityPoolDepositResultCode._internal(0);

  /// bad input.
  static const LIQUIDITY_POOL_DEPOSIT_MALFORMED =
      const XdrLiquidityPoolDepositResultCode._internal(-1);

  /// no trust line for one of the assets
  static const LIQUIDITY_POOL_DEPOSIT_NO_TRUST =
      const XdrLiquidityPoolDepositResultCode._internal(-2);

  /// not authorized for one of the assets
  static const LIQUIDITY_POOL_DEPOSIT_NOT_AUTHORIZED =
      const XdrLiquidityPoolDepositResultCode._internal(-3);

  /// not enough balance for one of the assets
  static const LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED =
      const XdrLiquidityPoolDepositResultCode._internal(-4);

  /// pool share trust line doesn't have sufficient limit
  static const LIQUIDITY_POOL_DEPOSIT_LINE_FULL =
      const XdrLiquidityPoolDepositResultCode._internal(-5);

  /// deposit price outside bounds
  static const LIQUIDITY_POOL_DEPOSIT_BAD_PRICE =
      const XdrLiquidityPoolDepositResultCode._internal(-6);

  /// pool reserves are full.
  static const LIQUIDITY_POOL_DEPOSIT_POOL_FULL =
      const XdrLiquidityPoolDepositResultCode._internal(-7);

  static XdrLiquidityPoolDepositResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return LIQUIDITY_POOL_DEPOSIT_SUCCESS;
      case -1:
        return LIQUIDITY_POOL_DEPOSIT_MALFORMED;
      case -2:
        return LIQUIDITY_POOL_DEPOSIT_NO_TRUST;
      case -3:
        return LIQUIDITY_POOL_DEPOSIT_NOT_AUTHORIZED;
      case -4:
        return LIQUIDITY_POOL_DEPOSIT_UNDERFUNDED;
      case -5:
        return LIQUIDITY_POOL_DEPOSIT_LINE_FULL;
      case -6:
        return LIQUIDITY_POOL_DEPOSIT_BAD_PRICE;
      case -7:
        return LIQUIDITY_POOL_DEPOSIT_POOL_FULL;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolDepositResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrLiquidityPoolWithdrawOp {
  XdrHash _liquidityPoolID;
  XdrHash get liquidityPoolID => this._liquidityPoolID;
  set liquidityPoolID(XdrHash value) => this._liquidityPoolID = value;

  XdrInt64 _amount;
  XdrInt64 get amount => this._amount;
  set amount(XdrInt64 value) => this._amount = value;

  XdrInt64 _minAmountA;
  XdrInt64 get minAmountA => this._minAmountA;
  set minAmountA(XdrInt64 value) => this._minAmountA = value;

  XdrInt64 _minAmountB;
  XdrInt64 get minAmountB => this._minAmountB;
  set minAmountB(XdrInt64 value) => this._minAmountB = value;

  XdrLiquidityPoolWithdrawOp(
      this._liquidityPoolID, this._amount, this._minAmountA, this._minAmountB);

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolWithdrawOp encoded) {
    XdrHash.encode(stream, encoded.liquidityPoolID);
    XdrInt64.encode(stream, encoded.amount);
    XdrInt64.encode(stream, encoded.minAmountA);
    XdrInt64.encode(stream, encoded.minAmountB);
  }

  static XdrLiquidityPoolWithdrawOp decode(XdrDataInputStream stream) {
    return XdrLiquidityPoolWithdrawOp(
        XdrHash.decode(stream),
        XdrInt64.decode(stream),
        XdrInt64.decode(stream),
        XdrInt64.decode(stream));
  }
}

class XdrLiquidityPoolWithdrawResult {
  XdrLiquidityPoolWithdrawResultCode _code;

  XdrLiquidityPoolWithdrawResultCode get discriminant => this._code;

  set discriminant(XdrLiquidityPoolWithdrawResultCode value) =>
      this._code = value;

  XdrLiquidityPoolWithdrawResult(this._code);

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolWithdrawResult encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrLiquidityPoolWithdrawResult decode(XdrDataInputStream stream) {
    XdrLiquidityPoolWithdrawResult decoded = XdrLiquidityPoolWithdrawResult(
        XdrLiquidityPoolWithdrawResultCode.decode(stream));
    switch (decoded.discriminant) {
      case XdrLiquidityPoolWithdrawResultCode.LIQUIDITY_POOL_WITHDRAW_SUCCESS:
        break;
      default:
        break;
    }
    return decoded;
  }
}

class XdrLiquidityPoolWithdrawResultCode {
  final _value;

  const XdrLiquidityPoolWithdrawResultCode._internal(this._value);

  toString() => 'XdrLiquidityPoolWithdrawResultCode.$_value';

  XdrLiquidityPoolWithdrawResultCode(this._value);

  get value => this._value;

  /// Success.
  static const LIQUIDITY_POOL_WITHDRAW_SUCCESS =
      const XdrLiquidityPoolWithdrawResultCode._internal(0);

  /// bad input.
  static const LIQUIDITY_POOL_WITHDRAW_MALFORMED =
      const XdrLiquidityPoolWithdrawResultCode._internal(-1);

  /// no trust line for one of the assets
  static const LIQUIDITY_POOL_WITHDRAW_NO_TRUST =
      const XdrLiquidityPoolWithdrawResultCode._internal(-2);

  /// not enough balance of the pool share
  static const LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED =
      const XdrLiquidityPoolWithdrawResultCode._internal(-3);

  /// would go above limit for one of the assets
  static const LIQUIDITY_POOL_WITHDRAW_LINE_FULL =
      const XdrLiquidityPoolWithdrawResultCode._internal(-4);

  /// didn't withdraw enough
  static const LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM =
      const XdrLiquidityPoolWithdrawResultCode._internal(-5);

  static XdrLiquidityPoolWithdrawResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return LIQUIDITY_POOL_WITHDRAW_SUCCESS;
      case -1:
        return LIQUIDITY_POOL_WITHDRAW_MALFORMED;
      case -2:
        return LIQUIDITY_POOL_WITHDRAW_NO_TRUST;
      case -3:
        return LIQUIDITY_POOL_WITHDRAW_UNDERFUNDED;
      case -4:
        return LIQUIDITY_POOL_WITHDRAW_LINE_FULL;
      case -5:
        return LIQUIDITY_POOL_WITHDRAW_UNDER_MINIMUM;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrLiquidityPoolWithdrawResultCode value) {
    stream.writeInt(value.value);
  }
}
