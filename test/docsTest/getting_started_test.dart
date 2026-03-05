@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  // Shared funded accounts for reuse across tests
  late KeyPair account1;
  late KeyPair account2;
  late KeyPair account3;

  setUpAll(() async {
    account1 = KeyPair.random();
    account2 = KeyPair.random();
    account3 = KeyPair.random();
    await FriendBot.fundTestAccount(account1.accountId);
    await FriendBot.fundTestAccount(account2.accountId);
    await FriendBot.fundTestAccount(account3.accountId);
  });

  test('getting-started: Networks', () {
    // Snippet from getting-started.md "Networks"
    Network testnet = Network.TESTNET;
    Network publicNet = Network.PUBLIC;
    Network futurenet = Network.FUTURENET;

    expect(testnet, isNotNull);
    expect(publicNet, isNotNull);
    expect(futurenet, isNotNull);
  });

  test('getting-started: Assets', () {
    // Snippet from getting-started.md "Assets"
    Asset xlm = Asset.NATIVE;
    Asset usdc = Asset.createNonNativeAsset(
        "USDC", "GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN");

    expect(xlm, isNotNull);
    expect(usdc, isA<AssetTypeCreditAlphaNum4>());
  });

  test('getting-started: Generate a Random KeyPair', () {
    // Snippet from getting-started.md "Generate a Random KeyPair"
    KeyPair keyPair = KeyPair.random();

    String accountId = keyPair.accountId;
    String secretSeed = keyPair.secretSeed;

    expect(accountId, startsWith('G'));
    expect(accountId.length, 56);
    expect(secretSeed, startsWith('S'));
    expect(secretSeed.length, 56);
  });

  test('getting-started: Import from Secret Seed', () {
    // Snippet from getting-started.md "Import from Secret Seed"
    KeyPair keyPair = KeyPair.fromSecretSeed(
        "SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE");

    expect(keyPair.accountId, startsWith('G'));
    expect(keyPair.secretSeed, startsWith('S'));
  });

  test('getting-started: Import from Account ID', () {
    // Snippet from getting-started.md "Import from Account ID"
    KeyPair keyPair = KeyPair.fromAccountId(
        "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D");

    expect(keyPair.accountId,
        "GCZHXL5HXQX5ABDM26LHYRCQZ5OJFHLOPLZX47WEBP3V2PF5AVFK2A5D");
  });

  test('getting-started: Mnemonic Phrases (SEP-5)', () async {
    // Snippet from getting-started.md "Mnemonic Phrases (SEP-5)"
    String mnemonic = await Wallet.generate24WordsMnemonic();

    // Verify it's 24 words
    expect(mnemonic.split(' ').length, 24);

    Wallet wallet = await Wallet.from(mnemonic);

    KeyPair keyPair0 = await wallet.getKeyPair(index: 0);
    KeyPair keyPair1 = await wallet.getKeyPair(index: 1);

    expect(keyPair0.accountId, startsWith('G'));
    expect(keyPair1.accountId, startsWith('G'));
    expect(keyPair0.accountId, isNot(equals(keyPair1.accountId)));

    // Also test 12 words
    String mnemonic12 = await Wallet.generate12WordsMnemonic();
    expect(mnemonic12.split(' ').length, 12);
  });

  test('getting-started: Fund on Testnet', () async {
    // Snippet from getting-started.md "Fund on Testnet"
    KeyPair keyPair = KeyPair.random();
    bool funded = await FriendBot.fundTestAccount(keyPair.accountId);

    expect(funded, true);
  });

  test('getting-started: Create Account on Public Network (testnet variant)',
      () async {
    // Snippet from getting-started.md "Create Account on Public Network"
    // Using testnet instead of public for testing
    KeyPair sourceKeyPair = account1;
    KeyPair newKeyPair = KeyPair.random();

    AccountResponse sourceAccount =
        await sdk.accounts.account(sourceKeyPair.accountId);

    CreateAccountOperation createOp = CreateAccountOperationBuilder(
      newKeyPair.accountId,
      "10",
    ).build();

    Transaction transaction = TransactionBuilder(sourceAccount)
        .addOperation(createOp)
        .build();

    transaction.sign(sourceKeyPair, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    expect(response.success, true);

    // Verify new account exists
    AccountResponse newAccount =
        await sdk.accounts.account(newKeyPair.accountId);
    expect(newAccount.accountId, newKeyPair.accountId);
  });

  test('getting-started: Query Account Data', () async {
    // Snippet from getting-started.md "Query Account Data"
    String accountId = account2.accountId;

    // Check if account exists
    bool exists = true;
    try {
      await sdk.accounts.account(accountId);
    } on ErrorResponse catch (e) {
      if (e.code == 404) exists = false;
    }

    expect(exists, true);

    AccountResponse account = await sdk.accounts.account(accountId);

    expect(account.sequenceNumber, isNotNull);

    // List balances
    bool foundNativeBalance = false;
    for (Balance balance in account.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        foundNativeBalance = true;
        expect(double.parse(balance.balance), greaterThan(0));
      }
    }
    expect(foundNativeBalance, true);

    // List signers
    expect(account.signers, isNotEmpty);
    for (Signer signer in account.signers) {
      expect(signer.key, isNotNull);
      expect(signer.weight, isNotNull);
    }
  });

  test('getting-started: Builder Pattern', () async {
    // Snippet from getting-started.md "Builder Pattern"
    AccountResponse sourceAccount =
        await sdk.accounts.account(account1.accountId);

    PaymentOperation operation1 = PaymentOperationBuilder(
      account2.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    PaymentOperation operation2 = PaymentOperationBuilder(
      account3.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    Transaction transaction = TransactionBuilder(sourceAccount)
        .addOperation(operation1)
        .addOperation(operation2)
        .addMemo(Memo.text("Payment reference"))
        .setMaxOperationFee(200)
        .build();

    expect(transaction.operations.length, 2);
    expect(transaction.memo, isNotNull);
  });

  test('getting-started: Building Operations', () async {
    // Snippet from getting-started.md "Building Operations"
    AccountResponse sourceAccount =
        await sdk.accounts.account(account2.accountId);

    PaymentOperation paymentOp = PaymentOperationBuilder(
      account3.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    expect(paymentOp, isNotNull);

    // Build a transaction with the payment operation
    Transaction transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

    expect(transaction.operations.length, 1);
  });

  test('getting-started: Signing and Submitting', () async {
    // Snippet from getting-started.md "Signing and Submitting"
    KeyPair sourceKeyPair = account2;

    AccountResponse sourceAccount =
        await sdk.accounts.account(sourceKeyPair.accountId);

    PaymentOperation paymentOp = PaymentOperationBuilder(
      account3.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    Transaction transaction = TransactionBuilder(sourceAccount)
        .addOperation(paymentOp)
        .build();

    transaction.sign(sourceKeyPair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    expect(response.success, true);
    expect(response.hash, isNotNull);
  });

  test('getting-started: Complete Payment Example', () async {
    // Snippet from getting-started.md "Complete Payment Example"
    KeyPair senderKeyPair = account3;
    String destination = account1.accountId;

    AccountResponse senderAccount =
        await sdk.accounts.account(senderKeyPair.accountId);

    PaymentOperation paymentOp =
        PaymentOperationBuilder(destination, Asset.NATIVE, "100").build();

    Transaction transaction = TransactionBuilder(senderAccount)
        .addOperation(paymentOp)
        .addMemo(Memo.text("Coffee payment"))
        .build();

    transaction.sign(senderKeyPair, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    expect(response.success, true);
    expect(response.hash, isNotNull);
  });

  test('getting-started: Connecting to Networks', () {
    // Snippet from getting-started.md "Connecting to Networks"
    StellarSDK testnetSdk = StellarSDK.TESTNET;
    StellarSDK publicSdk = StellarSDK.PUBLIC;
    StellarSDK customSdk = StellarSDK("https://horizon-testnet.stellar.org");

    expect(testnetSdk, isNotNull);
    expect(publicSdk, isNotNull);
    expect(customSdk, isNotNull);
  });

  test('getting-started: Connecting to Soroban RPC', () {
    // Snippet from getting-started.md "Connecting to Soroban RPC"
    SorobanServer server =
        SorobanServer("https://soroban-testnet.stellar.org");
    expect(server, isNotNull);
  });

  test('getting-started: Health Check', () async {
    // Snippet from getting-started.md "Health Check"
    SorobanServer server =
        SorobanServer("https://soroban-testnet.stellar.org");

    GetHealthResponse health = await server.getHealth();

    expect(health.status, GetHealthResponse.HEALTHY);
    expect(health.latestLedger, isNotNull);
    expect(health.oldestLedger, isNotNull);
  });

  test('getting-started: Latest Ledger Info', () async {
    // Snippet from getting-started.md "Latest Ledger Info"
    SorobanServer server =
        SorobanServer("https://soroban-testnet.stellar.org");

    GetLatestLedgerResponse ledger = await server.getLatestLedger();

    expect(ledger.sequence, isNotNull);
    expect(ledger.protocolVersion, isNotNull);
    expect(ledger.sequence, greaterThan(0));
  });

  test('getting-started: Horizon Request Errors', () async {
    // Snippet from getting-started.md "Horizon Request Errors"
    try {
      await sdk.accounts.account("GINVALIDACCOUNTID");
      fail("Should have thrown");
    } on ErrorResponse catch (e) {
      expect(e.code, 400);
      expect(e.body, isNotNull);
    }
  });

  test('getting-started: Transaction Failures', () async {
    // Snippet from getting-started.md "Transaction Failures"
    // Intentionally create a failing transaction (bad destination)
    KeyPair senderKeyPair = account1;
    AccountResponse senderAccount =
        await sdk.accounts.account(senderKeyPair.accountId);

    // Send to a non-existent account to trigger op_no_destination
    KeyPair nonExistent = KeyPair.random();
    PaymentOperation paymentOp = PaymentOperationBuilder(
      nonExistent.accountId,
      Asset.NATIVE,
      "1",
    ).build();

    Transaction transaction = TransactionBuilder(senderAccount)
        .addOperation(paymentOp)
        .build();

    transaction.sign(senderKeyPair, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    expect(response.success, false);

    String? txCode = response.extras?.resultCodes?.transactionResultCode;
    List<String?>? opCodes =
        response.extras?.resultCodes?.operationsResultCodes;

    expect(txCode, isNotNull);
    expect(opCodes, isNotNull);
    expect(opCodes!.first, "op_no_destination");
  });

  test('getting-started: Best Practices - Fee Stats', () async {
    // Snippet from getting-started.md "Best Practices - Set appropriate fees"
    FeeStatsResponse feeStats = await sdk.feeStats.execute();
    String recommendedFee = feeStats.lastLedgerBaseFee;

    expect(int.parse(recommendedFee), greaterThan(0));
  });
}
