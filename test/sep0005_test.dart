@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('Key Derivation Methods for Stellar Keys', () async {
    String mnemonic12Words = await Wallet.generate12WordsMnemonic();
    print(mnemonic12Words);
    assert(mnemonic12Words.split(" ").length == 12);

    String mnemonic12WordsChineseSimplified =
        await Wallet.generate12WordsMnemonic(
            language: LANGUAGE_CHINESE_SIMPLIFIED);
    print(mnemonic12WordsChineseSimplified);
    assert(mnemonic12WordsChineseSimplified.split(" ").length == 12);

    String mnemonic12WordsChineseTraditional =
        await Wallet.generate12WordsMnemonic(
            language: LANGUAGE_CHINESE_TRADITIONAL);
    print(mnemonic12WordsChineseTraditional);
    assert(mnemonic12WordsChineseTraditional.split(" ").length == 12);

    String mnemonic12WordsFrench =
        await Wallet.generate12WordsMnemonic(language: LANGUAGE_FRENCH);
    print(mnemonic12WordsFrench);
    assert(mnemonic12WordsFrench.split(" ").length == 12);

    String mnemonic12WordsItalian =
        await Wallet.generate12WordsMnemonic(language: LANGUAGE_ITALIAN);
    print(mnemonic12WordsItalian);
    assert(mnemonic12WordsItalian.split(" ").length == 12);

    String mnemonic12WordsJapanese =
        await Wallet.generate12WordsMnemonic(language: LANGUAGE_JAPANESE);
    print(mnemonic12WordsJapanese);
    assert(mnemonic12WordsJapanese.split(" ").length == 12);

    String mnemonic12WordsKorean =
        await Wallet.generate12WordsMnemonic(language: LANGUAGE_KOREAN);
    print(mnemonic12WordsKorean);
    assert(mnemonic12WordsKorean.split(" ").length == 12);

    String mnemonic12WordsSpanish =
        await Wallet.generate12WordsMnemonic(language: LANGUAGE_SPANISH);
    print(mnemonic12WordsSpanish);
    assert(mnemonic12WordsSpanish.split(" ").length == 12);

    String mnemonic12WordsMalay =
    await Wallet.generate12WordsMnemonic(language: LANGUAGE_MALAY);
    print(mnemonic12WordsMalay);
    assert(mnemonic12WordsMalay.split(" ").length == 12);

    String mnemonic12WordsEnglish =
        await Wallet.generate12WordsMnemonic(language: LANGUAGE_ENGLISH);
    print(mnemonic12WordsEnglish);
    assert(mnemonic12WordsEnglish.split(" ").length == 12);
	
	String mnemonic18Words = await Wallet.generate12WordsMnemonic();
    print(mnemonic18Words);
    assert(mnemonic18Words.split(" ").length == 18);

    String mnemonic18WordsChineseSimplified =
        await Wallet.generate18WordsMnemonic(
            language: LANGUAGE_CHINESE_SIMPLIFIED);
    print(mnemonic18WordsChineseSimplified);
    assert(mnemonic18WordsChineseSimplified.split(" ").length == 18);

    String mnemonic18WordsChineseTraditional =
        await Wallet.generate18WordsMnemonic(
            language: LANGUAGE_CHINESE_TRADITIONAL);
    print(mnemonic18WordsChineseTraditional);
    assert(mnemonic18WordsChineseTraditional.split(" ").length == 18);

    String mnemonic18WordsFrench =
        await Wallet.generate18WordsMnemonic(language: LANGUAGE_FRENCH);
    print(mnemonic18WordsFrench);
    assert(mnemonic18WordsFrench.split(" ").length == 18);

    String mnemonic18WordsItalian =
        await Wallet.generate18WordsMnemonic(language: LANGUAGE_ITALIAN);
    print(mnemonic18WordsItalian);
    assert(mnemonic18WordsItalian.split(" ").length == 18);

    String mnemonic18WordsJapanese =
        await Wallet.generate18WordsMnemonic(language: LANGUAGE_JAPANESE);
    print(mnemonic18WordsJapanese);
    assert(mnemonic18WordsJapanese.split(" ").length == 18);

    String mnemonic18WordsKorean =
        await Wallet.generate18WordsMnemonic(language: LANGUAGE_KOREAN);
    print(mnemonic18WordsKorean);
    assert(mnemonic18WordsKorean.split(" ").length == 18);

    String mnemonic18WordsSpanish =
        await Wallet.generate18WordsMnemonic(language: LANGUAGE_SPANISH);
    print(mnemonic18WordsSpanish);
    assert(mnemonic18WordsSpanish.split(" ").length == 18);

    String mnemonic18WordsMalay =
    await Wallet.generate18WordsMnemonic(language: LANGUAGE_MALAY);
    print(mnemonic18WordsMalay);
    assert(mnemonic18WordsMalay.split(" ").length == 18);

    String mnemonic18WordsEnglish =
        await Wallet.generate18WordsMnemonic(language: LANGUAGE_ENGLISH);
    print(mnemonic18WordsEnglish);
    assert(mnemonic18WordsEnglish.split(" ").length == 18);

    String mnemonic24Words = await Wallet.generate24WordsMnemonic();
    print(mnemonic24Words);
    assert(mnemonic24Words.split(" ").length == 24);

    String mnemonic24WordsChineseSimplified =
        await Wallet.generate24WordsMnemonic(
            language: LANGUAGE_CHINESE_SIMPLIFIED);
    print(mnemonic24WordsChineseSimplified);
    assert(mnemonic24WordsChineseSimplified.split(" ").length == 24);

    String mnemonic24WordsChineseTraditional =
        await Wallet.generate24WordsMnemonic(
            language: LANGUAGE_CHINESE_TRADITIONAL);
    print(mnemonic24WordsChineseTraditional);
    assert(mnemonic24WordsChineseTraditional.split(" ").length == 24);

    String mnemonic24WordsFrench =
        await Wallet.generate24WordsMnemonic(language: LANGUAGE_FRENCH);
    print(mnemonic24WordsFrench);
    assert(mnemonic24WordsFrench.split(" ").length == 24);

    String mnemonic24WordsItalian =
        await Wallet.generate24WordsMnemonic(language: LANGUAGE_ITALIAN);
    print(mnemonic24WordsItalian);
    assert(mnemonic24WordsItalian.split(" ").length == 24);

    String mnemonic24WordsJapanese =
        await Wallet.generate24WordsMnemonic(language: LANGUAGE_JAPANESE);
    print(mnemonic24WordsJapanese);
    assert(mnemonic24WordsJapanese.split(" ").length == 24);

    String mnemonic24WordsKorean =
        await Wallet.generate24WordsMnemonic(language: LANGUAGE_KOREAN);
    print(mnemonic24WordsKorean);
    assert(mnemonic24WordsKorean.split(" ").length == 24);

    String mnemonic24WordsSpanish =
        await Wallet.generate24WordsMnemonic(language: LANGUAGE_SPANISH);
    print(mnemonic24WordsSpanish);
    assert(mnemonic24WordsSpanish.split(" ").length == 24);

    String mnemonic24WordsMalay =
    await Wallet.generate24WordsMnemonic(language: LANGUAGE_MALAY);
    print(mnemonic24WordsMalay);
    assert(mnemonic24WordsMalay.split(" ").length == 24);

    String mnemonic24WordsEnglish =
        await Wallet.generate24WordsMnemonic(language: LANGUAGE_ENGLISH);
    print(mnemonic24WordsEnglish);
    assert(mnemonic24WordsEnglish.split(" ").length == 24);

    Wallet wallet = await Wallet.from(
        "illness spike retreat truth genius clock brain pass fit cave bargain toe");

    assert(await wallet.getAccountId(index: 0) ==
        "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6");
    KeyPair keyPair = await wallet.getKeyPair(index: 0);
    assert(keyPair.accountId ==
        "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6");
    assert(keyPair.secretSeed ==
        "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN");
    keyPair = await wallet.getKeyPair(index: 1);
    assert(keyPair.accountId ==
        "GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX");
    assert(keyPair.secretSeed ==
        "SCEPFFWGAG5P2VX5DHIYK3XEMZYLTYWIPWYEKXFHSK25RVMIUNJ7CTIS");
    keyPair = await wallet.getKeyPair(index: 2);
    assert(keyPair.accountId ==
        "GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW");
    assert(keyPair.secretSeed ==
        "SDAILLEZCSA67DUEP3XUPZJ7NYG7KGVRM46XA7K5QWWUIGADUZCZWTJP");
    keyPair = await wallet.getKeyPair(index: 3);
    assert(keyPair.accountId ==
        "GAOD5NRAEORFE34G5D4EOSKIJB6V4Z2FGPBCJNQI6MNICVITE6CSYIAE");
    assert(keyPair.secretSeed ==
        "SBMWLNV75BPI2VB4G27RWOMABVRTSSF7352CCYGVELZDSHCXWCYFKXIX");
    keyPair = await wallet.getKeyPair(index: 4);
    assert(keyPair.accountId ==
        "GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4");
    assert(keyPair.secretSeed ==
        "SCPCY3CEHMOP2TADSV2ERNNZBNHBGP4V32VGOORIEV6QJLXD5NMCJUXI");
    keyPair = await wallet.getKeyPair(index: 5);
    assert(keyPair.accountId ==
        "GBRQY5JFN5UBG5PGOSUOL4M6D7VRMAYU6WW2ZWXBMCKB7GPT3YCBU2XZ");
    assert(keyPair.secretSeed ==
        "SCK27SFHI3WUDOEMJREV7ZJQG34SCBR6YWCE6OLEXUS2VVYTSNGCRS6X");
    keyPair = await wallet.getKeyPair(index: 6);
    assert(keyPair.accountId ==
        "GBY27SJVFEWR3DUACNBSMJB6T4ZPR4C7ZXSTHT6GMZUDL23LAM5S2PQX");
    assert(keyPair.secretSeed ==
        "SDJ4WDPOQAJYR3YIAJOJP3E6E4BMRB7VZ4QAEGCP7EYVDW6NQD3LRJMZ");
    keyPair = await wallet.getKeyPair(index: 7);
    assert(keyPair.accountId ==
        "GAY7T23Z34DWLSTEAUKVBPHHBUE4E3EMZBAQSLV6ZHS764U3TKUSNJOF");
    assert(keyPair.secretSeed ==
        "SA3HXJUCE2N27TBIZ5JRBLEBF3TLPQEBINP47E6BTMIWW2RJ5UKR2B3L");
    keyPair = await wallet.getKeyPair(index: 8);
    assert(keyPair.accountId ==
        "GDJTCF62UUYSAFAVIXHPRBR4AUZV6NYJR75INVDXLLRZLZQ62S44443R");
    assert(keyPair.secretSeed ==
        "SCD5OSHUUC75MSJG44BAT3HFZL2HZMMQ5M4GPDL7KA6HJHV3FLMUJAME");
    keyPair = await wallet.getKeyPair(index: 9);
    assert(keyPair.accountId ==
        "GBTVYYDIYWGUQUTKX6ZMLGSZGMTESJYJKJWAATGZGITA25ZB6T5REF44");
    assert(keyPair.secretSeed ==
        "SCJGVMJ66WAUHQHNLMWDFGY2E72QKSI3XGSBYV6BANDFUFE7VY4XNXXR");

    wallet = await Wallet.fromBip39HexSeed(
        "e4a5a632e70943ae7f07659df1332160937fad82587216a4c64315a0fb39497ee4a01f76ddab4cba68147977f3a147b6ad584c41808e8238a07f6cc4b582f186");
    assert(await wallet.getAccountId(index: 0) ==
        "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6");
    keyPair = await wallet.getKeyPair(index: 0);
    assert(keyPair.accountId ==
        "GDRXE2BQUC3AZNPVFSCEZ76NJ3WWL25FYFK6RGZGIEKWE4SOOHSUJUJ6");
    assert(keyPair.secretSeed ==
        "SBGWSG6BTNCKCOB3DIFBGCVMUPQFYPA2G4O34RMTB343OYPXU5DJDVMN");
    keyPair = await wallet.getKeyPair(index: 1);
    assert(keyPair.accountId ==
        "GBAW5XGWORWVFE2XTJYDTLDHXTY2Q2MO73HYCGB3XMFMQ562Q2W2GJQX");
    assert(keyPair.secretSeed ==
        "SCEPFFWGAG5P2VX5DHIYK3XEMZYLTYWIPWYEKXFHSK25RVMIUNJ7CTIS");
    keyPair = await wallet.getKeyPair(index: 2);
    assert(keyPair.accountId ==
        "GAY5PRAHJ2HIYBYCLZXTHID6SPVELOOYH2LBPH3LD4RUMXUW3DOYTLXW");
    assert(keyPair.secretSeed ==
        "SDAILLEZCSA67DUEP3XUPZJ7NYG7KGVRM46XA7K5QWWUIGADUZCZWTJP");
    keyPair = await wallet.getKeyPair(index: 3);
    assert(keyPair.accountId ==
        "GAOD5NRAEORFE34G5D4EOSKIJB6V4Z2FGPBCJNQI6MNICVITE6CSYIAE");
    assert(keyPair.secretSeed ==
        "SBMWLNV75BPI2VB4G27RWOMABVRTSSF7352CCYGVELZDSHCXWCYFKXIX");
    keyPair = await wallet.getKeyPair(index: 4);
    assert(keyPair.accountId ==
        "GBCUXLFLSL2JE3NWLHAWXQZN6SQC6577YMAU3M3BEMWKYPFWXBSRCWV4");
    assert(keyPair.secretSeed ==
        "SCPCY3CEHMOP2TADSV2ERNNZBNHBGP4V32VGOORIEV6QJLXD5NMCJUXI");
    keyPair = await wallet.getKeyPair(index: 5);
    assert(keyPair.accountId ==
        "GBRQY5JFN5UBG5PGOSUOL4M6D7VRMAYU6WW2ZWXBMCKB7GPT3YCBU2XZ");
    assert(keyPair.secretSeed ==
        "SCK27SFHI3WUDOEMJREV7ZJQG34SCBR6YWCE6OLEXUS2VVYTSNGCRS6X");
    keyPair = await wallet.getKeyPair(index: 6);
    assert(keyPair.accountId ==
        "GBY27SJVFEWR3DUACNBSMJB6T4ZPR4C7ZXSTHT6GMZUDL23LAM5S2PQX");
    assert(keyPair.secretSeed ==
        "SDJ4WDPOQAJYR3YIAJOJP3E6E4BMRB7VZ4QAEGCP7EYVDW6NQD3LRJMZ");
    keyPair = await wallet.getKeyPair(index: 7);
    assert(keyPair.accountId ==
        "GAY7T23Z34DWLSTEAUKVBPHHBUE4E3EMZBAQSLV6ZHS764U3TKUSNJOF");
    assert(keyPair.secretSeed ==
        "SA3HXJUCE2N27TBIZ5JRBLEBF3TLPQEBINP47E6BTMIWW2RJ5UKR2B3L");
    keyPair = await wallet.getKeyPair(index: 8);
    assert(keyPair.accountId ==
        "GDJTCF62UUYSAFAVIXHPRBR4AUZV6NYJR75INVDXLLRZLZQ62S44443R");
    assert(keyPair.secretSeed ==
        "SCD5OSHUUC75MSJG44BAT3HFZL2HZMMQ5M4GPDL7KA6HJHV3FLMUJAME");
    keyPair = await wallet.getKeyPair(index: 9);
    assert(keyPair.accountId ==
        "GBTVYYDIYWGUQUTKX6ZMLGSZGMTESJYJKJWAATGZGITA25ZB6T5REF44");
    assert(keyPair.secretSeed ==
        "SCJGVMJ66WAUHQHNLMWDFGY2E72QKSI3XGSBYV6BANDFUFE7VY4XNXXR");

    wallet = await Wallet.from(
        "resource asthma orphan phone ice canvas fire useful arch jewel impose vague theory cushion top");
    assert(await wallet.getAccountId(index: 0) ==
        "GAVXVW5MCK7Q66RIBWZZKZEDQTRXWCZUP4DIIFXCCENGW2P6W4OA34RH");
    keyPair = await wallet.getKeyPair(index: 0);
    assert(keyPair.accountId ==
        "GAVXVW5MCK7Q66RIBWZZKZEDQTRXWCZUP4DIIFXCCENGW2P6W4OA34RH");
    assert(keyPair.secretSeed ==
        "SAKS7I2PNDBE5SJSUSU2XLJ7K5XJ3V3K4UDFAHMSBQYPOKE247VHAGDB");
    
	wallet = await Wallet.from(
        "cheap math piece okay jar quote chest repair own toilet denial loyal world remind potato cushion bargain paddle");
    assert(await wallet.getAccountId(index: 0) ==
        "GC7YQKL2P2JFZTTFTYW6XKCBJ7QTH4S3Q5AEVWWA6RIZ7MMER5NNINPL");
    KeyPair keyPair = await wallet.getKeyPair(index: 0);
    assert(keyPair.accountId ==
        "GC7YQKL2P2JFZTTFTYW6XKCBJ7QTH4S3Q5AEVWWA6RIZ7MMER5NNINPL");
    assert(keyPair.secretSeed ==
        "SAEF6667Z4TGIU6X7FK7JZVWQW7Z7JODCFI4RXL6BXP4MXWXJGQQWLDF");
    keyPair = await wallet.getKeyPair(index: 1);
    assert(keyPair.accountId ==
        "GBDFJLRIUXS3P43LHUOIL5GQ2LRF2GAUS3NRTOKBKM4HPOFQOJMK6BWA");
    assert(keyPair.secretSeed ==
        "SDMSUPDUDSOV2CGCEKMQSZBSUIKE3GYABFM35TTMQC36HCFZ2HABN3LY");
    keyPair = await wallet.getKeyPair(index: 2);
    assert(keyPair.accountId ==
        "GBUE6KGGARQMZZYJOGHJL6YXD2YAODDTYVQR7JNIZKZOWKRFSSVAMGYZ");
    assert(keyPair.secretSeed ==
        "SANXVCU365W77VHY2UOA4VJ27NAUZSXOLF5IAHKJAFHIF2L4CGHUGEOL");
    keyPair = await wallet.getKeyPair(index: 3);
    assert(keyPair.accountId ==
        "GAXHZUGJX3AMWEUOBF7DA7EOM6GVF2LPEDVHLRP4VZJ5SNZLOHGXSNO2");
    assert(keyPair.secretSeed ==
        "SBAOTA2QDMGRCPUEGRYPFKM4HE5YX43JKMDZHV2VIFUOL7TIWQ2EQF2P");
    keyPair = await wallet.getKeyPair(index: 4);
    assert(keyPair.accountId ==
        "GCRKQRZRYK3GFUTCNYLVYZEHIFLCIL67BW57QCGLS3XOUM25RKQIC6TV");
    assert(keyPair.secretSeed ==
        "SB4XJEOPKDB245WCVXEDREVOIZXYOB7AKAMNHPJ6QX4W2H47SFEEULZ6");
    keyPair = await wallet.getKeyPair(index: 5);
    assert(keyPair.accountId ==
        "GAQ3JLR57ZQNZJ6CQEIH5SV342BDSVRZGOSOT4SZ5IUVAKNUHM3R4N4S");
    assert(keyPair.secretSeed ==
        "SA6QRWTD2WWWAFTDSATZDGA5FQMJKRMCLBVCBA4DYUQ42FBDP3HLPPAG");
    keyPair = await wallet.getKeyPair(index: 6);
    assert(keyPair.accountId ==
        "GALHLBZU2UN4URL56BPPHDINX7CMQ773VDEA67NCM4Z4TE5ZLKH33U6W");
    assert(keyPair.secretSeed ==
        "SDRV6OPUNE7HHJONE3JLY4627BZD4XJNPILEEXFBVAWHHFSUVEUE36XX");
    keyPair = await wallet.getKeyPair(index: 7);
    assert(keyPair.accountId ==
        "GAR767ZVHXKS2KRMJD22Z7NBXJQ62VQWYEOADV5ZCT4RW7DDGKQ6EDQ4");
    assert(keyPair.secretSeed ==
        "SAIO5UMCRW22E6ELQQHXLBMDZWO4EPH7T6VHCPXQGIP4EDLF6VYEPRQO");
    keyPair = await wallet.getKeyPair(index: 8);
    assert(keyPair.accountId ==
        "GBOTSKKJSWCAXS4YBWSCFPHSN27OMIZQZBL3UHT2OKWBYK4LFGSLWY7V");
    assert(keyPair.secretSeed ==
        "SB3SXYF34R2KB73QI3ILU7YTWPZR3UHYL6A2CHGLA6BHQZAJUYBHMQ6G");
    keyPair = await wallet.getKeyPair(index: 9);
    assert(keyPair.accountId ==
        "GBOLXUO4DR76UUHLNWENTHU6L5L5YMPR22CCXXJMNBXXN3FM42LVFYEY");
    assert(keyPair.secretSeed ==
        "SB57GY6A6KO76CJDXYXELENJOJATVNYVUAJDIHCRVDMWY6DUUTZEOAMZ");
	
    wallet = await Wallet.from(
        "bench hurt jump file august wise shallow faculty impulse spring exact slush thunder author capable act festival slice deposit sauce coconut afford frown better");
    assert(await wallet.getAccountId(index: 0) ==
        "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ");
    keyPair = await wallet.getKeyPair(index: 0);
    assert(keyPair.accountId ==
        "GC3MMSXBWHL6CPOAVERSJITX7BH76YU252WGLUOM5CJX3E7UCYZBTPJQ");
    assert(keyPair.secretSeed ==
        "SAEWIVK3VLNEJ3WEJRZXQGDAS5NVG2BYSYDFRSH4GKVTS5RXNVED5AX7");

    wallet = await Wallet.from(
        'cable spray genius state float twenty onion head street palace net private method loan turn phrase state blanket interest dry amazing dress blast tube',
        passphrase: "p4ssphr4se");
    assert(await wallet.getAccountId(index: 0) ==
        "GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ");

    keyPair = await wallet.getKeyPair(index: 0);
    assert(keyPair.accountId ==
        "GDAHPZ2NSYIIHZXM56Y36SBVTV5QKFIZGYMMBHOU53ETUSWTP62B63EQ");
    assert(keyPair.secretSeed ==
        "SAFWTGXVS7ELMNCXELFWCFZOPMHUZ5LXNBGUVRCY3FHLFPXK4QPXYP2X");

    keyPair = await wallet.getKeyPair(index: 1);
    assert(keyPair.accountId ==
        "GDY47CJARRHHL66JH3RJURDYXAMIQ5DMXZLP3TDAUJ6IN2GUOFX4OJOC");
    assert(keyPair.secretSeed ==
        "SBQPDFUGLMWJYEYXFRM5TQX3AX2BR47WKI4FDS7EJQUSEUUVY72MZPJF");
  });
}
