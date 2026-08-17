import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';
import 'package:pinenacl/ed25519.dart' as ed25519;

import '../tests_util.dart';

/// Matches a [FormatException] carrying exactly [message].
///
/// A [FormatException] is an [Exception], while a [RangeError] raised by
/// reading past the end of a buffer is an [Error]. Pinning the type therefore
/// separates a refusal the codec makes deliberately from a failure it runs
/// into while decoding.
Matcher throwsFormat(String message) => throwsA(isA<FormatException>()
    .having((FormatException e) => e.message, 'message', message));

/// Matches an [Exception] whose rendering contains [fragment].
Matcher throwsExceptionWith(String fragment) => throwsA(isA<Exception>()
    .having((Exception e) => e.toString(), 'toString', contains(fragment)));

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

    // throws an error when the string is not the base32 of the bytes it holds
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
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SCMB30FQCIQAWZ4WQTS6SVK37LGMAFJGXOZIHTH2PY6EXLP37G46H6DT");
    } on Exception catch (e) {
      assert("FormatException: Invalid encoded string" == e.toString());
      thrown = true;
    }
    assert(thrown);

    // throws an error when the string is not the length of its type
    thrown = false;
    try {
      // invalid account id
      StrKey.decodeStellarAccountId(
          "GCFZB6L25D26RQFDWSSBDEYQ32JHLRMTT44ZYE3DZQUTYOL7WY43PLBG++");
    } on Exception catch (e) {
      assert("FormatException: Encoded string must be 56 characters, got 58" ==
          e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid account id
      StrKey.decodeStellarAccountId(
          "GB6OWYST45X57HCJY5XWOHDEBULB6XUROWPIKW77L5DSNANBEQGUPADT2T");
    } on Exception catch (e) {
      assert("FormatException: Encoded string must be 56 characters, got 58" ==
          e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYW");
    } on Exception catch (e) {
      assert("FormatException: Encoded string must be 56 characters, got 50" ==
          e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2");
    } on Exception catch (e) {
      assert("FormatException: Encoded string must be 56 characters, got 57" ==
          e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SB7OJNF5727F3RJUG5ASQJ3LUM44ELLNKW35ZZQDHMVUUQNGYWMEGB2W2T");
    } on Exception catch (e) {
      assert("FormatException: Encoded string must be 56 characters, got 58" ==
          e.toString());
      thrown = true;
    }
    assert(thrown);

    thrown = false;
    try {
      // invalid secret seed
      StrKey.decodeStellarSecretSeed(
          "SAYC2LQ322EEHZYWNSKBEW6N66IRTDREEBUXXU5HPVZGMAXKLIZNM45H++");
    } on Exception catch (e) {
      assert("FormatException: Encoded string must be 56 characters, got 58" ==
          e.toString());
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

  test('refuses to encode a payload of the wrong width', () async {
    final short = Uint8List(31);
    final encodersOf32Bytes = <String, String Function(Uint8List)>{
      'account id': StrKey.encodeStellarAccountId,
      'secret seed': StrKey.encodeStellarSecretSeed,
      'pre auth tx': StrKey.encodePreAuthTx,
      'sha256 hash': StrKey.encodeSha256Hash,
      'contract id': StrKey.encodeContractId,
      'liquidity pool id': StrKey.encodeLiquidityPoolId,
    };

    encodersOf32Bytes.forEach((name, encode) {
      expect(() => encode(short),
          throwsExceptionWith("Payload must be 32 bytes, got 31"),
          reason: name);
    });
    expect(() => StrKey.encodeStellarMuxedAccountId(Uint8List(39)),
        throwsExceptionWith("Payload must be 40 bytes, got 39"));
  });

  test('test sep-23 contract and muxed id 0 vectors', () async {
    final contract = "CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA";
    assert(StrKey.isValidContractId(contract));
    assert(
        contract == StrKey.encodeContractId(StrKey.decodeContractId(contract)));

    final muxedIdZero =
        "MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ";
    assert(StrKey.isValidStellarMuxedAccountId(muxedIdZero));
    assert(muxedIdZero ==
        StrKey.encodeStellarMuxedAccountId(
            StrKey.decodeStellarMuxedAccountId(muxedIdZero)));

    // An id of 0 stays a muxed account: it multiplexes the base account, it
    // does not collapse into it.
    final muxed = MuxedAccount.fromAccountId(muxedIdZero)!;
    assert(muxed.id == BigInt.zero);
    assert(muxed.accountId == muxedIdZero);
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

  test('test contract id hex validation accepts what contract id does',
      () async {
    // isValidContractIdHex has always taken a C... strkey rather than hex, and
    // answers for exactly the strings isValidContractId answers for.
    final contractId =
        "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE";
    final asHex =
        "363eaa3867841fbad0f4ed88c779e4fe66e56a2470dc98c0ec9c073d05c7b103";
    final candidates = <String, bool>{
      contractId: true,
      asHex: false,
      "GA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE": false,
      "INVALID": false,
      "": false,
    };

    candidates.forEach((candidate, accepted) {
      expect(StrKey.isValidContractIdHex(candidate), accepted,
          reason: candidate);
      expect(StrKey.isValidContractIdHex(candidate),
          StrKey.isValidContractId(candidate),
          reason: candidate);
    });
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

    // test with removed discriminant
    final asHex2 =
        "3f0c34bf93ad0d9971d04ccc90f705511c838aad9734a4a2fb0d7a03fc7fe89a";
    final cId2 = StrKey.encodeClaimableBalanceIdHex(asHex2);
    assert(claimableBalanceId == cId2);

    // test with the XDR encoding Horizon reports: the four byte union
    // discriminant in front of the hash
    final asHexXdr = "000000" + asHex;
    assert(claimableBalanceId == StrKey.encodeClaimableBalanceIdHex(asHexXdr));

    // The union discriminant is the whole four byte prefix, so a value set in
    // any of those bytes names no balance id type.
    for (final prefix in <String>["00000001", "01000000", "00010000"]) {
      expect(
          () => StrKey.encodeClaimableBalanceIdHex(prefix + asHex2),
          throwsExceptionWith("claimable balance id carries an XDR "
              "discriminant that names no claimable balance id type"),
          reason: prefix);
    }

    final xdr = "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";

    final aTx = AbstractTransaction.fromEnvelopeXdrString(xdr);
    assert (aTx is Transaction);
    final tx = aTx as Transaction;
    final op = tx.operations.first;
    assert(op is InvokeHostFunctionOperation);
    final hostFunction = (op as InvokeHostFunctionOperation).function;
    assert(hostFunction is InvokeContractHostFunction);
    final contractId = (hostFunction as InvokeContractHostFunction).contractID;
    assert("BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU" == contractId);
  });

  // The signed payload strkeys SEP-0023 lists as invalid, each named by the
  // reason the specification gives for refusing it.
  final signedPayloadPrefixShorterThanPayload =
      "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IAAAAAAAAPM";
  final signedPayloadPrefixLongerThanPayload =
      "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4Z2PQ";
  final signedPayloadWithoutZeroPadding =
      "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DXFH6";

  // The claimable balance strkey SEP-0023 lists as invalid because the
  // discriminant it leads with names no balance id type.
  final claimableBalanceOfUnknownType =
      "BAAT6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGXACA";

  // The two signed payload strkeys SEP-0023 lists as valid.
  final signedPayloadOf32Bytes =
      "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM";
  final signedPayloadOf29Bytes =
      "PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUAAAAFGBU";

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
    assert(!StrKey.isValidStellarMuxedAccountId(strKey));

    // Length prefix specifies length that is shorter than payload in signed
    // payload
    assert(!StrKey.isValidSignedPayload(signedPayloadPrefixShorterThanPayload));

    // Length prefix specifies length that is longer than payload in signed
    // payload
    assert(!StrKey.isValidSignedPayload(signedPayloadPrefixLongerThanPayload));

    // No zero padding in signed payload
    assert(!StrKey.isValidSignedPayload(signedPayloadWithoutZeroPadding));

    // Invalid claimable balance type (first byte of binary key is not 0)
    assert(!StrKey.isValidClaimableBalanceId(claimableBalanceOfUnknownType));
  });

  group('strkey decode refuses malformed input', () {
    // encodeCheck prepends the version byte and appends the CRC without
    // inspecting the width it was handed, so each address below is a
    // well-formed base32 rendering carrying a valid checksum and differs from
    // a real address only in the number of bytes it holds.
    final payloadOf31Bytes = Uint8List.fromList(List<int>.filled(31, 1));
    final payloadOf32Bytes = Uint8List.fromList(List<int>.filled(32, 1));
    final payloadOf37Bytes = Uint8List.fromList(List<int>.filled(37, 1));
    final accountIdOf31Bytes =
        craftStrKey(VersionByte.ACCOUNT_ID.getValue(), payloadOf31Bytes);
    final accountIdOf32Bytes =
        StrKey.encodeCheck(VersionByte.ACCOUNT_ID, payloadOf32Bytes);
    final accountIdOf37Bytes =
        craftStrKey(VersionByte.ACCOUNT_ID.getValue(), payloadOf37Bytes);
    final liquidityPoolOf32Bytes =
        StrKey.encodeCheck(VersionByte.LIQUIDITY_POOL, payloadOf32Bytes);

    test('accepts the address the wrong-width vectors are built beside', () {
      expect(accountIdOf32Bytes.length, 56);
      expect(
          StrKey.decodeStellarAccountId(accountIdOf32Bytes), payloadOf32Bytes);
    });

    test('refuses an empty string', () {
      expect(() => StrKey.decodeStellarAccountId(""),
          throwsFormat("Encoded string must be 56 characters, got 0"));
    });

    test('refuses a one character string', () {
      expect(() => StrKey.decodeStellarAccountId("G"),
          throwsFormat("Encoded string must be 56 characters, got 1"));
    });

    test('refuses a valid checksum carried on too few characters', () {
      expect(accountIdOf31Bytes.length, 55);
      expect(() => StrKey.decodeStellarAccountId(accountIdOf31Bytes),
          throwsFormat("Encoded string must be 56 characters, got 55"));
    });

    test('refuses a valid checksum carried on too many characters', () {
      expect(accountIdOf37Bytes.length, 64);
      expect(() => StrKey.decodeStellarAccountId(accountIdOf37Bytes),
          throwsFormat("Encoded string must be 56 characters, got 64"));
      expect(() => KeyPair.fromAccountId(accountIdOf37Bytes),
          throwsFormat("Encoded string must be 56 characters, got 64"));
    });

    test('refuses an over-long string', () {
      final overLongAccountId = "G${"A" * 319999}";
      expect(overLongAccountId.length, 320000);
      expect(() => StrKey.decodeStellarAccountId(overLongAccountId),
          throwsFormat("Encoded string must be 56 characters, got 320000"));

      final overLongSignedPayload = "P${"A" * 319999}";
      expect(
          () => StrKey.decodeSignedPayload(overLongSignedPayload),
          throwsFormat(
              "Encoded string must be 69 to 165 characters, got 320000"));
    });

    test('refuses a version byte belonging to another type', () {
      expect(liquidityPoolOf32Bytes.length, 56);
      expect(() => StrKey.decodeContractId(liquidityPoolOf32Bytes),
          throwsFormat("Version byte is invalid"));
    });

    test('refuses a version byte naming no type at all', () {
      expect(() => StrKey.decodeCheck(VersionByte(0), accountIdOf32Bytes),
          throwsFormat("Unrecognized version byte 0"));

      // One above the account id version byte, so the low three bits carry a
      // value no type claims.
      expect(() => StrKey.decodeCheck(VersionByte(49), accountIdOf32Bytes),
          throwsFormat("Unrecognized version byte 49"));
    });

    test('refuses a claimable balance id of an unknown type', () {
      expect(
          () => StrKey.decodeClaimableBalanceId(claimableBalanceOfUnknownType),
          throwsFormat("Decoded claimable balance id carries the discriminant "
              "1, which names no claimable balance id type"));
    });

    test('refuses to build a balance id from an unknown type', () {
      XdrClaimableBalanceID? built;
      expect(
          () => built =
              XdrClaimableBalanceID.forId(claimableBalanceOfUnknownType),
          throwsA(isA<FormatException>()));
      expect(built, isNull);
    });

    test('refuses to encode a claimable balance id of an unknown type', () {
      expect(
          () => StrKey.encodeClaimableBalanceId(
              Uint8List.fromList([1, ...payloadOf32Bytes])),
          throwsExceptionWith("claimable balance id carries the discriminant 1,"
              " which names no claimable balance id type"));
    });

    test('refuses to encode a claimable balance id of an unknown type through '
        'the raw codec', () {
      // encodeClaimableBalanceId reads the discriminant of what it is handed,
      // and encodeCheck holds the same rule for a caller that reaches past it.
      final unknownType = Uint8List.fromList([1, ...payloadOf32Bytes]);
      expect(
          () => StrKey.encodeCheck(VersionByte.CLAIMABLE_BALANCE, unknownType),
          throwsFormat("Claimable balance id carries the discriminant 1, "
              "which names no claimable balance id type"));
      expect(
          () => StrKey.decodeClaimableBalanceId(
              craftStrKey(VersionByte.CLAIMABLE_BALANCE.getValue(),
                  unknownType)),
          throwsFormat("Decoded claimable balance id carries the discriminant "
              "1, which names no claimable balance id type"));
    });

    test('refuses to encode a claimable balance id of the wrong width', () {
      expect(
          () => StrKey.encodeClaimableBalanceId(payloadOf31Bytes),
          throwsExceptionWith(
              "claimable balance id must be 32 bytes (the hash), 33 bytes "
              "(the hash behind its discriminant), or 36 bytes "
              "(its XDR encoding), got 31"));
      expect(
          () => StrKey.encodeClaimableBalanceId(payloadOf37Bytes),
          throwsExceptionWith(
              "claimable balance id must be 32 bytes (the hash), 33 bytes "
              "(the hash behind its discriminant), or 36 bytes "
              "(its XDR encoding), got 37"));
    });
  });

  group('signed payload framing', () {
    final signerKey = keyPair.publicKey;

    /// Builds the payload region a signed payload strkey carries: the 32-byte
    /// signer key, [declared] as a big-endian unsigned 32-bit length, and
    /// [body] as the bytes that follow it.
    Uint8List region(int declared, List<int> body) {
      final length = ByteData(4)..setUint32(0, declared, Endian.big);
      return Uint8List.fromList(
          [...signerKey, ...length.buffer.asUint8List(), ...body]);
    }

    final declaresEmptyPayload = region(0, List<int>.filled(4, 0));
    final declaresOversizePayload = region(65, List<int>.filled(4, 0));
    final declaresLessThanItCarries = region(32, List<int>.filled(36, 7));
    final declaresMoreThanItCarries = region(29, List<int>.filled(28, 7));
    final padsWithoutNul = region(29, [...List<int>.filled(29, 7), 0, 0, 1]);
    final wellFramed = region(29, [...List<int>.filled(29, 7), 0, 0, 0]);

    test('names the payload lengths a signed payload cannot render', () {
      expect(StrKey.signedPayloadLengthViolation(0),
          "carries an empty payload, which has no strkey rendering");
      expect(StrKey.signedPayloadLengthViolation(65),
          "carries a 65-byte payload, more than the declared maximum of 64");
      expect(StrKey.signedPayloadLengthViolation(1), isNull);
      expect(StrKey.signedPayloadLengthViolation(64), isNull);
    });

    test('names a region too short to hold a signer key and a length', () {
      expect(StrKey.signedPayloadFramingViolation(Uint8List(35)),
          "is 35 bytes, too short to hold a signer key and a payload length");
    });

    test('names a region declaring an empty payload', () {
      expect(StrKey.signedPayloadFramingViolation(declaresEmptyPayload),
          "carries an empty payload, which has no strkey rendering");
    });

    test('names a region declaring more than the maximum payload', () {
      expect(StrKey.signedPayloadFramingViolation(declaresOversizePayload),
          "carries a 65-byte payload, more than the declared maximum of 64");
    });

    test('names a region wider than its declared length occupies', () {
      expect(StrKey.signedPayloadFramingViolation(declaresLessThanItCarries),
          "is 72 bytes, but a 32-byte payload occupies 68");
    });

    test('names a region narrower than its declared length occupies', () {
      expect(StrKey.signedPayloadFramingViolation(declaresMoreThanItCarries),
          "is 64 bytes, but a 29-byte payload occupies 68");
    });

    test('names a region padding its payload with a byte that is not NUL', () {
      expect(StrKey.signedPayloadFramingViolation(padsWithoutNul),
          "pads its payload with a byte that is not NUL");
    });

    test('accepts a well framed region', () {
      expect(StrKey.signedPayloadFramingViolation(wellFramed), isNull);
    });

    test('refuses every framing violation carried on a P address', () {
      // encodeCheck applies the same framing rule, so each address below is
      // crafted around it: the version byte and the checksum are right and the
      // framing of the payload is the only thing wrong with it.
      final cases = <(String, String)>[
        (
          craftStrKey(
              VersionByte.SIGNED_PAYLOAD.getValue(), declaresEmptyPayload),
          "Decoded signed payload carries an empty payload, "
              "which has no strkey rendering"
        ),
        (
          craftStrKey(
              VersionByte.SIGNED_PAYLOAD.getValue(), declaresOversizePayload),
          "Decoded signed payload carries a 65-byte payload, "
              "more than the declared maximum of 64"
        ),
        (
          craftStrKey(
              VersionByte.SIGNED_PAYLOAD.getValue(), declaresLessThanItCarries),
          "Decoded signed payload is 72 bytes, "
              "but a 32-byte payload occupies 68"
        ),
        (
          craftStrKey(
              VersionByte.SIGNED_PAYLOAD.getValue(), declaresMoreThanItCarries),
          "Decoded signed payload is 64 bytes, "
              "but a 29-byte payload occupies 68"
        ),
        (
          craftStrKey(VersionByte.SIGNED_PAYLOAD.getValue(), padsWithoutNul),
          "Decoded signed payload pads its payload with a byte that is not NUL"
        ),
      ];

      for (final (address, message) in cases) {
        expect(() => StrKey.decodeSignedPayload(address), throwsFormat(message),
            reason: address);
        expect(() => StrKey.decodeXdrSignedPayload(address),
            throwsFormat(message),
            reason: address);
        expect(StrKey.isValidSignedPayload(address), isFalse, reason: address);
      }
    });

    test('refuses to encode every framing violation', () {
      final cases = <(Uint8List, String)>[
        (
          declaresEmptyPayload,
          "Signed payload carries an empty payload, "
              "which has no strkey rendering"
        ),
        (
          declaresOversizePayload,
          "Signed payload carries a 65-byte payload, "
              "more than the declared maximum of 64"
        ),
        (
          declaresLessThanItCarries,
          "Signed payload is 72 bytes, but a 32-byte payload occupies 68"
        ),
        (
          declaresMoreThanItCarries,
          "Signed payload is 64 bytes, but a 29-byte payload occupies 68"
        ),
        (
          padsWithoutNul,
          "Signed payload pads its payload with a byte that is not NUL"
        ),
      ];

      for (final (region, message) in cases) {
        expect(
            () => StrKey.encodeCheck(VersionByte.SIGNED_PAYLOAD, region),
            throwsFormat(message),
            reason: message);
      }
    });

    test('encodes a well framed region', () {
      final encoded =
          StrKey.encodeCheck(VersionByte.SIGNED_PAYLOAD, wellFramed);
      expect(encoded, startsWith("P"));
      expect(StrKey.decodeCheck(VersionByte.SIGNED_PAYLOAD, encoded),
          wellFramed);
    });

    test('refuses the signed payloads SEP-0023 lists as invalid', () {
      // decodeXdrSignedPayload hands its bytes straight to the XDR reader, so
      // it is only the framing check that keeps these out of it.
      final cases = <(String, String)>[
        (
          signedPayloadPrefixShorterThanPayload,
          "Decoded signed payload is 72 bytes, "
              "but a 32-byte payload occupies 68"
        ),
        (
          signedPayloadPrefixLongerThanPayload,
          "Decoded signed payload is 64 bytes, "
              "but a 29-byte payload occupies 68"
        ),
        (
          signedPayloadWithoutZeroPadding,
          "Decoded signed payload is 65 bytes, "
              "but a 29-byte payload occupies 68"
        ),
      ];

      for (final (address, message) in cases) {
        expect(() => StrKey.decodeSignedPayload(address), throwsFormat(message),
            reason: address);
        expect(() => StrKey.decodeXdrSignedPayload(address),
            throwsFormat(message),
            reason: address);
      }
    });

    test('re-encodes a payload of every boundary width to the same string', () {
      // 1 and 3 bytes are padded to 4, 4 bytes takes no padding, 5 bytes is
      // padded to 8, and 64 bytes is the widest payload the format carries.
      for (final width in <int>[1, 3, 4, 5, 64]) {
        final payload =
            Uint8List.fromList(List<int>.generate(width, (int i) => i + 1));
        final encoded = StrKey.encodeSignedPayload(
            SignedPayloadSigner.fromPublicKey(signerKey, payload));

        final decoded = StrKey.decodeSignedPayload(encoded);
        expect(decoded.payload, payload, reason: "payload of $width bytes");
        expect(StrKey.encodeSignedPayload(decoded), encoded,
            reason: "payload of $width bytes");

        final decodedXdr = StrKey.decodeXdrSignedPayload(encoded);
        expect(decodedXdr.payload.dataValue, payload,
            reason: "payload of $width bytes");
        expect(StrKey.encodeXdrSignedPayload(decodedXdr), encoded,
            reason: "payload of $width bytes");
      }
    });

    test('reaches both ends of its encoded length range', () {
      expect(
          StrKey.encodeSignedPayload(SignedPayloadSigner.fromPublicKey(
                  signerKey, Uint8List.fromList([1])))
              .length,
          69);
      expect(
          StrKey.encodeSignedPayload(SignedPayloadSigner.fromPublicKey(
                  signerKey, Uint8List.fromList(List<int>.filled(64, 1))))
              .length,
          165);
    });
  });

  group('strkey malleability', () {
    test('refuses a signed payload declaring less than it carries', () {
      // Read back as the length prefix declares, this address yields a 32-byte
      // payload that re-encodes to a shorter, different address.
      expect(
          () => StrKey.decodeSignedPayload(
              signedPayloadPrefixShorterThanPayload),
          throwsFormat("Decoded signed payload is 72 bytes, "
              "but a 32-byte payload occupies 68"));
      expect(StrKey.isValidSignedPayload(signedPayloadPrefixShorterThanPayload),
          isFalse);
    });

    test('re-encodes every accepted address to the string it came from', () {
      final addresses = <(String, String Function(String))>[
        (
          accountIdEncoded,
          (String a) =>
              StrKey.encodeStellarAccountId(StrKey.decodeStellarAccountId(a))
        ),
        (
          MPUBKEY,
          (String a) => StrKey.encodeStellarMuxedAccountId(
              StrKey.decodeStellarMuxedAccountId(a))
        ),
        (
          seedEncoded,
          (String a) =>
              StrKey.encodeStellarSecretSeed(StrKey.decodeStellarSecretSeed(a))
        ),
        (
          StrKey.encodePreAuthTx(keyPair.publicKey),
          (String a) => StrKey.encodePreAuthTx(StrKey.decodePreAuthTx(a))
        ),
        (
          StrKey.encodeSha256Hash(keyPair.publicKey),
          (String a) => StrKey.encodeSha256Hash(StrKey.decodeSha256Hash(a))
        ),
        (
          signedPayloadOf32Bytes,
          (String a) =>
              StrKey.encodeSignedPayload(StrKey.decodeSignedPayload(a))
        ),
        (
          signedPayloadOf29Bytes,
          (String a) =>
              StrKey.encodeSignedPayload(StrKey.decodeSignedPayload(a))
        ),
        (
          signedPayloadOf29Bytes,
          (String a) =>
              StrKey.encodeXdrSignedPayload(StrKey.decodeXdrSignedPayload(a))
        ),
        (
          "CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE",
          (String a) => StrKey.encodeContractId(StrKey.decodeContractId(a))
        ),
        (
          "LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN",
          (String a) =>
              StrKey.encodeLiquidityPoolId(StrKey.decodeLiquidityPoolId(a))
        ),
        (
          "BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU",
          (String a) => StrKey.encodeClaimableBalanceId(
              StrKey.decodeClaimableBalanceId(a))
        ),
      ];

      for (final (address, reencode) in addresses) {
        expect(reencode(address), address, reason: address);
      }
    });
  });

  group('strkey version bytes', () {
    // decodeCheck reads the lengths a type admits from a table keyed by
    // version byte, and refuses a version byte the table does not hold before
    // it decodes anything. A row added below for a version byte the table does
    // not hold therefore fails on "Unrecognized version byte".
    final hash = Uint8List.fromList(List<int>.filled(32, 1));
    final muxedAccount =
        Uint8List.fromList([...hash, ...List<int>.filled(8, 2)]);
    final claimableBalance = Uint8List.fromList([0, ...hash]);
    final signedPayload =
        Uint8List.fromList([...hash, 0, 0, 0, 4, 9, 9, 9, 9]);

    final payloads = <(VersionByte, Uint8List)>[
      (VersionByte.ACCOUNT_ID, hash),
      (VersionByte.MUXED_ACCOUNT_ID, muxedAccount),
      (VersionByte.SEED, hash),
      (VersionByte.PRE_AUTH_TX, hash),
      (VersionByte.SHA256_HASH, hash),
      (VersionByte.SIGNED_PAYLOAD, signedPayload),
      (VersionByte.CONTRACT_ID, hash),
      (VersionByte.LIQUIDITY_POOL, hash),
      (VersionByte.CLAIMABLE_BALANCE, claimableBalance),
    ];

    test('decodes an address of every type the codec names', () {
      expect(payloads.length, 9);
      for (final (versionByte, payload) in payloads) {
        final encoded = StrKey.encodeCheck(versionByte, payload);
        expect(StrKey.decodeCheck(versionByte, encoded), payload,
            reason: "version byte ${versionByte.getValue()}");
      }
    });
  });
}
