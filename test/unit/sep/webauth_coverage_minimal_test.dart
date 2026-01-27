import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebAuth exception classes', () {
    test('MissingClientDomainException should have correct message', () {
      final exception = MissingClientDomainException();
      expect(exception.toString(), contains('clientDomain'));
    });

    test('NoClientDomainSigningKeyFoundException should include domain', () {
      final exception = NoClientDomainSigningKeyFoundException('example.com');
      final message = exception.toString();
      expect(message, contains('example.com'));
    });

    test('ChallengeValidationErrorInvalidSourceAccount should have message', () {
      final exception = ChallengeValidationErrorInvalidSourceAccount('test error');
      expect(exception.toString(), contains('test error'));
    });

    test('ChallengeValidationErrorInvalidOperationType should have message', () {
      final exception = ChallengeValidationErrorInvalidOperationType('invalid type');
      expect(exception.toString(), contains('invalid type'));
    });

    test('ChallengeValidationErrorInvalidTimeBounds should have message', () {
      final exception = ChallengeValidationErrorInvalidTimeBounds('time bounds error');
      expect(exception.toString(), contains('time bounds error'));
    });

    test('ChallengeValidationErrorInvalidSignature should have message', () {
      final exception = ChallengeValidationErrorInvalidSignature('signature error');
      expect(exception.toString(), contains('signature error'));
    });

    test('ChallengeValidationErrorInvalidHomeDomain should have message', () {
      final exception = ChallengeValidationErrorInvalidHomeDomain('domain error');
      expect(exception.toString(), contains('domain error'));
    });

    test('ChallengeValidationErrorInvalidWebAuthDomain should have message', () {
      final exception = ChallengeValidationErrorInvalidWebAuthDomain('web auth domain error');
      expect(exception.toString(), contains('web auth domain error'));
    });

    test('ChallengeValidationErrorInvalidMemoValue should have message', () {
      final exception = ChallengeValidationErrorInvalidMemoValue('memo error');
      expect(exception.toString(), contains('memo error'));
    });

    test('ChallengeValidationErrorInvalidMemoType should have message', () {
      final exception = ChallengeValidationErrorInvalidMemoType('memo type error');
      expect(exception.toString(), contains('memo type error'));
    });
  });
}
