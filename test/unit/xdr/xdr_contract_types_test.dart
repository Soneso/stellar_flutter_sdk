// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Contract Types - XdrSCValType', () {
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

    test('XdrSCValType encode/decode round-trip', () {
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
  });

  group('XDR Contract Types - XdrSCAddressType', () {
    test('XdrSCAddressType enum values', () {
      expect(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT.value, equals(0));
      expect(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value, equals(1));
    });

    test('XdrSCAddressType encode/decode round-trip', () {
      final types = [
        XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT,
        XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
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
  });

  group('XDR Contract Types - XdrSCAddress', () {
    test('XdrSCAddress SC_ADDRESS_TYPE_ACCOUNT encode/decode round-trip', () {
      var publicKey = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      publicKey.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x42))));
      var accountId = XdrAccountID(publicKey);

      var original = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      original.accountId = accountId;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCAddress.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCAddress.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.accountId!.accountID.getEd25519()!.uint256,
             equals(original.accountId!.accountID.getEd25519()!.uint256));
    });

    test('XdrSCAddress SC_ADDRESS_TYPE_CONTRACT encode/decode round-trip', () {
      var contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      var original = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      original.contractId = contractId;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCAddress.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCAddress.decode(input);

      expect(decoded.discriminant.value, equals(original.discriminant.value));
      expect(decoded.contractId!.hash, equals(original.contractId!.hash));
    });
  });

  group('XDR Contract Types - XdrSCMapEntry', () {
    test('XdrSCMapEntry encode/decode round-trip', () {
      var key = XdrSCVal.forString('key1');
      var val = XdrSCVal.forU32(42);

      var original = XdrSCMapEntry(key, val);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCMapEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCMapEntry.decode(input);

      expect(decoded.key.discriminant.value, equals(XdrSCValType.SCV_STRING.value));
      expect(decoded.key.str, equals('key1'));
      expect(decoded.val.discriminant.value, equals(XdrSCValType.SCV_U32.value));
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

  group('XDR Contract Types - XdrInt128Parts', () {
    test('XdrInt128Parts encode/decode round-trip', () {
      var original = XdrInt128Parts(
        XdrInt64(BigInt.from(123)),
        XdrUint64(BigInt.from(456))
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt128Parts.decode(input);

      expect(decoded.hi.int64, equals(original.hi.int64));
      expect(decoded.lo.uint64, equals(original.lo.uint64));
    });

    test('XdrInt128Parts forHiLo factory', () {
      var original = XdrInt128Parts.forHiLo(
        BigInt.from(-12345),
        BigInt.from(67890)
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt128Parts.decode(input);

      expect(decoded.hi.int64, equals(BigInt.from(-12345)));
      expect(decoded.lo.uint64, equals(BigInt.from(67890)));
    });
  });

  group('XDR Contract Types - XdrUInt128Parts', () {
    test('XdrUInt128Parts encode/decode round-trip', () {
      var original = XdrUInt128Parts(
        XdrUint64(BigInt.from(1000000)),
        XdrUint64(BigInt.from(2000000))
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt128Parts.decode(input);

      expect(decoded.hi.uint64, equals(original.hi.uint64));
      expect(decoded.lo.uint64, equals(original.lo.uint64));
    });

    test('XdrUInt128Parts with max values', () {
      var original = XdrUInt128Parts.forHiLo(
        BigInt.parse('18446744073709551615'),
        BigInt.parse('18446744073709551615')
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt128Parts.decode(input);

      expect(decoded.hi.uint64, equals(BigInt.parse('18446744073709551615')));
      expect(decoded.lo.uint64, equals(BigInt.parse('18446744073709551615')));
    });
  });

  group('XDR Contract Types - XdrInt256Parts', () {
    test('XdrInt256Parts encode/decode round-trip', () {
      var original = XdrInt256Parts(
        XdrInt64(BigInt.from(100)),
        XdrUint64(BigInt.from(200)),
        XdrUint64(BigInt.from(300)),
        XdrUint64(BigInt.from(400))
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt256Parts.decode(input);

      expect(decoded.hiHi.int64, equals(original.hiHi.int64));
      expect(decoded.hiLo.uint64, equals(original.hiLo.uint64));
      expect(decoded.loHi.uint64, equals(original.loHi.uint64));
      expect(decoded.loLo.uint64, equals(original.loLo.uint64));
    });

    test('XdrInt256Parts forHiHiHiLoLoHiLoLo factory', () {
      var original = XdrInt256Parts.forHiHiHiLoLoHiLoLo(
        BigInt.from(-999),
        BigInt.from(111),
        BigInt.from(222),
        BigInt.from(333)
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt256Parts.decode(input);

      expect(decoded.hiHi.int64, equals(BigInt.from(-999)));
      expect(decoded.hiLo.uint64, equals(BigInt.from(111)));
      expect(decoded.loHi.uint64, equals(BigInt.from(222)));
      expect(decoded.loLo.uint64, equals(BigInt.from(333)));
    });
  });

  group('XDR Contract Types - XdrUInt256Parts', () {
    test('XdrUInt256Parts encode/decode round-trip', () {
      var original = XdrUInt256Parts(
        XdrUint64(BigInt.from(1111)),
        XdrUint64(BigInt.from(2222)),
        XdrUint64(BigInt.from(3333)),
        XdrUint64(BigInt.from(4444))
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt256Parts.decode(input);

      expect(decoded.hiHi.uint64, equals(original.hiHi.uint64));
      expect(decoded.hiLo.uint64, equals(original.hiLo.uint64));
      expect(decoded.loHi.uint64, equals(original.loHi.uint64));
      expect(decoded.loLo.uint64, equals(original.loLo.uint64));
    });

    test('XdrUInt256Parts with large values', () {
      var original = XdrUInt256Parts.forHiHiHiLoLoHiLoLo(
        BigInt.parse('9999999999999999999'),
        BigInt.parse('8888888888888888888'),
        BigInt.parse('7777777777777777777'),
        BigInt.parse('6666666666666666666')
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt256Parts.decode(input);

      expect(decoded.hiHi.uint64, equals(BigInt.parse('9999999999999999999')));
      expect(decoded.hiLo.uint64, equals(BigInt.parse('8888888888888888888')));
      expect(decoded.loHi.uint64, equals(BigInt.parse('7777777777777777777')));
      expect(decoded.loLo.uint64, equals(BigInt.parse('6666666666666666666')));
    });
  });

  group('XDR Contract Types - XdrContractExecutableType', () {
    test('XdrContractExecutableType enum values', () {
      expect(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value, equals(0));
      expect(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value, equals(1));
    });

    test('XdrContractExecutableType encode/decode round-trip', () {
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
  });

  group('XDR Contract Types - XdrContractExecutable', () {
    test('XdrContractExecutable WASM encode/decode round-trip', () {
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

    test('XdrContractExecutable STELLAR_ASSET encode/decode round-trip', () {
      var original = XdrContractExecutable.forAsset();

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractExecutable.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractExecutable.decode(input);

      expect(decoded.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value));
      expect(decoded.wasmHash, isNull);
    });
  });

  group('XDR Contract Types - XdrContractIDPreimage', () {
    test('XdrContractIDPreimage FROM_ADDRESS encode/decode round-trip', () {
      var publicKey = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      publicKey.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11))));
      var accountId = XdrAccountID(publicKey);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = accountId;
      var salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var original = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      original.address = address;
      original.salt = salt;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractIDPreimage.decode(input);

      expect(decoded.type.value, equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS.value));
      expect(decoded.address!.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT.value));
      expect(decoded.salt!.uint256, equals(salt.uint256));
    });

    test('XdrContractIDPreimage FROM_ASSET encode/decode round-trip', () {
      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
      original.fromAsset = asset;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractIDPreimage.decode(input);

      expect(decoded.type.value, equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET.value));
      expect(decoded.fromAsset!.discriminant.value, equals(XdrAssetType.ASSET_TYPE_NATIVE.value));
    });
  });

  group('XDR Contract Types - XdrContractDataDurability', () {
    test('XdrContractDataDurability enum values', () {
      expect(XdrContractDataDurability.TEMPORARY.value, equals(0));
      expect(XdrContractDataDurability.PERSISTENT.value, equals(1));
    });

    test('XdrContractDataDurability encode/decode round-trip', () {
      final durabilities = [
        XdrContractDataDurability.TEMPORARY,
        XdrContractDataDurability.PERSISTENT,
      ];

      for (var durability in durabilities) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrContractDataDurability.encode(output, durability);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrContractDataDurability.decode(input);

        expect(decoded.value, equals(durability.value));
      }
    });
  });

  group('XDR Contract Types - XdrSCNonceKey', () {
    test('XdrSCNonceKey encode/decode round-trip', () {
      var original = XdrSCNonceKey(XdrInt64(BigInt.from(12345)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCNonceKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCNonceKey.decode(input);

      expect(decoded.nonce.int64, equals(original.nonce.int64));
    });

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

  group('XDR Contract Types - XdrSCVal Basic Types', () {
    test('XdrSCVal SCV_BOOL true encode/decode round-trip', () {
      var original = XdrSCVal.forBool(true);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_BOOL.value));
      expect(decoded.b, equals(true));
    });

    test('XdrSCVal SCV_BOOL false encode/decode round-trip', () {
      var original = XdrSCVal.forBool(false);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_BOOL.value));
      expect(decoded.b, equals(false));
    });

    test('XdrSCVal SCV_VOID encode/decode round-trip', () {
      var original = XdrSCVal.forVoid();

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_VOID.value));
    });

    test('XdrSCVal SCV_U32 encode/decode round-trip', () {
      var original = XdrSCVal.forU32(42);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U32.value));
      expect(decoded.u32!.uint32, equals(42));
    });

    test('XdrSCVal SCV_I32 encode/decode round-trip', () {
      var original = XdrSCVal.forI32(-12345);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I32.value));
      expect(decoded.i32!.int32, equals(-12345));
    });

    test('XdrSCVal SCV_U64 encode/decode round-trip', () {
      var original = XdrSCVal.forU64(BigInt.from(9876543210));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U64.value));
      expect(decoded.u64!.uint64, equals(BigInt.from(9876543210)));
    });

    test('XdrSCVal SCV_I64 encode/decode round-trip', () {
      var original = XdrSCVal.forI64(BigInt.from(-9876543210));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I64.value));
      expect(decoded.i64!.int64, equals(BigInt.from(-9876543210)));
    });

    test('XdrSCVal SCV_TIMEPOINT encode/decode round-trip', () {
      var original = XdrSCVal.forTimepoint(BigInt.from(1640000000));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_TIMEPOINT.value));
      expect(decoded.timepoint!.uint64, equals(BigInt.from(1640000000)));
    });

    test('XdrSCVal SCV_DURATION encode/decode round-trip', () {
      var original = XdrSCVal.forDuration(BigInt.from(3600));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_DURATION.value));
      expect(decoded.duration!.uint64, equals(BigInt.from(3600)));
    });
  });

  group('XDR Contract Types - XdrSCVal 128-bit and 256-bit', () {
    test('XdrSCVal SCV_U128 encode/decode round-trip', () {
      var original = XdrSCVal.forU128Parts(
        BigInt.from(123456789),
        BigInt.from(987654321)
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U128.value));
      expect(decoded.u128!.hi.uint64, equals(BigInt.from(123456789)));
      expect(decoded.u128!.lo.uint64, equals(BigInt.from(987654321)));
    });

    test('XdrSCVal SCV_I128 encode/decode round-trip', () {
      var original = XdrSCVal.forI128Parts(
        BigInt.from(-123456789),
        BigInt.from(987654321)
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I128.value));
      expect(decoded.i128!.hi.int64, equals(BigInt.from(-123456789)));
      expect(decoded.i128!.lo.uint64, equals(BigInt.from(987654321)));
    });

    test('XdrSCVal SCV_U256 encode/decode round-trip', () {
      var original = XdrSCVal.forU256Parts(
        BigInt.from(111),
        BigInt.from(222),
        BigInt.from(333),
        BigInt.from(444)
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_U256.value));
      expect(decoded.u256!.hiHi.uint64, equals(BigInt.from(111)));
      expect(decoded.u256!.hiLo.uint64, equals(BigInt.from(222)));
      expect(decoded.u256!.loHi.uint64, equals(BigInt.from(333)));
      expect(decoded.u256!.loLo.uint64, equals(BigInt.from(444)));
    });

    test('XdrSCVal SCV_I256 encode/decode round-trip', () {
      var original = XdrSCVal.forI256Parts(
        BigInt.from(-111),
        BigInt.from(222),
        BigInt.from(333),
        BigInt.from(444)
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_I256.value));
      expect(decoded.i256!.hiHi.int64, equals(BigInt.from(-111)));
      expect(decoded.i256!.hiLo.uint64, equals(BigInt.from(222)));
      expect(decoded.i256!.loHi.uint64, equals(BigInt.from(333)));
      expect(decoded.i256!.loLo.uint64, equals(BigInt.from(444)));
    });
  });

  group('XDR Contract Types - XdrSCVal String Types', () {
    test('XdrSCVal SCV_BYTES encode/decode round-trip', () {
      var bytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05]);
      var original = XdrSCVal.forBytes(bytes);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_BYTES.value));
      expect(decoded.bytes!.dataValue, equals(bytes));
    });

    test('XdrSCVal SCV_STRING encode/decode round-trip', () {
      var original = XdrSCVal.forString('Hello Stellar');

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_STRING.value));
      expect(decoded.str, equals('Hello Stellar'));
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

    test('XdrSCVal SCV_SYMBOL encode/decode round-trip', () {
      var original = XdrSCVal.forSymbol('my_symbol');

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_SYMBOL.value));
      expect(decoded.sym, equals('my_symbol'));
    });
  });

  group('XDR Contract Types - XdrSCVal Complex Types', () {
    test('XdrSCVal SCV_VEC encode/decode round-trip', () {
      var vec = [
        XdrSCVal.forU32(1),
        XdrSCVal.forU32(2),
        XdrSCVal.forU32(3),
      ];
      var original = XdrSCVal.forVec(vec);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_VEC.value));
      expect(decoded.vec!.length, equals(3));
      expect(decoded.vec![0].u32!.uint32, equals(1));
      expect(decoded.vec![1].u32!.uint32, equals(2));
      expect(decoded.vec![2].u32!.uint32, equals(3));
    });

    test('XdrSCVal SCV_VEC with mixed types', () {
      var vec = [
        XdrSCVal.forU32(42),
        XdrSCVal.forString('test'),
        XdrSCVal.forBool(true),
      ];
      var original = XdrSCVal.forVec(vec);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.vec!.length, equals(3));
      expect(decoded.vec![0].u32!.uint32, equals(42));
      expect(decoded.vec![1].str, equals('test'));
      expect(decoded.vec![2].b, equals(true));
    });

    test('XdrSCVal SCV_MAP encode/decode round-trip', () {
      var map = [
        XdrSCMapEntry(XdrSCVal.forString('key1'), XdrSCVal.forU32(100)),
        XdrSCMapEntry(XdrSCVal.forString('key2'), XdrSCVal.forU32(200)),
      ];
      var original = XdrSCVal.forMap(map);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_MAP.value));
      expect(decoded.map!.length, equals(2));
      expect(decoded.map![0].key.str, equals('key1'));
      expect(decoded.map![0].val.u32!.uint32, equals(100));
      expect(decoded.map![1].key.str, equals('key2'));
      expect(decoded.map![1].val.u32!.uint32, equals(200));
    });

    test('XdrSCVal SCV_ADDRESS encode/decode round-trip', () {
      var publicKey = XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519);
      publicKey.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x99))));
      var accountId = XdrAccountID(publicKey);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = accountId;

      var original = XdrSCVal.forAddress(address);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_ADDRESS.value));
      expect(decoded.address!.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT.value));
    });
  });

  group('XDR Contract Types - XdrSCError', () {
    test('XdrSCError CONTRACT type encode/decode round-trip', () {
      var original = XdrSCError(XdrSCErrorType.SCE_CONTRACT);
      original.contractCode = XdrUint32(123);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_CONTRACT.value));
      expect(decoded.contractCode!.uint32, equals(123));
    });

    test('XdrSCError AUTH type encode/decode round-trip', () {
      var original = XdrSCError(XdrSCErrorType.SCE_AUTH);
      original.code = XdrSCErrorCode.SCEC_INVALID_INPUT;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_AUTH.value));
      expect(decoded.code!.value, equals(XdrSCErrorCode.SCEC_INVALID_INPUT.value));
    });

    test('XdrSCError WASM_VM type encode/decode round-trip', () {
      var original = XdrSCError(XdrSCErrorType.SCE_WASM_VM);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCError.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCError.decode(input);

      expect(decoded.type.value, equals(XdrSCErrorType.SCE_WASM_VM.value));
      expect(decoded.contractCode, isNull);
      expect(decoded.code, isNull);
    });
  });

  group('XDR Contract Types - XdrSCErrorType and XdrSCErrorCode', () {
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

      expect(decoded.executable.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
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

      expect(decoded.executable.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value));
      expect(decoded.storage!.length, equals(2));
      expect(decoded.storage![0].key.str, equals('key1'));
      expect(decoded.storage![0].val.u32!.uint32, equals(100));
    });
  });

  group('XDR Contract Types - Complex Scenarios', () {
    test('Nested XdrSCVal vectors', () {
      var innerVec1 = XdrSCVal.forVec([
        XdrSCVal.forU32(1),
        XdrSCVal.forU32(2),
      ]);
      var innerVec2 = XdrSCVal.forVec([
        XdrSCVal.forU32(3),
        XdrSCVal.forU32(4),
      ]);
      var outerVec = XdrSCVal.forVec([innerVec1, innerVec2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, outerVec);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.vec!.length, equals(2));
      expect(decoded.vec![0].vec!.length, equals(2));
      expect(decoded.vec![0].vec![0].u32!.uint32, equals(1));
      expect(decoded.vec![0].vec![1].u32!.uint32, equals(2));
      expect(decoded.vec![1].vec![0].u32!.uint32, equals(3));
      expect(decoded.vec![1].vec![1].u32!.uint32, equals(4));
    });

    test('XdrSCVal map with complex values', () {
      var map = [
        XdrSCMapEntry(
          XdrSCVal.forSymbol('balance'),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(1000000))
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('decimals'),
          XdrSCVal.forU32(7)
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('name'),
          XdrSCVal.forString('Test Token')
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
      expect(decoded.map![1].key.sym, equals('decimals'));
      expect(decoded.map![1].val.u32!.uint32, equals(7));
      expect(decoded.map![2].key.sym, equals('name'));
      expect(decoded.map![2].val.str, equals('Test Token'));
    });

    test('Large XdrUInt128Parts values', () {
      var original = XdrUInt128Parts.forHiLo(
        BigInt.parse('9223372036854775807'),
        BigInt.parse('18446744073709551615')
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt128Parts.decode(input);

      expect(decoded.hi.uint64, equals(BigInt.parse('9223372036854775807')));
      expect(decoded.lo.uint64, equals(BigInt.parse('18446744073709551615')));
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
      expect(decoded.vec![0].u32!.uint32, equals(1));
      expect(decoded.vec![1].error!.type.value, equals(XdrSCErrorType.SCE_CONTRACT.value));
      expect(decoded.vec![1].error!.contractCode!.uint32, equals(999));
      expect(decoded.vec![2].str, equals('after error'));
    });
  });
}
