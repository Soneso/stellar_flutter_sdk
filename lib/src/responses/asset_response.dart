// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import 'account_response.dart';
import 'response.dart';

/// Represents an asset response from the horizon server. Assets are representations of value issued on the Stellar network. An asset consists of a type, code, and issuer.
/// See: <a href="https://developers.stellar.org/api/resources/assets/" target="_blank">Assets documentation</a>.
class AssetResponse extends Response {
  String? assetType;
  String? assetCode;
  String? assetIssuer;
  AssetAccounts? accounts;
  int? numClaimableBalances;
  AssetBalances? balances;
  String? claimableBalancesAmount;
  String? pagingToken;
  String? amount;
  int? numAccounts;
  Flags? flags;
  AssetResponseLinks? links;

  AssetResponse(
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.accounts,
      this.numClaimableBalances,
      this.balances,
      this.claimableBalancesAmount,
      this.pagingToken,
      this.amount,
      this.numAccounts,
      this.flags,
      this.links);

  Asset get asset {
    return Asset.create(this.assetType!, this.assetCode!, this.assetIssuer!);
  }

  factory AssetResponse.fromJson(Map<String, dynamic> json) => AssetResponse(
      json['asset_type'],
      json['asset_code'],
      json['asset_issuer'],
      json['accounts'] == null ? null : AssetAccounts.fromJson(json['accounts']),
      convertInt(json['num_claimable_balances']),
      json['balances'] == null ? null : AssetBalances.fromJson(json['balances']),
      json['claimable_balances_amount'],
      json['paging_token'],
      json['amount'],
      convertInt(json['num_accounts']),
      json['flags'] == null ? null : Flags.fromJson(json['flags']),
      json['_links'] == null ? null : AssetResponseLinks.fromJson(json['_links']))
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Links connected to an asset response from the horizon server.
class AssetResponseLinks {
  Link? toml;

  AssetResponseLinks(this.toml);

  factory AssetResponseLinks.fromJson(Map<String, dynamic> json) {
    return AssetResponseLinks(json['toml'] == null ? null : Link.fromJson(json['toml']));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'toml': toml};
}

class AssetAccounts {
  int? authorized;
  int? authorizedToMaintainLiabilities;
  int? unauthorized;

  AssetAccounts(this.authorized, this.authorizedToMaintainLiabilities, this.unauthorized);

  factory AssetAccounts.fromJson(Map<String, dynamic> json) => AssetAccounts(
      convertInt(json['authorized']),
      convertInt(json['authorized_to_maintain_liabilities']),
      convertInt(json['unauthorized']));
}

class AssetBalances {
  String? authorized;
  String? authorizedToMaintainLiabilities;
  String? unauthorized;

  AssetBalances(this.authorized, this.authorizedToMaintainLiabilities, this.unauthorized);

  factory AssetBalances.fromJson(Map<String, dynamic> json) => AssetBalances(
      json['authorized'], json['authorized_to_maintain_liabilities'], json['unauthorized']);
}
