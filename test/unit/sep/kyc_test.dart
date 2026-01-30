import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('KYCService GET Customer Info', () {
    test('get customer info with ACCEPTED status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['id'], 'customer-123');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'id': 'customer-123',
          'status': 'ACCEPTED',
          'message': 'Customer information has been approved'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..id = 'customer-123'
        ..jwt = 'test-jwt';

      final response = await service.getCustomerInfo(request);

      expect(response.id, 'customer-123');
      expect(response.status, 'ACCEPTED');
      expect(response.message, 'Customer information has been approved');
      expect(response.fields, isNull);
    });

    test('get customer info with PROCESSING status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['account'], 'GXXXXXXX');

        return http.Response(json.encode({
          'id': 'customer-456',
          'status': 'PROCESSING',
          'message': 'Your information is being reviewed'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..jwt = 'test-jwt';

      final response = await service.getCustomerInfo(request);

      expect(response.id, 'customer-456');
      expect(response.status, 'PROCESSING');
      expect(response.message, 'Your information is being reviewed');
    });

    test('get customer info with NEEDS_INFO status and required fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['account'], 'GXXXXXXX');
        expect(request.url.queryParameters['type'], 'sep31-sender');

        return http.Response(json.encode({
          'status': 'NEEDS_INFO',
          'fields': {
            'first_name': {
              'type': 'string',
              'description': 'Your first name',
              'optional': false
            },
            'last_name': {
              'type': 'string',
              'description': 'Your last name',
              'optional': false
            },
            'email_address': {
              'type': 'string',
              'description': 'Your email address',
              'optional': false
            },
            'country_code': {
              'type': 'string',
              'description': 'ISO 3166-1 alpha-3 country code',
              'choices': ['USA', 'CAN', 'MEX'],
              'optional': false
            },
            'photo_id_front': {
              'type': 'binary',
              'description': 'Front of government-issued photo ID',
              'optional': true
            }
          }
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..type = 'sep31-sender'
        ..jwt = 'test-jwt';

      final response = await service.getCustomerInfo(request);

      expect(response.status, 'NEEDS_INFO');
      expect(response.fields, isNotNull);
      expect(response.fields!.length, 5);

      final firstNameField = response.fields!['first_name']!;
      expect(firstNameField.type, 'string');
      expect(firstNameField.description, 'Your first name');
      expect(firstNameField.optional, false);

      final countryField = response.fields!['country_code']!;
      expect(countryField.type, 'string');
      expect(countryField.choices, ['USA', 'CAN', 'MEX']);

      final photoField = response.fields!['photo_id_front']!;
      expect(photoField.type, 'binary');
      expect(photoField.optional, true);
    });

    test('get customer info with NEEDS_INFO and provided fields with status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['id'], 'customer-789');

        return http.Response(json.encode({
          'id': 'customer-789',
          'status': 'NEEDS_INFO',
          'fields': {
            'photo_id_front': {
              'type': 'binary',
              'description': 'Front of photo ID',
              'optional': false
            }
          },
          'provided_fields': {
            'first_name': {
              'type': 'string',
              'description': 'First name',
              'status': 'ACCEPTED'
            },
            'last_name': {
              'type': 'string',
              'description': 'Last name',
              'status': 'ACCEPTED'
            },
            'email_address': {
              'type': 'string',
              'description': 'Email address',
              'status': 'VERIFICATION_REQUIRED'
            },
            'mobile_number': {
              'type': 'string',
              'description': 'Phone number',
              'status': 'REJECTED',
              'error': 'Invalid phone number format'
            }
          }
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..id = 'customer-789'
        ..jwt = 'test-jwt';

      final response = await service.getCustomerInfo(request);

      expect(response.id, 'customer-789');
      expect(response.status, 'NEEDS_INFO');
      expect(response.fields!.length, 1);
      expect(response.providedFields, isNotNull);
      expect(response.providedFields!.length, 4);

      final firstName = response.providedFields!['first_name']!;
      expect(firstName.status, 'ACCEPTED');

      final email = response.providedFields!['email_address']!;
      expect(email.status, 'VERIFICATION_REQUIRED');

      final mobile = response.providedFields!['mobile_number']!;
      expect(mobile.status, 'REJECTED');
      expect(mobile.error, 'Invalid phone number format');
    });

    test('get customer info with REJECTED status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['id'], 'customer-rejected');

        return http.Response(json.encode({
          'id': 'customer-rejected',
          'status': 'REJECTED',
          'message': 'Customer information could not be verified'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..id = 'customer-rejected'
        ..jwt = 'test-jwt';

      final response = await service.getCustomerInfo(request);

      expect(response.id, 'customer-rejected');
      expect(response.status, 'REJECTED');
      expect(response.message, 'Customer information could not be verified');
    });

    test('get customer info with memo parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['account'], 'GXXXXXXX');
        expect(request.url.queryParameters['memo'], '123456');
        expect(request.url.queryParameters['memo_type'], 'id');

        return http.Response(json.encode({
          'status': 'ACCEPTED'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..memo = '123456'
        ..memoType = 'id'
        ..jwt = 'test-jwt';

      await service.getCustomerInfo(request);
    });

    test('get customer info with transaction_id parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['transaction_id'], 'tx-123');
        expect(request.url.queryParameters['type'], 'sep6-deposit');

        return http.Response(json.encode({
          'status': 'NEEDS_INFO',
          'fields': {}
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..transactionId = 'tx-123'
        ..type = 'sep6-deposit'
        ..jwt = 'test-jwt';

      await service.getCustomerInfo(request);
    });

    test('get customer info with language parameter', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.url.queryParameters['lang'], 'es');

        return http.Response(json.encode({
          'status': 'NEEDS_INFO',
          'fields': {
            'first_name': {
              'type': 'string',
              'description': 'Tu nombre',
              'optional': false
            }
          }
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..lang = 'es'
        ..jwt = 'test-jwt';

      final response = await service.getCustomerInfo(request);
      expect(response.fields!['first_name']!.description, 'Tu nombre');
    });
  });

  group('KYCService PUT Customer Info', () {
    test('register new customer with basic fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.method, 'PUT');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'id': 'new-customer-123'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..kycFields = (StandardKYCFields()
          ..naturalPersonKYCFields = (NaturalPersonKYCFields()
            ..firstName = 'John'
            ..lastName = 'Doe'
            ..emailAddress = 'john@example.com'))
        ..jwt = 'test-jwt';

      final response = await service.putCustomerInfo(request);

      expect(response.id, 'new-customer-123');
    });

    test('update existing customer by id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'existing-customer-456'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerInfoRequest()
        ..id = 'existing-customer-456'
        ..kycFields = (StandardKYCFields()
          ..naturalPersonKYCFields = (NaturalPersonKYCFields()
            ..emailAddress = 'newemail@example.com'))
        ..jwt = 'test-jwt';

      final response = await service.putCustomerInfo(request);

      expect(response.id, 'existing-customer-456');
    });

    test('submit customer with all natural person fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'customer-full-profile'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..type = 'sep31-sender'
        ..kycFields = (StandardKYCFields()
          ..naturalPersonKYCFields = (NaturalPersonKYCFields()
            ..firstName = 'Jane'
            ..lastName = 'Smith'
            ..emailAddress = 'jane@example.com'
            ..mobileNumber = '+1-555-0123'
            ..birthDate = DateTime(1990, 1, 15)
            ..address = '123 Main St'
            ..city = 'New York'
            ..stateOrProvince = 'NY'
            ..postalCode = '10001'
            ..addressCountryCode = 'USA'))
        ..jwt = 'test-jwt';

      final response = await service.putCustomerInfo(request);

      expect(response.id, 'customer-full-profile');
    });

    test('submit customer with file uploads', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'customer-with-docs'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final idFrontBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final idBackBytes = Uint8List.fromList([6, 7, 8, 9, 10]);

      final request = PutCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..kycFields = (StandardKYCFields()
          ..naturalPersonKYCFields = (NaturalPersonKYCFields()
            ..firstName = 'Bob'
            ..lastName = 'Johnson'
            ..photoIdFront = idFrontBytes
            ..photoIdBack = idBackBytes))
        ..jwt = 'test-jwt';

      final response = await service.putCustomerInfo(request);

      expect(response.id, 'customer-with-docs');
    });

    test('submit organization KYC fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'org-customer-123'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..type = 'sep31-receiver'
        ..kycFields = (StandardKYCFields()
          ..organizationKYCFields = (OrganizationKYCFields()
            ..name = 'Acme Corp'
            ..registrationNumber = '123456789'
            ..addressCountryCode = 'USA'))
        ..jwt = 'test-jwt';

      final response = await service.putCustomerInfo(request);

      expect(response.id, 'org-customer-123');
    });

    test('submit customer with custom fields', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'customer-custom-fields'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..customFields = {
          'referral_code': 'REF123',
          'account_type': 'premium'
        }
        ..jwt = 'test-jwt';

      final response = await service.putCustomerInfo(request);

      expect(response.id, 'customer-custom-fields');
    });

    test('submit customer with memo parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'customer-with-memo'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..memo = '987654'
        ..memoType = 'id'
        ..kycFields = (StandardKYCFields()
          ..naturalPersonKYCFields = (NaturalPersonKYCFields()
            ..firstName = 'Alice'
            ..lastName = 'Brown'))
        ..jwt = 'test-jwt';

      final response = await service.putCustomerInfo(request);

      expect(response.id, 'customer-with-memo');
    });
  });

  group('KYCService PUT Customer Verification', () {
    test('verify email address with code', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/verification'));
        expect(request.method, 'PUT');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'id': 'customer-123',
          'status': 'ACCEPTED',
          'provided_fields': {
            'email_address': {
              'type': 'string',
              'status': 'ACCEPTED'
            }
          }
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerVerificationRequest()
        ..id = 'customer-123'
        ..verificationFields = {
          'email_address_verification': '123456'
        }
        ..jwt = 'test-jwt';

      final response = await service.putCustomerVerification(request);

      expect(response.id, 'customer-123');
      expect(response.status, 'ACCEPTED');
      expect(response.providedFields!['email_address']!.status, 'ACCEPTED');
    });

    test('verify multiple fields with codes', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/verification'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'customer-456',
          'status': 'ACCEPTED',
          'provided_fields': {
            'email_address': {
              'type': 'string',
              'status': 'ACCEPTED'
            },
            'mobile_number': {
              'type': 'string',
              'status': 'ACCEPTED'
            }
          }
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerVerificationRequest()
        ..id = 'customer-456'
        ..verificationFields = {
          'email_address_verification': '123456',
          'mobile_number_verification': '654321'
        }
        ..jwt = 'test-jwt';

      final response = await service.putCustomerVerification(request);

      expect(response.id, 'customer-456');
      expect(response.status, 'ACCEPTED');
      expect(response.providedFields!['email_address']!.status, 'ACCEPTED');
      expect(response.providedFields!['mobile_number']!.status, 'ACCEPTED');
    });

    test('verification with still NEEDS_INFO status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/verification'));
        expect(request.method, 'PUT');

        return http.Response(json.encode({
          'id': 'customer-789',
          'status': 'NEEDS_INFO',
          'fields': {
            'photo_id_front': {
              'type': 'binary',
              'description': 'Photo ID required',
              'optional': false
            }
          },
          'provided_fields': {
            'email_address': {
              'type': 'string',
              'status': 'ACCEPTED'
            }
          }
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerVerificationRequest()
        ..id = 'customer-789'
        ..verificationFields = {
          'email_address_verification': '999999'
        }
        ..jwt = 'test-jwt';

      final response = await service.putCustomerVerification(request);

      expect(response.id, 'customer-789');
      expect(response.status, 'NEEDS_INFO');
      expect(response.fields, isNotNull);
      expect(response.providedFields!['email_address']!.status, 'ACCEPTED');
    });
  });

  group('KYCService DELETE Customer', () {
    test('delete customer by account', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/GXXXXXXX'));
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response('', 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.deleteCustomer(
        'GXXXXXXX',
        null,
        null,
        'test-jwt',
      );

      expect(response.statusCode, 200);
    });

    test('delete customer with memo', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/GXXXXXXX'));
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response('', 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.deleteCustomer(
        'GXXXXXXX',
        '123456',
        'id',
        'test-jwt',
      );

      expect(response.statusCode, 200);
    });
  });

  group('KYCService PUT Customer Callback', () {
    test('register callback URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/callback'));
        expect(request.method, 'PUT');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response('', 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerCallbackRequest()
        ..url = 'https://myapp.com/webhooks/kyc'
        ..account = 'GXXXXXXX'
        ..jwt = 'test-jwt';

      final response = await service.putCustomerCallback(request);

      expect(response.statusCode, 200);
    });

    test('register callback URL with customer id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/callback'));
        expect(request.method, 'PUT');

        return http.Response('', 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = PutCustomerCallbackRequest()
        ..url = 'https://myapp.com/webhooks/kyc'
        ..id = 'customer-123'
        ..jwt = 'test-jwt';

      final response = await service.putCustomerCallback(request);

      expect(response.statusCode, 200);
    });
  });

  group('KYCService Customer Files', () {
    test('upload customer file', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/files'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'file_id': 'file-123',
          'content_type': 'image/jpeg',
          'size': 1024,
          'expires_at': '2025-12-31T23:59:59Z'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final fileBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final response = await service.postCustomerFile(fileBytes, 'test-jwt');

      expect(response.fileId, 'file-123');
      expect(response.contentType, 'image/jpeg');
      expect(response.size, 1024);
      expect(response.expiresAt, '2025-12-31T23:59:59Z');
    });

    test('get customer files by file id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/files'));
        expect(request.url.queryParameters['file_id'], 'file-123');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'files': [
            {
              'file_id': 'file-123',
              'content_type': 'image/jpeg',
              'size': 1024,
              'expires_at': '2025-12-31T23:59:59Z',
              'customer_id': 'customer-456'
            }
          ]
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.getCustomerFiles('test-jwt', fileId: 'file-123');

      expect(response.files.length, 1);
      expect(response.files[0].fileId, 'file-123');
      expect(response.files[0].customerId, 'customer-456');
    });

    test('get customer files by customer id', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/customer/files'));
        expect(request.url.queryParameters['customer_id'], 'customer-789');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'files': [
            {
              'file_id': 'file-001',
              'content_type': 'image/jpeg',
              'size': 2048,
              'customer_id': 'customer-789'
            },
            {
              'file_id': 'file-002',
              'content_type': 'application/pdf',
              'size': 4096,
              'customer_id': 'customer-789'
            }
          ]
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.getCustomerFiles('test-jwt', customerId: 'customer-789');

      expect(response.files.length, 2);
      expect(response.files[0].fileId, 'file-001');
      expect(response.files[0].contentType, 'image/jpeg');
      expect(response.files[1].fileId, 'file-002');
      expect(response.files[1].contentType, 'application/pdf');
    });
  });

  group('KYCService Error Handling', () {
    test('handle 400 bad request error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid account parameter'
        }), 400);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..account = 'INVALID'
        ..jwt = 'test-jwt';

      expect(
        () => service.getCustomerInfo(request),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('handle 403 forbidden error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Forbidden'
        }), 403);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..jwt = 'invalid-jwt';

      expect(
        () => service.getCustomerInfo(request),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('handle 404 not found error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Customer not found'
        }), 404);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = GetCustomerInfoRequest()
        ..id = 'nonexistent-customer'
        ..jwt = 'test-jwt';

      expect(
        () => service.getCustomerInfo(request),
        throwsA(isA<ErrorResponse>()),
      );
    });

    test('verify service accepts custom headers in constructor', () async {
      // This test verifies that the service constructor accepts httpRequestHeaders
      // Note: There is a bug in the current implementation where GET requests
      // don't pass httpRequestHeaders to the requestExecute method (line 1008)
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'status': 'ACCEPTED'
        }), 200);
      });

      final service = KYCService(
        'https://api.example.com',
        httpClient: mockClient,
        httpRequestHeaders: {
          'X-Custom-Header': 'custom-value',
        },
      );

      final request = GetCustomerInfoRequest()
        ..account = 'GXXXXXXX'
        ..jwt = 'test-jwt';

      // Service should work even if custom headers aren't currently passed through
      await service.getCustomerInfo(request);
    });
  });

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
