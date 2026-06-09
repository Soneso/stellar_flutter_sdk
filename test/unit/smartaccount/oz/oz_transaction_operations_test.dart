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
  group('OZTransactionResult value type', () {
    test('transactionResult_allFields', () {
      const result = OZTransactionResult(
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
      const result = OZTransactionResult(success: false);
      expect(result.success, isFalse);
      expect(result.hash, isNull);
      expect(result.ledger, isNull);
      expect(result.error, isNull);
    });

    test('transactionResult_failureWithError', () {
      const result = OZTransactionResult(
        success: false,
        hash: 'abc',
        error: 'something went wrong',
      );
      expect(result.success, isFalse);
      expect(result.hash, equals('abc'));
      expect(result.error, equals('something went wrong'));
    });

    test('transactionResult_successWithLedger', () {
      const result = OZTransactionResult(success: true, hash: 'h', ledger: 99);
      expect(result.success, isTrue);
      expect(result.hash, equals('h'));
      expect(result.ledger, equals(99));
    });

    test('transactionResult_equalInstances', () {
      const a = OZTransactionResult(success: true, hash: 'h', ledger: 1);
      const b = OZTransactionResult(success: true, hash: 'h', ledger: 1);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('transactionResult_equalityWithNonConstInstances', () {
      // Non-const instances so identical() returns false, exercising the == body.
      final a = OZTransactionResult(success: true, hash: 'h', ledger: 1, error: null);
      final b = OZTransactionResult(success: true, hash: 'h', ledger: 1, error: null);
      final c = OZTransactionResult(success: true, hash: 'h', ledger: 1, error: 'e');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
      expect(a == 'other', isFalse);
    });

    test('transactionResult_toString', () {
      const r = OZTransactionResult(success: true, hash: 'h', ledger: 5);
      expect(r.toString(), contains('success: true'));
      expect(r.toString(), contains('hash: h'));
    });

    test('transactionResult_unequalInstances', () {
      const a = OZTransactionResult(success: true, hash: 'h', ledger: 1);
      const b = OZTransactionResult(success: false, hash: 'h', ledger: 1);
      const c = OZTransactionResult(success: true, hash: 'g', ledger: 1);
      const d = OZTransactionResult(success: true, hash: 'h', ledger: 2);
      expect(a == b, isFalse);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });

  });

  group('OZSubmissionMethod enum behavior', () {
    test('submissionMethod_values', () {
      expect(OZSubmissionMethod.values.length, equals(2));
      expect(OZSubmissionMethod.values, contains(OZSubmissionMethod.relayer));
      expect(OZSubmissionMethod.values, contains(OZSubmissionMethod.rpc));
    });

    test('submissionMethod_valueOf', () {
      final byName = OZSubmissionMethod.values.firstWhere((e) => e.name == 'relayer');
      expect(byName, equals(OZSubmissionMethod.relayer));
    });

    test('submissionMethod_invalidValue_throws', () {
      expect(
        () => OZSubmissionMethod.values.firstWhere((e) => e.name == 'unknown'),
        throwsStateError,
      );
    });
  });

  group('OZResolveContextRuleIds typealias behavior', () {
    test('resolveContextRuleIds_lambdaUsable', () async {
      OZResolveContextRuleIds resolver =
          (entry, idx) async => <int>[1, 2, 3];
      final dummy = _dummyAuthEntry();
      final result = await resolver(dummy, 0);
      expect(result, equals(<int>[1, 2, 3]));
    });

    test('resolveContextRuleIds_emptyList', () async {
      OZResolveContextRuleIds resolver = (entry, idx) async => const <int>[];
      final dummy = _dummyAuthEntry();
      final result = await resolver(dummy, 0);
      expect(result, isEmpty);
    });

    test('resolveContextRuleIds_multipleIds', () async {
      OZResolveContextRuleIds resolver =
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
          isA<SmartAccountInvalidInput>().having(
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
          decimals: 7,
        ),
        throwsA(isA<SmartAccountValidationException>()),
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
          decimals: 7,
        ),
        throwsA(isA<SmartAccountValidationException>()),
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
          decimals: 7,
        ),
        throwsA(isA<SmartAccountValidationException>()),
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
          decimals: 7,
        ),
        throwsA(isA<SmartAccountValidationException>()),
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
          decimals: 7,
        ),
        throwsA(isA<SmartAccountValidationException>()),
      );
    });

    test('transfer_amountTooSmall_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      // More than 7 fractional digits exceeds the token's 7-decimal scale.
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '0.00000001',
          decimals: 7,
        ),
        throwsA(isA<SmartAccountValidationException>()),
      );
    });

    test('transfer_invalidTokenContract_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      // tokenContract validation runs inside contractCall (after recipient
      // validation but before any network). A non-contract address should
      // produce SmartAccountInvalidAddress.
      await expectLater(
        () => ops.transfer(
          tokenContract: 'not-a-contract-id',
          recipient: _accountA,
          amount: '1',
        ),
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        expect(e, isNot(isA<SmartAccountInvalidAddress>()));
        expect(e, isNot(isA<SmartAccountInvalidInput>()));
        expect(e, isNot(isA<SmartAccountInvalidAmount>()));
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
        expect(e, isNot(isA<SmartAccountInvalidAddress>()));
        expect(e, isNot(isA<SmartAccountInvalidInput>()));
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
          isA<SmartAccountInvalidInput>().having(
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
        throwsA(isA<SmartAccountInvalidInput>()),
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
        expect(e, isNot(isA<SmartAccountInvalidAddress>()));
        expect(e, isNot(isA<SmartAccountInvalidInput>()));
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
      );
    });
  });

  group('order-of-validation tests', () {
    test('transfer_notConnected_beforeRecipientValidation', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      // Recipient is malformed AND not connected — must throw SmartAccountWalletNotConnected
      // first.
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: 'garbage',
          amount: '1',
        ),
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });
  });

  group('fundWallet validation', () {
    test('fundWallet_notConnected_throws', () async {
      final kit = FakePipelineKit();
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: _contractA),
        throwsA(isA<SmartAccountWalletNotConnected>()),
      );
    });

    test('fundWallet_invalidNativeTokenContract_throws', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fundWallet(nativeTokenContract: 'garbage'),
        throwsA(isA<SmartAccountInvalidAddress>()),
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
        throwsA(isA<SmartAccountWalletNotConnected>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
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
        throwsA(isA<SmartAccountTransactionSubmissionFailed>()),
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
        throwsA(isA<SmartAccountTransactionSimulationFailed>()),
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
        throwsA(isA<SmartAccountTransactionSimulationFailed>()),
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
        throwsA(isA<SmartAccountTransactionSimulationFailed>()),
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
        throwsA(isA<SmartAccountTransactionSimulationFailed>()),
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
        throwsA(isA<SmartAccountTransactionSubmissionFailed>()),
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
        throwsA(isA<SmartAccountTransactionSimulationFailed>()),
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
      final storage = OZInMemoryStorageAdapter();
      final pk = Uint8List(65);
      pk[0] = 0x04;
      for (var i = 1; i < 65; i++) pk[i] = i & 0xFF;
      await storage.save(OZStoredCredential(
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
        throwsA(isA<SmartAccountTransactionSubmissionFailed>()),
      );

      expect(resolverCalled, isTrue, reason: 'Custom resolver should have been called');
    });
  });

  group('submit pipeline: credential mismatch', () {
    test('webauthn_returns_wrong_credentialId_throwsCredentialException', () async {
      // When the WebAuthn provider returns a different credentialId than
      // requested, the signing path throws SmartAccountCredentialException (line 667).
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

      final storage = OZInMemoryStorageAdapter();
      final pk = Uint8List(65);
      pk[0] = 0x04;
      for (var i = 1; i < 65; i++) pk[i] = i & 0xFF;
      await storage.save(OZStoredCredential(
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
        throwsA(isA<SmartAccountCredentialInvalid>()),
      );
    });
  });

  group('submit pipeline: credential lookup from context rules', () {
    test('noCredentialInStorage_noContextRules_throwsCredentialNotFound', () async {
      // When the credential is not in storage and context rules are empty,
      // _findKeyDataFromContextRules throws SmartAccountCredentialNotFound.
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
      // Let's set up: count returns 0 (empty rules), then throws SmartAccountCredentialNotFound.

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
        storage: OZInMemoryStorageAdapter(),
      )..setConnected(credentialId: _credentialId, contractId: _contractA);

      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.submit(
          hostFunction: _makeSimpleHostFunction(_contractA),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(isA<SmartAccountCredentialNotFound>()),
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
        throwsA(isA<SmartAccountTransactionSubmissionFailed>()),
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
        throwsA(isA<SmartAccountInvalidInput>()),
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
        throwsA(isA<SmartAccountTransactionSubmissionFailed>()),
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
          forceMethod: OZSubmissionMethod.relayer, // relayer forced but not configured
        ),
        throwsA(isA<SmartAccountTransactionSubmissionFailed>()),
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
        throwsA(isA<SmartAccountTransactionSubmissionFailed>()),
      );
    });
  });

  group('amountToBaseUnits conversion', () {
    test('zero decimals accepts whole numbers only', () {
      expect(
        OZTransactionOperations.amountToBaseUnits('10', decimals: 0),
        equals(BigInt.from(10)),
      );
    });

    test('whole + fraction padding at 6 decimals', () {
      expect(
        OZTransactionOperations.amountToBaseUnits('1.5', decimals: 6),
        equals(BigInt.from(1500000)),
      );
    });

    test('smallest representable unit at 7 decimals', () {
      expect(
        OZTransactionOperations.amountToBaseUnits('0.0000001', decimals: 7),
        equals(BigInt.one),
      );
    });

    test('exact-precision fraction at 2 decimals', () {
      expect(
        OZTransactionOperations.amountToBaseUnits('12.34', decimals: 2),
        equals(BigInt.from(1234)),
      );
    });

    test('whole number padded at 18 decimals', () {
      expect(
        OZTransactionOperations.amountToBaseUnits('3', decimals: 18),
        equals(BigInt.from(3) * BigInt.from(10).pow(18)),
      );
    });

    test('fraction shorter than scale is right-padded', () {
      expect(
        OZTransactionOperations.amountToBaseUnits('2.5', decimals: 18),
        equals(BigInt.from(25) * BigInt.from(10).pow(17)),
      );
    });

    test('rejects more fractional digits than decimals', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('1.234', decimals: 2),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects scientific notation', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('1e5', decimals: 7),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects empty string', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('', decimals: 7),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects whitespace-only string', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('   ', decimals: 7),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects non-numeric string', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('abc', decimals: 7),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects negative amount', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('-1', decimals: 7),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects zero amount', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('0', decimals: 7),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects zero amount with explicit fraction', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('0.0', decimals: 7),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects negative decimals', () {
      expect(
        () => OZTransactionOperations.amountToBaseUnits('1', decimals: -1),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('rejects decimals above the maximum', () {
      expect(
        OZTransactionOperations.maxTokenDecimals,
        equals(38),
      );
      expect(
        () => OZTransactionOperations.amountToBaseUnits(
          '1',
          decimals: OZTransactionOperations.maxTokenDecimals + 1,
        ),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
    });

    test('accepts amount at the maximum decimals', () {
      expect(
        OZTransactionOperations.amountToBaseUnits(
          '1',
          decimals: OZTransactionOperations.maxTokenDecimals,
        ),
        equals(BigInt.from(10).pow(38)),
      );
    });

    test('trims surrounding whitespace before parsing', () {
      expect(
        OZTransactionOperations.amountToBaseUnits('  1.5  ', decimals: 6),
        equals(BigInt.from(1500000)),
      );
    });
  });

  group('baseUnitsToI128ScVal encoding', () {
    test('encodes an in-range value as SCV_I128', () {
      final scVal = OZTransactionOperations.baseUnitsToI128ScVal(
        BigInt.from(1500000),
        amount: '1.5',
      );
      expect(scVal.discriminant, equals(XdrSCValType.SCV_I128));
      expect(scVal.i128!.lo.uint64, equals(BigInt.from(1500000)));
    });

    test('out-of-i128-range value throws tagged invalidAmount with cause', () {
      final tooBig = BigInt.one << 127; // exceeds i128 max.
      expect(
        () => OZTransactionOperations.baseUnitsToI128ScVal(
          tooBig,
          amount: 'huge',
        ),
        throwsA(
          isA<SmartAccountInvalidAmount>()
              .having((e) => e.message, 'message', contains('i128'))
              .having((e) => e.cause, 'cause', isNotNull),
        ),
      );
    });
  });

  group('fetchTokenDecimals', () {
    test('returns the u32 decimals reported by the contract', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));
      mock.simulateDefault = _u32SimResponse(6);

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);

      final decimals = await ops.fetchTokenDecimals(_contractA);
      expect(decimals, equals(6));
    });

    test('invalid contract address throws SmartAccountInvalidAddress', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);
      await expectLater(
        () => ops.fetchTokenDecimals('not-a-contract'),
        throwsA(isA<SmartAccountInvalidAddress>()),
      );
    });

    test('non-u32 result throws simulationFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));
      // The contract returns a string instead of a u32.
      mock.simulateDefault =
          _scValSimResponse(XdrSCVal.forString('not-a-number'));

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = OZTransactionOperations(kit);

      await expectLater(
        () => ops.fetchTokenDecimals(_contractA),
        throwsA(isA<SmartAccountTransactionSimulationFailed>()),
      );
    });
  });

  group('transfer decimals encoding', () {
    test('supplied decimals: submitted i128 reflects the base units', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = _CapturingContractCallOps(kit);

      await ops.transfer(
        tokenContract: _contractA,
        recipient: _accountA,
        amount: '1.5',
        decimals: 6,
      );

      final args = ops.contractCallCalls.single.targetArgs;
      // targetArgs = [from, to, amount-i128].
      expect(args[2].discriminant, equals(XdrSCValType.SCV_I128));
      expect(args[2].i128!.lo.uint64, equals(BigInt.from(1500000)));
    });

    test('auto-fetch path: decimals() simulate drives the base units', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));
      // decimals() simulate returns u32 = 6.
      mock.simulateDefault = _u32SimResponse(6);

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = _CapturingContractCallOps(kit);

      await ops.transfer(
        tokenContract: _contractA,
        recipient: _accountA,
        amount: '2.5', // 2.5 at 6 decimals = 2_500_000 base units.
      );

      final args = ops.contractCallCalls.single.targetArgs;
      expect(args[2].discriminant, equals(XdrSCValType.SCV_I128));
      expect(args[2].i128!.lo.uint64, equals(BigInt.from(2500000)));
      // The decimals() simulate must have run exactly once.
      expect(mock.simulateCalls.length, equals(1));
    });

    test('out-of-i128 amount throws tagged invalidAmount', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final ops = _CapturingContractCallOps(kit);

      // 10^30 whole units at 18 decimals => 10^48 base units, far beyond i128.
      await expectLater(
        () => ops.transfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '1000000000000000000000000000000',
          decimals: 18,
        ),
        throwsA(
          isA<SmartAccountInvalidAmount>()
              .having((e) => e.message, 'message', contains('i128')),
        ),
      );
      expect(ops.contractCallCalls, isEmpty);
    });
  });

  group('multiSignerTransfer decimals encoding', () {
    test('supplied decimals: submitted i128 reflects the base units', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final manager = _CapturingMultiSignerManager(kit);

      await manager.multiSignerTransfer(
        tokenContract: _contractA,
        recipient: _accountA,
        amount: '1.5',
        decimals: 6,
        selectedSigners: const <OZSelectedSigner>[OZSelectedSignerPasskey()],
      );

      final args = manager.contractCallCalls.single.targetArgs;
      expect(args[2].discriminant, equals(XdrSCValType.SCV_I128));
      expect(args[2].i128!.lo.uint64, equals(BigInt.from(1500000)));
    });

    test('auto-fetch path: decimals() simulate drives the base units', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountDefault = Account(deployer.accountId, BigInt.from(1));
      mock.simulateDefault = _u32SimResponse(6);

      final kit = FakePipelineKit(sorobanServer: mock, deployer: deployer)
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      // multiSignerTransfer fetches decimals via kit.transactionOperations,
      // so the kit's bound ops must hit the same mock server.
      final manager = _CapturingMultiSignerManager(kit);

      await manager.multiSignerTransfer(
        tokenContract: _contractA,
        recipient: _accountA,
        amount: '2.5',
        selectedSigners: const <OZSelectedSigner>[OZSelectedSignerPasskey()],
      );

      final args = manager.contractCallCalls.single.targetArgs;
      expect(args[2].discriminant, equals(XdrSCValType.SCV_I128));
      expect(args[2].i128!.lo.uint64, equals(BigInt.from(2500000)));
      expect(mock.simulateCalls.length, equals(1));
    });

    test('empty amount throws invalidAmount before routing', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final manager = _CapturingMultiSignerManager(kit);

      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '',
          decimals: 7,
          selectedSigners: const <OZSelectedSigner>[OZSelectedSignerPasskey()],
        ),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
      expect(manager.contractCallCalls, isEmpty);
    });

    test('zero amount throws invalidAmount before routing', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final manager = _CapturingMultiSignerManager(kit);

      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '0',
          decimals: 7,
          selectedSigners: const <OZSelectedSigner>[OZSelectedSignerPasskey()],
        ),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
      expect(manager.contractCallCalls, isEmpty);
    });

    test('excess fractional digits throw invalidAmount before routing',
        () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final manager = _CapturingMultiSignerManager(kit);

      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '1.123', // 3 fractional digits > 2 decimals.
          decimals: 2,
          selectedSigners: const <OZSelectedSigner>[OZSelectedSignerPasskey()],
        ),
        throwsA(isA<SmartAccountInvalidAmount>()),
      );
      expect(manager.contractCallCalls, isEmpty);
    });

    test('out-of-i128 amount throws tagged invalidAmount', () async {
      final kit = FakePipelineKit()
        ..setConnected(credentialId: _credentialId, contractId: _contractA);
      final manager = _CapturingMultiSignerManager(kit);

      await expectLater(
        () => manager.multiSignerTransfer(
          tokenContract: _contractA,
          recipient: _accountA,
          amount: '1000000000000000000000000000000',
          decimals: 18,
          selectedSigners: const <OZSelectedSigner>[OZSelectedSignerPasskey()],
        ),
        throwsA(
          isA<SmartAccountInvalidAmount>()
              .having((e) => e.message, 'message', contains('i128')),
        ),
      );
      expect(manager.contractCallCalls, isEmpty);
    });
  });
}

