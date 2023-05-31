import 'dart:typed_data';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://rpc-futurenet.stellar.org:443");

  StellarSDK sdk = StellarSDK.FUTURENET;

  KeyPair adminKeypair = KeyPair.random();
  String adminId = adminKeypair.accountId;
  KeyPair aliceKeypair = KeyPair.random();
  String aliceId = aliceKeypair.accountId;
  KeyPair bobKeypair = KeyPair.random();
  String bobId = bobKeypair.accountId;

  String tokenContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/token.wasm";
  String swapContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/atomic_swap.wasm";
  String? tokenAContractWasmId;
  String? tokenAContractId;
  String? tokenBContractWasmId;
  String? tokenBContractId;
  String? swapContractWasmId;
  String? swapContractId;

  setUp(() async {
    sorobanServer.enableLogging = true;
    sorobanServer.acknowledgeExperimental = true;

    try {
      await sdk.accounts.account(adminId);
    } catch (e) {
      await FuturenetFriendBot.fundTestAccount(adminId);
      print("admin " + adminId + " : " + adminKeypair.secretSeed);
    }

    try {
      await sdk.accounts.account(aliceId);
    } catch (e) {
      await FuturenetFriendBot.fundTestAccount(aliceId);
      print("alice " + aliceId + " : " + aliceKeypair.secretSeed);
    }

    try {
      await sdk.accounts.account(bobId);
    } catch (e) {
      await FuturenetFriendBot.fundTestAccount(bobId);
      print("bob " + bobId + " : " + bobKeypair.secretSeed);
    }
  });

  // poll until success or error
  Future<GetTransactionResponse> pollStatus(String transactionId) async {
    var status = GetTransactionResponse.STATUS_NOT_FOUND;
    GetTransactionResponse? transactionResponse;
    while (status == GetTransactionResponse.STATUS_NOT_FOUND) {
      await Future.delayed(const Duration(seconds: 3), () {});
      transactionResponse = await sorobanServer.getTransaction(transactionId);
      assert(transactionResponse.error == null);
      status = transactionResponse.status!;
      if (status == GetTransactionResponse.STATUS_FAILED) {
        assert(transactionResponse.resultXdr != null);
        assert(false);
      } else if (status == GetTransactionResponse.STATUS_SUCCESS) {
        assert(transactionResponse.resultXdr != null);
      }
    }
    return transactionResponse!;
  }

  Future<String> installContract(String contractCodePath) async {
    await Future.delayed(Duration(seconds: 5));
    // load account
    AccountResponse submitter = await sdk.accounts.account(adminId);

    // load contract wasm file
    Uint8List contractCode = await Util.readFile(contractCodePath);

    // upload contract
    InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
        .addFunction(UploadContractWasmHostFunction(contractCode))
        .build();
    Transaction transaction =
        new TransactionBuilder(submitter).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(transaction);
    assert(!simulateResponse.isErrorResponse);
    assert(simulateResponse.transactionData != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, Network.FUTURENET);

    // check transaction xdr encoding and decoding back and forth
    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
    assert(transactionEnvelopeXdr ==
        AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
            .toEnvelopeXdrBase64());

    // send transaction to soroban rpc server
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(!sendResponse.isErrorResponse);
    assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

    GetTransactionResponse rpcTransactionResponse =
        await pollStatus(sendResponse.hash!);
    String? wasmId = rpcTransactionResponse.getWasmId();
    assert(wasmId != null);
    return wasmId!;
  }

  Future<String> createContract(String wasmId) async {
    await Future.delayed(Duration(seconds: 5));
    // reload account for current sequence nr
    AccountResponse submitter = await sdk.accounts.account(adminId);

    // build the operation for creating the contract
    InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
        .addFunction(CreateContractHostFunction(wasmId))
        .build();

    // build the transaction for creating the contract
    Transaction transaction =
        new TransactionBuilder(submitter).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(transaction);
    assert(!simulateResponse.isErrorResponse);
    assert(simulateResponse.resultError == null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, Network.FUTURENET);

    // send transaction to soroban rpc server
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(!sendResponse.isErrorResponse);

    assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

    GetTransactionResponse statusResponse =
        await pollStatus(sendResponse.hash!);
    String? contractId = statusResponse.getContractId();
    assert(contractId != null);
    return contractId!;
  }

  Future<void> createToken(
      String contractId, String name, String symbol) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
    // reload account for sequence number
    await Future.delayed(Duration(seconds: 5));
    AccountResponse invoker = await sdk.accounts.account(adminId);

    Address adminAddress = Address.forAccountId(adminId);
    String functionName = "initialize";
    List<int> list = utf8.encode(name);
    String nameHex = hex.encode(list);
    XdrSCVal tokenName = XdrSCVal.forBytes(Util.hexToBytes(nameHex));
    list = utf8.encode(name);
    String symbolHex = hex.encode(list);
    XdrSCVal tokenSymbol = XdrSCVal.forBytes(Util.hexToBytes(symbolHex));

    List<XdrSCVal> args = [
      adminAddress.toXdrSCVal(),
      XdrSCVal.forU32(8),
      tokenName,
      tokenSymbol
    ];

    AuthorizedInvocation rootInvocation =
        AuthorizedInvocation(contractId, functionName, args: args);

    ContractAuth contractAuth = ContractAuth(rootInvocation);

    InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
        contractId, functionName, arguments: args, auth: [contractAuth]);
    InvokeHostFunctionOperation operation =
    (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

    Transaction transaction =
        new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.footprint != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, Network.FUTURENET);

    // check transaction xdr encoding and decoding back and forth
    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
    assert(transactionEnvelopeXdr ==
        AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
            .toEnvelopeXdrBase64());

    // send the transaction
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(sendResponse.error == null);
    assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

    GetTransactionResponse statusResponse =
        await pollStatus(sendResponse.hash!);
    String status = statusResponse.status!;
    assert(status == GetTransactionResponse.STATUS_SUCCESS);
  }

  Future<void> mint(String contractId, String toAccountId, int amount) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
    // reload account for sequence number
    await Future.delayed(Duration(seconds: 5));
    AccountResponse invoker = await sdk.accounts.account(adminId);

    Address toAddress = Address.forAccountId(toAccountId);
    XdrSCVal amountVal = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, amount));
    String functionName = "mint";

    List<XdrSCVal> args = [
      toAddress.toXdrSCVal(),
      amountVal
    ];

    AuthorizedInvocation rootInvocation =
        AuthorizedInvocation(contractId, functionName, args: args);

    ContractAuth contractAuth = ContractAuth(rootInvocation);

    InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
        contractId, functionName, arguments: args, auth: [contractAuth]);
    InvokeHostFunctionOperation operation =
    (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

    Transaction transaction =
        new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, Network.FUTURENET);

    // check transaction xdr encoding and decoding back and forth
    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
    assert(transactionEnvelopeXdr ==
        AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
            .toEnvelopeXdrBase64());

    // send the transaction
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(sendResponse.error == null);
    assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

    GetTransactionResponse statusResponse =
        await pollStatus(sendResponse.hash!);
    String status = statusResponse.status!;
    assert(status == GetTransactionResponse.STATUS_SUCCESS);
  }

  Future<int> balance(String contractId, String accountId) async {
    await Future.delayed(Duration(seconds: 5));
    // reload account for sequence number
    AccountResponse invoker = await sdk.accounts.account(adminId);

    Address address = Address.forAccountId(accountId);
    String functionName = "balance";

    List<XdrSCVal> args = [address.toXdrSCVal()];

    InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
        contractId, functionName, arguments: args);
    InvokeHostFunctionOperation operation =
    (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

    Transaction transaction =
        new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, Network.FUTURENET);

    // check transaction xdr encoding and decoding back and forth
    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
    assert(transactionEnvelopeXdr ==
        AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
            .toEnvelopeXdrBase64());

    // send the transaction
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(sendResponse.error == null);

    GetTransactionResponse statusResponse =
        await pollStatus(sendResponse.hash!);
    String status = statusResponse.status!;
    assert(status == GetTransactionResponse.STATUS_SUCCESS);

    assert(statusResponse.getResultValue()?.i128 != null);
    XdrInt128Parts parts = statusResponse.getResultValue()!.i128!;
    return parts.lo.uint64;
  }

  group('all tests', () {
    test('test install contracts', () async {
      tokenAContractWasmId = await installContract(tokenContractPath);
      tokenBContractWasmId = await installContract(tokenContractPath);
      swapContractWasmId = await installContract(swapContractPath);
    });

    test('test create contracts', () async {
      tokenAContractId = await createContract(tokenAContractWasmId!);
      print("Token A Contract ID: " + tokenAContractId!);
      tokenBContractId = await createContract(tokenBContractWasmId!);
      print("Token B Contract ID: " + tokenBContractId!);
      swapContractId = await createContract(swapContractWasmId!);
      print("SWAP Contract ID: " + swapContractId!);
    });

    test('test create tokens', () async {
      await createToken(tokenAContractId!, "TokenA", "TokenA");
      await createToken(tokenBContractId!, "TokenB", "TokenB");
    });

    test('test mint tokens', () async {
      await mint(tokenAContractId!, aliceId, 10000000000000);
      await mint(tokenBContractId!, bobId, 10000000000000);
      int aliceTokenABalance = await balance(tokenAContractId!, aliceId);
      assert(aliceTokenABalance == 10000000000000);
      int bobTokenBBalance = await balance(tokenBContractId!, bobId);
      assert(bobTokenBBalance == 10000000000000);
    });

    test('test atomic swap', () async {
      // See https://soroban.stellar.org/docs/how-to-guides/atomic-swap
      // See https://soroban.stellar.org/docs/learn/authorization

      await Future.delayed(const Duration(seconds: 10), () {});

      KeyPair swapSubmitterKp = adminKeypair;
      String swapSubmitterAccountId = swapSubmitterKp.accountId;

      KeyPair aliceKp = aliceKeypair;
      String aliceAccountId = aliceKp.accountId;

      KeyPair bobKp = bobKeypair;
      String bobAccountId = bobKp.accountId;

      String atomicSwapContractId = swapContractId!;
      String tokenACId = tokenAContractId!;
      String tokenBCId = tokenBContractId!;

      Address addressAlice = Address.forAccountId(aliceAccountId);
      Address addressBob = Address.forAccountId(bobAccountId);
      Address addressSwapContract = Address.forContractId(atomicSwapContractId);

      XdrSCVal tokenABytes = XdrSCVal.forBytes(Util.hexToBytes(tokenACId));
      XdrSCVal tokenBBytes = XdrSCVal.forBytes(Util.hexToBytes(tokenBCId));

      XdrSCVal amountA = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 1000));
      XdrSCVal minBForA = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 4500));

      XdrSCVal amountB = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 5000));
      XdrSCVal minAForB = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 950));

      String swapFuntionName = "swap";
      String incrAllowFunctionName = "increase_allowance";

      List<XdrSCVal> aliceSubAuthArgs = [
        addressAlice.toXdrSCVal(),
        addressSwapContract.toXdrSCVal(),
        amountA
      ];
      AuthorizedInvocation aliceSubAuthInvocation = AuthorizedInvocation(
          tokenACId, incrAllowFunctionName,
          args: aliceSubAuthArgs);
      List<XdrSCVal> aliceRootAuthArgs = [
        tokenABytes,
        tokenBBytes,
        amountA,
        minBForA
      ];
      AuthorizedInvocation aliceRootInvocation = AuthorizedInvocation(
          atomicSwapContractId, swapFuntionName,
          args: aliceRootAuthArgs, subInvocations: [aliceSubAuthInvocation]);

      List<XdrSCVal> bobSubAuthArgs = [
        addressBob.toXdrSCVal(),
        addressSwapContract.toXdrSCVal(),
        amountB
      ];
      AuthorizedInvocation bobSubAuthInvocation = AuthorizedInvocation(
          tokenBCId, incrAllowFunctionName,
          args: bobSubAuthArgs);
      List<XdrSCVal> bobRootAuthArgs = [
        tokenBBytes,
        tokenABytes,
        amountB,
        minAForB
      ];
      AuthorizedInvocation bobRootInvocation = AuthorizedInvocation(
          atomicSwapContractId, swapFuntionName,
          args: bobRootAuthArgs, subInvocations: [bobSubAuthInvocation]);

      int aliceNonce =
          await sorobanServer.getNonce(aliceAccountId, atomicSwapContractId);
      ContractAuth aliceContractAuth = ContractAuth(aliceRootInvocation,
          address: addressAlice, nonce: aliceNonce);
      aliceContractAuth.sign(aliceKp, Network.FUTURENET);

      int bobNonce =
          await sorobanServer.getNonce(bobAccountId, atomicSwapContractId);
      ContractAuth bobContractAuth =
          ContractAuth(bobRootInvocation, address: addressBob, nonce: bobNonce);
      bobContractAuth.sign(bobKp, Network.FUTURENET);

      List<XdrSCVal> invokeArgs = [
        addressAlice.toXdrSCVal(),
        addressBob.toXdrSCVal(),
        tokenABytes,
        tokenBBytes,
        amountA,
        minBForA,
        amountB,
        minAForB
      ];

      // load submitter account for sequence number
      AccountResponse swapSubmitter =
          await sdk.accounts.account(swapSubmitterAccountId);

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          atomicSwapContractId, swapFuntionName, arguments: invokeArgs,
          auth: [aliceContractAuth, bobContractAuth]);
      InvokeHostFunctionOperation op = (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

      Transaction transaction =
          new TransactionBuilder(swapSubmitter).addOperation(op).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(swapSubmitterKp, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send the transaction
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      GetTransactionResponse statusResponse =
          await pollStatus(sendResponse.hash!);
      String status = statusResponse.status!;
      assert(status == GetTransactionResponse.STATUS_SUCCESS);
      print("Result " + statusResponse.getResultValue()!.toBase64EncodedXdrString());
    });
  });
}
