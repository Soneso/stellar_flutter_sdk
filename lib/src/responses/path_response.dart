// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../assets.dart';
import '../asset_type_native.dart';

/// Represents a payment path found by the Stellar path finding algorithm.
///
/// PathResponse contains information about a possible payment path between
/// two assets, including the amounts and intermediate assets required for
/// cross-asset payments. The Stellar network uses path finding to enable
/// payments in assets the sender doesn't directly hold, by automatically
/// finding conversion paths through orderbooks and liquidity pools.
///
/// Path finding is essential for:
/// - Cross-asset payments (paying in one asset while recipient receives another)
/// - Finding the best conversion rate between assets
/// - Discovering trading opportunities
/// - Building path payment operations
///
/// Example:
/// ```dart
/// // Find paths to send USD and have recipient receive EUR
/// var sourceAsset = AssetTypeCreditAlphaNum4(
///   'USD', 'ISSUER_ACCOUNT_ID');
/// var destinationAsset = AssetTypeCreditAlphaNum4(
///   'EUR', 'ISSUER_ACCOUNT_ID');
///
/// var paths = await sdk.strictSendPaths
///   .sourceAsset(sourceAsset)
///   .sourceAmount('100')
///   .destinationAssets([destinationAsset])
///   .execute();
///
/// for (var path in paths.records) {
///   print('Send ${path.sourceAmount} ${path.sourceAsset.code}');
///   print('Receive ${path.destinationAmount} ${path.destinationAsset.code}');
///   print('Path length: ${path.path.length}');
///
///   // Show intermediate conversions
///   for (var asset in path.path) {
///     print('  Via ${asset.code}');
///   }
/// }
/// ```
///
/// See also:
/// - [PathPaymentStrictSendOperation] for sending path payments
/// - [PathPaymentStrictReceiveOperation] for receiving path payments
/// - [Stellar developer docs](https://developers.stellar.org)
class PathResponse extends Response {
  /// Amount of destination asset received at the end of the path.
  ///
  /// This is the final amount the recipient will receive after all conversions
  /// along the payment path have been executed.
  String destinationAmount;

  /// Asset type of the destination asset (native, credit_alphanum4, credit_alphanum12).
  String destinationAssetType;

  /// Asset code of the destination asset (null for native XLM).
  String? destinationAssetCode;

  /// Issuer account ID of the destination asset (null for native XLM).
  String? destinationAssetIssuer;

  /// Amount of source asset sent at the start of the path.
  ///
  /// This is the initial amount the sender must provide to execute this
  /// payment path. The source amount will be converted through intermediate
  /// assets to arrive at the destination amount.
  String sourceAmount;

  /// Asset type of the source asset (native, credit_alphanum4, credit_alphanum12).
  String sourceAssetType;

  /// Asset code of the source asset (null for native XLM).
  String? sourceAssetCode;

  /// Issuer account ID of the source asset (null for native XLM).
  String? sourceAssetIssuer;

  /// List of intermediate assets in the payment path.
  ///
  /// This is the sequence of assets the payment will be converted through
  /// to reach from source to destination. An empty list means a direct
  /// conversion is possible. Each asset in the path represents a hop
  /// through an orderbook or liquidity pool.
  List<Asset> path;

  /// Hypermedia links to related resources.
  PathResponseLinks? links;

  /// Creates a PathResponse from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API path finding endpoints.
  ///
  /// Parameters:
  /// - [destinationAmount] Amount of destination asset received
  /// - [destinationAssetType] Asset type of destination
  /// - [destinationAssetCode] Asset code of destination
  /// - [destinationAssetIssuer] Issuer of destination asset
  /// - [sourceAmount] Amount of source asset sent
  /// - [sourceAssetType] Asset type of source
  /// - [sourceAssetCode] Asset code of source
  /// - [sourceAssetIssuer] Issuer of source asset
  /// - [path] List of intermediate assets in the payment path
  /// - [links] Hypermedia links to related resources
  PathResponse(
      this.destinationAmount,
      this.destinationAssetType,
      this.destinationAssetCode,
      this.destinationAssetIssuer,
      this.sourceAmount,
      this.sourceAssetType,
      this.sourceAssetCode,
      this.sourceAssetIssuer,
      this.path,
      this.links);

  /// The destination asset as an Asset object.
  ///
  /// Convenience getter that constructs an Asset from the destination
  /// asset type, code, and issuer fields.
  Asset get destinationAsset {
    if (destinationAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(destinationAssetCode!, destinationAssetIssuer!);
    }
  }

  /// The source asset as an Asset object.
  ///
  /// Convenience getter that constructs an Asset from the source
  /// asset type, code, and issuer fields.
  Asset get sourceAsset {
    if (sourceAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sourceAssetCode!, sourceAssetIssuer!);
    }
  }

  /// Constructs a PathResponse from JSON returned by Horizon API.
  factory PathResponse.fromJson(Map<String, dynamic> json) => PathResponse(
      json['destination_amount'],
      json['destination_asset_type'],
      json['destination_asset_code'],
      json['destination_asset_issuer'],
      json['source_amount'],
      json['source_asset_type'],
      json['source_asset_code'],
      json['source_asset_issuer'],
      json['path'] == null
          ? []
          : (json['path'] as List).map((e) => e = Asset.fromJson(e)).toList(),
      json['_links'] == null ? null : PathResponseLinks.fromJson(json['_links']))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Hypermedia links related to this path response.
///
/// Contains links to related resources following the HAL (Hypertext Application Language)
/// specification, enabling navigation through the Horizon API.
class PathResponseLinks {
  /// Link to this path resource.
  Link? self;

  /// Creates a PathResponseLinks from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API endpoints.
  ///
  /// Parameters:
  /// - [self] Link to this path resource
  PathResponseLinks(this.self);

  /// Constructs PathResponseLinks from JSON returned by Horizon API.
  factory PathResponseLinks.fromJson(Map<String, dynamic> json) =>
      PathResponseLinks(json['self'] == null ? null : Link.fromJson(json['self']));
}
