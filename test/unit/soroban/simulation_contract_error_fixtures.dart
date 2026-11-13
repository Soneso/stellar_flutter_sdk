import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const policyContract =
    'CAZJ3UVRY3R3S5C5BH32GMYBRSN23N75ZEEXEOLXOUUAHDFIMVP4AXUC';
const verifierContract =
    'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY';
const accountContract =
    'CABAV4UNU66OZ75MXQDX3FFO35WNQLLXG2HZAHKJNZ27C2LGAX4DK253';
const maskedContext = 'HostError: Error(Context, InvalidAction)';
const maskedAuth = 'HostError: Error(Auth, InvalidAction)';
const captureNames = [
  'case-a',
  'case-b1-registered-badsig',
  'case-b2-unregistered',
  'case-b3-registered-rightchallenge-badsig',
  'case-c1-policy-get-threshold',
  'case-c2-sac-negative-transfer',
];
const namedErrors = {
  3201: OZContractError(3201, 'SimpleThresholdError', 'InvalidThreshold'),
  3200: OZContractError(
    3200,
    'SimpleThresholdError',
    'SmartAccountNotInstalled',
  ),
  3114: OZContractError(3114, 'WebAuthnError', 'ChallengeInvalid'),
  3016: OZContractError(3016, 'SmartAccountError', 'UnauthorizedSigner'),
};

XdrSCVal contractErrorValue(int code) => XdrSCVal.forError(
  XdrSCError(XdrSCErrorType.SCE_CONTRACT)..contractCode = XdrUint32(code),
);

// Synthetic events isolate selection predicates, including caught errors.
String errorEvent(
  int code, {
  String? contract = policyContract,
  bool successful = false,
  XdrContractEventType type = XdrContractEventType.DIAGNOSTIC,
  List<XdrSCVal>? topics,
  XdrSCVal? data,
  int bodyVersion = 0,
}) => XdrDiagnosticEvent(
  successful,
  XdrContractEvent(
    XdrExtensionPoint(0),
    contract == null ? null : XdrHash(StrKey.decodeContractId(contract)),
    type,
    XdrContractEventBody(bodyVersion)
      ..v0 = XdrContractEventV0(
        topics ?? [XdrSCVal.forSymbol('error'), contractErrorValue(code)],
        data ?? XdrSCVal.forVoid(),
      ),
  ),
).toBase64EncodedXdrString();

class SimulationErrorCase {
  final String name;
  final bool browser;
  final bool decoder;
  final bool messageMarker;
  final String? header;
  final List<String>? events;
  final int? code;
  final ContractErrorProvenance? provenance;
  final String? contract;
  SimulationErrorCase(
    this.name,
    this.header,
    this.events, {
    this.browser = false,
    this.decoder = false,
    this.messageMarker = false,
    this.code,
    this.provenance,
    this.contract,
  });
  SimulateTransactionResponse response() => SimulateTransactionResponse({})
    ..resultError = header
    ..events = events == null ? null : List<String>.of(events!);
  String message(String prefix) {
    final text = '$prefix$header';
    if (provenance != ContractErrorProvenance.diagnosticEvents) return text;
    return '$text (contract error in diagnostic events: Error(Contract, #$code)'
        '${contract == null ? '' : ', contract $contract'})';
  }
}

SimulationErrorCase capturedCase(String name, SimulateTransactionResponse r) {
  final index = captureNames.indexWhere(
    (base) => name == base || name == '$base-rpc30.0.0',
  );
  final code = <int?>[3201, 3114, 3016, null, 3200, 8][index];
  return SimulationErrorCase(
    name,
    r.resultError,
    r.events?.toList(),
    code: code,
    provenance: code == null
        ? null
        : index < 3
        ? ContractErrorProvenance.diagnosticEvents
        : ContractErrorProvenance.hostError,
    contract: <String?>[
      policyContract,
      verifierContract,
      accountContract,
      null,
      null,
      null,
    ][index],
  );
}

