// Test SorobanContractParser and related classes
// These tests validate contract metadata parsing, info extraction, and helper methods
// without making any network calls

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SorobanContractParserFailed', () {
    test('creates exception with message', () {
      final exception =
          SorobanContractParserFailed('invalid byte code: test error');

      expect(exception.toString(), equals('invalid byte code: test error'));
    });

    test('creates exception with different message', () {
      final exception = SorobanContractParserFailed('environment meta not found');

      expect(exception.toString(), equals('environment meta not found'));
    });
  });

  group('SorobanContractInfo', () {
    test('creates with basic spec entries', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.envInterfaceVersion, equals(1));
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

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.supportedSeps, equals(['1', '10', '24', '47']));
    });

    test('handles SEPs with extra whitespace', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': '  1 ,  10  ,  24  '};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.supportedSeps, equals(['1', '10', '24']));
    });

    test('removes duplicate SEPs', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': '1, 10, 1, 24, 10'};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.supportedSeps.length, equals(3));
      expect(info.supportedSeps.contains('1'), isTrue);
      expect(info.supportedSeps.contains('10'), isTrue);
      expect(info.supportedSeps.contains('24'), isTrue);
    });

    test('handles empty SEP string', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': ''};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.supportedSeps, isEmpty);
    });

    test('handles missing SEP entry', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'name': 'Test Contract'};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.supportedSeps, isEmpty);
    });

    test('handles SEP string with only commas and spaces', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = {'sep': ' , , , '};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.supportedSeps, isEmpty);
    });

    test('extracts function entries from spec', () {
      final functionEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      functionEntry.functionV0 = XdrSCSpecFunctionV0(
        '',
        'testFunction',
        [],
        [],
      );
      final specEntries = [functionEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.funcs.length, equals(1));
      expect(info.funcs[0].name, equals('testFunction'));
    });

    test('extracts multiple function entries', () {
      final func1 = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      func1.functionV0 = XdrSCSpecFunctionV0('', 'func1', [], []);

      final func2 = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      func2.functionV0 = XdrSCSpecFunctionV0('', 'func2', [], []);

      final specEntries = [func1, func2];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.funcs.length, equals(2));
      expect(info.funcs[0].name, equals('func1'));
      expect(info.funcs[1].name, equals('func2'));
    });

    test('ignores function entry with null functionV0', () {
      final funcEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      final specEntries = [funcEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.funcs, isEmpty);
    });

    test('extracts UDT struct entries', () {
      final structEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'TestStruct', []);

      final specEntries = [structEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.udtStructs.length, equals(1));
      expect(info.udtStructs[0].name, equals('TestStruct'));
    });

    test('extracts UDT union entries', () {
      final unionEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = XdrSCSpecUDTUnionV0('', '', 'TestUnion', []);

      final specEntries = [unionEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.udtUnions.length, equals(1));
      expect(info.udtUnions[0].name, equals('TestUnion'));
    });

    test('extracts UDT enum entries', () {
      final enumEntry =
          XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = XdrSCSpecUDTEnumV0('', '', 'TestEnum', []);

      final specEntries = [enumEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.udtEnums.length, equals(1));
      expect(info.udtEnums[0].name, equals('TestEnum'));
    });

    test('extracts UDT error enum entries', () {
      final errorEnumEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0);
      errorEnumEntry.udtErrorEnumV0 =
          XdrSCSpecUDTErrorEnumV0('', '', 'TestError', []);

      final specEntries = [errorEnumEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.udtErrorEnums.length, equals(1));
      expect(info.udtErrorEnums[0].name, equals('TestError'));
    });

    test('extracts event entries', () {
      final eventEntry =
          XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0);
      eventEntry.eventV0 = XdrSCSpecEventV0('', '', 'TestEvent', [], [], XdrSCSpecEventDataFormat(0));

      final specEntries = [eventEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.events.length, equals(1));
      expect(info.events[0].name, equals('TestEvent'));
    });

    test('handles mixed spec entry types', () {
      final funcEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'testFunc', [], []);

      final structEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'TestStruct', []);

      final eventEntry =
          XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0);
      eventEntry.eventV0 = XdrSCSpecEventV0('', '', 'TestEvent', [], [], XdrSCSpecEventDataFormat(0));

      final specEntries = [funcEntry, structEntry, eventEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

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

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.metaEntries['name'], equals('My Contract'));
      expect(info.metaEntries['version'], equals('1.0.0'));
      expect(info.metaEntries['description'],
          equals('Test contract for unit tests'));
      expect(info.metaEntries['author'], equals('Test Author'));
      expect(info.supportedSeps, equals(['1', '41']));
    });

    test('preserves original spec entries', () {
      final funcEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'testFunc', [], []);

      final specEntries = [funcEntry];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.specEntries, equals(specEntries));
      expect(info.specEntries.length, equals(1));
    });

    test('handles high interface version', () {
      final specEntries = <XdrSCSpecEntry>[];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(999, specEntries, metaEntries);

      expect(info.envInterfaceVersion, equals(999));
    });

    test('extracts only non-null entries', () {
      final validFunc = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      validFunc.functionV0 = XdrSCSpecFunctionV0('', 'valid', [], []);

      final invalidFunc = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);

      final validStruct = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      validStruct.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'Valid', []);

      final invalidStruct = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);

      final specEntries = [validFunc, invalidFunc, validStruct, invalidStruct];
      final metaEntries = <String, String>{};

      final info = SorobanContractInfo(1, specEntries, metaEntries);

      expect(info.funcs.length, equals(1));
      expect(info.udtStructs.length, equals(1));
    });
  });

  group('SorobanContractParser static helpers', () {
    test('parseSupportedSeps handles single SEP', () {
      final metaEntries = {'sep': '41'};
      final info = SorobanContractInfo(1, [], metaEntries);

      expect(info.supportedSeps, equals(['41']));
    });

    test('parseSupportedSeps handles trailing comma', () {
      final metaEntries = {'sep': '1, 10, 24,'};
      final info = SorobanContractInfo(1, [], metaEntries);

      expect(info.supportedSeps, equals(['1', '10', '24']));
    });

    test('parseSupportedSeps handles leading comma', () {
      final metaEntries = {'sep': ',1, 10'};
      final info = SorobanContractInfo(1, [], metaEntries);

      expect(info.supportedSeps, equals(['1', '10']));
    });

    test('extractFunctions handles empty list', () {
      final info = SorobanContractInfo(1, [], {});

      expect(info.funcs, isEmpty);
    });

    test('extractFunctions filters non-function entries', () {
      final structEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'Struct', []);

      final funcEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'func', [], []);

      final info = SorobanContractInfo(1, [structEntry, funcEntry], {});

      expect(info.funcs.length, equals(1));
      expect(info.funcs[0].name, equals('func'));
    });

    test('extractUdtStructs filters non-struct entries', () {
      final funcEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'func', [], []);

      final structEntry = XdrSCSpecEntry(
          XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'Struct', []);

      final info = SorobanContractInfo(1, [funcEntry, structEntry], {});

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
        0x00
      ]);

      try {
        SorobanContractParser.parseContractByteCode(invalidBytes);
        fail('Should have thrown SorobanContractParserFailed');
      } catch (e) {
        expect(e, isA<SorobanContractParserFailed>());
        expect(
            e.toString(), contains('environment meta not found'));
      }
    });
  });
}
