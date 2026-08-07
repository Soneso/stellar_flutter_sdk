import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// The types SEP-0051 §Stellar-Specific Types gives a rendering of their own.
///
/// Three sections are covered. §Address Types lists the types that render as a
/// SEP-23 strkey, arm by arm; §Asset Code Types states the trimming and padding
/// an asset code takes; and §Integer Types states that the 128-bit and 256-bit
/// parts types render as one base-10 decimal string rather than as an object of
/// their limbs.
///
/// The strkey types are where a rendering can be wrong in a way that still
/// round-trips, so each arm is pinned against the binary form beside it, and the
/// rejections a strkey reader owes are pinned too: a wrong checksum, a strkey of
/// another kind, and a well-formed strkey carrying the wrong number of bytes.
/// A strkey codec verifies the encoding, the version byte and the checksum, and
/// says nothing about the width, so the width is checked where the declaration
/// that fixes it is known.
///
/// Four of the types the sections name are declared as typedefs that carry no
/// class of their own in this SDK: `ContractID`, `PoolID`, `AssetCode4` and
/// `AssetCode12`. A field declared with one of them is indistinguishable at the
/// Dart type level from a field declared with the type it collapsed onto, so
/// every field site of all four is swept below rather than sampled.

/// The 32-byte key every address fixture is built from, ascending so that a
/// reversal or a rotation of the bytes is visible.
final Uint8List _ed25519 = Uint8List.fromList(
  List<int>.generate(32, (int index) => index + 1),
);

/// The subaccount id of the muxed fixtures, distinct in every byte from the
/// key beside it.
final Uint8List _muxedIdBytes = Uint8List.fromList(<int>[
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
]);

const String _accountStrKey =
    'GAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSABOV';
const String _muxedStrKey =
    'MAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSAAICAMCAKBQHBCL3G';
const String _contractStrKey =
    'CADAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMSST';
const String _poolStrKey =
    'LAEQSCIJBEEQSCIJBEEQSCIJBEEQSCIJBEEQSCIJBEEQSCIJBEEQT2QG';
const String _balanceStrKey =
    'BAAAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBROVY';
const String _preAuthTxStrKey =
    'TAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSB44E';
const String _hashXStrKey =
    'XAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSAYZ5';
const String _signedPayloadStrKey =
    'PAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSAAAAAAA76AAAAADYY';
const String _signedPayload64StrKey =
    'PAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSAAAAABAAAAICAMCAKBQH'
    'BAEQUCYMBUHA6EARCIJRIFIWC4MBSGQ3DQOR4HZAEERCGJBFEYTSQKJKFMWC2LRPGAYTEMZU'
    'GU3DOOBZHI5TYPJ6H65T6';

const String _publicKeyBase64 =
    'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8g';
const String _muxedAccountBase64 =
    'AAABAAECAwQFBgcIAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA=';
const String _med25519Base64 =
    'AQIDBAUGBwgBAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIA==';

/// Replaces the final character of a strkey, which falls inside the checksum,
/// so the encoding stays well-formed and only the checksum disagrees.
String _breakChecksum(String strKey) {
  final String last = strKey.substring(strKey.length - 1);
  return strKey.substring(0, strKey.length - 1) + (last == 'A' ? 'B' : 'A');
}

