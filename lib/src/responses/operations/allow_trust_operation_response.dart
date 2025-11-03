// Copyright 2024 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'operation_responses.dart';
import '../../assets.dart';
import '../transaction_response.dart';

/// Represents an allow trust operation response from Horizon.
///
/// An allow trust operation authorizes or deauthorizes another account to hold
/// an asset issued by the source account. This operation is deprecated as of
/// Protocol 17. Use SetTrustLineFlagsOperation instead.
///
/// Returned by: Horizon API operations endpoint when querying allow trust operations
///
/// Fields:
/// - [trustor]: Account holding the asset (the account being authorized/deauthorized)
/// - [trustee]: Account issuing the asset and granting/revoking authorization (source account)
/// - [trusteeMuxed]: Muxed account representation of the trustee (if applicable)
/// - [trusteeMuxedId]: Muxed account ID of the trustee (if applicable)
/// - [assetType]: Type of asset ('credit_alphanum4' or 'credit_alphanum12')
/// - [assetCode]: Code of the asset being authorized
/// - [assetIssuer]: Issuer account ID of the asset
/// - [authorize]: Whether the trustline is fully authorized
/// - [authorizeToMaintainLiabilities]: Whether the trustline can maintain but not increase liabilities
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('issuer_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is AllowTrustOperationResponse) {
///     print('Trustor: ${op.trustor}');
///     print('Asset: ${op.assetCode}');
///     print('Authorized: ${op.authorize}');
///   }
/// }
/// ```
///
/// See also:
/// - [AllowTrustOperation] for creating allow trust operations (deprecated)
/// - [SetTrustLineFlagsOperation] for the preferred alternative
/// - [Horizon Allow Trust](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/allow-trust)
class AllowTrustOperationResponse extends OperationResponse {
  /// Account holding the asset (the account being authorized/deauthorized)
  String trustor;

  /// Account issuing the asset and granting/revoking authorization (source account)
  String trustee;

  /// Muxed account representation of the trustee (if applicable)
  String? trusteeMuxed;

  /// Muxed account ID of the trustee (if applicable)
  String? trusteeMuxedId;

  /// Type of asset ('credit_alphanum4' or 'credit_alphanum12')
  String assetType;

  /// Code of the asset being authorized
  String assetCode;

  /// Issuer account ID of the asset
  String assetIssuer;

  /// Whether the trustline is fully authorized
  bool authorize;

  /// Whether the trustline can maintain but not increase liabilities
  bool authorizeToMaintainLiabilities;

  AllowTrustOperationResponse(
      this.authorize,
      this.authorizeToMaintainLiabilities,
      this.assetIssuer,
      this.assetCode,
      this.assetType,
      this.trustee,
      this.trusteeMuxed,
      this.trusteeMuxedId,
      this.trustor,
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
  /// Returns an [AssetTypeCreditAlphaNum] for the asset being authorized.
  Asset get asset {
    return Asset.createNonNativeAsset(assetCode, assetIssuer);
  }

  factory AllowTrustOperationResponse.fromJson(Map<String, dynamic> json) =>
      AllowTrustOperationResponse(
          json['authorize'],
          json['authorize_to_maintain_liabilities'],
          json['asset_issuer'],
          json['asset_code'],
          json['asset_type'],
          json['trustee'],
          json['trustee_muxed'],
          json['trustee_muxed_id'],
          json['trustor'],
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
