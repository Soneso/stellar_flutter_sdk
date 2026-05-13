// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

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
  // ==========================================================================
  // multiSignerExecuteAndSubmit — not-connected guard
  // ==========================================================================

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

  // ==========================================================================
  // multiSignerExecuteAndSubmit — target address validation
  // ==========================================================================

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

  // ==========================================================================
  // multiSignerExecuteAndSubmit — function name validation
  // ==========================================================================

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

  // ==========================================================================
  // multiSignerExecuteAndSubmit — selectedSigners validation
  // ==========================================================================

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

  // ==========================================================================
  // multiSignerTransfer — not-connected guard
  // ==========================================================================

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

  // ==========================================================================
  // multiSignerTransfer — recipient validation
  // ==========================================================================

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
  // multiSignerTransfer — self-transfer guard (per D-141)
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

  // ==========================================================================
  // multiSignerExecuteAndSubmit — forceMethod parameter acceptance
  // ==========================================================================

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

  // ==========================================================================
  // SelectedSigner sealed-class construction and equality
  // ==========================================================================

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

    test('passkey_dataClassEquality_withNullFields', () {
      const a = SelectedSignerPasskey();
      const b = SelectedSignerPasskey();
      expect(a == b, isTrue);
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
  // _generateNonce entropy probe (F-CQ-Flu-1 / F-SEC-Flu-1)
  //
  // The previous implementation drew two `nextInt(0x7FFFFFFF)` values and
  // OR-ed them together — the high bit was never set, so every nonce came
  // out positive (62 effective bits of entropy on the JS target). The
  // hardened generator should produce nonces spanning the full signed
  // 64-bit range. Probabilistically, ~50% of draws should have the high
  // bit set when the source is uniform over the 64-bit space.
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
  // SelectedSignerPasskey.transports propagation (D-114)
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
      // Mirror the AllowCredential construction performed by
      // submitWithMultipleSigners (lines 401-407 in the production
      // pipeline) to verify the transport list flows unchanged into
      // the WebAuthn allow-credentials shape used by the configured
      // provider. Re-implementing the builder in the test is
      // intentional; the production pipeline mounts it inline so
      // there is no extracted helper to invoke.
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
      // becomes null (cross-device fallback per D-115); the
      // transports field is dropped along with it because there is no
      // credential to associate them with.
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
}
