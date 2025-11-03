// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr_asset.dart';
import 'key_pair.dart';
import 'util.dart';
import 'asset_type_native.dart';
import 'asset_type_credit_alphanum.dart';
import 'asset_type_credit_alphanum4.dart';
import 'asset_type_credit_alphanum12.dart';
import 'asset_type_pool_share.dart';
import 'constants/stellar_protocol_constants.dart';

/// Base Assets class.
/// See: [Assets](https://www.stellar.org/developers/learn/concepts/assets.html).
abstract class Asset {
  Asset();

  static final Asset NATIVE = AssetTypeNative();
  static const String TYPE_NATIVE = "native";
  static const String TYPE_CREDIT_ALPHANUM4 = "credit_alphanum4";
  static const String TYPE_CREDIT_ALPHANUM12 = "credit_alphanum12";
  static const String TYPE_POOL_SHARE = "liquidity_pool_shares";

  static Asset create(String type, String? code, String? issuer) {
    if (type == TYPE_NATIVE) {
      return Asset.NATIVE;
    } else {
      return Asset.createNonNativeAsset(code!, issuer!);
    }
  }

  /// Creates one of AssetTypeCreditAlphaNum4 or AssetTypeCreditAlphaNum12 object based on a [code], its length and the [issuer] of the asset.
  static Asset createNonNativeAsset(String code, String issuer) {
    if (code.length >= StellarProtocolConstants.ASSET_CODE_MIN_LENGTH &&
        code.length <= StellarProtocolConstants.ASSET_CODE_ALPHANUMERIC_4_MAX_LENGTH) {
      return new AssetTypeCreditAlphaNum4(code, issuer);
    } else if (code.length >= StellarProtocolConstants.ASSET_CODE_ALPHANUMERIC_12_MIN_LENGTH &&
               code.length <= StellarProtocolConstants.ASSET_CODE_ALPHANUMERIC_12_MAX_LENGTH) {
      return new AssetTypeCreditAlphaNum12(code, issuer);
    } else {
      throw new AssetCodeLengthInvalidException();
    }
  }

  static Asset? createFromCanonicalForm(String? canonicalForm) {
    if (canonicalForm == null) {
      return null;
    }
    if (canonicalForm == 'XLM' || canonicalForm == "native") {
      return Asset.NATIVE;
    } else {
      List<String> components = canonicalForm.split(':');
      if (components.length != 2) {
        return null;
      } else {
        String code = components[0].trim();
        String issuerId = components[1].trim();
        if (code.length <= StellarProtocolConstants.ASSET_CODE_ALPHANUMERIC_4_MAX_LENGTH) {
          return AssetTypeCreditAlphaNum4(code, issuerId);
        } else if (code.length <= StellarProtocolConstants.ASSET_CODE_ALPHANUMERIC_12_MAX_LENGTH) {
          return AssetTypeCreditAlphaNum12(code, issuerId);
        }
      }
    }
    return null;
  }

  static String canonicalForm(Asset asset) {
    if (asset is AssetTypeNative) {
      return 'native';
    } else if (asset is AssetTypeCreditAlphaNum) {
      AssetTypeCreditAlphaNum creditAsset = asset;
      return creditAsset.code + ":" + creditAsset.issuerId;
    } else {
      throw Exception("unsupported asset " + asset.type);
    }
  }

  /// Generates an Asset object from a given XDR object [xdrAsset].
  static Asset fromXdr(XdrAsset xdrAsset) {
    switch (xdrAsset.discriminant) {
      case XdrAssetType.ASSET_TYPE_NATIVE:
        return new AssetTypeNative();
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4:
        String assetCode4 =
            Util.paddedByteArrayToString(xdrAsset.alphaNum4!.assetCode);
        KeyPair issuer4 =
            KeyPair.fromXdrPublicKey(xdrAsset.alphaNum4!.issuer.accountID);
        return AssetTypeCreditAlphaNum4(assetCode4, issuer4.accountId);
      case XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12:
        String assetCode12 =
            Util.paddedByteArrayToString(xdrAsset.alphaNum12!.assetCode);
        KeyPair issuer12 =
            KeyPair.fromXdrPublicKey(xdrAsset.alphaNum12!.issuer.accountID);
        return AssetTypeCreditAlphaNum12(assetCode12, issuer12.accountId);
      case XdrAssetType.ASSET_TYPE_POOL_SHARE:
        if (xdrAsset is XdrChangeTrustAsset) {
          XdrAsset a = xdrAsset.liquidityPool!.constantProduct!.assetA;
          XdrAsset b = xdrAsset.liquidityPool!.constantProduct!.assetB;
          return AssetTypePoolShare(
              assetA: Asset.fromXdr(a), assetB: Asset.fromXdr(b));
        } else {
          throw Exception("Unknown pool share asset type");
        }
      default:
        throw Exception(
            "Unknown asset type ${xdrAsset.discriminant.toString()}");
    }
  }

  /// Returns asset type. Possible types:
  /// <ul>
  /// <li><code>native</code></li>
  /// <li><code>credit_alphanum4</code></li>
  /// <li><code>credit_alphanum12</code></li>
  /// </ul>
  String get type;

  int get hashCode;

  bool operator ==(Object object);

  /// Generates XDR object of this Asset object.
  XdrAsset toXdr();

  XdrChangeTrustAsset toXdrChangeTrustAsset();

  XdrTrustlineAsset toXdrTrustLineAsset();

  factory Asset.fromJson(Map<String, dynamic> json) {
    if (json['asset_type'] == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(
          json['asset_code'], json['asset_issuer']);
    }
  }
}

/// Exception thrown when an asset code length is invalid.
///
/// Asset codes must meet specific length requirements:
/// - AlphaNum4: 1-4 characters
/// - AlphaNum12: 5-12 characters
///
/// This exception is thrown when attempting to create an asset with a code
/// that doesn't meet these requirements.
///
/// Example:
/// ```dart
/// try {
///   // This will throw - code too long for AlphaNum4
///   Asset asset = AssetTypeCreditAlphaNum4("TOOLONG", issuerId);
/// } catch (e) {
///   if (e is AssetCodeLengthInvalidException) {
///     print("Invalid asset code length: ${e.message}");
///   }
/// }
/// ```
class AssetCodeLengthInvalidException implements Exception {
  final message;

  AssetCodeLengthInvalidException([this.message]);

  String toString() {
    if (message == null) return "AssetCodeLengthInvalidException";
    return "AssetCodeLengthInvalidException: $message";
  }
}
