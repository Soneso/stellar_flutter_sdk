import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/soroban/contract_address_guard.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'contract_address_guard_fixtures.dart';

void main() {
  test('checkContractAddress names a secret seed without repeating it', () {
    expect(StrKey.isValidStellarSecretSeed(secretSeed), isTrue);
    expect(
      () => checkContractAddress(secretSeed, 'The contract to invoke'),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          allOf(
            'The contract to invoke must be a contract (C...) address, got a '
            'secret seed (S...) instead of an address',
            isNot(contains(secretSeed)),
          ),
        ),
      ),
    );
  });
}
