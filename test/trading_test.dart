@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('manage buy offer', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair buyerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String buyerAccountId = buyerKeipair.accountId;

    await FriendBot.fundTestAccount(buyerAccountId);

    AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
    CreateAccountOperationBuilder caob = CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(buyerAccount, Network.TESTNET).addOperation(caob.build()).build();
    transaction.sign(buyerKeipair);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);

    Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);

    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(astroDollar,"10000");
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET).addOperation(ctob.build()).build();
    transaction.sign(buyerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String amountBuying = "100";
    String price = "0.5";

    ManageBuyOfferOperation ms = ManageBuyOfferOperationBuilder(Asset.NATIVE, astroDollar, amountBuying, price).build();
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET).addOperation(ms).build();
    transaction.sign(buyerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    List<OfferResponse> offers = (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    double offerAmount = double.parse(offer.amount);
    double offerPrice = double.parse(offer.price);
    double buyingAmount = double.parse(amountBuying);

    assert(offerAmount * offerPrice == buyingAmount);

    assert(offer.seller.accountId == buyerKeipair.accountId);

  });
}
