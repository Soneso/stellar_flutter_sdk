// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Live gate for signing on OpenZeppelin stellar-accounts wallets on testnet.
//
// Every case deploys a wallet of its own from a Friendbot-funded deployer,
// with one signer on the Default rule, and funds it with native asset through
// the asset contract before it signs. A case passes only when the network
// accepts the signatures the SDK produced, so a passing transfer proves that
// the signer signed the digest the wallet's code checks.
//
// - Case A: passkey signer created through `createWallet`, one transfer
//   through `transfer`.
// - Case B: Ed25519 External signer set by the constructor, one transfer
//   through the multi-signer path. On a 0.8.0 wallet, case F follows on the
//   entry B signed: the wallet's `auth_digest` view is simulated for that
//   entry and compared with the local digest.
// - Case C: Delegated signer (a Friendbot-funded account) set by the
//   constructor, one transfer through the multi-signer path.
// - Case D: as B; the signer adds a `CallContract` rule for the native asset
//   contract with a second Ed25519 signer and a spending-limit policy, the
//   second signer transfers under the limit with that rule selected
//   explicitly, and a transfer over the limit is rejected.
// - Case E (0.8.0 only): as B; the signer adds a `CreateContractExternalRef`
//   rule with a second Ed25519 signer, and the second signer deploys a
//   contract by that external reference with the rule found by resolution.
//
// The 0.7 regression runs cases A to D on wallets of the stellar-accounts
// 0.7.0 build. The smoke test runs a deployment and a transfer through the
// Soneso relayer proxy and two lookups on the Mercury indexer.
//
// The software passkey (_SoftwareP256WebAuthnProvider) signs with
// pointycastle. Every key is generated at run time and never printed; the
// `RESULT` lines name the case, the wallet and the transaction hash or the
// error. Run one case at a time from the repository root, for example:
// flutter test test/integration/smartaccount/oz/oz_auth_digest_live_test.dart --plain-name 'v080 case A'

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../../../tests_util.dart';
import '../../../unit/smartaccount/oz/oz_auth_digest_fixtures.dart';

/// An account build with the spending-limit policy its rules use.
class _AccountBuild {
  const _AccountBuild(this.label, this.wasmHash, this.spendingLimitPolicy);

  final String label;
  final String wasmHash;
  final String spendingLimitPolicy;
}

const String _rpcUrl = 'https://soroban-testnet.stellar.org';
const String _webauthnVerifier =
    'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY';
const String _ed25519Verifier =
    'CAW2Z46INPO5VIJEILMYSSEOLBVJIIII5GOE3TN5EUURSRM2FJCF7AJ6';
const String _relayerUrl =
    'https://smart-account-relayer-proxy.soneso.workers.dev';

const String _v080WasmHash =
    'c514d35ea67eaea9bfc1fb3327854c0c06111bc1ddebd4fe217c504c1004b9e1';
const String _v080SpendingLimit =
    'CC3CEYQAP6NPNFIYSWL5MVZRCPJZGWX4XO7WDEJOUVGO2FZX5OONYPA5';
const String _v070WasmHash =
    '86b49fe03f7df0ad1c2a28bd8361b923ab57096e09f397f92f0c00ae3bd06d28';
const String _v070SpendingLimit =
    'CBQE7L3UNP5IR4I7IBKLS7NV256WHR5TTH26HTMUIK7WXJC6J64RSE2L';

const _AccountBuild _v080 = _AccountBuild(
  '0.8.0',
  _v080WasmHash,
  _v080SpendingLimit,
);
const _AccountBuild _v070 = _AccountBuild(
  '0.7.0',
  _v070WasmHash,
  _v070SpendingLimit,
);

/// The 0.7.0 build with the 0.8.0 spending-limit policy on its rule.
const _AccountBuild _v070WithV080Policy = _AccountBuild(
  '0.7.0 with the 0.8.0 spending limit',
  _v070WasmHash,
  _v080SpendingLimit,
);

/// Spending limit of case D: 10 XLM in stroops per day.
final BigInt _spendingLimitStroops = BigInt.from(100000000);
const int _spendingPeriodLedgers = 17280;

const Timeout _liveTimeout = Timeout(Duration(minutes: 9));

final Network _network = Network.TESTNET;
final Random _random = Random.secure();

