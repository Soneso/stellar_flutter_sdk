// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'dart:async';
import '../../requests/request_builder.dart';
import 'package:toml/decoder.dart';

/// Parses the stellar toml data from a given string or from a given domain.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md" target="_blank">Stellar Toml</a>
class StellarToml {
  GeneralInformation generalInformation;
  Documentation documentation;
  List<PointOfContact> pointsOfContact;
  List<Currency> currencies;
  List<Validator> validators;

  StellarToml(String toml) {
    var parser = new TomlParser();
    var document = parser.parse(toml).value;

    generalInformation = GeneralInformation();
    generalInformation.version = document['VERSION'];
    generalInformation.networkPassphrase = document['NETWORK_PASSPHRASE'];
    generalInformation.federationServer = document['FEDERATION_SERVER'];
    generalInformation.authServer = document['AUTH_SERVER'];
    generalInformation.transferServer = document['TRANSFER_SERVER'];
    generalInformation.transferServerSep24 =
        document['TRANSFER_SERVER_SEP0024'];
    generalInformation.kYCServer = document['KYC_SERVER'];
    generalInformation.webAuthEndpoint = document['WEB_AUTH_ENDPOINT'];
    generalInformation.signingKey = document['SIGNING_KEY'];
    generalInformation.horizonUrl = document['HORIZON_URL'];
    document['ACCOUNTS'].forEach((var item) {
      generalInformation.accounts.add(item);
    });
    generalInformation.uriRequestSigningKey =
        document['URI_REQUEST_SIGNING_KEY'];

    documentation = Documentation();
    documentation.orgName = document['DOCUMENTATION']['ORG_NAME'];
    documentation.orgDBA = document['DOCUMENTATION']['ORG_DBA'];
    documentation.orgUrl = document['DOCUMENTATION']['ORG_URL'];
    documentation.orgLogo = document['DOCUMENTATION']['ORG_LOGO'];
    documentation.orgDescription = document['DOCUMENTATION']['ORG_DESCRIPTION'];
    documentation.orgPhysicalAddress =
        document['DOCUMENTATION']['ORG_PHYSICAL_ADDRESS'];
    documentation.orgPhysicalAddressAttestation =
        document['DOCUMENTATION']['ORG_PHYSICAL_ADDRESS_ATTESTATION'];
    documentation.orgPhoneNumber =
        document['DOCUMENTATION']['ORG_PHONE_NUMBER'];
    documentation.orgPhoneNumberAttestation =
        document['DOCUMENTATION']['ORG_PHONE_NUMBER_ATTESTATION'];
    documentation.orgKeybase = document['DOCUMENTATION']['ORG_KEYBASE'];
    documentation.orgTwitter = document['DOCUMENTATION']['ORG_TWITTER'];
    documentation.orgGithub = document['DOCUMENTATION']['ORG_GITHUB'];
    documentation.orgOfficialEmail =
        document['DOCUMENTATION']['ORG_OFFICIAL_EMAIL'];
    documentation.orgLicensingAuthority =
        document['DOCUMENTATION']['ORG_LICENSING_AUTHORITY'];
    documentation.orgLicenseType =
        document['DOCUMENTATION']['ORG_LICENSE_TYPE'];
    documentation.orgLicenseNumber =
        document['DOCUMENTATION']['ORG_LICENSE_NUMBER'];

    pointsOfContact = List<PointOfContact>();
    document['PRINCIPALS'].forEach((var item) {
      PointOfContact pointOfContact = PointOfContact();
      pointOfContact.name = item['name'];
      pointOfContact.email = item['email'];
      pointOfContact.keybase = item['keybase'];
      pointOfContact.twitter = item['twitter'];
      pointOfContact.telegram = item['telegram'];
      pointOfContact.github = item['github'];
      pointOfContact.idPhotoHash = item['id_photo_hash'];
      pointOfContact.verificationPhotoHash = item['verification_photo_hash'];
      pointsOfContact.add(pointOfContact);
    });

    currencies = List<Currency>();
    document['CURRENCIES'].forEach((var item) {
      Currency currency = _currencyFromItem(item);
      currencies.add(currency);
    });

    validators = List<Validator>();
    document['VALIDATORS'].forEach((var item) {
      Validator validator = Validator();
      validator.alias = item['ALIAS'];
      validator.displayName = item['DISPLAY_NAME'];
      validator.publicKey = item['PUBLIC_KEY'];
      validator.host = item['HOST'];
      validator.history = item['HISTORY'];
      validators.add(validator);
    });
  }

