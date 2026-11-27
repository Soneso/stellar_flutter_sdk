// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Decoding requires an optional's presence flag to be 0 or 1, no bytes after
// a single value and no input ending inside padding. Readers that take values
// from the front of longer input keep reading it, and two public network
// envelopes decode and re-encode to their bytes and hashes.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Fee bump envelopes from the public network, envelope_xdr of
// https://horizon.stellar.org/transactions/<hash>.
const _horizonEnvelopes = {
  'b48ed2676e987cd2a258e0d1cd0c03e1819c881d51d6959d67c7f78cfc8ddf43':
      'AAAABQAAAABIlh0MBJIUGNXtFAE1GZwbvIkLVkJ/W68qOzeIr59BJgAAAAAARKomAAAAAgAAAABK6mxmjpjABEUqazC64ZyiLoQy7GDw6goaYiEQXS22yAAAAGYDjzwLAAAa3gAAAAIAAAABAAAAAGr0nrUAAAAAav3GdQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAQAAAABIlh0MBJIUGNXtFAE1GZwbvIkLVkJ/W68qOzeIr59BJgAAAAIAAAABeVhMTQAAAAAiNtdw/g0+AVIZddXPesSEK3CV1rGp12jT6aYy6ZkGvgAAAAAAfZrFAAAAAEiWHQwEkhQY1e0UATUZnBu8iQtWQn9bryo7N4ivn0EmAAAAAAAAAAAAfZrFAAAAAgAAAAJ5VVNEQwAAAAAAAAAAAAAAzTraTOMNLk/59bkX2cI5NI9EZRILk0tjcD212hOLctkAAAABODE4AAAAAABAIAF6Dwmw6EUjhz1on4+tyZ7dD+D00TcQUv9Oyl8zHwAAAAAAAAACXS22yAAAAEDE12V7ZD+VZbtu9ywJGuf0MHVCr6DQikZX71x8wyIILGFRTqRPl1RpOWslOUrl+0EzwVkNjgf+vR9MLs4v7bEAr59BJgAAAEAszqFD3DAyKRTHMzYjmVAfIgeRqHqbZB0SeRUZXRx0UHePsRoyEofhxmVv/P3NmjpJVFWwLqSUjNS5YRs4vlsLAAAAAAAAAAo0pSUjAAAAQOihtln5QjzQgMtf+slCJsPpVFuRs+ji0ldM1++pWYrbMO8xm+wEliLxlPjeUcvM7/r1/T22rFtF/tIk2NNZSQ4fHArWAAAAAXUAAACSGkiBAAAAAXgAAADe+2SjAAAAATgAAABbk/bwAAAAAWwAAAAptJ/OAAAAATMAAAA8mv4pAAAAAWcAAADVnACdAAAAAWIAAAAn+1fpAAAAATAAAADsE6s1AAAAATIAAAA=',
  '34b6b29f3ea2ab77ace0b0a244b297cdcedd5434d1bd1b356636d7c54c2070cc':
      'AAAABQAAAABUBHORC+f3jADZQhru3jYxfSaTxjqXU8ckOHWA5NnKVgAAAAAAAYagAAAAAgAAAAB5hARY7qEOi72+I+T0ZzCQasTD9QawKBk2clAF7wDrSgAAAG4D3COQAAAAAgAAAAEAAAAAAAAAAAAAAABq+TiaAAAAAAAAAAEAAAAAAAAAAQAAAQAFHyABifkSWShEFCztAl8+nLogu9LkT7yeDUhww6rYIoR8vO5Rl55qAAAAAAAAAAAEQoqQAAAAAAAAAAHvAOtKAAAAQIS+M6f2STQ6JUR5jrOJiFqPkj6q7K+cUhuHkh7BXzOMGw8+mWkhoaYNqnzheOEYZJ1vlvMe/7AuGiXtFC2HagMAAAAAAAAAAeTZylYAAABAV+9/NGjQeP5GvF4QNmGl4sOWfVy8ijw8roBnFsCtpFxuXGtrR6jAfyYRIY+EoxU5Uz0CM+zogESxhI8tPBAZDw==',
};

