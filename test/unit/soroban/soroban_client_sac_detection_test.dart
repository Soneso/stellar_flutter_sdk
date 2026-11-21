// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Tests for SorobanClient.forClientOptions() on a Stellar Asset Contract, and
// for SorobanClient.forSpecEntries().
//
// A Stellar Asset Contract has no wasm, so the contract info loader returns
// null. forClientOptions() then reads the instance entry once more and opens
// the client with the embedded SAC spec. Each test asserts the exact sequence
// of requests the mock server received. All RPC calls are served by the mock;
// no network access.
//
// The wasm case reads test/wasm/soroban_hello_world_contract.wasm with dart:io,
// so this file runs on the VM lane only.

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'sac_test_fixtures.dart';

/// The protocol and pre-release versions of the contract info of the loader
/// overrides. The client does not read them.
const int _infoProtocolVersion = 23;
const int _infoPreReleaseVersion = 0;

const String _rpcUrl = 'https://soroban-testnet.stellar.org:443';
const String _sacContractId =
    'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';
const String _wasmContractId =
    'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';

const List<String> _sacFunctionNames = [
  'admin',
  'allowance',
  'approve',
  'authorized',
  'balance',
  'burn',
  'burn_from',
  'clawback',
  'decimals',
  'mint',
  'name',
  'set_admin',
  'set_authorized',
  'symbol',
  'transfer',
  'transfer_from',
  'trust',
];

final Uint8List _wasmHash = Uint8List.fromList(List.generate(32, (i) => i + 1));
final Uint8List _tag = Uint8List.fromList('token-v1'.codeUnits);

/// Answers the requests in order, one answer per request. A further request
/// gets a JSON-RPC error, and the request appears in the log of the double, so
/// the log assertion of the test fails.
RpcAnswer _inOrder(List<RpcAnswer> answers) {
  var next = 0;
  return (request) {
    if (next >= answers.length) {
      return jsonRpcError(request['id'], 'no further answer configured');
    }
    return answers[next++](request);
  };
}

ClientOptions _options(SacRpcDouble rpc, String contractId) => ClientOptions(
  sourceAccountKeyPair: KeyPair.random(),
  contractId: contractId,
  network: Network.TESTNET,
  rpcUrl: _rpcUrl,
  server: rpc.server,
);

/// A double that answers the instance reads of [contractId] with
/// [instanceAnswers], one answer per read in order.
SacRpcDouble _instanceDouble(
  String contractId,
  List<RpcAnswer> instanceAnswers,
) {
  return SacRpcDouble(
    rpcUrl: _rpcUrl,
    expectedKeys: {'instance': instanceLedgerKey(contractId)},
    answers: {'instance': _inOrder(instanceAnswers)},
  );
}

