// Cases shared by transaction_preconditions_exact_test.dart on the Dart VM
// and test/unit/sep/web/transaction_preconditions_exact_web_test.dart in the
// browser, where `int` is a JavaScript number. Expected hashes are computed
// from the input bytes or taken from Horizon, never from the typed model.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// True where `int` is a JavaScript number.
const bool _webInt = identical(0, 0.0);

final BigInt _two53 = BigInt.two.pow(53);
final BigInt _two63 = BigInt.two.pow(63);
final BigInt _two64 = BigInt.two.pow(64);

final Map<String, BigInt> _bounds = {
  '2^53-1': _two53 - BigInt.one,
  '2^53': _two53,
  '2^53+1': _two53 + BigInt.one,
  '2^63-1': _two63 - BigInt.one,
  '2^63': _two63,
  '2^64-1': _two64 - BigInt.one,
};

/// The values of [_bounds] the platform `int` cannot hold exactly.
final Set<String> _notInt = _webInt
    ? {'2^53+1', '2^63-1', '2^64-1'}
    : {'2^63', '2^64-1'};

// Transaction b48ed267 as returned by GET
// https://horizon.stellar.org/transactions/b48ed2676e987cd2a258e0d1cd0c03e1819c881d51d6959d67c7f78cfc8ddf43
// on 2026-11-20 (fields envelope_xdr, hash and inner_transaction.hash).
const String _pubnetEnvelope =
    'AAAABQAAAABIlh0MBJIUGNXtFAE1GZwbvIkLVkJ/W68qOzeIr59BJgAAAAAARKomAAAAAgAAAABK6mxmjpjABEUqazC64ZyiLoQy7GDw6goaYiEQXS22yAAAAGYDjzwLAAAa3gAAAAIAAAABAAAAAGr0nrUAAAAAav3GdQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAQAAAABIlh0MBJIUGNXtFAE1GZwbvIkLVkJ/W68qOzeIr59BJgAAAAIAAAABeVhMTQAAAAAiNtdw/g0+AVIZddXPesSEK3CV1rGp12jT6aYy6ZkGvgAAAAAAfZrFAAAAAEiWHQwEkhQY1e0UATUZnBu8iQtWQn9bryo7N4ivn0EmAAAAAAAAAAAAfZrFAAAAAgAAAAJ5VVNEQwAAAAAAAAAAAAAAzTraTOMNLk/59bkX2cI5NI9EZRILk0tjcD212hOLctkAAAABODE4AAAAAABAIAF6Dwmw6EUjhz1on4+tyZ7dD+D00TcQUv9Oyl8zHwAAAAAAAAACXS22yAAAAEDE12V7ZD+VZbtu9ywJGuf0MHVCr6DQikZX71x8wyIILGFRTqRPl1RpOWslOUrl+0EzwVkNjgf+vR9MLs4v7bEAr59BJgAAAEAszqFD3DAyKRTHMzYjmVAfIgeRqHqbZB0SeRUZXRx0UHePsRoyEofhxmVv/P3NmjpJVFWwLqSUjNS5YRs4vlsLAAAAAAAAAAo0pSUjAAAAQOihtln5QjzQgMtf+slCJsPpVFuRs+ji0ldM1++pWYrbMO8xm+wEliLxlPjeUcvM7/r1/T22rFtF/tIk2NNZSQ4fHArWAAAAAXUAAACSGkiBAAAAAXgAAADe+2SjAAAAATgAAABbk/bwAAAAAWwAAAAptJ/OAAAAATMAAAA8mv4pAAAAAWcAAADVnACdAAAAAWIAAAAn+1fpAAAAATAAAADsE6s1AAAAATIAAAA=';
const String _pubnetHash =
    'b48ed2676e987cd2a258e0d1cd0c03e1819c881d51d6959d67c7f78cfc8ddf43';
const String _pubnetInnerHash =
    '31016eac5454886be362b6abcede10830c3ab8df9cdce445df1d7658000e6793';

String _hex(List<int> bytes) =>
    Util.bytesToHex(Uint8List.fromList(bytes)).toLowerCase();

List<int> _encoded<T>(void Function(XdrDataOutputStream, T) encode, T value) {
  final out = XdrDataOutputStream();
  encode(out, value);
  return out.bytes;
}

/// sha256(network id || envelope type || body) on the testnet.
String _hashOf(int envelopeType, List<int> body) => _hex(
  Util.hash(
    Uint8List.fromList([
      ...Network.TESTNET.networkId,
      0,
      0,
      0,
      envelopeType,
      ...body,
    ]),
  ),
);

