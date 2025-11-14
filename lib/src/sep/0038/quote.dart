import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/sep/0001/stellar_toml.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import '../../responses/response.dart';
import 'dart:convert';

/// Implements SEP-0038 v2.5.0 - Anchor RFQ (Request for Quote) API.
///
/// Provides standardized APIs for requesting price quotes for asset exchanges
/// between on-chain and off-chain assets. Anchors use this protocol to provide
/// indicative and firm quotes for deposit/withdrawal operations.
///
/// Quote types:
/// - Indicative prices: Non-binding price information for asset pairs
/// - Indicative quotes: Price for specific amount without commitment
/// - Firm quotes: Binding commitment to exchange at specified rate
///
/// Workflow:
/// 1. Get available assets and delivery methods via [info]
/// 2. Request indicative prices for planning via [prices]
/// 3. Get specific price quote via [price]
/// 4. Request firm quote with [postQuote]
/// 5. Execute trade with SEP-6, SEP-24, or SEP-31
/// 6. Retrieve quote status with [getQuote]
///
/// Asset formats:
/// - Stellar assets: "stellar:CODE:ISSUER" or "native"
/// - ISO 4217 fiat: "iso4217:USD"
/// - Other formats as defined by anchor
///
/// Protocol specification:
/// - [SEP-0038](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)
///
/// Example:
/// ```dart
/// // Initialize from stellar.toml
/// SEP38QuoteService quotes = await SEP38QuoteService.fromDomain(
///   "example.com"
/// );
///
/// // Get available assets
/// SEP38InfoResponse info = await quotes.info();
///
/// // Get indicative price
/// SEP38PriceResponse price = await quotes.price(
///   context: "sep6",
///   sellAsset: "stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5",
///   buyAsset: "iso4217:USD",
///   sellAmount: "100"
/// );
///
/// // Request firm quote
/// SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
///   context: "sep6",
///   sellAsset: "stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5",
///   buyAsset: "iso4217:USD",
///   sellAmount: "100"
/// );
/// SEP38QuoteResponse quote = await quotes.postQuote(request, jwtToken);
/// ```
///
/// See also:
/// - [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md) for deposits/withdrawals
/// - [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md) for interactive flow
/// - [SEP-0031](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0031.md) for cross-border payments
class SEP38QuoteService {
  String _serviceAddress;
  late http.Client httpClient;
  Map<String, String>? httpRequestHeaders;

