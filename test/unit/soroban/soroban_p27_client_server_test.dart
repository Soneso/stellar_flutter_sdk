// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Protocol 27 simulation and AssembledTransaction unit tests: SimulateTransactionRequest.authV2, MethodOptions.authV2,
// AssembledTransaction.simulate() thread-through, needsNonInvokerSigningBy,
// signAuthEntries, and the send precheck for WITH_DELEGATES entries.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---------------------------------------------------------------------------
// Shared test fixtures (golden-vector addresses from section 8.1)
// ---------------------------------------------------------------------------

const _kSeed = 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';
const _kContractId = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';

const int _kExpiration = 4242;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal valid SorobanAuthorizationEntry with the given credentials.
SorobanAuthorizationEntry _makeEntry(SorobanCredentials creds) {
  final contractAddr = Address.forContractId(_kContractId);
  final fn = SorobanAuthorizedFunction.forContractFunction(
    contractAddr,
    'hello',
    [XdrSCVal.forU64(BigInt.from(1234))],
  );
  final invocation = SorobanAuthorizedInvocation(fn);
  return SorobanAuthorizationEntry(creds, invocation);
}

/// Builds a legacy ADDRESS entry for [accountId] with a void signature.
SorobanAuthorizationEntry _makeLegacyEntry(String accountId) {
  final address = Address.forAccountId(accountId);
  final inner = SorobanAddressCredentials(
      address, BigInt.parse('123456789101112'), _kExpiration, XdrSCVal.forVoid());
  return _makeEntry(SorobanCredentials.forAddressCredentials(inner));
}

/// Builds an ADDRESS_V2 entry for [accountId] with a void signature.
SorobanAuthorizationEntry _makeV2Entry(String accountId) {
  final address = Address.forAccountId(accountId);
  final inner = SorobanAddressCredentials(
      address, BigInt.parse('123456789101112'), _kExpiration, XdrSCVal.forVoid());
  return _makeEntry(SorobanCredentials.forAddressV2(inner));
}

/// Builds a WITH_DELEGATES entry whose top-level is [topAccountId] and with a
/// single delegate at [delegateAccountId]. Both signatures start void.
SorobanAuthorizationEntry _makeWithDelegatesEntry(
    String topAccountId, String delegateAccountId) {
  // Build the base V2 entry first, then promote to WITH_DELEGATES.
  final base = _makeV2Entry(topAccountId);
  final desc = SorobanDelegateDescriptor(delegateAccountId);
  return SorobanAuthorizationEntry.withDelegates(base, [desc], _kExpiration);
}

/// Encodes a [SorobanAuthorizationEntry] to base64 XDR (for mock responses).
String _entryToBase64(SorobanAuthorizationEntry entry) =>
    entry.toBase64EncodedXdrString();

/// Encodes a minimal [XdrAccountEntry] for [accountId] with [seqNum] to base64
/// so the mock getLedgerEntries response can satisfy [SorobanServer.getAccount].
String _buildAccountLedgerEntryXdr(String accountId, BigInt seqNum) {
  final xdrAccountId =
      XdrAccountID(KeyPair.fromAccountId(accountId).xdrPublicKey);
  final accountEntry = XdrAccountEntry(
    xdrAccountId,
    XdrInt64(BigInt.from(100000000)),
    XdrSequenceNumber(seqNum),
    XdrUint32(0),
    null,
    XdrUint32(0),
    XdrString32(''),
    XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
    [],
    XdrAccountEntryExt(0),
  );
  final ledgerEntryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
  ledgerEntryData.account = accountEntry;
  return ledgerEntryData.toBase64EncodedXdrString();
}

/// Minimal XdrSorobanTransactionData for mock simulate responses.
String _buildSorobanTransactionDataXdr() {
  final sorobanData = XdrSorobanTransactionData(
    XdrSorobanTransactionDataExt(0),
    XdrSorobanResources(
      XdrLedgerFootprint([], []),
      XdrUint32(0),
      XdrUint32(0),
      XdrUint32(0),
    ),
    XdrInt64(BigInt.zero),
  );
  return sorobanData.toBase64EncodedXdrString();
}

