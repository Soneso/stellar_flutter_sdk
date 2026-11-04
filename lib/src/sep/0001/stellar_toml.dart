// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:toml/toml.dart';

/// Parses and provides access to stellar.toml files as defined in SEP-0001.
///
/// The stellar.toml file is a standardized configuration file that organizations
/// publish at `https://DOMAIN/.well-known/stellar.toml` to provide information
/// about their Stellar integration, including service endpoints, validators,
/// currencies, and organizational details.
///
/// This class supports parsing stellar.toml from either a raw TOML string or
/// by automatically fetching from a domain's well-known location.
///
/// The stellar.toml file serves several critical purposes:
/// - Declares service endpoints for SEP implementations (WebAuth, Transfer, KYC, etc.)
/// - Publishes organization information and contact details for transparency
/// - Lists supported currencies/assets with their properties
/// - Declares validator nodes and their configuration
/// - Links Stellar accounts to a domain for identity verification
///
/// Parameters for the constructor:
/// - [toml] Raw TOML content as a string
///
/// Example - Fetch from domain:
/// ```dart
/// // Fetch and parse stellar.toml from a domain
/// final stellarToml = await StellarToml.fromDomain('example.com');
///
/// // Access general information
/// print('WebAuth endpoint: ${stellarToml.generalInformation.webAuthEndpoint}');
/// print('Transfer server: ${stellarToml.generalInformation.transferServer}');
///
/// // Access organization documentation
/// if (stellarToml.documentation != null) {
///   print('Organization: ${stellarToml.documentation!.orgName}');
///   print('Support email: ${stellarToml.documentation!.orgSupportEmail}');
/// }
///
/// // Iterate through supported currencies
/// if (stellarToml.currencies != null) {
///   for (var currency in stellarToml.currencies!) {
///     print('Currency: ${currency.code} issued by ${currency.issuer}');
///     print('Description: ${currency.desc}');
///   }
/// }
/// ```
///
/// Example - Parse from string:
/// ```dart
/// final tomlContent = '''
/// NETWORK_PASSPHRASE = "Public Global Stellar Network ; September 2015"
/// WEB_AUTH_ENDPOINT = "https://example.com/auth"
/// SIGNING_KEY = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
///
/// [DOCUMENTATION]
/// ORG_NAME = "Example Organization"
/// ORG_URL = "https://example.com"
/// ''';
///
/// final stellarToml = StellarToml(tomlContent);
/// print(stellarToml.generalInformation.webAuthEndpoint);
/// ```
///
/// Example - Load currency from external TOML:
/// ```dart
/// // Some currencies may be defined in separate files
/// final currency = stellarToml.currencies!.first;
/// if (currency.toml != null) {
///   final fullCurrency = await StellarToml.currencyFromUrl(currency.toml!);
///   print('Full currency details: ${fullCurrency.desc}');
/// }
/// ```
///
/// Security considerations:
/// - Always verify HTTPS is used when fetching stellar.toml files
/// - Validate signing keys match expected values for critical operations
/// - Cross-reference account information with on-chain data
/// - Be aware that stellar.toml content can change; cache appropriately
///
/// See also:
/// - [SEP-0001 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
/// - [fromDomain] for fetching stellar.toml from a domain
/// - [currencyFromUrl] for loading currency details from external TOML files
///
/// Supported Version: 2.7.0
class StellarToml {
  late GeneralInformation generalInformation;
  Documentation? documentation;
  List<PointOfContact>? pointsOfContact;
  List<Currency>? currencies;
  List<Validator>? validators;

