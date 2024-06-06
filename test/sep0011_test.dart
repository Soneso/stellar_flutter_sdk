// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  test('txrep to transaction envelope and back to txrep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.fee: 1400
tx.seqNum: 1102902109202
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 1595282368
tx.cond.timeBounds.maxTime: 1595284000
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 14
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CREATE_ACCOUNT
tx.operations[0].body.createAccountOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[0].body.createAccountOp.startingBalance: 9223372036854775807
tx.operations[1].sourceAccount._present: true
tx.operations[1].sourceAccount: GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[1].body.type: PAYMENT
tx.operations[1].body.paymentOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[1].body.paymentOp.asset: XLM
tx.operations[1].body.paymentOp.amount: 9223372036854775807
tx.operations[2].sourceAccount._present: true
tx.operations[2].sourceAccount: GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[2].body.type: PAYMENT
tx.operations[2].body.paymentOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operations[2].body.paymentOp.amount: 9223372036854775807
tx.operations[3].sourceAccount._present: false
tx.operations[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
tx.operations[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
tx.operations[3].body.pathPaymentStrictReceiveOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
tx.operations[3].body.pathPaymentStrictReceiveOp.path.len: 2
tx.operations[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[4].sourceAccount._present: false
tx.operations[4].body.type: PATH_PAYMENT_STRICT_SEND
tx.operations[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
tx.operations[4].body.pathPaymentStrictSendOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[4].body.pathPaymentStrictSendOp.destAsset: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[4].body.pathPaymentStrictSendOp.destMin: 12000000000
tx.operations[4].body.pathPaymentStrictSendOp.path.len: 2
tx.operations[4].body.pathPaymentStrictSendOp.path[0]: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[5].sourceAccount._present: false
tx.operations[5].body.type: SET_OPTIONS
tx.operations[5].body.setOptionsOp.inflationDest._present: true
tx.operations[5].body.setOptionsOp.inflationDest: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[5].body.setOptionsOp.clearFlags._present: true
tx.operations[5].body.setOptionsOp.clearFlags: 2
tx.operations[5].body.setOptionsOp.setFlags._present: true
tx.operations[5].body.setOptionsOp.setFlags: 4
tx.operations[5].body.setOptionsOp.masterWeight._present: true
tx.operations[5].body.setOptionsOp.masterWeight: 122
tx.operations[5].body.setOptionsOp.lowThreshold._present: true
tx.operations[5].body.setOptionsOp.lowThreshold: 10
tx.operations[5].body.setOptionsOp.medThreshold._present: true
tx.operations[5].body.setOptionsOp.medThreshold: 50
tx.operations[5].body.setOptionsOp.highThreshold._present: true
tx.operations[5].body.setOptionsOp.highThreshold: 122
tx.operations[5].body.setOptionsOp.homeDomain._present: true
tx.operations[5].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
tx.operations[5].body.setOptionsOp.signer._present: true
tx.operations[5].body.setOptionsOp.signer.key: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[5].body.setOptionsOp.signer.weight: 50
tx.operations[6].sourceAccount._present: false
tx.operations[6].body.type: MANAGE_SELL_OFFER
tx.operations[6].body.manageSellOfferOp.selling: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[6].body.manageSellOfferOp.buying: XLM
tx.operations[6].body.manageSellOfferOp.amount: 82820000000
tx.operations[6].body.manageSellOfferOp.price.n: 7
tx.operations[6].body.manageSellOfferOp.price.d: 10
tx.operations[6].body.manageSellOfferOp.offerID: 9298298398333
tx.operations[7].sourceAccount._present: false
tx.operations[7].body.type: CREATE_PASSIVE_SELL_OFFER
tx.operations[7].body.createPassiveSellOfferOp.selling: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[7].body.createPassiveSellOfferOp.buying: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[7].body.createPassiveSellOfferOp.amount: 28280000000
tx.operations[7].body.createPassiveSellOfferOp.price.n: 1
tx.operations[7].body.createPassiveSellOfferOp.price.d: 2
tx.operations[8].sourceAccount._present: false
tx.operations[8].body.type: CHANGE_TRUST
tx.operations[8].body.changeTrustOp.line: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[8].body.changeTrustOp.limit: 100000000000
tx.operations[9].sourceAccount._present: false
tx.operations[9].body.type: ALLOW_TRUST
tx.operations[9].body.allowTrustOp.trustor: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[9].body.allowTrustOp.asset: MOON
tx.operations[9].body.allowTrustOp.authorize: 1
tx.operations[10].sourceAccount._present: false
tx.operations[10].body.type: ACCOUNT_MERGE
tx.operations[10].body.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operations[11].sourceAccount._present: false
tx.operations[11].body.type: MANAGE_DATA
tx.operations[11].body.manageDataOp.dataName: "Sommer"
tx.operations[11].body.manageDataOp.dataValue._present: true
tx.operations[11].body.manageDataOp.dataValue: 446965204df662656c2073696e6420686569df21
tx.operations[12].sourceAccount._present: false
tx.operations[12].body.type: BUMP_SEQUENCE
tx.operations[12].body.bumpSequenceOp.bumpTo: 1102902109211
tx.operations[13].sourceAccount._present: false
tx.operations[13].body.type: MANAGE_BUY_OFFER
tx.operations[13].body.manageBuyOfferOp.selling: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[13].body.manageBuyOfferOp.buying: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operations[13].body.manageBuyOfferOp.buyAmount: 120000000
tx.operations[13].body.manageBuyOfferOp.price.n: 1
tx.operations[13].body.manageBuyOfferOp.price.d: 5
tx.operations[13].body.manageBuyOfferOp.offerID: 9298298398334
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: b51d604e
signatures[0].signature: c52a9c15a60a9b7281cb9e932e0eb1ffbe9a759b6cc242eeb08dda88cfff3faaa47b5d817153617825941d1d0c46523f54d9b3790f1cee1370af08a5c29dfe03''';

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('txrep to fee bump transaction envelope and back to txrep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GBD4KWT3HXUGS4ACUZZELY67UJXLOFTZAPR5DT5QIMBO6BX53FXFSLQS
feeBump.tx.fee: 1515
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.fee: 1400
feeBump.tx.innerTx.tx.seqNum: 1102902109202
feeBump.tx.innerTx.tx.timeBounds._present: true
feeBump.tx.innerTx.tx.timeBounds.minTime: 1595282368
feeBump.tx.innerTx.tx.timeBounds.maxTime: 1595284000
feeBump.tx.innerTx.tx.memo.type: MEMO_TEXT
feeBump.tx.innerTx.tx.memo.text: "Enjoy this transaction"
feeBump.tx.innerTx.tx.operations.len: 14
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: CREATE_ACCOUNT
feeBump.tx.innerTx.tx.operations[0].body.createAccountOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[0].body.createAccountOp.startingBalance: 9223372036854775807
feeBump.tx.innerTx.tx.operations[1].sourceAccount._present: true
feeBump.tx.innerTx.tx.operations[1].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[1].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.amount: 9223372036854775807
feeBump.tx.innerTx.tx.operations[2].sourceAccount._present: true
feeBump.tx.innerTx.tx.operations[2].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[2].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.amount: 9223372036854775807
feeBump.tx.innerTx.tx.operations[3].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path.len: 2
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[4].body.type: PATH_PAYMENT_STRICT_SEND
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destMin: 12000000000
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path.len: 2
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[5].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[5].body.type: SET_OPTIONS
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.inflationDest._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.inflationDest: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.clearFlags._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.clearFlags: 2
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.setFlags._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.setFlags: 4
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.masterWeight._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.masterWeight: 122
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.lowThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.lowThreshold: 10
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.medThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.medThreshold: 50
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.highThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.highThreshold: 122
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.homeDomain._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer.key: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer.weight: 50
feeBump.tx.innerTx.tx.operations[6].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[6].body.type: MANAGE_SELL_OFFER
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.selling: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.buying: XLM
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.amount: 82820000000
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.price.n: 7
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.price.d: 10
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.offerID: 9298298398333
feeBump.tx.innerTx.tx.operations[7].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[7].body.type: CREATE_PASSIVE_SELL_OFFER
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.selling: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.buying: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.amount: 28280000000
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.price.d: 2
feeBump.tx.innerTx.tx.operations[8].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[8].body.type: CHANGE_TRUST
feeBump.tx.innerTx.tx.operations[8].body.changeTrustOp.line: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[8].body.changeTrustOp.limit: 100000000000
feeBump.tx.innerTx.tx.operations[9].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[9].body.type: ALLOW_TRUST
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.trustor: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.asset: MOON
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.authorize: 1
feeBump.tx.innerTx.tx.operations[10].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[10].body.type: ACCOUNT_MERGE
feeBump.tx.innerTx.tx.operations[10].body.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[11].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[11].body.type: MANAGE_DATA
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataName: "Sommer"
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataValue._present: true
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataValue: 446965204df662656c2073696e6420686569df21
feeBump.tx.innerTx.tx.operations[12].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[12].body.type: BUMP_SEQUENCE
feeBump.tx.innerTx.tx.operations[12].body.bumpSequenceOp.bumpTo: 1102902109211
feeBump.tx.innerTx.tx.operations[13].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[13].body.type: MANAGE_BUY_OFFER
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.selling: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.buying: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.buyAmount: 120000000
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.price.d: 5
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.offerID: 9298298398334
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 1
feeBump.tx.innerTx.signatures[0].hint: 7b21e7e3
feeBump.tx.innerTx.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a
feeBump.tx.ext.v: 0
feeBump.signatures.len: 1
feeBump.signatures[0].hint: 7b21e7e3
feeBump.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a''';

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    String xdr =
        'AAAABQAAAABHxVp7PehpcAKmckXj36JutxZ5A+PRz7BDAu8G/dluWQAAAAAAAAXrAAAAAgAAAADutRMdnHiBkr8ubYKbzAeZrmBiv05Gw+OZJBJreyHn4wAABXgAAAEAyhakEgAAAAEAAAAAXxYTwAAAAABfFhogAAAAAQAAABZFbmpveSB0aGlzIHRyYW5zYWN0aW9uAAAAAAAOAAAAAAAAAAAAAAAAWuWjUwjUN29Tinf8R9pUL5cd9Dg7Vlor7vgPi45MWrt//////////wAAAAEAAAAA7rUTHZx4gZK/Lm2Cm8wHma5gYr9ORsPjmSQSa3sh5+MAAAABAAAAAFrlo1MI1DdvU4p3/EfaVC+XHfQ4O1ZaK+74D4uOTFq7AAAAAH//////////AAAAAQAAAADutRMdnHiBkr8ubYKbzAeZrmBiv05Gw+OZJBJreyHn4wAAAAEAAAAAWuWjUwjUN29Tinf8R9pUL5cd9Dg7Vlor7vgPi45MWrsAAAABVVNEAAAAAAAyUlQyIZKfbs+tUWuvK7N0nGSCII0/Go1/CpHXNW3tC3//////////AAAAAAAAAAIAAAABSU9NAAAAAADutRMdnHiBkr8ubYKbzAeZrmBiv05Gw+OZJBJreyHn4wAAAAABMS0AAAAAAFrlo1MI1DdvU4p3/EfaVC+XHfQ4O1ZaK+74D4uOTFq7AAAAAU1PT04AAAAA7rUTHZx4gZK/Lm2Cm8wHma5gYr9ORsPjmSQSa3sh5+MAAAAABMS0AAAAAAIAAAABRUNPAAAAAADutRMdnHiBkr8ubYKbzAeZrmBiv05Gw+OZJBJreyHn4wAAAAJBU1RSTwAAAAAAAAAAAAAA7rUTHZx4gZK/Lm2Cm8wHma5gYr9ORsPjmSQSa3sh5+MAAAAAAAAADQAAAAFJT00AAAAAAO61Ex2ceIGSvy5tgpvMB5muYGK/TkbD45kkEmt7IefjAAAAAO5rKAAAAAAAWuWjUwjUN29Tinf8R9pUL5cd9Dg7Vlor7vgPi45MWrsAAAABTU9PTgAAAADutRMdnHiBkr8ubYKbzAeZrmBiv05Gw+OZJBJreyHn4wAAAALLQXgAAAAAAgAAAAFFQ08AAAAAAO61Ex2ceIGSvy5tgpvMB5muYGK/TkbD45kkEmt7IefjAAAAAkFTVFJPAAAAAAAAAAAAAADutRMdnHiBkr8ubYKbzAeZrmBiv05Gw+OZJBJreyHn4wAAAAAAAAAFAAAAAQAAAABa5aNTCNQ3b1OKd/xH2lQvlx30ODtWWivu+A+LjkxauwAAAAEAAAACAAAAAQAAAAQAAAABAAAAegAAAAEAAAAKAAAAAQAAADIAAAABAAAAegAAAAEAAAAeaHR0cHM6Ly93d3cuc29uZXNvLmNvbS9ibHViYmVyAAAAAAABAAAAAFrlo1MI1DdvU4p3/EfaVC+XHfQ4O1ZaK+74D4uOTFq7AAAAMgAAAAAAAAADAAAAAUVDTwAAAAAA7rUTHZx4gZK/Lm2Cm8wHma5gYr9ORsPjmSQSa3sh5+MAAAAAAAAAE0h06QAAAAAHAAAACgAACHTtxeZ9AAAAAAAAAAQAAAACQVNUUk8AAAAAAAAAAAAAAO61Ex2ceIGSvy5tgpvMB5muYGK/TkbD45kkEmt7IefjAAAAAU1PT04AAAAA7rUTHZx4gZK/Lm2Cm8wHma5gYr9ORsPjmSQSa3sh5+MAAAAGlZ6OAAAAAAEAAAACAAAAAAAAAAYAAAACQVNUUk8AAAAAAAAAAAAAAO61Ex2ceIGSvy5tgpvMB5muYGK/TkbD45kkEmt7IefjAAAAF0h26AAAAAAAAAAABwAAAABa5aNTCNQ3b1OKd/xH2lQvlx30ODtWWivu+A+LjkxauwAAAAFNT09OAAAAAQAAAAAAAAAIAAAAAFrlo1MI1DdvU4p3/EfaVC+XHfQ4O1ZaK+74D4uOTFq7AAAAAAAAAAoAAAAGU29tbWVyAAAAAAABAAAAFERpZSBN9mJlbCBzaW5kIGhlad8hAAAAAAAAAAsAAAEAyhakGwAAAAAAAAAMAAAAAU1PT04AAAAA7rUTHZx4gZK/Lm2Cm8wHma5gYr9ORsPjmSQSa3sh5+MAAAABRUNPAAAAAADutRMdnHiBkr8ubYKbzAeZrmBiv05Gw+OZJBJreyHn4wAAAAAHJw4AAAAAAQAAAAUAAAh07cXmfgAAAAAAAAABeyHn4wAAAEAIWi7mG+DVvCwsfH6QzEySH+v+JapUtumciqLpzcv3uLJIcuEp5kVQHb3bQn1AD6kq9pdo/mKoCwQdDv76X8kKAAAAAAAAAAF7IefjAAAAQAhaLuYb4NW8LCx8fpDMTJIf6/4lqlS26ZyKounNy/e4skhy4SnmRVAdvdtCfUAPqSr2l2j+YqgLBB0O/vpfyQo=';
    assert(xdr == transactionEnvelopeXdrBase64);
  });

  test('txrep from stc', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GBD4KWT3HXUGS4ACUZZELY67UJXLOFTZAPR5DT5QIMBO6BX53FXFSLQS
feeBump.tx.fee: 1515 (0.0001515e7)
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.fee: 1400
feeBump.tx.innerTx.tx.seqNum: 1102902109202
feeBump.tx.innerTx.tx.cond.type: PRECOND_TIME
feeBump.tx.innerTx.tx.cond.timeBounds.minTime: 1595282368 (Mon Jul 20 23:59:28 CEST 2020)
feeBump.tx.innerTx.tx.cond.timeBounds.maxTime: 1595284000 (Tue Jul 21 00:26:40 CEST 2020)
feeBump.tx.innerTx.tx.memo.type: MEMO_TEXT
feeBump.tx.innerTx.tx.memo.text: "Enjoy this transaction"
feeBump.tx.innerTx.tx.operations.len: 14
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: CREATE_ACCOUNT
feeBump.tx.innerTx.tx.operations[0].body.createAccountOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[0].body.createAccountOp.startingBalance: 9223372036854775807 (922,337,203,685.4775807e7)
feeBump.tx.innerTx.tx.operations[1].sourceAccount._present: true
feeBump.tx.innerTx.tx.operations[1].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[1].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.amount: 9223372036854775807 (922,337,203,685.4775807e7)
feeBump.tx.innerTx.tx.operations[2].sourceAccount._present: true
feeBump.tx.innerTx.tx.operations[2].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[2].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.amount: 9223372036854775807 (922,337,203,685.4775807e7)
feeBump.tx.innerTx.tx.operations[3].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000 (2e7)
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000 (8e7)
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path.len: 2
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[4].body.type: PATH_PAYMENT_STRICT_SEND
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000 (400e7)
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destMin: 12000000000 (1,200e7)
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path.len: 2
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[5].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[5].body.type: SET_OPTIONS
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.inflationDest._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.inflationDest: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.clearFlags._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.clearFlags: 2
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.setFlags._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.setFlags: 4
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.masterWeight._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.masterWeight: 122
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.lowThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.lowThreshold: 10
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.medThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.medThreshold: 50
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.highThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.highThreshold: 122
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.homeDomain._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer.key: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer.weight: 50
feeBump.tx.innerTx.tx.operations[6].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[6].body.type: MANAGE_SELL_OFFER
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.selling: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.buying: XLM
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.amount: 82820000000 (8,282e7)
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.price.n: 7
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.price.d: 10
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.offerID: 9298298398333 (929,829.8398333e7)
feeBump.tx.innerTx.tx.operations[7].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[7].body.type: CREATE_PASSIVE_SELL_OFFER
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.selling: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.buying: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.amount: 28280000000 (2,828e7)
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.price.d: 2
feeBump.tx.innerTx.tx.operations[8].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[8].body.type: CHANGE_TRUST
feeBump.tx.innerTx.tx.operations[8].body.changeTrustOp.line: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[8].body.changeTrustOp.limit: 100000000000 (10,000e7)
feeBump.tx.innerTx.tx.operations[9].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[9].body.type: ALLOW_TRUST
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.trustor: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.asset: MOON
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.authorize: 1
feeBump.tx.innerTx.tx.operations[10].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[10].body.type: ACCOUNT_MERGE
feeBump.tx.innerTx.tx.operations[10].body.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[11].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[11].body.type: MANAGE_DATA
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataName: "Sommer"
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataValue._present: true
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataValue: 446965204df662656c2073696e6420686569df21
feeBump.tx.innerTx.tx.operations[12].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[12].body.type: BUMP_SEQUENCE
feeBump.tx.innerTx.tx.operations[12].body.bumpSequenceOp.bumpTo: 1102902109211
feeBump.tx.innerTx.tx.operations[13].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[13].body.type: MANAGE_BUY_OFFER
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.selling: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.buying: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.buyAmount: 120000000 (12e7)
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.price.d: 5
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.offerID: 9298298398334 (929,829.8398334e7)
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 1
feeBump.tx.innerTx.signatures[0].hint: 7b21e7e3 (bad signature/unknown key/main is wrong network)
feeBump.tx.innerTx.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a
feeBump.tx.ext.v: 0
feeBump.signatures.len: 1
feeBump.signatures[0].hint: 7b21e7e3 (bad signature/unknown key/main is wrong network)
feeBump.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a''';

    String txRepWithoutComments = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GBD4KWT3HXUGS4ACUZZELY67UJXLOFTZAPR5DT5QIMBO6BX53FXFSLQS
feeBump.tx.fee: 1515
feeBump.tx.innerTx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.fee: 1400
feeBump.tx.innerTx.tx.seqNum: 1102902109202
feeBump.tx.innerTx.tx.cond.type: PRECOND_TIME
feeBump.tx.innerTx.tx.cond.timeBounds.minTime: 1595282368
feeBump.tx.innerTx.tx.cond.timeBounds.maxTime: 1595284000
feeBump.tx.innerTx.tx.memo.type: MEMO_TEXT
feeBump.tx.innerTx.tx.memo.text: "Enjoy this transaction"
feeBump.tx.innerTx.tx.operations.len: 14
feeBump.tx.innerTx.tx.operations[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[0].body.type: CREATE_ACCOUNT
feeBump.tx.innerTx.tx.operations[0].body.createAccountOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[0].body.createAccountOp.startingBalance: 9223372036854775807
feeBump.tx.innerTx.tx.operations[1].sourceAccount._present: true
feeBump.tx.innerTx.tx.operations[1].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[1].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.asset: XLM
feeBump.tx.innerTx.tx.operations[1].body.paymentOp.amount: 9223372036854775807
feeBump.tx.innerTx.tx.operations[2].sourceAccount._present: true
feeBump.tx.innerTx.tx.operations[2].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[2].body.type: PAYMENT
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
feeBump.tx.innerTx.tx.operations[2].body.paymentOp.amount: 9223372036854775807
feeBump.tx.innerTx.tx.operations[3].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path.len: 2
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[4].body.type: PATH_PAYMENT_STRICT_SEND
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.destMin: 12000000000
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path.len: 2
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[5].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[5].body.type: SET_OPTIONS
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.inflationDest._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.inflationDest: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.clearFlags._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.clearFlags: 2
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.setFlags._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.setFlags: 4
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.masterWeight._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.masterWeight: 122
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.lowThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.lowThreshold: 10
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.medThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.medThreshold: 50
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.highThreshold._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.highThreshold: 122
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.homeDomain._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer._present: true
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer.key: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[5].body.setOptionsOp.signer.weight: 50
feeBump.tx.innerTx.tx.operations[6].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[6].body.type: MANAGE_SELL_OFFER
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.selling: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.buying: XLM
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.amount: 82820000000
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.price.n: 7
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.price.d: 10
feeBump.tx.innerTx.tx.operations[6].body.manageSellOfferOp.offerID: 9298298398333
feeBump.tx.innerTx.tx.operations[7].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[7].body.type: CREATE_PASSIVE_SELL_OFFER
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.selling: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.buying: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.amount: 28280000000
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operations[7].body.createPassiveSellOfferOp.price.d: 2
feeBump.tx.innerTx.tx.operations[8].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[8].body.type: CHANGE_TRUST
feeBump.tx.innerTx.tx.operations[8].body.changeTrustOp.line: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[8].body.changeTrustOp.limit: 100000000000
feeBump.tx.innerTx.tx.operations[9].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[9].body.type: ALLOW_TRUST
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.trustor: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.asset: MOON
feeBump.tx.innerTx.tx.operations[9].body.allowTrustOp.authorize: 1
feeBump.tx.innerTx.tx.operations[10].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[10].body.type: ACCOUNT_MERGE
feeBump.tx.innerTx.tx.operations[10].body.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operations[11].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[11].body.type: MANAGE_DATA
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataName: "Sommer"
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataValue._present: true
feeBump.tx.innerTx.tx.operations[11].body.manageDataOp.dataValue: 446965204df662656c2073696e6420686569df21
feeBump.tx.innerTx.tx.operations[12].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[12].body.type: BUMP_SEQUENCE
feeBump.tx.innerTx.tx.operations[12].body.bumpSequenceOp.bumpTo: 1102902109211
feeBump.tx.innerTx.tx.operations[13].sourceAccount._present: false
feeBump.tx.innerTx.tx.operations[13].body.type: MANAGE_BUY_OFFER
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.selling: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.buying: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.buyAmount: 120000000
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.price.d: 5
feeBump.tx.innerTx.tx.operations[13].body.manageBuyOfferOp.offerID: 9298298398334
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.innerTx.signatures.len: 1
feeBump.tx.innerTx.signatures[0].hint: 7b21e7e3
feeBump.tx.innerTx.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a
feeBump.tx.ext.v: 0
feeBump.signatures.len: 1
feeBump.signatures[0].hint: 7b21e7e3
feeBump.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a''';

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRepWithoutComments);
  });

  test('xdr test', () {
    String xdr =
        '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';
    String txrep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    String xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txrep);
    assert(xdr == xdr2);
  });
  test('fee bump transaction to txrep', () {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    Account a = Account(accountAId, 1102902109201);

    KeyPair keyPairB = KeyPair.random();
    String accountBId = keyPairB.accountId;

    Operation createAccount = new CreateAccountOperationBuilder(
            accountBId, "2200000000000000000020111229198190202020202.1230019")
        .build();
    Operation payment = new PaymentOperationBuilder(accountBId, Asset.NATIVE,
            "3333333000000000000020111229198190202020202.123333")
        .setSourceAccount(accountAId)
        .build();
    Asset nonNativeAsset = AssetTypeCreditAlphaNum4(
        "USD", "GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI");
    Operation nonNativePayment = new PaymentOperationBuilder(
            accountBId,
            nonNativeAsset,
            "3333333000000000000020111229198190202020202.123333")
        .setSourceAccount(accountAId)
        .build();

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);
    Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", keyPairA.accountId);
    Asset astroAsset = AssetTypeCreditAlphaNum12("ASTRO", keyPairA.accountId);
    Asset moonAsset = AssetTypeCreditAlphaNum4("MOON", keyPairA.accountId);
    List<Asset> path = [ecoAsset, astroAsset];
    PathPaymentStrictReceiveOperation strictReceive =
        PathPaymentStrictReceiveOperationBuilder(
                iomAsset, "2", accountBId, moonAsset, "8")
            .setPath(path)
            .build();

    PathPaymentStrictSendOperation strictSend =
        PathPaymentStrictSendOperationBuilder(
                iomAsset, "400", accountBId, moonAsset, "1200")
            .setPath(path)
            .build();

    ManageSellOfferOperation manageSellOfferOperation =
        ManageSellOfferOperationBuilder(ecoAsset, Asset.NATIVE, "8282", '0.7')
            .setOfferId('9298298398333')
            .build();
    ManageBuyOfferOperation manageBuyOfferOperation =
        ManageBuyOfferOperationBuilder(moonAsset, ecoAsset, "12", '0.2')
            .setOfferId('9298298398334')
            .build();

    CreatePassiveSellOfferOperation createPassiveSellOfferOperation =
        CreatePassiveSellOfferOperationBuilder(
                astroAsset, moonAsset, "2828", '0.5')
            .build();

    String limit = "10000";
    ChangeTrustOperation changeTrustOperation =
        ChangeTrustOperationBuilder(astroAsset, limit).build();

    AllowTrustOperation allowTrustOperation =
        AllowTrustOperationBuilder(accountBId, "MOON", 1).build();

    TimeBounds tb = TimeBounds(1595282368, 1595284000);
    MemoText mt = MemoText("Enjoy this transaction");

    XdrSignerKey signer =
        XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
    signer.ed25519 = XdrUint256(StrKey.decodeStellarAccountId(accountBId));

    SetOptionsOperation setOptionsOperation = SetOptionsOperationBuilder()
        .setInflationDestination(accountBId)
        .setClearFlags(2)
        .setSetFlags(4)
        .setMasterKeyWeight(122)
        .setLowThreshold(10)
        .setMediumThreshold(50)
        .setHighThreshold(122)
        .setSigner(signer, 50)
        .setHomeDomain("https://www.soneso.com/blubber")
        .build();

    AccountMergeOperation accountMergeOperation =
        AccountMergeOperationBuilder.forMuxedDestinationAccount(
                MuxedAccount(accountBId, 1010011222))
            .build();

    String key = "Sommer";
    String value = "Die Möbel sind heiß!";

    List<int> list = value.codeUnits;
    Uint8List valueBytes = Uint8List.fromList(list);

    ManageDataOperation manageDataOperation =
        ManageDataOperationBuilder(key, valueBytes).build();

    BumpSequenceOperation bumpSequenceOperation =
        BumpSequenceOperationBuilder(a.sequenceNumber + 10).build();

    Transaction transaction = new TransactionBuilder(a)
        .addTimeBounds(tb)
        .addMemo(mt)
        .addOperation(createAccount)
        .addOperation(payment)
        .addOperation(nonNativePayment)
        .addOperation(strictReceive)
        .addOperation(strictSend)
        .addOperation(setOptionsOperation)
        .addOperation(manageSellOfferOperation)
        .addOperation(createPassiveSellOfferOperation)
        .addOperation(changeTrustOperation)
        .addOperation(allowTrustOperation)
        .addOperation(accountMergeOperation)
        .addOperation(manageDataOperation)
        .addOperation(bumpSequenceOperation)
        .addOperation(manageBuyOfferOperation)
        .build();

    transaction.sign(keyPairA, Network.TESTNET);

    KeyPair keyPairC = KeyPair.random();
    FeeBumpTransaction feeBump = FeeBumpTransactionBuilder(transaction)
        .setMuxedFeeAccount(MuxedAccount(keyPairC.accountId, 110000))
        .setBaseFee(101)
        .build();
    feeBump.sign(keyPairC, Network.TESTNET);
    String transactionEnvelopeXdrBase64 = feeBump.toEnvelopeXdrBase64();
    print(transactionEnvelopeXdrBase64);
    String txrep =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    print(txrep);
    print('----------------');
    transactionEnvelopeXdrBase64 = transaction.toEnvelopeXdrBase64();
    print(transactionEnvelopeXdrBase64);
    txrep =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    print(txrep);
  });

  test('create claimable balance', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 100
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[0].body.type: CREATE_CLAIMABLE_BALANCE
tx.operations[0].body.createClaimableBalanceOp.asset: XLM
tx.operations[0].body.createClaimableBalanceOp.amount: 2900000000
tx.operations[0].body.createClaimableBalanceOp.claimants.len: 6
tx.operations[0].body.createClaimableBalanceOp.claimants[0].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.destination: GAF2EOTBIWV45XDG5O2QSIVXQ5KPI6EJIALVGI7VFOX7ENDNI6ONBYQO
tx.operations[0].body.createClaimableBalanceOp.claimants[0].v0.predicate.type: CLAIM_PREDICATE_UNCONDITIONAL
tx.operations[0].body.createClaimableBalanceOp.claimants[1].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[1].v0.destination: GCUEJ6YLQFWETNAXLIM3B3VN7CJISN6XLGXGDHQDVLWTYZODGSHRJWPS
tx.operations[0].body.createClaimableBalanceOp.claimants[1].v0.predicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[1].v0.predicate.relBefore: 400
tx.operations[0].body.createClaimableBalanceOp.claimants[2].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[2].v0.destination: GCWV5WETMS3RD2ZZUF7S3NQPEVMCXBCODMV7MIOUY4D3KR66W7ACL4LE
tx.operations[0].body.createClaimableBalanceOp.claimants[2].v0.predicate.type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[2].v0.predicate.absBefore: 1683723100
tx.operations[0].body.createClaimableBalanceOp.claimants[3].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.destination: GBOAHYPSVULLKLH4OMESGA5BGZTK37EYEPZVI2AHES6LANTCIUPFHUPE
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.type: CLAIM_PREDICATE_AND
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates.len: 2
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].type: CLAIM_PREDICATE_NOT
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].notPredicate._present: true
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].notPredicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[0].notPredicate.relBefore: 600
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[1].type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[3].v0.predicate.andPredicates[1].absBefore: 1683723100
tx.operations[0].body.createClaimableBalanceOp.claimants[4].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.destination: GDOA4UYIQ3A74WTHQ4BA56Z7F7NU7F34WP2KOGYHV4UXP2T5RXVEYLLF
tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.type: CLAIM_PREDICATE_OR
tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates.len: 2
tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[0].type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[0].absBefore: 1646723251
tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[1].type: CLAIM_PREDICATE_BEFORE_ABSOLUTE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[4].v0.predicate.orPredicates[1].absBefore: 1645723269
tx.operations[0].body.createClaimableBalanceOp.claimants[5].type: CLAIMANT_TYPE_V0
tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.destination: GBCZ2KRFMG7IGUSBTHXTJP3ULN2TK4F3EAYSVMS5X4MLOO3DT2LSISOR
tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.type: CLAIM_PREDICATE_NOT
tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.notPredicate._present: true
tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.notPredicate.type: CLAIM_PREDICATE_BEFORE_RELATIVE_TIME
tx.operations[0].body.createClaimableBalanceOp.claimants[5].v0.predicate.notPredicate.relBefore: 8000
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: 98f329b240374d898cfcb0171b37f495c488db1abd0e290c0678296e6db09d773e6e73f14a51a017808584d1c4dae13189e4539f4af8b81b6cc830fc43e9d500''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAADgAAAAAAAAAArNp9AAAAAAYAAAAAAAAAAAuiOmFFq87cZuu1CSK3h1T0eIlAF1Mj9Suv8jRtR5zQAAAAAAAAAAAAAAAAqET7C4FsSbQXWhmw7q34kok311muYZ4Dqu08ZcM0jxQAAAAFAAAAAAAAAZAAAAAAAAAAAK1e2JNktxHrOaF/LbYPJVgrhE4bK/Yh1McHtUfet8AlAAAABAAAAABkW5NcAAAAAAAAAABcA+HyrRa1LPxzCSMDoTZmrfyYI/NUaAckvLA2YkUeUwAAAAEAAAACAAAAAwAAAAEAAAAFAAAAAAAAAlgAAAAEAAAAAGRbk1wAAAAAAAAAANwOUwiGwf5aZ4cCDvs/L9tPl3yz9KcbB68pd+p9jepMAAAAAgAAAAIAAAAEAAAAAGInALMAAAAEAAAAAGIXvoUAAAAAAAAAAEWdKiVhvoNSQZnvNL90W3U1cLsgMSqyXb8YtztjnpckAAAAAwAAAAEAAAAFAAAAAAAAH0AAAAAAAAAAAezRl+8AAABAmPMpskA3TYmM/LAXGzf0lcSI2xq9DikMBngpbm2wnXc+bnPxSlGgF4CFhNHE2uExieRTn0r4uBtsyDD8Q+nVAA==";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    assert(txRepResult == txRep);
  });

  test('claim claimable balance', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 100
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CLAIM_CLAIMABLE_BALANCE
tx.operations[0].body.claimClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
tx.operations[0].body.claimClaimableBalanceOp.balanceID.v0: f69d8bb300b851590ab2f9d5ef3e5936a571d9d8dbb00b62013873e106adb93a
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: fec6e0b4d6b0ddd01c33a856a5d6d7ceeecfed8fe66f779419e4d5c5b8ef6922ea8f2476e1c2ba9c123fb43ecc8f43e538e56a7aa3239d4df8f7f9cb46e6ff0c''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAADwAAAAD2nYuzALhRWQqy+dXvPlk2pXHZ2NuwC2IBOHPhBq25OgAAAAAAAAAB7NGX7wAAAED+xuC01rDd0BwzqFal1tfO7s/tj+Zvd5QZ5NXFuO9pIuqPJHbhwrqcEj+0PsyPQ+U45Wp6oyOdTfj3+ctG5v8M";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    assert(txRepResult == txRep);
  });

  test('sponsoring', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 200
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 2
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[0].body.type: BEGIN_SPONSORING_FUTURE_RESERVES
tx.operations[0].body.beginSponsoringFutureReservesOp.sponsoredID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[1].sourceAccount._present: true
tx.operations[1].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[1].body.type: END_SPONSORING_FUTURE_RESERVES
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: 194a962d2f51ae1af1c4bfa3e8eeca7aa2b6654a84ac03de37d1738171e43f8ece2101fe6bd44cacd9f0bf10c93616cdfcf04639727a08ca84339fade990d40e''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAMgAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAEAAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAEAAAAARJW9RyahO88Zbk3lbcGLzpOAM9MN5KwMZ0rgROzRl+8AAAARAAAAAAAAAAHs0ZfvAAAAQBlKli0vUa4a8cS/o+juynqitmVKhKwD3jfRc4Fx5D+OziEB/mvUTKzZ8L8QyTYWzfzwRjlyegjKhDOfremQ1A4=";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    print(txRepResult);
    assert(txRepResult == txRep);
  });

  test('revoke sponsoring', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 800
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 8
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: REVOKE_SPONSORSHIP
tx.operations[0].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.type: ACCOUNT
tx.operations[0].body.revokeSponsorshipOp.ledgerKey.account.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[1].sourceAccount._present: false
tx.operations[1].body.type: REVOKE_SPONSORSHIP
tx.operations[1].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[1].body.revokeSponsorshipOp.ledgerKey.type: TRUSTLINE
tx.operations[1].body.revokeSponsorshipOp.ledgerKey.trustLine.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[1].body.revokeSponsorshipOp.ledgerKey.trustLine.asset: ACC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[2].sourceAccount._present: false
tx.operations[2].body.type: REVOKE_SPONSORSHIP
tx.operations[2].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[2].body.revokeSponsorshipOp.ledgerKey.type: OFFER
tx.operations[2].body.revokeSponsorshipOp.ledgerKey.offer.sellerID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[2].body.revokeSponsorshipOp.ledgerKey.offer.offerID: 293893
tx.operations[3].sourceAccount._present: false
tx.operations[3].body.type: REVOKE_SPONSORSHIP
tx.operations[3].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[3].body.revokeSponsorshipOp.ledgerKey.type: DATA
tx.operations[3].body.revokeSponsorshipOp.ledgerKey.data.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[3].body.revokeSponsorshipOp.ledgerKey.data.dataName: "Soneso"
tx.operations[4].sourceAccount._present: false
tx.operations[4].body.type: REVOKE_SPONSORSHIP
tx.operations[4].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_LEDGER_ENTRY
tx.operations[4].body.revokeSponsorshipOp.ledgerKey.type: CLAIMABLE_BALANCE
tx.operations[4].body.revokeSponsorshipOp.ledgerKey.claimableBalance.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
tx.operations[4].body.revokeSponsorshipOp.ledgerKey.claimableBalance.balanceID.v0: ceab14eebbdbfe25a1830e39e311c2180846df74947ba24a386b8314ccba6622
tx.operations[5].sourceAccount._present: true
tx.operations[5].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[5].body.type: REVOKE_SPONSORSHIP
tx.operations[5].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
tx.operations[5].body.revokeSponsorshipOp.signer.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[5].body.revokeSponsorshipOp.signer.signerKey: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[6].sourceAccount._present: false
tx.operations[6].body.type: REVOKE_SPONSORSHIP
tx.operations[6].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
tx.operations[6].body.revokeSponsorshipOp.signer.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[6].body.revokeSponsorshipOp.signer.signerKey: XD3J3C5TAC4FCWIKWL45L3Z6LE3KK4OZ3DN3AC3CAE4HHYIGVW4TUVTH
tx.operations[7].sourceAccount._present: false
tx.operations[7].body.type: REVOKE_SPONSORSHIP
tx.operations[7].body.revokeSponsorshipOp.type: REVOKE_SPONSORSHIP_SIGNER
tx.operations[7].body.revokeSponsorshipOp.signer.accountID: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[7].body.revokeSponsorshipOp.signer.signerKey: TD3J3C5TAC4FCWIKWL45L3Z6LE3KK4OZ3DN3AC3CAE4HHYIGVW4TVRW6
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: 73c223f85c34f1399e9af3322a638a8877987724567e452179a9f2b159a96a1dd4e63cfb8c54e7803aa2f3787492f255698ea536070fc3e3ad9f87e36a0e660c''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAyAAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAEgAAAAAAAAAAAAAAANsckvAQBXW3k2y4RII0grJp/OOnH95cepXI17IxxLNzAAAAAAAAABIAAAAAAAAAAQAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAFBQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAAAAAABIAAAAAAAAAAgAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAAABHwFAAAAAAAAABIAAAAAAAAAAwAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAZTb25lc28AAAAAAAAAAAASAAAAAAAAAAQAAAAAzqsU7rvb/iWhgw454xHCGAhG33SUe6JKOGuDFMy6ZiIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAEgAAAAEAAAAA2xyS8BAFdbeTbLhEgjSCsmn846cf3lx6lcjXsjHEs3MAAAAARJW9RyahO88Zbk3lbcGLzpOAM9MN5KwMZ0rgROzRl+8AAAAAAAAAEgAAAAEAAAAA2xyS8BAFdbeTbLhEgjSCsmn846cf3lx6lcjXsjHEs3MAAAAC9p2LswC4UVkKsvnV7z5ZNqVx2djbsAtiAThz4QatuToAAAAAAAAAEgAAAAEAAAAA2xyS8BAFdbeTbLhEgjSCsmn846cf3lx6lcjXsjHEs3MAAAAB9p2LswC4UVkKsvnV7z5ZNqVx2djbsAtiAThz4QatuToAAAAAAAAAAezRl+8AAABAc8Ij+Fw08TmemvMyKmOKiHeYdyRWfkUheanysVmpah3U5jz7jFTngDqi83h0kvJVaY6lNgcPw+Otn4fjag5mDA==";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    assert(txRepResult == txRep);
  });

  test('clawback', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 100
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[0].body.type: CLAWBACK
tx.operations[0].body.clawbackOp.asset: ACC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[0].body.clawbackOp.from: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[0].body.clawbackOp.amount: 2330000000
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: 336998785b7815aac464789d04735d06d0421c5f92d1307a9d164e270fa1a214d30d3f00260146a80a3bb0318c92058c05f6de07589b1172c4b6ab630c628c04''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAEwAAAAFBQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAANsckvAQBXW3k2y4RII0grJp/OOnH95cepXI17IxxLNzAAAAAIrg+oAAAAAAAAAAAezRl+8AAABAM2mYeFt4FarEZHidBHNdBtBCHF+S0TB6nRZOJw+hohTTDT8AJgFGqAo7sDGMkgWMBfbeB1ibEXLEtqtjDGKMBA==";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    assert(txRepResult == txRep);
  });

  test('clawback claimable balance', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 100
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: CLAWBACK_CLAIMABLE_BALANCE
tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.type: CLAIMABLE_BALANCE_ID_TYPE_V0
tx.operations[0].body.clawbackClaimableBalanceOp.balanceID.v0: f69d8bb300b851590ab2f9d5ef3e5936a571d9d8dbb00b62013873e106adb93a
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: 6db5b9ff8e89c2103971550a485754286d1f782aa7fac17e2553bbaec9ab3969794d0fd5ba6d0b4575b9c75c1c464337fee1b4e5592eb77877b7a72487acb909''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAGQAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAFAAAAAD2nYuzALhRWQqy+dXvPlk2pXHZ2NuwC2IBOHPhBq25OgAAAAAAAAAB7NGX7wAAAEBttbn/jonCEDlxVQpIV1QobR94Kqf6wX4lU7uuyas5aXlND9W6bQtFdbnHXBxGQzf+4bTlWS63eHe3pySHrLkJ";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    assert(txRepResult == txRep);
  });

  test('set trustline flags', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 200
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 2
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[0].body.type: SET_TRUST_LINE_FLAGS
tx.operations[0].body.setTrustLineFlagsOp.trustor: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[0].body.setTrustLineFlagsOp.asset: ACC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[0].body.setTrustLineFlagsOp.clearFlags: 6
tx.operations[0].body.setTrustLineFlagsOp.setFlags: 1
tx.operations[1].sourceAccount._present: false
tx.operations[1].body.type: SET_TRUST_LINE_FLAGS
tx.operations[1].body.setTrustLineFlagsOp.trustor: GDNRZEXQCACXLN4TNS4EJARUQKZGT7HDU4P54XD2SXENPMRRYSZXGYUX
tx.operations[1].body.setTrustLineFlagsOp.asset: BCC:GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[1].body.setTrustLineFlagsOp.clearFlags: 5
tx.operations[1].body.setTrustLineFlagsOp.setFlags: 2
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: 5d4569d07068fd4824c87bf531061cf962a820d9ac5d4fdda0a2728f035d154e5cc842aa8aa398bf8ba2f42577930af129c593832ab14ff02c25989eaf8fbf0b''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAMgAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAFQAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAFBQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAABgAAAAEAAAAAAAAAFQAAAADbHJLwEAV1t5NsuESCNIKyafzjpx/eXHqVyNeyMcSzcwAAAAFCQ0MAAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAABQAAAAIAAAAAAAAAAezRl+8AAABAXUVp0HBo/UgkyHv1MQYc+WKoINmsXU/doKJyjwNdFU5cyEKqiqOYv4ui9CV3kwrxKcWTgyqxT/AsJZier4+/Cw==";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    assert(txRepResult == txRep);
  });

  test('set liquidity pool', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.fee: 200
tx.seqNum: 2916609211498497
tx.cond.type: PRECOND_TIME
tx.cond.timeBounds.minTime: 0
tx.cond.timeBounds.maxTime: 0
tx.memo.type: MEMO_NONE
tx.operations.len: 2
tx.operations[0].sourceAccount._present: true
tx.operations[0].sourceAccount: GBCJLPKHE2QTXTYZNZG6K3OBRPHJHABT2MG6JLAMM5FOARHM2GL67VCW
tx.operations[0].body.type: LIQUIDITY_POOL_DEPOSIT
tx.operations[0].body.liquidityPoolDepositOp.liquidityPoolID: f69d8bb300b851590ab2f9d5ef3e5936a571d9d8dbb00b62013873e106adb93a
tx.operations[0].body.liquidityPoolDepositOp.maxAmountA: 1000000000
tx.operations[0].body.liquidityPoolDepositOp.maxAmountB: 2000000000
tx.operations[0].body.liquidityPoolDepositOp.minPrice.n: 20
tx.operations[0].body.liquidityPoolDepositOp.minPrice.d: 1
tx.operations[0].body.liquidityPoolDepositOp.maxPrice.n: 30
tx.operations[0].body.liquidityPoolDepositOp.maxPrice.d: 1
tx.operations[1].sourceAccount._present: false
tx.operations[1].body.type: LIQUIDITY_POOL_WITHDRAW
tx.operations[1].body.liquidityPoolWithdrawOp.liquidityPoolID: ceab14eebbdbfe25a1830e39e311c2180846df74947ba24a386b8314ccba6622
tx.operations[1].body.liquidityPoolWithdrawOp.amount: 9000000000
tx.operations[1].body.liquidityPoolWithdrawOp.minAmountA: 2000000000
tx.operations[1].body.liquidityPoolWithdrawOp.minAmountB: 4000000000
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: ecd197ef
signatures[0].signature: ed97d0d018a671c5a914a15346c1b38912d6695d1d152ffe976b8c9689ce2e7770b0e6cc8889c4a2423323898b087e5fbf43306ef7e63a75366befd3e2a9bd03''';

    String expected =
        "AAAAAgAAAABElb1HJqE7zxluTeVtwYvOk4Az0w3krAxnSuBE7NGX7wAAAMgAClykAAAAAQAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAABAAAAAESVvUcmoTvPGW5N5W3Bi86TgDPTDeSsDGdK4ETs0ZfvAAAAFvadi7MAuFFZCrL51e8+WTalcdnY27ALYgE4c+EGrbk6AAAAADuaygAAAAAAdzWUAAAAABQAAAABAAAAHgAAAAEAAAAAAAAAF86rFO672/4loYMOOeMRwhgIRt90lHuiSjhrgxTMumYiAAAAAhhxGgAAAAAAdzWUAAAAAADuaygAAAAAAAAAAAHs0ZfvAAAAQO2X0NAYpnHFqRShU0bBs4kS1mldHRUv/pdrjJaJzi53cLDmzIiJxKJCMyOJiwh+X79DMG735jp1Nmvv0+KpvQM=";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    print(txRepResult);
    assert(txRepResult == txRep);
  });

  test('xdr preconditions 1', () {
    String xdr =
        'AAAAAgAAAQAAAAAAABODoXOW2Y6q7AdenusH1X8NBxVPFXEW+/PQFDiBQV05qf4DAAAAZAAKAJMAAAACAAAAAgAAAAEAAAAAYnk1lQAAAABobxaVAAAAAQANnJQAHN7UAAAAAQAKAJMAAAABAAAAAAAAAAEAAAABAAAAAgAAAACUkeBPpCcGYCoqeszK1YjZ1Ww1qY6fRI02d2hKG1nqvwAAAAHW9EEhELfDtkfmtBrXuEgEpTBlO8E/iQ2ZI/uNXLDV9AAAAAEAAAAEdGVzdAAAAAEAAAABAAABAAAAAAAAE4Ohc5bZjqrsB16e6wfVfw0HFU8VcRb789AUOIFBXTmp/gMAAAABAAABAAAAAAJPOttvlJHgT6QnBmAqKnrMytWI2dVsNamOn0SNNndoShtZ6r8AAAAAAAAAAADk4cAAAAAAAAAAATmp/gMAAABAvm+8CxO9sj4KEDwSS6hDxZAiUGdpIN2l+KOxTIkdI2joBFjT9B1U9YaORVDx4LTrLd4QM2taUuzXB51QtDQYDA==';
    String txrep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    print(txrep);
    String xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txrep);
    assert(xdr == xdr2);
  });

  test('xdr preconditions 2', () {
    String xdr =
        'AAAAAgAAAQAAAAAAABODoa9e0m5apwHpUf3/HzJOJeQ5q7+CwSWrnHXENS8XoAfmAAAAZAAJ/s4AAAACAAAAAgAAAAEAAAAAYnk1lQAAAABobxaVAAAAAQANnJQAHN7UAAAAAQAJ/s4AAAABAAAAAAAAAAEAAAABAAAAAgAAAAJulGoyRpAB8JhKT+ffEiXh8Kgd8qrEXfiG3aK69JgQlAAAAAM/DDS/k60NmXHQTMyQ9wVRHIOKrZc0pKL7DXoD/H/omgAAACABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4fIAAAAAEAAAAEdGVzdAAAAAEAAAABAAABAAAAAAAAE4Ohr17SblqnAelR/f8fMk4l5Dmrv4LBJaucdcQ1LxegB+YAAAABAAABAAAAAAJPOttvipEw04NyfzwAhgQlf2S77YVGYbytcXKVNuM46+sMNAYAAAAAAAAAAADk4cAAAAAAAAAAARegB+YAAABAJG8wTpECV0rpq3TV9d26UL0MULmDxXKXGmKSJLiy9NCNJW3WMcrvrA6wiBsLHuCN7sIurD3o1/AKgntagup3Cw==';
    String txrep = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    print(txrep);
    String xdr2 = TxRep.transactionEnvelopeXdrBase64FromTxRep(txrep);
    assert(xdr == xdr2);
  });

  test('xdr preconditions 3', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBGZGXYWXZ65XBD4Q4UTOMIDXRZ5X5OJGNC54IQBLSPI2DDB5VGFZO2V
tx.fee: 6000
tx.seqNum: 5628434382323746
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: PAYMENT
tx.operations[0].body.paymentOp.destination: GD53ZDEHFQPY25NBF6NPDYEA5IWXSS5FYMLQ3AE6AIGAO75XQK7SIVNU
tx.operations[0].body.paymentOp.asset: XLM
tx.operations[0].body.paymentOp.amount: 100000000
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 61ed4c5c
signatures[0].signature: bd33b8de6ca4354d653329e4cfd2f012a3c155c816bca8275721bd801defb868642e2cd49330e904d2df270b4a2c95359536ba81eed9775c5982e411ac9c3909''';

    String expected =
        "AAAAAgAAAABNk18Wvn3bhHyHKTcxA7xz2/XJM0XeIgFcno0MYe1MXAAAF3AAE/8IAAAAIgAAAAAAAAAAAAAAAQAAAAAAAAABAAAAAPu8jIcsH411oS+a8eCA6i15S6XDFw2AngIMB3+3gr8kAAAAAAAAAAAF9eEAAAAAAAAAAAFh7UxcAAAAQL0zuN5spDVNZTMp5M/S8BKjwVXIFryoJ1chvYAd77hoZC4s1JMw6QTS3ycLSiyVNZU2uoHu2XdcWYLkEaycOQk=";

    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == xdr);
    String txRepResult = TxRep.fromTransactionEnvelopeXdrBase64(xdr);
    print(txRepResult);
    assert(txRepResult == txRep);
  });

  test('soroban txRep', () {
    var invokeXdr =
        "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";
    String txRep = TxRep.fromTransactionEnvelopeXdrBase64(invokeXdr);
    //print(txRep);
    String xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(invokeXdr == xdr);

    var uploadContractXdr =
        "AAAAAgAAAABIX3Dc+6c1k4NV9BfTH6V5dracuPihPEgfi738DuxO1AABDGUAHd+JAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAgAAAhsAYXNtAQAAAAEPA2ACfn4BfmABfgF+YAAAAgcBAXYBZwAAAwMCAQIFAwEAEAYZA38BQYCAwAALfwBBgIDAAAt/AEGAgMAACwcxBQZtZW1vcnkCAAVoZWxsbwABAV8AAgpfX2RhdGFfZW5kAwELX19oZWFwX2Jhc2UDAgrIAQLCAQECfyOAgICAAEEgayIBJICAgIAAAkACQCAAp0H/AXEiAkEORg0AIAJBygBHDQELIAEgADcDCCABQo7o8di6AjcDAEEAIQIDQAJAIAJBEEcNAEEAIQICQANAIAJBEEYNASABQRBqIAJqIAEgAmopAwA3AwAgAkEIaiECDAALCyABQRBqrUIghkIEhEKEgICAIBCAgICAACEAIAFBIGokgICAgAAgAA8LIAFBEGogAmpCAjcDACACQQhqIQIMAAsLAAALAgALAEMOY29udHJhY3RzcGVjdjAAAAAAAAAAAAAAAAVoZWxsbwAAAAAAAAEAAAAAAAAAAnRvAAAAAAARAAAAAQAAA+oAAAARAB4RY29udHJhY3RlbnZtZXRhdjAAAAAAAAAAFAAAAAAAbw5jb250cmFjdG1ldGF2MAAAAAAAAAAFcnN2ZXIAAAAAAAAGMS43NC4xAAAAAAAAAAAACHJzc2RrdmVyAAAALzIwLjAuMCM4MjJjZTZjYzNlNDYxY2NjOTI1Mjc1YjQ3MmQ3N2I2Y2EzNWIyY2Q5AAAAAAAAAAAAAQAAAAAAAAABAAAAB8GmUFBvfCDI9NFqrnP4lPMCzQEdfvM63vVy8gs092U+AAAAAAAX8g8AAAKAAAAAAAAAAAAAAQwBAAAAAQ7sTtQAAABAxNCu+lC8Xuee36jeGsz7YXNEBvg3Eq6Wqd0ZQ6qnLv8LpxbubpDOzFo86rcpAAWzO70Wdyl3op2ZRSHzsnaRDg==";
    txRep = TxRep.fromTransactionEnvelopeXdrBase64(uploadContractXdr);
    //print(txRep);
    xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(uploadContractXdr == xdr);

    var createContractXdr =
        "AAAAAgAAAABIX3Dc+6c1k4NV9BfTH6V5dracuPihPEgfi738DuxO1AAWOa0AHd+JAAAABAAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAAAAAAAAAAAAEhfcNz7pzWTg1X0F9MfpXl2tpy4+KE8SB+LvfwO7E7Uim0WqDBGeseONDCj0peIZwJ4EOMpvMrpcR5GXffg4AkAAAAAwaZQUG98IMj00Wquc/iU8wLNAR1+8zre9XLyCzT3ZT4AAAABAAAAAAAAAAEAAAAAAAAAAAAAAABIX3Dc+6c1k4NV9BfTH6V5dracuPihPEgfi738DuxO1IptFqgwRnrHjjQwo9KXiGcCeBDjKbzK6XEeRl334OAJAAAAAMGmUFBvfCDI9NFqrnP4lPMCzQEdfvM63vVy8gs092U+AAAAAAAAAAEAAAAAAAAAAQAAAAfBplBQb3wgyPTRaq5z+JTzAs0BHX7zOt71cvILNPdlPgAAAAEAAAAGAAAAAXw9vhysdvciUg3nErv76mvhqOiPxqaxaUhacQTpSiicAAAAFAAAAAEAAlNNAAACgAAAAGgAAAAAABY5SQAAAAEO7E7UAAAAQN4uzM1B4G60lKSmytQbCS8zfwyi274rFhotmwBZN6qBb5ksBbVqC5r2q4QqxeJgxdXD5IjysZbFuUmTDbeS/QQ=";
    txRep = TxRep.fromTransactionEnvelopeXdrBase64(createContractXdr);
    //print(txRep);
    xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(createContractXdr == xdr);

    var restoreFootprintXdr =
        "AAAAAgAAAAC+5AsLKJXPTGnveUAhL2cjFaOe6mneuq0bWVUbZttrKQAB1kkAHeCGAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAaAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC2XAAAAAFm22spAAAAQPvw3PtxT3tzS15GMDjNUa0i7bykd0BJbr4O43QqrujSYe8RBv3Z6pj6e5dfQST6nz2BfUKB1bzXavNUPdDpTA8=";
    txRep = TxRep.fromTransactionEnvelopeXdrBase64(restoreFootprintXdr);
    //print(txRep);
    xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(restoreFootprintXdr == xdr);

    var extendFootprintXdr =
        "AAAAAgAAAAC+5AsLKJXPTGnveUAhL2cjFaOe6mneuq0bWVUbZttrKQAAtwUAHeCGAAAAAwAAAAAAAAAAAAAAAQAAAAAAAAAZAAAAAAAAJxAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAtqEAAAABZttrKQAAAEAeae7iCVUwUOWlG1ai0z9GfswZstfWW8x0iC+bvtqWvYvrkIFA4Hy6ZpCsvWgPcljuDN5X8oiy2WT15egFcFUB";
    txRep = TxRep.fromTransactionEnvelopeXdrBase64(extendFootprintXdr);
    //print(txRep);
    xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(extendFootprintXdr == xdr);

    var deploySacWithAssetXdr =
        "AAAAAgAAAABxW9E8HvJ8y/Uo60YQVQRdVxbZXkyyqJC//cKccViIQgBivo0AHeDLAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAEAAAACU09ORVNPAAAAAAAAAAAAAHFb0Twe8nzL9SjrRhBVBF1XFtleTLKokL/9wpxxWIhCAAAAAQAAAAAAAAABAAAAAAAAAAAAAAABAAAABgAAAAF2AfJVgDq1MvSnUdklLI+KInZbJj/1BbL2GfVMBtwTKQAAABQAAAABAAK6lgAAAAAAAAHoAAAAAABivikAAAABcViIQgAAAEBSslktJS0iD3ObWkvXUQetp459tfnQyL3acMFhdl9H7wmUCj6UWzvZmt/X5mt/wmJlxnsyHBX6TkQv4jFkIWcG";
    txRep = TxRep.fromTransactionEnvelopeXdrBase64(deploySacWithAssetXdr);
    //print(txRep);
    xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(deploySacWithAssetXdr == xdr);

    var deploySacWithSrcAccXdr =
        "AAAAAgAAAAAbabUDd9S4GOPKgqESpn8By1G0TregWA0BWOfVFU66bAAPsTsAHeDKAAAABgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAAAAAAAAAAAABtptQN31LgY48qCoRKmfwHLUbROt6BYDQFY59UVTrpsvNipWcbiYhu2d8eo1jDinP914WszeL5g2tae6RwdHB4AAAABAAAAAQAAAAAAAAABAAAAAAAAAAAAAAAAG2m1A3fUuBjjyoKhEqZ/ActRtE63oFgNAVjn1RVOumy82KlZxuJiG7Z3x6jWMOKc/3XhazN4vmDa1p7pHB0cHgAAAAEAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAYAAAABPTcI9wETxIwLcM+S1/4yEsjMC/JU6l/Td2jwUvEQx4kAAAAUAAAAAQABuoEAAAAAAAAASAAAAAAAD7DXAAAAARVOumwAAABAZ8jZ2vKUTeuPjyeQBkj+pGJdzWATUXoSAlzo+5BeXhZsv5WizK+2kdEX4aeJULBnF/H+6AL9YLCqMjkmhvJ5BQ==";
    txRep = TxRep.fromTransactionEnvelopeXdrBase64(deploySacWithSrcAccXdr);
    //print(txRep);
    xdr = TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(deploySacWithSrcAccXdr == xdr);
  });

