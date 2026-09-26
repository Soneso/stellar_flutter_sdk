// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Decoding of malformed XDR: array counts the remaining bytes cannot hold and
// union discriminants without a matching arm, at stream level and through the
// public decoders. Each decoder vector is built with the SDK's own encoder and
// patched at a computed offset; the test checks the original bytes at that
// offset before patching.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XdrDataInputStream.readArrayLength', () {
    test('rejects a count with all bits set as negative', () {
      final input = XdrDataInputStream(bytes([0xFF, 0xFF, 0xFF, 0xFF]));
      expect(() => input.readArrayLength(), throwsNegativeCount(-1));
    });

    test('rejects a count with only the high bit set as negative', () {
      final input = XdrDataInputStream(
        bytes([0x80, 0x00, 0x00, 0x00, 0, 0, 0, 0]),
      );
      expect(() => input.readArrayLength(), throwsNegativeCount(-2147483648));
    });

    test('rejects a count above a quarter of the remaining bytes', () {
      final input = XdrDataInputStream(withCount(3, 8));
      expect(() => input.readArrayLength(), throwsCountRejected(3, 8));
    });

    test('rounds the quarter of the remaining bytes down', () {
      expect(XdrDataInputStream(withCount(2, 11)).readArrayLength(), equals(2));
      expect(
        () => XdrDataInputStream(withCount(3, 11)).readArrayLength(),
        throwsCountRejected(3, 11),
      );
    });

    test('accepts a count of exactly a quarter of the remaining bytes', () {
      final input = XdrDataInputStream(withCount(2, 8));
      expect(input.readArrayLength(), equals(2));
      expect(input.offset, equals(4));
    });

    test('accepts a zero count at the end of the input', () {
      final input = XdrDataInputStream(withCount(0, 0));
      expect(input.readArrayLength(), equals(0));
      expect(input.offset, equals(4));
    });

    test('rejects a count that is cut off', () {
      final input = XdrDataInputStream(bytes([0x00, 0x00, 0x01]));
      expect(() => input.readArrayLength(), throwsRangeError);
    });
  });

  group('XdrDataInputStream primitive arrays', () {
    test('readIntArray rejects a count beyond the remaining bytes', () {
      final input = XdrDataInputStream(withCount(2, 4));
      expect(() => input.readIntArray(), throwsCountRejected(2, 4));
    });

    test('readIntArray rejects a negative count', () {
      final input = XdrDataInputStream(withCount(-1, 4));
      expect(() => input.readIntArray(), throwsNegativeCount(-1));
    });

    test('readFloatArray rejects a count beyond the remaining bytes', () {
      final input = XdrDataInputStream(withCount(2, 4));
      expect(() => input.readFloatArray(), throwsCountRejected(2, 4));
    });

    test('readFloatArray rejects a negative count', () {
      final input = XdrDataInputStream(withCount(-1, 4));
      expect(() => input.readFloatArray(), throwsNegativeCount(-1));
    });

    test('readDoubleArray rejects a count beyond the remaining bytes', () {
      final input = XdrDataInputStream(withCount(3, 8));
      expect(() => input.readDoubleArray(), throwsCountRejected(3, 8));
    });

    test('readDoubleArray rejects a negative count', () {
      final input = XdrDataInputStream(withCount(-1, 8));
      expect(() => input.readDoubleArray(), throwsNegativeCount(-1));
    });
  });

  group('Array counts through the public decoders', () {
    test('transaction operations count beyond the remaining bytes', () {
      final vector = transactionOperationsCountVector();
      final remaining = vector.bytes.length - vector.countOffset - 4;
      final count = countAboveBound(remaining);

      expect(
        () => XdrTransactionEnvelope.fromEnvelopeXdrString(
          base64Encode(patchInt(vector.bytes, vector.countOffset, count)),
        ),
        throwsCountRejected(count, remaining),
      );
    });

    test('transaction operations negative count', () {
      final vector = transactionOperationsCountVector();

      expect(
        () => XdrTransactionEnvelope.fromEnvelopeXdrString(
          base64Encode(patchInt(vector.bytes, vector.countOffset, -1)),
        ),
        throwsNegativeCount(-1),
      );
    });

    test('contract cost params count beyond the remaining bytes', () {
      final params = XdrContractCostParams([
        XdrContractCostParamEntry(
          XdrExtensionPoint(0),
          XdrInt64(BigInt.from(10)),
          XdrInt64(BigInt.from(20)),
        ),
      ]);
      final encoded = base64Decode(params.toBase64EncodedXdrString());
      // The typedef array starts with its count.
      const countOffset = 0;
      expect(readIntAt(encoded, countOffset), equals(1));
      final remaining = encoded.length - countOffset - 4;
      final count = countAboveBound(remaining);

      expect(
        () => XdrContractCostParams.fromBase64EncodedXdrString(
          base64Encode(patchInt(encoded, countOffset, count)),
        ),
        throwsCountRejected(count, remaining),
      );
    });

    test('contract instance storage count beyond the remaining bytes', () {
      final instance = XdrSCContractInstance(XdrContractExecutable.forAsset(), [
        XdrSCMapEntry(XdrSCVal.forSymbol('key'), XdrSCVal.forU32(1)),
      ]);
      final encoded = base64Decode(instance.toBase64EncodedXdrString());
      // The executable type (a stellar asset executable has no body) and the
      // storage presence flag precede the storage count.
      const countOffset = 8;
      expect(
        readIntAt(encoded, 0),
        equals(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET.value,
        ),
      );
      expect(readIntAt(encoded, 4), equals(1));
      expect(readIntAt(encoded, countOffset), equals(1));
      final remaining = encoded.length - countOffset - 4;
      final count = countAboveBound(remaining);

      expect(
        () => XdrSCContractInstance.fromBase64EncodedXdrString(
          base64Encode(patchInt(encoded, countOffset, count)),
        ),
        throwsCountRejected(count, remaining),
      );
    });

    test('transaction result count without any elements', () {
      final encoded = successResultBytes();
      // The fee charged (8) and the result code precede the operation
      // results count.
      const countOffset = 12;
      expect(
        readIntAt(encoded, 8),
        equals(XdrTransactionResultCode.txSUCCESS.value),
      );
      expect(readIntAt(encoded, countOffset), equals(0));
      // A count of 0x40000000 and nothing after it: 16 bytes in total.
      final hostile = patchInt(
        Uint8List.sublistView(encoded, 0, countOffset + 4),
        countOffset,
        0x40000000,
      );
      expect(hostile.length, equals(16));

      expect(
        () => XdrTransactionResult.fromBase64EncodedXdrString(
          base64Encode(hostile),
        ),
        throwsCountRejected(0x40000000, 0),
      );
    });

    test('transaction result count beyond the remaining bytes', () {
      final encoded = successResultBytes();
      // The fee charged (8) and the result code precede the operation
      // results count; the extension (v0) follows it.
      const countOffset = 12;
      expect(
        readIntAt(encoded, 8),
        equals(XdrTransactionResultCode.txSUCCESS.value),
      );
      expect(readIntAt(encoded, countOffset), equals(0));
      final remaining = encoded.length - countOffset - 4;
      expect(remaining, equals(4));
      final count = countAboveBound(remaining);

      expect(
        () => XdrTransactionResult.fromBase64EncodedXdrString(
          base64Encode(patchInt(encoded, countOffset, count)),
        ),
        throwsCountRejected(count, remaining),
      );
    });

    test('SCV_VEC count beyond the remaining bytes', () {
      final vector = scValVecCountVector();
      final remaining = vector.bytes.length - vector.countOffset - 4;
      final count = countAboveBound(remaining);

      expect(
        () => XdrSCVal.fromBase64EncodedXdrString(
          base64Encode(patchInt(vector.bytes, vector.countOffset, count)),
        ),
        throwsCountRejected(count, remaining),
      );
    });

    test('SCV_VEC negative count', () {
      final vector = scValVecCountVector();

      expect(
        () => XdrSCVal.fromBase64EncodedXdrString(
          base64Encode(patchInt(vector.bytes, vector.countOffset, -1)),
        ),
        throwsNegativeCount(-1),
      );
    });
  });

  group('Union discriminants without a matching arm', () {
    test('fee bump extension with an int discriminant without an arm', () {
      final encoded = feeBumpEnvelopeBytes();
      // The fee bump extension and the empty outer signature list end the
      // envelope.
      final extOffset = encoded.length - 8;
      expect(readIntAt(encoded, extOffset), equals(0));
      expect(readIntAt(encoded, extOffset + 4), equals(0));

      expect(
        () => XdrTransactionEnvelope.fromEnvelopeXdrString(
          base64Encode(patchInt(encoded, extOffset, 1)),
        ),
        throwsUnknownDiscriminant('XdrFeeBumpTransactionExt', 1),
      );
    });

    test('fee bump inner transaction of type ENVELOPE_TYPE_TX_V0', () {
      final encoded = feeBumpEnvelopeBytes();
      // Envelope type, fee source (4 + 32) and fee (8) precede the inner
      // transaction type.
      const innerTypeOffset = 48;
      expect(
        readIntAt(encoded, innerTypeOffset),
        equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value),
      );
      // ENVELOPE_TYPE_TX_V0 is a valid envelope type without an arm in the
      // fee bump inner transaction union.
      final patched = patchInt(
        encoded,
        innerTypeOffset,
        XdrEnvelopeType.ENVELOPE_TYPE_TX_V0.value,
      );

      expect(
        () =>
            XdrTransactionEnvelope.fromEnvelopeXdrString(base64Encode(patched)),
        throwsUnknownDiscriminant(
          'XdrFeeBumpTransactionInnerTx',
          XdrEnvelopeType.ENVELOPE_TYPE_TX_V0.value,
        ),
      );
    });

    test('allow trust asset of type ASSET_TYPE_NATIVE', () {
      final transaction =
          TransactionBuilder(
                Account(KeyPair.random().accountId, BigInt.from(123)),
              )
              .addOperation(
                // ignore: deprecated_member_use_from_same_package
                AllowTrustOperationBuilder(
                  KeyPair.random().accountId,
                  'ABC',
                  1,
                ).build(),
              )
              .build();
      final encoded = base64Decode(transaction.toEnvelopeXdrBase64());
      // Envelope type, source account (4 + 32), fee, sequence number (8),
      // preconditions, memo, operation count, operation source flag,
      // operation type and trustor (4 + 32) precede the asset.
      const assetTypeOffset = 108;
      expect(
        readIntAt(encoded, assetTypeOffset),
        equals(XdrAssetType.ASSET_TYPE_CREDIT_ALPHANUM4.value),
      );
      expect(
        encoded.sublist(assetTypeOffset + 4, assetTypeOffset + 8),
        equals(utf8.encode('ABC') + [0]),
      );
      // ASSET_TYPE_NATIVE is a valid asset type without an arm in the allow
      // trust asset union.
      final patched = patchInt(
        encoded,
        assetTypeOffset,
        XdrAssetType.ASSET_TYPE_NATIVE.value,
      );

      expect(
        () =>
            XdrTransactionEnvelope.fromEnvelopeXdrString(base64Encode(patched)),
        throwsUnknownDiscriminant(
          'XdrAllowTrustOpAsset',
          XdrAssetType.ASSET_TYPE_NATIVE.value,
        ),
      );
    });
  });

  group('Void arms sharing their case with other codes', () {
    test('transaction result txBAD_AUTH', () {
      final result = XdrTransactionResult(
        XdrInt64(BigInt.from(100)),
        XdrTransactionResultResult(XdrTransactionResultCode.txBAD_AUTH),
        XdrTransactionResultExt(0),
      );

      final decoded = XdrTransactionResult.fromBase64EncodedXdrString(
        result.toBase64EncodedXdrString(),
      );

      expect(
        decoded.result.discriminant,
        equals(XdrTransactionResultCode.txBAD_AUTH),
      );
      expect(decoded.result.results, isNull);
      expect(decoded.ext.discriminant, equals(0));
    });

    test('fee bump inner transaction result txTOO_EARLY', () {
      final outer = XdrTransactionResultResult(
        XdrTransactionResultCode.txFEE_BUMP_INNER_FAILED,
      );
      outer.innerResultPair = XdrInnerTransactionResultPair(
        XdrHash(Uint8List.fromList(List<int>.filled(32, 0xAB))),
        XdrInnerTransactionResult(
          XdrInt64(BigInt.from(100)),
          XdrInnerTransactionResultResult(XdrTransactionResultCode.txTOO_EARLY),
          XdrTransactionResultExt(0),
        ),
      );
      final result = XdrTransactionResult(
        XdrInt64(BigInt.from(200)),
        outer,
        XdrTransactionResultExt(0),
      );

      final decoded = XdrTransactionResult.fromBase64EncodedXdrString(
        result.toBase64EncodedXdrString(),
      );

      final inner = decoded.result.innerResultPair!.result;
      expect(
        inner.result.discriminant,
        equals(XdrTransactionResultCode.txTOO_EARLY),
      );
      expect(inner.ext.discriminant, equals(0));
      expect(decoded.ext.discriminant, equals(0));
    });

    test(
      'contract spec type SC_SPEC_TYPE_BOOL through the wrapper decoder',
      () {
        final encoded = base64Decode(
          XdrSCSpecTypeDef.forBool().toBase64EncodedXdrString(),
        );
        final input = XdrDataInputStream(encoded);

        final decoded = XdrSCSpecTypeDef.decode(input);

        expect(decoded.discriminant, equals(XdrSCSpecType.SC_SPEC_TYPE_BOOL));
        expect(input.offset, equals(encoded.length));
      },
    );
  });
}

