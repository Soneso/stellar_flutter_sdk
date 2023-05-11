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
    } catch(e) {
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

    /*test ('xdr decodings', () async {
      String xdr = "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";
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(xdr);
      assert(meta.v3?.txResult.result.results.first.tr?.invokeHostFunctionResult?.success != null);
    });*/

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

    test('test install contract', () async {
      // load account
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      // load contract wasm file
      Uint8List contractCode = await Util.readFile(helloContractPath);

      // create transaction for installing the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInstallingContractCode(contractCode)
              .build();
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(int.parse(simulateResponse.cost!.cpuInsns) > 0);
      assert(int.parse(simulateResponse.cost!.memBytes) > 0);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);

      // set footprint and sign transaction
      transaction.setFootprint(simulateResponse.footprint!);
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
      if (rpcTransactionResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
        helloContractWasmId = rpcTransactionResponse.getWasmId();
      }

      assert(helloContractWasmId != null);

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      /*XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      print("Orig Meta: " + transactionResponse.resultMetaXdr!);
      print("New Meta: " + meta.toBase64EncodedXdrString());
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.hash!)
          .execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert(operationResponse.footprint ==
            simulateResponse.footprint?.toBase64EncodedXdrString());
      } else {
        assert(false);
      }
    });

    test('test create contract', () async {
      assert(helloContractWasmId != null);

      // reload account for current sequence nr
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      // build the operation for creating the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forCreatingContract(helloContractWasmId!)
              .build();

      // build the transaction for creating the contract
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // first simulate to obtain the footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);

      helloContractCreateFootprint = simulateResponse.footprint;

      // set footprint & sign
      transaction.setFootprint(simulateResponse.footprint!);
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
      if (rpcTransactionResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
        helloContractId = rpcTransactionResponse.getContractId();
      }
      assert(helloContractId != null);

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      /*XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.hash!)
          .execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert(operationResponse.footprint ==
            simulateResponse.footprint?.toBase64EncodedXdrString());
      } else {
        assert(false);
      }
    });

    test('test invoke contract', () async {
      assert(helloContractId != null);

      // load account for sequence number
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      // prepare argument
      XdrSCVal arg = XdrSCVal.forSymbol("friend");

      String method = "hello";
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInvokingContract(helloContractId!, method,
              functionArguments: [arg]).build();
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to get footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);

      // set footprint and sign
      transaction.setFootprint(simulateResponse.footprint!);
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
      if (rpcTransactionResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
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

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.hash!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      /*XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.hash!)
          .execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert(operationResponse.footprint ==
            simulateResponse.footprint?.toBase64EncodedXdrString());
        assert(operationResponse.parameters != null &&
            operationResponse.parameters!.length > 0);
      } else {
        assert(false);
      }
    });

    test('test events', () async {
      // Install contract
      AccountResponse submitter = await sdk.accounts.account(accountAId);

      Uint8List contractCode = await Util.readFile(eventsContractPath);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInstallingContractCode(contractCode)
              .build();
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.footprint != null);

      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(keyPairA, Network.FUTURENET);

      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      String? eventsContractWasmId;
      GetTransactionResponse rpcTransactionResponse =
          await pollStatus(sendResponse.hash!);
      if (rpcTransactionResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
        eventsContractWasmId = rpcTransactionResponse.getWasmId();
      }

      assert(eventsContractWasmId != null);
      String wasmId = eventsContractWasmId!;

      // Create contract
      submitter = await sdk.accounts.account(accountAId);
      operation = InvokeHostFuncOpBuilder.forCreatingContract(wasmId).build();
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      simulateResponse = await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.footprint != null);

      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(keyPairA, Network.FUTURENET);

      sendResponse = await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      String? eventsContractId;
      rpcTransactionResponse = await pollStatus(sendResponse.hash!);
      if (rpcTransactionResponse.status == GetTransactionResponse.STATUS_SUCCESS) {
        eventsContractId = rpcTransactionResponse.getContractId();
      }
      assert(eventsContractId != null);
      String contractId = eventsContractId!;

      // Invoke contract
      submitter = await sdk.accounts.account(accountAId);

      String functionName = "events";
      operation =
          InvokeHostFuncOpBuilder.forInvokingContract(contractId, functionName)
              .build();
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      simulateResponse = await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.footprint != null);

      transaction.setFootprint(simulateResponse.footprint!);
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
      // load account
      AccountResponse accountA = await sdk.accounts.account(accountAId);

      // create transaction for deploying the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forDeploySACWithSourceAccount().build();
      Transaction transaction =
          new TransactionBuilder(accountA).addOperation(operation).build();

      // simulate first to obtain the footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(int.parse(simulateResponse.cost!.cpuInsns) > 0);
      assert(int.parse(simulateResponse.cost!.memBytes) > 0);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);

      // set footprint and sign transaction
      transaction.setFootprint(simulateResponse.footprint!);
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
      /*XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.hash!)
          .execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert(operationResponse.footprint ==
            simulateResponse.footprint?.toBase64EncodedXdrString());
      } else {
        assert(false);
      }
    });

    test('test SAC with asset', () async {

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

      // create transaction for deploying the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forDeploySACWithAsset(assetFsdk).build();
      transaction =
          new TransactionBuilder(accountB).addOperation(operation).build();

      // simulate first to obtain the footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.results != null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.cost != null);
      assert(int.parse(simulateResponse.cost!.cpuInsns) > 0);
      assert(int.parse(simulateResponse.cost!.memBytes) > 0);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.latestLedger != null);

      // set footprint and sign transaction
      transaction.setFootprint(simulateResponse.footprint!);
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
      /*XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.hash!)
          .execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
      if (operationResponse is InvokeHostFunctionOperationResponse) {
        assert(operationResponse.footprint ==
            simulateResponse.footprint?.toBase64EncodedXdrString());
      } else {
        assert(false);
      }
    });

    test('test StrKey contractId', () async {
        String contractIdA = "86efd9a9d6fbf70297294772c9676127e16a23c2141cab3e29be836bb537a9b9";
        String strEncodedA = "CCDO7WNJ2357OAUXFFDXFSLHMET6C2RDYIKBZKZ6FG7IG25VG6U3SLHT";
        String strEncodedB = StrKey.encodeContractIdHex(contractIdA);
        assert(strEncodedA == strEncodedB);

        assert(strEncodedA == strEncodedB);
        String contractIdB = StrKey.decodeContractIdHex(strEncodedB);
        assert(contractIdA == contractIdB);

        String strEncodedC = StrKey.encodeContractId(Util.hexToBytes(contractIdA));
        assert(strEncodedA == strEncodedC);
        assert(contractIdA == Util.bytesToHex(StrKey.decodeContractId(strEncodedC)));
    });
  });
}