  /// Constructs a StellarToml instance by parsing raw TOML content.
  ///
  /// Parses the provided TOML string and extracts all stellar.toml sections
  /// including general information, documentation, points of contact, currencies,
  /// and validator information according to SEP-0001 specification.
  ///
  /// The constructor automatically applies content safeguards to correct common
  /// TOML formatting errors found in real-world stellar.toml files.
  ///
  /// Parameters:
  /// - [toml] Raw TOML content string to parse
  ///
  /// Example:
  /// ```dart
  /// final tomlContent = '''
  /// VERSION = "2.7.0"
  /// NETWORK_PASSPHRASE = "Public Global Stellar Network ; September 2015"
  /// WEB_AUTH_ENDPOINT = "https://example.com/auth"
  /// SIGNING_KEY = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP"
  ///
  /// [DOCUMENTATION]
  /// ORG_NAME = "Example Organization"
  /// ORG_URL = "https://example.com"
  ///
  /// [[CURRENCIES]]
  /// code = "USD"
  /// issuer = "GCZJM35NKGVK47BB4SPBDV25477PZYIYPVVG453LPYFNXLS3FGHDXOCM"
  /// ''';
  ///
  /// final stellarToml = StellarToml(tomlContent);
  /// print(stellarToml.generalInformation.webAuthEndpoint);
  /// print(stellarToml.documentation?.orgName);
  /// print(stellarToml.currencies?.first.code);
  /// ```
  ///
  /// See also:
  /// - [fromDomain] for fetching and parsing stellar.toml from a domain
  /// - [safeguardTomlContent] for details on automatic content corrections
  StellarToml(String toml) {
    final safeToml = safeguardTomlContent(toml);

    var document = TomlDocument.parse(safeToml).toMap();
    String? text(String key) => _field<String>(document, key);

    generalInformation = GeneralInformation();
    generalInformation.version = text('VERSION');
    generalInformation.networkPassphrase = text('NETWORK_PASSPHRASE');
    generalInformation.federationServer = text('FEDERATION_SERVER');
    generalInformation.authServer = text('AUTH_SERVER');
    generalInformation.transferServer = text('TRANSFER_SERVER');
    generalInformation.transferServerSep24 = text('TRANSFER_SERVER_SEP0024');
    generalInformation.kYCServer = text('KYC_SERVER');
    generalInformation.webAuthEndpoint = text('WEB_AUTH_ENDPOINT');
    generalInformation.signingKey = text('SIGNING_KEY');
    generalInformation.horizonUrl = text('HORIZON_URL');

    generalInformation.accounts.addAll(
      _list<String>(document, 'ACCOUNTS') ?? [],
    );
    generalInformation.uriRequestSigningKey = text('URI_REQUEST_SIGNING_KEY');
    generalInformation.directPaymentServer = text('DIRECT_PAYMENT_SERVER');
    generalInformation.anchorQuoteServer = text('ANCHOR_QUOTE_SERVER');
    generalInformation.webAuthForContractsEndpoint = text(
      'WEB_AUTH_FOR_CONTRACTS_ENDPOINT',
    );
    generalInformation.webAuthContractId = text('WEB_AUTH_CONTRACT_ID');

    final doc = _field<Map>(document, 'DOCUMENTATION');
    if (doc != null) {
      String? docText(String key) => _field<String>(doc, key, 'DOCUMENTATION');
      documentation = Documentation();
      documentation!.orgName = docText('ORG_NAME');
      documentation!.orgDBA = docText('ORG_DBA');
      documentation!.orgUrl = docText('ORG_URL');
      documentation!.orgLogo = docText('ORG_LOGO');
      documentation!.orgDescription = docText('ORG_DESCRIPTION');
      documentation!.orgPhysicalAddress = docText('ORG_PHYSICAL_ADDRESS');
      documentation!.orgPhysicalAddressAttestation = docText(
        'ORG_PHYSICAL_ADDRESS_ATTESTATION',
      );
      documentation!.orgPhoneNumber = docText('ORG_PHONE_NUMBER');
      documentation!.orgPhoneNumberAttestation = docText(
        'ORG_PHONE_NUMBER_ATTESTATION',
      );
      documentation!.orgKeybase = docText('ORG_KEYBASE');
      documentation!.orgTwitter = docText('ORG_TWITTER');
      documentation!.orgGithub = docText('ORG_GITHUB');
      documentation!.orgOfficialEmail = docText('ORG_OFFICIAL_EMAIL');
      documentation!.orgSupportEmail = docText('ORG_SUPPORT_EMAIL');
      documentation!.orgLicensingAuthority = docText('ORG_LICENSING_AUTHORITY');
      documentation!.orgLicenseType = docText('ORG_LICENSE_TYPE');
      documentation!.orgLicenseNumber = docText('ORG_LICENSE_NUMBER');
    }

    final principals = _list<Map>(document, 'PRINCIPALS');
    if (principals != null) {
      pointsOfContact = List<PointOfContact>.empty(growable: true);
      for (var i = 0; i < principals.length; i++) {
        final item = principals[i];
        final path = 'PRINCIPALS[$i]';
        String? text(String key) => _field<String>(item, key, path);
        PointOfContact pointOfContact = PointOfContact();
        pointOfContact.name = text('name');
        pointOfContact.email = text('email');
        pointOfContact.keybase = text('keybase');
        pointOfContact.twitter = text('twitter');
        pointOfContact.telegram = text('telegram');
        pointOfContact.github = text('github');
        pointOfContact.idPhotoHash = text('id_photo_hash');
        pointOfContact.verificationPhotoHash = text('verification_photo_hash');
        pointsOfContact!.add(pointOfContact);
      }
    }

    final entries = _list<Map>(document, 'CURRENCIES');
    if (entries != null) {
      currencies = List<Currency>.empty(growable: true);
      for (var i = 0; i < entries.length; i++) {
        final item = entries[i];
        final path = 'CURRENCIES[$i]';
        Currency currency = _currencyFromItem(item, path);
        currencies!.add(currency);
      }
    }

    final nodes = _list<Map>(document, 'VALIDATORS');
    if (nodes != null) {
      validators = List<Validator>.empty(growable: true);
      for (var i = 0; i < nodes.length; i++) {
        final item = nodes[i];
        final path = 'VALIDATORS[$i]';
        String? text(String key) => _field<String>(item, key, path);
        Validator validator = Validator();
        validator.alias = text('ALIAS');
        validator.displayName = text('DISPLAY_NAME');
        validator.publicKey = text('PUBLIC_KEY');
        validator.host = text('HOST');
        validator.history = text('HISTORY');
        validators!.add(validator);
      }
    }
  }

