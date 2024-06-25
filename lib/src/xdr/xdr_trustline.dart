// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_other.dart';
import 'xdr_asset.dart';
import 'xdr_account.dart';
import "dart:typed_data";

class XdrTrustLineFlags {
  final _value;

  const XdrTrustLineFlags._internal(this._value);

  toString() => 'TrustLineFlags.$_value';

  XdrTrustLineFlags(this._value);

  get value => this._value;

  /// The issuer has authorized account to perform transactions with its credit.
  static const AUTHORIZED_FLAG = const XdrTrustLineFlags._internal(1);

  /// The issuer has authorized account to maintain and reduce liabilities for its credit.
  static const AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG =
      const XdrTrustLineFlags._internal(2);

  static const TRUSTLINE_CLAWBACK_ENABLED_FLAG =
      const XdrTrustLineFlags._internal(4);

  static XdrTrustLineFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return AUTHORIZED_FLAG;
      case 2:
        return AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG;
      case 4:
        return TRUSTLINE_CLAWBACK_ENABLED_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAccountFlags value) {
    stream.writeInt(value.value);
  }
}

class XdrTrustLineEntry {
  XdrTrustLineEntry(this._accountID, this._asset, this._balance, this._limit,
      this._flags, this._ext);

  XdrAccountID _accountID;

  XdrAccountID get accountID => this._accountID;

  set accountID(XdrAccountID value) => this._accountID = value;

  XdrTrustlineAsset _asset;

  XdrTrustlineAsset get asset => this._asset;

  set asset(XdrTrustlineAsset value) => this._asset = value;

  XdrInt64 _balance;

  XdrInt64 get balance => this._balance;

  set balance(XdrInt64 value) => this._balance = value;

  XdrInt64 _limit;

  XdrInt64 get limit => this._limit;

  set limit(XdrInt64 value) => this._limit = value;

  XdrUint32 _flags;

  XdrUint32 get flags => this._flags;

  set flags(XdrUint32 value) => this._flags = value;

  XdrTrustLineEntryExt _ext;

  XdrTrustLineEntryExt get ext => this._ext;

  set ext(XdrTrustLineEntryExt value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrTrustLineEntry encodedTrustLineEntry) {
    XdrAccountID.encode(stream, encodedTrustLineEntry.accountID);
    XdrTrustlineAsset.encode(stream, encodedTrustLineEntry.asset);
    XdrInt64.encode(stream, encodedTrustLineEntry.balance);
    XdrInt64.encode(stream, encodedTrustLineEntry.limit);
    XdrUint32.encode(stream, encodedTrustLineEntry.flags);
    XdrTrustLineEntryExt.encode(stream, encodedTrustLineEntry.ext);
  }

  static XdrTrustLineEntry decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    XdrTrustlineAsset asset = XdrTrustlineAsset.decode(stream);
    XdrInt64 balance = XdrInt64.decode(stream);
    XdrInt64 limit = XdrInt64.decode(stream);
    XdrUint32 flags = XdrUint32.decode(stream);
    XdrTrustLineEntryExt ext = XdrTrustLineEntryExt.decode(stream);
    return XdrTrustLineEntry(accountID, asset, balance, limit, flags, ext);
  }
}

class XdrTrustLineEntryExt {
  XdrTrustLineEntryExt(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  XdrTrustLineEntryV1? _v1;

  XdrTrustLineEntryV1? get v1 => this._v1;

  set v1(XdrTrustLineEntryV1? value) => this._v1 = value;

  static void encode(XdrDataOutputStream stream,
      XdrTrustLineEntryExt encodedTrustLineEntryExt) {
    stream.writeInt(encodedTrustLineEntryExt.discriminant);
    switch (encodedTrustLineEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrTrustLineEntryV1.encode(stream, encodedTrustLineEntryExt.v1!);
        break;
    }
  }

  static XdrTrustLineEntryExt decode(XdrDataInputStream stream) {
    XdrTrustLineEntryExt decodedTrustLineEntryExt =
        XdrTrustLineEntryExt(stream.readInt());
    switch (decodedTrustLineEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        decodedTrustLineEntryExt.v1 = XdrTrustLineEntryV1.decode(stream);
        break;
    }
    return decodedTrustLineEntryExt;
  }
}

class XdrTrustLineEntryV1 {
  XdrTrustLineEntryV1(this._liabilities, this._ext);

  XdrLiabilities _liabilities;

