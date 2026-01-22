import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../tests_util.dart';

void main() {
  String testOn = 'testnet'; // futurenet

  SorobanServer sorobanServer = testOn == 'testnet'
      ? SorobanServer("https://soroban-testnet.stellar.org")
      : SorobanServer("https://rpc-futurenet.stellar.org");

  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;

  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  KeyPair adminKeypair = KeyPair.random();
  String adminId = adminKeypair.accountId;
  KeyPair aliceKeypair = KeyPair.random();
  String aliceId = aliceKeypair.accountId;
  KeyPair bobKeypair = KeyPair.random();
  String bobId = bobKeypair.accountId;

  String tokenContractPath = "test/wasm/soroban_token_contract.wasm";
  String swapContractPath = "test/wasm/soroban_atomic_swap_contract.wasm";
  String? tokenAContractWasmId;
  String? tokenAContractId;
  String? tokenBContractWasmId;
  String? tokenBContractId;
  String? swapContractWasmId;
  String? swapContractId;

  setUp(() async {
    sorobanServer.enableLogging = true;

    try {
      await sdk.accounts.account(adminId);
    } catch (e) {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(adminId);
      } else if (testOn == 'futurenet') {
        await FuturenetFriendBot.fundTestAccount(adminId);
      }
      print("admin " + adminId + " : " + adminKeypair.secretSeed);
    }

    try {
      await sdk.accounts.account(aliceId);
    } catch (e) {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(aliceId);
      } else if (testOn == 'futurenet') {
        await FuturenetFriendBot.fundTestAccount(aliceId);
      }
      print("alice " + aliceId + " : " + aliceKeypair.secretSeed);
    }

    try {
      await sdk.accounts.account(bobId);
    } catch (e) {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(bobId);
      } else if (testOn == 'futurenet') {
        await FuturenetFriendBot.fundTestAccount(bobId);
      }
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
    Account? account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    Account submitter = account!;

    // load contract wasm file
    Uint8List contractCode = await loadContractCode(contractCodePath);

    // upload contract
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(UploadContractWasmHostFunction(contractCode))
            .build();
    Transaction transaction =
        new TransactionBuilder(submitter).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    var request = SimulateTransactionRequest(transaction);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(!simulateResponse.isErrorResponse);
    assert(simulateResponse.transactionData != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, network);

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

  Future<String> createContract(String wasmId,
      {List<XdrSCVal>? constructorArgs}) async {
    await Future.delayed(Duration(seconds: 5));

    // reload account for current sequence nr
    Account? account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    Account submitter = account!;

    // build the operation for creating the contract
    HostFunction function;
    if (constructorArgs == null) {
      function =
          CreateContractHostFunction(Address.forAccountId(adminId), wasmId);
    } else {
      function = CreateContractWithConstructorHostFunction(
          Address.forAccountId(adminId), wasmId, constructorArgs);
    }

    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(function).build();

    // build the transaction for creating the contract
    Transaction transaction =
        new TransactionBuilder(submitter).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    var request = SimulateTransactionRequest(transaction);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(!simulateResponse.isErrorResponse);
    assert(simulateResponse.resultError == null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.setSorobanAuth(simulateResponse.sorobanAuth);
    transaction.sign(adminKeypair, network);

    // send transaction to soroban rpc server
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(!sendResponse.isErrorResponse);

    assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

    GetTransactionResponse statusResponse =
        await pollStatus(sendResponse.hash!);
    String? contractId = statusResponse.getCreatedContractId();
    assert(contractId != null);
    return contractId!;
  }

  Future<void> mint(String contractId, String toAccountId, int amount) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface

    await Future.delayed(Duration(seconds: 5));

    // reload account for sequence number
    Account? account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    Account invoker = account!;

    Address toAddress = Address.forAccountId(toAccountId);
    XdrSCVal amountVal = XdrSCVal.forI128(XdrInt128Parts.forHiLo(BigInt.zero, BigInt.from(amount)));
    String functionName = "mint";

    List<XdrSCVal> args = [toAddress.toXdrSCVal(), amountVal];

    InvokeContractHostFunction hostFunction =
        InvokeContractHostFunction(contractId, functionName, arguments: args);
    InvokeHostFunctionOperation operation =
        (InvokeHostFuncOpBuilder(hostFunction)).build();

    Transaction transaction =
        new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    var request = SimulateTransactionRequest(transaction);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.setSorobanAuth(simulateResponse.sorobanAuth);
    transaction.sign(adminKeypair, network);

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
    Account? account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    Account invoker = account!;

    Address address = Address.forAccountId(accountId);
    String functionName = "balance";

    List<XdrSCVal> args = [address.toXdrSCVal()];

    InvokeContractHostFunction hostFunction =
        InvokeContractHostFunction(contractId, functionName, arguments: args);
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(hostFunction).build();

    Transaction transaction =
        new TransactionBuilder(invoker).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    var request = SimulateTransactionRequest(transaction);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, network);

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
    return parts.lo.uint64.toInt();
  }

  Future restoreContractFootprint(String contractCodePath) async {
    await Future.delayed(Duration(seconds: 5));

    // load account
    Account? account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    Account accountA = account!;

    // load contract wasm file
    Uint8List contractCode = await loadContractCode(contractCodePath);

    UploadContractWasmHostFunction uploadFunction =
        UploadContractWasmHostFunction(contractCode);
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(uploadFunction).build();
    Transaction transaction =
        new TransactionBuilder(accountA).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    var request = SimulateTransactionRequest(transaction);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    XdrSorobanTransactionData transactionData =
        simulateResponse.transactionData!;
    transactionData.resources.footprint.readWrite
        .addAll(transactionData.resources.footprint.readOnly);
    transactionData.resources.footprint.readOnly =
        List<XdrLedgerKey>.empty(growable: false);

    account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    accountA = account!;

    RestoreFootprintOperation restoreOp =
        RestoreFootprintOperationBuilder().build();
    transaction =
        new TransactionBuilder(accountA).addOperation(restoreOp).build();
    transaction.sorobanTransactionData = transactionData;

    // simulate first to obtain the transaction data + resource fee
    request = SimulateTransactionRequest(transaction);
    simulateResponse = await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);
    assert(simulateResponse.minResourceFee != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, network);

    // check transaction xdr encoding and decoding back and forth
    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
    assert(transactionEnvelopeXdr ==
        AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
            .toEnvelopeXdrBase64());

    // send transaction to soroban rpc server
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(sendResponse.error == null);
    assert(sendResponse.hash != null);
    assert(sendResponse.status != null);
    assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

    GetTransactionResponse rpcTransactionResponse =
        await pollStatus(sendResponse.hash!);
    assert(
        GetTransactionResponse.STATUS_SUCCESS == rpcTransactionResponse.status);
  }

  Future extendContractCodeFootprintTTL(String wasmId, int extendTo) async {
    await Future.delayed(Duration(seconds: 5));

    // load account
    Account? account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    Account accountA = account!;

    ExtendFootprintTTLOperation bumpFunction =
        ExtendFootprintTTLOperationBuilder(extendTo).build();
    // create transaction for bumping
    Transaction transaction =
        new TransactionBuilder(accountA).addOperation(bumpFunction).build();

    List<XdrLedgerKey> readOnly = List<XdrLedgerKey>.empty(growable: true);
    List<XdrLedgerKey> readWrite = List<XdrLedgerKey>.empty(growable: false);
    XdrLedgerKey codeKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
    codeKey.contractCode =
        XdrLedgerKeyContractCode(XdrHash(Util.hexToBytes(wasmId)));
    readOnly.add(codeKey);

    XdrLedgerFootprint footprint = XdrLedgerFootprint(readOnly, readWrite);
    XdrSorobanResources resources = XdrSorobanResources(
        footprint, XdrUint32(0), XdrUint32(0), XdrUint32(0));
    XdrSorobanTransactionData transactionData = XdrSorobanTransactionData(
        XdrSorobanTransactionDataExt(0), resources, XdrInt64(BigInt.zero));

    transaction.sorobanTransactionData = transactionData;

    // simulate first to obtain the transaction data + resource fee
    var request = SimulateTransactionRequest(transaction);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    account = await sorobanServer.getAccount(adminId);
    assert(account != null);
    accountA = account!;

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, network);

    // check transaction xdr encoding and decoding back and forth
    String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
    assert(transactionEnvelopeXdr ==
        AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
            .toEnvelopeXdrBase64());

    // send transaction to soroban rpc server
    SendTransactionResponse sendResponse =
        await sorobanServer.sendTransaction(transaction);
    assert(sendResponse.error == null);
    assert(sendResponse.hash != null);
    assert(sendResponse.status != null);
    assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

    GetTransactionResponse rpcTransactionResponse =
        await pollStatus(sendResponse.hash!);
    assert(
        GetTransactionResponse.STATUS_SUCCESS == rpcTransactionResponse.status);

    await Future.delayed(Duration(seconds: 5));
    // check horizon responses decoding
    TransactionResponse transactionResponse =
        await sdk.transactions.transaction(sendResponse.hash!);
    assert(transactionResponse.operationCount == 1);
    assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

    // check operation response from horizon
    Page<OperationResponse> operations =
        await sdk.operations.forTransaction(sendResponse.hash!).execute();
    assert(operations.records.isNotEmpty);
    OperationResponse operationResponse = operations.records.first;

    if (operationResponse is ExtendFootprintTTLOperationResponse) {
      assert("extend_footprint_ttl" == operationResponse.type);
    } else {
      assert(false);
    }
  }

  group('all tests', () {
    test('test install contracts', () async {
      tokenAContractWasmId = await installContract(tokenContractPath);
      await Future.delayed(Duration(seconds: 5));
      await extendContractCodeFootprintTTL(tokenAContractWasmId!, 100000);
      tokenBContractWasmId = await installContract(tokenContractPath);
      await Future.delayed(Duration(seconds: 5));
      await extendContractCodeFootprintTTL(tokenBContractWasmId!, 100000);
      var contractInfo =
          await sorobanServer.loadContractInfoForWasmId(tokenBContractWasmId!);
      assert(contractInfo != null);
      assert(contractInfo!.specEntries.length > 0);
      assert(contractInfo!.metaEntries.length > 0);
      swapContractWasmId = await installContract(swapContractPath);
      await extendContractCodeFootprintTTL(swapContractWasmId!, 100000);
      contractInfo =
          await sorobanServer.loadContractInfoForWasmId(swapContractWasmId!);
      assert(contractInfo != null);
      assert(contractInfo!.specEntries.length > 0);
      assert(contractInfo!.metaEntries.length > 0);
      await Future.delayed(Duration(seconds: 5));
    });

    test('test create contracts', () async {
      Account? account = await sorobanServer.getAccount(adminId);
      assert(account != null);

      Address adminAddress = Address.forAccountId(adminId);

      List<XdrSCVal> constructorArgs = [
        adminAddress.toXdrSCVal(),
        XdrSCVal.forU32(8),
        XdrSCVal.forString("TokenA"),
        XdrSCVal.forString("TokenA")
      ];

      tokenAContractId = await createContract(tokenAContractWasmId!,
          constructorArgs: constructorArgs);
      print("Token A Contract ID: " + tokenAContractId!);
      await Future.delayed(Duration(seconds: 5));

      constructorArgs = [
        adminAddress.toXdrSCVal(),
        XdrSCVal.forU32(8),
        XdrSCVal.forString("TokenB"),
        XdrSCVal.forString("TokenB")
      ];

      tokenBContractId = await createContract(tokenBContractWasmId!,
          constructorArgs: constructorArgs);
      print("Token B Contract ID: " + tokenBContractId!);
      var contractInfo =
          await sorobanServer.loadContractInfoForContractId(tokenBContractId!);
      assert(contractInfo != null);
      assert(contractInfo!.specEntries.length > 0);
      assert(contractInfo!.metaEntries.length > 0);
      await Future.delayed(Duration(seconds: 5));
      swapContractId = await createContract(swapContractWasmId!);
      print("SWAP Contract ID: " + swapContractId!);
      contractInfo =
          await sorobanServer.loadContractInfoForContractId(swapContractId!);
      assert(contractInfo != null);
      assert(contractInfo!.specEntries.length > 0);
      assert(contractInfo!.metaEntries.length > 0);
      await Future.delayed(Duration(seconds: 5));
    });

    test('test restore footprint', () async {
      await restoreContractFootprint(tokenContractPath);
      await restoreContractFootprint(swapContractPath);
    });

    test('test mint tokens', () async {
      await mint(tokenAContractId!, aliceId, 10000000000000);
      await Future.delayed(Duration(seconds: 5));
      await mint(tokenBContractId!, bobId, 10000000000000);
      await Future.delayed(Duration(seconds: 5));
      int aliceTokenABalance = await balance(tokenAContractId!, aliceId);
      assert(aliceTokenABalance == 10000000000000);
      await Future.delayed(Duration(seconds: 5));
      int bobTokenBBalance = await balance(tokenBContractId!, bobId);
      assert(bobTokenBBalance == 10000000000000);
      await Future.delayed(Duration(seconds: 5));
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

      XdrSCVal amountA = XdrSCVal.forI128(XdrInt128Parts.forHiLo(BigInt.zero, BigInt.from(1000)));
      XdrSCVal minBForA = XdrSCVal.forI128(XdrInt128Parts.forHiLo(BigInt.zero, BigInt.from(4500)));

      XdrSCVal amountB = XdrSCVal.forI128(XdrInt128Parts.forHiLo(BigInt.zero, BigInt.from(5000)));
      XdrSCVal minAForB = XdrSCVal.forI128(XdrInt128Parts.forHiLo(BigInt.zero, BigInt.from(950)));

      String swapFuntionName = "swap";

      List<XdrSCVal> invokeArgs = [
        addressAlice.toXdrSCVal(),
        addressBob.toXdrSCVal(),
        Address.forContractId(tokenACId).toXdrSCVal(),
        Address.forContractId(tokenBCId).toXdrSCVal(),
        amountA,
        minBForA,
        amountB,
        minAForB
      ];

      // load submitter account for sequence number
      Account? account = await sorobanServer.getAccount(swapSubmitterAccountId);
      assert(account != null);
      Account swapSubmitter = account!;

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          atomicSwapContractId, swapFuntionName,
          arguments: invokeArgs);

      InvokeHostFunctionOperation op =
          InvokeHostFuncOpBuilder(hostFunction).build();

      Transaction transaction =
          new TransactionBuilder(swapSubmitter).addOperation(op).build();

      // simulate first to obtain the transaction data + resource fee
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      /*int instructions =
          simulateResponse.transactionData!.resources.instructions.uint32;
      instructions += (instructions / 4).round();
      simulateResponse.transactionData!.resources.instructions =
          XdrUint32(instructions);
      simulateResponse.minResourceFee =
          simulateResponse.minResourceFee! + 1005000;*/
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      // sign auth
      List<SorobanAuthorizationEntry>? auth = simulateResponse.sorobanAuth;
      assert(auth != null);
      GetLatestLedgerResponse latestLedgerResponse =
          await sorobanServer.getLatestLedger();

      for (SorobanAuthorizationEntry a in auth!) {
        a.credentials.addressCredentials!.signatureExpirationLedger =
            latestLedgerResponse.sequence! + 10;

        if (a.credentials.addressCredentials!.address.accountId == aliceId) {
          a.sign(aliceKeypair, network);
        }
        if (a.credentials.addressCredentials!.address.accountId == bobId) {
          a.sign(bobKeypair, network);
        }
      }
      transaction.setSorobanAuth(auth);
      transaction.sign(swapSubmitterKp, network);

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
      print("Result " +
          statusResponse.getResultValue()!.toBase64EncodedXdrString());
    });
  });
}