void main() {
  // 0.8.0 cases

  test('v080 case A', timeout: _liveTimeout, () => _caseA(_v080));

  test('v080 case B and case F', timeout: _liveTimeout, () async {
    final signed = await _caseB(_v080);
    await _caseF(signed);
  });

  test('v080 case C', timeout: _liveTimeout, () => _caseC(_v080));

  test('v080 case D', timeout: _liveTimeout, () => _caseD(_v080));

  test('v080 case E', timeout: _liveTimeout, () => _caseE(_v080));

  // 0.7 regression

  test('v070 case A', timeout: _liveTimeout, () => _caseA(_v070));

  test('v070 case B', timeout: _liveTimeout, () async {
    await _caseB(_v070);
  });

  test('v070 case C', timeout: _liveTimeout, () => _caseC(_v070));

  test('v070 case D', timeout: _liveTimeout, () => _caseD(_v070));

  test(
    'v070 with the 0.8.0 spending limit case D',
    timeout: _liveTimeout,
    () => _caseD(_v070WithV080Policy),
  );

  // Relayer proxy and indexer

  test('smoke relayer and indexer', timeout: _liveTimeout, _smoke);
}

// Cases

Future<void> _caseA(_AccountBuild build) async {
  final deployer = await _fundedAccount();
  final kit = _kit(
    build,
    deployer,
    webauthnProvider: _SoftwareP256WebAuthnProvider(),
  );
  try {
    final created = await kit.walletOperations.createWallet(
      userName: 'Case A',
      autoSubmit: true,
      autoFund: true,
      nativeTokenContract: _nativeAssetContract(),
    );
    final transfer = await kit.transactionOperations.transfer(
      tokenContract: _nativeAssetContract(),
      recipient: deployer.accountId,
      amount: '1',
    );
    _requireSuccess('A', build, created.contractId, transfer);
  } finally {
    await kit.close();
  }
}

/// Runs case B and returns the wallet with the auth entry its signer signed.
Future<_SignedWalletEntry> _caseB(_AccountBuild build) async {
  final deployer = await _fundedAccount();
  final kit = _kit(build, deployer);
  try {
    final publicKey = kit.externalSigners.addEd25519FromRawKey(
      secretKeyBytes: _randomBytes(32),
      verifierAddress: _ed25519Verifier,
    );
    final walletId = await _deployWallet(
      deployer,
      build,
      <OZSmartAccountSigner>[OZExternalSigner(_ed25519Verifier, publicKey)],
    );
    await kit.walletOperations.connectToContract(walletId);
    await kit.transactionOperations.fundWallet(
      nativeTokenContract: _nativeAssetContract(),
    );
    final transfer = await kit.multiSignerManager.multiSignerTransfer(
      tokenContract: _nativeAssetContract(),
      recipient: deployer.accountId,
      amount: '1',
      selectedSigners: <OZSelectedSigner>[
        OZSelectedSignerEd25519(
          verifierAddress: _ed25519Verifier,
          publicKey: publicKey,
        ),
      ],
    );
    final hash = _requireSuccess('B', build, walletId, transfer);
    return _SignedWalletEntry(
      walletId: walletId,
      source: deployer,
      entry: await _walletEntryOf(hash, walletId),
      ed25519PublicKey: publicKey,
    );
  } finally {
    await kit.close();
  }
}

Future<void> _caseC(_AccountBuild build) async {
  final deployer = await _fundedAccount();
  final delegate = await _fundedAccount();
  final kit = _kit(build, deployer);
  try {
    // The in-memory registry signs for the Delegated account.
    await kit.externalSigners.addFromSecret(delegate.secretSeed);
    final walletId = await _deployWallet(
      deployer,
      build,
      <OZSmartAccountSigner>[OZDelegatedSigner(delegate.accountId)],
    );
    await kit.walletOperations.connectToContract(walletId);
    await kit.transactionOperations.fundWallet(
      nativeTokenContract: _nativeAssetContract(),
    );
    final transfer = await kit.multiSignerManager.multiSignerTransfer(
      tokenContract: _nativeAssetContract(),
      recipient: deployer.accountId,
      amount: '1',
      selectedSigners: <OZSelectedSigner>[
        OZSelectedSignerWallet(delegate.accountId),
      ],
    );
    _requireSuccess('C', build, walletId, transfer);
  } finally {
    await kit.close();
  }
}

