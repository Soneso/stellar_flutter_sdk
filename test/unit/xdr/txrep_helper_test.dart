import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:stellar_flutter_sdk/src/xdr/txrep_helper.dart';

void main() {
  // ---------------------------------------------------------------------------
  // parse()
  // ---------------------------------------------------------------------------
  group('TxRepHelper.parse', () {
    test('parses simple key-value lines', () {
      var map = TxRepHelper.parse('tx.fee: 100\ntx.memo: none');
      expect(map['tx.fee'], '100');
      expect(map['tx.memo'], 'none');
    });

    test('handles CRLF line endings', () {
      var map = TxRepHelper.parse('tx.fee: 100\r\ntx.memo: none\r\n');
      expect(map['tx.fee'], '100');
      expect(map['tx.memo'], 'none');
    });

    test('skips blank lines', () {
      var map = TxRepHelper.parse('tx.fee: 100\n\n\ntx.memo: none');
      expect(map.length, 2);
    });

    test('skips comment-only lines (leading colon)', () {
      var map = TxRepHelper.parse(': this is a comment\ntx.fee: 100');
      expect(map.length, 1);
      expect(map['tx.fee'], '100');
    });

    test('skips lines with no colon', () {
      var map = TxRepHelper.parse('no colon here\ntx.fee: 100');
      expect(map.length, 1);
    });

    test('splits on first colon only', () {
      var map = TxRepHelper.parse('tx.asset: USD:GISSUER');
      expect(map['tx.asset'], 'USD:GISSUER');
    });

    test('trims values', () {
      var map = TxRepHelper.parse('tx.fee:   100  ');
      expect(map['tx.fee'], '100');
    });

    test('skips lines where key is empty after trim', () {
      var map = TxRepHelper.parse('  : value\ntx.fee: 100');
      expect(map.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // getValue() / removeComment()
  // ---------------------------------------------------------------------------
  group('TxRepHelper.getValue', () {
    test('returns null for missing key', () {
      expect(TxRepHelper.getValue({}, 'missing'), isNull);
    });

    test('strips inline parenthesized comment', () {
      var map = {'tx.fee': '100 (fee)'};
      expect(TxRepHelper.getValue(map, 'tx.fee'), '100');
    });

    test('returns plain value when no comment', () {
      var map = {'tx.fee': '100'};
      expect(TxRepHelper.getValue(map, 'tx.fee'), '100');
    });
  });

  group('TxRepHelper.removeComment', () {
    test('trims trailing whitespace', () {
      expect(TxRepHelper.removeComment('hello  '), 'hello');
    });

    test('removes parenthesized comment', () {
      expect(TxRepHelper.removeComment('100 (fee amount)'), '100');
    });

    test('handles quoted string with parens inside', () {
      expect(TxRepHelper.removeComment('"hello (world)"'), '"hello (world)"');
    });

    test('handles quoted string with escaped quote', () {
      expect(TxRepHelper.removeComment(r'"say \"hi\""'), r'"say \"hi\""');
    });

    test('handles quoted string with no closing quote', () {
      expect(TxRepHelper.removeComment('"unclosed'), '"unclosed');
    });

    test('handles value starting with open paren', () {
      expect(TxRepHelper.removeComment('(comment)'), '');
    });
  });

  // ---------------------------------------------------------------------------
  // bytesToHex / hexToBytes
  // ---------------------------------------------------------------------------
  group('TxRepHelper.bytesToHex', () {
    test('encodes bytes', () {
      expect(TxRepHelper.bytesToHex(Uint8List.fromList([0xAB, 0xCD])), 'abcd');
    });

    test('returns "0" for empty', () {
      expect(TxRepHelper.bytesToHex(Uint8List(0)), '0');
    });
  });

  group('TxRepHelper.hexToBytes', () {
    test('decodes hex string', () {
      expect(TxRepHelper.hexToBytes('abcd'),
          Uint8List.fromList([0xAB, 0xCD]));
    });

    test('returns empty for "0"', () {
      expect(TxRepHelper.hexToBytes('0'), Uint8List(0));
    });

    test('handles odd-length hex', () {
      expect(TxRepHelper.hexToBytes('abc'),
          Uint8List.fromList([0x0A, 0xBC]));
    });
  });

  // ---------------------------------------------------------------------------
  // escapeString / unescapeString
  // ---------------------------------------------------------------------------
  group('TxRepHelper.escapeString', () {
    test('wraps in double quotes', () {
      expect(TxRepHelper.escapeString('hello'), '"hello"');
    });

    test('escapes backslash', () {
      expect(TxRepHelper.escapeString(r'a\b'), r'"a\\b"');
    });

    test('escapes double quote', () {
      expect(TxRepHelper.escapeString('a"b'), r'"a\"b"');
    });

    test('escapes newline', () {
      expect(TxRepHelper.escapeString('a\nb'), r'"a\nb"');
    });

    test('escapes non-ASCII bytes as \\xNN', () {
      // \u00FF (ÿ) is 0xC3 0xBF in UTF-8
      var result = TxRepHelper.escapeString('\u00FF');
      expect(result, r'"\xc3\xbf"');
    });

    test('passes printable ASCII through', () {
      expect(TxRepHelper.escapeString('abc 123!@#'), '"abc 123!@#"');
    });
  });

  group('TxRepHelper.unescapeString', () {
    test('strips enclosing quotes', () {
      expect(TxRepHelper.unescapeString('"hello"'), 'hello');
    });

    test('handles no quotes', () {
      expect(TxRepHelper.unescapeString('hello'), 'hello');
    });

    test('unescapes backslash', () {
      expect(TxRepHelper.unescapeString(r'"a\\b"'), r'a\b');
    });

    test('unescapes double quote', () {
      expect(TxRepHelper.unescapeString(r'"a\"b"'), 'a"b');
    });

    test('unescapes newline', () {
      expect(TxRepHelper.unescapeString(r'"a\nb"'), 'a\nb');
    });

    test('unescapes hex sequences', () {
      expect(TxRepHelper.unescapeString(r'"\xc3\xbf"'), '\u00FF');
    });

    test('handles invalid hex gracefully', () {
      // \xZZ is not valid hex — should pass through the backslash
      expect(TxRepHelper.unescapeString(r'"\xZZ"'), r'\xZZ');
    });

    test('handles unknown escape sequence', () {
      // \q is not a known escape — pass backslash through
      expect(TxRepHelper.unescapeString(r'"\q"'), r'\q');
    });

    test('roundtrips with escapeString', () {
      var original = 'hello "world"\nnew line \\ backslash';
      var escaped = TxRepHelper.escapeString(original);
      var unescaped = TxRepHelper.unescapeString(escaped);
      expect(unescaped, original);
    });

    test('roundtrips non-ASCII', () {
      var original = '\u00FF\u0100';
      var escaped = TxRepHelper.escapeString(original);
      var unescaped = TxRepHelper.unescapeString(escaped);
      expect(unescaped, original);
    });
  });

  // ---------------------------------------------------------------------------
  // parseInt / parseBigInt
  // ---------------------------------------------------------------------------
  group('TxRepHelper.parseInt', () {
    test('parses decimal', () {
      expect(TxRepHelper.parseInt('42'), 42);
    });

    test('parses hex with 0x prefix', () {
      expect(TxRepHelper.parseInt('0xFF'), 255);
    });

    test('parses hex with 0X prefix', () {
      expect(TxRepHelper.parseInt('0XFF'), 255);
    });

    test('parses negative decimal', () {
      expect(TxRepHelper.parseInt('-42'), -42);
    });

    test('parses negative hex', () {
      expect(TxRepHelper.parseInt('-0xFF'), -255);
    });

    test('trims whitespace', () {
      expect(TxRepHelper.parseInt('  42  '), 42);
    });
  });

  group('TxRepHelper.parseBigInt', () {
    test('parses decimal', () {
      expect(TxRepHelper.parseBigInt('123456789'), BigInt.from(123456789));
    });

    test('parses hex with 0x prefix', () {
      expect(TxRepHelper.parseBigInt('0xFF'), BigInt.from(255));
    });

    test('parses hex with 0X prefix', () {
      expect(TxRepHelper.parseBigInt('0XFF'), BigInt.from(255));
    });

    test('parses negative decimal', () {
      expect(TxRepHelper.parseBigInt('-42'), BigInt.from(-42));
    });

    test('parses negative hex', () {
      expect(TxRepHelper.parseBigInt('-0xFF'), BigInt.from(-255));
    });

    test('trims whitespace', () {
      expect(TxRepHelper.parseBigInt('  42  '), BigInt.from(42));
    });
  });

  // ---------------------------------------------------------------------------
  // formatAccountId / parseAccountId
  // ---------------------------------------------------------------------------
  group('TxRepHelper account ID', () {
    test('formatAccountId roundtrips with parseAccountId', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var accountId = XdrAccountID(pk);
      var formatted = TxRepHelper.formatAccountId(accountId);
      expect(formatted.startsWith('G'), isTrue);
      var parsed = TxRepHelper.parseAccountId(formatted);
      expect(parsed.accountID.getEd25519()!.uint256,
          accountId.accountID.getEd25519()!.uint256);
    });
  });

  // ---------------------------------------------------------------------------
  // formatMuxedAccount / parseMuxedAccount
  // ---------------------------------------------------------------------------
  group('TxRepHelper muxed account', () {
    test('formats and parses ed25519 account', () {
      var muxed = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      muxed.ed25519 =
          XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var formatted = TxRepHelper.formatMuxedAccount(muxed);
      expect(formatted.startsWith('G'), isTrue);
      var parsed = TxRepHelper.parseMuxedAccount(formatted);
      expect(parsed.ed25519!.uint256, muxed.ed25519!.uint256);
    });

    test('throws for invalid strkey', () {
      expect(
        () => TxRepHelper.parseMuxedAccount('INVALID'),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // formatAsset / parseAsset
  // ---------------------------------------------------------------------------
  group('TxRepHelper asset', () {
    test('formats native asset', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      expect(TxRepHelper.formatAsset(asset), 'XLM');
    });

    test('formats alphanum4 asset', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(
        Uint8List.fromList([0x55, 0x53, 0x44, 0x00]), // USD\0
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatAsset(asset);
      expect(formatted.startsWith('USD:G'), isTrue);
    });

    test('formats alphanum12 asset', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = XdrAssetAlphaNum12(
        Uint8List.fromList(
            [...[0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45], ...List<int>.filled(4, 0)]),
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatAsset(asset);
      expect(formatted.startsWith('LONGCODE:G'), isTrue);
    });

    test('parseAsset handles native', () {
      var asset = TxRepHelper.parseAsset('native');
      expect(asset.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
    });

    test('parseAsset handles XLM', () {
      var asset = TxRepHelper.parseAsset('XLM');
      expect(asset.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
    });

    test('parseAsset roundtrips alphanum4', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(
        Uint8List.fromList([0x55, 0x53, 0x44, 0x00]),
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatAsset(asset);
      var parsed = TxRepHelper.parseAsset(formatted);
      expect(parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
    });

    test('parseAsset roundtrips alphanum12', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = XdrAssetAlphaNum12(
        Uint8List.fromList(
            [...[0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45], ...List<int>.filled(4, 0)]),
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatAsset(asset);
      var parsed = TxRepHelper.parseAsset(formatted);
      expect(parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
    });

    test('parseAsset throws for invalid format', () {
      expect(() => TxRepHelper.parseAsset('invalid:format:extra'),
          throwsException);
    });

    test('parseAsset throws for asset code too long', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var issuer = TxRepHelper.formatAccountId(XdrAccountID(pk));
      expect(() => TxRepHelper.parseAsset('TOOLONGASSETCODE:$issuer'),
          throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // formatChangeTrustAsset / parseChangeTrustAsset
  // ---------------------------------------------------------------------------
  group('TxRepHelper changeTrustAsset', () {
    test('formats native', () {
      var asset = XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      expect(TxRepHelper.formatChangeTrustAsset(asset), 'XLM');
    });

    test('formats alphanum4', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset =
          XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(
        Uint8List.fromList([0x55, 0x53, 0x44, 0x00]),
        XdrAccountID(pk),
      );
      expect(TxRepHelper.formatChangeTrustAsset(asset).startsWith('USD:G'),
          isTrue);
    });

    test('formats alphanum12', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset =
          XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = XdrAssetAlphaNum12(
        Uint8List.fromList(
            [...[0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45], ...List<int>.filled(4, 0)]),
        XdrAccountID(pk),
      );
      expect(
          TxRepHelper.formatChangeTrustAsset(asset).startsWith('LONGCODE:G'),
          isTrue);
    });

    test('throws for pool share', () {
      var asset =
          XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);
      expect(() => TxRepHelper.formatChangeTrustAsset(asset), throwsException);
    });

    test('parseChangeTrustAsset handles native', () {
      var asset = TxRepHelper.parseChangeTrustAsset('native');
      expect(asset.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
    });

    test('parseChangeTrustAsset handles XLM', () {
      var asset = TxRepHelper.parseChangeTrustAsset('XLM');
      expect(asset.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
    });

    test('parseChangeTrustAsset roundtrips alphanum4', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset =
          XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(
        Uint8List.fromList([0x55, 0x53, 0x44, 0x00]),
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatChangeTrustAsset(asset);
      var parsed = TxRepHelper.parseChangeTrustAsset(formatted);
      expect(parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
    });

    test('parseChangeTrustAsset roundtrips alphanum12', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset =
          XdrChangeTrustAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = XdrAssetAlphaNum12(
        Uint8List.fromList(
            [...[0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45], ...List<int>.filled(4, 0)]),
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatChangeTrustAsset(asset);
      var parsed = TxRepHelper.parseChangeTrustAsset(formatted);
      expect(parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
    });

    test('parseChangeTrustAsset throws for invalid format', () {
      expect(() => TxRepHelper.parseChangeTrustAsset('bad:format:extra'),
          throwsException);
    });

    test('parseChangeTrustAsset throws for code too long', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var issuer = TxRepHelper.formatAccountId(XdrAccountID(pk));
      expect(
          () => TxRepHelper.parseChangeTrustAsset('TOOLONGASSETCODE:$issuer'),
          throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // formatTrustlineAsset / parseTrustlineAsset
  // ---------------------------------------------------------------------------
  group('TxRepHelper trustlineAsset', () {
    test('formats native', () {
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      expect(TxRepHelper.formatTrustlineAsset(asset), 'XLM');
    });

    test('formats alphanum4', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(
        Uint8List.fromList([0x55, 0x53, 0x44, 0x00]),
        XdrAccountID(pk),
      );
      expect(TxRepHelper.formatTrustlineAsset(asset).startsWith('USD:G'),
          isTrue);
    });

    test('formats alphanum12', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = XdrAssetAlphaNum12(
        Uint8List.fromList(
            [...[0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45], ...List<int>.filled(4, 0)]),
        XdrAccountID(pk),
      );
      expect(TxRepHelper.formatTrustlineAsset(asset).startsWith('LONGCODE:G'),
          isTrue);
    });

    test('formats pool share as hex', () {
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);
      asset.liquidityPoolID =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var formatted = TxRepHelper.formatTrustlineAsset(asset);
      expect(formatted.length, 64); // 32 bytes = 64 hex chars
    });

    test('parseTrustlineAsset handles native', () {
      var asset = TxRepHelper.parseTrustlineAsset('native');
      expect(asset.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
    });

    test('parseTrustlineAsset handles XLM', () {
      var asset = TxRepHelper.parseTrustlineAsset('XLM');
      expect(asset.discriminant, XdrAssetType.ASSET_TYPE_NATIVE);
    });

    test('parseTrustlineAsset roundtrips pool share', () {
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_POOL_SHARE);
      asset.liquidityPoolID =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var formatted = TxRepHelper.formatTrustlineAsset(asset);
      var parsed = TxRepHelper.parseTrustlineAsset(formatted);
      expect(parsed.discriminant, XdrAssetType.ASSET_TYPE_POOL_SHARE);
      expect(parsed.liquidityPoolID!.hash,
          asset.liquidityPoolID!.hash);
    });

    test('parseTrustlineAsset roundtrips alphanum4', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(
        Uint8List.fromList([0x55, 0x53, 0x44, 0x00]),
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatTrustlineAsset(asset);
      var parsed = TxRepHelper.parseTrustlineAsset(formatted);
      expect(parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
    });

    test('parseTrustlineAsset roundtrips alphanum12', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var asset = XdrTrustlineAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = XdrAssetAlphaNum12(
        Uint8List.fromList(
            [...[0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45], ...List<int>.filled(4, 0)]),
        XdrAccountID(pk),
      );
      var formatted = TxRepHelper.formatTrustlineAsset(asset);
      var parsed = TxRepHelper.parseTrustlineAsset(formatted);
      expect(parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
    });

    test('parseTrustlineAsset throws for invalid format', () {
      expect(() => TxRepHelper.parseTrustlineAsset('bad:format:extra'),
          throwsException);
    });

    test('parseTrustlineAsset throws for code too long', () {
      var pk = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      pk.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var issuer = TxRepHelper.formatAccountId(XdrAccountID(pk));
      expect(
          () => TxRepHelper.parseTrustlineAsset('TOOLONGASSETCODE:$issuer'),
          throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // formatSignerKey / parseSignerKey
  // ---------------------------------------------------------------------------
  group('TxRepHelper signerKey', () {
    test('formats and parses ed25519', () {
      var key = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      key.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var formatted = TxRepHelper.formatSignerKey(key);
      expect(formatted.startsWith('G'), isTrue);
      var parsed = TxRepHelper.parseSignerKey(formatted);
      expect(parsed.discriminant, XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      expect(parsed.ed25519!.uint256, key.ed25519!.uint256);
    });

    test('formats and parses preAuthTx', () {
      var key = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      key.preAuthTx =
          XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCD)));
      var formatted = TxRepHelper.formatSignerKey(key);
      expect(formatted.startsWith('T'), isTrue);
      var parsed = TxRepHelper.parseSignerKey(formatted);
      expect(
          parsed.discriminant, XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX);
      expect(parsed.preAuthTx!.uint256, key.preAuthTx!.uint256);
    });

    test('formats and parses hashX', () {
      var key = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      key.hashX = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEF)));
      var formatted = TxRepHelper.formatSignerKey(key);
      expect(formatted.startsWith('X'), isTrue);
      var parsed = TxRepHelper.parseSignerKey(formatted);
      expect(parsed.discriminant, XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X);
      expect(parsed.hashX!.uint256, key.hashX!.uint256);
    });

    test('formats and parses signedPayload', () {
      var key = XdrSignerKey(
          XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD);
      key.signedPayload = XdrSignedPayload(
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))),
        XdrDataValue(Uint8List.fromList([1, 2, 3, 4])),
      );
      var formatted = TxRepHelper.formatSignerKey(key);
      expect(formatted.startsWith('P'), isTrue);
      var parsed = TxRepHelper.parseSignerKey(formatted);
      expect(parsed.discriminant,
          XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD);
    });

    test('parseSignerKey throws for unknown prefix', () {
      expect(() => TxRepHelper.parseSignerKey('Z1234'), throwsException);
    });
  });

  // ---------------------------------------------------------------------------
  // formatAllowTrustAsset / parseAllowTrustAsset
  // ---------------------------------------------------------------------------
  group('TxRepHelper allowTrustAsset', () {
    test('formats alphanum4', () {
      var asset =
          XdrAllowTrustOpAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.assetCode4 = Uint8List.fromList([0x55, 0x53, 0x44, 0x00]);
      expect(TxRepHelper.formatAllowTrustAsset(asset), 'USD');
    });

    test('formats alphanum12', () {
      var asset =
          XdrAllowTrustOpAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.assetCode12 = Uint8List.fromList(
          [...[0x4C, 0x4F, 0x4E, 0x47, 0x43, 0x4F, 0x44, 0x45], ...List<int>.filled(4, 0)]);
      expect(TxRepHelper.formatAllowTrustAsset(asset), 'LONGCODE');
    });

    test('parseAllowTrustAsset alphanum4', () {
      var parsed = TxRepHelper.parseAllowTrustAsset('USD');
      expect(
          parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
    });

    test('parseAllowTrustAsset alphanum12', () {
      var parsed = TxRepHelper.parseAllowTrustAsset('LONGASSET');
      expect(
          parsed.discriminant, XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
    });

    test('parseAllowTrustAsset throws for code too long', () {
      expect(() => TxRepHelper.parseAllowTrustAsset('TOOLONGASSETCODE'),
          throwsException);
    });
  });
}
