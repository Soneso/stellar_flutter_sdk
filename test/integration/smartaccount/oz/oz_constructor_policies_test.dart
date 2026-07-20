// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Testnet integration tests for constructor-time policy installation: a
// wallet deployed with `policies` installs them on the Default context rule
// via the contract constructor.
//
// The deploy transaction is signed by the deployer, not the passkey, so the
// passkey side is a MockWebAuthnProvider carrying a valid secp256r1 point
// (the curve's generator) as the public key: it passes client-side curve
// validation and the on-chain verifier's key canonicalization, and is never
// used for signing here. A random credential ID gives every run a fresh
// derived contract address.

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../../tests_util.dart';
import '../../../unit/smartaccount/core/mock_webauthn_provider.dart';

void main() {
  const rpcUrl = 'https://soroban-testnet.stellar.org';
  const accountWasmHash =
      '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28';
  const webauthnVerifier =
      'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY';

  /// SimpleThreshold policy contract deployed on testnet.
  const thresholdPolicy =
      'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC';

  /// Uncompressed secp256r1 generator point: a valid on-curve public key.
  final p256GeneratorPubKey = Util.hexToBytes('04'
      '6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296'
      '4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5');

  final random = Random.secure();

  Uint8List randomBytes(int length) => Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)));

  Future<OZSmartAccountKit> createKit() async {
    final deployer = KeyPair.random();
    final sorobanServer = SorobanServer(rpcUrl);
    await fundTestAccountAndWaitForRpc(sorobanServer, deployer.accountId);

    final provider = MockWebAuthnProvider();
    provider.registrationResult = WebAuthnRegistrationResult(
      credentialId: randomBytes(16),
      publicKey: p256GeneratorPubKey,
      attestationObject: MockWebAuthnProvider.testAttestationObject(),
      transports: const ['internal'],
      deviceType: 'multiDevice',
      backedUp: true,
    );

    return OZSmartAccountKit.create(
      config: OZSmartAccountConfig(
        rpcUrl: rpcUrl,
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: accountWasmHash,
        webauthnVerifierAddress: webauthnVerifier,
        webauthnProvider: provider,
        deployerKeypair: deployer,
        sorobanServer: sorobanServer,
      ),
    );
  }

  test('deploy with threshold-one policy installs it on the default rule',
      timeout: const Timeout(Duration(minutes: 5)), () async {
    final kit = await createKit();
    try {
      final result = await kit.walletOperations.createWallet(
        userName: 'Constructor Policy Test',
        autoSubmit: true,
        policies: <String, OZPolicyInstallParams>{
          thresholdPolicy: const OZSimpleThresholdPolicyParams(threshold: 1),
        },
      );
      expect(result.contractId, isNotEmpty,
          reason: 'deploy must yield a contract address');

      // Read back the Default rule and verify the policy was installed at
      // construction.
      final rules = await kit.contextRuleManager.listContextRules();
      final defaultRule = rules.firstWhere((rule) => rule.id == 0);
      expect(defaultRule.policies, contains(thresholdPolicy),
          reason: 'Default rule must carry the constructor-installed '
              'threshold policy, got: ${defaultRule.policies}');
    } finally {
      await kit.close();
    }
  });

  test(
      'deploy with two-of-one threshold fails at simulation with '
      'InvalidThreshold', timeout: const Timeout(Duration(minutes: 5)),
      () async {
    final kit = await createKit();
    try {
      // A threshold of 2 exceeds the Default rule's single initial signer;
      // the policy contract rejects the install during deploy simulation.
      Object? thrown;
      try {
        await kit.walletOperations.createWallet(
          userName: 'Constructor Policy Negative Test',
          autoSubmit: false,
          policies: <String, OZPolicyInstallParams>{
            thresholdPolicy: const OZSimpleThresholdPolicyParams(threshold: 2),
          },
        );
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isA<SmartAccountTransactionException>(),
          reason: 'createWallet must fail when the threshold exceeds the '
              'signer count, got: $thrown');
      final exception = thrown as SmartAccountTransactionException;
      final decoded = OZContractErrorCodes.decodeFromMessage(exception.message);
      expect(decoded, isNotNull,
          reason: 'simulation error must carry a decodable contract error, '
              'got: ${exception.message}');
      expect(decoded!.code, 3201);
      expect(decoded.name, 'InvalidThreshold');
      expect(decoded.contract, 'SimpleThresholdError');
    } finally {
      await kit.close();
    }
  });
}