  /// Returns [value] as a [T], or throws a [FormatException] naming [path] and the type found.
  static T _requireType<T>(dynamic value, String path) {
    if (value is T) return value;
    throw FormatException(
      'Invalid stellar.toml field $path: found ${value.runtimeType}',
    );
  }

  /// [path] names the enclosing table and is empty for the document root.
  static T? _field<T>(Map fields, String key, [String path = '']) {
    final value = fields[key];
    return value == null
        ? null
        : _requireType<T>(value, path.isEmpty ? key : '$path.$key');
  }

  static List<T>? _list<T>(Map fields, String key, [String path = '']) {
    final values = _field<List>(fields, key, path);
    if (values == null) return null;
    final name = path.isEmpty ? key : '$path.$key';
    return [
      for (var i = 0; i < values.length; i++)
        _requireType<T>(values[i], '$name[$i]'),
    ];
  }

  /// Corrects common formatting errors in stellar.toml content.
  ///
  /// Some stellar.toml files in the wild contain invalid TOML syntax, particularly
  /// with array table declarations. This method automatically corrects these issues
  /// to allow successful parsing while logging warnings.
  ///
  /// Common corrections made:
  /// - `[ACCOUNTS]` -> `[[ACCOUNTS]]` (should be array of tables)
  /// - `[[DOCUMENTATION]]` -> `[DOCUMENTATION]` (should be single table)
  /// - `[PRINCIPALS]` -> `[[PRINCIPALS]]` (should be array of tables)
  /// - `[CURRENCIES]` -> `[[CURRENCIES]]` (should be array of tables)
  /// - `[VALIDATORS]` -> `[[VALIDATORS]]` (should be array of tables)
  ///
  /// Parameters:
  /// - [input] The raw TOML content string
  ///
  /// Returns: Corrected TOML content string
  ///
  /// Note: Corrections are logged to help identify stellar.toml files that
  /// should be fixed by their publishers.
  String safeguardTomlContent(String input) {
    final lines = input.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final trimmedLine = lines[i].trimLeft();
      if (trimmedLine.startsWith("[ACCOUNTS]")) {
        log(
          "Replacing [ACCOUNTS] with [[ACCOUNTS]]. The [ACCOUNTS] value is invalid, please contact the issuer of the stellar.toml file and ask them to fix their stellar.toml file.",
          name: "stellar_flutter_sdk",
        );
        lines[i] = lines[i].replaceFirst("[ACCOUNTS]", "[[ACCOUNTS]]");
      }
      if (trimmedLine.startsWith("[[DOCUMENTATION]]")) {
        log(
          "Replacing [[DOCUMENTATION]] with [DOCUMENTATION]. The [[DOCUMENTATION]] value is invalid, please contact the issuer of the stellar.toml file and ask them to fix their stellar.toml file.",
          name: "stellar_flutter_sdk",
        );
        lines[i] = lines[i].replaceFirst(
          "[[DOCUMENTATION]]",
          "[DOCUMENTATION]",
        );
      }
      if (trimmedLine.startsWith("[PRINCIPALS]")) {
        log(
          "Replacing [PRINCIPALS] with [[PRINCIPALS]]. The [PRINCIPALS] value is invalid, please contact the issuer of the stellar.toml file and ask them to fix their stellar.toml file.",
          name: "stellar_flutter_sdk",
        );
        lines[i] = lines[i].replaceFirst("[PRINCIPALS]", "[[PRINCIPALS]]");
      }
      if (trimmedLine.startsWith("[CURRENCIES]")) {
        log(
          "Replacing [CURRENCIES] with [[CURRENCIES]]. The [CURRENCIES] value is invalid, please contact the issuer of the stellar.toml file and ask them to fix their stellar.toml file.",
          name: "stellar_flutter_sdk",
        );
        lines[i] = lines[i].replaceFirst("[CURRENCIES]", "[[CURRENCIES]]");
      }
      if (trimmedLine.startsWith("[VALIDATORS]")) {
        log(
          "Replacing [VALIDATORS] with [[VALIDATORS]]. The [VALIDATORS] value is invalid, please contact the issuer of the stellar.toml file and ask them to fix their stellar.toml file.",
          name: "stellar_flutter_sdk",
        );
        lines[i] = lines[i].replaceFirst("[VALIDATORS]", "[[VALIDATORS]]");
      }
    }
    return lines.join('\n');
  }

  /// Fetches and parses stellar.toml from a domain's well-known location.
  ///
  /// Automatically constructs the standard stellar.toml URL for the given domain
  /// and fetches the content via HTTPS. The standard location is always:
  /// `https://DOMAIN/.well-known/stellar.toml`
  ///
  /// This is the primary method for discovering a domain's Stellar integration
  /// information. Organizations publish their stellar.toml file at this standardized
  /// location to allow wallets, anchors, and other services to discover their
  /// capabilities and configuration.
  ///
  /// Parameters:
  /// - [domain] The domain name (without protocol). E.g., "example.com"
  /// - [httpClient] Optional custom HTTP client for testing or proxy configuration
  /// - [httpRequestHeaders] Optional custom HTTP headers to include in the request
  ///
  /// Returns: Future<StellarToml> containing the parsed stellar.toml data
  ///
  /// Throws:
  /// - Exception if the stellar.toml file is not found (non-200 status code)
  /// - FormatException if the TOML content cannot be parsed or a field, section or list element has the wrong type
  ///
  /// Example:
  /// ```dart
  /// // Fetch stellar.toml from a domain
  /// try {
  ///   final stellarToml = await StellarToml.fromDomain('example.com');
  ///
  ///   // Check if the domain supports WebAuth
  ///   if (stellarToml.generalInformation.webAuthEndpoint != null) {
  ///     print('WebAuth supported at: ${stellarToml.generalInformation.webAuthEndpoint}');
  ///   }
  ///
  ///   // Check for transfer server
  ///   if (stellarToml.generalInformation.transferServerSep24 != null) {
  ///     print('SEP-24 transfers available');
  ///   }
  /// } catch (e) {
  ///   print('Failed to fetch stellar.toml: $e');
  /// }
  /// ```
  ///
  /// Example with custom headers:
  /// ```dart
  /// final stellarToml = await StellarToml.fromDomain(
  ///   'example.com',
  ///   httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
  /// );
  /// ```
  static Future<StellarToml> fromDomain(
    String domain, {
    http.Client? httpClient,
    Map<String, String>? httpRequestHeaders,
  }) async {
    Uri uri = Uri.parse("https://" + domain + "/.well-known/stellar.toml");
    http.Client client = httpClient == null ? http.Client() : httpClient;
    return await client.get(uri, headers: httpRequestHeaders).then((response) {
      if (response.statusCode != 200) {
        throw Exception(
          "Stellar toml not found, response status code ${response.statusCode}",
        );
      }
      return new StellarToml(response.body);
    });
  }

  /// Loads detailed currency information from an external TOML file.
  ///
  /// Instead of embedding complete currency information directly in stellar.toml,
  /// organizations can link to separate TOML files for each currency. This is useful
  /// when currency information is extensive or when the same currency details need
  /// to be shared across multiple services.
  ///
  /// When a currency entry in stellar.toml contains only a `toml` field pointing to
  /// an external URL (e.g., `toml="https://DOMAIN/.well-known/USDC.toml"`), use this
  /// method to fetch and parse the complete currency information.
  ///
  /// Parameters:
  /// - [toml] The full URL to the currency TOML file
  /// - [httpClient] Optional custom HTTP client for testing or proxy configuration
  /// - [httpRequestHeaders] Optional custom HTTP headers to include in the request
  ///
  /// Returns: Future<Currency> containing the complete currency information
  ///
  /// Throws:
  /// - Exception if the currency TOML file is not found (non-200 status code)
  /// - FormatException if the TOML content cannot be parsed or a field, section or list element has the wrong type
  ///
  /// Example:
  /// ```dart
  /// final stellarToml = await StellarToml.fromDomain('example.com');
  ///
  /// // Check if any currencies link to external TOML files
  /// if (stellarToml.currencies != null) {
  ///   for (var currency in stellarToml.currencies!) {
  ///     if (currency.toml != null) {
  ///       // This currency's details are in an external file
  ///       final fullCurrency = await StellarToml.currencyFromUrl(currency.toml!);
  ///       print('${fullCurrency.code}: ${fullCurrency.desc}');
  ///       print('Issuer: ${fullCurrency.issuer}');
  ///       if (fullCurrency.isAssetAnchored == true) {
  ///         print('Anchored to: ${fullCurrency.anchorAsset}');
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  static Future<Currency> currencyFromUrl(
    String toml, {
    http.Client? httpClient,
    Map<String, String>? httpRequestHeaders,
  }) async {
    Uri uri = Uri.parse(toml);

    http.Client client = httpClient == null ? http.Client() : httpClient;

    return await client.get(uri, headers: httpRequestHeaders).then((response) {
      if (response.statusCode != 200) {
        throw Exception(
          "Currency toml not found, response status code ${response.statusCode}",
        );
      }
      // var parser = new TomlParser();
      // var document = parser.parse(response.body).value;
      var document = TomlDocument.parse(response.body).toMap();
      return _currencyFromItem(document);
    });
  }

  /// Converts a TOML map item into a Currency object.
  ///
  /// Internal helper method that maps TOML key-value pairs to Currency object
  /// properties. Handles all currency fields defined in SEP-0001 including code,
  /// issuer, contract, status, anchoring information, collateral addresses, and
  /// regulatory compliance fields.
  ///
  /// This method is used by both the main constructor and [currencyFromUrl] to
  /// ensure consistent currency parsing from any TOML source.
  ///
  /// Parameters:
  /// - [item] A map representing a single currency entry from parsed TOML
  ///
  /// Returns: Currency object populated with all available fields from the TOML item
  static Currency _currencyFromItem(Map item, [String path = '']) {
    String? text(String key) => _field<String>(item, key, path);
    Currency currency = Currency();
    currency.toml = text('toml');
    currency.code = text('code');
    currency.codeTemplate = text('code_template');
    currency.issuer = text('issuer');
    currency.contract = text('contract');
    currency.status = text('status');
    currency.displayDecimals = _field<int>(item, 'display_decimals', path);
    currency.name = text('name');
    currency.desc = text('desc');
    currency.conditions = text('conditions');
    currency.image = text('image');
    currency.fixedNumber = _field<int>(item, 'fixed_number', path);
    currency.maxNumber = _field<int>(item, 'max_number', path);
    currency.isUnlimited = _field<bool>(item, 'is_unlimited', path);
    currency.isAssetAnchored = _field<bool>(item, 'is_asset_anchored', path);
    currency.anchorAssetType = text('anchor_asset_type');
    currency.anchorAsset = text('anchor_asset');
    currency.attestationOfReserve = text('attestation_of_reserve');
    currency.redemptionInstructions = text('redemption_instructions');

    currency.collateralAddresses = _list<String>(
      item,
      'collateral_addresses',
      path,
    );
    currency.collateralAddressMessages = _list<String>(
      item,
      'collateral_address_messages',
      path,
    );
    currency.collateralAddressSignatures = _list<String>(
      item,
      'collateral_address_signatures',
      path,
    );

    currency.regulated = _field<bool>(item, 'regulated', path);
    currency.approvalServer = text('approval_server');
    currency.approvalCriteria = text('approval_criteria');

    return currency;
  }
}

