# SEP-01: Stellar info file (stellar.toml)

The stellar.toml file is a standardized configuration file that anchors and organizations host at their domains. It tells wallets and other services how to interact with their accounts, assets, and services. The SDK fetches and parses these files so your application can discover anchor endpoints.

**When to use:** Use this when your application needs to discover an anchor's service endpoints (SEP-6, SEP-10, SEP-24, federation, etc.) by fetching their stellar.toml file.

See the [SEP-01 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) for protocol details.

**Note for implementers:** When hosting a stellar.toml file:
- File size must not exceed **100KB**
- Return `Access-Control-Allow-Origin: *` header for CORS
- Set `Content-Type: text/plain` so browsers render the file instead of downloading it

## Quick example

This example demonstrates loading a stellar.toml file from a domain and accessing service endpoints:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Load stellar.toml from a domain
StellarToml stellarToml = await StellarToml.fromDomain('testanchor.stellar.org');

// Get service endpoints
GeneralInformation info = stellarToml.generalInformation;
print('Transfer Server: ${info.transferServerSep24}');
print('Web Auth: ${info.webAuthEndpoint}');
```

## Loading stellar.toml

### From a domain

The SDK automatically constructs the URL `https://DOMAIN/.well-known/stellar.toml` and fetches the file:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('soneso.com');

// Access organization info
Documentation? docs = stellarToml.documentation;
if (docs != null) {
  print('Organization: ${docs.orgName}');
  print('Support: ${docs.orgSupportEmail}');
}
```

### From a string

If you already have the TOML content (e.g., from a cached copy or test fixture), you can parse it directly:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String tomlContent = '''
VERSION="2.0.0"
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
FEDERATION_SERVER="https://example.com/federation"
TRANSFER_SERVER_SEP0024="https://example.com/sep24"
WEB_AUTH_ENDPOINT="https://example.com/auth"
SIGNING_KEY="GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK"

[DOCUMENTATION]
ORG_NAME="Example Anchor"
ORG_URL="https://example.com"
''';

StellarToml stellarToml = StellarToml(tomlContent);
GeneralInformation info = stellarToml.generalInformation;
print('Version: ${info.version}');
```

## Accessing data

### General information

The general information section contains service endpoints for SEP protocols and account information:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('testanchor.stellar.org');
GeneralInformation info = stellarToml.generalInformation;

// Protocol version
String? version = info.version;                        // SEP-1 version (e.g., "2.0.0")

// Service endpoints
String? federationServer = info.federationServer;      // SEP-02 Federation
String? transferServer = info.transferServer;           // SEP-06 Deposit/Withdrawal
String? transferServerSep24 = info.transferServerSep24; // SEP-24 Interactive
String? kycServer = info.kYCServer;                    // SEP-12 KYC
String? webAuthEndpoint = info.webAuthEndpoint;        // SEP-10 Web Auth
String? directPaymentServer = info.directPaymentServer; // SEP-31 Direct Payments
String? anchorQuoteServer = info.anchorQuoteServer;    // SEP-38 Quotes

// SEP-45 Contract Web Authentication (Soroban)
String? webAuthForContracts = info.webAuthForContractsEndpoint; // SEP-45 endpoint
String? webAuthContractId = info.webAuthContractId;    // SEP-45 contract ID (C... address)

// Signing keys
String? signingKey = info.signingKey;                  // For SEP-10 challenges
String? uriSigningKey = info.uriRequestSigningKey;     // For SEP-07 URIs

// Deprecated (SEP-03 Compliance Protocol)
String? authServer = info.authServer;                  // Deprecated

// Network info
String? networkPassphrase = info.networkPassphrase;
String? horizonUrl = info.horizonUrl;

