import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('WebAuthForContracts - jwtToken with Client Domain', () {
    test('throws exception when client account is not a contract address', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 200);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.jwtToken(
          'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('WebAuthForContracts - Constructor with Port in URL', () {
    test('accepts auth endpoint with non-standard port', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org:8080/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });

    test('accepts auth endpoint with standard HTTPS port (443)', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org:443/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });

    test('accepts auth endpoint with standard HTTP port (80)', () {
      expect(
        () => WebAuthForContracts(
          'http://testanchor.stellar.org:80/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });
  });

  group('WebAuthForContracts - useFormUrlEncoded Configuration', () {
    test('allows setting useFormUrlEncoded to false', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      webAuth.useFormUrlEncoded = false;
      expect(webAuth.useFormUrlEncoded, false);
    });

    test('defaults to true for useFormUrlEncoded', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      expect(webAuth.useFormUrlEncoded, true);
    });
  });

  group('WebAuthForContracts - Exception Classes Coverage', () {
    test('ContractChallengeRequestErrorResponse includes statusCode accessor', () {
      final exception = ContractChallengeRequestErrorResponse(
        'Test error',
        statusCode: 403,
      );

      expect(exception.statusCode, 403);
      expect(exception.message, 'Test error');
    });

    test('ContractChallengeRequestErrorResponse without status code', () {
      final exception = ContractChallengeRequestErrorResponse('Network error');

      expect(exception.statusCode, isNull);
      expect(exception.toString(), contains('Network error'));
    });

    test('MissingClientDomainForContractAuthException message', () {
      final exception = MissingClientDomainForContractAuthException();
      expect(exception.toString(), contains('clientDomain'));
      expect(exception.toString(), contains('required'));
    });
  });

  group('WebAuthForContracts - Default Home Domain', () {
    test('uses server home domain when homeDomain parameter not provided in getChallenge', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['home_domain'], 'testanchor.stellar.org');

        return http.Response(json.encode({
          'authorization_entries': base64Encode(Uint8List(10)),
        }), 200);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      await webAuth.getChallenge(
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
      );
    });
  });

  group('WebAuthForContracts - HTTP Error Handling', () {
    test('wraps network errors in ContractChallengeRequestErrorResponse', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network connection failed');
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.getChallenge(
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        ),
        throwsA(isA<ContractChallengeRequestErrorResponse>()),
      );
    });

    test('preserves ContractChallengeRequestErrorResponse when already thrown', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid parameters'
        }), 400);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.getChallenge(
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        ),
        throwsA(isA<ContractChallengeRequestErrorResponse>()),
      );
    });
  });

  group('WebAuthForContracts - Response JSON Parsing', () {
    test('throws exception when response cannot be parsed as JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('INVALID JSON{', 200);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.getChallenge(
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        ),
        throwsA(isA<ContractChallengeRequestErrorResponse>()),
      );
    });
  });

  group('WebAuthForContracts - Network Passphrase Validation', () {
    test('throws ContractChallengeValidationErrorInvalidNetworkPassphrase when network mismatch', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(json.encode({
            'authorization_entries': base64Encode(Uint8List.fromList([0, 0, 0, 0])),
            'network_passphrase': 'Public Global Stellar Network ; September 2015',
          }), 200);
        }
        return http.Response('', 404);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      await expectLater(
        webAuth.jwtToken(
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          [],
        ),
        throwsA(isA<ContractChallengeValidationErrorInvalidNetworkPassphrase>()),
      );
    });
  });
}
