
### Create Account

In this example we will let Friendbot fund a testnet account. In the main net however we need another already existing account to be able to create a new one.

### Friendbot (testnet only)

```dart
StellarSDK sdk = StellarSDK.TESTNET;

// Create a random key pair for our new account.
KeyPair keyPair = KeyPair.random();

// Ask the Friendbot to create our new account in the stellar network (only available in testnet).
bool funded = await FriendBot.fundTestAccount(keyPair.accountId);

// Load the data of the new account from stellar.
AccountResponse account = await sdk.accounts.account(keyPair.accountId);
```

### Create Account Operation

```dart
StellarSDK sdk = StellarSDK.TESTNET;

// Build a key pair from the seed of an existing account. We will need it for signing.
KeyPair existingAccountKeyPair = KeyPair.fromSecretSeed("SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");

// Existing account id.
String existingAccountId = existingAccountKeyPair.accountId;

// Create a random keypair for a new account to be created.
KeyPair newAccountKeyPair = KeyPair.random();

// Load the data of the existing account so that we receive it's current sequence number.
AccountResponse existingAccount = await sdk.accounts.account(existingAccountId);

// Build a transaction containing a create account operation to create the new account.
// Starting balance: 10 XLM.
Transaction transaction = new TransactionBuilder(existingAccount)
    .addOperation(new CreateAccountOperationBuilder(newAccountKeyPair.accountId, "10").build())
    .build();

// Sign the transaction with the key pair of the existing account.
transaction.sign(existingAccountKeyPair, Network.TESTNET);

// Submit the transaction to stellar.
await sdk.submitTransaction(transaction);

// Load the data of the new created account.
AccountResponse newAccount = await sdk.accounts.account(newAccountKeyPair.accountId);

```