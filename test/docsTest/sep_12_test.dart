@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final serviceAddress = 'http://api.stellar.org/kyc';
  final jwtToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0';
  final customerId = 'd1ce2f48-3ff1-495d-9240-7a50d806cfed';
  final accountId = 'GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP';

  String responseGetCustomerAccepted() {
    return '{"id": "$customerId","status": "ACCEPTED","provided_fields": {'
        '"first_name": {"description": "The customer\'s first name","type": "string","status": "ACCEPTED"},'
        '"last_name": {"description": "The customer\'s last name","type": "string","status": "ACCEPTED"},'
        '"email_address": {"description": "The customer\'s email address","type": "string","status": "ACCEPTED"}}}';
  }

  String responseGetCustomerNeedsInfo() {
    return '{"id": "$customerId","status": "NEEDS_INFO","fields": {'
        '"mobile_number": {"description": "phone number of the customer","type": "string"},'
        '"email_address": {"description": "email address of the customer","type": "string","optional": true}},'
        '"provided_fields": {'
        '"first_name": {"description": "The customer\'s first name","type": "string","status": "ACCEPTED"},'
        '"last_name": {"description": "The customer\'s last name","type": "string","status": "ACCEPTED"}}}';
  }

  String responseGetCustomerRequiresInfo() {
    return '{"status": "NEEDS_INFO","fields": {'
        '"email_address": {"description": "Email address of the customer","type": "string","optional": true},'
        '"id_type": {"description": "Government issued ID","type": "string","choices": ["Passport","Drivers License","State ID"]},'
        '"photo_id_front": {"description": "A clear photo of the front of the government issued ID","type": "binary"}}}';
  }

  String responseGetCustomerProcessing() {
    return '{"id": "$customerId","status": "PROCESSING",'
        '"message": "Photo ID requires manual review. This process typically takes 1-2 business days.",'
        '"provided_fields": {"photo_id_front": {"description": "A clear photo of the front of the government issued ID","type": "binary","status": "PROCESSING"}}}';
  }

  String responseGetCustomerRejected() {
    return '{"id": "$customerId","status": "REJECTED","message": "This person is on a sanctions list"}';
  }

  String responseGetCustomerVerificationRequired() {
    return '{"id": "$customerId","status": "NEEDS_INFO","provided_fields": {'
        '"mobile_number": {"description": "phone number of the customer","type": "string","status": "VERIFICATION_REQUIRED"}}}';
  }

  String responsePutCustomerInfo() {
    return '{"id": "$customerId"}';
  }

  String responsePutCustomerVerification() {
    return '{"id": "$customerId","status": "ACCEPTED","provided_fields": {'
        '"mobile_number": {"description": "phone number of the customer","type": "string","status": "ACCEPTED"}}}';
  }

  String responsePostCustomerFile() {
    return '{"file_id": "file_d3d54529-6683-4341-9b66-4ac7d7504238",'
        '"content_type": "image/jpeg","size": 4089371,'
        '"customer_id": "2bf95490-db23-442d-a1bd-c6fd5efb584e"}';
  }

  String responseGetCustomerFiles() {
    return '{"files": [{"file_id": "file_d5c67b4c-173c-428c-baab-944f4b89a57f",'
        '"content_type": "image/png","size": 6134063,'
        '"customer_id": "2bf95490-db23-442d-a1bd-c6fd5efb584e"},'
        '{"file_id": "file_d3d54529-6683-4341-9b66-4ac7d7504238",'
        '"content_type": "image/jpeg","size": 4089371,'
        '"customer_id": "2bf95490-db23-442d-a1bd-c6fd5efb584e"}]}';
  }

  Uint8List randomBytes(int length) {
    final random = Random();
    final ret = Uint8List(length);
    for (var i = 0; i < length; i++) {
      ret[i] = random.nextInt(256);
    }
    return ret;
  }

  MockClient mockGetCustomer(String responseBody) {
    return MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == 'GET' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken)) {
        return http.Response(responseBody, 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });
  }

  // -- Quick example --
  test('sep-12: Quick example - create service, check status, submit info', () async {
    // Snippet from sep-12.md "Quick example"
    final kycService = KYCService(serviceAddress);

    // Mock GET /customer to return NEEDS_INFO
    kycService.httpClient = mockGetCustomer(responseGetCustomerRequiresInfo());

    final request = GetCustomerInfoRequest();
    request.jwt = jwtToken;
    final response = await kycService.getCustomerInfo(request);

    expect(response.status, 'NEEDS_INFO');

    // Mock PUT /customer to return customer ID
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken)) {
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final personFields = NaturalPersonKYCFields();
    personFields.firstName = 'Jane';
    personFields.lastName = 'Doe';
    personFields.emailAddress = 'jane@example.com';

    final kycFields = StandardKYCFields();
    kycFields.naturalPersonKYCFields = personFields;

    final putRequest = PutCustomerInfoRequest();
    putRequest.jwt = jwtToken;
    putRequest.kycFields = kycFields;

    final putResponse = await kycService.putCustomerInfo(putRequest);
    expect(putResponse.id, customerId);
  });

  // -- Creating the KYC service --
  test('sep-12: Creating the KYC service from direct URL', () {
    // Snippet from sep-12.md "From Direct URL"
    final kycService = KYCService('https://api.anchor.com/kyc');
    expect(kycService, isNotNull);
  });

  // -- Checking customer status: ACCEPTED --
  test('sep-12: Checking customer status - ACCEPTED', () async {
    // Snippet from sep-12.md "Checking customer status"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = mockGetCustomer(responseGetCustomerAccepted());

    final request = GetCustomerInfoRequest();
    request.jwt = jwtToken;
    request.id = customerId;

    final response = await kycService.getCustomerInfo(request);

    expect(response.status, 'ACCEPTED');
    expect(response.id, customerId);
    expect(response.providedFields, isNotNull);
    expect(response.providedFields!.length, 3);

    final firstName = response.providedFields!['first_name'];
    expect(firstName, isNotNull);
    expect(firstName!.status, 'ACCEPTED');
    expect(firstName.type, 'string');
  });

  // -- Checking customer status: NEEDS_INFO with fields --
  test('sep-12: Checking customer status - NEEDS_INFO with fields and choices', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = mockGetCustomer(responseGetCustomerRequiresInfo());

    final request = GetCustomerInfoRequest();
    request.jwt = jwtToken;
    request.id = customerId;
    request.account = accountId;

    final response = await kycService.getCustomerInfo(request);

    expect(response.status, 'NEEDS_INFO');
    expect(response.fields, isNotNull);
    expect(response.fields!.length, 3);

    // Check field with choices
    final idType = response.fields!['id_type'];
    expect(idType, isNotNull);
    expect(idType!.type, 'string');
    expect(idType.choices, isNotNull);
    expect(idType.choices!.length, 3);
    expect(idType.choices!.contains('Passport'), true);

    // Check optional field
    final emailAddress = response.fields!['email_address'];
    expect(emailAddress, isNotNull);
    expect(emailAddress!.optional, true);

    // Check binary field
    final photoIdFront = response.fields!['photo_id_front'];
    expect(photoIdFront, isNotNull);
    expect(photoIdFront!.type, 'binary');
  });

  // -- Checking customer status: NEEDS_INFO with provided fields --
  test('sep-12: Checking customer status - NEEDS_INFO with provided fields', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = mockGetCustomer(responseGetCustomerNeedsInfo());

    final request = GetCustomerInfoRequest();
    request.jwt = jwtToken;
    request.id = customerId;

    final response = await kycService.getCustomerInfo(request);

    expect(response.status, 'NEEDS_INFO');
    expect(response.fields, isNotNull);
    expect(response.fields!.length, 2);
    expect(response.providedFields, isNotNull);
    expect(response.providedFields!.length, 2);

    final firstName = response.providedFields!['first_name'];
    expect(firstName, isNotNull);
    expect(firstName!.status, 'ACCEPTED');
  });

  // -- Checking customer status: PROCESSING --
  test('sep-12: Checking customer status - PROCESSING', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = mockGetCustomer(responseGetCustomerProcessing());

    final request = GetCustomerInfoRequest();
    request.jwt = jwtToken;
    request.id = customerId;

    final response = await kycService.getCustomerInfo(request);

    expect(response.status, 'PROCESSING');
    expect(response.id, customerId);
    expect(response.message, contains('manual review'));
    expect(response.providedFields, isNotNull);

    final photoIdFront = response.providedFields!['photo_id_front'];
    expect(photoIdFront, isNotNull);
    expect(photoIdFront!.status, 'PROCESSING');
    expect(photoIdFront.type, 'binary');
  });

  // -- Checking customer status: REJECTED --
  test('sep-12: Checking customer status - REJECTED', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = mockGetCustomer(responseGetCustomerRejected());

    final request = GetCustomerInfoRequest();
    request.jwt = jwtToken;
    request.id = customerId;

    final response = await kycService.getCustomerInfo(request);

    expect(response.status, 'REJECTED');
    expect(response.id, customerId);
    expect(response.message, 'This person is on a sanctions list');
  });

  // -- Submitting customer information: Personal information --
  test('sep-12: Submitting personal information', () async {
    // Snippet from sep-12.md "Personal information"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      final contentType = request.headers['content-type']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith('multipart/form-data;')) {
        expect(request.body, contains('first_name'));
        expect(request.body, contains('Jane'));
        expect(request.body, contains('last_name'));
        expect(request.body, contains('Doe'));
        expect(request.body, contains('email_address'));
        expect(request.body, contains('jane@example.com'));
        expect(request.body, contains('mobile_number'));
        expect(request.body, contains('+14155551234'));
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final personFields = NaturalPersonKYCFields();
    personFields.firstName = 'Jane';
    personFields.lastName = 'Doe';
    personFields.emailAddress = 'jane@example.com';
    personFields.mobileNumber = '+14155551234';
    personFields.birthDate = DateTime(1990, 5, 15);

    final kycFields = StandardKYCFields();
    kycFields.naturalPersonKYCFields = personFields;

    final request = PutCustomerInfoRequest();
    request.jwt = jwtToken;
    request.kycFields = kycFields;
    request.type = 'sep6-deposit';

    final response = await kycService.putCustomerInfo(request);
    expect(response.id, customerId);
  });

  // -- Submitting customer information: Complete natural person fields --
  test('sep-12: Complete natural person fields', () async {
    // Snippet from sep-12.md "Complete natural person fields"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken)) {
        // Verify key fields are present
        expect(request.body, contains('first_name'));
        expect(request.body, contains('Jane'));
        expect(request.body, contains('address_country_code'));
        expect(request.body, contains('USA'));
        expect(request.body, contains('id_type'));
        expect(request.body, contains('passport'));
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final personFields = NaturalPersonKYCFields();
    personFields.firstName = 'Jane';
    personFields.lastName = 'Doe';
    personFields.additionalName = 'Marie';
    personFields.address = '123 Main St, Apt 4B';
    personFields.city = 'San Francisco';
    personFields.stateOrProvince = 'CA';
    personFields.postalCode = '94102';
    personFields.addressCountryCode = 'USA';
    personFields.mobileNumber = '+14155551234';
    personFields.emailAddress = 'jane@example.com';
    personFields.languageCode = 'en';
    personFields.birthDate = DateTime(1990, 5, 15);
    personFields.birthPlace = 'New York, NY, USA';
    personFields.birthCountryCode = 'USA';
    personFields.taxId = '123-45-6789';
    personFields.taxIdName = 'SSN';
    personFields.occupation = 2512;
    personFields.employerName = 'Acme Corp';
    personFields.employerAddress = '456 Business Ave, New York, NY 10001';
    personFields.idType = 'passport';
    personFields.idNumber = 'AB123456';
    personFields.idCountryCode = 'USA';
    personFields.idIssueDate = DateTime(2020, 1, 15);
    personFields.idExpirationDate = DateTime(2030, 1, 15);
    personFields.sex = 'female';
    personFields.ipAddress = '192.168.1.1';
    personFields.referralId = 'REF123';

    final kycFields = StandardKYCFields();
    kycFields.naturalPersonKYCFields = personFields;

    final request = PutCustomerInfoRequest();
    request.jwt = jwtToken;
    request.kycFields = kycFields;

    final response = await kycService.putCustomerInfo(request);
    expect(response.id, customerId);
  });

  // -- Financial account information --
  test('sep-12: Financial account information', () async {
    // Snippet from sep-12.md "Financial account information"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken)) {
        expect(request.body, contains('bank_account_number'));
        expect(request.body, contains('1234567890'));
        expect(request.body, contains('first_name'));
        expect(request.body, contains('Jane'));
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final financialFields = FinancialAccountKYCFields();
    financialFields.bankName = 'First National Bank';
    financialFields.bankAccountType = 'checking';
    financialFields.bankAccountNumber = '1234567890';
    financialFields.bankNumber = '021000021';
    financialFields.bankBranchNumber = '001';
    financialFields.bankPhoneNumber = '+18005551234';
    financialFields.externalTransferMemo = 'WIRE-REF-12345';
    financialFields.clabeNumber = '032180000118359719';
    financialFields.cbuNumber = '0110000000001234567890';
    financialFields.cbuAlias = 'mi.cuenta.arg';
    financialFields.mobileMoneyNumber = '+254712345678';
    financialFields.mobileMoneyProvider = 'M-Pesa';
    financialFields.cryptoAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0AB12';

    final personFields = NaturalPersonKYCFields();
    personFields.firstName = 'Jane';
    personFields.lastName = 'Doe';
    personFields.financialAccountKYCFields = financialFields;

    final kycFields = StandardKYCFields();
    kycFields.naturalPersonKYCFields = personFields;

    final request = PutCustomerInfoRequest();
    request.jwt = jwtToken;
    request.kycFields = kycFields;

    final response = await kycService.putCustomerInfo(request);
    expect(response.id, customerId);
  });

  // -- Uploading ID documents --
  test('sep-12: Uploading ID documents (binary fields)', () async {
    // Snippet from sep-12.md "Uploading ID documents"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      final contentType = request.headers['content-type']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith('multipart/form-data;')) {
        // Binary fields make request.body fail with UTF-8 decode error,
        // so check content-type instead to verify multipart upload
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final idFrontBytes = randomBytes(100);
    final idBackBytes = randomBytes(100);

    final personFields = NaturalPersonKYCFields();
    personFields.idType = 'passport';
    personFields.idNumber = 'AB123456';
    personFields.idCountryCode = 'USA';
    personFields.idIssueDate = DateTime(2020, 1, 15);
    personFields.idExpirationDate = DateTime(2030, 1, 15);
    personFields.photoIdFront = idFrontBytes;
    personFields.photoIdBack = idBackBytes;

    final kycFields = StandardKYCFields();
    kycFields.naturalPersonKYCFields = personFields;

    final request = PutCustomerInfoRequest();
    request.jwt = jwtToken;
    request.id = customerId;
    request.kycFields = kycFields;

    final response = await kycService.putCustomerInfo(request);
    expect(response.id, customerId);
  });

  // -- Organization KYC --
  test('sep-12: Organization KYC', () async {
    // Snippet from sep-12.md "Organization KYC"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken)) {
        expect(request.body, contains('organization.name'));
        expect(request.body, contains('Acme Corporation'));
        expect(request.body, contains('organization.VAT_number'));
        expect(request.body, contains('DE123456789'));
        expect(request.body, contains('organization.bank_account_number'));
        expect(request.body, contains('9876543210'));
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final orgFields = OrganizationKYCFields();
    orgFields.name = 'Acme Corporation';
    orgFields.VATNumber = 'DE123456789';
    orgFields.registrationNumber = 'HRB 12345';
    orgFields.registrationDate = '2010-06-15';
    orgFields.registeredAddress = '456 Business Ave, Suite 100';
    orgFields.city = 'New York';
    orgFields.stateOrProvince = 'NY';
    orgFields.postalCode = '10001';
    orgFields.addressCountryCode = 'USA';
    orgFields.numberOfShareholders = 3;
    orgFields.shareholderName = 'John Smith';
    orgFields.directorName = 'Jane Doe';
    orgFields.website = 'https://acme-corp.example.com';
    orgFields.email = 'contact@acme-corp.example.com';
    orgFields.phone = '+12125551234';

    final orgFinancialFields = FinancialAccountKYCFields();
    orgFinancialFields.bankName = 'Business Bank';
    orgFinancialFields.bankAccountNumber = '9876543210';
    orgFinancialFields.bankNumber = '021000021';
    orgFields.financialAccountKYCFields = orgFinancialFields;

    final kycFields = StandardKYCFields();
    kycFields.organizationKYCFields = orgFields;

    final request = PutCustomerInfoRequest();
    request.jwt = jwtToken;
    request.kycFields = kycFields;

    final response = await kycService.putCustomerInfo(request);
    expect(response.id, customerId);
  });

  // -- Using custom fields --
  test('sep-12: Using custom fields', () async {
    // Snippet from sep-12.md "Using custom fields"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken)) {
        expect(request.body, contains('custom_field_1'));
        expect(request.body, contains('custom value'));
        expect(request.body, contains('anchor_specific_id'));
        expect(request.body, contains('ABC123'));
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final request = PutCustomerInfoRequest();
    request.jwt = jwtToken;
    request.id = customerId;
    request.customFields = {
      'custom_field_1': 'custom value',
      'anchor_specific_id': 'ABC123',
    };

    final response = await kycService.putCustomerInfo(request);
    expect(response.id, customerId);
  });

  // -- Verifying contact information --
  test('sep-12: Verifying contact information - check VERIFICATION_REQUIRED', () async {
    // Snippet from sep-12.md "Verifying contact information"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = mockGetCustomer(responseGetCustomerVerificationRequired());

    final getRequest = GetCustomerInfoRequest();
    getRequest.jwt = jwtToken;
    getRequest.id = customerId;
    final response = await kycService.getCustomerInfo(getRequest);

    expect(response.status, 'NEEDS_INFO');
    expect(response.providedFields, isNotNull);

    final mobileNumber = response.providedFields!['mobile_number'];
    expect(mobileNumber, isNotNull);
    expect(mobileNumber!.status, 'VERIFICATION_REQUIRED');

    // Submit verification code
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer') &&
          authHeader.contains(jwtToken)) {
        expect(request.body, contains('mobile_number_verification'));
        expect(request.body, contains('123456'));
        return http.Response(responsePutCustomerInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final putRequest = PutCustomerInfoRequest();
    putRequest.jwt = jwtToken;
    putRequest.id = customerId;
    putRequest.customFields = {
      'mobile_number_verification': '123456',
    };

    final verifyResponse = await kycService.putCustomerInfo(putRequest);
    expect(verifyResponse.id, customerId);
  });

  // -- Deprecated verification endpoint --
  test('sep-12: Deprecated verification endpoint', () async {
    // Snippet from sep-12.md "Deprecated verification endpoint"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer/verification') &&
          authHeader.contains(jwtToken)) {
        return http.Response(responsePutCustomerVerification(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final request = PutCustomerVerificationRequest();
    request.jwt = jwtToken;
    request.id = customerId;
    request.verificationFields = {
      'mobile_number_verification': '123456',
      'email_address_verification': 'ABC123',
    };

    // Returns GetCustomerInfoResponse, NOT PutCustomerInfoResponse
    final response = await kycService.putCustomerVerification(request);
    expect(response.status, 'ACCEPTED');
    expect(response.id, customerId);
    expect(response.providedFields, isNotNull);
    expect(response.providedFields!['mobile_number']!.status, 'ACCEPTED');
  });

  // -- File upload endpoint: Upload a file --
  test('sep-12: Upload a file (postCustomerFile)', () async {
    // Snippet from sep-12.md "Upload a file"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'POST' &&
          request.url.toString().contains('customer/files') &&
          authHeader.contains(jwtToken)) {
        return http.Response(responsePostCustomerFile(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final fileBytes = randomBytes(20000);
    final fileResponse = await kycService.postCustomerFile(fileBytes, jwtToken);

    expect(fileResponse.fileId, 'file_d3d54529-6683-4341-9b66-4ac7d7504238');
    expect(fileResponse.contentType, 'image/jpeg');
    expect(fileResponse.size, 4089371);
    expect(fileResponse.customerId, '2bf95490-db23-442d-a1bd-c6fd5efb584e');
  });

  // -- File upload endpoint: Retrieve file information --
  test('sep-12: Retrieve file information (getCustomerFiles)', () async {
    // Snippet from sep-12.md "Retrieve file information"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'GET' &&
          request.url.toString().contains('customer/files') &&
          authHeader.contains(jwtToken)) {
        return http.Response(responseGetCustomerFiles(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final response = await kycService.getCustomerFiles(jwtToken);
    expect(response.files.length, 2);

    final firstFile = response.files.first;
    expect(firstFile.fileId, 'file_d5c67b4c-173c-428c-baab-944f4b89a57f');
    expect(firstFile.contentType, 'image/png');
    expect(firstFile.size, 6134063);
    expect(firstFile.customerId, '2bf95490-db23-442d-a1bd-c6fd5efb584e');

    final secondFile = response.files.last;
    expect(secondFile.fileId, 'file_d3d54529-6683-4341-9b66-4ac7d7504238');
    expect(secondFile.contentType, 'image/jpeg');
    expect(secondFile.size, 4089371);
  });

  // -- Callback notifications --
  test('sep-12: Callback notifications (putCustomerCallback)', () async {
    // Snippet from sep-12.md "Callback notifications"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'PUT' &&
          request.url.toString().contains('customer/callback') &&
          authHeader.contains(jwtToken)) {
        return http.Response('', 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final request = PutCustomerCallbackRequest();
    request.jwt = jwtToken;
    request.id = customerId;
    request.url = 'https://myapp.com/kyc-callback';

    // Returns http.Response directly
    http.Response response = await kycService.putCustomerCallback(request);
    expect(response.statusCode, 200);
  });

  // -- Deleting customer data --
  test('sep-12: Deleting customer data', () async {
    // Snippet from sep-12.md "Deleting customer data"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'DELETE' &&
          request.url.toString().contains('customer/$accountId') &&
          authHeader.contains(jwtToken)) {
        return http.Response('', 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    // First argument is Stellar account ID (G... address), NOT customer UUID
    http.Response response = await kycService.deleteCustomer(
      accountId,
      null,
      null,
      jwtToken,
    );
    expect(response.statusCode, 200);
  });

  // -- Deleting customer data with memo --
  test('sep-12: Deleting customer data with memo', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'DELETE' &&
          request.url.toString().contains('customer/$accountId') &&
          authHeader.contains(jwtToken)) {
        return http.Response('', 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    http.Response response = await kycService.deleteCustomer(
      accountId,
      '12345',
      'id',
      jwtToken,
    );
    expect(response.statusCode, 200);
  });

  // -- Shared/omnibus accounts --
  test('sep-12: Shared/omnibus accounts with memo', () async {
    // Snippet from sep-12.md "Shared/omnibus accounts"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'GET' &&
          request.url.toString().contains('customer') &&
          request.url.toString().contains('memo=12345') &&
          authHeader.contains(jwtToken)) {
        return http.Response(responseGetCustomerAccepted(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final getRequest = GetCustomerInfoRequest();
    getRequest.jwt = jwtToken;
    getRequest.account = accountId;
    getRequest.memo = '12345';
    getRequest.memoType = 'id';

    final response = await kycService.getCustomerInfo(getRequest);
    expect(response.status, 'ACCEPTED');
  });

  // -- Transaction-based KYC --
  test('sep-12: Transaction-based KYC', () async {
    // Snippet from sep-12.md "Transaction-based KYC"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      final authHeader = request.headers['Authorization']!;
      if (request.method == 'GET' &&
          request.url.toString().contains('customer') &&
          request.url.toString().contains('transaction_id=tx_abc123') &&
          authHeader.contains(jwtToken)) {
        return http.Response(responseGetCustomerRequiresInfo(), 200);
      }
      return http.Response(json.encode({'error': 'Bad request'}), 400);
    });

    final getRequest = GetCustomerInfoRequest();
    getRequest.jwt = jwtToken;
    getRequest.transactionId = 'tx_abc123';
    getRequest.type = 'sep6';

    final response = await kycService.getCustomerInfo(getRequest);
    expect(response.status, 'NEEDS_INFO');
    expect(response.fields, isNotNull);
  });

  // -- Error handling --
  test('sep-12: Error handling - ErrorResponse on 404', () async {
    // Snippet from sep-12.md "Error handling"
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      return http.Response(json.encode({'error': 'customer not found'}), 404);
    });

    try {
      final request = GetCustomerInfoRequest();
      request.jwt = jwtToken;
      request.id = 'nonexistent-id';
      await kycService.getCustomerInfo(request);
      fail('Should have thrown ErrorResponse');
    } on ErrorResponse catch (e) {
      expect(e.code, 404);
    }
  });

  // -- Error handling for postCustomerFile --
  test('sep-12: Error handling - postCustomerFile 413', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      return http.Response('', 413);
    });

    try {
      await kycService.postCustomerFile(randomBytes(20000), jwtToken);
      fail('Should have thrown ErrorResponse');
    } on ErrorResponse catch (e) {
      expect(e.code, 413);
    }
  });

  // -- Error handling for postCustomerFile 400 --
  test('sep-12: Error handling - postCustomerFile 400 invalid format', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      return http.Response(
        json.encode({'error': 'file cannot be decoded. Must be jpg or png.'}),
        400,
      );
    });

    try {
      await kycService.postCustomerFile(randomBytes(20000), jwtToken);
      fail('Should have thrown ErrorResponse');
    } on ErrorResponse catch (e) {
      expect(e.code, 400);
      expect(e.body, contains('cannot be decoded'));
    }
  });
}
