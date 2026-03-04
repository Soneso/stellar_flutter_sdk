@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('sep-11: Quick Example - XDR to Txrep', () {
    // Snippet from sep-11.md "Quick Example"
    String xdrBase64 =
        'AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw=';

    String txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdrBase64);

    expect(txRep, contains('type: ENVELOPE_TYPE_TX'));
    expect(txRep,
        contains('tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN'));
    expect(txRep, contains('tx.fee: 100'));
    expect(txRep, contains('tx.seqNum: 46489056724385793'));
    expect(txRep, contains('tx.memo.type: MEMO_TEXT'));
    expect(txRep, contains('tx.memo.text: "Enjoy this transaction"'));
    expect(txRep, contains('tx.operations[0].body.type: PAYMENT'));
    expect(txRep, contains('tx.operations[0].body.paymentOp.amount: 400004000'));
  });

  test('sep-11: Fee bump transaction XDR to Txrep', () {
    // Snippet from sep-11.md "Fee bump transaction"
    String feeBumpXdr =
        'AAAABQAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAAAAGQAAAAAgAAAAAx5Qe+wF5jJp3kYrOZ2zBOQOcTHjtRBuR/GrBTLYydyQAAAGQAAVlhAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAVoZWxsbwAAAAAAAAEAAAAAAAAAAAAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAL68IAAAAAAAAAAAEtjJ3JAAAAQFzU5qFDIaZRUzUxf0BrRO2abx0PuMn3WKM7o8NXZvmB7K0zvS+HBlmDo2P/M3IZpF5Riax21neE0N9/WiHRuAoAAAAAAAAAAdoh7ugAAABARiKZWxfy8ZOPRj6yZRTKXAp1Aw6SoEn5OvnFbOmVztZtSRUaVOaCnBpdDWFBNJ6xBwsm7lMxvomMaOyNM3T/Bg==';

    String txRep = TxRep.fromTransactionEnvelopeXdrBase64(feeBumpXdr);

    expect(txRep, contains('type: ENVELOPE_TYPE_TX_FEE_BUMP'));
    expect(txRep, contains('feeBump.tx.feeSource:'));
    expect(txRep, contains('feeBump.tx.fee: 400'));
    expect(txRep, contains('feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX'));
    expect(txRep, contains('feeBump.tx.innerTx.tx.fee: 100'));
  });

  test('sep-11: Txrep to XDR conversion', () {
    // Snippet from sep-11.md "Converting Txrep to XDR"
    String txRep = '''type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN
tx.fee: 100
tx.seqNum: 46489056724385793
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 1535756672
tx.cond.timeBounds.maxTime: 1567292672
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: GBAF6NXN3DHSF357QBZLTBNWUTABKUODJXJYYE32ZDKA2QBM2H33IK6O
tx.operations[0].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operations[0].body.paymentOp.amount: 400004000
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 4aa07ed0
signatures[0].signature: defb4f1fad1c279327b55af184fdcddf73f4f7a8cb40e7e534a71d73a05124ba369db7a6d31b47cafd118592246a8575e6c249ab94ec3768dedb6292221ce50c''';

    String xdrBase64 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

    expect(xdrBase64, isNotEmpty);
    // Verify it's valid base64 that can be parsed back
    String roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(xdrBase64);
    expect(roundTrip, contains('tx.fee: 100'));
    expect(roundTrip, contains('tx.memo.text: "Enjoy this transaction"'));
  });

  test('sep-11: Round-trip conversion', () {
    // Snippet from sep-11.md "Round-trip conversion"
    String originalXdr =
        'AAAAAgAAAAArFkuQQ4QuQY6SkLc5xxSdwpFOvl7VqKVvrfkPSqB+0AAAAGQApSmNAAAAAQAAAAEAAAAAW4nJgAAAAABdav0AAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAABAAAAAAAAAAEAAAAAQF827djPIu+/gHK5hbakwBVRw03TjBN6yNQNQCzR97QAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tCwAAAAAX15OgAAAAAAAAAAFKoH7QAAAAQN77Tx+tHCeTJ7Va8YT9zd9z9Peoy0Dn5TSnHXOgUSS6Np23ptMbR8r9EYWSJGqFdebCSauU7Ddo3ttikiIc5Qw=';

    // Convert XDR -> Txrep -> XDR
    String txRep = TxRep.fromTransactionEnvelopeXdrBase64(originalXdr);
    String reconstructedXdr =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

    expect(originalXdr, equals(reconstructedXdr));
  });

  test('sep-11: Error handling - invalid base64', () {
    // Snippet from sep-11.md "Error handling"
    expect(
      () => TxRep.fromTransactionEnvelopeXdrBase64('not-valid-base64!'),
      throwsA(anything),
    );
  });

  test('sep-11: Error handling - invalid Txrep', () {
    expect(
      () => TxRep.transactionEnvelopeXdrBase64FromTxRep('this is not valid txrep'),
      throwsA(anything),
    );
  });

  test('sep-11: Error handling - missing required fields', () {
    String incompleteTxrep = '''type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAVRMS4QIOCC4QMOSKILOOOHCSO4FEKOXZPNLKFFN6W7SD2KUB7NBPLN''';

    expect(
      () => TxRep.transactionEnvelopeXdrBase64FromTxRep(incompleteTxrep),
      throwsA(anything),
    );
  });

  test('sep-11: Error handling - invalid account ID', () {
    String badAccountTxrep = '''type: ENVELOPE_TYPE_TX
tx.sourceAccount: NOT_A_VALID_ACCOUNT
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0''';

    expect(
      () => TxRep.transactionEnvelopeXdrBase64FromTxRep(badAccountTxrep),
      throwsA(anything),
    );
  });

  test('sep-11: Working with amounts', () {
    // Snippet from sep-11.md "Working with amounts"
    int stroops = 400004000;
    double displayAmount = stroops / 10000000;
    expect(displayAmount, closeTo(40.0004, 0.00001));

    double amount = 25.5;
    int stroopsValue = (amount * 10000000).toInt();
    expect(stroopsValue, equals(255000000));

    String formatAmount(int stroops) {
      return (stroops / 10000000).toStringAsFixed(7);
    }

    expect(formatAmount(400004000), equals('40.0004000'));
  });

  test('sep-11: Fee bump Txrep to XDR round-trip', () {
    // Verify fee bump XDR round-trips correctly
    String feeBumpXdr =
        'AAAABQAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAAAAGQAAAAAgAAAAAx5Qe+wF5jJp3kYrOZ2zBOQOcTHjtRBuR/GrBTLYydyQAAAGQAAVlhAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAVoZWxsbwAAAAAAAAEAAAAAAAAAAAAAAABkfT0dQuoYYNgStwXg4RJV62+W1uApFc4NpBdc2iHu6AAAAAAL68IAAAAAAAAAAAEtjJ3JAAAAQFzU5qFDIaZRUzUxf0BrRO2abx0PuMn3WKM7o8NXZvmB7K0zvS+HBlmDo2P/M3IZpF5Riax21neE0N9/WiHRuAoAAAAAAAAAAdoh7ugAAABARiKZWxfy8ZOPRj6yZRTKXAp1Aw6SoEn5OvnFbOmVztZtSRUaVOaCnBpdDWFBNJ6xBwsm7lMxvomMaOyNM3T/Bg==';

    String txRep = TxRep.fromTransactionEnvelopeXdrBase64(feeBumpXdr);
    String reconstructed = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);

    expect(feeBumpXdr, equals(reconstructed));
  });
}
