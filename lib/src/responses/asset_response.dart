// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import 'account_response.dart';
import 'response.dart';

/// Represents an asset response from Horizon.
///
/// Assets are representations of value issued on the Stellar network. Each asset
/// consists of a type, code, and issuer account. This response provides comprehensive
/// statistics about asset usage including distribution across accounts, claimable balances,
/// liquidity pools, and smart contracts.
///
/// Assets can have three types:
/// - native: The native asset (XLM)
/// - credit_alphanum4: Asset code with 1-4 alphanumeric characters
/// - credit_alphanum12: Asset code with 5-12 alphanumeric characters
///
/// Example:
/// ```dart
/// // Query assets by code
/// var assets = await sdk.assets
///     .forAssetCode('USDC')
///     .order(RequestBuilderOrder.DESC)
///     .limit(10)
///     .execute();
///
/// for (var asset in assets.records) {
///   print('Asset: ${asset.assetCode}');
///   print('Issuer: ${asset.assetIssuer}');
///   print('Total amount: ${asset.balances.authorized}');
///   print('Accounts holding asset: ${asset.accounts.authorized}');
///
///   // Check authorization levels
///   print('Authorized accounts: ${asset.accounts.authorized}');
///   print('Authorized to maintain liabilities: ${asset.accounts.authorizedToMaintainLiabilities}');
///   print('Unauthorized accounts: ${asset.accounts.unauthorized}');
///
///   // Check asset flags
///   print('Auth required: ${asset.flags.authRequired}');
///   print('Auth revocable: ${asset.flags.authRevocable}');
/// }
/// ```
///
/// See also:
/// - [Asset] for creating asset instances
/// - [AssetsRequestBuilder] for querying assets
/// - [Horizon Assets API](https://developers.stellar.org/docs/data/horizon/api-reference/resources/assets)
class AssetResponse extends Response {
  /// The asset type. One of: native, credit_alphanum4, credit_alphanum12
  String assetType;

  /// The asset code (e.g., USD, BTC). Not present for native assets.
  String assetCode;

  /// The account ID of the asset issuer. Not present for native assets.
  String assetIssuer;

  /// Statistics about accounts holding this asset, grouped by authorization level.
  AssetAccounts accounts;

  /// Number of claimable balances holding this asset.
  int numClaimableBalances;

  /// Total amount of this asset in existence across all holders, grouped by authorization level.
  AssetBalances balances;

  /// Total amount of this asset held in claimable balances.
  String claimableBalancesAmount;

  /// Cursor value for paginating through asset results.
  String pagingToken;

  /// Number of liquidity pools containing this asset.
  int numLiquidityPools;

  /// Total amount of this asset held in liquidity pools.
  String liquidityPoolsAmount;

  /// Authorization flags set by the asset issuer.
  Flags flags;

  /// Hypermedia links to related resources.
  AssetResponseLinks links;

  /// Number of smart contracts holding this asset.
  int numContracts;

  /// Total amount of this asset held in smart contracts.
  String contractsAmount;

  /// The Soroban contract ID for this asset (if deployed as a contract).
  String? contractId;

  AssetResponse(
    this.assetType,
    this.assetCode,
    this.assetIssuer,
    this.accounts,
    this.numClaimableBalances,
    this.balances,
    this.claimableBalancesAmount,
    this.pagingToken,
    this.numLiquidityPools,
    this.liquidityPoolsAmount,
    this.flags,
    this.links,
    this.numContracts,
    this.contractsAmount,
    this.contractId,
  );

  Asset get asset {
    return Asset.create(this.assetType, this.assetCode, this.assetIssuer);
  }

  factory AssetResponse.fromJson(Map<String, dynamic> json) => AssetResponse(
      json['asset_type'],
      json['asset_code'],
      json['asset_issuer'],
      AssetAccounts.fromJson(json['accounts']),
      convertInt(json['num_claimable_balances']!)!,
      AssetBalances.fromJson(json['balances']),
      json['claimable_balances_amount'],
      json['paging_token'],
      convertInt(json['num_liquidity_pools']!)!,
      json['liquidity_pools_amount'],
      Flags.fromJson(json['flags']),
      AssetResponseLinks.fromJson(json['_links']),
      convertInt(json['num_contracts'])!,
      json['contracts_amount'],
      json['contract_id'])
    ..rateLimitLimit = convertInt(json['rateLimitLimit'])
    ..rateLimitRemaining = convertInt(json['rateLimitRemaining'])
    ..rateLimitReset = convertInt(json['rateLimitReset']);
}

/// Hypermedia links connected to an asset response.
///
/// Provides links to related resources for this asset.
class AssetResponseLinks {
  /// Link to the stellar.toml file for this asset's issuer.
  ///
  /// The stellar.toml file contains metadata about the asset and its issuer,
  /// including asset documentation, issuer information, and other disclosures.
  Link toml;

  AssetResponseLinks(this.toml);

  factory AssetResponseLinks.fromJson(Map<String, dynamic> json) {
    return AssetResponseLinks(Link.fromJson(json['toml']));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'toml': toml};
}

/// Statistics about accounts holding an asset, grouped by authorization level.
///
/// Asset issuers can control who can hold and transact with their asset through
/// authorization flags. This class provides counts of accounts in each authorization state.
class AssetAccounts {
  /// Number of accounts that are fully authorized to hold and transact with this asset.
  ///
  /// These accounts can receive, hold, and send the asset without restrictions.
  int authorized;

  /// Number of accounts authorized to maintain existing liabilities but not receive new units.
  ///
  /// These accounts can send the asset and participate in existing offers, but cannot
  /// receive new units of the asset. This is a transitional state used when removing
  /// authorization from an account.
  int authorizedToMaintainLiabilities;

  /// Number of accounts that are not authorized to hold or transact with this asset.
  ///
  /// These accounts cannot receive or send the asset. If auth is required, accounts
  /// start in this state until explicitly authorized by the issuer.
  int unauthorized;

  AssetAccounts(
      this.authorized, this.authorizedToMaintainLiabilities, this.unauthorized);

  factory AssetAccounts.fromJson(Map<String, dynamic> json) => AssetAccounts(
      convertInt(json['authorized']!)!,
      convertInt(json['authorized_to_maintain_liabilities']!)!,
      convertInt(json['unauthorized']!)!);
}

/// Total amount of an asset in existence, grouped by authorization level.
///
/// Provides the sum of all balances held by accounts in each authorization state.
/// All amounts are represented as strings to preserve decimal precision.
class AssetBalances {
  /// Total amount held by fully authorized accounts.
  ///
  /// This represents the sum of all balances for accounts that are authorized
  /// to transact with this asset.
  String authorized;

  /// Total amount held by accounts authorized to maintain liabilities only.
  ///
  /// This represents the sum of all balances for accounts that can send but
  /// not receive the asset.
  String authorizedToMaintainLiabilities;

  /// Total amount held by unauthorized accounts.
  ///
  /// This represents the sum of all balances for accounts that are not authorized
  /// to transact with this asset. Typically zero unless authorization was revoked
  /// after balances were acquired.
  String unauthorized;

  AssetBalances(
      this.authorized, this.authorizedToMaintainLiabilities, this.unauthorized);

  factory AssetBalances.fromJson(Map<String, dynamic> json) => AssetBalances(
      json['authorized'],
      json['authorized_to_maintain_liabilities'],
      json['unauthorized']);
}
