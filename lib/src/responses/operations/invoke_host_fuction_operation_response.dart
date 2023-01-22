// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../xdr/xdr_contract.dart';
import 'operation_responses.dart';
import '../response.dart';

class InvokeHostFunctionOperationResponse extends OperationResponse {
  String function;
  List<ParameterResponse>? parameters;
  String footprint;

  InvokeHostFunctionOperationResponse(
      {required this.function,
        required this.parameters,
        required this.footprint});

  factory InvokeHostFunctionOperationResponse.fromJson(
      Map<String, dynamic> json) =>
      InvokeHostFunctionOperationResponse(
          function: json['function'],
          parameters: json['parameters'] != null
              ? List<ParameterResponse>.from(json['parameters']
              .map((e) => e == null ? null : ParameterResponse.fromJson(e)))
              : null,
          footprint: json['footprint'])
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

class ParameterResponse extends Response {
  String value;
  String type;

  ParameterResponse(this.value, this.type);

  factory ParameterResponse.fromJson(Map<String, dynamic> json) {
    return ParameterResponse(json['value'], json['type']);
  }

  XdrSCVal toXdr() {
      return XdrSCVal.fromBase64EncodedXdrString(value);
  }
}