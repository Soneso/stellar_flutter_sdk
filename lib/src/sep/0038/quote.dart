import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/requests/request_builder.dart';
import 'package:stellar_flutter_sdk/src/sep/0001/stellar_toml.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import '../../responses/response.dart';
import 'dart:convert';

/// Implements SEP-0038 - Anchor RFQ API.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md" target="_blank">Anchor RFQ API.</a>
class SEP38QuoteService {
  String _serviceAddress;
  late http.Client httpClient;

  /// Constructor accepting the [serviceAddress] from the server (ANCHOR_QUOTE_SERVER in stellar.toml).
  /// It also accepts an optional [httpClient] to be used for requests. If not provided, this service will use its own http client.
  SEP38QuoteService(this._serviceAddress, {http.Client? httpClient}) {
    if (httpClient != null) {
      this.httpClient = httpClient;
    } else {
      this.httpClient = http.Client();
    }
  }

  /// Creates an instance of this class by loading the anchor quote server sep 38 url from the given [domain] stellar toml file (ANCHOR_QUOTE_SERVER).
  /// It also accepts an optional [httpClient] to be used for all requests. If not provided, this service will use its own http client.
  static Future<SEP38QuoteService> fromDomain(String domain,
      {http.Client? httpClient}) async {
    StellarToml toml =
        await StellarToml.fromDomain(domain, httpClient: httpClient);
    String? addr = toml.generalInformation.anchorQuoteServer;
    checkNotNull(
        addr, "Anchor quote server SEP 38 not available for domain " + domain);
    return SEP38QuoteService(addr!, httpClient: httpClient);
  }

