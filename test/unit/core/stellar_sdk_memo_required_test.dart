// Tests for the SEP-29 memo-required check. A transaction without a memo
// must not be submitted when a payment, path payment or account merge
// operation names a non-multiplexed destination whose `config.memo_required`
// data entry is `1`. The check looks each distinct destination up once, in
// operation order, stops at the first hit, skips destinations Horizon does not
// know, and makes no request at all when the transaction carries a memo. Every
// case asserts the exact list of HTTP requests the SDK sent.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String memoRequiredKey = 'config.memo_required';

/// An [AbstractTransaction] that is neither a [Transaction] nor a
/// [FeeBumpTransaction]. The check must not touch any of its members.
class _OtherTransaction extends AbstractTransaction {
  @override
  Uint8List signatureBase(Network network) {
    throw UnimplementedError();
  }

  @override
  XdrTransactionEnvelope toEnvelopeXdr() {
    throw UnimplementedError();
  }
}

http.Response accountBody(String accountId, {Map<String, String>? data}) {
  Map<String, dynamic> encodedData = <String, dynamic>{};
  if (data != null) {
    data.forEach((key, value) {
      encodedData[key] = base64Encode(utf8.encode(value));
    });
  }
  final body = {
    'account_id': accountId,
    'sequence': '123456789012345',
    'paging_token': '123456789012345',
    'subentry_count': 0,
    'last_modified_ledger': 987654,
    'last_modified_time': '2024-01-15T10:30:00Z',
    'thresholds': {'low_threshold': 0, 'med_threshold': 0, 'high_threshold': 0},
    'flags': {
      'auth_required': false,
      'auth_revocable': false,
      'auth_immutable': false,
      'auth_clawback_enabled': false,
    },
    'balances': [
      {
        'asset_type': 'native',
        'balance': '1000.0000000',
        'buying_liabilities': '0.0000000',
        'selling_liabilities': '0.0000000',
      },
    ],
    'signers': [
      {'key': accountId, 'type': 'ed25519_public_key', 'weight': 1},
    ],
    'data': encodedData,
    '_links': {
      'effects': {'href': '/accounts/$accountId/effects'},
      'offers': {'href': '/accounts/$accountId/offers'},
      'operations': {'href': '/accounts/$accountId/operations'},
      'self': {'href': '/accounts/$accountId'},
      'transactions': {'href': '/accounts/$accountId/transactions'},
      'payments': {'href': '/accounts/$accountId/payments'},
      'trades': {'href': '/accounts/$accountId/trades'},
      'data': {'href': '/accounts/$accountId/data/{key}', 'templated': true},
    },
    'num_sponsoring': 0,
    'num_sponsored': 0,
  };
  return http.Response(json.encode(body), 200);
}

http.Response Function() flagged(String accountId) =>
    () => accountBody(accountId, data: {memoRequiredKey: '1'});

http.Response Function() unflagged(String accountId) =>
    () => accountBody(accountId, data: {'other.key': '1'});

http.Response Function() flaggedWith(String accountId, String value) =>
    () => accountBody(accountId, data: {memoRequiredKey: value});

http.Response Function() notFound() =>
    () => http.Response('Not found', 404);

http.Response Function() forbidden() =>
    () => http.Response('Forbidden', 403);

http.Response Function() rateLimited() =>
    () =>
        http.Response('Too many requests', 429, headers: {'retry-after': '10'});

http.Response submitSuccessBody() {
  final successJson = {
    'hash': 'abc123def456',
    'ledger': 12345,
    'envelope_xdr': 'AAAAAgAAAAA=',
    'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
    'result_meta_xdr': 'AAAAAwAAAAA=',
    'successful': true,
    'id': 'abc123def456',
    'paging_token': '12345-1',
    'source_account':
        'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
    'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
    'source_account_sequence': 100,
    'max_fee': 1000,
    'fee_charged': 100,
    'operation_count': 1,
    'created_at': '2024-01-15T10:30:00Z',
    'fee_meta_xdr': 'AAAAAgAAAAA=',
    'memo_type': 'none',
    'signatures': [],
    '_links': {
      'self': {'href': '/transactions/abc123def456'},
    },
  };
  return http.Response(json.encode(successJson), 200);
}

