import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/soroban/contract_address_guard.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../secret_seed_variants.dart';
import 'contract_address_guard_fixtures.dart';

void main() {
  test('checkContractAddress names a secret seed without repeating it', () {
    expect(StrKey.isValidStellarSecretSeed(secretSeed), isTrue);
    expect(
      () => checkContractAddress(secretSeed, 'The contract to invoke'),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          allOf(
            'The contract to invoke must be a contract (C...) address, got a '
            'secret seed (S...) instead of an address',
            isNot(contains(secretSeed)),
          ),
        ),
      ),
    );
  });

  final variants = SeedVariants();

  /// Valid inputs of every key kind; none starts with S.
  final Map<String, String> validKeys = {
    'account': sep23Account,
    'muxed account': sep23MuxedAccount,
    'contract': sep23Contract,
    'muxed contract': sep23MuxedContract,
    'liquidity pool': StrKey.encodeLiquidityPoolId(Uint8List(32)),
    'claimable balance': StrKey.encodeClaimableBalanceId(Uint8List(33)),
    'hex id': '00' * 32,
  };

  test('the near-seeds fail the seed check', () {
    expect(StrKey.isValidStellarSecretSeed(variants.seed), isTrue);
    for (final name in [
      'seed with a changed character',
      'seed with a digit outside base32',
      'seed with a character missing',
      'seed with a character added',
    ]) {
      expect(
        StrKey.isValidStellarSecretSeed(variants.all[name]!),
        isFalse,
        reason: name,
      );
    }
  });

  group('checkContractAddress', () {
    test('names every seed variant without repeating it', () {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          () => checkContractAddress(value, 'The contract to invoke'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message as String,
              'message',
              allOf(
                'The contract to invoke must be a contract (C...) address, '
                'got ${variants.keyWording(value)} instead of an address',
                leavesOut(value),
              ),
            ),
          ),
          reason: name,
        );
      }
    });

    test('names a seed with surrounding whitespace by its kind', () {
      expect(
        () => checkContractAddress(' ${variants.seed}\n', 'The contract'),
        throwsRejection(
          'The contract must be a contract (C...) address, got a secret seed '
          '(S...) instead of an address',
        ),
      );
    });

    test('keeps the message of an input that does not start with S', () {
      expect(
        () => checkContractAddress('XYZ', 'The contract'),
        throwsRejection('The contract must be a contract (C...) address: XYZ'),
      );
      expect(
        () => checkContractAddress('x ${variants.seed}', 'The contract'),
        throwsRejection(
          'The contract must be a contract (C...) address, got '
          'x a secret seed (S...) instead of an address',
        ),
      );
    });
  });

  group('secretSeedLikeKind', () {
    test('names a valid seed in either letter case as a secret seed', () {
      expect(secretSeedLikeKind(variants.seed), seedWording);
      expect(secretSeedLikeKind(variants.lowercase), seedWording);
      expect(secretSeedLikeKind('  ${variants.seed}\t'), seedWording);
    });

    test('names any other value that starts with S without showing it', () {
      for (final value in [
        variants.changed,
        variants.digit,
        variants.missing,
        variants.extra,
        'S',
        's',
        'SABC',
        ' s1',
      ]) {
        expect(secretSeedLikeKind(value), seedLikeWording, reason: value);
      }
    });

    test('returns null for every valid key and other text', () {
      for (final MapEntry(key: name, value: value) in validKeys.entries) {
        expect(secretSeedLikeKind(value), isNull, reason: name);
      }
      for (final value in ['', ' ', 'XS', ' GS', '1S']) {
        expect(secretSeedLikeKind(value), isNull, reason: value);
      }
    });
  });

  group('keyForMessage', () {
    test('returns every value that does not start with S unchanged', () {
      for (final value in [...validKeys.values, ' G ', 'XYZ', '']) {
        expect(keyForMessage(value), same(value), reason: value);
      }
    });

    test('replaces every seed variant by its wording', () {
      for (final value in variants.all.values) {
        expect(keyForMessage(value), variants.keyWording(value));
      }
    });
  });

  group('redactSecretSeeds', () {
    test('replaces every seed variant inside a text', () {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          redactSecretSeeds('prefix "$value": suffix'),
          'prefix "$seedWording": suffix',
          reason: name,
        );
      }
    });

    test('replaces a run from 40 characters on and keeps a shorter one', () {
      final String run39 = 'S${'A' * 38}';
      final String run40 = 's${'1' * 39}';
      expect(redactSecretSeeds('a $run39 b'), 'a $run39 b');
      expect(redactSecretSeeds('a $run40 b'), 'a $seedWording b');
    });

    test('replaces each run on its own', () {
      expect(
        redactSecretSeeds(
          '${variants.seed}/${variants.missing}+${variants.lowercase}',
        ),
        '$seedWording/$seedWording+$seedWording',
      );
    });

    test('replaces a valid seed glued to a preceding letter or digit', () {
      final String seed = variants.seed;
      final String lowercase = variants.lowercase;
      final Map<String, String> glued = {
        'x$seed': 'x$seedWording',
        '7$seed': '7$seedWording',
        'x$lowercase': 'x$seedWording',
        'got x${seed}y.': 'got x${seedWording}y.',
        'xS$seed': 'xS$seedWording',
      };
      for (final MapEntry(key: text, value: expected) in glued.entries) {
        expect(redactSecretSeeds(text), expected, reason: expected);
        expect(redactSecretSeeds(text), leavesOut(seed), reason: expected);
      }
    });

    test('keeps valid keys and text without such a run unchanged', () {
      for (final MapEntry(key: name, value: value) in validKeys.entries) {
        expect(redactSecretSeeds('got $value.'), 'got $value.', reason: name);
      }
      const String text = 'Value 12345 out of range for u32 (Sorobantype)';
      expect(redactSecretSeeds(text), text);
    });
  });

  group('parseHidingSecretSeed', () {
    test('replaces the source of the exception for an S value', () {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          () => parseHidingSecretSeed(value, BigInt.parse),
          throwsA(
            isA<FormatException>()
                .having((e) => e.message, 'message', 'Could not parse BigInt')
                .having((e) => e.source, 'source', variants.keyWording(value))
                .having((e) => e.offset, 'offset', isNull)
                .having((e) => e.toString(), 'text', leavesOut(value)),
          ),
          reason: name,
        );
      }
    });

    test('rethrows the exception for any other value unchanged', () {
      FormatException? original;
      try {
        BigInt.parse('x12');
      } on FormatException catch (e) {
        original = e;
      }
      expect(
        () => parseHidingSecretSeed<BigInt>('x12', (_) => throw original!),
        throwsA(same(original)),
      );
      expect(parseHidingSecretSeed('12', BigInt.parse), BigInt.from(12));
    });
  });

  group('checkNotSecretSeed', () {
    test('refuses every seed variant without showing it', () {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          () => checkNotSecretSeed(value, 'accountId'),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', 'accountId')
                .having(
                  (e) => e.message,
                  'message',
                  'got ${variants.keyWording(value)}, which is not sent to '
                      'Horizon',
                )
                .having((e) => e.invalidValue, 'invalidValue', isNull)
                .having((e) => e.toString(), 'text', leavesOut(value)),
          ),
          reason: name,
        );
      }
    });

    test('passes every valid key and any other value', () {
      for (final value in [...validKeys.values, '12345', 'now', '']) {
        checkNotSecretSeed(value, 'id');
      }
    });

    test('checks the issuer of a credit asset only', () {
      checkAssetIssuerNotSecretSeed(Asset.NATIVE, 'asset');
      checkAssetIssuerNotSecretSeed(
        AssetTypeCreditAlphaNum4('USD', sep23Account),
        'asset',
      );
      expect(
        () => checkAssetIssuerNotSecretSeed(
          AssetTypeCreditAlphaNum12('LONGCODE', variants.missing),
          'baseAsset',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'baseAsset.issuerId')
              .having(
                (e) => e.message,
                'message',
                'got $seedLikeWording, which is not sent to Horizon',
              ),
        ),
      );
    });
  });
}
