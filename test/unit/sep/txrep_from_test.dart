import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('TxRep fromTxRep Parsing Tests', () {
    late KeyPair sourceKeyPair;
    late KeyPair destinationKeyPair;
    late String sourceAccountId;
    late String destinationAccountId;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed('SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      sourceAccountId = sourceKeyPair.accountId;
      destinationKeyPair = KeyPair.fromSecretSeed('SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      destinationAccountId = destinationKeyPair.accountId;
    });

    group('Basic Transaction Parsing', () {
      test('Parse simple payment transaction', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('PAYMENT'));
        expect(roundTrip, contains(sourceAccountId));
        expect(roundTrip, contains(destinationAccountId));
      });

      test('Parse transaction with CREATE_ACCOUNT operation', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_ACCOUNT
tx.operations[0].body.createAccountOp.destination: $destinationAccountId
tx.operations[0].body.createAccountOp.startingBalance: 10000000000 (1000.0000000 XLM)
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('CREATE_ACCOUNT'));
      });
    });

    group('MANAGE_DATA Operation Parsing', () {
      test('Parse MANAGE_DATA with value', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: MANAGE_DATA
tx.operations[0].body.manageDataOp.dataName: "test_key"
tx.operations[0].body.manageDataOp.dataValue._present: true
tx.operations[0].body.manageDataOp.dataValue: 746573745f76616c7565
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('MANAGE_DATA'));
        expect(roundTrip, contains('test_key'));
      });

      test('Parse MANAGE_DATA delete (null value)', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: MANAGE_DATA
tx.operations[0].body.manageDataOp.dataName: "test_key"
tx.operations[0].body.manageDataOp.dataValue._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('MANAGE_DATA'));
        expect(roundTrip, contains('test_key'));
        expect(roundTrip, contains('dataValue._present: false'));
      });
    });

    group('SET_OPTIONS Operation Parsing', () {
      test('Parse SET_OPTIONS with inflation destination only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: true
tx.operations[0].body.setOptionsOp.inflationDest: $destinationAccountId
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains(destinationAccountId));
      });

      test('Parse SET_OPTIONS with clearFlags only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: true
tx.operations[0].body.setOptionsOp.clearFlags: 1
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('clearFlags: 1'));
      });

      test('Parse SET_OPTIONS with setFlags only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: true
tx.operations[0].body.setOptionsOp.setFlags: 2
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('setFlags: 2'));
      });

      test('Parse SET_OPTIONS with masterWeight only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: true
tx.operations[0].body.setOptionsOp.masterWeight: 10
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('masterWeight: 10'));
      });

      test('Parse SET_OPTIONS with lowThreshold only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: true
tx.operations[0].body.setOptionsOp.lowThreshold: 5
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('lowThreshold: 5'));
      });

      test('Parse SET_OPTIONS with medThreshold only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: true
tx.operations[0].body.setOptionsOp.medThreshold: 7
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('medThreshold: 7'));
      });

      test('Parse SET_OPTIONS with highThreshold only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: true
tx.operations[0].body.setOptionsOp.highThreshold: 9
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('highThreshold: 9'));
      });

      test('Parse SET_OPTIONS with homeDomain only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: true
tx.operations[0].body.setOptionsOp.homeDomain: "example.com"
tx.operations[0].body.setOptionsOp.signer._present: false
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('SET_OPTIONS'));
        expect(roundTrip, contains('example.com'));
      });
    });

    group('ALLOW_TRUST Operation Parsing', () {
      test('Parse ALLOW_TRUST with authorize = 0', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: ALLOW_TRUST
tx.operations[0].body.allowTrustOp.trustor: $destinationAccountId
tx.operations[0].body.allowTrustOp.asset: USD
tx.operations[0].body.allowTrustOp.authorize: 0
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('ALLOW_TRUST'));
        expect(roundTrip, contains('authorize: 0'));
      });

      test('Parse ALLOW_TRUST with authorize = 1', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: ALLOW_TRUST
tx.operations[0].body.allowTrustOp.trustor: $destinationAccountId
tx.operations[0].body.allowTrustOp.asset: USD
tx.operations[0].body.allowTrustOp.authorize: 1
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('ALLOW_TRUST'));
        expect(roundTrip, contains('authorize: 1'));
      });

      test('Parse ALLOW_TRUST with authorize = 2', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: ALLOW_TRUST
tx.operations[0].body.allowTrustOp.trustor: $destinationAccountId
tx.operations[0].body.allowTrustOp.asset: USD
tx.operations[0].body.allowTrustOp.authorize: 2
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('ALLOW_TRUST'));
        expect(roundTrip, contains('authorize: 2'));
      });
    });

    group('Preconditions Parsing', () {
      test('Parse PRECOND_TIME', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 1000000
tx.cond.timeBounds.maxTime: 2000000
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('PRECOND_TIME'));
        expect(roundTrip, contains('minTime: 1000000'));
        expect(roundTrip, contains('maxTime: 2000000'));
      });

      test('Parse PRECOND_V2 with all fields', () {
        final extraSigner = KeyPair.random().accountId;
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: true
tx.cond.v2.timeBounds.minTime: 1000000
tx.cond.v2.timeBounds.maxTime: 2000000
tx.cond.v2.ledgerBounds._present: true
tx.cond.v2.ledgerBounds.minLedger: 100
tx.cond.v2.ledgerBounds.maxLedger: 200
tx.cond.v2.minSeqNum._present: true
tx.cond.v2.minSeqNum: 1000
tx.cond.v2.minSeqAge: 300
tx.cond.v2.minSeqLedgerGap: 5
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: $extraSigner
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('PRECOND_V2'));
        expect(roundTrip, contains('minSeqAge: 300'));
        expect(roundTrip, contains('minSeqLedgerGap: 5'));
      });

      test('Parse PRECOND_V2 with minSeqAge and minSeqLedgerGap only', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: false
tx.cond.v2.ledgerBounds._present: false
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 600
tx.cond.v2.minSeqLedgerGap: 10
tx.cond.v2.extraSigners.len: 0
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('minSeqAge: 600'));
        expect(roundTrip, contains('minSeqLedgerGap: 10'));
      });

      test('Parse PRECOND_V2 with multiple extra signers', () {
        final extraSigner1 = KeyPair.random().accountId;
        final extraSigner2 = KeyPair.random().accountId;
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: false
tx.cond.v2.ledgerBounds._present: false
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 2
tx.cond.v2.extraSigners[0]: $extraSigner1
tx.cond.v2.extraSigners[1]: $extraSigner2
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('extraSigners.len: 2'));
      });
    });

    group('Memo Parsing', () {
      test('Parse MEMO_TEXT', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_TEXT
tx.memo.text: "Hello Stellar"
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('MEMO_TEXT'));
        expect(roundTrip, contains('Hello Stellar'));
      });

      test('Parse MEMO_ID', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_ID
tx.memo.id: 123456789
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('MEMO_ID'));
        expect(roundTrip, contains('123456789'));
      });

      test('Parse MEMO_HASH', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_HASH
tx.memo.hash: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('MEMO_HASH'));
      });
    });

    group('Asset Parsing', () {
      test('Parse native asset (XLM)', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('asset: XLM'));
      });

      test('Parse alphanum4 asset', () {
        final issuerKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: USD:${issuerKeyPair.accountId}
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('USD'));
      });

      test('Parse alphanum12 asset', () {
        final issuerKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: LONGASSET123:${issuerKeyPair.accountId}
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('LONGASSET123'));
      });
    });

    group('Operation with Source Account', () {
      test('Parse operation with source account present', () {
        final opSourceKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: ${opSourceKeyPair.accountId}
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains(opSourceKeyPair.accountId));
      });
    });

    group('Multiple Operations', () {
      test('Parse transaction with 3 operations', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 300
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 3
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
tx.operations[1].sourceAccount._present: false
tx.operations[1].body.type: PAYMENT
tx.operations[1].body.paymentOp.destination: $destinationAccountId
tx.operations[1].body.paymentOp.asset: XLM
tx.operations[1].body.paymentOp.amount: 2000000000
tx.operations[2].sourceAccount._present: false
tx.operations[2].body.type: PAYMENT
tx.operations[2].body.paymentOp.destination: $destinationAccountId
tx.operations[2].body.paymentOp.asset: XLM
tx.operations[2].body.paymentOp.amount: 3000000000
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('operations.len: 3'));
      });
    });

    group('Signatures Parsing', () {
      test('Parse transaction with signature', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 1
signatures[0].hint: 01020304
signatures[0].signature: 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('signatures.len: 1'));
      });

      test('Parse transaction with multiple signatures', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000
signatures.len: 2
signatures[0].hint: 01020304
signatures[0].signature: 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40
signatures[1].hint: 05060708
signatures[1].signature: 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('signatures.len: 2'));
      });
    });

    group('Fee Bump Transaction Parsing', () {
      test('Parse fee bump transaction', () {
        final feeSourceKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: ${feeSourceKeyPair.accountId}
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 2908908335136769
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.tx.operations.len: 1
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.destination: $destinationAccountId
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.amount: 1000000000
feeBump.tx.innerTx.signatures.len: 0
feeBump.signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('ENVELOPE_TYPE_TX_FEE_BUMP'));
        expect(roundTrip, contains(feeSourceKeyPair.accountId));
      });
    });

    group('Error Handling', () {
      test('Throws on missing source account', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on missing fee', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on missing sequence number', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on invalid source account', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: INVALID_ACCOUNT
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on invalid fee', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: invalid
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on invalid sequence number', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: invalid
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on missing memo type', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.operations.len: 0
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on missing operations length', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on invalid operations length', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: invalid
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on missing operation type', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });

      test('Throws on invalid ALLOW_TRUST authorize value', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: ALLOW_TRUST
tx.operations[0].body.allowTrustOp.trustor: $destinationAccountId
tx.operations[0].body.allowTrustOp.asset: USD
tx.operations[0].body.allowTrustOp.authorize: 99
signatures.len: 0
''';

        expect(
          () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
          throwsException,
        );
      });
    });

    group('Amount Parsing Edge Cases', () {
      test('Parse payment with decimal amount', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 123456789 (12.3456789 XLM)
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('123456789'));
      });

      test('Parse payment with small amount', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 2908908335136769
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.ext.v: 0
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: $destinationAccountId
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1 (0.0000001 XLM)
signatures.len: 0
''';

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('amount: 1'));
      });
    });
  });
}
