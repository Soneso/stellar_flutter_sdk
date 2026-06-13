// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Coverage tests for the OZ and AssembledTransaction credential-arm paths
// reachable-but-untested.  No production code changes; all tests use the
// existing mock infrastructure.
//
// Lines covered:
//   oz_transaction_operations.dart:591  — WITH_DELEGATES throw in _signSimulationAuthEntries
//   oz_multi_signer_manager.dart:421    — WITH_DELEGATES throw in submitWithMultipleSigners
//   oz_multi_signer_manager.dart:1034   — ADDRESS_V2 arm in _innerAddressCredentialsXdr
//   oz_multi_signer_manager.dart:1035   — return creds.addressV2
//   oz_multi_signer_manager.dart:1053   — ADDRESS_V2 arm in _rebuildCredentialsXdr
//   oz_multi_signer_manager.dart:1054   — forAddressV2Credentials(updated)

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// ---------------------------------------------------------------------------
// Shared constants (same contracts used by the existing pipeline tests so that
// the harness connected-state matches the auth-entry addresses).
// ---------------------------------------------------------------------------

const String _contractA =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
const String _contractB =
    'CADQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQOBYHA4DQP5KR';
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

Uint8List _bytes(int length, [int seed = 0]) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (seed + i) & 0xFF;
  }
  return out;
}

// ---------------------------------------------------------------------------
// XDR auth-entry helpers
// ---------------------------------------------------------------------------

/// Builds an [XdrSorobanAuthorizationEntry] with
/// [SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES] discriminant.
///
/// This type cannot be constructed via the public high-level API without
/// pre-signing, so we build it directly from XDR primitives to exercise the
/// throw-guard in the single-signer and multi-signer pipelines.
XdrSorobanAuthorizationEntry _makeWithDelegatesXdrEntry(String contractAddress) {
  final invokeArgs = XdrInvokeContractArgs(
    Address.forContractId(contractAddress).toXdr(),
    'noop',
    const <XdrSCVal>[],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    XdrSorobanAuthorizedFunction.forInvokeContractArgs(invokeArgs),
    <XdrSorobanAuthorizedInvocation>[],
  );
  final addressCreds = XdrSorobanAddressCredentials(
    Address.forContractId(contractAddress).toXdr(),
    XdrInt64(BigInt.zero),
    XdrUint32(0),
    XdrSCVal(XdrSCValType.SCV_VOID),
  );
  final delegateKp = KeyPair.random();
  final delegateNode = XdrSorobanDelegateSignature(
    XdrSCAddress.forAccountId(delegateKp.accountId),
    XdrSCVal(XdrSCValType.SCV_VOID),
    <XdrSorobanDelegateSignature>[],
  );
  final withDels = XdrSorobanAddressCredentialsWithDelegates(
    addressCreds,
    <XdrSorobanDelegateSignature>[delegateNode],
  );
  final creds = XdrSorobanCredentials(
    XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES,
  );
  creds.addressWithDelegates = withDels;
  return XdrSorobanAuthorizationEntry(creds, invocation);
}

/// Builds an [XdrSorobanAuthorizationEntry] with
/// [SOROBAN_CREDENTIALS_ADDRESS_V2] discriminant pointing at [contractAddress].
XdrSorobanAuthorizationEntry _makeAddressV2XdrEntry(String contractAddress) {
  final invokeArgs = XdrInvokeContractArgs(
    Address.forContractId(contractAddress).toXdr(),
    'noop',
    const <XdrSCVal>[],
  );
  final invocation = XdrSorobanAuthorizedInvocation(
    XdrSorobanAuthorizedFunction.forInvokeContractArgs(invokeArgs),
    <XdrSorobanAuthorizedInvocation>[],
  );
  final addressCreds = XdrSorobanAddressCredentials(
    Address.forContractId(contractAddress).toXdr(),
    XdrInt64(BigInt.zero),
    XdrUint32(0),
    XdrSCVal(XdrSCValType.SCV_VOID),
  );
  final creds = XdrSorobanCredentials(
    XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
  );
  creds.addressV2 = addressCreds;
  return XdrSorobanAuthorizationEntry(creds, invocation);
}

// ---------------------------------------------------------------------------
// Soroban response helpers (mirrors oz_pipeline_group_c_test.dart)
// ---------------------------------------------------------------------------

SimulateTransactionResponse _simResponseWithAuthEntry({
  required XdrSorobanAuthorizationEntry entry,
  int? minResourceFee,
}) {
  final entryXdr = entry.toBase64EncodedXdrString();
  final result = SimulateTransactionResult('', <String>[entryXdr]);
  final r = SimulateTransactionResponse(<String, dynamic>{});
  r.results = <SimulateTransactionResult>[result];
  r.minResourceFee = minResourceFee;
  return r;
}

