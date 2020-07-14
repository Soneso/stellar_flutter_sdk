@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';
import 'dart:async';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  setUp(() async {});

  test('../examples/send_native_payment.md', () async {
    KeyPair senderKeyPair = KeyPair.fromSecretSeed(
        "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");
    String destination =
        "GDXPJR65A6EXW7ZIWWIQPO6RKTPG3T2VWFBS3EAHJZNFW6ZXG3VWTTSK";

    // Load sender account data from the stellar network.
    AccountResponse sender =
        await sdk.accounts.account(senderKeyPair.accountId);

    // send 100 XLM native payment from A to destination
    Transaction transaction = new TransactionBuilder(sender, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(destination, Asset.NATIVE, "100").build())
        .build();

    // Sign the transaction with the senders key pair.
    transaction.sign(senderKeyPair);

    // Submit the transaction to the stellar network.
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    if (response.success) {
      print("Payment sent");
    } else {
      assert(false);
    }
  });

  test('create trustline', () async {
    // First we create the trustor key pair from the seed of the trustor so that we can use it to sign the transaction.
    KeyPair trustorKeyPair = KeyPair.fromSecretSeed(
        "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");

    // Account Id of the trustor account.
    String trustorAccountId = trustorKeyPair.accountId;

    // Load the trustor's account details including its current sequence number.
    AccountResponse trustor = await sdk.accounts.account(trustorAccountId);

    // Account Id of the issuer of our custom token "IOM".
    String issuerAccountId =
        "GBGAKKFVRQJCXDLYANAMK4H2D4UHY4FARMGJXPSLGVVW3DQLYODFIKZ2";

    // Define our custom token/asset "IOM" issued by the upper issuer account.
    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccountId);

    // Prepare the change trust operation to trust the IOM asset/token defined above.
    // We limit the trusted/credit amount to 30.000.
    ChangeTrustOperationBuilder changeTrustOperation =
        ChangeTrustOperationBuilder(iomAsset, "300000");

    // Build the transaction.
    Transaction transaction = new TransactionBuilder(trustor, Network.TESTNET)
        .addOperation(changeTrustOperation.build())
        .build();

    // The trustor signs the transaction.
    transaction.sign(trustorKeyPair);

    // Submit the transaction.
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    if (!response.success) {
      print("something went wrong.");
      assert(false);
    }

    // Now we can send 1000 IOM from the issuer to the trustor.

    // First we create the issuer account key pair from it's seed so that we can use it to sign the transaction.
    KeyPair issuerKeyPair = KeyPair.fromSecretSeed(
        "SA75FA55DXG7EN22ZYT6E42ZQBY3TUFF6MHDGG7R6ZEDMNGQ3EVSO3VZ");

    // Load the issuer's account details including its current sequence number.
    AccountResponse issuer = await sdk.accounts.account(issuerAccountId);

    // Send 1000 IOM non native payment from the issuer to the trustor
    transaction = new TransactionBuilder(issuer, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(trustorAccountId, iomAsset, "1000").build())
        .build();

    // The issuer signs the transaction.
    transaction.sign(issuerKeyPair);

    // Submit the transaction to the stellar network.
    response = await sdk.submitTransaction(transaction);

    if (!response.success) {
      print("something went wrong.");
      assert(false);
    }

    // (info) check the trustor account data to see if the trustor received the payment.
    trustor = await sdk.accounts.account(trustorAccountId);
    for (Balance balance in trustor.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "IOM" &&
          double.parse(balance.balance) > 90) {
        print("trustor received IOM payment");
        break;
      }
    }
  });

  test('send non native payment', () async {
    // Create the key pairs of issuer, sender and receiver from their secret seeds. We will need them for signing.
    KeyPair issuerKeyPair = KeyPair.fromSecretSeed(
        "SCLDSWDUG2WBTMP7DP5WCCTCDTNZJLLG5VCZPMJH4DLM6EQ7LSBH7FRV");
    KeyPair senderKeyPair = KeyPair.fromSecretSeed(
        "SAIGGXY7NRL5NQURHUTIBBIK5DCKEHX4MJ5QRD64IQIGLLYANR5INXBW");
    KeyPair receiverKeyPair = KeyPair.fromSecretSeed(
        "SA4ZEDTFV4KQ5A3YGYGGKMTTX4HFJWHOPIMSVOLJF6BIMDWJXAGZ4DQJ");

    // Account Ids.
    String issuerAccountId = issuerKeyPair.accountId;
    String senderAccountId = senderKeyPair.accountId;
    String receiverAccountId = receiverKeyPair.accountId;

    // Define the custom asset/token issued by the issuer account.
    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccountId);

    // Prepare a change trust operation so that we can create trustlines for both, the sender and receiver
    // Both need to trust the IOM asset issued by the issuer account so that they can hold the token/asset.
    // Trust limit is 10000.
    ChangeTrustOperationBuilder chOp =
        ChangeTrustOperationBuilder(iomAsset, "10000");

    // Load the sender account data from the stellar network so that we have the current sequence number.
    AccountResponse sender = await sdk.accounts.account(senderAccountId);

    // Build the transaction for the trustline (sender trusts custom asset).
    Transaction transaction = new TransactionBuilder(sender, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    // The sender signs the transaction.
    transaction.sign(senderKeyPair);

    // Submit the transaction to stellar.
    await sdk.submitTransaction(transaction);

    // Load the receiver account so that we have the current sequence number.
    AccountResponse receiver = await sdk.accounts.account(receiverAccountId);

    // Build the transaction for the trustline (receiver trusts custom asset).
    transaction = new TransactionBuilder(receiver, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    // The receiver signs the transaction.
    transaction.sign(receiverKeyPair);

    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // Load the issuer account so that we have it's current sequence number.
    AccountResponse issuer = await sdk.accounts.account(issuerAccountId);

    // Send 500 IOM non native payment from issuer to sender.
    transaction = new TransactionBuilder(issuer, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(receiverAccountId, iomAsset, "500").build())
        .build();

    // The issuer signs the transaction.
    transaction.sign(issuerKeyPair);

    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // The sender now has 500 IOM and can send to the receiver.
    // Send 200 IOM (non native payment) from sender to receiver
    transaction = new TransactionBuilder(sender, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(receiverAccountId, iomAsset, "200").build())
        .build();

    // The sender signs the transaction.
    transaction.sign(senderKeyPair);

    // Submit the transaction to stellar.
    await sdk.submitTransaction(transaction);

    // Check that the receiver obtained the 200 IOM.
    receiver = await sdk.accounts.account(receiverAccountId);
    for (Balance balance in receiver.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "IOM" &&
          double.parse(balance.balance) > 199) {
        print("received IOM payment");
        break;
      }
    }
  });

  test('path payment strict send and strict receive', () async {
    // Prepare new random key pairs, we will need them for signing.
    KeyPair issuerKeyPair = KeyPair.random();
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair firstMiddlemanKeyPair = KeyPair.random();
    KeyPair secondMiddlemanKeyPair = KeyPair.random();
    KeyPair receiverKeyPair = KeyPair.random();

    // Account Ids.
    String issuerAccoutId = issuerKeyPair.accountId;
    String senderAccountId = senderKeyPair.accountId;
    String firstMiddlemanAccountId = firstMiddlemanKeyPair.accountId;
    String secondMiddlemanAccountId = secondMiddlemanKeyPair.accountId;
    String receiverAccountId = receiverKeyPair.accountId;

    // Fund the issuer account.
    await FriendBot.fundTestAccount(issuerAccoutId);

    // Load the issuer account so that we have it's current sequence number.
    AccountResponse issuer = await sdk.accounts.account(issuerAccoutId);

    // Fund sender, middleman and receiver from our issuer account.
    // Create the accounts for our example.
    Transaction transaction = new TransactionBuilder(issuer, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(senderAccountId, "10").build())
        .addOperation(
            new CreateAccountOperationBuilder(firstMiddlemanAccountId, "10")
                .build())
        .addOperation(
            new CreateAccountOperationBuilder(secondMiddlemanAccountId, "10")
                .build())
        .addOperation(
            new CreateAccountOperationBuilder(receiverAccountId, "10").build())
        .build();

    // Sign the transaction.
    transaction.sign(issuerKeyPair);

    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // Load the data of the accounts so that we can create the trustlines in the next step.
    AccountResponse sender = await sdk.accounts.account(senderAccountId);
    AccountResponse firstMiddleman =
        await sdk.accounts.account(firstMiddlemanAccountId);
    AccountResponse secondMiddleman =
        await sdk.accounts.account(secondMiddlemanAccountId);
    AccountResponse receiver = await sdk.accounts.account(receiverAccountId);

    // Define our custom tokens.
    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccoutId);
    Asset moonAsset = AssetTypeCreditAlphaNum4("MOON", issuerAccoutId);
    Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", issuerAccoutId);

    // Let the sender trust IOM.
    ChangeTrustOperationBuilder ctIOMOp =
        ChangeTrustOperationBuilder(iomAsset, "200999");

    // Build the transaction.
    transaction = new TransactionBuilder(sender, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .build();

    // Sign the transaction.
    transaction.sign(senderKeyPair);

    // Submit the transaction to stellar.
    await sdk.submitTransaction(transaction);

    // Let the first middleman trust both IOM and MOON.
    ChangeTrustOperationBuilder ctMOONOp =
        ChangeTrustOperationBuilder(moonAsset, "200999");

    // Build the transaction.
    transaction = new TransactionBuilder(firstMiddleman, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .addOperation(ctMOONOp.build())
        .build();

    // Sign the transaction.
    transaction.sign(firstMiddlemanKeyPair);

    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // Let the second middleman trust both MOON and ECO.
    ChangeTrustOperationBuilder ctECOOp =
        ChangeTrustOperationBuilder(ecoAsset, "200999");

    // Build the transaction.
    transaction = new TransactionBuilder(secondMiddleman, Network.TESTNET)
        .addOperation(ctMOONOp.build())
        .addOperation(ctECOOp.build())
        .build();

    // Sign the transaction.
    transaction.sign(secondMiddlemanKeyPair);

    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // Let the receiver trust ECO.
    transaction = new TransactionBuilder(receiver, Network.TESTNET)
        .addOperation(ctECOOp.build())
        .build();

    // Sign.
    transaction.sign(receiverKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Now send assets to the accounts from the issuer, so that we can start our case.
    // Send 100 IOM to sender.
    // Send 100 MOON to first middleman.
    // Send 100 ECO to second middleman.
    transaction = new TransactionBuilder(issuer, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(senderAccountId, iomAsset, "100").build())
        .addOperation(
            PaymentOperationBuilder(firstMiddlemanAccountId, moonAsset, "100")
                .build())
        .addOperation(
            PaymentOperationBuilder(secondMiddlemanAccountId, ecoAsset, "100")
                .build())
        .build();

    // Sign.
    transaction.sign(issuerKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Now let the first middleman offer MOON for IOM: 1 IOM = 2 MOON. Offered Amount: 100 MOON.
    ManageSellOfferOperation sellOfferOp =
        ManageSellOfferOperation(moonAsset, iomAsset, "100", "0.5", "0");

    // Build the transaction.
    transaction = new TransactionBuilder(firstMiddleman, Network.TESTNET)
        .addOperation(sellOfferOp)
        .build();

    // Sign.
    transaction.sign(firstMiddlemanKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Now let the second middleman offer ECO for MOON: 1 MOON = 2 ECO. Offered Amount: 100 ECO.
    sellOfferOp =
        ManageSellOfferOperation(ecoAsset, moonAsset, "100", "0.5", "0");

    // Build the transaction.
    transaction = new TransactionBuilder(secondMiddleman, Network.TESTNET)
        .addOperation(sellOfferOp)
        .build();

    // Sign.
    transaction.sign(secondMiddlemanKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // In this example we are going to wait a couple of seconds to be sure that the ledger closed and the offers are available.
    // In your app you should stream for the offers and continue as soon as they are available.
    await Future.delayed(const Duration(seconds: 5), () {});

    // Everything is prepared now. We can use path payment to send IOM but receive ECO.
    // We will need to provide the path, so lets request/find it first
    Page<PathResponse> strictSendPaths = await sdk.strictSendPaths
        .sourceAsset(iomAsset)
        .sourceAmount("10")
        .destinationAssets([ecoAsset]).execute();

    // Here is our payment path.
    List<Asset> path = strictSendPaths.records.first.path;

    // First path payment strict send. Send exactly 10 IOM, receive minimum 38 ECO (it will be 40).
    PathPaymentStrictSendOperation strictSend =
        PathPaymentStrictSendOperationBuilder(
                iomAsset, "10", receiverAccountId, ecoAsset, "38")
            .setPath(path)
            .build();

    // Build the transaction.
    transaction = new TransactionBuilder(sender, Network.TESTNET)
        .addOperation(strictSend)
        .build();

    //Sign.
    transaction.sign(senderKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Check if the receiver received the ECOs.
    receiver = await sdk.accounts.account(receiverAccountId);
    for (Balance balance in receiver.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        print("Receiver received ${double.parse(balance.balance)} ECO");
        break;
      }
    }

    // And now a path payment strict receive.
    // Find the path.
    // We want the receiver to receive exactly 8 ECO.
    Page<PathResponse> strictReceivePaths = await sdk.strictReceivePaths
        .destinationAsset(ecoAsset)
        .destinationAmount("8")
        .sourceAccount(senderAccountId)
        .execute();

    // Here is our payment path.
    path = strictReceivePaths.records.first.path;

    // The sender sends max 2 IOM.
    PathPaymentStrictReceiveOperation strictReceive =
        PathPaymentStrictReceiveOperationBuilder(
                iomAsset, "2", receiverAccountId, ecoAsset, "8")
            .setPath(path)
            .build();

    // Build the transaction.
    transaction = new TransactionBuilder(sender, Network.TESTNET)
        .addOperation(strictReceive)
        .build();

    // Sign.
    transaction.sign(senderKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Check id the reciver received the ECOs.
    receiver = await sdk.accounts.account(receiverAccountId);
    for (Balance balance in receiver.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE &&
          balance.assetCode == "ECO") {
        print("Receiver has ${double.parse(balance.balance)} ECO");
        break;
      }
    }
    print("Success! :)");
  });

  test('friendbot', () async {
    StellarSDK sdk = StellarSDK.TESTNET;

// Create a random key pair for our account.
    KeyPair keyPair = KeyPair.random();

// Ask the Freindbot to create our account in the stellar network (only awailable in testnet).
    await FriendBot.fundTestAccount(keyPair.accountId);

// Load the account data from stellar.
    await sdk.accounts.account(keyPair.accountId);
  });

  test('create account', () async {
    StellarSDK sdk = StellarSDK.TESTNET;

    // Build a key pair from the seed of an existing account. We will need it for signing.
    KeyPair existingAccountKeyPair = KeyPair.fromSecretSeed(
        "SC4DBPMFWH6ZGEP6SJFJEW5UQQBG5RN4QEAWFVKSVL4KPJ3HHZO6ZAFY");

    // Existing account id.
    String existingAccountId = existingAccountKeyPair.accountId;

    // Create a random keypair for a new account to be created.
    KeyPair newAccountKeyPair = KeyPair.random();

    // Load the data of the existing account so that we receive it's current sequence number.
    AccountResponse existingAccount =
        await sdk.accounts.account(existingAccountId);

    // Build a transaction containing a create account operation to create the new account.
    Transaction transaction = new TransactionBuilder(
            existingAccount, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(newAccountKeyPair.accountId, "10")
                .build())
        .build();

    // Sign the transaction with the key pair of the existing account.
    transaction.sign(existingAccountKeyPair);

    // Submit the transaction to stellar.
    await sdk.submitTransaction(transaction);

    // Load the data of the new created account.
    await sdk.accounts.account(newAccountKeyPair.accountId);
  });

  test('test account merge', () async {
    // Create random key pairs for two accounts.
    KeyPair keyPairX = KeyPair.random();
    KeyPair keyPairY = KeyPair.random();

    // Account Ids.
    String accountXId = keyPairX.accountId;
    String accountYId = keyPairY.accountId;

    // Create both accounts.
    await FriendBot.fundTestAccount(accountXId);
    await FriendBot.fundTestAccount(accountYId);

    // Prepare the operation for merging account Y into account X.
    AccountMergeOperationBuilder accMergeOp =
        AccountMergeOperationBuilder(accountXId);

    // Load the data of account Y so that we have it's current sequence number.
    AccountResponse accountY = await sdk.accounts.account(accountYId);

    // Build the transaction to merge account Y into account X.
    Transaction transaction = TransactionBuilder(accountY, Network.TESTNET)
        .addOperation(accMergeOp.build())
        .build();

    // Account Y signs the transaction - R.I.P :)
    transaction.sign(keyPairY);

    // Submit the transaction.
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    if (response.success) {
      print("successfully merged");
    }

    // Check that account Y has been removed.
    await sdk.accounts.account(accountYId).then((response) {
      print("account still exists: $accountYId");
    }).catchError((error) {
      print(error.toString());
      if (error is ErrorResponse && error.code == 404) {
        print("success, account not found");
      }
    });

    // Check if accountX received the funds from accountY.
    AccountResponse accountX = await sdk.accounts.account(accountXId);
    for (Balance balance in accountX.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        print("X has ${double.parse(balance.balance)} XLM");
        break;
      }
    }
  });

  test('test bump sequence', () async {
    // Create a random key pair for a new account.
    KeyPair accountKeyPair = KeyPair.random();

    // Account Id.
    String accountId = accountKeyPair.accountId;

    // Create account.
    await FriendBot.fundTestAccount(accountId);

    // Load account data to get the current sequence number.
    AccountResponse account = await sdk.accounts.account(accountId);

    // Remember current sequence number.
    int startSequence = account.sequenceNumber;

    // Prepare the bump sequence operation to bump the sequence number to current + 10.
    BumpSequenceOperationBuilder bumpSequenceOpB =
        BumpSequenceOperationBuilder(startSequence + 10);

    // Prepare the transaction.
    Transaction transaction = TransactionBuilder(account, Network.TESTNET)
        .addOperation(bumpSequenceOpB.build())
        .build();

    // Sign the transaction.
    transaction.sign(accountKeyPair);

    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // Load the account again.
    account = await sdk.accounts.account(accountId);

    // Check that the new sequence number has correctly been bumped.
    if (startSequence + 10 == account.sequenceNumber) {
      print("success");
    } else {
      print("failed");
    }
  });

  test('test manage data', () async {
    // Create a random keypair for our new account.
    KeyPair keyPair = KeyPair.random();

    // Account Id.
    String accountId = keyPair.accountId;

    // Create account.
    await FriendBot.fundTestAccount(accountId);

    // Load account data including it's current sequence number.
    AccountResponse account = await sdk.accounts.account(accountId);

    // Define a key value pair to save as a data entry.
    String key = "Sommer";
    String value = "Die Möbel sind heiß!";

    // Convert the value to bytes.
    List<int> list = value.codeUnits;
    Uint8List valueBytes = Uint8List.fromList(list);

    // Prepare the manage data operation.
    ManageDataOperationBuilder manageDataOperationBuilder =
        ManageDataOperationBuilder(key, valueBytes);

    // Create the transaction.
    Transaction transaction = TransactionBuilder(account, Network.TESTNET)
        .addOperation(manageDataOperationBuilder.build())
        .build();

    // Sign the transaction.
    transaction.sign(keyPair);

    // Submit the transaction to stellar.
    await sdk.submitTransaction(transaction);

    // Reload the account.
    account = await sdk.accounts.account(accountId);

    // Get the value for our key as bytes.
    Uint8List resultBytes = account.data.getDecoded(key);

    // Convert it back to a string.
    String restltValue = String.fromCharCodes(resultBytes);

    // Compare.
    if (value == restltValue) {
      print("okay");
    } else {
      print("failed");
    }

    // In the next step we prepare the operation to delete the entry by passing null as a value.
    manageDataOperationBuilder = ManageDataOperationBuilder(key, null);

    // Prepare the transaction.
    transaction = TransactionBuilder(account, Network.TESTNET)
        .addOperation(manageDataOperationBuilder.build())
        .build();

    // Sign the transaction.
    transaction.sign(keyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Reload account.
    account = await sdk.accounts.account(accountId);

    // Check if the entry still exists. It should not be there any more.
    if (!account.data.keys.contains(key)) {
      print("success");
    }
  });

  test('test manage buy offer', () async {
    // Prepare two random keypairs, we will need the later for signing.
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair buyerKeipair = KeyPair.random();

    // Account Ids.
    String issuerAccountId = issuerKeipair.accountId;
    String buyerAccountId = buyerKeipair.accountId;

    // Create the buyer account.
    await FriendBot.fundTestAccount(buyerAccountId);

    // Create the issuer account.
    AccountResponse buyerAccount = await sdk.accounts.account(buyerAccountId);
    CreateAccountOperationBuilder caob =
        CreateAccountOperationBuilder(issuerAccountId, "10");
    Transaction transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(caob.build())
        .build();
    transaction.sign(buyerKeipair);
    await sdk.submitTransaction(transaction);

    // Define an asset.
    Asset astroDollar = AssetTypeCreditAlphaNum12("ASTRO", issuerAccountId);

    // Create a trustline for the buyer account.
    ChangeTrustOperation cto =
        ChangeTrustOperationBuilder(astroDollar, "10000").build();
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(cto)
        .build();
    transaction.sign(buyerKeipair);
    await sdk.submitTransaction(transaction);

    // Create the offer.
    // I want to pay max. 50 XLM for 100 ASTRO.
    String amountBuying = "100"; // Want to buy 100 ASTRO
    String price = "0.5"; // Price of 1 unit of buying in terms of selling

    // Create the manage buy offer operation. Buying: 100 ASTRO for 50 XLM (price = 0.5 => Price of 1 unit of buying in terms of selling)
    ManageBuyOfferOperation ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .build();
    // Create the transaction.
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    // Sign the transaction.
    transaction.sign(buyerKeipair);
    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // Now let's load the offers of our account to see if the offer has been created.
    Page<OfferResponse> offers =
        await sdk.offers.forAccount(buyerAccountId).execute();
    OfferResponse offer = offers.records.first;

    String buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum
        ? (offer.buying as AssetTypeCreditAlphaNum).code
        : "XLM";
    String sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum
        ? (offer.selling as AssetTypeCreditAlphaNum).code
        : "XLM";
    print("offerId: ${offer.id} - buying: " +
        buyingAssetCode +
        " - selling: ${offer.amount} " +
        sellingAssetCode +
        " price: ${offer.price}");
    // offerId: 16245277 - buying: ASTRO - selling: 50.0000000 XLM price: 2.0000000
    // As you can see, the price is stored here as "Price of 1 unit of selling in terms of buying".

    // Now lets modify our offer.
    String offerId = offer.id;

    // New data.
    amountBuying = "150";
    price = "0.3";

    // Build the manage buy offer operation
    ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .setOfferId(offerId) // provide the offerId of the offer to be modified.
        .build();

    // Build the transaction.
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    // Sign.
    transaction.sign(buyerKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Load the offer from stellar.
    offers = (await sdk.offers.forAccount(buyerAccountId).execute());
    offer = offers.records.first;

    buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum
        ? (offer.buying as AssetTypeCreditAlphaNum).code
        : "XLM";
    sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum
        ? (offer.selling as AssetTypeCreditAlphaNum).code
        : "XLM";
    print("offerId: ${offer.id} - buying: " +
        buyingAssetCode +
        " - selling: ${offer.amount} " +
        sellingAssetCode +
        " price: ${offer.price}");
    // offerId: 16245277 - buying: ASTRO - selling: 45.0000000 XLM price: 3.3333333

    // And now let's delete our offer
    // To delete, we need to set the amount to 0.
    amountBuying = "0";

    // Create the operation.
    ms = ManageBuyOfferOperationBuilder(
            Asset.NATIVE, astroDollar, amountBuying, price)
        .setOfferId(offerId) // Provide the id of the offer to be deleted.
        .build();

    // Build the transaction.
    transaction = TransactionBuilder(buyerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();

    // Sign.
    transaction.sign(buyerKeipair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // check if the offer has been deleted.
    offers = await sdk.offers.forAccount(buyerAccountId).execute();
    if (offers.records.length == 0) {
      print("success");
    }
  });

  test('test manage sell offer', () async {
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
    await sdk.submitTransaction(transaction);

    // Load issuer account so that we can send our custom assets to the seller account.
    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

    // Define our custom asset.
    Asset moonDollar = AssetTypeCreditAlphaNum4("MOON", issuerAccountId);

    // Let the seller trust our custom asset.
    ChangeTrustOperation cto =
        ChangeTrustOperationBuilder(moonDollar, "10000").build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(cto)
        .build();
    transaction.sign(sellerKeipair);
    await sdk.submitTransaction(transaction);

    // Send 2000 MOON asset to the seller account.
    PaymentOperation po =
        PaymentOperationBuilder(sellerAccountId, moonDollar, "2000").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(po)
        .build();
    transaction.sign(issuerKeipair);
    await sdk.submitTransaction(transaction);

    // Create the offer.
    // I want to sell 100 MOON for 50 XLM.
    String amountSelling = "100"; // We want to sell 100 MOON.
    String price = "0.5"; // Price of 1 unit of selling in terms of buying.

    // Create the manage sell offer operation. Selling: 100 MOON for 50 XLM (price = 0.5 => Price of 1 unit of selling in terms of buying.)
    ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
            moonDollar, Asset.NATIVE, amountSelling, price)
        .build();
    // Build the transaction.
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    // Sign.
    transaction.sign(sellerKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Now let's load the offers of our account to see if the offer has been created.
    Page<OfferResponse> offers =
        await sdk.offers.forAccount(sellerAccountId).execute();
    OfferResponse offer = offers.records.first;

    String sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum
        ? (offer.selling as AssetTypeCreditAlphaNum).code
        : "XLM";
    String buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum
        ? (offer.buying as AssetTypeCreditAlphaNum).code
        : "XLM";
    print("offerId: ${offer.id} - selling: ${offer.amount} " +
        sellingAssetCode +
        " buying: " +
        buyingAssetCode +
        " price: ${offer.price}");
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
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    // Sign.
    transaction.sign(sellerKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Load again to see if it has been modified.
    offers = await sdk.offers.forAccount(sellerAccountId).execute();
    offer = offers.records.first;
    sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum
        ? (offer.selling as AssetTypeCreditAlphaNum).code
        : "XLM";
    buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum
        ? (offer.buying as AssetTypeCreditAlphaNum).code
        : "XLM";
    print("offerId: ${offer.id} - selling: ${offer.amount} " +
        sellingAssetCode +
        " buying: " +
        buyingAssetCode +
        " price: ${offer.price}");
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
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    // Sign.
    transaction.sign(sellerKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Check if the offer has been deleted.
    offers = await sdk.offers.forAccount(sellerAccountId).execute();
    if (offers.records.length == 0) {
      print("success");
    }
  });

  test('create passive sell offer', () async {
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
    CreateAccountOperation co =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(co)
        .build();
    transaction.sign(sellerKeipair);
    await sdk.submitTransaction(transaction);

    // Load issuer account so that we can send some custom asset funds to the seller account.
    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);

    // Define our custom asset.
    Asset marsDollar = AssetTypeCreditAlphaNum4("MARS", issuerAccountId);

    // Let the seller account trust our issuer and custom asset.
    ChangeTrustOperation cto =
        ChangeTrustOperationBuilder(marsDollar, "10000").build();
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(cto)
        .build();
    transaction.sign(sellerKeipair);
    await sdk.submitTransaction(transaction);

    // Send a couple of custom asset MARS funds from the issuer to the seller account so that the seller can offer them.
    PaymentOperation po =
        PaymentOperationBuilder(sellerAccountId, marsDollar, "2000").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(po)
        .build();
    transaction.sign(issuerKeipair);
    await sdk.submitTransaction(transaction);

    // Create the offer.
    // I want to sell 100 MARS for 50 XLM.
    String amountSelling = "100";
    String price = "0.5";

    // Create the passive sell offer operation. Selling: 100 MARS for 50 XLM (price = 0.5 => Price of 1 unit of selling in terms of buying.)
    CreatePassiveSellOfferOperation cpso =
        CreatePassiveSellOfferOperationBuilder(
                marsDollar, Asset.NATIVE, amountSelling, price)
            .build();
    // Build the transaction.
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(cpso)
        .build();
    // Sign.
    transaction.sign(sellerKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Now let's load the offers of our account to see if the offer has been created.
    Page<OfferResponse> offers =
        (await sdk.offers.forAccount(sellerAccountId).execute());
    OfferResponse offer = offers.records.first;

    String sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum
        ? (offer.selling as AssetTypeCreditAlphaNum).code
        : "XLM";
    String buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum
        ? (offer.buying as AssetTypeCreditAlphaNum).code
        : "XLM";
    print("offerId: ${offer.id} - selling: ${offer.amount} " +
        sellingAssetCode +
        " buying: " +
        buyingAssetCode +
        " price: ${offer.price}");
    // offerId: 16260716 - selling: 100.0000000 MARS buying: XLM price: 0.5000000
    // Price of 1 unit of selling in terms of buying.

    // Now lets modify our offer.
    String offerId = offer.id;

    // update offer
    amountSelling = "150";
    price = "0.3";

    // To modify the offer, we are going to use the mange sell offer operation.
    ManageSellOfferOperation ms = ManageSellOfferOperationBuilder(
            marsDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId) // set id of the offer to be modified.
        .build();
    // Build the transaction.
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    // Sign.
    transaction.sign(sellerKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Load again to see if it has been modified.
    offers = await sdk.offers.forAccount(sellerAccountId).execute();
    offer = offers.records.first;

    sellingAssetCode = offer.selling is AssetTypeCreditAlphaNum
        ? (offer.selling as AssetTypeCreditAlphaNum).code
        : "XLM";
    buyingAssetCode = offer.buying is AssetTypeCreditAlphaNum
        ? (offer.buying as AssetTypeCreditAlphaNum).code
        : "XLM";
    print("offerId: ${offer.id} - selling: ${offer.amount} " +
        sellingAssetCode +
        " buying: " +
        buyingAssetCode +
        " price: ${offer.price}");
    //offerId: 16260716 - selling: 150.0000000 MARS buying: XLM price: 0.3000000

    // And now let's delete the offer. To delete it, we must set the amount to zero.
    amountSelling = "0";

    // To delete the offer we can use the manage sell offer operation.
    ms = ManageSellOfferOperationBuilder(
            marsDollar, Asset.NATIVE, amountSelling, price)
        .setOfferId(offerId) // Set the id of the offer to be deleted.
        .build();
    // Build the transaction.
    transaction = TransactionBuilder(sellerAccount, Network.TESTNET)
        .addOperation(ms)
        .build();
    // Sign.
    transaction.sign(sellerKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Check if the offer has been deleted.
    offers = await sdk.offers.forAccount(sellerAccountId).execute();
    if (offers.records.length == 0) {
      print("success");
    }
  });

  test('change trust', () async {
    // Create two random key pairs, we will need them later for signing.
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair trustorKeipair = KeyPair.random();

    // Account Ids.
    String issuerAccountId = issuerKeipair.accountId;
    String trustorAccountId = trustorKeipair.accountId;

    // Create trustor account.
    await FriendBot.fundTestAccount(trustorAccountId);

    // Load the trustor account so that we can later create the trustline.
    AccountResponse trustorAccount =
        await sdk.accounts.account(trustorAccountId);

    // Create the issuer account.
    CreateAccountOperation cao =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction =
        TransactionBuilder(trustorAccount, Network.TESTNET)
            .addOperation(cao)
            .build();
    transaction.sign(trustorKeipair);
    await sdk.submitTransaction(transaction);

    // Creat our custom asset.
    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    // Create the trustline. Limit: 10000 ASTRO.
    String limit = "10000";
    // Build the operation.
    ChangeTrustOperation cto =
        ChangeTrustOperationBuilder(astroDollar, limit).build();
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET)
        .addOperation(cto)
        .build();
    // Sign.
    transaction.sign(trustorKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Load the trustor account again to see if the trustline has been created.
    trustorAccount = await sdk.accounts.account(trustorAccountId);

    // Check if the trustline exists.
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        print("Trustline for " +
            assetCode +
            " found. Limit: ${double.parse(balance.limit)}");
        // Trustline for ASTRO found. Limit: 10000.0
        break;
      }
    }

    // Now, let's modify the trustline, change the trust limit to 40000.
    limit = "40000";

    // Build the change trust operation.
    cto = ChangeTrustOperationBuilder(astroDollar, limit).build();
    // Build the transaction.
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET)
        .addOperation(cto)
        .build();
    // Sign.
    transaction.sign(trustorKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

    // Load the trustor account to see if the trustline has been modified.
    trustorAccount = await sdk.accounts.account(trustorAccountId);

    // Check.
    for (Balance balance in trustorAccount.balances) {
      if (balance.assetCode == assetCode) {
        print("Trustline for " +
            assetCode +
            " found. Limit: ${double.parse(balance.limit)}");
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
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET)
        .addOperation(cto)
        .build();
    // Sign.
    transaction.sign(trustorKeipair);
    // Submit.
    await sdk.submitTransaction(transaction);

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

    if (!found) {
      print("success, trustline deleted");
    }
  });

  test('allow trust', () async {
    // Create two random key pairs, we will need them later for signing.
    KeyPair issuerKeipair = KeyPair.random();
    KeyPair trustorKeipair = KeyPair.random();

    // Account Ids.
    String issuerAccountId = issuerKeipair.accountId;
    String trustorAccountId = trustorKeipair.accountId;

    // Create trustor account.
    await FriendBot.fundTestAccount(trustorAccountId);

    // Load trustor account, we will need it later to create the trustline.
    AccountResponse trustorAccount =
        await sdk.accounts.account(trustorAccountId);

    // Create the issuer account.
    CreateAccountOperation cao =
        CreateAccountOperationBuilder(issuerAccountId, "10").build();
    Transaction transaction =
        TransactionBuilder(trustorAccount, Network.TESTNET)
            .addOperation(cao)
            .build();
    transaction.sign(trustorKeipair);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    // Load the issuer account.
    AccountResponse issuerAccount = await sdk.accounts.account(issuerAccountId);
    // Set up the flags on the isser account.
    SetOptionsOperationBuilder sopb = SetOptionsOperationBuilder();
    sopb.setSetFlags(3); // Auth required, auth revocable
    // Build the transaction.
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(sopb.build())
        .build();
    // Sign.
    transaction.sign(issuerKeipair);
    // Submit.
    response = await sdk.submitTransaction(transaction);

    // Reload the issuer account to check the flags.
    issuerAccount = await sdk.accounts.account(issuerAccountId);
    if (issuerAccount.flags.authRequired &&
        issuerAccount.flags.authRevocable &&
        !issuerAccount.flags.authImmutable) {
      print("issuer account flags correctly set");
    }

    // Define our custom asset.
    String assetCode = "ASTRO";
    Asset astroDollar = AssetTypeCreditAlphaNum12(assetCode, issuerAccountId);

    // Build the trustline.
    String limit = "10000";
    ChangeTrustOperation cto =
        ChangeTrustOperationBuilder(astroDollar, limit).build();
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
    PaymentOperation po =
        PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(po)
        .build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);
    if (!response.success) {
      // not authorized.
      print("trustline is not authorized");
    }

    // Now let's authorize the trustline.
    // Build the allow trust operation. Set the authorized flag to 1.
    AllowTrustOperation aop =
        AllowTrustOperationBuilder(trustorAccountId, assetCode, 1)
            .build(); // authorize
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(aop)
        .build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);

    // Try again to send the payment. Should work now.
    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(po)
        .build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);
    if (response.success) {
      // authorized.
      print("sccess - trustline is now authorized.");
    }

    // Now create an offer, to see if it will be deleted after we will remove the authorized flag.
    String amountSelling = "100";
    String price = "0.5";
    CreatePassiveSellOfferOperation cpso =
        CreatePassiveSellOfferOperationBuilder(
                astroDollar, Asset.NATIVE, amountSelling, price)
            .build();
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET)
        .addOperation(cpso)
        .build();
    transaction.sign(trustorKeipair);
    response = await sdk.submitTransaction(transaction);

    // Check if the offer has been added.
    List<OfferResponse> offers =
        (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    OfferResponse offer = offers.first;
    if (offer.buying == Asset.NATIVE && offer.selling == astroDollar) {
      print("offer found");
    }

    // Now lets remove the authorization. To do so, we set the authorized flag to 0.
    // This should also delete the offer.
    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 0)
        .build(); // not authorized
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(aop)
        .build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);

    // Check if the offer has been deleted.
    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    if (offers.length == 0) {
      print("success, offer has been deleted");
    }

    // Now, let's authorize the trustline again and then authorize it only to maintain liabilities.
    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 1)
        .build(); // authorize
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(aop)
        .build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);

    // Create the offer again.
    cpso = CreatePassiveSellOfferOperationBuilder(
            astroDollar, Asset.NATIVE, amountSelling, price)
        .build();
    transaction = TransactionBuilder(trustorAccount, Network.TESTNET)
        .addOperation(cpso)
        .build();
    transaction.sign(trustorKeipair);
    response = await sdk.submitTransaction(transaction);

    // Check that the offer has been created.
    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    if (offers.length == 1) {
      print("offer has been created");
    }

    // Now let's deautorize the trustline but allow the trustor to maintain his offer.
    // For this, we set the authorized flag to 2.
    aop = AllowTrustOperationBuilder(trustorAccountId, assetCode, 2)
        .build(); // authorized to maintain liabilities.
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(aop)
        .build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);

    // Load the offers to see if our offer is still there.
    offers = (await sdk.offers.forAccount(trustorAccountId).execute()).records;
    if (offers.length == 1) {
      print("success, offer exists");
    }

    // Next, let's try to send some ASTRO to the trustor account.
    // This should not work, since the trustline has been deauthorized before.
    po = PaymentOperationBuilder(trustorAccountId, astroDollar, "100").build();
    transaction = TransactionBuilder(issuerAccount, Network.TESTNET)
        .addOperation(po)
        .build();
    transaction.sign(issuerKeipair);
    response = await sdk.submitTransaction(transaction);
    if (!response.success) {
      // is not authorized for new funds
      print("payment correctly blocked.");
    }
  });

  test('streaming for payments', () async {
    // Create two accounts, so that we can send a payment.
    KeyPair keyPairA = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    String accountBId = keyPairB.accountId;
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    await FriendBot.fundTestAccount(accountBId);

    // Load current data of account B.
    AccountResponse accountB = await sdk.accounts.account(accountBId);

    // Subscribe to listen for payments for account A.
    // If we set the cursor to "now" it will not receive old events such as the create account operation.
    StreamSubscription subscription = sdk.payments
        .forAccount(accountAId)
        .cursor("now")
        .stream()
        .listen((response) {
      if (response is PaymentOperationResponse) {
        switch (response.assetType) {
          case Asset.TYPE_NATIVE:
            print(
                "Payment of ${response.amount} XLM from ${response.sourceAccount} received.");
            break;
          default:
            print(
                "Payment of ${response.amount} ${response.assetCode} from ${response.sourceAccount} received.");
        }
      }
    });

    // Send 10 XLM from account B to account A.
    Transaction transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(accountAId, Asset.NATIVE, "10").build())
        .build();
    transaction.sign(keyPairB);
    await sdk.submitTransaction(transaction);

    // When you are done listening to that Stream, for any reason, you may close/cancel the subscription.
    // In this example we wait 5 seconds for the payment event.
    await Future.delayed(const Duration(seconds: 5), () {});
    // Now cancel the subscription.
    subscription.cancel();
  });

  test('submit fee bump transaction', () async {
    // Create 3 random Keypairs, we will need them later for signing.
    KeyPair sourceKeyPair = KeyPair.random();
    KeyPair destinationKeyPair = KeyPair.random();
    KeyPair payerKeyPair = KeyPair.random();

    // Account Ids.
    String payerId = payerKeyPair.accountId;
    String sourceId = sourceKeyPair.accountId;
    String destinationId = destinationKeyPair.accountId;

    // Create the source and the payer account.
    await FriendBot.fundTestAccount(sourceId);
    await FriendBot.fundTestAccount(payerId);

    // Load the current data of the source account so that we can create the inner transaction.
    AccountResponse sourceAccount = await sdk.accounts.account(sourceId);

    // Build the inner transaction which will create the the destination account by using the source account.
    Transaction innerTx = new TransactionBuilder(sourceAccount, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(destinationId, "10").build())
        .build();

    // Sign the inner transaction with the source account key pair.
    innerTx.sign(sourceKeyPair);

    // Build the fee bump transaction to let the payer account pay the fee for the inner transaction.
    // The base fee for the fee bump transaction must be higher than the fee of the inner transaction.
    FeeBumpTransaction feeBump = new FeeBumpTransactionBuilder(innerTx)
        .setBaseFee(200)
        .setFeeAccount(payerId)
        .build();

    // Sign the fee bump transaction with the
    feeBump.sign(payerKeyPair);

    // Submit the fee bump transaction containing the inner transaction.
    SubmitTransactionResponse response =
        await sdk.submitFeeBumpTransaction(feeBump);

    // Let's check if the destination account has been created and received the funds.
    AccountResponse destination = await sdk.accounts.account(destinationId);
    for (Balance balance in destination.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        if (double.parse(balance.balance) > 9) {
          print("Success :)");
        }
      }
    }

    // You can load the transaction data with sdk.transactions
    TransactionResponse transaction =
        await sdk.transactions.transaction(response.hash);

    // Same for the inner transaction.
    transaction =
        await sdk.transactions.transaction(transaction.innerTransaction.hash);
  });

  test('send native payment - muxed source and muxed destination account',
      () async {
    // Create two random key pairs, we will need them later for signing.
    KeyPair senderKeyPair = KeyPair.random();
    KeyPair receiverKeyPair = KeyPair.random();

    // AccountIds
    String accountCId = receiverKeyPair.accountId;
    String senderAccountId = senderKeyPair.accountId;

    // Create the sender account.
    await FriendBot.fundTestAccount(senderAccountId);

    // Load the current account data of the sender account.
    AccountResponse accountA = await sdk.accounts.account(senderAccountId);

    // Create the receiver account.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    // Sign.
    transaction.sign(senderKeyPair);

    // Submit.
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);

    // Now let's create the mxued accounts to be used in the payment transaction.
    MuxedAccount muxedDestinationAccount = MuxedAccount(accountCId, 8298298319);
    MuxedAccount muxedSourceAccount = MuxedAccount(senderAccountId, 2442424242);

    // Build the payment operation.
    // We use the muxed account objects for destination and for source here.
    // This is not needed, you can also use only a muxed source account or muxed destination account.
    PaymentOperation paymentOperation =
        PaymentOperationBuilder.forMuxedDestinationAccount(
                muxedDestinationAccount, Asset.NATIVE, "100")
            .setMuxedSourceAccount(muxedSourceAccount)
            .build();

    // Build the transaction.
    // If we want to use a Med25519 muxed account with id as a source of the transaction, we can just set the id in our account object.
    accountA.muxedAccountMed25519Id = 44498494844;
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(paymentOperation)
        .build();

    // Sign.
    transaction.sign(senderKeyPair);

    // Submit.
    response = await sdk.submitTransaction(transaction);

    // Have a look to the transaction and the contents of the envelope in Stellar Laboratory
    // https://laboratory.stellar.org/#explorer?resource=transactions&endpoint=single&network=test
    print(response.hash);
  });

  test('sep 0001 - stellar.toml', () async {
    String toml = '''
      # Sample stellar.toml
      VERSION="2.0.0"
      # ...
    ''';

    StellarToml stellarToml = StellarToml(toml);
    GeneralInformation generalInformation = stellarToml.generalInformation;
    print(generalInformation.version);

    stellarToml = await StellarToml.fromDomain("soneso.com");
    List<Currency> currencies = stellarToml.currencies;
    for (Currency currency in currencies) {
      if (currency.toml != null) {
        Currency linkedCurrency =
            await StellarToml.currencyFromUrl(currency.toml);
        print(linkedCurrency.code);
      }
    }
  });

  test('sep 0002 - federation - resolve address', () async {
    FederationResponse response =
        await Federation.resolveStellarAddress("bob*soneso.com");
    print(response.stellarAddress);
    print(response.accountId);
    print(response.memoType);
    print(response.memo);
  });
}
