import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/xdr/txrep_helper.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Standard SEP-23 account id for 32 zero bytes.
const String _zeroAccountId =
    'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF';

Uint8List _seq(int length, [int start = 1]) => Uint8List.fromList(
  List<int>.generate(length, (int i) => (start + i) & 0xff),
);

Uint8List _pad(List<int> prefix, int width) {
  final Uint8List out = Uint8List(width);
  out.setAll(0, prefix);
  return out;
}

void main() {
  final Uint8List hash32 = _seq(32, 1);
  const String hash32Hex =
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20';
  final Uint8List hash31 = _seq(31, 1);
  const String hash31Hex =
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
  final Uint8List hash33 = _seq(33, 1);
  const String hash33Hex =
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f2021';

  final XdrAccountID zeroIssuer = XdrAccountID.forAccountId(_zeroAccountId);

  group('XdrLedgerKeyContractCode (Hash = opaque[32])', () {
    test('encodes and decodes 32-byte hash identically in all formats', () {
      final XdrLedgerKeyContractCode key = XdrLedgerKeyContractCode(
        XdrHash(hash32),
      );

      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrLedgerKeyContractCode.encode(out, key);
      expect(out.bytes, hash32);
      final XdrLedgerKeyContractCode decoded = XdrLedgerKeyContractCode.decode(
        XdrDataInputStream(Uint8List.fromList(out.bytes)),
      );
      expect(decoded.hash.hash, hash32);

      const String expectedJson = '{"hash":"$hash32Hex"}';
      expect(key.toXdrJson(), expectedJson);
      expect(
        XdrLedgerKeyContractCode.fromXdrJson(expectedJson).hash.hash,
        hash32,
      );

      final List<String> lines = <String>[];
      key.toTxRep('k', lines);
      expect(lines, <String>['k.hash: $hash32Hex']);
      expect(
        XdrLedgerKeyContractCode.fromTxRep(
          TxRepHelper.parse(lines.join('\n')),
          'k',
        ).hash.hash,
        hash32,
      );
    });

    for (final (String label, Uint8List bad, String badHex)
        in <(String, Uint8List, String)>[
          ('31-byte', hash31, hash31Hex),
          ('33-byte', hash33, hash33Hex),
        ]) {
      test('rejects $label hash on binary, XDR-JSON, and TxRep', () {
        final XdrLedgerKeyContractCode key = XdrLedgerKeyContractCode(
          XdrHash(bad),
        );

        final XdrDataOutputStream out = XdrDataOutputStream();
        expect(
          () => XdrLedgerKeyContractCode.encode(out, key),
          throwsA(isA<RangeError>()),
        );
        expect(out.bytes, isEmpty);

        expect(() => key.toXdrJson(), throwsA(isA<FormatException>()));
        expect(
          () => XdrLedgerKeyContractCode.fromXdrJson('{"hash":"$badHex"}'),
          throwsA(isA<FormatException>()),
        );

        final List<String> lines = <String>[];
        expect(
          () => key.toTxRep('k', lines),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('k.hash must be 32 bytes, ${bad.length} given'),
            ),
          ),
        );
        expect(lines, isEmpty);

        expect(
          () => XdrLedgerKeyContractCode.fromTxRep(<String, String>{
            'k.hash': badHex,
          }, 'k'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('k.hash must be 32 bytes, ${bad.length} given'),
            ),
          ),
        );
      });
    }

    test('rejects TxRep 0 for 32-byte hash', () {
      expect(
        () => XdrLedgerKeyContractCode.fromTxRep(<String, String>{
          'k.hash': '0',
        }, 'k'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('k.hash must be 32 bytes, 0 given'),
          ),
        ),
      );
    });
  });

  group('XdrDecoratedSignature (SignatureHint = opaque[4])', () {
    final Uint8List hint4 = Uint8List.fromList(<int>[0xaa, 0xbb, 0xcc, 0xdd]);
    final Uint8List sig2 = Uint8List.fromList(<int>[0x01, 0x02]);

    test('encodes and decodes 4-byte hint identically in all formats', () {
      final XdrDecoratedSignature decorated = XdrDecoratedSignature(
        XdrSignatureHint(hint4),
        XdrSignature(sig2),
      );

      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrDecoratedSignature.encode(out, decorated);
      expect(out.bytes, <int>[
        0xaa,
        0xbb,
        0xcc,
        0xdd,
        0x00,
        0x00,
        0x00,
        0x02,
        0x01,
        0x02,
        0x00,
        0x00,
      ]);

      const String expectedJson = '{"hint":"aabbccdd","signature":"0102"}';
      expect(decorated.toXdrJson(), expectedJson);
      expect(
        XdrDecoratedSignature.fromXdrJson(expectedJson).hint.signatureHint,
        hint4,
      );

      final List<String> lines = <String>[];
      decorated.toTxRep('s', lines);
      expect(lines, <String>['s.hint: aabbccdd', 's.signature: 0102']);
      expect(
        XdrDecoratedSignature.fromTxRep(
          TxRepHelper.parse(lines.join('\n')),
          's',
        ).hint.signatureHint,
        hint4,
      );
    });

    for (final (String label, Uint8List bad, String badHex)
        in <(String, Uint8List, String)>[
          ('3-byte', Uint8List.fromList(<int>[0xaa, 0xbb, 0xcc]), 'aabbcc'),
          (
            '5-byte',
            Uint8List.fromList(<int>[0xaa, 0xbb, 0xcc, 0xdd, 0xee]),
            'aabbccddee',
          ),
        ]) {
      test('rejects $label hint on binary, XDR-JSON, and TxRep', () {
        final XdrDecoratedSignature decorated = XdrDecoratedSignature(
          XdrSignatureHint(bad),
          XdrSignature(sig2),
        );

        final XdrDataOutputStream out = XdrDataOutputStream();
        expect(
          () => XdrDecoratedSignature.encode(out, decorated),
          throwsA(isA<RangeError>()),
        );
        expect(out.bytes, isEmpty);

        expect(() => decorated.toXdrJson(), throwsA(isA<FormatException>()));
        expect(
          () => XdrDecoratedSignature.fromXdrJson(
            '{"hint":"$badHex","signature":"0102"}',
          ),
          throwsA(isA<FormatException>()),
        );

        final List<String> lines = <String>[];
        expect(
          () => decorated.toTxRep('s', lines),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('s.hint must be 4 bytes, ${bad.length} given'),
            ),
          ),
        );
        expect(lines, isEmpty);

        expect(
          () => XdrDecoratedSignature.fromTxRep(<String, String>{
            's.hint': badHex,
            's.signature': '0102',
          }, 's'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('s.hint must be 4 bytes, ${bad.length} given'),
            ),
          ),
        );
      });
    }

    test('rejects TxRep 0 for 4-byte signature hint', () {
      expect(
        () => XdrSignatureHint.fromTxRep(<String, String>{'h': '0'}, 'h'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('h must be 4 bytes, 0 given'),
          ),
        ),
      );
    });
  });

  group('XdrShortHashSeed (inline opaque[16] struct)', () {
    final Uint8List seed16 = _seq(16, 0x10);
    const String seed16Hex = '101112131415161718191a1b1c1d1e1f';

    test('encodes and decodes 16-byte seed in binary and XDR-JSON', () {
      final XdrShortHashSeed seed = XdrShortHashSeed(seed16);

      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrShortHashSeed.encode(out, seed);
      expect(out.bytes, seed16);
      expect(
        XdrShortHashSeed.decode(
          XdrDataInputStream(Uint8List.fromList(out.bytes)),
        ).seed,
        seed16,
      );

      const String expectedJson = '{"seed":"$seed16Hex"}';
      expect(seed.toXdrJson(), expectedJson);
      expect(XdrShortHashSeed.fromXdrJson(expectedJson).seed, seed16);
    });

    for (final (String label, Uint8List bad, String badHex)
        in <(String, Uint8List, String)>[
          ('15-byte', _seq(15, 0x10), '101112131415161718191a1b1c1d1e'),
          ('17-byte', _seq(17, 0x10), '101112131415161718191a1b1c1d1e1f20'),
        ]) {
      test('rejects $label seed on binary and XDR-JSON', () {
        final XdrShortHashSeed seed = XdrShortHashSeed(bad);

        final XdrDataOutputStream out = XdrDataOutputStream();
        expect(
          () => XdrShortHashSeed.encode(out, seed),
          throwsA(isA<RangeError>()),
        );
        expect(out.bytes, isEmpty);

        expect(() => seed.toXdrJson(), throwsA(isA<FormatException>()));
        expect(
          () => XdrShortHashSeed.fromXdrJson('{"seed":"$badHex"}'),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });

  group('XdrPeerAddressIp (inline opaque[4] and opaque[16] union)', () {
    final Uint8List ipv4 = Uint8List.fromList(<int>[127, 0, 0, 1]);
    final Uint8List ipv6 = _seq(16, 0);

    test('encodes and decodes valid IPv4 and IPv6 in binary and XDR-JSON', () {
      final XdrPeerAddressIp v4 = XdrPeerAddressIp(XdrIPAddrType.IPv4)
        ..ipv4 = ipv4;
      final XdrDataOutputStream out4 = XdrDataOutputStream();
      XdrPeerAddressIp.encode(out4, v4);
      expect(out4.bytes, <int>[0, 0, 0, 0, 127, 0, 0, 1]);
      expect(v4.toXdrJson(), '{"i_pv4":"7f000001"}');
      expect(XdrPeerAddressIp.fromXdrJson('{"i_pv4":"7f000001"}').ipv4, ipv4);

      final XdrPeerAddressIp v6 = XdrPeerAddressIp(XdrIPAddrType.IPv6)
        ..ipv6 = ipv6;
      final XdrDataOutputStream out6 = XdrDataOutputStream();
      XdrPeerAddressIp.encode(out6, v6);
      expect(out6.bytes, <int>[0, 0, 0, 1, ...ipv6]);
      expect(v6.toXdrJson(), '{"i_pv6":"000102030405060708090a0b0c0d0e0f"}');
      expect(
        XdrPeerAddressIp.fromXdrJson(
          '{"i_pv6":"000102030405060708090a0b0c0d0e0f"}',
        ).ipv6,
        ipv6,
      );
    });

    test('rejects wrong-length IPv4 and IPv6 on binary and XDR-JSON', () {
      for (final Uint8List bad in <Uint8List>[_seq(3), _seq(5)]) {
        final XdrPeerAddressIp v4 = XdrPeerAddressIp(XdrIPAddrType.IPv4)
          ..ipv4 = bad;
        final XdrDataOutputStream out = XdrDataOutputStream();
        expect(
          () => XdrPeerAddressIp.encode(out, v4),
          throwsA(isA<RangeError>()),
        );
        expect(out.bytes.length, 4);
        expect(() => v4.toXdrJson(), throwsA(isA<FormatException>()));
      }

      for (final Uint8List bad in <Uint8List>[_seq(15), _seq(17)]) {
        final XdrPeerAddressIp v6 = XdrPeerAddressIp(XdrIPAddrType.IPv6)
          ..ipv6 = bad;
        final XdrDataOutputStream out = XdrDataOutputStream();
        expect(
          () => XdrPeerAddressIp.encode(out, v6),
          throwsA(isA<RangeError>()),
        );
        expect(out.bytes.length, 4);
        expect(() => v6.toXdrJson(), throwsA(isA<FormatException>()));
      }
    });
  });

  group('XdrMemo union arm (Hash = opaque[32])', () {
    test('encodes and decodes valid hash arm in all formats', () {
      final XdrMemo memo = XdrMemo(XdrMemoType.MEMO_HASH)
        ..hash = XdrHash(hash32);

      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrMemo.encode(out, memo);
      expect(out.bytes, <int>[0, 0, 0, 3, ...hash32]);

      const String expectedJson = '{"hash":"$hash32Hex"}';
      expect(memo.toXdrJson(), expectedJson);
      expect(XdrMemo.fromXdrJson(expectedJson).hash!.hash, hash32);

      final List<String> lines = <String>[];
      memo.toTxRep('m', lines);
      expect(lines, <String>['m.type: MEMO_HASH', 'm.hash: $hash32Hex']);
      expect(
        XdrMemo.fromTxRep(TxRepHelper.parse(lines.join('\n')), 'm').hash!.hash,
        hash32,
      );
    });

    test('rejects 31-byte and 33-byte hash arm in all formats', () {
      for (final (Uint8List bad, String badHex) in <(Uint8List, String)>[
        (hash31, hash31Hex),
        (hash33, hash33Hex),
      ]) {
        final XdrMemo memo = XdrMemo(XdrMemoType.MEMO_HASH)
          ..hash = XdrHash(bad);
        expect(
          () => XdrMemo.encode(XdrDataOutputStream(), memo),
          throwsA(isA<RangeError>()),
        );
        expect(() => memo.toXdrJson(), throwsA(isA<FormatException>()));
        expect(
          () => XdrMemo.fromXdrJson('{"hash":"$badHex"}'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => memo.toTxRep('m', <String>[]),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('m.hash must be 32 bytes, ${bad.length} given'),
            ),
          ),
        );
        expect(
          () => XdrMemo.fromTxRep(<String, String>{
            'm.type': 'MEMO_HASH',
            'm.hash': badHex,
          }, 'm'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('m.hash must be 32 bytes, ${bad.length} given'),
            ),
          ),
        );
      }
      expect(
        () => XdrMemo.fromTxRep(<String, String>{
          'm.type': 'MEMO_HASH',
          'm.hash': '0',
        }, 'm'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('m.hash must be 32 bytes, 0 given'),
          ),
        ),
      );
    });
  });

  group('Array elements holding fixed-length opaque', () {
    test('XdrTxAdvertVector accepts 32-byte and rejects 31/33-byte hashes', () {
      final XdrTxAdvertVector valid = XdrTxAdvertVector(<XdrHash>[
        XdrHash(hash32),
      ]);
      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrTxAdvertVector.encode(out, valid);
      expect(out.bytes, <int>[0, 0, 0, 1, ...hash32]);
      expect(valid.toXdrJson(), '["$hash32Hex"]');

      for (final (Uint8List bad, String badHex) in <(Uint8List, String)>[
        (hash31, hash31Hex),
        (hash33, hash33Hex),
      ]) {
        final XdrTxAdvertVector invalid = XdrTxAdvertVector(<XdrHash>[
          XdrHash(bad),
        ]);
        expect(
          () => XdrTxAdvertVector.encode(XdrDataOutputStream(), invalid),
          throwsA(isA<RangeError>()),
        );
        expect(() => invalid.toXdrJson(), throwsA(isA<FormatException>()));
        expect(
          () => XdrTxAdvertVector.fromXdrJson('["$badHex"]'),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('XdrLedgerFootprint rejects wrong-length hash in readOnly element', () {
      final XdrLedgerFootprint valid = XdrLedgerFootprint(<XdrLedgerKey>[
        XdrLedgerKey.forContractCode(hash32),
      ], <XdrLedgerKey>[]);
      final List<String> validLines = <String>[];
      valid.toTxRep('fp', validLines);
      expect(validLines, <String>[
        'fp.readOnly.len: 1',
        'fp.readOnly[0].type: CONTRACT_CODE',
        'fp.readOnly[0].contractCode.hash: $hash32Hex',
        'fp.readWrite.len: 0',
      ]);

      for (final (Uint8List bad, String badHex) in <(Uint8List, String)>[
        (hash31, hash31Hex),
        (hash33, hash33Hex),
      ]) {
        final XdrLedgerFootprint invalid = XdrLedgerFootprint(<XdrLedgerKey>[
          XdrLedgerKey.forContractCode(bad),
        ], <XdrLedgerKey>[]);
        expect(
          () => XdrLedgerFootprint.encode(XdrDataOutputStream(), invalid),
          throwsA(isA<RangeError>()),
        );
        expect(() => invalid.toXdrJson(), throwsA(isA<FormatException>()));
        expect(
          () => invalid.toTxRep('fp', <String>[]),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains(
                'fp.readOnly[0].contractCode.hash must be 32 bytes, ${bad.length} given',
              ),
            ),
          ),
        );
        expect(
          () => XdrLedgerFootprint.fromTxRep(<String, String>{
            'fp.readOnly.len': '1',
            'fp.readOnly[0].type': 'CONTRACT_CODE',
            'fp.readOnly[0].contractCode.hash': badHex,
            'fp.readWrite.len': '0',
          }, 'fp'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains(
                'fp.readOnly[0].contractCode.hash must be 32 bytes, ${bad.length} given',
              ),
            ),
          ),
        );
      }
    });
  });

  group('Pool share asset in TxRepHelper', () {
    test('formats and parses 32-byte pool id and rejects 31/33-byte ids', () {
      final XdrTrustlineAsset valid = XdrTrustlineAsset(
        XdrAssetType.ASSET_TYPE_POOL_SHARE,
      )..liquidityPoolID = XdrHash(hash32);
      expect(TxRepHelper.formatTrustlineAsset(valid), hash32Hex);
      expect(
        TxRepHelper.parseTrustlineAsset(hash32Hex).liquidityPoolID!.hash,
        hash32,
      );

      for (final (Uint8List bad, String badHex) in <(Uint8List, String)>[
        (hash31, hash31Hex),
        (hash33, hash33Hex),
      ]) {
        final XdrTrustlineAsset invalid = XdrTrustlineAsset(
          XdrAssetType.ASSET_TYPE_POOL_SHARE,
        )..liquidityPoolID = XdrHash(bad);
        expect(
          () => TxRepHelper.formatTrustlineAsset(invalid),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('liquidityPoolID must be 32 bytes, ${bad.length} given'),
            ),
          ),
        );
        expect(
          () => TxRepHelper.parseTrustlineAsset(badHex),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('invalid trustline asset: $badHex'),
            ),
          ),
        );
      }
    });
  });

  group('AssetCode4 and AssetCode12 in binary, XDR-JSON, and TxRep', () {
    final Uint8List abc3 = Uint8List.fromList(<int>[0x41, 0x42, 0x43]);
    final Uint8List abc4 = _pad(<int>[0x41, 0x42, 0x43], 4);
    final Uint8List abc12 = _pad(<int>[0x41, 0x42, 0x43], 12);
    final Uint8List issuerBytes = Uint8List(36);

    test('XdrAssetAlphaNum4 encodes and decodes 4-byte code identically', () {
      final Uint8List expectedBinary = Uint8List.fromList(<int>[
        ...abc4,
        ...issuerBytes,
      ]);
      const String expectedJson =
          '{"asset_code":"ABC","issuer":"$_zeroAccountId"}';
      final List<String> expectedTxRep = <String>[
        'a.assetCode: 41424300',
        'a.issuer: $_zeroAccountId',
      ];

      final XdrAssetAlphaNum4 asset = XdrAssetAlphaNum4(abc4, zeroIssuer);
      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrAssetAlphaNum4.encode(out, asset);
      expect(out.bytes, expectedBinary);
      expect(asset.toXdrJson(), expectedJson);
      expect(XdrAssetAlphaNum4.fromXdrJson(expectedJson).assetCode, abc4);
      final List<String> lines = <String>[];
      asset.toTxRep('a', lines);
      expect(lines, expectedTxRep);
      expect(
        XdrAssetAlphaNum4.fromTxRep(
          TxRepHelper.parse(lines.join('\n')),
          'a',
        ).assetCode,
        abc4,
      );
    });

    test('XdrAssetAlphaNum4 pads 0..3 bytes and rejects 5 bytes', () {
      final Uint8List expectedBinary = Uint8List.fromList(<int>[
        ...abc4,
        ...issuerBytes,
      ]);
      const String expectedJson =
          '{"asset_code":"ABC","issuer":"$_zeroAccountId"}';
      final List<String> expectedTxRep = <String>[
        'a.assetCode: 41424300',
        'a.issuer: $_zeroAccountId',
      ];

      final XdrAssetAlphaNum4 short = XdrAssetAlphaNum4(abc3, zeroIssuer);
      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrAssetAlphaNum4.encode(out, short);
      expect(out.bytes, expectedBinary);
      expect(short.toXdrJson(), expectedJson);
      final List<String> lines = <String>[];
      short.toTxRep('a', lines);
      expect(lines, expectedTxRep);

      // Empty 0-byte code pads to four NUL bytes on write.
      final XdrAssetAlphaNum4 empty = XdrAssetAlphaNum4(
        Uint8List(0),
        zeroIssuer,
      );
      final XdrDataOutputStream emptyOut = XdrDataOutputStream();
      XdrAssetAlphaNum4.encode(emptyOut, empty);
      expect(emptyOut.bytes, Uint8List(40));
      expect(empty.toXdrJson(), '{"asset_code":"","issuer":"$_zeroAccountId"}');
      final List<String> emptyLines = <String>[];
      empty.toTxRep('a', emptyLines);
      expect(emptyLines, <String>[
        'a.assetCode: 00000000',
        'a.issuer: $_zeroAccountId',
      ]);

      // TxRep reader keeps present behavior for 0..4 bytes, including '0'.
      expect(
        XdrAssetAlphaNum4.fromTxRep(<String, String>{
          'a.assetCode': '0',
          'a.issuer': _zeroAccountId,
        }, 'a').assetCode,
        Uint8List(0),
      );
      expect(
        XdrAssetAlphaNum4.fromTxRep(<String, String>{
          'a.assetCode': '414243',
          'a.issuer': _zeroAccountId,
        }, 'a').assetCode,
        abc3,
      );

      // 5 bytes rejected across all formats.
      final XdrAssetAlphaNum4 tooLong = XdrAssetAlphaNum4(
        Uint8List.fromList(<int>[0x41, 0x42, 0x43, 0x44, 0x45]),
        zeroIssuer,
      );
      final XdrDataOutputStream badOut = XdrDataOutputStream();
      expect(
        () => XdrAssetAlphaNum4.encode(badOut, tooLong),
        throwsA(isA<RangeError>()),
      );
      expect(badOut.bytes, isEmpty);
      expect(() => tooLong.toXdrJson(), throwsA(isA<FormatException>()));
      expect(
        () => XdrAssetAlphaNum4.fromXdrJson(
          '{"asset_code":"ABCDE","issuer":"$_zeroAccountId"}',
        ),
        throwsA(isA<FormatException>()),
      );
      final List<String> badLines = <String>[];
      expect(
        () => tooLong.toTxRep('a', badLines),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );
      expect(badLines, isEmpty);
      expect(
        () => XdrAssetAlphaNum4.fromTxRep(<String, String>{
          'a.assetCode': '4142434445',
          'a.issuer': _zeroAccountId,
        }, 'a'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );
    });

    test('XdrAssetAlphaNum12 encodes and decodes 12-byte code identically', () {
      final Uint8List expectedBinary = Uint8List.fromList(<int>[
        ...abc12,
        ...issuerBytes,
      ]);
      const String expectedJson =
          r'{"asset_code":"ABC\\0\\0","issuer":"'
          '$_zeroAccountId'
          '"}';
      final List<String> expectedTxRep = <String>[
        'a.assetCode: 414243000000000000000000',
        'a.issuer: $_zeroAccountId',
      ];

      final XdrAssetAlphaNum12 asset = XdrAssetAlphaNum12(abc12, zeroIssuer);
      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrAssetAlphaNum12.encode(out, asset);
      expect(out.bytes, expectedBinary);
      expect(asset.toXdrJson(), expectedJson);
      expect(XdrAssetAlphaNum12.fromXdrJson(expectedJson).assetCode, abc12);
      final List<String> lines = <String>[];
      asset.toTxRep('a', lines);
      expect(lines, expectedTxRep);
      expect(
        XdrAssetAlphaNum12.fromTxRep(
          TxRepHelper.parse(lines.join('\n')),
          'a',
        ).assetCode,
        abc12,
      );
    });

    test('XdrAssetAlphaNum12 pads 0..11 bytes and rejects 13 bytes', () {
      final Uint8List expectedBinary = Uint8List.fromList(<int>[
        ...abc12,
        ...issuerBytes,
      ]);
      const String expectedJson =
          r'{"asset_code":"ABC\\0\\0","issuer":"'
          '$_zeroAccountId'
          '"}';
      final List<String> expectedTxRep = <String>[
        'a.assetCode: 414243000000000000000000',
        'a.issuer: $_zeroAccountId',
      ];

      final XdrAssetAlphaNum12 short = XdrAssetAlphaNum12(abc3, zeroIssuer);
      final XdrDataOutputStream out = XdrDataOutputStream();
      XdrAssetAlphaNum12.encode(out, short);
      expect(out.bytes, expectedBinary);
      expect(short.toXdrJson(), expectedJson);
      final List<String> lines = <String>[];
      short.toTxRep('a', lines);
      expect(lines, expectedTxRep);

      // Empty 0-byte code pads to twelve NUL bytes (five escaped NULs in JSON).
      final XdrAssetAlphaNum12 empty = XdrAssetAlphaNum12(
        Uint8List(0),
        zeroIssuer,
      );
      final XdrDataOutputStream emptyOut = XdrDataOutputStream();
      XdrAssetAlphaNum12.encode(emptyOut, empty);
      expect(emptyOut.bytes, Uint8List(48));
      expect(
        empty.toXdrJson(),
        r'{"asset_code":"\\0\\0\\0\\0\\0","issuer":"'
        '$_zeroAccountId'
        '"}',
      );
      final List<String> emptyLines = <String>[];
      empty.toTxRep('a', emptyLines);
      expect(emptyLines, <String>[
        'a.assetCode: 000000000000000000000000',
        'a.issuer: $_zeroAccountId',
      ]);

      // TxRep reader keeps present behavior for 0..12 bytes, including '0'.
      expect(
        XdrAssetAlphaNum12.fromTxRep(<String, String>{
          'a.assetCode': '0',
          'a.issuer': _zeroAccountId,
        }, 'a').assetCode,
        Uint8List(0),
      );
      expect(
        XdrAssetAlphaNum12.fromTxRep(<String, String>{
          'a.assetCode': '414243',
          'a.issuer': _zeroAccountId,
        }, 'a').assetCode,
        abc3,
      );

      // 13 bytes rejected across all formats.
      final XdrAssetAlphaNum12 tooLong = XdrAssetAlphaNum12(
        _seq(13, 0x41),
        zeroIssuer,
      );
      final XdrDataOutputStream badOut = XdrDataOutputStream();
      expect(
        () => XdrAssetAlphaNum12.encode(badOut, tooLong),
        throwsA(isA<RangeError>()),
      );
      expect(badOut.bytes, isEmpty);
      expect(() => tooLong.toXdrJson(), throwsA(isA<FormatException>()));
      expect(
        () => XdrAssetAlphaNum12.fromXdrJson(
          '{"asset_code":"ABCDEFGHIJKLM","issuer":"$_zeroAccountId"}',
        ),
        throwsA(isA<FormatException>()),
      );
      final List<String> badLines = <String>[];
      expect(
        () => tooLong.toTxRep('a', badLines),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );
      expect(badLines, isEmpty);
      expect(
        () => XdrAssetAlphaNum12.fromTxRep(<String, String>{
          'a.assetCode': '4142434445464748494a4b4c4d',
          'a.issuer': _zeroAccountId,
        }, 'a'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );
    });

    test('XdrAllowTrustOpAsset encodes and decodes valid 4/12-byte codes', () {
      final XdrAllowTrustOpAsset a4 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      )..assetCode4 = abc4;
      final XdrDataOutputStream out4 = XdrDataOutputStream();
      XdrAllowTrustOpAsset.encode(out4, a4);
      expect(out4.bytes, <int>[0, 0, 0, 1, ...abc4]);
      expect(a4.toXdrJson(), '"ABC"');
      final List<String> lines4 = <String>[];
      a4.toTxRep('a', lines4);
      expect(lines4, <String>[
        'a.type: ASSET_TYPE_CREDIT_ALPHANUM4',
        'a.assetCode4: 41424300',
      ]);

      final XdrAllowTrustOpAsset a12 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      )..assetCode12 = abc12;
      final XdrDataOutputStream out12 = XdrDataOutputStream();
      XdrAllowTrustOpAsset.encode(out12, a12);
      expect(out12.bytes, <int>[0, 0, 0, 2, ...abc12]);
      expect(a12.toXdrJson(), r'"ABC\\0\\0"');
      final List<String> lines12 = <String>[];
      a12.toTxRep('a', lines12);
      expect(lines12, <String>[
        'a.type: ASSET_TYPE_CREDIT_ALPHANUM12',
        'a.assetCode12: 414243000000000000000000',
      ]);
    });

    test('XdrAllowTrustOpAsset pads short codes and rejects >N bytes', () {
      final XdrAllowTrustOpAsset a4 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      )..assetCode4 = abc3;
      final XdrDataOutputStream out4 = XdrDataOutputStream();
      XdrAllowTrustOpAsset.encode(out4, a4);
      expect(out4.bytes, <int>[0, 0, 0, 1, ...abc4]);
      expect(a4.toXdrJson(), '"ABC"');
      final List<String> lines4 = <String>[];
      a4.toTxRep('a', lines4);
      expect(lines4, <String>[
        'a.type: ASSET_TYPE_CREDIT_ALPHANUM4',
        'a.assetCode4: 41424300',
      ]);

      final XdrAllowTrustOpAsset a12 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      )..assetCode12 = abc3;
      final XdrDataOutputStream out12 = XdrDataOutputStream();
      XdrAllowTrustOpAsset.encode(out12, a12);
      expect(out12.bytes, <int>[0, 0, 0, 2, ...abc12]);
      expect(a12.toXdrJson(), r'"ABC\\0\\0"');
      final List<String> lines12 = <String>[];
      a12.toTxRep('a', lines12);
      expect(lines12, <String>[
        'a.type: ASSET_TYPE_CREDIT_ALPHANUM12',
        'a.assetCode12: 414243000000000000000000',
      ]);

      // TxRep reader keeps '0' as empty bytes and rejects >N bytes.
      expect(
        XdrAllowTrustOpAsset.fromTxRep(<String, String>{
          'a.type': 'ASSET_TYPE_CREDIT_ALPHANUM4',
          'a.assetCode4': '0',
        }, 'a').assetCode4,
        Uint8List(0),
      );
      expect(
        XdrAllowTrustOpAsset.fromTxRep(<String, String>{
          'a.type': 'ASSET_TYPE_CREDIT_ALPHANUM12',
          'a.assetCode12': '0',
        }, 'a').assetCode12,
        Uint8List(0),
      );

      final XdrAllowTrustOpAsset bad4 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      )..assetCode4 = _seq(5, 0x41);
      expect(
        () => XdrAllowTrustOpAsset.encode(XdrDataOutputStream(), bad4),
        throwsA(isA<RangeError>()),
      );
      expect(() => bad4.toXdrJson(), throwsA(isA<FormatException>()));
      expect(
        () => bad4.toTxRep('a', <String>[]),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode4 has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );
      expect(
        () => XdrAllowTrustOpAsset.fromTxRep(<String, String>{
          'a.type': 'ASSET_TYPE_CREDIT_ALPHANUM4',
          'a.assetCode4': '4142434445',
        }, 'a'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode4 has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );

      final XdrAllowTrustOpAsset bad12 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      )..assetCode12 = _seq(13, 0x41);
      expect(
        () => XdrAllowTrustOpAsset.encode(XdrDataOutputStream(), bad12),
        throwsA(isA<RangeError>()),
      );
      expect(() => bad12.toXdrJson(), throwsA(isA<FormatException>()));
      expect(
        () => bad12.toTxRep('a', <String>[]),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode12 has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );
      expect(
        () => XdrAllowTrustOpAsset.fromTxRep(<String, String>{
          'a.type': 'ASSET_TYPE_CREDIT_ALPHANUM12',
          'a.assetCode12': '4142434445464748494a4b4c4d',
        }, 'a'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'a.assetCode12 has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );
    });

    test('TxRepHelper asset formatters reject codes longer than N bytes', () {
      final XdrAsset badAsset4 = XdrAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      )..alphaNum4 = XdrAssetAlphaNum4(_seq(5, 0x41), zeroIssuer);
      final XdrAsset badAsset12 = XdrAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      )..alphaNum12 = XdrAssetAlphaNum12(_seq(13, 0x41), zeroIssuer);
      expect(
        () => TxRepHelper.formatAsset(badAsset4),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );
      expect(
        () => TxRepHelper.formatAsset(badAsset12),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );

      final XdrChangeTrustAsset badCt4 = XdrChangeTrustAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      )..alphaNum4 = XdrAssetAlphaNum4(_seq(5, 0x41), zeroIssuer);
      final XdrChangeTrustAsset badCt12 = XdrChangeTrustAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      )..alphaNum12 = XdrAssetAlphaNum12(_seq(13, 0x41), zeroIssuer);
      expect(
        () => TxRepHelper.formatChangeTrustAsset(badCt4),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );
      expect(
        () => TxRepHelper.formatChangeTrustAsset(badCt12),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );

      final XdrTrustlineAsset badTl4 = XdrTrustlineAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      )..alphaNum4 = XdrAssetAlphaNum4(_seq(5, 0x41), zeroIssuer);
      final XdrTrustlineAsset badTl12 = XdrTrustlineAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      )..alphaNum12 = XdrAssetAlphaNum12(_seq(13, 0x41), zeroIssuer);
      expect(
        () => TxRepHelper.formatTrustlineAsset(badTl4),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );
      expect(
        () => TxRepHelper.formatTrustlineAsset(badTl12),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );

      final XdrAllowTrustOpAsset badAt4 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4,
      )..assetCode4 = _seq(5, 0x41);
      final XdrAllowTrustOpAsset badAt12 = XdrAllowTrustOpAsset(
        XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12,
      )..assetCode12 = _seq(13, 0x41);
      expect(
        () => TxRepHelper.formatAllowTrustAsset(badAt4),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode4 has length 5, more than the declared maximum of 4',
            ),
          ),
        ),
      );
      expect(
        () => TxRepHelper.formatAllowTrustAsset(badAt12),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'assetCode12 has length 13, more than the declared maximum of 12',
            ),
          ),
        ),
      );
    });

    test(
      'TxRepHelper asset parsers choose asset type by UTF-8 byte length',
      () {
        // 2-char, 4 UTF-8 bytes -> ALPHANUM4.
        const String fourByteUtf8 = '\u00e9\u00e9';
        final Uint8List expectedFourBytes = Uint8List.fromList(<int>[
          0xc3,
          0xa9,
          0xc3,
          0xa9,
        ]);

        // 3-char, 6 UTF-8 bytes -> ALPHANUM12 (not ALPHANUM4).
        const String sixByteUtf8 = '\u00e9\u00e9\u00e9';
        final Uint8List expectedTwelveBytes = _pad(<int>[
          0xc3,
          0xa9,
          0xc3,
          0xa9,
          0xc3,
          0xa9,
        ], 12);

        // 7-char, 14 UTF-8 bytes -> throws (exceeds 12 UTF-8 bytes).
        const String fourteenByteUtf8 =
            '\u00e9\u00e9\u00e9\u00e9\u00e9\u00e9\u00e9';

        final XdrAsset a4 = TxRepHelper.parseAsset(
          '$fourByteUtf8:$_zeroAccountId',
        );
        expect(a4.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
        expect(a4.alphaNum4!.assetCode, expectedFourBytes);

        final XdrAsset a12 = TxRepHelper.parseAsset(
          '$sixByteUtf8:$_zeroAccountId',
        );
        expect(a12.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
        expect(a12.alphaNum12!.assetCode, expectedTwelveBytes);
        expect(
          () => TxRepHelper.parseAsset('$fourteenByteUtf8:$_zeroAccountId'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('asset code too long: $fourteenByteUtf8'),
            ),
          ),
        );

        final XdrChangeTrustAsset ct12 = TxRepHelper.parseChangeTrustAsset(
          '$sixByteUtf8:$_zeroAccountId',
        );
        expect(ct12.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
        expect(ct12.alphaNum12!.assetCode, expectedTwelveBytes);
        expect(
          () => TxRepHelper.parseChangeTrustAsset(
            '$fourteenByteUtf8:$_zeroAccountId',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('asset code too long: $fourteenByteUtf8'),
            ),
          ),
        );

        final XdrTrustlineAsset tl12 = TxRepHelper.parseTrustlineAsset(
          '$sixByteUtf8:$_zeroAccountId',
        );
        expect(tl12.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
        expect(tl12.alphaNum12!.assetCode, expectedTwelveBytes);
        expect(
          () => TxRepHelper.parseTrustlineAsset(
            '$fourteenByteUtf8:$_zeroAccountId',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('asset code too long: $fourteenByteUtf8'),
            ),
          ),
        );

        final XdrAllowTrustOpAsset at12 = TxRepHelper.parseAllowTrustAsset(
          sixByteUtf8,
        );
        expect(at12.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
        expect(at12.assetCode12, expectedTwelveBytes);
        expect(
          () => TxRepHelper.parseAllowTrustAsset(fourteenByteUtf8),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('asset code too long: $fourteenByteUtf8'),
            ),
          ),
        );
      },
    );
  });
}