/// General information from the stellar.toml file.
/// See [Stellar Toml](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
class GeneralInformation {
  /// The version of SEP-1 your stellar.toml adheres to. This helps parsers know which fields to expect.
  String? version;

  /// The passphrase for the specific Stellar network this infrastructure operates on.
  String? networkPassphrase;

  /// The endpoint for clients to resolve stellar addresses for users on your domain via SEP-2 Federation Protocol.
  String? federationServer;

  /// The endpoint used for SEP-3 Compliance Protocol.
  String? authServer;

  /// The server used for SEP-6 Anchor/Client interoperability.
  String? transferServer;

  /// The server used for SEP-24 Anchor/Client interoperability.
  String? transferServerSep24;

  /// The server used for SEP-12 Anchor/Client customer info transfer.
  String? kYCServer;

  /// The endpoint used for SEP-10 Web Authentication.
  String? webAuthEndpoint;

  /// The signing key is used for SEP-3 Compliance Protocol (deprecated) and SEP-10 Authentication Protocol.
  String? signingKey;

  /// Location of public-facing Horizon instance (if one is offered).
  String? horizonUrl;

  /// A list of Stellar accounts that are controlled by this domain.
  List<String> accounts = [];

  /// The signing key is used for SEP-7 delegated signing.
  String? uriRequestSigningKey;

