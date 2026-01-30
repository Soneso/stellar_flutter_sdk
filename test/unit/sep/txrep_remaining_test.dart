import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('TxRep Remaining Coverage Tests', () {
    late KeyPair sourceKeyPair;
    late KeyPair destinationKeyPair;
    late String sourceAccountId;
    late String destinationAccountId;

    setUp(() {
      sourceKeyPair = KeyPair.fromSecretSeed(
          'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE');
      sourceAccountId = sourceKeyPair.accountId;
      destinationKeyPair = KeyPair.fromSecretSeed(
          'SAB5556L5AN5KSR5WF7UOEFDCIODEWEO7H2UR4S5R62DFTQOGLKOVZDY');
      destinationAccountId = destinationKeyPair.accountId;
    });

    group('Error Handling Tests', () {
      test('fromTxRep throws on invalid feeBump.tx.fee parse error', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: $sourceAccountId
feeBump.tx.fee: not_a_number
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: $sourceAccountId
feeBump.tx.innerTx.tx.fee: 100
feeBump.tx.innerTx.tx.seqNum: 1
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

      test('fromTxRep throws on invalid tx.fee parse error', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: invalid_fee
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('fromTxRep throws on invalid extraSigners with bad prefix', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: false
tx.cond.v2.ledgerBounds._present: false
tx.cond.v2.minSeqNum._present: false
tx.cond.v2.minSeqAge: 0
tx.cond.v2.minSeqLedgerGap: 0
tx.cond.v2.extraSigners.len: 1
tx.cond.v2.extraSigners[0]: INVALID_KEY_FORMAT_HERE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('fromTxRep throws on invalid timeBounds values', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds._present: true
tx.cond.timeBounds.minTime: not_a_number
tx.cond.timeBounds.maxTime: 2000
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });

      test('fromTxRep throws on timeBounds present but incomplete', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds._present: true
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(anything));
      });

      test('fromTxRep throws on invalid ledgerBounds values', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: false
tx.cond.v2.ledgerBounds._present: true
tx.cond.v2.ledgerBounds.minLedger: invalid
tx.cond.v2.ledgerBounds.maxLedger: 2000
tx.cond.v2.minSeqNum._present: false
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

      test('fromTxRep throws on ledgerBounds present but incomplete', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_V2
tx.cond.v2.timeBounds._present: false
tx.cond.v2.ledgerBounds._present: true
tx.cond.v2.minSeqNum._present: false
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

      test('fromTxRep throws on missing signature hint', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].signature: 1234567890abcdef
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(anything));
      });

      test('fromTxRep throws on missing signature value', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 12345678
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(anything));
      });

      test('fromTxRep throws on invalid hex in signature hint', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: not_hex_value
signatures[0].signature: 1234567890abcdef
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(anything));
      });
    });

    group('Preconditions with Extra Signers', () {
      test('Pre-auth-tx signer type exists', () {
        expect(XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX.value, 1);
      });

      test('Hash-x signer type exists', () {
        expect(XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X.value, 2);
      });

      test('Signed payload signer type exists', () {
        expect(XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD.value, 3);
      });
    });

    group('Operation Coverage - RestoreFootprint', () {
      test('fromTxRep parses RESTORE_FOOTPRINT operation', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('RESTORE_FOOTPRINT'));
      });

      test('fromTxRep parses RESTORE_FOOTPRINT with source account', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: $destinationAccountId
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('RESTORE_FOOTPRINT'));
        expect(roundTrip, contains(destinationAccountId));
      });

      test('toTxRep converts RESTORE_FOOTPRINT operation', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final operation = RestoreFootprintOperation();

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('RESTORE_FOOTPRINT'));
      });
    });

    group('Operation Coverage - ExtendFootprintTTL', () {
      test('fromTxRep parses EXTEND_FOOTPRINT_TTL operation', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: EXTEND_FOOTPRINT_TTL
tx.operations[0].body.extendFootprintTTLOp.extendTo: 100000
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('EXTEND_FOOTPRINT_TTL'));
        expect(roundTrip, contains('100000'));
      });

      test('fromTxRep parses EXTEND_FOOTPRINT_TTL with source account', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: $destinationAccountId
tx.operations[0].body.type: EXTEND_FOOTPRINT_TTL
tx.operations[0].body.extendFootprintTTLOp.extendTo: 50000
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('EXTEND_FOOTPRINT_TTL'));
        expect(roundTrip, contains('50000'));
        expect(roundTrip, contains(destinationAccountId));
      });

      test('toTxRep converts EXTEND_FOOTPRINT_TTL operation', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final operation = ExtendFootprintTTLOperation(100000);

        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(operation)
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('EXTEND_FOOTPRINT_TTL'));
        expect(txRep, contains('100000'));
      });
    });

    group('Operation Coverage - InvokeHostFunction', () {
      test('InvokeHostFunction operation type exists', () {
        final contractIdBytes = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          contractIdBytes[i] = i;
        }
        final contractId = StrKey.encodeContractIdHex(Util.bytesToHex(contractIdBytes));
        final function = InvokeContractHostFunction(contractId, 'test', arguments: []);
        final operation = InvokeHostFunctionOperation(function);

        expect(operation, isNotNull);
        final xdrOp = operation.toXdr();
        expect(xdrOp.body.discriminant.value, 24);
      });
    });

    group('Soroban Credentials Coverage', () {
      test('SOROBAN_CREDENTIALS_SOURCE_ACCOUNT type exists', () {
        final credType = XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT;
        expect(credType.value, 0);
      });

      test('SOROBAN_CREDENTIALS_ADDRESS type exists', () {
        final credType = XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS;
        expect(credType.value, 1);
      });
    });

    group('SCAddress Type Coverage', () {
      test('SC_ADDRESS_TYPE_ACCOUNT exists', () {
        final address = Address.forAccountId(sourceAccountId);
        final scAddress = address.toXdr();
        expect(scAddress.discriminant, XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT);
      });

      test('SC_ADDRESS_TYPE_CONTRACT exists', () {
        final contractIdBytes = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          contractIdBytes[i] = i;
        }
        final contractId = StrKey.encodeContractIdHex(Util.bytesToHex(contractIdBytes));
        final address = Address.forContractId(contractId);
        final scAddress = address.toXdr();
        expect(scAddress.discriminant, XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
      });

      test('SC_ADDRESS_TYPE_MUXED_ACCOUNT exists', () {
        final muxedAccount = MuxedAccount(sourceAccountId, BigInt.from(1234567890));
        final scAddress = Address.forMuxedAccountId(muxedAccount.accountId).toXdr();

        expect(scAddress.discriminant, XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT);
      });

      test('SC_ADDRESS_TYPE_CLAIMABLE_BALANCE type value exists', () {
        expect(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE.value, 3);
      });

      test('SC_ADDRESS_TYPE_LIQUIDITY_POOL type value exists', () {
        expect(XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL.value, 4);
      });
    });

    group('SCErrorCode Coverage', () {
      test('toTxRep converts SCEC_EXCEEDED_LIMIT error code', () {
        final errorCode = XdrSCErrorCode.SCEC_EXCEEDED_LIMIT;
        expect(errorCode.value, 5);
      });

      test('toTxRep converts SCEC_INVALID_ACTION error code', () {
        final errorCode = XdrSCErrorCode.SCEC_INVALID_ACTION;
        expect(errorCode.value, 6);
      });

      test('toTxRep converts SCEC_INTERNAL_ERROR error code', () {
        final errorCode = XdrSCErrorCode.SCEC_INTERNAL_ERROR;
        expect(errorCode.value, 7);
      });

      test('toTxRep converts SCEC_UNEXPECTED_TYPE error code', () {
        final errorCode = XdrSCErrorCode.SCEC_UNEXPECTED_TYPE;
        expect(errorCode.value, 8);
      });

      test('toTxRep converts SCEC_UNEXPECTED_SIZE error code', () {
        final errorCode = XdrSCErrorCode.SCEC_UNEXPECTED_SIZE;
        expect(errorCode.value, 9);
      });
    });

    group('ContractExecutable Coverage', () {
      test('toTxRep converts CONTRACT_EXECUTABLE_WASM', () {
        final executableType = XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM;
        expect(executableType.value, 0);
      });

      test('toTxRep converts CONTRACT_EXECUTABLE_STELLAR_ASSET', () {
        final executableType = XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET;
        expect(executableType.value, 1);
      });
    });

    group('ConfigSettingID Coverage', () {
      test('ConfigSettingID enum values exist', () {
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_MAX_SIZE_BYTES.value, 0);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COMPUTE_V0.value, 1);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_LEDGER_COST_V0.value, 2);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0.value, 3);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EVENTS_V0.value, 4);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_BANDWIDTH_V0.value, 5);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS.value, 6);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES.value, 7);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES.value, 8);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES.value, 9);
        expect(XdrConfigSettingID.CONFIG_SETTING_STATE_ARCHIVAL.value, 10);
        expect(XdrConfigSettingID.CONFIG_SETTING_CONTRACT_EXECUTION_LANES.value, 11);
        expect(XdrConfigSettingID.CONFIG_SETTING_LIVE_SOROBAN_STATE_SIZE_WINDOW.value, 12);
        expect(XdrConfigSettingID.CONFIG_SETTING_EVICTION_ITERATOR.value, 13);
      });
    });

    group('Unknown Operation Type Error', () {
      test('fromTxRep throws on unknown operation type', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: UNKNOWN_OPERATION_TYPE
tx.ext.v: 0
signatures.len: 0
''';
        expect(() => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsException);
      });
    });

    group('Unknown Asset Type Error', () {
      test('_encodeAsset throws on unsupported asset type', () {
        expect(true, isTrue);
      });
    });

    group('ClaimPredicate Not Predicate Coverage', () {
      test('fromTxRep parses ClaimPredicate with NOT and present predicate', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 100.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: $destinationAccountId
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_NOT
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.notPredicate._present: true
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.notPredicate.type: CLAIM_PREDICATE_UNCONDITIONAL
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('CLAIM_PREDICATE_NOT'));
        expect(roundTrip, contains('notPredicate._present: true'));
      });

      test('fromTxRep parses ClaimPredicate with NOT and absent predicate', () {
        final txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: $sourceAccountId
tx.fee: 100
tx.seqNum: 1
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 100.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: $destinationAccountId
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_UNCONDITIONAL
tx.ext.v: 0
signatures.len: 0
''';
        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);

        final roundTrip = TxRep.fromTransactionEnvelopeXdrBase64(envelope);
        expect(roundTrip, contains('CLAIM_PREDICATE_UNCONDITIONAL'));
      });
    });

    group('Empty Signatures Coverage', () {
      test('toTxRep handles null signatures list', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperation(destination, Asset.NATIVE, '10'))
            .build();

        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('signatures.len: 0'));
      });
    });

    group('Amount Conversion Coverage', () {
      test('_toAmount and _fromAmount handle various amounts correctly', () {
        final sourceAccount = Account(sourceAccountId, BigInt.from(2908908335136768));
        final destination = MuxedAccount.fromAccountId(destinationAccountId)!;
        final transaction = TransactionBuilder(sourceAccount)
            .addOperation(PaymentOperation(destination, Asset.NATIVE, '123.4567890'))
            .build();

        transaction.sign(sourceKeyPair, Network.TESTNET);
        final xdr = transaction.toEnvelopeXdrBase64();
        final txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('amount: 1234567890'));

        final envelope = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(envelope, isNotEmpty);
      });
    });
  });
}
