// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR SCP Types - Deep Branch Testing', () {
    test('XdrSCPStatementType enum all variants', () {
      final types = [
        XdrSCPStatementType.SCP_ST_PREPARE,
        XdrSCPStatementType.SCP_ST_CONFIRM,
        XdrSCPStatementType.SCP_ST_EXTERNALIZE,
        XdrSCPStatementType.SCP_ST_NOMINATE,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCPStatementType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCPStatementType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrSCPBallot encode/decode round-trip', () {
      var original = XdrSCPBallot(
        XdrUint32(12345),
        XdrValue(Uint8List.fromList([1, 2, 3, 4, 5])),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPBallot.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPBallot.decode(input);

      expect(decoded.counter.uint32, equals(original.counter.uint32));
      expect(decoded.value.value, equals(original.value.value));
    });

    test('XdrSCPNomination encode/decode with empty votes and accepted', () {
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

      expect(decoded.quorumSetHash.hash, equals(original.quorumSetHash.hash));
      expect(decoded.votes, isEmpty);
      expect(decoded.accepted, isEmpty);
    });

    test('XdrSCPNomination encode/decode with votes and accepted', () {
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

      expect(decoded.quorumSetHash.hash, equals(original.quorumSetHash.hash));
      expect(decoded.votes.length, equals(2));
      expect(decoded.votes[0].value, equals(original.votes[0].value));
      expect(decoded.votes[1].value, equals(original.votes[1].value));
      expect(decoded.accepted.length, equals(1));
      expect(decoded.accepted[0].value, equals(original.accepted[0].value));
    });

    test('XdrSCPQuorumSet encode/decode with empty validators and innerSets', () {
      var original = XdrSCPQuorumSet(
        XdrUint32(2),
        [],
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.threshold.uint32, equals(original.threshold.uint32));
      expect(decoded.validators, isEmpty);
      expect(decoded.innerSets, isEmpty);
    });

    test('XdrSCPQuorumSet encode/decode with validators', () {
      var pk1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk1.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));

      var pk2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk2.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22))));

      var original = XdrSCPQuorumSet(
        XdrUint32(2),
        [pk1, pk2],
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.threshold.uint32, equals(original.threshold.uint32));
      expect(decoded.validators.length, equals(2));
      expect(decoded.innerSets, isEmpty);
    });

    test('XdrSCPQuorumSet encode/decode with nested innerSets', () {
      var innerQSet = XdrSCPQuorumSet(
        XdrUint32(1),
        [],
        [],
      );

      var original = XdrSCPQuorumSet(
        XdrUint32(1),
        [],
        [innerQSet],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.threshold.uint32, equals(original.threshold.uint32));
      expect(decoded.validators, isEmpty);
      expect(decoded.innerSets.length, equals(1));
      expect(decoded.innerSets[0].threshold.uint32, equals(innerQSet.threshold.uint32));
    });

    test('XdrSCPStatementPrepare encode/decode with null prepared and preparedPrime', () {
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

      expect(decoded.quorumSetHash.hash, equals(original.quorumSetHash.hash));
      expect(decoded.ballot.counter.uint32, equals(original.ballot.counter.uint32));
      expect(decoded.prepared, isNull);
      expect(decoded.preparedPrime, isNull);
      expect(decoded.nC.uint32, equals(original.nC.uint32));
      expect(decoded.nH.uint32, equals(original.nH.uint32));
    });

    test('XdrSCPStatementPrepare encode/decode with non-null prepared and preparedPrime', () {
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

      expect(decoded.quorumSetHash.hash, equals(original.quorumSetHash.hash));
      expect(decoded.ballot.counter.uint32, equals(original.ballot.counter.uint32));
      expect(decoded.prepared, isNotNull);
      expect(decoded.prepared!.counter.uint32, equals(prepared.counter.uint32));
      expect(decoded.preparedPrime, isNotNull);
      expect(decoded.preparedPrime!.counter.uint32, equals(preparedPrime.counter.uint32));
      expect(decoded.nC.uint32, equals(original.nC.uint32));
      expect(decoded.nH.uint32, equals(original.nH.uint32));
    });

    test('XdrSCPStatementConfirm encode/decode round-trip', () {
      var ballot = XdrSCPBallot(
        XdrUint32(200),
        XdrValue(Uint8List.fromList([10, 20, 30])),
      );

      var original = XdrSCPStatementConfirm(
        ballot,
        XdrUint32(150),
        XdrUint32(175),
        XdrUint32(190),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE))),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementConfirm.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementConfirm.decode(input);

      expect(decoded.ballot.counter.uint32, equals(original.ballot.counter.uint32));
      expect(decoded.nPrepared.uint32, equals(original.nPrepared.uint32));
      expect(decoded.nCommit.uint32, equals(original.nCommit.uint32));
      expect(decoded.nH.uint32, equals(original.nH.uint32));
      expect(decoded.quorumSetHash.hash, equals(original.quorumSetHash.hash));
    });

    test('XdrSCPStatementExternalize encode/decode round-trip', () {
      var commit = XdrSCPBallot(
        XdrUint32(300),
        XdrValue(Uint8List.fromList([100, 200])),
      );

      var original = XdrSCPStatementExternalize(
        commit,
        XdrUint32(295),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF))),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementExternalize.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementExternalize.decode(input);

      expect(decoded.commit.counter.uint32, equals(original.commit.counter.uint32));
      expect(decoded.nH.uint32, equals(original.nH.uint32));
      expect(decoded.commitQuorumSetHash.hash, equals(original.commitQuorumSetHash.hash));
    });

    test('XdrSCPStatementPledges PREPARE discriminant encode/decode', () {
      var ballot = XdrSCPBallot(
        XdrUint32(50),
        XdrValue(Uint8List.fromList([1, 2])),
      );

      var prepare = XdrSCPStatementPrepare(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11))),
        ballot,
        null,
        null,
        XdrUint32(40),
        XdrUint32(45),
      );

      var original = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_PREPARE);
      original.prepare = prepare;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementPledges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementPledges.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCPStatementType.SCP_ST_PREPARE.value));
      expect(decoded.prepare, isNotNull);
      expect(decoded.prepare!.ballot.counter.uint32, equals(ballot.counter.uint32));
    });

    test('XdrSCPStatementPledges CONFIRM discriminant encode/decode', () {
      var ballot = XdrSCPBallot(
        XdrUint32(100),
        XdrValue(Uint8List.fromList([3, 4])),
      );

      var confirm = XdrSCPStatementConfirm(
        ballot,
        XdrUint32(90),
        XdrUint32(95),
        XdrUint32(98),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22))),
      );

      var original = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_CONFIRM);
      original.confirm = confirm;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementPledges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementPledges.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCPStatementType.SCP_ST_CONFIRM.value));
      expect(decoded.confirm, isNotNull);
      expect(decoded.confirm!.ballot.counter.uint32, equals(ballot.counter.uint32));
    });

    test('XdrSCPStatementPledges EXTERNALIZE discriminant encode/decode', () {
      var commit = XdrSCPBallot(
        XdrUint32(200),
        XdrValue(Uint8List.fromList([5, 6])),
      );

      var externalize = XdrSCPStatementExternalize(
        commit,
        XdrUint32(195),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33))),
      );

      var original = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_EXTERNALIZE);
      original.externalize = externalize;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementPledges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementPledges.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCPStatementType.SCP_ST_EXTERNALIZE.value));
      expect(decoded.externalize, isNotNull);
      expect(decoded.externalize!.commit.counter.uint32, equals(commit.counter.uint32));
    });

    test('XdrSCPStatementPledges NOMINATE discriminant encode/decode', () {
      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x44))),
        [XdrValue(Uint8List.fromList([7, 8]))],
        [],
      );

      var original = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      original.nominate = nomination;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatementPledges.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatementPledges.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCPStatementType.SCP_ST_NOMINATE.value));
      expect(decoded.nominate, isNotNull);
      expect(decoded.nominate!.votes.length, equals(1));
    });

    test('XdrSCPStatement encode/decode round-trip', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55))));
      var nodeID = XdrNodeID(pk);

      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x66))),
        [],
        [],
      );

      var pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      var original = XdrSCPStatement(
        nodeID,
        XdrUint64(BigInt.from(12345)),
        pledges,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPStatement.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPStatement.decode(input);

      expect(decoded.slotIndex.uint64, equals(original.slotIndex.uint64));
      expect(decoded.pledges.discriminant.value, equals(original.pledges.discriminant.value));
    });

    test('XdrSCPEnvelope encode/decode round-trip', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x77))));
      var nodeID = XdrNodeID(pk);

      var nomination = XdrSCPNomination(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88))),
        [],
        [],
      );

      var pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      var statement = XdrSCPStatement(
        nodeID,
        XdrUint64(BigInt.from(99999)),
        pledges,
      );

      var signature = XdrSignature(Uint8List.fromList(List<int>.filled(64, 0x99)));

      var original = XdrSCPEnvelope(statement, signature);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCPEnvelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCPEnvelope.decode(input);

      expect(decoded.statement.slotIndex.uint64, equals(original.statement.slotIndex.uint64));
      expect(decoded.signature.signature, equals(original.signature.signature));
    });
  });

  group('XdrSCPStatementType enum', () {
    test('encodes and decodes SCP_ST_PREPARE', () {
      final output = XdrDataOutputStream();
      XdrSCPStatementType.encode(output, XdrSCPStatementType.SCP_ST_PREPARE);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementType.decode(input);

      expect(decoded, equals(XdrSCPStatementType.SCP_ST_PREPARE));
      expect(decoded.value, equals(0));
    });

    test('encodes and decodes SCP_ST_CONFIRM', () {
      final output = XdrDataOutputStream();
      XdrSCPStatementType.encode(output, XdrSCPStatementType.SCP_ST_CONFIRM);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementType.decode(input);

      expect(decoded, equals(XdrSCPStatementType.SCP_ST_CONFIRM));
      expect(decoded.value, equals(1));
    });

    test('encodes and decodes SCP_ST_EXTERNALIZE', () {
      final output = XdrDataOutputStream();
      XdrSCPStatementType.encode(output, XdrSCPStatementType.SCP_ST_EXTERNALIZE);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementType.decode(input);

      expect(decoded, equals(XdrSCPStatementType.SCP_ST_EXTERNALIZE));
      expect(decoded.value, equals(2));
    });

    test('encodes and decodes SCP_ST_NOMINATE', () {
      final output = XdrDataOutputStream();
      XdrSCPStatementType.encode(output, XdrSCPStatementType.SCP_ST_NOMINATE);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementType.decode(input);

      expect(decoded, equals(XdrSCPStatementType.SCP_ST_NOMINATE));
      expect(decoded.value, equals(3));
    });

    test('throws on unknown value', () {
      final output = XdrDataOutputStream();
      output.writeInt(999);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(() => XdrSCPStatementType.decode(input), throwsException);
    });
  });

  group('XdrSCPBallot encode/decode', () {
    test('encodes and decodes ballot with value', () {
      final value = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final ballot = XdrSCPBallot(XdrUint32(42), value);

      final output = XdrDataOutputStream();
      XdrSCPBallot.encode(output, ballot);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPBallot.decode(input);

      expect(decoded.counter.uint32, equals(42));
      expect(decoded.value.value, equals(Uint8List.fromList([1, 2, 3, 4])));
    });

    test('handles zero counter', () {
      final value = XdrValue(Uint8List.fromList([0, 0, 0, 0]));
      final ballot = XdrSCPBallot(XdrUint32(0), value);

      final output = XdrDataOutputStream();
      XdrSCPBallot.encode(output, ballot);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPBallot.decode(input);

      expect(decoded.counter.uint32, equals(0));
    });
  });

  group('XdrSCPEnvelope encode/decode', () {
    test('encodes and decodes envelope with statement', () {
      final nodeId = XdrNodeID(XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'));

      final hashBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        hashBytes[i] = i;
      }

      final nomination = XdrSCPNomination(
        XdrHash(hashBytes),
        [],
        [],
      );

      final pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      final statement = XdrSCPStatement(
        nodeId,
        XdrUint64(BigInt.from(12345)),
        pledges,
      );

      final signature = XdrSignature(Uint8List(64));

      final envelope = XdrSCPEnvelope(statement, signature);

      final output = XdrDataOutputStream();
      XdrSCPEnvelope.encode(output, envelope);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPEnvelope.decode(input);

      expect(decoded.statement.slotIndex.uint64, equals(BigInt.from(12345)));
      expect(decoded.signature.signature.length, equals(64));
    });
  });

  group('XdrSCPNomination encode/decode', () {
    test('encodes and decodes nomination with empty votes', () {
      final hashBytes = Uint8List(32);
      final nomination = XdrSCPNomination(
        XdrHash(hashBytes),
        [],
        [],
      );

      final output = XdrDataOutputStream();
      XdrSCPNomination.encode(output, nomination);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPNomination.decode(input);

      expect(decoded.votes, isEmpty);
      expect(decoded.accepted, isEmpty);
    });

    test('encodes and decodes nomination with votes', () {
      final hashBytes = Uint8List(32);
      final vote1 = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final vote2 = XdrValue(Uint8List.fromList([5, 6, 7, 8]));

      final nomination = XdrSCPNomination(
        XdrHash(hashBytes),
        [vote1, vote2],
        [],
      );

      final output = XdrDataOutputStream();
      XdrSCPNomination.encode(output, nomination);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPNomination.decode(input);

      expect(decoded.votes.length, equals(2));
      expect(decoded.accepted, isEmpty);
    });

    test('encodes and decodes nomination with accepted values', () {
      final hashBytes = Uint8List(32);
      final accepted1 = XdrValue(Uint8List.fromList([9, 10, 11, 12]));

      final nomination = XdrSCPNomination(
        XdrHash(hashBytes),
        [],
        [accepted1],
      );

      final output = XdrDataOutputStream();
      XdrSCPNomination.encode(output, nomination);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPNomination.decode(input);

      expect(decoded.votes, isEmpty);
      expect(decoded.accepted.length, equals(1));
    });
  });

  group('XdrSCPStatement encode/decode', () {
    test('encodes and decodes statement with NOMINATE', () {
      final nodeId = XdrNodeID(XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'));

      final hashBytes = Uint8List(32);
      final nomination = XdrSCPNomination(
        XdrHash(hashBytes),
        [],
        [],
      );

      final pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_NOMINATE);
      pledges.nominate = nomination;

      final statement = XdrSCPStatement(
        nodeId,
        XdrUint64(BigInt.from(999)),
        pledges,
      );

      final output = XdrDataOutputStream();
      XdrSCPStatement.encode(output, statement);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatement.decode(input);

      expect(decoded.slotIndex.uint64, equals(BigInt.from(999)));
      expect(decoded.pledges.discriminant, equals(XdrSCPStatementType.SCP_ST_NOMINATE));
    });

    test('encodes and decodes statement with PREPARE', () {
      final nodeId = XdrNodeID(XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'));

      final hashBytes = Uint8List(32);
      final value = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final ballot = XdrSCPBallot(XdrUint32(10), value);

      final prepare = XdrSCPStatementPrepare(
        XdrHash(hashBytes),
        ballot,
        null,
        null,
        XdrUint32(0),
        XdrUint32(0),
      );

      final pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_PREPARE);
      pledges.prepare = prepare;

      final statement = XdrSCPStatement(
        nodeId,
        XdrUint64(BigInt.from(1000)),
        pledges,
      );

      final output = XdrDataOutputStream();
      XdrSCPStatement.encode(output, statement);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatement.decode(input);

      expect(decoded.slotIndex.uint64, equals(BigInt.from(1000)));
      expect(decoded.pledges.discriminant, equals(XdrSCPStatementType.SCP_ST_PREPARE));
      expect(decoded.pledges.prepare, isNotNull);
    });

    test('encodes and decodes statement with CONFIRM', () {
      final nodeId = XdrNodeID(XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'));

      final hashBytes = Uint8List(32);
      final value = XdrValue(Uint8List.fromList([5, 6, 7, 8]));
      final ballot = XdrSCPBallot(XdrUint32(20), value);

      final confirm = XdrSCPStatementConfirm(
        ballot,
        XdrUint32(1),
        XdrUint32(2),
        XdrUint32(3),
        XdrHash(hashBytes),
      );

      final pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_CONFIRM);
      pledges.confirm = confirm;

      final statement = XdrSCPStatement(
        nodeId,
        XdrUint64(BigInt.from(2000)),
        pledges,
      );

      final output = XdrDataOutputStream();
      XdrSCPStatement.encode(output, statement);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatement.decode(input);

      expect(decoded.slotIndex.uint64, equals(BigInt.from(2000)));
      expect(decoded.pledges.discriminant, equals(XdrSCPStatementType.SCP_ST_CONFIRM));
      expect(decoded.pledges.confirm, isNotNull);
    });

    test('encodes and decodes statement with EXTERNALIZE', () {
      final nodeId = XdrNodeID(XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H'));

      final hashBytes = Uint8List(32);
      final value = XdrValue(Uint8List.fromList([9, 10, 11, 12]));
      final ballot = XdrSCPBallot(XdrUint32(30), value);

      final externalize = XdrSCPStatementExternalize(
        ballot,
        XdrUint32(5),
        XdrHash(hashBytes),
      );

      final pledges = XdrSCPStatementPledges(XdrSCPStatementType.SCP_ST_EXTERNALIZE);
      pledges.externalize = externalize;

      final statement = XdrSCPStatement(
        nodeId,
        XdrUint64(BigInt.from(3000)),
        pledges,
      );

      final output = XdrDataOutputStream();
      XdrSCPStatement.encode(output, statement);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatement.decode(input);

      expect(decoded.slotIndex.uint64, equals(BigInt.from(3000)));
      expect(decoded.pledges.discriminant, equals(XdrSCPStatementType.SCP_ST_EXTERNALIZE));
      expect(decoded.pledges.externalize, isNotNull);
    });
  });

  group('XdrSCPStatementPrepare encode/decode', () {
    test('encodes and decodes prepare with no optional ballots', () {
      final hashBytes = Uint8List(32);
      final value = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final ballot = XdrSCPBallot(XdrUint32(15), value);

      final prepare = XdrSCPStatementPrepare(
        XdrHash(hashBytes),
        ballot,
        null,
        null,
        XdrUint32(0),
        XdrUint32(0),
      );

      final output = XdrDataOutputStream();
      XdrSCPStatementPrepare.encode(output, prepare);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementPrepare.decode(input);

      expect(decoded.ballot.counter.uint32, equals(15));
      expect(decoded.prepared, isNull);
      expect(decoded.preparedPrime, isNull);
    });

    test('encodes and decodes prepare with prepared ballot', () {
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

      expect(decoded.ballot.counter.uint32, equals(20));
      expect(decoded.prepared, isNotNull);
      expect(decoded.prepared!.counter.uint32, equals(18));
      expect(decoded.preparedPrime, isNull);
    });

    test('encodes and decodes prepare with both prepared and preparedPrime', () {
      final hashBytes = Uint8List(32);
      final value1 = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final value2 = XdrValue(Uint8List.fromList([5, 6, 7, 8]));
      final value3 = XdrValue(Uint8List.fromList([9, 10, 11, 12]));
      final ballot = XdrSCPBallot(XdrUint32(25), value1);
      final prepared = XdrSCPBallot(XdrUint32(23), value2);
      final preparedPrime = XdrSCPBallot(XdrUint32(21), value3);

      final prepare = XdrSCPStatementPrepare(
        XdrHash(hashBytes),
        ballot,
        prepared,
        preparedPrime,
        XdrUint32(3),
        XdrUint32(4),
      );

      final output = XdrDataOutputStream();
      XdrSCPStatementPrepare.encode(output, prepare);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementPrepare.decode(input);

      expect(decoded.ballot.counter.uint32, equals(25));
      expect(decoded.prepared, isNotNull);
      expect(decoded.prepared!.counter.uint32, equals(23));
      expect(decoded.preparedPrime, isNotNull);
      expect(decoded.preparedPrime!.counter.uint32, equals(21));
    });
  });

  group('XdrSCPStatementConfirm encode/decode', () {
    test('encodes and decodes confirm', () {
      final hashBytes = Uint8List(32);
      final value = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final ballot = XdrSCPBallot(XdrUint32(40), value);

      final confirm = XdrSCPStatementConfirm(
        ballot,
        XdrUint32(10),
        XdrUint32(20),
        XdrUint32(30),
        XdrHash(hashBytes),
      );

      final output = XdrDataOutputStream();
      XdrSCPStatementConfirm.encode(output, confirm);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementConfirm.decode(input);

      expect(decoded.ballot.counter.uint32, equals(40));
      expect(decoded.nPrepared.uint32, equals(10));
      expect(decoded.nCommit.uint32, equals(20));
      expect(decoded.nH.uint32, equals(30));
    });
  });

  group('XdrSCPStatementExternalize encode/decode', () {
    test('encodes and decodes externalize', () {
      final hashBytes = Uint8List(32);
      final value = XdrValue(Uint8List.fromList([1, 2, 3, 4]));
      final ballot = XdrSCPBallot(XdrUint32(50), value);

      final externalize = XdrSCPStatementExternalize(
        ballot,
        XdrUint32(100),
        XdrHash(hashBytes),
      );

      final output = XdrDataOutputStream();
      XdrSCPStatementExternalize.encode(output, externalize);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPStatementExternalize.decode(input);

      expect(decoded.commit.counter.uint32, equals(50));
      expect(decoded.nH.uint32, equals(100));
    });
  });

  group('XdrSCPQuorumSet encode/decode', () {
    test('encodes and decodes quorum set with validators', () {
      final validator1 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      validator1.setEd25519(XdrUint256(Uint8List(32)..[0] = 1));
      final validator2 = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      validator2.setEd25519(XdrUint256(Uint8List(32)..[0] = 2));

      final quorumSet = XdrSCPQuorumSet(
        XdrUint32(2),
        [validator1, validator2],
        [],
      );

      final output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, quorumSet);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.threshold.uint32, equals(2));
      expect(decoded.validators.length, equals(2));
      expect(decoded.innerSets, isEmpty);
    });

    test('encodes and decodes nested quorum sets', () {
      final validator1 = XdrPublicKey.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      final innerSet = XdrSCPQuorumSet(
        XdrUint32(1),
        [validator1],
        [],
      );

      final quorumSet = XdrSCPQuorumSet(
        XdrUint32(1),
        [],
        [innerSet],
      );

      final output = XdrDataOutputStream();
      XdrSCPQuorumSet.encode(output, quorumSet);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrSCPQuorumSet.decode(input);

      expect(decoded.threshold.uint32, equals(1));
      expect(decoded.validators, isEmpty);
      expect(decoded.innerSets.length, equals(1));
      expect(decoded.innerSets[0].validators.length, equals(1));
    });
  });

  group('XdrUint256 encode/decode', () {
    test('encodes and decodes correctly', () {
      final bytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        bytes[i] = i;
      }

      final uint256 = XdrUint256(bytes);
      final output = XdrDataOutputStream();
      XdrUint256.encode(output, uint256);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrUint256.decode(input);

      expect(decoded.uint256.length, equals(32));
      for (int i = 0; i < 32; i++) {
        expect(decoded.uint256[i], equals(i));
      }
    });

    test('handles all zeros', () {
      final bytes = Uint8List(32);
      final uint256 = XdrUint256(bytes);

      final output = XdrDataOutputStream();
      XdrUint256.encode(output, uint256);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrUint256.decode(input);

      expect(decoded.uint256.every((b) => b == 0), isTrue);
    });

    test('handles all ones', () {
      final bytes = Uint8List(32);
      bytes.fillRange(0, 32, 255);
      final uint256 = XdrUint256(bytes);

      final output = XdrDataOutputStream();
      XdrUint256.encode(output, uint256);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrUint256.decode(input);

      expect(decoded.uint256.every((b) => b == 255), isTrue);
    });
  });

  group('XdrHash encode/decode', () {
    test('encodes and decodes correctly', () {
      final bytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        bytes[i] = 255 - i;
      }

      final hash = XdrHash(bytes);
      final output = XdrDataOutputStream();
      XdrHash.encode(output, hash);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHash.decode(input);

      expect(decoded.hash.length, equals(32));
      for (int i = 0; i < 32; i++) {
        expect(decoded.hash[i], equals(255 - i));
      }
    });

    test('handles random hash values', () {
      final bytes = Uint8List.fromList([
        0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE,
        0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
        0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10,
        0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88
      ]);

      final hash = XdrHash(bytes);
      final output = XdrDataOutputStream();
      XdrHash.encode(output, hash);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHash.decode(input);

      expect(decoded.hash, equals(bytes));
    });
  });

  group('XdrCurve25519Public encode/decode', () {
    test('encodes and decodes correctly', () {
      final key = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        key[i] = i * 2;
      }

      final curve = XdrCurve25519Public(key);
      final output = XdrDataOutputStream();
      XdrCurve25519Public.encode(output, curve);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrCurve25519Public.decode(input);

      expect(decoded.key.length, equals(32));
      for (int i = 0; i < 32; i++) {
        expect(decoded.key[i], equals(i * 2));
      }
    });
  });

  group('XdrHmacSha256Key encode/decode', () {
    test('encodes and decodes correctly', () {
      final key = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        key[i] = (i * 7) % 256;
      }

      final hmacKey = XdrHmacSha256Key(key);
      final output = XdrDataOutputStream();
      XdrHmacSha256Key.encode(output, hmacKey);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHmacSha256Key.decode(input);

      expect(decoded.key.length, equals(32));
      for (int i = 0; i < 32; i++) {
        expect(decoded.key[i], equals((i * 7) % 256));
      }
    });
  });

  group('XdrHmacSha256Mac encode/decode', () {
    test('encodes and decodes correctly', () {
      final mac = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        mac[i] = (i * 11) % 256;
      }

      final hmacMac = XdrHmacSha256Mac(mac);
      final output = XdrDataOutputStream();
      XdrHmacSha256Mac.encode(output, hmacMac);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrHmacSha256Mac.decode(input);

      expect(decoded.key.length, equals(32));
      for (int i = 0; i < 32; i++) {
        expect(decoded.key[i], equals((i * 11) % 256));
      }
    });
  });

  group('XdrCurve25519Secret encode/decode', () {
    test('encodes and decodes correctly', () {
      final secret = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        secret[i] = (i * 13) % 256;
      }

      final curve = XdrCurve25519Secret(secret);
      final output = XdrDataOutputStream();
      XdrCurve25519Secret.encode(output, curve);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrCurve25519Secret.decode(input);

      expect(decoded.key.length, equals(32));
      for (int i = 0; i < 32; i++) {
        expect(decoded.key[i], equals((i * 13) % 256));
      }
    });
  });

  group('XdrThresholds encode/decode', () {
    test('encodes and decodes correctly', () {
      final thresholds = Uint8List.fromList([1, 2, 3, 4]);
      final xdrThresholds = XdrThresholds(thresholds);

      final output = XdrDataOutputStream();
      XdrThresholds.encode(output, xdrThresholds);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrThresholds.decode(input);

      expect(decoded.thresholds.length, equals(4));
      expect(decoded.thresholds[0], equals(1));
      expect(decoded.thresholds[1], equals(2));
      expect(decoded.thresholds[2], equals(3));
      expect(decoded.thresholds[3], equals(4));
    });

    test('handles maximum threshold values', () {
      final thresholds = Uint8List.fromList([255, 255, 255, 255]);
      final xdrThresholds = XdrThresholds(thresholds);

      final output = XdrDataOutputStream();
      XdrThresholds.encode(output, xdrThresholds);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrThresholds.decode(input);

      expect(decoded.thresholds.every((t) => t == 255), isTrue);
    });
  });

  group('XdrUpgradeType encode/decode', () {
    test('encodes and decodes variable length data', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final upgradeType = XdrUpgradeType(data);

      final output = XdrDataOutputStream();
      XdrUpgradeType.encode(output, upgradeType);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrUpgradeType.decode(input);

      expect(decoded.upgradeType.length, equals(8));
      for (int i = 0; i < 8; i++) {
        expect(decoded.upgradeType[i], equals(i + 1));
      }
    });

    test('handles empty upgrade type', () {
      final data = Uint8List(0);
      final upgradeType = XdrUpgradeType(data);

      final output = XdrDataOutputStream();
      XdrUpgradeType.encode(output, upgradeType);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrUpgradeType.decode(input);

      expect(decoded.upgradeType.length, equals(0));
    });
  });

  group('XdrValue encode/decode', () {
    test('encodes and decodes variable length value', () {
      final data = Uint8List.fromList([10, 20, 30, 40]);
      final value = XdrValue(data);

      final output = XdrDataOutputStream();
      XdrValue.encode(output, value);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrValue.decode(input);

      expect(decoded.value.length, equals(4));
      expect(decoded.value, equals(data));
    });

    test('handles large values', () {
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

  group('XdrPublicKeyType enum', () {
    test('encodes and decodes PUBLIC_KEY_TYPE_ED25519', () {
      final output = XdrDataOutputStream();
      XdrPublicKeyType.encode(output, XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrPublicKeyType.decode(input);

      expect(decoded, equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      expect(decoded.value, equals(0));
    });

    test('throws on unknown value', () {
      final output = XdrDataOutputStream();
      output.writeInt(999);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(() => XdrPublicKeyType.decode(input), throwsException);
    });
  });

  group('XdrCryptoKeyType enum', () {
    test('encodes and decodes KEY_TYPE_ED25519', () {
      final output = XdrDataOutputStream();
      XdrCryptoKeyType.encode(output, XdrCryptoKeyType.KEY_TYPE_ED25519);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrCryptoKeyType.decode(input);

      expect(decoded, equals(XdrCryptoKeyType.KEY_TYPE_ED25519));
      expect(decoded.value, equals(0));
    });

    test('encodes and decodes KEY_TYPE_PRE_AUTH_TX', () {
      final output = XdrDataOutputStream();
      XdrCryptoKeyType.encode(output, XdrCryptoKeyType.KEY_TYPE_PRE_AUTH_TX);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrCryptoKeyType.decode(input);

      expect(decoded, equals(XdrCryptoKeyType.KEY_TYPE_PRE_AUTH_TX));
      expect(decoded.value, equals(1));
    });

    test('encodes and decodes KEY_TYPE_HASH_X', () {
      final output = XdrDataOutputStream();
      XdrCryptoKeyType.encode(output, XdrCryptoKeyType.KEY_TYPE_HASH_X);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrCryptoKeyType.decode(input);

      expect(decoded, equals(XdrCryptoKeyType.KEY_TYPE_HASH_X));
      expect(decoded.value, equals(2));
    });

    test('encodes and decodes KEY_TYPE_MUXED_ED25519', () {
      final output = XdrDataOutputStream();
      XdrCryptoKeyType.encode(output, XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrCryptoKeyType.decode(input);

      expect(decoded, equals(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519));
      expect(decoded.value, equals(256));
    });

    test('throws on unknown value', () {
      final output = XdrDataOutputStream();
      output.writeInt(555);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(() => XdrCryptoKeyType.decode(input), throwsException);
    });
  });

  group('XdrPublicKey encode/decode', () {
    test('encodes and decodes ED25519 public key', () {
      final keyBytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        keyBytes[i] = i;
      }

      final publicKey = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      publicKey.setEd25519(XdrUint256(keyBytes));

      final output = XdrDataOutputStream();
      XdrPublicKey.encode(output, publicKey);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrPublicKey.decode(input);

      expect(decoded.getDiscriminant(), equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      expect(decoded.getEd25519()!.uint256, equals(keyBytes));
    });

    test('creates public key from account ID', () {
      final accountId = 'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H';
      final publicKey = XdrPublicKey.forAccountId(accountId);

      expect(publicKey.getDiscriminant(), equals(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      expect(publicKey.getEd25519(), isNotNull);
      expect(publicKey.getEd25519()!.uint256.length, equals(32));
    });
  });
}
