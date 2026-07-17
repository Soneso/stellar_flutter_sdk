// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/src/responses/response.dart';
import '../xdr/xdr.dart';
import '../util.dart';
import 'soroban_auth.dart';
import 'soroban_ledger_event_responses.dart';
import 'soroban_rpc_requests.dart';
import 'soroban_rpc_responses.dart';

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

  /// Creates a RestorePreamble with restore operation parameters.
  ///
  /// Contains transaction data and resource fee for RestoreFootprint operation.
  RestorePreamble(this.transactionData, this.minResourceFee);

  factory RestorePreamble.fromJson(Map<String, dynamic> json) {
    XdrSorobanTransactionData transactionData =
        XdrSorobanTransactionData.fromBase64EncodedXdrString(
            json['transactionData']);

    int minResourceFee = convertInt(json['minResourceFee'])!;
    return RestorePreamble(transactionData, minResourceFee);
  }
}

/// Part of the simulate transaction response.
class LedgerEntryChange {
  /// Indicates if the entry was "created", "updated", or "deleted"
  String type;

  /// The XdrLedgerKey for this delta
  XdrLedgerKey key;

  /// if present - XdrLedgerEntry state prior to simulation
  XdrLedgerEntry? before;

  /// if present - XdrLedgerEntry state after simulation
  XdrLedgerEntry? after;

  /// Creates a LedgerEntryChange with delta information.
  ///
  /// Contains ledger entry change type and before/after states.
  LedgerEntryChange(this.type, this.key, {this.before, this.after});

  factory LedgerEntryChange.fromJson(Map<String, dynamic> json) {
    XdrLedgerKey key = XdrLedgerKey.fromBase64EncodedXdrString(json['key']);
    XdrLedgerEntry? before;
    if (json['before'] != null) {
      before = XdrLedgerEntry.fromBase64EncodedXdrString(json['before']);
    }
    XdrLedgerEntry? after;
    if (json['after'] != null) {
      after = XdrLedgerEntry.fromBase64EncodedXdrString(json['after']);
    }

    return LedgerEntryChange(json['type'], key, before: before, after: after);
  }
}

/// Response that will be received when submitting a trial contract invocation.
/// The response will include the anticipated affects the given transaction
/// will have on the network. Additionally, information needed to build, sign,
/// and actually submit the transaction will be provided.
///
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/simulateTransaction
class SimulateTransactionResponse extends SorobanRpcResponse {
  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedger;

  /// (optional) - This array will only have one element: the result for the
  /// Host Function invocation. Only present on successful simulation
  /// (i.e. no error) of InvokeHostFunction operations.
  List<SimulateTransactionResult>? results;

  /// The recommended Soroban Transaction Data to use when submitting the simulated transaction. This data contains the refundable fee and resource usage information such as the ledger footprint and IO access data.
  XdrSorobanTransactionData? transactionData;

  /// Recommended minimum resource fee to add when submitting the transaction. This fee is to be added on top of the Stellar network fee.
  int? minResourceFee;

  /// Array of the events emitted during the contract invocation(s). The events are ordered by their emission time. (an array of serialized base64 strings representing XdrDiagnosticEvent)
  /// Use [diagnosticEvents] for the decoded representation.
  List<String>? events;

  /// It can only present on successful simulation (i.e. no error) of InvokeHostFunction operations. If present, it indicates
  /// the simulation detected expired ledger entries which requires restoring with the submission of a RestoreFootprint
  /// operation before submitting the InvokeHostFunction operation. The restorePreamble.minResourceFee and restorePreamble.transactionData fields should
  /// be used to construct the transaction containing the RestoreFootprint
  RestorePreamble? restorePreamble;

  /// (optional) - On successful simulation of InvokeHostFunction operations,
  /// this field will be an array of LedgerEntrys before and after simulation occurred.
  List<LedgerEntryChange>? stateChanges;

  /// Creates a SimulateTransactionResponse from JSON-RPC response.
  ///
  /// Contains simulation results, resource estimates, and auth requirements.
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

