@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('test query accounts', () async {
    KeyPair accountKeyPair = KeyPair.random();
    String accountId = accountKeyPair.accountId;
    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);
    Page<AccountResponse> accountsForSigner =
        await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records.first.accountId == accountId);

    List<KeyPair> testKeyPairs = List<KeyPair>();
    for (int i = 0; i < 3; i++) {
      testKeyPairs.add(KeyPair.random());
    }
    // Create an issuer account and a custom asset to test "accounts.forAsset()"
    KeyPair issuerkp = KeyPair.random();
    String issuerAccountId = issuerkp.accountId;

    TransactionBuilder tb = TransactionBuilder(account, Network.TESTNET);

    CreateAccountOperation createAccount =
        CreateAccountOperationBuilder(issuerAccountId, "5").build();
    tb.addOperation(createAccount);

    for (KeyPair keyp in testKeyPairs) {
      createAccount =
          CreateAccountOperationBuilder(keyp.accountId, "5").build();
      tb.addOperation(createAccount);
    }

    Transaction transaction = tb.build();
    transaction.sign(accountKeyPair);
    SubmitTransactionResponse respone =
        await sdk.submitTransaction(transaction);
    assert(respone.success);

    tb = TransactionBuilder(account, Network.TESTNET);
    for (KeyPair keyp in testKeyPairs) {
      tb.addOperation(SetOptionsOperationBuilder()
          .setSourceAccount(keyp.accountId)
          .setSigner(accountKeyPair.xdrSignerKey, 1)
          .build());
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair);
    for (KeyPair keyp in testKeyPairs) {
      transaction.sign(keyp);
    }

    respone = await sdk.submitTransaction(transaction);
    assert(respone.success);
    accountsForSigner = await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records.length == 4);
    accountsForSigner = await sdk.accounts
        .forSigner(accountId)
        .limit(2)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(accountsForSigner.records.length == 2);

    Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);
    tb = TransactionBuilder(account, Network.TESTNET);
    ChangeTrustOperation ct = ChangeTrustOperationBuilder(astroDollar, "20000")
        .setSourceAccount(accountId)
        .build();
    tb.addOperation(ct);
    for (KeyPair keyp in testKeyPairs) {
      ct = ChangeTrustOperationBuilder(astroDollar, "20000")
          .setSourceAccount(keyp.accountId)
          .build();
      tb.addOperation(ct);
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair);
    respone = await sdk.submitTransaction(transaction);
    assert(respone.success);
    Page<AccountResponse> accountsForAsset =
        await sdk.accounts.forAsset(astroDollar).execute();
    assert(accountsForAsset.records.length == 4);
    accountsForAsset = await sdk.accounts
        .forAsset(astroDollar)
        .limit(2)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(accountsForAsset.records.length == 2);
  });

  test('test query assets', () async {
    Page<AssetResponse> assetsPage = await sdk.assets
        .assetCode("USD")
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    List<AssetResponse> assets = assetsPage.records;
    assert(assets.length > 0 && assets.length < 6);
    for (AssetResponse asset in assets) {
      print("asset issuer: " + asset.assetIssuer);
    }
    String assetIssuer = assets.last.assetIssuer;
    assetsPage = await sdk.assets
        .assetIssuer(assetIssuer)
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assets = assetsPage.records;
    assert(assets.length > 0 && assets.length < 6);
    for (AssetResponse asset in assets) {
      print("asset code: " +
          asset.assetCode +
          " amount:${asset.amount} " +
          "num accounts:${asset.numAccounts}");
    }
  });

  test('test query effects', () async {
    Page<AssetResponse> assetsPage = await sdk.assets
        .assetCode("USD")
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    List<AssetResponse> assets = assetsPage.records;
    assert(assets.length > 0 && assets.length < 6);

    String assetIssuer = assets.last.assetIssuer;

    Page<EffectResponse> effectsPage = await sdk.effects
        .forAccount(assetIssuer)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    List<EffectResponse> effects = effectsPage.records;
    assert(effects.length > 0 && effects.length < 4);
    assert(effects.first is AccountCreatedEffectResponse);

    Page<LedgerResponse> ledgersPage =
        await sdk.ledgers.limit(1).order(RequestBuilderOrder.DESC).execute();
    assert(ledgersPage.records.length == 1);
    LedgerResponse ledger = ledgersPage.records.first;
    effectsPage = await sdk.effects
        .forLedger(ledger.sequence)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    effects = effectsPage.records;
    assert(effects.length > 0);

    Page<TransactionResponse> transactionsPage = await sdk.transactions
        .forLedger(ledger.sequence)
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(transactionsPage.records.length == 1);
    TransactionResponse transaction = transactionsPage.records.first;
    effectsPage = await sdk.effects
        .forTransaction(transaction.hash)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    assert(effects.length > 0);

    Page<OperationResponse> operationsPage = await sdk.operations
        .forTransaction(transaction.hash)
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(operationsPage.records.length == 1);
    OperationResponse operation = operationsPage.records.first;
    effectsPage = await sdk.effects
        .forOperation(operation.id)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    assert(effects.length > 0);
  });

  test('test query ledgers', () async {

    Page<LedgerResponse> ledgersPage =
    await sdk.ledgers.limit(1).order(RequestBuilderOrder.DESC).execute();
    assert(ledgersPage.records.length == 1);
    LedgerResponse ledger = ledgersPage.records.first;

    LedgerResponse ledger2 = await sdk.ledgers.ledger(ledger.sequence);
    assert(ledger.sequence == ledger2.sequence);

  });
}
