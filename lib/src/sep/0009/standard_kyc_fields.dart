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

  /// Number identifying bank account
  String? bankAccountNumber;

  /// Number identifying bank in national banking system (routing number in US)
  String? bankNumber;

  /// Phone number with country code for bank
  String? bankPhoneNumber;

  /// Number identifying bank branch
  String? bankBranchNumber;

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

  Map<String, String> fields() {
    final fields = <String, String>{};
    if (lastName != null) {
      fields['last_name'] = lastName!;
    }
    if (firstName != null) {
      fields['first_name'] = firstName!;
    }
    if (additionalName != null) {
      fields['additional_name'] = additionalName!;
    }
    if (addressCountryCode != null) {
      fields['address_country_code'] = addressCountryCode!;
    }
    if (stateOrProvince != null) {
      fields['state_or_province'] = stateOrProvince!;
    }
    if (city != null) {
      fields['city'] = city!;
    }
    if (postalCode != null) {
      fields['postal_code'] = postalCode!;
    }
    if (address != null) {
      fields['address'] = address!;
    }
    if (mobileNumber != null) {
      fields['mobile_number'] = mobileNumber!;
    }
    if (emailAddress != null) {
      fields['email_address'] = emailAddress!;
    }
    if (birthDate != null) {
      fields['birth_date'] = birthDate!.toIso8601String();
    }
    if (birthPlace != null) {
      fields['birth_place'] = birthPlace!;
    }
    if (birthCountryCode != null) {
      fields['birth_country_code'] = birthCountryCode!;
    }
    if (bankAccountNumber != null) {
      fields['bank_account_number'] = bankAccountNumber!;
    }
    if (bankNumber != null) {
      fields['bank_number'] = bankNumber!;
    }
    if (bankPhoneNumber != null) {
      fields['bank_phone_number'] = bankPhoneNumber!;
    }
    if (bankBranchNumber != null) {
      fields['bank_branch_number'] = bankBranchNumber!;
    }
    if (taxId != null) {
      fields['tax_id'] = taxId!;
    }
    if (taxIdName != null) {
      fields['tax_id_name'] = taxIdName!;
    }
    if (occupation != null) {
      fields['occupation'] = occupation.toString();
    }
    if (employerName != null) {
      fields['employer_name'] = employerName!;
    }
    if (employerAddress != null) {
      fields['employer_address'] = employerAddress!;
    }
    if (languageCode != null) {
      fields['language_code'] = languageCode!;
    }
    if (idType != null) {
      fields['id_type'] = idType!;
    }
    if (idCountryCode != null) {
      fields['id_country_code'] = idCountryCode!;
    }
    if (idIssueDate != null) {
      fields['id_issue_date'] = idIssueDate!.toIso8601String();
    }
    if (idExpirationDate != null) {
      fields['id_expiration_date'] = idExpirationDate!.toIso8601String();
    }
    if (idNumber != null) {
      fields['id_number'] = idNumber!;
    }
    if (ipAddress != null) {
      fields['ip_address'] = ipAddress!;
    }
    if (sex != null) {
      fields['sex'] = sex!;
    }
    return fields;
  }

  Map<String, Uint8List> files() {
    final files = <String, Uint8List>{};
    if (photoIdFront != null) {
      files['photo_id_front'] = photoIdFront!;
    }
    if (photoIdBack != null) {
      files['photo_id_back'] = photoIdBack!;
    }
    if (notaryApprovalOfPhotoId != null) {
      files['notary_approval_of_photo_id'] = notaryApprovalOfPhotoId!;
    }
    if (photoProofResidence != null) {
      files['photo_proof_residence'] = photoProofResidence!;
    }
    return files;
  }
}

class OrganizationKYCFields {
  /// Full organization name as on the incorporation papers
  String? name;

  /// Organization VAT number
  String? VATNumber;

  /// Organization registration number
  String? registrationNumber;

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

  Map<String, String>? fields() {
    final fields = <String, String>{};
    if (name != null) {
      fields['organization.name'] = name!;
    }
    if (VATNumber != null) {
      fields['organization.VAT_number'] = VATNumber!;
    }
    if (registrationNumber != null) {
      fields['organization.registration_number'] = registrationNumber!;
    }
    if (registeredAddress != null) {
      fields['organization.registered_address'] = registeredAddress!;
    }
    if (numberOfShareholders != null) {
      fields['organization.number_of_shareholders'] = numberOfShareholders.toString();
    }
    if (shareholderName != null) {
      fields['organization.shareholder_name'] = shareholderName!;
    }
    if (addressCountryCode != null) {
      fields['organization.address_country_code'] = addressCountryCode!;
    }
    if (stateOrProvince != null) {
      fields['organization.state_or_province'] = stateOrProvince!;
    }
    if (city != null) {
      fields['organization.city'] = city!;
    }
    if (postalCode != null) {
      fields['organization.postal_code'] = postalCode!;
    }
    if (directorName != null) {
      fields['organization.director_name'] = directorName!;
    }
    if (website != null) {
      fields['organization.website'] = website!;
    }
    if (email != null) {
      fields['organization.email'] = email!;
    }
    if (phone != null) {
      fields['organization.phone'] = phone!;
    }
  }

  Map<String, Uint8List> files() {
    final files = <String, Uint8List>{};
    if (photoIncorporationDoc != null) {
      files['organization.photo_incorporation_doc'] = photoIncorporationDoc!;
    }
    if (photoProofAddress != null) {
      files['organization.photo_proof_address'] = photoProofAddress!;
    }
    return files;
  }
}
