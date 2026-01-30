@Timeout(const Duration(seconds: 400))
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final quoteServer = "http://api.stellar.org/query";

  String getInfoResponseSuccess() {
    return "{  \"assets\":  [    {      \"asset\": \"stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN\"    },    {      \"asset\": \"stellar:BRL:GDVKY2GU2DRXWTBEYJJWSFXIGBZV6AZNBVVSUHEPZI54LIS6BA7DVVSP\"    },    {      \"asset\": \"iso4217:BRL\",      \"country_codes\": [\"BRA\"],      \"sell_delivery_methods\": [        {          \"name\": \"cash\",          \"description\": \"Deposit cash BRL at one of our agent locations.\"        },        {          \"name\": \"ACH\",          \"description\": \"Send BRL directly to the Anchor's bank account.\"        },        {          \"name\": \"PIX\",          \"description\": \"Send BRL directly to the Anchor's bank account.\"        }      ],      \"buy_delivery_methods\": [        {          \"name\": \"cash\",          \"description\": \"Pick up cash BRL at one of our payout locations.\"        },        {          \"name\": \"ACH\",          \"description\": \"Have BRL sent directly to your bank account.\"        },        {          \"name\": \"PIX\",          \"description\": \"Have BRL sent directly to the account of your choice.\"        }      ]    }  ]}";
  }

  String getPricesResponseSuccess() {
    return "{  \"buy_assets\": [    {      \"asset\": \"iso4217:BRL\",      \"price\": \"0.18\",      \"decimals\": 2    }  ]}";
  }

  String getPrice1ResponseSuccess() {
    return "{  \"total_price\": \"5.42\",  \"price\": \"5.00\",  \"sell_amount\": \"542\",  \"buy_amount\": \"100\",  \"fee\": {    \"total\": \"42.00\",    \"asset\": \"iso4217:BRL\"  }}";
  }

  String getPrice2ResponseSuccess() {
    return "{  \"total_price\": \"5.42\",  \"price\": \"5.00\",  \"sell_amount\": \"542\",  \"buy_amount\": \"100\",  \"fee\": {    \"total\": \"8.40\",    \"asset\": \"stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN\",    \"details\": [      {        \"name\": \"Service fee\",        \"amount\": \"8.40\"      }    ]  }}";
  }

  String getPrice3ResponseSuccess() {
    return "{  \"total_price\": \"0.20\",  \"price\": \"0.18\",  \"sell_amount\": \"100\",  \"buy_amount\": \"500\",  \"fee\": {    \"total\": \"55.5556\",    \"asset\": \"iso4217:BRL\",    \"details\": [      {        \"name\": \"PIX fee\",        \"description\": \"Fee charged in order to process the outgoing PIX transaction.\",        \"amount\": \"55.5556\"      }    ]  }}";
  }

  String getPrice4ResponseSuccess() {
    return "{  \"total_price\": \"0.20\",  \"price\": \"0.18\",  \"sell_amount\": \"100\",  \"buy_amount\": \"500\",  \"fee\": {    \"total\": \"10.00\",    \"asset\": \"stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN\",    \"details\": [      {        \"name\": \"Service fee\",        \"amount\": \"5.00\"      },      {        \"name\": \"PIX fee\",        \"description\": \"Fee charged in order to process the outgoing BRL PIX transaction.\",        \"amount\": \"5.00\"      }    ]  }}";
  }

  String firmQuoteResponseSuccess() {
    return "{\"id\": \"de762cda-a193-4961-861e-57b31fed6eb3\",\"expires_at\": \"2024-02-01T10:40:14+0000\",  \"total_price\": \"5.42\",   \"price\": \"5.00\",  \"sell_asset\": \"iso4217:BRL\",  \"sell_amount\": \"542\",  \"buy_asset\": \"stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN\",  \"buy_amount\": \"100\",  \"fee\": {    \"total\": \"8.40\",    \"asset\": \"stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN\",    \"details\": [      {        \"name\": \"Service fee\",        \"amount\": \"8.40\"      }    ]  }}";
  }

  final String jwtToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";

  test('test get info', () async {

    final service = SEP38QuoteService(quoteServer);

    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(quoteServer) &&
          request.method == "GET" &&
          request.url.toString().endsWith("info") &&
          authHeader.contains(jwtToken)) {
        return http.Response(getInfoResponseSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP38InfoResponse response = await service.info(jwtToken: jwtToken);
    List<SEP38Asset> assets = response.assets;
    assert(assets.length == 3);
    assert(assets[0].asset ==
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN');
    assert(assets[1].asset ==
        'stellar:BRL:GDVKY2GU2DRXWTBEYJJWSFXIGBZV6AZNBVVSUHEPZI54LIS6BA7DVVSP');
    assert(assets[2].asset == 'iso4217:BRL');
    assert(assets[2].countryCodes != null);
    assert(assets[2].countryCodes!.length == 1);
    assert(assets[2].countryCodes![0] == 'BRA');
    assert(assets[2].sellDeliveryMethods != null);
    assert(assets[2].sellDeliveryMethods!.length == 3);
    assert(assets[2].sellDeliveryMethods![0].name == 'cash');
    assert(assets[2].sellDeliveryMethods![0].description ==
        'Deposit cash BRL at one of our agent locations.');
    assert(assets[2].sellDeliveryMethods![1].name == 'ACH');
    assert(assets[2].sellDeliveryMethods![1].description ==
        "Send BRL directly to the Anchor's bank account.");
    assert(assets[2].sellDeliveryMethods![2].name == 'PIX');
    assert(assets[2].sellDeliveryMethods![2].description ==
        "Send BRL directly to the Anchor's bank account.");
    assert(assets[2].buyDeliveryMethods != null);
    assert(assets[2].buyDeliveryMethods!.length == 3);
    assert(assets[2].buyDeliveryMethods![0].name == 'cash');
    assert(assets[2].buyDeliveryMethods![0].description ==
        'Pick up cash BRL at one of our payout locations.');
    assert(assets[2].buyDeliveryMethods![1].name == 'ACH');
    assert(assets[2].buyDeliveryMethods![1].description ==
        "Have BRL sent directly to your bank account.");
    assert(assets[2].buyDeliveryMethods![2].name == 'PIX');
    assert(assets[2].buyDeliveryMethods![2].description ==
        "Have BRL sent directly to the account of your choice.");
  });

  test('test get prices', () async {
    final service = SEP38QuoteService(quoteServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(quoteServer) &&
          request.method == "GET" &&
          request.url.toString().contains("prices") &&
          request.url.queryParameters.length == 4 &&
          authHeader.contains(jwtToken)) {
        return http.Response(getPricesResponseSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    var sellAsset =
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
    var sellAmount = '100';
    var countryCode = 'BRA';
    var buyDeliveryMethod = 'ACH';

    SEP38PricesResponse response = await service.prices(
        sellAsset: sellAsset,
        sellAmount: sellAmount,
        buyDeliveryMethod: buyDeliveryMethod,
        countryCode: countryCode,
        jwtToken: jwtToken);
    List<SEP38BuyAsset> buyAssets = response.buyAssets;
    assert(buyAssets.length == 1);
    assert(buyAssets[0].asset == 'iso4217:BRL');
    assert(buyAssets[0].price == '0.18');
    assert(buyAssets[0].decimals == 2);
  });

  test('test get price', () async {
    final service = SEP38QuoteService(quoteServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(quoteServer) &&
          request.method == "GET" &&
          request.url.toString().contains("price?") &&
          authHeader.contains(jwtToken)) {
        if (request.url.queryParameters['sell_asset'] == 'iso4217:BRL' &&
            request.url.queryParameters['sell_amount'] == '500') {
          return http.Response(getPrice1ResponseSuccess(), 200); // OK
        } else if (request.url.queryParameters['sell_asset'] == 'iso4217:BRL' &&
            request.url.queryParameters['buy_amount'] == '100') {
          return http.Response(getPrice2ResponseSuccess(), 200); // OK
        } else if (request.url.queryParameters['sell_asset'] ==
                'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN' &&
            request.url.queryParameters['sell_amount'] == '90') {
          return http.Response(getPrice3ResponseSuccess(), 200); // OK
        } else if (request.url.queryParameters['sell_asset'] ==
                'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN' &&
            request.url.queryParameters['buy_amount'] == '500') {
          return http.Response(getPrice4ResponseSuccess(), 200); // OK
        }
      }
      return http.Response(json.encode({'error': "Bad request"}), 400);
    });

    var sellAsset = 'iso4217:BRL';
    var buyAsset =
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
    var sellAmount = '500';
    var sellDeliveryMethod = 'PIX';
    var countryCode = 'BRA';
    var context = 'sep6';

    SEP38PriceResponse response = await service.price(
        context: context,
        sellAsset: sellAsset,
        buyAsset: buyAsset,
        sellAmount: sellAmount,
        sellDeliveryMethod: sellDeliveryMethod,
        countryCode: countryCode,
        jwtToken: jwtToken);

    assert(response.totalPrice == "5.42");
    assert(response.price == "5.00");
    assert(response.sellAmount == "542");
    assert(response.buyAmount == "100");
    var fee = response.fee;
    assert(fee.total == "42.00");
    assert(fee.asset == "iso4217:BRL");

    sellAsset = 'iso4217:BRL';
    buyAsset =
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
    var buyAmount = '100';
    sellDeliveryMethod = 'PIX';
    countryCode = 'BRA';
    context = 'sep31';

    response = await service.price(
        context: context,
        sellAsset: sellAsset,
        buyAsset: buyAsset,
        buyAmount: buyAmount,
        sellDeliveryMethod: sellDeliveryMethod,
        countryCode: countryCode,
        jwtToken: jwtToken);

    assert(response.totalPrice == "5.42");
    assert(response.price == "5.00");
    assert(response.sellAmount == "542");
    assert(response.buyAmount == "100");
    fee = response.fee;
    assert(fee.total == "8.40");
    assert(fee.asset ==
        "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN");
    var feeDetails = fee.details;
    assert(feeDetails != null);
    assert(feeDetails!.length == 1);
    assert(feeDetails![0].name == "Service fee");
    assert(feeDetails![0].amount == "8.40");

    sellAsset =
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
    buyAsset = 'iso4217:BRL';
    sellAmount = '90';
    var buyDeliveryMethod = 'PIX';
    countryCode = 'BRA';
    context = 'sep6';

    response = await service.price(
        context: context,
        sellAsset: sellAsset,
        buyAsset: buyAsset,
        sellAmount: sellAmount,
        buyDeliveryMethod: buyDeliveryMethod,
        countryCode: countryCode,
        jwtToken: jwtToken);

    assert(response.totalPrice == "0.20");
    assert(response.price == "0.18");
    assert(response.sellAmount == "100");
    assert(response.buyAmount == "500");
    fee = response.fee;
    assert(fee.total == "55.5556");
    assert(fee.asset == "iso4217:BRL");
    feeDetails = fee.details;
    assert(feeDetails != null);
    assert(feeDetails!.length == 1);
    assert(feeDetails![0].name == "PIX fee");
    assert(feeDetails![0].description ==
        "Fee charged in order to process the outgoing PIX transaction.");
    assert(feeDetails![0].amount == "55.5556");

    sellAsset =
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
    buyAsset = 'iso4217:BRL';
    buyAmount = '500';
    buyDeliveryMethod = 'PIX';
    countryCode = 'BRA';
    context = 'sep31';

    response = await service.price(
        context: context,
        sellAsset: sellAsset,
        buyAsset: buyAsset,
        buyAmount: buyAmount,
        buyDeliveryMethod: buyDeliveryMethod,
        countryCode: countryCode,
        jwtToken: jwtToken);

    assert(response.totalPrice == "0.20");
    assert(response.price == "0.18");
    assert(response.sellAmount == "100");
    assert(response.buyAmount == "500");
    fee = response.fee;
    assert(fee.total == "10.00");
    assert(fee.asset ==
        "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN");
    feeDetails = fee.details;
    assert(feeDetails != null);
    assert(feeDetails!.length == 2);
    assert(feeDetails![0].name == "Service fee");
    assert(feeDetails![0].description == null);
    assert(feeDetails![0].amount == "5.00");
    assert(feeDetails![1].name == "PIX fee");
    assert(feeDetails![1].description ==
        "Fee charged in order to process the outgoing BRL PIX transaction.");
    assert(feeDetails![1].amount == "5.00");

    var ex = false;
    try {
      response = await service.price(
          context: context,
          sellAsset: sellAsset,
          buyAsset: buyAsset,
          buyAmount: buyAmount,
          sellAmount: sellAmount,
          buyDeliveryMethod: buyDeliveryMethod,
          countryCode: countryCode,
          jwtToken: jwtToken);
    } catch (ArgumentError) {
      // The caller must provide either [sellAmount] or [buyAmount], but not both.
      ex = true;
    }

    assert(ex);

    ex = false;
    try {
      response = await service.price(
          context: context,
          sellAsset: sellAsset,
          buyAsset: buyAsset,
          buyDeliveryMethod: buyDeliveryMethod,
          countryCode: countryCode,
          jwtToken: jwtToken);
    } catch (ArgumentError) {
      // The caller must provide either [sellAmount] or [buyAmount], but not both.
      ex = true;
    }

    assert(ex);
  });

  test('test post quote', () async {
    final service = SEP38QuoteService(quoteServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(quoteServer) &&
          request.method == "POST" &&
          request.url.toString().contains("quote") &&
          authHeader.contains(jwtToken)) {
        var sellAsset = json.decode(request.body)["sell_asset"];
        if (sellAsset == 'iso4217:SAD') {
          return http.Response(
              "{'error':'SAD not allowed'}", 403); // permission denied
        }

        return http.Response(firmQuoteResponseSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    var sellAsset = 'iso4217:BRL';
    var buyAsset =
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
    var buyAmount = '100';
    var expireAfter = DateTime.now();
    var sellDeliveryMethod = 'PIX';
    var countryCode = 'BRA';
    var context = 'sep31';

    var request = SEP38PostQuoteRequest(
        context: context,
        sellAsset: sellAsset,
        buyAsset: buyAsset,
        buyAmount: buyAmount,
        expireAfter: expireAfter,
        sellDeliveryMethod: sellDeliveryMethod,
        countryCode: countryCode);
    SEP38QuoteResponse response = await service.postQuote(request, jwtToken);
    assert(response.id == 'de762cda-a193-4961-861e-57b31fed6eb3');
    assert(response.expiresAt == DateTime.parse('2024-02-01T10:40:14+0000'));
    assert(response.totalPrice == "5.42");
    assert(response.price == "5.00");
    assert(response.sellAsset == sellAsset);
    assert(response.buyAsset == buyAsset);
    assert(response.sellAmount == "542");
    assert(response.buyAmount == buyAmount);

    var fee = response.fee;
    assert(fee.total == "8.40");
    assert(fee.asset ==
        "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN");
    var feeDetails = fee.details;
    assert(feeDetails != null);
    assert(feeDetails!.length == 1);
    assert(feeDetails![0].name == "Service fee");
    assert(feeDetails![0].amount == "8.40");

    var ex = false;
    try {
      request = SEP38PostQuoteRequest(
          context: context,
          sellAsset: sellAsset,
          buyAsset: buyAsset,
          buyAmount: buyAmount,
          sellAmount: "542",
          expireAfter: expireAfter,
          sellDeliveryMethod: sellDeliveryMethod,
          countryCode: countryCode);
      response = await service.postQuote(request, jwtToken);
    } catch (ArgumentError) {
      ex = true;
    }

    assert(ex);

    ex = false;
    try {
      request = SEP38PostQuoteRequest(
          context: context,
          sellAsset: sellAsset,
          buyAsset: buyAsset,
          expireAfter: expireAfter,
          sellDeliveryMethod: sellDeliveryMethod,
          countryCode: countryCode);
      response = await service.postQuote(request, jwtToken);
    } catch (ArgumentError) {
      ex = true;
    }

    ex = false;
    try {
      request = SEP38PostQuoteRequest(
          context: context,
          sellAsset: "iso4217:SAD",
          buyAsset: buyAsset,
          buyAmount: buyAmount,
          expireAfter: expireAfter,
          sellDeliveryMethod: sellDeliveryMethod,
          countryCode: countryCode);
      response = await service.postQuote(request, jwtToken);
    } catch (SEP38PermissionDenied) {
      ex = true;
    }
  });

  test('test get quote', () async {
    final service = SEP38QuoteService(quoteServer);
    service.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(quoteServer) &&
          request.method == "GET" &&
          request.url
              .toString()
              .endsWith("quote/de762cda-a193-4961-861e-57b31fed6eb3") &&
          authHeader.contains(jwtToken)) {
        return http.Response(firmQuoteResponseSuccess(), 200); // OK
      }
      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    SEP38QuoteResponse response = await service.getQuote(
        'de762cda-a193-4961-861e-57b31fed6eb3', jwtToken);
    assert(response.id == 'de762cda-a193-4961-861e-57b31fed6eb3');
    assert(response.expiresAt == DateTime.parse('2024-02-01T10:40:14+0000'));
    assert(response.totalPrice == "5.42");
    assert(response.price == "5.00");
    assert(response.sellAsset == 'iso4217:BRL');
    assert(response.buyAsset ==
        'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN');
    assert(response.sellAmount == "542");
    assert(response.buyAmount == "100");

    var fee = response.fee;
    assert(fee.total == "8.40");
    assert(fee.asset ==
        "stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN");
    var feeDetails = fee.details;
    assert(feeDetails != null);
    assert(feeDetails!.length == 1);
    assert(feeDetails![0].name == "Service fee");
    assert(feeDetails![0].amount == "8.40");
  });
}
