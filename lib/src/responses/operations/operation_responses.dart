import '../../assets.dart';
import '../../asset_type_native.dart';
import '../../key_pair.dart';
import '../response.dart';
import '../transaction_response.dart';
import 'account_merge_operation_response.dart';
import 'allow_trust_operation_response.dart';
import 'bump_sequence_operation_response.dart';
import 'change_trust_operation_response.dart';
import 'create_account_operation_response.dart';
import 'create_passive_sell_offer_response.dart';
import 'inflation_operation_response.dart';
import 'manage_data_operation_response.dart';
import 'manage_buy_offer_operation_response.dart';
import 'manage_sell_offer_operation_response.dart';
import 'path_payment_strict_receive_operation_response.dart';
import 'path_payment_strict_send_operation_response.dart';

/// Abstract class for operation responses.
/// See: <a href="https://www.stellar.org/developers/horizon/reference/resources/operation.html" target="_blank">Operation documentation</a>
abstract class OperationResponse extends Response {
  int id;
  String sourceAccount;
  String pagingToken;
  String createdAt;
  String transactionHash;
  bool transactionSuccessful;
  String type;
  OperationResponseLinks links;
  TransactionResponse transaction;

  OperationResponse();

  factory OperationResponse.fromJson(Map<String, dynamic> json) {
    int type = convertInt(json["type_i"]);
    switch (type) {
      case 0:
        return CreateAccountOperationResponse.fromJson(json);
      case 1:
        return PaymentOperationResponse.fromJson(json);
      case 2:
        return PathPaymentStrictReceiveOperationResponse.fromJson(json);
      case 3:
        return ManageSellOfferOperationResponse.fromJson(json);
      case 4:
        return CreatePassiveSellOfferOperationResponse.fromJson(json);
      case 5:
        return SetOptionsOperationResponse.fromJson(json);
      case 6:
        return ChangeTrustOperationResponse.fromJson(json);
      case 7:
        return AllowTrustOperationResponse.fromJson(json);
      case 8:
        return AccountMergeOperationResponse.fromJson(json);
      case 9:
        return InflationOperationResponse.fromJson(json);
      case 10:
        return ManageDataOperationResponse.fromJson(json);
      case 11:
        return BumpSequenceOperationResponse.fromJson(json);
      case 12:
        return ManageBuyOfferOperationResponse.fromJson(json);
      case 13:
        return PathPaymentStrictSendOperationResponse.fromJson(json);
      default:
        throw new Exception("Invalid operation type");
    }
  }
}

/// Represents the operation response links.
class OperationResponseLinks {
  Link effects;
  Link precedes;
  Link self;
  Link succeeds;
  Link transaction;

  OperationResponseLinks(
      this.effects, this.precedes, this.self, this.succeeds, this.transaction);

  factory OperationResponseLinks.fromJson(Map<String, dynamic> json) =>
      new OperationResponseLinks(
          json['effects'] == null
              ? null
              : new Link.fromJson(json['effects'] as Map<String, dynamic>),
          json['precedes'] == null
              ? null
              : new Link.fromJson(json['precedes'] as Map<String, dynamic>),
          json['self'] == null
              ? null
              : new Link.fromJson(json['self'] as Map<String, dynamic>),
          json['succeeds'] == null
              ? null
              : new Link.fromJson(json['succeeds'] as Map<String, dynamic>),
          json['transaction'] == null
              ? null
              : new Link.fromJson(json['transaction'] as Map<String, dynamic>));
}



///Represents Payment operation response.
class PaymentOperationResponse extends OperationResponse {
  String amount;
  String assetType;
  String assetCode;
  String assetIssuer;
  KeyPair from;
  KeyPair to;

  PaymentOperationResponse(String amount, String assetType, String assetCode,
      String assetIssuer, KeyPair from, KeyPair to) {
    this.amount = amount;
    this.assetType = assetType;
    this.assetCode = assetCode;
    this.assetIssuer = assetIssuer;
    this.from = from;
    this.to = to;
  }

  Asset get asset {
    if (assetType == "native") {
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
          json['from'] == null
              ? null
              : KeyPair.fromAccountId(json['from'] as String),
          json['to'] == null
              ? null
              : KeyPair.fromAccountId(json['to'] as String))
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..pagingToken = json['paging_token'] as String
        ..createdAt = json['created_at'] as String
        ..transactionHash = json['transaction_hash'] as String
        ..type = json['type'] as String
        ..links = json['_links'] == null
            ? null
            : new OperationResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}

///Represents SetOptions operation response.
class SetOptionsOperationResponse extends OperationResponse {
  int lowThreshold;
  int medThreshold;
  int highThreshold;
  KeyPair inflationDestination;
  String homeDomain;
  String signerKey;
  int signerWeight;
  int masterKeyWeight;
  List<String> clearFlags;
  List<String> setFlags;

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
      this.setFlags);

  KeyPair get signer {
    return KeyPair.fromAccountId(signerKey);
  }

  factory SetOptionsOperationResponse.fromJson(Map<String, dynamic> json) =>
      new SetOptionsOperationResponse(
          convertInt(json['low_threshold']),
          convertInt(json['med_threshold']),
          convertInt(json['high_threshold']),
          json['inflation_dest'] == null
              ? null
              : KeyPair.fromAccountId(json['inflation_dest'] as String),
          json['home_domain'] as String,
          json['signer_key'] as String,
          convertInt(json['signer_weight']),
          convertInt(json['master_key_weight']),
          (json['clear_flags_s'] as List)?.map((e) => e as String)?.toList(),
          (json['set_flags_s'] as List)?.map((e) => e as String)?.toList())
        ..id = int.parse(json['id'] as String)
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..pagingToken = json['paging_token'] as String
        ..createdAt = json['created_at'] as String
        ..transactionHash = json['transaction_hash'] as String
        ..type = json['type'] as String
        ..links = json['_links'] == null
            ? null
            : new OperationResponseLinks.fromJson(
                json['_links'] as Map<String, dynamic>);
}