List<SimulationErrorCase> syntheticErrorCases() {
  final good = errorEvent(3201);
  SimulationErrorCase eventCase(
    String name,
    List<String>? events, {
    bool browser = false,
    bool decoder = false,
    bool messageMarker = false,
    int? code = 3201,
    String? contract = policyContract,
    String header = maskedContext,
  }) => SimulationErrorCase(
    name,
    header,
    events,
    browser: browser,
    decoder: decoder,
    messageMarker: messageMarker,
    code: code,
    provenance: code == null ? null : ContractErrorProvenance.diagnosticEvents,
    contract: code == null ? null : contract,
  );
  final wrongEvents = <String, String>{
    'invalid base64': '%',
    'truncated XDR': 'AAAAAA==',
    'non diagnostic': errorEvent(1, type: XdrContractEventType.CONTRACT),
    'unsupported body': errorEvent(1, bodyVersion: 1),
    'one topic': errorEvent(1, topics: [XdrSCVal.forSymbol('error')]),
    'three topics': errorEvent(
      1,
      topics: [
        XdrSCVal.forSymbol('error'),
        contractErrorValue(1),
        XdrSCVal.forVoid(),
      ],
    ),
    'string topic': errorEvent(
      1,
      topics: [XdrSCVal.forString('error'), contractErrorValue(1)],
    ),
    'other symbol': errorEvent(
      1,
      topics: [XdrSCVal.forSymbol('other'), contractErrorValue(1)],
    ),
    'integer topic': errorEvent(
      1,
      topics: [XdrSCVal.forSymbol('error'), XdrSCVal.forU32(1)],
    ),
    'non contract error': errorEvent(
      1,
      topics: [
        XdrSCVal.forSymbol('error'),
        XdrSCVal.forError(
          XdrSCError(XdrSCErrorType.SCE_AUTH)
            ..code = XdrSCErrorCode.SCEC_INVALID_ACTION,
        ),
      ],
    ),
    'code only in data': errorEvent(
      1,
      topics: [XdrSCVal.forSymbol('other'), XdrSCVal.forVoid()],
      data: contractErrorValue(1),
    ),
  };
  return [
    eventCase('masked Context selects the earliest event', [
      good,
    ], decoder: true),
    eventCase('masked Auth', [good], header: maskedAuth),
    eventCase(
      'optional host prefix',
      [good],
      header: 'Error( Context , InvalidAction )',
      decoder: true,
    ),
    eventCase(
      'text log is ignored',
      [],
      code: null,
      header: '$maskedContext\nError(Contract, #3016)',
    ),
    for (final header in [
      null,
      '',
      'arbitrary Error(Context, InvalidAction)',
      'Error(Crypto, InvalidInput)',
      'Error(Context, InvalidAction) trailing',
    ])
      SimulationErrorCase('rejects header $header', header, [good]),
    eventCase('absent events', null, code: null),
    eventCase('empty events', [], code: null),
    for (final wrong in wrongEvents.entries) ...[
      eventCase('${wrong.key}', [wrong.value], code: null),
      eventCase('${wrong.key} with positive control', [wrong.value, good]),
    ],
    eventCase('malformed entries before and between valid events', [
      '%',
      'AAAAAA==',
      good,
      '%',
      errorEvent(3016),
    ], browser: true),
    eventCase('successful call is skipped', [
      errorEvent(3016, successful: true),
      good,
    ]),
    eventCase('caught rolled back error wins', [good, errorEvent(3016)]),
    eventCase('missing contract ID', [
      errorEvent(3201, contract: null),
    ], contract: null),
    eventCase(
      'unknown wins over message and known event',
      [errorEvent(1), good],
      code: 1,
      header: '$maskedContext\nError(Contract, #3016)',
      decoder: true,
      messageMarker: true,
    ),
    eventCase(
      'marker only',
      [],
      code: null,
      header: '$maskedContext\nError(Contract, #3016)',
      decoder: true,
      messageMarker: true,
    ),
    for (final code in [0, 4294967295]) ...[
      eventCase(
        'event $code',
        [errorEvent(code)],
        code: code,
        browser: true,
        decoder: true,
      ),
      for (final header in {
        'plain contract header': 'Error(Contract, #$code)',
        'header with tabs and CR boundary':
            ' \tHostError: Error( Contract , #$code ) \t\rignored',
        'header with LF boundary':
            'Error( Contract , #$code )\nError(Contract, #1)',
      }.entries)
        SimulationErrorCase(
          '${header.key} code $code',
          header.value,
          [good],
          code: code,
          browser: true,
          decoder: true,
          provenance: ContractErrorProvenance.hostError,
        ),
    ],
    for (final value in [
      '#-1',
      '#4294967296',
      '#999999999999999999999999999999',
      'bad',
      '#1) trailing',
    ])
      SimulationErrorCase(
        'invalid header $value',
        'Error(Contract, $value)',
        [good],
        browser: true,
        decoder: true,
      ),
    eventCase(
      'foreign contract and duplicates',
      [errorEvent(1, contract: verifierContract), good, good],
      code: 1,
      contract: verifierContract,
      decoder: true,
    ),
    eventCase('reversed contracts', [
      good,
      good,
      errorEvent(1, contract: verifierContract),
    ], decoder: true),
  ];
}

