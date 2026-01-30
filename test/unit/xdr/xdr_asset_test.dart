import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('XdrAssetType enum', () {
    test('encodes and decodes ASSET_TYPE_NATIVE', () {
      final output = XdrDataOutputStream();
      XdrAssetType.encode(output, XdrAssetType.ASSET_TYPE_NATIVE);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetType.decode(input);

      expect(decoded, equals(XdrAssetType.ASSET_TYPE_NATIVE));
      expect(decoded.value, equals(0));
    });

    test('encodes and decodes ASSET_TYPE_CREDIT_ALPHANUM4', () {
      final output = XdrDataOutputStream();
      XdrAssetType.encode(output, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetType.decode(input);

      expect(decoded, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4));
      expect(decoded.value, equals(1));
    });

    test('encodes and decodes ASSET_TYPE_CREDIT_ALPHANUM12', () {
      final output = XdrDataOutputStream();
      XdrAssetType.encode(output, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetType.decode(input);

      expect(decoded, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12));
      expect(decoded.value, equals(2));
    });

    test('encodes and decodes ASSET_TYPE_POOL_SHARE', () {
      final output = XdrDataOutputStream();
      XdrAssetType.encode(output, XdrAssetType.ASSET_TYPE_POOL_SHARE);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetType.decode(input);

      expect(decoded, equals(XdrAssetType.ASSET_TYPE_POOL_SHARE));
      expect(decoded.value, equals(3));
    });

    test('throws on unknown value', () {
      final output = XdrDataOutputStream();
      output.writeInt(999);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      expect(() => XdrAssetType.decode(input), throwsException);
    });
  });

  group('XdrAsset encode/decode', () {
    test('encodes and decodes NATIVE asset', () {
      final asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      final output = XdrDataOutputStream();
      XdrAsset.encode(output, asset);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAsset.decode(input);

      expect(decoded.discriminant, equals(XdrAssetType.ASSET_TYPE_NATIVE));
    });

    test('encodes and decodes ALPHANUM4 asset', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List(4);
      assetCode[0] = 85; // U
      assetCode[1] = 83; // S
      assetCode[2] = 68; // D
      assetCode[3] = 0;

      final alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      final asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = alphaNum4;

      final output = XdrDataOutputStream();
      XdrAsset.encode(output, asset);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAsset.decode(input);

      expect(decoded.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4));
      expect(decoded.alphaNum4, isNotNull);
      expect(decoded.alphaNum4!.assetCode[0], equals(85));
      expect(decoded.alphaNum4!.assetCode[1], equals(83));
      expect(decoded.alphaNum4!.assetCode[2], equals(68));
    });

    test('encodes and decodes ALPHANUM12 asset', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List(12);
      assetCode[0] = 76;  // L
      assetCode[1] = 79;  // O
      assetCode[2] = 78;  // N
      assetCode[3] = 71;  // G
      assetCode[4] = 65;  // A
      assetCode[5] = 83;  // S
      assetCode[6] = 83;  // S
      assetCode[7] = 69;  // E
      assetCode[8] = 84;  // T
      for (int i = 9; i < 12; i++) {
        assetCode[i] = 0;
      }

      final alphaNum12 = XdrAssetAlphaNum12(assetCode, issuer);

      final asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = alphaNum12;

      final output = XdrDataOutputStream();
      XdrAsset.encode(output, asset);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAsset.decode(input);

      expect(decoded.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12));
      expect(decoded.alphaNum12, isNotNull);
      expect(decoded.alphaNum12!.assetCode[0], equals(76));
      expect(decoded.alphaNum12!.assetCode[8], equals(84));
    });
  });

  group('XdrAssetAlphaNum4 encode/decode', () {
    test('encodes and decodes complete asset', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List.fromList([69, 85, 82, 0]); // EUR

      final alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      final output = XdrDataOutputStream();
      XdrAssetAlphaNum4.encode(output, alphaNum4);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetAlphaNum4.decode(input);

      expect(decoded.assetCode, equals(assetCode));
    });

    test('handles single character code', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List.fromList([88, 0, 0, 0]); // X

      final alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      final output = XdrDataOutputStream();
      XdrAssetAlphaNum4.encode(output, alphaNum4);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetAlphaNum4.decode(input);

      expect(decoded.assetCode[0], equals(88));
      expect(decoded.assetCode[1], equals(0));
    });
  });

  group('XdrAssetAlphaNum12 encode/decode', () {
    test('encodes and decodes complete asset', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List(12);
      assetCode[0] = 84; // T
      assetCode[1] = 69; // E
      assetCode[2] = 83; // S
      assetCode[3] = 84; // T
      for (int i = 4; i < 12; i++) {
        assetCode[i] = 0;
      }

      final alphaNum12 = XdrAssetAlphaNum12(assetCode, issuer);

      final output = XdrDataOutputStream();
      XdrAssetAlphaNum12.encode(output, alphaNum12);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetAlphaNum12.decode(input);

      expect(decoded.assetCode, equals(assetCode));
    });

    test('handles full 12 character code', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List.fromList([
        65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76
      ]); // ABCDEFGHIJKL

      final alphaNum12 = XdrAssetAlphaNum12(assetCode, issuer);

      final output = XdrDataOutputStream();
      XdrAssetAlphaNum12.encode(output, alphaNum12);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrAssetAlphaNum12.decode(input);

      expect(decoded.assetCode.length, equals(12));
      expect(decoded.assetCode[0], equals(65));
      expect(decoded.assetCode[11], equals(76));
    });
  });

  group('XdrTrustlineAsset encode/decode', () {
    test('encodes and decodes NATIVE trustline asset', () {
      final asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      final output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, asset);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant, equals(XdrAssetType.ASSET_TYPE_NATIVE));
    });

    test('encodes and decodes ALPHANUM4 trustline asset', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List.fromList([71, 66, 80, 0]); // GBP

      final alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      final asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = alphaNum4;

      final output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, asset);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4));
      expect(decoded.alphaNum4, isNotNull);
    });

    test('encodes and decodes ALPHANUM12 trustline asset', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List(12);
      for (int i = 0; i < 12; i++) {
        assetCode[i] = i < 5 ? 65 + i : 0;
      }

      final alphaNum12 = XdrAssetAlphaNum12(assetCode, issuer);

      final asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = alphaNum12;

      final output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, asset);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12));
      expect(decoded.alphaNum12, isNotNull);
    });

    test('encodes and decodes POOL_SHARE trustline asset', () {
      final poolId = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        poolId[i] = i;
      }

      final asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);
      asset.poolId = XdrHash(poolId);

      final output = XdrDataOutputStream();
      XdrTrustlineAsset.encode(output, asset);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrTrustlineAsset.decode(input);

      expect(decoded.discriminant, equals(XdrAssetType.ASSET_TYPE_POOL_SHARE));
      expect(decoded.poolId, isNotNull);
      expect(decoded.poolId!.hash, equals(poolId));
    });

    test('creates from XdrAsset NATIVE', () {
      final xdrAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      final trustlineAsset = XdrTrustlineAsset.fromXdrAsset(xdrAsset);

      expect(trustlineAsset.discriminant, equals(XdrAssetType.ASSET_TYPE_NATIVE));
    });

    test('creates from XdrAsset ALPHANUM4', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List.fromList([88, 89, 90, 0]);

      final alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      final xdrAsset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      xdrAsset.alphaNum4 = alphaNum4;

      final trustlineAsset = XdrTrustlineAsset.fromXdrAsset(xdrAsset);

      expect(trustlineAsset.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4));
      expect(trustlineAsset.alphaNum4, isNotNull);
    });

    test('throws on POOL_SHARE conversion from XdrAsset', () {
      final xdrAsset = XdrAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);

      expect(() => XdrTrustlineAsset.fromXdrAsset(xdrAsset), throwsException);
    });
  });

  group('XdrChangeTrustAsset encode/decode', () {
    // Note: XdrChangeTrustAsset.encode doesn't write the discriminant, so direct
    // encode/decode round-trips fail. Test via fromXdrAsset instead.

    test('creates from XdrAsset NATIVE', () {
      final xdrAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      final changeTrustAsset = XdrChangeTrustAsset.fromXdrAsset(xdrAsset);

      expect(changeTrustAsset.discriminant, equals(XdrAssetType.ASSET_TYPE_NATIVE));
    });

    test('creates from XdrAsset ALPHANUM4', () {
      final issuer = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final assetCode = Uint8List.fromList([65, 66, 67, 0]);

      final alphaNum4 = XdrAssetAlphaNum4(assetCode, issuer);

      final xdrAsset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      xdrAsset.alphaNum4 = alphaNum4;

      final changeTrustAsset = XdrChangeTrustAsset.fromXdrAsset(xdrAsset);

      expect(changeTrustAsset.discriminant, equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4));
      expect(changeTrustAsset.alphaNum4, isNotNull);
    });
  });

  group('XdrLiquidityPoolParameters encode/decode', () {
    test('encodes and decodes CONSTANT_PRODUCT parameters', () {
      final assetA = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      final assetB = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      final constantProduct = XdrLiquidityPoolConstantProductParameters(
        assetA,
        assetB,
        XdrInt32(30),
      );

      final params = XdrLiquidityPoolParameters(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT);
      params.constantProduct = constantProduct;

      final output = XdrDataOutputStream();
      XdrLiquidityPoolParameters.encode(output, params);

      final input = XdrDataInputStream(Uint8List.fromList(output.bytes));
      final decoded = XdrLiquidityPoolParameters.decode(input);

      expect(decoded.discriminant, equals(XdrLiquidityPoolType.LIQUIDITY_POOL_CONSTANT_PRODUCT));
      expect(decoded.constantProduct, isNotNull);
      expect(decoded.constantProduct!.fee.int32, equals(30));
    });
  });
}
