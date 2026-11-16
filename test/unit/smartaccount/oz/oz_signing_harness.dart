// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:stellar_flutter_sdk/src/smartaccount/oz/oz_internal_pipeline_interfaces.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'oz_pipeline_fixtures.dart';

// One signing operation through `submit` or `submitWithMultipleSigners` over
// scripted RPC responses, with signers that record what they are asked to
// sign. Every key is generated at run time.

/// The connected smart account of every run.
const String harnessWallet =
    'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';

/// The WebAuthn verifier of the runs' config.
const String harnessWebAuthnVerifier =
    'CB26VN37RCVNTHJZDEPK6IRO2MMTS3Z2IEO5JD5BINY2OOJ5KKJG7NKY';

/// The Ed25519 verifier the multi-signer runs register their keys under.
const String harnessEd25519Verifier =
    'CAW2Z46INPO5VIJEILMYSSEOLBVJIIII5GOE3TN5EUURSRM2FJCF7AJ6';

/// The latest ledger the scripted signing read reports.
const int harnessSigningLedger = 1000;

/// The expiration a run signs with: [harnessSigningLedger] plus the default
/// 720 ledgers.
const int harnessExpiration = harnessSigningLedger + 720;

const String _credentialId = 'aGVsbG8tc21hcnQtYWNjb3VudA';
const String _txHash =
    'd4721e2a61e9a6b3c6c2e5c0d4c0a5f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b7';

/// The executable of the stellar-accounts 0.8.0 build.
XdrContractExecutable v080Executable() =>
    XdrContractExecutable.forWasm(Util.hexToBytes(v080AccountWasmHash));

/// An executable no table maps, which signs the legacy digest.
XdrContractExecutable legacyExecutable() =>
    XdrContractExecutable.forWasm(Uint8List(32));

/// The instance read answer for [harnessWallet] running [executable].
GetLedgerEntriesResponse harnessInstanceRead(
  XdrContractExecutable executable,
) => walletInstanceLedgerEntries(
  harnessWallet,
  executable: executable,
  latestLedger: harnessSigningLedger,
);

/// An RPC error response to the instance read.
GetLedgerEntriesResponse harnessInstanceReadError() =>
    GetLedgerEntriesResponse.fromJson(<String, dynamic>{
      'jsonrpc': '2.0',
      'id': 1,
      'error': <String, dynamic>{
        'code': -32603,
        'message': 'instance read failed',
      },
    });

/// An auth entry of [address] with ADDRESS credentials whose root invocation
/// is [functionName] on [target] with [args].
XdrSorobanAuthorizationEntry harnessEntry({
  String address = harnessWallet,
  String target = harnessWallet,
  String functionName = 'noop',
  List<XdrSCVal> args = const <XdrSCVal>[],
  List<XdrSorobanAuthorizedInvocation> subInvocations =
      const <XdrSorobanAuthorizedInvocation>[],
}) {
  final scAddress = address.startsWith('C')
      ? XdrSCAddress.forContractId(address)
      : XdrSCAddress.forAccountId(address);
  return XdrSorobanAuthorizationEntry(
    XdrSorobanCredentials.forAddressCredentials(
      XdrSorobanAddressCredentials(
        scAddress,
        XdrInt64(BigInt.from(7)),
        XdrUint32(0),
        XdrSCVal.forVoid(),
      ),
    ),
    XdrSorobanAuthorizedInvocation(
      XdrSorobanAuthorizedFunction.forInvokeContractArgs(
        XdrInvokeContractArgs(
          XdrSCAddress.forContractId(target),
          functionName,
          args,
        ),
      ),
      subInvocations,
    ),
  );
}

/// The signature payload of [entry] at [harnessExpiration] on testnet.
Future<Uint8List> harnessPayload(XdrSorobanAuthorizationEntry entry) =>
    OZSmartAccountAuth.buildAuthPayloadHash(
      entry,
      harnessExpiration,
      Network.TESTNET.networkPassphrase,
    );

/// An Ed25519 adapter over a run-time key that records the digests it signs.
class RecordingEd25519Adapter extends OZExternalEd25519SignerAdapter {
  RecordingEd25519Adapter() : _keyPair = KeyPair.random();

