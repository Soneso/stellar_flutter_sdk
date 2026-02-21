import 'dart:typed_data';

/// Implements SEP-0009 - Standard KYC Fields for Stellar Ecosystem.
///
/// Defines standardized Know Your Customer (KYC) and Anti-Money Laundering (AML)
/// fields for use across the Stellar ecosystem. Anchors, exchanges, and other
/// regulated entities should use these fields for consistent identity verification.
///
/// Implementation version: SEP-0009 v1.18.0
///
/// Field categories:
/// - Natural person fields (individuals)
/// - Organization fields (businesses)
/// - Financial account fields (bank accounts, crypto addresses)
/// - Card payment fields (credit/debit cards)
///
/// Use cases:
/// - Anchor deposit/withdrawal identity verification
/// - Exchange account registration
/// - Compliance requirements for regulated transfers
/// - Cross-border payment identity checks
///
/// Protocol specification:
/// - [SEP-0009](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md)
///
/// Example:
/// ```dart
/// // Create KYC data for natural person
/// NaturalPersonKYCFields person = NaturalPersonKYCFields();
/// person.firstName = "John";
/// person.lastName = "Doe";
/// person.emailAddress = "john@example.com";
/// person.birthDate = DateTime(1990, 1, 1);
///
/// StandardKYCFields kyc = StandardKYCFields();
/// kyc.naturalPersonKYCFields = person;
///
/// // Extract fields for API submission
/// Map<String, String> fields = person.fields();
/// ```
///
/// Important notes:
/// - Fields follow ISO standards where applicable
/// - Document images should be in common formats (JPEG, PNG)
/// - Some fields may be required or optional depending on jurisdiction
///
/// See also:
/// - [SEP-0012](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md) for Customer Info API
/// - [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md) for Anchor integration
/// Formats a [DateTime] as a date-only string in YYYY-MM-DD format,
/// as required by SEP-9 for date fields (birth_date, id_issue_date,
/// id_expiration_date).
String _formatDateOnly(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class StandardKYCFields {
  /// KYC fields for natural persons (individuals).
  NaturalPersonKYCFields? naturalPersonKYCFields;

  /// KYC fields for organizations (businesses).
  OrganizationKYCFields? organizationKYCFields;
}

/// KYC fields for natural persons (individuals).
///
/// Contains personal identification information for individual customers.
/// Fields follow international standards (ISO 3166, ISO 639, E.164) where applicable.
///
/// Example:
/// ```dart
/// NaturalPersonKYCFields person = NaturalPersonKYCFields();
/// person.firstName = "John";
/// person.lastName = "Doe";
/// person.emailAddress = "john@example.com";
/// person.birthDate = DateTime(1990, 1, 1);
/// person.addressCountryCode = "USA";
/// person.idType = "passport";
/// person.idNumber = "123456789";
///
/// // Extract fields for submission
/// Map<String, String> textFields = person.fields();
/// Map<String, Uint8List> fileFields = person.files();
/// ```
///
/// See also:
/// - [StandardKYCFields] for the parent container
/// - [FinancialAccountKYCFields] for bank account information
/// - [CardKYCFields] for payment card information
class NaturalPersonKYCFields {
  // field keys
  static const String last_name_field_key = 'last_name';
  static const String first_name_field_key = 'first_name';
  static const String additional_name_field_key = 'additional_name';
  static const String address_country_code_field_key = 'address_country_code';
  static const String state_or_province_field_key = 'state_or_province';
  static const String city_field_key = 'city';
  static const String postal_code_field_key = 'postal_code';
  static const String address_field_key = 'address';
  static const String mobile_number_field_key = 'mobile_number';
  static const String mobile_number_format_field_key = 'mobile_number_format';
  static const String email_address_field_key = 'email_address';
  static const String birth_date_field_key = 'birth_date';
  static const String birth_place_field_key = 'birth_place';
  static const String birth_country_code_field_key = 'birth_country_code';
  static const String tax_id_field_key = 'tax_id';
  static const String tax_id_name_field_key = 'tax_id_name';
  static const String occupation_field_key = 'occupation';
  static const String employer_name_field_key = 'employer_name';
  static const String employer_address_field_key = 'employer_address';
  static const String language_code_field_key = 'language_code';
  static const String id_type_field_key = 'id_type';
  static const String id_country_code_field_key = 'id_country_code';
  static const String id_issue_date_field_key = 'id_issue_date';
  static const String id_expiration_date_field_key = 'id_expiration_date';
  static const String id_number_field_key = 'id_number';
  static const String ip_address_field_key = 'ip_address';
  static const String sex_field_key = 'sex';
  static const String referral_id_field_key = 'referral_id';

  // files keys
  static const String photo_id_front_file_key = 'photo_id_front';
  static const String photo_id_back_file_key = 'photo_id_back';
  static const String notary_approval_of_photo_id_file_key =
      'notary_approval_of_photo_id';
  static const String photo_proof_residence_file_key = 'photo_proof_residence';
  static const String proof_of_income_file_key = 'proof_of_income';
  static const String proof_of_liveness_file_key = 'proof_of_liveness';

  /// Family or last name
  String? lastName;

  /// Given or first name
  String? firstName;

  /// Middle name or other additional name
  String? additionalName;

  /// country code for current address
  String? addressCountryCode;

  /// name of state/province/region/prefecture
  String? stateOrProvince;

  /// name of city/town
  String? city;

  /// Postal or other code identifying user's locale
  String? postalCode;

  /// Entire address (country, state, postal code, street address, etc...) as a multi-line string
  String? address;

  /// Mobile phone number with country code, in E.164 format
  String? mobileNumber;

  /// Expected format of the mobile_number field. E.g.: E.164, hash, etc... In case this field is not specified, receiver will assume it's in E.164 format
  String? mobileNumberFormat;

  /// Email address
  String? emailAddress;

  /// Date of birth, e.g. 1976-07-04
  ///
  /// Note: When serializing with `toIso8601String()`, only the date portion (YYYY-MM-DD)
  /// should be used, not the full timestamp.
  DateTime? birthDate;

  /// Place of birth (city, state, country; as on passport)
  String? birthPlace;

  /// ISO Code of country of birth ISO 3166-1 alpha-3
  String? birthCountryCode;

  /// Tax identifier of user in their country (social security number in US)
  String? taxId;

  /// Name of the tax ID (SSN or ITIN in the US)
  String? taxIdName;

  /// Occupation ISCO code.
  int? occupation;

  /// Name of employer.
  String? employerName;

  /// Address of employer
  String? employerAddress;

  /// primary language ISO 639-1
  String? languageCode;

  /// passport, drivers_license, id_card, etc...
  String? idType;

  /// country issuing passport or photo ID as ISO 3166-1 alpha-3 code
  String? idCountryCode;

  /// ID issue date
  ///
  /// Note: When serializing with `toIso8601String()`, only the date portion (YYYY-MM-DD)
  /// should be used, not the full timestamp.
  DateTime? idIssueDate;

  /// ID expiration date
  ///
  /// Note: When serializing with `toIso8601String()`, only the date portion (YYYY-MM-DD)
  /// should be used, not the full timestamp.
  DateTime? idExpirationDate;

  /// Passport or ID number
  String? idNumber;

  /// Image of front of user's photo ID or passport
  Uint8List? photoIdFront;

  /// 	Image of back of user's photo ID or passport
  Uint8List? photoIdBack;

  /// Image of notary's approval of photo ID or passport
  Uint8List? notaryApprovalOfPhotoId;

  /// IP address of customer's computer
  String? ipAddress;

  /// Image of a utility bill, bank statement or similar with the user's name and address
  Uint8List? photoProofResidence;

  /// male, female, or other
  String? sex;

  /// Image of user's proof of income document
  Uint8List? proofOfIncome;

  /// Video or image file of user as a liveness proof
  Uint8List? proofOfLiveness;

  /// User's origin (such as an id in another application) or a referral code
  String? referralId;

  /// Financial Account Fields
  FinancialAccountKYCFields? financialAccountKYCFields;

  /// Card Fields
  CardKYCFields? cardKYCFields;

  /// Converts all natural person KYC fields to a map of field names to values for SEP-9 submission.
  Map<String, String> fields() {
    final fields = <String, String>{};
    if (lastName != null) {
      fields[last_name_field_key] = lastName!;
    }
    if (firstName != null) {
      fields[first_name_field_key] = firstName!;
    }
    if (additionalName != null) {
      fields[additional_name_field_key] = additionalName!;
    }
    if (addressCountryCode != null) {
      fields[address_country_code_field_key] = addressCountryCode!;
    }
    if (stateOrProvince != null) {
      fields[state_or_province_field_key] = stateOrProvince!;
    }
    if (city != null) {
      fields[city_field_key] = city!;
    }
    if (postalCode != null) {
      fields[postal_code_field_key] = postalCode!;
    }
    if (address != null) {
      fields[address_field_key] = address!;
    }
    if (mobileNumber != null) {
      fields[mobile_number_field_key] = mobileNumber!;
    }
    if (mobileNumberFormat != null) {
      fields[mobile_number_format_field_key] = mobileNumberFormat!;
    }
    if (emailAddress != null) {
      fields[email_address_field_key] = emailAddress!;
    }
    if (birthDate != null) {
      fields[birth_date_field_key] = _formatDateOnly(birthDate!);
    }
    if (birthPlace != null) {
      fields[birth_place_field_key] = birthPlace!;
    }
    if (birthCountryCode != null) {
      fields[birth_country_code_field_key] = birthCountryCode!;
    }
    if (taxId != null) {
      fields[tax_id_field_key] = taxId!;
    }
    if (taxIdName != null) {
      fields[tax_id_name_field_key] = taxIdName!;
    }
    if (occupation != null) {
      fields[occupation_field_key] = occupation.toString();
    }
    if (employerName != null) {
      fields[employer_name_field_key] = employerName!;
    }
    if (employerAddress != null) {
      fields[employer_address_field_key] = employerAddress!;
    }
    if (languageCode != null) {
      fields[language_code_field_key] = languageCode!;
    }
    if (idType != null) {
      fields[id_type_field_key] = idType!;
    }
    if (idCountryCode != null) {
      fields[id_country_code_field_key] = idCountryCode!;
    }
    if (idIssueDate != null) {
      fields[id_issue_date_field_key] = _formatDateOnly(idIssueDate!);
    }
    if (idExpirationDate != null) {
      fields[id_expiration_date_field_key] =
          _formatDateOnly(idExpirationDate!);
    }
    if (idNumber != null) {
      fields[id_number_field_key] = idNumber!;
    }
    if (ipAddress != null) {
      fields[ip_address_field_key] = ipAddress!;
    }
    if (sex != null) {
      fields[sex_field_key] = sex!;
    }
    if (referralId != null) {
      fields[referral_id_field_key] = referralId!;
    }
    if (financialAccountKYCFields != null) {
      fields.addAll(financialAccountKYCFields!.fields());
    }
    if (cardKYCFields != null) {
      fields.addAll(cardKYCFields!.fields());
    }
    return fields;
  }

  /// Converts all natural person KYC file attachments to a map for SEP-9 submission.
  Map<String, Uint8List> files() {
    final files = <String, Uint8List>{};
    if (photoIdFront != null) {
      files[photo_id_front_file_key] = photoIdFront!;
    }
    if (photoIdBack != null) {
      files[photo_id_back_file_key] = photoIdBack!;
    }
    if (notaryApprovalOfPhotoId != null) {
      files[notary_approval_of_photo_id_file_key] = notaryApprovalOfPhotoId!;
    }
    if (photoProofResidence != null) {
      files[photo_proof_residence_file_key] = photoProofResidence!;
    }
    if (proofOfIncome != null) {
      files[proof_of_income_file_key] = proofOfIncome!;
    }
    if (proofOfLiveness != null) {
      files[proof_of_liveness_file_key] = proofOfLiveness!;
    }
    return files;
  }
}

/// Financial account information for KYC verification.
///
/// Contains bank account, mobile money, and cryptocurrency account details
/// for receiving or sending payments.
///
/// Example:
/// ```dart
/// FinancialAccountKYCFields account = FinancialAccountKYCFields();
/// account.bankName = "Example Bank";
/// account.bankAccountNumber = "1234567890";
/// account.bankNumber = "123456789"; // Routing number
/// account.bankBranchNumber = "001";
///
/// // Or for crypto
/// account.cryptoAddress = "GDJK...";
/// account.cryptoMemo = "12345";
/// ```
class FinancialAccountKYCFields {
  // field keys
  static const String bank_name_field_key = 'bank_name';
  static const String bank_account_type_field_key = 'bank_account_type';
  static const String bank_account_number_field_key = 'bank_account_number';
  static const String bank_number_field_key = 'bank_number';
  static const String bank_phone_number_field_key = 'bank_phone_number';
  static const String bank_branch_number_field_key = 'bank_branch_number';
  static const String external_transfer_memo_field_key = 'external_transfer_memo';
  static const String clabe_number_field_key = 'clabe_number';
  static const String cbu_number_field_key = 'cbu_number';
  static const String cbu_alias_field_key = 'cbu_alias';
  static const String mobile_money_number_field_key = 'mobile_money_number';
  static const String mobile_money_provider_field_key = 'mobile_money_provider';
  static const String crypto_address_field_key = 'crypto_address';
  static const String crypto_memo_field_key = 'crypto_memo';

  /// Name of the bank. May be necessary in regions that don't have a unified routing system.
  String? bankName;

  /// Type of bank account (e.g., checking or savings)
  String? bankAccountType;

  /// Number identifying bank account
  String? bankAccountNumber;

  /// Number identifying bank in national banking system (routing number in US)
  String? bankNumber;

  /// Phone number with country code for bank
  String? bankPhoneNumber;

  /// Number identifying bank branch
  String? bankBranchNumber;

  /// A destination tag/memo used to identify a transaction
  String? externalTransferMemo;

  /// Bank account number for Mexico
  String? clabeNumber;

  /// Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU).
  String? cbuNumber;

  /// The alias for a Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU).
  String? cbuAlias;

  /// Mobile phone number in E.164 format with which a mobile money account is associated. Note that this number may be distinct from the same customer's mobile_number.
  String? mobileMoneyNumber;

  /// Name of the mobile money service provider.
  String? mobileMoneyProvider;

  /// Address for a cryptocurrency account
  String? cryptoAddress;

  /// A destination tag/memo used to identify a transaction
  ///
  /// Deprecated: Use [externalTransferMemo] instead.
  /// This field is deprecated in favor of the more general external_transfer_memo field.
  @Deprecated('Use externalTransferMemo instead')
  String? cryptoMemo;

  /// Converts all financial account KYC fields to a map for SEP-9 submission with optional key prefix.
  Map<String, String> fields({String keyPrefix = ''}) {
    final fields = <String, String>{};

    if (bankName != null) {
      fields[keyPrefix + bank_name_field_key] = bankName!;
    }
    if (bankAccountType != null) {
      fields[keyPrefix + bank_account_type_field_key] = bankAccountType!;
    }
    if (bankAccountNumber != null) {
      fields[keyPrefix + bank_account_number_field_key] = bankAccountNumber!;
    }
    if (bankNumber != null) {
      fields[keyPrefix + bank_number_field_key] = bankNumber!;
    }
    if (bankPhoneNumber != null) {
      fields[keyPrefix + bank_phone_number_field_key] = bankPhoneNumber!;
    }
    if (bankBranchNumber != null) {
      fields[keyPrefix + bank_branch_number_field_key] = bankBranchNumber!;
    }
    if (externalTransferMemo != null) {
      fields[keyPrefix + external_transfer_memo_field_key] = externalTransferMemo!;
    }
    if (clabeNumber != null) {
      fields[keyPrefix + clabe_number_field_key] = clabeNumber!;
    }
    if (cbuNumber != null) {
      fields[keyPrefix + cbu_number_field_key] = cbuNumber!;
    }
    if (cbuAlias != null) {
      fields[keyPrefix + cbu_alias_field_key] = cbuAlias!;
    }
    if (mobileMoneyNumber != null) {
      fields[keyPrefix + mobile_money_number_field_key] = mobileMoneyNumber!;
    }
    if (mobileMoneyProvider != null) {
      fields[keyPrefix + mobile_money_provider_field_key] = mobileMoneyProvider!;
    }
    if (cryptoAddress != null) {
      fields[keyPrefix + crypto_address_field_key] = cryptoAddress!;
    }
    if (cryptoMemo != null) {
      fields[keyPrefix + crypto_memo_field_key] = cryptoMemo!;
    }
    return fields;
  }
}

/// KYC fields for organizations (businesses).
///
/// Contains business entity identification information for corporate customers.
/// All field keys are prefixed with "organization."
///
/// Example:
/// ```dart
/// OrganizationKYCFields org = OrganizationKYCFields();
/// org.name = "Example Corp";
/// org.VATNumber = "123456789";
/// org.registrationNumber = "987654321";
/// org.registrationDate = "2020-01-01";
/// org.addressCountryCode = "USA";
/// org.directorName = "Jane Smith";
/// org.email = "contact@example.com";
///
/// // Extract fields for submission
/// Map<String, String> fields = org.fields();
/// ```
///
/// See also:
/// - [StandardKYCFields] for the parent container
/// - [FinancialAccountKYCFields] for bank account information
class OrganizationKYCFields {
  // field keys
  static const String key_prefix = 'organization.';
  static const String name_field_key = key_prefix + 'name';
  static const String VAT_number_field_key = key_prefix + 'VAT_number';
  static const String registration_number_field_key =
      key_prefix + 'registration_number';
  static const String registration_date_field_key =
      key_prefix + 'registration_date';
  static const String registered_address_field_key =
      key_prefix + 'registered_address';
  static const String number_of_shareholders_field_key =
      key_prefix + 'number_of_shareholders';
  static const String shareholder_name_field_key =
      key_prefix + 'shareholder_name';
  static const String address_country_code_field_key =
      key_prefix + 'address_country_code';
  static const String state_or_province_field_key =
      key_prefix + 'state_or_province';
  static const String city_field_key = key_prefix + 'city';
  static const String postal_code_field_key = key_prefix + 'postal_code';
  static const String director_name_field_key = key_prefix + 'director_name';
  static const String website_field_key = key_prefix + 'website';
  static const String email_field_key = key_prefix + 'email';
  static const String phone_field_key = key_prefix + 'phone';

  // files keys
  static const String photo_incorporation_doc_file_key =
      key_prefix + 'photo_incorporation_doc';
  static const String photo_proof_address_file_key =
      key_prefix + 'photo_proof_address';

  /// Full organization name as on the incorporation papers
  String? name;

  /// Organization VAT number
  String? VATNumber;

  /// Organization registration number
  String? registrationNumber;

  /// Date the organization was registered
  String? registrationDate;

  /// Organization registered address
  String? registeredAddress;

  /// Organization shareholder number
  int? numberOfShareholders;

  /// Can be an organization or a person and should be queried recursively up to the ultimate beneficial owners (with KYC information for natural persons such as above)
  String? shareholderName;

  /// Image of incorporation documents
  Uint8List? photoIncorporationDoc;

  /// Image of a utility bill, bank statement with the organization's name and address
  Uint8List? photoProofAddress;

  /// Country code for current address
  String? addressCountryCode;

  /// Name of state/province/region/prefecture
  String? stateOrProvince;

  /// name of city/town
  String? city;

  /// Postal or other code identifying organization's locale
  String? postalCode;

  /// Organization registered managing director
  String? directorName;

  /// Organization website
  String? website;

  /// Organization contact email
  String? email;

  ///	Organization contact phone
  String? phone;

  /// Financial Account Fields
  FinancialAccountKYCFields? financialAccountKYCFields;

  /// Card Fields
  CardKYCFields? cardKYCFields;

  /// Converts all organization KYC fields to a map of field names to values for SEP-9 submission.
  Map<String, String> fields() {
    final fields = <String, String>{};
    if (name != null) {
      fields[name_field_key] = name!;
    }
    if (VATNumber != null) {
      fields[VAT_number_field_key] = VATNumber!;
    }
    if (registrationNumber != null) {
      fields[registration_number_field_key] = registrationNumber!;
    }
    if (registrationDate != null) {
      fields[registration_date_field_key] = registrationDate!;
    }
    if (registeredAddress != null) {
      fields[registered_address_field_key] = registeredAddress!;
    }
    if (numberOfShareholders != null) {
      fields[number_of_shareholders_field_key] =
          numberOfShareholders.toString();
    }
    if (shareholderName != null) {
      fields[shareholder_name_field_key] = shareholderName!;
    }
    if (addressCountryCode != null) {
      fields[address_country_code_field_key] = addressCountryCode!;
    }
    if (stateOrProvince != null) {
      fields[state_or_province_field_key] = stateOrProvince!;
    }
    if (city != null) {
      fields[city_field_key] = city!;
    }
    if (postalCode != null) {
      fields[postal_code_field_key] = postalCode!;
    }
    if (directorName != null) {
      fields[director_name_field_key] = directorName!;
    }
    if (website != null) {
      fields[website_field_key] = website!;
    }
    if (email != null) {
      fields[email_field_key] = email!;
    }
    if (phone != null) {
      fields[phone_field_key] = phone!;
    }
    if (financialAccountKYCFields != null) {
      fields.addAll(financialAccountKYCFields!.fields(keyPrefix: key_prefix));
    }
    if (cardKYCFields != null) {
      fields.addAll(cardKYCFields!.fields());
    }
    return fields;
  }

  /// Converts all organization KYC file attachments to a map for SEP-9 submission.
  Map<String, Uint8List> files() {
    final files = <String, Uint8List>{};
    if (photoIncorporationDoc != null) {
      files[photo_incorporation_doc_file_key] = photoIncorporationDoc!;
    }
    if (photoProofAddress != null) {
      files[photo_proof_address_file_key] = photoProofAddress!;
    }
    return files;
  }
}

/// Payment card information for KYC verification.
///
/// Contains credit or debit card details for payment processing.
/// All field keys are prefixed with "card."
///
/// Example:
/// ```dart
/// CardKYCFields card = CardKYCFields();
/// card.number = "4111111111111111";
/// card.expirationDate = "29-11"; // YY-MM format (e.g., November 2029)
/// card.cvc = "123";
/// card.holderName = "John Doe";
/// card.network = "Visa";
/// card.postalCode = "12345";
/// card.countryCode = "US";
///
/// // Or use tokenized card
/// card.token = "tok_visa_1234";
/// ```
///
/// Security note:
/// - Consider using tokenized cards when possible
/// - Never log or store full card numbers
/// - Follow PCI DSS compliance requirements
class CardKYCFields {
  // field keys
  static const String key_prefix = 'card.';
  static const String number_field_key = key_prefix + 'number';
  static const String expiration_date_field_key  = key_prefix + 'expiration_date';
  static const String cvc_field_key =
      key_prefix + 'cvc';
  static const String holder_name_field_key =
      key_prefix + 'holder_name';
  static const String network_field_key =
      key_prefix + 'network';
  static const String postal_code_field_key =
      key_prefix + 'postal_code';
  static const String country_code_field_key =
      key_prefix + 'country_code';
  static const String state_or_province_field_key =
      key_prefix + 'state_or_province';
  static const String city_field_key = key_prefix + 'city';
  static const String address_field_key = key_prefix + 'address';
  static const String token_field_key = key_prefix + 'token';

  /// Card number
  String? number;

  /// Expiration month and year in YY-MM format (e.g. 29-11, November 2029)
  String? expirationDate;

  /// CVC number (Digits on the back of the card)
  String? cvc;

  /// Name of the card holder
  String? holderName;

  /// Brand of the card/network it operates within (e.g. Visa, Mastercard, AmEx, etc.)
  String? network;

  /// Billing address postal code
  String? postalCode;

  /// Billing address country code in ISO 3166-1 alpha-2 code (e.g. US)
  String? countryCode;

  /// Name of state/province/region/prefecture is ISO 3166-2 format
  String? stateOrProvince;

  /// Name of city/town
  String? city;

  /// Entire address (country, state, postal code, street address, etc...) as a multi-line string
  String? address;

  /// Token representation of the card in some external payment system (e.g. Stripe)
  String? token;

  /// Converts all card KYC fields to a map for SEP-9 submission.
  Map<String, String> fields() {
    final fields = <String, String>{};
    if (number != null) {
      fields[number_field_key] = number!;
    }
    if (expirationDate != null) {
      fields[expiration_date_field_key] = expirationDate!;
    }
    if (cvc != null) {
      fields[cvc_field_key] = cvc!;
    }
    if (holderName != null) {
      fields[holder_name_field_key] = holderName!;
    }
    if (network != null) {
      fields[network_field_key] = network!;
    }
    if (postalCode != null) {
      fields[postal_code_field_key] = postalCode!;
    }
    if (countryCode != null) {
      fields[country_code_field_key] = countryCode!;
    }
    if (stateOrProvince != null) {
      fields[state_or_province_field_key] = stateOrProvince!;
    }
    if (city != null) {
      fields[city_field_key] = city!;
    }
    if (address != null) {
      fields[address_field_key] = address!;
    }
    if (token != null) {
      fields[token_field_key] = token!;
    }
    return fields;
  }
}