Future<void> _caseD(_AccountBuild build) async {
  final deployer = await _fundedAccount();
  final kit = _kit(build, deployer);
  try {
    final firstKey = kit.externalSigners.addEd25519FromRawKey(
      secretKeyBytes: _randomBytes(32),
      verifierAddress: _ed25519Verifier,
    );
    final secondKey = kit.externalSigners.addEd25519FromRawKey(
      secretKeyBytes: _randomBytes(32),
      verifierAddress: _ed25519Verifier,
    );
    final walletId = await _deployWallet(
      deployer,
      build,
      <OZSmartAccountSigner>[OZExternalSigner(_ed25519Verifier, firstKey)],
    );
    await kit.walletOperations.connectToContract(walletId);
    await kit.transactionOperations.fundWallet(
      nativeTokenContract: _nativeAssetContract(),
    );

    const ruleName = 'Case D spending';
    final added = await kit.contextRuleManager.addContextRule(
      contextType: OZContextRuleTypeCallContract(_nativeAssetContract()),
      name: ruleName,
      signers: <OZSmartAccountSigner>[
        OZExternalSigner(_ed25519Verifier, secondKey),
      ],
      policies: <String, OZPolicyInstallParams>{
        build.spendingLimitPolicy: OZSpendingLimitPolicyParams(
          spendingLimit: _spendingLimitStroops,
          periodLedgers: _spendingPeriodLedgers,
        ),
      },
      selectedSigners: <OZSelectedSigner>[
        OZSelectedSignerEd25519(
          verifierAddress: _ed25519Verifier,
          publicKey: firstKey,
        ),
      ],
    );
    _requireSuccess('D-add-rule', build, walletId, added);

    final rule = (await kit.contextRuleManager.listContextRules()).singleWhere(
      (candidate) => candidate.name == ruleName,
    );
    expect(rule.policies, <String>[
      build.spendingLimitPolicy,
    ], reason: 'the rule must carry the spending limit');
    final secondSigner = <OZSelectedSigner>[
      OZSelectedSignerEd25519(
        verifierAddress: _ed25519Verifier,
        publicKey: secondKey,
      ),
    ];

    final underLimit = await kit.multiSignerManager.multiSignerTransfer(
      tokenContract: _nativeAssetContract(),
      recipient: deployer.accountId,
      amount: '1',
      selectedSigners: secondSigner,
      resolveContextRuleIds: (_, _) async => <int>[rule.id],
    );
    _requireSuccess('D-under-limit', build, walletId, underLimit);

    OZTransactionResult? overLimit;
    String? failure;
    try {
      overLimit = await kit.multiSignerManager.multiSignerTransfer(
        tokenContract: _nativeAssetContract(),
        recipient: deployer.accountId,
        amount: '20',
        selectedSigners: secondSigner,
        resolveContextRuleIds: (_, _) async => <int>[rule.id],
      );
      if (!overLimit.success) failure = overLimit.error;
    } catch (e) {
      failure = '$e';
    }
    _result(
      'D-over-limit',
      build,
      walletId,
      error: failure ?? 'accepted: $overLimit',
    );
    expect(
      failure,
      isNotNull,
      reason: 'a transfer over the limit must be rejected, got: $overLimit',
    );
    final decoded = OZContractErrorCodes.decodeFromMessage(failure);
    expect(
      decoded,
      isNotNull,
      reason: 'the rejection must name a contract error, got: $failure',
    );
    expect(
      decoded!.code,
      3221,
      reason: 'the rejection must be SpendingLimitExceeded, got: $failure',
    );
  } finally {
    await kit.close();
  }
}

