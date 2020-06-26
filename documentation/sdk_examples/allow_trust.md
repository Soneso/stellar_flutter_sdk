
### Allow trust

In this example we will update the ```authorized``` flag of an existing trustline. This can only be called by the issuer of a trustline’s asset, and only when ```AUTHORIZATION REQUIRED``` (at the minimum) has been set on the issuer’s account.

The issuer can only clear the ```authorized``` flag if the issuer has the ```AUTH_REVOCABLE_FLAG``` set. Otherwise, the issuer can only set the authorized flag.

If the issuer clears the ```authorized``` flag, all offers owned by the trustor that are either selling type or buying type will be deleted. 

```dart
// Create two random key pairs, we will need them later for signing.
KeyPair issuerKeipair = KeyPair.random();
KeyPair trustorKeipair = KeyPair.random();

// Account Ids.
String issuerAccountId = issuerKeipair.accountId;
String trustorAccountId = trustorKeipair.accountId;

// Create trustor account.
await FriendBot.fundTestAccount(trustorAccountId);

// Load trustor account, we will need it later to create the trustline.
AccountResponse trustorAccount = await sdk.accounts.account(trustorAccountId);

// Create the issuer account.
CreateAccountOperation cao = CreateAccountOperationBuilder(issuerAccountId, "10").build();
Transaction transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(cao).build();
transaction.sign(trustorKeipair);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

// Load the issuer account.
AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);
// Set up the flags on the isser account.
SetOptionsOperationBuilder sopb = SetOptionsOperationBuilder();
sopb.setSetFlags(3); // Auth required, auth revocable
// Build the transaction.
transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(sopb.build()).build();
// Sign.
transaction.sign(issuerKeipair);
// Submit.
response = await sdk.submitTransaction(transaction);

// Reload the issuer account to check the flags.
issuerAccount = await sdk.accounts.account(issuerAccountId);
if(issuerAccount.flags.authRequired
    && issuerAccount.flags.authRevocable
    && !issuerAccount.flags.authImmutable) {

  print("issuer account flags correctly set");
}

// Define our custom asset.
String assetCode = "ASTRO";
Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

// Build the trustline.
String limit = "10000";
ChangeTrustOperation cto = ChangeTrustOperationBuilder(astroDollar, limit).build();
transaction = TransactionBuilder(trustorAccount, Network.TESTNET)
    .addOperation(cto)
    .build();
transaction.sign(trustorKeipair);
response = await sdk.submitTransaction(transaction);

// Reload the trustor account to see if the trustline has been created.
trustorAccount = await sdk.accounts.account(trustorAccountId);
for (Balance balance in trustorAccount.balances) {
  if (balance.assetCode == assetCode) {
    print("trustline awailable");
    break;
  }
}

// Now lets try to send some custom asset funds to the trustor account.
// This should not work, because the issuer must authorize the trustline first.
PaymentOperation po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
    .addOperation(po)
    .build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);
if(!response.success) { // not authorized.
    print("trustline is not authorized");
}

// Now let's authorize the trustline.
// Build the allow trust operation. Set the authorized flag to 1.
AllowTrustOperation aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 1).build(); // authorize
transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);

// Try again to send the payment. Should work now.
po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(po).build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);
if(response.success) { // authorized.
    print("sccess - trustline is now authorized.");
}

// Now create an offer, to see if it will be deleted after we will remove the authorized flag.
String amountSelling = "100";
String price = "0.5";
CreatePassiveSellOfferOperation cpso = CreatePassiveSellOfferOperationBuilder(astroDollar, Asset.NATIVE, amountSelling, price).build();
transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(cpso).build();
transaction.sign(trustorKeipair);
response = await sdk.submitTransaction(transaction);

// Check if the offer has been added.
List<OfferResponse> offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
OfferResponse offer = offers.first;
if(offer.buying == Asset.NATIVE && offer.selling == astroDollar) {
  print("offer found");
}

// Now lets remove the authorization. To do so, we set the authorized flag to 0.
// This should also delete the offer.
aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 0).build(); // not authorized
transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);

// Check if the offer has been deleted.
offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
if(offers.length == 0) {
  print("success, offer has been deleted");
}

// Now, let's authorize the trustline again and then authorize it only to maintain liabilities.
aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 1).build(); // authorize
transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);

// Create the offer again.
cpso = CreatePassiveSellOfferOperationBuilder(astroDollar, Asset.NATIVE, amountSelling, price).build();
transaction = TransactionBuilder(trustorAccount, Network.TESTNET).addOperation(cpso).build();
transaction.sign(trustorKeipair);
response = await sdk.submitTransaction(transaction);

// Check that the offer has been created.
offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
if(offers.length == 1) {
  print("offer has been created");
}

// Now let's deautorize the trustline but allow the trustor to maintain his offer.
// For this, we set the authorized flag to 2.
aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 2).build(); // authorized to maintain liabilities.
transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(aop).build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);

// Load the offers to see if our offer is still there.
offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
if(offers.length == 1) {
  print("success, offer exists");
}

// Next, let's try to send some ASTRO to the trustor account.
// This should not work, since the trustline has been deauthorized before.
po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
transaction = TransactionBuilder(issuerAccount, Network.TESTNET).addOperation(po).build();
transaction.sign(issuerKeipair);
response = await sdk.submitTransaction(transaction);
if(!response.success); {// is not authorized for new funds
  print("payment correctly blocked.");
}
```
