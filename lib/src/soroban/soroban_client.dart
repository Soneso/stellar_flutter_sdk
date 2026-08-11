// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/account.dart';
import 'package:stellar_flutter_sdk/src/constants/network_constants.dart';
import 'package:stellar_flutter_sdk/src/invoke_host_function_operation.dart';
import 'package:stellar_flutter_sdk/src/restore_footprint_operation.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_auth.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_contract_parser.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_server.dart';
import 'package:stellar_flutter_sdk/src/soroban/contract_spec.dart';
import 'package:stellar_flutter_sdk/src/transaction.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';

import '../key_pair.dart';
import '../network.dart';

/// High-level client for interacting with deployed Soroban smart contracts.
///
/// SorobanClient provides a convenient interface for invoking contract methods,
/// handling authorization, and managing transactions. It automatically:
/// - Loads contract specifications and method signatures
/// - Simulates transactions before submission
/// - Handles resource footprints and fees
/// - Manages authorization entries
/// - Polls for transaction completion
///
/// The client simplifies common workflows like:
/// - Reading contract data (read-only calls)
/// - Writing to contracts (state-changing calls)
/// - Deploying new contracts
/// - Installing contract code
///
/// Example - Basic contract interaction:
/// ```dart
/// try {
///   final options = ClientOptions(
///     sourceAccountKeyPair: myKeyPair,
///     contractId: 'CABC...',
///     network: Network.TESTNET,
///     rpcUrl: 'https://soroban-testnet.stellar.org:443',
///   );
///
///   final client = await SorobanClient.forClientOptions(options: options);
///
///   // Read-only call (automatically detected, no signing needed)
///   final balance = await client.invokeMethod(
///     name: 'balance',
///     args: [Address.forAccountId(accountId).toXdrSCVal()],
///   );
///
///   // Write call (automatically signed and submitted)
///   final result = await client.invokeMethod(
///     name: 'transfer',
///     args: [
///       Address.forAccountId(fromAccount).toXdrSCVal(),
///       Address.forAccountId(toAccount).toXdrSCVal(),
///       XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000)),
///     ],
///   );
/// } catch (e) {
///   print('Contract invocation failed: $e');
/// }
/// ```
///
/// Example - Deploy a contract (complete workflow):
/// ```dart
/// try {
///   // Step 1: Install the contract code
///   final wasmBytes = await File('contract.wasm').readAsBytes();
///   final installRequest = InstallRequest(
///     wasmBytes: wasmBytes,
///     sourceAccountKeyPair: myKeyPair,
///     network: Network.TESTNET,
///     rpcUrl: rpcUrl,
///   );
///
///   final wasmHash = await SorobanClient.install(installRequest: installRequest);
///   print('Contract installed with hash: $wasmHash');
///
///   // Step 2: Deploy the contract instance
///   final deployRequest = DeployRequest(
///     sourceAccountKeyPair: myKeyPair,
///     network: Network.TESTNET,
///     rpcUrl: rpcUrl,
///     wasmHash: wasmHash,
///     constructorArgs: [XdrSCVal.forU32(initialValue)],
///     // Optional: provide custom salt for deterministic contract ID
///     // salt: XdrUint256(customSaltBytes),
///   );
///
///   final client = await SorobanClient.deploy(deployRequest: deployRequest);
///   print('Contract deployed: ${client.getContractId()}');
///
///   // Step 3: Interact with deployed contract
///   final result = await client.invokeMethod(
///     name: 'initialize',
///     args: [XdrSCVal.forU32(42)],
///   );
///   print('Contract initialized successfully');
/// } catch (e) {
///   print('Deployment failed: $e');
/// }
/// ```
///
/// See also:
/// - [AssembledTransaction] for advanced transaction control
/// - [SorobanServer] for low-level RPC access
/// - [ContractSpec] for type conversion utilities
/// - [Soroban Documentation](https://developers.stellar.org/docs/build/smart-contracts/overview)
class SorobanClient {
  static const _CONSTRUCTOR_FUNC = "__constructor";
  List<XdrSCSpecEntry> _specEntries =
      List<XdrSCSpecEntry>.empty(growable: true);

  /// Client options for interacting with soroban.
  ClientOptions _options;

  /// Contract method names extracted from the spec entries
  List<String> _methodNames = List<String>.empty(growable: true);

  /// Contract specification utility
  late final ContractSpec _contractSpec;

  /// Private constructor that requires pre-loaded contract specification entries.
  ///
  /// This constructor is private to ensure proper contract initialization.
  /// Use factory methods instead:
  /// - [SorobanClient.forClientOptions] - Automatically loads contract spec from chain
  /// - [SorobanClient.deploy] - Deploys a new contract and returns initialized client
  ///
  /// Factory methods handle contract spec loading and validation automatically.
  SorobanClient._(this._specEntries, this._options) {
    _contractSpec = ContractSpec(_specEntries);
    for (XdrSCSpecEntry entry in _specEntries) {
      if (entry.discriminant == XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0) {
        final function = entry.functionV0;
        if (function == null || function.name == _CONSTRUCTOR_FUNC) {
          continue;
        }
        _methodNames.add(function.name);
      }
    }
  }

  /// Loads the contract info for the contractId provided by the [options],
  /// and then constructs a SorobanClient by using the loaded contract info.
  static Future<SorobanClient> forClientOptions(
      {required ClientOptions options}) async {
    SorobanServer server;
    if (options.server != null) {
      server = options.server!;
    } else {
      server = SorobanServer(options.rpcUrl);
      server.enableLogging = options.enableServerLogging;
    }
    final info = await server.loadContractInfoForContractId(options.contractId);
    if (info != null) {
      return SorobanClient._(info.specEntries, options);
    } else {
      throw new Exception(
          "Could not load contract info for the contract: ${options.contractId}");
    }
  }

