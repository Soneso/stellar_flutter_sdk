// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Integration test for the Protocol 27 (CAP-71) ADDRESS_WITH_DELEGATES credential arm.
//
// Deploys a modular custom account whose __check_auth carries no signature of its
// own and forwards authorization to its registered delegate signers, plus the
// standard auth (increment) contract. The increment call is invoked with the
// modular account as the authorizing address, so the host calls the modular
// account's __check_auth, which delegates to a registered G-account signer.
//
// Simulation returns a legacy ADDRESS entry for the modular account; it is
// converted to ADDRESS_WITH_DELEGATES client-side (preserving the simulated
// nonce), the delegate node is signed, and the transaction is re-simulated in
// enforcing mode so the modular account's __check_auth runs and its footprint is
// captured before submission. Both contracts are deployed with the high-level
// SorobanClient; the delegated-auth invocation is driven at the SorobanServer
// level.
//
// Requires a testnet running Protocol 27.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../tests_util.dart';

void main() {
  const testOn = 'testnet';
  final network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;
  final rpcUrl = testOn == 'testnet'
      ? 'https://soroban-testnet.stellar.org'
      : 'https://rpc-futurenet.stellar.org';
  final sorobanServer = SorobanServer(rpcUrl);
  sorobanServer.enableLogging = true;
  final sdk = testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;

  const modularAccountPath = 'test/wasm/soroban_modular_account_contract.wasm';
  const authContractPath = 'test/wasm/soroban_auth_contract.wasm';

  Future<void> fundAccount(String accountId) async {
    try {
      await sdk.accounts.account(accountId);
    } catch (_) {
      await fundTestAccountAndWaitForRpc(sorobanServer, accountId,
          useFuturenet: testOn != 'testnet');
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

  // ADDRESS_WITH_DELEGATES round-trip.
  //
  // The authorizing address is the modular custom account (a C-address). Its
  // __check_auth verifies no signature of its own and instead delegates to the
  // registered G-account, whose real signature the host verifies.
  test(
    'ADDRESS_WITH_DELEGATES round-trip: deploy modular account, delegate-sign, enforce re-simulate, submit',
    () async {
      final submitterKp = KeyPair.random();
      final delegateKp = KeyPair.random();
      await fundAccount(submitterKp.accountId);
      await fundAccount(delegateKp.accountId);

      // Deploy the modular custom account (registering the delegate as an allowed
      // signer) and the auth (increment) business contract, both via the
      // high-level client.
      final Uint8List modularWasm = await loadContractCode(modularAccountPath);
      final modularWasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: modularWasm,
          sourceAccountKeyPair: submitterKp,
          network: network,
          rpcUrl: rpcUrl,
          server: sorobanServer,
        ),
      );
      final signersArg = XdrSCVal.forVec(
          [Address.forAccountId(delegateKp.accountId).toXdrSCVal()]);
      final modularClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          sourceAccountKeyPair: submitterKp,
          network: network,
          rpcUrl: rpcUrl,
          wasmHash: modularWasmHash,
          constructorArgs: [signersArg],
          server: sorobanServer,
        ),
      );
      final modularAccountId = modularClient.getContractId();

      final Uint8List authWasm = await loadContractCode(authContractPath);
      final authWasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: authWasm,
          sourceAccountKeyPair: submitterKp,
          network: network,
          rpcUrl: rpcUrl,
          server: sorobanServer,
        ),
      );
      final authClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          sourceAccountKeyPair: submitterKp,
          network: network,
          rpcUrl: rpcUrl,
          wasmHash: authWasmHash,
          server: sorobanServer,
        ),
      );
      final authContractId = authClient.getContractId();

      // increment(user = modular account, value = 1) requires the modular
      // account's authorization, so the host invokes its __check_auth, which
      // delegates to the registered G-account.
      Account? account = await sorobanServer.getAccount(submitterKp.accountId);
      assert(account != null);
      final invokeFn = InvokeContractHostFunction(
        authContractId,
        'increment',
        arguments: [
          Address.forContractId(modularAccountId).toXdrSCVal(),
          XdrSCVal.forU32(1),
        ],
      );
      final invokeOp = InvokeHostFuncOpBuilder(invokeFn).build();
      final tx = TransactionBuilder(account!).addOperation(invokeOp).build();

      // Recording-mode simulation: returns the legacy ADDRESS authorization entry
      // for the modular account (with the RPC-assigned nonce). __check_auth is not
      // executed in this pass.
      final sim = await sorobanServer.simulateTransaction(SimulateTransactionRequest(tx));
      assert(!sim.isErrorResponse, 'simulation error: ${sim.error}');
      final auth = sim.sorobanAuth;
      assert(auth != null && auth.isNotEmpty,
          'simulation should return authorization entries');
      assert(auth!.length == 1,
          'increment should require exactly one authorization (the modular account)');

      final latest = await sorobanServer.getLatestLedger();
      final expirationLedger = latest.sequence! + 100;

      // Convert each address-based entry to the ADDRESS_WITH_DELEGATES arm
      // (preserving the simulated nonce), attach the delegate, and sign only the
      // delegate node. The top-level signature stays void: the modular account
      // verifies no signature of its own and authorizes through its delegate.
      final signedAuth = <SorobanAuthorizationEntry>[];
      for (final entry in auth!) {
        final arm = entry.credentials.arm;
        if (arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS ||
            arm == XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2) {
          final withDelegates = SorobanAuthorizationEntry.withDelegates(
            entry,
            [SorobanDelegateDescriptor(delegateKp.accountId)],
            expirationLedger,
          );
          withDelegates.sign(delegateKp, network,
              forAddress: delegateKp.accountId);
          signedAuth.add(withDelegates);
        } else {
          signedAuth.add(entry);
        }
      }

      // A WITH_DELEGATES entry must be present with a void top-level signature and
      // a signed delegate node for the G-account.
      final wdEntries = signedAuth
          .where((e) =>
              e.credentials.arm ==
              XdrSorobanCredentialsType
                  .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES)
          .toList();
      assert(wdEntries.length == 1,
          'Expected exactly one ADDRESS_WITH_DELEGATES auth entry');
      final wrapper = wdEntries.first.credentials.addressWithDelegatesCredentials!;
      assert(
        wrapper.addressCredentials.signature.discriminant ==
            XdrSCValType.SCV_VOID,
        'The top-level signature must remain void (the modular account signs nothing itself)',
      );
      assert(wrapper.delegates.length == 1,
          'Exactly one delegate node should be attached');
      assert(
        wrapper.delegates.first.signature.discriminant != XdrSCValType.SCV_VOID,
        'The delegate node must carry a signature after signing',
      );

      // Attach the signed auth and re-simulate in enforcing mode so the modular
      // account's __check_auth runs and its footprint reads (plus the delegate's
      // account entry) are captured. The recording-mode simulation above could not
      // have captured them.
      tx.setSorobanAuth(signedAuth);
      final reSim = await sorobanServer
          .simulateTransaction(SimulateTransactionRequest(tx, authMode: 'enforce'));
      assert(!reSim.isErrorResponse, 're-simulation error: ${reSim.error}');
      assert(reSim.transactionData != null);

      // Apply the enforcing simulation's footprint and resource fee; the
      // already-signed auth is kept.
      tx.sorobanTransactionData = reSim.transactionData;
      tx.addResourceFee(reSim.minResourceFee!);
      tx.sign(submitterKp, network);

      final send = await sorobanServer.sendTransaction(tx);
      assert(send.hash != null);
      final result = await pollUntilDone(sorobanServer, send.hash!);
      assert(result.status == GetTransactionResponse.STATUS_SUCCESS,
          'Expected SUCCESS, got ${result.status}');

      // increment returns the modular account's accumulated counter; a fresh
      // account starts at 0, so a single increment by 1 returns 1, proving the
      // delegated authorization succeeded.
      final resultValue = result.getResultValue();
      assert(resultValue?.u32 != null, 'increment should return a u32');
      assert(resultValue!.u32!.uint32 == 1,
          'increment should return the accumulated counter value (1)');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
