// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../assets.dart';
import 'response.dart';

/// Represents a claimable balance in the Stellar network.
///
/// Claimable balances are a mechanism for making conditional payments on Stellar.
/// They allow an account to create a balance that can only be claimed by specified
/// recipient accounts under predefined conditions. This enables use cases such as:
///
/// - Time-locked transfers: Funds that become available at a specific time
/// - Conditional payments: Payments that can only be claimed if certain conditions are met
/// - Escrow-like functionality: Funds held until specific criteria are satisfied
/// - Pre-authorized payments: Payments that can be claimed without the sender being online
///
/// A claimable balance consists of an asset amount held on the ledger along with
/// a list of claimants who may claim it. Each claimant has a predicate that must
/// evaluate to true before they can claim the balance. Once claimed, the balance
/// is transferred to the claimant's account and removed from the ledger.
///
/// Example:
/// ```dart
/// // Query claimable balances for an account
/// var balances = await sdk.claimableBalances
///     .forClaimant(accountId)
///     .limit(10)
///     .execute();
///
/// for (var balance in balances.records) {
///   print('Balance ID: ${balance.balanceId}');
///   print('Asset: ${balance.asset.code ?? 'XLM'}');
///   print('Amount: ${balance.amount}');
///   print('Sponsor: ${balance.sponsor}');
///
///   // Check claimants
///   for (var claimant in balance.claimants) {
///     print('Claimant: ${claimant.destination}');
///     if (claimant.predicate.unconditional == true) {
///       print('Can claim immediately');
///     } else if (claimant.predicate.beforeAbsoluteTime != null) {
///       print('Can claim before: ${claimant.predicate.beforeAbsoluteTime}');
///     }
///   }
/// }
///
/// // Claim a balance
/// var claimOp = ClaimClaimableBalanceOperation(balanceId: balance.balanceId);
/// var transaction = TransactionBuilder(sourceAccount)
///     .addOperation(claimOp)
///     .build();
/// transaction.sign(sourceKeyPair, network);
/// await sdk.submitTransaction(transaction);
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org) for API details
/// - [ClaimantResponse] for information about who can claim the balance
/// - [ClaimantPredicateResponse] for claim conditions
/// - [ClaimableBalanceFlags] for balance flags
class ClaimableBalanceResponse extends Response {
  /// Unique identifier for this claimable balance.
  ///
  /// This ID is used when claiming the balance or querying for its details.
  String balanceId;

  /// The asset held by this claimable balance.
  Asset asset;

  /// The amount of the asset held in this claimable balance.
  ///
  /// This is a string representation of the amount with up to 7 decimal places.
  String amount;

  /// The account sponsoring the base reserve for this claimable balance.
  ///
  /// Claimable balances require a base reserve. If sponsored, this field
  /// contains the account ID of the sponsor. Otherwise, it is null and the
  /// reserve is paid by the source account that created the balance.
  String? sponsor;

  /// The ledger sequence number when this claimable balance was last modified.
  int lastModifiedLedger;

  /// Timestamp when this claimable balance was last modified.
  ///
  /// This is an ISO 8601 formatted timestamp string.
  String? lastModifiedTime;

  /// List of accounts that can claim this balance and their conditions.
  ///
  /// Each claimant specifies an account ID and a predicate that must be
  /// satisfied for that account to claim the balance.
  List<ClaimantResponse> claimants;

  /// Hypermedia links to related resources.
  ClaimableBalanceResponseLinks links;

  /// Flags indicating the properties of this claimable balance.
  ClaimableBalanceFlags flags;

  /// Creates a ClaimableBalanceResponse from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing
  /// Horizon API responses. Use [StellarSDK.claimableBalances] to query
  /// claimable balance data.
  ClaimableBalanceResponse(
      this.balanceId,
      this.asset,
      this.amount,
      this.sponsor,
      this.lastModifiedLedger,
      this.lastModifiedTime,
      this.claimants,
      this.links,
      this.flags);

  factory ClaimableBalanceResponse.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceResponse(
          json['id'],
          Asset.createFromCanonicalForm(json['asset'])!,
          json['amount'],
          json['sponsor'],
          convertInt(json['last_modified_ledger'])!,
          json['last_modified_time'],
          List<ClaimantResponse>.from(
              json['claimants'].map((e) => ClaimantResponse.fromJson(e))),
          ClaimableBalanceResponseLinks.fromJson(json['_links']),
          ClaimableBalanceFlags.fromJson(json['flags']));
}

