// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('transaction to txrep', () async {
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
    MemoText mt = MemoText("Enjoy this transaction");
    Transaction transaction = new TransactionBuilder(a, Network.TESTNET)
        .addTimeBounds(tb)
        .addMemo(mt)
        .addOperation(createAccount)
        .addOperation(payment)
        .addOperation(nonNativePayment)
        .build();

    transaction.sign(keyPairA);

    String txrep = TxRep.toTxRep(transaction);
    print(txrep);
  });
}