      if (json['result']['stateChanges'] != null) {
        response.stateChanges = List<LedgerEntryChange>.from(json['result']
                ['stateChanges']
            .map((e) => LedgerEntryChange.fromJson(e)));
      }

      response.minResourceFee = convertInt(json['result']['minResourceFee']);
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }

  /// Returns the footprint from the transaction data if available.
  Footprint? getFootprint() {
    if (transactionData != null) {
      return Footprint(transactionData!.resources.footprint);
    }
    return null;
  }

  Footprint? get footprint => getFootprint();

  /// Returns the soroban authorization entries if available.
  List<SorobanAuthorizationEntry>? getSorobanAuth() {
    if (results != null && results!.length > 0) {
      List<SorobanAuthorizationEntry> result =
          List<SorobanAuthorizationEntry>.empty(growable: true);
      for (String nextAuthXdr in results![0].auth) {
        result.add(SorobanAuthorizationEntry.fromBase64EncodedXdr(nextAuthXdr));
      }
      return result;
    }
    return null;
  }

  List<SorobanAuthorizationEntry>? get sorobanAuth => getSorobanAuth();

  /// Returns the events emitted during the contract invocation(s) decoded
  /// from the base64 strings in [events], ordered by their emission time.
  /// Returns null if the simulation reported no events.
  List<XdrDiagnosticEvent>? getDiagnosticEvents() {
    if (events != null && events!.length > 0) {
      List<XdrDiagnosticEvent> result =
          List<XdrDiagnosticEvent>.empty(growable: true);
      for (String nextXdr in events!) {
        result.add(XdrDiagnosticEvent.fromBase64EncodedXdrString(nextXdr));
      }
      return result;
    }
    return null;
  }

  List<XdrDiagnosticEvent>? get diagnosticEvents => getDiagnosticEvents();
}

/// Used as a part of simulate transaction.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/simulateTransaction
class SimulateTransactionResult {
  /// Serialized base64 string - return value of the Host Function call.
  String xdr;

  /// Array of serialized base64 strings - Per-address authorizations recorded when simulating this Host Function call.
  List<String> auth;

  /// Creates a SimulateTransactionResult with invocation result.
  ///
  /// Contains return value and authorization entries from simulation.
  SimulateTransactionResult(this.xdr, this.auth);

  factory SimulateTransactionResult.fromJson(Map<String, dynamic> json) {
    String xdr = json['xdr'];
    List<String> auth = List<String>.from(json['auth'].map((e) => e));
    return SimulateTransactionResult(xdr, auth);
  }

  ///  Only present on success. Return value of the contract call operation.
  XdrSCVal? get resultValue => XdrSCVal.fromBase64EncodedXdrString(xdr);
}

/// Response when submitting a real transaction to the stellar network.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/sendTransaction
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

  /// Creates a SendTransactionResponse from JSON-RPC response.
  ///
  /// Contains transaction hash and submission status.
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
/// See https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getTransaction
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

  /// hex-encoded transaction hash string. Only available for protocol version >= 22
  String? txHash;

  /// events for the transaction. Only available for protocol version >= 23
  TransactionEvents? events;

  /// Creates a GetTransactionResponse from JSON-RPC response.
  ///
  /// Contains transaction status and execution details.
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
      response.txHash = json['result']['txHash'];
      if (json['result']['events'] != null) {
        response.events = TransactionEvents.fromJson(json['result']['events']);
      }
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

  XdrTransactionEnvelope? get xdrTransactionEnvelope => envelopeXdr == null
      ? null
      : XdrTransactionEnvelope.fromEnvelopeXdrString(envelopeXdr!);

  XdrTransactionResult? get xdrTransactionResult => resultXdr == null
      ? null
      : XdrTransactionResult.fromBase64EncodedXdrString(resultXdr!);

  XdrTransactionMeta? get xdrTransactionMeta => resultMetaXdr == null
      ? null
      : XdrTransactionMeta.fromBase64EncodedXdrString(resultMetaXdr!);

  /// Extracts the result value from the first entry on success
  XdrSCVal? getResultValue() {
    if (error != null || status != STATUS_SUCCESS || resultMetaXdr == null) {
      return null;
    }

    XdrTransactionMeta meta =
        XdrTransactionMeta.fromBase64EncodedXdrString(resultMetaXdr!);

    if (meta.v3 != null) {
      return meta.v3!.sorobanMeta?.returnValue;
    }
    return meta.v4?.sorobanMeta?.returnValue;
  }

  String? _getBinHex() {
    XdrSCBytes? bin = _getBin();
    if (bin != null) {
      return Util.bytesToHex(bin.sCBytes);
    }
    return null;
  }

  XdrSCBytes? _getBin() {
    XdrSCVal? xdrVal = getResultValue();
    return xdrVal?.bytes;
  }
}

