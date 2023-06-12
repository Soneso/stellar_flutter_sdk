import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'tests_util.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  Network network = Network.TESTNET;

  test('test set account options', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);
    int seqNum = accountA.sequenceNumber;

    KeyPair keyPairB = KeyPair.random();

    // Signer account B.
    XdrSignerKey bKey = XdrSignerKey(XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519);
    bKey.ed25519 = keyPairB.xdrPublicKey.getEd25519();

    var rng = new Random();
    String newHomeDomain = "www." + rng.nextInt(10000).toString() + ".com";

    SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();

    Transaction transaction = new TransactionBuilder(accountA)
        .addOperation(setOp
            .setHomeDomain(newHomeDomain)
            .setSigner(bKey, 1)
            .setHighThreshold(5)
            .setMasterKeyWeight(5)
            .setMediumThreshold(3)
            .setLowThreshold(1)
            .setSetFlags(2)
            .build())
        .addMemo(Memo.text("Test create account"))
        .build();

    transaction.sign(keyPairA, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    accountA = await sdk.accounts.account(keyPairA.accountId);

    assert(accountA.sequenceNumber > seqNum);
    assert(accountA.homeDomain == newHomeDomain);
    assert(accountA.thresholds.highThreshold == 5);
    assert(accountA.thresholds.medThreshold == 3);
    assert(accountA.thresholds.lowThreshold == 1);
    assert(accountA.signers.length > 1);
    bool bFound = false;
    bool aFound = false;
    for (Signer? signer in accountA.signers) {
      if (signer!.accountId == keyPairB.accountId) {
        bFound = true;
      }
      if (signer.accountId == keyPairA.accountId) {
        aFound = true;
        assert(signer.weight == 5);
      }
    }
    assert(aFound);
    assert(bFound);
    assert(accountA.flags.authRequired == false);
    assert(accountA.flags.authRevocable == true);
    assert(accountA.flags.authImmutable == false);

    // Find account for signer.
    Page<AccountResponse> accounts =
        await sdk.accounts.forSigner(keyPairB.accountId).execute();
    aFound = false;
    for (AccountResponse? account in accounts.records!) {
      if (account!.accountId == keyPairA.accountId) {
        aFound = true;
        break;
      }
    }
    assert(aFound);
  });

  test('test find accounts for asset', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(keyPairA.accountId);

    KeyPair keyPairC = KeyPair.random();
    String accountCId = keyPairC.accountId;

    // fund account C.
    Transaction transaction = new TransactionBuilder(accountA)
        .addOperation(
            new CreateAccountOperationBuilder(accountCId, "10").build())
        .build();

    transaction.sign(keyPairA, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    AccountResponse accountC = await sdk.accounts.account(accountCId);

    Asset iomAsset = AssetTypeCreditAlphaNum4("IOM", keyPairA.accountId);

    ChangeTrustOperation changeTrustOperation =
        ChangeTrustOperationBuilder(iomAsset, "200999").build();

    transaction = new TransactionBuilder(accountC)
        .addOperation(changeTrustOperation)
        .build();

    transaction.sign(keyPairC, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    // Find account for asset.
    AccountsRequestBuilder ab = sdk.accounts.forAsset(iomAsset);
    Page<AccountResponse> accounts = await ab.execute();
    bool cFound = false;
    for (AccountResponse? account in accounts.records!) {
      if (account!.accountId == keyPairC.accountId) {
        cFound = true;
      }
    }
    assert(cFound);
  });

  test('test stream account for account id', () async {
    KeyPair keyPairA = KeyPair.random();
    KeyPair keyPairB = KeyPair.random();
    await Future.wait([
      FriendBot.fundTestAccount(keyPairA.accountId),
      FriendBot.fundTestAccount(keyPairB.accountId)
    ]);

    final accountResponses = <AccountResponse>[];

    // Create a Completer to track when the stream receives the latest version
    final sub = sdk.accounts
        .forAccount(keyPairA.accountId)
        .cursor("now")
        .stream()
        .listen((accountReponse) {
      print(
        "Account response event received: ${accountReponse.balances.first.balance} XLM",
      );
      accountResponses.add(accountReponse);
    });

    // Get the source account details
    final sourceAccount = await sdk.accounts.account(keyPairA.accountId);
    final oldBalance = double.parse(sourceAccount.balances.first.balance);

    // Create a transaction
    String amount = "10";
    final transaction = TransactionBuilder(sourceAccount)
        .setMaxOperationFee(200000)
        .addOperation(
          PaymentOperationBuilder(
            keyPairB.accountId,
            Asset.NATIVE,
            amount,
          ).build(),
        )
        .build();

    // Sign the transaction
    transaction.sign(keyPairA, network);

    // Submit the transaction to the network
    final result = await sdk.submitTransaction(transaction);
    assert(result.success);
    print('Transaction completed: ${result.hash}');

    // Wait for the stream to receive the latest account details
    print('Waiting for stream to receive latest account details...');
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      if (accountResponses.length == 2) {
        sub.cancel();
        break;
      }
    }

    final accountResponse = accountResponses.last;
    final newBalance = double.parse(accountResponse.balances.first.balance);

    // Assert
    print('$newBalance < $oldBalance');
    assert(newBalance < oldBalance);
  }, timeout: Timeout(Duration(minutes: 1)));

  test('test account merge', () async {
    KeyPair keyPairX = KeyPair.random();
    KeyPair keyPairY = KeyPair.random();

    String accountXId = keyPairX.accountId;
    String accountYId = keyPairY.accountId;

    await FriendBot.fundTestAccount(accountXId);
    await FriendBot.fundTestAccount(accountYId);

    AccountMergeOperation accountMergeOperation =
        AccountMergeOperationBuilder(accountXId).build();

    AccountResponse accountY = await sdk.accounts.account(accountYId);
    Transaction transaction = TransactionBuilder(accountY)
        .addOperation(accountMergeOperation)
        .build();

    transaction.sign(keyPairY, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    await sdk.accounts.account(accountYId).then((response) {
      assert(false);
    }).catchError((error) {
      print(error.toString());
      assert(error is ErrorResponse && error.code == 404);
    });
  });

  test('test account merge muxed source and destination account', () async {
    KeyPair keyPairX = KeyPair.random();
    KeyPair keyPairY = KeyPair.random();

    String accountXId = keyPairX.accountId;
    String accountYId = keyPairY.accountId;

    await FriendBot.fundTestAccount(accountXId);
    await FriendBot.fundTestAccount(accountYId);

    MuxedAccount muxedDestinationAccount = MuxedAccount(accountXId, 10120291);
    MuxedAccount muxedSourceAccount = MuxedAccount(accountYId, 9999999999);

    AccountMergeOperation accountMergeOperation =
        AccountMergeOperationBuilder.forMuxedDestinationAccount(
                muxedDestinationAccount)
            .setMuxedSourceAccount(muxedSourceAccount)
            .build();

    AccountResponse accountY = await sdk.accounts.account(accountYId);
    Transaction transaction = TransactionBuilder(accountY)
        .addOperation(accountMergeOperation)
        .build();

    transaction.sign(keyPairY, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    //print(response.hash);

    await sdk.accounts.account(accountYId).then((response) {
      assert(false);
    }).catchError((error) {
      print(error.toString());
      assert(error is ErrorResponse && error.code == 404);
    });
  });

  test('test bump sequence', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);
    int startSequence = account.sequenceNumber;

    BumpSequenceOperation bumpSequenceOperation =
        BumpSequenceOperationBuilder(startSequence + 10).build();

    Transaction transaction =
        TransactionBuilder(account).addOperation(bumpSequenceOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);

    assert(startSequence + 10 == account.sequenceNumber);
  });

  test('test manage data', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    AccountResponse account = await sdk.accounts.account(accountId);

    String key = "Sommer";
    String value = "Die Möbel sind heiß!";

    List<int> list = value.codeUnits;
    Uint8List valueBytes = Uint8List.fromList(list);

    ManageDataOperation manageDataOperation =
        ManageDataOperationBuilder(key, valueBytes).build();

    Transaction transaction =
        TransactionBuilder(account).addOperation(manageDataOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);

    Uint8List resultBytes = account.data.getDecoded(key);
    String resultValue = String.fromCharCodes(resultBytes);

    assert(value == resultValue);

    manageDataOperation = ManageDataOperationBuilder(key, null).build();

    transaction =
        TransactionBuilder(account).addOperation(manageDataOperation).build();
    transaction.sign(keyPair, Network.TESTNET);

    response = await sdk.submitTransaction(transaction);
    assert(response.success);
    TestUtils.resultDeAndEncodingTest(transaction, response);

    account = await sdk.accounts.account(accountId);
    assert(!account.data.keys.contains(key));
  });

  test('test muxed account ID (M..)', () {
    String med25519AccountId =
        'MAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSAAAAAAAAAAE2LP26';
    MuxedAccount? mux = MuxedAccount.fromAccountId(med25519AccountId);
    assert(mux!.ed25519AccountId ==
        'GAQAA5L65LSYH7CQ3VTJ7F3HHLGCL3DSLAR2Y47263D56MNNGHSQSTVY');
    assert(mux!.id == 1234);
    assert(mux!.accountId == med25519AccountId);
  });

  test('stream transactions for an account', () async {
    KeyPair keyPairA = KeyPair.random();
    String accountAId = keyPairA.accountId;
    await FriendBot.fundTestAccount(accountAId);
    AccountResponse accountA = await sdk.accounts.account(accountAId);

    KeyPair keyPairB = KeyPair.random();
    String accountBId = keyPairB.accountId;

    const amountOfTransactions = 3;

    // fund account B.
    Transaction transaction = TransactionBuilder(accountA)
        .setMaxOperationFee(200000)
        .addOperation(CreateAccountOperationBuilder(accountBId, "1000").build())
        .build();
    transaction.sign(keyPairA, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    assert(response.success);

    String amount = "10";
    final eventTransactionHashes = <String>[];
    // Stream.
    var subscription = sdk.transactions
        .forAccount(accountAId)
        .cursor("now")
        .stream()
        .listen((response) async {
      assert(response.operationCount == 1);
      print("Transaction ${response.hash} event received.");
      eventTransactionHashes.add(response.hash);
    });

    //
    final transactionHashes = <String>[];

    // Execute transactions
    Future.doWhile(() async {
      AccountResponse accountB = await sdk.accounts.account(accountBId);
      transaction = TransactionBuilder(accountB)
          .setMaxOperationFee(200000)
          .addOperation(
              PaymentOperationBuilder(accountAId, Asset.NATIVE, amount).build())
          .build();
      transaction.sign(keyPairB, Network.TESTNET);
      response = await sdk.submitTransaction(transaction);
      assert(response.success);
      transactionHashes.add(response.hash!);
      print('Transaction ${response.hash} completed...');

      // Wait 1s and execute one more transaction
      await Future.delayed(Duration(seconds: 1));

      return transactionHashes.length <= amountOfTransactions;
    });

    print('Waiting for stream to receive all transaction events...');
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      if (eventTransactionHashes.length == amountOfTransactions) {
        subscription.cancel();
        break;
      }
    }

    subscription.cancel();
    assert(transactionHashes.length == amountOfTransactions);
    assert(eventTransactionHashes.length == amountOfTransactions);
    for (final hash in transactionHashes) {
      assert(eventTransactionHashes.contains(hash));
    }
  }, timeout: Timeout(Duration(minutes: 1)));
}
