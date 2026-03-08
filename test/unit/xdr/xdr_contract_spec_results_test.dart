// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Tests for XDR Contract Spec/Result types that go beyond simple roundtrip encode/decode.
  // Simple roundtrips are covered by auto-generated tests in test/unit/xdr/generated/.

  group('XdrLedgerFootprint edge cases', () {
    test('XdrLedgerFootprint with empty readOnly and readWrite', () {
      var original = XdrLedgerFootprint([], []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerFootprint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerFootprint.decode(input);

      expect(decoded.readOnly, isEmpty);
      expect(decoded.readWrite, isEmpty);
    });

    test('XdrLedgerFootprint with CONTRACT_DATA in readOnly', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var key = XdrSCVal(XdrSCValType.SCV_U32);
      key.u32 = XdrUint32(100);

      var contractData = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      contractData.contractData = XdrLedgerKeyContractData(
        address,
        key,
        XdrContractDataDurability.PERSISTENT,
      );

      var original = XdrLedgerFootprint([contractData], []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerFootprint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerFootprint.decode(input);

      expect(decoded.readOnly.length, equals(1));
      expect(decoded.readOnly[0].discriminant.value, equals(XdrLedgerEntryType.CONTRACT_DATA.value));
      expect(decoded.readWrite, isEmpty);
    });

    test('XdrLedgerFootprint with CONTRACT_CODE in readWrite', () {
      var wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var contractCode = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
      contractCode.contractCode = XdrLedgerKeyContractCode(wasmHash);

      var original = XdrLedgerFootprint([], [contractCode]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerFootprint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerFootprint.decode(input);

      expect(decoded.readOnly, isEmpty);
      expect(decoded.readWrite.length, equals(1));
      expect(decoded.readWrite[0].discriminant.value, equals(XdrLedgerEntryType.CONTRACT_CODE.value));
    });

    test('XdrLedgerFootprint with both readOnly and readWrite', () {
      var address1 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address1.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x11)));

      var key1 = XdrSCVal(XdrSCValType.SCV_U32);
      key1.u32 = XdrUint32(1);

      var contractData1 = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      contractData1.contractData = XdrLedgerKeyContractData(
        address1, key1, XdrContractDataDurability.PERSISTENT,
      );

      var wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x33)));
      var contractCode = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
      contractCode.contractCode = XdrLedgerKeyContractCode(wasmHash);

      var address2 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address2.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var key2 = XdrSCVal(XdrSCValType.SCV_U32);
      key2.u32 = XdrUint32(2);

      var contractData2 = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA);
      contractData2.contractData = XdrLedgerKeyContractData(
        address2, key2, XdrContractDataDurability.TEMPORARY,
      );

      var original = XdrLedgerFootprint([contractData1, contractCode], [contractData2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerFootprint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerFootprint.decode(input);

      expect(decoded.readOnly.length, equals(2));
      expect(decoded.readWrite.length, equals(1));
    });
  });

  group('XdrInvokeHostFunctionOp with auth', () {
    test('XdrInvokeHostFunctionOp with empty auth', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_U32);
      arg1.u32 = XdrUint32(99);

      var invokeArgs = XdrInvokeContractArgs(address, 'execute', [arg1]);

      var hostFunction = XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
      hostFunction.invokeContract = invokeArgs;

      var original = XdrInvokeHostFunctionOp(hostFunction, []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionOp.decode(input);

      expect(decoded.function.type.value, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT.value));
      expect(decoded.function.invokeContract!.functionName, equals('execute'));
      expect(decoded.auth, isEmpty);
    });

    test('XdrInvokeHostFunctionOp with auth entries', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var invokeArgs = XdrInvokeContractArgs(address, 'call', []);
      var hostFunction = XdrHostFunction(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT);
      hostFunction.invokeContract = invokeArgs;

      var authAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      authAddress.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var addressCreds = XdrSorobanAddressCredentials(
        authAddress,
        XdrInt64(BigInt.from(100)),
        XdrUint32(500),
        XdrSCVal(XdrSCValType.SCV_VOID),
      );

      var creds = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      creds.address = addressCreds;

      var authFunc = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN);
      authFunc.contractFn = XdrInvokeContractArgs(address, 'auth_call', []);

      var auth = XdrSorobanAuthorizationEntry(creds, XdrSorobanAuthorizedInvocation(authFunc, []));

      var original = XdrInvokeHostFunctionOp(hostFunction, [auth]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionOp.decode(input);

      expect(decoded.auth.length, equals(1));
      expect(decoded.auth[0].credentials.type.value,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS.value));
    });
  });

  group('XdrInvokeHostFunctionResult union branches', () {
    test('XdrInvokeHostFunctionResult SUCCESS has non-null success hash', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS);
      original.success = hash;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.success, isNotNull);
      expect(decoded.success!.hash, equals(hash.hash));
    });

    test('XdrInvokeHostFunctionResult MALFORMED has null success', () {
      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.success, isNull);
    });
  });
}
