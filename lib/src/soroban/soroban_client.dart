// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/account.dart';
import 'package:stellar_flutter_sdk/src/constants/network_constants.dart';
import 'package:stellar_flutter_sdk/src/invoke_host_function_operation.dart';
import 'package:stellar_flutter_sdk/src/restore_footprint_operation.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_auth.dart';
import 'package:stellar_flutter_sdk/src/soroban/soroban_server.dart';
import 'package:stellar_flutter_sdk/src/soroban/contract_spec.dart';
import 'package:stellar_flutter_sdk/src/transaction.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_contract.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_transaction.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

import '../key_pair.dart';
import '../network.dart';

/// Represents a Soroban contract and helps you to interact with the contract, such as by invoking a contract method.
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

  /// Private constructor. Use `SorobanClient.forClientOptions` or `SorobanClient.deploy` to construct a SorobanClient.
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
    final server = SorobanServer(options.rpcUrl);
    final info = await server.loadContractInfoForContractId(options.contractId);
    if (info != null) {
      return SorobanClient._(info.specEntries, options);
    } else {
      throw new Exception(
          "Could not load contract inf for the contract: ${options.contractId}");
    }
  }

  /// After deploying the contract it creates and returns a new SorobanClient for the deployed contract.
  /// The contract must be installed before calling this method. You can use `SorobanClient.install`
  /// to install the contract.
  static Future<SorobanClient> deploy(
      {required DeployRequest deployRequest}) async {
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
        return Util.bytesToHex(returnedValue.bytes!.dataValue);
      }
    }

    final response = await tx.signAndSend(force: force);
    final wasmHash = response.getWasmId();
    if (wasmHash == null) {
      throw new Exception("Could not get wasm hash for installed contract");
    }
    return wasmHash;
  }

  /// Invokes a contract method given by [name] and arguments given by [args] if any.
  /// It can be used for read only calls and for read/write calls.
  /// If it is read only call it will return the result from the simulation.
  /// If you want to force signing and submission even if it is a read only call set [force] to true.
  Future<XdrSCVal> invokeMethod(
      {required String name,
      List<XdrSCVal>? args,
      bool force = false,
      MethodOptions? methodOptions = null}) async {
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
  /// [functionName] - The name of the contract function
  /// [args] - Map of argument names to values
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
  /// [val] - The native Dart value to convert
  /// [ty] - The target type specification
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
/// final amountA = XdrSCVal.forI128Parts(0, 1000);
/// final minBForA = XdrSCVal.forI128Parts(0, 4500);

/// final amountB = XdrSCVal.forI128Parts(0, 5000);
/// final minAForB = XdrSCVal.forI128Parts(0, 950);
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

  /// The Soroban server to use for all RPC calls. This is constructed from the
  /// `rpcUrl` in the constructor arguments.
  late SorobanServer server;

  /// The signed transaction. Null if not yet signed.
  Transaction? signed;

  /// The options for constructing and managing this AssembledTransaction.
  AssembledTransactionOptions options;

  /// Private constructor. Use `AssembledTransaction.build` or `AssembledTransaction.buildWithOp`
  /// to construct an AssembledTransaction.
  AssembledTransaction._(this.options) {
    this.server = SorobanServer(this.options.clientOptions.rpcUrl);
    this.server.enableLogging = this.options.enableSorobanServerLogging;
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
    final account = await tx._getSourceAccount();
    tx.raw = TransactionBuilder(account);
    final timeBounds = TimeBounds(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - NetworkConstants.TRANSACTION_TIME_BUFFER_SECONDS,
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
    simulationResponse =
        await server.simulateTransaction(SimulateTransactionRequest(tx!));
    if (shouldRestore && simulationResponse!.restorePreamble != null) {
      if (options.clientOptions.sourceAccountKeyPair.privateKey == null) {
        throw new Exception(
            'Source account keypair has no private key, but needed for automatic restore.');
      }
      final result = await restoreFootprint(
          restorePreamble: simulationResponse!.restorePreamble!);
      if (result.status == GetTransactionResponse.STATUS_SUCCESS) {
        final sourceAccount = await _getSourceAccount();
        raw = TransactionBuilder(sourceAccount);
        final timeBounds = TimeBounds(
            DateTime.now().millisecondsSinceEpoch ~/ 1000 - NetworkConstants.TRANSACTION_TIME_BUFFER_SECONDS,
            DateTime.now().millisecondsSinceEpoch ~/ 1000 +
                options.methodOptions.timeoutInSeconds);
        final preconditions = TransactionPreconditions();
        preconditions.timeBounds = timeBounds;
        raw!.addPreconditions(preconditions);
        final invokeContractHostFunction = InvokeContractHostFunction(
            options.clientOptions.contractId, options.method,
            arguments: options.arguments);
        final builder = InvokeHostFuncOpBuilder(invokeContractHostFunction);
        raw!.addOperation(builder.build());
        await simulate();
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
    if (sendTxResponse.status == SendTransactionResponse.STATUS_ERROR) {
      throw new Exception(
          "Send transaction failed with error transaction result xdr: ${sendTxResponse.errorResultXdr}");
    } else if (sendTxResponse.status ==
        SendTransactionResponse.STATUS_DUPLICATE) {
      throw new Exception("Send transaction failed with status: DUPLICATE");
    }
    return await _pollStatus(sendTxResponse.hash!);
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

    final allNeededSigners = needsNonInvokerSigningBy();
    final neededAccountSigners = List<String>.empty(growable: true);
    for (String signer in allNeededSigners) {
      if (!signer.startsWith("C")) {
        neededAccountSigners.add(signer);
      }
    }
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

  /// Get a list of accounts, other than the invoker of the simulation, that
  /// need to sign auth entries in this transaction.
  ///
  /// Soroban allows multiple people to sign a transaction. Someone needs to
  /// sign the final transaction envelope; this person/account is called the
  /// _invoker_, or _source_. Other accounts might need to sign individual auth
  /// entries in the transaction, if they're not also the invoker.
  ///
  /// This function returns a list of accounts that need to sign auth entries,
  /// assuming that the same invoker/source account will sign the final
  /// transaction envelope as signed the initial simulation.
  ///
  /// With [includeAlreadySigned] you can define if the returned list should
  /// include the needed signers that already signed their auth entries.
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
        final addressCredentials = entry.credentials.addressCredentials;
        if (addressCredentials != null) {
          if (includeAlreadySigned ||
              addressCredentials.signature.discriminant ==
                  XdrSCValType.SCV_VOID) {
            final signer = addressCredentials.address.accountId ??
                addressCredentials.address.contractId;
            if (signer != null) {
              needed.add(signer);
            }
          }
        }
      }
    } else {
      throw Exception(
          "Unexpected Transaction type; no invoke host function operations found.");
    }
    return needed;
  }

  /// Whether this transaction is a read call. This is determined by the
  /// simulation result and the transaction data. If the transaction is a read
  /// call, it will not need to be signed and sent to the network. If this
  /// returns `false`, then you need to call `signAndSend` on this transaction.
  bool isReadCall() {
    final res = getSimulationData();
    final authsCount = res.auth?.length ?? 0;
    final writeLength =
        res.transactionData.resources.footprint.readWrite.length;
    return authsCount == 0 && writeLength == 0;
  }

  /// Signs and updates the auth entries related to the public key of the [signerKeyPair]
  /// provided for the auth entry. By default, this function will sign all auth
  /// entries that are connected to the signerKeyPair public key by using SorobanAuthorizationEntry.sign().
  /// The signerKeyPair must contain the private key for signing for this default case.
  /// If you don't have the signer's private key, provide the signers KeyPair containing
  /// only the public key and provide a callback function for signing by using the [authorizeEntryDelegate] parameter
  /// that is used to sign the auth entry. This is especially useful if you need to sign on another server or
  /// if you have a pro use-case and need to use your own function rather than the default `SorobanAuthorizationEntry.sign()`
  /// function. Your function needs to take following arguments: (SorobanAuthorizationEntry entry, Network network)
  /// and it must return the signed SorobanAuthorizationEntry.
  /// With [validUntilLedgerSeq] you can decide when to set each auth entry to expire.
  /// Could be any number of blocks in the future. Default: current sequence + 100 blocks (about 8.3 minutes from now)
  Future<void> signAuthEntries(
      {required KeyPair signerKeyPair,
      Future<SorobanAuthorizationEntry> Function(
              SorobanAuthorizationEntry entry, Network network)?
          authorizeEntryDelegate,
      int? validUntilLedgerSeq}) async {
    final signerAddress = signerKeyPair.accountId;
    if (authorizeEntryDelegate == null) {
      final neededSigning = await needsNonInvokerSigningBy();
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
      expirationLedger = getLatestLedgerResponse.sequence! + NetworkConstants.DEFAULT_LEDGER_EXPIRATION_OFFSET;
    }

    final ops = tx!.operations;
    if (ops.isEmpty) {
      throw Exception("Unexpected Transaction type; no operations found.");
    }
    final invokeHostFuncOp = ops.first;
    if (invokeHostFuncOp is InvokeHostFunctionOperation) {
      var authEntries = invokeHostFuncOp.auth;
      for (var i = 0; i < authEntries.length; i++) {
        final entry = authEntries[i];
        final addressCredentials = entry.credentials.addressCredentials;
        if (addressCredentials == null ||
            addressCredentials.address.accountId == null ||
            addressCredentials.address.accountId != signerAddress) {
          continue;
        }
        entry.credentials.addressCredentials!.signatureExpirationLedger =
            expirationLedger;
        SorobanAuthorizationEntry? authorized;
        if (authorizeEntryDelegate != null) {
          authorized = await authorizeEntryDelegate(
              entry, options.clientOptions.network);
        } else {
          entry.sign(signerKeyPair, options.clientOptions.network);
          authorized = entry;
        }
        authEntries[i] = authorized;
      }
      tx!.setSorobanAuth(authEntries);
    } else {
      throw new Exception(
          "Unexpected Transaction type; no invoke host function operations found.");
    }
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
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - NetworkConstants.TRANSACTION_TIME_BUFFER_SECONDS,
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
    restoreTx.simulate(restore: false);
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

class ClientOptions {
  /// Keypair of the Stellar account that will send this transaction. If restore is set to true,
  /// and restore is needed, the keypair must contain the private key (secret seed) otherwise the public key is sufficient.
  KeyPair sourceAccountKeyPair;

  /// The address of the contract the client will interact with.
  String contractId;

  /// The Stellar network this contract is deployed
  Network network;

  /// The URL of the RPC instance that will be used to interact with this contract.
  String rpcUrl;

  /// Enable soroban server logging (helpful for debugging). Default: false.
  bool enableServerLogging = false;

  ClientOptions(
      {required this.sourceAccountKeyPair,
      required this.contractId,
      required this.network,
      required this.rpcUrl,
      this.enableServerLogging = false});
}

class MethodOptions {
  /// The fee to pay for the transaction in Stoops. Default 100.
  int fee;

  /// The timebounds which should be set for transactions generated by the contract client. Default 300 seconds.
  int timeoutInSeconds;

  /// Whether to automatically simulate the transaction when constructing the AssembledTransaction. Default true.
  bool simulate = true;

  /// If true, will automatically attempt to restore the transaction if there
  /// are archived entries that need renewal. Default false.
  bool restore = false;

  MethodOptions(
      {this.fee = NetworkConstants.DEFAULT_SOROBAN_BASE_FEE,
      this.timeoutInSeconds = NetworkConstants.DEFAULT_TIMEOUT_SECONDS,
      this.simulate = true,
      this.restore = false});
}

class AssembledTransactionOptions {
  ClientOptions clientOptions;
  MethodOptions methodOptions;

  /// Name of the contract method to call
  String method;

  /// Arguments to pass to the method call
  List<XdrSCVal>? arguments;

  /// Enable soroban server logging (helpful for debugging). Default: false.
  bool enableSorobanServerLogging = false;

  AssembledTransactionOptions(
      {required this.clientOptions,
      required this.methodOptions,
      required this.method,
      this.arguments = null,
      this.enableSorobanServerLogging = false});
}

class InstallRequest {
  /// The contract code wasm bytes to install.
  Uint8List wasmBytes;

  /// Keypair of the Stellar account that will send this transaction.
  /// The keypair must contain the private key for signing.
  KeyPair sourceAccountKeyPair;

  /// The Stellar network this contract is to be installed
  Network network;

  /// The URL of the RPC instance that will be used to install the contract.
  String rpcUrl;

  /// Enable soroban server logging (helpful for debugging). Default: false.
  bool enableSorobanServerLogging = false;

  InstallRequest(
      {required this.wasmBytes,
      required this.sourceAccountKeyPair,
      required this.network,
      required this.rpcUrl,
      this.enableSorobanServerLogging = false});
}

class DeployRequest {
  /// Keypair of the Stellar account that will send this transaction.
  /// The keypair must contain the private key for signing.
  KeyPair sourceAccountKeyPair;

  /// The Stellar network this contract is to be deployed
  Network network;

  /// The URL of the RPC instance that will be used to deploy the contract.
  String rpcUrl;

  /// The hash of the Wasm blob (in hex string format), which must already be installed on-chain.
  String wasmHash;

  /// Constructor/Initialization Args for the contract's `__constructor` method.
  List<XdrSCVal>? constructorArgs;

  /// Salt used to generate the contract's ID. Default: random (new XdrUint256(TweetNaCl.randombytes(32)).
  XdrUint256? salt;

  /// Method options used to fine tune the transaction.
  late MethodOptions methodOptions;

  /// Enable soroban server logging (helpful for debugging). Default: false.
  bool enableSorobanServerLogging = false;

  DeployRequest(
      {required this.sourceAccountKeyPair,
      required this.network,
      required this.rpcUrl,
      required this.wasmHash,
      this.constructorArgs,
      this.salt,
      MethodOptions? methodOptions = null,
      this.enableSorobanServerLogging = false}) {
    this.methodOptions = methodOptions ?? MethodOptions();
  }
}

class SimulateHostFunctionResult {
  List<SorobanAuthorizationEntry>? auth;
  XdrSorobanTransactionData transactionData;
  XdrSCVal returnedValue;

  SimulateHostFunctionResult(
      this.auth, this.transactionData, this.returnedValue);
}
