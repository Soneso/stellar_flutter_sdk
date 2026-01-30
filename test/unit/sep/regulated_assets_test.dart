import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
  group('RegulatedAssetsService - fromDomain', () {
    test('creates instance from stellar.toml with regulated assets', () async {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="$testIssuer"
regulated=true
approval_server="https://api.example.com/approve"
approval_criteria="KYC required for all transactions"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(service.regulatedAssets, isNotEmpty);
      expect(service.regulatedAssets.length, 1);
      expect(service.regulatedAssets[0].code, 'USDC');
      expect(service.regulatedAssets[0].issuerId, testIssuer);
      expect(service.regulatedAssets[0].approvalServer, 'https://api.example.com/approve');
      expect(service.regulatedAssets[0].approvalCriteria, 'KYC required for all transactions');
    });

    test('filters out non-regulated assets', () async {
      final testIssuer1 = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';
      final testIssuer2 = 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
      final testIssuer3 = 'GBSTRUSD7IRX73RQZBL3RQUH6KS3O4NYFY3QCALDLZD77XMZOPWAVTUK';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="$testIssuer1"
regulated=true
approval_server="https://api.example.com/approve"
[[CURRENCIES]]
code="BTC"
issuer="$testIssuer2"
regulated=false
[[CURRENCIES]]
code="ETH"
issuer="$testIssuer3"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(service.regulatedAssets.length, 1);
      expect(service.regulatedAssets[0].code, 'USDC');
    });

    test('handles multiple regulated assets', () async {
      final testIssuer1 = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';
      final testIssuer2 = 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="$testIssuer1"
regulated=true
approval_server="https://api.example.com/approve/usdc"
[[CURRENCIES]]
code="GOAT"
issuer="$testIssuer2"
regulated=true
approval_server="https://api.example.com/approve/goat"
approval_criteria="Must be verified goat owner"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(service.regulatedAssets.length, 2);
      expect(service.regulatedAssets[0].code, 'USDC');
      expect(service.regulatedAssets[1].code, 'GOAT');
      expect(service.regulatedAssets[1].approvalCriteria, 'Must be verified goat owner');
    });

    test('throws IncompleteInitData when network passphrase missing', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      expect(
        () => RegulatedAssetsService.fromDomain(
          'example.com',
          httpClient: mockClient,
        ),
        throwsA(isA<IncompleteInitData>()),
      );
    });

    test('uses custom HTTP headers', () async {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'test-value');
        return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="$testIssuer"
regulated=true
approval_server="https://api.example.com/approve"
        ''', 200);
      });

      await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom-Header': 'test-value'},
      );
    });
  });

  group('RegulatedAssetsService - authorizationRequired', () {
    // Note: authorizationRequired makes HTTP calls to the Horizon server using
    // the StellarSDK's internal HTTP client. These tests verify the method
    // signature and exception handling behavior without making actual network calls.

    test('throws IssuerAccountNotFound when account lookup fails', () async {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="$testIssuer"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final asset = service.regulatedAssets[0];

      // The method will throw IssuerAccountNotFound because the SDK's
      // internal HTTP client cannot reach the Horizon server in tests
      await expectLater(
        service.authorizationRequired(asset),
        throwsA(isA<IssuerAccountNotFound>()),
      );
    });

    test('RegulatedAsset has correct issuer ID for authorization check', () async {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="$testIssuer"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final asset = service.regulatedAssets[0];
      expect(asset.issuerId, testIssuer);
    });

    test('service sdk is initialized with correct network', () async {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="$testIssuer"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(service.sdk, isNotNull);
      expect(service.network.networkPassphrase, 'Test SDF Network ; September 2015');
    });
  });

  group('RegulatedAssetsService - postTransaction', () {
    test('successfully posts transaction and receives success status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          expect(request.method, 'POST');
          expect(request.headers['Content-Type'], 'application/json');

          final body = json.decode(request.body);
          expect(body['tx'], isNotNull);

          return http.Response(json.encode({
            'status': 'success',
            'tx': 'AAAAAgAAAAA...',
            'message': 'Transaction approved successfully',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postTransaction(
        'AAAAAgAAAAA...',
        'https://api.example.com/approve',
      );

      expect(response, isA<PostTransactionSuccess>());
      final success = response as PostTransactionSuccess;
      expect(success.tx, 'AAAAAgAAAAA...');
      expect(success.message, 'Transaction approved successfully');
    });

    test('successfully posts transaction and receives revised status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          return http.Response(json.encode({
            'status': 'revised',
            'tx': 'AAAAAgAAAABBBBB...',
            'message': 'Added authorization operations',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postTransaction(
        'AAAAAgAAAAA...',
        'https://api.example.com/approve',
      );

      expect(response, isA<PostTransactionRevised>());
      final revised = response as PostTransactionRevised;
      expect(revised.tx, 'AAAAAgAAAABBBBB...');
      expect(revised.message, 'Added authorization operations');
    });

    test('successfully posts transaction and receives pending status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          return http.Response(json.encode({
            'status': 'pending',
            'timeout': 5000,
            'message': 'Manual review required',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postTransaction(
        'AAAAAgAAAAA...',
        'https://api.example.com/approve',
      );

      expect(response, isA<PostTransactionPending>());
      final pending = response as PostTransactionPending;
      expect(pending.timeout, 5000);
      expect(pending.message, 'Manual review required');
    });

    test('successfully posts transaction and receives action_required status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          return http.Response(json.encode({
            'status': 'action_required',
            'message': 'KYC information required',
            'action_url': 'https://api.example.com/kyc',
            'action_method': 'POST',
            'action_fields': ['email_address', 'mobile_number'],
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postTransaction(
        'AAAAAgAAAAA...',
        'https://api.example.com/approve',
      );

      expect(response, isA<PostTransactionActionRequired>());
      final actionRequired = response as PostTransactionActionRequired;
      expect(actionRequired.message, 'KYC information required');
      expect(actionRequired.actionUrl, 'https://api.example.com/kyc');
      expect(actionRequired.actionMethod, 'POST');
      expect(actionRequired.actionFields, ['email_address', 'mobile_number']);
    });

    test('successfully posts transaction and receives rejected status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          return http.Response(json.encode({
            'status': 'rejected',
            'error': 'Transaction violates compliance rules',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postTransaction(
        'AAAAAgAAAAA...',
        'https://api.example.com/approve',
      );

      expect(response, isA<PostTransactionRejected>());
      final rejected = response as PostTransactionRejected;
      expect(rejected.error, 'Transaction violates compliance rules');
    });

    test('handles HTTP 400 error response with rejected status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          // 400 responses with error field need a status to be parsed
          return http.Response(json.encode({
            'status': 'rejected',
            'error': 'Invalid transaction format',
          }), 400);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postTransaction(
        'INVALID_TX',
        'https://api.example.com/approve',
      );

      expect(response, isA<PostTransactionRejected>());
      final rejected = response as PostTransactionRejected;
      expect(rejected.error, 'Invalid transaction format');
    });

    test('throws UnknownPostTransactionResponse on unexpected status code', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.postTransaction(
          'AAAAAgAAAAA...',
          'https://api.example.com/approve',
        ),
        throwsA(isA<UnknownPostTransactionResponse>()),
      );
    });

    test('throws UnknownPostTransactionResponseStatus on unknown status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          return http.Response(json.encode({
            'status': 'unknown_status',
            'message': 'Something unexpected',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.postTransaction(
          'AAAAAgAAAAA...',
          'https://api.example.com/approve',
        ),
        throwsA(isA<UnknownPostTransactionResponseStatus>()),
      );
    });

    test('uses custom HTTP headers', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('approve')) {
          expect(request.headers['X-Custom-Header'], 'custom-value');
          return http.Response(json.encode({
            'status': 'success',
            'tx': 'AAAAAgAAAAA...',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom-Header': 'custom-value'},
      );

      await service.postTransaction(
        'AAAAAgAAAAA...',
        'https://api.example.com/approve',
      );
    });
  });

  group('RegulatedAssetsService - postAction', () {
    test('successfully posts action and receives no_further_action_required', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('kyc')) {
          expect(request.method, 'POST');
          expect(request.headers['Content-Type'], 'application/json');

          final body = json.decode(request.body);
          expect(body['email_address'], 'user@example.com');

          return http.Response(json.encode({
            'result': 'no_further_action_required',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postAction(
        'https://api.example.com/kyc',
        {'email_address': 'user@example.com'},
      );

      expect(response, isA<PostActionDone>());
    });

    test('successfully posts action and receives follow_next_url', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('kyc')) {
          return http.Response(json.encode({
            'result': 'follow_next_url',
            'next_url': 'https://api.example.com/kyc/verify',
            'message': 'Please verify your identity',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      final response = await service.postAction(
        'https://api.example.com/kyc',
        {'email_address': 'user@example.com'},
      );

      expect(response, isA<PostActionNextUrl>());
      final nextUrl = response as PostActionNextUrl;
      expect(nextUrl.nextUrl, 'https://api.example.com/kyc/verify');
      expect(nextUrl.message, 'Please verify your identity');
    });

    test('throws UnknownPostActionResponse on unexpected status code', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('kyc')) {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.postAction(
          'https://api.example.com/kyc',
          {'email_address': 'user@example.com'},
        ),
        throwsA(isA<UnknownPostActionResponse>()),
      );
    });

    test('throws UnknownPostActionResponseResult on unknown result', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('kyc')) {
          return http.Response(json.encode({
            'result': 'unknown_result',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.postAction(
          'https://api.example.com/kyc',
          {'email_address': 'user@example.com'},
        ),
        throwsA(isA<UnknownPostActionResponseResult>()),
      );
    });

    test('uses custom HTTP headers', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('.well-known/stellar.toml')) {
          return http.Response('''
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
HORIZON_URL="https://horizon-testnet.stellar.org"
[[CURRENCIES]]
code="USDC"
issuer="GXXXXXXX"
regulated=true
approval_server="https://api.example.com/approve"
          ''', 200);
        } else if (request.url.toString().contains('kyc')) {
          expect(request.headers['X-Custom-Header'], 'custom-value');
          return http.Response(json.encode({
            'result': 'no_further_action_required',
          }), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = await RegulatedAssetsService.fromDomain(
        'example.com',
        httpClient: mockClient,
        httpRequestHeaders: {'X-Custom-Header': 'custom-value'},
      );

      await service.postAction(
        'https://api.example.com/kyc',
        {'email_address': 'user@example.com'},
      );
    });
  });

  group('RegulatedAssetsService - Response Classes', () {
    test('PostTransactionSuccess parses correctly', () {
      final response = PostTransactionSuccess(
        'AAAAAgAAAAA...',
        message: 'Transaction approved',
      );

      expect(response.tx, 'AAAAAgAAAAA...');
      expect(response.message, 'Transaction approved');
    });

    test('PostTransactionRevised parses correctly', () {
      final response = PostTransactionRevised(
        'AAAAAgAAAABBBBB...',
        'Added authorization operations',
      );

      expect(response.tx, 'AAAAAgAAAABBBBB...');
      expect(response.message, 'Added authorization operations');
    });

    test('PostTransactionPending parses correctly with timeout', () {
      final response = PostTransactionPending(
        timeout: 5000,
        message: 'Manual review required',
      );

      expect(response.timeout, 5000);
      expect(response.message, 'Manual review required');
    });

    test('PostTransactionPending defaults timeout to 0', () {
      final response = PostTransactionPending();

      expect(response.timeout, 0);
      expect(response.message, isNull);
    });

    test('PostTransactionActionRequired parses correctly', () {
      final response = PostTransactionActionRequired(
        'KYC required',
        'https://api.example.com/kyc',
        actionMethod: 'POST',
        actionFields: ['email_address', 'mobile_number'],
      );

      expect(response.message, 'KYC required');
      expect(response.actionUrl, 'https://api.example.com/kyc');
      expect(response.actionMethod, 'POST');
      expect(response.actionFields, ['email_address', 'mobile_number']);
    });

    test('PostTransactionActionRequired defaults action_method to GET', () {
      final response = PostTransactionActionRequired(
        'Please complete KYC',
        'https://api.example.com/kyc',
      );

      expect(response.actionMethod, 'GET');
      expect(response.actionFields, isNull);
    });

    test('PostTransactionRejected parses correctly', () {
      final response = PostTransactionRejected(
        'Transaction violates compliance rules',
      );

      expect(response.error, 'Transaction violates compliance rules');
    });

    test('PostActionDone constructs correctly', () {
      final response = PostActionDone();
      expect(response, isA<PostActionDone>());
    });

    test('PostActionNextUrl parses correctly', () {
      final response = PostActionNextUrl(
        'https://api.example.com/verify',
        message: 'Please verify your identity',
      );

      expect(response.nextUrl, 'https://api.example.com/verify');
      expect(response.message, 'Please verify your identity');
    });
  });

  group('RegulatedAssetsService - Exception Classes', () {
    test('IssuerAccountNotFound formats message correctly', () {
      final exception = IssuerAccountNotFound('Issuer account GXXXXXXX not found');
      expect(exception.toString(), 'Issuer account GXXXXXXX not found');
    });

    test('IncompleteInitData formats message correctly', () {
      final exception = IncompleteInitData('could not find a network passphrase');
      expect(exception.toString(), 'could not find a network passphrase');
    });

    test('UnknownPostTransactionResponseStatus formats message correctly', () {
      final exception = UnknownPostTransactionResponseStatus(
        'Unknown status \'invalid_status\' received in the post transaction response',
      );
      expect(exception.toString(), contains('invalid_status'));
    });

    test('UnknownPostTransactionResponse formats message correctly', () {
      final exception = UnknownPostTransactionResponse(500, 'Internal Server Error');
      expect(exception.toString(), contains('500'));
      expect(exception.toString(), contains('Internal Server Error'));
      expect(exception.code, 500);
      expect(exception.body, 'Internal Server Error');
    });

    test('UnknownPostActionResponse formats message correctly', () {
      final exception = UnknownPostActionResponse(503, 'Service Unavailable');
      expect(exception.toString(), contains('503'));
      expect(exception.toString(), contains('Service Unavailable'));
      expect(exception.code, 503);
      expect(exception.body, 'Service Unavailable');
    });

    test('UnknownPostActionResponseResult formats message correctly', () {
      final exception = UnknownPostActionResponseResult(
        'Unknown result \'invalid_result\' received in the post action response',
      );
      expect(exception.toString(), contains('invalid_result'));
    });
  });

  group('RegulatedAssetsService - RegulatedAsset', () {
    test('creates regulated asset correctly', () {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final asset = RegulatedAsset(
        'USDC',
        testIssuer,
        'https://api.example.com/approve',
        approvalCriteria: 'KYC required',
      );

      expect(asset.code, 'USDC');
      expect(asset.issuerId, testIssuer);
      expect(asset.approvalServer, 'https://api.example.com/approve');
      expect(asset.approvalCriteria, 'KYC required');
    });

    test('creates regulated asset without approval criteria', () {
      final testIssuer = 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';

      final asset = RegulatedAsset(
        'GOAT',
        testIssuer,
        'https://api.example.com/approve/goat',
      );

      expect(asset.code, 'GOAT');
      expect(asset.issuerId, testIssuer);
      expect(asset.approvalServer, 'https://api.example.com/approve/goat');
      expect(asset.approvalCriteria, isNull);
    });

    test('toXdr creates valid XDR asset', () {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final asset = RegulatedAsset(
        'USDC',
        testIssuer,
        'https://api.example.com/approve',
      );

      final xdrAsset = asset.toXdr();
      expect(xdrAsset, isNotNull);
    });

    test('type returns correct asset type', () {
      final testIssuer = 'GDIROJW2YHMSFZJJ4R5XWWNUVND5I45YEWS5DSFKXCHMADZ5V374U2LM';

      final asset4 = RegulatedAsset(
        'USDC',
        testIssuer,
        'https://api.example.com/approve',
      );

      final asset12 = RegulatedAsset(
        'LONGASSETCD',
        testIssuer,
        'https://api.example.com/approve',
      );

      expect(asset4.type, contains('alphanum'));
      expect(asset12.type, contains('alphanum'));
    });
  });
}
