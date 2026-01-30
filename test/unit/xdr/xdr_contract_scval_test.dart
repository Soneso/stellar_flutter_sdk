// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Contract Types - Deep Branch Testing', () {
    test('XdrSCValType enum all 22 variants', () {
      final types = [
        XdrSCValType.SCV_BOOL,
        XdrSCValType.SCV_VOID,
        XdrSCValType.SCV_ERROR,
        XdrSCValType.SCV_U32,
        XdrSCValType.SCV_I32,
        XdrSCValType.SCV_U64,
        XdrSCValType.SCV_I64,
        XdrSCValType.SCV_TIMEPOINT,
        XdrSCValType.SCV_DURATION,
        XdrSCValType.SCV_U128,
        XdrSCValType.SCV_I128,
        XdrSCValType.SCV_U256,
        XdrSCValType.SCV_I256,
        XdrSCValType.SCV_BYTES,
        XdrSCValType.SCV_STRING,
        XdrSCValType.SCV_SYMBOL,
        XdrSCValType.SCV_VEC,
        XdrSCValType.SCV_MAP,
        XdrSCValType.SCV_ADDRESS,
        XdrSCValType.SCV_CONTRACT_INSTANCE,
        XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE,
        XdrSCValType.SCV_LEDGER_KEY_NONCE,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCValType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCValType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrSCVal SCV_BOOL true encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_BOOL);
      original.b = true;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_BOOL.value));
      expect(decoded.b, equals(true));
    });

    test('XdrSCVal SCV_BOOL false encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_BOOL);
      original.b = false;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_BOOL.value));
      expect(decoded.b, equals(false));
    });

    test('XdrSCVal SCV_VOID encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_VOID);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_VOID.value));
    });

    test('XdrSCVal SCV_ERROR with SCE_CONTRACT encode/decode', () {
      var error = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      error.contractCode = XdrUint32(42);

      var original = XdrSCVal(XdrSCValType.SCV_ERROR);
      original.error = error;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_ERROR.value));
      expect(decoded.error, isNotNull);
      expect(decoded.error!.type.value, equals(XdrSCErrorType.SCE_CONTRACT.value));
      expect(decoded.error!.contractCode!.uint32, equals(42));
    });

    test('XdrSCVal SCV_U32 encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_U32);
      original.u32 = XdrUint32(123456);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U32.value));
      expect(decoded.u32!.uint32, equals(123456));
    });

    test('XdrSCVal SCV_I32 positive encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_I32);
      original.i32 = XdrInt32(98765);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I32.value));
      expect(decoded.i32!.int32, equals(98765));
    });

    test('XdrSCVal SCV_I32 negative encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_I32);
      original.i32 = XdrInt32(-54321);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I32.value));
      expect(decoded.i32!.int32, equals(-54321));
    });

    test('XdrSCVal SCV_U64 encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_U64);
      original.u64 = XdrUint64(BigInt.from(9876543210));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U64.value));
      expect(decoded.u64!.uint64, equals(BigInt.from(9876543210)));
    });

    test('XdrSCVal SCV_I64 positive encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_I64);
      original.i64 = XdrInt64(BigInt.from(1234567890123));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I64.value));
      expect(decoded.i64!.int64, equals(BigInt.from(1234567890123)));
    });

    test('XdrSCVal SCV_I64 negative encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_I64);
      original.i64 = XdrInt64(BigInt.from(-9876543210987));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I64.value));
      expect(decoded.i64!.int64, equals(BigInt.from(-9876543210987)));
    });

    test('XdrSCVal SCV_TIMEPOINT encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_TIMEPOINT);
      original.timepoint = XdrUint64(BigInt.from(1704067200));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_TIMEPOINT.value));
      expect(decoded.timepoint!.uint64, equals(BigInt.from(1704067200)));
    });

    test('XdrSCVal SCV_DURATION encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_DURATION);
      original.duration = XdrUint64(BigInt.from(3600));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_DURATION.value));
      expect(decoded.duration!.uint64, equals(BigInt.from(3600)));
    });

    test('XdrSCVal SCV_U128 encode/decode', () {
      var u128Parts = XdrUInt128Parts(
        XdrUint64(BigInt.from(100)),
        XdrUint64(BigInt.from(200)),
      );

      var original = XdrSCVal(XdrSCValType.SCV_U128);
      original.u128 = u128Parts;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U128.value));
      expect(decoded.u128!.hi.uint64, equals(BigInt.from(100)));
      expect(decoded.u128!.lo.uint64, equals(BigInt.from(200)));
    });

    test('XdrSCVal SCV_I128 encode/decode', () {
      var i128Parts = XdrInt128Parts(
        XdrInt64(BigInt.from(-50)),
        XdrUint64(BigInt.from(150)),
      );

      var original = XdrSCVal(XdrSCValType.SCV_I128);
      original.i128 = i128Parts;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I128.value));
      expect(decoded.i128!.hi.int64, equals(BigInt.from(-50)));
      expect(decoded.i128!.lo.uint64, equals(BigInt.from(150)));
    });

    test('XdrSCVal SCV_U256 encode/decode', () {
      var u256Parts = XdrUInt256Parts(
        XdrUint64(BigInt.from(1000)),
        XdrUint64(BigInt.from(2000)),
        XdrUint64(BigInt.from(3000)),
        XdrUint64(BigInt.from(4000)),
      );

      var original = XdrSCVal(XdrSCValType.SCV_U256);
      original.u256 = u256Parts;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U256.value));
      expect(decoded.u256!.hiHi.uint64, equals(BigInt.from(1000)));
      expect(decoded.u256!.hiLo.uint64, equals(BigInt.from(2000)));
      expect(decoded.u256!.loHi.uint64, equals(BigInt.from(3000)));
      expect(decoded.u256!.loLo.uint64, equals(BigInt.from(4000)));
    });

    test('XdrSCVal SCV_I256 encode/decode', () {
      var i256Parts = XdrInt256Parts(
        XdrInt64(BigInt.from(-500)),
        XdrUint64(BigInt.from(600)),
        XdrUint64(BigInt.from(700)),
        XdrUint64(BigInt.from(800)),
      );

      var original = XdrSCVal(XdrSCValType.SCV_I256);
      original.i256 = i256Parts;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I256.value));
      expect(decoded.i256!.hiHi.int64, equals(BigInt.from(-500)));
      expect(decoded.i256!.hiLo.uint64, equals(BigInt.from(600)));
      expect(decoded.i256!.loHi.uint64, equals(BigInt.from(700)));
      expect(decoded.i256!.loLo.uint64, equals(BigInt.from(800)));
    });

    test('XdrSCVal SCV_BYTES encode/decode', () {
      var bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

      var original = XdrSCVal(XdrSCValType.SCV_BYTES);
      original.bytes = XdrDataValue(bytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_BYTES.value));
      expect(decoded.bytes!.dataValue, equals(bytes));
    });

    test('XdrSCVal SCV_STRING encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_STRING);
      original.str = 'Hello Stellar';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_STRING.value));
      expect(decoded.str, equals('Hello Stellar'));
    });

    test('XdrSCVal SCV_SYMBOL encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_SYMBOL);
      original.sym = 'my_symbol';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_SYMBOL.value));
      expect(decoded.sym, equals('my_symbol'));
    });

    test('XdrSCVal SCV_VEC with empty vector encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_VEC);
      original.vec = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_VEC.value));
      expect(decoded.vec, isNotNull);
      expect(decoded.vec, isEmpty);
    });

    test('XdrSCVal SCV_VEC with elements encode/decode', () {
      var elem1 = XdrSCVal(XdrSCValType.SCV_U32);
      elem1.u32 = XdrUint32(10);
      var elem2 = XdrSCVal(XdrSCValType.SCV_U32);
      elem2.u32 = XdrUint32(20);

      var original = XdrSCVal(XdrSCValType.SCV_VEC);
      original.vec = [elem1, elem2];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_VEC.value));
      expect(decoded.vec, isNotNull);
      expect(decoded.vec!.length, equals(2));
      expect(decoded.vec![0].u32!.uint32, equals(10));
      expect(decoded.vec![1].u32!.uint32, equals(20));
    });

    test('XdrSCVal SCV_MAP with empty map encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_MAP);
      original.map = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_MAP.value));
      expect(decoded.map, isNotNull);
      expect(decoded.map, isEmpty);
    });

    test('XdrSCVal SCV_MAP with entries encode/decode', () {
      var key1 = XdrSCVal(XdrSCValType.SCV_U32);
      key1.u32 = XdrUint32(1);
      var val1 = XdrSCVal(XdrSCValType.SCV_U32);
      val1.u32 = XdrUint32(100);

      var key2 = XdrSCVal(XdrSCValType.SCV_U32);
      key2.u32 = XdrUint32(2);
      var val2 = XdrSCVal(XdrSCValType.SCV_U32);
      val2.u32 = XdrUint32(200);

      var original = XdrSCVal(XdrSCValType.SCV_MAP);
      original.map = [
        XdrSCMapEntry(key1, val1),
        XdrSCMapEntry(key2, val2),
      ];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_MAP.value));
      expect(decoded.map, isNotNull);
      expect(decoded.map!.length, equals(2));
      expect(decoded.map![0].key.u32!.uint32, equals(1));
      expect(decoded.map![0].val.u32!.uint32, equals(100));
      expect(decoded.map![1].key.u32!.uint32, equals(2));
      expect(decoded.map![1].val.u32!.uint32, equals(200));
    });

    test('XdrSCVal SCV_ADDRESS with SC_ADDRESS_TYPE_ACCOUNT encode/decode', () {
      var accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = accountId;

      var original = XdrSCVal(XdrSCValType.SCV_ADDRESS);
      original.address = address;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_ADDRESS.value));
      expect(decoded.address, isNotNull);
      expect(decoded.address!.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT.value));
    });

    test('XdrSCVal SCV_ADDRESS with SC_ADDRESS_TYPE_CONTRACT encode/decode', () {
      var contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = contractId;

      var original = XdrSCVal(XdrSCValType.SCV_ADDRESS);
      original.address = address;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_ADDRESS.value));
      expect(decoded.address, isNotNull);
      expect(decoded.address!.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.address!.contractId!.hash, equals(contractId.hash));
    });

    test('XdrSCVal SCV_LEDGER_KEY_NONCE encode/decode', () {
      var nonceKey = XdrSCNonceKey(XdrInt64(BigInt.from(54321)));

      var original = XdrSCVal(XdrSCValType.SCV_LEDGER_KEY_NONCE);
      original.nonce_key = nonceKey;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_LEDGER_KEY_NONCE.value));
      expect(decoded.nonce_key, isNotNull);
      expect(decoded.nonce_key!.nonce.int64, equals(BigInt.from(54321)));
    });

    test('XdrSCVal SCV_CONTRACT_INSTANCE with WASM encode/decode', () {
      var wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = wasmHash;

      var instance = XdrSCContractInstance(executable, null);

      var original = XdrSCVal(XdrSCValType.SCV_CONTRACT_INSTANCE);
      original.instance = instance;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_CONTRACT_INSTANCE.value));
      expect(decoded.instance, isNotNull);
      expect(decoded.instance!.executable.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
      expect(decoded.instance!.executable.wasmHash!.hash, equals(wasmHash.hash));
    });

    test('XdrSCVal SCV_LEDGER_KEY_CONTRACT_INSTANCE encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE.value));
    });

    test('XdrSCErrorType enum all variants', () {
      final types = [
        XdrSCErrorType.SCE_CONTRACT,
        XdrSCErrorType.SCE_WASM_VM,
        XdrSCErrorType.SCE_CONTEXT,
        XdrSCErrorType.SCE_STORAGE,
        XdrSCErrorType.SCE_OBJECT,
        XdrSCErrorType.SCE_CRYPTO,
        XdrSCErrorType.SCE_EVENTS,
        XdrSCErrorType.SCE_BUDGET,
        XdrSCErrorType.SCE_VALUE,
        XdrSCErrorType.SCE_AUTH,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCErrorType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCErrorType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrSCError SCE_CONTRACT encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      original.contractCode = XdrUint32(999);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_CONTRACT.value));
      expect(decoded.contractCode, isNotNull);
      expect(decoded.contractCode!.uint32, equals(999));
    });

    test('XdrSCError SCE_WASM_VM encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_WASM_VM);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_WASM_VM.value));
    });

    test('XdrSCError SCE_AUTH encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_AUTH);
      original.code = XdrSCErrorCode.SCEC_INVALID_INPUT;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_AUTH.value));
      expect(decoded.code, isNotNull);
      expect(decoded.code!.value, equals(XdrSCErrorCode.SCEC_INVALID_INPUT.value));
    });

    test('XdrSCAddressType enum all variants', () {
      final types = [
        XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT,
        XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
        XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT,
        XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE,
        XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCAddressType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCAddressType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrContractExecutableType enum all variants', () {
      final types = [
        XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM,
        XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrContractExecutableType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrContractExecutableType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrContractExecutable CONTRACT_EXECUTABLE_WASM encode/decode', () {
      var wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var original = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      original.wasmHash = wasmHash;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractExecutable.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractExecutable.decode(input);

      expect(decoded.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
      expect(decoded.wasmHash, isNotNull);
      expect(decoded.wasmHash!.hash, equals(wasmHash.hash));
    });

    test('XdrContractExecutable CONTRACT_EXECUTABLE_STELLAR_ASSET encode/decode', () {
      var original = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractExecutable.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractExecutable.decode(input);

      expect(decoded.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value));
      expect(decoded.wasmHash, isNull);
    });

    test('XdrSorobanCredentialsType enum all variants', () {
      final types = [
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT,
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSorobanCredentialsType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSorobanCredentialsType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrSorobanCredentials SOROBAN_CREDENTIALS_SOURCE_ACCOUNT encode/decode', () {
      var original = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanCredentials.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanCredentials.decode(input);

      expect(decoded.type.value, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT.value));
      expect(decoded.address, isNull);
    });

    // NEW TESTS BELOW TO EXPAND COVERAGE

    test('XdrSCError SCE_CONTEXT encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_CONTEXT);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_CONTEXT.value));
    });

    test('XdrSCError SCE_STORAGE encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_STORAGE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_STORAGE.value));
    });

    test('XdrSCError SCE_OBJECT encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_OBJECT);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_OBJECT.value));
    });

    test('XdrSCError SCE_CRYPTO encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_CRYPTO);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_CRYPTO.value));
    });

    test('XdrSCError SCE_EVENTS encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_EVENTS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_EVENTS.value));
    });

    test('XdrSCError SCE_BUDGET encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_BUDGET);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_BUDGET.value));
    });

    test('XdrSCError SCE_VALUE encode/decode', () {
      var original = XdrSCError(XdrSCErrorType.SCE_VALUE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_VALUE.value));
    });

    test('XdrSCErrorCode enum all variants', () {
      final codes = [
        XdrSCErrorCode.SCEC_ARITH_DOMAIN,
        XdrSCErrorCode.SCEC_INDEX_BOUNDS,
        XdrSCErrorCode.SCEC_INVALID_INPUT,
        XdrSCErrorCode.SCEC_MISSING_VALUE,
        XdrSCErrorCode.SCEC_EXISTING_VALUE,
        XdrSCErrorCode.SCEC_EXCEEDED_LIMIT,
        XdrSCErrorCode.SCEC_INVALID_ACTION,
        XdrSCErrorCode.SCEC_INTERNAL_ERROR,
        XdrSCErrorCode.SCEC_UNEXPECTED_TYPE,
        XdrSCErrorCode.SCEC_UNEXPECTED_SIZE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCErrorCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCErrorCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrSCAddress SC_ADDRESS_TYPE_MUXED_ACCOUNT encode/decode', () {
      var muxedAccount = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.from(12345)),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE))),
      );
      var original = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT);
      original.muxedAccount = muxedAccount;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCAddress.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCAddress.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT.value));
      expect(decoded.muxedAccount, isNotNull);
      expect(decoded.muxedAccount!.id!.uint64, equals(BigInt.from(12345)));
    });

    test('XdrSCAddress SC_ADDRESS_TYPE_CLAIMABLE_BALANCE encode/decode', () {
      var balanceId = XdrClaimableBalanceID(XdrClaimableBalanceIDType.CLAIMABLE_BALANCE_ID_TYPE_V0);
      balanceId.v0 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var original = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE);
      original.claimableBalanceId = balanceId;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCAddress.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCAddress.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE.value));
      expect(decoded.claimableBalanceId, isNotNull);
    });

    test('XdrSCAddress SC_ADDRESS_TYPE_LIQUIDITY_POOL encode/decode', () {
      var poolId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var original = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL);
      original.liquidityPoolId = poolId;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCAddress.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCAddress.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL.value));
      expect(decoded.liquidityPoolId, isNotNull);
      expect(decoded.liquidityPoolId!.hash, equals(poolId.hash));
    });

    test('XdrSorobanCredentials SOROBAN_CREDENTIALS_ADDRESS encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var sig = XdrSCVal(XdrSCValType.SCV_VOID);
      var addressCreds = XdrSorobanAddressCredentials(
        address,
        XdrInt64(BigInt.from(999)),
        XdrUint32(100),
        sig,
      );

      var original = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      original.address = addressCreds;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanCredentials.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanCredentials.decode(input);

      expect(decoded.type.value, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS.value));
      expect(decoded.address, isNotNull);
      expect(decoded.address!.nonce.int64, equals(BigInt.from(999)));
    });

    test('XdrSCContractInstance with storage encode/decode', () {
      var wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = wasmHash;

      var storageKey = XdrSCVal(XdrSCValType.SCV_U32);
      storageKey.u32 = XdrUint32(1);
      var storageVal = XdrSCVal(XdrSCValType.SCV_U32);
      storageVal.u32 = XdrUint32(100);

      var storage = [XdrSCMapEntry(storageKey, storageVal)];

      var original = XdrSCContractInstance(executable, storage);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCContractInstance.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCContractInstance.decode(input);

      expect(decoded.executable.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
      expect(decoded.storage, isNotNull);
      expect(decoded.storage!.length, equals(1));
      expect(decoded.storage![0].key.u32!.uint32, equals(1));
      expect(decoded.storage![0].val.u32!.uint32, equals(100));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_VAL encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VAL);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_VAL.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_BOOL encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_BOOL.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_VOID encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VOID);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_VOID.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_U32 encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U32.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_I32 encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I32);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_I32.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_OPTION encode/decode', () {
      var innerType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      var option = XdrSCSpecTypeOption(innerType);

      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_OPTION);
      original.option = option;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_OPTION.value));
      expect(decoded.option, isNotNull);
      expect(decoded.option!.valueType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U32.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_RESULT encode/decode', () {
      var okType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      var errorType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ERROR);
      var result = XdrSCSpecTypeResult(okType, errorType);

      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_RESULT);
      original.result = result;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_RESULT.value));
      expect(decoded.result, isNotNull);
      expect(decoded.result!.okType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U32.value));
      expect(decoded.result!.errorType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_ERROR.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_VEC encode/decode', () {
      var elementType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U64);
      var vec = XdrSCSpecTypeVec(elementType);

      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VEC);
      original.vec = vec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_VEC.value));
      expect(decoded.vec, isNotNull);
      expect(decoded.vec!.elementType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U64.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_MAP encode/decode', () {
      var keyType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_SYMBOL);
      var valueType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I32);
      var map = XdrSCSpecTypeMap(keyType, valueType);

      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_MAP);
      original.map = map;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_MAP.value));
      expect(decoded.map, isNotNull);
      expect(decoded.map!.keyType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_SYMBOL.value));
      expect(decoded.map!.valueType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_I32.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_TUPLE encode/decode', () {
      var type1 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      var type2 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      var tuple = XdrSCSpecTypeTuple([type1, type2]);

      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_TUPLE);
      original.tuple = tuple;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_TUPLE.value));
      expect(decoded.tuple, isNotNull);
      expect(decoded.tuple!.valueTypes.length, equals(2));
      expect(decoded.tuple!.valueTypes[0].discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U32.value));
      expect(decoded.tuple!.valueTypes[1].discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_STRING.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_BYTES_N encode/decode', () {
      var bytesN = XdrSCSpecTypeBytesN(XdrUint32(32));

      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N);
      original.bytesN = bytesN;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_BYTES_N.value));
      expect(decoded.bytesN, isNotNull);
      expect(decoded.bytesN!.n.uint32, equals(32));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_UDT encode/decode', () {
      var udt = XdrSCSpecTypeUDT('MyCustomType');

      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_UDT);
      original.udt = udt;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_UDT.value));
      expect(decoded.udt, isNotNull);
      expect(decoded.udt!.name, equals('MyCustomType'));
    });

    test('XdrSCSpecEntry SC_SPEC_ENTRY_FUNCTION_V0 encode/decode', () {
      var input1 = XdrSCSpecFunctionInputV0('doc1', 'param1', XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32));
      var funcSpec = XdrSCSpecFunctionV0(
        'Function doc',
        'myFunction',
        [input1],
        [XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_VOID)],
      );

      var original = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0);
      original.functionV0 = funcSpec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0.value));
      expect(decoded.functionV0, isNotNull);
      expect(decoded.functionV0!.name, equals('myFunction'));
    });

    test('XdrSCSpecEntry SC_SPEC_ENTRY_UDT_STRUCT_V0 encode/decode', () {
      var field1 = XdrSCSpecUDTStructFieldV0(
        'Field doc',
        'field1',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
      );
      var structSpec = XdrSCSpecUDTStructV0('Struct doc', 'lib', 'MyStruct', [field1]);

      var original = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0);
      original.udtStructV0 = structSpec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_STRUCT_V0.value));
      expect(decoded.udtStructV0, isNotNull);
      expect(decoded.udtStructV0!.name, equals('MyStruct'));
    });

    test('XdrSCSpecEntry SC_SPEC_ENTRY_UDT_UNION_V0 encode/decode', () {
      var voidCase = XdrSCSpecUDTUnionCaseVoidV0('Case doc', 'VoidCase');
      var unionCase = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0);
      unionCase.voidCase = voidCase;

      var unionSpec = XdrSCSpecUDTUnionV0('Union doc', 'lib', 'MyUnion', [unionCase]);

      var original = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      original.udtUnionV0 = unionSpec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0.value));
      expect(decoded.udtUnionV0, isNotNull);
      expect(decoded.udtUnionV0!.name, equals('MyUnion'));
    });

    test('XdrSCSpecEntry SC_SPEC_ENTRY_UDT_ENUM_V0 encode/decode', () {
      var enumCase = XdrSCSpecUDTEnumCaseV0('Case doc', 'Case1', XdrUint32(0));
      var enumSpec = XdrSCSpecUDTEnumV0('Enum doc', 'lib', 'MyEnum', [enumCase]);

      var original = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0);
      original.udtEnumV0 = enumSpec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ENUM_V0.value));
      expect(decoded.udtEnumV0, isNotNull);
      expect(decoded.udtEnumV0!.name, equals('MyEnum'));
    });

    test('XdrSCSpecEntry SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0 encode/decode', () {
      var errorCase = XdrSCSpecUDTErrorEnumCaseV0('Error doc', 'Error1', XdrUint32(1));
      var errorEnumSpec = XdrSCSpecUDTErrorEnumV0('Error enum doc', 'lib', 'MyError', [errorCase]);

      var original = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0);
      original.udtErrorEnumV0 = errorEnumSpec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_ERROR_ENUM_V0.value));
      expect(decoded.udtErrorEnumV0, isNotNull);
      expect(decoded.udtErrorEnumV0!.name, equals('MyError'));
    });

    // XdrSCSpecEntry SC_SPEC_ENTRY_EVENT_V0 not available in this SDK version

    test('XdrContractIDPreimage CONTRACT_ID_PREIMAGE_FROM_ADDRESS encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var original = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      original.address = address;
      original.salt = salt;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractIDPreimage.decode(input);

      expect(decoded.type.value, equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS.value));
      expect(decoded.address, isNotNull);
      expect(decoded.salt, isNotNull);
    });

    test('XdrContractIDPreimage CONTRACT_ID_PREIMAGE_FROM_ASSET encode/decode', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
      original.fromAsset = asset;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractIDPreimage.decode(input);

      expect(decoded.type.value, equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET.value));
      expect(decoded.fromAsset, isNotNull);
      expect(decoded.fromAsset!.discriminant.value, equals(XdrAssetType.ASSET_TYPE_NATIVE.value));
    });

    test('XdrHostFunction HOST_FUNCTION_TYPE_INVOKE_CONTRACT encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_U32);
      arg1.u32 = XdrUint32(42);

      var invokeArgs = XdrInvokeContractArgs(address, 'transfer', [arg1]);

      var original = XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
      original.invokeContract = invokeArgs;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHostFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHostFunction.decode(input);

      expect(decoded.type.value, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT.value));
      expect(decoded.invokeContract, isNotNull);
      expect(decoded.invokeContract!.functionName, equals('transfer'));
    });

    test('XdrHostFunction HOST_FUNCTION_TYPE_CREATE_CONTRACT encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var preimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = address;
      preimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var createArgs = XdrCreateContractArgs(preimage, executable);

      var original = XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT);
      original.createContract = createArgs;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHostFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHostFunction.decode(input);

      expect(decoded.type.value, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT.value));
      expect(decoded.createContract, isNotNull);
    });

    test('XdrHostFunction HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM encode/decode', () {
      var wasmCode = Uint8List.fromList([0, 97, 115, 109, 1, 0, 0, 0]);

      var original = XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM);
      original.wasm = XdrDataValue(wasmCode);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHostFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHostFunction.decode(input);

      expect(decoded.type.value, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM.value));
      expect(decoded.wasm, isNotNull);
      expect(decoded.wasm!.dataValue, equals(wasmCode));
    });

    test('XdrHostFunction HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2 encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var preimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = address;
      preimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_U32);
      arg1.u32 = XdrUint32(100);

      var createArgsV2 = XdrCreateContractArgsV2(preimage, executable, [arg1]);

      var original = XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2);
      original.createContractV2 = createArgsV2;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHostFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHostFunction.decode(input);

      expect(decoded.type.value, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2.value));
      expect(decoded.createContractV2, isNotNull);
      expect(decoded.createContractV2!.constructorArgs.length, equals(1));
    });

    test('XdrSCSpecUDTUnionCaseV0 SC_SPEC_UDT_UNION_CASE_TUPLE_V0 encode/decode', () {
      var type1 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      var type2 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      var tupleCase = XdrSCSpecUDTUnionCaseTupleV0('Tuple case doc', 'TupleCase', [type1, type2]);

      var original = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0);
      original.tupleCase = tupleCase;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTUnionCaseV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTUnionCaseV0.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0.value));
      expect(decoded.tupleCase, isNotNull);
      expect(decoded.tupleCase!.name, equals('TupleCase'));
      expect(decoded.tupleCase!.type.length, equals(2));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_ADDRESS encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_ADDRESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_ADDRESS.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_STRING encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_STRING.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_SYMBOL encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_SYMBOL);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_SYMBOL.value));
    });

    test('XdrSCSpecTypeDef SC_SPEC_TYPE_BYTES encode/decode', () {
      var original = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeDef.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeDef.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_BYTES.value));
    });

    test('XdrSCSpecTypeDef all remaining simple types encode/decode', () {
      final simpleTypes = [
        XdrSCSpecType.SC_SPEC_TYPE_ERROR,
        XdrSCSpecType.SC_SPEC_TYPE_U64,
        XdrSCSpecType.SC_SPEC_TYPE_I64,
        XdrSCSpecType.SC_SPEC_TYPE_TIMEPOINT,
        XdrSCSpecType.SC_SPEC_TYPE_DURATION,
        XdrSCSpecType.SC_SPEC_TYPE_U128,
        XdrSCSpecType.SC_SPEC_TYPE_I128,
        XdrSCSpecType.SC_SPEC_TYPE_U256,
        XdrSCSpecType.SC_SPEC_TYPE_I256,
        XdrSCSpecType.SC_SPEC_TYPE_MUXED_ADDRESS,
      ];

      for (var type in simpleTypes) {
        var original = XdrSCSpecTypeDef(type);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCSpecTypeDef.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCSpecTypeDef.decode(input);

        expect(decoded.discriminant.value, equals(type.value));
      }
    });
  });
}
