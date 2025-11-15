// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import '../../xdr/xdr_contract.dart';
import 'operation_responses.dart';
import '../transaction_response.dart';

/// Represents an invoke host function operation response from Horizon.
///
/// This Soroban operation invokes a smart contract function on the Stellar network.
/// It can deploy contracts, invoke contract functions, or extend contract storage.
///
/// Returned by: Horizon API operations endpoint when querying invoke host function operations
///
/// Example:
/// ```dart
/// final operations = await sdk.operations
///     .forAccount('account_id')
///     .execute();
///
/// for (var op in operations.records) {
///   if (op is InvokeHostFunctionOperationResponse) {
///     print('Function: ${op.function}');
///     print('Contract: ${op.address}');
///
///     // Access function parameters
///     if (op.parameters != null) {
///       for (var param in op.parameters!) {
///         print('Parameter type: ${param.type}');
///         var scVal = param.xdrValue();
///         // Process XDR value
///       }
///     }
///
///     // Check asset balance changes
///     if (op.assetBalanceChanges != null) {
///       for (var change in op.assetBalanceChanges!) {
///         print('Transfer: ${change.amount} from ${change.from} to ${change.to}');
///       }
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [InvokeHostFunctionOperation] for invoking smart contracts
/// - [Stellar developer docs](https://developers.stellar.org)
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

  /// Creates an InvokeHostFunctionOperationResponse from Horizon API operation data.
  ///
  /// This constructor is typically called internally when deserializing operation
  /// records from Horizon API responses.
  ///
  /// Parameters:
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
  /// - [function] The host function type being invoked
  /// - [address] Contract address (if applicable)
  /// - [salt] Salt value for contract creation
  /// - [parameters] Function parameters (if applicable)
  /// - [assetBalanceChanges] Asset balance changes from the invocation
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

  /// Deserializes an invoke host function operation response from JSON.
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

/// Represents a parameter passed to a Soroban smart contract function.
///
/// Parameters are encoded in XDR format as SCVal types. The [value] field contains
/// the base64-encoded XDR representation, which can be decoded to access the
/// actual parameter data.
///
/// Use [xdrValue] to decode the parameter into a typed XDR structure for
/// processing in your application.
class ParameterResponse {
  /// Parameter type identifier
  String type;

  /// Base64-encoded XDR representation of the parameter value
  String value;

  /// Creates a ParameterResponse from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing parameter
  /// data from Horizon API responses.
  ///
  /// Parameters:
  /// - [type] Parameter type identifier
  /// - [value] Base64-encoded XDR representation of the parameter
  ParameterResponse(this.type, this.value);

  /// Deserializes a parameter response from JSON.
  factory ParameterResponse.fromJson(Map<String, dynamic> json) {
    return ParameterResponse(json['type'], json['value']);
  }

  /// Decodes the parameter value from base64 XDR to an XdrSCVal object.
  ///
  /// Returns the decoded Soroban contract value that can be processed
  /// according to its specific type.
  XdrSCVal xdrValue() {
    return XdrSCVal.fromBase64EncodedXdrString(value);
  }
}

/// Represents asset balance changes resulting from smart contract execution.
///
/// Tracks asset transfers that occur during Soroban contract invocations.
/// This includes the asset type, amount, and the accounts involved in the transfer.
///
/// Balance changes show which assets were moved and in what direction, allowing
/// applications to track the economic effects of contract executions.
class AssetBalanceChange {
  /// Type of balance change (e.g., 'transfer', 'mint', 'burn')
  String type;

  /// Source account of the transfer (if applicable)
  String? from;

  /// Destination account of the transfer (if applicable)
  String? to;

  /// Amount transferred as decimal string
  String amount;

  /// Type of asset ('native', 'credit_alphanum4', or 'credit_alphanum12')
  String assetType;

  /// Asset code (e.g., 'USD', 'EUR'), null for native XLM
  String? assetCode;

  /// Asset issuer account ID, null for native XLM
  String? assetIssuer;

  /// Muxed account ID if the invocation involved a muxed destination address.
  /// A uint64 as string.
  /// Only available for protocol version >= 23
  String? destinationMuxedId;

  /// Creates an AssetBalanceChange from Horizon API data.
  ///
  /// This constructor is typically called internally when deserializing asset
  /// balance change data from Horizon API responses.
  ///
  /// Parameters:
  /// - [type] Type of balance change
  /// - [from] Source account of the transfer (if applicable)
  /// - [to] Destination account of the transfer (if applicable)
  /// - [amount] Amount transferred as decimal string
  /// - [assetType] Type of asset
  /// - [assetCode] Asset code (null for native XLM)
  /// - [assetIssuer] Asset issuer account ID (null for native XLM)
  /// - [destinationMuxedId] Muxed account ID if applicable (protocol 23+)
  AssetBalanceChange(this.type, this.from, this.to, this.amount, this.assetType,
      {this.assetCode,
      this.assetIssuer,
      this.destinationMuxedId});

  /// Deserializes an asset balance change from JSON.
  factory AssetBalanceChange.fromJson(Map<String, dynamic> json) {
    return AssetBalanceChange(json['type'], json['from'], json['to'],
        json['amount'], json['asset_type'],
        assetCode: json['asset_code'],
        assetIssuer: json['asset_issuer'],
        destinationMuxedId: json['destination_muxed_id']);
  }
}
