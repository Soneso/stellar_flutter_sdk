import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'simulation_contract_error_fixtures.dart';

void main() {
  test('reported errors compare by code, provenance and contract ID', () {
    final response = syntheticErrorCases().first.response();
    final value = response.reportedContractError()!;
    final equal = response.reportedContractError()!;
    final host = SimulationErrorCase(
      'host',
      'Error(Contract, #3201)',
      [],
    ).response().reportedContractError()!;
    ReportedContractError eventValue(int code, String? contract) =>
        (SimulateTransactionResponse({})
              ..resultError = maskedContext
              ..events = [errorEvent(code, contract: contract)])
            .reportedContractError()!;
    final noId = eventValue(3201, null);
    final otherId = eventValue(3201, verifierContract);
    final otherCode = eventValue(1, policyContract);
    expect(value, equal);
    expect(value == Object(), isFalse);
    expect(value == otherCode, isFalse);
    expect(noId == host, isFalse);
    expect(value == otherId, isFalse);
    expect(
      value.hashCode,
      Object.hash(value.code, value.provenance, value.contractId),
    );
    expect(value.hashCode, equal.hashCode);
    expect(
      host.hashCode,
      Object.hash(3201, ContractErrorProvenance.hostError, null),
    );
    expect(
      value.toString(),
      'ReportedContractError(code: 3201, provenance: ContractErrorProvenance.diagnosticEvents, contractId: $policyContract)',
    );
    expect(
      host.toString(),
      'ReportedContractError(code: 3201, provenance: ContractErrorProvenance.hostError, contractId: null)',
    );
  });
  for (final c in syntheticErrorCases().where((c) => c.browser)) {
    test('browser ${c.name}', () async {
      final rpc = SimulationRpc([
        {
          'result': {'error': c.header, 'events': c.events},
        },
      ]);
      final tx = await AssembledTransaction.build(options: rpc.options());
      expectReported(tx.simulationResponse!.reportedContractError(), c);
      final e = await caught(() async => tx.getSimulationData());
      expectSorobanFailure(e, c);
      expect(rpc.sends, 0);
    });
  }
  test(
    'getter failure snapshots the response list and selected value',
    () async {
      final c = syntheticErrorCases().first;
      final rpc = SimulationRpc([
        {
          'result': {'error': c.header, 'events': c.events},
        },
      ]);
      final tx = await AssembledTransaction.build(options: rpc.options());
      final response = tx.simulationResponse!;
      final original = response.events!;
      final e =
          await caught(() async => tx.getSimulationData())
              as SorobanSimulationException;
      original[0] = '%';
      response.events = [];
      response.resultError = 'Error(Contract, #1)';
      expect(
        () => e.diagnosticEventsXdr.add('changed'),
        throwsUnsupportedError,
      );
      expectSorobanFailure(e, c);
      expect(rpc.sends, 0);
    },
  );
}