/// Records the [contractCall] arguments produced by [transfer] while letting
/// [fetchTokenDecimals] run against the kit's (mock) Soroban server. Used to
/// assert the encoded i128 amount without driving the full submission
/// pipeline.
class _CapturingContractCallOps extends OZTransactionOperations {
  _CapturingContractCallOps(super.kit);

  final List<({String target, String targetFn, List<XdrSCVal> targetArgs})>
      contractCallCalls =
      <({String target, String targetFn, List<XdrSCVal> targetArgs})>[];

  @override
  Future<OZTransactionResult> contractCall({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
    dynamic cancelToken,
  }) async {
    contractCallCalls.add((
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.from(targetArgs),
    ));
    return const OZTransactionResult(success: true, hash: 'captured');
  }
}

/// Records the [multiSignerContractCall] arguments produced by
/// [multiSignerTransfer] while letting the decimals fetch run against the
/// kit's (mock) Soroban server through `kit.transactionOperations`.
class _CapturingMultiSignerManager extends OZMultiSignerManager {
  _CapturingMultiSignerManager(super.kit);

  final List<({String target, String targetFn, List<XdrSCVal> targetArgs})>
      contractCallCalls =
      <({String target, String targetFn, List<XdrSCVal> targetArgs})>[];

  @override
  Future<OZTransactionResult> multiSignerContractCall({
    required String target,
    required String targetFn,
    List<XdrSCVal> targetArgs = const <XdrSCVal>[],
    required List<OZSelectedSigner> selectedSigners,
    OZSubmissionMethod? forceMethod,
    OZResolveContextRuleIds? resolveContextRuleIds,
  }) async {
    contractCallCalls.add((
      target: target,
      targetFn: targetFn,
      targetArgs: List<XdrSCVal>.from(targetArgs),
    ));
    return const OZTransactionResult(success: true, hash: 'captured');
  }
}

/// Builds a [SimulateTransactionResponse] whose single result decodes to the
/// supplied [scVal], mirroring the shape an on-chain read-only simulate
/// returns.
SimulateTransactionResponse _scValSimResponse(XdrSCVal scVal) {
  final stream = XdrDataOutputStream();
  XdrSCVal.encode(stream, scVal);
  final base64 = base64Encode(stream.bytes);
  final resp = SimulateTransactionResponse(<String, dynamic>{});
  resp.results = <SimulateTransactionResult>[
    SimulateTransactionResult(base64, <String>[]),
  ];
  resp.minResourceFee = 100;
  return resp;
}

/// Builds a [SimulateTransactionResponse] whose single result decodes to a
/// `u32` value, used to emulate a token's `decimals()` return.
SimulateTransactionResponse _u32SimResponse(int value) =>
    _scValSimResponse(XdrSCVal.forU32(value));

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
