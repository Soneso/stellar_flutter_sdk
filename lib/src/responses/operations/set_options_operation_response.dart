// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../transaction_response.dart';
import '../response.dart';
import 'operation_responses.dart';

/// Represents a set options operation response from Horizon.
///
/// A set options operation sets various account configuration options including
/// thresholds, signers, home domain, and account flags.
///
/// Returned by: Horizon API operations endpoint when querying set options operations
///
/// Fields:
/// - [lowThreshold]: New low threshold for the account (0-255), null if unchanged
/// - [medThreshold]: New medium threshold for the account (0-255), null if unchanged
/// - [highThreshold]: New high threshold for the account (0-255), null if unchanged
/// - [inflationDestination]: Account to receive inflation, null if unchanged (deprecated)
/// - [homeDomain]: Account's home domain, null if unchanged
/// - [signerKey]: Public key of signer being added/modified, null if no signer change
/// - [signerWeight]: Weight of the signer (0 to remove), null if no signer change
/// - [masterKeyWeight]: New weight for master key (0-255), null if unchanged
/// - [clearFlags]: Human-readable names of flags being cleared
/// - [setFlags]: Human-readable names of flags being set
/// - [clearFlagsInt]: Integer values of flags being cleared
/// - [setFlagsInt]: Integer values of flags being set
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is SetOptionsOperationResponse) {
///     if (op.homeDomain != null) print('Home domain: ${op.homeDomain}');
///     if (op.signerKey != null) print('Signer: ${op.signerKey} (weight: ${op.signerWeight})');
///     if (op.setFlags != null) print('Set flags: ${op.setFlags}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetOptionsOperation] for creating set options operations
/// - [Horizon Set Options](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/set-options)
class SetOptionsOperationResponse extends OperationResponse {
  /// New low threshold for the account (0-255), null if unchanged
  int? lowThreshold;

  /// New medium threshold for the account (0-255), null if unchanged
  int? medThreshold;

  /// New high threshold for the account (0-255), null if unchanged
  int? highThreshold;

  /// Account to receive inflation, null if unchanged (deprecated)
  String? inflationDestination;

  /// Account's home domain, null if unchanged
  String? homeDomain;

  /// Public key of signer being added/modified, null if no signer change
  String? signerKey;

  /// Weight of the signer (0 to remove), null if no signer change
  int? signerWeight;

  /// New weight for master key (0-255), null if unchanged
  int? masterKeyWeight;

  /// Human-readable names of flags being cleared
  List<String>? clearFlags;

  /// Human-readable names of flags being set
  List<String>? setFlags;

  /// Integer values of flags being cleared
  List<int>? clearFlagsInt;

  /// Integer values of flags being set
  List<int>? setFlagsInt;

  SetOptionsOperationResponse(
      this.lowThreshold,
      this.medThreshold,
      this.highThreshold,
      this.inflationDestination,
      this.homeDomain,
      this.signerKey,
      this.signerWeight,
      this.masterKeyWeight,
      this.clearFlags,
      this.setFlags,
      this.clearFlagsInt,
      this.setFlagsInt,
      super.links,
      super.id,
      super.pagingToken,
      super.transactionSuccessful,
      super.sourceAccount,
      super.sourceAccountMuxed,
      super.sourceAccountMuxedId,
      super.type,
      super.type_i,
      super.createdAt,
      super.transactionHash,
      super.transaction,
      super.sponsor);

  /// Alias for [signerKey] for backward compatibility
  String? get signer {
    return signerKey;
  }

  factory SetOptionsOperationResponse.fromJson(Map<String, dynamic> json) =>
      SetOptionsOperationResponse(
          convertInt(json['low_threshold']),
          convertInt(json['med_threshold']),
          convertInt(json['high_threshold']),
          json['inflation_dest'],
          json['home_domain'],
          json['signer_key'],
          convertInt(json['signer_weight']),
          convertInt(json['master_key_weight']),
          json['clear_flags_s'] != null
              ? List<String>.from(json['clear_flags_s'].map((e) => e))
              : null,
          json['set_flags_s'] != null
              ? List<String>.from(json['set_flags_s'].map((e) => e))
              : null,
          json['clear_flags'] != null
              ? List<int>.from(json['clear_flags'].map((e) => e))
              : null,
          json['set_flags'] != null
              ? List<int>.from(json['set_flags'].map((e) => e))
              : null,
          OperationResponseLinks.fromJson(json['_links']),
          json['id'],
          json['paging_token'],
          json['transaction_successful'],
          json['source_account'],
          json['source_account_muxed'],
          json['source_account_muxed_id'],
          json['type'],
          json['type_i'],
          json['created_at'],
          json['transaction_hash'],
          json['transaction'] == null
              ? null
              : TransactionResponse.fromJson(json['transaction']),
          json['sponsor']);
}
