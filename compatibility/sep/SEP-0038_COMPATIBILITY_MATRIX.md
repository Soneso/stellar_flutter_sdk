# SEP-0038 (Anchor RFQ API) Compatibility Matrix

**Generated:** 2026-03-10 19:47:51  
**SDK Version:** 3.0.4  
**SEP Version:** 2.5.0  
**SEP Status:** Draft  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md

## SEP Summary

This protocol enables anchors to accept off-chain assets in exchange for
different on-chain assets, and vice versa. Specifically, it enables anchors to
provide quotes that can be referenced within the context of existing Stellar
Ecosystem Proposals. How the exchange of assets is facilitated is outside the
scope of this document.

## Overall Coverage

**Total Coverage:** 100.0% (58/58 fields)

- ✅ **Implemented:** 58/58
- ❌ **Not Implemented:** 0/58

**Required Fields:** 100.0% (39/39)

**Optional Fields:** 100.0% (19/19)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0038/quote.dart`

### Key Classes

- **`SEP38QuoteService`**: Main service for SEP-38 quote/RFQ operations
- **`SEP38PostQuoteRequest`**: Request for creating a firm quote
- **`SEP38QuoteResponse`**: Response containing firm quote details
- **`SEP38PriceResponse`**: Response containing single price quote
- **`SEP38Fee`**: Fee information for a quote
- **`SEP38FeeDetails`**: Detailed fee breakdown
- **`SEP38PricesResponse`**: Response containing indicative prices
- **`SEP38InfoResponse`**: Response from /info endpoint with supported assets
- **`SEP38Asset`**: Asset information with delivery methods and exchange info
- **`SEP38BuyAsset`**: Buy asset configuration with delivery methods
- **`Sep38SellDeliveryMethod`**: Delivery method for selling assets
- **`Sep38BuyDeliveryMethod`**: Delivery method for buying assets
- **`SEP38ResponseException`**: Base exception for SEP-38 errors
- **`SEP38BadRequest`**: Exception for invalid request parameters
- **`SEP38PermissionDenied`**: Exception when access is denied
- **`SEP38NotFound`**: Exception when quote is not found
- **`SEP38UnknownResponse`**: Exception for unrecognized response format

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Asset Fields | 100.0% | 100.0% | 4 | 0 | 4 |
| Buy Asset Fields | 100.0% | 100.0% | 3 | 0 | 3 |
| Delivery Method Fields | 100.0% | 100.0% | 2 | 0 | 2 |
| Fee Details Fields | 100.0% | 100.0% | 3 | 0 | 3 |
| Fee Fields | 100.0% | 100.0% | 3 | 0 | 3 |
| Get Quote Endpoint | 100.0% | 100.0% | 1 | 0 | 1 |
| Info Endpoint | 100.0% | 100.0% | 1 | 0 | 1 |
| Info Response Fields | 100.0% | 100.0% | 1 | 0 | 1 |
| Post Quote Endpoint | 100.0% | 100.0% | 1 | 0 | 1 |
| Post Quote Request Fields | 100.0% | 100.0% | 9 | 0 | 9 |
| Price Endpoint | 100.0% | 100.0% | 1 | 0 | 1 |
| Price Request Parameters | 100.0% | 100.0% | 8 | 0 | 8 |
| Price Response Fields | 100.0% | 100.0% | 5 | 0 | 5 |
| Prices Endpoint | 100.0% | 100.0% | 1 | 0 | 1 |
| Prices Request Parameters | 100.0% | 100.0% | 5 | 0 | 5 |
| Prices Response Fields | 100.0% | 100.0% | 1 | 0 | 1 |
| Quote Response Fields | 100.0% | 100.0% | 9 | 0 | 9 |

## Detailed Field Comparison

### Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset` | ✓ | ✅ | `asset` | Asset identifier in Asset Identification Format |
| `buy_delivery_methods` |  | ✅ | `buyDeliveryMethods` | Array of delivery methods for buying this asset |
| `country_codes` |  | ✅ | `countryCodes` | Array of ISO 3166-2 or ISO 3166-1 alpha-2 country codes |
| `sell_delivery_methods` |  | ✅ | `sellDeliveryMethods` | Array of delivery methods for selling this asset |

### Buy Asset Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset` | ✓ | ✅ | `asset` | Asset identifier in Asset Identification Format |
| `decimals` | ✓ | ✅ | `decimals` | Number of decimals for the buy asset |
| `price` | ✓ | ✅ | `price` | Price offered by anchor for one unit of buy_asset |

### Delivery Method Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `description` | ✓ | ✅ | `description` | Human-readable description of the delivery method |
| `name` | ✓ | ✅ | `name` | Delivery method name identifier |

### Fee Details Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `amount` | ✓ | ✅ | `amount` | Fee amount as decimal string |
| `description` |  | ✅ | `description` | Human-readable description of the fee |
| `name` | ✓ | ✅ | `name` | Name identifier for the fee component |