void expectReported(ReportedContractError? actual, SimulationErrorCase c) {
  expect(actual?.code, c.code);
  expect(actual?.provenance, c.provenance);
  expect(actual?.contractId, c.contract);
  if (c.code == null) expect(actual, isNull);
}

void expectSmartFailure(Object error, SimulationErrorCase c, String prefix) {
  expect(error, isA<SmartAccountTransactionSimulationFailed>());
  final e = error as SmartAccountTransactionSimulationFailed;
  expect(e.code, SmartAccountErrorCode.transactionSimulationFailed);
  expect(e.diagnosticEventsXdr, c.events ?? <String>[]);
  expectReported(e.reportedContractError, c);
  expect(
    OZContractErrorCodes.decodeFromSimulationException(e),
    namedErrors[c.code],
  );
  expect(e.message, c.message(prefix));
  expect(e.toString(), 'SmartAccountException [5001]: ${c.message(prefix)}');
}

void expectSorobanFailure(Object error, SimulationErrorCase c) {
  expect(error, isA<SorobanSimulationException>());
  final e = error as SorobanSimulationException;
  expect(
    e.diagnosticEventsXdr,
    c.header == null ? <String>[] : c.events ?? <String>[],
  );
  expectReported(e.reportedContractError, c);
  expect(e.message, c.message('Transaction simulation failed: '));
  expect(
    e.toString(),
    'Exception: ${c.message('Transaction simulation failed: ')}',
  );
}

Future<Object> caught(Future<dynamic> Function() action) async {
  try {
    await action();
  } catch (e) {
    return e;
  }
  throw TestFailure('Expected a simulation failure');
}