  /// The server used for receiving SEP-31 direct fiat-to-fiat payments. Requires SEP-12 and hence a KYC_SERVER TOML attribute.
  String? directPaymentServer;

  /// The server used for receiving SEP-38 requests.
  String? anchorQuoteServer;

  /// The endpoint used for SEP-45 Web Authentication (contract-based auth).
  String? webAuthForContractsEndpoint;

  /// The web authentication contract ID for SEP-45 Web Authentication.
  String? webAuthContractId;
}

/// Organization Documentation. From the stellar.toml DOCUMENTATION table.
/// See [Stellar Toml](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
class Documentation {
  /// Legal name of the organization.
  String? orgName;

  /// (may not apply) DBA of the organization.
  String? orgDBA;

  /// The organization's official URL. The stellar.toml must be hosted on the same domain.
  String? orgUrl;

  /// An Url to a PNG image of the organization's logo on a transparent background.
  String? orgLogo;

  /// Short description of the organization.
  String? orgDescription;

  /// Physical address for the organization.
  String? orgPhysicalAddress;

  /// URL on the same domain as the orgUrl that contains an image or pdf official document attesting to the physical address. It must list the orgName or orgDBA as the party at the address. Only documents from an official third party are acceptable. E.g. a utility bill, mail from a financial institution, or business license.
  String? orgPhysicalAddressAttestation;

