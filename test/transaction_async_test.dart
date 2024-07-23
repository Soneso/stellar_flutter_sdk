@Timeout(const Duration(seconds: 400))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  test('test submit async success', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    var account = await sdk.accounts.account(accountId);
    BigInt startSequence = account.sequenceNumber;

    var bumpSequenceOperation =
    BumpSequenceOperationBuilder(startSequence + BigInt.from(10)).build();

    var transaction =
    TransactionBuilder(account).addOperation(bumpSequenceOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    SubmitAsyncTransactionResponse response = await sdk.submitAsyncTransaction(transaction);
    assert(SubmitAsyncTransactionResponse.txStatusPending == response.txStatus);
    assert(null == response.errorResultXdrBase64);
    assert(201 == response.httpStatusCode);

    // wait a couple of seconds for the ledger to close
    await Future.delayed(Duration(seconds: 5));

    // check if the transaction was successful
    var transactionResponse = await sdk.transactions.transaction(response.hash);
    assert(transactionResponse.successful);

  });

  test('test submit async duplicate', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    var account = await sdk.accounts.account(accountId);
    BigInt startSequence = account.sequenceNumber;

    var bumpSequenceOperation =
    BumpSequenceOperationBuilder(startSequence + BigInt.from(10)).build();

    var transaction =
    TransactionBuilder(account).addOperation(bumpSequenceOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    SubmitAsyncTransactionResponse response = await sdk.submitAsyncTransaction(transaction);
    assert(SubmitAsyncTransactionResponse.txStatusPending == response.txStatus);

    response = await sdk.submitAsyncTransaction(transaction);
    assert(SubmitAsyncTransactionResponse.txStatusDuplicate == response.txStatus);
    assert(409 == response.httpStatusCode);

    // wait a couple of seconds for the ledger to close
    await Future.delayed(Duration(seconds: 5));

    // check if the transaction was successful
    var transactionResponse = await sdk.transactions.transaction(response.hash);
    assert(transactionResponse.successful);

  });

  test('test submit async malformed', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    var account = await sdk.accounts.account(accountId);
    BigInt startSequence = account.sequenceNumber;

    var bumpSequenceOperation =
    BumpSequenceOperationBuilder(startSequence + BigInt.from(10)).build();

    var transaction =
    TransactionBuilder(account).addOperation(bumpSequenceOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    var envelopeXdrBase64 = transaction.toEnvelopeXdrBase64();
    envelopeXdrBase64 = envelopeXdrBase64.substring(0, envelopeXdrBase64.length - 10);

    bool thrown = false;
    try {
      await sdk.submitAsyncTransactionEnvelopeXdrBase64(envelopeXdrBase64);
    } catch (e) {
      assert(e is SubmitAsyncTransactionProblem);
      var problem = e as SubmitAsyncTransactionProblem;
      assert(400 == problem.status);
      thrown = true;
    }
    assert(thrown);

  });

  test('test submit async error', () async {
    KeyPair keyPair = KeyPair.random();
    String accountId = keyPair.accountId;

    await FriendBot.fundTestAccount(accountId);

    // set invalid sequence number to produce error.
    var account = Account(accountId, BigInt.from(100000000));
    BigInt startSequence = account.sequenceNumber;

    var bumpSequenceOperation =
    BumpSequenceOperationBuilder(startSequence + BigInt.from(10)).build();

    var transaction =
    TransactionBuilder(account).addOperation(bumpSequenceOperation).build();

    transaction.sign(keyPair, Network.TESTNET);

    SubmitAsyncTransactionResponse response = await sdk
        .submitAsyncTransaction(transaction);
    assert(SubmitAsyncTransactionResponse.txStatusError == response.txStatus);
    assert(400 == response.httpStatusCode);
    assert(null != response.errorResultXdrBase64);
    assert(null != response.transactionErrorResultXdr);

  });
}