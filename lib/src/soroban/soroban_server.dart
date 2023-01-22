// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import '../xdr/xdr_data_entry.dart';
import '../xdr/xdr_ledger.dart';
import '../transaction.dart';
import '../requests/request_builder.dart';
import '../xdr/xdr_contract.dart';
import '../xdr/xdr_data_io.dart';
import '../util.dart';

/// This class helps you to connect to a local or remote soroban rpc server
/// and send requests to the server. It parses the results and provides
/// corresponding response objects.
class SorobanServer {
  static const String TRANSACTION_STATUS_PENDING = "pending";
  static const String TRANSACTION_STATUS_SUCCESS = "success";
  static const String TRANSACTION_STATUS_ERROR = "error";

  bool enableLogging = false;
  bool acknowledgeExperimental = false;

  String _serverUrl;
  late Map<String, String> _headers;
  final _dio = dio.Dio();
  Map<String, dynamic> _experimentalErr = {
    'error': {'code': -1, 'message': 'acknowledgeExperimental flag not set'}
  };

  /// Constructor.
  /// Provide the url of the soroban rpc server to initialize this class.
  SorobanServer(this._serverUrl) {
    _headers = {...RequestBuilder.headers};
    _headers.putIfAbsent("Content-Type", () => "application/json");
  }

  /// General node health check request.
  Future<GetHealthResponse> getHealth() async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetHealthResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getHealth = JsonRpcMethod("getHealth");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getHealth), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getHealth response: $response");
    }
    return GetHealthResponse.fromJson(response.data);
  }

  /// Fetch a minimal set of current info about a stellar account.
  Future<GetAccountResponse> getAccount(String accountId) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetAccountResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getAccount =
        JsonRpcMethod("getAccount", args: {'address': accountId});
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getAccount response: $response");
    }
    return GetAccountResponse.fromJson(response.data);
  }

  /// For reading the current value of ledger entries directly.
  /// Allows you to directly inspect the current state of a contract,
  /// a contract’s code, or any other ledger entry.
  /// This is a backup way to access your contract data which may
  /// not be available via events or simulateTransaction.
  /// To fetch contract wasm byte-code, use the ContractCode ledger entry key.
  Future<GetLedgerEntryResponse> getLedgerEntry(String base64EncodedKey) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetLedgerEntryResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getLedgerEntry =
        JsonRpcMethod("getLedgerEntry", args: {'key': base64EncodedKey});
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getLedgerEntry),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getLedgerEntry response: $response");
    }
    return GetLedgerEntryResponse.fromJson(response.data);
  }

  /// Submit a trial contract invocation to get back return values,
  /// expected ledger footprint, and expected costs.
  Future<SimulateTransactionResponse> simulateTransaction(
      Transaction transaction) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return SimulateTransactionResponse.fromJson(_experimentalErr);
    }

    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();

    JsonRpcMethod getAccount =
        JsonRpcMethod("simulateTransaction", args: transactionEnvelopeXdr);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("simulateTransaction response: $response");
    }
    return SimulateTransactionResponse.fromJson(response.data);
  }

  /// Submit a real transaction to the stellar network.
  /// This is the only way to make changes “on-chain”.
  /// Unlike Horizon, this does not wait for transaction completion.
  /// It simply validates and enqueues the transaction.
  /// Clients should call getTransactionStatus to learn about
  /// transaction success/failure.
  Future<SendTransactionResponse> sendTransaction(
      Transaction transaction) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return SendTransactionResponse.fromJson(_experimentalErr);
    }

    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();

    JsonRpcMethod getAccount =
        JsonRpcMethod("sendTransaction", args: transactionEnvelopeXdr);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("sendTransaction response: $response");
    }
    return SendTransactionResponse.fromJson(response.data);
  }

  /// Clients will poll this to tell when the transaction has been completed.
  Future<GetTransactionStatusResponse> getTransactionStatus(
      String transactionHash) async {
    if (!this.acknowledgeExperimental) {
      printExperimentalFlagErr();
      return GetTransactionStatusResponse.fromJson(_experimentalErr);
    }

    JsonRpcMethod getAccount =
        JsonRpcMethod("getTransactionStatus", args: transactionHash);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getTransactionStatus response: $response");
    }
    return GetTransactionStatusResponse.fromJson(response.data);
  }

  printExperimentalFlagErr() {
    print("Error: acknowledgeExperimental flag not set");
  }
}

