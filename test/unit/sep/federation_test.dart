import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
  group('Federation - resolveStellarAddress', () {
    test('resolves valid stellar address', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        if (request.url.toString().contains('/federation')) {
          expect(request.url.queryParameters['q'], equals('bob*example.com'));
          expect(request.url.queryParameters['type'], equals('name'));
          return http.Response(
            json.encode({
              'stellar_address': 'bob*example.com',
              'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final response = await Federation.resolveStellarAddress(
        'bob*example.com',
        httpClient: mockClient,
      );

      expect(response.stellarAddress, equals('bob*example.com'));
      expect(response.accountId, equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
    });

    test('resolves address with memo', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        if (request.url.toString().contains('/federation')) {
          return http.Response(
            json.encode({
              'stellar_address': 'alice*example.com',
              'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
              'memo_type': 'id',
              'memo': '12345',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final response = await Federation.resolveStellarAddress(
        'alice*example.com',
        httpClient: mockClient,
      );

      expect(response.accountId, isNotNull);
      expect(response.memoType, equals('id'));
      expect(response.memo, equals('12345'));
    });

    test('resolves address with text memo', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        if (request.url.toString().contains('/federation')) {
          return http.Response(
            json.encode({
              'stellar_address': 'user*example.com',
              'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
              'memo_type': 'text',
              'memo': 'payment reference',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final response = await Federation.resolveStellarAddress(
        'user*example.com',
        httpClient: mockClient,
      );

      expect(response.memoType, equals('text'));
      expect(response.memo, equals('payment reference'));
    });

    test('resolves address with hash memo', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        if (request.url.toString().contains('/federation')) {
          return http.Response(
            json.encode({
              'stellar_address': 'user*example.com',
              'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
              'memo_type': 'hash',
              'memo': 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final response = await Federation.resolveStellarAddress(
        'user*example.com',
        httpClient: mockClient,
      );

      expect(response.memoType, equals('hash'));
      expect(response.memo, isNotNull);
    });

    test('throws exception for invalid address format', () async {
      expect(
        () => Federation.resolveStellarAddress('invalid-address'),
        throwsException,
      );
    });

    test('throws exception for missing address separator', () async {
      expect(
        () => Federation.resolveStellarAddress('bob.example.com'),
        throwsException,
      );
    });

    test('throws exception when no federation server found', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response('', 200);
        }
        return http.Response('Not found', 404);
      });

      expect(
        () => Federation.resolveStellarAddress(
          'bob*example.com',
          httpClient: mockClient,
        ),
        throwsException,
      );
    });

    test('resolves email-style address', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        if (request.url.toString().contains('/federation')) {
          expect(request.url.queryParameters['q'], contains('@gmail.com*'));
          return http.Response(
            json.encode({
              'stellar_address': 'maria@gmail.com*example.com',
              'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final response = await Federation.resolveStellarAddress(
        'maria@gmail.com*example.com',
        httpClient: mockClient,
      );

      expect(response.accountId, isNotNull);
    });

    test('resolves phone number address', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        if (request.url.toString().contains('/federation')) {
          expect(request.url.queryParameters['q'], contains('+14155550100*'));
          return http.Response(
            json.encode({
              'stellar_address': '+14155550100*example.com',
              'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final response = await Federation.resolveStellarAddress(
        '+14155550100*example.com',
        httpClient: mockClient,
      );

      expect(response.accountId, isNotNull);
    });

    test('handles address with multiple domain parts', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        if (request.url.toString().contains('/federation')) {
          return http.Response(
            json.encode({
              'stellar_address': 'user*subdomain.example.com',
              'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final response = await Federation.resolveStellarAddress(
        'user*subdomain.example.com',
        httpClient: mockClient,
      );

      expect(response.accountId, isNotNull);
    });
  });

  group('Federation - resolveStellarAccountId', () {
    test('resolves account id to stellar address', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['q'], equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
        expect(request.url.queryParameters['type'], equals('id'));
        return http.Response(
          json.encode({
            'stellar_address': 'bob*example.com',
            'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
          }),
          200,
        );
      });

      final response = await Federation.resolveStellarAccountId(
        'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
        'https://api.example.com/federation',
        httpClient: mockClient,
      );

      expect(response.stellarAddress, equals('bob*example.com'));
      expect(response.accountId, equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
    });

    test('handles account id with special characters in response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'stellar_address': 'alice*example.com',
            'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
          }),
          200,
        );
      });

      final response = await Federation.resolveStellarAccountId(
        'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
        'https://api.example.com/federation',
        httpClient: mockClient,
      );

      expect(response.stellarAddress, isNotNull);
    });
  });

  group('Federation - resolveStellarTransactionId', () {
    test('resolves transaction id to stellar address', () async {
      final mockClient = MockClient((request) async {
        final txId = 'c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a';
        expect(request.url.queryParameters['q'], equals(txId));
        expect(request.url.queryParameters['type'], equals('txid'));
        return http.Response(
          json.encode({
            'stellar_address': 'sender*example.com',
            'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
          }),
          200,
        );
      });

      final response = await Federation.resolveStellarTransactionId(
        'c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a',
        'https://api.example.com/federation',
        httpClient: mockClient,
      );

      expect(response.stellarAddress, equals('sender*example.com'));
    });

    test('handles different transaction id formats', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'stellar_address': 'sender*example.com',
            'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
          }),
          200,
        );
      });

      final response = await Federation.resolveStellarTransactionId(
        'abc123def456',
        'https://api.example.com/federation',
        httpClient: mockClient,
      );

      expect(response.stellarAddress, isNotNull);
    });
  });

  group('Federation - resolveForward', () {
    test('performs forward federation lookup', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['type'], equals('forward'));
        expect(request.url.queryParameters['forward_type'], equals('bank_account'));
        expect(request.url.queryParameters['swift'], equals('BOPBPHMM'));
        expect(request.url.queryParameters['acct'], equals('2382376'));
        return http.Response(
          json.encode({
            'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
            'memo_type': 'id',
            'memo': '54321',
          }),
          200,
        );
      });

      final response = await Federation.resolveForward(
        {
          'forward_type': 'bank_account',
          'swift': 'BOPBPHMM',
          'acct': '2382376',
        },
        'https://api.example.com/federation',
        httpClient: mockClient,
      );

      expect(response.accountId, equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
      expect(response.memoType, equals('id'));
      expect(response.memo, equals('54321'));
    });

    test('handles forward request with minimal parameters', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
          }),
          200,
        );
      });

      final response = await Federation.resolveForward(
        {'forward_type': 'bank_account'},
        'https://api.example.com/federation',
        httpClient: mockClient,
      );

      expect(response.accountId, isNotNull);
    });
  });

  group('FederationResponse', () {
    test('fromJson creates response with all fields', () {
      final json = {
        'stellar_address': 'bob*example.com',
        'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
        'memo_type': 'id',
        'memo': '12345',
      };

      final response = FederationResponse.fromJson(json);

      expect(response.stellarAddress, equals('bob*example.com'));
      expect(response.accountId, equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
      expect(response.memoType, equals('id'));
      expect(response.memo, equals('12345'));
    });

    test('fromJson handles null memo fields', () {
      final json = {
        'stellar_address': 'alice*example.com',
        'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
      };

      final response = FederationResponse.fromJson(json);

      expect(response.stellarAddress, equals('alice*example.com'));
      expect(response.accountId, isNotNull);
      expect(response.memoType, isNull);
      expect(response.memo, isNull);
    });

    test('fromJson handles null stellar address', () {
      final json = {
        'account_id': 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
        'memo_type': 'id',
        'memo': '99999',
      };

      final response = FederationResponse.fromJson(json);

      expect(response.stellarAddress, isNull);
      expect(response.accountId, isNotNull);
      expect(response.memoType, equals('id'));
      expect(response.memo, equals('99999'));
    });

    test('creates response with constructor', () {
      final response = FederationResponse(
        'test*example.com',
        'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP',
        'text',
        'test memo',
      );

      expect(response.stellarAddress, equals('test*example.com'));
      expect(response.accountId, equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
      expect(response.memoType, equals('text'));
      expect(response.memo, equals('test memo'));
    });
  });

  group('Federation Error Handling', () {
    test('handles HTTP 404 error', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      expect(
        () => Federation.resolveStellarAddress(
          'unknown*example.com',
          httpClient: mockClient,
        ),
        throwsException,
      );
    });

    test('handles HTTP 500 error', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        return http.Response('Server error', 500);
      });

      expect(
        () => Federation.resolveStellarAddress(
          'bob*example.com',
          httpClient: mockClient,
        ),
        throwsException,
      );
    });

    test('handles malformed JSON response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('.well-known/stellar.toml')) {
          return http.Response(
            'FEDERATION_SERVER="https://api.example.com/federation"',
            200,
          );
        }
        return http.Response('not valid json', 200);
      });

      expect(
        () => Federation.resolveStellarAddress(
          'bob*example.com',
          httpClient: mockClient,
        ),
        throwsException,
      );
    });
  });
}