  /// After deploying the contract it creates and returns a new SorobanClient for the deployed contract.
  /// The contract must be installed before calling this method. You can use `SorobanClient.install`
  /// to install the contract.
  static Future<SorobanClient> deploy(
      {required DeployRequest deployRequest}) async {
    // Load the spec from the wasm code entry before deploying: the code entry
    // was settled by the install transaction, while reading the contract
    // instance right after deployment races the RPC's ledger-entry ingestion,
    // so a successful deployment could surface as a load failure.
    SorobanServer server;
    if (deployRequest.server != null) {
      server = deployRequest.server!;
    } else {
      server = SorobanServer(deployRequest.rpcUrl);
      server.enableLogging = deployRequest.enableSorobanServerLogging;
    }
    SorobanContractInfo? contractInfo;
    try {
      contractInfo =
          await server.loadContractInfoForWasmId(deployRequest.wasmHash);
    } on SorobanContractParserFailed {
      contractInfo = null; // code without a parseable spec: fall back below
    }

    final sourceAddress =
        Address.forAccountId(deployRequest.sourceAccountKeyPair.accountId);
    final createContractHostFunction =
        CreateContractWithConstructorHostFunction(sourceAddress,
            deployRequest.wasmHash, deployRequest.constructorArgs ?? [],
            salt: deployRequest.salt);

    final op = InvokeHostFuncOpBuilder(createContractHostFunction).build();
    final clientOptions = ClientOptions(
        sourceAccountKeyPair: deployRequest.sourceAccountKeyPair,
        contractId: "ignored",
        network: deployRequest.network,
        rpcUrl: deployRequest.rpcUrl,
        server: deployRequest.server,
        enableServerLogging: deployRequest.enableSorobanServerLogging);
    final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: deployRequest.methodOptions,
        method: SorobanClient._CONSTRUCTOR_FUNC,
        arguments: deployRequest.constructorArgs,
        enableSorobanServerLogging: deployRequest.enableSorobanServerLogging);
    final tx =
        await AssembledTransaction.buildWithOp(operation: op, options: options);
    final response = await tx.signAndSend();
    final contractId = response.getCreatedContractId();
    if (contractId == null) {
      throw Exception("Could not get contract id for deployed contract");
    }
    clientOptions.contractId = StrKey.encodeContractIdHex(contractId);
    if (contractInfo != null) {
      return SorobanClient._(contractInfo.specEntries, clientOptions);
    }
    return SorobanClient.forClientOptions(options: clientOptions);
  }

  /// Installs (uploads) the given contract code to soroban.
  /// If successfully it returns the wasm hash of the installed contract as a hex string.
  static Future<String> install(
      {required InstallRequest installRequest, bool force = false}) async {
    final uploadContractHostFunction =
        UploadContractWasmHostFunction(installRequest.wasmBytes);
    final op = InvokeHostFuncOpBuilder(uploadContractHostFunction).build();
    final clientOptions = ClientOptions(
        sourceAccountKeyPair: installRequest.sourceAccountKeyPair,
        contractId: "ignored",
        network: installRequest.network,
        rpcUrl: installRequest.rpcUrl,
        server: installRequest.server,
        enableServerLogging: installRequest.enableSorobanServerLogging);
    final options = AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(),
        method: "ignored",
        enableSorobanServerLogging: installRequest.enableSorobanServerLogging);
    final tx =
        await AssembledTransaction.buildWithOp(operation: op, options: options);

    if (!force && tx.isReadCall()) {
      final simulationData = tx.getSimulationData();
      final returnedValue = simulationData.returnedValue;
      if (returnedValue.bytes == null) {
        throw Exception("Could not extract wasm hash from simulation result");
      } else {
        return Util.bytesToHex(returnedValue.bytes!.sCBytes);
      }
    }

    final response = await tx.signAndSend(force: force);
    final wasmHash = response.getWasmId();
    if (wasmHash == null) {
      throw new Exception("Could not get wasm hash for installed contract");
    }
    return wasmHash;
  }

  /// Invokes a contract method and returns the result.
  ///
  /// This is the primary method for contract interaction. It automatically:
  /// - Validates the method exists in the contract
  /// - Simulates the transaction
  /// - Determines if it's a read or write call
  /// - For read calls: returns simulation result immediately
  /// - For write calls: signs, submits, and waits for completion
  ///
  /// Parameters:
  /// - [name] Name of the contract method to invoke
  /// - [args] Method arguments as XdrSCVal values (optional)
  /// - [force] If true, signs and submits even for read-only calls (default: false)
  /// - [methodOptions] Custom fee, timeout, and simulation options
  ///
  /// Returns: XdrSCVal containing the method's return value
  ///
  /// Throws:
  /// - Exception If method doesn't exist, simulation fails, or transaction fails
  ///
  /// Example - Read call:
  /// ```dart
  /// // Get account balance (read-only, no signing needed)
  /// final accountArg = Address.forAccountId('GABC...').toXdrSCVal();
  /// final balance = await client.invokeMethod(
  ///   name: 'balance',
  ///   args: [accountArg],
  /// );
  ///
  /// // Extract integer value
  /// if (balance.i128 != null) {
  ///   final amount = balance.i128!.lo.int64;
  ///   print('Balance: $amount');
  /// }
  /// ```
  ///
  /// Example - Write call:
  /// ```dart
  /// // Transfer tokens (state-changing, automatically signed and submitted)
  /// final fromArg = Address.forAccountId('GABC...').toXdrSCVal();
  /// final toArg = Address.forAccountId('GDEF...').toXdrSCVal();
  /// final amountArg = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000));
  ///
  /// final result = await client.invokeMethod(
  ///   name: 'transfer',
  ///   args: [fromArg, toArg, amountArg],
  /// );
  ///
  /// print('Transfer successful: $result');
  /// ```
  ///
  /// Example - Custom options:
  /// ```dart
  /// final options = MethodOptions(
  ///   fee: 200,  // Higher fee for faster inclusion
  ///   timeoutInSeconds: 60,  // Wait up to 60 seconds
  ///   restore: true,  // Auto-restore expired entries
  /// );
  ///
  /// final result = await client.invokeMethod(
  ///   name: 'complexOperation',
  ///   args: [arg1, arg2],
  ///   methodOptions: options,
  /// );
  /// ```
  ///
  /// See also:
  /// - [buildInvokeMethodTx] for manual transaction control
  /// - [funcArgsToXdrSCValues] for convenient argument conversion
  /// - [MethodOptions] for customizing execution
  Future<XdrSCVal> invokeMethod(
      {required String name,
      List<XdrSCVal>? args,
      bool force = false,
      MethodOptions? methodOptions}) async {
    final tx = await buildInvokeMethodTx(
        name: name, args: args, methodOptions: methodOptions);

    if (!force && tx.isReadCall()) {
      return tx.getSimulationData().returnedValue;
    }

    final response = await tx.signAndSend(force: force);
    if (response.error != null) {
      throw new Exception(
          "Invoke '$name' failed with message: ${response.error!.message} and code: ${response.error!.code}");
    }
    if (response.status != GetTransactionResponse.STATUS_SUCCESS) {
      throw new Exception(
          "Invoke '$name' failed with result: ${response.resultXdr}");
    }
    final result = response.getResultValue();
    if (result == null) {
      throw new Exception(
          "Could not extract return value from '$name' invocation");
    }
    return result;
  }

  /// Creates an  [AssembledTransaction] for invoking the given method by [name] with the args given by [args] if any.
  /// This is usefully if you need to manipulate the transaction before signing and sending.
  Future<AssembledTransaction> buildInvokeMethodTx(
      {required String name,
      List<XdrSCVal>? args,
      MethodOptions? methodOptions = null}) async {
    if (!_methodNames.contains(name)) {
      throw Exception("Method '$name' does not exist");
    }
    final options = AssembledTransactionOptions(
        clientOptions: _options,
        methodOptions: methodOptions ?? MethodOptions(),
        method: name,
        arguments: args,
        enableSorobanServerLogging: _options.enableServerLogging);
    return await AssembledTransaction.build(options: options);
  }

  /// Contract id of the contract represented by this client
  String getContractId() {
    return _options.contractId;
  }

  /// Spec entries of the contract represented by this client.
  List<XdrSCSpecEntry> getSpecEntries() {
    return _specEntries;
  }

  /// Client options for interacting with soroban.
  ClientOptions getOptions() {
    return _options;
  }

  /// Method names of the represented contract.
  List<String> getMethodNames() {
    return _methodNames;
  }

  /// Gets the contract specification utility.
  /// This can be used for advanced type conversion and contract introspection.
  ContractSpec getContractSpec() {
    return _contractSpec;
  }

  /// Convenience method to convert function arguments using ContractSpec.
  /// This simplifies calling contract functions by automatically converting
  /// native Dart values to the correct XdrSCVal types based on the function specification.
  ///
  /// [functionName] The name of the contract function
  /// [args] Map of argument names to values
  ///
  /// Returns a list of XdrSCVal objects ready for contract invocation.
  /// Throws ContractSpecException if the function is not found or arguments are invalid.
  ///
  /// Example:
  /// ```dart
  /// final args = client.funcArgsToXdrSCValues('hello', {'to': 'World'});
  /// final result = await client.invokeHostFunction('hello', args);
  /// ```
  List<XdrSCVal> funcArgsToXdrSCValues(String functionName, Map<String, dynamic> args) {
    return _contractSpec.funcArgsToXdrSCValues(functionName, args);
  }

  /// Convenience method to convert a single value using ContractSpec.
  /// This is useful when you need to convert individual values to XdrSCVal
  /// based on type specifications.
  ///
  /// [val] The native Dart value to convert
  /// [ty] The target type specification
  ///
  /// Returns the converted XdrSCVal.
  /// Throws ContractSpecException for invalid types or conversion failures.
  XdrSCVal nativeToXdrSCVal(dynamic val, XdrSCSpecTypeDef ty) {
    return _contractSpec.nativeToXdrSCVal(val, ty);
  }
}

/// The main workhorse of [SorobanClient]. This class is used to wrap a
/// transaction-under-construction and provide high-level interfaces to the most
/// common workflows, while still providing access to low-level stellar-sdk
/// transaction manipulation.
///
/// Most of the time, you will not construct an [AssembledTransaction] directly,
/// but instead receive one as the return value of a [SorobanClient] method.
///
/// Let's look at examples of how to use [AssembledTransaction] for a variety of
/// use-cases:
///
/// ### 1. Simple read call
///
///  Since these only require simulation, you can get the `result` of the call
///  right after constructing your `AssembledTransaction`:
///
/// ```dart
///
///   final clientOptions = new ClientOptions(
///   sourceAccountKeyPair: sourceAccountKeyPair,
///   contractId: "C123...",
///   network: Network.TESTNET,
///   rpcUrl: "https://...");
///
///   List<XdrSCVal> args = [];
///
///   final txOptions = AssembledTransactionOptions(
///   clientOptions: clientOptions,
///   methodOptions: MethodOptions(),
///   method: "myReadMethod",
///   arguments: args);
///
///   final tx = await AssembledTransaction.build(options: txOptions);
///   final result = await tx.getSimulationData().returnedValue;
/// ```
///
///
/// While that looks pretty complicated, most of the time you will use this in
/// conjunction with [SorobanClient], which simplifies it to:
///
/// ```dart
/// final result = await client.invokeMethod(name: 'myReadMethod', args: args);
/// ```
///
/// ### 2. Simple write call
///
/// For write calls that will be simulated and then sent to the network without
/// further manipulation, only one more step is needed:
///
/// ```dart
///  final tx = await AssembledTransaction.build(options: txOptions);
///
///  final response = await tx.signAndSend();
///  if (response.status == GetTransactionResponse.STATUS_SUCCESS) {
///    final result = response.getResultValue();
///  }
/// ```
///
/// If you are using it in conjunction with [SorobanClient]:
///
/// ```dart
///  final result = await client.invokeMethod(name: "myReadMethod", args: args);
///  ```
///
/// ### 3. More fine-grained control over transaction construction
///
/// If you need more control over the transaction before simulating it, you can
/// set various [MethodOptions] when constructing your
/// [AssembledTransaction]. With a [SorobanClient], this can be passed as an
/// argument when calling `invokeMethod` or `buildInvokeMethodTx` :
///
/// ```dart
/// final methodOptions = MethodOptions(fee: 1000,
/// timeoutInSeconds: 20, simulate: false);
///
/// final tx = await client.buildInvokeMethodTx(name: "myWriteMethod",
/// args: args, methodOptions: methodOptions);
/// ```
///
/// Since we've skipped simulation, we can now edit the `raw` transaction builder and
/// then manually call `simulate`:
///
/// ```dart
///  tx.raw!.addMemo(MemoText("Hello!"));
///  await tx.simulate();
/// ```
///  If you need to inspect the simulation later, you can access it with
///  `tx.getSimulationData()`.
///
/// ### 4. Multi-auth workflows
///
/// Soroban, and Stellar in general, allows multiple parties to sign a
/// transaction.
///
/// Let's consider an Atomic Swap contract. Alice wants to give some of her Token
/// A tokens to Bob for some of his Token B tokens.
///
/// ```dart
/// final swapMethodName = "swap";
///
/// final amountA = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000));
/// final minBForA = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(4500));

