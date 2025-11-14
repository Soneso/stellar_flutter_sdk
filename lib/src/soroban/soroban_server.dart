// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:io' as IO;
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:dio/io.dart';
import 'package:stellar_flutter_sdk/src/account.dart';
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/responses/response.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_contract_parser.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_account.dart';
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

/// Client for interacting with a Soroban RPC server.
///
/// SorobanServer provides methods to interact with Stellar's smart contract platform (Soroban)
/// through its RPC interface. Use this class to simulate transactions, submit them to the network,
/// query contract state, retrieve events, and manage contract deployments.
///
/// The Soroban RPC server is separate from Horizon and provides specialized endpoints for
/// smart contract operations including transaction simulation, resource footprint calculation,
/// and contract state queries.
///
/// Parameters:
/// - [_serverUrl]: URL of the Soroban RPC server endpoint
///
/// Example:
/// ```dart
/// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
///
/// // Check server health
/// final health = await server.getHealth();
/// if (health.status == GetHealthResponse.HEALTHY) {
///   print('Server is healthy');
/// }
///
/// // Get network information
/// final network = await server.getNetwork();
/// print('Network passphrase: ${network.passphrase}');
///
/// // Simulate a transaction
/// final simulation = await server.simulateTransaction(request);
/// final resourceFee = simulation.minResourceFee;
/// ```
///
/// See also:
/// - [Soroban RPC API Reference](https://developers.stellar.org/network/soroban-rpc/api-reference)
/// - [SorobanClient] for higher-level contract interaction
/// - [AssembledTransaction] for transaction building and signing
class SorobanServer {
  bool enableLogging = false;

  String _serverUrl;
  late Map<String, String> _headers;
  dio.Dio _dio = dio.Dio();

  /// Creates a SorobanServer instance with explicit RPC server URL.
  ///
  /// Initializes the client with default HTTP headers for JSON-RPC communication.
  /// For most use cases, this is the primary constructor for connecting to Soroban RPC endpoints.
  SorobanServer(this._serverUrl) {
    _headers = {...RequestBuilder.headers};
    _headers.putIfAbsent("Content-Type", () => "application/json");
  }

