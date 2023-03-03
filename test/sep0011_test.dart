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
        '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';
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
    Account b = Account(accountBId, 19181981888);

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

  test('soroban install contract code txRep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GAI4D5HAVLV4I3TJQ6IQJIDV53BC7UAQYPYVMTE4L6Y3VJ4I2OY3XI5T
tx.fee: 100
tx.seqNum: 699950820229121
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INSTALL_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.function.installContractCodeArgs.code: 0061736d0100000001150460017e017e60027e7e017e60027f7e017e6000000219040178013800000176015f00000176013400010176013600010304030200030503010001060b027f0141000b7f0141000b071d030568656c6c6f0005066d656d6f727902000873646b737461727400060c01060a9004033900200041ff0171410849200142808080808080808010547145044041064208100410001a0b200041017441ff0171ad2001420486844201840bc10302067f027e410242001004100121082300220441046a2201411c6a22053f002203411074410f6a41707122064b04402003200520066b41ffff036a4180807c714110762206200320064a1b40004100480440200640004100480440000b0b0b200524002004411c360200200141046b22034100360204200341003602082003410336020c200341083602102001420037031020012008370310419c09280200410176410a4b044041064208100410001a0b03402002419c092802004101764804402002419c092802004101764f047f417f05200241017441a0096a2f01000b220341fa004c200341304e7104402007420686210842002107200341ff017141df004604404201210705200341ff0171220441394d200441304f710440200341ff0171ad422e7d210705200341ff0171220441da004d200441c1004f710440200341ff0171ad42357d210705200341ff0171220441fa004d200441e1004f710440200341ff0171ad423b7d21070541064208100410001a0b0b0b0b200720088421070541064208100410001a0b200241016a21020c010b0b41042007100421072001200129031020071002370310200120012903102000100337031020012903100b1100230104400f0b4101240141ac0924000b0b8d010600418c080b013c004198080b2f010000002800000041006c006c006f0063006100740069006f006e00200074006f006f0020006c00610072006700650041cc080b013c0041d8080b25010000001e0000007e006c00690062002f00720074002f0073007400750062002e0074007300418c090b011c004198090b11010000000a000000480065006c006c006f001e11636f6e7472616374656e766d657461763000000000000000000000001d00430e636f6e747261637473706563763000000000000000000000000568656c6c6f000000000000010000000000000002746f00000000000800000001000003ea00000008
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractCode.hash: e811e15852de29ad91753af97e6ead60d953f76e7eb2644aa09938c82d080199
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 88d3b1bb
signatures[0].signature: d7df4d986b844dfc760496e0e9d104c67211ff92961164caad7d59c449278480b25d69458e805787c12cd74bab7386f7c249be76def42c3f7c2c230531554b0b''';

    String expected =
        "AAAAAgAAAAARwfTgquvEbmmHkQSgde7CL9AQw/FWTJxfsbqniNOxuwAAAGQAAnyaAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAgAAA3wAYXNtAQAAAAEVBGABfgF+YAJ+fgF+YAJ/fgF+YAAAAhkEAXgBOAAAAXYBXwAAAXYBNAABAXYBNgABAwQDAgADBQMBAAEGCwJ/AUEAC38BQQALBx0DBWhlbGxvAAUGbWVtb3J5AgAIc2Rrc3RhcnQABgwBBgqQBAM5ACAAQf8BcUEISSABQoCAgICAgICAEFRxRQRAQQZCCBAEEAAaCyAAQQF0Qf8Bca0gAUIEhoRCAYQLwQMCBn8CfkECQgAQBBABIQgjACIEQQRqIgFBHGoiBT8AIgNBEHRBD2pBcHEiBksEQCADIAUgBmtB//8DakGAgHxxQRB2IgYgAyAGShtAAEEASARAIAZAAEEASARAAAsLCyAFJAAgBEEcNgIAIAFBBGsiA0EANgIEIANBADYCCCADQQM2AgwgA0EINgIQIAFCADcDECABIAg3AxBBnAkoAgBBAXZBCksEQEEGQggQBBAAGgsDQCACQZwJKAIAQQF2SARAIAJBnAkoAgBBAXZPBH9BfwUgAkEBdEGgCWovAQALIgNB+gBMIANBME5xBEAgB0IGhiEIQgAhByADQf8BcUHfAEYEQEIBIQcFIANB/wFxIgRBOU0gBEEwT3EEQCADQf8Bca1CLn0hBwUgA0H/AXEiBEHaAE0gBEHBAE9xBEAgA0H/AXGtQjV9IQcFIANB/wFxIgRB+gBNIARB4QBPcQRAIANB/wFxrUI7fSEHBUEGQggQBBAAGgsLCwsgByAIhCEHBUEGQggQBBAAGgsgAkEBaiECDAELC0EEIAcQBCEHIAEgASkDECAHEAI3AxAgASABKQMQIAAQAzcDECABKQMQCxEAIwEEQA8LQQEkAUGsCSQACwuNAQYAQYwICwE8AEGYCAsvAQAAACgAAABBAGwAbABvAGMAYQB0AGkAbwBuACAAdABvAG8AIABsAGEAcgBnAGUAQcwICwE8AEHYCAslAQAAAB4AAAB+AGwAaQBiAC8AcgB0AC8AcwB0AHUAYgAuAHQAcwBBjAkLARwAQZgJCxEBAAAACgAAAEgAZQBsAGwAbwAeEWNvbnRyYWN0ZW52bWV0YXYwAAAAAAAAAAAAAAAdAEMOY29udHJhY3RzcGVjdjAAAAAAAAAAAAAAAAVoZWxsbwAAAAAAAAEAAAAAAAAAAnRvAAAAAAAIAAAAAQAAA+oAAAAIAAAAAQAAAAfoEeFYUt4prZF1Ovl+bq1g2VP3bn6yZEqgmTjILQgBmQAAAAAAAAAAAAAAAAAAAAGI07G7AAAAQNffTZhrhE38dgSW4OnRBMZyEf+SlhFkyq19WcRJJ4SAsl1pRY6AV4fBLNdLq3OG98JJvnbe9Cw/fCwjBTFVSws=";
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
tx.sourceAccount: GCX3VZJFJTICKE7OJ6I2H5FQQ3UKRM4F55UCCVDPSJQEQOXZB7YRWEIM
tx.fee: 100
tx.seqNum: 700225698136066
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.type: SCCONTRACT_CODE_WASM_REF
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.wasm_id: e811e15852de29ad91753af97e6ead60d953f76e7eb2644aa09938c82d080199
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.type: CONTRACT_ID_FROM_SOURCE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.salt: 697552b02c33739d0000799bb9ed9955ab849d58b575406461673b9f544f9437
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractCode.hash: e811e15852de29ad91753af97e6ead60d953f76e7eb2644aa09938c82d080199
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 1a1e28893379dcf707d921ba300402d6976b15283a1e8b71df5d89e445d5d6df
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: f90ff11b
signatures[0].signature: 999896922fd58755609c40fb640e472b746fec02c8ad088ac1c831743655dc5827922ea1eb52d6192360bfbc87da75162e21d366527f2289528269aea6a74b04''';

    String expected =
        "AAAAAgAAAACvuuUlTNAlE+5PkaP0sIboqLOF72ghVG+SYEg6+Q/xGwAAAGQAAnzaAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAABpdVKwLDNznQAAeZu57ZlVq4SdWLV1QGRhZzufVE+UNwAAAADoEeFYUt4prZF1Ovl+bq1g2VP3bn6yZEqgmTjILQgBmQAAAAEAAAAH6BHhWFLeKa2RdTr5fm6tYNlT925+smRKoJk4yC0IAZkAAAABAAAABhoeKIkzedz3B9khujAEAtaXaxUoOh6Lcd9dieRF1dbfAAAAAwAAAAMAAAAAAAAAAAAAAAH5D/EbAAAAQJmYlpIv1YdVYJxA+2QORyt0b+wCyK0IisHIMXQ2VdxYJ5IuoetS1hkjYL+8h9p1Fi4h02ZSfyKJUoJprqanSwQ=";
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
tx.sourceAccount: GAQT2VKQOKFT25Y76MNVTUQGAW5FGMDUTEYRKRSN4T6R6Q3P4ODUABRL
tx.fee: 100
tx.seqNum: 700444741468163
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 3
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.bin: f7e6d29ebdbc115cbb06b9f144e557aff277ad5befb008bc9459a10bb134c479
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: hello
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].sym: friend
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.contractID: f7e6d29ebdbc115cbb06b9f144e557aff277ad5befb008bc9459a10bb134c479
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractCode.hash: e811e15852de29ad91753af97e6ead60d953f76e7eb2644aa09938c82d080199
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 6fe38740
signatures[0].signature: c5c8d1975454d00bb8610bd8d3b6880b82bf11e1f6f43e7d7339275bba88f4ec37673b58802f4298ec5c2bf89e36224f1b4ac21adef5d1486147def4b147b90e''';

    String expected =
        "AAAAAgAAAAAhPVVQcos9dx/zG1nSBgW6UzB0mTEVRk3k/R9Db+OHQAAAAGQAAn0NAAAAAwAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAMAAAAEAAAAAQAAAAYAAAAg9+bSnr28EVy7BrnxROVXr/J3rVvvsAi8lFmhC7E0xHkAAAAFAAAABWhlbGxvAAAAAAAABQAAAAZmcmllbmQAAAAAAAIAAAAG9+bSnr28EVy7BrnxROVXr/J3rVvvsAi8lFmhC7E0xHkAAAADAAAAAwAAAAfoEeFYUt4prZF1Ovl+bq1g2VP3bn6yZEqgmTjILQgBmQAAAAAAAAAAAAAAAAAAAAFv44dAAAAAQMXI0ZdUVNALuGEL2NO2iAuCvxHh9vQ+fXM5J1u6iPTsN2c7WIAvQpjsXCv4njYiTxtKwhre9dFIYUfe9LFHuQ4=";

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
tx.sourceAccount: GAHNCPKG2JV7BOIFVANQYSPQMBEAXOY43HWQKQRKXY5F4Q6BDC3X2DXU
tx.fee: 100
tx.seqNum: 701235015450628
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.type: SCCONTRACT_CODE_TOKEN
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.type: CONTRACT_ID_FROM_SOURCE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.salt: 9566851518a113fc7adedf5a4e27f0c04e4141f74ebac59598077500cf812544
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 0
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 977fe6300294de0e53ef9bca220e625102fff523c35ea865bb79b764453be4b4
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: c118b77d
signatures[0].signature: 403c2f3696f7df6400d1d087f55cd343015bf1bfa9bb95ae47b9ac6a160a3eaa152a83f615fe27f63cb94ccb77d12e5ecaf71500f6c7685fce44ef279c59fb03''';

    String expected =
        "AAAAAgAAAAAO0T1G0mvwuQWoGwxJ8GBIC7sc2e0FQiq+Ol5DwRi3fQAAAGQAAn3FAAAABAAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAACVZoUVGKET/Hre31pOJ/DATkFB9066xZWYB3UAz4ElRAAAAAEAAAAAAAAAAQAAAAaXf+YwApTeDlPvm8oiDmJRAv/1I8NeqGW7ebdkRTvktAAAAAMAAAADAAAAAAAAAAAAAAABwRi3fQAAAEBAPC82lvffZADR0If1XNNDAVvxv6m7la5HuaxqFgo+qhUqg/YV/if2PLlMy3fRLl7K9xUA9sdoX85E7yecWfsD";
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
tx.sourceAccount: GBVB7WYKS7FNHYS6SU2XBNL3JTI57BWYHLRYNR65TNDAUIDCVPC5QODD
tx.fee: 100
tx.seqNum: 701415404077058
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_CREATE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.source.type: SCCONTRACT_CODE_TOKEN
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.type: CONTRACT_ID_FROM_ASSET
tx.operations[0].body.invokeHostFunctionOp.function.createContractArgs.contractID.asset: IOM:GBD6JRML66ATNIZV6SW3YAN2JIZO7BUU7JRYZP3KXQ6UWVOCNWTQXFZE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 0
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 3
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: df908b9ccc3102bcc8a2b1f03cf0b6a57697931362793bb332cdc729e975410f
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.contractID: df908b9ccc3102bcc8a2b1f03cf0b6a57697931362793bb332cdc729e975410f
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj.type: SCO_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj.vec.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj.vec[0].sym: Admin
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.contractID: df908b9ccc3102bcc8a2b1f03cf0b6a57697931362793bb332cdc729e975410f
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.obj.type: SCO_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.obj.vec.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.obj.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].contractData.key.obj.vec[0].sym: Metadata
tx.operations[0].body.invokeHostFunctionOp.auth.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 62abc5d8
signatures[0].signature: 60965ae1b766081a6439f54c6e167284ced64f2a555bc0ee3894bd6e894a443941ad04bfb7678375f8a34932581bc6c267a5af7562e1de9d34a2577a05a99103''';

    String expected =
        "AAAAAgAAAABqH9sKl8rT4l6VNXC1e0zR34bYOuOGx92bRgogYqvF2AAAAGQAAn3vAAAAAgAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAQAAAAIAAAABSU9NAAAAAABH5MWL94E2ozX0rbwBukoy74aU+mOMv2q8PUtVwm2nCwAAAAEAAAAAAAAAAwAAAAbfkIuczDECvMiisfA88LaldpeTE2J5O7Myzccp6XVBDwAAAAMAAAADAAAABt+Qi5zMMQK8yKKx8DzwtqV2l5MTYnk7szLNxynpdUEPAAAABAAAAAEAAAAAAAAAAQAAAAUAAAAFQWRtaW4AAAAAAAAG35CLnMwxArzIorHwPPC2pXaXkxNieTuzMs3HKel1QQ8AAAAEAAAAAQAAAAAAAAABAAAABQAAAAhNZXRhZGF0YQAAAAAAAAAAAAAAAWKrxdgAAABAYJZa4bdmCBpkOfVMbhZyhM7WTypVW8DuOJS9bolKRDlBrQS/t2eDdfijSTJYG8bCZ6WvdWLh3p00old6BamRAw==";
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
tx.sourceAccount: GAY5EPJ3N5KL4QHXADD2W6B574IIU5DZWRY63TTRCGHJBNNYUVVQZ3MR
tx.fee: 100
tx.seqNum: 701591497736195
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 4
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.bin: 6a964b996d200a64972d35129abbee5b1724ade12974dfe664d433466f4d01f9
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: auth
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.address.accountId: GDETISNUQP33A3G57OKA3ULULK6VVT6IYBBLJUSXFZQX2W3YCKBM6WYH
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].u32: 3
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 3
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].account.accountID: GDETISNUQP33A3G57OKA3ULULK6VVT6IYBBLJUSXFZQX2W3YCKBM6WYH
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.contractID: 6a964b996d200a64972d35129abbee5b1724ade12974dfe664d433466f4d01f9
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractCode.hash: 9f0bc3696780799491f3f1ef7d8d6c9eb4ac09e4d7e54e623ab92f1b767c4389
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: 6a964b996d200a64972d35129abbee5b1724ade12974dfe664d433466f4d01f9
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj.address.accountId: GDETISNUQP33A3G57OKA3ULULK6VVT6IYBBLJUSXFZQX2W3YCKBM6WYH
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.contractID: 6a964b996d200a64972d35129abbee5b1724ade12974dfe664d433466f4d01f9
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj.type: SCO_NONCE_KEY
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj.nonceAddress.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].contractData.key.obj.nonceAddress.accountId: GDETISNUQP33A3G57OKA3ULULK6VVT6IYBBLJUSXFZQX2W3YCKBM6WYH
tx.operations[0].body.invokeHostFunctionOp.auth.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.accountId: GDETISNUQP33A3G57OKA3ULULK6VVT6IYBBLJUSXFZQX2W3YCKBM6WYH
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.nonce: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.contractID: 6a964b996d200a64972d35129abbee5b1724ade12974dfe664d433466f4d01f9
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.functionName: auth
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.address.accountId: GDETISNUQP33A3G57OKA3ULULK6VVT6IYBBLJUSXFZQX2W3YCKBM6WYH
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].u32: 3
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.type: SCO_MAP
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].key.sym: public_key
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.obj.bin: c93449b483f7b06cddfb940dd1745abd5acfc8c042b4d2572e617d5b781282cf
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].key.sym: signature
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.obj.bin: 0b8e45e4ce3a350696d0ec24c8dfd4f1835f0fb640029aa1b009e46041fc331f9ec4d27266b3141d2ca283db6887f4ebb68531d343d4e044f9bb9e2751268904
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: b8a56b0c
signatures[0].signature: 9a766e5916a608dcc2b17c32a00a51a5bae3c062cf3c6a95eeeab95049888193f4a46f5ad6e2124c2bf3439188678122f1427badf688131e773cdaa45c3b9109''';

    String expected =
        "AAAAAgAAAAAx0j07b1S+QPcAx6t4Pf8QinR5tHHtznERjpC1uKVrDAAAAGQAAn4YAAAAAwAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAQAAAAEAAAAAQAAAAYAAAAgapZLmW0gCmSXLTUSmrvuWxckreEpdN/mZNQzRm9NAfkAAAAFAAAABGF1dGgAAAAEAAAAAQAAAAgAAAAAAAAAAMk0SbSD97Bs3fuUDdF0Wr1az8jAQrTSVy5hfVt4EoLPAAAAAQAAAAMAAAADAAAAAAAAAADJNEm0g/ewbN37lA3RdFq9Ws/IwEK00lcuYX1beBKCzwAAAAZqlkuZbSAKZJctNRKau+5bFySt4Sl03+Zk1DNGb00B+QAAAAMAAAADAAAAB58Lw2lngHmUkfPx732NbJ60rAnk1+VOYjq5Lxt2fEOJAAAAAgAAAAZqlkuZbSAKZJctNRKau+5bFySt4Sl03+Zk1DNGb00B+QAAAAQAAAABAAAACAAAAAAAAAAAyTRJtIP3sGzd+5QN0XRavVrPyMBCtNJXLmF9W3gSgs8AAAAGapZLmW0gCmSXLTUSmrvuWxckreEpdN/mZNQzRm9NAfkAAAAEAAAAAQAAAAkAAAAAAAAAAMk0SbSD97Bs3fuUDdF0Wr1az8jAQrTSVy5hfVt4EoLPAAAAAQAAAAEAAAAAAAAAAMk0SbSD97Bs3fuUDdF0Wr1az8jAQrTSVy5hfVt4EoLPAAAAAAAAAABqlkuZbSAKZJctNRKau+5bFySt4Sl03+Zk1DNGb00B+QAAAARhdXRoAAAAAgAAAAQAAAABAAAACAAAAAAAAAAAyTRJtIP3sGzd+5QN0XRavVrPyMBCtNJXLmF9W3gSgs8AAAABAAAAAwAAAAAAAAABAAAABAAAAAEAAAAAAAAAAQAAAAQAAAABAAAAAQAAAAIAAAAFAAAACnB1YmxpY19rZXkAAAAAAAQAAAABAAAABgAAACDJNEm0g/ewbN37lA3RdFq9Ws/IwEK00lcuYX1beBKCzwAAAAUAAAAJc2lnbmF0dXJlAAAAAAAABAAAAAEAAAAGAAAAQAuOReTOOjUGltDsJMjf1PGDXw+2QAKaobAJ5GBB/DMfnsTScmazFB0sooPbaIf067aFMdND1OBE+bueJ1EmiQQAAAAAAAAAAbilawwAAABAmnZuWRamCNzCsXwyoApRpbrjwGLPPGqV7uq5UEmIgZP0pG9a1uISTCvzQ5GIZ4Ei8UJ7rfaIEx53PNqkXDuRCQ==";
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
tx.sourceAccount: GDYVOEHHXD7FNTYCQU6K2JP5CPIDMC7647RLWUNXP7OTSKYCK6I4ORZD
tx.fee: 100
tx.seqNum: 706685328949252
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 4
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.bin: ace40a194f6fa17565dd96f77d5c018c7cd95a71a9fbf067dbf9ca734880597a
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: auth
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.address.accountId: GDYVOEHHXD7FNTYCQU6K2JP5CPIDMC7647RLWUNXP7OTSKYCK6I4ORZD
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].u32: 5
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.contractID: ace40a194f6fa17565dd96f77d5c018c7cd95a71a9fbf067dbf9ca734880597a
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractCode.hash: 9f0bc3696780799491f3f1ef7d8d6c9eb4ac09e4d7e54e623ab92f1b767c4389
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.contractID: ace40a194f6fa17565dd96f77d5c018c7cd95a71a9fbf067dbf9ca734880597a
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].contractData.key.obj.address.accountId: GDYVOEHHXD7FNTYCQU6K2JP5CPIDMC7647RLWUNXP7OTSKYCK6I4ORZD
tx.operations[0].body.invokeHostFunctionOp.auth.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce._present: false
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.contractID: ace40a194f6fa17565dd96f77d5c018c7cd95a71a9fbf067dbf9ca734880597a
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.functionName: auth
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.address.accountId: GDYVOEHHXD7FNTYCQU6K2JP5CPIDMC7647RLWUNXP7OTSKYCK6I4ORZD
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].type: SCV_U32
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].u32: 5
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs.len: 0
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: 025791c7
signatures[0].signature: db7ccd50b6a791466fdbbe9e8fca7999409ac64b181493ac896029172a3819d46839cb3c1839f0e94adcc8f666422b82a82be9aa86c2869a02ba19675100a609''';

    String expected =
        "AAAAAgAAAADxVxDnuP5WzwKFPK0l/RPQNgv+5+K7Ubd/3TkrAleRxwAAAGQAAoK6AAAABAAAAAAAAAAAAAAAAQAAAAAAAAAYAAAAAAAAAAQAAAAEAAAAAQAAAAYAAAAgrOQKGU9voXVl3Zb3fVwBjHzZWnGp+/Bn2/nKc0iAWXoAAAAFAAAABGF1dGgAAAAEAAAAAQAAAAgAAAAAAAAAAPFXEOe4/lbPAoU8rSX9E9A2C/7n4rtRt3/dOSsCV5HHAAAAAQAAAAUAAAACAAAABqzkChlPb6F1Zd2W931cAYx82VpxqfvwZ9v5ynNIgFl6AAAAAwAAAAMAAAAHnwvDaWeAeZSR8/HvfY1snrSsCeTX5U5iOrkvG3Z8Q4kAAAABAAAABqzkChlPb6F1Zd2W931cAYx82VpxqfvwZ9v5ynNIgFl6AAAABAAAAAEAAAAIAAAAAAAAAADxVxDnuP5WzwKFPK0l/RPQNgv+5+K7Ubd/3TkrAleRxwAAAAEAAAAArOQKGU9voXVl3Zb3fVwBjHzZWnGp+/Bn2/nKc0iAWXoAAAAEYXV0aAAAAAIAAAAEAAAAAQAAAAgAAAAAAAAAAPFXEOe4/lbPAoU8rSX9E9A2C/7n4rtRt3/dOSsCV5HHAAAAAQAAAAUAAAAAAAAAAAAAAAAAAAABAleRxwAAAEDbfM1QtqeRRm/bvp6PynmZQJrGSxgUk6yJYCkXKjgZ1Gg5yzwYOfDpStzI9mZCK4KoK+mqhsKGmgK6GWdRAKYJ";
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
tx.sourceAccount: GAERW3OYAVYMZMPMVKHSCDS4ORFPLT5Z3YXA4VM3BVYEA2W7CG3V6YYB
tx.fee: 100
tx.seqNum: 454682417823797
tx.cond.type: PRECOND_NONE
tx.memo.type: MEMO_NONE
tx.operations.len: 1
tx.operations[0].sourceAccount._present: false
tx.operations[0].body.type: INVOKE_HOST_FUNCTION
tx.operations[0].body.invokeHostFunctionOp.function.type: HOST_FUNCTION_TYPE_INVOKE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs.len: 10
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[0].obj.bin: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[1].sym: swap
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[2].obj.address.accountId: GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[3].obj.address.accountId: GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[4].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[4].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[4].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[4].obj.bin: d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[5].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[5].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[5].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[5].obj.bin: 8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].obj.i128.lo: 1000
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[6].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].obj.i128.lo: 4500
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[7].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].obj.i128.lo: 5000
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[8].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].obj.i128.lo: 950
tx.operations[0].body.invokeHostFunctionOp.function.invokeArgs[9].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly.len: 6
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.contractID: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[0].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.contractID: 8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[1].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.contractID: 8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.key.obj.type: SCO_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.key.obj.vec.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.key.obj.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[2].contractData.key.obj.vec[0].sym: Metadata
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].contractData.contractID: d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].contractData.key.type: SCV_STATIC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[3].contractData.key.ic: SCS_LEDGER_KEY_CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.contractID: d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.key.obj.type: SCO_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.key.obj.vec.len: 1
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.key.obj.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[4].contractData.key.obj.vec[0].sym: Metadata
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[5].type: CONTRACT_CODE
tx.operations[0].body.invokeHostFunctionOp.footprint.readOnly[5].contractCode.hash: 2aa932bbdb0faf6fd2de7f2d190b3739ca32f62a156c73b25dd908dae8b1a989
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite.len: 8
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].type: ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[0].account.accountID: GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].type: ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[1].account.accountID: GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].type: TRUSTLINE
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].trustLine.accountID: GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[2].trustLine.asset: CAT:GDYD52U5BORAJA634A7MXGKDUQAK6UNY7T3B67UIB5XQGJ5QHHULQV3Y
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[3].type: TRUSTLINE
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[3].trustLine.accountID: GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[3].trustLine.asset: CAT:GDYD52U5BORAJA634A7MXGKDUQAK6UNY7T3B67UIB5XQGJ5QHHULQV3Y
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.contractID: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.key.obj.type: SCO_NONCE_KEY
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.key.obj.nonceAddress.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[4].contractData.key.obj.nonceAddress.accountId: GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.contractID: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.key.obj.type: SCO_NONCE_KEY
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.key.obj.nonceAddress.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[5].contractData.key.obj.nonceAddress.accountId: GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.contractID: 8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.type: SCO_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[0].sym: Allowance
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.type: SCO_MAP
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[0].key.sym: from
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[0].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[0].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[0].val.obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[0].val.obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[0].val.obj.address.accountId: GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[1].key.sym: spender
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[1].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[1].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[1].val.obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[1].val.obj.address.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[6].contractData.key.obj.vec[1].obj.map[1].val.obj.address.contractId: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].type: CONTRACT_DATA
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.contractID: d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.type: SCO_VEC
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[0].type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[0].sym: Allowance
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.type: SCO_MAP
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map.len: 2
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[0].key.sym: from
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[0].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[0].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[0].val.obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[0].val.obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[0].val.obj.address.accountId: GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[1].key.sym: spender
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[1].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[1].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[1].val.obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[1].val.obj.address.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.footprint.readWrite[7].contractData.key.obj.vec[1].obj.map[1].val.obj.address.contractId: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.auth.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.address.accountId: GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
tx.operations[0].body.invokeHostFunctionOp.auth[0].addressWithNonce.nonce: 6
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.contractID: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.functionName: swap
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args.len: 4
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[0].obj.bin: d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[1].obj.bin: 8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].obj.i128.lo: 1000
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[2].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].obj.i128.lo: 4500
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.args[3].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].contractID: d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].functionName: incr_allow
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args.len: 3
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[0].obj.address.accountId: GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].obj.address.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[1].obj.address.contractId: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].obj.i128.lo: 1000
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].args[2].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].rootInvocation.subInvocations[0].subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.type: SCO_MAP
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].key.sym: public_key
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[0].val.obj.bin: c13e9ed33229c9ca59e7fba7505c900235cd792c5f9a2763f2d41691e0fd7424
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].key.sym: signature
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[0].signatureArgs[0].obj.map[1].val.obj.bin: e0b6363b70446590bc37bd9538ed01cad346c9f6a0ed3bad9d7af04fd284c91f5a801bb546d6b07db5e4adc14802aa191c279c545e7a45106fa67698a4c3f206
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce.address.accountId: GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
tx.operations[0].body.invokeHostFunctionOp.auth[1].addressWithNonce.nonce: 7
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.contractID: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.functionName: swap
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args.len: 4
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[0].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[0].obj.bin: 8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[1].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[1].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[1].obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[1].obj.bin: d93f5c7bb0ebc4a9c8f727c5cebc4e41194d38257e1d0d910356b43bfc528813
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].obj.i128.lo: 5000
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[2].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].obj.i128.lo: 950
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.args[3].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].contractID: 8dc97b166bd98c755b0e881ee9bd6d0b45e797ec73671f30e026f14a0f1cce67
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].functionName: incr_allow
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args.len: 3
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].obj.address.type: SC_ADDRESS_TYPE_ACCOUNT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[0].obj.address.accountId: GBMLPRFCZDZJPKUPHUSHCKA737GOZL7ERZLGGMJ6YGHBFJZ6ZKMKCZTM
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].obj.type: SCO_ADDRESS
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].obj.address.type: SC_ADDRESS_TYPE_CONTRACT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[1].obj.address.contractId: 828e7031194ec4fb9461d8283b448d3eaf5e36357cf465d8db6021ded6eff05c
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].obj.type: SCO_I128
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].obj.i128.lo: 5000
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].args[2].obj.i128.hi: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].rootInvocation.subInvocations[0].subInvocations.len: 0
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs.len: 1
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.type: SCO_MAP
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map.len: 2
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[0].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[0].key.sym: public_key
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[0].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[0].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[0].val.obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[0].val.obj.bin: 58b7c4a2c8f297aa8f3d2471281fdfccecafe48e5663313ec18e12a73eca98a1
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[1].key.type: SCV_SYMBOL
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[1].key.sym: signature
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[1].val.type: SCV_OBJECT
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[1].val.obj._present: true
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[1].val.obj.type: SCO_BYTES
tx.operations[0].body.invokeHostFunctionOp.auth[1].signatureArgs[0].obj.map[1].val.obj.bin: ffdb371608f9953970ada9a99b3c6157f5fb20f44434409a268b920c27fb364b14a35068be5d147fa7169d18c6598cfd6d49d1dc38a9129260b208401d090702
tx.ext.v: 0
signatures.len: 1
signatures[0].hint: df11b75f
signatures[0].signature: cee4413fab6192bddf46d2a5fe693bde708532759b326de2e171dc976a831c99e126e84fa6325e95876c6752fcc8d7b35e1858f103eec52cc031dc687ab3c308''';

    String expected =
        "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";
    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    assert(expected == transactionEnvelopeXdrBase64);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    print(txRepRes);
    assert(txRepRes == txRep);
  });
}
