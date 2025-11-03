// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../xdr/xdr_contract.dart';
import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents an invoke host function operation response from Horizon.
///
/// This Soroban operation invokes a smart contract function on the Stellar network.
///
/// Returned by: Horizon API operations endpoint when querying invoke host function operations
///
/// See also:
/// - [InvokeHostFunctionOperation] for invoking smart contracts
/// - [Horizon Invoke Host Function](https://developers.stellar.org/docs/data/horizon/api-reference/resources/operations/object/invoke-host-function)
class InvokeHostFunctionOperationResponse extends OperationResponse {
  /// The host function type being invoked
  String function;

  /// Contract address if applicable
  String address;

  /// Salt value for contract creation
  String salt;

  /// Function parameters if applicable
  List<ParameterResponse>? parameters;

  /// Asset balance changes resulting from the invocation
  List<AssetBalanceChange>? assetBalanceChanges;

  InvokeHostFunctionOperationResponse(
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
      super.sponsor,
      this.function,
      this.address,
      this.salt,
      this.parameters,
      this.assetBalanceChanges);

  factory InvokeHostFunctionOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      InvokeHostFunctionOperationResponse(
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
        json['sponsor'],
        json['function'],
        json['address'],
        json['salt'],
        json['parameters'] == null
            ? null
            : List<ParameterResponse>.from(
                json['parameters'].map((e) => ParameterResponse.fromJson(e))),
        json['asset_balance_changes'] == null
            ? null
            : List<AssetBalanceChange>.from(json['asset_balance_changes']
                .map((e) => AssetBalanceChange.fromJson(e))),
      );
}

class ParameterResponse {
  String type;
  String value;

  ParameterResponse(this.type, this.value);

  factory ParameterResponse.fromJson(Map<String, dynamic> json) {
    return ParameterResponse(json['type'], json['value']);
  }

  XdrSCVal xdrValue() {
    return XdrSCVal.fromBase64EncodedXdrString(value);
  }
}

class AssetBalanceChange {
  String type;
  String? from;
  String? to;
  String amount;
  String assetType;
  String? assetCode;
  String? assetIssuer;

  /// Muxed Id if the invocation involved a muxed destination address.
  /// A uint64 as string.
  /// Only available for protocol version >= 23
  String? destinationMuxedId;

  AssetBalanceChange(this.type, this.from, this.to, this.amount, this.assetType,
      {this.assetCode,
      this.assetIssuer,
      this.destinationMuxedId});

  factory AssetBalanceChange.fromJson(Map<String, dynamic> json) {
    return AssetBalanceChange(json['type'], json['from'], json['to'],
        json['amount'], json['asset_type'],
        assetCode: json['asset_code'],
        assetIssuer: json['asset_issuer'],
        destinationMuxedId: json['destination_muxed_id']);
  }
}
