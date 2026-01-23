import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SetOptionsOperation', () {
    late KeyPair accountKeyPair;
    late KeyPair signerKeyPair;
    late KeyPair inflationKeyPair;

    setUpAll(() {
      accountKeyPair = KeyPair.random();
      signerKeyPair = KeyPair.random();
      inflationKeyPair = KeyPair.random();
    });

    group('creation', () {
      test('creates with inflation destination', () {
        final operation = SetOptionsOperationBuilder()
          .setInflationDestination(inflationKeyPair.accountId)
          .build();

        expect(operation.inflationDestination, equals(inflationKeyPair.accountId));
        expect(operation.clearFlags, isNull);
        expect(operation.setFlags, isNull);
        expect(operation.masterKeyWeight, isNull);
      });

      test('creates with set flags', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(1)
          .build();

        expect(operation.setFlags, equals(1));
        expect(operation.clearFlags, isNull);
      });

      test('creates with clear flags', () {
        final operation = SetOptionsOperationBuilder()
          .setClearFlags(2)
          .build();

        expect(operation.clearFlags, equals(2));
        expect(operation.setFlags, isNull);
      });

      test('creates with master key weight', () {
        final operation = SetOptionsOperationBuilder()
          .setMasterKeyWeight(100)
          .build();

        expect(operation.masterKeyWeight, equals(100));
      });

      test('creates with zero master key weight', () {
        final operation = SetOptionsOperationBuilder()
          .setMasterKeyWeight(0)
          .build();

        expect(operation.masterKeyWeight, equals(0));
      });

      test('creates with all thresholds', () {
        final operation = SetOptionsOperationBuilder()
          .setLowThreshold(1)
          .setMediumThreshold(2)
          .setHighThreshold(3)
          .build();

        expect(operation.lowThreshold, equals(1));
        expect(operation.mediumThreshold, equals(2));
        expect(operation.highThreshold, equals(3));
      });

      test('creates with home domain', () {
        final operation = SetOptionsOperationBuilder()
          .setHomeDomain('example.com')
          .build();

        expect(operation.homeDomain, equals('example.com'));
      });

      test('creates with maximum length home domain', () {
        final maxDomain = 'a' * 32;
        final operation = SetOptionsOperationBuilder()
          .setHomeDomain(maxDomain)
          .build();

        expect(operation.homeDomain, equals(maxDomain));
      });

      test('throws on home domain exceeding 32 characters', () {
        expect(
          () => SetOptionsOperationBuilder().setHomeDomain('a' * 33),
          throwsException
        );
      });

      test('creates with signer', () {
        final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        signerKey.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(signerKeyPair.accountId));

        final operation = SetOptionsOperationBuilder()
          .setSigner(signerKey, 5)
          .build();

        expect(operation.signer, isNotNull);
        expect(operation.signerWeight, equals(5));
      });

      test('creates with zero weight signer to remove', () {
        final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        signerKey.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(signerKeyPair.accountId));

        final operation = SetOptionsOperationBuilder()
          .setSigner(signerKey, 0)
          .build();

        expect(operation.signer, isNotNull);
        expect(operation.signerWeight, equals(0));
      });

      test('creates with all flags combined', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(3)
          .build();

        expect(operation.setFlags, equals(3));
      });

      test('creates with AUTH_REQUIRED_FLAG', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(1)
          .build();

        expect(operation.setFlags, equals(1));
      });

      test('creates with AUTH_REVOCABLE_FLAG', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(2)
          .build();

        expect(operation.setFlags, equals(2));
      });

      test('creates with AUTH_IMMUTABLE_FLAG', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(4)
          .build();

        expect(operation.setFlags, equals(4));
      });

      test('creates with AUTH_CLAWBACK_ENABLED_FLAG', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(8)
          .build();

        expect(operation.setFlags, equals(8));
      });

      test('creates with source account', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(1)
          .setSourceAccount(accountKeyPair.accountId)
          .build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(accountKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(accountKeyPair.accountId, BigInt.from(12345));
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(1)
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(12345)));
      });

      test('creates with multiple options combined', () {
        final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        signerKey.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(signerKeyPair.accountId));

        final operation = SetOptionsOperationBuilder()
          .setInflationDestination(inflationKeyPair.accountId)
          .setSetFlags(1)
          .setMasterKeyWeight(1)
          .setLowThreshold(1)
          .setMediumThreshold(2)
          .setHighThreshold(2)
          .setHomeDomain('stellar.org')
          .setSigner(signerKey, 1)
          .build();

        expect(operation.inflationDestination, equals(inflationKeyPair.accountId));
        expect(operation.setFlags, equals(1));
        expect(operation.masterKeyWeight, equals(1));
        expect(operation.lowThreshold, equals(1));
        expect(operation.mediumThreshold, equals(2));
        expect(operation.highThreshold, equals(2));
        expect(operation.homeDomain, equals('stellar.org'));
        expect(operation.signerWeight, equals(1));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with inflation destination', () {
        final operation = SetOptionsOperationBuilder()
          .setInflationDestination(inflationKeyPair.accountId)
          .build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.SET_OPTIONS));
        expect(xdrBody.setOptionsOp, isNotNull);

        final restoredBuilder = SetOptionsOperation.builder(xdrBody.setOptionsOp!);
        final restored = restoredBuilder.build();

        expect(restored.inflationDestination, equals(inflationKeyPair.accountId));
      });

      test('XDR round-trip with flags', () {
        final operation = SetOptionsOperationBuilder()
          .setSetFlags(3)
          .setClearFlags(2)
          .build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetOptionsOperation.builder(xdrBody.setOptionsOp!);
        final restored = restoredBuilder.build();

        expect(restored.setFlags, equals(3));
        expect(restored.clearFlags, equals(2));
      });

      test('XDR round-trip with thresholds', () {
        final operation = SetOptionsOperationBuilder()
          .setMasterKeyWeight(100)
          .setLowThreshold(10)
          .setMediumThreshold(50)
          .setHighThreshold(100)
          .build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetOptionsOperation.builder(xdrBody.setOptionsOp!);
        final restored = restoredBuilder.build();

        expect(restored.masterKeyWeight, equals(100));
        expect(restored.lowThreshold, equals(10));
        expect(restored.mediumThreshold, equals(50));
        expect(restored.highThreshold, equals(100));
      });

      test('XDR round-trip with home domain', () {
        final operation = SetOptionsOperationBuilder()
          .setHomeDomain('stellar.org')
          .build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetOptionsOperation.builder(xdrBody.setOptionsOp!);
        final restored = restoredBuilder.build();

        expect(restored.homeDomain, equals('stellar.org'));
      });

      test('XDR round-trip with signer', () {
        final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        signerKey.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(signerKeyPair.accountId));

        final operation = SetOptionsOperationBuilder()
          .setSigner(signerKey, 5)
          .build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetOptionsOperation.builder(xdrBody.setOptionsOp!);
        final restored = restoredBuilder.build();

        expect(restored.signer, isNotNull);
        expect(restored.signerWeight, equals(5));
      });

      test('XDR round-trip with all options', () {
        final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
        signerKey.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(signerKeyPair.accountId));

        final operation = SetOptionsOperationBuilder()
          .setInflationDestination(inflationKeyPair.accountId)
          .setSetFlags(1)
          .setClearFlags(2)
          .setMasterKeyWeight(1)
          .setLowThreshold(1)
          .setMediumThreshold(2)
          .setHighThreshold(2)
          .setHomeDomain('stellar.org')
          .setSigner(signerKey, 1)
          .build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetOptionsOperation.builder(xdrBody.setOptionsOp!);
        final restored = restoredBuilder.build();

        expect(restored.inflationDestination, equals(inflationKeyPair.accountId));
        expect(restored.setFlags, equals(1));
        expect(restored.clearFlags, equals(2));
        expect(restored.masterKeyWeight, equals(1));
        expect(restored.lowThreshold, equals(1));
        expect(restored.mediumThreshold, equals(2));
        expect(restored.highThreshold, equals(2));
        expect(restored.homeDomain, equals('stellar.org'));
        expect(restored.signerWeight, equals(1));
      });
    });
  });

  group('ManageDataOperation', () {
    late KeyPair accountKeyPair;

    setUpAll(() {
      accountKeyPair = KeyPair.random();
    });

    group('creation', () {
      test('creates with data entry', () {
        final data = Uint8List.fromList(utf8.encode('testValue'));
        final operation = ManageDataOperationBuilder('testKey', data).build();

        expect(operation.name, equals('testKey'));
        expect(operation.value, equals(data));
      });

      test('creates with null value to delete', () {
        final operation = ManageDataOperationBuilder('testKey', null).build();

        expect(operation.name, equals('testKey'));
        expect(operation.value, isNull);
      });

      test('creates with empty value', () {
        final data = Uint8List(0);
        final operation = ManageDataOperationBuilder('testKey', data).build();

        expect(operation.name, equals('testKey'));
        expect(operation.value, equals(data));
      });

      test('creates with maximum length name', () {
        final maxName = 'a' * 64;
        final data = Uint8List.fromList(utf8.encode('value'));
        final operation = ManageDataOperationBuilder(maxName, data).build();

        expect(operation.name, equals(maxName));
      });

      test('creates with maximum length value', () {
        final data = Uint8List(64);
        final operation = ManageDataOperationBuilder('key', data).build();

        expect(operation.value!.length, equals(64));
      });

      test('creates with source account', () {
        final data = Uint8List.fromList(utf8.encode('value'));
        final operation = ManageDataOperationBuilder('key', data)
          .setSourceAccount(accountKeyPair.accountId)
          .build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(accountKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final data = Uint8List.fromList(utf8.encode('value'));
        final muxedSource = MuxedAccount(accountKeyPair.accountId, BigInt.from(99999));
        final operation = ManageDataOperationBuilder('key', data)
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(99999)));
      });

      test('creates with JSON data', () {
        final jsonString = '{"version":"1.0","type":"user"}';
        final data = Uint8List.fromList(utf8.encode(jsonString));
        final operation = ManageDataOperationBuilder('metadata', data).build();

        expect(operation.name, equals('metadata'));
        expect(utf8.decode(operation.value!), equals(jsonString));
      });

      test('creates with binary data', () {
        final data = Uint8List.fromList([0, 1, 2, 3, 255, 254, 253]);
        final operation = ManageDataOperationBuilder('binary', data).build();

        expect(operation.value, equals(data));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with data', () {
        final data = Uint8List.fromList(utf8.encode('testValue'));
        final operation = ManageDataOperationBuilder('testKey', data).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.MANAGE_DATA));
        expect(xdrBody.manageDataOp, isNotNull);

        final restoredBuilder = ManageDataOperation.builder(xdrBody.manageDataOp!);
        final restored = restoredBuilder.build();

        expect(restored.name, equals('testKey'));
        expect(restored.value, equals(data));
      });

      test('XDR round-trip with null value', () {
        final operation = ManageDataOperationBuilder('testKey', null).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageDataOperation.builder(xdrBody.manageDataOp!);
        final restored = restoredBuilder.build();

        expect(restored.name, equals('testKey'));
        expect(restored.value, isNull);
      });

      test('XDR round-trip with maximum length data', () {
        final data = Uint8List(64);
        for (int i = 0; i < 64; i++) {
          data[i] = i % 256;
        }
        final operation = ManageDataOperationBuilder('key', data).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageDataOperation.builder(xdrBody.manageDataOp!);
        final restored = restoredBuilder.build();

        expect(restored.value, equals(data));
      });
    });
  });

  group('BumpSequenceOperation', () {
    late KeyPair accountKeyPair;

    setUpAll(() {
      accountKeyPair = KeyPair.random();
    });

    group('creation', () {
      test('creates with new sequence number', () {
        final newSeq = BigInt.from(12345);
        final operation = BumpSequenceOperationBuilder(newSeq).build();

        expect(operation.bumpTo, equals(newSeq));
      });

      test('creates with large sequence number', () {
        final newSeq = BigInt.parse('9223372036854775807');
        final operation = BumpSequenceOperationBuilder(newSeq).build();

        expect(operation.bumpTo, equals(newSeq));
      });

      test('creates with source account', () {
        final newSeq = BigInt.from(12345);
        final operation = BumpSequenceOperationBuilder(newSeq)
          .setSourceAccount(accountKeyPair.accountId)
          .build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(accountKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final newSeq = BigInt.from(12345);
        final muxedSource = MuxedAccount(accountKeyPair.accountId, BigInt.from(777));
        final operation = BumpSequenceOperationBuilder(newSeq)
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(777)));
      });

      test('creates with sequence number increment', () {
        final currentSeq = BigInt.from(100);
        final increment = BigInt.from(1000);
        final newSeq = currentSeq + increment;
        final operation = BumpSequenceOperationBuilder(newSeq).build();

        expect(operation.bumpTo, equals(BigInt.from(1100)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with sequence number', () {
        final newSeq = BigInt.from(12345);
        final operation = BumpSequenceOperationBuilder(newSeq).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.BUMP_SEQUENCE));
        expect(xdrBody.bumpSequenceOp, isNotNull);

        final restoredBuilder = BumpSequenceOperation.builder(xdrBody.bumpSequenceOp!);
        final restored = restoredBuilder.build();

        expect(restored.bumpTo, equals(newSeq));
      });

      test('XDR round-trip with large sequence number', () {
        final newSeq = BigInt.parse('9223372036854775807');
        final operation = BumpSequenceOperationBuilder(newSeq).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = BumpSequenceOperation.builder(xdrBody.bumpSequenceOp!);
        final restored = restoredBuilder.build();

        expect(restored.bumpTo, equals(newSeq));
      });
    });
  });

  group('CreateClaimableBalanceOperation', () {
    late KeyPair sourceKeyPair;
    late KeyPair claimantKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usdAsset;

    setUpAll(() {
      sourceKeyPair = KeyPair.random();
      claimantKeyPair = KeyPair.random();
      issuerKeyPair = KeyPair.random();
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
    });

    group('creation', () {
      test('creates with single unconditional claimant', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).build();

        expect(operation.claimants.length, equals(1));
        expect(operation.claimants[0].destination, equals(claimantKeyPair.accountId));
        expect(operation.asset, equals(usdAsset));
        expect(operation.amount, equals('100.0'));
      });

      test('creates with multiple claimants', () {
        final claimant1 = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final claimant2 = Claimant(
          sourceKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant1, claimant2],
          usdAsset,
          '100.0'
        ).build();

        expect(operation.claimants.length, equals(2));
        expect(operation.claimants[0].destination, equals(claimantKeyPair.accountId));
        expect(operation.claimants[1].destination, equals(sourceKeyPair.accountId));
      });

      test('creates with time-based predicate', () {
        final futureTime = DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000;
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateNot(
            Claimant.predicateBeforeAbsoluteTime(futureTime)
          )
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).build();

        expect(operation.claimants[0].predicate.discriminant,
          equals(XdrClaimPredicateType.CLAIM_PREDICATE_NOT));
      });

      test('creates with relative time predicate', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateBeforeRelativeTime(604800)
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '50.0'
        ).build();

        expect(operation.claimants[0].predicate.discriminant,
          equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_RELATIVE_TIME));
      });

      test('creates with AND predicate', () {
        final pred1 = Claimant.predicateBeforeAbsoluteTime(1000000);
        final pred2 = Claimant.predicateNot(Claimant.predicateBeforeAbsoluteTime(500000));
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateAnd(pred1, pred2)
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).build();

        expect(operation.claimants[0].predicate.discriminant,
          equals(XdrClaimPredicateType.CLAIM_PREDICATE_AND));
      });

      test('creates with OR predicate', () {
        final pred1 = Claimant.predicateBeforeAbsoluteTime(1000000);
        final pred2 = Claimant.predicateNot(Claimant.predicateBeforeAbsoluteTime(2000000));
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateOr(pred1, pred2)
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).build();

        expect(operation.claimants[0].predicate.discriminant,
          equals(XdrClaimPredicateType.CLAIM_PREDICATE_OR));
      });

      test('creates with native asset', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          AssetTypeNative(),
          '100.0'
        ).build();

        expect(operation.asset, isA<AssetTypeNative>());
      });

      test('creates with source account', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).setSourceAccount(sourceKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(555));
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(555)));
      });

      test('creates with decimal precision amount', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0000001'
        ).build();

        expect(operation.amount, equals('100.0000001'));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with single claimant', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.CREATE_CLAIMABLE_BALANCE));
        expect(xdrBody.createClaimableBalanceOp, isNotNull);

        final restoredBuilder = CreateClaimableBalanceOperation.builder(
          xdrBody.createClaimableBalanceOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.claimants.length, equals(1));
        expect(restored.claimants[0].destination, equals(claimantKeyPair.accountId));
        expect(restored.amount, equals('100'));
        expect(restored.asset, isA<AssetTypeCreditAlphaNum4>());
      });

      test('XDR round-trip with multiple claimants', () {
        final claimant1 = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final claimant2 = Claimant(
          sourceKeyPair.accountId,
          Claimant.predicateUnconditional()
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant1, claimant2],
          usdAsset,
          '100.0'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = CreateClaimableBalanceOperation.builder(
          xdrBody.createClaimableBalanceOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.claimants.length, equals(2));
      });

      test('XDR round-trip with time predicate', () {
        final claimant = Claimant(
          claimantKeyPair.accountId,
          Claimant.predicateBeforeAbsoluteTime(1000000)
        );
        final operation = CreateClaimableBalanceOperationBuilder(
          [claimant],
          usdAsset,
          '100.0'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = CreateClaimableBalanceOperation.builder(
          xdrBody.createClaimableBalanceOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.claimants[0].predicate.discriminant,
          equals(XdrClaimPredicateType.CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME));
      });
    });
  });

  group('ClaimClaimableBalanceOperation', () {
    late KeyPair claimantKeyPair;
    late String balanceId;
    late String balanceIdWithoutPrefix;

    setUpAll(() {
      claimantKeyPair = KeyPair.random();
      balanceId = '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
      balanceIdWithoutPrefix = 'da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
    });

    group('creation', () {
      test('creates with balance ID', () {
        final operation = ClaimClaimableBalanceOperationBuilder(balanceId).build();

        expect(operation.balanceId, equals(balanceId));
      });

      test('creates with source account', () {
        final operation = ClaimClaimableBalanceOperationBuilder(balanceId)
          .setSourceAccount(claimantKeyPair.accountId)
          .build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(claimantKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(claimantKeyPair.accountId, BigInt.from(333));
        final operation = ClaimClaimableBalanceOperationBuilder(balanceId)
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(333)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip', () {
        final operation = ClaimClaimableBalanceOperationBuilder(balanceId).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.CLAIM_CLAIMABLE_BALANCE));
        expect(xdrBody.claimClaimableBalanceOp, isNotNull);

        final restoredBuilder = ClaimClaimableBalanceOperation.builder(
          xdrBody.claimClaimableBalanceOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.balanceId, equals(balanceIdWithoutPrefix));
      });
    });
  });

  group('ClawbackClaimableBalanceOperation', () {
    late KeyPair issuerKeyPair;
    late String balanceId;
    late String balanceIdWithoutPrefix;

    setUpAll(() {
      issuerKeyPair = KeyPair.random();
      balanceId = '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
      balanceIdWithoutPrefix = 'da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
    });

    group('creation', () {
      test('creates with balance ID', () {
        final operation = ClawbackClaimableBalanceOperationBuilder(balanceId).build();

        expect(operation.balanceId, equals(balanceId));
      });

      test('creates with source account', () {
        final operation = ClawbackClaimableBalanceOperationBuilder(balanceId)
          .setSourceAccount(issuerKeyPair.accountId)
          .build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(issuerKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(issuerKeyPair.accountId, BigInt.from(888));
        final operation = ClawbackClaimableBalanceOperationBuilder(balanceId)
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(888)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip', () {
        final operation = ClawbackClaimableBalanceOperationBuilder(balanceId).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE));
        expect(xdrBody.clawbackClaimableBalanceOp, isNotNull);

        final restoredBuilder = ClawbackClaimableBalanceOperation.builder(
          xdrBody.clawbackClaimableBalanceOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.balanceId, equals(balanceIdWithoutPrefix));
      });
    });
  });

  group('BeginSponsoringFutureReservesOperation', () {
    late KeyPair sponsorKeyPair;
    late KeyPair sponsoredKeyPair;

    setUpAll(() {
      sponsorKeyPair = KeyPair.random();
      sponsoredKeyPair = KeyPair.random();
    });

    group('creation', () {
      test('creates with sponsored account ID', () {
        final operation = BeginSponsoringFutureReservesOperationBuilder(
          sponsoredKeyPair.accountId
        ).build();

        expect(operation.sponsoredId, equals(sponsoredKeyPair.accountId));
      });

      test('creates with source account', () {
        final operation = BeginSponsoringFutureReservesOperationBuilder(
          sponsoredKeyPair.accountId
        ).setSourceAccount(sponsorKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sponsorKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(sponsorKeyPair.accountId, BigInt.from(111));
        final operation = BeginSponsoringFutureReservesOperationBuilder(
          sponsoredKeyPair.accountId
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(111)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip', () {
        final operation = BeginSponsoringFutureReservesOperationBuilder(
          sponsoredKeyPair.accountId
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES));
        expect(xdrBody.beginSponsoringFutureReservesOp, isNotNull);

        final restored = BeginSponsoringFutureReservesOperation.builder(
          xdrBody.beginSponsoringFutureReservesOp!
        );

        expect(restored.sponsoredId, equals(sponsoredKeyPair.accountId));
      });
    });
  });

  group('EndSponsoringFutureReservesOperation', () {
    late KeyPair sponsoredKeyPair;

    setUpAll(() {
      sponsoredKeyPair = KeyPair.random();
    });

    group('creation', () {
      test('creates end sponsoring operation', () {
        final operation = EndSponsoringFutureReservesOperationBuilder().build();

        expect(operation, isNotNull);
      });

      test('creates with source account', () {
        final operation = EndSponsoringFutureReservesOperationBuilder()
          .setSourceAccount(sponsoredKeyPair.accountId)
          .build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sponsoredKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(sponsoredKeyPair.accountId, BigInt.from(222));
        final operation = EndSponsoringFutureReservesOperationBuilder()
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(222)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip', () {
        final operation = EndSponsoringFutureReservesOperationBuilder().build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.END_SPONSORING_FUTURE_RESERVES));

        final restored = EndSponsoringFutureReservesOperation.builder();

        expect(restored, isNotNull);
      });
    });
  });

  group('RevokeSponsorshipOperation', () {
    late KeyPair sponsorKeyPair;
    late KeyPair accountKeyPair;
    late KeyPair signerKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usdAsset;

    setUpAll(() {
      sponsorKeyPair = KeyPair.random();
      accountKeyPair = KeyPair.random();
      signerKeyPair = KeyPair.random();
      issuerKeyPair = KeyPair.random();
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
    });

    group('creation', () {
      test('creates revoke account sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeAccountSponsorship(accountKeyPair.accountId)
          .build();

        expect(operation.ledgerKey, isNotNull);
        expect(operation.ledgerKey!.discriminant, equals(XdrLedgerEntryType.ACCOUNT));
      });

      test('creates revoke trustline sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeTrustlineSponsorship(accountKeyPair.accountId, usdAsset)
          .build();

        expect(operation.ledgerKey, isNotNull);
        expect(operation.ledgerKey!.discriminant, equals(XdrLedgerEntryType.TRUSTLINE));
      });

      test('creates revoke data sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeDataSponsorship(accountKeyPair.accountId, 'testKey')
          .build();

        expect(operation.ledgerKey, isNotNull);
        expect(operation.ledgerKey!.discriminant, equals(XdrLedgerEntryType.DATA));
      });

      test('creates revoke offer sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeOfferSponsorship(accountKeyPair.accountId, 12345)
          .build();

        expect(operation.ledgerKey, isNotNull);
        expect(operation.ledgerKey!.discriminant, equals(XdrLedgerEntryType.OFFER));
      });

      test('creates revoke claimable balance sponsorship', () {
        final balanceId = '00000000da0d57da7d4850e7fc10d2a9d0ebc731f7afb40574c03395b17d49149b91f5be';
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeClaimableBalanceSponsorship(balanceId)
          .build();

        expect(operation.ledgerKey, isNotNull);
        expect(operation.ledgerKey!.discriminant, equals(XdrLedgerEntryType.CLAIMABLE_BALANCE));
      });

      test('creates revoke Ed25519 signer sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeEd25519Signer(accountKeyPair.accountId, signerKeyPair.accountId)
          .build();

        expect(operation.signerKey, isNotNull);
        expect(operation.signerAccountId, equals(accountKeyPair.accountId));
        expect(operation.signerKey!.discriminant,
          equals(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519));
      });

      test('creates revoke pre-auth tx signer sponsorship', () {
        final preAuthTx = StrKey.encodePreAuthTx(Uint8List(32));
        final operation = RevokeSponsorshipOperationBuilder()
          .revokePreAuthTxSigner(accountKeyPair.accountId, preAuthTx)
          .build();

        expect(operation.signerKey, isNotNull);
        expect(operation.signerKey!.discriminant,
          equals(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX));
      });

      test('creates revoke sha256 hash signer sponsorship', () {
        final sha256Hash = StrKey.encodeSha256Hash(Uint8List(32));
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeSha256HashSigner(accountKeyPair.accountId, sha256Hash)
          .build();

        expect(operation.signerKey, isNotNull);
        expect(operation.signerKey!.discriminant,
          equals(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X));
      });

      test('throws when trying to revoke multiple entries', () {
        final builder = RevokeSponsorshipOperationBuilder()
          .revokeAccountSponsorship(accountKeyPair.accountId);

        expect(
          () => builder.revokeTrustlineSponsorship(accountKeyPair.accountId, usdAsset),
          throwsException
        );
      });

      test('creates with source account', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeAccountSponsorship(accountKeyPair.accountId)
          .setSourceAccount(sponsorKeyPair.accountId)
          .build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sponsorKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(sponsorKeyPair.accountId, BigInt.from(444));
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeAccountSponsorship(accountKeyPair.accountId)
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(444)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with account sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeAccountSponsorship(accountKeyPair.accountId)
          .build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.REVOKE_SPONSORSHIP));
        expect(xdrBody.revokeSponsorshipOp, isNotNull);

        final restored = RevokeSponsorshipOperation.fromXdr(xdrBody.revokeSponsorshipOp!);

        expect(restored, isNotNull);
        expect(restored!.ledgerKey, isNotNull);
        expect(restored.ledgerKey!.discriminant, equals(XdrLedgerEntryType.ACCOUNT));
      });

      test('XDR round-trip with trustline sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeTrustlineSponsorship(accountKeyPair.accountId, usdAsset)
          .build();

        final xdrBody = operation.toOperationBody();
        final restored = RevokeSponsorshipOperation.fromXdr(xdrBody.revokeSponsorshipOp!);

        expect(restored, isNotNull);
        expect(restored!.ledgerKey!.discriminant, equals(XdrLedgerEntryType.TRUSTLINE));
      });

      test('XDR round-trip with data sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeDataSponsorship(accountKeyPair.accountId, 'testKey')
          .build();

        final xdrBody = operation.toOperationBody();
        final restored = RevokeSponsorshipOperation.fromXdr(xdrBody.revokeSponsorshipOp!);

        expect(restored, isNotNull);
        expect(restored!.ledgerKey!.discriminant, equals(XdrLedgerEntryType.DATA));
      });

      test('XDR round-trip with signer sponsorship', () {
        final operation = RevokeSponsorshipOperationBuilder()
          .revokeEd25519Signer(accountKeyPair.accountId, signerKeyPair.accountId)
          .build();

        final xdrBody = operation.toOperationBody();
        final restored = RevokeSponsorshipOperation.fromXdr(xdrBody.revokeSponsorshipOp!);

        expect(restored, isNotNull);
        expect(restored!.signerKey, isNotNull);
        expect(restored.signerAccountId, equals(accountKeyPair.accountId));
      });
    });
  });

  group('LiquidityPoolDepositOperation', () {
    late KeyPair providerKeyPair;
    late String poolId;

    setUpAll(() {
      providerKeyPair = KeyPair.random();
      poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
    });

    group('creation', () {
      test('creates with pool ID and amounts', () {
        final operation = LiquidityPoolDepositOperationBuilder(
          liquidityPoolId: poolId,
          maxAmountA: '1000.0',
          maxAmountB: '500.0',
          minPrice: '0.49',
          maxPrice: '0.51'
        ).build();

        expect(operation.liquidityPoolId, equals(poolId));
        expect(operation.maxAmountA, equals('1000.0'));
        expect(operation.maxAmountB, equals('500.0'));
        expect(operation.minPrice, equals('0.49'));
        expect(operation.maxPrice, equals('0.51'));
      });

      test('creates with decimal precision amounts', () {
        final operation = LiquidityPoolDepositOperationBuilder(
          liquidityPoolId: poolId,
          maxAmountA: '1000.0000001',
          maxAmountB: '500.0000001',
          minPrice: '0.4999999',
          maxPrice: '0.5000001'
        ).build();

        expect(operation.maxAmountA, equals('1000.0000001'));
        expect(operation.maxAmountB, equals('500.0000001'));
        expect(operation.minPrice, equals('0.4999999'));
        expect(operation.maxPrice, equals('0.5000001'));
      });

      test('creates with source account', () {
        final operation = LiquidityPoolDepositOperationBuilder(
          liquidityPoolId: poolId,
          maxAmountA: '1000.0',
          maxAmountB: '500.0',
          minPrice: '0.49',
          maxPrice: '0.51'
        ).setSourceAccount(providerKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(providerKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(providerKeyPair.accountId, BigInt.from(666));
        final operation = LiquidityPoolDepositOperationBuilder(
          liquidityPoolId: poolId,
          maxAmountA: '1000.0',
          maxAmountB: '500.0',
          minPrice: '0.49',
          maxPrice: '0.51'
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(666)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip', () {
        final operation = LiquidityPoolDepositOperationBuilder(
          liquidityPoolId: poolId,
          maxAmountA: '1000.0',
          maxAmountB: '500.0',
          minPrice: '0.49',
          maxPrice: '0.51'
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.LIQUIDITY_POOL_DEPOSIT));
        expect(xdrBody.liquidityPoolDepositOp, isNotNull);

        final restoredBuilder = LiquidityPoolDepositOperation.builder(
          xdrBody.liquidityPoolDepositOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.liquidityPoolId, equals(poolId));
        expect(restored.maxAmountA, equals('1000'));
        expect(restored.maxAmountB, equals('500'));
      });

      test('XDR round-trip with decimal precision', () {
        final operation = LiquidityPoolDepositOperationBuilder(
          liquidityPoolId: poolId,
          maxAmountA: '1000.0000001',
          maxAmountB: '500.0000001',
          minPrice: '0.4999999',
          maxPrice: '0.5000001'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = LiquidityPoolDepositOperation.builder(
          xdrBody.liquidityPoolDepositOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.maxAmountA, equals('1000.0000001'));
        expect(restored.maxAmountB, equals('500.0000001'));
      });
    });
  });

  group('LiquidityPoolWithdrawOperation', () {
    late KeyPair providerKeyPair;
    late String poolId;

    setUpAll(() {
      providerKeyPair = KeyPair.random();
      poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
    });

    group('creation', () {
      test('creates with pool ID and amounts', () {
        final operation = LiquidityPoolWithdrawOperationBuilder(
          liquidityPoolId: poolId,
          amount: '100.0',
          minAmountA: '990.0',
          minAmountB: '490.0'
        ).build();

        expect(operation.liquidityPoolId, equals(poolId));
        expect(operation.amount, equals('100.0'));
        expect(operation.minAmountA, equals('990.0'));
        expect(operation.minAmountB, equals('490.0'));
      });

      test('creates with decimal precision amounts', () {
        final operation = LiquidityPoolWithdrawOperationBuilder(
          liquidityPoolId: poolId,
          amount: '100.0000001',
          minAmountA: '990.0000001',
          minAmountB: '490.0000001'
        ).build();

        expect(operation.amount, equals('100.0000001'));
        expect(operation.minAmountA, equals('990.0000001'));
        expect(operation.minAmountB, equals('490.0000001'));
      });

      test('creates with source account', () {
        final operation = LiquidityPoolWithdrawOperationBuilder(
          liquidityPoolId: poolId,
          amount: '100.0',
          minAmountA: '990.0',
          minAmountB: '490.0'
        ).setSourceAccount(providerKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(providerKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(providerKeyPair.accountId, BigInt.from(999));
        final operation = LiquidityPoolWithdrawOperationBuilder(
          liquidityPoolId: poolId,
          amount: '100.0',
          minAmountA: '990.0',
          minAmountB: '490.0'
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(999)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip', () {
        final operation = LiquidityPoolWithdrawOperationBuilder(
          liquidityPoolId: poolId,
          amount: '100.0',
          minAmountA: '990.0',
          minAmountB: '490.0'
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.LIQUIDITY_POOL_WITHDRAW));
        expect(xdrBody.liquidityPoolWithdrawOp, isNotNull);

        final restoredBuilder = LiquidityPoolWithdrawOperation.builder(
          xdrBody.liquidityPoolWithdrawOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.liquidityPoolId, equals(poolId));
        expect(restored.amount, equals('100'));
        expect(restored.minAmountA, equals('990'));
        expect(restored.minAmountB, equals('490'));
      });

      test('XDR round-trip with decimal precision', () {
        final operation = LiquidityPoolWithdrawOperationBuilder(
          liquidityPoolId: poolId,
          amount: '100.0000001',
          minAmountA: '990.0000001',
          minAmountB: '490.0000001'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = LiquidityPoolWithdrawOperation.builder(
          xdrBody.liquidityPoolWithdrawOp!
        );
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('100.0000001'));
        expect(restored.minAmountA, equals('990.0000001'));
        expect(restored.minAmountB, equals('490.0000001'));
      });
    });
  });
}
