import 'dart:typed_data';

/// Defines a list of standard KYC and AML fields for use in Stellar ecosystem protocols.
/// Issuers, banks, and other entities on Stellar should use these fields when sending
/// or requesting KYC / AML information with other parties on Stellar.
/// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md
class StandardKYCFields {
  NaturalPersonKYCFields naturalPersonKYCFields;
  OrganizationKYCFields organizationKYCFields;
}

class KYCFields {}

class NaturalPersonKYCFields implements KYCFields {
  /// Family or last name
  String lastName;

  /// Given or first name
  String firstName;

  /// Middle name or other additional name
  String additionalName;

  /// country code for current address
  String addressCountryCode;

  /// name of state/province/region/prefecture
  String stateOrProvince;

  /// name of city/town
  String city;

  /// Postal or other code identifying user's locale
  String postalCode;

  /// Entire address (country, state, postal code, street address, etc...) as a multi-line string
  String address;

  /// Mobile phone number with country code, in E.164 format
  String mobileNumber;

  /// Email address
  String emailAddress;

  /// Date of birth, e.g. 1976-07-04
  DateTime birthDate;

  /// Place of birth (city, state, country; as on passport)
  String birthPlace;

  /// ISO Code of country of birth ISO 3166-1 alpha-3
  String birthCountryCode;

  /// Number identifying bank account
  String bankAccountNumber;

  /// Number identifying bank in national banking system (routing number in US)
  String bankNumber;

  /// Phone number with country code for bank
  String bankPhoneNumber;

  /// Number identifying bank branch
  String bankBranchNumber;

  /// Tax identifier of user in their country (social security number in US)
  String taxId;

  /// Name of the tax ID (SSN or ITIN in the US)
  String taxIdName;

  /// Occupation ISCO code.
  int occupation;

  /// Name of employer.
  String employerName;

  /// Address of employer
  String employerAddress;

  /// primary language ISO 639-1
  String languageCode;

  /// passport, drivers_license, id_card, etc...
  String idType;

  /// country issuing passport or photo ID as ISO 3166-1 alpha-3 code
  String idCountryCode;

  /// ID issue date
  DateTime idIssueDate;

  /// ID expiration date
  DateTime idExpirationDate;

  /// Passport or ID number
  String idNumber;

  /// Image of front of user's photo ID or passport
  Uint8List photoIdFront;

  /// 	Image of back of user's photo ID or passport
  Uint8List photoIdBack;

  /// Image of notary's approval of photo ID or passport
  Uint8List notaryApprovalOfPhotoId;

  /// IP address of customer's computer
  String ipAddress;

  /// Image of a utility bill, bank statement or similar with the user's name and address
  Uint8List photoProofResidence;

  /// male, female, or other
  String sex;
}

class OrganizationKYCFields implements KYCFields {
  /// Full organiation name as on the incorporation papers
  String name;

  /// Organization VAT number
  String VATNumber;

  /// Organization registration number
  String registrationNumber;

  /// Organization registered address
  String registeredAddress;

  /// Organization shareholder number
  int numberOfShareholders;

  /// Can be an organization or a person and should be queried recursively up to the ultimate beneficial owners (with KYC information for natural persons such as above)
  //List<KYCFields> shareholderNames;

  /// Image of incorporation documents
  Uint8List photoIncorporationDoc;

  /// Image of a utility bill, bank statement with the organization's name and address
  Uint8List photoProofAddress;

  /// Country code for current address
  String addressCountryCode;

  /// Name of state/province/region/prefecture
  String stateOrProvince;

  /// name of city/town
  String city;

  /// Postal or other code identifying organization's locale
  String postalCode;

  /// Organization registered managing director
  String directorName;

  /// Organization website
  String website;

  /// Organization contact email
  String email;

  ///	Organization contact phone
  String phone;
}