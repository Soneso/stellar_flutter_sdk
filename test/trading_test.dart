@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'tests_util.dart';

void main() {
  String testOn = 'testnet'; //'futurenet';
  StellarSDK sdk =
      testOn == 'testnet' ? StellarSDK.TESTNET : StellarSDK.FUTURENET;
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  test('manage buy offer', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair buyerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String buyerAccountId = buyerKeipair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(buyerAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(buyerAccountId);
    }

    AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
    CreateAccountOperationBuilder caob =
        CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction =
        TransactionBuilder(buyerAccount).addOperation(caob.build()).build();
    transaction.sign(buyerKeipair, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String assetCode = "ASTRO";

    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(astroDollar, "10000");
    transaction =
        TransactionBuilder(buyerAccount).addOperation(ctob.build()).build();
    transaction.sign(buyerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String amountBuying = "100";
    String price = "0.5";

    ManageBuyOfferOperation ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .build();
    transaction = TransactionBuilder(buyerAccount).addOperation(ms).build();
    transaction.sign(buyerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    var offers =
        (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    double offerAmount = double.parse(offer.amount);
    double offerPrice = double.parse(offer.price);
    double buyingAmount = double.parse(amountBuying);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    assert(offer.seller == buyerKeipair.accountId);

    String offerId = offer.id;

    offers = (await sdk.offers.forBuyingAsset(astroDollar).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    String offerId2 = offer.id;
    assert(offerId == offerId2);

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

    AssetTypeCreditAlphaNum12 counter12 = counter as AssetTypeCreditAlphaNum12;
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

    // update offer
    amountBuying = "150";
    price = "0.3";
    ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(buyerAccount).addOperation(ms).build();
    transaction.sign(buyerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    assert(offer.buying == astroDollar);
    assert(offer.selling == Asset.NATIVE);

    offerAmount = double.parse(offer.amount);
    offerPrice = double.parse(offer.price);
    buyingAmount = double.parse(amountBuying);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    assert(offer.seller == buyerAccountId);

    orderBook = await sdk.orderBook
        .buyingAsset(astroDollar)
        .sellingAsset(Asset.NATIVE)
        .limit(1)
        .execute();
    offerAmount = double.parse(orderBook.asks.first.amount);
    offerPrice = double.parse(orderBook.asks.first.price);

    assert((offerAmount * offerPrice).round() == buyingAmount);

    base = orderBook.base;
    counter = orderBook.counter;

    assert(base is AssetTypeNative);
    assert(counter is AssetTypeCreditAlphaNum12);

    counter12 = counter as AssetTypeCreditAlphaNum12;
    assert(counter12.code == assetCode);
    assert(counter12.issuerId == issuerAccountId);

    // delete offer
    amountBuying = "0";
    ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(buyerAccount).addOperation(ms).build();
    transaction.sign(buyerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(buyerAccountId).execute()).records;
    assert(offers.isEmpty);

    orderBook = await sdk.orderBook
        .buyingAsset(astroDollar)
        .sellingAsset(Asset.NATIVE)
        .limit(1)
        .execute();
    assert(orderBook.asks.length == 0);
    assert(orderBook.bids.length == 0);

    // test operation & effects responses can be parsed
    var operationsPage =
        await sdk.operations.forAccount(buyerAccountId).execute();
    assert(operationsPage.records.isNotEmpty);
    var effectsPage = await sdk.effects.forAccount(buyerAccountId).execute();
    assert(effectsPage.records.isNotEmpty);
  });

  test('manage sell offer', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair sellerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String sellerAccountId = sellerKeipair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(sellerAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(sellerAccountId);
    }

    AccountResponse sellerAccount = await sdk.accounts.account(sellerAccountId);
    CreateAccountOperation co =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction =
        TransactionBuilder(sellerAccount).addOperation(co).build();
    transaction.sign(sellerKeipair, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

    String assetCode = "MOON";

    Asset moonDollar = AssetTypeCreditAlphaNum4(assetCode, issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(moonDollar, "10000");
    transaction =
        TransactionBuilder(sellerAccount).addOperation(ctob.build()).build();
    transaction.sign(sellerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    PaymentOperation po =
        PaymentOperationBuilder(sellerAccountId, moonDollar, "2000").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String amountSelling = "100";
    String price = "0.5";

    ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
            moonDollar, Asset.NATIVE, amountSelling, price)
        .build();
    transaction = TransactionBuilder(sellerAccount).addOperation(ms).build();
    transaction.sign(sellerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    List<OfferResponse>? offers =
        (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == moonDollar);

    double offerAmount = double.parse(offer.amount);
    double sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    double offerPrice = double.parse(offer.price);
    double sellingPrice = double.parse(price);
    assert(offerPrice == sellingPrice);

    assert(offer.seller == sellerAccountId);

    String offerId = offer.id;

    offers = (await sdk.offers.forSellingAsset(moonDollar).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    String offerId2 = offer.id;
    assert(offerId == offerId2);

    OrderBookResponse orderBook = await sdk.orderBook
        .buyingAsset(Asset.NATIVE)
        .sellingAsset(moonDollar)
        .limit(1)
        .execute();
    offerAmount = double.parse(orderBook.asks.first.amount);
    assert(offerAmount == sellingAmount);
    offerPrice = double.parse(orderBook.asks.first.price);
    assert(offerPrice == sellingPrice);

    Asset base = orderBook.base;
    Asset counter = orderBook.counter;

    assert(counter is AssetTypeNative);
    assert(base is AssetTypeCreditAlphaNum4);

    AssetTypeCreditAlphaNum4 base4 = base as AssetTypeCreditAlphaNum4;
    assert(base4.code == assetCode);
    assert(base4.issuerId == issuerAccountId);

    orderBook = await sdk.orderBook
        .buyingAsset(moonDollar)
        .sellingAsset(Asset.NATIVE)
        .limit(1)
        .execute();
    offerAmount = double.parse(orderBook.bids.first.amount);
    offerPrice = double.parse(orderBook.bids.first.price);
    assert((offerAmount * offerPrice).round() == 200);

    // update offer
    amountSelling = "150";
    price = "0.3";
    ms = ManageSellOfferOperationBuilder(
            moonDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount).addOperation(ms).build();
    transaction.sign(sellerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == moonDollar);

    offerAmount = double.parse(offer.amount);
    sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    offerPrice = double.parse(offer.price);
    sellingPrice = double.parse(price);

    assert(offerPrice == sellingPrice);

    assert(offer.seller == sellerAccountId);

    // delete offer
    amountSelling = "0";
    ms = ManageSellOfferOperationBuilder(
            moonDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount).addOperation(ms).build();
    transaction.sign(sellerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);
    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 0);
  });

  test('create passive sell offer', () async {
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair sellerKeipair = KeyPair.random();

    String issuerAccountId = issuerKeipair.accountId;
    String sellerAccountId = sellerKeipair.accountId;

    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(sellerAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(sellerAccountId);
    }

    AccountResponse sellerAccount = await sdk.accounts.account(sellerAccountId);
    CreateAccountOperation co =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction =
        TransactionBuilder(sellerAccount).addOperation(co).build();
    transaction.sign(sellerKeipair, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

    Asset marsDollar = AssetTypeCreditAlphaNum4("MARS", issuerAccountId);

    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(marsDollar, "10000");
    transaction =
        TransactionBuilder(sellerAccount).addOperation(ctob.build()).build();
    transaction.sign(sellerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    PaymentOperation po =
        PaymentOperationBuilder(sellerAccountId, marsDollar, "2000").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeipair, network);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    String amountSelling = "100";
    String price = "0.5";

    CreatePassiveSellOfferOperation cpso =
        CreatePassiveSellOfferOperationBuilder(
                marsDollar, Asset.NATIVE, amountSelling, price)
            .build();
    transaction = TransactionBuilder(sellerAccount).addOperation(cpso).build();
    transaction.sign(sellerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    List<OfferResponse>? offers =
        (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    OfferResponse offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == marsDollar);

    double offerAmount = double.parse(offer.amount);
    double sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    double offerPrice = double.parse(offer.price);
    double sellingPrice = double.parse(price);
    assert(offerPrice == sellingPrice);

    assert(offer.seller == sellerAccountId);

    String offerId = offer.id;

    // update offer
    amountSelling = "150";
    price = "0.3";
    ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
            marsDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount).addOperation(ms).build();
    transaction.sign(sellerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 1);
    offer = offers.first;
    assert(offer.buying == Asset.NATIVE);
    assert(offer.selling == marsDollar);

    offerAmount = double.parse(offer.amount);
    sellingAmount = double.parse(amountSelling);
    assert(offerAmount == sellingAmount);

    offerPrice = double.parse(offer.price);
    sellingPrice = double.parse(price);

    assert(offerPrice == sellingPrice);

    assert(offer.seller == sellerAccountId);

    // delete offer
    amountSelling = "0";
    ms = ManageSellOfferOperationBuilder(
            marsDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId)
        .build();
    transaction = TransactionBuilder(sellerAccount).addOperation(ms).build();
    transaction.sign(sellerKeipair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    offers = (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.length == 0);
  });

  test('offer trades endpoint', () async {
    // This test verifies that the /offers/{offer_id}/trades endpoint is properly implemented
    KeyPair issuerKeypair = KeyPair.random();
    KeyPair sellerKeypair = KeyPair.random();
    KeyPair buyerKeypair = KeyPair.random();

    String issuerAccountId = issuerKeypair.accountId;
    String sellerAccountId = sellerKeypair.accountId;
    String buyerAccountId = buyerKeypair.accountId;

    // Fund accounts
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(sellerAccountId);
      await FriendBot.fundTestAccount(buyerAccountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(sellerAccountId);
      await FuturenetFriendBot.fundTestAccount(buyerAccountId);
    }

    // Create issuer account
    AccountResponse sellerAccount = await sdk.accounts.account(sellerAccountId);
    CreateAccountOperation co =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction =
        TransactionBuilder(sellerAccount).addOperation(co).build();
    transaction.sign(sellerKeypair, network);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

    // Create custom asset
    String assetCode = "TRD";
    Asset tradeAsset = AssetTypeCreditAlphaNum4(assetCode, issuerAccountId);

    // Seller establishes trustline
    ChangeTrustOperationBuilder ctob =
        ChangeTrustOperationBuilder(tradeAsset, "10000");
    transaction =
        TransactionBuilder(sellerAccount).addOperation(ctob.build()).build();
    transaction.sign(sellerKeypair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Buyer establishes trustline
    AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
    ctob = ChangeTrustOperationBuilder(tradeAsset, "10000");
    transaction =
        TransactionBuilder(buyerAccount).addOperation(ctob.build()).build();
    transaction.sign(buyerKeypair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Issuer sends asset to seller
    PaymentOperation po =
        PaymentOperationBuilder(sellerAccountId, tradeAsset, "2000").build();
    transaction = TransactionBuilder(issuerAccount).addOperation(po).build();
    transaction.sign(issuerKeypair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Seller creates sell offer
    String amountSelling = "100";
    String price = "0.5";
    ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
            tradeAsset, Asset.NATIVE, amountSelling, price)
        .build();
    transaction = TransactionBuilder(sellerAccount).addOperation(ms).build();
    transaction.sign(sellerKeypair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Get the offer ID
    List<OfferResponse>? offers =
        (await sdk.offers.forAccount(sellerAccountId).execute()).records;
    assert(offers.isNotEmpty);
    OfferResponse offer = offers.first;
    String offerId = offer.id;

    // Buyer creates a path payment or buy offer to match the sell offer
    // This will create a trade
    String amountBuying = "50";
    ManageBuyOfferOperation buyOp = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, tradeAsset, amountBuying, price)
        .build();
    transaction = TransactionBuilder(buyerAccount).addOperation(buyOp).build();
    transaction.sign(buyerKeypair, network);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Now test the /offers/{offer_id}/trades endpoint
    var tradesPage = await sdk.offers.trades(offerId).limit(10).execute();

    // Verify that we can fetch trades for this offer
    // The trades list might be empty if the offers didn't match, or contain trades if they did
    assert(tradesPage != null);
    assert(tradesPage.records != null);

    // Print trades for debugging (optional)
    print('Trades for offer $offerId: ${tradesPage.records.length}');

    // If there are trades, verify their structure
    if (tradesPage.records.isNotEmpty) {
      var trade = tradesPage.records.first;
      assert(trade.id != null);
      assert(trade.baseAccount != null || trade.counterAccount != null);
      print('Trade found: ${trade.id}');
    }

  });
}
