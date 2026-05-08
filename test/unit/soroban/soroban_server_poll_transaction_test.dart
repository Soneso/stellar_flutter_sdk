import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// MockDioAdapter for mocking HTTP responses in `SorobanServer` tests.
class MockDioAdapter implements dio.HttpClientAdapter {
  /// Constructs the adapter using the provided per-request handler that
  /// returns a fully-formed [dio.ResponseBody] for each captured request.
  MockDioAdapter(this.onRequest);

  /// Per-request handler invoked for every fetch.
  final dio.ResponseBody Function(dio.RequestOptions) onRequest;

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

dio.ResponseBody _jsonResponseBody(int requestId, Map<String, dynamic> result) {
  return dio.ResponseBody.fromString(
    jsonEncode({
      'jsonrpc': '2.0',
      'id': requestId,
      'result': result,
    }),
    200,
    headers: {
      'content-type': [dio.Headers.jsonContentType],
    },
  );
}

Map<String, dynamic> _notFoundResult() => {
      'status': 'NOT_FOUND',
      'latestLedger': 100,
      'latestLedgerCloseTime': '1234567890',
      'oldestLedger': 50,
      'oldestLedgerCloseTime': '1234560000',
    };

Map<String, dynamic> _successResult() => {
      'status': 'SUCCESS',
      'ledger': 200,
      'createdAt': '1234567890',
      'applicationOrder': 1,
      'feeBump': false,
      'envelopeXdr': 'AAAA',
      'resultXdr': 'AAAA',
      'resultMetaXdr': 'AAAA',
    };

Map<String, dynamic> _failedResult() => {
      'status': 'FAILED',
      'ledger': 200,
      'createdAt': '1234567890',
      'applicationOrder': 1,
      'feeBump': false,
      'envelopeXdr': 'AAAA',
      'resultXdr': 'AAAA',
      'resultMetaXdr': 'AAAA',
    };

const String _txHash = 'deadbeef';

void main() {
  group('SorobanServer.pollTransaction', () {
    test('test_pollTransaction_respects_max_attempts', () async {
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        expect(body['method'], 'getTransaction');
        requestCount++;
        return _jsonResponseBody(body['id'] as int, _notFoundResult());
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      final response = await server.pollTransaction(
        _txHash,
        maxAttempts: 3,
        sleepStrategy: (_) => Duration.zero,
      );
      expect(response.status, GetTransactionResponse.STATUS_NOT_FOUND);
      expect(requestCount, 3);
    });

    test('test_pollTransaction_zero_max_attempts_throws_argument_error',
        () async {
      final server = SorobanServer('https://soroban-testnet.stellar.org');
      expect(
        () => server.pollTransaction(_txHash, maxAttempts: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('test_pollTransaction_negative_max_attempts_throws_argument_error',
        () async {
      final server = SorobanServer('https://soroban-testnet.stellar.org');
      expect(
        () => server.pollTransaction(_txHash, maxAttempts: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'test_pollTransaction_returns_success_when_status_succeeds_on_first_attempt',
        () async {
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        requestCount++;
        return _jsonResponseBody(body['id'] as int, _successResult());
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      final response = await server.pollTransaction(
        _txHash,
        maxAttempts: 5,
        sleepStrategy: (_) => Duration.zero,
      );
      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(requestCount, 1);
    });

    test('test_pollTransaction_returns_failed_status_without_continuing_polling',
        () async {
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        requestCount++;
        return _jsonResponseBody(body['id'] as int, _failedResult());
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      final response = await server.pollTransaction(
        _txHash,
        maxAttempts: 5,
        sleepStrategy: (_) => Duration.zero,
      );
      expect(response.status, GetTransactionResponse.STATUS_FAILED);
      expect(requestCount, 1);
    });

    test('test_pollTransaction_swallows_transient_rpc_error_and_continues',
        () async {
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        requestCount++;
        if (requestCount == 1) {
          // Trigger transient failure: a 500 status forces dio to throw.
          return dio.ResponseBody.fromString(
            'internal server error',
            500,
            headers: {
              'content-type': [dio.Headers.jsonContentType],
            },
          );
        }
        return _jsonResponseBody(body['id'] as int, _successResult());
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      final response = await server.pollTransaction(
        _txHash,
        maxAttempts: 5,
        sleepStrategy: (_) => Duration.zero,
      );
      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(requestCount, 2);
    });

    test('test_pollTransaction_pending_then_success_two_attempt_sequence',
        () async {
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        requestCount++;
        if (requestCount == 1) {
          return _jsonResponseBody(body['id'] as int, _notFoundResult());
        }
        return _jsonResponseBody(body['id'] as int, _successResult());
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      final response = await server.pollTransaction(
        _txHash,
        maxAttempts: 5,
        sleepStrategy: (_) => Duration.zero,
      );
      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(requestCount, 2);
    });

    test('test_pollTransaction_attempts_equals_one_polls_exactly_once',
        () async {
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        requestCount++;
        return _jsonResponseBody(body['id'] as int, _notFoundResult());
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      final response = await server.pollTransaction(
        _txHash,
        maxAttempts: 1,
        sleepStrategy: (_) => Duration.zero,
      );
      expect(response.status, GetTransactionResponse.STATUS_NOT_FOUND);
      expect(requestCount, 1);
    });

    test('test_pollTransaction_default_sleep_strategy_is_one_second_per_attempt',
        () async {
      // Exercise the production default sleepStrategy end-to-end. Force
      // exactly one inter-attempt sleep by returning NOT_FOUND on the first
      // poll and SUCCESS on the second, then assert elapsed wall time is at
      // least the documented 1-second default. A regression that lowers the
      // default (e.g., to zero or a few milliseconds) fails this test.
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        requestCount++;
        final result =
            requestCount == 1 ? _notFoundResult() : _successResult();
        return _jsonResponseBody(body['id'] as int, result);
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      final stopwatch = Stopwatch()..start();
      // Intentionally omit sleepStrategy to invoke the production default.
      final response =
          await server.pollTransaction(_txHash, maxAttempts: 2);
      stopwatch.stop();

      expect(response.status, GetTransactionResponse.STATUS_SUCCESS);
      expect(requestCount, 2);
      // One inter-attempt sleep at the documented 1000 ms default. Allow a
      // small floor tolerance for timer scheduling jitter while keeping the
      // assertion tight enough to catch a regression that drops the default
      // below ~1 second.
      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 950)),
      );
    });

    test('rethrows last RPC error when every attempt fails',
        () async {
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        requestCount++;
        // Always return a 500 to keep `getTransaction` in failure state.
        return dio.ResponseBody.fromString(
          'persistent error',
          500,
          headers: {
            'content-type': [dio.Headers.jsonContentType],
          },
        );
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      await expectLater(
        server.pollTransaction(
          _txHash,
          maxAttempts: 2,
          sleepStrategy: (_) => Duration.zero,
        ),
        throwsA(anything),
      );
      expect(requestCount, 2);
    });

    test(
        'test_pollTransaction_custom_sleep_strategy_called_with_attempt_number',
        () async {
      final attemptsObserved = <int>[];
      var requestCount = 0;
      final mockDio = dio.Dio();
      mockDio.httpClientAdapter = MockDioAdapter((options) {
        final body = jsonDecode(options.data as String) as Map<String, dynamic>;
        requestCount++;
        return _jsonResponseBody(body['id'] as int, _notFoundResult());
      });

      final server = SorobanServer.withDio(
        'https://soroban-testnet.stellar.org',
        mockDio,
      );

      await server.pollTransaction(
        _txHash,
        maxAttempts: 4,
        sleepStrategy: (attempt) {
          attemptsObserved.add(attempt);
          return Duration.zero;
        },
      );
      // The strategy is invoked between attempts only — for `maxAttempts=4`
      // that yields three sleeps, one per inter-attempt boundary, with
      // 1-indexed attempt numbers.
      expect(requestCount, 4);
      expect(attemptsObserved, <int>[1, 2, 3]);
    });
  });
}
