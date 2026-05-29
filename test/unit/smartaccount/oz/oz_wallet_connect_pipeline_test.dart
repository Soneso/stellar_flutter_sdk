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
const String _credentialIdB64 = 'aGVsbG8tc21hcnQtYWNjb3VudA';

Uint8List _bytes(int length, [int seed = 0]) {
  final out = Uint8List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (seed + i) & 0xFF;
  }
  return out;
}

// P-256 generator point (valid on-curve public key).
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

Uint8List _validSecp256r1PublicKey() {
  final out = Uint8List(65);
  out[0] = 0x04;
  out.setRange(1, 33, _bigIntToBytes(_gx, 32));
  out.setRange(33, 65, _bigIntToBytes(_gy, 32));
  return out;
}

LedgerEntry _fakeLedgerEntry() {
  // Minimal LedgerEntry that passes null check in _verifyContractExists.
  // key and xdr are base64-encoded XDR placeholders that decode without error.
  // Using the simplest possible valid XDR: void ScVal encoded to base64.
  return LedgerEntry.fromJson(<String, dynamic>{
    'key': 'AAAAAA==', // minimal base64 XDR placeholder
    'xdr': 'AAAAAA==', // minimal base64 XDR placeholder
    'lastModifiedLedgerSeq': 1000,
    'liveUntilLedgerSeq': 2000,
  });
}

