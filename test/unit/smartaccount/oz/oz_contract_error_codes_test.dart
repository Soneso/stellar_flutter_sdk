import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('OZContractErrorCodes', () {
    test('contract error codes are correct', () {
      expect(OZContractErrorCodes.mathOverflow, 3012);
      expect(OZContractErrorCodes.keyDataTooLarge, 3013);
      expect(OZContractErrorCodes.contextRuleIdsLengthMismatch, 3014);
      expect(OZContractErrorCodes.nameTooLong, 3015);
      expect(OZContractErrorCodes.unauthorizedSigner, 3016);
    });
  });
}
