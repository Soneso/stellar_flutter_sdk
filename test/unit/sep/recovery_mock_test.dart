import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:convert';

void main() {
  group('SEP30RecoveryService Register Account', () {
    test('register account with single owner identity', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GXXXXXXX'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-jwt');
        expect(request.headers['Content-Type'], 'application/json');

        final body = json.decode(request.body);
        expect(body['identities'], isNotNull);
        expect(body['identities'].length, 1);
        expect(body['identities'][0]['role'], 'owner');

        return http.Response(json.encode({
          'address': 'GXXXXXXX',
          'identities': [
            {
              'role': 'owner'
            }
          ],
          'signers': [
            {
              'key': 'GSIGNER1XXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final emailAuth = SEP30AuthMethod('email', 'user@example.com');
      final ownerIdentity = SEP30RequestIdentity('owner', [emailAuth]);
      final request = SEP30Request([ownerIdentity]);

      final response = await service.registerAccount(
        'GXXXXXXX',
        request,
        'test-jwt',
      );

      expect(response.address, 'GXXXXXXX');
      expect(response.identities.length, 1);
      expect(response.identities[0].role, 'owner');
      expect(response.signers.length, 1);
      expect(response.signers[0].key, 'GSIGNER1XXXXXXX');
    });

    test('register account with multiple authentication methods', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GYYYYYY'));
        expect(request.method, 'POST');

        final body = json.decode(request.body);
        expect(body['identities'][0]['auth_methods'].length, 3);

        return http.Response(json.encode({
          'address': 'GYYYYYY',
          'identities': [
            {
              'role': 'owner'
            }
          ],
          'signers': [
            {
              'key': 'GSIGNER2XXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final emailAuth = SEP30AuthMethod('email', 'user@example.com');
      final phoneAuth = SEP30AuthMethod('phone_number', '+1234567890');
      final stellarAuth = SEP30AuthMethod('stellar_address', 'user*example.com');
      final ownerIdentity = SEP30RequestIdentity('owner', [emailAuth, phoneAuth, stellarAuth]);
      final request = SEP30Request([ownerIdentity]);

      final response = await service.registerAccount(
        'GYYYYYY',
        request,
        'test-jwt',
      );

      expect(response.address, 'GYYYYYY');
      expect(response.signers.length, 1);
    });

    test('register account with multiple identities', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GZZZZZZ'));
        expect(request.method, 'POST');

        final body = json.decode(request.body);
        expect(body['identities'].length, 3);

        return http.Response(json.encode({
          'address': 'GZZZZZZ',
          'identities': [
            {
              'role': 'owner'
            },
            {
              'role': 'other'
            },
            {
              'role': 'other'
            }
          ],
          'signers': [
            {
              'key': 'GSIGNER3XXXXXXX'
            },
            {
              'key': 'GSIGNER4XXXXXXX'
            },
            {
              'key': 'GSIGNER5XXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final owner = SEP30RequestIdentity('owner', [
        SEP30AuthMethod('email', 'owner@example.com')
      ]);
      final other1 = SEP30RequestIdentity('other', [
        SEP30AuthMethod('phone_number', '+1111111111')
      ]);
      final other2 = SEP30RequestIdentity('other', [
        SEP30AuthMethod('email', 'backup@example.com')
      ]);
      final request = SEP30Request([owner, other1, other2]);

      final response = await service.registerAccount(
        'GZZZZZZ',
        request,
        'test-jwt',
      );

      expect(response.address, 'GZZZZZZ');
      expect(response.identities.length, 3);
      expect(response.signers.length, 3);
    });
  });

  group('SEP30RecoveryService Update Account Identities', () {
    test('update account identities', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GXXXXXXX'));
        expect(request.method, 'PUT');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'address': 'GXXXXXXX',
          'identities': [
            {
              'role': 'owner'
            }
          ],
          'signers': [
            {
              'key': 'GSIGNERNEWXXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final newEmail = SEP30AuthMethod('email', 'newemail@example.com');
      final ownerIdentity = SEP30RequestIdentity('owner', [newEmail]);
      final request = SEP30Request([ownerIdentity]);

      final response = await service.updateIdentitiesForAccount(
        'GXXXXXXX',
        request,
        'test-jwt',
      );

      expect(response.address, 'GXXXXXXX');
      expect(response.identities.length, 1);
      expect(response.signers.length, 1);
      expect(response.signers[0].key, 'GSIGNERNEWXXXXXXX');
    });

    test('update adds new identity role', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GYYYYYY'));
        expect(request.method, 'PUT');

        final body = json.decode(request.body);
        expect(body['identities'].length, 2);

        return http.Response(json.encode({
          'address': 'GYYYYYY',
          'identities': [
            {
              'role': 'owner'
            },
            {
              'role': 'other'
            }
          ],
          'signers': [
            {
              'key': 'GSIGNER1XXXXXXX'
            },
            {
              'key': 'GSIGNER2XXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final owner = SEP30RequestIdentity('owner', [
        SEP30AuthMethod('email', 'owner@example.com')
      ]);
      final other = SEP30RequestIdentity('other', [
        SEP30AuthMethod('phone_number', '+1234567890')
      ]);
      final request = SEP30Request([owner, other]);

      final response = await service.updateIdentitiesForAccount(
        'GYYYYYY',
        request,
        'test-jwt',
      );

      expect(response.identities.length, 2);
      expect(response.signers.length, 2);
    });
  });

  group('SEP30RecoveryService Sign Transaction', () {
    test('sign transaction with recovery signer', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GXXXXXXX/sign/GSIGNER1XXXXXXX'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-jwt');
        expect(request.headers['Content-Type'], 'application/json');

        final body = json.decode(request.body);
        expect(body['transaction'], 'AAAAAgAAAAA...');

        return http.Response(json.encode({
          'signature': 'SIGNATURE_BASE64_ENCODED',
          'network_passphrase': 'Test SDF Network ; September 2015'
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.signTransaction(
        'GXXXXXXX',
        'GSIGNER1XXXXXXX',
        'AAAAAgAAAAA...',
        'test-jwt',
      );

      expect(response.signature, 'SIGNATURE_BASE64_ENCODED');
      expect(response.networkPassphrase, 'Test SDF Network ; September 2015');
    });

    test('sign transaction for different signer', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GYYYYYY/sign/GSIGNER2XXXXXXX'));
        expect(request.method, 'POST');

        return http.Response(json.encode({
          'signature': 'DIFFERENT_SIGNATURE_BASE64',
          'network_passphrase': 'Public Global Stellar Network ; September 2015'
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.signTransaction(
        'GYYYYYY',
        'GSIGNER2XXXXXXX',
        'TRANSACTION_XDR_BASE64',
        'test-jwt',
      );

      expect(response.signature, 'DIFFERENT_SIGNATURE_BASE64');
      expect(response.networkPassphrase, 'Public Global Stellar Network ; September 2015');
    });
  });

  group('SEP30RecoveryService Get Account Details', () {
    test('get account details by address', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GXXXXXXX'));
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'address': 'GXXXXXXX',
          'identities': [
            {
              'role': 'owner',
              'authenticated': true
            },
            {
              'role': 'other',
              'authenticated': false
            }
          ],
          'signers': [
            {
              'key': 'GSIGNER1XXXXXXX'
            },
            {
              'key': 'GSIGNER2XXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.accountDetails(
        'GXXXXXXX',
        'test-jwt',
      );

      expect(response.address, 'GXXXXXXX');
      expect(response.identities.length, 2);
      expect(response.identities[0].role, 'owner');
      expect(response.identities[0].authenticated, true);
      expect(response.identities[1].role, 'other');
      expect(response.identities[1].authenticated, false);
      expect(response.signers.length, 2);
    });

    test('get account details without authentication status', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GYYYYYY'));
        expect(request.method, 'GET');

        return http.Response(json.encode({
          'address': 'GYYYYYY',
          'identities': [
            {
              'role': 'owner'
            }
          ],
          'signers': [
            {
              'key': 'GSIGNER3XXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.accountDetails(
        'GYYYYYY',
        'test-jwt',
      );

      expect(response.address, 'GYYYYYY');
      expect(response.identities.length, 1);
      expect(response.identities[0].authenticated, isNull);
      expect(response.signers.length, 1);
    });
  });

  group('SEP30RecoveryService Delete Account', () {
    test('delete account registration', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts/GXXXXXXX'));
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer test-jwt');

        return http.Response(json.encode({
          'address': 'GXXXXXXX',
          'identities': [
            {
              'role': 'owner'
            }
          ],
          'signers': [
            {
              'key': 'GSIGNER1XXXXXXX'
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.deleteAccount(
        'GXXXXXXX',
        'test-jwt',
      );

      expect(response.address, 'GXXXXXXX');
      expect(response.identities.length, 1);
      expect(response.signers.length, 1);
    });
  });

  group('SEP30RecoveryService List Accounts', () {
    test('list all accessible accounts', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts'));
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer test-jwt');
        expect(request.url.queryParameters.containsKey('after'), false);

        return http.Response(json.encode({
          'accounts': [
            {
              'address': 'GACCOUNT1XXXXXX',
              'identities': [
                {
                  'role': 'owner'
                }
              ],
              'signers': [
                {
                  'key': 'GSIGNER1XXXXXXX'
                }
              ]
            },
            {
              'address': 'GACCOUNT2XXXXXX',
              'identities': [
                {
                  'role': 'owner'
                }
              ],
              'signers': [
                {
                  'key': 'GSIGNER2XXXXXXX'
                }
              ]
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.accounts('test-jwt');

      expect(response.accounts.length, 2);
      expect(response.accounts[0].address, 'GACCOUNT1XXXXXX');
      expect(response.accounts[1].address, 'GACCOUNT2XXXXXX');
    });

    test('list accounts with pagination', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts'));
        expect(request.url.queryParameters['after'], 'GACCOUNT1XXXXXX');

        return http.Response(json.encode({
          'accounts': [
            {
              'address': 'GACCOUNT2XXXXXX',
              'identities': [
                {
                  'role': 'owner'
                }
              ],
              'signers': [
                {
                  'key': 'GSIGNER2XXXXXXX'
                }
              ]
            },
            {
              'address': 'GACCOUNT3XXXXXX',
              'identities': [
                {
                  'role': 'owner'
                }
              ],
              'signers': [
                {
                  'key': 'GSIGNER3XXXXXXX'
                }
              ]
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.accounts('test-jwt', after: 'GACCOUNT1XXXXXX');

      expect(response.accounts.length, 2);
      expect(response.accounts[0].address, 'GACCOUNT2XXXXXX');
      expect(response.accounts[1].address, 'GACCOUNT3XXXXXX');
    });

    test('list accounts returns empty array', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts'));

        return http.Response(json.encode({
          'accounts': []
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.accounts('test-jwt');

      expect(response.accounts.length, 0);
    });

    test('list accounts supports identities without role', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/accounts'));

        return http.Response(json.encode({
          'accounts': [
            {
              'address': 'GACCOUNT4XXXXXX',
              'identities': [
                {
                  'authenticated': true
                }
              ],
              'signers': [
                {
                  'key': 'GSIGNER4XXXXXXX'
                }
              ]
            }
          ]
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final response = await service.accounts('test-jwt');

      expect(response.accounts.length, 1);
      expect(response.accounts[0].identities.length, 1);
      expect(response.accounts[0].identities[0].role, isNull);
      expect(response.accounts[0].identities[0].authenticated, true);
    });
  });

  group('SEP30RecoveryService Error Handling', () {
    test('handle 400 bad request from registerAccount', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid identities format'
        }), 400);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final request = SEP30Request([]);

      expect(
        () => service.registerAccount('GXXXXXXX', request, 'test-jwt'),
        throwsA(isA<SEP30BadRequestResponseException>()),
      );
    });

    test('handle 401 unauthorized from accountDetails', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Invalid or expired JWT token'
        }), 401);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.accountDetails('GXXXXXXX', 'invalid-jwt'),
        throwsA(isA<SEP30UnauthorizedResponseException>()),
      );
    });

    test('handle 404 not found from accountDetails', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Account not found'
        }), 404);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.accountDetails('GNONEXISTENT', 'test-jwt'),
        throwsA(isA<SEP30NotFoundResponseException>()),
      );
    });

    test('handle 404 not found from signTransaction', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Signing address not found'
        }), 404);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      expect(
        () => service.signTransaction(
          'GXXXXXXX',
          'GINVALIDSIGNER',
          'TRANSACTION_XDR',
          'test-jwt',
        ),
        throwsA(isA<SEP30NotFoundResponseException>()),
      );
    });

    test('handle 409 conflict from registerAccount', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Account already registered'
        }), 409);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final emailAuth = SEP30AuthMethod('email', 'user@example.com');
      final ownerIdentity = SEP30RequestIdentity('owner', [emailAuth]);
      final request = SEP30Request([ownerIdentity]);

      expect(
        () => service.registerAccount('GXXXXXXX', request, 'test-jwt'),
        throwsA(isA<SEP30ConflictResponseException>()),
      );
    });

    test('handle 409 conflict from updateIdentitiesForAccount', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({
          'error': 'Concurrent modification detected'
        }), 409);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
      );

      final emailAuth = SEP30AuthMethod('email', 'user@example.com');
      final ownerIdentity = SEP30RequestIdentity('owner', [emailAuth]);
      final request = SEP30Request([ownerIdentity]);

      expect(
        () => service.updateIdentitiesForAccount('GXXXXXXX', request, 'test-jwt'),
        throwsA(isA<SEP30ConflictResponseException>()),
      );
    });

    test('verify custom headers are passed', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Custom-Header'], 'custom-value');

        return http.Response(json.encode({
          'accounts': []
        }), 200);
      });

      final service = SEP30RecoveryService(
        'https://api.example.com',
        httpClient: mockClient,
        httpRequestHeaders: {
          'X-Custom-Header': 'custom-value',
        },
      );

      await service.accounts('test-jwt');
    });
  });
}
