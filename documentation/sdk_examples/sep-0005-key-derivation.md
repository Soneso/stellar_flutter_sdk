
### SEP-0005 - Key Derivation Methods for Stellar Keys

Methods for key derivation for Stellar are described in [SEP-005](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md). This improves key storage and moving keys between wallets and apps.

In the following examples you can see how to generate 12 or 24 words mnemonics for different languages using the Flutter SDK, how to generate key pairs from a mnemonic (with and without BIP 39 passphrase) and how to generate key pairs from a BIP 39 seed.

### Generate mnemonic

```dart
String mnemonic =  await Wallet.generate12WordsMnemonic(); 
print(mnemonic);
// twice news void fiction lamp chaos few code rate donkey supreme primary

mnemonic =  await Wallet.generate24WordsMnemonic(); 
print(mnemonic);
// mango debris lumber vivid bar risk prosper verify photo put ridge sell range pet indoor lava sister around panther brush twice cattle sauce romance
```
Default language is english.

### Generate other language mnemonic 

```dart
String frenchMnemonic = await Wallet.generate12WordsMnemonic(language: LANGUAGE_FRENCH);
print(frenchMnemonic);
// pouvoir aménager lagune alliage bermuda taxer dogme avancer espadon sucre bermuda aboyer

String koreanMnemonic = await Wallet.generate24WordsMnemonic(language: LANGUAGE_KOREAN);
print(koreanMnemonic);
// 합리적 채널 침대 달걀 기념 정성 세종대왕 한식 불안 독창적 착각 체계 순서 학급 평화 마약 냉면 멀리 남매 초반 치약 여권 지방 물음
```
Supported languages are: 

- english 
- french 
- spanish 
- italian 
- korean
- japanese
- simplified chinese
- traditional chinese

### Generate key pairs from mnemonic

```dart
Wallet wallet = await Wallet.from("shell green recycle learn purchase able oxygen right echo claim hill again hidden evidence nice decade panic enemy cake version say furnace garment glue");

KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print("${keyPair0.accountId} : ${keyPair0.secretSeed}");
// GCVSEBHB6CTMEHUHIUY4DDFMWQ7PJTHFZGOK2JUD5EG2ARNVS6S22E3K : SATLGMF3SP2V47SJLBFVKZZJQARDOBDQ7DNSSPUV7NLQNPN3QB7M74XH

KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print("${keyPair1.accountId} : ${keyPair1.secretSeed}");
// GBPHPX7SZKYEDV5CVOA5JOJE2RHJJDCJMRWMV4KBOIE5VSDJ6VAESR2W : SCAYXPIDEUVDGDTKF4NGVMN7HCZOTZJ43E62EEYKVUYXEE7HMU4DFQA6
```

### Generate key pairs from mnemonic of other language

```dart
Wallet wallet = await Wallet.from("절차 튀김 건강 평가 테스트 민족 몹시 어른 주민 형제 발레 만점 산길 물고기 방면 여학생 결국 수명 애정 정치 관심 상자 축하 고무신",
        language: LANGUAGE_KOREAN);
KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print("${keyPair0.accountId} : ${keyPair0.secretSeed}");
// GCITEFHNYX3ZCD6XQXPWPZGGS2KTYE4C6RPDUIYOW33PC3PU3PGU667E : SB6KJ2HFH32PXSRATDPSV65DNYCN2XA6RVHKSFI3NSGU5YRSDLB56M76

KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print("${keyPair1.accountId} : ${keyPair1.secretSeed}");
// GB6LTLB32AFIZL5DPOLHYRVZNHGFBBWGJ5DZCVHMBEW3U4DOXHTX3UQV : SBJJXYH3HPBZ2BDJ5NBE3EJLYDPMVBGG7ZZIYGEED2EKWMNKLCVFPAY7
```

### Generate key pairs from mnemonic with BIP 39 passphrase

```dart
Wallet wallet = await Wallet.from("cable spray genius state float twenty onion head street palace net private method loan turn phrase state blanket interest dry amazing dress blast tube",
        passphrase: "p4ssphr4se");
    
KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print("${keyPair0.accountId} : ${keyPair0.secretSeed}");
// GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ : SAFWTGXVS7ELMNCXELFWCFZOPMHUZ5LXNBGUVRCY3FHLFPXK4QPXYP2X

KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print("${keyPair1.accountId} : ${keyPair1.secretSeed}");
// GDY47CJARRHHL66JH3RJURDYXAMIQ5DMXZLP3TDAUJ6IN2GUOFX4OJOC : SBQPDFUGLMWJYEYXFRM5TQX3AX2BR47WKI4FDS7EJQUSEUUVY72MZPJF
```

### Generate key pairs from BIP 39 seed

```dart
Wallet wallet = await Wallet.fromBip39HexSeed("e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497ee4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186");

KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
print("${keyPair0.accountId} : ${keyPair0.secretSeed}");
// GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6 : SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN

KeyPair keyPair1 = await wallet.getKeyPair(index: 1);
print("${keyPair1.accountId} : ${keyPair1.secretSeed}");
// GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX : SCEPFFWGAG5P2VX5DHIYK3XEMZYLTYWIPWYEKXFHSK25RVMIUNJ7CTIS
```