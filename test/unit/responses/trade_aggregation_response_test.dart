// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('TradeAggregationResponse', () {
    test('parses complete JSON with all fields', () {
      final json = {
        'timestamp': '1609459200000',
        'trade_count': '42',
        'base_volume': '1000.5000000',
        'counter_volume': '500.2500000',
        'avg': '0.5002500',
        'high': '0.5500000',
        'high_r': {'n': 11, 'd': 20},
        'low': '0.4500000',
        'low_r': {'n': 9, 'd': 20},
        'open': '0.4800000',
        'open_r': {'n': 12, 'd': 25},
        'close': '0.5200000',
        'close_r': {'n': 13, 'd': 25},
        'rateLimitLimit': 200,
        'rateLimitRemaining': 150,
        'rateLimitReset': 1609459800
      };

      final response = TradeAggregationResponse.fromJson(json);

      expect(response.timestamp, equals('1609459200000'));
      expect(response.tradeCount, equals('42'));
      expect(response.baseVolume, equals('1000.5000000'));
      expect(response.counterVolume, equals('500.2500000'));
      expect(response.avg, equals('0.5002500'));
      expect(response.high, equals('0.5500000'));
      expect(response.highR.n, equals(11));
      expect(response.highR.d, equals(20));
      expect(response.low, equals('0.4500000'));
      expect(response.lowR.n, equals(9));
      expect(response.lowR.d, equals(20));
      expect(response.open, equals('0.4800000'));
      expect(response.openR.n, equals(12));
      expect(response.openR.d, equals(25));
      expect(response.close, equals('0.5200000'));
      expect(response.closeR.n, equals(13));
      expect(response.closeR.d, equals(25));
      expect(response.rateLimitLimit, equals(200));
      expect(response.rateLimitRemaining, equals(150));
      expect(response.rateLimitReset, equals(1609459800));
    });

    test('converts timestamp to DateTime correctly', () {
      final json = {
        'timestamp': '1609459200000',
        'trade_count': '10',
        'base_volume': '100.0',
        'counter_volume': '50.0',
        'avg': '0.5',
        'high': '0.6',
        'high_r': {'n': 3, 'd': 5},
        'low': '0.4',
        'low_r': {'n': 2, 'd': 5},
        'open': '0.45',
        'open_r': {'n': 9, 'd': 20},
        'close': '0.55',
        'close_r': {'n': 11, 'd': 20},
      };

      final response = TradeAggregationResponse.fromJson(json);
      final date = response.getDate();

      expect(date, isA<DateTime>());
      expect(date.millisecondsSinceEpoch, equals(1609459200000));
    });

    test('parses Price objects with string values', () {
      final json = {
        'timestamp': '1609459200000',
        'trade_count': '5',
        'base_volume': '100.0',
        'counter_volume': '50.0',
        'avg': '0.5',
        'high': '0.6',
        'high_r': {'n': '3', 'd': '5'},
        'low': '0.4',
        'low_r': {'n': '2', 'd': '5'},
        'open': '0.45',
        'open_r': {'n': '9', 'd': '20'},
        'close': '0.55',
        'close_r': {'n': '11', 'd': '20'},
      };

      final response = TradeAggregationResponse.fromJson(json);

      expect(response.highR.n, equals(3));
      expect(response.highR.d, equals(5));
      expect(response.lowR.n, equals(2));
      expect(response.lowR.d, equals(5));
      expect(response.openR.n, equals(9));
      expect(response.openR.d, equals(20));
      expect(response.closeR.n, equals(11));
      expect(response.closeR.d, equals(20));
    });
  });

  group('RootResponse', () {
    test('parses complete TESTNET root response', () {
      final json = {
        'horizon_version': '2.27.0',
        'core_version': 'v19.14.0',
        'ingest_latest_ledger': 123456,
        'history_latest_ledger': 123456,
        'history_latest_ledger_closed_at': '2025-10-05T12:34:56Z',
        'history_elder_ledger': 2,
        'core_latest_ledger': 123456,
        'network_passphrase': 'Test SDF Network ; September 2015',
        'current_protocol_version': 20,
        'supported_protocol_version': 20,
        'core_supported_protocol_version': 20,
        'rateLimitLimit': 300,
        'rateLimitRemaining': 250,
        'rateLimitReset': 1609459800
      };

      final response = RootResponse.fromJson(json);

      expect(response.horizonVersion, equals('2.27.0'));
      expect(response.stellarCoreVersion, equals('v19.14.0'));
      expect(response.ingestLatestLedger, equals(123456));
      expect(response.historyLatestLedger, equals(123456));
      expect(response.historyLatestLedgerClosedAt,
          equals('2025-10-05T12:34:56Z'));
      expect(response.historyElderLedger, equals(2));
      expect(response.coreLatestLedger, equals(123456));
      expect(response.networkPassphrase,
          equals('Test SDF Network ; September 2015'));
      expect(response.currentProtocolVersion, equals(20));
      expect(response.supportedProtocolVersion, equals(20));
      expect(response.coreSupportedProtocolVersion, equals(20));
      expect(response.rateLimitLimit, equals(300));
      expect(response.rateLimitRemaining, equals(250));
      expect(response.rateLimitReset, equals(1609459800));
    });

    test('parses complete PUBNET root response', () {
      final json = {
        'horizon_version': '2.28.1',
        'core_version': 'v20.0.0',
        'ingest_latest_ledger': 50000000,
        'history_latest_ledger': 50000000,
        'history_latest_ledger_closed_at': '2025-10-05T15:00:00Z',
        'history_elder_ledger': 2,
        'core_latest_ledger': 50000000,
        'network_passphrase': 'Public Global Stellar Network ; September 2015',
        'current_protocol_version': 21,
        'supported_protocol_version': 21,
        'core_supported_protocol_version': 21,
      };

      final response = RootResponse.fromJson(json);

      expect(response.horizonVersion, equals('2.28.1'));
      expect(response.stellarCoreVersion, equals('v20.0.0'));
      expect(response.ingestLatestLedger, equals(50000000));
      expect(response.historyLatestLedger, equals(50000000));
      expect(response.networkPassphrase,
          equals('Public Global Stellar Network ; September 2015'));
      expect(response.currentProtocolVersion, equals(21));
    });

    test('parses ledger numbers as strings', () {
      final json = {
        'horizon_version': '2.27.0',
        'core_version': 'v19.14.0',
        'ingest_latest_ledger': '123456',
        'history_latest_ledger': '123456',
        'history_latest_ledger_closed_at': '2025-10-05T12:34:56Z',
        'history_elder_ledger': '2',
        'core_latest_ledger': '123456',
        'network_passphrase': 'Test SDF Network ; September 2015',
        'current_protocol_version': '20',
        'supported_protocol_version': '20',
        'core_supported_protocol_version': '20',
      };

      final response = RootResponse.fromJson(json);

      expect(response.ingestLatestLedger, equals(123456));
      expect(response.historyLatestLedger, equals(123456));
      expect(response.historyElderLedger, equals(2));
      expect(response.coreLatestLedger, equals(123456));
      expect(response.currentProtocolVersion, equals(20));
      expect(response.supportedProtocolVersion, equals(20));
      expect(response.coreSupportedProtocolVersion, equals(20));
    });
  });

  group('HealthResponse', () {
    test('parses healthy status', () {
      final json = {
        'database_connected': true,
        'core_up': true,
        'core_synced': true,
      };

      final response = HealthResponse.fromJson(json);

      expect(response.databaseConnected, isTrue);
      expect(response.coreUp, isTrue);
      expect(response.coreSynced, isTrue);
      expect(response.isHealthy, isTrue);
    });

    test('parses unhealthy status - database disconnected', () {
      final json = {
        'database_connected': false,
        'core_up': true,
        'core_synced': true,
      };

      final response = HealthResponse.fromJson(json);

      expect(response.databaseConnected, isFalse);
      expect(response.coreUp, isTrue);
      expect(response.coreSynced, isTrue);
      expect(response.isHealthy, isFalse);
    });

    test('parses unhealthy status - core down', () {
      final json = {
        'database_connected': true,
        'core_up': false,
        'core_synced': true,
      };

      final response = HealthResponse.fromJson(json);

      expect(response.databaseConnected, isTrue);
      expect(response.coreUp, isFalse);
      expect(response.coreSynced, isTrue);
      expect(response.isHealthy, isFalse);
    });

    test('parses unhealthy status - core not synced', () {
      final json = {
        'database_connected': true,
        'core_up': true,
        'core_synced': false,
      };

      final response = HealthResponse.fromJson(json);

      expect(response.databaseConnected, isTrue);
      expect(response.coreUp, isTrue);
      expect(response.coreSynced, isFalse);
      expect(response.isHealthy, isFalse);
    });

    test('parses completely unhealthy status', () {
      final json = {
        'database_connected': false,
        'core_up': false,
        'core_synced': false,
      };

      final response = HealthResponse.fromJson(json);

      expect(response.databaseConnected, isFalse);
      expect(response.coreUp, isFalse);
      expect(response.coreSynced, isFalse);
      expect(response.isHealthy, isFalse);
    });

    test('toJson returns correct map', () {
      final response = HealthResponse(
        databaseConnected: true,
        coreUp: true,
        coreSynced: false,
      );

      final json = response.toJson();

      expect(json['database_connected'], isTrue);
      expect(json['core_up'], isTrue);
      expect(json['core_synced'], isFalse);
    });

    test('toString returns formatted string', () {
      final response = HealthResponse(
        databaseConnected: true,
        coreUp: true,
        coreSynced: true,
      );

      final str = response.toString();

      expect(str, contains('HealthResponse'));
      expect(str, contains('databaseConnected: true'));
      expect(str, contains('coreUp: true'));
      expect(str, contains('coreSynced: true'));
    });
  });

  group('SubmitTransactionResponse - Success Cases', () {
    test('parses basic submit transaction response fields', () {
      final json = {
        'hash': 'abc123def456',
        'ledger': 123456,
        'rateLimitLimit': 100,
        'rateLimitRemaining': 50,
        'rateLimitReset': 1609459800
      };

      final response = SubmitTransactionResponse.fromJson(json);

      expect(response.hash, equals('abc123def456'));
      expect(response.ledger, equals(123456));
      expect(response.rateLimitLimit, equals(100));
      expect(response.rateLimitRemaining, equals(50));
      expect(response.rateLimitReset, equals(1609459800));
    });

    test('parses transaction with extras on failure', () {
      final json = {
        'hash': 'failed123',
        'extras': {
          'envelope_xdr': 'BBBBB...',
          'result_xdr': 'CCCCC...',
          'result_meta_xdr': 'DDDDD...',
          'fee_meta_xdr': 'EEEEE...',
          'result_codes': {
            'transaction': 'tx_failed',
            'operations': ['op_underfunded', 'op_success']
          }
        }
      };

      final response = SubmitTransactionResponse.fromJson(json);

      expect(response.hash, equals('failed123'));
      expect(response.extras, isNotNull);
      expect(response.extras!.envelopeXdr, equals('BBBBB...'));
      expect(response.extras!.resultXdr, equals('CCCCC...'));
      expect(response.extras!.strMetaXdr, equals('DDDDD...'));
      expect(response.extras!.strFeeMetaXdr, equals('EEEEE...'));
      expect(response.extras!.resultCodes, isNotNull);
      expect(response.extras!.resultCodes!.transactionResultCode,
          equals('tx_failed'));
      expect(response.extras!.resultCodes!.operationsResultCodes, isNotNull);
      expect(response.extras!.resultCodes!.operationsResultCodes!.length,
          equals(2));
      expect(response.extras!.resultCodes!.operationsResultCodes![0],
          equals('op_underfunded'));
      expect(response.extras!.resultCodes!.operationsResultCodes![1],
          equals('op_success'));
    });
  });

  group('ExtrasResultCodes', () {
    test('parses result codes with operations', () {
      final json = {
        'transaction': 'tx_bad_seq',
        'operations': ['op_underfunded', 'op_no_destination', 'op_line_full']
      };

      final codes = ExtrasResultCodes.fromJson(json);

      expect(codes.transactionResultCode, equals('tx_bad_seq'));
      expect(codes.operationsResultCodes, isNotNull);
      expect(codes.operationsResultCodes!.length, equals(3));
      expect(codes.operationsResultCodes![0], equals('op_underfunded'));
      expect(codes.operationsResultCodes![1], equals('op_no_destination'));
      expect(codes.operationsResultCodes![2], equals('op_line_full'));
    });

    test('parses result codes without operations', () {
      final json = {
        'transaction': 'tx_insufficient_balance',
      };

      final codes = ExtrasResultCodes.fromJson(json);

      expect(codes.transactionResultCode, equals('tx_insufficient_balance'));
      expect(codes.operationsResultCodes, isNull);
    });

    test('parses result codes with empty operations', () {
      final json = {
        'transaction': 'tx_failed',
        'operations': []
      };

      final codes = ExtrasResultCodes.fromJson(json);

      expect(codes.transactionResultCode, equals('tx_failed'));
      expect(codes.operationsResultCodes, isNotNull);
      expect(codes.operationsResultCodes!.length, equals(0));
    });
  });

  group('SubmitTransactionTimeoutResponseException', () {
    test('parses timeout exception with hash', () {
      final json = {
        'type': 'timeout',
        'title': 'Timeout',
        'status': 504,
        'detail': 'Transaction submission timeout',
        'extras': {'hash': 'timeout123abc'}
      };

      final exception =
          SubmitTransactionTimeoutResponseException.fromJson(json);

      expect(exception.type, equals('timeout'));
      expect(exception.title, equals('Timeout'));
      expect(exception.status, equals(504));
      expect(exception.detail, equals('Transaction submission timeout'));
      expect(exception.hash, equals('timeout123abc'));
    });

    test('parses timeout exception without hash', () {
      final json = {
        'type': 'timeout',
        'title': 'Timeout',
        'status': 504,
        'detail': 'Transaction submission timeout',
      };

      final exception =
          SubmitTransactionTimeoutResponseException.fromJson(json);

      expect(exception.type, equals('timeout'));
      expect(exception.hash, isNull);
    });

    test('toString returns formatted message', () {
      final exception = SubmitTransactionTimeoutResponseException(
        type: 'timeout',
        title: 'Timeout',
        status: 504,
        detail: 'Request timed out',
      );

      final str = exception.toString();

      expect(str, contains('Submit transaction timeout response from Horizon'));
      expect(str, contains('type: timeout'));
      expect(str, contains('title:Timeout'));
      expect(str, contains('status:504'));
      expect(str, contains('detail:Request timed out'));
    });
  });

  group('SubmitAsyncTransactionResponse', () {
    test('parses PENDING status', () {
      final json = {
        'tx_status': 'PENDING',
        'hash': 'async123',
      };

      final response =
          SubmitAsyncTransactionResponse.fromJson(json, 201);

      expect(response.txStatus, equals('PENDING'));
      expect(response.hash, equals('async123'));
      expect(response.httpStatusCode, equals(201));
      expect(response.txStatus,
          equals(SubmitAsyncTransactionResponse.txStatusPending));
    });

    test('parses ERROR status', () {
      final json = {
        'tx_status': 'ERROR',
        'hash': 'error123',
      };

      final response =
          SubmitAsyncTransactionResponse.fromJson(json, 400);

      expect(response.txStatus, equals('ERROR'));
      expect(response.hash, equals('error123'));
      expect(response.httpStatusCode, equals(400));
      expect(response.txStatus,
          equals(SubmitAsyncTransactionResponse.txStatusError));
    });

    test('parses DUPLICATE status', () {
      final json = {
        'tx_status': 'DUPLICATE',
        'hash': 'duplicate123',
      };

      final response =
          SubmitAsyncTransactionResponse.fromJson(json, 409);

      expect(response.txStatus, equals('DUPLICATE'));
      expect(response.hash, equals('duplicate123'));
      expect(response.httpStatusCode, equals(409));
      expect(response.txStatus,
          equals(SubmitAsyncTransactionResponse.txStatusDuplicate));
    });

    test('parses TRY_AGAIN_LATER status', () {
      final json = {
        'tx_status': 'TRY_AGAIN_LATER',
        'hash': 'retry123',
      };

      final response =
          SubmitAsyncTransactionResponse.fromJson(json, 503);

      expect(response.txStatus, equals('TRY_AGAIN_LATER'));
      expect(response.hash, equals('retry123'));
      expect(response.httpStatusCode, equals(503));
      expect(response.txStatus,
          equals(SubmitAsyncTransactionResponse.txStatusTryAgainLater));
    });
  });

  group('SubmitAsyncTransactionProblem', () {
    test('parses async transaction problem', () {
      final json = {
        'type': 'transaction_failed',
        'title': 'Transaction Failed',
        'status': 400,
        'detail': 'Transaction was malformed',
        'extras': {'envelope_xdr': 'XXXXX...'}
      };

      final problem = SubmitAsyncTransactionProblem.fromJson(json);

      expect(problem.type, equals('transaction_failed'));
      expect(problem.title, equals('Transaction Failed'));
      expect(problem.status, equals(400));
      expect(problem.detail, equals('Transaction was malformed'));
      expect(problem.extras, isNotNull);
      expect(problem.extras!['envelope_xdr'], equals('XXXXX...'));
    });

    test('toString returns formatted message', () {
      final problem = SubmitAsyncTransactionProblem(
        type: 'invalid_transaction',
        title: 'Invalid Transaction',
        status: 400,
        detail: 'Transaction signature invalid',
      );

      final str = problem.toString();

      expect(
          str, contains('Submit async transaction problem response from Horizon'));
      expect(str, contains('type: invalid_transaction'));
      expect(str, contains('title:Invalid Transaction'));
      expect(str, contains('status:400'));
      expect(str, contains('detail:Transaction signature invalid'));
    });
  });

  group('EffectResponse - AssetAmount', () {
    test('parses asset amount with native asset', () {
      final json = {
        'amount': '100.5000000',
        'asset': 'native',
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('100.5000000'));
      expect(assetAmount.asset, isNotNull);
      expect(assetAmount.asset, isA<AssetTypeNative>());
    });

    test('parses asset amount with credit asset', () {
      final json = {
        'amount': '250.0000000',
        'asset': 'USDC:GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5',
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('250.0000000'));
      expect(assetAmount.asset, isNotNull);
      expect(assetAmount.asset, isA<AssetTypeCreditAlphaNum>());
      final creditAsset = assetAmount.asset as AssetTypeCreditAlphaNum;
      expect(creditAsset.code, equals('USDC'));
    });

    test('parses asset amount with null asset', () {
      final json = {
        'amount': '10.0000000',
        'asset': null,
      };

      final assetAmount = AssetAmount.fromJson(json);

      expect(assetAmount.amount, equals('10.0000000'));
      expect(assetAmount.asset, isNull);
    });
  });
}