// Organization accounts
List<String> accounts = info.accounts; // List of G... account IDs controlled by this domain
```

### Organization documentation

The documentation section contains contact and compliance information about the organization:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('testanchor.stellar.org');
Documentation? docs = stellarToml.documentation;

if (docs != null) {
  // Basic organization info
  print('Name: ${docs.orgName}');
  print('DBA: ${docs.orgDBA}');
  print('URL: ${docs.orgUrl}');
  print('Logo: ${docs.orgLogo}');
  print('Description: ${docs.orgDescription}');

  // Physical address with attestation
  print('Address: ${docs.orgPhysicalAddress}');
  print('Address Proof: ${docs.orgPhysicalAddressAttestation}');

  // Phone number with attestation (E.164 format)
  print('Phone: ${docs.orgPhoneNumber}');
  print('Phone Proof: ${docs.orgPhoneNumberAttestation}');

  // Contact information
  print('Official Email: ${docs.orgOfficialEmail}');
  print('Support Email: ${docs.orgSupportEmail}');

  // Social accounts
  print('Keybase: ${docs.orgKeybase}');
  print('Twitter: ${docs.orgTwitter}');
  print('GitHub: ${docs.orgGithub}');

  // Licensing information (for regulated entities)
  print('Licensing Authority: ${docs.orgLicensingAuthority}');
  print('License Type: ${docs.orgLicenseType}');
  print('License Number: ${docs.orgLicenseNumber}');
}
```

### Principals (points of contact)

The principals section contains identifying information for the organization's primary contact persons:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('testanchor.stellar.org');
List<PointOfContact>? principals = stellarToml.pointsOfContact;

if (principals != null) {
  for (PointOfContact principal in principals) {
    // Basic contact info
    print('Name: ${principal.name}');
    print('Email: ${principal.email}');

    // Social accounts for verification
    print('Keybase: ${principal.keybase}');
    print('Telegram: ${principal.telegram}');
    print('Twitter: ${principal.twitter}');
    print('GitHub: ${principal.github}');

    // Identity verification hashes (SHA-256)
    print('ID Photo Hash: ${principal.idPhotoHash}');
    print('Verification Photo Hash: ${principal.verificationPhotoHash}');

    print('---');
  }
}
```

### Currencies (assets)

The currencies section provides information about assets issued by the organization, including both classic Stellar assets and Soroban token contracts:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('testanchor.stellar.org');
List<Currency>? currencies = stellarToml.currencies;

if (currencies != null) {
  for (Currency currency in currencies) {
    // Basic token info
    print('Code: ${currency.code}');
    print('Name: ${currency.name}');
    print('Description: ${currency.desc}');
    print('Conditions: ${currency.conditions}');
    print('Status: ${currency.status}');  // live, dead, test, or private
    print('Decimals: ${currency.displayDecimals}');
    print('Image: ${currency.image}');

    // Token identifier (one of these will be set)
    print('Issuer: ${currency.issuer}');       // G... for classic assets
    print('Contract: ${currency.contract}');   // C... for Soroban contracts (SEP-41)
    print('Code Template: ${currency.codeTemplate}'); // Pattern for multiple assets

    // Supply information (mutually exclusive)
    print('Fixed Number: ${currency.fixedNumber}');
    print('Max Number: ${currency.maxNumber}');
    print('Unlimited: ${currency.isUnlimited == true ? 'Yes' : 'No'}');

    // Anchored asset information
    print('Is Anchored: ${currency.isAssetAnchored == true ? 'Yes' : 'No'}');
    print('Anchor Type: ${currency.anchorAssetType}');  // fiat, crypto, nft, stock, bond, commodity, realestate, other
    print('Anchor Asset: ${currency.anchorAsset}');
    print('Attestation: ${currency.attestationOfReserve}');
    print('Redemption: ${currency.redemptionInstructions}');

    // Collateral proof for crypto-backed tokens
    if (currency.collateralAddresses != null) {
      print('Collateral Addresses: ${currency.collateralAddresses!.join(', ')}');
      print('Collateral Messages: ${(currency.collateralAddressMessages ?? []).join(', ')}');
      print('Collateral Signatures: ${(currency.collateralAddressSignatures ?? []).join(', ')}');
    }

    // SEP-08 Regulated Assets
    print('Regulated: ${currency.regulated == true ? 'Yes' : 'No'}');
    print('Approval Server: ${currency.approvalServer}');
    print('Approval Criteria: ${currency.approvalCriteria}');

    print('---');
  }
}
```

### Linked currencies

Some stellar.toml files link to separate TOML files for detailed currency information. Use `currencyFromUrl()` to fetch the full currency data:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('example.com');
List<Currency>? currencies = stellarToml.currencies;

