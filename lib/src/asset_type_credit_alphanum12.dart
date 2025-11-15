// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'asset_type_credit_alphanum.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_asset.dart';
import 'key_pair.dart';
import 'util.dart';

/// Represents credit assets with 5-12 character asset codes.
///
/// This asset type is used for assets with longer codes that don't fit in
/// AlphaNum4 (1-4 characters). Common for branded tokens and specific
/// asset identifiers.
///
/// Asset code requirements:
/// - Length: 5-12 characters (inclusive)
/// - Characters: ASCII 32-127 excluding spaces
/// - Case-sensitive: "LONGCODE" and "longcode" are different
/// - No leading/trailing spaces
///
/// Common examples:
/// - Domain-based codes: "example.com", "anchor.io"
/// - Descriptive names: "GOLDTOKEN", "SHARECLASS"
/// - Versioned assets: "USDC2024", "TOKEN-V2"
/// - Brand identifiers: "ACMECOINS"
///
/// Creating assets:
/// ```dart
/// // Long asset code
/// Asset longAsset = AssetTypeCreditAlphaNum12(
///   "LONGASSET",
///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
/// );
///
/// // Domain-based code
/// Asset domainAsset = AssetTypeCreditAlphaNum12(
///   "example.com",
///   "GD5J6HLF5666X4AZLTFTXLY46J5SW7EXRKBLEYPJP33S33MXZGV6CWFN"
/// );
///
/// // Maximum length (12 characters)
/// Asset maxLength = AssetTypeCreditAlphaNum12(
///   "TWELVECHARS",
///   issuerId
/// );
/// ```
///
/// Using in operations:
/// ```dart
/// // Create trustline
/// ChangeTrustOperation trustOp = ChangeTrustOperationBuilder(
///   longAsset,
///   "1000000"
/// ).build();
///
/// // Make payment
/// PaymentOperation paymentOp = PaymentOperationBuilder(
///   destinationId,
///   longAsset,
///   "50.25"
/// ).build();
/// ```
///
/// Important notes:
/// - Codes 1-4 characters must use [AssetTypeCreditAlphaNum4] instead
/// - Codes < 5 or > 12 characters throw [AssetCodeLengthInvalidException]
/// - Always verify the issuer address before trusting
/// - Asset ordering: AlphaNum4 < AlphaNum12 (matters for liquidity pools)
///
/// See also:
/// - [AssetTypeCreditAlphaNum4] for codes 1-4 characters
/// - [AssetTypeCreditAlphaNum] for base credit asset functionality
/// - [Asset] for general asset operations
/// - [ChangeTrustOperation] for establishing trustlines
class AssetTypeCreditAlphaNum12 extends AssetTypeCreditAlphaNum {
  /// Creates a credit asset with a 5-12 character code.
  ///
  /// Parameters:
  /// - [code] Asset code (5-12 characters, case-sensitive)
  /// - [issuerId] Issuer's Stellar account ID (G... address)
  ///
  /// Throws:
  /// - [AssetCodeLengthInvalidException] If code length is not 5-12 characters
  ///
  /// Example:
  /// ```dart
  /// Asset longCode = AssetTypeCreditAlphaNum12(
  ///   "LONGASSET",
  ///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
  /// );
  /// ```
  AssetTypeCreditAlphaNum12(String code, String issuerId)
      : super(code, issuerId) {
    if (code.length < 5 || code.length > 12) {
      throw new AssetCodeLengthInvalidException();
    }
  }

  @override
  String get type => Asset.TYPE_CREDIT_ALPHANUM12;

  /// Converts this asset to its XDR Asset representation.
  ///
  /// Returns: XDR Asset for this 12-character credit alphanum asset.
  @override
  XdrAsset toXdr() {
    XdrAsset xdrAsset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);

    XdrAssetAlphaNum12 credit = XdrAssetAlphaNum12(
        Util.paddedByteArrayString(mCode, 12),
        XdrAccountID(KeyPair.fromAccountId(issuerId).xdrPublicKey));
    xdrAsset.alphaNum12 = credit;
    return xdrAsset;
  }
}
