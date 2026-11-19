// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Integration tests for the Stellar Asset Contract client (SACClient) on
// testnet, plus one offline test.
//
// 'SAC client against testnet' deploys the Stellar Asset Contract of a classic
// TEST asset and checks, in order: the trustlines and the issuer's payment to A;
// the detection of the embedded spec by SorobanClient (17 functions); the
// read-only balance, decimals, name and symbol; a transfer from A to B with A as
// the source; a transfer from A to a muxed account of B, with the decoded
// transfer event; a transfer with the issuer as the source, which needs A's
// authorization entry; and the read-only reads of the native (XLM) contract.
//
// 'SAC transfer to a muxed contract' transfers to a muxed contract address (W...)
// and checks the to_muxed_id of its transfer event and the balance of the base
// contract. It skips on a network below protocol 30.
//
// 'protocol gate' checks the protocol gate of the muxed contract test offline,
// on a mocked RPC: protocol 30 passes, protocol 29 does not, and an answer
// without a protocol version or with a JSON-RPC error throws.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../tests_util.dart';

const String _testnetRpcUrl = 'https://soroban-testnet.stellar.org';
const String _gateRpcUrl = 'https://rpc.invalid/soroban';

/// The contract id of the native asset on testnet.
const String _testnetXlmContractId =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';

/// The accounts and the Stellar Asset Contract of one test.
class _Context {
  _Context({
    required this.issuer,
    required this.a,
    required this.b,
    required this.asset,
    required this.sacId,
  });

  final KeyPair issuer;
  final KeyPair a;
  final KeyPair b;
  final Asset asset;
  final String sacId;
}

/// Creates three funded accounts and derives the contract id of their TEST
/// asset. Each network test calls it, so every test stands alone.
Future<_Context> _createContext(SorobanServer server, StellarSDK sdk) async {
  final issuer = KeyPair.random();
  final a = KeyPair.random();
  final b = KeyPair.random();
  for (final keyPair in [issuer, a, b]) {
    await fundTestAccountAndAwaitVisibility(
      keyPair.accountId,
      rpc: server,
      horizon: sdk,
    );
  }
  final asset = AssetTypeCreditAlphaNum4('TEST', issuer.accountId);
  return _Context(
    issuer: issuer,
    a: a,
    b: b,
    asset: asset,
    sacId: asset.contractId(Network.TESTNET),
  );
}

/// Sets up the trustlines of A and B, deploys the Stellar Asset Contract of
/// the asset, and pays A 1000 TEST from the issuer.
Future<void> _prepareSac(
  SorobanServer server,
  StellarSDK sdk,
  _Context c,
) async {
  // Trustlines: one issuer transaction with a change-trust operation for each
  // of A and B as source.
  final issuerAccount = await server.getAccount(c.issuer.accountId);
  expect(issuerAccount, isNotNull);
  final trustA = ChangeTrustOperationBuilder(c.asset, '1000000');
  trustA.setSourceAccount(c.a.accountId);
  final trustB = ChangeTrustOperationBuilder(c.asset, '1000000');
  trustB.setSourceAccount(c.b.accountId);
  final trustTx = TransactionBuilder(
    issuerAccount!,
  ).addOperation(trustA.build()).addOperation(trustB.build()).build();
  trustTx.sign(c.issuer, Network.TESTNET);
  trustTx.sign(c.a, Network.TESTNET);
  trustTx.sign(c.b, Network.TESTNET);
  final trustResponse = await sdk.submitTransaction(trustTx);
  expect(trustResponse.success, isTrue);
  await Future.delayed(const Duration(seconds: 5));

  // Deploy the Stellar Asset Contract with the issuer as source.
  final deployOperation = InvokeHostFuncOpBuilder(
    DeploySACWithAssetHostFunction(c.asset),
  ).build();
  final deployOptions = AssembledTransactionOptions(
    clientOptions: ClientOptions(
      sourceAccountKeyPair: c.issuer,
      contractId: c.sacId,
      network: Network.TESTNET,
      rpcUrl: _testnetRpcUrl,
      server: server,
    ),
    methodOptions: MethodOptions(),
    method: 'deploy_sac',
  );
  final deployTx = await AssembledTransaction.buildWithOp(
    operation: deployOperation,
    options: deployOptions,
  );
  final deployResponse = await deployTx.signAndSend();
  expect(deployResponse.status, GetTransactionResponse.STATUS_SUCCESS);
  expect(
    StrKey.encodeContractIdHex(deployResponse.getCreatedContractId()!),
    c.sacId,
  );

  // The issuer pays A 1000 TEST.
  await Future.delayed(const Duration(seconds: 5));
  final issuerAfterDeploy = await server.getAccount(c.issuer.accountId);
  expect(issuerAfterDeploy, isNotNull);
  final payment = PaymentOperationBuilder(c.a.accountId, c.asset, '1000');
  final paymentTx = TransactionBuilder(
    issuerAfterDeploy!,
  ).addOperation(payment.build()).build();
  paymentTx.sign(c.issuer, Network.TESTNET);
  final paymentResponse = await sdk.submitTransaction(paymentTx);
  expect(paymentResponse.success, isTrue);
  await Future.delayed(const Duration(seconds: 5));
}

