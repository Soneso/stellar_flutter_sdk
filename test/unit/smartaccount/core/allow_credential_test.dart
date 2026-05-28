// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('AllowCredential', () {
    test('test_allow_credential_construction_with_id_only', () {
      final id = Uint8List.fromList(const [0x01, 0x02, 0x03]);
      final credential = AllowCredential(id: id);

      expect(credential.id, equals(id));
      expect(credential.transports, isNull);
    });

    test('test_allow_credential_construction_with_id_and_transports', () {
      final id = Uint8List.fromList(const [0x0A, 0x0B, 0x0C]);
      const transports = ['internal', 'hybrid'];
      final credential = AllowCredential(id: id, transports: transports);

      expect(credential.id, equals(id));
      expect(credential.transports, equals(transports));
    });

    test('test_allow_credential_construction_with_explicit_null_transports',
        () {
      final id = Uint8List.fromList(const [0x10, 0x20]);
      final credential = AllowCredential(id: id, transports: null);

      expect(credential.id, equals(id));
      expect(credential.transports, isNull);
    });

    test('test_allow_credential_equals_same_byte_content', () {
      final id1 = Uint8List.fromList(const [0xDE, 0xAD, 0xBE, 0xEF]);
      final id2 = Uint8List.fromList(const [0xDE, 0xAD, 0xBE, 0xEF]);
      const transports = ['internal'];

      final credential1 = AllowCredential(id: id1, transports: transports);
      final credential2 = AllowCredential(id: id2, transports: transports);

      expect(identical(id1, id2), isFalse,
          reason: 'Precondition: id arrays must be distinct references');
      expect(credential1, equals(credential2));
    });

    test('test_allow_credential_equals_with_null_transports', () {
      final id1 = Uint8List.fromList(const [0x01, 0x02]);
      final id2 = Uint8List.fromList(const [0x01, 0x02]);

      final credential1 = AllowCredential(id: id1);
      final credential2 = AllowCredential(id: id2);

      expect(credential1, equals(credential2));
    });

    test('test_allow_credential_not_equal_when_ids_differ', () {
      final credential1 =
          AllowCredential(id: Uint8List.fromList(const [0x01, 0x02]));
      final credential2 =
          AllowCredential(id: Uint8List.fromList(const [0x01, 0x03]));

      expect(credential1, isNot(equals(credential2)));
    });

    test('test_allow_credential_not_equal_when_transports_differ', () {
      final id = Uint8List.fromList(const [0x01, 0x02]);
      final credential1 = AllowCredential(
        id: Uint8List.fromList(id),
        transports: const ['internal'],
      );
      final credential2 = AllowCredential(
        id: Uint8List.fromList(id),
        transports: const ['usb'],
      );

      expect(credential1, isNot(equals(credential2)));
    });

    test('test_allow_credential_not_equal_null_transports_vs_empty_list', () {
      final id = Uint8List.fromList(const [0x01, 0x02]);
      final withNull = AllowCredential(id: Uint8List.fromList(id));
      final withEmpty = AllowCredential(
        id: Uint8List.fromList(id),
        transports: const <String>[],
      );

      expect(withNull, isNot(equals(withEmpty)));
    });

    test(
        'test_allow_credential_not_equal_one_null_other_non_null_transports',
        () {
      final id = Uint8List.fromList(const [0x01, 0x02]);
      final withNull = AllowCredential(id: Uint8List.fromList(id));
      final withValue = AllowCredential(
        id: Uint8List.fromList(id),
        transports: const ['hybrid'],
      );

      expect(withNull, isNot(equals(withValue)));
      expect(withValue, isNot(equals(withNull)));
    });

    test('test_allow_credential_equals_with_self', () {
      final credential = AllowCredential(
        id: Uint8List.fromList(const [0x01, 0x02, 0x03]),
        transports: const ['internal'],
      );

      // ignore: unrelated_type_equality_checks
      expect(credential == credential, isTrue);
    });

    test('test_allow_credential_hashcode_consistency', () {
      final id1 = Uint8List.fromList(const [0x11, 0x22, 0x33]);
      final id2 = Uint8List.fromList(const [0x11, 0x22, 0x33]);
      const transports = ['internal', 'usb'];

      final credential1 = AllowCredential(id: id1, transports: transports);
      final credential2 = AllowCredential(id: id2, transports: transports);

      expect(credential1, equals(credential2));
      expect(credential1.hashCode, equals(credential2.hashCode));
    });

    test('test_allow_credential_hashcode_differs_for_different_objects', () {
      final credential1 = AllowCredential(
        id: Uint8List.fromList(const [0x01]),
        transports: const ['internal'],
      );
      final credential2 = AllowCredential(
        id: Uint8List.fromList(const [0x02]),
        transports: const ['internal'],
      );

      expect(credential1.hashCode, isNot(equals(credential2.hashCode)));
    });

    test('test_allow_credential_hashcode_null_vs_non_null_transports_differs',
        () {
      final id = Uint8List.fromList(const [0x01, 0x02]);
      final withNull = AllowCredential(id: Uint8List.fromList(id));
      final withValue = AllowCredential(
        id: Uint8List.fromList(id),
        transports: const ['internal'],
      );

      expect(withNull.hashCode, isNot(equals(withValue.hashCode)));
    });

    test('test_allow_credential_from_id_creates_credential_with_null_transports',
        () {
      final id = Uint8List.fromList(const [0xAB, 0xCD]);
      final credential = AllowCredential.fromId(id);

      expect(credential.id, equals(id));
      expect(credential.transports, isNull);
    });

    test('test_allow_credential_from_id_equivalent_to_direct_construction',
        () {
      final id = Uint8List.fromList(const [0x01, 0x02, 0x03, 0x04]);
      final fromFactory = AllowCredential.fromId(id);
      final direct = AllowCredential(id: id);

      expect(direct, equals(fromFactory));
    });

    test('test_allow_credential_from_ids_creates_list_with_all_null_transports',
        () {
      final ids = <Uint8List>[
        Uint8List.fromList(const [0x01]),
        Uint8List.fromList(const [0x02, 0x03]),
        Uint8List.fromList(const [0x04, 0x05, 0x06]),
      ];

      final credentials = AllowCredential.fromIds(ids);

      expect(credentials.length, equals(ids.length));
      for (var i = 0; i < ids.length; i++) {
        expect(credentials[i].id, equals(ids[i]));
        expect(credentials[i].transports, isNull);
      }
    });

    test('test_allow_credential_from_ids_empty_list_returns_empty_list', () {
      final credentials = AllowCredential.fromIds(const <Uint8List>[]);

      expect(credentials, isEmpty);
    });

    test('test_allow_credential_from_ids_single_element_list', () {
      final id = Uint8List.fromList(const [0xFF, 0x00]);
      final credentials = AllowCredential.fromIds(<Uint8List>[id]);

      expect(credentials.length, equals(1));
      expect(credentials[0].id, equals(id));
      expect(credentials[0].transports, isNull);
    });

    test('test_allow_credential_common_transport_values_preserved', () {
      final id = Uint8List.fromList(const [0x01]);
      const transports = ['internal', 'hybrid', 'usb', 'ble', 'nfc'];
      final credential = AllowCredential(id: id, transports: transports);

      expect(credential.transports, equals(transports));
      expect(credential.transports!.length, equals(5));
      expect(credential.transports!.contains('internal'), isTrue);
      expect(credential.transports!.contains('hybrid'), isTrue);
      expect(credential.transports!.contains('usb'), isTrue);
      expect(credential.transports!.contains('ble'), isTrue);
      expect(credential.transports!.contains('nfc'), isTrue);
    });

    test('test_allow_credential_transport_order_preserved', () {
      final id = Uint8List.fromList(const [0x01]);
      const transports = ['nfc', 'usb', 'internal'];
      final credential = AllowCredential(id: id, transports: transports);

      expect(credential.transports![0], equals('nfc'));
      expect(credential.transports![1], equals('usb'));
      expect(credential.transports![2], equals('internal'));
    });

    test('test_allow_credential_id_stored_by_reference_not_copied', () {
      // Dart Uint8List is a typed list with reference semantics: mutating the
      // original array is reflected in the stored id (no defensive copy is
      // performed).
      final originalId = Uint8List.fromList(const [0x01, 0x02, 0x03]);
      final credential = AllowCredential(id: originalId);

      expect(credential.id[0], equals(0x01));
      expect(identical(credential.id, originalId), isTrue);

      originalId[0] = 0xFF;

      // The stored id reflects the mutation because it shares the same
      // reference.
      expect(credential.id[0], equals(0xFF));
    });

    test('test_allow_credential_copy_of_id_is_independent', () {
      // When callers want isolation they must copy the array themselves.
      final originalId = Uint8List.fromList(const [0x01, 0x02, 0x03]);
      final credential = AllowCredential(id: Uint8List.fromList(originalId));

      originalId[0] = 0xFF;

      // The credential id was constructed from a copy — it is unaffected.
      expect(credential.id[0], equals(0x01));
    });
  });
}
