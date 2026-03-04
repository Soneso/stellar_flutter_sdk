# SEP-38: Anchor RFQ API

Get exchange quotes between Stellar assets and off-chain assets (like fiat currencies).

## Overview

SEP-38 enables anchors to provide price quotes for asset exchanges. Use it when you need to:

- Show users estimated conversion rates before a deposit or withdrawal
- Lock in a firm exchange rate for a transaction
- Get available trading pairs from an anchor

Quotes come in two types:
- **Indicative quotes**: Estimated prices that may change (via `GET /prices` and `GET /price`)
- **Firm quotes**: Locked prices valid for a limited time (via `POST /quote`)

SEP-38 is used alongside SEP-6, SEP-24, or SEP-31 for the actual asset transfer.

## Quick example

This example shows how to connect to an anchor's quote service and fetch available assets and indicative prices:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Connect to anchor's quote service using stellar.toml discovery
SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// Get available assets for trading
SEP38InfoResponse info = await quoteService.info();
for (SEP38Asset asset in info.assets) {
  print(asset.asset);
}

// Get indicative prices for selling 100 USD
SEP38PricesResponse prices = await quoteService.prices(
  sellAsset: 'iso4217:USD',
  sellAmount: '100',
);

for (SEP38BuyAsset buyAsset in prices.buyAssets) {
  print('Buy ${buyAsset.asset} at price ${buyAsset.price}');
}
```

## Detailed usage

### Creating the service

The `SEP38QuoteService` class has methods for all SEP-38 endpoints. You can create an instance by domain discovery or with a direct URL.

**From stellar.toml (recommended):**

The service address is automatically resolved from the anchor's `ANCHOR_QUOTE_SERVER` field in stellar.toml:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');
```

**With a direct URL:**

If you already know the quote server URL, you can instantiate the service directly:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = SEP38QuoteService('https://anchor.example.com/sep38');
```

**With a custom HTTP client:**

For advanced use cases, you can provide your own HTTP client:

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = SEP38QuoteService(
  'https://anchor.example.com/sep38',
  httpClient: http.Client(),
  httpRequestHeaders: {'X-App-Version': '1.0'},
);
```

### Asset identification format

SEP-38 uses a specific format for identifying assets in requests and responses:

| Type | Format | Example |
|------|--------|---------|
| Stellar asset | `stellar:CODE:ISSUER` | `stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN` |
| Fiat currency | `iso4217:CODE` | `iso4217:USD` |

### Getting available assets (GET /info)

The `info()` method returns all Stellar and off-chain assets available for trading, along with their supported delivery methods and country restrictions:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// Authentication is optional for this endpoint
String? jwtToken; // Or obtain via SEP-10 for personalized results

SEP38InfoResponse info = await quoteService.info(jwtToken: jwtToken);

for (SEP38Asset asset in info.assets) {
  print('Asset: ${asset.asset}');

  // Check country restrictions for fiat assets
  if (asset.countryCodes != null) {
    print('  Available in: ${asset.countryCodes!.join(', ')}');
  }

  // Check delivery methods for selling to the anchor
  if (asset.sellDeliveryMethods != null) {
    for (Sep38SellDeliveryMethod method in asset.sellDeliveryMethods!) {
      print('  Sell via ${method.name}: ${method.description}');
    }
  }

  // Check delivery methods for receiving from the anchor
  if (asset.buyDeliveryMethods != null) {
    for (Sep38BuyDeliveryMethod method in asset.buyDeliveryMethods!) {
      print('  Buy via ${method.name}: ${method.description}');
    }
  }
}
```

### Getting indicative prices (GET /prices)

The `prices()` method returns indicative (non-binding) exchange rates for multiple assets. Use this to show users what they can receive for a given amount.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// What can I buy for 100 USD?
SEP38PricesResponse prices = await quoteService.prices(
  sellAsset: 'iso4217:USD',
  sellAmount: '100',
  jwtToken: jwtToken, // Optional
);

for (SEP38BuyAsset buyAsset in prices.buyAssets) {
  print('Asset: ${buyAsset.asset}');
  print('Price: ${buyAsset.price}');
  print('Decimals: ${buyAsset.decimals}');
}
```

**With delivery method and country code:**

For off-chain assets, you can specify delivery methods and country codes to get more accurate pricing:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// What USDC can I buy for 500 BRL via PIX in Brazil?
SEP38PricesResponse prices = await quoteService.prices(
  sellAsset: 'iso4217:BRL',
  sellAmount: '500',
  sellDeliveryMethod: 'PIX',
  countryCode: 'BRA',
  jwtToken: jwtToken,
);

