// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Integration tests for Protocol 27 (CAP-71) ADDRESS_V2 credential arm.
//
// These tests require a testnet running Protocol 27 and a deployed Soroban auth
// contract. They are skipped until the testnet is upgraded (target: 2026-06-18).
// To run against a live testnet, remove the skip string from each test.
//
// The tests do not require the unreleased RPC 'authV2' flag. When the RPC
// returns ADDRESS entries (legacy), the arm check accepts both arms.
//
// Each test deploys its own contract instance for independence.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../tests_util.dart';

/// Remove this skip string once testnet runs Protocol 27.
const _skipUntilP27 =
    'Skipped: testnet must run Protocol 27 before these tests can pass';

void main() {
  const testOn = 'testnet';
  final network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;
  final rpcUrl = testOn == 'testnet'
      ? 'https://soroban-testnet.stellar.org'
      : 'https://rpc-futurenet.stellar.org';
  final sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;

  const authContractPath = 'test/wasm/soroban_auth_contract.wasm';

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Future<void> fundAccount(String accountId) async {
    try {
      await sdk.accounts.account(accountId);
    } catch (_) {
      if (testOn == 'testnet') {
        await FriendBot.fundTestAccount(accountId);
      } else {
        await FuturenetFriendBot.fundTestAccount(accountId);
      }
    }
  }

  Future<GetTransactionResponse> pollUntilDone(
      SorobanServer server, String transactionId) async {
    var status = GetTransactionResponse.STATUS_NOT_FOUND;
    GetTransactionResponse? response;
    while (status == GetTransactionResponse.STATUS_NOT_FOUND) {
      await Future.delayed(const Duration(seconds: 3));
      response = await server.getTransaction(transactionId);
      assert(response.error == null,
          'getTransaction returned an error: ${response.error}');
      status = response.status!;
      if (status == GetTransactionResponse.STATUS_FAILED) {
        fail('Transaction $transactionId failed: ${response.resultXdr}');
      }
    }
    return response!;
  }

  /// Installs and deploys the auth contract; returns contractId.
  Future<String> deployAuthContract(
      SorobanServer server, KeyPair submitterKp) async {
    final Uint8List wasmBytes = await loadContractCode(authContractPath);

    // --- Upload wasm ---
    Account? account = await server.getAccount(submitterKp.accountId);
    assert(account != null);

    InvokeHostFunctionOperation uploadOp =
        InvokeHostFuncOpBuilder(UploadContractWasmHostFunction(wasmBytes))
            .build();
    Transaction uploadTx =
        TransactionBuilder(account!).addOperation(uploadOp).build();

    var simUpload =
        await server.simulateTransaction(SimulateTransactionRequest(uploadTx));
    assert(!simUpload.isErrorResponse);
    assert(simUpload.transactionData != null);

    uploadTx.sorobanTransactionData = simUpload.transactionData;
    uploadTx.addResourceFee(simUpload.minResourceFee!);
    uploadTx.sign(submitterKp, network);

    final sendUpload = await server.sendTransaction(uploadTx);
    assert(sendUpload.hash != null);
    final uploadResult = await pollUntilDone(server, sendUpload.hash!);
    final wasmId = uploadResult.getWasmId();
    assert(wasmId != null, 'wasm upload did not return a wasmId');

    // --- Deploy contract ---
    account = await server.getAccount(submitterKp.accountId);
    assert(account != null);

    final deployFn = CreateContractWithConstructorHostFunction(
        Address.forAccountId(submitterKp.accountId), wasmId!, []);
    InvokeHostFunctionOperation deployOp =
        InvokeHostFuncOpBuilder(deployFn).build();
    Transaction deployTx =
        TransactionBuilder(account!).addOperation(deployOp).build();

    var simDeploy =
        await server.simulateTransaction(SimulateTransactionRequest(deployTx));
    assert(!simDeploy.isErrorResponse);
    assert(simDeploy.transactionData != null);

    deployTx.sorobanTransactionData = simDeploy.transactionData;
    deployTx.addResourceFee(simDeploy.minResourceFee!);
    deployTx.setSorobanAuth(simDeploy.sorobanAuth);
    deployTx.sign(submitterKp, network);

    final sendDeploy = await server.sendTransaction(deployTx);
    assert(sendDeploy.hash != null);
    final deployResult = await pollUntilDone(server, sendDeploy.hash!);
    final contractId = deployResult.getCreatedContractId();
    assert(contractId != null, 'contract deploy did not return a contractId');
    return contractId!;
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  // Test 1: ADDRESS_V2 arm round-trip.
  //
  // Builds an invocation of the auth contract with authV2=true, simulates,
  // inspects the returned auth entry arm (accepts both ADDRESS and ADDRESS_V2
  // for compatibility with legacy RPC), signs, and submits.
  test(
    'ADDRESS_V2 arm round-trip: simulate, inspect arm, sign, submit',
    () async {
      final server = SorobanServer(rpcUrl);
      server.enableLogging = true;

      final submitterKp = KeyPair.random();
      final invokerKp = KeyPair.random();
      await fundAccount(submitterKp.accountId);
      await fundAccount(invokerKp.accountId);

      final contractId = await deployAuthContract(server, submitterKp);

      final clientOptions = ClientOptions(
        sourceAccountKeyPair: invokerKp,
        contractId: contractId,
        network: network,
        rpcUrl: rpcUrl,
        enableServerLogging: true,
      );
      final assembled = await AssembledTransaction.build(
        options: AssembledTransactionOptions(
          clientOptions: clientOptions,
          methodOptions: MethodOptions(authV2: true),
          method: 'invoker_auth',
          arguments: [
            XdrSCVal.forU128Parts(BigInt.zero, BigInt.from(42)),
            Address.forAccountId(invokerKp.accountId).toXdrSCVal(),
          ],
        ),
      );

      // Inspect arm of each returned auth entry.
      final ops = assembled.tx!.operations;
      if (ops.isNotEmpty && ops.first is InvokeHostFunctionOperation) {
        for (final entry
            in (ops.first as InvokeHostFunctionOperation).auth) {
          final arm = entry.credentials.arm;
          assert(
            arm ==
                    XdrSorobanCredentialsType
                        .SOROBAN_CREDENTIALS_ADDRESS ||
                arm ==
                    XdrSorobanCredentialsType
                        .SOROBAN_CREDENTIALS_ADDRESS_V2 ||
                arm ==
                    XdrSorobanCredentialsType
                        .SOROBAN_CREDENTIALS_SOURCE_ACCOUNT,
            'Unexpected credential arm: $arm',
          );
        }
      }

      final needsSigning = assembled.needsNonInvokerSigningBy();
      if (needsSigning.isNotEmpty) {
        await assembled.signAuthEntries(signerKeyPair: invokerKp);
      }
      assembled.sign();
      final response = await assembled.send();
      assert(response.status == GetTransactionResponse.STATUS_SUCCESS,
          'Expected SUCCESS, got ${response.status}');
    },
    skip: _skipUntilP27,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  // Test 2: ADDRESS_V2 entry uses address-bound preimage envelope type.
  //
  // After simulation with authV2=true, verifies that an ADDRESS_V2 entry uses
  // ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS (CAP-71) and an ADDRESS
  // entry uses the legacy ENVELOPE_TYPE_SOROBAN_AUTHORIZATION.
  test(
    'ADDRESS_V2 entry uses address-bound preimage (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS)',
    () async {
      final server = SorobanServer(rpcUrl);
      final submitterKp = KeyPair.random();
      final invokerKp = KeyPair.random();
      await fundAccount(submitterKp.accountId);
      await fundAccount(invokerKp.accountId);

      final contractId = await deployAuthContract(server, submitterKp);

      final assembled = await AssembledTransaction.build(
        options: AssembledTransactionOptions(
          clientOptions: ClientOptions(
            sourceAccountKeyPair: invokerKp,
            contractId: contractId,
            network: network,
            rpcUrl: rpcUrl,
          ),
          methodOptions: MethodOptions(authV2: true),
          method: 'invoker_auth',
          arguments: [
            XdrSCVal.forU128Parts(BigInt.zero, BigInt.from(1)),
            Address.forAccountId(invokerKp.accountId).toXdrSCVal(),
          ],
        ),
      );

      final ops = assembled.tx!.operations;
      if (ops.isEmpty || ops.first is! InvokeHostFunctionOperation) {
        return;
      }
      for (final entry
          in (ops.first as InvokeHostFunctionOperation).auth) {
        final arm = entry.credentials.arm;
        if (arm ==
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2) {
          final preimage = entry.buildPreimage(network);
          assert(
            preimage.discriminant ==
                XdrEnvelopeType
                    .ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS,
            'ADDRESS_V2 must use address-bound preimage envelope type',
          );
        } else if (arm ==
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS) {
          final preimage = entry.buildPreimage(network);
          assert(
            preimage.discriminant ==
                XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
            'ADDRESS must use legacy preimage envelope type',
          );
        }
      }
    },
    skip: _skipUntilP27,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  // Test 3: Signed ADDRESS_V2 entry survives XDR round-trip intact.
  //
  // Signs the returned ADDRESS_V2 entry and verifies that arm and non-void
  // signature survive a toBase64EncodedXdrString / fromBase64EncodedXdr cycle.
  test(
    'ADDRESS_V2 signed entry survives XDR round-trip',
    () async {
      final server = SorobanServer(rpcUrl);
      final submitterKp = KeyPair.random();
      final invokerKp = KeyPair.random();
      await fundAccount(submitterKp.accountId);
      await fundAccount(invokerKp.accountId);

      final contractId = await deployAuthContract(server, submitterKp);

      final assembled = await AssembledTransaction.build(
        options: AssembledTransactionOptions(
          clientOptions: ClientOptions(
            sourceAccountKeyPair: invokerKp,
            contractId: contractId,
            network: network,
            rpcUrl: rpcUrl,
          ),
          methodOptions: MethodOptions(authV2: true),
          method: 'invoker_auth',
          arguments: [
            XdrSCVal.forU128Parts(BigInt.zero, BigInt.from(7)),
            Address.forAccountId(invokerKp.accountId).toXdrSCVal(),
          ],
        ),
      );

      final ops = assembled.tx!.operations;
      if (ops.isEmpty || ops.first is! InvokeHostFunctionOperation) {
        return;
      }

      await assembled.signAuthEntries(signerKeyPair: invokerKp);

      for (final entry
          in (ops.first as InvokeHostFunctionOperation).auth) {
        if (entry.credentials.arm !=
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2) {
          continue;
        }
        final b64 = entry.toBase64EncodedXdrString();
        final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(b64);

        assert(
          restored.credentials.arm ==
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
          'Arm must be preserved through XDR round-trip',
        );
        assert(
          restored.credentials.addressV2Credentials != null,
          'addressV2Credentials must be non-null after round-trip',
        );
        assert(
          restored.credentials.addressV2Credentials!.signature.discriminant !=
              XdrSCValType.SCV_VOID,
          'Signature must be non-void after signing and XDR round-trip',
        );
      }
    },
    skip: _skipUntilP27,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
