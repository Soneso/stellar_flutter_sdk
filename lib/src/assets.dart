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

/// Base class representing assets on the Stellar network.
///
/// Assets are the units of value traded on Stellar. An asset consists of a type,
/// code (for credit assets), and issuer (for credit assets). Assets are used in
/// payments, offers, trustlines, and other operations.
///
/// Asset Types:
/// - **Native (XLM)**: The built-in cryptocurrency, requires no trustline
/// - **Credit AlphaNum4**: Assets with 1-4 character codes (e.g., "USD", "BTC")
/// - **Credit AlphaNum12**: Assets with 5-12 character codes (e.g., "USDC", "EURT")
/// - **Pool Share**: Liquidity pool share assets (Protocol 18+)
///
/// Creating assets:
/// ```dart
/// // Native asset (XLM/lumens)
/// Asset xlm = Asset.NATIVE;
/// // or
/// Asset xlm = AssetTypeNative();
///
/// // Credit asset with 4-character code
/// Asset usd = AssetTypeCreditAlphaNum4(
///   "USD",
///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
/// );
///
/// // Credit asset with 12-character code
/// Asset longCode = AssetTypeCreditAlphaNum12(
///   "LONGASSET",
///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
/// );
///
/// // Create from canonical form (code:issuer)
/// Asset? asset = Asset.createFromCanonicalForm(
///   "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
/// );
///
/// // Auto-detect type from code length
/// Asset auto = Asset.createNonNativeAsset(
///   "USDC",
///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
/// );
/// ```
///
/// Asset codes:
/// - AlphaNum4: 1-4 characters (ASCII characters 32-127, excluding spaces)
/// - AlphaNum12: 5-12 characters (same character restrictions)
/// - Case-sensitive ("USD" and "usd" are different assets)
/// - No leading/trailing spaces allowed
///
/// Trustlines:
/// - Native asset (XLM) requires no trustline
/// - Credit assets require recipients to establish trustlines before receiving
/// - Trustlines can have limits and authorization flags
/// - Pool shares require trustlines before depositing liquidity
///
/// Common operations:
/// ```dart
/// // Payment with asset
/// PaymentOperation payment = PaymentOperationBuilder(
///   destination,
///   usd,
///   "100.50"
/// ).build();
///
/// // Create trustline for asset
/// ChangeTrustOperation trust = ChangeTrustOperationBuilder(
///   usd,
///   "1000000"
/// ).build();
///
/// // Compare assets
/// if (asset1 == asset2) {
///   print("Same asset");
/// }
///
/// // Get canonical form
/// String canonical = Asset.canonicalForm(usd);
/// // Returns: "USD:GDUKMG..."
/// ```
///
/// Important notes:
/// - Always verify asset issuer addresses before trusting
/// - Native asset (XLM) cannot have an issuer
/// - Asset codes are case-sensitive
/// - Maximum supply is 9,223,372,036,854.7758079 (signed 64-bit with 7 decimal places)
/// - Assets can be authorized required, revocable, or immutable (see [AccountFlag])
///
/// See also:
/// - [AssetTypeNative] for XLM/lumens
/// - [AssetTypeCreditAlphaNum4] for 1-4 character codes
/// - [AssetTypeCreditAlphaNum12] for 5-12 character codes
/// - [AssetTypePoolShare] for liquidity pool shares
/// - [ChangeTrustOperation] for creating trustlines
/// - [PaymentOperation] for asset payments
/// - [Stellar developer docs](https://developers.stellar.org)
abstract class Asset {
  /// Creates an Asset instance.
  ///
  /// This is an abstract base class constructor. Use factory methods or
  /// subclass constructors to create concrete asset instances.
  Asset();

  /// Singleton instance representing the native Stellar asset (XLM/lumens).
  ///
  /// This is the most commonly used way to reference the native asset.
  ///
  /// Example:
  /// ```dart
  /// Asset xlm = Asset.NATIVE;
  /// ```
  static final Asset NATIVE = AssetTypeNative();

  /// Type identifier for native assets (XLM).
  static const String TYPE_NATIVE = "native";

  /// Type identifier for credit assets with 1-4 character codes.
  static const String TYPE_CREDIT_ALPHANUM4 = "credit_alphanum4";

  /// Type identifier for credit assets with 5-12 character codes.
  static const String TYPE_CREDIT_ALPHANUM12 = "credit_alphanum12";

  /// Type identifier for liquidity pool share assets.
  static const String TYPE_POOL_SHARE = "liquidity_pool_shares";