/// final amountB = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(5000));
/// final minAForB = XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(950));
///
/// List<XdrSCVal> args = [
///      Address.forAccountId(aliceId).toXdrSCVal(),
///      Address.forAccountId(bobId).toXdrSCVal(),
///      Address.forContractId(tokenAContractId).toXdrSCVal(),
///      Address.forContractId(tokenBContractId).toXdrSCVal(),
///      amountA,
///      minBForA,
///      amountB,
///      minAForB];
/// ```
///
/// Let's say Alice is also going to be the one signing the final transaction
///  envelope, meaning she is the invoker. So your app, she
///  simulates the `swap` call:
///
/// ```dart
/// final tx = await atomicSwapClient.buildInvokeMethodTx(name: swapMethodName,
/// args: args);
///  ```
/// But your app can't `signAndSend` this right away, because Bob needs to sign
///  it first. You can check this:
///
/// ```dart
///  final whoElseNeedsToSign = tx.needsNonInvokerSigningBy()
///  ```
///
/// You can verify that `whoElseNeedsToSign` is an array of length `1`,
///  containing only Bob's public key.
///
/// If you have Bob's secret key, you can sign it right away with:
///
/// ```dart
/// final bobsKeyPair = KeyPair.fromSecretSeed("S...");
/// await tx.signAuthEntries(signerKeyPair: bobsKeyPair);
/// ```
/// But if you don't have Bob's private key, and e.g. need to send it to another server for signing,
/// you can provide a callback function for signing the auth entry:
///
/// ```dart
/// final bobPublicKeyKeyPair = KeyPair.fromAccountId(bobId);
/// await tx.signAuthEntries(
///   signerKeyPair: bobPublicKeyKeyPair,
///   authorizeEntryDelegate: (entry, network) async {
///
///     // You can send it to some other server for signing by encoding it as a base64xdr string
///     final base64Entry = entry.toBase64EncodedXdrString();
///
///     // send for signing ...
///     // and on the other server you can decode it:
///     final entryToSign =
///     SorobanAuthorizationEntry.fromBase64EncodedXdr(base64Entry);
///
///     // sign it
///     entryToSign.sign(bobKeyPair, network);
///
///     // encode as a base64xdr string and send it back
///     final signedBase64Entry = entryToSign.toBase64EncodedXdrString();
///
///     // here you can now decode it and return it
///     return SorobanAuthorizationEntry.fromBase64EncodedXdr(signedBase64Entry);
/// });
///  ```
/// To see an even more complicated example, where Alice swaps with Bob but the
/// transaction is invoked by yet another party, check out in the SorobanClientTest.testAtomicSwap()
class AssembledTransaction {
  /// The TransactionBuilder as constructed in `AssembledTransaction.build`
  /// Feel free set `simulate: false` in the method options to modify
  /// this object before calling `tx.simulate()` manually. Example:
  ///
  /// ```dart
  /// final methodOptions = MethodOptions(simulate: false);
  ///
  /// final tx = await client.buildInvokeMethodTx(name: "myWriteMethod",
  /// args: args, methodOptions: methodOptions);
  ///
  /// tx.raw!.addMemo(MemoText("Hello!"));
  /// await tx.simulate();
  ///  ```
  TransactionBuilder? raw;

  /// The Transaction as it was built with `raw.build()` right before
  /// simulation. Once this is set, modifying `raw` will have no effect unless
  /// you call `tx.simulate()` again.
  Transaction? tx;

  /// The response of the transaction simulation. This is set after the first call
  /// to `simulate`.
  SimulateTransactionResponse? simulationResponse;

  /// The result extracted from the simulation response if it was successfull.
  /// To receive this you can call `tx.getSimulationData()`.
  SimulateHostFunctionResult? _simulationResult = null;

  /// The Soroban server to use for all RPC calls. Taken from
  /// `ClientOptions.server` if provided, otherwise constructed from the
  /// `rpcUrl` in the constructor arguments.
  late SorobanServer server;

  /// The signed transaction. Null if not yet signed.
  Transaction? signed;

  /// The options for constructing and managing this AssembledTransaction.
  AssembledTransactionOptions options;

  /// The operation this transaction was built with. Reused when the
  /// transaction is rebuilt after an automatic footprint restore, so that
  /// transactions built via `buildWithOp` keep their original operation.
  /// Set by `buildWithOp` for every publicly constructible transaction;
  /// null only for internally built footprint-restore transactions, which
  /// simulate with `restore: false` and never enter the restore rebuild.
  InvokeHostFunctionOperation? _originalOp;

  /// Private constructor. Use `AssembledTransaction.build` or `AssembledTransaction.buildWithOp`
  /// to construct an AssembledTransaction.
  AssembledTransaction._(this.options) {
    final providedServer = this.options.clientOptions.server;
    if (providedServer != null) {
      this.server = providedServer;
    } else {
      this.server = SorobanServer(this.options.clientOptions.rpcUrl);
      this.server.enableLogging = this.options.enableSorobanServerLogging;
    }
  }

  /// Construct a new AssembledTransaction. This is the main way to create a new
  /// AssembledTransaction; the constructor is private.
  ///
  /// It will fetch the account from the network to get the current sequence number, and it will
  /// simulate the transaction to get the expected fee. If you don't want to simulate the transaction,
  /// you can set `simulate` to `false` in the method options.
  ///
  /// If you need to create a soroban operation with a host function other than `InvokeContractHostFunction`, you
  /// can use `AssembledTransaction.buildWithOp` instead.
  static Future<AssembledTransaction> build(
      {required AssembledTransactionOptions options}) async {
    final invokeContractHostFunction = InvokeContractHostFunction(
        options.clientOptions.contractId, options.method,
        arguments: options.arguments);
    final builder = InvokeHostFuncOpBuilder(invokeContractHostFunction);
    return await buildWithOp(operation: builder.build(), options: options);
  }

  /// Construct a new AssembledTransaction, specifying a soroban operation with a host function other
  /// than `InvokeContractHostFunction` (the default used by `AssembledTransaction.build`).
  /// E.g. `CreateContractWithConstructorHostFunction`
  static Future<AssembledTransaction> buildWithOp(
      {required InvokeHostFunctionOperation operation,
      required AssembledTransactionOptions options}) async {
    final tx = AssembledTransaction._(options);
    tx._originalOp = operation;
    final account = await tx._getSourceAccount();
    tx.raw = TransactionBuilder(account);
    final timeBounds = TimeBounds(
        0,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
            tx.options.methodOptions.timeoutInSeconds);
    final preconditions = TransactionPreconditions();
    preconditions.timeBounds = timeBounds;
    tx.raw!.addPreconditions(preconditions);
    tx.raw!.addOperation(operation);
    tx.raw!.setMaxOperationFee(tx.options.methodOptions.fee);
    if (options.methodOptions.simulate) {
      await tx.simulate();
    }
    return tx;
  }

  /// Simulates the transaction and assembles the final transaction from the simulation result.
  /// To access the simulation response data call `getSimulationData()` after simulation.
  Future<void> simulate({bool? restore = null}) async {
    if (tx == null) {
      if (raw == null) {
        throw Exception(
            'Transaction has not yet been assembled; call "AssembledTransaction.build" first.');
      }
      tx = raw!.build();
    }

    var shouldRestore = restore ?? options.methodOptions.restore;
    _simulationResult = null;
    simulationResponse = await server.simulateTransaction(
        SimulateTransactionRequest(tx!,
            useUpgradedAuth: options.methodOptions.useUpgradedAuth));
    if (shouldRestore && simulationResponse!.restorePreamble != null) {
      if (options.clientOptions.sourceAccountKeyPair.privateKey == null) {
        throw new Exception(
            'Source account keypair has no private key, but needed for automatic restore.');
      }
      final result = await restoreFootprint(
          restorePreamble: simulationResponse!.restorePreamble!);
      if (result.status == GetTransactionResponse.STATUS_SUCCESS) {
        // Rebuild the transaction with the bumped account sequence number,
        // reusing the operation this transaction was originally built with.
        final sourceAccount = await _getSourceAccount();
        raw = TransactionBuilder(sourceAccount);
        final timeBounds = TimeBounds(
            0,
            DateTime.now().millisecondsSinceEpoch ~/ 1000 +
                options.methodOptions.timeoutInSeconds);
        final preconditions = TransactionPreconditions();
        preconditions.timeBounds = timeBounds;
        raw!.addPreconditions(preconditions);
        raw!.addOperation(_originalOp!);
        raw!.setMaxOperationFee(options.methodOptions.fee);
        tx = null; // force the rebuilt `raw` to be built on re-simulation
        await simulate();
        return;
      }
      throw new Exception(
          "Automatic restore failed! You set 'restore: true' but the attempted "
          "restore did not work. Status: ${result.status} , transaction result xdr: ${result.resultXdr}");
    }
    if (simulationResponse!.transactionData != null) {
      // success
      tx!.sorobanTransactionData = simulationResponse!.transactionData!;
      tx!.addResourceFee(simulationResponse!.minResourceFee ?? 0);
      tx!.setSorobanAuth(simulationResponse!.sorobanAuth);
    }
  }

