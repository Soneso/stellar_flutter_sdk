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
tx.timeBounds._present: true
tx.timeBounds.minTime: 1595282368
tx.timeBounds.maxTime: 1595284000
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 14
tx.operation[0].sourceAccount._present: false
tx.operation[0].body.type: CREATE_ACCOUNT
tx.operation[0].body.createAccountOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[0].body.createAccountOp.startingBalance: 9223372036854775807
tx.operation[1].sourceAccount._present: true
tx.operation[1].sourceAccount: GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[1].body.type: PAYMENT
tx.operation[1].body.paymentOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[1].body.paymentOp.asset: native
tx.operation[1].body.paymentOp.amount: 9223372036854775807
tx.operation[2].sourceAccount._present: true
tx.operation[2].sourceAccount: GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[2].body.type: PAYMENT
tx.operation[2].body.paymentOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operation[2].body.paymentOp.amount: 9223372036854775807
tx.operation[3].sourceAccount._present: false
tx.operation[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
tx.operation[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
tx.operation[3].body.pathPaymentStrictReceiveOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
tx.operation[3].body.pathPaymentStrictReceiveOp.path.len: 2
tx.operation[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[4].sourceAccount._present: false
tx.operation[4].body.type: PATH_PAYMENT_STRICT_SEND
tx.operation[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
tx.operation[4].body.pathPaymentStrictSendOp.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[4].body.pathPaymentStrictSendOp.destAsset: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[4].body.pathPaymentStrictSendOp.destMin: 12000000000
tx.operation[4].body.pathPaymentStrictSendOp.path.len: 2
tx.operation[4].body.pathPaymentStrictSendOp.path[0]: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[5].sourceAccount._present: false
tx.operation[5].body.type: SET_OPTIONS
tx.operation[5].body.setOptionsOp.inflationDest._present: true
tx.operation[5].body.setOptionsOp.inflationDest: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[5].body.setOptionsOp.clearFlags._present: true
tx.operation[5].body.setOptionsOp.clearFlags: 2
tx.operation[5].body.setOptionsOp.setFlags._present: true
tx.operation[5].body.setOptionsOp.setFlags: 4
tx.operation[5].body.setOptionsOp.masterWeight._present: true
tx.operation[5].body.setOptionsOp.masterWeight: 122
tx.operation[5].body.setOptionsOp.lowThreshold._present: true
tx.operation[5].body.setOptionsOp.lowThreshold: 10
tx.operation[5].body.setOptionsOp.medThreshold._present: true
tx.operation[5].body.setOptionsOp.medThreshold: 50
tx.operation[5].body.setOptionsOp.highThreshold._present: true
tx.operation[5].body.setOptionsOp.highThreshold: 122
tx.operation[5].body.setOptionsOp.homeDomain._present: true
tx.operation[5].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
tx.operation[5].body.setOptionsOp.signer._present: true
tx.operation[5].body.setOptionsOp.signer.key: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[5].body.setOptionsOp.signer.weight: 50
tx.operation[6].sourceAccount._present: false
tx.operation[6].body.type: MANAGE_SELL_OFFER
tx.operation[6].body.manageSellOfferOp.selling: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[6].body.manageSellOfferOp.buying: native
tx.operation[6].body.manageSellOfferOp.amount: 82820000000
tx.operation[6].body.manageSellOfferOp.price.n: 7
tx.operation[6].body.manageSellOfferOp.price.d: 10
tx.operation[6].body.manageSellOfferOp.offerID: 9298298398333
tx.operation[7].sourceAccount._present: false
tx.operation[7].body.type: CREATE_PASSIVE_SELL_OFFER
tx.operation[7].body.createPassiveSellOfferOp.selling: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[7].body.createPassiveSellOfferOp.buying: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[7].body.createPassiveSellOfferOp.amount: 28280000000
tx.operation[7].body.createPassiveSellOfferOp.price.n: 1
tx.operation[7].body.createPassiveSellOfferOp.price.d: 2
tx.operation[8].sourceAccount._present: false
tx.operation[8].body.type: CHANGE_TRUST
tx.operation[8].body.changeTrustOp.line: ASTRO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[8].body.changeTrustOp.limit._present: true
tx.operation[8].body.changeTrustOp.limit: 100000000000
tx.operation[9].sourceAccount._present: false
tx.operation[9].body.type: ALLOW_TRUST
tx.operation[9].body.allowTrustOp.trustor: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[9].body.allowTrustOp.asset: MOON
tx.operation[9].body.allowTrustOp.authorize: 1
tx.operation[10].sourceAccount._present: false
tx.operation[10].body.type: ACCOUNT_MERGE
tx.operation[10].body.destination: GALKCFFI5YT2D2SR2WPXAPFN7AWYIMU4DYSPN6HNBHH37YAD2PNFIGXE
tx.operation[11].sourceAccount._present: false
tx.operation[11].body.type: MANAGE_DATA
tx.operation[11].body.manageDataOp.dataName: Sommer
tx.operation[11].body.manageDataOp.dataValue._present: true
tx.operation[11].body.manageDataOp.dataValue: 446965204df662656c2073696e6420686569df21
tx.operation[12].sourceAccount._present: false
tx.operation[12].body.type: BUMP_SEQUENCE
tx.operation[12].body.bumpSequenceOp.bumpTo: 1102902109211
tx.operation[13].sourceAccount._present: false
tx.operation[13].body.type: MANAGE_BUY_OFFER
tx.operation[13].body.manageBuyOfferOp.selling: MOON:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[13].body.manageBuyOfferOp.buying: ECO:GDICQ4HZOFVPJF7QNLHOUFUBNAH3TN4AJSRHZKFQH25I465VDVQE4ZS2
tx.operation[13].body.manageBuyOfferOp.buyAmount: 120000000
tx.operation[13].body.manageBuyOfferOp.price.n: 1
tx.operation[13].body.manageBuyOfferOp.price.d: 5
tx.operation[13].body.manageBuyOfferOp.offerID: 9298298398334
tx.signatures.len: 1
tx.signatures[0].hint: b51d604e
tx.signatures[0].signature: c52a9c15a60a9b7281cb9e932e0eb1ffbe9a759b6cc242eeb08dda88cfff3faaa47b5d817153617825941d1d0c46523f54d9b3790f1cee1370af08a5c29dfe03
tx.ext.v: 0''';

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    print(txRepRes);
    assert(txRepRes == txRep);
  });

  test('txrep to fee bump transaction envelope and back to txrep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX_FEE_BUMP
feeBump.tx.feeSource: GBD4KWT3HXUGS4ACUZZELY67UJXLOFTZAPR5DT5QIMBO6BX53FXFSLQS
feeBump.tx.fee: 1515
feeBump.tx.innerTx.tx.type: ENVELOPE_TYPE_TX
feeBump.tx.innerTx.tx.sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.fee: 1400
feeBump.tx.innerTx.tx.seqNum: 1102902109202
feeBump.tx.innerTx.tx.timeBounds._present: true
feeBump.tx.innerTx.tx.timeBounds.minTime: 1595282368
feeBump.tx.innerTx.tx.timeBounds.maxTime: 1595284000
feeBump.tx.innerTx.tx.memo.type: MEMO_TEXT
feeBump.tx.innerTx.tx.memo.text: "Enjoy this transaction"
feeBump.tx.innerTx.tx.operations.len: 14
feeBump.tx.innerTx.tx.operation[0].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[0].body.type: CREATE_ACCOUNT
feeBump.tx.innerTx.tx.operation[0].body.createAccountOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[0].body.createAccountOp.startingBalance: 9223372036854775807
feeBump.tx.innerTx.tx.operation[1].sourceAccount._present: true
feeBump.tx.innerTx.tx.operation[1].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[1].body.type: PAYMENT
feeBump.tx.innerTx.tx.operation[1].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[1].body.paymentOp.asset: native
feeBump.tx.innerTx.tx.operation[1].body.paymentOp.amount: 9223372036854775807
feeBump.tx.innerTx.tx.operation[2].sourceAccount._present: true
feeBump.tx.innerTx.tx.operation[2].sourceAccount: GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[2].body.type: PAYMENT
feeBump.tx.innerTx.tx.operation[2].body.paymentOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
feeBump.tx.innerTx.tx.operation[2].body.paymentOp.amount: 9223372036854775807
feeBump.tx.innerTx.tx.operation[3].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.path.len: 2
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[4].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[4].body.type: PATH_PAYMENT_STRICT_SEND
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.destAsset: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.destMin: 12000000000
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.path.len: 2
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.path[0]: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[5].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[5].body.type: SET_OPTIONS
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.inflationDest._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.inflationDest: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.clearFlags._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.clearFlags: 2
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.setFlags._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.setFlags: 4
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.masterWeight._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.masterWeight: 122
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.lowThreshold._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.lowThreshold: 10
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.medThreshold._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.medThreshold: 50
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.highThreshold._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.highThreshold: 122
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.homeDomain._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.signer._present: true
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.signer.key: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[5].body.setOptionsOp.signer.weight: 50
feeBump.tx.innerTx.tx.operation[6].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[6].body.type: MANAGE_SELL_OFFER
feeBump.tx.innerTx.tx.operation[6].body.manageSellOfferOp.selling: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[6].body.manageSellOfferOp.buying: native
feeBump.tx.innerTx.tx.operation[6].body.manageSellOfferOp.amount: 82820000000
feeBump.tx.innerTx.tx.operation[6].body.manageSellOfferOp.price.n: 7
feeBump.tx.innerTx.tx.operation[6].body.manageSellOfferOp.price.d: 10
feeBump.tx.innerTx.tx.operation[6].body.manageSellOfferOp.offerID: 9298298398333
feeBump.tx.innerTx.tx.operation[7].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[7].body.type: CREATE_PASSIVE_SELL_OFFER
feeBump.tx.innerTx.tx.operation[7].body.createPassiveSellOfferOp.selling: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[7].body.createPassiveSellOfferOp.buying: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[7].body.createPassiveSellOfferOp.amount: 28280000000
feeBump.tx.innerTx.tx.operation[7].body.createPassiveSellOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operation[7].body.createPassiveSellOfferOp.price.d: 2
feeBump.tx.innerTx.tx.operation[8].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[8].body.type: CHANGE_TRUST
feeBump.tx.innerTx.tx.operation[8].body.changeTrustOp.line: ASTRO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[8].body.changeTrustOp.limit._present: true
feeBump.tx.innerTx.tx.operation[8].body.changeTrustOp.limit: 100000000000
feeBump.tx.innerTx.tx.operation[9].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[9].body.type: ALLOW_TRUST
feeBump.tx.innerTx.tx.operation[9].body.allowTrustOp.trustor: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[9].body.allowTrustOp.asset: MOON
feeBump.tx.innerTx.tx.operation[9].body.allowTrustOp.authorize: 1
feeBump.tx.innerTx.tx.operation[10].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[10].body.type: ACCOUNT_MERGE
feeBump.tx.innerTx.tx.operation[10].body.destination: GBNOLI2TBDKDO32TRJ37YR62KQXZOHPUHA5VMWRL534A7C4OJRNLWOJP
feeBump.tx.innerTx.tx.operation[11].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[11].body.type: MANAGE_DATA
feeBump.tx.innerTx.tx.operation[11].body.manageDataOp.dataName: Sommer
feeBump.tx.innerTx.tx.operation[11].body.manageDataOp.dataValue._present: true
feeBump.tx.innerTx.tx.operation[11].body.manageDataOp.dataValue: 446965204df662656c2073696e6420686569df21
feeBump.tx.innerTx.tx.operation[12].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[12].body.type: BUMP_SEQUENCE
feeBump.tx.innerTx.tx.operation[12].body.bumpSequenceOp.bumpTo: 1102902109211
feeBump.tx.innerTx.tx.operation[13].sourceAccount._present: false
feeBump.tx.innerTx.tx.operation[13].body.type: MANAGE_BUY_OFFER
feeBump.tx.innerTx.tx.operation[13].body.manageBuyOfferOp.selling: MOON:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[13].body.manageBuyOfferOp.buying: ECO:GDXLKEY5TR4IDEV7FZWYFG6MA6M24YDCX5HENQ7DTESBE233EHT6HHGK
feeBump.tx.innerTx.tx.operation[13].body.manageBuyOfferOp.buyAmount: 120000000
feeBump.tx.innerTx.tx.operation[13].body.manageBuyOfferOp.price.n: 1
feeBump.tx.innerTx.tx.operation[13].body.manageBuyOfferOp.price.d: 5
feeBump.tx.innerTx.tx.operation[13].body.manageBuyOfferOp.offerID: 9298298398334
feeBump.tx.innerTx.tx.signatures.len: 1
feeBump.tx.innerTx.tx.signatures[0].hint: 7b21e7e3
feeBump.tx.innerTx.tx.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a
feeBump.tx.innerTx.tx.ext.v: 0
feeBump.tx.ext.v: 0
feeBump.signatures.len: 1
feeBump.signatures[0].hint: 7b21e7e3
feeBump.signatures[0].signature: 085a2ee61be0d5bc2c2c7c7e90cc4c921febfe25aa54b6e99c8aa2e9cdcbf7b8b24872e129e645501dbddb427d400fa92af69768fe62a80b041d0efefa5fc90a''';

    String transactionEnvelopeXdrBase64 =
        TxRep.transactionEnvelopeXdrBase64FromTxRep(txRep);
    String txRepRes =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    print(txRepRes);
    assert(txRepRes == txRep);
  });

  test('fee bump transaction to txrep', () {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    Account a = Account(keyPairA, 1102902109201);

    KeyPair keyPairB = KeyPair.random();
    String accountBId = keyPairB.accountId;
    Account b = Account(keyPairB, 19181981888);

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

    XdrSignerKey signer = XdrSignerKey();
    signer.discriminant = XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519;
    signer.ed25519 = XdrUint256();
    signer.ed25519.uint256 = StrKey.decodeStellarAccountId(accountBId);

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
        AccountMergeOperationBuilder(accountBId).build();

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
    String accountCId = keyPairC.accountId;
    Account c = Account(keyPairB, 19181981888);

    FeeBumpTransaction feeBump = FeeBumpTransactionBuilder(transaction)
        .setFeeAccount(accountCId)
        .setBaseFee(101)
        .build();
    feeBump.sign(keyPairC, Network.TESTNET);
    String transactionEnvelopeXdrBase64 = feeBump.toEnvelopeXdrBase64();
    print(transactionEnvelopeXdrBase64);
    String txrep =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    print(txrep);
    print('----------------');
    print(transactionEnvelopeXdrBase64);
    transactionEnvelopeXdrBase64 = transaction.toEnvelopeXdrBase64();
    txrep =
        TxRep.fromTransactionEnvelopeXdrBase64(transactionEnvelopeXdrBase64);
    print(txrep);
  });
}