  /// Dio HTTP Overrides
  /// Enable overrides to handle badCertificateCallback.
  /// Available only for the non-Web platform.
  ///
  /// WARNING: Only use for LOCAL DEVELOPMENT with self-signed certificates
  /// NEVER enable this in production - it disables TLS certificate validation
  /// This makes your app vulnerable to man-in-the-middle attacks where an
  /// attacker could intercept network traffic and read/modify responses.
  ///
  /// While signed transactions cannot be modified (signature validation protects
  /// against transaction tampering), an attacker could still:
  /// - Manipulate simulation results (fake fee estimates, contract data)
  /// - Monitor your transaction patterns (privacy leak)
  /// - Return fake account balances or transaction statuses
  ///
  /// This setting should ONLY be used when testing against local Soroban RPC
  /// servers with self-signed certificates during development.
  set httpOverrides(bool setOverrides) {
    if (!kIsWeb && setOverrides) {
      print('');
      print('================================================================');
      print('WARNING: TLS certificate validation is DISABLED');
      print('This should ONLY be used in local development environments');
      print('Your connection is NOT secure against man-in-the-middle attacks');
      print('NEVER use this setting in production builds');
      print('================================================================');
      print('');

      dio.Dio dioOverrides = dio.Dio();
      final adapter = dioOverrides.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = IO.HttpClient();
          client.badCertificateCallback = (cert, host, port) {
            return true;
          };
          return client;
        };
      }
      _dio = dioOverrides;
    }
  }

  /// Retrieves the health status of the Soroban RPC server.
  ///
  /// This method performs a general health check to determine if the RPC server is operational
  /// and responsive. Use this to verify server availability before making other requests.
  ///
  /// Returns: GetHealthResponse containing:
  /// - status: Health status string (typically "healthy" when operational)
  /// - ledgerRetentionWindow: Maximum number of ledgers retained by this node
  /// - latestLedger: Most recent ledger sequence number known to the server
  /// - oldestLedger: Oldest ledger sequence number stored by the server
  ///
  /// The retention window indicates how far back in history you can query. If you need to access
  /// ledgers outside this window, you may need to use a different data source like Horizon.
  ///
  /// Throws:
  /// - Exception: If the network request fails or the server is unreachable
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final health = await server.getHealth();
  ///
  /// if (health.status == GetHealthResponse.HEALTHY) {
  ///   print('Server is healthy');
  ///   print('Retention window: ${health.ledgerRetentionWindow} ledgers');
  ///   print('Latest ledger: ${health.latestLedger}');
  /// } else {
  ///   print('Server health check failed');
  /// }
  /// ```
  ///
  /// See also:
  /// - [GetHealthResponse] for response details
  /// - [Soroban RPC getHealth](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getHealth)
  Future<GetHealthResponse> getHealth() async {
    JsonRpcMethod getHealth = JsonRpcMethod("getHealth");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getHealth), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getHealth response: $response");
    }
    return GetHealthResponse.fromJson(response.data);
  }

  /// Retrieves version information about the Soroban RPC server and Captive Core.
  ///
  /// This method returns detailed version information about the RPC server software and the
  /// embedded Captive Core instance it uses. RPC manages its own optimized version of Stellar
  /// Core (Captive Core) that is tailored for RPC operations.
  ///
  /// Use this to verify server compatibility, debug issues, or ensure you're running the
  /// expected version of the software.
  ///
  /// Returns: GetVersionInfoResponse containing:
  /// - version: RPC server version string
  /// - commitHash: Git commit hash of the RPC server build
  /// - buildTimeStamp: ISO 8601 timestamp when the server was built
  /// - captiveCoreVersion: Version of the embedded Stellar Core
  /// - protocolVersion: Stellar protocol version supported by this server
  ///
  /// The protocol version is particularly important as it determines which Soroban features
  /// are available and how transactions should be structured.
  ///
  /// Throws:
  /// - Exception: If the network request fails or the server is unreachable
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final versionInfo = await server.getVersionInfo();
  ///
  /// print('RPC Version: ${versionInfo.version}');
  /// print('Protocol Version: ${versionInfo.protocolVersion}');
  /// print('Captive Core: ${versionInfo.captiveCoreVersion}');
  /// print('Build Time: ${versionInfo.buildTimeStamp}');
  /// ```
  ///
  /// See also:
  /// - [GetVersionInfoResponse] for response details
  /// - [Soroban RPC getVersionInfo](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getVersionInfo)
  Future<GetVersionInfoResponse> getVersionInfo() async {
    JsonRpcMethod getVersionInfo = JsonRpcMethod("getVersionInfo");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getVersionInfo),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getVersionInfo response: $response");
    }
    return GetVersionInfoResponse.fromJson(response.data);
  }

  /// Retrieves statistical information about inclusion fees charged by the network.
  ///
  /// This method returns fee statistics based on recent transactions that were successfully
  /// included in ledgers. The data helps you determine appropriate fees for your transactions
  /// to ensure timely inclusion during both normal and high-traffic periods.
  ///
  /// Soroban transactions and classic Stellar transactions have separate fee pools with
  /// independent surge pricing. This prevents smart contract activity from affecting
  /// the fees for regular Stellar operations and vice versa.
  ///
  /// Fee statistics are essential for:
  /// - Setting competitive transaction fees
  /// - Understanding current network congestion
  /// - Implementing dynamic fee strategies
  /// - Avoiding transaction delays during traffic surges
  ///
  /// Returns: GetFeeStatsResponse containing:
  /// - sorobanInclusionFee: Fee statistics for Soroban smart contract transactions
  /// - inclusionFee: Fee statistics for classic Stellar transactions (per operation)
  /// - latestLedger: Latest ledger sequence number when stats were calculated
  ///
  /// Each InclusionFee object provides percentile distribution (p10-p99), min/max values,
  /// mode, transaction count, and ledger count for the statistical sample.
  ///
  /// Throws:
  /// - Exception: If the network request fails or the server is unreachable
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final feeStats = await server.getFeeStats();
  ///
  /// if (feeStats.sorobanInclusionFee != null) {
  ///   final fee = feeStats.sorobanInclusionFee!;
  ///   print('Soroban fee median (p50): ${fee.p50} stroops');
  ///   print('Soroban fee 90th percentile: ${fee.p90} stroops');
  ///   print('Sample size: ${fee.transactionCount} transactions');
  /// }
  /// ```
  ///
  /// See also:
  /// - [GetFeeStatsResponse] for response details
  /// - [InclusionFee] for fee distribution data
  /// - [Soroban RPC getFeeStats](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getFeeStats)
  Future<GetFeeStatsResponse> getFeeStats() async {
    JsonRpcMethod getFeeStats = JsonRpcMethod("getFeeStats");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getFeeStats),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getFeeStats response: $response");
    }
    return GetFeeStatsResponse.fromJson(response.data);
  }

  /// Retrieves information about the latest ledger known to the Soroban RPC server.
  ///
  /// This method returns the most recent ledger that has been processed and is available
  /// through this RPC server. Use this to:
  /// - Verify the server is keeping up with the network
  /// - Get the current ledger sequence for time-sensitive operations
  /// - Determine if specific ledgers are available for queries
  /// - Monitor ledger progression over time
  ///
  /// The latest ledger represents the most recent state of the blockchain that this
  /// server knows about. There may be a small delay between network consensus and
  /// when an RPC server processes the ledger.
  ///
  /// Returns: GetLatestLedgerResponse containing:
  /// - id: Hash of the latest ledger (hex-encoded string)
  /// - protocolVersion: Stellar protocol version for this ledger
  /// - sequence: Ledger sequence number (increments with each ledger)
  ///
  /// Throws:
  /// - Exception: If the network request fails or the server is unreachable
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final latestLedger = await server.getLatestLedger();
  ///
  /// print('Latest ledger sequence: ${latestLedger.sequence}');
  /// print('Ledger hash: ${latestLedger.id}');
  /// print('Protocol version: ${latestLedger.protocolVersion}');
  ///
  /// // Check if server is up to date by comparing with another source
  /// ```
  ///
  /// See also:
  /// - [GetLatestLedgerResponse] for response details
  /// - [getLedgers] to retrieve multiple ledgers with details
  /// - [Soroban RPC getLatestLedger](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getLatestLedger)
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

  /// Reads ledger entries directly from the current ledger state.
  ///
  /// This method allows direct inspection of any ledger entry including contract data,
  /// contract code, accounts, and other ledger entries. Use this to:
  /// - Read contract instance data
  /// - Fetch contract wasm bytecode
  /// - Access contract storage
  /// - Get account information
  ///
  /// This is useful when data is not available through events or simulation, or when
  /// you need the current state directly.
  ///
  /// Parameters:
  /// - [base64EncodedKeys]: List of base64-encoded XdrLedgerKey values identifying the entries
  ///
  /// Returns: GetLedgerEntriesResponse containing:
  /// - entries: List of LedgerEntry objects with current state
  /// - latestLedger: Latest ledger sequence number
  ///
  /// Each LedgerEntry provides:
  /// - key: The ledger entry key
  /// - xdr: Current value (base64-encoded)
  /// - lastModifiedLedgerSeq: When the entry was last modified
  /// - liveUntilLedgerSeq: Expiration ledger (for contract entries)
  ///
  /// Throws:
  /// - Exception: If the RPC request fails
  ///
  /// Example:
  /// ```dart
  /// // Read contract data
  /// final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
  /// ledgerKey.contractData = XdrLedgerKeyContractData(
  ///   Address.forContractId(contractId).toXdr(),
  ///   storageKey,
  ///   XdrContractDataDurability.PERSISTENT,
  /// );
  ///
  /// final response = await server.getLedgerEntries([
  ///   ledgerKey.toBase64EncodedXdrString()
  /// ]);
  ///
  /// if (response.entries != null && response.entries!.isNotEmpty) {
  ///   final entry = response.entries!.first;
  ///   final data = entry.ledgerEntryDataXdr;
  ///   print('Contract data: ${data.contractData?.val}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getContractData] for simplified contract data access
  /// - [loadContractCodeForContractId] for loading contract code
  /// - [Soroban RPC getLedgerEntries](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getLedgerEntries)
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

  /// Fetches current account information from the ledger state.
  ///
  /// This method retrieves essential account data needed for transaction building, particularly
  /// the current sequence number. Every Stellar transaction requires the source account's
  /// sequence number to prevent replay attacks and ensure transaction ordering.
  ///
  /// Unlike Horizon's account endpoint, this returns only the minimal information stored
  /// in the ledger: the account ID and sequence number. For detailed account information
  /// including balances, signers, and flags, use Horizon instead.
  ///
  /// Parameters:
  /// - [accountId]: The account ID (public key) to query, in Stellar address format (G...)
  ///
  /// Returns: Account object containing:
  /// - accountId: The account's public key
  /// - sequenceNumber: Current sequence number for transaction building
  ///
  /// Returns null if the account does not exist on the network. This typically means:
  /// - The account has never been created (never received XLM)
  /// - The account was merged into another account
  ///
  /// Throws:
  /// - [dio.DioException]: On network failures or RPC errors
  /// - [FormatException]: If the response cannot be parsed
  /// - [Exception]: If accountId is invalid or ledger entry decoding fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final accountId = 'GDAT5...';
  ///
  /// final account = await server.getAccount(accountId);
  /// if (account != null) {
  ///   // Use account to build transaction
  ///   final tx = TransactionBuilder(account)
  ///     .addOperation(operation)
  ///     .build();
  /// } else {
  ///   print('Account does not exist');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getLedgerEntries] for querying other ledger entry types
  /// - [Account] for the returned account object
  /// - Horizon API for detailed account information
  Future<Account?> getAccount(String accountId) async {
    XdrLedgerKey ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
    ledgerKey.account = XdrLedgerKeyAccount(
        XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey));
    GetLedgerEntriesResponse ledgerEntriesResponse =
        await getLedgerEntries([ledgerKey.toBase64EncodedXdrString()]);

    if (ledgerEntriesResponse.entries != null &&
        ledgerEntriesResponse.entries!.length > 0) {
      var accountEntry =
          ledgerEntriesResponse.entries![0].ledgerEntryDataXdr.account;
      if (accountEntry != null) {
        String accountId =
            KeyPair.fromXdrPublicKey(accountEntry.accountID.accountID)
                .accountId;
        BigInt seqNr = accountEntry.seqNum.sequenceNumber.bigInt;
        return Account(accountId, seqNr);
      }
    }
    return null;
  }

  /// Reads the current value of contract data from the ledger state.
  ///
  /// This method retrieves data stored by a smart contract in its persistent or temporary
  /// storage. Soroban contracts can store data in two durability tiers with different
  /// characteristics and costs:
  /// - PERSISTENT: Data that should remain indefinitely (requires rent payments)
  /// - TEMPORARY: Short-lived data that expires automatically (lower fees)
  ///
  /// Use this to query contract state directly without invoking contract functions.
  ///
  /// Parameters:
  /// - [contractId]: Contract ID (hex-encoded hash) of the contract containing the data
  /// - [key]: Storage key as XdrSCVal identifying which data to retrieve
  /// - [durability]: Storage tier where the data is stored:
  ///   - XdrContractDataDurability.PERSISTENT for long-term storage
  ///   - XdrContractDataDurability.TEMPORARY for ephemeral storage
  ///
  /// Returns: LedgerEntry containing:
  /// - key: The ledger entry key (base64-encoded)
  /// - xdr: Current value of the data (base64-encoded XdrLedgerEntryData)
  /// - lastModifiedLedgerSeq: Ledger when this entry was last modified
  /// - liveUntilLedgerSeq: Ledger when this entry expires (if applicable)
  ///
  /// Returns null if the contract data entry does not exist. This may occur if:
  /// - The key was never written
  /// - The entry expired (for temporary data)
  /// - The entry was archived and needs restoration
  ///
  /// Throws:
  /// - Exception: If the RPC request fails or data cannot be decoded
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final contractId = 'c5b1...'; // hex-encoded contract ID
  ///
  /// // Create storage key
  /// final key = XdrSCVal.forSymbol('counter');
  ///
  /// // Read persistent contract data
  /// final entry = await server.getContractData(
  ///   contractId,
  ///   key,
  ///   XdrContractDataDurability.PERSISTENT,
  /// );
  ///
  /// if (entry != null) {
  ///   final value = entry.ledgerEntryDataXdr.contractData?.val;
  ///   print('Contract data value: $value');
  /// } else {
  ///   print('Contract data not found');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getLedgerEntries] for querying multiple entries at once
  /// - [XdrContractDataDurability] for storage tier options
  /// - [Soroban storage documentation](https://developers.stellar.org/docs/smart-contracts/storage)
  Future<LedgerEntry?> getContractData(String contractId, XdrSCVal key,
      XdrContractDataDurability durability) async {
    XdrLedgerKey ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
    ledgerKey.contractData = XdrLedgerKeyContractData(
        Address.forContractId(contractId).toXdr(), key, durability);
    GetLedgerEntriesResponse ledgerEntriesResponse =
        await getLedgerEntries([ledgerKey.toBase64EncodedXdrString()]);
    if (ledgerEntriesResponse.entries != null &&
        ledgerEntriesResponse.entries!.length > 0) {
      return ledgerEntriesResponse.entries![0];
    }
    return null;
  }

  /// Loads the WebAssembly bytecode for a contract given its Wasm ID.
  ///
  /// This method retrieves the contract code entry containing the compiled WebAssembly
  /// bytecode. The Wasm ID is the hash of the contract bytecode and serves as its
  /// unique identifier in the ledger.
  ///
  /// Use this when you know the Wasm ID directly (for example, from a contract instance
  /// or from an upload transaction result).
  ///
  /// Parameters:
  /// - [wasmId]: Hex-encoded hash of the contract WebAssembly bytecode
  ///
  /// Returns: XdrContractCodeEntry containing:
  /// - code: DataValue with the raw WebAssembly bytecode
  /// - ext: Extension field for future protocol upgrades
  ///
  /// Returns null if no contract code exists with the given Wasm ID.
  ///
  /// Throws:
  /// - Exception: If the RPC request fails or XDR decoding fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final wasmId = 'f3b5...'; // hex-encoded wasm hash
  ///
  /// final codeEntry = await server.loadContractCodeForWasmId(wasmId);
  /// if (codeEntry != null) {
  ///   final wasmBytes = codeEntry.code.dataValue;
  ///   print('Contract bytecode size: ${wasmBytes.length} bytes');
  ///   // Can parse bytecode to extract contract metadata
  /// }
  /// ```
  ///
  /// See also:
  /// - [loadContractCodeForContractId] to get code from a contract ID
  /// - [loadContractInfoForWasmId] to extract contract metadata
  /// - [SorobanContractParser] for parsing contract bytecode
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

  /// Loads the WebAssembly bytecode for a contract given its contract ID.
  ///
  /// This method first retrieves the contract instance to determine its Wasm ID, then
  /// loads the corresponding contract code. This is a two-step process:
  /// 1. Query the contract instance ledger entry to get the Wasm hash
  /// 2. Query the contract code entry using that Wasm hash
  ///
  /// Use this when you have a contract ID but need to access the underlying bytecode.
  /// Multiple contracts can share the same bytecode (same Wasm ID) if they were
  /// created from the same uploaded code.
  ///
  /// Parameters:
  /// - [contractId]: Hex-encoded contract ID (hash derived from contract address)
  ///
  /// Returns: XdrContractCodeEntry containing:
  /// - code: DataValue with the raw WebAssembly bytecode
  /// - ext: Extension field for future protocol upgrades
  ///
  /// Returns null if:
  /// - The contract instance does not exist
  /// - The contract code entry is missing (should not happen for valid contracts)
  ///
  /// Throws:
  /// - Exception: If the RPC request fails or XDR decoding fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final contractId = 'c5b1...'; // hex-encoded contract ID
  ///
  /// final codeEntry = await server.loadContractCodeForContractId(contractId);
  /// if (codeEntry != null) {
  ///   final wasmBytes = codeEntry.code.dataValue;
  ///   print('Contract bytecode size: ${wasmBytes.length} bytes');
  ///
  ///   // Parse contract to extract metadata and spec
  ///   final info = SorobanContractParser.parseContractByteCode(wasmBytes);
  ///   print('Contract spec: ${info.spec}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [loadContractCodeForWasmId] to get code directly by Wasm ID
  /// - [loadContractInfoForContractId] for parsed contract information
  /// - [SorobanContractParser] for parsing contract bytecode
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

  /// Loads and parses contract metadata for a given contract ID.
  ///
  /// This is a convenience method that combines loading the contract bytecode and parsing
  /// it to extract structured metadata. It performs these steps:
  /// 1. Retrieves the contract instance to get the Wasm ID
  /// 2. Loads the contract code entry
  /// 3. Parses the WebAssembly bytecode to extract metadata sections
  ///
  /// The parsed information includes the contract specification (function signatures,
  /// types), environment metadata (SDK version, protocol requirements), and custom
  /// contract metadata.
  ///
  /// Parameters:
  /// - [contractId]: Hex-encoded contract ID to load and parse
  ///
  /// Returns: SorobanContractInfo containing:
  /// - envMeta: Environment metadata (SDK version, protocol version)
  /// - spec: Contract specification with function and type definitions
  /// - contractMeta: Custom metadata embedded in the contract
  ///
  /// Returns null if the contract does not exist.
  ///
  /// Throws:
  /// - [SorobanContractParserFailed]: If bytecode parsing fails due to invalid format
  /// - [Exception]: If the RPC request fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final contractId = 'c5b1...';
  ///
  /// try {
  ///   final info = await server.loadContractInfoForContractId(contractId);
  ///   if (info != null) {
  ///     print('Contract environment: ${info.envMeta?.interfaceVersion}');
  ///     if (info.spec != null && info.spec!.isNotEmpty) {
  ///       for (final entry in info.spec!) {
  ///         if (entry.functionV0 != null) {
  ///           print('Function: ${entry.functionV0!.name}');
  ///         }
  ///       }
  ///     }
  ///   }
  /// } catch (e) {
  ///   print('Failed to parse contract: $e');
  /// }
  /// ```
  ///
  /// See also:
  /// - [loadContractInfoForWasmId] to parse by Wasm ID
  /// - [loadContractCodeForContractId] to get raw bytecode
  /// - [SorobanContractParser] for the parsing implementation
  /// - [SorobanContractInfo] for parsed metadata structure
  Future<SorobanContractInfo?> loadContractInfoForContractId(
      String contractId) async {
    var contractCodeEntry = await loadContractCodeForContractId(contractId);
    if (contractCodeEntry == null) {
      return null;
    }
    var byteCode = contractCodeEntry.code.dataValue;
    return SorobanContractParser.parseContractByteCode(byteCode);
  }

  /// Loads and parses contract metadata for a given Wasm ID.
  ///
  /// This is a convenience method that loads the contract bytecode by its Wasm ID and
  /// parses it to extract structured metadata. It performs these steps:
  /// 1. Loads the contract code entry using the Wasm ID
  /// 2. Parses the WebAssembly bytecode to extract metadata sections
  ///
  /// The Wasm ID is the hash of the contract bytecode. Multiple contract instances can
  /// share the same Wasm ID if they were deployed from the same uploaded code.
  ///
  /// Parameters:
  /// - [wasmId]: Hex-encoded hash of the contract WebAssembly bytecode
  ///
  /// Returns: SorobanContractInfo containing:
  /// - envMeta: Environment metadata (SDK version, protocol version)
  /// - spec: Contract specification with function and type definitions
  /// - contractMeta: Custom metadata embedded in the contract
  ///
  /// Returns null if no contract code exists with the given Wasm ID.
  ///
  /// Throws:
  /// - [SorobanContractParserFailed]: If bytecode parsing fails due to invalid format
  /// - [Exception]: If the RPC request fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final wasmId = 'f3b5...'; // From contract upload result
  ///
  /// try {
  ///   final info = await server.loadContractInfoForWasmId(wasmId);
  ///   if (info != null) {
  ///     print('Protocol version: ${info.envMeta?.protocolVersion}');
  ///     if (info.contractMeta != null) {
  ///       print('Contract metadata: ${info.contractMeta!.description}');
  ///     }
  ///   }
  /// } catch (e) {
  ///   print('Failed to parse contract: $e');
  /// }
  /// ```
  ///
  /// See also:
  /// - [loadContractInfoForContractId] to parse by contract ID
  /// - [loadContractCodeForWasmId] to get raw bytecode
  /// - [SorobanContractParser] for the parsing implementation
  /// - [SorobanContractInfo] for parsed metadata structure
  Future<SorobanContractInfo?> loadContractInfoForWasmId(String wasmId) async {
    var contractCodeEntry = await loadContractCodeForWasmId(wasmId);
    if (contractCodeEntry == null) {
      return null;
    }
    var byteCode = contractCodeEntry.code.dataValue;
    return SorobanContractParser.parseContractByteCode(byteCode);
  }

  /// Retrieves information about the Stellar network configuration.
  ///
  /// This method returns essential network information needed to construct and submit
  /// transactions correctly. The network passphrase is particularly critical as it
  /// ensures transactions are valid only for the intended network (preventing replay
  /// attacks across different networks).
  ///
  /// Use this to:
  /// - Verify you're connected to the correct network (testnet vs mainnet)
  /// - Get the network passphrase for transaction signing
  /// - Find the friendbot URL for funding testnet accounts
  /// - Check the protocol version supported by the network
  ///
  /// Returns: GetNetworkResponse containing:
  /// - passphrase: Network passphrase used for transaction signing
  ///   - Mainnet: "Public Global Stellar Network ; September 2015"
  ///   - Testnet: "Test SDF Network ; September 2015"
  /// - friendbotUrl: URL for testnet account funding (null on mainnet)
  /// - protocolVersion: Current Stellar protocol version
  ///
  /// Throws:
  /// - Exception: If the network request fails or the server is unreachable
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final network = await server.getNetwork();
  ///
  /// print('Network: ${network.passphrase}');
  /// print('Protocol: ${network.protocolVersion}');
  ///
  /// // Use for transaction signing
  /// final stellarNetwork = Network(network.passphrase!);
  /// transaction.sign(keyPair, stellarNetwork);
  ///
  /// // Fund testnet account if friendbot is available
  /// if (network.friendbotUrl != null) {
  ///   print('Friendbot: ${network.friendbotUrl}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [GetNetworkResponse] for response details
  /// - [Network] class for transaction signing
  /// - [Soroban RPC getNetwork](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getNetwork)
  Future<GetNetworkResponse> getNetwork() async {
    JsonRpcMethod getNetwork = JsonRpcMethod("getNetwork");
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getNetwork), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getNetwork response: $response");
    }
    return GetNetworkResponse.fromJson(response.data);
  }

  /// Simulates a transaction to estimate resources and preview results.
  ///
  /// This is one of the most important Soroban RPC methods. It allows you to preview the effects
  /// of a transaction before submitting it to the network. The simulation provides:
  /// - Expected return values from contract function calls
  /// - Required resource footprint (ledger entries that will be read/written)
  /// - Estimated resource fees
  /// - Authorization entries that need signing
  /// - State changes that would occur
  ///
  /// Use simulation results to:
  /// 1. Validate that your transaction will succeed
  /// 2. Get the required resource footprint and fees
  /// 3. Preview return values for read-only operations
  /// 4. Identify which parties need to sign authorization entries
  ///
  /// Parameters:
  /// - [request]: SimulateTransactionRequest containing the transaction to simulate
  ///
  /// Returns: SimulateTransactionResponse with simulation results including:
  /// - results: Return values from the simulation
  /// - transactionData: Soroban transaction data with resource footprint
  /// - minResourceFee: Minimum resource fee required
  /// - events: Events that would be emitted
  /// - restorePreamble: If present, indicates archived entries need restoration
  ///
  /// Throws:
  /// - Exception: If the simulation request fails or returns an error
  ///
  /// Example:
  /// ```dart
  /// final tx = TransactionBuilder(sourceAccount)
  ///   .addOperation(invokeOp)
  ///   .build();
  ///
  /// final request = SimulateTransactionRequest(tx);
  /// final response = await server.simulateTransaction(request);
  ///
  /// if (response.error == null) {
  ///   final resourceFee = response.minResourceFee;
  ///   final footprint = response.getFootprint();
  ///   final returnValue = response.results?.first.resultValue;
  /// }
  /// ```
  ///
  /// See also:
  /// - [SimulateTransactionRequest] for request options
  /// - [SimulateTransactionResponse] for response details
  /// - [Soroban RPC simulateTransaction](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/simulateTransaction)
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

  /// Submits a signed transaction to the Stellar network.
  ///
  /// This is the only way to make changes on-chain. Unlike Horizon's submit endpoint,
  /// this method does not wait for the transaction to complete. It validates the transaction,
  /// enqueues it, and returns immediately with a status.
  ///
  /// After submitting, use getTransaction to poll for the final result.
  ///
  /// This method supports all transaction types, not just smart contract operations.
  ///
  /// Parameters:
  /// - [transaction]: The signed Transaction to submit
  ///
  /// Returns: SendTransactionResponse containing:
  /// - hash: Transaction hash for tracking
  /// - status: One of PENDING, DUPLICATE, TRY_AGAIN_LATER, or ERROR
  /// - latestLedger: Latest known ledger at submission time
  /// - errorResultXdr: If status is ERROR, contains the error details
  ///
  /// Throws:
  /// - Exception: If the network request fails
  ///
  /// Example:
  /// ```dart
  /// // Build and simulate transaction first
  /// final simulation = await server.simulateTransaction(simulateRequest);
  /// tx.sorobanTransactionData = simulation.transactionData;
  /// tx.addResourceFee(simulation.minResourceFee);
  ///
  /// // Sign the transaction
  /// tx.sign(sourceKeyPair, network);
  ///
  /// // Submit to network
  /// final response = await server.sendTransaction(tx);
  ///
  /// if (response.status == SendTransactionResponse.STATUS_PENDING) {
  ///   // Poll for completion
  ///   final result = await server.getTransaction(response.hash!);
  /// } else if (response.status == SendTransactionResponse.STATUS_ERROR) {
  ///   print('Error: ${response.errorResultXdr}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getTransaction] to poll for transaction completion
  /// - [SendTransactionResponse] for status codes
  /// - [Soroban RPC sendTransaction](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/sendTransaction)
  Future<SendTransactionResponse> sendTransaction(
      Transaction transaction) async {
    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();

    JsonRpcMethod getAccount = JsonRpcMethod("sendTransaction",
        args: {'transaction': transactionEnvelopeXdr});
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getAccount), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("sendTransaction response: $response");
    }
    return SendTransactionResponse.fromJson(response.data);
  }

  /// Retrieves the status and results of a submitted transaction.
  ///
  /// Use this method to poll for transaction completion after calling sendTransaction.
  /// The transaction hash is returned by sendTransaction.
  ///
  /// Parameters:
  /// - [transactionHash]: Hash of the transaction to query (hex-encoded)
  ///
  /// Returns: GetTransactionResponse containing:
  /// - status: SUCCESS, NOT_FOUND, or FAILED
  /// - ledger: Ledger number where transaction was included (if SUCCESS or FAILED)
  /// - resultXdr: Transaction result XDR (if SUCCESS or FAILED)
  /// - resultMetaXdr: Transaction metadata XDR with contract return values
  /// - envelopeXdr: Original transaction envelope
  ///
  /// Status values:
  /// - SUCCESS: Transaction completed successfully
  /// - NOT_FOUND: Transaction not yet processed or outside retention window
  /// - FAILED: Transaction failed (check resultXdr for details)
  ///
  /// Throws:
  /// - Exception: If the RPC request fails
  ///
  /// Example:
  /// ```dart
  /// final sendResponse = await server.sendTransaction(signedTx);
  ///
  /// // Poll until transaction completes
  /// while (true) {
  ///   await Future.delayed(Duration(seconds: 2));
  ///   final getResponse = await server.getTransaction(sendResponse.hash!);
  ///
  ///   if (getResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
  ///     final returnValue = getResponse.getResultValue();
  ///     print('Success! Return value: $returnValue');
  ///     break;
  ///   } else if (getResponse.status == GetTransactionResponse.STATUS_FAILED) {
  ///     print('Transaction failed: ${getResponse.resultXdr}');
  ///     break;
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  /// - [sendTransaction] to submit transactions
  /// - [GetTransactionResponse] for response details
  /// - [Soroban RPC getTransaction](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getTransaction)
  Future<GetTransactionResponse> getTransaction(String transactionHash) async {
    JsonRpcMethod getTransactionStatus =
        JsonRpcMethod("getTransaction", args: {'hash': transactionHash});
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getTransactionStatus),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getTransaction response: $response");
    }
    return GetTransactionResponse.fromJson(response.data);
  }

  /// Retrieves contract events emitted within a specified ledger range.
  ///
  /// Events are emitted by smart contracts during execution and provide a way to track
  /// contract activity. This method allows filtering events by contract, topic, and type.
  ///
  /// Event retention period is network-dependent (typically 24 hours on public networks,
  /// but may vary by RPC provider configuration). Use pagination to handle large result sets.
  ///
  /// Important: When making multiple requests, deduplicate events using their unique ID
  /// to prevent double-processing.
  ///
  /// Parameters:
  /// - [request]: GetEventsRequest with filters and pagination options
  ///
  /// Returns: GetEventsResponse containing:
  /// - events: List of EventInfo objects matching the filter criteria
  /// - latestLedger: Latest ledger known to the server
  /// - cursor: Pagination cursor for next page
  ///
  /// Throws:
  /// - Exception: If the RPC request fails
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   // Get all events from a specific contract
  ///   final filter = EventFilter(
  ///     contractIds: ['CABC...'],
  ///     topics: [
  ///       TopicFilter(['*', XdrSCVal.forSymbol('transfer').toBase64EncodedXdrString()])
  ///     ],
  ///   );
  ///
  ///   final request = GetEventsRequest(
  ///     startLedger: 1000,
  ///     filters: [filter],
  ///     paginationOptions: PaginationOptions(limit: 100),
  ///   );
  ///
  ///   final response = await server.getEvents(request);
  ///   if (response.events != null) {
  ///     for (final event in response.events!) {
  ///       print('Event: ${event.id} at ledger ${event.ledger}');
  ///       final value = event.valueXdr;
  ///     }
  ///   }
  /// } catch (e) {
  ///   print('Failed to fetch events: $e');
  /// }
  /// ```
  ///
  /// See also:
  /// - [GetEventsRequest] for filter options
  /// - [EventFilter] for filtering events
  /// - [Soroban RPC getEvents](https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents)
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

  /// Retrieves a paginated list of transactions from the ledger history.
  ///
  /// This method returns detailed transaction information starting from a specified ledger
  /// sequence. It provides comprehensive data including the transaction envelope, results,
  /// metadata, and events. Use this to track historical transaction activity or audit
  /// on-chain operations.
  ///
  /// The returned data is subject to the RPC server's retention window. Transactions
  /// outside this window are no longer available through this endpoint.
  ///
  /// Parameters:
  /// - [request]: GetTransactionsRequest containing:
  ///   - startLedger: Ledger sequence to start from (inclusive)
  ///   - paginationOptions: Optional cursor and limit for pagination
  ///
  /// Returns: GetTransactionsResponse containing:
  /// - transactions: List of TransactionInfo objects with full transaction details
  /// - latestLedger: Latest ledger sequence known to the server
  /// - latestLedgerCloseTimestamp: Unix timestamp of latest ledger close
  /// - oldestLedger: Oldest ledger available in retention window
  /// - oldestLedgerCloseTimestamp: Unix timestamp of oldest ledger close
  /// - cursor: Pagination cursor for next page of results
  ///
  /// Each TransactionInfo includes:
  /// - envelopeXdr: Full transaction envelope
  /// - resultXdr: Transaction execution result
  /// - resultMetaXdr: Metadata including state changes and return values
  /// - status: SUCCESS, FAILED, or NOT_FOUND
  /// - events: Diagnostic and contract events (protocol >= 23)
  ///
  /// Throws:
  /// - Exception: If startLedger is outside retention window or request fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  ///
  /// // Get transactions from ledger 1000 onwards
  /// final request = GetTransactionsRequest(
  ///   startLedger: 1000,
  ///   paginationOptions: PaginationOptions(limit: 50),
  /// );
  ///
  /// final response = await server.getTransactions(request);
  /// if (response.transactions != null) {
  ///   for (final tx in response.transactions!) {
  ///     print('Transaction: ${tx.txHash}');
  ///     print('Status: ${tx.status}');
  ///     print('Ledger: ${tx.ledger}');
  ///   }
  ///
  ///   // Get next page if available
  ///   if (response.cursor != null) {
  ///     final nextRequest = GetTransactionsRequest(
  ///       paginationOptions: PaginationOptions(cursor: response.cursor),
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  /// - [getTransaction] to query a specific transaction by hash
  /// - [GetTransactionsRequest] for request options
  /// - [TransactionInfo] for transaction details
  /// - [Soroban RPC getTransactions](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getTransactions)
  Future<GetTransactionsResponse> getTransactions(
      GetTransactionsRequest request) async {
    JsonRpcMethod getTransactions =
        JsonRpcMethod("getTransactions", args: request.getRequestArgs());
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getTransactions),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getTransactions response: $response");
    }
    return GetTransactionsResponse.fromJson(response.data);
  }

  /// Retrieves a paginated list of ledgers with detailed information.
  ///
  /// This method returns comprehensive ledger data including headers and metadata starting
  /// from a specified sequence. Use this to analyze ledger progression, track protocol
  /// changes, or audit blockchain state transitions over time.
  ///
  /// Each ledger represents a snapshot of the entire blockchain state at a specific point
  /// in time. Ledgers close approximately every 5 seconds on the Stellar network.
  ///
  /// The returned data is subject to the RPC server's retention window. Ledgers outside
  /// this window are no longer available through this endpoint.
  ///
  /// Parameters:
  /// - [request]: GetLedgersRequest containing:
  ///   - startLedger: Ledger sequence to start from (inclusive)
  ///   - paginationOptions: Optional cursor and limit for pagination
  ///
  /// Returns: GetLedgersResponse containing:
  /// - ledgers: List of LedgerInfo objects with full ledger details
  /// - latestLedger: Latest ledger sequence known to the server
  /// - latestLedgerCloseTime: Unix timestamp of latest ledger close
  /// - oldestLedger: Oldest ledger available in retention window
  /// - oldestLedgerCloseTime: Unix timestamp of oldest ledger close
  /// - cursor: Pagination cursor for next page of results
  ///
  /// Each LedgerInfo includes:
  /// - hash: Ledger hash as hex-encoded string
  /// - sequence: Ledger sequence number
  /// - ledgerCloseTime: Unix timestamp when ledger closed
  /// - headerXdr: Base64-encoded ledger header (if available)
  /// - metadataXdr: Base64-encoded ledger metadata (if available)
  ///
  /// Throws:
  /// - Exception: If startLedger is outside retention window or request fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  ///
  /// // Get ledgers starting from sequence 1000
  /// final request = GetLedgersRequest(
  ///   startLedger: 1000,
  ///   paginationOptions: PaginationOptions(limit: 100),
  /// );
  ///
  /// final response = await server.getLedgers(request);
  /// if (response.ledgers != null) {
  ///   for (final ledger in response.ledgers!) {
  ///     print('Ledger ${ledger.sequence}: ${ledger.hash}');
  ///     print('Closed at: ${ledger.ledgerCloseTime}');
  ///
  ///     // Access ledger header if needed
  ///     if (ledger.headerXdr != null) {
  ///       final header = XdrLedgerHeader.fromBase64EncodedXdrString(
  ///         ledger.headerXdr!
  ///       );
  ///     }
  ///   }
  ///
  ///   // Paginate to next set of ledgers
  ///   if (response.cursor != null) {
  ///     final nextRequest = GetLedgersRequest(
  ///       paginationOptions: PaginationOptions(cursor: response.cursor),
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  /// - [getLatestLedger] to get only the latest ledger info
  /// - [GetLedgersRequest] for request options
  /// - [LedgerInfo] for ledger details
  /// - [Soroban RPC getLedgers](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgers)
  Future<GetLedgersResponse> getLedgers(GetLedgersRequest request) async {
    JsonRpcMethod getLedgers =
        JsonRpcMethod("getLedgers", args: request.getRequestArgs());
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(getLedgers),
        options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("getLedgers response: $response");
    }
    return GetLedgersResponse.fromJson(response.data);
  }
}

