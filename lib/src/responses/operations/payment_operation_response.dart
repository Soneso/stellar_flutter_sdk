// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../assets.dart';
import '../../asset_type_native.dart';
import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents a payment operation response from Horizon.
///
/// A payment operation sends a specific amount of an asset from one account to another.
/// This is the most common operation type on the Stellar network.
///
/// Fields:
/// - [amount]: Amount of the asset sent (as string to preserve precision)
/// - [assetType]: Type of asset ('native' for XLM, 'credit_alphanum4' or 'credit_alphanum12' for others)
/// - [assetCode]: Asset code (null for native XLM)
/// - [assetIssuer]: Asset issuer account ID (null for native XLM)
/// - [from]: Source account ID of the payment
/// - [to]: Destination account ID of the payment
/// - [fromMuxed]: Muxed account representation of the sender (if applicable)
/// - [fromMuxedId]: Muxed account ID of the sender (if applicable)
/// - [toMuxed]: Muxed account representation of the recipient (if applicable)
/// - [toMuxedId]: Muxed account ID of the recipient (if applicable)
///
/// Example:
/// ```dart
/// final operations = await sdk.operations.forAccount('account_id').execute();
/// for (var op in operations.records) {
///   if (op is PaymentOperationResponse) {
///     print('Payment: ${op.amount} ${op.assetCode ?? 'XLM'} from ${op.from} to ${op.to}');
///   }
/// }
/// ```
///
/// See also:
/// - [Stellar developer docs](https://developers.stellar.org)
/// - [PaymentOperation] for creating payment operations
class PaymentOperationResponse extends OperationResponse {
  /// Amount of the asset sent (as string to preserve precision)
  String amount;

  /// Type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
  String? assetCode;

  /// Asset issuer account ID, null for native XLM
  String? assetIssuer;

  /// Source account ID of the payment
  String from;

  /// Destination account ID of the payment
  String to;

  /// Muxed account representation of the sender (if applicable)
  String? fromMuxed;

  /// Muxed account ID of the sender (if applicable)
  String? fromMuxedId;

  /// Muxed account representation of the recipient (if applicable)
  String? toMuxed;

  /// Muxed account ID of the recipient (if applicable)
  String? toMuxedId;

  /// Creates a PaymentOperationResponse with all payment details and parent operation fields.
  PaymentOperationResponse(
      this.amount,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.from,
      this.fromMuxed,
      this.fromMuxedId,
      this.to,
      this.toMuxed,
      this.toMuxedId,
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

  /// Convenience getter to retrieve the asset as an [Asset] object.
  ///
  /// Returns either an [AssetTypeNative] for XLM or an [AssetTypeCreditAlphaNum]
  /// for issued assets.
  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  /// Constructs a PaymentOperationResponse from JSON returned by Horizon API.
  factory PaymentOperationResponse.fromJson(Map<String, dynamic> json) =>
      PaymentOperationResponse(
          json['amount'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['from'],
          json['from_muxed'],
          json['from_muxed_id'],
          json['to'],
          json['to_muxed'],
          json['to_muxed_id'],
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
