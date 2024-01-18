// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:io' as IO;
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:dio/io.dart';
import 'package:stellar_flutter_sdk/src/responses/response.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';
import 'soroban_auth.dart';
import '../xdr/xdr_data_entry.dart';
import '../xdr/xdr_ledger.dart';
import '../transaction.dart';
import '../requests/request_builder.dart';
import '../xdr/xdr_contract.dart';
import '../xdr/xdr_data_io.dart';
import '../util.dart';
import '../xdr/xdr_transaction.dart';

import 'package:stellar_flutter_sdk/stub/non-web.dart'
    if (dart.library.html) 'package:stellar_flutter_sdk/stub/web.dart';

/// This class helps you to connect to a local or remote soroban rpc server
/// and send requests to the server. It parses the results and provides
/// corresponding response objects.
class SorobanServer {
  bool enableLogging = false;

  String _serverUrl;
  late Map<String, String> _headers;
  dio.Dio _dio = dio.Dio();

  /// Constructor.
  /// Provide the url of the soroban rpc server to initialize this class.
  SorobanServer(this._serverUrl) {
    _headers = {...RequestBuilder.headers};
    _headers.putIfAbsent("Content-Type", () => "application/json");
  }

  /// Dio HTTP Overrides
  /// enable overrides to handle badCertificateCallback.
  /// available only for the non-Web platform.
  set httpOverrides(bool setOverrides) {
    if (!kIsWeb && setOverrides) {
      dio.Dio dioOverrides = dio.Dio();
      (dioOverrides.httpClientAdapter as IOHttpClientAdapter)
          .onHttpClientCreate = (IO.HttpClient client) {
        client.badCertificateCallback =
            (IO.X509Certificate cert, String host, int port) => true;
        return client;
      };
      _dio = dioOverrides;
    }
  }