http.Response submitAsyncPendingBody() {
  final asyncJson = {
    'tx_status': 'PENDING',
    'hash': 'async123',
    'error_result_xdr': null,
  };
  return http.Response(json.encode(asyncJson), 201);
}

/// Returns an SDK whose HTTP client appends `'<METHOD> <path>'` of every
/// request to [requests], appends the `tx` form field of every POST to
/// [posted] when given, and answers account lookups from [accounts].
StellarSDK sdkWith({
  required Map<String, http.Response Function()> accounts,
  required List<String> requests,
  List<String>? posted,
}) {
  final mockClient = MockClient((request) async {
    requests.add('${request.method} ${request.url.path}');
    if (request.method == 'POST' && posted != null) {
      posted.add(request.bodyFields['tx']!);
    }
    final segments = request.url.pathSegments;
    if (request.method == 'GET' &&
        segments.length == 2 &&
        segments[0] == 'accounts') {
      final respond = accounts[segments[1]];
      if (respond == null) {
        fail('unexpected account lookup: ${segments[1]}');
      }
      return respond();
    }
    if (request.method == 'POST' && request.url.path == '/transactions') {
      return submitSuccessBody();
    }
    if (request.method == 'POST' && request.url.path == '/transactions_async') {
      return submitAsyncPendingBody();
    }
    fail('unexpected request: ${request.method} ${request.url}');
  });
  final sdk = StellarSDK('https://horizon-testnet.stellar.org');
  sdk.httpClient = mockClient;
  return sdk;
}

Matcher memoRequired(String accountId, int operationIndex) {
  return isA<AccountRequiresMemoException>()
      .having((e) => e.accountId, 'accountId', accountId)
      .having((e) => e.operationIndex, 'operationIndex', operationIndex)
      .having(
        (e) => e.toString(),
        'toString()',
        'Destination account $accountId of operation $operationIndex '
            'requires a memo in the transaction.',
      );
}

