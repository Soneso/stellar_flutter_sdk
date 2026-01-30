import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('TxRep Error Handling and Edge Cases', () {
    late KeyPair sourceKeyPair;
    late String sourceAccountId;

    setUp(() {
      sourceKeyPair = KeyPair.random();
      sourceAccountId = sourceKeyPair.accountId;
    });

    group('Fee Bump Transaction Error Cases', () {
      test('Invalid feeBump.tx.fee - not parseable', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: $sourceAccountId
feeBump.tx.fee: invalid_fee
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 100
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 0
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 0
feeBump.tx.ext.v: 0
feeBump.signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid feeBump.tx.fee - null after parsing', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: $sourceAccountId
feeBump.tx.fee: abc
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 100
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 0
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 0
feeBump.tx.ext.v: 0
feeBump.signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid feeBump.tx.feeSource', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: INVALID_ACCOUNT
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 100
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 0
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 0
feeBump.tx.ext.v: 0
feeBump.signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });
    });

    group('Transaction Fee Error Cases', () {
      test('Invalid tx.fee - not parseable', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: invalid_fee
tx.seqNum: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid tx.fee - null after parsing', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: abc
tx.seqNum: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });
    });

    group('Memo Error Cases', () {
      test('Invalid MEMO_RETURN', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_RETURN
tx.memo.return: invalid_hex_!!!
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid memo - catch block', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_ID
tx.memo.id: not_a_number
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });
    });

    group('Signatures Error Cases', () {
      test('Invalid signatures.len - greater than 20', () {
        final destKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: ${destKeyPair.accountId}
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
tx.ext.v: 0
signatures.len: 21
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid signatures.len - not a number', () {
        final destKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: ${destKeyPair.accountId}
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
tx.ext.v: 0
signatures.len: not_a_number
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid feeBump.signatures.len - not a number', () {
        final destKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: $sourceAccountId
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 100
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 1
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.destination: ${destKeyPair.accountId}
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 0
feeBump.tx.ext.v: 0
feeBump.signatures.len: not_a_number
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid feeBump.signatures.len - greater than 20', () {
        final destKeyPair = KeyPair.random();
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: $sourceAccountId
feeBump.tx.fee: 200
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 100
feeBump.tx.innerTx.tx.cond.type: PRECOND_NONE
feeBump.tx.innerTx.tx.memo.type: MEMO_NONE
feeBump.tx.innerTx.tx.operations.len: 1
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.destination: ${destKeyPair.accountId}
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 0
feeBump.tx.ext.v: 0
feeBump.signatures.len: 25
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });
    });

    group('Preconditions Error Cases', () {
      test('Invalid timeBounds in PRECOND_TIME', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: invalid
tx.cond.timeBounds.maxTime: 200
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid minSeqNum in PRECOND_V2', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: true
tx.cond.v2.minSeqNum: not_a_number
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Missing minSeqNum when _present is true', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: true
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Missing minSeqAge', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Missing minSeqLedgerGap', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.extraSigners.len: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Missing extraSigners.len', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid extraSigners.len - not a number', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: not_a_number
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Invalid extraSigners.len - greater than 2', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 3
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Missing extraSigner when len > 0', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 1
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Valid extraSigners with T (pre-auth tx) key', () {
        final destKeyPair = KeyPair.random();
        final preAuthKey = 'TAQCSRX2RIDJNHFIFHWD63X7D7D6TRT5Y2S6E3TEMXTG5W3OECHZ2OG4';
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: $preAuthKey
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: ${destKeyPair.accountId}
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);
      });

      test('Invalid extraSigners with X (hash) key - error case', () {
        final destKeyPair = KeyPair.random();
        final hashKey = 'XBU5MG2VJGZFZ62W7JNSDD7YW5IXVHPJVBK4SWQ4GBML6FKWKJYJMQR4';
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: $hashKey
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: ${destKeyPair.accountId}
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('Valid extraSigners with P (payload) key', () {
        final destKeyPair = KeyPair.random();
        final payloadKey = 'PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAQACAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM';
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_V2
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: $payloadKey
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: ${destKeyPair.accountId}
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 1000000000 (100.0000000 XLM)
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);
      });
    });

    group('Soroban Transaction Data Tests', () {
      test('Transaction with ext.v = 1 and soroban data', () {
        final account = Account(sourceAccountId, BigInt.from(100));

        // Create a transaction with Soroban data
        final txBuilder = TransactionBuilder(account);
        final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);

        final function = UploadContractWasmHostFunction(wasmBytes);
        final invokeOp = InvokeHostFunctionOperation(function);

        txBuilder.addOperation(invokeOp);

        final tx = txBuilder.build();

        // Add minimal Soroban transaction data
        tx.sorobanTransactionData = XdrSorobanTransactionData(
          XdrSorobanTransactionDataExt(0),
          XdrSorobanResources(
            XdrLedgerFootprint([], []),
            XdrUint32(0),
            XdrUint32(0),
            XdrUint32(0)
          ),
          XdrInt64(BigInt.zero)
        );

        final xdr = tx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('tx.ext.v: 1'));
        expect(txRep, contains('sorobanData'));
      });
    });

    group('Soroban Operations Tests', () {
      test('RESTORE_FOOTPRINT operation', () {
        final account = Account(sourceAccountId, BigInt.from(100));
        final txBuilder = TransactionBuilder(account);

        final restoreOp = RestoreFootprintOperation();
        txBuilder.addOperation(restoreOp);

        final tx = txBuilder.build();
        final xdr = tx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('RESTORE_FOOTPRINT'));

        // Round trip
        final xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr2, isNotEmpty);
      });

      test('EXTEND_FOOTPRINT_TTL operation', () {
        final account = Account(sourceAccountId, BigInt.from(100));
        final txBuilder = TransactionBuilder(account);

        final extendOp = ExtendFootprintTTLOperation(100);
        txBuilder.addOperation(extendOp);

        final tx = txBuilder.build();
        final xdr = tx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('EXTEND_FOOTPRINT_TTL'));
        expect(txRep, contains('100'));

        // Round trip
        final xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr2, isNotEmpty);
      });

      test('INVOKE_HOST_FUNCTION operation with upload wasm', () {
        final account = Account(sourceAccountId, BigInt.from(100));
        final txBuilder = TransactionBuilder(account);

        final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00]);
        final function = UploadContractWasmHostFunction(wasmBytes);
        final invokeOp = InvokeHostFunctionOperation(function);

        txBuilder.addOperation(invokeOp);

        final tx = txBuilder.build();
        final xdr = tx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('INVOKE_HOST_FUNCTION'));

        // Round trip
        final xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr2, isNotEmpty);
      });
    });

    group('Duplicate Operation Types Tests', () {
      test('SET_TRUST_LINE_FLAGS operation (duplicate check)', () {
        final account = Account(sourceAccountId, BigInt.from(100));
        final issuerKeyPair = KeyPair.random();
        final asset = AssetTypeCreditAlphaNum4('USDC', issuerKeyPair.accountId);

        final txBuilder = TransactionBuilder(account);
        final trustor = KeyPair.random();

        final setTrustOp = SetTrustLineFlagsOperationBuilder(
          trustor.accountId,
          asset,
          0,  // clearFlags
          XdrTrustLineFlags.AUTHORIZED_FLAG.value  // setFlags
        ).build();

        txBuilder.addOperation(setTrustOp);

        final tx = txBuilder.build();
        final xdr = tx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('SET_TRUST_LINE_FLAGS'));

        // Round trip
        final xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr2, isNotEmpty);
      });

      test('LIQUIDITY_POOL_DEPOSIT operation', () {
        final account = Account(sourceAccountId, BigInt.from(100));
        final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';

        final txBuilder = TransactionBuilder(account);
        final depositOp = LiquidityPoolDepositOperation(
          liquidityPoolId: poolId,
          maxAmountA: '1000.0',
          maxAmountB: '2000.0',
          minPrice: '0.5',
          maxPrice: '0.5'
        );
        txBuilder.addOperation(depositOp);

        final tx = txBuilder.build();
        final xdr = tx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('LIQUIDITY_POOL_DEPOSIT'));

        // Round trip
        final xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr2, isNotEmpty);
      });

      test('LIQUIDITY_POOL_WITHDRAW operation', () {
        final account = Account(sourceAccountId, BigInt.from(100));
        final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';

        final txBuilder = TransactionBuilder(account);
        final withdrawOp = LiquidityPoolWithdrawOperation(
          liquidityPoolId: poolId,
          amount: '500.0',
          minAmountA: '200.0',
          minAmountB: '100.0'
        );
        txBuilder.addOperation(withdrawOp);

        final tx = txBuilder.build();
        final xdr = tx.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('LIQUIDITY_POOL_WITHDRAW'));

        // Round trip
        final xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr2, isNotEmpty);
      });
    });

    group('Invalid Operation Type', () {
      test('Unsupported operation type', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 100
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: UNSUPPORTED_OP_TYPE
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });
    });

    group('SCVal Type Tests', () {
      test('SCVal SCV_BOOL true', () {
        final scVal = XdrSCVal.forBool(true);
        expect(scVal.b, isTrue);
      });

      test('SCVal SCV_BOOL false', () {
        final scVal = XdrSCVal.forBool(false);
        expect(scVal.b, isFalse);
      });

      test('SCVal SCV_VOID', () {
        final scVal = XdrSCVal.forVoid();
        expect(scVal, isNotNull);
      });

      test('SCVal SCV_U32', () {
        final scVal = XdrSCVal.forU32(42);
        expect(scVal.u32?.uint32, equals(42));
      });

      test('SCVal SCV_I32', () {
        final scVal = XdrSCVal.forI32(-42);
        expect(scVal.i32?.int32, equals(-42));
      });

      test('SCVal SCV_U64', () {
        final scVal = XdrSCVal.forU64(BigInt.from(12345));
        expect(scVal.u64?.uint64, equals(BigInt.from(12345)));
      });

      test('SCVal SCV_I64', () {
        final scVal = XdrSCVal.forI64(BigInt.from(-12345));
        expect(scVal.i64?.int64, equals(BigInt.from(-12345)));
      });

      test('SCVal SCV_TIMEPOINT', () {
        final scVal = XdrSCVal.forTimepoint(BigInt.from(1234567890));
        expect(scVal.timepoint?.uint64, equals(BigInt.from(1234567890)));
      });

      test('SCVal SCV_DURATION', () {
        final scVal = XdrSCVal.forDuration(BigInt.from(3600));
        expect(scVal.duration?.uint64, equals(BigInt.from(3600)));
      });

      test('SCVal SCV_U128', () {
        final parts = XdrUInt128Parts(
          XdrUint64(BigInt.from(100)),
          XdrUint64(BigInt.from(200))
        );
        final scVal = XdrSCVal.forU128(parts);
        expect(scVal.u128?.hi.uint64, equals(BigInt.from(100)));
        expect(scVal.u128?.lo.uint64, equals(BigInt.from(200)));
      });
    });

    group('SCAddress Type Tests', () {
      test('SCAddress SC_ADDRESS_TYPE_ACCOUNT', () {
        final accountId = KeyPair.random().accountId;
        final scAddress = XdrSCAddress.forAccountId(accountId);
        expect(scAddress, isNotNull);
        expect(scAddress.accountId, isNotNull);
      });

      test('SCAddress SC_ADDRESS_TYPE_CONTRACT', () {
        final contractId = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
        final scAddress = XdrSCAddress.forContractId(contractId);
        expect(scAddress, isNotNull);
        expect(scAddress.contractId, isNotNull);
      });

      test('SCAddress SC_ADDRESS_TYPE_CLAIMABLE_BALANCE', () {
        final balanceId = '000000006d6f6e657900000000000000000000000000000000000000000000000000000000';
        final scAddress = XdrSCAddress.forClaimableBalanceId(balanceId);
        expect(scAddress.discriminant, equals(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE));
        expect(scAddress.claimableBalanceId, isNotNull);
      });

      test('SCAddress SC_ADDRESS_TYPE_LIQUIDITY_POOL', () {
        final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
        final scAddress = XdrSCAddress.forLiquidityPoolId(poolId);
        expect(scAddress, isNotNull);
      });
    });

    group('ContractExecutable Type Tests', () {
      test('CONTRACT_EXECUTABLE_WASM', () {
        final wasmHash = Uint8List.fromList(List.generate(32, (i) => i));
        final executable = XdrContractExecutable.forWasm(wasmHash);
        expect(executable, isNotNull);
        expect(executable.wasmHash, isNotNull);
      });

      test('CONTRACT_EXECUTABLE_STELLAR_ASSET', () {
        final executable = XdrContractExecutable.forAsset();
        expect(executable, isNotNull);
      });
    });

    group('SorobanCredentials Type Tests', () {
      test('SOROBAN_CREDENTIALS_SOURCE_ACCOUNT', () {
        final credentials = XdrSorobanCredentials.forSourceAccount();
        expect(credentials, isNotNull);
      });

      test('SOROBAN_CREDENTIALS_ADDRESS', () {
        final address = XdrSCAddress.forAccountId(KeyPair.random().accountId);
        final signature = XdrSCVal.forVoid();
        final addressCreds = XdrSorobanAddressCredentials(
          address,
          XdrInt64(BigInt.from(123)),
          XdrUint32(1000),
          signature
        );
        final credentials = XdrSorobanCredentials.forAddressCredentials(addressCreds);
        expect(credentials, isNotNull);
        expect(credentials.address, isNotNull);
      });
    });

    group('ConfigSettingID Tests', () {
      test('CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_COMPUTE_V0', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_LEDGER_COST_V0', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_EVENTS_V0', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_BANDWIDTH_V0', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_STATE_ARCHIVAL', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_EXECUTION_LANES', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_EVICTION_ITERATOR', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0;
        expect(id, isNotNull);
      });

      test('CONFIG_SETTING_SCP_TIMING', () {
        final id = XdrConfigSettingID.CONFIG_SETTING_SCP_TIMING;
        expect(id, isNotNull);
      });
    });
  });
}
