@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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

  test('../examples/trustline.md', () async {
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
        "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF");
    KeyPair senderKeyPair = KeyPair.fromSecretSeed(
        "SCYKGVCVPKMNIG3DKLW42WR3Q6BAU2PTOEEFYNMSHDPWS2Z4LB6HDCXR");
    KeyPair receiverKeyPair = KeyPair.fromSecretSeed(
        "SB2VYVJSBKXV6YUPMP2627EJP3FZIQQSX3XZIKD5ZUJX5ZDKCRVKXC5N");

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

    // Build the transactuion for the trustline (receiver trusts custom asset).
    transaction = new TransactionBuilder(sender, Network.TESTNET)
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
    KeyPair middlemanKeyPair = KeyPair.random();
    KeyPair receiverKeyPair = KeyPair.random();

    // Account Ids.
    String issuerAccoutId = issuerKeyPair.accountId;
    String senderAccountId = senderKeyPair.accountId;
    String middlemanAccountId = middlemanKeyPair.accountId;
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
            new CreateAccountOperationBuilder(middlemanAccountId, "10").build())
        .addOperation(
            new CreateAccountOperationBuilder(receiverAccountId, "10").build())
        .build();

    // Sign the transaction.
    transaction.sign(issuerKeyPair);

    // Submit the transaction.
    await sdk.submitTransaction(transaction);

    // Load the data of the accounts so that we can create the trustlines in the next step.
    AccountResponse sender = await sdk.accounts.account(senderAccountId);
    AccountResponse middleman = await sdk.accounts.account(middlemanAccountId);
    AccountResponse receiver = await sdk.accounts.account(receiverAccountId);

    // Define our custom tokens.
    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", issuerAccoutId);
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

    // Let the middleman trust both IOM and ECO.
    ChangeTrustOperationBuilder ctECOOp =
        ChangeTrustOperationBuilder(ecoAsset, "200999");

    // Build the transaction.
    transaction = new TransactionBuilder(middleman, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .addOperation(ctECOOp.build())
        .build();

    // Sign the transaction.
    transaction.sign(middlemanKeyPair);

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
    // Send 100 IOM and 100 ECO to middleman.
    transaction = new TransactionBuilder(issuer, Network.TESTNET)
        .addOperation(
            PaymentOperationBuilder(senderAccountId, iomAsset, "100").build())
        .addOperation(
            PaymentOperationBuilder(middlemanAccountId, iomAsset, "100")
                .build())
        .addOperation(
            PaymentOperationBuilder(middlemanAccountId, ecoAsset, "100")
                .build())
        .build();

    // Sign.
    transaction.sign(issuerKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Now let the middleman offer ECO for IOM: 1 IOM = 2 ECO. Offered Amount: 30 ECO.
    ManageSellOfferOperation sellOfferOp =
        ManageSellOfferOperation(ecoAsset, iomAsset, "30", "0.5", 0);

    // Build the transaction.
    transaction = new TransactionBuilder(middleman, Network.TESTNET)
        .addOperation(sellOfferOp)
        .build();

    // Sign.
    transaction.sign(middlemanKeyPair);

    // Submit.
    await sdk.submitTransaction(transaction);

    // Everything is prepared now. We can use path payment to send IOM but receive ECO.
    // Stellar will find the path for us.
    // First path payment strict send. Send exactly 10 IOM, receive minimum 18 ECO (it will be 20).
    PathPaymentStrictSendOperation strictSend = PathPaymentStrictSendOperation(
        iomAsset, "10", receiverAccountId, ecoAsset, "18", null);

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
    // We want the receiver to receive exactly 3 ECO.
    // The sender sends max 2 IOM (will be 1.5).
    PathPaymentStrictReceiveOperation strictReceive =
        PathPaymentStrictReceiveOperation(
            iomAsset, "2", receiverAccountId, ecoAsset, "3", null);

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
}