  /// The organization's phone number in E.164 format, e.g. +14155552671.
  String? orgPhoneNumber;

  /// URL on the same domain as the orgUrl that contains an image or pdf of a phone bill showing both the phone number and the organization's name.
  String? orgPhoneNumberAttestation;

  /// A Keybase account name for the organization. Should contain proof of ownership of any public online accounts you list here, including the organization's domain.
  String? orgKeybase;

  /// The organization's Twitter account.
  String? orgTwitter;

  /// The organization's Github account
  String? orgGithub;

  /// An email where clients can contact the organization. Must be hosted at the orgUrl domain.
  String? orgOfficialEmail;

  /// An email that users can use to request support regarding the organizations Stellar assets or applications.
  String? orgSupportEmail;

  /// Name of the authority or agency that licensed the organization, if applicable.
  String? orgLicensingAuthority;

  /// Type of financial or other license the organization holds, if applicable.
  String? orgLicenseType;

  /// Official license number of the organization, if applicable.
  String? orgLicenseNumber;
}

/// Point of Contact Documentation. From the stellar.toml PRINCIPALS list. It contains identifying information for the primary point of contact or principal of the organization.
/// See [Stellar Toml](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
class PointOfContact {
  /// Full legal name.
  String? name;

  /// Business email address for the principal.
  String? email;

  /// Personal Keybase account. Should include proof of ownership for other online accounts, as well as the organization's domain.
  String? keybase;

  /// Personal Telegram account.
  String? telegram;

  /// Personal Twitter account.
  String? twitter;

