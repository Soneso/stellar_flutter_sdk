
### Create passive sell offer

In this example we are going to create an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook, _without taking a reverse offer of equal price_.

First we are going to prepare the example by creating a seller account, an issuer account and a trusted asset. Then, we send some custom asset funds to from the issuer account to the seller account so that the seller is able to offer them for sale. Then, we are going to create, modify and delete the passive sell offer.

```dart
// Create two random key pairs, we will need them later for signing.
KeyPair issuerKeipair = KeyPair.random();
KeyPair sellerKeipair = KeyPair.random();

// Account Ids.
String issuerAccountId = issuerKeipair.accountId;
String sellerAccountId = sellerKeipair.accountId;

// Create seller account.
await FriendBot.fundTestAccount(sellerAccountId);

// Create issuer account.
AccountResponse sellerAccount = await sdk.accounts.account(sellerAccountId);
CreateAccountOperation co = CreateAccountOperationBuilder(issuerAccountId, "10").build();
Transaction transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
    .addOperation(co).build();
transaction.sign(sellerKeipair);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

// Load issuer account so that we can send some custom asset funds to the seller account.
AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

// Define our custom asset.
Asset marsDollar = AssetTypeCreditAlphaNum4("MARS", issuerAccountId);

// Let the seller account trust our issuer and custom asset.
ChangeTrustOperation cto = ChangeTrustOperationBuilder(marsDollar, "10000").build();
transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
    .addOperation(cto)
    .build();
transaction.sign(sellerKeipair);
response = await sdk.submitTransaction(transaction);

// Send a couple of custom asset MARS funds from the issuer to the seller account so that the seller can offer them.
PaymentOperation po = PaymentOperationBuilder(sellerAccountId, marsDollar, "2000").build();
transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
    .addOperation(po).build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);

// Create the offer.
// I want to sell 100 MARS for 50 XLM.
String amountSelling = "100";
String price = "0.5";

// Create the passive sell offer operation. Selling: 100 MARS for 50 XLM (price = 0.5 => Price of 1 unit of selling in terms of buying.)
CreatePassiveSellOfferOperation cpso = CreatePassiveSellOfferOperationBuilder(
            marsDollar, Asset.NATIVE, amountSelling, price).build();
// Build the transaction.
transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
    .addOperation(cpso)
    .build();
// Sign.
transaction.sign(sellerKeipair);
// Submit.
response = await sdk.submitTransaction(transaction);

// Now let's load the offers of our account to see if the offer has been created.
Page<OfferResponse> offers = (await sdk.offers.forAccount(sellerAccountId).execute());
OfferResponse offer = offers.records.first;

String sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum ? (offer.selling as AssetTypeCreditAlphaNum).code : "XLM";
String buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum ? (offer.buying as AssetTypeCreditAlphaNum).code : "XLM";
print("offerId: ${offer.id} - selling: ${offer.amount} " + sellingAssetCode + " buying: " + buyingAssetCode + " price: ${offer.price}");
// offerId: 16260716 - selling: 100.0000000 MARS buying: XLM price: 0.5000000
// Price of 1 unit of selling in terms of buying.

// Now lets modify our offer.
String offerId = offer.id;

// update offer
amountSelling = "150";
price = "0.3";

// To modify the offer, we are going to use the mange sell offer operation.
ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(marsDollar, Asset.NATIVE, amountSelling, price)
    .setOfferId(offerId) // set id of the offer to be modified.
    .build();
// Build the transaction.
transaction = TransactionBuilder(sellerAccount, Network.TESTNET).addOperation(ms).build();
// Sign.
transaction.sign(sellerKeipair);
// Submit.
response = await sdk.submitTransaction(transaction);

// Load again to see if it has been modified.
offers = await sdk.offers.forAccount(sellerAccountId).execute();
offer = offers.records.first;

sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum ? (offer.selling as AssetTypeCreditAlphaNum).code : "XLM";
buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum ? (offer.buying as AssetTypeCreditAlphaNum).code : "XLM";
print("offerId: ${offer.id} - selling: ${offer.amount} " + sellingAssetCode + " buying: " + buyingAssetCode + " price: ${offer.price}");
//offerId: 16260716 - selling: 150.0000000 MARS buying: XLM price: 0.3000000

// And now let's delete the offer. To delete it, we must set the amount to zero.
amountSelling = "0";

// To delete the offer we can use the manage sell offer operation.
ms = ManageSellOfferOperationBuilder(marsDollar, Asset.NATIVE, amountSelling, price)
    .setOfferId(offerId) // Set the id of the offer to be deleted.
    .build();
// Build the transaction.
transaction = TransactionBuilder(sellerAccount, Network.TESTNET).addOperation(ms).build();
// Sign.
transaction.sign(sellerKeipair);
// Submit.
response = await sdk.submitTransaction(transaction);

// Check if the offer has been deleted.
offers = await sdk.offers.forAccount(sellerAccountId).execute();
if (offers.records.length == 0) {
  print("success");
}
```
