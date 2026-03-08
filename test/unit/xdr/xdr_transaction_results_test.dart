// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Transaction Results - Complex Constructions & Edge Cases', () {
    test('XdrInnerTransactionResultResult with txFAILED and operation results', () {
      var opResult = XdrOperationResult(XdrOperationResultCode.opBAD_AUTH);

      var original = XdrInnerTransactionResultResult(XdrTransactionResultCode.txFAILED);
      original.results = [opResult];

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrInnerTransactionResultResult.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrInnerTransactionResultResult.decode(input);

      expect(decoded.discriminant.value, equals(XdrTransactionResultCode.txFAILED.value));
      expect(decoded.results, isNotNull);
      expect(decoded.results!.length, equals(1));
    });

    test('XdrFeeBumpTransactionEnvelope with multiple signatures', () {
      var feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x44)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x55)));

      var preconditions = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(null, XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(150),
        XdrSequenceNumber(BigInt.from(234567)),
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

    test('XdrTransactionSet with multiple envelopes', () {
      var hash = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAA)));

      var sourceAccount1 = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount1.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xBB)));
      var preconditions1 = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      var memo1 = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation1 = XdrOperation(null, XdrOperationBody(XdrOperationType.INFLATION));
      var ext1 = XdrTransactionExt(0);
      var tx1 = XdrTransaction(sourceAccount1, XdrUint32(100), XdrSequenceNumber(BigInt.from(100)), preconditions1, memo1, [operation1], ext1);
      var txEnvelope1 = XdrTransactionV1Envelope(tx1, []);
      var envelope1 = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      envelope1.v1 = txEnvelope1;

      var sourceAccount2 = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount2.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xCC)));
      var preconditions2 = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      var memo2 = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation2 = XdrOperation(null, XdrOperationBody(XdrOperationType.INFLATION));
      var ext2 = XdrTransactionExt(0);
      var tx2 = XdrTransaction(sourceAccount2, XdrUint32(200), XdrSequenceNumber(BigInt.from(200)), preconditions2, memo2, [operation2], ext2);
      var txEnvelope2 = XdrTransactionV1Envelope(tx2, []);
      var envelope2 = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX);
      envelope2.v1 = txEnvelope2;

      var original = XdrTransactionSet(hash, [envelope1, envelope2]);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSet.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSet.decode(input);

      expect(decoded.txs.length, equals(2));
      expect(decoded.previousLedgerHash.hash.length, equals(32));
    });

    test('XdrTransactionSignaturePayload with ENVELOPE_TYPE_TX_FEE_BUMP', () {
      var networkId = XdrHash(Uint8List.fromList(List<int>.filled(32, 0xDD)));

      var feeSource = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      feeSource.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xEE)));

      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF)));

      var preconditions = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operation = XdrOperation(null, XdrOperationBody(XdrOperationType.INFLATION));
      var ext = XdrTransactionExt(0);

      var tx = XdrTransaction(
        sourceAccount,
        XdrUint32(300),
        XdrSequenceNumber(BigInt.from(3000)),
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
      taggedTx.feeBump = feeBumpTx;

      var original = XdrTransactionSignaturePayload(networkId, taggedTx);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransactionSignaturePayload.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransactionSignaturePayload.decode(input);

      expect(decoded.networkId.hash.length, equals(32));
      expect(decoded.taggedTransaction.discriminant.value, equals(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP.value));
    });

    test('XdrSorobanAuthorizationEntry with ADDRESS credentials', () {
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

    test('XdrSorobanResourcesExtV0 with array element values', () {
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
