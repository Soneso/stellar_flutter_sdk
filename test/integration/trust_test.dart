@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../tests_util.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';
  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  test('change trust test', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair trustorKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String trustorAccountId = trustorKeipair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(trustorAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(trustorAccountId);
    }

    AccountResponse trustorAccount =
        await sdk.accounts.account(trustorAccountId);
    CreateAccountOperationBuilder caob =
        CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction =
        TransactionBuilder(trustorAccount).addOperation(caob.build()).build();
    transaction.sign(trustorKeipair, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    String limit = "10000";
    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(astroDollar, limit);
    transaction =
        TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    bool found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        assert(double.parse(balance.limit!) == double.parse(limit));
        break;
      }
    }
    assert(found);

    // update trustline, change limit.
    limit = "40000";
    ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction =
        TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        assert(double.parse(balance.limit!) == double.parse(limit));
        break;
      }
    }
    assert(found);

    // delete trustline.
    limit = "0";
    ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction =
        TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        break;
      }
    }
    assert(!found);

    // test operation & effects responses can be parsed
    var operationsPage =
        await sdk.operations.forAccount(trustorAccountId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(trustorAccountId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('test max trust amount', () async {
    final issuerAccountId = KeyPair.random().accountId;
    final trustingKeyPair = KeyPair.random();
    final trustingAccountId = trustingKeyPair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(issuerAccountId);
      await FriendBot.fundTestAccount(trustingAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(issuerAccountId);
      await FuturenetFriendBot.fundTestAccount(trustingAccountId);
    }

    final trustingAccount = await sdk.accounts.account(trustingAccountId);

    final myAsset = AssetTypeCreditAlphaNum4('IOM', issuerAccountId);

    final changeTrustOp = ChangeTrustOperationBuilder(
            myAsset, ChangeTrustOperationBuilder.MAX_LIMIT)
        .build();

    final transaction = new TransactionBuilder(trustingAccount)
        .addOperation(changeTrustOp)
        .build();

    transaction.sign(trustingKeyPair, network);

    print('TX XDR: ${transaction.toEnvelopeXdrBase64()}');

    final response = await sdk.submitTransaction(transaction);
    assert(response.success);
  });

  test('allow trust test', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair trustorKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String trustorAccountId = trustorKeipair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(trustorAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(trustorAccountId);
    }

    AccountResponse trustorAccount =
        await sdk.accounts.account(trustorAccountId);
    CreateAccountOperationBuilder caob =
        CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction =
        TransactionBuilder(trustorAccount).addOperation(caob.build()).build();
    transaction.sign(trustorKeipair, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);
    SetOptionsOperationBuilder sopb = SetOptionsOperationBuilder();
    sopb.setSetFlags(3); // Auth required, auth revocable
    transaction =
        TransactionBuilder(issuerAccount).addOperation(sopb.build()).build();
    transaction.sign(issuerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    issuerAccount = await sdk.accounts.account(issuerAccountId);
    assert(issuerAccount.flags.authRequired);
    assert(issuerAccount.flags.authRevocable);
    assert(!issuerAccount.flags.authImmutable);

    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    String limit = "10000";
    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(astroDollar, limit);
    transaction =
        TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    bool found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        //assert(double.parse(balance.balance) == 100.0);
        break;
      }
    }
    assert(found);

    PaymentOperation po =
        PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(!response.success); // not authorized.
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AllowTrustOperation aop =
        AllowTrustOperationBuilder(trustorAccountId, assetCode, 1)
            .build(); // authorize
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success); // authorized.
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String amountSelling = "100";
    String price = "0.5";

    CreatePassiveSellOfferOperation cpso =
        CreatePassiveSellOfferOperationBuilder(
                astroDollar, Asset.NATIVE, amountSelling, price)
            .build();
    transaction = TransactionBuilder(trustorAccount).addOperation(cpso).build();
    transaction.sign(trustorKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    List<OfferResponse>? offers =
        (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == astroDollar);

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 0)
        .build(); // authorize
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers.length == 0);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        assert(double.parse(balance.balance) == 100.0);
        break;
      }
    }
    assert(found);

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 1)
        .build(); // authorize
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    cpso = CreatePassiveSellOfferOperationBuilder(
            astroDollar, Asset.NATIVE, amountSelling, price)
        .build();
    transaction = TransactionBuilder(trustorAccount).addOperation(cpso).build();
    transaction.sign(trustorKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers.length == 1);

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 2)
        .build(); // authorized to maintain liabilities.
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers.length == 1);

    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(!response.success); // is not authorized for new funds
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // test operation & effects responses can be parsed
    var operationsPage =
        await sdk.operations.forAccount(trustorAccountId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(trustorAccountId).execute();
    assert(effectsPage.records.isNotEmpty);

    operationsPage = await sdk.operations.forAccount(issuerAccountId).execute();
    assert(operationsPage.records.isNotEmpty);
    effectsPage = await sdk.effects.forAccount(issuerAccountId).execute();
    assert(effectsPage.records.isNotEmpty);
  });
}
