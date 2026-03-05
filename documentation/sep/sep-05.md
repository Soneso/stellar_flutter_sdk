# SEP-05: Key derivation for Stellar

SEP-05 defines how to generate Stellar keypairs from mnemonic phrases using hierarchical deterministic (HD) key derivation. Users can backup their entire wallet with a simple word list and derive multiple accounts from a single seed using the path `m/44'/148'/index'`.

**When to use:** Building wallets that support mnemonic backup phrases, recovering accounts from seed words, or generating multiple related accounts from a single master seed.

See the [SEP-05 specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md) for protocol details.

## Quick example

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate a new 24-word mnemonic
String mnemonic = await Wallet.generate24WordsMnemonic();
print(mnemonic);

// Create wallet and derive the first account
Wallet wallet = await Wallet.from(mnemonic);
KeyPair keyPair = await wallet.getKeyPair(index: 0);
print("Account: ${keyPair.accountId}");
```

## Generating mnemonics

The SDK supports generating mnemonics with 12, 18, or 24 words using cryptographically secure entropy.

### 12-word mnemonic

Standard security for most use cases (128 bits entropy):

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String mnemonic = await Wallet.generate12WordsMnemonic();
print(mnemonic);
// e.g. "bind struggle sausage repair machine fee setup finish transfer stamp benefit economy"
```

### 24-word mnemonic

Higher security for larger holdings (256 bits entropy, recommended for production):

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String mnemonic = await Wallet.generate24WordsMnemonic();
print(mnemonic);
// e.g. "cabbage verb depart erase cable eye crowd approve tower umbrella violin tube
//  island tortoise suspect resemble harbor twelve romance away rug current robust practice"
```

### 18-word mnemonic

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String mnemonic = await Wallet.generate18WordsMnemonic();
print(mnemonic);
```

## Mnemonics in other languages

The SDK supports BIP-39 word lists in multiple languages:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// French
String french = await Wallet.generate12WordsMnemonic(language: LANGUAGE_FRENCH);
print(french);

// Korean
String korean = await Wallet.generate24WordsMnemonic(language: LANGUAGE_KOREAN);
print(korean);

// Spanish
String spanish = await Wallet.generate12WordsMnemonic(language: LANGUAGE_SPANISH);
print(spanish);
```

**Supported languages:**
- `LANGUAGE_ENGLISH` (default)
- `LANGUAGE_FRENCH`
- `LANGUAGE_SPANISH`
- `LANGUAGE_ITALIAN`
- `LANGUAGE_KOREAN`
- `LANGUAGE_JAPANESE`
- `LANGUAGE_CHINESE_SIMPLIFIED`
- `LANGUAGE_CHINESE_TRADITIONAL`
- `LANGUAGE_MALAY`

## Deriving keypairs from mnemonics

All derivation follows the SEP-05 path `m/44'/148'/index'` where 44 is the BIP-44 purpose, 148 is Stellar's registered coin type, and index is the account number.

### Basic derivation

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String words = 'shell green recycle learn purchase able oxygen right echo claim hill again '
    'hidden evidence nice decade panic enemy cake version say furnace garment glue';
Wallet wallet = await Wallet.from(words);

// First account (index 0)
KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print("Account 0: ${keyPair0.accountId}");
// GCVSEBHB6CTMEHUHIUY4DDFMWQ7PJTHFZGOK2JUD5EG2ARNVS6S22E3K

print("Secret 0: ${keyPair0.secretSeed}");
// SATLGMF3SP2V47SJLBFVKZZJQARDOBDQ7DNSSPUV7NLQNPN3QB7M74XH

// Second account (index 1)
KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print("Account 1: ${keyPair1.accountId}");
// GBPHPX7SZKYEDV5CVOA5JOJE2RHJJDCJMRWMV4KBOIE5VSDJ6VAESR2W
```

### Derivation with passphrase

An optional passphrase adds extra security. Different passphrases produce completely different accounts:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String words = 'cable spray genius state float twenty onion head street palace net private '
    'method loan turn phrase state blanket interest dry amazing dress blast tube';
Wallet wallet = await Wallet.from(words, passphrase: 'p4ssphr4se');

// With passphrase
KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print("Account: ${keyPair0.accountId}");
// GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ

KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print("Account: ${keyPair1.accountId}");
// GDY47CJARRHHL66JH3RJURDYXAMIQ5DMXZLP3TDAUJ6IN2GUOFX4OJOC
```

### Derivation from non-English mnemonic

Generate a mnemonic in another language and derive keypairs from it:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate a Korean mnemonic
String korean = await Wallet.generate24WordsMnemonic(language: LANGUAGE_KOREAN);
print(korean);

// Create wallet with the same language parameter
Wallet wallet = await Wallet.from(korean, language: LANGUAGE_KOREAN);
KeyPair keyPair = await wallet.getKeyPair(index: 0);
print("Account: ${keyPair.accountId}");
```

### Restoring from non-English mnemonic

Restore an existing mnemonic in another language:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Restore from existing Japanese mnemonic
String words = 'あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん '
    'あいこくしん あいこくしん あいこくしん あいこくしん あいこくしん あおぞら';
Wallet wallet = await Wallet.from(words, language: LANGUAGE_JAPANESE);

KeyPair keyPair = await wallet.getKeyPair(index: 0);
print("Account: ${keyPair.accountId}");
// Note: Produces a different account than the English equivalent because
// BIP-39 uses the actual words (not entropy) to derive the seed
```

