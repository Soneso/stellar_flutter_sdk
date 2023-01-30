@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'tests_util.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('change trust test', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair trustorKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String trustorAccountId = trustorKeipair.accountId;

    await FriendBot.fundTestAccount(trustorAccountId);

    AccountResponse trustorAccount = await sdk.accounts.account(trustorAccountId);
    CreateAccountOperationBuilder caob = CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(trustorAccount).addOperation(caob.build()).build();
    transaction.sign(trustorKeipair, Network.TESTNET);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    String limit = "10000";
    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, Network.TESTNET);

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
    transaction = TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, Network.TESTNET);

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
    transaction = TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, Network.TESTNET);

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
  });

  test('allow trust test', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair trustorKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String trustorAccountId = trustorKeipair.accountId;

    await FriendBot.fundTestAccount(trustorAccountId);

    AccountResponse trustorAccount = await sdk.accounts.account(trustorAccountId);
    CreateAccountOperationBuilder caob = CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(trustorAccount).addOperation(caob.build()).build();
    transaction.sign(trustorKeipair, Network.TESTNET);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);
    SetOptionsOperationBuilder sopb = SetOptionsOperationBuilder();
    sopb.setSetFlags(3); // Auth required, auth revocable
    transaction = TransactionBuilder(issuerAccount).addOperation(sopb.build()).build();
    transaction.sign(issuerKeipair, Network.TESTNET);
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
    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair, Network.TESTNET);

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

    PaymentOperation po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(!response.success); // not authorized.
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AllowTrustOperation aop =
        AllowTrustOperationBuilder(trustorAccountId, assetCode, 1).build(); // authorize
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success); // authorized.
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String amountSelling = "100";
    String price = "0.5";

    CreatePassiveSellOfferOperation cpso =
        CreatePassiveSellOfferOperationBuilder(astroDollar, Asset.NATIVE, amountSelling, price)
            .build();
    transaction = TransactionBuilder(trustorAccount).addOperation(cpso).build();
    transaction.sign(trustorKeipair, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    List<OfferResponse>? offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers!.length == 1);
    OfferResponse offer = offers!.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == astroDollar);

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 0).build(); // authorize
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers!.length == 0);

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

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 1).build(); // authorize
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    cpso = CreatePassiveSellOfferOperationBuilder(astroDollar, Asset.NATIVE, amountSelling, price)
        .build();
    transaction = TransactionBuilder(trustorAccount).addOperation(cpso).build();
    transaction.sign(trustorKeipair, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers!.length == 1);

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 2)
        .build(); // authorized to maintain liabilities.
    transaction = TransactionBuilder(issuerAccount).addOperation(aop).build();
    transaction.sign(issuerKeipair, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers!.length == 1);

    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(!response.success); // is not authorized for new funds
    TestUtils.resultDeAndEncodingTest(transaction, response);
  });
}
