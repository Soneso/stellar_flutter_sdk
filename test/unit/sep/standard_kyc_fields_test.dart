import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('NaturalPersonKYCFields', () {
    test('sets and gets basic personal information fields', () {
      var kyc = NaturalPersonKYCFields();
      kyc.lastName = 'Doe';
      kyc.firstName = 'John';
      kyc.additionalName = 'Michael';
      kyc.emailAddress = 'john@example.com';

      var fields = kyc.fields();
      expect(fields['last_name'], equals('Doe'));
      expect(fields['first_name'], equals('John'));
      expect(fields['additional_name'], equals('Michael'));
      expect(fields['email_address'], equals('john@example.com'));
    });

    test('sets and gets address fields', () {
      var kyc = NaturalPersonKYCFields();
      kyc.addressCountryCode = 'USA';
      kyc.stateOrProvince = 'California';
      kyc.city = 'San Francisco';
      kyc.postalCode = '94102';
      kyc.address = '123 Main St\nSan Francisco, CA 94102';

      var fields = kyc.fields();
      expect(fields['address_country_code'], equals('USA'));
      expect(fields['state_or_province'], equals('California'));
      expect(fields['city'], equals('San Francisco'));
      expect(fields['postal_code'], equals('94102'));
      expect(fields['address'], equals('123 Main St\nSan Francisco, CA 94102'));
    });

    test('sets and gets mobile number fields', () {
      var kyc = NaturalPersonKYCFields();
      kyc.mobileNumber = '+14155551234';
      kyc.mobileNumberFormat = 'E.164';

      var fields = kyc.fields();
      expect(fields['mobile_number'], equals('+14155551234'));
      expect(fields['mobile_number_format'], equals('E.164'));
    });

    test('sets and gets birth information fields', () {
      var kyc = NaturalPersonKYCFields();
      kyc.birthDate = DateTime(1990, 5, 15);
      kyc.birthPlace = 'New York City';
      kyc.birthCountryCode = 'USA';

      var fields = kyc.fields();
      expect(fields['birth_date'], equals('1990-05-15T00:00:00.000'));
      expect(fields['birth_place'], equals('New York City'));
      expect(fields['birth_country_code'], equals('USA'));
    });

    test('sets and gets tax information fields', () {
      var kyc = NaturalPersonKYCFields();
      kyc.taxId = '123-45-6789';
      kyc.taxIdName = 'SSN';

      var fields = kyc.fields();
      expect(fields['tax_id'], equals('123-45-6789'));
      expect(fields['tax_id_name'], equals('SSN'));
    });

    test('sets and gets occupation and employer fields', () {
      var kyc = NaturalPersonKYCFields();
      kyc.occupation = 2310; // ISCO code for teachers
      kyc.employerName = 'Example Corp';
      kyc.employerAddress = '456 Corporate Blvd';

      var fields = kyc.fields();
      expect(fields['occupation'], equals('2310'));
      expect(fields['employer_name'], equals('Example Corp'));
      expect(fields['employer_address'], equals('456 Corporate Blvd'));
    });

    test('sets and gets language code field', () {
      var kyc = NaturalPersonKYCFields();
      kyc.languageCode = 'en';

      var fields = kyc.fields();
      expect(fields['language_code'], equals('en'));
    });

    test('sets and gets ID document fields', () {
      var kyc = NaturalPersonKYCFields();
      kyc.idType = 'passport';
      kyc.idCountryCode = 'USA';
      kyc.idIssueDate = DateTime(2020, 1, 1);
      kyc.idExpirationDate = DateTime(2030, 1, 1);
      kyc.idNumber = 'P123456789';

      var fields = kyc.fields();
      expect(fields['id_type'], equals('passport'));
      expect(fields['id_country_code'], equals('USA'));
      expect(fields['id_issue_date'], equals('2020-01-01T00:00:00.000'));
      expect(fields['id_expiration_date'], equals('2030-01-01T00:00:00.000'));
      expect(fields['id_number'], equals('P123456789'));
    });

    test('sets and gets IP address field', () {
      var kyc = NaturalPersonKYCFields();
      kyc.ipAddress = '192.168.1.1';

      var fields = kyc.fields();
      expect(fields['ip_address'], equals('192.168.1.1'));
    });

    test('sets and gets sex field', () {
      var kyc = NaturalPersonKYCFields();
      kyc.sex = 'male';

      var fields = kyc.fields();
      expect(fields['sex'], equals('male'));
    });

    test('sets and gets referral ID field', () {
      var kyc = NaturalPersonKYCFields();
      kyc.referralId = 'REF123456';

      var fields = kyc.fields();
      expect(fields['referral_id'], equals('REF123456'));
    });

    test('returns empty map when no fields are set', () {
      var kyc = NaturalPersonKYCFields();
      var fields = kyc.fields();
      expect(fields, isEmpty);
    });

    test('handles file attachments for photo ID front', () {
      var kyc = NaturalPersonKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.photoIdFront = imageData;

      var files = kyc.files();
      expect(files['photo_id_front'], equals(imageData));
    });

    test('handles file attachments for photo ID back', () {
      var kyc = NaturalPersonKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.photoIdBack = imageData;

      var files = kyc.files();
      expect(files['photo_id_back'], equals(imageData));
    });

    test('handles file attachments for notary approval', () {
      var kyc = NaturalPersonKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.notaryApprovalOfPhotoId = imageData;

      var files = kyc.files();
      expect(files['notary_approval_of_photo_id'], equals(imageData));
    });

    test('handles file attachments for proof of residence', () {
      var kyc = NaturalPersonKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.photoProofResidence = imageData;

      var files = kyc.files();
      expect(files['photo_proof_residence'], equals(imageData));
    });

    test('handles file attachments for proof of income', () {
      var kyc = NaturalPersonKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.proofOfIncome = imageData;

      var files = kyc.files();
      expect(files['proof_of_income'], equals(imageData));
    });

    test('handles file attachments for proof of liveness', () {
      var kyc = NaturalPersonKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.proofOfLiveness = imageData;

      var files = kyc.files();
      expect(files['proof_of_liveness'], equals(imageData));
    });

    test('returns empty map when no files are set', () {
      var kyc = NaturalPersonKYCFields();
      var files = kyc.files();
      expect(files, isEmpty);
    });

    test('includes financial account fields when set', () {
      var kyc = NaturalPersonKYCFields();
      kyc.firstName = 'John';

      var financialAccount = FinancialAccountKYCFields();
      financialAccount.bankName = 'Test Bank';
      financialAccount.bankAccountNumber = '123456789';
      kyc.financialAccountKYCFields = financialAccount;

      var fields = kyc.fields();
      expect(fields['first_name'], equals('John'));
      expect(fields['bank_name'], equals('Test Bank'));
      expect(fields['bank_account_number'], equals('123456789'));
    });

    test('includes card fields when set', () {
      var kyc = NaturalPersonKYCFields();
      kyc.firstName = 'John';

      var card = CardKYCFields();
      card.number = '4111111111111111';
      card.holderName = 'John Doe';
      kyc.cardKYCFields = card;

      var fields = kyc.fields();
      expect(fields['first_name'], equals('John'));
      expect(fields['card.number'], equals('4111111111111111'));
      expect(fields['card.holder_name'], equals('John Doe'));
    });
  });

  group('OrganizationKYCFields', () {
    test('sets and gets basic organization fields', () {
      var kyc = OrganizationKYCFields();
      kyc.name = 'Example Corp';
      kyc.VATNumber = 'VAT123456789';
      kyc.registrationNumber = 'REG987654321';
      kyc.registrationDate = '2020-01-15';

      var fields = kyc.fields();
      expect(fields['organization.name'], equals('Example Corp'));
      expect(fields['organization.VAT_number'], equals('VAT123456789'));
      expect(fields['organization.registration_number'], equals('REG987654321'));
      expect(fields['organization.registration_date'], equals('2020-01-15'));
    });

    test('sets and gets registered address field', () {
      var kyc = OrganizationKYCFields();
      kyc.registeredAddress = '123 Business Plaza\nNew York, NY 10001';

      var fields = kyc.fields();
      expect(fields['organization.registered_address'], equals('123 Business Plaza\nNew York, NY 10001'));
    });

    test('sets and gets shareholder information', () {
      var kyc = OrganizationKYCFields();
      kyc.numberOfShareholders = 5;
      kyc.shareholderName = 'Jane Smith';

      var fields = kyc.fields();
      expect(fields['organization.number_of_shareholders'], equals('5'));
      expect(fields['organization.shareholder_name'], equals('Jane Smith'));
    });

    test('sets and gets address fields', () {
      var kyc = OrganizationKYCFields();
      kyc.addressCountryCode = 'USA';
      kyc.stateOrProvince = 'New York';
      kyc.city = 'New York City';
      kyc.postalCode = '10001';

      var fields = kyc.fields();
      expect(fields['organization.address_country_code'], equals('USA'));
      expect(fields['organization.state_or_province'], equals('New York'));
      expect(fields['organization.city'], equals('New York City'));
      expect(fields['organization.postal_code'], equals('10001'));
    });

    test('sets and gets director name field', () {
      var kyc = OrganizationKYCFields();
      kyc.directorName = 'Robert Johnson';

      var fields = kyc.fields();
      expect(fields['organization.director_name'], equals('Robert Johnson'));
    });

    test('sets and gets contact information fields', () {
      var kyc = OrganizationKYCFields();
      kyc.website = 'https://example.com';
      kyc.email = 'contact@example.com';
      kyc.phone = '+14155551234';

      var fields = kyc.fields();
      expect(fields['organization.website'], equals('https://example.com'));
      expect(fields['organization.email'], equals('contact@example.com'));
      expect(fields['organization.phone'], equals('+14155551234'));
    });

    test('returns empty map when no fields are set', () {
      var kyc = OrganizationKYCFields();
      var fields = kyc.fields();
      expect(fields, isEmpty);
    });

    test('handles file attachment for incorporation documents', () {
      var kyc = OrganizationKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.photoIncorporationDoc = imageData;

      var files = kyc.files();
      expect(files['organization.photo_incorporation_doc'], equals(imageData));
    });

    test('handles file attachment for proof of address', () {
      var kyc = OrganizationKYCFields();
      var imageData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      kyc.photoProofAddress = imageData;

      var files = kyc.files();
      expect(files['organization.photo_proof_address'], equals(imageData));
    });

    test('returns empty map when no files are set', () {
      var kyc = OrganizationKYCFields();
      var files = kyc.files();
      expect(files, isEmpty);
    });

    test('includes financial account fields with organization prefix', () {
      var kyc = OrganizationKYCFields();
      kyc.name = 'Example Corp';

      var financialAccount = FinancialAccountKYCFields();
      financialAccount.bankName = 'Corporate Bank';
      financialAccount.bankAccountNumber = '987654321';
      kyc.financialAccountKYCFields = financialAccount;

      var fields = kyc.fields();
      expect(fields['organization.name'], equals('Example Corp'));
      expect(fields['organization.bank_name'], equals('Corporate Bank'));
      expect(fields['organization.bank_account_number'], equals('987654321'));
    });

    test('includes card fields when set', () {
      var kyc = OrganizationKYCFields();
      kyc.name = 'Example Corp';

      var card = CardKYCFields();
      card.number = '5555555555554444';
      card.holderName = 'Example Corp';
      kyc.cardKYCFields = card;

      var fields = kyc.fields();
      expect(fields['organization.name'], equals('Example Corp'));
      expect(fields['card.number'], equals('5555555555554444'));
      expect(fields['card.holder_name'], equals('Example Corp'));
    });
  });

  group('FinancialAccountKYCFields', () {
    test('sets and gets bank account fields', () {
      var kyc = FinancialAccountKYCFields();
      kyc.bankName = 'Test Bank';
      kyc.bankAccountType = 'checking';
      kyc.bankAccountNumber = '1234567890';
      kyc.bankNumber = '987654321';

      var fields = kyc.fields();
      expect(fields['bank_name'], equals('Test Bank'));
      expect(fields['bank_account_type'], equals('checking'));
      expect(fields['bank_account_number'], equals('1234567890'));
      expect(fields['bank_number'], equals('987654321'));
    });

    test('sets and gets bank phone and branch fields', () {
      var kyc = FinancialAccountKYCFields();
      kyc.bankPhoneNumber = '+14155551234';
      kyc.bankBranchNumber = '001';

      var fields = kyc.fields();
      expect(fields['bank_phone_number'], equals('+14155551234'));
      expect(fields['bank_branch_number'], equals('001'));
    });

    test('sets and gets external transfer memo field', () {
      var kyc = FinancialAccountKYCFields();
      kyc.externalTransferMemo = 'MEMO123456';

      var fields = kyc.fields();
      expect(fields['external_transfer_memo'], equals('MEMO123456'));
    });

    test('sets and gets CLABE and CBU fields', () {
      var kyc = FinancialAccountKYCFields();
      kyc.clabeNumber = '123456789012345678';
      kyc.cbuNumber = '0123456789012345678901';
      kyc.cbuAlias = 'alias.cbu';

      var fields = kyc.fields();
      expect(fields['clabe_number'], equals('123456789012345678'));
      expect(fields['cbu_number'], equals('0123456789012345678901'));
      expect(fields['cbu_alias'], equals('alias.cbu'));
    });

    test('sets and gets mobile money fields', () {
      var kyc = FinancialAccountKYCFields();
      kyc.mobileMoneyNumber = '+254712345678';
      kyc.mobileMoneyProvider = 'M-Pesa';

      var fields = kyc.fields();
      expect(fields['mobile_money_number'], equals('+254712345678'));
      expect(fields['mobile_money_provider'], equals('M-Pesa'));
    });

    test('sets and gets crypto fields', () {
      var kyc = FinancialAccountKYCFields();
      kyc.cryptoAddress = 'GDJKZLTXCKVQYIGJQIYSNFJ3CEKIIZ6HIAZEDE2KBPCSEPBVH4GNDLTJ';
      kyc.cryptoMemo = '12345';

      var fields = kyc.fields();
      expect(fields['crypto_address'], equals('GDJKZLTXCKVQYIGJQIYSNFJ3CEKIIZ6HIAZEDE2KBPCSEPBVH4GNDLTJ'));
      expect(fields['crypto_memo'], equals('12345'));
    });

    test('returns empty map when no fields are set', () {
      var kyc = FinancialAccountKYCFields();
      var fields = kyc.fields();
      expect(fields, isEmpty);
    });

    test('applies key prefix when provided', () {
      var kyc = FinancialAccountKYCFields();
      kyc.bankName = 'Test Bank';
      kyc.bankAccountNumber = '1234567890';

      var fields = kyc.fields(keyPrefix: 'organization.');
      expect(fields['organization.bank_name'], equals('Test Bank'));
      expect(fields['organization.bank_account_number'], equals('1234567890'));
    });
  });

  group('CardKYCFields', () {
    test('sets and gets basic card fields', () {
      var kyc = CardKYCFields();
      kyc.number = '4111111111111111';
      kyc.expirationDate = '29-11';
      kyc.cvc = '123';
      kyc.holderName = 'John Doe';

      var fields = kyc.fields();
      expect(fields['card.number'], equals('4111111111111111'));
      expect(fields['card.expiration_date'], equals('29-11'));
      expect(fields['card.cvc'], equals('123'));
      expect(fields['card.holder_name'], equals('John Doe'));
    });

    test('sets and gets network field', () {
      var kyc = CardKYCFields();
      kyc.network = 'Visa';

      var fields = kyc.fields();
      expect(fields['card.network'], equals('Visa'));
    });

    test('sets and gets billing address fields', () {
      var kyc = CardKYCFields();
      kyc.postalCode = '94102';
      kyc.countryCode = 'US';
      kyc.stateOrProvince = 'CA';
      kyc.city = 'San Francisco';
      kyc.address = '123 Main St\nSan Francisco, CA 94102';

      var fields = kyc.fields();
      expect(fields['card.postal_code'], equals('94102'));
      expect(fields['card.country_code'], equals('US'));
      expect(fields['card.state_or_province'], equals('CA'));
      expect(fields['card.city'], equals('San Francisco'));
      expect(fields['card.address'], equals('123 Main St\nSan Francisco, CA 94102'));
    });

    test('sets and gets token field', () {
      var kyc = CardKYCFields();
      kyc.token = 'tok_visa_1234';

      var fields = kyc.fields();
      expect(fields['card.token'], equals('tok_visa_1234'));
    });

    test('returns empty map when no fields are set', () {
      var kyc = CardKYCFields();
      var fields = kyc.fields();
      expect(fields, isEmpty);
    });
  });

  group('StandardKYCFields', () {
    test('can hold natural person fields', () {
      var standardKYC = StandardKYCFields();
      var person = NaturalPersonKYCFields();
      person.firstName = 'John';
      person.lastName = 'Doe';

      standardKYC.naturalPersonKYCFields = person;

      expect(standardKYC.naturalPersonKYCFields, isNotNull);
      expect(standardKYC.naturalPersonKYCFields!.firstName, equals('John'));
      expect(standardKYC.naturalPersonKYCFields!.lastName, equals('Doe'));
    });

    test('can hold organization fields', () {
      var standardKYC = StandardKYCFields();
      var org = OrganizationKYCFields();
      org.name = 'Example Corp';
      org.VATNumber = 'VAT123';

      standardKYC.organizationKYCFields = org;

      expect(standardKYC.organizationKYCFields, isNotNull);
      expect(standardKYC.organizationKYCFields!.name, equals('Example Corp'));
      expect(standardKYC.organizationKYCFields!.VATNumber, equals('VAT123'));
    });

    test('can hold both natural person and organization fields', () {
      var standardKYC = StandardKYCFields();

      var person = NaturalPersonKYCFields();
      person.firstName = 'John';
      standardKYC.naturalPersonKYCFields = person;

      var org = OrganizationKYCFields();
      org.name = 'Example Corp';
      standardKYC.organizationKYCFields = org;

      expect(standardKYC.naturalPersonKYCFields, isNotNull);
      expect(standardKYC.organizationKYCFields, isNotNull);
    });
  });
}
