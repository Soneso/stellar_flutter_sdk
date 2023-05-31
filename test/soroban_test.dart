import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://rpc-futurenet.stellar.org:443");

  StellarSDK sdk = StellarSDK.FUTURENET;

  KeyPair keyPairA = KeyPair.random();
  String accountAId = keyPairA.accountId;
  KeyPair keyPairB = KeyPair.random();
  String accountBId = keyPairB.accountId;
  Asset assetFsdk = AssetTypeCreditAlphaNum4("Fsdk", accountBId);

  String helloContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/hello.wasm";
  String? helloContractWasmId;
  String? helloContractId;
  Footprint? helloContractCreateFootprint;

  String eventsContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/event.wasm";

  setUp(() async {
    sorobanServer.enableLogging = true;
    sorobanServer.acknowledgeExperimental = true;
    try {
      await sdk.accounts.account(accountAId);
    } catch (e) {
      await FuturenetFriendBot.fundTestAccount(accountAId);
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

  group('all tests', () {
    test('test server health ', () async {
      GetHealthResponse healthResponse = await sorobanServer.getHealth();
      assert(GetHealthResponse.HEALTHY == healthResponse.status);
    });

    test('test network request', () async {
      GetNetworkResponse networkResponse = await sorobanServer.getNetwork();

      assert(!networkResponse.isErrorResponse);
      assert("https://friendbot-futurenet.stellar.org/" ==
          networkResponse.friendbotUrl);
      assert("Test SDF Future Network ; October 2022" ==
          networkResponse.passphrase);
    });

    test('test upload contract', () async {
      await Future.delayed(Duration(seconds: 5));
      // load account
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      // load contract wasm file
      Uint8List contractCode = await Util.readFile(helloContractPath);

      UploadContractWasmHostFunction uploadFunction =
          UploadContractWasmHostFunction(contractCode);
      InvokeHostFunctionOperation operation =
          (InvokeHostFuncOpBuilder()).addFunction(uploadFunction).build();
      // create transaction for installing the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(simulateResponse.cost!.cpuInsns > 0);
      assert(simulateResponse.cost!.memBytes > 0);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // print("Envelope xdr: " + transactionEnvelopeXdr);

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

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      /*print("Orig Meta: " + transactionResponse.resultMetaXdr!);
      print("New Meta: " + meta.toBase64EncodedXdrString());
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations =
          await sdk.operations.forTransaction(sendResponse.hash!).execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert("upload_wasm" == operationResponse.hostFunctions![0].type);
      } else {
        assert(false);
      }
    });

    test('test create contract', () async {
      await Future.delayed(Duration(seconds: 5));
      assert(helloContractWasmId != null);

      // reload account for current sequence nr
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
          .addFunction(CreateContractHostFunction(helloContractWasmId!))
          .build();
      // create transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      helloContractCreateFootprint = simulateResponse.footprint;

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, Network.FUTURENET);

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
        helloContractId = rpcTransactionResponse.getContractId();
      }
      assert(helloContractId != null);

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      /*assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations =
          await sdk.operations.forTransaction(sendResponse.hash!).execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert("create_contract" == operationResponse.hostFunctions![0].type);
      } else {
        assert(false);
      }
    });

    test('test invoke contract', () async {
      await Future.delayed(Duration(seconds: 5));
      assert(helloContractId != null);

      // load account for sequence number
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      // prepare argument
      XdrSCVal arg = XdrSCVal.forSymbol("friend");

      String functionName = "hello";

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          helloContractId!, functionName,
          arguments: [arg]);

      InvokeHostFunctionOperation operation =
          (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

      // create transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, Network.FUTURENET);

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
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      /*assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations =
          await sdk.operations.forTransaction(sendResponse.hash!).execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert("invoke_contract" == operationResponse.hostFunctions![0].type);
      } else {
        assert(false);
      }
    });

    test('test events', () async {
      await Future.delayed(Duration(seconds: 5));
      // Install contract
      AccountResponse submitter = await sdk.accounts.account(accountAId);

      Uint8List contractCode = await Util.readFile(eventsContractPath);

      InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
          .addFunction(UploadContractWasmHostFunction(contractCode))
          .build();
      // create transaction for installing the contract
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, Network.FUTURENET);

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
      submitter = await sdk.accounts.account(accountAId);
      operation = (InvokeHostFuncOpBuilder())
          .addFunction(CreateContractHostFunction(wasmId))
          .build();
      // create transaction for creating the contract
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      simulateResponse = await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, Network.FUTURENET);

      sendResponse = await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      String? eventsContractId;
      rpcTransactionResponse = await pollStatus(sendResponse.hash!);
      if (rpcTransactionResponse.status ==
          GetTransactionResponse.STATUS_SUCCESS) {
        eventsContractId = rpcTransactionResponse.getContractId();
      }
      assert(eventsContractId != null);
      String contractId = eventsContractId!;

      await Future.delayed(Duration(seconds: 5));
      // Invoke contract
      submitter = await sdk.accounts.account(accountAId);

      String functionName = "events";
      InvokeContractHostFunction hostFunction =
          InvokeContractHostFunction(contractId, functionName);

      operation = (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

      // create transaction for creating the contract
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      simulateResponse = await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.transactionData != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, Network.FUTURENET);

      sendResponse = await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      await pollStatus(sendResponse.hash!);

      // query events
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      String startLedger = transactionResponse.ledger.toString();

      EventFilter eventFilter =
          EventFilter(type: "contract", contractIds: [contractId]);
      GetEventsRequest eventsRequest =
          GetEventsRequest(startLedger, filters: [eventFilter]);
      GetEventsResponse eventsResponse =
          await sorobanServer.getEvents(eventsRequest);
      assert(!eventsResponse.isErrorResponse);
      assert(eventsResponse.events != null);
      assert(eventsResponse.events!.length > 0);
    });

    test('test get ledger entries', () async {
      assert(helloContractCreateFootprint != null);
      String? contractCodeKey =
          helloContractCreateFootprint!.getContractCodeLedgerKey();
      assert(contractCodeKey != null);
      String? contractDataKey =
          helloContractCreateFootprint!.getContractDataLedgerKey();
      assert(contractDataKey != null);

      GetLedgerEntryResponse contractCodeEntry =
          await sorobanServer.getLedgerEntry(contractCodeKey!);
      assert(contractCodeEntry.ledgerEntryData != null);
      assert(contractCodeEntry.lastModifiedLedgerSeq != null);
      assert(contractCodeEntry.latestLedger != null);
      assert(contractCodeEntry.ledgerEntryDataXdr != null);
      GetLedgerEntryResponse contractDataEntry =
          await sorobanServer.getLedgerEntry(contractDataKey!);
      assert(contractDataEntry.ledgerEntryData != null);
      assert(contractDataEntry.lastModifiedLedgerSeq != null);
      assert(contractDataEntry.latestLedger != null);
      assert(contractDataEntry.ledgerEntryDataXdr != null);
      assert(true);
    });

    test('test deploy SAC with source account', () async {
      await Future.delayed(Duration(seconds: 5));
      // load account
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
          .addFunction(DeploySACWithSourceAccountHostFunction())
          .build();
      // create transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(simulateResponse.cost!.cpuInsns > 0);
      assert(simulateResponse.cost!.memBytes > 0);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairA, Network.FUTURENET);

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

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      /*assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations =
          await sdk.operations.forTransaction(sendResponse.hash!).execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert("create_contract" == operationResponse.hostFunctions![0].type);
      } else {
        assert(false);
      }
    });

    test('test SAC with asset', () async {
      await Future.delayed(Duration(seconds: 5));
      await FuturenetFriendBot.fundTestAccount(accountBId);

      // prepare trustline
      AccountResponse sourceAccount = await sdk.accounts.account(accountBId);
      ChangeTrustOperationBuilder ctOp =
          ChangeTrustOperationBuilder(assetFsdk, "1000000");
      ctOp.setSourceAccount(accountAId);
      PaymentOperationBuilder pOp =
          PaymentOperationBuilder(accountAId, assetFsdk, "200");

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(ctOp.build())
          .addOperation(pOp.build())
          .build();
      transaction.sign(keyPairA, Network.FUTURENET);
      transaction.sign(keyPairB, Network.FUTURENET);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);

      // load account
      AccountResponse accountB = await sdk.accounts.account(accountBId);

      InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
          .addFunction(DeploySACWithAssetHostFunction(assetFsdk))
          .build();
      // create transaction for creating the contract
      transaction =
          new TransactionBuilder(accountB).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(simulateResponse.cost!.cpuInsns > 0);
      assert(simulateResponse.cost!.memBytes > 0);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(keyPairB, Network.FUTURENET);

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

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse
              .resultMetaXdr!); /*
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations =
          await sdk.operations.forTransaction(sendResponse.hash!).execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert("create_contract" == operationResponse.hostFunctions![0].type);
      } else {
        assert(false);
      }
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
  });
}