  XdrLiabilities get liabilities => this._liabilities;

  set liabilities(XdrLiabilities value) => this._liabilities = value;

  XdrTrustLineEntryV1Ext _ext;

  XdrTrustLineEntryV1Ext get ext => this._ext;

  set ext(XdrTrustLineEntryV1Ext value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, XdrTrustLineEntryV1 encodedTrustLineEntryV1) {
    XdrLiabilities.encode(stream, encodedTrustLineEntryV1.liabilities);
    XdrTrustLineEntryV1Ext.encode(stream, encodedTrustLineEntryV1.ext);
  }

  static XdrTrustLineEntryV1 decode(XdrDataInputStream stream) {
    XdrLiabilities liabilities = XdrLiabilities.decode(stream);
    XdrTrustLineEntryV1Ext ext = XdrTrustLineEntryV1Ext.decode(stream);
    return XdrTrustLineEntryV1(liabilities, ext);
  }
}

class XdrTrustLineEntryV1Ext {
  XdrTrustLineEntryV1Ext(this._v);

  int _v;

  int get discriminant => this._v;

  set discriminant(int value) => this._v = value;

  TrustLineEntryExtensionV2? _ext;

  TrustLineEntryExtensionV2? get ext => this._ext;

  set ext(TrustLineEntryExtensionV2? value) => this._ext = value;

  static void encode(XdrDataOutputStream stream, XdrTrustLineEntryV1Ext value) {
    stream.writeInt(value.discriminant);
    switch (value.discriminant) {
      case 0:
        break;
      case 2:
        TrustLineEntryExtensionV2.encode(stream, value.ext!);
        break;
    }
  }

  static XdrTrustLineEntryV1Ext decode(XdrDataInputStream stream) {
    XdrTrustLineEntryV1Ext decodedTrustLineEntryV1Ext =
        XdrTrustLineEntryV1Ext(stream.readInt());
    switch (decodedTrustLineEntryV1Ext.discriminant) {
      case 0:
        break;
      case 2:
        decodedTrustLineEntryV1Ext.ext =
            TrustLineEntryExtensionV2.decode(stream);
        break;
    }
    return decodedTrustLineEntryV1Ext;
  }
}

class TrustLineEntryExtensionV2 {
  TrustLineEntryExtensionV2(this._liquidityPoolUseCount, this._ext);

  XdrInt32 _liquidityPoolUseCount;
  XdrInt32 get liquidityPoolUseCount => this._liquidityPoolUseCount;
  set liquidityPoolUseCount(XdrInt32 value) =>
      this._liquidityPoolUseCount = value;

  TrustLineEntryExtensionV2Ext _ext;
  TrustLineEntryExtensionV2Ext get ext => this._ext;
  set ext(TrustLineEntryExtensionV2Ext value) => this._ext = value;

  static void encode(
      XdrDataOutputStream stream, TrustLineEntryExtensionV2 value) {
    XdrInt32.encode(stream, value.liquidityPoolUseCount);
    TrustLineEntryExtensionV2Ext.encode(stream, value.ext);
  }

  static TrustLineEntryExtensionV2 decode(XdrDataInputStream stream) {
    XdrInt32 liquidityPoolUseCount = XdrInt32.decode(stream);
    TrustLineEntryExtensionV2Ext ext =
        TrustLineEntryExtensionV2Ext.decode(stream);
    return TrustLineEntryExtensionV2(liquidityPoolUseCount, ext);
  }
}

class TrustLineEntryExtensionV2Ext {
  TrustLineEntryExtensionV2Ext(this._v);

  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(
      XdrDataOutputStream stream, TrustLineEntryExtensionV2Ext value) {
    stream.writeInt(value.discriminant);
    switch (value.discriminant) {
      case 0:
        break;
    }
  }

  static TrustLineEntryExtensionV2Ext decode(XdrDataInputStream stream) {
    TrustLineEntryExtensionV2Ext value =
        TrustLineEntryExtensionV2Ext(stream.readInt());
    switch (value.discriminant) {
      case 0:
        break;
    }
    return value;
  }
}

class XdrAllowTrustOp {
  XdrAllowTrustOp(this._trustor, this._asset, this._authorize);

  XdrAccountID _trustor;
  XdrAccountID get trustor => this._trustor;
  set trustor(XdrAccountID value) => this._trustor = value;

  XdrAllowTrustOpAsset _asset;
  XdrAllowTrustOpAsset get asset => this._asset;
  set asset(XdrAllowTrustOpAsset value) => this._asset = value;