  /// This endpoint returns the supported Stellar assets and off-chain assets available for trading.
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-info
  /// It also accepts an optional [jwtToken] token obtained before with SEP-0010.
  Future<SEP38InfoResponse> info({String? jwtToken}) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'info');
    Map<String, String> headers = {...RequestBuilder.headers};
    if (jwtToken != null) {
      headers["Authorization"] = "Bearer " + jwtToken;
    }
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP38InfoResponse result =
        await httpClient.get(requestURI, headers: headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP38InfoResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP38BadRequest(errorFromResponseBody(response.body));
        default:
          throw new SEP38UnknownResponse(response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// This endpoint can be used to fetch the indicative prices of available off-chain assets in exchange for a Stellar asset and vice versa.
  /// It accepts following parameters:
  /// [sellAsset] The asset you want to sell, using the Asset Identification Format.
  /// [sellAmount] The amount of sell_asset the client would exchange for each of the buy_assets.
  /// [sellDeliveryMethod] Optional, one of the name values specified by the sell_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user is delivering an off-chain asset to the anchor but is not strictly required.
  /// [buyDeliveryMethod] Optional, one of the name values specified by the buy_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user intends to receive an off-chain asset from the anchor but is not strictly required.
  /// [countryCode] Optional, The ISO 3166-2 or ISO-3166-1 alpha-2 code of the user's current address. Should be provided if there are two or more country codes available for the desired asset in GET /info.
  /// It also accepts an optional [jwtToken] token obtained before with SEP-0010.
  Future<SEP38PricesResponse> prices(
      {required String sellAsset,
      required String sellAmount,
      String? sellDeliveryMethod,
      String? buyDeliveryMethod,
      String? countryCode,
      String? jwtToken}) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'prices');
    Map<String, String> queryParameters = {
      'sell_asset': sellAsset,
      'sell_amount': sellAmount
    };
    if (sellDeliveryMethod != null) {
      queryParameters['sell_delivery_method'] = sellDeliveryMethod;
    }
    if (buyDeliveryMethod != null) {
      queryParameters['buy_delivery_method'] = buyDeliveryMethod;
    }
    if (countryCode != null) {
      queryParameters['country_code'] = countryCode;
    }
    requestURI = requestURI.replace(queryParameters: queryParameters);

    Map<String, String> headers = {...RequestBuilder.headers};
    if (jwtToken != null) {
      headers["Authorization"] = "Bearer " + jwtToken;
    }
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP38PricesResponse result =
        await httpClient.get(requestURI, headers: headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP38PricesResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP38BadRequest(errorFromResponseBody(response.body));
        default:
          throw new SEP38UnknownResponse(response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// This endpoint can be used to fetch the indicative price for a given asset pair.
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-price
  /// The client must provide either [sellAmount] or [buyAmount], but not both.
  /// Parameters:
  /// [context] The context for what this quote will be used for. Must be one of 'sep6' or 'sep31'.
  /// [sellAsset] The asset the client would like to sell. Ex. stellar:USDC:G..., iso4217:ARS
  /// [buyAsset] The asset the client would like to exchange for [sellAsset].
  /// [sellAmount] optional, the amount of [sellAsset] the client would like to exchange for [buyAsset].
  /// [buyAmount] optional, the amount of [buyAsset] the client would like to exchange for [sellAsset].
  /// [sellDeliveryMethod] optional, one of the name values specified by the sell_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user is delivering an off-chain asset to the anchor but is not strictly required.
  /// [buyDeliveryMethod] optional, one of the name values specified by the buy_delivery_methods array for the associated asset returned from GET /info. Can be provided if the user intends to receive an off-chain asset from the anchor but is not strictly required.
  /// [countryCode] Optional, The ISO 3166-2 or ISO-3166-1 alpha-2 code of the user's current address. Should be provided if there are two or more country codes available for the desired asset in GET /info.
  /// It also accepts an optional [jwtToken] token obtained before with SEP-0010.
  Future<SEP38PriceResponse> price(
      {required String context,
      required String sellAsset,
      required String buyAsset,
      String? sellAmount,
      String? buyAmount,
      String? sellDeliveryMethod,
      String? buyDeliveryMethod,
      String? countryCode,
      String? jwtToken}) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'price');
    Map<String, String> queryParameters = {
      'sell_asset': sellAsset,
      'buy_asset': buyAsset,
      'context': context,
    };

    if ((sellAmount != null && buyAmount != null) ||
        (sellAmount == null && buyAmount == null)) {
      throw ArgumentError(
          'The caller must provide either [sellAmount] or [buyAmount], but not both.');
    }
    if (sellAmount != null) {
      queryParameters['sell_amount'] = sellAmount;
    }
    if (buyAmount != null) {
      queryParameters['buy_amount'] = buyAmount;
    }
    if (sellDeliveryMethod != null) {
      queryParameters['sell_delivery_method'] = sellDeliveryMethod;
    }
    if (buyDeliveryMethod != null) {
      queryParameters['buy_delivery_method'] = buyDeliveryMethod;
    }
    if (countryCode != null) {
      queryParameters['country_code'] = countryCode;
    }

    requestURI = requestURI.replace(queryParameters: queryParameters);

    Map<String, String> headers = {...RequestBuilder.headers};
    if (jwtToken != null) {
      headers["Authorization"] = "Bearer " + jwtToken;
    }
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP38PriceResponse result =
        await httpClient.get(requestURI, headers: headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP38PriceResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP38BadRequest(errorFromResponseBody(response.body));
        default:
          throw new SEP38UnknownResponse(response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// This endpoint can be used to request a firm quote for a Stellar asset and off-chain asset pair.
  /// Needs [jwtToken] token obtained before with SEP-0010.
  Future<SEP38QuoteResponse> postQuote(
      SEP38PostQuoteRequest request, String jwtToken) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'quote');
    Map<String, String> headers = {...RequestBuilder.headers};
    headers["Authorization"] = "Bearer " + jwtToken;
    headers.putIfAbsent("Content-Type", () => "application/json");

    if ((request.sellAmount != null && request.buyAmount != null) ||
        (request.sellAmount == null && request.buyAmount == null)) {
      throw ArgumentError(
          'The caller must provide either [sellAmount] or [buyAmount], but not both.');
    }

    SEP38QuoteResponse result = await httpClient
        .post(requestURI, body: json.encode(request.toJson()), headers: headers)
        .then((response) {
      switch (response.statusCode) {
        case 201:
        case 200:
          return SEP38QuoteResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP38BadRequest(errorFromResponseBody(response.body));
        case 403:
          throw SEP38PermissionDenied(errorFromResponseBody(response.body));
        default:
          throw new SEP38UnknownResponse(response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// This endpoint can be used to fetch a previously-provided firm quote by [id].
  /// Needs [jwtToken] token obtained before with SEP-0010.
  Future<SEP38QuoteResponse> getQuote(String id, String jwtToken) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'quote/$id');
    Map<String, String> headers = {...RequestBuilder.headers};
    headers["Authorization"] = "Bearer " + jwtToken;
    headers.putIfAbsent("Content-Type", () => "application/json");

    SEP38QuoteResponse result =
        await httpClient.get(requestURI, headers: headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return SEP38QuoteResponse.fromJson(json.decode(response.body));
        case 400:
          throw SEP38BadRequest(errorFromResponseBody(response.body));
        case 403:
          throw SEP38PermissionDenied(errorFromResponseBody(response.body));
        case 404:
          throw SEP38NotFound(errorFromResponseBody(response.body));
        default:
          throw new SEP38UnknownResponse(response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  String errorFromResponseBody(String body) {
    Map<String, dynamic>? res = json.decode(body);
    if (res != null && res["error"] != null) {
      return res["error"];
    }
    return "none";
  }
}

class SEP38PostQuoteRequest {
  String context;
  String sellAsset;
  String buyAsset;
  String? sellAmount;
  String? buyAmount;
  DateTime? expireAfter;
  String? sellDeliveryMethod;
  String? buyDeliveryMethod;
  String? countryCode;

  SEP38PostQuoteRequest(
      {required this.context,
      required this.sellAsset,
      required this.buyAsset,
      this.sellAmount,
      this.buyAmount,
      this.expireAfter,
      this.sellDeliveryMethod,
      this.buyDeliveryMethod,
      this.countryCode});

  Map<String, dynamic> toJson() {
    Map<String, String> result = {
      'sell_asset': sellAsset,
      'buy_asset': buyAsset,
      'context': context
    };

    if (sellAmount != null) {
      result['sell_amount'] = sellAmount!;
    }

    if (buyAmount != null) {
      result['buy_amount'] = buyAmount!;
    }

    if (expireAfter != null) {
      result['expire_after'] = expireAfter!.toIso8601String();
    }

    if (sellDeliveryMethod != null) {
      result['sell_delivery_method'] = sellDeliveryMethod!;
    }

    if (buyDeliveryMethod != null) {
      result['buy_delivery_method'] = buyDeliveryMethod!;
    }

    if (countryCode != null) {
      result['country_code'] = countryCode!;
    }

    return result;
  }
}

class SEP38QuoteResponse {
  String id;
  DateTime expiresAt;
  String totalPrice;
  String price;
  String sellAsset;
  String sellAmount;
  String buyAsset;
  String buyAmount;
  SEP38Fee fee;

  SEP38QuoteResponse(this.id, this.expiresAt, this.totalPrice, this.price,
      this.sellAsset, this.sellAmount, this.buyAsset, this.buyAmount, this.fee);

  factory SEP38QuoteResponse.fromJson(Map<String, dynamic> json) =>
      SEP38QuoteResponse(
          json['id'],
          DateTime.parse(json['expires_at']),
          json['total_price'],
          json['price'],
          json['sell_asset'],
          json['sell_amount'],
          json['buy_asset'],
          json['buy_amount'],
          SEP38Fee.fromJson(json['fee']));
}

class SEP38PriceResponse {
  String totalPrice;
  String price;
  String sellAmount;
  String buyAmount;
  SEP38Fee fee;

  SEP38PriceResponse(
      this.totalPrice, this.price, this.sellAmount, this.buyAmount, this.fee);

  factory SEP38PriceResponse.fromJson(Map<String, dynamic> json) =>
      SEP38PriceResponse(
          json['total_price'],
          json['price'],
          json['sell_amount'],
          json['buy_amount'],
          SEP38Fee.fromJson(json['fee']));
}

class SEP38Fee {
  String total;
  String asset;
  List<SEP38FeeDetails>? details;

  SEP38Fee(this.total, this.asset, {this.details});

  factory SEP38Fee.fromJson(Map<String, dynamic> json) =>
      SEP38Fee(json['total'], json['asset'],
          details: json['details'] == null
              ? null
              : List<SEP38FeeDetails>.from(
                  json['details'].map((e) => SEP38FeeDetails.fromJson(e))));
}

class SEP38FeeDetails {
  String name;
  String amount;
  String? description;

  SEP38FeeDetails(this.name, this.amount, {this.description});

  factory SEP38FeeDetails.fromJson(Map<String, dynamic> json) =>
      SEP38FeeDetails(json['name'], json['amount'],
          description:
              json['description'] == null ? null : json['description']);
}

/// Response of the prices endpoint.
class SEP38PricesResponse extends Response {
  List<SEP38BuyAsset> buyAssets;

  SEP38PricesResponse(this.buyAssets);

  factory SEP38PricesResponse.fromJson(Map<String, dynamic> json) {
    return SEP38PricesResponse(List<SEP38BuyAsset>.from(
        json['buy_assets'].map((e) => SEP38BuyAsset.fromJson(e))));
  }
}

/// Response of the info endpoint.
class SEP38InfoResponse extends Response {
  List<SEP38Asset> assets;

  SEP38InfoResponse(this.assets);

  factory SEP38InfoResponse.fromJson(Map<String, dynamic> json) {
    return SEP38InfoResponse(List<SEP38Asset>.from(
        json['assets'].map((e) => SEP38Asset.fromJson(e))));
  }
}

class SEP38Asset {
  String asset;
  List<Sep38SellDeliveryMethod>? sellDeliveryMethods;
  List<Sep38BuyDeliveryMethod>? buyDeliveryMethods;
  List<String>? countryCodes;

  SEP38Asset(this.asset,
      {this.sellDeliveryMethods, this.buyDeliveryMethods, this.countryCodes});

  factory SEP38Asset.fromJson(Map<String, dynamic> json) =>
      SEP38Asset(json['asset'],
          sellDeliveryMethods: json['sell_delivery_methods'] == null
              ? null
              : List<Sep38SellDeliveryMethod>.from(json['sell_delivery_methods']
                  .map((e) => Sep38SellDeliveryMethod.fromJson(e))),
          buyDeliveryMethods: json['buy_delivery_methods'] == null
              ? null
              : List<Sep38BuyDeliveryMethod>.from(json['buy_delivery_methods']
                  .map((e) => Sep38BuyDeliveryMethod.fromJson(e))),
          countryCodes: json['country_codes'] == null
              ? null
              : List<String>.from(json['country_codes'].map((e) => e)));
}

class SEP38BuyAsset {
  String asset;
  String price;
  int decimals;

  SEP38BuyAsset(this.asset, this.price, this.decimals);

  factory SEP38BuyAsset.fromJson(Map<String, dynamic> json) => SEP38BuyAsset(
      json['asset'], json['price'], convertInt(json['decimals'])!);
}

class Sep38SellDeliveryMethod {
  String name;
  String description;

  Sep38SellDeliveryMethod(this.name, this.description);

  factory Sep38SellDeliveryMethod.fromJson(Map<String, dynamic> json) =>
      Sep38SellDeliveryMethod(json['name'], json['description']);
}

class Sep38BuyDeliveryMethod {
  String name;
  String description;

  Sep38BuyDeliveryMethod(this.name, this.description);

  factory Sep38BuyDeliveryMethod.fromJson(Map<String, dynamic> json) =>
      Sep38BuyDeliveryMethod(json['name'], json['description']);
}

class SEP38ResponseException implements Exception {
  String error;

  SEP38ResponseException(this.error);

  String toString() {
    return "SEP38 response - error:$error";
  }
}

class SEP38BadRequest extends SEP38ResponseException {
  SEP38BadRequest(String error) : super(error);
}

class SEP38PermissionDenied extends SEP38ResponseException {
  SEP38PermissionDenied(String error) : super(error);
}

class SEP38NotFound extends SEP38ResponseException {
  SEP38NotFound(String error) : super(error);
}

class SEP38UnknownResponse implements Exception {
  int code;
  String body;

  SEP38UnknownResponse(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}
