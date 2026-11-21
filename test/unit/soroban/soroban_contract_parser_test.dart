// Test SorobanContractParser and related classes
// These tests validate contract metadata parsing, info extraction, and helper methods
// without making any network calls

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SorobanContractParserFailed', () {
    test('creates exception with message', () {
      final exception = SorobanContractParserFailed(
        'invalid byte code: test error',
      );

      expect(exception.toString(), equals('invalid byte code: test error'));
    });

    test('creates exception with different message', () {
      final exception = SorobanContractParserFailed(
        'environment meta not found',
      );

      expect(exception.toString(), equals('environment meta not found'));
    });
  });

  group('SorobanContractInfo', () {
    test('creates with basic spec entries', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.envProtocolVersion, equals(1));
      expect(info.envPreReleaseVersion, equals(0));
      expect(info.specEntries, equals(specEntries));
      expect(info.metaEntries, equals(metaEntries));
      expect(info.supportedSeps, isEmpty);
      expect(info.funcs, isEmpty);
      expect(info.udtStructs, isEmpty);
      expect(info.udtUnions, isEmpty);
      expect(info.udtEnums, isEmpty);
      expect(info.udtErrorEnums, isEmpty);
      expect(info.events, isEmpty);
    });

    test('extracts supported SEPs from meta entries', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': '1, 10, 24, 47'};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.supportedSeps, equals(['1', '10', '24', '47']));
    });

    test('handles SEPs with extra whitespace', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': '  1 ,  10  ,  24  '};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.supportedSeps, equals(['1', '10', '24']));
    });

    test('removes duplicate SEPs', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': '1, 10, 1, 24, 10'};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.supportedSeps.length, equals(3));
      expect(info.supportedSeps.contains('1'), isTrue);
      expect(info.supportedSeps.contains('10'), isTrue);
      expect(info.supportedSeps.contains('24'), isTrue);
    });

    test('handles empty SEP string', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': ''};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.supportedSeps, isEmpty);
    });

    test('handles missing SEP entry', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'name': 'Test Contract'};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.supportedSeps, isEmpty);
    });

    test('handles SEP string with only commas and spaces', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': ' , , , '};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.supportedSeps, isEmpty);
    });

    test('extracts function entries from spec', () {
      final functionEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      functionEntry.functionV0 = XdrSCSpecFunctionV0(
        '',
        'testFunction',
        [],
        [],
      );
      final specEntries = [functionEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.funcs.length, equals(1));
      expect(info.funcs[0].name, equals('testFunction'));
    });

    test('extracts multiple function entries', () {
      final func1 = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      func1.functionV0 = XdrSCSpecFunctionV0('', 'func1', [], []);

      final func2 = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      func2.functionV0 = XdrSCSpecFunctionV0('', 'func2', [], []);

      final specEntries = [func1, func2];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.funcs.length, equals(2));
      expect(info.funcs[0].name, equals('func1'));
      expect(info.funcs[1].name, equals('func2'));
    });

    test('ignores function entry with null functionV0', () {
      final funcEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      final specEntries = [funcEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.funcs, isEmpty);
    });

    test('extracts UDT struct entries', () {
      final structEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0,
      );
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'TestStruct', []);

      final specEntries = [structEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.udtStructs.length, equals(1));
      expect(info.udtStructs[0].name, equals('TestStruct'));
    });

    test('extracts UDT union entries', () {
      final unionEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0,
      );
      unionEntry.udtUnionV0 = XdrSCSpecUDTUnionV0('', '', 'TestUnion', []);

      final specEntries = [unionEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.udtUnions.length, equals(1));
      expect(info.udtUnions[0].name, equals('TestUnion'));
    });

    test('extracts UDT enum entries', () {
      final enumEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0,
      );
      enumEntry.udtEnumV0 = XdrSCSpecUDTEnumV0('', '', 'TestEnum', []);

      final specEntries = [enumEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.udtEnums.length, equals(1));
      expect(info.udtEnums[0].name, equals('TestEnum'));
    });

    test('extracts UDT error enum entries', () {
      final errorEnumEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0,
      );
      errorEnumEntry.udtErrorEnumV0 = XdrSCSpecUDTErrorEnumV0(
        '',
        '',
        'TestError',
        [],
      );

      final specEntries = [errorEnumEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.udtErrorEnums.length, equals(1));
      expect(info.udtErrorEnums[0].name, equals('TestError'));
    });

    test('extracts event entries', () {
      final eventEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0,
      );
      eventEntry.eventV0 = XdrSCSpecEventV0(
        '',
        '',
        'TestEvent',
        [],
        [],
        XdrSCSpecEventDataFormat(0),
      );

      final specEntries = [eventEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.events.length, equals(1));
      expect(info.events[0].name, equals('TestEvent'));
    });

    test('handles mixed spec entry types', () {
      final funcEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'testFunc', [], []);

      final structEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0,
      );
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'TestStruct', []);

      final eventEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0,
      );
      eventEntry.eventV0 = XdrSCSpecEventV0(
        '',
        '',
        'TestEvent',
        [],
        [],
        XdrSCSpecEventDataFormat(0),
      );

      final specEntries = [funcEntry, structEntry, eventEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.funcs.length, equals(1));
      expect(info.udtStructs.length, equals(1));
      expect(info.events.length, equals(1));
      expect(info.udtUnions, isEmpty);
      expect(info.udtEnums, isEmpty);
      expect(info.udtErrorEnums, isEmpty);
    });

    test('handles complex meta entries', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {
        'name': 'My Contract',
        'version': '1.0.0',
        'description': 'Test contract for unit tests',
        'sep': '1, 41',
        'author': 'Test Author',
      };

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.metaEntries['name'], equals('My Contract'));
      expect(info.metaEntries['version'], equals('1.0.0'));
      expect(
        info.metaEntries['description'],
        equals('Test contract for unit tests'),
      );
      expect(info.metaEntries['author'], equals('Test Author'));
      expect(info.supportedSeps, equals(['1', '41']));
    });

    test('preserves original spec entries', () {
      final funcEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'testFunc', [], []);

      final specEntries = [funcEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.specEntries, equals(specEntries));
      expect(info.specEntries.length, equals(1));
    });

    test('handles high interface version', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(999, 42, specEntries, metaEntries);

      expect(info.envProtocolVersion, equals(999));
      expect(info.envPreReleaseVersion, equals(42));
    });

    test('extracts only non-null entries', () {
      final validFunc = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      validFunc.functionV0 = XdrSCSpecFunctionV0('', 'valid', [], []);

      final invalidFunc = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );

      final validStruct = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0,
      );
      validStruct.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'Valid', []);

      final invalidStruct = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0,
      );

      final specEntries = [validFunc, invalidFunc, validStruct, invalidStruct];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, 0, specEntries, metaEntries);

      expect(info.funcs.length, equals(1));
      expect(info.udtStructs.length, equals(1));
    });
  });

  group('SorobanContractParser static helpers', () {
    test('parseSupportedSeps handles single SEP', () {
      final metaEntries = {'sep': '41'};
      final info = SorobanContractInfo(1, 0, [], metaEntries);

      expect(info.supportedSeps, equals(['41']));
    });

    test('parseSupportedSeps handles trailing comma', () {
      final metaEntries = {'sep': '1, 10, 24,'};
      final info = SorobanContractInfo(1, 0, [], metaEntries);

      expect(info.supportedSeps, equals(['1', '10', '24']));
    });

    test('parseSupportedSeps handles leading comma', () {
      final metaEntries = {'sep': ',1, 10'};
      final info = SorobanContractInfo(1, 0, [], metaEntries);

      expect(info.supportedSeps, equals(['1', '10']));
    });

    test('extractFunctions handles empty list', () {
      final info = SorobanContractInfo(1, 0, [], {});

      expect(info.funcs, isEmpty);
    });

    test('extractFunctions filters non-function entries', () {
      final structEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0,
      );
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'Struct', []);

      final funcEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'func', [], []);

      final info = SorobanContractInfo(1, 0, [structEntry, funcEntry], {});

      expect(info.funcs.length, equals(1));
      expect(info.funcs[0].name, equals('func'));
    });

    test('extractUdtStructs filters non-struct entries', () {
      final funcEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0,
      );
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'func', [], []);

      final structEntry = XdrSCSpecEntry(
        XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0,
      );
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'Struct', []);

      final info = SorobanContractInfo(1, 0, [funcEntry, structEntry], {});

      expect(info.udtStructs.length, equals(1));
      expect(info.udtStructs[0].name, equals('Struct'));
    });
  });

  group('SorobanContractParser parseContractByteCode', () {
    test('throws exception on invalid bytecode', () {
      final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02]);

      expect(
        () => SorobanContractParser.parseContractByteCode(invalidBytes),
        throwsA(isA<SorobanContractParserFailed>()),
      );
    });

    test('throws exception on empty bytecode', () {
      final emptyBytes = Uint8List(0);

      expect(
        () => SorobanContractParser.parseContractByteCode(emptyBytes),
        throwsA(isA<SorobanContractParserFailed>()),
      );
    });

    test('throws specific error for missing environment meta', () {
      final invalidBytes = Uint8List.fromList([
        0x00,
        0x61,
        0x73,
        0x6d,
        0x01,
        0x00,
        0x00,
        0x00,
      ]);

      try {
        SorobanContractParser.parseContractByteCode(invalidBytes);
        fail('Should have thrown SorobanContractParserFailed');
      } catch (e) {
        expect(e, isA<SorobanContractParserFailed>());
        expect(e.toString(), contains('environment meta not found'));
      }
    });
  });

  group('SorobanContractParser - Error Handling', () {
    final env20 = _envMeta(20);
    final funcTest = _function('test');
    final env = _custom('contractenvmetav0', env20);
    final spec = _custom('contractspecv0', funcTest);
    List<int> meta(List<int> content) => _custom('contractmetav0', content);
    // The same sections as bare markers, without wasm framing, fail at the
    // header.
    final markerEnv = 'contractenvmetav0'.codeUnits + env20;
    final markerSpec = 'contractspecv0'.codeUnits + funcTest;
    List<int> markerMeta(List<int> content) =>
        'contractmetav0'.codeUnits + content;
    const noHeader =
        'invalid byte code: the wasm magic at byte offset 0 is 636f6e74, '
        'expected 0061736d.';

    for (final (name, framed, unframed, metaEntries) in [
      (
        'the environment meta and the spec',
        [env, spec],
        [markerEnv, markerSpec],
        <String, String>{},
      ),
      (
        'meta before the environment meta',
        [meta(_kv('testKey', 'testValue')), env, spec],
        [markerMeta(_kv('testKey', 'testValue')), markerEnv, markerSpec],
        {'testKey': 'testValue'},
      ),
      (
        'meta between the environment meta and the spec',
        [env, meta(_kv('key2', 'value2')), spec],
        [markerEnv, markerMeta(_kv('key2', 'value2')), markerSpec],
        {'key2': 'value2'},
      ),
      (
        'meta after the spec',
        [env, spec, meta(_kv('key3', 'value3'))],
        [markerEnv, markerSpec, markerMeta(_kv('key3', 'value3'))],
        {'key3': 'value3'},
      ),
    ]) {
      test('reads $name from their sections', () {
        final result = _parse(_wasm(framed));
        expect(result.envProtocolVersion, 20);
        expect(result.specEntries.single.functionV0!.name, 'test');
        expect(result.metaEntries, metaEntries);
        final markerOnly = Uint8List.fromList([for (final p in unframed) ...p]);
        expect(() => _parse(markerOnly), _fails(noHeader));
      });
    }

    final invalid = 'invalid'.codeUnits;
    for (final (name, framed, message) in [
      (
        'a module without a spec section',
        [env],
        'invalid byte code: spec entries not found.',
      ),
      (
        'malformed environment meta',
        [
          _custom('contractenvmetav0', [0, 0, 0, ...invalid]),
        ],
        'invalid byte code: the contractenvmetav0 entry at byte offset 345 '
            'does not decode: Exception: Unknown enum value: 105',
      ),
      (
        'a malformed spec entry after a valid one',
        [
          env,
          _custom('contractspecv0', [...funcTest, 0, 0, 0, ...invalid]),
        ],
        'invalid byte code: the contractspecv0 entry at byte offset 398 '
            'does not decode: Exception: Unknown enum value: 105',
      ),
      (
        'an unsupported spec entry kind',
        [
          env,
          _custom('contractspecv0', [...funcTest, 0, 0, 0, 0xff]),
        ],
        'invalid byte code: the contractspecv0 entry at byte offset 398 '
            'does not decode: Exception: Unknown enum value: 255',
      ),
      (
        'a malformed meta entry after a valid one',
        [
          env,
          spec,
          meta([..._kv('key', 'value'), 0, 0, ...invalid]),
        ],
        'invalid byte code: the contractmetav0 entry at byte offset 439 '
            'does not decode: Exception: Unknown enum value: 26990',
      ),
      (
        'an unsupported meta kind',
        [
          env,
          spec,
          meta([0, 0, 0, 0xff]),
        ],
        'invalid byte code: the contractmetav0 entry at byte offset 415 '
            'does not decode: Exception: Unknown enum value: 255',
      ),
    ]) {
      test('rejects $name', () {
        expect(() => _parse(_wasm(framed)), _fails(message));
      });
    }
  });

  group('SorobanContractParser section bounds', () {
    final helloSpec = _decodeAll(_specContent, XdrSCSpecEntry.decode);
    final helloMeta = {
      for (final e in _decodeAll(_metaContent, XdrSCMetaEntry.decode))
        e.v0!.key: e.v0!.val,
    };
    final other = _function('other');
    final env99 = _envMeta(99);
    final kv = _kv('k', 'v');
    final spec = _custom('contractspecv0', _specContent);
    final env = _custom('contractenvmetav0', _envMetaContent);
    final meta = _custom('contractmetav0', _metaContent);
    Uint8List before(List<int> section) => _wasm([section, spec, env, meta]);
    Uint8List after(List<int> section) => _wasm([env, meta, section]);

    test('reads the hello world module as its sections hold it', () {
      final info = _parse(_helloWorld);
      final envMeta = _decodeAll(_envMetaContent, XdrSCEnvMetaEntry.decode);
      expect(_xdrOf(info.specEntries), _xdrOf(helloSpec));
      expect(info.specEntries.single.functionV0!.name, 'hello');
      expect(
        info.envProtocolVersion,
        envMeta.single.interfaceVersion!.protocol.uint32,
      );
      expect(info.metaEntries, helloMeta);
    });

    test('reads a spec section followed by another custom section', () {
      final name = _custom('name', const [1, 2, 3]);
      final info = _parse(_wasm([spec, name, env, meta]));
      expect(_xdrOf(info.specEntries), _xdrOf(helloSpec));
    });

    test('decodes every entry of a section up to the section end', () {
      final specContent = _specContent + other;
      final info = _parse(
        _wasm([
          _custom('contractspecv0', specContent),
          _custom('contractenvmetav0', _envMetaContent + env99),
          _custom('contractmetav0', _metaContent + kv),
        ]),
      );
      final expected = _decodeAll(specContent, XdrSCSpecEntry.decode);
      expect(expected, hasLength(2));
      expect(_xdrOf(info.specEntries), _xdrOf(expected));
      expect(info.envProtocolVersion, 20);
      expect(info.metaEntries, {...helloMeta, 'k': 'v'});
    });

    test('uses the first spec and environment meta section and every '
        'meta section', () {
      final info = _parse(
        _wasm([
          spec,
          _custom('contractspecv0', other),
          env,
          _custom('contractenvmetav0', env99),
          meta,
          _custom('contractmetav0', kv + _kv('rsver', '2')),
        ]),
      );
      expect(_xdrOf(info.specEntries), _xdrOf(helloSpec));
      expect(info.envProtocolVersion, 20);
      // The second meta section is read after the first, and a later entry
      // replaces an earlier one with the same key.
      expect(info.metaEntries.keys, [...helloMeta.keys, 'k']);
      expect(info.metaEntries, {...helloMeta, 'rsver': '2', 'k': 'v'});
    });

    for (final (name, metaSections) in [
      ('one meta section', [_kv('sep', '41') + _kv('sep', '40,46')]),
      ('two meta sections', [_kv('sep', '41'), _kv('sep', '40,46')]),
    ]) {
      test('joins the values of repeated sep entries in $name', () {
        final metas = [
          for (final m in metaSections) _custom('contractmetav0', m),
        ];
        final info = _parse(_wasm([spec, env, ...metas]));
        expect(info.metaEntries['sep'], '41,40,46');
        expect(info.supportedSeps, ['41', '40', '46']);
      });
    }

    test('never starts the spec at marker bytes inside a data segment', () {
      // One active data segment for memory 0 at offset 0.
      final segment = 'contractspecv0'.codeUnits + other;
      final data = [1, 0, 0x41, 0, 0x0b, ..._leb(segment.length), ...segment];
      final info = _parse(before([11, ..._leb(data.length), ...data]));
      expect(_xdrOf(info.specEntries), _xdrOf(helloSpec));
    });

    test('accepts padded LEB128 sizes and name lengths', () {
      // A custom section with an empty name whose length is 0 in five bytes,
      // the spec section size 67 and the meta name length 14 in five bytes.
      final emptyName = [0, 5, 0x80, 0x80, 0x80, 0x80, 0];
      final paddedSpec = [0, 0xc3, 0x80, 0x80, 0x80, 0, 14]
        ..addAll('contractspecv0'.codeUnits + _specContent);
      final paddedMeta = [0, 115, 0x8e, 0x80, 0x80, 0x80, 0]
        ..addAll('contractmetav0'.codeUnits + _metaContent);
      final info = _parse(_wasm([emptyName, paddedSpec, env, paddedMeta]));
      expect(_xdrOf(info.specEntries), _xdrOf(helloSpec));
      expect(info.metaEntries, helloMeta);
    });

    // Each entry error names the module offset of the entry; the hello world
    // spec content starts at 342 and its one entry ends at 394.
    Matcher entryAt(String section, int offset, String cause) => _fails(
      startsWith(
        'invalid byte code: the $section entry at byte offset $offset '
        'does not decode: $cause',
      ),
    );
    Matcher framing(String detail) => _fails('invalid byte code: $detail');
    Uint8List withSpec(List<int> content) =>
        _wasm([_custom('contractspecv0', content), env, meta]);
    final ffDoc = [0, 0, 0, 0, 0, 0, 0, 1, 0xff, 0, 0, 0]
      ..addAll(_specContent.sublist(8));
    final ffValue = [0, 0, 0, 0, 0, 0, 0, 1, 0x6b, 0, 0, 0, 0, 0, 0, 1]
      ..addAll([0xff, 0, 0, 0]);
    final rangeError = 'RangeError: XDR read of 4 bytes exceeds the';
    for (final (name, bytes, matcher) in [
      (
        'a spec entry whose doc holds the byte ff',
        withSpec([..._specContent, ...ffDoc]),
        entryAt('contractspecv0', 394, 'FormatException: '),
      ),
      (
        'a meta value holding the byte ff in a second meta section',
        _wasm([spec, env, meta, _custom('contractmetav0', kv + ffValue)]),
        entryAt('contractmetav0', 576, 'FormatException: '),
      ),
      (
        'an unknown spec entry kind',
        withSpec([..._specContent, 0, 0, 0, 6]),
        entryAt('contractspecv0', 394, 'Exception: Unknown enum value: 6'),
      ),
      (
        'bytes after the last spec entry',
        withSpec([..._specContent, 0, 0]),
        entryAt('contractspecv0', 394, '$rangeError 2 remaining bytes'),
      ),
      (
        'bytes after the last environment meta entry',
        _wasm([
          spec,
          _custom('contractenvmetav0', [..._envMetaContent, 0, 0, 0, 0, 0]),
          meta,
        ]),
        entryAt('contractenvmetav0', 426, '$rangeError 1 remaining bytes'),
      ),
      (
        'bytes after the last meta entry',
        _wasm([
          spec,
          env,
          _custom('contractmetav0', [..._metaContent, 0, 0, 0, 0, 0, 0, 0, 9]),
        ]),
        entryAt(
          'contractmetav0',
          539,
          'RangeError: XDR byte count 9 exceeds the 0 remaining bytes',
        ),
      ),
      (
        'a meta entry split across two meta sections',
        _wasm([
          spec,
          env,
          _custom('contractmetav0', _metaContent + kv.sublist(0, 8)),
          _custom('contractmetav0', kv.sublist(8)),
        ]),
        entryAt(
          'contractmetav0',
          539,
          'RangeError: XDR byte count 1 exceeds the 0 remaining bytes',
        ),
      ),
      (
        'an empty first environment meta section before a valid one',
        _wasm([spec, _custom('contractenvmetav0', const []), env, meta]),
        _fails('invalid byte code: environment meta not found.'),
      ),
      (
        'a section size past the end before the spec section',
        before([11, 0xe8, 0x07]),
        framing(
          'the section with id 11 at byte offset 325 declares 1000 bytes, '
          'but 214 bytes remain.',
        ),
      ),
      (
        'a name length cut by its section before the spec section',
        before([0, 1, 0x8e]),
        framing(
          'the name length of the custom section at byte offset 325 ends at '
          'byte offset 328 before its last byte.',
        ),
      ),
      (
        'a spec section whose size runs past the end',
        after(_custom('contractspecv0', _specContent)..[1] = 68),
        framing(
          'the section with id 0 at byte offset 470 declares 68 bytes, '
          'but 67 bytes remain.',
        ),
      ),
      (
        'a section size cut by the end of the module',
        after(const [0, 0xc3]),
        framing(
          'the size of the section at byte offset 470 ends at byte offset '
          '472 before its last byte.',
        ),
      ),
      (
        'a section size past the end after the contract sections',
        Uint8List.fromList([..._helloWorld, 11, 0xe8, 0x07]),
        framing(
          'the section with id 11 at byte offset 539 declares 1000 bytes, '
          'but 0 bytes remain.',
        ),
      ),
      (
        'a wrong wasm magic',
        Uint8List.fromList(_helloWorld)..[3] = 0x6e,
        framing(
          'the wasm magic at byte offset 0 is 0061736e, expected 0061736d.',
        ),
      ),
      (
        'a wrong wasm version',
        Uint8List.fromList(_helloWorld)..[4] = 2,
        framing(
          'the wasm version at byte offset 4 is 02000000, expected 01000000.',
        ),
      ),
      (
        'fewer bytes than the wasm header',
        _helloWorld.sublist(0, 7),
        framing(
          'the 7 bytes at byte offset 0 are shorter than the 8-byte wasm '
          'header.',
        ),
      ),
      (
        'a fifth LEB128 byte beyond the u32 range',
        before([11, 0xff, 0xff, 0xff, 0xff, 0x1f]),
        framing(
          'the size of the section at byte offset 325 exceeds the u32 range.',
        ),
      ),
      (
        'a six-byte LEB128',
        before([11, 0x80, 0x80, 0x80, 0x80, 0x80, 0]),
        framing(
          'the size of the section at byte offset 325 is longer than 5 bytes.',
        ),
      ),
      (
        'the largest u32 size',
        before([11, 0xff, 0xff, 0xff, 0xff, 0x0f]),
        framing(
          'the section with id 11 at byte offset 325 declares 4294967295 '
          'bytes, but 214 bytes remain.',
        ),
      ),
      (
        'a custom section name past its section end',
        before([0, 3, 14, 0x63, 0x6f]),
        framing(
          'the custom section at byte offset 325 declares a 14-byte name, '
          'but 2 bytes of the section remain.',
        ),
      ),
    ]) {
      test('rejects $name', () {
        expect(() => _parse(bytes), matcher);
      });
    }
  });
}