XdrTimeBounds _xtb(BigInt min, BigInt max) =>
    XdrTimeBounds(XdrUint64(min), XdrUint64(max));

XdrTimeBounds _window() =>
    _xtb(BigInt.from(1700000000), BigInt.from(1800000000));

XdrPreconditions _time(XdrTimeBounds tb) =>
    XdrPreconditions(XdrPreconditionType.PRECOND_TIME)..timeBounds = tb;

XdrPreconditions _v2({
  XdrTimeBounds? tb,
  XdrLedgerBounds? lb,
  BigInt? minSeqNum,
  BigInt? age,
}) => XdrPreconditions(XdrPreconditionType.PRECOND_V2)
  ..v2 = XdrPreconditionsV2(
    tb,
    lb,
    minSeqNum == null ? null : XdrSequenceNumber(minSeqNum),
    XdrUint64(age ?? BigInt.zero),
    XdrUint32(0),
    [],
  );

final Map<String, XdrPreconditions Function()> _v2Shapes = {
  'V2 with time bounds and minSeqNum 0': () =>
      _v2(tb: _window(), minSeqNum: BigInt.zero),
  'V2 with time bounds and no minSeqNum': () => _v2(tb: _window()),
  'V2 with time bounds and minSeqNum -1': () =>
      _v2(tb: _window(), minSeqNum: BigInt.from(-1)),
  'V2 with every field at its default': () => _v2(),
};

// Controls: shapes the typed model writes back unchanged on master as well.
final Map<String, XdrPreconditions Function()> _controls = {
  'control V2 with ledger bounds': () => _v2(
    lb: XdrLedgerBounds(XdrUint32(1), XdrUint32(2)),
    minSeqNum: BigInt.zero,
  ),
  'control PRECOND_TIME': () => _time(_window()),
  'control PRECOND_NONE': () =>
      XdrPreconditions(XdrPreconditionType.PRECOND_NONE),
};

XdrTransaction _rawTx(XdrPreconditions cond, {KeyPair? source}) {
  final account = (source ?? KeyPair.random()).accountId;
  final tx = TransactionBuilder(Account(account, BigInt.from(100)))
      .addOperation(PaymentOperationBuilder(account, Asset.NATIVE, '1').build())
      .build()
      .toXdr();
  tx.cond = cond;
  return tx;
}

String _v1Base64(XdrTransaction tx) => base64Encode(
  _encoded(
    XdrTransactionEnvelope.encode,
    XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX)
      ..v1 = XdrTransactionV1Envelope(tx, []),
  ),
);

XdrFeeBumpTransaction _feeBumpOf(XdrTransaction inner) => XdrFeeBumpTransaction(
  MuxedAccount.fromAccountId(KeyPair.random().accountId)!.toXdr(),
  XdrInt64(BigInt.from(400)),
  XdrFeeBumpTransactionInnerTx(XdrEnvelopeType.ENVELOPE_TYPE_TX)
    ..v1 = XdrTransactionV1Envelope(inner, []),
  XdrFeeBumpTransactionExt(0),
);

String _feeBumpBase64(XdrFeeBumpTransaction fb) => base64Encode(
  _encoded(
    XdrTransactionEnvelope.encode,
    XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_FEE_BUMP)
      ..feeBump = XdrFeeBumpTransactionEnvelope(fb, []),
  ),
);

/// Parses the V1 envelope of [tx] and checks its hash and its bytes.
void _expectExactV1(XdrTransaction tx) {
  final b64 = _v1Base64(tx);
  final parsed = AbstractTransaction.fromEnvelopeXdrString(b64);
  expect(
    _hex(parsed.hash(Network.TESTNET)),
    _hashOf(2, _encoded(XdrTransaction.encode, tx)),
  );
  expect(parsed.toEnvelopeXdrBase64(), b64);
}

int _arm(TransactionPreconditions p) => p.toXdr().discriminant.value;

void _expectInt(int Function() read, BigInt value, String label, String name) {
  if (_notInt.contains(label)) {
    expect(
      read,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('$value'), contains('${name}BigInt')),
        ),
      ),
    );
  } else {
    expect(BigInt.from(read()), value);
  }
}

