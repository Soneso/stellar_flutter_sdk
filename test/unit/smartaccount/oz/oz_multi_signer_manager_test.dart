// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_secure_nonce.dart';

import 'mock_oz_multi_signer_manager.dart';
import 'mock_oz_transaction_operations.dart';
import 'oz_pipeline_fixtures.dart';

/// A well-formed Stellar contract address used as the connected smart-account
/// contractId.
const String _validContractId =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';

/// A second well-formed contract address used as a target for execute calls.
const String _validTargetContract =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';

/// A well-formed Stellar G-address used as a recipient / delegated signer.
const String _validAccountAddress =
    'GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ';

/// Builds a fresh kit that is not connected to any wallet.
FakePipelineKit _buildKit() => FakePipelineKit();

/// Builds a fresh kit pre-connected to [_validContractId] so validations that
/// run after [requireConnected] can be reached.
FakePipelineKit _buildConnectedKit() => FakePipelineKit()
  ..setConnected(
    credentialId: 'test-credential-id',
    contractId: _validContractId,
  );

/// Constructs an [OZMultiSignerManager] bound to the supplied [kit].
///
/// The Flutter `OZMultiSignerManager` constructor accepts the
/// `OZSmartAccountWalletKitInterface` directly (as `_kit`), and
/// [FakePipelineKit] satisfies that interface. The kit's pipeline
/// `multiSignerManager` accessor throws by default; tests construct the
/// manager directly and exercise it as the call site would after the cast
/// `kit.multiSignerManager as OZMultiSignerManager`.
OZMultiSignerManager _manager(FakePipelineKit kit) => OZMultiSignerManager(kit);

/// Returns a passkey selected-signer with no credential data; sufficient to
/// drive validation paths that fail before any signing work.
SelectedSignerPasskey _passkeyStub() => const SelectedSignerPasskey();