Future<void> _caseE(_AccountBuild build) async {
  final deployer = await _fundedAccount();
  final kit = _kit(build, deployer);
  final server = SorobanServer(_rpcUrl);
  try {
    final firstKey = kit.externalSigners.addEd25519FromRawKey(
      secretKeyBytes: _randomBytes(32),
      verifierAddress: _ed25519Verifier,
    );
    final secondKey = kit.externalSigners.addEd25519FromRawKey(
      secretKeyBytes: _randomBytes(32),
      verifierAddress: _ed25519Verifier,
    );
    final walletId = await _deployWallet(
      deployer,
      build,
      <OZSmartAccountSigner>[OZExternalSigner(_ed25519Verifier, firstKey)],
    );
    await kit.walletOperations.connectToContract(walletId);

    // The owner fixture holds the tag for the hello world contract's code.
    final ownerWasmHash = await SorobanClient.install(
      installRequest: InstallRequest(
        wasmBytes: await loadContractCode('test/wasm/p28_owner_fixture.wasm'),
        sourceAccountKeyPair: deployer,
        network: _network,
        rpcUrl: _rpcUrl,
        server: server,
      ),
    );
    final owner = await SorobanClient.deploy(
      deployRequest: DeployRequest(
        sourceAccountKeyPair: deployer,
        network: _network,
        rpcUrl: _rpcUrl,
        wasmHash: ownerWasmHash,
        server: server,
      ),
    );
    final helloWasmHash = await SorobanClient.install(
      installRequest: InstallRequest(
        wasmBytes: await loadContractCode(
          'test/wasm/soroban_hello_world_contract.wasm',
        ),
        sourceAccountKeyPair: deployer,
        network: _network,
        rpcUrl: _rpcUrl,
        server: server,
      ),
    );
    final tag = 'sa08-live-${Util.bytesToHex(_randomBytes(4))}';
    await owner.invokeMethod(
      name: 'set_executable',
      args: <XdrSCVal>[
        XdrSCVal.forString(tag),
        XdrSCVal.forBytes(Util.hexToBytes(helloWasmHash)),
      ],
    );
    final ownerId = owner.getContractId();

    const ruleName = 'Case E reference';
    final added = await kit.contextRuleManager.addContextRule(
      contextType: OZBuilders.createCreateContractExternalRefContextType(
        ownerId,
        tag,
      ),
      name: ruleName,
      signers: <OZSmartAccountSigner>[
        OZExternalSigner(_ed25519Verifier, secondKey),
      ],
      selectedSigners: <OZSelectedSigner>[
        OZSelectedSignerEd25519(
          verifierAddress: _ed25519Verifier,
          publicKey: firstKey,
        ),
      ],
    );
    _requireSuccess('E-add-rule', build, walletId, added);

    final rule = (await kit.contextRuleManager.listContextRules()).singleWhere(
      (candidate) => candidate.name == ruleName,
    );
    final ruleType = rule.contextType;
    expect(ruleType, isA<OZContextRuleTypeCreateContractExternalRef>());
    ruleType as OZContextRuleTypeCreateContractExternalRef;
    expect(
      ruleType.owner,
      ownerId,
      reason: 'the listed rule must name the owner',
    );
    expect(ruleType.tag, tag, reason: 'the listed rule must name the tag');

    final salt = _randomBytes(32);
    final deployment = CreateContractFromExternalRefHostFunction.forTagString(
      Address.forContractId(walletId),
      Address.forContractId(ownerId),
      tag,
      salt: XdrUint256(salt),
    );
    final deployed = await kit.multiSignerManager.submitWithMultipleSigners(
      hostFunction: deployment.toXdr(),
      selectedSigners: <OZSelectedSigner>[
        OZSelectedSignerEd25519(
          verifierAddress: _ed25519Verifier,
          publicKey: secondKey,
        ),
      ],
    );
    _requireSuccess('E-deploy-by-reference', build, walletId, deployed);

    final createdId = Address.deriveContractId(
      deployer: Address.forContractId(walletId),
      salt: salt,
      network: _network,
    );
    final hello = await SorobanClient.forClientOptions(
      options: ClientOptions(
        sourceAccountKeyPair: deployer,
        contractId: createdId,
        network: _network,
        rpcUrl: _rpcUrl,
      )..server = server,
    );
    final answer = await hello.invokeMethod(
      name: 'hello',
      args: <XdrSCVal>[XdrSCVal.forSymbol('friend')],
    );
    final words = <String?>[for (final word in answer.vec!) word.sym];
    print(
      'RESULT case=E-hello build=${build.label} contract=$createdId '
      'answer=$words',
    );
    expect(words, <String>[
      'Hello',
      'friend',
    ], reason: 'the contract deployed by reference must answer');
  } finally {
    server.close();
    await kit.close();
  }
}

