import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('StellarToml', () {
    group('parsing', () {
      test('parses minimal TOML with general information', () {
        final toml = '''
VERSION="2.7.0"
NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
SIGNING_KEY="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.generalInformation.version, equals('2.7.0'));
        expect(stellarToml.generalInformation.networkPassphrase,
            equals('Public Global Stellar Network ; September 2015'));
        expect(stellarToml.generalInformation.signingKey,
            equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
      });

      test('parses all general information fields', () {
        final toml = '''
VERSION="2.7.0"
NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
FEDERATION_SERVER="https://example.com/federation"
AUTH_SERVER="https://example.com/auth"
TRANSFER_SERVER="https://example.com/transfer"
TRANSFER_SERVER_SEP0024="https://example.com/sep24"
KYC_SERVER="https://example.com/kyc"
WEB_AUTH_ENDPOINT="https://example.com/webauth"
SIGNING_KEY="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
HORIZON_URL="https://horizon.example.com"
URI_REQUEST_SIGNING_KEY="GCKJZ2YVECFGLUDJ5T7RDWAYQSP35ZFVCODPRLL4PYBLQ3FYZBZ2D7IZ"
DIRECT_PAYMENT_SERVER="https://example.com/sep31"
ANCHOR_QUOTE_SERVER="https://example.com/sep38"
WEB_AUTH_FOR_CONTRACTS_ENDPOINT="https://example.com/contracts/auth"
WEB_AUTH_CONTRACT_ID="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
''';

        final stellarToml = StellarToml(toml);
        final info = stellarToml.generalInformation;

        expect(info.version, equals('2.7.0'));
        expect(info.networkPassphrase,
            equals('Public Global Stellar Network ; September 2015'));
        expect(info.federationServer, equals('https://example.com/federation'));
        expect(info.authServer, equals('https://example.com/auth'));
        expect(info.transferServer, equals('https://example.com/transfer'));
        expect(info.transferServerSep24, equals('https://example.com/sep24'));
        expect(info.kYCServer, equals('https://example.com/kyc'));
        expect(info.webAuthEndpoint, equals('https://example.com/webauth'));
        expect(info.signingKey,
            equals('GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP'));
        expect(info.horizonUrl, equals('https://horizon.example.com'));
        expect(info.uriRequestSigningKey,
            equals('GCKJZ2YVECFGLUDJ5T7RDWAYQSP35ZFVCODPRLL4PYBLQ3FYZBZ2D7IZ'));
        expect(info.directPaymentServer, equals('https://example.com/sep31'));
        expect(info.anchorQuoteServer, equals('https://example.com/sep38'));
        expect(info.webAuthForContractsEndpoint,
            equals('https://example.com/contracts/auth'));
        expect(info.webAuthContractId,
            equals('CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'));
      });

      test('parses ACCOUNTS array', () {
        final toml = '''
VERSION="2.7.0"
ACCOUNTS=[
  "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3",
  "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7",
  "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
]
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.generalInformation.accounts.length, equals(3));
        expect(stellarToml.generalInformation.accounts[0],
            equals('GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3'));
        expect(stellarToml.generalInformation.accounts[1],
            equals('GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7'));
        expect(stellarToml.generalInformation.accounts[2],
            equals('GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U'));
      });
    });

    group('documentation', () {
      test('parses DOCUMENTATION section', () {
        final toml = '''
VERSION="2.7.0"

[DOCUMENTATION]
ORG_NAME="Example Organization"
ORG_DBA="Example DBA"
ORG_URL="https://example.com"
ORG_LOGO="https://example.com/logo.png"
ORG_DESCRIPTION="A test organization"
ORG_PHYSICAL_ADDRESS="123 Main St, City, State 12345"
ORG_PHYSICAL_ADDRESS_ATTESTATION="https://example.com/address_proof.pdf"
ORG_PHONE_NUMBER="+1-555-123-4567"
ORG_PHONE_NUMBER_ATTESTATION="https://example.com/phone_proof.pdf"
ORG_KEYBASE="example_org"
ORG_TWITTER="example_org"
ORG_GITHUB="example_org"
ORG_OFFICIAL_EMAIL="official@example.com"
ORG_SUPPORT_EMAIL="support@example.com"
ORG_LICENSING_AUTHORITY="State Financial Authority"
ORG_LICENSE_TYPE="Money Transmitter"
ORG_LICENSE_NUMBER="MT-123456"
''';

        final stellarToml = StellarToml(toml);
        final doc = stellarToml.documentation;

        expect(doc, isNotNull);
        expect(doc!.orgName, equals('Example Organization'));
        expect(doc.orgDBA, equals('Example DBA'));
        expect(doc.orgUrl, equals('https://example.com'));
        expect(doc.orgLogo, equals('https://example.com/logo.png'));
        expect(doc.orgDescription, equals('A test organization'));
        expect(doc.orgPhysicalAddress, equals('123 Main St, City, State 12345'));
        expect(doc.orgPhysicalAddressAttestation,
            equals('https://example.com/address_proof.pdf'));
        expect(doc.orgPhoneNumber, equals('+1-555-123-4567'));
        expect(doc.orgPhoneNumberAttestation,
            equals('https://example.com/phone_proof.pdf'));
        expect(doc.orgKeybase, equals('example_org'));
        expect(doc.orgTwitter, equals('example_org'));
        expect(doc.orgGithub, equals('example_org'));
        expect(doc.orgOfficialEmail, equals('official@example.com'));
        expect(doc.orgSupportEmail, equals('support@example.com'));
        expect(doc.orgLicensingAuthority, equals('State Financial Authority'));
        expect(doc.orgLicenseType, equals('Money Transmitter'));
        expect(doc.orgLicenseNumber, equals('MT-123456'));
      });

      test('handles missing DOCUMENTATION section', () {
        final toml = '''
VERSION="2.7.0"
SIGNING_KEY="GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.documentation, isNull);
      });
    });

    group('principals', () {
      test('parses PRINCIPALS array', () {
        final toml = '''
VERSION="2.7.0"

[[PRINCIPALS]]
name="Jane Doe"
email="jane@example.com"
keybase="jane_doe"
twitter="jane_doe"
telegram="jane_doe_tg"
github="jane_doe_gh"
id_photo_hash="be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09"
verification_photo_hash="016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7"

[[PRINCIPALS]]
name="John Smith"
email="john@example.com"
keybase="john_smith"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.pointsOfContact, isNotNull);
        expect(stellarToml.pointsOfContact!.length, equals(2));

        final jane = stellarToml.pointsOfContact![0];
        expect(jane.name, equals('Jane Doe'));
        expect(jane.email, equals('jane@example.com'));
        expect(jane.keybase, equals('jane_doe'));
        expect(jane.twitter, equals('jane_doe'));
        expect(jane.telegram, equals('jane_doe_tg'));
        expect(jane.github, equals('jane_doe_gh'));
        expect(jane.idPhotoHash,
            equals('be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09'));
        expect(jane.verificationPhotoHash,
            equals('016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7'));

        final john = stellarToml.pointsOfContact![1];
        expect(john.name, equals('John Smith'));
        expect(john.email, equals('john@example.com'));
        expect(john.keybase, equals('john_smith'));
      });

      test('handles missing PRINCIPALS section', () {
        final toml = '''
VERSION="2.7.0"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.pointsOfContact, isNull);
      });
    });

    group('currencies', () {
      test('parses basic currency', () {
        final toml = '''
VERSION="2.7.0"

[[CURRENCIES]]
code="USD"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
display_decimals=2
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.currencies, isNotNull);
        expect(stellarToml.currencies!.length, equals(1));

        final currency = stellarToml.currencies![0];
        expect(currency.code, equals('USD'));
        expect(currency.issuer,
            equals('GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM'));
        expect(currency.displayDecimals, equals(2));
      });

      test('parses currency with all fields', () {
        final toml = '''
VERSION="2.7.0"

[[CURRENCIES]]
code="BTC"
issuer="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
status="live"
display_decimals=7
name="Bitcoin"
desc="Anchored Bitcoin on Stellar"
conditions="Redeemable 1:1 for BTC"
image="https://example.com/btc.png"
fixed_number=21000000
is_asset_anchored=true
anchor_asset_type="crypto"
anchor_asset="BTC"
attestation_of_reserve="https://example.com/audit.pdf"
redemption_instructions="Use SEP-6 with our anchor"
collateral_addresses=["1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"]
collateral_address_messages=["Reserved for Stellar BTC"]
collateral_address_signatures=["304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"]
regulated=true
approval_server="https://example.com/approval"
approval_criteria="KYC required"
''';

        final stellarToml = StellarToml(toml);
        final currency = stellarToml.currencies![0];

        expect(currency.code, equals('BTC'));
        expect(currency.issuer,
            equals('GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U'));
        expect(currency.status, equals('live'));
        expect(currency.displayDecimals, equals(7));
        expect(currency.name, equals('Bitcoin'));
        expect(currency.desc, equals('Anchored Bitcoin on Stellar'));
        expect(currency.conditions, equals('Redeemable 1:1 for BTC'));
        expect(currency.image, equals('https://example.com/btc.png'));
        expect(currency.fixedNumber, equals(21000000));
        expect(currency.isAssetAnchored, isTrue);
        expect(currency.anchorAssetType, equals('crypto'));
        expect(currency.anchorAsset, equals('BTC'));
        expect(currency.attestationOfReserve,
            equals('https://example.com/audit.pdf'));
        expect(currency.redemptionInstructions,
            equals('Use SEP-6 with our anchor'));
        expect(currency.collateralAddresses, isNotNull);
        expect(currency.collateralAddresses!.length, equals(1));
        expect(currency.collateralAddresses![0],
            equals('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'));
        expect(currency.collateralAddressMessages, isNotNull);
        expect(currency.collateralAddressMessages![0],
            equals('Reserved for Stellar BTC'));
        expect(currency.collateralAddressSignatures, isNotNull);
        expect(currency.collateralAddressSignatures![0],
            equals('304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10'));
        expect(currency.regulated, isTrue);
        expect(currency.approvalServer, equals('https://example.com/approval'));
        expect(currency.approvalCriteria, equals('KYC required'));
      });

      test('parses currency with contract', () {
        final toml = '''
VERSION="2.7.0"

[[CURRENCIES]]
code="USDC"
contract="CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
display_decimals=7
name="USD Coin"
desc="USDC on Stellar Soroban"
''';

        final stellarToml = StellarToml(toml);
        final currency = stellarToml.currencies![0];

        expect(currency.code, equals('USDC'));
        expect(currency.contract,
            equals('CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC'));
        expect(currency.issuer, isNull);
      });

      test('parses currency with code template', () {
        final toml = '''
VERSION="2.7.0"

[[CURRENCIES]]
code_template="CORN????????"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
desc="Corn futures contracts"
''';

        final stellarToml = StellarToml(toml);
        final currency = stellarToml.currencies![0];

        expect(currency.codeTemplate, equals('CORN????????'));
        expect(currency.desc, equals('Corn futures contracts'));
      });

      test('parses multiple currencies', () {
        final toml = '''
VERSION="2.7.0"

[[CURRENCIES]]
code="USD"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"

[[CURRENCIES]]
code="EUR"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"

[[CURRENCIES]]
code="BTC"
issuer="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.currencies, isNotNull);
        expect(stellarToml.currencies!.length, equals(3));
        expect(stellarToml.currencies![0].code, equals('USD'));
        expect(stellarToml.currencies![1].code, equals('EUR'));
        expect(stellarToml.currencies![2].code, equals('BTC'));
      });

      test('handles missing CURRENCIES section', () {
        final toml = '''
VERSION="2.7.0"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.currencies, isNull);
      });
    });

    group('validators', () {
      test('parses VALIDATORS array', () {
        final toml = '''
VERSION="2.7.0"

[[VALIDATORS]]
ALIAS="domain-au"
DISPLAY_NAME="Domain Australia"
HOST="core-au.domain.com:11625"
PUBLIC_KEY="GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"
HISTORY="http://history.domain.com/prd/core-live/core_live_001/"

[[VALIDATORS]]
ALIAS="domain-sg"
DISPLAY_NAME="Domain Singapore"
HOST="core-sg.domain.com:11625"
PUBLIC_KEY="GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"
HISTORY="http://history.domain.com/prd/core-live/core_live_002/"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.validators, isNotNull);
        expect(stellarToml.validators!.length, equals(2));

        final validator1 = stellarToml.validators![0];
        expect(validator1.alias, equals('domain-au'));
        expect(validator1.displayName, equals('Domain Australia'));
        expect(validator1.host, equals('core-au.domain.com:11625'));
        expect(validator1.publicKey,
            equals('GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3'));
        expect(validator1.history,
            equals('http://history.domain.com/prd/core-live/core_live_001/'));

        final validator2 = stellarToml.validators![1];
        expect(validator2.alias, equals('domain-sg'));
        expect(validator2.displayName, equals('Domain Singapore'));
      });

      test('handles missing VALIDATORS section', () {
        final toml = '''
VERSION="2.7.0"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.validators, isNull);
      });
    });

    group('safeguards', () {
      test('corrects [[DOCUMENTATION]] to [DOCUMENTATION]', () {
        final toml = '''
VERSION="2.7.0"

[[DOCUMENTATION]]
ORG_NAME="Example"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.documentation, isNotNull);
        expect(stellarToml.documentation!.orgName, equals('Example'));
      });

      test('handles malformed but correctable TOML structures', () {
        // Test that safeguardTomlContent method exists and processes content
        final toml = StellarToml('VERSION="2.7.0"');

        expect(toml.generalInformation.version, equals('2.7.0'));
      });

      test('parses TOML with correct array syntax', () {
        final toml = '''
VERSION="2.7.0"

[[CURRENCIES]]
code="USD"
issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.currencies, isNotNull);
        expect(stellarToml.currencies!.length, equals(1));
      });

      test('parses TOML with correct single table syntax', () {
        final toml = '''
VERSION="2.7.0"

[DOCUMENTATION]
ORG_NAME="Example"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.documentation, isNotNull);
        expect(stellarToml.documentation!.orgName, equals('Example'));
      });
    });

    group('edge cases', () {
      test('handles empty TOML', () {
        final toml = '';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.generalInformation, isNotNull);
        expect(stellarToml.documentation, isNull);
        expect(stellarToml.pointsOfContact, isNull);
        expect(stellarToml.currencies, isNull);
        expect(stellarToml.validators, isNull);
      });

      test('handles TOML with only comments', () {
        final toml = '''
# This is a comment
# Another comment
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.generalInformation, isNotNull);
      });

      test('handles empty arrays', () {
        final toml = '''
VERSION="2.7.0"
ACCOUNTS=[]
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.generalInformation.accounts.length, equals(0));
      });

      test('handles partial documentation', () {
        final toml = '''
VERSION="2.7.0"

[DOCUMENTATION]
ORG_NAME="Example"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.documentation, isNotNull);
        expect(stellarToml.documentation!.orgName, equals('Example'));
        expect(stellarToml.documentation!.orgUrl, isNull);
        expect(stellarToml.documentation!.orgOfficialEmail, isNull);
      });

      test('handles currency with toml field only', () {
        final toml = '''
VERSION="2.7.0"

[[CURRENCIES]]
toml="https://example.com/.well-known/USD.toml"
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.currencies, isNotNull);
        expect(stellarToml.currencies!.length, equals(1));
        expect(stellarToml.currencies![0].toml,
            equals('https://example.com/.well-known/USD.toml'));
        expect(stellarToml.currencies![0].code, isNull);
        expect(stellarToml.currencies![0].issuer, isNull);
      });

      test('handles whitespace in arrays', () {
        final toml = '''
VERSION="2.7.0"
ACCOUNTS=[
  "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3",

  "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"

]
''';

        final stellarToml = StellarToml(toml);

        expect(stellarToml.generalInformation.accounts.length, equals(2));
      });
    });
  });
}
