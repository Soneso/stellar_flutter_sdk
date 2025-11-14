// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'asset_type_credit_alphanum.dart';
import 'xdr/xdr_account.dart';
import 'xdr/xdr_asset.dart';
import 'key_pair.dart';
import 'util.dart';

/// Represents credit assets with 1-4 character asset codes.
///
/// This is the most common type of credit asset on Stellar, used for assets
/// with short codes like "USD", "EUR", "BTC", "USDC", etc.
///
/// Asset code requirements:
/// - Length: 1-4 characters (inclusive)
/// - Characters: ASCII 32-127 excluding spaces
/// - Case-sensitive: "USD" and "usd" are different assets
/// - No leading/trailing spaces
///
/// Common examples:
/// - Fiat currencies: "USD", "EUR", "JPY", "GBP"
/// - Cryptocurrencies: "BTC", "ETH"
/// - Stablecoins: "USDC" (4 chars, fits in AlphaNum4)
/// - Custom tokens: "GOLD", "OIL", "COIN"
///
/// Creating assets:
/// ```dart
/// // US Dollar issued by an anchor
/// Asset usd = AssetTypeCreditAlphaNum4(
///   "USD",
///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
/// );
///
/// // Bitcoin token
/// Asset btc = AssetTypeCreditAlphaNum4(
///   "BTC",
///   "GD5J6HLF5666X4AZLTFTXLY46J5SW7EXRKBLEYPJP33S33MXZGV6CWFN"
/// );
///
/// // Single character code
/// Asset x = AssetTypeCreditAlphaNum4("X", issuerId);
/// ```
///
/// Using in operations:
/// ```dart
/// // Create trustline
/// ChangeTrustOperation trustOp = ChangeTrustOperationBuilder(
///   usd,
///   "10000" // Maximum amount to trust
/// ).build();
///
/// // Make payment
/// PaymentOperation paymentOp = PaymentOperationBuilder(
///   destinationId,
///   usd,
///   "100.50"
/// ).build();
/// ```
///
/// Important notes:
/// - Codes longer than 4 characters must use [AssetTypeCreditAlphaNum12]
/// - Empty codes or codes > 4 characters throw [AssetCodeLengthInvalidException]
/// - Always verify the issuer address before trusting an asset
/// - Asset code "XLM" is valid but discouraged (could confuse with native)
///
/// See also:
/// - [AssetTypeCreditAlphaNum12] for codes 5-12 characters
/// - [AssetTypeCreditAlphaNum] for base credit asset functionality
/// - [Asset] for general asset operations
/// - [ChangeTrustOperation] for establishing trustlines
class AssetTypeCreditAlphaNum4 extends AssetTypeCreditAlphaNum {
  /// Creates a credit asset with a 1-4 character code.
  ///
  /// Parameters:
  /// - [code]: Asset code (1-4 characters, case-sensitive)
  /// - [issuerId]: Issuer's Stellar account ID (G... address)
  ///
  /// Throws:
  /// - [AssetCodeLengthInvalidException]: If code length is not 1-4 characters
  ///
  /// Example:
  /// ```dart
  /// Asset usd = AssetTypeCreditAlphaNum4(
  ///   "USD",
  ///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
  /// );
  /// ```
  AssetTypeCreditAlphaNum4(String code, String issuerId)
      : super(code, issuerId) {
    if (code.length < 1 || code.length > 4) {
      throw new AssetCodeLengthInvalidException();
    }
  }

  @override
  String get type => Asset.TYPE_CREDIT_ALPHANUM4;

  @override
  XdrAsset toXdr() {
    XdrAsset xdrAsset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);

    XdrAccountID accountID =
        XdrAccountID(KeyPair.fromAccountId(issuerId).xdrPublicKey);

    XdrAssetAlphaNum4 credit =
        XdrAssetAlphaNum4(Util.paddedByteArrayString(mCode, 4), accountID);
    xdrAsset.alphaNum4 = credit;
    return xdrAsset;
  }
}
