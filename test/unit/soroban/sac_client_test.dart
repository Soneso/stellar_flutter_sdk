// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Tests for SACClient: the factories, the reads, the amount helper, and the
// writes of a Stellar Asset Contract client.
//
// Every RPC call is served by the shared SacRpcDouble; no test reaches a
// network. Each simulating test decodes the simulateTransaction envelope and
// asserts the contract id, the function, and the full argument list in order.
// The writes also assert the envelope fee, the time bound against the clock
// before and after the call, and the upgraded-auth flag. The double records
// each request it does not expect as a violation and answers it with a
// JSON-RPC error; each double registers its violation check with addTearDown
// where it is built. Each test asserts the exact request log of its double.
//
// This file imports no dart:io and runs on the VM and the web.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'sac_test_fixtures.dart';

const String _rpcUrl = 'https://soroban-testnet.stellar.org:443';

/// The testnet XLM contract, the id the id-based factories open.
const String _sac = 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';

/// A contract address used as a holder, recipient, and `from` in the tests.
final Uint8List _holderBytes = Uint8List.fromList(
  List.generate(32, (i) => i + 1),
);
final String _holderC = StrKey.encodeContractId(_holderBytes);

const String _readOnlyAccount =
    'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF';
const String _muxedAccount =
    'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ';
const String _muxedContract =
    'WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG';
const String _claimableBalance =
    'BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU';
const String _liquidityPool =
    'LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN';

const String _txHash =
    'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';

/// The result XDR that a FAILED transaction reports in these tests.
const String _failedResultXdr = 'AAAAAAAAAAAAAAAAAAAAAA==';

const String _restoreMessage =
    'You need to restore some contract state before you can invoke this method.\n'
    'You can set `restore` to true in the options in order to '
    'automatically restore the contract state when needed.';

/// The i128 maximum, 2^127 - 1, in base units.
final BigInt _maxAmount = (BigInt.one << 127) - BigInt.one;

const List<String> _sacFunctionNames = [
  'admin',
  'allowance',
  'approve',
  'authorized',
  'balance',
  'burn',
  'burn_from',
  'clawback',
  'decimals',
  'mint',
  'name',
  'set_admin',
  'set_authorized',
  'symbol',
  'transfer',
  'transfer_from',
  'trust',
];

/// Matches an [ArgumentError] whose message is exactly [message].
Matcher _argumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

/// Matches an [Exception] whose string form is exactly `Exception: [text]`.
Matcher _exception(String text) => throwsA(
  isA<Exception>().having((e) => e.toString(), 'toString', 'Exception: $text'),
);

/// Matches a [ContractSpecException] whose message is exactly [message].
Matcher _specError(String message) => throwsA(
  isA<ContractSpecException>().having((e) => e.message, 'message', message),
);

/// The message of the [ArgumentError] that [call] throws; fails the test when
/// [call] returns without throwing.
String _argumentMessage(Object? Function() call) {
  try {
    call();
  } on ArgumentError catch (error) {
    return error.message as String;
  }
  fail('the call did not throw an ArgumentError');
}

/// Fails when [message] holds an 8-character window of [seed], in its case or
/// in lower case.
void _expectNoSeedWindow(String message, String seed) {
  for (final text in [seed, seed.toLowerCase()]) {
    for (var start = 0; start + 8 <= text.length; start++) {
      expect(message, isNot(contains(text.substring(start, start + 8))));
    }
  }
}

/// Each seed form the seed tests cover, with its label.
List<(String, String)> _seedForms(String seed) => [
  ('the bare seed', seed),
  ('a lowercase seed', seed.toLowerCase()),
  ('a seed with a trailing newline', '$seed\n'),
  ('a seed with leading spaces', '  $seed'),
  ('a seed with a leading tab', '\t$seed'),
  ('a seed with a trailing CRLF', '$seed\r\n'),
];

int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

List<String> _encoded(List<XdrSCVal> values) => [
  for (final value in values) value.toBase64EncodedXdrString(),
];

/// Transaction data with a read-write footprint when [writes] is set, so that
/// the transaction it simulates is not a read call.
XdrSorobanTransactionData _txData({bool writes = false}) {
  final key = accountLedgerKey(KeyPair.random());
  final footprint = writes
      ? XdrLedgerFootprint([], [key])
      : XdrLedgerFootprint([], []);
  final resources = XdrSorobanResources(
    footprint,
    XdrUint32(0),
    XdrUint32(0),
    XdrUint32(0),
  );
  return XdrSorobanTransactionData(
    XdrSorobanTransactionDataExt(0),
    resources,
    XdrInt64(BigInt.zero),
  );
}

/// A successful simulation that returns [returns]. With [writes] it touches a
/// ledger entry, with [restorePreamble] it reports archived entries, and with
/// [auth] it carries the authorization entries. It has no minimum resource
/// fee, so the envelope keeps the fee of the method options.
RpcAnswer _simulation({
  XdrSCVal? returns,
  bool writes = false,
  bool restorePreamble = false,
  List<XdrSorobanAuthorizationEntry> auth = const [],
}) {
  return rpcResult(
    (_) => {
      'latestLedger': 100000,
      'transactionData': _txData(writes: writes).toBase64EncodedXdrString(),
      'results': [
        {
          'xdr': (returns ?? XdrSCVal.forVoid()).toBase64EncodedXdrString(),
          'auth': [for (final entry in auth) entry.toBase64EncodedXdrString()],
        },
      ],
      if (restorePreamble)
        'restorePreamble': {
          'transactionData': _txData(writes: true).toBase64EncodedXdrString(),
          'minResourceFee': 100,
        },
    },
  );
}

/// A simulation that fails with the host error [resultError].
RpcAnswer _simulationError(String resultError) {
  return rpcResult((_) => {'latestLedger': 100000, 'error': resultError});
}

/// A sendTransaction answer with [status] for the transaction [_txHash].
RpcAnswer _sendStatus(String status) {
  return rpcResult((_) => {'status': status, 'hash': _txHash});
}

/// A getTransaction answer with [status].
RpcAnswer _txStatus(String status) {
  return rpcResult(
    (_) => {
      'status': status,
      'ledger': 99999,
      'createdAt': '1234567890',
      'applicationOrder': 1,
      'feeBump': false,
      if (status == 'FAILED') 'resultXdr': _failedResultXdr,
    },
  );
}

/// The double of a keyed client for [keyPair]. Its account answer is the
/// account entry; [answers] serve the other requests.
SacRpcDouble _keyedDouble(KeyPair keyPair, Map<String, RpcAnswer> answers) {
  final rpc = SacRpcDouble(
    rpcUrl: _rpcUrl,
    expectedKeys: {'account': accountLedgerKey(keyPair)},
    answers: {'account': ledgerEntry(accountEntry(keyPair)), ...answers},
  );
  addTearDown(rpc.expectNoViolations);
  return rpc;
}

SACClient _keyedClient(SacRpcDouble rpc, KeyPair keyPair) {
  return SACClient.forContractId(
    contractId: _sac,
    sourceAccountKeyPair: keyPair,
    network: Network.TESTNET,
    rpcUrl: _rpcUrl,
    server: rpc.server,
  );
}

