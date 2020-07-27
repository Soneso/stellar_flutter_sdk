
### Change trust

In this example we will create, update, and delete a trustline. For more on trustlines, please refer to the [assets documentation](https://www.stellar.org/developers/learn/concepts/assets.html).

We will let one account, called trustor, trust another account that is the issuer of a custom token called "ASTRO". Then, we will modify and finally delete the trustline.

```dart
// Create two random key pairs, we will need them later for signing.
KeyPair issuerKeypair = KeyPair.random();
KeyPair trustorKeypair = KeyPair.random();

// Account Ids.
String issuerAccountId = issuerKeypair.accountId;
String trustorAccountId = trustorKeypair.accountId;

// Create trustor account.
await FriendBot.fundTestAccount(trustorAccountId);

// Load the trustor account so that we can later create the trustline.
AccountResponse trustorAccount = await sdk.accounts.account(trustorAccountId);

// Create the issuer account.
CreateAccountOperation cao = CreateAccountOperationBuilder(issuerAccountId, "10").build();
Transaction transaction = TransactionBuilder(trustorAccount)
    .addOperation(cao)
    .build();
transaction.sign(trustorKeypair, Network.TESTNET);
SubmitTransactionResponse response = await sdk.submitTransaction(transaction);

// Creat our custom asset.
String assetCode = "ASTRO";
Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

// Create the trustline. Limit: 10000 ASTRO.
String limit = "10000";
// Build the operation.
ChangeTrustOperation cto = ChangeTrustOperationBuilder(astroDollar, limit).build();
// Build the transaction.
transaction = TransactionBuilder(trustorAccount)
    .addOperation(cto)
    .build();
// Sign.
transaction.sign(trustorKeypair, Network.TESTNET);
// Submit.
response = await sdk.submitTransaction(transaction);

// Load the trustor account again to see if the trustline has been created.
trustorAccount = await sdk.accounts.account(trustorAccountId);

// Check if the trustline exists.
for (Balance balance in trustorAccount.balances) {
  if (balance.assetCode == assetCode) {
    print("Trustline for " +  assetCode + " found. Limit: ${double.parse(balance.limit)}");
    // Trustline for ASTRO found. Limit: 10000.0
    break;
  }
}

// Now, let's modify the trustline, change the trust limit to 40000.
limit = "40000";

// Build the change trust operation.
cto = ChangeTrustOperationBuilder(astroDollar, limit).build();
// Build the transaction.
transaction = TransactionBuilder(trustorAccount).addOperation(cto).build();
// Sign.
transaction.sign(trustorKeypair, Network.TESTNET);
// Submit.
response = await sdk.submitTransaction(transaction);

// Load the trustor account to see if the trustline has been modified.
trustorAccount = await sdk.accounts.account(trustorAccountId);

// Check.
for (Balance balance in trustorAccount.balances) {
  if (balance.assetCode == assetCode) {
    print("Trustline for " +  assetCode + " found. Limit: ${double.parse(balance.limit)}");
    // Trustline for ASTRO found. Limit: 40000.0
    break;
  }
}

// And now let's delete the trustline.
// To delete it, we must set the trust limit to zero.
limit = "0";
// Build the operation.
cto = ChangeTrustOperationBuilder(astroDollar, limit).build();
// Build the transaction.
transaction = TransactionBuilder(trustorAccount).addOperation(cto).build();
// Sign.
transaction.sign(trustorKeypair, Network.TESTNET);
// Submit.
response = await sdk.submitTransaction(transaction);

// Load the trustor account again to see if the trustline has been deleted.
trustorAccount = await sdk.accounts.account(trustorAccountId);

// Check.
bool found = false;

for (Balance balance in trustorAccount.balances) {
  if (balance.assetCode == assetCode) {
    found = true;
    break;
  }
}

if(!found) {
  print("success, trustline deleted");
}
```
