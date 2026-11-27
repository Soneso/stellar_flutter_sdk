// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// The maxima the XDR definitions declare for arrays, strings and opaque
// values, in binary XDR, XDR-JSON, TxRep and TransactionBuilder. A binary
// vector is the encoding of the value with no elements, with the count and
// the elements written after it by hand.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  final accountId = KeyPair.random().accountId;
  final native = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
  final one = XdrInt64(BigInt.one);
  final bump = BumpSequenceOperationBuilder(BigInt.one).build();
  final operation = bump.toXdr();
  final tx = TransactionBuilder(
    Account(accountId, BigInt.one),
  ).addOperation(bump).build().toXdr();
  final signature = XdrDecoratedSignature(
    XdrSignatureHint(Uint8List(4)),
    XdrSignature(Uint8List(64)),
  );
  final claimant = XdrClaimant(XdrClaimantType.CLAIMANT_TYPE_V0)
    ..v0 = XdrClaimantV0(
      XdrAccountID.forAccountId(accountId),
      XdrClaimPredicate(XdrClaimPredicateType.CLAIM_PREDICATE_UNCONDITIONAL),
    );
  final signerKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519)
    ..ed25519 = XdrUint256(Uint8List(32));
  final boolType = XdrSCSpecTypeDef(XdrSCSpecType.SC_SPEC_TYPE_BOOL);
  const letter = [0x61];

  final cases = <_Bounded<dynamic>>[
    _Bounded<XdrMemo>(
      'memo text',
      28,
      letter,
      (n) => XdrMemo(XdrMemoType.MEMO_TEXT)..text = 'a' * n,
      XdrMemo.encode,
      XdrMemo.decode,
    ),
    _Bounded<XdrTransaction>(
      'transaction operations',
      100,
      _encoded((s) => XdrOperation.encode(s, operation)),
      (n) => XdrTransaction(
        tx.sourceAccount,
        tx.fee,
        tx.seqNum,
        tx.cond,
        tx.memo,
        List.filled(n, operation),
        tx.ext,
      ),
      XdrTransaction.encode,
      XdrTransaction.decode,
      suffixLength: 4,
    ),
    _Bounded<XdrTransactionV1Envelope>(
      'envelope signatures',
      20,
      _encoded((s) => XdrDecoratedSignature.encode(s, signature)),
      (n) => XdrTransactionV1Envelope(tx, List.filled(n, signature)),
      XdrTransactionV1Envelope.encode,
      XdrTransactionV1Envelope.decode,
    ),
    _Bounded<XdrSCVal>(
      'symbol',
      32,
      letter,
      (n) => XdrSCVal.forSymbol('a' * n),
      XdrSCVal.encode,
      XdrSCVal.decode,
    ),
    _Bounded<XdrDataValue>(
      'data value',
      64,
      letter,
      (n) => XdrDataValue(_letters(n)),
      XdrDataValue.encode,
      XdrDataValue.decode,
    ),
    _Bounded<XdrSignedPayload>(
      'signed payload',
      64,
      letter,
      (n) => XdrSignedPayload(
        XdrUint256(Uint8List(32)),
        XdrDataValue(_letters(n)),
      ),
      XdrSignedPayload.encode,
      XdrSignedPayload.decode,
    ),
    _Bounded<XdrSignature>(
      'signature',
      64,
      letter,
      (n) => XdrSignature(_letters(n)),
      XdrSignature.encode,
      XdrSignature.decode,
    ),
    _Bounded<XdrPathPaymentStrictSendOp>(
      'path payment path',
      5,
      _encoded((s) => XdrAsset.encode(s, native)),
      (n) => XdrPathPaymentStrictSendOp(
        native,
        one,
        MuxedAccount.fromAccountId(accountId)!.toXdr(),
        native,
        one,
        List.filled(n, native),
      ),
      XdrPathPaymentStrictSendOp.encode,
      XdrPathPaymentStrictSendOp.decode,
    ),
    _Bounded<XdrCreateClaimableBalanceOp>(
      'claimable balance claimants',
      10,
      _encoded((s) => XdrClaimant.encode(s, claimant)),
      (n) => XdrCreateClaimableBalanceOp(native, one, List.filled(n, claimant)),
      XdrCreateClaimableBalanceOp.encode,
      XdrCreateClaimableBalanceOp.decode,
    ),
    _Bounded<XdrPreconditionsV2>(
      'extra signers',
      2,
      _encoded((s) => XdrSignerKey.encode(s, signerKey)),
      (n) => XdrPreconditionsV2(
        null,
        null,
        null,
        XdrUint64(BigInt.zero),
        XdrUint32(0),
        List.filled(n, signerKey),
      ),
      XdrPreconditionsV2.encode,
      XdrPreconditionsV2.decode,
    ),
    _Bounded<XdrSCSpecFunctionV0>(
      'spec function outputs',
      1,
      _encoded((s) => XdrSCSpecTypeDef.encode(s, boolType)),
      (n) => XdrSCSpecFunctionV0('', 'f', [], List.filled(n, boolType)),
      XdrSCSpecFunctionV0.encode,
      XdrSCSpecFunctionV0.decode,
    ),
  ];
  for (final c in cases) {
    c.register();
  }

  test('XDR-JSON writes and reads a 32-byte symbol and throws for 33', () {
    String json(int length) => '{"symbol":"${'a' * length}"}';
    const prefix = 'FormatException: XDR-JSON XdrSCVal key "symbol"';
    expect(XdrSCVal.forSymbol('a' * 32).toXdrJson(), json(32));
    expect(XdrSCVal.fromXdrJson(json(32)).sym, 'a' * 32);
    expect(
      () => XdrSCVal.fromXdrJson(json(33)),
      _throws<FormatException>(
        '$prefix holds 33 bytes, more than the declared maximum of 32',
      ),
    );
    expect(
      () => XdrSCVal.forSymbol('a' * 33).toXdrJson(),
      _throws<FormatException>(
        '$prefix is 33 bytes, longer than the declared maximum of 32',
      ),
    );
  });

  test('memo text counts UTF-8 bytes: 28 decode and encode, 29 throw', () {
    Uint8List memoBytes(String text) {
      final bytes = utf8.encode(text);
      return Uint8List.fromList([
        ..._int32(XdrMemoType.MEMO_TEXT.value),
        ..._int32(bytes.length),
        ...bytes,
        ...List.filled((4 - bytes.length % 4) % 4, 0),
      ]);
    }

    XdrMemo memo(String text) => XdrMemo(XdrMemoType.MEMO_TEXT)..text = text;
    final fits = 'é' * 14;
    final over = '${'é' * 14}a';
    expect(memoBytes(fits), hasLength(4 + 4 + 28));
    expect(XdrMemo.decode(XdrDataInputStream(memoBytes(fits))).text, fits);
    expect(_encoded((s) => XdrMemo.encode(s, memo(fits))), memoBytes(fits));
    final error = _throws<RangeError>(
      'RangeError: XDR length 29 exceeds the declared maximum of 28',
    );
    expect(() => XdrMemo.decode(XdrDataInputStream(memoBytes(over))), error);
    expect(() => _encoded((s) => XdrMemo.encode(s, memo(over))), error);
  });

  test('a 1,000-byte contract wasm upload round-trips in XDR and TxRep', () {
    final wasm = _letters(1000);
    final envelope = TransactionBuilder(Account(accountId, BigInt.one))
        .addOperation(
          InvokeHostFuncOpBuilder(UploadContractWasmHostFunction(wasm)).build(),
        )
        .build()
        .toEnvelopeXdrBase64();
    final decoded = XdrTransactionEnvelope.fromBase64EncodedXdrString(envelope);
    final op = decoded.v1!.tx.operations[0].body.invokeHostFunctionOp!;
    expect(op.function.wasm!.dataValue, wasm);
    expect(decoded.toBase64EncodedXdrString(), envelope);
    final txRep = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
    expect(TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep), envelope);
  });

  test('TxRep input converts at the maxima and throws above them', () {
    String envelope(Operation op, Memo memo) =>
        (TransactionBuilder(
                Account(accountId, BigInt.one),
              ).addOperation(op).addMemo(memo).build()
              ..sign(KeyPair.random(), Network.TESTNET))
            .toEnvelopeXdrBase64();
    final memo = envelope(bump, Memo.text('a' * 28));
    final data = envelope(
      ManageDataOperationBuilder('k', _letters(64)).build(),
      Memo.none(),
    );
    final sig = Util.bytesToHex(
      XdrTransactionEnvelope.fromBase64EncodedXdrString(
        memo,
      ).v1!.signatures[0].signature.signature,
    );
    final dataKey = 'tx.operations[0].body.manageDataOp.dataValue';
    final cases = [
      (
        memo,
        'text: "${'a' * 28}"',
        'text: "${'a' * 29}"',
        'tx.memo.text',
        29,
        28,
      ),
      (data, '61' * 64, '61' * 65, dataKey, 65, 64),
      (
        memo,
        'operations.len: 1',
        'operations.len: 101',
        'tx.operations.len',
        101,
        100,
      ),
      (
        memo,
        'signatures.len: 1',
        'signatures.len: 21',
        'signatures.len',
        21,
        20,
      ),
      (memo, sig, '${sig}61', 'signatures[0].signature', 65, 64),
    ];
    for (final (input, line, over, key, length, max) in cases) {
      final txRep = TxRep.fromTransactionEnvelopeXdrBase64(input);
      expect(txRep, contains(line), reason: key);
      expect(TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep), input);
      expect(
        () => TxRep.transactionEnvelopeXdrBase64FromTxRep(
          txRep.replaceFirst(line, over),
        ),
        _throws<Exception>(
          'Exception: $key has length $length, more than the declared '
          'maximum of $max',
        ),
        reason: key,
      );
    }
  });

  test('TransactionBuilder builds 100 operations and throws for 101', () {
    final account = Account(accountId, BigInt.from(7));
    final builder = TransactionBuilder(account);
    for (var i = 0; i < 100; i++) {
      builder.addOperation(bump);
    }
    expect(builder.build().operations, hasLength(100));
    expect(account.sequenceNumber, BigInt.from(8));
    builder.addOperation(bump);
    expect(
      () => builder.build(),
      _throws<Exception>(
        'Exception: A transaction holds at most 100 operations, 101 were added',
      ),
    );
    expect(account.sequenceNumber, BigInt.from(8));
  });
}

