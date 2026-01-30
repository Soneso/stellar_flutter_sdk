import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('WebAuth - fromDomain Integration', () {
    test('creates WebAuth instance from domain with valid stellar.toml', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
WEB_AUTH_ENDPOINT="https://testanchor.stellar.org/auth"
SIGNING_KEY="GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final webAuth = await WebAuth.fromDomain(
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(webAuth, isNotNull);
    });

    test('throws NoWebAuthEndpointFoundException when WEB_AUTH_ENDPOINT missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
SIGNING_KEY="GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"
        ''', 200);
      });

      expect(
        () => WebAuth.fromDomain(
          'testanchor.stellar.org',
          Network.TESTNET,
          httpClient: mockClient,
        ),
        throwsA(isA<NoWebAuthEndpointFoundException>()),
      );
    });

    test('throws NoWebAuthServerSigningKeyFoundException when SIGNING_KEY missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
WEB_AUTH_ENDPOINT="https://testanchor.stellar.org/auth"
        ''', 200);
      });

      expect(
        () => WebAuth.fromDomain(
          'testanchor.stellar.org',
          Network.TESTNET,
          httpClient: mockClient,
        ),
        throwsA(isA<NoWebAuthServerSigningKeyFoundException>()),
      );
    });

    test('passes custom headers to stellar.toml request', () async {
      final customHeaders = {
        'X-Custom-Header': 'test-value',
        'Authorization': 'Bearer token123',
      };

      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'test-value');
        expect(request.headers['Authorization'], 'Bearer token123');

        return http.Response('''
WEB_AUTH_ENDPOINT="https://testanchor.stellar.org/auth"
SIGNING_KEY="GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"
        ''', 200);
      });

      await WebAuth.fromDomain(
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
        httpRequestHeaders: customHeaders,
      );
    });
  });

  group('WebAuth - getChallengeResponse', () {
    test('returns challenge response with transaction and network passphrase', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.queryParameters['account'], startsWith('G'));

        return http.Response(json.encode({
          'transaction': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          'network_passphrase': 'Test SDF Network ; September 2015',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      final response = await webAuth.getChallengeResponse(
        'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
      );

      expect(response.transaction, isNotNull);
      expect(response.networkPassphrase, 'Test SDF Network ; September 2015');
    });

    test('includes memo parameter when provided', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['memo'], '12345');

        return http.Response(json.encode({
          'transaction': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      await webAuth.getChallengeResponse(
        'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        12345,
      );
    });

    test('includes home_domain parameter when provided', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['home_domain'], 'custom.example.com');

        return http.Response(json.encode({
          'transaction': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      await webAuth.getChallengeResponse(
        'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        null,
        'custom.example.com',
      );
    });

    test('includes client_domain parameter when provided', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['client_domain'], 'wallet.example.com');

        return http.Response(json.encode({
          'transaction': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      await webAuth.getChallengeResponse(
        'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        null,
        null,
        'wallet.example.com',
      );
    });

    test('throws NoMemoForMuxedAccountsException when memo provided for muxed account', () async {
      final serverKeyPair = KeyPair.random();
      final clientKeyPair = KeyPair.random();
      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
      );

      final muxedAccount = MuxedAccount(
        clientKeyPair.accountId,
        BigInt.from(12345),
      );

      expect(
        () => webAuth.getChallengeResponse(
          muxedAccount.accountId,
          12345,
        ),
        throwsA(isA<NoMemoForMuxedAccountsException>()),
      );
    });

    test('throws ChallengeRequestErrorResponse on HTTP error', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid account parameter'
        }), 400);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      expect(
        () => webAuth.getChallengeResponse(
          'INVALID_ACCOUNT',
        ),
        throwsA(isA<ChallengeRequestErrorResponse>()),
      );
    });

    test('passes custom headers in request', () async {
      final serverKeyPair = KeyPair.random();
      final customHeaders = {
        'Authorization': 'Bearer token123',
        'X-API-Version': '2.0',
      };

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token123');
        expect(request.headers['X-API-Version'], '2.0');

        return http.Response(json.encode({
          'transaction': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
        httpRequestHeaders: customHeaders,
      );

      await webAuth.getChallengeResponse(
        'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
      );
    });
  });

  group('WebAuth - getChallenge', () {
    test('returns transaction XDR from challenge response', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'transaction': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          'network_passphrase': 'Test SDF Network ; September 2015',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      final transaction = await webAuth.getChallenge(
        'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
      );

      expect(transaction, 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=');
    });

    test('throws MissingTransactionInChallengeResponseException when transaction missing', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'network_passphrase': 'Test SDF Network ; September 2015',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      expect(
        () => webAuth.getChallenge(
          'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        ),
        throwsA(isA<MissingTransactionInChallengeResponseException>()),
      );
    });
  });

  group('WebAuth - sendSignedChallengeTransaction', () {
    test('successfully submits signed challenge and returns JWT token', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], 'application/json');

        final body = json.decode(request.body);
        expect(body['transaction'], isNotNull);

        return http.Response(json.encode({
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      final token = await webAuth.sendSignedChallengeTransaction(
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      );

      expect(token, startsWith('eyJ'));
    });

    test('throws SubmitCompletedChallengeErrorResponseException on HTTP 400 with error', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid signature',
        }), 400);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      expect(
        () => webAuth.sendSignedChallengeTransaction(
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        ),
        throwsA(isA<SubmitCompletedChallengeErrorResponseException>()),
      );
    });

    test('throws SubmitCompletedChallengeTimeoutResponseException on HTTP 504', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        return http.Response('Gateway Timeout', 504);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      expect(
        () => webAuth.sendSignedChallengeTransaction(
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        ),
        throwsA(isA<SubmitCompletedChallengeTimeoutResponseException>()),
      );
    });

    test('throws SubmitCompletedChallengeUnknownResponseException on unknown HTTP status', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      expect(
        () => webAuth.sendSignedChallengeTransaction(
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        ),
        throwsA(isA<SubmitCompletedChallengeUnknownResponseException>()),
      );
    });

    test('throws SubmitCompletedChallengeErrorResponseException when error field present without token', () async {
      final serverKeyPair = KeyPair.random();
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Challenge expired',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
      );

      expect(
        () => webAuth.sendSignedChallengeTransaction(
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        ),
        throwsA(isA<SubmitCompletedChallengeErrorResponseException>()),
      );
    });

    test('passes custom headers in request', () async {
      final serverKeyPair = KeyPair.random();
      final customHeaders = {
        'X-Custom-Header': 'test-value',
      };

      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'test-value');

        return http.Response(json.encode({
          'token': 'jwt-token-here',
        }), 200);
      });

      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
        httpClient: mockClient,
        httpRequestHeaders: customHeaders,
      );

      await webAuth.sendSignedChallengeTransaction(
        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      );
    });
  });

  group('WebAuth - Exception Message Formatting', () {
    test('ChallengeRequestErrorResponse formats correctly', () {
      final exception = ChallengeRequestErrorResponse(
        http.Response(json.encode({'error': 'test error'}), 401),
      );

      expect(exception.toString(), contains('401'));
    });

    test('NoWebAuthEndpointFoundException includes domain', () {
      final exception = NoWebAuthEndpointFoundException('testanchor.stellar.org');

      expect(exception.domain, 'testanchor.stellar.org');
      expect(exception.toString(), contains('testanchor.stellar.org'));
      expect(exception.toString(), contains('WEB_AUTH_ENDPOINT'));
    });

    test('NoWebAuthServerSigningKeyFoundException includes domain', () {
      final exception = NoWebAuthServerSigningKeyFoundException('testanchor.stellar.org');

      expect(exception.domain, 'testanchor.stellar.org');
      expect(exception.toString(), contains('testanchor.stellar.org'));
      expect(exception.toString(), contains('SIGNING_KEY'));
    });

    test('NoClientDomainSigningKeyFoundException includes domain', () {
      final exception = NoClientDomainSigningKeyFoundException('wallet.example.com');

      expect(exception.domain, 'wallet.example.com');
      expect(exception.toString(), contains('wallet.example.com'));
      expect(exception.toString(), contains('SIGNING_KEY'));
    });

    test('SubmitCompletedChallengeUnknownResponseException includes code and body', () {
      final exception = SubmitCompletedChallengeUnknownResponseException(
        503,
        'Service Unavailable',
      );

      expect(exception.code, 503);
      expect(exception.body, 'Service Unavailable');
      expect(exception.toString(), contains('503'));
      expect(exception.toString(), contains('Service Unavailable'));
    });

    test('SubmitCompletedChallengeErrorResponseException includes error message', () {
      final exception = SubmitCompletedChallengeErrorResponseException('Signature verification failed');

      expect(exception.error, 'Signature verification failed');
      expect(exception.toString(), contains('Signature verification failed'));
    });
  });

  group('WebAuth - Grace Period', () {
    test('allows setting custom grace period', () {
      final serverKeyPair = KeyPair.random();
      final webAuth = WebAuth(
        'https://testanchor.stellar.org/auth',
        Network.TESTNET,
        serverKeyPair.accountId,
        'testanchor.stellar.org',
      );

      webAuth.gracePeriod = 600;
      expect(webAuth.gracePeriod, 600);
    });
  });
}
