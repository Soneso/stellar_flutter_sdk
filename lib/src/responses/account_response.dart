// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import '../assets.dart';
import '../asset_type_native.dart';
import '../key_pair.dart';
import '../account.dart';
import '../muxed_account.dart';
import 'response.dart';

/// Represents an account in the Stellar network.
///
/// AccountResponse contains comprehensive information about a Stellar account,
/// including balances, signers, thresholds, flags, and metadata. Accounts are
/// the fundamental entities in Stellar that own assets, submit transactions,
/// and interact with the ledger.
///
/// This class implements [TransactionBuilderAccount], allowing it to be used
/// directly when building transactions.
///
/// Example:
/// ```dart
/// var account = await sdk.accounts.account(accountId);
///
/// // Access account properties
/// print('Account ID: ${account.accountId}');
/// print('Sequence: ${account.sequenceNumber}');
/// print('Home domain: ${account.homeDomain}');
///
/// // Check balances
/// for (var balance in account.balances) {
///   if (balance.assetType == 'native') {
///     print('XLM balance: ${balance.balance}');
///   } else {
///     print('${balance.assetCode}: ${balance.balance}');
///   }
/// }
///
/// // Check signers
/// for (var signer in account.signers) {
///   print('Signer: ${signer.key}, weight: ${signer.weight}');
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [Balance] for asset balance information
/// - [Signer] for account signer information
class AccountResponse extends Response implements TransactionBuilderAccount {
  /// The public key of this account.
  String accountId;

  /// The current sequence number for this account.
  BigInt _sequenceNumber;

  /// Cursor value for paginating through account results.
  String pagingToken;

  /// Number of subentries (trustlines, offers, signers, data entries) for this account.
  int subentryCount;

  /// Account designated to receive inflation (deprecated).
  String? inflationDestination;

  /// The home domain associated with this account.
  String? homeDomain;

  /// Ledger sequence number when this account was last modified.
  int lastModifiedLedger;

  /// Timestamp when this account was last modified.
  String? lastModifiedTime;

  /// Signature thresholds for this account.
  Thresholds thresholds;

  /// Authorization flags for this account.
  Flags flags;

  /// List of asset balances held by this account.
  List<Balance> balances;

  /// List of signers authorized to sign transactions for this account.
  List<Signer> signers;

  /// Custom data entries stored on this account.
  AccountResponseData data;

  /// Hypermedia links to related resources.
  AccountResponseLinks links;

  /// Account that sponsors the base reserve for this account.
  String? sponsor;

  /// Number of reserves this account is sponsoring for other accounts.
  int numSponsoring;

  /// Number of reserves sponsored for this account by other accounts.
  int numSponsored;

  /// Optional muxed account ID for multiplexed accounts.
  BigInt? muxedAccountMed25519Id;

  /// Ledger sequence number of the account's last sequence number update.
  int? sequenceLedger;

  /// Timestamp of the account's last sequence number update.
  String? sequenceTime;

  /// Creates an AccountResponse from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing
  /// Horizon API responses. Use [AccountsRequestBuilder.account] to retrieve
  /// account data from the network.
  AccountResponse(
      this.accountId,
      this._sequenceNumber,
      this.pagingToken,
      this.subentryCount,
      this.inflationDestination,
      this.homeDomain,
      this.lastModifiedLedger,
      this.lastModifiedTime,
      this.thresholds,
      this.flags,
      this.balances,
      this.signers,
      this.data,
      this.links,
      this.sponsor,
      this.numSponsored,
      this.numSponsoring,
      this.sequenceLedger,
      this.sequenceTime);

  // @override
  KeyPair get keypair => KeyPair.fromAccountId(accountId);

  @override
  BigInt get sequenceNumber => _sequenceNumber;

  @override
  BigInt get incrementedSequenceNumber => _sequenceNumber + BigInt.one;

  @override
  void incrementSequenceNumber() => _sequenceNumber = _sequenceNumber + BigInt.one;

  @override
  MuxedAccount get muxedAccount =>
      MuxedAccount(accountId, muxedAccountMed25519Id);

  factory AccountResponse.fromJson(Map<String, dynamic> json) =>
      AccountResponse(
        json['account_id'],
        BigInt.parse(json['sequence']),
        json['paging_token'],
        convertInt(json['subentry_count'])!,
        json['inflation_destination'],
        json['home_domain'],
        convertInt(json['last_modified_ledger'])!,
        json['last_modified_time'],
        Thresholds.fromJson(json['thresholds']),
        Flags.fromJson(json['flags']),
        List<Balance>.from(json['balances'].map((e) => Balance.fromJson(e))),
        List<Signer>.from(json['signers'].map((e) => Signer.fromJson(e))),
        AccountResponseData(json['data']),
        AccountResponseLinks.fromJson(json['_links']),
        json['sponsor'],
        convertInt(json['num_sponsoring'])!,
        convertInt(json['num_sponsored'])!,
        convertInt(json['sequence_ledger']),
        json['sequence_time'],
      );
}