/// Case F: the wallet's `auth_digest` view, simulated for the preimage of the
/// entry case B signed, returns the digest the SDK computes for that entry,
/// the digest built from the stellar-accounts definition, and the digest the
/// entry's Ed25519 signature verifies over.
Future<void> _caseF(_SignedWalletEntry signed) async {
  final credentials = _addressCredentials(signed.entry);
  expect(
    credentials,
    isNotNull,
    reason: 'the wallet entry must carry address credentials',
  );
  final payload = OZSmartAccountAuthPayloadCodec.read(credentials!.signature);
  final local = await OZSmartAccountAuth.computeEntryAuthDigest(
    signed.entry,
    credentials.signatureExpirationLedger.uint32,
    _network.networkPassphrase,
    payload.contextRuleIds,
    OZAuthDigestScheme.preimageV1,
  );
  final preimage = IndependentAuthDigest.preimage(
    signed.walletId,
    local.signaturePayload,
    payload.contextRuleIds,
  );
  final independent = IndependentAuthDigest.preimageDigest(
    signed.walletId,
    local.signaturePayload,
    payload.contextRuleIds,
  );

  final view = await _simulateView(
    signed.source,
    signed.walletId,
    'auth_digest',
    <XdrSCVal>[preimage],
  );
  expect(
    view.discriminant,
    XdrSCValType.SCV_BYTES,
    reason: 'auth_digest must return bytes',
  );
  final contractDigest = Uint8List.fromList(view.bytes!.sCBytes);

  expect(payload.signers, hasLength(1));
  final signature = payload.signers.values.single;
  final signatureVerifies = KeyPair.fromPublicKey(
    signed.ed25519PublicKey,
  ).verify(contractDigest, signature);

  print(
    'RESULT case=F build=0.8.0 wallet=${signed.walletId} '
    'ruleIds=${payload.contextRuleIds} '
    'signaturePayload=${Util.bytesToHex(local.signaturePayload)} '
    'contract=${Util.bytesToHex(contractDigest)} '
    'local=${Util.bytesToHex(local.authDigest)} '
    'independent=${Util.bytesToHex(independent)} '
    'signatureVerifies=$signatureVerifies',
  );
  expect(
    local.authDigest,
    contractDigest,
    reason: "the SDK digest must equal the contract's",
  );
  expect(
    independent,
    contractDigest,
    reason: "the definition's digest must equal the contract's",
  );
  expect(local.delegatedAuthArgs.map(scValXdrBase64).toList(), <String>[
    scValXdrBase64(preimage),
  ], reason: 'a Delegated signer authorizes the preimage');
  expect(
    signatureVerifies,
    isTrue,
    reason: "the signer's signature must verify over the contract's digest",
  );
}

Future<void> _smoke() async {
  final deployer = await _fundedAccount();

  // A passkey wallet deployed by createWallet through the relayer.
  final passkeyKit = _kit(
    _v080,
    deployer,
    webauthnProvider: _SoftwareP256WebAuthnProvider(),
    relayerUrl: _relayerUrl,
  );
  final OZCreateWalletResult passkeyWallet;
  try {
    passkeyWallet = await passkeyKit.walletOperations.createWallet(
      userName: 'Relayer smoke',
      autoSubmit: true,
    );
    _result(
      'smoke-relayer-deploy',
      _v080,
      passkeyWallet.contractId,
      hash: passkeyWallet.transactionHash,
    );
    expect(
      passkeyWallet.transactionHash,
      isNotNull,
      reason: 'the relayer deployment must report a transaction hash',
    );
  } finally {
    await passkeyKit.close();
  }

  // An Ed25519 wallet deployed through the relayer and one transfer through
  // it.
  final ed25519Kit = _kit(_v080, deployer, relayerUrl: _relayerUrl);
  final relayer = OZRelayerClient(_relayerUrl);
  final String ed25519Wallet;
  try {
    final publicKey = ed25519Kit.externalSigners.addEd25519FromRawKey(
      secretKeyBytes: _randomBytes(32),
      verifierAddress: _ed25519Verifier,
    );
    ed25519Wallet = await _deployWallet(deployer, _v080, <OZSmartAccountSigner>[
      OZExternalSigner(_ed25519Verifier, publicKey),
    ], relayer: relayer);
    await ed25519Kit.walletOperations.connectToContract(ed25519Wallet);
    await ed25519Kit.transactionOperations.fundWallet(
      nativeTokenContract: _nativeAssetContract(),
    );
    final transfer = await ed25519Kit.multiSignerManager.multiSignerTransfer(
      tokenContract: _nativeAssetContract(),
      recipient: deployer.accountId,
      amount: '1',
      selectedSigners: <OZSelectedSigner>[
        OZSelectedSignerEd25519(
          verifierAddress: _ed25519Verifier,
          publicKey: publicKey,
        ),
      ],
    );
    _requireSuccess('smoke-relayer-transfer', _v080, ed25519Wallet, transfer);
  } finally {
    await relayer.close();
    await ed25519Kit.close();
  }

  // The indexer returns the Ed25519 wallet under its verifier and the passkey
  // wallet under its credential.
  final indexer = OZIndexerClient.forNetwork(_network.networkPassphrase);
  expect(indexer, isNotNull, reason: 'testnet must have a default indexer');
  try {
    await _awaitIndexed(
      'smoke-indexer-address',
      ed25519Wallet,
      () async => (await indexer!.lookupByAddress(
        _ed25519Verifier,
      )).contracts.map((contract) => contract.contractId).toList(),
    );
    await _awaitIndexed(
      'smoke-indexer-credential',
      passkeyWallet.contractId,
      () async => (await indexer!.lookupByCredentialId(
        passkeyWallet.credentialId,
      )).contracts.map((contract) => contract.contractId).toList(),
    );
  } finally {
    await indexer!.close();
  }
}

