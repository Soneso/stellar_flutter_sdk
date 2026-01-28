// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final http.Client httpClient = http.Client();
  final Uri serverUri = Uri.parse('https://horizon-testnet.stellar.org');
  final String testAccountId =
      'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B';
  final String testIssuerId =
      'GBVOL67TMUQBGL4TZYNMY3ZQ5WGQYFPFD5VJRWXR72VA33VFNL225PL5';
  final String testTransactionId =
      '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';
  final String testLiquidityPoolId =
      'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
  final String testClaimableBalanceId =
      '00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072';
  final String testOfferId = '12345';
  final String testOperationId = '123456789';

  // ======================================================================
  // From request_builder_deep_test.dart
  // ======================================================================

  group('AccountsRequestBuilder', () {
    test('forSigner adds signer query parameter', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.forSigner(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['signer'], equals(testAccountId));
      expect(uri.path, contains('/accounts'));
    });

    test('forAsset adds asset query parameter for native', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.forAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], equals('native'));
    });

    test('forAsset adds asset query parameter for credit asset', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], equals('USD:$testIssuerId'));
    });

    test('forSponsor adds sponsor query parameter', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.forSponsor(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['sponsor'], equals(testAccountId));
    });

    test('forLiquidityPool adds liquidity_pool query parameter', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final poolId = 'abc123';
      builder.forLiquidityPool(poolId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['liquidity_pool'], equals(poolId));
    });

    test('combining forSigner with limit and order', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.forSigner(testAccountId).limit(10).order(RequestBuilderOrder.DESC);
      final uri = builder.buildUri();

      expect(uri.queryParameters['signer'], equals(testAccountId));
      expect(uri.queryParameters['limit'], equals('10'));
      expect(uri.queryParameters['order'], equals('desc'));
    });
  });

  group('LiquidityPoolsRequestBuilder', () {
    test('forReserves adds reserves query parameter', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final assetA = Asset.NATIVE;
      final assetB = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forReserveAssets(assetA, assetB);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], isNotNull);
      expect(uri.queryParameters['reserves'], contains('native'));
      expect(uri.queryParameters['reserves'], contains('USD'));
      expect(uri.queryParameters['reserves'], contains(testIssuerId));
    });

    test('forAccount adds account query parameter', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['account'], equals(testAccountId));
    });

    test('combining forAccount with cursor and limit', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId).cursor('test_cursor').limit(20);
      final uri = builder.buildUri();

      expect(uri.queryParameters['account'], equals(testAccountId));
      expect(uri.queryParameters['cursor'], equals('test_cursor'));
      expect(uri.queryParameters['limit'], equals('20'));
    });
  });

  group('OffersRequestBuilder', () {
    test('forAccount sets path segments correctly', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/offers'));
    });

    test('forSeller adds seller query parameter', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forSeller(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['seller'], equals(testAccountId));
    });

    test('forBuyingAsset adds buying asset parameters for native', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forBuyingAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('native'));
    });

    test('forBuyingAsset adds buying asset parameters for credit', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forBuyingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['buying_asset_code'], equals('USD'));
      expect(uri.queryParameters['buying_asset_issuer'], equals(testIssuerId));
    });

    test('forSellingAsset adds selling asset parameters', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum12('SILVERCOIN', testIssuerId);
      builder.forSellingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum12'));
      expect(uri.queryParameters['selling_asset_code'], equals('SILVERCOIN'));
      expect(uri.queryParameters['selling_asset_issuer'], equals(testIssuerId));
    });

    test('combining buying and selling assets', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final buyAsset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      final sellAsset = Asset.NATIVE;
      builder.forBuyingAsset(buyAsset).forSellingAsset(sellAsset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['selling_asset_type'], equals('native'));
    });

    test('forSponsor adds sponsor query parameter', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forSponsor(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['sponsor'], equals(testAccountId));
    });
  });

  group('OperationsRequestBuilder', () {
    test('forAccount sets path segments correctly', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/operations'));
    });

    test('forLedger sets path segments with ledger number', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forLedger(123456);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/123456/operations'));
    });

    test('forTransaction sets path segments with tx id', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final txId = '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';
      builder.forTransaction(txId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/$txId/operations'));
    });

    test('includeFailed adds include_failed query parameter', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('combining forAccount with includeFailed and pagination', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId).includeFailed(false).limit(50).order(RequestBuilderOrder.ASC);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/operations'));
      expect(uri.queryParameters['include_failed'], equals('false'));
      expect(uri.queryParameters['limit'], equals('50'));
      expect(uri.queryParameters['order'], equals('asc'));
    });
  });

  group('TransactionsRequestBuilder', () {
    test('forAccount sets path segments correctly', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/transactions'));
    });

    test('forLedger sets path segments with ledger number', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forLedger(789012);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/789012/transactions'));
    });

    test('includeFailed adds include_failed query parameter', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('combining forLedger with includeFailed and order', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forLedger(100000).includeFailed(true).order(RequestBuilderOrder.DESC);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/100000/transactions'));
      expect(uri.queryParameters['include_failed'], equals('true'));
      expect(uri.queryParameters['order'], equals('desc'));
    });
  });

  group('LedgersRequestBuilder', () {
    test('basic builder with limit and order', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      builder.limit(25).order(RequestBuilderOrder.DESC);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers'));
      expect(uri.queryParameters['limit'], equals('25'));
      expect(uri.queryParameters['order'], equals('desc'));
    });

    test('with cursor for pagination', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      builder.cursor('12345').limit(100);
      final uri = builder.buildUri();

      expect(uri.queryParameters['cursor'], equals('12345'));
      expect(uri.queryParameters['limit'], equals('100'));
    });
  });

  group('TradesRequestBuilder', () {
    test('forAccount sets path segments correctly', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/trades'));
    });

    test('baseAsset adds base asset parameters', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('BTC', testIssuerId);
      builder.baseAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['base_asset_code'], equals('BTC'));
      expect(uri.queryParameters['base_asset_issuer'], equals(testIssuerId));
    });

    test('counterAsset adds counter asset parameters', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.counterAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['counter_asset_type'], equals('native'));
    });

    test('combining base and counter assets', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final baseAsset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      final counterAsset = Asset.NATIVE;
      builder.baseAsset(baseAsset).counterAsset(counterAsset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['base_asset_code'], equals('USD'));
      expect(uri.queryParameters['counter_asset_type'], equals('native'));
    });

    test('offerId adds offer_id query parameter', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.offerId('12345');
      final uri = builder.buildUri();

      expect(uri.queryParameters['offer_id'], equals('12345'));
    });

    test('tradeType adds trade_type query parameter', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.tradeType('orderbook');
      final uri = builder.buildUri();

      expect(uri.queryParameters['trade_type'], equals('orderbook'));
    });
  });

  group('EffectsRequestBuilder', () {
    test('forAccount sets path segments correctly', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/effects'));
    });

    test('forLedger sets path segments with ledger number', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forLedger(555555);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/555555/effects'));
    });

    test('forTransaction sets path segments with tx id', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      final txId = 'abcdef1234567890';
      builder.forTransaction(txId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/$txId/effects'));
    });

    test('forOperation sets path segments with operation id', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forOperation('98765432109876');
      final uri = builder.buildUri();

      expect(uri.path, contains('/operations/98765432109876/effects'));
    });

    test('combining forLedger with pagination', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forLedger(123).limit(30).order(RequestBuilderOrder.ASC);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/123/effects'));
      expect(uri.queryParameters['limit'], equals('30'));
      expect(uri.queryParameters['order'], equals('asc'));
    });
  });

  group('OrderBookRequestBuilder', () {
    test('sellingAsset adds selling asset parameters for native', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      builder.sellingAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('native'));
    });

    test('buyingAsset adds buying asset parameters for credit', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USDC', testIssuerId);
      builder.buyingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['buying_asset_code'], equals('USDC'));
      expect(uri.queryParameters['buying_asset_issuer'], equals(testIssuerId));
    });

    test('combining selling and buying assets', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      final sellAsset = Asset.NATIVE;
      final buyAsset = AssetTypeCreditAlphaNum4('EUR', testIssuerId);
      builder.sellingAsset(sellAsset).buyingAsset(buyAsset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('native'));
      expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['buying_asset_code'], equals('EUR'));
    });

    test('with limit parameter', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      builder.sellingAsset(Asset.NATIVE).buyingAsset(AssetTypeCreditAlphaNum4('USD', testIssuerId)).limit(15);
      final uri = builder.buildUri();

      expect(uri.queryParameters['limit'], equals('15'));
    });
  });

  group('PaymentsRequestBuilder', () {
    test('forAccount sets path segments correctly', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/payments'));
    });

    test('forLedger sets path segments with ledger number', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      builder.forLedger(999888);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/999888/payments'));
    });

    test('forTransaction sets path segments with tx id', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      final txId = 'payment_tx_hash_123';
      builder.forTransaction(txId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/$txId/payments'));
    });

    test('combining forAccount with order and limit', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId).order(RequestBuilderOrder.DESC).limit(100);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/$testAccountId/payments'));
      expect(uri.queryParameters['order'], equals('desc'));
      expect(uri.queryParameters['limit'], equals('100'));
    });
  });

  group('TradeAggregationsRequestBuilder', () {
    test('constructor sets all required parameters', () {
      final baseAsset = Asset.NATIVE;
      final counterAsset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      final startTime = 1609459200000;
      final endTime = 1609545600000;
      final resolution = 3600000;
      final offset = 0;

      final builder = TradeAggregationsRequestBuilder(
        httpClient,
        serverUri,
        baseAsset,
        counterAsset,
        startTime,
        endTime,
        resolution,
        offset,
      );
      final uri = builder.buildUri();

      expect(uri.path, contains('/trade_aggregations'));
      expect(uri.queryParameters['base_asset_type'], equals('native'));
      expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['counter_asset_code'], equals('USD'));
      expect(uri.queryParameters['start_time'], equals(startTime.toString()));
      expect(uri.queryParameters['end_time'], equals(endTime.toString()));
      expect(uri.queryParameters['resolution'], equals(resolution.toString()));
      expect(uri.queryParameters['offset'], equals(offset.toString()));
    });

    test('with both credit assets', () {
      final baseAsset = AssetTypeCreditAlphaNum4('BTC', testIssuerId);
      final counterAsset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      final startTime = 1609459200000;
      final endTime = 1609545600000;
      final resolution = 86400000;
      final offset = 0;

      final builder = TradeAggregationsRequestBuilder(
        httpClient,
        serverUri,
        baseAsset,
        counterAsset,
        startTime,
        endTime,
        resolution,
        offset,
      );
      final uri = builder.buildUri();

      expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['base_asset_code'], equals('BTC'));
      expect(uri.queryParameters['counter_asset_code'], equals('USD'));
    });
  });

  group('ClaimableBalanceRequestBuilder', () {
    test('forClaimant adds claimant query parameter', () {
      final builder = ClaimableBalancesRequestBuilder(httpClient, serverUri);
      builder.forClaimant(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['claimant'], equals(testAccountId));
    });

    test('forSponsor adds sponsor query parameter', () {
      final builder = ClaimableBalancesRequestBuilder(httpClient, serverUri);
      builder.forSponsor(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['sponsor'], equals(testAccountId));
    });

    test('forAsset adds asset query parameter for native', () {
      final builder = ClaimableBalancesRequestBuilder(httpClient, serverUri);
      builder.forAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], equals('native'));
    });

    test('forAsset adds asset query parameter for credit', () {
      final builder = ClaimableBalancesRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('GOLD', testIssuerId);
      builder.forAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], contains('GOLD'));
      expect(uri.queryParameters['asset'], contains(testIssuerId));
    });

    test('combining multiple filters', () {
      final builder = ClaimableBalancesRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('XLM', testIssuerId);
      builder.forClaimant(testAccountId).forAsset(asset).limit(25);
      final uri = builder.buildUri();

      expect(uri.queryParameters['claimant'], equals(testAccountId));
      expect(uri.queryParameters['asset'], contains('XLM'));
      expect(uri.queryParameters['limit'], equals('25'));
    });
  });

  group('StrictReceivePathsRequestBuilder', () {
    test('sourceAccount adds source_account parameter', () {
      final builder = StrictReceivePathsRequestBuilder(httpClient, serverUri);
      builder.sourceAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/paths/strict-receive'));
      expect(uri.queryParameters['source_account'], equals(testAccountId));
    });

    test('destinationAmount adds destination_amount parameter', () {
      final builder = StrictReceivePathsRequestBuilder(httpClient, serverUri);
      builder.destinationAmount('100.50');
      final uri = builder.buildUri();

      expect(uri.queryParameters['destination_amount'], equals('100.50'));
    });

    test('destinationAsset adds destination asset parameters', () {
      final builder = StrictReceivePathsRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.destinationAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['destination_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['destination_asset_code'], equals('USD'));
      expect(uri.queryParameters['destination_asset_issuer'], equals(testIssuerId));
    });

    test('complete path request with all parameters', () {
      final builder = StrictReceivePathsRequestBuilder(httpClient, serverUri);
      final destAsset = AssetTypeCreditAlphaNum4('EUR', testIssuerId);
      builder
        .sourceAccount(testAccountId)
        .destinationAmount('250.00')
        .destinationAsset(destAsset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['source_account'], equals(testAccountId));
      expect(uri.queryParameters['destination_amount'], equals('250.00'));
      expect(uri.queryParameters['destination_asset_code'], equals('EUR'));
    });
  });

  group('StrictSendPathsRequestBuilder', () {
    test('destinationAccount adds destination_account parameter', () {
      final builder = StrictSendPathsRequestBuilder(httpClient, serverUri);
      builder.destinationAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/paths/strict-send'));
      expect(uri.queryParameters['destination_account'], equals(testAccountId));
    });

    test('sourceAmount adds source_amount parameter', () {
      final builder = StrictSendPathsRequestBuilder(httpClient, serverUri);
      builder.sourceAmount('500.75');
      final uri = builder.buildUri();

      expect(uri.queryParameters['source_amount'], equals('500.75'));
    });

    test('sourceAsset adds source asset parameters', () {
      final builder = StrictSendPathsRequestBuilder(httpClient, serverUri);
      builder.sourceAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['source_asset_type'], equals('native'));
    });

    test('complete path request with all parameters', () {
      final builder = StrictSendPathsRequestBuilder(httpClient, serverUri);
      final srcAsset = AssetTypeCreditAlphaNum4('JPY', testIssuerId);
      builder
        .destinationAccount(testAccountId)
        .sourceAmount('1000.00')
        .sourceAsset(srcAsset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['destination_account'], equals(testAccountId));
      expect(uri.queryParameters['source_amount'], equals('1000.00'));
      expect(uri.queryParameters['source_asset_code'], equals('JPY'));
    });
  });

  group('Common RequestBuilder methods', () {
    test('cursor parameter is added correctly', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.cursor('test_cursor_token');
      final uri = builder.buildUri();

      expect(uri.queryParameters['cursor'], equals('test_cursor_token'));
    });

    test('limit parameter is added correctly', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.limit(200);
      final uri = builder.buildUri();

      expect(uri.queryParameters['limit'], equals('200'));
    });

    test('order ASC parameter is added correctly', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.order(RequestBuilderOrder.ASC);
      final uri = builder.buildUri();

      expect(uri.queryParameters['order'], equals('asc'));
    });

    test('order DESC parameter is added correctly', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      builder.order(RequestBuilderOrder.DESC);
      final uri = builder.buildUri();

      expect(uri.queryParameters['order'], equals('desc'));
    });

    test('chaining cursor, limit, and order together', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder
        .cursor('abc123xyz')
        .limit(75)
        .order(RequestBuilderOrder.ASC);
      final uri = builder.buildUri();

      expect(uri.queryParameters['cursor'], equals('abc123xyz'));
      expect(uri.queryParameters['limit'], equals('75'));
      expect(uri.queryParameters['order'], equals('asc'));
    });

    test('base URI is preserved in built URI', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final uri = builder.buildUri();

      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('horizon-testnet.stellar.org'));
    });
  });

  // ======================================================================
  // From request_builder_deep2_test.dart
  // ======================================================================

  group('AccountsRequestBuilder Deep Testing', () {
    test('forSigner throws exception when forAsset already called', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forAsset(asset);

      expect(
        () => builder.forSigner(testAccountId),
        throwsA(isA<Exception>()),
      );
    });

    test('forAsset throws exception when forSigner already called', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.forSigner(testAccountId);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);

      expect(
        () => builder.forAsset(asset),
        throwsA(isA<Exception>()),
      );
    });

    test('forLiquidityPool with L-prefixed pool ID attempts decode', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forLiquidityPool(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.queryParameters['liquidity_pool'], isNotNull);
      // If decode fails, it falls back to the original ID
    });

    test('forLiquidityPool with hex pool ID', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.forLiquidityPool(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(
          uri.queryParameters['liquidity_pool'], equals(testLiquidityPoolId));
    });

    test('forSponsor can be combined with forAsset', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forAsset(asset).forSponsor(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], isNotNull);
      expect(uri.queryParameters['sponsor'], equals(testAccountId));
    });

    test('forSponsor can be combined with forSigner', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.forSigner(testAccountId).forSponsor(testIssuerId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['signer'], equals(testAccountId));
      expect(uri.queryParameters['sponsor'], equals(testIssuerId));
    });

    test('cursor returns builder instance for chaining', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
      expect(builder.buildUri().queryParameters['cursor'], equals('test_cursor'));
    });

    test('limit returns builder instance for chaining', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(50);

      expect(result, same(builder));
      expect(builder.buildUri().queryParameters['limit'], equals('50'));
    });

    test('order returns builder instance for chaining', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.ASC);

      expect(result, same(builder));
      expect(builder.buildUri().queryParameters['order'], equals('asc'));
    });

    test('stream returns a stream', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<AccountResponse>>());
    });

    test('forAsset with AlphaNum12 asset', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum12('LONGERNAME', testIssuerId);
      builder.forAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['asset'], equals('LONGERNAME:$testIssuerId'));
    });
  });

  group('LiquidityPoolsRequestBuilder Deep Testing', () {
    test('forReserveAssets with native and credit asset', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final assetA = Asset.NATIVE;
      final assetB = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forReserveAssets(assetA, assetB);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], contains('native'));
      expect(uri.queryParameters['reserves'], contains(','));
    });

    test('forReserveAssets with two credit assets', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final assetA = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      final assetB = AssetTypeCreditAlphaNum4('EUR', testIssuerId);
      builder.forReserveAssets(assetA, assetB);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], contains('USD'));
      expect(uri.queryParameters['reserves'], contains('EUR'));
      expect(uri.queryParameters['reserves'], contains(','));
    });

    test('forAccount returns builder instance for chaining', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final result = builder.forAccount(testAccountId);

      expect(result, same(builder));
    });

    test('cursor returns builder instance for chaining', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns builder instance for chaining', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(100);

      expect(result, same(builder));
    });

    test('order returns builder instance for chaining', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });

    test('combining forReserveAssets with pagination', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final assetA = Asset.NATIVE;
      final assetB = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder
          .forReserveAssets(assetA, assetB)
          .cursor('cursor123')
          .limit(25)
          .order(RequestBuilderOrder.ASC);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], isNotNull);
      expect(uri.queryParameters['cursor'], equals('cursor123'));
      expect(uri.queryParameters['limit'], equals('25'));
      expect(uri.queryParameters['order'], equals('asc'));
    });
  });

  group('LiquidityPoolTradesRequestBuilder Deep Testing', () {
    test('forPoolId sets path segments correctly', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      builder.forPoolId(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/trades'));
    });

    test('forPoolId with L-prefixed ID', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forPoolId(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/trades'));
    });

    test('cursor returns builder instance for chaining', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('trade_cursor');

      expect(result, same(builder));
    });

    test('limit returns builder instance for chaining', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final result = builder.limit(50);

      expect(result, same(builder));
    });

    test('order returns builder instance for chaining', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });
  });

  group('OffersRequestBuilder Deep Testing', () {
    test('forAccount sets path segments correctly', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains('/offers'));
    });

    test('forSeller adds seller query parameter', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forSeller(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['seller'], equals(testAccountId));
    });

    test('forBuyingAsset with native asset', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forBuyingAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('native'));
      expect(uri.queryParameters['buying_asset_code'], isNull);
      expect(uri.queryParameters['buying_asset_issuer'], isNull);
    });

    test('forBuyingAsset with credit AlphaNum4', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forBuyingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'],
          equals('credit_alphanum4'));
      expect(uri.queryParameters['buying_asset_code'], equals('USD'));
      expect(uri.queryParameters['buying_asset_issuer'], equals(testIssuerId));
    });

    test('forBuyingAsset with credit AlphaNum12', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum12('LONGASSET', testIssuerId);
      builder.forBuyingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'],
          equals('credit_alphanum12'));
      expect(uri.queryParameters['buying_asset_code'], equals('LONGASSET'));
      expect(
          uri.queryParameters['buying_asset_issuer'], equals(testIssuerId));
    });

    test('forSellingAsset with native asset', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forSellingAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('native'));
      expect(uri.queryParameters['selling_asset_code'], isNull);
      expect(uri.queryParameters['selling_asset_issuer'], isNull);
    });

    test('forSellingAsset with credit asset', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('EUR', testIssuerId);
      builder.forSellingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'],
          equals('credit_alphanum4'));
      expect(uri.queryParameters['selling_asset_code'], equals('EUR'));
      expect(
          uri.queryParameters['selling_asset_issuer'], equals(testIssuerId));
    });

    test('forSponsor adds sponsor query parameter', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forSponsor(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['sponsor'], equals(testAccountId));
    });

    test('trades returns TradesRequestBuilder', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final tradesBuilder = builder.trades('12345');

      expect(tradesBuilder, isA<TradesRequestBuilder>());
    });

    test('stream returns a stream', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<OfferResponse>>());
    });

    test('cursor returns builder instance for chaining', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('offer_cursor');

      expect(result, same(builder));
    });

    test('limit returns builder instance for chaining', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final result = builder.limit(75);

      expect(result, same(builder));
    });

    test('order returns builder instance for chaining', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.ASC);

      expect(result, same(builder));
    });

    test('combining filters with pagination', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder
          .forBuyingAsset(asset)
          .forSeller(testAccountId)
          .limit(10)
          .order(RequestBuilderOrder.DESC);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], isNotNull);
      expect(uri.queryParameters['seller'], equals(testAccountId));
      expect(uri.queryParameters['limit'], equals('10'));
      expect(uri.queryParameters['order'], equals('desc'));
    });
  });

  group('OperationsRequestBuilder Deep Testing', () {
    test('forAccount sets path segments correctly', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains('/operations'));
    });

    test('forClaimableBalance with B-prefixed ID', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final claimableBalanceId =
          'B00000000000000000000000000000000000000000000000000000000000000000000001';
      builder.forClaimableBalance(claimableBalanceId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/claimable_balances/'));
      expect(uri.path, contains('/operations'));
    });

    test('forClaimableBalance with hex ID', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final hexId =
          '000000000000000000000000000000000000000000000000000000000000000000000001';
      builder.forClaimableBalance(hexId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/claimable_balances/'));
      expect(uri.path, contains(hexId));
    });

    test('forLedger sets path segments correctly', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forLedger(12345);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/12345/operations'));
    });

    test('forTransaction sets path segments correctly', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forTransaction(testTransactionId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/'));
      expect(uri.path, contains(testTransactionId));
      expect(uri.path, contains('/operations'));
    });

    test('forLiquidityPool with L-prefixed ID', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forLiquidityPool(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/operations'));
    });

    test('forLiquidityPool with hex ID', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forLiquidityPool(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.path, contains(testLiquidityPoolId));
    });

    test('includeFailed adds query parameter', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('includeFailed with false', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(false);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('false'));
    });

    test('stream returns a stream', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<OperationResponse>>());
    });

    test('cursor returns builder instance for chaining', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('ops_cursor');

      expect(result, same(builder));
    });

    test('limit returns builder instance for chaining', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(200);

      expect(result, same(builder));
    });

    test('order returns builder instance for chaining', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });
  });

  group('TransactionsRequestBuilder Deep Testing', () {
    test('forAccount sets path segments correctly', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains('/transactions'));
    });

    test('forClaimableBalance with B-prefixed ID', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final claimableBalanceId =
          'B00000000000000000000000000000000000000000000000000000000000000000000002';
      builder.forClaimableBalance(claimableBalanceId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/claimable_balances/'));
      expect(uri.path, contains('/transactions'));
    });

    test('forClaimableBalance with hex ID', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final hexId =
          '000000000000000000000000000000000000000000000000000000000000000000000002';
      builder.forClaimableBalance(hexId);
      final uri = builder.buildUri();

      expect(uri.path, contains(hexId));
    });

    test('forLedger sets path segments correctly', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forLedger(54321);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/54321/transactions'));
    });

    test('forLiquidityPool with L-prefixed ID', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forLiquidityPool(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/transactions'));
    });

    test('forLiquidityPool with hex ID', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forLiquidityPool(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.path, contains(testLiquidityPoolId));
    });

    test('includeFailed adds query parameter', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('includeFailed with false', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(false);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('false'));
    });

    test('stream returns a stream', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<TransactionResponse>>());
    });

    test('cursor returns builder instance for chaining', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('tx_cursor');

      expect(result, same(builder));
    });

    test('limit returns builder instance for chaining', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(150);

      expect(result, same(builder));
    });

    test('order returns builder instance for chaining', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.ASC);

      expect(result, same(builder));
    });
  });

  group('LedgersRequestBuilder Deep Testing', () {
    test('ledger sets path segments correctly', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final result = builder.ledger(98765);

      expect(result, isA<Future<LedgerResponse>>());
    });

    test('stream returns a stream', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final stream = builder.stream();

      expect(stream, isA<Stream<LedgerResponse>>());
    });

    test('cursor returns builder instance for chaining', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('ledger_cursor');

      expect(result, same(builder));
    });

    test('limit returns builder instance for chaining', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final result = builder.limit(30);

      expect(result, same(builder));
    });

    test('order returns builder instance for chaining', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });

    test('combining pagination parameters', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      builder.cursor('12345').limit(50).order(RequestBuilderOrder.ASC);
      final uri = builder.buildUri();

      expect(uri.queryParameters['cursor'], equals('12345'));
      expect(uri.queryParameters['limit'], equals('50'));
      expect(uri.queryParameters['order'], equals('asc'));
    });
  });

  // ======================================================================
  // From request_builder_final_test.dart
  // ======================================================================

  group('LiquidityPoolsRequestBuilder Additional Tests', () {
    test('forAccount builds correct URI path segment', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['account'], equals(testAccountId));
      expect(uri.path, contains('/liquidity_pools'));
    });

    test('forReserveAssets with native and credit asset', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final assetA = Asset.NATIVE;
      final assetB = AssetTypeCreditAlphaNum4('USDC', testIssuerId);
      builder.forReserveAssets(assetA, assetB);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], isNotNull);
      expect(uri.queryParameters['reserves'], contains('native'));
      expect(uri.queryParameters['reserves'], contains('USDC'));
    });

    test('forReserveAssets with two credit assets', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final assetA = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      final assetB = AssetTypeCreditAlphaNum12('EURTEST', testIssuerId);
      builder.forReserveAssets(assetA, assetB);
      final uri = builder.buildUri();

      expect(uri.queryParameters['reserves'], isNotNull);
      expect(uri.queryParameters['reserves'], contains('USD'));
      expect(uri.queryParameters['reserves'], contains('EURTEST'));
    });

    test('cursor returns same builder instance', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(25);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = LiquidityPoolsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });
  });

  group('LiquidityPoolTradesRequestBuilder Tests', () {
    test('forPoolId with hex pool ID builds correct path', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      builder.forPoolId(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains(testLiquidityPoolId));
      expect(uri.path, contains('/trades'));
    });

    test('forPoolId with L-prefixed ID attempts decode', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forPoolId(poolIdWithPrefix);
      final uri = builder.buildUri();

      // Should contain the pool ID in the path
      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/trades'));
    });

    test('cursor returns same builder instance', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final result = builder.limit(30);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = LiquidityPoolTradesRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.ASC);

      expect(result, same(builder));
    });
  });

  group('OffersRequestBuilder Additional Tests', () {
    test('offer builds correct path for specific offer', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.offer(testOfferId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/offers/'));
      expect(uri.path, contains(testOfferId));
    });

    test('forAccount builds correct path segments', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains(testAccountId));
      expect(uri.path, contains('/offers'));
    });

    test('forSeller adds seller query parameter', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forSeller(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['seller'], equals(testAccountId));
    });

    test('forBuyingAsset with native asset', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forBuyingAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('native'));
    });

    test('forBuyingAsset with credit asset adds code and issuer', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      builder.forBuyingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['buying_asset_code'], equals('USD'));
      expect(uri.queryParameters['buying_asset_issuer'], equals(testIssuerId));
    });

    test('forSellingAsset with credit asset adds code and issuer', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum12('EURTEST', testIssuerId);
      builder.forSellingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum12'));
      expect(uri.queryParameters['selling_asset_code'], equals('EURTEST'));
      expect(uri.queryParameters['selling_asset_issuer'], equals(testIssuerId));
    });

    test('forSponsor adds sponsor query parameter', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      builder.forSponsor(testAccountId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['sponsor'], equals(testAccountId));
    });

    test('trades returns TradesRequestBuilder with correct path', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final tradesBuilder = builder.trades(testOfferId);

      expect(tradesBuilder, isA<TradesRequestBuilder>());
      final uri = tradesBuilder.buildUri();
      expect(uri.path, contains('/offers/'));
      expect(uri.path, contains(testOfferId));
      expect(uri.path, contains('/trades'));
    });

    test('cursor returns same builder instance', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final result = builder.limit(40);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = OffersRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });
  });

  group('OperationsRequestBuilder Additional Tests', () {
    test('forAccount builds correct path segments', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains(testAccountId));
      expect(uri.path, contains('/operations'));
    });

    test('forClaimableBalance with hex ID builds correct path', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forClaimableBalance(testClaimableBalanceId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/claimable_balances/'));
      expect(uri.path, contains(testClaimableBalanceId));
      expect(uri.path, contains('/operations'));
    });

    test('forClaimableBalance with B-prefixed ID attempts decode', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final balanceIdWithPrefix =
          'B00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072';
      builder.forClaimableBalance(balanceIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/claimable_balances/'));
      expect(uri.path, contains('/operations'));
    });

    test('forLedger builds correct path segments', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forLedger(12345);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/'));
      expect(uri.path, contains('12345'));
      expect(uri.path, contains('/operations'));
    });

    test('forTransaction builds correct path segments', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forTransaction(testTransactionId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/'));
      expect(uri.path, contains(testTransactionId));
      expect(uri.path, contains('/operations'));
    });

    test('forLiquidityPool with hex ID builds correct path', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.forLiquidityPool(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains(testLiquidityPoolId));
      expect(uri.path, contains('/operations'));
    });

    test('forLiquidityPool with L-prefixed ID attempts decode', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forLiquidityPool(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/operations'));
    });

    test('includeFailed adds query parameter', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('includeFailed with false value', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(false);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('false'));
    });

    test('cursor returns same builder instance', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(35);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = OperationsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.ASC);

      expect(result, same(builder));
    });
  });

  group('TransactionsRequestBuilder Additional Tests', () {
    test('forAccount builds correct path segments', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains(testAccountId));
      expect(uri.path, contains('/transactions'));
    });

    test('forClaimableBalance with hex ID builds correct path', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forClaimableBalance(testClaimableBalanceId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/claimable_balances/'));
      expect(uri.path, contains(testClaimableBalanceId));
      expect(uri.path, contains('/transactions'));
    });

    test('forClaimableBalance with B-prefixed ID attempts decode', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final balanceIdWithPrefix =
          'B00000000929b20b72e5890ab51c24f1cc46fa01c4f318d8d33367d24dd614cfdf5491072';
      builder.forClaimableBalance(balanceIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/claimable_balances/'));
      expect(uri.path, contains('/transactions'));
    });

    test('forLedger builds correct path segments', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forLedger(67890);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/'));
      expect(uri.path, contains('67890'));
      expect(uri.path, contains('/transactions'));
    });

    test('forLiquidityPool with hex ID builds correct path', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.forLiquidityPool(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains(testLiquidityPoolId));
      expect(uri.path, contains('/transactions'));
    });

    test('forLiquidityPool with L-prefixed ID attempts decode', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forLiquidityPool(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/transactions'));
    });

    test('includeFailed adds query parameter', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(true);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('true'));
    });

    test('includeFailed with false value', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      builder.includeFailed(false);
      final uri = builder.buildUri();

      expect(uri.queryParameters['include_failed'], equals('false'));
    });

    test('cursor returns same builder instance', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(45);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = TransactionsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });
  });

  group('TradesRequestBuilder Additional Tests', () {
    test('baseAsset with native asset adds query parameter', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.baseAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['base_asset_type'], equals('native'));
    });

    test('baseAsset with credit asset adds code and issuer', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('BTC', testIssuerId);
      builder.baseAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['base_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['base_asset_code'], equals('BTC'));
      expect(uri.queryParameters['base_asset_issuer'], equals(testIssuerId));
    });

    test('counterAsset with native asset adds query parameter', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.counterAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['counter_asset_type'], equals('native'));
    });

    test('counterAsset with credit asset adds code and issuer', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum12('EURTEST', testIssuerId);
      builder.counterAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['counter_asset_type'], equals('credit_alphanum12'));
      expect(uri.queryParameters['counter_asset_code'], equals('EURTEST'));
      expect(uri.queryParameters['counter_asset_issuer'], equals(testIssuerId));
    });

    test('tradeType adds query parameter', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.tradeType('orderbook');
      final uri = builder.buildUri();

      expect(uri.queryParameters['trade_type'], equals('orderbook'));
    });

    test('tradeType with liquidity_pool value', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.tradeType('liquidity_pool');
      final uri = builder.buildUri();

      expect(uri.queryParameters['trade_type'], equals('liquidity_pool'));
    });

    test('forAccount builds correct path segments', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains(testAccountId));
      expect(uri.path, contains('/trades'));
    });

    test('offerId adds query parameter', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.offerId(testOfferId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['offer_id'], equals(testOfferId));
    });

    test('liquidityPoolId with hex ID adds query parameter', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      builder.liquidityPoolId(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.queryParameters['liquidity_pool_id'], equals(testLiquidityPoolId));
    });

    test('liquidityPoolId with L-prefixed ID attempts decode', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.liquidityPoolId(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.queryParameters['liquidity_pool_id'], isNotNull);
    });

    test('cursor returns same builder instance', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final result = builder.limit(55);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = TradesRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.ASC);

      expect(result, same(builder));
    });
  });

  group('EffectsRequestBuilder Additional Tests', () {
    test('forAccount builds correct path segments', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains(testAccountId));
      expect(uri.path, contains('/effects'));
    });

    test('forLedger builds correct path segments', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forLedger(11111);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/'));
      expect(uri.path, contains('11111'));
      expect(uri.path, contains('/effects'));
    });

    test('forTransaction builds correct path segments', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forTransaction(testTransactionId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/'));
      expect(uri.path, contains(testTransactionId));
      expect(uri.path, contains('/effects'));
    });

    test('forOperation builds correct path segments', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forOperation(testOperationId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/operations/'));
      expect(uri.path, contains(testOperationId));
      expect(uri.path, contains('/effects'));
    });

    test('forLiquidityPool with hex ID builds correct path', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      builder.forLiquidityPool(testLiquidityPoolId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains(testLiquidityPoolId));
      expect(uri.path, contains('/effects'));
    });

    test('forLiquidityPool with L-prefixed ID attempts decode', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      final poolIdWithPrefix =
          'LAQHPQVZ5EYYDWUOIJLPQZFQIBZSNBBRMUNX4UPWWKJXWMHJXP4D3WGU';
      builder.forLiquidityPool(poolIdWithPrefix);
      final uri = builder.buildUri();

      expect(uri.path, contains('/liquidity_pools/'));
      expect(uri.path, contains('/effects'));
    });

    test('cursor returns same builder instance', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(60);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = EffectsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });
  });

  group('OrderBookRequestBuilder Additional Tests', () {
    test('sellingAsset with native asset adds query parameters', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      builder.sellingAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('native'));
    });

    test('sellingAsset with credit asset adds code and issuer', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum4('XLM', testIssuerId);
      builder.sellingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['selling_asset_code'], equals('XLM'));
      expect(uri.queryParameters['selling_asset_issuer'], equals(testIssuerId));
    });

    test('buyingAsset with native asset adds query parameters', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      builder.buyingAsset(Asset.NATIVE);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('native'));
    });

    test('buyingAsset with credit asset adds code and issuer', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      final asset = AssetTypeCreditAlphaNum12('TESTASSET', testIssuerId);
      builder.buyingAsset(asset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['buying_asset_type'], equals('credit_alphanum12'));
      expect(uri.queryParameters['buying_asset_code'], equals('TESTASSET'));
      expect(uri.queryParameters['buying_asset_issuer'], equals(testIssuerId));
    });

    test('both sellingAsset and buyingAsset can be set together', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      final sellingAsset = AssetTypeCreditAlphaNum4('USD', testIssuerId);
      final buyingAsset = Asset.NATIVE;
      builder.sellingAsset(sellingAsset).buyingAsset(buyingAsset);
      final uri = builder.buildUri();

      expect(uri.queryParameters['selling_asset_type'], equals('credit_alphanum4'));
      expect(uri.queryParameters['selling_asset_code'], equals('USD'));
      expect(uri.queryParameters['buying_asset_type'], equals('native'));
    });

    test('limit returns same builder instance', () {
      final builder = OrderBookRequestBuilder(httpClient, serverUri);
      final result = builder.limit(15);

      expect(result, same(builder));
    });
  });

  group('PaymentsRequestBuilder Additional Tests', () {
    test('forAccount builds correct path segments', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      builder.forAccount(testAccountId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains(testAccountId));
      expect(uri.path, contains('/payments'));
    });

    test('forLedger builds correct path segments', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      builder.forLedger(22222);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/'));
      expect(uri.path, contains('22222'));
      expect(uri.path, contains('/payments'));
    });

    test('forTransaction builds correct path segments', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      builder.forTransaction(testTransactionId);
      final uri = builder.buildUri();

      expect(uri.path, contains('/transactions/'));
      expect(uri.path, contains(testTransactionId));
      expect(uri.path, contains('/payments'));
    });

    test('cursor returns same builder instance', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      final result = builder.limit(65);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = PaymentsRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.ASC);

      expect(result, same(builder));
    });
  });

  group('LedgersRequestBuilder Additional Tests', () {
    test('ledger builds correct path for specific ledger', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      builder.ledger(33333);
      final uri = builder.buildUri();

      expect(uri.path, contains('/ledgers/'));
      expect(uri.path, contains('33333'));
    });

    test('cursor returns same builder instance', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final result = builder.cursor('test_cursor');

      expect(result, same(builder));
    });

    test('limit returns same builder instance', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final result = builder.limit(70);

      expect(result, same(builder));
    });

    test('order returns same builder instance', () {
      final builder = LedgersRequestBuilder(httpClient, serverUri);
      final result = builder.order(RequestBuilderOrder.DESC);

      expect(result, same(builder));
    });
  });

  group('AccountsRequestBuilder Additional Tests', () {
    test('accountData builds correct path segments', () {
      final builder = AccountsRequestBuilder(httpClient, serverUri);
      builder.accountData(testAccountId, 'my_data_key');
      final uri = builder.buildUri();

      expect(uri.path, contains('/accounts/'));
      expect(uri.path, contains(testAccountId));
      expect(uri.path, contains('/data/'));
      expect(uri.path, contains('my_data_key'));
    });
  });
}