/// Flags indicating special properties of a claimable balance.
///
/// These flags control the behavior and capabilities of the claimable balance,
/// particularly regarding asset issuer controls.
class ClaimableBalanceFlags {
  /// Indicates whether the asset issuer can clawback this claimable balance.
  ///
  /// When true, the asset issuer can revoke the claimable balance before it
  /// is claimed, returning the funds to the issuer's account. This flag is
  /// set based on the asset's CLAWBACK_ENABLED flag at the time the claimable
  /// balance was created.
  ///
  /// Clawback is typically used for:
  /// - Regulatory compliance requirements
  /// - Reversing fraudulent transactions
  /// - Asset recovery in special circumstances
  bool clawbackEnabled;

  /// Creates a ClaimableBalanceFlags instance with clawback setting.
  ///
  /// This constructor initializes the flags for a claimable balance, indicating
  /// whether the asset issuer retains the ability to claw back the balance.
  ///
  /// Parameters:
  /// - [clawbackEnabled] Whether the issuer can clawback this balance
  ClaimableBalanceFlags(this.clawbackEnabled);

  factory ClaimableBalanceFlags.fromJson(Map<String, dynamic> json) =>
      ClaimableBalanceFlags(json['clawback_enabled']);
}

/// Represents an account that can claim a claimable balance.
///
/// A claimant specifies both the account ID that is authorized to claim the
/// balance and the predicate conditions that must be satisfied before claiming.
/// Multiple claimants can be defined for a single claimable balance, each with
/// their own conditions.
///
/// Example:
/// ```dart
/// for (var claimant in claimableBalance.claimants) {
///   print('Claimant account: ${claimant.destination}');
///
///   // Check if can claim immediately
///   if (claimant.predicate.unconditional == true) {
///     print('Can claim immediately without conditions');
///   }
///
///   // Check for time-based conditions
///   if (claimant.predicate.beforeAbsoluteTime != null) {
///     print('Can claim before: ${claimant.predicate.beforeAbsoluteTime}');
///   }
///
///   // Check for complex conditions
///   if (claimant.predicate.and != null) {
///     print('Must satisfy all conditions in the AND clause');
///   }
/// }
/// ```
///
/// See also:
/// - [ClaimantPredicateResponse] for the predicate condition details
/// - [ClaimableBalanceResponse] for the parent claimable balance
class ClaimantResponse {
  /// The account ID authorized to claim this claimable balance.
  ///
  /// This is the public key (G-address) of the account that can claim
  /// the balance if the predicate conditions are satisfied.
  String destination;

  /// The predicate conditions that must be satisfied for this claimant to claim.
  ///
  /// The predicate can be unconditional (always true), time-based (before/after
  /// specific times), or complex logical combinations using AND, OR, and NOT.
  ClaimantPredicateResponse predicate;

  /// Creates a ClaimantResponse instance.
  ///
  /// Parameters:
  /// - [destination]: Account ID authorized to claim
  /// - [predicate]: Conditions that must be satisfied to claim
  ClaimantResponse(this.destination, this.predicate);

  factory ClaimantResponse.fromJson(Map<String, dynamic> json) =>
      ClaimantResponse(json['destination'],
          ClaimantPredicateResponse.fromJson(json['predicate']));
}

/// Defines conditions that must be satisfied for a claimant to claim a balance.
///
/// Predicates control when and under what circumstances a claimable balance can
/// be claimed. They can be simple (unconditional or time-based) or complex
/// (combining multiple conditions with logical operators).
///
/// Predicate types:
///
/// 1. Unconditional: Always evaluates to true, balance can be claimed immediately
/// 2. Time-based absolute: Claim before a specific Unix timestamp
/// 3. Time-based relative: Claim before a relative time from balance creation
/// 4. Logical AND: All nested predicates must be true
/// 5. Logical OR: At least one nested predicate must be true
/// 6. Logical NOT: Inverts the nested predicate
///
/// Time-based predicates use Unix epoch timestamps (seconds since 1970-01-01).
/// The relative time predicates are relative to when the claimable balance
/// was created on the ledger.
///
/// Example - Simple unconditional predicate:
/// ```dart
/// if (predicate.unconditional == true) {
///   print('Can claim immediately');
/// }
/// ```
///
/// Example - Time-based predicate:
/// ```dart
/// if (predicate.beforeAbsoluteTime != null) {
///   var deadline = DateTime.parse(predicate.beforeAbsoluteTime!);
///   if (DateTime.now().isBefore(deadline)) {
///     print('Can claim now, deadline: $deadline');
///   } else {
///     print('Claim period has expired');
///   }
/// }
/// ```
///
/// Example - Complex AND predicate:
/// ```dart
/// // Claim must be before a certain time AND after another time
/// if (predicate.and != null) {
///   for (var condition in predicate.and!) {
///     if (condition.beforeAbsoluteTime != null) {
///       print('Must claim before: ${condition.beforeAbsoluteTime}');
///     }
///     if (condition.not?.beforeAbsoluteTime != null) {
///       print('Must claim after: ${condition.not!.beforeAbsoluteTime}');
///     }
///   }
/// }
/// ```
///
/// Example - OR predicate:
/// ```dart
/// // Can claim if ANY condition is met
/// if (predicate.or != null) {
///   print('Can claim if any of these conditions are true:');
///   for (var condition in predicate.or!) {
///     if (condition.unconditional == true) {
///       print('- Immediately');
///     } else if (condition.beforeAbsoluteTime != null) {
///       print('- Before ${condition.beforeAbsoluteTime}');
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [ClaimantResponse] for the claimant that owns this predicate
/// - [ClaimableBalanceResponse] for the parent claimable balance
class ClaimantPredicateResponse {
  /// If true, the predicate always evaluates to true (no conditions).
  ///
  /// When this is true, the claimant can claim the balance immediately
  /// without any time or other restrictions.
  bool? unconditional;

