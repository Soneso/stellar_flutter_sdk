@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('from toml string', () async {
    String toml = '''
      # Sample stellar.toml
      VERSION="2.0.0"
      
      NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
      FEDERATION_SERVER="https://stellarid.io/federation/"
      AUTH_SERVER="https://api.domain.com/auth"
      TRANSFER_SERVER="https://api.domain.com"
      SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"
      HORIZON_URL="https://horizon.domain.com"
      ACCOUNTS=[
      "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3",
      "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7",
      "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
      ]
      DIRECT_PAYMENT_SERVER="https://test.direct-payment.com"
      ANCHOR_QUOTE_SERVER="https://test.anchor-quote.com"
      
      [DOCUMENTATION]
      ORG_NAME="Organization Name"
      ORG_DBA="Organization DBA"
      ORG_URL="https://www.domain.com"
      ORG_LOGO="https://www.domain.com/awesomelogo.png"
      ORG_DESCRIPTION="Description of issuer"
      ORG_PHYSICAL_ADDRESS="123 Sesame Street, New York, NY 12345, United States"
      ORG_PHYSICAL_ADDRESS_ATTESTATION="https://www.domain.com/address_attestation.jpg"
      ORG_PHONE_NUMBER="1 (123)-456-7890"
      ORG_PHONE_NUMBER_ATTESTATION="https://www.domain.com/phone_attestation.jpg"
      ORG_KEYBASE="accountname"
      ORG_TWITTER="orgtweet"
      ORG_GITHUB="orgcode"
      ORG_OFFICIAL_EMAIL="info@domain.com"
      ORG_SUPPORT_EMAIL="support@domain.com"
      
      [[PRINCIPALS]]
      name="Jane Jedidiah Johnson"
      email="jane@domain.com"
      keybase="crypto_jane"
      twitter="crypto_jane"
      github="crypto_jane"
      id_photo_hash="be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09"
      verification_photo_hash="016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7"
      
      [[CURRENCIES]]
      code="USD"
      issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
      display_decimals=2
      
      [[CURRENCIES]]
      code="BTC"
      issuer="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
      display_decimals=7
      anchor_asset_type="crypto"
      anchor_asset="BTC"
      redemption_instructions="Use SEP6 with our federation server"
      collateral_addresses=["2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"]
      collateral_address_signatures=["304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"]
      
      # asset with meta info
      [[CURRENCIES]]
      code="GOAT"
      issuer="GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP"
      display_decimals=2
      name="goat share"
      desc="1 GOAT token entitles you to a share of revenue from Elkins Goat Farm."
      conditions="There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th"
      image="https://static.thenounproject.com/png/2292360-200.png"
      fixed_number=10000
      
      [[CURRENCIES]]
      code="CCRT"
      issuer="GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP"
      contract="CC4DZNN2TPLUOAIRBI3CY7TGRFFCCW6GNVVRRQ3QIIBY6TM6M2RVMBMC"
      display_decimals=2
      name="ccrt"
      desc="contract test"
      
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
      
      [[VALIDATORS]]
      ALIAS="domain-us"
      DISPLAY_NAME="Domain United States"
      HOST="core-us.domain.com:11625"
      PUBLIC_KEY="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
      HISTORY="http://history.domain.com/prd/core-live/core_live_003/"
      
      # optional extra information for humans
      # Useful place for anchors to detail various policies and required info
      
      ###################################
      # Required compliance fields:
      #      name=<recipient name>
      #      addr=<recipient address>
      # Federation Format:
      #        <phone number>*anchor.com
      #        Forwarding supported by sending to: forward*anchor.com
      #           forward_type=bank_account
      #           swift=<swift code of receiving bank>
      #           acct=<recipient account number at receiving bank>
      # Minimum Amount Forward: \$2 USD
      # Maximum Amount Forward: \$10000 USD
     ''';

    StellarToml stellarToml = StellarToml(toml);
    GeneralInformation generalInformation = stellarToml.generalInformation;
    assert(generalInformation.version == "2.0.0");
    assert(generalInformation.networkPassphrase ==
        "Public Global Stellar Network ; September 2015");
    assert(generalInformation.federationServer ==
        "https://stellarid.io/federation/");
    assert(generalInformation.authServer == "https://api.domain.com/auth");
    assert(generalInformation.transferServer == "https://api.domain.com");
    assert(generalInformation.transferServerSep24 == null);
    assert(generalInformation.kYCServer == null);
    assert(generalInformation.webAuthEndpoint == null);
    assert(generalInformation.signingKey ==
        "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3");
    assert(generalInformation.horizonUrl == "https://horizon.domain.com");
    assert(generalInformation.accounts
        .contains("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"));
    assert(generalInformation.accounts
        .contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"));
    assert(generalInformation.accounts
        .contains("GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"));
    assert(generalInformation.uriRequestSigningKey == null);
    assert(generalInformation.directPaymentServer ==
        "https://test.direct-payment.com");
    assert(generalInformation.anchorQuoteServer ==
        "https://test.anchor-quote.com");

    Documentation documentation = stellarToml.documentation!;
    assert(documentation.orgName == "Organization Name");
    assert(documentation.orgDBA == "Organization DBA");
    assert(documentation.orgUrl == "https://www.domain.com");
    assert(documentation.orgLogo == "https://www.domain.com/awesomelogo.png");
    assert(documentation.orgDescription == "Description of issuer");
    assert(documentation.orgPhysicalAddress ==
        "123 Sesame Street, New York, NY 12345, United States");
    assert(documentation.orgPhysicalAddressAttestation ==
        "https://www.domain.com/address_attestation.jpg");
    assert(documentation.orgPhoneNumber == "1 (123)-456-7890");
    assert(documentation.orgPhoneNumberAttestation ==
        "https://www.domain.com/phone_attestation.jpg");
    assert(documentation.orgKeybase == "accountname");
    assert(documentation.orgTwitter == "orgtweet");
    assert(documentation.orgGithub == "orgcode");
    assert(documentation.orgOfficialEmail == "info@domain.com");
    assert(documentation.orgSupportEmail == "support@domain.com");
    assert(documentation.orgLicensingAuthority == null);
    assert(documentation.orgLicenseType == null);
    assert(documentation.orgLicenseNumber == null);

    PointOfContact pointOfContact = stellarToml.pointsOfContact!.first;
    assert(pointOfContact.name == "Jane Jedidiah Johnson");
    assert(pointOfContact.email == "jane@domain.com");
    assert(pointOfContact.keybase == "crypto_jane");
    assert(pointOfContact.telegram == null);
    assert(pointOfContact.twitter == "crypto_jane");
    assert(pointOfContact.github == "crypto_jane");
    assert(pointOfContact.idPhotoHash ==
        "be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09");
    assert(pointOfContact.verificationPhotoHash ==
        "016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7");

    List<Currency?>? currencies = stellarToml.currencies!;
    assert(currencies[0]!.code == "USD");
    assert(currencies[0]!.issuer ==
        "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM");
    assert(currencies[0]!.displayDecimals == 2);
    assert(currencies[1]!.code == "BTC");
    assert(currencies[1]!.issuer ==
        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
    assert(currencies[1]!.displayDecimals == 7);
    assert(currencies[1]!.anchorAssetType == "crypto");
    assert(currencies[1]!.anchorAsset == "BTC");
    assert(currencies[1]!.redemptionInstructions ==
        "Use SEP6 with our federation server");
    assert(currencies[1]!
        .collateralAddresses!
        .contains("2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"));
    assert(currencies[1]!.collateralAddressSignatures!.contains(
        "304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"));
    assert(currencies[2]!.code == "GOAT");
    assert(currencies[2]!.issuer ==
        "GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP");
    assert(currencies[2]!.displayDecimals == 2);
    assert(currencies[2]!.name == "goat share");
    assert(currencies[2]!.desc ==
        "1 GOAT token entitles you to a share of revenue from Elkins Goat Farm.");
    assert(currencies[2]!.conditions ==
        "There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th");
    assert(currencies[2]!.image ==
        "https://static.thenounproject.com/png/2292360-200.png");
    assert(currencies[2]!.fixedNumber == 10000);
    assert(currencies[3]!.contract == "CC4DZNN2TPLUOAIRBI3CY7TGRFFCCW6GNVVRRQ3QIIBY6TM6M2RVMBMC");

    List<Validator?>? validators = stellarToml.validators!;
    assert(validators[0]!.alias == "domain-au");
    assert(validators[0]!.displayName == "Domain Australia");
    assert(validators[0]!.host == "core-au.domain.com:11625");
    assert(validators[0]!.publicKey ==
        "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3");
    assert(validators[0]!.history ==
        "http://history.domain.com/prd/core-live/core_live_001/");
    assert(validators[1]!.alias == "domain-sg");
    assert(validators[1]!.displayName == "Domain Singapore");
    assert(validators[1]!.host == "core-sg.domain.com:11625");
    assert(validators[1]!.publicKey ==
        "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7");
    assert(validators[1]!.history ==
        "http://history.domain.com/prd/core-live/core_live_002/");
    assert(validators[2]!.alias == "domain-us");
    assert(validators[2]!.displayName == "Domain United States");
    assert(validators[2]!.host == "core-us.domain.com:11625");
    assert(validators[2]!.publicKey ==
        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
    assert(validators[2]!.history ==
        "http://history.domain.com/prd/core-live/core_live_003/");
  });

  test('from toml string with incorrect headers', () async {
    String toml = '''
      # Sample stellar.toml
      VERSION="2.0.0"
      
      NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
      FEDERATION_SERVER="https://stellarid.io/federation/"
      AUTH_SERVER="https://api.domain.com/auth"
      TRANSFER_SERVER="https://api.domain.com"
      SIGNING_KEY="GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3"
      HORIZON_URL="https://horizon.domain.com"
      ACCOUNTS=[
      "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3",
      "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7",
      "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
      ]
      DIRECT_PAYMENT_SERVER="https://test.direct-payment.com"
      ANCHOR_QUOTE_SERVER="https://test.anchor-quote.com"
      
      [[DOCUMENTATION]]
      ORG_NAME="Organization Name"
      ORG_DBA="Organization DBA"
      ORG_URL="https://www.domain.com"
      ORG_LOGO="https://www.domain.com/awesomelogo.png"
      ORG_DESCRIPTION="Description of issuer"
      ORG_PHYSICAL_ADDRESS="123 Sesame Street, New York, NY 12345, United States"
      ORG_PHYSICAL_ADDRESS_ATTESTATION="https://www.domain.com/address_attestation.jpg"
      ORG_PHONE_NUMBER="1 (123)-456-7890"
      ORG_PHONE_NUMBER_ATTESTATION="https://www.domain.com/phone_attestation.jpg"
      ORG_KEYBASE="accountname"
      ORG_TWITTER="orgtweet"
      ORG_GITHUB="orgcode"
      ORG_OFFICIAL_EMAIL="info@domain.com"
      ORG_SUPPORT_EMAIL="support@domain.com"
      
      [PRINCIPALS]
      name="Jane Jedidiah Johnson"
      email="jane@domain.com"
      keybase="crypto_jane"
      twitter="crypto_jane"
      github="crypto_jane"
      id_photo_hash="be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09"
      verification_photo_hash="016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7"
      
      [CURRENCIES]
      code="USD"
      issuer="GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
      display_decimals=2
      
      [CURRENCIES]
      code="BTC"
      issuer="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
      display_decimals=7
      anchor_asset_type="crypto"
      anchor_asset="BTC"
      redemption_instructions="Use SEP6 with our federation server"
      collateral_addresses=["2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"]
      collateral_address_signatures=["304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"]
      
      # asset with meta info
      [CURRENCIES]
      code="GOAT"
      issuer="GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP"
      display_decimals=2
      name="goat share"
      desc="1 GOAT token entitles you to a share of revenue from Elkins Goat Farm."
      conditions="There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th"
      image="https://static.thenounproject.com/png/2292360-200.png"
      fixed_number=10000
      
      [VALIDATORS]
      ALIAS="domain-au"
      DISPLAY_NAME="Domain Australia"
      HOST="core-au.domain.com:11625"
      PUBLIC_KEY="GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"
      HISTORY="http://history.domain.com/prd/core-live/core_live_001/"
      
      [VALIDATORS]
      ALIAS="domain-sg"
      DISPLAY_NAME="Domain Singapore"
      HOST="core-sg.domain.com:11625"
      PUBLIC_KEY="GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"
      HISTORY="http://history.domain.com/prd/core-live/core_live_002/"
      
      [VALIDATORS]
      ALIAS="domain-us"
      DISPLAY_NAME="Domain United States"
      HOST="core-us.domain.com:11625"
      PUBLIC_KEY="GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"
      HISTORY="http://history.domain.com/prd/core-live/core_live_003/"
      
      # optional extra information for humans
      # Useful place for anchors to detail various policies and required info
      
      ###################################
      # Required compliance fields:
      #      name=<recipient name>
      #      addr=<recipient address>
      # Federation Format:
      #        <phone number>*anchor.com
      #        Forwarding supported by sending to: forward*anchor.com
      #           forward_type=bank_account
      #           swift=<swift code of receiving bank>
      #           acct=<recipient account number at receiving bank>
      # Minimum Amount Forward: \$2 USD
      # Maximum Amount Forward: \$10000 USD
     ''';

    StellarToml stellarToml = StellarToml(toml);
    GeneralInformation generalInformation = stellarToml.generalInformation;
    assert(generalInformation.version == "2.0.0");
    assert(generalInformation.networkPassphrase ==
        "Public Global Stellar Network ; September 2015");
    assert(generalInformation.federationServer ==
        "https://stellarid.io/federation/");
    assert(generalInformation.authServer == "https://api.domain.com/auth");
    assert(generalInformation.transferServer == "https://api.domain.com");
    assert(generalInformation.transferServerSep24 == null);
    assert(generalInformation.kYCServer == null);
    assert(generalInformation.webAuthEndpoint == null);
    assert(generalInformation.signingKey ==
        "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3");
    assert(generalInformation.horizonUrl == "https://horizon.domain.com");
    assert(generalInformation.accounts
        .contains("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"));
    assert(generalInformation.accounts
        .contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"));
    assert(generalInformation.accounts
        .contains("GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"));
    assert(generalInformation.uriRequestSigningKey == null);
    assert(generalInformation.directPaymentServer ==
        "https://test.direct-payment.com");
    assert(generalInformation.anchorQuoteServer ==
        "https://test.anchor-quote.com");

    Documentation documentation = stellarToml.documentation!;
    assert(documentation.orgName == "Organization Name");
    assert(documentation.orgDBA == "Organization DBA");
    assert(documentation.orgUrl == "https://www.domain.com");
    assert(documentation.orgLogo == "https://www.domain.com/awesomelogo.png");
    assert(documentation.orgDescription == "Description of issuer");
    assert(documentation.orgPhysicalAddress ==
        "123 Sesame Street, New York, NY 12345, United States");
    assert(documentation.orgPhysicalAddressAttestation ==
        "https://www.domain.com/address_attestation.jpg");
    assert(documentation.orgPhoneNumber == "1 (123)-456-7890");
    assert(documentation.orgPhoneNumberAttestation ==
        "https://www.domain.com/phone_attestation.jpg");
    assert(documentation.orgKeybase == "accountname");
    assert(documentation.orgTwitter == "orgtweet");
    assert(documentation.orgGithub == "orgcode");
    assert(documentation.orgOfficialEmail == "info@domain.com");
    assert(documentation.orgSupportEmail == "support@domain.com");
    assert(documentation.orgLicensingAuthority == null);
    assert(documentation.orgLicenseType == null);
    assert(documentation.orgLicenseNumber == null);

    PointOfContact pointOfContact = stellarToml.pointsOfContact!.first;
    assert(pointOfContact.name == "Jane Jedidiah Johnson");
    assert(pointOfContact.email == "jane@domain.com");
    assert(pointOfContact.keybase == "crypto_jane");
    assert(pointOfContact.telegram == null);
    assert(pointOfContact.twitter == "crypto_jane");
    assert(pointOfContact.github == "crypto_jane");
    assert(pointOfContact.idPhotoHash ==
        "be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09");
    assert(pointOfContact.verificationPhotoHash ==
        "016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7");

    List<Currency?>? currencies = stellarToml.currencies!;
    assert(currencies[0]!.code == "USD");
    assert(currencies[0]!.issuer ==
        "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM");
    assert(currencies[0]!.displayDecimals == 2);
    assert(currencies[1]!.code == "BTC");
    assert(currencies[1]!.issuer ==
        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
    assert(currencies[1]!.displayDecimals == 7);
    assert(currencies[1]!.anchorAssetType == "crypto");
    assert(currencies[1]!.anchorAsset == "BTC");
    assert(currencies[1]!.redemptionInstructions ==
        "Use SEP6 with our federation server");
    assert(currencies[1]!
        .collateralAddresses!
        .contains("2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"));
    assert(currencies[1]!.collateralAddressSignatures!.contains(
        "304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"));
    assert(currencies[2]!.code == "GOAT");
    assert(currencies[2]!.issuer ==
        "GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP");
    assert(currencies[2]!.displayDecimals == 2);
    assert(currencies[2]!.name == "goat share");
    assert(currencies[2]!.desc ==
        "1 GOAT token entitles you to a share of revenue from Elkins Goat Farm.");
    assert(currencies[2]!.conditions ==
        "There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th");
    assert(currencies[2]!.image ==
        "https://static.thenounproject.com/png/2292360-200.png");
    assert(currencies[2]!.fixedNumber == 10000);

    List<Validator?>? validators = stellarToml.validators!;
    assert(validators[0]!.alias == "domain-au");
    assert(validators[0]!.displayName == "Domain Australia");
    assert(validators[0]!.host == "core-au.domain.com:11625");
    assert(validators[0]!.publicKey ==
        "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3");
    assert(validators[0]!.history ==
        "http://history.domain.com/prd/core-live/core_live_001/");
    assert(validators[1]!.alias == "domain-sg");
    assert(validators[1]!.displayName == "Domain Singapore");
    assert(validators[1]!.host == "core-sg.domain.com:11625");
    assert(validators[1]!.publicKey ==
        "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7");
    assert(validators[1]!.history ==
        "http://history.domain.com/prd/core-live/core_live_002/");
    assert(validators[2]!.alias == "domain-us");
    assert(validators[2]!.displayName == "Domain United States");
    assert(validators[2]!.host == "core-us.domain.com:11625");
    assert(validators[2]!.publicKey ==
        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
    assert(validators[2]!.history ==
        "http://history.domain.com/prd/core-live/core_live_003/");
  });

  test('from toml domain', () async {
    StellarToml stellarToml = await StellarToml.fromDomain("soneso.com");
    GeneralInformation generalInformation = stellarToml.generalInformation;
    assert(generalInformation.version == "2.0.0");
    assert(generalInformation.networkPassphrase ==
        "Public Global Stellar Network ; September 2015");
    assert(generalInformation.federationServer ==
        "https://stellarid.io/federation/");
    assert(generalInformation.authServer == "https://api.domain.com/auth");
    assert(generalInformation.transferServer == "https://api.domain.com");
    assert(generalInformation.transferServerSep24 == null);
    assert(generalInformation.kYCServer == null);
    assert(generalInformation.webAuthEndpoint == null);
    assert(generalInformation.signingKey ==
        "GBBHQ7H4V6RRORKYLHTCAWP6MOHNORRFJSDPXDFYDGJB2LPZUFPXUEW3");
    assert(generalInformation.horizonUrl == "https://horizon.domain.com");
    assert(generalInformation.accounts
        .contains("GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3"));
    assert(generalInformation.accounts
        .contains("GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7"));
    assert(generalInformation.accounts
        .contains("GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U"));
    assert(generalInformation.uriRequestSigningKey == null);

    Documentation documentation = stellarToml.documentation!;
    assert(documentation.orgName == "Organization Name");
    assert(documentation.orgDBA == "Organization DBA");
    assert(documentation.orgUrl == "https://www.domain.com");
    assert(documentation.orgLogo == "https://www.domain.com/awesomelogo.png");
    assert(documentation.orgDescription == "Description of issuer");
    assert(documentation.orgPhysicalAddress ==
        "123 Sesame Street, New York, NY 12345, United States");
    assert(documentation.orgPhysicalAddressAttestation ==
        "https://www.domain.com/address_attestation.jpg");
    assert(documentation.orgPhoneNumber == "1 (123)-456-7890");
    assert(documentation.orgPhoneNumberAttestation ==
        "https://www.domain.com/phone_attestation.jpg");
    assert(documentation.orgKeybase == "accountname");
    assert(documentation.orgTwitter == "orgtweet");
    assert(documentation.orgGithub == "orgcode");
    assert(documentation.orgOfficialEmail == "support@domain.com");
    assert(documentation.orgLicensingAuthority == null);
    assert(documentation.orgLicenseType == null);
    assert(documentation.orgLicenseNumber == null);

    PointOfContact pointOfContact = stellarToml.pointsOfContact!.first;
    assert(pointOfContact.name == "Jane Jedidiah Johnson");
    assert(pointOfContact.email == "jane@domain.com");
    assert(pointOfContact.keybase == "crypto_jane");
    assert(pointOfContact.telegram == null);
    assert(pointOfContact.twitter == "crypto_jane");
    assert(pointOfContact.github == "crypto_jane");
    assert(pointOfContact.idPhotoHash ==
        "be688838ca8686e5c90689bf2ab585cef1137c999b48c70b92f67a5c34dc15697b5d11c982ed6d71be1e1e7f7b4e0733884aa97c3f7a339a8ed03577cf74be09");
    assert(pointOfContact.verificationPhotoHash ==
        "016ba8c4cfde65af99cb5fa8b8a37e2eb73f481b3ae34991666df2e04feb6c038666ebd1ec2b6f623967756033c702dde5f423f7d47ab6ed1827ff53783731f7");

    List<Currency?>? currencies = stellarToml.currencies!;
    assert(currencies[0]!.code == "USD");
    assert(currencies[0]!.issuer ==
        "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM");
    assert(currencies[0]!.displayDecimals == 2);
    assert(currencies[1]!.code == "BTC");
    assert(currencies[1]!.issuer ==
        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
    assert(currencies[1]!.displayDecimals == 7);
    assert(currencies[1]!.anchorAssetType == "crypto");
    assert(currencies[1]!.anchorAsset == "BTC");
    assert(currencies[1]!.redemptionInstructions ==
        "Use SEP6 with our federation server");
    assert(currencies[1]!
        .collateralAddresses!
        .contains("2C1mCx3ukix1KfegAY5zgQJV7sanAciZpv"));
    assert(currencies[1]!.collateralAddressSignatures!.contains(
        "304502206e21798a42fae0e854281abd38bacd1aeed3ee3738d9e1446618c4571d10"));
    assert(currencies[2]!.code == "GOAT");
    assert(currencies[2]!.issuer ==
        "GD5T6IPRNCKFOHQWT264YPKOZAWUMMZOLZBJ6BNQMUGPWGRLBK3U7ZNP");
    assert(currencies[2]!.displayDecimals == 2);
    assert(currencies[2]!.name == "goat share");
    assert(currencies[2]!.desc ==
        "1 GOAT token entitles you to a share of revenue from Elkins Goat Farm.");
    assert(currencies[2]!.conditions ==
        "There will only ever be 10,000 GOAT tokens in existence. We will distribute the revenue share annually on Jan. 15th");
    assert(currencies[2]!.image ==
        "https://static.thenounproject.com/png/2292360-200.png");
    assert(currencies[2]!.fixedNumber == 10000);

    assert(currencies[3]!.toml == "https://soneso.com/.well-known/TESTC.toml");

    // Load currency data separately.
    Currency currency = await StellarToml.currencyFromUrl(currencies[3]!.toml!);
    assert(currency.code == "TESTC");
    assert(currency.issuer ==
        "GCPWPTAX6QVJQIQARN2WESISHVLN65D4HAGQECHLCAV22UST3W2Q6QTA");
    assert(currency.displayDecimals == 2);
    assert(currency.name == "test currency");
    assert(currency.desc == "TESTC description");
    assert(currency.conditions == "TESTC conditions");
    assert(currency.image == "https://soneso.com/123.png");
    assert(currency.fixedNumber == 10000);

    List<Validator?>? validators = stellarToml.validators!;
    assert(validators[0]!.alias == "domain-au");
    assert(validators[0]!.displayName == "Domain Australia");
    assert(validators[0]!.host == "core-au.domain.com:11625");
    assert(validators[0]!.publicKey ==
        "GD5DJQDDBKGAYNEAXU562HYGOOSYAEOO6AS53PZXBOZGCP5M2OPGMZV3");
    assert(validators[0]!.history ==
        "http://history.domain.com/prd/core-live/core_live_001/");
    assert(validators[1]!.alias == "domain-sg");
    assert(validators[1]!.displayName == "Domain Singapore");
    assert(validators[1]!.host == "core-sg.domain.com:11625");
    assert(validators[1]!.publicKey ==
        "GAENZLGHJGJRCMX5VCHOLHQXU3EMCU5XWDNU4BGGJFNLI2EL354IVBK7");
    assert(validators[1]!.history ==
        "http://history.domain.com/prd/core-live/core_live_002/");
    assert(validators[2]!.alias == "domain-us");
    assert(validators[2]!.displayName == "Domain United States");
    assert(validators[2]!.host == "core-us.domain.com:11625");
    assert(validators[2]!.publicKey ==
        "GAOO3LWBC4XF6VWRP5ESJ6IBHAISVJMSBTALHOQM2EZG7Q477UWA6L7U");
    assert(validators[2]!.history ==
        "http://history.domain.com/prd/core-live/core_live_003/");
  });
}