  /// Sign the transaction with the private key of the `sourceAccountKeyPair` provided with the options previously.
  /// If you did not previously provide one that has a private key, you need to include one now.
  /// After signing, this method will send the transaction to the network and wait max. options.timeoutInSeconds to complete.
  /// If not completed after options->timeoutInSeconds it will throw an exception. Otherwise, returns the `GetTransactionResponse`.
  /// With [force] you can force signing and sending even if it is a read call. Default false.
  /// Returns the get transaction response received after sending and waiting for the transaction to complete.
  Future<GetTransactionResponse> signAndSend(
      {KeyPair? sourceAccountKeyPair = null, bool force = false}) async {
    if (signed == null) {
      sign(sourceAccountKeyPair: sourceAccountKeyPair, force: force);
    }
    return await send();
  }

  /// Sends the transaction and waits until completed. Returns `GetTransactionResponse`.
  Future<GetTransactionResponse> send() async {
    if (signed == null) {
      throw Exception(
          "The transaction has not yet been signed. Run `sign` first, or use `signAndSend` instead.");
    }
    final sendTxResponse = await server.sendTransaction(signed!);
    if (sendTxResponse.isErrorResponse) {
      if (sendTxResponse.error != null) {
        throw Exception(
            "Could not send transaction. Rpc error code: ${sendTxResponse.error!.code}, message:  ${sendTxResponse.error!.message}");
      }
      throw Exception("Could not send transaction.");
    }
    // A PENDING submission was accepted into the network's transaction queue
    // and a DUPLICATE one names a transaction already in that queue, so both
    // poll to the transaction's true outcome. Any other status reports a
    // submission the network did not queue, so polling its hash cannot find
    // a result.
    final status = sendTxResponse.status;
    if (status != SendTransactionResponse.STATUS_PENDING &&
        status != SendTransactionResponse.STATUS_DUPLICATE) {
      var message = "Send transaction failed with status: $status";
      if (sendTxResponse.errorResultXdr != null) {
        message +=
            ", error transaction result xdr: ${sendTxResponse.errorResultXdr}";
      }
      final diagnosticEvents = sendTxResponse.diagnosticEvents;
      if (diagnosticEvents != null && diagnosticEvents.isNotEmpty) {
        message +=
            ", diagnostic events: ${diagnosticEvents.map((event) => event.toBase64EncodedXdrString()).join(", ")}";
      }
      throw Exception(message);
    }
    final hash = sendTxResponse.hash;
    if (hash == null) {
      throw Exception(
          "Send transaction response contains no transaction hash.");
    }
    return await _pollStatus(hash);
  }

  Future<GetTransactionResponse> _pollStatus(String transactionId) async {
    GetTransactionResponse? statusResponse;
    var status = GetTransactionResponse.STATUS_NOT_FOUND;
    const waitTime = NetworkConstants.TRANSACTION_POLL_WAIT_SECONDS;
    var waited = 0;

    while (status == GetTransactionResponse.STATUS_NOT_FOUND) {
      if (waited > options.methodOptions.timeoutInSeconds) {
        throw new Exception(
            "Interrupted after waiting ${options.methodOptions.timeoutInSeconds} seconds (options.methodOptions.timeoutInSeconds) for the transaction $transactionId to complete.");
      }
      await Future.delayed(const Duration(seconds: waitTime), () {});
      waited += waitTime;
      statusResponse = await server.getTransaction(transactionId);
      if (statusResponse.isErrorResponse) {
        continue;
      }
      status = statusResponse.status!;
    }
    return statusResponse!;
  }

  /// Sign the transaction with the private key of the `sourceAccountKeyPair` provided with the options previously.
  /// If you did not previously provide one that has a private key, you need to include one now.
  /// With [force] you can force signing and sending even if it is a read call. Default false.
  void sign({KeyPair? sourceAccountKeyPair = null, bool force = false}) {
    if (tx == null) {
      throw Exception("Transaction has not yet been simulated");
    }

    if (!force && isReadCall()) {
      throw Exception(
          "This is a read call. It requires no signature or sending. " +
              "Use `force: true` to sign and send anyway.");
    }
    final signerKp =
        sourceAccountKeyPair ?? options.clientOptions.sourceAccountKeyPair;
    if (signerKp.privateKey == null) {
      throw Exception(
          'Source account keypair has no private key, but needed for signing.');
    }

    // Use the send precheck: a WITH_DELEGATES entry whose top-level is void but
    // every delegate is signed does not block submission (delegates-only
    // pattern). needsNonInvokerSigningBy() reports the void top-level for
    // informational purposes, but _neededSignersForSend() omits it when all
    // delegates are present and signed.
    final neededAccountSigners = _neededSignersForSend();
    if (neededAccountSigners.isNotEmpty) {
      throw new Exception(
          "Transaction requires signatures from multiple signers. " +
              "See `needsNonInvokerSigningBy` for details.");
    }

    // clone tx
    final envelopeXdr = tx!.toEnvelopeXdrBase64();
    final clonedTxAbstract =
        AbstractTransaction.fromEnvelopeXdrString(envelopeXdr);
    if (clonedTxAbstract is Transaction) {
      clonedTxAbstract.sign(signerKp, options.clientOptions.network);
      signed = clonedTxAbstract;
    } else {
      throw new Exception("Could not clone transaction for signing.");
    }
  }

  /// Get a list of addresses, other than the invoker of the simulation, that
  /// still need to provide signatures for auth entries in this transaction.
  ///
  /// Soroban allows multiple parties to authorize different parts of a
  /// transaction. Someone needs to sign the final transaction envelope; this
  /// person/account is called the _invoker_, or _source_. Other accounts or
  /// delegates might need to sign individual auth entries.
  ///
  /// This function returns strkeys for every node whose signature is currently
  /// void, assuming that the same invoker/source account will sign the final
  /// transaction envelope. For ADDRESS and ADDRESS_V2 entries the top-level
  /// credential address is reported when its signature is void. For
  /// ADDRESS_WITH_DELEGATES entries BOTH the top-level address (when its
  /// signature is void) AND every unsigned delegate node at any depth are
  /// reported — a top-level signature alongside delegates is a legal pattern.
  ///
  /// Note: a WITH_DELEGATES entry where the top-level signature is void but
  /// every delegate node is signed is the legitimate delegates-only pattern;
  /// this function still lists the void top-level, but the send precheck
  /// treats such an entry as fully satisfied. Use [sign] (not this function)
  /// to determine whether the transaction is ready to submit.
  ///
  /// With [includeAlreadySigned] set to true, addresses that already have
  /// signatures are included in the returned list.
  List<String> needsNonInvokerSigningBy({bool includeAlreadySigned = false}) {
    if (tx == null) {
      throw Exception("Transaction has not yet been simulated");
    }
    final ops = tx!.operations;
    if (ops.isEmpty) {
      throw Exception("Unexpected Transaction type; no operations found.");
    }
    final needed = List<String>.empty(growable: true);
    final invokeHostFuncOp = ops.first;
    if (invokeHostFuncOp is InvokeHostFunctionOperation) {
      final authEntries = invokeHostFuncOp.auth;
      for (SorobanAuthorizationEntry entry in authEntries) {
        final arm = entry.credentials.arm;

        if (arm ==
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
          // Source-account entries: no explicit signing needed.
          continue;
        }

        if (arm != XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS &&
            arm != XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2 &&
            arm != XdrSorobanCredentialsType
                .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
          throw Exception(
              'Unknown credential arm in auth entry: $arm');
        }

        final inner = entry.credentials.innerAddressCredentials;
        if (inner == null) {
          // Should not happen for any of the three address arms.
          throw Exception(
              'Address credentials missing for arm $arm');
        }

        // Report the top-level address when its signature is void (or when
        // includeAlreadySigned is true).
        final topSigIsVoid =
            inner.signature.discriminant == XdrSCValType.SCV_VOID;
        if (includeAlreadySigned || topSigIsVoid) {
          final signer =
              inner.address.accountId ?? inner.address.contractId;
          if (signer != null) {
            needed.add(signer);
          }
        }

        // For WITH_DELEGATES, also walk every delegate node at any depth.
        if (arm == XdrSorobanCredentialsType
            .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
          final withDelegates =
              entry.credentials.addressWithDelegatesCredentials!;
          _collectUnsignedDelegates(
              withDelegates.delegates, needed, includeAlreadySigned, 0);
        }
      }
    }
    return needed;
  }

  /// Depth-first walk of a delegate list, appending unsigned addresses to [out].
  ///
  /// [depth] guards against pathological nesting; uses the same limit as
  /// [SorobanAuthorizationEntry._maxDelegateTraversalDepth].
  static void _collectUnsignedDelegates(
      List<SorobanDelegateSignature> delegates,
      List<String> out,
      bool includeAlreadySigned,
      int depth) {
    if (depth > 128) {
      throw Exception(
          'Delegate tree traversal depth limit (128) exceeded');
    }
    for (final node in delegates) {
      final isSigned =
          node.signature.discriminant != XdrSCValType.SCV_VOID;
      if (includeAlreadySigned || !isSigned) {
        final nodeAddr = _xdrAddressToStrKey(node.address);
        if (nodeAddr.isNotEmpty) {
          out.add(nodeAddr);
        }
      }
      _collectUnsignedDelegates(
          node.nestedDelegates, out, includeAlreadySigned, depth + 1);
    }
  }