void main() {
  group('SorobanClient.forClientOptions on a Stellar Asset Contract', () {
    test('reads the instance twice and opens the embedded spec', () async {
      final rpc = _instanceDouble(_sacContractId, [
        ledgerEntry(null),
        ledgerEntry(sacInstanceEntry(_sacContractId)),
      ]);
      addTearDown(rpc.expectNoViolations);
      final client = await SorobanClient.forClientOptions(
        options: _options(rpc, _sacContractId),
      );

      // The loader finds no code for the SAC, so the detection reads the
      // instance once more; the client is returned without a further request.
      expect(rpc.log, ['instance', 'instance']);
      expect(client.getMethodNames(), unorderedEquals(_sacFunctionNames));
      expect(client.getMethodNames(), hasLength(17));
    });
  });

  group('SorobanClient.forClientOptions on a wasm contract', () {
    test('reads the instance, the code, and opens the wasm spec', () async {
      final helloWasm = File(
        'test/wasm/soroban_hello_world_contract.wasm',
      ).readAsBytesSync();
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        expectedKeys: {
          'instance': instanceLedgerKey(_wasmContractId),
          'code': codeLedgerKey(_wasmHash),
        },
        answers: {
          'instance': ledgerEntry(
            wasmInstanceEntry(_wasmContractId, _wasmHash),
          ),
          'code': ledgerEntry(contractCodeEntry(_wasmHash, helloWasm)),
        },
      );
      addTearDown(rpc.expectNoViolations);
      final client = await SorobanClient.forClientOptions(
        options: _options(rpc, _wasmContractId),
      );

      expect(rpc.log, ['instance', 'code']);
      expect(client.getMethodNames(), ['hello']);
    });

    test('an external reference reads the tag, then the code', () async {
      final helloWasm = File(
        'test/wasm/soroban_hello_world_contract.wasm',
      ).readAsBytesSync();
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        expectedKeys: {
          'instance': instanceLedgerKey(_wasmContractId),
          'tag': tagLedgerKey(_sacContractId, _tag),
          'code': codeLedgerKey(_wasmHash),
        },
        answers: {
          'instance': ledgerEntry(
            externalRefInstanceEntry(_wasmContractId, _sacContractId, _tag),
          ),
          'tag': ledgerEntry(
            executableTagEntry(_sacContractId, _tag, _wasmHash),
          ),
          'code': ledgerEntry(contractCodeEntry(_wasmHash, helloWasm)),
        },
      );
      addTearDown(rpc.expectNoViolations);
      final client = await SorobanClient.forClientOptions(
        options: _options(rpc, _wasmContractId),
      );

      expect(rpc.log, ['instance', 'tag', 'code']);
      expect(client.getMethodNames(), ['hello']);
    });

    test(
      'a missing instance gives the missing-contract message after two reads',
      () async {
        final rpc = _instanceDouble(_wasmContractId, [
          ledgerEntry(null),
          ledgerEntry(null),
        ]);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          SorobanClient.forClientOptions(
            options: _options(rpc, _wasmContractId),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Could not load contract info for the contract: '
                  'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
          ),
        );
        expect(rpc.log, ['instance', 'instance']);
      },
    );

    test(
      'a missing code gives the missing-contract message after three reads',
      () async {
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          expectedKeys: {
            'instance': instanceLedgerKey(_wasmContractId),
            'code': codeLedgerKey(_wasmHash),
          },
          answers: {
            'instance': ledgerEntry(
              wasmInstanceEntry(_wasmContractId, _wasmHash),
            ),
            'code': ledgerEntry(null),
          },
        );
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          SorobanClient.forClientOptions(
            options: _options(rpc, _wasmContractId),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Could not load contract info for the contract: '
                  'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
          ),
        );
        expect(rpc.log, ['instance', 'code', 'instance']);
      },
    );

    test(
      'an unresolved external reference gives the missing-contract message',
      () async {
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          expectedKeys: {
            'instance': instanceLedgerKey(_wasmContractId),
            'tag': tagLedgerKey(_sacContractId, _tag),
          },
          answers: {
            'instance': _inOrder([
              ledgerEntry(
                externalRefInstanceEntry(_wasmContractId, _sacContractId, _tag),
              ),
              ledgerEntry(
                externalRefInstanceEntry(_wasmContractId, _sacContractId, _tag),
              ),
            ]),
            'tag': ledgerEntry(null),
          },
        );
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          SorobanClient.forClientOptions(
            options: _options(rpc, _wasmContractId),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Could not load contract info for the contract: '
                  'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
          ),
        );
        expect(rpc.log, ['instance', 'tag', 'instance']);
      },
    );

    test('code that is not wasm throws the parser failure', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        expectedKeys: {
          'instance': instanceLedgerKey(_wasmContractId),
          'code': codeLedgerKey(_wasmHash),
        },
        answers: {
          'instance': ledgerEntry(
            wasmInstanceEntry(_wasmContractId, _wasmHash),
          ),
          'code': ledgerEntry(
            contractCodeEntry(
              _wasmHash,
              Uint8List.fromList('not wasm'.codeUnits),
            ),
          ),
        },
      );
      addTearDown(rpc.expectNoViolations);
      await expectLater(
        SorobanClient.forClientOptions(options: _options(rpc, _wasmContractId)),
        throwsA(
          isA<SorobanContractParserFailed>().having(
            (e) => e.toString(),
            'toString',
            'invalid byte code: the wasm magic at byte offset 0 is 6e6f7420, '
                'expected 0061736d.',
          ),
        ),
      );
      expect(rpc.log, ['instance', 'code']);
    });
  });

  group('SorobanClient.forClientOptions detection read failures', () {
    test(
      'an account entry at the instance key gives the missing-contract message',
      () async {
        final rpc = _instanceDouble(_wasmContractId, [
          ledgerEntry(null),
          ledgerEntry(accountEntry(KeyPair.random())),
        ]);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          SorobanClient.forClientOptions(
            options: _options(rpc, _wasmContractId),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Could not load contract info for the contract: '
                  'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
          ),
        );
        expect(rpc.log, ['instance', 'instance']);
      },
    );

    test(
      'contract data without an instance gives the missing-contract message',
      () async {
        final rpc = _instanceDouble(_wasmContractId, [
          ledgerEntry(null),
          ledgerEntry(
            contractDataEntry(
              _wasmContractId,
              XdrSCVal.forLedgerKeyContractInstance(),
              XdrSCVal.forU32(1),
            ),
          ),
        ]);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          SorobanClient.forClientOptions(
            options: _options(rpc, _wasmContractId),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Could not load contract info for the contract: '
                  'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
          ),
        );
        expect(rpc.log, ['instance', 'instance']);
      },
    );

    test(
      'a JSON-RPC error on the detection read gives the missing-contract message',
      () async {
        final rpc = _instanceDouble(_wasmContractId, [
          ledgerEntry(null),
          rpcError('server unavailable'),
        ]);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          SorobanClient.forClientOptions(
            options: _options(rpc, _wasmContractId),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Could not load contract info for the contract: '
                  'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
          ),
        );
        expect(rpc.log, ['instance', 'instance']);
      },
    );
  });

  group('SorobanClient.forClientOptions loader request failures', () {
    test('a transport failure on the instance read propagates', () async {
      final rpc = _instanceDouble(_wasmContractId, [
        (request) => throw Exception('connection refused'),
      ]);
      addTearDown(rpc.expectNoViolations);
      await expectLater(
        SorobanClient.forClientOptions(options: _options(rpc, _wasmContractId)),
        throwsA(isA<dio.DioException>()),
      );
      expect(rpc.log, ['instance']);
    });

    test(
      'a JSON-RPC error on the loader read leaves no entry, so the detection read follows',
      () async {
        final rpc = _instanceDouble(_wasmContractId, [
          rpcError('server unavailable'),
          ledgerEntry(null),
        ]);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          SorobanClient.forClientOptions(
            options: _options(rpc, _wasmContractId),
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Could not load contract info for the contract: '
                  'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
            ),
          ),
        );
        expect(rpc.log, ['instance', 'instance']);
      },
    );
  });

  group('SorobanClient.forClientOptions with a loader override', () {
    test('an info opens the client with no HTTP request', () async {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      final server = _InfoServer(
        _rpcUrl,
        rpc.httpClient,
        SorobanContractInfo(
          _infoProtocolVersion,
          _infoPreReleaseVersion,
          SACClient.specEntries(),
          {},
        ),
      );
      final client = await SorobanClient.forClientOptions(
        options: ClientOptions(
          sourceAccountKeyPair: KeyPair.random(),
          contractId: _sacContractId,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: server,
        ),
      );

      expect(rpc.log, isEmpty);
      expect(client.getMethodNames(), unorderedEquals(_sacFunctionNames));
    });

    test(
      'an info with empty spec entries opens a client with no methods',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        final server = _InfoServer(
          _rpcUrl,
          rpc.httpClient,
          SorobanContractInfo(
            _infoProtocolVersion,
            _infoPreReleaseVersion,
            [],
            {},
          ),
        );
        final client = await SorobanClient.forClientOptions(
          options: ClientOptions(
            sourceAccountKeyPair: KeyPair.random(),
            contractId: _wasmContractId,
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: server,
          ),
        );

        expect(rpc.log, isEmpty);
        expect(client.getMethodNames(), isEmpty);
      },
    );
  });

  group('SorobanClient.forClientOptions with a null loader', () {
    test(
      'the second instance read goes through the overriding server',
      () async {
        final rpc = _instanceDouble(_sacContractId, [
          ledgerEntry(sacInstanceEntry(_sacContractId)),
          ledgerEntry(sacInstanceEntry(_sacContractId)),
        ]);
        addTearDown(rpc.expectNoViolations);
        final server = _CountingNullLoaderServer(_rpcUrl, rpc.httpClient);
        final client = await SorobanClient.forClientOptions(
          options: ClientOptions(
            sourceAccountKeyPair: KeyPair.random(),
            contractId: _sacContractId,
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: server,
          ),
        );

        // The detection read is the only getContractData call of the open, and
        // it reads the instance key of the contract.
        expect(server.contractDataCalls, [_sacContractId]);
        expect(server.instanceKeyReads, 1);
        expect(rpc.log, ['instance', 'instance']);
        expect(client.getMethodNames(), unorderedEquals(_sacFunctionNames));
      },
    );

    test('an absent instance gives the missing-contract message', () async {
      final rpc = _instanceDouble(_wasmContractId, [
        ledgerEntry(null),
        ledgerEntry(null),
      ]);
      addTearDown(rpc.expectNoViolations);
      await expectLater(
        SorobanClient.forClientOptions(
          options: ClientOptions(
            sourceAccountKeyPair: KeyPair.random(),
            contractId: _wasmContractId,
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: _NullLoaderServer(_rpcUrl, rpc.httpClient),
          ),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            'Exception: Could not load contract info for the contract: '
                'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
          ),
        ),
      );
      expect(rpc.log, ['instance', 'instance']);
    });
  });

  group('SorobanClient.forSpecEntries', () {
    test('sends no request and keeps the given entries and options', () {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      final entries = SACClient.specEntries();
      final options = _options(rpc, _sacContractId);
      final client = SorobanClient.forSpecEntries(
        specEntries: entries,
        options: options,
      );

      expect(rpc.log, isEmpty);
      expect(identical(client.getSpecEntries(), entries), isTrue);
      expect(identical(client.getOptions(), options), isTrue);
      expect(client.getMethodNames(), unorderedEquals(_sacFunctionNames));
    });

    test('defaults readOnly to false, so a build reads the account', () async {
      final keyPair = KeyPair.random();
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        expectedKeys: {'account': accountLedgerKey(keyPair)},
        answers: {'account': ledgerEntry(accountEntry(keyPair))},
      );
      addTearDown(rpc.expectNoViolations);
      final client = SorobanClient.forSpecEntries(
        specEntries: SACClient.specEntries(),
        options: ClientOptions(
          sourceAccountKeyPair: keyPair,
          contractId: _sacContractId,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
      );

      await client.buildInvokeMethodTx(
        name: 'decimals',
        args: [],
        methodOptions: MethodOptions(simulate: false),
      );
      expect(rpc.log, ['account']);
    });

    test('readOnly true builds without reading the account', () async {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      final client = SorobanClient.forSpecEntries(
        specEntries: SACClient.specEntries(),
        options: ClientOptions(
          sourceAccountKeyPair: KeyPair.fromAccountId(
            SACClient.READ_ONLY_SOURCE_ACCOUNT_ID,
          ),
          contractId: _sacContractId,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
        readOnly: true,
      );

      await client.buildInvokeMethodTx(
        name: 'decimals',
        args: [],
        methodOptions: MethodOptions(simulate: false),
      );
      expect(rpc.log, isEmpty);
    });

    test('rejects a G account address before any request', () {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      final account = KeyPair.random().accountId;
      expect(
        () => SorobanClient.forSpecEntries(
          specEntries: SACClient.specEntries(),
          options: ClientOptions(
            sourceAccountKeyPair: KeyPair.random(),
            contractId: account,
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: rpc.server,
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'The contract to invoke must be a contract (C...) address, got an '
                'account (G...) address: $account',
          ),
        ),
      );
      expect(rpc.log, isEmpty);
    });

    test('rejects a muxed contract (W...) id before any request', () {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      expect(
        () => SorobanClient.forSpecEntries(
          specEntries: SACClient.specEntries(),
          options: ClientOptions(
            sourceAccountKeyPair: KeyPair.random(),
            contractId:
                'WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG',
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: rpc.server,
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'The contract to invoke must be a contract (C...) address, got a '
                'muxed contract (W...) address: '
                'WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; '
                'use its base contract (C...) address',
          ),
        ),
      );
      expect(rpc.log, isEmpty);
    });
  });
}

