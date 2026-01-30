import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('LedgerResponse', () {
    group('fromJson', () {
      test('parses complete ledger response with all fields', () {
        final json = {
          'sequence': 12345,
          'hash': 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
          'id': 'ledger-12345-id',
          'paging_token': '12345',
          'prev_hash': '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
          'successful_transaction_count': 42,
          'failed_transaction_count': 3,
          'operation_count': 150,
          'tx_set_operation_count': 153,
          'closed_at': '2024-01-15T10:30:00Z',
          'total_coins': '105443902087.3472865',
          'fee_pool': '1873823575.5016190',
          'base_fee_in_stroops': 100,
          'base_reserve_in_stroops': 5000000,
          'max_tx_set_size': 1000,
          'protocol_version': 20,
          'header_xdr': 'AAAAFAAAAABjZW5kZXIgaGFzaCBoZXJlAAAAAAAAAAAAAAAAAAAA',
          '_links': {
            'effects': {'href': '/ledgers/12345/effects'},
            'operations': {'href': '/ledgers/12345/operations'},
            'self': {'href': '/ledgers/12345'},
            'transactions': {'href': '/ledgers/12345/transactions'},
            'payments': {'href': '/ledgers/12345/payments'},
          },
          'rateLimitLimit': 200,
          'rateLimitRemaining': 150,
          'rateLimitReset': 1705315200,
        };

        final ledger = LedgerResponse.fromJson(json);

        expect(ledger.sequence, equals(12345));
        expect(ledger.hash, equals('abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890'));
        expect(ledger.id, equals('ledger-12345-id'));
        expect(ledger.pagingToken, equals('12345'));
        expect(ledger.prevHash, equals('1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'));
        expect(ledger.successfulTransactionCount, equals(42));
        expect(ledger.failedTransactionCount, equals(3));
        expect(ledger.operationCount, equals(150));
        expect(ledger.txSetOperationCount, equals(153));
        expect(ledger.closedAt, equals('2024-01-15T10:30:00Z'));
        expect(ledger.totalCoins, equals('105443902087.3472865'));
        expect(ledger.feePool, equals('1873823575.5016190'));
        expect(ledger.baseFeeInStroops, equals(100));
        expect(ledger.baseReserveInStroops, equals(5000000));
        expect(ledger.maxTxSetSize, equals(1000));
        expect(ledger.protocolVersion, equals(20));
        expect(ledger.headerXdr, equals('AAAAFAAAAABjZW5kZXIgaGFzaCBoZXJlAAAAAAAAAAAAAAAAAAAA'));
        expect(ledger.rateLimitLimit, equals(200));
        expect(ledger.rateLimitRemaining, equals(150));
        expect(ledger.rateLimitReset, equals(1705315200));
      });

      test('parses ledger response with null prev_hash', () {
        final json = {
          'sequence': 1,
          'hash': 'genesishash1234567890abcdef1234567890abcdef1234567890abcdef12345',
          'id': 'ledger-1-id',
          'paging_token': '1',
          'prev_hash': null,
          'successful_transaction_count': 0,
          'failed_transaction_count': 0,
          'operation_count': 0,
          'tx_set_operation_count': 0,
          'closed_at': '2015-09-30T17:15:54Z',
          'total_coins': '100000000000.0000000',
          'fee_pool': '0.0000000',
          'base_fee_in_stroops': 100,
          'base_reserve_in_stroops': 10000000,
          'max_tx_set_size': 100,
          'protocol_version': 1,
          'header_xdr': 'AAAAAQAAAAAAAAAA',
          '_links': {
            'effects': {'href': '/ledgers/1/effects'},
            'operations': {'href': '/ledgers/1/operations'},
            'self': {'href': '/ledgers/1'},
            'transactions': {'href': '/ledgers/1/transactions'},
            'payments': {'href': '/ledgers/1/payments'},
          },
        };

        final ledger = LedgerResponse.fromJson(json);

        expect(ledger.sequence, equals(1));
        expect(ledger.prevHash, isNull);
        expect(ledger.successfulTransactionCount, equals(0));
        expect(ledger.failedTransactionCount, equals(0));
      });

      test('parses ledger with high transaction counts', () {
        final json = {
          'sequence': 50000000,
          'hash': 'busyledgerhash1234567890abcdef1234567890abcdef1234567890abcdef',
          'id': 'ledger-50000000-id',
          'paging_token': '50000000',
          'prev_hash': 'prevhash1234567890abcdef1234567890abcdef1234567890abcdef1234',
          'successful_transaction_count': 999,
          'failed_transaction_count': 50,
          'operation_count': 5000,
          'tx_set_operation_count': 5250,
          'closed_at': '2024-01-15T10:35:00Z',
          'total_coins': '105443902087.3472865',
          'fee_pool': '2000000000.0000000',
          'base_fee_in_stroops': 100,
          'base_reserve_in_stroops': 5000000,
          'max_tx_set_size': 1000,
          'protocol_version': 20,
          'header_xdr': 'AAAAAAAAAAAAAAAA',
          '_links': {
            'effects': {'href': '/ledgers/50000000/effects'},
            'operations': {'href': '/ledgers/50000000/operations'},
            'self': {'href': '/ledgers/50000000'},
            'transactions': {'href': '/ledgers/50000000/transactions'},
            'payments': {'href': '/ledgers/50000000/payments'},
          },
        };

        final ledger = LedgerResponse.fromJson(json);

        expect(ledger.sequence, equals(50000000));
        expect(ledger.successfulTransactionCount, equals(999));
        expect(ledger.failedTransactionCount, equals(50));
        expect(ledger.operationCount, equals(5000));
        expect(ledger.txSetOperationCount, equals(5250));
      });

      test('parses ledger with different protocol versions', () {
        final json = {
          'sequence': 12345,
          'hash': 'hash123',
          'id': 'ledger-12345-id',
          'paging_token': '12345',
          'successful_transaction_count': 10,
          'failed_transaction_count': 0,
          'operation_count': 20,
          'tx_set_operation_count': 20,
          'closed_at': '2024-01-15T10:30:00Z',
          'total_coins': '105443902087.3472865',
          'fee_pool': '1873823575.5016190',
          'base_fee_in_stroops': 100,
          'base_reserve_in_stroops': 5000000,
          'max_tx_set_size': 1000,
          'protocol_version': 21,
          'header_xdr': 'AAAAAAAAAAAAAAAA',
          '_links': {
            'effects': {'href': '/ledgers/12345/effects'},
            'operations': {'href': '/ledgers/12345/operations'},
            'self': {'href': '/ledgers/12345'},
            'transactions': {'href': '/ledgers/12345/transactions'},
            'payments': {'href': '/ledgers/12345/payments'},
          },
        };

        final ledger = LedgerResponse.fromJson(json);

        expect(ledger.protocolVersion, equals(21));
      });

      test('parses ledger with empty transaction set', () {
        final json = {
          'sequence': 100,
          'hash': 'emptyhash123',
          'id': 'ledger-100-id',
          'paging_token': '100',
          'prev_hash': 'prevhash',
          'successful_transaction_count': 0,
          'failed_transaction_count': 0,
          'operation_count': 0,
          'tx_set_operation_count': 0,
          'closed_at': '2024-01-15T10:30:00Z',
          'total_coins': '100000000000.0000000',
          'fee_pool': '1000000.0000000',
          'base_fee_in_stroops': 100,
          'base_reserve_in_stroops': 5000000,
          'max_tx_set_size': 1000,
          'protocol_version': 20,
          'header_xdr': 'AAAAAAAAAAAAAAAA',
          '_links': {
            'effects': {'href': '/ledgers/100/effects'},
            'operations': {'href': '/ledgers/100/operations'},
            'self': {'href': '/ledgers/100'},
            'transactions': {'href': '/ledgers/100/transactions'},
            'payments': {'href': '/ledgers/100/payments'},
          },
        };

        final ledger = LedgerResponse.fromJson(json);

        expect(ledger.successfulTransactionCount, equals(0));
        expect(ledger.failedTransactionCount, equals(0));
        expect(ledger.operationCount, equals(0));
        expect(ledger.txSetOperationCount, equals(0));
      });

      test('parses ledger with varying base fees', () {
        final json = {
          'sequence': 12345,
          'hash': 'hash123',
          'id': 'ledger-12345-id',
          'paging_token': '12345',
          'successful_transaction_count': 10,
          'failed_transaction_count': 0,
          'operation_count': 20,
          'tx_set_operation_count': 20,
          'closed_at': '2024-01-15T10:30:00Z',
          'total_coins': '105443902087.3472865',
          'fee_pool': '1873823575.5016190',
          'base_fee_in_stroops': 500,
          'base_reserve_in_stroops': 10000000,
          'max_tx_set_size': 1000,
          'protocol_version': 20,
          'header_xdr': 'AAAAAAAAAAAAAAAA',
          '_links': {
            'effects': {'href': '/ledgers/12345/effects'},
            'operations': {'href': '/ledgers/12345/operations'},
            'self': {'href': '/ledgers/12345'},
            'transactions': {'href': '/ledgers/12345/transactions'},
            'payments': {'href': '/ledgers/12345/payments'},
          },
        };

        final ledger = LedgerResponse.fromJson(json);

        expect(ledger.baseFeeInStroops, equals(500));
        expect(ledger.baseReserveInStroops, equals(10000000));
      });
    });

    group('LedgerResponseLinks', () {
      test('parses all links correctly', () {
        final json = {
          'effects': {'href': '/ledgers/12345/effects'},
          'operations': {'href': '/ledgers/12345/operations'},
          'self': {'href': '/ledgers/12345'},
          'transactions': {'href': '/ledgers/12345/transactions'},
          'payments': {'href': '/ledgers/12345/payments'},
        };

        final links = LedgerResponseLinks.fromJson(json);

        expect(links.effects.href, equals('/ledgers/12345/effects'));
        expect(links.operations.href, equals('/ledgers/12345/operations'));
        expect(links.self.href, equals('/ledgers/12345'));
        expect(links.transactions.href, equals('/ledgers/12345/transactions'));
        expect(links.payments.href, equals('/ledgers/12345/payments'));
      });

      test('parses links with query parameters', () {
        final json = {
          'effects': {'href': '/ledgers/12345/effects?cursor=abc&limit=10'},
          'operations': {'href': '/ledgers/12345/operations?order=desc'},
          'self': {'href': '/ledgers/12345'},
          'transactions': {'href': '/ledgers/12345/transactions?include_failed=true'},
          'payments': {'href': '/ledgers/12345/payments?cursor=xyz'},
        };

        final links = LedgerResponseLinks.fromJson(json);

        expect(links.effects.href, contains('cursor=abc'));
        expect(links.operations.href, contains('order=desc'));
        expect(links.transactions.href, contains('include_failed=true'));
        expect(links.payments.href, contains('cursor=xyz'));
      });

      test('parses links with templated parameters', () {
        final json = {
          'effects': {'href': '/ledgers/{sequence}/effects', 'templated': true},
          'operations': {'href': '/ledgers/{sequence}/operations', 'templated': true},
          'self': {'href': '/ledgers/12345'},
          'transactions': {'href': '/ledgers/{sequence}/transactions', 'templated': true},
          'payments': {'href': '/ledgers/{sequence}/payments', 'templated': true},
        };

        final links = LedgerResponseLinks.fromJson(json);

        expect(links.effects.href, equals('/ledgers/{sequence}/effects'));
        expect(links.effects.templated, isTrue);
        expect(links.operations.href, equals('/ledgers/{sequence}/operations'));
        expect(links.self.href, equals('/ledgers/12345'));
      });
    });
  });
}
