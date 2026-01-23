import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SorobanContractParser - Error Handling', () {
    test('parseContractByteCode with null environment meta throws', () {
      final invalidByteCode = Uint8List.fromList([0x00, 0x61, 0x73, 0x6D]);

      expect(
        () => SorobanContractParser.parseContractByteCode(invalidByteCode),
        throwsA(isA<SorobanContractParserFailed>()),
      );
    });

    test('parseContractByteCode with null spec entries throws', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final envMetaBytes = xdrOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);

      final byteCode = 'contractenvmetav0$envMetaString';
      final invalidByteCode = Uint8List.fromList(byteCode.codeUnits);

      expect(
        () => SorobanContractParser.parseContractByteCode(invalidByteCode),
        throwsA(isA<SorobanContractParserFailed>()),
      );
    });

    test('_parseEnvironmentMeta with malformed bytes throws', () {
      final invalidBytesString = 'contractenvmetav0\x00\x00\x00invalid';

      expect(
        () => SorobanContractParser.parseContractByteCode(
          Uint8List.fromList(invalidBytesString.codeUnits),
        ),
        throwsA(isA<SorobanContractParserFailed>()),
      );
    });

    test('_parseEnvironmentMeta falls back to contractspecv0 boundary', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final funcOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0$funcString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      // Should parse successfully with contractspecv0 boundary
      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.envInterfaceVersion, equals(20));
      expect(result.specEntries.length, equals(1));
    });

    test('_parseEnvironmentMeta extracts to end when no boundary found', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final envMetaBytes = xdrOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);

      final byteCode = 'contractenvmetav0$envMetaString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      expect(
        () => SorobanContractParser.parseContractByteCode(validByteCode),
        throwsA(isA<SorobanContractParserFailed>()),
      );
    });

    test('_parseContractSpec with no boundaries extracts to end', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final funcOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0$funcString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.envInterfaceVersion, equals(20));
      expect(result.specEntries.length, equals(1));
    });

    test('_parseContractSpec stops on malformed entry', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final funcOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);
      final malformedString = '\x00\x00\x00invalid';

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0$funcString$malformedString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.specEntries.length, equals(1));
    });

    test('_parseContractSpec skips unsupported entry kinds', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final funcOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0${funcString}\x00\x00\x00\xFF';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      // Parser should succeed but stop at unsupported entry
      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.envInterfaceVersion, equals(20));
      expect(result.specEntries.length, equals(1));
    });

    test('_parseMeta with contractenvmetav0 boundary', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final metaEntry = XdrSCMetaEntry(XdrSCMetaKind.SC_META_V0);
      metaEntry.v0 = XdrSCMetaV0('testKey', 'testValue');

      final funcOutputStream = XdrDataOutputStream();
      final metaOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);
      XdrSCMetaEntry.encode(metaOutputStream, metaEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final metaBytes = metaOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);
      final metaString = String.fromCharCodes(metaBytes);

      final byteCode = 'contractmetav0${metaString}contractenvmetav0${envMetaString}contractspecv0$funcString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.metaEntries['testKey'], equals('testValue'));
    });

    test('_parseMeta with contractspecv0 boundary', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final metaEntry = XdrSCMetaEntry(XdrSCMetaKind.SC_META_V0);
      metaEntry.v0 = XdrSCMetaV0('key2', 'value2');

      final funcOutputStream = XdrDataOutputStream();
      final metaOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);
      XdrSCMetaEntry.encode(metaOutputStream, metaEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final metaBytes = metaOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);
      final metaString = String.fromCharCodes(metaBytes);

      final byteCode = 'contractenvmetav0${envMetaString}contractmetav0${metaString}contractspecv0$funcString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.metaEntries['key2'], equals('value2'));
    });

    test('_parseMeta extracts to end when no boundary found', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final metaEntry = XdrSCMetaEntry(XdrSCMetaKind.SC_META_V0);
      metaEntry.v0 = XdrSCMetaV0('key3', 'value3');

      final funcOutputStream = XdrDataOutputStream();
      final metaOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);
      XdrSCMetaEntry.encode(metaOutputStream, metaEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final metaBytes = metaOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);
      final metaString = String.fromCharCodes(metaBytes);

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0${funcString}contractmetav0$metaString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.metaEntries['key3'], equals('value3'));
    });

    test('_parseMeta with no meta entries returns empty map', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final funcOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0$funcString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.metaEntries, isEmpty);
    });

    test('_parseMeta stops on malformed entry', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final metaEntry = XdrSCMetaEntry(XdrSCMetaKind.SC_META_V0);
      metaEntry.v0 = XdrSCMetaV0('key', 'value');

      final funcOutputStream = XdrDataOutputStream();
      final metaOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);
      XdrSCMetaEntry.encode(metaOutputStream, metaEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final metaBytes = metaOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);
      final metaString = String.fromCharCodes(metaBytes);
      final malformedString = '\x00\x00invalid';

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0${funcString}contractmetav0$metaString$malformedString';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.metaEntries.length, equals(1));
    });

    test('_parseMeta skips unsupported meta kinds', () {
      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final funcOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);

      final byteCode = 'contractenvmetav0${envMetaString}contractspecv0${funcString}contractmetav0\x00\x00\x00\xFF';
      final validByteCode = Uint8List.fromList(byteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result.metaEntries, isEmpty);
    });

    test('_extractStringBetween with start not found returns null', () {
      final byteCode = 'somedata';

      final xdrOutputStream = XdrDataOutputStream();
      final envMeta = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      envMeta.interfaceVersion = XdrUint64(BigInt.from(20));
      XdrSCEnvMetaEntry.encode(xdrOutputStream, envMeta);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'test', [], []);

      final funcOutputStream = XdrDataOutputStream();
      XdrSCSpecEntry.encode(funcOutputStream, funcEntry);

      final envMetaBytes = xdrOutputStream.bytes;
      final funcBytes = funcOutputStream.bytes;
      final envMetaString = String.fromCharCodes(envMetaBytes);
      final funcString = String.fromCharCodes(funcBytes);

      final fullByteCode = 'contractenvmetav0${envMetaString}contractspecv0$funcString';
      final validByteCode = Uint8List.fromList(fullByteCode.codeUnits);

      final result = SorobanContractParser.parseContractByteCode(validByteCode);

      expect(result, isNotNull);
    });
  });
}
