// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('ContractSpec', () {
    late ContractSpec spec;
    late List<XdrSCSpecEntry> entries;

    setUp(() {
      entries = _createTestSpecEntries();
      spec = ContractSpec(entries);
    });

    group('Basic functionality', () {
      test('should get all functions', () {
        final functions = spec.funcs();
        expect(functions.length, greaterThan(0));
        
        final functionNames = functions.map((f) => f.name).toList();
        expect(functionNames, contains('hello'));
        expect(functionNames, contains('add'));
      });

      test('should get specific function by name', () {
        final helloFunc = spec.getFunc('hello');
        expect(helloFunc, isNotNull);
        expect(helloFunc!.name, equals('hello'));

        final nonExistentFunc = spec.getFunc('nonExistent');
        expect(nonExistentFunc, isNull);
      });

      test('should find entries by name', () {
        final helloEntry = spec.findEntry('hello');
        expect(helloEntry, isNotNull);
        expect(helloEntry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0));

        final structEntry = spec.findEntry('TestStruct');
        expect(structEntry, isNotNull);
        expect(structEntry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0));

        final nonExistentEntry = spec.findEntry('nonExistent');
        expect(nonExistentEntry, isNull);
      });
    });

    group('Basic type conversions', () {
      test('should convert void type', () {
        final result = spec.nativeToXdrSCVal(null, XdrSCSpecTypeDef.forVoid());
        expect(result.discriminant, equals(XdrSCValType.SCV_VOID));
      });

      test('should convert bool type', () {
        final trueResult = spec.nativeToXdrSCVal(true,  XdrSCSpecTypeDef.forBool());
        expect(trueResult.discriminant, equals(XdrSCValType.SCV_BOOL));
        expect(trueResult.b, equals(true));

        final falseResult = spec.nativeToXdrSCVal(false, XdrSCSpecTypeDef.forBool());
        expect(falseResult.discriminant, equals(XdrSCValType.SCV_BOOL));
        expect(falseResult.b, equals(false));
      });

      test('should convert integer types', () {
        // u32
        final u32Result = spec.nativeToXdrSCVal(42, XdrSCSpecTypeDef.forU32());
        expect(u32Result.discriminant, equals(XdrSCValType.SCV_U32));
        expect(u32Result.u32!.uint32, equals(42));

        // i32
        final i32Result = spec.nativeToXdrSCVal(-42, XdrSCSpecTypeDef.forI32());
        expect(i32Result.discriminant, equals(XdrSCValType.SCV_I32));
        expect(i32Result.i32!.int32, equals(-42));

        // u64
        final u64Result = spec.nativeToXdrSCVal(12345678901234, XdrSCSpecTypeDef.forU64());
        expect(u64Result.discriminant, equals(XdrSCValType.SCV_U64));
        expect(u64Result.u64!.uint64, equals(BigInt.from(12345678901234)));

        // i64
        final i64Result = spec.nativeToXdrSCVal(-12345678901234, XdrSCSpecTypeDef.forI64());
        expect(i64Result.discriminant, equals(XdrSCValType.SCV_I64));
        expect(i64Result.i64!.int64, equals(BigInt.from(-12345678901234)));
      });

      test('should convert 128-bit integer types with BigInt', () {
        // u128 with BigInt
        final u128Value = BigInt.from(2).pow(100);
        final u128Result = spec.nativeToXdrSCVal(u128Value, XdrSCSpecTypeDef.forU128());
        expect(u128Result.discriminant, equals(XdrSCValType.SCV_U128));
        expect(u128Result.u128, isNotNull);
        
        // Verify roundtrip
        final u128Back = u128Result.toBigInt();
        expect(u128Back, equals(u128Value));

        // i128 with BigInt
        final i128Value = BigInt.parse('-123456789012345678901234567890');
        final i128Result = spec.nativeToXdrSCVal(i128Value, XdrSCSpecTypeDef.forI128());
        expect(i128Result.discriminant, equals(XdrSCValType.SCV_I128));
        expect(i128Result.i128, isNotNull);
        
        // Verify roundtrip
        final i128Back = i128Result.toBigInt();
        expect(i128Back, equals(i128Value));

        // u128 with small int (should still work)
        final u128SmallResult = spec.nativeToXdrSCVal(42, XdrSCSpecTypeDef.forU128());
        expect(u128SmallResult.discriminant, equals(XdrSCValType.SCV_U128));
        expect(u128SmallResult.u128!.hi.uint64, equals(BigInt.zero));
        expect(u128SmallResult.u128!.lo.uint64, equals(BigInt.from(42)));

        // u128 with negative BigInt should fail
        expect(
          () => spec.nativeToXdrSCVal(BigInt.from(-1), XdrSCSpecTypeDef.forU128()),
          throwsA(isA<ContractSpecException>()),
        );
      });

      test('should convert 256-bit integer types with BigInt', () {
        // u256 with BigInt
        final u256Value = BigInt.from(2).pow(200);
        final u256Result = spec.nativeToXdrSCVal(u256Value, XdrSCSpecTypeDef.forU256());
        expect(u256Result.discriminant, equals(XdrSCValType.SCV_U256));
        expect(u256Result.u256, isNotNull);
        
        // Verify roundtrip
        final u256Back = u256Result.toBigInt();
        expect(u256Back, equals(u256Value));

        // i256 with BigInt
        final i256Value = -BigInt.from(2).pow(200);
        final i256Result = spec.nativeToXdrSCVal(i256Value, XdrSCSpecTypeDef.forI256());
        expect(i256Result.discriminant, equals(XdrSCValType.SCV_I256));
        expect(i256Result.i256, isNotNull);
        
        // Verify roundtrip
        final i256Back = i256Result.toBigInt();
        expect(i256Back, equals(i256Value));

        // u256 with small int (should work now)
        final u256SmallResult = spec.nativeToXdrSCVal(42, XdrSCSpecTypeDef.forU256());
        expect(u256SmallResult.discriminant, equals(XdrSCValType.SCV_U256));
        expect(u256SmallResult.u256, isNotNull);
        expect(u256SmallResult.toBigInt(), equals(BigInt.from(42)));

        // i256 with small negative int (should work now)
        final i256SmallResult = spec.nativeToXdrSCVal(-42, XdrSCSpecTypeDef.forI256());
        expect(i256SmallResult.discriminant, equals(XdrSCValType.SCV_I256));
        expect(i256SmallResult.i256, isNotNull);
        expect(i256SmallResult.toBigInt(), equals(BigInt.from(-42)));

        // u256 with negative BigInt should fail
        expect(
          () => spec.nativeToXdrSCVal(BigInt.from(-1), XdrSCSpecTypeDef.forU256()),
          throwsA(isA<ContractSpecException>()),
        );

        // u256 with negative int should also fail
        expect(
          () => spec.nativeToXdrSCVal(-1, XdrSCSpecTypeDef.forU256()),
          throwsA(isA<ContractSpecException>()),
        );
      });

      test('should convert string types', () {
        final stringResult = spec.nativeToXdrSCVal('hello', XdrSCSpecTypeDef.forString());
        expect(stringResult.discriminant, equals(XdrSCValType.SCV_STRING));
        expect(stringResult.str, equals('hello'));

        final symbolResult = spec.nativeToXdrSCVal('symbol', XdrSCSpecTypeDef.forSymbol());
        expect(symbolResult.discriminant, equals(XdrSCValType.SCV_SYMBOL));
        expect(symbolResult.sym, equals('symbol'));
      });

      test('should convert bytes type', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        final result = spec.nativeToXdrSCVal(bytes, XdrSCSpecTypeDef.forBytes());
        expect(result.discriminant, equals(XdrSCValType.SCV_BYTES));
        expect(result.bytes!.dataValue, equals(bytes));

        // Test hex string conversion
        final hexResult = spec.nativeToXdrSCVal('01020304', XdrSCSpecTypeDef.forBytes());
        expect(hexResult.discriminant, equals(XdrSCValType.SCV_BYTES));
        expect(hexResult.bytes!.dataValue, equals(bytes));
      });

      test('should convert address types', () {
        final accountAddress = 'GAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSTVY';
        final result = spec.nativeToXdrSCVal(accountAddress, XdrSCSpecTypeDef.forAddress());
        expect(result.discriminant, equals(XdrSCValType.SCV_ADDRESS));
        expect(result.address, isNotNull);

        final contractAddress = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
        final contractResult = spec.nativeToXdrSCVal(contractAddress, XdrSCSpecTypeDef.forAddress());
        expect(contractResult.discriminant, equals(XdrSCValType.SCV_ADDRESS));
        expect(contractResult.address, isNotNull);
      });
    });

    group('Collection type conversions', () {
      test('should convert vector type', () {
        final elementTypeDef = XdrSCSpecTypeDef.forU32();
        final vecTypeDef = XdrSCSpecTypeDef.forVec(XdrSCSpecTypeVec(elementTypeDef));

        final result = spec.nativeToXdrSCVal([1, 2, 3], vecTypeDef);
        expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
        expect(result.vec!.length, equals(3));
        expect(result.vec![0].u32!.uint32, equals(1));
        expect(result.vec![1].u32!.uint32, equals(2));
        expect(result.vec![2].u32!.uint32, equals(3));
      });

      test('should convert map type', () {
        final mapTypeDef = XdrSCSpecTypeDef.forMap(XdrSCSpecTypeMap(
          XdrSCSpecTypeDef.forString(),
          XdrSCSpecTypeDef.forU32(),
        ));

        final result = spec.nativeToXdrSCVal({'a': 1, 'b': 2}, mapTypeDef);
        expect(result.discriminant, equals(XdrSCValType.SCV_MAP));
        expect(result.map!.length, equals(2));
      });

      test('should convert tuple type', () {
        final tupleSpec = XdrSCSpecTypeTuple([
          XdrSCSpecTypeDef.forString(),
          XdrSCSpecTypeDef.forU32(),
        ]);
        final tupleTypeDef = XdrSCSpecTypeDef.forTuple(tupleSpec);

        final result = spec.nativeToXdrSCVal(['hello', 42], tupleTypeDef);
        expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
        expect(result.vec!.length, equals(2));
        expect(result.vec![0].str, equals('hello'));
        expect(result.vec![1].u32!.uint32, equals(42));
      });

      test('should convert option type', () {
        final optionSpec = XdrSCSpecTypeOption(XdrSCSpecTypeDef.forU32());
        final optionTypeDef = XdrSCSpecTypeDef.forOption(optionSpec);

        // Test with value
        final withValueResult = spec.nativeToXdrSCVal(42, optionTypeDef);
        expect(withValueResult.discriminant, equals(XdrSCValType.SCV_U32));
        expect(withValueResult.u32!.uint32, equals(42));

        // Test with null
        final nullResult = spec.nativeToXdrSCVal(null, optionTypeDef);
        expect(nullResult.discriminant, equals(XdrSCValType.SCV_VOID));
      });
    });

    group('Function argument conversion', () {
      test('should convert function arguments correctly', () {
        final args = {'to': 'World'};
        final result = spec.funcArgsToXdrSCValues('hello', args);
        
        expect(result.length, equals(1));
        expect(result[0].discriminant, equals(XdrSCValType.SCV_STRING));
        expect(result[0].str, equals('World'));
      });

      test('should throw exception for missing function', () {
        expect(
          () => spec.funcArgsToXdrSCValues('nonExistent', {}),
          throwsA(isA<ContractSpecException>()),
        );
      });

      test('should throw exception for missing arguments', () {
        expect(
          () => spec.funcArgsToXdrSCValues('add', {'a': 1}), // missing 'b'
          throwsA(isA<ContractSpecException>()),
        );
      });

      test('should convert multiple arguments in correct order', () {
        final args = {'a': 10, 'b': 20};
        final result = spec.funcArgsToXdrSCValues('add', args);
        
        expect(result.length, equals(2));
        expect(result[0].discriminant, equals(XdrSCValType.SCV_U32));
        expect(result[0].u32!.uint32, equals(10));
        expect(result[1].discriminant, equals(XdrSCValType.SCV_U32));
        expect(result[1].u32!.uint32, equals(20));
      });
    });

    group('Error handling', () {
      test('should throw for invalid type conversions', () {
        expect(
          () => spec.nativeToXdrSCVal('not a bool', XdrSCSpecTypeDef.forBool()),
          throwsA(isA<ContractSpecException>()),
        );

        expect(
          () => spec.nativeToXdrSCVal('not a number', XdrSCSpecTypeDef.forU32()),
          throwsA(isA<ContractSpecException>()),
        );
      });

      test('should throw for out of range values', () {
        expect(
          () => spec.nativeToXdrSCVal(-1, XdrSCSpecTypeDef.forU32()),
          throwsA(isA<ContractSpecException>()),
        );

        expect(
          () => spec.nativeToXdrSCVal(0x100000000, XdrSCSpecTypeDef.forU32()),
          throwsA(isA<ContractSpecException>()),
        );
      });

      test('should provide meaningful error messages', () {
        try {
          spec.funcArgsToXdrSCValues('nonExistent', {});
          fail('Expected ContractSpecException');
        } catch (e) {
          expect(e, isA<ContractSpecException>());
          final exception = e as ContractSpecException;
          expect(exception.message, contains('Function not found'));
          expect(exception.functionName, equals('nonExistent'));
        }
      });
    });

    group('NativeUnionVal', () {
      test('should create void union cases', () {
        final voidCase = NativeUnionVal.voidCase('Success');
        expect(voidCase.tag, equals('Success'));
        expect(voidCase.isVoidCase, isTrue);
        expect(voidCase.isTupleCase, isFalse);
        expect(voidCase.values, isNull);
      });

      test('should create tuple union cases', () {
        final tupleCase = NativeUnionVal.tupleCase('Data', ['field1', 42]);
        expect(tupleCase.tag, equals('Data'));
        expect(tupleCase.isVoidCase, isFalse);
        expect(tupleCase.isTupleCase, isTrue);
        expect(tupleCase.values, equals(['field1', 42]));
      });

      test('should implement equality correctly', () {
        final case1 = NativeUnionVal.voidCase('Success');
        final case2 = NativeUnionVal.voidCase('Success');
        final case3 = NativeUnionVal.voidCase('Error');

        expect(case1, equals(case2));
        expect(case1, isNot(equals(case3)));

        final tuple1 = NativeUnionVal.tupleCase('Data', ['a', 1]);
        final tuple2 = NativeUnionVal.tupleCase('Data', ['a', 1]);
        final tuple3 = NativeUnionVal.tupleCase('Data', ['b', 2]);

        expect(tuple1, equals(tuple2));
        expect(tuple1, isNot(equals(tuple3)));
      });
    });

    group('Edge cases', () {
      test('should handle already converted XdrSCVal values', () {
        final existingVal = XdrSCVal.forU32(42);
        final result = spec.nativeToXdrSCVal(existingVal, XdrSCSpecTypeDef.forU32());
        expect(result, equals(existingVal));
      });

      test('should handle string integer conversion', () {
        final result = spec.nativeToXdrSCVal('42', XdrSCSpecTypeDef.forU32());
        expect(result.discriminant, equals(XdrSCValType.SCV_U32));
        expect(result.u32!.uint32, equals(42));
      });

      test('should handle double to int conversion', () {
        final result = spec.nativeToXdrSCVal(42.7, XdrSCSpecTypeDef.forU32());
        expect(result.discriminant, equals(XdrSCValType.SCV_U32));
        expect(result.u32!.uint32, equals(42));
      });
    });
  });

  // Run roundtrip tests merged from contract_spec_roundtrip_test.dart
  _runRoundtripTests();
}

