// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../xdr/xdr_contract.dart';
import 'operation_responses.dart';

class InvokeHostFunctionOperationResponse extends OperationResponse {
  String function;
  String address;
  String salt;

  List<ParameterResponse>? parameters;
  List<AssetBalanceChange>? assetBalanceChanges;

  InvokeHostFunctionOperationResponse(this.function, this.address, this.salt,
      {this.parameters, this.assetBalanceChanges});

  factory InvokeHostFunctionOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      InvokeHostFunctionOperationResponse(
        json['function'],
        json['address'],
        json['salt'],
        parameters: json['parameters'] == null
            ? null
            : List<ParameterResponse>.from(json['parameters']
                .map((e) => e == null ? null : ParameterResponse.fromJson(e))),
        assetBalanceChanges: json['asset_balance_changes'] == null
            ? null
            : List<AssetBalanceChange>.from(json['asset_balance_changes']
                .map((e) => e == null ? null : AssetBalanceChange.fromJson(e))),
      )
        ..id = int.tryParse(json['id'])
        ..sourceAccount =
            json['source_account'] == null ? null : json['source_account']
        ..sourceAccountMuxed = json['source_account_muxed'] == null
            ? null
            : json['source_account_muxed']
        ..sourceAccountMuxedId = json['source_account_muxed_id'] == null
            ? null
            : json['source_account_muxed_id']
        ..pagingToken = json['paging_token']
        ..createdAt = json['created_at']
        ..transactionHash = json['transaction_hash']
        ..transactionSuccessful = json['transaction_successful']
        ..type = json['type']
        ..links = json['_links'] == null
            ? null
            : OperationResponseLinks.fromJson(json['_links']);
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
  String from;
  String to;
  String amount;
  String assetType;
  String? assetCode;
  String? assetIssuer;

  AssetBalanceChange(this.type, this.from, this.to, this.amount, this.assetType,
      {this.assetCode, this.assetIssuer});

  factory AssetBalanceChange.fromJson(Map<String, dynamic> json) {
    return AssetBalanceChange(json['type'], json['from'], json['to'],
        json['amount'], json['asset_type'],
        assetCode: json['asset_code'], assetIssuer: json['asset_issuer']);
  }
}