for (SEP38BuyAsset buyAsset in prices.buyAssets) {
  print('${buyAsset.asset} at ${buyAsset.price}');
}
```

### Getting a price for a specific pair (GET /price)

The `price()` method returns an indicative price for a specific asset pair with detailed fee information. You must provide either `sellAmount` or `buyAmount`, but not both:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// How much USDC do I get for 100 USD? (SEP-6 deposit context)
SEP38PriceResponse price = await quoteService.price(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
  jwtToken: jwtToken,
);

print('Total price (with fees): ${price.totalPrice}');
print('Price (without fees): ${price.price}');
print('Sell amount: ${price.sellAmount}');
print('Buy amount: ${price.buyAmount}');
print('Fee total: ${price.fee.total} ${price.fee.asset}');
```

**Query by buy amount instead:**

If you know how much you want to receive, specify `buyAmount` instead:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// How much USD do I need to get 50 USDC?
SEP38PriceResponse price = await quoteService.price(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  buyAmount: '50',
  jwtToken: jwtToken,
);

print('You need to sell: ${price.sellAmount} USD');
print('You will receive: ${price.buyAmount} USDC');
```

**With delivery methods:**

Specify delivery methods for more accurate quotes when working with off-chain assets:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// BRL to USDC via PIX in Brazil, for SEP-31 cross-border payment
SEP38PriceResponse price = await quoteService.price(
  context: 'sep31',
  sellAsset: 'iso4217:BRL',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '500',
  sellDeliveryMethod: 'PIX',
  countryCode: 'BRA',
  jwtToken: jwtToken,
);
```

**Working with fee details:**

The response includes a detailed fee breakdown when provided by the anchor:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

SEP38PriceResponse price = await quoteService.price(
  context: 'sep6',
  sellAsset: 'iso4217:BRL',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '500',
  jwtToken: jwtToken,
);

print('Total fee: ${price.fee.total} ${price.fee.asset}');

// Check for detailed fee breakdown
if (price.fee.details != null) {
  for (SEP38FeeDetails detail in price.fee.details!) {
    String desc = detail.description != null ? ' (${detail.description})' : '';
    print('  ${detail.name}: ${detail.amount}$desc');
  }
}
```

### Requesting a firm quote (POST /quote)

Firm quotes lock in a guaranteed price for a limited time. Authentication is required. Use the `SEP38PostQuoteRequest` class to build your request:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// Build the quote request
SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
);

// Submit the request (JWT is required, positional parameter)
SEP38QuoteResponse quote = await quoteService.postQuote(request, jwtToken);

print('Quote ID: ${quote.id}');
print('Expires at: ${quote.expiresAt.toIso8601String()}');
print('Total price: ${quote.totalPrice}');
print('Price (without fees): ${quote.price}');
print('You sell: ${quote.sellAmount} (${quote.sellAsset})');
print('You receive: ${quote.buyAmount} (${quote.buyAsset})');
```

**With expiration preference:**

You can request a minimum expiration time using the `expireAfter` parameter. The anchor may provide a longer expiration but should not provide a shorter one:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// Request quote valid for at least 1 hour
SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',
  sellAsset: 'iso4217:USD',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '100',
  expireAfter: DateTime.now().add(Duration(hours: 1)),
);

SEP38QuoteResponse quote = await quoteService.postQuote(request, jwtToken);
print('Quote valid until: ${quote.expiresAt.toIso8601String()}');
```

**With delivery methods:**

Include delivery methods when exchanging off-chain assets:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// Quote for selling BRL via bank transfer, buying USDC
SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
  context: 'sep6',
  sellAsset: 'iso4217:BRL',
  buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
  sellAmount: '1000',
  sellDeliveryMethod: 'ACH',
  countryCode: 'BRA',
);

SEP38QuoteResponse quote = await quoteService.postQuote(request, jwtToken);
```

### Retrieving a previous quote (GET /quote/:id)

Use `getQuote()` to retrieve a previously-created firm quote by its ID. This is useful for checking the quote status or retrieving details after creation. Authentication is required:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

// Use the ID from postQuote() response
String quoteId = 'de762cda-a193-4961-861e-57b31fed6eb3';
SEP38QuoteResponse quote = await quoteService.getQuote(quoteId, jwtToken);

