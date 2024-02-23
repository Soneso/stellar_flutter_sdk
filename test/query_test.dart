@Timeout(const Duration(seconds: 400))
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'tests_util.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('test query accounts', () async {
    KeyPair accountKeyPair = KeyPair.random();
    String accountId = accountKeyPair.accountId;
    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);
    Page<AccountResponse> accountsForSigner = await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records!.first.accountId == accountId);

    List<KeyPair> testKeyPairs = [];
    for (int i = 0; i < 3; i++) {
      testKeyPairs.add(KeyPair.random());
    }
    // Create an issuer account and a custom asset to test "accounts.forAsset()"
    KeyPair issuerkp = KeyPair.random();
    String issuerAccountId = issuerkp.accountId;

    TransactionBuilder tb = TransactionBuilder(account);

    CreateAccountOperation createAccount =
        CreateAccountOperationBuilder(issuerAccountId, "5").build();
    tb.addOperation(createAccount);

    for (KeyPair? keyp in testKeyPairs) {
      createAccount = CreateAccountOperationBuilder(keyp!.accountId, "5").build();
      tb.addOperation(createAccount);
    }

    Transaction transaction = tb.build();
    transaction.sign(accountKeyPair, Network.TESTNET);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    tb = TransactionBuilder(account);
    for (KeyPair keyp in testKeyPairs) {
      tb.addOperation(SetOptionsOperationBuilder()
          .setSourceAccount(keyp.accountId)
          .setSigner(accountKeyPair.xdrSignerKey, 1)
          .build());
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair, Network.TESTNET);
    for (KeyPair keyp in testKeyPairs) {
      transaction.sign(keyp, Network.TESTNET);
    }

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    accountsForSigner = await sdk.accounts.forSigner(accountId).execute();
    assert(accountsForSigner.records!.length == 4);
    accountsForSigner =
        await sdk.accounts.forSigner(accountId).limit(2).order(RequestBuilderOrder.DESC).execute();
    assert(accountsForSigner.records!.length == 2);

    Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);
    tb = TransactionBuilder(account);
    ChangeTrustOperation ct =
        ChangeTrustOperationBuilder(astroDollar, "20000").setSourceAccount(accountId).build();
    tb.addOperation(ct);
    for (KeyPair? keyp in testKeyPairs) {
      ct = ChangeTrustOperationBuilder(astroDollar, "20000")
          .setSourceAccount(keyp!.accountId)
          .build();
      tb.addOperation(ct);
    }
    transaction = tb.build();
    transaction.sign(accountKeyPair, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    Page<AccountResponse> accountsForAsset = await sdk.accounts.forAsset(astroDollar).execute();
    assert(accountsForAsset.records!.length == 4);
    accountsForAsset =
        await sdk.accounts.forAsset(astroDollar).limit(2).order(RequestBuilderOrder.DESC).execute();
    assert(accountsForAsset.records!.length == 2);
  });

  test('test query assets', () async {
    Page<AssetResponse> assetsPage =
        await sdk.assets.assetCode("ASTRO").limit(5).order(RequestBuilderOrder.DESC).execute();
    List<AssetResponse?>? assets = assetsPage.records;

    assert(assets!.length > 0 && assets.length < 6);
    for (AssetResponse? asset in assets!) {
      print("asset issuer: " + asset!.assetIssuer);
    }
    String assetIssuer = assets.last!.assetIssuer;
    assetsPage = await sdk.assets
        .assetIssuer(assetIssuer)
        .limit(5)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assets = assetsPage.records;
    assert(assets!.length > 0 && assets.length < 6);
    for (AssetResponse? asset in assets!) {
      print("asset code: " +
          asset!.assetCode +
          " amount:${asset.amount} " +
          "num accounts:${asset.numAccounts} " +
          "num claimable Balances: ${asset.numClaimableBalances} " +
          " claimable balances amount: ${asset.claimableBalancesAmount}");
      print("accounts-authorized: ${asset.accounts.authorized}");
      print("accounts-authorizedToMaintainLiabilities: "
          "${asset.accounts.authorizedToMaintainLiabilities}");
      print("accounts-unauthorized: ${asset.accounts.unauthorized}");

      print("balances-authorized: ${asset.balances.authorized}");
      print("balances-authorizedToMaintainLiabilities: "
          "${asset.balances.authorizedToMaintainLiabilities}");
      print("balances-unauthorized: ${asset.balances.unauthorized}");
    }
  });

  test('test query effects', () async {
    Page<AssetResponse> assetsPage =
        await sdk.assets.assetCode("USD").limit(5).order(RequestBuilderOrder.DESC).execute();
    List<AssetResponse?>? assets = assetsPage.records;
    assert(assets!.length > 0 && assets.length < 6);

    String assetIssuer = assets!.first!.assetIssuer;

    Page<EffectResponse> effectsPage =
        await sdk.effects.forAccount(assetIssuer).limit(3).order(RequestBuilderOrder.ASC).execute();
    List<EffectResponse> effects = effectsPage.records!;
    assert(effects.length > 0 && effects.length < 4);
    assert(effects.first is AccountCreatedEffectResponse);

    Page<LedgerResponse> ledgersPage =
        await sdk.ledgers.limit(1).order(RequestBuilderOrder.DESC).execute();
    assert(ledgersPage.records!.length == 1);
    LedgerResponse ledger = ledgersPage.records!.first;
    effectsPage = await sdk.effects
        .forLedger(ledger.sequence)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    effects = effectsPage.records!;
    assert(effects.length > 0);

    Page<TransactionResponse> transactionsPage = await sdk.transactions
        .forLedger(ledger.sequence)
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(transactionsPage.records!.length == 1);
    TransactionResponse transaction = transactionsPage.records!.first;
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
    assert(operationsPage.records!.length == 1);
    OperationResponse operation = operationsPage.records!.first;
    effectsPage = await sdk.effects
        .forOperation(operation.id!)
        .limit(3)
        .order(RequestBuilderOrder.ASC)
        .execute();
    assert(effects.length > 0);
  });

  test('test query operations for claimable balance', () async {
    /// ! get Claimable Balance ID from BID result at claimable_balance_test.dart
    Page<OperationResponse> operationsPage = await sdk.operations
        .forClaimableBalance(
            "00000000199478d4131cb6dc67969452425d1df3d575748c2dc8323b7dd87860bbb1daac")
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(operationsPage.records!.length == 1);
    OperationResponse operation = operationsPage.records!.first;
    assert(operation.transactionSuccessful!);
  });

  test('test query transactions for claimable balance', () async {
    /// ! get Claimable Balance ID from BID result at claimable_balance_test.dart
    Page<TransactionResponse> transactionsPage = await sdk.transactions
        .forClaimableBalance(
            "00000000199478d4131cb6dc67969452425d1df3d575748c2dc8323b7dd87860bbb1daac")
        .limit(1)
        .order(RequestBuilderOrder.DESC)
        .execute();
    assert(transactionsPage.records!.length == 1);
  });

  test('test query ledgers', () async {
    Page<LedgerResponse> ledgersPage =
        await sdk.ledgers.limit(1).order(RequestBuilderOrder.DESC).execute();
    assert(ledgersPage.records!.length == 1);
    LedgerResponse ledger = ledgersPage.records!.first;
    // print("tx_set_operation_count: ${ledger.txSetOperationCount}");

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
    CreateAccountOperationBuilder caob = CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(buyerAccount).addOperation(caob.build()).build();
    transaction.sign(buyerKeipair, Network.TESTNET);
    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String assetCode = "ASTRO";

    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    ChangeTrustOperationBuilder ctob = ChangeTrustOperationBuilder(astroDollar, "10000");
    transaction = TransactionBuilder(buyerAccount).addOperation(ctob.build()).build();
    transaction.sign(buyerKeipair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String amountBuying = "100";
    String price = "0.5";

    ManageBuyOfferOperation ms =
        ManageBuyOfferOperationBuilder(Asset.NATIVE, astroDollar, amountBuying, price).build();
    transaction = TransactionBuilder(buyerAccount).addOperation(ms).build();
    transaction.sign(buyerKeipair, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    List<OfferResponse?>? offers = (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers!.length == 1);
    OfferResponse offer = offers!.first!;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    double offerAmount = double.parse(offer.amount);
    double offerPrice = double.parse(offer.price);
    double buyingAmount = double.parse(amountBuying);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    assert(offer.seller == buyerKeipair.accountId);

    offers = (await sdk.offers.forBuyingAsset(astroDollar).execute()).records;
    assert(offers!.length == 1);
    OfferResponse offer2 = offers!.first!;
    assert(offer.id == offer2.id);

    OrderBookResponse orderBook =
        await sdk.orderBook.buyingAsset(astroDollar).sellingAsset(Asset.NATIVE).limit(1).execute();
    offerAmount = double.parse(orderBook.asks.first.amount);
    offerPrice = double.parse(orderBook.asks.first.price);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    Asset? base = orderBook.base;
    Asset? counter = orderBook.counter;

    assert(base is AssetTypeNative);
    assert(counter is AssetTypeCreditAlphaNum12);

    AssetTypeCreditAlphaNum12? counter12 = counter as AssetTypeCreditAlphaNum12;
    assert(counter12.code == assetCode);
    assert(counter12.issuerId == issuerAccountId);

    orderBook =
        await sdk.orderBook.buyingAsset(Asset.NATIVE).sellingAsset(astroDollar).limit(1).execute();
    offerAmount = double.parse(orderBook.bids.first.amount);
    offerPrice = double.parse(orderBook.bids.first.price);

    assert((offerAmount * offerPrice).round() == 25);

    base = orderBook.base;
    counter = orderBook.counter;

    assert(counter is AssetTypeNative);
    assert(base is AssetTypeCreditAlphaNum12);

    AssetTypeCreditAlphaNum12 base12 = base as AssetTypeCreditAlphaNum12;
    assert(base12.code == assetCode);
    assert(base12.issuerId == issuerAccountId);
  });

  test('query: strict send path, strict receive path, trades', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    KeyPair keyPairD = KeyPair.random();
    KeyPair keyPairE = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;
    String accountDId = keyPairD.accountId;
    String accountEId = keyPairE.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10").build())
        .addOperation(new CreateAccountOperationBuilder(accountBId, "10").build())
        .addOperation(new CreateAccountOperationBuilder(accountDId, "10").build())
        .addOperation(new CreateAccountOperationBuilder(accountEId, "10").build())
        .build();
    transaction.sign(keyPairA, Network.TESTNET);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    AccountResponse accountB = await sdk.accounts.account(accountBId);
    AccountResponse accountD = await sdk.accounts.account(accountDId);
    AccountResponse accountE = await sdk.accounts.account(accountEId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);
    Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", keyPairA.accountId);
    Asset moonAsset = AssetTypeCreditAlphaNum4("MOON", keyPairA.accountId);
    ChangeTrustOperationBuilder ctIOMOp = ChangeTrustOperationBuilder(iomAsset, "200999");
    ChangeTrustOperationBuilder ctECOOp = ChangeTrustOperationBuilder(ecoAsset, "200999");
    ChangeTrustOperationBuilder ctMOONOp = ChangeTrustOperationBuilder(moonAsset, "200999");

    transaction = new TransactionBuilder(accountC).addOperation(ctIOMOp.build()).build();
    transaction.sign(keyPairC, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    transaction = new TransactionBuilder(accountB)
        .addOperation(ctIOMOp.build())
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairB, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    transaction = new TransactionBuilder(accountD)
        .addOperation(ctECOOp.build())
        .addOperation(ctMOONOp.build())
        .build();
    transaction.sign(keyPairD, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    transaction = new TransactionBuilder(accountE).addOperation(ctMOONOp.build()).build();
    transaction.sign(keyPairE, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    transaction = new TransactionBuilder(accountA)
        .addOperation(PaymentOperationBuilder(accountCId, iomAsset, "100").build())
        .addOperation(PaymentOperationBuilder(accountBId, iomAsset, "100").build())
        .addOperation(PaymentOperationBuilder(accountBId, ecoAsset, "100").build())
        .addOperation(PaymentOperationBuilder(accountDId, moonAsset, "100").build())
        .build();
    transaction.sign(keyPairA, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    ManageSellOfferOperation sellOfferOp =
        ManageSellOfferOperationBuilder(ecoAsset, iomAsset, "100", "0.5").build();
    transaction = new TransactionBuilder(accountB).addOperation(sellOfferOp).build();
    transaction.sign(keyPairB, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    sellOfferOp = ManageSellOfferOperationBuilder(moonAsset, ecoAsset, "100", "0.5").build();
    transaction = new TransactionBuilder(accountD).addOperation(sellOfferOp).build();
    transaction.sign(keyPairD, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    bool exceptionThrown = false;
    List<Asset> destinationAssets = [moonAsset];
    try {
      await sdk.strictSendPaths
          .sourceAsset(iomAsset)
          .sourceAmount("10")
          .destinationAccount(accountEId)
          .destinationAssets(destinationAssets)
          .execute();
    } catch (exception) {
      exceptionThrown = true;
    }
    assert(exceptionThrown);

    await Future.delayed(const Duration(seconds: 3), () {});

    Page<PathResponse> strictSendPaths = await sdk.strictSendPaths
        .sourceAsset(iomAsset)
        .sourceAmount("10")
        .destinationAccount(accountEId)
        .execute();
    assert(strictSendPaths.records!.length > 0);

    PathResponse pathResponse = strictSendPaths.records!.first;
    assert(double.parse(pathResponse.destinationAmount) == 40);
    assert(pathResponse.destinationAssetType == "credit_alphanum4");
    assert(pathResponse.destinationAssetCode == "MOON");
    assert(pathResponse.destinationAssetIssuer == accountAId);

    assert(double.parse(pathResponse.sourceAmount) == 10);
    assert(pathResponse.sourceAssetType == "credit_alphanum4");
    assert(pathResponse.sourceAssetCode == "IOM");
    assert(pathResponse.sourceAssetIssuer == accountAId);

    assert(pathResponse.path.length > 0);
    Asset? pathAsset = pathResponse.path.first;
    assert(pathAsset == ecoAsset);

    strictSendPaths = await sdk.strictSendPaths
        .sourceAsset(iomAsset)
        .sourceAmount("10")
        .destinationAssets(destinationAssets)
        .execute();
    assert(strictSendPaths.records!.length > 0);

    pathResponse = strictSendPaths.records!.first;
    assert(double.parse(pathResponse.destinationAmount) == 40);
    assert(pathResponse.destinationAssetType == "credit_alphanum4");
    assert(pathResponse.destinationAssetCode == "MOON");
    assert(pathResponse.destinationAssetIssuer == accountAId);

    assert(double.parse(pathResponse.sourceAmount) == 10);
    assert(pathResponse.sourceAssetType == "credit_alphanum4");
    assert(pathResponse.sourceAssetCode == "IOM");
    assert(pathResponse.sourceAssetIssuer == accountAId);

    assert(pathResponse.path.length > 0);
    pathAsset = pathResponse.path.first;
    assert(pathAsset == ecoAsset);

    List<Asset> path = pathResponse.path;

    PathPaymentStrictSendOperation strictSend =
        PathPaymentStrictSendOperationBuilder(iomAsset, "10", accountEId, moonAsset, "38")
            .setPath(path)
            .build();
    transaction = new TransactionBuilder(accountC).addOperation(strictSend).build();
    transaction.sign(keyPairC, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    bool found = false;
    accountE = await sdk.accounts.account(accountEId);
    for (Balance balance in accountE.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == "MOON") {
        assert(double.parse(balance.balance) > 39);
        found = true;
        break;
      }
    }
    assert(found);

    bool tradeExecuted = false;
    // Stream trades.
    var subscription = sdk.trades.forAccount(accountBId).cursor("now").stream().listen((response) {
      tradeExecuted = true;
      assert(response.baseAccount == accountBId);
    });

    exceptionThrown = false;
    List<Asset> sourceAssets = [iomAsset];
    try {
      await sdk.strictReceivePaths
          .destinationAsset(moonAsset)
          .destinationAmount("8")
          .sourceAssets(sourceAssets)
          .sourceAccount(accountCId)
          .execute();
    } catch (exception) {
      exceptionThrown = true;
    }
    assert(exceptionThrown);

    Page<PathResponse> strictReceivePaths = await sdk.strictReceivePaths
        .destinationAsset(moonAsset)
        .destinationAmount("8")
        .sourceAssets(sourceAssets)
        .execute();
    assert(strictReceivePaths.records!.length > 0);

    pathResponse = strictReceivePaths.records!.first;
    assert(double.parse(pathResponse.destinationAmount) == 8);
    assert(pathResponse.destinationAssetType == "credit_alphanum4");
    assert(pathResponse.destinationAssetCode == "MOON");
    assert(pathResponse.destinationAssetIssuer == accountAId);

    assert(double.parse(pathResponse.sourceAmount) == 2);
    assert(pathResponse.sourceAssetType == "credit_alphanum4");
    assert(pathResponse.sourceAssetCode == "IOM");
    assert(pathResponse.sourceAssetIssuer == accountAId);

    assert(pathResponse.path.length > 0);
    pathAsset = pathResponse.path.first;
    assert(pathAsset == ecoAsset);

    strictReceivePaths = await sdk.strictReceivePaths
        .destinationAsset(moonAsset)
        .destinationAmount("8")
        .sourceAccount(accountCId)
        .execute();
    assert(strictReceivePaths.records!.length > 0);

    pathResponse = strictReceivePaths.records!.first;
    assert(double.parse(pathResponse.destinationAmount) == 8);
    assert(pathResponse.destinationAssetType == "credit_alphanum4");
    assert(pathResponse.destinationAssetCode == "MOON");
    assert(pathResponse.destinationAssetIssuer == accountAId);

    assert(double.parse(pathResponse.sourceAmount) == 2);
    assert(pathResponse.sourceAssetType == "credit_alphanum4");
    assert(pathResponse.sourceAssetCode == "IOM");
    assert(pathResponse.sourceAssetIssuer == accountAId);

    assert(pathResponse.path.length > 0);
    pathAsset = pathResponse.path.first;
    assert(pathAsset == ecoAsset);

    path = pathResponse.path;

    PathPaymentStrictReceiveOperation strictReceive =
        PathPaymentStrictReceiveOperationBuilder(iomAsset, "2", accountEId, moonAsset, "8")
            .setPath(path)
            .build();
    transaction = new TransactionBuilder(accountC).addOperation(strictReceive).build();
    transaction.sign(keyPairC, Network.TESTNET);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    found = false;
    accountE = await sdk.accounts.account(accountEId);
    for (Balance balance in accountE.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == "MOON") {
        assert(double.parse(balance.balance) > 47);
        found = true;
        break;
      }
    }
    assert(found);

    Page<TradeResponse> trades = await sdk.trades.forAccount(accountBId).execute();
    assert(trades.records!.length == 2);
    TradeResponse trade = trades.records!.first;

    assert(trade.baseIsSeller);
    assert(trade.baseAccount == accountBId);
    assert(double.parse(trade.baseAmount) == 20);
    assert(trade.baseAssetType == "credit_alphanum4");
    assert(trade.baseAssetCode == "ECO");
    assert(trade.baseAssetIssuer == accountAId);

    assert(trade.counterAccount == accountCId);
    assert(trade.counterOfferId != null);
    assert(double.parse(trade.counterAmount) == 10);
    assert(trade.counterAssetType == "credit_alphanum4");
    assert(trade.counterAssetCode == "IOM");
    assert(trade.counterAssetIssuer == accountAId);
    assert(trade.price.numerator == 1);
    assert(trade.price.denominator == 2);

    trade = trades.records!.last;

    assert(trade.baseIsSeller);
    assert(trade.baseAccount == accountBId);
    assert(double.parse(trade.baseAmount) == 4);
    assert(trade.baseAssetType == "credit_alphanum4");
    assert(trade.baseAssetCode == "ECO");
    assert(trade.baseAssetIssuer == accountAId);

    assert(trade.counterAccount == accountCId);
    assert(trade.counterOfferId != null);
    assert(double.parse(trade.counterAmount) == 2);
    assert(trade.counterAssetType == "credit_alphanum4");
    assert(trade.counterAssetCode == "IOM");
    assert(trade.counterAssetIssuer == accountAId);
    assert(trade.price.numerator == 1);
    assert(trade.price.denominator == 2);

    // wait 3 seconds for the trades event.
    await Future.delayed(const Duration(seconds: 10), () {});
    subscription.cancel();
    assert(tradeExecuted);
  });

  test('test query root', () async {
    RootResponse root = await sdk.root();
    assert(root.supportedProtocolVersion > 10);
  });
}
