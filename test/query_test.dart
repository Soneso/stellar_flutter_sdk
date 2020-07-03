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

  test('test query fee stats', () async {
    FeeStatsResponse feeStats = await sdk.feeStats.execute();
    assert(feeStats.lastLedger.isNotEmpty);
    assert(feeStats.lastLedgerBaseFee.isNotEmpty);
    assert(feeStats.lastLedgerCapacityUsage.isNotEmpty);
    assert(feeStats.feeCharged.max.isNotEmpty);
    assert(feeStats.feeCharged.min.isNotEmpty);
    assert(feeStats.feeCharged.mode.isNotEmpty);
    assert(feeStats.feeCharged.p10.isNotEmpty);
    assert(feeStats.feeCharged.p20.isNotEmpty);
    assert(feeStats.feeCharged.p30.isNotEmpty);
    assert(feeStats.feeCharged.p40.isNotEmpty);
    assert(feeStats.feeCharged.p50.isNotEmpty);
    assert(feeStats.feeCharged.p60.isNotEmpty);
    assert(feeStats.feeCharged.p70.isNotEmpty);
    assert(feeStats.feeCharged.p80.isNotEmpty);
    assert(feeStats.feeCharged.p90.isNotEmpty);
    assert(feeStats.feeCharged.p95.isNotEmpty);
    assert(feeStats.feeCharged.p99.isNotEmpty);
    assert(feeStats.maxFee.max.isNotEmpty);
    assert(feeStats.maxFee.min.isNotEmpty);
    assert(feeStats.maxFee.mode.isNotEmpty);
    assert(feeStats.maxFee.p10.isNotEmpty);
    assert(feeStats.maxFee.p20.isNotEmpty);
    assert(feeStats.maxFee.p30.isNotEmpty);
    assert(feeStats.maxFee.p40.isNotEmpty);
    assert(feeStats.maxFee.p50.isNotEmpty);
    assert(feeStats.maxFee.p60.isNotEmpty);
    assert(feeStats.maxFee.p70.isNotEmpty);
    assert(feeStats.maxFee.p80.isNotEmpty);
    assert(feeStats.maxFee.p90.isNotEmpty);
    assert(feeStats.maxFee.p95.isNotEmpty);
    assert(feeStats.maxFee.p99.isNotEmpty);
  });

  test('test query offers and order book', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair buyerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String buyerAccountId = buyerKeipair.accountId;

    await FriendBot.fundTestAccount(buyerAccountId);

    AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
    CreateAccountOperationBuilder caob =
        CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(caob.build())
        .build();
    transaction.sign(buyerKeipair);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    String assetCode = "ASTRO";

    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(astroDollar, "10000");
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ctob.build())
        .build();
    transaction.sign(buyerKeipair);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    String amountBuying = "100";
    String price = "0.5";

    ManageBuyOfferOperation ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .build();
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    transaction.sign(buyerKeipair);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    List<OfferResponse> offers =
        (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    double offerAmount = double.parse(offer.amount);
    double offerPrice = double.parse(offer.price);
    double buyingAmount = double.parse(amountBuying);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    assert(offer.seller.accountId == buyerKeipair.accountId);

    String offerId = offer.id;

    OrderBookResponse orderBook = await sdk.orderBook
        .buyingAsset(astroDollar)
        .sellingAsset(Asset.NATIVE)
        .limit(1)
        .execute();
    offerAmount = double.parse(orderBook.asks.first.amount);
    offerPrice = double.parse(orderBook.asks.first.price);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    Asset base = orderBook.base;
    Asset counter = orderBook.counter;

    assert(base is AssetTypeNative);
    assert(counter is AssetTypeCreditAlphaNum12);

    AssetTypeCreditAlphaNum12 counter12 = counter;
    assert(counter12.code == assetCode);
    assert(counter12.issuerId == issuerAccountId);

    orderBook = await sdk.orderBook
        .buyingAsset(Asset.NATIVE)
        .sellingAsset(astroDollar)
        .limit(1)
        .execute();
    offerAmount = double.parse(orderBook.bids.first.amount);
    offerPrice = double.parse(orderBook.bids.first.price);

    assert((offerAmount * offerPrice).round() == 25);

    base = orderBook.base;
    counter = orderBook.counter;

    assert(counter is AssetTypeNative);
    assert(base is AssetTypeCreditAlphaNum12);

    AssetTypeCreditAlphaNum12 base12 = base;
    assert(base12.code == assetCode);
    assert(base12.issuerId == issuerAccountId);
  });
}
