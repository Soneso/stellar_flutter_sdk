// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../xdr/xdr_contract.dart';
import 'operation_responses.dart';
import '../response.dart';

class InvokeHostFunctionOperationResponse extends OperationResponse {
  String? function;
  List<ParameterResponse>? parameters;

  InvokeHostFunctionOperationResponse({this.function, this.parameters});

  factory InvokeHostFunctionOperationResponse.fromJson(
          Map<String, dynamic> json) =>
      InvokeHostFunctionOperationResponse(
          function: json['function'] == null ? null : json['function'],
          parameters: json['parameters'] == null ? null : List<ParameterResponse>.from(json['parameters']
              .map((e) => e == null ? null : ParameterResponse.fromJson(e))))
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

class HostFunctionResponse extends Response {
  String type;
  List<ParameterResponse>? parameters;

  HostFunctionResponse(this.type, this.parameters);

  factory HostFunctionResponse.fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    List<ParameterResponse>? parameters;
    if (json['parameters'] != null) {
      parameters = List<ParameterResponse>.from(json['parameters']
          .map((e) => e == null ? null : ParameterResponse.fromJson(e)));
    }
    return HostFunctionResponse(type, parameters);
  }
}

class ParameterResponse extends Response {
  String type;
  String? value;
  String? from;
  String? salt;
  String? asset;

  ParameterResponse(this.type, {this.value, this.from, this.salt, this.asset});

  factory ParameterResponse.fromJson(Map<String, dynamic> json) {
    return ParameterResponse(json['type'],
        value: json['value'],
        from: json['from'],
        salt: json['salt'],
        asset: json['asset']);
  }

  XdrSCVal? xdrValue() {
    if (value != null) {
      return XdrSCVal.fromBase64EncodedXdrString(value!);
    }
    return null;
  }
}
