@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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
    Transaction transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(caob.build()).build();
    transaction.sign(trustorKeipair);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    String limit = "10000";
    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    bool found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        assert(double.parse(balance.limit) == double.parse(limit));
        break;
      }
    }
    assert(found);

    // update trustline, change limit.
    limit = "40000";
    ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    trustorAccount = await sdk.accounts.account(trustorAccountId);
    found = false;
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        found = true;
        assert(double.parse(balance.limit) == double.parse(limit));
        break;
      }
    }
    assert(found);

    // delete trustline.
    limit = "0";
    ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

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
    Transaction transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(caob.build()).build();
    transaction.sign(trustorKeipair);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);
    SetOptionsOperationBuilder sopb = SetOptionsOperationBuilder();
    sopb.setSetFlags(3); // Auth required, auth revocable
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(sopb.build()).build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    issuerAccount = await sdk.accounts.account(issuerAccountId);
    assert(issuerAccount.flags.authRequired);
    assert(issuerAccount.flags.authRevocable);
    assert(!issuerAccount.flags.authImmutable);

    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    String limit = "10000";
    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(astroDollar, limit);
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(trustorKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

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
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(po).build();
    transaction.sign(issuerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(!response.success); // not authorized.

    AllowTrustOperation aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 1).build(); // authorize
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
    transaction.sign(issuerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(po).build();
    transaction.sign(issuerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success); // authorized.

    String amountSelling = "100";
    String price = "0.5";

    CreatePassiveSellOfferOperation cpso = CreatePassiveSellOfferOperationBuilder(astroDollar, Asset.NATIVE, amountSelling, price).build();
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(cpso).build();
    transaction.sign(trustorKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    List<OfferResponse> offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == astroDollar);

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 0).build(); // authorize
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
    transaction.sign(issuerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

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

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 1).build(); // authorize
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    cpso = CreatePassiveSellOfferOperationBuilder(astroDollar, Asset.NATIVE, amountSelling, price).build();
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(cpso).build();
    transaction.sign(trustorKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers.length == 1);

    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 2).build(); // authorized to maintain liabilities.
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    assert(offers.length == 1);

    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(po).build();
    transaction.sign(issuerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(!response.success); // is not authorized for new funds

  });
}