// Helpers

/// A wallet with the auth entry its Ed25519 signer signed in a confirmed
/// transaction.
class _SignedWalletEntry {
  const _SignedWalletEntry({
    required this.walletId,
    required this.source,
    required this.entry,
    required this.ed25519PublicKey,
  });

  final String walletId;
  final KeyPair source;
  final XdrSorobanAuthorizationEntry entry;
  final Uint8List ed25519PublicKey;
}

Uint8List _randomBytes(int length) =>
    Uint8List.fromList(List<int>.generate(length, (_) => _random.nextInt(256)));

Future<KeyPair> _fundedAccount() async {
  final account = KeyPair.random();
  final server = SorobanServer(_rpcUrl);
  try {
    await fundTestAccountAndAwaitVisibility(account.accountId, rpc: server);
  } finally {
    server.close();
  }
  return account;
}

/// The contract of the native asset on testnet, derived from its asset
/// preimage.
String _nativeAssetContract() {
  final preimage = XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID)
    ..contractID = XdrHashIDPreimageContractID(
      XdrHash(_network.networkId),
      XdrContractIDPreimage.forAsset(Asset.NATIVE.toXdr()),
    );
  final stream = XdrDataOutputStream();
  XdrHashIDPreimage.encode(stream, preimage);
  return StrKey.encodeContractId(
    Uint8List.fromList(
      crypto.sha256.convert(Uint8List.fromList(stream.bytes)).bytes,
    ),
  );
}

OZSmartAccountKit _kit(
  _AccountBuild build,
  KeyPair deployer, {
  WebAuthnProvider? webauthnProvider,
  String? relayerUrl,
}) => OZSmartAccountKit.create(
  config: OZSmartAccountConfig(
    rpcUrl: _rpcUrl,
    networkPassphrase: _network.networkPassphrase,
    accountWasmHash: build.wasmHash,
    webauthnVerifierAddress: _webauthnVerifier,
    deployerKeypair: deployer,
    webauthnProvider: webauthnProvider,
    relayerUrl: relayerUrl,
  ),
);

/// Deploys a wallet of [build] whose Default rule holds [signers], from
/// [deployer] with a random salt, directly or through [relayer], and returns
/// its address once it is confirmed.
Future<String> _deployWallet(
  KeyPair deployer,
  _AccountBuild build,
  List<OZSmartAccountSigner> signers, {
  OZRelayerClient? relayer,
}) async {
  final salt = _randomBytes(32);
  final deployerAddress = Address.forAccountId(deployer.accountId);
  final hostFunction = CreateContractWithConstructorHostFunction(
    deployerAddress,
    build.wasmHash,
    <XdrSCVal>[
      XdrSCVal.forVec(<XdrSCVal>[for (final s in signers) s.toScVal()]),
      OZPolicyManager.policiesToScVal(const <String, XdrSCVal>{}),
    ],
    salt: XdrUint256(salt),
  );
  final walletId = Address.deriveContractId(
    deployer: deployerAddress,
    salt: salt,
    network: _network,
  );
  final server = SorobanServer(_rpcUrl);
  try {
    final account = await server.getAccount(deployer.accountId);
    expect(account, isNotNull, reason: 'the deployer account must exist');
    final transaction = TransactionBuilder(account!)
        .setMaxOperationFee(AbstractTransaction.MIN_BASE_FEE)
        .addOperation(InvokeHostFunctionOperation(hostFunction))
        .addMemo(Memo.none())
        // The relayer refuses transactions valid for more than 60 seconds.
        .addPreconditions(
          TransactionPreconditions()
            ..timeBounds = TimeBounds(
              0,
              DateTime.now().millisecondsSinceEpoch ~/ 1000 +
                  OZConstants.defaultTimeoutSeconds,
            ),
        )
        .build();
    final simulation = await server.simulateTransaction(
      SimulateTransactionRequest(transaction),
    );
    expect(
      simulation.resultError ?? simulation.error?.message,
      isNull,
      reason: 'the deployment of $walletId must simulate',
    );
    final minResourceFee = simulation.minResourceFee;
    expect(
      minResourceFee,
      isNotNull,
      reason: 'the simulation must name the resource fee',
    );
    transaction.sorobanTransactionData = simulation.transactionData;
    final auth = simulation.getSorobanAuth();
    if (auth != null) transaction.setSorobanAuth(auth);

    final String hash;
    if (relayer == null) {
      transaction.addResourceFee(minResourceFee!);
      transaction.sign(deployer, _network);
      final sent = await server.sendTransaction(transaction);
      expect(
        sent.hash,
        isNotNull,
        reason:
            'the deployment of $walletId must be accepted, got: '
            '${sent.status} ${sent.error?.message} ${sent.errorResultXdr}',
      );
      hash = sent.hash!;
    } else {
      // The relayer wraps the transaction in a fee bump, so its own fee is
      // the resource fee.
      transaction.fee = minResourceFee!;
      transaction.sign(deployer, _network);
      final response = await relayer.sendXdr(transaction.toEnvelopeXdr());
      expect(
        response.success,
        isTrue,
        reason:
            'the relayer must accept the deployment of $walletId, got: '
            '${response.error}',
      );
      expect(
        response.hash,
        isNotNull,
        reason: 'the relayer must report the deployment hash',
      );
      hash = response.hash!;
    }
    final confirmed = await server.pollTransaction(hash, maxAttempts: 60);
    expect(
      confirmed.status,
      GetTransactionResponse.STATUS_SUCCESS,
      reason:
          'the deployment $hash of $walletId must succeed, got: '
          '${confirmed.status}',
    );
    print(
      'RESULT case=deploy build=${build.label} wallet=$walletId tx=$hash'
      '${relayer != null ? ' via=relayer' : ''}',
    );
  } finally {
    server.close();
  }
  return walletId;
}