  /// Constructor accepting the [serviceAddress] from the server (ANCHOR_QUOTE_SERVER in stellar.toml).
  /// It also accepts an optional [httpClient] to be used for requests. If not provided, this service will use its own http client.
  SEP38QuoteService(this._serviceAddress,
      {http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient ?? http.Client();
  }

  /// Creates an instance of this class by loading the anchor quote server sep 38 url from the given [domain] stellar toml file (ANCHOR_QUOTE_SERVER).
  /// It also accepts an optional [httpClient] to be used for all requests. If not provided, this service will use its own http client.
  static Future<SEP38QuoteService> fromDomain(String domain,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders}) async {
    StellarToml toml = await StellarToml.fromDomain(domain,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
    String? addr = toml.generalInformation.anchorQuoteServer;
    checkNotNull(
        addr, "Anchor quote server SEP 38 not available for domain " + domain);
    return SEP38QuoteService(addr!,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
  }

  /// Returns supported assets and delivery methods available for trading.
  ///
  /// Retrieves a list of on-chain and off-chain assets that the anchor supports
  /// for exchange operations, along with available delivery methods and country codes.
  ///
  /// Parameters:
  /// - [jwtToken] Optional JWT token from SEP-10 authentication
  ///
  /// Returns [SEP38InfoResponse] containing available assets and options.
  ///
  /// Throws:
  /// - [SEP38BadRequest] for HTTP 400 responses (invalid parameters)
  /// - [SEP38UnknownResponse] for unexpected HTTP status codes
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-info
  Future<SEP38InfoResponse> info({String? jwtToken}) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'info');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
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

  /// Fetches indicative prices for available buy assets given a sell asset and amount.
  ///
  /// Returns non-binding price information for multiple asset pairs. Useful for
  /// displaying exchange rate options to users before requesting firm quotes.
  ///
  /// Parameters:
  /// - [sellAsset] Asset to sell using Asset Identification Format
  /// - [sellAmount] Amount of sellAsset to exchange
  /// - [sellDeliveryMethod] Optional delivery method name from info endpoint
  /// - [buyDeliveryMethod] Optional delivery method name from info endpoint
  /// - [countryCode] Optional ISO 3166-1 alpha-2 or ISO 3166-2 country code
  /// - [jwtToken] Optional JWT token from SEP-10 authentication
  ///
  /// Returns [SEP38PricesResponse] containing prices for available buy assets.
  ///
  /// Throws:
  /// - [SEP38BadRequest] for HTTP 400 responses (invalid parameters)
  /// - [SEP38UnknownResponse] for unexpected HTTP status codes
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-prices
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

    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
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

  /// Fetches an indicative price for a specific asset pair and amount.
  ///
  /// Returns a non-binding price quote for exchanging one asset for another.
  /// Must provide either [sellAmount] or [buyAmount], but not both.
  ///
  /// Parameters:
  /// - [context] Context for quote usage ("sep6" or "sep31")
  /// - [sellAsset] Asset to sell (e.g., "stellar:USDC:G...", "iso4217:USD")
  /// - [buyAsset] Asset to buy
  /// - [sellAmount] Optional amount of sellAsset to exchange
  /// - [buyAmount] Optional amount of buyAsset to receive
  /// - [sellDeliveryMethod] Optional delivery method name from info endpoint
  /// - [buyDeliveryMethod] Optional delivery method name from info endpoint
  /// - [countryCode] Optional ISO 3166-1 alpha-2 or ISO 3166-2 country code
  /// - [jwtToken] Optional JWT token from SEP-10 authentication
  ///
  /// Returns [SEP38PriceResponse] containing price details and fees.
  ///
  /// Throws:
  /// - [ArgumentError] if both or neither amount parameters are provided
  /// - [SEP38BadRequest] for HTTP 400 responses (invalid parameters)
  /// - [SEP38UnknownResponse] for unexpected HTTP status codes
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-price
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

    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
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

  /// Requests a firm quote with binding commitment from the anchor.
  ///
  /// Creates a quote that the anchor is committed to honor until expiration.
  /// The quote can be used with SEP-6, SEP-24, or SEP-31 transactions.
  ///
  /// Parameters:
  /// - [request] Quote request parameters
  /// - [jwtToken] Required JWT token from SEP-10 authentication
  ///
  /// Returns [SEP38QuoteResponse] containing firm quote with unique ID.
  ///
  /// Throws:
  /// - [ArgumentError] if both or neither amount parameters are provided in request
  /// - [SEP38BadRequest] for HTTP 400 responses (invalid parameters)
  /// - [SEP38PermissionDenied] for HTTP 403 responses (authentication required)
  /// - [SEP38UnknownResponse] for unexpected HTTP status codes
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#post-quote
  Future<SEP38QuoteResponse> postQuote(
      SEP38PostQuoteRequest request, String jwtToken) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'quote');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
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