/// Creates test specification entries for testing
List<XdrSCSpecEntry> _createTestSpecEntries() {
  final entries = <XdrSCSpecEntry>[];

  // Hello function: hello(to: string) -> string
  final helloFunc = XdrSCSpecFunctionV0(
    '', 
    'hello', 
    [
      XdrSCSpecFunctionInputV0(
        '', 
        'to',
          XdrSCSpecTypeDef.forString()
      )
    ], 
    [XdrSCSpecTypeDef.forString()]
  );

  final helloEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
  helloEntry.functionV0 = helloFunc;
  entries.add(helloEntry);

  // Add function: add(a: u32, b: u32) -> u32
  final addFunc = XdrSCSpecFunctionV0(
    '', 
    'add', 
    [
      XdrSCSpecFunctionInputV0(
        '', 
        'a',
          XdrSCSpecTypeDef.forU32()
      ),
      XdrSCSpecFunctionInputV0(
        '', 
        'b',
          XdrSCSpecTypeDef.forU32()
      ),
    ], 
    [XdrSCSpecTypeDef.forU32()]
  );

  final addEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
  addEntry.functionV0 = addFunc;
  entries.add(addEntry);

  // Test struct: TestStruct { field1: string, field2: u32 }
  final testStruct = XdrSCSpecUDTStructV0(
    '', 
    '', 
    'TestStruct', 
    [
      XdrSCSpecUDTStructFieldV0(
        '', 
        'field1',
          XdrSCSpecTypeDef.forString()
      ),
      XdrSCSpecUDTStructFieldV0(
        '', 
        'field2',
          XdrSCSpecTypeDef.forU32()
      ),
    ]
  );

  final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
  structEntry.udtStructV0 = testStruct;
  entries.add(structEntry);

  return entries;
}

