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

    ManageSellOfferOperation manageSellOfferOperation =
        ManageSellOfferOperationBuilder(ecoAsset, Asset.NATIVE, "8282", '0.7')
            .setOfferId('9298298398333')
            .build();

    CreatePassiveSellOfferOperation createPassiveSellOfferOperation =
        CreatePassiveSellOfferOperationBuilder(
                astroAsset, moonAsset, "2828", '0.5')
            .build();

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
        .build();

    transaction.sign(keyPairA, Network.TESTNET);

    String txrep = TxRep.toTxRep(transaction);
    print(txrep);
  });

  test('txrep to transaction', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.fee: 800
tx.seqNum: 1102902109202
tx.timeBounds._present: true
tx.timeBounds.minTime: 1595282368
tx.timeBounds.maxTime: 1595284000
tx.memo.type: MEMO_TEXT
tx.memo.text: "Enjoy this transaction"
tx.operations.len: 8
tx.operation[0].sourceAccount._present: false
tx.operation[0].body.type: CREATE_ACCOUNT
tx.operation[0].body.createAccountOp.destination: GBTU43IBHZW2QOMQBGFYIJGOMSAKQCEMDHDICDHXQJLBFWDRW2J4GTTI
tx.operation[0].body.createAccountOp.startingBalance: 22000000000000000000201112291981902020202021230019
tx.operation[1].sourceAccount._present: true
tx.operation[1].sourceAccount: GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[1].body.type: PAYMENT
tx.operation[1].body.paymentOp.destination: GBTU43IBHZW2QOMQBGFYIJGOMSAKQCEMDHDICDHXQJLBFWDRW2J4GTTI
tx.operation[1].body.paymentOp.asset: native
tx.operation[1].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[2].sourceAccount._present: true
tx.operation[2].sourceAccount: GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[2].body.type: PAYMENT
tx.operation[2].body.paymentOp.destination: GBTU43IBHZW2QOMQBGFYIJGOMSAKQCEMDHDICDHXQJLBFWDRW2J4GTTI
tx.operation[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operation[2].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[3].sourceAccount._present: false
tx.operation[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
tx.operation[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
tx.operation[3].body.pathPaymentStrictReceiveOp.destination: GBTU43IBHZW2QOMQBGFYIJGOMSAKQCEMDHDICDHXQJLBFWDRW2J4GTTI
tx.operation[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
tx.operation[3].body.pathPaymentStrictReceiveOp.path.len: 2
tx.operation[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[4].sourceAccount._present: false
tx.operation[4].body.type: PATH_PAYMENT_STRICT_SEND
tx.operation[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
tx.operation[4].body.pathPaymentStrictSendOp.destination: GBTU43IBHZW2QOMQBGFYIJGOMSAKQCEMDHDICDHXQJLBFWDRW2J4GTTI
tx.operation[4].body.pathPaymentStrictSendOp.destAsset: MOON:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[4].body.pathPaymentStrictSendOp.destMin: 12000000000
tx.operation[4].body.pathPaymentStrictSendOp.path.len: 2
tx.operation[4].body.pathPaymentStrictSendOp.path[0]: ECO:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[5].sourceAccount._present: false
tx.operation[5].body.type: SET_OPTIONS
tx.operation[5].body.setOptionsOp.inflationDest._present: true
tx.operation[5].body.setOptionsOp.inflationDest: GBTU43IBHZW2QOMQBGFYIJGOMSAKQCEMDHDICDHXQJLBFWDRW2J4GTTI
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
tx.operation[5].body.setOptionsOp.signer.key: GBTU43IBHZW2QOMQBGFYIJGOMSAKQCEMDHDICDHXQJLBFWDRW2J4GTTI
tx.operation[5].body.setOptionsOp.signer.weight: 50
tx.operation[6].sourceAccount._present: false
tx.operation[6].body.type: MANAGE_SELL_OFFER
tx.operation[6].body.manageSellOfferOp.selling: ECO:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[6].body.manageSellOfferOp.buying: native
tx.operation[6].body.manageSellOfferOp.amount: 82820000000
tx.operation[6].body.manageSellOfferOp.price.n: 7
tx.operation[6].body.manageSellOfferOp.price.d: 10
tx.operation[6].body.manageSellOfferOp.offerID: 9298298398333
tx.operation[7].sourceAccount._present: false
tx.operation[7].body.type: CREATE_PASSIVE_SELL_OFFER
tx.operation[7].body.createPassiveSellOfferOp.selling: ASTRO:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[7].body.createPassiveSellOfferOp.buying: MOON:GDNKJ544DQUUBAJESDL3ZMQ6T3EMHWEQKLKYJD2OUZFIQRDOETE3UJZS
tx.operation[7].body.createPassiveSellOfferOp.amount: 28280000000
tx.operation[7].body.createPassiveSellOfferOp.price.n: 1
tx.operation[7].body.createPassiveSellOfferOp.price.d: 2
tx.signatures.len: 1
tx.signatures[0].hint: 6e24c9ba
tx.signatures[0].signature: f790c47d6d2b44843c98700f20275272fc8a951e82d12b6f56b393cc75f8dab116736503242f355a9fd037da186fe7bf86b0765166df3fba52ccec1aa813be05
tx.ext.v: 0''';

    AbstractTransaction transaction = TxRep.fromTxRep(txRep);
    String txRepRes = TxRep.toTxRep(transaction);
    print(txRepRes);
    assert(txRepRes == txRep);
  });
}
