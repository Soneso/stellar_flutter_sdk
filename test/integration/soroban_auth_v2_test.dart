// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Integration tests for Protocol 27 (CAP-71) ADDRESS_V2 credential arm.
//
// These tests require a testnet running Protocol 27 with a stellar-rpc that
// honors useUpgradedAuth (v27.1.0+), and a deployed Soroban auth contract.
//
// Simulation with useUpgradedAuth set returns ADDRESS_V2 credential entries;
// each test hard-asserts that the server returned the V2 arm before exercising
// the address-bound signing path.
//
// Each test deploys its own contract instance for independence.

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
      await fundTestAccountAndWaitForRpc(sorobanServer, accountId,
          useFuturenet: testOn != 'testnet');
    }
  }

  /// Installs and deploys the auth contract via the high-level client; returns contractId.
  Future<String> deployAuthContract(KeyPair submitterKp) async {
    final Uint8List wasmBytes = await loadContractCode(authContractPath);
    final wasmHash = await SorobanClient.install(
      installRequest: InstallRequest(
        wasmBytes: wasmBytes,
        sourceAccountKeyPair: submitterKp,
        network: network,
        rpcUrl: rpcUrl,
        server: sorobanServer,
      ),
    );
    final client = await SorobanClient.deploy(
      deployRequest: DeployRequest(
        sourceAccountKeyPair: submitterKp,
        network: network,
        rpcUrl: rpcUrl,
        wasmHash: wasmHash,
        server: sorobanServer,
      ),
    );
    return client.getContractId();
  }

  /// Hard-asserts that simulation returned at least one ADDRESS_V2 auth entry
  /// for [signerAccountId] — proving the useUpgradedAuth flag was sent on the
  /// wire and honored by the server (requires stellar-rpc v27.1.0+).
  void assertSimulationReturnedAddressV2(
      AssembledTransaction assembled, String signerAccountId) {
    final tx = assembled.tx;
    assert(tx != null, 'Expected an assembled transaction');
    final ops = tx!.operations;
    assert(ops.isNotEmpty && ops.first is InvokeHostFunctionOperation,
        'Expected an InvokeHostFunctionOperation');
    final authEntries = (ops.first as InvokeHostFunctionOperation).auth;
    final hasV2 = authEntries.any((e) =>
        e.credentials.arm ==
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2 &&
        e.credentials.addressV2Credentials?.address.accountId ==
            signerAccountId);
    assert(
        hasV2,
        'Simulation must return an ADDRESS_V2 auth entry for the invoker when '
        'useUpgradedAuth is set (requires stellar-rpc v27.1.0+)');
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  // Test 1: ADDRESS_V2 arm round-trip.
  //
  // The required signer (the invoker) differs from the transaction source, so
  // simulation with useUpgradedAuth returns an ADDRESS_V2 auth entry for the
  // invoker, which is then signed with the address-bound preimage and submitted.
  test(
    'ADDRESS_V2 arm round-trip: build, sign, submit',
    () async {
      final sourceKp = KeyPair.random();
      final invokerKp = KeyPair.random();
      await fundAccount(sourceKp.accountId);
      await fundAccount(invokerKp.accountId);

      final contractId = await deployAuthContract(sourceKp);

      final clientOptions = ClientOptions(
        sourceAccountKeyPair: sourceKp,
        contractId: contractId,
        network: network,
        rpcUrl: rpcUrl,
        server: sorobanServer,
        enableServerLogging: true,
      );
      final assembled = await AssembledTransaction.build(
        options: AssembledTransactionOptions(
          clientOptions: clientOptions,
          // useUpgradedAuth requests ADDRESS_V2 credential entries; stellar-rpc
          // v27.1.0+ honors the flag in recording mode.
          methodOptions: MethodOptions(useUpgradedAuth: true),
          method: 'increment',
          arguments: [
            Address.forAccountId(invokerKp.accountId).toXdrSCVal(),
            XdrSCVal.forU32(42),
          ],
        ),
      );

      // The invoker differs from the source, so simulation must return the
      // invoker's entry with the ADDRESS_V2 arm already set — this proves the
      // flag was sent on the wire and honored by the server.
      assertSimulationReturnedAddressV2(assembled, invokerKp.accountId);

      final needsSigning = assembled.needsNonInvokerSigningBy();
      assert(needsSigning.isNotEmpty,
          'The invoker must be required to sign the ADDRESS_V2 auth entry');
      await assembled.signAuthEntries(signerKeyPair: invokerKp);

      assembled.sign();
      final response = await assembled.send();
      assert(response.status == GetTransactionResponse.STATUS_SUCCESS,
          'Expected SUCCESS, got ${response.status}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  // Test 2: ADDRESS_V2 entry uses the address-bound preimage envelope type.
  //
  // Simulation with useUpgradedAuth returns the invoker's entry as ADDRESS_V2;
  // verifies that an ADDRESS_V2 entry uses
  // ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS (CAP-71) and any remaining
  // ADDRESS entry uses the legacy ENVELOPE_TYPE_SOROBAN_AUTHORIZATION.
  test(
    'ADDRESS_V2 entry uses address-bound preimage (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS)',
    () async {
      final sourceKp = KeyPair.random();
      final invokerKp = KeyPair.random();
      await fundAccount(sourceKp.accountId);
      await fundAccount(invokerKp.accountId);

      final contractId = await deployAuthContract(sourceKp);

      final assembled = await AssembledTransaction.build(
        options: AssembledTransactionOptions(
          clientOptions: ClientOptions(
            sourceAccountKeyPair: sourceKp,
            contractId: contractId,
            network: network,
            rpcUrl: rpcUrl,
            server: sorobanServer,
          ),
          // useUpgradedAuth requests ADDRESS_V2 credential entries; stellar-rpc
          // v27.1.0+ honors the flag in recording mode.
          methodOptions: MethodOptions(useUpgradedAuth: true),
          method: 'increment',
          arguments: [
            Address.forAccountId(invokerKp.accountId).toXdrSCVal(),
            XdrSCVal.forU32(1),
          ],
        ),
      );

      // Simulation must return the invoker's entry as ADDRESS_V2 before the
      // preimage is inspected.
      assertSimulationReturnedAddressV2(assembled, invokerKp.accountId);

      final invokeOp =
          assembled.tx!.operations.first as InvokeHostFunctionOperation;
      var checkedV2 = false;
      for (final entry in invokeOp.auth) {
        final arm = entry.credentials.arm;
        if (arm ==
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2) {
          checkedV2 = true;
          final preimage = entry.buildPreimage(network);
          assert(
            preimage.discriminant ==
                XdrEnvelopeType
                    .ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS,
            'ADDRESS_V2 must use the address-bound preimage envelope type',
          );
        } else if (arm ==
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS) {
          final preimage = entry.buildPreimage(network);
          assert(
            preimage.discriminant ==
                XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION,
            'ADDRESS must use the legacy preimage envelope type',
          );
        }
      }
      assert(checkedV2,
          'Expected an ADDRESS_V2 auth entry to verify the address-bound preimage');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  // Test 3: Signed ADDRESS_V2 entry survives an XDR round-trip intact.
  //
  // Signs the simulation-returned ADDRESS_V2 entry and verifies that the arm and
  // the non-void signature survive a toBase64EncodedXdrString /
  // fromBase64EncodedXdr cycle.
  test(
    'ADDRESS_V2 signed entry survives XDR round-trip',
    () async {
      final sourceKp = KeyPair.random();
      final invokerKp = KeyPair.random();
      await fundAccount(sourceKp.accountId);
      await fundAccount(invokerKp.accountId);

      final contractId = await deployAuthContract(sourceKp);

      final assembled = await AssembledTransaction.build(
        options: AssembledTransactionOptions(
          clientOptions: ClientOptions(
            sourceAccountKeyPair: sourceKp,
            contractId: contractId,
            network: network,
            rpcUrl: rpcUrl,
            server: sorobanServer,
          ),
          // useUpgradedAuth requests ADDRESS_V2 credential entries; stellar-rpc
          // v27.1.0+ honors the flag in recording mode.
          methodOptions: MethodOptions(useUpgradedAuth: true),
          method: 'increment',
          arguments: [
            Address.forAccountId(invokerKp.accountId).toXdrSCVal(),
            XdrSCVal.forU32(7),
          ],
        ),
      );

      // Simulation must return the invoker's entry as ADDRESS_V2; sign it with
      // the address-bound preimage.
      assertSimulationReturnedAddressV2(assembled, invokerKp.accountId);
      await assembled.signAuthEntries(signerKeyPair: invokerKp);

      final invokeOp =
          assembled.tx!.operations.first as InvokeHostFunctionOperation;
      var roundTripped = false;
      for (final entry in invokeOp.auth) {
        if (entry.credentials.arm !=
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2) {
          continue;
        }
        roundTripped = true;
        final b64 = entry.toBase64EncodedXdrString();
        final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(b64);

        assert(
          restored.credentials.arm ==
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
          'Arm must be preserved through the XDR round-trip',
        );
        assert(
          restored.credentials.addressV2Credentials != null,
          'addressV2Credentials must be non-null after the round-trip',
        );
        assert(
          restored.credentials.addressV2Credentials!.signature.discriminant !=
              XdrSCValType.SCV_VOID,
          'Signature must be non-void after signing and the XDR round-trip',
        );
      }
      assert(roundTripped,
          'Expected a signed ADDRESS_V2 entry to round-trip');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
