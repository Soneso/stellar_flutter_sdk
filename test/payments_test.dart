@Timeout(const Duration(seconds: 300))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  String testSeed = "SAPS66IJDXUSFDSDKIHR4LN6YPXIGCM5FBZ7GE66FDKFJRYJGFW7ZHYF";
  KeyPair keyPairA;
  AccountResponse accountA;

  setUp(() async {

    keyPairA = KeyPair.fromSecretSeed(testSeed); // KeyPair.random();

    if (testSeed != keyPairA.secretSeed) {
      await FriendBot.fundTestAccount(keyPairA.accountId).then((funded) async {
        if (funded) {
          print(
              "Funded account A: ${keyPairA.accountId} : ${keyPairA.secretSeed}");
        }
      });
    } else {
      print("Account A: ${keyPairA.accountId} : ${keyPairA.secretSeed}");
    }
  });

  test('send native payment', () async {
    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;
    accountA = await sdk.accounts.account(keyPairA.accountId);

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("C funded: " + accountCId);
    }).catchError((error) {
      print(error);
      assert(false);
    });

    // send 100 XLM native payment from A to C
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(PaymentOperationBuilder(accountCId,Asset.NATIVE, "100").build())
        .build();
    transaction.sign(keyPairA);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("Payment 100 MXL from A to C sent");
    }).catchError((error) {
      print(error);
      assert(false);
    });

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    for (Balance balance in accountC.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
          assert(double.parse(balance.balance) > 100);
          print("C received payment");
          break;
      }
    }
  });

  test('send non native payment', () async {
    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;

    accountA = await sdk.accounts.account(keyPairA.accountId);

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("C funded: " + accountCId);
    }).catchError((error) {
      print(error);
      assert(false);
    });

    // fund account B.
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountBId, "10").build())
        .build();

    transaction.sign(keyPairA);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("B funded: " + accountBId);
    }).catchError((error) {
      print(error);
      assert(false);
    });

    AccountResponse accountC = await sdk.accounts.account(accountCId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);

    ChangeTrustOperationBuilder chOp =
    ChangeTrustOperationBuilder(iomAsset, "200999");

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    transaction.sign(keyPairC);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("C trusts IOM:A");
    }).catchError((error) {
      print(error);
      assert(false);
    });


    AccountResponse accountB = await sdk.accounts.account(accountBId);
    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(chOp.build())
        .build();

    transaction.sign(keyPairB);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("B trusts IOM:A");
    }).catchError((error) {
      print(error);
      assert(false);
    });

    // send 100 IOM non native payment from A to C
    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(PaymentOperationBuilder(accountCId, iomAsset, "100").build())
        .build();
    transaction.sign(keyPairA);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("Payment 100 IOM from A to C sent");
    }).catchError((error) {
      print(error);
      assert(false);
    });

    accountC = await sdk.accounts.account(accountCId);
    for (Balance balance in accountC.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == "IOM") {
        assert(double.parse(balance.balance) > 90);
        print("C received IOM payment");
        break;
      }
    }

    // send 50.09 IOM non native payment from C to B
    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(PaymentOperationBuilder(accountBId, iomAsset, "50.09").build())
        .build();
    transaction.sign(keyPairC);

    await sdk.submitTransaction(transaction).then((response) {
      assert(response.success);
      print("Payment 50.09 IOM from C to B sent");
    }).catchError((error) {
      print(error);
      assert(false);
    });

    accountB = await sdk.accounts.account(accountBId);
    for (Balance balance in accountB.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == "IOM") {
        assert(double.parse(balance.balance) > 40);
        print("B received IOM payment");
        break;
      }
    }
  });

  test('path payment strict send and strict receive', () async {
    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    KeyPair keyPairD = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;
    String accountDId = keyPairD.accountId;

    accountA = await sdk.accounts.account(keyPairA.accountId);

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10").build())
        .addOperation(new CreateAccountOperationBuilder(accountBId, "10").build())
        .addOperation(new CreateAccountOperationBuilder(accountDId, "10").build())
        .build();
    transaction.sign(keyPairA);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("C funded: " + accountCId);
    print("B funded: " + accountBId);
    print("D funded: " + accountDId);

    AccountResponse accountC = await sdk.accounts.account(accountCId);
    AccountResponse accountB = await sdk.accounts.account(accountBId);
    AccountResponse accountD = await sdk.accounts.account(accountDId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);
    Asset ecoAsset = AssetTypeCreditAlphaNum4("ECO", keyPairA.accountId);
    ChangeTrustOperationBuilder ctIOMOp = ChangeTrustOperationBuilder(iomAsset, "200999");
    ChangeTrustOperationBuilder ctECOOp = ChangeTrustOperationBuilder(ecoAsset, "200999");

    transaction = new TransactionBuilder(accountC, Network.TESTNET)
        .addOperation(ctIOMOp.build()).build();
    transaction.sign(keyPairC);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("C trusts IOM:A");

    transaction = new TransactionBuilder(accountB, Network.TESTNET)
        .addOperation(ctIOMOp.build())
        .addOperation(ctECOOp.build())
        .build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("B trusts IOM:A and ECO:A");

    transaction = new TransactionBuilder(accountD, Network.TESTNET)
        .addOperation(ctECOOp.build()).build();
    transaction.sign(keyPairD);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("D trusts ECO:A");

    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(PaymentOperationBuilder(accountCId, iomAsset, "100").build())
        .addOperation(PaymentOperationBuilder(accountBId, iomAsset, "100").build())
        .addOperation(PaymentOperationBuilder(accountBId, ecoAsset, "100").build())
        .addOperation(PaymentOperationBuilder(accountDId, ecoAsset, "100").build())
        .build();
    transaction.sign(keyPairA);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("C,B,D recived non native funds.");

    ManageSellOfferOperation sellOfferOp = ManageSellOfferOperation(ecoAsset, iomAsset, "30", "0.5", 0);
    transaction = new TransactionBuilder(accountB, Network.TESTNET).addOperation(sellOfferOp).build();
    transaction.sign(keyPairB);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("B offes ECO for IOM");

    PathPaymentStrictSendOperation strictSend = PathPaymentStrictSendOperation(iomAsset, "10", accountDId, ecoAsset, "18", null);
    transaction = new TransactionBuilder(accountC, Network.TESTNET).addOperation(strictSend).build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("C sent strict-send IOM->ECO to D");

    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 19);
        print("D received ECO payment");
        break;
      }
    }

    PathPaymentStrictReceiveOperation strictReceive = PathPaymentStrictReceiveOperation(iomAsset,"2",accountDId,ecoAsset,"3",null);
    transaction = new TransactionBuilder(accountC, Network.TESTNET).addOperation(strictReceive).build();
    transaction.sign(keyPairC);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("C sent strict-receive IOM->ECO to D");

    accountD = await sdk.accounts.account(accountDId);
    for (Balance balance in accountD.balances) {
      if (balance.assetType != Asset.TYPE_NATIVE && balance.assetCode == "ECO") {
        assert(double.parse(balance.balance) > 22);
        print("D received ECO payment");
        break;
      }
    }
    print("Success!");
  });

  test('get payments for account, transaction, ledger', () async {

    String accountAId = keyPairA.accountId;
    KeyPair keyPairC = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    KeyPair keyPairD = KeyPair.random();
    String accountCId = keyPairC.accountId;
    String accountBId = keyPairB.accountId;
    String accountDId = keyPairD.accountId;

    accountA = await sdk.accounts.account(accountAId);

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(new CreateAccountOperationBuilder(accountCId, "10").build())
        .addOperation(new CreateAccountOperationBuilder(accountBId, "10").build())
        .addOperation(new CreateAccountOperationBuilder(accountDId, "10").build())
        .build();
    transaction.sign(keyPairA);

    SubmitTransactionResponse response = await sdk.submitTransaction(transaction);
    assert(response.success);
    print("C funded: " + accountCId);
    print("B funded: " + accountBId);
    print("D funded: " + accountDId);

    transaction = new TransactionBuilder(accountA, Network.TESTNET)
        .addOperation(PaymentOperationBuilder(accountCId,Asset.NATIVE, "10").build())
        .addOperation(PaymentOperationBuilder(accountBId,Asset.NATIVE, "10").build())
        .addOperation(PaymentOperationBuilder(accountDId,Asset.NATIVE, "10").build())
        .build();
    transaction.sign(keyPairA);
    response = await sdk.submitTransaction(transaction);
    assert(response.success);

    Page<OperationResponse> payments = await sdk.payments.forAccount(accountAId).order(RequestBuilderOrder.DESC).execute();
    assert(payments.records.length > 6);
    print(payments.records.length.toString() + " payments found for account A: " + accountAId);


    String createAccTransactionHash;
    String paymentTransactionHash;
    for (OperationResponse response in payments.records) {
        if (response is PaymentOperationResponse && paymentTransactionHash == null) {
          PaymentOperationResponse por = response;
          if (por.transactionSuccessful) {
            paymentTransactionHash = por.transactionHash;
          }
        } else if (response is CreateAccountOperationResponse && createAccTransactionHash == null) {
            CreateAccountOperationResponse car = response;
            if(car.transactionSuccessful) {
              createAccTransactionHash = car.transactionHash;
            }
        }
    }
    assert(paymentTransactionHash != null);
    assert(createAccTransactionHash != null);

    payments = await sdk.payments.forTransaction(paymentTransactionHash).execute();
    assert(payments.records.length > 0);
    print(payments.records.length.toString() + " payments found for transaction: " + paymentTransactionHash);

    payments = await sdk.payments.forTransaction(createAccTransactionHash).execute();
    assert(payments.records.length > 0);
    print(payments.records.length.toString() + " payments found for transaction: " + createAccTransactionHash);

    TransactionResponse tran = await sdk.transactions.transaction(paymentTransactionHash);
    assert(tran.ledger != null);
    payments = await sdk.payments.forLedger(tran.ledger).execute();
    assert(payments.records.length > 0);
    print(payments.records.length.toString() + " payments found for ledger: " + tran.ledger.toString());

  });
}



