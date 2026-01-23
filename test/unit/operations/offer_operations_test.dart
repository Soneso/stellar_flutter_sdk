import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('ManageSellOfferOperation', () {
    late KeyPair sellerKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usdAsset;
    late Asset euroAsset;
    late Asset nativeAsset;

    setUp(() {
      sellerKeyPair = KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      issuerKeyPair = KeyPair.fromAccountId('GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
      euroAsset = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);
      nativeAsset = AssetTypeNative();
    });

    group('creation', () {
      test('creates new sell offer with offerId 0', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.selling, equals(usdAsset));
        expect(operation.buying, equals(nativeAsset));
        expect(operation.amount, equals('100.0'));
        expect(operation.price, equals('2.5'));
        expect(operation.offerId, equals('0'));
        expect(operation.sourceAccount, isNull);
      });

      test('updates existing offer with positive offerId', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '150.0',
          '2.6'
        ).setOfferId('12345').build();

        expect(operation.selling, equals(usdAsset));
        expect(operation.buying, equals(nativeAsset));
        expect(operation.amount, equals('150.0'));
        expect(operation.price, equals('2.6'));
        expect(operation.offerId, equals('12345'));
      });

      test('deletes offer with amount 0', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '0',
          '2.5'
        ).setOfferId('12345').build();

        expect(operation.amount, equals('0'));
        expect(operation.offerId, equals('12345'));
      });

      test('creates with AlphaNum4 selling asset', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '1.5'
        ).build();

        expect(operation.selling, isA<AssetTypeCreditAlphaNum4>());
        final asset = operation.selling as AssetTypeCreditAlphaNum4;
        expect(asset.code, equals('USD'));
        expect(asset.issuerId, equals(issuerKeyPair.accountId));
      });

      test('creates with AlphaNum12 selling asset', () {
        final operation = ManageSellOfferOperationBuilder(
          euroAsset,
          nativeAsset,
          '100.0',
          '1.5'
        ).build();

        expect(operation.selling, isA<AssetTypeCreditAlphaNum12>());
        final asset = operation.selling as AssetTypeCreditAlphaNum12;
        expect(asset.code, equals('EUROTOKEN'));
        expect(asset.issuerId, equals(issuerKeyPair.accountId));
      });

      test('creates with native selling asset', () {
        final operation = ManageSellOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '0.4'
        ).build();

        expect(operation.selling, isA<AssetTypeNative>());
        expect(operation.buying, equals(usdAsset));
      });

      test('creates with AlphaNum4 buying asset', () {
        final operation = ManageSellOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '0.4'
        ).build();

        expect(operation.buying, isA<AssetTypeCreditAlphaNum4>());
        final asset = operation.buying as AssetTypeCreditAlphaNum4;
        expect(asset.code, equals('USD'));
      });

      test('creates with AlphaNum12 buying asset', () {
        final operation = ManageSellOfferOperationBuilder(
          nativeAsset,
          euroAsset,
          '100.0',
          '0.4'
        ).build();

        expect(operation.buying, isA<AssetTypeCreditAlphaNum12>());
        final asset = operation.buying as AssetTypeCreditAlphaNum12;
        expect(asset.code, equals('EUROTOKEN'));
      });

      test('creates with decimal precision amount', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0000001',
          '2.5'
        ).build();

        expect(operation.amount, equals('100.0000001'));
      });

      test('creates with decimal precision price', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5555555'
        ).build();

        expect(operation.price, equals('2.5555555'));
      });

      test('creates with large amount', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '922337203685.4775807',
          '1.0'
        ).build();

        expect(operation.amount, equals('922337203685.4775807'));
      });

      test('creates with high price', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '1000.0'
        ).build();

        expect(operation.price, equals('1000.0'));
      });

      test('creates with low price', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '0.0001'
        ).build();

        expect(operation.price, equals('0.0001'));
      });

      test('creates with source account', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).setSourceAccount(sellerKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sellerKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(sellerKeyPair.accountId, BigInt.from(12345));
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sellerKeyPair.accountId));
        expect(operation.sourceAccount!.id, equals(BigInt.from(12345)));
      });

      test('creates with very large offerId', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).setOfferId('9223372036854775807').build();

        expect(operation.offerId, equals('9223372036854775807'));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with new offer', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.MANAGE_SELL_OFFER));
        expect(xdrBody.manageSellOfferOp, isNotNull);

        final restoredBuilder = ManageSellOfferOperation.builder(xdrBody.manageSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeCreditAlphaNum4>());
        final sellingAsset = restored.selling as AssetTypeCreditAlphaNum4;
        expect(sellingAsset.code, equals('USD'));
        expect(sellingAsset.issuerId, equals(issuerKeyPair.accountId));
        expect(restored.buying, isA<AssetTypeNative>());
        expect(restored.amount, equals('100'));
        expect(restored.offerId, equals('0'));
      });

      test('XDR round-trip with existing offerId', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '150.0',
          '2.6'
        ).setOfferId('12345').build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageSellOfferOperation.builder(xdrBody.manageSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.offerId, equals('12345'));
        expect(restored.amount, equals('150'));
      });

      test('XDR round-trip with AlphaNum12 asset', () {
        final operation = ManageSellOfferOperationBuilder(
          euroAsset,
          nativeAsset,
          '100.0',
          '1.5'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageSellOfferOperation.builder(xdrBody.manageSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeCreditAlphaNum12>());
        final sellingAsset = restored.selling as AssetTypeCreditAlphaNum12;
        expect(sellingAsset.code, equals('EUROTOKEN'));
      });

      test('XDR round-trip with native selling asset', () {
        final operation = ManageSellOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '0.4'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageSellOfferOperation.builder(xdrBody.manageSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeNative>());
        expect(restored.buying, isA<AssetTypeCreditAlphaNum4>());
      });

      test('XDR round-trip with decimal precision', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0000001',
          '2.5555555'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageSellOfferOperation.builder(xdrBody.manageSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('100.0000001'));
      });

      test('XDR round-trip with zero amount delete', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '0',
          '2.5'
        ).setOfferId('12345').build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageSellOfferOperation.builder(xdrBody.manageSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('0'));
        expect(restored.offerId, equals('12345'));
      });

      test('XDR round-trip with large offerId', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).setOfferId('9223372036854775807').build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageSellOfferOperation.builder(xdrBody.manageSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.offerId, equals('9223372036854775807'));
      });
    });

    group('builder pattern', () {
      test('builder supports method chaining', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        )
          .setOfferId('12345')
          .setSourceAccount(sellerKeyPair.accountId)
          .build();

        expect(operation, isNotNull);
        expect(operation, isA<ManageSellOfferOperation>());
        expect(operation.offerId, equals('12345'));
        expect(operation.sourceAccount!.ed25519AccountId, equals(sellerKeyPair.accountId));
      });

      test('builder can set muxed source account', () {
        final muxedSource = MuxedAccount(sellerKeyPair.accountId, BigInt.from(99999));
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        )
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(99999)));
      });

      test('builder defaults offerId to 0', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.offerId, equals('0'));
      });
    });

    group('getters', () {
      test('selling getter returns correct asset', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        final selling = operation.selling;
        expect(selling, isA<AssetTypeCreditAlphaNum4>());
        expect((selling as AssetTypeCreditAlphaNum4).code, equals('USD'));
      });

      test('buying getter returns correct asset', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.buying, isA<AssetTypeNative>());
      });

      test('amount getter returns correct amount', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.amount, equals('100.0'));
      });

      test('price getter returns correct price', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.price, equals('2.5'));
      });

      test('offerId getter returns correct offerId', () {
        final operation = ManageSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).setOfferId('12345').build();

        expect(operation.offerId, equals('12345'));
      });
    });
  });

  group('ManageBuyOfferOperation', () {
    late KeyPair buyerKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usdAsset;
    late Asset eurAsset;
    late Asset nativeAsset;

    setUp(() {
      buyerKeyPair = KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      issuerKeyPair = KeyPair.fromAccountId('GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
      eurAsset = AssetTypeCreditAlphaNum4('EUR', issuerKeyPair.accountId);
      nativeAsset = AssetTypeNative();
    });

    group('creation', () {
      test('creates new buy offer with offerId 0', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.selling, equals(nativeAsset));
        expect(operation.buying, equals(usdAsset));
        expect(operation.amount, equals('100.0'));
        expect(operation.price, equals('1.1'));
        expect(operation.offerId, equals('0'));
        expect(operation.sourceAccount, isNull);
      });

      test('updates existing offer with positive offerId', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '150.0',
          '1.15'
        ).setOfferId('54321').build();

        expect(operation.selling, equals(nativeAsset));
        expect(operation.buying, equals(usdAsset));
        expect(operation.amount, equals('150.0'));
        expect(operation.price, equals('1.15'));
        expect(operation.offerId, equals('54321'));
      });

      test('deletes offer with amount 0', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '0',
          '1.1'
        ).setOfferId('54321').build();

        expect(operation.amount, equals('0'));
        expect(operation.offerId, equals('54321'));
      });

      test('creates with AlphaNum4 buying asset', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.buying, isA<AssetTypeCreditAlphaNum4>());
        final asset = operation.buying as AssetTypeCreditAlphaNum4;
        expect(asset.code, equals('USD'));
        expect(asset.issuerId, equals(issuerKeyPair.accountId));
      });

      test('creates with AlphaNum4 selling asset', () {
        final operation = ManageBuyOfferOperationBuilder(
          usdAsset,
          eurAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.selling, isA<AssetTypeCreditAlphaNum4>());
        final asset = operation.selling as AssetTypeCreditAlphaNum4;
        expect(asset.code, equals('USD'));
      });

      test('creates with native selling asset', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.selling, isA<AssetTypeNative>());
        expect(operation.buying, equals(usdAsset));
      });

      test('creates with decimal precision amount', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0000001',
          '1.1'
        ).build();

        expect(operation.amount, equals('100.0000001'));
      });

      test('creates with decimal precision price', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1234567'
        ).build();

        expect(operation.price, equals('1.1234567'));
      });

      test('creates with large amount', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '922337203685.4775807',
          '1.0'
        ).build();

        expect(operation.amount, equals('922337203685.4775807'));
      });

      test('creates with source account', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).setSourceAccount(buyerKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(buyerKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(buyerKeyPair.accountId, BigInt.from(67890));
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(buyerKeyPair.accountId));
        expect(operation.sourceAccount!.id, equals(BigInt.from(67890)));
      });

      test('creates with very large offerId', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).setOfferId('9223372036854775807').build();

        expect(operation.offerId, equals('9223372036854775807'));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with new offer', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.MANAGE_BUY_OFFER));
        expect(xdrBody.manageBuyOfferOp, isNotNull);

        final restoredBuilder = ManageBuyOfferOperation.builder(xdrBody.manageBuyOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeNative>());
        expect(restored.buying, isA<AssetTypeCreditAlphaNum4>());
        final buyingAsset = restored.buying as AssetTypeCreditAlphaNum4;
        expect(buyingAsset.code, equals('USD'));
        expect(buyingAsset.issuerId, equals(issuerKeyPair.accountId));
        expect(restored.amount, equals('100'));
        expect(restored.offerId, equals('0'));
      });

      test('XDR round-trip with existing offerId', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '150.0',
          '1.15'
        ).setOfferId('54321').build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageBuyOfferOperation.builder(xdrBody.manageBuyOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.offerId, equals('54321'));
        expect(restored.amount, equals('150'));
      });

      test('XDR round-trip with AlphaNum4 assets', () {
        final operation = ManageBuyOfferOperationBuilder(
          usdAsset,
          eurAsset,
          '100.0',
          '1.1'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageBuyOfferOperation.builder(xdrBody.manageBuyOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeCreditAlphaNum4>());
        expect(restored.buying, isA<AssetTypeCreditAlphaNum4>());
        final sellingAsset = restored.selling as AssetTypeCreditAlphaNum4;
        final buyingAsset = restored.buying as AssetTypeCreditAlphaNum4;
        expect(sellingAsset.code, equals('USD'));
        expect(buyingAsset.code, equals('EUR'));
      });

      test('XDR round-trip with decimal precision', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0000001',
          '1.1234567'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageBuyOfferOperation.builder(xdrBody.manageBuyOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('100.0000001'));
      });

      test('XDR round-trip with zero amount delete', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '0',
          '1.1'
        ).setOfferId('54321').build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageBuyOfferOperation.builder(xdrBody.manageBuyOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('0'));
        expect(restored.offerId, equals('54321'));
      });

      test('XDR round-trip with large offerId', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).setOfferId('9223372036854775807').build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = ManageBuyOfferOperation.builder(xdrBody.manageBuyOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.offerId, equals('9223372036854775807'));
      });
    });

    group('builder pattern', () {
      test('builder supports method chaining', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        )
          .setOfferId('54321')
          .setSourceAccount(buyerKeyPair.accountId)
          .build();

        expect(operation, isNotNull);
        expect(operation, isA<ManageBuyOfferOperation>());
        expect(operation.offerId, equals('54321'));
        expect(operation.sourceAccount!.ed25519AccountId, equals(buyerKeyPair.accountId));
      });

      test('builder can set muxed source account', () {
        final muxedSource = MuxedAccount(buyerKeyPair.accountId, BigInt.from(11111));
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        )
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(11111)));
      });

      test('builder defaults offerId to 0', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.offerId, equals('0'));
      });
    });

    group('getters', () {
      test('selling getter returns correct asset', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.selling, isA<AssetTypeNative>());
      });

      test('buying getter returns correct asset', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        final buying = operation.buying;
        expect(buying, isA<AssetTypeCreditAlphaNum4>());
        expect((buying as AssetTypeCreditAlphaNum4).code, equals('USD'));
      });

      test('amount getter returns correct amount', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.amount, equals('100.0'));
      });

      test('price getter returns correct price', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).build();

        expect(operation.price, equals('1.1'));
      });

      test('offerId getter returns correct offerId', () {
        final operation = ManageBuyOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '1.1'
        ).setOfferId('54321').build();

        expect(operation.offerId, equals('54321'));
      });
    });
  });

  group('CreatePassiveSellOfferOperation', () {
    late KeyPair sellerKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usdAsset;
    late Asset euroAsset;
    late Asset nativeAsset;

    setUp(() {
      sellerKeyPair = KeyPair.fromAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      issuerKeyPair = KeyPair.fromAccountId('GCEZWKCA5VLDNRLN3RPRJMRZOX3Z6G5CHCGSNFHEYVXM3XOJMDS674JZ');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
      euroAsset = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);
      nativeAsset = AssetTypeNative();
    });

    group('creation', () {
      test('creates passive sell offer', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.selling, equals(usdAsset));
        expect(operation.buying, equals(nativeAsset));
        expect(operation.amount, equals('100.0'));
        expect(operation.price, equals('2.5'));
        expect(operation.sourceAccount, isNull);
      });

      test('creates with AlphaNum4 selling asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '1.5'
        ).build();

        expect(operation.selling, isA<AssetTypeCreditAlphaNum4>());
        final asset = operation.selling as AssetTypeCreditAlphaNum4;
        expect(asset.code, equals('USD'));
        expect(asset.issuerId, equals(issuerKeyPair.accountId));
      });

      test('creates with AlphaNum12 selling asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          euroAsset,
          nativeAsset,
          '100.0',
          '1.5'
        ).build();

        expect(operation.selling, isA<AssetTypeCreditAlphaNum12>());
        final asset = operation.selling as AssetTypeCreditAlphaNum12;
        expect(asset.code, equals('EUROTOKEN'));
        expect(asset.issuerId, equals(issuerKeyPair.accountId));
      });

      test('creates with native selling asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '0.4'
        ).build();

        expect(operation.selling, isA<AssetTypeNative>());
        expect(operation.buying, equals(usdAsset));
      });

      test('creates with AlphaNum4 buying asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '0.4'
        ).build();

        expect(operation.buying, isA<AssetTypeCreditAlphaNum4>());
        final asset = operation.buying as AssetTypeCreditAlphaNum4;
        expect(asset.code, equals('USD'));
      });

      test('creates with AlphaNum12 buying asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          nativeAsset,
          euroAsset,
          '100.0',
          '0.4'
        ).build();

        expect(operation.buying, isA<AssetTypeCreditAlphaNum12>());
        final asset = operation.buying as AssetTypeCreditAlphaNum12;
        expect(asset.code, equals('EUROTOKEN'));
      });

      test('creates with decimal precision amount', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0000001',
          '2.5'
        ).build();

        expect(operation.amount, equals('100.0000001'));
      });

      test('creates with decimal precision price', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5555555'
        ).build();

        expect(operation.price, equals('2.5555555'));
      });

      test('creates with large amount', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '922337203685.4775807',
          '1.0'
        ).build();

        expect(operation.amount, equals('922337203685.4775807'));
      });

      test('creates with high price', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '1000.0'
        ).build();

        expect(operation.price, equals('1000.0'));
      });

      test('creates with low price', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '0.0001'
        ).build();

        expect(operation.price, equals('0.0001'));
      });

      test('creates with source account', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).setSourceAccount(sellerKeyPair.accountId).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sellerKeyPair.accountId));
      });

      test('creates with muxed source account', () {
        final muxedSource = MuxedAccount(sellerKeyPair.accountId, BigInt.from(33333));
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).setMuxedSourceAccount(muxedSource).build();

        expect(operation.sourceAccount, isNotNull);
        expect(operation.sourceAccount!.ed25519AccountId, equals(sellerKeyPair.accountId));
        expect(operation.sourceAccount!.id, equals(BigInt.from(33333)));
      });
    });

    group('XDR serialization', () {
      test('XDR round-trip with passive offer', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        final xdrBody = operation.toOperationBody();
        expect(xdrBody.discriminant, equals(XdrOperationType.CREATE_PASSIVE_SELL_OFFER));
        expect(xdrBody.createPassiveSellOfferOp, isNotNull);

        final restoredBuilder = CreatePassiveSellOfferOperation.builder(xdrBody.createPassiveSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeCreditAlphaNum4>());
        final sellingAsset = restored.selling as AssetTypeCreditAlphaNum4;
        expect(sellingAsset.code, equals('USD'));
        expect(sellingAsset.issuerId, equals(issuerKeyPair.accountId));
        expect(restored.buying, isA<AssetTypeNative>());
        expect(restored.amount, equals('100'));
      });

      test('XDR round-trip with AlphaNum12 asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          euroAsset,
          nativeAsset,
          '100.0',
          '1.5'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = CreatePassiveSellOfferOperation.builder(xdrBody.createPassiveSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeCreditAlphaNum12>());
        final sellingAsset = restored.selling as AssetTypeCreditAlphaNum12;
        expect(sellingAsset.code, equals('EUROTOKEN'));
      });

      test('XDR round-trip with native selling asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          nativeAsset,
          usdAsset,
          '100.0',
          '0.4'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = CreatePassiveSellOfferOperation.builder(xdrBody.createPassiveSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.selling, isA<AssetTypeNative>());
        expect(restored.buying, isA<AssetTypeCreditAlphaNum4>());
      });

      test('XDR round-trip with decimal precision', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0000001',
          '2.5555555'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = CreatePassiveSellOfferOperation.builder(xdrBody.createPassiveSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('100.0000001'));
      });

      test('XDR round-trip with large amount', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '922337203685.4775807',
          '1.0'
        ).build();

        final xdrBody = operation.toOperationBody();
        final restoredBuilder = CreatePassiveSellOfferOperation.builder(xdrBody.createPassiveSellOfferOp!);
        final restored = restoredBuilder.build();

        expect(restored.amount, equals('922337203685.4775807'));
      });
    });

    group('builder pattern', () {
      test('builder supports method chaining', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        )
          .setSourceAccount(sellerKeyPair.accountId)
          .build();

        expect(operation, isNotNull);
        expect(operation, isA<CreatePassiveSellOfferOperation>());
        expect(operation.sourceAccount!.ed25519AccountId, equals(sellerKeyPair.accountId));
      });

      test('builder can set muxed source account', () {
        final muxedSource = MuxedAccount(sellerKeyPair.accountId, BigInt.from(44444));
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        )
          .setMuxedSourceAccount(muxedSource)
          .build();

        expect(operation.sourceAccount!.id, equals(BigInt.from(44444)));
      });
    });

    group('getters', () {
      test('selling getter returns correct asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        final selling = operation.selling;
        expect(selling, isA<AssetTypeCreditAlphaNum4>());
        expect((selling as AssetTypeCreditAlphaNum4).code, equals('USD'));
      });

      test('buying getter returns correct asset', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.buying, isA<AssetTypeNative>());
      });

      test('amount getter returns correct amount', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.amount, equals('100.0'));
      });

      test('price getter returns correct price', () {
        final operation = CreatePassiveSellOfferOperationBuilder(
          usdAsset,
          nativeAsset,
          '100.0',
          '2.5'
        ).build();

        expect(operation.price, equals('2.5'));
      });
    });
  });

  group('Offer Operations Integration', () {
    late KeyPair makerKeyPair;
    late KeyPair issuerKeyPair;
    late Asset usdAsset;
    late Asset eurAsset;

    setUp(() {
      makerKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      issuerKeyPair = KeyPair.fromSecretSeed('SCZANGBA5YHTNYVVV4C3U252E2B6P6F5T3U6MM63WBSBZATAQI3EBTQ4');
      usdAsset = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
      eurAsset = AssetTypeCreditAlphaNum4('EUR', issuerKeyPair.accountId);
    });

    test('manage sell offer operation can be added to transaction', () {
      final sourceAccount = Account(makerKeyPair.accountId, BigInt.from(2908908335136768));

      final manageSellOffer = ManageSellOfferOperationBuilder(
        usdAsset,
        AssetTypeNative(),
        '100.0',
        '2.5'
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageSellOffer)
        .build();

      expect(transaction.operations.length, equals(1));
      expect(transaction.operations[0], isA<ManageSellOfferOperation>());
    });

    test('manage buy offer operation can be added to transaction', () {
      final sourceAccount = Account(makerKeyPair.accountId, BigInt.from(2908908335136768));

      final manageBuyOffer = ManageBuyOfferOperationBuilder(
        AssetTypeNative(),
        usdAsset,
        '100.0',
        '1.1'
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageBuyOffer)
        .build();

      expect(transaction.operations.length, equals(1));
      expect(transaction.operations[0], isA<ManageBuyOfferOperation>());
    });

    test('create passive sell offer operation can be added to transaction', () {
      final sourceAccount = Account(makerKeyPair.accountId, BigInt.from(2908908335136768));

      final passiveOffer = CreatePassiveSellOfferOperationBuilder(
        usdAsset,
        AssetTypeNative(),
        '100.0',
        '2.5'
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(passiveOffer)
        .build();

      expect(transaction.operations.length, equals(1));
      expect(transaction.operations[0], isA<CreatePassiveSellOfferOperation>());
    });

    test('multiple offer operations in single transaction', () {
      final sourceAccount = Account(makerKeyPair.accountId, BigInt.from(2908908335136768));

      final manageSellOffer = ManageSellOfferOperationBuilder(
        usdAsset,
        AssetTypeNative(),
        '100.0',
        '2.5'
      ).build();

      final manageBuyOffer = ManageBuyOfferOperationBuilder(
        AssetTypeNative(),
        eurAsset,
        '50.0',
        '1.1'
      ).build();

      final passiveOffer = CreatePassiveSellOfferOperationBuilder(
        eurAsset,
        usdAsset,
        '75.0',
        '0.9'
      ).build();

      final transaction = TransactionBuilder(sourceAccount)
        .addOperation(manageSellOffer)
        .addOperation(manageBuyOffer)
        .addOperation(passiveOffer)
        .build();

      expect(transaction.operations.length, equals(3));
      expect(transaction.operations[0], isA<ManageSellOfferOperation>());
      expect(transaction.operations[1], isA<ManageBuyOfferOperation>());
      expect(transaction.operations[2], isA<CreatePassiveSellOfferOperation>());
    });

    test('offer operations with different asset types', () {
      final usd4 = AssetTypeCreditAlphaNum4('USD', issuerKeyPair.accountId);
      final euro12 = AssetTypeCreditAlphaNum12('EUROTOKEN', issuerKeyPair.accountId);

      final sellOffer = ManageSellOfferOperationBuilder(
        usd4,
        AssetTypeNative(),
        '100.0',
        '2.5'
      ).build();

      final buyOffer = ManageBuyOfferOperationBuilder(
        AssetTypeNative(),
        euro12,
        '100.0',
        '1.1'
      ).build();

      expect(sellOffer.selling, isA<AssetTypeCreditAlphaNum4>());
      expect(buyOffer.buying, isA<AssetTypeCreditAlphaNum12>());
    });

    test('create and update offer workflow', () {
      final sourceAccount = Account(makerKeyPair.accountId, BigInt.from(2908908335136768));

      final createOffer = ManageSellOfferOperationBuilder(
        usdAsset,
        AssetTypeNative(),
        '100.0',
        '2.5'
      ).build();

      expect(createOffer.offerId, equals('0'));

      final updateOffer = ManageSellOfferOperationBuilder(
        usdAsset,
        AssetTypeNative(),
        '150.0',
        '2.6'
      ).setOfferId('12345').build();

      expect(updateOffer.offerId, equals('12345'));
      expect(updateOffer.amount, equals('150.0'));
    });

    test('delete offer with zero amount', () {
      final deleteOffer = ManageSellOfferOperationBuilder(
        usdAsset,
        AssetTypeNative(),
        '0',
        '2.5'
      ).setOfferId('12345').build();

      expect(deleteOffer.amount, equals('0'));
      expect(deleteOffer.offerId, equals('12345'));
    });

    test('offer operations preserve price precision', () {
      final sellOffer = ManageSellOfferOperationBuilder(
        usdAsset,
        AssetTypeNative(),
        '100.0000001',
        '2.5555555'
      ).build();

      final buyOffer = ManageBuyOfferOperationBuilder(
        AssetTypeNative(),
        usdAsset,
        '100.0000001',
        '1.1234567'
      ).build();

      expect(sellOffer.amount, equals('100.0000001'));
      expect(sellOffer.price, equals('2.5555555'));
      expect(buyOffer.amount, equals('100.0000001'));
      expect(buyOffer.price, equals('1.1234567'));
    });
  });
}