// test/wasm/soroban_hello_world_contract.wasm, embedded because browser tests
// cannot read a file fixture.
final _helloWorld = base64Decode(
  'AGFzbQEAAAABDwNgAn5+AX5gAX4BfmAAAAIHAQF2AWcAAAMDAgECBQMBABAGGQN/AUGAgMAA'
  'C38AQYCAwAALfwBBgIDAAAsHMQUGbWVtb3J5AgAFaGVsbG8AAQFfAAIKX19kYXRhX2VuZAMB'
  'C19faGVhcF9iYXNlAwIKyAECwgEBAn8jgICAgABBIGsiASSAgICAAAJAAkAgAKdB/wFxIgJB'
  'DkYNACACQcoARw0BCyABIAA3AwggAUKO6PHYugI3AwBBACECA0ACQCACQRBHDQBBACECAkAD'
  'QCACQRBGDQEgAUEQaiACaiABIAJqKQMANwMAIAJBCGohAgwACwsgAUEQaq1CIIZCBIRChICA'
  'gCAQgICAgAAhACABQSBqJICAgIAAIAAPCyABQRBqIAJqQgI3AwAgAkEIaiECDAALCwAACwIA'
  'CwBDDmNvbnRyYWN0c3BlY3YwAAAAAAAAAAAAAAAFaGVsbG8AAAAAAAABAAAAAAAAAAJ0bwAA'
  'AAAAEQAAAAEAAAPqAAAAEQAeEWNvbnRyYWN0ZW52bWV0YXYwAAAAAAAAABQAAAAAAG8OY29u'
  'dHJhY3RtZXRhdjAAAAAAAAAABXJzdmVyAAAAAAAABjEuNzQuMQAAAAAAAAAAAAhyc3Nka3Zl'
  'cgAAAC8yMC4wLjAjODIyY2U2Y2MzZTQ2MWNjYzkyNTI3NWI0NzJkNzdiNmNhMzViMmNkOQA=',
);

