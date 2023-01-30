import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class TestUtils {
  static void  resultDeAndEncodingTest(AbstractTransaction transaction, SubmitTransactionResponse response) {
    String metaXdrStr = response.resultMetaXdr!;
    XdrTransactionMeta meta = XdrTransactionMeta.fromBase64EncodedXdrString(metaXdrStr);
    assert(metaXdrStr == meta.toBase64EncodedXdrString());

    String envelopeXdrStr = response.envelopeXdr!;
    XdrTransactionEnvelope envelope = XdrTransactionEnvelope.fromEnvelopeXdrString(envelopeXdrStr);
    assert(envelopeXdrStr == envelope.toEnvelopeXdrBase64());

    String resultXdrStr = response.resultXdr!;
    XdrTransactionResult result = XdrTransactionResult.fromBase64EncodedXdrString(resultXdrStr);
    assert(resultXdrStr == result.toBase64EncodedXdrString());
  }
}