print('Quote ID: ${quote.id}');
print('Expires at: ${quote.expiresAt.toIso8601String()}');
print('Still valid: ${quote.expiresAt.isAfter(DateTime.now())}');
```

## Price formulas

The SEP-38 spec defines these relationships between price, amounts, and fees:

```
sell_amount = total_price * buy_amount
```

When the fee is in the sell asset:
```
sell_amount - fee = price * buy_amount
```

When the fee is in the buy asset:
```
sell_amount = price * (buy_amount + fee)
```

## Error handling

The SDK provides specific exception classes for different error scenarios. Always wrap quote service calls in try-catch blocks for production use:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

SEP38QuoteService quoteService = await SEP38QuoteService.fromDomain('anchor.example.com');

try {
  SEP38PostQuoteRequest request = SEP38PostQuoteRequest(
    context: 'sep6',
    sellAsset: 'iso4217:USD',
    buyAsset: 'stellar:USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
    sellAmount: '100',
  );

  SEP38QuoteResponse quote = await quoteService.postQuote(request, jwtToken);
  print('Quote created: ${quote.id}');

} on ArgumentError catch (e) {
  // Invalid parameters (e.g., both sellAmount and buyAmount provided)
  print('Invalid request: $e');

} on SEP38BadRequest catch (e) {
  // HTTP 400 - Invalid request parameters
  print('Bad request: ${e.error}');

} on SEP38PermissionDenied catch (e) {
  // HTTP 403 - Authentication failed or not authorized
  print('Permission denied: ${e.error}');

} on SEP38NotFound catch (e) {
  // HTTP 404 - Quote not found (for getQuote)
  print('Quote not found: ${e.error}');

} on SEP38UnknownResponse catch (e) {
  // Other HTTP errors
  print('Unexpected error: code=${e.code}, body=${e.body}');
}
```

### Exception reference

| Exception | HTTP Status | Common Causes | Solution |
|-----------|-------------|---------------|----------|
| `ArgumentError` | N/A | Both `sellAmount` and `buyAmount` provided, or neither provided | Provide exactly one of the two amounts |
| `SEP38BadRequest` | 400 | Invalid asset format, unsupported asset pair, invalid context | Check asset identifiers and required fields |
| `SEP38PermissionDenied` | 403 | Missing JWT, expired JWT, or user not authorized | Re-authenticate with SEP-10 |
| `SEP38NotFound` | 404 | Quote ID doesn't exist (for `getQuote`) | Verify quote ID; it may have expired and been removed |
| `SEP38UnknownResponse` | Other | Server error or unexpected response | Check anchor status; retry later |

## SDK classes reference

### Service class

| Class | Description |
|-------|-------------|
| `SEP38QuoteService` | Main service class with methods: `info()`, `prices()`, `price()`, `postQuote()`, `getQuote()` |

### Request classes

| Class | Description |
|-------|-------------|
| `SEP38PostQuoteRequest` | Request body for creating firm quotes via `postQuote()` |

### Response classes

| Class | Description |
|-------|-------------|
| `SEP38InfoResponse` | Response from `info()` containing available assets |
| `SEP38PricesResponse` | Response from `prices()` containing indicative prices for multiple assets |
| `SEP38PriceResponse` | Response from `price()` containing indicative price for a single pair |
| `SEP38QuoteResponse` | Response from `postQuote()` and `getQuote()` containing firm quote details |

### Model classes

| Class | Description |
|-------|-------------|
| `SEP38Asset` | Asset information including delivery methods and country availability |
| `SEP38BuyAsset` | Buy asset option with price from `prices()` response |
| `SEP38Fee` | Fee structure with total amount and optional breakdown |
| `SEP38FeeDetails` | Individual fee component (name, amount, description) |
| `Sep38SellDeliveryMethod` | Method for delivering off-chain assets to the anchor |
| `Sep38BuyDeliveryMethod` | Method for receiving off-chain assets from the anchor |

### Exception classes

| Class | Description |
|-------|-------------|
| `SEP38BadRequest` | HTTP 400 - Invalid request |
| `SEP38PermissionDenied` | HTTP 403 - Authentication required or failed |
| `SEP38NotFound` | HTTP 404 - Quote not found |
| `SEP38UnknownResponse` | Other HTTP errors |

## Related SEPs

- [SEP-10](sep-10.md) - Authentication for traditional Stellar accounts
- [SEP-6](sep-06.md) - Programmatic deposit/withdrawal (uses quotes with `context: "sep6"`)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal (uses quotes with `context: "sep24"`)

## Further reading

- [SDK test cases](../../test/integration/sep0038_test.dart) - Examples of all SEP-38 functionality

## Reference

- [SEP-38 Specification (v2.5.0)](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md)

---

[Back to SEP Overview](README.md)