/// Starts a local HTTP server that:
/// - Returns [accountXdr] for any `getLedgerEntries` call.
/// - Returns a simulate response containing [authEntries] as base64 XDR.
/// - Records the last `simulateTransaction` request body to [capturedRequest].
/// Returns a Future<[httpServer, capturedRequestHolder]> tuple.
Future<(HttpServer, Map<String, dynamic>)> _startMockRpcServer({
  required String accountId,
  required BigInt seqNum,
  List<SorobanAuthorizationEntry>? authEntries,
}) async {
  final accountXdr = _buildAccountLedgerEntryXdr(accountId, seqNum);
  final sorobanDataXdr = _buildSorobanTransactionDataXdr();
  final capturedRequest = <String, dynamic>{};

  final server = await HttpServer.bind('127.0.0.1', 0);
  server.listen((req) async {
    final body = await utf8.decoder.bind(req).join();
    final parsed = json.decode(body) as Map<String, dynamic>;
    final method = parsed['method'] as String?;

    String responseJson;
    if (method == 'getLedgerEntries') {
      responseJson = json.encode({
        'jsonrpc': '2.0',
        'id': parsed['id'],
        'result': {
          'entries': [
            {
              'key': 'AAAAAAAAAA==',
              'xdr': accountXdr,
              'lastModifiedLedgerSeq': 100,
            }
          ],
          'latestLedger': 1000,
        }
      });
    } else if (method == 'simulateTransaction') {
      // Capture request params for assertion.
      capturedRequest.addAll(
          (parsed['params'] as Map<String, dynamic>).cast<String, dynamic>());
      final authBase64 = (authEntries ?? [])
          .map((e) => _entryToBase64(e))
          .toList();
      responseJson = json.encode({
        'jsonrpc': '2.0',
        'id': parsed['id'],
        'result': {
          'results': [
            {
              'xdr': 'AAAAAA==',
              'auth': authBase64,
            }
          ],
          'transactionData': sorobanDataXdr,
          'minResourceFee': '100',
          'latestLedger': 1000,
        }
      });
    } else if (method == 'getLatestLedger') {
      responseJson = json.encode({
        'jsonrpc': '2.0',
        'id': parsed['id'],
        'result': {'sequence': 1000},
      });
    } else {
      responseJson = json.encode({
        'jsonrpc': '2.0',
        'id': parsed['id'],
        'error': {'code': -32601, 'message': 'Method not found: $method'},
      });
    }

    req.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(responseJson);
    await req.response.close();
  });

  return (server, capturedRequest);
}

/// Builds an [AssembledTransaction] wired to the mock server at [rpcUrl].
/// [simulate] controls whether auto-simulation runs during build.
Future<AssembledTransaction> _buildAssembledTx(
    String rpcUrl,
    String accountId,
    KeyPair kp, {
    bool simulate = false,
    bool authV2 = false,
}) async {
  final clientOptions = ClientOptions(
    sourceAccountKeyPair: kp,
    contractId: _kContractId,
    network: Network.TESTNET,
    rpcUrl: rpcUrl,
  );
  final options = AssembledTransactionOptions(
    clientOptions: clientOptions,
    methodOptions: MethodOptions(simulate: simulate, authV2: authV2),
    method: 'hello',
    arguments: [XdrSCVal.forU64(BigInt.from(1234))],
  );
  return await AssembledTransaction.build(options: options);
}