/// The address credentials of [entry], for the legacy and the upgraded arm.
XdrSorobanAddressCredentials? _addressCredentials(
  XdrSorobanAuthorizationEntry entry,
) {
  final credentials = entry.credentials;
  switch (credentials.discriminant) {
    case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
      return credentials.address;
    case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
      return credentials.addressV2;
    default:
      return null;
  }
}

/// The entry of [walletId] in the confirmed transaction [hash], as the
/// network received it.
Future<XdrSorobanAuthorizationEntry> _walletEntryOf(
  String hash,
  String walletId,
) async {
  final server = SorobanServer(_rpcUrl);
  try {
    final response = await server.pollTransaction(hash, maxAttempts: 60);
    final envelope = response.envelopeXdr;
    expect(
      envelope,
      isNotNull,
      reason: 'transaction $hash must carry its envelope',
    );
    final parsed = AbstractTransaction.fromEnvelopeXdrString(envelope!);
    final transaction = parsed is FeeBumpTransaction
        ? parsed.innerTransaction
        : parsed as Transaction;
    final operation = transaction.operations.single;
    expect(operation, isA<InvokeHostFunctionOperation>());
    return (operation as InvokeHostFunctionOperation).auth
        .map((entry) => entry.toXdr())
        .singleWhere(
          (entry) => _addressCredentials(entry)?.address.toStrKey() == walletId,
        );
  } finally {
    server.close();
  }
}

/// Simulates [functionName] of [contractId] with [args] from [source] and
/// returns its return value.
Future<XdrSCVal> _simulateView(
  KeyPair source,
  String contractId,
  String functionName,
  List<XdrSCVal> args,
) async {
  final server = SorobanServer(_rpcUrl);
  try {
    final account = await server.getAccount(source.accountId);
    expect(account, isNotNull, reason: 'the source account must exist');
    final transaction = TransactionBuilder(account!)
        .addOperation(
          InvokeHostFunctionOperation(
            InvokeContractHostFunction(
              contractId,
              functionName,
              arguments: args,
            ),
          ),
        )
        .build();
    final simulation = await server.simulateTransaction(
      SimulateTransactionRequest(transaction),
    );
    expect(
      simulation.resultError ?? simulation.error?.message,
      isNull,
      reason: '$functionName of $contractId must simulate',
    );
    final value = simulation.results?.single.resultValue;
    expect(value, isNotNull, reason: '$functionName must return a value');
    return value!;
  } finally {
    server.close();
  }
}

/// Polls the indexer until [lookup] lists [contractId], for at most three
/// minutes.
Future<void> _awaitIndexed(
  String caseName,
  String contractId,
  Future<List<String>> Function() lookup,
) async {
  var listed = <String>[];
  for (var attempt = 1; attempt <= 18; attempt++) {
    listed = await lookup();
    if (listed.contains(contractId)) {
      print(
        'RESULT case=$caseName wallet=$contractId '
        'listedAfterAttempts=$attempt count=${listed.length}',
      );
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 10));
  }
  print(
    'RESULT case=$caseName wallet=$contractId error=not listed after 18 '
    'lookups, count=${listed.length}',
  );
  fail(
    'the indexer must list $contractId, got ${listed.length} contracts '
    'without it',
  );
}