// From the module's section table: the header and the non-custom sections
// end at offset 325, followed by the contents of contractspecv0,
// contractenvmetav0 and contractmetav0.
final _code = _helloWorld.sublist(0, 325);
final _specContent = _helloWorld.sublist(342, 394);
final _envMetaContent = _helloWorld.sublist(414, 426);
final _metaContent = _helloWorld.sublist(443, 539);

SorobanContractInfo _parse(Uint8List byteCode) =>
    SorobanContractParser.parseContractByteCode(byteCode);

Matcher _fails(Object message) => throwsA(
  isA<SorobanContractParserFailed>().having(
    (e) => e.toString(),
    'message',
    message,
  ),
);

List<int> _leb(int value) {
  final bytes = <int>[];
  for (; value >= 0x80; value >>= 7) {
    bytes.add((value & 0x7f) | 0x80);
  }
  return bytes..add(value);
}

List<int> _custom(String name, List<int> content) {
  final payload = [..._leb(name.length), ...name.codeUnits, ...content];
  return [0, ..._leb(payload.length), ...payload];
}

/// The hello world module's header and non-custom sections, then [sections].
Uint8List _wasm(List<List<int>> sections) =>
    Uint8List.fromList([..._code, for (final s in sections) ...s]);

List<int> _xdr(void Function(XdrDataOutputStream stream) write) {
  final stream = XdrDataOutputStream();
  write(stream);
  return stream.bytes;
}

