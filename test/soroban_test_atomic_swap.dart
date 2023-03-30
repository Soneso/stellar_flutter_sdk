import 'dart:typed_data';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
  SorobanServer("https://horizon-futurenet.stellar.cash/soroban/rpc");

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
    sorobanServer.enableLogging = false;
    sorobanServer.acknowledgeExperimental = true;
    GetAccountResponse accountResponse =
    await sorobanServer.getAccount(adminId);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(adminId);
      print("admin " + adminId + " : " + adminKeypair.secretSeed);
    }
    await sorobanServer.getAccount(aliceId);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(aliceId);
      print("alice " + aliceId + " : " + aliceKeypair.secretSeed);
    }
    await sorobanServer.getAccount(bobId);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(bobId);
      print("bob " + bobId + " : " + bobKeypair.secretSeed);
    }
  });

  // poll until success or error
  Future<GetTransactionStatusResponse> pollStatus(String transactionId) async {
    var status = SorobanServer.TRANSACTION_STATUS_PENDING;
    GetTransactionStatusResponse? statusResponse;
    while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
      await Future.delayed(const Duration(seconds: 3), () {});
      statusResponse = await sorobanServer.getTransactionStatus(transactionId);
      assert(statusResponse.error == null);
      status = statusResponse.status!;
      if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
        assert(statusResponse.resultError != null);
        print(statusResponse.resultError?.message);
        assert(false);
      } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
        assert(statusResponse.results != null);
        assert(statusResponse.results!.isNotEmpty);
      }
    }
    return statusResponse!;
  }

  Future<String> installContract(String contractCodePath) async {
    // load account
    GetAccountResponse submitter =
    await sorobanServer.getAccount(adminId);
    assert(!submitter.isErrorResponse);

    // load contract wasm file
    Uint8List contractCode = await Util.readFile(contractCodePath);

    // create transaction for installing the contract
    InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder.forInstallingContractCode(contractCode)
        .build();
    Transaction transaction =
    new TransactionBuilder(submitter).addOperation(operation).build();

    // simulate first to obtain the footprint
    SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);
    assert(!simulateResponse.isErrorResponse);
    assert(simulateResponse.footprint != null);

    // set footprint and sign transaction
    transaction.setFootprint(simulateResponse.footprint!);
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
    assert(sendResponse.resultError == null);

    GetTransactionStatusResponse statusResponse =
    await pollStatus(sendResponse.transactionId!);
    String? wasmId = statusResponse.getWasmId();
    assert(wasmId != null);
    return wasmId!;
  }

  Future<String> createContract(String wasmId) async {

    // reload account for current sequence nr
    GetAccountResponse submitter =
    await sorobanServer.getAccount(adminId);
    assert(!submitter.isErrorResponse);

    // build the operation for creating the contract
    InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder.forCreatingContract(wasmId)
        .build();

    // build the transaction for creating the contract
    Transaction transaction =
    new TransactionBuilder(submitter).addOperation(operation).build();

    // first simulate to obtain the footprint
    SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);
    assert(!simulateResponse.isErrorResponse);
    assert(simulateResponse.resultError == null);

    // set footprint & sign
    transaction.setFootprint(simulateResponse.footprint!);
    transaction.sign(adminKeypair, Network.FUTURENET);

    // send transaction to soroban rpc server
    SendTransactionResponse sendResponse =
    await sorobanServer.sendTransaction(transaction);
    assert(!sendResponse.isErrorResponse);
    assert(sendResponse.resultError == null);

    GetTransactionStatusResponse statusResponse =
    await pollStatus(sendResponse.transactionId!);
    String? contractId = statusResponse.getContractId();
    assert(contractId != null);
    return contractId!;
  }

  Future<void> createToken(String contractId, String name, String symbol) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
    // reload account for sequence number
    GetAccountResponse invoker = await sorobanServer.getAccount(adminId);
    assert(!invoker.isErrorResponse);

    Address adminAddress = Address.forAccountId(adminId);
    String functionName = "initialize";
    List<int> list = utf8.encode(name);
    String nameHex = hex.encode(list);
    XdrSCVal tokenName = XdrSCVal.forObject(XdrSCObject.forBytes(Util.hexToBytes(nameHex)));
    list = utf8.encode(name);
    String symbolHex = hex.encode(list);
    XdrSCVal tokenSymbol = XdrSCVal.forObject(XdrSCObject.forBytes(Util.hexToBytes(symbolHex)));

    List<XdrSCVal> args = [adminAddress.toXdrSCVal(), XdrSCVal.forU32(8), tokenName, tokenSymbol];

    AuthorizedInvocation rootInvocation =
    AuthorizedInvocation(contractId, functionName, args: args);

    ContractAuth contractAuth = ContractAuth(rootInvocation);

    InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder.forInvokingContract(
        contractId, functionName,
        functionArguments: args, contractAuth: [contractAuth]).build();
    Transaction transaction =
    new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to get footprint
    SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.footprint != null);

    // set footprint and sign
    transaction.setFootprint(simulateResponse.footprint!);
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
    assert(sendResponse.resultError == null);

    GetTransactionStatusResponse statusResponse =
    await pollStatus(sendResponse.transactionId!);
    String status = statusResponse.status!;
    assert(status == SorobanServer.TRANSACTION_STATUS_SUCCESS);
  }

  Future<void> mint(String contractId, String toAccountId, int amount) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
    // reload account for sequence number
    GetAccountResponse invoker = await sorobanServer.getAccount(adminId);
    assert(!invoker.isErrorResponse);

    Address adminAddress = Address.forAccountId(adminId);
    Address toAddress = Address.forAccountId(toAccountId);
    XdrSCVal amountVal = XdrSCVal.forObject(
        XdrSCObject.forI128(XdrInt128Parts.forLoHi(amount, 0)));
    String functionName = "mint";

    List<XdrSCVal> args = [adminAddress.toXdrSCVal(), toAddress.toXdrSCVal(), amountVal];

    AuthorizedInvocation rootInvocation =
    AuthorizedInvocation(contractId, functionName, args: args);

    ContractAuth contractAuth = ContractAuth(rootInvocation);

    InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder.forInvokingContract(
        contractId, functionName,
        functionArguments: args, contractAuth: [contractAuth]).build();
    Transaction transaction =
    new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to get footprint
    SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.footprint != null);

    // set footprint and sign
    transaction.setFootprint(simulateResponse.footprint!);
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
    assert(sendResponse.resultError == null);

    GetTransactionStatusResponse statusResponse =
    await pollStatus(sendResponse.transactionId!);
    String status = statusResponse.status!;
    assert(status == SorobanServer.TRANSACTION_STATUS_SUCCESS);
  }

  Future<int>balance(String contractId, String accountId) async {

    // reload account for sequence number
    GetAccountResponse invoker = await sorobanServer.getAccount(adminId);
    assert(!invoker.isErrorResponse);


    Address address = Address.forAccountId(accountId);
    String functionName = "balance";

    List<XdrSCVal> args = [address.toXdrSCVal()];

    InvokeHostFunctionOperation operation =
    InvokeHostFuncOpBuilder.forInvokingContract(
        contractId, functionName,
        functionArguments: args).build();
    Transaction transaction =
    new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to get footprint
    SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.footprint != null);

    // set footprint and sign
    transaction.setFootprint(simulateResponse.footprint!);
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
    assert(sendResponse.resultError == null);

    GetTransactionStatusResponse statusResponse =
    await pollStatus(sendResponse.transactionId!);
    String status = statusResponse.status!;
    assert(status == SorobanServer.TRANSACTION_STATUS_SUCCESS);

    assert(statusResponse.getResultValue()?.getI128() != null);
    XdrInt128Parts parts = statusResponse.getResultValue()!.getI128()!;
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
      String  tokenBCId = tokenBContractId!;

      Address addressAlice = Address.forAccountId(aliceAccountId);
      Address addressBob = Address.forAccountId(bobAccountId);
      Address addressSwapContract = Address.forContractId(atomicSwapContractId);

      XdrSCVal tokenABytes = XdrSCVal.forObject(
          XdrSCObject.forBytes(Util.hexToBytes(tokenACId)));
      XdrSCVal tokenBBytes = XdrSCVal.forObject(
          XdrSCObject.forBytes(Util.hexToBytes(tokenBCId)));

      XdrSCVal amountA = XdrSCVal.forObject(
          XdrSCObject.forI128(XdrInt128Parts.forLoHi(1000, 0)));
      XdrSCVal minBForA = XdrSCVal.forObject(
          XdrSCObject.forI128(XdrInt128Parts.forLoHi(4500, 0)));

      XdrSCVal amountB = XdrSCVal.forObject(
          XdrSCObject.forI128(XdrInt128Parts.forLoHi(5000, 0)));
      XdrSCVal minAForB = XdrSCVal.forObject(
          XdrSCObject.forI128(XdrInt128Parts.forLoHi(950, 0)));

      String swapFuntionName = "swap";
      String incrAllowFunctionName = "incr_allow";

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
      GetAccountResponse swapSubmitter =
      await sorobanServer.getAccount(swapSubmitterAccountId);
      assert(!swapSubmitter.isErrorResponse);

      InvokeHostFunctionOperation operation =
      InvokeHostFuncOpBuilder.forInvokingContract(
          atomicSwapContractId, swapFuntionName,
          functionArguments: invokeArgs,
          contractAuth: [aliceContractAuth, bobContractAuth]).build();

      Transaction transaction =
      new TransactionBuilder(swapSubmitter).addOperation(operation).build();

      // simulate first to get footprint
      SimulateTransactionResponse simulateResponse =
      await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);

      // set footprint and sign
      transaction.setFootprint(simulateResponse.footprint!);
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
      assert(sendResponse.resultError == null);

      GetTransactionStatusResponse statusResponse =
      await pollStatus(sendResponse.transactionId!);
      String status = statusResponse.status!;
      assert(status == SorobanServer.TRANSACTION_STATUS_SUCCESS);
      print("Result " + statusResponse.results![0].xdr);
    });
  });
}
