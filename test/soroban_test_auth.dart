import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'tests_util.dart';

void main() {
  String testOn = 'testnet'; // 'futurenet'

  SorobanServer sorobanServer = testOn == 'testnet'
      ? SorobanServer("https://soroban-testnet.stellar.org")
      : SorobanServer("https://rpc-futurenet.stellar.org");

  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;

  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  KeyPair submitterKeypair = KeyPair.random();
  String submitterId = submitterKeypair.accountId;
  KeyPair invokerKeypair = KeyPair.random();
  String invokerId = invokerKeypair.accountId;

  String authContractPath = "test/wasm/soroban_auth_contract.wasm";
  String? authContractWasmId;
  String? authContractId;

  setUp(() async {
    sorobanServer.enableLogging = true;

    try {
      await sdk.accounts.account(submitterId);
    } catch (e) {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(submitterId);
      } else if (testOn == 'futurenet') {
        await FuturenetFriendBot.fundTestAccount(submitterId);
      }
    }

    try {
      await sdk.accounts.account(invokerId);
    } catch (e) {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(invokerId);
      } else if (testOn == 'futurenet') {
        await FuturenetFriendBot.fundTestAccount(invokerId);
      }
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

  Future restoreContractFootprint(String contractCodePath) async {
    await Future.delayed(Duration(seconds: 5));
    // load account
    Account? account = await sorobanServer.getAccount(submitterId);
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
    var request = new SimulateTransactionRequest(transaction);
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

    account = await sorobanServer.getAccount(submitterId);
    assert(account != null);
    accountA = account!;

    RestoreFootprintOperation restoreOp =
        RestoreFootprintOperationBuilder().build();
    transaction =
        new TransactionBuilder(accountA).addOperation(restoreOp).build();
    transaction.sorobanTransactionData = transactionData;

    // simulate first to obtain the transaction data + resource fee
    request = new SimulateTransactionRequest(transaction);
    simulateResponse = await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);
    assert(simulateResponse.minResourceFee != null);

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(submitterKeypair, network);

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
    Account? account = await sorobanServer.getAccount(submitterId);
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
    XdrSorobanTransactionData transactionData =
        XdrSorobanTransactionData(XdrSorobanTransactionDataExt(0), resources, XdrInt64(BigInt.zero));

    transaction.sorobanTransactionData = transactionData;

    // simulate first to obtain the transaction data + resource fee
    var request = new SimulateTransactionRequest(transaction);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    account = await sorobanServer.getAccount(submitterId);
    assert(account != null);
    accountA = account!;

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(submitterKeypair, network);

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

    test('test upload auth contract', () async {
      await Future.delayed(Duration(seconds: 5));
      // load account
      Account? account = await sorobanServer.getAccount(submitterId);
      assert(account != null);
      Account submitter = account!;

      // load contract wasm file
      Uint8List contractCode = await loadContractCode(authContractPath);

      // upload the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(UploadContractWasmHostFunction(contractCode))
              .build();
      // create transaction for installing the contract
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(!simulateResponse.isErrorResponse);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(submitterKeypair, network);

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
      authContractWasmId = rpcTransactionResponse.getWasmId();

      assert(authContractWasmId != null);
      await extendContractCodeFootprintTTL(authContractWasmId!, 100000);
    });

    test('test create auth contract', () async {
      await Future.delayed(Duration(seconds: 5));
      assert(authContractWasmId != null);

      // reload account for current sequence nr
      Account? account = await sorobanServer.getAccount(submitterId);
      assert(account != null);
      Account submitter = account!;

      /*CreateContractHostFunction function = CreateContractHostFunction(
          Address.forAccountId(submitterId), authContractWasmId!);*/
      CreateContractWithConstructorHostFunction function =
          CreateContractWithConstructorHostFunction(
              Address.forAccountId(submitterId), authContractWasmId!, []);
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(function).build();

      // build the transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(!simulateResponse.isErrorResponse);
      assert(simulateResponse.resultError == null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.setSorobanAuth(simulateResponse.sorobanAuth);
      transaction.sign(submitterKeypair, network);

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(!sendResponse.isErrorResponse);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      GetTransactionResponse rpcTransactionResponse =
          await pollStatus(sendResponse.hash!);
      authContractId = rpcTransactionResponse.getCreatedContractId();
      assert(authContractId != null);
    });

    test('test restore footprint', () async {
      await restoreContractFootprint(authContractPath);
    });

    test('test invoke auth account', () async {
      // submitter and invoker use are NOT the same
      // we need to sign auth
      assert(authContractId != null);

      // reload account for sequence number
      Account? account = await sorobanServer.getAccount(submitterId);
      assert(account != null);
      Account submitter = account!;

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "increment";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          authContractId!, functionName,
          arguments: args);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(hostFunction).build();

      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);

      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      // sign auth
      List<SorobanAuthorizationEntry>? auth = simulateResponse.sorobanAuth;
      assert(auth != null);
      GetLatestLedgerResponse latestLedgerResponse =
          await sorobanServer.getLatestLedger();
      for (SorobanAuthorizationEntry a in auth!) {
        // update signature expiration ledger
        a.credentials.addressCredentials!.signatureExpirationLedger =
            latestLedgerResponse.sequence! + 10;
        // sign
        a.sign(invokerKeypair, network);
      }
      transaction.setSorobanAuth(auth);
      transaction.sign(submitterKeypair, network);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();

      print("TX ENVELOPE: " + transactionEnvelopeXdr);
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send the transaction
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.hash != null);
      assert(sendResponse.status != null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      GetTransactionResponse rpcTransactionResponse =
          await pollStatus(sendResponse.hash!);
      String status = rpcTransactionResponse.status!;
      assert(status == GetTransactionResponse.STATUS_SUCCESS);

      XdrSCVal result = rpcTransactionResponse.getResultValue()!;
      assert(result.u32 != null);
      print("Result: " + result.u32!.uint32.toString());

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      if (transactionResponse.resultMetaXdr != null) {
        XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
            transactionResponse.resultMetaXdr!);
        assert(meta.toBase64EncodedXdrString() ==
            transactionResponse.resultMetaXdr!);
      }

      // check operation response from horizon
      Page<OperationResponse> operations =
          await sdk.operations.forTransaction(sendResponse.hash!).execute();
      assert(operations.records.isNotEmpty);
      OperationResponse operationResponse = operations.records.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert("HostFunctionTypeHostFunctionTypeInvokeContract" ==
            operationResponse.function);
      } else {
        assert(false);
      }
    });

    test('test invoke auth invoker', () async {
      // submitter and invoker use are the same
      // no need to sign auth
      assert(authContractId != null);

      // load invoker account for sequence number
      Account? account = await sorobanServer.getAccount(invokerId);
      assert(account != null);
      Account invoker = account!;

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "increment";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          authContractId!, functionName,
          arguments: args);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(hostFunction).build();

      Transaction transaction =
          new TransactionBuilder(invoker).addOperation(operation).build();

      // simulate first to get transaction data
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.setSorobanAuth(simulateResponse.sorobanAuth);
      transaction.sign(invokerKeypair, network);

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

      GetTransactionResponse rpcTransactionResponse =
          await pollStatus(sendResponse.hash!);
      String status = rpcTransactionResponse.status!;
      assert(status == GetTransactionResponse.STATUS_SUCCESS);

      XdrSCVal result = rpcTransactionResponse.getResultValue()!;
      assert(result.u32 != null);
      print("Result: " + result.u32!.uint32.toString());
    });
  });
}
