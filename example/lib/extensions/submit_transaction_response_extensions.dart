import 'dart:convert';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'xdr_operation_result_extensions.dart';

extension SubmitTransactionResponseX on SubmitTransactionResponse {
  void printResult() {
    if (success) {
      print('Transaction submitted successfully!');
      final results = resultXdrDecoded.result?.results as List?;
      if (results == null) {
        return;
      }
      for (var result in results) {
        if (result is XdrOperationResult) {
          result.printResult();
        }
      }
    } else {
      print('Transaction failed!');
      if (extras?.resultCodes?.transactionResultCode?.isNotEmpty ?? false) {
        print(extras?.resultCodes?.transactionResultCode);
      }
      if (extras?.resultCodes?.operationsResultCodes?.isNotEmpty ?? false) {
        extras?.resultCodes?.operationsResultCodes?.forEach(print);
      }
    }
  }

  XdrTransactionResult get resultXdrDecoded {
    final result = XdrTransactionResult.decode(
      XdrDataInputStream(
        base64Decode(resultXdr!),
      ),
    );
    return result;
  }
}