void main() {
  final accountId = KeyPair.random().accountId;
  final bump = BumpSequenceOperationBuilder(BigInt.one).build();

  /// An unsigned one-operation envelope and the offset of the operation's
  /// presence flag, before the operation, extension and signature count.
  (Uint8List, int) envelopeWith(Operation op) {
    final envelope = base64Decode(
      TransactionBuilder(
        Account(accountId, BigInt.one),
      ).addOperation(op).build().toEnvelopeXdrBase64(),
    );
    final opBytes = _encoded((s) => XdrOperation.encode(s, op.toXdr()));
    return (envelope, envelope.length - 8 - opBytes.length);
  }

  group('optional presence flag', () {
    final name = [0, 0, 0, 1, 0x6B, 0, 0, 0];
    final value = [0, 0, 0, 1, 0x61, 0, 0, 0];
    XdrManageDataOp manageData(List<int> flag, [List<int> rest = const []]) =>
        XdrManageDataOp.decode(
          XdrDataInputStream(Uint8List.fromList([...name, ...flag, ...rest])),
        );

    test('0 and 1 decode through a generated type and an envelope', () {
      expect(manageData([0, 0, 0, 0]).dataValue, isNull);
      expect(manageData([0, 0, 0, 1], value).dataValue!.dataValue, [0x61]);
      final withSource = BumpSequenceOperationBuilder(
        BigInt.one,
      ).setSourceAccount(accountId).build();
      for (final (op, flag) in [(bump, 0), (withSource, 1)]) {
        final (envelope, offset) = envelopeWith(op);
        expect(envelope.sublist(offset, offset + 4), _int32(flag));
        final decoded = XdrTransactionEnvelope.fromBase64EncodedXdrString(
          base64Encode(envelope),
        );
        expect(decoded.v1!.tx.operations[0].sourceAccount != null, flag == 1);
      }
    });

    for (final flag in [2, -1, 0x7FFFFFFF]) {
      test('$flag throws through a generated type and an envelope', () {
        final error = _throws(
          'XDR optional presence flag must be 0 or 1, got $flag',
        );
        expect(() => manageData(_int32(flag), value), error);
        final (envelope, offset) = envelopeWith(bump);
        envelope.setRange(offset, offset + 4, _int32(flag));
        expect(
          () => XdrTransactionEnvelope.fromBase64EncodedXdrString(
            base64Encode(envelope),
          ),
          error,
        );
      });
    }
  });

  group('bytes after a single value', () {
    final (envelope, _) = envelopeWith(bump);
    for (final tail in [
      [0, 0, 0, 0],
      [0xFF, 0xFF, 0xFF, 0xFF],
      [0],
    ]) {
      test('an envelope followed by $tail throws', () {
        final input = base64Encode([...envelope, ...tail]);
        final error = _throws(
          '${tail.length} of ${envelope.length + tail.length} bytes remain '
          'after the decoded XDR value',
        );
        expect(() => AbstractTransaction.fromEnvelopeXdrString(input), error);
        expect(
          () => XdrTransactionEnvelope.fromBase64EncodedXdrString(input),
          error,
        );
      });
    }

    final singleValues = <String, (String, Object Function(String))>{
      'XdrMemo MEMO_NONE': (
        XdrMemo(XdrMemoType.MEMO_NONE).toBase64EncodedXdrString(),
        XdrMemo.fromBase64EncodedXdrString,
      ),
      'XdrLedgerKey': (
        XdrLedgerKey.forAccountId(accountId).toBase64EncodedXdrString(),
        XdrLedgerKey.fromBase64EncodedXdrString,
      ),
      'XdrMuxedContract': (
        XdrMuxedContract(
          XdrUint64(BigInt.one),
          XdrHash(Uint8List(32)),
        ).toBase64EncodedXdrString(),
        XdrMuxedContract.fromBase64EncodedXdrString,
      ),
      'XdrSCVal': (
        XdrSCVal.forU32(1).toBase64EncodedXdrString(),
        XdrSCVal.fromBase64EncodedXdrString,
      ),
      'SorobanAuthorizationEntry': (
        SorobanAuthorizationEntry(
          SorobanCredentials.forSourceAccount(),
          SorobanAuthorizedInvocation(
            SorobanAuthorizedFunction.forContractFunction(
              Address.forAccountId(accountId),
              'f',
              [],
            ),
          ),
        ).toBase64EncodedXdrString(),
        SorobanAuthorizationEntry.fromBase64EncodedXdr,
      ),
      'Footprint': (
        Footprint(XdrLedgerFootprint([], [])).toBase64EncodedXdrString(),
        Footprint.fromBase64EncodedXdrString,
      ),
    };
    singleValues.forEach((label, entry) {
      final (encoded, decode) = entry;
      test('$label decodes alone and throws with four bytes after it', () {
        final bytes = base64Decode(encoded);
        expect(() => decode(encoded), returnsNormally);
        expect(
          () => decode(base64Encode([...bytes, 0, 0, 0, 0])),
          _throws(
            '4 of ${bytes.length + 4} bytes remain after the decoded XDR '
            'value',
          ),
        );
      });
    });

    test('contract challenge entries throw with bytes after them', () {
      final webAuth = WebAuthForContracts(
        'https://testanchor.stellar.org/auth',
        'CABC1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDE',
        'GBSERVER1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ12345',
        'testanchor.stellar.org',
        Network.TESTNET,
      );
      expect(webAuth.decodeAuthorizationEntries('AAAAAA=='), isEmpty);
      expect(
        () => webAuth.decodeAuthorizationEntries('AAAAAAAAAAA='),
        throwsA(
          isA<ContractChallengeValidationException>().having(
            (e) => e.message,
            'message',
            'Failed to decode authorization entries: '
                'Exception: 4 of 8 bytes remain after the decoded XDR value',
          ),
        ),
      );
    });

    test('the contract parser reads entries followed by more bytes', () {
      final envMeta =
          XdrSCEnvMetaEntry(XdrSCEnvMetaKind.SC_ENV_META_KIND_INTERFACE_VERSION)
            ..interfaceVersion = XdrSCEnvMetaEntryInterfaceVersion(
              XdrUint32(23),
              XdrUint32(0),
            );
      final meta = XdrSCMetaEntry(XdrSCMetaKind.SC_META_V0)
        ..v0 = XdrSCMetaV0('k', 'v');
      final spec = XdrSCSpecEntry(XdrSCSpecEntryKind.SC_SPEC_ENTRY_FUNCTION_V0)
        ..functionV0 = XdrSCSpecFunctionV0('', 'f', [], []);
      final tail = utf8.encode('tail');
      final parts = [
        (
          'contractenvmetav0',
          _encoded((s) => XdrSCEnvMetaEntry.encode(s, envMeta)),
        ),
        ('contractmetav0', _encoded((s) => XdrSCMetaEntry.encode(s, meta))),
        ('contractspecv0', _encoded((s) => XdrSCSpecEntry.encode(s, spec))),
      ];
      // Each entry fills a wasm custom section that another section follows.
      List<int> section(String name, List<int> content) {
        final payload = [name.length, ...utf8.encode(name), ...content];
        return [0, payload.length, ...payload];
      }

      final info = SorobanContractParser.parseContractByteCode(
        Uint8List.fromList([
          ...[0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00],
          for (final (name, entry) in parts) ...[
            ...section(name, entry),
            ...section('tail', tail),
          ],
        ]),
      );
      expect(info.envProtocolVersion, 23);
      expect(info.metaEntries, {'k': 'v'});
      expect(info.specEntries.single.functionV0!.name, 'f');
      expect(SACClient.specEntries(), hasLength(30));
      // The same entries behind bare markers, without wasm framing.
      final markersOnly = [
        for (final (name, entry) in parts) ...[
          ...utf8.encode(name),
          ...entry,
          ...tail,
        ],
      ];
      expect(
        () => SorobanContractParser.parseContractByteCode(
          Uint8List.fromList(markersOnly),
        ),
        throwsA(
          isA<SorobanContractParserFailed>().having(
            (e) => e.toString(),
            'message',
            'invalid byte code: the wasm magic at byte offset 0 is 636f6e74, '
                'expected 0061736d.',
          ),
        ),
      );
    });
  });

  test('MEMO_TEXT "abc" decodes with its padding byte and throws without', () {
    final abc = [0, 0, 0, 1, 0, 0, 0, 3, 0x61, 0x62, 0x63];
    final memo = XdrMemo.fromBase64EncodedXdrString(base64Encode([...abc, 0]));
    expect(memo.text, 'abc');
    expect(
      () => XdrMemo.fromBase64EncodedXdrString(base64Encode(abc)),
      _throws('XDR input ends inside padding at offset 11'),
    );
  });

  _horizonEnvelopes.forEach((hash, envelope) {
    test('envelope $hash decodes and re-encodes to its bytes and hash', () {
      final decoded = XdrTransactionEnvelope.fromBase64EncodedXdrString(
        envelope,
      );
      expect(decoded.toBase64EncodedXdrString(), envelope);
      final payload = XdrTransactionSignaturePayload(
        XdrHash(Network.PUBLIC.networkId),
        XdrTransactionSignaturePayloadTaggedTransaction(
          XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP,
        )..feeBump = decoded.feeBump!.tx,
      );
      final signatureBase = _encoded(
        (s) => XdrTransactionSignaturePayload.encode(s, payload),
      );
      expect(Util.bytesToHex(Util.hash(signatureBase)), hash);
    });
  });
}

Uint8List _encoded(void Function(XdrDataOutputStream stream) write) {
  final stream = XdrDataOutputStream();
  write(stream);
  return Uint8List.fromList(stream.bytes);
}

List<int> _int32(int value) =>
    (ByteData(4)..setInt32(0, value)).buffer.asUint8List();

Matcher _throws(String message) => throwsA(
  isA<Exception>().having((e) => e.toString(), 'text', 'Exception: $message'),
);
