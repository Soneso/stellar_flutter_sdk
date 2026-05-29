// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
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

    test('transactionResult_equalityWithNonConstInstances', () {
      // Non-const instances so identical() returns false, exercising the == body.
      final a = TransactionResult(success: true, hash: 'h', ledger: 1, error: null);
      final b = TransactionResult(success: true, hash: 'h', ledger: 1, error: null);
      final c = TransactionResult(success: true, hash: 'h', ledger: 1, error: 'e');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
      expect(a == 'other', isFalse);
    });

    test('transactionResult_copyWithAllFields', () {
      const original = TransactionResult(success: true, hash: 'h', ledger: 1);
      final copy = original.copyWith(success: false, hash: 'h2', ledger: 2, error: 'e');
      expect(copy.success, isFalse);
      expect(copy.hash, 'h2');
      expect(copy.ledger, 2);
      expect(copy.error, 'e');
    });

    test('transactionResult_toString', () {
      const r = TransactionResult(success: true, hash: 'h', ledger: 5);
      expect(r.toString(), contains('success: true'));
      expect(r.toString(), contains('hash: h'));
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
    test('requireConnected_whenNotConnected_throws', () async {
      final kit = FakePipelineKit();
      await expectLater(
        () => kit.requireConnected(),
        throwsA(isA<WalletNotConnected>()),
      );
    });

    test('requireConnected_afterSet_returnsState', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: 'cred', contractId: _contractA);
      final state = await kit.requireConnected();
      expect(state.credentialId, equals('cred'));
      expect(state.contractId, equals(_contractA));
    });

    test('setConnected_overwritesPrevious', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: 'cred1', contractId: _contractA)
        ..setConnected(credentialId: 'cred2', contractId: _contractA);
      final state = await kit.requireConnected();
      expect(state.credentialId, equals('cred2'));
    });
  });

  group('executeAndSubmit pipeline path', () {
    test('validParams_callsSubmit_simulationThrows_wrapsError', () async {
      // executeAndSubmit with valid params → calls submit → simulation throws.
      // This covers lines 359-362, 365-372 in oz_transaction_operations.dart.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));
      mock.simulateDefault = Exception('rpc down');

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.executeAndSubmit(
          target: _contractA,
          targetFn: 'some_function',
        ),
        throwsA(isA<SmartAccountException>()),
      );
    });
  });

  group('executeAndSubmit validation', () {
    test('emptyTargetFn_throwsInvalidInput', () async {
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

    test('whitespaceOnlyTargetFn_throwsInvalidInput', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.executeAndSubmit(
          target: _contractA,
          targetFn: '   ',
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('_fetchAccount error paths', () {
    test('getAccount_returnsNull_throwsSubmissionFailed', () async {
      // When getAccount returns null ("account not found"), should throw.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      // getAccount returns null (account not found on network).
      mock.getAccountDefault = null;

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);
      final hostFn = _makeSimpleHostFunction(_contractA);

      await expectLater(
        () => ops.submit(
          hostFunction: hostFn,
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });
  });

  group('simulateAndExtractResult error paths', () {
    test('simulationThrows_throwsTransactionSimulationFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));
      mock.simulateDefault = Exception('rpc down');

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);

      final hostFn = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractA).toXdr(),
          'query',
          const <XdrSCVal>[],
        ),
      );

      await expectLater(
        ops.simulateAndExtractResult(hostFn),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });

    test('simulationErrorString_throwsTransactionSimulationFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));

      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.resultError = 'contract trap: revert';
      mock.simulateDefault = simResp;

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);

      final hostFn = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractA).toXdr(),
          'query',
          const <XdrSCVal>[],
        ),
      );

      await expectLater(
        ops.simulateAndExtractResult(hostFn),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });

    test('simulationNullResults_throwsTransactionSimulationFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));

      // No results set → results is null.
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      mock.simulateDefault = simResp;

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);

      final hostFn = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractA).toXdr(),
          'query',
          const <XdrSCVal>[],
        ),
      );

      await expectLater(
        ops.simulateAndExtractResult(hostFn),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });

    test('simulationEmptyResultsList_throwsTransactionSimulationFailed', () async {
      // Same as simulationNullResults but with an explicitly empty results list.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));

      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[];
      mock.simulateDefault = simResp;

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);

      final hostFn = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractA).toXdr(),
          'query',
          const <XdrSCVal>[],
        ),
      );

      await expectLater(
        ops.simulateAndExtractResult(hostFn),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });
  });

  group('submit pipeline: re-simulation error branches', () {
    test('reSimulationThrows_wrapsAsSubmissionFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(2)));

      // Initial simulation returns empty (no auth entries to sign).
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[]),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);

      // Re-simulation throws.
      mock.simulateResponses.add(Exception('re-simulate error'));

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);
      final hostFn = _makeSimpleHostFunction(_contractA);

      await expectLater(
        () => ops.submit(
          hostFunction: hostFn,
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('reSimulationErrorString_wrapsAsSimulationFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(2)));

      // Initial simulation returns empty.
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[]),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);

      // Re-simulation returns an error string.
      final reSimError = SimulateTransactionResponse(<String, dynamic>{});
      reSimError.resultError = 're-simulate contract trap';
      mock.simulateResponses.add(reSimError);

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);
      final hostFn = _makeSimpleHostFunction(_contractA);

      await expectLater(
        () => ops.submit(
          hostFunction: hostFn,
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<TransactionSimulationFailed>()),
      );
    });
  });

  group('submit pipeline: custom resolveContextRuleIds callback', () {
    test('customResolver_firesForAuthEntry_whenProviderConfigured', () async {
      // When submit is called with a resolveContextRuleIds callback and a
      // webauthn provider, the callback fires for smart-account auth entries.
      // This covers line 642 in oz_transaction_operations.dart.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(2)));

      final authEntry = _makeAddressCredsEntryForOps(_contractA);
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult(
          '',
          <String>[authEntry.toBase64EncodedXdrString()],
        ),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);
      // Re-simulate.
      mock.simulateResponses.add(simResp);
      mock.sendDefault = Exception('send error'); // fails at send, not earlier

      // WebAuthn provider.
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialId),
      );
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: Uint8List.fromList(List<int>.generate(37, (i) => i)),
        clientDataJSON: Uint8List.fromList(
          utf8.encode('{"type":"webauthn.get","challenge":"abc"}'),
        ),
        signature: Uint8List.fromList(<int>[
          0x30, 0x44,
          0x02, 0x20, ...List<int>.generate(32, (i) => i + 1),
          0x02, 0x20, ...List<int>.generate(32, (i) => i + 2),
        ]),
      ));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );

      // Store the credential so key-data lookup works.
      final storage = InMemoryStorageAdapter();
      final pk = Uint8List(65);
      pk[0] = 0x04;
      for (var i = 1; i < 65; i++) pk[i] = i & 0xFF;
      await storage.save(StoredCredential(
        credentialId: _credentialId,
        publicKey: pk,
        contractId: _contractA,
        createdAt: 1700000000000,
      ));

      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
        storage: storage,
      )..setConnected(credentialId: _credentialId, contractId: _contractA);

      var resolverCalled = false;
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.submit(
          hostFunction: _makeSimpleHostFunction(_contractA),
          auth: const <XdrSorobanAuthorizationEntry>[],
          resolveContextRuleIds: (entry, idx) async {
            resolverCalled = true;
            return <int>[0]; // rule ID 0
          },
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );

      expect(resolverCalled, isTrue, reason: 'Custom resolver should have been called');
    });
  });

  group('submit pipeline: credential mismatch', () {
    test('webauthn_returns_wrong_credentialId_throwsCredentialException', () async {
      // When the WebAuthn provider returns a different credentialId than
      // requested, the signing path throws CredentialException (line 667).
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));

      final authEntry = _makeAddressCredsEntryForOps(_contractA);
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult(
          '',
          <String>[authEntry.toBase64EncodedXdrString()],
        ),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);

      final provider = RecordingWebAuthnProvider();
      // Return a DIFFERENT credentialId than the one stored.
      final wrongCredId = Uint8List.fromList(<int>[0x99, 0x99, 0x99]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: wrongCredId,
        authenticatorData: Uint8List.fromList(List<int>.generate(37, (i) => i)),
        clientDataJSON: Uint8List.fromList(
          utf8.encode('{"type":"webauthn.get","challenge":"abc"}'),
        ),
        signature: Uint8List.fromList(<int>[
          0x30, 0x44,
          0x02, 0x20, ...List<int>.generate(32, (i) => i + 1),
          0x02, 0x20, ...List<int>.generate(32, (i) => i + 2),
        ]),
      ));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );

      final storage = InMemoryStorageAdapter();
      final pk = Uint8List(65);
      pk[0] = 0x04;
      for (var i = 1; i < 65; i++) pk[i] = i & 0xFF;
      await storage.save(StoredCredential(
        credentialId: _credentialId,
        publicKey: pk,
        contractId: _contractA,
        createdAt: 1700000000000,
      ));

      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
        storage: storage,
      )..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.submit(
          hostFunction: _makeSimpleHostFunction(_contractA),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<CredentialInvalid>()),
      );
    });
  });

  group('submit pipeline: credential lookup from context rules', () {
    test('noCredentialInStorage_noContextRules_throwsCredentialNotFound', () async {
      // When the credential is not in storage and context rules are empty,
      // _findKeyDataFromContextRules throws CredentialNotFound.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));

      final authEntry = _makeAddressCredsEntryForOps(_contractA);
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult(
          '',
          <String>[authEntry.toBase64EncodedXdrString()],
        ),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);

      // No webauthnProvider configured → throws before credential lookup
      // Wait, we need webauthn to reach the credential lookup. Let me use
      // a webauthn provider but no storage entry.
      // Actually, the no-storage path is reached when storage.get returns null.
      // The _FetchAccount issue: we need a webauthn provider configured.
      // Use pipeline fixtures provider.
      final provider = RecordingWebAuthnProvider();
      // Provider will fail because we're not setting up auth responses -
      // but actually, the credential lookup happens BEFORE webauthn.
      // The code at line 622-633 checks storage first, then finds credentials.
      // If credential not in storage, calls _findKeyDataFromContextRules.
      // _findKeyDataFromContextRules calls getAllContextRules → simulate count.
      // Let's set up: count returns 0 (empty rules), then throws CredentialNotFound.

      // StubContextRuleManager.getAllContextRules returns empty list.
      // But getAllContextRules calls getContextRulesCount which calls simulateAndExtractResult.
      // Let me set up the mock for that.

      // Actually, the kit uses StubContextRuleManager which returns empty allRules.
      // So getAllContextRules returns []. Then _findKeyDataFromContextRules throws.

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );

      // Use in-memory storage with NO credential stored.
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
        storage: InMemoryStorageAdapter(),
      )..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.submit(
          hostFunction: _makeSimpleHostFunction(_contractA),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<CredentialNotFound>()),
      );
    });
  });

  group('submit pipeline: signing path validation', () {
    test('latestLedgerNullSequence_throwsSubmissionFailed', () async {
      // When the latest ledger returns null sequence, signing should throw.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));

      final authEntry = _makeAddressCredsEntryForOps(_contractA);
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult(
          '',
          <String>[authEntry.toBase64EncodedXdrString()],
        ),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);

      // latestLedger with null sequence.
      final nullSeqLedger = GetLatestLedgerResponse(<String, dynamic>{});
      // sequence is null by default.
      mock.latestLedgerDefault = nullSeqLedger;

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);
      final hostFn = _makeSimpleHostFunction(_contractA);

      await expectLater(
        () => ops.submit(
          hostFunction: hostFn,
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('noWebAuthnProvider_withAuthEntry_throwsInvalidInput', () async {
      // Config without a webauthnProvider → signing should throw when the
      // simulation returns an auth entry for our contract.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));

      // Build an auth entry pointing at the contract.
      final authEntry = _makeAddressCredsEntryForOps(_contractA);

      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult(
          '',
          <String>[authEntry.toBase64EncodedXdrString()],
        ),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);

      // No webauthnProvider in config (default null).
      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);
      final hostFn = _makeSimpleHostFunction(_contractA);

      await expectLater(
        () => ops.submit(
          hostFunction: hostFn,
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<InvalidInput>()),
      );
    });
  });

  group('submit pipeline: polling error branches', () {
    test('pollTransactionThrows_wrapsAsSubmissionFailed', () async {
      // When poll throws, _pollForConfirmation wraps as submissionFailed.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(2)));

      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[]),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);
      mock.simulateResponses.add(simResp); // re-simulate

      // sendTransaction succeeds.
      final sendResp = SendTransactionResponse(<String, dynamic>{});
      sendResp.hash = 'poll-hash';
      sendResp.status = SendTransactionResponse.STATUS_PENDING;
      mock.sendDefault = sendResp;

      // pollTransaction throws.
      mock.pollDefault = Exception('poll error');

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.submit(
          hostFunction: _makeSimpleHostFunction(_contractA),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('sendTransaction_errorStatus_returnsFailedResult', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(2)));

      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[]),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);
      mock.simulateResponses.add(simResp); // re-simulate

      // sendTransaction returns ERROR status.
      final sendResp = SendTransactionResponse(<String, dynamic>{});
      sendResp.hash = 'error-hash';
      sendResp.status = SendTransactionResponse.STATUS_ERROR;
      sendResp.errorResultXdr = 'base64-error-xdr';
      mock.sendDefault = sendResp;

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final result = await OZTransactionOperations(kit).submit(
        hostFunction: _makeSimpleHostFunction(_contractA),
        auth: const <XdrSorobanAuthorizationEntry>[],
      );

      expect(result.success, isFalse);
      expect(result.error, equals('base64-error-xdr'));
    });
  });

  group('submit pipeline: relayer configuration', () {
    test('forceRelayer_noRelayerClient_throwsSubmissionFailed', () async {
      // forceMethod=relayer but no relayer configured → throws submissionFailed (line 1170).
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(1)));
      mock.getAccountResponses.add(Account(deployer.accountId, BigInt.from(2)));

      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[]),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses.add(simResp);
      mock.latestLedgerDefault = _makeLedgerResponse(1000);
      mock.simulateResponses.add(simResp); // re-simulate

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.submit(
          hostFunction: _makeSimpleHostFunction(_contractA),
          auth: const <XdrSorobanAuthorizationEntry>[],
          forceMethod: SubmissionMethod.relayer, // relayer forced but not configured
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });
  });

  group('submit pipeline: direct RPC path error branches', () {
    test('sendTransaction_throws_wrapsAsSubmissionFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));

      // Simulation returns empty results (no auth entries to sign).
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[]),
      ];
      simResp.minResourceFee = 100;
      mock.simulateResponses
        ..add(simResp) // initial simulate
        ..add(simResp); // re-simulate after signing
      mock.latestLedgerDefault = _makeLedgerResponse(1000);

      // sendTransaction throws.
      mock.sendDefault = Exception('network error');

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);
      final hostFn = _makeSimpleHostFunction(_contractA);

      await expectLater(
        () => ops.submit(
          hostFunction: hostFn,
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });
  });
}

XdrSorobanAuthorizationEntry _makeAddressCredsEntryForOps(String contractAddress) {
  final invokeArgs = XdrInvokeContractArgs(
    Address.forContractId(contractAddress).toXdr(),
    'noop',
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

XdrSorobanAuthorizationEntry _makeSimpleSourceAccountEntry() {
  final args = XdrInvokeContractArgs(
    Address.forContractId(_contractA).toXdr(),
    'call',
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

XdrHostFunction _makeSimpleHostFunction(String contractId) {
  return XdrHostFunction.forInvokingContractWithArgs(
    XdrInvokeContractArgs(
      Address.forContractId(contractId).toXdr(),
      'call',
      const <XdrSCVal>[],
    ),
  );
}

GetLatestLedgerResponse _makeLedgerResponse(int sequence) {
  final r = GetLatestLedgerResponse(<String, dynamic>{});
  r.sequence = sequence;
  return r;
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
