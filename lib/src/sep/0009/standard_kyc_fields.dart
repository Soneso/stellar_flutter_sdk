import 'dart:typed_data';

/// Defines a list of standard KYC and AML fields for use in Stellar ecosystem protocols.
/// Issuers, banks, and other entities on Stellar should use these fields when sending
/// or requesting KYC / AML information with other parties on Stellar.
/// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md
class StandardKYCFields {
  NaturalPersonKYCFields? naturalPersonKYCFields;
  OrganizationKYCFields? organizationKYCFields;
}

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

  /// Email address
  String? emailAddress;

  /// Date of birth, e.g. 1976-07-04
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
  DateTime? idIssueDate;

  /// ID expiration date
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
    if (emailAddress != null) {
      fields[email_address_field_key] = emailAddress!;
    }
    if (birthDate != null) {
      fields[birth_date_field_key] = birthDate!.toIso8601String();
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
      fields[id_issue_date_field_key] = idIssueDate!.toIso8601String();
    }
    if (idExpirationDate != null) {
      fields[id_expiration_date_field_key] =
          idExpirationDate!.toIso8601String();
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
    return fields;
  }

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

class FinancialAccountKYCFields {
  // field keys
  static const String bank_account_type_field_key = 'bank_account_type';
  static const String bank_account_number_field_key = 'bank_account_number';
  static const String bank_number_field_key = 'bank_number';
  static const String bank_phone_number_field_key = 'bank_phone_number';
  static const String bank_branch_number_field_key = 'bank_branch_number';
  static const String clabe_number_field_key = 'clabe_number';
  static const String cbu_number_field_key = 'cbu_number';
  static const String cbu_alias_field_key = 'cbu_alias';
  static const String crypto_address_field_key = 'crypto_address';
  static const String crypto_memo_field_key = 'crypto_memo';

  /// ISO Code of country of birth ISO 3166-1 alpha-3
  String? bankAccountType;

  /// Number identifying bank account
  String? bankAccountNumber;

  /// Number identifying bank in national banking system (routing number in US)
  String? bankNumber;

  /// Phone number with country code for bank
  String? bankPhoneNumber;

  /// Number identifying bank branch
  String? bankBranchNumber;

  /// Bank account number for Mexico
  String? clabeNumber;

  /// Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU).
  String? cbuNumber;

  /// The alias for a Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU).
  String? cbuAlias;

  /// Address for a cryptocurrency account
  String? cryptoAddress;

  /// A destination tag/memo used to identify a transaction
  String? cryptoMemo;

  Map<String, String> fields({String keyPrefix = ''}) {
    final fields = <String, String>{};

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
    if (clabeNumber != null) {
      fields[keyPrefix + clabe_number_field_key] = clabeNumber!;
    }
    if (cbuNumber != null) {
      fields[keyPrefix + cbu_number_field_key] = cbuNumber!;
    }
    if (cbuAlias != null) {
      fields[keyPrefix + cbu_alias_field_key] = cbuAlias!;
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
    return fields;
  }

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
