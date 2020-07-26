// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('transaction to txrep', () {
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

    TimeBounds tb = TimeBounds(1595282368, 1595284000);
    MemoText mt = MemoText("Enjoy this ,̆  transaction");

    SetOptionsOperation setOptionsOperation = SetOptionsOperationBuilder()
        .setHomeDomain("https://www.soneso.com/blubber")
        .build();

    Transaction transaction = new TransactionBuilder(a, Network.TESTNET)
        .addTimeBounds(tb)
        .addMemo(mt)
        .addOperation(createAccount)
        .addOperation(payment)
        .addOperation(nonNativePayment)
        .addOperation(setOptionsOperation)
        .build();

    transaction.sign(keyPairA);

    String txrep = TxRep.toTxRep(transaction);
    print(txrep);
  });

  test('txrep to transaction', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GCFCWXFXIHTM4HZW6SOV2A354Y4XNNNHEOUQDKMJA3F2S34KIK2DTSRT
tx.fee: 400
tx.seqNum: 1102902109202
tx.timeBounds._present: true
tx.timeBounds.minTime: 1595282368
tx.timeBounds.maxTime: 1595284000
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 4
tx.operation[0].sourceAccount._present: false
tx.operation[0].body.type: CREATE_ACCOUNT
tx.operation[0].body.createAccountOp.destination: GAHHBWN6V5XDUUD6UUQQLLSJRZQMRJHM7BW5SR3PKMUVLT4GLLZHJB6W
tx.operation[0].body.createAccountOp.startingBalance: 22000000000000000000201112291981902020202021230019
tx.operation[1].sourceAccount._present: true
tx.operation[1].sourceAccount: GCFCWXFXIHTM4HZW6SOV2A354Y4XNNNHEOUQDKMJA3F2S34KIK2DTSRT
tx.operation[1].body.type: PAYMENT
tx.operation[1].body.paymentOp.destination: GAHHBWN6V5XDUUD6UUQQLLSJRZQMRJHM7BW5SR3PKMUVLT4GLLZHJB6W
tx.operation[1].body.paymentOp.asset: native
tx.operation[1].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[2].sourceAccount._present: true
tx.operation[2].sourceAccount: GCFCWXFXIHTM4HZW6SOV2A354Y4XNNNHEOUQDKMJA3F2S34KIK2DTSRT
tx.operation[2].body.type: PAYMENT
tx.operation[2].body.paymentOp.destination: GAHHBWN6V5XDUUD6UUQQLLSJRZQMRJHM7BW5SR3PKMUVLT4GLLZHJB6W
tx.operation[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operation[2].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[3].sourceAccount._present: false
tx.operation[3].body.type: SET_OPTIONS
tx.operation[3].body.setOptionsOp.inflationDest._present: false
tx.operation[3].body.setOptionsOp.clearFlags._present: false
tx.operation[3].body.setOptionsOp.setFlags._present: false
tx.operation[3].body.setOptionsOp.masterWeight._present: false
tx.operation[3].body.setOptionsOp.lowThreshold._present: false
tx.operation[3].body.setOptionsOp.medThreshold._present: false
tx.operation[3].body.setOptionsOp.highThreshold._present: false
tx.operation[3].body.setOptionsOp.homeDomain._present: true
tx.operation[3].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
tx.operation[3].body.setOptionsOp.signer._present: false
tx.signatures.len: 1
tx.signatures[0].hint: 8a42b439
tx.signatures[0].signature: d67dc7c0befb2d9de57411221b2549424a945525f5c5089c7dd52e2a293344d5ab23326783bbaa43d6825efe3abe4eb161a3f1f399fec1aab12aaffd37edfe00
tx.ext.v: 0''';

    AbstractTransaction transaction = TxRep.fromTxRep(txRep);
    print(TxRep.toTxRep(transaction));
  });
}
