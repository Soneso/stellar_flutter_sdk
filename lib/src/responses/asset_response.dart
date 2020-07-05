// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import 'account_response.dart';
import 'response.dart';

/// Represents an asset response from the horizon server. Assets are representations of value issued on the Stellar network. An asset consists of a type, code, and issuer.
/// See: <a href="https://developers.stellar.org/api/resources/assets/" target="_blank">Assets documentation</a>.
class AssetResponse extends Response {
  String assetType;
  String assetCode;
  String assetIssuer;
  String pagingToken;
  String amount;
  int numAccounts;
  Flags flags;
  AssetResponseLinks links;

  AssetResponse(this.assetType, this.assetCode, this.assetIssuer,
      this.pagingToken, this.amount, this.numAccounts, this.flags, this.links);

  Asset get asset {
    return Asset.create(this.assetType, this.assetCode, this.assetIssuer);
  }

  factory AssetResponse.fromJson(Map<String, dynamic> json) =>
      new AssetResponse(
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String,
          json['paging_token'] as String,
          json['amount'] as String,
          convertInt(json['num_accounts']),
          json['flags'] == null
              ? null
              : new Flags.fromJson(json['flags'] as Map<String, dynamic>),
          json['_links'] == null
              ? null
              : new AssetResponseLinks.fromJson(
                  json['_links'] as Map<String, dynamic>))
        ..rateLimitLimit = convertInt(json['rateLimitLimit'])
        ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
        ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Links connected to an asset response from the horizon server.
class AssetResponseLinks {
  Link toml;
  AssetResponseLinks(this.toml);

  factory AssetResponseLinks.fromJson(Map<String, dynamic> json) {
    return new AssetResponseLinks(json['toml'] == null
        ? null
        : new Link.fromJson(json['toml'] as Map<String, dynamic>));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'toml': toml};
}