class SimulationRpc implements dio.HttpClientAdapter {
  final key = KeyPair.random();
  final List<Map<String, dynamic>> responses;
  int sends = 0;
  Object? failure;
  late final SorobanServer server;
  SimulationRpc(this.responses) {
    final client = dio.Dio()..httpClientAdapter = this;
    server = SorobanServer('https://rpc.invalid', httpClient: client);
  }
  ClientOptions get clientOptions => ClientOptions(
    sourceAccountKeyPair: key,
    contractId: policyContract,
    network: Network.TESTNET,
    rpcUrl: 'https://rpc.invalid',
    server: server,
  );
  AssembledTransactionOptions options({bool simulate = true}) =>
      AssembledTransactionOptions(
        clientOptions: clientOptions,
        methodOptions: MethodOptions(simulate: simulate),
        method: 'hello',
      );
  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = jsonDecode(options.data);
    Map<String, dynamic> body;
    switch (request['method']) {
      case 'getLedgerEntries':
        final entry = accountEntry(key)
          ..account!.seqNum = XdrSequenceNumber(BigInt.one);
        body = {
          'result': {
            'entries': [
              {
                'key': request['params']['keys'][0],
                'xdr': entry.toBase64EncodedXdrString(),
                'lastModifiedLedgerSeq': 1,
              },
            ],
            'latestLedger': 1,
          },
        };
        break;
      case 'simulateTransaction':
        if (failure != null) throw failure!;
        expect(responses, isNotEmpty);
        body = responses.removeAt(0);
        break;
      case 'sendTransaction':
        sends++;
        throw TestFailure('Unexpected submission');
      default:
        throw TestFailure('Unexpected RPC method: ${request['method']}');
    }
    return dio.ResponseBody.fromString(
      jsonEncode({'jsonrpc': '2.0', 'id': request['id'], ...body}),
      200,
      headers: {
        'content-type': [dio.Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class SimulationDioAdapter implements dio.HttpClientAdapter {
  final Function(dio.RequestOptions) onRequest;

  SimulationDioAdapter(this.onRequest);

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => onRequest(options);

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody jsonRpcResponse(dynamic id, Map<String, dynamic> result) {
  return dio.ResponseBody.fromString(
    jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
    200,
    headers: {
      'content-type': [dio.Headers.jsonContentType],
    },
  );
}

dio.ResponseBody ledgerEntryResponse(
  Map<String, dynamic> requestBody,
  XdrLedgerEntryData entryData,
) {
  return jsonRpcResponse(requestBody['id'], {
    'entries': [
      {
        'key': (requestBody['params']['keys'] as List)[0],
        'xdr': entryData.toBase64EncodedXdrString(),
        'lastModifiedLedgerSeq': 99999,
      },
    ],
    'latestLedger': 100000,
  });
}

XdrLedgerEntryData accountEntry(KeyPair keyPair) {
  final account = XdrAccountEntry(
    XdrAccountID(keyPair.xdrPublicKey),
    XdrInt64(BigInt.zero),
    XdrSequenceNumber(BigInt.from(1000)),
    XdrUint32(0),
    null,
    XdrUint32(0),
    XdrString32(''),
    XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
    [],
    XdrAccountEntryExt(0),
  );
  return XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT)..account = account;
}

XdrLedgerEntryData contractCodeEntry(Uint8List wasmHashBytes, Uint8List code) {
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_CODE);
  entryData.contractCode = XdrContractCodeEntry(
    XdrContractCodeEntryExt(0),
    XdrHash(wasmHashBytes),
    code,
  );
  return entryData;
}

XdrLedgerEntryData contractInstanceEntry(
  Uint8List contractIdBytes,
  Uint8List wasmHashBytes,
) {
  final executable = XdrContractExecutable(
    XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM,
  );
  executable.wasmHash = XdrHash(wasmHashBytes);
  final instance = XdrSCContractInstance(executable, null);
  final contractAddress = XdrSCAddress(
    XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
  );
  contractAddress.contractId = XdrHash(contractIdBytes);
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
  entryData.contractData = XdrContractDataEntry(
    XdrExtensionPoint(0),
    contractAddress,
    XdrSCVal.forLedgerKeyContractInstance(),
    XdrContractDataDurability.PERSISTENT,
    XdrSCVal.forContractInstance(instance),
  );
  return entryData;
}

/// Transaction data with a non-empty read-write footprint, so that the
/// deploy transaction is not considered a read call.
XdrSorobanTransactionData transactionDataWithWrites(KeyPair keyPair) {
  final key = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
  key.account = XdrLedgerKeyAccount(XdrAccountID(keyPair.xdrPublicKey));
  final resources = XdrSorobanResources(
    XdrLedgerFootprint([], [key]),
    XdrUint32(0),
    XdrUint32(0),
    XdrUint32(0),
  );
  return XdrSorobanTransactionData(
    XdrSorobanTransactionDataExt(0),
    resources,
    XdrInt64(BigInt.zero),
  );
}
