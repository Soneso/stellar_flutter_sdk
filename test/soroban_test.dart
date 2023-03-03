import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://horizon-futurenet.stellar.cash/soroban/rpc");

  StellarSDK sdk = StellarSDK.FUTURENET;

  KeyPair keyPair1 = KeyPair.random();
  String account1Id = keyPair1.accountId;
  KeyPair keyPair2 = KeyPair.random();
  String account2Id = keyPair2.accountId;
  Asset assetFsdk = AssetTypeCreditAlphaNum4("Fsdk", account2Id);

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
    GetAccountResponse accountResponse =
        await sorobanServer.getAccount(account1Id);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(account1Id);
    }
  });

  group('all tests', () {
    test('test server health ', () async {
      GetHealthResponse healthResponse = await sorobanServer.getHealth();
      assert(GetHealthResponse.HEALTHY == healthResponse.status);
    });

    test('test account request', () async {
      GetAccountResponse accountResponse =
          await sorobanServer.getAccount(account1Id);

      assert(!accountResponse.isErrorResponse);
      assert(account1Id == accountResponse.accountId);
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
      AccountResponse accountA = await sdk.accounts.account(account1Id);

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
      transaction.sign(keyPair1, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.transactionId != null);
      assert(sendResponse.status != null);
      assert(sendResponse.resultError == null);

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;
      GetTransactionStatusResponse statusResponse;

      // poll until status is success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);
        assert(statusResponse.id != null);
        assert(statusResponse.status != null);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          print(statusResponse.resultError!.message);
          assert(false);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          helloContractWasmId = statusResponse.getWasmId();
        }
      }
      assert(helloContractWasmId != null);

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.transactionId!)
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
      AccountResponse accountA = await sdk.accounts.account(account1Id);

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
      transaction.sign(keyPair1, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      String status = SorobanServer.TRANSACTION_STATUS_PENDING;
      assert(sendResponse.error == null);
      assert(sendResponse.transactionId != null);
      assert(sendResponse.status != null);
      assert(sendResponse.resultError == null);

      // poll until success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        GetTransactionStatusResponse statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);
        assert(statusResponse.id != null);
        assert(statusResponse.status != null);
        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          print(statusResponse.resultError!.message);
          assert(false);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          helloContractId = statusResponse.getContractId();
        }
      }

      assert(helloContractId != null);

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.transactionId!)
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

      // reload account for sequence number
      AccountResponse accountA = await sdk.accounts.account(account1Id);

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
      transaction.sign(keyPair1, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send the transaction
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.transactionId != null);
      assert(sendResponse.status != null);
      assert(sendResponse.resultError == null);

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;

      // poll until success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        GetTransactionStatusResponse statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);
        assert(statusResponse.id != null);
        assert(statusResponse.status != null);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          print(statusResponse.resultError?.message);
          assert(false);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          assert(statusResponse.results!.isNotEmpty);

          List<TransactionStatusResult> res = statusResponse.results!;
          for (int i = 0; i < res.length; i++) {
            String xdr = res[i].xdr;
            XdrSCVal resVal = XdrSCVal.fromBase64EncodedXdrString(xdr);

            assert(resVal.obj != null);
            assert(resVal.obj!.vec != null);
            assert(resVal.obj!.vec!.length == 2);
            assert(resVal.obj!.vec![0].sym == "Hello");
            assert(resVal.obj!.vec![1].sym == "friend");
            print(resVal.obj!.vec![0].sym! + " " + resVal.obj!.vec![1].sym!);
          }

          // user friendly
          XdrSCVal? resVal = statusResponse.getResultValue();
          List<XdrSCVal>? vec = resVal?.getVec();
          if (vec != null && vec.length > 1) {
            print("[${vec[0].sym} , ${vec[1].sym}]");
          }
        }
      }

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.transactionId!)
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
      GetAccountResponse submitter = await sorobanServer.getAccount(account1Id);

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
      transaction.sign(keyPair1, Network.FUTURENET);

      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.resultError == null);

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;
      GetTransactionStatusResponse statusResponse;

      String? eventsContractWasmId;
      // poll until status is success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          print(statusResponse.resultError!.message);
          assert(false);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          eventsContractWasmId = statusResponse.getWasmId();
        }
      }
      assert(eventsContractWasmId != null);
      String wasmId = eventsContractWasmId!;

      // Create contract

      submitter = await sorobanServer.getAccount(account1Id);
      operation = InvokeHostFuncOpBuilder.forCreatingContract(wasmId).build();
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      simulateResponse = await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.footprint != null);

      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(keyPair1, Network.FUTURENET);

      sendResponse = await sorobanServer.sendTransaction(transaction);
      status = SorobanServer.TRANSACTION_STATUS_PENDING;
      assert(sendResponse.error == null);
      assert(sendResponse.resultError == null);

      String? eventsContractId;
      // poll until success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        GetTransactionStatusResponse statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);
        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          print(statusResponse.resultError!.message);
          assert(false);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          eventsContractId = statusResponse.getContractId();
        }
      }

      assert(eventsContractId != null);
      String contractId = eventsContractId!;

      // Invoke contract
      submitter = await sorobanServer.getAccount(account1Id);

      String functionName = "events";
      operation =
          InvokeHostFuncOpBuilder.forInvokingContract(contractId, functionName)
              .build();
      transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      simulateResponse = await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.footprint != null);

      transaction.setFootprint(simulateResponse.footprint!);
      transaction.sign(keyPair1, Network.FUTURENET);

      sendResponse = await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.resultError == null);

      status = SorobanServer.TRANSACTION_STATUS_PENDING;

      // poll until success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        GetTransactionStatusResponse statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
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

      // query events
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      String startLedger = transactionResponse.ledger.toString();
      String endLedger = transactionResponse.ledger.toString();

      EventFilter eventFilter =
          EventFilter(type: "contract", contractIds: [contractId]);
      GetEventsRequest eventsRequest =
          GetEventsRequest(startLedger, endLedger, filters: [eventFilter]);
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
      AccountResponse account1 = await sdk.accounts.account(account1Id);

      // create transaction for deploying the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forDeploySACWithSourceAccount().build();
      Transaction transaction =
          new TransactionBuilder(account1).addOperation(operation).build();

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
      transaction.sign(keyPair1, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.transactionId != null);
      assert(sendResponse.status != null);
      assert(sendResponse.resultError == null);

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;
      GetTransactionStatusResponse statusResponse;

      // poll until status is success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);
        assert(statusResponse.id != null);
        assert(statusResponse.status != null);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          print(statusResponse.resultError!.message);
          assert(false);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
        }
      }

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.transactionId!)
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
      GetAccountResponse accountResponse =
          await sorobanServer.getAccount(account2Id);
      if (accountResponse.accountMissing) {
        await FuturenetFriendBot.fundTestAccount(account2Id);
      }

      // prepare trustline
      AccountResponse sourceAccount = await sdk.accounts.account(account2Id);
      ChangeTrustOperationBuilder ctOp =
          ChangeTrustOperationBuilder(assetFsdk, "1000000");
      ctOp.setSourceAccount(account1Id);
      PaymentOperationBuilder pOp =
          PaymentOperationBuilder(account1Id, assetFsdk, "200");

      Transaction transaction = TransactionBuilder(sourceAccount)
          .addOperation(ctOp.build())
          .addOperation(pOp.build())
          .build();
      transaction.sign(keyPair1, Network.FUTURENET);
      transaction.sign(keyPair2, Network.FUTURENET);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);
      assert(response.success);

      // load account
      AccountResponse accountA = await sdk.accounts.account(account2Id);

      // create transaction for deploying the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forDeploySACWithAsset(assetFsdk).build();
      transaction =
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
      transaction.sign(keyPair2, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.transactionId != null);
      assert(sendResponse.status != null);
      assert(sendResponse.resultError == null);

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;
      GetTransactionStatusResponse statusResponse;

      // poll until status is success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);
        assert(statusResponse.id != null);
        assert(statusResponse.status != null);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          print(statusResponse.resultError!.message);
          assert(false);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
        }
      }

      // check horizon responses decoding
      TransactionResponse transactionResponse =
          await sdk.transactions.transaction(sendResponse.transactionId!);
      assert(transactionResponse.operationCount == 1);
      assert(transactionEnvelopeXdr == transactionResponse.envelopeXdr);

      // check if meta can be parsed
      XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);

      // check operation response from horizon
      Page<OperationResponse> operations = await sdk.operations
          .forTransaction(sendResponse.transactionId!)
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
  });
}
