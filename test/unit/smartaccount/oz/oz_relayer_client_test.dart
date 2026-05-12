// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_dio_adapter.dart';

const String _testSourceAccountId =
    'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54';
const String _testContractId =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

XdrHostFunction _testHostFunction() {
  final addr = XdrSCAddress.forContractId(_testContractId);
  final args = XdrInvokeContractArgs(addr, 'hello', <XdrSCVal>[
    XdrSCVal.forSymbol('world'),
  ]);
  return XdrHostFunction.forInvokingContractWithArgs(args);
}

XdrSorobanAuthorizationEntry _testAuthEntry() {
  final addr = XdrSCAddress.forContractId(_testContractId);
  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(addr, 'hello', <XdrSCVal>[]);
  final invocation = XdrSorobanAuthorizedInvocation(
    fn,
    <XdrSorobanAuthorizedInvocation>[],
  );
  final wrapper = XdrSorobanCredentials.forSourceAccount();
  return XdrSorobanAuthorizationEntry(wrapper, invocation);
}

XdrTransactionEnvelope _testTransactionEnvelope() {
  final source = Account(_testSourceAccountId, BigInt.from(0));
  final tx = TransactionBuilder(source)
      .addOperation(BumpSequenceOperation(BigInt.from(1)))
      .build();
  return tx.toEnvelopeXdr();
}

OZRelayerClient _client(
  MockDioAdapter adapter, {
  String url = 'https://relayer.example.com',
}) {
  final mockDio = dio.Dio();
  mockDio.httpClientAdapter = adapter;
  return OZRelayerClient.withDio(url, mockDio);
}

