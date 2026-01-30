import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('FeeStatsResponse', () {
    test('parses JSON with all fields correctly', () {
      final json = {
        'last_ledger': '12345',
        'last_ledger_base_fee': '100',
        'ledger_capacity_usage': '0.75',
        'fee_charged': {
          'max': '1000',
          'min': '100',
          'mode': '100',
          'p10': '100',
          'p20': '100',
          'p30': '100',
          'p40': '100',
          'p50': '100',
          'p60': '200',
          'p70': '300',
          'p80': '400',
          'p90': '500',
          'p95': '750',
          'p99': '1000'
        },
        'max_fee': {
          'max': '10000',
          'min': '1000',
          'mode': '5000',
          'p10': '1000',
          'p20': '2000',
          'p30': '3000',
          'p40': '4000',
          'p50': '5000',
          'p60': '6000',
          'p70': '7000',
          'p80': '8000',
          'p90': '9000',
          'p95': '9500',
          'p99': '10000'
        }
      };

      final response = FeeStatsResponse.fromJson(json);

      expect(response.lastLedger, equals('12345'));
      expect(response.lastLedgerBaseFee, equals('100'));
      expect(response.lastLedgerCapacityUsage, equals('0.75'));
    });

    test('parses fee charged statistics correctly', () {
      final json = {
        'last_ledger': '12345',
        'last_ledger_base_fee': '100',
        'ledger_capacity_usage': '0.5',
        'fee_charged': {
          'max': '500',
          'min': '100',
          'mode': '100',
          'p10': '100',
          'p20': '100',
          'p30': '100',
          'p40': '100',
          'p50': '100',
          'p60': '100',
          'p70': '100',
          'p80': '200',
          'p90': '300',
          'p95': '400',
          'p99': '500'
        },
        'max_fee': {
          'max': '10000',
          'min': '1000',
          'mode': '5000',
          'p10': '1000',
          'p20': '2000',
          'p30': '3000',
          'p40': '4000',
          'p50': '5000',
          'p60': '6000',
          'p70': '7000',
          'p80': '8000',
          'p90': '9000',
          'p95': '9500',
          'p99': '10000'
        }
      };

      final response = FeeStatsResponse.fromJson(json);

      expect(response.feeCharged.max, equals('500'));
      expect(response.feeCharged.min, equals('100'));
      expect(response.feeCharged.mode, equals('100'));
      expect(response.feeCharged.p50, equals('100'));
      expect(response.feeCharged.p95, equals('400'));
    });

    test('parses max fee statistics correctly', () {
      final json = {
        'last_ledger': '12345',
        'last_ledger_base_fee': '100',
        'ledger_capacity_usage': '0.5',
        'fee_charged': {
          'max': '500',
          'min': '100',
          'mode': '100',
          'p10': '100',
          'p20': '100',
          'p30': '100',
          'p40': '100',
          'p50': '100',
          'p60': '100',
          'p70': '100',
          'p80': '200',
          'p90': '300',
          'p95': '400',
          'p99': '500'
        },
        'max_fee': {
          'max': '20000',
          'min': '2000',
          'mode': '10000',
          'p10': '2000',
          'p20': '3000',
          'p30': '4000',
          'p40': '5000',
          'p50': '10000',
          'p60': '12000',
          'p70': '14000',
          'p80': '16000',
          'p90': '18000',
          'p95': '19000',
          'p99': '20000'
        }
      };

      final response = FeeStatsResponse.fromJson(json);

      expect(response.maxFee.max, equals('20000'));
      expect(response.maxFee.min, equals('2000'));
      expect(response.maxFee.mode, equals('10000'));
      expect(response.maxFee.p50, equals('10000'));
      expect(response.maxFee.p95, equals('19000'));
    });
  });

  group('FeeChargedResponse', () {
    test('parses all percentiles correctly', () {
      final json = {
        'max': '1000',
        'min': '100',
        'mode': '100',
        'p10': '100',
        'p20': '150',
        'p30': '200',
        'p40': '250',
        'p50': '300',
        'p60': '400',
        'p70': '500',
        'p80': '600',
        'p90': '750',
        'p95': '875',
        'p99': '1000'
      };

      final feeCharged = FeeChargedResponse.fromJson(json);

      expect(feeCharged.max, equals('1000'));
      expect(feeCharged.min, equals('100'));
      expect(feeCharged.mode, equals('100'));
      expect(feeCharged.p10, equals('100'));
      expect(feeCharged.p20, equals('150'));
      expect(feeCharged.p30, equals('200'));
      expect(feeCharged.p40, equals('250'));
      expect(feeCharged.p50, equals('300'));
      expect(feeCharged.p60, equals('400'));
      expect(feeCharged.p70, equals('500'));
      expect(feeCharged.p80, equals('600'));
      expect(feeCharged.p90, equals('750'));
      expect(feeCharged.p95, equals('875'));
      expect(feeCharged.p99, equals('1000'));
    });

    test('handles minimum fee network scenario', () {
      final json = {
        'max': '100',
        'min': '100',
        'mode': '100',
        'p10': '100',
        'p20': '100',
        'p30': '100',
        'p40': '100',
        'p50': '100',
        'p60': '100',
        'p70': '100',
        'p80': '100',
        'p90': '100',
        'p95': '100',
        'p99': '100'
      };

      final feeCharged = FeeChargedResponse.fromJson(json);

      expect(feeCharged.min, equals('100'));
      expect(feeCharged.max, equals('100'));
      expect(feeCharged.p50, equals('100'));
      expect(feeCharged.p95, equals('100'));
    });

    test('handles high congestion scenario', () {
      final json = {
        'max': '10000',
        'min': '100',
        'mode': '5000',
        'p10': '100',
        'p20': '500',
        'p30': '1000',
        'p40': '2000',
        'p50': '5000',
        'p60': '6000',
        'p70': '7000',
        'p80': '8000',
        'p90': '9000',
        'p95': '9500',
        'p99': '10000'
      };

      final feeCharged = FeeChargedResponse.fromJson(json);

      expect(feeCharged.p95, equals('9500'));
      expect(feeCharged.p99, equals('10000'));
      expect(feeCharged.max, equals('10000'));
    });
  });

  group('MaxFeeResponse', () {
    test('parses all percentiles correctly', () {
      final json = {
        'max': '100000',
        'min': '10000',
        'mode': '50000',
        'p10': '10000',
        'p20': '20000',
        'p30': '30000',
        'p40': '40000',
        'p50': '50000',
        'p60': '60000',
        'p70': '70000',
        'p80': '80000',
        'p90': '90000',
        'p95': '95000',
        'p99': '100000'
      };

      final maxFee = MaxFeeResponse.fromJson(json);

      expect(maxFee.max, equals('100000'));
      expect(maxFee.min, equals('10000'));
      expect(maxFee.mode, equals('50000'));
      expect(maxFee.p10, equals('10000'));
      expect(maxFee.p20, equals('20000'));
      expect(maxFee.p30, equals('30000'));
      expect(maxFee.p40, equals('40000'));
      expect(maxFee.p50, equals('50000'));
      expect(maxFee.p60, equals('60000'));
      expect(maxFee.p70, equals('70000'));
      expect(maxFee.p80, equals('80000'));
      expect(maxFee.p90, equals('90000'));
      expect(maxFee.p95, equals('95000'));
      expect(maxFee.p99, equals('100000'));
    });

    test('handles conservative max fee scenario', () {
      final json = {
        'max': '5000',
        'min': '1000',
        'mode': '1000',
        'p10': '1000',
        'p20': '1000',
        'p30': '1000',
        'p40': '1000',
        'p50': '1000',
        'p60': '2000',
        'p70': '3000',
        'p80': '4000',
        'p90': '5000',
        'p95': '5000',
        'p99': '5000'
      };

      final maxFee = MaxFeeResponse.fromJson(json);

      expect(maxFee.mode, equals('1000'));
      expect(maxFee.p50, equals('1000'));
      expect(maxFee.max, equals('5000'));
    });
  });
}
