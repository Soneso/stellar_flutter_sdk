import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  SorobanServer sorobanServer =
      SorobanServer("https://horizon-futurenet.stellar.cash/soroban/rpc");

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
    GetAccountResponse accountResponse =
        await sorobanServer.getAccount(submitterId);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(submitterId);
    }
    await sorobanServer.getAccount(invokerId);
    if (accountResponse.accountMissing) {
      await FuturenetFriendBot.fundTestAccount(invokerId);
    }
  });

  group('all tests', () {
    test('test install auth contract', () async {
      // load account
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      // load contract wasm file
      Uint8List contractCode = await Util.readFile(authContractPath);

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
      assert(sendResponse.resultError == null);

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;
      GetTransactionStatusResponse statusResponse;

      // poll until status is success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(!statusResponse.isErrorResponse);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          fail("status response result error: " +
              statusResponse.resultError!.message!);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          authContractWasmId = statusResponse.getWasmId();
        }
      }
      assert(authContractWasmId != null);
    });

    test('test create auth contract', () async {
      assert(authContractWasmId != null);

      // reload account for current sequence nr
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      // build the operation for creating the contract
      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forCreatingContract(authContractWasmId!)
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
      transaction.sign(submitterKeypair, Network.FUTURENET);

      // send transaction to soroban rpc server
      SendTransactionResponse sendResponse =
          await sorobanServer.sendTransaction(transaction);
      String status = SorobanServer.TRANSACTION_STATUS_PENDING;
      assert(!sendResponse.isErrorResponse);
      assert(sendResponse.resultError == null);

      // poll until success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        GetTransactionStatusResponse statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(!statusResponse.isErrorResponse);
        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          fail("status response result error: " +
              statusResponse.resultError!.message!);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          authContractId = statusResponse.getContractId();
        }
      }

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
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      AuthorizedInvocation rootInvocation =
          AuthorizedInvocation(authContractId!, functionName, args: args);
      int nonce = await sorobanServer.getNonce(invokerId, authContractId!);
      ContractAuth contractAuth =
          ContractAuth(rootInvocation, address: invokerAddress, nonce: nonce);
      contractAuth.sign(invokerKeypair, Network.FUTURENET);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInvokingContract(
              authContractId!, functionName,
              functionArguments: args, contractAuth: [contractAuth]).build();
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to get footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);

      // set footprint and sign
      transaction.setFootprint(simulateResponse.footprint!);
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

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          fail(statusResponse.resultError!.message!);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          assert(statusResponse.results!.isNotEmpty);

          List<XdrSCMapEntry>? map = statusResponse.getResultValue()?.getMap();
          if (map != null && map.length > 0) {
            for (XdrSCMapEntry entry in map) {
              Address address = Address.fromXdr(entry.key.obj!.address!);
              print("{" +
                  address.accountId! +
                  ", " +
                  entry.val.u32!.uint32.toString() +
                  "}");
            }
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

    test('test invoke auth invoker', () async {
      // See https://soroban.stellar.org/docs/learn/authorization#transaction-invoker
      // See https://discord.com/channels/897514728459468821/1078208197283807305

      // submitter and invoker use are thw same
      // so we should not need its address & nonce in contract auth and no need to sign

      assert(authContractId != null);

      // reload account for sequence number
      GetAccountResponse invoker = await sorobanServer.getAccount(invokerId);
      assert(!invoker.isErrorResponse);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      AuthorizedInvocation rootInvocation =
          AuthorizedInvocation(authContractId!, functionName, args: args);

      //int nonce = await sorobanServer.getNonce(invokerId, authContractId!);
      //ContractAuth contractAuth = ContractAuth(rootInvocation, address: invokerAddress, nonce: nonce);
      //contractAuth.sign(invokerKeypair, Network.FUTURENET);
      ContractAuth contractAuth = ContractAuth(rootInvocation);

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInvokingContract(
              authContractId!, functionName,
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
      assert(sendResponse.resultError == null);

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;

      // poll until success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        GetTransactionStatusResponse statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          fail(statusResponse.resultError!.message!);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          assert(statusResponse.results!.isNotEmpty);

          List<XdrSCMapEntry>? map = statusResponse.getResultValue()?.getMap();
          if (map != null && map.length > 0) {
            for (XdrSCMapEntry entry in map) {
              Address address = Address.fromXdr(entry.key.obj!.address!);
              print("{" +
                  address.accountId! +
                  ", " +
                  entry.val.u32!.uint32.toString() +
                  "}");
            }
          }
        }
      }
    });

    test('test invoke with auth from simulation', () async {
      // in this test we use the contract auth from the simulation response.

      assert(authContractId != null);

      // reload account for sequence number
      GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);
      assert(!submitter.isErrorResponse);

      Address invokerAddress = Address.forAccountId(invokerId);
      String functionName = "auth";
      List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

      InvokeHostFunctionOperation operation =
          InvokeHostFuncOpBuilder.forInvokingContract(
                  authContractId!, functionName,
                  functionArguments: args)
              .build();
      Transaction transaction =
          new TransactionBuilder(submitter).addOperation(operation).build();

      // simulate first to get footprint
      SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
      assert(simulateResponse.error == null);
      assert(simulateResponse.resultError == null);
      assert(simulateResponse.footprint != null);
      assert(simulateResponse.contractAuth != null);

      // set footprint, contract auth and sign
      transaction.setFootprint(simulateResponse.footprint!);
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

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          fail(statusResponse.resultError!.message!);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          assert(statusResponse.results!.isNotEmpty);

          List<XdrSCMapEntry>? map = statusResponse.getResultValue()?.getMap();
          if (map != null && map.length > 0) {
            for (XdrSCMapEntry entry in map) {
              Address address = Address.fromXdr(entry.key.obj!.address!);
              print("{" +
                  address.accountId! +
                  ", " +
                  entry.val.u32!.uint32.toString() +
                  "}");
            }
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

    test('test atomic swap', () async {
      // See https://soroban.stellar.org/docs/how-to-guides/atomic-swap
      // See https://soroban.stellar.org/docs/learn/authorization
      // See https://github.com/StellarCN/py-stellar-base/blob/soroban/examples/soroban_auth_atomic_swap.py

      KeyPair swapSubmitterKp = KeyPair.fromSecretSeed(
          "SBPTTA3D3QYQ6E2GSACAZDUFH2UILBNG3EBJCK3NNP7BE4O757KGZUGA");
      String swapSubmitterAccountId = swapSubmitterKp
          .accountId; // GAERW3OYAVYMZMPMVKHSCDS4ORFPLT5Z3YXA4VM3BVYEA2W7CG3V6YYB

      KeyPair aliceKp = KeyPair.fromSecretSeed(
          "SAAPYAPTTRZMCUZFPG3G66V4ZMHTK4TWA6NS7U4F7Z3IMUD52EK4DDEV");
      String aliceAccountId = aliceKp
          .accountId; // GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54

      KeyPair bobKp = KeyPair.fromSecretSeed(
          "SAEZSI6DY7AXJFIYA4PM6SIBNEYYXIEM2MSOTHFGKHDW32MBQ7KVO6EN");
      String bobAccountId = bobKp
          .accountId; // GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM

      String atomicSwapContractId =
          "828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c";
      String nativeTokenContractId =
          "d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813";
      String catTokenContractId =
          "8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67";

      Address addressAlice = Address.forAccountId(aliceAccountId);
      Address addressBob = Address.forAccountId(bobAccountId);
      Address addressSwapContract = Address.forContractId(atomicSwapContractId);

      XdrSCVal tokenABytes = XdrSCVal.forObject(
          XdrSCObject.forBytes(Util.hexToBytes(nativeTokenContractId)));
      XdrSCVal tokenBBytes = XdrSCVal.forObject(
          XdrSCObject.forBytes(Util.hexToBytes(catTokenContractId)));

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
          nativeTokenContractId, incrAllowFunctionName,
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
          catTokenContractId, incrAllowFunctionName,
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

      String status = SorobanServer.TRANSACTION_STATUS_PENDING;

      // poll until success or error
      while (status == SorobanServer.TRANSACTION_STATUS_PENDING) {
        await Future.delayed(const Duration(seconds: 3), () {});
        GetTransactionStatusResponse statusResponse = await sorobanServer
            .getTransactionStatus(sendResponse.transactionId!);
        assert(statusResponse.error == null);

        status = statusResponse.status!;
        if (status == SorobanServer.TRANSACTION_STATUS_ERROR) {
          assert(statusResponse.resultError != null);
          fail(statusResponse.resultError!.message!);
        } else if (status == SorobanServer.TRANSACTION_STATUS_SUCCESS) {
          assert(statusResponse.results != null);
          assert(statusResponse.results!.isNotEmpty);
          print("Result " + statusResponse.results![0].xdr);
        }
      }
    });
  });
}