/// Abstract class for soroban rpc responses.
abstract class SorobanRpcResponse {
  Map<String, dynamic>
      jsonResponse; // JSON response received from the rpc server
  SorobanRpcErrorResponse? error;

  /// Creates a SorobanRpcResponse with JSON response data.
  ///
  /// Base constructor for all Soroban RPC response types.
  SorobanRpcResponse(this.jsonResponse);

  bool get isErrorResponse => error != null;
}

/// General node health check response.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getHealth
class GetHealthResponse extends SorobanRpcResponse {
  /// Health status e.g. "healthy"
  String? status;

  /// Maximum retention window configured. A full window state can be determined
  /// via: ledgerRetentionWindow = latestLedger - oldestLedger + 1
  int? ledgerRetentionWindow;

  /// Most recent known ledger sequence
  int? latestLedger;

  /// Oldest ledger sequence kept in history.
  int? oldestLedger;

  static const String HEALTHY = "healthy";

  /// Creates a GetHealthResponse from JSON-RPC response.
  ///
  /// Contains health status and ledger retention information.
  GetHealthResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetHealthResponse.fromJson(Map<String, dynamic> json) {
    GetHealthResponse response = GetHealthResponse(json);
    if (json['result'] != null) {
      if (json['result']['status'] != null) {
        response.status = json['result']['status'];
      }
      if (json['result']['ledgerRetentionWindow'] != null) {
        response.ledgerRetentionWindow =
            json['result']['ledgerRetentionWindow'];
      }
      if (json['result']['latestLedger'] != null) {
        response.latestLedger = json['result']['latestLedger'];
      }
      if (json['result']['oldestLedger'] != null) {
        response.oldestLedger = json['result']['oldestLedger'];
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Version information about the RPC and Captive core.
/// RPC manages its own, pared-down version of Stellar Core optimized for its own subset of needs.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getVersionInfo
class GetVersionInfoResponse extends SorobanRpcResponse {
  /// The version of the RPC server.
  String? version;

  /// The commit hash of the RPC server.
  String? commitHash;

  /// The build timestamp of the RPC server.
  String? buildTimeStamp;

  /// The version of the Captive Core.
  String? captiveCoreVersion;

  /// The protocol version.
  int? protocolVersion;

  /// Creates a GetVersionInfoResponse from JSON-RPC response.
  ///
  /// Contains version information for RPC server and Captive Core.
  GetVersionInfoResponse(Map<String, dynamic> jsonResponse)
      : super(jsonResponse);

  factory GetVersionInfoResponse.fromJson(Map<String, dynamic> json) {
    GetVersionInfoResponse response = GetVersionInfoResponse(json);
    if (json['result'] != null) {
      response.version = json['result']['version'];

      if (json['result']['commit_hash'] != null) {
        response.commitHash =
            json['result']['commit_hash']; // protocol version < 22
      } else {
        response.commitHash =
            json['result']['commitHash']; // protocol version >= 22
      }

      if (json['result']['build_time_stamp'] != null) {
        response.buildTimeStamp =
            json['result']['build_time_stamp']; // protocol version < 22
      } else {
        response.buildTimeStamp =
            json['result']['buildTimestamp']; // protocol version >= 22
      }

      if (json['result']['captive_core_version'] != null) {
        response.captiveCoreVersion =
            json['result']['captive_core_version']; // protocol version < 22
      } else {
        response.captiveCoreVersion =
            json['result']['captiveCoreVersion']; // protocol version >= 22
      }

      if (json['result']['protocol_version'] != null) {
        response.protocolVersion =
            json['result']['protocol_version']; // protocol version < 22
      } else {
        response.protocolVersion =
            json['result']['protocolVersion']; // protocol version >= 22
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Statistics for charged inclusion fees. The inclusion fee statistics are calculated
/// from the inclusion fees that were paid for the transactions to be included onto the ledger.
/// For Soroban transactions and Stellar transactions, they each have their own inclusion fees
/// and own surge pricing. Inclusion fees are used to prevent spam and prioritize transactions
/// during network traffic surge.
class GetFeeStatsResponse extends SorobanRpcResponse {
  /// Inclusion fee distribution statistics for Soroban transactions
  InclusionFee? sorobanInclusionFee;

  /// Fee distribution statistics for Stellar (i.e. non-Soroban) transactions.
  /// Statistics are normalized per operation.
  InclusionFee? inclusionFee;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedger;

  /// Creates a GetFeeStatsResponse from JSON-RPC response.
  ///
  /// Contains fee statistics for Soroban and classic transactions.
  GetFeeStatsResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetFeeStatsResponse.fromJson(Map<String, dynamic> json) {
    GetFeeStatsResponse response = GetFeeStatsResponse(json);
    if (json['result'] != null) {
      if (json['result']['sorobanInclusionFee'] != null) {
        response.sorobanInclusionFee =
            InclusionFee.fromJson(json['result']['sorobanInclusionFee']);
      }
      if (json['result']['inclusionFee'] != null) {
        response.inclusionFee =
            InclusionFee.fromJson(json['result']['inclusionFee']);
      }
      if (json['result']['latestLedger'] != null) {
        response.latestLedger = json['result']['latestLedger'];
      }
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Statistics about transaction inclusion fees on the Soroban network.
///
/// InclusionFee provides comprehensive fee distribution data to help estimate appropriate
/// fees for transaction inclusion in upcoming ledgers. The data represents fee statistics
/// from recent ledgers and includes percentile-based fee recommendations.
///
/// Fee Selection Strategy:
/// - Use [min] for non-urgent transactions (may take longer to confirm)
/// - Use [mode] for typical transactions (most common fee paid)
/// - Use [p50] (median) for balanced priority
/// - Use [p90] or [p99] for high-priority transactions requiring fast confirmation
/// - Use [max] to see the highest fee paid in the sample period
///
/// All fee values are represented as strings in stroops (1 stroop = 0.0000001 XLM).
/// The distribution is calculated from [ledgerCount] consecutive ledgers containing
/// [transactionCount] total transactions.
///
/// Fields:
/// - [min]: Minimum fee in the distribution
/// - [max]: Maximum fee in the distribution
/// - [mode]: Most frequently occurring fee (useful for typical transactions)
/// - [p10] to [p99]: Percentile-based fee recommendations
/// - [transactionCount]: Number of transactions in the sample
/// - [ledgerCount]: Number of ledgers analyzed
///
/// Example:
/// ```dart
/// final server = SorobanServer(rpcUrl);
/// final feeStats = await server.getFeeStats();
///
/// if (feeStats.sorobanInclusionFee != null) {
///   final fees = feeStats.sorobanInclusionFee!;
///   print('Recommended fee (median): ${fees.p50} stroops');
///   print('Fast confirmation fee (90th percentile): ${fees.p90} stroops');
///   print('Based on ${fees.transactionCount} transactions');
/// }
/// ```
///
/// See also:
/// - [GetFeeStatsResponse] for the complete fee statistics response
/// - [Soroban Fee Documentation](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getFeeStats)
class InclusionFee {
  /// Maximum fee
  String max;

  /// Minimum fee
  String min;

  /// Fee value which occurs the most often
  String mode;

  /// 10th nearest-rank fee percentile
  String p10;

  /// 20th nearest-rank fee percentile
  String p20;

  /// 30th nearest-rank fee percentile
  String p30;

  /// 40th nearest-rank fee percentile
  String p40;

  /// 50th nearest-rank fee percentile
  String p50;

  /// 60th nearest-rank fee percentile
  String p60;

  /// 70th nearest-rank fee percentile
  String p70;

  /// 80th nearest-rank fee percentile
  String p80;

  /// 90th nearest-rank fee percentile
  String p90;

  /// 99th nearest-rank fee percentile
  String p99;

  /// How many transactions are part of the distribution
  String transactionCount;

  /// How many consecutive ledgers form the distribution
  int ledgerCount;

  /// Creates an InclusionFee with fee distribution statistics.
  ///
  /// Contains percentile-based fee recommendations for transaction inclusion.
  InclusionFee(
      this.max,
      this.min,
      this.mode,
      this.p10,
      this.p20,
      this.p30,
      this.p40,
      this.p50,
      this.p60,
      this.p70,
      this.p80,
      this.p90,
      this.p99,
      this.transactionCount,
      this.ledgerCount);

  factory InclusionFee.fromJson(Map<String, dynamic> json) {
    return InclusionFee(
      json['max'],
      json['min'],
      json['mode'],
      json['p10'],
      json['p20'],
      json['p30'],
      json['p40'],
      json['p50'],
      json['p60'],
      json['p70'],
      json['p80'],
      json['p90'],
      json['p99'],
      json['transactionCount'],
      json['ledgerCount'],
    );
  }
}

/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getLatestLedger
class GetLatestLedgerResponse extends SorobanRpcResponse {
  /// Hash identifier of the latest ledger (as a hex-encoded string) known to Soroban RPC at the time it handled the request.
  String? id;

  /// Stellar Core protocol version associated with the latest ledger.
  int? protocolVersion;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? sequence;

  /// Creates a GetLatestLedgerResponse from JSON-RPC response.
  ///
  /// Contains the latest ledger sequence and hash information.
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

  /// Creates a SorobanRpcErrorResponse from error JSON.
  ///
  /// Contains error code, message, and optional additional data.
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

/// Response from the getLedgerEntries RPC method.
///
/// GetLedgerEntriesResponse contains ledger entries retrieved from the Soroban network.
/// Ledger entries represent contract state, contract code, and other on-chain data stored
/// in the ledger. This method allows querying the current state of contracts and their data.
///
/// The response includes:
/// - A list of [LedgerEntry] objects containing the requested entries
/// - The latest known ledger sequence for context
///
/// Use Cases:
/// - Query contract data storage (contract persistent/temporary data)
/// - Retrieve contract WASM code
/// - Read contract instance configuration
/// - Access account contract data entries
///
/// Fields:
/// - [entries]: List of ledger entries matching the query
/// - [latestLedger]: Latest ledger sequence known to RPC server
///
/// Example:
/// ```dart
/// final server = SorobanServer(rpcUrl);
///
/// // Create ledger keys for contract data
/// final contractId = StrKey.decodeContractIdHex('CABC...');
/// final dataKey = XdrSCVal.forSymbol('balance');
/// final ledgerKey = XdrLedgerKey.forContractData(contractId, dataKey);
///
/// // Query ledger entries
/// final request = GetLedgerEntriesRequest([ledgerKey]);
/// final response = await server.getLedgerEntries(request);
///
/// if (response.entries != null) {
///   for (var entry in response.entries!) {
///     print('Entry last modified: ${entry.lastModifiedLedgerSeq}');
///     print('Entry expires at ledger: ${entry.liveUntilLedgerSeq}');
///     // Decode entry data
///     final data = entry.ledgerEntryDataXdr;
///   }
/// }
/// ```
///
/// See also:
/// - [LedgerEntry] for individual entry details
/// - [SorobanServer.getLedgerEntries] for the method to fetch ledger entries
/// - [Soroban RPC Documentation](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgerEntries)
class GetLedgerEntriesResponse extends SorobanRpcResponse {
  /// Entries
  List<LedgerEntry>? entries;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedger;

  /// Creates a GetLedgerEntriesResponse from JSON-RPC response.
  ///
  /// Contains ledger entries retrieved from the network.
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

/// A single ledger entry retrieved from the Soroban network.
///
/// LedgerEntry represents a piece of data stored on the Stellar ledger, including
/// contract code, contract instance data, contract persistent data, contract temporary data,
/// and other ledger state. Each entry has a unique key and contains XDR-encoded data.
///
/// Entry Types:
/// - Contract Code: WASM bytecode for deployed smart contracts
/// - Contract Data: Persistent or temporary storage for contract state
/// - Contract Instance: Configuration and metadata for contract instances
/// - Account Data: Contract-related data attached to accounts
///
/// Expiration Management:
/// - Contract code and data entries have TTL (time-to-live) managed by [liveUntilLedgerSeq]
/// - Entries must be restored before expiration to remain accessible
/// - Use RestoreFootprint operation to extend expired entries
///
/// Fields:
/// - [key]: Unique identifier for the entry (base64-encoded XDR)
/// - [xdr]: Entry data content (base64-encoded XDR)
/// - [lastModifiedLedgerSeq]: Ledger when entry was last updated
/// - [liveUntilLedgerSeq]: Expiration ledger (contract code/data only)
/// - [ext]: Extension field (protocol 23+)
///
/// Example - Reading contract data:
/// ```dart
/// final response = await server.getLedgerEntries(request);
///
/// for (var entry in response.entries!) {
///   // Access the entry key
///   final keyValue = entry.keyValue;
///
///   // Decode entry data
///   final entryData = entry.ledgerEntryDataXdr;
///
///   // Check expiration
///   if (entry.liveUntilLedgerSeq != null) {
///     final ledgersUntilExpiry = entry.liveUntilLedgerSeq! - currentLedger;
///     if (ledgersUntilExpiry < 100) {
///       print('Entry expires soon, consider restoring');
///     }
///   }
/// }
/// ```
///
/// Example - Working with contract data:
/// ```dart
/// if (entry.ledgerEntryData.contractData != null) {
///   final contractData = entry.ledgerEntryData.contractData!;
///   final value = contractData.val;
///   print('Contract data value: $value');
/// }
/// ```
///
/// See also:
/// - [GetLedgerEntriesResponse] for querying entries
/// - [XdrLedgerEntryData] for decoded entry structure
/// - [RestoreFootprintOperation] for extending entry TTL
class LedgerEntry {
  /// The key of the ledger entry (serialized in a base64 string)
  String key;

  /// The current value of the given ledger entry (serialized in a base64 string)
  String xdr;

  /// The ledger sequence number of the last time this entry was updated.
  int lastModifiedLedgerSeq;

  /// The ledger sequence number after which the ledger entry would expire. This field exists only for ContractCodeEntry and ContractDataEntry ledger entries (optional).
  int? liveUntilLedgerSeq;

  /// The entry's "Ext" field. Only available for protocol version >= 23
  String? ext;

  XdrLedgerEntryData get ledgerEntryDataXdr =>
      XdrLedgerEntryData.fromBase64EncodedXdrString(xdr);

  /// Creates a LedgerEntry with entry data.
  ///
  /// Contains ledger entry key, value, and TTL information.
  LedgerEntry(
      this.key, this.xdr, this.lastModifiedLedgerSeq, this.liveUntilLedgerSeq, this.ext);

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    String key = json['key'];
    String xdr = json['xdr'];
    int lastModifiedLedgerSeq = json['lastModifiedLedgerSeq'];
    int? liveUntilLedgerSeq = json['liveUntilLedgerSeq'];
    return LedgerEntry(key, xdr, lastModifiedLedgerSeq, liveUntilLedgerSeq, json['ext']);
  }

  XdrLedgerEntryData get ledgerEntryData =>
      XdrLedgerEntryData.fromBase64EncodedXdrString(xdr);

  XdrSCVal get keyValue => XdrSCVal.fromBase64EncodedXdrString(key);
}

/// General information about the currently configured network. This response
/// will contain all the information needed to successfully submit transactions
/// to the network this node serves.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getNetwork
class GetNetworkResponse extends SorobanRpcResponse {
  String? friendbotUrl;
  String? passphrase;
  int? protocolVersion;

  /// Creates a GetNetworkResponse from JSON-RPC response.
  ///
  /// Contains network passphrase and protocol version.
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

/// Part of the SimulateTransactionRequest.
/// Allows budget instruction leeway used in preflight calculations to be configured.
class ResourceConfig {
  /// Configuration for how resources will be calculated.
  /// Allow this many extra instructions when budgeting resources.
  int instructionLeeway;

  /// Creates a ResourceConfig with instruction leeway.
  ///
  /// Allows extra instructions when budgeting resources for simulation.
  ResourceConfig(this.instructionLeeway);

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    map['instructionLeeway'] = instructionLeeway;
    return map;
  }
}

/// Holds the request parameters for simulateTransaction.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/simulateTransaction
class SimulateTransactionRequest {
  /// The transaction to be submitted. In order for the RPC server to
  /// successfully simulate a Stellar transaction, the provided transaction
  /// must contain only a single operation of the type invokeHostFunction.
  Transaction transaction;

  /// Allows budget instruction leeway used in preflight calculations to be configured
  /// If not provided the leeway defaults to 3000000 instructions
  ResourceConfig? resourceConfig;

  /// Support for non-root authorization. Only available for protocol >= 23
  /// Possible values: "enforce" | "record" | "record_allow_nonroot"
  String? authMode;

  /// Creates a SimulateTransactionRequest for transaction simulation.
  ///
  /// Contains transaction to simulate with optional resource config and auth mode.
  SimulateTransactionRequest(this.transaction, {this.resourceConfig, this.authMode});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    map['transaction'] = transaction.toEnvelopeXdrBase64();
    if (resourceConfig != null) {
      map['resourceConfig'] = resourceConfig!.getRequestArgs();
    }
    if (authMode != null) {
      map['authMode'] = authMode;
    }

    return map;
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

/// Holds the request parameters for getTransactions.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getTransactions
class GetTransactionsRequest {
  /// Ledger sequence number to start fetching responses from (inclusive).
  /// Get Transactions will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  int? startLedger;

  /// Pagination
  PaginationOptions? paginationOptions;

  /// Creates a GetTransactionsRequest with query parameters.
  ///
  /// Contains start ledger and pagination options for querying transactions.
  GetTransactionsRequest({this.startLedger, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (paginationOptions != null) {
      Map<String, dynamic> values = {};
      values.addAll(paginationOptions!.getRequestArgs());
      map['pagination'] = values;
    }
    return map;
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

/// Holds the request parameters for getLedgers.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgers
class GetLedgersRequest {
  /// Ledger sequence number to start fetching responses from (inclusive).
  /// GetLedgers will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  int? startLedger;

  /// Pagination options for the request
  PaginationOptions? paginationOptions;

  /// Creates a GetLedgersRequest with query parameters.
  ///
  /// Contains start ledger and pagination options for querying ledgers.
  GetLedgersRequest({this.startLedger, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (paginationOptions != null) {
      Map<String, dynamic> values = {};
      values.addAll(paginationOptions!.getRequestArgs());
      map['pagination'] = values;
    }
    return map;
  }
}

/// Response for the getLedgers request.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgers
class GetLedgersResponse extends SorobanRpcResponse {
  /// Array of ledger information
  List<LedgerInfo>? ledgers;

  /// The sequence number of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedger;

  /// The unix timestamp of the close time of the latest ledger known to Soroban RPC at the time it handled the request.
  int? latestLedgerCloseTime;

  /// The sequence number of the oldest ledger ingested by Soroban RPC at the time it handled the request.
  int? oldestLedger;

  /// The unix timestamp of the close time of the oldest ledger ingested by Soroban RPC at the time it handled the request.
  int? oldestLedgerCloseTime;

  /// A cursor value for use in pagination
  String? cursor;

  /// Creates a GetLedgersResponse from JSON-RPC response.
  ///
  /// Contains paginated list of ledger information.
  GetLedgersResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetLedgersResponse.fromJson(Map<String, dynamic> json) {
    GetLedgersResponse response = GetLedgersResponse(json);
    if (json['result'] != null) {
      if (json['result']['ledgers'] != null) {
        response.ledgers = List<LedgerInfo>.from(
            json['result']['ledgers'].map((e) => LedgerInfo.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.oldestLedger = json['result']['oldestLedger'];
      response.oldestLedgerCloseTime = json['result']['oldestLedgerCloseTime'];
      response.cursor = json['result']['cursor'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Represents a single ledger in the getLedgers response.
/// See: https://developers.stellar.org/docs/data/rpc/api-reference/methods/getLedgers
class LedgerInfo {
  /// Hash of the ledger as a hex-encoded string
  String hash;

  /// Sequence number of the ledger
  int sequence;

  /// The unix timestamp of the close time of the ledger
  String ledgerCloseTime;

  /// Base64-encoded ledger header XDR
  String? headerXdr;

  /// Base64-encoded ledger metadata XDR
  String? metadataXdr;

  /// Creates a LedgerInfo with ledger details.
  ///
  /// Contains ledger hash, sequence, close time, and XDR data.
  LedgerInfo(
    this.hash,
    this.sequence,
    this.ledgerCloseTime,
    this.headerXdr,
    this.metadataXdr,
  );

  factory LedgerInfo.fromJson(Map<String, dynamic> json) {
    return LedgerInfo(
      json['hash'],
      json['sequence'],
      json['ledgerCloseTime'],
      json['headerXdr'],
      json['metadataXdr'],
    );
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

  String status;
  int applicationOrder;
  bool feeBump;
  String envelopeXdr;
  String resultXdr;
  String resultMetaXdr;
  int ledger;
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

/// Holds the request parameters for getEvents.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
class GetEventsRequest {
  /// ledger sequence number to fetch events after (inclusive).
  /// The getEvents method will return an error if startLedger is less than the oldest ledger stored in this node,
  /// or greater than the latest ledger seen by this node.
  /// If a cursor is included in the request, startLedger must be omitted.
  int? startLedger;

  /// Ledger sequence number represents the end of search window (exclusive).
  /// If a cursor is included in the request, endLedger must be omitted.
  int? endLedger;

  /// List of filters for the returned events. Events matching any of the filters are included.
  /// To match a filter, an event must match both a contractId and a topic.
  /// Maximum 5 filters are allowed per request.
  List<EventFilter>? filters;

  /// Pagination
  PaginationOptions? paginationOptions;

  /// Creates a GetEventsRequest with event query parameters.
  ///
  /// Contains ledger range, event filters, and pagination options.
  GetEventsRequest({this.startLedger, this.endLedger, this.filters, this.paginationOptions});

  Map<String, dynamic> getRequestArgs() {
    var map = <String, dynamic>{};
    if (startLedger != null) {
      map['startLedger'] = startLedger;
    }
    if (endLedger != null) {
      map['endLedger'] = endLedger;
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
      values.addAll(paginationOptions!.getRequestArgs());
      map['pagination'] = values;
    }
    return map;
  }
}

/// Event filter for the getEvents request.
/// See: https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
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

  /// Creates an EventFilter with filtering criteria.
  ///
  /// Contains event type, contract IDs, and topic filters.
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
/// https://developers.stellar.org/network/soroban-rpc/api-reference/methods/getEvents
/// ```dart
/// TopicFilter topicFilter = TopicFilter(
///           ["*", XdrSCVal.forSymbol('increment').toBase64EncodedXdrString()]);
/// ```
class TopicFilter {
  List<String> segmentMatchers;

  /// Creates a TopicFilter with segment matchers.
  ///
  /// Contains list of topic segments for pattern matching.
  TopicFilter(this.segmentMatchers);

  List<String> getRequestArgs() {
    return this.segmentMatchers;
  }
}

/// Pagination parameters for Soroban RPC methods that return large result sets.
///
/// PaginationOptions controls the pagination behavior when querying data that may
/// span multiple pages. Use this to efficiently retrieve large datasets by fetching
/// manageable chunks and iterating through pages using continuation cursors.
///
/// Pagination Workflow:
/// 1. Make initial request with optional [limit]
/// 2. Process returned results
/// 3. Check response for continuation [cursor]
/// 4. Make subsequent request with cursor to fetch next page
/// 5. Repeat until cursor is null (no more pages)
///
/// Fields:
/// - [cursor]: Continuation token from previous response (null for first page)
/// - [limit]: Maximum number of results per page (server may have its own limit)
///
/// Applicable Methods:
/// - getEvents: Paginate through contract events
/// - getTransactions: Paginate through transaction history
/// - getLedgers: Paginate through ledger data
///
/// Example - Basic pagination:
/// ```dart
/// final server = SorobanServer(rpcUrl);
/// String? cursor;
/// var pageNum = 1;
///
/// do {
///   final request = GetEventsRequest(
///     startLedger: 1000000,
///     paginationOptions: PaginationOptions(cursor: cursor, limit: 100),
///   );
///
///   final response = await server.getEvents(request);
///
///   print('Page $pageNum: ${response.events?.length ?? 0} events');
///
///   // Process events
///   if (response.events != null) {
///     for (var event in response.events!) {
///       // Process each event
///     }
///   }
///
///   // Get cursor for next page
///   cursor = response.cursor;
///   pageNum++;
/// } while (cursor != null);
/// ```
///
/// Example - Limited iteration:
/// ```dart
/// // Fetch only first 500 events across multiple pages
/// var totalFetched = 0;
/// const maxEvents = 500;
/// String? cursor;
///
/// while (totalFetched < maxEvents) {
///   final remaining = maxEvents - totalFetched;
///   final pageSize = remaining > 100 ? 100 : remaining;
///
///   final request = GetTransactionsRequest(
///     paginationOptions: PaginationOptions(cursor: cursor, limit: pageSize),
///   );
///
///   final response = await server.getTransactions(request);
///
///   if (response.transactions == null || response.transactions!.isEmpty) {
///     break;
///   }
///
///   totalFetched += response.transactions!.length;
///   cursor = response.cursor;
/// }
/// ```
///
/// See also:
/// - [GetEventsRequest] for event pagination
/// - [GetTransactionsRequest] for transaction pagination
/// - [GetLedgersRequest] for ledger pagination
class PaginationOptions {
  String? cursor;
  int? limit;

  /// Creates a PaginationOptions with cursor and limit.
  ///
  /// Contains pagination parameters for paginated RPC methods.
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

/// Response from the getEvents RPC method.
///
/// GetEventsResponse contains a paginated list of contract events emitted within a
/// specified ledger range. Events are the primary mechanism for smart contracts to
/// communicate state changes and emit notifications that applications can monitor
/// and react to.
///
/// The response provides:
/// - List of [EventInfo] objects with complete event details
/// - Pagination cursor for fetching subsequent pages
/// - Ledger range metadata (latest, oldest ledgers and timestamps)
///
/// Event Filtering:
/// Events can be filtered by:
/// - Ledger range (startLedger to endLedger)
/// - Contract IDs (specific contracts)
/// - Event topics (structured filters on event data)
/// - Event type (contract, system, diagnostic)
///
/// Use Cases:
/// - Monitor specific contract events (transfers, approvals, etc.)
/// - Build event-driven applications
/// - Track contract state changes
/// - Implement notification systems
/// - Generate analytics from contract activity
///
/// Fields:
/// - [events]: List of events in the queried range
/// - [latestLedger]: Latest ledger sequence on RPC server
/// - [cursor]: Pagination cursor for next page (protocol 22+)
/// - [latestLedgerCloseTime]: Unix timestamp of latest ledger close (protocol 23+)
/// - [oldestLedger]: Oldest available ledger on RPC server (protocol 23+)
/// - [oldestLedgerCloseTime]: Unix timestamp of oldest ledger close (protocol 23+)
///
/// Example - Basic event monitoring:
/// ```dart
/// final server = SorobanServer(rpcUrl);
///
/// // Query events from a contract
/// final contractIds = [StrKey.encodeContractIdHex(contractId)];
/// final request = GetEventsRequest(
///   startLedger: 1000000,
///   filters: [EventFilter(contractIds: contractIds)],
///   paginationOptions: PaginationOptions(limit: 100),
/// );
///
/// final response = await server.getEvents(request);
///
/// print('Found ${response.events?.length ?? 0} events');
/// print('Latest ledger: ${response.latestLedger}');
///
/// if (response.events != null) {
///   for (var event in response.events!) {
///     print('Event ID: ${event.id}');
///     print('Contract: ${event.contractId}');
///     print('Type: ${event.type}');
///     print('Topics: ${event.topic.length}');
///
///     // Decode event value
///     final value = event.valueXdr;
///     // Process value based on contract spec
///   }
/// }
/// ```
///
/// Example - Paginated event streaming:
/// ```dart
/// String? cursor;
///
/// do {
///   final request = GetEventsRequest(
///     startLedger: startLedger,
///     filters: [EventFilter(contractIds: [contractAddress])],
///     paginationOptions: PaginationOptions(cursor: cursor, limit: 100),
///   );
///
///   final response = await server.getEvents(request);
///
///   if (response.events != null) {
///     for (var event in response.events!) {
///       // Process each event
///       await processEvent(event);
///     }
///   }
///
///   cursor = response.cursor;
///
///   // Add delay to avoid rate limiting
///   await Future.delayed(Duration(milliseconds: 100));
/// } while (cursor != null);
/// ```
///
/// Example - Filtering by topics:
/// ```dart
/// // Filter events with specific topic structure
/// final topicFilter = TopicFilter(['*', 'transfer', '*']);
/// final filter = EventFilter(
///   contractIds: [contractAddress],
///   topics: [topicFilter],
/// );
///
/// final request = GetEventsRequest(
///   startLedger: startLedger,
///   filters: [filter],
/// );
///
/// final response = await server.getEvents(request);
/// ```
///
/// See also:
/// - [EventInfo] for individual event details
/// - [GetEventsRequest] for request parameters and filtering
/// - [EventFilter] for event filtering options
/// - [PaginationOptions] for pagination control
/// - [Soroban RPC Documentation](https://developers.stellar.org/docs/data/rpc/api-reference/methods/getEvents)
class GetEventsResponse extends SorobanRpcResponse {
  int? latestLedger;

  /// If error is present then results will not be in the response
  List<EventInfo>? events;

  /// For paging, only available for protocol version >= 22
  String? cursor;

  /// The unix timestamp of the close time of the latest ledger known to Soroban-RPC at the time it handled the request.
  /// Only available for protocol version >= 23
  String? latestLedgerCloseTime;

  /// The oldest ledger ingested by Soroban-RPC at the time it handled the request.
  /// Only available for protocol version >= 23
  int? oldestLedger;

  /// The unix timestamp of the close time of the oldest ledger ingested by Soroban-RPC at the time it handled the request.
  /// Only available for protocol version >= 23
  String? oldestLedgerCloseTime;

  /// Creates a GetEventsResponse from JSON-RPC response.
  ///
  /// Contains paginated list of contract events.
  GetEventsResponse(Map<String, dynamic> jsonResponse) : super(jsonResponse);

  factory GetEventsResponse.fromJson(Map<String, dynamic> json) {
    GetEventsResponse response = GetEventsResponse(json);
    if (json['result'] != null) {
      if (json['result']['events'] != null) {
        response.events = List<EventInfo>.from(
            json['result']['events'].map((e) => EventInfo.fromJson(e)));
      }
      response.latestLedger = json['result']['latestLedger'];
      response.cursor = json['result']['cursor'];
      response.latestLedgerCloseTime = json['result']['latestLedgerCloseTime'];
      response.oldestLedger = json['result']['oldestLedger'];
      response.oldestLedgerCloseTime = json['result']['oldestLedgerCloseTime'];
    } else if (json['error'] != null) {
      response.error = SorobanRpcErrorResponse.fromJson(json);
    }
    return response;
  }
}

/// Detailed information about a single event emitted by a Soroban smart contract.
///
/// EventInfo represents an event generated during contract execution. Events are the
/// primary mechanism for contracts to communicate state changes and emit structured
/// notifications that applications can monitor, filter, and react to.
///
/// Event Structure:
/// Events consist of:
/// - Topics: Indexed fields for efficient filtering (similar to Ethereum event topics)
/// - Value: The event data payload (XDR-encoded SCVal)
/// - Metadata: Contract ID, ledger, transaction hash, timestamps
///
/// Events can be:
/// - Contract events: Explicitly emitted by contract code
/// - System events: Generated by the Soroban runtime
/// - Diagnostic events: For debugging and internal monitoring
///
/// Topic Filtering:
/// Topics are indexed and can be filtered efficiently:
/// - `Topic[0]`: Often the event name or identifier
/// - `Topic[1..n]`: Event-specific indexed parameters
/// - Use wildcards ('*') in topic filters for flexible matching
///
/// Fields:
/// - [type]: Event type (contract, system, diagnostic)
/// - [ledger]: Ledger sequence number where event was emitted
/// - [ledgerCloseAt]: ISO8601 timestamp of ledger close
/// - [contractId]: Contract that emitted the event (C... address)
/// - [id]: Unique event identifier
/// - [topic]: List of base64-encoded XDR topic values for filtering
/// - [value]: Base64-encoded XDR event data payload
/// - [inSuccessfulContractCall]: Whether event was in successful call
/// - [txHash]: Transaction hash that generated the event
/// - [opIndex]: Operation index in transaction (protocol 23+)
/// - [txIndex]: Transaction index in ledger (protocol 23+)
///
/// Example - Processing events:
/// ```dart
/// final response = await server.getEvents(request);
///
/// if (response.events != null) {
///   for (var event in response.events!) {
///     print('Event from contract: ${event.contractId}');
///     print('Transaction: ${event.txHash}');
///     print('Ledger: ${event.ledger} at ${event.ledgerCloseAt}');
///     print('Topics: ${event.topic.length}');
///
///     // Decode event value
///     final value = event.valueXdr;
///     if (value.map != null) {
///       // Process map data
///       for (var entry in value.map!.entries) {
///         print('Key: ${entry.key}, Value: ${entry.val}');
///       }
///     }
///
///     // Process topics
///     for (var topicXdr in event.topic) {
///       final topic = XdrSCVal.fromBase64EncodedXdrString(topicXdr);
///       if (topic.sym != null) {
///         print('Topic symbol: ${topic.sym}');
///       }
///     }
///   }
/// }
/// ```
///
/// Example - Filtering by event signature:
/// ```dart
/// // Listen for "transfer" events
/// final transferEvents = response.events?.where((event) {
///   if (event.topic.isEmpty) return false;
///
///   // First topic often contains event name
///   final firstTopic = XdrSCVal.fromBase64EncodedXdrString(event.topic.first);
///   return firstTopic.sym == 'transfer';
/// }).toList();
///
/// for (var event in transferEvents ?? []) {
///   // Decode transfer event data
///   final value = event.valueXdr;
///   print('Transfer event: $value');
/// }
/// ```
///
/// Example - Monitoring contract state changes:
/// ```dart
/// // Stream events and update local state
/// await for (var batch in getEventStream(contractId)) {
///   for (var event in batch) {
///     if (event.inSuccessfulContractCall ?? false) {
///       // Decode and process event
///       final eventData = event.valueXdr;
///
///       // Update local cache/state based on event
///       await updateLocalState(event.contractId, eventData);
///
///       print('State updated from ledger ${event.ledger}');
///     }
///   }
/// }
/// ```
///
/// See also:
/// - [GetEventsResponse] for querying events
/// - [EventFilter] for filtering by contract, topics, and type
/// - [XdrSCVal] for decoding event topics and values
/// - [XdrContractEvent] for the underlying XDR structure
class EventInfo {
  String type;
  int ledger;
  String ledgerCloseAt;
  String contractId;
  String id;
  List<String> topic;
  String value;
  bool? inSuccessfulContractCall;
  String txHash;
  // starting from protocol 23 opIndex, txIndex will be filled.
  int? opIndex;
  int? txIndex;

  /// Creates an EventInfo with event details.
  ///
  /// Contains complete event information including topics, value, and metadata.
  EventInfo(
    this.type,
    this.ledger,
    this.ledgerCloseAt,
    this.contractId,
    this.id,
    this.topic,
    this.value,
    this.inSuccessfulContractCall,
    this.txHash,
    this.opIndex,
    this.txIndex,
  );

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
      topic,
      value,
      json['inSuccessfulContractCall'],
      json['txHash'],
      json['opIndex'],
      json['txIndex'],
    );
  }

  XdrSCVal get valueXdr => XdrSCVal.fromBase64EncodedXdrString(value);
}

/// Footprint received when simulating a transaction.
/// Contains utility functions.
class Footprint {
  XdrLedgerFootprint xdrFootprint;

  /// Creates a Footprint with XDR ledger footprint.
  ///
  /// Contains ledger keys accessed by the transaction.
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

  /// Creates a JsonRpcMethod with method name and arguments.
  ///
  /// Contains JSON-RPC method call parameters for Soroban RPC.
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
