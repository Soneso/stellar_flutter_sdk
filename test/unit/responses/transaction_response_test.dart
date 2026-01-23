import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('TransactionResponse', () {
    group('fromJson', () {
      test('parses complete successful transaction response', () {
        final json = {
          'id': 'abc123',
          'hash': 'abc123',
          'ledger': 12345,
          'created_at': '2024-01-15T10:30:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'successful': true,
          'paging_token': '12345-1',
          'source_account_sequence': 100,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'result_meta_xdr': 'AAAAAwAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': ['sig1==', 'sig2=='],
          '_links': {
            'self': {'href': '/transactions/abc123'},
            'account': {'href': '/accounts/GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'},
            'ledger': {'href': '/ledgers/12345'},
            'operations': {'href': '/transactions/abc123/operations'},
            'effects': {'href': '/transactions/abc123/effects'},
            'precedes': {'href': '/transactions?order=asc&cursor=12345-1'},
            'succeeds': {'href': '/transactions?order=desc&cursor=12345-1'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.id, equals('abc123'));
        expect(tx.hash, equals('abc123'));
        expect(tx.ledger, equals(12345));
        expect(tx.createdAt, equals('2024-01-15T10:30:00Z'));
        expect(tx.sourceAccount, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(tx.feeAccount, equals('GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7'));
        expect(tx.successful, isTrue);
        expect(tx.pagingToken, equals('12345-1'));
        expect(tx.sourceAccountSequence, equals(100));
        expect(tx.maxFee, equals(1000));
        expect(tx.feeCharged, equals(100));
        expect(tx.operationCount, equals(1));
        expect(tx.envelopeXdr, equals('AAAAAgAAAAA='));
        expect(tx.resultXdr, equals('AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA='));
        expect(tx.resultMetaXdr, equals('AAAAAwAAAAA='));
        expect(tx.feeMetaXdr, equals('AAAAAgAAAAA='));
        expect(tx.signatures.length, equals(2));
        expect(tx.signatures[0], equals('sig1=='));
        expect(tx.signatures[1], equals('sig2=='));
      });

      test('parses transaction with muxed accounts', () {
        final json = {
          'id': 'xyz789',
          'hash': 'xyz789',
          'ledger': 12346,
          'created_at': '2024-01-15T10:31:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'source_account_muxed': 'MAAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY',
          'source_account_muxed_id': '420',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account_muxed': 'MAAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY',
          'fee_account_muxed_id': '420',
          'successful': true,
          'paging_token': '12346-1',
          'source_account_sequence': 101,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/xyz789'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.sourceAccountMuxed, equals('MAAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY'));
        expect(tx.sourceAccountMuxedId, equals('420'));
        expect(tx.feeAccountMuxed, equals('MAAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY'));
        expect(tx.feeAccountMuxedId, equals('420'));
      });

      test('parses transaction with text memo', () {
        final json = {
          'id': 'memo123',
          'hash': 'memo123',
          'ledger': 12347,
          'created_at': '2024-01-15T10:32:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'successful': true,
          'paging_token': '12347-1',
          'source_account_sequence': 102,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'text',
          'memo': 'test memo',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/memo123'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.memo, isA<MemoText>());
        expect((tx.memo as MemoText).text, equals('test memo'));
      });

      test('parses transaction with id memo', () {
        final json = {
          'id': 'memoid',
          'hash': 'memoid',
          'ledger': 12348,
          'created_at': '2024-01-15T10:33:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'successful': true,
          'paging_token': '12348-1',
          'source_account_sequence': 103,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'id',
          'memo': '12345',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/memoid'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.memo, isA<MemoId>());
        expect((tx.memo as MemoId).getId(), equals(BigInt.from(12345)));
      });

      test('parses transaction with hash memo', () {
        final json = {
          'id': 'memohash',
          'hash': 'memohash',
          'ledger': 12349,
          'created_at': '2024-01-15T10:34:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'successful': true,
          'paging_token': '12349-1',
          'source_account_sequence': 104,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'hash',
          'memo': 'YWJjZGVmMTIzNDU2Nzg5MGFiY2RlZjEyMzQ1Njc4OTA=',
          'memo_bytes': 'YWJjZGVmMTIzNDU2Nzg5MGFiY2RlZjEyMzQ1Njc4OTA=',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/memohash'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.memo, isA<MemoHash>());
        expect(tx.memoBytes, equals('YWJjZGVmMTIzNDU2Nzg5MGFiY2RlZjEyMzQ1Njc4OTA='));
      });

      test('parses transaction with preconditions', () {
        final json = {
          'id': 'precond123',
          'hash': 'precond123',
          'ledger': 12350,
          'created_at': '2024-01-15T10:35:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'successful': true,
          'paging_token': '12350-1',
          'source_account_sequence': 105,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': [],
          'preconditions': {
            'timebounds': {
              'min_time': '1705315200',
              'max_time': '1705318800',
            },
            'ledgerbounds': {
              'min_ledger': 12000,
              'max_ledger': 13000,
            },
            'min_account_sequence': '100',
            'min_account_sequence_age': '3600',
            'min_account_sequence_ledger_gap': 10,
            'extra_signers': ['GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA'],
          },
          '_links': {
            'self': {'href': '/transactions/precond123'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.preconditions, isNotNull);
        expect(tx.preconditions!.timeBounds, isNotNull);
        expect(tx.preconditions!.timeBounds!.minTime, equals('1705315200'));
        expect(tx.preconditions!.timeBounds!.maxTime, equals('1705318800'));
        expect(tx.preconditions!.ledgerBounds, isNotNull);
        expect(tx.preconditions!.ledgerBounds!.minLedger, equals(12000));
        expect(tx.preconditions!.ledgerBounds!.maxLedger, equals(13000));
        expect(tx.preconditions!.minAccountSequence, equals('100'));
        expect(tx.preconditions!.minAccountSequenceAge, equals('3600'));
        expect(tx.preconditions!.minAccountSequenceLedgerGap, equals(10));
        expect(tx.preconditions!.extraSigners, isNotNull);
        expect(tx.preconditions!.extraSigners!.length, equals(1));
      });

      test('parses fee bump transaction with inner transaction', () {
        final json = {
          'id': 'feebump123',
          'hash': 'feebump123',
          'ledger': 12351,
          'created_at': '2024-01-15T10:36:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GBCD1234EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXAMPLE7EXA',
          'successful': true,
          'paging_token': '12351-1',
          'source_account_sequence': 106,
          'max_fee': 2000,
          'fee_charged': 200,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': ['feesig=='],
          'fee_bump_transaction': {
            'hash': 'outertxhash',
            'signatures': ['outersig=='],
          },
          'inner_transaction': {
            'hash': 'innertxhash',
            'signatures': ['innersig1==', 'innersig2=='],
            'max_fee': 1000,
          },
          '_links': {
            'self': {'href': '/transactions/feebump123'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.feeBumpTransaction, isNotNull);
        expect(tx.feeBumpTransaction!.hash, equals('outertxhash'));
        expect(tx.feeBumpTransaction!.signatures.length, equals(1));
        expect(tx.feeBumpTransaction!.signatures[0], equals('outersig=='));

        expect(tx.innerTransaction, isNotNull);
        expect(tx.innerTransaction!.hash, equals('innertxhash'));
        expect(tx.innerTransaction!.signatures.length, equals(2));
        expect(tx.innerTransaction!.maxFee, equals(1000));
      });

      test('parses transaction with null optional fields', () {
        final json = {
          'id': 'minimal123',
          'hash': 'minimal123',
          'ledger': 12352,
          'created_at': '2024-01-15T10:37:00Z',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'successful': false,
          'paging_token': '12352-1',
          'source_account_sequence': 107,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/minimal123'},
          },
        };

        final tx = TransactionResponse.fromJson(json);

        expect(tx.sourceAccountMuxed, isNull);
        expect(tx.sourceAccountMuxedId, isNull);
        expect(tx.feeAccountMuxed, isNull);
        expect(tx.feeAccountMuxedId, isNull);
        expect(tx.resultMetaXdr, isNull);
        expect(tx.memoBytes, isNull);
        expect(tx.feeBumpTransaction, isNull);
        expect(tx.innerTransaction, isNull);
        expect(tx.preconditions, isNull);
        expect(tx.successful, isFalse);
      });
    });

    group('TransactionResponseLinks', () {
      test('parses all links correctly', () {
        final json = {
          'self': {'href': '/transactions/abc123'},
          'account': {'href': '/accounts/GABC'},
          'ledger': {'href': '/ledgers/12345'},
          'operations': {'href': '/transactions/abc123/operations'},
          'effects': {'href': '/transactions/abc123/effects'},
          'precedes': {'href': '/transactions?order=asc&cursor=12345-1'},
          'succeeds': {'href': '/transactions?order=desc&cursor=12345-1'},
        };

        final links = TransactionResponseLinks.fromJson(json);

        expect(links.self!.href, equals('/transactions/abc123'));
        expect(links.account!.href, equals('/accounts/GABC'));
        expect(links.ledger!.href, equals('/ledgers/12345'));
        expect(links.operations!.href, equals('/transactions/abc123/operations'));
        expect(links.effects!.href, equals('/transactions/abc123/effects'));
        expect(links.precedes!.href, equals('/transactions?order=asc&cursor=12345-1'));
        expect(links.succeeds!.href, equals('/transactions?order=desc&cursor=12345-1'));
      });

      test('handles null links', () {
        final json = {
          'self': {'href': '/transactions/abc123'},
        };

        final links = TransactionResponseLinks.fromJson(json);

        expect(links.self, isNotNull);
        expect(links.account, isNull);
        expect(links.ledger, isNull);
        expect(links.operations, isNull);
        expect(links.effects, isNull);
        expect(links.precedes, isNull);
        expect(links.succeeds, isNull);
      });
    });

    group('FeeBumpTransactionResponse', () {
      test('parses correctly', () {
        final json = {
          'hash': 'outertxhash123',
          'signatures': ['sig1==', 'sig2==', 'sig3=='],
        };

        final feeBump = FeeBumpTransactionResponse.fromJson(json);

        expect(feeBump.hash, equals('outertxhash123'));
        expect(feeBump.signatures.length, equals(3));
        expect(feeBump.signatures[0], equals('sig1=='));
        expect(feeBump.signatures[1], equals('sig2=='));
        expect(feeBump.signatures[2], equals('sig3=='));
      });

      test('handles empty signatures', () {
        final json = {
          'hash': 'nosighash',
          'signatures': [],
        };

        final feeBump = FeeBumpTransactionResponse.fromJson(json);

        expect(feeBump.hash, equals('nosighash'));
        expect(feeBump.signatures, isEmpty);
      });
    });

    group('InnerTransaction', () {
      test('parses correctly', () {
        final json = {
          'hash': 'innertxhash456',
          'signatures': ['innersig1=='],
          'max_fee': 1500,
        };

        final inner = InnerTransaction.fromJson(json);

        expect(inner.hash, equals('innertxhash456'));
        expect(inner.signatures.length, equals(1));
        expect(inner.signatures[0], equals('innersig1=='));
        expect(inner.maxFee, equals(1500));
      });
    });

    group('TransactionPreconditionsResponse', () {
      test('parses with all preconditions', () {
        final json = {
          'timebounds': {
            'min_time': '1000',
            'max_time': '2000',
          },
          'ledgerbounds': {
            'min_ledger': 100,
            'max_ledger': 200,
          },
          'min_account_sequence': '50',
          'min_account_sequence_age': '3600',
          'min_account_sequence_ledger_gap': 5,
          'extra_signers': ['GABC', 'GDEF'],
        };

        final preconditions = TransactionPreconditionsResponse.fromJson(json);

        expect(preconditions.timeBounds, isNotNull);
        expect(preconditions.ledgerBounds, isNotNull);
        expect(preconditions.minAccountSequence, equals('50'));
        expect(preconditions.minAccountSequenceAge, equals('3600'));
        expect(preconditions.minAccountSequenceLedgerGap, equals(5));
        expect(preconditions.extraSigners!.length, equals(2));
      });

      test('handles null preconditions', () {
        final json = <String, dynamic>{};

        final preconditions = TransactionPreconditionsResponse.fromJson(json);

        expect(preconditions.timeBounds, isNull);
        expect(preconditions.ledgerBounds, isNull);
        expect(preconditions.minAccountSequence, isNull);
        expect(preconditions.minAccountSequenceAge, isNull);
        expect(preconditions.minAccountSequenceLedgerGap, isNull);
      });

      test('handles empty extra_signers', () {
        final json = {
          'extra_signers': null,
        };

        final preconditions = TransactionPreconditionsResponse.fromJson(json);

        expect(preconditions.extraSigners, isEmpty);
      });
    });

    group('PreconditionsTimeBoundsResponse', () {
      test('parses correctly', () {
        final json = {
          'min_time': '1705315200',
          'max_time': '1705318800',
        };

        final timeBounds = PreconditionsTimeBoundsResponse.fromJson(json);

        expect(timeBounds.minTime, equals('1705315200'));
        expect(timeBounds.maxTime, equals('1705318800'));
      });

      test('handles null values', () {
        final json = {
          'min_time': null,
          'max_time': null,
        };

        final timeBounds = PreconditionsTimeBoundsResponse.fromJson(json);

        expect(timeBounds.minTime, isNull);
        expect(timeBounds.maxTime, isNull);
      });
    });

    group('PreconditionsLedgerBoundsResponse', () {
      test('parses correctly', () {
        final json = {
          'min_ledger': 12000,
          'max_ledger': 13000,
        };

        final ledgerBounds = PreconditionsLedgerBoundsResponse.fromJson(json);

        expect(ledgerBounds.minLedger, equals(12000));
        expect(ledgerBounds.maxLedger, equals(13000));
      });

      test('handles null max_ledger', () {
        final json = {
          'min_ledger': 12000,
          'max_ledger': null,
        };

        final ledgerBounds = PreconditionsLedgerBoundsResponse.fromJson(json);

        expect(ledgerBounds.minLedger, equals(12000));
        expect(ledgerBounds.maxLedger, isNull);
      });

      test('defaults to zero when min_ledger is null', () {
        final json = {
          'min_ledger': null,
        };

        final ledgerBounds = PreconditionsLedgerBoundsResponse.fromJson(json);

        expect(ledgerBounds.minLedger, equals(0));
      });
    });
  });
}