  /// Retrieves a previously created firm quote by ID.
  ///
  /// Fetches the current state and details of a firm quote that was created
  /// via [postQuote]. Useful for checking quote expiration and exchange rates.
  ///
  /// Parameters:
  /// - [id] Unique identifier of the quote to retrieve
  /// - [jwtToken] Required JWT token from SEP-10 authentication
  ///
  /// Returns [SEP38QuoteResponse] containing quote details.
  ///
  /// Throws:
  /// - [SEP38BadRequest] for HTTP 400 responses (invalid parameters)
  /// - [SEP38PermissionDenied] for HTTP 403 responses (authentication required)
  /// - [SEP38NotFound] for HTTP 404 responses (quote not found)
  /// - [SEP38UnknownResponse] for unexpected HTTP status codes
  ///
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#get-quote
  Future<SEP38QuoteResponse> getQuote(String id, String jwtToken) async {
    Uri requestURI = Util.appendEndpointToUrl(_serviceAddress, 'quote/$id');
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
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

/// Request for creating a firm quote.
///
/// Specifies the parameters for a binding quote commitment from the anchor.
/// Either [sellAmount] or [buyAmount] must be provided, but not both.
///
/// Example:
/// ```dart
/// SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
///   context: "sep6",
///   sellAsset: "stellar:USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5",
///   buyAsset: "iso4217:USD",
///   sellAmount: "100",
///   expireAfter: DateTime.now().add(Duration(minutes: 5))
/// );
/// ```
class SEP38PostQuoteRequest {
  /// Context for quote usage ("sep6" or "sep31").
  String context;

  /// Asset to sell using Asset Identification Format.
  String sellAsset;

  /// Asset to buy using Asset Identification Format.
  String buyAsset;

  /// Amount of sellAsset to exchange (provide either this or buyAmount).
  String? sellAmount;

  /// Amount of buyAsset to receive (provide either this or sellAmount).
  String? buyAmount;

  /// Optional expiration time for the quote.
  DateTime? expireAfter;

  /// Optional delivery method for sell asset.
  String? sellDeliveryMethod;

  /// Optional delivery method for buy asset.
  String? buyDeliveryMethod;

  /// Optional country code (ISO 3166-1 alpha-2 or ISO 3166-2).
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

/// Response containing a firm quote.
///
/// Provides a binding commitment from the anchor to exchange assets at the
/// specified rate. The quote is valid until [expiresAt].
///
/// Example:
/// ```dart
/// SEP38QuoteResponse quote = await service.postQuote(request, jwt);
/// print("Quote ID: ${quote.id}");
/// print("Price: ${quote.price}");
/// print("Expires: ${quote.expiresAt}");
/// print("Fee: ${quote.fee.total} ${quote.fee.asset}");
/// ```
class SEP38QuoteResponse {
  /// Unique identifier for this quote.
  String id;

  /// Expiration timestamp for quote validity.
  DateTime expiresAt;

  /// Total price including fees (buyAmount / sellAmount).
  String totalPrice;

  /// Price excluding fees.
  String price;

  /// Asset being sold.
  String sellAsset;

  /// Amount of sellAsset to exchange.
  String sellAmount;

  /// Asset being bought.
  String buyAsset;

  /// Amount of buyAsset to receive.
  String buyAmount;

  /// Fee breakdown for the exchange.
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

/// Response containing an indicative price quote.
///
/// Provides non-binding price information for an asset pair. Unlike firm quotes,
/// indicative prices are not binding commitments and may change before execution.
///
/// The [totalPrice] includes all fees, while [price] excludes fees. This allows
/// clients to show users both the nominal exchange rate and the effective rate.
///
/// Example:
/// ```dart
/// SEP38PriceResponse price = await service.price(
///   context: "sep6",
///   sellAsset: "stellar:USDC:G...",
///   buyAsset: "iso4217:USD",
///   sellAmount: "100"
/// );
/// print("Price: ${price.price}");
/// print("Total with fees: ${price.totalPrice}");
/// print("Fee: ${price.fee.total} ${price.fee.asset}");
/// ```
class SEP38PriceResponse {
  /// Total price including all fees (buyAmount / sellAmount).
  String totalPrice;

  /// Exchange rate excluding fees.
  String price;

  /// Amount of asset being sold.
  String sellAmount;

  /// Amount of asset being bought.
  String buyAmount;

  /// Fee breakdown for the exchange.
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

/// Fee structure for an exchange operation.
///
/// Provides total fee amount and optional breakdown of individual fee components.
/// The [total] represents the complete fee charged by the anchor, while [details]
/// provides transparency about how the fee is calculated.
///
/// Example:
/// ```dart
/// SEP38Fee fee = price.fee;
/// print("Total fee: ${fee.total} ${fee.asset}");
/// if (fee.details != null) {
///   for (var detail in fee.details!) {
///     print("${detail.name}: ${detail.amount}");
///   }
/// }
/// ```
class SEP38Fee {
  /// Total fee amount as a string decimal.
  String total;

  /// Asset in which fee is denominated.
  String asset;

  /// Optional breakdown of individual fee components.
  List<SEP38FeeDetails>? details;

  SEP38Fee(this.total, this.asset, {this.details});

  factory SEP38Fee.fromJson(Map<String, dynamic> json) =>
      SEP38Fee(json['total'], json['asset'],
          details: json['details'] == null
              ? null
              : List<SEP38FeeDetails>.from(
                  json['details'].map((e) => SEP38FeeDetails.fromJson(e))));
}

/// Detailed breakdown of a single fee component.
///
/// Provides transparency about individual fees that make up the total fee.
/// Common fee types include network fees, processing fees, and conversion fees.
///
/// Example:
/// ```dart
/// SEP38FeeDetails detail = fee.details.first;
/// print("${detail.name}: ${detail.amount}");
/// if (detail.description != null) {
///   print("Description: ${detail.description}");
/// }
/// ```
class SEP38FeeDetails {
  /// Name identifying this fee component (e.g., "Network fee", "Processing fee").
  String name;

  /// Amount for this fee component as a string decimal.
  String amount;

  /// Optional human-readable description of this fee.
  String? description;

  SEP38FeeDetails(this.name, this.amount, {this.description});

  factory SEP38FeeDetails.fromJson(Map<String, dynamic> json) =>
      SEP38FeeDetails(json['name'], json['amount'],
          description:
              json['description'] == null ? null : json['description']);
}

/// Response containing indicative prices for multiple buy assets.
///
/// Returns a list of available buy assets with their indicative prices for a
/// given sell asset and amount. Useful for displaying multiple exchange options
/// to users before they select a specific asset pair.
///
/// Example:
/// ```dart
/// SEP38PricesResponse prices = await service.prices(
///   sellAsset: "stellar:USDC:G...",
///   sellAmount: "100"
/// );
/// for (var buyAsset in prices.buyAssets) {
///   print("${buyAsset.asset}: ${buyAsset.price}");
/// }
/// ```
class SEP38PricesResponse extends Response {
  /// List of available buy assets with their prices and decimal precision.
  List<SEP38BuyAsset> buyAssets;

  SEP38PricesResponse(this.buyAssets);

  factory SEP38PricesResponse.fromJson(Map<String, dynamic> json) {
    return SEP38PricesResponse(List<SEP38BuyAsset>.from(
        json['buy_assets'].map((e) => SEP38BuyAsset.fromJson(e))));
  }
}

/// Response containing supported assets and delivery methods.
///
/// Returns comprehensive information about all assets supported by the anchor
/// for exchange operations, including available delivery methods and country
/// restrictions. This is typically the first call made to discover what exchanges
/// are possible.
///
/// Example:
/// ```dart
/// SEP38InfoResponse info = await service.info();
/// for (var asset in info.assets) {
///   print("Asset: ${asset.asset}");
///   if (asset.sellDeliveryMethods != null) {
///     print("Sell methods: ${asset.sellDeliveryMethods}");
///   }
/// }
/// ```
class SEP38InfoResponse extends Response {
  /// List of supported assets with their delivery methods and restrictions.
  List<SEP38Asset> assets;

  SEP38InfoResponse(this.assets);

  factory SEP38InfoResponse.fromJson(Map<String, dynamic> json) {
    return SEP38InfoResponse(List<SEP38Asset>.from(
        json['assets'].map((e) => SEP38Asset.fromJson(e))));
  }
}

/// Information about a supported asset for exchange operations.
///
/// Describes an asset that can be bought or sold through the anchor, including
/// available delivery methods and country restrictions. Assets are identified
/// using the Asset Identification Format (e.g., "stellar:USDC:G...", "iso4217:USD").
///
/// Example:
/// ```dart
/// SEP38Asset asset = info.assets.first;
/// print("Asset: ${asset.asset}");
/// print("Countries: ${asset.countryCodes}");
/// if (asset.sellDeliveryMethods != null) {
///   for (var method in asset.sellDeliveryMethods!) {
///     print("Sell via ${method.name}: ${method.description}");
///   }
/// }
/// ```
class SEP38Asset {
  /// Asset identifier in Asset Identification Format.
  String asset;

  /// Optional delivery methods for selling this asset to the anchor.
  List<Sep38SellDeliveryMethod>? sellDeliveryMethods;

  /// Optional delivery methods for buying this asset from the anchor.
  List<Sep38BuyDeliveryMethod>? buyDeliveryMethods;

  /// Optional ISO 3166-1 alpha-2 or ISO 3166-2 country codes where asset is available.
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

/// Buy asset information with price and decimal precision.
///
/// Represents a buy asset option returned from the prices endpoint, including
/// its indicative price and the number of decimal places for amount precision.
///
/// Example:
/// ```dart
/// SEP38BuyAsset buyAsset = prices.buyAssets.first;
/// print("Asset: ${buyAsset.asset}");
/// print("Price: ${buyAsset.price}");
/// print("Decimals: ${buyAsset.decimals}");
/// ```
class SEP38BuyAsset {
  /// Asset identifier in Asset Identification Format.
  String asset;

  /// Indicative price for this buy asset.
  String price;

  /// Number of decimal places for amount precision.
  int decimals;

  SEP38BuyAsset(this.asset, this.price, this.decimals);

  factory SEP38BuyAsset.fromJson(Map<String, dynamic> json) => SEP38BuyAsset(
      json['asset'], json['price'], convertInt(json['decimals'])!);
}

/// Delivery method for selling an off-chain asset to the anchor.
///
/// Describes how a user can deliver an off-chain asset to the anchor (e.g.,
/// bank transfer, wire transfer, cash pickup). The [name] is used in API calls
/// while [description] provides human-readable details.
///
/// Example:
/// ```dart
/// Sep38SellDeliveryMethod method = asset.sellDeliveryMethods.first;
/// print("Method: ${method.name}");
/// print("Description: ${method.description}");
/// ```
class Sep38SellDeliveryMethod {
  /// Unique identifier for this delivery method (e.g., "WIRE", "ACH").
  String name;

  /// Human-readable description of the delivery method.
  String description;

  Sep38SellDeliveryMethod(this.name, this.description);

  factory Sep38SellDeliveryMethod.fromJson(Map<String, dynamic> json) =>
      Sep38SellDeliveryMethod(json['name'], json['description']);
}

/// Delivery method for buying an off-chain asset from the anchor.
///
/// Describes how a user can receive an off-chain asset from the anchor (e.g.,
/// bank transfer, cash pickup, mobile money). The [name] is used in API calls
/// while [description] provides human-readable details.
///
/// Example:
/// ```dart
/// Sep38BuyDeliveryMethod method = asset.buyDeliveryMethods.first;
/// print("Method: ${method.name}");
/// print("Description: ${method.description}");
/// ```
class Sep38BuyDeliveryMethod {
  /// Unique identifier for this delivery method (e.g., "WIRE", "ACH").
  String name;

  /// Human-readable description of the delivery method.
  String description;

  Sep38BuyDeliveryMethod(this.name, this.description);

  factory Sep38BuyDeliveryMethod.fromJson(Map<String, dynamic> json) =>
      Sep38BuyDeliveryMethod(json['name'], json['description']);
}

/// Base exception for SEP-38 API errors.
///
/// Contains error message returned by the anchor. Subclasses provide specific
/// exception types for different HTTP status codes.
class SEP38ResponseException implements Exception {
  /// Error message from the anchor.
  String error;

  SEP38ResponseException(this.error);

  String toString() {
    return "SEP38 response - error:$error";
  }
}

/// Exception for HTTP 400 Bad Request responses.
///
/// Thrown when request parameters are invalid or malformed.
///
/// Common causes:
/// - Invalid asset format
/// - Missing required parameters
/// - Both sellAmount and buyAmount provided
/// - Invalid delivery method
/// - Invalid country code
///
/// Resolution:
/// - Verify asset identifiers use correct format (stellar:CODE:ISSUER)
/// - Ensure only one of sellAmount or buyAmount is provided
/// - Check delivery methods match those from info endpoint
/// - Validate country codes are ISO 3166 compliant
class SEP38BadRequest extends SEP38ResponseException {
  SEP38BadRequest(String error) : super(error);
}

/// Exception for HTTP 403 Forbidden responses.
///
/// Thrown when authentication is required or the authenticated user lacks
/// necessary permissions.
///
/// Common causes:
/// - Missing or invalid JWT token
/// - Expired JWT token
/// - Insufficient permissions for requested operation
///
/// Resolution:
/// - Obtain fresh JWT token via SEP-10 authentication
/// - Verify token is for correct account
/// - Ensure user has necessary KYC status via SEP-12
class SEP38PermissionDenied extends SEP38ResponseException {
  SEP38PermissionDenied(String error) : super(error);
}

/// Exception for HTTP 404 Not Found responses.
///
/// Thrown when a requested quote ID does not exist.
///
/// Common causes:
/// - Quote ID does not exist
/// - Quote has expired and been deleted
/// - Quote belongs to different user
///
/// Resolution:
/// - Verify quote ID is correct
/// - Create new quote if previous one expired
/// - Ensure using quote ID from same authenticated session
class SEP38NotFound extends SEP38ResponseException {
  SEP38NotFound(String error) : super(error);
}

/// Exception for unexpected HTTP responses.
///
/// Thrown when the anchor returns an HTTP status code that is not explicitly
/// handled by other exception types.
///
/// Common causes:
/// - Server errors (5xx)
/// - Network issues
/// - Anchor service unavailable
///
/// Resolution:
/// - Check anchor service status
/// - Retry request after delay
/// - Contact anchor support if problem persists
class SEP38UnknownResponse implements Exception {
  /// HTTP status code returned.
  int code;

  /// Raw response body.
  String body;

  SEP38UnknownResponse(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}
