// Copyright 2023 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'soroban_http_stub.dart' if (dart.library.io) 'soroban_http_io.dart';
import 'package:stellar_flutter_sdk/src/account.dart';
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_contract_parser.dart';
import '../xdr/xdr.dart';
import 'soroban_auth.dart';
import '../transaction.dart';
import '../requests/request_builder.dart';
import '../util.dart';

import 'package:stellar_flutter_sdk/stub/web.dart'
    if (dart.library.io) 'package:stellar_flutter_sdk/stub/non-web.dart';

import 'soroban_ledger_event_responses.dart';
import 'soroban_rpc_requests.dart';
import 'soroban_rpc_responses.dart';
import 'soroban_transaction_responses.dart';

export 'soroban_ledger_event_responses.dart';
export 'soroban_rpc_requests.dart';
export 'soroban_rpc_responses.dart';
export 'soroban_transaction_responses.dart';

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
/// - [_serverUrl] URL of the Soroban RPC server endpoint
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
  /// Parameters:
  /// - [_serverUrl] URL of the Soroban RPC server endpoint
  /// - [httpClient] Optional preconfigured Dio instance used for all requests.
  ///   Provide one to customize networking, e.g. proxies, interceptors,
  ///   timeouts or certificate pinning. If omitted, a default instance is
  ///   created. The SDK request headers are applied per request either way.
  ///
  /// Initializes the client with default HTTP headers for JSON-RPC communication.
  /// For most use cases, this is the primary constructor for connecting to Soroban RPC endpoints.
  ///
  /// Example:
  /// ```dart
  /// final customDio = dio.Dio()
  ///   ..options.connectTimeout = const Duration(seconds: 5);
  /// final server = SorobanServer(
  ///   'https://soroban-testnet.stellar.org:443',
  ///   httpClient: customDio,
  /// );
  /// ```
  SorobanServer(this._serverUrl, {dio.Dio? httpClient}) {
    if (httpClient != null) {
      _dio = httpClient;
    }
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
  ///
  /// The overrides are applied to the Dio instance in use, including one
  /// injected via the constructor's httpClient parameter; the instance is
  /// kept, not replaced. Instances with a non-IO HTTP client adapter are
  /// left unchanged.
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

      configureHttpOverrides(_dio, setOverrides);
    }
  }

  /// Sends the JSON-RPC request for [method] with optional [args] to the
  /// server and converts the JSON response with [fromJson].
  Future<T> _postRequest<T>(
      String method, T Function(Map<String, dynamic> json) fromJson,
      {Object? args}) async {
    JsonRpcMethod request = JsonRpcMethod(method, args: args);
    dio.Response response = await _dio.post(_serverUrl,
        data: json.encode(request), options: dio.Options(headers: _headers));
    if (enableLogging) {
      print("$method response: $response");
    }
    return fromJson(response.data);
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
  /// - latestLedgerCloseTime: Unix timestamp (seconds, as string) of the latest
  ///   ledger close; null on servers below RPC v27.1.0
  /// - oldestLedgerCloseTime: Unix timestamp (seconds, as string) of the oldest
  ///   ledger close; null on servers below RPC v27.1.0
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
    return _postRequest("getHealth", GetHealthResponse.fromJson);
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
    return _postRequest("getVersionInfo", GetVersionInfoResponse.fromJson);
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
    return _postRequest("getFeeStats", GetFeeStatsResponse.fromJson);
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
    return _postRequest("getLatestLedger", GetLatestLedgerResponse.fromJson);
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
  /// - [base64EncodedKeys] List of base64-encoded XdrLedgerKey values identifying the entries
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
    return _postRequest("getLedgerEntries", GetLedgerEntriesResponse.fromJson,
        args: {'keys': base64EncodedKeys});
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
  /// - [accountId] The account ID (public key) to query, in Stellar address format (G...)
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
  /// - [dio.DioException] On network failures or RPC errors
  /// - [FormatException] If the response cannot be parsed
  /// - [Exception] If accountId is invalid or ledger entry decoding fails
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
        BigInt seqNr = accountEntry.seqNum.sequenceNumber;
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
  /// - [contractId] Contract ID (hex-encoded hash) of the contract containing the data
  /// - [key] Storage key as XdrSCVal identifying which data to retrieve
  /// - [durability] Storage tier where the data is stored:
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
    return _getContractDataForAddress(
        Address.forContractId(contractId).toXdr(), key, durability);
  }

  /// Address-typed body shared by [getContractData] and
  /// [getExternalRefWasmHash].
  Future<LedgerEntry?> _getContractDataForAddress(XdrSCAddress contract,
      XdrSCVal key, XdrContractDataDurability durability) async {
    XdrLedgerKey ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
    ledgerKey.contractData =
        XdrLedgerKeyContractData(contract, key, durability);
    GetLedgerEntriesResponse ledgerEntriesResponse =
        await getLedgerEntries([ledgerKey.toBase64EncodedXdrString()]);
    if (ledgerEntriesResponse.entries != null &&
        ledgerEntriesResponse.entries!.length > 0) {
      return ledgerEntriesResponse.entries![0];
    }
    return null;
  }

  /// Resolves a CAP-85 external executable reference to the wasm hash it names.
  ///
  /// A contract created from an external reference does not carry its own code
  /// hash. The reference names an owner contract and a tag, and the owner holds
  /// a persistent contract data entry keyed by that tag whose value is the
  /// 32-byte hash of an already uploaded wasm. This method reads that entry off
  /// the ledger; the owner contract is not invoked.
  ///
  /// The tag entry is matched byte for byte, so the tag is passed through
  /// exactly as the reference carries it.
  ///
  /// Parameters:
  /// - [ref] The external reference naming the owner contract and the tag
  ///
  /// Returns the 32-byte wasm hash, or null when:
  /// - the owner address is not a contract address; only a contract can hold
  ///   the tag entry
  /// - the owner has no entry under the tag, or the entry was archived
  /// - the entry is not a contract data entry, its value is not an SCV_BYTES
  ///   value, or the value is not exactly 32 bytes long
  /// - the RPC answered with an error; the error is carried on the response
  ///   object of the underlying getLedgerEntries request, and the entry list
  ///   stays null
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final instanceEntry = await server.getContractData(contractId,
  ///     XdrSCVal.forLedgerKeyContractInstance(),
  ///     XdrContractDataDurability.PERSISTENT);
  /// final executable = instanceEntry?.ledgerEntryDataXdr.contractData?.val
  ///     .instance?.executable;
  /// if (executable?.externalRef != null) {
  ///   final wasmHash =
  ///       await server.getExternalRefWasmHash(executable!.externalRef!);
  ///   print('runs wasm: ${wasmHash != null ? Util.bytesToHex(wasmHash) : 'unresolved'}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [loadContractCodeForContractId], which applies this resolution
  ///   automatically when it meets an external reference executable
  Future<Uint8List?> getExternalRefWasmHash(
      XdrContractExecutableExternalRef ref) async {
    if (ref.executableOwner.discriminant !=
        XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT) {
      return null;
    }
    LedgerEntry? entry = await _getContractDataForAddress(
        ref.executableOwner,
        XdrSCVal.forExecutableTag(ref.tag),
        XdrContractDataDurability.PERSISTENT);
    if (entry == null) {
      return null;
    }
    XdrSCVal? value = entry.ledgerEntryDataXdr.contractData?.val;
    if (value == null ||
        value.discriminant != XdrSCValType.SCV_BYTES ||
        value.bytes == null ||
        value.bytes!.sCBytes.length != 32) {
      return null;
    }
    return value.bytes!.sCBytes;
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
  /// - [wasmId] Hex-encoded hash of the contract WebAssembly bytecode
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
  /// This method first retrieves the contract instance, determines the wasm
  /// hash from its executable, then loads the corresponding contract code:
  /// - a wasm executable carries the hash directly
  /// - a CAP-85 external reference executable is resolved through the owner
  ///   contract's tag entry via [getExternalRefWasmHash]
  /// - a Stellar Asset Contract has no wasm on chain and yields null
  ///
  /// Use this when you have a contract ID but need to access the underlying bytecode.
  /// Multiple contracts can share the same bytecode (same Wasm ID) if they were
  /// created from the same uploaded code.
  ///
  /// Parameters:
  /// - [contractId] Hex-encoded contract ID (hash derived from contract address)
  ///
  /// Returns: XdrContractCodeEntry containing:
  /// - code: DataValue with the raw WebAssembly bytecode
  /// - ext: Extension field for future protocol upgrades
  ///
  /// Returns null if:
  /// - The contract instance does not exist
  /// - The instance is a Stellar Asset Contract
  /// - The instance carries an external reference that does not resolve; see
  ///   [getExternalRefWasmHash] for the cases
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
      XdrContractExecutable? executable =
          ledgerEntryData.contractData?.val.instance?.executable;
      if (executable == null) {
        return null;
      }
      if (executable.discriminant ==
              XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM &&
          executable.wasmHash != null) {
        return await loadContractCodeForWasmId(
            Util.bytesToHex(executable.wasmHash!.hash));
      }
      if (executable.discriminant ==
              XdrContractExecutableType.CONTRACT_EXECUTABLE_EXTERNAL_REF &&
          executable.externalRef != null) {
        Uint8List? wasmHash =
            await getExternalRefWasmHash(executable.externalRef!);
        if (wasmHash != null) {
          return await loadContractCodeForWasmId(Util.bytesToHex(wasmHash));
        }
      }
    }
    return null;
  }

  /// Loads and parses contract metadata for a given contract ID.
  ///
  /// This is a convenience method that combines loading the contract bytecode and parsing
  /// it to extract structured metadata. It performs these steps:
  /// 1. Retrieves the contract instance to get the Wasm ID, resolving a CAP-85
  ///    external reference executable through [getExternalRefWasmHash]
  /// 2. Loads the contract code entry
  /// 3. Parses the WebAssembly bytecode to extract metadata sections
  ///
  /// The parsed information includes the contract specification (function signatures,
  /// types), environment metadata (SDK version, protocol requirements), and custom
  /// contract metadata.
  ///
  /// Parameters:
  /// - [contractId] Hex-encoded contract ID to load and parse
  ///
  /// Returns: [SorobanContractInfo] containing environment version, spec entries,
  /// and contract metadata. Returns null if the contract does not exist, if the
  /// instance is a Stellar Asset Contract, or if it carries an external reference
  /// that does not resolve.
  ///
  /// Throws:
  /// - [SorobanContractParserFailed] If bytecode parsing fails due to invalid format
  /// - [Exception] If the RPC request fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final contractId = 'c5b1...';
  ///
  /// try {
  ///   final info = await server.loadContractInfoForContractId(contractId);
  ///   if (info != null) {
  ///     print('Protocol version: ${info.envProtocolVersion}');
  ///     for (final entry in info.specEntries) {
  ///       if (entry.functionV0 != null) {
  ///         print('Function: ${entry.functionV0!.name}');
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
    var byteCode = contractCodeEntry.code;
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
  /// - [wasmId] Hex-encoded hash of the contract WebAssembly bytecode
  ///
  /// Returns: [SorobanContractInfo] containing environment version, spec entries,
  /// and contract metadata. Returns null if no contract code exists with the given Wasm ID.
  ///
  /// Throws:
  /// - [SorobanContractParserFailed] If bytecode parsing fails due to invalid format
  /// - [Exception] If the RPC request fails
  ///
  /// Example:
  /// ```dart
  /// final server = SorobanServer('https://soroban-testnet.stellar.org:443');
  /// final wasmId = 'f3b5...'; // From contract upload result
  ///
  /// try {
  ///   final info = await server.loadContractInfoForWasmId(wasmId);
  ///   if (info != null) {
  ///     print('Protocol version: ${info.envProtocolVersion}');
  ///     for (final entry in info.metaEntries.entries) {
  ///       print('${entry.key}: ${entry.value}');
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
    var byteCode = contractCodeEntry.code;
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
    return _postRequest("getNetwork", GetNetworkResponse.fromJson);
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
  /// - [request] SimulateTransactionRequest containing the transaction to simulate
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
    return _postRequest(
        "simulateTransaction", SimulateTransactionResponse.fromJson,
        args: request.getRequestArgs());
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
  /// - [transaction] The signed Transaction to submit
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

    return _postRequest("sendTransaction", SendTransactionResponse.fromJson,
        args: {'transaction': transactionEnvelopeXdr});
  }

  /// Retrieves the status and results of a submitted transaction.
  ///
  /// Use this method to poll for transaction completion after calling sendTransaction.
  /// The transaction hash is returned by sendTransaction.
  ///
  /// Parameters:
  /// - [transactionHash] Hash of the transaction to query (hex-encoded)
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
    return _postRequest("getTransaction", GetTransactionResponse.fromJson,
        args: {'hash': transactionHash});
  }

  /// Polls for transaction completion.
  ///
  /// Repeatedly invokes [getTransaction] until the transaction reaches a final
  /// state (`SUCCESS` or `FAILED`) or [maxAttempts] is reached. The default
  /// configuration polls 30 attempts at 1-second intervals.
  ///
  /// Transient RPC errors (network glitches, rate limiting, and other
  /// temporary failures) are swallowed inside the poll loop so polling
  /// continues until [maxAttempts] is exhausted. The method returns the most
  /// recent successful response: this may have status `NOT_FOUND` if the
  /// transaction was not yet observed before the attempt budget ran out, or
  /// `SUCCESS` / `FAILED` once a final status was reached. If every poll
  /// attempt fails to obtain any response from the RPC server the most
  /// recent caught exception is rethrown.
  ///
  /// Parameters:
  /// - [hash] Transaction hash as a hex string.
  /// - [maxAttempts] Maximum number of polling attempts. Must be greater than
  ///   zero. Defaults to `30`.
  /// - [sleepStrategy] Function mapping the 1-indexed attempt number to the
  ///   sleep [Duration] applied between attempts. The default strategy waits
  ///   one second between attempts regardless of attempt number. Pass a custom
  ///   function (for example, exponential backoff) to change the polling
  ///   cadence.
  ///
  /// Returns the final [GetTransactionResponse] (which may still have status
  /// `NOT_FOUND` if [maxAttempts] is reached without observing the
  /// transaction).
  ///
  /// Throws:
  /// - [ArgumentError] when [maxAttempts] is less than or equal to zero.
  /// - The most recently caught [Exception] when every poll attempt failed
  ///   without ever obtaining a response from the RPC server.
  /// - [StateError] as a defensive guard if the loop terminates without
  ///   producing either a response or an error (this indicates a logic bug
  ///   and should never be observed in practice).
  ///
  /// Example:
  /// ```dart
  /// final response = await server.pollTransaction(txHash);
  /// if (response.status == GetTransactionResponse.STATUS_SUCCESS) {
  ///   final returnValue = response.getResultValue();
  ///   print('Success! Return value: $returnValue');
  /// } else if (response.status == GetTransactionResponse.STATUS_FAILED) {
  ///   print('Transaction failed: ${response.resultXdr}');
  /// }
  ///
  /// // Custom polling cadence with exponential backoff:
  /// final fast = await server.pollTransaction(
  ///   txHash,
  ///   maxAttempts: 10,
  ///   sleepStrategy: (attempt) => Duration(milliseconds: attempt * 500),
  /// );
  /// ```
  Future<GetTransactionResponse> pollTransaction(
    String hash, {
    int maxAttempts = 30,
    Duration Function(int attempt) sleepStrategy = _defaultPollSleep,
  }) async {
    if (maxAttempts <= 0) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'maxAttempts must be greater than 0',
      );
    }

    var attempts = 0;
    GetTransactionResponse? lastResponse;
    Object? lastError;

    while (attempts < maxAttempts) {
      try {
        final response = await getTransaction(hash);
        lastResponse = response;
        lastError = null;
        if (response.status != GetTransactionResponse.STATUS_NOT_FOUND) {
          return response;
        }
      } on Exception catch (e) {
        lastError = e;
      }

      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(sleepStrategy(attempts));
      }
    }

    if (lastResponse != null) {
      return lastResponse;
    }
    if (lastError != null) {
      throw lastError;
    }
    throw StateError('pollTransaction terminated without a response');
  }

  /// Releases the underlying HTTP transport held by this server.
  ///
  /// Closes the internal Dio HTTP client so its connection pool and any
  /// associated keep-alive sockets are torn down. After calling close, this
  /// SorobanServer instance must not be used for further RPC calls; any
  /// subsequent request will throw because the transport is shut down.
  ///
  /// Idempotent: calling close more than once is safe; the underlying Dio
  /// client tolerates repeated close invocations.
  ///
  /// The forceful close flag is intentionally left at the Dio default
  /// (`force: false`) so any in-flight requests are allowed to complete
  /// before sockets are released. Callers that need a hard tear-down should
  /// cancel in-flight work first via their own cancellation token.
  void close() {
    _dio.close(force: false);
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
  /// - [request] GetEventsRequest with filters and pagination options
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
    return _postRequest("getEvents", GetEventsResponse.fromJson,
        args: request.getRequestArgs());
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
  /// - [request] GetTransactionsRequest containing:
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
    return _postRequest("getTransactions", GetTransactionsResponse.fromJson,
        args: request.getRequestArgs());
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
    return _postRequest("getLedgers", GetLedgersResponse.fromJson,
        args: request.getRequestArgs());
  }
}

Duration _defaultPollSleep(int attempt) => const Duration(milliseconds: 1000);

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

  /// Returns a string representation of this instance for debugging.
  @override
  String toString() => 'JsonRpcMethod: ${toJson()}';
}