  int _authorize;
  int get authorize => this._authorize;
  set authorize(int value) => this._authorize = value;

  static void encode(
      XdrDataOutputStream stream, XdrAllowTrustOp encodedAllowTrustOp) {
    XdrAccountID.encode(stream, encodedAllowTrustOp.trustor);
    XdrAllowTrustOpAsset.encode(stream, encodedAllowTrustOp.asset);
    stream.writeInt(encodedAllowTrustOp.authorize);
  }

  static XdrAllowTrustOp decode(XdrDataInputStream stream) {
    XdrAccountID trustor = XdrAccountID.decode(stream);
    XdrAllowTrustOpAsset asset = XdrAllowTrustOpAsset.decode(stream);
    return XdrAllowTrustOp(trustor, asset, stream.readInt());
  }
}

class XdrAllowTrustOpAsset {
  XdrAllowTrustOpAsset(this._type);

  XdrAssetType _type;
  XdrAssetType get discriminant => this._type;
  set discriminant(XdrAssetType value) => this._type = value;

  Uint8List? _assetCode4;
  Uint8List? get assetCode4 => this._assetCode4;
  set assetCode4(Uint8List? value) => this._assetCode4 = value;

  Uint8List? _assetCode12;
  Uint8List? get assetCode12 => this._assetCode12;
  set assetCode12(Uint8List? value) => this._assetCode12 = value;

  static void encode(XdrDataOutputStream stream,
      XdrAllowTrustOpAsset encodedAllowTrustOpAsset) {
    stream.writeInt(encodedAllowTrustOpAsset.discriminant.value);
    switch (encodedAllowTrustOpAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        stream.write(encodedAllowTrustOpAsset.assetCode4!);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        stream.write(encodedAllowTrustOpAsset.assetCode12!);
        break;
    }
  }

  static XdrAllowTrustOpAsset decode(XdrDataInputStream stream) {
    XdrAllowTrustOpAsset decodedAllowTrustOpAsset =
        XdrAllowTrustOpAsset(XdrAssetType.decode(stream));
    switch (decodedAllowTrustOpAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        int assetCode4size = 4;
        decodedAllowTrustOpAsset.assetCode4 = stream.readBytes(assetCode4size);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        int assetCode12size = 12;
        decodedAllowTrustOpAsset.assetCode12 =
            stream.readBytes(assetCode12size);
        break;
    }
    return decodedAllowTrustOpAsset;
  }
}

class XdrAllowTrustResult {
  XdrAllowTrustResult(this._code);

  XdrAllowTrustResultCode _code;
  XdrAllowTrustResultCode get discriminant => this._code;
  set discriminant(XdrAllowTrustResultCode value) => this._code = value;