  /// Logical AND: All predicates in this list must evaluate to true.
  ///
  /// Used to combine multiple conditions that must all be satisfied.
  /// For example, can claim after time X AND before time Y.
  List<ClaimantPredicateResponse>? and;

  /// Logical OR: At least one predicate in this list must evaluate to true.
  ///
  /// Used to specify alternative conditions where any one being true
  /// allows claiming. For example, can claim by account A OR account B.
  List<ClaimantPredicateResponse>? or;

  /// Logical NOT: Inverts the nested predicate.
  ///
  /// If the nested predicate is true, this evaluates to false, and vice versa.
  /// Commonly used with time predicates to express "after" conditions.
  /// For example, NOT(before time X) means "after time X".
  ClaimantPredicateResponse? not;

  /// Unix timestamp (ISO 8601 format) before which the balance can be claimed.
  ///
  /// The claim must occur before this absolute time. After this time,
  /// the predicate evaluates to false and the balance cannot be claimed
  /// by this claimant.
  ///
  /// Example: "2024-12-31T23:59:59Z" means can claim until end of 2024.
  String? beforeAbsoluteTime;

  /// Duration in seconds relative to balance creation before which claim must occur.
  ///
  /// The claim must occur within this many seconds after the claimable
  /// balance was created. This is relative to the creation ledger time.
  ///
  /// Example: "86400" means can claim within 24 hours of creation.
  String? beforeRelativeTime;

  /// Creates a ClaimantPredicateResponse instance.
  ///
  /// Parameters:
  /// - [unconditional]: True if always claimable
  /// - [and]: List of predicates that must all be true
  /// - [or]: List of predicates where at least one must be true
  /// - [not]: Inverted predicate
  /// - [beforeAbsoluteTime]: Absolute deadline (ISO 8601 timestamp)
  /// - [beforeRelativeTime]: Relative deadline in seconds
  ClaimantPredicateResponse(this.unconditional, this.and, this.or, this.not,
      this.beforeAbsoluteTime, this.beforeRelativeTime);

  factory ClaimantPredicateResponse.fromJson(Map<String, dynamic> json) =>
      ClaimantPredicateResponse(
          json['unconditional'],
          json['and'] != null
              ? List<ClaimantPredicateResponse>.from(
                  json['and'].map((e) => ClaimantPredicateResponse.fromJson(e)))
              : null,
          json['or'] != null
              ? List<ClaimantPredicateResponse>.from(
                  json['or'].map((e) => ClaimantPredicateResponse.fromJson(e)))
              : null,
          json['not'] == null
              ? null
              : ClaimantPredicateResponse.fromJson(json['not']),
          json['abs_before'],
          json['rel_before']);
}

/// Hypermedia links to related resources for a claimable balance.
///
/// These links follow the HAL (Hypertext Application Language) specification
/// and provide URIs to related Horizon API endpoints for retrieving additional
/// information about the claimable balance.
///
/// Example:
/// ```dart
/// // Access the self link
/// if (claimableBalance.links.self != null) {
///   print('Claimable balance URL: ${claimableBalance.links.self!.href}');
/// }
/// ```
///
/// See also:
/// - [ClaimableBalanceResponse] for the parent response object
/// - [Link] for the link structure details
class ClaimableBalanceResponseLinks {
  /// Link to this specific claimable balance resource.
  ///
  /// This link points to the Horizon API endpoint for retrieving the full
  /// details of this claimable balance.
  Link? self;

  /// Creates a ClaimableBalanceResponseLinks instance.
  ///
  /// Parameters:
  /// - [self]: Link to this claimable balance resource
  ClaimableBalanceResponseLinks(this.self);

  factory ClaimableBalanceResponseLinks.fromJson(Map<String, dynamic> json) {
    return ClaimableBalanceResponseLinks(
        json['self'] == null ? null : Link.fromJson(json['self']));
  }
}
