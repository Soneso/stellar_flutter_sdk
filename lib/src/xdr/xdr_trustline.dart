// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

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

  static XdrTrustLineFlags decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 1:
        return AUTHORIZED_FLAG;
      case 2:
        return AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrAccountFlags value) {
    stream.writeInt(value.value);
  }
}

class XdrTrustLineEntry {
  XdrTrustLineEntry();
  XdrAccountID _accountID;
  XdrAccountID get accountID => this._accountID;
  set accountID(XdrAccountID value) => this._accountID = value;

  XdrAsset _asset;
  XdrAsset get asset => this._asset;
  set asset(XdrAsset value) => this._asset = value;

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
    XdrAsset.encode(stream, encodedTrustLineEntry.asset);
    XdrInt64.encode(stream, encodedTrustLineEntry.balance);
    XdrInt64.encode(stream, encodedTrustLineEntry.limit);
    XdrUint32.encode(stream, encodedTrustLineEntry.flags);
    XdrTrustLineEntryExt.encode(stream, encodedTrustLineEntry.ext);
  }

  static XdrTrustLineEntry decode(XdrDataInputStream stream) {
    XdrTrustLineEntry decodedTrustLineEntry = XdrTrustLineEntry();
    decodedTrustLineEntry.accountID = XdrAccountID.decode(stream);
    decodedTrustLineEntry.asset = XdrAsset.decode(stream);
    decodedTrustLineEntry.balance = XdrInt64.decode(stream);
    decodedTrustLineEntry.limit = XdrInt64.decode(stream);
    decodedTrustLineEntry.flags = XdrUint32.decode(stream);
    decodedTrustLineEntry.ext = XdrTrustLineEntryExt.decode(stream);
    return decodedTrustLineEntry;
  }
}

class XdrTrustLineEntryExt {
  XdrTrustLineEntryExt();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  XdrTrustLineEntryV1 _v1;
  XdrTrustLineEntryV1 get v1 => this._v1;
  set v1(XdrTrustLineEntryV1 value) => this._v1 = value;

  static void encode(XdrDataOutputStream stream,
      XdrTrustLineEntryExt encodedTrustLineEntryExt) {
    stream.writeInt(encodedTrustLineEntryExt.discriminant);
    switch (encodedTrustLineEntryExt.discriminant) {
      case 0:
        break;
      case 1:
        XdrTrustLineEntryV1.encode(stream, encodedTrustLineEntryExt.v1);
        break;
    }
  }

  static XdrTrustLineEntryExt decode(XdrDataInputStream stream) {
    XdrTrustLineEntryExt decodedTrustLineEntryExt = XdrTrustLineEntryExt();
    int discriminant = stream.readInt();
    decodedTrustLineEntryExt.discriminant = discriminant;
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
  XdrTrustLineEntryV1();
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
    XdrTrustLineEntryV1 decodedTrustLineEntryV1 = XdrTrustLineEntryV1();
    decodedTrustLineEntryV1.liabilities = XdrLiabilities.decode(stream);
    decodedTrustLineEntryV1.ext = XdrTrustLineEntryV1Ext.decode(stream);
    return decodedTrustLineEntryV1;
  }
}

class XdrTrustLineEntryV1Ext {
  XdrTrustLineEntryV1Ext();
  int _v;
  int get discriminant => this._v;
  set discriminant(int value) => this._v = value;

  static void encode(XdrDataOutputStream stream,
      XdrTrustLineEntryV1Ext encodedTrustLineEntryV1Ext) {
    stream.writeInt(encodedTrustLineEntryV1Ext.discriminant);
    switch (encodedTrustLineEntryV1Ext.discriminant) {
      case 0:
        break;
    }
  }

  static XdrTrustLineEntryV1Ext decode(XdrDataInputStream stream) {
    XdrTrustLineEntryV1Ext decodedTrustLineEntryV1Ext =
        XdrTrustLineEntryV1Ext();
    int discriminant = stream.readInt();
    decodedTrustLineEntryV1Ext.discriminant = discriminant;
    switch (decodedTrustLineEntryV1Ext.discriminant) {
      case 0:
        break;
    }
    return decodedTrustLineEntryV1Ext;
  }
}

class XdrAllowTrustOp {
  XdrAllowTrustOp();
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
    XdrAllowTrustOp decodedAllowTrustOp = XdrAllowTrustOp();
    decodedAllowTrustOp.trustor = XdrAccountID.decode(stream);
    decodedAllowTrustOp.asset = XdrAllowTrustOpAsset.decode(stream);
    decodedAllowTrustOp.authorize = stream.readInt();
    return decodedAllowTrustOp;
  }
}

class XdrAllowTrustOpAsset {
  XdrAllowTrustOpAsset();
  XdrAssetType _type;
  XdrAssetType get discriminant => this._type;
  set discriminant(XdrAssetType value) => this._type = value;

  Uint8List _assetCode4;
  Uint8List get assetCode4 => this._assetCode4;
  set assetCode4(Uint8List value) => this._assetCode4 = value;

  Uint8List _assetCode12;
  Uint8List get assetCode12 => this._assetCode12;
  set assetCode12(Uint8List value) => this._assetCode12 = value;

  static void encode(XdrDataOutputStream stream,
      XdrAllowTrustOpAsset encodedAllowTrustOpAsset) {
    stream.writeInt(encodedAllowTrustOpAsset.discriminant.value);
    switch (encodedAllowTrustOpAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        stream.write(encodedAllowTrustOpAsset.assetCode4);
        break;
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        stream.write(encodedAllowTrustOpAsset.assetCode12);
        break;
    }
  }

  static XdrAllowTrustOpAsset decode(XdrDataInputStream stream) {
    XdrAllowTrustOpAsset decodedAllowTrustOpAsset = XdrAllowTrustOpAsset();
    XdrAssetType discriminant = XdrAssetType.decode(stream);
    decodedAllowTrustOpAsset.discriminant = discriminant;
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
  XdrAllowTrustResult();
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
    XdrAllowTrustResult decodedAllowTrustResult = XdrAllowTrustResult();
    XdrAllowTrustResultCode discriminant =
        XdrAllowTrustResultCode.decode(stream);
    decodedAllowTrustResult.discriminant = discriminant;
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
  XdrChangeTrustOp();
  XdrAsset _line;
  XdrAsset get line => this._line;
  set line(XdrAsset value) => this._line = value;

  XdrInt64 _limit;
  XdrInt64 get limit => this._limit;
  set limit(XdrInt64 value) => this._limit = value;

  static void encode(
      XdrDataOutputStream stream, XdrChangeTrustOp encodedChangeTrustOp) {
    XdrAsset.encode(stream, encodedChangeTrustOp.line);
    XdrInt64.encode(stream, encodedChangeTrustOp.limit);
  }

  static XdrChangeTrustOp decode(XdrDataInputStream stream) {
    XdrChangeTrustOp decodedChangeTrustOp = XdrChangeTrustOp();
    decodedChangeTrustOp.line = XdrAsset.decode(stream);
    decodedChangeTrustOp.limit = XdrInt64.decode(stream);
    return decodedChangeTrustOp;
  }
}

class XdrChangeTrustResult {
  XdrChangeTrustResult();
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
    XdrChangeTrustResult decodedChangeTrustResult = XdrChangeTrustResult();
    XdrChangeTrustResultCode discriminant =
        XdrChangeTrustResultCode.decode(stream);
    decodedChangeTrustResult.discriminant = discriminant;
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
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(
      XdrDataOutputStream stream, XdrChangeTrustResultCode value) {
    stream.writeInt(value.value);
  }
}
