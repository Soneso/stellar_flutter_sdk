import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('SubmitTransactionResponse', () {
    group('fromJson - successful transaction', () {
      test('parses successful transaction response', () {
        final json = {
          'hash': 'abc123def456',
          'ledger': 12345,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'result_meta_xdr': 'AAAAAwAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'successful': true,
          'id': 'abc123def456',
          'paging_token': '12345-1',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'source_account_sequence': 100,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'created_at': '2024-01-15T10:30:00Z',
          'memo_type': 'none',
          'signatures': ['sig1=='],
          '_links': {
            'self': {'href': '/transactions/abc123def456'},
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);

        expect(response.hash, equals('abc123def456'));
        expect(response.ledger, equals(12345));
        expect(response.envelopeXdr, equals('AAAAAgAAAAA='));
        expect(response.resultXdr, equals('AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA='));
        expect(response.resultMetaXdr, equals('AAAAAwAAAAA='));
        expect(response.feeMetaXdr, equals('AAAAAgAAAAA='));
        expect(response.extras, isNull);
        expect(response.successfulTransaction, isNotNull);
      });

      test('success getter returns true for successful transaction', () {
        final json = {
          'hash': 'success123',
          'ledger': 12345,
          'envelope_xdr': 'AAAAAgAAAAA=',
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'successful': true,
          'id': 'success123',
          'paging_token': '12345-1',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
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
            'self': {'href': '/transactions/success123'},
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);

        expect(response.success, isTrue);
      });
    });

    group('fromJson - failed transaction', () {
      test('parses failed transaction response with extras', () {
        final json = {
          'hash': null,
          'ledger': null,
          'successful': false,
          'extras': {
            'envelope_xdr': 'AAAAAgAAAABFAILED',
            'result_xdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=',
            'result_meta_xdr': null,
            'fee_meta_xdr': null,
            'result_codes': {
              'transaction': 'tx_failed',
              'operations': ['op_underfunded'],
            },
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);

        expect(response.hash, isNull);
        expect(response.ledger, isNull);
        expect(response.extras, isNotNull);
        expect(response.extras!.envelopeXdr, equals('AAAAAgAAAABFAILED'));
        expect(response.extras!.resultXdr, equals('AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA='));
        expect(response.extras!.resultCodes, isNotNull);
        expect(response.extras!.resultCodes!.transactionResultCode, equals('tx_failed'));
        expect(response.extras!.resultCodes!.operationsResultCodes, isNotNull);
        expect(response.extras!.resultCodes!.operationsResultCodes!.length, equals(1));
        expect(response.extras!.resultCodes!.operationsResultCodes![0], equals('op_underfunded'));
        expect(response.successfulTransaction, isNull);
      });

      test('success getter returns false for failed transaction', () {
        final json = {
          'successful': false,
          'extras': {
            'envelope_xdr': 'AAAAAgAAAAA=',
            'result_xdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=',
            'result_codes': {
              'transaction': 'tx_failed',
              'operations': ['op_underfunded'],
            },
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);

        expect(response.success, isFalse);
      });

      test('XDR getters return values from extras when failed', () {
        final json = {
          'successful': false,
          'extras': {
            'envelope_xdr': 'ExtrasEnvelopeXdr==',
            'result_xdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=',
            'result_meta_xdr': 'ExtrasMetaXdr==',
            'fee_meta_xdr': 'ExtrasFeeMetaXdr==',
            'result_codes': {
              'transaction': 'tx_failed',
            },
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);

        expect(response.envelopeXdr, equals('ExtrasEnvelopeXdr=='));
        expect(response.resultXdr, equals('AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA='));
        expect(response.resultMetaXdr, equals('ExtrasMetaXdr=='));
        expect(response.feeMetaXdr, equals('ExtrasFeeMetaXdr=='));
      });

      test('parses multiple operation result codes', () {
        final json = {
          'successful': false,
          'extras': {
            'envelope_xdr': 'AAAAAgAAAAA=',
            'result_xdr': 'AAAAAAAAAGT/////AAAAAQAAAAAAAAAB////+wAAAAA=',
            'result_codes': {
              'transaction': 'tx_failed',
              'operations': ['op_success', 'op_underfunded', 'op_line_full'],
            },
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);

        expect(response.extras!.resultCodes!.operationsResultCodes!.length, equals(3));
        expect(response.extras!.resultCodes!.operationsResultCodes![0], equals('op_success'));
        expect(response.extras!.resultCodes!.operationsResultCodes![1], equals('op_underfunded'));
        expect(response.extras!.resultCodes!.operationsResultCodes![2], equals('op_line_full'));
      });
    });

    group('XDR decoding methods', () {
      test('getTransactionResultXdr decodes successfully', () {
        final json = {
          'hash': 'abc123',
          'ledger': 12345,
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'successful': true,
          'id': 'abc123',
          'paging_token': '12345-1',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'source_account_sequence': 100,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'created_at': '2024-01-15T10:30:00Z',
          'envelope_xdr': 'AAAAAgAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/abc123'},
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);
        final xdrResult = response.getTransactionResultXdr();

        expect(xdrResult, isNotNull);
      });

      test('getTransactionResultXdr handles invalid XDR gracefully', () {
        final json = {
          'successful': false,
          'extras': {
            'envelope_xdr': 'AAAAAgAAAAA=',
            'result_xdr': 'InvalidBase64!@#\$',
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);
        final xdrResult = response.getTransactionResultXdr();

        expect(xdrResult, isNull);
      });

      test('getTransactionMetaResultXdr returns null when result_meta_xdr is null', () {
        final json = {
          'hash': 'abc123',
          'ledger': 12345,
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'result_meta_xdr': null,
          'successful': true,
          'id': 'abc123',
          'paging_token': '12345-1',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'source_account_sequence': 100,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'created_at': '2024-01-15T10:30:00Z',
          'envelope_xdr': 'AAAAAgAAAAA=',
          'fee_meta_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/abc123'},
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);
        final metaXdr = response.getTransactionMetaResultXdr();

        expect(metaXdr, isNull);
      });

      test('getFeeMetaXdr handles invalid XDR gracefully', () {
        final json = {
          'hash': 'abc123',
          'ledger': 12345,
          'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
          'fee_meta_xdr': 'InvalidBase64!@#\$',
          'successful': true,
          'id': 'abc123',
          'paging_token': '12345-1',
          'source_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'fee_account': 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7',
          'source_account_sequence': 100,
          'max_fee': 1000,
          'fee_charged': 100,
          'operation_count': 1,
          'created_at': '2024-01-15T10:30:00Z',
          'envelope_xdr': 'AAAAAgAAAAA=',
          'memo_type': 'none',
          'signatures': [],
          '_links': {
            'self': {'href': '/transactions/abc123'},
          },
        };

        final response = SubmitTransactionResponse.fromJson(json);
        final feeMetaXdr = response.getFeeMetaXdr();

        expect(feeMetaXdr, isNull);
      });
    });

    group('ExtrasResultCodes', () {
      test('parses transaction and operation result codes', () {
        final json = {
          'transaction': 'tx_bad_seq',
          'operations': ['op_success', 'op_no_destination'],
        };

        final resultCodes = ExtrasResultCodes.fromJson(json);

        expect(resultCodes.transactionResultCode, equals('tx_bad_seq'));
        expect(resultCodes.operationsResultCodes, isNotNull);
        expect(resultCodes.operationsResultCodes!.length, equals(2));
        expect(resultCodes.operationsResultCodes![0], equals('op_success'));
        expect(resultCodes.operationsResultCodes![1], equals('op_no_destination'));
      });

      test('handles null operations array', () {
        final json = {
          'transaction': 'tx_insufficient_balance',
          'operations': null,
        };

        final resultCodes = ExtrasResultCodes.fromJson(json);

        expect(resultCodes.transactionResultCode, equals('tx_insufficient_balance'));
        expect(resultCodes.operationsResultCodes, isNull);
      });

      test('parses various transaction error codes', () {
        final errorCodes = [
          'tx_failed',
          'tx_too_early',
          'tx_too_late',
          'tx_missing_operation',
          'tx_bad_seq',
          'tx_bad_auth',
          'tx_insufficient_balance',
          'tx_no_source_account',
          'tx_insufficient_fee',
          'tx_bad_auth_extra',
          'tx_internal_error',
        ];

        for (final code in errorCodes) {
          final json = {
            'transaction': code,
          };

          final resultCodes = ExtrasResultCodes.fromJson(json);

          expect(resultCodes.transactionResultCode, equals(code));
        }
      });
    });

    group('SubmitTransactionResponseExtras', () {
      test('parses complete extras object', () {
        final json = {
          'envelope_xdr': 'EnvelopeXdrValue==',
          'result_xdr': 'ResultXdrValue==',
          'result_meta_xdr': 'MetaXdrValue==',
          'fee_meta_xdr': 'FeeMetaXdrValue==',
          'result_codes': {
            'transaction': 'tx_failed',
            'operations': ['op_underfunded'],
          },
        };

        final extras = SubmitTransactionResponseExtras.fromJson(json);

        expect(extras.envelopeXdr, equals('EnvelopeXdrValue=='));
        expect(extras.resultXdr, equals('ResultXdrValue=='));
        expect(extras.strMetaXdr, equals('MetaXdrValue=='));
        expect(extras.strFeeMetaXdr, equals('FeeMetaXdrValue=='));
        expect(extras.resultCodes, isNotNull);
      });

      test('handles null result_codes', () {
        final json = {
          'envelope_xdr': 'EnvelopeXdr==',
          'result_xdr': 'ResultXdr==',
          'result_meta_xdr': null,
          'fee_meta_xdr': null,
          'result_codes': null,
        };

        final extras = SubmitTransactionResponseExtras.fromJson(json);

        expect(extras.envelopeXdr, equals('EnvelopeXdr=='));
        expect(extras.resultXdr, equals('ResultXdr=='));
        expect(extras.strMetaXdr, isNull);
        expect(extras.strFeeMetaXdr, isNull);
        expect(extras.resultCodes, isNull);
      });
    });

    group('SubmitTransactionTimeoutResponseException', () {
      test('parses timeout exception correctly', () {
        final json = {
          'type': 'transaction_submission_timeout',
          'title': 'Transaction Submission Timeout',
          'status': 504,
          'detail': 'Transaction submission timed out.',
          'extras': {
            'hash': 'timeouthash123',
          },
        };

        final exception = SubmitTransactionTimeoutResponseException.fromJson(json);

        expect(exception.type, equals('transaction_submission_timeout'));
        expect(exception.title, equals('Transaction Submission Timeout'));
        expect(exception.status, equals(504));
        expect(exception.detail, equals('Transaction submission timed out.'));
        expect(exception.hash, equals('timeouthash123'));
      });

      test('hash getter returns null when not in extras', () {
        final json = {
          'type': 'transaction_submission_timeout',
          'title': 'Transaction Submission Timeout',
          'status': 504,
          'detail': 'Transaction submission timed out.',
          'extras': null,
        };

        final exception = SubmitTransactionTimeoutResponseException.fromJson(json);

        expect(exception.hash, isNull);
      });

      test('hash getter returns null when extras has no hash key', () {
        final json = {
          'type': 'transaction_submission_timeout',
          'title': 'Transaction Submission Timeout',
          'status': 504,
          'detail': 'Transaction submission timed out.',
          'extras': {
            'other_field': 'value',
          },
        };

        final exception = SubmitTransactionTimeoutResponseException.fromJson(json);

        expect(exception.hash, isNull);
      });

      test('toString returns formatted error message', () {
        final exception = SubmitTransactionTimeoutResponseException(
          type: 'timeout_type',
          title: 'Timeout Title',
          status: 504,
          detail: 'Timeout detail message',
        );

        final message = exception.toString();

        expect(message, contains('timeout_type'));
        expect(message, contains('Timeout Title'));
        expect(message, contains('504'));
        expect(message, contains('Timeout detail message'));
      });
    });

    group('SubmitAsyncTransactionResponse', () {
      test('parses async response with PENDING status', () {
        final json = {
          'tx_status': 'PENDING',
          'hash': 'asynchash123',
        };

        final response = SubmitAsyncTransactionResponse.fromJson(json, 200);

        expect(response.txStatus, equals('PENDING'));
        expect(response.hash, equals('asynchash123'));
        expect(response.httpStatusCode, equals(200));
      });

      test('parses async response with ERROR status', () {
        final json = {
          'tx_status': 'ERROR',
          'hash': 'errorhash456',
        };

        final response = SubmitAsyncTransactionResponse.fromJson(json, 400);

        expect(response.txStatus, equals('ERROR'));
        expect(response.hash, equals('errorhash456'));
        expect(response.httpStatusCode, equals(400));
      });

      test('parses async response with DUPLICATE status', () {
        final json = {
          'tx_status': 'DUPLICATE',
          'hash': 'duphash789',
        };

        final response = SubmitAsyncTransactionResponse.fromJson(json, 409);

        expect(response.txStatus, equals('DUPLICATE'));
        expect(response.hash, equals('duphash789'));
        expect(response.httpStatusCode, equals(409));
      });

      test('parses async response with TRY_AGAIN_LATER status', () {
        final json = {
          'tx_status': 'TRY_AGAIN_LATER',
          'hash': 'retryhash101',
        };

        final response = SubmitAsyncTransactionResponse.fromJson(json, 503);

        expect(response.txStatus, equals('TRY_AGAIN_LATER'));
        expect(response.hash, equals('retryhash101'));
        expect(response.httpStatusCode, equals(503));
      });

      test('verifies status constants are correct', () {
        expect(SubmitAsyncTransactionResponse.txStatusError, equals('ERROR'));
        expect(SubmitAsyncTransactionResponse.txStatusPending, equals('PENDING'));
        expect(SubmitAsyncTransactionResponse.txStatusDuplicate, equals('DUPLICATE'));
        expect(SubmitAsyncTransactionResponse.txStatusTryAgainLater, equals('TRY_AGAIN_LATER'));
      });
    });

    group('SubmitAsyncTransactionProblem', () {
      test('parses async transaction problem correctly', () {
        final json = {
          'type': 'transaction_submission_failed',
          'title': 'Transaction Submission Failed',
          'status': 400,
          'detail': 'The transaction submission failed for some reason.',
          'extras': {
            'envelope_xdr': 'SomeXdrData==',
            'result_xdr': 'SomeResultXdr==',
          },
        };

        final problem = SubmitAsyncTransactionProblem.fromJson(json);

        expect(problem.type, equals('transaction_submission_failed'));
        expect(problem.title, equals('Transaction Submission Failed'));
        expect(problem.status, equals(400));
        expect(problem.detail, equals('The transaction submission failed for some reason.'));
        expect(problem.extras, isNotNull);
        expect(problem.extras!['envelope_xdr'], equals('SomeXdrData=='));
      });

      test('handles null extras', () {
        final json = {
          'type': 'problem_type',
          'title': 'Problem Title',
          'status': 500,
          'detail': 'Problem detail',
          'extras': null,
        };

        final problem = SubmitAsyncTransactionProblem.fromJson(json);

        expect(problem.extras, isNull);
      });

      test('toString returns formatted error message', () {
        final problem = SubmitAsyncTransactionProblem(
          type: 'async_problem',
          title: 'Async Problem Title',
          status: 400,
          detail: 'Async problem detail',
        );

        final message = problem.toString();

        expect(message, contains('async_problem'));
        expect(message, contains('Async Problem Title'));
        expect(message, contains('400'));
        expect(message, contains('Async problem detail'));
      });
    });
  });
}