SimulateTransactionResponse _simResponseEmpty({int? minResourceFee}) {
  final r = SimulateTransactionResponse(<String, dynamic>{});
  r.results = <SimulateTransactionResult>[];
  r.minResourceFee = minResourceFee;
  return r;
}

GetLatestLedgerResponse _latestLedger(int sequence) {
  final r = GetLatestLedgerResponse(<String, dynamic>{});
  r.sequence = sequence;
  return r;
}

SendTransactionResponse _sendPending({required String hash}) {
  final r = SendTransactionResponse(<String, dynamic>{});
  r.hash = hash;
  r.status = SendTransactionResponse.STATUS_PENDING;
  return r;
}

GetTransactionResponse _txSuccess({int ledger = 12345}) {
  final r = GetTransactionResponse(<String, dynamic>{});
  r.status = GetTransactionResponse.STATUS_SUCCESS;
  r.ledger = ledger;
  return r;
}

Account _deployerAccount(KeyPair deployer, {int seq = 1}) {
  return Account(deployer.accountId, BigInt.from(seq));
}

WebAuthnAuthenticationResult _fakeAuthResult() {
  final credIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
  final sig = Uint8List.fromList(<int>[
    0x30, 0x44,
    0x02, 0x20, ..._bytes(32, 1),
    0x02, 0x20, ..._bytes(32, 2),
  ]);
  return WebAuthnAuthenticationResult(
    credentialId: credIdBytes,
    authenticatorData: _bytes(37, 3),
    clientDataJSON: utf8.encode(
      '{"type":"webauthn.get","challenge":"abc","origin":"https://test"}',
    ),
    signature: sig,
  );
}

// ---------------------------------------------------------------------------
// Shared harness (mirrors oz_multi_signer_pipeline_test.dart)
// ---------------------------------------------------------------------------

Future<
    ({
      FakePipelineKit kit,
      MockSorobanServer soroban,
      RecordingWebAuthnProvider provider,
      KeyPair deployer,
      OZStoredCredential stored,
    })> _harness() async {
  final soroban = MockSorobanServer();
  final provider = RecordingWebAuthnProvider();
  final deployer = KeyPair.random();
  final config = OZSmartAccountConfig(
    rpcUrl: 'https://soroban-testnet.stellar.org',
    networkPassphrase: Network.TESTNET.networkPassphrase,
    accountWasmHash: '0' * 64,
    webauthnVerifierAddress: _contractA,
    webauthnProvider: provider,
  );
  final credentials = StubCredentialManager();
  final stored = OZStoredCredential(
    credentialId: _credentialIdB64,
    publicKey: _bytes(65, 4),
    contractId: _contractA,
  );
  credentials.inject(stored);
  final storage = OZInMemoryStorageAdapter();
  await storage.save(stored);
  final kit = FakePipelineKit(
    config: config,
    sorobanServer: soroban,
    deployer: deployer,
    credentialManager: credentials,
    storage: storage,
  )..setConnected(credentialId: _credentialIdB64, contractId: _contractA);
  return (
    kit: kit,
    soroban: soroban,
    provider: provider,
    deployer: deployer,
    stored: stored,
  );
}

