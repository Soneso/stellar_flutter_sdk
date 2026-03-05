@Timeout(const Duration(seconds: 300))

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('sep-09: Quick Example', () {
    // Snippet from sep-09.md "Quick Example"
    NaturalPersonKYCFields person = NaturalPersonKYCFields();
    person.firstName = 'John';
    person.lastName = 'Doe';
    person.emailAddress = 'john@example.com';
    person.birthDate = DateTime(1990, 5, 15);

    StandardKYCFields kyc = StandardKYCFields();
    kyc.naturalPersonKYCFields = person;

    Map<String, String> fields = person.fields();

    expect(fields['first_name'], 'John');
    expect(fields['last_name'], 'Doe');
    expect(fields['email_address'], 'john@example.com');
    expect(fields['birth_date'], '1990-05-15');
    expect(kyc.naturalPersonKYCFields, isNotNull);
  });

  test('sep-09: Natural Person Fields', () {
    // Snippet from sep-09.md "Natural Person Fields"
    NaturalPersonKYCFields person = NaturalPersonKYCFields();

    // Personal identification
    person.firstName = 'Maria';
    person.lastName = 'Garcia';
    person.additionalName = 'Elena';
    person.birthDate = DateTime(1985, 3, 20);
    person.birthPlace = 'Madrid, Spain';
    person.birthCountryCode = 'ESP';
    person.sex = 'female';

    // Contact information
    person.emailAddress = 'maria@example.com';
    person.mobileNumber = '+34612345678';
    person.mobileNumberFormat = 'E.164';

    // Current address
    person.addressCountryCode = 'ESP';
    person.stateOrProvince = 'Madrid';
    person.city = 'Madrid';
    person.postalCode = '28001';
    person.address = 'Calle Mayor 10\n28001 Madrid\nSpain';

    // Employment
    person.occupation = 2511;
    person.employerName = 'Tech Corp';
    person.employerAddress = 'Paseo de la Castellana 50, Madrid';

    // Tax information
    person.taxId = '12345678Z';
    person.taxIdName = 'NIF';

    // Identity document
    person.idType = 'passport';
    person.idNumber = 'AB1234567';
    person.idCountryCode = 'ESP';
    person.idIssueDate = DateTime(2020, 1, 15);
    person.idExpirationDate = DateTime(2030, 1, 14);

    // Other
    person.languageCode = 'es';
    person.ipAddress = '192.168.1.1';
    person.referralId = 'partner-12345';

    Map<String, String> fieldData = person.fields();

    expect(fieldData['first_name'], 'Maria');
    expect(fieldData['last_name'], 'Garcia');
    expect(fieldData['additional_name'], 'Elena');
    expect(fieldData['birth_date'], '1985-03-20');
    expect(fieldData['birth_place'], 'Madrid, Spain');
    expect(fieldData['birth_country_code'], 'ESP');
    expect(fieldData['sex'], 'female');
    expect(fieldData['email_address'], 'maria@example.com');
    expect(fieldData['mobile_number'], '+34612345678');
    expect(fieldData['mobile_number_format'], 'E.164');
    expect(fieldData['address_country_code'], 'ESP');
    expect(fieldData['state_or_province'], 'Madrid');
    expect(fieldData['city'], 'Madrid');
    expect(fieldData['postal_code'], '28001');
    expect(fieldData['address'], contains('Calle Mayor'));
    expect(fieldData['occupation'], '2511');
    expect(fieldData['employer_name'], 'Tech Corp');
    expect(fieldData['employer_address'], contains('Castellana'));
    expect(fieldData['tax_id'], '12345678Z');
    expect(fieldData['tax_id_name'], 'NIF');
    expect(fieldData['id_type'], 'passport');
    expect(fieldData['id_number'], 'AB1234567');
    expect(fieldData['id_country_code'], 'ESP');
    expect(fieldData['id_issue_date'], '2020-01-15');
    expect(fieldData['id_expiration_date'], '2030-01-14');
    expect(fieldData['language_code'], 'es');
    expect(fieldData['ip_address'], '192.168.1.1');
    expect(fieldData['referral_id'], 'partner-12345');
  });

  test('sep-09: Document Uploads', () {
    // Snippet from sep-09.md "Document Uploads"
    NaturalPersonKYCFields person = NaturalPersonKYCFields();
    person.firstName = 'John';
    person.lastName = 'Doe';

    // Use synthetic bytes instead of reading real files
    person.photoIdFront = Uint8List.fromList([1, 2, 3]);
    person.photoIdBack = Uint8List.fromList([4, 5, 6]);
    person.notaryApprovalOfPhotoId = Uint8List.fromList([7, 8, 9]);
    person.photoProofResidence = Uint8List.fromList([10, 11, 12]);
    person.proofOfIncome = Uint8List.fromList([13, 14, 15]);
    person.proofOfLiveness = Uint8List.fromList([16, 17, 18]);

    Map<String, String> textFields = person.fields();
    Map<String, Uint8List> fileFields = person.files();

    expect(textFields['first_name'], 'John');
    expect(textFields['last_name'], 'Doe');
    // Text fields should not contain file keys
    expect(textFields.containsKey('photo_id_front'), false);

    expect(fileFields['photo_id_front'], isNotNull);
    expect(fileFields['photo_id_back'], isNotNull);
    expect(fileFields['notary_approval_of_photo_id'], isNotNull);
    expect(fileFields['photo_proof_residence'], isNotNull);
    expect(fileFields['proof_of_income'], isNotNull);
    expect(fileFields['proof_of_liveness'], isNotNull);
    expect(fileFields.length, 6);
  });

  test('sep-09: Organization Fields', () {
    // Snippet from sep-09.md "Organization Fields"
    OrganizationKYCFields org = OrganizationKYCFields();

    org.name = 'Acme Corporation S.L.';
    org.VATNumber = 'ESB12345678';
    org.registrationNumber = 'B-12345678';
    org.registrationDate = '2015-06-01';
    org.registeredAddress = 'Calle Gran Via 100, 28013 Madrid, Spain';
    org.numberOfShareholders = 3;
    org.shareholderName = 'John Smith';
    org.directorName = 'Jane Doe';
    org.addressCountryCode = 'ESP';
    org.stateOrProvince = 'Madrid';
    org.city = 'Madrid';
    org.postalCode = '28013';
    org.website = 'https://acme-corp.example.com';
    org.email = 'compliance@acme-corp.example.com';
    org.phone = '+34911234567';

    StandardKYCFields kyc = StandardKYCFields();
    kyc.organizationKYCFields = org;

    Map<String, String> fieldData = org.fields();

    expect(fieldData['organization.name'], 'Acme Corporation S.L.');
    expect(fieldData['organization.VAT_number'], 'ESB12345678');
    expect(fieldData['organization.registration_number'], 'B-12345678');
    expect(fieldData['organization.registration_date'], '2015-06-01');
    expect(fieldData['organization.registered_address'], contains('Gran Via'));
    expect(fieldData['organization.number_of_shareholders'], '3');
    expect(fieldData['organization.shareholder_name'], 'John Smith');
    expect(fieldData['organization.director_name'], 'Jane Doe');
    expect(fieldData['organization.address_country_code'], 'ESP');
    expect(fieldData['organization.state_or_province'], 'Madrid');
    expect(fieldData['organization.city'], 'Madrid');
    expect(fieldData['organization.postal_code'], '28013');
    expect(fieldData['organization.website'], 'https://acme-corp.example.com');
    expect(fieldData['organization.email'], 'compliance@acme-corp.example.com');
    expect(fieldData['organization.phone'], '+34911234567');
  });

  test('sep-09: Organization Document Uploads', () {
    // Snippet from sep-09.md "Organization Documents"
    OrganizationKYCFields org = OrganizationKYCFields();
    org.name = 'Acme Corporation S.L.';

    org.photoIncorporationDoc = Uint8List.fromList([1, 2, 3]);
    org.photoProofAddress = Uint8List.fromList([4, 5, 6]);

    Map<String, String> textFields = org.fields();
    Map<String, Uint8List> fileFields = org.files();

    expect(textFields['organization.name'], 'Acme Corporation S.L.');
    expect(fileFields['organization.photo_incorporation_doc'], isNotNull);
    expect(fileFields['organization.photo_proof_address'], isNotNull);
    expect(fileFields.length, 2);
  });

  test('sep-09: Financial Account Fields', () {
    // Snippet from sep-09.md "Financial Account Fields"
    NaturalPersonKYCFields person = NaturalPersonKYCFields();
    person.firstName = 'John';
    person.lastName = 'Doe';

    FinancialAccountKYCFields bankAccount = FinancialAccountKYCFields();
    bankAccount.bankName = 'First National Bank';
    bankAccount.bankAccountType = 'checking';
    bankAccount.bankAccountNumber = '123456789012';
    bankAccount.bankNumber = '021000021';
    bankAccount.bankBranchNumber = '001';
    bankAccount.bankPhoneNumber = '+12025551234';
    bankAccount.clabeNumber = '012345678901234567';
    bankAccount.cbuNumber = '0123456789012345678901';
    bankAccount.cbuAlias = 'john.doe.acme';
    bankAccount.mobileMoneyNumber = '+254712345678';
    bankAccount.mobileMoneyProvider = 'M-Pesa';
    bankAccount.cryptoAddress =
        'GBH4TZYZ4IRCPO44CBOLFUHULU2WGALXTAVESQA6432MBJMABBB4GIYI';
    bankAccount.externalTransferMemo = 'user-12345';

    person.financialAccountKYCFields = bankAccount;

    Map<String, String> allFields = person.fields();

    expect(allFields['first_name'], 'John');
    expect(allFields['bank_name'], 'First National Bank');
    expect(allFields['bank_account_type'], 'checking');
    expect(allFields['bank_account_number'], '123456789012');
    expect(allFields['bank_number'], '021000021');
    expect(allFields['bank_branch_number'], '001');
    expect(allFields['bank_phone_number'], '+12025551234');
    expect(allFields['clabe_number'], '012345678901234567');
    expect(allFields['cbu_number'], '0123456789012345678901');
    expect(allFields['cbu_alias'], 'john.doe.acme');
    expect(allFields['mobile_money_number'], '+254712345678');
    expect(allFields['mobile_money_provider'], 'M-Pesa');
    expect(allFields['crypto_address'],
        'GBH4TZYZ4IRCPO44CBOLFUHULU2WGALXTAVESQA6432MBJMABBB4GIYI');
    expect(allFields['external_transfer_memo'], 'user-12345');
  });

  test('sep-09: Card Fields', () {
    // Snippet from sep-09.md "Card Fields"
    NaturalPersonKYCFields person = NaturalPersonKYCFields();
    person.firstName = 'John';
    person.lastName = 'Doe';

    CardKYCFields card = CardKYCFields();
    card.number = '4111111111111111';
    card.expirationDate = '29-11';
    card.cvc = '123';
    card.holderName = 'JOHN DOE';
    card.network = 'Visa';
    card.address = '123 Main St\nApt 4B';
    card.city = 'New York';
    card.stateOrProvince = 'NY';
    card.postalCode = '10001';
    card.countryCode = 'US';
    card.token = 'tok_visa_4242';

    person.cardKYCFields = card;

    Map<String, String> allFields = person.fields();

    expect(allFields['first_name'], 'John');
    expect(allFields['card.number'], '4111111111111111');
    expect(allFields['card.expiration_date'], '29-11');
    expect(allFields['card.cvc'], '123');
    expect(allFields['card.holder_name'], 'JOHN DOE');
    expect(allFields['card.network'], 'Visa');
    expect(allFields['card.address'], contains('Main St'));
    expect(allFields['card.city'], 'New York');
    expect(allFields['card.state_or_province'], 'NY');
    expect(allFields['card.postal_code'], '10001');
    expect(allFields['card.country_code'], 'US');
    expect(allFields['card.token'], 'tok_visa_4242');
  });

  test('sep-09: Combining with Organizations', () {
    // Snippet from sep-09.md "Combining with Organizations"
    OrganizationKYCFields org = OrganizationKYCFields();
    org.name = 'Acme Corp';
    org.VATNumber = 'US12-3456789';

    FinancialAccountKYCFields bankAccount = FinancialAccountKYCFields();
    bankAccount.bankName = 'Business Bank';
    bankAccount.bankAccountNumber = '9876543210';
    bankAccount.bankNumber = '021000021';

    org.financialAccountKYCFields = bankAccount;

    Map<String, String> fields = org.fields();

    expect(fields['organization.name'], 'Acme Corp');
    expect(fields['organization.VAT_number'], 'US12-3456789');
    expect(fields['organization.bank_name'], 'Business Bank');
    expect(fields['organization.bank_account_number'], '9876543210');
    expect(fields['organization.bank_number'], '021000021');
  });

  test('sep-09: Field Key Constants', () {
    // Snippet from sep-09.md "Using Field Key Constants"

    // Natural person field keys
    expect(NaturalPersonKYCFields.first_name_field_key, 'first_name');
    expect(NaturalPersonKYCFields.last_name_field_key, 'last_name');
    expect(NaturalPersonKYCFields.email_address_field_key, 'email_address');
    expect(NaturalPersonKYCFields.birth_date_field_key, 'birth_date');
    expect(NaturalPersonKYCFields.mobile_number_format_field_key,
        'mobile_number_format');
    expect(
        NaturalPersonKYCFields.photo_id_front_file_key, 'photo_id_front');
    expect(NaturalPersonKYCFields.referral_id_field_key, 'referral_id');

    // Organization field keys (includes prefix)
    expect(OrganizationKYCFields.key_prefix, 'organization.');
    expect(OrganizationKYCFields.name_field_key, 'organization.name');
    expect(OrganizationKYCFields.VAT_number_field_key,
        'organization.VAT_number');
    expect(OrganizationKYCFields.registration_number_field_key,
        'organization.registration_number');

    // Financial account field keys
    expect(FinancialAccountKYCFields.bank_name_field_key, 'bank_name');
    expect(FinancialAccountKYCFields.bank_account_type_field_key,
        'bank_account_type');
    expect(FinancialAccountKYCFields.clabe_number_field_key, 'clabe_number');
    expect(FinancialAccountKYCFields.cbu_number_field_key, 'cbu_number');
    expect(FinancialAccountKYCFields.mobile_money_number_field_key,
        'mobile_money_number');
    expect(FinancialAccountKYCFields.external_transfer_memo_field_key,
        'external_transfer_memo');
    expect(
        FinancialAccountKYCFields.crypto_address_field_key, 'crypto_address');

    // Card field keys (includes prefix)
    expect(CardKYCFields.number_field_key, 'card.number');
    expect(CardKYCFields.expiration_date_field_key, 'card.expiration_date');
    expect(CardKYCFields.token_field_key, 'card.token');
    expect(CardKYCFields.holder_name_field_key, 'card.holder_name');
  });

  test('sep-09: StandardKYCFields container', () {
    // Verify container holds both natural person and organization
    StandardKYCFields kyc = StandardKYCFields();

    NaturalPersonKYCFields person = NaturalPersonKYCFields();
    person.firstName = 'John';

    OrganizationKYCFields org = OrganizationKYCFields();
    org.name = 'Acme Corp';

    kyc.naturalPersonKYCFields = person;
    kyc.organizationKYCFields = org;

    expect(kyc.naturalPersonKYCFields, isNotNull);
    expect(kyc.organizationKYCFields, isNotNull);
    expect(kyc.naturalPersonKYCFields!.fields()['first_name'], 'John');
    expect(
        kyc.organizationKYCFields!.fields()['organization.name'], 'Acme Corp');
  });

  test('sep-09: Organization card fields do not get org prefix', () {
    // Verify card fields nested under org keep 'card.' prefix (not 'organization.card.')
    OrganizationKYCFields org = OrganizationKYCFields();
    org.name = 'Acme Corp';

    CardKYCFields card = CardKYCFields();
    card.number = '4111111111111111';
    org.cardKYCFields = card;

    Map<String, String> fields = org.fields();

    expect(fields['organization.name'], 'Acme Corp');
    expect(fields['card.number'], '4111111111111111');
    // Should NOT have organization.card.number
    expect(fields.containsKey('organization.card.number'), false);
  });

  test('sep-09: FinancialAccountKYCFields keyPrefix parameter', () {
    // Verify the named keyPrefix parameter works
    FinancialAccountKYCFields fin = FinancialAccountKYCFields();
    fin.bankName = 'Chase';

    // No prefix
    Map<String, String> fields = fin.fields();
    expect(fields['bank_name'], 'Chase');

    // With organization prefix
    Map<String, String> orgFields = fin.fields(keyPrefix: 'organization.');
    expect(orgFields['organization.bank_name'], 'Chase');
    expect(orgFields.containsKey('bank_name'), false);
  });
}
