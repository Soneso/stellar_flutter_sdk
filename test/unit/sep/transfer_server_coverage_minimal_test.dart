import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DepositExchangeAsset fromJson', () {
    test('should parse from JSON with fields', () {
      final json = {
        'enabled': true,
        'authentication_required': true,
        'fields': {
          'dest': {
            'description': 'your email address',
            'optional': false,
          }
        }
      };

      final asset = DepositExchangeAsset.fromJson(json);
      expect(asset.enabled, isTrue);
      expect(asset.authenticationRequired, isTrue);
      expect(asset.fields, isNotNull);
      expect(asset.fields!['dest'], isNotNull);
    });
  });

  group('WithdrawExchangeAsset fromJson', () {
    test('should parse from JSON with types and fields', () {
      final json = {
        'enabled': true,
        'authentication_required': true,
        'types': {
          'bank_account': {
            'fields': {
              'dest': {
                'description': 'your bank account number',
                'optional': false,
              }
            }
          }
        }
      };

      final asset = WithdrawExchangeAsset.fromJson(json);
      expect(asset.enabled, isTrue);
      expect(asset.authenticationRequired, isTrue);
      expect(asset.types, isNotNull);
      expect(asset.types!['bank_account'], isNotNull);
    });
  });

  group('CustomerInformationNeededException', () {
    test('should return correct toString', () {
      final response = CustomerInformationNeededResponse(['email_address']);
      final exception = CustomerInformationNeededException(response);
      final message = exception.toString();

      expect(message, contains('anchor needs more information'));
      expect(message, contains('email_address'));
    });
  });
}