  /// Creates an Asset from type, code, and issuer strings.
  ///
  /// Parameters:
  /// - [type]: One of TYPE_NATIVE, TYPE_CREDIT_ALPHANUM4, or TYPE_CREDIT_ALPHANUM12
  /// - [code]: Asset code (null for native)
  /// - [issuer]: Issuer account ID (null for native)
  ///
  /// Returns: The appropriate Asset subclass instance
  ///
  /// Example:
  /// ```dart
  /// Asset native = Asset.create(Asset.TYPE_NATIVE, null, null);
  /// Asset usd = Asset.create(
  ///   Asset.TYPE_CREDIT_ALPHANUM4,
  ///   "USD",
  ///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
  /// );
  /// ```
  static Asset create(String type, String? code, String? issuer) {
    if (type == TYPE_NATIVE) {
      return Asset.NATIVE;
    } else {
      return Asset.createNonNativeAsset(code!, issuer!);
    }
  }

  /// Creates a credit asset (AlphaNum4 or AlphaNum12) based on code length.
  ///
  /// Automatically determines the asset type based on the length of the code:
  /// - 1-4 characters: Creates AssetTypeCreditAlphaNum4
  /// - 5-12 characters: Creates AssetTypeCreditAlphaNum12
  ///
  /// Parameters:
  /// - [code]: The asset code (1-12 characters, case-sensitive)
  /// - [issuer]: The issuer's Stellar account ID (G... address)
  ///
  /// Returns: AssetTypeCreditAlphaNum4 or AssetTypeCreditAlphaNum12
  ///
  /// Throws:
  /// - [AssetCodeLengthInvalidException]: If code length is not 1-12 characters
  ///
  /// Example:
  /// ```dart
  /// // Creates AlphaNum4 (code length = 3)
  /// Asset usd = Asset.createNonNativeAsset(
  ///   "USD",
  ///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
  /// );
  ///
  /// // Creates AlphaNum12 (code length = 8)
  /// Asset longAsset = Asset.createNonNativeAsset(
  ///   "LONGCODE",
  ///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
  /// );
  /// ```
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

  /// Creates an Asset from its canonical string representation.
  ///
  /// Canonical form is "code:issuer" for credit assets or "native"/"XLM" for
  /// the native asset. This format is commonly used in URLs and APIs.
  ///
  /// Parameters:
  /// - [canonicalForm]: String in format "CODE:ISSUER" or "native"/"XLM"
  ///
  /// Returns: Asset instance, or null if format is invalid
  ///
  /// Supported formats:
  /// - "native" or "XLM": Returns native asset
  /// - "USD:GDUKMG...": Returns credit asset
  ///
  /// Example:
  /// ```dart
  /// // Parse native asset
  /// Asset? xlm1 = Asset.createFromCanonicalForm("native");
  /// Asset? xlm2 = Asset.createFromCanonicalForm("XLM");
  ///
  /// // Parse credit asset
  /// Asset? usd = Asset.createFromCanonicalForm(
  ///   "USD:GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
  /// );
  ///
  /// if (usd != null) {
  ///   print("Valid asset: ${usd.type}");
  /// }
  /// ```
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

  /// Converts an Asset to its canonical string representation.
  ///
  /// Returns "native" for native asset or "CODE:ISSUER" for credit assets.
  /// This format is useful for URLs, APIs, and storage.
  ///
  /// Parameters:
  /// - [asset]: The asset to convert
  ///
  /// Returns: Canonical string representation
  ///
  /// Throws:
  /// - [Exception]: If asset type is unsupported (e.g., pool shares)
  ///
  /// Example:
  /// ```dart
  /// Asset xlm = Asset.NATIVE;
  /// String canonical1 = Asset.canonicalForm(xlm);
  /// // Returns: "native"
  ///
  /// Asset usd = AssetTypeCreditAlphaNum4("USD", issuerId);
  /// String canonical2 = Asset.canonicalForm(usd);
  /// // Returns: "USD:GDUKMG..."
  /// ```
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

  /// Creates an Asset from its XDR representation.
  ///
  /// XDR (External Data Representation) is the binary format used by Stellar
  /// for serializing data structures in the protocol.
  ///
  /// Parameters:
  /// - [xdrAsset]: XDR asset object to deserialize
  ///
  /// Returns: Appropriate Asset subclass instance
  ///
  /// Throws:
  /// - [Exception]: If XDR contains unknown or unsupported asset type
  ///
  /// Example:
  /// ```dart
  /// // Usually used internally when parsing transaction XDR
  /// Asset asset = Asset.fromXdr(xdrAsset);
  /// ```
  ///
  /// See also:
  /// - [toXdr] for serializing to XDR
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

  /// Returns the asset type identifier.
  ///
  /// Possible types:
  /// - `native`: Native asset (XLM)
  /// - `credit_alphanum4`: Credit asset with 1-4 character code
  /// - `credit_alphanum12`: Credit asset with 5-12 character code
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

  /// Creates an exception for invalid asset code length with an optional error message.
  AssetCodeLengthInvalidException([this.message]);

  /// Returns a string representation of this instance for debugging.
  @override
  String toString() {
    if (message == null) return "AssetCodeLengthInvalidException";
    return "AssetCodeLengthInvalidException: $message";
  }
}
