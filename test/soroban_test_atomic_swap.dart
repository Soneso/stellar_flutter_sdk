import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://soroban-testnet.stellar.org");

  StellarSDK sdk = StellarSDK.TESTNET;

  KeyPair adminKeypair = KeyPair.random();
  String adminId = adminKeypair.accountId;
  KeyPair aliceKeypair = KeyPair.random();
  String aliceId = aliceKeypair.accountId;
  KeyPair bobKeypair = KeyPair.random();
  String bobId = bobKeypair.accountId;

  String tokenContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_token_contract.wasm";
  String swapContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_atomic_swap_contract.wasm";
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
      await FriendBot.fundTestAccount(adminId);
      print("admin " + adminId + " : " + adminKeypair.secretSeed);
    }

    try {
      await sdk.accounts.account(aliceId);
    } catch (e) {
      await FriendBot.fundTestAccount(aliceId);
      print("alice " + aliceId + " : " + aliceKeypair.secretSeed);
    }

    try {
      await sdk.accounts.account(bobId);
    } catch (e) {
      await FriendBot.fundTestAccount(bobId);
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
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(UploadContractWasmHostFunction(contractCode))
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
    transaction.sign(adminKeypair, Network.TESTNET);

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
    CreateContractHostFunction function =
        CreateContractHostFunction(Address.forAccountId(adminId), wasmId);
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(function).build();

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
    transaction.setSorobanAuth(simulateResponse.sorobanAuth);
    transaction.sign(adminKeypair, Network.TESTNET);

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

  Future<void> createToken(
      String contractId, String name, String symbol) async {
    // see https://soroban.stellar.org/docs/reference/interfaces/token-interface
    // reload account for sequence number
    await Future.delayed(Duration(seconds: 5));
    AccountResponse invoker = await sdk.accounts.account(adminId);

    Address adminAddress = Address.forAccountId(adminId);
    String functionName = "initialize";
    XdrSCVal tokenName = XdrSCVal.forString(name);
    XdrSCVal tokenSymbol = XdrSCVal.forString(symbol);

    List<XdrSCVal> args = [
      adminAddress.toXdrSCVal(),
      XdrSCVal.forU32(8),
      tokenName,
      tokenSymbol
    ];

    InvokeContractHostFunction hostFunction =
        InvokeContractHostFunction(contractId, functionName, arguments: args);
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(hostFunction).build();

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
    transaction.setSorobanAuth(simulateResponse.sorobanAuth);
    transaction.sign(adminKeypair, Network.TESTNET);

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

    List<XdrSCVal> args = [toAddress.toXdrSCVal(), amountVal];

    InvokeContractHostFunction hostFunction =
        InvokeContractHostFunction(contractId, functionName, arguments: args);
    InvokeHostFunctionOperation operation =
        (InvokeHostFuncOpBuilder(hostFunction)).build();

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
    transaction.setSorobanAuth(simulateResponse.sorobanAuth);
    transaction.sign(adminKeypair, Network.TESTNET);

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

    InvokeContractHostFunction hostFunction =
        InvokeContractHostFunction(contractId, functionName, arguments: args);
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(hostFunction).build();

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
    transaction.sign(adminKeypair, Network.TESTNET);

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

  Future restoreContractFootprint(String contractCodePath) async {
    await Future.delayed(Duration(seconds: 5));
    // load account
    AccountResponse accountA = await sdk.accounts.account(adminId);

    // load contract wasm file
    Uint8List contractCode = await Util.readFile(contractCodePath);

    UploadContractWasmHostFunction uploadFunction =
        UploadContractWasmHostFunction(contractCode);
    InvokeHostFunctionOperation operation =
        InvokeHostFuncOpBuilder(uploadFunction).build();
    Transaction transaction =
        new TransactionBuilder(accountA).addOperation(operation).build();

    // simulate first to obtain the transaction data + resource fee
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    XdrSorobanTransactionData transactionData =
        simulateResponse.transactionData!;
    transactionData.resources.footprint.readWrite
        .addAll(transactionData.resources.footprint.readOnly);
    transactionData.resources.footprint.readOnly =
        List<XdrLedgerKey>.empty(growable: false);

    accountA = await sdk.accounts.account(adminId);
    RestoreFootprintOperation restoreOp =
        RestoreFootprintOperationBuilder().build();
    transaction =
        new TransactionBuilder(accountA).addOperation(restoreOp).build();
    transaction.sorobanTransactionData = transactionData;
    transaction.addResourceFee(10000);

    // simulate first to obtain the transaction data + resource fee
    simulateResponse = await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);
    assert(simulateResponse.minResourceFee != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, Network.TESTNET);

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

  Future bumpContractCodeFootprint(String wasmId, int ledgersToExpire) async {
    await Future.delayed(Duration(seconds: 5));

    // load account
    AccountResponse accountA = await sdk.accounts.account(adminId);

    BumpFootprintExpirationOperation bumpFunction =
        BumpFootprintExpirationOperationBuilder(ledgersToExpire).build();
    // create transaction for bumping
    Transaction transaction =
        new TransactionBuilder(accountA).addOperation(bumpFunction).build();

    List<XdrLedgerKey> readOnly = List<XdrLedgerKey>.empty(growable: true);
    List<XdrLedgerKey> readWrite = List<XdrLedgerKey>.empty(growable: false);
    XdrLedgerKey codeKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
    codeKey.contractCode = XdrLedgerKeyContractCode(
        XdrHash(Util.hexToBytes(wasmId)));
    readOnly.add(codeKey);

    XdrLedgerFootprint footprint = XdrLedgerFootprint(readOnly, readWrite);
    XdrSorobanResources resources = XdrSorobanResources(
        footprint, XdrUint32(0), XdrUint32(0), XdrUint32(0));
    XdrSorobanTransactionData transactionData =
        XdrSorobanTransactionData(XdrExtensionPoint(0), resources, XdrInt64(0));

    transaction.sorobanTransactionData = transactionData;

    // simulate first to obtain the transaction data + resource fee
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(transaction);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    accountA = await sdk.accounts.account(adminId);
    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(adminKeypair, Network.TESTNET);

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
    assert(operations.records != null && operations.records!.length > 0);
    OperationResponse operationResponse = operations.records!.first;

    if (operationResponse is BumpFootprintExpirationOperationResponse) {
      assert("bump_footprint_expiration" == operationResponse.type);
    } else {
      assert(false);
    }
  }

  group('all tests', () {
    test('test restore footprint', () async {
      await restoreContractFootprint(tokenContractPath);
      await restoreContractFootprint(swapContractPath);
    });

    test('test install contracts', () async {
      tokenAContractWasmId = await installContract(tokenContractPath);
      await Future.delayed(Duration(seconds: 5));
      await bumpContractCodeFootprint(tokenAContractWasmId!, 100000);
      tokenBContractWasmId = await installContract(tokenContractPath);
      await Future.delayed(Duration(seconds: 5));
      await bumpContractCodeFootprint(tokenBContractWasmId!, 100000);
      swapContractWasmId = await installContract(swapContractPath);
      await bumpContractCodeFootprint(swapContractWasmId!, 100000);
      await Future.delayed(Duration(seconds: 5));
    });

    test('test create contracts', () async {
      tokenAContractId = await createContract(tokenAContractWasmId!);
      print("Token A Contract ID: " + tokenAContractId!);
      await Future.delayed(Duration(seconds: 5));
      tokenBContractId = await createContract(tokenBContractWasmId!);
      print("Token B Contract ID: " + tokenBContractId!);
      await Future.delayed(Duration(seconds: 5));
      swapContractId = await createContract(swapContractWasmId!);
      print("SWAP Contract ID: " + swapContractId!);
      await Future.delayed(Duration(seconds: 5));
    });

    test('test create tokens', () async {
      await createToken(tokenAContractId!, "TokenA", "TokenA");
      await Future.delayed(Duration(seconds: 5));
      await createToken(tokenBContractId!, "TokenB", "TokenB");
      await Future.delayed(Duration(seconds: 5));
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

      XdrSCVal amountA = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 1000));
      XdrSCVal minBForA = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 4500));

      XdrSCVal amountB = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 5000));
      XdrSCVal minAForB = XdrSCVal.forI128(XdrInt128Parts.forHiLo(0, 950));

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
      AccountResponse swapSubmitter =
          await sdk.accounts.account(swapSubmitterAccountId);

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          atomicSwapContractId, swapFuntionName,
          arguments: invokeArgs);

      InvokeHostFunctionOperation op =
          InvokeHostFuncOpBuilder(hostFunction).build();

      Transaction transaction =
          new TransactionBuilder(swapSubmitter).addOperation(op).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      int instructions =
          simulateResponse.transactionData!.resources.instructions.uint32;
      instructions += (instructions / 4).round();
      simulateResponse.transactionData!.resources.instructions =
          XdrUint32(instructions);
      simulateResponse.minResourceFee =
          simulateResponse.minResourceFee! + 1005000;
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
          a.sign(aliceKeypair, Network.TESTNET);
        }
        if (a.credentials.addressCredentials!.address.accountId == bobId) {
          a.sign(bobKeypair, Network.TESTNET);
        }
      }
      transaction.setSorobanAuth(auth);
      transaction.sign(swapSubmitterKp, Network.TESTNET);

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
