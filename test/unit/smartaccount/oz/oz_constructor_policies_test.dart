// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/core/sc_val_host_order.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// Constructor-time policy installation: the config-level
// OZSmartAccountConfig.defaultPolicies default and the per-call `policies`
// override on OZWalletOperations.createWallet and
// OZWalletOperations.deployPendingCredential, plus the wiring of the
// resolved map into the deploy transaction's constructor arguments.

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

Uint8List _bytes(int length, [int seed = 0]) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (seed + i) & 0xFF;
  }
  return out;
}

// secp256r1 generator point G (valid P-256 point on the curve).
final BigInt _gx = BigInt.parse(
  '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
  radix: 16,
);
final BigInt _gy = BigInt.parse(
  '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5',
  radix: 16,
);

Uint8List _bigIntToBytes(BigInt value, int len) {
  var hex = value.toRadixString(16);
  if (hex.length.isOdd) hex = '0$hex';
  final raw = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < raw.length; i++) {
    raw[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  if (raw.length == len) return raw;
  final padded = Uint8List(len);
  padded.setRange(len - raw.length, len, raw);
  return padded;
}

/// A valid P-256 public key (the generator point G in uncompressed format).
Uint8List _validSecp256r1PublicKey() {
  final out = Uint8List(65);
  out[0] = 0x04;
  out.setRange(1, 33, _bigIntToBytes(_gx, 32));
  out.setRange(33, 65, _bigIntToBytes(_gy, 32));
  return out;
}

SimulateTransactionResponse _simResponseEmpty({int? minResourceFee}) {
  final r = SimulateTransactionResponse(<String, dynamic>{});
  r.results = <SimulateTransactionResult>[];
  r.minResourceFee = minResourceFee;
  return r;
}

Account _deployerAccount(KeyPair deployer, {int seq = 1}) {
  return Account(deployer.accountId, BigInt.from(seq));
}

/// Deterministic, valid policy contract C-address derived from [seed].
String _policyAddress(int seed) => StrKey.encodeContractId(
      Uint8List.fromList(List<int>.generate(32, (j) => (seed + j) & 0xFF)),
    );

OZPolicyInstallParams _installParams() =>
    const OZSimpleThresholdPolicyParams(threshold: 1);

Map<String, OZPolicyInstallParams> _policies(int n) => <String,
        OZPolicyInstallParams>{
      for (var i = 0; i < n; i++) _policyAddress(i): _installParams(),
    };

OZSmartAccountConfig _config({
  WebAuthnProvider? provider,
  Map<String, OZPolicyInstallParams> defaultPolicies =
      const <String, OZPolicyInstallParams>{},
}) {
  return OZSmartAccountConfig(
    rpcUrl: 'https://soroban-testnet.stellar.org',
    networkPassphrase: Network.TESTNET.networkPassphrase,
    accountWasmHash: '0' * 64,
    webauthnVerifierAddress: _contractA,
    webauthnProvider: provider,
    defaultPolicies: defaultPolicies,
  );
}

/// Queues a successful WebAuthn registration on [provider].
void _queueRegistration(RecordingWebAuthnProvider provider) {
  provider.registerResponses.add(WebAuthnRegistrationResult(
    credentialId: base64Url.decode(base64Url.normalize(_credentialIdB64)),
    publicKey: _validSecp256r1PublicKey(),
    attestationObject: _bytes(37, 0xAA),
  ));
}

/// Decodes the signed deploy envelope and returns the CreateContractV2
/// constructor arguments `[signers, policies]`.
List<XdrSCVal> _constructorArgs(String signedTransactionXdr) {
  final envelope =
      XdrTransactionEnvelope.fromEnvelopeXdrString(signedTransactionXdr);
  final operations = envelope.v1!.tx.operations;
  expect(operations, hasLength(1));
  final hostFunction = operations.single.body.invokeHostFunctionOp!.function;
  final createContractV2 = hostFunction.createContractV2;
  expect(createContractV2, isNotNull,
      reason: 'deploy must use the CreateContractV2 host function');
  return createContractV2!.constructorArgs;
}

/// The expected constructor encoding of a typed policies map.
List<int> _expectedPoliciesBytes(Map<String, OZPolicyInstallParams> policies) {
  return OZPolicyManager.scValToXdrBytes(
    OZPolicyManager.policiesToScVal(<String, XdrSCVal>{
      for (final entry in policies.entries) entry.key: entry.value.toScVal(),
    }),
  );
}

void main() {
  group('OZSmartAccountConfig.defaultPolicies', () {
    test('testConfig_defaultPolicies_defaultsEmpty', () {
      expect(_config().defaultPolicies, isEmpty);
    });

    test('testConfig_defaultPolicies_viaConstructorAndBuilder', () {
      final p = _policies(2);
      expect(_config(defaultPolicies: p).defaultPolicies, equals(p));

      final built = OZSmartAccountConfig.builder(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      ).defaultPolicies(p).build();
      expect(built.defaultPolicies, equals(p));
    });

    test('testConfig_defaultPolicies_notValidatedAtConstructionTime', () {
      // Constructing a config with an over-limit default map succeeds; the
      // map is validated when a wallet operation resolves it.
      expect(
        _config(defaultPolicies: _policies(OZConstants.maxPolicies + 1))
            .defaultPolicies,
        hasLength(OZConstants.maxPolicies + 1),
      );
    });

    test('testConfig_defaultPolicies_equalityAndCopyWith', () {
      final p = _policies(1);
      expect(_config(defaultPolicies: p), equals(_config(defaultPolicies: p)));
      expect(
        _config(defaultPolicies: p),
        isNot(equals(_config(defaultPolicies: _policies(2)))),
      );
      expect(
        _config(defaultPolicies: p).hashCode,
        equals(_config(defaultPolicies: p).hashCode),
      );

      final copied = _config().copyWith(defaultPolicies: p);
      expect(copied.defaultPolicies, equals(p));
      // Omitting the argument keeps the current value.
      expect(
        _config(defaultPolicies: p).copyWith(rpcUrl: 'https://other.test')
            .defaultPolicies,
        equals(p),
      );
    });
  });

  group('createWallet constructor-policy validation before the ceremony', () {
    test('testCreateWallet_invalidPerCallPolicies_throwsBeforeCeremony',
        () async {
      final provider = RecordingWebAuthnProvider();
      final kit = FakePipelineKit(config: _config(provider: provider));
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.createWallet(policies: <String, OZPolicyInstallParams>{
          'not-a-contract': _installParams(),
        }),
        throwsA(isA<SmartAccountInvalidAddress>()),
      );
      expect(provider.registerCalls, isEmpty,
          reason: 'policy validation must run before the passkey ceremony');
    });

    test('testCreateWallet_tooManyPerCallPolicies_throwsBeforeCeremony',
        () async {
      final provider = RecordingWebAuthnProvider();
      final kit = FakePipelineKit(config: _config(provider: provider));
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.createWallet(policies: _policies(OZConstants.maxPolicies + 1)),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
      expect(provider.registerCalls, isEmpty);
    });

    test('testCreateWallet_structurallyInvalidParams_throwsBeforeCeremony',
        () async {
      final provider = RecordingWebAuthnProvider();
      final kit = FakePipelineKit(config: _config(provider: provider));
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.createWallet(policies: <String, OZPolicyInstallParams>{
          _policyAddress(0):
              const OZSimpleThresholdPolicyParams(threshold: 0),
        }),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
      expect(provider.registerCalls, isEmpty,
          reason: 'install params are encoded before the passkey ceremony, '
              'so a structurally invalid value must not orphan a credential');
    });

    test('testCreateWallet_usesConfigDefaultWhenNoOverride', () async {
      // No per-call policies -> the invalid config default is used ->
      // throws before the ceremony.
      final provider = RecordingWebAuthnProvider();
      final kit = FakePipelineKit(
        config: _config(
          provider: provider,
          defaultPolicies: _policies(OZConstants.maxPolicies + 1),
        ),
      );
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.createWallet(),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
      expect(provider.registerCalls, isEmpty);
    });

    test('testCreateWallet_perCallOverridesInvalidConfigDefault', () async {
      // A valid per-call override supersedes an invalid config default:
      // validation passes and the ceremony proceeds to a successful build.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();
      _queueRegistration(provider);
      mock.getAccountResponses.add(_deployerAccount(deployer));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 500));

      final kit = FakePipelineKit(
        config: _config(
          provider: provider,
          defaultPolicies: _policies(OZConstants.maxPolicies + 1),
        ),
        sorobanServer: mock,
        deployer: deployer,
      );
      final ops = OZWalletOperations(kit);

      final result = await ops.createWallet(
        policies: const <String, OZPolicyInstallParams>{},
        autoSubmit: false,
      );

      expect(provider.registerCalls, hasLength(1),
          reason:
              'a valid per-call override must supersede the invalid config default');
      // The explicit empty override encodes the empty ScMap.
      final args = _constructorArgs(result.signedTransactionXdr);
      expect(args, hasLength(2));
      expect(
        OZPolicyManager.scValToXdrBytes(args[1]),
        equals(OZPolicyManager.scValToXdrBytes(
          XdrSCVal.forMap(const <XdrSCMapEntry>[]),
        )),
      );
    });
  });

  group('deployPendingCredential constructor-policy validation', () {
    test('testDeployPending_invalidPolicies_throwsBeforeCredentialLookup',
        () async {
      // Policy validation runs before the stored-credential lookup: an
      // unknown credential with an over-limit policies map fails with the
      // validation error, not with credential-not-found.
      final kit = FakePipelineKit(config: _config());
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.deployPendingCredential(
          credentialId: 'unknown-credential',
          policies: _policies(OZConstants.maxPolicies + 1),
        ),
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

  group('deploy transaction constructor-policies wiring', () {
    Future<OZCreateWalletResult> createWallet({
      Map<String, OZPolicyInstallParams>? policies,
      Map<String, OZPolicyInstallParams> defaultPolicies =
          const <String, OZPolicyInstallParams>{},
    }) async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();
      _queueRegistration(provider);
      mock.getAccountResponses.add(_deployerAccount(deployer));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 500));

      final kit = FakePipelineKit(
        config: _config(provider: provider, defaultPolicies: defaultPolicies),
        sorobanServer: mock,
        deployer: deployer,
      );
      return OZWalletOperations(kit).createWallet(
        policies: policies,
        autoSubmit: false,
      );
    }

    test('testCreateWallet_noPolicies_encodesEmptyMap', () async {
      final result = await createWallet();
      final args = _constructorArgs(result.signedTransactionXdr);
      expect(args, hasLength(2));
      expect(args[0].discriminant, equals(XdrSCValType.SCV_VEC));
      expect(
        OZPolicyManager.scValToXdrBytes(args[1]),
        equals(OZPolicyManager.scValToXdrBytes(
          XdrSCVal.forMap(const <XdrSCMapEntry>[]),
        )),
      );
    });

    test('testCreateWallet_perCallPolicies_reachConstructorArgs', () async {
      final p = _policies(2);
      final result = await createWallet(policies: p);
      final args = _constructorArgs(result.signedTransactionXdr);
      expect(
        OZPolicyManager.scValToXdrBytes(args[1]),
        equals(_expectedPoliciesBytes(p)),
      );
    });

    test('testCreateWallet_configDefaultPolicies_reachConstructorArgs',
        () async {
      final p = _policies(1);
      final result = await createWallet(defaultPolicies: p);
      final args = _constructorArgs(result.signedTransactionXdr);
      expect(
        OZPolicyManager.scValToXdrBytes(args[1]),
        equals(_expectedPoliciesBytes(p)),
      );
    });

    test('testCreateWallet_perCallPolicies_overrideConfigDefault', () async {
      final perCall = <String, OZPolicyInstallParams>{
        _policyAddress(7): _installParams(),
      };
      final configDefault = _policies(2);
      final result = await createWallet(
        policies: perCall,
        defaultPolicies: configDefault,
      );
      final encoded =
          OZPolicyManager.scValToXdrBytes(_constructorArgs(result.signedTransactionXdr)[1]);
      expect(encoded, equals(_expectedPoliciesBytes(perCall)));
      expect(encoded, isNot(equals(_expectedPoliciesBytes(configDefault))));
    });

    test('testDeployPendingCredential_policies_reachConstructorArgs',
        () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final credentialManager = StubCredentialManager();
      credentialManager.inject(OZStoredCredential(
        credentialId: _credentialIdB64,
        publicKey: _validSecp256r1PublicKey(),
        contractId: _contractA,
      ));
      mock.getAccountResponses.add(_deployerAccount(deployer));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 500));

      final kit = FakePipelineKit(
        config: _config(),
        sorobanServer: mock,
        deployer: deployer,
        credentialManager: credentialManager,
      );
      final ops = OZWalletOperations(kit);

      final p = _policies(2);
      final result = await ops.deployPendingCredential(
        credentialId: _credentialIdB64,
        autoSubmit: false,
        policies: p,
      );

      final args = _constructorArgs(result.signedTransactionXdr);
      expect(
        OZPolicyManager.scValToXdrBytes(args[1]),
        equals(_expectedPoliciesBytes(p)),
      );
    });

    test('testCreateWallet_policiesMap_isHostOrdered', () async {
      // Three policies inserted in descending host order must come out of
      // the constructor args in ascending host order, and the encoding must
      // not depend on the insertion order.
      final addresses = List<String>.generate(3, _policyAddress);
      final keyScVals = <String, XdrSCVal>{
        for (final a in addresses)
          a: XdrSCVal.forAddress(Address.forContractId(a).toXdr()),
      };
      addresses.sort(
        (a, b) => compareScValHostOrder(keyScVals[a]!, keyScVals[b]!),
      );
      final reversed = <String, OZPolicyInstallParams>{
        for (final a in addresses.reversed) a: _installParams(),
      };

      final result = await createWallet(policies: reversed);
      final policiesScVal = _constructorArgs(result.signedTransactionXdr)[1];

      final entries = policiesScVal.map!;
      expect(entries, hasLength(3));
      for (var i = 1; i < entries.length; i++) {
        expect(
          compareScValHostOrder(entries[i - 1].key, entries[i].key),
          lessThan(0),
          reason: 'ScMap keys must be strictly ascending in host order',
        );
      }

      // Insertion order does not leak into the encoding.
      final inOrder = <String, OZPolicyInstallParams>{
        for (final a in addresses) a: _installParams(),
      };
      expect(
        OZPolicyManager.scValToXdrBytes(policiesScVal),
        equals(_expectedPoliciesBytes(inOrder)),
      );
    });
  });
}
