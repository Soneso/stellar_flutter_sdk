// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_storage_serialization.dart';

void main() {
  group('_statusFromName via SerializableCredential.toStoredCredential', () {
    test('knownStatus_pending_roundTrips', () {
      final cred = SerializableCredential(
        credentialId: 'cred-001',
        publicKeyHex: '04' + ('aa' * 32),
        deploymentStatus: 'pending',
        createdAt: 1700000000000,
      );
      final stored = cred.toStoredCredential();
      expect(stored.deploymentStatus.name, 'pending');
    });

    test('knownStatus_failed_roundTrips', () {
      final cred = SerializableCredential(
        credentialId: 'cred-001',
        publicKeyHex: '04' + ('aa' * 32),
        deploymentStatus: 'failed',
        createdAt: 1700000000000,
      );
      final stored = cred.toStoredCredential();
      expect(stored.deploymentStatus.name, 'failed');
    });

    test('unknownStatus_throwsArgumentError', () {
      final cred = SerializableCredential(
        credentialId: 'cred-001',
        publicKeyHex: '04' + ('aa' * 32),
        deploymentStatus: 'not_a_real_status',
        createdAt: 1700000000000,
      );
      expect(() => cred.toStoredCredential(), throwsArgumentError);
    });
  });

  group('SerializableCredential.fromJson nullable helpers', () {
    test('nullableString_wrongType_throwsFormatException', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'publicKeyHex': '04' + ('aa' * 32),
        'createdAt': 1700000000000,
        'nickname': 42, // wrong type — should be String or null
      };
      expect(
        () => SerializableCredential.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('nullableInt_wrongType_throwsFormatException', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'publicKeyHex': '04' + ('aa' * 32),
        'createdAt': 1700000000000,
        'lastUsedAt': 'not-an-int', // wrong type
      };
      expect(
        () => SerializableCredential.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('nullableBool_wrongType_throwsFormatException', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'publicKeyHex': '04' + ('aa' * 32),
        'createdAt': 1700000000000,
        'backedUp': 'yes', // wrong type — should be bool or null
      };
      expect(
        () => SerializableCredential.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('nullableStringList_wrongType_throwsFormatException', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'publicKeyHex': '04' + ('aa' * 32),
        'createdAt': 1700000000000,
        'transports': 'internal', // wrong type — should be List or null
      };
      expect(
        () => SerializableCredential.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('nullableString_null_returnsNull', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'publicKeyHex': '04' + ('aa' * 32),
        'createdAt': 1700000000000,
        'nickname': null,
      };
      final cred = SerializableCredential.fromJson(json);
      expect(cred.nickname, isNull);
    });

    test('nullableStringList_null_returnsNull', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'publicKeyHex': '04' + ('aa' * 32),
        'createdAt': 1700000000000,
        'transports': null,
      };
      final cred = SerializableCredential.fromJson(json);
      expect(cred.transports, isNull);
    });
  });

  group('SerializableSession.fromJson nullable helpers', () {
    test('session_missingCredentialId_throwsFormatException', () {
      final json = <String, dynamic>{
        'contractId': 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
        'connectedAt': 1700000000000,
        'expiresAt': 1700604800000,
      };
      expect(
        () => SerializableSession.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('session_missingContractId_throwsFormatException', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'connectedAt': 1700000000000,
        'expiresAt': 1700604800000,
      };
      expect(
        () => SerializableSession.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('session_missingConnectedAt_throwsFormatException', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'contractId': 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
        'expiresAt': 1700604800000,
      };
      expect(
        () => SerializableSession.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('session_missingExpiresAt_throwsFormatException', () {
      final json = <String, dynamic>{
        'credentialId': 'cred-001',
        'contractId': 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
        'connectedAt': 1700000000000,
      };
      expect(
        () => SerializableSession.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('session_roundTrip_allFieldsPreserved', () {
      final session = SerializableSession(
        credentialId: 'cred-001',
        contractId: 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM',
        connectedAt: 1700000000000,
        expiresAt: 1700604800000,
      );
      final json = session.toJson();
      final decoded = SerializableSession.fromJson(json);
      expect(decoded.credentialId, session.credentialId);
      expect(decoded.contractId, session.contractId);
      expect(decoded.connectedAt, session.connectedAt);
      expect(decoded.expiresAt, session.expiresAt);
    });
  });

  group('CredentialIndex.fromJson', () {
    test('missingIds_throwsFormatException', () {
      expect(
        () => CredentialIndex.fromJson(<String, dynamic>{}),
        throwsA(isA<FormatException>()),
      );
    });

    test('nonListIds_throwsFormatException', () {
      expect(
        () => CredentialIndex.fromJson(<String, dynamic>{'ids': 'not-a-list'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('emptyList_succeeds', () {
      final index = CredentialIndex.fromJson(<String, dynamic>{'ids': <dynamic>[]});
      expect(index.ids, isEmpty);
    });

    test('populatedList_roundTrips', () {
      final original = const CredentialIndex(ids: <String>['cred-1', 'cred-2']);
      final decoded = CredentialIndex.fromJson(original.toJson());
      expect(decoded.ids, <String>['cred-1', 'cred-2']);
    });
  });
}
