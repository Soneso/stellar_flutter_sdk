import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';
import 'package:pinenacl/ed25519.dart' as ed25519;

void main() {
  final keyPair = KeyPair.fromSecretSeedList(Util.hash(
      Uint8List.fromList(Network.TESTNET.networkPassphrase.codeUnits)));
  final accountIdEncoded = keyPair.accountId;
  final seedEncoded = keyPair.secretSeed;

  test('test decode check', () async {
    // decodes account id correctly
    final decodedAccountId = StrKey.decodeStellarAccountId(accountIdEncoded);
    assert(ListEquality().equals(keyPair.publicKey, decodedAccountId));

    // decodes secret seed correctly
    final decodedSeed = StrKey.decodeStellarSecretSeed(seedEncoded);
    assert(ListEquality().equals(
        ed25519.SigningKey.fromValidBytes(keyPair.privateKey!).seed.asTypedList,
        decodedSeed));

    // throws an error when the version byte is wrong
    var thrown = false;
    try {
      StrKey.decodeStellarSecretSeed(
          "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL");
    } on Exception catch (e) {
      assert("FormatException: Version byte is invalid" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      StrKey.decodeStellarAccountId(
          "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCU");
    } on Exception catch (e) {
      assert("FormatException: Version byte is invalid" == e.toString());
      thrown = true;
    }
    assert(thrown);

    // throws an error when invalid encoded string
    thrown = false;
    try {
      // invalid account id
      StrKey.decodeStellarAccountId(
          "GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid account id
      StrKey.decodeStellarAccountId(
          "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid account id
      StrKey.decodeStellarAccountId(
          "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYW");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2T");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SCMB30FQCIQAWZ4WQTS6SVK37LGMAFJGXOZIHTH2PY6EXLP37G46H6DT");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SAYC2LQ322EEHZYWNSKBEW6N66IRTDREEBUXXU5HPVZGMAXKLIZNM45H++");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    // throws an error when checksum is wrong
    thrown = false;
    try {
      // invalid account id checksum
      StrKey.decodeStellarAccountId(
          "GBPXXOA5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVT");
    } on Exception catch (e) {
      assert("FormatException: Checksum invalid" == e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed checksum
      StrKey.decodeStellarSecretSeed(
          "SBGWKM3CD4IL47QN6X54N6Y33T3JDNVI6AIJ6CD5IM47HG3IG4O36XCX");
    } on Exception catch (e) {
      assert("FormatException: Checksum invalid" == e.toString());
      thrown = true;
    }
    assert(thrown);
  });

  test('test encode check', () async {
    // encodes a buffer correctly
    final encodedAccountId = StrKey.encodeStellarAccountId(keyPair.publicKey);
    assert(accountIdEncoded == encodedAccountId);
    assert(encodedAccountId.startsWith("G"));
    assert(ListEquality().equals(
        keyPair.publicKey, StrKey.decodeStellarAccountId(accountIdEncoded)));

    final encodedSecretSeed = StrKey.encodeStellarSecretSeed(
        ed25519.SigningKey.fromValidBytes(keyPair.privateKey!)
            .seed
            .asTypedList);
    assert(seedEncoded == encodedSecretSeed);
    assert(encodedSecretSeed.startsWith("S"));
    assert(ListEquality().equals(
        ed25519.SigningKey.fromValidBytes(keyPair.privateKey!).seed.asTypedList,
        StrKey.decodeStellarSecretSeed(encodedSecretSeed)));

    var strKeyEncoded = StrKey.encodePreAuthTx(keyPair.publicKey);
    assert(strKeyEncoded.startsWith("T"));
    assert(ListEquality()
        .equals(keyPair.publicKey, StrKey.decodePreAuthTx(strKeyEncoded)));

    strKeyEncoded = StrKey.encodeSha256Hash(keyPair.publicKey);
    assert(strKeyEncoded.startsWith("X"));
    assert(ListEquality()
        .equals(keyPair.publicKey, StrKey.decodeSha256Hash(strKeyEncoded)));
  });

  test('test is valid', () async {
    // returns true for valid public key
    var keys = [
      'GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB',
      'GB7KKHHVYLDIZEKYJPAJUOTBE5E3NJAXPSDZK7O6O44WR3EBRO5HRPVT',
      'GD6WVYRVID442Y4JVWFWKWCZKB45UGHJAABBJRS22TUSTWGJYXIUR7N2',
      'GBCG42WTVWPO4Q6OZCYI3D6ZSTFSJIXIS6INCIUF23L6VN3ADE4337AP',
      'GDFX463YPLCO2EY7NGFMI7SXWWDQAMASGYZXCG2LATOF3PP5NQIUKBPT',
      'GBXEODUMM3SJ3QSX2VYUWFU3NRP7BQRC2ERWS7E2LZXDJXL2N66ZQ5PT',
      'GAJHORKJKDDEPYCD6URDFODV7CVLJ5AAOJKR6PG2VQOLWFQOF3X7XLOG',
      'GACXQEAXYBEZLBMQ2XETOBRO4P66FZAJENDHOQRYPUIXZIIXLKMZEXBJ',
      'GDD3XRXU3G4DXHVRUDH7LJM4CD4PDZTVP4QHOO4Q6DELKXUATR657OZV',
      'GDTYVCTAUQVPKEDZIBWEJGKBQHB4UGGXI2SXXUEW7LXMD4B7MK37CWLJ'
    ];

    for (var key in keys) {
      assert(StrKey.isValidStellarAccountId(key));
    }

    // returns false for invalid public key
    keys = [
      'GBPXX0A5N4JYPESHAADMQKBPWZWQDQ64ZV6ZL2S3LAGW4SY7NTCMWIVL',
      'GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++',
      'GADE5QJ2TY7S5ZB65Q43DFGWYWCPHIYDJ2326KZGAGBN7AE5UY6JVDRRA',
      'GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2',
      'GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T',
      'GDXIIZTKTLVYCBHURXL2UPMTYXOVNI7BRAEFQCP6EZCY4JLKY4VKFNLT',
      'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY',
      'gWRYUerEKuz53tstxEuR3NCkiQDcV4wzFHmvLnZmj7PUqxW2wt',
      'test',
      'g4VPBPrHZkfE8CsjuG2S4yBQNd455UWmk' // Old network key
    ];

    for (var key in keys) {
      assert(!StrKey.isValidStellarAccountId(key));
    }

    // returns true for valid secret key
    keys = [
      'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY',
      'SCZTUEKSEH2VYZQC6VLOTOM4ZDLMAGV4LUMH4AASZ4ORF27V2X64F2S2',
      'SCGNLQKTZ4XCDUGVIADRVOD4DEVNYZ5A7PGLIIZQGH7QEHK6DYODTFEH',
      'SDH6R7PMU4WIUEXSM66LFE4JCUHGYRTLTOXVUV5GUEPITQEO3INRLHER',
      'SC2RDTRNSHXJNCWEUVO7VGUSPNRAWFCQDPP6BGN4JFMWDSEZBRAPANYW',
      'SCEMFYOSFZ5MUXDKTLZ2GC5RTOJO6FGTAJCF3CCPZXSLXA2GX6QUYOA7'
    ];

    for (var key in keys) {
      assert(StrKey.isValidStellarSecretSeed(key));
    }

    // returns false for invalid secret key
    keys = [
      'GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB',
      'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDYT', // Too long
      'SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEV', // To short
      'SAFGAMN5Z6IHVI3IVEPIILS7ITZDYSCEPLN4FN5Z3IY63DRH4CIYEVIT', // Checksum
      'test',
    ];

    for (var key in keys) {
      assert(!StrKey.isValidStellarSecretSeed(key));
    }
  });

  final MPUBKEY =
      'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK';
  final RAW_MPUBKEY = Util.hexToBytes(
      '3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a8000000000000000');

  test('test muxed accounts', () async {
    // encodes & decodes M... addresses correctly
    assert(MPUBKEY == StrKey.encodeStellarMuxedAccountId(RAW_MPUBKEY));
    assert(ListEquality()
        .equals(RAW_MPUBKEY, StrKey.decodeStellarMuxedAccountId(MPUBKEY)));
  });

  test('test signed payloads', () async {
    var decoded = StrKey.decodeSignedPayload(
        "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM");
    assert("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ" ==
        KeyPair.fromXdrAccountId(decoded.signerAccountID).accountId);
    assert("0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20" ==
        Util.bytesToHex(decoded.payload));

    decoded = StrKey.decodeSignedPayload(
        "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU");
    assert("GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ" ==
        KeyPair.fromXdrAccountId(decoded.signerAccountID).accountId);
    assert("0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d" ==
        Util.bytesToHex(decoded.payload));
  });

  test('test contracts', () async {
    final contractId =
        "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE";
    final asHex =
        "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103";
    var decoded = StrKey.decodeContractId(contractId);
    assert(asHex == Util.bytesToHex(decoded));
    assert(contractId == StrKey.encodeContractId(Util.hexToBytes(asHex)));
    assert(contractId == StrKey.encodeContractIdHex(asHex));

    assert(StrKey.isValidContractId(contractId));
    assert(!StrKey.isValidContractId(
        "GA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE"));
  });

  test('test liquidity pools', () async {
    final liquidityPoolId =
        "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN";
    final asHex =
        "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a";
    var decoded = StrKey.decodeLiquidityPoolId(liquidityPoolId);
    assert(asHex == Util.bytesToHex(decoded));
    assert(liquidityPoolId ==
        StrKey.encodeLiquidityPoolId(Util.hexToBytes(asHex)));
    assert(liquidityPoolId == StrKey.encodeLiquidityPoolIdHex(asHex));

    assert(StrKey.isValidLiquidityPoolId(liquidityPoolId));
    assert(!StrKey.isValidLiquidityPoolId(
        "LB7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN"));
  });

  test('test claimable balances', () async {
    final claimableBalanceId =
        "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU";
    final asHex =
        "003f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a";
    var decoded = StrKey.decodeClaimableBalanceId(claimableBalanceId);
    assert(asHex == Util.bytesToHex(decoded));
    assert(claimableBalanceId ==
        StrKey.encodeClaimableBalanceId(Util.hexToBytes(asHex)));
    assert(claimableBalanceId == StrKey.encodeClaimableBalanceIdHex(asHex));

    assert(StrKey.isValidClaimableBalanceId(claimableBalanceId));
    assert(!StrKey.isValidClaimableBalanceId(
        "BBAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU"));
  });

  test('test invalid str keys', () async {
    // The unused trailing bit must be zero in the encoding of the last three
    // bytes (24 bits) as five base-32 symbols (25 bits)
    var strKey =
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUR";
    assert(!StrKey.isValidStellarMuxedAccountId(strKey));

    // Invalid length (congruent to 1 mod 8)
    strKey = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZA";
    assert(!StrKey.isValidStellarAccountId(strKey));

    // Invalid algorithm (low 3 bits of version byte are 7)
    strKey = "G47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVP2I";
    assert(!StrKey.isValidStellarAccountId(strKey));

    // Invalid length (congruent to 6 mod 8)
    strKey =
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLKA";
    assert(!StrKey.isValidStellarMuxedAccountId(strKey));

    // Invalid algorithm (low 3 bits of version byte are 7)
    strKey =
        "M47QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ";
    assert(!StrKey.isValidStellarMuxedAccountId(strKey));

    // Padding bytes are not allowed
    strKey =
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUK===";
    assert(!StrKey.isValidStellarMuxedAccountId(strKey));

    // Invalid checksum
    strKey =
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUO";
    assert(!StrKey.isValidStellarMuxedAccountId(strKey));

    // Trailing bits should be zeroes
    strKey = "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TV";
    assert(!StrKey.isValidClaimableBalanceId(strKey));

    // Invalid length (Ed25519 should be 32 bytes, not 5)
    strKey = "GAAAAAAAACGC6";
    assert(!StrKey.isValidStellarAccountId(strKey));

    // Invalid length (base-32 decoding should yield 35 bytes, not 36)
    strKey = "GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUACUSI";
    assert(!StrKey.isValidStellarAccountId(strKey));

    // Invalid length (base-32 decoding should yield 43 bytes, not 44)
    strKey =
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAAV75I";
    assert(!StrKey.isValidStellarAccountId(strKey));
  });
}