/// Response from the getTransactions RPC method.
///
/// GetTransactionsResponse contains a paginated list of transactions that occurred
/// within a specified ledger range. This method allows retrieving historical transaction
/// data including successful and failed transactions, their results, and associated events.
///
/// The response provides comprehensive transaction information with pagination support
/// for efficient data retrieval when dealing with large result sets.
///
/// Response Structure:
/// - List of [TransactionInfo] objects with full transaction details
/// - Pagination cursor for fetching subsequent pages
/// - Ledger range boundaries (oldest and latest ledgers available)
/// - Timestamps for ledger close times
///
/// Use Cases:
/// - Retrieve transaction history for analysis
/// - Monitor contract invocations and their results
/// - Audit transaction execution and events
/// - Build transaction explorers and analytics tools
///
/// Fields:
/// - [transactions]: List of transactions in the queried range
/// - [latestLedger]: Latest ledger sequence available on RPC server
/// - [latestLedgerCloseTimestamp]: Unix timestamp of latest ledger close
/// - [oldestLedger]: Oldest ledger sequence available on RPC server
/// - [oldestLedgerCloseTimestamp]: Unix timestamp of oldest ledger close
/// - [cursor]: Pagination cursor for fetching next page
///
/// Example:
/// ```dart
/// final server = SorobanServer(rpcUrl);
///
/// // Query transactions from a specific ledger
/// final request = GetTransactionsRequest(
///   startLedger: 1000000,
///   paginationOptions: PaginationOptions(limit: 50),
/// );
///
/// final response = await server.getTransactions(request);
///
/// if (response.transactions != null) {
///   for (var tx in response.transactions!) {
///     print('Transaction: ${tx.txHash}');
///     print('Status: ${tx.status}');
///     print('Ledger: ${tx.ledger}');
///     if (tx.events != null) {
///       print('Contract events: ${tx.events!.contractEventsXdr?.length}');
///     }
///   }
///
///   // Fetch next page if available
///   if (response.cursor != null) {
///     final nextRequest = GetTransactionsRequest(
///       paginationOptions: PaginationOptions(cursor: response.cursor),
///     );
///     final nextPage = await server.getTransactions(nextRequest);
///   }
/// }
/// ```
///
/// See also:
/// - [TransactionInfo] for individual transaction details
/// - [GetTransactionsRequest] for request parameters
/// - [PaginationOptions] for pagination control
/// - [Soroban RPC Documentation](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getTransactions)
class GetTransactionsResponse extends SorobanRpcResponse {
  int? latestLedger;
  int? latestLedgerCloseTimestamp;
  int? oldestLedger;
  int? oldestLedgerCloseTimestamp;
  String? cursor;

  /// If error is present then results will not be in the response
  List<TransactionInfo>? transactions;

