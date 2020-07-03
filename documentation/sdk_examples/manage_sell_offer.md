
### Manage sell offer

In this example we are going to create, update, and delete an offer to sell one asset for another, otherwise known as a "ask" order or “offer” on a traditional orderbook.

First we are going to prepare the example by creating a seller account, an issuer account and a trusted asset. Then, we send some funds to from the issuer account to the seller account so that the seller is able to offer them for sale. Then, we are going to create, modify and delete the sell offer.

```dart
// Create two key random key pairs, we will need them later for signing.
KeyPair issuerKeipair = KeyPair.random();
KeyPair sellerKeipair = KeyPair.random();

// Account Ids.
String issuerAccountId = issuerKeipair.accountId;
String sellerAccountId = sellerKeipair.accountId;

// Create seller account.
await FriendBot.fundTestAccount(sellerAccountId);

// Create issuer account.
AccountResponse sellerAccount = await sdk.accounts.account(sellerAccountId);
CreateAccountOperation co =
CreateAccountOperationBuilder(issuerAccountId, "10").build();
Transaction transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
    .addOperation(co)
    .build();
transaction.sign(sellerKeipair);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

// Load issuer account so that we can send our custom assets to the seller account.
AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

// Define our custom asset.
Asset moonDollar = AssetTypeCreditAlphaNum4("MOON", issuerAccountId);

// Let the seller trust our custom asset.
ChangeTrustOperation cto = ChangeTrustOperationBuilder(moonDollar, "10000").build();
transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
    .addOperation(cto)
    .build();
transaction.sign(sellerKeipair);
response = await sdk.submitTransaction(transaction);

// Send 2000 MOON asset to the seller account.
PaymentOperation po =
PaymentOperationBuilder(sellerAccountId, moonDollar, "2000").build();
transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
    .addOperation(po)
    .build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);

// Create the offer.
// I want to sell 100 MOON for 50 XLM.
String amountSelling = "100"; // I want to sell 100 MOON.
String price = "0.5"; // Price of 1 unit of selling in terms of buying.

// Create the manage sell offer operation. Selling: 100 MOON for 50 XLM (price = 0.5 => Price of 1 unit of selling in terms of buying.)
ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
    moonDollar, Asset.NATIVE, amountSelling, price).build();
// Build the transaction.
transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
    .addOperation(ms)
    .build();
// Sign.
transaction.sign(sellerKeipair);
// Submit.
response = await sdk.submitTransaction(transaction);

// Now let's load the offers of our account to see if the offer has been created.
Page<OfferResponse> offers = await sdk.offers.forAccount(sellerAccountId).execute();
OfferResponse offer = offers.records.first;

String sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum ? (offer.selling as AssetTypeCreditAlphaNum).code : "XLM";
String buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum ? (offer.buying as AssetTypeCreditAlphaNum).code : "XLM";
print("offerId: ${offer.id} - selling: ${offer.amount} " + sellingAssetCode + " buying: " + buyingAssetCode + " price: ${offer.price}");
// offerId: 16252986 - selling: 100.0000000 MOON buying: XLM price: 0.5000000
// Price of 1 unit of selling in terms of buying.

String offerId = offer.id;

// Now lets modify our offer.
amountSelling = "150";
price = "0.3";

// Create the manage sell offer operation.
ms = ManageSellOfferOperationBuilder(
    moonDollar, Asset.NATIVE, amountSelling, price)
    .setOfferId(offerId) // Provide the id of the offer to be modified.
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
// offerId: 16252986 - selling: 150.0000000 MOON buying: XLM price: 0.3000000
// Price of 1 unit of selling in terms of buying.

// And now let's delete the offer. To delete it, we must set the amount to zero.
amountSelling = "0";
// Create the operation.
ms = ManageSellOfferOperationBuilder(
    moonDollar, Asset.NATIVE, amountSelling, price)
    .setOfferId(offerId) // Provide the id of the offer to be deleted.
    .build();
// Build the transaction.
transaction = TransactionBuilder(sellerAccount, Network.TESTNET).addOperation(ms).build();
// Sign.
transaction.sign(sellerKeipair);
// Submit.
response = await sdk.submitTransaction(transaction);

// Check if the offer has been deleted.
offers = await sdk.offers.forAccount(sellerAccountId).execute();
if(offers.records.length == 0) {
  print("success");
}
```
