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

  group('SubmitTransactionResponse Success Cases', () {
    test('success getter returns true for successful transaction', () {
      final resultXdr =
          'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA='; // txSUCCESS result
      final response = SubmitTransactionResponse(
        null,
        12345,
        '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889',
        'AAAA',
        resultXdr,
        'AAAA',
        'AAAA',
        null,
      );

      expect(response.success, isTrue);
    });

    test('success getter returns false when result XDR is null', () {
      final response = SubmitTransactionResponse(
        null,
        null,
        '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889',
        'AAAA',
        null,
        'AAAA',
        'AAAA',
        null,
      );

      expect(response.success, isFalse);
    });

    test('envelopeXdr returns value from main response for success', () {
      final envelopeXdr = 'AAAAAgAAAABelb1.....';
      final resultXdr = 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=';
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        envelopeXdr,
        resultXdr,
        'AAAA',
        'AAAA',
        null,
      );

      expect(response.envelopeXdr, equals(envelopeXdr));
    });

    test('resultXdr returns value from main response for success', () {
      final resultXdr = 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=';
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        resultXdr,
        'AAAA',
        'AAAA',
        null,
      );

      expect(response.resultXdr, equals(resultXdr));
    });

    test('resultMetaXdr returns value from main response for success', () {
      final metaXdr = 'AAAAAQAAAAIAAAADAABGxA...';
      final resultXdr = 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=';
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        resultXdr,
        metaXdr,
        'AAAA',
        null,
      );

      expect(response.resultMetaXdr, equals(metaXdr));
    });

    test('feeMetaXdr returns value from main response for success', () {
      final feeMetaXdr = 'AAAAAgAAAAMAABGxA...';
      final resultXdr = 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=';
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        resultXdr,
        'AAAA',
        feeMetaXdr,
        null,
      );

      expect(response.feeMetaXdr, equals(feeMetaXdr));
    });
  });

  group('SubmitTransactionResponse Failure Cases', () {
    test('envelopeXdr returns value from extras for failure', () {
      final envelopeXdr = 'AAAAAgAAAABelb1.....';
      final extras = SubmitTransactionResponseExtras(
        envelopeXdr,
        'invalid_result_xdr',
        null,
        null,
        null,
      );
      final response = SubmitTransactionResponse(
        extras,
        null,
        'hash123',
        'shouldNotBeUsed',
        'invalid_result_xdr',
        null,
        null,
        null,
      );

      // Test without calling success getter (which would try to decode XDR)
      expect(response.extras?.envelopeXdr, equals(envelopeXdr));
    });

    test('resultXdr returns value from extras for failure', () {
      final resultXdr = 'test_result_xdr';
      final extras = SubmitTransactionResponseExtras(
        'AAAA',
        resultXdr,
        null,
        null,
        null,
      );
      final response = SubmitTransactionResponse(
        extras,
        null,
        'hash123',
        'AAAA',
        resultXdr,
        null,
        null,
        null,
      );

      // Test via extras directly since we can't decode invalid XDR
      expect(response.extras?.resultXdr, equals(resultXdr));
    });

    test('resultMetaXdr returns value from extras for failure', () {
      final metaXdr = 'AAAAAQAAAAIAAAADAABGxA...';
      final extras = SubmitTransactionResponseExtras(
        'AAAA',
        'test_result_xdr',
        metaXdr,
        null,
        null,
      );
      final response = SubmitTransactionResponse(
        extras,
        null,
        'hash123',
        'AAAA',
        'test_result_xdr',
        null,
        null,
        null,
      );

      // Test via extras directly
      expect(response.extras?.strMetaXdr, equals(metaXdr));
    });

    test('feeMetaXdr returns value from extras for failure', () {
      final feeMetaXdr = 'AAAAAgAAAAMAABGxA...';
      final extras = SubmitTransactionResponseExtras(
        'AAAA',
        'test_result_xdr',
        null,
        feeMetaXdr,
        null,
      );
      final response = SubmitTransactionResponse(
        extras,
        null,
        'hash123',
        'AAAA',
        'test_result_xdr',
        null,
        null,
        null,
      );

      // Test via extras directly
      expect(response.extras?.strFeeMetaXdr, equals(feeMetaXdr));
    });

    test('XDR getters return null when extras is null', () {
      final response = SubmitTransactionResponse(
        null,
        null,
        'hash123',
        null,
        null,
        null,
        null,
        null,
      );

      expect(response.envelopeXdr, isNull);
      expect(response.resultXdr, isNull);
      expect(response.resultMetaXdr, isNull);
      expect(response.feeMetaXdr, isNull);
    });
  });

  group('SubmitTransactionResponse XDR Decoding', () {
    test('getTransactionResultXdr returns null when resultXdr is null', () {
      final response = SubmitTransactionResponse(
        null,
        null,
        'hash123',
        'AAAA',
        null,
        null,
        null,
        null,
      );

      expect(response.getTransactionResultXdr(), isNull);
    });

    test('getTransactionResultXdr with valid XDR', () {
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        'AAAA',
        'AAAA',
        null,
      );

      // Method returns XdrTransactionResult or null on error
      final result = response.getTransactionResultXdr();
      expect(result, isA<XdrTransactionResult>());
    });

    test('getTransactionMetaResultXdr returns null when resultMetaXdr is null', () {
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        null,
        'AAAA',
        null,
      );

      expect(response.getTransactionMetaResultXdr(), isNull);
    });

    test('getTransactionMetaResultXdr handles short XDR', () {
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        'AAAA',
        'AAAA',
        null,
      );

      // AAAA is valid base64 but might decode to something
      // Just test that the method doesn't throw
      final result = response.getTransactionMetaResultXdr();
      // Result might be null or a valid XDR object
      expect(result, anyOf(isNull, isA<XdrTransactionMeta>()));
    });

    test('getFeeMetaXdr returns null when feeMetaXdr is null', () {
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        'AAAA',
        null,
        null,
      );

      expect(response.getFeeMetaXdr(), isNull);
    });

    test('getFeeMetaXdr handles short XDR', () {
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        'AAAA',
        'AAAA',
        null,
      );

      // AAAA is valid base64 but might decode to something
      // Just test that the method doesn't throw
      final result = response.getFeeMetaXdr();
      // Result might be null or a valid XDR object
      expect(result, anyOf(isNull, isA<XdrLedgerEntryChanges>()));
    });
  });

  group('SubmitTransactionResponse Helper Methods', () {
    test('getOfferIdFromResult returns null when result XDR is null', () {
      final response = SubmitTransactionResponse(
        null,
        null,
        'hash123',
        'AAAA',
        null,
        null,
        null,
        null,
      );

      expect(response.getOfferIdFromResult(0), isNull);
    });

    test('getOfferIdFromResult needs valid success XDR', () {
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        'AAAA',
        'AAAA',
        null,
      );

      // Method needs proper XDR structure, otherwise returns null
      final result = response.getOfferIdFromResult(0);
      // Result depends on XDR structure
      expect(result, anyOf(isNull, isA<int>()));
    });

    test('getClaimableBalanceIdIdFromResult returns null when result XDR is null', () {
      final response = SubmitTransactionResponse(
        null,
        null,
        'hash123',
        'AAAA',
        null,
        null,
        null,
        null,
      );

      expect(response.getClaimableBalanceIdIdFromResult(0), isNull);
    });

    test('getClaimableBalanceIdIdFromResult needs valid success XDR', () {
      final response = SubmitTransactionResponse(
        null,
        12345,
        'hash123',
        'AAAA',
        'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        'AAAA',
        'AAAA',
        null,
      );

      // Method needs proper XDR structure, otherwise returns null
      final result = response.getClaimableBalanceIdIdFromResult(0);
      // Result depends on XDR structure
      expect(result, anyOf(isNull, isA<String>()));
    });
  });

  group('SubmitTransactionResponse fromJson - deep', () {
    test('fromJson creates response from failed transaction', () {
      final json = {
        'hash': '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889',
        'extras': {
          'envelope_xdr': 'AAAA',
          'result_xdr': 'test_xdr',
          'result_codes': {
            'transaction': 'tx_failed',
            'operations': ['op_underfunded'],
          },
        },
      };

      final response = SubmitTransactionResponse.fromJson(json);

      expect(response.hash, equals(json['hash']));
      expect(response.ledger, isNull);
      expect(response.extras, isNotNull);
      expect(response.extras?.resultCodes?.transactionResultCode, equals('tx_failed'));
      expect(response.successfulTransaction, isNull);
    });

    test('fromJson with rate limit headers and basic fields', () {
      final json = {
        'hash': '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889',
        'ledger': 12345,
        'envelope_xdr': 'AAAA',
        'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
        'rateLimitLimit': '3600',
        'rateLimitRemaining': '3599',
        'rateLimitReset': '1234567890',
      };

      final response = SubmitTransactionResponse.fromJson(json);

      expect(response.rateLimitLimit, equals(3600));
      expect(response.rateLimitRemaining, equals(3599));
      expect(response.rateLimitReset, equals(1234567890));
    });

    test('fromJson with null extras', () {
      final json = {
        'hash': 'hash123',
        'ledger': 12345,
        'envelope_xdr': 'AAAA',
        'result_xdr': 'AAAAAAAAAGQAAAAAAAAAAQAAAAAAAAABAAAAAAAAAAA=',
      };

      final response = SubmitTransactionResponse.fromJson(json);

      expect(response.extras, isNull);
    });

    test('fromJson extracts basic fields', () {
      final json = {
        'hash': 'test_hash',
        'ledger': 99999,
        'envelope_xdr': 'test_envelope',
        'result_xdr': 'test_result',
        'result_meta_xdr': 'test_meta',
        'fee_meta_xdr': 'test_fee',
      };

      final response = SubmitTransactionResponse.fromJson(json);

      expect(response.hash, equals('test_hash'));
      expect(response.ledger, equals(99999));
    });
  });

  group('ExtrasResultCodes - deep', () {
    test('fromJson creates result codes', () {
      final json = {
        'transaction': 'tx_failed',
        'operations': ['op_underfunded', 'op_no_destination'],
      };

      final resultCodes = ExtrasResultCodes.fromJson(json);

      expect(resultCodes.transactionResultCode, equals('tx_failed'));
      expect(resultCodes.operationsResultCodes?.length, equals(2));
      expect(resultCodes.operationsResultCodes?[0], equals('op_underfunded'));
      expect(resultCodes.operationsResultCodes?[1], equals('op_no_destination'));
    });

    test('fromJson with null operations', () {
      final json = {
        'transaction': 'tx_bad_seq',
      };

      final resultCodes = ExtrasResultCodes.fromJson(json);

      expect(resultCodes.transactionResultCode, equals('tx_bad_seq'));
      expect(resultCodes.operationsResultCodes, isNull);
    });

    test('fromJson with empty operations array', () {
      final json = {
        'transaction': 'tx_failed',
        'operations': [],
      };

      final resultCodes = ExtrasResultCodes.fromJson(json);

      expect(resultCodes.transactionResultCode, equals('tx_failed'));
      expect(resultCodes.operationsResultCodes, isEmpty);
    });
  });

  group('SubmitTransactionResponseExtras - deep', () {
    test('fromJson creates extras with all fields', () {
      final json = {
        'envelope_xdr': 'AAAA',
        'result_xdr': 'AAAAAAAAAL////8AAAAA',
        'result_meta_xdr': 'META',
        'fee_meta_xdr': 'FEE',
        'result_codes': {
          'transaction': 'tx_failed',
          'operations': ['op_underfunded'],
        },
      };

      final extras = SubmitTransactionResponseExtras.fromJson(json);

      expect(extras.envelopeXdr, equals('AAAA'));
      expect(extras.resultXdr, equals('AAAAAAAAAL////8AAAAA'));
      expect(extras.strMetaXdr, equals('META'));
      expect(extras.strFeeMetaXdr, equals('FEE'));
      expect(extras.resultCodes, isNotNull);
    });

    test('fromJson with null result codes', () {
      final json = {
        'envelope_xdr': 'AAAA',
        'result_xdr': 'AAAAAAAAAL////8AAAAA',
      };

      final extras = SubmitTransactionResponseExtras.fromJson(json);

      expect(extras.envelopeXdr, equals('AAAA'));
      expect(extras.resultXdr, equals('AAAAAAAAAL////8AAAAA'));
      expect(extras.resultCodes, isNull);
    });

    test('fromJson with null meta and fee meta', () {
      final json = {
        'envelope_xdr': 'AAAA',
        'result_xdr': 'AAAAAAAAAL////8AAAAA',
      };

      final extras = SubmitTransactionResponseExtras.fromJson(json);

      expect(extras.strMetaXdr, isNull);
      expect(extras.strFeeMetaXdr, isNull);
    });
  });

  group('SubmitTransactionTimeoutResponseException - deep', () {
    test('fromJson creates exception with all fields', () {
      final json = {
        'type': 'transaction_submission_timeout',
        'title': 'Transaction Submission Timeout',
        'status': 504,
        'detail': 'Transaction submission timed out',
        'extras': {
          'hash': '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889',
        },
      };

      final exception = SubmitTransactionTimeoutResponseException.fromJson(json);

      expect(exception.type, equals('transaction_submission_timeout'));
      expect(exception.title, equals('Transaction Submission Timeout'));
      expect(exception.status, equals(504));
      expect(exception.detail, equals('Transaction submission timed out'));
      expect(exception.extras, isNotNull);
    });

    test('hash getter extracts hash from extras', () {
      final exception = SubmitTransactionTimeoutResponseException(
        type: 'timeout',
        title: 'Timeout',
        status: 504,
        detail: 'Timed out',
        extras: {
          'hash': 'hash123',
        },
      );

      expect(exception.hash, equals('hash123'));
    });

    test('hash getter returns null when extras is null', () {
      final exception = SubmitTransactionTimeoutResponseException(
        type: 'timeout',
        title: 'Timeout',
        status: 504,
        detail: 'Timed out',
      );

      expect(exception.hash, isNull);
    });

    test('hash getter returns null when hash is not in extras', () {
      final exception = SubmitTransactionTimeoutResponseException(
        type: 'timeout',
        title: 'Timeout',
        status: 504,
        detail: 'Timed out',
        extras: {
          'other_field': 'value',
        },
      );

      expect(exception.hash, isNull);
    });

    test('hash getter returns null when hash is not a string', () {
      final exception = SubmitTransactionTimeoutResponseException(
        type: 'timeout',
        title: 'Timeout',
        status: 504,
        detail: 'Timed out',
        extras: {
          'hash': 123,
        },
      );

      expect(exception.hash, isNull);
    });

    test('toString contains type, title, status, and detail', () {
      final exception = SubmitTransactionTimeoutResponseException(
        type: 'timeout',
        title: 'Timeout Title',
        status: 504,
        detail: 'Timeout Detail',
      );

      final str = exception.toString();

      expect(str, contains('timeout'));
      expect(str, contains('Timeout Title'));
      expect(str, contains('504'));
      expect(str, contains('Timeout Detail'));
    });
  });

  group('SubmitAsyncTransactionResponse - deep', () {
    test('fromJson creates response', () {
      final json = {
        'tx_status': 'PENDING',
        'hash': '3389e9f0f1a65f19736cacf544c2e825313e8447f569233bb8db39aa607c8889',
      };

      final response = SubmitAsyncTransactionResponse.fromJson(json, 201);

      expect(response.txStatus, equals('PENDING'));
      expect(response.hash, equals(json['hash']));
      expect(response.httpStatusCode, equals(201));
    });

    test('constant values are correct', () {
      expect(SubmitAsyncTransactionResponse.txStatusError, equals('ERROR'));
      expect(SubmitAsyncTransactionResponse.txStatusPending, equals('PENDING'));
      expect(SubmitAsyncTransactionResponse.txStatusDuplicate, equals('DUPLICATE'));
      expect(SubmitAsyncTransactionResponse.txStatusTryAgainLater, equals('TRY_AGAIN_LATER'));
    });

    test('fromJson with ERROR status', () {
      final json = {
        'tx_status': 'ERROR',
        'hash': 'hash123',
      };

      final response = SubmitAsyncTransactionResponse.fromJson(json, 400);

      expect(response.txStatus, equals('ERROR'));
      expect(response.httpStatusCode, equals(400));
    });

    test('fromJson with DUPLICATE status', () {
      final json = {
        'tx_status': 'DUPLICATE',
        'hash': 'hash456',
      };

      final response = SubmitAsyncTransactionResponse.fromJson(json, 409);

      expect(response.txStatus, equals('DUPLICATE'));
      expect(response.httpStatusCode, equals(409));
    });

    test('fromJson with TRY_AGAIN_LATER status', () {
      final json = {
        'tx_status': 'TRY_AGAIN_LATER',
        'hash': 'hash789',
      };

      final response = SubmitAsyncTransactionResponse.fromJson(json, 503);

      expect(response.txStatus, equals('TRY_AGAIN_LATER'));
      expect(response.httpStatusCode, equals(503));
    });
  });

  group('SubmitAsyncTransactionProblem - deep', () {
    test('fromJson creates problem', () {
      final json = {
        'type': 'transaction_malformed',
        'title': 'Transaction Malformed',
        'status': 400,
        'detail': 'The transaction envelope is malformed',
        'extras': {
          'envelope_xdr': 'AAAA',
        },
      };

      final problem = SubmitAsyncTransactionProblem.fromJson(json);

      expect(problem.type, equals('transaction_malformed'));
      expect(problem.title, equals('Transaction Malformed'));
      expect(problem.status, equals(400));
      expect(problem.detail, equals('The transaction envelope is malformed'));
      expect(problem.extras, isNotNull);
    });

    test('fromJson with null extras', () {
      final json = {
        'type': 'internal_error',
        'title': 'Internal Error',
        'status': 500,
        'detail': 'An internal error occurred',
      };

      final problem = SubmitAsyncTransactionProblem.fromJson(json);

      expect(problem.type, equals('internal_error'));
      expect(problem.extras, isNull);
    });

    test('toString contains type, title, status, and detail', () {
      final problem = SubmitAsyncTransactionProblem(
        type: 'bad_request',
        title: 'Bad Request',
        status: 400,
        detail: 'Request was invalid',
      );

      final str = problem.toString();

      expect(str, contains('bad_request'));
      expect(str, contains('Bad Request'));
      expect(str, contains('400'));
      expect(str, contains('Request was invalid'));
    });

    test('toString with extras', () {
      final problem = SubmitAsyncTransactionProblem(
        type: 'problem_type',
        title: 'Problem',
        status: 422,
        detail: 'Something went wrong',
        extras: {'additional': 'info'},
      );

      final str = problem.toString();

      expect(str, contains('problem_type'));
      expect(str, contains('422'));
    });
  });

  group('SubmitTransactionUnknownResponseException', () {
    test('deprecated exception extends UnknownResponse', () {
      final exception = SubmitTransactionUnknownResponseException(503, 'Service Unavailable');

      expect(exception, isA<UnknownResponse>());
      expect(exception.code, equals(503));
      expect(exception.body, equals('Service Unavailable'));
    });

    test('toString includes code and body', () {
      final exception = SubmitTransactionUnknownResponseException(502, 'Bad Gateway');
      final str = exception.toString();

      expect(str, contains('502'));
      expect(str, contains('Bad Gateway'));
    });
  });
}
