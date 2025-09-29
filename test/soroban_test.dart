import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';

  SorobanServer sorobanServer = testOn == 'testnet'
      ? SorobanServer("https://soroban-testnet.stellar.org")
      : SorobanServer("https://rpc-futurenet.stellar.org");

  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;

  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  KeyPair keyPairA = KeyPair.random();
  String accountAId = keyPairA.accountId;
  KeyPair keyPairB = KeyPair.random();
  String accountBId = keyPairB.accountId;
  Asset assetFsdk = AssetTypeCreditAlphaNum4("Fsdk", accountBId);

  String helloContractPath = "test/wasm/soroban_hello_world_contract.wasm";
  String? helloContractWasmId;
  String? helloContractId;
  Footprint? helloContractCreateFootprint;

  String eventsContractPath = "test/wasm/soroban_events_contract.wasm";

  Uint8List? helloContractCode;

  setUp(() async {
    sorobanServer.enableLogging = true;
    try {
      await sdk.accounts.account(accountAId);
    } catch (e) {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(accountAId);
      } else if (testOn == 'futurenet') {
        await FuturenetFriendBot.fundTestAccount(accountAId);
      }

      await Future.delayed(const Duration(seconds: 3), () {});
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
    Account? account = await sorobanServer.getAccount(accountAId);
    assert(account != null);
    Account accountA = account!;

    // load contract wasm file
    Uint8List contractCode = await Util.readFile(contractCodePath);

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

    account = await sorobanServer.getAccount(accountAId);
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
    transaction.addResourceFee(simulateResponse.minResourceFee! + 5000);
    transaction.sign(keyPairA, network);

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

    // test operation & effects responses can be parsed
    var operationsPage = await sdk.operations.forAccount(accountAId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(accountAId).execute();
    assert(effectsPage.records.isNotEmpty);
  }

  Future extendContractCodeFootprintTTL(String wasmId, int extendTo) async {
    await Future.delayed(Duration(seconds: 5));

    // load account
    Account? account = await sorobanServer.getAccount(accountAId);
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
        XdrSorobanTransactionData(XdrSorobanTransactionDataExt(0), resources, XdrInt64(0));

    transaction.sorobanTransactionData = transactionData;

    // simulate first to obtain the transaction data + resource fee
    var resourceConfig = new ResourceConfig(300000);
    var request = new SimulateTransactionRequest(transaction,
        resourceConfig: resourceConfig);
    SimulateTransactionResponse simulateResponse =
        await sorobanServer.simulateTransaction(request);
    assert(simulateResponse.error == null);
    // assert(simulateResponse.results != null);
    assert(simulateResponse.resultError == null);
    assert(simulateResponse.transactionData != null);

    account = await sorobanServer.getAccount(accountAId);
    assert(account != null);
    accountA = account!;

    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(keyPairA, network);

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

    // print("Transaction hash: " + sendResponse.hash!);
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

    var effectsPage = await sdk.effects.forAccount(accountAId).execute();
    assert(effectsPage.records.isNotEmpty);
  }

  group('all tests', () {
    test('test server health ', () async {
      GetHealthResponse healthResponse = await sorobanServer.getHealth();
      assert(GetHealthResponse.HEALTHY == healthResponse.status);
      assert(healthResponse.ledgerRetentionWindow != null);
      assert(healthResponse.latestLedger != null);
      assert(healthResponse.oldestLedger != null);
    });

    test('test server version info ', () async {
      var response = await sorobanServer.getVersionInfo();
      assert(response.version != null);
      assert(response.commitHash != null);
      assert(response.buildTimeStamp != null);
      assert(response.captiveCoreVersion != null);
      assert(response.protocolVersion != null);
    });

    test('test server fee stats ', () async {
      var response = await sorobanServer.getFeeStats();
      assert(response.sorobanInclusionFee != null);
      assert(response.inclusionFee != null);
      assert(response.latestLedger != null);
    });

    test('test network request', () async {
      GetNetworkResponse networkResponse = await sorobanServer.getNetwork();

      assert(!networkResponse.isErrorResponse);
      if (testOn == 'testnet') {
        assert(
            "https://friendbot.stellar.org/" == networkResponse.friendbotUrl);
        assert(
            "Test SDF Network ; September 2015" == networkResponse.passphrase);
      } else if (testOn == 'futurenet') {
        assert("https://friendbot-futurenet.stellar.org/" ==
            networkResponse.friendbotUrl);
        assert("Test SDF Future Network ; October 2022" ==
            networkResponse.passphrase);
      }
    });

    test('test get latest ledger', () async {
      GetLatestLedgerResponse latestLedgerResponse =
          await sorobanServer.getLatestLedger();

      assert(!latestLedgerResponse.isErrorResponse);
      assert(latestLedgerResponse.id != null);
      assert(latestLedgerResponse.protocolVersion != null);
      assert(latestLedgerResponse.sequence != null);
    });

    test('test server get transactions ', () async {
      var latestLedgerResponse = await sorobanServer.getLatestLedger();
      assert(latestLedgerResponse.sequence != null);

      var startLedger = latestLedgerResponse.sequence! - 200;
      var paginationOptions = PaginationOptions(limit: 2);
      var request = GetTransactionsRequest(
        startLedger: startLedger,
        paginationOptions: paginationOptions,
      );
      var response = await sorobanServer.getTransactions(request);
      assert(!response.isErrorResponse);
      assert(response.transactions != null);
      assert(response.latestLedger != null);
      assert(response.oldestLedger != null);
      assert(response.oldestLedgerCloseTimestamp != null);
      assert(response.cursor != null);
      var transactions = response.transactions!;
      assert(transactions.isNotEmpty);

      paginationOptions = PaginationOptions(cursor: response.cursor!, limit: 2);
      request = GetTransactionsRequest(paginationOptions: paginationOptions);
      response = await sorobanServer.getTransactions(request);
      assert(!response.isErrorResponse);
      assert(response.transactions != null);
      transactions = response.transactions!;
      assert(transactions.length == 2);
    });

    test('test upload contract', () async {
      await Future.delayed(Duration(seconds: 5));
      // load account
      //AccountResponse accountA = await sdk.accounts.account(accountAId);
      Account? account = await sorobanServer.getAccount(accountAId);
      assert(account != null);
      Account accountA = account!;

      // load contract wasm file
      helloContractCode = await Util.readFile(helloContractPath);

      UploadContractWasmHostFunction uploadFunction =
          UploadContractWasmHostFunction(helloContractCode!);
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(uploadFunction).build();
      // create transaction for installing the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, network);

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
      if (rpcTransactionResponse.status ==
          GetTransactionResponse.STATUS_SUCCESS) {
        helloContractWasmId = rpcTransactionResponse.getWasmId();
      }

      assert(helloContractWasmId != null);

      await Future.delayed(Duration(seconds: 5));
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
        assert("HostFunctionTypeHostFunctionTypeUploadContractWasm" ==
            operationResponse.function);
      } else {
        assert(false);
      }
      await extendContractCodeFootprintTTL(helloContractWasmId!, 100000);

      var effectsPage = await sdk.effects.forAccount(accountAId).execute();
      assert(effectsPage.records.isNotEmpty);

      var contractInfo = await sorobanServer.loadContractInfoForWasmId(helloContractWasmId!);
      assert(contractInfo != null);
      assert(contractInfo!.specEntries.length > 0);
      assert(contractInfo!.metaEntries.length > 0);
    });

    test('test create contract', () async {
      await Future.delayed(Duration(seconds: 5));
      assert(helloContractWasmId != null);

      // reload account for current sequence nr
      Account? account = await sorobanServer.getAccount(accountAId);
      assert(account != null);
      Account accountA = account!;

      CreateContractHostFunction function = CreateContractHostFunction(
          Address.forAccountId(accountAId), helloContractWasmId!);
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(function).build();
      // create transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      helloContractCreateFootprint = simulateResponse.footprint;

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.setSorobanAuth(simulateResponse.sorobanAuth);
      transaction.sign(keyPairA, network);

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
      if (rpcTransactionResponse.status ==
          GetTransactionResponse.STATUS_SUCCESS) {
        helloContractId = rpcTransactionResponse.getCreatedContractId();
      }
      assert(helloContractId != null);

      await Future.delayed(Duration(seconds: 5));
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
        assert("HostFunctionTypeHostFunctionTypeCreateContract" ==
            operationResponse.function);
      } else {
        assert(false);
      }

      var effectsPage = await sdk.effects.forAccount(accountAId).execute();
      assert(effectsPage.records.isNotEmpty);

      var contractInfo = await sorobanServer.loadContractInfoForContractId(helloContractId!);
      assert(contractInfo != null);
      assert(contractInfo!.specEntries.length > 0);
      assert(contractInfo!.metaEntries.length > 0);
    });

    test('test restore footprint', () async {
      await restoreContractFootprint(helloContractPath);
      await restoreContractFootprint(eventsContractPath);
    });

    test('test invoke contract', () async {
      await Future.delayed(Duration(seconds: 5));
      assert(helloContractId != null);

      // load account for sequence number
      Account? account = await sorobanServer.getAccount(accountAId);
      assert(account != null);
      Account accountA = account!;

      // prepare argument
      XdrSCVal arg = XdrSCVal.forSymbol("friend");

      String functionName = "hello";
      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          helloContractId!, functionName,
          arguments: [arg]);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(hostFunction).build();

      // create transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, network);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
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
      if (rpcTransactionResponse.status ==
          GetTransactionResponse.STATUS_SUCCESS) {
        XdrSCVal resVal = rpcTransactionResponse.getResultValue()!;

        assert(resVal.vec!.length == 2);
        assert(resVal.vec![0].sym == "Hello");
        assert(resVal.vec![1].sym == "friend");
        print(resVal.vec![0].sym! + " " + resVal.vec![1].sym!);

        // user friendly
        XdrSCVal? resValO = rpcTransactionResponse.getResultValue();
        List<XdrSCVal>? vec = resValO?.vec;
        if (vec != null && vec.length > 1) {
          print("[${vec[0].sym} , ${vec[1].sym}]");
        }
      }

      await Future.delayed(Duration(seconds: 5));

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

      var effectsPage = await sdk.effects.forAccount(accountAId).execute();
      assert(effectsPage.records.isNotEmpty);

      await Future.delayed(Duration(seconds: 5));
      // test contract data fetching
      print(StrKey.encodeContractIdHex(helloContractId!));
      LedgerEntry? entry = await sorobanServer.getContractData(
          helloContractId!,
          XdrSCVal.forLedgerKeyContractInstance(),
          XdrContractDataDurability.PERSISTENT);
      assert(entry != null);
    });

    test('test events', () async {
      await Future.delayed(Duration(seconds: 5));
      // Install contract
      Account? account = await sorobanServer.getAccount(accountAId);
      assert(account != null);
      Account submitter = account!;

      Uint8List contractCode = await Util.readFile(eventsContractPath);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(UploadContractWasmHostFunction(contractCode))
              .build();
      // create transaction for installing the contract
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      var request = new SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, network);

      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      String? eventsContractWasmId;
      GetTransactionResponse rpcTransactionResponse =
          await pollStatus(sendResponse.hash!);
      if (rpcTransactionResponse.status ==
          GetTransactionResponse.STATUS_SUCCESS) {
        eventsContractWasmId = rpcTransactionResponse.getWasmId();
      }

      assert(eventsContractWasmId != null);
      String wasmId = eventsContractWasmId!;

      await Future.delayed(Duration(seconds: 5));

      // Create contract
      account = await sorobanServer.getAccount(accountAId);
      assert(account != null);
      submitter = account!;

      operation = InvokeHostFuncOpBuilder(CreateContractHostFunction(
              Address.forAccountId(accountAId), wasmId))
          .build();
      // create transaction for creating the contract
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      request = SimulateTransactionRequest(transaction);
      simulateResponse = await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.setSorobanAuth(simulateResponse.sorobanAuth);
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, network);

      sendResponse = await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      String? eventsContractId;
      rpcTransactionResponse = await pollStatus(sendResponse.hash!);
      if (rpcTransactionResponse.status ==
          GetTransactionResponse.STATUS_SUCCESS) {
        eventsContractId = rpcTransactionResponse.getCreatedContractId();
      }
      assert(eventsContractId != null);
      String contractId = eventsContractId!;

      await Future.delayed(Duration(seconds: 5));
      // Invoke contract
      account = await sorobanServer.getAccount(accountAId);
      assert(account != null);
      submitter = account!;

      String functionName = "increment";
      InvokeContractHostFunction hostFunction =
          InvokeContractHostFunction(contractId, functionName);

      operation = InvokeHostFuncOpBuilder(hostFunction).build();

      // create transaction for creating the contract
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      request = SimulateTransactionRequest(transaction);
      simulateResponse = await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, network);

      sendResponse = await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      await pollStatus(sendResponse.hash!);

      await Future.delayed(Duration(seconds: 5));
      // query events
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      int startLedger = transactionResponse.ledger;

      // seams that position of the topic in the filter must match event topics ...
      TopicFilter topicFilter = TopicFilter(
          ["*", XdrSCVal.forSymbol('increment').toBase64EncodedXdrString()]);

      // TopicFilter topicFilter = TopicFilter(
      //    [XdrSCVal.forSymbol('COUNTER').toBase64EncodedXdrString(), "*"]);

      EventFilter eventFilter = EventFilter(
          type: "contract",
          contractIds: [StrKey.encodeContractIdHex(contractId)],
          topics: [topicFilter]);
      var paginationOptions = PaginationOptions(limit: 2);
      GetEventsRequest eventsRequest = GetEventsRequest(startLedger:startLedger,
          endLedger: startLedger + 5,
          filters: [eventFilter], paginationOptions: paginationOptions);
      GetEventsResponse eventsResponse =
          await sorobanServer.getEvents(eventsRequest);
      assert(!eventsResponse.isErrorResponse);
      assert(eventsResponse.events != null);
      assert(eventsResponse.events!.length > 0);

      await extendContractCodeFootprintTTL(eventsContractWasmId, 100000);

      var contractInfo = await sorobanServer.loadContractInfoForContractId(eventsContractId);
      assert(contractInfo != null);
      assert(contractInfo!.specEntries.length > 0);
      assert(contractInfo!.metaEntries.length > 0);
    });

    test('test get ledger entries', () async {
      assert(helloContractCreateFootprint != null);
      String? contractCodeKey =
          helloContractCreateFootprint!.getContractCodeLedgerKey();
      assert(contractCodeKey != null);
      String? contractDataKey =
          helloContractCreateFootprint!.getContractDataLedgerKey();
      assert(contractDataKey != null);

      GetLedgerEntriesResponse contractCodeEntries =
          await sorobanServer.getLedgerEntries([contractCodeKey!]);
      assert(contractCodeEntries.latestLedger != null);
      assert(contractCodeEntries.entries != null);
      assert(contractCodeEntries.entries!.length == 1);

      GetLedgerEntriesResponse contractDataEntries =
          await sorobanServer.getLedgerEntries([contractDataKey!]);
      assert(contractDataEntries.latestLedger != null);
      assert(contractDataEntries.entries != null);
      assert(contractDataEntries.entries!.length == 1);

      XdrContractCodeEntry? cCodeEntry =
          await sorobanServer.loadContractCodeForWasmId(helloContractWasmId!);
      assert(cCodeEntry != null);
      assert(base64Encode(cCodeEntry!.code.dataValue) ==
          base64Encode(helloContractCode!));

      cCodeEntry =
          await sorobanServer.loadContractCodeForContractId(helloContractId!);
      assert(cCodeEntry != null);
      assert(base64Encode(cCodeEntry!.code.dataValue) ==
          base64Encode(helloContractCode!));
    });

    test('test deploy SAC with source account', () async {
      await Future.delayed(Duration(seconds: 5));
      // load account
      Account? account = await sorobanServer.getAccount(accountAId);
      assert(account != null);
      Account accountA = account!;

      InvokeHostFunctionOperation operation = InvokeHostFuncOpBuilder(
              DeploySACWithSourceAccountHostFunction(
                  Address.forAccountId(accountAId)))
          .build();
      // create transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      if (testOn == 'futurenet') {
        assert(simulateResponse.stateChanges != null);
        var stateChange = simulateResponse.stateChanges!.first;
        assert(stateChange.after != null);
      }

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.setSorobanAuth(simulateResponse.sorobanAuth);
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, network);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      await pollStatus(sendResponse.hash!);

      await Future.delayed(Duration(seconds: 5));
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
        assert("HostFunctionTypeHostFunctionTypeCreateContract" ==
            operationResponse.function);
      } else {
        assert(false);
      }

      var effectsPage = await sdk.effects.forAccount(accountAId).execute();
      assert(effectsPage.records.isNotEmpty);
    });

    test('test SAC with asset', () async {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(accountBId);
      } else if (testOn == 'futurenet') {
        await FuturenetFriendBot.fundTestAccount(accountBId);
      }
      await Future.delayed(Duration(seconds: 5));

      // prepare trustline
      Account? account = await sorobanServer.getAccount(accountBId);
      assert(account != null);
      Account sourceAccount = account!;

      ChangeTrustOperationBuilder ctOp =
          ChangeTrustOperationBuilder(assetFsdk, "1000000");
      ctOp.setSourceAccount(accountAId);
      PaymentOperationBuilder pOp =
          PaymentOperationBuilder(accountAId, assetFsdk, "200");

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(ctOp.build())
          .addOperation(pOp.build())
          .build();
      transaction.sign(keyPairA, network);
      transaction.sign(keyPairB, network);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);

      // load account
      account = await sorobanServer.getAccount(accountBId);
      assert(account != null);
      Account accountB = account!;

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(DeploySACWithAssetHostFunction(assetFsdk))
              .build();
      // create transaction for creating the contract
      transaction =
          new TransactionBuilder(accountB).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      var request = SimulateTransactionRequest(transaction);
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(request);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.setSorobanAuth(simulateResponse.sorobanAuth);
      transaction.sign(keyPairB, network);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      await pollStatus(sendResponse.hash!);

      await Future.delayed(Duration(seconds: 5));
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
        assert("HostFunctionTypeHostFunctionTypeCreateContract" ==
            operationResponse.function);
      } else {
        assert(false);
      }

      var effectsPage = await sdk.effects.forAccount(accountAId).execute();
      assert(effectsPage.records.isNotEmpty);
    });

    test('test StrKey contractId', () async {
      String contractIdA =
          "86efd9a9d6fbf70297294772c9676127e16a23c2141cab3e29be836bb537a9b9";
      String strEncodedA =
          "CCDO7WNJ2357OAUXFFDXFSLHMET6C2RDYIKBZKZ6FG7IG25VG6U3SLHT";
      String strEncodedB = StrKey.encodeContractIdHex(contractIdA);
      assert(strEncodedA == strEncodedB);

      assert(strEncodedA == strEncodedB);
      String contractIdB = StrKey.decodeContractIdHex(strEncodedB);
      assert(contractIdA == contractIdB);

      String strEncodedC =
          StrKey.encodeContractId(Util.hexToBytes(contractIdA));
      assert(strEncodedA == strEncodedC);
      assert(
          contractIdA == Util.bytesToHex(StrKey.decodeContractId(strEncodedC)));
    });

    ///
    test('test tx events parsing', () async {
      final body = "{  \"jsonrpc\": \"2.0\",  \"id\": 8675309,  \"result\": {    \"latestLedger\": 1317536,    \"latestLedgerCloseTime\": \"1748999063\",    \"oldestLedger\": 1297535,    \"oldestLedgerCloseTime\": \"1748898975\",    \"status\": \"SUCCESS\",    \"txHash\": \"2e29cacfc90565027c44bb9477f58af7c179309b5234d6742cd7e7301fcd847f\",    \"applicationOrder\": 1,    \"feeBump\": false,    \"envelopeXdr\": \"AAAAAgAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQBY644AEETyAAAOngAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAA1jcmVhdGVfZXNjcm93AAAAAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAegAAAAAAAAAAQAAAAAAAAACAAAABgAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAABQAAAABAAAABw92WUOXbPOCn5SPHsgIOq8K1UypMpJe18Eh5s6eH8KeAAAAAQAAAAYAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAAQAAAAAQAAAAIAAAAPAAAABVN0YXRlAAAAAAAABQAAAAAABpGZAAAAAQA1p5gAAEC0AAABuAAAAAAAWOsqAAAAAcVTVrkAAABAkR3EyCbHmZqEzQ1hvb1u2zY8PMqfhm7Z8zULGlpdNV0rWSbchA/NDudYEYrQKdA0qy647T+ojtdMfwLrfHELCA==\",    \"resultXdr\": \"AAAAAABM5iEAAAAAAAAAAQAAAAAAAAAYAAAAANkPSp3CD6fXFropzD1Dse4sGrxEO/NPfv6SvhMR1kNkAAAAAA==\",    \"resultMetaXdr\": \"AAAABAAAAAAAAAACAAAAAwAT44AAAAAAAAAAAO17mcmt6Emr+m7eqVX9sBJFI6IlVd00L6BBb+fFU1a5AAAAFCYiTnMAEETyAAAOnQAAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAMAAAAAABPjfwAAAABoPoe3AAAAAAAAAAEAE+OAAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAABQmIk5zABBE8gAADp4AAAABAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAADAAAAAAAT44AAAAAAaD6HvAAAAAAAAAABAAAAAAAAAAIAAAAAABPjgAAAAAm7BMApSYoASMZ2qaMBnGEMDyvtMCQCXaAg5KcoiQAt+QAzh38AAAAAAAAAAAAT44AAAAAGAAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAABAAAAABAAAAAgAAAA8AAAAFU3RhdGUAAAAAAAAFAAAAAAAGkZkAAAABAAAAEQAAAAEAAAAHAAAADwAAAAZhbW91bnQAAAAAAAoAAAAAAAAAAAAAAAAAAAAAAAAADwAAAAphcmJpdHJhdG9yAAAAAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAAA8AAAAFYXNzZXQAAAAAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHoAAAADwAAAAVidXllcgAAAAAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAADwAAAAlmaW5hbGl6ZWQAAAAAAAAAAAAAAAAAAA8AAAAGc2VsbGVyAAAAAAASAAAAAAAAAADJ7DBeTuWqnGJA1g/dWVnUQSms0r51IFXgpD2KW7BvHwAAAA8AAAAFdm90ZXMAAAAAAAARAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAABAAAAAAAAAAEAAAAPAAAABGluaXQAAAAQAAAAAQAAAAUAAAAFAAAAAAAGkZkAAAASAAAAAAAAAAAnDGNhr4xd4oCt9ulsolPIb9dO6fWMbwEtvYLdX5pdlgAAABIAAAAAAAAAAMnsMF5O5aqcYkDWD91ZWdRBKazSvnUgVeCkPYpbsG8fAAAAEgAAAAAAAAAAGNkZtSF153RCNK2INm7df68NpotUmDlE9qnij73+enIAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHoAAAAAgAAAAMAE+OAAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAABQmIk5zABBE8gAADp4AAAABAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAADAAAAAAAT44AAAAAAaD6HvAAAAAAAAAABABPjgAAAAAAAAAAA7XuZya3oSav6bt6pVf2wEkUjoiVV3TQvoEFv58VTVrkAAAAUJi5T4AAQRPIAAA6eAAAAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAwAAAAAAE+OAAAAAAGg+h7wAAAAAAAAAAQAAAAEAAAAAAAAAAAABUswAAAAAAEuS8QAAAAAAS4jeAAAAAQAAAAEAAAACAAAAAAAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAoAAAAAAAAAAAAAAAAAWOuOAAAAAQAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAr/////////////////8/qTAAAAFgAAAAEAAAAAAAAAAAAAAAIAAAAAAAAAAwAAAA8AAAAHZm5fY2FsbAAAAAANAAAAIN/rkbbh3K3Wr5e7fEVfl/N0dwp/ePaVc7mfXVv4Sc58AAAADwAAAA1jcmVhdGVfZXNjcm93AAAAAAAAEAAAAAEAAAAFAAAABQAAAAAABpGZAAAAEgAAAAAAAAAAJwxjYa+MXeKArfbpbKJTyG/XTun1jG8BLb2C3V+aXZYAAAASAAAAAAAAAADJ7DBeTuWqnGJA1g/dWVnUQSms0r51IFXgpD2KW7BvHwAAABIAAAAAAAAAABjZGbUhded0QjStiDZu3X+vDaaLVJg5RPap4o+9/npyAAAAEgAAAAG6wrOLOBdGxRYolBGulYcBYb/K6NDosFP+kwOWMSIB6AAAAAEAAAAAAAAAAd/rkbbh3K3Wr5e7fEVfl/N0dwp/ePaVc7mfXVv4Sc58AAAAAQAAAAAAAAABAAAADwAAAARpbml0AAAAEAAAAAEAAAAFAAAABQAAAAAABpGZAAAAEgAAAAAAAAAAJwxjYa+MXeKArfbpbKJTyG/XTun1jG8BLb2C3V+aXZYAAAASAAAAAAAAAADJ7DBeTuWqnGJA1g/dWVnUQSms0r51IFXgpD2KW7BvHwAAABIAAAAAAAAAABjZGbUhded0QjStiDZu3X+vDaaLVJg5RPap4o+9/npyAAAAEgAAAAG6wrOLOBdGxRYolBGulYcBYb/K6NDosFP+kwOWMSIB6AAAAAEAAAAAAAAAAd/rkbbh3K3Wr5e7fEVfl/N0dwp/ePaVc7mfXVv4Sc58AAAAAgAAAAAAAAACAAAADwAAAAlmbl9yZXR1cm4AAAAAAAAPAAAADWNyZWF0ZV9lc2Nyb3cAAAAAAAABAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACnJlYWRfZW50cnkAAAAAAAUAAAAAAAAAAwAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAAAt3cml0ZV9lbnRyeQAAAAAFAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAPAAAADGNvcmVfbWV0cmljcwAAAA8AAAAQbGVkZ2VyX3JlYWRfYnl0ZQAAAAUAAAAAAABAtAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAABFsZWRnZXJfd3JpdGVfYnl0ZQAAAAAAAAUAAAAAAAABuAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAAA1yZWFkX2tleV9ieXRlAAAAAAAABQAAAAAAAACoAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADndyaXRlX2tleV9ieXRlAAAAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAPAAAADGNvcmVfbWV0cmljcwAAAA8AAAAOcmVhZF9kYXRhX2J5dGUAAAAAAAUAAAAAAAAAaAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAAA93cml0ZV9kYXRhX2J5dGUAAAAABQAAAAAAAAG4AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfY29kZV9ieXRlAAAAAAAFAAAAAAAAQEwAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAPAAAADGNvcmVfbWV0cmljcwAAAA8AAAAPd3JpdGVfY29kZV9ieXRlAAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAAAplbWl0X2V2ZW50AAAAAAAFAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAPAAAADGNvcmVfbWV0cmljcwAAAA8AAAAPZW1pdF9ldmVudF9ieXRlAAAAAAUAAAAAAAABBAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAAAhjcHVfaW5zbgAAAAUAAAAAADNgQgAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAAAhtZW1fYnl0ZQAAAAUAAAAAABsHqwAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAABFpbnZva2VfdGltZV9uc2VjcwAAAAAAAAUAAAAAAAg/fQAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAAA9tYXhfcndfa2V5X2J5dGUAAAAABQAAAAAAAABUAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19kYXRhX2J5dGUAAAAFAAAAAAAAAbgAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAIAAAAPAAAADGNvcmVfbWV0cmljcwAAAA8AAAAQbWF4X3J3X2NvZGVfYnl0ZQAAAAUAAAAAAABATAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAgAAAA8AAAAMY29yZV9tZXRyaWNzAAAADwAAABNtYXhfZW1pdF9ldmVudF9ieXRlAAAAAAUAAAAAAAABBA==\",    \"diagnosticEventsXdr\": [      \"AAAAAQAAAAAAAAAAAAAAAgAAAAAAAAADAAAADwAAAAdmbl9jYWxsAAAAAA0AAAAg3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAAPAAAADWNyZWF0ZV9lc2Nyb3cAAAAAAAAQAAAAAQAAAAUAAAAFAAAAAAAGkZkAAAASAAAAAAAAAAAnDGNhr4xd4oCt9ulsolPIb9dO6fWMbwEtvYLdX5pdlgAAABIAAAAAAAAAAMnsMF5O5aqcYkDWD91ZWdRBKazSvnUgVeCkPYpbsG8fAAAAEgAAAAAAAAAAGNkZtSF153RCNK2INm7df68NpotUmDlE9qnij73+enIAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHo\",      \"AAAAAQAAAAAAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAABAAAAAAAAAAEAAAAPAAAABGluaXQAAAAQAAAAAQAAAAUAAAAFAAAAAAAGkZkAAAASAAAAAAAAAAAnDGNhr4xd4oCt9ulsolPIb9dO6fWMbwEtvYLdX5pdlgAAABIAAAAAAAAAAMnsMF5O5aqcYkDWD91ZWdRBKazSvnUgVeCkPYpbsG8fAAAAEgAAAAAAAAAAGNkZtSF153RCNK2INm7df68NpotUmDlE9qnij73+enIAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHo\",      \"AAAAAQAAAAAAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAACAAAAAAAAAAIAAAAPAAAACWZuX3JldHVybgAAAAAAAA8AAAANY3JlYXRlX2VzY3JvdwAAAAAAAAE=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACnJlYWRfZW50cnkAAAAAAAUAAAAAAAAAAw==\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAC3dyaXRlX2VudHJ5AAAAAAUAAAAAAAAAAQ==\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEGxlZGdlcl9yZWFkX2J5dGUAAAAFAAAAAAAAQLQ=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWxlZGdlcl93cml0ZV9ieXRlAAAAAAAABQAAAAAAAAG4\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADXJlYWRfa2V5X2J5dGUAAAAAAAAFAAAAAAAAAKg=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADndyaXRlX2tleV9ieXRlAAAAAAAFAAAAAAAAAAA=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfZGF0YV9ieXRlAAAAAAAFAAAAAAAAAGg=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2RhdGFfYnl0ZQAAAAAFAAAAAAAAAbg=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfY29kZV9ieXRlAAAAAAAFAAAAAAAAQEw=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2NvZGVfYnl0ZQAAAAAFAAAAAAAAAAA=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACmVtaXRfZXZlbnQAAAAAAAUAAAAAAAAAAQ==\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD2VtaXRfZXZlbnRfYnl0ZQAAAAAFAAAAAAAAAQQ=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACGNwdV9pbnNuAAAABQAAAAAAM2BC\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACG1lbV9ieXRlAAAABQAAAAAAGwer\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWludm9rZV90aW1lX25zZWNzAAAAAAAABQAAAAAACD99\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD21heF9yd19rZXlfYnl0ZQAAAAAFAAAAAAAAAFQ=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19kYXRhX2J5dGUAAAAFAAAAAAAAAbg=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19jb2RlX2J5dGUAAAAFAAAAAAAAQEw=\",      \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAE21heF9lbWl0X2V2ZW50X2J5dGUAAAAABQAAAAAAAAEE\",      \"AAAAAQAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAoAAAAAAAAAAAAAAAAAWOuO\",      \"AAAAAQAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAr/////////////////8/qT\"    ],    \"events\": {      \"diagnosticEventsXdr\": [        \"AAAAAQAAAAAAAAAAAAAAAgAAAAAAAAADAAAADwAAAAdmbl9jYWxsAAAAAA0AAAAg3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAAPAAAADWNyZWF0ZV9lc2Nyb3cAAAAAAAAQAAAAAQAAAAUAAAAFAAAAAAAGkZkAAAASAAAAAAAAAAAnDGNhr4xd4oCt9ulsolPIb9dO6fWMbwEtvYLdX5pdlgAAABIAAAAAAAAAAMnsMF5O5aqcYkDWD91ZWdRBKazSvnUgVeCkPYpbsG8fAAAAEgAAAAAAAAAAGNkZtSF153RCNK2INm7df68NpotUmDlE9qnij73+enIAAAASAAAAAbrCs4s4F0bFFiiUEa6VhwFhv8ro0OiwU/6TA5YxIgHo\",        \"AAAAAQAAAAAAAAAB3+uRtuHcrdavl7t8RV+X83R3Cn949pVzuZ9dW/hJznwAAAACAAAAAAAAAAIAAAAPAAAACWZuX3JldHVybgAAAAAAAA8AAAANY3JlYXRlX2VzY3JvdwAAAAAAAAE=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACnJlYWRfZW50cnkAAAAAAAUAAAAAAAAAAw==\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAC3dyaXRlX2VudHJ5AAAAAAUAAAAAAAAAAQ==\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEGxlZGdlcl9yZWFkX2J5dGUAAAAFAAAAAAAAQLQ=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWxlZGdlcl93cml0ZV9ieXRlAAAAAAAABQAAAAAAAAG4\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADXJlYWRfa2V5X2J5dGUAAAAAAAAFAAAAAAAAAKg=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADndyaXRlX2tleV9ieXRlAAAAAAAFAAAAAAAAAAA=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfZGF0YV9ieXRlAAAAAAAFAAAAAAAAAGg=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2RhdGFfYnl0ZQAAAAAFAAAAAAAAAbg=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAADnJlYWRfY29kZV9ieXRlAAAAAAAFAAAAAAAAQEw=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD3dyaXRlX2NvZGVfYnl0ZQAAAAAFAAAAAAAAAAA=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACmVtaXRfZXZlbnQAAAAAAAUAAAAAAAAAAQ==\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD2VtaXRfZXZlbnRfYnl0ZQAAAAAFAAAAAAAAAQQ=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACGNwdV9pbnNuAAAABQAAAAAAM2BC\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAACG1lbV9ieXRlAAAABQAAAAAAGwer\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEWludm9rZV90aW1lX25zZWNzAAAAAAAABQAAAAAACD99\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAD21heF9yd19rZXlfYnl0ZQAAAAAFAAAAAAAAAFQ=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19kYXRhX2J5dGUAAAAFAAAAAAAAAbg=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAEG1heF9yd19jb2RlX2J5dGUAAAAFAAAAAAAAQEw=\",        \"AAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAADwAAAAxjb3JlX21ldHJpY3MAAAAPAAAAE21heF9lbWl0X2V2ZW50X2J5dGUAAAAABQAAAAAAAAEE\"      ],      \"transactionEventsXdr\": [        \"AAAAAAAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAoAAAAAAAAAAAAAAAAAWOuO\",        \"AAAAAQAAAAAAAAAB15KLcsJwPM/q9+uf9O9NUEpVqLl5/JtFDqLIQrTRzmEAAAABAAAAAAAAAAIAAAAPAAAAA2ZlZQAAAAASAAAAAAAAAADte5nJrehJq/pu3qlV/bASRSOiJVXdNC+gQW/nxVNWuQAAAAr/////////////////8/qT\"      ],      \"contractEventsXdr\": [        [          \"AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg=\",           \"AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg=\"        ],        [          \"AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg=\",           \"AAAAAAAAAAHf65G24dyt1q+Xu3xFX5fzdHcKf3j2lXO5n11b+EnOfAAAAAEAAAAAAAAAAQAAAA8AAAAEaW5pdAAAABAAAAABAAAABQAAAAUAAAAAAAaRmQAAABIAAAAAAAAAACcMY2GvjF3igK326WyiU8hv107p9YxvAS29gt1fml2WAAAAEgAAAAAAAAAAyewwXk7lqpxiQNYP3VlZ1EEprNK+dSBV4KQ9iluwbx8AAAASAAAAAAAAAAAY2Rm1IXXndEI0rYg2bt1/rw2mi1SYOUT2qeKPvf56cgAAABIAAAABusKzizgXRsUWKJQRrpWHAWG/yujQ6LBT/pMDljEiAeg=\"        ]      ]    },    \"ledger\": 1303424,    \"createdAt\": \"1748928444\"  }}";
      Map<String, dynamic>? res = json.decode(body);
      final txResponse = GetTransactionResponse.fromJson(res!);
      assert(21 == txResponse.events?.diagnosticEventsXdr?.length);
      assert(2 == txResponse.events?.transactionEventsXdr?.length);
      assert(2 == txResponse.events?.contractEventsXdr?.length);
      assert(2 == txResponse.events?.contractEventsXdr?[0].length);

      for (final eventXdrStr in txResponse.events!.diagnosticEventsXdr!) {
        XdrDiagnosticEvent.fromBase64EncodedXdrString(eventXdrStr);
      }
      for (final eventXdrStr in txResponse.events!.transactionEventsXdr!) {
        XdrTransactionEvent.fromBase64EncodedXdrString(eventXdrStr);
      }
      for (final eventsList in txResponse.events!.contractEventsXdr!) {
        for (final eventXdrStr in eventsList) {
          XdrContractEvent.fromBase64EncodedXdrString(eventXdrStr);
        }
      }
    });
  });
}