/// A value whose bounded array, string or opaque value ends its encoding, or
/// is followed only by [suffixLength] bytes.
class _Bounded<T> {
  _Bounded(
    this.name,
    this.max,
    this.element,
    this.build,
    this.encode,
    this.decode, {
    this.suffixLength = 0,
  });

  final String name;
  final int max;

  /// The encoding of one element; one byte for a string or opaque value.
  final List<int> element;
  final T Function(int count) build;
  final void Function(XdrDataOutputStream stream, T value) encode;
  final T Function(XdrDataInputStream stream) decode;
  final int suffixLength;

  Uint8List encoded(T value) => _encoded((s) => encode(s, value));

  Uint8List bytes(int count) {
    final empty = encoded(build(0));
    final end = empty.length - suffixLength;
    final body = [for (var i = 0; i < count; i++) ...element];
    final padding = List.filled((4 - body.length % 4) % 4, 0);
    return Uint8List.fromList([
      ...empty.sublist(0, end - 4),
      ..._int32(count),
      ...body,
      ...padding,
      ...empty.sublist(end),
    ]);
  }

  void register() {
    group('$name, maximum $max', () {
      test('decodes and encodes $max', () {
        final input = bytes(max);
        final stream = XdrDataInputStream(input);
        expect(encoded(decode(stream)), input);
        expect(stream.offset, input.length);
        expect(encoded(build(max)), input);
      });

      test('decode and encode throw a RangeError for ${max + 1}', () {
        final error = _throws<RangeError>(
          'RangeError: XDR length ${max + 1} exceeds the declared maximum of '
          '$max',
        );
        expect(() => decode(XdrDataInputStream(bytes(max + 1))), error);
        expect(() => encoded(build(max + 1)), error);
      });
    });
  }
}

Uint8List _encoded(void Function(XdrDataOutputStream stream) write) {
  final stream = XdrDataOutputStream();
  write(stream);
  return Uint8List.fromList(stream.bytes);
}

Uint8List _letters(int count) => Uint8List.fromList(List.filled(count, 0x61));

List<int> _int32(int value) =>
    (ByteData(4)..setInt32(0, value)).buffer.asUint8List();

Matcher _throws<T>(String text) =>
    throwsA(isA<T>().having((e) => e.toString(), 'text', text));
