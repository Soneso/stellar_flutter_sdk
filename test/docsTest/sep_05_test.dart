@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('sep-05: Quick example', () async {
    // Snippet from sep-05.md "Quick example"
    String mnemonic = await Wallet.generate24WordsMnemonic();
    expect(mnemonic.split(' ').length, 24);

    Wallet wallet = await Wallet.from(mnemonic);
    KeyPair keyPair = await wallet.getKeyPair(index: 0);
    expect(keyPair.accountId, startsWith('G'));
    expect(keyPair.accountId.length, 56);
  });

  test('sep-05: 12-word mnemonic', () async {
    // Snippet from sep-05.md "12-word mnemonic"
    String mnemonic = await Wallet.generate12WordsMnemonic();
    expect(mnemonic.split(' ').length, 12);
  });

  test('sep-05: 24-word mnemonic', () async {
    // Snippet from sep-05.md "24-word mnemonic"
    String mnemonic = await Wallet.generate24WordsMnemonic();
    expect(mnemonic.split(' ').length, 24);
  });

  test('sep-05: 18-word mnemonic', () async {
    // Snippet from sep-05.md "18-word mnemonic"
    String mnemonic = await Wallet.generate18WordsMnemonic();
    expect(mnemonic.split(' ').length, 18);
  });

  test('sep-05: Mnemonics in other languages', () async {
    // Snippet from sep-05.md "Mnemonics in other languages"
    String french = await Wallet.generate12WordsMnemonic(language: LANGUAGE_FRENCH);
    expect(french.split(' ').length, 12);

    String korean = await Wallet.generate24WordsMnemonic(language: LANGUAGE_KOREAN);
    expect(korean.split(' ').length, 24);

    String spanish = await Wallet.generate12WordsMnemonic(language: LANGUAGE_SPANISH);
    expect(spanish.split(' ').length, 12);
  });

  test('sep-05: Basic derivation', () async {
    // Snippet from sep-05.md "Basic derivation"
    String words = 'shell green recycle learn purchase able oxygen right echo claim hill again '
        'hidden evidence nice decade panic enemy cake version say furnace garment glue';
    Wallet wallet = await Wallet.from(words);

    KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
    expect(keyPair0.accountId, 'GCVSEBHB6CTMEHUHIUY4DDFMWQ7PJTHFZGOK2JUD5EG2ARNVS6S22E3K');
    expect(keyPair0.secretSeed, 'SATLGMF3SP2V47SJLBFVKZZJQARDOBDQ7DNSSPUV7NLQNPN3QB7M74XH');

    KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
    expect(keyPair1.accountId, 'GBPHPX7SZKYEDV5CVOA5JOJE2RHJJDCJMRWMV4KBOIE5VSDJ6VAESR2W');
  });

  test('sep-05: Derivation with passphrase', () async {
    // Snippet from sep-05.md "Derivation with passphrase"
    String words = 'cable spray genius state float twenty onion head street palace net private '
        'method loan turn phrase state blanket interest dry amazing dress blast tube';
    Wallet wallet = await Wallet.from(words, passphrase: 'p4ssphr4se');

    KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
    expect(keyPair0.accountId, 'GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ');

    KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
    expect(keyPair1.accountId, 'GDY47CJARRHHL66JH3RJURDYXAMIQ5DMXZLP3TDAUJ6IN2GUOFX4OJOC');
  });

  test('sep-05: Derivation from non-English mnemonic', () async {
    // Snippet from sep-05.md "Derivation from non-English mnemonic"
    String korean = await Wallet.generate24WordsMnemonic(language: LANGUAGE_KOREAN);
    expect(korean.isNotEmpty, true);

    Wallet wallet = await Wallet.from(korean, language: LANGUAGE_KOREAN);
    KeyPair keyPair = await wallet.getKeyPair(index: 0);
    expect(keyPair.accountId, startsWith('G'));
    expect(keyPair.accountId.length, 56);
  });

  test('sep-05: Restoring from non-English mnemonic', () async {
    // Snippet from sep-05.md "Restoring from non-English mnemonic"
    // Generate a valid Japanese mnemonic, then restore from it
    String japaneseMnemonic = await Wallet.generate12WordsMnemonic(
        language: LANGUAGE_JAPANESE);
    Wallet wallet = await Wallet.from(japaneseMnemonic,
        language: LANGUAGE_JAPANESE);

    KeyPair keyPair = await wallet.getKeyPair(index: 0);
    expect(keyPair.accountId, startsWith('G'));
    expect(keyPair.accountId.length, 56);
  });

  test('sep-05: Multiple account derivation', () async {
    // Snippet from sep-05.md "Multiple account derivation"
    Wallet wallet = await Wallet.from(
        'illness spike retreat truth genius clock brain pass fit cave bargain toe');

    KeyPair kp0 = await wallet.getKeyPair(index: 0);
    expect(kp0.accountId, 'GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6');

    KeyPair kp1 = await wallet.getKeyPair(index: 1);
    expect(kp1.accountId, 'GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX');

    KeyPair kp2 = await wallet.getKeyPair(index: 2);
    expect(kp2.accountId, 'GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW');

    KeyPair kp3 = await wallet.getKeyPair(index: 3);
    expect(kp3.accountId, 'GAOD5NRAEORFE34G5D4EOSKIJB6V4Z2FGPBCJNQI6MNICVITE6CSYIAE');

    KeyPair kp4 = await wallet.getKeyPair(index: 4);
    expect(kp4.accountId, 'GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4');
  });

  test('sep-05: From a hex seed directly', () async {
    // Snippet from sep-05.md "From a hex seed directly"
    Wallet wallet = await Wallet.fromBip39HexSeed(
        'e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497e'
        'e4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186');

    KeyPair kp0 = await wallet.getKeyPair(index: 0);
    expect(kp0.accountId, 'GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6');

    KeyPair kp1 = await wallet.getKeyPair(index: 1);
    expect(kp1.accountId, 'GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX');
  });

  test('sep-05: Restoring from words', () async {
    // Snippet from sep-05.md "Restoring from words"
    // Use a known valid mnemonic
    String words = 'illness spike retreat truth genius clock brain pass fit cave bargain toe';

    Wallet wallet = await Wallet.from(words);
    KeyPair keyPair = await wallet.getKeyPair(index: 0);
    expect(keyPair.accountId, 'GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6');
  });

  test('sep-05: Mnemonic validation', () async {
    // Snippet from sep-05.md "Mnemonic validation"

    // Valid mnemonic
    bool valid = await Wallet.validate(
        'illness spike retreat truth genius clock brain pass fit cave bargain toe');
    expect(valid, true);

    // Invalid mnemonic
    bool invalid = await Wallet.validate(
        'witch witch witch witch witch witch witch witch witch witch witch witch');
    expect(invalid, false);

    // Validate non-English mnemonic (generate a valid one first)
    String koreanMnemonic = await Wallet.generate24WordsMnemonic(
        language: LANGUAGE_KOREAN);
    bool validKorean = await Wallet.validate(koreanMnemonic,
        language: LANGUAGE_KOREAN);
    expect(validKorean, true);

    // Wallet.from() throws ArgumentError on invalid mnemonic
    expect(
      () async => await Wallet.from('bad mnemonic words here'),
      throwsArgumentError,
    );
  });
}
