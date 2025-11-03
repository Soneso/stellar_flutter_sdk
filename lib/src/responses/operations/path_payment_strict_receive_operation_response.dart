// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../../asset_type_native.dart';
import '../transaction_response.dart';

/// Represents a path payment strict receive operation response from Horizon.
///
/// A path payment strict receive operation sends an amount of a specific asset to a
/// destination account through a path of offers, specifying the exact amount to be
/// received. The source amount varies based on the path taken.
///
/// Returned by: Horizon API operations endpoint when querying path payment strict receive operations
///
/// Fields:
/// - [amount]: The amount of destination asset received (exact, as specified in the operation)
/// - [sourceAmount]: The actual amount of source asset sent (determined by the path)
/// - [sourceMax]: The maximum amount of source asset the sender was willing to send
/// - [from]: Source account ID that sent the payment
/// - [to]: Destination account ID that received the payment
/// - [fromMuxed]: Muxed account representation of the sender (if applicable)
/// - [fromMuxedId]: Muxed account ID of the sender (if applicable)
/// - [toMuxed]: Muxed account representation of the recipient (if applicable)
/// - [toMuxedId]: Muxed account ID of the recipient (if applicable)
/// - [assetType]: Type of destination asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
/// - [assetCode]: Destination asset code (null for native XLM)
/// - [assetIssuer]: Destination asset issuer account ID (null for native XLM)
/// - [sourceAssetType]: Type of source asset
/// - [sourceAssetCode]: Source asset code (null for native XLM)
/// - [sourceAssetIssuer]: Source asset issuer account ID (null for native XLM)
/// - [path]: Array of assets that define the conversion path from source to destination asset
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is PathPaymentStrictReceiveOperationResponse) {
///     print('Path payment: ${op.sourceAmount} ${op.sourceAsset.code} -> ${op.amount} ${op.asset.code}');
///     print('Path length: ${op.path.length}');
///     print('From: ${op.from} to: ${op.to}');
///   }
/// }
/// ```
///
/// See also:
/// - [PathPaymentStrictReceiveOperation] for creating path payment operations
/// - [Horizon Path Payment Strict Receive](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/path-payment-strict-receive)
class PathPaymentStrictReceiveOperationResponse extends OperationResponse {
  /// The amount of destination asset received (exact, as specified in the operation)
  String amount;

  /// The actual amount of source asset sent (determined by the path)
  String? sourceAmount;

  /// The maximum amount of source asset the sender was willing to send
  String? sourceMax;

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
  String assetType;

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

  PathPaymentStrictReceiveOperationResponse(
      this.amount,
      this.sourceAmount,
      this.sourceMax,
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

  factory PathPaymentStrictReceiveOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      PathPaymentStrictReceiveOperationResponse(
          json['amount'],
          json['source_amount'],
          json['source_max'],
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