List<int> _envMeta(int protocol) => _xdr(
  (s) => XdrSCEnvMetaEntry.encode(
    s,
    XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION)
      ..interfaceVersion = XdrSCEnvMetaEntryInterfaceVersion(
        XdrUint32(protocol),
        XdrUint32(0),
      ),
  ),
);

List<int> _function(String name) => _xdr(
  (s) => XdrSCSpecEntry.encode(
    s,
    XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0)
      ..functionV0 = XdrSCSpecFunctionV0('', name, [], []),
  ),
);

List<int> _kv(String key, String value) => _xdr(
  (s) => XdrSCMetaEntry.encode(
    s,
    XdrSCMetaEntry(XdrSCMetaKind.SC_META_V0)..v0 = XdrSCMetaV0(key, value),
  ),
);

/// Decodes [content] entry by entry with the XDR type alone.
List<T> _decodeAll<T>(
  List<int> content,
  T Function(XdrDataInputStream stream) decode,
) {
  final stream = XdrDataInputStream(Uint8List.fromList(content));
  final entries = <T>[];
  while (stream.offset! < content.length) {
    entries.add(decode(stream));
  }
  return entries;
}

List<String> _xdrOf(List<XdrSCSpecEntry> entries) => [
  for (final e in entries) e.toBase64EncodedXdrString(),
];