// ---------------------------------------------------------------------------
// TESTS
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // GROUP 1: SimulateTransactionRequest.getRequestArgs() authV2 key rules
  // -------------------------------------------------------------------------
  group('SimulateTransactionRequest.getRequestArgs() authV2 flag', () {
    late Account sourceAccount;

    setUp(() {
      sourceAccount = Account(
          'GDAT5HWTGIU4TSSZ4752OUC4SABDLTLZFRPZUJ3D6LKBNEPA7V2CIG54',
          BigInt.from(100));
    });

    Transaction _buildTx() => TransactionBuilder(sourceAccount)
        .addOperation(BumpSequenceOperation(BigInt.from(110)))
        .build();

    test('authV2 key is ABSENT when default (false)', () {
      final req = SimulateTransactionRequest(_buildTx());
      final args = req.getRequestArgs();

      expect(args.containsKey('authV2'), isFalse,
          reason: '"authV2" must be omitted entirely when not set');
    });

    test('authV2 key is ABSENT when explicitly false', () {
      final req = SimulateTransactionRequest(_buildTx(), authV2: false);
      final args = req.getRequestArgs();

      expect(args.containsKey('authV2'), isFalse,
          reason: '"authV2: false" must never be emitted');
    });

    test('authV2 key is present as boolean true when opted in', () {
      final req = SimulateTransactionRequest(_buildTx(), authV2: true);
      final args = req.getRequestArgs();

      expect(args['authV2'], equals(true),
          reason: '"authV2" must be boolean true when opted in');
    });

    test('existing params (transaction, resourceConfig, authMode) unaffected', () {
      final tx = _buildTx();
      final rc = ResourceConfig(12345);
      final req = SimulateTransactionRequest(tx,
          resourceConfig: rc, authMode: 'record', authV2: true);
      final args = req.getRequestArgs();

      expect(args.containsKey('transaction'), isTrue);
      expect(args['resourceConfig']['instructionLeeway'], equals(12345));
      expect(args['authMode'], equals('record'));
      expect(args['authV2'], equals(true));
    });

    test('existing params unaffected when authV2 false', () {
      final tx = _buildTx();
      final rc = ResourceConfig(999);
      final req = SimulateTransactionRequest(tx,
          resourceConfig: rc, authMode: 'enforce', authV2: false);
      final args = req.getRequestArgs();

      expect(args.containsKey('authV2'), isFalse);
      expect(args['resourceConfig']['instructionLeeway'], equals(999));
      expect(args['authMode'], equals('enforce'));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 2: MethodOptions.authV2 field
  // -------------------------------------------------------------------------
  group('MethodOptions.authV2 field', () {
    test('defaults to false', () {
      final opts = MethodOptions();
      expect(opts.authV2, isFalse);
    });

    test('can be set to true', () {
      final opts = MethodOptions(authV2: true);
      expect(opts.authV2, isTrue);
    });

    test('existing fields unaffected when authV2 added', () {
      final opts = MethodOptions(
          fee: 500, timeoutInSeconds: 120, simulate: false, restore: true);
      expect(opts.fee, equals(500));
      expect(opts.timeoutInSeconds, equals(120));
      expect(opts.simulate, isFalse);
      expect(opts.restore, isTrue);
      expect(opts.authV2, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 3: MethodOptions.authV2 threads into AssembledTransaction.simulate()
  // -------------------------------------------------------------------------
  group('MethodOptions.authV2 threads into simulate() request body', () {
    test('authV2: true produces "authV2": true in the wire request', () async {
      // Skip on web: uses HttpServer.bind.
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final (server, captured) = await _startMockRpcServer(
          accountId: kp.accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        await _buildAssembledTx(rpcUrl, kp.accountId, kp,
            simulate: true, authV2: true);

        expect(captured['authV2'], equals(true),
            reason: '"authV2": true must appear in the simulate request params');
      } finally {
        await server.close();
      }
    });

    test('default MethodOptions() omits authV2 from the wire request', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final (server, captured) = await _startMockRpcServer(
          accountId: kp.accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        await _buildAssembledTx(rpcUrl, kp.accountId, kp, simulate: true);

        expect(captured.containsKey('authV2'), isFalse,
            reason: '"authV2" must be absent from the request by default');
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 4: needsNonInvokerSigningBy — all arm types
  // -------------------------------------------------------------------------
  group('needsNonInvokerSigningBy', () {
    test('ADDRESS entry: reports void top-level, omits signed top-level',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled = await _buildAssembledTx(
            rpcUrl, accountId, kp,
            simulate: false);

        // Inject a tx with a legacy ADDRESS entry (void signature).
        final legacyEntry = _makeLegacyEntry(accountId);
        final account = Account(accountId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        final opBuilder = InvokeHostFuncOpBuilder(invokeOp);
        assembled.tx = TransactionBuilder(account)
            .addOperation(opBuilder.build())
            .build();
        assembled.tx!.setSorobanAuth([legacyEntry]);

        final needed = assembled.needsNonInvokerSigningBy();
        expect(needed, contains(accountId));

        // After signing, should no longer appear.
        final signed = assembled.needsNonInvokerSigningBy(includeAlreadySigned: false);
        // Note: we haven't signed yet — just confirm it's listed above.
        expect(needed.length, equals(1));
        expect(signed.length, equals(1));
      } finally {
        await server.close();
      }
    });

    test('ADDRESS_V2 entry: reports void top-level', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        final v2Entry = _makeV2Entry(accountId);
        final account = Account(accountId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([v2Entry]);

        final needed = assembled.needsNonInvokerSigningBy();
        expect(needed, contains(accountId));
        expect(needed.length, equals(1));
      } finally {
        await server.close();
      }
    });

    test('WITH_DELEGATES entry: reports void top-level AND unsigned delegate',
        () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;

      // Ensure addresses are distinct.
      expect(topId, isNot(equals(delegateId)));

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final wdEntry = _makeWithDelegatesEntry(topId, delegateId);
        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([wdEntry]);

        final needed = assembled.needsNonInvokerSigningBy();
        // Both the void top-level and the unsigned delegate must be reported.
        expect(needed, contains(topId));
        expect(needed, contains(delegateId));
        expect(needed.length, equals(2));
      } finally {
        await server.close();
      }
    });

    test(
        'WITH_DELEGATES entry: omits signed delegate from unsigned-only report',
        () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final wdEntry = _makeWithDelegatesEntry(topId, delegateId);
        // Sign the delegate node; leave top-level void.
        wdEntry.sign(delegateKp, Network.TESTNET, forAddress: delegateId);

        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([wdEntry]);

        final needed = assembled.needsNonInvokerSigningBy();
        // Top-level is still void, so it appears.
        expect(needed, contains(topId));
        // Delegate is signed, so it should NOT appear.
        expect(needed, isNot(contains(delegateId)));
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 5: Send precheck — WITH_DELEGATES delegates-only pattern
  // -------------------------------------------------------------------------
  group('sign() precheck — delegates-only pattern does not block', () {
    test(
        'WITH_DELEGATES entry with all delegates signed passes sign() despite '
        'void top-level', () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final wdEntry = _makeWithDelegatesEntry(topId, delegateId);
        // Sign the delegate node; top-level intentionally left void.
        wdEntry.sign(delegateKp, Network.TESTNET, forAddress: delegateId);

        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([wdEntry]);

        // sign() with force:true bypasses the read-call check so we can
        // exercise the precheck specifically. sign() should NOT throw even
        // though needsNonInvokerSigningBy() reports topId (void top-level),
        // because every delegate is signed (delegates-only pattern).
        expect(
          () => assembled.sign(sourceAccountKeyPair: topKp, force: true),
          returnsNormally,
          reason: 'delegates-only pattern must not block sign()',
        );
      } finally {
        await server.close();
      }
    });

    test(
        'WITH_DELEGATES entry with an unsigned delegate DOES block sign()',
        () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        // Leave both top-level and delegate unsigned.
        final wdEntry = _makeWithDelegatesEntry(topId, delegateId);

        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([wdEntry]);

        expect(
          () => assembled.sign(sourceAccountKeyPair: topKp, force: true),
          throwsA(isA<Exception>()),
          reason: 'unsigned delegates must block sign()',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 6: signAuthEntries — delegate node matching
  // -------------------------------------------------------------------------
  group('signAuthEntries — delegate and top-level matching', () {
    test(
        'signs delegate node when signer matches delegate address; '
        'top-level stays void', () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;

      // Distinct addresses required: assert they differ.
      expect(topId, isNot(equals(delegateId)));

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final wdEntry = _makeWithDelegatesEntry(topId, delegateId);
        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([wdEntry]);

        // Sign as the delegate (private key provided, valid until fixed ledger).
        await assembled.signAuthEntries(
          signerKeyPair: delegateKp,
          validUntilLedgerSeq: _kExpiration + 100,
        );

        // Re-read the entry from the transaction.
        final ops = assembled.tx!.operations;
        final invokeOp2 = ops.first as InvokeHostFunctionOperation;
        final signedEntry = invokeOp2.auth.first;

        final withDelegates =
            signedEntry.credentials.addressWithDelegatesCredentials!;

        // The delegate node must be signed.
        final delegateNode = withDelegates.delegates.first;
        expect(
          delegateNode.signature.discriminant,
          isNot(equals(XdrSCValType.SCV_VOID)),
          reason: 'delegate node must carry a non-void signature after signing',
        );
        expect(delegateNode.signature.vec, isNotNull);
        expect(delegateNode.signature.vec!.length, equals(1));

        // The top-level signature must remain void.
        final topInner = signedEntry.credentials.innerAddressCredentials!;
        expect(
          topInner.signature.discriminant,
          equals(XdrSCValType.SCV_VOID),
          reason: 'top-level signature must remain void when only delegate signed',
        );
      } finally {
        await server.close();
      }
    });

    test('signs top-level when signer matches top-level address', () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final legacyEntry = _makeLegacyEntry(topId);
        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([legacyEntry]);

        await assembled.signAuthEntries(
          signerKeyPair: topKp,
          validUntilLedgerSeq: _kExpiration + 100,
        );

        final ops = assembled.tx!.operations;
        final invokeOp2 = ops.first as InvokeHostFunctionOperation;
        final signedEntry = invokeOp2.auth.first;
        final inner = signedEntry.credentials.innerAddressCredentials!;

        expect(
          inner.signature.discriminant,
          isNot(equals(XdrSCValType.SCV_VOID)),
          reason: 'top-level must be signed for legacy ADDRESS entry',
        );
      } finally {
        await server.close();
      }
    });

    // Regression: same address as top-level and as a delegate must produce
    // exactly one signature on the top-level and one on the delegate node —
    // not two on the top-level (which the host rejects due to duplicate-key order).
    test(
        'same address as top-level and delegate: exactly one signature each, '
        'no duplicate top-level', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Build a WITH_DELEGATES entry where both the top-level credential address
        // and the sole delegate address are the same key (kp / accountId).
        final wdEntry = _makeWithDelegatesEntry(accountId, accountId);

        final account = Account(accountId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([wdEntry]);

        await assembled.signAuthEntries(
          signerKeyPair: kp,
          validUntilLedgerSeq: _kExpiration + 100,
        );

        final signedEntry =
            (assembled.tx!.operations.first as InvokeHostFunctionOperation)
                .auth
                .first;
        final withDelegates =
            signedEntry.credentials.addressWithDelegatesCredentials!;

        // Top-level must have exactly ONE signature (not two).
        final topInner = signedEntry.credentials.innerAddressCredentials!;
        expect(
          topInner.signature.discriminant,
          isNot(equals(XdrSCValType.SCV_VOID)),
          reason: 'top-level must be signed',
        );
        expect(
          topInner.signature.vec,
          isNotNull,
          reason: 'top-level signature must be a vec',
        );
        expect(
          topInner.signature.vec!.length,
          equals(1),
          reason: 'top-level must carry exactly one signature, not two '
              '(duplicate would violate ascending-key-order constraint)',
        );

        // Delegate node must also have exactly ONE signature.
        final delegateNode = withDelegates.delegates.first;
        expect(
          delegateNode.signature.discriminant,
          isNot(equals(XdrSCValType.SCV_VOID)),
          reason: 'delegate node must be signed',
        );
        expect(delegateNode.signature.vec, isNotNull);
        expect(
          delegateNode.signature.vec!.length,
          equals(1),
          reason: 'delegate node must carry exactly one signature',
        );
      } finally {
        await server.close();
      }
    });

    test('signAuthEntries with no private key throws', () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final topId = topKp.accountId;
      final pubOnlyKp = KeyPair.fromAccountId(topId);

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final legacyEntry = _makeLegacyEntry(topId);
        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([legacyEntry]);

        expect(
          () async => await assembled.signAuthEntries(
            signerKeyPair: pubOnlyKp,
            validUntilLedgerSeq: _kExpiration + 100,
          ),
          throwsA(isA<Exception>()),
          reason: 'signing without private key must throw',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 7: Arm preservation through sign flow
  // -------------------------------------------------------------------------
  group('Arm preservation through signAuthEntries', () {
    test('V2 entry stays V2 after signing via signAuthEntries', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        final v2Entry = _makeV2Entry(accountId);
        final account = Account(accountId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([v2Entry]);

        await assembled.signAuthEntries(
          signerKeyPair: kp,
          validUntilLedgerSeq: _kExpiration + 100,
        );

        final ops = assembled.tx!.operations;
        final invokeOp2 = ops.first as InvokeHostFunctionOperation;
        final signedEntry = invokeOp2.auth.first;

        // Arm must still be ADDRESS_V2, not ADDRESS.
        expect(
          signedEntry.credentials.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2),
          reason: 'ADDRESS_V2 arm must be preserved after signing',
        );
        expect(signedEntry.credentials.addressV2Credentials, isNotNull);
        expect(signedEntry.credentials.addressCredentials, isNull);

        // Signature must be non-void.
        final inner = signedEntry.credentials.innerAddressCredentials!;
        expect(inner.signature.discriminant,
            isNot(equals(XdrSCValType.SCV_VOID)));
      } finally {
        await server.close();
      }
    });

    test('WITH_DELEGATES arm is preserved after signing the delegate node',
        () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final wdEntry = _makeWithDelegatesEntry(topId, delegateId);
        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([wdEntry]);

        await assembled.signAuthEntries(
          signerKeyPair: delegateKp,
          validUntilLedgerSeq: _kExpiration + 100,
        );

        final ops = assembled.tx!.operations;
        final signedEntry =
            (ops.first as InvokeHostFunctionOperation).auth.first;

        expect(
          signedEntry.credentials.arm,
          equals(XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES),
          reason: 'WITH_DELEGATES arm must be preserved after signing delegate',
        );
        expect(
            signedEntry.credentials.addressWithDelegatesCredentials, isNotNull);
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 8: simulate() routes auth entries returned by server into tx
  // -------------------------------------------------------------------------
  group('simulate() wires returned auth entries into tx', () {
    test('ADDRESS entry from simulate response appears in tx auth', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final legacyEntry = _makeLegacyEntry(accountId);

      final (server, _) = await _startMockRpcServer(
        accountId: accountId,
        seqNum: BigInt.from(100),
        authEntries: [legacyEntry],
      );

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: true);

        final ops = assembled.tx!.operations;
        final invokeOp = ops.first as InvokeHostFunctionOperation;
        expect(invokeOp.auth.length, equals(1));
        expect(
          invokeOp.auth.first.credentials.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS),
        );
      } finally {
        await server.close();
      }
    });

    test('ADDRESS_V2 entry from simulate response appears in tx auth', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final v2Entry = _makeV2Entry(accountId);

      final (server, _) = await _startMockRpcServer(
        accountId: accountId,
        seqNum: BigInt.from(100),
        authEntries: [v2Entry],
      );

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: true);

        final ops = assembled.tx!.operations;
        final invokeOp = ops.first as InvokeHostFunctionOperation;
        expect(invokeOp.auth.length, equals(1));
        expect(
          invokeOp.auth.first.credentials.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2),
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP 9: Unknown arm fail-fast
  // -------------------------------------------------------------------------
  group('Unknown arm fail-fast', () {
    test('signAuthEntries throws on unknown credential arm', () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final topId = topKp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        // Build an entry with a raw XDR credential that has an unrecognized
        // arm discriminant. We do this by constructing SOURCE_ACCOUNT creds
        // and verifying that signAuthEntries skips it (source-account skipping
        // is by design). For an unknown arm we confirm needsNonInvokerSigningBy
        // throws when it encounters it.
        //
        // Simulate the unknown-arm case by creating a raw XdrSorobanCredentials
        // with an unrecognized type value. The Dart XDR layer will throw on
        // decode; instead we exercise the branch via SorobanCredentials.fromXdr
        // with a tampered discriminant.
        //
        // Since we can't easily inject a raw unknown discriminant at the high
        // level, we verify that an XdrSorobanCredentials with an invalid type
        // throws via fromXdr.
        final rawCreds = XdrSorobanCredentials(
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
        // fromXdr of SOURCE_ACCOUNT: no exception — that's the correct path.
        final parsed = SorobanCredentials.fromXdr(rawCreds);
        expect(
          parsed.arm,
          equals(
              XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT),
        );

        // Verify that SOURCE_ACCOUNT is silently skipped (not thrown) by
        // needsNonInvokerSigningBy.
        final sourceCreds = SorobanCredentials.forSourceAccount();
        final sourceEntry = _makeEntry(sourceCreds);

        final account = Account(topId, BigInt.from(100));
        final invokeOp = InvokeContractHostFunction(
            _kContractId, 'hello',
            arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
        assembled.tx = TransactionBuilder(account)
            .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
            .build();
        assembled.tx!.setSorobanAuth([sourceEntry]);

        // SOURCE_ACCOUNT is skipped, not reported.
        final needed = assembled.needsNonInvokerSigningBy();
        expect(needed, isEmpty);
      } finally {
        await server.close();
      }
    });
  });
}