void main() {

  group('multiSignerExecuteAndSubmit not-connected', () {
    test('notConnected_throwsWalletNotConnected', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.multiSignerExecuteAndSubmit(
          target: _validTargetContract,
          targetFn: 'vote',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  group('multiSignerExecuteAndSubmit target validation', () {
    test('targetIsGAddress_throwsInvalidAddress', () async {
      final manager = _manager(_buildConnectedKit());
      await expectLater(
        () => manager.multiSignerExecuteAndSubmit(
          target: _validAccountAddress, // G-address, not a contract
          targetFn: 'vote',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('targetTooShort_throwsInvalidAddress', () async {
      final manager = _manager(_buildConnectedKit());
      await expectLater(
        () => manager.multiSignerExecuteAndSubmit(
          target: 'CABC', // valid prefix but far too short
          targetFn: 'vote',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('targetIsBlank_throwsInvalidAddress', () async {
      final manager = _manager(_buildConnectedKit());
      await expectLater(
        () => manager.multiSignerExecuteAndSubmit(
          target: '',
          targetFn: 'vote',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  group('multiSignerExecuteAndSubmit function name validation', () {
    test('targetFnIsBlank_throwsInvalidInput', () async {
      final manager = _manager(_buildConnectedKit());
      try {
        await manager.multiSignerExecuteAndSubmit(
          target: _validTargetContract,
          targetFn: '',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        );
        fail('Expected InvalidInput');
      } on InvalidInput catch (e) {
        expect(
          e.message.contains('Function name'),
          isTrue,
          reason:
              "Exception message must reference 'Function name', got: ${e.message}",
        );
      }
    });

    test('targetFnIsWhitespaceOnly_throwsInvalidInput', () async {
      final manager = _manager(_buildConnectedKit());
      await expectLater(
        () => manager.multiSignerExecuteAndSubmit(
          target: _validTargetContract,
          targetFn: '   ',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('multiSignerExecuteAndSubmit signers validation', () {
    test('emptySigners_throwsInvalidInput', () async {
      final manager = _manager(_buildConnectedKit());
      try {
        await manager.multiSignerExecuteAndSubmit(
          target: _validTargetContract,
          targetFn: 'vote',
          selectedSigners: const <SelectedSigner>[],
        );
        fail('Expected InvalidInput');
      } on InvalidInput catch (e) {
        expect(
          e.message.contains('signer'),
          isTrue,
          reason:
              'Exception message must reference signers, got: ${e.message}',
        );
      }
    });
  });

  group('multiSignerTransfer not-connected', () {
    test('notConnected_throwsWalletNotConnected', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: _validAccountAddress,
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  // ==========================================================================
  // multiSignerTransfer — tokenContract validation
  //
  // The Flutter implementation validates the recipient first, then performs
  // the self-transfer guard, then converts amount to stroops, then routes
  // into multiSignerContractCall which calls requireContractAddress on the
  // target. The rows below pass a valid recipient that is distinct from the
  // connected contractId so the failure surfaces on the tokenContract leg
  // as InvalidAddress.
  // ==========================================================================

  group('multiSignerTransfer tokenContract validation', () {
    test('tokenContractIsGAddress_throwsInvalidAddress', () async {
      final manager = _manager(_buildConnectedKit());
      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _validAccountAddress, // G-address, not a contract
          recipient: _validAccountAddress,
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('tokenContractTooShort_throwsInvalidAddress', () async {
      final manager = _manager(_buildConnectedKit());
      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: 'CABC',
          recipient: _validAccountAddress,
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  group('multiSignerTransfer recipient validation', () {
    test('recipientInvalid_throwsInvalidAddress', () async {
      final manager = _manager(_buildConnectedKit());
      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: 'NOTAVALIDADDRESS',
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  // ==========================================================================
  // multiSignerTransfer — self-transfer guard
  //
  // The guard fires AFTER requireConnected AND requireStellarAddress(recipient).
  // ==========================================================================

  group('multiSignerTransfer self-transfer', () {
    test('recipientIsSelf_throwsInvalidInput', () async {
      final manager = _manager(_buildConnectedKit());
      try {
        await manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: _validContractId, // == connected contractId
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
        );
        fail('Expected InvalidInput');
      } on InvalidInput catch (e) {
        expect(
          e.message.toLowerCase().contains('self'),
          isTrue,
          reason:
              'Exception message must reference self-transfer, got: ${e.message}',
        );
      }
    });
  });

  // ==========================================================================
  // multiSignerTransfer — selectedSigners validation
  //
  // Empty signers must throw InvalidInput. The guard is reached after
  // requireConnected + requireStellarAddress(recipient) + self-transfer guard
  // + amount conversion + multiSignerContractCall's requireContractAddress
  // for the token contract; supplying valid distinct addresses ensures the
  // failure surfaces on the empty-signers leg.
  // ==========================================================================

  group('multiSignerTransfer signers validation', () {
    test('emptySigners_throwsInvalidInput', () async {
      final manager = _manager(_buildConnectedKit());
      try {
        await manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: _validAccountAddress,
          amount: '10',
          selectedSigners: const <SelectedSigner>[],
        );
        fail('Expected InvalidInput');
      } on InvalidInput catch (e) {
        expect(
          e.message.contains('signer'),
          isTrue,
          reason:
              'Exception message must reference signers, got: ${e.message}',
        );
      }
    });
  });

  // ==========================================================================
  // multiSignerTransfer — forceMethod parameter acceptance
  //
  // These rows verify the named parameter compiles and is accepted with each
  // documented value. The call still throws WalletNotConnected because the
  // kit is unconnected — that proves the signature accepts the parameter
  // without reaching the submission stage.
  // ==========================================================================

  group('multiSignerTransfer forceMethod parameter', () {
    test('forceMethodNullDefault_signatureCompiles', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: _validAccountAddress,
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
          // forceMethod not specified — defaults to null.
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('forceMethodRpc_signatureCompiles', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: _validAccountAddress,
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
          forceMethod: SubmissionMethod.rpc,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('forceMethodRelayer_signatureCompiles', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: _validAccountAddress,
          amount: '10',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
          forceMethod: SubmissionMethod.relayer,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  group('multiSignerExecuteAndSubmit forceMethod parameter', () {
    test('forceMethodNullDefault_signatureCompiles', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.multiSignerExecuteAndSubmit(
          target: _validTargetContract,
          targetFn: 'vote',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
          // forceMethod defaults to null.
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('forceMethodRpc_signatureCompiles', () async {
      final manager = _manager(_buildKit());
      await expectLater(
        () => manager.multiSignerExecuteAndSubmit(
          target: _validTargetContract,
          targetFn: 'vote',
          selectedSigners: <SelectedSigner>[_passkeyStub()],
          forceMethod: SubmissionMethod.rpc,
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  group('SelectedSigner sealed class', () {
    test('passkey_defaultFieldsAreNull', () {
      const signer = SelectedSignerPasskey();
      expect(signer.credentialId, isNull);
      expect(signer.credentialIdBytes, isNull);
      expect(signer.keyData, isNull);
    });

    test('passkey_fieldsAreSetCorrectly', () {
      final credBytes = Uint8List.fromList(<int>[1, 2, 3]);
      final keyData = Uint8List(97);
      for (var i = 0; i < keyData.length; i++) {
        keyData[i] = i & 0xFF;
      }
      final signer = SelectedSignerPasskey(
        credentialId: 'abc123',
        credentialIdBytes: credBytes,
        keyData: keyData,
      );
      expect(signer.credentialId, 'abc123');
      expect(signer.credentialIdBytes, isNotNull);
      expect(signer.credentialIdBytes, orderedEquals(credBytes));
      expect(signer.keyData, isNotNull);
      expect(signer.keyData, orderedEquals(keyData));
    });

    test('wallet_holdsAddress', () {
      const signer = SelectedSignerWallet(_validAccountAddress);
      expect(signer.address, _validAccountAddress);
    });

    test('wallet_dataClassEquality', () {
      const a = SelectedSignerWallet(_validAccountAddress);
      const b = SelectedSignerWallet(_validAccountAddress);
      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);
    });

    test('wallet_equalityWithNonConstInstances', () {
      // Non-const instances to exercise lines 140-141 in oz_selected_signer.dart.
      final a = SelectedSignerWallet(_validAccountAddress);
      final b = SelectedSignerWallet(_validAccountAddress);
      final c = SelectedSignerWallet(_validTargetContract);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
      expect(a == 'not-a-wallet', isFalse);
    });

    test('passkey_dataClassEquality_withNullFields', () {
      const a = SelectedSignerPasskey();
      const b = SelectedSignerPasskey();
      expect(a == b, isTrue);
    });
  });

  group('OZSecureNonce', () {
    test('generateBigInt_returnsNonNull', () {
      final v = OZSecureNonce.generateBigInt();
      expect(v, isNotNull);
    });

    test('bytes_negativeCount_throwsArgumentError', () {
      expect(() => OZSecureNonce.bytes(-1), throwsArgumentError);
    });

    test('bytes_zeroCount_returnsEmpty', () {
      final b = OZSecureNonce.bytes(0);
      expect(b, isEmpty);
    });
  });

  // ==========================================================================
  // Manager construction is reachable on the kit
  //
  // The Flutter SDK exposes the multi-signer manager via
  // `OZMultiSignerManager(kit)`. Tests construct the manager directly and
  // verify the construction is non-throwing and stable for repeat calls
  // against the same kit.
  // ==========================================================================

  group('manager construction', () {
    test('multiSignerManager_isNotNull', () {
      final manager = _manager(_buildKit());
      expect(manager, isNotNull);
    });

    test('multiSignerManager_independentInstances_distinct', () {
      // Each `OZMultiSignerManager(kit)` call yields a fresh instance; the
      // SDK does not memoise the manager on the kit interface, so callers
      // must hold the reference they construct rather than re-construct it.
      final kit = _buildKit();
      final first = _manager(kit);
      final second = _manager(kit);
      expect(identical(first, second), isFalse);
      expect(first, isA<OZMultiSignerManagerInterface>());
      expect(second, isA<OZMultiSignerManagerInterface>());
    });
  });

  // ==========================================================================
  // _generateNonce entropy expectations.
  //
  // The nonce must span the full signed 64-bit range. Probabilistically,
  // ~50% of draws should have the high bit set when the source is uniform.
  // ==========================================================================

  group('_generateNonce entropy', () {
    test('nonceHighBitSet_atLeastForty_percentOfThousandDraws', () {
      final manager = _manager(_buildKit());
      const draws = 1000;
      final twoTo63 = BigInt.one << 63;
      var negativeCount = 0;
      for (var i = 0; i < draws; i++) {
        final nonce = manager.generateNonceForTest().int64;
        // Negative when the unsigned representation has the high bit set
        // (the helper sign-extends values >= 2^63 into the negative range).
        if (nonce < BigInt.zero) {
          negativeCount++;
        }
        // Sanity: |nonce| must fit in signed 64-bit.
        expect(nonce.abs() <= twoTo63, isTrue,
            reason: 'Nonce $nonce overflows signed 64-bit range');
      }
      // Expected ~500/1000 negatives. The 40% lower bound below leaves
      // generous headroom for the binomial tails (per-test failure
      // probability < 1e-9 under a uniform 64-bit source).
      expect(
        negativeCount,
        greaterThanOrEqualTo(400),
        reason: 'Expected ~50% of nonces to have the high bit set, '
            'got $negativeCount/$draws negatives',
      );
    });

    test('nonceDistinctness_thousandDrawsAreUnique', () {
      // why: a 64-bit secure-random generator should produce no
      // duplicates over 1000 draws (collision probability ~ 2^-44).
      final manager = _manager(_buildKit());
      final seen = <BigInt>{};
      for (var i = 0; i < 1000; i++) {
        final n = manager.generateNonceForTest().int64;
        expect(seen.add(n), isTrue,
            reason: 'Duplicate nonce $n at draw $i — entropy collapse');
      }
    });
  });

  // ==========================================================================
  // SelectedSignerPasskey.transports propagation
  //
  // The transports list (when supplied alongside credentialIdBytes) must
  // flow into the WebAuthn AllowCredential entry built by
  // submitWithMultipleSigners so cross-device authentication picks the
  // correct authenticator transport.
  // ==========================================================================

  group('SelectedSignerPasskey transports', () {
    test('transports_assignedToFieldUnchanged', () {
      final transports = <String>['internal', 'hybrid'];
      final signer = SelectedSignerPasskey(
        credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3]),
        keyData: Uint8List(97),
        transports: transports,
      );
      expect(signer.transports, isNotNull);
      expect(signer.transports, orderedEquals(transports));
    });

    test(
        'transports_listIdentityIsPreservedThroughEqualityAndHash',
        () {
      final a = SelectedSignerPasskey(
        credentialIdBytes: Uint8List.fromList(<int>[9]),
        keyData: Uint8List(97),
        transports: const <String>['hybrid', 'usb'],
      );
      final b = SelectedSignerPasskey(
        credentialIdBytes: Uint8List.fromList(<int>[9]),
        keyData: Uint8List(97),
        transports: const <String>['hybrid', 'usb'],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('transports_differingListsBreakEquality', () {
      final a = SelectedSignerPasskey(
        credentialIdBytes: Uint8List.fromList(<int>[7]),
        keyData: Uint8List(97),
        transports: const <String>['internal'],
      );
      final b = SelectedSignerPasskey(
        credentialIdBytes: Uint8List.fromList(<int>[7]),
        keyData: Uint8List(97),
        transports: const <String>['hybrid'],
      );
      expect(a, isNot(equals(b)));
    });

    test(
        'transportsAllowCredentialBuilder_includesTransportsWhenIdSupplied',
        () {
      // Mirrors the inline AllowCredential construction in submitWithMultipleSigners;
      // the production pipeline does not extract a helper to invoke directly.
      final credBytes = Uint8List.fromList(<int>[42, 43, 44]);
      final transports = <String>['internal', 'hybrid'];
      final signer = SelectedSignerPasskey(
        credentialIdBytes: credBytes,
        keyData: Uint8List(97),
        transports: transports,
      );
      final allowCreds = signer.credentialIdBytes != null
          ? <AllowCredential>[
              AllowCredential(
                id: signer.credentialIdBytes!,
                transports: signer.transports,
              ),
            ]
          : null;
      expect(allowCreds, hasLength(1));
      expect(allowCreds!.single.id, orderedEquals(credBytes));
      expect(allowCreds.single.transports, orderedEquals(transports));
    });

    test(
        'transportsAllowCredentialBuilder_dropsAllowCredentialsWhenIdMissing',
        () {
      // When credentialIdBytes is null the entire allowCredentials list
      // becomes null; the transports field is dropped along with it because
      // there is no credential to associate them with.
      final signer = SelectedSignerPasskey(
        transports: const <String>['internal'],
      );
      final allowCreds = signer.credentialIdBytes != null
          ? <AllowCredential>[
              AllowCredential(
                id: signer.credentialIdBytes!,
                transports: signer.transports,
              ),
            ]
          : null;
      expect(allowCreds, isNull);
    });
  });

  group('SelectedSignerEd25519 construction and equality', () {
    test('test_selectedSignerEd25519_constructionAndEquality', () {
      final pk = Uint8List.fromList(List<int>.generate(32, (i) => i & 0xFF));

      final a = SelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: pk,
      );
      final b = SelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: Uint8List.fromList(pk),
      );
      final c = SelectedSignerEd25519(
        verifierAddress: _verifierB,
        publicKey: pk,
      );

      expect(a == b, isTrue, reason: 'Byte-equal instances must be equal');
      expect(a == c, isFalse,
          reason: 'Differing verifier address must break equality');

      final altPk = Uint8List.fromList(
        List<int>.generate(32, (i) => (i + 1) & 0xFF),
      );
      final d = SelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: altPk,
      );
      expect(a == d, isFalse,
          reason: 'Differing public key must break equality');
    });

    test('test_selectedSignerEd25519_hashCodeStableAcrossInstances', () {
      final pk = Uint8List.fromList(List<int>.generate(32, (i) => i & 0xFF));

      final a = SelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: pk,
      );
      final b = SelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: Uint8List.fromList(pk),
      );

      expect(a.hashCode, equals(b.hashCode),
          reason: 'Hash codes must be stable for byte-equivalent instances');

      final c = SelectedSignerEd25519(
        verifierAddress: _verifierB,
        publicKey: pk,
      );
      // Different verifier produces a different hash (not guaranteed by the
      // hashCode contract, but holds for this implementation).
      expect(a.hashCode, isNot(equals(c.hashCode)));
    });
  });

  group('validateSignerSet Ed25519', () {
    test(
        'test_validateSignerSet_ed25519WithRegisteredSigner_passes',
        () async {
      // Wire a connected kit with an OZExternalSignerManager that has an
      // Ed25519 signer registered.
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final publicKey = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );

      final kit = FakePipelineKit(externalSignerManager: extManager);
      kit.setConnected(
        credentialId: 'test-cred',
        contractId: _validContractId,
      );

      // submitWithMultipleSigners validates before RPC; we expect a
      // simulation-related error here (NullServer), which proves validation
      // of Ed25519 signers passed.
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: [
            SelectedSignerEd25519(
              verifierAddress: _verifierA,
              publicKey: publicKey,
            ),
          ],
        ),
        // Reaches RPC simulation after validation passes.
        throwsA(isNot(isA<InvalidInput>())),
      );
    });

    test(
        'test_validateSignerSet_ed25519WithoutRegisteredSigner_throwsInvalidInputSelectedSigners',
        () async {
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );

      final kit = FakePipelineKit(externalSignerManager: extManager);
      kit.setConnected(
        credentialId: 'test-cred',
        contractId: _validContractId,
      );

      final manager = OZMultiSignerManager(kit);
      final unregisteredKey =
          Uint8List.fromList(KeyPair.random().publicKey);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: [
            SelectedSignerEd25519(
              verifierAddress: _verifierA,
              publicKey: unregisteredKey,
            ),
          ],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'test_validateSignerSet_ed25519InvalidPublicKeyLength_throws',
        () async {
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );

      final kit = FakePipelineKit(externalSignerManager: extManager);
      kit.setConnected(
        credentialId: 'test-cred',
        contractId: _validContractId,
      );

      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: [
            SelectedSignerEd25519(
              verifierAddress: _verifierA,
              // 16 bytes is not a valid Ed25519 public key.
              publicKey: Uint8List(16),
            ),
          ],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'test_validateSignerSet_ed25519InvalidVerifierAddress_throws',
        () async {
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final publicKey = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );

      final kit = FakePipelineKit(externalSignerManager: extManager);
      kit.setConnected(
        credentialId: 'test-cred',
        contractId: _validContractId,
      );

      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: [
            SelectedSignerEd25519(
              verifierAddress: 'G${'A' * 55}', // G-address, not C-address
              publicKey: publicKey,
            ),
          ],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test(
        'test_validateSignerSet_ed25519SamePubkeyDifferentVerifiers_resolvedByTuple',
        () async {
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 2));

      // Same raw seed, two different verifier addresses — two distinct entries.
      final pk1 = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );
      extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierB,
      );

      // Both can sign despite sharing the same underlying public key bytes.
      expect(
        extManager.canSignEd25519For(
          verifierAddress: _verifierA,
          publicKey: pk1,
        ),
        isTrue,
      );
      expect(
        extManager.canSignEd25519For(
          verifierAddress: _verifierB,
          publicKey: pk1,
        ),
        isTrue,
      );
    });

    test(
        'test_validateSignerSet_ed25519PubkeyMatchesWalletGAddressBytes_noFalseMatch',
        () async {
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );

      // Raw seed whose derived public key will be used as the Ed25519 signer.
      final ed25519RawSeed =
          Uint8List.fromList(List<int>.generate(32, (i) => i + 3));
      final ed25519PublicKey = Uint8List.fromList(
        KeyPair.fromSecretSeedList(ed25519RawSeed).publicKey,
      );

      extManager.addEd25519FromRawKey(
        secretKeyBytes: ed25519RawSeed,
        verifierAddress: _verifierA,
      );

      final kit = FakePipelineKit(externalSignerManager: extManager);
      kit.setConnected(
        credentialId: 'test-cred',
        contractId: _validContractId,
      );

      // canSignEd25519For uses the (verifierAddress, publicKey) tuple key;
      // the matching wallet-signer storage keyed by G-address is unaffected.
      expect(
        extManager.canSignEd25519For(
          verifierAddress: _verifierA,
          publicKey: ed25519PublicKey,
        ),
        isTrue,
      );

      // canSignFor (wallet path) for the G-address derived from the same raw seed
      // must return false because no wallet signer was added.
      final derivedAccountId =
          KeyPair.fromSecretSeedList(ed25519RawSeed).accountId;
      expect(
        await extManager.canSignFor(derivedAccountId),
        isFalse,
        reason:
            'Ed25519 registry must not bleed into the wallet canSignFor path',
      );
    });
  });

  // ==========================================================================
  // submitWithMultipleSigners — Ed25519 mock-based fanout tests
  //
  // These tests wire the MockOZMultiSignerManager so the signer-manager
  // layer forwards the selectedSigners list intact without reaching the
  // network.  They assert structural properties of the forwarded payload.
  // ==========================================================================

  group('submitWithMultipleSigners Ed25519 fanout (mock pipeline)', () {
    ({
      FakePipelineKit kit,
      MockOZMultiSignerManager multi,
      MockOZTransactionOperations txOps,
      OZExternalSignerManager extManager,
    }) buildEd25519Harness({bool registerSigner = true}) {
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );
      if (registerSigner) {
        extManager.addEd25519FromRawKey(
          secretKeyBytes:
              Uint8List.fromList(List<int>.generate(32, (i) => i + 10)),
          verifierAddress: _verifierA,
        );
      }
      final kit = FakePipelineKit(externalSignerManager: extManager);
      kit.setConnected(
        credentialId: 'test-cred',
        contractId: _validContractId,
      );
      final txOps = MockOZTransactionOperations(kit);
      kit.setTransactionOperations(txOps);
      final multi = MockOZMultiSignerManager(kit);
      kit.setMultiSignerManager(multi);
      return (kit: kit, multi: multi, txOps: txOps, extManager: extManager);
    }

    test(
        'test_submitWithMultipleSigners_ed25519Only_producesCorrectAuthPayloadSignatureBytes',
        () async {
      final h = buildEd25519Harness();
      final rawSeed =
          Uint8List.fromList(List<int>.generate(32, (i) => i + 20));
      final publicKey = h.extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );

      final ed25519Signer = SelectedSignerEd25519(
        verifierAddress: _verifierA,
        publicKey: publicKey,
      );

      // Route through OZSignerManager so the selected signer is forwarded
      // to the mock multi-signer manager.
      final signerMgr = OZSignerManager(h.kit);
      await signerMgr.removeSigner(
        contextRuleId: 0,
        signerId: 1,
        selectedSigners: [ed25519Signer],
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, equals(1));
      final call = h.multi.submitWithMultipleSignersCalls.single;
      expect(call.selectedSigners.length, equals(1));
      expect(call.selectedSigners.single, isA<SelectedSignerEd25519>());
      final forwarded = call.selectedSigners.single as SelectedSignerEd25519;
      expect(forwarded.verifierAddress, equals(_verifierA));
      expect(forwarded.publicKey, orderedEquals(publicKey));

      // Verify OZEd25519Signature.toScVal() produces Bytes (not a Map)
      // and toAuthPayloadBytes() returns exactly 64 raw bytes (no XDR
      // envelope). The Ed25519 verifier contract expects BytesN<64>.
      final rawSig = Uint8List(64)..fillRange(0, 64, 0xAB);
      final ed25519Sig = OZEd25519Signature(
        publicKey: publicKey,
        signature: rawSig,
      );
      final scVal = ed25519Sig.toScVal();
      expect(scVal.discriminant, equals(XdrSCValType.SCV_BYTES));
      expect(scVal.bytes!.sCBytes, orderedEquals(rawSig));
      final sigBytes = ed25519Sig.toAuthPayloadBytes();
      expect(sigBytes.length, equals(64),
          reason: 'Ed25519 signatureBytes must be exactly 64 bytes (no XDR envelope)');
      expect(sigBytes, orderedEquals(rawSig),
          reason: 'signatureBytes must equal the original raw Ed25519 signature');
    });

    test(
        'test_submitWithMultipleSigners_mixedPasskeyEd25519Wallet_allSlotsFilled',
        () async {
      final h = buildEd25519Harness();
      final rawSeed =
          Uint8List.fromList(List<int>.generate(32, (i) => i + 21));
      final publicKey = h.extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );

      final selected = <SelectedSigner>[
        SelectedSignerPasskey(
          credentialId: 'pk-a',
          credentialIdBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          keyData: _passkeyKeyDataLocal(seed: 1),
        ),
        SelectedSignerEd25519(
          verifierAddress: _verifierA,
          publicKey: publicKey,
        ),
        SelectedSignerWallet(_validAccountAddress),
      ];

      final signerMgr = OZSignerManager(h.kit);
      await signerMgr.removeSigner(
        contextRuleId: 0,
        signerId: 2,
        selectedSigners: selected,
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, equals(1));
      final call = h.multi.submitWithMultipleSignersCalls.single;
      expect(call.selectedSigners.length, equals(3));
      expect(call.selectedSigners[0], isA<SelectedSignerPasskey>());
      expect(call.selectedSigners[1], isA<SelectedSignerEd25519>());
      expect(call.selectedSigners[2], isA<SelectedSignerWallet>());
    });

    test(
        'test_submitWithMultipleSigners_mixedRuleEd25519AndPasskeyAtSameIndex_routesCorrectly',
        () async {
      final h = buildEd25519Harness();
      final rawSeed =
          Uint8List.fromList(List<int>.generate(32, (i) => i + 22));
      final publicKey = h.extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _verifierA,
      );

      final selected = <SelectedSigner>[
        SelectedSignerEd25519(
          verifierAddress: _verifierA,
          publicKey: publicKey,
        ),
        SelectedSignerPasskey(
          credentialId: 'pk-b',
          credentialIdBytes: Uint8List.fromList(<int>[9, 8, 7, 6]),
          keyData: _passkeyKeyDataLocal(seed: 2),
        ),
      ];

      final ctxMgr = OZContextRuleManager(h.kit);
      await ctxMgr.updateName(
        id: 1,
        name: 'mixed-ed25519-passkey',
        selectedSigners: selected,
      );

      expect(h.multi.submitWithMultipleSignersCalls.length, equals(1));
      final call = h.multi.submitWithMultipleSignersCalls.single;
      expect(call.selectedSigners.length, equals(2));
      expect(call.selectedSigners[0], isA<SelectedSignerEd25519>());
      expect(call.selectedSigners[1], isA<SelectedSignerPasskey>());
    });

    test(
        'test_submitWithMultipleSigners_ed25519AdapterReachableForSigning',
        () async {
      // Installs an Ed25519 adapter that claims it can sign, then verifies
      // that canSignEd25519For returns true for the registered key.
      final extManager = OZExternalSignerManager(
        networkPassphrase: _testNetworkPassphrase,
      );
      final publicKey = Uint8List.fromList(KeyPair.random().publicKey);

      // Install an adapter that claims it can sign but returns an invalid sig.
      extManager.setEd25519Adapter(_ZeroBytesAdapter(publicKey: publicKey));

      final kit = FakePipelineKit(externalSignerManager: extManager);
      kit.setConnected(
        credentialId: 'test-cred',
        contractId: _validContractId,
      );

      expect(
        extManager.canSignEd25519For(
          verifierAddress: _verifierA,
          publicKey: publicKey,
        ),
        isTrue,
        reason:
            'canSignEd25519For must return true when the adapter claims it can sign',
      );
    });

    test(
        'test_submitWithMultipleSigners_ed25519PolicyOnlyAuth_succeedsWithZeroSelectedSigners',
        () async {
      // Verify that a rule with zero selectedSigners is forwarded correctly.
      // The mock returns success; on-chain policy evaluation is not exercised
      // in unit tests.
      final h = buildEd25519Harness(registerSigner: false);
      final ctxMgr = OZContextRuleManager(h.kit);

      await ctxMgr.updateName(
        id: 0,
        name: 'policy-only',
        selectedSigners: const <SelectedSigner>[],
      );

      // With zero selectedSigners the call goes directly through the passkey
      // path (no multi-signer fanout) so the mock is not invoked.
      expect(h.multi.submitWithMultipleSignersCalls, isEmpty);
    });
  });

  group('submitWithMultipleSigners validation guards', () {
    test('walletSigner_adapterCannotSign_throwsValidation', () async {
      // External wallet configured but canSignFor returns false.
      final kit = _buildConnectedKit();
      kit.setExternalWallet(_NeverSignWallet());
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[
            SelectedSignerWallet(_validAccountAddress),
          ],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('walletSigner_noExternalWallet_throwsValidation', () async {
      final kit = _buildConnectedKit();
      // externalWallet is null by default on FakePipelineKit.
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[
            SelectedSignerWallet(_validAccountAddress),
          ],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('ed25519Signer_noExternalSignerManager_throwsValidation', () async {
      final kit = _buildConnectedKit();
      // externalSignerManager is null by default.
      final manager = OZMultiSignerManager(kit);

      final pubKey = Uint8List(32);
      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[
            SelectedSignerEd25519(
              verifierAddress: _validTargetContract,
              publicKey: pubKey,
            ),
          ],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('latestLedger_nullSequence_throwsSubmissionFailed', () async {
      // After simulation succeeds with a non-empty auth list (so sorobanAuth is
      // non-empty), the pipeline fetches the latest ledger. If the sequence
      // is null, it throws submissionFailed (line 310).
      // We need a valid auth entry XDR to get past the sorobanAuth check.
      // Use the SOURCE_ACCOUNT entry which has a simple encoding.
      final sourceAccountEntry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forInvokeContractArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_validContractId).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      );
      final entryXdr = sourceAccountEntry.toBase64EncodedXdrString();

      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(_validAccountAddress, BigInt.from(1));
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[entryXdr]),
      ];
      mock.simulateDefault = simResp;

      // latestLedger with null sequence.
      final nullLedger = GetLatestLedgerResponse(<String, dynamic>{});
      mock.latestLedgerDefault = nullLedger;

      final kit = FakePipelineKit(sorobanServer: mock)
        ..setConnected(credentialId: 'cred', contractId: _validContractId);
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('simulationThrows_throwsTransactionSimulationFailed', () async {
      final mock = MockSorobanServer();
      // getAccount must succeed so the simulation throw can be exercised.
      mock.getAccountDefault = Account(_validAccountAddress, BigInt.from(1));
      mock.simulateDefault = Exception('rpc unreachable');
      final kit = FakePipelineKit(sorobanServer: mock)
        ..setConnected(credentialId: 'cred', contractId: _validContractId);
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
        ),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });

    test('simulationReturnsErrorString_throwsTransactionSimulationFailed', () async {
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(_validAccountAddress, BigInt.from(1));
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.resultError = 'contract trap: simulated failure';
      mock.simulateDefault = simResp;
      final kit = FakePipelineKit(sorobanServer: mock)
        ..setConnected(credentialId: 'cred', contractId: _validContractId);
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
        ),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });

    test('simulationReturnsNullSorobanAuth_throwsTransactionSimulationFailed', () async {
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(_validAccountAddress, BigInt.from(1));
      // Empty results → sorobanAuth is null/empty.
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[];
      mock.simulateDefault = simResp;
      final kit = FakePipelineKit(sorobanServer: mock)
        ..setConnected(credentialId: 'cred', contractId: _validContractId);
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
        ),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });

    test('passkeyKeyDataNull_throwsInvalidInput', () async {
      // Build a simulation response with one auth entry targeting the smart account.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));

      final authEntry = _makeAddressCredsEntry(contractAddress: _validContractId);
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[authEntry.toBase64EncodedXdrString()]),
      ];
      mock.simulateDefault = simResp;

      // latestLedger must succeed.
      final ledgerResp = GetLatestLedgerResponse(<String, dynamic>{});
      ledgerResp.sequence = 1000;
      mock.latestLedgerDefault = ledgerResp;

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: 'cred', contractId: _validContractId);
      final manager = OZMultiSignerManager(kit);

      // SelectedSignerPasskey with no keyData triggers the hoist guard.
      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: _stubHostFunction(),
          selectedSigners: <SelectedSigner>[
            const SelectedSignerPasskey(), // keyData is null
          ],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('multiSignerTransfer_selfTransfer_throwsInvalidInput', () async {
      final kit = _buildConnectedKit();
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _validTargetContract,
          recipient: _validContractId, // same as connected contract
          amount: '10',
          selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('multiSignerContractCall_emptyFunctionName_throwsInvalidInput', () async {
      final kit = _buildConnectedKit();
      final manager = OZMultiSignerManager(kit);

      await expectLater(
        () => manager.multiSignerContractCall(
          target: _validTargetContract,
          targetFn: '',
          selectedSigners: <SelectedSigner>[const SelectedSignerPasskey()],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers shared with Batch I tests.
// ---------------------------------------------------------------------------

XdrSorobanAuthorizationEntry _makeAddressCredsEntry({
  required String contractAddress,
  String? targetContract,
  String targetFn = 'noop',
}) {
  final targetC = targetContract ?? contractAddress;
  final invokeArgs = XdrInvokeContractArgs(
    Address.forContractId(targetC).toXdr(),
    targetFn,
    const <XdrSCVal>[],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    XdrSorobanAuthorizedFunction.forInvokeContractArgs(invokeArgs),
    <XdrSorobanAuthorizedInvocation>[],
  );
  final placeholderSig = XdrSCVal(XdrSCValType.SCV_VOID);
  final addressCredentials = XdrSorobanAddressCredentials(
    Address.forContractId(contractAddress).toXdr(),
    XdrInt64(BigInt.from(0)),
    XdrUint32(0),
    placeholderSig,
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forAddressCredentials(addressCredentials),
    invocation,
  );
}

const String _testNetworkPassphrase = 'Test SDF Network ; September 2015';
const String _verifierA =
    'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM';
const String _verifierB =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

Uint8List _passkeyKeyDataLocal({required int seed}) {
  final pk = Uint8List(65);
  pk[0] = 0x04;
  for (var i = 1; i < pk.length; i++) {
    pk[i] = (seed + i) & 0xFF;
  }
  final credentialId = Uint8List.fromList(<int>[seed, seed + 1, seed + 2]);
  return Uint8List(pk.length + credentialId.length)
    ..setRange(0, pk.length, pk)
    ..setRange(pk.length, pk.length + credentialId.length, credentialId);
}

XdrHostFunction _stubHostFunction() {
  return XdrHostFunction.forInvokingContractWithArgs(
    XdrInvokeContractArgs(
      Address.forContractId(_validContractId).toXdr(),
      'noop',
      const <XdrSCVal>[],
    ),
  );
}

/// A wallet adapter that always reports it cannot sign for any address.
class _NeverSignWallet extends ExternalWalletAdapter {
  @override
  Future<ConnectedWallet?> connect() async => null;

  @override
  Future<void> disconnect() async {}

  @override
  bool canSignFor(String address) => false;

  @override
  List<ConnectedWallet> getConnectedWallets() => const <ConnectedWallet>[];

  @override
  Future<SignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    SignAuthEntryOptions? options,
  }) async {
    throw UnsupportedError('_NeverSignWallet cannot sign');
  }
}

/// Adapter that claims it can sign for a specific public key but returns
/// 64 zero-bytes — an invalid signature that will fail local verification
/// in the real signing pipeline.
class _ZeroBytesAdapter extends OZExternalEd25519SignerAdapter {
  _ZeroBytesAdapter({required this.publicKey});

  final Uint8List publicKey;

  @override
  bool canSignFor(String verifierAddress, Uint8List pk) {
    if (pk.length != publicKey.length) return false;
    for (var i = 0; i < pk.length; i++) {
      if (pk[i] != publicKey[i]) return false;
    }
    return true;
  }

  @override
  Future<Uint8List> signAuthDigest(
    Uint8List authDigest,
    Uint8List pk,
  ) async {
    return Uint8List(64); // all zeros — fails Ed25519 verification
  }
}