  /// Returns the strkey for an [XdrSCAddress].
  ///
  /// Returns an empty string for address types that are not valid Soroban
  /// auth targets (muxed, claimable balance, liquidity pool).
  static String _xdrAddressToStrKey(XdrSCAddress addr) {
    if (addr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT &&
        addr.accountId != null) {
      return KeyPair.fromXdrPublicKey(addr.accountId!.accountID).accountId;
    } else if (addr.discriminant == XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT &&
        addr.contractId != null) {
      return StrKey.encodeContractId(addr.contractId!.hash);
    }
    return '';
  }

  /// Returns true when the auth entries in [tx] require no additional signing
  /// before the transaction can be submitted.
  ///
  /// The logic differs from [needsNonInvokerSigningBy]:
  /// - A WITH_DELEGATES entry whose top-level signature is void but whose
  ///   every delegate node (at any depth) carries a signature is treated as
  ///   satisfied — that is the legitimate delegates-only pattern.
  /// - Any other entry with a void signature on its top-level address (ADDRESS
  ///   or ADDRESS_V2) is unsatisfied.
  ///
  /// Returns a list of unsatisfied non-invoker G-address signers. An empty
  /// list means the transaction is ready to submit.
  List<String> _neededSignersForSend() {
    if (tx == null) {
      return [];
    }
    final ops = tx!.operations;
    if (ops.isEmpty) {
      return [];
    }
    final needed = <String>[];
    final invokeHostFuncOp = ops.first;
    if (invokeHostFuncOp is! InvokeHostFunctionOperation) {
      return needed;
    }
    for (final entry in invokeHostFuncOp.auth) {
      final arm = entry.credentials.arm;
      if (arm ==
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
        continue;
      }

      final inner = entry.credentials.innerAddressCredentials;
      if (inner == null) continue;
      if (arm == XdrSorobanCredentialsType
          .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
        // Delegates-only pattern: top-level may be void; entry is satisfied
        // when every delegate node at any depth carries a non-void signature.
        final withDelegates =
            entry.credentials.addressWithDelegatesCredentials!;
        if (_allDelegatesSigned(withDelegates.delegates, 0)) {
          // Fully satisfied; skip.
          continue;
        }
        // Some delegate nodes are unsigned — collect them (and top-level if
        // also void) for reporting.
        final topSigIsVoid =
            inner.signature.discriminant == XdrSCValType.SCV_VOID;
        if (topSigIsVoid) {
          final signer =
              inner.address.accountId ?? inner.address.contractId;
          if (signer != null && !signer.startsWith('C')) {
            needed.add(signer);
          }
        }
        _collectUnsignedDelegates(withDelegates.delegates, needed, false, 0);
      } else {
        // ADDRESS or ADDRESS_V2: top-level must be signed.
        final topSigIsVoid =
            inner.signature.discriminant == XdrSCValType.SCV_VOID;
        if (topSigIsVoid) {
          final signer =
              inner.address.accountId ?? inner.address.contractId;
          if (signer != null && !signer.startsWith('C')) {
            needed.add(signer);
          }
        }
      }
    }
    return needed;
  }

  /// Returns true when every delegate node in [delegates] (depth-first) has a
  /// non-void signature.
  static bool _allDelegatesSigned(
      List<SorobanDelegateSignature> delegates, int depth) {
    if (depth > 128) {
      throw Exception('Delegate tree traversal depth limit (128) exceeded');
    }
    for (final node in delegates) {
      if (node.signature.discriminant == XdrSCValType.SCV_VOID) {
        return false;
      }
      if (!_allDelegatesSigned(node.nestedDelegates, depth + 1)) {
        return false;
      }
    }
    return true;
  }

  /// Whether this transaction is a read call. This is determined by the
  /// simulation result and the transaction data. If the transaction is a read
  /// call, it will not need to be signed and sent to the network. If this
  /// returns `false`, then you need to call `signAndSend` on this transaction.
  ///
  /// A transaction is considered a read call when:
  /// - No authorization entries are required (authsCount == 0)
  /// - No ledger entries will be modified (writeLength == 0)
  ///
  /// Read calls can be executed via simulation without blockchain submission,
  /// while write calls require signing and on-chain execution.
  bool isReadCall() {
    final res = getSimulationData();
    final authsCount = res.auth?.length ?? 0;
    final writeLength =
        res.transactionData.resources.footprint.readWrite.length;
    return authsCount == 0 && writeLength == 0;
  }

  /// Signs authorization entries for multi-party transactions.
  ///
  /// Soroban allows multiple parties to authorize different parts of a
  /// transaction. When a transaction requires authorization from accounts or
  /// contracts other than the source/invoker, those parties must sign their
  /// authorization entries before the transaction is submitted.
  ///
  /// All three address credential arms are handled:
  /// - ADDRESS and ADDRESS_V2: matches on the top-level credential address.
  /// - ADDRESS_WITH_DELEGATES: matches on the top-level address AND on every
  ///   delegate node at any depth (depth-first). When the signer address
  ///   matches a delegate node, the expiration is stamped on the top-level
  ///   credentials and the signature is routed into that delegate node via
  ///   [SorobanAuthorizationEntry.sign] with `forAddress`. A delegate signer
  ///   never silently matches no entry — if [signerKeyPair.accountId] appears
  ///   in [needsNonInvokerSigningBy] but no entry matches during the signing
  ///   walk, an exception is thrown.
  ///
  /// SOURCE_ACCOUNT entries are skipped. Unknown/unrecognized arms fail fast.
  ///
  /// The credential arm is preserved after signing; V2 entries stay V2.
  ///
  /// Use [needsNonInvokerSigningBy] to determine which addresses need to sign.
  ///
  /// Parameters:
  /// - [signerKeyPair] KeyPair of the signer (must include private key unless
  ///   [authorizeEntryDelegate] is provided)
  /// - [authorizeEntryDelegate] Optional custom signing function (e.g. for
  ///   remote or HSM signing). When provided the validation checks are skipped
  ///   and the returned entry replaces the original.
  /// - [validUntilLedgerSeq] Signature expiration ledger. Defaults to the
  ///   latest ledger sequence plus [NetworkConstants.DEFAULT_LEDGER_EXPIRATION_OFFSET].
  ///
  /// Throws:
  /// - Exception If no entries need signing, keypair lacks a private key, or
  ///   the signer address is not found in any entry.
  ///
  /// Example - Local signing:
  /// ```dart
  /// final tx = await client.buildInvokeMethodTx(name: 'swap', args: swapArgs);
  ///
  /// // Check who needs to sign
  /// final needsSigning = tx.needsNonInvokerSigningBy();
  /// print('Needs signing by: $needsSigning');
  ///
  /// // Bob signs his auth entry
  /// await tx.signAuthEntries(signerKeyPair: bobKeyPair);
  ///
  /// // Alice (invoker) signs and submits
  /// await tx.signAndSend();
  /// ```
  ///
  /// Example - Remote signing:
  /// ```dart
  /// await tx.signAuthEntries(
  ///   signerKeyPair: KeyPair.fromAccountId(bobAccountId),
  ///   authorizeEntryDelegate: (entry, network) async {
  ///     final base64Entry = entry.toBase64EncodedXdrString();
  ///     final signedBase64 = await sendToSigningServer(base64Entry);
  ///     return SorobanAuthorizationEntry.fromBase64EncodedXdr(signedBase64);
  ///   },
  /// );
  /// ```
  ///
  /// See also:
  /// - [needsNonInvokerSigningBy] to check which addresses need to sign
  /// - [SorobanAuthorizationEntry] for authorization entry details
  Future<void> signAuthEntries(
      {required KeyPair signerKeyPair,
      Future<SorobanAuthorizationEntry> Function(
              SorobanAuthorizationEntry entry, Network network)?
          authorizeEntryDelegate,
      int? validUntilLedgerSeq}) async {
    final signerAddress = signerKeyPair.accountId;
    if (authorizeEntryDelegate == null) {
      final neededSigning = needsNonInvokerSigningBy();
      if (neededSigning.isEmpty) {
        throw Exception(
            "No unsigned non-invoker auth entries; maybe you already signed?");
      }
      if (!neededSigning.contains(signerAddress)) {
        throw Exception("No auth entries for public key $signerAddress");
      }
      if (signerKeyPair.privateKey == null) {
        throw Exception(
            "You must provide a signer keypair containing the private key.");
      }
    }
    if (tx == null) {
      throw Exception("Transaction has not yet been simulated");
    }
    var expirationLedger = validUntilLedgerSeq;
    if (expirationLedger == null) {
      final getLatestLedgerResponse = await server.getLatestLedger();
      if (getLatestLedgerResponse.sequence == null) {
        throw Exception("Could not fetch latest ledger sequence from server");
      }
      expirationLedger = getLatestLedgerResponse.sequence! +
          NetworkConstants.DEFAULT_LEDGER_EXPIRATION_OFFSET;
    }

    final ops = tx!.operations;
    if (ops.isEmpty) {
      throw Exception("Unexpected Transaction type; no operations found.");
    }
    final invokeHostFuncOp = ops.first;
    if (invokeHostFuncOp is! InvokeHostFunctionOperation) {
      throw Exception(
          "Unexpected Transaction type; no invoke host function operations found.");
    }

    var authEntries = invokeHostFuncOp.auth;
    for (var i = 0; i < authEntries.length; i++) {
      final entry = authEntries[i];
      final arm = entry.credentials.arm;

      if (arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT) {
        // Source-account entries need no explicit signing.
        continue;
      }

      if (arm != XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS &&
          arm != XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2 &&
          arm != XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
        throw Exception(
            'Unknown credential arm in auth entry: $arm');
      }

      final inner = entry.credentials.innerAddressCredentials;
      if (inner == null) {
        // Should not happen for any of the three address arms.
        throw Exception('Address credentials missing for arm $arm');
      }

      final topLevelStrKey =
          inner.address.accountId ?? inner.address.contractId ?? '';

      // Determine whether the signer matches the top-level address or any
      // delegate node (for WITH_DELEGATES entries). Only entries the signer is
      // responsible for are touched; entries for other parties are left intact,
      // so a signature already applied by another signer is never disturbed.
      final bool matchesTopLevel = topLevelStrKey == signerAddress;

      bool matchesDelegate = false;
      if (arm == XdrSorobanCredentialsType
          .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES) {
        final withDelegates =
            entry.credentials.addressWithDelegatesCredentials!;
        matchesDelegate =
            _delegateListContains(withDelegates.delegates, signerAddress, 0);
      }

      if (!matchesTopLevel && !matchesDelegate) {
        // This entry does not involve the signer; skip.
        continue;
      }

      // Stamp expiration before signing — the preimage is built from the
      // current expiration value.
      inner.signatureExpirationLedger = expirationLedger;

      if (authorizeEntryDelegate != null) {
        // Hand the matching entry off to the external signer.
        final authorized =
            await authorizeEntryDelegate(entry, options.clientOptions.network);
        authEntries[i] = authorized;
        continue;
      }

      if (matchesTopLevel && !matchesDelegate) {
        // Sign the top-level credentials.
        entry.sign(signerKeyPair, options.clientOptions.network);
      } else {
        // Signer matches a delegate node (and possibly also the top-level
        // address). forAddress routing signs the top-level credential when the
        // address matches and every matching delegate node in one pass, so a
        // preceding plain sign() would write a duplicate top-level signature the
        // host rejects.
        entry.sign(signerKeyPair, options.clientOptions.network,
            forAddress: signerAddress);
      }
      authEntries[i] = entry;
    }
    tx!.setSorobanAuth(authEntries);
  }

