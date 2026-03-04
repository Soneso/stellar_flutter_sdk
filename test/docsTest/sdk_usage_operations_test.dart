@Timeout(const Duration(seconds: 600))

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  // Shared accounts funded in setUpAll
  late KeyPair account1;
  late KeyPair account2;
  late KeyPair issuer;

  setUpAll(() async {
    account1 = KeyPair.random();
    account2 = KeyPair.random();
    issuer = KeyPair.random();
    await FriendBot.fundTestAccount(account1.accountId);
    await FriendBot.fundTestAccount(account2.accountId);
    await FriendBot.fundTestAccount(issuer.accountId);
  });

  test('sdk-usage: Payment Operations', () async {
    // Native XLM payment
    PaymentOperation paymentOp = PaymentOperationBuilder(
      account2.accountId,
      Asset.NATIVE,
      "100",
    ).build();

    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    Transaction transaction = TransactionBuilder(account)
        .addOperation(paymentOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Custom asset payment
    Asset usdAsset = AssetTypeCreditAlphaNum4("USD", issuer.accountId);

    // First set up trustline on account2
    AccountResponse acct2 =
        await sdk.accounts.account(account2.accountId);
    Transaction trustTx = TransactionBuilder(acct2)
        .addOperation(ChangeTrustOperationBuilder(usdAsset, "10000").build())
        .build();
    trustTx.sign(account2, Network.TESTNET);
    await sdk.submitTransaction(trustTx);

    // Send USD from issuer
    AccountResponse issuerAcct =
        await sdk.accounts.account(issuer.accountId);
    PaymentOperation usdPayment = PaymentOperationBuilder(
      account2.accountId,
      usdAsset,
      "50.25",
    ).build();
    Transaction usdTx = TransactionBuilder(issuerAcct)
        .addOperation(usdPayment)
        .build();
    usdTx.sign(issuer, Network.TESTNET);
    SubmitTransactionResponse usdResponse =
        await sdk.submitTransaction(usdTx);
    expect(usdResponse.success, true);
  });

  test('sdk-usage: Create Account Operation', () async {
    KeyPair newAccount = KeyPair.random();
    AccountResponse sourceAccount =
        await sdk.accounts.account(account1.accountId);

    CreateAccountOperation createOp = CreateAccountOperationBuilder(
      newAccount.accountId,
      "10",
    ).build();

    Transaction transaction = TransactionBuilder(sourceAccount)
        .addOperation(createOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify
    AccountResponse created =
        await sdk.accounts.account(newAccount.accountId);
    expect(created.accountId, newAccount.accountId);
  });

  test('sdk-usage: Manage Data Operation', () async {
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);

    // Store a string value
    ManageDataOperation setDataOp = ManageDataOperationBuilder(
      "config",
      Uint8List.fromList(utf8.encode("production")),
    ).build();

    Transaction transaction = TransactionBuilder(account)
        .addOperation(setDataOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify
    AccountDataResponse data =
        await sdk.accounts.accountData(account1.accountId, "config");
    expect(data.value, isNotNull);

    // Delete entry
    account = await sdk.accounts.account(account1.accountId);
    ManageDataOperation deleteDataOp = ManageDataOperationBuilder(
      "config",
      null,
    ).build();
    Transaction deleteTx = TransactionBuilder(account)
        .addOperation(deleteDataOp)
        .build();
    deleteTx.sign(account1, Network.TESTNET);
    SubmitTransactionResponse deleteResponse =
        await sdk.submitTransaction(deleteTx);
    expect(deleteResponse.success, true);
  });

  test('sdk-usage: Set Options - Home Domain', () async {
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);

    SetOptionsOperation setDomainOp = SetOptionsOperationBuilder()
        .setHomeDomain("example.com")
        .build();

    Transaction transaction = TransactionBuilder(account)
        .addOperation(setDomainOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify
    AccountResponse updated =
        await sdk.accounts.account(account1.accountId);
    expect(updated.homeDomain, "example.com");
  });

  test('sdk-usage: Set Options - Add Signer', () async {
    KeyPair signerKeyPair = KeyPair.random();
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);

    XdrSignerKey signerKey =
        KeyPair.fromAccountId(signerKeyPair.accountId).xdrSignerKey;
    SetOptionsOperation addSignerOp = SetOptionsOperationBuilder()
        .setSigner(signerKey, 1)
        .build();

    Transaction transaction = TransactionBuilder(account)
        .addOperation(addSignerOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify signer was added
    AccountResponse updated =
        await sdk.accounts.account(account1.accountId);
    bool found = false;
    for (Signer signer in updated.signers) {
      if (signer.key == signerKeyPair.accountId) {
        found = true;
        expect(signer.weight, 1);
      }
    }
    expect(found, true);

    // Remove signer
    account = await sdk.accounts.account(account1.accountId);
    SetOptionsOperation removeSignerOp = SetOptionsOperationBuilder()
        .setSigner(signerKey, 0)
        .build();
    Transaction removeTx = TransactionBuilder(account)
        .addOperation(removeSignerOp)
        .build();
    removeTx.sign(account1, Network.TESTNET);
    await sdk.submitTransaction(removeTx);
  });

  test('sdk-usage: Change Trust Operations', () async {
    Asset testAsset = AssetTypeCreditAlphaNum4("TST", issuer.accountId);

    // Create trustline
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    ChangeTrustOperation trustOp = ChangeTrustOperationBuilder(
      testAsset,
      "10000",
    ).build();
    Transaction trustTx = TransactionBuilder(account)
        .addOperation(trustOp)
        .build();
    trustTx.sign(account1, Network.TESTNET);
    SubmitTransactionResponse trustResponse =
        await sdk.submitTransaction(trustTx);
    expect(trustResponse.success, true);

    // Modify limit
    account = await sdk.accounts.account(account1.accountId);
    ChangeTrustOperation modifyOp = ChangeTrustOperationBuilder(
      testAsset,
      "50000",
    ).build();
    Transaction modifyTx = TransactionBuilder(account)
        .addOperation(modifyOp)
        .build();
    modifyTx.sign(account1, Network.TESTNET);
    SubmitTransactionResponse modifyResponse =
        await sdk.submitTransaction(modifyTx);
    expect(modifyResponse.success, true);

    // Remove trustline
    account = await sdk.accounts.account(account1.accountId);
    ChangeTrustOperation removeTrustOp = ChangeTrustOperationBuilder(
      testAsset,
      "0",
    ).build();
    Transaction removeTx = TransactionBuilder(account)
        .addOperation(removeTrustOp)
        .build();
    removeTx.sign(account1, Network.TESTNET);
    SubmitTransactionResponse removeResponse =
        await sdk.submitTransaction(removeTx);
    expect(removeResponse.success, true);
  });

  test('sdk-usage: Manage Sell Offer', () async {
    // First create trustline and get some USD
    Asset usdAsset = AssetTypeCreditAlphaNum4("USD", issuer.accountId);

    AccountResponse account1Response =
        await sdk.accounts.account(account1.accountId);

    // Make sure account1 has USD trustline
    bool hasTrustline = false;
    for (Balance b in account1Response.balances) {
      if (b.assetCode == "USD" && b.assetIssuer == issuer.accountId) {
        hasTrustline = true;
      }
    }

    if (!hasTrustline) {
      Transaction trustTx = TransactionBuilder(account1Response)
          .addOperation(
              ChangeTrustOperationBuilder(usdAsset, "100000").build())
          .build();
      trustTx.sign(account1, Network.TESTNET);
      await sdk.submitTransaction(trustTx);
    }

    // Send some USD from issuer to account1
    AccountResponse issuerAcct =
        await sdk.accounts.account(issuer.accountId);
    Transaction sendUsd = TransactionBuilder(issuerAcct)
        .addOperation(PaymentOperationBuilder(
          account1.accountId,
          usdAsset,
          "1000",
        ).build())
        .build();
    sendUsd.sign(issuer, Network.TESTNET);
    await sdk.submitTransaction(sendUsd);

    // Create sell offer
    account1Response = await sdk.accounts.account(account1.accountId);
    ManageSellOfferOperation sellOp = ManageSellOfferOperationBuilder(
      Asset.NATIVE,
      usdAsset,
      "100",
      "0.20",
    ).build();

    Transaction transaction = TransactionBuilder(account1Response)
        .addOperation(sellOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Query offers
    Page<OfferResponse> offersPage =
        await sdk.offers.forAccount(account1.accountId).execute();
    expect(offersPage.records.isNotEmpty, true);

    // Cancel the offer
    String offerId = offersPage.records.first.id;
    account1Response = await sdk.accounts.account(account1.accountId);
    ManageSellOfferOperation cancelOp = ManageSellOfferOperationBuilder(
      Asset.NATIVE,
      usdAsset,
      "0",
      "0.20",
    ).setOfferId(offerId).build();

    Transaction cancelTx = TransactionBuilder(account1Response)
        .addOperation(cancelOp)
        .build();
    cancelTx.sign(account1, Network.TESTNET);
    SubmitTransactionResponse cancelResponse =
        await sdk.submitTransaction(cancelTx);
    expect(cancelResponse.success, true);
  });

  test('sdk-usage: Passive Sell Offer', () async {
    Asset usdAsset = AssetTypeCreditAlphaNum4("USD", issuer.accountId);

    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    CreatePassiveSellOfferOperation passiveOp =
        CreatePassiveSellOfferOperationBuilder(
      Asset.NATIVE,
      usdAsset,
      "10",
      "0.20",
    ).build();

    Transaction transaction = TransactionBuilder(account)
        .addOperation(passiveOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);
  });

  test('sdk-usage: Claimable Balance Operations', () async {
    // Create a claimable balance
    Claimant claimant = Claimant(
      account2.accountId,
      Claimant.predicateUnconditional(),
    );

    AccountResponse sourceAccount =
        await sdk.accounts.account(account1.accountId);
    CreateClaimableBalanceOperation createOp =
        CreateClaimableBalanceOperationBuilder(
      [claimant],
      Asset.NATIVE,
      "10",
    ).build();

    Transaction createTx = TransactionBuilder(sourceAccount)
        .addOperation(createOp)
        .build();
    createTx.sign(account1, Network.TESTNET);
    SubmitTransactionResponse createResponse =
        await sdk.submitTransaction(createTx);
    expect(createResponse.success, true);

    // Find claimable balances for account2
    Page<ClaimableBalanceResponse> balancesPage =
        await sdk.claimableBalances
            .forClaimant(account2.accountId)
            .execute();
    expect(balancesPage.records.isNotEmpty, true);

    // Claim it
    String balanceId = balancesPage.records.first.balanceId;
    AccountResponse claimerAccount =
        await sdk.accounts.account(account2.accountId);
    ClaimClaimableBalanceOperation claimOp =
        ClaimClaimableBalanceOperationBuilder(balanceId).build();

    Transaction claimTx = TransactionBuilder(claimerAccount)
        .addOperation(claimOp)
        .build();
    claimTx.sign(account2, Network.TESTNET);
    SubmitTransactionResponse claimResponse =
        await sdk.submitTransaction(claimTx);
    expect(claimResponse.success, true);
  });

  test('sdk-usage: Sponsorship Operations', () async {
    KeyPair sponsorKeyPair = account1;
    KeyPair newAccountKeyPair = KeyPair.random();
    String newAccountId = newAccountKeyPair.accountId;

    AccountResponse sponsorAccount =
        await sdk.accounts.account(sponsorKeyPair.accountId);

    Transaction transaction = TransactionBuilder(sponsorAccount)
        .addOperation(
          BeginSponsoringFutureReservesOperationBuilder(newAccountId)
              .build(),
        )
        .addOperation(
          CreateAccountOperationBuilder(newAccountId, "0").build(),
        )
        .addOperation(
          EndSponsoringFutureReservesOperationBuilder()
              .setSourceAccount(newAccountId)
              .build(),
        )
        .build();

    transaction.sign(sponsorKeyPair, Network.TESTNET);
    transaction.sign(newAccountKeyPair, Network.TESTNET);

    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify sponsored account exists
    AccountResponse sponsoredAccount =
        await sdk.accounts.account(newAccountId);
    expect(sponsoredAccount.accountId, newAccountId);
  });

  test('sdk-usage: Bump Sequence', () async {
    AccountResponse account =
        await sdk.accounts.account(account1.accountId);
    BigInt currentSequence = account.sequenceNumber;

    BumpSequenceOperation bumpOp = BumpSequenceOperationBuilder(
      currentSequence + BigInt.from(100),
    ).build();

    Transaction transaction = TransactionBuilder(account)
        .addOperation(bumpOp)
        .build();
    transaction.sign(account1, Network.TESTNET);
    SubmitTransactionResponse response =
        await sdk.submitTransaction(transaction);
    expect(response.success, true);

    // Verify sequence was bumped
    AccountResponse updated =
        await sdk.accounts.account(account1.accountId);
    expect(updated.sequenceNumber,
        greaterThanOrEqualTo(currentSequence + BigInt.from(100)));
  });

  test('sdk-usage: Message Signing (SEP-53)', () {
    KeyPair keyPair = KeyPair.random();

    String message = "Please sign this message to verify your identity";
    Uint8List signature = keyPair.signMessageString(message);

    expect(signature.isNotEmpty, true);

    // Verify with same keypair
    bool isValid = keyPair.verifyMessageString(message, signature);
    expect(isValid, true);

    // Verify with public key only
    KeyPair publicOnly = KeyPair.fromAccountId(keyPair.accountId);
    bool isValidPublic =
        publicOnly.verifyMessageString(message, signature);
    expect(isValidPublic, true);

    // Wrong message should fail
    bool wrongMessage =
        keyPair.verifyMessageString("wrong message", signature);
    expect(wrongMessage, false);
  });
}
