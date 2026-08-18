@Timeout(const Duration(seconds: 300))
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// The transaction envelope SEP-0051 publishes in its Examples section, used by
/// several snippets on the page.
const String envelopeBase64 =
    'AAAAAgAAAADmmSZkwY3163TMouB2TY8MljqXw2IxVYTGyvDrR6YtAAAqmmQAABpuAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAEAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAAAAAABAAAABgAAAAHXkotywnA8z+r365/0701QSlWouXn8m0UOoshCtNHOYQAAABQAAAABAAI9fQAAAAAAAAD4AAAAAAAqmgAAAAABR6YtAAAAAEArDtxbqUI+CsdkRmV0lFhVt0wyB7fyrmmkM6Fr35wpPcK8WKcXeKTl4BQ+akE14MZtpaea9LMdhXopaW3pJA0E';

void main() {
  test('sep-51: Quick example - envelope to XDR-JSON and back', () {
    // Snippet from sep-51.md "Quick example"
    XdrTransactionEnvelope envelope =
        XdrTransactionEnvelope.fromBase64EncodedXdrString(envelopeBase64);

    String json = envelope.toXdrJson();

    XdrTransactionEnvelope parsed = XdrTransactionEnvelope.fromXdrJson(json);
    String backToBase64 = parsed.toBase64EncodedXdrString();

    // The whole document, not a set of fragments: the page prints this
    // rendering, so every key and every value on it is part of what the
    // snippet claims.
    expect(
      json,
      equals(
        '{"tx":{"tx":{"source_account":'
        '"GDTJSJTEYGG7L23UZSROA5SNR4GJMOUXYNRDCVMEY3FPB22HUYWQBZIA",'
        '"fee":2792036,"seq_num":"29059748724737","cond":"none",'
        '"memo":"none","operations":[{"source_account":null,'
        '"body":{"invoke_host_function":{"host_function":'
        '{"create_contract":{"contract_id_preimage":{"asset":"native"},'
        '"executable":"stellar_asset"}},"auth":[]}}}],'
        '"ext":{"v1":{"ext":"v0","resources":{"footprint":'
        '{"read_only":[],"read_write":[{"contract_data":{"contract":'
        '"CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",'
        '"key":"ledger_key_contract_instance","durability":"persistent"}}]},'
        '"instructions":146813,"disk_read_bytes":0,"write_bytes":248},'
        '"resource_fee":"2791936"}}},"signatures":[{"hint":"47a62d00",'
        '"signature":"2b0edc5ba9423e0ac764466574945855b74c3207b7f2ae69a433'
        'a16bdf9c293dc2bc58a71778a4e5e0143e6a4135e0c66da5a79af4b31d857a2969'
        '6de9240d04"}]}}',
      ),
    );
    expect(backToBase64, equals(envelopeBase64));
  });

  test('sep-51: The four members', () {
    // Snippet from sep-51.md "The four members"
    XdrMemo memo = XdrMemo.fromBase64EncodedXdrString(
      'AAAAAQAAAAVoZWxsbwAAAA==',
    );

    String document = memo.toXdrJson();
    Object? tree = memo.toXdrJsonValue();

    XdrMemo fromDocument = XdrMemo.fromXdrJson(document);
    XdrMemo fromTree = XdrMemo.fromXdrJsonValue(tree);

    expect(document, equals('{"text":"hello"}'));
    expect(tree, equals(<String, Object?>{'text': 'hello'}));
    expect(fromDocument.text, equals('hello'));
    expect(fromTree.text, equals('hello'));
  });

  test('sep-51: Booleans', () {
    // Snippet from sep-51.md "Booleans"
    XdrSCVal flag = XdrSCVal.fromXdrJson('{"bool":true}');

    expect(flag.b, isTrue);
    expect(flag.toXdrJson(), equals('{"bool":true}'));
    expect(XdrSCVal.forBool(false).toXdrJson(), equals('{"bool":false}'));

    // A boolean member of a struct renders the same way.
    XdrDiagnosticEvent event = XdrDiagnosticEvent.fromBase64EncodedXdrString(
      'AAAAAQAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAQ==',
    );
    expect(
      event.toXdrJson(),
      startsWith('{"in_successful_contract_call":true,"event":'),
    );

    // The strings "true" and "false" and the numbers 1 and 0 are refused.
    expect(
      () => XdrSCVal.fromXdrJson('{"bool":"true"}'),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('expects a boolean but found "true"'),
        ),
      ),
    );
    expect(
      () => XdrSCVal.fromXdrJson('{"bool":1}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('sep-51: 32-bit numbers stay numbers', () {
    // Snippet from sep-51.md "Integers"
    XdrLedgerBounds bounds = XdrLedgerBounds.fromXdrJson(
      '{"min_ledger":1,"max_ledger":2}',
    );

    expect(bounds.minLedger.uint32, equals(1));
    expect(bounds.toXdrJson(), equals('{"min_ledger":1,"max_ledger":2}'));

    // A 32-bit field takes a JSON number, not a string.
    expect(
      () => XdrLedgerBounds.fromXdrJson('{"min_ledger":"1","max_ledger":2}'),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('expects a JSON number but found "1"'),
        ),
      ),
    );
  });

  test('sep-51: 64-bit numbers are base-10 strings', () {
    // Snippet from sep-51.md "Integers"
    XdrTimeBounds bounds = XdrTimeBounds.fromXdrJson(
      '{"min_time":"0","max_time":"1735689600"}',
    );

    expect(bounds.maxTime.uint64, equals(BigInt.from(1735689600)));
    expect(
      bounds.toXdrJson(),
      equals('{"min_time":"0","max_time":"1735689600"}'),
    );

    // The full unsigned range survives, including values no JavaScript number
    // can hold exactly.
    XdrUint64 max = XdrUint64.fromXdrJson('"18446744073709551615"');
    expect(max.uint64, equals(BigInt.parse('18446744073709551615')));
    expect(max.toXdrJson(), equals('"18446744073709551615"'));
  });

  test('sep-51: Opaque fields render as lowercase hex', () {
    // Snippet from sep-51.md "Opaque data and text"
    XdrSignatureHint hint = XdrSignatureHint.fromBase64EncodedXdrString(
      'YWJjZA==',
    );
    expect(hint.toXdrJson(), equals('"61626364"'));

    // A variable-length opaque field renders the same way, and an empty one
    // renders as an empty string.
    expect(
      XdrDataValue.fromXdrJson('"deadbeef"').toXdrJson(),
      equals('"deadbeef"'),
    );
    expect(
      XdrDataValue.fromXdrJson('""').toBase64EncodedXdrString(),
      equals('AAAAAA=='),
    );
  });

  test('sep-51: Text takes the escape ladder', () {
    // Snippet from sep-51.md "Opaque data and text"
    XdrMemo tab = XdrMemo.fromBase64EncodedXdrString(
      'AAAAAQAAAAh0YWIJaGVyZQ==',
    );
    expect(tab.toXdrJson(), equals(r'{"text":"tab\\there"}'));

    // The escape ladder runs over the bytes, so a multi-byte character arrives
    // as one \xNN escape per byte.
    XdrManageDataOp op = XdrManageDataOp.fromXdrJson(
      r'{"data_name":"caf\\xc3\\xa9","data_value":null}',
    );
    expect(op.dataName.string64, equals('café'));
    expect(
      op.toXdrJson(),
      equals(r'{"data_name":"caf\\xc3\\xa9","data_value":null}'),
    );
  });

  test('sep-51: Unions - void arm, absent optional, empty container', () {
    // Snippet from sep-51.md "Unions: a void arm is not an absent value"
    XdrSCVal voidArm = XdrSCVal.fromXdrJson('"void"');
    XdrSCVal absentVec = XdrSCVal.fromXdrJson('{"vec":null}');
    XdrSCVal emptyVec = XdrSCVal.fromXdrJson('{"vec":[]}');

    expect(voidArm.toBase64EncodedXdrString(), equals('AAAAAQ=='));
    expect(absentVec.toBase64EncodedXdrString(), equals('AAAAEAAAAAA='));
    expect(emptyVec.toBase64EncodedXdrString(), equals('AAAAEAAAAAEAAAAA'));

    expect(absentVec.vec, isNull);
    expect(emptyVec.vec, isEmpty);

    // The three are different values and encode to different bytes.
    expect(
      voidArm.toBase64EncodedXdrString(),
      isNot(absentVec.toBase64EncodedXdrString()),
    );
    expect(
      absentVec.toBase64EncodedXdrString(),
      isNot(emptyVec.toBase64EncodedXdrString()),
    );

    // The bare string form is refused for an arm that is not void.
    expect(
      () => XdrSCVal.fromXdrJson('"vec"'),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('XdrSCVal has no arm named "vec"'),
        ),
      ),
    );
  });

  test('sep-51: Structs key on the XDR field name', () {
    // Snippet from sep-51.md "Structs"
    XdrContractEvent event = XdrContractEvent.fromBase64EncodedXdrString(
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB',
    );

    expect(
      event.toXdrJson(),
      equals(
        '{"ext":"v0","contract_id":null,"type":"system",'
        '"body":{"v0":{"topics":[],"data":"void"}}}',
      ),
    );

    // Every declared key has to be present, even where the value is null.
    expect(
      () => XdrContractEvent.fromXdrJson(
        '{"ext":"v0","type":"system",'
        '"body":{"v0":{"topics":[],"data":"void"}}}',
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('is missing the required key "contract_id"'),
        ),
      ),
    );
  });

  test('sep-51: The type_ input alias', () {
    // Snippet from sep-51.md "Structs"
    String declared =
        '{"ext":"v0","contract_id":null,"type":"system",'
        '"body":{"v0":{"topics":[],"data":"void"}}}';
    String aliased =
        '{"ext":"v0","contract_id":null,"type_":"system",'
        '"body":{"v0":{"topics":[],"data":"void"}}}';

    expect(
      XdrContractEvent.fromXdrJson(aliased).toBase64EncodedXdrString(),
      equals(XdrContractEvent.fromXdrJson(declared).toBase64EncodedXdrString()),
    );

    // `type_` is accepted and never emitted.
    expect(XdrContractEvent.fromXdrJson(aliased).toXdrJson(), equals(declared));

    // Supplying both spellings is refused rather than resolved, and the page
    // quotes the message, so the message is part of the snippet.
    expect(
      () => XdrContractEvent.fromXdrJson(
        '{"ext":"v0","contract_id":null,"type":"system","type_":"system",'
        '"body":{"v0":{"topics":[],"data":"void"}}}',
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('carries both "type" and its accepted alias "type_"'),
        ),
      ),
    );
  });

  test('sep-51: An array of an optional type carries null elements', () {
    // Snippet from sep-51.md "Optional values"
    XdrAccountEntryV2 sponsors = XdrAccountEntryV2.fromXdrJson(
      '{"num_sponsored":0,"num_sponsoring":1,'
      '"signer_sponsoring_i_ds":[null],"ext":"v0"}',
    );

    expect(sponsors.signerSponsoringIDs, hasLength(1));
    expect(sponsors.signerSponsoringIDs.first, isNull);
    expect(
      sponsors.toBase64EncodedXdrString(),
      equals('AAAAAAAAAAEAAAABAAAAAAAAAAA='),
    );

    // Present and absent elements interleave without shifting position.
    XdrAccountEntryV2 mixed = XdrAccountEntryV2.fromXdrJson(
      '{"num_sponsored":2,"num_sponsoring":3,"signer_sponsoring_i_ds":'
      '["GAAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQDZ7H",null,'
      '"GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H"],'
      '"ext":"v0"}',
    );
    expect(mixed.signerSponsoringIDs, hasLength(3));
    expect(mixed.signerSponsoringIDs[1], isNull);
  });

  test('sep-51: The \$schema property is accepted and stripped', () {
    // Snippet from sep-51.md "The \$schema property"
    String document =
        r'{"$schema":"https://stellar.org/schema/xdr-json/main/Asset.json",'
        '"credit_alphanum4":{"asset_code":"ABCD","issuer":'
        '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';

    XdrAsset asset = XdrAsset.fromXdrJson(document);

    expect(asset.toXdrJson(), isNot(contains(r'$schema')));
    expect(
      asset.toXdrJson(),
      equals(
        '{"credit_alphanum4":{"asset_code":"ABCD","issuer":'
        '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}',
      ),
    );
  });

  test('sep-51: An undeclared key is refused', () {
    // Snippet from sep-51.md "Undeclared keys are refused"
    expect(
      () =>
          XdrTimeBounds.fromXdrJson('{"min_time":"0","max_time":"1","foo":2}'),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('has the unknown key "foo"'),
        ),
      ),
    );

    // Several are reported together, in sorted order.
    expect(
      () => XdrTimeBounds.fromXdrJson(
        '{"min_time":"0","max_time":"1","zeta":2,"alpha":3}',
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('has the unknown keys "alpha", "zeta"'),
        ),
      ),
    );
  });

  test('sep-51: Only the canonical rendering is accepted', () {
    // Snippet from sep-51.md "Input strictness"
    Map<String, String> reported = <String, String>{};

    void report(String label, void Function() read) {
      try {
        read();
        reported[label] = 'accepted';
      } on FormatException catch (e) {
        reported[label] = e.message;
      }
    }

    report('uppercase hex', () => XdrDataValue.fromXdrJson('"DEADBEEF"'));
    report('odd-length hex', () => XdrDataValue.fromXdrJson('"deadbee"'));
    report(
      'leading zero',
      () => XdrTimeBounds.fromXdrJson('{"min_time":"007","max_time":"0"}'),
    );
    report(
      'repeated key',
      () => XdrTimeBounds.fromXdrJson(
        '{"min_time":"1","min_time":"2","max_time":"3"}',
      ),
    );

    expect(
      reported['uppercase hex'],
      contains('expects lowercase hexadecimal digits'),
    );
    expect(
      reported['odd-length hex'],
      contains('has an odd number of hexadecimal digits'),
    );
    expect(
      reported['leading zero'],
      contains('expects a base-10 uint64 string but found "007"'),
    );
    expect(
      reported['repeated key'],
      contains('repeats the object key "min_time"'),
    );
  });

  test('sep-51: Nesting is bounded', () {
    // Snippet from sep-51.md "Input strictness"
    expect(XdrJsonHelper.maxDepth, equals(128));

    String tooDeep = '${'{"not":' * 129}"unconditional"${'}' * 129}';

    expect(
      () => XdrClaimPredicate.fromXdrJson(tooDeep),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('nests JSON containers more than 128 deep'),
        ),
      ),
    );
  });

  test('sep-51: Byte equality and value equality are different questions', () {
    // Snippet from sep-51.md "Comparing documents"
    String canonical = '{"text":"hello"}';
    String spaced = '{ "text" : "hello" }';

    expect(canonical == spaced, isFalse);

    // Reading both into the XDR type and re-emitting gives one text.
    XdrMemo fromCanonical = XdrMemo.fromXdrJson(canonical);
    XdrMemo fromSpaced = XdrMemo.fromXdrJson(spaced);
    expect(fromCanonical.toXdrJson(), equals(fromSpaced.toXdrJson()));
    expect(fromSpaced.toXdrJson(), equals(canonical));

    // A producer that orders the struct keys differently is accepted, and the
    // output carries the declared order either way.
    expect(
      XdrTimeBounds.fromXdrJson('{"max_time":"1","min_time":"0"}').toXdrJson(),
      equals('{"min_time":"0","max_time":"1"}'),
    );
  });

  test('sep-51: Error handling', () {
    // Snippet from sep-51.md "Error handling"
    try {
      XdrTimeBounds.fromXdrJson('{"min_time":"0"}');
      fail('expected a FormatException');
    } on FormatException catch (e) {
      expect(
        e.message,
        contains('XdrTimeBounds is missing the required key "max_time"'),
      );
    }

    // Text that is not JSON at all arrives as the same exception type.
    expect(
      () => XdrTimeBounds.fromXdrJson('{'),
      throwsA(isA<FormatException>()),
    );
  });

  test('sep-51: Non-UTF-8 bytes cannot reach a text member', () {
    // Snippet from sep-51.md "Limitations"
    // A `string<>` member is Dart text, and 0xc3 alone is not valid UTF-8.
    expect(
      () => XdrManageDataOp.fromXdrJson(
        r'{"data_name":"\\xc3","data_value":null}',
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('not valid UTF-8'),
        ),
      ),
    );

    // The same bytes in an opaque member are just bytes and round-trip.
    expect(XdrDataValue.fromXdrJson('"c3"').toXdrJson(), equals('"c3"'));
  });

  test('sep-51: A JSON number is accepted for a 64-bit field below 2^53', () {
    // Snippet from sep-51.md "Limitations"
    XdrTimeBounds v1Document = XdrTimeBounds.fromXdrJson(
      '{"min_time":9007199254740992,"max_time":0}',
    );

    expect(v1Document.minTime.uint64, equals(BigInt.from(9007199254740992)));
    // What was read as a number is emitted as the string the current
    // specification requires.
    expect(
      v1Document.toXdrJson(),
      equals('{"min_time":"9007199254740992","max_time":"0"}'),
    );

    expect(
      () => XdrTimeBounds.fromXdrJson(
        '{"min_time":9007199254740994,"max_time":0}',
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('which a JSON number cannot carry exactly'),
        ),
      ),
    );
  });

  test('sep-51: Inline fixed opaque renders as hex, not a byte array', () {
    // Snippet from sep-51.md "Divergences from the reference implementation"
    XdrPeerAddress peer = XdrPeerAddress.fromBase64EncodedXdrString(
      'AAAAAH8AAAEAAC1pAAAAAw==',
    );

    expect(
      peer.toXdrJson(),
      equals(
        '{"ip":{"i_pv4":"7f000001"},"port":11625,'
        '"num_failures":3}',
      ),
    );

    XdrShortHashSeed seed = XdrShortHashSeed.fromBase64EncodedXdrString(
      'AQIDBAUGBwgJCgsMDQ4PEA==',
    );
    expect(
      seed.toXdrJson(),
      equals('{"seed":"0102030405060708090a0b0c0d0e0f10"}'),
    );
  });

  test('sep-51: A standalone 64-bit value renders as a string', () {
    // Snippet from sep-51.md "Divergences from the reference implementation"
    expect(XdrInt64.fromXdrJson('"-1"').toXdrJson(), equals('"-1"'));
    expect(
      XdrInt64.fromXdrJson('"-1"').toBase64EncodedXdrString(),
      equals('//////////8='),
    );
  });

  test('sep-51: An empty signed payload has no strkey rendering', () {
    // Snippet from sep-51.md "Divergences from the reference implementation"
    expect(
      () => XdrSignerKey.fromXdrJson(
        '"PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAED2A"',
      ),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          contains('Encoded string must be 69 to 165 characters, got 63'),
        ),
      ),
    );

    // A payload of one to sixty-four bytes renders and reads back normally.
    expect(
      XdrSignerKey.fromXdrJson(
        '"PAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSAAAAAACACAQDATYOS"',
      ).toXdrJson(),
      equals(
        '"PAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPSAAAAAACACAQDATYOS"',
      ),
    );
  });
}
