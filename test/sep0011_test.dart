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

    TimeBounds tb = TimeBounds(1595282368, 1595284000);
    MemoText mt = MemoText("Enjoy this transaction");

    SetOptionsOperation setOptionsOperation = SetOptionsOperationBuilder()
        .setHomeDomain("https://www.soneso.com/blubber")
        .build();

    Transaction transaction = new TransactionBuilder(a)
        .addTimeBounds(tb)
        .addMemo(mt)
        .addOperation(createAccount)
        .addOperation(payment)
        .addOperation(nonNativePayment)
        .addOperation(strictReceive)
        .addOperation(strictSend)
        .addOperation(setOptionsOperation)
        .build();

    transaction.sign(keyPairA, Network.TESTNET);

    String txrep = TxRep.toTxRep(transaction);
    print(txrep);
  });

  test('txrep to transaction', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.fee: 600
tx.seqNum: 1102902109202
tx.timeBounds._present: true
tx.timeBounds.minTime: 1595282368
tx.timeBounds.maxTime: 1595284000
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 6
tx.operation[0].sourceAccount._present: false
tx.operation[0].body.type: CREATE_ACCOUNT
tx.operation[0].body.createAccountOp.destination: GBO3INUHTPSOEGJOIZCCKWGFDCL7XV4OZR7LY2GYL53YJ3AHYSK7ONZ5
tx.operation[0].body.createAccountOp.startingBalance: 22000000000000000000201112291981902020202021230019
tx.operation[1].sourceAccount._present: true
tx.operation[1].sourceAccount: GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[1].body.type: PAYMENT
tx.operation[1].body.paymentOp.destination: GBO3INUHTPSOEGJOIZCCKWGFDCL7XV4OZR7LY2GYL53YJ3AHYSK7ONZ5
tx.operation[1].body.paymentOp.asset: native
tx.operation[1].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[2].sourceAccount._present: true
tx.operation[2].sourceAccount: GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[2].body.type: PAYMENT
tx.operation[2].body.paymentOp.destination: GBO3INUHTPSOEGJOIZCCKWGFDCL7XV4OZR7LY2GYL53YJ3AHYSK7ONZ5
tx.operation[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operation[2].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[3].sourceAccount._present: false
tx.operation[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
tx.operation[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
tx.operation[3].body.pathPaymentStrictReceiveOp.destination: GBO3INUHTPSOEGJOIZCCKWGFDCL7XV4OZR7LY2GYL53YJ3AHYSK7ONZ5
tx.operation[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
tx.operation[3].body.pathPaymentStrictReceiveOp.path.len: 2
tx.operation[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[4].sourceAccount._present: false
tx.operation[4].body.type: PATH_PAYMENT_STRICT_SEND
tx.operation[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
tx.operation[4].body.pathPaymentStrictSendOp.destination: GBO3INUHTPSOEGJOIZCCKWGFDCL7XV4OZR7LY2GYL53YJ3AHYSK7ONZ5
tx.operation[4].body.pathPaymentStrictSendOp.destAsset: MOON:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[4].body.pathPaymentStrictSendOp.destMin: 12000000000
tx.operation[4].body.pathPaymentStrictSendOp.path.len: 2
tx.operation[4].body.pathPaymentStrictSendOp.path[0]: ECO:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GCRWVE2HLSWIYL7PXMXWRAENZMN5HKXIRZWTJG53S6O5JNZBZJJHN7TX
tx.operation[5].sourceAccount._present: false
tx.operation[5].body.type: SET_OPTIONS
tx.operation[5].body.setOptionsOp.inflationDest._present: false
tx.operation[5].body.setOptionsOp.clearFlags._present: false
tx.operation[5].body.setOptionsOp.setFlags._present: false
tx.operation[5].body.setOptionsOp.masterWeight._present: false
tx.operation[5].body.setOptionsOp.lowThreshold._present: false
tx.operation[5].body.setOptionsOp.medThreshold._present: false
tx.operation[5].body.setOptionsOp.highThreshold._present: false
tx.operation[5].body.setOptionsOp.homeDomain._present: true
tx.operation[5].body.setOptionsOp.homeDomain: "https://www.soneso.com/blubber"
tx.operation[5].body.setOptionsOp.signer._present: false
tx.signatures.len: 1
tx.signatures[0].hint: 21ca5276
tx.signatures[0].signature: 95d493680429be16e7d0a7f3dca4eeb59b3ee0ee516a8dd0f179fbcc47cd62b8eb474ab32d94701c81d82a02287399801e0eadcb686dc3c391208aa52d0d0302
tx.ext.v: 0''';

    AbstractTransaction transaction = TxRep.fromTxRep(txRep);
    String txRepRes = TxRep.toTxRep(transaction);
    print(txRepRes);
    assert(txRepRes == txRep);
  });
}
