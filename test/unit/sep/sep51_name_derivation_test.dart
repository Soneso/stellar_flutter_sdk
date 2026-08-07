import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Names derived under SEP-0051 §Enum, §Struct and §Discriminated Union, at the
/// declarations where the derivation is not obvious from the identifier.
///
/// SEP-0051 states three naming rules. An enum member is its identifier in
/// snake_case with the shared prefix removed when the enum declares more than
/// one member. A struct component is its declared name in snake_case, with no
/// prefix removal. A union arm is named by its discriminant under the enum's own
/// rule, or by the discriminant letter and the integer where the cases are
/// integers.
///
/// Every name below is asserted through the generated type that carries it, so
/// what is pinned is the wire the SDK writes rather than a second statement of
/// the rule that could agree with the first and both be wrong.

/// A type declaring an XDR component named `type`.
///
/// SEP-0051 §Struct names the key after the component, so the key is `type`. The
/// spelling `type_` is accepted on input, because a document may have been
/// written by a producer that escaped the name, and it is never emitted.
class _TypeKeyCase {
  const _TypeKeyCase(this.name, this.base64, this.json, this.render, this.pack);

  final String name;
  final String base64;
  final String json;
  final String Function(String base64) render;
  final String Function(String json) pack;

  String get aliased => json.replaceAll('"type":', '"type_":');
  String get bothSpellings =>
      json.replaceAll('"type":', '"type":${_typeValue(json)},"type_":');
}

String _typeValue(String json) {
  final int start = json.indexOf('"type":') + '"type":'.length;
  int depth = 0;
  for (int i = start; i < json.length; i++) {
    final String unit = json[i];
    if (unit == '[' || unit == '{') {
      depth++;
    } else if (unit == ']' || unit == '}') {
      if (depth == 0) {
        return json.substring(start, i);
      }
      depth--;
    } else if (unit == ',' && depth == 0) {
      return json.substring(start, i);
    }
  }
  return json.substring(start);
}

