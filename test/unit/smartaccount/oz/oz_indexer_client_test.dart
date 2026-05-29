// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'mock_dio_adapter.dart';

const String _testAccountId =
    'GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D';
const String _testContractId =
    'CA2LVQXQLGPWHV2QO5ENVAGWM2TYICRMWXW4UXBPVKV26WLKU2V3UTH5';

const String _contractSummaryJson = '''
{
    "contract_id": "CA2LVQXQLGPWHV2QO5ENVAGWM2TYICRMWXW4UXBPVKV26WLKU2V3UTH5",
    "context_rule_count": 2,
    "external_signer_count": 1,
    "delegated_signer_count": 1,
    "native_signer_count": 0,
    "first_seen_ledger": 100000,
    "last_seen_ledger": 200000,
    "context_rule_ids": [0, 1]
}
''';

OZIndexerClient _client(
  MockDioAdapter adapter, {
  String url = 'https://indexer.example.com',
}) {
  final mockDio = dio.Dio();
  mockDio.httpClientAdapter = adapter;
  return OZIndexerClient.withDio(url, mockDio);
}

void main() {
  group('OZIndexerClient - constructor validation', () {
    test('testConstructor_blankUrl_throwsConfigurationException', () {
      expect(() => OZIndexerClient(''), throwsA(isA<InvalidConfig>()));
    });

    test('testConstructor_whitespaceUrl_throwsConfigurationException', () {
      expect(() => OZIndexerClient('   '), throwsA(isA<InvalidConfig>()));
    });

    test('testConstructor_httpUrl_throwsConfigurationException', () {
      expect(
        () => OZIndexerClient('http://indexer.example.com'),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testConstructor_httpsUrlSucceeds', () async {
      final client = OZIndexerClient('https://indexer.example.com');
      await client.close();
    });

    test('testConstructor_localhostHttpUrlSucceeds', () async {
      final client = OZIndexerClient('http://localhost:8080');
      await client.close();
    });

    test('testConstructor_ftpSchemeThrows', () {
      expect(
        () => OZIndexerClient('ftp://indexer.example.com'),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testConstructor_noSchemeThrows', () {
      expect(
        () => OZIndexerClient('indexer.example.com'),
        throwsA(isA<InvalidConfig>()),
      );
    });

    test('testConstructor_leadingWhitespaceUrl_succeedsAfterTrim', () async {
      final client = OZIndexerClient('  https://indexer.example.com');
      await client.close();
    });

    test('testConstructor_trailingNewlineUrl_succeedsAfterTrim', () async {
      final client = OZIndexerClient('https://indexer.example.com\n');
      await client.close();
    });

    test('testConstructor_schemeOnlyUrl_throwsConfigurationException', () {
      expect(
        () => OZIndexerClient('https://'),
        throwsA(isA<InvalidConfig>()),
      );
    });
  });

  group('OZIndexerClient - DEFAULT_INDEXER_URLS', () {
    test('testDefaultIndexerUrls_testnetHasUrl', () {
      final url =
          OZIndexerClient.defaultIndexerUrls[Network.TESTNET.networkPassphrase];
      expect(url, isNotNull);
      expect(url!.startsWith('https://'), isTrue);
    });

    test('testDefaultIndexerUrls_unknownNetworkReturnsNull', () {
      final url = OZIndexerClient.defaultIndexerUrls['Custom Network ; 2026'];
      expect(url, isNull);
    });
  });

  group('OZIndexerClient - getDefaultUrl', () {
    test('testGetDefaultUrl_testnetReturnsUrl', () {
      final url =
          OZIndexerClient.getDefaultUrl(Network.TESTNET.networkPassphrase);
      expect(url, isNotNull);
      expect(url!.startsWith('https://'), isTrue);
    });

    test('testGetDefaultUrl_unknownNetworkReturnsNull', () {
      final url =
          OZIndexerClient.getDefaultUrl('Unknown Network ; January 2099');
      expect(url, isNull);
    });

    test('testGetDefaultUrl_mainnetReturnsNullOrUrl', () {
      final url =
          OZIndexerClient.getDefaultUrl(Network.PUBLIC.networkPassphrase);
      if (url != null) {
        expect(url.startsWith('https://'), isTrue,
            reason: 'If mainnet URL is set, it must use HTTPS');
      }
    });
  });

  group('OZIndexerClient - forNetwork', () {
    test('testForNetwork_testnetReturnsClient', () async {
      final client =
          OZIndexerClient.forNetwork(Network.TESTNET.networkPassphrase);
      expect(client, isNotNull);
      await client!.close();
    });

    test('testForNetwork_unknownNetworkReturnsNull', () {
      final client = OZIndexerClient.forNetwork('Unknown Network ; 2099');
      expect(client, isNull);
    });

    test('testForNetwork_mainnetReturnsNullCurrently', () async {
      final url =
          OZIndexerClient.getDefaultUrl(Network.PUBLIC.networkPassphrase);
      final client =
          OZIndexerClient.forNetwork(Network.PUBLIC.networkPassphrase);
      if (url == null) {
        expect(client, isNull);
      } else {
        expect(client, isNotNull);
        await client!.close();
      }
    });
  });

  group('OZIndexerClient - lookupByCredentialId', () {
    test('testLookupByCredentialId_success', () async {
      final body = '''
{
    "credentialId": "aabbccdd",
    "contracts": [$_contractSummaryJson],
    "count": 1
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        final result = await indexer.lookupByCredentialId('qrvM3Q');
        expect(result.credentialId, 'aabbccdd');
        expect(result.count, 1);
        expect(result.contracts.length, 1);
        expect(result.contracts[0].contractId, _testContractId);
        expect(result.contracts[0].contextRuleCount, 2);
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByCredentialId_acceptsStringEncodedNumericFields',
        () async {
      // The production indexer service serialises numeric columns (counts,
      // ledger numbers) as JSON strings to preserve precision; the SDK must
      // accept them alongside JSON numbers.
      const body = '''
{
    "credentialId": "aabbccdd",
    "contracts": [
        {
            "contract_id": "CA2LVQXQLGPWHV2QO5ENVAGWM2TYICRMWXW4UXBPVKV26WLKU2V3UTH5",
            "context_rule_count": "2",
            "external_signer_count": "1",
            "delegated_signer_count": "1",
            "native_signer_count": "0",
            "first_seen_ledger": "100000",
            "last_seen_ledger": "200000",
            "context_rule_ids": ["0", "1"]
        }
    ],
    "count": "1"
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        final result = await indexer.lookupByCredentialId('qrvM3Q');
        expect(result.count, 1);
        expect(result.contracts.length, 1);
        final summary = result.contracts[0];
        expect(summary.contextRuleCount, 2);
        expect(summary.externalSignerCount, 1);
        expect(summary.delegatedSignerCount, 1);
        expect(summary.nativeSignerCount, 0);
        expect(summary.firstSeenLedger, 100000);
        expect(summary.lastSeenLedger, 200000);
        expect(summary.contextRuleIds, [0, 1]);
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByCredentialId_verifiesUrlPath', () async {
      final body = '''
{
    "credentialId": "aabbccdd",
    "contracts": [],
    "count": 0
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        await indexer.lookupByCredentialId('qrvM3Q');
        expect(adapter.capturedUrl, isNotNull);
        expect(adapter.capturedUrl!.contains('/api/lookup/'), isTrue,
            reason: 'Request URL must contain /api/lookup/ path');
        expect(adapter.capturedUrl!.endsWith('aabbccdd'), isTrue,
            reason: 'Request URL must end with hex-encoded credential ID');
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByCredentialId_invalidBase64url_throwsValidationException',
        () async {
      final adapter = MockDioAdapter.json('{}');
      final indexer = _client(adapter);
      try {
        await expectLater(
          indexer.lookupByCredentialId('!!!invalid-base64url!!!'),
          throwsA(isA<InvalidInput>()),
        );
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByCredentialId_http404_throwsIndexerException', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error": "not found"}',
        statusCode: 404,
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('404'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByCredentialId_http500_throwsIndexerException', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error": "internal server error"}',
        statusCode: 500,
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('500'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByCredentialId_nonJsonResponse_throwsIndexerException',
        () async {
      final adapter = MockDioAdapter.response(
        responseBody: '<html>Not JSON</html>',
        contentType: 'text/html',
      );
      final indexer = _client(adapter);
      try {
        await expectLater(
          indexer.lookupByCredentialId('qrvM3Q'),
          throwsA(isA<IndexerRequestFailed>()),
        );
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - lookupByAddress', () {
    test('testLookupByAddress_successWithGAddress', () async {
      final body = '''
{
    "signerAddress": "$_testAccountId",
    "contracts": [$_contractSummaryJson],
    "count": 1
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        final result = await indexer.lookupByAddress(_testAccountId);
        expect(result.signerAddress, _testAccountId);
        expect(result.count, 1);
        expect(result.contracts.length, 1);
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByAddress_successWithCAddress', () async {
      final body = '''
{
    "signerAddress": "$_testContractId",
    "contracts": [$_contractSummaryJson],
    "count": 1
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        final result = await indexer.lookupByAddress(_testContractId);
        expect(result.signerAddress, _testContractId);
        expect(result.count, 1);
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByAddress_verifiesUrlPath', () async {
      final body = '''
{
    "signerAddress": "$_testAccountId",
    "contracts": [],
    "count": 0
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        await indexer.lookupByAddress(_testAccountId);
        expect(adapter.capturedUrl, isNotNull);
        expect(adapter.capturedUrl!.contains('/api/lookup/address/'), isTrue,
            reason: 'Request URL must contain /api/lookup/address/ path');
        expect(adapter.capturedUrl!.endsWith(_testAccountId), isTrue,
            reason: 'Request URL must end with the address');
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByAddress_invalidAddress_throwsValidationException',
        () async {
      final adapter = MockDioAdapter.json('{}');
      final indexer = _client(adapter);
      try {
        await expectLater(
          indexer.lookupByAddress('INVALID_ADDRESS'),
          throwsA(isA<InvalidAddress>()),
        );
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByAddress_httpError_throwsIndexerException', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error": "service unavailable"}',
        statusCode: 503,
      );
      final indexer = _client(adapter);
      try {
        await expectLater(
          indexer.lookupByAddress(_testAccountId),
          throwsA(isA<IndexerRequestFailed>()),
        );
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - getContract', () {
    test('testGetContract_success', () async {
      final body = '''
{
    "contractId": "$_testContractId",
    "summary": $_contractSummaryJson,
    "contextRules": [
        {
            "context_rule_id": 0,
            "signers": [
                {
                    "signer_type": "External",
                    "credential_id": "aabbccdd"
                },
                {
                    "signer_type": "Delegated",
                    "signer_address": "$_testAccountId"
                }
            ],
            "policies": [
                {
                    "policy_address": "$_testContractId",
                    "install_params": {"limit": "1000000000"}
                }
            ]
        },
        {
            "context_rule_id": 1,
            "signers": [
                {
                    "signer_type": "Native"
                }
            ],
            "policies": []
        }
    ]
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        final result = await indexer.getContract(_testContractId);
        expect(result.contractId, _testContractId);
        expect(result.summary.contextRuleCount, 2);
        expect(result.summary.externalSignerCount, 1);
        expect(result.summary.delegatedSignerCount, 1);
        expect(result.summary.nativeSignerCount, 0);
        expect(result.summary.firstSeenLedger, 100000);
        expect(result.summary.lastSeenLedger, 200000);
        expect(result.summary.contextRuleIds, <int>[0, 1]);

        final rule0 = result.contextRules[0];
        expect(rule0.contextRuleId, 0);
        expect(rule0.signers.length, 2);
        expect(rule0.signers[0].signerType, 'External');
        expect(rule0.signers[0].credentialId, 'aabbccdd');
        expect(rule0.signers[1].signerType, 'Delegated');
        expect(rule0.signers[1].signerAddress, _testAccountId);
        expect(rule0.policies.length, 1);
        expect(rule0.policies[0].policyAddress, _testContractId);
        expect(rule0.policies[0].installParams, isNotNull);

        final rule1 = result.contextRules[1];
        expect(rule1.contextRuleId, 1);
        expect(rule1.signers.length, 1);
        expect(rule1.signers[0].signerType, 'Native');
        expect(rule1.policies.length, 0);
      } finally {
        await indexer.close();
      }
    });

    test('testGetContract_verifiesUrlPath', () async {
      final body = '''
{
    "contractId": "$_testContractId",
    "summary": $_contractSummaryJson,
    "contextRules": []
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        await indexer.getContract(_testContractId);
        expect(adapter.capturedUrl, isNotNull);
        expect(adapter.capturedUrl!.contains('/api/contract/'), isTrue,
            reason: 'Request URL must contain /api/contract/ path');
        expect(adapter.capturedUrl!.endsWith(_testContractId), isTrue,
            reason: 'Request URL must end with the contract ID');
      } finally {
        await indexer.close();
      }
    });

    test('testGetContract_invalidContractId_throwsValidationException',
        () async {
      final adapter = MockDioAdapter.json('{}');
      final indexer = _client(adapter);
      try {
        await expectLater(
          indexer.getContract(_testAccountId),
          throwsA(isA<InvalidAddress>()),
        );
      } finally {
        await indexer.close();
      }
    });

    test('testGetContract_httpError_throwsIndexerException', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error": "not found"}',
        statusCode: 404,
      );
      final indexer = _client(adapter);
      try {
        await expectLater(
          indexer.getContract(_testContractId),
          throwsA(isA<IndexerRequestFailed>()),
        );
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - getStats', () {
    test('testGetStats_success', () async {
      final body = '''
{
    "stats": {
        "total_events": 15234,
        "unique_contracts": 842,
        "unique_credentials": 1203,
        "first_ledger": 50000,
        "last_ledger": 250000,
        "eventTypes": [
            {"event_type": "signer_added", "count": 5000},
            {"event_type": "signer_removed", "count": 1200},
            {"event_type": "policy_added", "count": 3500}
        ]
    }
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        final result = await indexer.getStats();
        expect(result.stats.totalEvents, 15234);
        expect(result.stats.uniqueContracts, 842);
        expect(result.stats.uniqueCredentials, 1203);
        expect(result.stats.firstLedger, 50000);
        expect(result.stats.lastLedger, 250000);
        expect(result.stats.eventTypes.length, 3);
        expect(result.stats.eventTypes[0].eventType, 'signer_added');
        expect(result.stats.eventTypes[0].count, 5000);
        expect(result.stats.eventTypes[1].eventType, 'signer_removed');
        expect(result.stats.eventTypes[1].count, 1200);
        expect(result.stats.eventTypes[2].eventType, 'policy_added');
        expect(result.stats.eventTypes[2].count, 3500);
      } finally {
        await indexer.close();
      }
    });

    test('testGetStats_verifiesUrlPath', () async {
      final body = '''
{
    "stats": {
        "total_events": 0,
        "unique_contracts": 0,
        "unique_credentials": 0,
        "first_ledger": 0,
        "last_ledger": 0,
        "eventTypes": []
    }
}
''';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        await indexer.getStats();
        expect(adapter.capturedUrl, isNotNull);
        expect(adapter.capturedUrl!.endsWith('/api/stats'), isTrue,
            reason: 'Request URL must end with /api/stats');
      } finally {
        await indexer.close();
      }
    });

    test('testGetStats_httpError_throwsIndexerException', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error": "internal server error"}',
        statusCode: 500,
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.getStats();
          fail('expected IndexerRequestFailed');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('500'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - performRequest', () {
    test('testPerformRequest_truncatesLongErrorBody', () async {
      final longBody = 'x' * 300;
      final adapter = MockDioAdapter.response(
        responseBody: longBody,
        statusCode: 400,
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('...'), isTrue,
              reason: 'Long error body must be truncated with ellipsis');
          expect(e.message.contains('x' * 201), isFalse,
              reason: 'Error body must be truncated to at most 200 characters');
        }
      } finally {
        await indexer.close();
      }
    });

    test('testPerformRequest_shortErrorBodyNotTruncated', () async {
      const shortBody = 'short error';
      final adapter = MockDioAdapter.response(
        responseBody: shortBody,
        statusCode: 400,
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('short error'), isTrue);
          expect(e.message.endsWith('...'), isFalse,
              reason: 'Short error body must not be truncated');
        }
      } finally {
        await indexer.close();
      }
    });

    test('testPerformRequest_timeout_throwsIndexerTimeoutException', () async {
      final timeoutException = dio.DioException(
        requestOptions: dio.RequestOptions(path: '/'),
        type: dio.DioExceptionType.receiveTimeout,
        message: 'request timed out',
      );
      final adapter = MockDioAdapter.throwing(timeoutException);
      final indexer = _client(adapter);
      try {
        try {
          await indexer.getStats();
          fail('expected IndexerTimeout');
        } on IndexerTimeout catch (e) {
          expect(e.message.contains('timed out'), isTrue,
              reason: 'Timeout exception message must indicate timeout');
        }
      } finally {
        await indexer.close();
      }
    });

    test('testPerformRequest_genericException_wrappedAsRequestFailed',
        () async {
      final genericException = Exception('unexpected network failure');
      final adapter = MockDioAdapter.throwing(genericException);
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('unexpected network failure'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - isHealthy', () {
    test('testIsHealthy_returnsTrue_whenStatusOk', () async {
      final adapter = MockDioAdapter.json('{"status": "ok"}');
      final indexer = _client(adapter);
      try {
        expect(await indexer.isHealthy(), isTrue);
      } finally {
        await indexer.close();
      }
    });

    test('testIsHealthy_returnsFalse_whenStatusError', () async {
      final adapter = MockDioAdapter.json('{"status": "error"}');
      final indexer = _client(adapter);
      try {
        expect(await indexer.isHealthy(), isFalse);
      } finally {
        await indexer.close();
      }
    });

    test('testIsHealthy_returnsFalse_whenNetworkError', () async {
      final adapter = MockDioAdapter.throwing(Exception('Connection refused'));
      final indexer = _client(adapter);
      try {
        expect(await indexer.isHealthy(), isFalse);
      } finally {
        await indexer.close();
      }
    });

    test('testIsHealthy_returnsFalse_whenNon2xxStatus', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"status": "ok"}',
        statusCode: 500,
      );
      final indexer = _client(adapter);
      try {
        expect(await indexer.isHealthy(), isFalse);
      } finally {
        await indexer.close();
      }
    });

    test('testIsHealthy_verifiesUrlPath', () async {
      final adapter = MockDioAdapter.json('{"status": "ok"}');
      final indexer = _client(adapter);
      try {
        await indexer.isHealthy();
        expect(adapter.capturedUrl, isNotNull);
        expect(adapter.capturedUrl!.endsWith('/'), isTrue,
            reason: 'Health check URL must be the root endpoint');
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - close', () {
    test('testClose_clientIsAutoCloseable', () async {
      final indexer = OZIndexerClient('https://indexer.example.com');
      await indexer.close();
    });

    test('testClose_doubleCloseDoesNotThrow', () async {
      final indexer = OZIndexerClient('https://indexer.example.com');
      await indexer.close();
      await indexer.close();
    });
  });

  group('OZIndexerClient - redirect / response-size hardening', () {
    test('testRequest_followRedirectsDisabledOnEveryRequest', () async {
      final mockDio = dio.Dio();
      final adapter = MockDioAdapter.json(
        '{"credentialId": "aabbccdd", "contracts": [], "count": 0}',
      );
      mockDio.httpClientAdapter = adapter;
      final injected =
          OZIndexerClient.withDio('https://indexer.example.com', mockDio);
      try {
        await injected.lookupByCredentialId('qrvM3Q');
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
        '{"credentialId": "aabbccdd", "contracts": [], "count": 0}',
      );
      // Pre-set followRedirects to a value distinct from the client's
      // expected request-time value (which is false). The withDio
      // constructor must not overwrite this caller-owned configuration.
      mockDio.options.followRedirects = true;
      mockDio.options.maxRedirects = 7;
      final injected =
          OZIndexerClient.withDio('https://indexer.example.com', mockDio);
      try {
        await injected.lookupByCredentialId('qrvM3Q');
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

    test('testLookup_oversizedResponseBody_throwsRequestFailed', () async {
      // A hostile or misconfigured indexer cannot force unbounded
      // memory growth on the client. Bodies larger than the configured
      // cap are rejected before any JSON parsing happens.
      final body =
          '{"credentialId": "aabbccdd", "contracts": [], "count": 0, '
          '"padding": "${'x' * (OZConstants.maxIndexerResponseBytes + 16)}"}';
      final adapter = MockDioAdapter.json(body);
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed for oversized response');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('exceeds maximum size'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - Content-Type validation', () {
    test('testPerformRequest_textHtmlContentType_throwsRequestFailed',
        () async {
      // A server emitting a JSON-shaped body under a non-JSON Content-Type
      // is rejected before parsing so callers receive a precise error.
      final adapter = MockDioAdapter.response(
        responseBody: '{"credentialId": "aabbccdd", "contracts": [], "count": 0}',
        contentType: 'text/html',
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed for non-JSON Content-Type');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('Unexpected Content-Type'), isTrue,
              reason: 'Error message must identify the unexpected type');
          expect(e.message.contains('text/html'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });

    test('testIsHealthy_textHtmlContentType_returnsFalse', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"status": "ok"}',
        contentType: 'text/html',
      );
      final indexer = _client(adapter);
      try {
        expect(await indexer.isHealthy(), isFalse,
            reason:
                'Health check must reject responses without an application/json '
                'Content-Type');
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - JSON body parsing', () {
    test('testLookup_validJsonContentTypeWithMalformedBody_throwsFailedToParse',
        () async {
      final adapter = MockDioAdapter.response(
        responseBody: 'not-json-at-all',
        contentType: 'application/json',
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed for malformed JSON body');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('Failed to parse'), isTrue,
              reason:
                  'A malformed JSON body under application/json must surface '
                  'as Failed-to-parse, not as a FormatException');
        }
      } finally {
        await indexer.close();
      }
    });

    test('testLookup_validJsonContentTypeWithNonObjectBody_throwsNotAJsonObject',
        () async {
      final adapter = MockDioAdapter.response(
        responseBody: '[1,2,3]',
        contentType: 'application/json',
      );
      final indexer = _client(adapter);
      try {
        try {
          await indexer.lookupByCredentialId('qrvM3Q');
          fail('expected IndexerRequestFailed for non-object JSON body');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('is not a JSON object'), isTrue,
              reason:
                  'A non-object JSON body must surface as a typed '
                  'is-not-a-JSON-object error rather than as a typed-cast '
                  'crash');
        }
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - timeout-variant mapping', () {
    for (final variant in <dio.DioExceptionType>[
      dio.DioExceptionType.receiveTimeout,
      dio.DioExceptionType.connectionTimeout,
      dio.DioExceptionType.sendTimeout,
    ]) {
      test('testPerformRequest_${variant.name}_throwsIndexerTimeout',
          () async {
        final timeoutException = dio.DioException(
          requestOptions: dio.RequestOptions(path: '/'),
          type: variant,
          message: 'request timed out',
        );
        final adapter = MockDioAdapter.throwing(timeoutException);
        final indexer = _client(adapter);
        try {
          try {
            await indexer.getStats();
            fail('expected IndexerTimeout for $variant');
          } on IndexerTimeout catch (e) {
            expect(e.message.contains('timed out'), isTrue,
                reason: 'Timeout exception message must indicate timeout');
          }
        } finally {
          await indexer.close();
        }
      });
    }
  });

  group('OZIndexerClient - client headers', () {
    test('testRequest_carriesClientNameAndVersionHeaders', () async {
      final adapter = MockDioAdapter.json(
        '{"credentialId": "aabbccdd", "contracts": [], "count": 0}',
      );
      final indexer = _client(adapter);
      try {
        await indexer.lookupByCredentialId('qrvM3Q');
        final headers = adapter.capturedHeaders;
        final nameHeader = headers[OZConstants.clientNameHeader] ??
            headers[OZConstants.clientNameHeader.toLowerCase()];
        final versionHeader = headers[OZConstants.clientVersionHeader] ??
            headers[OZConstants.clientVersionHeader.toLowerCase()];
        expect(nameHeader, isNotNull,
            reason: 'X-Client-Name header must be present on every request');
        expect(nameHeader!.first.isNotEmpty, isTrue,
            reason: 'X-Client-Name header value must be non-empty');
        expect(versionHeader, isNotNull,
            reason: 'X-Client-Version header must be present on every request');
        expect(versionHeader!.first.isNotEmpty, isTrue,
            reason: 'X-Client-Version header value must be non-empty');
      } finally {
        await indexer.close();
      }
    });

    test('testRequest_trailingSlashUrlNormalizedInRequestUrl', () async {
      final adapter = MockDioAdapter.json(
        '{"credentialId": "aabbccdd", "contracts": [], "count": 0}',
      );
      final indexer = _client(adapter, url: 'https://indexer.example.com///');
      try {
        await indexer.lookupByCredentialId('qrvM3Q');
        expect(
          adapter.capturedUrl,
          'https://indexer.example.com/api/lookup/aabbccdd',
          reason:
              'Captured URL must be the trailing-slash-stripped canonical '
              'form joined with the lookup path and hex-encoded credential ID',
        );
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - cancellation', () {
    test('testLookupByCredentialId_cancellation_throwsRequestFailed', () async {
      final adapter = MockDioAdapter.delayed(
        '{"credentialId": "aabbccdd", "contracts": [], "count": 0}',
        const Duration(seconds: 5),
      );
      final indexer = _client(adapter);
      final cancelToken = dio.CancelToken();
      try {
        final future =
            indexer.lookupByCredentialId('qrvM3Q', cancelToken: cancelToken);
        cancelToken.cancel('test cancellation');
        try {
          await future;
          fail('expected IndexerRequestFailed for cancelled request');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('Request cancelled'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });

    test('testLookupByAddress_cancellation_throwsRequestFailed', () async {
      final adapter = MockDioAdapter.delayed(
        '{"signerAddress": "$_testAccountId", "contracts": [], "count": 0}',
        const Duration(seconds: 5),
      );
      final indexer = _client(adapter);
      final cancelToken = dio.CancelToken();
      try {
        final future =
            indexer.lookupByAddress(_testAccountId, cancelToken: cancelToken);
        cancelToken.cancel('test cancellation');
        try {
          await future;
          fail('expected IndexerRequestFailed for cancelled request');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('Request cancelled'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });

    test('testGetContract_cancellation_throwsRequestFailed', () async {
      final adapter = MockDioAdapter.delayed(
        '{"contractId": "$_testContractId", "summary": $_contractSummaryJson, '
        '"contextRules": []}',
        const Duration(seconds: 5),
      );
      final indexer = _client(adapter);
      final cancelToken = dio.CancelToken();
      try {
        final future =
            indexer.getContract(_testContractId, cancelToken: cancelToken);
        cancelToken.cancel('test cancellation');
        try {
          await future;
          fail('expected IndexerRequestFailed for cancelled request');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('Request cancelled'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });

    test('testGetStats_cancellation_throwsRequestFailed', () async {
      final adapter = MockDioAdapter.delayed(
        '{"stats": {"total_events": 0, "unique_contracts": 0, '
        '"unique_credentials": 0, "first_ledger": 0, "last_ledger": 0, '
        '"eventTypes": []}}',
        const Duration(seconds: 5),
      );
      final indexer = _client(adapter);
      final cancelToken = dio.CancelToken();
      try {
        final future = indexer.getStats(cancelToken: cancelToken);
        cancelToken.cancel('test cancellation');
        try {
          await future;
          fail('expected IndexerRequestFailed for cancelled request');
        } on IndexerRequestFailed catch (e) {
          expect(e.message.contains('Request cancelled'), isTrue);
        }
      } finally {
        await indexer.close();
      }
    });

    test('testIsHealthy_cancellation_returnsFalse', () async {
      final adapter = MockDioAdapter.delayed(
        '{"status": "ok"}',
        const Duration(seconds: 5),
      );
      final indexer = _client(adapter);
      final cancelToken = dio.CancelToken();
      try {
        final future = indexer.isHealthy(cancelToken: cancelToken);
        cancelToken.cancel('test cancellation');
        expect(await future, isFalse,
            reason: 'Cancelled health check must return false');
      } finally {
        await indexer.close();
      }
    });
  });

  group('OZIndexerClient - DTO equality', () {
    test('testOZCredentialLookupResponse_equalityWithIdenticalFields', () {
      const a = OZCredentialLookupResponse(
        credentialId: 'aabbccdd',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const b = OZCredentialLookupResponse(
        credentialId: 'aabbccdd',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZCredentialLookupResponse_inequalityWithDifferentField', () {
      const a = OZCredentialLookupResponse(
        credentialId: 'aabbccdd',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const b = OZCredentialLookupResponse(
        credentialId: 'eeff0011',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      expect(a == b, isFalse);
    });

    test('testOZAddressLookupResponse_equalityWithIdenticalFields', () {
      const a = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const b = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZAddressLookupResponse_inequalityWithDifferentField', () {
      const a = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const b = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: <OZIndexedContractSummary>[],
        count: 7,
      );
      expect(a == b, isFalse);
    });

    test('testOZContractDetailsResponse_equalityWithIdenticalFields', () {
      const summary = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 1,
        externalSignerCount: 0,
        delegatedSignerCount: 0,
        nativeSignerCount: 1,
        firstSeenLedger: 0,
        lastSeenLedger: 1,
        contextRuleIds: <int>[0],
      );
      const a = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: summary,
        contextRules: <OZIndexedContextRule>[],
      );
      const b = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: summary,
        contextRules: <OZIndexedContextRule>[],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZContractDetailsResponse_inequalityWithDifferentField', () {
      const summary = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 1,
        externalSignerCount: 0,
        delegatedSignerCount: 0,
        nativeSignerCount: 1,
        firstSeenLedger: 0,
        lastSeenLedger: 1,
        contextRuleIds: <int>[0],
      );
      const a = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: summary,
        contextRules: <OZIndexedContextRule>[],
      );
      const b = OZContractDetailsResponse(
        contractId: _testAccountId,
        summary: summary,
        contextRules: <OZIndexedContextRule>[],
      );
      expect(a == b, isFalse);
    });

    test('testOZIndexedContractSummary_equalityWithIdenticalFields', () {
      const a = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 2,
        externalSignerCount: 1,
        delegatedSignerCount: 1,
        nativeSignerCount: 0,
        firstSeenLedger: 100,
        lastSeenLedger: 200,
        contextRuleIds: <int>[0, 1],
      );
      const b = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 2,
        externalSignerCount: 1,
        delegatedSignerCount: 1,
        nativeSignerCount: 0,
        firstSeenLedger: 100,
        lastSeenLedger: 200,
        contextRuleIds: <int>[0, 1],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZIndexedContractSummary_inequalityWithDifferentField', () {
      const a = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 2,
        externalSignerCount: 1,
        delegatedSignerCount: 1,
        nativeSignerCount: 0,
        firstSeenLedger: 100,
        lastSeenLedger: 200,
        contextRuleIds: <int>[0, 1],
      );
      const b = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 2,
        externalSignerCount: 1,
        delegatedSignerCount: 1,
        nativeSignerCount: 0,
        firstSeenLedger: 100,
        lastSeenLedger: 200,
        contextRuleIds: <int>[0, 2],
      );
      expect(a == b, isFalse);
    });

    test('testOZIndexedContextRule_equalityWithIdenticalFields', () {
      const a = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[
          OZIndexedSigner(signerType: 'Native'),
        ],
        policies: <OZIndexedPolicy>[],
      );
      const b = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[
          OZIndexedSigner(signerType: 'Native'),
        ],
        policies: <OZIndexedPolicy>[],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZIndexedContextRule_inequalityWithDifferentField', () {
      const a = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[],
        policies: <OZIndexedPolicy>[],
      );
      const b = OZIndexedContextRule(
        contextRuleId: 1,
        signers: <OZIndexedSigner>[],
        policies: <OZIndexedPolicy>[],
      );
      expect(a == b, isFalse);
    });

    test('testOZIndexedSigner_equalityWithIdenticalFields', () {
      const a = OZIndexedSigner(
        signerType: 'Delegated',
        signerAddress: _testAccountId,
      );
      const b = OZIndexedSigner(
        signerType: 'Delegated',
        signerAddress: _testAccountId,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZIndexedSigner_inequalityWithDifferentField', () {
      const a = OZIndexedSigner(
        signerType: 'Delegated',
        signerAddress: _testAccountId,
      );
      const b = OZIndexedSigner(
        signerType: 'External',
        credentialId: 'aabbccdd',
      );
      expect(a == b, isFalse);
    });

    test('testOZIndexedPolicy_equalityWithIdenticalFields', () {
      final a = OZIndexedPolicy(
        policyAddress: _testContractId,
        installParams: <String, Object?>{'limit': '1000'},
      );
      final b = OZIndexedPolicy(
        policyAddress: _testContractId,
        installParams: <String, Object?>{'limit': '1000'},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZIndexedPolicy_inequalityWithDifferentField', () {
      final a = OZIndexedPolicy(
        policyAddress: _testContractId,
        installParams: <String, Object?>{'limit': '1000'},
      );
      final b = OZIndexedPolicy(
        policyAddress: _testContractId,
        installParams: <String, Object?>{'limit': '2000'},
      );
      expect(a == b, isFalse);
    });

    test('testOZIndexerStatsResponse_equalityWithIdenticalFields', () {
      const stats = OZIndexerStats(
        totalEvents: 1,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 4,
        lastLedger: 5,
        eventTypes: <OZEventTypeCount>[],
      );
      const a = OZIndexerStatsResponse(stats: stats);
      const b = OZIndexerStatsResponse(stats: stats);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZIndexerStatsResponse_inequalityWithDifferentField', () {
      const a = OZIndexerStatsResponse(
        stats: OZIndexerStats(
          totalEvents: 1,
          uniqueContracts: 2,
          uniqueCredentials: 3,
          firstLedger: 4,
          lastLedger: 5,
          eventTypes: <OZEventTypeCount>[],
        ),
      );
      const b = OZIndexerStatsResponse(
        stats: OZIndexerStats(
          totalEvents: 99,
          uniqueContracts: 2,
          uniqueCredentials: 3,
          firstLedger: 4,
          lastLedger: 5,
          eventTypes: <OZEventTypeCount>[],
        ),
      );
      expect(a == b, isFalse);
    });

    test('testOZIndexerStats_equalityWithIdenticalFields', () {
      const a = OZIndexerStats(
        totalEvents: 1,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 4,
        lastLedger: 5,
        eventTypes: <OZEventTypeCount>[
          OZEventTypeCount(eventType: 'signer_added', count: 7),
        ],
      );
      const b = OZIndexerStats(
        totalEvents: 1,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 4,
        lastLedger: 5,
        eventTypes: <OZEventTypeCount>[
          OZEventTypeCount(eventType: 'signer_added', count: 7),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZIndexerStats_inequalityWithDifferentField', () {
      const a = OZIndexerStats(
        totalEvents: 1,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 4,
        lastLedger: 5,
        eventTypes: <OZEventTypeCount>[],
      );
      const b = OZIndexerStats(
        totalEvents: 1,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 4,
        lastLedger: 999,
        eventTypes: <OZEventTypeCount>[],
      );
      expect(a == b, isFalse);
    });

    test('testOZEventTypeCount_equalityWithIdenticalFields', () {
      const a = OZEventTypeCount(eventType: 'signer_added', count: 7);
      const b = OZEventTypeCount(eventType: 'signer_added', count: 7);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZEventTypeCount_inequalityWithDifferentField', () {
      const a = OZEventTypeCount(eventType: 'signer_added', count: 7);
      const b = OZEventTypeCount(eventType: 'policy_added', count: 7);
      expect(a == b, isFalse);
    });

    test('testOZIndexerHealthCheckResponse_equalityWithIdenticalFields', () {
      const a = OZIndexerHealthCheckResponse(status: 'ok');
      const b = OZIndexerHealthCheckResponse(status: 'ok');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('testOZIndexerHealthCheckResponse_inequalityWithDifferentField', () {
      const a = OZIndexerHealthCheckResponse(status: 'ok');
      const b = OZIndexerHealthCheckResponse(status: 'fail');
      expect(a == b, isFalse);
    });
  });

  group('OZIndexerClient - DTO toJson', () {
    test('OZCredentialLookupResponse_toJson', () {
      const r = OZCredentialLookupResponse(
        credentialId: 'cred-1',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      final json = r.toJson();
      expect(json['credentialId'], equals('cred-1'));
      expect(json['count'], equals(0));
      expect(json['contracts'], isEmpty);
    });

    test('OZAddressLookupResponse_toJson', () {
      const r = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      final json = r.toJson();
      expect(json['signerAddress'], equals(_testAccountId));
      expect(json['count'], equals(0));
    });

    test('OZIndexedSigner_toJson', () {
      const signer = OZIndexedSigner(
        signerType: 'Delegated',
        signerAddress: _testAccountId,
      );
      final json = signer.toJson();
      expect(json['signer_type'], equals('Delegated'));
      expect(json['signer_address'], equals(_testAccountId));
      expect(json.containsKey('credential_id'), isFalse);
    });

    test('OZIndexedSigner_toJson_withCredentialId', () {
      // Exercises line 392 (credentialId != null branch).
      const signer = OZIndexedSigner(
        signerType: 'External',
        credentialId: 'cred-hex-123',
      );
      final json = signer.toJson();
      expect(json['signer_type'], equals('External'));
      expect(json['credential_id'], equals('cred-hex-123'));
      expect(json.containsKey('signer_address'), isFalse);
    });

    test('OZIndexedPolicy_toJson', () {
      const policy = OZIndexedPolicy(policyAddress: _testContractId);
      final json = policy.toJson();
      expect(json['policy_address'], equals(_testContractId));
    });

    test('OZIndexedPolicy_toJson_withInstallParams', () {
      // Exercises line 445 (installParams != null branch).
      const policy = OZIndexedPolicy(
        policyAddress: _testContractId,
        installParams: <String, dynamic>{'key': 'value'},
      );
      final json = policy.toJson();
      expect(json['policy_address'], equals(_testContractId));
      expect(json['install_params'], isNotNull);
    });

    test('OZIndexerStatsResponse_toJson', () {
      // Exercises lines 479-480.
      const stats = OZIndexerStats(
        totalEvents: 1,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 100,
        lastLedger: 200,
        eventTypes: <OZEventTypeCount>[],
      );
      const r = OZIndexerStatsResponse(stats: stats);
      final json = r.toJson();
      expect(json['stats'], isNotNull);
    });

    test('OZIndexedContextRule_toJson', () {
      const rule = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[],
        policies: <OZIndexedPolicy>[],
      );
      final json = rule.toJson();
      expect(json['context_rule_id'], equals(0));
      expect(json['signers'], isEmpty);
    });

    test('OZIndexedContractSummary_toJson', () {
      const summary = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 2,
        externalSignerCount: 1,
        delegatedSignerCount: 0,
        nativeSignerCount: 0,
        firstSeenLedger: 100,
        lastSeenLedger: 200,
        contextRuleIds: <int>[0, 1],
      );
      final json = summary.toJson();
      expect(json['contract_id'], equals(_testContractId));
      expect(json['context_rule_count'], equals(2));
    });

    test('OZContractDetailsResponse_toJson', () {
      const summary = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 0,
        externalSignerCount: 0,
        delegatedSignerCount: 0,
        nativeSignerCount: 0,
        firstSeenLedger: 0,
        lastSeenLedger: 0,
        contextRuleIds: <int>[],
      );
      const r = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: summary,
        contextRules: <OZIndexedContextRule>[],
      );
      final json = r.toJson();
      expect(json['contractId'], equals(_testContractId));
    });

    test('OZCredentialLookupResponse_equalityWithNonConstInstances', () {
      // Use non-const (mutable) instances so identical() returns false.
      final a = OZCredentialLookupResponse(
        credentialId: 'cred-x',
        contracts: const <OZIndexedContractSummary>[],
        count: 5,
      );
      final b = OZCredentialLookupResponse(
        credentialId: 'cred-x',
        contracts: const <OZIndexedContractSummary>[],
        count: 5,
      );
      final c = OZCredentialLookupResponse(
        credentialId: 'cred-y',
        contracts: const <OZIndexedContractSummary>[],
        count: 5,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZContractDetailsResponse_equalityWithNonConstInstances', () {
      const summary = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 0,
        externalSignerCount: 0,
        delegatedSignerCount: 0,
        nativeSignerCount: 0,
        firstSeenLedger: 0,
        lastSeenLedger: 0,
        contextRuleIds: <int>[],
      );
      final a = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: summary,
        contextRules: const <OZIndexedContextRule>[],
      );
      final b = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: summary,
        contextRules: const <OZIndexedContextRule>[],
      );
      final c = OZContractDetailsResponse(
        contractId: _testAccountId, // different
        summary: summary,
        contextRules: const <OZIndexedContextRule>[],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZIndexedContextRule_equalityWithNonConstInstances', () {
      // Non-const so deepEquality path executes.
      final a = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[const OZIndexedSigner(signerType: 'Delegated')],
        policies: <OZIndexedPolicy>[],
      );
      final b = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[const OZIndexedSigner(signerType: 'Delegated')],
        policies: <OZIndexedPolicy>[],
      );
      final c = OZIndexedContextRule(
        contextRuleId: 1,
        signers: <OZIndexedSigner>[],
        policies: <OZIndexedPolicy>[],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZIndexedSigner_equalityWithNonConstInstances', () {
      final a = OZIndexedSigner(signerType: 'Delegated', signerAddress: _testAccountId);
      final b = OZIndexedSigner(signerType: 'Delegated', signerAddress: _testAccountId);
      final c = OZIndexedSigner(signerType: 'External', credentialId: 'abc');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZAddressLookupResponse_equalityWithNonConstInstances', () {
      final a = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: const <OZIndexedContractSummary>[],
        count: 3,
      );
      final b = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: const <OZIndexedContractSummary>[],
        count: 3,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('OZIndexerClient - response DTO equality and hashCode', () {
    test('OZCredentialLookupResponse_equality', () {
      const a = OZCredentialLookupResponse(
        credentialId: 'cred-1',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const b = OZCredentialLookupResponse(
        credentialId: 'cred-1',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const c = OZCredentialLookupResponse(
        credentialId: 'cred-2',
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZAddressLookupResponse_equality', () {
      const a = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const b = OZAddressLookupResponse(
        signerAddress: _testAccountId,
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      const c = OZAddressLookupResponse(
        signerAddress: _testContractId,
        contracts: <OZIndexedContractSummary>[],
        count: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZIndexedContractSummary_equality', () {
      const a = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 1,
        externalSignerCount: 0,
        delegatedSignerCount: 0,
        nativeSignerCount: 0,
        firstSeenLedger: 100,
        lastSeenLedger: 200,
        contextRuleIds: <int>[0],
      );
      const b = OZIndexedContractSummary(
        contractId: _testContractId,
        contextRuleCount: 1,
        externalSignerCount: 0,
        delegatedSignerCount: 0,
        nativeSignerCount: 0,
        firstSeenLedger: 100,
        lastSeenLedger: 200,
        contextRuleIds: <int>[0],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('OZIndexedContextRule_equality', () {
      const a = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[],
        policies: <OZIndexedPolicy>[],
      );
      const b = OZIndexedContextRule(
        contextRuleId: 0,
        signers: <OZIndexedSigner>[],
        policies: <OZIndexedPolicy>[],
      );
      const c = OZIndexedContextRule(
        contextRuleId: 1,
        signers: <OZIndexedSigner>[],
        policies: <OZIndexedPolicy>[],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZIndexedSigner_equality', () {
      const a = OZIndexedSigner(signerType: 'Delegated', signerAddress: _testAccountId);
      const b = OZIndexedSigner(signerType: 'Delegated', signerAddress: _testAccountId);
      const c = OZIndexedSigner(signerType: 'External', credentialId: 'abc123');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('OZContractDetailsResponse_equality', () {
      const a = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: OZIndexedContractSummary(
          contractId: _testContractId,
          contextRuleCount: 0,
          externalSignerCount: 0,
          delegatedSignerCount: 0,
          nativeSignerCount: 0,
          firstSeenLedger: 0,
          lastSeenLedger: 0,
          contextRuleIds: <int>[],
        ),
        contextRules: <OZIndexedContextRule>[],
      );
      const b = OZContractDetailsResponse(
        contractId: _testContractId,
        summary: OZIndexedContractSummary(
          contractId: _testContractId,
          contextRuleCount: 0,
          externalSignerCount: 0,
          delegatedSignerCount: 0,
          nativeSignerCount: 0,
          firstSeenLedger: 0,
          lastSeenLedger: 0,
          contextRuleIds: <int>[],
        ),
        contextRules: <OZIndexedContextRule>[],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('OZIndexerStatsResponse_equality', () {
      const stats1 = OZIndexerStats(
        totalEvents: 10,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 100,
        lastLedger: 200,
        eventTypes: <OZEventTypeCount>[],
      );
      const stats2 = OZIndexerStats(
        totalEvents: 10,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 100,
        lastLedger: 200,
        eventTypes: <OZEventTypeCount>[],
      );
      const stats3 = OZIndexerStats(
        totalEvents: 99,
        uniqueContracts: 2,
        uniqueCredentials: 3,
        firstLedger: 100,
        lastLedger: 200,
        eventTypes: <OZEventTypeCount>[],
      );
      const a = OZIndexerStatsResponse(stats: stats1);
      const b = OZIndexerStatsResponse(stats: stats2);
      const c = OZIndexerStatsResponse(stats: stats3);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });
  });

  group('OZIndexerClient - HTTP error responses', () {
    test('lookupByCredentialId_404_throwsIndexerRequestFailed', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error":"not found"}',
        statusCode: 404,
      );
      final client = _client(adapter);
      // Use a valid base64url credential id (no padding, URL-safe alphabet).
      const credId = 'aGVsbG8tc21hcnQtYWNjb3VudA';

      await expectLater(
        client.lookupByCredentialId(credId),
        throwsA(isA<IndexerRequestFailed>()),
      );
      await client.close();
    });

    test('lookupByCredentialId_malformedJson_throwsIndexerRequestFailed', () async {
      final adapter = MockDioAdapter.json('{bad json{{');
      final client = _client(adapter);
      const credId = 'aGVsbG8tc21hcnQtYWNjb3VudA';

      await expectLater(
        client.lookupByCredentialId(credId),
        throwsA(isA<IndexerRequestFailed>()),
      );
      await client.close();
    });

    test('lookupByAddress_500_throwsIndexerRequestFailed', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error":"server error"}',
        statusCode: 500,
      );
      final client = _client(adapter);

      await expectLater(
        client.lookupByAddress(_testAccountId),
        throwsA(isA<IndexerRequestFailed>()),
      );
      await client.close();
    });

    test('getContract_404_throwsIndexerRequestFailed', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{"error":"not found"}',
        statusCode: 404,
      );
      final client = _client(adapter);

      await expectLater(
        client.getContract(_testContractId),
        throwsA(isA<IndexerRequestFailed>()),
      );
      await client.close();
    });

    test('getStats_500_throwsIndexerRequestFailed', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '{}',
        statusCode: 500,
      );
      final client = _client(adapter);

      await expectLater(
        client.getStats(),
        throwsA(isA<IndexerRequestFailed>()),
      );
      await client.close();
    });

    test('getDefaultUrl_unknownPassphrase_returnsNull', () {
      const unknownPassphrase = 'Unknown Network ; January 2099';
      final url = OZIndexerClient.getDefaultUrl(unknownPassphrase);
      expect(url, isNull);
    });

    test('getDefaultUrl_testnetPassphrase_returnsNonNull', () {
      const testnetPassphrase = 'Test SDF Network ; September 2015';
      final url = OZIndexerClient.getDefaultUrl(testnetPassphrase);
      expect(url, isNotNull);
    });

    test('network_dioException_throwsIndexerRequestFailed', () async {
      final adapter = MockDioAdapter.throwing(
        dio.DioException(
          requestOptions: dio.RequestOptions(path: '/'),
          type: dio.DioExceptionType.connectionError,
          message: 'connection refused',
        ),
      );
      final client = _client(adapter);
      const credId = 'aGVsbG8tc21hcnQtYWNjb3VudA';

      await expectLater(
        client.lookupByCredentialId(credId),
        throwsA(isA<IndexerRequestFailed>()),
      );
      await client.close();
    });

    test('lookupByCredentialId_nonJsonContentType_throwsIndexerRequestFailed', () async {
      final adapter = MockDioAdapter.response(
        responseBody: '<html>Error</html>',
        statusCode: 200,
        contentType: 'text/html',
      );
      final client = _client(adapter);
      const credId = 'aGVsbG8tc21hcnQtYWNjb3VudA';

      await expectLater(
        client.lookupByCredentialId(credId),
        throwsA(isA<IndexerRequestFailed>()),
      );
      await client.close();
    });
  });
}