  static Future<StellarToml> fromDomain(String domain) async {
    Uri uri = Uri.parse("https://" + domain + "/.well-known/stellar.toml");

    return await http.Client()
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      if (response.statusCode != 200) {
        throw Exception(
            "Stellar toml not found, response status code ${response.statusCode}");
      }
      return new StellarToml(response.body);
    });
  }

  /// Alternately to specifying a currency in its content, stellar.toml can link out to a separate TOML file for the currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
  /// In this case you can use this method to load the currency data from the received link (Currency.toml).
  static Future<Currency> currencyFromUrl(String toml) async {
    Uri uri = Uri.parse(toml);

    return await http.Client()
        .get(uri, headers: RequestBuilder.headers)
        .then((response) {
      if (response.statusCode != 200) {
        throw Exception(
            "Currency toml not found, response status code ${response.statusCode}");
      }
      var parser = new TomlParser();
      var document = parser.parse(response.body).value;
      return _currencyFromItem(document);
    });
  }

  static Currency _currencyFromItem(var item) {
    Currency currency = Currency();
    currency.toml = item['toml'];
    currency.code = item['code'];
    currency.codeTemplate = item['code_template'];
    currency.issuer = item['issuer'];
    currency.status = item['status'];
    currency.displayDecimals = item['display_decimals'];
    currency.name = item['name'];
    currency.desc = item['desc'];
    currency.conditions = item['conditions'];
    currency.image = item['image'];
    currency.fixedNumber = item['fixed_number'];
    currency.maxNumber = item['max_number'];
    currency.isUnlimited = item['is_unlimited'];
    currency.isAssetAnchored = item['is_asset_anchored'];
    currency.anchorAssetType = item['anchor_asset_type'];
    currency.anchorAsset = item['anchor_asset'];
    currency.redemptionInstructions = item['redemption_instructions'];

    var collateralAddresses = item['collateral_addresses'];
    if (collateralAddresses != null) {
      currency.collateralAddresses = List<String>();
      collateralAddresses.forEach((var item) {
        currency.collateralAddresses.add(item);
      });
    }

    var collateralAddressMessages = item['collateral_address_messages'];
    if (collateralAddressMessages != null) {
      currency.collateralAddressMessages = List<String>();
      collateralAddressMessages.forEach((var item) {
        currency.collateralAddressMessages.add(item);
      });
    }

    var collateralAddressSignatures = item['collateral_address_signatures'];
    if (collateralAddressSignatures != null) {
      currency.collateralAddressSignatures = List<String>();
      collateralAddressSignatures.forEach((var item) {
        currency.collateralAddressSignatures.add(item);
      });
    }

    currency.regulated = item['regulated'];
    currency.approvalServer = item['approval_server'];
    currency.approvalCriteria = item['approval_criteria'];

    return currency;
  }
}

/// General information from the stellar.toml file.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md" target="_blank">Stellar Toml</a>
class GeneralInformation {
  /// The version of SEP-1 your stellar.toml adheres to. This helps parsers know which fields to expect.
  String version;

  /// The passphrase for the specific Stellar network this infrastructure operates on.
  String networkPassphrase;

  /// The endpoint for clients to resolve stellar addresses for users on your domain via SEP-2 Federation Protocol.
  String federationServer;

  /// The endpoint used for SEP-3 Compliance Protocol.
  String authServer;

  /// The server used for SEP-6 Anchor/Client interoperability.
  String transferServer;

  /// The server used for SEP-24 Anchor/Client interoperability.
  String transferServerSep24;

  /// The server used for SEP-12 Anchor/Client customer info transfer.
  String kYCServer;

  /// The endpoint used for SEP-10 Web Authentication.
  String webAuthEndpoint;

  /// The signing key is used for SEP-3 Compliance Protocol and SEP-10 Authentication Protocol.
  String signingKey;

  /// Location of public-facing Horizon instance (if one is offered).
  String horizonUrl;

  /// A list of Stellar accounts that are controlled by this domain.
  List<String> accounts = List<String>();

  /// The signing key is used for SEP-7 delegated signing.
  String uriRequestSigningKey;
}

/// Organization Documentation. From the stellar.toml DOCUMENTATION table.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md" target="_blank">Stellar Toml</a>
class Documentation {
  /// Legal name of the organization.
  String orgName;

  /// (may not apply) DBA of the organization.
  String orgDBA;

  /// The organization's official URL. The stellar.toml must be hosted on the same domain.
  String orgUrl;

  /// An Url to a PNG image of the organization's logo on a transparent background.
  String orgLogo;

  /// Short description of the organization.
  String orgDescription;

  /// Physical address for the organization.
  String orgPhysicalAddress;

  /// URL on the same domain as the orgUrl that contains an image or pdf official document attesting to the physical address. It must list the orgName or orgDBA as the party at the address. Only documents from an official third party are acceptable. E.g. a utility bill, mail from a financial institution, or business license.
  String orgPhysicalAddressAttestation;

  /// The organization's phone number in E.164 format, e.g. +14155552671.
  String orgPhoneNumber;

  /// URL on the same domain as the orgUrl that contains an image or pdf of a phone bill showing both the phone number and the organization's name.
  String orgPhoneNumberAttestation;

  /// A Keybase account name for the organization. Should contain proof of ownership of any public online accounts you list here, including the organization's domain.
  String orgKeybase;

