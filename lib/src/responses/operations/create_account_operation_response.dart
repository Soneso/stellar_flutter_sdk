// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents a create account operation response from Horizon.
///
/// Creates a new Stellar account with a minimum starting balance. This is the
/// first step to onboard a new user to the Stellar network. The funder's account
/// must provide the minimum reserve (currently 1 XLM) to activate the new account.
///
/// Use cases:
/// - Onboarding new users to the Stellar network
/// - Creating escrow or temporary accounts
/// - Setting up multi-signature account hierarchies
///
/// Fields:
/// - [account]: The newly created account ID
/// - [funder]: Account that funded the creation
/// - [funderMuxed]: Muxed account address of funder if applicable
/// - [funderMuxedId]: Muxed account sub-account ID of funder
/// - [startingBalance]: Initial balance provided in lumens (XLM)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('funder_account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is CreateAccountOperationResponse) {
///     print('Created account: ${op.account}');
///     print('Funded by: ${op.funder}');
///     print('Starting balance: ${op.startingBalance} XLM');
///
///     // Handle muxed accounts if applicable
///     if (op.funderMuxed != null) {
///       print('Funder muxed: ${op.funderMuxed}');
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [CreateAccountOperation] for creating account operations
/// - [Stellar developer docs](https://developers.stellar.org)
class CreateAccountOperationResponse extends OperationResponse {
  /// The account ID that was created
  String account;

  /// Account that funded the new account
  String funder;

  /// Muxed account address of funder if applicable
  String? funderMuxed;

  /// Muxed account sub-account ID of funder
  String? funderMuxedId;

  /// Initial balance provided in lumens (XLM)
  String startingBalance;

  /// Creates a CreateAccountOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [funder]: Account that funded the new account
  /// - [funderMuxed]: Muxed funder account (if applicable)
  /// - [funderMuxedId]: Muxed funder account ID (if applicable)
  /// - [startingBalance]: Initial balance provided in lumens
  /// - [account]: The newly created account ID
  /// - [links]: Hypermedia links to related resources
  /// - [id]: Unique operation identifier
  /// - [pagingToken]: Pagination cursor
  /// - [transactionSuccessful]: Whether the parent transaction succeeded
  /// - [sourceAccount]: Operation source account ID
  /// - [sourceAccountMuxed]: Muxed source account (if applicable)
  /// - [sourceAccountMuxedId]: Muxed source account ID (if applicable)
  /// - [type]: Operation type name
  /// - [type_i]: Operation type as integer
  /// - [createdAt]: Creation timestamp
  /// - [transactionHash]: Parent transaction hash
  /// - [transaction]: Full parent transaction
  /// - [sponsor]: Account sponsoring the operation (if applicable)
  CreateAccountOperationResponse(
      this.funder,
      this.funderMuxed,
      this.funderMuxedId,
      this.startingBalance,
      this.account,
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

  /// Deserializes a create account operation response from JSON.
  factory CreateAccountOperationResponse.fromJson(Map<String, dynamic> json) =>
      CreateAccountOperationResponse(
          json['funder'],
          json['funder_muxed'],
          json['funder_muxed_id'],
          json['starting_balance'],
          json['account'],
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
