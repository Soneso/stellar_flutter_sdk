// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Transaction Types - Additional Deep Branch Testing', () {
    test('XdrTransactionSignaturePayloadTaggedTransaction ENVELOPE_TYPE_TX_V0 encode/decode', () {
      var sourceAccountEd25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x11)));
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(100000)),
        XdrUint64(BigInt.from(200000)),
      );
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionV0Ext(0);

      var tx = XdrTransactionV0(
        sourceAccountEd25519,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(12345))),
        timeBounds,
        memo,
        [operation],
        ext,
      );

      var original = XdrTransactionSignaturePayloadTaggedTransaction(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);
      original.tx = null;

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSignaturePayloadTaggedTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSignaturePayloadTaggedTransaction.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0.value));
    });

    test('XdrFeeBumpTransaction full encode/decode with signatures', () {
      var feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x22)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x33)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(123456))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var innerTxEnvelope = XdrTransactionV1Envelope(tx, []);
      var innerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTx.v1 = innerTxEnvelope;

      var original = XdrFeeBumpTransaction(
        feeSource,
        XdrInt64(BigInt.from(20000)),
        innerTx,
        XdrFeeBumpTransactionExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrFeeBumpTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrFeeBumpTransaction.decode(input);

      expect(decoded.fee.int64, equals(BigInt.from(20000)));
      expect(decoded.innerTx.v1, isNotNull);
    });

    test('XdrFeeBumpTransactionEnvelope with signatures encode/decode', () {
      var feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(150),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(234567))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var innerTxEnvelope = XdrTransactionV1Envelope(tx, []);
      var innerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTx.v1 = innerTxEnvelope;

      var feeBumpTx = XdrFeeBumpTransaction(
        feeSource,
        XdrInt64(BigInt.from(30000)),
        innerTx,
        XdrFeeBumpTransactionExt(0),
      );

      var signature = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([1, 2, 3, 4])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xAA))),
      );

      var original = XdrFeeBumpTransactionEnvelope(feeBumpTx, [signature, signature]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrFeeBumpTransactionEnvelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrFeeBumpTransactionEnvelope.decode(input);

      expect(decoded.tx.fee.int64, equals(BigInt.from(30000)));
      expect(decoded.signatures.length, equals(2));
    });

    test('XdrTransactionResultCode all error codes decode', () {
      final errorCodes = [
        XdrTransactionResultCode.txTOO_LATE,
        XdrTransactionResultCode.txMISSING_OPERATION,
        XdrTransactionResultCode.txBAD_SEQ,
        XdrTransactionResultCode.txBAD_AUTH,
        XdrTransactionResultCode.txINSUFFICIENT_BALANCE,
        XdrTransactionResultCode.txNO_ACCOUNT,
        XdrTransactionResultCode.txINSUFFICIENT_FEE,
        XdrTransactionResultCode.txBAD_AUTH_EXTRA,
        XdrTransactionResultCode.txINTERNAL_ERROR,
        XdrTransactionResultCode.txNOT_SUPPORTED,
        XdrTransactionResultCode.txBAD_SPONSORSHIP,
        XdrTransactionResultCode.txSOROBAN_INVALID,
      ];

      for (var code in errorCodes) {
        XdrDataOutputStream output = XdrDataOutputStream();
        XdrTransactionResultCode.encode(output, code);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrTransactionResultCode.decode(input);

        expect(decoded, isNotNull);
      }
    });

    test('XdrTransactionResultResult with txTOO_LATE encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txTOO_LATE, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txTOO_LATE.value));
      expect(decoded.results, isNull);
      expect(decoded.innerResultPair, isNull);
    });

    test('XdrTransactionResultResult with txMISSING_OPERATION encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txMISSING_OPERATION, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txMISSING_OPERATION.value));
    });

    test('XdrTransactionResultResult with txBAD_SEQ encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txBAD_SEQ, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txBAD_SEQ.value));
    });

    test('XdrTransactionResultResult with txINSUFFICIENT_BALANCE encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txINSUFFICIENT_BALANCE, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txINSUFFICIENT_BALANCE.value));
    });

    test('XdrTransactionResultResult with txNOT_SUPPORTED encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txNOT_SUPPORTED, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txNOT_SUPPORTED.value));
    });

    test('XdrTransactionResultResult with txSOROBAN_INVALID encode/decode', () {
      var original = XdrTransactionResultResult(XdrTransactionResultCode.txSOROBAN_INVALID, null, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txSOROBAN_INVALID.value));
    });

    test('XdrInnerTransactionResultResult with txTOO_EARLY encode/decode', () {
      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txTOO_EARLY, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txTOO_EARLY.value));
      expect(decoded.results, isNull);
    });

    test('XdrInnerTransactionResultResult with txBAD_AUTH encode/decode', () {
      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txBAD_AUTH, null);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txBAD_AUTH.value));
    });

    test('XdrInnerTransactionResultResult with operation results encode/decode', () {
      var opResult = XdrOperationResult(XdrOperationResultCode.opBAD_AUTH);

      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txFAILED, [opResult]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txFAILED.value));
      expect(decoded.results, isNotNull);
      expect(decoded.results!.length, equals(1));
    });

    test('XdrInnerTransactionResult full encode/decode', () {
      var opResult = XdrOperationResult(XdrOperationResultCode.opBAD_AUTH);
      var resultResult = XdrInnerTransactionResultResult(XdrTransactionResultCode.txSUCCESS, [opResult]);

      var original = XdrInnerTransactionResult(
        XdrInt64(BigInt.from(500)),
        resultResult,
        XdrTransactionResultExt(0),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResult.decode(input);

      expect(decoded.feeCharged.int64, equals(BigInt.from(500)));
      expect(decoded.result.discriminant.value, equals(XdrTransactionResultCode.txSUCCESS.value));
    });

    test('XdrInnerTransactionResultPair encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x66)));
      var opResult = XdrOperationResult(XdrOperationResultCode.opNOT_SUPPORTED);
      var resultResult = XdrInnerTransactionResultResult(XdrTransactionResultCode.txFAILED, [opResult]);
      var result = XdrInnerTransactionResult(
        XdrInt64(BigInt.from(750)),
        resultResult,
        XdrTransactionResultExt(0),
      );

      var original = XdrInnerTransactionResultPair(hash, result);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultPair.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultPair.decode(input);

      expect(decoded.transactionHash.hash.length, equals(32));
      expect(decoded.result.feeCharged.int64, equals(BigInt.from(750)));
    });

    test('XdrTransactionResultPair encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x77)));
      var resultResult = XdrTransactionResultResult(XdrTransactionResultCode.txTOO_EARLY, null, null);
      var result = XdrTransactionResult(
        XdrInt64(BigInt.from(1500)),
        resultResult,
        XdrTransactionResultExt(0),
      );

      var original = XdrTransactionResultPair(hash, result);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultPair.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultPair.decode(input);

      expect(decoded.transactionHash.hash.length, equals(32));
      expect(decoded.result.feeCharged.int64, equals(BigInt.from(1500)));
    });

    test('XdrTransactionResultSet with multiple results encode/decode', () {
      var hash1 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x88)));
      var resultResult1 = XdrTransactionResultResult(XdrTransactionResultCode.txSUCCESS, [], null);
      var result1 = XdrTransactionResult(XdrInt64(BigInt.from(1000)), resultResult1, XdrTransactionResultExt(0));
      var pair1 = XdrTransactionResultPair(hash1, result1);

      var hash2 = XdrHash(Uint8List.fromList(List<int>.filled(32, 0x99)));
      var resultResult2 = XdrTransactionResultResult(XdrTransactionResultCode.txBAD_SEQ, null, null);
      var result2 = XdrTransactionResult(XdrInt64(BigInt.from(2000)), resultResult2, XdrTransactionResultExt(0));
      var pair2 = XdrTransactionResultPair(hash2, result2);

      var original = XdrTransactionResultSet([pair1, pair2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionResultSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionResultSet.decode(input);

      expect(decoded.results.length, equals(2));
    });

    test('XdrTransactionSet with multiple envelopes encode/decode', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var sourceAccount1 = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount1.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));
      var preconditions1 = XdrPreconditions(XdrPreconditionType.NONE);
      var memo1 = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation1 = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext1 = XdrTransactionExt(0);
      var tx1 = XdrTransaction(sourceAccount1, XdrUint32(100), XdrSequenceNumber(XdrBigInt64(BigInt.from(100))), preconditions1, memo1, [operation1], ext1);
      var txEnvelope1 = XdrTransactionV1Envelope(tx1, []);
      var envelope1 = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      envelope1.v1 = txEnvelope1;

      var sourceAccount2 = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount2.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var preconditions2 = XdrPreconditions(XdrPreconditionType.NONE);
      var memo2 = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation2 = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext2 = XdrTransactionExt(0);
      var tx2 = XdrTransaction(sourceAccount2, XdrUint32(200), XdrSequenceNumber(XdrBigInt64(BigInt.from(200))), preconditions2, memo2, [operation2], ext2);
      var txEnvelope2 = XdrTransactionV1Envelope(tx2, []);
      var envelope2 = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      envelope2.v1 = txEnvelope2;

      var original = XdrTransactionSet(hash, [envelope1, envelope2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSet.decode(input);

      expect(decoded.txEnvelopes.length, equals(2));
      expect(decoded.previousLedgerHash.hash.length, equals(32));
    });

    test('XdrTransactionSignaturePayload with ENVELOPE_TYPE_TX_FEE_BUMP encode/decode', () {
      var networkId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(300),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(3000))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var innerTxEnvelope = XdrTransactionV1Envelope(tx, []);
      var innerTx = XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      innerTx.v1 = innerTxEnvelope;

      var feeBumpTx = XdrFeeBumpTransaction(
        feeSource,
        XdrInt64(BigInt.from(5000)),
        innerTx,
        XdrFeeBumpTransactionExt(0),
      );

      var taggedTx = XdrTransactionSignaturePayloadTaggedTransaction(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP);

      var original = XdrTransactionSignaturePayload(networkId, taggedTx);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSignaturePayload.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSignaturePayload.decode(input);

      expect(decoded.networkId.hash.length, equals(32));
      expect(decoded.taggedTransaction.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value));
    });

    test('XdrSorobanAuthorizedFunction CREATE_CONTRACT_V2_HOST_FN encode/decode', () {
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

    test('XdrSorobanAuthorizedInvocation with sub-invocations encode/decode', () {
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

    test('XdrSorobanCredentials SOURCE_ACCOUNT encode/decode', () {
      var original = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanCredentials.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanCredentials.decode(input);

      expect(decoded.type.value, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT.value));
    });

    test('XdrSorobanCredentials ADDRESS encode/decode', () {
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

    test('XdrSorobanAuthorizationEntry with ADDRESS credentials encode/decode', () {
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xAB))));

      var signature = XdrSCVal(XdrSCValType.SCV_BOOL);
      signature.b = false;

      var addressCreds = XdrSorobanAddressCredentials(address, XdrInt64(BigInt.from(99999)), XdrUint32(20000), signature);

      var credentials = XdrSorobanCredentials(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      credentials.address = addressCreds;

      var contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBC))));

      var functionName = "test";
      var args = XdrInvokeContractArgs(contractAddress, functionName, []);

      var function = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);
      var rootInvocation = XdrSorobanAuthorizedInvocation(function, []);

      var original = XdrSorobanAuthorizationEntry(credentials, rootInvocation);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanAuthorizationEntry.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanAuthorizationEntry.decode(input);

      expect(decoded.credentials.type.value, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS.value));
      expect(decoded.credentials.address!.nonce.int64, equals(BigInt.from(99999)));
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_TX_V0 encode/decode', () {
      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0.value));
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_SCP encode/decode', () {
      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_SCP);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_SCP.value));
    });

    test('XdrHashIDPreimage ENVELOPE_TYPE_TX encode/decode', () {
      var original = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_TX);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimage.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimage.decode(input);

      expect(decoded.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value));
    });

    test('XdrHashIDPreimageOperationID encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCD)));

      var original = XdrHashIDPreimageOperationID(
        sourceAccount,
        XdrSequenceNumber(XdrBigInt64(BigInt.from(5000))),
        XdrUint32(2),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimageOperationID.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimageOperationID.decode(input);

      expect(decoded.opNum.uint32, equals(2));
      expect(decoded.seqNum.sequenceNumber.bigInt, equals(BigInt.from(5000)));
    });

    test('XdrHashIDPreimageRevokeID encode/decode', () {
      var accountID = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xDE))));

      var asset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);

      var original = XdrHashIDPreimageRevokeID(
        accountID,
        XdrSequenceNumber(XdrBigInt64(BigInt.from(3000))),
        XdrUint32(1),
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xEF))),
        asset,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimageRevokeID.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimageRevokeID.decode(input);

      expect(decoded.opNum.uint32, equals(1));
      expect(decoded.seqNum.sequenceNumber.bigInt, equals(BigInt.from(3000)));
      expect(decoded.asset.discriminant.value, equals(XdrAssetType.ASSET_TYPE_NATIVE.value));
    });

    test('XdrHashIDPreimageContractID encode/decode', () {
      var networkID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xF0)));

      var contractIDPreimage = XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
      var address = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      address.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      address.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF1))));
      contractIDPreimage.address = address;
      contractIDPreimage.salt = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF2)));

      var original = XdrHashIDPreimageContractID(networkID, contractIDPreimage);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimageContractID.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimageContractID.decode(input);

      expect(decoded.networkID.hash.length, equals(32));
      expect(decoded.contractIDPreimage.type.value, equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS.value));
    });

    test('XdrHashIDPreimageSorobanAuthorization encode/decode', () {
      var networkID = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xF3)));

      var contractAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      contractAddress.accountId = XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519));
      contractAddress.accountId!.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF4))));

      var functionName = "test";
      var args = XdrInvokeContractArgs(contractAddress, functionName, []);

      var function = XdrSorobanAuthorizedFunction.forInvokeContractArgs(args);
      var invocation = XdrSorobanAuthorizedInvocation(function, []);

      var original = XdrHashIDPreimageSorobanAuthorization(
        networkID,
        XdrInt64(BigInt.from(12345)),
        XdrUint32(30000),
        invocation,
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrHashIDPreimageSorobanAuthorization.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrHashIDPreimageSorobanAuthorization.decode(input);

      expect(decoded.networkID.hash.length, equals(32));
      expect(decoded.nonce.int64, equals(BigInt.from(12345)));
      expect(decoded.signatureExpirationLedger.uint32, equals(30000));
    });

    test('XdrTransactionV0Envelope with multiple signatures encode/decode', () {
      var sourceAccountEd25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF5)));
      var timeBounds = XdrTimeBounds(
        XdrUint64(BigInt.from(100000)),
        XdrUint64(BigInt.from(200000)),
      );
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionV0Ext(0);

      var tx = XdrTransactionV0(
        sourceAccountEd25519,
        XdrUint32(100),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(12345))),
        timeBounds,
        memo,
        [operation],
        ext,
      );

      var signature1 = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([1, 2, 3, 4])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xAA))),
      );

      var signature2 = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([5, 6, 7, 8])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xBB))),
      );

      var original = XdrTransactionV0Envelope(tx, [signature1, signature2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionV0Envelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionV0Envelope.decode(input);

      expect(decoded.tx.fee.uint32, equals(100));
      expect(decoded.signatures.length, equals(2));
    });

    test('XdrTransactionV1Envelope with multiple signatures encode/decode', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF6)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(200),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(7654321))),
        preconditions,
        memo,
        [operation],
        ext,
      );

      var signature1 = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([9, 10, 11, 12])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xCC))),
      );

      var signature2 = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([13, 14, 15, 16])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xDD))),
      );

      var signature3 = XdrDecoratedSignature(
        XdrSignatureHint(Uint8List.fromList([17, 18, 19, 20])),
        XdrSignature(Uint8List.fromList(List<int>.filled(64, 0xEE))),
      );

      var original = XdrTransactionV1Envelope(tx, [signature1, signature2, signature3]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionV1Envelope.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionV1Envelope.decode(input);

      expect(decoded.tx.fee.uint32, equals(200));
      expect(decoded.signatures.length, equals(3));
    });

    test('XdrTransactionEnvelope fromEnvelopeXdrString and toEnvelopeXdrBase64', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF7)));

      var preconditions = XdrPreconditions(XdrPreconditionType.NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(300),
        XdrSequenceNumber(XdrBigInt64(BigInt.from(9999999))),
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

    test('XdrSorobanResources with footprint encode/decode', () {
      var ledgerKey = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
      ledgerKey.account = XdrLedgerKeyAccount(XdrAccountID(XdrPublicKey(XdrPublicKeyType.PUBLIC_KEY_TYPE_ED25519)));
      ledgerKey.account!.accountID.accountID.setEd25519(XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xF8))));

      var footprint = XdrLedgerFootprint([ledgerKey], []);

      var original = XdrSorobanResources(
        footprint,
        XdrUint32(2000000),
        XdrUint32(10000),
        XdrUint32(5000),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanResources.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanResources.decode(input);

      expect(decoded.instructions.uint32, equals(2000000));
      expect(decoded.diskReadBytes.uint32, equals(10000));
      expect(decoded.writeBytes.uint32, equals(5000));
      expect(decoded.footprint.readOnly.length, equals(1));
    });

    test('XdrSorobanTransactionData with resources encode/decode', () {
      var footprint = XdrLedgerFootprint([], []);
      var resources = XdrSorobanResources(
        footprint,
        XdrUint32(1500000),
        XdrUint32(7500),
        XdrUint32(2500),
      );
      var ext = XdrSorobanTransactionDataExt(0);

      var original = XdrSorobanTransactionData(
        ext,
        resources,
        XdrInt64(BigInt.from(750000)),
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanTransactionData.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanTransactionData.decode(input);

      expect(decoded.resources.instructions.uint32, equals(1500000));
      expect(decoded.resourceFee.int64, equals(BigInt.from(750000)));
    });

    test('XdrSorobanResourcesExtV0 encode/decode', () {
      var original = XdrSorobanResourcesExtV0([XdrUint32(10), XdrUint32(20), XdrUint32(30)]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSorobanResourcesExtV0.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSorobanResourcesExtV0.decode(input);

      expect(decoded.archivedSorobanEntries.length, equals(3));
      expect(decoded.archivedSorobanEntries[0].uint32, equals(10));
      expect(decoded.archivedSorobanEntries[1].uint32, equals(20));
      expect(decoded.archivedSorobanEntries[2].uint32, equals(30));
    });
  });
}