final List<_TypeKeyCase> _typeKeyCases = <_TypeKeyCase>[
  _TypeKeyCase(
    'XdrDontHave',
    'AAAAAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB',
    '{"type":"error_msg","req_hash":'
        '"0101010101010101010101010101010101010101010101010101010101010101"}',
    (String base64) =>
        XdrDontHave.fromBase64EncodedXdrString(base64).toXdrJson(),
    (String json) => XdrDontHave.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _TypeKeyCase(
    'XdrContractEvent',
    'AAAAAAAAAAEGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgAAAAEAAAAAAAAAAAAA'
        'AAE=',
    '{"ext":"v0","contract_id":'
        '"CADAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMBQGAYDAMSST",'
        '"type":"contract","body":{"v0":{"topics":[],"data":"void"}}}',
    (String base64) =>
        XdrContractEvent.fromBase64EncodedXdrString(base64).toXdrJson(),
    (String json) =>
        XdrContractEvent.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _TypeKeyCase(
    'XdrSCSpecUDTStructFieldV0',
    'AAAAAAAAAAJpZAAAAAAAAQ==',
    '{"doc":"","name":"id","type":"bool"}',
    (String base64) => XdrSCSpecUDTStructFieldV0.fromBase64EncodedXdrString(
      base64,
    ).toXdrJson(),
    (String json) =>
        XdrSCSpecUDTStructFieldV0.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _TypeKeyCase(
    'XdrSCSpecFunctionInputV0',
    'AAAAA2RvYwAAAAAGYW1vdW50AAAAAAAB',
    '{"doc":"doc","name":"amount","type":"bool"}',
    (String base64) =>
        XdrSCSpecFunctionInputV0.fromBase64EncodedXdrString(base64).toXdrJson(),
    (String json) =>
        XdrSCSpecFunctionInputV0.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _TypeKeyCase(
    'XdrSCSpecEventParamV0',
    'AAAAAAAAAAV0b3BpYwAAAAAAAAEAAAAB',
    '{"doc":"","name":"topic","type":"bool","location":"topic_list"}',
    (String base64) =>
        XdrSCSpecEventParamV0.fromBase64EncodedXdrString(base64).toXdrJson(),
    (String json) =>
        XdrSCSpecEventParamV0.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _TypeKeyCase(
    'XdrSCSpecUDTUnionCaseTupleV0',
    'AAAAAAAAAARQYWlyAAAAAgAAAAEAAAAC',
    '{"doc":"","name":"Pair","type":["bool","void"]}',
    (String base64) => XdrSCSpecUDTUnionCaseTupleV0.fromBase64EncodedXdrString(
      base64,
    ).toXdrJson(),
    (String json) => XdrSCSpecUDTUnionCaseTupleV0.fromXdrJson(
      json,
    ).toBase64EncodedXdrString(),
  ),
  _TypeKeyCase(
    'XdrSerializedBinaryFuseFilter',
    'AAAAAQABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fAAAAQAAAAD8AAAAEAAAAEAAA'
        'AAgAAAADqrvMAA==',
    '{"type":"b16_bit","input_hash_seed":'
        '{"seed":"000102030405060708090a0b0c0d0e0f"},"filter_seed":'
        '{"seed":"101112131415161718191a1b1c1d1e1f"},"segment_length":64,'
        '"segement_length_mask":63,"segment_count":4,"segment_count_length":16,'
        '"fingerprint_length":8,"fingerprints":"aabbcc"}',
    (String base64) => XdrSerializedBinaryFuseFilter.fromBase64EncodedXdrString(
      base64,
    ).toXdrJson(),
    (String json) => XdrSerializedBinaryFuseFilter.fromXdrJson(
      json,
    ).toBase64EncodedXdrString(),
  ),
];

void main() {
  group('an enum member keeps a prefix that carries no underscore', () {
    test('opINNER renders as op_inner', () {
      // OperationResultCode's members share the leading `op`, but a shared
      // prefix is only removed up to and including its last underscore and
      // there is none, so nothing is removed and the member's own snake_case
      // stands.
      const String base64 = 'AAAAAAAAAAAAAAAA';
      const String json = '{"op_inner":{"create_account":"success"}}';
      expect(
        XdrOperationResult.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrOperationResult.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('txSUCCESS renders as tx_success', () {
      const String base64 = 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAA=';
      const String json =
          '{"fee_charged":"100","result":{"tx_success":'
          '[{"op_inner":{"create_account":"success"}}]},"ext":"v0"}';
      expect(
        XdrTransactionResult.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrTransactionResult.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('a single-member enum keeps its whole identifier', () {
    test('PUBLIC_KEY_TYPE_ED25519 renders as public_key_type_ed25519', () {
      // Prefix removal applies only where an enum declares more than one
      // member, so the one member of PublicKeyType is not shortened.
      const String base64 = 'AAAAAA==';
      const String json = '"public_key_type_ed25519"';
      expect(
        XdrPublicKeyType.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrPublicKeyType.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('a camel-cased identifier splits at its case boundaries', () {
    test('WasmInsnExec renders as wasm_insn_exec', () {
      const String base64 = 'AAAAAA==';
      const String json = '"wasm_insn_exec"';
      expect(
        XdrContractCostType.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrContractCostType.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('signerSponsoringIDs renders as signer_sponsoring_i_ds', () {
      // The trailing run of capitals splits before the last capital of the run,
      // giving `i` and `ds` as separate words rather than one `ids`.
      const String base64 = 'AAAAAAAAAAEAAAABAAAAAAAAAAA=';
      const String json =
          '{"num_sponsored":0,"num_sponsoring":1,'
          '"signer_sponsoring_i_ds":[null],"ext":"v0"}';
      expect(
        XdrAccountEntryV2.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrAccountEntryV2.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('IPv4 renders as i_pv4', () {
      // The same split, on a two-letter run: `I` closes one word and `Pv4`
      // opens the next.
      const String base64 = 'AAAAAH8AAAEAAC1pAAAAAw==';
      const String json =
          '{"ip":{"i_pv4":"7f000001"},"port":11625,"num_failures":3}';
      expect(
        XdrPeerAddress.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrPeerAddress.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });
  });

  group('a remainder starting with a digit regains the prefix letter', () {
    // BinaryFuseFilterType is where a stripped identifier would otherwise begin
    // with a digit. The first character of the removed prefix is put back, so
    // BINARY_FUSE_FILTER_8_BIT becomes b8_bit and not 8_bit. The letter comes
    // from the prefix, which is why the three members all take `b` here rather
    // than a letter fixed by the rule.
    const Map<String, String> members = <String, String>{
      'AAAAAA==': '"b8_bit"',
      'AAAAAQ==': '"b16_bit"',
      'AAAAAg==': '"b32_bit"',
    };

    test('every member of BinaryFuseFilterType carries the letter back', () {
      members.forEach((String base64, String json) {
        expect(
          XdrBinaryFuseFilterType.fromBase64EncodedXdrString(
            base64,
          ).toXdrJson(),
          json,
        );
        expect(
          XdrBinaryFuseFilterType.fromXdrJson(json).toBase64EncodedXdrString(),
          base64,
        );
      });
    });

    test('the bare digit form is refused', () {
      expect(
        () => XdrBinaryFuseFilterType.fromXdrJson('"8_bit"'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('a struct component named type keeps the key type', () {
    test('every such type emits type and never type_', () {
      for (final _TypeKeyCase entry in _typeKeyCases) {
        expect(entry.render(entry.base64), entry.json, reason: entry.name);
        expect(
          entry.render(entry.base64).contains('"type_"'),
          isFalse,
          reason: entry.name,
        );
      }
    });

    test('every such type accepts type_ as an input spelling', () {
      for (final _TypeKeyCase entry in _typeKeyCases) {
        expect(entry.aliased == entry.json, isFalse, reason: entry.name);
        expect(entry.pack(entry.aliased), entry.base64, reason: entry.name);
      }
    });

    test('reading type_ emits type, so the spelling is not carried over', () {
      for (final _TypeKeyCase entry in _typeKeyCases) {
        expect(
          entry.render(entry.pack(entry.aliased)),
          entry.json,
          reason: entry.name,
        );
      }
    });

    test('supplying both spellings is refused rather than resolved', () {
      for (final _TypeKeyCase entry in _typeKeyCases) {
        // The document is well-formed JSON carrying both keys with the same
        // value, so what is refused is the pair of spellings and not a parse
        // failure standing in for it.
        final Map<String, dynamic> parsed =
            jsonDecode(entry.bothSpellings) as Map<String, dynamic>;
        expect(parsed.containsKey('type'), isTrue, reason: entry.name);
        expect(parsed.containsKey('type_'), isTrue, reason: entry.name);
        expect(parsed['type'], parsed['type_'], reason: entry.name);
        expect(
          () => entry.pack(entry.bothSpellings),
          throwsA(isA<FormatException>()),
          reason: entry.name,
        );
      }
    });
  });

  group('an integer-cased union names its arm v and the integer', () {
    test('a void case renders as v0', () {
      const String base64 = 'AAAAAA==';
      const String json = '"v0"';
      expect(
        XdrExtensionPoint.fromBase64EncodedXdrString(base64).toXdrJson(),
        json,
      );
      expect(
        XdrExtensionPoint.fromXdrJson(json).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the key is the letter v, not the declared discriminant name', () {
      // The discriminant of these unions is declared `int v`, and the key would
      // read the same if it were taken from that name. SorobanTransactionMetaExt
      // is the same shape and renders the same way, which is what shows the key
      // does not vary with the declaration.
      expect(
        XdrSorobanTransactionMetaExt.fromBase64EncodedXdrString(
          'AAAAAA==',
        ).toXdrJson(),
        '"v0"',
      );
    });

    test('a name that is not the integer form is refused', () {
      expect(
        () => XdrExtensionPoint.fromXdrJson('"v1"'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => XdrExtensionPoint.fromXdrJson('"ext_v0"'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('a union arm is named over the whole discriminant enum', () {
    // FeeBumpTransaction's innerTx switches on EnvelopeType and declares one
    // case, ENVELOPE_TYPE_TX. The shared prefix that is removed belongs to
    // EnvelopeType as declared, over all eleven of its members, not to the one
    // member this union happens to cover. The prefix is therefore
    // ENVELOPE_TYPE_ and the arm key is tx.
    const String base64 =
        'AAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGQAAAAAAAAA'
        'AQAAAAAAAAAAAAAAAAAAAAAAAAAA';
    const String json =
        '{"tx":{"tx":{"source_account":'
        '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF",'
        '"fee":100,"seq_num":"1","cond":"none","memo":"none",'
        '"operations":[],"ext":"v0"},"signatures":[]}}';

    test('the arm key is tx', () {
      expect(
        XdrFeeBumpTransactionInnerTx.fromBase64EncodedXdrString(
          base64,
        ).toXdrJson(),
        json,
      );
      expect(
        XdrFeeBumpTransactionInnerTx.fromXdrJson(
          json,
        ).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('it is the discriminant member\'s own name', () {
      expect(
        XdrEnvelopeType.fromBase64EncodedXdrString('AAAAAg==').toXdrJson(),
        '"tx"',
      );
    });

    test('the unstripped spelling is refused', () {
      expect(
        () => XdrFeeBumpTransactionInnerTx.fromXdrJson(
          json.replaceFirst('{"tx":', '{"envelope_type_tx":'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('the prefix is what the other members of the enum show it to be', () {
      // Two members that keep a `tx` of their own after the prefix is removed.
      // A prefix computed over only the members this union covers would leave
      // `envelope_type_tx` above and could not produce these.
      expect(
        XdrEnvelopeType.fromBase64EncodedXdrString('AAAAAA==').toXdrJson(),
        '"tx_v0"',
      );
      expect(
        XdrEnvelopeType.fromBase64EncodedXdrString('AAAABQ==').toXdrJson(),
        '"tx_fee_bump"',
      );
    });
  });

  group('a component name is reproduced as the .x declares it', () {
    test('segementLengthMask renders as segement_length_mask', () {
      // The declaration carries this spelling, and the key is derived from the
      // declared name rather than from any correction of it.
      const String base64 =
          'AAAAAQABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fAAAAQAAAAD8AAAAEAAAA'
          'EAAAAAgAAAADqrvMAA==';
      final String rendered =
          XdrSerializedBinaryFuseFilter.fromBase64EncodedXdrString(
            base64,
          ).toXdrJson();
      expect(rendered.contains('"segement_length_mask":63'), isTrue);
      expect(rendered.contains('"segment_length_mask"'), isFalse);
      expect(
        XdrSerializedBinaryFuseFilter.fromXdrJson(
          rendered,
        ).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('the corrected spelling is refused', () {
      const String base64 =
          'AAAAAQABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fAAAAQAAAAD8AAAAEAAAA'
          'EAAAAAgAAAADqrvMAA==';
      final String rendered =
          XdrSerializedBinaryFuseFilter.fromBase64EncodedXdrString(
            base64,
          ).toXdrJson();
      expect(
        () => XdrSerializedBinaryFuseFilter.fromXdrJson(
          rendered.replaceFirst(
            '"segement_length_mask"',
            '"segment_length_mask"',
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