void main() {
  group('SEP-0051 §Address Types renders a public key as a G strkey', () {
    test('PublicKey carries its one arm', () {
      const String json = '"$_accountStrKey"';
      expect(XdrPublicKey.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrPublicKey.fromXdrJson(json).toBase64EncodedXdrString(),
        _publicKeyBase64,
      );
    });

    test('AccountID renders the same way, being a typedef of it', () {
      const String json = '"$_accountStrKey"';
      expect(XdrAccountID.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrAccountID.fromXdrJson(json).toBase64EncodedXdrString(),
        _publicKeyBase64,
      );
    });

    test('NodeID renders the same way, being a typedef of it', () {
      const String json = '"$_accountStrKey"';
      expect(XdrNodeID.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrNodeID.fromXdrJson(json).toBase64EncodedXdrString(),
        _publicKeyBase64,
      );
    });
  });

  group('SEP-0051 §Address Types renders every muxed account arm', () {
    test('the unmuxed arm renders as a G strkey', () {
      const String json = '"$_accountStrKey"';
      expect(XdrMuxedAccount.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrMuxedAccount.fromXdrJson(json).toBase64EncodedXdrString(),
        _publicKeyBase64,
      );
    });

    test('the muxed arm renders as an M strkey', () {
      const String json = '"$_muxedStrKey"';
      expect(XdrMuxedAccount.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrMuxedAccount.fromXdrJson(json).toBase64EncodedXdrString(),
        _muxedAccountBase64,
      );
    });

    test('MuxedAccountMed25519 renders as the same M strkey on its own', () {
      const String json = '"$_muxedStrKey"';
      expect(XdrMuxedAccountMed25519.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrMuxedAccountMed25519.fromXdrJson(json).toBase64EncodedXdrString(),
        _med25519Base64,
      );
    });
  });

  group('an M strkey packs the key before the subaccount id', () {
    // The struct declares the id first and the key second; the strkey payload
    // carries them the other way round. Both orders produce a 40-byte payload
    // with a valid checksum, so nothing but the byte positions distinguishes
    // them, and every fixture here uses a key and an id that differ in every
    // byte so a swap cannot pass.

    test('the payload is the key, then the id', () {
      final Uint8List payload = StrKey.decodeStellarMuxedAccountId(
        _muxedStrKey,
      );
      expect(payload.length, 40);
      expect(payload.sublist(0, 32), _ed25519);
      expect(payload.sublist(32), _muxedIdBytes);
    });

    test('the leading 32 bytes are the key the G strkey carries', () {
      expect(
        StrKey.decodeStellarMuxedAccountId(_muxedStrKey).sublist(0, 32),
        StrKey.decodeStellarAccountId(_accountStrKey),
      );
    });

    test('the binary form carries them in the opposite order', () {
      // The first eight bytes of the XDR are the id and the remaining
      // thirty-two are the key, which is the order the rendering reverses.
      final Uint8List encoded = base64Decode(_med25519Base64);
      expect(encoded.length, 40);
      expect(encoded.sublist(0, 8), _muxedIdBytes);
      expect(encoded.sublist(8), _ed25519);

      final XdrMuxedAccountMed25519 value = XdrMuxedAccountMed25519.fromXdrJson(
        '"$_muxedStrKey"',
      );
      expect(value.ed25519.uint256, _ed25519);
      expect(value.id.uint64, BigInt.parse('72623859790382856'));
    });

    test('a payload of the wrong width is refused', () {
      // The strkey codec checks the checksum and the version byte and not the
      // width, so a 39-byte payload encodes and decodes cleanly and only this
      // reader stands between it and an instance the binary encoder would
      // write as malformed XDR.
      final String short = StrKey.encodeStellarMuxedAccountId(Uint8List(39));
      expect(
        () => XdrMuxedAccountMed25519.fromXdrJson('"$short"'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SEP-0051 §Address Types renders every contract address arm', () {
    final Map<String, String> arms = <String, String>{
      '"$_accountStrKey"':
          'AAAAAAAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIA==',
      '"$_contractStrKey"': 'AAAAAQYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYG',
      '"$_muxedStrKey"':
          'AAAAAgECAwQFBgcIAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA=',
      '"$_balanceStrKey"':
          'AAAAAwAAAAAGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBg==',
      '"$_poolStrKey"': 'AAAABAkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJ',
    };

    test('the account, contract, muxed, balance and pool arms', () {
      arms.forEach((String json, String base64) {
        expect(XdrSCAddress.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrSCAddress.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('every arm renders as a bare string, never as a keyed object', () {
      arms.forEach((String json, String _) {
        expect(XdrSCAddress.fromXdrJson(json).toXdrJsonValue(), isA<String>());
      });
    });

    test('a strkey of a kind the union does not declare is refused', () {
      final String seed = StrKey.encodeStellarSecretSeed(Uint8List(32));
      expect(
        () => XdrSCAddress.fromXdrJson('"$seed"'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SEP-0051 §Address Types renders every signer key arm', () {
    final Map<String, String> arms = <String, String>{
      '"$_accountStrKey"': 'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8g',
      '"$_preAuthTxStrKey"': 'AAAAAQECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8g',
      '"$_hashXStrKey"': 'AAAAAgECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8g',
      '"$_signedPayloadStrKey"':
          'AAAAAwECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAAf8AAAA=',
    };

    test('the ed25519, pre-auth, hash-x and signed-payload arms', () {
      arms.forEach((String json, String base64) {
        expect(XdrSignerKey.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrSignerKey.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('the three 32-byte arms differ only by their strkey kind', () {
      // The same key under three version bytes, so an arm that reached for the
      // wrong codec would render one of these as another.
      expect(
        <String>{_accountStrKey, _preAuthTxStrKey, _hashXStrKey}.length,
        3,
      );
      for (final String strKey in <String>[
        _accountStrKey,
        _preAuthTxStrKey,
        _hashXStrKey,
      ]) {
        expect(XdrSignerKey.fromXdrJson('"$strKey"').toXdrJson(), '"$strKey"');
      }
    });
  });

  group('SEP-0051 §Address Types renders a signed payload as a P strkey', () {
    test('a one-byte payload, which the region pads to four', () {
      const String json = '"$_signedPayloadStrKey"';
      expect(XdrSignedPayload.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrSignedPayload.fromXdrJson(json).toBase64EncodedXdrString(),
        'AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyAAAAAB/wAAAA==',
      );
    });

    test('a sixty-four byte payload, the widest the declaration allows', () {
      const String json = '"$_signedPayload64StrKey"';
      expect(XdrSignedPayload.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrSignedPayload.fromXdrJson(json).toBase64EncodedXdrString(),
        'AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyAAAABAAAECAwQFBgcICQoLDA0O'
        'DxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+Pw==',
      );
    });

    test('an empty payload has no rendering, in either direction', () {
      // The declaration is `opaque payload<64>`, and the region an empty
      // payload produces is shorter than any P strkey a reader accepts, so
      // there is nothing to render it as. Both directions refuse rather than
      // one of them emitting a value the other cannot read.
      final XdrSignedPayload empty = XdrSignedPayload(
        XdrUint256(_ed25519),
        XdrDataValue(Uint8List(0)),
      );
      expect(() => empty.toXdrJson(), throwsA(isA<FormatException>()));
      expect(
        () => XdrSignedPayload.fromXdrJson(
          '"PAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSAAAAAAADPWA"',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('a payload longer than the declaration allows is refused', () {
      final XdrSignedPayload wide = XdrSignedPayload(
        XdrUint256(_ed25519),
        XdrDataValue(Uint8List(65)),
      );
      expect(() => wide.toXdrJson(), throwsA(isA<FormatException>()));
    });
  });

  group('SEP-0051 §Address Types renders a balance id as a B strkey', () {
    test('the v0 arm', () {
      const String json = '"$_balanceStrKey"';
      expect(XdrClaimableBalanceID.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrClaimableBalanceID.fromXdrJson(json).toBase64EncodedXdrString(),
        'AAAAAAYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYG',
      );
    });

    test('the payload is the discriminant tag followed by the hash', () {
      final Uint8List payload = StrKey.decodeClaimableBalanceId(_balanceStrKey);
      expect(payload.length, 33);
      expect(payload[0], 0);
      expect(payload.sublist(1), List<int>.filled(32, 6));
    });

    test('a payload of the wrong width is refused', () {
      // Thirty-two bytes carrying the tag and a hash one byte short. The
      // checksum and the version byte are both right, so the width is the only
      // thing that says this is not a balance id.
      final String narrow = StrKey.encodeCheck(
        VersionByte.CLAIMABLE_BALANCE,
        Uint8List.fromList(<int>[0, ...List<int>.filled(31, 6)]),
      );
      expect(
        () => XdrClaimableBalanceID.fromXdrJson('"$narrow"'),
        throwsA(isA<FormatException>()),
      );
    });

    test('a tag the union does not declare is refused', () {
      final String tagged = StrKey.encodeClaimableBalanceId(
        Uint8List.fromList(<int>[7, ...List<int>.filled(32, 6)]),
      );
      expect(
        () => XdrClaimableBalanceID.fromXdrJson('"$tagged"'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('a strkey reader refuses what a strkey reader must', () {
    final Map<String, void Function(String)> readers =
        <String, void Function(String)>{
          'XdrPublicKey': (String s) => XdrPublicKey.fromXdrJson('"$s"'),
          'XdrAccountID': (String s) => XdrAccountID.fromXdrJson('"$s"'),
          'XdrMuxedAccount': (String s) => XdrMuxedAccount.fromXdrJson('"$s"'),
          'XdrSCAddress': (String s) => XdrSCAddress.fromXdrJson('"$s"'),
          'XdrSignerKey': (String s) => XdrSignerKey.fromXdrJson('"$s"'),
        };

    test('a strkey whose checksum does not match its payload', () {
      final String broken = _breakChecksum(_accountStrKey);
      expect(broken, isNot(_accountStrKey));
      readers.forEach((String name, void Function(String) read) {
        expect(
          () => read(broken),
          throwsA(isA<FormatException>()),
          reason: name,
        );
      });
    });

    test('a well-formed strkey of another kind', () {
      readers.forEach((String name, void Function(String) read) {
        if (name == 'XdrSCAddress') {
          // Every kind below is one of this union's arms; its own rejection is
          // covered where the arms are.
          return;
        }
        expect(
          () => read(_contractStrKey),
          throwsA(isA<FormatException>()),
          reason: name,
        );
      });
    });

    test('a well-formed strkey carrying the wrong number of bytes', () {
      final String narrow = StrKey.encodeStellarAccountId(Uint8List(31));
      readers.forEach((String name, void Function(String) read) {
        expect(
          () => read(narrow),
          throwsA(isA<FormatException>()),
          reason: name,
        );
      });
    });

    test('a value that is not a string at all', () {
      readers.forEach((String name, void Function(String) read) {
        expect(
          () => XdrPublicKey.fromXdrJson('123'),
          throwsA(isA<FormatException>()),
          reason: name,
        );
      });
      expect(
        () => XdrSCAddress.fromXdrJson('{"account_id":"$_accountStrKey"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('the ContractID typedef renders as a C strkey at every field site', () {
    test('the contract arm of a contract address', () {
      const String json = '"$_contractStrKey"';
      expect(XdrSCAddress.fromXdrJson(json).toXdrJson(), json);
    });

    test('the contract id of a config upgrade set key', () {
      // The two components are both a 32-byte hash in Dart, and only the type
      // the .x declares tells them apart: one is a strkey and one is hex.
      const String base64 =
          'BgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYCAgICAgICAgICAgICAgICAgIC'
          'AgICAgICAgICAgICAg==';
      const String json =
          '{"contract_id":"$_contractStrKey","content_hash":'
          '"0202020202020202020202020202020202020202020202020202020202020202"}';
      expect(
        XdrConfigUpgradeSetKey.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrConfigUpgradeSetKey.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the optional contract id of a contract event, when present', () {
      const String base64 =
          'AAAAAAAAAAEGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgAAAAEAAAAAAAAA'
          'AAAAAAE=';
      const String json =
          '{"ext":"v0","contract_id":"$_contractStrKey","type":"contract",'
          '"body":{"v0":{"topics":[],"data":"void"}}}';
      expect(
        XdrContractEvent.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrContractEvent.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the optional contract id of a contract event, when absent', () {
      const String base64 = 'AAAAAAAAAAAAAAABAAAAAAAAAAAAAAAB';
      const String json =
          '{"ext":"v0","contract_id":null,"type":"contract",'
          '"body":{"v0":{"topics":[],"data":"void"}}}';
      expect(
        XdrContractEvent.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrContractEvent.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('the PoolID typedef renders as an L strkey at every field site', () {
    test('the pool share arm of a trustline asset', () {
      const String json = '{"pool_share":"$_poolStrKey"}';
      expect(XdrTrustlineAsset.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrTrustlineAsset.fromXdrJson(json).toBase64EncodedXdrString(),
        'AAAAAwkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJ',
      );
    });

    test('the pool id of a liquidity pool entry', () {
      const String base64 =
          'CQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkAAAAAAAAAAAAAAAAAAAAeAAAA'
          'AAAAAAoAAAAAAAAAFAAAAAAAAAAeAAAAAAAAACg=';
      const String json =
          '{"liquidity_pool_id":"$_poolStrKey","body":'
          '{"liquidity_pool_constant_product":{"params":{"asset_a":"native",'
          '"asset_b":"native","fee":30},"reserve_a":"10","reserve_b":"20",'
          '"total_pool_shares":"30","pool_shares_trust_line_count":"40"}}}';
      expect(
        XdrLiquidityPoolEntry.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrLiquidityPoolEntry.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the pool id of the liquidity pool ledger key', () {
      // This arm carries an anonymous struct, so the field is reached through
      // the struct path rather than the arm path.
      const String base64 = 'AAAABQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJ';
      const String json =
          '{"liquidity_pool":{"liquidity_pool_id":"$_poolStrKey"}}';
      expect(XdrLedgerKey.fromBase64EncodedXdrString(base64).toXdrJson(), json);
      expect(XdrLedgerKey.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test('the pool id of a deposit operation', () {
      const String base64 =
          'CQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkAAAAAAAAAAQAAAAAAAAACAAAA'
          'AwAAAAQAAAAFAAAABg==';
      const String json =
          '{"liquidity_pool_id":"$_poolStrKey","max_amount_a":"1",'
          '"max_amount_b":"2","min_price":{"n":3,"d":4},'
          '"max_price":{"n":5,"d":6}}';
      expect(
        XdrLiquidityPoolDepositOp.fromBase64EncodedXdrString(
          base64,
        ).toXdrJson(),
        json,
      );
      expect(
        XdrLiquidityPoolDepositOp.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the pool id of a withdraw operation', () {
      const String base64 =
          'CQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkAAAAAAAAABwAAAAAAAAAIAAAA'
          'AAAAAAk=';
      const String json =
          '{"liquidity_pool_id":"$_poolStrKey","amount":"7","min_amount_a":"8",'
          '"min_amount_b":"9"}';
      expect(
        XdrLiquidityPoolWithdrawOp.fromBase64EncodedXdrString(
          base64,
        ).toXdrJson(),
        json,
      );
      expect(
        XdrLiquidityPoolWithdrawOp.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the pool id of a liquidity claim atom', () {
      const String base64 =
          'CQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkAAAAAAAAAAAAAAAsAAAAAAAAA'
          'AAAAAAw=';
      const String json =
          '{"liquidity_pool_id":"$_poolStrKey","asset_sold":"native",'
          '"amount_sold":"11","asset_bought":"native","amount_bought":"12"}';
      expect(
        XdrClaimLiquidityAtom.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrClaimLiquidityAtom.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the pool id of a sponsorship revocation preimage', () {
      const String base64 =
          'AAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gAAAAAAAAAAUAAAACCQkJ'
          'CQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkAAAAA';
      const String json =
          '{"source_account":"$_accountStrKey","seq_num":"5","op_num":2,'
          '"liquidity_pool_id":"$_poolStrKey","asset":"native"}';
      expect(
        XdrHashIDPreimageRevokeID.fromBase64EncodedXdrString(
          base64,
        ).toXdrJson(),
        json,
      );
      expect(
        XdrHashIDPreimageRevokeID.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the pool id arm of a contract address', () {
      const String json = '"$_poolStrKey"';
      expect(XdrSCAddress.fromXdrJson(json).toXdrJson(), json);
    });
  });

  group('SEP-0051 §Asset Code Types trims and pads by the declared width', () {
    test('a four-byte code drops its trailing NUL bytes', () {
      const String base64 =
          'VVNEAAAAAAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIA==';
      const String json = '{"asset_code":"USD","issuer":"$_accountStrKey"}';
      expect(
        XdrAssetAlphaNum4.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAssetAlphaNum4.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('a twelve-byte code is padded back up to five', () {
      const String base64 =
          'VVMAAAAAAAAAAAAAAAAAAAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8g';
      const String json =
          '{"asset_code":"US\\\\0\\\\0\\\\0","issuer":"$_accountStrKey"}';
      expect(
        XdrAssetAlphaNum12.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAssetAlphaNum12.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('an all-NUL twelve-byte code renders as five escaped NUL bytes', () {
      // Five is the shortest rendering the twelve-byte width takes, so this is
      // an empty code rather than a failure, and it reads back as the twelve
      // NUL bytes it came from.
      const String base64 = 'AAAAAgAAAAAAAAAAAAAAAA==';
      const String json = r'"\\0\\0\\0\\0\\0"';
      expect(
        XdrAllowTrustOpAsset.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      final String reencoded = XdrAllowTrustOpAsset.fromXdrJson(
        json,
      ).toBase64EncodedXdrString();
      expect(reencoded, base64);
    });

    test('an all-NUL four-byte code renders as the empty string', () {
      const String base64 = 'AAAAAQAAAAA=';
      const String json = '""';
      expect(
        XdrAllowTrustOpAsset.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAllowTrustOpAsset.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the asset code union renders as a bare string, never as an arm', () {
      // The union has no key on the wire: the rendered width alone says which
      // arm it is, four characters or fewer for one and five or more for the
      // other.
      for (final String json in <String>[
        '"USD"',
        '"ABCD"',
        '"ABCDE"',
        r'"US\\0\\0\\0"',
      ]) {
        expect(
          XdrAllowTrustOpAsset.fromXdrJson(json).toXdrJsonValue(),
          isA<String>(),
        );
        expect(XdrAllowTrustOpAsset.fromXdrJson(json).toXdrJson(), json);
      }
      expect(
        () => XdrAllowTrustOpAsset.fromXdrJson('{"credit_alphanum4":"USD"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('the arm is chosen at the boundary between the two widths', () {
      expect(
        XdrAllowTrustOpAsset.fromXdrJson('"ABCD"').toBase64EncodedXdrString(),
        'AAAAAUFCQ0Q=',
      );
      expect(
        XdrAllowTrustOpAsset.fromXdrJson('"ABCDE"').toBase64EncodedXdrString(),
        'AAAAAkFCQ0RFAAAAAAAAAA==',
      );
    });

    test('a code wider than twelve bytes is refused', () {
      expect(
        () => XdrAllowTrustOpAsset.fromXdrJson('"ABCDEFGHIJKLM"'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SEP-0051 §Integer Types renders the parts as one decimal string', () {
    test('a 128-bit signed value carries the sign on its high limb', () {
      const Map<String, String> values = <String, String>{
        '"-18446744073709551616"': '//////////8AAAAAAAAAAA==',
        '"-18446744073709551615"': '//////////8AAAAAAAAAAQ==',
        '"170141183460469231731687303715884105727"': 'f////////////////////w==',
        '"-170141183460469231731687303715884105728"':
            'gAAAAAAAAAAAAAAAAAAAAA==',
      };
      values.forEach((String json, String base64) {
        expect(XdrInt128Parts.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrInt128Parts.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('a 128-bit signed value carries no sign on its low limb', () {
      // A high limb of zero and a low limb of every bit set. Reading the low
      // limb as signed would make this zero minus one rather than 2^64 - 1.
      const String json = '"18446744073709551615"';
      expect(XdrInt128Parts.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrInt128Parts.fromXdrJson(json).toBase64EncodedXdrString(),
        'AAAAAAAAAAD//////////w==',
      );
    });

    test('a 128-bit unsigned value uses the whole range', () {
      const Map<String, String> values = <String, String>{
        '"1"': 'AAAAAAAAAAAAAAAAAAAAAQ==',
        '"18446744073709551618"': 'AAAAAAAAAAEAAAAAAAAAAg==',
        '"340282366920938463463374607431768211455"': '/////////////////////w==',
      };
      values.forEach((String json, String base64) {
        expect(XdrUInt128Parts.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrUInt128Parts.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('a 256-bit signed value carries the sign on its highest limb', () {
      const Map<String, String> values = <String, String>{
        '"-6277101735386680763835789423207666416102355444464034512895"':
            '//////////8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE=',
        '"-57896044618658097711785492504343953926634992332820282019728792003'
                '956564819968"':
            'gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      };
      values.forEach((String json, String base64) {
        expect(XdrInt256Parts.fromXdrJson(json).toXdrJson(), json);
        expect(
          XdrInt256Parts.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('a 256-bit signed value carries no sign on its lower limbs', () {
      const String json =
          '"6277101735386680763835789423207666416102355444464034512895"';
      expect(XdrInt256Parts.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrInt256Parts.fromXdrJson(json).toBase64EncodedXdrString(),
        'AAAAAAAAAAD///////////////////////////////8=',
      );
    });

    test('a 256-bit unsigned value uses the whole range', () {
      const String json =
          '"115792089237316195423570985008687907853269984665640564039457584007'
          '913129639935"';
      expect(XdrUInt256Parts.fromXdrJson(json).toXdrJson(), json);
      expect(
        XdrUInt256Parts.fromXdrJson(json).toBase64EncodedXdrString(),
        '//////////////////////////////////////////8=',
      );
    });

    test('a value outside the declared width is refused', () {
      expect(
        () => XdrUInt128Parts.fromXdrJson('"-1"'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => XdrInt128Parts.fromXdrJson(
          '"170141183460469231731687303715884105728"',
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => XdrUInt256Parts.fromXdrJson(
          '"11579208923731619542357098500868790785326998466564056403945758400'
          '7913129639936"',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('the rendering is one string, not an object of limbs', () {
      expect(XdrInt128Parts.fromXdrJson('"1"').toXdrJsonValue(), isA<String>());
      expect(
        () => XdrInt128Parts.fromXdrJson('{"hi":"0","lo":"1"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