SACClient _readOnlyClient(SacRpcDouble rpc) {
  return SACClient.readOnlyForContractId(
    contractId: _sac,
    network: Network.TESTNET,
    rpcUrl: _rpcUrl,
    server: rpc.server,
  );
}

/// The request body of the last simulation that [rpc] received.
Map<String, dynamic> _simulateBody(SacRpcDouble rpc) {
  return rpc.bodies.lastWhere(
    (body) => body['method'] == 'simulateTransaction',
  );
}

Transaction _simulatedTx(SacRpcDouble rpc) {
  final params = _simulateBody(rpc)['params'] as Map<String, dynamic>;
  return AbstractTransaction.fromEnvelopeXdrString(
        params['transaction'] as String,
      )
      as Transaction;
}

InvokeContractHostFunction _invocation(SacRpcDouble rpc) {
  final operation =
      _simulatedTx(rpc).operations.single as InvokeHostFunctionOperation;
  return operation.function as InvokeContractHostFunction;
}

/// The argument list of the last simulated invocation, in order.
List<XdrSCVal> _invokedArgs(SacRpcDouble rpc) {
  return _invocation(rpc).arguments ?? <XdrSCVal>[];
}

/// Asserts the simulated invocation: the SAC id, the function name, and the
/// full argument list in order, empty lists included.
void _expectInvocation(SacRpcDouble rpc, String function, List<XdrSCVal> args) {
  final call = _invocation(rpc);
  expect(call.contractID, _sac);
  expect(call.functionName, function);
  expect(_encoded(_invokedArgs(rpc)), _encoded(args));
}

/// Asserts the envelope fee, the time bound against the clock before and after
/// the call, and the upgraded-auth flag of a simulated write.
void _expectWriteOptions(
  SacRpcDouble rpc, {
  required int fee,
  required int timeoutInSeconds,
  required bool useUpgradedAuth,
  required int before,
  required int after,
}) {
  final tx = _simulatedTx(rpc);
  expect(tx.fee, fee);
  expect(
    tx.preconditions!.timeBounds!.maxTime,
    inInclusiveRange(before + timeoutInSeconds, after + timeoutInSeconds),
  );
  final params = _simulateBody(rpc)['params'] as Map<String, dynamic>;
  expect(params['useUpgradedAuth'], useUpgradedAuth);
}

/// The argument list of a transfer of [amount] from [from] to [to].
List<XdrSCVal> _transferArgs(Address from, Address to, BigInt amount) => [
  from.toXdrSCVal(),
  to.toXdrSCVal(),
  XdrSCVal.forI128BigInt(amount),
];

/// Asserts the complete invocation of a simulated write and its envelope.
/// [before] is the clock read before the call; the clock is read again when
/// this helper runs, after the call, so the time bound lies between the two
/// readings.
void _expectWrite(
  SacRpcDouble rpc,
  String function,
  List<XdrSCVal> args, {
  required int before,
  int fee = 100,
  int timeoutInSeconds = 300,
  bool useUpgradedAuth = true,
}) {
  _expectInvocation(rpc, function, args);
  _expectWriteOptions(
    rpc,
    fee: fee,
    timeoutInSeconds: timeoutInSeconds,
    useUpgradedAuth: useUpgradedAuth,
    before: before,
    after: _now(),
  );
}

/// An unsigned auth entry of the contract [authorizer], for the call [function]
/// of the SAC with [args].
XdrSorobanAuthorizationEntry _contractAuthEntry(
  String authorizer,
  String function,
  List<XdrSCVal> args,
) {
  final credentials = XdrSorobanCredentials.forAddressCredentials(
    XdrSorobanAddressCredentials(
      XdrSCAddress.forContractId(authorizer),
      XdrInt64(BigInt.zero),
      XdrUint32(0),
      XdrSCVal.forVoid(),
    ),
  );
  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    XdrSCAddress.forContractId(_sac),
    function,
    args,
  );
  return XdrSorobanAuthorizationEntry(
    credentials,
    XdrSorobanAuthorizedInvocation(fn, []),
  );
}

/// The address of [accountId] as the `from` of a transfer.
Address _account(String accountId) => Address.forAccountId(accountId);

/// An unsigned address-credential auth entry of the account [accountId] for
/// the call [args] of the transfer of the SAC.
XdrSorobanAuthorizationEntry _accountAuthEntry(
  String accountId,
  List<XdrSCVal> args,
) {
  final credentials = XdrSorobanCredentials.forAddressCredentials(
    XdrSorobanAddressCredentials(
      XdrSCAddress.forAccountId(accountId),
      XdrInt64(BigInt.zero),
      XdrUint32(0),
      XdrSCVal.forVoid(),
    ),
  );
  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn = XdrInvokeContractArgs(
    XdrSCAddress.forContractId(_sac),
    'transfer',
    args,
  );
  return XdrSorobanAuthorizationEntry(
    credentials,
    XdrSorobanAuthorizedInvocation(fn, []),
  );
}

/// The recipient and amount shared by the transferAndSend tests.
final Address _recipient = Address.forAccountId(_readOnlyAccount);
final BigInt _amount = BigInt.from(125000000);

