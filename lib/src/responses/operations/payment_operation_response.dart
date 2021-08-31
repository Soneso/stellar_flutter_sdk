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
  String? assetCode;
  String? assetIssuer;
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
      return AssetTypeNative();
    } else {
      return Asset.createNonNativeAsset(assetCode!, assetIssuer!);
    }
  }

  factory PaymentOperationResponse.fromJson(Map<String, dynamic> json) => PaymentOperationResponse(
      json['amount'],
      json['asset_type'],
      json['asset_code'],
      json['asset_issuer'],
      json['from'] == null ? null : KeyPair.fromAccountId(json['from']),
      json['from_muxed'] == null ? null : json['from_muxed'],
      json['from_muxed_id'] == null ? null : json['from_muxed_id'],
      json['to'] == null ? null : KeyPair.fromAccountId(json['to']),
      json['to_muxed'] == null ? null : json['to_muxed'],
      json['to_muxed_id'] == null ? null : json['to_muxed_id'])
    ..id = int.tryParse(json['id'])
    ..sourceAccount = json['source_account'] == null ? null : json['source_account']
    ..sourceAccountMuxed =
        json['source_account_muxed'] == null ? null : json['source_account_muxed']
    ..sourceAccountMuxedId =
        json['source_account_muxed_id'] == null ? null : json['source_account_muxed_id']
    ..pagingToken = json['paging_token']
    ..createdAt = json['created_at']
    ..transactionHash = json['transaction_hash']
    ..transactionSuccessful = json['transaction_successful']
    ..type = json['type']
    ..links = json['_links'] == null ? null : OperationResponseLinks.fromJson(json['_links']);
}
