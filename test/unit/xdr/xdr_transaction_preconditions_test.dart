// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Transaction Types - Edge Cases & Unique Behavior', () {
    test('XdrPreconditionsV2 with all optional fields populated', () {
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(1000000)),
        XdrUint64(BigInt.from(2000000)),
      );

      var ledgerBounds = XdrLedgerBounds(
        XdrUint32(100),
        XdrUint32(200),
      );

      var signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
      signerKey.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var original = XdrPreconditionsV2(
        timeBounds,
        ledgerBounds,
        XdrSequenceNumber(BigInt.from(123456789)),
        XdrUint64(BigInt.from(7200)),
        XdrUint32(10),
        [signerKey],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPreconditionsV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPreconditionsV2.decode(input);

      expect(decoded.timeBounds, isNotNull);
      expect(decoded.timeBounds!.minTime.uint64, equals(BigInt.from(1000000)));
      expect(decoded.ledgerBounds, isNotNull);
      expect(decoded.ledgerBounds!.minLedger.uint32, equals(100));
      expect(decoded.minSeqNum, isNotNull);
      expect(decoded.minSeqNum!.sequenceNumber, equals(BigInt.from(123456789)));
      expect(decoded.minSeqAge.uint64, equals(BigInt.from(7200)));
      expect(decoded.minSeqLedgerGap.uint32, equals(10));
      expect(decoded.extraSigners.length, equals(1));
    });

    test('XdrTransactionV0 with null timeBounds encode/decode', () {
      var sourceAccountEd25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55)));
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(null, XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionV0Ext(0);

      var original = XdrTransactionV0(
        sourceAccountEd25519,
        XdrUint32(500),
        XdrSequenceNumber(BigInt.from(7777777)),
        null,
        memo,
        [operation],
        ext,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionV0.decode(input);

      expect(decoded.fee.uint32, equals(500));
      expect(decoded.timeBounds, isNull);
    });

    test('XdrTransactionEnvelope fromEnvelopeXdrString and toEnvelopeXdrBase64', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF7)));

      var preconditions = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(null, XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(300),
        XdrSequenceNumber(BigInt.from(9999999)),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var envelope = XdrTransactionV1Envelope(tx, []);

      var original = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      original.v1 = envelope;

      var base64String = original.toEnvelopeXdrBase64();
      var decoded = XdrTransactionEnvelope.fromEnvelopeXdrString(base64String);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value));
      expect(decoded.v1, isNotNull);
      expect(decoded.v1!.tx.fee.uint32, equals(300));
    });

    test('XdrSorobanTransactionMetaV2 with null returnValue', () {
      var ext = XdrSorobanTransactionMetaExt(0);
      var original = XdrSorobanTransactionMetaV2(ext, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMetaV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMetaV2.decode(input);

      expect(decoded.returnValue, isNull);
    });

    test('XdrSorobanTransactionMetaV2 with returnValue', () {
      var ext = XdrSorobanTransactionMetaExt(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_U32);
      scVal.u32 = XdrUint32(42);

      var original = XdrSorobanTransactionMetaV2(ext, scVal);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionMetaV2.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionMetaV2.decode(input);

      expect(decoded.returnValue, isNotNull);
      expect(decoded.returnValue!.u32!.uint32, equals(42));
    });

    test('XdrContractEvent with hash (non-null optional)', () {
      var ext = XdrExtensionPoint(0);
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xBB)));
      var scVal = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal.b = true;
      var bodyV0 = XdrContractEventV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var original = XdrContractEvent(ext, hash, XdrContractEventType.CONTRACT, body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractEvent.decode(input);

      expect(decoded.hash, isNotNull);
      expect(decoded.type.value, equals(XdrContractEventType.CONTRACT.value));
    });

    test('XdrContractEvent with null hash', () {
      var ext = XdrExtensionPoint(0);
      var scVal = XdrSCVal(XdrSCValType.SCV_BOOL);
      scVal.b = true;
      var bodyV0 = XdrContractEventV0([], scVal);
      var body = XdrContractEventBody(0);
      body.v0 = bodyV0;

      var original = XdrContractEvent(ext, null, XdrContractEventType.DIAGNOSTIC, body);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrContractEvent.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrContractEvent.decode(input);

      expect(decoded.hash, isNull);
      expect(decoded.type.value, equals(XdrContractEventType.DIAGNOSTIC.value));
    });

    test('XdrTransactionResultResult with txSUCCESS and operation results', () {
      var opResult = XdrOperationResult(XdrOperationResultCode.opINNER);
      opResult.tr = XdrOperationResultTr(XdrOperationType.INFLATION);
      opResult.tr!.inflationResult = XdrInflationResult(XdrInflationResultCode.INFLATION_NOT_TIME);

      var original = XdrTransactionResultResult(XdrTransactionResultCode.txSUCCESS);
      original.results = [opResult];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txSUCCESS.value));
      expect(decoded.results, isNotNull);
      expect(decoded.results!.length, equals(1));
    });

    test('XdrTransactionResultResult with txFEE_BUMP_INNER_SUCCESS and innerResultPair', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var innerResultResult = XdrInnerTransactionResultResult(XdrTransactionResultCode.txSUCCESS);
      innerResultResult.results = [];
      var innerResult = XdrInnerTransactionResult(XdrInt64(BigInt.from(100)), innerResultResult, XdrTransactionResultExt(0));
      var innerResultPair = XdrInnerTransactionResultPair(hash, innerResult);

      var original = XdrTransactionResultResult(XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS);
      original.innerResultPair = innerResultPair;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txFEE_BUMP_INNER_SUCCESS.value));
      expect(decoded.innerResultPair, isNotNull);
    });

    test('XdrTransactionResultResult with txFEE_BUMP_INNER_FAILED and innerResultPair', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));
      var innerResultResult = XdrInnerTransactionResultResult(XdrTransactionResultCode.txFAILED);
      innerResultResult.results = [];
      var innerResult = XdrInnerTransactionResult(XdrInt64(BigInt.from(100)), innerResultResult, XdrTransactionResultExt(0));
      var innerResultPair = XdrInnerTransactionResultPair(hash, innerResult);

      var original = XdrTransactionResultResult(XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED);
      original.innerResultPair = innerResultPair;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED.value));
      expect(decoded.innerResultPair, isNotNull);
    });

    test('XdrTransactionResultResult with txTOO_EARLY (default branch - null results and innerResultPair)', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txTOO_EARLY);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txTOO_EARLY.value));
      expect(decoded.results, isNull);
      expect(decoded.innerResultPair, isNull);
    });
  });

  group('XDR Soroban Authorization - Factory Methods & Complex Nesting', () {
    test('XdrSorobanAuthorizedFunction.forInvokeContractArgs factory', () {
      var contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))));

      var functionName = "test";
      var args = XdrInvokeContractArgs(contractAddress, functionName, []);

      var original = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedFunction.decode(input);

      expect(decoded.type.value, equals(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN.value));
      expect(decoded.contractFn, isNotNull);
    });

    test('XdrSorobanAuthorizedFunction.forCreateContractArgs factory', () {
      var contractIDPreimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB))));
      contractIDPreimage.address = address;
      contractIDPreimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var args = XdrCreateContractArgs(contractIDPreimage, executable);

      var original = XdrSorobanAuthorizedFunction.forCreateContractArgs(args);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedFunction.decode(input);

      expect(decoded.type.value, equals(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN.value));
      expect(decoded.createContractHostFn, isNotNull);
    });

    test('XdrSorobanAuthorizedFunction.forCreateContractArgsV2 factory', () {
      var contractIDPreimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAA))));
      contractIDPreimage.address = address;
      contractIDPreimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));

      var executable = XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
      executable.wasmHash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xCC)));

      var argsV2 = XdrCreateContractArgsV2(contractIDPreimage, executable, []);

      var original = XdrSorobanAuthorizedFunction.forCreateContractArgsV2(argsV2);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedFunction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedFunction.decode(input);

      expect(decoded.type.value, equals(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN.value));
      expect(decoded.createContractV2HostFn, isNotNull);
    });

    test('XdrSorobanAuthorizedInvocation with recursive sub-invocations', () {
      var contractAddress1 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress1.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress1.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDD))));

      var functionName1 = "test";
      var args1 = XdrInvokeContractArgs(contractAddress1, functionName1, []);
      var function1 = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args1);

      var contractAddress2 = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress2.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress2.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE))));

      var functionName2 = "test";
      var args2 = XdrInvokeContractArgs(contractAddress2, functionName2, []);
      var function2 = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args2);

      var subInvocation = XdrSorobanAuthorizedInvocation(function2, []);

      var original = XdrSorobanAuthorizedInvocation(function1, [subInvocation]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizedInvocation.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizedInvocation.decode(input);

      expect(decoded.subInvocations.length, equals(1));
    });

    test('XdrSorobanCredentials ADDRESS with nested address credentials', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF))));

      var signature = XdrSCVal(XdrSCValType.SCV_BOOL);
      signature.b = true;

      var addressCreds = XdrSorobanAddressCredentials(address, XdrInt64(BigInt.from(54321)), XdrUint32(10000), signature);

      var original = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      original.address = addressCreds;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanCredentials.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanCredentials.decode(input);

      expect(decoded.type.value, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS.value));
      expect(decoded.address, isNotNull);
      expect(decoded.address!.nonce.int64, equals(BigInt.from(54321)));
    });
  });
}