Uint8List bytes(List<int> values) => Uint8List.fromList(values);

/// A four-byte [count] followed by [remaining] zero bytes.
Uint8List withCount(int count, int remaining) {
  final result = Uint8List(4 + remaining);
  ByteData.sublistView(result).setInt32(0, count);
  return result;
}

int readIntAt(Uint8List encoded, int offset) =>
    ByteData.sublistView(encoded).getInt32(offset);

/// A copy of [encoded] with the four bytes at [offset] replaced by [value].
Uint8List patchInt(Uint8List encoded, int offset, int value) {
  final patched = Uint8List.fromList(encoded);
  ByteData.sublistView(patched).setInt32(offset, value);
  return patched;
}

/// The smallest count above a quarter of the remaining bytes. It does not
/// exceed the remaining bytes, so only the 4-byte element bound rejects it.
int countAboveBound(int remaining) {
  final count = remaining ~/ 4 + 1;
  expect(count, lessThanOrEqualTo(remaining));
  return count;
}

class CountVector {
  CountVector(this.bytes, this.countOffset);

  final Uint8List bytes;
  final int countOffset;
}

Transaction paymentTransaction() =>
    TransactionBuilder(Account(KeyPair.random().accountId, BigInt.from(123)))
        .addOperation(
          PaymentOperationBuilder(
            KeyPair.random().accountId,
            Asset.NATIVE,
            '10',
          ).build(),
        )
        .build();

