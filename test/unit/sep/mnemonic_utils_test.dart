import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('Wallet mnemonic generation', () {
    group('generation', () {
      test('generates 12-word mnemonic', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic();

        final words = mnemonic.split(' ');
        expect(words.length, equals(12));
        expect(mnemonic, isNotEmpty);
      });

      test('generates 18-word mnemonic', () async {
        final mnemonic = await Wallet.generate18WordsMnemonic();

        final words = mnemonic.split(' ');
        expect(words.length, equals(18));
        expect(mnemonic, isNotEmpty);
      });

      test('generates 24-word mnemonic', () async {
        final mnemonic = await Wallet.generate24WordsMnemonic();

        final words = mnemonic.split(' ');
        expect(words.length, equals(24));
        expect(mnemonic, isNotEmpty);
      });

      test('generates unique mnemonics', () async {
        final mnemonic1 = await Wallet.generate12WordsMnemonic();
        final mnemonic2 = await Wallet.generate12WordsMnemonic();

        expect(mnemonic1, isNot(equals(mnemonic2)));
      });

      test('generates 12-word mnemonic in Chinese Simplified', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic(
            language: LANGUAGE_CHINESE_SIMPLIFIED);

        final words = mnemonic.split(' ');
        expect(words.length, equals(12));
      });

      test('generates 12-word mnemonic in French', () async {
        final mnemonic =
            await Wallet.generate12WordsMnemonic(language: LANGUAGE_FRENCH);

        final words = mnemonic.split(' ');
        expect(words.length, equals(12));
      });

      test('generates 12-word mnemonic in Spanish', () async {
        final mnemonic =
            await Wallet.generate12WordsMnemonic(language: LANGUAGE_SPANISH);

        final words = mnemonic.split(' ');
        expect(words.length, equals(12));
      });

      test('generates 12-word mnemonic in Italian', () async {
        final mnemonic =
            await Wallet.generate12WordsMnemonic(language: LANGUAGE_ITALIAN);

        final words = mnemonic.split(' ');
        expect(words.length, equals(12));
      });

      test('generates 12-word mnemonic in Japanese', () async {
        final mnemonic =
            await Wallet.generate12WordsMnemonic(language: LANGUAGE_JAPANESE);

        final words = mnemonic.split(' ');
        expect(words.length, equals(12));
      });

      test('generates 12-word mnemonic in Korean', () async {
        final mnemonic =
            await Wallet.generate12WordsMnemonic(language: LANGUAGE_KOREAN);

        final words = mnemonic.split(' ');
        expect(words.length, equals(12));
      });
    });

    group('wallet creation', () {
      test('creates wallet from 12-word mnemonic', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);

        expect(wallet, isNotNull);
      });

      test('creates wallet from 24-word mnemonic', () async {
        final mnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
        final wallet = await Wallet.from(mnemonic);

        expect(wallet, isNotNull);
      });

      test('throws on invalid mnemonic', () async {
        final mnemonic = 'invalid mnemonic phrase';

        expect(() async => await Wallet.from(mnemonic), throwsA(anything));
      });

      test('throws on empty mnemonic', () async {
        final mnemonic = '';

        expect(() async => await Wallet.from(mnemonic), throwsA(anything));
      });
    });

    group('KeyPair derivation', () {
      test('derives KeyPair from known mnemonic', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);
        final keyPair0 = await wallet.getKeyPair(index: 0);

        expect(keyPair0.accountId,
            equals('GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6'));
      });

      test('derives different KeyPairs for different indices', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);
        final keyPair0 = await wallet.getKeyPair(index: 0);
        final keyPair1 = await wallet.getKeyPair(index: 1);

        expect(keyPair0.accountId, isNot(equals(keyPair1.accountId)));
        expect(keyPair0.secretSeed, isNot(equals(keyPair1.secretSeed)));
      });

      test('derives consistent KeyPair from same mnemonic and index', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet1 = await Wallet.from(mnemonic);
        final wallet2 = await Wallet.from(mnemonic);

        final keyPair1 = await wallet1.getKeyPair(index: 0);
        final keyPair2 = await wallet2.getKeyPair(index: 0);

        expect(keyPair1.accountId, equals(keyPair2.accountId));
        expect(keyPair1.secretSeed, equals(keyPair2.secretSeed));
      });

      test('derives multiple unique accounts from same mnemonic', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);

        final accounts = <String>[];
        for (int i = 0; i < 5; i++) {
          final keyPair = await wallet.getKeyPair(index: i);
          accounts.add(keyPair.accountId);
        }

        final uniqueAccounts = accounts.toSet();
        expect(uniqueAccounts.length, equals(5));
      });

      test('derives KeyPair with correct signing capability', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.canSign(), isTrue);
        expect(keyPair.secretSeed, isNotEmpty);
        expect(keyPair.accountId, isNotEmpty);
      });
    });

    group('account ID retrieval', () {
      test('gets account ID without full KeyPair', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);
        final accountId = await wallet.getAccountId(index: 0);

        expect(accountId,
            equals('GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6'));
      });

      test('account ID matches KeyPair account ID', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);
        final accountId = await wallet.getAccountId(index: 0);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(accountId, equals(keyPair.accountId));
      });

      test('gets multiple different account IDs', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);

        final accountIds = <String>[];
        for (int i = 0; i < 5; i++) {
          final accountId = await wallet.getAccountId(index: i);
          accountIds.add(accountId);
        }

        final uniqueAccountIds = accountIds.toSet();
        expect(uniqueAccountIds.length, equals(5));
      });
    });

    group('BIP-39 test vectors', () {
      test('test vector 1 - standard mnemonic', () async {
        final mnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.accountId, isNotEmpty);
        expect(keyPair.accountId.startsWith('G'), isTrue);
        expect(keyPair.secretSeed, isNotEmpty);
      });

      test('test vector 2 - 24-word mnemonic', () async {
        final mnemonic =
            'legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth useful legal winner thank year wave sausage worth title';
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.accountId, isNotEmpty);
        expect(keyPair.accountId.startsWith('G'), isTrue);
      });

      test('test vector 3 - another standard mnemonic', () async {
        final mnemonic =
            'letter advice cage absurd amount doctor acoustic avoid letter advice cage above';
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.accountId, isNotEmpty);
        expect(keyPair.accountId.startsWith('G'), isTrue);
      });

      test('test vector 4 - all same words except last', () async {
        final mnemonic =
            'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong';
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.accountId, isNotEmpty);
        expect(keyPair.accountId.startsWith('G'), isTrue);
      });

      test('test vector 5 - 24-word all abandon', () async {
        final mnemonic =
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.accountId, isNotEmpty);
        expect(keyPair.accountId.startsWith('G'), isTrue);
      });
    });

    group('wallet integration', () {
      test('roundtrip: generate, derive, verify', () async {
        final mnemonic = await Wallet.generate24WordsMnemonic();
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(mnemonic.split(' ').length, equals(24));
        expect(keyPair.accountId, isNotEmpty);
        expect(keyPair.canSign(), isTrue);
      });

      test('derives multiple accounts from generated mnemonic', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic();
        final wallet = await Wallet.from(mnemonic);

        final keyPairs = <KeyPair>[];
        for (int i = 0; i < 3; i++) {
          keyPairs.add(await wallet.getKeyPair(index: i));
        }

        expect(keyPairs[0].accountId, isNot(equals(keyPairs[1].accountId)));
        expect(keyPairs[1].accountId, isNot(equals(keyPairs[2].accountId)));
        expect(keyPairs[0].accountId, isNot(equals(keyPairs[2].accountId)));
      });

      test('consistent derivation across wallet instances', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic();

        final wallet1 = await Wallet.from(mnemonic);
        final wallet2 = await Wallet.from(mnemonic);

        final keyPair1_0 = await wallet1.getKeyPair(index: 0);
        final keyPair2_0 = await wallet2.getKeyPair(index: 0);
        final keyPair1_1 = await wallet1.getKeyPair(index: 1);
        final keyPair2_1 = await wallet2.getKeyPair(index: 1);

        expect(keyPair1_0.accountId, equals(keyPair2_0.accountId));
        expect(keyPair1_1.accountId, equals(keyPair2_1.accountId));
      });
    });

    group('SEP-0005 compliance', () {
      test('generates valid BIP-39 mnemonic', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic();

        expect(mnemonic, isNotEmpty);
        expect(mnemonic.split(' ').length, equals(12));
        expect(mnemonic, matches(RegExp(r'^[a-z\s]+$')));
      });

      test('derives keys following m/44\'/148\'/x\' path', () async {
        final mnemonic =
            'illness spike retreat truth genius clock brain pass fit cave bargain toe';
        final wallet = await Wallet.from(mnemonic);

        final keyPair0 = await wallet.getKeyPair(index: 0);
        expect(keyPair0.accountId,
            equals('GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6'));
      });

      test('supports multiple account indices', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic();
        final wallet = await Wallet.from(mnemonic);

        final accounts = <String>[];
        for (int i = 0; i < 10; i++) {
          final keyPair = await wallet.getKeyPair(index: i);
          accounts.add(keyPair.accountId);
        }

        expect(accounts.toSet().length, equals(10));
      });

      test('produces valid Stellar public keys', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic();
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.accountId.startsWith('G'), isTrue);
        expect(keyPair.accountId.length, equals(56));
      });

      test('produces valid Stellar secret seeds', () async {
        final mnemonic = await Wallet.generate12WordsMnemonic();
        final wallet = await Wallet.from(mnemonic);
        final keyPair = await wallet.getKeyPair(index: 0);

        expect(keyPair.secretSeed.startsWith('S'), isTrue);
        expect(keyPair.secretSeed.length, equals(56));
      });
    });

    group('mnemonic constants', () {
      test('verifies 12-word entropy constant', () {
        expect(MnemonicConstants.MNEMONIC_ENTROPY_BITS_12_WORDS, equals(128));
      });

      test('verifies 18-word entropy constant', () {
        expect(MnemonicConstants.MNEMONIC_ENTROPY_BITS_18_WORDS, equals(192));
      });

      test('verifies 24-word entropy constant', () {
        expect(MnemonicConstants.MNEMONIC_ENTROPY_BITS_24_WORDS, equals(256));
      });

      test('verifies PBKDF2 iteration count', () {
        expect(MnemonicConstants.PBKDF2_ITERATION_COUNT, equals(2048));
      });

      test('verifies PBKDF2 key length', () {
        expect(MnemonicConstants.PBKDF2_KEY_LENGTH_BYTES, equals(64));
      });

      test('verifies BIP32 hardened offset', () {
        expect(MnemonicConstants.BIP32_HARDENED_OFFSET, equals(2147483648));
      });
    });
  });
}
