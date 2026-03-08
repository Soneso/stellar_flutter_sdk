import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';
import 'dart:typed_data';

/// Tests for error paths and byte-level encoding verification
/// in ledger-related XDR types.
void main() {
  group('XdrLedgerEntryChangeType decode edge cases', () {
    test('should_throw_exception_when_unknown_enum_value_provided', () {
      // Arrange - Create stream with invalid discriminant value 99
      final bytes = Uint8List.fromList([0, 0, 0, 99]); // Big-endian int 99
      final stream = XdrDataInputStream(bytes);

      // Act & Assert - Should throw exception for unknown enum value
      expect(
        () => XdrLedgerEntryChangeType.decode(stream),
        throwsA(predicate((e) =>
          e is Exception && e.toString().contains("Unknown enum value: 99"))),
      );
    });

    test('should_encode_LEDGER_ENTRY_RESTORED_correctly', () {
      // Arrange
      final stream = XdrDataOutputStream();
      final changeType = XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED;

      // Act - This will fail if encode path is uncovered
      XdrLedgerEntryChangeType.encode(stream, changeType);

      // Assert - Check encoded bytes match expected value
      final bytes = stream.bytes;
      final expectedBytes = Uint8List.fromList([0, 0, 0, 4]); // Big-endian 4
      expect(bytes, equals(expectedBytes));
    });
  });

  group('XdrLedgerEntryType decode edge cases', () {
    test('should_throw_exception_when_invalid_ledger_entry_type', () {
      // Arrange
      final bytes = Uint8List.fromList([0, 0, 0, 255]); // Invalid value 255
      final stream = XdrDataInputStream(bytes);

      // Act & Assert - Should throw for unknown enum value
      expect(
        () => XdrLedgerEntryType.decode(stream),
        throwsA(predicate((e) =>
          e is Exception && e.toString().contains("Unknown enum value: 255"))),
      );
    });
  });

  group('XdrClaimPredicateType decode branches', () {
    test('should_throw_exception_for_invalid_claim_predicate_type', () {
      // Arrange
      final bytes = Uint8List.fromList([0, 0, 0, 100]); // Invalid value 100
      final stream = XdrDataInputStream(bytes);

      // Act & Assert
      expect(
        () => XdrClaimPredicateType.decode(stream),
        throwsA(predicate((e) =>
          e is Exception && e.toString().contains("Unknown enum value: 100"))),
      );
    });
  });

  group('XdrLedgerUpgradeType decode branches', () {
    test('should_throw_exception_for_invalid_ledger_upgrade_type', () {
      // Arrange
      final bytes = Uint8List.fromList([0, 0, 0, 200]); // Invalid value 200
      final stream = XdrDataInputStream(bytes);

      // Act & Assert
      expect(
        () => XdrLedgerUpgradeType.decode(stream),
        throwsA(predicate((e) =>
          e is Exception && e.toString().contains("Unknown enum value: 200"))),
      );
    });
  });
}