void main() {
  group('OZRelayerClient - constructor validation', () {
    test('testConstructor_blankUrl_throwsConfigurationException', () {
      expect(() => OZRelayerClient(''), throwsA(isA<InvalidConfig>()));
    });

    test('testConstructor_whitespaceUrl_throwsConfigurationException', () {
      expect(() => OZRelayerClient('   '), throwsA(isA<InvalidConfig>()));
    });

    test('testConstructor_httpUrl_throwsConfigurationException', () {
      expect(
        () => OZRelayerClient('http://relayer.example.com'),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testConstructor_httpsUrlSucceeds', () async {
      final client = OZRelayerClient('https://relayer.example.com');
      await client.close();
    });

    test('testConstructor_localhostHttpUrlSucceeds', () async {
      final client = OZRelayerClient('http://localhost:3000');
      await client.close();
    });

    test('testConstructor_localhostWithoutPortSucceeds', () async {
      final client = OZRelayerClient('http://localhost');
      await client.close();
    });

    test('testConstructor_trailingSlashNormalization', () async {
      final client = OZRelayerClient('https://relayer.example.com///');
      await client.close();
    });

    test('testConstructor_ftpSchemeThrows', () {
      expect(
        () => OZRelayerClient('ftp://relayer.example.com'),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testConstructor_noSchemeThrows', () {
      expect(
        () => OZRelayerClient('relayer.example.com'),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testConstructor_customTimeoutIsAccepted', () async {
      final client = OZRelayerClient(
        'https://relayer.example.com',
        timeout: const Duration(milliseconds: 10000),
      );
      await client.close();
    });

    test('testConstructor_leadingWhitespaceUrl_succeedsAfterTrim', () async {
      final client = OZRelayerClient('  https://relayer.example.com');
      await client.close();
    });

    test('testConstructor_trailingNewlineUrl_succeedsAfterTrim', () async {
      final client = OZRelayerClient('https://relayer.example.com\n');
      await client.close();
    });

    test('testConstructor_schemeOnlyUrl_throwsConfigurationException', () {
      expect(
        () => OZRelayerClient('https://'),
        throwsA(isA<InvalidConfig>()),
      );
    });
  });

  group('OZRelayerClient - send', () {
    test('testSend_success_returnsHash', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "abc123", '
        '"transactionId": "tx-001", "status": "PENDING"}}',
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isTrue);
        expect(response.hash, 'abc123');
        expect(response.transactionId, 'tx-001');
        expect(response.status, 'PENDING');
      } finally {
        await relayer.close();
      }
    });

    test('testSend_buildsCorrectJsonPayload', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "abc123"}}',
      );
      final relayer = _client(adapter);
      try {
        final hostFunction = _testHostFunction();
        final authEntry = _testAuthEntry();
        final response = await relayer.send(
          hostFunction,
          <XdrSorobanAuthorizationEntry>[authEntry],
        );
        expect(response.success, isTrue);
        expect(response.hash, 'abc123');

        expect(adapter.capturedBody, isNotNull);
        final body = json.decode(adapter.capturedBody!) as Map<String, dynamic>;

        expect(body.containsKey('func'), isTrue);
        final funcValue = body['func'] as String;
        expect(funcValue.isNotEmpty, isTrue);

        expect(body.containsKey('auth'), isTrue);
        final authArray = body['auth'] as List<dynamic>;
        expect(authArray.length, 1);
        final authEntryBase64 = authArray[0] as String;
        expect(authEntryBase64.isNotEmpty, isTrue);

        final decodedFn =
            XdrHostFunctionBase.fromBase64EncodedXdrString(funcValue);
        expect(decodedFn.discriminant.value, hostFunction.discriminant.value,
            reason:
                'Round-tripped host function must preserve discriminant');

        final decodedAuth =
            XdrSorobanAuthorizationEntry.fromBase64EncodedXdrString(
                authEntryBase64);
        expect(
          decodedAuth.credentials.discriminant.value,
          authEntry.credentials.discriminant.value,
          reason:
              'Round-tripped auth entry must preserve credentials discriminant',
        );
        expect(
          decodedAuth.rootInvocation.function.discriminant.value,
          authEntry.rootInvocation.function.discriminant.value,
          reason: 'Round-tripped auth entry must preserve invocation '
              'function discriminant',
        );
      } finally {
        await relayer.close();
      }
    });

    test('testSend_errorResponse_returnsErrorWithCode', () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "error": "simulation failed", "code": "SIMULATION_FAILED"}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, 'simulation failed');
        expect(response.errorCode, 'SIMULATION_FAILED');
      } finally {
        await relayer.close();
      }
    });

    test('testSend_errorWithNestedDataCode_returnsCorrectErrorCode', () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "error": "tx failed", "data": {"code": "ONCHAIN_FAILED", "details": "..."}}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, 'tx failed');
        expect(response.errorCode, 'ONCHAIN_FAILED');
      } finally {
        await relayer.close();
      }
    });

    test('testSend_nonJsonResponse_returnsContentTypeError', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '<html>Bad Gateway</html>',
        contentType: 'text/html',
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
        expect(response.error!.contains('Unexpected Content-Type'), isTrue,
            reason:
                'A non-application/json response must surface as an explicit '
                'Content-Type error');
      } finally {
        await relayer.close();
      }
    });

    test('testSend_networkError_returnsError', () async {
      final adapter = MockDioAdapter.throwing(Exception('Connection refused'));
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
      } finally {
        await relayer.close();
      }
    });

    test('testSend_timeout_returnsTimeoutErrorCode', () async {
      final timeoutException = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/'),
        type: dio.DioExceptionType.receiveTimeout,
        message: 'request timed out',
      );
      final adapter = MockDioAdapter.throwing(timeoutException);
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.errorCode, OZRelayerErrorCodes.timeout);
        expect(response.error!.contains('timed out'), isTrue);
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - send with per-request timeout', () {
    test('testSend_withPerRequestTimeout_sendsRequest', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "timeout-test-hash"}}',
      );
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = adapter;
      // Install a default that is far longer than the per-request
      // override so the override is provably the value reaching dio.
      final relayer = OZRelayerClient.withDio(
        'https://relayer.example.com',
        mockDio,
      );
      try {
        final response = await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
          perRequestTimeoutMs: 5000,
        );
        expect(response.success, isTrue);
        expect(response.hash, 'timeout-test-hash');
        expect(adapter.capturedReceiveTimeout,
            const Duration(milliseconds: 5000));
        expect(
            adapter.capturedSendTimeout, const Duration(milliseconds: 5000));
        expect(adapter.capturedReceiveTimeout,
            isNot(equals(mockDio.options.receiveTimeout)),
            reason: 'Per-request override must replace the client default '
                'on the emitted request');
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - sendXdr', () {
    test('testSendXdr_success_returnsHash', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "def456", '
        '"transactionId": "tx-002", "status": "SUCCESS"}}',
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.sendXdr(_testTransactionEnvelope());
        expect(response.success, isTrue);
        expect(response.hash, 'def456');
        expect(response.transactionId, 'tx-002');
        expect(response.status, 'SUCCESS');
      } finally {
        await relayer.close();
      }
    });

    test('testSendXdr_buildsCorrectJsonPayload', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "def456"}}',
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.sendXdr(_testTransactionEnvelope());
        expect(response.success, isTrue);
        expect(response.hash, 'def456');

        expect(adapter.capturedBody, isNotNull);
        final body = json.decode(adapter.capturedBody!) as Map<String, dynamic>;
        expect(body.containsKey('xdr'), isTrue);
        final xdrValue = body['xdr'] as String;
        expect(xdrValue.isNotEmpty, isTrue);

        final decoded =
            XdrTransactionEnvelope.fromEnvelopeXdrString(xdrValue);
        expect(decoded.discriminant, XdrEnvelopeType.ENVELOPE_TYPE_TX);
      } finally {
        await relayer.close();
      }
    });

    test('testSendXdr_errorResponse_returnsError', () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "error": "invalid xdr", "code": "INVALID_XDR"}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.sendXdr(_testTransactionEnvelope());
        expect(response.success, isFalse);
        expect(response.error, 'invalid xdr');
        expect(response.errorCode, 'INVALID_XDR');
      } finally {
        await relayer.close();
      }
    });

    test('testSendXdr_timeout_returnsTimeoutErrorCode', () async {
      final timeoutException = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/'),
        type: dio.DioExceptionType.receiveTimeout,
        message: 'request timed out',
      );
      final adapter = MockDioAdapter.throwing(timeoutException);
      final relayer = _client(adapter);
      try {
        final response = await relayer.sendXdr(_testTransactionEnvelope());
        expect(response.success, isFalse);
        expect(response.errorCode, OZRelayerErrorCodes.timeout);
        expect(response.error!.contains('timed out'), isTrue);
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - response parsing', () {
    test('testResponseParsing_withDataWrapper_extractsNestedFields', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"transactionId": "tx-100", '
        '"hash": "hash-100", "status": "PENDING"}}',
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isTrue);
        expect(response.transactionId, 'tx-100');
        expect(response.hash, 'hash-100');
        expect(response.status, 'PENDING');
      } finally {
        await relayer.close();
      }
    });

    test('testResponseParsing_withoutDataWrapper_usesTopLevelFields',
        () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "transactionId": "tx-200", '
        '"hash": "hash-200", "status": "SUCCESS"}',
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isTrue);
        expect(response.transactionId, 'tx-200');
        expect(response.hash, 'hash-200');
        expect(response.status, 'SUCCESS');
      } finally {
        await relayer.close();
      }
    });

    test('testResponseParsing_errorFromErrorField', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"success": false, "error": "specific error message"}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, 'specific error message');
      } finally {
        await relayer.close();
      }
    });

    test('testResponseParsing_errorFallbackToMessageField', () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "message": "fallback error message"}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, 'fallback error message');
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - extractErrorCode', () {
    test('testExtractErrorCode_topLevelCode', () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "error": "failed", "code": "SIMULATION_FAILED"}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.errorCode, 'SIMULATION_FAILED');
      } finally {
        await relayer.close();
      }
    });

    test('testExtractErrorCode_errorCodeField', () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "error": "unauthorized", "errorCode": "UNAUTHORIZED"}',
        statusCode: 403,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.errorCode, 'UNAUTHORIZED');
      } finally {
        await relayer.close();
      }
    });

    test('testExtractErrorCode_nestedDataCode', () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "error": "failed", "data": {"code": "ONCHAIN_FAILED"}}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.errorCode, 'ONCHAIN_FAILED');
      } finally {
        await relayer.close();
      }
    });

    test('testExtractErrorCode_noCodeFieldReturnsNull', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"success": false, "error": "something went wrong"}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, 'something went wrong');
        expect(response.errorCode, isNull);
      } finally {
        await relayer.close();
      }
    });

    test('testExtractErrorCode_topLevelCodeWinsOverErrorCodeAndNestedData',
        () async {
      final adapter = MockDioAdapter.response(
        responseBody:
            '{"success": false, "error": "failed", "code": "A", '
            '"errorCode": "B", "data": {"code": "C"}}',
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        expect(response.success, isFalse);
        expect(response.errorCode, 'A',
            reason:
                'Top-level `code` must take precedence over `errorCode` and '
                'nested `data.code`');
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - status code fallback', () {
    test('testErrorResponse_statusCodeFallback_whenNoErrorOrMessageField',
        () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"success": false}',
        statusCode: 502,
      );
      final relayer = _client(adapter);
      try {
        final response =
            await relayer.send(_testHostFunction(), <XdrSorobanAuthorizationEntry>[
          _testAuthEntry(),
        ]);
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
        expect(response.error!.contains('502'), isTrue,
            reason: 'Error message must contain the HTTP status code when '
                'no error/message field is present');
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - close', () {
    test('testClose_clientIsAutoCloseable', () async {
      final relayer = OZRelayerClient('https://relayer.example.com');
      await relayer.close();
    });

    test('testClose_doubleCloseDoesNotThrow', () async {
      final relayer = OZRelayerClient('https://relayer.example.com');
      await relayer.close();
      await relayer.close();
    });
  });

  group('OZRelayerClient - OZRelayerErrorCodes constants', () {
    test('testOZRelayerErrorCodes_allCodesAreNonBlank', () {
      const codes = <String>[
        OZRelayerErrorCodes.invalidParams,
        OZRelayerErrorCodes.invalidXdr,
        OZRelayerErrorCodes.poolCapacity,
        OZRelayerErrorCodes.simulationFailed,
        OZRelayerErrorCodes.onchainFailed,
        OZRelayerErrorCodes.invalidTimeBounds,
        OZRelayerErrorCodes.feeLimitExceeded,
        OZRelayerErrorCodes.unauthorized,
        OZRelayerErrorCodes.timeout,
      ];
      for (final code in codes) {
        expect(code.trim().isNotEmpty, isTrue,
            reason: 'Error code must not be blank: "$code"');
      }
    });

    test('testOZRelayerErrorCodes_specificValues', () {
      expect(OZRelayerErrorCodes.timeout, 'TIMEOUT');
      expect(OZRelayerErrorCodes.invalidParams, 'INVALID_PARAMS');
      expect(OZRelayerErrorCodes.invalidXdr, 'INVALID_XDR');
      expect(OZRelayerErrorCodes.poolCapacity, 'POOL_CAPACITY');
      expect(OZRelayerErrorCodes.simulationFailed, 'SIMULATION_FAILED');
      expect(OZRelayerErrorCodes.onchainFailed, 'ONCHAIN_FAILED');
      expect(OZRelayerErrorCodes.invalidTimeBounds, 'INVALID_TIME_BOUNDS');
      expect(OZRelayerErrorCodes.feeLimitExceeded, 'FEE_LIMIT_EXCEEDED');
      expect(OZRelayerErrorCodes.unauthorized, 'UNAUTHORIZED');
    });
  });

  group('OZRelayerClient - OZRelayerResponse equality', () {
    test('testOZRelayerResponse_equalityWithIdenticalFields', () {
      final detailsA = <String, dynamic>{
        'outer': <String, dynamic>{
          'inner': <dynamic>[1, 2, 3],
          'flag': true,
        },
        'extra': 'value',
      };
      final detailsB = <String, dynamic>{
        'outer': <String, dynamic>{
          'inner': <dynamic>[1, 2, 3],
          'flag': true,
        },
        'extra': 'value',
      };
      final a = OZRelayerResponse(
        success: false,
        transactionId: 'tx',
        hash: 'h',
        status: 'PENDING',
        error: 'oops',
        errorCode: 'SIMULATION_FAILED',
        details: detailsA,
      );
      final b = OZRelayerResponse(
        success: false,
        transactionId: 'tx',
        hash: 'h',
        status: 'PENDING',
        error: 'oops',
        errorCode: 'SIMULATION_FAILED',
        details: detailsB,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZRelayerResponse_inequalityWithDifferentDetails', () {
      final a = OZRelayerResponse(
        success: false,
        error: 'oops',
        details: <String, dynamic>{
          'outer': <String, dynamic>{
            'inner': <dynamic>[1, 2, 3],
          },
        },
      );
      final b = OZRelayerResponse(
        success: false,
        error: 'oops',
        details: <String, dynamic>{
          'outer': <String, dynamic>{
            'inner': <dynamic>[1, 2, 4],
          },
        },
      );
      expect(a == b, isFalse,
          reason: 'A nested-value difference in details must make '
              'OZRelayerResponse instances unequal');
    });
  });

  group('OZRelayerClient - redirect / response-size hardening', () {
    test('testRequest_followRedirectsDisabledOnEveryRequest', () async {
      final mockDio = dio.Dio();
      final adapter = MockDioAdapter.json('{"success": true}');
      mockDio.httpClientAdapter = adapter;
      final injected =
          OZRelayerClient.withDio('https://relayer.example.com', mockDio);
      try {
        await injected.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
      } finally {
        await injected.close();
      }
      expect(adapter.capturedFollowRedirects, isFalse,
          reason: 'Every emitted request must carry followRedirects=false');
      expect(adapter.capturedMaxRedirects, 0,
          reason: 'Every emitted request must carry maxRedirects=0');
    });

    test('testWithDio_doesNotMutateInjectedClientOptions', () async {
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "h"}}',
      );
      // Pre-set followRedirects to a value distinct from the client's
      // expected request-time value (which is false). The withDio
      // constructor must not overwrite this caller-owned configuration.
      mockDio.options.followRedirects = true;
      mockDio.options.maxRedirects = 7;
      final injected =
          OZRelayerClient.withDio('https://relayer.example.com', mockDio);
      try {
        await injected.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
      } finally {
        await injected.close();
      }
      expect(mockDio.options.followRedirects, isTrue,
          reason:
              'withDio must not mutate the injected client default options');
      expect(mockDio.options.maxRedirects, 7,
          reason:
              'withDio must not mutate the injected client default options');
    });

    test('testSend_oversizedResponseBody_returnsErrorResponse', () async {
      final body = '{"success": true, "data": '
          '"${'x' * (OZConstants.maxRelayerResponseBytes + 16)}"}';
      final adapter = MockDioAdapter.response(responseBody: body);
      final relayer = _client(adapter);
      try {
        final response = await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
        expect(response.error!.contains('exceeds maximum size'), isTrue,
            reason: 'Oversized response must surface as an error response');
      } finally {
        await relayer.close();
      }
    });

    test('testSend_errorMessageIsTruncated', () async {
      // A hostile relayer returns a multi-KiB error string; the
      // truncation guard caps it to 200 chars + ellipsis.
      final longMessage = 'E' * 5000;
      final body = '{"success": false, "error": "$longMessage"}';
      final adapter = MockDioAdapter.response(
        responseBody: body,
        statusCode: 400,
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
        expect(response.error!.length <= 203, isTrue,
            reason:
                'Relayer error message must be truncated to at most 200 '
                'characters plus a 3-character ellipsis');
        expect(response.error!.endsWith('...'), isTrue);
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - Content-Type validation', () {
    test('testSend_textHtmlContentType_returnsContentTypeError', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"success": true}',
        contentType: 'text/html',
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
        expect(response.error!.contains('Unexpected Content-Type'), isTrue,
            reason:
                'A non-application/json response must surface as an explicit '
                'Content-Type error');
        expect(response.error!.contains('text/html'), isTrue);
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - JSON body parsing', () {
    test(
        'testSend_validJsonContentTypeWithMalformedBody_returnsFailedToParse',
        () async {
      final adapter = MockDioAdapter.response(
        responseBody: 'not-json-at-all',
        contentType: 'application/json',
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
        expect(response.error!.contains('Failed to parse'), isTrue,
            reason:
                'A malformed JSON body under application/json must surface '
                'as a Failed-to-parse error');
      } finally {
        await relayer.close();
      }
    });

    test(
        'testSend_validJsonContentTypeWithNonObjectBody_returnsFailedToParse',
        () async {
      final adapter = MockDioAdapter.response(
        responseBody: '[1,2,3]',
        contentType: 'application/json',
      );
      final relayer = _client(adapter);
      try {
        final response = await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        expect(response.success, isFalse);
        expect(response.error, isNotNull);
        expect(response.error!.contains('Failed to parse'), isTrue,
            reason:
                'A non-object JSON body must surface as a Failed-to-parse '
                'error rather than as a typed-cast crash');
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - timeout-variant mapping', () {
    for (final variant in <dio.DioExceptionType>[
      dio.DioExceptionType.receiveTimeout,
      dio.DioExceptionType.connectionTimeout,
      dio.DioExceptionType.sendTimeout,
    ]) {
      test('testSend_${variant.name}_returnsTimeoutErrorCode', () async {
        final timeoutException = dio.DioException(
          requestOptions: dio.RequestOptions(path: '/'),
          type: variant,
          message: 'request timed out',
        );
        final adapter = MockDioAdapter.throwing(timeoutException);
        final relayer = _client(adapter);
        try {
          final response = await relayer.send(
            _testHostFunction(),
            <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
          );
          expect(response.success, isFalse);
          expect(response.errorCode, OZRelayerErrorCodes.timeout,
              reason: 'All three DioExceptionType timeout variants must map to '
                  'the TIMEOUT error code');
          expect(response.error!.contains('timed out'), isTrue);
        } finally {
          await relayer.close();
        }
      });
    }
  });

  group('OZRelayerClient - client headers', () {
    test('testRequest_carriesClientNameAndVersionHeaders', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "h"}}',
      );
      final relayer = _client(adapter);
      try {
        await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        final headers = adapter.capturedHeaders;
        final nameHeader = headers[OZConstants.clientNameHeader] ??
            headers[OZConstants.clientNameHeader.toLowerCase()];
        final versionHeader = headers[OZConstants.clientVersionHeader] ??
            headers[OZConstants.clientVersionHeader.toLowerCase()];
        expect(nameHeader, isNotNull,
            reason: 'OZ-Client-Name header must be present on every request');
        expect(nameHeader!.first.isNotEmpty, isTrue,
            reason: 'OZ-Client-Name header value must be non-empty');
        expect(versionHeader, isNotNull,
            reason: 'OZ-Client-Version header must be present on every request');
        expect(versionHeader!.first.isNotEmpty, isTrue,
            reason: 'OZ-Client-Version header value must be non-empty');
      } finally {
        await relayer.close();
      }
    });

    test('testRequest_trailingSlashUrlNormalizedInRequestUrl', () async {
      final adapter = MockDioAdapter.json(
        '{"success": true, "data": {"hash": "h"}}',
      );
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = adapter;
      final relayer = OZRelayerClient.withDio(
        'https://relayer.example.com///',
        mockDio,
      );
      try {
        await relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
        );
        expect(adapter.capturedUrl, isNotNull);
        expect(adapter.capturedUrl, 'https://relayer.example.com',
            reason:
                'Captured URL must be the trailing-slash-stripped canonical '
                'form (no path, no trailing slashes)');
      } finally {
        await relayer.close();
      }
    });
  });

  group('OZRelayerClient - cancellation', () {
    test('testSend_cancellation_returnsCancelledResponse', () async {
      final adapter = MockDioAdapter.delayed(
        '{"success": true, "data": {"hash": "abc"}}',
        const Duration(seconds: 5),
      );
      final relayer = _client(adapter);
      final cancelToken = dio.CancelToken();
      try {
        final future = relayer.send(
          _testHostFunction(),
          <XdrSorobanAuthorizationEntry>[_testAuthEntry()],
          cancelToken: cancelToken,
        );
        cancelToken.cancel('test cancellation');
        final response = await future;
        expect(response.success, isFalse);
        expect(response.error, 'Request cancelled');
        expect(response.errorCode, isNull,
            reason: 'Cancellation does not emit a distinct error code');
      } finally {
        await relayer.close();
      }
    });

    test('testSendXdr_cancellation_returnsCancelledResponse', () async {
      final adapter = MockDioAdapter.delayed(
        '{"success": true, "data": {"hash": "abc"}}',
        const Duration(seconds: 5),
      );
      final relayer = _client(adapter);
      final cancelToken = dio.CancelToken();
      try {
        final future = relayer.sendXdr(
          _testTransactionEnvelope(),
          cancelToken: cancelToken,
        );
        cancelToken.cancel('test cancellation');
        final response = await future;
        expect(response.success, isFalse);
        expect(response.error, 'Request cancelled');
        expect(response.errorCode, isNull,
            reason: 'Cancellation does not emit a distinct error code');
      } finally {
        await relayer.close();
      }
    });
  });
}