String _requireSuccess(
  String caseName,
  _AccountBuild build,
  String walletId,
  OZTransactionResult outcome,
) {
  _result(
    caseName,
    build,
    walletId,
    hash: outcome.hash,
    error: outcome.success ? null : outcome.error,
  );
  expect(
    outcome.success,
    isTrue,
    reason:
        'case $caseName on ${build.label} must succeed, got: '
        '${outcome.error}',
  );
  expect(
    outcome.hash,
    isNotNull,
    reason: 'case $caseName on ${build.label} must report a transaction hash',
  );
  return outcome.hash!;
}

void _result(
  String caseName,
  _AccountBuild build,
  String walletId, {
  String? hash,
  String? error,
}) {
  print(
    'RESULT case=$caseName build=${build.label} wallet=$walletId '
    '${error != null ? 'error=$error' : 'tx=$hash'}',
  );
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A WebAuthn authenticator in software: a P-256 key generated per
/// registration, assertions with the user present and user verified flags
/// over client data that carries the challenge as given. Signatures are DER
/// encoded, as a platform authenticator returns them.
class _SoftwareP256WebAuthnProvider extends WebAuthnProvider {
  Uint8List? _credentialId;
  pc.ECPrivateKey? _privateKey;

  @override
  Future<WebAuthnRegistrationResult> register({
    required Uint8List challenge,
    required Uint8List userId,
    required String userName,
  }) async {
    final secureRandom = pc.FortunaRandom()
      ..seed(pc.KeyParameter(_randomBytes(32)));
    final generator = pc.ECKeyGenerator()
      ..init(
        pc.ParametersWithRandom(
          pc.ECKeyGeneratorParameters(pc.ECCurve_secp256r1()),
          secureRandom,
        ),
      );
    final keyPair = generator.generateKeyPair();
    final id = _randomBytes(16);
    _credentialId = id;
    _privateKey = keyPair.privateKey;
    return WebAuthnRegistrationResult(
      credentialId: id,
      publicKey: keyPair.publicKey.Q!.getEncoded(false),
      attestationObject: Uint8List(0),
      transports: const <String>['internal'],
      deviceType: 'singleDevice',
      backedUp: false,
    );
  }

  @override
  Future<WebAuthnAuthenticationResult> authenticate({
    required Uint8List challenge,
    List<WebAuthnAllowCredential>? allowCredentials,
  }) async {
    final id = _credentialId;
    final key = _privateKey;
    if (id == null || key == null) {
      throw StateError('authenticate called before register');
    }
    if (allowCredentials != null &&
        !allowCredentials.any((credential) => _bytesEqual(credential.id, id))) {
      throw StateError(
        'the allowed credentials do not include the registered one',
      );
    }
    final clientDataJson = Uint8List.fromList(
      utf8.encode(
        '{"type":"webauthn.get","challenge":"'
        '${base64Url.encode(challenge).replaceAll('=', '')}'
        '","origin":"https://localhost","crossOrigin":false}',
      ),
    );
    // rpIdHash, flags user present and user verified, sign count 1.
    final authenticatorData = Uint8List.fromList(<int>[
      ...crypto.sha256.convert(utf8.encode('localhost')).bytes,
      0x05,
      0,
      0,
      0,
      1,
    ]);
    final signer = pc.ECDSASigner(
      pc.SHA256Digest(),
      pc.HMac(pc.SHA256Digest(), 64),
    )..init(true, pc.PrivateKeyParameter<pc.ECPrivateKey>(key));
    final signature =
        signer.generateSignature(
              Uint8List.fromList(<int>[
                ...authenticatorData,
                ...crypto.sha256.convert(clientDataJson).bytes,
              ]),
            )
            as pc.ECSignature;
    return WebAuthnAuthenticationResult(
      credentialId: id,
      authenticatorData: authenticatorData,
      clientDataJSON: clientDataJson,
      signature: _derSignature(signature.r, signature.s),
    );
  }

  static Uint8List _derSignature(BigInt r, BigInt s) {
    List<int> integer(BigInt value) {
      final hex = value.toRadixString(16);
      var bytes = Util.hexToBytes(hex.length.isOdd ? '0$hex' : hex).toList();
      if (bytes.first & 0x80 != 0) bytes = <int>[0, ...bytes];
      return <int>[0x02, bytes.length, ...bytes];
    }

    final body = <int>[...integer(r), ...integer(s)];
    return Uint8List.fromList(<int>[0x30, body.length, ...body]);
  }
}