/// Account signature threshold weights for different operation types.
///
/// Thresholds determine how much signing weight is required for operations
/// based on their security level. Operations are categorized as low, medium,
/// or high threshold based on their potential impact.
///
/// Example:
/// ```dart
/// var account = await sdk.accounts.account(accountId);
/// print('Low threshold: ${account.thresholds.lowThreshold}');
/// print('Medium threshold: ${account.thresholds.medThreshold}');
/// print('High threshold: ${account.thresholds.highThreshold}');
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
class Thresholds {
  /// Weight required for low-security operations (e.g., allow trust).
  int lowThreshold;

  /// Weight required for medium-security operations (e.g., payments, offers).
  int medThreshold;

  /// Weight required for high-security operations (e.g., set options, account merge).
  int highThreshold;

  /// Creates a Thresholds instance.
  ///
  /// Parameters:
  /// - [lowThreshold]: Weight required for low-security operations
  /// - [medThreshold]: Weight required for medium-security operations
  /// - [highThreshold]: Weight required for high-security operations
  Thresholds(this.lowThreshold, this.medThreshold, this.highThreshold);

  factory Thresholds.fromJson(Map<String, dynamic> json) => Thresholds(
      convertInt(json['low_threshold'])!,
      convertInt(json['med_threshold'])!,
      convertInt(json['high_threshold'])!);
}

/// Authorization flags that control account behavior for issued assets.
///
/// Flags determine whether an account requires authorization for holding assets
/// and whether issued assets can be revoked or clawed back.
///
/// Example:
/// ```dart
/// var account = await sdk.accounts.account(issuerId);
/// if (account.flags.authRequired) {
///   print('Account requires authorization for trustlines');
/// }
/// if (account.flags.clawbackEnabled) {
///   print('Account can clawback issued assets');
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
class Flags {
  /// Whether trustlines to this account require authorization.
  bool authRequired;

  /// Whether this account can revoke authorization of trustlines.
  bool authRevocable;

  /// Whether authorization flags are permanently set (cannot be changed).
  bool authImmutable;

  /// Whether this account can clawback issued assets.
  bool clawbackEnabled;

  /// Creates a Flags instance.
  ///
  /// Parameters:
  /// - [authRequired]: Whether authorization is required for trustlines
  /// - [authRevocable]: Whether authorization can be revoked
  /// - [authImmutable]: Whether flags are immutable
  /// - [clawbackEnabled]: Whether clawback is enabled
  Flags(this.authRequired, this.authRevocable, this.authImmutable,
      this.clawbackEnabled);

  factory Flags.fromJson(Map<String, dynamic> json) => Flags(
        json['auth_required'],
        json['auth_revocable'],
        json['auth_immutable'],
        json['auth_clawback_enabled'],
      );
}

/// Represents an asset balance held by an account.
///
/// Balance contains information about an asset the account holds, including
/// the amount, trustline limits, liabilities, and authorization status.
///
/// Example:
/// ```dart
/// var account = await sdk.accounts.account(accountId);
/// for (var balance in account.balances) {
///   if (balance.assetType == 'native') {
///     print('XLM: ${balance.balance}');
///   } else {
///     print('${balance.assetCode} (${balance.assetIssuer}): ${balance.balance}');
///     print('Limit: ${balance.limit}');
///   }
/// }
/// ```
///
/// See also:
/// - [AccountResponse] for full account details
/// - [Stellar developer docs](https://developers.stellar.org)
class Balance {
  /// Asset type (native, credit_alphanum4, credit_alphanum12, or liquidity_pool_shares).
  String assetType;

  String? assetCode;
  String? assetIssuer;
  String? limit;

  /// Amount of the asset held by the account (decimal string format).
  String balance;
  String? buyingLiabilities;
  String? sellingLiabilities;
  bool? isAuthorized;
  bool? isAuthorizedToMaintainLiabilities;
  bool? isClawbackEnabled;
  int? lastModifiedLedger;
  String? lastModifiedTime;
  String? sponsor;
  String? liquidityPoolId;

  /// Creates a Balance instance from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing
  /// account balance data from Horizon API responses.
  Balance(
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.balance,
      this.limit,
      this.buyingLiabilities,
      this.sellingLiabilities,
      this.isAuthorized,
      this.isAuthorizedToMaintainLiabilities,
      this.isClawbackEnabled,
      this.lastModifiedLedger,
      this.lastModifiedTime,
      this.sponsor,
      this.liquidityPoolId);

  /// Returns the Asset object for this balance.
  ///
  /// Converts the balance's asset type, code, and issuer fields into an Asset instance.
  /// Returns AssetTypeNative for native XLM, or a credit asset for other asset types.
  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
      json['asset_type'],
      json['asset_code'],
      json['asset_issuer'],
      json['balance'],
      json['limit'],
      json['buying_liabilities'],
      json['selling_liabilities'],
      json['is_authorized'],
      json['is_authorized_to_maintain_liabilities'],
      json['is_clawback_enabled'],
      convertInt(json['last_modified_ledger']),
      json['last_modified_time'],
      json['sponsor'],
      json['liquidity_pool_id']);
}

