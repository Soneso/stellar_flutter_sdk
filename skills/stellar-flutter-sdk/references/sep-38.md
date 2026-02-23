# SEP-38: Anchor RFQ API

**Purpose:** Get exchange quotes between Stellar assets and off-chain assets for use in SEP-6 and SEP-24 flows.
**Prerequisites:** JWT from SEP-10 required for `postQuote()` and `getQuote()`; optional for `info()`, `prices()`, and `price()`

## Table of Contents

1. [Creating the Service](#1-creating-the-service)
2. [Asset Identification Format](#2-asset-identification-format)
3. [GET /info — Available Assets](#3-get-info--available-assets)
4. [GET /prices — Indicative Prices (Multi-Asset)](#4-get-prices--indicative-prices-multi-asset)
5. [GET /price — Indicative Price (Single Pair)](#5-get-price--indicative-price-single-pair)
6. [POST /quote — Request a Firm Quote](#6-post-quote--request-a-firm-quote)
7. [GET /quote/:id — Retrieve a Firm Quote](#7-get-quoteid--retrieve-a-firm-quote)
8. [Response Objects Reference](#8-response-objects-reference)
9. [Error Handling](#9-error-handling)
10. [Price Formulas](#10-price-formulas)
11. [Common Pitfalls](#11-common-pitfalls)

---

## 1. Creating the Service

### From domain (recommended)

`SEP38QuoteService.fromDomain()` is a static async factory. It fetches the domain's `stellar.toml`, reads the `ANCHOR_QUOTE_SERVER` field, and returns a configured service instance. Pass only the bare domain — no protocol prefix.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Fetches stellar.toml from anchor.example.com, reads ANCHOR_QUOTE_SERVER
try {
  SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');
} catch (e) {
  print('Could not load quote service: $e');
}
```

Throws if the stellar.toml fetch fails or `ANCHOR_QUOTE_SERVER` is absent.

Signature:
```
static Future<SEP38QuoteService> fromDomain(
  String domain, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### With a direct URL

Use when you already know the quote server address.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = SEP38QuoteService('https://anchor.example.com/sep38');
```

Constructor signature:
```
SEP38QuoteService(
  String serviceAddress, {
  http.Client? httpClient,
  Map<String, String>? httpRequestHeaders,
})
```

### With custom HTTP client or headers

Pass a custom `http.Client` for timeouts, proxies, or custom headers:

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = SEP38QuoteService(
  'https://anchor.example.com/sep38',
  httpClient: http.Client(),
  httpRequestHeaders: {'X-App-Version': '1.0'},
);
```

---

## 2. Asset Identification Format

SEP-38 uses a specific string format to identify assets. Always use this format directly as a plain string — do not construct `Asset` objects.

| Asset type | Format | Example |
|------------|--------|---------|
| Stellar asset | `stellar:CODE:ISSUER` | `stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN` |
| Fiat currency | `iso4217:CODE` | `iso4217:USD` |

```dart
// WRONG: passing a Stellar Asset object — SEP-38 methods expect String, not Asset
// CORRECT: use the string identifier format
String sellAsset = 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
String buyAsset  = 'iso4217:BRL';
```

---

## 3. GET /info — Available Assets

Returns all assets the anchor supports for exchange, with optional delivery methods and country restrictions. Authentication is optional.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

// JWT is optional — omit for unauthenticated call
SEP38InfoResponse info = await service.info(jwtToken: jwtToken);

for (SEP38Asset asset in info.assets) {
  print('Asset: ${asset.asset}');

  // Country codes for fiat assets — null if no restriction
  if (asset.countryCodes != null) {
    print('  Countries: ${asset.countryCodes!.join(', ')}');
  }

  // Methods for delivering off-chain assets TO the anchor (e.g. user sends BRL via PIX)
  if (asset.sellDeliveryMethods != null) {
    for (Sep38SellDeliveryMethod method in asset.sellDeliveryMethods!) {
      print('  Sell via ${method.name}: ${method.description}');
    }
  }

  // Methods for receiving off-chain assets FROM the anchor (e.g. user receives BRL via ACH)
  if (asset.buyDeliveryMethods != null) {
    for (Sep38BuyDeliveryMethod method in asset.buyDeliveryMethods!) {
      print('  Buy via ${method.name}: ${method.description}');
    }
  }
}
```

Method signature:
```
Future<SEP38InfoResponse> info({String? jwtToken})
throws: SEP38BadRequest (HTTP 400), SEP38UnknownResponse (other)
```

### SEP38InfoResponse properties

| Property | Type | Description |
|----------|------|-------------|
| `assets` | `List<SEP38Asset>` | All supported assets |

### SEP38Asset properties

| Property | Type | Description |
|----------|------|-------------|
| `asset` | `String` | Asset identifier in SEP-38 format |
| `sellDeliveryMethods` | `List<Sep38SellDeliveryMethod>?` | Methods for delivering this asset to the anchor; null if none |
| `buyDeliveryMethods` | `List<Sep38BuyDeliveryMethod>?` | Methods for receiving this asset from the anchor; null if none |
| `countryCodes` | `List<String>?` | ISO country codes where asset is available; null if unrestricted |

---

## 4. GET /prices — Indicative Prices (Multi-Asset)

Returns indicative (non-binding) prices for all tradeable buy assets given a sell asset and amount. Use this to show users all available exchange options before they commit to a specific pair. Authentication is optional.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

SEP38PricesResponse response = await service.prices(
  sellAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
  jwtToken: jwtToken, // optional
);

for (SEP38BuyAsset buyAsset in response.buyAssets) {
  print('${buyAsset.asset}: price=${buyAsset.price}, decimals=${buyAsset.decimals}');
}
```

### With delivery method and country code

For off-chain assets, providing delivery method and country code yields more accurate indicative prices:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

// What can I buy for 500 BRL sent via PIX in Brazil?
SEP38PricesResponse response = await service.prices(
  sellAsset: 'iso4217:BRL',
  sellAmount: '500',
  sellDeliveryMethod: 'PIX',  // name from info().assets[n].sellDeliveryMethods
  countryCode: 'BRA',         // ISO 3166-1 alpha-3 or ISO 3166-2 code
  jwtToken: jwtToken,
);
```

Method signature:
```
Future<SEP38PricesResponse> prices({
  required String sellAsset,
  required String sellAmount,
  String? sellDeliveryMethod,
  String? buyDeliveryMethod,
  String? countryCode,
  String? jwtToken,
})
throws: SEP38BadRequest (HTTP 400), SEP38UnknownResponse (other)
```

### SEP38PricesResponse properties

| Property | Type | Description |
|----------|------|-------------|
| `buyAssets` | `List<SEP38BuyAsset>` | Assets available to buy and their indicative prices |

### SEP38BuyAsset properties

| Property | Type | Description |
|----------|------|-------------|
| `asset` | `String` | Asset identifier in SEP-38 format |
| `price` | `String` | Indicative price of one sell-asset unit in terms of this buy asset |
| `decimals` | `int` | Decimal precision for this asset |

---

## 5. GET /price — Indicative Price (Single Pair)

Returns an indicative price for a specific asset pair with fee details. You must provide either `sellAmount` or `buyAmount`, but not both. Providing both or neither throws `ArgumentError`. Authentication is optional.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

// Query by sell amount: how much BRL do I receive for 100 USDC?
SEP38PriceResponse response = await service.price(
  context: 'sep6',    // 'sep6' or 'sep24'
  sellAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  buyAsset: 'iso4217:BRL',
  sellAmount: '100',  // provide sellAmount OR buyAmount, not both
  jwtToken: jwtToken,
);

print('Total price (with fees): ${response.totalPrice}');
print('Price (without fees):    ${response.price}');
print('Sell amount:             ${response.sellAmount}');
print('Buy amount:              ${response.buyAmount}');
print('Fee total:               ${response.fee.total} ${response.fee.asset}');
```

### Query by buy amount

If you know the desired receive amount, use `buyAmount` instead:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

// How much USDC do I need to sell to receive 500 BRL?
SEP38PriceResponse response = await service.price(
  context: 'sep6',
  sellAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  buyAsset: 'iso4217:BRL',
  buyAmount: '500', // provide buyAmount when you know the target receive amount
  jwtToken: jwtToken,
);

print('You need to sell: ${response.sellAmount} USDC');
print('You will receive: ${response.buyAmount} BRL');
```

### With delivery methods

For off-chain assets, specify delivery methods for more accurate quotes:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

SEP38PriceResponse response = await service.price(
  context: 'sep6',
  sellAsset: 'iso4217:BRL',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '500',
  sellDeliveryMethod: 'PIX',
  countryCode: 'BRA',
  jwtToken: jwtToken,
);
```

### Reading fee details

The response always includes a `SEP38Fee` object. The optional `details` list contains itemized fee components:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38PriceResponse response = await service.price(
  context: 'sep6',
  sellAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  buyAsset: 'iso4217:BRL',
  sellAmount: '100',
);

SEP38Fee fee = response.fee;
print('Fee total: ${fee.total} (${fee.asset})');

if (fee.details != null) {
  for (SEP38FeeDetails detail in fee.details!) {
    String desc = detail.description != null ? ' (${detail.description})' : '';
    print('  ${detail.name}: ${detail.amount}$desc');
  }
}
```

Method signature:
```
Future<SEP38PriceResponse> price({
  required String context,
  required String sellAsset,
  required String buyAsset,
  String? sellAmount,
  String? buyAmount,
  String? sellDeliveryMethod,
  String? buyDeliveryMethod,
  String? countryCode,
  String? jwtToken,
})
throws: ArgumentError (both/neither amount), SEP38BadRequest (HTTP 400), SEP38UnknownResponse (other)
```

### SEP38PriceResponse properties

| Property | Type | Description |
|----------|------|-------------|
| `totalPrice` | `String` | Total price including fees: `sell_amount = total_price * buy_amount` |
| `price` | `String` | Exchange rate without fees |
| `sellAmount` | `String` | Amount of the sell asset |
| `buyAmount` | `String` | Amount of the buy asset |
| `fee` | `SEP38Fee` | Fee structure (always present) |

---

## 6. POST /quote — Request a Firm Quote

A firm quote is a binding commitment from the anchor to exchange assets at the given rate, valid until `expiresAt`. Authentication is **required** — the `jwtToken` parameter is non-nullable and positional (not named). Either `sellAmount` or `buyAmount` must be set in the request, but not both. Providing both or neither throws `ArgumentError`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',    // 'sep6' or 'sep24'
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',  // OR buyAmount — not both
);

// JWT is required and positional (not named)
SEP38QuoteResponse quote = await service.postQuote(request, jwtToken);

print('Quote ID:    ${quote.id}');
print('Expires at:  ${quote.expiresAt.toIso8601String()}');
print('Total price: ${quote.totalPrice}');
print('Price:       ${quote.price}');
print('Sell:        ${quote.sellAmount} ${quote.sellAsset}');
print('Buy:         ${quote.buyAmount} ${quote.buyAsset}');
print('Fee:         ${quote.fee.total} ${quote.fee.asset}');
```

### Request with expiration preference

Use `expireAfter` to request a minimum quote validity period. The anchor may grant a longer expiration:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
  expireAfter: DateTime.now().add(Duration(minutes: 30)), // request at least 30 min validity
);

SEP38QuoteResponse quote = await service.postQuote(request, jwtToken);

// Check validity
bool isValid = quote.expiresAt.isAfter(DateTime.now());
print('Valid: $isValid, expires: ${quote.expiresAt.toIso8601String()}');
```

### Request with delivery methods

Include delivery method names (from `info()`) when exchanging off-chain assets:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',
  sellAsset: 'iso4217:BRL',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  buyAmount: '100',
  sellDeliveryMethod: 'PIX',   // name from info().assets[n].sellDeliveryMethods
  countryCode: 'BRA',
);

SEP38QuoteResponse quote = await service.postQuote(request, jwtToken);
```

Method signature:
```
Future<SEP38QuoteResponse> postQuote(SEP38PostQuoteRequest request, String jwtToken)
throws: ArgumentError (both/neither amount), SEP38BadRequest (HTTP 400),
        SEP38PermissionDenied (HTTP 403), SEP38UnknownResponse (other)
```

### SEP38PostQuoteRequest constructor

```
SEP38PostQuoteRequest({
  required String context,
  required String sellAsset,
  required String buyAsset,
  String? sellAmount,
  String? buyAmount,
  DateTime? expireAfter,
  String? sellDeliveryMethod,
  String? buyDeliveryMethod,
  String? countryCode,
})
```

All constructor parameters are public fields accessible directly (e.g., `request.sellAmount`).

---

## 7. GET /quote/:id — Retrieve a Firm Quote

Retrieves a previously-created firm quote by its ID. Authentication is **required** — `jwtToken` is non-nullable and positional (not named).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

String quoteId = 'de762cda-a193-4961-861e-57b31fed6eb3'; // from postQuote() response
SEP38QuoteResponse quote = await service.getQuote(quoteId, jwtToken);

print('Quote ID:    ${quote.id}');
print('Expires at:  ${quote.expiresAt.toIso8601String()}');
bool isValid = quote.expiresAt.isAfter(DateTime.now());
print('Still valid: $isValid');
print('Sell: ${quote.sellAmount} ${quote.sellAsset}');
print('Buy:  ${quote.buyAmount} ${quote.buyAsset}');
```

Method signature:
```
Future<SEP38QuoteResponse> getQuote(String id, String jwtToken)
throws: SEP38BadRequest (HTTP 400), SEP38PermissionDenied (HTTP 403),
        SEP38NotFound (HTTP 404), SEP38UnknownResponse (other)
```

### SEP38QuoteResponse properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Unique quote identifier |
| `expiresAt` | `DateTime` | When this quote expires (parsed from ISO 8601 string) |
| `totalPrice` | `String` | Total price including fees |
| `price` | `String` | Exchange rate without fees |
| `sellAsset` | `String` | The asset being sold (SEP-38 format) |
| `sellAmount` | `String` | Amount of the sell asset |
| `buyAsset` | `String` | The asset being purchased (SEP-38 format) |
| `buyAmount` | `String` | Amount of the buy asset |
| `fee` | `SEP38Fee` | Fee structure (always present) |

---

## 8. Response Objects Reference

### SEP38Fee

Represents the total fee and optional itemized breakdown.

```dart
SEP38Fee fee = quote.fee;

print('Total fee: ${fee.total}');   // String — total fee amount
print('Fee asset: ${fee.asset}');   // String — SEP-38 format, e.g. "iso4217:BRL"

// details is null when the anchor does not provide an itemized breakdown
if (fee.details != null) {
  for (SEP38FeeDetails detail in fee.details!) {
    print('${detail.name}: ${detail.amount}');       // String, String
    if (detail.description != null) {
      print('  ${detail.description}');              // String?
    }
  }
}
```

### SEP38Fee properties

| Property | Type | Description |
|----------|------|-------------|
| `total` | `String` | Total fee amount |
| `asset` | `String` | Asset the fee is charged in (SEP-38 format) |
| `details` | `List<SEP38FeeDetails>?` | Itemized breakdown; null if not provided by anchor |

### SEP38FeeDetails properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Fee component name (e.g. `"Service fee"`, `"PIX fee"`) |
| `amount` | `String` | Amount for this component |
| `description` | `String?` | Optional human-readable explanation |

### Delivery method classes

`Sep38SellDeliveryMethod` and `Sep38BuyDeliveryMethod` are separate classes but have identical structure:

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Identifier used as parameter value (e.g. `"PIX"`, `"ACH"`, `"cash"`) |
| `description` | `String` | Human-readable description of the delivery method |

Use the `name` value as the `sellDeliveryMethod` or `buyDeliveryMethod` parameter in `prices()`, `price()`, and `SEP38PostQuoteRequest`.

```dart
// Discover delivery methods from info, then use the name in subsequent calls
SEP38InfoResponse info = await service.info();

for (SEP38Asset asset in info.assets) {
  if (asset.asset == 'iso4217:BRL') {
    if (asset.sellDeliveryMethods != null) {
      for (Sep38SellDeliveryMethod method in asset.sellDeliveryMethods!) {
        // method.name is the value to pass as sellDeliveryMethod
        print('${method.name}: ${method.description}');
      }
    }
  }
}
```

---

## 9. Error Handling

Wrap quote service calls in `try-catch` blocks in production. The SDK throws specific exception types for each error condition:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');

try {
  SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
    context: 'sep6',
    sellAsset: 'iso4217:USD',
    buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
    sellAmount: '100',
  );
  SEP38QuoteResponse quote = await service.postQuote(request, jwtToken);
  print('Quote ID: ${quote.id}');

} on ArgumentError catch (e) {
  // Both sellAmount and buyAmount provided, or neither provided — thrown before HTTP call
  print('Invalid request: $e');

} on SEP38BadRequest catch (e) {
  // HTTP 400 — invalid params, unsupported asset pair, unknown context
  print('Bad request: ${e.error}');

} on SEP38PermissionDenied catch (e) {
  // HTTP 403 — missing JWT, expired JWT, or user not authorized
  print('Permission denied: ${e.error}');

} on SEP38NotFound catch (e) {
  // HTTP 404 — quote ID not found (getQuote only)
  print('Quote not found: ${e.error}');

} on SEP38UnknownResponse catch (e) {
  // Other HTTP errors (5xx, etc.)
  print('Unexpected error: code=${e.code}, body=${e.body}');
}
```

### Exception reference

| Exception | HTTP Status | Thrown by | Common cause |
|-----------|-------------|-----------|--------------|
| `ArgumentError` | N/A | `price()`, `postQuote()` | Both or neither of `sellAmount`/`buyAmount` provided |
| `SEP38BadRequest` | 400 | all methods | Invalid asset format, unsupported pair, missing required field |
| `SEP38PermissionDenied` | 403 | `postQuote()`, `getQuote()` | Missing or expired JWT, user not authorized |
| `SEP38NotFound` | 404 | `getQuote()` | Quote ID doesn't exist or has expired |
| `SEP38UnknownResponse` | other | all methods | Server error or unexpected response |

All `SEP38*` exceptions extend `SEP38ResponseException` (which implements `Exception`) and expose an `error` field (String). `SEP38UnknownResponse` implements `Exception` directly and exposes `code` (int) and `body` (String).

```dart
// Accessing error details from different exception types
} on SEP38BadRequest catch (e) {
  print(e.error);   // String — error message from anchor
  print(e);         // toString(): "SEP38 response - error:<message>"

} on SEP38UnknownResponse catch (e) {
  print(e.code);    // int — HTTP status code
  print(e.body);    // String — raw response body
  print(e);         // toString(): "Unknown response - code: N - body:<body>"
}
```

---

## 10. Price Formulas

The relationship between price, total_price, amounts, and fees:

```
sell_amount = total_price * buy_amount
```

When the fee is denominated in the **sell** asset:
```
sell_amount - fee.total = price * buy_amount
```

When the fee is denominated in the **buy** asset:
```
sell_amount = price * (buy_amount + fee.total)
```

`totalPrice` always includes fees. `price` is the raw exchange rate before fees.

```dart
// Example: selling 542 BRL to buy 100 USDC, fee = 8.40 USDC in sell-asset
// totalPrice = "5.42", price = "5.00"
// Verification: sell_amount = total_price * buy_amount => 542 = 5.42 * 100 ✓

SEP38PriceResponse r = await service.price(...);
double totalPriceNum = double.parse(r.totalPrice);
double buyAmountNum  = double.parse(r.buyAmount);
// Effective sell cost including fees:
double effectiveSell = totalPriceNum * buyAmountNum;
```

---

## 11. Common Pitfalls

**Wrong: providing both sellAmount and buyAmount**

```dart
// WRONG: throws ArgumentError before the HTTP call — never reaches the server
await service.price(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
  buyAmount: '95',  // WRONG: cannot provide both
);

// CORRECT: provide exactly one
await service.price(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
);
```

**Wrong: providing neither sellAmount nor buyAmount**

```dart
// WRONG: throws ArgumentError — exactly one amount is required
SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  // no sellAmount, no buyAmount
);
await service.postQuote(request, jwtToken); // throws ArgumentError

// CORRECT: provide exactly one amount
SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
);
```

**Wrong: passing jwtToken as a named parameter to postQuote/getQuote**

```dart
// WRONG: jwtToken is a positional parameter in postQuote and getQuote — not named
await service.postQuote(request, jwtToken: jwtToken); // compile error
await service.getQuote(quoteId, jwtToken: jwtToken);  // compile error

// CORRECT: positional (no label)
await service.postQuote(request, jwtToken);
await service.getQuote(quoteId, jwtToken);
```

**Wrong: treating expiresAt as a String**

```dart
// WRONG: expiresAt is DateTime, not a String
// SEP38QuoteResponse.fromJson() calls DateTime.parse() on the JSON 'expires_at' value
String s = quote.expiresAt; // type error

// CORRECT: use DateTime methods
print(quote.expiresAt.toIso8601String());
bool isValid = quote.expiresAt.isAfter(DateTime.now());
```

**Wrong: assuming fee.details is always present**

```dart
// WRONG: details is null when the anchor omits the itemized breakdown
for (SEP38FeeDetails detail in quote.fee.details!) { /* throws if details is null */ }

// CORRECT: null-check first
if (quote.fee.details != null) {
  for (SEP38FeeDetails detail in quote.fee.details!) {
    print('${detail.name}: ${detail.amount}');
  }
}
```

**Wrong: using totalPrice as the raw exchange rate for display**

```dart
// WRONG: totalPrice includes fees — it is not the raw exchange rate
double rate = double.parse(price.totalPrice); // misleading for display

// CORRECT: use price for the raw rate; totalPrice for the effective sell cost calculation
double rawRate       = double.parse(price.price);       // exchange rate without fees
double effectiveRate = double.parse(price.totalPrice);  // satisfies: sell = totalPrice * buy
```

**Wrong: fromDomain without await**

```dart
// WRONG: SEP38QuoteService.fromDomain() returns Future<SEP38QuoteService>
SEP38QuoteService service = SEP38QuoteService.fromDomain('anchor.example.com'); // compile error

// CORRECT: must await
SEP38QuoteService service = await SEP38QuoteService.fromDomain('anchor.example.com');
```

---

## Related SEPs

- `references/sep-10.md` — Web Authentication (provides JWT for authenticated endpoints)
- `references/sep-01.md` — stellar.toml (provides `ANCHOR_QUOTE_SERVER` consumed by `fromDomain()`)
- SEP-06 — Deposit/Withdrawal API (use `context: 'sep6'`)
- SEP-24 — Interactive Deposit/Withdrawal (use `context: 'sep24'`)
