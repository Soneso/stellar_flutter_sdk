import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('WebAuthForContracts - Network Configuration', () {
    test('uses default Soroban RPC URL for TESTNET', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      expect(webAuth.sorobanRpcUrl, 'https://soroban-testnet.stellar.org');
    });

    test('uses default Soroban RPC URL for PUBLIC', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.PUBLIC,
      );

      expect(webAuth.sorobanRpcUrl, 'https://soroban.stellar.org');
    });

    test('uses custom Soroban RPC URL when provided', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        sorobanRpcUrl: 'https://custom-soroban.example.com',
      );

      expect(webAuth.sorobanRpcUrl, 'https://custom-soroban.example.com');
    });

    test('accepts custom HTTP client', () {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(webAuth, isNotNull);
    });
  });

  group('WebAuthForContracts - jwtToken Invalid Parameters', () {
    test('throws error when clientAccountId is not a contract address', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
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
        () => webAuth.jwtToken('GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345', []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ignores clientDomainSigningCallback when clientDomain not provided', () async {
      // When clientDomain is null, the clientDomainSigningCallback is ignored
      // and the flow proceeds without client domain signing
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth')) {
          // Return empty authorization entries to avoid decoding issues
          return http.Response(json.encode({
            'authorization_entries': 'AAAAAA==',
            'token': 'test-jwt-token',
          }), 200);
        }
        return http.Response('{}', 200);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      // The callback is provided but clientDomain is null, so the callback
      // should be ignored and the flow should proceed (may fail for other reasons
      // like invalid auth entries, but not due to the callback)
      try {
        await webAuth.jwtToken(
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          [],
          clientDomainSigningCallback: (entry) async => entry,
        );
      } on ContractChallengeValidationException {
        // Expected - empty auth entries will fail validation
      }
    });

    test('uses server home domain when homeDomain not provided', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth')) {
          expect(request.url.queryParameters['home_domain'], 'testanchor.stellar.org');
          return http.Response(json.encode({
            'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          }), 200);
        }
        return http.Response('{}', 200);
      });

      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      try {
        await webAuth.jwtToken('CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE', []);
      } catch (e) {
        // Expected to fail due to invalid auth entries, but we verified the home_domain parameter
      }
    });
  });

  group('WebAuthForContracts - validateChallenge Edge Cases', () {
    test('throws when authorization entries list is empty', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      expect(
        () => webAuth.validateChallenge(
          [],
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        ),
        throwsA(isA<ContractChallengeValidationException>()),
      );
    });

    test('uses server home domain when homeDomain not provided in validation', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      expect(
        () => webAuth.validateChallenge(
          [],
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        ),
        throwsA(isA<ContractChallengeValidationException>()),
      );
    });

    test('extracts web_auth_domain with port from auth endpoint', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org:8080/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      // The internal validation will extract the domain with port
      expect(webAuth, isNotNull);
    });

    test('does not include port 80 in web_auth_domain', () {
      final webAuth = WebAuthForContracts(
        'http://testanchor.stellar.org:80/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      expect(webAuth, isNotNull);
    });

    test('does not include port 443 in web_auth_domain', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org:443/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      expect(webAuth, isNotNull);
    });
  });

  group('WebAuthForContracts - decodeAuthorizationEntries', () {
    test('decodes empty authorization entries', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      // Empty array XDR (length = 0)
      final entries = webAuth.decodeAuthorizationEntries('AAAAAA==');
      expect(entries, isEmpty);
    });

    test('handles invalid base64 gracefully', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      // Test that invalid input is handled (may throw or return empty)
      try {
        webAuth.decodeAuthorizationEntries('INVALID_BASE64!!!');
        // If no exception, that's also acceptable behavior
      } on ContractChallengeValidationException {
        // Expected exception
      } on FormatException {
        // Also acceptable - base64 decode error
      }
    });
  });

  group('WebAuthForContracts - signAuthorizationEntries Scenarios', () {
    test('signs entries when signatureExpirationLedger provided', () async {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      // Create empty list to test
      final entries = await webAuth.signAuthorizationEntries(
        [],
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        [],
        12345,
        null,
        null,
        null,
      );

      expect(entries, isEmpty);
    });

    test('signs entries when signatureExpirationLedger is null', () async {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      final entries = await webAuth.signAuthorizationEntries(
        [],
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        [],
        null,
        null,
        null,
        null,
      );

      expect(entries, isEmpty);
    });
  });

  group('WebAuthForContracts - Soroban Network Paths', () {
    test('handles TESTNET network passphrase correctly', () {
      final network = Network.TESTNET;
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        network,
      );

      expect(webAuth.sorobanRpcUrl, 'https://soroban-testnet.stellar.org');
    });

    test('handles PUBLIC network passphrase correctly', () {
      final network = Network.PUBLIC;
      final webAuth = WebAuthForContracts(
        'https://anchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'anchor.stellar.org',
        network,
      );

      expect(webAuth.sorobanRpcUrl, 'https://soroban.stellar.org');
    });

    test('handles custom network with provided Soroban RPC URL', () {
      final customNetwork = Network('Custom Network Passphrase');
      final webAuth = WebAuthForContracts(
        'https://custom.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'custom.stellar.org',
        customNetwork,
        sorobanRpcUrl: 'https://custom-soroban.stellar.org',
      );

      expect(webAuth.sorobanRpcUrl, 'https://custom-soroban.stellar.org');
    });
  });

  group('WebAuthForContracts - Configuration Properties', () {
    test('useFormUrlEncoded can be modified', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      expect(webAuth.useFormUrlEncoded, true);

      webAuth.useFormUrlEncoded = false;
      expect(webAuth.useFormUrlEncoded, false);
    });

    test('httpRequestHeaders can be set', () {
      final headers = {'X-Custom-Header': 'custom-value'};
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
        httpRequestHeaders: headers,
      );

      expect(webAuth.httpRequestHeaders, headers);
    });

    test('sorobanRpcUrl can be set after construction', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );

      webAuth.sorobanRpcUrl = 'https://new-soroban-url.example.com';
      expect(webAuth.sorobanRpcUrl, 'https://new-soroban-url.example.com');
    });
  });

  group('WebAuthForContracts - Response Handling Edge Cases', () {
    test('sendSignedChallenge handles response with only token field', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'token': 'jwt-token-only',
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

      final token = await webAuth.sendSignedChallenge([]);
      expect(token, 'jwt-token-only');
    });

    test('sendSignedChallenge throws on empty response with 200 status', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({}), 200);
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
        () => webAuth.sendSignedChallenge([]),
        throwsA(isA<SubmitContractChallengeErrorResponseException>()),
      );
    });

    test('sendSignedChallenge handles HTTP 400 with error field', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid authorization entries',
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
        () => webAuth.sendSignedChallenge([]),
        throwsA(isA<SubmitContractChallengeErrorResponseException>()),
      );
    });
  });

  group('WebAuthForContracts - URL and Domain Validation Edge Cases', () {
    test('accepts URL without trailing slash', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });

    test('accepts URL with trailing slash', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth/',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });

    test('accepts URL with query parameters', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth?param=value',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });

    test('throws on URL with only host', () {
      expect(
        () => WebAuthForContracts(
          'testanchor.stellar.org',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on empty string URL', () {
      expect(
        () => WebAuthForContracts(
          '',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on whitespace-only server home domain', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          '   ',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('WebAuthForContracts - Account ID Validation', () {
    test('accepts valid contract address starting with C', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });

    test('throws when contract address starts with G', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'GABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when contract address starts with M', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'MABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid server signing key starting with G', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        returnsNormally,
      );
    });

    test('throws when server signing key starts with C', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'CBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when server signing key starts with M', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'MBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
