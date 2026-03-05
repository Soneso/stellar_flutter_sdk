@Timeout(const Duration(seconds: 600))

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../tests_util.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;
  final String rpcUrl = 'https://soroban-testnet.stellar.org:443';
  final Network network = Network.TESTNET;
  final String helloContractPath =
      'test/wasm/soroban_hello_world_contract.wasm';

  group('README: Send a payment', () {
    late KeyPair senderKeyPair;
    late KeyPair receiverKeyPair;

    setUpAll(() async {
      senderKeyPair = KeyPair.random();
      receiverKeyPair = KeyPair.random();
      await FriendBot.fundTestAccount(senderKeyPair.accountId);
      await FriendBot.fundTestAccount(receiverKeyPair.accountId);
    });

    test('send XLM payment', () async {
      // Snippet from README.md "Send a payment"
      AccountResponse senderAccount =
          await sdk.accounts.account(senderKeyPair.accountId);
      String receiverId = receiverKeyPair.accountId;

      Transaction transaction = TransactionBuilder(senderAccount)
          .addOperation(
              PaymentOperationBuilder(receiverId, Asset.NATIVE, '100').build())
          .build();
      transaction.sign(senderKeyPair, Network.TESTNET);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      expect(response.success, true);

      // Verify receiver got the payment
      AccountResponse receiverAccount =
          await sdk.accounts.account(receiverKeyPair.accountId);
      for (Balance balance in receiverAccount.balances) {
        if (balance.assetType == Asset.TYPE_NATIVE) {
          expect(double.parse(balance.balance), greaterThanOrEqualTo(10100.0));
        }
      }
    });
  });

  group('README: Trust an asset', () {
    late KeyPair issuerKeyPair;
    late KeyPair accountKeyPair;

    setUpAll(() async {
      issuerKeyPair = KeyPair.random();
      accountKeyPair = KeyPair.random();
      await FriendBot.fundTestAccount(issuerKeyPair.accountId);
      await FriendBot.fundTestAccount(accountKeyPair.accountId);
    });

    test('create trustline for USDC', () async {
      // Snippet from README.md "Trust an asset"
      String issuerAccountId = issuerKeyPair.accountId;
      AccountResponse account =
          await sdk.accounts.account(accountKeyPair.accountId);

      Asset usdc = Asset.createNonNativeAsset('USDC', issuerAccountId);
      Transaction transaction = TransactionBuilder(account)
          .addOperation(ChangeTrustOperationBuilder(
                  usdc, ChangeTrustOperationBuilder.MAX_LIMIT)
              .build())
          .build();
      transaction.sign(accountKeyPair, Network.TESTNET);
      SubmitTransactionResponse response =
          await sdk.submitTransaction(transaction);

      expect(response.success, true);

      // Verify trustline was created
      AccountResponse updatedAccount =
          await sdk.accounts.account(accountKeyPair.accountId);
      bool foundUsdcTrustline = false;
      for (Balance balance in updatedAccount.balances) {
        if (balance.assetCode == 'USDC' &&
            balance.assetIssuer == issuerAccountId) {
          foundUsdcTrustline = true;
        }
      }
      expect(foundUsdcTrustline, true);
    });
  });

  group('README: Call a smart contract', () {
    late KeyPair keyPair;
    late SorobanClient helloClient;

    setUpAll(() async {
      keyPair = KeyPair.random();
      await FriendBot.fundTestAccount(keyPair.accountId);

      // Install hello contract
      final contractCode = await loadContractCode(helloContractPath);
      String wasmHash = await SorobanClient.install(
        installRequest: InstallRequest(
          wasmBytes: contractCode,
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
        ),
      );

      // Deploy hello contract
      helloClient = await SorobanClient.deploy(
        deployRequest: DeployRequest(
          rpcUrl: rpcUrl,
          network: network,
          sourceAccountKeyPair: keyPair,
          wasmHash: wasmHash,
        ),
      );
    });

    test('invoke contract method', () async {
      // Snippet from README.md "Call a smart contract"
      // SorobanClient.forClientOptions is the alternative way to create a client
      // for an already-deployed contract. Here we use the deployed client directly.
      XdrSCVal result = await helloClient.invokeMethod(
          name: 'hello', args: [XdrSCVal.forSymbol('World')]);

      expect(result, isNotNull);
    });

    test('forClientOptions constructor', () async {
      // Verify the forClientOptions factory works as shown in README
      SorobanClient client = await SorobanClient.forClientOptions(
        options: ClientOptions(
          sourceAccountKeyPair: keyPair,
          contractId: helloClient.getContractId(),
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
        ),
      );

      XdrSCVal result = await client.invokeMethod(
          name: 'hello', args: [XdrSCVal.forSymbol('World')]);

      expect(result, isNotNull);
    });
  });
}