/// Abstract class for soroban rpc responses.
abstract class SorobanRpcResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  SorobanRpcErrorResponse? error;
  SorobanRpcResponse(this.jsonResponse);
}

/// General node health check response.
class GetHealthResponse extends SorobanRpcResponse {
  /// Health status e.g. "healthy"
  String? status;
  static const String HEALTHY = "healthy";

  GetHealthResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetHealthResponse.fromJson(Map<String, dynamic> json) {
    GetHealthResponse response = GetHealthResponse(json);
    if (json['result'] != null) {
      response.status = json['result']['status'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Error response.
class SorobanRpcErrorResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  String? code; // error code
  String? message;
  Map<String, dynamic>? data;

  SorobanRpcErrorResponse(this.jsonResponse);

  factory SorobanRpcErrorResponse.fromJson(Map<String, dynamic> json) {
    SorobanRpcErrorResponse response = SorobanRpcErrorResponse(json);
    if (json['error'] != null) {
      var jErrCode = json['error']['code'];
      if (jErrCode != null) {
        response.code = jErrCode.toString();
      }
      response.message = json['error']['message'];
      response.data = json['error']['data'];
    }
    return response;
  }
}

/// Response for fetching current info about a stellar account.
class GetAccountResponse extends SorobanRpcResponse {
  /// Account Id of the account
  String? id;

  /// Current sequence number of the account
  String? sequence;

  GetAccountResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  bool get accountMissing => error?.code == "-32600" ? true : false;

  factory GetAccountResponse.fromJson(Map<String, dynamic> json) {
    GetAccountResponse response = GetAccountResponse(json);
    if (json['result'] != null) {
      response.id = json['result']['id'];
      response.sequence = json['result']['sequence'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Response when reading the current values of ledger entries.
class GetLedgerEntryResponse extends SorobanRpcResponse {
  /// The current value of the given ledger entry  (serialized in a base64 string)
  String? ledgerEntryData;

  /// The ledger number of the last time this entry was updated (optional)
  String? lastModifiedLedgerSeq;

  /// The current latest ledger observed by the node when this response was generated.
  String? latestLedger;

  XdrLedgerEntryData? get ledgerEntryDataXdr => ledgerEntryData == null
      ? null
      : XdrLedgerEntryData.fromBase64EncodedXdrString(ledgerEntryData!);

  GetLedgerEntryResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetLedgerEntryResponse.fromJson(Map<String, dynamic> json) {
    GetLedgerEntryResponse response = GetLedgerEntryResponse(json);

    if (json['result'] != null) {
      response.ledgerEntryData = json['result']['xdr'];
      response.lastModifiedLedgerSeq = json['result']['lastModifiedLedgerSeq'];
      response.latestLedger = json['result']['latestLedger'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Response that will be received when submitting a trial contract invocation.
class SimulateTransactionResponse extends SorobanRpcResponse {
  /// Footprint containing the ledger keys expected to be written by this transaction
  Footprint? footprint;

  /// Stringified-number of the current latest ledger observed by the node when this response was generated.
  String? latestLedger;

  /// If error is present then results will not be in the response
  List<TransactionStatusResult>? results;

  /// Information about the fees expected, instructions used, etc.
  Cost? cost;

  SimulateTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  /// Error within the result if an error occurs.
  String? resultError;

  factory SimulateTransactionResponse.fromJson(Map<String, dynamic> json) {
    SimulateTransactionResponse response = SimulateTransactionResponse(json);
    if (json['result'] != null) {
      response.resultError = json['result']['error'];
      if (json['result']['results'] != null) {
        response.results = List<TransactionStatusResult>.from(json['result']
                ['results']
            .map((e) => TransactionStatusResult.fromJson(e)));
      }
      String? footStr = json['result']['footprint'];
      if (footStr != null && footStr.trim() != "") {
        response.footprint =
            Footprint(XdrLedgerFootprint.fromBase64EncodedXdrString(footStr));
      }
      response.latestLedger = json['result']['latestLedger'];
      if (json['result']['cost'] != null) {
        response.cost = Cost.fromJson(json['result']['cost']);
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Response when submitting a real transaction to the stellar network.
class SendTransactionResponse extends SorobanRpcResponse {
  /// The transaction hash (in an hex-encoded string), and the initial
  /// transaction status, ("pending" or something)
  String? transactionId;

  /// The current status of the transaction by hash, one of: pending, success, error
  String? status;

  /// (optional) If the transaction was rejected immediately,
  /// this will be an error object.
  TransactionStatusError? resultError;

  SendTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory SendTransactionResponse.fromJson(Map<String, dynamic> json) {
    SendTransactionResponse response = SendTransactionResponse(json);
    if (json['result'] != null) {
      response.transactionId = json['result']['id'];
      response.status = json['result']['status'];
      if (json['result']['error'] != null) {
        response.resultError =
            TransactionStatusError.fromJson(json['result']['error']);
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Internal error used within some of the responses.
class TransactionStatusError extends SorobanRpcResponse {
  /// Short unique string representing the type of error
  String? code;

  /// Human friendly summary of the error
  String? message;

  /// (optional) More data related to the error if available
  Map<String, dynamic>? data;

  TransactionStatusError(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory TransactionStatusError.fromJson(Map<String, dynamic> json) {
    TransactionStatusError response = TransactionStatusError(json);
    response.code = json['code'];
    response.message = json['message'];
    response.data = json['data'];
    return response;
  }
}

/// Response when polling the rpc server to find out if a transaction has been
/// completed.
class GetTransactionStatusResponse extends SorobanRpcResponse {
  /// Hash (id) of the transaction as a hex-encoded string
  String? id;

  /// The current status of the transaction by hash, one of: pending, success, error
  String? status;

  /// (optional) Will be present on completed successful transactions.
  List<TransactionStatusResult>? results;

  /// (optional) A base64 encoded string of the raw TransactionEnvelope XDR struct for this transaction.
  String? envelopeXdr;

  ///  (optional) A base64 encoded string of the raw TransactionResult XDR struct for this transaction.
  String? resultXdr;

  /// (optional) A base64 encoded string of the raw TransactionMeta XDR struct for this transaction.
  String? resultMetaXdr;

  /// (optional) Will be present on failed transactions.
  TransactionStatusError? resultError;

  GetTransactionStatusResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetTransactionStatusResponse.fromJson(Map<String, dynamic> json) {
    GetTransactionStatusResponse response = GetTransactionStatusResponse(json);
    if (json['result'] != null) {
      if (json['result']['results'] != null) {
        response.results = List<TransactionStatusResult>.from(json['result']
                ['results']
            .map((e) => TransactionStatusResult.fromJson(e)));
      }
      response.id = json['result']['id'];
      response.status = json['result']['status'];
      response.envelopeXdr = json['result']['envelopeXdr'];
      response.resultXdr = json['result']['resultXdr'];
      response.resultMetaXdr = json['result']['resultMetaXdr'];
      if (json['result']['error'] != null) {
        response.resultError =
            TransactionStatusError.fromJson(json['result']['error']);
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }

  /// Extracts the wasm id from the response if the transaction installed a contract
  String? getWasmId() {
    return _getBinHex();
  }

  /// Extracts the contract is from the response if the transaction created a contract
  String? getContractId() {
    return _getBinHex();
  }

  /// Extracts the result value from the first entry on success
  XdrSCVal? getResultValue() {
    if (error != null || results == null || results!.length == 0) {
      return null;
    }
    return results!.first.value;
  }

  String? _getBinHex() {
    XdrDataValue? bin = _getBin();
    if (bin != null) {
      return Util.bytesToHex(bin.dataValue);
    }
    return null;
  }

  XdrDataValue? _getBin() {
    if (error != null || results == null || results!.length == 0) {
      return null;
    }
    XdrSCVal xdrVal = results!.first.value;
    if (xdrVal.obj != null) {
      return xdrVal.obj!.bin;
    }
    return null;
  }
}

/// Used as a part of get transaction status and send transaction.
class TransactionStatusResult {
  /// xdr-encoded return value of the contract call
  String xdr;
  TransactionStatusResult(this.xdr);

  factory TransactionStatusResult.fromJson(Map<String, dynamic> json) =>
      TransactionStatusResult(json['xdr']);

  XdrSCVal get value => XdrSCVal.fromBase64EncodedXdrString(xdr);
}

/// Information about the fees expected, instructions used, etc.
class Cost {
  /// Stringified-number of the total cpu instructions consumed by this transaction
  String cpuInsns;

  /// Stringified-number of the total memory bytes allocated by this transaction
  String memBytes;

  Cost(this.cpuInsns, this.memBytes);

  factory Cost.fromJson(Map<String, dynamic> json) =>
      Cost(json['cpuInsns'], json['memBytes']);
}

/// Footprint received when simulating a transaction.
/// Contains utility functions.
class Footprint {
  XdrLedgerFootprint xdrFootprint;
  Footprint(this.xdrFootprint);

  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerFootprint.encode(xdrOutputStream, this.xdrFootprint);
    return base64Encode(xdrOutputStream.bytes);
  }

  static Footprint fromBase64EncodedXdrString(String base64Encoded) {
    Uint8List bytes = base64Decode(base64Encoded);
    return Footprint(XdrLedgerFootprint.decode(XdrDataInputStream(bytes)));
  }

  /// if found, returns the contract code ledger key as base64 encoded xdr string
  String? getContractCodeLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_CODE)
        ?.toBase64EncodedXdrString();
  }

  /// if found, returns the contract code ledger key as XdrLedgerKey
  XdrLedgerKey? getContractCodeXdrLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_CODE);
  }

  /// if found, returns the contract data ledger key as base64 encoded xdr string
  String? getContractDataLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_DATA)
        ?.toBase64EncodedXdrString();
  }

  /// if found, returns the contract code ledger key as XdrLedgerKey
  XdrLedgerKey? getContractDataXdrLedgerKey() {
    return _findFirstKeyOfType(XdrLedgerEntryType.CONTRACT_DATA);
  }

  XdrLedgerKey? _findFirstKeyOfType(XdrLedgerEntryType type) {
    for (XdrLedgerKey key in xdrFootprint.readOnly) {
      if (key.discriminant == type) {
        return key;
      }
    }
    for (XdrLedgerKey key in xdrFootprint.readWrite) {
      if (key.discriminant == type) {
        return key;
      }
    }
    return null;
  }
}

/// Holds name and args of a method request for JSON-RPC v2
///
/// Initialize with a string method name and list or map of params
/// if [notify] is true, output format will be as 'notification'
/// [id] is an int automatically generated from hashCode
class JsonRpcMethod {
  /// [method] is the name of the method at the server
  String method;

  /// [args] is arguments to the method at the server. May be Map or List or nil
  Object? args;

  /// Do we care about the response value?
  bool notify = false;

  /// private. It's auto-generated, but we hold on to it in case we need it
  /// more than once. id is null for notifications.
  int? _id;

  /// constructor
  JsonRpcMethod(this.method, {this.args, this.notify = false});

  /// create id from hashcode when first requested
  dynamic get id {
    _id ??= hashCode;
    return notify ? null : _id;
  }

  /// output the map representation of this instance for processing into JSON
  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map = {'jsonrpc': '2.0', 'method': method};
    if (args != null) {
      map['params'] = (args is List || args is Map) ? args : [args];
    }
    if (!notify) map['id'] = id;
    return map;
  }

  @override
  String toString() => 'JsonRpcMethod: ${toJson()}';
}