void main() {
  late KeyPair sourceKeyPair;
  late KeyPair feeKeyPair;
  late String dest;
  late String a;
  late String b;
  late String c;
  late List<String> requests;
  late List<String> posted;

  setUp(() {
    sourceKeyPair = KeyPair.random();
    feeKeyPair = KeyPair.random();
    dest = KeyPair.random().accountId;
    a = KeyPair.random().accountId;
    b = KeyPair.random().accountId;
    c = KeyPair.random().accountId;
    requests = <String>[];
    posted = <String>[];
  });

  Transaction buildTx(List<Operation> operations, {Memo? memo}) {
    TransactionBuilder builder = TransactionBuilder(
      Account(sourceKeyPair.accountId, BigInt.from(123)),
    );
    for (Operation operation in operations) {
      builder.addOperation(operation);
    }
    if (memo != null) {
      builder.addMemo(memo);
    }
    Transaction transaction = builder.build();
    transaction.sign(sourceKeyPair, Network.TESTNET);
    return transaction;
  }

  FeeBumpTransaction feeBump(Transaction inner) {
    FeeBumpTransaction transaction = FeeBumpTransactionBuilder(
      inner,
    ).setBaseFee(200).setFeeAccount(feeKeyPair.accountId).build();
    transaction.sign(feeKeyPair, Network.TESTNET);
    return transaction;
  }

  Operation payment(String destination) =>
      PaymentOperationBuilder(destination, Asset.NATIVE, '10').build();

  Operation mergeInto(String destination) =>
      AccountMergeOperationBuilder(destination).build();

  Operation createAccount(String destination) =>
      CreateAccountOperationBuilder(destination, '10').build();

  Operation strictSend(String destination) =>
      PathPaymentStrictSendOperationBuilder(
        Asset.NATIVE,
        '10',
        destination,
        Asset.NATIVE,
        '9',
      ).build();

  Operation strictReceive(String destination) =>
      PathPaymentStrictReceiveOperationBuilder(
        Asset.NATIVE,
        '10',
        destination,
        Asset.NATIVE,
        '9',
      ).build();

  Operation mux(String destination, BigInt id) =>
      PaymentOperationBuilder.forMuxedDestinationAccount(
        MuxedAccount(destination, id),
        Asset.NATIVE,
        '10',
      ).build();

  group('submitTransaction', () {
    test('throws when a destination requires a memo', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitTransaction(buildTx([payment(dest)])),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('submits when no destination requires a memo', () async {
      final sdk = sdkWith(
        accounts: {dest: unflagged(dest)},
        requests: requests,
      );
      final response = await sdk.submitTransaction(buildTx([payment(dest)]));
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$dest', 'POST /transactions']);
    });

    test('submits when the entry holds a value other than 1', () async {
      final sdk = sdkWith(
        accounts: {dest: flaggedWith(dest, '0')},
        requests: requests,
      );
      final response = await sdk.submitTransaction(buildTx([payment(dest)]));
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$dest', 'POST /transactions']);
    });

    test('compares the decoded value exactly', () async {
      final sdk = sdkWith(
        accounts: {dest: flaggedWith(dest, '1 ')},
        requests: requests,
      );
      final response = await sdk.submitTransaction(buildTx([payment(dest)]));
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$dest', 'POST /transactions']);
    });

    test('skips the check when asked', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([payment(dest)]),
        skipMemoRequiredCheck: true,
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('makes no lookup when a text memo is present', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([payment(dest)], memo: MemoText('hello')),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('makes no lookup when an id memo is present', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([payment(dest)], memo: MemoId(BigInt.one)),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('makes no lookup when a hash memo is present', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([payment(dest)], memo: MemoHash(Uint8List(32))),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('makes no lookup when a return hash memo is present', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([payment(dest)], memo: MemoReturnHash(Uint8List(32))),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('treats an explicit MemoNone as no memo', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitTransaction(buildTx([payment(dest)], memo: MemoNone())),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('makes no lookup without destination operations', () async {
      final sdk = sdkWith(accounts: {}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([createAccount(dest)]),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('reports the index of the offending operation', () async {
      final n = KeyPair.random().accountId;
      final sdk = sdkWith(
        accounts: {a: unflagged(a), b: flagged(b)},
        requests: requests,
      );
      await expectLater(
        sdk.submitTransaction(
          buildTx([payment(a), createAccount(n), payment(b)]),
        ),
        throwsA(memoRequired(b, 2)),
      );
      expect(requests, ['GET /accounts/$a', 'GET /accounts/$b']);
    });

    test('checks every qualifying operation type', () async {
      final sdk = sdkWith(
        accounts: {a: unflagged(a), b: unflagged(b), c: flagged(c)},
        requests: requests,
      );
      await expectLater(
        sdk.submitTransaction(
          buildTx([strictSend(a), strictReceive(b), mergeInto(c)]),
        ),
        throwsA(memoRequired(c, 2)),
      );
      expect(requests, [
        'GET /accounts/$a',
        'GET /accounts/$b',
        'GET /accounts/$c',
      ]);
    });

    test('stops at the first destination that requires a memo', () async {
      final sdk = sdkWith(
        accounts: {a: flagged(a), b: unflagged(b), c: flagged(c)},
        requests: requests,
      );
      await expectLater(
        sdk.submitTransaction(
          buildTx([strictSend(a), strictReceive(b), mergeInto(c)]),
        ),
        throwsA(memoRequired(a, 0)),
      );
      expect(requests, ['GET /accounts/$a']);
    });

    test('detects a flagged strict receive destination', () async {
      final sdk = sdkWith(
        accounts: {a: unflagged(a), b: flagged(b)},
        requests: requests,
      );
      await expectLater(
        sdk.submitTransaction(buildTx([strictSend(a), strictReceive(b)])),
        throwsA(memoRequired(b, 1)),
      );
      expect(requests, ['GET /accounts/$a', 'GET /accounts/$b']);
    });

    test('queries a repeated destination once', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitTransaction(buildTx([payment(dest), payment(dest)])),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('queries a repeated unflagged destination once', () async {
      final sdk = sdkWith(
        accounts: {dest: unflagged(dest)},
        requests: requests,
      );
      final response = await sdk.submitTransaction(
        buildTx([payment(dest), strictSend(dest), mergeInto(dest)]),
      );
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$dest', 'POST /transactions']);
    });

    test('skips muxed destinations', () async {
      final sdk = sdkWith(accounts: {}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([mux(dest, BigInt.zero), mux(dest, BigInt.from(1234))]),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('skips muxed path payment and merge destinations', () async {
      final muxed = MuxedAccount(dest, BigInt.from(7));
      final sdk = sdkWith(accounts: {}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([
          PathPaymentStrictSendOperationBuilder.forMuxedDestinationAccount(
            Asset.NATIVE,
            '10',
            muxed,
            Asset.NATIVE,
            '9',
          ).build(),
          PathPaymentStrictReceiveOperationBuilder.forMuxedDestinationAccount(
            Asset.NATIVE,
            '10',
            muxed,
            Asset.NATIVE,
            '9',
          ).build(),
          AccountMergeOperationBuilder.forMuxedDestinationAccount(
            muxed,
          ).build(),
        ]),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('skips a muxed M-address given as a string destination', () async {
      final mAddress = MuxedAccount(dest, BigInt.from(99)).accountId;
      expect(mAddress.startsWith('M'), isTrue);
      final sdk = sdkWith(accounts: {}, requests: requests);
      final response = await sdk.submitTransaction(
        buildTx([payment(mAddress)]),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test(
      'reports the first non-muxed operation that names the account',
      () async {
        final sdk = sdkWith(
          accounts: {dest: flagged(dest)},
          requests: requests,
        );
        await expectLater(
          sdk.submitTransaction(
            buildTx([mux(dest, BigInt.from(7)), payment(dest)]),
          ),
          throwsA(memoRequired(dest, 1)),
        );
        expect(requests, ['GET /accounts/$dest']);
      },
    );

    test('skips a destination Horizon does not know', () async {
      final sdk = sdkWith(accounts: {dest: notFound()}, requests: requests);
      final response = await sdk.submitTransaction(buildTx([payment(dest)]));
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$dest', 'POST /transactions']);
    });

    test('continues after a destination Horizon does not know', () async {
      final sdk = sdkWith(
        accounts: {a: notFound(), b: flagged(b)},
        requests: requests,
      );
      await expectLater(
        sdk.submitTransaction(buildTx([payment(a), payment(b)])),
        throwsA(memoRequired(b, 1)),
      );
      expect(requests, ['GET /accounts/$a', 'GET /accounts/$b']);
    });

    test('propagates other lookup errors', () async {
      final sdk = sdkWith(accounts: {dest: forbidden()}, requests: requests);
      await expectLater(
        sdk.submitTransaction(buildTx([payment(dest)])),
        throwsA(isA<ErrorResponse>().having((e) => e.code, 'code', 403)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('propagates a rate limited lookup', () async {
      final sdk = sdkWith(accounts: {dest: rateLimited()}, requests: requests);
      await expectLater(
        sdk.submitTransaction(buildTx([payment(dest)])),
        throwsA(
          isA<TooManyRequestsException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            10,
          ),
        ),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('propagates a lookup error after an earlier lookup', () async {
      final sdk = sdkWith(
        accounts: {a: unflagged(a), b: forbidden(), c: flagged(c)},
        requests: requests,
      );
      await expectLater(
        sdk.submitTransaction(buildTx([payment(a), payment(b), payment(c)])),
        throwsA(isA<ErrorResponse>().having((e) => e.code, 'code', 403)),
      );
      expect(requests, ['GET /accounts/$a', 'GET /accounts/$b']);
    });
  });

  group('submitFeeBumpTransaction', () {
    test('checks the inner transaction', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitFeeBumpTransaction(feeBump(buildTx([payment(dest)]))),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('submits after one lookup per destination', () async {
      final sdk = sdkWith(
        accounts: {dest: unflagged(dest)},
        requests: requests,
      );
      final response = await sdk.submitFeeBumpTransaction(
        feeBump(buildTx([payment(dest)])),
      );
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$dest', 'POST /transactions']);
    });

    test('submits when the inner transaction carries a memo', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitFeeBumpTransaction(
        feeBump(buildTx([payment(dest)], memo: MemoText('hello'))),
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    test('skips the check when asked', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitFeeBumpTransaction(
        feeBump(buildTx([payment(dest)])),
        skipMemoRequiredCheck: true,
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });
  });

  group('submitAsyncTransaction', () {
    test('throws when a destination requires a memo', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitAsyncTransaction(buildTx([payment(dest)])),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('submits after one lookup per destination', () async {
      final sdk = sdkWith(
        accounts: {dest: unflagged(dest)},
        requests: requests,
      );
      final response = await sdk.submitAsyncTransaction(
        buildTx([payment(dest)]),
      );
      expect(response.txStatus, 'PENDING');
      expect(requests, ['GET /accounts/$dest', 'POST /transactions_async']);
    });

    test('skips the check when asked', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitAsyncTransaction(
        buildTx([payment(dest)]),
        skipMemoRequiredCheck: true,
      );
      expect(response.txStatus, 'PENDING');
      expect(requests, ['POST /transactions_async']);
    });
  });

  group('submitAsyncFeeBumpTransaction', () {
    test('throws when a destination requires a memo', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitAsyncFeeBumpTransaction(feeBump(buildTx([payment(dest)]))),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('submits after one lookup per destination', () async {
      final sdk = sdkWith(
        accounts: {dest: unflagged(dest)},
        requests: requests,
      );
      final response = await sdk.submitAsyncFeeBumpTransaction(
        feeBump(buildTx([payment(dest)])),
      );
      expect(response.txStatus, 'PENDING');
      expect(requests, ['GET /accounts/$dest', 'POST /transactions_async']);
    });

    test('skips the check when asked', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitAsyncFeeBumpTransaction(
        feeBump(buildTx([payment(dest)])),
        skipMemoRequiredCheck: true,
      );
      expect(response.txStatus, 'PENDING');
      expect(requests, ['POST /transactions_async']);
    });
  });

  final undecodableEnvelopes = <String, String Function()>{
    'invalid base64': () => 'not*base64',
    'unknown envelope type': () => base64Encode(utf8.encode('garbage')),
    'truncated bytes': () => base64Encode([0, 0, 0]),
  };

  group('submitTransactionEnvelopeXdrBase64', () {
    test('throws when a destination requires a memo', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitTransactionEnvelopeXdrBase64(
          buildTx([payment(dest)]).toEnvelopeXdrBase64(),
        ),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('submits after one lookup per destination', () async {
      final sdk = sdkWith(
        accounts: {dest: unflagged(dest)},
        requests: requests,
      );
      final response = await sdk.submitTransactionEnvelopeXdrBase64(
        buildTx([payment(dest)]).toEnvelopeXdrBase64(),
      );
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$dest', 'POST /transactions']);
    });

    test('checks the inner transaction of a fee bump envelope', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitTransactionEnvelopeXdrBase64(
          feeBump(buildTx([payment(dest)])).toEnvelopeXdrBase64(),
        ),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('skips the check when asked', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitTransactionEnvelopeXdrBase64(
        buildTx([payment(dest)]).toEnvelopeXdrBase64(),
        skipMemoRequiredCheck: true,
      );
      expect(response.success, isTrue);
      expect(requests, ['POST /transactions']);
    });

    undecodableEnvelopes.forEach((name, envelope) {
      test('submits an undecodable envelope unchecked: $name', () async {
        final sdk = sdkWith(accounts: {}, requests: requests, posted: posted);
        final original = envelope();
        final response = await sdk.submitTransactionEnvelopeXdrBase64(original);
        expect(response.success, isTrue);
        expect(requests, ['POST /transactions']);
        expect(posted, [original]);
      });
    });
  });

  group('submitAsyncTransactionEnvelopeXdrBase64', () {
    test('throws when a destination requires a memo', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitAsyncTransactionEnvelopeXdrBase64(
          buildTx([payment(dest)]).toEnvelopeXdrBase64(),
        ),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('checks the inner transaction of a fee bump envelope', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.submitAsyncTransactionEnvelopeXdrBase64(
          feeBump(buildTx([payment(dest)])).toEnvelopeXdrBase64(),
        ),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('skips the check when asked', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      final response = await sdk.submitAsyncTransactionEnvelopeXdrBase64(
        buildTx([payment(dest)]).toEnvelopeXdrBase64(),
        skipMemoRequiredCheck: true,
      );
      expect(response.txStatus, 'PENDING');
      expect(requests, ['POST /transactions_async']);
    });

    undecodableEnvelopes.forEach((name, envelope) {
      test('submits an undecodable envelope unchecked: $name', () async {
        final sdk = sdkWith(accounts: {}, requests: requests, posted: posted);
        final original = envelope();
        final response = await sdk.submitAsyncTransactionEnvelopeXdrBase64(
          original,
        );
        expect(response.txStatus, 'PENDING');
        expect(requests, ['POST /transactions_async']);
        expect(posted, [original]);
      });
    });
  });

  group('checkMemoRequired', () {
    test('completes without a request when a memo is present', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await sdk.checkMemoRequired(
        buildTx([payment(dest)], memo: MemoText('hello')),
      );
      expect(requests, isEmpty);
    });

    test('throws with the account and index for a hit', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.checkMemoRequired(buildTx([payment(dest)])),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('completes after one lookup when the entry holds 0', () async {
      final sdk = sdkWith(
        accounts: {dest: flaggedWith(dest, '0')},
        requests: requests,
      );
      await sdk.checkMemoRequired(buildTx([payment(dest)]));
      expect(requests, ['GET /accounts/$dest']);
    });

    test('checks the inner transaction of a fee bump', () async {
      final sdk = sdkWith(accounts: {dest: flagged(dest)}, requests: requests);
      await expectLater(
        sdk.checkMemoRequired(feeBump(buildTx([payment(dest)]))),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('skips a 404 destination and continues to the next', () async {
      final sdk = sdkWith(
        accounts: {a: notFound(), b: unflagged(b)},
        requests: requests,
      );
      await sdk.checkMemoRequired(buildTx([payment(a), payment(b)]));
      expect(requests, ['GET /accounts/$a', 'GET /accounts/$b']);
    });

    test('makes no request for muxed destinations', () async {
      final sdk = sdkWith(accounts: {}, requests: requests);
      await sdk.checkMemoRequired(
        buildTx([mux(dest, BigInt.zero), mux(dest, BigInt.from(1234))]),
      );
      expect(requests, isEmpty);
    });

    test('propagates lookup errors other than 404', () async {
      final sdk = sdkWith(
        accounts: {a: forbidden(), b: rateLimited()},
        requests: requests,
      );
      await expectLater(
        sdk.checkMemoRequired(buildTx([payment(a)])),
        throwsA(isA<ErrorResponse>().having((e) => e.code, 'code', 403)),
      );
      await expectLater(
        sdk.checkMemoRequired(buildTx([payment(b)])),
        throwsA(isA<TooManyRequestsException>()),
      );
      expect(requests, ['GET /accounts/$a', 'GET /accounts/$b']);
    });

    test('completes without a request for another transaction type', () async {
      final sdk = sdkWith(accounts: {}, requests: requests);
      await sdk.checkMemoRequired(_OtherTransaction());
      expect(requests, isEmpty);
    });
  });

  group('typed submit methods check the payload they post', () {
    // Each lookup handler appends a payment to a flagged account to the live
    // operation list of the submitted transaction. The appended operation is
    // not part of the checked and posted payload.
    test('submitTransaction', () async {
      final transaction = buildTx([payment(a)]);
      final envelope = transaction.toEnvelopeXdrBase64();
      final sdk = sdkWith(
        accounts: {
          a: () {
            transaction.operations.add(payment(b));
            return unflagged(a)();
          },
          b: flagged(b),
        },
        requests: requests,
        posted: posted,
      );
      final response = await sdk.submitTransaction(transaction);
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$a', 'POST /transactions']);
      expect(posted, [envelope]);
    });

    test('submitFeeBumpTransaction', () async {
      final inner = buildTx([payment(a)]);
      final transaction = feeBump(inner);
      final envelope = transaction.toEnvelopeXdrBase64();
      final sdk = sdkWith(
        accounts: {
          a: () {
            inner.operations.add(payment(b));
            return unflagged(a)();
          },
          b: flagged(b),
        },
        requests: requests,
        posted: posted,
      );
      final response = await sdk.submitFeeBumpTransaction(transaction);
      expect(response.success, isTrue);
      expect(requests, ['GET /accounts/$a', 'POST /transactions']);
      expect(posted, [envelope]);
    });

    test('submitAsyncTransaction', () async {
      final transaction = buildTx([payment(a)]);
      final envelope = transaction.toEnvelopeXdrBase64();
      final sdk = sdkWith(
        accounts: {
          a: () {
            transaction.operations.add(payment(b));
            return unflagged(a)();
          },
          b: flagged(b),
        },
        requests: requests,
        posted: posted,
      );
      final response = await sdk.submitAsyncTransaction(transaction);
      expect(response.txStatus, 'PENDING');
      expect(requests, ['GET /accounts/$a', 'POST /transactions_async']);
      expect(posted, [envelope]);
    });

    test('submitAsyncFeeBumpTransaction', () async {
      final inner = buildTx([payment(a)]);
      final transaction = feeBump(inner);
      final envelope = transaction.toEnvelopeXdrBase64();
      final sdk = sdkWith(
        accounts: {
          a: () {
            inner.operations.add(payment(b));
            return unflagged(a)();
          },
          b: flagged(b),
        },
        requests: requests,
        posted: posted,
      );
      final response = await sdk.submitAsyncFeeBumpTransaction(transaction);
      expect(response.txStatus, 'PENDING');
      expect(requests, ['GET /accounts/$a', 'POST /transactions_async']);
      expect(posted, [envelope]);
    });
  });

  group('SEP-7 signAndSubmitTransaction', () {
    test('throws when a destination requires a memo', () async {
      final signer = KeyPair.random();
      final transaction = TransactionBuilder(
        Account(signer.accountId, BigInt.from(123)),
      ).addOperation(payment(dest)).build();
      final uriScheme = URIScheme();
      final url = uriScheme.generateSignTransactionURI(
        transaction.toEnvelopeXdrBase64(),
      );

      final originalClient = StellarSDK.TESTNET.httpClient;
      addTearDown(() => StellarSDK.TESTNET.httpClient = originalClient);
      StellarSDK.TESTNET.httpClient = sdkWith(
        accounts: {dest: flagged(dest)},
        requests: requests,
      ).httpClient;

      await expectLater(
        uriScheme.signAndSubmitTransaction(
          url,
          signer,
          network: Network.TESTNET,
        ),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });

    test('checks the inner transaction of a fee bump', () async {
      final signer = KeyPair.random();
      final inner = TransactionBuilder(
        Account(signer.accountId, BigInt.from(123)),
      ).addOperation(payment(dest)).build();
      final uriScheme = URIScheme();
      final url = uriScheme.generateSignTransactionURI(
        feeBump(inner).toEnvelopeXdrBase64(),
      );

      final originalClient = StellarSDK.TESTNET.httpClient;
      addTearDown(() => StellarSDK.TESTNET.httpClient = originalClient);
      StellarSDK.TESTNET.httpClient = sdkWith(
        accounts: {dest: flagged(dest)},
        requests: requests,
      ).httpClient;

      await expectLater(
        uriScheme.signAndSubmitTransaction(
          url,
          signer,
          network: Network.TESTNET,
        ),
        throwsA(memoRequired(dest, 0)),
      );
      expect(requests, ['GET /accounts/$dest']);
    });
  });

  group('AccountRequiresMemoException', () {
    test('carries the account id and the operation index', () {
      final accountId = KeyPair.random().accountId;
      final exception = AccountRequiresMemoException(accountId, 3);
      expect(exception, isA<Exception>());
      expect(exception.accountId, accountId);
      expect(exception.operationIndex, 3);
      expect(
        exception.toString(),
        'Destination account $accountId of operation 3 '
        'requires a memo in the transaction.',
      );
    });
  });
}
