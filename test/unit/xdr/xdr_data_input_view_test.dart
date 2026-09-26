// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Decoding from a Uint8List that is a view on part of a larger buffer. The
// encoded bytes sit at a non-zero offset between filler bytes, and every
// result is compared with the decoding of a fresh copy of the same bytes.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XdrDataInputStream on a view', () {
    test('reads integers, strings and bytes from the view only', () {
      final output = XdrDataOutputStream();
      output.writeInt(-7);
      output.writeString('stellar');
      output.writeBigInt64(BigInt.from(1234567890123));
      final encoded = Uint8List.fromList(output.bytes);
      final view = embed(encoded, before: 12, after: 8);

      final input = XdrDataInputStream(view);

      expect(input.fileLength, equals(encoded.length));
      expect(input.readInt(), equals(-7));
      expect(input.readString(), equals('stellar'));
      expect(input.readBigInt64Signed(), equals(BigInt.from(1234567890123)));
      expect(input.offset, equals(encoded.length));
      expect(
        () => input.readInt(),
        throwsA(isA<RangeError>().having((e) => e.message, 'message',
            'XDR read of 4 bytes exceeds the 0 remaining bytes')),
      );
      expect(
        () => input.readBytes(1),
        throwsA(isA<RangeError>().having((e) => e.message, 'message',
            'XDR byte count 1 exceeds the 0 remaining bytes')),
      );
      expect(input.offset, equals(encoded.length));
    });

    test('decodes a transaction envelope equal to a fresh copy', () {
      final envelope = paymentEnvelope();
      final encoded = base64Decode(envelope.toEnvelopeXdrBase64());
      final view = embed(encoded, before: 20, after: 4);

      final fromView = XdrTransactionEnvelope.decode(XdrDataInputStream(view));
      final fromCopy = XdrTransactionEnvelope.decode(
        XdrDataInputStream(Uint8List.fromList(encoded)),
      );

      expect(
        fromView.toBase64EncodedXdrString(),
        equals(fromCopy.toBase64EncodedXdrString()),
      );
      expect(
        fromView.toBase64EncodedXdrString(),
        equals(envelope.toEnvelopeXdrBase64()),
      );
    });

    test('decodes an SCVal map equal to a fresh copy', () {
      final value = XdrSCVal.forMap([
        XdrSCMapEntry(
          XdrSCVal.forSymbol('amount'),
          XdrSCVal.forI128Parts(BigInt.zero, BigInt.from(5000)),
        ),
        XdrSCMapEntry(
          XdrSCVal.forSymbol('memo'),
          XdrSCVal.forBytes(Uint8List.fromList([1, 2, 3, 4, 5])),
        ),
      ]);
      final encoded = base64Decode(value.toBase64EncodedXdrString());
      final view = embed(encoded, before: 7, after: 3);

      final fromView = XdrSCVal.decode(XdrDataInputStream(view));
      final fromCopy = XdrSCVal.decode(
        XdrDataInputStream(Uint8List.fromList(encoded)),
      );

      expect(
        fromView.toBase64EncodedXdrString(),
        equals(fromCopy.toBase64EncodedXdrString()),
      );
      expect(
        fromView.toBase64EncodedXdrString(),
        equals(value.toBase64EncodedXdrString()),
      );
    });
  });
}

/// A view on [encoded] inside a larger buffer, with [before] bytes of 0xAA
/// ahead of it and [after] bytes of 0xBB behind it.
Uint8List embed(Uint8List encoded, {required int before, required int after}) {
  final buffer = Uint8List(before + encoded.length + after)
    ..fillRange(0, before, 0xAA)
    ..setRange(before, before + encoded.length, encoded)
    ..fillRange(before + encoded.length, before + encoded.length + after, 0xBB);
  final view = Uint8List.sublistView(buffer, before, before + encoded.length);
  expect(view.offsetInBytes, equals(before));
  expect(view.buffer.lengthInBytes, greaterThan(view.lengthInBytes));
  return view;
}

Transaction paymentEnvelope() =>
    TransactionBuilder(Account(KeyPair.random().accountId, BigInt.from(123)))
        .addOperation(
          PaymentOperationBuilder(
            KeyPair.random().accountId,
            Asset.NATIVE,
            '10',
          ).build(),
        )
        .build();
