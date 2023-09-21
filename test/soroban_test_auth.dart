import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://soroban-testnet.stellar.org");

  StellarSDK sdk = StellarSDK.TESTNET;

  KeyPair submitterKeypair = KeyPair.random();
  String submitterId = submitterKeypair.accountId;
  KeyPair invokerKeypair = KeyPair.random();
  String invokerId = invokerKeypair.accountId;

  String authContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/soroban_auth_contract.wasm";
  String? authContractWasmId;
  String? authContractId;

  setUp(() async {
    sorobanServer.enableLogging = true;
    sorobanServer.acknowledgeExperimental = true;

    try {
      await sdk.accounts.account(submitterId);
    } catch (e) {
      await FriendBot.fundTestAccount(submitterId);
    }

    try {
      await sdk.accounts.account(invokerId);
    } catch (e) {
      await FriendBot.fundTestAccount(invokerId);
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
    AccountResponse accountA = await sdk.accounts.account(submitterId);

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
    
    accountA = await sdk.accounts.account(submitterId);
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
    transaction.sign(submitterKeypair, Network.TESTNET);

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
    AccountResponse accountA = await sdk.accounts.account(submitterId);

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

    accountA = await sdk.accounts.account(submitterId);
    // set transaction data, add resource fee and sign transaction
    transaction.sorobanTransactionData = simulateResponse.transactionData;
    transaction.addResourceFee(simulateResponse.minResourceFee!);
    transaction.sign(submitterKeypair, Network.TESTNET);

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
      await restoreContractFootprint(authContractPath);
    });

    test('test upload auth contract', () async {
      await Future.delayed(Duration(seconds: 5));
      // load account
      AccountResponse submitter = await sdk.accounts.account(submitterId);
      // load contract wasm file
      Uint8List contractCode = await Util.readFile(authContractPath);

      // upload the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder(UploadContractWasmHostFunction(contractCode))
              .build();
      // create transaction for installing the contract
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
      transaction.sign(submitterKeypair, Network.TESTNET);

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
      await bumpContractCodeFootprint(authContractWasmId!, 100000);
    });

    test('test create auth contract', () async {
      await Future.delayed(Duration(seconds: 5));
      assert(authContractWasmId != null);

      // reload account for current sequence nr
      AccountResponse submitter = await sdk.accounts.account(submitterId);

      CreateContractHostFunction function = CreateContractHostFunction(
          Address.forAccountId(submitterId), authContractWasmId!);
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
      transaction.sign(submitterKeypair, Network.TESTNET);

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

    test('test invoke auth account', () async {
      // submitter and invoker use are NOT the same
      // we need to sign auth
      assert(authContractId != null);
      // reload account for sequence number
      AccountResponse submitter = await sdk.accounts.account(submitterId);

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
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);

      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // this is because the fee calculation from the simulation is not always accurate
      // see: https://discord.com/channels/897514728459468821/1112853306881081354
      int instructions =
          simulateResponse.transactionData!.resources.instructions.uint32;
      instructions += (instructions / 4).round();
      simulateResponse.transactionData!.resources.instructions =
          XdrUint32(instructions);
      simulateResponse.minResourceFee = simulateResponse.minResourceFee! + 6000;

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
        a.credentials.addressCredentials!.signatureExpirationLedger = latestLedgerResponse.sequence! + 10;
        // sign
        a.sign(invokerKeypair, Network.TESTNET);
      }
      transaction.setSorobanAuth(auth);
      transaction.sign(submitterKeypair, Network.TESTNET);

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
      /*XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(
          transactionResponse.resultMetaXdr!);
      assert(meta.toBase64EncodedXdrString() ==
          transactionResponse.resultMetaXdr!);*/

      // check operation response from horizon
      Page<OperationResponse> operations =
          await sdk.operations.forTransaction(sendResponse.hash!).execute();
      assert(operations.records != null && operations.records!.length > 0);
      OperationResponse operationResponse = operations.records!.first;
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

      // reload account for sequence number
      AccountResponse invoker = await sdk.accounts.account(invokerId);

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
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.setSorobanAuth(simulateResponse.sorobanAuth);
      transaction.sign(invokerKeypair, Network.TESTNET);

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
