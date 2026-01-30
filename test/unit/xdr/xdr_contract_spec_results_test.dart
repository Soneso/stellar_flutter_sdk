// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Contract Types - Deep Branch Testing Part 2', () {
    test('XdrSCSpecEntry SC_SPEC_ENTRY_EVENT_V0 encode/decode', () {
      var param1 = XdrSCSpecEventParamV0(
        'Param doc',
        'amount',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U64),
        XdrSCSpecEventParamLocationV0.SC_SPEC_EVENT_PARAM_LOCATION_DATA,
      );

      var eventSpec = XdrSCSpecEventV0(
        'Event doc',
        'lib',
        'Transfer',
        ['topic1', 'topic2'],
        [param1],
        XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_SINGLE_VALUE,
      );

      var original = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0);
      original.eventV0 = eventSpec;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecEntryKind.SC_SPEC_ENTRY_EVENT_V0.value));
      expect(decoded.eventV0, isNotNull);
      expect(decoded.eventV0!.name, equals('Transfer'));
      expect(decoded.eventV0!.prefixTopics.length, equals(2));
      expect(decoded.eventV0!.params.length, equals(1));
    });

    test('XdrSCSpecEventV0 with VEC data format encode/decode', () {
      var param1 = XdrSCSpecEventParamV0(
        'Doc for amount',
        'amount',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I128),
        XdrSCSpecEventParamLocationV0.SC_SPEC_EVENT_PARAM_LOCATION_TOPIC_LIST,
      );

      var original = XdrSCSpecEventV0(
        'Event documentation',
        'mylib',
        'DataEvent',
        [],
        [param1],
        XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_VEC,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEventV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEventV0.decode(input);

      expect(decoded.name, equals('DataEvent'));
      expect(decoded.dataFormat.value, equals(XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_VEC.value));
      expect(decoded.params[0].location.value, equals(XdrSCSpecEventParamLocationV0.SC_SPEC_EVENT_PARAM_LOCATION_TOPIC_LIST.value));
    });

    test('XdrSCSpecEventV0 with MAP data format encode/decode', () {
      var param1 = XdrSCSpecEventParamV0(
        'Key doc',
        'key',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING),
        XdrSCSpecEventParamLocationV0.SC_SPEC_EVENT_PARAM_LOCATION_DATA,
      );

      var original = XdrSCSpecEventV0(
        'Map event doc',
        'lib',
        'MapEvent',
        ['prefix'],
        [param1],
        XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_MAP,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecEventV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecEventV0.decode(input);

      expect(decoded.dataFormat.value, equals(XdrSCSpecEventDataFormat.SC_SPEC_EVENT_DATA_FORMAT_MAP.value));
      expect(decoded.prefixTopics.length, equals(1));
      expect(decoded.prefixTopics[0], equals('prefix'));
    });

    test('XdrSCSpecUDTUnionCaseV0 SC_SPEC_UDT_UNION_CASE_VOID_V0 encode/decode', () {
      var voidCase = XdrSCSpecUDTUnionCaseVoidV0('Void case documentation', 'VoidVariant');

      var original = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0);
      original.voidCase = voidCase;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTUnionCaseV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTUnionCaseV0.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0.value));
      expect(decoded.voidCase, isNotNull);
      expect(decoded.voidCase!.name, equals('VoidVariant'));
      expect(decoded.voidCase!.doc, equals('Void case documentation'));
    });

    test('XdrHostFunctionType enum all variants encode/decode', () {
      final types = [
        XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT,
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT,
        XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM,
        XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrHostFunctionType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrHostFunctionType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrContractIDPreimageType enum all variants encode/decode', () {
      final types = [
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS,
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET,
      ];

      for (var type in types) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrContractIDPreimageType.encode(output, type);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrContractIDPreimageType.decode(input);

        expect(decoded.value, equals(type.value));
      }
    });

    test('XdrInvokeHostFunctionResultCode enum all variants encode/decode', () {
      final codes = [
        XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS,
        XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED,
        XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED,
        XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED,
        XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED,
        XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrInvokeHostFunctionResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrInvokeHostFunctionResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrInvokeHostFunctionResult INVOKE_HOST_FUNCTION_SUCCESS encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB)));

      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS);
      original.success = hash;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_SUCCESS.value));
      expect(decoded.success, isNotNull);
      expect(decoded.success!.hash, equals(hash.hash));
    });

    test('XdrInvokeHostFunctionResult INVOKE_HOST_FUNCTION_MALFORMED encode/decode', () {
      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_MALFORMED.value));
      expect(decoded.success, isNull);
    });

    test('XdrInvokeHostFunctionResult INVOKE_HOST_FUNCTION_TRAPPED encode/decode', () {
      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_TRAPPED.value));
    });

    test('XdrInvokeHostFunctionResult INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED encode/decode', () {
      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_RESOURCE_LIMIT_EXCEEDED.value));
    });

    test('XdrInvokeHostFunctionResult INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED encode/decode', () {
      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_ENTRY_ARCHIVED.value));
    });

    test('XdrInvokeHostFunctionResult INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE encode/decode', () {
      var original = XdrInvokeHostFunctionResult(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeHostFunctionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeHostFunctionResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrInvokeHostFunctionResultCode.INVOKE_HOST_FUNCTION_INSUFFICIENT_REFUNDABLE_FEE.value));
    });

    test('XdrExtendFootprintTTLResultCode enum all variants encode/decode', () {
      final codes = [
        XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS,
        XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_MALFORMED,
        XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED,
        XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrExtendFootprintTTLResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrExtendFootprintTTLResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrExtendFootprintTTLResult EXTEND_FOOTPRINT_TTL_SUCCESS encode/decode', () {
      var original = XdrExtendFootprintTTLResult(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrExtendFootprintTTLResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrExtendFootprintTTLResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_SUCCESS.value));
    });

    test('XdrExtendFootprintTTLResult EXTEND_FOOTPRINT_TTL_MALFORMED encode/decode', () {
      var original = XdrExtendFootprintTTLResult(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrExtendFootprintTTLResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrExtendFootprintTTLResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_MALFORMED.value));
    });

    test('XdrExtendFootprintTTLResult EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED encode/decode', () {
      var original = XdrExtendFootprintTTLResult(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrExtendFootprintTTLResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrExtendFootprintTTLResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_RESOURCE_LIMIT_EXCEEDED.value));
    });

    test('XdrExtendFootprintTTLResult EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE encode/decode', () {
      var original = XdrExtendFootprintTTLResult(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrExtendFootprintTTLResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrExtendFootprintTTLResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrExtendFootprintTTLResultCode.EXTEND_FOOTPRINT_TTL_INSUFFICIENT_REFUNDABLE_FEE.value));
    });

    test('XdrRestoreFootprintResultCode enum all variants encode/decode', () {
      final codes = [
        XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS,
        XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_MALFORMED,
        XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED,
        XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE,
      ];

      for (var code in codes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrRestoreFootprintResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrRestoreFootprintResultCode.decode(input);

        expect(decoded.value, equals(code.value));
      }
    });

    test('XdrRestoreFootprintResult RESTORE_FOOTPRINT_SUCCESS encode/decode', () {
      var original = XdrRestoreFootprintResult(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRestoreFootprintResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRestoreFootprintResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_SUCCESS.value));
    });

    test('XdrRestoreFootprintResult RESTORE_FOOTPRINT_MALFORMED encode/decode', () {
      var original = XdrRestoreFootprintResult(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_MALFORMED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRestoreFootprintResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRestoreFootprintResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_MALFORMED.value));
    });

    test('XdrRestoreFootprintResult RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED encode/decode', () {
      var original = XdrRestoreFootprintResult(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRestoreFootprintResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRestoreFootprintResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_RESOURCE_LIMIT_EXCEEDED.value));
    });

    test('XdrRestoreFootprintResult RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE encode/decode', () {
      var original = XdrRestoreFootprintResult(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRestoreFootprintResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRestoreFootprintResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrRestoreFootprintResultCode.RESTORE_FOOTPRINT_INSUFFICIENT_REFUNDABLE_FEE.value));
    });

    test('XdrLedgerFootprint with empty readOnly and readWrite encode/decode', () {
      var original = XdrLedgerFootprint([], []);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrLedgerFootprint.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrLedgerFootprint.decode(input);

      expect(decoded.readOnly, isEmpty);
      expect(decoded.readWrite, isEmpty);
    });

    test('XdrLedgerFootprint with CONTRACT_DATA ledger keys encode/decode', () {
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

    test('XdrLedgerFootprint with CONTRACT_CODE ledger keys encode/decode', () {
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

    test('XdrInvokeHostFunctionOp encode/decode', () {
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

    test('XdrExtendFootprintTTLOp encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var original = XdrExtendFootprintTTLOp(ext, XdrUint32(1000));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrExtendFootprintTTLOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrExtendFootprintTTLOp.decode(input);

      expect(decoded.ext.discriminant, equals(0));
      expect(decoded.extendTo.uint32, equals(1000));
    });

    test('XdrRestoreFootprintOp encode/decode', () {
      var ext = XdrExtensionPoint(0);
      var original = XdrRestoreFootprintOp(ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrRestoreFootprintOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrRestoreFootprintOp.decode(input);

      expect(decoded.ext.discriminant, equals(0));
    });

    test('XdrSCEnvMetaKind enum all variants encode/decode', () {
      final kinds = [
        XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION,
      ];

      for (var kind in kinds) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCEnvMetaKind.encode(output, kind);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCEnvMetaKind.decode(input);

        expect(decoded.value, equals(kind.value));
      }
    });

    test('XdrSCEnvMetaEntry SC_ENV_META_KIND_INTERFACE_VERSION encode/decode', () {
      var original = XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION);
      original.interfaceVersion = XdrUint64(BigInt.from(42));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCEnvMetaEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCEnvMetaEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION.value));
      expect(decoded.interfaceVersion!.uint64, equals(BigInt.from(42)));
    });

    test('XdrSCMetaV0 encode/decode', () {
      var original = XdrSCMetaV0('Test key', 'Test value');

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCMetaV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCMetaV0.decode(input);

      expect(decoded.key, equals('Test key'));
      expect(decoded.value, equals('Test value'));
    });

    test('XdrSCMetaKind enum all variants encode/decode', () {
      final kinds = [
        XdrSCMetaKind.SC_META_V0,
      ];

      for (var kind in kinds) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrSCMetaKind.encode(output, kind);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrSCMetaKind.decode(input);

        expect(decoded.value, equals(kind.value));
      }
    });

    test('XdrSCMetaEntry SC_META_V0 encode/decode', () {
      var metaV0 = XdrSCMetaV0('key', 'value');

      var original = XdrSCMetaEntry(XdrSCMetaKind.SC_META_V0);
      original.v0 = metaV0;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCMetaEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCMetaEntry.decode(input);

      expect(decoded.discriminant.value, equals(XdrSCMetaKind.SC_META_V0.value));
      expect(decoded.v0, isNotNull);
      expect(decoded.v0!.key, equals('key'));
      expect(decoded.v0!.value, equals('value'));
    });

    test('XdrSCNonceKey encode/decode', () {
      var original = XdrSCNonceKey(XdrInt64(BigInt.from(12345)));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCNonceKey.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCNonceKey.decode(input);

      expect(decoded.nonce.int64, equals(BigInt.from(12345)));
    });

    test('XdrSCMapEntry encode/decode', () {
      var key = XdrSCVal(XdrSCValType.SCV_STRING);
      key.str = 'name';

      var val = XdrSCVal(XdrSCValType.SCV_STRING);
      val.str = 'Alice';

      var original = XdrSCMapEntry(key, val);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCMapEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCMapEntry.decode(input);

      expect(decoded.key.str, equals('name'));
      expect(decoded.val.str, equals('Alice'));
    });

    test('XdrInt128Parts encode/decode', () {
      var original = XdrInt128Parts(
        XdrInt64(BigInt.from(-100)),
        XdrUint64(BigInt.from(200)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt128Parts.decode(input);

      expect(decoded.hi.int64, equals(BigInt.from(-100)));
      expect(decoded.lo.uint64, equals(BigInt.from(200)));
    });

    test('XdrUInt128Parts encode/decode', () {
      var original = XdrUInt128Parts(
        XdrUint64(BigInt.from(300)),
        XdrUint64(BigInt.from(400)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt128Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt128Parts.decode(input);

      expect(decoded.hi.uint64, equals(BigInt.from(300)));
      expect(decoded.lo.uint64, equals(BigInt.from(400)));
    });

    test('XdrInt256Parts encode/decode', () {
      var original = XdrInt256Parts(
        XdrInt64(BigInt.from(-1000)),
        XdrUint64(BigInt.from(2000)),
        XdrUint64(BigInt.from(3000)),
        XdrUint64(BigInt.from(4000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInt256Parts.decode(input);

      expect(decoded.hiHi.int64, equals(BigInt.from(-1000)));
      expect(decoded.hiLo.uint64, equals(BigInt.from(2000)));
      expect(decoded.loHi.uint64, equals(BigInt.from(3000)));
      expect(decoded.loLo.uint64, equals(BigInt.from(4000)));
    });

    test('XdrUInt256Parts encode/decode', () {
      var original = XdrUInt256Parts(
        XdrUint64(BigInt.from(5000)),
        XdrUint64(BigInt.from(6000)),
        XdrUint64(BigInt.from(7000)),
        XdrUint64(BigInt.from(8000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrUInt256Parts.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrUInt256Parts.decode(input);

      expect(decoded.hiHi.uint64, equals(BigInt.from(5000)));
      expect(decoded.hiLo.uint64, equals(BigInt.from(6000)));
      expect(decoded.loHi.uint64, equals(BigInt.from(7000)));
      expect(decoded.loLo.uint64, equals(BigInt.from(8000)));
    });

    test('XdrSCSpecTypeOption encode/decode', () {
      var valueType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I64);
      var original = XdrSCSpecTypeOption(valueType);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeOption.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeOption.decode(input);

      expect(decoded.valueType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_I64.value));
    });

    test('XdrSCSpecTypeResult encode/decode', () {
      var okType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      var errorType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      var original = XdrSCSpecTypeResult(okType, errorType);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeResult.decode(input);

      expect(decoded.okType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_STRING.value));
      expect(decoded.errorType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U32.value));
    });

    test('XdrSCSpecTypeVec encode/decode', () {
      var elementType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BYTES);
      var original = XdrSCSpecTypeVec(elementType);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeVec.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeVec.decode(input);

      expect(decoded.elementType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_BYTES.value));
    });

    test('XdrSCSpecTypeMap encode/decode', () {
      var keyType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      var valueType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);
      var original = XdrSCSpecTypeMap(keyType, valueType);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeMap.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeMap.decode(input);

      expect(decoded.keyType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_STRING.value));
      expect(decoded.valueType.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_BOOL.value));
    });

    test('XdrSCSpecTypeTuple with multiple types encode/decode', () {
      var type1 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32);
      var type2 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING);
      var type3 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);
      var original = XdrSCSpecTypeTuple([type1, type2, type3]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeTuple.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeTuple.decode(input);

      expect(decoded.valueTypes.length, equals(3));
      expect(decoded.valueTypes[0].discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U32.value));
      expect(decoded.valueTypes[1].discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_STRING.value));
      expect(decoded.valueTypes[2].discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_BOOL.value));
    });

    test('XdrSCSpecTypeBytesN encode/decode', () {
      var original = XdrSCSpecTypeBytesN(XdrUint32(64));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeBytesN.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeBytesN.decode(input);

      expect(decoded.n.uint32, equals(64));
    });

    test('XdrSCSpecTypeUDT encode/decode', () {
      var original = XdrSCSpecTypeUDT('CustomType');

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecTypeUDT.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecTypeUDT.decode(input);

      expect(decoded.name, equals('CustomType'));
    });

    test('XdrSCSpecUDTStructFieldV0 encode/decode', () {
      var original = XdrSCSpecUDTStructFieldV0(
        'Field documentation',
        'fieldName',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U128),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTStructFieldV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTStructFieldV0.decode(input);

      expect(decoded.doc, equals('Field documentation'));
      expect(decoded.name, equals('fieldName'));
      expect(decoded.type.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_U128.value));
    });

    test('XdrSCSpecUDTStructV0 with multiple fields encode/decode', () {
      var field1 = XdrSCSpecUDTStructFieldV0(
        'First field',
        'field1',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
      );
      var field2 = XdrSCSpecUDTStructFieldV0(
        'Second field',
        'field2',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING),
      );

      var original = XdrSCSpecUDTStructV0('Struct doc', 'lib', 'MyStruct', [field1, field2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTStructV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTStructV0.decode(input);

      expect(decoded.doc, equals('Struct doc'));
      expect(decoded.name, equals('MyStruct'));
      expect(decoded.fields.length, equals(2));
      expect(decoded.fields[0].name, equals('field1'));
      expect(decoded.fields[1].name, equals('field2'));
    });

    test('XdrSCSpecUDTUnionCaseTupleV0 encode/decode', () {
      var type1 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I32);
      var type2 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);

      var original = XdrSCSpecUDTUnionCaseTupleV0('Tuple case', 'TupleName', [type1, type2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTUnionCaseTupleV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTUnionCaseTupleV0.decode(input);

      expect(decoded.doc, equals('Tuple case'));
      expect(decoded.name, equals('TupleName'));
      expect(decoded.type.length, equals(2));
    });

    test('XdrSCSpecUDTUnionV0 with multiple cases encode/decode', () {
      var voidCase = XdrSCSpecUDTUnionCaseVoidV0('Void case', 'VoidVariant');
      var unionCase1 = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_VOID_V0);
      unionCase1.voidCase = voidCase;

      var tupleCase = XdrSCSpecUDTUnionCaseTupleV0(
        'Tuple case',
        'TupleVariant',
        [XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32)],
      );
      var unionCase2 = XdrSCSpecUDTUnionCaseV0(XdrSCSpecUDTUnionCaseV0Kind.SC_SPEC_UDT_UNION_CASE_TUPLE_V0);
      unionCase2.tupleCase = tupleCase;

      var original = XdrSCSpecUDTUnionV0('Union doc', 'lib', 'MyUnion', [unionCase1, unionCase2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTUnionV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTUnionV0.decode(input);

      expect(decoded.doc, equals('Union doc'));
      expect(decoded.name, equals('MyUnion'));
      expect(decoded.cases.length, equals(2));
    });

    test('XdrSCSpecUDTEnumCaseV0 encode/decode', () {
      var original = XdrSCSpecUDTEnumCaseV0('Case doc', 'CaseOne', XdrUint32(1));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTEnumCaseV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTEnumCaseV0.decode(input);

      expect(decoded.doc, equals('Case doc'));
      expect(decoded.name, equals('CaseOne'));
      expect(decoded.value.uint32, equals(1));
    });

    test('XdrSCSpecUDTErrorEnumCaseV0 encode/decode', () {
      var original = XdrSCSpecUDTErrorEnumCaseV0('Error case doc', 'ErrorOne', XdrUint32(100));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecUDTErrorEnumCaseV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecUDTErrorEnumCaseV0.decode(input);

      expect(decoded.doc, equals('Error case doc'));
      expect(decoded.name, equals('ErrorOne'));
      expect(decoded.value.uint32, equals(100));
    });

    test('XdrSCSpecFunctionInputV0 encode/decode', () {
      var original = XdrSCSpecFunctionInputV0(
        'Input doc',
        'inputName',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I256),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecFunctionInputV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecFunctionInputV0.decode(input);

      expect(decoded.doc, equals('Input doc'));
      expect(decoded.name, equals('inputName'));
      expect(decoded.type.discriminant.value, equals(XdrSCSpecType.SC_SPEC_TYPE_I256.value));
    });

    test('XdrSCSpecFunctionV0 with multiple inputs and outputs encode/decode', () {
      var input1 = XdrSCSpecFunctionInputV0(
        'Input1 doc',
        'input1',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_U32),
      );
      var input2 = XdrSCSpecFunctionInputV0(
        'Input2 doc',
        'input2',
        XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_STRING),
      );

      var output1 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);
      var output2 = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_I64);

      var original = XdrSCSpecFunctionV0(
        'Function doc',
        'myFunction',
        [input1, input2],
        [output1, output2],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSCSpecFunctionV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSCSpecFunctionV0.decode(input);

      expect(decoded.doc, equals('Function doc'));
      expect(decoded.name, equals('myFunction'));
      expect(decoded.inputs.length, equals(2));
      expect(decoded.outputs.length, equals(2));
    });

    test('XdrCreateContractArgs encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var preimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = address;
      preimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var original = XdrCreateContractArgs(preimage, executable);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateContractArgs.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateContractArgs.decode(input);

      expect(decoded.contractIDPreimage.type.value, equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS.value));
      expect(decoded.executable.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM.value));
    });

    test('XdrCreateContractArgsV2 encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var preimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      preimage.address = address;
      preimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET);

      var arg1 = XdrSCVal(XdrSCValType.SCV_U32);
      arg1.u32 = XdrUint32(123);

      var arg2 = XdrSCVal(XdrSCValType.SCV_BOOL);
      arg2.b = true;

      var original = XdrCreateContractArgsV2(preimage, executable, [arg1, arg2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrCreateContractArgsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrCreateContractArgsV2.decode(input);

      expect(decoded.contractIDPreimage.type.value, equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS.value));
      expect(decoded.executable.type.value, equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value));
      expect(decoded.constructorArgs.length, equals(2));
    });

    test('XdrInvokeContractArgs encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      address.contractId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var arg1 = XdrSCVal(XdrSCValType.SCV_STRING);
      arg1.str = 'hello';

      var arg2 = XdrSCVal(XdrSCValType.SCV_I32);
      arg2.i32 = XdrInt32(-42);

      var original = XdrInvokeContractArgs(address, 'testMethod', [arg1, arg2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInvokeContractArgs.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInvokeContractArgs.decode(input);

      expect(decoded.contractAddress.discriminant.value, equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT.value));
      expect(decoded.functionName, equals('testMethod'));
      expect(decoded.args.length, equals(2));
      expect(decoded.args[0].str, equals('hello'));
      expect(decoded.args[1].i32!.int32, equals(-42));
    });
  });
}