  /// The organization's Twitter account.
  String orgTwitter;

  /// The organization's Github account
  String orgGithub;

  /// An email where clients can contact the organization. Must be hosted at the orgUrl domain.
  String orgOfficialEmail;

  /// Name of the authority or agency that licensed the organization, if applicable.
  String orgLicensingAuthority;

  /// Type of financial or other license the organization holds, if applicable.
  String orgLicenseType;

  /// Official license number of the organization, if applicable.
  String orgLicenseNumber;
}

/// Point of Contact Documentation. From the stellar.toml [[PRINCIPALS]] list. It contains identifying information for the primary point of contact or principal of the organization.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md" target="_blank">Stellar Toml</a>
class PointOfContact {
  /// Full legal name.
  String name;

  /// Business email address for the principal.
  String email;

  /// Personal Keybase account. Should include proof of ownership for other online accounts, as well as the organization's domain.
  String keybase;

  /// Personal Telegram account.
  String telegram;

  /// Personal Twitter account.
  String twitter;

  /// Personal Github account.
  String github;

  /// SHA-256 hash of a photo of the principal's government-issued photo ID.
  String idPhotoHash;

  /// SHA-256 hash of a verification photo of principal. Should be well-lit and contain: principal holding ID card and signed, dated, hand-written message stating I, $name, am a principal of $orgName, a Stellar token issuer with address $issuerAddress.
  String verificationPhotoHash;
}

/// Currency Documentation. From the stellar.toml [[CURRENCIES]] list, one set of fields for each currency supported. Applicable fields should be completed and any that don't apply should be excluded.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md" target="_blank">Stellar Toml</a>
class Currency {
  /// Token code.
  String code;

  /// A pattern with ? as a single character wildcard. Allows a [[CURRENCIES]] entry to apply to multiple assets that share the same info. An example is futures, where the only difference between issues is the date of the contract. E.g. CORN???????? to match codes such as CORN20180604.
  String codeTemplate;

  /// Token issuer Stellar public key.
  String issuer;

  /// Status of token. One of live, dead, test, or private. Allows issuer to mark whether token is dead/for testing/for private use or is live and should be listed in live exchanges.
  String status;

  /// Preference for number of decimals to show when a client displays currency balance.
  int displayDecimals;

  /// A short name for the token.
  String name;

  /// Description of token and what it represents.
  String desc;

  /// Conditions on token.
  String conditions;

  /// URL to a PNG image on a transparent background representing token.
  String image;

  /// Fixed number of tokens, if the number of tokens issued will never change.
  int fixedNumber;

  /// Max number of tokens, if there will never be more than maxNumber tokens.
  int maxNumber;

  /// The number of tokens is dilutable at the issuer's discretion.
  bool isUnlimited;

  /// true if token can be redeemed for underlying asset, otherwise false.
  bool isAssetAnchored;

  /// Type of asset anchored. Can be fiat, crypto, stock, bond, commodity, realestate, or other.
  String anchorAssetType;

  /// If anchored token, code / symbol for asset that token is anchored to. E.g. USD, BTC, SBUX, Address of real-estate investment property.
  String anchorAsset;

  /// If anchored token, these are instructions to redeem the underlying asset from tokens.
  String redemptionInstructions;

  /// If this is an anchored crypto token, list of one or more public addresses that hold the assets for which you are issuing tokens.
  List<String> collateralAddresses;

  /// Messages stating that funds in the collateralAddresses list are reserved to back the issued asset.
  List<String> collateralAddressMessages;

  /// These prove you control the collateralAddresses. For each address you list, sign the entry in collateralAddressMessages with the address's private key and add the resulting string to this list as a base64-encoded raw signature.
  List<String> collateralAddressSignatures;

  /// Indicates whether or not this is a sep0008 regulated asset. If missing, false is assumed.
  bool regulated;

  /// URL of a sep0008 compliant approval service that signs validated transactions.
  String approvalServer;

  /// A human readable string that explains the issuer's requirements for approving transactions.
  String approvalCriteria;

  /// Alternately, stellar.toml can link out to a separate TOML file for each currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
  /// In this case only this field is filled. To load the currency data, you can use StellarToml.currencyFromUrl(String toml).
  String toml;
}

/// Validator Information. From the the stellar.toml [[VALIDATORS]] list, one set of fields for each node your organization runs. Combined with the steps outlined in SEP-20, this section allows to declare the node(s), and to let others know the location of any public archives they maintain.
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md" target="_blank">Stellar Toml</a>
class Validator {
  /// A name for display in stellar-core configs that conforms to ^[a-z0-9-]{2,16}$.
  String alias;

  /// A human-readable name for display in quorum explorers and other interfaces.
  String displayName;

  /// The Stellar account associated with the node.
  String publicKey;

  /// The IP:port or domain:port peers can use to connect to the node.
  String host;

  /// The location of the history archive published by this validator.
  String history;
}