### Fee Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `asset` | ✓ | ✅ | `asset` | Asset identifier for the fee |
| `details` |  | ✅ | `details` | Optional array of fee breakdown objects |
| `total` | ✓ | ✅ | `total` | Total fee amount as decimal string |

### Get Quote Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `get_quote_endpoint` | ✓ | ✅ | `getQuote` | GET /quote/:id - Fetch a previously-provided firm quote |

### Info Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `info_endpoint` | ✓ | ✅ | `info` | GET /info - Returns supported Stellar and off-chain assets available for trading |

### Info Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `assets` | ✓ | ✅ | `assets` | Array of asset objects supported for trading |

### Post Quote Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `post_quote_endpoint` | ✓ | ✅ | `postQuote` | POST /quote - Request a firm quote for asset exchange |

### Post Quote Request Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `buy_amount` |  | ✅ | `buyAmount` | Amount of buy_asset to exchange for (mutually exclusive with sell_amount) |
| `buy_asset` | ✓ | ✅ | `buyAsset` | Asset client would like to exchange for sell_asset |
| `buy_delivery_method` |  | ✅ | `buyDeliveryMethod` | Delivery method for off-chain buy asset |
| `context` | ✓ | ✅ | `context` | Context for quote usage (sep6 or sep31) |
| `country_code` |  | ✅ | `countryCode` | ISO 3166-2 or ISO 3166-1 alpha-2 country code |
| `expire_after` |  | ✅ | `expireAfter` | Requested expiration timestamp for the quote (ISO 8601) |
| `sell_amount` |  | ✅ | `sellAmount` | Amount of sell_asset to exchange (mutually exclusive with buy_amount) |
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset client would like to sell |
| `sell_delivery_method` |  | ✅ | `sellDeliveryMethod` | Delivery method for off-chain sell asset |

### Price Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `price_endpoint` | ✓ | ✅ | `price` | GET /price - Returns indicative price for a specific asset pair |

### Price Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `buy_amount` |  | ✅ | `buyAmount` | Amount of buy_asset to exchange for (mutually exclusive with sell_amount) |
| `buy_asset` | ✓ | ✅ | `buyAsset` | Asset client would like to exchange for sell_asset |
| `buy_delivery_method` |  | ✅ | `buyDeliveryMethod` | Delivery method for off-chain buy asset |
| `context` | ✓ | ✅ | `context` | Context for quote usage (sep6 or sep31) |
| `country_code` |  | ✅ | `countryCode` | ISO 3166-2 or ISO 3166-1 alpha-2 country code |
| `sell_amount` |  | ✅ | `sellAmount` | Amount of sell_asset to exchange (mutually exclusive with buy_amount) |
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset client would like to sell |
| `sell_delivery_method` |  | ✅ | `sellDeliveryMethod` | Delivery method for off-chain sell asset |

### Price Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `buy_amount` | ✓ | ✅ | `buyAmount` | Amount of buy_asset that will be received |
| `fee` | ✓ | ✅ | `fee` | Fee object with total, asset, and optional details |
| `price` | ✓ | ✅ | `price` | Base conversion price excluding fees |
| `sell_amount` | ✓ | ✅ | `sellAmount` | Amount of sell_asset that will be exchanged |
| `total_price` | ✓ | ✅ | `totalPrice` | Total conversion price including fees |

### Prices Endpoint

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `prices_endpoint` | ✓ | ✅ | `prices` | GET /prices - Returns indicative prices of off-chain assets in exchange for Stellar assets |

### Prices Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `buy_delivery_method` |  | ✅ | `buyDeliveryMethod` | Delivery method for off-chain buy asset |
| `country_code` |  | ✅ | `countryCode` | ISO 3166-2 or ISO 3166-1 alpha-2 country code |
| `sell_amount` | ✓ | ✅ | `sellAmount` | Amount of sell_asset to exchange |
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset to sell using Asset Identification Format |
| `sell_delivery_method` |  | ✅ | `sellDeliveryMethod` | Delivery method for off-chain sell asset |

### Prices Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `buy_assets` | ✓ | ✅ | `buyAssets` | Array of buy asset objects with prices |

### Quote Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `buy_amount` | ✓ | ✅ | `buyAmount` | Amount of buy_asset to be received |
| `buy_asset` | ✓ | ✅ | `buyAsset` | Asset to be bought |
| `expires_at` | ✓ | ✅ | `expiresAt` | Expiration timestamp for the quote (ISO 8601) |
| `fee` | ✓ | ✅ | `fee` | Fee object with total, asset, and optional details |
| `id` | ✓ | ✅ | `id` | Unique identifier for the quote |
| `price` | ✓ | ✅ | `price` | Base conversion price excluding fees |
| `sell_amount` | ✓ | ✅ | `sellAmount` | Amount of sell_asset to be exchanged |
| `sell_asset` | ✓ | ✅ | `sellAsset` | Asset to be sold |
| `total_price` | ✓ | ✅ | `totalPrice` | Total conversion price including fees |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0038!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