/*
  test('soroban install contract code txRep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDBTMUPR2TKKCZDDCHVSDUCQBQAWGKZW2A7AHPP4UUCNDU4YUQMBEHSV
tx.fee: 100
tx.seqNum: 1480762989740033
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.function.installContractCodeArgs.code: 0061736d01000000010f0360017e017e60027e7e017e6000000219040176015f000001780138000001760134000101760136000103030200020503010001060b027f0141000b7f0141000b071d030568656c6c6f0004066d656d6f727902000873646b737461727400050c01060ac70302b20302067f027e4202100021082300220441046a2201411c6a22053f002203411074410f6a41707122064b04402003200520066b41ffff036a4180807c714110762206200320064a1b40004100480440200640004100480440000b0b0b200524002004411c360200200141046b22034100360204200341003602082003410336020c200341083602102001420037031020012008370310419c0928020041017641094b044042831010011a0b03402002419c092802004101764804402002419c092802004101764f047f417f05200241017441a0096a2f01000b220341fa004c200341304e7104402007420686210842002107200341ff017141df004604404201210705200341ff0171220441394d200441304f710440200341ff0171ad422e7d210705200341ff0171220441da004d200441c1004f710440200341ff0171ad42357d210705200341ff0171220441fa004d200441e1004f710440200341ff0171ad423b7d21070542831010011a0b0b0b0b200720088421070542831010011a0b200241016a21020c010b0b200120012903102007420886420e841002370310200120012903102000100337031020012903100b1100230104400f0b4101240141ac0924000b0b8d010600418c080b013c004198080b2f010000002800000041006c006c006f0063006100740069006f006e00200074006f006f0020006c00610072006700650041cc080b013c0041d8080b25010000001e0000007e006c00690062002f00720074002f0073007400750062002e0074007300418c090b011c004198090b11010000000a000000480065006c006c006f001e11636f6e7472616374656e766d657461763000000000000000000000002000430e636f6e747261637473706563763000000000000000000000000568656c6c6f000000000000010000000000000002746f00000000001100000001000003ea00000011
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractCode.hash: 3c2852fb06f47f4f371ac1b13472ae65ce3354c8af3001e66896cea08358b554
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 98a41812
signatures[0].signature: 6cb05049158787df9df2019c865b618f8731498cea25b14eee7a369af2167cca7b304a0981783998685ea89a64eb3e98f52811ffa168524f7b6e67d14e18be01''';

    String expected =
        "AAAAAgAAAADDNlHx1NShZGMR6yHQUAwBYys20D4DvfylBNHTmKQYEgAAAGQABUK/AAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAgAAAywAYXNtAQAAAAEPA2ABfgF+YAJ+fgF+YAAAAhkEAXYBXwAAAXgBOAAAAXYBNAABAXYBNgABAwMCAAIFAwEAAQYLAn8BQQALfwFBAAsHHQMFaGVsbG8ABAZtZW1vcnkCAAhzZGtzdGFydAAFDAEGCscDArIDAgZ/An5CAhAAIQgjACIEQQRqIgFBHGoiBT8AIgNBEHRBD2pBcHEiBksEQCADIAUgBmtB//8DakGAgHxxQRB2IgYgAyAGShtAAEEASARAIAZAAEEASARAAAsLCyAFJAAgBEEcNgIAIAFBBGsiA0EANgIEIANBADYCCCADQQM2AgwgA0EINgIQIAFCADcDECABIAg3AxBBnAkoAgBBAXZBCUsEQEKDEBABGgsDQCACQZwJKAIAQQF2SARAIAJBnAkoAgBBAXZPBH9BfwUgAkEBdEGgCWovAQALIgNB+gBMIANBME5xBEAgB0IGhiEIQgAhByADQf8BcUHfAEYEQEIBIQcFIANB/wFxIgRBOU0gBEEwT3EEQCADQf8Bca1CLn0hBwUgA0H/AXEiBEHaAE0gBEHBAE9xBEAgA0H/AXGtQjV9IQcFIANB/wFxIgRB+gBNIARB4QBPcQRAIANB/wFxrUI7fSEHBUKDEBABGgsLCwsgByAIhCEHBUKDEBABGgsgAkEBaiECDAELCyABIAEpAxAgB0IIhkIOhBACNwMQIAEgASkDECAAEAM3AxAgASkDEAsRACMBBEAPC0EBJAFBrAkkAAsLjQEGAEGMCAsBPABBmAgLLwEAAAAoAAAAQQBsAGwAbwBjAGEAdABpAG8AbgAgAHQAbwBvACAAbABhAHIAZwBlAEHMCAsBPABB2AgLJQEAAAAeAAAAfgBsAGkAYgAvAHIAdAAvAHMAdAB1AGIALgB0AHMAQYwJCwEcAEGYCQsRAQAAAAoAAABIAGUAbABsAG8AHhFjb250cmFjdGVudm1ldGF2MAAAAAAAAAAAAAAAIABDDmNvbnRyYWN0c3BlY3YwAAAAAAAAAAAAAAAFaGVsbG8AAAAAAAABAAAAAAAAAAJ0bwAAAAAAEQAAAAEAAAPqAAAAEQAAAAEAAAAHPChS+wb0f083GsGxNHKuZc4zVMivMAHmaJbOoINYtVQAAAAAAAAAAAAAAAAAAAABmKQYEgAAAEBssFBJFYeH353yAZyGW2GPhzFJjOolsU7uejaa8hZ8ynswSgmBeDmYaF6ommTrPpj1KBH/oWhST3tuZ9FOGL4B";

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('soroban create contract txRep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDBTMUPR2TKKCZDDCHVSDUCQBQAWGKZW2A7AHPP4UUCNDU4YUQMBEHSV
tx.fee: 100
tx.seqNum: 1480762989740034
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.type: SCCONTRACT_CODE_WASM_REF
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.wasm_id: 3c2852fb06f47f4f371ac1b13472ae65ce3354c8af3001e66896cea08358b554
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.type: CONTRACT_ID_FROM_SOURCE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.salt: f08671c76d71ebe297b71ef2eedb131c1f31c3e99749289fb5f1673c8779d8bf
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractCode.hash: 3c2852fb06f47f4f371ac1b13472ae65ce3354c8af3001e66896cea08358b554
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 2941f74968f504d697365aeb36b32e3a9e771025faf7f983d7d2e18b65ea8c8f
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 98a41812
signatures[0].signature: 320de04c50a28cda01f49352a55a3cd0b2ae7ea05aafbdf6548bcb05148e3b20eebebae625a5e684c83f29ada9f56d35d09267f8f8d5749a7ca3e030d0fcc107''';

    String expected =
        "AAAAAgAAAADDNlHx1NShZGMR6yHQUAwBYys20D4DvfylBNHTmKQYEgAAAGQABUK/AAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAADwhnHHbXHr4pe3HvLu2xMcHzHD6ZdJKJ+18Wc8h3nYvwAAAAA8KFL7BvR/TzcawbE0cq5lzjNUyK8wAeZols6gg1i1VAAAAAEAAAAHPChS+wb0f083GsGxNHKuZc4zVMivMAHmaJbOoINYtVQAAAABAAAABilB90lo9QTWlzZa6zazLjqedxAl+vf5g9fS4Ytl6oyPAAAAFAAAAAAAAAAAAAAAAZikGBIAAABAMg3gTFCijNoB9JNSpVo80LKufqBar732VIvLBRSOOyDuvrrmJaXmhMg/Ka2p9W010JJn+PjVdJp8o+Aw0PzBBw==";

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('soroban invoke contract txRep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDBTMUPR2TKKCZDDCHVSDUCQBQAWGKZW2A7AHPP4UUCNDU4YUQMBEHSV
tx.fee: 100
tx.seqNum: 1480762989740035
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 3
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].bytes: 2941f74968f504d697365aeb36b32e3a9e771025faf7f983d7d2e18b65ea8c8f
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: hello
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].sym: friend
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.contractID: 2941f74968f504d697365aeb36b32e3a9e771025faf7f983d7d2e18b65ea8c8f
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractCode.hash: 3c2852fb06f47f4f371ac1b13472ae65ce3354c8af3001e66896cea08358b554
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 98a41812
signatures[0].signature: a8521e2d0b8132b5374566f76a10f5a500bb6e36c9e483ff34f429a9f4bcb5d11e8eb954b20bc605ddc1e7adff8ada27f7186df0f05ca9ced433075a2ddcc60d''';

    String expected =
        "AAAAAgAAAADDNlHx1NShZGMR6yHQUAwBYys20D4DvfylBNHTmKQYEgAAAGQABUK/AAAAAwAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAMAAAANAAAAIClB90lo9QTWlzZa6zazLjqedxAl+vf5g9fS4Ytl6oyPAAAADwAAAAVoZWxsbwAAAAAAAA8AAAAGZnJpZW5kAAAAAAACAAAABilB90lo9QTWlzZa6zazLjqedxAl+vf5g9fS4Ytl6oyPAAAAFAAAAAc8KFL7BvR/TzcawbE0cq5lzjNUyK8wAeZols6gg1i1VAAAAAAAAAAAAAAAAAAAAAGYpBgSAAAAQKhSHi0LgTK1N0Vm92oQ9aUAu242yeSD/zT0Kan0vLXRHo65VLILxgXdweet/4raJ/cYbfDwXKnO1DMHWi3cxg0=";

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('soroban deploy sac with source account txRep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDBTMUPR2TKKCZDDCHVSDUCQBQAWGKZW2A7AHPP4UUCNDU4YUQMBEHSV
tx.fee: 100
tx.seqNum: 1480762989740037
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.type: SCCONTRACT_CODE_TOKEN
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.type: CONTRACT_ID_FROM_SOURCE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.salt: b8bcf30dd1512f076e2e0e2e53f4f1c9a75678a74e6d9034fd8440b26d77f077
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 0
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 3ac5b88be7b5b8793e02c5992e4b24f10b27351a8babf1b9f938b0fb372cb01f
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 98a41812
signatures[0].signature: fb76fa3f7f048d16c641c1d853d8eba9e136ecf139bab8c4eb2a5fe1494ff347ad0d3fc3189c3475ea550704169dffc871e399b7aa5c5c9a69155994d0572e07''';

    String expected =
        "AAAAAgAAAADDNlHx1NShZGMR6yHQUAwBYys20D4DvfylBNHTmKQYEgAAAGQABUK/AAAABQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAC4vPMN0VEvB24uDi5T9PHJp1Z4p05tkDT9hECybXfwdwAAAAEAAAAAAAAAAQAAAAY6xbiL57W4eT4CxZkuSyTxCyc1Gour8bn5OLD7NyywHwAAABQAAAAAAAAAAAAAAAGYpBgSAAAAQPt2+j9/BI0WxkHB2FPY66nhNuzxObq4xOsqX+FJT/NHrQ0/wxicNHXqVQcEFp3/yHHjmbeqXFyaaRVZlNBXLgc=";

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('soroban deploy sac with asset txRep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDMQRURGSSY2MUFGCC6YITK7MKEFX6PH7MIFZJGQF5GJXRCGAALAALQB
tx.fee: 100
tx.seqNum: 1480793054511106
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.type: SCCONTRACT_CODE_TOKEN
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.type: CONTRACT_ID_FROM_ASSET
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.asset: Fsdk:GDMQRURGSSY2MUFGCC6YITK7MKEFX6PH7MIFZJGQF5GJXRCGAALAALQB
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 0
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 3
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 7d2ea92d3b334b6dfc2204d26004894092b66da94637914dc41e516f01db2e71
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.vec._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.vec.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.vec[0].sym: Admin
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.contractID: 7d2ea92d3b334b6dfc2204d26004894092b66da94637914dc41e516f01db2e71
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.type: SCV_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.vec._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.vec.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.vec[0].sym: Metadata
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.contractID: 7d2ea92d3b334b6dfc2204d26004894092b66da94637914dc41e516f01db2e71
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 46001600
signatures[0].signature: c93d1f2cfafb0a5985cd66844c0c058cd36a1f58f6ee0afe7061b4074134e74bc94279d03dade7bc4fd1773266c2a410c17956af846f3fab71489298e337fd0e''';

    String expected =
        "AAAAAgAAAADZCNImlLGmUKYQvYRNX2KIW/nn+xBcpNAvTJvERgAWAAAAAGQABULGAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAIAAAABRnNkawAAAADZCNImlLGmUKYQvYRNX2KIW/nn+xBcpNAvTJvERgAWAAAAAAEAAAAAAAAAAwAAAAZ9LqktOzNLbfwiBNJgBIlAkrZtqUY3kU3EHlFvAdsucQAAABAAAAABAAAAAQAAAA8AAAAFQWRtaW4AAAAAAAAGfS6pLTszS238IgTSYASJQJK2balGN5FNxB5RbwHbLnEAAAAQAAAAAQAAAAEAAAAPAAAACE1ldGFkYXRhAAAABn0uqS07M0tt/CIE0mAEiUCStm2pRjeRTcQeUW8B2y5xAAAAFAAAAAAAAAAAAAAAAUYAFgAAAABAyT0fLPr7ClmFzWaETAwFjNNqH1j27gr+cGG0B0E050vJQnnQPa3nvE/RdzJmwqQQwXlWr4RvP6txSJKY4zf9Dg==";

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('soroban invoke auth 1', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GBAKHYCEKMHP4ZG3GJBGTQ75DMAFYN2IDEJI54QGHRZU3WP6MPOHCWCK
tx.fee: 100
tx.seqNum: 1481510314049539
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 4
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].bytes: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: auth
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].u32: 3
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 3
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].account.accountID: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.contractID: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractCode.hash: 185b8c6d92815faa9da6b69fdb8ec62f439bf967ffd51751b6e8c116b15edd26
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.contractID: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.type: SCV_LEDGER_KEY_NONCE
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.nonce_key.nonce_address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.nonce_key.nonce_address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.auth.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.nonce: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.contractID: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.functionName: auth
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].u32: 3
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].type: SCV_MAP
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].key.sym: public_key
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].val.type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].val.bytes: d5b27e662a7f6b6a8089b4efe975f48ad5d93502b30f99dfcebf3e7d509b8965
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].key.sym: signature
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].val.type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].val.bytes: dca9acad3dac4d217661dd0a1221b52f1d3f7145610bd8b13ccc5c2083ce6fb0cfaba3ecdbb999e4dde5161f0434d4f1d51b34f252ce8d4404e799eae43c740c
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: fe63dc71
signatures[0].signature: c751f2070d6f2d0adea75f216122618b3f0508114bb3888bd0bb318a98afd92aa38da37ea7787953d3b6c0d53894ef7cc54712ca851288d9d6d25b95467b9006''';

    String expected =
        "AAAAAgAAAABAo+BEUw7+ZNsyQmnD/RsAXDdIGRKO8gY8c03Z/mPccQAAAGQABUNtAAAAAwAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAQAAAANAAAAIHdgdu9bvHfDxFxcnz6M8RHltnfJ5AxZcTalbrBZPSyXAAAADwAAAARhdXRoAAAAEwAAAAAAAAAA1bJ+Zip/a2qAibTv6XX0itXZNQKzD5nfzr8+fVCbiWUAAAADAAAAAwAAAAMAAAAAAAAAANWyfmYqf2tqgIm07+l19IrV2TUCsw+Z386/Pn1Qm4llAAAABndgdu9bvHfDxFxcnz6M8RHltnfJ5AxZcTalbrBZPSyXAAAAFAAAAAcYW4xtkoFfqp2mtp/bjsYvQ5v5Z//VF1G26MEWsV7dJgAAAAIAAAAGd2B271u8d8PEXFyfPozxEeW2d8nkDFlxNqVusFk9LJcAAAATAAAAAAAAAADVsn5mKn9raoCJtO/pdfSK1dk1ArMPmd/Ovz59UJuJZQAAAAZ3YHbvW7x3w8RcXJ8+jPER5bZ3yeQMWXE2pW6wWT0slwAAABUAAAAAAAAAANWyfmYqf2tqgIm07+l19IrV2TUCsw+Z386/Pn1Qm4llAAAAAQAAAAEAAAAAAAAAANWyfmYqf2tqgIm07+l19IrV2TUCsw+Z386/Pn1Qm4llAAAAAAAAAAB3YHbvW7x3w8RcXJ8+jPER5bZ3yeQMWXE2pW6wWT0slwAAAARhdXRoAAAAAgAAABMAAAAAAAAAANWyfmYqf2tqgIm07+l19IrV2TUCsw+Z386/Pn1Qm4llAAAAAwAAAAMAAAAAAAAAAQAAABAAAAABAAAAAQAAABEAAAABAAAAAgAAAA8AAAAKcHVibGljX2tleQAAAAAADQAAACDVsn5mKn9raoCJtO/pdfSK1dk1ArMPmd/Ovz59UJuJZQAAAA8AAAAJc2lnbmF0dXJlAAAAAAAADQAAAEDcqaytPaxNIXZh3QoSIbUvHT9xRWEL2LE8zFwgg85vsM+ro+zbuZnk3eUWHwQ01PHVGzTyUs6NRATnmerkPHQMAAAAAAAAAAH+Y9xxAAAAQMdR8gcNby0K3qdfIWEiYYs/BQgRS7OIi9C7MYqYr9kqo42jfqd4eVPTtsDVOJTvfMVHEsqFEojZ1tJblUZ7kAY=";

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('soroban invoke auth 2', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.fee: 100
tx.seqNum: 1481514609016833
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 4
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].bytes: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: auth
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].u32: 3
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.contractID: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractCode.hash: 185b8c6d92815faa9da6b69fdb8ec62f439bf967ffd51751b6e8c116b15edd26
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.auth.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce._present: false
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.contractID: 776076ef5bbc77c3c45c5c9f3e8cf111e5b677c9e40c597136a56eb0593d2c97
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.functionName: auth
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].address.accountId: GDK3E7TGFJ7WW2UARG2O72LV6SFNLWJVAKZQ7GO7Z27T47KQTOEWLTJ4
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].u32: 3
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 509b8965
signatures[0].signature: 50c98146c951de3883433308925fe738699b3b911eb171f20e8c4cfcc22f97c0a16ec83c93307bf8085eb0f25440b133ed01f9e51d3ca6b97f3846e82220db0b''';

    String expected =
        "AAAAAgAAAADVsn5mKn9raoCJtO/pdfSK1dk1ArMPmd/Ovz59UJuJZQAAAGQABUNuAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAQAAAANAAAAIHdgdu9bvHfDxFxcnz6M8RHltnfJ5AxZcTalbrBZPSyXAAAADwAAAARhdXRoAAAAEwAAAAAAAAAA1bJ+Zip/a2qAibTv6XX0itXZNQKzD5nfzr8+fVCbiWUAAAADAAAAAwAAAAIAAAAGd2B271u8d8PEXFyfPozxEeW2d8nkDFlxNqVusFk9LJcAAAAUAAAABxhbjG2SgV+qnaa2n9uOxi9Dm/ln/9UXUbbowRaxXt0mAAAAAQAAAAZ3YHbvW7x3w8RcXJ8+jPER5bZ3yeQMWXE2pW6wWT0slwAAABMAAAAAAAAAANWyfmYqf2tqgIm07+l19IrV2TUCsw+Z386/Pn1Qm4llAAAAAQAAAAB3YHbvW7x3w8RcXJ8+jPER5bZ3yeQMWXE2pW6wWT0slwAAAARhdXRoAAAAAgAAABMAAAAAAAAAANWyfmYqf2tqgIm07+l19IrV2TUCsw+Z386/Pn1Qm4llAAAAAwAAAAMAAAAAAAAAAAAAAAAAAAABUJuJZQAAAEBQyYFGyVHeOINDMwiSX+c4aZs7kR6xcfIOjEz8wi+XwKFuyDyTMHv4CF6w8lRAsTPtAfnlHTymuX84RugiINsL";


    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });

  test('soroban invoke auth 3', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GACGE76ZI5GZK66YHK5IOZHQ6V5N5243MUYEDMBIOCCPMEDED42SEKRQ
tx.fee: 100
tx.seqNum: 1481776602021901
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 10
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].bytes: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: swap
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].address.accountId: GBRCWMTNF7Z5GKQFHJ35GO4OKMH4I56V2THEBKRHDQ4ULGYELZX7KYPC
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].address.accountId: GC7ZOYTNA5PRGFU2BAP4H6CTFXPAG46Y2Z3SJV6BNRPP56ET5R7L3ZEM
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[4].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[4].bytes: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[5].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[5].bytes: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].i128.lo: 1000
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].i128.lo: 4500
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].i128.lo: 5000
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].i128.lo: 950
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 9
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].account.accountID: GBRCWMTNF7Z5GKQFHJ35GO4OKMH4I56V2THEBKRHDQ4ULGYELZX7KYPC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].account.accountID: GC7ZOYTNA5PRGFU2BAP4H6CTFXPAG46Y2Z3SJV6BNRPP56ET5R7L3ZEM
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.contractID: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].contractData.contractID: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].contractData.key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].contractData.key.sym: Authorizd
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.contractID: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[5].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[5].contractData.contractID: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[5].contractData.key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[5].contractData.key.sym: Authorizd
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[6].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[6].contractData.contractID: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[6].contractData.key.type: SCV_LEDGER_KEY_CONTRACT_EXECUTABLE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[7].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[7].contractCode.hash: 45f7a27e1e9c33ba1ac0f13ad276a1929367624c5edd95dbdfeeba0ab959b991
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[8].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[8].contractCode.hash: ff0071b0fe9460c8ffb06b993822fd121b2bcdabf76facb19852787793cfb4a0
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 6
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_LEDGER_KEY_NONCE
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.nonce_key.nonce_address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.nonce_key.nonce_address.accountId: GBRCWMTNF7Z5GKQFHJ35GO4OKMH4I56V2THEBKRHDQ4ULGYELZX7KYPC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.contractID: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.type: SCV_LEDGER_KEY_NONCE
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.nonce_key.nonce_address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.nonce_key.nonce_address.accountId: GC7ZOYTNA5PRGFU2BAP4H6CTFXPAG46Y2Z3SJV6BNRPP56ET5R7L3ZEM
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.contractID: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.sym: Allowance
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[3].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[3].contractData.contractID: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[3].contractData.key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[3].contractData.key.sym: Balance
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.contractID: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.key.sym: Allowance
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.contractID: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.key.sym: Balance
tx.operations[0].body.invokeHostFunctionOp.auth.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.accountId: GBRCWMTNF7Z5GKQFHJ35GO4OKMH4I56V2THEBKRHDQ4ULGYELZX7KYPC
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.nonce: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.contractID: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.functionName: swap
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args.len: 4
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].bytes: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].bytes: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].i128.lo: 1000
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].i128.lo: 4500
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].contractID: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].functionName: incr_allow
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args.len: 3
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].address.accountId: GBRCWMTNF7Z5GKQFHJ35GO4OKMH4I56V2THEBKRHDQ4ULGYELZX7KYPC
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].address.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].address.contractId: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].i128.lo: 1000
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].type: SCV_MAP
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].key.sym: public_key
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].val.type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[0].val.bytes: 622b326d2ff3d32a053a77d33b8e530fc477d5d4ce40aa271c39459b045e6ff5
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].key.sym: signature
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].val.type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].map[1].val.bytes: d65127e230b0a6c9674616e76c0aacf4e093dd75e09fb04517947828b9d0f06f5572094ff54d0fe259334b8dad9e05fe591a1b9eaa4117fa0a608e2162138300
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce.address.accountId: GC7ZOYTNA5PRGFU2BAP4H6CTFXPAG46Y2Z3SJV6BNRPP56ET5R7L3ZEM
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce.nonce: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.contractID: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.functionName: swap
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args.len: 4
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[0].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[0].bytes: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[1].type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[1].bytes: c94aabb0aba62c99ee266ce1196508b5408a434e23bbdf3489b469af5ba12755
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].i128.lo: 5000
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].i128.lo: 950
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].contractID: ff62f815e98f71375604f385753731597e2621349fabe11ad870e92306085865
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].functionName: incr_allow
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args.len: 3
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].address.accountId: GC7ZOYTNA5PRGFU2BAP4H6CTFXPAG46Y2Z3SJV6BNRPP56ET5R7L3ZEM
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].type: SCV_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].address.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].address.contractId: 881f144f015143d017c313e49515d2405bea95284f3b8d1cb0685349dbc45cc4
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].type: SCV_I128
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].i128.lo: 5000
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].type: SCV_MAP
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[0].key.sym: public_key
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[0].val.type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[0].val.bytes: bf97626d075f13169a081fc3f8532dde0373d8d67724d7c16c5efef893ec7ebd
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[1].key.sym: signature
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[1].val.type: SCV_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].map[1].val.bytes: 5981d9e83fab51b2e991e833aae20a9c514bdcef8553a0dd4da9d13ceb55ce85afa7e625b37c2591712dc3029ca552ed097e614e6ecb242c7accc1861a29190f
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 641f3522
signatures[0].signature: e81c489735c9b165b7cbacdffe38dc1ff70da1994b2d555480071ffee8b319dc44610963676b25c90af3b84d6b3a67bafee2635180fe6b4cb43501f830f6bb09''';

    String expected =
        "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";

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    assert(txRepRes == txRep);
  });
 */
}
