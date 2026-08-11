import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// The optional `$schema` property of SEP-0051 §JSON Schema.
///
/// The section says that all JSON objects should allow, but not require, a
/// `$schema` property whose value is the URL of a JSON Schema document for the
/// type. This SDK reads it as follows, and these are SDK rules, stated here so
/// that the reading is pinned rather than assumed:
///
/// - it is accepted wherever an object is accepted, at any nesting depth;
/// - it is removed before anything else looks at the object, so it never counts
///   as a component of a struct nor as the single key of a union arm;
/// - it is never emitted, because this SDK publishes no schema documents;
/// - it carries no other privilege: an object that holds nothing but `$schema`
///   is an object that holds nothing, and a struct still requires its
///   components while a union arm still requires its one key.
///
/// It is the one key this decoder accepts that no XDR type declares. Every other
/// key a type does not declare is refused.
const String _assetSchemaUrl =
    'https://stellar.org/schema/xdr-json/main/Asset.json';

const String _ttlSchemaUrl =
    'https://stellar.org/schema/xdr-json/main/TtlEntry.json';

/// struct TtlEntry, from SEP-0051 §Struct.
const String _ttlBase64 = 'AQIDBAUGBwgJEBESExQVFhcYGSAhIiMkJSYnKCkwMTIAAAAB';
const String _ttlJson =
    '{"key_hash":'
    '"0102030405060708091011121314151617181920212223242526272829303132",'
    '"live_until_ledger_seq":1}';

/// The union document of SEP-0051 §JSON Schema, quoted as the section prints it.
const String _assetWithSchema =
    r'{"$schema":"https://stellar.org/schema/xdr-json/main/Asset.json",'
    '"credit_alphanum4":{"asset_code":"ABCD","issuer":'
    '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';

const String _assetJson =
    '{"credit_alphanum4":{"asset_code":"ABCD","issuer":'
    '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';

const String _assetBase64 =
    'AAAAAUFCQ0QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

void main() {
  group('the schema property is accepted', () {
    test('on the top-level object of a struct', () {
      final String document = _ttlJson.replaceFirst(
        '{',
        '{"\$schema":"$_ttlSchemaUrl",',
      );
      expect(XdrTTLEntry.fromXdrJson(document).toXdrJson(), _ttlJson);
      expect(
        XdrTTLEntry.fromXdrJson(document).toBase64EncodedXdrString(),
        _ttlBase64,
      );
    });

    test('on the object a union arm carries', () {
      // The section prints this document for the Asset type.
      expect(XdrAsset.fromXdrJson(_assetWithSchema).toXdrJson(), _assetJson);
      expect(
        XdrAsset.fromXdrJson(_assetWithSchema).toBase64EncodedXdrString(),
        _assetBase64,
      );
    });

    test('on a nested object, not only on the outermost one', () {
      const String document =
          '{"credit_alphanum4":{"\$schema":"$_assetSchemaUrl",'
          '"asset_code":"ABCD","issuer":'
          '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';
      expect(XdrAsset.fromXdrJson(document).toXdrJson(), _assetJson);
    });

    test('on the outer object and a nested one at once', () {
      const String document =
          '{"\$schema":"$_assetSchemaUrl","credit_alphanum4":'
          '{"\$schema":"$_assetSchemaUrl","asset_code":"ABCD","issuer":'
          '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"}}';
      expect(
        XdrAsset.fromXdrJson(document).toBase64EncodedXdrString(),
        _assetBase64,
      );
    });

    test('on an object inside an array', () {
      const String base64 = 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAA=';
      const String document =
          '{"fee_charged":"100","result":{"tx_success":'
          '[{"\$schema":"https://stellar.org/schema/xdr-json/main/'
          'OperationResult.json","op_inner":{"create_account":"success"}}]},'
          '"ext":"v0"}';
      expect(
        XdrTransactionResult.fromXdrJson(document).toBase64EncodedXdrString(),
        base64,
      );
    });

    test('but is not required', () {
      expect(XdrTTLEntry.fromXdrJson(_ttlJson).toXdrJson(), _ttlJson);
    });
  });

  group('the schema property is never emitted', () {
    test('for a value read from binary', () {
      expect(
        XdrTTLEntry.fromBase64EncodedXdrString(_ttlBase64).toXdrJson(),
        isNot(contains(r'$schema')),
      );
    });

    test('for a value read from a document that supplied it', () {
      final String document = _ttlJson.replaceFirst(
        '{',
        '{"\$schema":"$_ttlSchemaUrl",',
      );
      expect(
        XdrTTLEntry.fromXdrJson(document).toXdrJson(),
        isNot(contains(r'$schema')),
      );
      expect(
        XdrAsset.fromXdrJson(_assetWithSchema).toXdrJson(),
        isNot(contains(r'$schema')),
      );
    });

    test('in the tree form, not only in the rendered text', () {
      final Object? value = XdrTTLEntry.fromXdrJson(
        _ttlJson.replaceFirst('{', '{"\$schema":"$_ttlSchemaUrl",'),
      ).toXdrJsonValue();
      expect((value! as Map<String, Object?>).keys.toList(), <String>[
        'key_hash',
        'live_until_ledger_seq',
      ]);
    });
  });

  group('an object holding nothing but the schema property is refused', () {
    test('where a struct expects its components', () {
      expect(
        () => XdrTTLEntry.fromXdrJson('{"\$schema":"$_ttlSchemaUrl"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('where a union expects its one arm', () {
      expect(
        () => XdrAsset.fromXdrJson('{"\$schema":"$_assetSchemaUrl"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('where an empty object would also be refused', () {
      // The two failures are the same failure: after the property is removed
      // there is nothing left, so it cannot stand in for the value.
      expect(
        () => XdrTTLEntry.fromXdrJson('{}'),
        throwsA(isA<FormatException>()),
      );
      expect(() => XdrAsset.fromXdrJson('{}'), throwsA(isA<FormatException>()));
    });
  });

  group('the schema property carries no further licence', () {
    test('a struct still refuses a key it does not declare', () {
      final String document = _ttlJson.replaceFirst(
        '{',
        '{"\$schema":"$_ttlSchemaUrl","not_declared":1,',
      );
      expect(
        () => XdrTTLEntry.fromXdrJson(document),
        throwsA(isA<FormatException>()),
      );
    });

    test('a union still refuses a second arm beside it', () {
      const String document =
          '{"\$schema":"$_assetSchemaUrl","credit_alphanum4":'
          '{"asset_code":"ABCD","issuer":'
          '"GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF"},'
          '"native":null}';
      expect(
        () => XdrAsset.fromXdrJson(document),
        throwsA(isA<FormatException>()),
      );
    });

    test('a struct still requires every component', () {
      const String document =
          '{"\$schema":"$_ttlSchemaUrl","live_until_ledger_seq":1}';
      expect(
        () => XdrTTLEntry.fromXdrJson(document),
        throwsA(isA<FormatException>()),
      );
    });

    test('a value that does not render as an object still refuses one', () {
      // The section states the rule for JSON objects. A type rendered as a
      // string is not an object, so an object carrying the property is not a
      // document for it.
      expect(
        () => XdrAssetType.fromXdrJson('{"\$schema":"$_assetSchemaUrl"}'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => XdrSCAddress.fromXdrJson('{"\$schema":"$_assetSchemaUrl"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
