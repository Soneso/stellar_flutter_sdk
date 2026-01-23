// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Contract Types - Deep Branch Testing Part 3', () {
    test('XdrContractDataDurability TEMPORARY encode/decode', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractDataDurability.encode(
          output, XdrContractDataDurability.TEMPORARY);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractDataDurability.decode(input);

      expect(decoded.value,
          equals(XdrContractDataDurability.TEMPORARY.value));
    });

    test('XdrContractDataDurability PERSISTENT encode/decode', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractDataDurability.encode(
          output, XdrContractDataDurability.PERSISTENT);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractDataDurability.decode(input);

      expect(decoded.value,
          equals(XdrContractDataDurability.PERSISTENT.value));
    });

    test('XdrLedgerKeyContractData with TEMPORARY durability encode/decode',
        () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var key = XdrSCVal(XdrSCValType.SCV_STRING);
      key.str = 'temp_key';

      var original = XdrLedgerKeyContractData(
        address,
        key,
        XdrContractDataDurability.TEMPORARY,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyContractData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyContractData.decode(input);

      expect(decoded.contract.discriminant.value,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.key.str, equals('temp_key'));
      expect(decoded.durability.value,
          equals(XdrContractDataDurability.TEMPORARY.value));
    });

    test('XdrLedgerKeyContractData with PERSISTENT durability encode/decode',
        () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var key = XdrSCVal(XdrSCValType.SCV_SYMBOL);
      key.sym = 'persist';

      var original = XdrLedgerKeyContractData(
        address,
        key,
        XdrContractDataDurability.PERSISTENT,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyContractData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyContractData.decode(input);

      expect(decoded.contract.discriminant.value,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT.value));
      expect(decoded.key.sym, equals('persist'));
      expect(decoded.durability.value,
          equals(XdrContractDataDurability.PERSISTENT.value));
    });

    test('XdrLedgerKeyContractCode encode/decode', () {
      var wasmHash =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var original = XdrLedgerKeyContractCode(wasmHash);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerKeyContractCode.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerKeyContractCode.decode(input);

      expect(decoded.hash.hash, equals(wasmHash.hash));
    });

    test('XdrContractDataEntry with TEMPORARY durability encode/decode',
        () {
      var ext = XdrExtensionPoint(0);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var key = XdrSCVal(XdrSCValType.SCV_U32);
      key.u32 = XdrUint32(42);

      var val = XdrSCVal(XdrSCValType.SCV_STRING);
      val.str = 'test_value';

      var original = XdrContractDataEntry(
        ext,
        address,
        key,
        XdrContractDataDurability.TEMPORARY,
        val,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractDataEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractDataEntry.decode(input);

      expect(decoded.contract.discriminant.value,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.key.u32!.uint32, equals(42));
      expect(decoded.durability.value,
          equals(XdrContractDataDurability.TEMPORARY.value));
      expect(decoded.val.str, equals('test_value'));
    });

    test('XdrContractDataEntry with PERSISTENT durability encode/decode',
        () {
      var ext = XdrExtensionPoint(0);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var key = XdrSCVal(XdrSCValType.SCV_SYMBOL);
      key.sym = 'storage_key';

      var val = XdrSCVal(XdrSCValType.SCV_I64);
      val.i64 = XdrInt64(BigInt.from(999));

      var original = XdrContractDataEntry(
        ext,
        address,
        key,
        XdrContractDataDurability.PERSISTENT,
        val,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractDataEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractDataEntry.decode(input);

      expect(decoded.contract.discriminant.value,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.key.sym, equals('storage_key'));
      expect(decoded.durability.value,
          equals(XdrContractDataDurability.PERSISTENT.value));
      expect(decoded.val.i64!.int64, equals(BigInt.from(999)));
    });

    test('XdrContractCodeEntry encode/decode', () {
      var ext = XdrContractCodeEntryExt(0);
      var wasmHash =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));
      var wasmCode = Uint8List.fromList([0, 97, 115, 109, 1, 0, 0, 0]);

      var original = XdrContractCodeEntry(
        ext,
        wasmHash,
        XdrDataValue(wasmCode),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractCodeEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractCodeEntry.decode(input);

      expect(decoded.cHash.hash, equals(wasmHash.hash));
      expect(decoded.code.dataValue, equals(wasmCode));
    });

    test('XdrSorobanAuthorizedFunctionType enum variants encode/decode', () {
      final types = [
        XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
        XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSorobanAuthorizedFunctionType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSorobanAuthorizedFunctionType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test(
        'XdrSorobanAuthorizedFunction SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN encode/decode',
        () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_U32);
      arg1.u32 = XdrUint32(100);

      var invokeArgs = XdrInvokeContractArgs(address, 'authorize', [arg1]);

      var original = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      original.contractFn = invokeArgs;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedFunction.decode(input);

      expect(
          decoded.type.value,
          equals(XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN.value));
      expect(decoded.contractFn, isNotNull);
      expect(decoded.contractFn!.functionName, equals('authorize'));
    });

    test(
        'XdrSorobanAuthorizedFunction SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN encode/decode',
        () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var preimage = XdrContractIDPreimage(
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = address;
      preimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var createArgs = XdrCreateContractArgs(preimage, executable);

      var original = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN);
      original.createContractHostFn = createArgs;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedFunction.decode(input);

      expect(
          decoded.type.value,
          equals(XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN
              .value));
      expect(decoded.createContractHostFn, isNotNull);
    });

    test('XdrSorobanAuthorizedInvocation encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_BOOL);
      arg1.b = true;

      var invokeArgs = XdrInvokeContractArgs(address, 'invoke', [arg1]);

      var authFunction = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      authFunction.contractFn = invokeArgs;

      var original = XdrSorobanAuthorizedInvocation(authFunction, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedInvocation.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedInvocation.decode(input);

      expect(
          decoded.function.type.value,
          equals(XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN.value));
      expect(decoded.function.contractFn!.functionName, equals('invoke'));
      expect(decoded.subInvocations, isEmpty);
    });

    test('XdrSorobanAuthorizedInvocation with nested subInvocations encode/decode',
        () {
      var address1 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address1.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_U32);
      arg1.u32 = XdrUint32(1);

      var invokeArgs1 = XdrInvokeContractArgs(address1, 'main', [arg1]);

      var authFunction1 = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      authFunction1.contractFn = invokeArgs1;

      var address2 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address2.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var arg2 = XdrSCVal(XdrSCValType.SCV_U32);
      arg2.u32 = XdrUint32(2);

      var invokeArgs2 = XdrInvokeContractArgs(address2, 'sub', [arg2]);

      var authFunction2 = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
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
      expect(decoded.subInvocations[0].function.contractFn!.functionName,
          equals('sub'));
    });

    test('XdrSorobanAddressCredentials encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var signature = XdrSCVal(XdrSCValType.SCV_BYTES);
      signature.bytes = XdrDataValue(Uint8List.fromList([1, 2, 3, 4]));

      var original = XdrSorobanAddressCredentials(
        address,
        XdrInt64(BigInt.from(12345)),
        XdrUint32(600),
        signature,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAddressCredentials.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAddressCredentials.decode(input);

      expect(decoded.address.discriminant.value,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.nonce.int64, equals(BigInt.from(12345)));
      expect(decoded.signatureExpirationLedger.uint32, equals(600));
      expect(decoded.signature.bytes!.dataValue, equals(Uint8List.fromList([1, 2, 3, 4])));
    });

    test('XdrInvokeHostFunctionOp with auth encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_STRING);
      arg1.str = 'param';

      var invokeArgs = XdrInvokeContractArgs(address, 'call', [arg1]);

      var hostFunction = XdrHostFunction(
          XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
      hostFunction.invokeContract = invokeArgs;

      var authAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      authAddress.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var authSig = XdrSCVal(XdrSCValType.SCV_VOID);

      var addressCreds = XdrSorobanAddressCredentials(
        authAddress,
        XdrInt64(BigInt.from(100)),
        XdrUint32(500),
        authSig,
      );

      var creds = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      creds.address = addressCreds;

      var authInvokeArgs = XdrInvokeContractArgs(address, 'auth_call', []);

      var authFunc = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      authFunc.contractFn = authInvokeArgs;

      var authInvocation = XdrSorobanAuthorizedInvocation(authFunc, []);

      var auth = XdrSorobanAuthorizationEntry(creds, authInvocation);

      var original = XdrInvokeHostFunctionOp(hostFunction, [auth]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionOp.decode(input);

      expect(decoded.function.type.value,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT.value));
      expect(decoded.auth.length, equals(1));
      expect(
          decoded.auth[0].credentials.type.value,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS.value));
    });

    test('XdrSorobanAuthorizationEntry encode/decode', () {
      var creds = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);

      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var invokeArgs = XdrInvokeContractArgs(address, 'test', []);

      var authFunc = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      authFunc.contractFn = invokeArgs;

      var rootInvocation = XdrSorobanAuthorizedInvocation(authFunc, []);

      var original = XdrSorobanAuthorizationEntry(creds, rootInvocation);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizationEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizationEntry.decode(input);

      expect(
          decoded.credentials.type.value,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT
              .value));
      expect(decoded.rootInvocation.function.contractFn!.functionName,
          equals('test'));
    });

    test('XdrSCVal with nested VEC and MAP encode/decode', () {
      var innerKey = XdrSCVal(XdrSCValType.SCV_STRING);
      innerKey.str = 'key1';

      var innerVal = XdrSCVal(XdrSCValType.SCV_U64);
      innerVal.u64 = XdrUint64(BigInt.from(999));

      var mapEntry = XdrSCMapEntry(innerKey, innerVal);

      var mapVal = XdrSCVal(XdrSCValType.SCV_MAP);
      mapVal.map = [mapEntry];

      var vecVal = XdrSCVal(XdrSCValType.SCV_VEC);
      vecVal.vec = [mapVal];

      var original = vecVal;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_VEC.value));
      expect(decoded.vec!.length, equals(1));
      expect(decoded.vec![0].discriminant.value,
          equals(XdrSCValType.SCV_MAP.value));
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

      var original = level1;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_VEC.value));
      expect(decoded.vec!.length, equals(1));
      expect(decoded.vec![0].discriminant.value,
          equals(XdrSCValType.SCV_VEC.value));
      expect(decoded.vec![0].vec!.length, equals(1));
      expect(decoded.vec![0].vec![0].u32!.uint32, equals(42));
    });

    test('XdrSCVal empty BYTES encode/decode', () {
      var bytes = Uint8List.fromList([]);

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

    test('XdrSCVal empty STRING encode/decode', () {
      var original = XdrSCVal(XdrSCValType.SCV_STRING);
      original.str = '';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCVal.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCVal.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_STRING.value));
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

      expect(decoded.discriminant.value, equals(XdrSCValType.SCV_SYMBOL.value));
      expect(decoded.sym, equals(''));
    });

    test('XdrSCVal large BYTES encode/decode', () {
      var bytes = Uint8List.fromList(List<int>.generate(256, (i) => i % 256));

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

    test('XdrSCContractInstance with empty storage encode/decode', () {
      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);

      var original = XdrSCContractInstance(executable, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCContractInstance.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCContractInstance.decode(input);

      expect(
          decoded.executable.type.value,
          equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET
              .value));
      expect(decoded.storage, isEmpty);
    });

    test('XdrSCContractInstance with multiple storage entries encode/decode',
        () {
      var wasmHash =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));
      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = wasmHash;

      var key1 = XdrSCVal(XdrSCValType.SCV_SYMBOL);
      key1.sym = 'key1';
      var val1 = XdrSCVal(XdrSCValType.SCV_U32);
      val1.u32 = XdrUint32(100);

      var key2 = XdrSCVal(XdrSCValType.SCV_SYMBOL);
      key2.sym = 'key2';
      var val2 = XdrSCVal(XdrSCValType.SCV_STRING);
      val2.str = 'value2';

      var storage = [
        XdrSCMapEntry(key1, val1),
        XdrSCMapEntry(key2, val2),
      ];

      var original = XdrSCContractInstance(executable, storage);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCContractInstance.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCContractInstance.decode(input);

      expect(decoded.executable.type.value,
          equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
      expect(decoded.storage!.length, equals(2));
      expect(decoded.storage![0].key.sym, equals('key1'));
      expect(decoded.storage![0].val.u32!.uint32, equals(100));
      expect(decoded.storage![1].key.sym, equals('key2'));
      expect(decoded.storage![1].val.str, equals('value2'));
    });

    test('XdrHostFunction HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM with large WASM encode/decode',
        () {
      var wasmCode = Uint8List.fromList(
          List<int>.generate(512, (i) => i % 256));

      var original = XdrHostFunction(
          XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM);
      original.wasm = XdrDataValue(wasmCode);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHostFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHostFunction.decode(input);

      expect(
          decoded.type.value,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM
              .value));
      expect(decoded.wasm!.dataValue, equals(wasmCode));
    });

    test('XdrCreateContractArgs with STELLAR_ASSET executable encode/decode',
        () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');

      var preimage = XdrContractIDPreimage(
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = address;
      preimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x00)));

      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);

      var original = XdrCreateContractArgs(preimage, executable);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateContractArgs.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateContractArgs.decode(input);

      expect(
          decoded.contractIDPreimage.type.value,
          equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS
              .value));
      expect(
          decoded.executable.type.value,
          equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET
              .value));
    });

    test('XdrContractIDPreimage CONTRACT_ID_PREIMAGE_FROM_ASSET with AlphaNum4 encode/decode',
        () {
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

      expect(decoded.type.value,
          equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET.value));
      expect(decoded.fromAsset!.discriminant.value,
          equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4.value));
    });

    test('XdrContractIDPreimage CONTRACT_ID_PREIMAGE_FROM_ASSET with AlphaNum12 encode/decode',
        () {
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

      expect(decoded.type.value,
          equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET.value));
      expect(decoded.fromAsset!.discriminant.value,
          equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM12.value));
    });

    test('XdrInvokeContractArgs with empty args encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var original = XdrInvokeContractArgs(address, 'noArgsFunc', []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeContractArgs.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeContractArgs.decode(input);

      expect(decoded.contractAddress.discriminant.value,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.functionName, equals('noArgsFunc'));
      expect(decoded.args, isEmpty);
    });

    test('XdrInvokeContractArgs with multiple args encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_U32);
      arg1.u32 = XdrUint32(1);

      var arg2 = XdrSCVal(XdrSCValType.SCV_STRING);
      arg2.str = 'test';

      var arg3 = XdrSCVal(XdrSCValType.SCV_BOOL);
      arg3.b = true;

      var arg4 = XdrSCVal(XdrSCValType.SCV_I64);
      arg4.i64 = XdrInt64(BigInt.from(-999));

      var original =
          XdrInvokeContractArgs(address, 'multiArg', [arg1, arg2, arg3, arg4]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeContractArgs.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeContractArgs.decode(input);

      expect(decoded.contractAddress.discriminant.value,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.functionName, equals('multiArg'));
      expect(decoded.args.length, equals(4));
      expect(decoded.args[0].u32!.uint32, equals(1));
      expect(decoded.args[1].str, equals('test'));
      expect(decoded.args[2].b, equals(true));
      expect(decoded.args[3].i64!.int64, equals(BigInt.from(-999)));
    });

    test('XdrCreateContractArgsV2 with empty constructor args encode/decode',
        () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var preimage = XdrContractIDPreimage(
          XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = address;
      preimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var executable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var original = XdrCreateContractArgsV2(preimage, executable, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateContractArgsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateContractArgsV2.decode(input);

      expect(
          decoded.contractIDPreimage.type.value,
          equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS
              .value));
      expect(decoded.executable.type.value,
          equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
      expect(decoded.constructorArgs, isEmpty);
    });

    test('XdrLedgerFootprint with both readOnly and readWrite encode/decode',
        () {
      var address1 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address1.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var key1 = XdrSCVal(XdrSCValType.SCV_U32);
      key1.u32 = XdrUint32(1);

      var contractData1 = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      contractData1.contractData = XdrLedgerKeyContractData(
        address1,
        key1,
        XdrContractDataDurability.PERSISTENT,
      );

      var address2 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address2.contractId =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var key2 = XdrSCVal(XdrSCValType.SCV_U32);
      key2.u32 = XdrUint32(2);

      var contractData2 = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      contractData2.contractData = XdrLedgerKeyContractData(
        address2,
        key2,
        XdrContractDataDurability.TEMPORARY,
      );

      var wasmHash =
          XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33)));

      var contractCode = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
      contractCode.contractCode = XdrLedgerKeyContractCode(wasmHash);

      var original =
          XdrLedgerFootprint([contractData1, contractCode], [contractData2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerFootprint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerFootprint.decode(input);

      expect(decoded.readOnly.length, equals(2));
      expect(decoded.readOnly[0].discriminant.value,
          equals(XdrLedgerEntryType.CONTRACT_DATA.value));
      expect(decoded.readOnly[1].discriminant.value,
          equals(XdrLedgerEntryType.CONTRACT_CODE.value));
      expect(decoded.readWrite.length, equals(1));
      expect(decoded.readWrite[0].discriminant.value,
          equals(XdrLedgerEntryType.CONTRACT_DATA.value));
    });

    test('XdrSCSpecEntry SC_SPEC_ENTRY_UDT_UNION_V0 with multiple case types encode/decode',
        () {
      var voidCase = XdrSCSpecUDTUnionCaseVoidV0('Void case', 'None');
      var unionCase1 =
          XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0);
      unionCase1.voidCase = voidCase;

      var tupleCase = XdrSCSpecUDTUnionCaseTupleV0('Tuple case', 'Some', [
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING),
      ]);
      var unionCase2 =
          XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0);
      unionCase2.tupleCase = tupleCase;

      var unionSpec = XdrSCSpecUDTUnionV0(
          'Union doc', 'lib', 'Option', [unionCase1, unionCase2]);

      var original =
          XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0);
      original.udtUnionV0 = unionSpec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEntry.decode(input);

      expect(decoded.discriminant.value,
          equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_UDT_UNION_V0.value));
      expect(decoded.udtUnionV0!.name, equals('Option'));
      expect(decoded.udtUnionV0!.cases.length, equals(2));
      expect(
          decoded.udtUnionV0!.cases[0].discriminant.value,
          equals(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0
              .value));
      expect(
          decoded.udtUnionV0!.cases[1].discriminant.value,
          equals(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0
              .value));
    });
  });
}