/// Registers the cases for the platform the test runs on.
void preconditionsExactCases() {
  test('pubnet b48ed267 keeps its Horizon hashes and its envelope', () {
    final tx =
        AbstractTransaction.fromEnvelopeXdrString(_pubnetEnvelope)
            as FeeBumpTransaction;
    expect(_hex(tx.hash(Network.PUBLIC)), _pubnetHash);
    expect(_hex(tx.innerTransaction.hash(Network.PUBLIC)), _pubnetInnerHash);
    expect(tx.toEnvelopeXdrBase64(), _pubnetEnvelope);
  });

  group('preconditions read from bytes', () {
    for (final shape in {..._v2Shapes, ..._controls}.entries) {
      test('${shape.key} re-encodes and hashes as its bytes', () {
        _expectExactV1(_rawTx(shape.value()));
      });

      test('${shape.key} as a fee bump inner transaction', () {
        final inner = _rawTx(shape.value());
        final fb = _feeBumpOf(inner);
        final b64 = _feeBumpBase64(fb);
        final parsed =
            AbstractTransaction.fromEnvelopeXdrString(b64)
                as FeeBumpTransaction;
        expect(
          _hex(parsed.hash(Network.TESTNET)),
          _hashOf(5, _encoded(XdrFeeBumpTransaction.encode, fb)),
        );
        expect(
          _hex(parsed.innerTransaction.hash(Network.TESTNET)),
          _hashOf(2, _encoded(XdrTransaction.encode, inner)),
        );
        expect(parsed.toEnvelopeXdrBase64(), b64);
      });

      test('${shape.key} keeps its bytes through SEP-11', () {
        final tx = _rawTx(shape.value());
        final b64 = _v1Base64(tx);
        final back = TxRep.transactionEnvelopeXdrBase64FromTxRep(
          TxRep.fromTransactionEnvelopeXdrBase64(b64),
        );
        // Control: SEP-11 works on the XDR types only.
        expect(back, b64);
        final parsed = AbstractTransaction.fromEnvelopeXdrString(back);
        expect(parsed.toEnvelopeXdrBase64(), b64);
        expect(
          _hex(parsed.hash(Network.TESTNET)),
          _hashOf(2, _encoded(XdrTransaction.encode, tx)),
        );
      });
    }

    test('a V0 envelope keeps its V0 body and canonical hash', () {
      final v1 = _rawTx(_time(_window()));
      final v0 = XdrTransactionV0(
        v1.sourceAccount.ed25519!,
        v1.fee,
        v1.seqNum,
        v1.cond.timeBounds,
        v1.memo,
        v1.operations,
        XdrTransactionV0Ext(0),
      );
      final body = _encoded(XdrTransactionV0.encode, v0);
      final b64 = base64Encode(
        _encoded(
          XdrTransactionEnvelope.encode,
          XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX_V0)
            ..v0 = XdrTransactionV0Envelope(v0, []),
        ),
      );
      final parsed =
          AbstractTransaction.fromEnvelopeXdrString(b64) as Transaction;
      expect(_encoded(XdrTransactionV0.encode, parsed.toV0Xdr()), body);
      // KEY_TYPE_ED25519 (0) before the V0 body gives the V1 body.
      expect(
        _hex(parsed.hash(Network.TESTNET)),
        _hashOf(2, [0, 0, 0, 0, ...body]),
      );
    });
  });

  group('precondition arm of built and changed instances', () {
    final none = XdrPreconditionType.PRECOND_NONE.value;
    final time = XdrPreconditionType.PRECOND_TIME.value;
    final v2 = XdrPreconditionType.PRECOND_V2.value;

    test('a minSeqNumber of 0 or -1 is written as PRECOND_V2', () {
      for (final n in [BigInt.zero, BigInt.from(-1)]) {
        final p = TransactionPreconditions()
          ..timeBounds = TimeBounds(1, 2)
          ..minSeqNumber = n;
        final x = p.toXdr();
        expect(x.discriminant.value, v2);
        expect(x.v2!.minSeqNum!.sequenceNumber, n);
        expect(x.v2!.timeBounds!.maxTime.uint64, BigInt.two);
      }
    });

    test('time bounds alone give TIME and nothing gives NONE', () {
      expect(
        _arm(TransactionPreconditions()..timeBounds = TimeBounds(1, 2)),
        time,
      );
      expect(_arm(TransactionPreconditions()), none);
    });

    test('setters after parsing NONE and TIME follow the arm rule', () {
      final p = TransactionPreconditions.fromXdr(
        XdrPreconditions(XdrPreconditionType.PRECOND_NONE),
      );
      p.minSeqNumber = BigInt.zero;
      expect(_arm(p), v2);
      p.minSeqNumber = null;
      expect(_arm(p), none);

      final t = TransactionPreconditions.fromXdr(_time(_window()));
      expect(_arm(t), time);
      t.ledgerBounds = LedgerBounds(1, 2);
      expect(_arm(t), v2);
      t.ledgerBounds = null;
      expect(_arm(t), time);
      t.minSeqAge = 0;
      t.extraSigners = [];
      expect(_arm(t), time);
      t.minSeqAge = 1;
      expect(_arm(t), v2);
      t.minSeqAge = null;
      t.timeBounds = null;
      expect(_arm(t), none);
    });

    test('an instance read as PRECOND_V2 stays V2 after its fields clear', () {
      final p = TransactionPreconditions.fromXdr(
        _v2(tb: _window(), minSeqNum: BigInt.zero),
      );
      p.timeBounds = null;
      p.minSeqNumber = null;
      p.extraSigners = null;
      final x = p.toXdr();
      expect(x.discriminant.value, v2);
      expect(x.v2!.timeBounds, isNull);
      expect(x.v2!.minSeqNum, isNull);
      expect(x.v2!.minSeqAge.uint64, BigInt.zero);
      expect(x.v2!.extraSigners, isEmpty);
    });
  });

  group('SEP-10 challenge with PRECOND_V2', () {
    final server = KeyPair.random();
    final client = KeyPair.random();
    final webAuth = WebAuth(
      'https://auth.example.com/auth',
      Network.TESTNET,
      server.accountId,
      'example.com',
    );

    /// A challenge signed by [server] over the hash of its bytes.
    (String, String) challenge(XdrPreconditions cond) {
      final tx = TransactionBuilder(Account(server.accountId, BigInt.from(-1)))
          .addOperation(
            ManageDataOperationBuilder(
              'example.com auth',
              Uint8List.fromList(utf8.encode('A' * 64)),
            ).setSourceAccount(client.accountId).build(),
          )
          .addOperation(
            ManageDataOperationBuilder(
              'web_auth_domain',
              Uint8List.fromList(utf8.encode('auth.example.com')),
            ).setSourceAccount(server.accountId).build(),
          )
          .build()
          .toXdr();
      tx.cond = cond;
      final hash = _hashOf(2, _encoded(XdrTransaction.encode, tx));
      final signature = server.signDecorated(Util.hexToBytes(hash));
      final env = XdrTransactionEnvelope(XdrEnvelopeType.ENVELOPE_TYPE_TX)
        ..v1 = XdrTransactionV1Envelope(tx, [signature]);
      return (base64Encode(_encoded(XdrTransactionEnvelope.encode, env)), hash);
    }

    test('validates, and the client signature verifies over its hash', () {
      final now = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final (b64, hash) = challenge(
        _v2(
          tb: _xtb(now - BigInt.from(10), now + BigInt.from(300)),
          minSeqNum: BigInt.zero,
        ),
      );
      webAuth.validateChallenge(b64, client.accountId, null);
      final signed = XdrTransactionEnvelope.fromBase64EncodedXdrString(
        webAuth.signTransaction(b64, [client]),
      );
      expect(
        client.verify(
          Util.hexToBytes(hash),
          signed.v1!.signatures.last.signature.signature,
        ),
        isTrue,
      );
    });

    test('accepts a maxTime of 2^64-1 with a grace period', () {
      final now = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final (b64, _) = challenge(
        _v2(tb: _xtb(now - BigInt.from(10), _two64 - BigInt.one)),
      );
      webAuth.validateChallenge(b64, client.accountId, null, 300);
    });
  });

  group('uint64 bounds', () {
    for (final e in _bounds.entries) {
      final v = e.value;
      test('${e.key} is read, written and hashed exactly', () {
        _expectExactV1(_rawTx(_time(_xtb(v, BigInt.zero))));
        _expectExactV1(_rawTx(_time(_xtb(BigInt.zero, v))));
        _expectExactV1(_rawTx(_v2(age: v)));

        final p = TransactionPreconditions.fromXdr(_v2(tb: _xtb(v, v), age: v));
        expect(p.timeBounds!.minTimeBigInt, v);
        expect(p.timeBounds!.maxTimeBigInt, v);
        expect(p.minSeqAgeBigInt, v);
        _expectInt(() => p.timeBounds!.minTime, v, e.key, 'minTime');
        _expectInt(() => p.timeBounds!.maxTime, v, e.key, 'maxTime');
        _expectInt(() => p.minSeqAge!, v, e.key, 'minSeqAge');

        final built =
            TransactionBuilder(
                  Account(KeyPair.random().accountId, BigInt.from(100)),
                )
                .addOperation(
                  BumpSequenceOperationBuilder(BigInt.from(200)).build(),
                )
                .addPreconditions(
                  TransactionPreconditions()
                    ..timeBounds = TimeBounds.fromBigInt(v, v)
                    ..minSeqAgeBigInt = v,
                )
                .build();
        final b64 = built.toEnvelopeXdrBase64();
        final raw = XdrTransactionEnvelope.fromBase64EncodedXdrString(b64);
        final cond = raw.v1!.tx.cond.v2!;
        expect(cond.timeBounds!.minTime.uint64, v);
        expect(cond.timeBounds!.maxTime.uint64, v);
        expect(cond.minSeqAge.uint64, v);
        _expectExactV1(raw.v1!.tx);
        if (!_notInt.contains(e.key)) {
          final i = v.toInt();
          expect(TimeBounds(i, i), TimeBounds.fromBigInt(v, v));
          expect(
            (TransactionPreconditions()..minSeqAge = i).minSeqAgeBigInt,
            v,
          );
        }
      });
    }

    test('values outside 0 to 2^64-1 are refused', () {
      expect(
        () => TimeBounds.fromBigInt(BigInt.zero, _two64),
        throwsA(
          isA<Exception>().having(
            (e) => '$e',
            'message',
            contains('maxTime cannot be greater than ${_two64 - BigInt.one}'),
          ),
        ),
      );
      expect(
        () => TimeBounds.fromBigInt(BigInt.from(-1), BigInt.zero),
        throwsException,
      );
      if (_webInt) {
        expect(() => TimeBounds(0, _two64.toInt()), throwsException);
      }
      final p = TransactionPreconditions();
      expect(() => p.minSeqAgeBigInt = _two64, throwsException);
      expect(() => p.minSeqAge = -1, throwsException);
      expect(p.minSeqAgeBigInt, isNull);
      p.minSeqAge = 5;
      expect(p.minSeqAgeBigInt, BigInt.from(5));
      p.minSeqAge = null;
      expect(p.minSeqAgeBigInt, isNull);
    });

    test('the bounds order is checked on the exact values', () {
      expect(
        () => TimeBounds.fromXdr(_xtb(_two64 - BigInt.one, _two63)),
        throwsException,
      );
      expect(
        () => TimeBounds.fromXdr(_xtb(_two53 + BigInt.one, _two53)),
        throwsException,
      );
    });
  });

  group('consumers of exact values', () {
    test('equal bounds are equal, hash alike and match in a Set', () {
      final max = _two64 - BigInt.one;
      final a = TimeBounds.fromBigInt(max - BigInt.one, max);
      final b = TimeBounds.fromXdr(_xtb(max - BigInt.one, max));
      final c = TimeBounds.fromBigInt(max - BigInt.two, max);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a}.contains(b), isTrue);
      expect(a == c, isFalse);
      expect({TimeBounds(1, 2)}.contains(TimeBounds(1, 2)), isTrue);
    });

    test('expiresAfter adds the timeout exactly', () {
      for (final timeout in [
        300,
        (_webInt ? _two63 : _two63 - BigInt.one).toInt(),
      ]) {
        final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final tb = TimeBounds.expiresAfter(timeout);
        final after = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1;
        final t = BigInt.from(timeout);
        expect(tb.minTimeBigInt, BigInt.zero);
        expect(tb.maxTimeBigInt >= BigInt.from(before) + t, isTrue);
        expect(tb.maxTimeBigInt <= BigInt.from(after) + t, isTrue);
        if (!_webInt && timeout != 300) {
          expect(() => tb.maxTime, throwsStateError);
        }
      }
      if (_webInt) {
        expect(() => TimeBounds.expiresAfter(_two64.toInt()), throwsException);
      }
    });

    test(
      'SEP-7 signAndSubmitTransaction signs a V2 shape over its bytes',
      () async {
        final tx = _rawTx(_v2(tb: _window(), minSeqNum: BigInt.zero));
        final hash = _hashOf(2, _encoded(XdrTransaction.encode, tx));
        final signer = KeyPair.random();
        String? posted;
        final uriScheme = URIScheme(
          httpClient: MockClient((http.Request r) async {
            posted = Uri.decodeComponent(r.body.substring('xdr='.length));
            return http.Response('ok', 200);
          }),
        );
        await uriScheme.signAndSubmitTransaction(
          uriScheme.generateSignTransactionURI(
            _v1Base64(tx),
            callback: 'url:https://wallet.example.com/tx',
          ),
          signer,
          network: Network.TESTNET,
        );
        final env = XdrTransactionEnvelope.fromBase64EncodedXdrString(posted!);
        expect(
          _encoded(XdrTransaction.encode, env.v1!.tx),
          _encoded(XdrTransaction.encode, tx),
        );
        expect(
          signer.verify(
            Util.hexToBytes(hash),
            env.v1!.signatures.single.signature.signature,
          ),
          isTrue,
        );
      },
    );
  });
}