// ============================================================================
// Tests merged from contract_spec_roundtrip_test.dart
// ============================================================================

void _runRoundtripTests() {
  group('ContractSpec - Type Helpers', () {
    test('funcs returns all function entries', () {
      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'testFunc', [], []);

      final spec = ContractSpec([funcEntry]);
      final funcs = spec.funcs();

      expect(funcs, hasLength(1));
      expect(funcs[0].name, equals('testFunc'));
    });

    test('funcs skips null function entries', () {
      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      // functionV0 is null

      final spec = ContractSpec([funcEntry]);
      final funcs = spec.funcs();

      expect(funcs, isEmpty);
    });

    test('udtStructs returns all struct entries', () {
      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'TestStruct', []);

      final spec = ContractSpec([structEntry]);
      final structs = spec.udtStructs();

      expect(structs, hasLength(1));
      expect(structs[0].name, equals('TestStruct'));
    });

    test('udtStructs skips null struct entries', () {
      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);

      final spec = ContractSpec([structEntry]);
      final structs = spec.udtStructs();

      expect(structs, isEmpty);
    });

    test('udtUnions returns all union entries', () {
      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = XdrSCSpecUDTUnionV0('', '', 'TestUnion', []);

      final spec = ContractSpec([unionEntry]);
      final unions = spec.udtUnions();

      expect(unions, hasLength(1));
      expect(unions[0].name, equals('TestUnion'));
    });

    test('udtUnions skips null union entries', () {
      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);

      final spec = ContractSpec([unionEntry]);
      final unions = spec.udtUnions();

      expect(unions, isEmpty);
    });

    test('udtEnums returns all enum entries', () {
      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = XdrSCSpecUDTEnumV0('', '', 'TestEnum', []);

      final spec = ContractSpec([enumEntry]);
      final enums = spec.udtEnums();

      expect(enums, hasLength(1));
      expect(enums[0].name, equals('TestEnum'));
    });

    test('udtEnums skips null enum entries', () {
      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);

      final spec = ContractSpec([enumEntry]);
      final enums = spec.udtEnums();

      expect(enums, isEmpty);
    });

    test('udtErrorEnums returns all error enum entries', () {
      final errorEnumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0);
      errorEnumEntry.udtErrorEnumV0 = XdrSCSpecUDTErrorEnumV0('', '', 'TestError', []);

      final spec = ContractSpec([errorEnumEntry]);
      final errorEnums = spec.udtErrorEnums();

      expect(errorEnums, hasLength(1));
      expect(errorEnums[0].name, equals('TestError'));
    });

    test('udtErrorEnums skips null error enum entries', () {
      final errorEnumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0);

      final spec = ContractSpec([errorEnumEntry]);
      final errorEnums = spec.udtErrorEnums();

      expect(errorEnums, isEmpty);
    });

    test('events returns all event entries', () {
      final eventEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0);
      eventEntry.eventV0 = XdrSCSpecEventV0('', '', 'TestEvent', [], [], XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_SINGLE_VALUE);

      final spec = ContractSpec([eventEntry]);
      final events = spec.events();

      expect(events, hasLength(1));
      expect(events[0].name, equals('TestEvent'));
    });

    test('events skips null event entries', () {
      final eventEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0);

      final spec = ContractSpec([eventEntry]);
      final events = spec.events();

      expect(events, isEmpty);
    });

    test('getFunc finds function by name', () {
      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'transfer', [], []);

      final spec = ContractSpec([funcEntry]);
      final func = spec.getFunc('transfer');

      expect(func, isNotNull);
      expect(func!.name, equals('transfer'));
    });

    test('getFunc returns null when function not found', () {
      final spec = ContractSpec([]);
      final func = spec.getFunc('notFound');

      expect(func, isNull);
    });

    test('findEntry finds function entry by name', () {
      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0('', 'transfer', [], []);

      final spec = ContractSpec([funcEntry]);
      final entry = spec.findEntry('transfer');

      expect(entry, isNotNull);
      expect(entry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0));
    });

    test('findEntry finds struct entry by name', () {
      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0('', '', 'TestStruct', []);

      final spec = ContractSpec([structEntry]);
      final entry = spec.findEntry('TestStruct');

      expect(entry, isNotNull);
      expect(entry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0));
    });

    test('findEntry finds union entry by name', () {
      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = XdrSCSpecUDTUnionV0('', '', 'TestUnion', []);

      final spec = ContractSpec([unionEntry]);
      final entry = spec.findEntry('TestUnion');

      expect(entry, isNotNull);
      expect(entry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0));
    });

    test('findEntry finds enum entry by name', () {
      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = XdrSCSpecUDTEnumV0('', '', 'TestEnum', []);

      final spec = ContractSpec([enumEntry]);
      final entry = spec.findEntry('TestEnum');

      expect(entry, isNotNull);
      expect(entry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0));
    });

    test('findEntry finds error enum entry by name', () {
      final errorEnumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0);
      errorEnumEntry.udtErrorEnumV0 = XdrSCSpecUDTErrorEnumV0('', '', 'TestError', []);

      final spec = ContractSpec([errorEnumEntry]);
      final entry = spec.findEntry('TestError');

      expect(entry, isNotNull);
      expect(entry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0));
    });

    test('findEntry finds event entry by name', () {
      final eventEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0);
      eventEntry.eventV0 = XdrSCSpecEventV0('', '', 'TestEvent', [], [], XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_SINGLE_VALUE);

      final spec = ContractSpec([eventEntry]);
      final entry = spec.findEntry('TestEvent');

      expect(entry, isNotNull);
      expect(entry!.discriminant, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0));
    });

    test('findEntry returns null when entry not found', () {
      final spec = ContractSpec([]);
      final entry = spec.findEntry('notFound');

      expect(entry, isNull);
    });
  });

  group('ContractSpec - funcArgsToXdrSCValues', () {
    test('converts function arguments to XdrSCVal list', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final stringType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0(
        '',
        'transfer',
        [
          XdrSCSpecFunctionInputV0('', 'amount', u32Type),
          XdrSCSpecFunctionInputV0('', 'memo', stringType),
        ],
        [],
      );

      final spec = ContractSpec([funcEntry]);
      final scValues = spec.funcArgsToXdrSCValues('transfer', {
        'amount': 100,
        'memo': 'test memo',
      });

      expect(scValues, hasLength(2));
      expect(scValues[0].discriminant, equals(XdrSCValType.SCV_U32));
      expect(scValues[1].discriminant, equals(XdrSCValType.SCV_STRING));
    });

    test('throws when function not found', () {
      final spec = ContractSpec([]);

      expect(
        () => spec.funcArgsToXdrSCValues('notFound', {}),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when required argument missing', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      final funcEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      funcEntry.functionV0 = XdrSCSpecFunctionV0(
        '',
        'transfer',
        [XdrSCSpecFunctionInputV0('', 'amount', u32Type)],
        [],
      );

      final spec = ContractSpec([funcEntry]);

      expect(
        () => spec.funcArgsToXdrSCValues('transfer', {}),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpec - Basic Types', () {
    late ContractSpec spec;

    setUp(() {
      spec = ContractSpec([]);
    });

    test('converts null to void', () {
      final voidType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VOID);
      final result = spec.nativeToXdrSCVal(null, voidType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VOID));
    });

    test('returns XdrSCVal as-is', () {
      final voidType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VOID);
      final existing = XdrSCVal.forBool(true);
      final result = spec.nativeToXdrSCVal(existing, voidType);

      expect(result, same(existing));
    });

    test('converts bool type', () {
      final boolType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);

      final trueResult = spec.nativeToXdrSCVal(true, boolType);
      expect(trueResult.discriminant, equals(XdrSCValType.SCV_BOOL));
      expect(trueResult.b, isTrue);

      final falseResult = spec.nativeToXdrSCVal(false, boolType);
      expect(falseResult.discriminant, equals(XdrSCValType.SCV_BOOL));
      expect(falseResult.b, isFalse);
    });

    test('throws when bool type receives non-bool', () {
      final boolType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);

      expect(
        () => spec.nativeToXdrSCVal('not a bool', boolType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts void type', () {
      final voidType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VOID);
      final result = spec.nativeToXdrSCVal(null, voidType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VOID));
    });

    test('converts u32 type with valid values', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      final result1 = spec.nativeToXdrSCVal(0, u32Type);
      expect(result1.discriminant, equals(XdrSCValType.SCV_U32));
      expect(result1.u32!.uint32, equals(0));

      final result2 = spec.nativeToXdrSCVal(0xFFFFFFFF, u32Type);
      expect(result2.discriminant, equals(XdrSCValType.SCV_U32));
      expect(result2.u32!.uint32, equals(0xFFFFFFFF));
    });

    test('converts u32 from double', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final result = spec.nativeToXdrSCVal(42.0, u32Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U32));
      expect(result.u32!.uint32, equals(42));
    });

    test('converts u32 from string', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final result = spec.nativeToXdrSCVal('123', u32Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U32));
      expect(result.u32!.uint32, equals(123));
    });

    test('throws when u32 is negative', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      expect(
        () => spec.nativeToXdrSCVal(-1, u32Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when u32 is out of range', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      expect(
        () => spec.nativeToXdrSCVal(0x100000000, u32Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when u32 string is invalid', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      expect(
        () => spec.nativeToXdrSCVal('not a number', u32Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when u32 type is invalid', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      expect(
        () => spec.nativeToXdrSCVal({}, u32Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts i32 type with valid values', () {
      final i32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I32);

      final result1 = spec.nativeToXdrSCVal(-2147483648, i32Type);
      expect(result1.discriminant, equals(XdrSCValType.SCV_I32));
      expect(result1.i32!.int32, equals(-2147483648));

      final result2 = spec.nativeToXdrSCVal(2147483647, i32Type);
      expect(result2.discriminant, equals(XdrSCValType.SCV_I32));
      expect(result2.i32!.int32, equals(2147483647));
    });

    test('throws when i32 is below minimum', () {
      final i32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I32);

      expect(
        () => spec.nativeToXdrSCVal(-2147483649, i32Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when i32 is above maximum', () {
      final i32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I32);

      expect(
        () => spec.nativeToXdrSCVal(2147483648, i32Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts u64 type', () {
      final u64Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U64);
      final result = spec.nativeToXdrSCVal(1000000000, u64Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U64));
      expect(result.u64!.uint64, equals(BigInt.from(1000000000)));
    });

    test('throws when u64 is negative', () {
      final u64Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U64);

      expect(
        () => spec.nativeToXdrSCVal(-1, u64Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts i64 type', () {
      final i64Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I64);

      final result1 = spec.nativeToXdrSCVal(-1000000000, i64Type);
      expect(result1.discriminant, equals(XdrSCValType.SCV_I64));
      expect(result1.i64!.int64, equals(BigInt.from(-1000000000)));

      final result2 = spec.nativeToXdrSCVal(1000000000, i64Type);
      expect(result2.discriminant, equals(XdrSCValType.SCV_I64));
      expect(result2.i64!.int64, equals(BigInt.from(1000000000)));
    });

    test('converts timepoint type', () {
      final timepointType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT);
      final result = spec.nativeToXdrSCVal(1609459200, timepointType);

      expect(result.discriminant, equals(XdrSCValType.SCV_TIMEPOINT));
      expect(result.timepoint!.uint64, equals(BigInt.from(1609459200)));
    });

    test('throws when timepoint is negative', () {
      final timepointType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT);

      expect(
        () => spec.nativeToXdrSCVal(-1, timepointType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts duration type', () {
      final durationType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_DURATION);
      final result = spec.nativeToXdrSCVal(3600, durationType);

      expect(result.discriminant, equals(XdrSCValType.SCV_DURATION));
      expect(result.duration!.uint64, equals(BigInt.from(3600)));
    });

    test('throws when duration is negative', () {
      final durationType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_DURATION);

      expect(
        () => spec.nativeToXdrSCVal(-1, durationType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts string type', () {
      final stringType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      final result = spec.nativeToXdrSCVal('hello world', stringType);

      expect(result.discriminant, equals(XdrSCValType.SCV_STRING));
      expect(result.str, equals('hello world'));
    });

    test('throws when string type receives non-string', () {
      final stringType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);

      expect(
        () => spec.nativeToXdrSCVal(123, stringType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts symbol type', () {
      final symbolType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_SYMBOL);
      final result = spec.nativeToXdrSCVal('my_symbol', symbolType);

      expect(result.discriminant, equals(XdrSCValType.SCV_SYMBOL));
      expect(result.sym, equals('my_symbol'));
    });

    test('throws when symbol type receives non-string', () {
      final symbolType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_SYMBOL);

      expect(
        () => spec.nativeToXdrSCVal(123, symbolType),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpec - Large Integer Types', () {
    late ContractSpec spec;

    setUp(() {
      spec = ContractSpec([]);
    });

    test('converts u128 from XdrUInt128Parts', () {
      final u128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128);
      final parts = XdrUInt128Parts(XdrUint64(BigInt.zero), XdrUint64(BigInt.from(42)));
      final result = spec.nativeToXdrSCVal(parts, u128Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U128));
    });

    test('converts u128 from BigInt', () {
      final u128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128);
      final bigValue = BigInt.parse('1000000000000000000');
      final result = spec.nativeToXdrSCVal(bigValue, u128Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U128));
    });

    test('throws when u128 BigInt is negative', () {
      final u128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128);

      expect(
        () => spec.nativeToXdrSCVal(BigInt.from(-1), u128Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts u128 from small integer', () {
      final u128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128);
      final result = spec.nativeToXdrSCVal(100, u128Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U128));
    });

    test('throws when u128 small integer is negative', () {
      final u128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128);

      expect(
        () => spec.nativeToXdrSCVal(-1, u128Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts i128 from XdrInt128Parts', () {
      final i128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I128);
      final parts = XdrInt128Parts(XdrInt64(BigInt.zero), XdrUint64(BigInt.from(42)));
      final result = spec.nativeToXdrSCVal(parts, i128Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_I128));
    });

    test('converts i128 from BigInt', () {
      final i128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I128);
      final bigValue = BigInt.parse('1000000000000000000');
      final result = spec.nativeToXdrSCVal(bigValue, i128Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_I128));
    });

    test('converts i128 from small positive integer', () {
      final i128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I128);
      final result = spec.nativeToXdrSCVal(100, i128Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_I128));
    });

    test('converts i128 from small negative integer', () {
      final i128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I128);
      final result = spec.nativeToXdrSCVal(-100, i128Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_I128));
    });

    test('converts u256 from XdrUInt256Parts', () {
      final u256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U256);
      final parts = XdrUInt256Parts(XdrUint64(BigInt.zero), XdrUint64(BigInt.zero), XdrUint64(BigInt.zero), XdrUint64(BigInt.from(42)));
      final result = spec.nativeToXdrSCVal(parts, u256Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U256));
    });

    test('converts u256 from BigInt', () {
      final u256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U256);
      final bigValue = BigInt.parse('1000000000000000000');
      final result = spec.nativeToXdrSCVal(bigValue, u256Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U256));
    });

    test('throws when u256 BigInt is negative', () {
      final u256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U256);

      expect(
        () => spec.nativeToXdrSCVal(BigInt.from(-1), u256Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts u256 from small integer', () {
      final u256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U256);
      final result = spec.nativeToXdrSCVal(100, u256Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_U256));
    });

    test('throws when u256 small integer is negative', () {
      final u256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U256);

      expect(
        () => spec.nativeToXdrSCVal(-1, u256Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts i256 from XdrInt256Parts', () {
      final i256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I256);
      final parts = XdrInt256Parts(XdrInt64(BigInt.zero), XdrUint64(BigInt.zero), XdrUint64(BigInt.zero), XdrUint64(BigInt.from(42)));
      final result = spec.nativeToXdrSCVal(parts, i256Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_I256));
    });

    test('converts i256 from BigInt', () {
      final i256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I256);
      final bigValue = BigInt.parse('-1000000000000000000');
      final result = spec.nativeToXdrSCVal(bigValue, i256Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_I256));
    });

    test('converts i256 from small integer', () {
      final i256Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I256);
      final result = spec.nativeToXdrSCVal(-100, i256Type);

      expect(result.discriminant, equals(XdrSCValType.SCV_I256));
    });
  });

  group('ContractSpec - Bytes Types', () {
    late ContractSpec spec;

    setUp(() {
      spec = ContractSpec([]);
    });

    test('converts bytes from Uint8List', () {
      final bytesType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = spec.nativeToXdrSCVal(bytes, bytesType);

      expect(result.discriminant, equals(XdrSCValType.SCV_BYTES));
      expect(result.bytes!.dataValue, equals(bytes));
    });

    test('converts bytes from List<int>', () {
      final bytesType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);
      final bytes = [1, 2, 3, 4, 5];
      final result = spec.nativeToXdrSCVal(bytes, bytesType);

      expect(result.discriminant, equals(XdrSCValType.SCV_BYTES));
    });

    test('converts bytes from hex string', () {
      final bytesType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);
      final result = spec.nativeToXdrSCVal('0102030405', bytesType);

      expect(result.discriminant, equals(XdrSCValType.SCV_BYTES));
      expect(result.bytes!.dataValue, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
    });

    test('throws when bytes string is invalid hex', () {
      final bytesType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);

      expect(
        () => spec.nativeToXdrSCVal('invalid hex', bytesType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when bytes type is invalid', () {
      final bytesType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);

      expect(
        () => spec.nativeToXdrSCVal(123, bytesType),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpec - Address Types', () {
    late ContractSpec spec;

    setUp(() {
      spec = ContractSpec([]);
    });

    test('converts contract address', () {
      final addressType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ADDRESS);
      final contractId = 'CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABSC4';
      final result = spec.nativeToXdrSCVal(contractId, addressType);

      expect(result.discriminant, equals(XdrSCValType.SCV_ADDRESS));
    });

    test('converts account address', () {
      final addressType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ADDRESS);
      final accountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final result = spec.nativeToXdrSCVal(accountId, addressType);

      expect(result.discriminant, equals(XdrSCValType.SCV_ADDRESS));
    });

    test('throws when address has invalid format', () {
      final addressType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ADDRESS);

      expect(
        () => spec.nativeToXdrSCVal('INVALID', addressType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when address type is not string', () {
      final addressType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ADDRESS);

      expect(
        () => spec.nativeToXdrSCVal(123, addressType),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpec - Complex Types', () {
    late ContractSpec spec;

    setUp(() {
      spec = ContractSpec([]);
    });

    test('converts option type with value', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final optionType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_OPTION);
      optionType.option = XdrSCSpecTypeOption(u32Type);

      final result = spec.nativeToXdrSCVal(42, optionType);

      expect(result.discriminant, equals(XdrSCValType.SCV_U32));
      expect(result.u32!.uint32, equals(42));
    });

    test('converts option type with null value', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final optionType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_OPTION);
      optionType.option = XdrSCSpecTypeOption(u32Type);

      final result = spec.nativeToXdrSCVal(null, optionType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VOID));
    });

    test('throws when option type is null', () {
      final optionType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_OPTION);

      expect(
        () => spec.nativeToXdrSCVal(42, optionType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws for result type (not yet implemented)', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final resultType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_RESULT);
      resultType.result = XdrSCSpecTypeResult(u32Type, u32Type);

      expect(
        () => spec.nativeToXdrSCVal(42, resultType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when result type is null', () {
      final resultType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_RESULT);

      expect(
        () => spec.nativeToXdrSCVal(42, resultType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts vec type', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(u32Type);

      final result = spec.nativeToXdrSCVal([1, 2, 3], vecType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
      expect(result.vec, hasLength(3));
    });

    test('throws when vec type receives non-list', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(u32Type);

      expect(
        () => spec.nativeToXdrSCVal('not a list', vecType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when vec type is null', () {
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);

      expect(
        () => spec.nativeToXdrSCVal([1, 2, 3], vecType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts map type', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final stringType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      final mapType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_MAP);
      mapType.map = XdrSCSpecTypeMap(stringType, u32Type);

      final result = spec.nativeToXdrSCVal({'key1': 1, 'key2': 2}, mapType);

      expect(result.discriminant, equals(XdrSCValType.SCV_MAP));
      expect(result.map, hasLength(2));
    });

    test('throws when map type receives non-map', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final stringType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      final mapType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_MAP);
      mapType.map = XdrSCSpecTypeMap(stringType, u32Type);

      expect(
        () => spec.nativeToXdrSCVal('not a map', mapType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when map type is null', () {
      final mapType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_MAP);

      expect(
        () => spec.nativeToXdrSCVal({'key': 'value'}, mapType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts tuple type', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final stringType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      final tupleType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TUPLE);
      tupleType.tuple = XdrSCSpecTypeTuple([u32Type, stringType]);

      final result = spec.nativeToXdrSCVal([42, 'hello'], tupleType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
      expect(result.vec, hasLength(2));
    });

    test('throws when tuple type receives non-list', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final tupleType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TUPLE);
      tupleType.tuple = XdrSCSpecTypeTuple([u32Type]);

      expect(
        () => spec.nativeToXdrSCVal('not a list', tupleType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when tuple type is null', () {
      final tupleType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TUPLE);

      expect(
        () => spec.nativeToXdrSCVal([1, 2], tupleType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when tuple length mismatch', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final tupleType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TUPLE);
      tupleType.tuple = XdrSCSpecTypeTuple([u32Type, u32Type]);

      expect(
        () => spec.nativeToXdrSCVal([42], tupleType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts bytesN type from Uint8List', () {
      final bytesNType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      bytesNType.bytesN = XdrSCSpecTypeBytesN(XdrUint32(4));

      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = spec.nativeToXdrSCVal(bytes, bytesNType);

      expect(result.discriminant, equals(XdrSCValType.SCV_BYTES));
    });

    test('converts bytesN type from List<int>', () {
      final bytesNType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      bytesNType.bytesN = XdrSCSpecTypeBytesN(XdrUint32(4));

      final result = spec.nativeToXdrSCVal([1, 2, 3, 4], bytesNType);

      expect(result.discriminant, equals(XdrSCValType.SCV_BYTES));
    });

    test('converts bytesN type from hex string', () {
      final bytesNType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      bytesNType.bytesN = XdrSCSpecTypeBytesN(XdrUint32(4));

      final result = spec.nativeToXdrSCVal('01020304', bytesNType);

      expect(result.discriminant, equals(XdrSCValType.SCV_BYTES));
    });

    test('throws when bytesN length mismatch', () {
      final bytesNType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      bytesNType.bytesN = XdrSCSpecTypeBytesN(XdrUint32(4));

      expect(
        () => spec.nativeToXdrSCVal(Uint8List.fromList([1, 2, 3]), bytesNType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when bytesN string is invalid hex', () {
      final bytesNType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      bytesNType.bytesN = XdrSCSpecTypeBytesN(XdrUint32(4));

      expect(
        () => spec.nativeToXdrSCVal('invalid', bytesNType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when bytesN type receives invalid type', () {
      final bytesNType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      bytesNType.bytesN = XdrSCSpecTypeBytesN(XdrUint32(4));

      expect(
        () => spec.nativeToXdrSCVal(123, bytesNType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when bytesN type is null', () {
      final bytesNType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);

      expect(
        () => spec.nativeToXdrSCVal(Uint8List.fromList([1, 2, 3, 4]), bytesNType),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpec - User Defined Types', () {
    test('converts struct type with named fields', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final stringType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);

      final structDef = XdrSCSpecUDTStructV0('', '', 'TestStruct', [
        XdrSCSpecUDTStructFieldV0('', 'amount', u32Type),
        XdrSCSpecUDTStructFieldV0('', 'memo', stringType),
      ]);

      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = structDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestStruct');

      final spec = ContractSpec([structEntry]);
      final result = spec.nativeToXdrSCVal({
        'amount': 100,
        'memo': 'test',
      }, udtType);

      expect(result.discriminant, equals(XdrSCValType.SCV_MAP));
      expect(result.map, hasLength(2));
    });

    test('converts struct type with numeric fields (vector representation)', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      final structDef = XdrSCSpecUDTStructV0('', '', 'TestStruct', [
        XdrSCSpecUDTStructFieldV0('', '0', u32Type),
        XdrSCSpecUDTStructFieldV0('', '1', u32Type),
      ]);

      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = structDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestStruct');

      final spec = ContractSpec([structEntry]);
      final result = spec.nativeToXdrSCVal({
        '0': 100,
        '1': 200,
      }, udtType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
      expect(result.vec, hasLength(2));
    });

    test('throws when struct field is missing', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      final structDef = XdrSCSpecUDTStructV0('', '', 'TestStruct', [
        XdrSCSpecUDTStructFieldV0('', 'amount', u32Type),
      ]);

      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = structDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestStruct');

      final spec = ContractSpec([structEntry]);

      expect(
        () => spec.nativeToXdrSCVal({}, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when struct type receives non-map', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      final structDef = XdrSCSpecUDTStructV0('', '', 'TestStruct', [
        XdrSCSpecUDTStructFieldV0('', 'amount', u32Type),
      ]);

      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = structDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestStruct');

      final spec = ContractSpec([structEntry]);

      expect(
        () => spec.nativeToXdrSCVal('not a map', udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts enum type from string', () {
      final enumDef = XdrSCSpecUDTEnumV0('', '', 'TestEnum', [
        XdrSCSpecUDTEnumCaseV0('', 'SUCCESS', XdrUint32(0)),
        XdrSCSpecUDTEnumCaseV0('', 'FAILURE', XdrUint32(1)),
      ]);

      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = enumDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestEnum');

      final spec = ContractSpec([enumEntry]);
      final result = spec.nativeToXdrSCVal('SUCCESS', udtType);

      expect(result.discriminant, equals(XdrSCValType.SCV_U32));
      expect(result.u32!.uint32, equals(0));
    });

    test('converts enum type from int', () {
      final enumDef = XdrSCSpecUDTEnumV0('', '', 'TestEnum', [
        XdrSCSpecUDTEnumCaseV0('', 'SUCCESS', XdrUint32(0)),
        XdrSCSpecUDTEnumCaseV0('', 'FAILURE', XdrUint32(1)),
      ]);

      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = enumDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestEnum');

      final spec = ContractSpec([enumEntry]);
      final result = spec.nativeToXdrSCVal(1, udtType);

      expect(result.discriminant, equals(XdrSCValType.SCV_U32));
      expect(result.u32!.uint32, equals(1));
    });

    test('throws when enum string case not found', () {
      final enumDef = XdrSCSpecUDTEnumV0('', '', 'TestEnum', [
        XdrSCSpecUDTEnumCaseV0('', 'SUCCESS', XdrUint32(0)),
      ]);

      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = enumDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestEnum');

      final spec = ContractSpec([enumEntry]);

      expect(
        () => spec.nativeToXdrSCVal('UNKNOWN', udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when enum int value is invalid', () {
      final enumDef = XdrSCSpecUDTEnumV0('', '', 'TestEnum', [
        XdrSCSpecUDTEnumCaseV0('', 'SUCCESS', XdrUint32(0)),
      ]);

      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = enumDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestEnum');

      final spec = ContractSpec([enumEntry]);

      expect(
        () => spec.nativeToXdrSCVal(99, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when enum type is invalid', () {
      final enumDef = XdrSCSpecUDTEnumV0('', '', 'TestEnum', [
        XdrSCSpecUDTEnumCaseV0('', 'SUCCESS', XdrUint32(0)),
      ]);

      final enumEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      enumEntry.udtEnumV0 = enumDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestEnum');

      final spec = ContractSpec([enumEntry]);

      expect(
        () => spec.nativeToXdrSCVal({}, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('converts union type with void case', () {
      final voidCase = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0);
      voidCase.voidCase = XdrSCSpecUDTUnionCaseVoidV0('', 'Success');

      final unionDef = XdrSCSpecUDTUnionV0('', '', 'TestUnion', [voidCase]);

      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = unionDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestUnion');

      final spec = ContractSpec([unionEntry]);
      final unionVal = NativeUnionVal.voidCase('Success');
      final result = spec.nativeToXdrSCVal(unionVal, udtType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
      expect(result.vec, hasLength(1));
    });

    test('converts union type with tuple case', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final tupleCase = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0);
      tupleCase.tupleCase = XdrSCSpecUDTUnionCaseTupleV0('', 'Data', [u32Type]);

      final unionDef = XdrSCSpecUDTUnionV0('', '', 'TestUnion', [tupleCase]);

      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = unionDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestUnion');

      final spec = ContractSpec([unionEntry]);
      final unionVal = NativeUnionVal.tupleCase('Data', [42]);
      final result = spec.nativeToXdrSCVal(unionVal, udtType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
      expect(result.vec, hasLength(2));
    });

    test('throws when union case not found', () {
      final voidCase = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0);
      voidCase.voidCase = XdrSCSpecUDTUnionCaseVoidV0('', 'Success');

      final unionDef = XdrSCSpecUDTUnionV0('', '', 'TestUnion', [voidCase]);

      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = unionDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestUnion');

      final spec = ContractSpec([unionEntry]);
      final unionVal = NativeUnionVal.voidCase('Unknown');

      expect(
        () => spec.nativeToXdrSCVal(unionVal, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when union tuple case has null value', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final tupleCase = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0);
      tupleCase.tupleCase = XdrSCSpecUDTUnionCaseTupleV0('', 'Data', [u32Type]);

      final unionDef = XdrSCSpecUDTUnionV0('', '', 'TestUnion', [tupleCase]);

      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = unionDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestUnion');

      final spec = ContractSpec([unionEntry]);
      final unionVal = NativeUnionVal.voidCase('Data');

      expect(
        () => spec.nativeToXdrSCVal(unionVal, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when union tuple case has wrong number of values', () {
      final u32Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      final tupleCase = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0);
      tupleCase.tupleCase = XdrSCSpecUDTUnionCaseTupleV0('', 'Data', [u32Type]);

      final unionDef = XdrSCSpecUDTUnionV0('', '', 'TestUnion', [tupleCase]);

      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = unionDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestUnion');

      final spec = ContractSpec([unionEntry]);
      final unionVal = NativeUnionVal.tupleCase('Data', [42, 100]);

      expect(
        () => spec.nativeToXdrSCVal(unionVal, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when union type receives non-NativeUnionVal', () {
      final voidCase = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0);
      voidCase.voidCase = XdrSCSpecUDTUnionCaseVoidV0('', 'Success');

      final unionDef = XdrSCSpecUDTUnionV0('', '', 'TestUnion', [voidCase]);

      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      unionEntry.udtUnionV0 = unionDef;

      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestUnion');

      final spec = ContractSpec([unionEntry]);

      expect(
        () => spec.nativeToXdrSCVal('not a union', udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when UDT type is null', () {
      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);

      final spec = ContractSpec([]);

      expect(
        () => spec.nativeToXdrSCVal({}, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('throws when UDT entry not found', () {
      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('Unknown');

      final spec = ContractSpec([]);

      expect(
        () => spec.nativeToXdrSCVal({}, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpec - Type Inference', () {
    test('infers bool type', () {
      final spec = ContractSpec([]);
      final result = spec.nativeToXdrSCVal(true, XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(result.discriminant, equals(XdrSCValType.SCV_BOOL));
    });

    test('infers u32 for small positive int', () {
      final spec = ContractSpec([]);
      final result = spec.nativeToXdrSCVal(100, XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(result.discriminant, equals(XdrSCValType.SCV_U32));
    });

    test('infers i32 for small negative int', () {
      final spec = ContractSpec([]);
      final result = spec.nativeToXdrSCVal(-100, XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(result.discriminant, equals(XdrSCValType.SCV_I32));
    });

    test('infers i64 for large int', () {
      final spec = ContractSpec([]);
      final result = spec.nativeToXdrSCVal(5000000000, XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(result.discriminant, equals(XdrSCValType.SCV_I64));
    });

    test('infers string type', () {
      final spec = ContractSpec([]);
      final result = spec.nativeToXdrSCVal('hello', XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(result.discriminant, equals(XdrSCValType.SCV_STRING));
    });

    test('infers vec type for list', () {
      final spec = ContractSpec([]);
      final result = spec.nativeToXdrSCVal([1, 2, 3], XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
    });

    test('infers map type for map', () {
      final spec = ContractSpec([]);
      final result = spec.nativeToXdrSCVal({'key': 'value'}, XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(result.discriminant, equals(XdrSCValType.SCV_MAP));
    });

    test('throws when type cannot be inferred', () {
      final spec = ContractSpec([]);

      expect(
        () => spec.nativeToXdrSCVal(Object(), XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL)),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpecException', () {
    test('functionNotFound creates correct exception', () {
      final exception = ContractSpecException.functionNotFound('transfer');

      expect(exception.message, contains('Function not found'));
      expect(exception.functionName, equals('transfer'));
      expect(exception.toString(), contains('transfer'));
    });

    test('argumentNotFound creates correct exception', () {
      final exception = ContractSpecException.argumentNotFound('amount', functionName: 'transfer');

      expect(exception.message, contains('Required argument not found'));
      expect(exception.argumentName, equals('amount'));
      expect(exception.functionName, equals('transfer'));
      expect(exception.toString(), contains('amount'));
      expect(exception.toString(), contains('transfer'));
    });

    test('entryNotFound creates correct exception', () {
      final exception = ContractSpecException.entryNotFound('TestStruct');

      expect(exception.message, contains('Entry not found'));
      expect(exception.entryName, equals('TestStruct'));
      expect(exception.toString(), contains('TestStruct'));
    });

    test('invalidType creates correct exception', () {
      final exception = ContractSpecException.invalidType('Expected bool, got String');

      expect(exception.message, contains('Invalid type'));
      expect(exception.toString(), contains('Expected bool'));
    });

    test('conversionFailed creates correct exception', () {
      final exception = ContractSpecException.conversionFailed('Cannot convert to bytes');

      expect(exception.message, contains('Conversion failed'));
      expect(exception.toString(), contains('Cannot convert'));
    });

    test('invalidEnumValue creates correct exception', () {
      final exception = ContractSpecException.invalidEnumValue('Unknown case INVALID');

      expect(exception.message, contains('Invalid enum value'));
      expect(exception.toString(), contains('INVALID'));
    });
  });

  group('NativeUnionVal - Roundtrip Tests', () {
    test('voidCase constructor creates void case', () {
      final unionVal = NativeUnionVal.voidCase('Success');

      expect(unionVal.tag, equals('Success'));
      expect(unionVal.values, isNull);
      expect(unionVal.isVoidCase, isTrue);
      expect(unionVal.isTupleCase, isFalse);
    });

    test('tupleCase constructor creates tuple case', () {
      final unionVal = NativeUnionVal.tupleCase('Data', [1, 2, 3]);

      expect(unionVal.tag, equals('Data'));
      expect(unionVal.values, equals([1, 2, 3]));
      expect(unionVal.isVoidCase, isFalse);
      expect(unionVal.isTupleCase, isTrue);
    });

    test('generic constructor with values', () {
      final unionVal = NativeUnionVal('Data', values: [1, 2]);

      expect(unionVal.tag, equals('Data'));
      expect(unionVal.values, equals([1, 2]));
      expect(unionVal.isTupleCase, isTrue);
    });

    test('generic constructor without values', () {
      final unionVal = NativeUnionVal('Success');

      expect(unionVal.tag, equals('Success'));
      expect(unionVal.values, isNull);
      expect(unionVal.isVoidCase, isTrue);
    });

    test('equality for void cases', () {
      final val1 = NativeUnionVal.voidCase('Success');
      final val2 = NativeUnionVal.voidCase('Success');
      final val3 = NativeUnionVal.voidCase('Failure');

      expect(val1, equals(val2));
      expect(val1, isNot(equals(val3)));
    });

    test('equality for tuple cases', () {
      final val1 = NativeUnionVal.tupleCase('Data', [1, 2]);
      final val2 = NativeUnionVal.tupleCase('Data', [1, 2]);
      final val3 = NativeUnionVal.tupleCase('Data', [1, 3]);

      expect(val1, equals(val2));
      expect(val1, isNot(equals(val3)));
    });

    test('hashCode for void case', () {
      final val1 = NativeUnionVal.voidCase('Success');
      final val2 = NativeUnionVal.voidCase('Success');

      expect(val1.hashCode, equals(val2.hashCode));
    });

    test('hashCode for tuple case', () {
      final val1 = NativeUnionVal.tupleCase('Data', [1, 2]);
      final val2 = NativeUnionVal.tupleCase('Data', [1, 2]);

      expect(val1.hashCode, equals(val2.hashCode));
    });

    test('toString for void case', () {
      final unionVal = NativeUnionVal.voidCase('Success');

      expect(unionVal.toString(), equals('NativeUnionVal.voidCase(Success)'));
    });

    test('toString for tuple case', () {
      final unionVal = NativeUnionVal.tupleCase('Data', [1, 2]);

      expect(unionVal.toString(), equals('NativeUnionVal.tupleCase(Data, [1, 2])'));
    });
  });

  group('ContractSpec - Uncovered Error Paths and Edge Cases', () {
    test('nativeToXdrSCVal with unsupported default type throws', () {
      final spec = ContractSpec([]);
      final unsupportedType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);

      expect(
        () => spec.nativeToXdrSCVal(123, unsupportedType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleValueType with SC_SPEC_TYPE_VOID returns void', () {
      final spec = ContractSpec([]);
      final voidType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VOID);

      final result = spec.nativeToXdrSCVal(null, voidType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VOID));
    });

    test('_handleValueType with unsupported value type throws', () {
      final spec = ContractSpec([]);
      final unsupportedType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);

      expect(
        () => spec.nativeToXdrSCVal('test', unsupportedType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_inferType with BigInt returns i128', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
      final bigValue = BigInt.from(9223372036854775807);

      final result = spec.nativeToXdrSCVal(bigValue, valType);

      expect(result.discriminant, equals(XdrSCValType.SCV_I128));
    });

    test('_inferType with Uint8List returns vec due to List check', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final result = spec.nativeToXdrSCVal(bytes, valType);

      // Note: Uint8List is caught by List check before Uint8List check
      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
    });

    test('_inferType with unsupported type throws', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);

      expect(
        () => spec.nativeToXdrSCVal(DateTime.now(), valType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleU128Type with string value that cannot be parsed throws', () {
      final spec = ContractSpec([]);
      final u128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128);

      expect(
        () => spec.nativeToXdrSCVal('not_a_number', u128Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleI128Type with string value that cannot be parsed throws', () {
      final spec = ContractSpec([]);
      final i128Type = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I128);

      expect(
        () => spec.nativeToXdrSCVal('not_a_number', i128Type),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleVecValue with non-List throws', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32));

      expect(
        () => spec.nativeToXdrSCVal('not a list', vecType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleMapValue with non-Map throws', () {
      final spec = ContractSpec([]);
      final mapType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_MAP);
      mapType.map = XdrSCSpecTypeMap(
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING),
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
      );

      expect(
        () => spec.nativeToXdrSCVal('not a map', mapType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_inferAndConvert with null returns void', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      final result = spec.nativeToXdrSCVal([null], vecType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
      expect(result.vec!.length, equals(1));
      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_VOID));
    });

    test('_inferAndConvert with negative int in i32 range returns i32', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      final result = spec.nativeToXdrSCVal([-1000], vecType);

      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_I32));
    });

    test('_inferAndConvert with large positive int returns i64', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));
      final largeInt = 0xFFFFFFFF + 1;

      final result = spec.nativeToXdrSCVal([largeInt], vecType);

      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_I64));
    });

    test('_inferAndConvert with nested List', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      final result = spec.nativeToXdrSCVal([[1, 2, 3]], vecType);

      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_VEC));
    });

    test('_inferAndConvert with nested Map', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      final result = spec.nativeToXdrSCVal([{'key': 'value'}], vecType);

      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_MAP));
    });

    test('_inferAndConvert with unsupported type throws', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      expect(
        () => spec.nativeToXdrSCVal([DateTime.now()], vecType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleOptionType with null returns void', () {
      final spec = ContractSpec([]);
      final optionType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_OPTION);
      optionType.option = XdrSCSpecTypeOption(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32));

      final result = spec.nativeToXdrSCVal(null, optionType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VOID));
    });

    test('_handleUDTType with unsupported entry kind throws', () {
      final spec = ContractSpec([
        XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0),
      ]);
      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestType');

      expect(
        () => spec.nativeToXdrSCVal({'field': 'value'}, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleStructType with missing field throws', () {
      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0(
        '',
        '',
        'TestStruct',
        [
          XdrSCSpecUDTStructFieldV0(
            '',
            'field1',
            XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
          ),
        ],
      );

      final spec = ContractSpec([structEntry]);
      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestStruct');

      expect(
        () => spec.nativeToXdrSCVal(<String, dynamic>{}, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleStructType with numeric fields uses vector representation', () {
      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0(
        '',
        '',
        'TestStruct',
        [
          XdrSCSpecUDTStructFieldV0(
            '',
            '0',
            XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
          ),
          XdrSCSpecUDTStructFieldV0(
            '',
            '1',
            XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
          ),
        ],
      );

      final spec = ContractSpec([structEntry]);
      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestStruct');

      final result = spec.nativeToXdrSCVal({'0': 10, '1': 20}, udtType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
    });

    test('_handleStructType with numeric fields missing throws', () {
      final structEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      structEntry.udtStructV0 = XdrSCSpecUDTStructV0(
        '',
        '',
        'TestStruct',
        [
          XdrSCSpecUDTStructFieldV0(
            '',
            '0',
            XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
          ),
        ],
      );

      final spec = ContractSpec([structEntry]);
      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestStruct');

      expect(
        () => spec.nativeToXdrSCVal(<String, dynamic>{}, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });

    test('_handleUnionType with tuple case and null tuple case throws', () {
      final unionEntry = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      final unionCase = XdrSCSpecUDTUnionCaseV0(
        XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0,
      );
      unionCase.tupleCase = null;

      unionEntry.udtUnionV0 = XdrSCSpecUDTUnionV0(
        '',
        '',
        'TestUnion',
        [unionCase],
      );

      final spec = ContractSpec([unionEntry]);
      final udtType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      udtType.udt = XdrSCSpecTypeUDT('TestUnion');

      final unionVal = NativeUnionVal('TestCase', values: [42]);

      expect(
        () => spec.nativeToXdrSCVal(unionVal, udtType),
        throwsA(isA<ContractSpecException>()),
      );
    });
  });

  group('ContractSpec - Type Inference and Conversion', () {
    test('_inferType with i32 range negative int', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);

      final result = spec.nativeToXdrSCVal(-1, valType);

      expect(result.discriminant, equals(XdrSCValType.SCV_I32));
    });

    test('_inferType with i64 range int', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
      final largeValue = 0xFFFFFFFF + 1;

      final result = spec.nativeToXdrSCVal(largeValue, valType);

      expect(result.discriminant, equals(XdrSCValType.SCV_I64));
    });

    test('_inferType with Map infers map type', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
      final map = {'key': 'value'};

      final result = spec.nativeToXdrSCVal(map, valType);

      expect(result.discriminant, equals(XdrSCValType.SCV_MAP));
    });

    test('_inferType with List infers vec type', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
      final list = [1, 2, 3];

      final result = spec.nativeToXdrSCVal(list, valType);

      expect(result.discriminant, equals(XdrSCValType.SCV_VEC));
    });

    test('_inferType recursively converts list elements', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
      final list = [1, 'test', true];

      final result = spec.nativeToXdrSCVal(list, valType);

      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_U32));
      expect(result.vec![1].discriminant, equals(XdrSCValType.SCV_STRING));
      expect(result.vec![2].discriminant, equals(XdrSCValType.SCV_BOOL));
    });

    test('_inferType recursively converts map entries', () {
      final spec = ContractSpec([]);
      final valType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);
      final map = {'count': 42, 'name': 'test'};

      final result = spec.nativeToXdrSCVal(map, valType);

      expect(result.map!.length, equals(2));
    });

    test('_inferAndConvert with XdrSCVal returns as-is', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));
      final scVal = XdrSCVal.forU32(42);

      final result = spec.nativeToXdrSCVal([scVal], vecType);

      expect(result.vec![0], equals(scVal));
    });

    test('_inferAndConvert with bool returns bool', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      final result = spec.nativeToXdrSCVal([true], vecType);

      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_BOOL));
      expect(result.vec![0].b, equals(true));
    });

    test('_inferAndConvert with string returns string', () {
      final spec = ContractSpec([]);
      final vecType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      vecType.vec = XdrSCSpecTypeVec(XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL));

      final result = spec.nativeToXdrSCVal(['hello'], vecType);

      expect(result.vec![0].discriminant, equals(XdrSCValType.SCV_STRING));
      expect(result.vec![0].str, equals('hello'));
    });
  });
}