  final KeyPair _keyPair;

  /// Every digest [signAuthDigest] received, in call order.
  final List<Uint8List> digests = <Uint8List>[];

  /// The 32-byte public key of the adapter's key.
  Uint8List get publicKey => Uint8List.fromList(_keyPair.publicKey);

  @override
  bool canSignFor(String verifierAddress, Uint8List publicKey) =>
      Util.constantTimeEquals(publicKey, this.publicKey);

  @override
  Future<Uint8List> signAuthDigest(
    Uint8List authDigest,
    Uint8List publicKey,
  ) async {
    digests.add(Uint8List.fromList(authDigest));
    return Uint8List.fromList(_keyPair.sign(authDigest));
  }
}

/// A wallet adapter over a run-time account key that records the preimages
/// it signs.
class RecordingWalletAdapter extends OZExternalWalletAdapter {
  RecordingWalletAdapter() : _keyPair = KeyPair.random();

  final KeyPair _keyPair;

  /// Every preimage [signAuthEntry] received, decoded, in call order.
  final List<XdrHashIDPreimage> preimages = <XdrHashIDPreimage>[];

  /// The G-address of the adapter's key.
  String get address => _keyPair.accountId;

  OZConnectedWallet get _wallet => OZConnectedWallet(
    address: address,
    walletId: 'recording',
    walletName: 'Recording',
  );

  @override
  Future<OZConnectedWallet?> connect() async => _wallet;

  @override
  Future<void> disconnect() async {}

  @override
  bool canSignFor(String address) => address == this.address;

  @override
  List<OZConnectedWallet> getConnectedWallets() => <OZConnectedWallet>[_wallet];

  @override
  OZConnectedWallet? getWalletForAddress(String address) =>
      canSignFor(address) ? _wallet : null;

  @override
  Future<OZSignAuthEntryResult> signAuthEntry(
    String preimageXdr, {
    OZSignAuthEntryOptions? options,
  }) async {
    final bytes = base64Decode(preimageXdr);
    preimages.add(XdrHashIDPreimage.decode(XdrDataInputStream(bytes)));
    final signature = _keyPair.sign(
      Uint8List.fromList(crypto.sha256.convert(bytes).bytes),
    );
    return OZSignAuthEntryResult(
      signedAuthEntry: base64Encode(signature),
      signerAddress: address,
    );
  }
}

/// The arguments of the `__check_auth` call a delegated wallet signer
/// authorized through [preimage].
List<XdrSCVal> checkAuthArgs(XdrHashIDPreimage preimage) {
  final invocation =
      preimage.sorobanAuthorizationWithAddress?.invocation ??
      preimage.sorobanAuthorization!.invocation;
  final call = invocation.function.contractFn!;
  if (call.functionName != '__check_auth' ||
      call.contractAddress.toStrKey() != harnessWallet) {
    throw StateError('Expected __check_auth on $harnessWallet');
  }
  return call.args;
}

/// The scripted server of one run: the deployer account, the simulation
/// returning [entries], the signing read, the reads of [onChainRules] when
/// given, and the re-simulation, send and poll of a successful submission.
MockSorobanServer harnessServer(
  KeyPair deployer,
  List<XdrSorobanAuthorizationEntry> entries,
  Object signingRead, {
  List<XdrSCVal>? onChainRules,
}) {
  SimulateTransactionResponse valueResult(XdrSCVal value) =>
      SimulateTransactionResponse(<String, dynamic>{})
        ..results = <SimulateTransactionResult>[
          SimulateTransactionResult(
            value.toBase64EncodedXdrString(),
            <String>[],
          ),
        ];

  final mock = MockSorobanServer()
    ..getAccountDefault = Account(deployer.accountId, BigInt.one);
  mock.simulateResponses.add(
    SimulateTransactionResponse(<String, dynamic>{})
      ..results = <SimulateTransactionResult>[
        SimulateTransactionResult(
          '',
          entries.map((e) => e.toBase64EncodedXdrString()).toList(),
        ),
      ]
      ..minResourceFee = 100,
  );
  if (onChainRules != null) {
    mock.simulateResponses
      ..add(valueResult(XdrSCVal.forU32(onChainRules.length)))
      ..addAll(onChainRules.map(valueResult));
  }
  mock.simulateResponses.add(
    SimulateTransactionResponse(<String, dynamic>{})
      ..results = <SimulateTransactionResult>[]
      ..minResourceFee = 200,
  );
  if (signingRead is GetLatestLedgerResponse) {
    mock.latestLedgerResponses.add(signingRead);
  } else {
    mock.ledgerEntriesResponses.add(signingRead);
  }
  mock.sendDefault = SendTransactionResponse(<String, dynamic>{})
    ..hash = _txHash
    ..status = SendTransactionResponse.STATUS_PENDING;
  mock.pollDefault = GetTransactionResponse(<String, dynamic>{})
    ..status = GetTransactionResponse.STATUS_SUCCESS
    ..ledger = harnessSigningLedger + 1;
  return mock;
}