> **Note:** When restoring from non-English mnemonics, the words must match the exact encoding used by the SDK's BIP-39 wordlists. Some languages like Korean and Japanese may use different Unicode normalization forms (NFD vs NFC), which can cause validation failures with copy-pasted text.

### Multiple account derivation

A single wallet can derive an unlimited number of accounts. Index 0 is the primary account; subsequent indices are independent accounts under the same seed.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Wallet wallet = await Wallet.from(
    'illness spike retreat truth genius clock brain pass fit cave bargain toe');

// Derive accounts 0-4
for (int i = 0; i < 5; i++) {
  KeyPair kp = await wallet.getKeyPair(index: i);
  print('Account $i: ${kp.accountId}');
}
// Account 0: GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
// Account 1: GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX
// Account 2: GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW
// Account 3: GAOD5NRAEORFE34G5D4EOSKIJB6V4Z2FGPBCJNQI6MNICVITE6CSYIAE
// Account 4: GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4
```

## Working with BIP-39 seeds

The 512-bit seed is derived from the mnemonic using PBKDF2 with 2048 iterations. Use these methods when interoperating with other wallets or tools.

### From a hex seed directly

When you have a pre-computed 64-byte BIP-39 seed (e.g. from a hardware wallet export or another library), skip the mnemonic step:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Wallet wallet = await Wallet.fromBip39HexSeed(
    'e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497e'
    'e4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186');

KeyPair kp0 = await wallet.getKeyPair(index: 0);
print("Account: ${kp0.accountId}");
// GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6

KeyPair kp1 = await wallet.getKeyPair(index: 1);
print("Account: ${kp1.accountId}");
// GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX
```

### From a Uint8List seed

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List seedBytes = ...; // your 64-byte seed
Wallet wallet = await Wallet.fromBip39Seed(seedBytes);
KeyPair kp = await wallet.getKeyPair(index: 0);
```

## Restoring from words

Convert a space-separated word string back to a wallet:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

String words = 'illness spike retreat truth genius clock brain pass fit cave bargain toe';

try {
  Wallet wallet = await Wallet.from(words);
  KeyPair keyPair = await wallet.getKeyPair(index: 0);
  print("Recovered account: ${keyPair.accountId}");
  // GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
} on ArgumentError catch (e) {
  print("Invalid mnemonic: ${e.message}");
}
```

## Mnemonic validation

`Wallet.validate()` checks that all words are in the word list and the BIP-39 checksum is correct:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Valid mnemonic
bool valid = await Wallet.validate(
    'illness spike retreat truth genius clock brain pass fit cave bargain toe');
print(valid); // true

// Invalid -- bad checksum or unknown words
bool invalid = await Wallet.validate(
    'witch witch witch witch witch witch witch witch witch witch witch witch');
print(invalid); // false

// Validate a non-English mnemonic -- pass the matching language constant
bool validKorean = await Wallet.validate(
    '절차 튀김 건강 평가 테스트 민족 몹시 어른 주민 형제 발레 만점 '
    '산길 물고기 방면 여학생 결국 수명 애정 정치 관심 상자 축하 고무신',
    language: LANGUAGE_KOREAN);
print(validKorean); // true

// Wallet.from() validates internally and throws ArgumentError on failure
try {
  Wallet wallet = await Wallet.from('bad mnemonic words here');
} on ArgumentError catch (e) {
  print(e.message); // "Invalid mnemonic"
}
```

## Entropy and security requirements

### Entropy standards

The SDK enforces BIP-39 entropy requirements:
- **Minimum**: 128 bits (12 words) - acceptable for most use cases
- **Recommended**: 256 bits (24 words) - recommended for production
- **Supported**: 128, 192, 256 bits (12, 18, 24 words)
- **Source**: Cryptographically secure random number generation

### Checksum validation

Each mnemonic includes a checksum to detect errors:
- **12 words**: 4-bit checksum (1 in 16 chance random words pass)
- **24 words**: 8-bit checksum (1 in 256 chance random words pass)
- **Validation**: Automatic via `Wallet.from()`, or check explicitly with `Wallet.validate()`

## Security notes

- **Never share your mnemonic** -- Anyone with your words can access all derived accounts
- **Store mnemonics offline** -- Write them on paper, use a hardware wallet, or use encrypted storage
- **Use passphrases for extra security** -- A passphrase creates a completely different set of accounts
- **Verify checksums** -- The SDK validates mnemonics by default to catch typos
- **Test recovery** -- Before using an account for real funds, verify you can recover it from the mnemonic
- **Hardware security** -- Consider using hardware wallets for high-value accounts

## Compatibility

The SDK is compatible with BIP-39 wallets and uses the standard Stellar derivation path `m/44'/148'/index'`.

## Test vectors

The SEP-05 specification includes detailed test vectors for validating implementations. Use these to verify your integration produces correct results across different mnemonic lengths, languages, and passphrases.

See the [official SEP-05 test vectors](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md#test-cases) in the specification.

## Related SEPs

- [SEP-30 Account Recovery](sep-30.md) - Uses mnemonics for account recovery flows

---

[Back to SEP Overview](README.md)
