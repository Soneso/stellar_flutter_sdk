import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('AssetTypeNative', () {
    test('create native asset', () {
      final nativeAsset = AssetTypeNative();

      expect(nativeAsset, isNotNull);
      expect(nativeAsset, isA<AssetTypeNative>());
      expect(nativeAsset, isA<Asset>());
    });

    test('native asset type is "native"', () {
      final nativeAsset = AssetTypeNative();

      expect(nativeAsset.type, equals(Asset.TYPE_NATIVE));
      expect(nativeAsset.type, equals('native'));
    });

    test('native asset XDR round-trip', () {
      final originalAsset = AssetTypeNative();

      final xdrAsset = originalAsset.toXdr();
      final restoredAsset = Asset.fromXdr(xdrAsset);

      expect(restoredAsset, isA<AssetTypeNative>());
      expect(restoredAsset.type, equals(Asset.TYPE_NATIVE));
      expect(restoredAsset, equals(originalAsset));
    });

    test('native asset equality', () {
      final native1 = AssetTypeNative();
      final native2 = AssetTypeNative();
      final native3 = Asset.NATIVE;

      expect(native1, equals(native2));
      expect(native1, equals(native3));
      expect(native2, equals(native3));
      expect(native1.hashCode, equals(native2.hashCode));
      expect(native1.hashCode, equals(0));
    });
  });

  group('AssetTypeCreditAlphanum4', () {
    final validIssuerId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

    test('create credit alphanum4 with valid code', () {
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);

      expect(usd, isNotNull);
      expect(usd, isA<AssetTypeCreditAlphaNum4>());
      expect(usd, isA<AssetTypeCreditAlphaNum>());
      expect(usd, isA<Asset>());
      expect(usd.code, equals('USD'));
      expect(usd.issuerId, equals(validIssuerId));
      expect(usd.type, equals(Asset.TYPE_CREDIT_ALPHANUM4));
    });

    test('code must be <= 4 characters', () {
      // Valid lengths: 1-4 characters
      expect(() => AssetTypeCreditAlphaNum4('X', validIssuerId), returnsNormally);
      expect(() => AssetTypeCreditAlphaNum4('AB', validIssuerId), returnsNormally);
      expect(() => AssetTypeCreditAlphaNum4('USD', validIssuerId), returnsNormally);
      expect(() => AssetTypeCreditAlphaNum4('ABCD', validIssuerId), returnsNormally);

      // Invalid: too long (>4 characters)
      expect(
        () => AssetTypeCreditAlphaNum4('TOOLONG', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );
      expect(
        () => AssetTypeCreditAlphaNum4('ABCDE', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );
    });

    test('code cannot be empty', () {
      expect(
        () => AssetTypeCreditAlphaNum4('', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );
    });

    test('issuer must be valid account ID', () {
      // Valid issuer
      final validAsset = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      expect(() => validAsset.toXdr(), returnsNormally);

      // Invalid issuer format - error only occurs when converting to XDR
      final invalidAsset = AssetTypeCreditAlphaNum4('USD', 'INVALID_ISSUER');
      expect(
        () => invalidAsset.toXdr(),
        throwsA(isA<FormatException>()),
      );
    });

    test('XDR round-trip', () {
      final originalAsset = AssetTypeCreditAlphaNum4('USD', validIssuerId);

      final xdrAsset = originalAsset.toXdr();
      final restoredAsset = Asset.fromXdr(xdrAsset);

      expect(restoredAsset, isA<AssetTypeCreditAlphaNum4>());
      expect((restoredAsset as AssetTypeCreditAlphaNum4).code, equals('USD'));
      expect(restoredAsset.issuerId, equals(validIssuerId));
      expect(restoredAsset, equals(originalAsset));
    });

    test('equality comparison', () {
      final usd1 = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final usd2 = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final eur = AssetTypeCreditAlphaNum4('EUR', validIssuerId);
      final otherIssuerId = 'GD5J6HLF5666X4AZLTFTXLY46J5SW7EXRKBLEYPJP33S33MXZGV6CWFN';
      final usd3 = AssetTypeCreditAlphaNum4('USD', otherIssuerId);
      final native = AssetTypeNative();

      // Same code and issuer
      expect(usd1, equals(usd2));
      expect(usd1.hashCode, equals(usd2.hashCode));

      // Different code
      expect(usd1, isNot(equals(eur)));

      // Different issuer
      expect(usd1, isNot(equals(usd3)));

      // Different type
      expect(usd1, isNot(equals(native)));
    });
  });

  group('AssetTypeCreditAlphanum12', () {
    final validIssuerId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

    test('create credit alphanum12 with valid code (5-12 chars)', () {
      final longAsset = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);

      expect(longAsset, isNotNull);
      expect(longAsset, isA<AssetTypeCreditAlphaNum12>());
      expect(longAsset, isA<AssetTypeCreditAlphaNum>());
      expect(longAsset, isA<Asset>());
      expect(longAsset.code, equals('LONGASSET'));
      expect(longAsset.issuerId, equals(validIssuerId));
      expect(longAsset.type, equals(Asset.TYPE_CREDIT_ALPHANUM12));
    });

    test('code must be > 4 and <= 12 characters', () {
      // Valid lengths: 5-12 characters
      expect(() => AssetTypeCreditAlphaNum12('ABCDE', validIssuerId), returnsNormally);
      expect(() => AssetTypeCreditAlphaNum12('SIXCHA', validIssuerId), returnsNormally);
      expect(() => AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId), returnsNormally);
      expect(() => AssetTypeCreditAlphaNum12('TWELVECHARS', validIssuerId), returnsNormally);
      expect(() => AssetTypeCreditAlphaNum12('EXACTLYTWELV', validIssuerId), returnsNormally);

      // Invalid: too short (<=4 characters)
      expect(
        () => AssetTypeCreditAlphaNum12('USD', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );
      expect(
        () => AssetTypeCreditAlphaNum12('ABCD', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );

      // Invalid: too long (>12 characters)
      expect(
        () => AssetTypeCreditAlphaNum12('TOOLONGASSETCODE', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );
      expect(
        () => AssetTypeCreditAlphaNum12('THIRTEENCHARS', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );
    });

    test('XDR round-trip', () {
      final originalAsset = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);

      final xdrAsset = originalAsset.toXdr();
      final restoredAsset = Asset.fromXdr(xdrAsset);

      expect(restoredAsset, isA<AssetTypeCreditAlphaNum12>());
      expect((restoredAsset as AssetTypeCreditAlphaNum12).code, equals('LONGASSET'));
      expect(restoredAsset.issuerId, equals(validIssuerId));
      expect(restoredAsset, equals(originalAsset));
    });

    test('equality comparison', () {
      final long1 = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);
      final long2 = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);
      final other = AssetTypeCreditAlphaNum12('OTHERASSET', validIssuerId);
      final otherIssuerId = 'GD5J6HLF5666X4AZLTFTXLY46J5SW7EXRKBLEYPJP33S33MXZGV6CWFN';
      final long3 = AssetTypeCreditAlphaNum12('LONGASSET', otherIssuerId);
      final native = AssetTypeNative();

      // Same code and issuer
      expect(long1, equals(long2));
      expect(long1.hashCode, equals(long2.hashCode));

      // Different code
      expect(long1, isNot(equals(other)));

      // Different issuer
      expect(long1, isNot(equals(long3)));

      // Different type
      expect(long1, isNot(equals(native)));
    });
  });

  group('Asset factory methods', () {
    final validIssuerId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

    test('Asset.create() returns native for "native" or "XLM"', () {
      final nativeFromType = Asset.create(Asset.TYPE_NATIVE, null, null);
      expect(nativeFromType, isA<AssetTypeNative>());
      expect(nativeFromType.type, equals(Asset.TYPE_NATIVE));
    });

    test('Asset.create() returns alphanum4 for short codes', () {
      final usd = Asset.create(Asset.TYPE_CREDIT_ALPHANUM4, 'USD', validIssuerId);

      expect(usd, isA<AssetTypeCreditAlphaNum4>());
      expect((usd as AssetTypeCreditAlphaNum4).code, equals('USD'));
      expect(usd.issuerId, equals(validIssuerId));
    });

    test('Asset.create() returns alphanum12 for long codes', () {
      final longAsset = Asset.create(Asset.TYPE_CREDIT_ALPHANUM12, 'LONGASSET', validIssuerId);

      expect(longAsset, isA<AssetTypeCreditAlphaNum12>());
      expect((longAsset as AssetTypeCreditAlphaNum12).code, equals('LONGASSET'));
      expect(longAsset.issuerId, equals(validIssuerId));
    });

    test('Asset.createNonNativeAsset() works correctly', () {
      // Short code (1-4 chars) -> AlphaNum4
      final usd = Asset.createNonNativeAsset('USD', validIssuerId);
      expect(usd, isA<AssetTypeCreditAlphaNum4>());
      expect((usd as AssetTypeCreditAlphaNum4).code, equals('USD'));

      final btc = Asset.createNonNativeAsset('BTC', validIssuerId);
      expect(btc, isA<AssetTypeCreditAlphaNum4>());

      final abcd = Asset.createNonNativeAsset('ABCD', validIssuerId);
      expect(abcd, isA<AssetTypeCreditAlphaNum4>());

      // Long code (5-12 chars) -> AlphaNum12
      final longAsset = Asset.createNonNativeAsset('LONGASSET', validIssuerId);
      expect(longAsset, isA<AssetTypeCreditAlphaNum12>());
      expect((longAsset as AssetTypeCreditAlphaNum12).code, equals('LONGASSET'));

      final abcde = Asset.createNonNativeAsset('ABCDE', validIssuerId);
      expect(abcde, isA<AssetTypeCreditAlphaNum12>());

      final twelve = Asset.createNonNativeAsset('TWELVECHARS', validIssuerId);
      expect(twelve, isA<AssetTypeCreditAlphaNum12>());
    });
  });

  group('AssetTypePoolShare', () {
    final validIssuerId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

    test('create pool share asset', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);

      final poolShare = AssetTypePoolShare(assetA: xlm, assetB: usd);

      expect(poolShare, isNotNull);
      expect(poolShare, isA<AssetTypePoolShare>());
      expect(poolShare, isA<Asset>());
      expect(poolShare.type, equals(Asset.TYPE_POOL_SHARE));
      expect(poolShare.assetA, equals(xlm));
      expect(poolShare.assetB, equals(usd));
    });

    test('pool share XDR round-trip', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final originalPoolShare = AssetTypePoolShare(assetA: xlm, assetB: usd);

      final xdrAsset = originalPoolShare.toXdrChangeTrustAsset();
      final restoredAsset = Asset.fromXdr(xdrAsset);

      expect(restoredAsset, isA<AssetTypePoolShare>());
      expect((restoredAsset as AssetTypePoolShare).assetA, equals(xlm));
      expect(restoredAsset.assetB, equals(usd));
    });

    test('pool share assets must be in correct order', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);

      // Correct order: Native before AlphaNum4
      expect(() => AssetTypePoolShare(assetA: xlm, assetB: usd), returnsNormally);

      // Incorrect order: AlphaNum4 before Native
      expect(
        () => AssetTypePoolShare(assetA: usd, assetB: xlm),
        throwsA(isA<Exception>()),
      );
    });

    test('pool share cannot contain pool share assets', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final poolShare = AssetTypePoolShare(assetA: xlm, assetB: usd);

      expect(
        () => AssetTypePoolShare(assetA: poolShare, assetB: usd),
        throwsA(isA<Exception>()),
      );
    });

    test('pool share cannot have both assets as native', () {
      final xlm1 = AssetTypeNative();
      final xlm2 = AssetTypeNative();

      expect(
        () => AssetTypePoolShare(assetA: xlm1, assetB: xlm2),
        throwsA(isA<Exception>()),
      );
    });

    test('pool share equality', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final pool1 = AssetTypePoolShare(assetA: xlm, assetB: usd);
      final pool2 = AssetTypePoolShare(assetA: xlm, assetB: usd);

      expect(pool1, equals(pool2));
      expect(pool1.hashCode, equals(pool2.hashCode));
    });
  });

  group('Edge cases', () {
    final validIssuerId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

    test('invalid asset code throws', () {
      // Empty code
      expect(
        () => Asset.createNonNativeAsset('', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );

      // Code too long (>12 characters)
      expect(
        () => Asset.createNonNativeAsset('CODEWAYTOOOLONG', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );

      expect(
        () => Asset.createNonNativeAsset('THIRTEENCHARS', validIssuerId),
        throwsA(isA<AssetCodeLengthInvalidException>()),
      );
    });

    test('invalid issuer throws', () {
      // Invalid format - error only occurs when converting to XDR
      final invalidAsset1 = AssetTypeCreditAlphaNum4('USD', 'INVALID');
      expect(
        () => invalidAsset1.toXdr(),
        throwsA(isA<FormatException>()),
      );

      // Empty issuer throws RangeError
      final invalidAsset2 = AssetTypeCreditAlphaNum4('USD', '');
      expect(
        () => invalidAsset2.toXdr(),
        throwsA(isA<RangeError>()),
      );

      // Wrong prefix (secret seed instead of account ID)
      final invalidAsset3 = AssetTypeCreditAlphaNum4('USD', 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      expect(
        () => invalidAsset3.toXdr(),
        throwsA(isA<FormatException>()),
      );
    });

    test('asset canonical string format', () {
      // Native asset
      final native = AssetTypeNative();
      expect(Asset.canonicalForm(native), equals('native'));

      // AlphaNum4 asset
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      expect(Asset.canonicalForm(usd), equals('USD:$validIssuerId'));

      // AlphaNum12 asset
      final longAsset = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);
      expect(Asset.canonicalForm(longAsset), equals('LONGASSET:$validIssuerId'));
    });

    test('createFromCanonicalForm handles valid formats', () {
      // Native asset
      final native1 = Asset.createFromCanonicalForm('native');
      expect(native1, isA<AssetTypeNative>());

      final native2 = Asset.createFromCanonicalForm('XLM');
      expect(native2, isA<AssetTypeNative>());

      // AlphaNum4 asset
      final usd = Asset.createFromCanonicalForm('USD:$validIssuerId');
      expect(usd, isA<AssetTypeCreditAlphaNum4>());
      expect((usd as AssetTypeCreditAlphaNum4).code, equals('USD'));
      expect(usd.issuerId, equals(validIssuerId));

      // AlphaNum12 asset
      final longAsset = Asset.createFromCanonicalForm('LONGASSET:$validIssuerId');
      expect(longAsset, isA<AssetTypeCreditAlphaNum12>());
      expect((longAsset as AssetTypeCreditAlphaNum12).code, equals('LONGASSET'));
      expect(longAsset.issuerId, equals(validIssuerId));
    });

    test('createFromCanonicalForm handles invalid formats', () {
      // Null input
      expect(Asset.createFromCanonicalForm(null), isNull);

      // Invalid format (no colon)
      expect(Asset.createFromCanonicalForm('USD'), isNull);

      // Invalid format (too many colons)
      expect(Asset.createFromCanonicalForm('USD:ISSUER:EXTRA'), isNull);

      // Code too long (>12 chars)
      expect(Asset.createFromCanonicalForm('CODEWAYTOOOLONG:$validIssuerId'), isNull);
    });

    test('case sensitive asset codes', () {
      final usdUpper = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final usdLower = AssetTypeCreditAlphaNum4('usd', validIssuerId);

      expect(usdUpper, isNot(equals(usdLower)));
      expect(usdUpper.code, isNot(equals(usdLower.code)));
    });

    test('Asset.NATIVE singleton', () {
      final native1 = Asset.NATIVE;
      final native2 = Asset.NATIVE;

      expect(identical(native1, native2), isTrue);
      expect(native1, isA<AssetTypeNative>());
    });

    test('fromJson creates assets correctly', () {
      // Native asset
      final nativeJson = {'asset_type': 'native'};
      final native = Asset.fromJson(nativeJson);
      expect(native, isA<AssetTypeNative>());

      // AlphaNum4 asset
      final usdJson = {
        'asset_type': 'credit_alphanum4',
        'asset_code': 'USD',
        'asset_issuer': validIssuerId,
      };
      final usd = Asset.fromJson(usdJson);
      expect(usd, isA<AssetTypeCreditAlphaNum4>());
      expect((usd as AssetTypeCreditAlphaNum4).code, equals('USD'));
      expect(usd.issuerId, equals(validIssuerId));

      // AlphaNum12 asset
      final longJson = {
        'asset_type': 'credit_alphanum12',
        'asset_code': 'LONGASSET',
        'asset_issuer': validIssuerId,
      };
      final longAsset = Asset.fromJson(longJson);
      expect(longAsset, isA<AssetTypeCreditAlphaNum12>());
      expect((longAsset as AssetTypeCreditAlphaNum12).code, equals('LONGASSET'));
      expect(longAsset.issuerId, equals(validIssuerId));
    });

    test('XDR ChangeTrustAsset conversion', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final longAsset = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);

      expect(xlm.toXdrChangeTrustAsset(), isNotNull);
      expect(usd.toXdrChangeTrustAsset(), isNotNull);
      expect(longAsset.toXdrChangeTrustAsset(), isNotNull);
    });

    test('XDR TrustlineAsset conversion', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final longAsset = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);

      expect(xlm.toXdrTrustLineAsset(), isNotNull);
      expect(usd.toXdrTrustLineAsset(), isNotNull);
      expect(longAsset.toXdrTrustLineAsset(), isNotNull);
    });

    test('pool share toXdrTrustLineAsset throws exception', () {
      final xlm = AssetTypeNative();
      final usd = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final poolShare = AssetTypePoolShare(assetA: xlm, assetB: usd);

      expect(
        () => poolShare.toXdrTrustLineAsset(),
        throwsA(isA<Exception>()),
      );
    });

    test('pool share asset ordering by type', () {
      final xlm = AssetTypeNative();
      final usd4 = AssetTypeCreditAlphaNum4('USD', validIssuerId);
      final long12 = AssetTypeCreditAlphaNum12('LONGASSET', validIssuerId);

      // Native < AlphaNum4
      expect(() => AssetTypePoolShare(assetA: xlm, assetB: usd4), returnsNormally);

      // AlphaNum4 < AlphaNum12
      expect(() => AssetTypePoolShare(assetA: usd4, assetB: long12), returnsNormally);
    });

    test('pool share asset ordering by code', () {
      final otherIssuerId = 'GD5J6HLF5666X4AZLTFTXLY46J5SW7EXRKBLEYPJP33S33MXZGV6CWFN';
      final abc = AssetTypeCreditAlphaNum4('ABC', validIssuerId);
      final xyz = AssetTypeCreditAlphaNum4('XYZ', otherIssuerId);

      // Correct order: ABC < XYZ
      expect(() => AssetTypePoolShare(assetA: abc, assetB: xyz), returnsNormally);

      // Incorrect order: XYZ > ABC
      expect(
        () => AssetTypePoolShare(assetA: xyz, assetB: abc),
        throwsA(isA<Exception>()),
      );
    });

    test('pool share asset ordering by issuer', () {
      final issuer1 = 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
      final issuer2 = 'GD5J6HLF5666X4AZLTFTXLY46J5SW7EXRKBLEYPJP33S33MXZGV6CWFN';
      final usd1 = AssetTypeCreditAlphaNum4('USD', issuer1);
      final usd2 = AssetTypeCreditAlphaNum4('USD', issuer2);

      // Correct order based on lexicographic issuer comparison
      if (issuer1.compareTo(issuer2) < 0) {
        expect(() => AssetTypePoolShare(assetA: usd1, assetB: usd2), returnsNormally);
      } else {
        expect(() => AssetTypePoolShare(assetA: usd2, assetB: usd1), returnsNormally);
      }
    });
  });
}
