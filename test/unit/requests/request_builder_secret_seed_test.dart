// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../secret_seed_variants.dart';

/// Returns the error [call] throws, synchronously or through its future.
Future<Object> errorOf(Object? Function() call) async {
  try {
    await call();
  } catch (e) {
    return e;
  }
  fail('no error thrown');
}

typedef Call = Object? Function(http.Client client, String value);

void main() {
  final variants = SeedVariants();
  final Uri server = Uri.parse('https://horizon.example.org');
  final String account = KeyPair.random().accountId;
  final List<http.BaseRequest> requests = [];
  final http.Client client = MockClient((request) async {
    requests.add(request);
    return http.Response('{}', 404);
  });

  setUp(requests.clear);

  Asset issuedBy(String issuer) => AssetTypeCreditAlphaNum4('USD', issuer);

  // Every method that puts an account id, an asset issuer or a transaction
  // hash into a Horizon URL, with the name its refusal reports and a call
  // that passes the value to it. A filter is followed by the request or the
  // stream it configures.
  final Map<String, (String, Call)> methods = {
    'AccountsRequestBuilder.account': (
      'accountId',
      (c, v) => AccountsRequestBuilder(c, server).account(v),
    ),
    'AccountsRequestBuilder.accountData': (
      'accountId',
      (c, v) => AccountsRequestBuilder(c, server).accountData(v, 'key'),
    ),
    'AccountsRequestBuilder.forSigner': (
      'signerAccountId',
      (c, v) => AccountsRequestBuilder(c, server).forSigner(v).execute(),
    ),
    'AccountsRequestBuilder.forSigner stream': (
      'signerAccountId',
      (c, v) => AccountsRequestBuilder(c, server).forSigner(v).stream(),
    ),
    'AccountsRequestBuilder.forSponsor': (
      'sponsorAccountId',
      (c, v) => AccountsRequestBuilder(c, server).forSponsor(v).execute(),
    ),
    'AccountsRequestBuilder.forAsset': (
      'asset.issuerId',
      (c, v) =>
          AccountsRequestBuilder(c, server).forAsset(issuedBy(v)).execute(),
    ),
    'AssetsRequestBuilder.assetIssuer': (
      'assetIssuer',
      (c, v) => AssetsRequestBuilder(c, server).assetIssuer(v).execute(),
    ),
    'ClaimableBalancesRequestBuilder.forSponsor': (
      'signerAccountId',
      (c, v) =>
          ClaimableBalancesRequestBuilder(c, server).forSponsor(v).execute(),
    ),
    'ClaimableBalancesRequestBuilder.forClaimant': (
      'claimantAccountId',
      (c, v) =>
          ClaimableBalancesRequestBuilder(c, server).forClaimant(v).execute(),
    ),
    'ClaimableBalancesRequestBuilder.forAsset': (
      'asset.issuerId',
      (c, v) => ClaimableBalancesRequestBuilder(
        c,
        server,
      ).forAsset(issuedBy(v)).execute(),
    ),
    'EffectsRequestBuilder.forAccount': (
      'accountId',
      (c, v) => EffectsRequestBuilder(c, server).forAccount(v).execute(),
    ),
    'EffectsRequestBuilder.forAccount stream': (
      'accountId',
      (c, v) => EffectsRequestBuilder(c, server).forAccount(v).stream(),
    ),
    'EffectsRequestBuilder.forTransaction': (
      'transactionId',
      (c, v) => EffectsRequestBuilder(c, server).forTransaction(v).execute(),
    ),
    'LiquidityPoolsRequestBuilder.forAccount': (
      'accountId',
      (c, v) => LiquidityPoolsRequestBuilder(c, server).forAccount(v).execute(),
    ),
    'LiquidityPoolsRequestBuilder.forReserveAssets first asset': (
      'reserveAssetA.issuerId',
      (c, v) => LiquidityPoolsRequestBuilder(
        c,
        server,
      ).forReserveAssets(issuedBy(v), Asset.NATIVE).execute(),
    ),
    'LiquidityPoolsRequestBuilder.forReserveAssets second asset': (
      'reserveAssetB.issuerId',
      (c, v) => LiquidityPoolsRequestBuilder(
        c,
        server,
      ).forReserveAssets(Asset.NATIVE, issuedBy(v)).execute(),
    ),
    'OffersRequestBuilder.forAccount': (
      'accountId',
      (c, v) => OffersRequestBuilder(c, server).forAccount(v).execute(),
    ),
    'OffersRequestBuilder.forAccount stream': (
      'accountId',
      (c, v) => OffersRequestBuilder(c, server).forAccount(v).stream(),
    ),
    'OffersRequestBuilder.forSeller': (
      'seller',
      (c, v) => OffersRequestBuilder(c, server).forSeller(v).execute(),
    ),
    'OffersRequestBuilder.forSponsor': (
      'sponsorAccountId',
      (c, v) => OffersRequestBuilder(c, server).forSponsor(v).execute(),
    ),
    'OffersRequestBuilder.forBuyingAsset': (
      'asset.issuerId',
      (c, v) =>
          OffersRequestBuilder(c, server).forBuyingAsset(issuedBy(v)).execute(),
    ),
    'OffersRequestBuilder.forSellingAsset': (
      'asset.issuerId',
      (c, v) => OffersRequestBuilder(
        c,
        server,
      ).forSellingAsset(issuedBy(v)).execute(),
    ),
    'OperationsRequestBuilder.forAccount': (
      'accountId',
      (c, v) => OperationsRequestBuilder(c, server).forAccount(v).execute(),
    ),
    'OperationsRequestBuilder.forAccount stream': (
      'accountId',
      (c, v) => OperationsRequestBuilder(c, server).forAccount(v).stream(),
    ),
    'OperationsRequestBuilder.forTransaction': (
      'transactionId',
      (c, v) => OperationsRequestBuilder(c, server).forTransaction(v).execute(),
    ),
    'OrderBookRequestBuilder.sellingAsset': (
      'asset.issuerId',
      (c, v) => OrderBookRequestBuilder(
        c,
        server,
      ).sellingAsset(issuedBy(v)).execute(),
    ),
    'OrderBookRequestBuilder.buyingAsset stream': (
      'asset.issuerId',
      (c, v) =>
          OrderBookRequestBuilder(c, server).buyingAsset(issuedBy(v)).stream(),
    ),
    'StrictReceivePathsRequestBuilder.sourceAccount': (
      'accountId',
      (c, v) => StrictReceivePathsRequestBuilder(
        c,
        server,
      ).sourceAccount(v).execute(),
    ),
    'StrictReceivePathsRequestBuilder.sourceAssets': (
      'asset.issuerId',
      (c, v) => StrictReceivePathsRequestBuilder(
        c,
        server,
      ).sourceAssets([Asset.NATIVE, issuedBy(v)]).execute(),
    ),
    'StrictReceivePathsRequestBuilder.destinationAsset': (
      'asset.issuerId',
      (c, v) => StrictReceivePathsRequestBuilder(
        c,
        server,
      ).destinationAsset(issuedBy(v)).execute(),
    ),
    'StrictSendPathsRequestBuilder.destinationAccount': (
      'accountId',
      (c, v) => StrictSendPathsRequestBuilder(
        c,
        server,
      ).destinationAccount(v).execute(),
    ),
    'StrictSendPathsRequestBuilder.destinationAssets': (
      'asset.issuerId',
      (c, v) => StrictSendPathsRequestBuilder(
        c,
        server,
      ).destinationAssets([issuedBy(v)]).execute(),
    ),
    'StrictSendPathsRequestBuilder.sourceAsset': (
      'asset.issuerId',
      (c, v) => StrictSendPathsRequestBuilder(
        c,
        server,
      ).sourceAsset(issuedBy(v)).execute(),
    ),
    'PaymentsRequestBuilder.forAccount': (
      'accountId',
      (c, v) => PaymentsRequestBuilder(c, server).forAccount(v).execute(),
    ),
    'PaymentsRequestBuilder.forAccount stream': (
      'accountId',
      (c, v) => PaymentsRequestBuilder(c, server).forAccount(v).stream(),
    ),
    'PaymentsRequestBuilder.forTransaction': (
      'transactionId',
      (c, v) => PaymentsRequestBuilder(c, server).forTransaction(v).execute(),
    ),
    'TradeAggregationsRequestBuilder base asset': (
      'baseAsset.issuerId',
      (c, v) => TradeAggregationsRequestBuilder(
        c,
        server,
        issuedBy(v),
        Asset.NATIVE,
        0,
        1,
        60000,
        0,
      ).execute(),
    ),
    'TradeAggregationsRequestBuilder counter asset': (
      'counterAsset.issuerId',
      (c, v) => TradeAggregationsRequestBuilder(
        c,
        server,
        Asset.NATIVE,
        issuedBy(v),
        0,
        1,
        60000,
        0,
      ).execute(),
    ),
    'TradesRequestBuilder.baseAsset': (
      'asset.issuerId',
      (c, v) =>
          TradesRequestBuilder(c, server).baseAsset(issuedBy(v)).execute(),
    ),
    'TradesRequestBuilder.counterAsset': (
      'asset.issuerId',
      (c, v) =>
          TradesRequestBuilder(c, server).counterAsset(issuedBy(v)).execute(),
    ),
    'TradesRequestBuilder.forAccount': (
      'accountId',
      (c, v) => TradesRequestBuilder(c, server).forAccount(v).execute(),
    ),
    'TradesRequestBuilder.forAccount stream': (
      'accountId',
      (c, v) => TradesRequestBuilder(c, server).forAccount(v).stream(),
    ),
    'TransactionsRequestBuilder.transaction': (
      'transactionId',
      (c, v) => TransactionsRequestBuilder(c, server).transaction(v),
    ),
    'TransactionsRequestBuilder.forAccount': (
      'accountId',
      (c, v) => TransactionsRequestBuilder(c, server).forAccount(v).execute(),
    ),
    'TransactionsRequestBuilder.forAccount stream': (
      'accountId',
      (c, v) => TransactionsRequestBuilder(c, server).forAccount(v).stream(),
    ),
  };

  // The methods whose existing id check refuses a value that starts with S.
  final Map<String, Call> idMethods = {
    'ClaimableBalancesRequestBuilder.forBalanceId': (c, v) =>
        ClaimableBalancesRequestBuilder(c, server).forBalanceId(v),
    'OperationsRequestBuilder.forClaimableBalance': (c, v) =>
        OperationsRequestBuilder(c, server).forClaimableBalance(v).execute(),
    'TransactionsRequestBuilder.forClaimableBalance': (c, v) =>
        TransactionsRequestBuilder(c, server).forClaimableBalance(v).execute(),
    'AccountsRequestBuilder.forLiquidityPool': (c, v) =>
        AccountsRequestBuilder(c, server).forLiquidityPool(v).execute(),
    'EffectsRequestBuilder.forLiquidityPool': (c, v) =>
        EffectsRequestBuilder(c, server).forLiquidityPool(v).execute(),
    'OperationsRequestBuilder.forLiquidityPool': (c, v) =>
        OperationsRequestBuilder(c, server).forLiquidityPool(v).execute(),
    'TransactionsRequestBuilder.forLiquidityPool': (c, v) =>
        TransactionsRequestBuilder(c, server).forLiquidityPool(v).execute(),
    'LiquidityPoolsRequestBuilder.forPoolId': (c, v) =>
        LiquidityPoolsRequestBuilder(c, server).forPoolId(v),
    'LiquidityPoolTradesRequestBuilder.forPoolId': (c, v) =>
        LiquidityPoolTradesRequestBuilder(c, server).forPoolId(v).execute(),
    'TradesRequestBuilder.liquidityPoolId': (c, v) =>
        TradesRequestBuilder(c, server).liquidityPoolId(v).execute(),
  };

  for (final MapEntry(key: method, value: (name, call)) in methods.entries) {
    test('$method refuses every seed variant before a request', () async {
      for (final MapEntry(key: variant, value: value) in variants.all.entries) {
        final Object error = await errorOf(() => call(client, value));
        expect(
          error,
          isA<ArgumentError>()
              .having((e) => e.name, 'name', name)
              .having(
                (e) => e.message,
                'message',
                'got ${variants.keyWording(value)}, which is not sent to '
                    'Horizon',
              )
              .having((e) => e.toString(), 'text', leavesOut(value)),
          reason: variant,
        );
      }
      expect(requests, isEmpty);
    });
  }

  for (final MapEntry(key: method, value: call) in idMethods.entries) {
    test('$method refuses every seed variant before a request', () async {
      for (final MapEntry(key: variant, value: value) in variants.all.entries) {
        final Object error = await errorOf(() => call(client, value));
        expect(
          error,
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'text',
            allOf(contains(variants.keyWording(value)), leavesOut(value)),
          ),
          reason: variant,
        );
      }
      expect(requests, isEmpty);
    });
  }

  test('a valid account id, issuer and id reach the request', () async {
    const String hash =
        '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889';
    final Map<Call, String> sent = {
      (c, v) => AccountsRequestBuilder(c, server).account(v):
          '$server/accounts/$account',
      (c, v) => AccountsRequestBuilder(c, server).forSigner(v).execute():
          '$server/accounts?signer=$account',
      (c, v) => OffersRequestBuilder(
            c,
            server,
          ).forBuyingAsset(issuedBy(v)).execute():
          '$server/offers?buying_asset_type=credit_alphanum4'
          '&buying_asset_code=USD&buying_asset_issuer=$account',
      (c, v) => PaymentsRequestBuilder(c, server).forAccount(v).execute():
          '$server/accounts/$account/payments',
    };
    for (final MapEntry(key: call, value: url) in sent.entries) {
      requests.clear();
      expect(await errorOf(() => call(client, account)), isA<ErrorResponse>());
      expect(requests.single.url.toString(), url);
    }
    for (final MapEntry(key: call, value: url) in {
      (http.Client c) =>
              TransactionsRequestBuilder(c, server).transaction(hash):
          '$server/transactions/$hash',
      (http.Client c) =>
              TradesRequestBuilder(c, server).offerId('123').execute():
          '$server/trades?offer_id=123',
    }.entries) {
      requests.clear();
      expect(await errorOf(() => call(client)), isA<ErrorResponse>());
      expect(requests.single.url.toString(), url);
    }
  });

  test('a data entry name and an asset code that start with S are sent '
      'as given', () async {
    final Map<Object? Function(), String> sent = {
      () => AccountsRequestBuilder(client, server).accountData(account, 'Sig'):
          '$server/accounts/$account/data/Sig',
      () => AssetsRequestBuilder(client, server).assetCode('SHIB').execute():
          '$server/assets?asset_code=SHIB',
      () => AccountsRequestBuilder(
            client,
            server,
          ).forAsset(AssetTypeCreditAlphaNum4('SHIB', account)).execute():
          '$server/accounts?asset=SHIB%3A$account',
    };
    for (final MapEntry(key: call, value: url) in sent.entries) {
      requests.clear();
      expect(await errorOf(call), isA<ErrorResponse>());
      expect(requests.single.url.toString(), url);
    }
  });

  test('account and transaction throw at the call, accountData fails its '
      'future', () async {
    final String seed = variants.seed;
    final Map<String, Object? Function()> synchronous = {
      'account': () => AccountsRequestBuilder(client, server).account(seed),
      'transaction': () =>
          TransactionsRequestBuilder(client, server).transaction(seed),
    };
    for (final MapEntry(key: method, value: call) in synchronous.entries) {
      Object? returned;
      Object? thrown;
      try {
        returned = call();
      } catch (e) {
        thrown = e;
      }
      expect(returned, isNull, reason: method);
      expect(thrown, isA<ArgumentError>(), reason: method);
    }
    late final Future<AccountDataResponse> data;
    expect(() {
      data = AccountsRequestBuilder(client, server).accountData(seed, 'key');
    }, returnsNormally);
    await expectLater(data, throwsA(isA<ArgumentError>()));
    expect(requests, isEmpty);
  });
}
