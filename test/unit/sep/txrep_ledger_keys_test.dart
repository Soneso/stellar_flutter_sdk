import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('TxRep Final Coverage Tests', () {
    // Test ConfigSettingID enum cases
    group('LedgerKey CONFIG_SETTING coverage', () {
      test('fromTxRep parses CONFIG_SETTING_CONTRACT_COMPUTE_V0', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_COMPUTE_V0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_LEDGER_COST_V0', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_LEDGER_COST_V0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_HISTORICAL_DATA_V0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_EVENTS_V0', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_EVENTS_V0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_BANDWIDTH_V0', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_BANDWIDTH_V0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test(
          'fromTxRep parses CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_COST_PARAMS_CPU_INSTRUCTIONS
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test(
          'fromTxRep parses CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_COST_PARAMS_MEMORY_BYTES
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_DATA_KEY_SIZE_BYTES
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_DATA_ENTRY_SIZE_BYTES
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_STATE_ARCHIVAL', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_STATE_ARCHIVAL
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_EXECUTION_LANES', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_EXECUTION_LANES
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_BUCKETLIST_SIZE_WINDOW', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_BUCKETLIST_SIZE_WINDOW
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_EVICTION_ITERATOR', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_EVICTION_ITERATOR
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_PARALLEL_COMPUTE_V0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_CONTRACT_LEDGER_COST_EXT_V0
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });

      test('fromTxRep parses CONFIG_SETTING_SCP_TIMING', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: CONFIG_SETTING
tx.sorobanData.resources.footprint.readOnly[0].configSetting.configSettingID: CONFIG_SETTING_SCP_TIMING
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });
    });

    // Test LedgerKey TTL type
    group('LedgerKey TTL coverage', () {
      test('toTxRep with TTL ledger key', () {
        var keyHash = Uint8List.fromList(List<int>.filled(32, 0));
        var sourceAccount = Account(
            'GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW',
            BigInt.from(123));
        var restoreOp = RestoreFootprintOperationBuilder().build();

        var tx = TransactionBuilder(sourceAccount)
            .addOperation(restoreOp)
            .build();

        tx.sorobanTransactionData = XdrSorobanTransactionData(
          XdrSorobanTransactionDataExt(0),
          XdrSorobanResources(
            XdrLedgerFootprint([XdrLedgerKey.forTTL(keyHash)], []),
            XdrUint32(1000),
            XdrUint32(1000),
            XdrUint32(1000),
          ),
          XdrInt64(BigInt.from(100)),
        );

        var xdr = tx.toEnvelopeXdrBase64();
        var txRep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);

        expect(txRep, contains('TTL'));
        expect(txRep, contains('keyHash'));
      });

      test('fromTxRep parses TTL ledger key', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: RESTORE_FOOTPRINT
tx.operations[0].body.restoreFootprintOp.ext.v: 0
tx.ext.v: 1
tx.sorobanData.ext.v: 0
tx.sorobanData.resources.footprint.readOnly.len: 1
tx.sorobanData.resources.footprint.readOnly[0].type: TTL
tx.sorobanData.resources.footprint.readOnly[0].ttl.keyHash: 0000000000000000000000000000000000000000000000000000000000000000
tx.sorobanData.resources.footprint.readWrite.len: 0
tx.sorobanData.resources.instructions: 1000
tx.sorobanData.resources.readBytes: 1000
tx.sorobanData.resources.writeBytes: 1000
tx.sorobanData.resourceFee: 100
tx.ext.v: 0
signatures.len: 0
''';
        var xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
        expect(xdr, isNotEmpty);
      });
    });

    // Test error handling paths
    group('Error handling coverage', () {
      test('fromTxRep throws on invalid feeBump.tx.fee non-numeric', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
feeBump.tx.fee: abc
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) =>
                e.toString().contains('feeBump.tx.fee'))));
      });

      test('fromTxRep throws on invalid tx.fee non-numeric', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: abc
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate(
                (e) => e.toString().contains('tx.fee'))));
      });

      test('fromTxRep throws on invalid timeBounds when present is true', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_TIME
tx.timeBounds._present: true
tx.timeBounds.minTime: abc
tx.memo.type: MEMO_NONE
tx.operations.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) =>
                e.toString().contains('timeBounds'))));
      });

      test('fromTxRep throws on missing CREATE_ACCOUNT destination', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_ACCOUNT
tx.operations[0].body.createAccountOp.startingBalance: 10.0000000
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e
                .toString()
                .contains(
                    'missing tx.operations[0].body.createAccountOp.destination'))));
      });

      test('fromTxRep throws on invalid CREATE_ACCOUNT destination', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_ACCOUNT
tx.operations[0].body.createAccountOp.destination: GINVALID
tx.operations[0].body.createAccountOp.startingBalance: 10.0000000
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e
                .toString()
                .contains(
                    'invalid tx.operations[0].body.createAccountOp.destination'))));
      });

      test('fromTxRep throws on missing PAYMENT destination', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 10.0000000
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e
                .toString()
                .contains(
                    'missing tx.operations[0].body.paymentOp.destination'))));
      });

      test('fromTxRep throws on invalid PAYMENT destination', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: GINVALID
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 10.0000000
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e
                .toString()
                .contains(
                    'invalid tx.operations[0].body.paymentOp.destination'))));
      });

      test('fromTxRep throws on missing BEGIN_SPONSORING sponsoredID', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.beginSponsoringFutureReservesOp.sponsoredID'))));
      });

      test('fromTxRep throws on missing CLAIM_CLAIMABLE_BALANCE balanceID',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CLAIM_CLAIMABLE_BALANCE
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.claimClaimableBalanceOp.balanceID.v0'))));
      });

      test('fromTxRep throws on missing CREATE_CLAIMABLE_BALANCE asset', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.createClaimableBalanceOp.asset'))));
      });

      test('fromTxRep throws on invalid CREATE_CLAIMABLE_BALANCE asset', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: TOOLONGASSETCODE12345
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.createClaimableBalanceOp.asset'))));
      });

      test('fromTxRep throws on missing CREATE_CLAIMABLE_BALANCE amount', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.createClaimableBalanceOp.amount'))));
      });

      test('fromTxRep throws on invalid CREATE_CLAIMABLE_BALANCE amount', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: abc
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 0
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.createClaimableBalanceOp.amount'))));
      });

      test('fromTxRep throws on missing claimant destination', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_UNCONDITIONAL
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination'))));
      });

      test('fromTxRep throws on invalid claimant destination', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GINVALID
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_UNCONDITIONAL
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination'))));
      });

      test('fromTxRep throws on missing claim predicate type', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type'))));
      });

      test('fromTxRep throws on missing AND predicates length', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_AND
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.andPredicates.len'))));
      });

      test('fromTxRep throws on missing absBefore time', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.absBefore'))));
      });

      test('fromTxRep throws on invalid absBefore time', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.absBefore: abc
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.absBefore'))));
      });

      test('fromTxRep throws on missing relBefore time', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.relBefore'))));
      });

      test('fromTxRep throws on invalid relBefore time', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 10.0000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 1
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.relBefore: abc
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.relBefore'))));
      });

      test('fromTxRep throws on missing SET_OPTIONS inflationDest._present',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.inflationDest._present'))));
      });

      test('fromTxRep throws on missing inflationDest when present is true',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: true
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.inflationDest'))));
      });

      test('fromTxRep throws on missing SET_OPTIONS clearFlags._present', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.clearFlags._present'))));
      });

      test('fromTxRep throws on missing clearFlags when present is true', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: true
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.clearFlags'))));
      });

      test('fromTxRep throws on invalid clearFlags value', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: true
tx.operations[0].body.setOptionsOp.clearFlags: abc
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.setOptionsOp.clearFlags'))));
      });

      test('fromTxRep throws on missing SET_OPTIONS setFlags._present', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.setFlags._present'))));
      });

      test('fromTxRep throws on missing setFlags when present is true', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: true
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.setFlags'))));
      });

      test('fromTxRep throws on invalid setFlags value', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: true
tx.operations[0].body.setOptionsOp.setFlags: abc
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.setOptionsOp.setFlags'))));
      });

      test('fromTxRep throws on missing SET_OPTIONS masterWeight._present',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.masterWeight._present'))));
      });

      test('fromTxRep throws on missing masterWeight when present is true',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: true
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.masterWeight'))));
      });

      test('fromTxRep throws on invalid masterWeight value', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: true
tx.operations[0].body.setOptionsOp.masterWeight: abc
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.setOptionsOp.masterWeight'))));
      });

      test('fromTxRep throws on missing SET_OPTIONS lowThreshold._present',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.lowThreshold._present'))));
      });

      test('fromTxRep throws on missing lowThreshold when present is true',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: true
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.lowThreshold'))));
      });

      test('fromTxRep throws on invalid lowThreshold value', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: true
tx.operations[0].body.setOptionsOp.lowThreshold: abc
tx.operations[0].body.setOptionsOp.medThreshold._present: false
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.setOptionsOp.lowThreshold'))));
      });

      test('fromTxRep throws on missing SET_OPTIONS medThreshold._present',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.medThreshold._present'))));
      });

      test('fromTxRep throws on missing medThreshold when present is true',
          () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: true
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'missing tx.operations[0].body.setOptionsOp.medThreshold'))));
      });

      test('fromTxRep throws on invalid medThreshold value', () {
        var txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GASOCNHNNLYFNMDJYQ3XFMI7BYHIOCFW3GJEOWRPEGK2TDPGTG2E5EDW
tx.fee: 100
tx.seqNum: 124
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: SET_OPTIONS
tx.operations[0].body.setOptionsOp.inflationDest._present: false
tx.operations[0].body.setOptionsOp.clearFlags._present: false
tx.operations[0].body.setOptionsOp.setFlags._present: false
tx.operations[0].body.setOptionsOp.masterWeight._present: false
tx.operations[0].body.setOptionsOp.lowThreshold._present: false
tx.operations[0].body.setOptionsOp.medThreshold._present: true
tx.operations[0].body.setOptionsOp.medThreshold: abc
tx.operations[0].body.setOptionsOp.highThreshold._present: false
tx.operations[0].body.setOptionsOp.homeDomain._present: false
tx.operations[0].body.setOptionsOp.signer._present: false
tx.ext.v: 0
signatures.len: 0
''';
        expect(
            () => TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep),
            throwsA(predicate((e) => e.toString().contains(
                'invalid tx.operations[0].body.setOptionsOp.medThreshold'))));
      });
    });
  });
}
