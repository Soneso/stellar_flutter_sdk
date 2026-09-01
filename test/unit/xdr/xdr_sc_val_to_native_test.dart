// Tests for XdrSCVal.toNative(), the best-effort conversion of a smart
// contract value to native Dart values. Every arm of the conversion contract
// is pinned here: the per-type conversions, the BigInt rules for every
// 64-bit-and-wider integer, the map key rules including the sentinel
// design, both map fallback triggers, null-payload handling for every arm
// that can carry one, and totality for ill-formed payloads that only
// direct construction (never decode()) can produce.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('scalars', () {
    test('bool converts to bool', () {
      expect(XdrSCVal.forBool(true).toNative(), true);
      expect(XdrSCVal.forBool(false).toNative(), false);
    });

    test('void converts to null', () {
      expect(XdrSCVal.forVoid().toNative(), isNull);
    });

    test('u32 converts to int', () {
      expect(XdrSCVal.forU32(0).toNative(), 0);
      expect(XdrSCVal.forU32(4294967295).toNative(), 4294967295);
    });

    test('i32 converts to int', () {
      expect(XdrSCVal.forI32(-2147483648).toNative(), -2147483648);
      expect(XdrSCVal.forI32(2147483647).toNative(), 2147483647);
    });

    test('u64 converts to BigInt, never int', () {
      final zero = XdrSCVal.forU64(BigInt.zero).toNative();
      expect(zero, isA<BigInt>());
      expect(zero, BigInt.zero);

      final max = XdrSCVal.forU64(
        BigInt.parse('18446744073709551615'),
      ).toNative();
      expect(max, isA<BigInt>());
      expect(max, BigInt.parse('18446744073709551615'));
    });

    test('i64 converts to BigInt, never int', () {
      final min = XdrSCVal.forI64(
        BigInt.parse('-9223372036854775808'),
      ).toNative();
      expect(min, isA<BigInt>());
      expect(min, BigInt.parse('-9223372036854775808'));

      final max = XdrSCVal.forI64(
        BigInt.parse('9223372036854775807'),
      ).toNative();
      expect(max, isA<BigInt>());
      expect(max, BigInt.parse('9223372036854775807'));
    });

    test('timepoint and duration convert to BigInt, never int', () {
      final timepoint = XdrSCVal.forTimepoint(
        BigInt.parse('1700000000'),
      ).toNative();
      expect(timepoint, isA<BigInt>());
      expect(timepoint, BigInt.parse('1700000000'));

      final duration = XdrSCVal.forDuration(
        BigInt.parse('18446744073709551615'),
      ).toNative();
      expect(duration, isA<BigInt>());
      expect(duration, BigInt.parse('18446744073709551615'));
    });
  });

  group('128-bit and 256-bit integers', () {
    test('u128 converts to BigInt at its extreme (2^128-1)', () {
      final result = XdrSCVal.forU128BigInt(
        BigInt.parse('340282366920938463463374607431768211455'),
      ).toNative();
      expect(result, isA<BigInt>());
      expect(result, BigInt.parse('340282366920938463463374607431768211455'));
    });

    test('i128 converts to BigInt at its extremes (-2^127 and -1)', () {
      final min = XdrSCVal.forI128BigInt(
        BigInt.parse('-170141183460469231731687303715884105728'),
      ).toNative();
      expect(min, isA<BigInt>());
      expect(min, BigInt.parse('-170141183460469231731687303715884105728'));

      final negativeOne = XdrSCVal.forI128BigInt(BigInt.from(-1)).toNative();
      expect(negativeOne, BigInt.from(-1));
    });

    test('u256 converts to BigInt at its extreme (2^256-1)', () {
      final result = XdrSCVal.forU256BigInt(
        BigInt.parse(
          '115792089237316195423570985008687907853269984665640564039457584007913129639935',
        ),
      ).toNative();
      expect(result, isA<BigInt>());
      expect(
        result,
        BigInt.parse(
          '115792089237316195423570985008687907853269984665640564039457584007913129639935',
        ),
      );
    });

    test('i256 converts to BigInt at its extreme (-2^255)', () {
      final result = XdrSCVal.forI256BigInt(
        BigInt.parse(
          '-57896044618658097711785492504343953926634992332820282019728792003956564819968',
        ),
      ).toNative();
      expect(result, isA<BigInt>());
      expect(
        result,
        BigInt.parse(
          '-57896044618658097711785492504343953926634992332820282019728792003956564819968',
        ),
      );
    });
  });

  group('bytes, strings and symbols', () {
    test('bytes converts to the stored Uint8List instance', () {
      final bytes = Uint8List.fromList([0, 1, 255]);
      final val = XdrSCVal.forBytes(bytes);
      final result = val.toNative();
      expect(result, isA<Uint8List>());
      expect(result, equals(bytes));
      expect(identical(result, val.bytes!.sCBytes), isTrue);
    });

    test('string converts to String, including multi-byte UTF-8', () {
      expect(XdrSCVal.forString('hello').toNative(), 'hello');
      expect(XdrSCVal.forString('héllo €𝕏').toNative(), 'héllo €𝕏');
    });

    test('symbol converts to String', () {
      expect(XdrSCVal.forSymbol('transfer').toNative(), 'transfer');
    });
  });

  group('vec', () {
    test('a vec converts to a List, elements converted recursively', () {
      final val = XdrSCVal.forVec([
        XdrSCVal.forU32(1),
        XdrSCVal.forSymbol('a'),
        XdrSCVal.forVec([XdrSCVal.forBool(true)]),
      ]);
      expect(
        val.toNative(),
        equals([
          1,
          'a',
          [true],
        ]),
      );
    });

    test('an empty vec converts to an empty List', () {
      expect(XdrSCVal.forVec([]).toNative(), equals([]));
    });

    test('a vec with a null payload converts to an empty List', () {
      final val = XdrSCVal(XdrSCValType.SCV_VEC);
      expect(val.vec, isNull);
      expect(val.toNative(), equals([]));
    });

    test('a vec containing a fallback map keeps that map as an element', () {
      final mapWithVecKey = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forVec([XdrSCVal.forBool(true)]),
          XdrSCVal.forU32(1),
        ),
      ]);
      final val = XdrSCVal.forVec([XdrSCVal.forU32(7), mapWithVecKey]);
      final result = val.toNative() as List<dynamic>;
      expect(result[0], 7);
      expect(result[1], same(mapWithVecKey));
    });
  });

  group('map', () {
    test('symbol keys convert to a Map preserving insertion order', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forSymbol('name'), XdrSCVal.forString('Alice')),
        XdrSCMapEntry(XdrSCVal.forSymbol('age'), XdrSCVal.forU32(30)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result, equals({'name': 'Alice', 'age': 30}));
      expect(result.keys.toList(), equals(['name', 'age']));
    });

    test('u32 keys convert to int keys', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forU32(1), XdrSCVal.forString('one')),
        XdrSCMapEntry(XdrSCVal.forU32(2), XdrSCVal.forString('two')),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result, equals({1: 'one', 2: 'two'}));
      expect(result.keys.toList(), equals([1, 2]));
    });

    test('a string key converts to a String key', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forString('label'), XdrSCVal.forU32(1)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals(['label']));
    });

    test('an i32 key converts to an int key', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forI32(-7), XdrSCVal.forU32(1)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([-7]));
    });

    test('a timepoint key converts to a BigInt key', () {
      final key = BigInt.parse('1700000000');
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forTimepoint(key), XdrSCVal.forU32(1)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([key]));
    });

    test('a duration key converts to a BigInt key', () {
      final key = BigInt.parse('18446744073709551615');
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forDuration(key), XdrSCVal.forU32(1)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([key]));
    });

    test('an i64 key converts to a BigInt key', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forI64(BigInt.from(-5)),
          XdrSCVal.forString('negative five'),
        ),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([BigInt.from(-5)]));
    });

    test('a u64 key at its extreme converts to that BigInt key', () {
      final key = BigInt.parse('18446744073709551615');
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forU64(key), XdrSCVal.forString('max u64')),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([key]));
    });

    test('an i128 key converts to its BigInt via toBigInt()', () {
      final key = BigInt.parse('170141183460469231731687303715884105727');
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forI128BigInt(key),
          XdrSCVal.forString('max i128'),
        ),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([key]));
    });

    test('a bool key converts to a bool key and a void key to null', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forBool(true), XdrSCVal.forU32(1)),
        XdrSCMapEntry(XdrSCVal.forVoid(), XdrSCVal.forU32(2)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([true, null]));
      expect(result[true], 1);
      expect(result[null], 2);
    });

    test('a bytes key converts to a lowercase hex String key', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forBytes(Uint8List.fromList([1, 2])),
          XdrSCVal.forU32(1),
        ),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals(['0102']));
    });

    test('an account address key converts to its StrKey String', () {
      const g = 'GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB';
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forAccountAddress(g), XdrSCVal.forU32(1)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([g]));
    });

    test('a contract address key converts to its StrKey String', () {
      const c = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forContractAddress(c), XdrSCVal.forU32(1)),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.keys.toList(), equals([c]));
    });

    test('a u32 key and a u64 key holding the same number are distinct', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forU32(5), XdrSCVal.forString('u32 five')),
        XdrSCMapEntry(
          XdrSCVal.forU64(BigInt.from(5)),
          XdrSCVal.forString('u64 five'),
        ),
      ]);
      final result = val.toNative() as Map<dynamic, dynamic>;
      expect(result.length, 2);
      expect(result.keys.toList(), equals([5, BigInt.from(5)]));
    });

    test('a vec key makes the whole map fall back to itself', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forVec([XdrSCVal.forU32(1)]),
          XdrSCVal.forU32(1),
        ),
      ]);
      expect(val.toNative(), same(val));
    });

    test('a map key makes the whole map fall back to itself', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forMap([]), XdrSCVal.forU32(1)),
      ]);
      expect(val.toNative(), same(val));
    });

    test('an error key makes the whole map fall back to itself', () {
      final error = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      error.contractCode = XdrUint32(1);
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forError(error), XdrSCVal.forU32(1)),
      ]);
      expect(val.toNative(), same(val));
    });

    test(
      'two entries colliding on the same key fall back to the map itself',
      () {
        final val = XdrSCVal.forMap([
          XdrSCMapEntry(XdrSCVal.forSymbol('a'), XdrSCVal.forU32(1)),
          XdrSCMapEntry(XdrSCVal.forSymbol('a'), XdrSCVal.forU32(2)),
        ]);
        expect(val.toNative(), same(val));
      },
    );

    test(
      'a u64 key and a u128 key holding the same value collide (equal BigInt)',
      () {
        final val = XdrSCVal.forMap([
          XdrSCMapEntry(XdrSCVal.forU64(BigInt.from(7)), XdrSCVal.forU32(1)),
          XdrSCMapEntry(
            XdrSCVal.forU128BigInt(BigInt.from(7)),
            XdrSCVal.forU32(2),
          ),
        ]);
        expect(val.toNative(), same(val));
      },
    );

    test('an empty map converts to an empty Map', () {
      expect(XdrSCVal.forMap([]).toNative(), equals(<dynamic, dynamic>{}));
    });

    test('a map with a null payload converts to an empty Map', () {
      final val = XdrSCVal(XdrSCValType.SCV_MAP);
      expect(val.map, isNull);
      expect(val.toNative(), equals(<dynamic, dynamic>{}));
    });
  });

  group('address values', () {
    test('an account address value converts to an Address', () {
      const g = 'GBBM6BKZPEHWYO3E3YKREDPQXMS4VK35YLNU7NFBRI26RAN7GI5POFBB';
      final native = XdrSCVal.forAccountAddress(g).toNative();
      expect(native, isA<Address>());
      final address = native as Address;
      expect(address.type, Address.TYPE_ACCOUNT);
      expect(address.accountId, g);
    });

    test('a contract address value converts to an Address', () {
      const c = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
      final val = XdrSCVal.forContractAddress(c);
      final native = val.toNative();
      expect(native, isA<Address>());
      final address = native as Address;
      expect(address.type, Address.TYPE_CONTRACT);
      expect(val.address!.toStrKey(), c);
    });
  });

  group('fallback arms returning the value itself', () {
    test('an error value falls back to itself', () {
      final error = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      error.contractCode = XdrUint32(1);
      final val = XdrSCVal.forError(error);
      expect(val.toNative(), same(val));
    });

    test('a contract instance value falls back to itself', () {
      final val = XdrSCVal.forContractInstance(
        XdrSCContractInstance(
          XdrContractExecutable.forWasm(Uint8List(32)),
          null,
        ),
      );
      expect(val.toNative(), same(val));
    });

    test('a ledger-key-contract-instance value falls back to itself', () {
      final val = XdrSCVal.forLedgerKeyContractInstance();
      expect(val.toNative(), same(val));
    });

    test('a ledger-key-nonce value falls back to itself', () {
      final val = XdrSCVal.forLedgerKeyNonce(1);
      expect(val.toNative(), same(val));
    });

    test('an executable tag value falls back to itself', () {
      final val = XdrSCVal.forExecutableTag('token-v1');
      expect(val.toNative(), same(val));
    });

    test('an unrecognized future arm falls back to itself', () {
      final val = XdrSCVal(XdrSCValType(99));
      expect(val.toNative(), same(val));
    });

    test('an unrecognized future arm as a map key falls back the map', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal(XdrSCValType(99)), XdrSCVal.forU32(1)),
      ]);
      expect(val.toNative(), same(val));
    });
  });

  group('ill-formed payloads return the value itself (toNative)', () {
    test('every null-payload arm falls back to the same instance', () {
      final illFormed = <XdrSCVal>[
        XdrSCVal(XdrSCValType.SCV_BOOL),
        XdrSCVal(XdrSCValType.SCV_U32),
        XdrSCVal(XdrSCValType.SCV_I32),
        XdrSCVal(XdrSCValType.SCV_U64),
        XdrSCVal(XdrSCValType.SCV_I64),
        XdrSCVal(XdrSCValType.SCV_TIMEPOINT),
        XdrSCVal(XdrSCValType.SCV_DURATION),
        XdrSCVal(XdrSCValType.SCV_U128),
        XdrSCVal(XdrSCValType.SCV_BYTES),
        XdrSCVal(XdrSCValType.SCV_STRING),
        XdrSCVal(XdrSCValType.SCV_SYMBOL),
        XdrSCVal(XdrSCValType.SCV_ADDRESS),
      ];
      for (final val in illFormed) {
        expect(val.toNative(), same(val));
      }
    });

    test(
      'an ill-formed address value returns the value itself, no exception',
      () {
        final val = XdrSCVal.forAddress(
          XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT),
        );
        expect(val.address!.contractId, isNull);
        expect(val.toNative(), same(val));
      },
    );
  });

  group('ill-formed map key payloads make the map fall back', () {
    test('every null-payload key arm falls back the enclosing map', () {
      final illFormedKeys = <XdrSCVal>[
        XdrSCVal(XdrSCValType.SCV_SYMBOL),
        XdrSCVal(XdrSCValType.SCV_STRING),
        XdrSCVal(XdrSCValType.SCV_U32),
        XdrSCVal(XdrSCValType.SCV_I32),
        XdrSCVal(XdrSCValType.SCV_U64),
        XdrSCVal(XdrSCValType.SCV_I64),
        XdrSCVal(XdrSCValType.SCV_TIMEPOINT),
        XdrSCVal(XdrSCValType.SCV_DURATION),
        XdrSCVal(XdrSCValType.SCV_U128),
        XdrSCVal(XdrSCValType.SCV_BOOL),
        XdrSCVal(XdrSCValType.SCV_BYTES),
        XdrSCVal(XdrSCValType.SCV_ADDRESS),
      ];
      for (final key in illFormedKeys) {
        final mapVal = XdrSCVal.forMap([
          XdrSCMapEntry(key, XdrSCVal.forU32(1)),
        ]);
        expect(mapVal.toNative(), same(mapVal));
      }
    });

    test('an ill-formed address key falls back the enclosing map', () {
      final key = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      final mapVal = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forAddress(key), XdrSCVal.forU32(1)),
      ]);
      expect(key.contractId, isNull);
      expect(mapVal.toNative(), same(mapVal));
    });
  });

  group('round trip through wire format', () {
    test('a decode()-produced tree converts identically to a factory-built '
        'one', () {
      final val = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('items'),
          XdrSCVal.forVec([
            XdrSCVal.forU32(1),
            XdrSCVal.forI128BigInt(
              BigInt.parse('-170141183460469231731687303715884105728'),
            ),
          ]),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('big'),
          XdrSCVal.forU64(BigInt.parse('18446744073709551615')),
        ),
      ]);

      final decoded = XdrSCVal.fromBase64EncodedXdrString(
        val.toBase64EncodedXdrString(),
      );

      expect(decoded.toNative(), equals(val.toNative()));
    });
  });
}
