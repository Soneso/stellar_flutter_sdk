import 'dart:convert';

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

extension SubmitTransactionResponseExtrasX on SubmitTransactionResponseExtras {
  XdrTransactionResult get resultXdrDecoded {
    final result = XdrTransactionResult.decode(
      XdrDataInputStream(
        base64Decode(resultXdr!),
      ),
    );
    return result;
  }
}