/// One single-signer run: the server, the passkey provider and the result or
/// the error.
class SingleSignerRun {
  SingleSignerRun(this.server, this.provider, this.result, this.error);

  final MockSorobanServer server;
  final RecordingWebAuthnProvider provider;
  final OZTransactionResult? result;
  final Object? error;

  /// The challenges the passkey was asked to sign.
  List<Uint8List> get challenges =>
      provider.authenticateCalls.map((call) => call.challenge).toList();
}

/// A rule manager that forwards to [target], so a real
/// [OZContextRuleManager] can serve the kit it is built over.
class _ForwardingContextRuleManager implements OZContextRuleManagerInterface {
  late OZContextRuleManager target;

  @override
  Future<List<OZParsedContextRule>> listContextRules() =>
      target.listContextRules();

  @override
  Future<List<int>> resolveContextRuleIdsForEntry(
    XdrSorobanAuthorizationEntry entry,
    List<OZSmartAccountSigner> signers,
    List<OZParsedContextRule> contextRules,
  ) => target.resolveContextRuleIdsForEntry(entry, signers, contextRules);

  @override
  Future<List<XdrSCVal>> getAllContextRules() => target.getAllContextRules();

  @override
  Future<XdrSCVal> getContextRule(int id) => target.getContextRule(id);

  @override
  OZParsedContextRule parseContextRule(XdrSCVal scVal) =>
      target.parseContextRule(scVal);
}

/// Runs `submit` over a simulation that returns [entries], with the
/// connected passkey answering once. Without [onChainRules] the rule IDs
/// are [ruleIds]; with them the kit lists those rules from the chain and
/// resolves the IDs itself.
Future<SingleSignerRun> runSingleSignerSubmit(
  List<XdrSorobanAuthorizationEntry> entries,
  Object signingRead, {
  List<int> ruleIds = const <int>[0],
  List<XdrSCVal>? onChainRules,
}) async {
  final deployer = KeyPair.random();
  final server = harnessServer(
    deployer,
    entries,
    signingRead,
    onChainRules: onChainRules,
  );
  final ruleManager = _ForwardingContextRuleManager();
  final provider = RecordingWebAuthnProvider();
  final credentialIdBytes = base64Url.decode(
    base64Url.normalize(_credentialId),
  );
  provider.authenticateResponses.add(
    WebAuthnAuthenticationResult(
      credentialId: credentialIdBytes,
      authenticatorData: Uint8List.fromList(List<int>.generate(37, (i) => i)),
      clientDataJSON: Uint8List.fromList(
        utf8.encode('{"type":"webauthn.get","challenge":"abc"}'),
      ),
      signature: Uint8List.fromList(<int>[
        0x30,
        0x44,
        0x02,
        0x20,
        ...List<int>.generate(32, (i) => i + 1),
        0x02,
        0x20,
        ...List<int>.generate(32, (i) => i + 2),
      ]),
    ),
  );
  final publicKey = Uint8List(65)..[0] = 0x04;
  final storage = OZInMemoryStorageAdapter();
  await storage.save(
    OZStoredCredential(
      credentialId: _credentialId,
      publicKey: publicKey,
      contractId: harnessWallet,
    ),
  );
  final kit = FakePipelineKit(
    config: OZSmartAccountConfig(
      rpcUrl: 'https://soroban-testnet.stellar.org',
      networkPassphrase: Network.TESTNET.networkPassphrase,
      accountWasmHash: '0' * 64,
      webauthnVerifierAddress: harnessWebAuthnVerifier,
      webauthnProvider: provider,
    ),
    sorobanServer: server,
    deployer: deployer,
    storage: storage,
    contextRuleManager: onChainRules == null ? null : ruleManager,
  )..setConnected(credentialId: _credentialId, contractId: harnessWallet);
  ruleManager.target = OZContextRuleManager(kit);

  try {
    final result = await kit.transactionOperations.submit(
      hostFunction: _hostFunction(),
      auth: const <XdrSorobanAuthorizationEntry>[],
      resolveContextRuleIds: onChainRules == null
          ? (_, __) async => ruleIds
          : null,
    );
    return SingleSignerRun(server, provider, result, null);
  } catch (e) {
    return SingleSignerRun(server, provider, null, e);
  }
}

