// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/src/xdr/txrep_helper.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../secret_seed_variants.dart';

// The XDR schema declares every offer id as an int64. The expected values are
// written from the schema: an int64 is eight big-endian bytes in two's
// complement, and XDR-JSON and TxRep write it as signed decimal text.

const String _seller32 =
    '0000000000000000000000000000000000000000000000000000000000000001';
const String _sellerAccountId =
    'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC6PV';
const String _accountId = '00000000$_seller32';
const String _native = '00000000';
const String _amount = '0000000000000064';
const String _price = '0000000100000002';

const String _min = '-9223372036854775808';
const String _max = '9223372036854775807';

/// The eight bytes of each offer id the tests read or write, by its text.
const Map<String, String> _idBytes = {
  '0': '0000000000000000',
  '16': '0000000000000010',
  '12345': '0000000000003039',
  '-1': 'ffffffffffffffff',
  '-16': 'fffffffffffffff0',
  _max: '7fffffffffffffff',
  _min: '8000000000000000',
};

/// Offer ids outside the int64 range, as XDR-JSON and TxRep text.
const List<String> _outsideInt64 = [
  '9223372036854775808',
  '-9223372036854775809',
];

String _base64(String hex) => base64Encode(Util.hexToBytes(hex));

String _hex(String base64) => Util.bytesToHex(base64Decode(base64));

/// A manage offer operation of 100 stroops of the native asset at price 1/2,
/// by how it is made, with the XDR discriminant of its operation type.
class _OfferOperation {
  const _OfferOperation(this.name, this.type, this.build);

  final String name;
  final String type;
  final Operation Function(String id) build;

  /// The XDR of this operation with offer id [id] and no source account.
  String xdr(String id) =>
      _base64('00000000$type$_native$_native$_amount$_price${_idBytes[id]}');
}

final List<_OfferOperation> _offerOperations = [
  _OfferOperation(
    'ManageSellOfferOperation',
    '00000003',
    (id) => ManageSellOfferOperation(
      Asset.NATIVE,
      Asset.NATIVE,
      '0.00001',
      '0.5',
      id,
    ),
  ),
  _OfferOperation(
    'ManageSellOfferOperationBuilder',
    '00000003',
    (id) => ManageSellOfferOperationBuilder(
      Asset.NATIVE,
      Asset.NATIVE,
      '0.00001',
      '0.5',
    ).setOfferId(id).build(),
  ),
  _OfferOperation(
    'ManageBuyOfferOperation',
    '0000000c',
    (id) => ManageBuyOfferOperation(
      Asset.NATIVE,
      Asset.NATIVE,
      '0.00001',
      '0.5',
      id,
    ),
  ),
  _OfferOperation(
    'ManageBuyOfferOperationBuilder',
    '0000000c',
    (id) => ManageBuyOfferOperationBuilder(
      Asset.NATIVE,
      Asset.NATIVE,
      '0.00001',
      '0.5',
    ).setOfferId(id).build(),
  ),
];

/// The offer id text of a manage offer operation.
String _offerIdOf(Operation operation) => switch (operation) {
  ManageSellOfferOperation(:final offerId) => offerId,
  ManageBuyOfferOperation(:final offerId) => offerId,
  _ => fail('not a manage offer operation: $operation'),
};

/// One of the six types holding an offer id, with its bytes, the XDR-JSON
/// document the schema gives it and its codecs.
class _OfferType {
  const _OfferType(
    this.name,
    this.hex,
    this.document,
    this.toXdrJson,
    this.fromXdrJson,
  );

  final String name;

  /// The bytes of a value with offer id [id].
  final String Function(String id) hex;

  /// The XDR-JSON document of a value with offer id [id].
  final String Function(String id) document;

  /// Reads a value from [bytes] and returns its XDR-JSON document.
  final String Function(Uint8List bytes) toXdrJson;

  /// Reads a value from the XDR-JSON document [json] and returns its bytes in
  /// base64.
  final String Function(String json) fromXdrJson;
}