  static void encode(
      XdrDataOutputStream stream, XdrAllowTrustResult encodedAllowTrustResult) {
    stream.writeInt(encodedAllowTrustResult.discriminant.value);
    switch (encodedAllowTrustResult.discriminant) {
      case XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrAllowTrustResult decode(XdrDataInputStream stream) {
    XdrAllowTrustResult decodedAllowTrustResult =
        XdrAllowTrustResult(XdrAllowTrustResultCode.decode(stream));
    switch (decodedAllowTrustResult.discriminant) {
      case XdrAllowTrustResultCode.ALLOW_TRUST_SUCCESS:
        break;
      default:
        break;
    }
    return decodedAllowTrustResult;
  }
}

class XdrAllowTrustResultCode {
  final _value;

  const XdrAllowTrustResultCode._internal(this._value);

  toString() => 'AllowTrustResultCode.$_value';

  XdrAllowTrustResultCode(this._value);

  get value => this._value;

  /// Success code.
  static const ALLOW_TRUST_SUCCESS = const XdrAllowTrustResultCode._internal(0);

  // Codes considered as "failure" for the operation.

  /// Asset is not ASSET_TYPE_ALPHANUM.
  static const ALLOW_TRUST_MALFORMED =
      const XdrAllowTrustResultCode._internal(-1);

  /// Trustor does not have a trustline.
  static const ALLOW_TRUST_NO_TRUST_LINE =
      const XdrAllowTrustResultCode._internal(-2);

  /// Source account does not require trust.
  static const ALLOW_TRUST_TRUST_NOT_REQUIRED =
      const XdrAllowTrustResultCode._internal(-3);

  /// Source account can't revoke trust.
  static const ALLOW_TRUST_CANT_REVOKE =
      const XdrAllowTrustResultCode._internal(-4);

  /// Trusting self is not allowed.
  static const ALLOW_TRUST_SELF_NOT_ALLOWED =
      const XdrAllowTrustResultCode._internal(-5);

  /// Claimable balances can't be created on revoke due to low reserves.
  static const ALLOW_TRUST_LOW_RESERVE =
      const XdrAllowTrustResultCode._internal(-6);

  static XdrAllowTrustResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return ALLOW_TRUST_SUCCESS;
      case -1:
        return ALLOW_TRUST_MALFORMED;
      case -2:
        return ALLOW_TRUST_NO_TRUST_LINE;
      case -3:
        return ALLOW_TRUST_TRUST_NOT_REQUIRED;
      case -4:
        return ALLOW_TRUST_CANT_REVOKE;
      case -5:
        return ALLOW_TRUST_SELF_NOT_ALLOWED;
      case -6:
        return ALLOW_TRUST_LOW_RESERVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrAllowTrustResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrChangeTrustOp {
  XdrChangeTrustOp(this._line, this._limit);

  XdrChangeTrustAsset _line;
  XdrChangeTrustAsset get line => this._line;
  set line(XdrChangeTrustAsset value) => this._line = value;

  XdrBigInt64 _limit;
  XdrBigInt64 get limit => this._limit;
  set limit(XdrBigInt64 value) => this._limit = value;

  static void encode(
      XdrDataOutputStream stream, XdrChangeTrustOp encodedChangeTrustOp) {
    XdrAsset.encode(stream, encodedChangeTrustOp.line);
    XdrBigInt64.encode(stream, encodedChangeTrustOp.limit);
  }

  static XdrChangeTrustOp decode(XdrDataInputStream stream) {
    XdrChangeTrustAsset line = XdrChangeTrustAsset.decode(stream);
    XdrBigInt64 limit = XdrBigInt64.decode(stream);
    return XdrChangeTrustOp(line, limit);
  }
}

class XdrChangeTrustResult {
  XdrChangeTrustResult(this._code);

  XdrChangeTrustResultCode _code;
  XdrChangeTrustResultCode get discriminant => this._code;
  set discriminant(XdrChangeTrustResultCode value) => this._code = value;

  static void encode(XdrDataOutputStream stream,
      XdrChangeTrustResult encodedChangeTrustResult) {
    stream.writeInt(encodedChangeTrustResult.discriminant.value);
    switch (encodedChangeTrustResult.discriminant) {
      case XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrChangeTrustResult decode(XdrDataInputStream stream) {
    XdrChangeTrustResult decodedChangeTrustResult =
        XdrChangeTrustResult(XdrChangeTrustResultCode.decode(stream));
    switch (decodedChangeTrustResult.discriminant) {
      case XdrChangeTrustResultCode.CHANGE_TRUST_SUCCESS:
        break;
      default:
        break;
    }
    return decodedChangeTrustResult;
  }
}

class XdrChangeTrustResultCode {
  final _value;

  const XdrChangeTrustResultCode._internal(this._value);

  toString() => 'ChangeTrustResultCode.$_value';

  XdrChangeTrustResultCode(this._value);

  get value => this._value;

  /// Success.
  static const CHANGE_TRUST_SUCCESS =
      const XdrChangeTrustResultCode._internal(0);

  /// Bad input.
  static const CHANGE_TRUST_MALFORMED =
      const XdrChangeTrustResultCode._internal(-1);

  /// Could not find issuer.
  static const CHANGE_TRUST_NO_ISSUER =
      const XdrChangeTrustResultCode._internal(-2);

  /// Cannot drop limit below balance. Cannot create with a limit of 0.
  static const CHANGE_TRUST_INVALID_LIMIT =
      const XdrChangeTrustResultCode._internal(-3);

  /// Not enough funds to create a new trust line
  static const CHANGE_TRUST_LOW_RESERVE =
      const XdrChangeTrustResultCode._internal(-4);

  /// Trusting self is not allowed.
  static const CHANGE_TRUST_SELF_NOT_ALLOWED =
      const XdrChangeTrustResultCode._internal(-5);

  /// Asset trustline is missing for pool.
  static const CHANGE_TRUST_TRUST_LINE_MISSING =
      const XdrChangeTrustResultCode._internal(-6);

  /// Asset trustline is still referenced in a pool.
  static const CHANGE_TRUST_CANNOT_DELETE =
      const XdrChangeTrustResultCode._internal(-7);

  /// Asset trustline is deauthorized.
  static const CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES =
      const XdrChangeTrustResultCode._internal(-8);

  static XdrChangeTrustResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CHANGE_TRUST_SUCCESS;
      case -1:
        return CHANGE_TRUST_MALFORMED;
      case -2:
        return CHANGE_TRUST_NO_ISSUER;
      case -3:
        return CHANGE_TRUST_INVALID_LIMIT;
      case -4:
        return CHANGE_TRUST_LOW_RESERVE;
      case -5:
        return CHANGE_TRUST_SELF_NOT_ALLOWED;
      case -6:
        return CHANGE_TRUST_TRUST_LINE_MISSING;
      case -7:
        return CHANGE_TRUST_CANNOT_DELETE;
      case -8:
        return CHANGE_TRUST_NOT_AUTH_MAINTAIN_LIABILITIES;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrChangeTrustResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrClawbackOp {
  XdrClawbackOp(this._asset, this._from, this._amount);

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrMuxedAccount _from;
  XdrMuxedAccount get from => this._from;
  set from(XdrMuxedAccount value) => this._from = value;

  XdrBigInt64 _amount;
  XdrBigInt64 get amount => this._amount;
  set amount(XdrBigInt64 value) => this._amount = value;

  static void encode(
      XdrDataOutputStream stream, XdrClawbackOp encodedClawbackOp) {
    XdrAsset.encode(stream, encodedClawbackOp.asset);
    XdrMuxedAccount.encode(stream, encodedClawbackOp.from);
    XdrBigInt64.encode(stream, encodedClawbackOp.amount);
  }

  static XdrClawbackOp decode(XdrDataInputStream stream) {
    XdrAsset asset = XdrAsset.decode(stream);
    XdrMuxedAccount from = XdrMuxedAccount.decode(stream);
    XdrBigInt64 amount = XdrBigInt64.decode(stream);
    return XdrClawbackOp(asset, from, amount);
  }
}

class XdrClawbackResultCode {
  final _value;

  const XdrClawbackResultCode._internal(this._value);

  toString() => 'ClawbackResultCode.$_value';

  XdrClawbackResultCode(this._value);

  get value => this._value;

  /// Clawback successfully completed.
  static const CLAWBACK_SUCCESS = const XdrClawbackResultCode._internal(0);

  /// Bad input.
  static const CLAWBACK_MALFORMED = const XdrClawbackResultCode._internal(-1);

  static const CLAWBACK_NOT_ENABLED = const XdrClawbackResultCode._internal(-2);

  static const CLAWBACK_NO_TRUST = const XdrClawbackResultCode._internal(-3);

  /// Not enough funds in source account.
  static const CLAWBACK_UNDERFUNDED = const XdrClawbackResultCode._internal(-4);

  static XdrClawbackResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return CLAWBACK_SUCCESS;
      case -1:
        return CLAWBACK_MALFORMED;
      case -2:
        return CLAWBACK_NOT_ENABLED;
      case -3:
        return CLAWBACK_NO_TRUST;
      case -4:
        return CLAWBACK_UNDERFUNDED;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrClawbackResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrClawbackResult {
  XdrClawbackResult(this._code);

  XdrClawbackResultCode _code;
  XdrClawbackResultCode get discriminant => this._code;
  set discriminant(XdrClawbackResultCode value) => this._code = value;

  static void encode(
      XdrDataOutputStream stream, XdrClawbackResult encodedClawbackResult) {
    stream.writeInt(encodedClawbackResult.discriminant.value);
    switch (encodedClawbackResult.discriminant) {
      case XdrClawbackResultCode.CLAWBACK_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrClawbackResult decode(XdrDataInputStream stream) {
    XdrClawbackResult decodedClawbackResult =
        XdrClawbackResult(XdrClawbackResultCode.decode(stream));
    switch (decodedClawbackResult.discriminant) {
      case XdrClawbackResultCode.CLAWBACK_SUCCESS:
        break;
      default:
        break;
    }
    return decodedClawbackResult;
  }
}

class XdrSetTrustLineFlagsOp {
  XdrSetTrustLineFlagsOp(
      this._accountID, this._asset, this._clearFlags, this._setFlags);

  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

  XdrUint32 _clearFlags;
  XdrUint32 get clearFlags => this._clearFlags;
  set clearFlags(XdrUint32 value) => this._clearFlags = value;

  XdrUint32 _setFlags;
  XdrUint32 get setFlags => this._setFlags;
  set setFlags(XdrUint32 value) => this._setFlags = value;

  static void encode(XdrDataOutputStream stream,
      XdrSetTrustLineFlagsOp encodedSetTrustLineFlagssOp) {
    XdrAccountID.encode(stream, encodedSetTrustLineFlagssOp.accountID);
    XdrAsset.encode(stream, encodedSetTrustLineFlagssOp.asset);
    XdrUint32.encode(stream, encodedSetTrustLineFlagssOp.clearFlags);
    XdrUint32.encode(stream, encodedSetTrustLineFlagssOp.setFlags);
  }

  static XdrSetTrustLineFlagsOp decode(XdrDataInputStream stream) {
    XdrAccountID accountID = XdrAccountID.decode(stream);
    XdrAsset asset = XdrAsset.decode(stream);
    XdrUint32 clearFlags = XdrUint32.decode(stream);
    XdrUint32 setFlags = XdrUint32.decode(stream);

    return XdrSetTrustLineFlagsOp(accountID, asset, clearFlags, setFlags);
  }
}

class XdrSetTrustLineFlagsResultCode {
  final _value;

  const XdrSetTrustLineFlagsResultCode._internal(this._value);

  toString() => 'XdrSetTrustLineFlagsResultCode.$_value';

  XdrSetTrustLineFlagsResultCode(this._value);

  get value => this._value;

  /// Success.
  static const SET_TRUST_LINE_FLAGS_SUCCESS =
      const XdrSetTrustLineFlagsResultCode._internal(0);

  static const SET_TRUST_LINE_FLAGS_MALFORMED =
      const XdrSetTrustLineFlagsResultCode._internal(-1);

  static const SET_TRUST_LINE_FLAGS_NO_TRUST_LINE =
      const XdrSetTrustLineFlagsResultCode._internal(-2);

  static const SET_TRUST_LINE_FLAGS_CANT_REVOKE =
      const XdrSetTrustLineFlagsResultCode._internal(-3);

  static const SET_TRUST_LINE_FLAGS_INVALID_STATE =
      const XdrSetTrustLineFlagsResultCode._internal(-4);

  static const SET_TRUST_LINE_FLAGS_LOW_RESERVE =
      const XdrSetTrustLineFlagsResultCode._internal(-5);

  static XdrSetTrustLineFlagsResultCode decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SET_TRUST_LINE_FLAGS_SUCCESS;
      case -1:
        return SET_TRUST_LINE_FLAGS_MALFORMED;
      case -2:
        return SET_TRUST_LINE_FLAGS_NO_TRUST_LINE;
      case -3:
        return SET_TRUST_LINE_FLAGS_CANT_REVOKE;
      case -4:
        return SET_TRUST_LINE_FLAGS_INVALID_STATE;
      case -5:
        return SET_TRUST_LINE_FLAGS_LOW_RESERVE;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrSetTrustLineFlagsResultCode value) {
    stream.writeInt(value.value);
  }
}

class XdrSetTrustLineFlagsResult {
  XdrSetTrustLineFlagsResult(this._code);

  XdrSetTrustLineFlagsResultCode _code;
  XdrSetTrustLineFlagsResultCode get discriminant => this._code;
  set discriminant(XdrSetTrustLineFlagsResultCode value) => this._code = value;

  static void encode(XdrDataOutputStream stream,
      XdrSetTrustLineFlagsResult encodedSetTrustLineFlagsResult) {
    stream.writeInt(encodedSetTrustLineFlagsResult.discriminant.value);
    switch (encodedSetTrustLineFlagsResult.discriminant) {
      case XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS:
        break;
      default:
        break;
    }
  }

  static XdrSetTrustLineFlagsResult decode(XdrDataInputStream stream) {
    XdrSetTrustLineFlagsResult decodedSetTrustLineFlagsResult =
        XdrSetTrustLineFlagsResult(
            XdrSetTrustLineFlagsResultCode.decode(stream));
    switch (decodedSetTrustLineFlagsResult.discriminant) {
      case XdrSetTrustLineFlagsResultCode.SET_TRUST_LINE_FLAGS_SUCCESS:
        break;
      default:
        break;
    }
    return decodedSetTrustLineFlagsResult;
  }
}