void main() {
  group('OZConnectWalletConnected equality and copyWith', () {
    test('equalInstances_areEqual', () {
      const a = OZConnectWalletConnected(
        credentialId: _credentialIdB64,
        contractId: _contractA,
        restoredFromSession: false,
      );
      const b = OZConnectWalletConnected(
        credentialId: _credentialIdB64,
        contractId: _contractA,
        restoredFromSession: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differentContractId_notEqual', () {
      const a = OZConnectWalletConnected(
        credentialId: _credentialIdB64,
        contractId: _contractA,
        restoredFromSession: false,
      );
      const b = OZConnectWalletConnected(
        credentialId: _credentialIdB64,
        contractId: 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
        restoredFromSession: false,
      );
      expect(a == b, isFalse);
    });

    test('copyWith_changesRestoredFromSession', () {
      const original = OZConnectWalletConnected(
        credentialId: _credentialIdB64,
        contractId: _contractA,
        restoredFromSession: false,
      );
      final copy = original.copyWith(restoredFromSession: true);
      expect(copy.restoredFromSession, isTrue);
      expect(copy.contractId, equals(_contractA));
    });
  });

  group('OZConnectWalletResult polymorphism', () {
    test('connected_and_ambiguous_are_different_subtypes', () {
      const connected = OZConnectWalletConnected(
        credentialId: _credentialIdB64,
        contractId: _contractA,
        restoredFromSession: false,
      );
      final ambiguous = OZConnectWalletAmbiguous(
        credentialId: _credentialIdB64,
        candidates: <String>[_contractA],
      );
      expect(connected, isA<OZConnectWalletConnected>());
      expect(ambiguous, isA<OZConnectWalletAmbiguous>());
      expect(connected == ambiguous, isFalse);
    });
  });

  group('OZWalletOperations.connectWallet authentication error paths', () {
    test('webAuthnThrowsGenericException_wrapsAsAuthenticationFailed', () async {
      // When the WebAuthn provider throws a non-WebAuthnException during
      // connectWallet, lines 715-717 wrap it.
      final provider = RecordingWebAuthnProvider();
      provider.authenticateResponses.add(Exception('network error'));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(config: config);
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.connectWallet(options: const ConnectWalletOptions(prompt: true)),
        throwsA(isA<WebAuthnAuthenticationFailed>()),
      );
    });

    test('connectWallet_derivedContractOnChain_returnsConnected', () async {
      // _resolveViaDerivation finds the contract on-chain (lines 725-735).
      // No credential in storage → derivation is tried.
      // The credential manager has no credential → storage lookup returns null.
      // Then derivation is tried: deriveContractAddress + verifyContractExists.
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
      final sig = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20, ..._bytes(32, 1),
        0x02, 0x20, ..._bytes(32, 2),
      ]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37, 3),
        clientDataJSON: utf8.encode('{"type":"webauthn.get","challenge":"abc","origin":"https://test"}'),
        signature: sig,
      ));

      final mock = MockSorobanServer();
      // getContractData returns a LedgerEntry → contract is on-chain (derivation succeeds).
      // Add two entries: one for _resolveViaDerivation, one for _finalizeConnect.
      mock.getContractDataResponses.add(_fakeLedgerEntry());
      mock.getContractDataResponses.add(_fakeLedgerEntry());

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      // No credential in storage → storage lookup returns null.
      final kit = FakePipelineKit(config: config, sorobanServer: mock);
      final ops = OZWalletOperations(kit);

      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(prompt: true),
      );

      expect(result, isNotNull);
      expect(result, isA<OZConnectWalletConnected>());
    });
  });

  group('OZWalletOperations.connectWallet indexer edge cases', () {
    test('indexerReturnsEmpty_throwsWalletNotFound', () async {
      // _resolveViaIndexer with empty candidates → line 1258 throws WalletNotFound.
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
      final sig = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20, ..._bytes(32, 1),
        0x02, 0x20, ..._bytes(32, 2),
      ]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37),
        clientDataJSON: utf8.encode('{"type":"webauthn.get","challenge":"abc"}'),
        signature: sig,
      ));

      final mock = MockSorobanServer();
      // Storage: no credential. Derivation: not on-chain.
      mock.getContractDataResponses.add(null); // derivation check

      // Indexer returns empty contracts.
      final indexerJson = jsonEncode(<String, dynamic>{
        'credentialId': _credentialIdB64,
        'contracts': <Map<String, dynamic>>[],
        'count': 0,
      });
      final indexerHarness = buildIndexerHarness(responseBody: indexerJson);

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        indexerClient: indexerHarness.client,
      );
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.connectWallet(options: const ConnectWalletOptions(prompt: true)),
        throwsA(isA<WalletNotFound>()),
      );
    });
  });

  group('OZWalletOperations.connectWallet indexer resolution', () {
    test('indexerResolvesOneCandidate_contractOnChain_returnsConnected', () async {
      // _resolveViaIndexer with one candidate that verifies → OZConnectWalletConnected.
      // Covers lines 1262-1265 in oz_wallet_operations.dart.
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
      final sig = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20, ..._bytes(32, 1),
        0x02, 0x20, ..._bytes(32, 2),
      ]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37, 3),
        clientDataJSON: utf8.encode('{"type":"webauthn.get","challenge":"abc","origin":"https://test"}'),
        signature: sig,
      ));

      // No credential in storage → storage lookup returns null.
      // No contract at derived address → derivation returns null.
      // Indexer returns one candidate.
      final mock = MockSorobanServer();
      // Derivation check: getContractData returns null (not at derived address).
      mock.getContractDataResponses.add(null);
      // Indexer verification: getContractData returns LedgerEntry (candidate exists).
      mock.getContractDataResponses.add(_fakeLedgerEntry());
      // _finalizeConnect → _connectWithCredentials → _verifyContractExists.
      mock.getContractDataResponses.add(_fakeLedgerEntry());

      // Indexer returns one candidate matching _contractA.
      final indexerJson = jsonEncode(<String, dynamic>{
        'credentialId': _credentialIdB64,
        'contracts': <Map<String, dynamic>>[
          <String, dynamic>{
            'contract_id': _contractA,
            'context_rule_count': 1,
            'external_signer_count': 1,
            'delegated_signer_count': 0,
            'native_signer_count': 0,
            'first_seen_ledger': 1000,
            'last_seen_ledger': 2000,
            'context_rule_ids': <int>[0],
          },
        ],
        'count': 1,
      });
      final indexerHarness = buildIndexerHarness(responseBody: indexerJson);

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        indexerClient: indexerHarness.client,
      );
      final ops = OZWalletOperations(kit);

      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(prompt: true),
      );

      expect(result, isNotNull);
      expect(result, isA<OZConnectWalletConnected>());
      final connected = result as OZConnectWalletConnected;
      expect(connected.contractId, equals(_contractA));
    });
  });

  group('OZWalletOperations.connectWallet session restoration pipeline', () {
    test('validSession_contractOnChain_returnsConnectedFromSession', () async {
      // Restore from a valid non-expired session when the contract is on-chain.
      final storage = InMemoryStorageAdapter();
      await storage.saveSession(
        StoredSession(
          credentialId: _credentialIdB64,
          contractId: _contractA,
          connectedAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
        ),
      );

      final mock = MockSorobanServer();
      // getContractData returns a non-null LedgerEntry → contract is on-chain.
      mock.getContractDataResponses.add(_fakeLedgerEntry());

      final kit = FakePipelineKit(storage: storage, sorobanServer: mock);
      final ops = OZWalletOperations(kit);

      final result = await ops.connectWallet();

      expect(result, isNotNull);
      expect(result, isA<OZConnectWalletConnected>());
      final connected = result as OZConnectWalletConnected;
      expect(connected.contractId, equals(_contractA));
      expect(connected.credentialId, equals(_credentialIdB64));
      expect(connected.restoredFromSession, isTrue);
    });
  });

  group('OZWalletOperations.connectWallet WebAuthn prompt pipeline', () {
    test('promptConnect_credentialFoundInStorage_contractOnChain_returnsConnected', () async {
      // Prompt=true + WebAuthn auth → credential found in storage → contract on-chain.
      final credentials = StubCredentialManager();
      final pubKey = _validSecp256r1PublicKey();
      credentials.inject(StoredCredential(
        credentialId: _credentialIdB64,
        publicKey: pubKey,
        contractId: _contractA,
        deploymentStatus: CredentialDeploymentStatus.pending,
        createdAt: 1700000000000,
      ));

      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final sig = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20, ..._bytes(32, 1),
        0x02, 0x20, ..._bytes(32, 2),
      ]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37, 3),
        clientDataJSON: utf8.encode(
          '{"type":"webauthn.get","challenge":"abc","origin":"https://test"}',
        ),
        signature: sig,
      ));

      final mock = MockSorobanServer();
      // getContractData returns a LedgerEntry (contract is on-chain).
      mock.getContractDataResponses.add(_fakeLedgerEntry());

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        credentialManager: credentials,
      );
      final ops = OZWalletOperations(kit);

      final result = await ops.connectWallet(
        options: const ConnectWalletOptions(prompt: true),
      );

      expect(result, isNotNull);
      expect(result, isA<OZConnectWalletConnected>());
      final connected = result as OZConnectWalletConnected;
      expect(connected.contractId, equals(_contractA));
    });
  });

  group('OZWalletOperations.authenticatePasskey edge cases', () {
    test('authThrowsGenericException_wrapsAsAuthenticationFailed', () async {
      // When the WebAuthn provider throws a non-WebAuthnException,
      // lines 872-873 wrap it as WebAuthnAuthenticationFailed.
      final provider = RecordingWebAuthnProvider();
      provider.authenticateResponses.add(Exception('generic auth error'));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(config: config);
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.authenticatePasskey(),
        throwsA(isA<WebAuthnAuthenticationFailed>()),
      );
    });

    test('invalidSignature_throwsValidationException', () async {
      // When the WebAuthn signature is malformed, normalizeSignature throws
      // ValidationException which is rethrown via line 906 of oz_wallet_operations.
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(base64Url.normalize(_credentialIdB64));
      // Invalid DER signature (wrong prefix).
      final invalidSig = Uint8List.fromList(<int>[0xFF, 0x00, 0x01]);

      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37),
        clientDataJSON: utf8.encode('{"type":"webauthn.get","challenge":"abc"}'),
        signature: invalidSig,
      ));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(config: config);
      final ops = OZWalletOperations(kit);

      await expectLater(
        () => ops.authenticatePasskey(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('credentialIdMismatch_throwsCredentialInvalid', () async {
      // When allowCredentials is specified and the returned credentialId
      // doesn't match, line 892 throws CredentialInvalid.
      final provider = RecordingWebAuthnProvider();
      final requestedCredIdBytes = Uint8List.fromList(<int>[0x01, 0x02, 0x03]);
      final returnedCredIdBytes = Uint8List.fromList(<int>[0x99, 0x98]); // different

      final sig = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20, ..._bytes(32, 1),
        0x02, 0x20, ..._bytes(32, 2),
      ]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: returnedCredIdBytes, // different from requested
        authenticatorData: _bytes(37),
        clientDataJSON: utf8.encode('{"type":"webauthn.get","challenge":"abc"}'),
        signature: sig,
      ));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(config: config);
      final ops = OZWalletOperations(kit);

      // Provide credentialIds to restrict which credential can be returned.
      await expectLater(
        () => ops.authenticatePasskey(
          credentialIds: <String>[base64Url.encode(requestedCredIdBytes)],
        ),
        throwsA(isA<CredentialInvalid>()),
      );
    });
  });

  group('OZWalletOperations.authenticatePasskey', () {
    test('authenticatePasskey_withProvider_success', () async {
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final sig = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20, ..._bytes(32, 1),
        0x02, 0x20, ..._bytes(32, 2),
      ]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37, 3),
        clientDataJSON: utf8.encode(
          '{"type":"webauthn.get","challenge":"abc","origin":"https://test"}',
        ),
        signature: sig,
      ));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(config: config);
      final ops = OZWalletOperations(kit);

      final result = await ops.authenticatePasskey();

      expect(result.credentialId, equals(_credentialIdB64));
      expect(result.signature, isNotNull);
    });

    test('authenticatePasskey_withCustomChallenge_usesChallenge', () async {
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final sig = Uint8List.fromList(<int>[
        0x30, 0x44,
        0x02, 0x20, ..._bytes(32, 1),
        0x02, 0x20, ..._bytes(32, 2),
      ]);
      provider.authenticateResponses.add(WebAuthnAuthenticationResult(
        credentialId: credIdBytes,
        authenticatorData: _bytes(37),
        clientDataJSON: utf8.encode(
          '{"type":"webauthn.get","challenge":"xyz","origin":"https://test"}',
        ),
        signature: sig,
      ));

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
      );
      final kit = FakePipelineKit(config: config);
      final ops = OZWalletOperations(kit);
      final challenge = _bytes(32, 99);

      final result = await ops.authenticatePasskey(challenge: challenge);

      expect(result.credentialId, equals(_credentialIdB64));
      expect(provider.authenticateCalls.single.challenge, equals(challenge));
    });
  });
}
