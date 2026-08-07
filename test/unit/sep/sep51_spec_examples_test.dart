import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Anchors on the worked examples of SEP-0051 §Specification.
///
/// Each example the specification states is pinned here in both directions: the
/// base64 it publishes decodes to the JSON it publishes, and that JSON encodes
/// back to the same base64. Anchoring on the specification's own values rather
/// than on a round trip is what makes these tests capable of failing; two
/// directions that are wrong in the same way round-trip perfectly.
///
/// Where the specification illustrates a rule with an XDR declaration that no
/// Stellar `.x` file contains, the nearest declaration that does is used and the
/// substitution is named in a comment. Nothing else deviates.
void main() {
  group('SEP-0051 §Integer (32-bit)', () {
    // int identifier; 0x7fffffff
    const String base64 = 'f////w==';
    const String json = '2147483647';

    test('renders as a JSON number', () {
      expect(XdrInt32.fromXdrJson(json).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrInt32.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });
  });

  group('SEP-0051 §Unsigned Integer (32-bit)', () {
    // unsigned int identifier; 0xffffffff
    const String base64 = '/////w==';
    const String json = '4294967295';

    test('renders as a JSON number', () {
      expect(XdrUint32.fromXdrJson(json).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrUint32.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });
  });

  group('SEP-0051 §Hyper Integer (64-bit)', () {
    // hyper identifier; 0x7fffffffffffffff
    const String base64 = 'f/////////8=';
    const String json = '"9223372036854775807"';

    test('renders as a base-10 string', () {
      expect(XdrInt64.fromXdrJson(json).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrInt64.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test('also reads a JSON number, for XDR-JSON v1 documents', () {
      // The specification's note under this section asks implementations to
      // accept the number form on input where they can. The string form is
      // still the only one emitted.
      expect(XdrInt64.fromXdrJson('-7').toXdrJson(), '"-7"');
    });
  });

  group('SEP-0051 §Unsigned Hyper Integer (64-bit)', () {
    // unsigned hyper identifier; 0xffffffffffffffff
    const String base64 = '//////////8=';
    const String json = '"18446744073709551615"';

    test('renders as a base-10 string', () {
      expect(XdrUint64.fromXdrJson(json).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrUint64.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test('also reads a JSON number, for XDR-JSON v1 documents', () {
      expect(XdrUint64.fromXdrJson('7').toXdrJson(), '"7"');
    });
  });

  group('SEP-0051 §Boolean', () {
    // bool identifier; true. Reached through SCVal's bool arm, the boolean the
    // .x declares that is addressable on its own.
    const String base64 = 'AAAAAAAAAAE=';
    const String json = '{"bool":true}';

    test('renders as a JSON boolean', () {
      expect(XdrSCVal.fromBase64EncodedXdrString(base64).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrSCVal.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });
  });

  group('SEP-0051 §Opaque Data (Fixed Length)', () {
    // opaque identifier[4]; "abcd". SignatureHint is the four-byte fixed opaque
    // the .x declares.
    const String base64 = 'YWJjZA==';
    const String json = '"61626364"';

    test('renders as a lowercase hexadecimal string', () {
      expect(
        XdrSignatureHint.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
    });

    test('reads back to the published binary', () {
      expect(
        XdrSignatureHint.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('SEP-0051 §Opaque Data (Variable Length)', () {
    // opaque identifier<>; "abcd". The published binary carries the four-byte
    // length prefix a variable-length opaque field is declared with.
    const String base64 = 'AAAABGFiY2Q=';
    const String json = '"61626364"';

    test('renders as a lowercase hexadecimal string', () {
      expect(XdrDataValue.fromBase64EncodedXdrString(base64).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrDataValue.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test('renders an empty field as an empty string', () {
      const String empty = 'AAAAAA==';
      expect(XdrDataValue.fromBase64EncodedXdrString(empty).toXdrJson(), '""');
      expect(XdrDataValue.fromXdrJson('""').toBase64EncodedXdrString(), empty);
    });
  });

  group('SEP-0051 §String', () {
    test('applies the escape ladder byte by byte', () {
      // One byte from each rung, in the order the section lists them: NUL, tab,
      // line feed, carriage return, backslash, then the last character of the
      // unescaped printable range and the first one past it.
      const String base64 = 'AAAACQAJCg1cfn9BQgAAAA==';
      const String json = r'"\\0\\t\\n\\r\\\\~\\x7fAB"';
      expect(XdrString64.fromBase64EncodedXdrString(base64).toXdrJson(), json);
      expect(XdrString64.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test('escapes a byte above the printable range as two lowercase digits', () {
      // The section's own example value, `hello\xc3world`, reached through the
      // twelve-byte asset code that carries exactly those bytes: the code is
      // opaque, so the bytes take the escape ladder without being read as text.
      const String base64 = 'AAAAAmhlbGxvw3dvcmxkAA==';
      const String json = r'"hello\\xc3world"';
      expect(
        XdrAllowTrustOpAsset.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAllowTrustOpAsset.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('refuses those bytes for a string field, which carries text', () {
      // A `string<>` member is a Dart string, so its bytes are text and
      // `hello\xc3world` is not a text this SDK can hold: the binary decoder
      // refuses the same bytes. The JSON path accepts exactly what the binary
      // path accepts, no more and no less.
      expect(
        () => XdrString64.fromXdrJson(r'"hello\\xc3world"'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SEP-0051 §Arrays (Fixed Length)', () {
    test('renders as a JSON array of its elements', () {
      // The section illustrates the rule with `int identifier[4]`, a shape no
      // Stellar .x declares. LedgerHeader.skipList is the fixed-length array
      // that is declared, four hashes wide.
      const String base64 =
          'AAAAF6qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqAQIDBAUGBwgJCgsMDQ4P'
          'EBESExQVFhcYGRobHB0eHyAAAAAASZYC0gAAAAAAAAAAu7u7u7u7u7u7u7u7u7u7u7u7'
          'u7u7u7u7u7u7u7u7u7vMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzAAAAAkA'
          'AAAAO5rKAAAAAAAAAABkAAAAAAAAAAAAAAAHAAAAZABMS0AAAAH0AQEBAQEBAQEBAQEB'
          'AQEBAQEBAQEBAQEBAQEBAQEBAQECAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIC'
          'AgMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDBAQEBAQEBAQEBAQEBAQEBAQE'
          'BAQEBAQEBAQEBAQEBAQAAAAA';
      final Object? value = XdrLedgerHeader.fromBase64EncodedXdrString(
        base64,
      ).toXdrJsonValue();
      expect((value! as Map<String, Object?>)['skip_list'], <String>[
        '0101010101010101010101010101010101010101010101010101010101010101',
        '0202020202020202020202020202020202020202020202020202020202020202',
        '0303030303030303030303030303030303030303030303030303030303030303',
        '0404040404040404040404040404040404040404040404040404040404040404',
      ]);
      expect(
        XdrLedgerHeader.fromXdrJson(
          XdrLedgerHeader.fromBase64EncodedXdrString(base64).toXdrJson(),
        ).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('SEP-0051 §Arrays (Variable Length)', () {
    // The section's example is `int identifier<>` holding 1, 2, 3, 4. The
    // declared array of 32-bit integers in the .x holds the same four values
    // here.
    const String base64 = 'AAAABAAAAAEAAAACAAAAAwAAAAQ=';
    const String json = '{"archived_soroban_entries":[1,2,3,4]}';

    test('renders as a JSON array of its elements', () {
      expect(
        XdrSorobanResourcesExtV0.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
    });

    test('reads back to the published binary', () {
      expect(
        XdrSorobanResourcesExtV0.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('renders an empty array as [], never omitting it', () {
      const String empty = 'AAAAAA==';
      expect(
        XdrSorobanResourcesExtV0.fromBase64EncodedXdrString(empty).toXdrJson(),
        '{"archived_soroban_entries":[]}',
      );
    });
  });

  group('SEP-0051 §Enum', () {
    // enum SCValType, value 3.
    const String base64 = 'AAAAAw==';
    const String json = '"u32"';

    test('renders as the shared-prefix-stripped member name', () {
      expect(XdrSCValType.fromBase64EncodedXdrString(base64).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrSCValType.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });
  });

  group('SEP-0051 §Struct', () {
    // struct TtlEntry { Hash keyHash; uint32 liveUntilLedgerSeq; }
    const String base64 = 'AQIDBAUGBwgJEBESExQVFhcYGSAhIiMkJSYnKCkwMTIAAAAB';
    const String json =
        '{"key_hash":'
        '"0102030405060708091011121314151617181920212223242526272829303132",'
        '"live_until_ledger_seq":1}';

    test('renders each component under its snake_case name', () {
      expect(XdrTTLEntry.fromBase64EncodedXdrString(base64).toXdrJson(), json);
    });

    test('reads back to the published binary', () {
      expect(XdrTTLEntry.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });
  });

  group('SEP-0051 §Discriminated Union', () {
    test('renders a void arm as a bare string', () {
      // union Asset switch (AssetType type) case ASSET_TYPE_NATIVE: void;
      const String base64 = 'AAAAAA==';
      const String json = '"native"';
      expect(XdrAsset.fromBase64EncodedXdrString(base64).toXdrJson(), json);
      expect(XdrAsset.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test('renders a valued arm as a single-key object', () {
      const String base64 =
          'AAAAAUFCQ0QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
      const String json =
          '{"credit_alphanum4":{"asset_code":"ABCD","issuer":'
          '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';
      expect(XdrAsset.fromBase64EncodedXdrString(base64).toXdrJson(), json);
      expect(XdrAsset.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });

    test(
      'names an integer case by the discriminant letter and the integer',
      () {
        // union SorobanTransactionMetaExt switch (int v) case 0: void;
        const String base64 = 'AAAAAA==';
        const String json = '"v0"';
        expect(
          XdrSorobanTransactionMetaExt.fromBase64EncodedXdrString(
            base64,
          ).toXdrJson(),
          json,
        );
        expect(
          XdrSorobanTransactionMetaExt.fromXdrJson(
            json,
          ).toBase64EncodedXdrString(),
          base64,
        );
      },
    );
  });

  group('SEP-0051 §Optional Data', () {
    // The section's example is `int* identifier`, rendered as null when unset
    // and as the value when set. SetOptionsOp.clearFlags is the declared
    // optional 32-bit integer.
    const String allUnset = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
    const String clearFlagsSet =
        'AAAAAAAAAAEAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==';

    test('renders an unset value as null, keeping the key', () {
      final Object? value = XdrSetOptionsOp.fromBase64EncodedXdrString(
        allUnset,
      ).toXdrJsonValue();
      final Map<String, Object?> object = value! as Map<String, Object?>;
      expect(object.containsKey('clear_flags'), isTrue);
      expect(object['clear_flags'], isNull);
    });

    test('renders a set value as the value itself', () {
      final Object? value = XdrSetOptionsOp.fromBase64EncodedXdrString(
        clearFlagsSet,
      ).toXdrJsonValue();
      expect((value! as Map<String, Object?>)['clear_flags'], 1);
    });

    test('reads both states back to the published binary', () {
      for (final String base64 in <String>[allUnset, clearFlagsSet]) {
        final String json = XdrSetOptionsOp.fromBase64EncodedXdrString(
          base64,
        ).toXdrJson();
        expect(
          XdrSetOptionsOp.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      }
    });
  });

  group('SEP-0051 §Address Types', () {
    test('renders the section\'s muxed contract address as an M-strkey', () {
      const String base64 =
          'AAAAAgAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
      const String json =
          '"MAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFNZG"';
      expect(XdrSCAddress.fromXdrJson(json).toXdrJson(), json);
      expect(XdrSCAddress.fromXdrJson(json).toBase64EncodedXdrString(), base64);
    });
  });

  group('SEP-0051 §Asset Code Types', () {
    test('renders a four-byte code with its trailing NUL bytes removed', () {
      // typedef opaque AssetCode4[4] filling three bytes.
      const String base64 = 'AAAAAUFCQwA=';
      const String json = '"ABC"';
      expect(
        XdrAllowTrustOpAsset.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAllowTrustOpAsset.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('renders a twelve-byte code filling five bytes unpadded', () {
      const String base64 = 'AAAAAkFCQ0RFAAAAAAAAAA==';
      const String json = '"ABCDE"';
      expect(
        XdrAllowTrustOpAsset.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAllowTrustOpAsset.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('pads a twelve-byte code filling three bytes back to five', () {
      const String base64 = 'AAAAAkFCQwAAAAAAAAAAAA==';
      const String json = r'"ABC\\0\\0"';
      expect(
        XdrAllowTrustOpAsset.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAllowTrustOpAsset.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('SEP-0051 §Integer Types', () {
    test('renders the reassembled integer as one base-10 string', () {
      // The section states the rule for the four parts types and publishes no
      // worked example; the limb arithmetic is pinned in
      // sep51_stellar_types_test.dart. This holds the rule itself: one string,
      // not an object of limbs.
      const String base64 = 'AAAAAAAAAAEAAAAAAAAAAg==';
      final Object? value = XdrUInt128Parts.fromXdrJson(
        '"18446744073709551618"',
      ).toXdrJsonValue();
      expect(value, isA<String>());
      expect(value, '18446744073709551618');
      expect(
        XdrUInt128Parts.fromXdrJson(
          '"18446744073709551618"',
        ).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('SEP-0051 canonical form', () {
    test('emits compact JSON in declaration order', () {
      // The rendered document carries no insignificant whitespace and lists
      // keys in the order the .x declares the components, which is what makes a
      // byte-for-byte comparison of two documents meaningful.
      const String base64 = 'AQIDBAUGBwgJEBESExQVFhcYGSAhIiMkJSYnKCkwMTIAAAAB';
      final String rendered = XdrTTLEntry.fromBase64EncodedXdrString(
        base64,
      ).toXdrJson();
      expect(rendered.contains(' '), isFalse);
      expect(rendered.contains('\n'), isFalse);
      expect(
        (jsonDecode(rendered) as Map<String, dynamic>).keys.toList(),
        <String>['key_hash', 'live_until_ledger_seq'],
      );
    });

    test('renders bytes as lowercase hexadecimal', () {
      final Uint8List raw = Uint8List.fromList(<int>[0xab, 0xcd, 0xef, 0x10]);
      expect(XdrSignatureHint(raw).toXdrJson(), '"abcdef10"');
    });
  });
}