/// Whether the protocol of the network behind [server] is at least [version].
///
/// A JSON-RPC error or an answer without a protocol version throws an
/// [Exception] that names [rpcUrl]. A request failure propagates.
Future<bool> _protocolAtLeast(
  SorobanServer server,
  String rpcUrl,
  int version,
) async {
  final latest = await server.getLatestLedger();
  if (latest.error != null) {
    throw Exception(
      'The network at $rpcUrl returned a JSON-RPC error for getLatestLedger: '
      '${latest.error!.message}',
    );
  }
  final protocolVersion = latest.protocolVersion;
  if (protocolVersion == null) {
    throw Exception(
      'The network at $rpcUrl did not report a protocol version in its '
      'getLatestLedger answer',
    );
  }
  return protocolVersion >= version;
}

class _MockDioAdapter implements dio.HttpClientAdapter {
  _MockDioAdapter(this.onRequest);

  final dio.ResponseBody Function(dio.RequestOptions options) onRequest;

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

/// A server whose every request is answered with [envelope] and whose method
/// is checked to be getLatestLedger.
SorobanServer _gateServer(Map<String, dynamic> envelope) {
  final adapter = _MockDioAdapter((options) {
    final body = jsonDecode(options.data as String) as Map<String, dynamic>;
    if (body['method'] != 'getLatestLedger') {
      fail(
        'The protocol gate mock got an unexpected request: ${body['method']}',
      );
    }
    return dio.ResponseBody.fromString(
      jsonEncode(envelope),
      200,
      headers: {
        'content-type': [dio.Headers.jsonContentType],
      },
    );
  });
  final httpClient = dio.Dio()..httpClientAdapter = adapter;
  return SorobanServer(_gateRpcUrl, httpClient: httpClient);
}

void main() {
  test(
    'SAC client against testnet',
    timeout: const Timeout(Duration(minutes: 10)),
    () async {
      final sorobanServer = SorobanServer(_testnetRpcUrl);
      final sdk = StellarSDK.TESTNET;
      final c = await _createContext(sorobanServer, sdk);
      await _prepareSac(sorobanServer, sdk, c);
      final aId = c.a.accountId;
      final bId = c.b.accountId;
      final issuerId = c.issuer.accountId;

      // Detection: the embedded spec of a SAC has 17 functions.
      final detected = await SorobanClient.forClientOptions(
        options: ClientOptions(
          sourceAccountKeyPair: c.a,
          contractId: c.sacId,
          network: Network.TESTNET,
          rpcUrl: _testnetRpcUrl,
          server: sorobanServer,
        ),
      );
      expect(detected.getMethodNames(), hasLength(17));

      // Read-only reads of the TEST asset.
      final readOnly = SACClient.readOnlyForAsset(
        asset: c.asset,
        network: Network.TESTNET,
        rpcUrl: _testnetRpcUrl,
        server: sorobanServer,
      );
      expect(readOnly.contractId, c.sacId);
      expect(
        await readOnly.balance(Address.forAccountId(aId)),
        BigInt.from(10000000000),
      );
      expect(await readOnly.decimals(), 7);
      expect(await readOnly.name(), 'TEST:$issuerId');
      expect(await readOnly.symbol(), 'TEST');

      // A to B, with A as the source.
      final clientA = SACClient.forAsset(
        asset: c.asset,
        sourceAccountKeyPair: c.a,
        network: Network.TESTNET,
        rpcUrl: _testnetRpcUrl,
        server: sorobanServer,
      );
      final toB = await clientA.transferAndSend(
        to: Address.forAccountId(bId),
        amount: SACClient.toBaseUnits('100'),
      );
      expect(toB.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(
        await readOnly.balance(Address.forAccountId(bId)),
        BigInt.from(1000000000),
      );
      expect(
        await readOnly.balance(Address.forAccountId(aId)),
        BigInt.from(9000000000),
      );

      // A to a muxed account of B.
      final muxedB = Address.forMuxedAccountId(
        MuxedAccount(bId, BigInt.from(4242)).accountId,
      );
      final muxedTx = await clientA.transfer(
        from: Address.forAccountId(aId),
        to: muxedB,
        amount: BigInt.from(250000000),
      );
      final muxedResponse = await muxedTx.signAndSend();
      expect(muxedResponse.status, GetTransactionResponse.STATUS_SUCCESS);
      final muxedEvent = transferEvent(muxedResponse);
      final muxedTopics = muxedEvent.body.v0!.topics;
      expect(Address.fromXdrSCVal(muxedTopics[2]).accountId, bId);
      final muxedData = eventDataMap(muxedEvent);
      expect(muxedData['amount']!.toBigInt(), BigInt.from(250000000));
      expect(muxedData['to_muxed_id']!.u64!.uint64, BigInt.from(4242));
      expect(
        await readOnly.balance(Address.forAccountId(bId)),
        BigInt.from(1250000000),
      );

      // The issuer as the source; A authorizes its transfer.
      final clientIssuer = SACClient.forAsset(
        asset: c.asset,
        sourceAccountKeyPair: c.issuer,
        network: Network.TESTNET,
        rpcUrl: _testnetRpcUrl,
        server: sorobanServer,
      );
      final authTx = await clientIssuer.transfer(
        from: Address.forAccountId(aId),
        to: Address.forAccountId(bId),
        amount: SACClient.toBaseUnits('10.5'),
      );
      expect(authTx.needsNonInvokerSigningBy(), [aId]);
      await authTx.signAuthEntries(signerKeyPair: c.a);
      final authResponse = await authTx.signAndSend();
      expect(authResponse.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(
        await readOnly.balance(Address.forAccountId(bId)),
        BigInt.from(1355000000),
      );

      // The native asset's contract on testnet.
      final xlm = SACClient.readOnlyForAsset(
        asset: Asset.NATIVE,
        network: Network.TESTNET,
        rpcUrl: _testnetRpcUrl,
        server: sorobanServer,
      );
      expect(xlm.contractId, _testnetXlmContractId);
      expect(
        await xlm.balance(Address.forAccountId(aId)),
        greaterThan(BigInt.zero),
      );
      expect(await xlm.decimals(), 7);
      expect(await xlm.name(), 'native');
      expect(await xlm.symbol(), 'native');
    },
  );

  test(
    'SAC transfer to a muxed contract',
    timeout: const Timeout(Duration(minutes: 10)),
    () async {
      final protocolServer = SorobanServer(_testnetRpcUrl);
      if (!await _protocolAtLeast(protocolServer, _testnetRpcUrl, 30)) {
        markTestSkipped(
          'The network at $_testnetRpcUrl runs below protocol 30, the required '
          'version of this test: muxed contract destinations need protocol 30.',
        );
        return;
      }

      final sorobanServer = SorobanServer(_testnetRpcUrl);
      final sdk = StellarSDK.TESTNET;
      final c = await _createContext(sorobanServer, sdk);
      await _prepareSac(sorobanServer, sdk, c);

      final clientA = SACClient.forAsset(
        asset: c.asset,
        sourceAccountKeyPair: c.a,
        network: Network.TESTNET,
        rpcUrl: _testnetRpcUrl,
        server: sorobanServer,
      );
      final muxedContract = MuxedContract(c.sacId, BigInt.from(7)).toAddress();
      final tx = await clientA.transfer(
        from: Address.forAccountId(c.a.accountId),
        to: muxedContract,
        amount: BigInt.from(50000000),
      );
      final response = await tx.signAndSend();
      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);

      final event = transferEvent(response);
      expect(eventDataMap(event)['to_muxed_id']!.u64!.uint64, BigInt.from(7));

      final readOnly = SACClient.readOnlyForAsset(
        asset: c.asset,
        network: Network.TESTNET,
        rpcUrl: _testnetRpcUrl,
        server: sorobanServer,
      );
      expect(
        await readOnly.balance(Address.forContractId(c.sacId)),
        BigInt.from(50000000),
      );
    },
  );

  test('protocol gate', () async {
    final atProtocol30 = _gateServer({
      'jsonrpc': '2.0',
      'id': 1,
      'result': {'id': 'ledger-hash', 'protocolVersion': 30, 'sequence': 1},
    });
    expect(await _protocolAtLeast(atProtocol30, _gateRpcUrl, 30), isTrue);

    final atProtocol29 = _gateServer({
      'jsonrpc': '2.0',
      'id': 1,
      'result': {'id': 'ledger-hash', 'protocolVersion': 29, 'sequence': 1},
    });
    expect(await _protocolAtLeast(atProtocol29, _gateRpcUrl, 30), isFalse);

    final withoutVersion = _gateServer({
      'jsonrpc': '2.0',
      'id': 1,
      'result': {'id': 'ledger-hash', 'sequence': 1},
    });
    await expectLater(
      () => _protocolAtLeast(withoutVersion, _gateRpcUrl, 30),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          equals(
            'Exception: The network at https://rpc.invalid/soroban did not '
            'report a protocol version in its getLatestLedger answer',
          ),
        ),
      ),
    );

    final rpcError = _gateServer({
      'jsonrpc': '2.0',
      'id': 1,
      'error': {'code': -32600, 'message': 'Invalid request'},
    });
    await expectLater(
      () => _protocolAtLeast(rpcError, _gateRpcUrl, 30),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          equals(
            'Exception: The network at https://rpc.invalid/soroban returned a '
            'JSON-RPC error for getLatestLedger: Invalid request',
          ),
        ),
      ),
    );
  });
}
