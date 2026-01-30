import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('ChangeTrustOperation', () {
    late KeyPair sourceKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usdAsset;
    late Asset euroAsset;

    setUp(() {
      sourceKeyPair = KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      issuerKeyPair = KeyPair.fromAccountId('GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
      euroAsset = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);
    });

    group('creation', () {
      test('creates with AlphaNum4 asset and maximum limit', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          ChangeTrustOperationBuilder.MAX_LIMIT
        ).build();

        expect(operation.asset, equals(usdAsset));
        expect(operation.limit, equals(ChangeTrustOperationBuilder.MAX_LIMIT));
        expect(operation.sourceAccount, isNull);
      });

      test('creates with AlphaNum12 asset and specific limit', () {
        final operation = ChangeTrustOperationBuilder(
          euroAsset,
          '5000.00'
        ).build();

        expect(operation.asset, equals(euroAsset));
        expect(operation.limit, equals('5000.00'));
        expect(operation.sourceAccount, isNull);
      });

      test('creates with zero limit to remove trustline', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '0'
        ).build();

        expect(operation.asset, equals(usdAsset));
        expect(operation.limit, equals('0'));
      });

      test('creates with source account', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '1000.00'
        ).setSourceAccount(sourceKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(12345));
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '1000.00'
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
        expect(operation.sourceAccount!.id, equals(BigInt.from(12345)));
      });

      test('creates with decimal precision limit', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '100.0000001'
        ).build();

        expect(operation.limit, equals('100.0000001'));
      });

      test('verifies MAX_LIMIT constant value', () {
        expect(ChangeTrustOperationBuilder.MAX_LIMIT, equals('922337203685.4775807'));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip preserves AlphaNum4 asset data', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '1000.00'
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.CHANGE_TRUST));
        expect(xdrBody.changeTrustOp, isNotNull);

        final restoredBuilder = ChangeTrustOperation.builder(xdrBody.changeTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.asset, isA<AssetTypeCreditAlphaNum4>());
        final restoredAsset = restored.asset as AssetTypeCreditAlphaNum4;
        expect(restoredAsset.code, equals('USD'));
        expect(restoredAsset.issuerId, equals(issuerKeyPair.accountId));
        expect(restored.limit, equals('1000'));
      });

      test('XDR round-trip preserves AlphaNum12 asset data', () {
        final operation = ChangeTrustOperationBuilder(
          euroAsset,
          '5000.00'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ChangeTrustOperation.builder(xdrBody.changeTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.asset, isA<AssetTypeCreditAlphaNum12>());
        final restoredAsset = restored.asset as AssetTypeCreditAlphaNum12;
        expect(restoredAsset.code, equals('EUROTOKEN'));
        expect(restoredAsset.issuerId, equals(issuerKeyPair.accountId));
        expect(restored.limit, equals('5000'));
      });

      test('XDR round-trip preserves maximum limit', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          ChangeTrustOperationBuilder.MAX_LIMIT
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ChangeTrustOperation.builder(xdrBody.changeTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.limit, equals('922337203685.4775807'));
      });

      test('XDR round-trip preserves zero limit', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '0'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ChangeTrustOperation.builder(xdrBody.changeTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.limit, equals('0'));
      });

      test('XDR round-trip preserves decimal precision', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '100.0000001'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ChangeTrustOperation.builder(xdrBody.changeTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.limit, equals('100.0000001'));
      });
    });

    group('builder pattern', () {
      test('builder supports method chaining', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '1000.00'
        )
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

        expect(operation, isNotNull);
        expect(operation, isA<ChangeTrustOperation>());
        expect(operation.asset, equals(usdAsset));
        expect(operation.limit, equals('1000.00'));
        expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
      });

      test('builder can set muxed source account', () {
        final muxedSource = MuxedAccount(sourceKeyPair.accountId, BigInt.from(99999));
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '1000.00'
        )
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(99999)));
      });
    });

    group('getters', () {
      test('asset getter returns correct asset', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '1000.00'
        ).build();

        final asset = operation.asset;
        expect(asset, isA<AssetTypeCreditAlphaNum4>());
        expect((asset as AssetTypeCreditAlphaNum4).code, equals('USD'));
      });

      test('limit getter returns correct limit', () {
        final operation = ChangeTrustOperationBuilder(
          usdAsset,
          '1000.00'
        ).build();

        expect(operation.limit, equals('1000.00'));
      });
    });
  });

  group('AllowTrustOperation', () {
    late KeyPair issuerKeyPair;
    late KeyPair trustorKeyPair;
    late String assetCode;

    setUp(() {
      issuerKeyPair = KeyPair.fromAccountId('GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ');
      trustorKeyPair = KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      assetCode = 'USD';
    });

    group('creation', () {
      test('creates with authorize flag set to true', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          1 // AUTHORIZED_FLAG
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.trustor, equals(trustorKeyPair.accountId));
        expect(operation.assetCode, equals(assetCode));
        expect(operation.authorize, isTrue);
        expect(operation.authorizeToMaintainLiabilities, isFalse);
      });

      test('creates with authorize flag set to false', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          0 // No authorization
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.trustor, equals(trustorKeyPair.accountId));
        expect(operation.assetCode, equals(assetCode));
        expect(operation.authorize, isFalse);
        expect(operation.authorizeToMaintainLiabilities, isFalse);
      });

      test('creates with authorize to maintain liabilities flag', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          2 // AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.trustor, equals(trustorKeyPair.accountId));
        expect(operation.assetCode, equals(assetCode));
        expect(operation.authorize, isFalse);
        expect(operation.authorizeToMaintainLiabilities, isTrue);
      });

      test('creates with AlphaNum4 asset code', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          'USD',
          1
        ).build();

        expect(operation.assetCode, equals('USD'));
      });

      test('creates with AlphaNum12 asset code', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          'LONGASSET',
          1
        ).build();

        expect(operation.assetCode, equals('LONGASSET'));
      });

      test('creates with muxed source account', () {
        final muxedIssuer = MuxedAccount(issuerKeyPair.accountId, BigInt.from(54321));
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          1
        ).setMuxedSourceAccount(muxedIssuer).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(issuerKeyPair.accountId));
        expect(operation.sourceAccount!.id, equals(BigInt.from(54321)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with authorize true', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          1
        ).setSourceAccount(issuerKeyPair.accountId).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.ALLOW_TRUST));
        expect(xdrBody.allowTrustOp, isNotNull);

        final restoredBuilder = AllowTrustOperation.builder(xdrBody.allowTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.trustor, equals(trustorKeyPair.accountId));
        expect(restored.assetCode, equals(assetCode));
        expect(restored.authorize, isTrue);
        expect(restored.authorizeToMaintainLiabilities, isFalse);
      });

      test('XDR round-trip with authorize false', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          0
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = AllowTrustOperation.builder(xdrBody.allowTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.authorize, isFalse);
        expect(restored.authorizeToMaintainLiabilities, isFalse);
      });

      test('XDR round-trip with authorize to maintain liabilities', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          2
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = AllowTrustOperation.builder(xdrBody.allowTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.authorize, isFalse);
        expect(restored.authorizeToMaintainLiabilities, isTrue);
      });

      test('XDR round-trip with AlphaNum12 asset', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          'LONGASSET',
          1
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = AllowTrustOperation.builder(xdrBody.allowTrustOp!);
        final restored = restoredBuilder.build();

        expect(restored.assetCode, equals('LONGASSET'));
      });
    });

    group('builder pattern', () {
      test('builder supports method chaining', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          1
        )
          .setSourceAccount(issuerKeyPair.accountId)
          .build();

        expect(operation, isNotNull);
        expect(operation, isA<AllowTrustOperation>());
        expect(operation.trustor, equals(trustorKeyPair.accountId));
        expect(operation.assetCode, equals(assetCode));
      });
    });

    group('getters', () {
      test('trustor getter returns correct value', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          1
        ).build();

        expect(operation.trustor, equals(trustorKeyPair.accountId));
      });

      test('assetCode getter returns correct value', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          1
        ).build();

        expect(operation.assetCode, equals(assetCode));
      });

      test('authorize getter returns correct value', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          1
        ).build();

        expect(operation.authorize, isTrue);
      });

      test('authorizeToMaintainLiabilities getter returns correct value', () {
        final operation = AllowTrustOperationBuilder(
          trustorKeyPair.accountId,
          assetCode,
          2
        ).build();

        expect(operation.authorizeToMaintainLiabilities, isTrue);
      });
    });
  });

  group('SetTrustLineFlagsOperation', () {
    late KeyPair issuerKeyPair;
    late KeyPair trustorKeyPair;
    late Asset usdAsset;

    setUp(() {
      issuerKeyPair = KeyPair.fromAccountId('GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ');
      trustorKeyPair = KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
    });

    group('creation', () {
      test('creates with authorize flag set', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0, // clearFlags
          1  // setFlags: AUTHORIZED_FLAG
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.trustorId, equals(trustorKeyPair.accountId));
        expect(operation.asset, equals(usdAsset));
        expect(operation.clearFlags, equals(0));
        expect(operation.setFlags, equals(1));
      });

      test('creates with clear authorize flag', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          1, // clearFlags: AUTHORIZED_FLAG
          0  // setFlags
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.clearFlags, equals(1));
        expect(operation.setFlags, equals(0));
      });

      test('creates with authorize to maintain liabilities flag', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          1, // clearFlags: AUTHORIZED_FLAG
          2  // setFlags: AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.clearFlags, equals(1));
        expect(operation.setFlags, equals(2));
      });

      test('creates with clawback enabled flag', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0, // clearFlags
          4  // setFlags: TRUSTLINE_CLAWBACK_ENABLED_FLAG
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.setFlags, equals(4));
      });

      test('creates with multiple flags set', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,   // clearFlags
          1 | 4 // setFlags: AUTHORIZED_FLAG | TRUSTLINE_CLAWBACK_ENABLED_FLAG
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.setFlags, equals(5));
      });

      test('creates with both set and clear flags', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          1, // clearFlags: AUTHORIZED_FLAG
          2  // setFlags: AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.clearFlags, equals(1));
        expect(operation.setFlags, equals(2));
      });

      test('creates with AlphaNum12 asset', () {
        final euroAsset = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          euroAsset,
          0,
          1
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.asset, equals(euroAsset));
      });

      test('creates with muxed source account', () {
        final muxedIssuer = MuxedAccount(issuerKeyPair.accountId, BigInt.from(11111));
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          1
        ).setMuxedSourceAccount(muxedIssuer).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(issuerKeyPair.accountId));
        expect(operation.sourceAccount!.id, equals(BigInt.from(11111)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with authorize flag', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          1
        ).setSourceAccount(issuerKeyPair.accountId).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.SET_TRUST_LINE_FLAGS));
        expect(xdrBody.setTrustLineFlagsOp, isNotNull);

        final restoredBuilder = SetTrustLineFlagsOperation.builder(xdrBody.setTrustLineFlagsOp!);
        final restored = restoredBuilder.build();

        expect(restored.trustorId, equals(trustorKeyPair.accountId));
        expect((restored.asset as AssetTypeCreditAlphaNum4).code, equals('USD'));
        expect(restored.clearFlags, equals(0));
        expect(restored.setFlags, equals(1));
      });

      test('XDR round-trip with clear flags', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          1,
          0
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetTrustLineFlagsOperation.builder(xdrBody.setTrustLineFlagsOp!);
        final restored = restoredBuilder.build();

        expect(restored.clearFlags, equals(1));
        expect(restored.setFlags, equals(0));
      });

      test('XDR round-trip with both set and clear flags', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          1,
          2
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetTrustLineFlagsOperation.builder(xdrBody.setTrustLineFlagsOp!);
        final restored = restoredBuilder.build();

        expect(restored.clearFlags, equals(1));
        expect(restored.setFlags, equals(2));
      });

      test('XDR round-trip with clawback enabled flag', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          4
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetTrustLineFlagsOperation.builder(xdrBody.setTrustLineFlagsOp!);
        final restored = restoredBuilder.build();

        expect(restored.setFlags, equals(4));
      });

      test('XDR round-trip with multiple flags', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          5 // AUTHORIZED_FLAG | TRUSTLINE_CLAWBACK_ENABLED_FLAG
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = SetTrustLineFlagsOperation.builder(xdrBody.setTrustLineFlagsOp!);
        final restored = restoredBuilder.build();

        expect(restored.setFlags, equals(5));
      });
    });

    group('builder pattern', () {
      test('builder supports method chaining', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          1
        )
          .setSourceAccount(issuerKeyPair.accountId)
          .build();

        expect(operation, isNotNull);
        expect(operation, isA<SetTrustLineFlagsOperation>());
        expect(operation.trustorId, equals(trustorKeyPair.accountId));
        expect(operation.asset, equals(usdAsset));
      });
    });

    group('getters', () {
      test('trustorId getter returns correct value', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          1
        ).build();

        expect(operation.trustorId, equals(trustorKeyPair.accountId));
      });

      test('asset getter returns correct value', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          1
        ).build();

        expect(operation.asset, isA<AssetTypeCreditAlphaNum4>());
        expect((operation.asset as AssetTypeCreditAlphaNum4).code, equals('USD'));
      });

      test('clearFlags getter returns correct value', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          1,
          0
        ).build();

        expect(operation.clearFlags, equals(1));
      });

      test('setFlags getter returns correct value', () {
        final operation = SetTrustLineFlagsOperationBuilder(
          trustorKeyPair.accountId,
          usdAsset,
          0,
          1
        ).build();

        expect(operation.setFlags, equals(1));
      });
    });
  });

  group('ClawbackOperation', () {
    late KeyPair issuerKeyPair;
    late KeyPair holderKeyPair;
    late Asset usdAsset;

    setUp(() {
      issuerKeyPair = KeyPair.fromAccountId('GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ');
      holderKeyPair = KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
    });

    group('creation', () {
      test('creates with asset holder and amount', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0'
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.from.ed25519AccountId, equals(holderKeyPair.accountId));
        expect(operation.asset, equals(usdAsset));
        expect(operation.amount, equals('100.0'));
        expect(operation.sourceAccount!.ed25519AccountId, equals(issuerKeyPair.accountId));
      });

      test('creates with AlphaNum4 asset', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '50.75'
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.asset, isA<AssetTypeCreditAlphaNum4>());
        final asset = operation.asset as AssetTypeCreditAlphaNum4;
        expect(asset.code, equals('USD'));
        expect(asset.issuerId, equals(issuerKeyPair.accountId));
        expect(operation.amount, equals('50.75'));
      });

      test('creates with AlphaNum12 asset', () {
        final euroAsset = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);
        final operation = ClawbackOperationBuilder(
          euroAsset,
          holderKeyPair.accountId,
          '25.5'
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.asset, isA<AssetTypeCreditAlphaNum12>());
        final asset = operation.asset as AssetTypeCreditAlphaNum12;
        expect(asset.code, equals('EUROTOKEN'));
        expect(operation.amount, equals('25.5'));
      });

      test('creates with decimal precision amount', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0000001'
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.amount, equals('100.0000001'));
      });

      test('creates with large amount', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '922337203685.4775807'
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.amount, equals('922337203685.4775807'));
      });

      test('creates with muxed source account', () {
        final muxedIssuer = MuxedAccount(issuerKeyPair.accountId, BigInt.from(99999));
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0'
        ).setMuxedSourceAccount(muxedIssuer).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(issuerKeyPair.accountId));
        expect(operation.sourceAccount!.id, equals(BigInt.from(99999)));
      });

      test('creates with muxed from account', () {
        final muxedHolder = MuxedAccount(holderKeyPair.accountId, BigInt.from(77777));
        final operation = ClawbackOperationBuilder.forMuxedFromAccount(
          usdAsset,
          muxedHolder,
          '100.0'
        ).setSourceAccount(issuerKeyPair.accountId).build();

        expect(operation.from.ed25519AccountId, equals(holderKeyPair.accountId));
        expect(operation.from.id, equals(BigInt.from(77777)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip preserves data', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0'
        ).setSourceAccount(issuerKeyPair.accountId).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.CLAWBACK));
        expect(xdrBody.clawbackOp, isNotNull);

        final restoredBuilder = ClawbackOperation.builder(xdrBody.clawbackOp!);
        final restored = restoredBuilder.build();

        expect(restored.from.ed25519AccountId, equals(holderKeyPair.accountId));
        expect((restored.asset as AssetTypeCreditAlphaNum4).code, equals('USD'));
        expect(restored.amount, equals('100'));
      });

      test('XDR round-trip with AlphaNum12 asset', () {
        final euroAsset = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);
        final operation = ClawbackOperationBuilder(
          euroAsset,
          holderKeyPair.accountId,
          '50.75'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ClawbackOperation.builder(xdrBody.clawbackOp!);
        final restored = restoredBuilder.build();

        expect(restored.asset, isA<AssetTypeCreditAlphaNum12>());
        expect((restored.asset as AssetTypeCreditAlphaNum12).code, equals('EUROTOKEN'));
        expect(restored.amount, equals('50.75'));
      });

      test('XDR round-trip preserves decimal precision', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0000001'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ClawbackOperation.builder(xdrBody.clawbackOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('100.0000001'));
      });

      test('XDR round-trip preserves large amount', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '922337203685.4775807'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ClawbackOperation.builder(xdrBody.clawbackOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('922337203685.4775807'));
      });

      test('XDR round-trip with muxed from account', () {
        final muxedHolder = MuxedAccount(holderKeyPair.accountId, BigInt.from(12345));
        final operation = ClawbackOperationBuilder.forMuxedFromAccount(
          usdAsset,
          muxedHolder,
          '100.0'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ClawbackOperation.builder(xdrBody.clawbackOp!);
        final restored = restoredBuilder.build();

        expect(restored.from.ed25519AccountId, equals(holderKeyPair.accountId));
        expect(restored.from.id, equals(BigInt.from(12345)));
      });
    });

    group('builder pattern', () {
      test('builder supports method chaining', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0'
        )
          .setSourceAccount(issuerKeyPair.accountId)
          .build();

        expect(operation, isNotNull);
        expect(operation, isA<ClawbackOperation>());
        expect(operation.from.ed25519AccountId, equals(holderKeyPair.accountId));
        expect(operation.asset, equals(usdAsset));
        expect(operation.amount, equals('100.0'));
      });

      test('builder can create with muxed from account', () {
        final muxedHolder = MuxedAccount(holderKeyPair.accountId, BigInt.from(55555));
        final operation = ClawbackOperationBuilder.forMuxedFromAccount(
          usdAsset,
          muxedHolder,
          '100.0'
        )
          .setSourceAccount(issuerKeyPair.accountId)
          .build();

        expect(operation.from.id, equals(BigInt.from(55555)));
      });
    });

    group('getters', () {
      test('from getter returns correct account', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0'
        ).build();

        expect(operation.from.ed25519AccountId, equals(holderKeyPair.accountId));
      });

      test('asset getter returns correct asset', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0'
        ).build();

        final asset = operation.asset;
        expect(asset, isA<AssetTypeCreditAlphaNum4>());
        expect((asset as AssetTypeCreditAlphaNum4).code, equals('USD'));
      });

      test('amount getter returns correct amount', () {
        final operation = ClawbackOperationBuilder(
          usdAsset,
          holderKeyPair.accountId,
          '100.0'
        ).build();

        expect(operation.amount, equals('100.0'));
      });
    });
  });

  group('Trust Operations Integration', () {
    late KeyPair sourceKeyPair;
    late KeyPair issuerKeyPair;
    late KeyPair holderKeyPair;
    late Asset usdAsset;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      issuerKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
      holderKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
    });

    test('change trust operation can be added to transaction', () {
      final sourceAccount = Account(sourceKeyPair.accountId, BigInt.from(2908908335136768));

      final changeTrust = ChangeTrustOperationBuilder(
        usdAsset,
        '1000.00'
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(changeTrust)
        .build();

      expect(transaction.operations.length, equals(1));
      expect(transaction.operations[0], isA<ChangeTrustOperation>());
    });

    test('allow trust operation can be added to transaction', () {
      final sourceAccount = Account(issuerKeyPair.accountId, BigInt.from(2908908335136768));

      final allowTrust = AllowTrustOperationBuilder(
        holderKeyPair.accountId,
        'USD',
        1
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(allowTrust)
        .build();

      expect(transaction.operations.length, equals(1));
      expect(transaction.operations[0], isA<AllowTrustOperation>());
    });

    test('set trust line flags operation can be added to transaction', () {
      final sourceAccount = Account(issuerKeyPair.accountId, BigInt.from(2908908335136768));

      final setFlags = SetTrustLineFlagsOperationBuilder(
        holderKeyPair.accountId,
        usdAsset,
        0,
        1
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setFlags)
        .build();

      expect(transaction.operations.length, equals(1));
      expect(transaction.operations[0], isA<SetTrustLineFlagsOperation>());
    });

    test('clawback operation can be added to transaction', () {
      final sourceAccount = Account(issuerKeyPair.accountId, BigInt.from(2908908335136768));

      final clawback = ClawbackOperationBuilder(
        usdAsset,
        holderKeyPair.accountId,
        '100.0'
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(clawback)
        .build();

      expect(transaction.operations.length, equals(1));
      expect(transaction.operations[0], isA<ClawbackOperation>());
    });

    test('multiple trust operations in single transaction', () {
      final sourceAccount = Account(issuerKeyPair.accountId, BigInt.from(2908908335136768));

      final setFlags = SetTrustLineFlagsOperationBuilder(
        holderKeyPair.accountId,
        usdAsset,
        0,
        1
      ).build();

      final clawback = ClawbackOperationBuilder(
        usdAsset,
        holderKeyPair.accountId,
        '50.0'
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(setFlags)
        .addOperation(clawback)
        .build();

      expect(transaction.operations.length, equals(2));
      expect(transaction.operations[0], isA<SetTrustLineFlagsOperation>());
      expect(transaction.operations[1], isA<ClawbackOperation>());
    });

    test('trust operations with different asset types', () {
      final usd4 = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
      final euro12 = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);

      final trustOp1 = ChangeTrustOperationBuilder(
        usd4,
        '1000.00'
      ).build();

      final trustOp2 = ChangeTrustOperationBuilder(
        euro12,
        '2000.00'
      ).build();

      expect(trustOp1.asset, isA<AssetTypeCreditAlphaNum4>());
      expect(trustOp2.asset, isA<AssetTypeCreditAlphaNum12>());
    });
  });
}
