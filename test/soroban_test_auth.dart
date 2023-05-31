import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://rpc-futurenet.stellar.org:443");

  StellarSDK sdk = StellarSDK.FUTURENET;

  KeyPair submitterKeypair = KeyPair.random();
  String submitterId = submitterKeypair.accountId;
  KeyPair invokerKeypair = KeyPair.random();
  String invokerId = invokerKeypair.accountId;

  String authContractPath =
      "/Users/chris/Soneso/github/stellar_flutter_sdk/test/wasm/auth.wasm";
  String? authContractWasmId;
  String? authContractId;

  setUp(() async {
    sorobanServer.enableLogging = true;
    sorobanServer.acknowledgeExperimental = true;

    try {
      await sdk.accounts.account(submitterId);
    } catch (e) {
      await FuturenetFriendBot.fundTestAccount(submitterId);
    }

    try {
      await sdk.accounts.account(invokerId);
    } catch (e) {
      await FuturenetFriendBot.fundTestAccount(invokerId);
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
    test('test upload auth contract', () async {
      // load account
      AccountResponse submitter = await sdk.accounts.account(submitterId);
      // load contract wasm file
      Uint8List contractCode = await Util.readFile(authContractPath);

      // upload the contract
      InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
          .addFunction(UploadContractWasmHostFunction(contractCode))
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
      transaction.sign(submitterKeypair, Network.FUTURENET);

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
    });

    test('test create auth contract', () async {
      assert(authContractWasmId != null);

      // reload account for current sequence nr
      AccountResponse submitter = await sdk.accounts.account(submitterId);

      InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
          .addFunction(CreateContractHostFunction(authContractWasmId!))
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
      transaction.sign(submitterKeypair, Network.FUTURENET);

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(!sendResponse.isErrorResponse);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      GetTransactionResponse rpcTransactionResponse =
          await pollStatus(sendResponse.hash!);
      authContractId = rpcTransactionResponse.getContractId();
      assert(authContractId != null);
    });

    test('test invoke auth account', () async {
      // invoke contract
      // If submitter_kp and invoker are the same account, the submission will fail
      // because in that case we do not need address, nonce and signature in auth
      // or we have to change the footprint
      // See https://discord.com/channels/897514728459468821/1078208197283807305

      assert(authContractId != null);

      // reload account for sequence number
      AccountResponse submitter = await sdk.accounts.account(submitterId);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      AuthorizedInvocation rootInvocation =
          AuthorizedInvocation(authContractId!, functionName, args: args);
      int nonce = await sorobanServer.getNonce(invokerId, authContractId!);
      ContractAuth contractAuth =
          ContractAuth(rootInvocation, address: invokerAddress, nonce: nonce);
      contractAuth.sign(invokerKeypair, Network.FUTURENET);

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          authContractId!, functionName,
          arguments: args, auth: [contractAuth]);

      InvokeHostFunctionOperation operation =
      (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.transactionData != null);
      assert(simulateResponse.minResourceFee != null);

      // this is because in preview 9 the fee calculation from the simulation is not always accurate
      // see: https://discord.com/channels/897514728459468821/1112853306881081354
      int instructions = simulateResponse.transactionData!.resources.instructions.uint32;
      instructions += (instructions / 4).round();
      simulateResponse.transactionData!.resources.instructions = XdrUint32(instructions);
      simulateResponse.minResourceFee = simulateResponse.minResourceFee! + 3000;

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      transaction.sign(submitterKeypair, Network.FUTURENET);

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
      String status = rpcTransactionResponse.status!;
      assert(status == GetTransactionResponse.STATUS_SUCCESS);

      assert(rpcTransactionResponse.getResultValue()?.map != null);
      List<XdrSCMapEntry> map = rpcTransactionResponse.getResultValue()!.map!;
      if (map.length > 0) {
        for (XdrSCMapEntry entry in map) {
          Address address = Address.fromXdr(entry.key.address!);
          print("{" +
              address.accountId! +
              ", " +
              entry.val.u32!.uint32.toString() +
              "}");
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

    test('test invoke auth invoker', () async {
      // See https://soroban.stellar.org/docs/learn/authorization#transaction-invoker
      // See https://discord.com/channels/897514728459468821/1078208197283807305

      // submitter and invoker use are thw same
      // so we should not need its address & nonce in contract auth and no need to sign

      assert(authContractId != null);

      // reload account for sequence number
      AccountResponse invoker = await sdk.accounts.account(invokerId);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      AuthorizedInvocation rootInvocation =
          AuthorizedInvocation(authContractId!, functionName, args: args);

      //int nonce = await sorobanServer.getNonce(invokerId, authContractId!);
      //ContractAuth contractAuth = ContractAuth(rootInvocation, address: invokerAddress, nonce: nonce);
      //contractAuth.sign(invokerKeypair, Network.FUTURENET);
      ContractAuth contractAuth = ContractAuth(rootInvocation);

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          authContractId!, functionName,
          arguments: args, auth: [contractAuth]);

      InvokeHostFunctionOperation operation =
      (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

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
      transaction.sign(invokerKeypair, Network.FUTURENET);

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

      assert(rpcTransactionResponse.getResultValue()?.map != null);
      List<XdrSCMapEntry> map = rpcTransactionResponse.getResultValue()!.map!;
      if (map.length > 0) {
        for (XdrSCMapEntry entry in map) {
          Address address = Address.fromXdr(entry.key.address!);
          print("{" +
              address.accountId! +
              ", " +
              entry.val.u32!.uint32.toString() +
              "}");
        }
      }
    });

    test('test invoke with auth from simulation', () async {
      // in this test we use the contract auth from the simulation response.

      assert(authContractId != null);

      // reload account for sequence number
      await Future.delayed(Duration(seconds: 5));
      AccountResponse submitter = await sdk.accounts.account(submitterId);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          authContractId!, functionName, arguments: args);

      InvokeHostFunctionOperation operation =
      (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to obtain the transaction data + resource fee
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.contractAuth != null);

      // this is because in preview 9 the fee calculation from the simulation is not always accurate
      // see: https://discord.com/channels/897514728459468821/1112853306881081354
      int instructions = simulateResponse.transactionData!.resources.instructions.uint32;
      instructions += (instructions / 4).round();
      simulateResponse.transactionData!.resources.instructions = XdrUint32(instructions);
      simulateResponse.minResourceFee = simulateResponse.minResourceFee! + 3000;

      // set transaction data, add resource fee and sign transaction
      transaction.sorobanTransactionData = simulateResponse.transactionData;
      transaction.addResourceFee(simulateResponse.minResourceFee!);
      // add contract auth
      List<ContractAuth> contractAuth = simulateResponse.contractAuth!;
      for (ContractAuth auth in contractAuth) {
        auth.sign(invokerKeypair, Network.FUTURENET);
      }

      transaction.setContractAuth(contractAuth);

      transaction.sign(submitterKeypair, Network.FUTURENET);

      // check transaction xdr encoding and decoding back and forth
      String transactionEnvelopeXdr = transaction.toEnvelopeXdrBase64();
      assert(transactionEnvelopeXdr ==
          AbstractTransaction.fromEnvelopeXdrString(transactionEnvelopeXdr)
              .toEnvelopeXdrBase64());

      // send the transaction
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      assert(sendResponse.error == null);
      assert(sendResponse.status != null);
      assert(sendResponse.status != SendTransactionResponse.STATUS_ERROR);

      GetTransactionResponse rpcTransactionResponse =
          await pollStatus(sendResponse.hash!);
      String status = rpcTransactionResponse.status!;
      assert(status == GetTransactionResponse.STATUS_SUCCESS);

      assert(rpcTransactionResponse.getResultValue()?.map != null);
      List<XdrSCMapEntry> map = rpcTransactionResponse.getResultValue()!.map!;
      if (map.length > 0) {
        for (XdrSCMapEntry entry in map) {
          Address address = Address.fromXdr(entry.key.address!);
          print("{" +
              address.accountId! +
              ", " +
              entry.val.u32!.uint32.toString() +
              "}");
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

    });
  });
}
