// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../transaction_response.dart';

/// Represents a path payment strict send operation response from Horizon.
///
/// A path payment strict send operation sends a specific amount of an asset from a
/// source account through a path of offers to a destination account. The exact amount
/// sent is specified, while the destination amount varies based on the path taken.
///
/// Returned by: Horizon API operations endpoint when querying path payment strict send operations
///
/// Fields:
/// - [amount] The actual amount of destination asset received (determined by the path)
/// - [sourceAmount] The exact amount of source asset sent (as specified in the operation)
/// - [destinationMin] The minimum amount of destination asset the sender required to be received
/// - [from] Source account ID that sent the payment
/// - [to] Destination account ID that received the payment
/// - [fromMuxed] Muxed account representation of the sender (if applicable)
/// - [fromMuxedId] Muxed account ID of the sender (if applicable)
/// - [toMuxed] Muxed account representation of the recipient (if applicable)
/// - [toMuxedId] Muxed account ID of the recipient (if applicable)
/// - [assetType] Type of destination asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
/// - [assetCode] Destination asset code (null for native XLM)
/// - [assetIssuer] Destination asset issuer account ID (null for native XLM)
/// - [sourceAssetType] Type of source asset
/// - [sourceAssetCode] Source asset code (null for native XLM)
/// - [sourceAssetIssuer] Source asset issuer account ID (null for native XLM)
/// - [path] Array of assets that define the conversion path from source to destination asset
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is PathPaymentStrictSendOperationResponse) {
///     print('Path payment: ${op.sourceAmount} ${op.sourceAsset.code} -> ${op.amount} ${op.asset.code}');
///     print('Min destination: ${op.destinationMin}');
///     print('From: ${op.from} to: ${op.to}');
///   }
/// }
/// ```
///
/// See also:
/// - [PathPaymentStrictSendOperation] for creating path payment operations
/// - [Stellar developer docs](https://developers.stellar.org)
class PathPaymentStrictSendOperationResponse extends OperationResponse {
  /// The actual amount of destination asset received (determined by the path)
  String amount;

  /// The exact amount of source asset sent (as specified in the operation)
  String sourceAmount;

  /// The minimum amount of destination asset the sender required to be received
  String destinationMin;

  /// Source account ID that sent the payment
  String from;

  /// Destination account ID that received the payment
  String to;

  /// Muxed account representation of the sender (if applicable)
  String? fromMuxed;

  /// Muxed account ID of the sender (if applicable)
  String? fromMuxedId;

  /// Muxed account representation of the recipient (if applicable)
  String? toMuxed;

  /// Muxed account ID of the recipient (if applicable)
  String? toMuxedId;

  /// Type of destination asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String? assetType;

  /// Destination asset code (null for native XLM)
  String? assetCode;

  /// Destination asset issuer account ID (null for native XLM)
  String? assetIssuer;

  /// Type of source asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String sourceAssetType;

  /// Source asset code (null for native XLM)
  String? sourceAssetCode;

  /// Source asset issuer account ID (null for native XLM)
  String? sourceAssetIssuer;

  /// Array of assets that define the conversion path from source to destination asset
  List<Asset> path;

  /// Creates a PathPaymentStrictSendOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
  /// - [amount] The actual amount of destination asset received
  /// - [sourceAmount] The exact amount of source asset sent
  /// - [destinationMin] The minimum destination amount required
  /// - [from] Source account ID
  /// - [fromMuxed] Muxed from account (if applicable)
  /// - [fromMuxedId] Muxed from account ID (if applicable)
  /// - [to] Destination account ID
  /// - [toMuxed] Muxed to account (if applicable)
  /// - [toMuxedId] Muxed to account ID (if applicable)
  /// - [assetType] Type of destination asset
  /// - [assetCode] Destination asset code (null for XLM)
  /// - [assetIssuer] Destination asset issuer (null for XLM)
  /// - [sourceAssetType] Type of source asset
  /// - [sourceAssetCode] Source asset code (null for XLM)
  /// - [sourceAssetIssuer] Source asset issuer (null for XLM)
  /// - [path] Conversion path from source to destination
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
  PathPaymentStrictSendOperationResponse(
      this.amount,
      this.sourceAmount,
      this.destinationMin,
      this.from,
      this.fromMuxed,
      this.fromMuxedId,
      this.to,
      this.toMuxed,
      this.toMuxedId,
      this.assetType,
      this.assetCode,
      this.assetIssuer,
      this.sourceAssetType,
      this.sourceAssetCode,
      this.sourceAssetIssuer,
      this.path,
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

  /// Convenience getter to retrieve the destination asset as an [Asset] object.
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

  /// Convenience getter to retrieve the source asset as an [Asset] object.
  ///
  /// Returns either an [AssetTypeNative] for XLM or an [AssetTypeCreditAlphaNum]
  /// for issued assets.
  Asset get sourceAsset {
    if (sourceAssetType == Asset.TYPE_NATIVE) {
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(sourceAssetCode!, sourceAssetIssuer!);
    }
  }

  factory PathPaymentStrictSendOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      PathPaymentStrictSendOperationResponse(
          json['amount'],
          json['source_amount'],
          json['destination_min'],
          json['from'],
          json['from_muxed'],
          json['from_muxed_id'],
          json['to'],
          json['to_muxed'],
          json['to_muxed_id'],
          json['asset_type'],
          json['asset_code'],
          json['asset_issuer'],
          json['source_asset_type'],
          json['source_asset_code'],
          json['source_asset_issuer'],
          List<Asset>.from(json['path'].map((e) => Asset.fromJson(e))),
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