if (currencies != null) {
  for (Currency currency in currencies) {
    // Check if currency details are in a separate file
    if (currency.toml != null) {
      try {
        Currency linkedCurrency = await StellarToml.currencyFromUrl(currency.toml!);
        print('Code: ${linkedCurrency.code}');
        print('Issuer: ${linkedCurrency.issuer}');
        print('Name: ${linkedCurrency.name}');
      } catch (e) {
        print('Failed to load linked currency: $e');
      }
    } else {
      // Currency data is inline
      print('Code: ${currency.code}');
    }
  }
}
```

### Validators

The validators section is for organizations running Stellar validator nodes. Combined with SEP-20, it allows public declaration of nodes and archive locations:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('stellar.org');
List<Validator>? validators = stellarToml.validators;

if (validators != null) {
  for (Validator validator in validators) {
    print('Alias: ${validator.alias}');         // Config name (e.g., "sdf-1")
    print('Display Name: ${validator.displayName}');
    print('Public Key: ${validator.publicKey}'); // G... account
    print('Host: ${validator.host}');           // IP:port or domain:port
    print('History: ${validator.history}');     // Archive URL
    print('---');
  }
}
```

## Error handling

The SDK throws exceptions when the stellar.toml file cannot be fetched or parsed. Always wrap network calls in try-catch blocks:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Handle network failures
try {
  StellarToml stellarToml = await StellarToml.fromDomain('nonexistent-domain.invalid');
} catch (e) {
  // Domain unreachable, DNS failure, or stellar.toml not found (404)
  print('Failed to load stellar.toml: $e');
}

// Handle TOML parsing errors
try {
  String badToml = 'this is not valid TOML [[[';
  StellarToml stellarToml = StellarToml(badToml);
} on FormatException catch (e) {
  print('Failed to parse stellar.toml: $e');
}
```

After loading, check for missing optional data before using it. Not all anchors implement every SEP:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StellarToml stellarToml = await StellarToml.fromDomain('example.com');
GeneralInformation info = stellarToml.generalInformation;

// Check for SEP support before using endpoints
if (info.webAuthEndpoint == null) {
  print("This anchor doesn't support SEP-10 authentication");
}

if (info.transferServerSep24 == null) {
  print("This anchor doesn't support SEP-24 interactive deposits");
}

if (info.kYCServer == null) {
  print("This anchor doesn't support SEP-12 KYC");
}

// Documentation section may also be null
Documentation? docs = stellarToml.documentation;
if (docs == null) {
  print('No organization documentation available');
}
```

## Custom HTTP client

You can provide a custom HTTP client for testing or to configure timeouts, proxies, and other HTTP options:

```dart
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create a custom HTTP client
final httpClient = http.Client();

StellarToml stellarToml = await StellarToml.fromDomain(
  'testanchor.stellar.org',
  httpClient: httpClient,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

## Testing your stellar.toml

Use these tools to validate your stellar.toml configuration:

- **[Stellar Anchor Validator](https://anchor-tests.stellar.org/)** - Test suite for anchor implementations, including stellar.toml validation
- **[stellar.toml checker](https://stellar.sui.li)** - Quick validation tool for stellar.toml files

## Related SEPs

SEPs that rely on stellar.toml for endpoint discovery or configuration:

- [SEP-02 Federation](sep-02.md) - `FEDERATION_SERVER`
- [SEP-06 Deposit/Withdrawal](sep-06.md) - `TRANSFER_SERVER`
- [SEP-07 URI Scheme](sep-07.md) - `URI_REQUEST_SIGNING_KEY`
- [SEP-08 Regulated Assets](sep-08.md) - Currency `approval_server`
- [SEP-10 Authentication](sep-10.md) - `WEB_AUTH_ENDPOINT`, `SIGNING_KEY`
- [SEP-12 KYC](sep-12.md) - `KYC_SERVER`
- [SEP-24 Interactive](sep-24.md) - `TRANSFER_SERVER_SEP0024`
- [SEP-38 Quotes](sep-38.md) - `ANCHOR_QUOTE_SERVER`
- [SEP-45 Contract Auth](sep-45.md) - `WEB_AUTH_FOR_CONTRACTS_ENDPOINT`, `WEB_AUTH_CONTRACT_ID`

---

[Back to SEP Overview](README.md)
