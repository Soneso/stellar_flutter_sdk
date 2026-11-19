// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Tests for AssembledTransaction built by a read-only client: the placeholder
// source, the refusal of every write-side rule, and what stays allowed.
//
// The clients come from SorobanClient.forSpecEntries with the spec of
// SACClient.specEntries() and the readOnly flag. Every RPC call is served by
// the shared SacRpcDouble, which records each request it does not expect as a
// violation and answers it with a JSON-RPC error. Each double registers
// expectNoViolations() with addTearDown where it is built, and each test
// asserts its exact request log. No test reaches a network.
//
// This file imports no dart:io and runs on the VM and the web.

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'sac_test_fixtures.dart';

const String _rpcUrl = 'https://soroban-testnet.stellar.org:443';

/// The testnet XLM contract, the id of every client in this file.
const String _sac = 'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC';

/// The all-zero placeholder source of a read-only client.
const String _readOnlyAccount =
    'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF';

/// Matches an [Exception] whose string form is exactly `Exception: [text]`.
Matcher _exception(String text) => throwsA(
  isA<Exception>().having((e) => e.toString(), 'toString', 'Exception: $text'),
);

/// Transaction data with a read-write footprint when [writes] is set, so that
/// the transaction it simulates is not a read call. Without [writes] the
/// footprint is empty, which makes the simulated transaction a read call.
XdrSorobanTransactionData _txData({bool writes = false}) {
  final key = accountLedgerKey(KeyPair.random());
  final footprint = writes
      ? XdrLedgerFootprint([], [key])
      : XdrLedgerFootprint([], []);
  return XdrSorobanTransactionData(
    XdrSorobanTransactionDataExt(0),
    XdrSorobanResources(footprint, XdrUint32(0), XdrUint32(0), XdrUint32(0)),
    XdrInt64(BigInt.zero),
  );
}

/// A successful simulation that returns [returns]. With [writes] it touches a
/// ledger entry, with [restorePreamble] it reports archived entries, and with
/// [auth] it carries the authorization entries.
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

/// A client for the SAC with the read-only placeholder source. [readOnly] sets
/// the flag.
SorobanClient _client(SacRpcDouble rpc, {bool readOnly = true}) {
  return SorobanClient.forSpecEntries(
    specEntries: SACClient.specEntries(),
    options: ClientOptions(
      sourceAccountKeyPair: KeyPair.fromAccountId(_readOnlyAccount),
      contractId: _sac,
      network: Network.TESTNET,
      rpcUrl: _rpcUrl,
      server: rpc.server,
    ),
    readOnly: readOnly,
  );
}

/// Builds a transfer of one base unit from the placeholder account to itself.
Future<AssembledTransaction> _transfer(
  SorobanClient client, {
  MethodOptions? methodOptions,
}) {
  final account = Address.forAccountId(_readOnlyAccount);
  return client.buildInvokeMethodTx(
    name: 'transfer',
    args: client.funcArgsToXdrSCValues('transfer', {
      'from': account,
      'to': account,
      'amount': BigInt.one,
    }),
    methodOptions: methodOptions,
  );
}

/// A read-only transfer simulated with a write, so that it is not a read call.
Future<(SacRpcDouble, AssembledTransaction)> _writeSimulated({
  List<XdrSorobanAuthorizationEntry> auth = const [],
}) async {
  final rpc = SacRpcDouble(
    rpcUrl: _rpcUrl,
    answers: {'simulate': _simulation(writes: true, auth: auth)},
  );
  addTearDown(rpc.expectNoViolations);
  final tx = await _transfer(_client(rpc));
  return (rpc, tx);
}

/// An unsigned address-credential auth entry of the account [accountId] for
/// the transfer of the SAC.
XdrSorobanAuthorizationEntry _gAccountAuthEntry(String accountId) {
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
  fn.contractFn =
      XdrInvokeContractArgs(XdrSCAddress.forContractId(_sac), 'transfer', [
        XdrSCVal.forAddress(XdrSCAddress.forAccountId(accountId)),
        XdrSCVal.forAddress(XdrSCAddress.forAccountId(_readOnlyAccount)),
        XdrSCVal.forI128BigInt(BigInt.one),
      ]);
  return XdrSorobanAuthorizationEntry(
    credentials,
    XdrSorobanAuthorizedInvocation(fn, []),
  );
}