String _manageOfferHex(String id) =>
    '$_native$_native$_amount$_price${_idBytes[id]}';

String _ledgerKeyOfferHex(String id) => '$_accountId${_idBytes[id]}';

String _offerEntryHex(String id) =>
    '$_accountId${_idBytes[id]}$_native$_native$_amount$_price'
    '0000000000000000';

final List<_OfferType> _offerTypes = [
  _OfferType(
    'XdrManageSellOfferOp',
    _manageOfferHex,
    (id) =>
        '{"selling":"native","buying":"native","amount":"100",'
        '"price":{"n":1,"d":2},"offer_id":"$id"}',
    (bytes) =>
        XdrManageSellOfferOp.decode(XdrDataInputStream(bytes)).toXdrJson(),
    (json) => XdrManageSellOfferOp.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _OfferType(
    'XdrManageBuyOfferOp',
    _manageOfferHex,
    (id) =>
        '{"selling":"native","buying":"native","buy_amount":"100",'
        '"price":{"n":1,"d":2},"offer_id":"$id"}',
    (bytes) =>
        XdrManageBuyOfferOp.decode(XdrDataInputStream(bytes)).toXdrJson(),
    (json) => XdrManageBuyOfferOp.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _OfferType(
    'XdrOfferEntry',
    _offerEntryHex,
    (id) =>
        '{"seller_id":"$_sellerAccountId","offer_id":"$id",'
        '"selling":"native","buying":"native","amount":"100",'
        '"price":{"n":1,"d":2},"flags":0,"ext":"v0"}',
    (bytes) => XdrOfferEntry.decode(XdrDataInputStream(bytes)).toXdrJson(),
    (json) => XdrOfferEntry.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _OfferType(
    'XdrLedgerKeyOffer',
    _ledgerKeyOfferHex,
    (id) => '{"seller_id":"$_sellerAccountId","offer_id":"$id"}',
    (bytes) => XdrLedgerKeyOffer.decode(XdrDataInputStream(bytes)).toXdrJson(),
    (json) => XdrLedgerKeyOffer.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _OfferType(
    'XdrClaimOfferAtom',
    (id) => '$_accountId${_idBytes[id]}$_native$_amount$_native$_amount',
    (id) =>
        '{"seller_id":"$_sellerAccountId","offer_id":"$id",'
        '"asset_sold":"native","amount_sold":"100",'
        '"asset_bought":"native","amount_bought":"100"}',
    (bytes) => XdrClaimOfferAtom.decode(XdrDataInputStream(bytes)).toXdrJson(),
    (json) => XdrClaimOfferAtom.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
  _OfferType(
    'XdrClaimOfferAtomV0',
    (id) => '$_seller32${_idBytes[id]}$_native$_amount$_native$_amount',
    (id) =>
        '{"seller_ed25519":"$_seller32","offer_id":"$id",'
        '"asset_sold":"native","amount_sold":"100",'
        '"asset_bought":"native","amount_bought":"100"}',
    (bytes) =>
        XdrClaimOfferAtomV0.decode(XdrDataInputStream(bytes)).toXdrJson(),
    (json) => XdrClaimOfferAtomV0.fromXdrJson(json).toBase64EncodedXdrString(),
  ),
];

/// One of the three offer id types that have TxRep, with its bytes, the TxRep
/// lines the schema gives it under the prefix `p` and its codecs.
class _TxRepType {
  const _TxRepType(
    this.name,
    this.hex,
    this.lines,
    this.toTxRep,
    this.fromTxRep,
  );

  final String name;

  /// The bytes of a value with offer id [id].
  final String Function(String id) hex;

  /// The TxRep lines of a value with offer id [id].
  final List<String> Function(String id) lines;

  /// Reads a value from [bytes] and adds its TxRep lines to [lines].
  final void Function(Uint8List bytes, List<String> lines) toTxRep;

  /// Reads a value from the TxRep text [txRep] and returns its bytes in
  /// base64.
  final String Function(String txRep) fromTxRep;
}

final List<_TxRepType> _txRepTypes = [
  _TxRepType(
    'XdrManageSellOfferOp',
    _manageOfferHex,
    (id) => [
      'p.selling: XLM',
      'p.buying: XLM',
      'p.amount: 100',
      'p.price.n: 1',
      'p.price.d: 2',
      'p.offerID: $id',
    ],
    (bytes, lines) => XdrManageSellOfferOp.decode(
      XdrDataInputStream(bytes),
    ).toTxRep('p', lines),
    (txRep) => XdrManageSellOfferOp.fromTxRep(
      TxRepHelper.parse(txRep),
      'p',
    ).toBase64EncodedXdrString(),
  ),
  _TxRepType(
    'XdrManageBuyOfferOp',
    _manageOfferHex,
    (id) => [
      'p.selling: XLM',
      'p.buying: XLM',
      'p.buyAmount: 100',
      'p.price.n: 1',
      'p.price.d: 2',
      'p.offerID: $id',
    ],
    (bytes, lines) => XdrManageBuyOfferOp.decode(
      XdrDataInputStream(bytes),
    ).toTxRep('p', lines),
    (txRep) => XdrManageBuyOfferOp.fromTxRep(
      TxRepHelper.parse(txRep),
      'p',
    ).toBase64EncodedXdrString(),
  ),
  _TxRepType(
    'XdrLedgerKeyOffer',
    _ledgerKeyOfferHex,
    (id) => ['p.sellerID: $_sellerAccountId', 'p.offerID: $id'],
    (bytes, lines) =>
        XdrLedgerKeyOffer.decode(XdrDataInputStream(bytes)).toTxRep('p', lines),
    (txRep) => XdrLedgerKeyOffer.fromTxRep(
      TxRepHelper.parse(txRep),
      'p',
    ).toBase64EncodedXdrString(),
  ),
];

/// Checks that the XDR-JSON of [type] with offer id [id] is the document the
/// schema gives it, and that the document reads back to the same bytes.
void _expectXdrJson(_OfferType type, String id) {
  final String hex = type.hex(id);
  expect(type.toXdrJson(Util.hexToBytes(hex)), type.document(id), reason: id);
  expect(_hex(type.fromXdrJson(type.document(id))), hex, reason: id);
}

/// Checks that the TxRep of [type] with offer id [id] is the lines the schema
/// gives it, and that the lines read back to the same bytes.
void _expectTxRep(_TxRepType type, String id) {
  final String hex = type.hex(id);
  final List<String> lines = [];
  type.toTxRep(Util.hexToBytes(hex), lines);
  expect(lines, type.lines(id), reason: id);
  expect(_hex(type.fromTxRep(type.lines(id).join('\n'))), hex, reason: id);
}

/// A transaction from the account [_sellerAccountId] with fee 300 and sequence
/// number 1 that manages a sell offer with id -16, a buy offer with id -2^63
/// and revokes the sponsorship of the offer with id -16, without signatures.
const String _transactionHex =
    '00000002'
    '00000000$_seller32'
    '0000012c'
    '0000000000000001'
    '00000000'
    '00000000'
    '00000003'
    '00000000'
    '00000003'
    '$_native$_native$_amount${_price}fffffffffffffff0'
    '00000000'
    '0000000c'
    '$_native$_native$_amount${_price}8000000000000000'
    '00000000'
    '00000012'
    '00000000'
    '00000002'
    '${_accountId}fffffffffffffff0'
    '00000000';

void main() {
  group('offer id text of the manage offer operations', () {
    test('refuses text that is not decimal int64 text', () {
      const List<String> texts = [
        '0x10',
        ' 16 ',
        '+16',
        '-0',
        '016',
        '',
        '1.0',
      ];
      for (final _OfferOperation operation in _offerOperations) {
        for (final String text in texts) {
          expect(
            () => operation.build(text).toOperationBody(),
            throwsA(
              isA<FormatException>()
                  .having(
                    (e) => e.message,
                    'message',
                    'An offer id is decimal int64 text',
                  )
                  .having((e) => e.source, 'source', text),
            ),
            reason: '${operation.name} "$text"',
          );
        }
      }
    });

    test('refuses a value outside the int64 range', () {
      const List<String> texts = [
        '9223372036854775808',
        '18446744073709551615',
        '-9223372036854775809',
      ];
      for (final _OfferOperation operation in _offerOperations) {
        for (final String text in texts) {
          expect(
            () => operation.build(text).toOperationBody(),
            throwsA(
              isA<FormatException>()
                  .having(
                    (e) => e.message,
                    'message',
                    'An offer id is outside the int64 range',
                  )
                  .having((e) => e.source, 'source', text),
            ),
            reason: '${operation.name} "$text"',
          );
        }
      }
    });

    test('a secret seed passed to a constructor never appears in the '
        'exception', () {
      final SeedVariants variants = SeedVariants();
      final List<_OfferOperation> constructors = _offerOperations
          .where((operation) => !operation.name.endsWith('Builder'))
          .toList();
      for (final _OfferOperation operation in constructors) {
        for (final MapEntry(key: name, value: value) in variants.all.entries) {
          expect(
            () => operation.build(value).toOperationBody(),
            throwsA(
              isA<FormatException>()
                  .having(
                    (e) => e.message,
                    'message',
                    'An offer id is decimal int64 text',
                  )
                  .having((e) => e.source, 'source', variants.keyWording(value))
                  .having((e) => e.toString(), 'text', leavesOut(value)),
            ),
            reason: '${operation.name} $name',
          );
        }
      }
    });

    test('accepts decimal int64 text and writes its eight bytes', () {
      for (final _OfferOperation operation in _offerOperations) {
        for (final String id in ['0', '16', '-16', _max, _min]) {
          expect(
            operation.build(id).toXdrBase64(),
            operation.xdr(id),
            reason: '${operation.name} "$id"',
          );
        }
      }
    });
  });

  group('manage offer operations read from XDR', () {
    test('rebuild to the same bytes and hold the signed offer id text', () {
      final List<_OfferOperation> kinds = [
        _offerOperations[0],
        _offerOperations[2],
      ];
      for (final _OfferOperation kind in kinds) {
        for (final String id in ['-16', '0', _max, _min]) {
          final String xdr = kind.xdr(id);
          final Operation operation = Operation.fromXdr(
            XdrOperation.fromBase64EncodedXdrString(xdr),
          );
          expect(_offerIdOf(operation), id, reason: '${kind.name} $id');
          expect(operation.toXdrBase64(), xdr, reason: '${kind.name} $id');
        }
      }
    });
  });

  group('XDR-JSON of the six offer id types', () {
    for (final _OfferType type in _offerTypes) {
      test('${type.name} writes and reads a signed offer id', () {
        for (final String id in ['-16', '-1', _min, _max]) {
          _expectXdrJson(type, id);
        }
      });

      test('${type.name} refuses an offer id outside the int64 range', () {
        for (final String id in _outsideInt64) {
          expect(
            () => type.fromXdrJson(type.document(id)),
            throwsFormatException,
            reason: id,
          );
        }
      });
    }
  });

  group('TxRep of the three offer id types that have it', () {
    for (final _TxRepType type in _txRepTypes) {
      test('${type.name} writes and reads a signed offer id', () {
        for (final String id in ['-16', _min, _max]) {
          _expectTxRep(type, id);
        }
      });

      test('${type.name} refuses an offer id outside the int64 range', () {
        for (final String id in _outsideInt64) {
          expect(
            () => type.fromTxRep(type.lines(id).join('\n')),
            throwsFormatException,
            reason: id,
          );
        }
      });
    }
  });

  group('a transaction envelope with negative offer ids', () {
    const String envelopeHex = '${_transactionHex}00000000';

    test('TxRep writes the signed offer ids and reads back the same '
        'envelope', () {
      final String envelope = _base64(envelopeHex);
      final String txRep = TxRep.fromTransactionEnvelopeXdrBase64(envelope);

      expect(
        txRep.split('\n'),
        containsAll(<String>[
          'tx.operations[0].body.manageSellOfferOp.offerID: -16',
          'tx.operations[1].body.manageBuyOfferOp.offerID: $_min',
          'tx.operations[2].body.revokeSponsorshipOp.ledgerKey.offer.offerID: '
              '-16',
        ]),
      );
      expect(TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep), envelope);
    });

    test('SEP-7 signs and sends the same transaction', () async {
      String? sentBody;
      final MockClient client = MockClient((request) async {
        sentBody = request.body;
        return http.Response('{}', 200);
      });
      final URIScheme uriScheme = URIScheme(httpClient: client);
      final String url = uriScheme.generateSignTransactionURI(
        _base64(envelopeHex),
        callback: 'url:https://example.com/callback',
      );

      await uriScheme.signAndSubmitTransaction(
        url,
        KeyPair.random(),
        network: Network.TESTNET,
      );

      expect(sentBody, startsWith('xdr='));
      final String sentHex = _hex(
        Uri.decodeComponent(sentBody!.substring('xdr='.length)),
      );
      // A signed envelope is the transaction followed by one signature.
      expect(sentHex.substring(0, _transactionHex.length), _transactionHex);
      expect(
        sentHex.substring(_transactionHex.length, _transactionHex.length + 8),
        '00000001',
      );
    });
  });

  group('offer id getters', () {
    test('XdrLedgerKey.getOfferOfferId returns a negative offer id', () {
      for (final MapEntry(key: id, value: expected) in {
        '-16': -16,
        '-1': -1,
      }.entries) {
        final XdrLedgerKey key = XdrLedgerKey.fromBase64EncodedXdrString(
          _base64('00000002${_ledgerKeyOfferHex(id)}'),
        );
        expect(key.getOfferOfferId(), expected, reason: id);
      }
    });

    test('SubmitTransactionResponse.getOfferIdFromResult returns a negative '
        'offer id', () {
      // A successful transaction with fee 100 whose one manage sell offer
      // operation created the offer with id -16.
      final String resultXdr = _base64(
        '0000000000000064'
        '00000000'
        '00000001'
        '00000000'
        '00000003'
        '00000000'
        '00000000'
        '00000000'
        '${_offerEntryHex('-16')}'
        '00000000',
      );
      final SubmitTransactionResponse response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        resultXdr,
        'AAAA',
        'AAAA',
        null,
      );

      expect(response.getOfferIdFromResult(0), -16);
    });
  });

  group('offer ledger keys made from an int offer id', () {
    test('write a negative offer id as signed XDR-JSON and read it back', () {
      final String offerHex = _ledgerKeyOfferHex('-16');
      final String offerDocument =
          '{"seller_id":"$_sellerAccountId","offer_id":"-16"}';
      final String keyHex = '00000002$offerHex';
      final String keyDocument = '{"offer":$offerDocument}';

      final XdrLedgerKeyOffer offer = XdrLedgerKeyOffer.forOfferId(
        _sellerAccountId,
        -16,
      );
      expect(offer.toXdrJson(), offerDocument);
      expect(_hex(offer.toBase64EncodedXdrString()), offerHex);
      expect(
        _hex(
          XdrLedgerKeyOffer.fromXdrJson(
            offerDocument,
          ).toBase64EncodedXdrString(),
        ),
        offerHex,
      );

      final Map<String, XdrLedgerKey> keys = {
        'XdrLedgerKey.forOffer': XdrLedgerKey.forOffer(_sellerAccountId, -16),
        'revokeOfferSponsorship': RevokeSponsorshipOperationBuilder()
            .revokeOfferSponsorship(_sellerAccountId, -16)
            .build()
            .ledgerKey!,
      };
      for (final MapEntry(key: name, value: key) in keys.entries) {
        expect(key.toXdrJson(), keyDocument, reason: name);
        expect(_hex(key.toBase64EncodedXdrString()), keyHex, reason: name);
      }
      expect(
        _hex(XdrLedgerKey.fromXdrJson(keyDocument).toBase64EncodedXdrString()),
        keyHex,
      );
    });
  });

  group('controls', () {
    test('offer ids 0 and 12345 keep their bytes, XDR-JSON and TxRep', () {
      for (final String id in ['0', '12345']) {
        for (final _OfferOperation operation in _offerOperations) {
          expect(
            operation.build(id).toXdrBase64(),
            operation.xdr(id),
            reason: '${operation.name} "$id"',
          );
        }
        for (final _OfferType type in _offerTypes) {
          _expectXdrJson(type, id);
        }
        for (final _TxRepType type in _txRepTypes) {
          _expectTxRep(type, id);
        }
      }
    });

    test(
      'XdrTimeBounds keeps its unsigned XDR-JSON and TxRep above 2^63-1',
      () {
        const String hex = '8000000000000000ffffffffffffffff';
        const String document =
            '{"min_time":"9223372036854775808",'
            '"max_time":"18446744073709551615"}';
        const List<String> lines = [
          'p.minTime: 9223372036854775808',
          'p.maxTime: 18446744073709551615',
        ];
        final XdrTimeBounds bounds = XdrTimeBounds.decode(
          XdrDataInputStream(Util.hexToBytes(hex)),
        );

        expect(bounds.toXdrJson(), document);
        expect(
          _hex(XdrTimeBounds.fromXdrJson(document).toBase64EncodedXdrString()),
          hex,
        );
        final List<String> written = [];
        bounds.toTxRep('p', written);
        expect(written, lines);
        expect(
          _hex(
            XdrTimeBounds.fromTxRep(
              TxRepHelper.parse(lines.join('\n')),
              'p',
            ).toBase64EncodedXdrString(),
          ),
          hex,
        );
        expect(
          () => XdrTimeBounds.fromXdrJson('{"min_time":"-1","max_time":"0"}'),
          throwsFormatException,
        );
      },
    );
  });

  group('the offerID setters of the six offer id types', () {
    // Each entry reads a value from its bytes, sets [offerId] through the
    // setter and returns the bytes of the result in base64.
    final Map<String, String Function(Uint8List bytes, XdrInt64 offerId)>
    setters = {
      'XdrManageSellOfferOp': (bytes, offerId) => (XdrManageSellOfferOp.decode(
        XdrDataInputStream(bytes),
      )..offerID = offerId).toBase64EncodedXdrString(),
      'XdrManageBuyOfferOp': (bytes, offerId) => (XdrManageBuyOfferOp.decode(
        XdrDataInputStream(bytes),
      )..offerID = offerId).toBase64EncodedXdrString(),
      'XdrOfferEntry': (bytes, offerId) => (XdrOfferEntry.decode(
        XdrDataInputStream(bytes),
      )..offerID = offerId).toBase64EncodedXdrString(),
      'XdrLedgerKeyOffer': (bytes, offerId) => (XdrLedgerKeyOffer.decode(
        XdrDataInputStream(bytes),
      )..offerID = offerId).toBase64EncodedXdrString(),
      'XdrClaimOfferAtom': (bytes, offerId) => (XdrClaimOfferAtom.decode(
        XdrDataInputStream(bytes),
      )..offerID = offerId).toBase64EncodedXdrString(),
      'XdrClaimOfferAtomV0': (bytes, offerId) => (XdrClaimOfferAtomV0.decode(
        XdrDataInputStream(bytes),
      )..offerID = offerId).toBase64EncodedXdrString(),
    };

    test('setting a negative offer id writes its signed bytes', () {
      for (final _OfferType type in _offerTypes) {
        final String encoded = setters[type.name]!(
          Util.hexToBytes(type.hex('0')),
          XdrInt64(BigInt.from(-16)),
        );
        expect(_hex(encoded), type.hex('-16'), reason: type.name);
      }
    });
  });
}
