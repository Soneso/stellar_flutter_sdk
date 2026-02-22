# SEP-01: Stellar Info File (stellar.toml)

**Purpose:** Fetch and parse a domain's `stellar.toml` to discover anchor service endpoints, supported assets, validators, and organization details.
**Prerequisites:** None

## Table of Contents

1. [Loading stellar.toml](#1-loading-stellartoml)
2. [General Information](#2-general-information)
3. [Organization Documentation](#3-organization-documentation)
4. [Currencies (Assets)](#4-currencies-assets)
5. [Principals (Points of Contact)](#5-principals-points-of-contact)
6. [Validators](#6-validators)
7. [Error Handling](#7-error-handling)
8. [Common Pitfalls](#8-common-pitfalls)
9. [Typical Integration Pattern](#9-typical-integration-pattern)

---

## 1. Loading stellar.toml

### From a domain

`StellarToml.fromDomain()` is a static async factory. It constructs
`https://DOMAIN/.well-known/stellar.toml`, fetches it, and returns a parsed
`StellarToml` instance. Pass only the bare domain — no protocol prefix.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Fetches https://anchor.example.com/.well-known/stellar.toml
try {
  StellarToml stellarToml = await StellarToml.fromDomain('anchor.example.com');
  GeneralInformation info = stellarToml.generalInformation;
  print('WebAuth: ${info.webAuthEndpoint}');
  print('SEP-24: ${info.transferServerSep24}');
  print('Signing key: ${info.signingKey}');
} catch (e) {
  print('Failed to load stellar.toml: $e');
}
```

Throws `Exception` if the HTTP response is not 200. Throws `FormatException`
if the TOML cannot be parsed.

### With a custom HTTP client or headers

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Custom client (timeouts, proxies, etc.)
final client = http.Client();
StellarToml stellarToml = await StellarToml.fromDomain(
  'anchor.example.com',
  httpClient: client,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

### From a TOML string

Parse an already-fetched or locally-stored TOML string with the default
constructor `StellarToml(String toml)`. This is synchronous.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String tomlContent = '''
VERSION="2.7.0"
NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
WEB_AUTH_ENDPOINT="https://anchor.example.com/auth"
TRANSFER_SERVER_SEP0024="https://anchor.example.com/sep24"
SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"

[DOCUMENTATION]
ORG_NAME="Example Anchor"
ORG_URL="https://anchor.example.com"

[[CURRENCIES]]
code="USDC"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
display_decimals=2
''';

StellarToml stellarToml = StellarToml(tomlContent);
print(stellarToml.generalInformation.version);            // 2.7.0
print(stellarToml.documentation?.orgName);               // Example Anchor
print(stellarToml.currencies?.first.code);               // USDC
```

### TOML syntax rules for stellar.toml

Use these TOML markers correctly — the SDK corrects common mistakes (see
[Common Pitfalls](#7-common-pitfalls)), but writing them correctly is best:

| Section | Correct TOML |
|---------|-------------|
| `DOCUMENTATION` | `[DOCUMENTATION]` (single table) |
| `PRINCIPALS` | `[[PRINCIPALS]]` (array of tables) |
| `CURRENCIES` | `[[CURRENCIES]]` (array of tables) |
| `VALIDATORS` | `[[VALIDATORS]]` (array of tables) |
| `ACCOUNTS` | `ACCOUNTS=["G...", "G..."]` (inline array) |

---

## 2. General Information

Access via `stellarToml.generalInformation` (always non-null, direct field
access — not a getter method). All fields are `String?` except `accounts`
which is `List<String>` (never null, may be empty).

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('anchor.example.com');
GeneralInformation info = stellarToml.generalInformation;

// SEP spec version
info.version;                       // String?  e.g. "2.7.0"

// Network
info.networkPassphrase;             // String?  mainnet or testnet passphrase
info.horizonUrl;                    // String?  anchor's public Horizon instance

// SEP service endpoints — null when the anchor does not support that SEP
info.federationServer;              // String?  SEP-02 federation
info.transferServer;                // String?  SEP-06 deposit/withdrawal
info.transferServerSep24;           // String?  SEP-24 interactive deposit/withdrawal
info.kYCServer;                     // String?  SEP-12 KYC  (note: uppercase YC)
info.webAuthEndpoint;               // String?  SEP-10 web authentication
info.directPaymentServer;           // String?  SEP-31 cross-border payments
info.anchorQuoteServer;             // String?  SEP-38 quotes
info.uriRequestSigningKey;          // String?  SEP-07 URI signing key (G...)
info.webAuthForContractsEndpoint;   // String?  SEP-45 contract auth endpoint
info.webAuthContractId;             // String?  SEP-45 contract address (C...)

// Signing key for SEP-10 challenge verification
info.signingKey;                    // String?  G... public key

// Accounts controlled by this domain
info.accounts;                      // List<String>  G... accounts (never null)

// Deprecated
info.authServer;                    // String?  SEP-03 compliance (deprecated)
```

Always null-check endpoints before using them:

```dart
GeneralInformation info = stellarToml.generalInformation;

if (info.webAuthEndpoint == null) {
  throw Exception('Anchor does not support SEP-10 authentication');
}
if (info.transferServerSep24 == null) {
  throw Exception('Anchor does not support SEP-24');
}

// Safe to use
final webAuthUrl = info.webAuthEndpoint!;
final sep24Url = info.transferServerSep24!;
```

---

## 3. Organization Documentation

Access via `stellarToml.documentation` — returns `Documentation?` (null if
the `[DOCUMENTATION]` section is absent). All fields are `String?`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('anchor.example.com');
Documentation? docs = stellarToml.documentation;

if (docs != null) {
  docs.orgName;                        // String?  legal name
  docs.orgDBA;                         // String?  doing-business-as name
  docs.orgUrl;                         // String?  official website URL
  docs.orgLogo;                        // String?  URL to PNG logo (transparent bg)
  docs.orgDescription;                 // String?  short description
  docs.orgPhysicalAddress;             // String?  mailing address
  docs.orgPhysicalAddressAttestation;  // String?  URL to address proof document
  docs.orgPhoneNumber;                 // String?  E.164 format e.g. "+14155552671"
  docs.orgPhoneNumberAttestation;      // String?  URL to phone bill image
  docs.orgKeybase;                     // String?  Keybase username
  docs.orgTwitter;                     // String?  Twitter handle (without @)
  docs.orgGithub;                      // String?  GitHub organization name
  docs.orgOfficialEmail;               // String?  official contact email
  docs.orgSupportEmail;                // String?  user support email
  docs.orgLicensingAuthority;          // String?  e.g. "FinCEN"
  docs.orgLicenseType;                 // String?  e.g. "Money Transmitter"
  docs.orgLicenseNumber;               // String?  license number
}
```

---

## 4. Currencies (Assets)

Access via `stellarToml.currencies` — returns `List<Currency>?` (null if
`[[CURRENCIES]]` is absent). Each `Currency` object has only the fields that
were populated in the TOML; all others are null.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('anchor.example.com');
List<Currency>? currencies = stellarToml.currencies;

if (currencies != null) {
  for (Currency currency in currencies) {
    // Token identifier
    currency.code;              // String?  e.g. "USDC"
    currency.issuer;            // String?  G... issuer (classic Stellar assets)
    currency.contract;          // String?  C... contract address (SEP-41 tokens)
    currency.codeTemplate;      // String?  wildcard pattern e.g. "CORN????????"

    // Display info
    currency.name;              // String?  short display name
    currency.desc;              // String?  description
    currency.conditions;        // String?  terms or conditions text
    currency.image;             // String?  URL to PNG logo
    currency.displayDecimals;   // int?     preferred decimal places for display
    currency.status;            // String?  "live", "dead", "test", or "private"

    // Supply model — at most one is typically set
    currency.fixedNumber;       // int?     total fixed supply (never more issued)
    currency.maxNumber;         // int?     maximum supply cap
    currency.isUnlimited;       // bool?    true = dilutable at issuer's discretion

    // Anchored asset info
    currency.isAssetAnchored;         // bool?    true if backed by off-chain asset
    currency.anchorAssetType;         // String?  "fiat", "crypto", "nft", "stock",
                                      //          "bond", "commodity", "realestate", "other"
    currency.anchorAsset;             // String?  e.g. "USD", "BTC"
    currency.attestationOfReserve;    // String?  URL to audit/reserve proof
    currency.redemptionInstructions;  // String?  how to redeem the underlying asset

    // Crypto-backed collateral proof (parallel lists, same length)
    currency.collateralAddresses;          // List<String>?  crypto addresses holding collateral
    currency.collateralAddressMessages;    // List<String>?  signed reserve messages
    currency.collateralAddressSignatures;  // List<String>?  base64-encoded signatures

    // SEP-08 Regulated Assets
    currency.regulated;          // bool?    true if requires approval server
    currency.approvalServer;     // String?  URL of SEP-08 approval service
    currency.approvalCriteria;   // String?  human-readable approval requirements

    // Linked currency (see section below)
    currency.toml;               // String?  URL to external TOML file for this currency
  }
}
```

### Linked currencies

A currency entry can contain only `toml` pointing to a separate TOML file
rather than embedding all fields inline. When `currency.toml != null`, all
other fields on that entry are `null`. Load the full data with the static
async method `StellarToml.currencyFromUrl()`:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('anchor.example.com');

if (stellarToml.currencies != null) {
  for (Currency currency in stellarToml.currencies!) {
    if (currency.toml != null) {
      // This entry is a link — all other fields are null
      try {
        Currency linked = await StellarToml.currencyFromUrl(currency.toml!);
        print('${linked.code}: ${linked.desc}');
        print('Issuer: ${linked.issuer}');
      } catch (e) {
        print('Failed to fetch linked currency: $e');
      }
    } else {
      // Inline entry — fields are populated directly
      print('${currency.code}: ${currency.issuer}');
    }
  }
}
```

`currencyFromUrl()` also accepts optional `httpClient` and `httpRequestHeaders`
parameters, identical to `fromDomain()`.

### Soroban contract tokens (SEP-41)

Tokens deployed as Soroban smart contracts use `contract` instead of `issuer`:

```dart
// Classic Stellar asset: has issuer, no contract
currency.code == 'USDC'
currency.issuer == 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN'
currency.contract == null

// Soroban token: has contract, issuer may be null
currency.code == 'USDC'
currency.contract == 'CC4DZNN2TPLUOAIRBI3CY7TGRFFCCW6GNVVRRQ3QIIBY6TM6M2RVMBMC'
currency.issuer == null  // not set for contract-only tokens
```

---

## 5. Principals (Points of Contact)

Access via `stellarToml.pointsOfContact` — returns `List<PointOfContact>?`
(null if `[[PRINCIPALS]]` is absent). The TOML section is named `PRINCIPALS`
but the Dart class and property are `PointOfContact` / `pointsOfContact`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('anchor.example.com');
List<PointOfContact>? principals = stellarToml.pointsOfContact;

if (principals != null) {
  for (PointOfContact principal in principals) {
    principal.name;                  // String?  full legal name
    principal.email;                 // String?  business email
    principal.keybase;               // String?  Keybase username
    principal.telegram;              // String?  Telegram handle
    principal.twitter;               // String?  Twitter handle
    principal.github;                // String?  GitHub username
    principal.idPhotoHash;           // String?  SHA-256 of government ID photo
    principal.verificationPhotoHash; // String?  SHA-256 of verification photo
  }
}
```

---

## 6. Validators

Access via `stellarToml.validators` — returns `List<Validator>?` (null if
`[[VALIDATORS]]` is absent). Most anchors do not run validators; this is
populated primarily by network node operators.

Note: TOML keys for validators are uppercase (`ALIAS`, `DISPLAY_NAME`,
`PUBLIC_KEY`, `HOST`, `HISTORY`), but Dart properties are camelCase.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('stellar.org');
List<Validator>? validators = stellarToml.validators;

if (validators != null) {
  for (Validator validator in validators) {
    validator.alias;        // String?  short name conforming to ^[a-z0-9-]{2,16}$
    validator.displayName;  // String?  human-readable name for quorum explorers
    validator.publicKey;    // String?  G... Stellar account associated with the node
    validator.host;         // String?  "domain.com:11625" or "IP:port"
    validator.history;      // String?  URL to published history archive
  }
}
```

---

## 7. Error Handling

All SEP-01 methods throw generic `Exception` on HTTP errors. TOML parse failures throw `FormatException` (though many common syntax errors are auto-corrected by `safeguardTomlContent()` before parsing).

| Method | Throws | Condition |
|--------|--------|-----------|
| `StellarToml.fromDomain()` | `Exception` | Non-200 HTTP status (`"Stellar toml not found, response status code {code}"`) |
| `StellarToml.fromDomain()` | `Exception` | Network failure (connection refused, DNS error, timeout) |
| `StellarToml(String)` | `FormatException` | TOML content is malformed beyond what auto-correction can fix |
| `StellarToml.currencyFromUrl()` | `Exception` | Non-200 HTTP status (`"Currency toml not found, response status code {code}"`) |
| `StellarToml.currencyFromUrl()` | `Exception` | Network failure |
| `StellarToml.currencyFromUrl()` | `FormatException` | Linked TOML content is malformed |

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  StellarToml stellarToml = await StellarToml.fromDomain('anchor.example.com');
} on FormatException catch (e) {
  print('Malformed TOML: $e');
} catch (e) {
  print('Failed to fetch stellar.toml: $e');
}
```

---

## 8. Common Pitfalls

**Wrong capitalization for kYCServer:**

```dart
// WRONG: info.kycServer  -- property does not exist
// CORRECT: info.kYCServer  -- uppercase YC
String? kycUrl = info.kYCServer;
```

**Confusing property name: pointsOfContact vs principals:**

```dart
// WRONG: stellarToml.principals  -- property does not exist
// CORRECT: stellarToml.pointsOfContact  -- the Dart property name
List<PointOfContact>? contacts = stellarToml.pointsOfContact;
```

**Accessing documentation without null check:**

```dart
// WRONG: will throw if [DOCUMENTATION] section is absent
print(stellarToml.documentation!.orgName);

// CORRECT: documentation is nullable
if (stellarToml.documentation != null) {
  print(stellarToml.documentation!.orgName);
}
// Or with null-aware operator
print(stellarToml.documentation?.orgName);
```

**Not null-checking service endpoints before use:**

```dart
// WRONG: will pass null to another service if anchor doesn't publish the endpoint
WebAuth webAuth = WebAuth(stellarToml.generalInformation.webAuthEndpoint!);

// CORRECT: verify support before proceeding
final info = stellarToml.generalInformation;
if (info.webAuthEndpoint == null || info.signingKey == null) {
  throw Exception('Anchor does not support SEP-10');
}
```

**accounts is never null (unlike other list fields):**

```dart
// WRONG: null check is unnecessary, may confuse readers
if (stellarToml.generalInformation.accounts != null) { ... }

// CORRECT: accounts is List<String> (never null, may be empty [])
final accounts = stellarToml.generalInformation.accounts;  // always a List
print('Domain controls ${accounts.length} accounts');
```

**Using fromDomain() without await:**

```dart
// WRONG: returns Future<StellarToml>, not StellarToml
StellarToml toml = StellarToml.fromDomain('anchor.example.com'); // compile error

// CORRECT: it is a Future — must await
StellarToml toml = await StellarToml.fromDomain('anchor.example.com');
```

**Malformed TOML syntax — the SDK auto-corrects these:**

The SDK's `safeguardTomlContent()` method silently fixes common real-world
errors before parsing. You do not need to call it manually — the constructor
calls it automatically. Corrections made:

| Invalid | Corrected to |
|---------|-------------|
| `[ACCOUNTS]` | `[[ACCOUNTS]]` |
| `[[DOCUMENTATION]]` | `[DOCUMENTATION]` |
| `[PRINCIPALS]` | `[[PRINCIPALS]]` |
| `[CURRENCIES]` | `[[CURRENCIES]]` |
| `[VALIDATORS]` | `[[VALIDATORS]]` |

This means even stellar.toml files with incorrect syntax parse successfully.

---

## 9. Typical Integration Pattern

Most SEP integrations start with SEP-01 discovery, then SEP-10 authentication:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> connectToAnchor(String domain, KeyPair userKeyPair) async {
  // Step 1: SEP-01 — discover what the anchor supports
  StellarToml stellarToml;
  try {
    stellarToml = await StellarToml.fromDomain(domain);
  } catch (e) {
    throw Exception('Cannot reach anchor stellar.toml: $e');
  }

  final info = stellarToml.generalInformation;

  // Verify the anchor supports what we need
  if (info.webAuthEndpoint == null || info.signingKey == null) {
    throw Exception('Anchor does not support SEP-10');
  }
  if (info.transferServerSep24 == null) {
    throw Exception('Anchor does not support SEP-24');
  }

  // Step 2: SEP-10 — authenticate and obtain JWT
  // (WebAuth uses SEP-01 discovery internally, but you can also pass endpoints directly)
  WebAuth webAuth = await WebAuth.fromDomain(domain, Network.PUBLIC);
  String jwt = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);

  // Step 3: SEP-24 — start interactive deposit/withdrawal
  TransferServerSEP24Service sep24 =
      await TransferServerSEP24Service.fromDomain(domain);
  SEP24DepositRequest request = SEP24DepositRequest();
  request.assetCode = 'USDC';
  request.jwt = jwt;
  SEP24InteractiveResponse response = await sep24.deposit(request);
  // Open response.url in a webview
  print('Open in webview: ${response.url}');
}
```
