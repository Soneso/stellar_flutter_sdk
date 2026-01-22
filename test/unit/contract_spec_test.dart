// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/src/soroban/contract_spec.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_contract.dart';
import 'dart:typed_data';

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