  /// Returns true when [targetStrKey] appears as the address of any delegate
  /// node in [delegates] or their nested delegates (depth-first).
  static bool _delegateListContains(
      List<SorobanDelegateSignature> delegates,
      String targetStrKey,
      int depth) {
    if (depth > 128) {
      throw Exception('Delegate tree traversal depth limit (128) exceeded');
    }
    for (final node in delegates) {
      final nodeStr = _xdrAddressToStrKey(node.address);
      if (nodeStr == targetStrKey) return true;
      if (_delegateListContains(node.nestedDelegates, targetStrKey, depth + 1)) {
        return true;
      }
    }
    return false;
  }

  /// Restores the footprint (resource ledger entries that can be read or written)
  /// of an expired transaction.
  ///
  /// The method will:
  /// 1. Build a new transaction aimed at restoring the necessary resources.
  /// 2. Sign this new transaction if a sourceAccountKeyPair with private key is provided.
  /// 3. Send the signed transaction to the network.
  /// 4. Await and return the response from the network.
  ///
  /// Preconditions:
  /// - A `sourceAccountKeyPair` with private key must be provided during the Client initialization.
  ///
  Future<GetTransactionResponse> restoreFootprint(
      {required RestorePreamble restorePreamble}) async {
    final restoreTx = await _buildFootprintRestoreTransaction(options,
        restorePreamble.transactionData, restorePreamble.minResourceFee);
    return await restoreTx.signAndSend();
  }

  /// Simulation data collected from the transaction simulation.
  SimulateHostFunctionResult getSimulationData() {
    if (_simulationResult != null) {
      return _simulationResult!;
    }
    if (simulationResponse == null) {
      throw Exception("Transaction has not yet been simulated");
    }
    if (simulationResponse!.error != null ||
        simulationResponse!.resultError != null ||
        simulationResponse!.transactionData == null) {
      throw new Exception(
          "Transaction simulation failed: ${simulationResponse?.resultError}");
    }

    if (simulationResponse!.restorePreamble != null) {
      throw Exception(
          "You need to restore some contract state before you can invoke this method.\n" +
              "You can set `restore` to true in the options in order to " +
              "automatically restore the contract state when needed.");
    }

    var resultValue = XdrSCVal.forVoid();
    if (simulationResponse!.results != null) {
      if (simulationResponse!.results!.isNotEmpty) {
        final xdr = simulationResponse!.results![0].xdr;
        resultValue = XdrSCVal.fromBase64EncodedXdrString(xdr);
      }
    }
    _simulationResult = SimulateHostFunctionResult(
        simulationResponse!.sorobanAuth,
        simulationResponse!.transactionData!,
        resultValue);
    return _simulationResult!;
  }

  static Future<AssembledTransaction> _buildFootprintRestoreTransaction(
      AssembledTransactionOptions options,
      XdrSorobanTransactionData transactionData,
      int fee) async {
    final restoreTx = AssembledTransaction._(options);
    final restoreOp = (RestoreFootprintOperationBuilder()).build();
    final sourceAccount = await restoreTx._getSourceAccount();
    final timeBounds = TimeBounds(
        0,
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
            restoreTx.options.methodOptions.timeoutInSeconds);
    final preconditions = TransactionPreconditions();
    preconditions.timeBounds = timeBounds;
    restoreTx.raw = TransactionBuilder(sourceAccount)
        .addOperation(restoreOp)
        .setMaxOperationFee(fee)
        .addPreconditions(preconditions);
    restoreTx.tx = restoreTx.raw!.build();
    restoreTx.tx!.sorobanTransactionData = transactionData;
    await restoreTx.simulate(restore: false);
    return restoreTx;
  }

  Future<Account> _getSourceAccount() async {
    var account = await server
        .getAccount(options.clientOptions.sourceAccountKeyPair.accountId);
    if (account == null) {
      throw Exception(
          "Account: ${options.clientOptions.sourceAccountKeyPair.accountId} not found.");
    }
    return account;
  }
}

/// Configuration options for SorobanClient initialization.
///
/// ClientOptions defines all parameters needed to create and configure a SorobanClient
/// instance for interacting with deployed smart contracts. These options specify the
/// contract to interact with, the network configuration, and authentication details.
///
/// Key considerations:
///
/// Private Key Requirements:
/// - For read-only operations: Only public key is required in sourceAccountKeyPair
/// - For write operations: Private key (secret seed) must be provided for signing
/// - For automatic restore: Private key must be provided if restore flag is enabled
///
/// Network Configuration:
/// - Use Network.TESTNET for Soroban testnet
/// - Use Network.PUBLIC for Soroban mainnet (when available)
/// - Custom networks can be configured via Network constructor
///
/// RPC Endpoint:
/// - Must point to a valid Soroban RPC server
/// - Testnet default: 'https://soroban-testnet.stellar.org:443'
/// - For local development: 'http://localhost:8000/soroban/rpc'
///
/// Fields:
/// - [sourceAccountKeyPair] Keypair for transaction source account
/// - [contractId] Contract address to interact with (C... format)
/// - [network] Stellar network where contract is deployed
/// - [rpcUrl] Soroban RPC server endpoint URL
/// - [enableServerLogging] Enable debug logging for RPC calls
///
/// Example - Read-only client (public key only):
/// ```dart
/// final options = ClientOptions(
///   sourceAccountKeyPair: KeyPair.fromAccountId('GABC...'),
///   contractId: 'CABC...',
///   network: Network.TESTNET,
///   rpcUrl: 'https://soroban-testnet.stellar.org:443',
/// );
///
/// final client = await SorobanClient.forClientOptions(options: options);
/// final balance = await client.invokeMethod(name: 'balance', args: [accountArg]);
/// ```
///
/// Example - Write operations client (private key required):
/// ```dart
/// final options = ClientOptions(
///   sourceAccountKeyPair: KeyPair.fromSecretSeed('S...'),
///   contractId: 'CABC...',
///   network: Network.TESTNET,
///   rpcUrl: 'https://soroban-testnet.stellar.org:443',
///   enableServerLogging: true,  // For debugging
/// );
///
/// final client = await SorobanClient.forClientOptions(options: options);
/// await client.invokeMethod(
///   name: 'transfer',
///   args: [fromArg, toArg, amountArg],
/// );
/// ```
///
/// Example - Using custom network:
/// ```dart
/// final customNetwork = Network('Custom Network', 'custom passphrase');
///
/// final options = ClientOptions(
///   sourceAccountKeyPair: myKeyPair,
///   contractId: contractAddress,
///   network: customNetwork,
///   rpcUrl: 'https://my-custom-rpc.example.com',
/// );
/// ```
///
/// See also:
/// - [SorobanClient.forClientOptions] for creating clients
/// - [MethodOptions] for per-method configuration
/// - [Network] for network configuration details
class ClientOptions {
  /// Keypair of the Stellar account that will send transactions.
  ///
  /// Requirements:
  /// - Read operations: Public key only (KeyPair.fromAccountId)
  /// - Write operations: Must include private key (KeyPair.fromSecretSeed)
  /// - Restore operations: Must include private key if restore flag is enabled
  KeyPair sourceAccountKeyPair;

