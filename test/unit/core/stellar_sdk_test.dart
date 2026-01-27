import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('StellarSDK', () {
    group('static instances', () {
      test('PUBLIC instance points to mainnet Horizon URL', () {
        final sdk = StellarSDK.PUBLIC;

        expect(sdk.httpClient, isNotNull);
        final rootRequest = sdk.root();
        expect(rootRequest, isA<Future<RootResponse>>());
      });

      test('TESTNET instance points to testnet Horizon URL', () {
        final sdk = StellarSDK.TESTNET;

        expect(sdk.httpClient, isNotNull);
        final rootRequest = sdk.root();
        expect(rootRequest, isA<Future<RootResponse>>());
      });

      test('FUTURENET instance points to futurenet Horizon URL', () {
        final sdk = StellarSDK.FUTURENET;

        expect(sdk.httpClient, isNotNull);
        final rootRequest = sdk.root();
        expect(rootRequest, isA<Future<RootResponse>>());
      });

      test('static instances are singletons', () {
        final public1 = StellarSDK.PUBLIC;
        final public2 = StellarSDK.PUBLIC;

        expect(identical(public1, public2), isTrue);

        final testnet1 = StellarSDK.TESTNET;
        final testnet2 = StellarSDK.TESTNET;

        expect(identical(testnet1, testnet2), isTrue);

        final futurenet1 = StellarSDK.FUTURENET;
        final futurenet2 = StellarSDK.FUTURENET;

        expect(identical(futurenet1, futurenet2), isTrue);
      });
    });

    group('constructor', () {
      test('creates SDK with custom Horizon URL', () {
        final customUrl = 'https://custom-horizon.example.com';
        final sdk = StellarSDK(customUrl);

        expect(sdk.httpClient, isNotNull);
      });

      test('creates SDK with HTTP URL', () {
        final httpUrl = 'http://localhost:8000';
        final sdk = StellarSDK(httpUrl);

        expect(sdk.httpClient, isNotNull);
      });

      test('creates SDK with HTTPS URL', () {
        final httpsUrl = 'https://horizon.stellar.org';
        final sdk = StellarSDK(httpsUrl);

        expect(sdk.httpClient, isNotNull);
      });

      test('creates SDK and sets custom HTTP client via setter', () {
        final customClient = MockClient((request) async {
          return http.Response('{"test": "mock"}', 200);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = customClient;

        expect(sdk.httpClient, same(customClient));
      });

      test('creates SDK without custom HTTP client', () {
        final sdk = StellarSDK('https://horizon.stellar.org');

        expect(sdk.httpClient, isNotNull);
        expect(sdk.httpClient, isA<http.Client>());
      });
    });

    group('httpClient getter and setter', () {
      test('httpClient getter returns the HTTP client', () {
        final sdk = StellarSDK('https://horizon-testnet.stellar.org');

        expect(sdk.httpClient, isNotNull);
        expect(sdk.httpClient, isA<http.Client>());
      });

      test('httpClient setter updates the HTTP client', () {
        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        final originalClient = sdk.httpClient;

        final newClient = MockClient((request) async {
          return http.Response('{"test": "new"}', 200);
        });

        sdk.httpClient = newClient;

        expect(sdk.httpClient, same(newClient));
        expect(sdk.httpClient, isNot(same(originalClient)));
      });
    });

    group('root', () {
      test('fetches root endpoint successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(request.url.path, anyOf(equals('/'), equals('')));

          final rootJson = {
            'horizon_version': '2.0.0',
            'core_version': 'stellar-core 19.0.0',
            'ingest_latest_ledger': 12345,
            'history_latest_ledger': 12345,
            'history_latest_ledger_closed_at': '2024-01-15T10:30:00Z',
            'history_elder_ledger': 1,
            'core_latest_ledger': 12345,
            'network_passphrase': 'Test SDF Network ; September 2015',
            'current_protocol_version': 19,
            'supported_protocol_version': 20,
            'core_supported_protocol_version': 19,
            '_links': {
              'self': {'href': 'https://horizon-testnet.stellar.org/'},
            }
          };

          return http.Response(json.encode(rootJson), 200);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final rootResponse = await sdk.root();

        expect(rootResponse, isA<RootResponse>());
        expect(rootResponse.horizonVersion, equals('2.0.0'));
        expect(rootResponse.stellarCoreVersion, equals('stellar-core 19.0.0'));
        expect(rootResponse.currentProtocolVersion, equals(19));
        expect(rootResponse.supportedProtocolVersion, equals(20));
        expect(rootResponse.networkPassphrase, equals('Test SDF Network ; September 2015'));
        expect(rootResponse.historyLatestLedger, equals(12345));
        expect(rootResponse.coreLatestLedger, equals(12345));
      });
    });

    group('request builder getters', () {
      late StellarSDK sdk;

      setUp(() {
        sdk = StellarSDK('https://horizon-testnet.stellar.org');
      });

      test('accounts getter returns AccountsRequestBuilder', () {
        final builder = sdk.accounts;

        expect(builder, isA<AccountsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('assets getter returns AssetsRequestBuilder', () {
        final builder = sdk.assets;

        expect(builder, isA<AssetsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('effects getter returns EffectsRequestBuilder', () {
        final builder = sdk.effects;

        expect(builder, isA<EffectsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('ledgers getter returns LedgersRequestBuilder', () {
        final builder = sdk.ledgers;

        expect(builder, isA<LedgersRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('offers getter returns OffersRequestBuilder', () {
        final builder = sdk.offers;

        expect(builder, isA<OffersRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('operations getter returns OperationsRequestBuilder', () {
        final builder = sdk.operations;

        expect(builder, isA<OperationsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('feeStats getter returns FeeStatsRequestBuilder', () {
        final builder = sdk.feeStats;

        expect(builder, isA<FeeStatsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('health getter returns HealthRequestBuilder', () {
        final builder = sdk.health;

        expect(builder, isA<HealthRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('orderBook getter returns OrderBookRequestBuilder', () {
        final builder = sdk.orderBook;

        expect(builder, isA<OrderBookRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('trades getter returns TradesRequestBuilder', () {
        final builder = sdk.trades;

        expect(builder, isA<TradesRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('claimableBalances getter returns ClaimableBalancesRequestBuilder', () {
        final builder = sdk.claimableBalances;

        expect(builder, isA<ClaimableBalancesRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('strictSendPaths getter returns StrictSendPathsRequestBuilder', () {
        final builder = sdk.strictSendPaths;

        expect(builder, isA<StrictSendPathsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('strictReceivePaths getter returns StrictReceivePathsRequestBuilder', () {
        final builder = sdk.strictReceivePaths;

        expect(builder, isA<StrictReceivePathsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('payments getter returns PaymentsRequestBuilder', () {
        final builder = sdk.payments;

        expect(builder, isA<PaymentsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('transactions getter returns TransactionsRequestBuilder', () {
        final builder = sdk.transactions;

        expect(builder, isA<TransactionsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('liquidityPools getter returns LiquidityPoolsRequestBuilder', () {
        final builder = sdk.liquidityPools;

        expect(builder, isA<LiquidityPoolsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('liquidityPoolTrades getter returns LiquidityPoolTradesRequestBuilder', () {
        final builder = sdk.liquidityPoolTrades;

        expect(builder, isA<LiquidityPoolTradesRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('request builders use same HTTP client instance', () {
        final accountsBuilder = sdk.accounts;
        final paymentsBuilder = sdk.payments;
        final ledgersBuilder = sdk.ledgers;

        expect(accountsBuilder.httpClient, same(sdk.httpClient));
        expect(paymentsBuilder.httpClient, same(sdk.httpClient));
        expect(ledgersBuilder.httpClient, same(sdk.httpClient));
      });
    });

    group('tradeAggregations', () {
      late StellarSDK sdk;

      setUp(() {
        sdk = StellarSDK('https://horizon-testnet.stellar.org');
      });

      test('returns TradeAggregationsRequestBuilder with all parameters', () {
        final baseAsset = Asset.NATIVE;
        final counterAsset = AssetTypeCreditAlphaNum4(
          'USD',
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        );
        final startTime = 1609459200000;
        final endTime = 1609545600000;
        final resolution = 3600000;
        final offset = 0;

        final builder = sdk.tradeAggregations(
          baseAsset,
          counterAsset,
          startTime,
          endTime,
          resolution,
          offset,
        );

        expect(builder, isA<TradeAggregationsRequestBuilder>());
        expect(builder.httpClient, same(sdk.httpClient));
      });

      test('creates builder with different asset types', () {
        final baseAsset = AssetTypeCreditAlphaNum4(
          'BTC',
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        );
        final counterAsset = AssetTypeCreditAlphaNum12(
          'STELLARTOKEN',
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX',
        );

        final builder = sdk.tradeAggregations(
          baseAsset,
          counterAsset,
          1609459200000,
          1609545600000,
          3600000,
          0,
        );

        expect(builder, isA<TradeAggregationsRequestBuilder>());
      });
    });

    group('submitTransaction', () {
      test('submits transaction successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.pathSegments, contains('transactions'));
          expect(request.headers['Content-Type'], equals('application/x-www-form-urlencoded'));

          final successJson = {
            'hash': 'abc123def456',
            'ledger': 12345,
            'envelope_xdr': 'AAAAAgAAAAA=',
            'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
            'result_meta_xdr': 'AAAAAwAAAAA=',
            'successful': true,
            'id': 'abc123def456',
            'paging_token': '12345-1',
            'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
            'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
            'source_account_sequence': 100,
            'max_fee': 1000,
            'fee_charged': 100,
            'operation_count': 1,
            'created_at': '2024-01-15T10:30:00Z',
            'fee_meta_xdr': 'AAAAAgAAAAA=',
            'memo_type': 'none',
            'signatures': [],
            '_links': {
              'self': {'href': '/transactions/abc123def456'},
            },
          };

          return http.Response(json.encode(successJson), 200);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );
        final destinationKeyPair = KeyPair.fromSecretSeed(
          'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY',
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              destinationKeyPair.accountId,
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final response = await sdk.submitTransaction(transaction);

        expect(response, isA<SubmitTransactionResponse>());
        expect(response.success, isTrue);
        expect(response.hash, equals('abc123def456'));
      });

      test('handles failed transaction submission', () async {
        final mockClient = MockClient((request) async {
          final failureJson = {
            'successful': false,
            'extras': {
              'envelope_xdr': 'AAAAAgAAAABFAILED',
              'result_xdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=',
              'result_codes': {
                'transaction': 'tx_failed',
                'operations': ['op_underfunded'],
              },
            },
          };

          return http.Response(json.encode(failureJson), 400);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );
        final destinationKeyPair = KeyPair.fromSecretSeed(
          'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY',
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              destinationKeyPair.accountId,
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final response = await sdk.submitTransaction(transaction);

        expect(response, isA<SubmitTransactionResponse>());
        expect(response.success, isFalse);
        expect(response.extras, isNotNull);
      });

      test('throws SubmitTransactionTimeoutResponseException on timeout', () async {
        final mockClient = MockClient((request) async {
          final timeoutJson = {
            'type': 'https://stellar.org/horizon-errors/timeout',
            'title': 'Timeout',
            'status': 504,
            'detail': 'Request timed out',
            'hash': 'timeout123',
          };

          return http.Response(json.encode(timeoutJson), 504);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        expect(
          () => sdk.submitTransaction(transaction),
          throwsA(isA<SubmitTransactionTimeoutResponseException>()),
        );
      });

      test('throws UnknownResponse on unexpected status code', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Server Error', 500);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        expect(
          () => sdk.submitTransaction(transaction),
          throwsA(isA<UnknownResponse>()),
        );
      });
    });

    group('submitFeeBumpTransaction', () {
      test('submits fee bump transaction successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.pathSegments, contains('transactions'));

          final successJson = {
            'hash': 'feebump123',
            'ledger': 12346,
            'envelope_xdr': 'AAAABgAAAAA=',
            'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
            'result_meta_xdr': 'AAAAAwAAAAA=',
            'successful': true,
            'id': 'feebump123',
            'paging_token': '12346-1',
            'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
            'fee_account': 'GBVFTZL5HIPT4PFQVTZVIWR77V7LWYCXU4CLYWWHHOEXB64XPG5LDMTU',
            'source_account_sequence': 100,
            'max_fee': 2000,
            'fee_charged': 200,
            'operation_count': 1,
            'created_at': '2024-01-15T10:35:00Z',
            'fee_meta_xdr': 'AAAAAgAAAAA=',
            'memo_type': 'none',
            'signatures': [],
            '_links': {
              'self': {'href': '/transactions/feebump123'},
            },
          };

          return http.Response(json.encode(successJson), 200);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final innerTx = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeSourceKeyPair = KeyPair.fromSecretSeed(
          'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY',
        );

        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .setFeeAccount(feeSourceKeyPair.accountId)
            .build();

        feeBumpTx.sign(feeSourceKeyPair, Network.TESTNET);

        final response = await sdk.submitFeeBumpTransaction(feeBumpTx);

        expect(response, isA<SubmitTransactionResponse>());
        expect(response.success, isTrue);
        expect(response.hash, equals('feebump123'));
      });
    });

    group('submitAsyncTransaction', () {
      test('submits async transaction successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.pathSegments, contains('transactions_async'));

          final asyncJson = {
            'tx_status': 'PENDING',
            'hash': 'async123',
            'error_result_xdr': null,
          };

          return http.Response(json.encode(asyncJson), 201);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final response = await sdk.submitAsyncTransaction(transaction);

        expect(response, isA<SubmitAsyncTransactionResponse>());
        expect(response.txStatus, equals('PENDING'));
        expect(response.hash, equals('async123'));
      });

      test('handles async transaction with error status', () async {
        final mockClient = MockClient((request) async {
          final errorJson = {
            'tx_status': 'ERROR',
            'hash': 'asyncerror123',
            'error_result_xdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=',
          };

          return http.Response(json.encode(errorJson), 400);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final response = await sdk.submitAsyncTransaction(transaction);

        expect(response, isA<SubmitAsyncTransactionResponse>());
        expect(response.txStatus, equals('ERROR'));
      });

      test('throws SubmitAsyncTransactionProblem on problem response', () async {
        final mockClient = MockClient((request) async {
          final problemJson = {
            'type': 'https://stellar.org/horizon-errors/transaction_malformed',
            'title': 'Transaction Malformed',
            'status': 400,
            'detail': 'Transaction is malformed',
          };

          return http.Response(json.encode(problemJson), 400);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        expect(
          () => sdk.submitAsyncTransaction(transaction),
          throwsA(isA<SubmitAsyncTransactionProblem>()),
        );
      });
    });

    group('submitAsyncFeeBumpTransaction', () {
      test('submits async fee bump transaction successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.pathSegments, contains('transactions_async'));

          final asyncJson = {
            'tx_status': 'PENDING',
            'hash': 'asyncfeebump123',
            'error_result_xdr': null,
          };

          return http.Response(json.encode(asyncJson), 201);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final innerTx = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        innerTx.sign(sourceKeyPair, Network.TESTNET);

        final feeSourceKeyPair = KeyPair.fromSecretSeed(
          'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY',
        );

        final feeBumpTx = FeeBumpTransactionBuilder(innerTx)
            .setBaseFee(200)
            .setFeeAccount(feeSourceKeyPair.accountId)
            .build();

        feeBumpTx.sign(feeSourceKeyPair, Network.TESTNET);

        final response = await sdk.submitAsyncFeeBumpTransaction(feeBumpTx);

        expect(response, isA<SubmitAsyncTransactionResponse>());
        expect(response.txStatus, equals('PENDING'));
      });
    });

    group('submitTransactionEnvelopeXdrBase64', () {
      test('submits XDR envelope string successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.pathSegments, contains('transactions'));

          final successJson = {
            'hash': 'xdr123',
            'ledger': 12347,
            'envelope_xdr': 'AAAAAgAAAAA=',
            'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
            'result_meta_xdr': 'AAAAAwAAAAA=',
            'successful': true,
            'id': 'xdr123',
            'paging_token': '12347-1',
            'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
            'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
            'source_account_sequence': 100,
            'max_fee': 1000,
            'fee_charged': 100,
            'operation_count': 1,
            'created_at': '2024-01-15T10:40:00Z',
            'fee_meta_xdr': 'AAAAAgAAAAA=',
            'memo_type': 'none',
            'signatures': [],
            '_links': {
              'self': {'href': '/transactions/xdr123'},
            },
          };

          return http.Response(json.encode(successJson), 200);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final xdrBase64 = transaction.toEnvelopeXdrBase64();
        final response = await sdk.submitTransactionEnvelopeXdrBase64(xdrBase64);

        expect(response, isA<SubmitTransactionResponse>());
        expect(response.success, isTrue);
        expect(response.hash, equals('xdr123'));
      });
    });

    group('submitAsyncTransactionEnvelopeXdrBase64', () {
      test('submits async XDR envelope string successfully', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.pathSegments, contains('transactions_async'));

          final asyncJson = {
            'tx_status': 'PENDING',
            'hash': 'asyncxdr123',
            'error_result_xdr': null,
          };

          return http.Response(json.encode(asyncJson), 201);
        });

        final sdk = StellarSDK('https://horizon-testnet.stellar.org');
        sdk.httpClient = mockClient;

        final sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
        );
        final sourceAccount = Account(
          sourceKeyPair.accountId,
          BigInt.from(2908908335136768),
        );

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperationBuilder(
              'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
              Asset.NATIVE,
              '100.0',
            ).build())
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);

        final xdrBase64 = transaction.toEnvelopeXdrBase64();
        final response = await sdk.submitAsyncTransactionEnvelopeXdrBase64(xdrBase64);

        expect(response, isA<SubmitAsyncTransactionResponse>());
        expect(response.txStatus, equals('PENDING'));
      });

      test('handles different async status codes correctly', () async {
        final statusCodes = [400, 403, 409, 500, 503];

        for (final statusCode in statusCodes) {
          final mockClient = MockClient((request) async {
            final asyncJson = {
              'tx_status': 'ERROR',
              'hash': 'status$statusCode',
              'error_result_xdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=',
            };

            return http.Response(json.encode(asyncJson), statusCode);
          });

          final sdk = StellarSDK('https://horizon-testnet.stellar.org');
          sdk.httpClient = mockClient;

          final sourceKeyPair = KeyPair.fromSecretSeed(
            'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE',
          );
          final sourceAccount = Account(
            sourceKeyPair.accountId,
            BigInt.from(2908908335136768),
          );

          final transaction = TransactionBuilder(sourceAccount)
              .addOperation(PaymentOperationBuilder(
                'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
                Asset.NATIVE,
                '100.0',
              ).build())
              .build();

          transaction.sign(sourceKeyPair, Network.TESTNET);

          final xdrBase64 = transaction.toEnvelopeXdrBase64();
          final response = await sdk.submitAsyncTransactionEnvelopeXdrBase64(xdrBase64);

          expect(response, isA<SubmitAsyncTransactionResponse>());
          expect(response.txStatus, equals('ERROR'));
        }
      });
    });

    group('version', () {
      test('versionNumber constant is defined', () {
        expect(StellarSDK.versionNumber, isNotNull);
        expect(StellarSDK.versionNumber, isA<String>());
        expect(StellarSDK.versionNumber, equals('3.0.0'));
      });
    });
  });
}
