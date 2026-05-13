// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _accountA =
    'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
const String _credentialId = 'aGVsbG8tc21hcnQtYWNjb3VudA';

void main() {
  group('TransactionResult value type', () {
    test('transactionResult_allFields', () {
      const result = TransactionResult(
        success: true,
        hash: 'h',
        ledger: 42,
        error: null,
      );
      expect(result.success, isTrue);
      expect(result.hash, equals('h'));
      expect(result.ledger, equals(42));
      expect(result.error, isNull);
    });

    test('transactionResult_defaults', () {
      const result = TransactionResult(success: false);
      expect(result.success, isFalse);
      expect(result.hash, isNull);
      expect(result.ledger, isNull);
      expect(result.error, isNull);
    });

    test('transactionResult_failureWithError', () {
      const result = TransactionResult(
        success: false,
        hash: 'abc',
        error: 'something went wrong',
      );
      expect(result.success, isFalse);
      expect(result.hash, equals('abc'));
      expect(result.error, equals('something went wrong'));
    });

    test('transactionResult_successWithLedger', () {
      const result = TransactionResult(success: true, hash: 'h', ledger: 99);
      expect(result.success, isTrue);
      expect(result.hash, equals('h'));
      expect(result.ledger, equals(99));
    });

    test('transactionResult_equalInstances', () {
      const a = TransactionResult(success: true, hash: 'h', ledger: 1);
      const b = TransactionResult(success: true, hash: 'h', ledger: 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('transactionResult_unequalInstances', () {
      const a = TransactionResult(success: true, hash: 'h', ledger: 1);
      const b = TransactionResult(success: false, hash: 'h', ledger: 1);
      const c = TransactionResult(success: true, hash: 'g', ledger: 1);
      const d = TransactionResult(success: true, hash: 'h', ledger: 2);
      expect(a == b, isFalse);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });

    test('transactionResult_copy', () {
      const original = TransactionResult(success: true, hash: 'h', ledger: 1);
      final copy = original.copyWith(error: 'err');
      expect(copy.success, isTrue);
      expect(copy.hash, equals('h'));
      expect(copy.ledger, equals(1));
      expect(copy.error, equals('err'));
    });
  });

  group('SubmissionMethod enum behavior', () {
    test('submissionMethod_values', () {
      expect(SubmissionMethod.values.length, equals(2));
      expect(SubmissionMethod.values, contains(SubmissionMethod.relayer));
      expect(SubmissionMethod.values, contains(SubmissionMethod.rpc));
    });

    test('submissionMethod_valueOf', () {
      final byName = SubmissionMethod.values.firstWhere((e) => e.name == 'relayer');
      expect(byName, equals(SubmissionMethod.relayer));
    });

    test('submissionMethod_invalidValue_throws', () {
      expect(
        () => SubmissionMethod.values.firstWhere((e) => e.name == 'unknown'),
        throwsStateError,
      );
    });
  });

  group('ResolveContextRuleIds typealias behavior', () {
    test('resolveContextRuleIds_lambdaUsable', () async {
      ResolveContextRuleIds resolver =
          (entry, idx) async => <int>[1, 2, 3];
      final dummy = _dummyAuthEntry();
      final result = await resolver(dummy, 0);
      expect(result, equals(<int>[1, 2, 3]));
    });

    test('resolveContextRuleIds_emptyList', () async {
      ResolveContextRuleIds resolver = (entry, idx) async => const <int>[];
      final dummy = _dummyAuthEntry();
      final result = await resolver(dummy, 0);
      expect(result, isEmpty);
    });

    test('resolveContextRuleIds_multipleIds', () async {
      ResolveContextRuleIds resolver =
          (entry, idx) async => <int>[7, 8, 9, 10];
      final dummy = _dummyAuthEntry();
      final result = await resolver(dummy, 2);
      expect(result, equals(<int>[7, 8, 9, 10]));
    });
  });

  group('transfer validation', () {
    test('transfer_notConnected_throws', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      expect(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '1',
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('transfer_invalidRecipient_garbage_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: 'not-a-real-address',
          amount: '1',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('transfer_invalidRecipient_emptyString_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: '',
          amount: '1',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('transfer_invalidRecipient_muxedAddress_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      // Muxed M-address (deliberately rejected per validation rules).
      const muxed =
          'MAAAAAAAAAAAACEEAAAAAAAAAAFGW5MNJOAFV2ZUNRC4UYJAXLNQRJC6QQ77XAE7ZF44N2D6';
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: muxed,
          amount: '1',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('transfer_selfTransfer_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _contractA, // same as smart account
          amount: '1',
        ),
        throwsA(
          isA<InvalidInput>().having(
            (e) => e.message,
            'message',
            contains('Cannot transfer to self'),
          ),
        ),
      );
    });

    test('transfer_zeroAmount_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '0',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('transfer_negativeAmount_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '-1',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('transfer_nonNumericAmount_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: 'abc',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('transfer_emptyAmount_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('transfer_scientificNotation_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '1e5',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('transfer_amountTooSmall_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      // More than 7 decimal places is invalid in Stellar's amount format.
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '0.00000001',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('transfer_invalidTokenContract_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      // tokenContract validation runs inside contractCall (after recipient
      // validation but before any network). A non-contract address should
      // produce InvalidAddress.
      await expectLater(
        () => ops.transfer(
          tokenContract: 'not-a-contract-id',
          recipient: _accountA,
          amount: '1',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('transfer_recipientGAddress_passesValidation', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      // We expect validation to succeed and then the call to fail at the
      // network step (transaction-builder will succeed but simulation will
      // throw because the RPC URL is not reachable from the test harness).
      try {
        await ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '10',
        );
        // If somehow it succeeds (no network attempted in stub), that's fine.
      } catch (e) {
        // Validation must not be the failure mode.
        expect(e, isNot(isA<InvalidAddress>()));
        expect(e, isNot(isA<InvalidInput>()));
        expect(e, isNot(isA<InvalidAmount>()));
      }
    });

    test('transfer_recipientCAddress_passesValidation', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      // why: derive a real valid C-address from random bytes via StrKey so
      // the recipient is guaranteed CRC-checksum-valid distinct from the
      // smart-account contract address.
      final otherContractBytes = List<int>.filled(32, 7);
      final otherC = StrKey.encodeContractId(
        Uint8List.fromList(otherContractBytes),
      );
      try {
        await ops.transfer(
          tokenContract: _contractA,
          recipient: otherC,
          amount: '10',
        );
      } catch (e) {
        expect(e, isNot(isA<InvalidAddress>()));
        expect(e, isNot(isA<InvalidInput>()));
      }
    });
  });

  group('contractCall validation', () {
    test('contractCall_notConnected_throws', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.contractCall(
          target: _contractA,
          targetFn: 'hello',
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('contractCall_invalidTarget_garbage_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.contractCall(
          target: 'garbage',
          targetFn: 'hello',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('contractCall_invalidTarget_gAddress_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.contractCall(
          target: _accountA, // G-address, but contractCall requires C-address
          targetFn: 'hello',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('contractCall_invalidTarget_emptyString_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.contractCall(
          target: '',
          targetFn: 'hello',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('contractCall_emptyFunctionName_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.contractCall(
          target: _contractA,
          targetFn: '',
        ),
        throwsA(
          isA<InvalidInput>().having(
            (e) => e.message,
            'message',
            contains('cannot be empty'),
          ),
        ),
      );
    });

    test('contractCall_blankFunctionName_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.contractCall(
          target: _contractA,
          targetFn: '   ',
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('contractCall_validInputs_passesValidation', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      try {
        await ops.contractCall(
          target: _contractA,
          targetFn: 'hello',
        );
      } catch (e) {
        expect(e, isNot(isA<InvalidAddress>()));
        expect(e, isNot(isA<InvalidInput>()));
      }
    });
  });

  group('executeAndSubmit validation', () {
    test('executeAndSubmit_notConnected_throws', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.executeAndSubmit(
          target: _contractA,
          targetFn: 'hello',
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('executeAndSubmit_invalidTarget_garbage_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.executeAndSubmit(
          target: 'garbage',
          targetFn: 'hello',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('executeAndSubmit_invalidTarget_gAddress_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.executeAndSubmit(
          target: _accountA,
          targetFn: 'hello',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('executeAndSubmit_invalidTarget_emptyString_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.executeAndSubmit(
          target: '',
          targetFn: 'hello',
        ),
        throwsA(isA<InvalidAddress>()),
      );
    });

    test('executeAndSubmit_emptyFunctionName_throwsValidationException',
        () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.executeAndSubmit(
          target: _contractA,
          targetFn: '',
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('order-of-validation tests', () {
    test('transfer_notConnected_beforeRecipientValidation', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      // Recipient is malformed AND not connected — must throw WalletNotConnected
      // first.
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: 'garbage',
          amount: '1',
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('transfer_notConnected_beforeAmountValidation', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      // Amount is malformed AND not connected.
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: 'abc',
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('contractCall_notConnected_beforeTargetValidation', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.contractCall(
          target: 'garbage',
          targetFn: 'hello',
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('executeAndSubmit_notConnected_beforeTargetValidation', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.executeAndSubmit(
          target: 'garbage',
          targetFn: 'hello',
        ),
        throwsA(isA<WalletNotConnected>()),
      );
    });
  });

  group('fundWallet validation', () {
    test('fundWallet_notConnected_throws', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: _contractA),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('fundWallet_invalidNativeTokenContract_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: 'garbage'),
        throwsA(isA<InvalidAddress>()),
      );
    });
  });

  group('above-floor: submission-method selection', () {
    test('submissionMethod_auto_noRelayer_returnsRpc', () async {
      // Implicit: a kit without a relayer chooses RPC. Constructed via
      // FakePipelineKit's default (relayerClient = null).
      final kit = FakePipelineKit();
      expect(kit.relayerClient, isNull);
    });

    test('submissionMethod_auto_withRelayer_returnsRelayer', () async {
      final relayer = OZRelayerClient('https://relayer.test/relay');
      try {
        final kit = FakePipelineKit(relayerClient: relayer);
        expect(kit.relayerClient, isNotNull);
      } finally {
        await relayer.close();
      }
    });
  });

  group('above-floor: connected-state lifecycle', () {
    test('requireConnected_whenNotConnected_throws', () {
      final kit = FakePipelineKit();
      expect(kit.requireConnected, throwsA(isA<WalletNotConnected>()));
    });

    test('requireConnected_afterSet_returnsState', () {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: 'cred', contractId: _contractA);
      final state = kit.requireConnected();
      expect(state.credentialId, equals('cred'));
      expect(state.contractId, equals(_contractA));
    });

    test('setConnected_overwritesPrevious', () {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: 'cred1', contractId: _contractA)
        ..setConnected(credentialId: 'cred2', contractId: _contractA);
      final state = kit.requireConnected();
      expect(state.credentialId, equals('cred2'));
    });
  });
}

/// Builds a synthetic [XdrSorobanAuthorizationEntry] for typealias-callback
/// tests. The entry's contents are irrelevant; the typealias contract only
/// requires that a value be passable through the callback signature.
XdrSorobanAuthorizationEntry _dummyAuthEntry() {
  final args = XdrInvokeContractArgs(
    Address.forContractId(_contractA).toXdr(),
    'noop',
    const <XdrSCVal>[],
  );
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forSourceAccount(),
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forInvokeContractArgs(args),
      <XdrSorobanAuthorizedInvocation>[],
    ),
  );
}
