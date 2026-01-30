import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('WebAuthForContracts - fromDomain', () {
    test('creates instance from valid stellar.toml', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('.well-known/stellar.toml'));

        return http.Response('''
WEB_AUTH_FOR_CONTRACTS_ENDPOINT="https://testanchor.stellar.org/auth"
WEB_AUTH_CONTRACT_ID="CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE"
SIGNING_KEY="GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"
        ''', 200);
      });

      final webAuth = await WebAuthForContracts.fromDomain(
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(webAuth, isNotNull);
    });

    test('throws NoWebAuthForContractsEndpointFoundException when endpoint missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
WEB_AUTH_CONTRACT_ID="CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE"
SIGNING_KEY="GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"
        ''', 200);
      });

      expect(
        () => WebAuthForContracts.fromDomain(
          'testanchor.stellar.org',
          Network.TESTNET,
          httpClient: mockClient,
        ),
        throwsA(isA<NoWebAuthForContractsEndpointFoundException>()),
      );
    });

    test('throws NoWebAuthContractIdFoundException when contract ID missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
WEB_AUTH_FOR_CONTRACTS_ENDPOINT="https://testanchor.stellar.org/auth"
SIGNING_KEY="GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"
        ''', 200);
      });

      expect(
        () => WebAuthForContracts.fromDomain(
          'testanchor.stellar.org',
          Network.TESTNET,
          httpClient: mockClient,
        ),
        throwsA(isA<NoWebAuthContractIdFoundException>()),
      );
    });

    test('throws exception when signing key missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
WEB_AUTH_FOR_CONTRACTS_ENDPOINT="https://testanchor.stellar.org/auth"
WEB_AUTH_CONTRACT_ID="CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE"
        ''', 200);
      });

      expect(
        () => WebAuthForContracts.fromDomain(
          'testanchor.stellar.org',
          Network.TESTNET,
          httpClient: mockClient,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('passes custom headers to stellar.toml request', () async {
      final customHeaders = {
        'X-Custom-Header': 'custom-value',
        'X-API-Version': '2.0',
      };

      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');
        expect(request.headers['X-API-Version'], '2.0');

        return http.Response('''
WEB_AUTH_FOR_CONTRACTS_ENDPOINT="https://testanchor.stellar.org/auth"
WEB_AUTH_CONTRACT_ID="CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE"
SIGNING_KEY="GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345"
        ''', 200);
      });

      await WebAuthForContracts.fromDomain(
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
        httpRequestHeaders: customHeaders,
      );
    });
  });

  group('WebAuthForContracts - Constructor Validation', () {
    test('throws error for invalid contract address', () {
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

    test('throws error for invalid server signing key', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'MABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws error for invalid auth endpoint URL', () {
      expect(
        () => WebAuthForContracts(
          'not-a-valid-url',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          'testanchor.stellar.org',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws error for empty server home domain', () {
      expect(
        () => WebAuthForContracts(
          'https://testanchor.stellar.org/auth',
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
          'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
          '',
          Network.TESTNET,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid constructor parameters', () {
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
  });

  group('WebAuthForContracts - getChallenge', () {
    late WebAuthForContracts webAuth;
    late String authEndpoint;
    late String webAuthContractId;
    late String serverSigningKey;

    setUp(() {
      authEndpoint = 'https://testanchor.stellar.org/auth';
      webAuthContractId = 'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE';
      serverSigningKey = 'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345';
    });

    test('successfully retrieves challenge with authorization entries', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/auth'));
        expect(request.url.queryParameters['account'], 'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE');
        expect(request.url.queryParameters['home_domain'], 'testanchor.stellar.org');

        return http.Response(json.encode({
          'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          'network_passphrase': 'Test SDF Network ; September 2015',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      final response = await webAuth.getChallenge(
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
      );

      expect(response.authorizationEntries, isNotNull);
      expect(response.networkPassphrase, 'Test SDF Network ; September 2015');
    });

    test('includes home_domain parameter in request', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['home_domain'], 'custom.domain.com');

        return http.Response(json.encode({
          'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      await webAuth.getChallenge(
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        homeDomain: 'custom.domain.com',
      );
    });

    test('includes client_domain parameter when provided', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['client_domain'], 'client.example.com');

        return http.Response(json.encode({
          'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      await webAuth.getChallenge(
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        clientDomain: 'client.example.com',
      );
    });

    test('parses response with snake_case field names', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          'network_passphrase': 'Test SDF Network ; September 2015',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      final response = await webAuth.getChallenge(
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
      );

      expect(response.authorizationEntries, isNotNull);
      expect(response.networkPassphrase, 'Test SDF Network ; September 2015');
    });

    test('parses response with camelCase field names', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'authorizationEntries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          'networkPassphrase': 'Test SDF Network ; September 2015',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      final response = await webAuth.getChallenge(
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
      );

      expect(response.authorizationEntries, isNotNull);
    });

    test('throws ContractChallengeRequestErrorResponse on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid account parameter'
        }), 400);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.getChallenge(
          'INVALID_ACCOUNT',
        ),
        throwsA(isA<ContractChallengeRequestErrorResponse>()),
      );
    });

    test('passes custom HTTP headers in request', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');

        return http.Response(json.encode({
          'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom-Header': 'custom-value'},
      );

      await webAuth.getChallenge(
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
      );
    });

    test('throws exception when authorization_entries field missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'network_passphrase': 'Test SDF Network ; September 2015',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      await expectLater(
        webAuth.getChallenge(
          'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        ),
        throwsA(isA<ContractChallengeRequestErrorResponse>()),
      );
    });
  });

  group('WebAuthForContracts - sendSignedChallenge', () {
    late WebAuthForContracts webAuth;
    late String authEndpoint;
    late String webAuthContractId;
    late String serverSigningKey;

    setUp(() {
      authEndpoint = 'https://testanchor.stellar.org/auth';
      webAuthContractId = 'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE';
      serverSigningKey = 'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345';
    });

    test('successfully submits signed entries and returns JWT token', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), authEndpoint);
        expect(request.headers['Content-Type'], 'application/x-www-form-urlencoded');
        expect(request.body, contains('authorization_entries='));

        return http.Response(json.encode({
          'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJDQUJDMTIzNDU2Nzg5MEFCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaMTIzNDU2Nzg5MEFCQ0RFIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      final token = await webAuth.sendSignedChallenge([]);

      expect(token, isNotNull);
      expect(token, startsWith('eyJ'));
    });

    test('sends form-urlencoded data when useFormUrlEncoded is true', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Content-Type'], 'application/x-www-form-urlencoded');
        expect(request.body, contains('authorization_entries='));

        return http.Response(json.encode({
          'token': 'jwt-token',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );
      webAuth.useFormUrlEncoded = true;

      await webAuth.sendSignedChallenge([]);
    });

    test('sends JSON data when useFormUrlEncoded is false', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Content-Type'], 'application/json');
        final body = json.decode(request.body);
        expect(body['authorization_entries'], isNotNull);

        return http.Response(json.encode({
          'token': 'jwt-token',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );
      webAuth.useFormUrlEncoded = false;

      await webAuth.sendSignedChallenge([]);
    });

    test('throws SubmitContractChallengeErrorResponseException on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid signature',
        }), 400);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.sendSignedChallenge([]),
        throwsA(isA<SubmitContractChallengeErrorResponseException>()),
      );
    });

    test('throws SubmitContractChallengeTimeoutResponseException on HTTP 504', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 504);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.sendSignedChallenge([]),
        throwsA(isA<SubmitContractChallengeTimeoutResponseException>()),
      );
    });

    test('throws SubmitContractChallengeUnknownResponseException on unknown HTTP status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
      );

      expect(
        () => webAuth.sendSignedChallenge([]),
        throwsA(isA<SubmitContractChallengeUnknownResponseException>()),
      );
    });

    test('passes custom HTTP headers in request', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');

        return http.Response(json.encode({
          'token': 'jwt-token',
        }), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
        'testanchor.stellar.org',
        Network.TESTNET,
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom-Header': 'custom-value'},
      );

      await webAuth.sendSignedChallenge([]);
    });

    test('throws error when token field missing in response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({}), 200);
      });

      webAuth = WebAuthForContracts(
        authEndpoint,
        webAuthContractId,
        serverSigningKey,
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

  group('WebAuthForContracts - Exception Classes', () {
    test('ContractChallengeValidationException formats message correctly', () {
      final exception = ContractChallengeValidationException('Test validation error');
      expect(exception.toString(), 'Test validation error');
    });

    test('ContractChallengeValidationErrorInvalidContractAddress formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidContractAddress(
        'Contract address does not match'
      );
      expect(exception.toString(), 'Contract address does not match');
    });

    test('ContractChallengeValidationErrorInvalidFunctionName formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidFunctionName(
        'Function name is not web_auth_verify'
      );
      expect(exception.toString(), 'Function name is not web_auth_verify');
    });

    test('ContractChallengeValidationErrorSubInvocationsFound formats message correctly', () {
      final exception = ContractChallengeValidationErrorSubInvocationsFound(
        'Sub-invocations found'
      );
      expect(exception.toString(), 'Sub-invocations found');
    });

    test('ContractChallengeValidationErrorInvalidHomeDomain formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidHomeDomain(
        'Home domain does not match'
      );
      expect(exception.toString(), 'Home domain does not match');
    });

    test('ContractChallengeValidationErrorInvalidWebAuthDomain formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidWebAuthDomain(
        'Web auth domain does not match'
      );
      expect(exception.toString(), 'Web auth domain does not match');
    });

    test('ContractChallengeValidationErrorInvalidAccount formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidAccount(
        'Account does not match'
      );
      expect(exception.toString(), 'Account does not match');
    });

    test('ContractChallengeValidationErrorInvalidNonce formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidNonce(
        'Nonce is inconsistent'
      );
      expect(exception.toString(), 'Nonce is inconsistent');
    });

    test('ContractChallengeValidationErrorInvalidServerSignature formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidServerSignature(
        'Server signature is invalid'
      );
      expect(exception.toString(), 'Server signature is invalid');
    });

    test('ContractChallengeValidationErrorMissingServerEntry formats message correctly', () {
      final exception = ContractChallengeValidationErrorMissingServerEntry(
        'Server entry not found'
      );
      expect(exception.toString(), 'Server entry not found');
    });

    test('ContractChallengeValidationErrorMissingClientEntry formats message correctly', () {
      final exception = ContractChallengeValidationErrorMissingClientEntry(
        'Client entry not found'
      );
      expect(exception.toString(), 'Client entry not found');
    });

    test('ContractChallengeValidationErrorInvalidArgs formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidArgs(
        'Arguments are invalid'
      );
      expect(exception.toString(), 'Arguments are invalid');
    });

    test('ContractChallengeValidationErrorInvalidNetworkPassphrase formats message correctly', () {
      final exception = ContractChallengeValidationErrorInvalidNetworkPassphrase(
        'Network passphrase mismatch'
      );
      expect(exception.toString(), 'Network passphrase mismatch');
    });

    test('ContractChallengeRequestErrorResponse formats message correctly with status code', () {
      final exception = ContractChallengeRequestErrorResponse(
        'Invalid request',
        statusCode: 400,
      );
      expect(exception.toString(), contains('HTTP 400'));
      expect(exception.toString(), contains('Invalid request'));
    });

    test('ContractChallengeRequestErrorResponse formats message correctly without status code', () {
      final exception = ContractChallengeRequestErrorResponse('Network error');
      expect(exception.toString(), contains('Network error'));
      expect(exception.toString(), isNot(contains('HTTP')));
    });

    test('SubmitContractChallengeErrorResponseException formats message correctly', () {
      final exception = SubmitContractChallengeErrorResponseException('Invalid signature');
      expect(exception.toString(), contains('Invalid signature'));
    });

    test('SubmitContractChallengeTimeoutResponseException formats message correctly', () {
      final exception = SubmitContractChallengeTimeoutResponseException();
      expect(exception.toString(), contains('504'));
    });

    test('SubmitContractChallengeUnknownResponseException formats message correctly', () {
      final exception = SubmitContractChallengeUnknownResponseException(
        500,
        'Internal Server Error',
      );
      expect(exception.toString(), contains('500'));
      expect(exception.toString(), contains('Internal Server Error'));
    });

    test('NoWebAuthForContractsEndpointFoundException formats message correctly', () {
      final exception = NoWebAuthForContractsEndpointFoundException('testanchor.stellar.org');
      expect(exception.toString(), contains('testanchor.stellar.org'));
      expect(exception.toString(), contains('WEB_AUTH_FOR_CONTRACTS_ENDPOINT'));
    });

    test('NoWebAuthContractIdFoundException formats message correctly', () {
      final exception = NoWebAuthContractIdFoundException('testanchor.stellar.org');
      expect(exception.toString(), contains('testanchor.stellar.org'));
      expect(exception.toString(), contains('WEB_AUTH_CONTRACT_ID'));
    });

    test('MissingClientDomainForContractAuthException formats message correctly', () {
      final exception = MissingClientDomainForContractAuthException();
      expect(exception.toString(), contains('clientDomain is required'));
    });
  });

  group('WebAuthForContracts - Response Classes', () {
    test('ContractChallengeResponse parses snake_case JSON correctly', () {
      final json = {
        'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        'network_passphrase': 'Test SDF Network ; September 2015',
      };

      final response = ContractChallengeResponse.fromJson(json);

      expect(response.authorizationEntries, 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=');
      expect(response.networkPassphrase, 'Test SDF Network ; September 2015');
    });

    test('ContractChallengeResponse parses camelCase JSON correctly', () {
      final json = {
        'authorizationEntries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        'networkPassphrase': 'Test SDF Network ; September 2015',
      };

      final response = ContractChallengeResponse.fromJson(json);

      expect(response.authorizationEntries, 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=');
      expect(response.networkPassphrase, 'Test SDF Network ; September 2015');
    });

    test('ContractChallengeResponse allows null network passphrase', () {
      final json = {
        'authorization_entries': 'AAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      };

      final response = ContractChallengeResponse.fromJson(json);

      expect(response.authorizationEntries, isNotNull);
      expect(response.networkPassphrase, isNull);
    });

    test('ContractChallengeResponse throws error when authorization_entries missing', () {
      final json = {
        'network_passphrase': 'Test SDF Network ; September 2015',
      };

      expect(
        () => ContractChallengeResponse.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('SubmitContractChallengeResponse parses JWT token correctly', () {
      final json = {
        'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U',
      };

      final response = SubmitContractChallengeResponse.fromJson(json);

      expect(response.jwtToken, isNotNull);
      expect(response.error, isNull);
    });

    test('SubmitContractChallengeResponse parses error correctly', () {
      final json = {
        'error': 'Invalid signature',
      };

      final response = SubmitContractChallengeResponse.fromJson(json);

      expect(response.jwtToken, isNull);
      expect(response.error, 'Invalid signature');
    });

    test('SubmitContractChallengeResponse handles both null fields', () {
      final json = <String, dynamic>{};

      final response = SubmitContractChallengeResponse.fromJson(json);

      expect(response.jwtToken, isNull);
      expect(response.error, isNull);
    });
  });
}