/// One multi-signer run: the server, the recording signers and the result
/// or the error.
class MultiSignerRun {
  MultiSignerRun(
    this.server,
    this.ed25519,
    this.wallet,
    this.result,
    this.error,
  );

  final MockSorobanServer server;
  final RecordingEd25519Adapter ed25519;
  final RecordingWalletAdapter wallet;
  final OZTransactionResult? result;
  final Object? error;
}

/// Runs `submitWithMultipleSigners` over a simulation that returns the
/// entries [entriesFor] builds for the recording wallet signer's address,
/// signed by an Ed25519 signer, the wallet signer, or both, with the rule
/// IDs [ruleIds].
Future<MultiSignerRun> runMultiSignerSubmit(
  List<XdrSorobanAuthorizationEntry> Function(String walletSignerAddress)
  entriesFor,
  Object signingRead, {
  bool withEd25519 = true,
  bool withWalletSigner = false,
  List<int> ruleIds = const <int>[0],
}) async {
  final deployer = KeyPair.random();
  final ed25519 = RecordingEd25519Adapter();
  final wallet = RecordingWalletAdapter();
  final server = harnessServer(
    deployer,
    entriesFor(wallet.address),
    signingRead,
  );
  final kit = FakePipelineKit(
    config: OZSmartAccountConfig(
      rpcUrl: 'https://soroban-testnet.stellar.org',
      networkPassphrase: Network.TESTNET.networkPassphrase,
      accountWasmHash: '0' * 64,
      webauthnVerifierAddress: harnessWebAuthnVerifier,
    ),
    sorobanServer: server,
    deployer: deployer,
    externalSigners: OZExternalSignerManager(
      networkPassphrase: Network.TESTNET.networkPassphrase,
      walletAdapter: wallet,
      ed25519Adapter: ed25519,
    ),
  )..setConnected(credentialId: _credentialId, contractId: harnessWallet);
  kit.setMultiSignerManager(OZMultiSignerManager(kit));

  try {
    final result = await (kit.multiSignerManager as OZMultiSignerManager)
        .submitWithMultipleSigners(
          hostFunction: _hostFunction(),
          selectedSigners: <OZSelectedSigner>[
            if (withWalletSigner) OZSelectedSignerWallet(wallet.address),
            if (withEd25519)
              OZSelectedSignerEd25519(
                verifierAddress: harnessEd25519Verifier,
                publicKey: ed25519.publicKey,
              ),
          ],
          resolveContextRuleIds: (_, __) async => ruleIds,
        );
    return MultiSignerRun(server, ed25519, wallet, result, null);
  } catch (e) {
    return MultiSignerRun(server, ed25519, wallet, null, e);
  }
}

XdrHostFunction _hostFunction() => XdrHostFunction.forInvokingContractWithArgs(
  XdrInvokeContractArgs(
    XdrSCAddress.forContractId(harnessWallet),
    'noop',
    const <XdrSCVal>[],
  ),
);