  /// General node health check request.
  /// See: https://soroban.stellar.org/api/methods/getHealth
  Future<GetHealthResponse> getHealth() async {
    JsonRpcMethod getHealth = JsonRpcMethod("getHealth");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getHealth), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getHealth response: $response");
    }
    return GetHealthResponse.fromJson(response.data);
  }

  /// For finding out the current latest known ledger.
  /// See: https://soroban.stellar.org/api/methods/getLatestLedger
  Future<GetLatestLedgerResponse> getLatestLedger() async {
    JsonRpcMethod getLatestLedger = JsonRpcMethod("getLatestLedger");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getLatestLedger),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getLatestLedger response: $response");
    }
    return GetLatestLedgerResponse.fromJson(response.data);
  }

  /// For reading the current value of ledger entries directly.
  /// Allows you to directly inspect the current state of a contract,
  /// a contract’s code, or any other ledger entry.
  /// This is a backup way to access your contract data which may
  /// not be available via events or simulateTransaction.
  /// To fetch contract wasm byte-code, use the ContractCode ledger entry key.
  /// See: https://soroban.stellar.org/api/methods/getLedgerEntries
  Future<GetLedgerEntriesResponse> getLedgerEntries(
      List<String> base64EncodedKeys) async {
    JsonRpcMethod getLedgerEntries =
        JsonRpcMethod("getLedgerEntries", args: {'keys': base64EncodedKeys});
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getLedgerEntries),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getLedgerEntries response: $response");
    }
    return GetLedgerEntriesResponse.fromJson(response.data);
  }

  /// Loads the contract source code (including source code - wasm bytes) for a given wasm id.
  Future<XdrContractCodeEntry?> loadContractCodeForWasmId(String wasmId) async {
    XdrLedgerKey ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
    ledgerKey.contractCode =
        XdrLedgerKeyContractCode(XdrHash(Util.hexToBytes(wasmId)));
    GetLedgerEntriesResponse ledgerEntriesResponse =
        await getLedgerEntries([ledgerKey.toBase64EncodedXdrString()]);

    if (ledgerEntriesResponse.entries != null &&
        ledgerEntriesResponse.entries!.length > 0) {
      return ledgerEntriesResponse.entries![0].ledgerEntryDataXdr.contractCode;
    }
    return null;
  }

  /// Loads the contract code entry (including source code - wasm bytes) for a given contract id.
  Future<XdrContractCodeEntry?> loadContractCodeForContractId(
      String contractId) async {
    XdrLedgerKey ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
    ledgerKey.contractData = XdrLedgerKeyContractData(
        Address.forContractId(contractId).toXdr(),
        XdrSCVal.forLedgerKeyContractInstance(),
        XdrContractDataDurability.PERSISTENT);

    GetLedgerEntriesResponse ledgerEntriesResponse =
        await getLedgerEntries([ledgerKey.toBase64EncodedXdrString()]);
    if (ledgerEntriesResponse.entries != null &&
        ledgerEntriesResponse.entries!.length > 0) {
      XdrLedgerEntryData ledgerEntryData =
          ledgerEntriesResponse.entries![0].ledgerEntryDataXdr;
      if (ledgerEntryData.contractData != null &&
          ledgerEntryData.contractData?.val.instance?.executable.wasmHash !=
              null) {
        String wasmId = Util.bytesToHex(ledgerEntryData
            .contractData!.val.instance!.executable.wasmHash!.hash);
        return await (loadContractCodeForWasmId(wasmId));
      }
    }
    return null;
  }

  /// General info about the currently configured network.
  /// See: https://soroban.stellar.org/api/methods/getNetwork
  Future<GetNetworkResponse> getNetwork() async {
    JsonRpcMethod getNetwork = JsonRpcMethod("getNetwork");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getNetwork), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getNetwork response: $response");
    }
    return GetNetworkResponse.fromJson(response.data);
  }

  /// Submit a trial contract invocation to get back return values,
  /// expected ledger footprint, and expected costs.
  /// See: https://soroban.stellar.org/api/methods/simulateTransaction
  Future<SimulateTransactionResponse> simulateTransaction(
      SimulateTransactionRequest request) async {
    JsonRpcMethod getAccount =
        JsonRpcMethod("simulateTransaction", args: request.getRequestArgs());
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
  /// This supports all transactions, not only smart contract-related transactions.
  /// See: https://soroban.stellar.org/api/methods/sendTransaction
  Future<SendTransactionResponse> sendTransaction(
      Transaction transaction) async {
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
  /// See: https://soroban.stellar.org/api/methods/getTransaction
  Future<GetTransactionResponse> getTransaction(String transactionHash) async {
    JsonRpcMethod getTransactionStatus =
        JsonRpcMethod("getTransaction", args: transactionHash);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getTransactionStatus),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getTransaction response: $response");
    }
    return GetTransactionResponse.fromJson(response.data);
  }

  /// Clients can request a filtered list of events emitted by a given ledger range.
  /// Soroban-RPC will support querying within a maximum 24 hours of recent ledgers.
  /// Note, this could be used by the client to only prompt a refresh when there is a new ledger with relevant events.
  /// It should also be used by backend Dapp components to "ingest" events into their own database for querying and serving.
  /// If making multiple requests, clients should deduplicate any events received, based on the event's unique id field.
  /// This prevents double-processing in the case of duplicate events being received.
  /// By default soroban-rpc retains the most recent 24 hours of events.
  /// See: https://soroban.stellar.org/api/methods/getEvents
  Future<GetEventsResponse> getEvents(GetEventsRequest request) async {
    JsonRpcMethod getEvents =
        JsonRpcMethod("getEvents", args: request.getRequestArgs());
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getEvents), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getEvents response: $response");
    }
    return GetEventsResponse.fromJson(response.data);
  }
}

/// Abstract class for soroban rpc responses.
abstract class SorobanRpcResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  SorobanRpcErrorResponse? error;

  SorobanRpcResponse(this.jsonResponse);

  bool get isErrorResponse => error != null;
}

/// General node health check response.
/// See: https://soroban.stellar.org/api/methods/getHealth
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

/// See: https://soroban.stellar.org/api/methods/getLatestLedger
class GetLatestLedgerResponse extends SorobanRpcResponse {
  /// hash of the latest ledger as a hex-encoded string.
  String? id;

  /// Stellar Core protocol version associated with the latest ledger.
  int? protocolVersion;

  /// Sequence number of the latest ledger.
  int? sequence;

  GetLatestLedgerResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetLatestLedgerResponse.fromJson(Map<String, dynamic> json) {
    GetLatestLedgerResponse response = GetLatestLedgerResponse(json);
    if (json['result'] != null) {
      response.id = json['result']['id'];
      response.protocolVersion = json['result']['protocolVersion'];
      response.sequence = json['result']['sequence'];
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

class GetLedgerEntriesResponse extends SorobanRpcResponse {
  /// Entries
  List<LedgerEntry>? entries;

  /// The current latest ledger observed by the node when this response was generated.
  int? latestLedger;

  GetLedgerEntriesResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetLedgerEntriesResponse.fromJson(Map<String, dynamic> json) {
    GetLedgerEntriesResponse response = GetLedgerEntriesResponse(json);

    if (json['result'] != null) {
      response.entries = List<LedgerEntry>.from(
          json['result']['entries'].map((e) => LedgerEntry.fromJson(e)));
      response.latestLedger = json['result']['latestLedger'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

class LedgerEntry {
  /// The key of the ledger entry (serialized in a base64 string)
  String key;

  /// The current value of the given ledger entry (serialized in a base64 string)
  String xdr;

  /// The ledger number of the last time this entry was updated (optional)
  int lastModifiedLedgerSeq;

  /// The ledger sequence number after which the ledger entry would expire. This field exists only for ContractCodeEntry and ContractDataEntry ledger entries (optional).
  int? liveUntilLedgerSeq;

  XdrLedgerEntryData get ledgerEntryDataXdr =>
      XdrLedgerEntryData.fromBase64EncodedXdrString(xdr);

  LedgerEntry(
      this.key, this.xdr, this.lastModifiedLedgerSeq, this.liveUntilLedgerSeq);

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    String key = json['key'];
    String xdr = json['xdr'];
    int lastModifiedLedgerSeq = json['lastModifiedLedgerSeq'];
    int? liveUntilLedgerSeq = json['liveUntilLedgerSeq'];
    return LedgerEntry(key, xdr, lastModifiedLedgerSeq, liveUntilLedgerSeq);
  }
}

/// See: https://soroban.stellar.org/api/methods/getNetwork
class GetNetworkResponse extends SorobanRpcResponse {
  String? friendbotUrl;
  String? passphrase;
  int? protocolVersion;

  GetNetworkResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetNetworkResponse.fromJson(Map<String, dynamic> json) {
    GetNetworkResponse response = GetNetworkResponse(json);
    if (json['result'] != null) {
      response.friendbotUrl = json['result']['friendbotUrl'];
      response.passphrase = json['result']['passphrase'];
      response.protocolVersion = json['result']['protocolVersion'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// It can only present on successful simulation (i.e. no error) of InvokeHostFunction operations.
/// If present, it indicates the simulation detected expired ledger entries which requires restoring
/// with the submission of a RestoreFootprint operation before submitting the InvokeHostFunction operation.
/// The minResourceFee and transactionData fields should be used to construct the transaction
/// containing the RestoreFootprint operation.
class RestorePreamble {
  /// The recommended Soroban Transaction Data to use when submitting the RestoreFootprint operation.
  XdrSorobanTransactionData transactionData;

  ///  Recommended minimum resource fee to add when submitting the RestoreFootprint operation. This fee is to be added on top of the Stellar network fee.
  int minResourceFee;

  RestorePreamble(this.transactionData, this.minResourceFee);

  factory RestorePreamble.fromJson(Map<String, dynamic> json) {
    XdrSorobanTransactionData transactionData =
        XdrSorobanTransactionData.fromBase64EncodedXdrString(
            json['transactionData']);

    int minResourceFee = convertInt(json['minResourceFee'])!;
    return RestorePreamble(transactionData, minResourceFee);
  }
}

/// Part of the SimulateTransactionRequest.
/// Allows budget instruction leeway used in preflight calculations to be configured.
class ResourceConfig {
  int instructionLeeway;

  ResourceConfig(this.instructionLeeway);

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    map['instructionLeeway'] = instructionLeeway;
    return map;
  }
}

/// Holds the request parameters for simulateTransaction.
/// See: https://soroban.stellar.org/api/methods/simulateTransaction
class SimulateTransactionRequest {
  /// The transaction to be submitted.
  Transaction transaction;

  /// Allows budget instruction leeway used in preflight calculations to be configured
  /// If not provided the leeway defaults to 3000000 instructions
  ResourceConfig? resourceConfig;

  SimulateTransactionRequest(this.transaction, {this.resourceConfig});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    map['transaction'] = transaction.toEnvelopeXdrBase64();
    if (resourceConfig != null) {
      map['resourceConfig'] = resourceConfig!.getRequestArgs();
    }
    return map;
  }
}

/// Response that will be received when submitting a trial contract invocation.
/// See: https://soroban.stellar.org/api/methods/simulateTransaction
class SimulateTransactionResponse extends SorobanRpcResponse {
  /// number of the current latest ledger observed by the node when this response was generated.
  int? latestLedger;

  /// If error is present then results will not be in the response
  /// There will be one results object for each operation in the transaction.
  List<SimulateTransactionResult>? results;

  /// Information about the fees expected, instructions used, etc.
  SimulateTransactionCost? cost;

  /// The recommended Soroban Transaction Data to use when submitting the simulated transaction. This data contains the refundable fee and resource usage information such as the ledger footprint and IO access data.
  XdrSorobanTransactionData? transactionData;

  /// Recommended minimum resource fee to add when submitting the transaction. This fee is to be added on top of the Stellar network fee.
  int? minResourceFee;

  /// Array of the events emitted during the contract invocation(s). The events are ordered by their emission time. (an array of serialized base64 strings representing XdrDiagnosticEvent)
  List<String>? events;

  /// It can only present on successful simulation (i.e. no error) of InvokeHostFunction operations. If present, it indicates
  /// the simulation detected expired ledger entries which requires restoring with the submission of a RestoreFootprint
  /// operation before submitting the InvokeHostFunction operation. The restorePreamble.minResourceFee and restorePreamble.transactionData fields should
  /// be used to construct the transaction containing the RestoreFootprint
  RestorePreamble? restorePreamble;

  SimulateTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  /// (optional) only present if the transaction failed.
  /// This field will include more details from stellar-core about why the invoke host function call failed.
  String? resultError;

  factory SimulateTransactionResponse.fromJson(Map<String, dynamic> json) {
    SimulateTransactionResponse response = SimulateTransactionResponse(json);
    if (json['result'] != null) {
      response.resultError = json['result']['error'];
      if (json['result']['results'] != null) {
        response.results = List<SimulateTransactionResult>.from(json['result']
                ['results']
            .map((e) => SimulateTransactionResult.fromJson(e)));
      }

      response.latestLedger = json['result']['latestLedger'];

      if (json['result']['cost'] != null) {
        response.cost =
            SimulateTransactionCost.fromJson(json['result']['cost']);
      }

      if (json['result']['transactionData'] != null &&
          json['result']['transactionData'].trim() != "") {
        response.transactionData =
            XdrSorobanTransactionData.fromBase64EncodedXdrString(
                json['result']['transactionData']);
      }

      if (json['result']['events'] != null) {
        response.events =
            List<String>.from(json['result']['events'].map((e) => e));
      }

      if (json['result']['restorePreamble'] != null) {
        response.restorePreamble =
            RestorePreamble.fromJson(json['result']['restorePreamble']);
      }

      response.minResourceFee = convertInt(json['result']['minResourceFee']);
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }

  Footprint? getFootprint() {
    if (transactionData != null) {
      return Footprint(transactionData!.resources.footprint);
    }
    return null;
  }

  Footprint? get footprint => getFootprint();

  List<SorobanAuthorizationEntry>? getSorobanAuth() {
    if (results != null && results!.length > 0 && results![0].auth != null) {
      List<SorobanAuthorizationEntry> result =
          List<SorobanAuthorizationEntry>.empty(growable: true);
      for (String nextAuthXdr in results![0].auth!) {
        result.add(SorobanAuthorizationEntry.fromBase64EncodedXdr(nextAuthXdr));
      }
      return result;
    }
    return null;
  }

  List<SorobanAuthorizationEntry>? get sorobanAuth => getSorobanAuth();
}

/// Used as a part of simulate transaction.
/// See: https://soroban.stellar.org/api/methods/simulateTransaction
class SimulateTransactionResult {
  /// (optional) Only present on success. xdr-encoded return value of the contract call operation.
  String? xdr;

  /// Per-address authorizations recorded when simulating this operation. (an array of XdrContractAuth serialized base64 strings)
  List<String>? auth;

  SimulateTransactionResult(this.xdr, this.auth);

  factory SimulateTransactionResult.fromJson(Map<String, dynamic> json) {
    String xdr = json['xdr'];

    List<String>? auth;
    if (json['auth'] != null) {
      auth = List<String>.from(json['auth'].map((e) => e));
    }

    return SimulateTransactionResult(xdr, auth);
  }

  ///  Only present on success. Return value of the contract call operation.
  XdrSCVal? get resultValue =>
      xdr != null ? XdrSCVal.fromBase64EncodedXdrString(xdr!) : null;
}

/// Response when submitting a real transaction to the stellar network.
/// See: https://soroban.stellar.org/api/methods/sendTransaction
class SendTransactionResponse extends SorobanRpcResponse {
  /// represents the status value returned by stellar-core when an error occurred from submitting a transaction
  static const String STATUS_ERROR = "ERROR";

  /// represents the status value returned by stellar-core when a transaction has been accepted for processing
  static const String STATUS_PENDING = "PENDING";

  /// represents the status value returned by stellar-core when a submitted transaction is a duplicate
  static const String STATUS_DUPLICATE = "DUPLICATE";

  /// represents the status value returned by stellar-core when a submitted transaction was not included in the
  static const String STATUS_TRY_AGAIN_LATER = "TRY_AGAIN_LATER";

  /// The transaction hash (in an hex-encoded string).
  String? hash;

  /// The current status of the transaction by hash, one of: ERROR, PENDING, DUPLICATE, TRY_AGAIN_LATER
  /// ERROR represents the status value returned by stellar-core when an error occurred from submitting a transaction
  /// PENDING represents the status value returned by stellar-core when a transaction has been accepted for processing
  /// DUPLICATE represents the status value returned by stellar-core when a submitted transaction is a duplicate
  /// TRY_AGAIN_LATER represents the status value returned by stellar-core when a submitted transaction was not included in the
  /// previous 4 ledgers and get banned for being added in the next few ledgers.
  String? status;

  /// The latest ledger known to Soroban-RPC at the time it handled the sendTransaction() request.
  int? latestLedger;

  /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the sendTransaction() request.
  String? latestLedgerCloseTime;

  ///  (optional) If the transaction status is ERROR, this will be a base64 encoded string of the raw TransactionResult XDR struct containing details on why stellar-core rejected the transaction.
  String? errorResultXdr;

  /// If the transaction status is "ERROR", this list of diagnostic events may be present containing details on why stellar-core rejected the transaction.
  List<XdrDiagnosticEvent>? diagnosticEvents;

  SendTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory SendTransactionResponse.fromJson(Map<String, dynamic> json) {
    SendTransactionResponse response = SendTransactionResponse(json);
    if (json['result'] != null) {
      response.hash = json['result']['hash'];
      response.status = json['result']['status'];
      response.latestLedger = json['result']['latestLedger'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.errorResultXdr = json['result']['errorResultXdr'];
      if (json['result']['diagnosticEventsXdr'] != null) {
        List<String> xdrList = List<String>.from(
            json['result']['diagnosticEventsXdr'].map((e) => e));
        response.diagnosticEvents =
            List<XdrDiagnosticEvent>.empty(growable: true);
        for (String nextXdr in xdrList) {
          response.diagnosticEvents!
              .add(XdrDiagnosticEvent.fromBase64EncodedXdrString(nextXdr));
        }
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Response when polling the rpc server to find out if a transaction has been
/// completed.
/// See https://soroban.stellar.org/api/methods/getTransaction
class GetTransactionResponse extends SorobanRpcResponse {
  static const String STATUS_SUCCESS = "SUCCESS";
  static const String STATUS_NOT_FOUND = "NOT_FOUND";
  static const String STATUS_FAILED = "FAILED";

  /// The current status of the transaction by hash, one of: SUCCESS, NOT_FOUND, FAILED
  String? status;

  /// The latest ledger known to Soroban-RPC at the time it handled the getTransaction() request.
  int? latestLedger;

  /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the getTransaction() request.
  String? latestLedgerCloseTime;

  /// The oldest ledger ingested by Soroban-RPC at the time it handled the getTransaction() request.
  int? oldestLedger;

  /// The unix timestamp of the close time of the oldest ledger ingested by Soroban-RPC at the time it handled the getTransaction() request.
  String? oldestLedgerCloseTime;

  /// (optional) The sequence of the ledger which included the transaction. This field is only present if status is SUCCESS or FAILED.
  int? ledger;

  ///  (optional) The unix timestamp of when the transaction was included in the ledger. This field is only present if status is SUCCESS or FAILED.
  String? createdAt;

  /// (optional) The index of the transaction among all transactions included in the ledger. This field is only present if status is SUCCESS or FAILED.
  int? applicationOrder;

  /// (optional) Indicates whether the transaction was fee bumped. This field is only present if status is SUCCESS or FAILED.
  bool? feeBump;

  /// (optional) A base64 encoded string of the raw TransactionEnvelope XDR struct for this transaction.
  String? envelopeXdr;

  /// (optional) A base64 encoded string of the raw TransactionResult XDR struct for this transaction. This field is only present if status is SUCCESS or FAILED.
  String? resultXdr;

  /// (optional) A base64 encoded string of the raw TransactionMeta XDR struct for this transaction.
  String? resultMetaXdr;

  GetTransactionResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetTransactionResponse.fromJson(Map<String, dynamic> json) {
    GetTransactionResponse response = GetTransactionResponse(json);
    if (json['result'] != null) {
      response.status = json['result']['status'];
      response.latestLedger = json['result']['latestLedger'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.oldestLedger = json['result']['oldestLedger'];
      response.oldestLedgerCloseTime = json['result']['oldestLedgerCloseTime'];
      response.ledger = json['result']['ledger'];
      response.createdAt = json['result']['createdAt'];
      response.applicationOrder =
          convertToInt(json['result']['applicationOrder']);
      response.feeBump = json['result']['feeBump'];
      response.envelopeXdr = json['result']['envelopeXdr'];
      response.resultXdr = json['result']['resultXdr'];
      response.resultMetaXdr = json['result']['resultMetaXdr'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }

  static int? convertToInt(var src) {
    if (src == null) return null;
    if (src is int) return src;
    if (src is String) return int.parse(src);
    throw Exception("Not integer");
  }

  /// Extracts the wasm id from the response if the transaction installed a contract
  String? getWasmId() {
    return _getBinHex();
  }

  /// Extracts the contract is from the response if the transaction created a contract
  String? getCreatedContractId() {
    XdrSCVal? resultValue = getResultValue();
    if (resultValue != null &&
        resultValue.discriminant == XdrSCValType.SCV_ADDRESS &&
        resultValue.address != null) {
      XdrSCAddress address = resultValue.address!;
      if (address.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT &&
          address.contractId != null) {
        return Util.bytesToHex(address.contractId!.hash);
      }
    }
    return null;
  }

  /// Extracts the result value from the first entry on success
  XdrSCVal? getResultValue() {
    if (error != null || status != STATUS_SUCCESS || resultMetaXdr == null) {
      return null;
    }

    XdrTransactionMeta meta =
        XdrTransactionMeta.fromBase64EncodedXdrString(resultMetaXdr!);

    return meta.v3?.sorobanMeta?.returnValue;
  }

  String? _getBinHex() {
    XdrDataValue? bin = _getBin();
    if (bin != null) {
      return Util.bytesToHex(bin.dataValue);
    }
    return null;
  }

  XdrDataValue? _getBin() {
    XdrSCVal? xdrVal = getResultValue();
    return xdrVal?.bytes;
  }
}

/// Holds the request parameters for getEvents.
/// See: https://soroban.stellar.org/api/methods/getEvents
class GetEventsRequest {
  /// ledger sequence number to fetch events after (inclusive).
  /// The getEvents method will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  int? startLedger;

  /// List of filters for the returned events. Events matching any of the filters are included.
  /// To match a filter, an event must match both a contractId and a topic.
  /// Maximum 5 filters are allowed per request.
  List<EventFilter>? filters;

  /// Pagination
  List<PaginationOptions>? paginationOptions;

  GetEventsRequest(this.startLedger, {this.filters, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (filters != null) {
      List<Map<String, dynamic>> values =
          List<Map<String, dynamic>>.empty(growable: true);
      for (EventFilter filter in filters!) {
        values.add(filter.getRequestArgs());
      }
      map['filters'] = values;
    }
    if (paginationOptions != null) {
      Map<String, dynamic> values = {};
      for (PaginationOptions options in paginationOptions!) {
        values.addAll(options.getRequestArgs());
      }
      map['pagination'] = values;
    }
    return map;
  }
}

/// Event filter for the getEvents request.
/// See: https://soroban.stellar.org/api/methods/getEvents
class EventFilter {
  /// (optional) A comma separated list of event types (system, contract, or diagnostic)
  /// used to filter events. If omitted, all event types are included.
  String? type;

  /// (optional) List of contract ids to query for events.
  /// If omitted, return events for all contracts.
  /// Maximum 5 contract IDs are allowed per request.
  List<String>? contractIds;

  /// (optional) List of topic filters. If omitted, query for all events.
  /// If multiple filters are specified, events will be included if they match any of the filters.
  /// Maximum 5 filters are allowed per request.
  List<TopicFilter>? topics;

  EventFilter({this.type, this.contractIds, this.topics});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (type != null) {
      map['type'] = type!;
    }
    if (contractIds != null) {
      map['contractIds'] = contractIds!;
    }
    if (topics != null) {
      List<List<String>> values = List<List<String>>.empty(growable: true);
      for (TopicFilter filter in topics!) {
        values.add(filter.getRequestArgs());
      }
      map['topics'] = values;
    }
    return map;
  }
}

/// Part of the getEvents request parameters.
/// https://soroban.stellar.org/api/methods/getEvents
/// ```dart
/// TopicFilter topicFilter = TopicFilter(
///           ["*", XdrSCVal.forSymbol('increment').toBase64EncodedXdrString()]);
/// ```
class TopicFilter {
  List<String> segmentMatchers;

  TopicFilter(this.segmentMatchers);

  List<String> getRequestArgs() {
    return this.segmentMatchers;
  }
}

class PaginationOptions {
  String? cursor;
  int? limit;

  PaginationOptions({this.cursor, this.limit});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (cursor != null) {
      map['cursor'] = cursor!;
    }
    if (limit != null) {
      map['limit'] = limit!;
    }
    return map;
  }
}

class GetEventsResponse extends SorobanRpcResponse {
  int? latestLedger;

  /// If error is present then results will not be in the response
  List<EventInfo>? events;

  GetEventsResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetEventsResponse.fromJson(Map<String, dynamic> json) {
    GetEventsResponse response = GetEventsResponse(json);
    if (json['result'] != null) {
      if (json['result']['events'] != null) {
        response.events = List<EventInfo>.from(
            json['result']['events'].map((e) => EventInfo.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

class EventInfo {
  String type;
  int ledger;
  String ledgerCloseAt;
  String contractId;
  String id;
  String paginationToken;
  List<String> topic;
  String value;
  bool inSuccessfulContractCall;

  EventInfo(
      this.type,
      this.ledger,
      this.ledgerCloseAt,
      this.contractId,
      this.id,
      this.paginationToken,
      this.topic,
      this.value,
      this.inSuccessfulContractCall);

  factory EventInfo.fromJson(Map<String, dynamic> json) {
    List<String> topic = List<String>.from(json['topic'].map((e) => e));
    String value = "";

    if (json['value'] is Map) {
      value = json['value']['xdr'];
    } else {
      value = json['value'];
    }

    return EventInfo(
        json['type'],
        json['ledger'],
        json['ledgerClosedAt'],
        json['contractId'],
        json['id'],
        json['pagingToken'],
        topic,
        value,
        json['inSuccessfulContractCall']);
  }
}

/// Information about the fees expected, instructions used, etc.
class SimulateTransactionCost {
  /// Stringified-number of the total cpu instructions consumed by this transaction
  int cpuInsns;

  /// Stringified-number of the total memory bytes allocated by this transaction
  int memBytes;

  SimulateTransactionCost(this.cpuInsns, this.memBytes);

  factory SimulateTransactionCost.fromJson(Map<String, dynamic> json) =>
      SimulateTransactionCost(
          convertInt(json['cpuInsns'])!, convertInt(json['memBytes'])!);
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
