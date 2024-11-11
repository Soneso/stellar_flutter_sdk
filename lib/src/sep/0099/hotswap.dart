// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/extensions/extensions.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class Hotswap {
  late final String _serverAddress;
  final http.Client _httpClient;
  final StellarSDK _sdk;
  final Network _network;
  final bool _isClientInternal;

  Hotswap(
    String serverAddress, {
    required StellarSDK sdk,
    required Network network,
    http.Client? httpClient,
  })  : _sdk = sdk,
        _network = network,
        _isClientInternal = httpClient == null,
        _httpClient = httpClient ?? http.Client() {
    this._serverAddress = "https://dev.api.mykobo.co/boomerang";
  }

  static Future<Hotswap> fromDomain(
    String domain, {
    required StellarSDK sdk,
    required Network network,
    http.Client? httpClient,
  }) async {
    // StellarToml toml = await StellarToml.fromDomain(
    //   domain,
    //   httpClient: httpClient,
    //   httpRequestHeaders: httpRequestHeaders,
    // );
    // String? hotswapServer = toml.generalInformation.hotswapServer;
    // checkNotNull(
    //   hotswapServer,
    //   "hotswap server not found in stellar toml of domain " + domain,
    // );

    return Hotswap(
      "https://dev.api.mykobo.co/boomerang",
      httpClient: httpClient,
      sdk: sdk,
      network: network,
    );
  }

  Future<List<HotswapRoute>> info() async {
    Uri serverURI = Util.appendEndpointToUrl(_serverAddress, 'info');
    var response = await _httpClient.get(serverURI);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final result = _HotswapInfoResponse.fromJson(json).hotswapRoutes;

    return result;
  }

  Future<Transaction> getSignedTransaction({
    required String accountId,
    required KeyPair signer,
    required HotswapRoute hotswapRoute,
    String toAssetTrustLineLimit = ChangeTrustOperationBuilder.MAX_LIMIT,
  }) async {
    var account = await _sdk.accounts.account(accountId);

    final txBuilder = TransactionBuilder(account);

    final toAsset = hotswapRoute.toAsset.toAsset();
    final trustDestinationAssetOperation = ChangeTrustOperationBuilder(
      toAsset,
      toAssetTrustLineLimit,
    ).build();

    final hotswapHandlerAccountId = hotswapRoute.toAddress;

    final fromAsset = hotswapRoute.fromAsset.toAsset();
    final fromAssetBalanceObject = account.balances.firstWhere(
      (e) =>
          e.assetCode == fromAsset.code && e.assetIssuer == fromAsset.issuerId,
    );
    // Send from asset to the hotswap server
    final depositSourceAssetOperation = PaymentOperationBuilder(
      hotswapHandlerAccountId,
      fromAsset,
      fromAssetBalanceObject.balance,
    ).build();

    // Receive to asset from hotswap server
    final receiveDestinationAssetOperation = PaymentOperationBuilder(
      accountId,
      toAsset,
      fromAssetBalanceObject.balance, // Ensuring a 1:1 exchange
    ).setSourceAccount(hotswapHandlerAccountId).build();

    final untrustSourceAssetOperation = ChangeTrustOperationBuilder(
      fromAsset,
      '0',
    ).build();

    txBuilder
        .addOperation(trustDestinationAssetOperation)
        .addOperation(depositSourceAssetOperation)
        .addOperation(receiveDestinationAssetOperation)
        .addOperation(untrustSourceAssetOperation);

    final transaction = txBuilder.build();

    transaction.sign(signer, _network);

    var transactionXdr = transaction.toEnvelopeXdrBase64();
    var hotswapUrl = Util.appendEndpointToUrl(
      _serverAddress,
      'hotswap',
    ).replace(
      queryParameters: {
        'transaction_xdr': transactionXdr,
      },
    );

    final response = await _httpClient.post(hotswapUrl);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get signed transaction: ${response.statusCode}',
      );
    }

    final signedTransactionResponseData =
        jsonDecode(response.body) as Map<String, dynamic>;
    transactionXdr = signedTransactionResponseData['signed_tx_xdr'] as String;

    final signedTransaction = Transaction.fromV1EnvelopeXdr(
      XdrTransactionEnvelope.fromEnvelopeXdrString(
        transactionXdr,
      ).v1!,
    );
    return signedTransaction;
  }

  void dispose() {
    // Close the client if we created it internally
    if (_isClientInternal) {
      _httpClient.close();
    }
  }
}

class HotswapRoute extends Response {
  final String toAddress;
  final String fromAsset;
  final String toAsset;
  final double minimumAmount;

  HotswapRoute({
    required this.toAddress,
    required this.fromAsset,
    required this.toAsset,
    required this.minimumAmount,
  });

  factory HotswapRoute.fromJson(Map<String, dynamic> json) {
    return HotswapRoute(
      toAddress:
          (json['hotswap_address'] ?? json['receivables_address']) as String,
      fromAsset: (json['from_asset'] ?? json['you_send_asset']) as String,
      toAsset: (json['to_asset'] ?? json['we_send_asset']) as String,
      minimumAmount: double.parse(
        (json['min_amount'] ?? json['minimum_amount']) as String,
      ),
    );
  }
}

class _HotswapInfoResponse {
  final List<HotswapRoute> hotswapRoutes;

  _HotswapInfoResponse({required this.hotswapRoutes});

  factory _HotswapInfoResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('hotswap_routes')) {
      return _HotswapInfoResponse(
        hotswapRoutes: (json['hotswap_routes'] as List)
            .map(
              (route) => HotswapRoute.fromJson(
                route as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    } else {
      // Single hotswap case (legacy)
      // TODO: Remove as soon as MYKOBO has updated their implementation
      return _HotswapInfoResponse(
        hotswapRoutes: [
          HotswapRoute.fromJson(json),
        ],
      );
    }
  }
}
