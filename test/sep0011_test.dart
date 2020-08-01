// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  test('txrep to transaction qnd back to txrep', () {
    String txRep = '''
type: ENVELOPE_TYPE_TX
tx.sourceAccount: GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
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
tx.operation[0].body.createAccountOp.destination: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
tx.operation[0].body.createAccountOp.startingBalance: 22000000000000000000201112291981902020202021230019
tx.operation[1].sourceAccount._present: true
tx.operation[1].sourceAccount: GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[1].body.type: PAYMENT
tx.operation[1].body.paymentOp.destination: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
tx.operation[1].body.paymentOp.asset: native
tx.operation[1].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[2].sourceAccount._present: true
tx.operation[2].sourceAccount: GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[2].body.type: PAYMENT
tx.operation[2].body.paymentOp.destination: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
tx.operation[2].body.paymentOp.asset: USD:GAZFEVBSEGJJ63WPVVIWXLZLWN2JYZECECGT6GUNP4FJDVZVNXWQWMYI
tx.operation[2].body.paymentOp.amount: 33333330000000000000201112291981902020202021233330
tx.operation[3].sourceAccount._present: false
tx.operation[3].body.type: PATH_PAYMENT_STRICT_RECEIVE
tx.operation[3].body.pathPaymentStrictReceiveOp.sendAsset: IOM:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[3].body.pathPaymentStrictReceiveOp.sendMax: 20000000
tx.operation[3].body.pathPaymentStrictReceiveOp.destination: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
tx.operation[3].body.pathPaymentStrictReceiveOp.destAsset: MOON:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[3].body.pathPaymentStrictReceiveOp.destAmount: 80000000
tx.operation[3].body.pathPaymentStrictReceiveOp.path.len: 2
tx.operation[3].body.pathPaymentStrictReceiveOp.path[0]: ECO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[3].body.pathPaymentStrictReceiveOp.path[1]: ASTRO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[4].sourceAccount._present: false
tx.operation[4].body.type: PATH_PAYMENT_STRICT_SEND
tx.operation[4].body.pathPaymentStrictSendOp.sendAsset: IOM:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[4].body.pathPaymentStrictSendOp.sendAmount: 4000000000
tx.operation[4].body.pathPaymentStrictSendOp.destination: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
tx.operation[4].body.pathPaymentStrictSendOp.destAsset: MOON:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[4].body.pathPaymentStrictSendOp.destMin: 12000000000
tx.operation[4].body.pathPaymentStrictSendOp.path.len: 2
tx.operation[4].body.pathPaymentStrictSendOp.path[0]: ECO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[4].body.pathPaymentStrictSendOp.path[1]: ASTRO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[5].sourceAccount._present: false
tx.operation[5].body.type: SET_OPTIONS
tx.operation[5].body.setOptionsOp.inflationDest._present: true
tx.operation[5].body.setOptionsOp.inflationDest: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
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
tx.operation[5].body.setOptionsOp.signer.key: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
tx.operation[5].body.setOptionsOp.signer.weight: 50
tx.operation[6].sourceAccount._present: false
tx.operation[6].body.type: MANAGE_SELL_OFFER
tx.operation[6].body.manageSellOfferOp.selling: ECO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[6].body.manageSellOfferOp.buying: native
tx.operation[6].body.manageSellOfferOp.amount: 82820000000
tx.operation[6].body.manageSellOfferOp.price.n: 7
tx.operation[6].body.manageSellOfferOp.price.d: 10
tx.operation[6].body.manageSellOfferOp.offerID: 9298298398333
tx.operation[7].sourceAccount._present: false
tx.operation[7].body.type: CREATE_PASSIVE_SELL_OFFER
tx.operation[7].body.createPassiveSellOfferOp.selling: ASTRO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[7].body.createPassiveSellOfferOp.buying: MOON:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[7].body.createPassiveSellOfferOp.amount: 28280000000
tx.operation[7].body.createPassiveSellOfferOp.price.n: 1
tx.operation[7].body.createPassiveSellOfferOp.price.d: 2
tx.operation[8].sourceAccount._present: false
tx.operation[8].body.type: CHANGE_TRUST
tx.operation[8].body.changeTrustOp.line: ASTRO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[8].body.changeTrustOp.limit._present: true
tx.operation[8].body.changeTrustOp.limit: 100000000000
tx.operation[9].sourceAccount._present: false
tx.operation[9].body.type: ALLOW_TRUST
tx.operation[9].body.allowTrustOp.trustor: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
tx.operation[9].body.allowTrustOp.asset: MOON
tx.operation[9].body.allowTrustOp.authorize: 1
tx.operation[10].sourceAccount._present: false
tx.operation[10].body.type: ACCOUNT_MERGE
tx.operation[10].body.destination: GAB4GIAHEQ7C6UNG4U7KDTQZSMRP4ZWOPF4ZW5TARG6N7UBHJD5UMQZK
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
tx.operation[13].body.manageBuyOfferOp.selling: MOON:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[13].body.manageBuyOfferOp.buying: ECO:GB2LBNNYUSZEJQF37MBBLXKGR4SBNEJHKMDDZ5EJL2ZRGGHEEJMNL3XX
tx.operation[13].body.manageBuyOfferOp.buyAmount: 120000000
tx.operation[13].body.manageBuyOfferOp.price.n: 1
tx.operation[13].body.manageBuyOfferOp.price.d: 5
tx.operation[13].body.manageBuyOfferOp.offerID: 9298298398334
tx.signatures.len: 1
tx.signatures[0].hint: e42258d5
tx.signatures[0].signature: e59cb71274c91bcc94f26b92a66357aba866f3f8c63d1879551937a24f1986af976e87e2387ef36e61cd94c9bc8771b04551e8bf8325d85775ae3647262bad02
tx.ext.v: 0''';

    AbstractTransaction transaction = TxRep.fromTxRep(txRep);
    String txRepRes = TxRep.toTxRep(transaction);
    assert(txRepRes == txRep);
  });

  /*test('fee bump transaction to txrep', () {
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

    AccountMergeOperation accountMergeOperation = AccountMergeOperationBuilder(
        accountBId).build();

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

    FeeBumpTransaction feeBump = FeeBumpTransactionBuilder(transaction).setFeeAccount(accountCId).setBaseFee(100000).build();
    String txrep = TxRep.toTxRep(feeBump);
    print(txrep);
  });*/
}
