import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Matches a [FormatException] whose message contains [fragment].
///
/// Malformed XDR-JSON is refused under one exception type whatever the cause.
/// Only messages this SDK builds are pinned: the wording `jsonDecode` produces
/// for text that is not JSON at all differs between compilation targets.
Matcher formatFailure(String fragment) => throwsA(
  isA<FormatException>().having(
    (FormatException e) => e.message,
    'message',
    contains(fragment),
  ),
);

/// A well-formed G-strkey, supplied wherever a document needs an account and
/// the account is not what the test is about.
const String issuer =
    'GAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSABOV';

/// An `AlphaNum4` document carrying [assetCode].
///
/// [assetCode] is the body of a JSON string, so a SEP-0051 escape appears here
/// with its backslash doubled: the escape ladder runs over the text the JSON
/// parser produces, not over the document.
String alphaNum4(String assetCode) =>
    '{"asset_code":"$assetCode","issuer":"$issuer"}';

/// A `TimeBounds` document carrying [minTime] and [maxTime] verbatim, so a
/// test can supply a rendering that is not a JSON string.
String timeBounds(String minTime, String maxTime) =>
    '{"min_time":$minTime,"max_time":$maxTime}';

void main() {
  // ---------------------------------------------------------------------------
  // Hexadecimal
  // ---------------------------------------------------------------------------
  group('SEP-0051 hexadecimal input', () {
    // Curve25519Public is a struct whose only member is a fixed opaque, so its
    // rejections name both the type and the key.
    const String thirtyTwoBytes =
        '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20';

    test('accepts the canonical lowercase rendering', () {
      expect(
        XdrCurve25519Public.fromXdrJson(
          '{"key":"$thirtyTwoBytes"}',
        ).toXdrJson(),
        '{"key":"$thirtyTwoBytes"}',
      );
    });

    test('rejects uppercase hexadecimal digits', () {
      expect(
        () => XdrCurve25519Public.fromXdrJson('{"key":"${'AB' * 32}"}'),
        formatFailure(
          'XDR-JSON XdrCurve25519Public key "key" expects lowercase '
          'hexadecimal digits',
        ),
      );
      // A single uppercase digit is enough; the rendering is lowercase or it is
      // not the canonical one.
      expect(
        () => XdrCurve25519Public.fromXdrJson(
          '{"key":"${thirtyTwoBytes.substring(0, 62)}2A"}',
        ),
        formatFailure('expects lowercase hexadecimal digits'),
      );
    });

    test('rejects an odd number of hexadecimal digits', () {
      expect(
        () => XdrCurve25519Public.fromXdrJson('{"key":"${'ab' * 32}c"}'),
        formatFailure(
          'XDR-JSON XdrCurve25519Public key "key" has an odd number of '
          'hexadecimal digits',
        ),
      );
    });

    test('rejects a fixed opaque field of the wrong byte count', () {
      expect(
        () => XdrCurve25519Public.fromXdrJson('{"key":"${'ab' * 33}"}'),
        formatFailure('key "key" holds 33 bytes but the declared length is 32'),
      );
      expect(
        () => XdrCurve25519Public.fromXdrJson('{"key":"${'ab' * 31}"}'),
        formatFailure('key "key" holds 31 bytes but the declared length is 32'),
      );
    });

    test('rejects uppercase and odd-length input to a variable opaque', () {
      // DataValue is `opaque<64>`, so the same two rules apply where no length
      // is fixed.
      expect(XdrDataValue.fromXdrJson('"deadbeef"').toXdrJson(), '"deadbeef"');
      expect(
        () => XdrDataValue.fromXdrJson('"DEADBEEF"'),
        formatFailure('XDR-JSON XdrDataValue expects lowercase hexadecimal'),
      );
      expect(
        () => XdrDataValue.fromXdrJson('"deadbee"'),
        formatFailure('odd number of hexadecimal digits'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Escape ladder
  // ---------------------------------------------------------------------------
  group('SEP-0051 escape ladder input', () {
    test('accepts the escapes the ladder defines', () {
      expect(
        XdrAssetAlphaNum4.fromXdrJson(alphaNum4('USD')).toXdrJson(),
        alphaNum4('USD'),
      );
      expect(
        XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'\\xc3\\xc4')).toXdrJson(),
        alphaNum4(r'\\xc3\\xc4'),
      );
      expect(
        XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'A\\0B')).toXdrJson(),
        alphaNum4(r'A\\0B'),
      );
    });

    test('rejects an uppercase hexadecimal escape', () {
      expect(
        () => XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'\\xC3')),
        formatFailure(
          'XDR-JSON XdrAssetAlphaNum4 key "asset_code" has an escape that is '
          'not followed by two lowercase hexadecimal digits',
        ),
      );
      expect(
        () => XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'\\xcD')),
        formatFailure('two lowercase hexadecimal digits'),
      );
    });

    test('rejects an escape the ladder does not define', () {
      expect(
        () => XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'\\q')),
        formatFailure(
          'XDR-JSON XdrAssetAlphaNum4 key "asset_code" holds the unrecognised '
          r'escape \q',
        ),
      );
      // A JSON escape is not a SEP-0051 escape. The ladder sees the text the
      // JSON parser produced, and `\u` is not one of its five markers.
      expect(
        () => XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'\\u0041')),
        formatFailure(r'unrecognised escape \u'),
      );
    });

    test('rejects a trailing backslash', () {
      expect(
        () => XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'AB\\')),
        formatFailure(
          'XDR-JSON XdrAssetAlphaNum4 key "asset_code" ends with an unfinished '
          'escape',
        ),
      );
      expect(
        () => XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'\\x')),
        formatFailure(r'ends with a truncated \x escape'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Integers
  // ---------------------------------------------------------------------------
  group('SEP-0051 integer input', () {
    test('accepts the base-10 string the specification requires', () {
      expect(
        XdrTimeBounds.fromXdrJson(
          timeBounds('"0"', '"1735689600"'),
        ).toXdrJson(),
        timeBounds('"0"', '"1735689600"'),
      );
      expect(
        XdrLiabilities.fromXdrJson(
          '{"buying":"-9223372036854775808","selling":"9223372036854775807"}',
        ).toXdrJson(),
        '{"buying":"-9223372036854775808","selling":"9223372036854775807"}',
      );
    });

    test('rejects decimal text the specification does not define', () {
      // These are string renderings, so the text under test is the document's
      // own. A JSON number reaches the same check through `num.toString()`,
      // whose result differs between compilation targets, and is therefore not
      // asserted here.
      for (final String rendering in <String>[
        '"1e10"',
        '"1.0"',
        '"0x10"',
        '"+1"',
        '"007"',
        '"-0"',
        '" 1"',
        '""',
      ]) {
        expect(
          () => XdrTimeBounds.fromXdrJson(timeBounds(rendering, '"0"')),
          formatFailure('XDR-JSON XdrUint64 expects a base-10 uint64 string'),
          reason: 'accepted $rendering',
        );
      }
    });

    test('rejects a 64-bit value outside its declared range', () {
      expect(
        () => XdrTimeBounds.fromXdrJson(
          timeBounds('"18446744073709551616"', '"0"'),
        ),
        formatFailure(
          'XDR-JSON XdrUint64 holds 18446744073709551616, outside the range of '
          'a uint64',
        ),
      );
      expect(
        () => XdrTimeBounds.fromXdrJson(timeBounds('"-1"', '"0"')),
        formatFailure('outside the range of a uint64'),
      );
      expect(
        () => XdrLiabilities.fromXdrJson(
          '{"buying":"9223372036854775808","selling":"0"}',
        ),
        formatFailure(
          'XDR-JSON XdrInt64 holds 9223372036854775808, outside the range of '
          'an int64',
        ),
      );
      expect(
        () => XdrLiabilities.fromXdrJson(
          '{"buying":"0","selling":"-9223372036854775809"}',
        ),
        formatFailure('outside the range of an int64'),
      );
    });

    test('rejects a JSON number a 64-bit field cannot carry exactly', () {
      // XDR-JSON v1 rendered a 64-bit value as a JSON number, so one is still
      // accepted below 2^53 where it is exact. Past that the parser has already
      // rounded and the rounded value is itself a whole number, so magnitude is
      // the only signal left. Magnitude does not vary by compilation target.
      final XdrTimeBounds fromNumbers = XdrTimeBounds.fromXdrJson(
        timeBounds('9007199254740992', '0'),
      );
      expect(fromNumbers.minTime.uint64, BigInt.from(9007199254740992));
      // What was read from a v1 number renders back in the string form the
      // current specification requires.
      expect(fromNumbers.toXdrJson(), timeBounds('"9007199254740992"', '"0"'));
      expect(
        () => XdrTimeBounds.fromXdrJson(timeBounds('9007199254740994', '0')),
        formatFailure(
          'XDR-JSON XdrUint64 holds 9007199254740994, which a JSON number '
          'cannot carry exactly; render a uint64 as a base-10 string',
        ),
      );
    });

    test('rejects a 32-bit field that is not a JSON number', () {
      // A 32-bit value stays on the number path in both directions, so the
      // string form the 64-bit types require is refused here.
      //
      // A whole double such as 1.0 is deliberately not asserted: the Dart VM
      // refuses it for a 32-bit field and dart2js accepts it, because on that
      // target the value is an integer and carries no signal to tell the two
      // apart. No assertion about it could hold everywhere this SDK runs.
      expect(
        XdrLedgerBounds.fromXdrJson(
          '{"min_ledger":1,"max_ledger":2}',
        ).toXdrJson(),
        '{"min_ledger":1,"max_ledger":2}',
      );
      expect(
        () => XdrLedgerBounds.fromXdrJson('{"min_ledger":"1","max_ledger":2}'),
        formatFailure('XDR-JSON XdrUint32 expects a JSON number'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Struct keys
  // ---------------------------------------------------------------------------
  group('SEP-0051 struct keys', () {
    test('rejects an object missing a declared key', () {
      expect(
        () => XdrTimeBounds.fromXdrJson('{"min_time":"0"}'),
        formatFailure(
          'XDR-JSON XdrTimeBounds is missing the required key "max_time"',
        ),
      );
    });

    test('requires the key of an optional field to be present', () {
      // An optional field may hold null, but its key still has to be there: a
      // missing key and a null value are different documents.
      expect(
        XdrManageDataOp.fromXdrJson(
          '{"data_name":"config","data_value":null}',
        ).toXdrJson(),
        '{"data_name":"config","data_value":null}',
      );
      expect(
        () => XdrManageDataOp.fromXdrJson('{"data_name":"config"}'),
        formatFailure(
          'XDR-JSON XdrManageDataOp is missing the required key "data_value"',
        ),
      );
    });

    test('rejects one undeclared key, naming it', () {
      expect(
        () => XdrTimeBounds.fromXdrJson(
          '{"min_time":"0","max_time":"1","foo":2}',
        ),
        formatFailure('XDR-JSON XdrTimeBounds has the unknown key "foo"'),
      );
    });

    test('rejects several undeclared keys, naming them in sorted order', () {
      // The document below lists its extra keys in descending order. The
      // reported list is sorted, because decoded key order differs between
      // compilation targets and an unsorted list could not be asserted at all.
      expect(
        () => XdrTimeBounds.fromXdrJson(
          '{"min_time":"0","max_time":"1","zeta":2,"foo":3,"alpha":4}',
        ),
        formatFailure(
          'XDR-JSON XdrTimeBounds has the unknown keys "alpha", "foo", "zeta"',
        ),
      );
    });

    test('rejects an undeclared key on a nested struct', () {
      // The declared key set travels with the type, not with the document
      // root, so a nested value is held to its own.
      expect(
        () => XdrPreconditionsV2.fromXdrJson(
          '{"time_bounds":{"min_time":"0","max_time":"1","foo":2},'
          '"ledger_bounds":null,"min_seq_num":null,"min_seq_age":"0",'
          '"min_seq_ledger_gap":0,"extra_signers":[]}',
        ),
        formatFailure('XDR-JSON XdrTimeBounds has the unknown key "foo"'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Aliased keys
  // ---------------------------------------------------------------------------
  group('SEP-0051 aliased struct key', () {
    // DontHave declares an XDR field named `type`. SEP-0051 §Struct requires
    // the key `type`; `type_` is accepted on input and never emitted.
    const String reqHash =
        '0000000000000000000000000000000000000000000000000000000000000000';

    test('accepts either spelling of an aliased key on its own', () {
      final XdrDontHave declared = XdrDontHave.fromXdrJson(
        '{"type":"tx_set","req_hash":"$reqHash"}',
      );
      final XdrDontHave aliased = XdrDontHave.fromXdrJson(
        '{"type_":"tx_set","req_hash":"$reqHash"}',
      );
      expect(
        aliased.toBase64EncodedXdrString(),
        declared.toBase64EncodedXdrString(),
      );
    });

    test('rejects both spellings of an aliased key together', () {
      // The two spellings name one field, so supplying both is the same
      // failure as repeating a key: it is refused rather than resolved to
      // either one.
      expect(
        () => XdrDontHave.fromXdrJson(
          '{"type":"tx_set","type_":"tx_set","req_hash":"$reqHash"}',
        ),
        formatFailure(
          'XDR-JSON XdrDontHave carries both "type" and its accepted alias '
          '"type_"; supply one',
        ),
      );
      // It is refused even where the two spellings disagree, so the rejection
      // does not depend on the values being equal.
      expect(
        () => XdrDontHave.fromXdrJson(
          '{"type":"tx_set","type_":"peers","req_hash":"$reqHash"}',
        ),
        formatFailure('carries both "type" and its accepted alias "type_"'),
      );
    });

    test('counts the alias as a declared key rather than an unknown one', () {
      expect(
        () => XdrDontHave.fromXdrJson(
          '{"type_":"tx_set","req_hash":"$reqHash","foo":1}',
        ),
        formatFailure('has the unknown key "foo"'),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Enums
  // ---------------------------------------------------------------------------
  group('SEP-0051 enum input', () {
    test('rejects a name the enum does not declare', () {
      expect(
        () => XdrEnvelopeType.fromXdrJson('"tx_v9"'),
        formatFailure(
          'XDR-JSON XdrEnvelopeType expects one of its member names but found '
          '"tx_v9"',
        ),
      );
    });

    test('rejects the XDR identifier in place of the SEP-0051 name', () {
      // The wire name is derived from the XDR identifier, not equal to it.
      expect(
        () => XdrEnvelopeType.fromXdrJson('"ENVELOPE_TYPE_TX"'),
        formatFailure('expects one of its member names'),
      );
      expect(
        () => XdrEnvelopeType.fromXdrJson('"envelope_type_tx"'),
        formatFailure('expects one of its member names'),
      );
    });

    test('rejects the numeric value in place of the name', () {
      expect(
        () => XdrEnvelopeType.fromXdrJson('2'),
        formatFailure(
          'XDR-JSON XdrEnvelopeType expects one of its member names but found 2',
        ),
      );
    });

    test('rejects an unknown name inside a struct', () {
      expect(
        () => XdrDontHave.fromXdrJson(
          '{"type":"not_a_message_type","req_hash":"${'00' * 32}"}',
        ),
        formatFailure(
          'XDR-JSON XdrMessageType expects one of its member names',
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Duplicate keys
  // ---------------------------------------------------------------------------
  group('SEP-0051 duplicate object keys', () {
    const String duplicated = '{"min_time":"1","min_time":"2","max_time":"3"}';

    test('rejects a key the document repeats', () {
      expect(
        () => XdrTimeBounds.fromXdrJson(duplicated),
        formatFailure(
          'XDR-JSON XdrTimeBounds repeats the object key "min_time"',
        ),
      );
    });

    test('rejects it from the text, which is where it is still visible', () {
      // The JSON parser resolves a repeat silently in favour of the last
      // occurrence, so by the time a tree exists the repeat is gone. Reading
      // the text is what makes the rejection possible at all.
      expect(jsonDecode(duplicated), <String, Object?>{
        'min_time': '2',
        'max_time': '3',
      });
      expect(
        XdrTimeBounds.fromXdrJsonValue(jsonDecode(duplicated)).minTime.uint64,
        BigInt.two,
      );
      expect(
        () => XdrTimeBounds.fromXdrJson(duplicated),
        formatFailure('repeats the object key "min_time"'),
      );
    });

    test('accepts the same key in sibling objects', () {
      const String siblings =
          '{"read_only":[{"account":{"account_id":"$issuer"}}],'
          '"read_write":[{"account":{"account_id":"$issuer"}}]}';
      expect(XdrLedgerFootprint.fromXdrJson(siblings).toXdrJson(), siblings);
    });
  });

  // ---------------------------------------------------------------------------
  // Text strings
  // ---------------------------------------------------------------------------
  group('SEP-0051 text string input', () {
    test('rejects escapes resolving to bytes that are not valid UTF-8', () {
      // ManageDataOp.dataName is a `string64`, which the XDR layer holds as
      // text. A lone continuation byte decodes to no character, and the
      // UTF-8 decoder's own failure is reported under the XDR-JSON contract
      // rather than escaping as a second exception type.
      expect(
        () => XdrManageDataOp.fromXdrJson(
          r'{"data_name":"\\xc3","data_value":null}',
        ),
        formatFailure(
          'XDR-JSON XdrString64 resolves to bytes that are not valid UTF-8',
        ),
      );
      expect(
        () => XdrManageDataOp.fromXdrJson(
          r'{"data_name":"\\xff","data_value":null}',
        ),
        formatFailure('resolves to bytes that are not valid UTF-8'),
      );
    });

    test('names the member where the reading type declares a key', () {
      expect(
        () => XdrMemo.fromXdrJson(r'{"text":"\\xc3"}'),
        formatFailure(
          'XDR-JSON XdrMemo key "text" resolves to bytes that are not valid '
          'UTF-8',
        ),
      );
      expect(
        () => XdrSCVal.fromXdrJson(r'{"symbol":"\\xc3"}'),
        formatFailure(
          'XDR-JSON XdrSCVal key "symbol" resolves to bytes that are not valid '
          'UTF-8',
        ),
      );
    });

    test('accepts multi-byte text whose escapes form valid UTF-8', () {
      expect(
        XdrManageDataOp.fromXdrJson(
          r'{"data_name":"caf\\xc3\\xa9","data_value":null}',
        ).toXdrJson(),
        r'{"data_name":"caf\\xc3\\xa9","data_value":null}',
      );
    });

    test('takes the ladder over raw bytes where the member is opaque', () {
      // An opaque-backed member is not text, so the same escape that fails on
      // a `string<>` is simply a byte here and no UTF-8 decoding takes place.
      expect(
        XdrAssetAlphaNum4.fromXdrJson(alphaNum4(r'\\xc3')).toXdrJson(),
        alphaNum4(r'\\xc3'),
      );
      expect(XdrDataValue.fromXdrJson('"c3"').toXdrJson(), '"c3"');
    });
  });
}