/// Represents a signer authorized to sign transactions for an account.
///
/// Stellar accounts use a multi-signature system where multiple signers can be
/// configured, each with a weight. Transaction operations require threshold
/// levels (low, medium, high) to be met by summing the weights of signers.
///
/// Signer types include:
/// - ed25519_public_key: Standard account public key signer
/// - sha256_hash: Hash(x) signer for pre-image revelation
/// - preauth_tx: Pre-authorized transaction hash signer
///
/// The master key is always present as a signer with type ed25519_public_key.
/// When the master weight is 0, the account cannot use its original keypair.
///
/// See also:
/// - [AccountResponse] for the parent account details
/// - [Stellar developer docs](https://developers.stellar.org)
class Signer {
  /// Signer public key, hash, or transaction hash (format depends on type).
  String key;

  /// Signer type (ed25519_public_key, sha256_hash, or preauth_tx).
  String type;

  /// Signing weight (0-255) for multi-signature threshold calculation.
  int weight;
  String? sponsor;

  /// Creates a Signer instance from Horizon API data.
  ///
  /// Parameters:
  /// - [key]: Signer public key or hash
  /// - [type]: Signer type (ed25519_public_key, sha256_hash, preauth_tx)
  /// - [weight]: Signing weight (0-255)
  /// - [sponsor]: Optional sponsor account ID
  Signer(this.key, this.type, this.weight, this.sponsor);

  String? get accountId => key;

  factory Signer.fromJson(Map<String, dynamic> json) => Signer(
      json['key'], json['type'], convertInt(json['weight'])!, json['sponsor']);
}

/// Container for account data entries attached to an account.
///
/// Provides access to the data entries (key-value pairs) stored on-chain
/// for an account. Each entry consists of a key (up to 64 bytes) and a
/// base64-encoded value (up to 64 bytes). Accounts can have up to 1000
/// data entries.
///
/// This class provides convenient access methods:
/// - Use bracket notation to get base64-encoded values
/// - Use getDecoded() to get raw byte data
/// - Use keys property to iterate over all data entry keys
/// - Use length to check the number of data entries
///
/// See also:
/// - [AccountResponse] for the parent account details
/// - [AccountDataResponse] for individual data entry responses
class AccountResponseData {
  Map<String, dynamic> _map = {};

  /// Creates an AccountResponseData container from Horizon API data.
  ///
  /// Parameters:
  /// - [_map]: Map of data entry keys to base64-encoded values
  AccountResponseData(this._map);

  int get length => _map.length;

  Iterable<String> get keys => _map.keys;

  /// Gets base64-encoded value for a given [key].
  String operator [](Object key) => _map[key] as String;

  /// Gets raw value for a given [key].
  Uint8List getDecoded(String key) => base64Decode(this[key]);
}

/// HAL links for navigating related account resources.
///
/// Provides hypermedia links to related Horizon API endpoints for an account.
/// These links follow the HAL (Hypertext Application Language) standard and
/// enable navigation to:
/// - effects: Effects created by this account's operations
/// - offers: Active offers created by this account
/// - operations: Operations performed by or on this account
/// - self: This account's details endpoint
/// - transactions: Transactions involving this account
/// - payments: Payment operations for this account
/// - trades: Trades executed by this account
/// - data: Data entries attached to this account
///
/// See also:
/// - [AccountResponse] for the parent account details
/// - [Link] for link structure details
class AccountResponseLinks {
  /// Link to effects created by this account's operations.
  Link effects;

  /// Link to active offers created by this account.
  Link offers;

  /// Link to operations performed by or on this account.
  Link operations;

  /// Link to this account's details endpoint.
  Link self;

  /// Link to transactions involving this account.
  Link transactions;

  /// Link to payment operations for this account.
  Link payments;

  /// Link to trades executed by this account.
  Link trades;

  /// Link to data entries attached to this account.
  Link data;

  /// Creates an AccountResponseLinks from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing JSON responses
  /// from Horizon API endpoints.
  ///
  /// Parameters:
  /// - [effects] Link to effects created by this account
  /// - [offers] Link to active offers by this account
  /// - [operations] Link to operations for this account
  /// - [self] Link to this account's details
  /// - [transactions] Link to transactions involving this account
  /// - [payments] Link to payment operations for this account
  /// - [trades] Link to trades executed by this account
  /// - [data] Link to data entries attached to this account
  AccountResponseLinks(this.effects, this.offers, this.operations, this.self,
      this.transactions, this.payments, this.trades, this.data);

  factory AccountResponseLinks.fromJson(Map<String, dynamic> json) {
    return AccountResponseLinks(
        Link.fromJson(json['effects']),
        Link.fromJson(json['offers']),
        Link.fromJson(json['operations']),
        Link.fromJson(json['self']),
        Link.fromJson(json['transactions']),
        Link.fromJson(json['payments']),
        Link.fromJson(json['trades']),
        Link.fromJson(json['data']));
  }
}