/// Passkey key-data blob (65-byte uncompressed public key + credential id).
Uint8List _passkeyKeyData() {
  final pk = Uint8List(65);
  pk[0] = 0x04;
  for (var i = 1; i < 65; i++) pk[i] = (4 + i) & 0xFF;
  final credIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
  return Uint8List(pk.length + credIdBytes.length)
    ..setRange(0, pk.length, pk)
    ..setRange(pk.length, pk.length + credIdBytes.length, credIdBytes);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // oz_transaction_operations.dart:591
  // WITH_DELEGATES throw in _signSimulationAuthEntries.
  //
  // submit() calls _signSimulationAuthEntries when the simulate response
  // contains auth entries.  When the entry has the ADDRESS_WITH_DELEGATES
  // discriminant, line 591 throws SmartAccountTransactionSigningFailed with
  // a message that mentions 'ADDRESS_WITH_DELEGATES'.
  // -------------------------------------------------------------------------
  group('OZTransactionOperations submit — WITH_DELEGATES entry throws (line 591)', () {
    test(
        'submit_withDelegatesAuthEntry_throwsSigningFailed_mentionsAddressWithDelegates',
        () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      // Simulate returns a WITH_DELEGATES entry.  The pipeline must throw
      // before attempting to sign it.
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeWithDelegatesXdrEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));

      final ops = OZTransactionOperations(h.kit);
      await expectLater(
        () => ops.submit(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractB).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          auth: const <XdrSorobanAuthorizationEntry>[],
        ),
        throwsA(
          isA<SmartAccountTransactionSigningFailed>().having(
            (e) => e.message,
            'message',
            contains('ADDRESS_WITH_DELEGATES'),
          ),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // oz_multi_signer_manager.dart:421
  // WITH_DELEGATES throw in the signing loop of submitWithMultipleSigners.
  //
  // The multi-signer pipeline performs the same guard as the single-signer
  // pipeline: when it encounters an ADDRESS_WITH_DELEGATES entry in the
  // auth-entry list returned by simulate, it throws at line 421.
  // -------------------------------------------------------------------------
  group('OZMultiSignerManager submitWithMultipleSigners — WITH_DELEGATES throws (line 421)', () {
    test(
        'submitWithMultipleSigners_withDelegatesEntry_throwsSigningFailed',
        () async {
      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeWithDelegatesXdrEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));

      final keyData = _passkeyKeyData();
      final manager = OZMultiSignerManager(h.kit);
      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractB).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          selectedSigners: <OZSelectedSigner>[
            OZSelectedSignerPasskey(keyData: keyData),
          ],
        ),
        throwsA(
          isA<SmartAccountTransactionSigningFailed>().having(
            (e) => e.message,
            'message',
            contains('ADDRESS_WITH_DELEGATES'),
          ),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // oz_multi_signer_manager.dart:1034-1035  (_innerAddressCredentialsXdr ADDRESS_V2)
  // oz_multi_signer_manager.dart:1053-1054  (_rebuildCredentialsXdr ADDRESS_V2)
  //
  // When the simulate response returns an ADDRESS_V2 entry whose credential
  // address matches the connected contract (_contractA), the signing loop:
  //   1. calls _innerAddressCredentialsXdr  → hits the ADDRESS_V2 arm (1034-1035)
  //   2. calls _rebuildCredentialsXdr       → hits the ADDRESS_V2 arm (1053-1054)
  //      inside _cloneEntryWithExpiration (via the rebuild step in signing)
  //
  // The full pipeline succeeds: after signing the ADDRESS_V2 entry with the
  // passkey, the re-simulate + submit + poll are fed from the mock queue.
  // -------------------------------------------------------------------------
  group('OZMultiSignerManager submitWithMultipleSigners — ADDRESS_V2 entry (lines 1034-1035 + 1053-1054)', () {
    test(
        'submitWithMultipleSigners_addressV2Entry_matchingContract_executesV2Arms',
        () async {
      final h = await _harness();

      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      // Simulation returns an ADDRESS_V2 entry for _contractA (the connected contract).
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressV2XdrEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      // WebAuthn provider returns a valid signature for the passkey signer.
      h.provider.authenticateResponses.add(_fakeAuthResult());
      // Re-simulate after signing.
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 200));
      // Submit + poll.
      h.soroban.sendResponses.add(_sendPending(hash: 'v2-multi-hash'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 9999));

      final keyData = _passkeyKeyData();
      final credentialIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final manager = OZMultiSignerManager(h.kit);
      final result = await manager.submitWithMultipleSigners(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'vote',
            const <XdrSCVal>[],
          ),
        ),
        selectedSigners: <OZSelectedSigner>[
          OZSelectedSignerPasskey(
            keyData: keyData,
            credentialIdBytes: credentialIdBytes,
            transports: const <String>['internal'],
          ),
        ],
        // Custom resolver returns rule ID 0 to bypass on-chain context-rule
        // lookup (which would require additional mock responses).
        resolveContextRuleIds: (entry, idx) async => <int>[0],
      );

      // Pipeline completed successfully — both V2 arms were traversed.
      expect(result.success, isTrue,
          reason: 'ADDRESS_V2 entry must be signed and submitted successfully');
      expect(result.hash, equals('v2-multi-hash'));
      // WebAuthn was invoked exactly once (one auth entry).
      expect(h.provider.authenticateCalls, hasLength(1));

      // The sent transaction must carry an auth entry whose credentials arm
      // is ADDRESS_V2 (the arm was preserved by _rebuildCredentialsXdr).
      expect(h.soroban.sendCalls.length, equals(1));
      final sentTx = h.soroban.sendCalls.single;
      final envelope = sentTx.toEnvelopeXdr();
      // ignore: invalid_use_of_internal_member
      final opAuth =
          envelope.v1!.tx.operations.first.body.invokeHostFunctionOp!.auth;
      expect(opAuth, isNotEmpty);
      expect(
        opAuth.first.credentials.discriminant,
        equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2),
        reason: '_rebuildCredentialsXdr must preserve the ADDRESS_V2 arm on write-back',
      );
    });
  });
}
