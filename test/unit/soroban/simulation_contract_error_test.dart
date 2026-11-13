import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'simulation_contract_error_fixtures.dart';

void main() {
  final unsupportedBody = Uint8List.fromList(
    base64Decode(errorEvent(1, contract: null)),
  );
  // Keep the encoded v0 payload behind an unsupported union discriminant.
  ByteData.sublistView(unsupportedBody).setInt32(16, 1);
  final conflictingEvents = {
    'integer topic with typed error data': errorEvent(
      1,
      topics: [XdrSCVal.forSymbol('error'), XdrSCVal.forU32(1)],
      data: contractErrorValue(3201),
    ),
    'non-contract error with typed error data': errorEvent(
      1,
      topics: [
        XdrSCVal.forSymbol('error'),
        XdrSCVal.forError(
          XdrSCError(XdrSCErrorType.SCE_AUTH)
            ..code = XdrSCErrorCode.SCEC_INVALID_ACTION,
        ),
      ],
      data: contractErrorValue(3201),
    ),
    'unsupported body with trailing v0 payload': base64Encode(unsupportedBody),
  };
  for (final entry in conflictingEvents.entries) {
    for (final positive in [false, true]) {
      test('${entry.key} positive=$positive', () async {
        final c = SimulationErrorCase(
          entry.key,
          maskedContext,
          [entry.value, if (positive) errorEvent(3201)],
          code: positive ? 3201 : null,
          provenance: positive
              ? ContractErrorProvenance.diagnosticEvents
              : null,
          contract: positive ? policyContract : null,
        );
        final rpc = SimulationRpc([
          {
            'result': {'error': c.header, 'events': c.events},
          },
        ]);
        final tx = await AssembledTransaction.build(options: rpc.options());
        expectSorobanFailure(
          await caught(() async => tx.getSimulationData()),
          c,
        );
        expect(rpc.sends, 0);
      });
    }
  }
  for (final name in captureNames) {
    for (final suffix in ['', '-rpc30.0.0']) {
      test('captured $name$suffix through build and getter', () async {
        final raw =
            jsonDecode(
                  File(
                    'test/fixtures/simulation_contract_error/$name$suffix-response.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final c = capturedCase(
          '$name$suffix',
          SimulateTransactionResponse.fromJson(raw),
        );
        final rpc = SimulationRpc([raw]);
        final tx = await AssembledTransaction.build(options: rpc.options());
        expectReported(tx.simulationResponse!.reportedContractError(), c);
        expectSorobanFailure(
          await caught(() async => tx.getSimulationData()),
          c,
        );
        expect(rpc.sends, 0);
      });
    }
  }
  for (final c in syntheticErrorCases()) {
    test('${c.name} through buildWithOp and getter', () async {
      final rpc = SimulationRpc([
        {
          'result': {'error': c.header, 'events': c.events},
        },
      ]);
      final tx = await AssembledTransaction.buildWithOp(
        operation: InvokeHostFuncOpBuilder(
          UploadContractWasmHostFunction(Uint8List(1)),
        ).build(),
        options: rpc.options(),
      );
      expectReported(tx.simulationResponse!.reportedContractError(), c);
      expectSorobanFailure(await caught(() async => tx.getSimulationData()), c);
      expect(rpc.sends, 0);
    });
  }
  for (final route in [
    'getter',
    'isReadCall',
    'sign',
    'signAndSend',
    'simulate',
    'resimulate',
    'install',
  ]) {
    test('$route preserves structured failure without submission', () async {
      final c = syntheticErrorCases().first;
      final raw = {
        'result': {'error': c.header, 'events': c.events},
      };
      final rpc = SimulationRpc([raw, raw]);
      if (route == 'install') {
        expectSorobanFailure(
          await caught(
            () => SorobanClient.install(
              installRequest: InstallRequest(
                wasmBytes: Uint8List(1),
                sourceAccountKeyPair: rpc.key,
                network: Network.TESTNET,
                rpcUrl: 'https://rpc.invalid',
                server: rpc.server,
              ),
            ),
          ),
          c,
        );
      } else {
        final tx = await AssembledTransaction.build(
          options: rpc.options(simulate: route != 'simulate'),
        );
        if (route == 'simulate' || route == 'resimulate') await tx.simulate();
        final e = await caught(() async {
          switch (route) {
            case 'isReadCall':
              tx.isReadCall();
              break;
            case 'sign':
              tx.sign();
              break;
            case 'signAndSend':
              await tx.signAndSend();
              break;
            default:
              tx.getSimulationData();
          }
        });
        expectSorobanFailure(e, c);
      }
      expect(rpc.sends, 0);
    });
  }
  test('invoke loads the spec and reports the failed simulation', () async {
    final c = syntheticErrorCases().first;
    final key = KeyPair.random();
    final wasm = File(
      'test/wasm/soroban_hello_world_contract.wasm',
    ).readAsBytesSync();
    var sends = 0;
    final client = dio.Dio()
      ..httpClientAdapter = SimulationDioAdapter((options) {
        final request = jsonDecode(options.data);
        if (request['method'] == 'getLedgerEntries') {
          final type = XdrLedgerKey.fromBase64EncodedXdrString(
            request['params']['keys'][0],
          ).discriminant;
          return ledgerEntryResponse(
            request,
            type == XdrLedgerEntryType.ACCOUNT
                ? accountEntry(key)
                : type == XdrLedgerEntryType.CONTRACT_CODE
                ? contractCodeEntry(Uint8List(32), wasm)
                : contractInstanceEntry(
                    StrKey.decodeContractId(policyContract),
                    Uint8List(32),
                  ),
          );
        }
        if (request['method'] == 'simulateTransaction')
          return jsonRpcResponse(request['id'], {
            'error': c.header,
            'events': c.events,
          });
        if (request['method'] == 'sendTransaction') sends++;
        throw TestFailure('Unexpected RPC method ${request['method']}');
      });
    final server = SorobanServer('https://rpc.invalid', httpClient: client);
    final contract = await SorobanClient.forClientOptions(
      options: ClientOptions(
        sourceAccountKeyPair: key,
        contractId: policyContract,
        network: Network.TESTNET,
        rpcUrl: 'https://rpc.invalid',
        server: server,
      ),
    );
    expectSorobanFailure(
      await caught(
        () => contract.invokeMethod(
          name: 'hello',
          args: [XdrSCVal.forSymbol('world')],
        ),
      ),
      c,
    );
    expect(sends, 0);
  });
  test('JSON RPC keeps the original error object and useful message', () async {
    final rpc = SimulationRpc([
      {
        'error': {
          'code': -32004,
          'message': 'queue full',
          'data': {'retry': true},
        },
      },
    ]);
    final tx = await AssembledTransaction.build(options: rpc.options());
    final e =
        await caught(() async => tx.getSimulationData())
            as SorobanSimulationException;
    expect(e.rpcError, same(tx.simulationResponse!.error));
    expect(e.rpcError!.code, '-32004');
    expect(e.rpcError!.message, 'queue full');
    expect(e.rpcError!.data, {'retry': true});
    expect(e.diagnosticEventsXdr, isEmpty);
    expect(e.reportedContractError, isNull);
    expect(
      e.message,
      'Transaction simulation failed: JSON-RPC error -32004: queue full',
    );
    expect(
      e.toString(),
      'Exception: Transaction simulation failed: JSON-RPC error -32004: queue full',
    );
    expect(rpc.sends, 0);
  });
  test(
    'no simulation and missing transaction data keep their messages',
    () async {
      final rpc = SimulationRpc([
        {
          'result': {
            'events': [errorEvent(1)],
          },
        },
      ]);
      final tx = await AssembledTransaction.build(
        options: rpc.options(simulate: false),
      );
      expect(
        () => tx.getSimulationData(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'text',
            'Exception: Transaction has not yet been simulated',
          ),
        ),
      );
      await tx.simulate();
      expectSorobanFailure(
        await caught(() async => tx.getSimulationData()),
        SimulationErrorCase('missing data', null, []),
      );
      expect(rpc.sends, 0);
    },
  );
  test('transport and parser failures are not simulation exceptions', () async {
    final rpc = SimulationRpc([])
      ..failure = const FormatException('transport parser failure');
    final error = await caught(
      () => AssembledTransaction.build(options: rpc.options()),
    );
    expect(
      error,
      isA<dio.DioException>().having(
        (e) => e.error,
        'cause',
        same(rpc.failure),
      ),
    );
    final malformed = SimulationRpc([
      {
        'result': {'transactionData': '%'},
      },
    ]);
    expect(
      await caught(
        () => AssembledTransaction.build(options: malformed.options()),
      ),
      isA<FormatException>(),
    );
    expect(rpc.sends + malformed.sends, 0);
  });
  test('successful result ignores error-looking events', () async {
    final rpc = SimulationRpc([]);
    final data = transactionDataWithWrites(rpc.key);
    rpc.responses.add({
      'result': {
        'transactionData': data.toBase64EncodedXdrString(),
        'minResourceFee': '100',
        'events': [errorEvent(3201)],
        'results': [
          {'auth': [], 'xdr': XdrSCVal.forU32(7).toBase64EncodedXdrString()},
        ],
      },
    });
    final tx = await AssembledTransaction.build(options: rpc.options());
    expect(tx.simulationResponse!.reportedContractError(), isNull);
    expect(tx.getSimulationData().returnedValue.u32!.uint32, 7);
    expect(rpc.sends, 0);
  });
}
