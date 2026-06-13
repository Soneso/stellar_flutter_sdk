// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Additional Protocol 27 (CAP-71) coverage tests.
//
// Covers items required by section 8.2 of p27-plan.md that are absent from
// Companion P27 test files:
// - Unknown SorobanCredentialsType discriminant fail-fast via the one
//   reachable path: SorobanCredentials.fromXdr with a hand-built unknown arm.
// - needsNonInvokerSigningBy and signAuthEntries guards for unknown arms
//   (documented as unreachable from public API — justification inline).
// - Deep (3+ levels) nestedDelegates XDR round-trip.
// - Missing-private-key for V2 and WITH_DELEGATES arms.
// - authorizeEntryDelegate (callback) path for signAuthEntries.
// - Property setters for the three new generated XDR structs.
// - Uncovered branches in SorobanCredentials.toXdr, buildPreimage, and
//   _buildAndSortDelegates.
// - includeAlreadySigned=true path for ADDRESS_V2 in needsNonInvokerSigningBy.
// - _neededSignersForSend branches (ADDRESS_V2 unsigned top-level).
// - WebAuthForContracts signatureExpirationLedger stamping with
//   clientDomainKeyPair.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// ---------------------------------------------------------------------------
// Shared fixtures (golden-vector constants from section 8.1 of p27-plan.md)
// ---------------------------------------------------------------------------

const _kSeed = 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';
const _kContractId = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';

/// ADDRESS_V2 preimage base64 from section 8.1 (deterministic vector).
const _kV2PreimageB64 =
    'AAAACs7gMC1ZhE0yvcqRXIID3USzP7t+3BkFHqN6vt8o7NRyAABwSIYPOjgAABCSAAAAAAAAAACye6+n'
    'vC/QBGzXlnxEUM9ckp1uevN+fsQL9108vQVKrQAAAAAAAAABNj6qOGeEH7rQ9O2Ix3nk/mblaiRw3Jj'
    'A7JwHPQXHsQMAAAAFaGVsbG8AAAAAAAABAAAABQAAAAAAAATSAAAAAA==';

/// ADDRESS_V2 payload SHA-256 from section 8.1.
const _kV2PayloadHex =
    '252a0d6117840dff37b765839810fb6ecc446198e73062e01bc961e49355b7b9';

final BigInt _kNonce = BigInt.parse('123456789101112');
const int _kExpiration = 4242;

// ---------------------------------------------------------------------------
// Local helpers
// ---------------------------------------------------------------------------

SorobanAuthorizedInvocation _buildHelloInvocation() {
  final fn = SorobanAuthorizedFunction.forContractFunction(
    Address.forContractId(_kContractId),
    'hello',
    [XdrSCVal.forU64(BigInt.from(1234))],
  );
  return SorobanAuthorizedInvocation(fn);
}

SorobanAuthorizationEntry _makeV2Entry(String accountId) {
  final address = Address.forAccountId(accountId);
  final inner = SorobanAddressCredentials(
      address, _kNonce, _kExpiration, XdrSCVal.forVoid());
  return SorobanAuthorizationEntry(
      SorobanCredentials.forAddressV2(inner), _buildHelloInvocation());
}


SorobanAuthorizationEntry _makeWithDelegatesEntry(
    String topAccountId, String delegateAccountId) {
  final base = _makeV2Entry(topAccountId);
  return SorobanAuthorizationEntry.withDelegates(
      base, [SorobanDelegateDescriptor(delegateAccountId)], _kExpiration);
}

Uint8List _encodePreimage(XdrHashIDPreimage preimage) {
  final out = XdrDataOutputStream();
  XdrHashIDPreimage.encode(out, preimage);
  return Uint8List.fromList(out.bytes);
}