  /// The address of the contract the client will interact with.
  ///
  /// Must be a valid Stellar contract address starting with 'C'.
  /// Can be obtained from contract deployment or looked up on-chain.
  String contractId;

  /// The Stellar network where the contract is deployed.
  ///
  /// Common values:
  /// - Network.TESTNET - Soroban testnet
  /// - Network.PUBLIC - Soroban mainnet
  /// - Custom Network instance for private networks
  Network network;

  /// The URL of the Soroban RPC server to use for contract interaction.
  ///
  /// Must be a complete URL including protocol and port.
  /// Examples:
  /// - Testnet: 'https://soroban-testnet.stellar.org:443'
  /// - Local: 'http://localhost:8000/soroban/rpc'
  String rpcUrl;

  /// Enable detailed logging of RPC server requests and responses.
  ///
  /// When true, prints all RPC calls and responses to console.
  /// Useful for debugging contract interactions. Default: false.
  bool enableServerLogging = false;

  /// Optional: A preconfigured [SorobanServer] to use for all RPC calls
  /// instead of constructing one from [rpcUrl].
  ///
  /// Provide this to reuse a single RPC connection across operations
  /// (e.g. to guarantee that all calls hit the same backend node of a
  /// load-balanced RPC endpoint) or to supply a server with a custom
  /// HTTP client configuration.
  ///
  /// When provided, the server is used as configured; [enableServerLogging]
  /// does not modify its logging setting.
  SorobanServer? server;

  /// Creates ClientOptions for SorobanClient initialization.
  ///
  /// Parameters:
  /// - [sourceAccountKeyPair]: Account keypair for sending transactions
  /// - [contractId]: Contract address to interact with
  /// - [network]: Network where contract is deployed
  /// - [rpcUrl]: Soroban RPC server URL
  /// - [enableServerLogging]: Enable debug logging (default: false)
  /// - [server]: Preconfigured SorobanServer to use instead of constructing one from [rpcUrl]
  ClientOptions(
      {required this.sourceAccountKeyPair,
      required this.contractId,
      required this.network,
      required this.rpcUrl,
      this.enableServerLogging = false,
      this.server});
}

/// Options for fine-tuning contract method invocation behavior.
///
/// These options control transaction parameters and simulation behavior
/// when invoking contract methods through SorobanClient.
class MethodOptions {
  /// The fee to pay for the transaction in stroops (1 stroop = 0.0000001 XLM).
  /// Default: 100 stroops (NetworkConstants.DEFAULT_SOROBAN_BASE_FEE).
  int fee;

  /// Transaction timeout in seconds from current time.
  /// Default: 300 seconds (5 minutes, NetworkConstants.DEFAULT_TIMEOUT_SECONDS).
  int timeoutInSeconds;

  /// Whether to automatically simulate the transaction when constructing the AssembledTransaction.
  /// Default: true.
  bool simulate = true;

  /// If true, will automatically attempt to restore the transaction if there
  /// are archived entries that need renewal.
  /// Default: false.
  bool restore = false;

  /// When true, the simulation request includes `"useUpgradedAuth": true`,
  /// asking the RPC server to return ADDRESS_V2 credential entries (protocol 27+).
  ///
  /// The key is omitted from the request entirely when false (never sent as
  /// `"useUpgradedAuth": false`). RPCs that do not support this flag silently
  /// ignore it and return legacy ADDRESS entries; support is detected by
  /// inspecting the credential arm of the returned entries, not by an error code.
  ///
  /// Emitting V2 entries on a network below protocol 27 invalidates the
  /// transaction; set this only when targeting protocol 27+. Default: false.
  bool useUpgradedAuth = false;

  /// Creates MethodOptions for contract method invocation.
  ///
  /// Parameters:
  /// - [fee] Transaction fee in stroops (default: 100)
  /// - [timeoutInSeconds] Transaction timeout (default: 300 seconds)
  /// - [simulate] Auto-simulate transaction (default: true)
  /// - [restore] Auto-restore archived entries (default: false)
  /// - [useUpgradedAuth] Request ADDRESS_V2 credential entries (default: false)
  ///
  /// Example:
  /// ```dart
  /// final options = MethodOptions(
  ///   fee: 200,
  ///   timeoutInSeconds: 60,
  ///   restore: true,
  /// );
  /// ```
  MethodOptions(
      {this.fee = NetworkConstants.DEFAULT_SOROBAN_BASE_FEE,
      this.timeoutInSeconds = NetworkConstants.DEFAULT_TIMEOUT_SECONDS,
      this.simulate = true,
      this.restore = false,
      this.useUpgradedAuth = false});
}

/// Configuration options for constructing an AssembledTransaction.
///
/// AssembledTransactionOptions combines all parameters needed to build, simulate, and
/// execute a Soroban smart contract transaction. These options control the contract method
/// to invoke, arguments to pass, fee settings, timeout, and client configuration.
///
/// This class is typically used internally by SorobanClient but can be used directly
/// for advanced use cases requiring fine-grained transaction control.
///
/// Options Structure:
///
/// Client Configuration ([clientOptions]):
/// - Source account keypair for signing
/// - Contract ID to interact with
/// - Network configuration
/// - RPC server URL
///
/// Method Configuration ([methodOptions]):
/// - Transaction fee limits
/// - Timeout duration
/// - Simulation control
/// - Automatic restore settings
///
/// Invocation Details:
/// - Contract method name
/// - Method arguments (XDR-encoded)
/// - Debug logging control
///
/// Fields:
/// - [clientOptions]: Client configuration for network and authentication
/// - [methodOptions]: Transaction execution parameters
/// - [method]: Name of contract method to invoke
/// - [arguments]: XDR-encoded arguments for the method (optional)
/// - [enableSorobanServerLogging]: Enable debug logging for RPC calls
///
/// Example - Basic invocation options:
/// ```dart
/// final clientOpts = ClientOptions(
///   sourceAccountKeyPair: myKeyPair,
///   contractId: 'CABC...',
///   network: Network.TESTNET,
///   rpcUrl: rpcUrl,
/// );
///
/// final methodOpts = MethodOptions(
///   fee: 200,
///   timeoutInSeconds: 60,
/// );
///
/// final options = AssembledTransactionOptions(
///   clientOptions: clientOpts,
///   methodOptions: methodOpts,
///   method: 'transfer',
///   arguments: [fromArg, toArg, amountArg],
/// );
///
/// final tx = await AssembledTransaction.build(options: options);
/// ```
///
/// Example - Advanced configuration with restore:
/// ```dart
/// final methodOpts = MethodOptions(
///   fee: 500,
///   timeoutInSeconds: 120,
///   restore: true,  // Auto-restore expired entries
///   simulate: true,
/// );
///
/// final options = AssembledTransactionOptions(
///   clientOptions: clientOptions,
///   methodOptions: methodOpts,
///   method: 'complexOperation',
///   arguments: complexArgs,
///   enableSorobanServerLogging: true,  // Debug RPC calls
/// );
///
/// final tx = await AssembledTransaction.build(options: options);
/// ```
///
/// Example - Deployment transaction options:
/// ```dart
/// // For deploying contracts (used internally by SorobanClient.deploy)
/// final deployOpts = AssembledTransactionOptions(
///   clientOptions: clientOptions,
///   methodOptions: MethodOptions(),
///   method: '__constructor',
///   arguments: constructorArgs,
/// );
///
/// final operation = InvokeHostFuncOpBuilder(createContractHostFunction).build();
/// final tx = await AssembledTransaction.buildWithOp(
///   operation: operation,
///   options: deployOpts,
/// );
/// ```
///
/// Example - Manual simulation control:
/// ```dart
/// final methodOpts = MethodOptions(
///   simulate: false,  // Skip initial simulation
/// );
///
/// final options = AssembledTransactionOptions(
///   clientOptions: clientOptions,
///   methodOptions: methodOpts,
///   method: 'myMethod',
///   arguments: args,
/// );
///
/// final tx = await AssembledTransaction.build(options: options);
///
/// // Modify transaction before simulation
/// tx.raw!.addMemo(MemoText('Custom memo'));
///
/// // Now simulate
/// await tx.simulate();
/// ```
///
/// See also:
/// - [AssembledTransaction.build] for building transactions with these options
/// - [ClientOptions] for client configuration details
/// - [MethodOptions] for method execution parameters
/// - [SorobanClient.invokeMethod] for simplified invocation
class AssembledTransactionOptions {
  ClientOptions clientOptions;
  MethodOptions methodOptions;

  /// Name of the contract method to call
  String method;

  /// Arguments to pass to the method call
  List<XdrSCVal>? arguments;

  /// Enable soroban server logging (helpful for debugging). Default: false.
  bool enableSorobanServerLogging = false;

  /// Creates configuration options for assembling a Soroban contract method call transaction.
  ///
  /// Parameters:
  /// - [clientOptions] Client configuration including source account and network details
  /// - [methodOptions] Method execution parameters including fee and timeout settings
  /// - [method] Name of the contract method to invoke
  /// - [arguments] Arguments to pass to the contract method call
  /// - [enableSorobanServerLogging] Enable server-side logging for debugging
  ///
  /// Example:
  /// ```dart
  /// final options = AssembledTransactionOptions(
  ///   clientOptions: myClientOptions,
  ///   methodOptions: MethodOptions(),
  ///   method: 'transfer',
  ///   arguments: [fromArg, toArg, amountArg],
  /// );
  /// ```
  AssembledTransactionOptions(
      {required this.clientOptions,
      required this.methodOptions,
      required this.method,
      this.arguments = null,
      this.enableSorobanServerLogging = false});
}

