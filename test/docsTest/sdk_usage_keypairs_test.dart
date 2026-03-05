@Timeout(const Duration(seconds: 600))

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  StellarSDK sdk = StellarSDK.TESTNET;

  // Shared accounts funded in setUpAll
  late KeyPair account1;
  late KeyPair account2;

  setUpAll(() async {
    account1 = KeyPair.random();
    account2 = KeyPair.random();
    await FriendBot.fundTestAccount(account1.accountId);
    await FriendBot.fundTestAccount(account2.accountId);
  });

  test('sdk-usage: Creating Keypairs', () {
    // Generate new random keypair
    KeyPair keyPair = KeyPair.random();

    expect(keyPair.accountId, startsWith('G'));
    expect(keyPair.accountId.length, 56);
    expect(keyPair.secretSeed, startsWith('S'));
    expect(keyPair.secretSeed.length, 56);

    // Create from existing secret seed
    KeyPair fromSeed = KeyPair.fromSecretSeed(keyPair.secretSeed);
    expect(fromSeed.accountId, keyPair.accountId);

    // Create public-key-only keypair (cannot sign)
    KeyPair publicOnly = KeyPair.fromAccountId(keyPair.accountId);
    expect(publicOnly.accountId, keyPair.accountId);
  });

  test('sdk-usage: Loading an Account', () async {
    AccountResponse account = await sdk.accounts.account(account1.accountId);
    expect(account.sequenceNumber, isNotNull);

    // Check balances
    bool foundNative = false;
    for (Balance balance in account.balances) {
      if (balance.assetType == Asset.TYPE_NATIVE) {
        foundNative = true;
        expect(double.parse(balance.balance), greaterThan(0));
      }
    }
    expect(foundNative, true);

    // Check if account exists (try/catch pattern)
    bool exists = true;
    try {
      await sdk.accounts.account(account1.accountId);
    } on ErrorResponse catch (e) {
      if (e.code == 404) exists = false;
    }
    expect(exists, true);

    // Non-existent account
    bool fakeExists = true;
    try {
      await sdk.accounts.account(KeyPair.random().accountId);
    } on ErrorResponse catch (e) {
      if (e.code == 404) fakeExists = false;
    }
    expect(fakeExists, false);
  });

  test('sdk-usage: Funding Testnet Accounts', () async {
    KeyPair keyPair = KeyPair.random();
    bool funded = await FriendBot.fundTestAccount(keyPair.accountId);
    expect(funded, true);
  });

  test('sdk-usage: HD Wallets (SEP-5)', () async {
    // Generate 24-word mnemonic
    String mnemonic = await Wallet.generate24WordsMnemonic();
    expect(mnemonic.split(' ').length, 24);

    // Create wallet from words
    Wallet wallet = await Wallet.from(mnemonic);

    // Derive keypairs
    KeyPair account0 = await wallet.getKeyPair(index: 0);
    KeyPair account1 = await wallet.getKeyPair(index: 1);

    expect(account0.accountId, startsWith('G'));
    expect(account1.accountId, startsWith('G'));
    expect(account0.accountId, isNot(account1.accountId));

    // Same mnemonic produces same keys
    Wallet wallet2 = await Wallet.from(mnemonic);
    KeyPair account0Again = await wallet2.getKeyPair(index: 0);
    expect(account0Again.accountId, account0.accountId);
  });

  test('sdk-usage: HD Wallets with passphrase', () async {
    String mnemonic = await Wallet.generate24WordsMnemonic();

    // With passphrase
    Wallet walletWithPass = await Wallet.from(
      mnemonic,
      passphrase: "my-secret-passphrase",
    );
    KeyPair withPass = await walletWithPass.getKeyPair(index: 0);

    // Without passphrase
    Wallet walletNoPass = await Wallet.from(mnemonic);
    KeyPair noPass = await walletNoPass.getKeyPair(index: 0);

    // Different accounts
    expect(withPass.accountId, isNot(noPass.accountId));
  });

  test('sdk-usage: Muxed Accounts', () {
    // Create muxed account from base account + ID
    MuxedAccount muxedAccount =
        MuxedAccount(account1.accountId, BigInt.from(123456789));

    expect(muxedAccount.id, BigInt.from(123456789));
    expect(muxedAccount.ed25519AccountId, account1.accountId);

    // Parse existing muxed address
    MuxedAccount? parsed =
        MuxedAccount.fromAccountId(muxedAccount.accountId);
    expect(parsed, isNotNull);
    expect(parsed!.ed25519AccountId, account1.accountId);
    expect(parsed.id, BigInt.from(123456789));
  });

  test('sdk-usage: Connecting to Networks', () {
    // Test network instances
    StellarSDK testnet = StellarSDK.TESTNET;
    StellarSDK pubnet = StellarSDK.PUBLIC;
    StellarSDK futurenet = StellarSDK.FUTURENET;

    expect(testnet, isNotNull);
    expect(pubnet, isNotNull);
    expect(futurenet, isNotNull);

    // Network passphrases
    expect(Network.TESTNET, isNotNull);
    expect(Network.PUBLIC, isNotNull);
    expect(Network.FUTURENET, isNotNull);

    // Custom horizon
    StellarSDK custom = StellarSDK("https://horizon-testnet.stellar.org");
    expect(custom, isNotNull);
  });
}