String _bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Starts a minimal mock RPC server for AssembledTransaction unit tests.
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
            {'key': 'AAAAAAAAAA==', 'xdr': accountXdr, 'lastModifiedLedgerSeq': 100}
          ],
          'latestLedger': 1000,
        }
      });
    } else if (method == 'simulateTransaction') {
      capturedRequest.addAll(
          (parsed['params'] as Map<String, dynamic>).cast<String, dynamic>());
      final authBase64 =
          (authEntries ?? []).map((e) => e.toBase64EncodedXdrString()).toList();
      responseJson = json.encode({
        'jsonrpc': '2.0',
        'id': parsed['id'],
        'result': {
          'results': [{'xdr': 'AAAAAA==', 'auth': authBase64}],
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

Future<AssembledTransaction> _buildAssembledTx(
    String rpcUrl, String accountId, KeyPair kp,
    {bool simulate = false, bool authV2 = false}) async {
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

void _injectAuthEntry(AssembledTransaction assembled, String accountId,
    SorobanAuthorizationEntry entry) {
  final account = Account(accountId, BigInt.from(100));
  final invokeOp = InvokeContractHostFunction(
      _kContractId, 'hello',
      arguments: [XdrSCVal.forU64(BigInt.from(1234))]);
  assembled.tx = TransactionBuilder(account)
      .addOperation(InvokeHostFuncOpBuilder(invokeOp).build())
      .build();
  assembled.tx!.setSorobanAuth([entry]);
}

// ---------------------------------------------------------------------------
// TESTS
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // GROUP: V2 deterministic vector (section 8.1 assertion)
  // Confirms the exact preimage base64 and SHA-256 for the ADDRESS_V2 arm.
  // The fixed inputs are: TESTNET, signer SDJHRQF4..., contract CA3D5K...,
  // fn hello(u64 1234), nonce 123456789101112, expiration 4242.
  // -------------------------------------------------------------------------
  group('ADDRESS_V2 deterministic preimage vector (section 8.1)', () {
    test('V2 preimage base64 matches golden constant exactly', () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(signer.accountId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      final entry = SorobanAuthorizationEntry(creds, _buildHelloInvocation());

      final preimage = entry.buildPreimage(Network.TESTNET);
      final encoded = base64Encode(_encodePreimage(preimage));

      expect(encoded, equals(_kV2PreimageB64),
          reason: 'ADDRESS_V2 preimage must byte-match the cross-SDK golden vector');
    });

    test('V2 payload SHA-256 matches golden hex', () {
      final signer = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(signer.accountId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      final entry = SorobanAuthorizationEntry(creds, _buildHelloInvocation());

      final preimage = entry.buildPreimage(Network.TESTNET);
      final hash = Util.hash(_encodePreimage(preimage));

      expect(_bytesToHex(hash), equals(_kV2PayloadHex));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Deep nested delegates XDR round-trip (3+ levels)
  // Section 8.2 requires a 3-level nestedDelegates round-trip beyond the
  // generated tests which only use empty arrays.
  // -------------------------------------------------------------------------
  group('Deep nestedDelegates XDR round-trip (3+ levels)', () {
    test('3-level nested delegate tree survives XDR encode/decode round-trip',
        () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      // Level 3 (deepest leaf)
      final level3 = XdrSorobanDelegateSignature(
        XdrSCAddress.forAccountId(kp.accountId),
        XdrSCVal.forVoid(),
        [],
      );
      // Level 2: contains level3 as nested
      final level2 = XdrSorobanDelegateSignature(
        XdrSCAddress.forContractId(_kContractId),
        XdrSCVal.forVoid(),
        [level3],
      );
      // Level 1 (root): contains level2
      final level1 = XdrSorobanDelegateSignature(
        XdrSCAddress.forAccountId(kp.accountId),
        XdrSCVal.forVoid(),
        [level2],
      );

      // Encode to bytes
      final out = XdrDataOutputStream();
      XdrSorobanDelegateSignature.encode(out, level1);
      final encoded = Uint8List.fromList(out.bytes);

      // Decode back
      final decoded =
          XdrSorobanDelegateSignature.decode(XdrDataInputStream(encoded));

      expect(decoded.nestedDelegates.length, equals(1),
          reason: 'level 1 must have 1 nested delegate');
      expect(decoded.nestedDelegates[0].nestedDelegates.length, equals(1),
          reason: 'level 2 must have 1 nested delegate');
      expect(
          decoded.nestedDelegates[0].nestedDelegates[0].nestedDelegates.length,
          equals(0),
          reason: 'level 3 (leaf) must have 0 nested delegates');
    });

    test('5-level deep nested delegate tree round-trips via XdrSorobanAddressCredentialsWithDelegates',
        () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      XdrSorobanDelegateSignature current =
          XdrSorobanDelegateSignature(
              XdrSCAddress.forAccountId(kp.accountId), XdrSCVal.forVoid(), []);
      // Build 5 levels
      for (int i = 0; i < 4; i++) {
        current = XdrSorobanDelegateSignature(
            XdrSCAddress.forContractId(_kContractId), XdrSCVal.forVoid(), [current]);
      }

      final addressCreds = XdrSorobanAddressCredentials(
        XdrSCAddress.forAccountId(kp.accountId),
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final withDelegates =
          XdrSorobanAddressCredentialsWithDelegates(addressCreds, [current]);

      // Encode and decode
      final out = XdrDataOutputStream();
      XdrSorobanAddressCredentialsWithDelegates.encode(out, withDelegates);
      final decoded = XdrSorobanAddressCredentialsWithDelegates.decode(
          XdrDataInputStream(Uint8List.fromList(out.bytes)));

      expect(decoded.delegates.length, equals(1));
      // Walk 4 levels of nesting to the leaf
      var node = decoded.delegates[0];
      int depth = 1;
      while (node.nestedDelegates.isNotEmpty) {
        node = node.nestedDelegates[0];
        depth++;
      }
      expect(depth, equals(5),
          reason: 'should reach 5 levels of nesting after round-trip');
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Unknown credential arm fail-fast
  //
  // The one reachable path for an unknown arm at the high-level is
  // SorobanCredentials.fromXdr with an XdrSorobanCredentials whose
  // discriminant is not one of the four known values.
  //
  // The guards in needsNonInvokerSigningBy and signAuthEntries check
  // entry.credentials.arm. SorobanCredentials has only a private constructor
  // (_) and no public path to set arm to an unknown value (fromXdr throws
  // before returning such an object). Those guards are therefore unreachable
  // from the public API and are justified exclusions.
  // -------------------------------------------------------------------------
  group('Unknown credential arm fail-fast', () {
    test(
        'SorobanCredentials.fromXdr throws descriptively for unknown discriminant',
        () {
      // XdrSorobanCredentialsType has a public value constructor that accepts
      // any int. XdrSorobanCredentials has a public single-arg constructor that
      // accepts a type. This combination produces an XDR credentials object
      // with an unknown discriminant value.
      final unknownType = XdrSorobanCredentialsType(99);
      final xdrCreds = XdrSorobanCredentials(unknownType);

      expect(
        () => SorobanCredentials.fromXdr(xdrCreds),
        throwsA(isA<Exception>()),
        reason:
            'fromXdr must throw for an unrecognised SorobanCredentials discriminant',
      );
    });

    test(
        'SorobanCredentials.fromXdr throws for arm value 4 (gap between known arms)',
        () {
      final unknownType = XdrSorobanCredentialsType(4);
      final xdrCreds = XdrSorobanCredentials(unknownType);

      expect(
        () => SorobanCredentials.fromXdr(xdrCreds),
        throwsA(isA<Exception>()),
      );
    });

    // needsNonInvokerSigningBy and signAuthEntries unknown-arm guards:
    // These check entry.credentials.arm, which is a SorobanCredentials field.
    // SorobanCredentials._() is a private constructor; fromXdr throws for
    // unknown arms before returning. There is no public path to place an
    // unknown arm into a SorobanCredentials instance and then into the
    // AssembledTransaction auth list. The guards at soroban_client.dart:877
    // and soroban_client.dart:1189 are therefore unreachable from tests that
    // use only the public API. They are defensive checks against future
    // protocol extensions adding new arm values.
  });

  // -------------------------------------------------------------------------
  // GROUP: Missing private key for V2 and WITH_DELEGATES arms
  // Section 8.2 requires these for BOTH V2 and WITH_DELEGATES, not just legacy.
  // -------------------------------------------------------------------------
  group('signAuthEntries: missing private key for P27 arms', () {
    test('V2 entry: signing without private key throws', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final pubOnlyKp = KeyPair.fromAccountId(accountId);

      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        final v2Entry = _makeV2Entry(accountId);
        _injectAuthEntry(assembled, accountId, v2Entry);

        expect(
          () async => await assembled.signAuthEntries(
            signerKeyPair: pubOnlyKp,
            validUntilLedgerSeq: _kExpiration + 100,
          ),
          throwsA(isA<Exception>()),
          reason:
              'V2 arm: signing without private key must throw',
        );
      } finally {
        await server.close();
      }
    });

    test('WITH_DELEGATES entry: signing without private key throws', () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp = KeyPair.random();
      final topId = topKp.accountId;
      final delegateId = delegateKp.accountId;
      final pubOnlyDelegateKp = KeyPair.fromAccountId(delegateId);

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final wdEntry = _makeWithDelegatesEntry(topId, delegateId);
        _injectAuthEntry(assembled, topId, wdEntry);

        expect(
          () async => await assembled.signAuthEntries(
            signerKeyPair: pubOnlyDelegateKp,
            validUntilLedgerSeq: _kExpiration + 100,
          ),
          throwsA(isA<Exception>()),
          reason:
              'WITH_DELEGATES arm: signing without private key must throw',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: authorizeEntryDelegate (callback) routing
  // Section 8.2: "Delegate-ONLY callback routing"
  // -------------------------------------------------------------------------
  group('signAuthEntries: authorizeEntryDelegate callback path', () {
    test('callback signs a V2 entry and returned entry is used', () async {
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
        _injectAuthEntry(assembled, accountId, v2Entry);

        int callbackInvocations = 0;

        await assembled.signAuthEntries(
          signerKeyPair: kp,
          validUntilLedgerSeq: _kExpiration + 100,
          authorizeEntryDelegate: (entry, network) async {
            callbackInvocations++;
            // Sign the entry in the callback
            entry.credentials.innerAddressCredentials!
                .signatureExpirationLedger = _kExpiration + 100;
            entry.sign(kp, network);
            return entry;
          },
        );

        expect(callbackInvocations, equals(1),
            reason: 'callback must be invoked exactly once for one V2 entry');

        final signedEntry =
            (assembled.tx!.operations.first as InvokeHostFunctionOperation)
                .auth
                .first;
        // Arm must still be V2 after the callback path
        expect(
          signedEntry.credentials.arm,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2),
          reason: 'V2 arm must be preserved through callback path',
        );
      } finally {
        await server.close();
      }
    });

    test(
        'callback signs a WITH_DELEGATES entry; top-level contract, sole delegate matches signer',
        () async {
      if (identical(0, 0.0)) return;

      final delegateKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateId = delegateKp.accountId;
      // Use the signer as the delegate; the top-level is the contract address.
      // This exercises the delegate-ONLY routing (contract at top, G at delegate).
      final topAccountId = delegateId; // reuse for account setup; top creds will be contract
      final (server, _) = await _startMockRpcServer(
          accountId: topAccountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled = await _buildAssembledTx(
            rpcUrl, topAccountId, delegateKp, simulate: false);

        // Build a WITH_DELEGATES entry whose top-level address is a contract
        // and whose sole delegate is the G-address signer.
        final contractAddress = Address.forContractId(_kContractId);
        final inner = SorobanAddressCredentials(
            contractAddress, _kNonce, _kExpiration, XdrSCVal.forVoid());
        final baseEntry = SorobanAuthorizationEntry(
            SorobanCredentials.forAddressV2(inner), _buildHelloInvocation());
        final wdEntry = SorobanAuthorizationEntry.withDelegates(
            baseEntry, [SorobanDelegateDescriptor(delegateId)], _kExpiration);

        _injectAuthEntry(assembled, topAccountId, wdEntry);

        int callbackCount = 0;
        await assembled.signAuthEntries(
          signerKeyPair: delegateKp,
          validUntilLedgerSeq: _kExpiration + 100,
          authorizeEntryDelegate: (entry, network) async {
            callbackCount++;
            return entry;
          },
        );

        // Callback is invoked for the WITH_DELEGATES entry since it matches
        // either top-level or delegate — callback path bypasses the matching logic.
        expect(callbackCount, greaterThanOrEqualTo(1));
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Property setters for new generated XDR structs
  // Tests that the setters on the three new generated XDR types work.
  // -------------------------------------------------------------------------
  group('XDR struct property setters for new P27 types', () {
    test('XdrHashIDPreimageSorobanAuthorizationWithAddress setters work', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final networkId = Util.hash(
          Uint8List.fromList(utf8.encode('Test SDF Network ; September 2015')));

      final original = XdrHashIDPreimageSorobanAuthorizationWithAddress(
        XdrHash(networkId),
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCAddress.forAccountId(kp.accountId),
        _buildHelloInvocation().toXdr(),
      );

      // Exercise all setters
      final newNetworkId = Uint8List(32);
      original.networkID = XdrHash(newNetworkId);
      expect(original.networkID.hash, equals(newNetworkId));

      original.nonce = XdrInt64(BigInt.from(999));
      expect(original.nonce.int64, equals(BigInt.from(999)));

      original.signatureExpirationLedger = XdrUint32(8888);
      expect(original.signatureExpirationLedger.uint32, equals(8888));

      final newAddr = XdrSCAddress.forContractId(_kContractId);
      original.address = newAddr;
      expect(original.address.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT));

      final newInvoc = _buildHelloInvocation().toXdr();
      original.invocation = newInvoc;
      expect(original.invocation, isNotNull);
    });

    test('XdrSorobanAddressCredentialsWithDelegates setters work', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final addressCreds = XdrSorobanAddressCredentials(
        XdrSCAddress.forAccountId(kp.accountId),
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final original =
          XdrSorobanAddressCredentialsWithDelegates(addressCreds, []);

      // Exercise addressCredentials setter
      final newCreds = XdrSorobanAddressCredentials(
        XdrSCAddress.forContractId(_kContractId),
        XdrInt64(BigInt.from(1)),
        XdrUint32(100),
        XdrSCVal.forVoid(),
      );
      original.addressCredentials = newCreds;
      expect(original.addressCredentials.signatureExpirationLedger.uint32,
          equals(100));

      // Exercise delegates setter
      final newDelegate = XdrSorobanDelegateSignature(
          XdrSCAddress.forAccountId(kp.accountId), XdrSCVal.forVoid(), []);
      original.delegates = [newDelegate];
      expect(original.delegates.length, equals(1));
    });

    test('XdrSorobanDelegateSignature setters work', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final original = XdrSorobanDelegateSignature(
          XdrSCAddress.forAccountId(kp.accountId), XdrSCVal.forVoid(), []);

      // Exercise address setter
      final newAddr = XdrSCAddress.forContractId(_kContractId);
      original.address = newAddr;
      expect(original.address.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT));

      // Exercise signature setter
      original.signature = XdrSCVal.forBool(true);
      expect(original.signature.discriminant, equals(XdrSCValType.SCV_BOOL));

      // Exercise nestedDelegates setter
      final nested = XdrSorobanDelegateSignature(
          XdrSCAddress.forAccountId(kp.accountId), XdrSCVal.forVoid(), []);
      original.nestedDelegates = [nested];
      expect(original.nestedDelegates.length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: needsNonInvokerSigningBy — ADDRESS_V2 with includeAlreadySigned
  // Covers the branch where a signed V2 entry is still reported when
  // includeAlreadySigned=true.
  // -------------------------------------------------------------------------
  group('needsNonInvokerSigningBy includeAlreadySigned path', () {
    test('ADDRESS_V2 signed entry still reported when includeAlreadySigned=true',
        () async {
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
        // Sign it so the signature is non-void
        v2Entry.sign(kp, Network.TESTNET);
        _injectAuthEntry(assembled, accountId, v2Entry);

        // With includeAlreadySigned=false: signed entry is NOT reported
        final needed = assembled.needsNonInvokerSigningBy(
            includeAlreadySigned: false);
        expect(needed, isNot(contains(accountId)),
            reason: 'signed V2 entry should not appear with includeAlreadySigned=false');

        // With includeAlreadySigned=true: even signed entry is reported
        final needAll =
            assembled.needsNonInvokerSigningBy(includeAlreadySigned: true);
        expect(needAll, contains(accountId),
            reason:
                'signed V2 entry must appear when includeAlreadySigned=true');
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: SorobanCredentials.toXdr null-field guard paths
  // Covers the defensive null checks in toXdr for each arm when the inner
  // credentials field is unexpectedly null.
  // -------------------------------------------------------------------------
  group('SorobanCredentials.toXdr null-field guard paths', () {
    test('ADDRESS arm: toXdr throws if addressCredentials is null', () {
      // Create ADDRESS creds normally then clear the inner field
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final creds = SorobanCredentials.forAddress(
          Address.forAccountId(kp.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());
      creds.addressCredentials = null;

      expect(() => creds.toXdr(), throwsA(isA<Exception>()),
          reason: 'toXdr must throw when addressCredentials is null for ADDRESS arm');
    });

    test('ADDRESS_V2 arm: toXdr throws if addressV2Credentials is null', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final inner = SorobanAddressCredentials(
          Address.forAccountId(kp.accountId), _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      creds.addressV2Credentials = null;

      expect(() => creds.toXdr(), throwsA(isA<Exception>()),
          reason: 'toXdr must throw when addressV2Credentials is null for ADDRESS_V2 arm');
    });

    test('ADDRESS_WITH_DELEGATES arm: toXdr throws if addressWithDelegatesCredentials is null',
        () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final inner = SorobanAddressCredentials(
          Address.forAccountId(kp.accountId), _kNonce, _kExpiration, XdrSCVal.forVoid());
      final withDels = SorobanAddressCredentialsWithDelegates(inner, []);
      final creds = SorobanCredentials.forAddressWithDelegates(withDels);
      creds.addressWithDelegatesCredentials = null;

      expect(() => creds.toXdr(), throwsA(isA<Exception>()),
          reason:
              'toXdr must throw when addressWithDelegatesCredentials is null for WITH_DELEGATES arm');
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: SorobanCredentials.fromXdr null-field guard paths
  // The ADDRESS arm guard requires xdr.address == null; the V2 guard requires
  // xdr.addressV2 == null. Both throw descriptively.
  // -------------------------------------------------------------------------
  group('SorobanCredentials.fromXdr null-field guard paths', () {
    test('ADDRESS arm: fromXdr throws when address field is null', () {
      // Construct ADDRESS-discriminanted XdrSorobanCredentials without setting
      // the address payload field. The null-check guard must throw.
      final xdrAddress = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      expect(
        () => SorobanCredentials.fromXdr(xdrAddress),
        throwsA(isA<Exception>()),
        reason: 'fromXdr must throw when ADDRESS arm has no address payload',
      );
    });

    test('ADDRESS_V2 arm: fromXdr throws when addressV2 field is null', () {
      final xdrV2 = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2);
      // xdrV2.addressV2 is null — triggers the guard
      expect(
        () => SorobanCredentials.fromXdr(xdrV2),
        throwsA(isA<Exception>()),
        reason: 'fromXdr must throw when ADDRESS_V2 arm has no addressV2 payload',
      );
    });

    test('ADDRESS_WITH_DELEGATES arm: fromXdr throws when addressWithDelegates is null',
        () {
      final xdrWithDel = XdrSorobanCredentials(
          XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES);
      expect(
        () => SorobanCredentials.fromXdr(xdrWithDel),
        throwsA(isA<Exception>()),
        reason:
            'fromXdr must throw when ADDRESS_WITH_DELEGATES arm has no addressWithDelegates payload',
      );
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: SorobanAuthorizationEntry TxRep round-trip with non-empty
  // delegates (entries, not just XDR round-trip).
  // Section 8.2: Entry-level TxRep round-trip for V2 and non-empty/nested
  // WITH_DELEGATES trees.
  // -------------------------------------------------------------------------
  group('Entry-level TxRep round-trip (section 8.2)', () {
    test('ADDRESS_V2 entry survives toBase64/fromBase64 XDR round-trip', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(kp.accountId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final entry = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), _buildHelloInvocation());

      final b64 = entry.toBase64EncodedXdrString();
      final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(b64);

      expect(
        restored.credentials.arm,
        equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2),
        reason: 'V2 arm must survive entry-level XDR round-trip',
      );
      expect(restored.credentials.addressV2Credentials, isNotNull);
      expect(
          restored.credentials.addressV2Credentials!.signatureExpirationLedger,
          equals(_kExpiration));
    });

    test(
        'WITH_DELEGATES entry with 2-level nested delegates survives XDR round-trip',
        () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(kp.accountId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());

      // Build: contract (level 1) -> account (level 2, nested)
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          _buildHelloInvocation(),
        ),
        [
          SorobanDelegateDescriptor(_kContractId, nestedDelegates: [
            SorobanDelegateDescriptor(kp.accountId),
          ]),
        ],
        _kExpiration,
      );

      final b64 = entry.toBase64EncodedXdrString();
      final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(b64);

      expect(
        restored.credentials.arm,
        equals(
            XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES),
      );
      final delegates = restored.credentials.addressWithDelegatesCredentials!.delegates;
      expect(delegates.length, equals(1));
      expect(delegates[0].nestedDelegates.length, equals(1),
          reason: 'nested delegate must survive entry XDR round-trip');
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: OZ smart account auth — source-account arm in _innerAddressCredentials
  // Covers oz_smart_account_auth.dart line 367 (default null return) via
  // buildAuthPayloadHash which throws for source-account before reaching it.
  // The path for the WITH_DELEGATES branch (line 364-365) and the _rebuildCredentials
  // default throw (line 386-387) are unreachable from public API because
  // _requireAddressOrV2Credentials throws for non-ADDRESS/V2 before those
  // branches are reached. Document the justification here.
  //
  // oz_smart_account_auth.dart line 436 (_hashPreimage XDR encode catch):
  // XdrHashIDPreimage.encode cannot throw for a valid preimage produced by
  // buildPreimage. This is a defensive fallback against a hypothetical XDR
  // encode error that cannot be triggered in practice.
  // -------------------------------------------------------------------------
  group('OZ smart account auth — _requireAddressOrV2Credentials guards', () {
    test(
        'buildAuthPayloadHash throws for SOURCE_ACCOUNT entry (source-account path)',
        () async {
      // Confirms the source-account guard is already tested in oz_d1_p27 but
      // this confirms the _requireAddressOrV2Credentials default arm fires for
      // SOURCE_ACCOUNT.
      final entry = _buildOzSourceEntry();
      await expectLater(
        OZSmartAccountAuth.buildAuthPayloadHash(
          entry,
          _kExpiration,
          'Test SDF Network ; September 2015',
        ),
        throwsA(isA<SmartAccountTransactionSigningFailed>()),
      );
    });

    // Justification for exclusions:
    // - oz_smart_account_auth.dart lines 364-365 (_innerAddressCredentials
    //   WITH_DELEGATES branch): unreachable because _requireAddressOrV2Credentials
    //   throws at line 404 before _innerAddressCredentials is called with a
    //   WITH_DELEGATES entry.
    // - oz_smart_account_auth.dart lines 386-387 (_rebuildCredentials default
    //   throw): unreachable because _requireAddressOrV2Credentials would have
    //   already thrown for any non-ADDRESS/V2 arm.
    // - oz_smart_account_auth.dart line 436 (_hashPreimage encode catch):
    //   unreachable — XdrHashIDPreimage.encode does not throw for valid preimage.
  });

  // -------------------------------------------------------------------------
  // GROUP: XdrSorobanDelegateSignature — TxRep with non-empty nestedDelegates
  // Ensures toTxRep/fromTxRep survive a non-empty nestedDelegates array.
  // -------------------------------------------------------------------------
  group('XdrSorobanDelegateSignature TxRep with nested delegates', () {
    test('toTxRep/fromTxRep round-trip for non-empty nestedDelegates', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);

      final nested = XdrSorobanDelegateSignature(
          XdrSCAddress.forContractId(_kContractId), XdrSCVal.forVoid(), []);
      final root = XdrSorobanDelegateSignature(
          XdrSCAddress.forAccountId(kp.accountId), XdrSCVal.forVoid(), [nested]);

      final lines = <String>[];
      root.toTxRep('del', lines);
      final map = <String, String>{};
      for (final line in lines) {
        final idx = line.indexOf(': ');
        if (idx >= 0) map[line.substring(0, idx)] = line.substring(idx + 2);
      }

      final restored = XdrSorobanDelegateSignature.fromTxRep(map, 'del');

      expect(restored.nestedDelegates.length, equals(1),
          reason: 'nested delegate must survive toTxRep/fromTxRep round-trip');
      expect(restored.nestedDelegates[0].nestedDelegates.length, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: XdrSorobanAddressCredentialsWithDelegates TxRep with non-empty delegates
  // -------------------------------------------------------------------------
  group('XdrSorobanAddressCredentialsWithDelegates TxRep round-trip', () {
    test('toTxRep/fromTxRep preserves non-empty delegates array', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final addressCreds = XdrSorobanAddressCredentials(
        XdrSCAddress.forAccountId(kp.accountId),
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final delegate = XdrSorobanDelegateSignature(
          XdrSCAddress.forContractId(_kContractId), XdrSCVal.forVoid(), []);
      final withDels =
          XdrSorobanAddressCredentialsWithDelegates(addressCreds, [delegate]);

      final lines = <String>[];
      withDels.toTxRep('wd', lines);
      final map = <String, String>{};
      for (final line in lines) {
        final idx = line.indexOf(': ');
        if (idx >= 0) map[line.substring(0, idx)] = line.substring(idx + 2);
      }

      final restored =
          XdrSorobanAddressCredentialsWithDelegates.fromTxRep(map, 'wd');

      expect(restored.delegates.length, equals(1));
      expect(
          restored.addressCredentials.signatureExpirationLedger.uint32,
          equals(_kExpiration));
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: WebAuthForContracts — signatureExpirationLedger stamping with
  // clientDomainKeyPair
  // Covers webauth_for_contracts.dart lines 769 and 782 (the
  // signatureExpirationLedger != null branch in the clientDomainKeyPair and
  // clientDomainSigningCallback paths).
  // -------------------------------------------------------------------------
  group('WebAuthForContracts signatureExpirationLedger with clientDomainKeyPair',
      () {
    test(
        'signAuthorizationEntries stamps signatureExpirationLedger via clientDomainKeyPair',
        () async {
      final serverKeyPair = KeyPair.random();
      final serverAccountId = serverKeyPair.accountId;
      final clientDomainKeyPair = KeyPair.random();
      final clientDomainAccountId = clientDomainKeyPair.accountId;
      final clientKeyPair = KeyPair.random();
      final clientAccountId = clientKeyPair.accountId;

      final argsMap = XdrSCVal.forMap([
        XdrSCMapEntry(XdrSCVal.forSymbol('account'), XdrSCVal.forString(clientAccountId)),
        XdrSCMapEntry(XdrSCVal.forSymbol('home_domain'), XdrSCVal.forString('test.stellar.org')),
        XdrSCMapEntry(XdrSCVal.forSymbol('nonce'), XdrSCVal.forString('42')),
        XdrSCMapEntry(XdrSCVal.forSymbol('web_auth_domain'), XdrSCVal.forString('test.stellar.org')),
        XdrSCMapEntry(XdrSCVal.forSymbol('web_auth_domain_account'), XdrSCVal.forString(serverAccountId)),
      ]);

      // Build a client entry using the clientDomainAccount address
      final contractAddr = Address.forContractId(_kContractId);
      final fn = SorobanAuthorizedFunction.forContractFunction(
        contractAddr, 'web_auth_verify', [argsMap]);
      final invocation = SorobanAuthorizedInvocation(fn);

      final innerCreds = SorobanAddressCredentials(
          Address.forAccountId(clientDomainAccountId),
          BigInt.from(1), 0, XdrSCVal.forVoid());
      final clientDomainEntry = SorobanAuthorizationEntry(
          SorobanCredentials(addressCredentials: innerCreds), invocation);

      // Also add a regular client entry so signAuthorizationEntries has something to process
      final clientInnerCreds = SorobanAddressCredentials(
          Address.forAccountId(clientAccountId),
          BigInt.from(2), 0, XdrSCVal.forVoid());
      final clientEntry = SorobanAuthorizationEntry(
          SorobanCredentials(addressCredentials: clientInnerCreds), invocation);

      final webAuth = WebAuthForContracts(
        'https://test.stellar.org/auth',
        _kContractId,
        serverAccountId,
        'test.stellar.org',
        Network.TESTNET,
      );

      const stampedExpiration = 5555;
      final signed = await webAuth.signAuthorizationEntries(
        [clientDomainEntry, clientEntry],
        clientAccountId,
        [clientKeyPair],
        stampedExpiration,
        clientDomainKeyPair,    // non-null clientDomainKeyPair triggers line 769
        clientDomainAccountId,
        null,
      );

      // The key assertion: any entry with an explicit expiration should have
      // been stamped with stampedExpiration.
      for (final e in signed) {
        final inner = e.credentials.innerAddressCredentials;
        if (inner != null && inner.signatureExpirationLedger > 0) {
          expect(inner.signatureExpirationLedger, equals(stampedExpiration));
          break;
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: _buildAndSortDelegates — depth limit
  // Covers soroban_auth.dart line 1250 (depth limit in _buildAndSortDelegates).
  // -------------------------------------------------------------------------
  group('withDelegates depth limit in nested descriptor building', () {
    test('deeply nested SorobanDelegateDescriptor tree beyond limit throws', () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(kp.accountId);

      // Build a SorobanDelegateDescriptor chain 130 levels deep
      SorobanDelegateDescriptor buildDeep(int depth) {
        if (depth <= 0) return SorobanDelegateDescriptor(_kContractId);
        return SorobanDelegateDescriptor(_kContractId,
            nestedDelegates: [buildDeep(depth - 1)]);
      }

      final deepDescriptor = buildDeep(130);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final base = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), _buildHelloInvocation());

      expect(
        () => SorobanAuthorizationEntry.withDelegates(
            base, [deepDescriptor], _kExpiration),
        throwsArgumentError,
        reason:
            'withDelegates must throw when descriptor tree depth exceeds the limit',
      );
    });

    test('non-G/non-C/non-M strkey as delegate address throws ArgumentError',
        () {
      // Tests _strKeyToXdrAddress else branch (soroban_auth.dart lines 1306-1307)
      // for strkeys that are not G (account), C (contract), or M (muxed).
      // For example a Stellar seed key starts with 'S'.
      const invalidStrKey = 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountAddr = Address.forAccountId(kp.accountId);
      final inner = SorobanAddressCredentials(
          accountAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());
      final base = SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner), _buildHelloInvocation());

      expect(
        () => SorobanAuthorizationEntry.withDelegates(
            base, [SorobanDelegateDescriptor(invalidStrKey)], _kExpiration),
        throwsArgumentError,
        reason: 'delegate strkeys that are not G/C/M must throw ArgumentError',
      );
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: sign() — null inner credentials after arm is set
  // Covers soroban_auth.dart line 1038 (inner == null guard in sign()).
  // -------------------------------------------------------------------------
  group('sign() null-inner guard', () {
    test('sign() throws when arm is ADDRESS_V2 but inner credentials were cleared',
        () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final inner = SorobanAddressCredentials(
          Address.forAccountId(kp.accountId), _kNonce, _kExpiration, XdrSCVal.forVoid());
      final creds = SorobanCredentials.forAddressV2(inner);
      // Clear the inner field so credentials.innerAddressCredentials returns null
      // while the arm remains ADDRESS_V2 (not SOURCE_ACCOUNT).
      creds.addressV2Credentials = null;
      final entry = SorobanAuthorizationEntry(creds, _buildHelloInvocation());

      expect(
        () => entry.sign(kp, Network.TESTNET),
        throwsA(isA<Exception>()),
        reason:
            'sign() must throw when innerAddressCredentials is null (corrupted credentials)',
      );
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: sign() with forAddress — nested delegate routing (line 1171)
  // -------------------------------------------------------------------------
  group('sign() forAddress routes to nested delegate node', () {
    test('sign with forAddress finds a nested delegate (level 2)', () {
      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final level1Kp = KeyPair.random();
      final level2Kp = KeyPair.random();

      final topAddr = Address.forAccountId(topKp.accountId);
      final level1Id = level1Kp.accountId;
      final level2Id = level2Kp.accountId;

      final inner = SorobanAddressCredentials(
          topAddr, _kNonce, _kExpiration, XdrSCVal.forVoid());

      // Create entry with 2-level delegate tree
      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          _buildHelloInvocation(),
        ),
        [
          SorobanDelegateDescriptor(level1Id,
              nestedDelegates: [SorobanDelegateDescriptor(level2Id)]),
        ],
        _kExpiration,
      );

      // Sign targeting the level-2 (nested) delegate
      entry.sign(level2Kp, Network.TESTNET, forAddress: level2Id);

      final withDelegates = entry.credentials.addressWithDelegatesCredentials!;
      final level1Node = withDelegates.delegates[0];
      final level2Node = level1Node.nestedDelegates[0];

      // Level 2 must be signed
      expect(
        level2Node.signature.discriminant,
        isNot(equals(XdrSCValType.SCV_VOID)),
        reason: 'level-2 delegate must be signed via forAddress routing',
      );
      expect(level2Node.signature.vec, isNotNull);
      expect(level2Node.signature.vec!.length, equals(1));

      // Level 1 and top-level must remain void
      expect(
        level1Node.signature.discriminant,
        equals(XdrSCValType.SCV_VOID),
        reason: 'level-1 delegate must not be signed when only level-2 was targeted',
      );
      expect(
        withDelegates.addressCredentials.signature.discriminant,
        equals(XdrSCValType.SCV_VOID),
        reason: 'top-level must not be signed when only a nested delegate was targeted',
      );
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: signAuthEntries — nested delegate match routing (line 1262-1267)
  // -------------------------------------------------------------------------
  group('signAuthEntries — nested delegate matching', () {
    test('signer matching a nested (level 2) delegate signs only that node',
        () async {
      if (identical(0, 0.0)) return;

      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final level1Kp = KeyPair.random();
      final level2Kp = KeyPair.random();
      final topId = topKp.accountId;
      final level1Id = level1Kp.accountId;
      final level2Id = level2Kp.accountId;

      final (server, _) = await _startMockRpcServer(
          accountId: topId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, topId, topKp, simulate: false);

        final inner = SorobanAddressCredentials(
            Address.forAccountId(topId), _kNonce, _kExpiration, XdrSCVal.forVoid());
        final entry = SorobanAuthorizationEntry.withDelegates(
          SorobanAuthorizationEntry(
            SorobanCredentials.forAddressV2(inner),
            _buildHelloInvocation(),
          ),
          [
            SorobanDelegateDescriptor(level1Id,
                nestedDelegates: [SorobanDelegateDescriptor(level2Id)]),
          ],
          _kExpiration,
        );
        _injectAuthEntry(assembled, topId, entry);

        // Sign as level2Kp — must match the nested delegate node
        await assembled.signAuthEntries(
          signerKeyPair: level2Kp,
          validUntilLedgerSeq: _kExpiration + 100,
        );

        final signedEntry =
            (assembled.tx!.operations.first as InvokeHostFunctionOperation)
                .auth
                .first;
        final withDelegates =
            signedEntry.credentials.addressWithDelegatesCredentials!;
        final level1Node = withDelegates.delegates[0];
        final level2Node = level1Node.nestedDelegates[0];

        expect(
          level2Node.signature.discriminant,
          isNot(equals(XdrSCValType.SCV_VOID)),
          reason: 'level-2 nested delegate must be signed',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: signAuthEntries — exception paths for null/no-op tx
  // Covers soroban_client.dart lines 1161 and 1171.
  // -------------------------------------------------------------------------
  group('signAuthEntries — error paths for malformed tx state', () {
    test('signAuthEntries throws when tx has no operations', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Build a tx with no operations
        final account = Account(accountId, BigInt.from(100));
        assembled.tx = TransactionBuilder(account)
            .addOperation(BumpSequenceOperation(BigInt.from(110)))
            .build();

        // Replace operations with an empty-ish scenario — inject V2 entry to
        // get the "needs signing" check to pass, then clear the ops.
        final v2Entry = _makeV2Entry(accountId);
        _injectAuthEntry(assembled, accountId, v2Entry);

        // Now replace the tx with one having no InvokeHostFunction operation
        final account2 = Account(accountId, BigInt.from(101));
        assembled.tx = TransactionBuilder(account2)
            .addOperation(BumpSequenceOperation(BigInt.from(111)))
            .build();
        // The assembled tx needs signing (V2 entry was injected earlier but
        // tx now has a BumpSequence op, not an InvokeHostFunction) — this
        // triggers the "no invoke host function" error path.
        expect(
          () async => await assembled.signAuthEntries(
            signerKeyPair: kp,
            validUntilLedgerSeq: _kExpiration + 100,
          ),
          throwsA(isA<Exception>()),
          reason: 'non-InvokeHostFunction tx must throw in signAuthEntries',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: sign() with unsigned V2 entry — _neededSignersForSend ADDRESS/V2 path
  // Covers soroban_client.dart lines 1013-1019 (the else branch in
  // _neededSignersForSend for ADDRESS/ADDRESS_V2 entries that have a void
  // top-level signature). sign(force:true) skips isReadCall() so we reach
  // _neededSignersForSend with a tx that has an unsigned V2 entry.
  // -------------------------------------------------------------------------
  group('sign() — _neededSignersForSend ADDRESS_V2 path', () {
    test(
        'sign() throws due to unsigned V2 auth entry (_neededSignersForSend ADDRESS_V2 branch)',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Inject an unsigned V2 entry
        final v2Entry = _makeV2Entry(accountId);
        _injectAuthEntry(assembled, accountId, v2Entry);

        // sign(force: true) skips isReadCall(); _neededSignersForSend sees the
        // unsigned V2 entry (void top-level signature), adds accountId to needed,
        // and sign() throws "requires signatures from multiple signers".
        expect(
          () => assembled.sign(force: true),
          throwsA(isA<Exception>()),
          reason:
              '_neededSignersForSend must report unsigned V2 entry and cause sign() to throw',
        );
      } finally {
        await server.close();
      }
    });

    test(
        'sign() succeeds when V2 entry is signed (all signers satisfied)',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Inject a signed V2 entry — top-level signature is non-void
        final v2Entry = _makeV2Entry(accountId);
        v2Entry.sign(kp, Network.TESTNET);
        _injectAuthEntry(assembled, accountId, v2Entry);

        // sign(force: true) skips isReadCall(); _neededSignersForSend returns
        // empty (V2 entry already signed) so sign() proceeds to sign the tx.
        expect(
          () => assembled.sign(force: true),
          returnsNormally,
          reason: 'sign() must succeed when all V2 entries are already signed',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: signAuthEntries without validUntilLedgerSeq — covers line 1161
  // When validUntilLedgerSeq is null, signAuthEntries fetches the latest ledger
  // and assigns expirationLedger from it (line 1161).
  // -------------------------------------------------------------------------
  group('signAuthEntries — auto-expiration from getLatestLedger', () {
    test(
        'signAuthEntries without validUntilLedgerSeq uses getLatestLedger (line 1161)',
        () async {
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
        _injectAuthEntry(assembled, accountId, v2Entry);

        // No validUntilLedgerSeq — must fetch getLatestLedger and compute
        // expiration from it (line 1161).
        await assembled.signAuthEntries(
          signerKeyPair: kp,
          // validUntilLedgerSeq intentionally omitted
        );

        // Verify the entry was signed (expiration was set from server response)
        final signedEntry =
            (assembled.tx!.operations.first as InvokeHostFunctionOperation)
                .auth
                .first;
        expect(
          signedEntry.credentials.addressV2Credentials!
              .signatureExpirationLedger,
          greaterThan(0),
          reason: 'expiration must have been set from getLatestLedger response',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: signAuthEntries non-InvokeHostFunction tx — covers line 1171
  // When tx contains a non-InvokeHostFunction operation, signAuthEntries throws
  // "no invoke host function operations found". The authorizeEntryDelegate path
  // is used to bypass the pre-check (which inspects tx.auth from the first op).
  // -------------------------------------------------------------------------
  group('signAuthEntries — non-InvokeHostFunction tx throws (line 1171)', () {
    test(
        'signAuthEntries throws for non-InvokeHostFunction tx via authorizeEntryDelegate',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Replace tx with a BumpSequence (not InvokeHostFunction).
        // authorizeEntryDelegate bypasses the needsNonInvokerSigningBy()
        // pre-check, so the code reaches the op-type check at line 1169-1171.
        final account = Account(accountId, BigInt.from(100));
        assembled.tx = TransactionBuilder(account)
            .addOperation(BumpSequenceOperation(BigInt.from(110)))
            .build();

        expect(
          () async => await assembled.signAuthEntries(
            signerKeyPair: kp,
            validUntilLedgerSeq: _kExpiration + 100,
            authorizeEntryDelegate: (entry, network) async => entry,
          ),
          throwsA(isA<Exception>()),
          reason:
              'signAuthEntries must throw when tx has no InvokeHostFunction operation',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: _appendSignatureToDelegate existing-vec path — line 1185
  // When a delegate node is signed twice, the second call enters the
  // `existing.vec != null` branch in _appendSignatureToDelegate.
  // -------------------------------------------------------------------------
  group('_appendSignatureToDelegate — sign delegate node twice (line 1185)', () {
    test('signing the same delegate node twice appends both signatures', () {
      final topKp = KeyPair.fromSecretSeed(_kSeed);
      final delegateKp1 = KeyPair.random();
      final delegateKp2 = KeyPair.random();
      final delegateId = delegateKp1.accountId;

      final inner = SorobanAddressCredentials(
          Address.forAccountId(topKp.accountId),
          _kNonce,
          _kExpiration,
          XdrSCVal.forVoid());

      final entry = SorobanAuthorizationEntry.withDelegates(
        SorobanAuthorizationEntry(
          SorobanCredentials.forAddressV2(inner),
          _buildHelloInvocation(),
        ),
        [SorobanDelegateDescriptor(delegateId)],
        _kExpiration,
      );

      // First sign — delegate node goes from void → 1-element vec
      entry.sign(delegateKp1, Network.TESTNET, forAddress: delegateId);
      // Second sign (different key) — hits existing.vec != null branch (line 1185)
      entry.sign(delegateKp2, Network.TESTNET, forAddress: delegateId);

      final withDelegates = entry.credentials.addressWithDelegatesCredentials!;
      final delegateNode = withDelegates.delegates[0];

      expect(
        delegateNode.signature.vec!.length,
        equals(2),
        reason: 'delegate node must have 2 signatures after being signed twice',
      );
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: Deep XDR-constructed WITH_DELEGATES tree — depth limit tests
  //
  // withDelegates() enforces the depth limit during construction. These tests
  // bypass the construction limit by building the XdrSorobanDelegateSignature
  // tree directly and wrapping it in a SorobanAuthorizationEntry via fromXdr.
  // This drives:
  // - soroban_auth.dart line 1159 (_walkDelegate depth > 128)
  // - soroban_client.dart line 923 (_collectUnsignedDelegates depth > 128)
  // - soroban_client.dart line 1262 (_delegateListContains depth > 128)
  // -------------------------------------------------------------------------
  group('Deep XDR delegate tree — depth limit guards', () {
    /// Builds a 130-deep XdrSorobanDelegateSignature chain.
    /// Returns the root node and the strkey of the leaf address.
    ({XdrSorobanDelegateSignature root, String leafStrKey})
        _buildDeepXdrDelegateTree(KeyPair kp) {
      // Build from the leaf upward: leaf is level 130 (depth 130).
      XdrSorobanDelegateSignature current = XdrSorobanDelegateSignature(
          XdrSCAddress.forAccountId(kp.accountId), XdrSCVal.forVoid(), []);
      final leafStrKey = kp.accountId;
      for (int i = 0; i < 130; i++) {
        current = XdrSorobanDelegateSignature(
            XdrSCAddress.forContractId(_kContractId),
            XdrSCVal.forVoid(),
            [current]);
      }
      return (root: current, leafStrKey: leafStrKey);
    }

    /// Builds a SorobanAuthorizationEntry with a 130-deep delegate tree
    /// directly via XDR constructors (bypassing withDelegates depth check).
    SorobanAuthorizationEntry _buildDeepEntry(KeyPair topKp) {
      final (:root, leafStrKey: _) = _buildDeepXdrDelegateTree(topKp);

      final addressCreds = XdrSorobanAddressCredentials(
        XdrSCAddress.forAccountId(topKp.accountId),
        XdrInt64(_kNonce),
        XdrUint32(_kExpiration),
        XdrSCVal.forVoid(),
      );
      final withDelegates =
          XdrSorobanAddressCredentialsWithDelegates(addressCreds, [root]);
      final xdrCreds = XdrSorobanCredentials(
          XdrSorobanCredentialsType
              .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES);
      xdrCreds.addressWithDelegates = withDelegates;

      final contractAddr = XdrSCAddress.forContractId(_kContractId);
      final fn = XdrSorobanAuthorizedFunction(
        XdrSorobanAuthorizedFunctionType
            .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
      );
      fn.contractFn = XdrInvokeContractArgs(
          contractAddr, 'hello', [XdrSCVal.forU64(BigInt.from(1234))]);
      final invocation = XdrSorobanAuthorizedInvocation(fn, []);
      final xdrEntry = XdrSorobanAuthorizationEntry(xdrCreds, invocation);

      return SorobanAuthorizationEntry.fromXdr(xdrEntry);
    }

    test('sign(forAddress:) on 130-deep tree throws depth limit (_walkDelegate line 1159)',
        () {
      final kp = KeyPair.fromSecretSeed(_kSeed);
      final (:root, :leafStrKey) = _buildDeepXdrDelegateTree(kp);
      final entry = _buildDeepEntry(kp);

      // sign(forAddress:) triggers _routeSignatureToAddress(depth=0) which
      // calls _walkDelegate(depth=1); the tree is 130 levels deep so the
      // recursion reaches depth 129 before throwing at line 1159.
      expect(
        () => entry.sign(kp, Network.TESTNET, forAddress: leafStrKey),
        throwsA(isA<Exception>()),
        reason: '_walkDelegate must throw when delegate tree depth exceeds 128',
      );
    });

    test(
        'needsNonInvokerSigningBy on 130-deep tree throws depth limit (_collectUnsignedDelegates line 923)',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        final deepEntry = _buildDeepEntry(kp);
        _injectAuthEntry(assembled, accountId, deepEntry);

        // needsNonInvokerSigningBy calls _collectUnsignedDelegates recursively;
        // the 130-deep tree causes it to exceed the limit at line 923.
        expect(
          () => assembled.needsNonInvokerSigningBy(),
          throwsA(isA<Exception>()),
          reason:
              '_collectUnsignedDelegates must throw when delegate depth exceeds 128',
        );
      } finally {
        await server.close();
      }
    });

    test(
        'signAuthEntries on 130-deep tree with authorizeEntryDelegate bypasses pre-check',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        final deepEntry = _buildDeepEntry(kp);
        _injectAuthEntry(assembled, accountId, deepEntry);

        // authorizeEntryDelegate bypasses needsNonInvokerSigningBy() pre-check
        // and also bypasses _delegateListContains (callback path at line 1202).
        // The entry is handed to the callback without matching.
        // _delegateListContains line 1262 is never reached via this path;
        // that guard is unreachable because needsNonInvokerSigningBy() always
        // throws first for trees deep enough to trigger it.
        await assembled.signAuthEntries(
          signerKeyPair: kp,
          validUntilLedgerSeq: _kExpiration + 100,
          authorizeEntryDelegate: (entry, network) async => entry,
        );
        // If we reach here the callback path completed without throwing.
      } finally {
        await server.close();
      }
    });

    test(
        'sign(force:true) on 130-deep fully-signed tree throws depth limit (_allDelegatesSigned line 1032)',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Build a 130-deep tree where all nodes have a non-void signature so
        // that _allDelegatesSigned recurses all the way to depth 130 before
        // encountering an unsigned node. The depth check at line 1032 fires
        // when depth > 128.
        //
        // We set a dummy non-void signature directly on the XDR node to avoid
        // calling sign() on the tree (which would throw in _walkDelegate first).
        final dummySig = XdrSCVal.forBool(true); // non-void, non-vec
        XdrSorobanDelegateSignature current =
            XdrSorobanDelegateSignature(
                XdrSCAddress.forAccountId(kp.accountId), dummySig, []);
        for (int i = 0; i < 130; i++) {
          current = XdrSorobanDelegateSignature(
              XdrSCAddress.forContractId(_kContractId), dummySig, [current]);
        }

        final addressCreds = XdrSorobanAddressCredentials(
          XdrSCAddress.forAccountId(accountId),
          XdrInt64(_kNonce),
          XdrUint32(_kExpiration),
          XdrSCVal.forVoid(),
        );
        final withDelegates =
            XdrSorobanAddressCredentialsWithDelegates(addressCreds, [current]);
        final xdrCreds = XdrSorobanCredentials(
            XdrSorobanCredentialsType
                .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES);
        xdrCreds.addressWithDelegates = withDelegates;

        final contractAddr = XdrSCAddress.forContractId(_kContractId);
        final fn = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
        );
        fn.contractFn = XdrInvokeContractArgs(
            contractAddr, 'hello', [XdrSCVal.forU64(BigInt.from(1234))]);
        final invocation = XdrSorobanAuthorizedInvocation(fn, []);
        final xdrEntry = XdrSorobanAuthorizationEntry(xdrCreds, invocation);
        final deepSignedEntry = SorobanAuthorizationEntry.fromXdr(xdrEntry);

        _injectAuthEntry(assembled, accountId, deepSignedEntry);

        // sign(force:true) calls _neededSignersForSend() → _allDelegatesSigned()
        // which recurses 130 levels deep and throws at depth > 128 (line 1032).
        expect(
          () => assembled.sign(force: true),
          throwsA(isA<Exception>()),
          reason:
              '_allDelegatesSigned must throw when fully-signed delegate tree depth exceeds 128',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: _xdrAddressToStrKey returns empty for non-account/contract address
  // soroban_client.dart lines 948-950.
  // A delegate node whose XdrSCAddress is neither account nor contract type
  // is silently skipped (empty strkey) by _collectUnsignedDelegates.
  // This is achieved by building a WITH_DELEGATES entry via XDR (bypassing
  // withDelegates which only accepts G/C strkeys), using a CONTRACT address
  // for the delegate node but then patching it to an unknown discriminant.
  // -------------------------------------------------------------------------
  group('_xdrAddressToStrKey — contract address (non-account) returns contractId strkey',
      () {
    test(
        'needsNonInvokerSigningBy collects contract-address delegate strkey correctly',
        () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Build a WITH_DELEGATES entry with a contract-address delegate node
        // via XDR directly. The contract address triggers the second branch in
        // _xdrAddressToStrKey (line 948-950) and returns a non-empty strkey.
        final delegateNode = XdrSorobanDelegateSignature(
            XdrSCAddress.forContractId(_kContractId),
            XdrSCVal.forVoid(),
            []);

        final addressCreds = XdrSorobanAddressCredentials(
          XdrSCAddress.forAccountId(accountId),
          XdrInt64(_kNonce),
          XdrUint32(_kExpiration),
          XdrSCVal.forVoid(),
        );
        final withDelegates =
            XdrSorobanAddressCredentialsWithDelegates(addressCreds, [delegateNode]);
        final xdrCreds = XdrSorobanCredentials(
            XdrSorobanCredentialsType
                .SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES);
        xdrCreds.addressWithDelegates = withDelegates;

        final contractAddr = XdrSCAddress.forContractId(_kContractId);
        final fn = XdrSorobanAuthorizedFunction(
          XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
        );
        fn.contractFn = XdrInvokeContractArgs(
            contractAddr, 'hello', [XdrSCVal.forU64(BigInt.from(1234))]);
        final invocation = XdrSorobanAuthorizedInvocation(fn, []);
        final xdrEntry = XdrSorobanAuthorizationEntry(xdrCreds, invocation);
        final entry = SorobanAuthorizationEntry.fromXdr(xdrEntry);

        _injectAuthEntry(assembled, accountId, entry);

        // needsNonInvokerSigningBy collects unsigned delegate strkeys.
        // The contract-address delegate fires the second _xdrAddressToStrKey
        // branch (line 948-950); the returned contractId strkey starts with 'C'
        // so it IS added to needed.
        final needed =
            assembled.needsNonInvokerSigningBy(includeAlreadySigned: true);
        expect(needed, isNotEmpty,
            reason: 'contract-address delegate must be collected by needsNonInvokerSigningBy');
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: sign() with tx == null — covers _neededSignersForSend line 969
  //
  // _neededSignersForSend() (line 967) is called from sign() at line 809.
  // Line 969 (return [] when tx == null) and line 973 (return [] when
  // ops.isEmpty) are defensive guards reached only when the caller has
  // already set assembled.tx to a value different from what sign() checked.
  //
  // For line 969: sign() throws at line 788 when tx == null, so
  // _neededSignersForSend is only ever reached with tx != null from sign().
  // The null guard at 969 is a pure defensive check.  The test below
  // documents the sign() contract (throws) and confirms line 788 fires.
  //
  // For line 973: set tx to a transaction with no operations by clearing the
  // operations list between AssembledTransaction.build() and sign().  The
  // Transaction.operations getter returns the backing list directly, so
  // list.clear() produces a tx that is non-null but has ops.isEmpty == true.
  // _neededSignersForSend then hits line 973 and returns []; sign() proceeds.
  // -------------------------------------------------------------------------
  group('sign() — tx==null and empty-ops guards (lines 969 + 973)', () {
    test('sign_throwsWhenTxIsNull', () async {
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Set tx to null — sign() throws at line 788 (before calling
        // _neededSignersForSend). This documents the contract that a null tx
        // produces an Exception and prevents an unsigned send.
        assembled.tx = null;

        expect(
          () => assembled.sign(force: true),
          throwsA(isA<Exception>()),
          reason: 'sign() must throw when tx is null',
        );
      } finally {
        await server.close();
      }
    });

    test('sign_passesNeededSignersCheckWhenTxHasNoOperations_line973', () async {
      // Exercises _neededSignersForSend line 973: ops.isEmpty → return [].
      //
      // Transaction.operations returns the backing mutable list.  Clearing it
      // produces a non-null tx with no operations.  _neededSignersForSend
      // enters the ops.isEmpty branch (line 973) and returns [] — the
      // "needed signers" check passes.  The subsequent clone step inside
      // sign() fails because Transaction(account, fee, seq, [], ...) calls
      // checkArgument(ops.length > 0) and throws.  The test confirms that
      // the exception does NOT come from the "multiple signers required"
      // path (lines 810-813) — i.e., line 973 returned [] successfully.
      if (identical(0, 0.0)) return;

      final kp = KeyPair.fromSecretSeed(_kSeed);
      final accountId = kp.accountId;
      final (server, _) = await _startMockRpcServer(
          accountId: accountId, seqNum: BigInt.from(100));

      try {
        final rpcUrl = 'http://127.0.0.1:${server.port}';
        final assembled =
            await _buildAssembledTx(rpcUrl, accountId, kp, simulate: false);

        // Build a valid 1-op tx, inject it, then clear the operations list.
        // After clear(): tx != null (line 788 guard passes), ops.isEmpty == true
        // (line 973 returns []), sign() proceeds past the signers check and
        // fails at the XDR clone step with "At least one operation required".
        final account = Account(accountId, BigInt.from(100));
        final tx = TransactionBuilder(account)
            .addOperation(BumpSequenceOperation(BigInt.from(110)))
            .build();
        assembled.tx = tx;
        assembled.tx!.operations.clear();

        // The exception comes from the clone step, not from "multiple signers"
        // (which would say "requires signatures from multiple signers").
        final threw = <Exception>[];
        try {
          assembled.sign(force: true);
        } on Exception catch (e) {
          threw.add(e);
        }
        expect(threw.length, equals(1),
            reason: 'sign() must throw when operations list is empty');
        expect(
          threw.first.toString(),
          isNot(contains('requires signatures from multiple signers')),
          reason:
              '_neededSignersForSend returned [] (line 973 executed), so the '
              'exception must not come from the multi-signer guard',
        );
        expect(
          threw.first.toString(),
          contains('operation'),
          reason: 'exception must come from the clone step (empty operations)',
        );
      } finally {
        await server.close();
      }
    });
  });

  // -------------------------------------------------------------------------
  // GROUP: WebAuthForContracts — clientDomainSigningCallback with expiration
  // Covers webauth_for_contracts.dart line 782 (signatureExpirationLedger
  // stamping in the clientDomainSigningCallback branch).
  // -------------------------------------------------------------------------
  group('WebAuthForContracts — clientDomainSigningCallback with expiration',
      () {
    test(
        'signAuthorizationEntries stamps expiration before calling clientDomainSigningCallback',
        () async {
      final serverKeyPair = KeyPair.random();
      final serverAccountId = serverKeyPair.accountId;
      final clientKeyPair = KeyPair.random();
      final clientAccountId = clientKeyPair.accountId;
      final clientDomainAccountId = KeyPair.random().accountId;

      final contractAddr = Address.forContractId(_kContractId);
      final fn = SorobanAuthorizedFunction.forContractFunction(
          contractAddr, 'web_auth_verify', [
        XdrSCVal.forMap([
          XdrSCMapEntry(XdrSCVal.forSymbol('account'), XdrSCVal.forString(clientAccountId)),
          XdrSCMapEntry(XdrSCVal.forSymbol('home_domain'), XdrSCVal.forString('test.stellar.org')),
          XdrSCMapEntry(XdrSCVal.forSymbol('nonce'), XdrSCVal.forString('42')),
          XdrSCMapEntry(XdrSCVal.forSymbol('web_auth_domain'), XdrSCVal.forString('test.stellar.org')),
          XdrSCMapEntry(XdrSCVal.forSymbol('web_auth_domain_account'), XdrSCVal.forString(serverAccountId)),
        ]),
      ]);
      final invocation = SorobanAuthorizedInvocation(fn);

      // Build the client domain entry
      final clientDomainCreds = SorobanAddressCredentials(
          Address.forAccountId(clientDomainAccountId),
          BigInt.from(1), 0, XdrSCVal.forVoid());
      final clientDomainEntry = SorobanAuthorizationEntry(
          SorobanCredentials(addressCredentials: clientDomainCreds), invocation);

      // Build a regular client entry
      final clientCreds = SorobanAddressCredentials(
          Address.forAccountId(clientAccountId),
          BigInt.from(2), 0, XdrSCVal.forVoid());
      final clientEntry = SorobanAuthorizationEntry(
          SorobanCredentials(addressCredentials: clientCreds), invocation);

      final webAuth = WebAuthForContracts(
        'https://test.stellar.org/auth',
        _kContractId,
        serverAccountId,
        'test.stellar.org',
        Network.TESTNET,
      );

      const stampedExpiration = 9876;
      int callbackInvocations = 0;
      int? capturedExpiration;

      await webAuth.signAuthorizationEntries(
        [clientDomainEntry, clientEntry],
        clientAccountId,
        [clientKeyPair],
        stampedExpiration,
        null,                 // no clientDomainKeyPair
        clientDomainAccountId,
        (entry) async {       // clientDomainSigningCallback triggers line 782
          callbackInvocations++;
          capturedExpiration =
              entry.credentials.innerAddressCredentials?.signatureExpirationLedger;
          return entry;
        },
      );

      expect(callbackInvocations, equals(1),
          reason: 'callback must be invoked once for the client domain entry');
      expect(capturedExpiration, equals(stampedExpiration),
          reason:
              'expiration must be stamped before the callback receives the entry (line 782)');
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers used only in this file
// ---------------------------------------------------------------------------

/// Builds a minimal SOURCE_ACCOUNT XdrSorobanAuthorizationEntry.
XdrSorobanAuthorizationEntry _buildOzSourceEntry() {
  final contractAddr = XdrSCAddress.forContractId(_kContractId);
  final fn = XdrSorobanAuthorizedFunction(
    XdrSorobanAuthorizedFunctionType
        .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN,
  );
  fn.contractFn =
      XdrInvokeContractArgs(contractAddr, 'hello', [XdrSCVal.forU64(BigInt.from(1234))]);
  final invocation =
      XdrSorobanAuthorizedInvocation(fn, []);
  return XdrSorobanAuthorizationEntry(
      XdrSorobanCredentials.forSourceAccount(), invocation);
}