/// Request configuration for installing Soroban contract WASM code.
///
/// Uploads and stores contract code on the ledger, returning a hash that can be
/// used to deploy contract instances via DeployRequest.
class InstallRequest {
  /// The contract code wasm bytes to install.
  Uint8List wasmBytes;

  /// Keypair of the Stellar account that will send this transaction.
  /// The keypair must contain the private key for signing.
  KeyPair sourceAccountKeyPair;

  /// The Stellar network this contract is to be installed.
  Network network;

  /// The URL of the RPC instance that will be used to install the contract.
  String rpcUrl;

  /// Optional: Enable soroban server logging (helpful for debugging). Default: false.
  bool enableSorobanServerLogging = false;

  /// Optional: A preconfigured [SorobanServer] to use for all RPC calls
  /// instead of constructing one from [rpcUrl]. When provided, the server
  /// is used as configured; [enableSorobanServerLogging] does not modify
  /// its logging setting.
  SorobanServer? server;

  /// Creates an InstallRequest for uploading contract WASM code to Soroban.
  ///
  /// This request configuration is used with SorobanClient.install to upload and store
  /// contract WebAssembly bytecode on the ledger, returning a WASM hash for deployment.
  ///
  /// Parameters:
  /// - [wasmBytes] Contract WebAssembly bytecode to install
  /// - [sourceAccountKeyPair] Account keypair with private key for signing
  /// - [network] Stellar network for installation (TESTNET, PUBLIC, etc.)
  /// - [rpcUrl] Soroban RPC server URL
  /// - [enableSorobanServerLogging] Enable debug logging (default: false)
  /// - [server] Preconfigured SorobanServer to use instead of constructing one from [rpcUrl]
  ///
  /// Example:
  /// ```dart
  /// final request = InstallRequest(
  ///   wasmBytes: contractBytes,
  ///   sourceAccountKeyPair: myKeyPair,
  ///   network: Network.TESTNET,
  ///   rpcUrl: rpcUrl,
  /// );
  /// final wasmHash = await SorobanClient.install(installRequest: request);
  /// ```
  InstallRequest(
      {required this.wasmBytes,
      required this.sourceAccountKeyPair,
      required this.network,
      required this.rpcUrl,
      this.enableSorobanServerLogging = false,
      this.server});
}

/// Request configuration for deploying a Soroban smart contract.
///
/// Deploys a contract instance from previously installed WASM code.
/// The contract is assigned a unique ID derived from the deployer address and salt.
class DeployRequest {
  /// Keypair of the Stellar account that will send this transaction.
  /// The keypair must contain the private key for signing.
  KeyPair sourceAccountKeyPair;

  /// The Stellar network this contract is to be deployed.
  Network network;

  /// The URL of the RPC instance that will be used to deploy the contract.
  String rpcUrl;

  /// The hash of the Wasm blob (in hex string format), which must already be installed on-chain.
  String wasmHash;

  /// Optional: Constructor/Initialization args for the contract's `__constructor` method.
  /// Only required if the contract has a constructor function.
  List<XdrSCVal>? constructorArgs;

  /// Optional: Salt used to generate the contract's ID. If not provided, a random 32-byte
  /// salt will be generated automatically during contract deployment.
  XdrUint256? salt;

  /// Optional: Method options used to fine tune the transaction.
  /// If not provided, default MethodOptions will be used.
  late MethodOptions methodOptions;

  /// Optional: Enable soroban server logging (helpful for debugging). Default: false.
  bool enableSorobanServerLogging = false;

  /// Optional: A preconfigured [SorobanServer] to use for all RPC calls
  /// instead of constructing one from [rpcUrl]. When provided, the server
  /// is used as configured; [enableSorobanServerLogging] does not modify
  /// its logging setting.
  SorobanServer? server;

  /// Creates a DeployRequest for deploying a contract instance from installed WASM.
  ///
  /// This request configuration is used with SorobanClient.deploy to create a new
  /// contract instance from previously installed WASM code. The contract ID is derived
  /// from the deployer address and salt.
  ///
  /// Parameters:
  /// - [sourceAccountKeyPair] Account keypair with private key for signing
  /// - [network] Stellar network for deployment (TESTNET, PUBLIC, etc.)
  /// - [rpcUrl] Soroban RPC server URL
  /// - [wasmHash] Hex-encoded hash of installed WASM code (from SorobanClient.install)
  /// - [constructorArgs] Optional constructor arguments if contract has __constructor
  /// - [salt] Optional salt for deterministic contract ID (random if not provided)
  /// - [methodOptions] Optional transaction tuning options (fee, timeout, etc.)
  /// - [enableSorobanServerLogging] Enable debug logging (default: false)
  /// - [server] Preconfigured SorobanServer to use instead of constructing one from [rpcUrl]
  ///
  /// Example:
  /// ```dart
  /// final request = DeployRequest(
  ///   sourceAccountKeyPair: myKeyPair,
  ///   network: Network.TESTNET,
  ///   rpcUrl: rpcUrl,
  ///   wasmHash: installedHash,
  ///   constructorArgs: [XdrSCVal.forU32(42)],
  /// );
  /// final client = await SorobanClient.deploy(deployRequest: request);
  /// ```
  DeployRequest(
      {required this.sourceAccountKeyPair,
      required this.network,
      required this.rpcUrl,
      required this.wasmHash,
      this.constructorArgs,
      this.salt,
      MethodOptions? methodOptions,
      this.enableSorobanServerLogging = false,
      this.server}) {
    this.methodOptions = methodOptions ?? MethodOptions();
  }
}

/// Result data from simulating a Soroban contract invocation.
///
/// SimulateHostFunctionResult contains the essential data extracted from a successful
/// transaction simulation. This includes authorization requirements, resource footprint,
/// and the simulated return value.
///
/// This class is used internally by AssembledTransaction to store simulation results
/// and is returned by getSimulationData(). It provides:
///
/// Authorization Information:
/// - List of authorization entries that need signing before submission
/// - Identifies which parties must authorize the transaction
/// - Contains signature placeholders to be filled during signing
///
/// Resource Requirements:
/// - Transaction data including resource footprint (read/write ledger entries)
/// - Resource limits and fees required for execution
/// - Used to prepare the final transaction for submission
///
/// Return Value:
/// - The value that would be returned by the contract function
/// - Useful for read-only calls where no submission is needed
/// - Can be used to validate results before committing
///
/// Fields:
/// - [auth]: Authorization entries requiring signatures (null if none needed)
/// - [transactionData]: Soroban transaction data with resource footprint
/// - [returnedValue]: The simulated return value from the contract
///
/// Example - Accessing simulation results:
/// ```dart
/// final tx = await client.buildInvokeMethodTx(name: 'balance', args: [accountArg]);
///
/// // For read calls, get result immediately from simulation
/// if (tx.isReadCall()) {
///   final simulationData = tx.getSimulationData();
///   final balance = simulationData.returnedValue;
///   print('Balance: ${balance.i128?.lo.int64}');
/// }
/// ```
///
/// Example - Checking authorization requirements:
/// ```dart
/// final tx = await client.buildInvokeMethodTx(name: 'transfer', args: transferArgs);
/// final simulationData = tx.getSimulationData();
///
/// if (simulationData.auth != null && simulationData.auth!.isNotEmpty) {
///   print('Transaction requires ${simulationData.auth!.length} authorization(s)');
///
///   for (var entry in simulationData.auth!) {
///     final address = entry.credentials.innerAddressCredentials?.address;
///     print('Needs signature from: ${address?.accountId ?? address?.contractId}');
///   }
/// }
/// ```
///
/// Example - Inspecting resource footprint:
/// ```dart
/// final simulationData = tx.getSimulationData();
/// final footprint = simulationData.transactionData.resources.footprint;
///
/// print('Read entries: ${footprint.readOnly.length}');
/// print('Write entries: ${footprint.readWrite.length}');
/// print('Instructions: ${simulationData.transactionData.resources.instructions.uint32}');
/// ```
///
/// See also:
/// - [AssembledTransaction.getSimulationData] for retrieving this data
/// - [SimulateTransactionResponse] for raw RPC simulation response
/// - [SorobanAuthorizationEntry] for authorization entry details
class SimulateHostFunctionResult {
  /// List of authorization entries that need signatures.
  ///
  /// Each entry represents a party that must authorize part of the transaction.
  /// Will be null or empty for transactions requiring only source account authorization.
  List<SorobanAuthorizationEntry>? auth;

  /// Transaction data containing resource footprint and limits.
  ///
  /// Includes:
  /// - Resource footprint (ledger entries to be read/written)
  /// - Resource limits (CPU instructions, memory, etc.)
  /// - Used to construct the final transaction for submission
  XdrSorobanTransactionData transactionData;

  /// The value returned by simulating the contract invocation.
  ///
  /// This is the result that would be returned if the transaction were executed.
  /// For read-only calls, this is the primary data of interest.
  XdrSCVal returnedValue;

  /// Creates a SimulateHostFunctionResult.
  ///
  /// Parameters:
  /// - [auth]: Authorization entries (null if none required)
  /// - [transactionData]: Soroban transaction data with resource info
  /// - [returnedValue]: Simulated return value from contract
  SimulateHostFunctionResult(
      this.auth, this.transactionData, this.returnedValue);
}
