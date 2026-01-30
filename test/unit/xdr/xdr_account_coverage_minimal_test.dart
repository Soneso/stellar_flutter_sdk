import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('XdrAccountEntryV1Ext setters', () {
    test('should set discriminant and v2', () {
      final ext = XdrAccountEntryV1Ext(0);
      ext.discriminant = 2;
      expect(ext.discriminant, equals(2));

      final v2 = XdrAccountEntryV2(
        XdrUint32(5),
        XdrUint32(10),
        [],
        XdrAccountEntryV2Ext(0),
      );
      ext.v2 = v2;
      expect(ext.v2, equals(v2));
    });
  });

  group('XdrAccountEntryV2Ext setters', () {
    test('should set discriminant and v3', () {
      final ext = XdrAccountEntryV2Ext(0);
      ext.discriminant = 3;
      expect(ext.discriminant, equals(3));

      final v3 = XdrAccountEntryV3(
        XdrExtensionPoint(0),
        XdrUint32(100),
        XdrUint64(BigInt.from(1000)),
      );
      ext.v3 = v3;
      expect(ext.v3, equals(v3));
    });
  });
}
