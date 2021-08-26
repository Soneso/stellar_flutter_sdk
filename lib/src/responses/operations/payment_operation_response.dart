import '../../assets.dart';
import '../../asset_type_native.dart';
import '../../key_pair.dart';
import 'operation_responses.dart';
import '../response.dart';

/// Represents Payment operation response.
/// See: <a href="https://developers.stellar.org/api/resources/operations/" target="_blank">Operation documentation</a>
class PaymentOperationResponse extends OperationResponse {
  String? amount;
  String? assetType;
  String assetCode;
  String assetIssuer;
  KeyPair? from;
  KeyPair? to;
  String? fromMuxed;
  String? fromMuxedId;
  String? toMuxed;
  String? toMuxedId;

  PaymentOperationResponse(this.amount, this.assetType, this.assetCode, this.assetIssuer, this.from,
      this.fromMuxed, this.fromMuxedId, this.to, this.toMuxed, this.toMuxedId);

  Asset get asset {
    if (assetType == Asset.TYPE_NATIVE) {
      return new AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode, assetIssuer);
    }
  }

  factory PaymentOperationResponse.fromJson(Map<String, dynamic> json) =>
      new PaymentOperationResponse(
          json['amount'] as String,
          json['asset_type'] as String,
          json['asset_code'] as String,
          json['asset_issuer'] as String,
          json['from'] == null ? null : KeyPair.fromAccountId(json['from'] as String),
          json['from_muxed'] == null ? null : json['from_muxed'],
          json['from_muxed_id'] == null ? null : json['from_muxed_id'] as String,
          json['to'] == null ? null : KeyPair.fromAccountId(json['to'] as String),
          json['to_muxed'] == null ? null : json['to_muxed'],
          json['to_muxed_id'] == null ? null : json['to_muxed_id'] as String)
        ..id = int.parse(json['id'] as String)
        ..sourceAccount = json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed =
            json['source_account_muxed'] == null ? null : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : json['source_account_muxed_id'] as String
        ..pagingToken = json['paging_token'] as String
        ..createdAt = json['created_at'] as String
        ..transactionHash = json['transaction_hash'] as String
        ..transactionSuccessful = json['transaction_successful'] as bool
        ..type = json['type'] as String
        ..links = json['_links'] == null
            ? null
            : new OperationResponseLinks.fromJson(json['_links'] as Map<String, dynamic>);
}
