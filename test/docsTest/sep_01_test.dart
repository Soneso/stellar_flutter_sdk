@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('sep-01: Quick example - parse from string', () {
    // Snippet from sep-01.md "From a string"
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

    expect(info.version, '2.0.0');
    expect(info.networkPassphrase, 'Test SDF Network ; September 2015');
    expect(info.federationServer, 'https://example.com/federation');
    expect(info.transferServerSep24, 'https://example.com/sep24');
    expect(info.webAuthEndpoint, 'https://example.com/auth');
    expect(info.signingKey, 'GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK');

    Documentation? docs = stellarToml.documentation;
    expect(docs, isNotNull);
    expect(docs!.orgName, 'Example Anchor');
    expect(docs.orgUrl, 'https://example.com');
  });

  test('sep-01: General information fields', () {
    // Snippet from sep-01.md "General information"
    String tomlContent = '''
VERSION="2.7.0"
NETWORK_PASSPHRASE="Test SDF Network ; September 2015"
FEDERATION_SERVER="https://example.com/federation"
TRANSFER_SERVER="https://example.com/sep6"
TRANSFER_SERVER_SEP0024="https://example.com/sep24"
KYC_SERVER="https://example.com/kyc"
WEB_AUTH_ENDPOINT="https://example.com/auth"
DIRECT_PAYMENT_SERVER="https://example.com/sep31"
ANCHOR_QUOTE_SERVER="https://example.com/sep38"
WEB_AUTH_FOR_CONTRACTS_ENDPOINT="https://example.com/sep45"
WEB_AUTH_CONTRACT_ID="CCXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
SIGNING_KEY="GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK"
URI_REQUEST_SIGNING_KEY="GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK"
AUTH_SERVER="https://example.com/compliance"
HORIZON_URL="https://horizon-testnet.stellar.org"
ACCOUNTS=["GCKX7PGTILCAM6NKST6PWNCBSMLHZJKFWXFHQLE4SUVKBQY3HOOYUNK"]
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    GeneralInformation info = stellarToml.generalInformation;

    expect(info.version, '2.7.0');
    expect(info.networkPassphrase, isNotNull);
    expect(info.federationServer, 'https://example.com/federation');
    expect(info.transferServer, 'https://example.com/sep6');
    expect(info.transferServerSep24, 'https://example.com/sep24');
    expect(info.kYCServer, 'https://example.com/kyc');
    expect(info.webAuthEndpoint, 'https://example.com/auth');
    expect(info.directPaymentServer, 'https://example.com/sep31');
    expect(info.anchorQuoteServer, 'https://example.com/sep38');
    expect(info.webAuthForContractsEndpoint, 'https://example.com/sep45');
    expect(info.webAuthContractId, 'CCXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');
    expect(info.signingKey, isNotNull);
    expect(info.uriRequestSigningKey, isNotNull);
    expect(info.authServer, 'https://example.com/compliance');
    expect(info.horizonUrl, 'https://horizon-testnet.stellar.org');
    expect(info.accounts, isNotEmpty);
    expect(info.accounts.first, startsWith('G'));
  });

  test('sep-01: Organization documentation', () {
    // Snippet from sep-01.md "Organization documentation"
    String tomlContent = '''
[DOCUMENTATION]
ORG_NAME="Test Anchor"
ORG_DBA="Test DBA"
ORG_URL="https://testanchor.example.com"
ORG_LOGO="https://testanchor.example.com/logo.png"
ORG_DESCRIPTION="A test anchor"
ORG_PHYSICAL_ADDRESS="123 Test St"
ORG_PHYSICAL_ADDRESS_ATTESTATION="https://testanchor.example.com/address.pdf"
ORG_PHONE_NUMBER="+14155552671"
ORG_PHONE_NUMBER_ATTESTATION="https://testanchor.example.com/phone.pdf"
ORG_KEYBASE="testanchor"
ORG_TWITTER="testanchor"
ORG_GITHUB="testanchor"
ORG_OFFICIAL_EMAIL="official@testanchor.example.com"
ORG_SUPPORT_EMAIL="support@testanchor.example.com"
ORG_LICENSING_AUTHORITY="FinCEN"
ORG_LICENSE_TYPE="Money Transmitter"
ORG_LICENSE_NUMBER="MT-12345"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    Documentation? docs = stellarToml.documentation;

    expect(docs, isNotNull);
    expect(docs!.orgName, 'Test Anchor');
    expect(docs.orgDBA, 'Test DBA');
    expect(docs.orgUrl, 'https://testanchor.example.com');
    expect(docs.orgLogo, 'https://testanchor.example.com/logo.png');
    expect(docs.orgDescription, 'A test anchor');
    expect(docs.orgPhysicalAddress, '123 Test St');
    expect(docs.orgPhysicalAddressAttestation, isNotNull);
    expect(docs.orgPhoneNumber, '+14155552671');
    expect(docs.orgPhoneNumberAttestation, isNotNull);
    expect(docs.orgKeybase, 'testanchor');
    expect(docs.orgTwitter, 'testanchor');
    expect(docs.orgGithub, 'testanchor');
    expect(docs.orgOfficialEmail, 'official@testanchor.example.com');
    expect(docs.orgSupportEmail, 'support@testanchor.example.com');
    expect(docs.orgLicensingAuthority, 'FinCEN');
    expect(docs.orgLicenseType, 'Money Transmitter');
    expect(docs.orgLicenseNumber, 'MT-12345');
  });

  test('sep-01: Principals (points of contact)', () {
    // Snippet from sep-01.md "Principals (points of contact)"
    String tomlContent = '''
[[PRINCIPALS]]
name="Jane Doe"
email="jane@example.com"
keybase="janedoe"
telegram="janedoe"
twitter="janedoe"
github="janedoe"
id_photo_hash="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
verification_photo_hash="1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    List<PointOfContact>? principals = stellarToml.pointsOfContact;

    expect(principals, isNotNull);
    expect(principals!.length, 1);

    PointOfContact principal = principals.first;
    expect(principal.name, 'Jane Doe');
    expect(principal.email, 'jane@example.com');
    expect(principal.keybase, 'janedoe');
    expect(principal.telegram, 'janedoe');
    expect(principal.twitter, 'janedoe');
    expect(principal.github, 'janedoe');
    expect(principal.idPhotoHash, isNotNull);
    expect(principal.verificationPhotoHash, isNotNull);
  });

  test('sep-01: Currencies (assets)', () {
    // Snippet from sep-01.md "Currencies (assets)"
    String tomlContent = '''
[[CURRENCIES]]
code="USDC"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
status="live"
display_decimals=2
name="USD Coin"
desc="A stablecoin pegged to the US Dollar"
conditions="Redeemable 1:1 for USD"
image="https://example.com/usdc.png"
is_asset_anchored=true
anchor_asset_type="fiat"
anchor_asset="USD"
attestation_of_reserve="https://example.com/audit.pdf"
redemption_instructions="Send to issuer account"
regulated=false

[[CURRENCIES]]
code="MYTOKEN"
contract="CC4DZNN2TPLUOAIRBI3CY7TGRFFCCW6GNVVRRQ3QIIBY6TM6M2RVMBMC"
status="test"
name="My Soroban Token"
desc="A test Soroban token"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    List<Currency>? currencies = stellarToml.currencies;

    expect(currencies, isNotNull);
    expect(currencies!.length, 2);

    // Classic Stellar asset
    Currency usdc = currencies[0];
    expect(usdc.code, 'USDC');
    expect(usdc.issuer, startsWith('G'));
    expect(usdc.contract, isNull);
    expect(usdc.status, 'live');
    expect(usdc.displayDecimals, 2);
    expect(usdc.name, 'USD Coin');
    expect(usdc.desc, isNotNull);
    expect(usdc.conditions, isNotNull);
    expect(usdc.image, isNotNull);
    expect(usdc.isAssetAnchored, true);
    expect(usdc.anchorAssetType, 'fiat');
    expect(usdc.anchorAsset, 'USD');
    expect(usdc.attestationOfReserve, isNotNull);
    expect(usdc.redemptionInstructions, isNotNull);
    expect(usdc.regulated, false);

    // Soroban token contract
    Currency sorobanToken = currencies[1];
    expect(sorobanToken.code, 'MYTOKEN');
    expect(sorobanToken.contract, startsWith('C'));
    expect(sorobanToken.issuer, isNull);
    expect(sorobanToken.status, 'test');
    expect(sorobanToken.name, 'My Soroban Token');
  });

  test('sep-01: Validators', () {
    // Snippet from sep-01.md "Validators"
    String tomlContent = '''
[[VALIDATORS]]
ALIAS="sdf-1"
DISPLAY_NAME="SDF Validator 1"
PUBLIC_KEY="GCGB2S2KBER43ZNEZ5SUBER7AQ2KY2GZIP44REJDN4X3YXYQNLMTV3GV"
HOST="core-live-a.stellar.org:11625"
HISTORY="https://history.stellar.org/prd/core-live/core_live_001"

[[VALIDATORS]]
ALIAS="sdf-2"
DISPLAY_NAME="SDF Validator 2"
PUBLIC_KEY="GCM6QMP3DLRPTAZW2UZPCPX2LF3SBER7FALK47IXMDCL3TP6RVZIUUN7"
HOST="core-live-b.stellar.org:11625"
HISTORY="https://history.stellar.org/prd/core-live/core_live_002"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    List<Validator>? validators = stellarToml.validators;

    expect(validators, isNotNull);
    expect(validators!.length, 2);

    Validator first = validators[0];
    expect(first.alias, 'sdf-1');
    expect(first.displayName, 'SDF Validator 1');
    expect(first.publicKey, startsWith('G'));
    expect(first.host, contains(':'));
    expect(first.history, startsWith('https://'));

    Validator second = validators[1];
    expect(second.alias, 'sdf-2');
    expect(second.displayName, isNotNull);
  });

  test('sep-01: Error handling - TOML parsing error', () {
    // Snippet from sep-01.md "Error handling"
    expect(
      () => StellarToml('this is not valid TOML [[['),
      throwsFormatException,
    );
  });

  test('sep-01: Null checks for missing optional data', () {
    // Snippet from sep-01.md "Error handling" - check for missing data
    String tomlContent = '''
VERSION="2.0.0"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    GeneralInformation info = stellarToml.generalInformation;

    // Endpoints should be null when not provided
    expect(info.webAuthEndpoint, isNull);
    expect(info.transferServerSep24, isNull);
    expect(info.kYCServer, isNull);
    expect(info.federationServer, isNull);
    expect(info.transferServer, isNull);
    expect(info.directPaymentServer, isNull);
    expect(info.anchorQuoteServer, isNull);

    // Documentation should be null when section is absent
    expect(stellarToml.documentation, isNull);

    // accounts is never null, just empty
    expect(info.accounts, isNotNull);
    expect(info.accounts, isEmpty);
  });

  test('sep-01: Collateral addresses', () {
    String tomlContent = '''
[[CURRENCIES]]
code="WBTC"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
is_asset_anchored=true
anchor_asset_type="crypto"
anchor_asset="BTC"
collateral_addresses=["1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"]
collateral_address_messages=["Funds reserved for WBTC"]
collateral_address_signatures=["c2lnbmF0dXJl"]
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    List<Currency>? currencies = stellarToml.currencies;

    expect(currencies, isNotNull);
    Currency currency = currencies!.first;
    expect(currency.collateralAddresses, isNotNull);
    expect(currency.collateralAddresses!.length, 1);
    expect(currency.collateralAddressMessages, isNotNull);
    expect(currency.collateralAddressSignatures, isNotNull);
  });

  test('sep-01: SEP-08 Regulated asset fields', () {
    String tomlContent = '''
[[CURRENCIES]]
code="REGULATED"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
regulated=true
approval_server="https://example.com/approval"
approval_criteria="KYC required"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    Currency currency = stellarToml.currencies!.first;

    expect(currency.regulated, true);
    expect(currency.approvalServer, 'https://example.com/approval');
    expect(currency.approvalCriteria, 'KYC required');
  });

  test('sep-01: Linked currency with toml field', () {
    // Snippet from sep-01.md "Linked currencies"
    String tomlContent = '''
[[CURRENCIES]]
toml="https://example.com/.well-known/USDC.toml"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    List<Currency>? currencies = stellarToml.currencies;

    expect(currencies, isNotNull);
    Currency currency = currencies!.first;
    expect(currency.toml, 'https://example.com/.well-known/USDC.toml');
    // When toml is set, other fields should be null
    expect(currency.code, isNull);
    expect(currency.issuer, isNull);
  });

  test('sep-01: Safeguard corrects common TOML errors', () {
    // Test the auto-correction described in the doc
    // [[DOCUMENTATION]] (wrong) should be corrected to [DOCUMENTATION]
    String tomlContent = '''
VERSION="2.0.0"

[[DOCUMENTATION]]
ORG_NAME="Test Org"
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    expect(stellarToml.documentation, isNotNull);
    expect(stellarToml.documentation!.orgName, 'Test Org');
  });

  test('sep-01: Supply model fields', () {
    String tomlContent = '''
[[CURRENCIES]]
code="FIXED"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
fixed_number=1000000

[[CURRENCIES]]
code="CAPPED"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
max_number=5000000

[[CURRENCIES]]
code="UNLIMITED"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
is_unlimited=true
''';

    StellarToml stellarToml = StellarToml(tomlContent);
    List<Currency>? currencies = stellarToml.currencies;

    expect(currencies, isNotNull);
    expect(currencies!.length, 3);

    expect(currencies[0].fixedNumber, 1000000);
    expect(currencies[1].maxNumber, 5000000);
    expect(currencies[2].isUnlimited, true);
  });
}
