// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Tests for XDR Contract Data/Auth types that go beyond simple roundtrip encode/decode.
  // Focuses on: nested structures, edge cases, complex multi-type construction.
  // Simple roundtrips are covered by auto-generated tests in test/unit/xdr/generated/.

  group('XdrSorobanAuthorizedInvocation nested subInvocations', () {
    test('XdrSorobanAuthorizedInvocation with nested subInvocations encode/decode', () {
      var address1 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address1.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var invokeArgs1 = XdrInvokeContractArgs(address1, 'main', [
        XdrSCVal(XdrSCValType.SCV_U32)..u32 = XdrUint32(1),
      ]);

      var authFunction1 = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      authFunction1.contractFn = invokeArgs1;

      var address2 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address2.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var invokeArgs2 = XdrInvokeContractArgs(address2, 'sub', [
        XdrSCVal(XdrSCValType.SCV_U32)..u32 = XdrUint32(2),
      ]);

      var authFunction2 = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      authFunction2.contractFn = invokeArgs2;

      var subInvocation = XdrSorobanAuthorizedInvocation(authFunction2, []);
      var original = XdrSorobanAuthorizedInvocation(authFunction1, [subInvocation]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedInvocation.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedInvocation.decode(input);

      expect(decoded.function.contractFn!.functionName, equals('main'));
      expect(decoded.subInvocations.length, equals(1));
      expect(decoded.subInvocations[0].function.contractFn!.functionName, equals('sub'));
    });
  });

  group('XdrSCContractInstance storage edge cases', () {
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

    test('XdrSCContractInstance with multiple storage entries', () {
      var wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));
      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = wasmHash;

      var key1 = XdrSCVal(XdrSCValType.SCV_SYMBOL)..sym = 'key1';
      var val1 = XdrSCVal(XdrSCValType.SCV_U32)..u32 = XdrUint32(100);

      var key2 = XdrSCVal(XdrSCValType.SCV_SYMBOL)..sym = 'key2';
      var val2 = XdrSCVal(XdrSCValType.SCV_STRING)..str = 'value2';

      var original = XdrSCContractInstance(executable, [
        XdrSCMapEntry(key1, val1),
        XdrSCMapEntry(key2, val2),
      ]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCContractInstance.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCContractInstance.decode(input);

      expect(decoded.storage!.length, equals(2));
      expect(decoded.storage![0].key.sym, equals('key1'));
      expect(decoded.storage![1].val.str, equals('value2'));
    });
  });

  group('XdrHostFunction large WASM upload', () {
    test('XdrHostFunction HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM with large WASM', () {
      var wasmCode = Uint8List.fromList(List<int>.generate(512, (i) => i % 256));

      var original = XdrHostFunction(
          XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM);
      original.wasm = XdrDataValue(wasmCode);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHostFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHostFunction.decode(input);

      expect(decoded.wasm!.dataValue, equals(wasmCode));
    });
  });

  group('XdrContractIDPreimage asset types', () {
    test('CONTRACT_ID_PREIMAGE_FROM_ASSET with AlphaNum4', () {
      var assetCodeBytes = Uint8List(4);
      var assetCodeStr = 'TEST';
      for (var i = 0; i < assetCodeStr.length; i++) {
        assetCodeBytes[i] = assetCodeStr.codeUnitAt(i);
      }

      var issuer = XdrAccountID.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4);
      asset.alphaNum4 = XdrAssetAlphaNum4(assetCodeBytes, issuer);

      var original = XdrContractIDPreimage(
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
      original.fromAsset = asset;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractIDPreimage.decode(input);

      expect(decoded.fromAsset!.discriminant.value,
          equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4.value));
    });

    test('CONTRACT_ID_PREIMAGE_FROM_ASSET with AlphaNum12', () {
      var assetCodeBytes = Uint8List(12);
      var assetCodeStr = 'LONGASSET123';
      for (var i = 0; i < assetCodeStr.length; i++) {
        assetCodeBytes[i] = assetCodeStr.codeUnitAt(i);
      }

      var issuer = XdrAccountID.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12);
      asset.alphaNum12 = XdrAssetAlphaNum12(assetCodeBytes, issuer);

      var original = XdrContractIDPreimage(
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET);
      original.fromAsset = asset;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractIDPreimage.decode(input);

      expect(decoded.fromAsset!.discriminant.value,
          equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12.value));
    });
  });
}
