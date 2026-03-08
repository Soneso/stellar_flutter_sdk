// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Tests for XDR Contract types that go beyond simple roundtrip encode/decode.
  // Focuses on: enum value assertions, factory methods, edge cases.
  // Simple roundtrips are covered by auto-generated tests in test/unit/xdr/generated/.

  group('XDR Contract Types - Enum value assertions', () {
    test('XdrSCValType enum values', () {
      expect(XdrSCValType.SCV_BOOL.value, equals(0));
      expect(XdrSCValType.SCV_VOID.value, equals(1));
      expect(XdrSCValType.SCV_ERROR.value, equals(2));
      expect(XdrSCValType.SCV_U32.value, equals(3));
      expect(XdrSCValType.SCV_I32.value, equals(4));
      expect(XdrSCValType.SCV_U64.value, equals(5));
      expect(XdrSCValType.SCV_I64.value, equals(6));
      expect(XdrSCValType.SCV_TIMEPOINT.value, equals(7));
      expect(XdrSCValType.SCV_DURATION.value, equals(8));
      expect(XdrSCValType.SCV_U128.value, equals(9));
      expect(XdrSCValType.SCV_I128.value, equals(10));
      expect(XdrSCValType.SCV_U256.value, equals(11));
      expect(XdrSCValType.SCV_I256.value, equals(12));
      expect(XdrSCValType.SCV_BYTES.value, equals(13));
      expect(XdrSCValType.SCV_STRING.value, equals(14));
      expect(XdrSCValType.SCV_SYMBOL.value, equals(15));
      expect(XdrSCValType.SCV_VEC.value, equals(16));
      expect(XdrSCValType.SCV_MAP.value, equals(17));
      expect(XdrSCValType.SCV_ADDRESS.value, equals(18));
    });

    test('XdrSCAddressType enum values', () {
      expect(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT.value, equals(0));
      expect(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value, equals(1));
    });

    test('XdrContractExecutableType enum values', () {
      expect(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value, equals(0));
      expect(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value, equals(1));
    });

    test('XdrContractDataDurability enum values', () {
      expect(XdrContractDataDurability.TEMPORARY.value, equals(0));
      expect(XdrContractDataDurability.PERSISTENT.value, equals(1));
    });

    test('XdrSCErrorType all enum values', () {
      expect(XdrSCErrorType.SCE_CONTRACT.value, equals(0));
      expect(XdrSCErrorType.SCE_WASM_VM.value, equals(1));
      expect(XdrSCErrorType.SCE_CONTEXT.value, equals(2));
      expect(XdrSCErrorType.SCE_STORAGE.value, equals(3));
      expect(XdrSCErrorType.SCE_OBJECT.value, equals(4));
      expect(XdrSCErrorType.SCE_CRYPTO.value, equals(5));
      expect(XdrSCErrorType.SCE_EVENTS.value, equals(6));
      expect(XdrSCErrorType.SCE_BUDGET.value, equals(7));
      expect(XdrSCErrorType.SCE_VALUE.value, equals(8));
      expect(XdrSCErrorType.SCE_AUTH.value, equals(9));
    });

    test('XdrSCErrorCode all enum values', () {
      expect(XdrSCErrorCode.SCEC_ARITH_DOMAIN.value, equals(0));
      expect(XdrSCErrorCode.SCEC_INDEX_BOUNDS.value, equals(1));
      expect(XdrSCErrorCode.SCEC_INVALID_INPUT.value, equals(2));
      expect(XdrSCErrorCode.SCEC_MISSING_VALUE.value, equals(3));
      expect(XdrSCErrorCode.SCEC_EXISTING_VALUE.value, equals(4));
      expect(XdrSCErrorCode.SCEC_EXCEEDED_LIMIT.value, equals(5));
      expect(XdrSCErrorCode.SCEC_INVALID_ACTION.value, equals(6));
      expect(XdrSCErrorCode.SCEC_INTERNAL_ERROR.value, equals(7));
      expect(XdrSCErrorCode.SCEC_UNEXPECTED_TYPE.value, equals(8));
      expect(XdrSCErrorCode.SCEC_UNEXPECTED_SIZE.value, equals(9));
    });
  });

  group('XDR Contract Types - Factory methods', () {
    test('XdrContractExecutable.forWasm factory', () {
      var wasmHash = Uint8List.fromList(List<int>.filled(32, 0xCD));
      var original = XdrContractExecutable.forWasm(wasmHash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractExecutable.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractExecutable.decode(input);

      expect(decoded.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
      expect(decoded.wasmHash!.hash, equals(wasmHash));
    });

    test('XdrContractExecutable.forAsset factory', () {
      var original = XdrContractExecutable.forAsset();

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractExecutable.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractExecutable.decode(input);

      expect(decoded.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value));
      expect(decoded.wasmHash, isNull);
    });

    test('XdrSCVal.forBool factory', () {
      var trueVal = XdrSCVal.forBool(true);
      var falseVal = XdrSCVal.forBool(false);

      expect(trueVal.discriminant.value, equals(XdrSCValType.SCV_BOOL.value));
      expect(trueVal.b, equals(true));
      expect(falseVal.b, equals(false));
    });

    test('XdrSCVal.forVoid factory', () {
      var original = XdrSCVal.forVoid();
      expect(original.discriminant.value, equals(XdrSCValType.SCV_VOID.value));
    });

    test('XdrSCVal.forU32 factory', () {
      var original = XdrSCVal.forU32(42);
      expect(original.discriminant.value, equals(XdrSCValType.SCV_U32.value));
      expect(original.u32!.uint32, equals(42));
    });

    test('XdrSCVal.forI32 factory', () {
      var original = XdrSCVal.forI32(-12345);
      expect(original.discriminant.value, equals(XdrSCValType.SCV_I32.value));
      expect(original.i32!.int32, equals(-12345));
    });

    test('XdrSCVal.forU64 factory', () {
      var original = XdrSCVal.forU64(BigInt.from(9876543210));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_U64.value));
      expect(original.u64!.uint64, equals(BigInt.from(9876543210)));
    });

    test('XdrSCVal.forI64 factory', () {
      var original = XdrSCVal.forI64(BigInt.from(-9876543210));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_I64.value));
      expect(original.i64!.int64, equals(BigInt.from(-9876543210)));
    });

    test('XdrSCVal.forTimepoint factory', () {
      var original = XdrSCVal.forTimepoint(BigInt.from(1640000000));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_TIMEPOINT.value));
      expect(original.timepoint!.uint64, equals(BigInt.from(1640000000)));
    });

    test('XdrSCVal.forDuration factory', () {
      var original = XdrSCVal.forDuration(BigInt.from(3600));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_DURATION.value));
      expect(original.duration!.uint64, equals(BigInt.from(3600)));
    });

    test('XdrSCVal.forU128Parts factory', () {
      var original = XdrSCVal.forU128Parts(BigInt.from(123456789), BigInt.from(987654321));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_U128.value));
      expect(original.u128!.hi.uint64, equals(BigInt.from(123456789)));
      expect(original.u128!.lo.uint64, equals(BigInt.from(987654321)));
    });

    test('XdrSCVal.forI128Parts factory', () {
      var original = XdrSCVal.forI128Parts(BigInt.from(-123456789), BigInt.from(987654321));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_I128.value));
      expect(original.i128!.hi.int64, equals(BigInt.from(-123456789)));
    });

    test('XdrSCVal.forU256Parts factory', () {
      var original = XdrSCVal.forU256Parts(BigInt.from(111), BigInt.from(222), BigInt.from(333), BigInt.from(444));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_U256.value));
      expect(original.u256!.hiHi.uint64, equals(BigInt.from(111)));
    });

    test('XdrSCVal.forI256Parts factory', () {
      var original = XdrSCVal.forI256Parts(BigInt.from(-111), BigInt.from(222), BigInt.from(333), BigInt.from(444));
      expect(original.discriminant.value, equals(XdrSCValType.SCV_I256.value));
      expect(original.i256!.hiHi.int64, equals(BigInt.from(-111)));
    });

    test('XdrSCVal.forBytes factory', () {
      var bytes = Uint8List.fromList([0x01, 0x02, 0x03]);
      var original = XdrSCVal.forBytes(bytes);
      expect(original.discriminant.value, equals(XdrSCValType.SCV_BYTES.value));
      expect(original.bytes!.sCBytes, equals(bytes));
    });

    test('XdrSCVal.forString factory', () {
      var original = XdrSCVal.forString('Hello Stellar');
      expect(original.discriminant.value, equals(XdrSCValType.SCV_STRING.value));
      expect(original.str, equals('Hello Stellar'));
    });

    test('XdrSCVal.forSymbol factory', () {
      var original = XdrSCVal.forSymbol('my_symbol');
      expect(original.discriminant.value, equals(XdrSCValType.SCV_SYMBOL.value));
      expect(original.sym, equals('my_symbol'));
    });

    test('XdrSCVal.forVec factory', () {
      var vec = [XdrSCVal.forU32(1), XdrSCVal.forU32(2), XdrSCVal.forU32(3)];
      var original = XdrSCVal.forVec(vec);
      expect(original.discriminant.value, equals(XdrSCValType.SCV_VEC.value));
      expect(original.vec!.length, equals(3));
    });

    test('XdrSCVal.forMap factory', () {
      var map = [
        XdrSCMapEntry(XdrSCVal.forString('key1'), XdrSCVal.forU32(100)),
      ];
      var original = XdrSCVal.forMap(map);
      expect(original.discriminant.value, equals(XdrSCValType.SCV_MAP.value));
      expect(original.map!.length, equals(1));
    });

    test('XdrSCVal.forAddress factory', () {
      var publicKey = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      publicKey.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99))));
      var accountId = XdrAccountID(publicKey);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = accountId;

      var original = XdrSCVal.forAddress(address);
      expect(original.discriminant.value, equals(XdrSCValType.SCV_ADDRESS.value));
      expect(original.address!.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT.value));
    });

    test('XdrSCVal.forError factory', () {
      var error = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      error.contractCode = XdrUint32(999);

      var original = XdrSCVal.forError(error);
      expect(original.discriminant.value, equals(XdrSCValType.SCV_ERROR.value));
      expect(original.error!.contractCode!.uint32, equals(999));
    });

    test('XdrInt128Parts.forHiLo factory', () {
      var original = XdrInt128Parts.forHiLo(BigInt.from(-12345), BigInt.from(67890));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt128Parts.decode(input);

      expect(decoded.hi.int64, equals(BigInt.from(-12345)));
      expect(decoded.lo.uint64, equals(BigInt.from(67890)));
    });

    test('XdrInt256Parts.forHiHiHiLoLoHiLoLo factory', () {
      var original = XdrInt256Parts.forHiHiHiLoLoHiLoLo(
        BigInt.from(-999), BigInt.from(111), BigInt.from(222), BigInt.from(333));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt256Parts.decode(input);

      expect(decoded.hiHi.int64, equals(BigInt.from(-999)));
      expect(decoded.hiLo.uint64, equals(BigInt.from(111)));
    });
  });

  group('XDR Contract Types - Max values', () {
    test('XdrUInt128Parts with max values', () {
      var original = XdrUInt128Parts.forHiLo(
        BigInt.parse('18446744073709551615'),
        BigInt.parse('18446744073709551615'),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt128Parts.decode(input);

      expect(decoded.hi.uint64, equals(BigInt.parse('18446744073709551615')));
      expect(decoded.lo.uint64, equals(BigInt.parse('18446744073709551615')));
    });

    test('XdrUInt256Parts with large values', () {
      var original = XdrUInt256Parts.forHiHiHiLoLoHiLoLo(
        BigInt.parse('9999999999999999999'),
        BigInt.parse('8888888888888888888'),
        BigInt.parse('7777777777777777777'),
        BigInt.parse('6666666666666666666'),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt256Parts.decode(input);

      expect(decoded.hiHi.uint64, equals(BigInt.parse('9999999999999999999')));
      expect(decoded.hiLo.uint64, equals(BigInt.parse('8888888888888888888')));
    });

    test('Large XdrUInt128Parts values', () {
      var original = XdrUInt128Parts.forHiLo(
        BigInt.parse('9223372036854775807'),
        BigInt.parse('18446744073709551615'),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt128Parts.decode(input);

      expect(decoded.hi.uint64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.lo.uint64, equals(BigInt.parse('18446744073709551615')));
    });
  });

  group('XDR Contract Types - Complex scenarios', () {
    test('Nested XdrSCVal vectors', () {
      var innerVec1 = XdrSCVal.forVec([XdrSCVal.forU32(1), XdrSCVal.forU32(2)]);
      var innerVec2 = XdrSCVal.forVec([XdrSCVal.forU32(3), XdrSCVal.forU32(4)]);
      var outerVec = XdrSCVal.forVec([innerVec1, innerVec2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, outerVec);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.vec!.length, equals(2));
      expect(decoded.vec![0].vec![0].u32!.uint32, equals(1));
      expect(decoded.vec![1].vec![1].u32!.uint32, equals(4));
    });

    test('XdrSCVal map with complex values', () {
      var map = [
        XdrSCMapEntry(
          XdrSCVal.forSymbol('balance'),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000000)),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('decimals'),
          XdrSCVal.forU32(7),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('name'),
          XdrSCVal.forString('Test Token'),
        ),
      ];
      var original = XdrSCVal.forMap(map);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.map!.length, equals(3));
      expect(decoded.map![0].key.sym, equals('balance'));
      expect(decoded.map![0].val.i128!.lo.uint64, equals(BigInt.from(1000000)));
      expect(decoded.map![2].val.str, equals('Test Token'));
    });

    test('XdrSCVal error in vec', () {
      var error = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      error.contractCode = XdrUint32(999);

      var vec = [
        XdrSCVal.forU32(1),
        XdrSCVal.forError(error),
        XdrSCVal.forString('after error'),
      ];
      var original = XdrSCVal.forVec(vec);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.vec!.length, equals(3));
      expect(decoded.vec![1].error!.contractCode!.uint32, equals(999));
      expect(decoded.vec![2].str, equals('after error'));
    });

    test('XdrSCVal SCV_STRING with empty string', () {
      var original = XdrSCVal.forString('');

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.str, equals(''));
    });
  });

  group('XDR Contract Types - XdrSCContractInstance', () {
    test('XdrSCContractInstance with WASM executable and no storage', () {
      var wasmHash = Uint8List.fromList(List<int>.filled(32, 0xEE));
      var executable = XdrContractExecutable.forWasm(wasmHash);

      var original = XdrSCContractInstance(executable, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCContractInstance.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCContractInstance.decode(input);

      expect(decoded.executable.wasmHash!.hash, equals(wasmHash));
      expect(decoded.storage, isNull);
    });

    test('XdrSCContractInstance with storage entries', () {
      var executable = XdrContractExecutable.forAsset();
      var storage = [
        XdrSCMapEntry(XdrSCVal.forString('key1'), XdrSCVal.forU32(100)),
        XdrSCMapEntry(XdrSCVal.forString('key2'), XdrSCVal.forU32(200)),
      ];

      var original = XdrSCContractInstance(executable, storage);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCContractInstance.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCContractInstance.decode(input);

      expect(decoded.storage!.length, equals(2));
      expect(decoded.storage![0].key.str, equals('key1'));
    });
  });

  group('XDR Contract Types - XdrSCNonceKey edge cases', () {
    test('XdrSCNonceKey with negative nonce', () {
      var original = XdrSCNonceKey(XdrInt64(BigInt.from(-999999)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCNonceKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCNonceKey.decode(input);

      expect(decoded.nonce.int64, equals(BigInt.from(-999999)));
    });
  });

  group('XDR Contract Types - XdrSCMapEntry with factory methods', () {
    test('XdrSCMapEntry with factory-created values', () {
      var key = XdrSCVal.forString('key1');
      var val = XdrSCVal.forU32(42);

      var original = XdrSCMapEntry(key, val);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCMapEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCMapEntry.decode(input);

      expect(decoded.key.str, equals('key1'));
      expect(decoded.val.u32!.uint32, equals(42));
    });

    test('XdrSCMapEntry with complex values', () {
      var key = XdrSCVal.forSymbol('complexKey');
      var val = XdrSCVal.forI64(BigInt.from(-999999));

      var original = XdrSCMapEntry(key, val);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCMapEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCMapEntry.decode(input);

      expect(decoded.key.sym, equals('complexKey'));
      expect(decoded.val.i64!.int64, equals(BigInt.from(-999999)));
    });
  });
}
