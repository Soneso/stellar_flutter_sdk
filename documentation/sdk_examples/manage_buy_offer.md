
### Manage buy offer

In this example we are going to create, update, and delete an offer to buy one asset for another, otherwise known as a "bid" order on a traditional orderbook.

First we are going to prepare the example by creating an account and a trusted asset, so that we can make a buy offer for it. Then, we are going to create, modify and delete the offer.

```dart
// Prepare two random keypairs, we will need the later for signing.
KeyPair issuerKeypair = KeyPair.random();
KeyPair buyerKeypair = KeyPair.random();

// Account Ids.
String issuerAccountId = issuerKeypair.accountId;
String buyerAccountId = buyerKeypair.accountId;

// Create the buyer account.
await FriendBot.fundTestAccount(buyerAccountId);

// Create the issuer account.
AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
CreateAccountOperationBuilder caob = CreateAccountOperationBuilder(issuerAccountId, "10");
Transaction transaction = TransactionBuilder(buyerAccount)
    .addOperation(caob.build()).build();
transaction.sign(buyerKeypair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

// Define an asset.
Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);

// Create a trustline for the buyer account.
ChangeTrustOperation cto = ChangeTrustOperationBuilder(astroDollar, "10000").build();
transaction = TransactionBuilder(buyerAccount).addOperation(cto).build();
transaction.sign(buyerKeypair, Network.TESTNET);
response = await sdk.submitTransaction(transaction);

// Create the offer.
// I want to pay max. 50 XLM for 100 ASTRO.
String amountBuying = "100"; // Want to buy 100 ASTRO
String price = "0.5"; // Price of 1 unit of buying in terms of selling

// Create the manage buy offer operation. Buying: 100 ASTRO for 50 XLM (price = 0.5 => Price of 1 unit of buying in terms of selling)
ManageBuyOfferOperation ms = ManageBuyOfferOperationBuilder(Asset.NATIVE, astroDollar, amountBuying, price).build();
// Create the transaction.
transaction = TransactionBuilder(buyerAccount).addOperation(ms).build();
// Sign the transaction.
transaction.sign(buyerKeypair, Network.TESTNET);
// Submit the transaction.
response = await sdk.submitTransaction(transaction);

// Now let's load the offers of our account to see if the offer has been created.
Page<OfferResponse> offers = await sdk.offers.forAccount(buyerAccountId).execute();
OfferResponse offer = offers.records.first;

String buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum ? (offer.buying as AssetTypeCreditAlphaNum).code : "XLM";
String sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum ? (offer.selling as AssetTypeCreditAlphaNum).code : "XLM";
print("offerId: ${offer.id} - buying: " + buyingAssetCode +  " - selling: ${offer.amount} " + sellingAssetCode + " price: ${offer.price}");
// offerId: 16245277 - buying: ASTRO - selling: 50.0000000 XLM price: 2.0000000
// As you can see, the price is stored here as "Price of 1 unit of selling in terms of buying".

// Now lets modify our offer.
String offerId = offer.id;

// New data.
amountBuying = "150";
price = "0.3";

// Build the manage buy offer operation
ms = ManageBuyOfferOperationBuilder(Asset.NATIVE, astroDollar, amountBuying, price)
    .setOfferId(offerId) // provide the offerId of the offer to be modified.
    .build();

// Build the transaction.
transaction = TransactionBuilder(buyerAccount).addOperation(ms).build();
// Sign.
transaction.sign(buyerKeypair, Network.TESTNET);
// Submit.
response = await sdk.submitTransaction(transaction);

// Load the offer from stellar.
offers = (await sdk.offers.forAccount(buyerAccountId).execute());
offer = offers.records.first;

buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum ? (offer.buying as AssetTypeCreditAlphaNum).code : "XLM";
sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum ? (offer.selling as AssetTypeCreditAlphaNum).code : "XLM";
print("offerId: ${offer.id} - buying: " + buyingAssetCode +  " - selling: ${offer.amount} " + sellingAssetCode + " price: ${offer.price}");
// offerId: 16245277 - buying: ASTRO - selling: 45.0000000 XLM price: 3.3333333

// And now let's delete our offer
// To delete, we need to set the amount to 0.
amountBuying = "0";

// Create the operation.
ms = ManageBuyOfferOperationBuilder(Asset.NATIVE, astroDollar, amountBuying, price)
    .setOfferId(offerId) // Provide the id of the offer to be deleted.
    .build();

// Build the transaction.
transaction = TransactionBuilder(buyerAccount).addOperation(ms).build();

// Sign.
transaction.sign(buyerKeypair, Network.TESTNET);

// Submit.
response = await sdk.submitTransaction(transaction);

// check if the offer has been deleted.
offers = await sdk.offers.forAccount(buyerAccountId).execute();
if(offers.records.length == 0) {
  print("success");
}
```