  /// Personal Github account.
  String? github;

  /// SHA-256 hash of a photo of the principal's government-issued photo ID.
  String? idPhotoHash;

  /// SHA-256 hash of a verification photo of principal. Should be well-lit and contain: principal holding ID card and signed, dated, hand-written message stating I, $name, am a principal of $orgName, a Stellar token issuer with address $issuerAddress.
  String? verificationPhotoHash;
}

/// Currency Documentation. From the stellar.toml CURRENCIES list, one set of fields for each currency supported. Applicable fields should be completed and any that don't apply should be excluded.
/// See [Stellar Toml](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
class Currency {
  /// Token code.
  String? code;

  /// A pattern with ? as a single character wildcard. Allows a CURRENCIES entry to apply to multiple assets that share the same info. An example is futures, where the only difference between issues is the date of the contract. E.g. CORN???????? to match codes such as CORN20180604.
  String? codeTemplate;

  /// Token issuer Stellar public key.
  String? issuer;

  /// Contract ID of the token contract. The token must be compatible with the SEP-41 Token Interface to be defined here. Required for tokens that are not Stellar Assets. Omitted if the token is a Stellar Asset.
  String? contract;

  /// Status of token. One of live, dead, test, or private. Allows issuer to mark whether token is dead/for testing/for private use or is live and should be listed in live exchanges.
  String? status;

  /// Preference for number of decimals to show when a client displays currency balance.
  int? displayDecimals;

  /// A short name for the token.
  String? name;

  /// Description of token and what it represents.
  String? desc;

  /// Conditions on token.
  String? conditions;

  /// URL to a PNG image on a transparent background representing token.
  String? image;

  /// Fixed number of tokens, if the number of tokens issued will never change.
  int? fixedNumber;

  /// Max number of tokens, if there will never be more than maxNumber tokens.
  int? maxNumber;

  /// The number of tokens is dilutable at the issuer's discretion.
  bool? isUnlimited;

  /// true if token can be redeemed for underlying asset, otherwise false.
  bool? isAssetAnchored;

  /// Type of asset anchored. Can be fiat, crypto, nft, stock, bond, commodity, realestate, or other.
  String? anchorAssetType;

  /// If anchored token, code / symbol for asset that token is anchored to. E.g. USD, BTC, SBUX, Address of real-estate investment property.
  String? anchorAsset;

  /// URL to attestation or other proof, evidence, or verification of reserves, such as third-party audits.
  String? attestationOfReserve;

  /// If anchored token, these are instructions to redeem the underlying asset from tokens.
  String? redemptionInstructions;

  /// If this is an anchored crypto token, list of one or more public addresses that hold the assets for which you are issuing tokens.
  List<String>? collateralAddresses;

  /// Messages stating that funds in the collateralAddresses list are reserved to back the issued asset.
  List<String>? collateralAddressMessages;

  /// These prove you control the collateralAddresses. For each address you list, sign the entry in collateralAddressMessages with the address's private key and add the resulting string to this list as a base64-encoded raw signature.
  List<String>? collateralAddressSignatures;

  /// Indicates whether or not this is a sep0008 regulated asset. If missing, false is assumed.
  bool? regulated;

  /// URL of a sep0008 compliant approval service that signs validated transactions.
  String? approvalServer;

  /// A human readable string that explains the issuer's requirements for approving transactions.
  String? approvalCriteria;

  /// Alternately, stellar.toml can link out to a separate TOML file for each currency by specifying toml="https://DOMAIN/.well-known/CURRENCY.toml" as the currency's only field.
  /// In this case only this field is filled. To load the currency data, you can use StellarToml.currencyFromUrl(String toml).
  String? toml;
}

/// Validator Information. From the the stellar.toml VALIDATORS list, one set of fields for each node your organization runs. Combined with the steps outlined in SEP-20, this section allows to declare the node(s), and to let others know the location of any public archives they maintain.
/// See [Stellar Toml](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
class Validator {
  /// A name for display in stellar-core configs that conforms to `^[a-z0-9-]{2,16}$`.
  String? alias;

  /// A human-readable name for display in quorum explorers and other interfaces.
  String? displayName;

  /// The Stellar account associated with the node.
  String? publicKey;

  /// The IP:port or domain:port peers can use to connect to the node.
  String? host;

  /// The location of the history archive published by this validator.
  String? history;
}