  /// Creates a GetTransactionsResponse from JSON-RPC response.
  ///
  /// Contains paginated list of transactions with metadata.
  GetTransactionsResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetTransactionsResponse.fromJson(Map<String, dynamic> json) {
    GetTransactionsResponse response = GetTransactionsResponse(json);
    if (json['result'] != null) {
      if (json['result']['transactions'] != null) {
        response.transactions = List<TransactionInfo>.from(json['result']
                ['transactions']
            .map((e) => TransactionInfo.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
      response.latestLedgerCloseTimestamp =
          json['result']['latestLedgerCloseTimestamp'];
      response.oldestLedger = json['result']['oldestLedger'];
      response.oldestLedgerCloseTimestamp =
          json['result']['oldestLedgerCloseTimestamp'];
      response.cursor = json['result']['cursor'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Detailed information about a single transaction on the Soroban network.
///
/// TransactionInfo contains comprehensive data about a transaction including its execution
/// status, results, events, and XDR-encoded data. This class provides both raw transaction
/// data and decoded information for analysis and processing.
///
/// Transaction Status Values:
/// - [STATUS_SUCCESS]: Transaction executed successfully
/// - [STATUS_FAILED]: Transaction failed during execution
/// - [STATUS_NOT_FOUND]: Transaction not found in ledger history
///
/// The class includes:
/// - Execution metadata (status, ledger, timestamp)
/// - XDR-encoded transaction data (envelope, result, metadata)
/// - Transaction events (contract events, diagnostic events)
/// - Transaction hash for identification
///
/// Fields:
/// - [status]: Execution status (SUCCESS, FAILED, or NOT_FOUND)
/// - [applicationOrder]: Order of application within the ledger
/// - [feeBump]: Whether this is a fee-bump transaction
/// - [envelopeXdr]: Base64-encoded transaction envelope XDR
/// - [resultXdr]: Base64-encoded transaction result XDR
/// - [resultMetaXdr]: Base64-encoded transaction metadata XDR
/// - [ledger]: Ledger sequence number containing the transaction
/// - [createdAt]: Unix timestamp when transaction was included
/// - [txHash]: Transaction hash (protocol 23+)
/// - [diagnosticEventsXdr]: Diagnostic events (deprecated, protocol < 24)
/// - [events]: Transaction events including contract events (protocol 23+)
///
/// Example - Analyzing transaction results:
/// ```dart
/// final response = await server.getTransactions(request);
///
/// for (var txInfo in response.transactions!) {
///   print('Transaction ${txInfo.txHash}');
///   print('Status: ${txInfo.status}');
///   print('Ledger: ${txInfo.ledger}');
///   print('Created: ${DateTime.fromMillisecondsSinceEpoch(txInfo.createdAt * 1000)}');
///
///   if (txInfo.status == TransactionInfo.STATUS_SUCCESS) {
///     // Decode transaction result
///     final result = XdrTransactionResult.fromBase64EncodedXdrString(txInfo.resultXdr);
///
///     // Process contract events
///     if (txInfo.events?.contractEventsXdr != null) {
///       for (var eventList in txInfo.events!.contractEventsXdr!) {
///         print('Contract emitted ${eventList.length} events');
///       }
///     }
///   } else {
///     print('Transaction failed with result: ${txInfo.resultXdr}');
///   }
/// }
/// ```
///
/// Example - Extracting transaction metadata:
/// ```dart
/// if (txInfo.status == TransactionInfo.STATUS_SUCCESS) {
///   final meta = XdrTransactionMeta.fromBase64EncodedXdrString(txInfo.resultMetaXdr);
///
///   // Access Soroban-specific metadata
///   if (meta.v3?.sorobanMeta != null) {
///     final sorobanMeta = meta.v3!.sorobanMeta!;
///     final returnValue = sorobanMeta.returnValue;
///     print('Contract returned: $returnValue');
///   }
/// }
/// ```
///
/// See also:
/// - [GetTransactionsResponse] for querying transactions
/// - [TransactionEvents] for event details
/// - [XdrTransactionMeta] for decoded metadata structure
class TransactionInfo {
  static const String STATUS_SUCCESS = "SUCCESS";
  static const String STATUS_NOT_FOUND = "NOT_FOUND";
  static const String STATUS_FAILED = "FAILED";

  /// Transaction execution status (SUCCESS, NOT_FOUND, or FAILED).
  String status;

  /// Order in which this transaction was applied in the ledger.
  int applicationOrder;

  /// Whether this transaction is a fee bump transaction.
  bool feeBump;

  /// Base64-encoded transaction envelope XDR.
  String envelopeXdr;

  /// Base64-encoded transaction result XDR.
  String resultXdr;

  /// Base64-encoded transaction result metadata XDR.
  String resultMetaXdr;

  /// Ledger sequence number when this transaction was applied.
  int ledger;

  /// Unix timestamp when this transaction was created.
  int createdAt;

  /// hex-encoded transaction hash string. Only available for protocol version > 22
  String? txHash;

  /// deprecated and will be removed in protocol 24
  List<String>? diagnosticEventsXdr;

  /// events for the transaction. Only available for protocol version >= 23
  TransactionEvents? events;

  /// Creates a TransactionInfo with transaction execution details.
  ///
  /// Contains complete transaction metadata including status, XDR, and events.
  TransactionInfo(
      this.status,
      this.applicationOrder,
      this.feeBump,
      this.envelopeXdr,
      this.resultXdr,
      this.resultMetaXdr,
      this.ledger,
      this.createdAt,
      this.txHash,
      this.diagnosticEventsXdr,
      this.events);

  factory TransactionInfo.fromJson(Map<String, dynamic> json) {
    List<String>? diagnosticEventsXdr = json.containsKey('diagnosticEventsXdr')
        ? List<String>.from(json['diagnosticEventsXdr'].map((e) => e))
        : null;

    int createdAt = 0;
    if (json['createdAt'] is int) {
      createdAt = json['createdAt'];
    } else {
      createdAt = convertInt(json['createdAt']) ?? 0;
    }

    TransactionEvents? events;
    if (json['events'] != null) {
      events = TransactionEvents.fromJson(json['events']);
    }

    return TransactionInfo(
      json['status'],
      json['applicationOrder'],
      json['feeBump'],
      json['envelopeXdr'],
      json['resultXdr'],
      json['resultMetaXdr'],
      json['ledger'],
      createdAt,
      json['txHash'],
      diagnosticEventsXdr,
      events,
    );
  }

  XdrTransactionEnvelope get xdrTransactionEnvelope =>
      XdrTransactionEnvelope.fromEnvelopeXdrString(envelopeXdr);

  XdrTransactionResult get xdrTransactionResult =>
      XdrTransactionResult.fromBase64EncodedXdrString(resultXdr);

  XdrTransactionMeta get xdrTransactionMeta =>
      XdrTransactionMeta.fromBase64EncodedXdrString(resultMetaXdr);

  /// Extracts the result value from the first entry on success
  XdrSCVal? getResultValue() {
    if (status != STATUS_SUCCESS) {
      return null;
    }

    return xdrTransactionMeta.v3?.sorobanMeta?.returnValue;
  }
}

/// Events emitted during transaction execution on the Soroban network.
///
/// TransactionEvents contains XDR-encoded events generated during smart contract execution.
/// Events are organized by type and provide visibility into contract behavior, state changes,
/// and diagnostic information. This data is essential for monitoring, debugging, and
/// analyzing contract interactions.
///
/// Event Categories:
///
/// Diagnostic Events ([diagnosticEventsXdr]):
/// - Internal events for debugging and diagnostics
/// - Include contract logging and system information
/// - Useful for troubleshooting failed transactions
///
/// Transaction Events ([transactionEventsXdr]):
/// - General transaction-level events
/// - System-generated events during transaction processing
///
/// Contract Events ([contractEventsXdr]):
/// - Events explicitly emitted by smart contracts
/// - Organized as nested lists (one list per operation)
/// - Used for application-level notifications and state tracking
/// - Can be filtered and subscribed to via getEvents RPC method
///
/// All events are base64-encoded XDR strings that can be decoded using XdrContractEvent
/// or XdrDiagnosticEvent for analysis.
///
/// Fields:
/// - [diagnosticEventsXdr]: Base64-encoded diagnostic events
/// - [transactionEventsXdr]: Base64-encoded transaction events
/// - [contractEventsXdr]: Nested lists of base64-encoded contract events per operation
///
/// Example - Processing transaction events:
/// ```dart
/// final txInfo = response.transactions!.first;
///
/// if (txInfo.events != null) {
///   final events = txInfo.events!;
///
///   // Process diagnostic events
///   if (events.diagnosticEventsXdr != null) {
///     for (var eventXdr in events.diagnosticEventsXdr!) {
///       final event = XdrDiagnosticEvent.fromBase64EncodedXdrString(eventXdr);
///       print('Diagnostic: ${event.inSuccessfulContractCall}');
///     }
///   }
///
///   // Process contract events
///   if (events.contractEventsXdr != null) {
///     for (var operationEvents in events.contractEventsXdr!) {
///       print('Operation emitted ${operationEvents.length} events');
///       for (var eventXdr in operationEvents) {
///         final event = XdrContractEvent.fromBase64EncodedXdrString(eventXdr);
///         print('Contract ID: ${event.contractId}');
///         print('Topics: ${event.body.v0?.topics.length}');
///       }
///     }
///   }
/// }
/// ```
///
/// Example - Filtering for specific contract events:
/// ```dart
/// if (events.contractEventsXdr != null) {
///   for (var opEvents in events.contractEventsXdr!) {
///     for (var eventXdr in opEvents) {
///       final event = XdrContractEvent.fromBase64EncodedXdrString(eventXdr);
///
///       // Filter by contract ID
///       if (event.contractId == targetContractId) {
///         // Process event data
///         final data = event.body.v0?.data;
///         print('Event data: $data');
///       }
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [TransactionInfo] for parent transaction details
/// - [EventInfo] for individual event details from getEvents
/// - [XdrContractEvent] for decoding contract events
/// - [XdrDiagnosticEvent] for decoding diagnostic events
class TransactionEvents {
  List<String>? diagnosticEventsXdr;
  List<String>? transactionEventsXdr;
  List<List<String>>? contractEventsXdr;

  /// Creates a TransactionEvents with event XDR lists.
  ///
  /// Contains diagnostic, transaction, and contract event data.
  TransactionEvents(this.diagnosticEventsXdr, this.transactionEventsXdr,
      this.contractEventsXdr);

  factory TransactionEvents.fromJson(Map<String, dynamic> json) {
    List<String>? diagnosticEventsXdr = json.containsKey('diagnosticEventsXdr')
        ? List<String>.from(json['diagnosticEventsXdr'].map((e) => e))
        : null;
    List<String>? transactionEventsXdr =
        json.containsKey('transactionEventsXdr')
            ? List<String>.from(json['transactionEventsXdr'].map((e) => e))
            : null;

    List<List<String>>? contractEventsXdr;
    if (json.containsKey('contractEventsXdr')) {
      final allContractEvents =
          List<dynamic>.from(json['contractEventsXdr'].map((e) => e));
      contractEventsXdr = List<List<String>>.empty(growable: true);
      for (final entry in allContractEvents) {
        if (entry is List) {
          final nextList = List<String>.empty(growable: true);
          for (final subEntry in entry) {
            if (subEntry is String) {
              nextList.add(subEntry);
            }
          }
          contractEventsXdr.add(nextList);
        }
      }
    }
    return TransactionEvents(
        diagnosticEventsXdr, transactionEventsXdr, contractEventsXdr);
  }
}

/// Footprint received when simulating a transaction.
/// Contains utility functions.
class Footprint {
  XdrLedgerFootprint xdrFootprint;

  /// Creates a Footprint with XDR ledger footprint.
  ///
  /// Contains ledger keys accessed by the transaction.
  Footprint(this.xdrFootprint);

  /// Converts this footprint to base64-encoded XDR format.
  String toBase64EncodedXdrString() {
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrLedgerFootprint.encode(xdrOutputStream, this.xdrFootprint);
    return base64Encode(xdrOutputStream.bytes);
  }

  /// Creates a footprint from base64-encoded XDR.
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
