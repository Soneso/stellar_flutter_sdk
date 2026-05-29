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

XdrSorobanAuthorizationEntry _makeAddressCredsEntry(String contractAddress) {
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

WebAuthnAuthenticationResult _fakeAuthResult({
  Uint8List? credentialIdBytes,
}) {
  final credIdBytes = credentialIdBytes ??
      base64Url.decode(base64Url.normalize(_credentialIdB64));
  final sig = Uint8List.fromList(<int>[
    0x30, 0x44,
    0x02, 0x20,
    ..._bytes(32, 1),
    0x02, 0x20,
    ..._bytes(32, 2),
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

Account _deployerAccount(KeyPair deployer, {int seq = 1}) {
  return Account(deployer.accountId, BigInt.from(seq));
}

Uint8List _passkeyKeyData() {
  final pk = Uint8List(65);
  pk[0] = 0x04;
  for (var i = 1; i < 65; i++) pk[i] = (4 + i) & 0xFF;
  final credIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
  return Uint8List(pk.length + credIdBytes.length)
    ..setRange(0, pk.length, pk)
    ..setRange(pk.length, pk.length + credIdBytes.length, credIdBytes);
}

Future<
    ({
      FakePipelineKit kit,
      MockSorobanServer soroban,
      RecordingWebAuthnProvider provider,
      KeyPair deployer,
      StoredCredential stored,
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
  final stored = StoredCredential(
    credentialId: _credentialIdB64,
    publicKey: _bytes(65, 4),
    contractId: _contractA,
  );
  credentials.inject(stored);
  final storage = InMemoryStorageAdapter();
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

/// A wallet adapter that always reports it can sign for a specific address
/// and returns a dummy signature.
class _AlwaysSignWallet extends ExternalWalletAdapter {
  _AlwaysSignWallet(this._address);

  final String _address;

  @override
  Future<ConnectedWallet?> connect() async => ConnectedWallet(
        address: _address,
        walletId: 'test-wallet',
        walletName: 'Test Wallet',
      );

  @override
  Future<void> disconnect() async {}

  @override
  bool canSignFor(String address) => address == _address;

  @override
  List<ConnectedWallet> getConnectedWallets() => <ConnectedWallet>[
        ConnectedWallet(
          address: _address,
          walletId: 'test-wallet',
          walletName: 'Test Wallet',
        ),
      ];

  @override
  ConnectedWallet? getWalletForAddress(String address) {
    if (address != _address) return null;
    return ConnectedWallet(
      address: _address,
      walletId: 'test-wallet',
      walletName: 'Test Wallet',
    );
  }

  @override
  Future<SignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    SignAuthEntryOptions? options,
  }) async {
    // Return a dummy 64-byte signature (all zeros) encoded as base64.
    final dummySig = List<int>.filled(64, 0);
    return SignAuthEntryResult(
      signedAuthEntry: base64.encode(dummySig),
      signerAddress: _address,
    );
  }
}

void main() {
  group('OZMultiSignerManager - passkey signing pipeline', () {
    test('passkey_fullPipeline_success', () async {
      final h = await _harness();

      // Deployer account.
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      // Initial simulation returns one auth entry targeting the smart account.
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(1000));
      // WebAuthn provider returns a valid auth result.
      h.provider.authenticateResponses.add(_fakeAuthResult());
      // Re-simulate after signing.
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 200));
      // Submit + poll.
      h.soroban.sendResponses.add(_sendPending(hash: 'multi-hash'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 9999));

      final manager = OZMultiSignerManager(h.kit);
      final hostFn = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractB).toXdr(),
          'vote',
          const <XdrSCVal>[],
        ),
      );

      final keyData = _passkeyKeyData();
      // Also provide credentialIdBytes to cover the allowCredentials branch.
      final credentialIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
      final result = await manager.submitWithMultipleSigners(
        hostFunction: hostFn,
        selectedSigners: <SelectedSigner>[
          SelectedSignerPasskey(
            keyData: keyData,
            credentialIdBytes: credentialIdBytes,
            transports: const <String>['internal'],
          ),
        ],
      );

      expect(result.success, isTrue);
      expect(result.hash, equals('multi-hash'));
      expect(h.provider.authenticateCalls, hasLength(1));
    });

    test('passkey_customResolveContextRuleIds_isUsed', () async {
      final h = await _harness();

      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(500));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 150));
      h.soroban.sendResponses.add(_sendPending(hash: 'resolved-hash'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 5000));

      var resolverCalled = false;
      final manager = OZMultiSignerManager(h.kit);
      final hostFn = XdrHostFunction.forInvokingContractWithArgs(
        XdrInvokeContractArgs(
          Address.forContractId(_contractB).toXdr(),
          'vote',
          const <XdrSCVal>[],
        ),
      );

      final keyData = _passkeyKeyData();
      final result = await manager.submitWithMultipleSigners(
        hostFunction: hostFn,
        selectedSigners: <SelectedSigner>[
          SelectedSignerPasskey(keyData: keyData),
        ],
        resolveContextRuleIds: (entry, idx) async {
          resolverCalled = true;
          return <int>[0];
        },
      );

      expect(result.success, isTrue);
      expect(resolverCalled, isTrue);
    });

    test('multiSignerExecuteAndSubmit_passkeyFullPipeline', () async {
      final h = await _harness();

      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(800));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 120));
      h.soroban.sendResponses.add(_sendPending(hash: 'exec-hash'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 8001));

      final manager = OZMultiSignerManager(h.kit);
      final keyData = _passkeyKeyData();

      final result = await manager.multiSignerExecuteAndSubmit(
        target: _contractB,
        targetFn: 'execute_me',
        selectedSigners: <SelectedSigner>[
          SelectedSignerPasskey(keyData: keyData),
        ],
      );

      expect(result.success, isTrue);
      expect(result.hash, equals('exec-hash'));
    });

    test('multiSignerTransfer_passkeyFullPipeline', () async {
      final h = await _harness();

      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(300));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 80));
      h.soroban.sendResponses.add(_sendPending(hash: 'transfer-hash'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 3001));

      final manager = OZMultiSignerManager(h.kit);
      final keyData = _passkeyKeyData();

      final result = await manager.multiSignerTransfer(
        tokenContract: _contractB,
        recipient: 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
        amount: '10',
        selectedSigners: <SelectedSigner>[
          SelectedSignerPasskey(keyData: keyData),
        ],
      );

      expect(result.success, isTrue);
    });

    test('walletSigner_authEntryForWalletAddress_signsEntry', () async {
      // When simulation returns an auth entry pointing at the wallet signer's
      // G-address, the pipeline routes to _signWalletAddressAuthEntry
      // (lines 368-380 in oz_multi_signer_manager.dart).
      final walletAddress =
          'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
      final walletAdapter = _AlwaysSignWallet(walletAddress);

      // Build an auth entry with ADDRESS credentials for the wallet address.
      final walletAddrXdr = Address.forAccountId(walletAddress).toXdr();
      final invokeArgs = XdrInvokeContractArgs(
        Address.forContractId(_contractB).toXdr(),
        'noop',
        const <XdrSCVal>[],
      );
      final invocation = XdrSorobanAuthorizedInvocation(
        XdrSorobanAuthorizedFunction.forInvokeContractArgs(invokeArgs),
        <XdrSorobanAuthorizedInvocation>[],
      );
      final placeholderSig = XdrSCVal(XdrSCValType.SCV_VOID);
      final addressCreds = XdrSorobanAddressCredentials(
        walletAddrXdr,
        XdrInt64(BigInt.from(0)),
        XdrUint32(0),
        placeholderSig,
      );
      final walletEntry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forAddressCredentials(addressCreds),
        invocation,
      );
      final entryXdr = walletEntry.toBase64EncodedXdrString();

      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(_deployerAccount(deployer));
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[entryXdr]),
      ];
      mock.simulateResponses.add(simResp);
      mock.latestLedgerResponses.add(_latestLedger(200));
      mock.getAccountResponses.add(_deployerAccount(deployer, seq: 2));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 60));
      mock.sendResponses.add(_sendPending(hash: 'wallet-addr-hash'));
      mock.pollResponses.add(_txSuccess(ledger: 2001));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
      );
      kit.setExternalWallet(walletAdapter);
      kit.setConnected(credentialId: _credentialIdB64, contractId: _contractA);

      final manager = OZMultiSignerManager(kit);
      final result = await manager.submitWithMultipleSigners(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        selectedSigners: <SelectedSigner>[
          SelectedSignerWallet(walletAddress),
        ],
      );

      expect(result.success, isTrue);
    });

    test('walletSigner_smartAccountAuthEntry_signsViaCheckAuth', () async {
      // When a wallet signer participates in signing a smart-account auth entry,
      // lines 482-536 execute (wallet produces __check_auth delegated entry).
      final walletAddress =
          'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
      final walletAdapter = _AlwaysSignWallet(walletAddress);

      final h = await _harness();
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      // Smart-account auth entry (points at _contractA, the connected contract).
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(_contractA),
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(600));
      h.provider.authenticateResponses.add(_fakeAuthResult());
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 80));
      h.soroban.sendResponses.add(_sendPending(hash: 'wallet-sa-hash'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 6001));

      h.kit.setExternalWallet(walletAdapter);

      final keyData = _passkeyKeyData();
      final manager = OZMultiSignerManager(h.kit);
      final result = await manager.submitWithMultipleSigners(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'vote',
            const <XdrSCVal>[],
          ),
        ),
        selectedSigners: <SelectedSigner>[
          SelectedSignerPasskey(keyData: keyData),
          SelectedSignerWallet(walletAddress),
        ],
      );

      expect(result.success, isTrue);
    });

    test('walletSigner_authEntryForUnmatchedAddress_throwsSigningFailed', () async {
      // When auth entry address is neither the smart-account contract nor
      // a wallet signer address, line 382 throws TransactionSigningFailed.
      final walletAddress =
          'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
      final unmatchedAddress =
          'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
      final walletAdapter = _AlwaysSignWallet(walletAddress);

      // Auth entry for an address not in selectedSigners.
      final addrXdr = Address.forAccountId(unmatchedAddress).toXdr();
      final invArgs = XdrInvokeContractArgs(
        Address.forContractId(_contractB).toXdr(),
        'noop',
        const <XdrSCVal>[],
      );
      final inv = XdrSorobanAuthorizedInvocation(
        XdrSorobanAuthorizedFunction.forInvokeContractArgs(invArgs),
        <XdrSorobanAuthorizedInvocation>[],
      );
      final addrCreds = XdrSorobanAddressCredentials(
        addrXdr,
        XdrInt64(BigInt.from(0)),
        XdrUint32(0),
        XdrSCVal(XdrSCValType.SCV_VOID),
      );
      final entry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forAddressCredentials(addrCreds),
        inv,
      );

      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(_deployerAccount(deployer));
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[entry.toBase64EncodedXdrString()]),
      ];
      mock.simulateResponses.add(simResp);
      mock.latestLedgerResponses.add(_latestLedger(50));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
      );
      kit.setExternalWallet(walletAdapter);
      kit.setConnected(credentialId: _credentialIdB64, contractId: _contractA);

      final manager = OZMultiSignerManager(kit);
      await expectLater(
        () => manager.submitWithMultipleSigners(
          hostFunction: XdrHostFunction.forInvokingContractWithArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractB).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          selectedSigners: <SelectedSigner>[
            SelectedSignerWallet(walletAddress), // wallet signs walletAddress entries
            // but the auth entry points to unmatchedAddress - no match
          ],
        ),
        throwsA(isA<TransactionSigningFailed>()),
      );
    });

    test('walletSigner_withSourceAccountEntry_passthroughWithoutWalletSign', () async {
      // When the only selected signer is a wallet signer and all auth entries
      // are source-account type (not targeting a wallet address), the entries
      // pass through unsigned. The wallet signer's address is added to the
      // smartAccountSigners list for context-rule resolution (lines 339-340).
      final sourceAccountEntry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forInvokeContractArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractB).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      );
      final entryXdr = sourceAccountEntry.toBase64EncodedXdrString();

      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(_deployerAccount(deployer));
      final simResp = SimulateTransactionResponse(<String, dynamic>{});
      simResp.results = <SimulateTransactionResult>[
        SimulateTransactionResult('', <String>[entryXdr]),
      ];
      mock.simulateResponses.add(simResp);
      mock.latestLedgerResponses.add(_latestLedger(100));

      // Re-simulate.
      mock.getAccountResponses.add(_deployerAccount(deployer, seq: 2));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 50));

      // submit + poll.
      final sendResp = SendTransactionResponse(<String, dynamic>{});
      sendResp.hash = 'wallet-hash';
      sendResp.status = SendTransactionResponse.STATUS_PENDING;
      mock.sendResponses.add(sendResp);
      mock.pollResponses.add(_txSuccess(ledger: 200));

      // A wallet adapter that can sign for the wallet address.
      final walletAddress =
          'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';
      final walletAdapter = _AlwaysSignWallet(walletAddress);

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
      );
      kit.setExternalWallet(walletAdapter);
      kit.setConnected(credentialId: _credentialIdB64, contractId: _contractA);

      final manager = OZMultiSignerManager(kit);
      final result = await manager.submitWithMultipleSigners(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        selectedSigners: <SelectedSigner>[
          SelectedSignerWallet(walletAddress),
        ],
      );

      expect(result.success, isTrue);
    });

    test('ed25519Signer_fullPipeline_signsSmartAccountEntry', () async {
      // Full pipeline with Ed25519 signer + smart-account auth entry.
      // Covers lines 688-736 in oz_multi_signer_manager.dart.
      final extManager = OZExternalSignerManager(
        networkPassphrase: Network.TESTNET.networkPassphrase,
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 20));
      final publicKey = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _contractA,
      );

      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(_deployerAccount(deployer));
      // Smart-account auth entry targeting _contractA (the connected contract).
      mock.simulateResponses.add(_simResponseWithAuthEntry(
        entry: _makeAddressCredsEntry(_contractA),
        minResourceFee: 100,
      ));
      mock.latestLedgerResponses.add(_latestLedger(300));
      // Re-simulate after signing.
      mock.getAccountResponses.add(_deployerAccount(deployer, seq: 2));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 80));
      mock.sendResponses.add(_sendPending(hash: 'ed25519-sa-hash'));
      mock.pollResponses.add(_txSuccess(ledger: 3001));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
        externalSignerManager: extManager,
      );
      kit.setConnected(credentialId: _credentialIdB64, contractId: _contractA);

      final manager = OZMultiSignerManager(kit);
      final result = await manager.submitWithMultipleSigners(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        selectedSigners: <SelectedSigner>[
          SelectedSignerEd25519(
            verifierAddress: _contractA,
            publicKey: publicKey,
          ),
        ],
        // Use a custom resolver returning rule ID 0.
        resolveContextRuleIds: (entry, idx) async => <int>[0],
      );

      expect(result.success, isTrue);
    });

    test('ed25519Signer_hoist_executes_lines341_345', () async {
      // When an SelectedSignerEd25519 is in selectedSigners, the hoist loop
      // at lines 341-345 in oz_multi_signer_manager.dart executes.
      // The Ed25519 signing path requires a matching signer in extManager.
      final extManager = OZExternalSignerManager(
        networkPassphrase: Network.TESTNET.networkPassphrase,
      );
      final rawSeed = Uint8List.fromList(List<int>.generate(32, (i) => i + 10));
      final publicKey = extManager.addEd25519FromRawKey(
        secretKeyBytes: rawSeed,
        verifierAddress: _contractA,
      );

      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      mock.getAccountResponses.add(_deployerAccount(deployer));
      // Source-account entry passes through; no smart-account entry to sign.
      final sourceAccountEntry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forInvokeContractArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractB).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      );
      mock.simulateResponses.add(_simResponseWithAuthEntry(
        entry: sourceAccountEntry,
        minResourceFee: 100,
      ));
      mock.latestLedgerResponses.add(_latestLedger(500));
      mock.getAccountResponses.add(_deployerAccount(deployer, seq: 2));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 80));
      mock.sendResponses.add(_sendPending(hash: 'ed25519-hash'));
      mock.pollResponses.add(_txSuccess(ledger: 5001));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        // No webauthnProvider: source-account entries don't need passkey signing.
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
        externalSignerManager: extManager,
      );
      kit.setConnected(credentialId: _credentialIdB64, contractId: _contractA);

      final manager = OZMultiSignerManager(kit);
      final result = await manager.submitWithMultipleSigners(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        selectedSigners: <SelectedSigner>[
          SelectedSignerEd25519(
            verifierAddress: _contractA,
            publicKey: publicKey,
          ),
        ],
      );

      expect(result.success, isTrue);
    });

    test('sourceAccountEntry_passesThrough', () async {
      final h = await _harness();

      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer));
      // Simulation returns a SOURCE_ACCOUNT entry (not our contract).
      final sourceAccountEntry = XdrSorobanAuthorizationEntry(
        XdrSorobanCredentials.forSourceAccount(),
        XdrSorobanAuthorizedInvocation(
          XdrSorobanAuthorizedFunction.forInvokeContractArgs(
            XdrInvokeContractArgs(
              Address.forContractId(_contractB).toXdr(),
              'noop',
              const <XdrSCVal>[],
            ),
          ),
          <XdrSorobanAuthorizedInvocation>[],
        ),
      );
      h.soroban.simulateResponses.add(_simResponseWithAuthEntry(
        entry: sourceAccountEntry,
        minResourceFee: 100,
      ));
      h.soroban.latestLedgerResponses.add(_latestLedger(100));
      // No WebAuthn needed since source-account entry passes through.
      h.soroban.getAccountResponses.add(_deployerAccount(h.deployer, seq: 2));
      h.soroban.simulateResponses.add(_simResponseEmpty(minResourceFee: 50));
      h.soroban.sendResponses.add(_sendPending(hash: 'pass-thru-hash'));
      h.soroban.pollResponses.add(_txSuccess(ledger: 1001));

      final manager = OZMultiSignerManager(h.kit);
      final keyData = _passkeyKeyData();

      final result = await manager.submitWithMultipleSigners(
        hostFunction: XdrHostFunction.forInvokingContractWithArgs(
          XdrInvokeContractArgs(
            Address.forContractId(_contractB).toXdr(),
            'noop',
            const <XdrSCVal>[],
          ),
        ),
        selectedSigners: <SelectedSigner>[
          SelectedSignerPasskey(keyData: keyData),
        ],
      );

      expect(result.success, isTrue);
      // Provider should NOT have been called since entry was source-account.
      expect(h.provider.authenticateCalls, isEmpty);
    });
  });
}