/// A one-operation transaction envelope and the offset of its operation
/// count.
CountVector transactionOperationsCountVector() {
  final encoded = base64Decode(paymentTransaction().toEnvelopeXdrBase64());
  // Envelope type, source account (4 + 32), fee, sequence number (8),
  // preconditions and memo precede the operation count.
  const countOffset = 60;
  expect(readIntAt(encoded, 0), equals(XdrEnvelopeType.ENVELOPE_TYPE_TX.value));
  expect(
    readIntAt(encoded, countOffset - 8),
    equals(XdrPreconditionType.PRECOND_NONE.value),
  );
  expect(
    readIntAt(encoded, countOffset - 4),
    equals(XdrMemoType.MEMO_NONE.value),
  );
  expect(readIntAt(encoded, countOffset), equals(1));
  return CountVector(encoded, countOffset);
}

/// A one-element SCV_VEC value and the offset of its element count.
CountVector scValVecCountVector() {
  final encoded = base64Decode(
    XdrSCVal.forVec([XdrSCVal.forU32(1)]).toBase64EncodedXdrString(),
  );
  // The value type and the vec presence flag precede the vec count.
  const countOffset = 8;
  expect(readIntAt(encoded, 0), equals(XdrSCValType.SCV_VEC.value));
  expect(readIntAt(encoded, 4), equals(1));
  expect(readIntAt(encoded, countOffset), equals(1));
  return CountVector(encoded, countOffset);
}

