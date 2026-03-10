// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Core Types - Edge Cases', () {
    test('XdrMemo MEMO_TEXT with empty string', () {
      var original = XdrMemo(XdrMemoType.MEMO_TEXT);
      original.text = '';

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.text, equals(''));
    });

    test('XdrMemo MEMO_ID with max uint64', () {
      var original = XdrMemo(XdrMemoType.MEMO_ID);
      original.id = XdrUint64(BigInt.parse('18446744073709551615'));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMemo.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMemo.decode(input);

      expect(decoded.id!.uint64, equals(original.id!.uint64));
    });

    test('XdrTransaction with large sequence number', () {
      var sourceAccount = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      sourceAccount.ed25519 = XdrUint256(Uint8List.fromList(List<int>.filled(32, 0x01)));

      var fee = XdrUint32(100);
      var seqNum = XdrSequenceNumber(BigInt.parse('9223372036854775807'));
      var cond = XdrPreconditions(XdrPreconditionType.PRECOND_NONE);
      var memo = XdrMemo(XdrMemoType.MEMO_NONE);
      var operations = <XdrOperation>[];
      var ext = XdrTransactionExt(0);

      var original = XdrTransaction(sourceAccount, fee, seqNum, cond, memo, operations, ext);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrTransaction.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrTransaction.decode(input);

      expect(decoded.seqNum.sequenceNumber, equals(BigInt.parse('9223372036854775807')));
    });

    test('XdrMuxedAccountMed25519 with max uint64 id', () {
      var original = XdrMuxedAccountMed25519(
        XdrUint64(BigInt.parse('18446744073709551615')),
        XdrUint256(Uint8List.fromList(List<int>.filled(32, 0xFF)))
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrMuxedAccountMed25519.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrMuxedAccountMed25519.decode(input);

      expect(decoded.id.uint64, equals(BigInt.parse('18446744073709551615')));
      expect(decoded.ed25519.uint256, equals(original.ed25519.uint256));
    });

    test('XdrSequenceNumber with zero', () {
      var original = XdrSequenceNumber(BigInt.zero);

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSequenceNumber.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSequenceNumber.decode(input);

      expect(decoded.sequenceNumber, equals(BigInt.zero));
    });

    test('XdrSequenceNumber with max value', () {
      var original = XdrSequenceNumber(BigInt.parse('9223372036854775807'));

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrSequenceNumber.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrSequenceNumber.decode(input);

      expect(decoded.sequenceNumber, equals(BigInt.parse('9223372036854775807')));
    });

    test('XdrInt64 with negative and boundary values', () {
      final values = [
        BigInt.zero,
        BigInt.from(1),
        BigInt.from(-1),
        BigInt.parse('9223372036854775807'),
        BigInt.parse('-9223372036854775808'),
      ];

      for (var value in values) {
        var original = XdrInt64(value);

        XdrDataOutputStream output = XdrDataOutputStream();
        XdrInt64.encode(output, original);
        Uint8List encoded = Uint8List.fromList(output.bytes);

        XdrDataInputStream input = XdrDataInputStream(encoded);
        var decoded = XdrInt64.decode(input);

        expect(decoded.int64, equals(value));
      }
    });
  });

  group('XDR Core Types - Error Paths & Value Verification', () {
    test('XdrOperationType value mapping verification', () {
      expect(XdrOperationType.CREATE_ACCOUNT.value, equals(0));
      expect(XdrOperationType.PAYMENT.value, equals(1));
      expect(XdrOperationType.PATH_PAYMENT_STRICT_RECEIVE.value, equals(2));
      expect(XdrOperationType.MANAGE_SELL_OFFER.value, equals(3));
      expect(XdrOperationType.CREATE_PASSIVE_SELL_OFFER.value, equals(4));
      expect(XdrOperationType.SET_OPTIONS.value, equals(5));
      expect(XdrOperationType.CHANGE_TRUST.value, equals(6));
      expect(XdrOperationType.ALLOW_TRUST.value, equals(7));
      expect(XdrOperationType.ACCOUNT_MERGE.value, equals(8));
      expect(XdrOperationType.INFLATION.value, equals(9));
      expect(XdrOperationType.MANAGE_DATA.value, equals(10));
      expect(XdrOperationType.BUMP_SEQUENCE.value, equals(11));
      expect(XdrOperationType.MANAGE_BUY_OFFER.value, equals(12));
      expect(XdrOperationType.PATH_PAYMENT_STRICT_SEND.value, equals(13));
      expect(XdrOperationType.CREATE_CLAIMABLE_BALANCE.value, equals(14));
      expect(XdrOperationType.CLAIM_CLAIMABLE_BALANCE.value, equals(15));
      expect(XdrOperationType.BEGIN_SPONSORING_FUTURE_RESERVES.value, equals(16));
      expect(XdrOperationType.END_SPONSORING_FUTURE_RESERVES.value, equals(17));
      expect(XdrOperationType.REVOKE_SPONSORSHIP.value, equals(18));
      expect(XdrOperationType.CLAWBACK.value, equals(19));
      expect(XdrOperationType.CLAWBACK_CLAIMABLE_BALANCE.value, equals(20));
      expect(XdrOperationType.SET_TRUST_LINE_FLAGS.value, equals(21));
      expect(XdrOperationType.LIQUIDITY_POOL_DEPOSIT.value, equals(22));
      expect(XdrOperationType.LIQUIDITY_POOL_WITHDRAW.value, equals(23));
      expect(XdrOperationType.INVOKE_HOST_FUNCTION.value, equals(24));
      expect(XdrOperationType.EXTEND_FOOTPRINT_TTL.value, equals(25));
      expect(XdrOperationType.RESTORE_FOOTPRINT.value, equals(26));
    });

    test('XdrOperationType decode invalid value throws exception', () {
      XdrDataOutputStream output = XdrDataOutputStream();
      output.writeInt(999);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      expect(() => XdrOperationType.decode(input), throwsException);
    });

    test('XdrCryptoKeyType enum values', () {
      expect(XdrCryptoKeyType.KEY_TYPE_ED25519.value, equals(0));
      expect(XdrCryptoKeyType.KEY_TYPE_PRE_AUTH_TX.value, equals(1));
      expect(XdrCryptoKeyType.KEY_TYPE_HASH_X.value, equals(2));
      expect(XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519.value, equals(256));
    });

    test('XdrPreconditionType enum values', () {
      expect(XdrPreconditionType.PRECOND_NONE.value, equals(0));
      expect(XdrPreconditionType.PRECOND_TIME.value, equals(1));
      expect(XdrPreconditionType.PRECOND_V2.value, equals(2));
    });
  });

  group('XDR Core Types - Complex Scenarios', () {
    test('Multiple XdrMemo types encoded/decoded in sequence', () {
      var memos = [
        XdrMemo(XdrMemoType.MEMO_NONE),
        () {
          var m = XdrMemo(XdrMemoType.MEMO_TEXT);
          m.text = 'Test';
          return m;
        }(),
        () {
          var m = XdrMemo(XdrMemoType.MEMO_ID);
          m.id = XdrUint64(BigInt.from(999));
          return m;
        }(),
      ];

      XdrDataOutputStream output = XdrDataOutputStream();
      for (var memo in memos) {
        XdrMemo.encode(output, memo);
      }
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      for (var originalMemo in memos) {
        var decoded = XdrMemo.decode(input);
        expect(decoded.discriminant.value, equals(originalMemo.discriminant.value));
      }
    });
  });
}