void main() {
  group('factories', () {
    test('no factory sends a request and each gives the 17 method names', () {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      final keyPair = KeyPair.random();
      final clients = [
        SACClient.forAsset(
          asset: Asset.NATIVE,
          sourceAccountKeyPair: keyPair,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
        SACClient.forContractId(
          contractId: _sac,
          sourceAccountKeyPair: keyPair,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
        SACClient.readOnlyForAsset(
          asset: Asset.NATIVE,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
        SACClient.readOnlyForContractId(
          contractId: _sac,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
      ];
      expect(rpc.log, isEmpty);
      for (final client in clients) {
        expect(
          client.sorobanClient.getMethodNames(),
          unorderedEquals(_sacFunctionNames),
        );
        expect(client.sorobanClient.getMethodNames(), hasLength(17));
      }
      expect(rpc.log, isEmpty);
    });

    test('forAsset gives the contract id of the asset on each network', () {
      const usdcIssuer =
          'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
      const testAssetIssuer =
          'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final cases = <(Asset, Network, String)>[
        (
          Asset.NATIVE,
          Network.TESTNET,
          'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
        ),
        (
          Asset.NATIVE,
          Network.PUBLIC,
          'CAS3J7GYLGXMF6TDJBBYYSE3HQ6BBSMLNUQ34T6TZMYMW2EVH34XOWMA',
        ),
        (
          AssetTypeCreditAlphaNum4('USDC', usdcIssuer),
          Network.PUBLIC,
          'CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75',
        ),
        (
          AssetTypeCreditAlphaNum12('TESTASSET', testAssetIssuer),
          Network.TESTNET,
          'CBEFNXB7GMEO2PKBCOSKRUQBDWAH4PVA2RIREKPV335KM7MBK2HRLRGB',
        ),
      ];
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      for (final (asset, network, contractId) in cases) {
        final client = SACClient.forAsset(
          asset: asset,
          sourceAccountKeyPair: KeyPair.random(),
          network: network,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        );
        expect(client.contractId, contractId);
        expect(client.sorobanClient.getContractId(), contractId);
      }
      expect(rpc.log, isEmpty);
    });

    test('a liquidity pool share throws before any request', () {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      final pool = AssetTypePoolShare(
        assetA: Asset.NATIVE,
        assetB: AssetTypeCreditAlphaNum4(
          'USDC',
          'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
        ),
      );
      const message =
          'A liquidity pool share has no Stellar Asset Contract; contractId() takes the native asset or an issued asset';
      expect(
        () => SACClient.forAsset(
          asset: pool,
          sourceAccountKeyPair: KeyPair.random(),
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
        throwsA(
          isA<UnsupportedError>().having((e) => e.message, 'message', message),
        ),
      );
      expect(
        () => SACClient.readOnlyForAsset(
          asset: pool,
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
        throwsA(
          isA<UnsupportedError>().having((e) => e.message, 'message', message),
        ),
      );
      expect(rpc.log, isEmpty);
    });

    test('forContractId turns a 64-character hex id into its C strkey', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => 255 - i));
      final hex = Util.bytesToHex(bytes);
      expect(hex, hasLength(64));
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      final client = SACClient.forContractId(
        contractId: hex,
        sourceAccountKeyPair: KeyPair.random(),
        network: Network.TESTNET,
        rpcUrl: _rpcUrl,
        server: rpc.server,
      );
      expect(client.contractId, StrKey.encodeContractId(bytes));
      expect(
        client.sorobanClient.getContractId(),
        StrKey.encodeContractId(bytes),
      );
      expect(rpc.log, isEmpty);
    });

    test('forContractId rejects a muxed contract id before any request', () {
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      expect(
        () => SACClient.forContractId(
          contractId: _muxedContract,
          sourceAccountKeyPair: KeyPair.random(),
          network: Network.TESTNET,
          rpcUrl: _rpcUrl,
          server: rpc.server,
        ),
        _argumentError(
          'The contract to invoke must be a contract (C...) address, got a muxed contract (W...) address: WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; use its base contract (C...) address',
        ),
      );
      expect(rpc.log, isEmpty);
    });

    test(
      'forContractId rejects a G account address with the contract message, before any request',
      () {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        expect(
          () => SACClient.forContractId(
            contractId: _readOnlyAccount,
            sourceAccountKeyPair: KeyPair.random(),
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: rpc.server,
          ),
          _argumentError(
            'The contract to invoke must be a contract (C...) address, got an account (G...) address: GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF',
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test('forContractId and readOnlyForContractId reject every seed form', () {
      final seed = KeyPair.random().secretSeed;
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      for (final (label, value) in _seedForms(seed)) {
        expect(
          () => SACClient.forContractId(
            contractId: value,
            sourceAccountKeyPair: KeyPair.random(),
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: rpc.server,
          ),
          _argumentError(
            'The contract to invoke must be a contract (C...) address, got a secret seed (S...) instead of an address',
          ),
          reason: label,
        );
        expect(
          () => SACClient.readOnlyForContractId(
            contractId: value,
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: rpc.server,
          ),
          _argumentError(
            'The contract to invoke must be a contract (C...) address, got a secret seed (S...) instead of an address',
          ),
          reason: label,
        );
      }
      expect(rpc.log, isEmpty);
    });

    test('the seed message names the kind and holds no window of the seed', () {
      final seed = KeyPair.random().secretSeed;
      final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
      addTearDown(rpc.expectNoViolations);
      for (final (label, value) in _seedForms(seed)) {
        final message = _argumentMessage(
          () => SACClient.readOnlyForContractId(
            contractId: value,
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: rpc.server,
          ),
        );
        expect(
          message,
          'The contract to invoke must be a contract (C...) address, got a secret seed (S...) instead of an address',
          reason: label,
        );
        _expectNoSeedWindow(message, seed);
      }
      expect(rpc.log, isEmpty);
    });

    test('the read-only source placeholder is the all-zero ed25519 key', () {
      expect(SACClient.READ_ONLY_SOURCE_ACCOUNT_ID, _readOnlyAccount);
    });
  });

  group('reads', () {
    test('decimals returns 7 and sends only simulateTransaction', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {'simulate': _simulation(returns: XdrSCVal.forU32(7))},
      );
      addTearDown(rpc.expectNoViolations);
      expect(await _readOnlyClient(rpc).decimals(), 7);
      expect(rpc.log, ['simulate']);
      _expectInvocation(rpc, 'decimals', []);
      expect(
        _simulatedTx(rpc).sourceAccount.accountId,
        SACClient.READ_ONLY_SOURCE_ACCOUNT_ID,
      );
    });

    test(
      'name returns the mocked string, with a complete invocation',
      () async {
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulation(
              returns: XdrSCVal.forString(
                'USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
              ),
            ),
          },
        );
        addTearDown(rpc.expectNoViolations);
        expect(
          await _readOnlyClient(rpc).name(),
          'USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN',
        );
        expect(rpc.log, ['simulate']);
        _expectInvocation(rpc, 'name', []);
      },
    );

    test(
      'symbol returns the mocked string, with a complete invocation',
      () async {
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulation(returns: XdrSCVal.forString('USDC')),
          },
        );
        addTearDown(rpc.expectNoViolations);
        expect(await _readOnlyClient(rpc).symbol(), 'USDC');
        expect(rpc.log, ['simulate']);
        _expectInvocation(rpc, 'symbol', []);
      },
    );

    test(
      'balance of a G holder returns 2^100 and sends only simulateTransaction',
      () async {
        final holder = KeyPair.random().accountId;
        final value = BigInt.one << 100;
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulation(returns: XdrSCVal.forI128BigInt(value)),
          },
        );
        addTearDown(rpc.expectNoViolations);
        expect(
          await _readOnlyClient(rpc).balance(Address.forAccountId(holder)),
          value,
        );
        expect(rpc.log, ['simulate']);
        _expectInvocation(rpc, 'balance', [
          Address.forAccountId(holder).toXdrSCVal(),
        ]);
      },
    );

    test(
      'balance of a C holder returns 2^127 - 1, and a keyed client reads the account first',
      () async {
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(returns: XdrSCVal.forI128BigInt(_maxAmount)),
        });
        expect(
          await _keyedClient(
            rpc,
            source,
          ).balance(Address.forContractId(_holderC)),
          _maxAmount,
        );
        expect(rpc.log, ['account', 'simulate']);
        _expectInvocation(rpc, 'balance', [
          Address.forContractId(_holderC).toXdrSCVal(),
        ]);
      },
    );

    for (final (name, resultError, message, code) in [
      (
        'a HostError Error(Contract, #6) throws SorobanSimulationException with code 6',
        'HostError: Error(Contract, #6)',
        'Exception: Transaction simulation failed: HostError: Error(Contract, #6)',
        6,
      ),
      (
        'a HostError Error(Contract, #13) throws SorobanSimulationException with code 13',
        'HostError: Error(Contract, #13)',
        'Exception: Transaction simulation failed: HostError: Error(Contract, #13)',
        13,
      ),
    ]) {
      test(name, () async {
        final holder = KeyPair.random().accountId;
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {'simulate': _simulationError(resultError)},
        );
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _readOnlyClient(rpc).balance(Address.forAccountId(holder)),
          throwsA(
            isA<SorobanSimulationException>()
                .having((e) => e.toString(), 'toString', message)
                .having((e) => e.reportedContractError?.code, 'code', code),
          ),
        );
        expect(rpc.log, ['simulate']);
        _expectInvocation(rpc, 'balance', [
          Address.forAccountId(holder).toXdrSCVal(),
        ]);
      });
    }

    test(
      'a simulation error without a contract error code reports no code',
      () async {
        final holder = KeyPair.random().accountId;
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulationError(
              'HostError: Error(Value, UnexpectedType)',
            ),
          },
        );
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _readOnlyClient(rpc).balance(Address.forAccountId(holder)),
          throwsA(
            isA<SorobanSimulationException>()
                .having(
                  (e) => e.toString(),
                  'toString',
                  'Exception: Transaction simulation failed: HostError: Error(Value, UnexpectedType)',
                )
                .having(
                  (e) => e.reportedContractError,
                  'reportedContractError',
                  isNull,
                ),
          ),
        );
        expect(rpc.log, ['simulate']);
      },
    );

    final reads = <(String, Future<Object?> Function(SACClient), List<XdrSCVal>, String)>[
      (
        'balance',
        (c) => c.balance(Address.forAccountId(_readOnlyAccount)),
        [Address.forAccountId(_readOnlyAccount).toXdrSCVal()],
        "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC cannot run balance: ledger entries it needs are archived; restore them from a client opened with a funded account's keypair",
      ),
      (
        'decimals',
        (c) => c.decimals(),
        <XdrSCVal>[],
        "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC cannot run decimals: ledger entries it needs are archived; restore them from a client opened with a funded account's keypair",
      ),
      (
        'name',
        (c) => c.name(),
        <XdrSCVal>[],
        "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC cannot run name: ledger entries it needs are archived; restore them from a client opened with a funded account's keypair",
      ),
      (
        'symbol',
        (c) => c.symbol(),
        <XdrSCVal>[],
        "The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC cannot run symbol: ledger entries it needs are archived; restore them from a client opened with a funded account's keypair",
      ),
    ];
    for (final (function, read, args, message) in reads) {
      test(
        '$function throws on a restore preamble and reads no value',
        () async {
          final rpc = SacRpcDouble(
            rpcUrl: _rpcUrl,
            answers: {'simulate': _simulation(restorePreamble: true)},
          );
          addTearDown(rpc.expectNoViolations);
          await expectLater(read(_readOnlyClient(rpc)), _exception(message));
          expect(rpc.log, ['simulate']);
          _expectInvocation(rpc, function, args);
        },
      );
    }

    test('balance throws on a result arm other than I128', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {'simulate': _simulation(returns: XdrSCVal.forU32(1))},
      );
      addTearDown(rpc.expectNoViolations);
      await expectLater(
        _readOnlyClient(rpc).balance(Address.forAccountId(_readOnlyAccount)),
        _exception(
          'The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC returned SCV_U32 from balance, expected SCV_I128',
        ),
      );
      _expectInvocation(rpc, 'balance', [
        Address.forAccountId(_readOnlyAccount).toXdrSCVal(),
      ]);
      expect(rpc.log, ['simulate']);
    });

    test('decimals throws on a result arm other than U32', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {'simulate': _simulation(returns: XdrSCVal.forString('7'))},
      );
      addTearDown(rpc.expectNoViolations);
      await expectLater(
        _readOnlyClient(rpc).decimals(),
        _exception(
          'The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC returned SCV_STRING from decimals, expected SCV_U32',
        ),
      );
      _expectInvocation(rpc, 'decimals', []);
      expect(rpc.log, ['simulate']);
    });

    test('name throws on a result arm other than STRING', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {'simulate': _simulation(returns: XdrSCVal.forU32(1))},
      );
      addTearDown(rpc.expectNoViolations);
      await expectLater(
        _readOnlyClient(rpc).name(),
        _exception(
          'The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC returned SCV_U32 from name, expected SCV_STRING',
        ),
      );
      _expectInvocation(rpc, 'name', []);
      expect(rpc.log, ['simulate']);
    });

    test('symbol throws on a result arm other than STRING', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {'simulate': _simulation(returns: XdrSCVal.forU32(1))},
      );
      addTearDown(rpc.expectNoViolations);
      await expectLater(
        _readOnlyClient(rpc).symbol(),
        _exception(
          'The Stellar Asset Contract CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC returned SCV_U32 from symbol, expected SCV_STRING',
        ),
      );
      _expectInvocation(rpc, 'symbol', []);
      expect(rpc.log, ['simulate']);
    });

    test(
      'balance rejects a muxed account and a muxed contract before any request',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        final client = _readOnlyClient(rpc);
        await expectLater(
          client.balance(Address.forMuxedAccountId(_muxedAccount)),
          _argumentError(
            'The balance holder must be an account (G...) or contract (C...) address, got a muxed account (M...) address: MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ; query its base account GA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVSGZ',
          ),
        );
        await expectLater(
          client.balance(Address.forMuxedContractId(_muxedContract)),
          _argumentError(
            'The balance holder must be an account (G...) or contract (C...) address, got a muxed contract (W...) address: WA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAAAAAAAAAPCIA6IG; query its base contract CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE',
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test(
      'balance rejects a claimable balance and a liquidity pool before any request',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        final client = _readOnlyClient(rpc);
        await expectLater(
          client.balance(Address.forClaimableBalanceId(_claimableBalance)),
          _specError(
            'Invalid type: Address takes an account (G...) or contract (C...) address, got the claimable balance address BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU, which is produced by the host and is not a contract input',
          ),
        );
        await expectLater(
          client.balance(Address.forLiquidityPoolId(_liquidityPool)),
          _specError(
            'Invalid type: Address takes an account (G...) or contract (C...) address, got the liquidity pool address LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN, which is produced by the host and is not a contract input',
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test('balance of a contract holder with no balance returns 0', () async {
      final holder = StrKey.encodeContractId(
        Uint8List.fromList(List<int>.filled(32, 7)),
      );
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {
          'simulate': _simulation(returns: XdrSCVal.forI128BigInt(BigInt.zero)),
        },
      );
      addTearDown(rpc.expectNoViolations);
      expect(
        await _readOnlyClient(rpc).balance(Address.forContractId(holder)),
        BigInt.zero,
      );
      expect(rpc.log, ['simulate']);
      _expectInvocation(rpc, 'balance', [
        Address.forContractId(holder).toXdrSCVal(),
      ]);
    });

    test('balance of an existing zero balance returns 0', () async {
      final holder = KeyPair.random().accountId;
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {
          'simulate': _simulation(returns: XdrSCVal.forI128BigInt(BigInt.zero)),
        },
      );
      addTearDown(rpc.expectNoViolations);
      expect(
        await _readOnlyClient(rpc).balance(Address.forAccountId(holder)),
        BigInt.zero,
      );
      expect(rpc.log, ['simulate']);
      _expectInvocation(rpc, 'balance', [
        Address.forAccountId(holder).toXdrSCVal(),
      ]);
    });

    test(
      'balance of an existing zero balance of a contract holder returns 0',
      () async {
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulation(
              returns: XdrSCVal.forI128BigInt(BigInt.zero),
            ),
          },
        );
        addTearDown(rpc.expectNoViolations);
        expect(
          await _readOnlyClient(rpc).balance(Address.forContractId(_holderC)),
          BigInt.zero,
        );
        expect(rpc.log, ['simulate']);
        _expectInvocation(rpc, 'balance', [
          Address.forContractId(_holderC).toXdrSCVal(),
        ]);
      },
    );
  });

  group('toBaseUnits', () {
    test('converts every vector of the contract', () {
      final vectors = <String, BigInt>{
        '0': BigInt.zero,
        '1': BigInt.from(10000000),
        '12.5': BigInt.from(125000000),
        '0.0000001': BigInt.one,
        '1.2345678': BigInt.from(12345678),
        '007': BigInt.from(70000000),
        '922337203685.4775807': BigInt.parse('9223372036854775807'),
        '17014118346046923173168730371588.4105727': _maxAmount,
      };
      vectors.forEach((text, base) {
        expect(SACClient.toBaseUnits(text), base, reason: text);
      });
    });

    test('rejects every invalid amount with its exact message', () {
      final rejects = <(String, String)>[
        (
          '17014118346046923173168730371588.4105728',
          'Amount 17014118346046923173168730371588.4105728 exceeds the largest i128 amount, 17014118346046923173168730371588.4105727',
        ),
        (
          '1.12345678',
          'Invalid amount "1.12345678": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '-1',
          'Invalid amount "-1": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '+1',
          'Invalid amount "+1": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          ' 1',
          'Invalid amount " 1": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '1 ',
          'Invalid amount "1 ": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '',
          'Invalid amount "": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '1.',
          'Invalid amount "1.": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '.5',
          'Invalid amount ".5": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '1e7',
          'Invalid amount "1e7": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '1,5',
          'Invalid amount "1,5": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '\u0661',
          r'Invalid amount "\u0661": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '\uFF11',
          r'Invalid amount "\uff11": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
      ];
      for (final (text, message) in rejects) {
        expect(
          () => SACClient.toBaseUnits(text),
          _argumentError(message),
          reason: text,
        );
      }
    });

    test('previews a rejected value with escapes and at most 40 characters', () {
      final previews = <(String, String)>[
        (
          '1\n',
          r'Invalid amount "1\u000a": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          '1\u007F',
          r'Invalid amount "1\u007f": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
        (
          'a' * 100,
          'Invalid amount "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa...": expected decimal digits with at most 7 fractional digits, such as 12.5',
        ),
      ];
      for (final (text, message) in previews) {
        expect(
          () => SACClient.toBaseUnits(text),
          _argumentError(message),
          reason: 'input of length ${text.length}',
        );
      }
    });

    test('rejects a secret seed by its kind, with no window of the seed', () {
      final seed = KeyPair.random().secretSeed;
      for (final (label, value) in _seedForms(seed)) {
        final message = _argumentMessage(() => SACClient.toBaseUnits(value));
        expect(
          message,
          'Invalid amount: got a secret seed (S...) instead of a decimal amount',
          reason: label,
        );
        _expectNoSeedWindow(message, seed);
      }
    });

    test('rejects "1 " followed by a seed without showing the seed', () {
      final seed = KeyPair.random().secretSeed;
      final message = _argumentMessage(() => SACClient.toBaseUnits('1 $seed'));
      expect(
        message,
        'Invalid amount "1 a secret seed (S...)": expected decimal digits with at most 7 fractional digits, such as 12.5',
      );
      _expectNoSeedWindow(message, seed);
    });
  });

  group('transfer', () {
    final recipients = <(String, Address, XdrSCAddressType)>[
      (
        'M',
        Address.forMuxedAccountId(_muxedAccount),
        XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT,
      ),
      (
        'W',
        Address.forMuxedContractId(_muxedContract),
        XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_CONTRACT,
      ),
      (
        'C',
        Address.forContractId(_holderC),
        XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
      ),
      (
        'G',
        Address.forAccountId(_readOnlyAccount),
        XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT,
      ),
    ];

    for (final (label, to, arm) in recipients) {
      test(
        'transfer from G to $label passes the address arm of $label, signs and sends nothing',
        () async {
          final source = KeyPair.random();
          final from = _account(KeyPair.random().accountId);
          final amount = BigInt.from(125000000);
          final rpc = _keyedDouble(source, {
            'simulate': _simulation(writes: true),
          });
          final before = _now();
          final tx = await _keyedClient(
            rpc,
            source,
          ).transfer(from: from, to: to, amount: amount);
          final after = _now();

          expect(rpc.log, ['account', 'simulate']);
          expect(tx.signed, isNull);
          _expectInvocation(rpc, 'transfer', _transferArgs(from, to, amount));
          expect(
            _invokedArgs(rpc)[0].address!.discriminant,
            XdrSCAddressType.SC_ADDRESS_TYPE_ACCOUNT,
          );
          expect(_invokedArgs(rpc)[1].address!.discriminant, arm);
          _expectWriteOptions(
            rpc,
            fee: 100,
            timeoutInSeconds: 300,
            useUpgradedAuth: true,
            before: before,
            after: after,
          );
        },
      );
    }

    test('transfer accepts the amounts 0 and 2^127 - 1', () async {
      final before = _now();
      for (final amount in [BigInt.zero, _maxAmount]) {
        final source = KeyPair.random();
        final from = _account(_readOnlyAccount);
        final to = Address.forAccountId(KeyPair.random().accountId);
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
        });
        await _keyedClient(
          rpc,
          source,
        ).transfer(from: from, to: to, amount: amount);
        expect(rpc.log, ['account', 'simulate'], reason: '$amount');
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(from, to, amount),
          before: before,
        );
      }
    });

    test(
      'transfer from a C address passes the contract arm and names it as the signer',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final from = Address.forContractId(_holderC);
        final to = Address.forAccountId(KeyPair.random().accountId);
        final amount = BigInt.from(125000000);
        final args = _transferArgs(from, to, amount);
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(
            writes: true,
            auth: [_contractAuthEntry(_holderC, 'transfer', args)],
          ),
        });
        final tx = await _keyedClient(
          rpc,
          source,
        ).transfer(from: from, to: to, amount: amount);

        expect(rpc.log, ['account', 'simulate']);
        expect(tx.signed, isNull);
        _expectInvocation(rpc, 'transfer', args);
        expect(
          _invokedArgs(rpc)[0].address!.discriminant,
          XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT,
        );
        expect(tx.needsNonInvokerSigningBy(), [Util.bytesToHex(_holderBytes)]);
        tx.sign();
        expect(tx.signed, isNotNull);
        expect(rpc.log, ['account', 'simulate']);
        _expectWriteOptions(
          rpc,
          fee: 100,
          timeoutInSeconds: 300,
          useUpgradedAuth: true,
          before: before,
          after: _now(),
        );
      },
    );

    test(
      'transfer rejects a muxed from, out-of-range amounts, and claimable or pool recipients before any request',
      () async {
        final source = KeyPair.random();
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        final client = _keyedClient(rpc, source);
        final from = _account(_readOnlyAccount);
        final to = Address.forAccountId(KeyPair.random().accountId);

        await expectLater(
          client.transfer(
            from: Address.forMuxedAccountId(_muxedAccount),
            to: to,
            amount: BigInt.one,
          ),
          _specError(
            'Invalid type: Address takes an account (G...) or contract (C...) address, got the muxed address MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAAAAAAAACJUQ, which needs a MuxedAddress parameter',
          ),
        );
        await expectLater(
          client.transfer(from: from, to: to, amount: BigInt.from(-1)),
          _argumentError(
            'The transfer amount must be from 0 to 170141183460469231731687303715884105727 base units, got -1',
          ),
        );
        final above = _maxAmount + BigInt.one;
        await expectLater(
          client.transfer(from: from, to: to, amount: above),
          _argumentError(
            'The transfer amount must be from 0 to 170141183460469231731687303715884105727 base units, got 170141183460469231731687303715884105728',
          ),
        );
        await expectLater(
          client.transfer(
            from: from,
            to: Address.forClaimableBalanceId(_claimableBalance),
            amount: BigInt.one,
          ),
          _specError(
            'Invalid type: MuxedAddress takes an account (G...), muxed account (M...), contract (C...) or muxed contract (W...) address, got the claimable balance address BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU, which is produced by the host and is not a contract input',
          ),
        );
        await expectLater(
          client.transfer(
            from: from,
            to: Address.forLiquidityPoolId(_liquidityPool),
            amount: BigInt.one,
          ),
          _specError(
            'Invalid type: MuxedAddress takes an account (G...), muxed account (M...), contract (C...) or muxed contract (W...) address, got the liquidity pool address LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN, which is produced by the host and is not a contract input',
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test(
      'a read-only transfer with restore true and a preamble throws the refusal',
      () async {
        final before = _now();
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulation(writes: true, restorePreamble: true),
          },
        );
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _readOnlyClient(rpc).transfer(
            from: _account(_readOnlyAccount),
            to: Address.forAccountId(_readOnlyAccount),
            amount: BigInt.one,
            methodOptions: MethodOptions(restore: true),
          ),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        expect(rpc.log, ['simulate']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            _account(_readOnlyAccount),
            Address.forAccountId(_readOnlyAccount),
            BigInt.one,
          ),
          before: before,
        );
      },
    );

    test(
      'signAndSend on a read-only transfer throws the refusal and sends nothing',
      () async {
        final before = _now();
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {'simulate': _simulation(writes: true)},
        );
        addTearDown(rpc.expectNoViolations);
        final tx = await _readOnlyClient(rpc).transfer(
          from: _account(_readOnlyAccount),
          to: Address.forAccountId(_readOnlyAccount),
          amount: BigInt.one,
        );
        await expectLater(
          tx.signAndSend(),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        expect(tx.signed, isNull);
        expect(rpc.log, ['simulate']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            _account(_readOnlyAccount),
            Address.forAccountId(_readOnlyAccount),
            BigInt.one,
          ),
          before: before,
        );
      },
    );

    test(
      'a read-only transfer to a claimable balance throws before any request',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _readOnlyClient(rpc).transfer(
            from: _account(_readOnlyAccount),
            to: Address.forClaimableBalanceId(_claimableBalance),
            amount: BigInt.one,
          ),
          _specError(
            'Invalid type: MuxedAddress takes an account (G...), muxed account (M...), contract (C...) or muxed contract (W...) address, got the claimable balance address BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU, which is produced by the host and is not a contract input',
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test(
      'transfer with simulate false returns an unsimulated transaction',
      () async {
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {});
        final tx = await _keyedClient(rpc, source).transfer(
          from: _account(_readOnlyAccount),
          to: Address.forAccountId(_readOnlyAccount),
          amount: BigInt.one,
          methodOptions: MethodOptions(simulate: false),
        );
        expect(rpc.log, ['account']);
        expect(tx.tx, isNull);
        expect(tx.simulationResponse, isNull);
        expect(tx.signed, isNull);
      },
    );

    test(
      'restore false with a preamble throws the restore message from signAndSend on a keyed transfer',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true, restorePreamble: true),
        });
        final tx = await _keyedClient(rpc, source).transfer(
          from: _account(_readOnlyAccount),
          to: Address.forAccountId(_readOnlyAccount),
          amount: BigInt.one,
          methodOptions: MethodOptions(restore: false),
        );
        await expectLater(tx.signAndSend(), _exception(_restoreMessage));
        expect(rpc.log, ['account', 'simulate']);
        expect(tx.signed, isNull);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            _account(_readOnlyAccount),
            Address.forAccountId(_readOnlyAccount),
            BigInt.one,
          ),
          before: before,
        );
      },
    );

    test(
      'restore false with a preamble throws the restore message from signAndSend on a read-only transfer',
      () async {
        final before = _now();
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulation(writes: true, restorePreamble: true),
          },
        );
        addTearDown(rpc.expectNoViolations);
        final tx = await _readOnlyClient(rpc).transfer(
          from: _account(_readOnlyAccount),
          to: Address.forAccountId(_readOnlyAccount),
          amount: BigInt.one,
          methodOptions: MethodOptions(restore: false),
        );
        await expectLater(tx.signAndSend(), _exception(_restoreMessage));
        expect(rpc.log, ['simulate']);
        expect(tx.signed, isNull);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            _account(_readOnlyAccount),
            Address.forAccountId(_readOnlyAccount),
            BigInt.one,
          ),
          before: before,
        );
      },
    );

    test(
      'transfer applies fee 1234, timeoutInSeconds 60 and useUpgradedAuth false from its options',
      () async {
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
        });
        final before = _now();
        await _keyedClient(rpc, source).transfer(
          from: _account(_readOnlyAccount),
          to: Address.forAccountId(_readOnlyAccount),
          amount: BigInt.one,
          methodOptions: MethodOptions(
            fee: 1234,
            timeoutInSeconds: 60,
            useUpgradedAuth: false,
          ),
        );
        expect(rpc.log, ['account', 'simulate']);
        final after = _now();
        _expectWriteOptions(
          rpc,
          fee: 1234,
          timeoutInSeconds: 60,
          useUpgradedAuth: false,
          before: before,
          after: after,
        );
        _expectInvocation(
          rpc,
          'transfer',
          _transferArgs(
            _account(_readOnlyAccount),
            Address.forAccountId(_readOnlyAccount),
            BigInt.one,
          ),
        );
      },
    );
  });

  group('transferAndSend', () {
    test(
      'transferAndSend sends from the source with the default options and returns SUCCESS',
      () async {
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': _sendStatus('PENDING'),
          'getTx': _txStatus('SUCCESS'),
        });
        final before = _now();
        final response = await _keyedClient(
          rpc,
          source,
        ).transferAndSend(to: _recipient, amount: _amount);
        final after = _now();

        expect(response.status, 'SUCCESS');
        expect(rpc.log, ['account', 'simulate', 'send', 'getTx']);
        _expectInvocation(rpc, 'transfer', [
          Address.forAccountId(source.accountId).toXdrSCVal(),
          _recipient.toXdrSCVal(),
          XdrSCVal.forI128BigInt(_amount),
        ]);
        _expectWriteOptions(
          rpc,
          fee: 100,
          timeoutInSeconds: 300,
          useUpgradedAuth: true,
          before: before,
          after: after,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test('transferAndSend throws the result of a FAILED transaction', () async {
      final before = _now();
      final source = KeyPair.random();
      final rpc = _keyedDouble(source, {
        'simulate': _simulation(writes: true),
        'send': _sendStatus('PENDING'),
        'getTx': _txStatus('FAILED'),
      });
      await expectLater(
        _keyedClient(
          rpc,
          source,
        ).transferAndSend(to: _recipient, amount: _amount),
        _exception(
          'The transfer did not succeed: status FAILED, transaction result xdr: AAAAAAAAAAAAAAAAAAAAAA==',
        ),
      );
      expect(rpc.log, ['account', 'simulate', 'send', 'getTx']);
      _expectWrite(
        rpc,
        'transfer',
        _transferArgs(
          Address.forAccountId(source.accountId),
          _recipient,
          _amount,
        ),
        before: before,
      );
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
      'transferAndSend throws the send failure of an ERROR status before polling',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': _sendStatus('ERROR'),
        });
        await expectLater(
          _keyedClient(
            rpc,
            source,
          ).transferAndSend(to: _recipient, amount: _amount),
          _exception('Send transaction failed with status: ERROR'),
        );
        expect(rpc.log, ['account', 'simulate', 'send']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
          before: before,
        );
      },
    );

    test(
      'transferAndSend polls past a thrown status request to SUCCESS',
      () async {
        final before = _now();
        final source = KeyPair.random();
        var statusCalls = 0;
        final success = _txStatus('SUCCESS');
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': _sendStatus('PENDING'),
          'getTx': (request) {
            statusCalls++;
            if (statusCalls == 1) {
              throw Exception('temporary status failure');
            }
            return success(request);
          },
        });
        final response = await _keyedClient(rpc, source).transferAndSend(
          to: _recipient,
          amount: _amount,
          methodOptions: MethodOptions(timeoutInSeconds: 7),
        );
        expect(response.status, 'SUCCESS');
        expect(rpc.log, ['account', 'simulate', 'send', 'getTx', 'getTx']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
          before: before,
          timeoutInSeconds: 7,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'transferAndSend throws the interrupted message naming the hash on NOT_FOUND until the timeout',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': _sendStatus('PENDING'),
          'getTx': _txStatus('NOT_FOUND'),
        });
        await expectLater(
          _keyedClient(rpc, source).transferAndSend(
            to: _recipient,
            amount: _amount,
            methodOptions: MethodOptions(timeoutInSeconds: 3),
          ),
          _exception(
            'Interrupted after waiting 3 seconds (options.methodOptions.timeoutInSeconds) for the transaction a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2 to complete.',
          ),
        );
        expect(rpc.log, ['account', 'simulate', 'send', 'getTx']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
          before: before,
          timeoutInSeconds: 3,
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'transferAndSend applies fee 1234, timeoutInSeconds 60 and useUpgradedAuth false',
      () async {
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': _sendStatus('PENDING'),
          'getTx': _txStatus('SUCCESS'),
        });
        final before = _now();
        await _keyedClient(rpc, source).transferAndSend(
          to: _recipient,
          amount: _amount,
          methodOptions: MethodOptions(
            fee: 1234,
            timeoutInSeconds: 60,
            useUpgradedAuth: false,
          ),
        );
        expect(rpc.log, ['account', 'simulate', 'send', 'getTx']);
        final after = _now();
        _expectWriteOptions(
          rpc,
          fee: 1234,
          timeoutInSeconds: 60,
          useUpgradedAuth: false,
          before: before,
          after: after,
        );
        _expectInvocation(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'transferAndSend with simulate false throws the not-simulated message and sends nothing',
      () async {
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {});
        await expectLater(
          _keyedClient(rpc, source).transferAndSend(
            to: _recipient,
            amount: _amount,
            methodOptions: MethodOptions(simulate: false),
          ),
          _exception('Transaction has not yet been simulated'),
        );
        expect(rpc.log, ['account']);
      },
    );

    test(
      'a read-only transferAndSend throws the read-only message before any request',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        final client = _readOnlyClient(rpc);
        const message =
            "transferAndSend needs the sending account's keypair, and this SACClient is read-only; open the client with SACClient.forAsset() or SACClient.forContractId()";
        await expectLater(
          client.transferAndSend(to: _recipient, amount: BigInt.from(-1)),
          _exception(message),
        );
        await expectLater(
          client.transferAndSend(
            to: _recipient,
            amount: _amount,
            methodOptions: MethodOptions(simulate: false),
          ),
          _exception(message),
        );
        expect(rpc.log, isEmpty);
      },
    );
  });

  group('send, polling, and source edge cases', () {
    test(
      'transferAndSend throws the RPC error of sendTransaction before polling',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': rpcError('boom'),
        });
        await expectLater(
          _keyedClient(
            rpc,
            source,
          ).transferAndSend(to: _recipient, amount: _amount),
          _exception(
            'Could not send transaction. Rpc error code: -32600, message:  boom',
          ),
        );
        expect(rpc.log, ['account', 'simulate', 'send']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
          before: before,
        );
      },
    );

    test(
      'transferAndSend throws when sendTransaction gives no hash, before polling',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': rpcResult((_) => {'status': 'PENDING'}),
        });
        await expectLater(
          _keyedClient(
            rpc,
            source,
          ).transferAndSend(to: _recipient, amount: _amount),
          _exception('Send transaction response contains no transaction hash.'),
        );
        expect(rpc.log, ['account', 'simulate', 'send']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
          before: before,
        );
      },
    );

    test('transferAndSend polls a DUPLICATE submission to SUCCESS', () async {
      final before = _now();
      final source = KeyPair.random();
      final rpc = _keyedDouble(source, {
        'simulate': _simulation(writes: true),
        'send': _sendStatus('DUPLICATE'),
        'getTx': _txStatus('SUCCESS'),
      });
      final response = await _keyedClient(
        rpc,
        source,
      ).transferAndSend(to: _recipient, amount: _amount);
      expect(response.status, 'SUCCESS');
      expect(rpc.log, ['account', 'simulate', 'send', 'getTx']);
      _expectWrite(
        rpc,
        'transfer',
        _transferArgs(
          Address.forAccountId(source.accountId),
          _recipient,
          _amount,
        ),
        before: before,
      );
    }, timeout: const Timeout(Duration(seconds: 20)));

    test(
      'transferAndSend retries an RPC error answer of getTransaction until SUCCESS',
      () async {
        final before = _now();
        final source = KeyPair.random();
        var statusCalls = 0;
        final success = _txStatus('SUCCESS');
        final failure = rpcError('temporary status error');
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': _sendStatus('PENDING'),
          'getTx': (request) {
            statusCalls++;
            return statusCalls == 1 ? failure(request) : success(request);
          },
        });
        final response = await _keyedClient(rpc, source).transferAndSend(
          to: _recipient,
          amount: _amount,
          methodOptions: MethodOptions(timeoutInSeconds: 7),
        );
        expect(response.status, 'SUCCESS');
        expect(rpc.log, ['account', 'simulate', 'send', 'getTx', 'getTx']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
          before: before,
          timeoutInSeconds: 7,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'the interrupted message carries the error of the last status request',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(writes: true),
          'send': _sendStatus('PENDING'),
          'getTx': rpcError('status unavailable'),
        });
        await expectLater(
          _keyedClient(rpc, source).transferAndSend(
            to: _recipient,
            amount: _amount,
            methodOptions: MethodOptions(timeoutInSeconds: 3),
          ),
          _exception(
            'Interrupted after waiting 3 seconds (options.methodOptions.timeoutInSeconds) for the transaction a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2 to complete. Last status request error: RPC error code: -32600, message: status unavailable',
          ),
        );
        expect(rpc.log, ['account', 'simulate', 'send', 'getTx']);
        _expectWrite(
          rpc,
          'transfer',
          _transferArgs(
            Address.forAccountId(source.accountId),
            _recipient,
            _amount,
          ),
          before: before,
          timeoutInSeconds: 3,
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'transfer from a G other than the source lists it as the needed signer',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final signer = KeyPair.random();
        final from = Address.forAccountId(signer.accountId);
        final to = Address.forAccountId(KeyPair.random().accountId);
        final args = _transferArgs(from, to, _amount);
        final rpc = _keyedDouble(source, {
          'simulate': _simulation(
            writes: true,
            auth: [_accountAuthEntry(signer.accountId, args)],
          ),
        });
        final tx = await _keyedClient(
          rpc,
          source,
        ).transfer(from: from, to: to, amount: _amount);
        expect(rpc.log, ['account', 'simulate']);
        _expectInvocation(rpc, 'transfer', args);
        expect(tx.needsNonInvokerSigningBy(), [signer.accountId]);
        _expectWriteOptions(
          rpc,
          fee: 100,
          timeoutInSeconds: 300,
          useUpgradedAuth: true,
          before: before,
          after: _now(),
        );
      },
    );

    test(
      'transfer from a claimable balance address throws before any request',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _keyedClient(rpc, KeyPair.random()).transfer(
            from: Address.forClaimableBalanceId(_claimableBalance),
            to: _recipient,
            amount: BigInt.one,
          ),
          _specError(
            'Invalid type: Address takes an account (G...) or contract (C...) address, got the claimable balance address BAAD6DBUX6J22DMZOHIEZTEQ64CVCHEDRKWZONFEUL5Q26QD7R76RGR4TU, which is produced by the host and is not a contract input',
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test(
      'transfer from a liquidity pool address throws before any request',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _keyedClient(rpc, KeyPair.random()).transfer(
            from: Address.forLiquidityPoolId(_liquidityPool),
            to: _recipient,
            amount: BigInt.one,
          ),
          _specError(
            'Invalid type: Address takes an account (G...) or contract (C...) address, got the liquidity pool address LA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUPJN, which is produced by the host and is not a contract input',
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test(
      'a read-only transfer with simulate false, then signAndSend, throws the not-simulated message and sends nothing',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        final tx = await _readOnlyClient(rpc).transfer(
          from: _account(_readOnlyAccount),
          to: _recipient,
          amount: BigInt.one,
          methodOptions: MethodOptions(simulate: false),
        );
        await expectLater(
          tx.signAndSend(),
          _exception('Transaction has not yet been simulated'),
        );
        expect(rpc.log, isEmpty);
      },
    );

    test(
      'a keyed transfer with restore true restores the archived entries before it signs and sends',
      () async {
        final before = _now();
        final source = KeyPair.random();
        final sourceAddress = Address.forAccountId(source.accountId);
        final args = _transferArgs(sourceAddress, _recipient, _amount);
        // The first simulation reports the archived entries; the second is the
        // restore transaction's simulation; the third is the transfer rebuilt
        // after the restore.
        final simulations = [
          _simulation(writes: true, restorePreamble: true),
          _simulation(writes: true),
          _simulation(writes: true),
        ];
        var simulated = 0;
        final rpc = _keyedDouble(source, {
          'simulate': (request) => simulations[simulated++](request),
          'send': _sendStatus('PENDING'),
          'getTx': _txStatus('SUCCESS'),
        });

        final tx = await _keyedClient(rpc, source).transfer(
          from: sourceAddress,
          to: _recipient,
          amount: _amount,
          methodOptions: MethodOptions(restore: true),
        );
        // Building the transfer restores first: the account read, the simulation
        // that reports the archived entries, the restore's own account read,
        // simulation, send, and status, then the rebuilt transfer's account read
        // and simulation.
        expect(rpc.log, [
          'account',
          'simulate',
          'account',
          'simulate',
          'send',
          'getTx',
          'account',
          'simulate',
        ]);
        _expectInvocation(rpc, 'transfer', args);

        final restoreSimulation = rpc.bodies
            .where((b) => b['method'] == 'simulateTransaction')
            .toList()[1];
        final restoreEnvelope =
            AbstractTransaction.fromEnvelopeXdrString(
                  (restoreSimulation['params']
                          as Map<String, dynamic>)['transaction']
                      as String,
                )
                as Transaction;
        expect(restoreEnvelope.sourceAccount.accountId, source.accountId);
        expect(
          restoreEnvelope.operations.single,
          isA<RestoreFootprintOperation>(),
        );

        // Signing and sending the transfer come after the restore.
        final response = await tx.signAndSend();
        expect(response.status, 'SUCCESS');
        expect(rpc.log, [
          'account',
          'simulate',
          'account',
          'simulate',
          'send',
          'getTx',
          'account',
          'simulate',
          'send',
          'getTx',
        ]);
        _expectWriteOptions(
          rpc,
          fee: 100,
          timeoutInSeconds: 300,
          useUpgradedAuth: true,
          before: before,
          after: _now(),
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });

  group('SACClient messages', () {
    test(
      'the invalid amount, grammar, range, and seed messages match their literal text',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        expect(
          () => SACClient.toBaseUnits('1.12345678'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Invalid amount "1.12345678": expected decimal digits with at most 7 fractional digits, such as 12.5',
            ),
          ),
        );
        expect(
          () => SACClient.readOnlyForContractId(
            contractId: KeyPair.random().secretSeed,
            network: Network.TESTNET,
            rpcUrl: _rpcUrl,
            server: rpc.server,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'The contract to invoke must be a contract (C...) address, got a secret seed (S...) instead of an address',
            ),
          ),
        );
        await expectLater(
          _keyedClient(rpc, KeyPair.random()).transfer(
            from: Address.forAccountId(_readOnlyAccount),
            to: Address.forAccountId(_readOnlyAccount),
            amount: BigInt.from(-1),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'The transfer amount must be from 0 to 170141183460469231731687303715884105727 base units, got -1',
            ),
          ),
        );
        expect(rpc.log, isEmpty);
      },
    );
  });
}