void main() {
  group('a flagged build of a read-only client', () {
    test(
      'sends only simulateTransaction, with the source at sequence 1',
      () async {
        final (rpc, _) = await _writeSimulated();
        expect(rpc.log, ['simulate']);

        final body = rpc.bodies.single;
        final params = body['params'] as Map<String, dynamic>;
        final envelope =
            AbstractTransaction.fromEnvelopeXdrString(
                  params['transaction'] as String,
                )
                as Transaction;
        expect(envelope.sourceAccount.accountId, _readOnlyAccount);
        expect(envelope.sequenceNumber, BigInt.one);
      },
    );

    test('a second simulate sends only simulateTransaction', () async {
      final (rpc, tx) = await _writeSimulated();
      await tx.simulate();
      expect(rpc.log, ['simulate', 'simulate']);
    });
  });

  group('the refusal after a write simulation', () {
    test('sign() throws the refusal and signs nothing', () async {
      final (rpc, tx) = await _writeSimulated();
      expect(
        () => tx.sign(),
        _exception(
          "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
        ),
      );
      expect(tx.signed, isNull);
      expect(rpc.log, ['simulate']);
    });

    test('sign(force: true) throws the refusal and signs nothing', () async {
      final (rpc, tx) = await _writeSimulated();
      expect(
        () => tx.sign(force: true),
        _exception(
          "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
        ),
      );
      expect(tx.signed, isNull);
      expect(rpc.log, ['simulate']);
    });

    test(
      'sign with a sourceAccountKeyPair throws the refusal and signs nothing',
      () async {
        final (rpc, tx) = await _writeSimulated();
        expect(
          () => tx.sign(sourceAccountKeyPair: KeyPair.random()),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        expect(tx.signed, isNull);
        expect(rpc.log, ['simulate']);
      },
    );

    test('signAndSend() throws the refusal and sends nothing', () async {
      final (rpc, tx) = await _writeSimulated();
      await expectLater(
        tx.signAndSend(),
        _exception(
          "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
        ),
      );
      expect(tx.signed, isNull);
      expect(rpc.log, ['simulate']);
    });

    test('restoreFootprint() throws the refusal before any request', () async {
      final (rpc, tx) = await _writeSimulated();
      await expectLater(
        tx.restoreFootprint(
          restorePreamble: RestorePreamble(_txData(writes: true), 100),
        ),
        _exception(
          "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
        ),
      );
      expect(tx.signed, isNull);
      expect(rpc.log, ['simulate']);
    });

    test(
      'send() throws the refusal for a signed transaction set by hand',
      () async {
        final (rpc, tx) = await _writeSimulated();
        expect(tx.signed, isNull);
        tx.signed = tx.tx;
        await expectLater(
          tx.send(),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        expect(rpc.log, ['simulate']);
      },
    );

    test(
      'signAndSend() calls send() for a signed transaction set by hand and throws the refusal',
      () async {
        final (rpc, tx) = await _writeSimulated();
        tx.signed = tx.tx;
        await expectLater(
          tx.signAndSend(),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        expect(rpc.log, ['simulate']);
      },
    );
  });

  group('the refusal does not depend on the options', () {
    test(
      'a replaced options object with readOnly false keeps the refusal',
      () async {
        final (rpc, tx) = await _writeSimulated();
        tx.options = AssembledTransactionOptions(
          clientOptions: tx.options.clientOptions,
          methodOptions: MethodOptions(),
          method: 'transfer',
          readOnly: false,
        );
        expect(
          () => tx.sign(),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        await expectLater(
          tx.signAndSend(),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        expect(tx.signed, isNull);
        expect(rpc.log, ['simulate']);
      },
    );

    test(
      'a preamble with restore true throws the refusal, not the private-key message',
      () async {
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {
            'simulate': _simulation(writes: true, restorePreamble: true),
          },
        );
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _transfer(_client(rpc), methodOptions: MethodOptions(restore: true)),
          _exception(
            "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
          ),
        );
        expect(rpc.log, ['simulate']);
      },
    );
  });

  group('the reads and the allowed signing', () {
    test('after a read simulation, sign() keeps the read-call message', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {'simulate': _simulation(returns: XdrSCVal.forU32(7))},
      );
      addTearDown(rpc.expectNoViolations);
      final tx = await _client(rpc).buildInvokeMethodTx(name: 'decimals');
      expect(
        () => tx.sign(),
        _exception(
          'This is a read call. It requires no signature or sending. Use `force: true` to sign and send anyway.',
        ),
      );
      expect(tx.signed, isNull);
      expect(rpc.log, ['simulate']);
    });

    test(
      'signAuthEntries with an entry\'s G keypair and an explicit validUntilLedgerSeq signs it with no request',
      () async {
        final signer = KeyPair.random();
        final (rpc, tx) = await _writeSimulated(
          auth: [_gAccountAuthEntry(signer.accountId)],
        );
        expect(tx.needsNonInvokerSigningBy(), [signer.accountId]);

        await tx.signAuthEntries(
          signerKeyPair: signer,
          validUntilLedgerSeq: 1000,
        );

        expect(tx.needsNonInvokerSigningBy(), isEmpty);
        expect(rpc.log, ['simulate']);
      },
    );

    test(
      'without the flag, a zero-key source still sends the account request first',
      () async {
        final zeroKey = KeyPair.fromAccountId(_readOnlyAccount);
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          expectedKeys: {'account': accountLedgerKey(zeroKey)},
          answers: {'account': ledgerEntry(null)},
        );
        addTearDown(rpc.expectNoViolations);
        await expectLater(
          _client(rpc, readOnly: false).buildInvokeMethodTx(name: 'decimals'),
          _exception(
            'Account: GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF not found.',
          ),
        );
        expect(rpc.log, ['account']);
      },
    );
  });

  group('sign on a read-only transaction that is not a write', () {
    test(
      'sign() on an unsimulated read-only transaction throws the not-simulated message, not the refusal',
      () async {
        final rpc = SacRpcDouble(rpcUrl: _rpcUrl);
        addTearDown(rpc.expectNoViolations);
        final tx = await _transfer(
          _client(rpc),
          methodOptions: MethodOptions(simulate: false),
        );
        expect(
          () => tx.sign(),
          _exception('Transaction has not yet been simulated'),
        );
        expect(tx.signed, isNull);
        expect(rpc.log, isEmpty);
      },
    );

    test('sign(force: true) on a read call throws the refusal', () async {
      final rpc = SacRpcDouble(
        rpcUrl: _rpcUrl,
        answers: {'simulate': _simulation(returns: XdrSCVal.forU32(7))},
      );
      addTearDown(rpc.expectNoViolations);
      final tx = await _client(rpc).buildInvokeMethodTx(name: 'decimals');
      expect(
        () => tx.sign(force: true),
        _exception(
          "This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
        ),
      );
      expect(tx.signed, isNull);
      expect(rpc.log, ['simulate']);
    });
  });

  group('read-only messages as literal text', () {
    test(
      'the refusal and the read-call message match their literal text',
      () async {
        final rpc = SacRpcDouble(
          rpcUrl: _rpcUrl,
          answers: {'simulate': _simulation(returns: XdrSCVal.forU32(7))},
        );
        addTearDown(rpc.expectNoViolations);
        final readTx = await _client(rpc).buildInvokeMethodTx(name: 'decimals');
        expect(
          () => readTx.sign(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: This is a read call. It requires no signature or sending. Use `force: true` to sign and send anyway.',
            ),
          ),
        );

        expect(rpc.log, ['simulate']);

        final (writeRpc, writeTx) = await _writeSimulated();
        expect(
          () => writeTx.sign(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              "Exception: This transaction was built by a read-only client for source account GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF, which has no keypair to sign with; build it from a client opened with the submitting account's keypair",
            ),
          ),
        );
        expect(writeRpc.log, ['simulate']);
      },
    );
  });
}
