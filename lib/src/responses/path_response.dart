// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'response.dart';
import '../assets.dart';
import '../asset_type_native.dart';

/// Represents a path response received from the horizon server.
/// See: <a href="https://developers.stellar.org/api/aggregations/paths/" target="_blank">Path documentation</a>
class PathResponse extends Response {
  String destinationAmount;
  String destinationAssetType;
  String destinationAssetCode;
  String destinationAssetIssuer;

  String sourceAmount;
  String sourceAssetType;
  String sourceAssetCode;
  String sourceAssetIssuer;

  List<Asset> path;

  PathResponseLinks links;

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

  Asset get destinationAsset {
    if (destinationAssetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(
          destinationAssetCode, destinationAssetIssuer);
    }
  }

  Asset get sourceAsset {
    if (sourceAssetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sourceAssetCode, sourceAssetIssuer);
    }
  }

  factory PathResponse.fromJson(Map<String, dynamic> json) => new PathResponse(
      json['destination_amount'] as String,
      json['destination_asset_type'] as String,
      json['destination_asset_code'] as String,
      json['destination_asset_issuer'] as String,
      json['source_amount'] as String,
      json['source_asset_type'] as String,
      json['source_asset_code'] as String,
      json['source_asset_issuer'] as String,
      json['path'] == null
          ? null
          : (json['path'] as List)
              ?.map((e) =>
                  e == null ? null : Asset.fromJson(e as Map<String, dynamic>))
              ?.toList(),
      json['_links'] == null
          ? null
          : new PathResponseLinks.fromJson(
              json['_links'] as Map<String, dynamic>))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

///Links connected to a path response received from horizon.
class PathResponseLinks {
  Link self;
  PathResponseLinks(this.self);

  factory PathResponseLinks.fromJson(Map<String, dynamic> json) =>
      new PathResponseLinks(json['self'] == null
          ? null
          : new Link.fromJson(json['self'] as Map<String, dynamic>));
}
