// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Tests for XDR SCP types that go beyond simple roundtrip encode/decode.
  // Focuses on: throws on unknown enum, nested structures, optional fields, edge cases.
  // Simple roundtrips are covered by auto-generated tests in test/unit/xdr/generated/.

  group('Enum throws on unknown value', () {
    test('XdrSCPStatementType throws on unknown value', () {
      final output = XdrDataOutputStream();
      output.writeInt(999);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(() => XdrSCPStatementType.decode(input), throwsException);
    });

    test('XdrPublicKeyType throws on unknown value', () {
      final output = XdrDataOutputStream();
      output.writeInt(999);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(() => XdrPublicKeyType.decode(input), throwsException);
    });

    test('XdrCryptoKeyType throws on unknown value', () {
      final output = XdrDataOutputStream();
      output.writeInt(555);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(() => XdrCryptoKeyType.decode(input), throwsException);
    });
  });

  group('XdrSCPQuorumSet nested innerSets', () {
    test('XdrSCPQuorumSet with nested innerSets', () {
      var innerQSet = XdrSCPQuorumSet(XdrUint32(1), [], []);

      var original = XdrSCPQuorumSet(XdrUint32(1), [], [innerQSet]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.validators, isEmpty);
      expect(decoded.innerSets.length, equals(1));
      expect(decoded.innerSets[0].threshold.uint32, equals(1));
    });

    test('XdrSCPQuorumSet with validators and nested inner set', () {
      final validator1 = XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      final innerSet = XdrSCPQuorumSet(
        XdrUint32(1),
        [XdrNodeID(validator1)],
        [],
      );

      final quorumSet = XdrSCPQuorumSet(XdrUint32(1), [], [innerSet]);

      final output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, quorumSet);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.innerSets.length, equals(1));
      expect(decoded.innerSets[0].validators.length, equals(1));
    });

    test('XdrSCPQuorumSet with empty validators and innerSets', () {
      var original = XdrSCPQuorumSet(XdrUint32(2), [], []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.validators, isEmpty);
      expect(decoded.innerSets, isEmpty);
    });
  });

  group('XdrSCPStatementPrepare optional fields', () {
    test('XdrSCPStatementPrepare with null prepared and preparedPrime', () {
      var ballot = XdrSCPBallot(
        XdrUint32(100),
        XdrValue(Uint8List.fromList([1, 2, 3])),
      );

      var original = XdrSCPStatementPrepare(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC))),
        ballot,
        null,
        null,
        XdrUint32(50),
        XdrUint32(75),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementPrepare.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementPrepare.decode(input);

      expect(decoded.prepared, isNull);
      expect(decoded.preparedPrime, isNull);
      expect(decoded.nC.uint32, equals(50));
      expect(decoded.nH.uint32, equals(75));
    });

    test('XdrSCPStatementPrepare with non-null prepared and preparedPrime', () {
      var ballot = XdrSCPBallot(
        XdrUint32(100),
        XdrValue(Uint8List.fromList([1, 2, 3])),
      );
      var prepared = XdrSCPBallot(
        XdrUint32(90),
        XdrValue(Uint8List.fromList([4, 5, 6])),
      );
      var preparedPrime = XdrSCPBallot(
        XdrUint32(85),
        XdrValue(Uint8List.fromList([7, 8, 9])),
      );

      var original = XdrSCPStatementPrepare(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD))),
        ballot,
        prepared,
        preparedPrime,
        XdrUint32(80),
        XdrUint32(95),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementPrepare.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementPrepare.decode(input);

      expect(decoded.prepared, isNotNull);
      expect(decoded.prepared!.counter.uint32, equals(90));
      expect(decoded.preparedPrime, isNotNull);
      expect(decoded.preparedPrime!.counter.uint32, equals(85));
    });

    test('XdrSCPStatementPrepare with only prepared (no preparedPrime)', () {
      final hashBytes = Uint8List(32);
      final value1 = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final value2 = XdrValue(Uint8List.fromList([5, 6, 7, 8]));
      final ballot = XdrSCPBallot(XdrUint32(20), value1);
      final prepared = XdrSCPBallot(XdrUint32(18), value2);

      final prepare = XdrSCPStatementPrepare(
        XdrHash(hashBytes),
        ballot,
        prepared,
        null,
        XdrUint32(1),
        XdrUint32(2),
      );

      final output = XdrDataOutputStream();
      XdrSCPStatementPrepare.encode(output, prepare);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementPrepare.decode(input);

      expect(decoded.prepared, isNotNull);
      expect(decoded.prepared!.counter.uint32, equals(18));
      expect(decoded.preparedPrime, isNull);
    });
  });

  group('XdrPublicKey.forAccountId factory', () {
    test('creates public key from account ID', () {
      final accountId = 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';
      final publicKey = XdrPublicKey.forAccountId(accountId);

      expect(publicKey.discriminant, equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      expect(publicKey.getEd25519(), isNotNull);
      expect(publicKey.getEd25519()!.uint256.length, equals(32));
    });
  });

  group('XdrSCPNomination empty vs non-empty', () {
    test('XdrSCPNomination with empty votes and accepted', () {
      var original = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA))),
        [],
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPNomination.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPNomination.decode(input);

      expect(decoded.votes, isEmpty);
      expect(decoded.accepted, isEmpty);
    });

    test('XdrSCPNomination with votes and accepted', () {
      var original = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB))),
        [
          XdrValue(Uint8List.fromList([1, 2, 3])),
          XdrValue(Uint8List.fromList([4, 5, 6])),
        ],
        [
          XdrValue(Uint8List.fromList([7, 8, 9])),
        ],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPNomination.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPNomination.decode(input);

      expect(decoded.votes.length, equals(2));
      expect(decoded.accepted.length, equals(1));
    });
  });

  group('XdrSCPBallot edge cases', () {
    test('XdrSCPBallot handles zero counter', () {
      final value = XdrValue(Uint8List.fromList([0, 0, 0, 0]));
      final ballot = XdrSCPBallot(XdrUint32(0), value);

      final output = XdrDataOutputStream();
      XdrSCPBallot.encode(output, ballot);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPBallot.decode(input);

      expect(decoded.counter.uint32, equals(0));
    });
  });

  group('XdrUpgradeType edge cases', () {
    test('XdrUpgradeType handles empty upgrade type', () {
      final data = Uint8List(0);
      final upgradeType = XdrUpgradeType(data);

      final output = XdrDataOutputStream();
      XdrUpgradeType.encode(output, upgradeType);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrUpgradeType.decode(input);

      expect(decoded.upgradeType.length, equals(0));
    });
  });

  group('XdrThresholds max values', () {
    test('XdrThresholds handles maximum threshold values', () {
      final thresholds = Uint8List.fromList([255, 255, 255, 255]);
      final xdrThresholds = XdrThresholds(thresholds);

      final output = XdrDataOutputStream();
      XdrThresholds.encode(output, xdrThresholds);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrThresholds.decode(input);

      expect(decoded.thresholds.every((t) => t == 255), isTrue);
    });
  });

  group('XdrValue edge cases', () {
    test('XdrValue handles large values', () {
      final data = Uint8List(100);
      for (int i = 0; i < 100; i++) {
        data[i] = i % 256;
      }
      final value = XdrValue(data);

      final output = XdrDataOutputStream();
      XdrValue.encode(output, value);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrValue.decode(input);

      expect(decoded.value.length, equals(100));
      expect(decoded.value, equals(data));
    });
  });
}
