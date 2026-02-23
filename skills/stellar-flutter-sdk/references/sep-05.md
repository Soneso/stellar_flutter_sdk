# SEP-05: Key Derivation Methods for Stellar Keys

**Purpose:** Generate BIP-39 mnemonic phrases and derive deterministic Stellar keypairs using the SEP-0005 hierarchical derivation path `m/44'/148'/x'`.
**Prerequisites:** None

## Table of Contents

1. [Wallet Class Overview](#1-wallet-class-overview)
2. [Mnemonic Generation](#2-mnemonic-generation)
3. [Language Support](#3-language-support)
4. [Deriving Keypairs from a Mnemonic](#4-deriving-keypairs-from-a-mnemonic)
5. [Multiple Account Derivation](#5-multiple-account-derivation)
6. [BIP-39 Passphrase](#6-bip-39-passphrase)
7. [From a BIP-39 Seed Directly](#7-from-a-bip-39-seed-directly)
8. [Mnemonic Validation](#8-mnemonic-validation)
9. [Common Pitfalls](#9-common-pitfalls)

---

## 1. Wallet Class Overview

`Wallet` is a static-factory class with no public constructor. All creation
goes through `Wallet.from()`, `Wallet.fromBip39HexSeed()`, or
`Wallet.fromBip39Seed()`. It stores the 64-byte BIP-39 seed internally and
derives keypairs on demand using the Stellar path `m/44'/148'/index'`.

All three factory methods are `async` and must be awaited. `getKeyPair()` and
`getAccountId()` are also `async`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 1. Generate a fresh mnemonic
String mnemonic = await Wallet.generate24WordsMnemonic();

// 2. Create wallet from that mnemonic
Wallet wallet = await Wallet.from(mnemonic);

// 3. Derive keypair for account 0
KeyPair keyPair = await wallet.getKeyPair(index: 0);
print(keyPair.accountId);  // G... public key
print(keyPair.secretSeed); // S... secret key — store securely, never log
```

---

## 2. Mnemonic Generation

Three convenience methods generate 12-, 18-, or 24-word phrases. All return
`Future<String>` with space-separated words.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// 12 words — 128 bits of entropy (adequate for most use cases)
String mnemonic12 = await Wallet.generate12WordsMnemonic();
// e.g. "twice news void fiction lamp chaos few code rate donkey supreme primary"

// 18 words — 192 bits of entropy
String mnemonic18 = await Wallet.generate18WordsMnemonic();

// 24 words — 256 bits of entropy (recommended for high-value accounts)
String mnemonic24 = await Wallet.generate24WordsMnemonic();
// e.g. "mango debris lumber vivid bar risk prosper verify photo put ridge sell
//        range pet indoor lava sister around panther brush twice cattle sauce romance"
```

All three default to English. Pass a `language:` named parameter to change
the word list (see section 3).

---

## 3. Language Support

Nine languages are available via the language constants exported from
`stellar_flutter_sdk`. Pass the constant as the `language:` named parameter
to any generation or parsing method.

| Constant                       | Language              |
|--------------------------------|-----------------------|
| `LANGUAGE_ENGLISH`             | English (default)     |
| `LANGUAGE_FRENCH`              | French                |
| `LANGUAGE_SPANISH`             | Spanish               |
| `LANGUAGE_ITALIAN`             | Italian               |
| `LANGUAGE_KOREAN`              | Korean                |
| `LANGUAGE_JAPANESE`            | Japanese              |
| `LANGUAGE_CHINESE_SIMPLIFIED`  | Chinese Simplified    |
| `LANGUAGE_CHINESE_TRADITIONAL` | Chinese Traditional   |
| `LANGUAGE_MALAY`               | Malay                 |

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Generate
String frenchMnemonic = await Wallet.generate12WordsMnemonic(
    language: LANGUAGE_FRENCH);
// e.g. "pouvoir aménager lagune alliage bermuda taxer dogme avancer espadon sucre bermuda aboyer"

String koreanMnemonic = await Wallet.generate24WordsMnemonic(
    language: LANGUAGE_KOREAN);

// When creating a wallet from a non-English mnemonic, pass the SAME language
Wallet wallet = await Wallet.from(koreanMnemonic, language: LANGUAGE_KOREAN);
KeyPair kp = await wallet.getKeyPair(index: 0);
```

---

## 4. Deriving Keypairs from a Mnemonic

`Wallet.from()` validates the mnemonic (checksum + word list), then converts
it to a 64-byte seed. It throws `ArgumentError('Invalid mnemonic')` if
validation fails.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Wallet wallet = await Wallet.from(
    "shell green recycle learn purchase able oxygen right echo claim hill again "
    "hidden evidence nice decade panic enemy cake version say furnace garment glue");

// getKeyPair returns a full KeyPair (public + private)
KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print(keyPair0.accountId);  // GCVSEBHB6CTMEHUHIUY4DDFMWQ7PJTHFZGOK2JUD5EG2ARNVS6S22E3K
print(keyPair0.secretSeed); // SATLGMF3SP2V47SJLBFVKZZJQARDOBDQ7DNSSPUV7NLQNPN3QB7M74XH

KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print(keyPair1.accountId);  // GBPHPX7SZKYEDV5CVOA5JOJE2RHJJDCJMRWMV4KBOIE5VSDJ6VAESR2W
print(keyPair1.secretSeed); // SCAYXPIDEUVDGDTKF4NGVMN7HCZOTZJ43E62EEYKVUYXEE7HMU4DFQA6

// getAccountId is a convenience method — returns only the G... public key
// without exposing the private key; more efficient if you only need the address
String accountId = await wallet.getAccountId(index: 0);
print(accountId); // GCVSEBHB6CTMEHUHIUY4DDFMWQ7PJTHFZGOK2JUD5EG2ARNVS6S22E3K
```

The derivation path used is `m/44'/148'/index'` (all components hardened,
following SLIP-0010 for Ed25519).

---

## 5. Multiple Account Derivation

A single wallet can derive an unlimited number of accounts. Index 0 is the
primary account; subsequent indices are independent accounts under the same
seed. This is the standard HD wallet pattern.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Wallet wallet = await Wallet.from(
    "illness spike retreat truth genius clock brain pass fit cave bargain toe");

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

// Collect keypairs into a list
List<KeyPair> keyPairs = [];
for (int i = 0; i < 3; i++) {
  keyPairs.add(await wallet.getKeyPair(index: i));
}
```

---

## 6. BIP-39 Passphrase

An optional passphrase can be provided to `Wallet.from()`. A passphrase
creates a completely different wallet from the same mnemonic — it is NOT a
password protecting the mnemonic. Without the exact passphrase, the wallet
cannot be recovered even with a correct mnemonic.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Same mnemonic, different passphrase → completely different keypairs
Wallet walletNoPass = await Wallet.from(
    "cable spray genius state float twenty onion head street palace net private "
    "method loan turn phrase state blanket interest dry amazing dress blast tube");

Wallet walletWithPass = await Wallet.from(
    "cable spray genius state float twenty onion head street palace net private "
    "method loan turn phrase state blanket interest dry amazing dress blast tube",
    passphrase: "p4ssphr4se");

KeyPair kp0NoPass   = await walletNoPass.getKeyPair(index: 0);
KeyPair kp0WithPass = await walletWithPass.getKeyPair(index: 0);

// These produce different public keys
print(kp0WithPass.accountId);  // GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ
print(kp0WithPass.secretSeed); // SAFWTGXVS7ELMNCXELFWCFZOPMHUZ5LXNBGUVRCY3FHLFPXK4QPXYP2X

KeyPair kp1WithPass = await walletWithPass.getKeyPair(index: 1);
print(kp1WithPass.accountId);  // GDY47CJARRHHL66JH3RJURDYXAMIQ5DMXZLP3TDAUJ6IN2GUOFX4OJOC
```

---

## 7. From a BIP-39 Seed Directly

When you have a pre-computed 64-byte BIP-39 seed (e.g. from hardware wallet
export, another library, or stored externally), you can skip the mnemonic step.

### From hex string

`Wallet.fromBip39HexSeed()` accepts a hex string representing 64 bytes:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Wallet wallet = await Wallet.fromBip39HexSeed(
    "e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497e"
    "e4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186");

KeyPair kp0 = await wallet.getKeyPair(index: 0);
print(kp0.accountId);  // GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6
print(kp0.secretSeed); // SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN

KeyPair kp1 = await wallet.getKeyPair(index: 1);
print(kp1.accountId);  // GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX
```

### From Uint8List

`Wallet.fromBip39Seed()` accepts a `Uint8List` of exactly 64 bytes:

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Uint8List seedBytes = ...; // your 64-byte seed
Wallet wallet = await Wallet.fromBip39Seed(seedBytes);
KeyPair kp = await wallet.getKeyPair(index: 0);
```

---

## 8. Mnemonic Validation

`Wallet.validate()` checks that all words are in the word list and the
BIP-39 checksum is correct. Returns `Future<bool>`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Valid mnemonic
bool valid = await Wallet.validate(
    "illness spike retreat truth genius clock brain pass fit cave bargain toe");
print(valid); // true

// Invalid — bad checksum or unknown words
bool invalid = await Wallet.validate(
    "witch witch witch witch witch witch witch witch witch witch witch witch");
print(invalid); // false

// Validate a non-English mnemonic — pass the matching language constant
bool validKorean = await Wallet.validate(
    "절차 튀김 건강 평가 테스트 민족 몹시 어른 주민 형제 발레 만점 "
    "산길 물고기 방면 여학생 결국 수명 애정 정치 관심 상자 축하 고무신",
    language: LANGUAGE_KOREAN);
print(validKorean); // true

// Wallet.from() validates internally and throws ArgumentError on failure
try {
  Wallet wallet = await Wallet.from("bad mnemonic words here");
} on ArgumentError catch (e) {
  print(e.message); // "Invalid mnemonic"
}
```

---

## 9. Common Pitfalls

**Not awaiting async factory methods and instance methods:**

```dart
// WRONG: all three factories return Future<Wallet>, not Wallet
Wallet wallet = Wallet.from(mnemonic);             // compile error
KeyPair kp    = wallet.getKeyPair(index: 0);       // compile error

// CORRECT: must await every call
Wallet wallet = await Wallet.from(mnemonic);
KeyPair kp    = await wallet.getKeyPair(index: 0);
String id     = await wallet.getAccountId(index: 0);
```

**Forgetting the language parameter when parsing a non-English mnemonic:**

```dart
// WRONG: English word list won't find Korean words — throws ArgumentError('Invalid mnemonic')
Wallet wallet = await Wallet.from("절차 튀김 건강 평가 테스트 민족 몹시 어른 주민 형제 발레 만점");

// CORRECT: pass the matching language constant
Wallet wallet = await Wallet.from(
    "절차 튀김 건강 평가 테스트 민족 몹시 어른 주민 형제 발레 만점",
    language: LANGUAGE_KOREAN);
```

**Misunderstanding the BIP-39 passphrase — it changes the wallet entirely:**

```dart
// WRONG assumption: passphrase "protects" the same accounts
// In BIP-39, the passphrase is mixed into the seed derivation and produces a
// completely different wallet. Without the exact passphrase you cannot
// recover the same accounts, even with a correct mnemonic.

// CORRECT: treat mnemonic + passphrase as an inseparable unit; store both
Wallet wallet = await Wallet.from(mnemonic, passphrase: "my-extra-secret");
// Losing the passphrase means losing access — there is no recovery
```

**Using language constants as string literals:**

```dart
// WRONG: typos won't be caught at compile time; falls back to English silently
Wallet wallet = await Wallet.from(mnemonic, language: "Korean");

// CORRECT: use the exported constants
Wallet wallet = await Wallet.from(mnemonic, language: LANGUAGE_KOREAN);
```

