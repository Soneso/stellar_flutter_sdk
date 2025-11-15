// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents a set trustline flags operation response from Horizon.
///
/// This operation sets or clears trustline authorization flags on a trustline.
/// It replaces the deprecated AllowTrustOperation and provides more granular control
/// over trustline authorization states.
///
/// Returned by: Horizon API operations endpoint when querying set trustline flags operations
///
/// Fields:
/// - [trustor]: Account holding the trustline being modified
/// - [assetType]: Type of asset ('credit_alphanum4' or 'credit_alphanum12')
/// - [assetCode]: Code of the asset
/// - [assetIssuer]: Issuer account ID of the asset (source account)
/// - [clearFlags]: Human-readable names of flags being cleared
/// - [setFlags]: Human-readable names of flags being set
/// - [clearFlagsInt]: Integer values of flags being cleared
/// - [setFlagsInt]: Integer values of flags being set
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('issuer_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is SetTrustlineFlagsOperationResponse) {
///     print('Trustor: ${op.trustor}');
///     if (op.setFlags != null) print('Set flags: ${op.setFlags}');
///     if (op.clearFlags != null) print('Clear flags: ${op.clearFlags}');
///   }
/// }
/// ```
///
/// See also:
/// - [SetTrustLineFlagsOperation] for creating set trustline flags operations
/// - [Stellar developer docs](https://developers.stellar.org)
class SetTrustlineFlagsOperationResponse extends OperationResponse {
  /// Account holding the trustline being modified
  String trustor;

  /// Type of asset ('credit_alphanum4' or 'credit_alphanum12')
  String assetType;

  /// Code of the asset
  String? assetCode;

  /// Issuer account ID of the asset (source account)
  String? assetIssuer;

  /// Human-readable names of flags being cleared
  List<String>? clearFlags;

  /// Human-readable names of flags being set
  List<String>? setFlags;

  /// Integer values of flags being cleared
  List<int>? clearFlagsInt;

  /// Integer values of flags being set
  List<int>? setFlagsInt;

  /// Creates a SetTrustlineFlagsOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [trustor] Account holding the trustline being modified
  /// - [assetType] Type of asset
  /// - [assetCode] Code of the asset
  /// - [assetIssuer] Issuer account ID of the asset
  /// - [clearFlags] Human-readable names of flags being cleared
  /// - [setFlags] Human-readable names of flags being set
  /// - [clearFlagsInt] Integer values of flags being cleared
  /// - [setFlagsInt] Integer values of flags being set
  /// - [links] Hypermedia links to related resources
  /// - [id] Unique operation identifier
  /// - [pagingToken] Pagination cursor
  /// - [transactionSuccessful] Whether the parent transaction succeeded
  /// - [sourceAccount] Operation source account ID
  /// - [sourceAccountMuxed] Muxed source account (if applicable)
  /// - [sourceAccountMuxedId] Muxed source account ID (if applicable)
  /// - [type] Operation type name
  /// - [type_i] Operation type as integer
  /// - [createdAt] Creation timestamp
  /// - [transactionHash] Parent transaction hash
  /// - [transaction] Full parent transaction
  /// - [sponsor] Account sponsoring the operation (if applicable)
  SetTrustlineFlagsOperationResponse(
      this.trustor,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
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

  /// Deserializes a set trustline flags operation response from JSON.
  ///
  /// Converts a JSON map from the Horizon API into a SetTrustlineFlagsOperationResponse object.
  factory SetTrustlineFlagsOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      SetTrustlineFlagsOperationResponse(
          json['trustor'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
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
