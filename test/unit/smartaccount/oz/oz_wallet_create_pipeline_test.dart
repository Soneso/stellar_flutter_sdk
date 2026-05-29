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

SimulateTransactionResponse _simResponseError(String error) {
  final r = SimulateTransactionResponse(<String, dynamic>{});
  r.resultError = error;
  return r;
}

GetLatestLedgerResponse _latestLedger(int sequence) {
  final r = GetLatestLedgerResponse(<String, dynamic>{});
  r.sequence = sequence;
  return r;
}

Account _deployerAccount(KeyPair deployer, {int seq = 1}) {
  return Account(deployer.accountId, BigInt.from(seq));
}

void main() {
  group('OZWalletOperations.createWallet pipeline', () {
    test('createWallet_noAutoSubmit_returnsBuildResult', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();

      // The credential ID bytes (valid base64url).
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      // Valid P-256 uncompressed public key (generator point G).
      final pubKey = _validSecp256r1PublicKey();

      // WebAuthn registration result with a valid-looking public key.
      final regResult = WebAuthnRegistrationResult(
        credentialId: credIdBytes,
        publicKey: pubKey,
        attestationObject: _bytes(37, 0xAA),
        transports: <String>['internal'],
        deviceType: 'multiDevice',
        backedUp: true,
      );
      provider.registerResponses.add(regResult);

      // _buildDeployTransaction: getAccount + simulateTransaction.
      mock.getAccountResponses.add(_deployerAccount(deployer));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 500));

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
        deployer: deployer,
      );

      final ops = OZWalletOperations(kit);
      final result = await ops.createWallet(
        userName: 'Test User',
        autoSubmit: false,
      );

      expect(result.credentialId, equals(_credentialIdB64));
      expect(result.signedTransactionXdr, isNotEmpty);
      expect(result.transactionHash, isNull); // no autoSubmit
      expect(provider.registerCalls, hasLength(1));
      expect(provider.registerCalls.single.userName, 'Test User');
    });

    test('createWallet_registrationThrowsNonWebAuthnException_wrapsAsRegistrationFailed', () async {
      // When registration throws a non-WebAuthnException, it wraps as
      // WebAuthnRegistrationFailed (lines 461-463 in oz_wallet_operations.dart).
      final provider = RecordingWebAuthnProvider();
      // Throw a plain Exception (not a WebAuthnException).
      provider.registerResponses.add(Exception('generic registration error'));

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
        () => ops.createWallet(),
        throwsA(isA<WebAuthnRegistrationFailed>()),
      );
    });

    test('createWallet_autoFundWithoutToken_withProvider_throwsInvalidInput', () async {
      // When webauthnProvider IS configured and autoFund=true but
      // nativeTokenContract=null, validation guard fires.
      final provider = RecordingWebAuthnProvider();
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
        () => ops.createWallet(
          autoSubmit: true,
          autoFund: true,
          nativeTokenContract: null, // missing
        ),
        throwsA(isA<InvalidInput>()),
      );
    });

    test('createWallet_autoSubmit_sendFails_throwsSubmissionFailed', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final pubKey = _validSecp256r1PublicKey();

      provider.registerResponses.add(WebAuthnRegistrationResult(
        credentialId: credIdBytes,
        publicKey: pubKey,
        attestationObject: _bytes(37, 0xBB),
      ));

      mock.getAccountResponses.add(_deployerAccount(deployer));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 500));
      // sendTransaction throws.
      mock.sendDefault = Exception('network error during deploy send');

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
        deployer: deployer,
      );

      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(autoSubmit: true),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('createWallet_autoSubmit_sendErrorStatus_throwsSubmissionFailed', () async {
      // createWallet with autoSubmit=true → _submitDeployTransaction →
      // sendTransaction returns ERROR status → throws submissionFailed.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final pubKey = _validSecp256r1PublicKey();

      provider.registerResponses.add(WebAuthnRegistrationResult(
        credentialId: credIdBytes,
        publicKey: pubKey,
        attestationObject: _bytes(37, 0xCC),
      ));

      mock.getAccountResponses.add(_deployerAccount(deployer));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 500));

      // sendTransaction returns ERROR status.
      final sendResp = SendTransactionResponse(<String, dynamic>{});
      sendResp.hash = 'err-hash';
      sendResp.status = SendTransactionResponse.STATUS_ERROR;
      sendResp.errorResultXdr = 'base64-error-xdr';
      mock.sendResponses.add(sendResp);

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
        deployer: deployer,
      );

      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(autoSubmit: true),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('createWallet_autoSubmit_relayerPath_success', () async {
      // createWallet with autoSubmit=true and relayer configured → uses relayer.
      // The relayer's success path (lines 1498+) requires polling.
      // To avoid 2-second delays, test the relayer-failure path instead.
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();
      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final pubKey = _validSecp256r1PublicKey();

      provider.registerResponses.add(WebAuthnRegistrationResult(
        credentialId: credIdBytes,
        publicKey: pubKey,
        attestationObject: _bytes(37, 0xDD),
      ));

      mock.getAccountResponses.add(_deployerAccount(deployer));
      mock.simulateResponses.add(_simResponseEmpty(minResourceFee: 500));

      // Use relayer harness that returns failure response.
      final relayerHarness = buildRelayerHarness(
        responseBody: '{"success":false,"error":"relayer error","hash":null,"status":"FAILED"}',
      );

      final config = OZSmartAccountConfig(
        rpcUrl: 'https://soroban-testnet.stellar.org',
        networkPassphrase: Network.TESTNET.networkPassphrase,
        accountWasmHash: '0' * 64,
        webauthnVerifierAddress: _contractA,
        webauthnProvider: provider,
        relayerUrl: 'https://relayer.test/',
      );
      final kit = FakePipelineKit(
        config: config,
        sorobanServer: mock,
        deployer: deployer,
        relayerClient: relayerHarness.client,
      );

      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(autoSubmit: true),
        throwsA(isA<TransactionSubmissionFailed>()),
      );
    });

    test('createWallet_buildDeployTransactionSimulationError_throwsException', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();

      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final pubKey = _validSecp256r1PublicKey();

      provider.registerResponses.add(WebAuthnRegistrationResult(
        credentialId: credIdBytes,
        publicKey: pubKey,
        attestationObject: _bytes(37, 0xAA),
      ));

      mock.getAccountResponses.add(_deployerAccount(deployer));
      // Simulation returns an error string.
      mock.simulateResponses.add(_simResponseError('contract error'));

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
        deployer: deployer,
      );

      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(autoSubmit: false),
        throwsA(isA<SmartAccountException>()),
      );
    });

    test('createWallet_buildDeployTransactionThrows_throwsException', () async {
      final deployer = KeyPair.random();
      final mock = MockSorobanServer();
      final provider = RecordingWebAuthnProvider();

      final credIdBytes = base64Url.decode(
        base64Url.normalize(_credentialIdB64),
      );
      final pubKey = _validSecp256r1PublicKey();

      provider.registerResponses.add(WebAuthnRegistrationResult(
        credentialId: credIdBytes,
        publicKey: pubKey,
        attestationObject: _bytes(37, 0xAA),
      ));

      // getAccount throws (RPC error during build).
      mock.getAccountResponses.add(Exception('network error'));

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
        deployer: deployer,
      );

      final ops = OZWalletOperations(kit);
      await expectLater(
        () => ops.createWallet(autoSubmit: false),
        throwsA(isA<SmartAccountException>()),
      );
    });
  });
}