/// A txSUCCESS transaction result with no operation results.
Uint8List successResultBytes() {
  final result = XdrTransactionResultResult(XdrTransactionResultCode.txSUCCESS);
  result.results = [];
  return base64Decode(
    XdrTransactionResult(
      XdrInt64(BigInt.from(100)),
      result,
      XdrTransactionResultExt(0),
    ).toBase64EncodedXdrString(),
  );
}

Uint8List feeBumpEnvelopeBytes() {
  final feeBump = FeeBumpTransactionBuilder(
    paymentTransaction(),
  ).setBaseFee(200).setFeeAccount(KeyPair.random().accountId).build();
  return base64Decode(feeBump.toEnvelopeXdrBase64());
}

Matcher throwsNegativeCount(int count) => throwsA(
  isA<RangeError>().having(
    (e) => e.message,
    'message',
    'XDR array count cannot be negative, got $count',
  ),
);

/// Expects the array count diagnostic for [count] and the [remaining] bytes
/// after it.
Matcher throwsCountRejected(int count, int remaining) => throwsA(
  isA<RangeError>().having(
    (e) => e.message,
    'message',
    'XDR array count $count exceeds the maximum of ${remaining ~/ 4} '
        'for the $remaining remaining bytes',
  ),
);

Matcher throwsUnknownDiscriminant(String typeName, int value) => throwsA(
  isA<Exception>().having(
    (e) => e.toString(),
    'toString',
    'Exception: Unknown $typeName discriminant: $value',
  ),
);
