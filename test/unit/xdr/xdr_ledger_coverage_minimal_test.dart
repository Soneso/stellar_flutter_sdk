import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('XdrClaimableBalanceID setters', () {
    test('should set discriminant and v0', () {
      final balanceId = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceId.discriminant = XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0;
      expect(balanceId.discriminant, equals(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0));

      final hash = XdrHash(Uint8List(32));
      balanceId.v0 = hash;
      expect(balanceId.v0, equals(hash));
    });
  });

  group('XdrClaimableBalanceEntryExt setters', () {
    test('should set discriminant', () {
      final ext = XdrClaimableBalanceEntryExt(0);
      ext.discriminant = 1;
      expect(ext.discriminant, equals(1));
    });
  });
}
