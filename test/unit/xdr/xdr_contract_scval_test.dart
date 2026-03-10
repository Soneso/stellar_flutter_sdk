// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Tests for XDR Contract/SCVal types that go beyond simple roundtrip encode/decode.
  // Simple roundtrips are covered by auto-generated tests in test/unit/xdr/generated/.

  group('XdrSCVal negative value edge cases', () {
    test('XdrSCVal SCV_I32 negative encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_I32);
      original.i32 = XdrInt32(-54321);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.i32!.int32, equals(-54321));
    });

    test('XdrSCVal SCV_I64 negative encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_I64);
      original.i64 = XdrInt64(BigInt.from(-9876543210987));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.i64!.int64, equals(BigInt.from(-9876543210987)));
    });

    test('XdrSCVal SCV_I128 negative hi encode/decode', () {
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

      expect(decoded.i128!.hi.int64, equals(BigInt.from(-50)));
      expect(decoded.i128!.lo.uint64, equals(BigInt.from(150)));
    });

    test('XdrSCVal SCV_I256 negative hiHi encode/decode', () {
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

      expect(decoded.i256!.hiHi.int64, equals(BigInt.from(-500)));
    });
  });

  group('XdrSCVal empty container edge cases', () {
    test('XdrSCVal SCV_VEC with empty vector encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_VEC);
      original.vec = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.vec, isNotNull);
      expect(decoded.vec!, isEmpty);
    });

    test('XdrSCVal SCV_MAP with empty map encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_MAP);
      original.map = [];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.map, isNotNull);
      expect(decoded.map!, isEmpty);
    });

    test('XdrSCVal empty BYTES encode/decode', () {
      var bytes = Uint8List.fromList([]);

      var original = XdrSCVal(XdrSCValType.SCV_BYTES);
      original.bytes = XdrSCBytes(bytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.bytes!.sCBytes, equals(bytes));
    });

    test('XdrSCVal empty STRING encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_STRING);
      original.str = '';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.str, equals(''));
    });

    test('XdrSCVal empty SYMBOL encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_SYMBOL);
      original.sym = '';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.sym, equals(''));
    });
  });

  group('XdrSCVal nested structures', () {
    test('XdrSCVal SCV_VEC with multiple elements encode/decode', () {
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

      expect(decoded.vec!.length, equals(2));
      expect(decoded.vec![0].u32!.uint32, equals(10));
      expect(decoded.vec![1].u32!.uint32, equals(20));
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

      expect(decoded.map!.length, equals(2));
      expect(decoded.map![0].key.u32!.uint32, equals(1));
      expect(decoded.map![0].val.u32!.uint32, equals(100));
    });

    test('XdrSCVal nested VEC and MAP encode/decode', () {
      var innerKey = XdrSCVal(XdrSCValType.SCV_STRING);
      innerKey.str = 'key1';

      var innerVal = XdrSCVal(XdrSCValType.SCV_U64);
      innerVal.u64 = XdrUint64(BigInt.from(999));

      var mapEntry = XdrSCMapEntry(innerKey, innerVal);

      var mapVal = XdrSCVal(XdrSCValType.SCV_MAP);
      mapVal.map = [mapEntry];

      var vecVal = XdrSCVal(XdrSCValType.SCV_VEC);
      vecVal.vec = [mapVal];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, vecVal);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.vec!.length, equals(1));
      expect(decoded.vec![0].map!.length, equals(1));
      expect(decoded.vec![0].map![0].key.str, equals('key1'));
      expect(decoded.vec![0].map![0].val.u64!.uint64, equals(BigInt.from(999)));
    });

    test('XdrSCVal deeply nested structures encode/decode', () {
      var level3 = XdrSCVal(XdrSCValType.SCV_U32);
      level3.u32 = XdrUint32(42);

      var level2 = XdrSCVal(XdrSCValType.SCV_VEC);
      level2.vec = [level3];

      var level1 = XdrSCVal(XdrSCValType.SCV_VEC);
      level1.vec = [level2];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, level1);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.vec![0].vec![0].u32!.uint32, equals(42));
    });
  });

  group('XdrSCVal large data', () {
    test('XdrSCVal large BYTES encode/decode', () {
      var bytes = Uint8List.fromList(List<int>.generate(256, (i) => i % 256));

      var original = XdrSCVal(XdrSCValType.SCV_BYTES);
      original.bytes = XdrSCBytes(bytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.bytes!.sCBytes, equals(bytes));
    });
  });

  group('XdrSCContractInstance optional storage', () {
    test('XdrSCContractInstance with null storage', () {
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

      expect(decoded.instance!.storage, isNull);
      expect(decoded.instance!.executable.wasmHash!.hash, equals(wasmHash.hash));
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

      expect(decoded.storage, isNotNull);
      expect(decoded.storage!.length, equals(1));
      expect(decoded.storage![0].key.u32!.uint32, equals(1));
      expect(decoded.storage![0].val.u32!.uint32, equals(100));
    });

    test('XdrSCContractInstance with empty storage', () {
      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);

      var original = XdrSCContractInstance(executable, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCContractInstance.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCContractInstance.decode(input);

      expect(decoded.storage!, isEmpty);
    });
  });

  group('XdrSorobanCredentials branches', () {
    test('XdrSorobanCredentials SOROBAN_CREDENTIALS_SOURCE_ACCOUNT has null address', () {
      var original = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanCredentials.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanCredentials.decode(input);

      expect(decoded.type.value, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT.value));
      expect(decoded.address, isNull);
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
  });
}
