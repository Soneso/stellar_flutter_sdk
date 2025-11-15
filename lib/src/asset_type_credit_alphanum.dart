// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'assets.dart';
import 'xdr/xdr_asset.dart';

/// Base class for issued credit assets on the Stellar network.
///
/// This abstract class provides common functionality for both AlphaNum4
/// (1-4 character codes) and AlphaNum12 (5-12 character codes) credit assets.
/// Credit assets are issued by specific accounts and require trustlines.
///
/// Credit assets consist of:
/// - **Code**: 1-12 character identifier (case-sensitive, ASCII 32-127 except spaces)
/// - **Issuer**: Stellar account ID (G... address) that creates the asset
///
/// Unlike the native asset (XLM), credit assets:
/// - Require recipients to establish trustlines before receiving
/// - Can have authorization controls (required, revocable, clawback)
/// - Are issued by specific accounts (not built-in to the network)
/// - Can represent any type of value (fiat, commodities, tokens, etc.)
///
/// Use the concrete subclasses:
/// - [AssetTypeCreditAlphaNum4]: For codes 1-4 characters (e.g., "USD", "BTC")
/// - [AssetTypeCreditAlphaNum12]: For codes 5-12 characters (e.g., "USDC", "EURT")
///
/// Common operations:
/// ```dart
/// // Create credit asset (use specific subclass)
/// Asset usd = AssetTypeCreditAlphaNum4(
///   "USD",
///   "GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX"
/// );
///
/// // Access code and issuer
/// if (usd is AssetTypeCreditAlphaNum) {
///   print("Code: ${usd.code}");
///   print("Issuer: ${usd.issuerId}");
/// }
///
/// // Compare assets
/// Asset usd2 = AssetTypeCreditAlphaNum4("USD", sameIssuerId);
/// bool same = (usd == usd2); // true if code and issuer match
/// ```
///
/// Important notes:
/// - Asset codes are case-sensitive ("USD" != "usd")
/// - Two assets are equal only if both code and issuer match
/// - Always verify issuer addresses before trusting assets
/// - Some issuers require authorization before accounts can hold their assets
///
/// See also:
/// - [AssetTypeCreditAlphaNum4] for 1-4 character asset codes
/// - [AssetTypeCreditAlphaNum12] for 5-12 character asset codes
/// - [Asset] for base asset functionality
/// - [ChangeTrustOperation] for establishing trustlines
abstract class AssetTypeCreditAlphaNum extends Asset {
  /// The asset code (1-12 characters, case-sensitive).
  ///
  /// This is the identifier for the asset such as "USD", "BTC", or "USDC".
  /// Combined with the issuer, it uniquely identifies this asset on the network.
  String mCode;

  /// The Stellar account ID (G... address) that issued this asset.
  ///
  /// The issuer is the account that creates and controls the asset.
  /// Issuers can set authorization flags and other asset properties.
  String issuerId;

  /// Creates a credit asset with the given code and issuer.
  ///
  /// Parameters:
  /// - [mCode]: The asset code (1-12 characters)
  /// - [issuerId]: The issuer's Stellar account ID
  AssetTypeCreditAlphaNum(this.mCode, this.issuerId);

  /// Returns the asset code as a string.
  ///
  /// The asset code is a 1-12 character identifier that, combined with
  /// the issuer, uniquely identifies this asset on the network.
  String get code => String.fromCharCodes(mCode.codeUnits);

  /// Returns the hash code for this instance based on its fields.
  @override
  int get hashCode {
    return "${this.code}\$${this.issuerId}".hashCode;
  }

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [object] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object object) {
    if (!(object is AssetTypeCreditAlphaNum)) {
      return false;
    }

    return (this.code == object.code) && (this.issuerId == object.issuerId);
  }

  /// Converts this asset to its XDR ChangeTrustAsset representation.
  ///
  /// Returns: XDR ChangeTrustAsset for this credit alphanum asset.
  @override
  XdrChangeTrustAsset toXdrChangeTrustAsset() {
    return XdrChangeTrustAsset.fromXdrAsset(toXdr());
  }

  /// Converts this asset to its XDR TrustlineAsset representation.
  ///
  /// Returns: XDR TrustlineAsset for this credit alphanum asset.
  @override
  XdrTrustlineAsset toXdrTrustLineAsset() {
    return XdrTrustlineAsset.fromXdrAsset(toXdr());
  }

}