/// A null-loader server that records each getContractData call: the contract
/// id, and whether the key is the contract instance key.
class _CountingNullLoaderServer extends _NullLoaderServer {
  _CountingNullLoaderServer(super.rpcUrl, super.httpClient);

  final List<String> contractDataCalls = [];
  int instanceKeyReads = 0;

  @override
  Future<LedgerEntry?> getContractData(
    String contractId,
    XdrSCVal key,
    XdrContractDataDurability durability,
  ) {
    contractDataCalls.add(contractId);
    if (key.toBase64EncodedXdrString() ==
        XdrSCVal.forLedgerKeyContractInstance().toBase64EncodedXdrString()) {
      instanceKeyReads++;
    }
    return super.getContractData(contractId, key, durability);
  }
}

/// A server whose loader returns no info. It reads the instance once through
/// its own request path, as the loader does, and then returns null.
class _NullLoaderServer extends SorobanServer {
  _NullLoaderServer(String rpcUrl, dio.Dio httpClient)
    : super(rpcUrl, httpClient: httpClient);

  @override
  Future<SorobanContractInfo?> loadContractInfoForContractId(
    String contractId,
  ) async {
    await super.loadContractInfoForContractId(contractId);
    return null;
  }
}

/// A server whose loader returns [info] without any request.
class _InfoServer extends SorobanServer {
  _InfoServer(String rpcUrl, dio.Dio httpClient, this._info)
    : super(rpcUrl, httpClient: httpClient);

  final SorobanContractInfo? _info;

  @override
  Future<SorobanContractInfo?> loadContractInfoForContractId(
    String contractId,
  ) async {
    return _info;
  }
}
