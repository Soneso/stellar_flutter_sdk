// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Unsigned signature placeholders and the send precheck of
// AssembledTransaction: a void value and an empty vector both mark a node as
// unsigned, and sign() stops on every unsigned account, never on a contract.
//
// A mocked Dio adapter answers every RPC call; no test reaches a network.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const _kRpcUrl = 'https://soroban-testnet.stellar.org';
const _kSeed = 'SDJHRQF4GCMIIKAAAQ6IHY42X73FQFLHUULAPSKKD4DFDM7UXWWCRHBE';
const _kContractId = 'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE';
const int _kExpiration = 4242;
const int _kLatestLedger = 1000;
final BigInt _kNonce = BigInt.parse('123456789101112');

KeyPair _keyPairFilledWith(int byte) =>
    KeyPair.fromSecretSeedList(Uint8List.fromList(List<int>.filled(32, byte)));

/// The invoker: source account of the transaction and signer of its envelope.
final KeyPair _invoker = KeyPair.fromSecretSeed(_kSeed);

/// An account other than the invoker that authorizes an entry.
final KeyPair _owner = _keyPairFilledWith(1);

/// An account that signs a delegate node.
final KeyPair _delegate = _keyPairFilledWith(2);

/// A custom account contract, distinct from the invoked contract.
final String _kAccountContractId = StrKey.encodeContractId(
  Uint8List.fromList(List<int>.filled(32, 7)),
);

final Matcher _throwsMultipleSigners = throwsA(
  isA<Exception>().having(
    (e) => e.toString(),
    'message',
    contains('Transaction requires signatures from multiple signers.'),
  ),
);

class _MockDioAdapter implements dio.HttpClientAdapter {
  final dio.ResponseBody Function(dio.RequestOptions) onRequest;

  _MockDioAdapter(this.onRequest);

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => onRequest(options);

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody _rpcResult(dynamic id, Map<String, dynamic> result) =>
    dio.ResponseBody.fromString(
      jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
      200,
      headers: {
        'content-type': [dio.Headers.jsonContentType],
      },
    );

String _invokerAccountEntryXdr() {
  final accountEntry = XdrAccountEntry(
    XdrAccountID(_invoker.xdrPublicKey),
    XdrInt64(BigInt.from(100000000)),
    XdrSequenceNumber(BigInt.from(100)),
    XdrUint32(0),
    null,
    XdrUint32(0),
    XdrString32(''),
    XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
    [],
    XdrAccountEntryExt(0),
  );
  final data = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
  data.account = accountEntry;
  return data.toBase64EncodedXdrString();
}

String _transactionDataXdr() => XdrSorobanTransactionData(
  XdrSorobanTransactionDataExt(0),
  XdrSorobanResources(
    XdrLedgerFootprint([], []),
    XdrUint32(0),
    XdrUint32(0),
    XdrUint32(0),
  ),
  XdrInt64(BigInt.zero),
).toBase64EncodedXdrString();

/// A Soroban RPC server whose simulation returns [authEntries] and whose
/// `getLatestLedger` answers [_kLatestLedger]. The returned map counts the
/// `getLatestLedger` requests under `getLatestLedgerCalls`; an absent key
/// means none.
(SorobanServer, Map<String, dynamic>) _mockRpcServer(
  List<SorobanAuthorizationEntry> authEntries,
) {
  final captured = <String, dynamic>{};
  final mockDio = dio.Dio();
  mockDio.httpClientAdapter = _MockDioAdapter((options) {
    final request = jsonDecode(options.data as String) as Map<String, dynamic>;
    final id = request['id'];
    switch (request['method']) {
      case 'getLedgerEntries':
        return _rpcResult(id, {
          'entries': [
            {
              'key': (request['params']['keys'] as List).first,
              'xdr': _invokerAccountEntryXdr(),
              'lastModifiedLedgerSeq': 100,
            },
          ],
          'latestLedger': _kLatestLedger,
        });
      case 'simulateTransaction':
        return _rpcResult(id, {
          'results': [
            {
              'xdr': XdrSCVal.forVoid().toBase64EncodedXdrString(),
              'auth': authEntries
                  .map((e) => e.toBase64EncodedXdrString())
                  .toList(),
            },
          ],
          'transactionData': _transactionDataXdr(),
          'minResourceFee': '100',
          'latestLedger': _kLatestLedger,
        });
      case 'getLatestLedger':
        captured.update(
          'getLatestLedgerCalls',
          (n) => n + 1,
          ifAbsent: () => 1,
        );
        return _rpcResult(id, {'sequence': _kLatestLedger});
      default:
        fail('Unexpected RPC method: ${request['method']}');
    }
  });
  return (SorobanServer(_kRpcUrl, httpClient: mockDio), captured);
}

/// Builds and simulates an invocation whose simulation returns
/// [authEntries]; returns the transaction and the request counters of its
/// mocked server.
Future<(AssembledTransaction, Map<String, dynamic>)> _simulated(
  List<SorobanAuthorizationEntry> authEntries,
) async {
  final (server, captured) = _mockRpcServer(authEntries);
  final assembled = await AssembledTransaction.build(
    options: AssembledTransactionOptions(
      clientOptions: ClientOptions(
        sourceAccountKeyPair: _invoker,
        contractId: _kContractId,
        network: Network.TESTNET,
        rpcUrl: _kRpcUrl,
        server: server,
      ),
      methodOptions: MethodOptions(),
      method: 'hello',
      arguments: [XdrSCVal.forU64(BigInt.from(1234))],
    ),
  );
  return (assembled, captured);
}

List<SorobanAuthorizationEntry> _authOf(AssembledTransaction assembled) =>
    (assembled.tx!.operations.first as InvokeHostFunctionOperation).auth;

SorobanAuthorizationEntry _entry(SorobanCredentials credentials) =>
    SorobanAuthorizationEntry(
      credentials,
      SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(_kContractId),
          'hello',
          [XdrSCVal.forU64(BigInt.from(1234))],
        ),
      ),
    );

SorobanAddressCredentials _credentials(
  Address address,
  int expiration,
  XdrSCVal signature,
) => SorobanAddressCredentials(address, _kNonce, expiration, signature);

/// An ADDRESS_V2 entry of [_owner] with a void top-level signature.
SorobanAuthorizationEntry _ownerV2Entry() => _entry(
  SorobanCredentials.forAddressV2(
    _credentials(
      Address.forAccountId(_owner.accountId),
      _kExpiration,
      XdrSCVal.forVoid(),
    ),
  ),
);

/// Returns true when a signature in the vector [signature] verifies for
/// [signer] against the payload hash of [entry]'s current preimage.
bool _signatureVerifies(
  SorobanAuthorizationEntry entry,
  XdrSCVal signature,
  KeyPair signer,
) {
  final out = XdrDataOutputStream();
  XdrHashIDPreimage.encode(out, entry.buildPreimage(Network.TESTNET));
  final payload = Util.hash(Uint8List.fromList(out.bytes));
  return signature.vec!.any(
    (sig) => signer.verify(
      payload,
      sig.map!.firstWhere((e) => e.key.sym == 'signature').val.bytes!.sCBytes,
    ),
  );
}

void main() {
  group('SorobanAuthorizationEntry.carriesSignature', () {
    test('is false for a void value', () {
      expect(
        SorobanAuthorizationEntry.carriesSignature(XdrSCVal.forVoid()),
        isFalse,
      );
    });

    test('is false for an empty vector', () {
      expect(
        SorobanAuthorizationEntry.carriesSignature(XdrSCVal.forVec([])),
        isFalse,
      );
    });

    test('is false for a vector value without a list', () {
      final vectorWithoutList = XdrSCVal(XdrSCValType.SCV_VEC);
      expect(vectorWithoutList.vec, isNull);
      expect(
        SorobanAuthorizationEntry.carriesSignature(vectorWithoutList),
        isFalse,
      );
    });

    test('is true for a one-element vector', () {
      expect(
        SorobanAuthorizationEntry.carriesSignature(
          XdrSCVal.forVec([XdrSCVal.forBytes(Uint8List(64))]),
        ),
        isTrue,
      );
    });

    test('is true for a Bytes value', () {
      expect(
        SorobanAuthorizationEntry.carriesSignature(
          XdrSCVal.forBytes(Uint8List(64)),
        ),
        isTrue,
      );
    });

    test('is true for a non-empty map', () {
      expect(
        SorobanAuthorizationEntry.carriesSignature(
          XdrSCVal.forMap([
            XdrSCMapEntry(XdrSCVal.forSymbol('signature'), XdrSCVal.forU32(1)),
          ]),
        ),
        isTrue,
      );
    });
  });

  group('an entry with an empty-vector placeholder', () {
    final arms = {
      'ADDRESS': (SorobanAddressCredentials c) =>
          SorobanCredentials.forAddressCredentialsLegacy(c),
      'ADDRESS_V2': (SorobanAddressCredentials c) =>
          SorobanCredentials.forAddressV2(c),
    };

    for (final MapEntry(key: armName, value: credentialsFor) in arms.entries) {
      /// An unsigned entry for [_owner] with an empty signature vector and
      /// expiration ledger 0.
      SorobanAuthorizationEntry unsignedEntry() => _entry(
        credentialsFor(
          _credentials(
            Address.forAccountId(_owner.accountId),
            0,
            XdrSCVal.forVec([]),
          ),
        ),
      );

      test('$armName: is listed, blocks sign() and signs with the default '
          'expiration', () async {
        final (assembled, captured) = await _simulated([unsignedEntry()]);

        expect(
          assembled.needsNonInvokerSigningBy(),
          equals([_owner.accountId]),
        );
        expect(() => assembled.sign(), _throwsMultipleSigners);

        await assembled.signAuthEntries(signerKeyPair: _owner);

        final entry = _authOf(assembled).single;
        final inner = entry.credentials.innerAddressCredentials!;
        expect(entry.credentials.arm, equals(unsignedEntry().credentials.arm));
        expect(
          inner.signatureExpirationLedger,
          equals(
            _kLatestLedger + NetworkConstants.DEFAULT_LEDGER_EXPIRATION_OFFSET,
          ),
        );
        expect(captured['getLatestLedgerCalls'], equals(1));
        expect(inner.signature.vec, hasLength(1));
        expect(_signatureVerifies(entry, inner.signature, _owner), isTrue);
        expect(assembled.needsNonInvokerSigningBy(), isEmpty);

        assembled.sign();
        expect(assembled.signed, isNotNull);
      });

      test('$armName: an explicit validUntilLedgerSeq is stamped without a '
          'latest-ledger request', () async {
        final (assembled, captured) = await _simulated([unsignedEntry()]);

        await assembled.signAuthEntries(
          signerKeyPair: _owner,
          validUntilLedgerSeq: 500,
        );

        final entry = _authOf(assembled).single;
        final inner = entry.credentials.innerAddressCredentials!;
        expect(inner.signatureExpirationLedger, equals(500));
        expect(captured['getLatestLedgerCalls'] ?? 0, equals(0));
        expect(inner.signature.vec, hasLength(1));
        expect(_signatureVerifies(entry, inner.signature, _owner), isTrue);
      });
    }
  });

  group('a delegate node with an empty vector', () {
    test('is listed and gets the explicit expiration when signed', () async {
      final entry = SorobanAuthorizationEntry.withDelegates(_ownerV2Entry(), [
        SorobanDelegateDescriptor(
          _delegate.accountId,
          signature: XdrSCVal.forVec([]),
        ),
      ], 0);
      final (assembled, captured) = await _simulated([entry]);

      expect(
        assembled.needsNonInvokerSigningBy(),
        equals([_owner.accountId, _delegate.accountId]),
      );

      await assembled.signAuthEntries(
        signerKeyPair: _delegate,
        validUntilLedgerSeq: 500,
        authorizeEntryDelegate: (entry, network) async {
          entry.sign(_delegate, network, forAddress: _delegate.accountId);
          return entry;
        },
      );

      final signed = _authOf(assembled).single;
      final inner = signed.credentials.innerAddressCredentials!;
      final node =
          signed.credentials.addressWithDelegatesCredentials!.delegates.single;
      expect(inner.signatureExpirationLedger, equals(500));
      expect(captured['getLatestLedgerCalls'] ?? 0, equals(0));
      expect(node.signature.vec, hasLength(1));
      expect(_signatureVerifies(signed, node.signature, _delegate), isTrue);
      expect(assembled.needsNonInvokerSigningBy(), equals([_owner.accountId]));
    });
  });

  group('sign() stops on an unsigned account at the top level', () {
    test('of a delegates entry without delegate nodes', () async {
      final entry = SorobanAuthorizationEntry.withDelegates(
        _ownerV2Entry(),
        [],
        _kExpiration,
      );
      final (assembled, captured) = await _simulated([entry]);

      expect(assembled.needsNonInvokerSigningBy(), equals([_owner.accountId]));
      expect(() => assembled.sign(), _throwsMultipleSigners);

      await assembled.signAuthEntries(signerKeyPair: _owner);

      final signed = _authOf(assembled).single;
      final inner = signed.credentials.innerAddressCredentials!;
      expect(
        inner.signatureExpirationLedger,
        equals(
          _kLatestLedger + NetworkConstants.DEFAULT_LEDGER_EXPIRATION_OFFSET,
        ),
      );
      expect(captured['getLatestLedgerCalls'], equals(1));
      expect(_signatureVerifies(signed, inner.signature, _owner), isTrue);
      expect(assembled.needsNonInvokerSigningBy(), isEmpty);

      assembled.sign();
      expect(assembled.signed, isNotNull);
    });

    test('with an empty vector and a signed delegate node', () async {
      final entry = SorobanAuthorizationEntry.withDelegates(_ownerV2Entry(), [
        SorobanDelegateDescriptor(_delegate.accountId),
      ], _kExpiration);
      entry.sign(_delegate, Network.TESTNET, forAddress: _delegate.accountId);
      entry.credentials.innerAddressCredentials!.signature = XdrSCVal.forVec(
        [],
      );
      final (assembled, _) = await _simulated([entry]);

      expect(assembled.needsNonInvokerSigningBy(), equals([_owner.accountId]));
      expect(() => assembled.sign(), _throwsMultipleSigners);
    });
  });

  group('sign() stops on an unsigned account delegate node', () {
    test('nested under a contract node, with the top level signed', () async {
      final entry = SorobanAuthorizationEntry.withDelegates(_ownerV2Entry(), [
        SorobanDelegateDescriptor(
          _kAccountContractId,
          nestedDelegates: [SorobanDelegateDescriptor(_delegate.accountId)],
        ),
      ], _kExpiration);
      entry.sign(_owner, Network.TESTNET);
      final (assembled, _) = await _simulated([entry]);

      expect(
        assembled.needsNonInvokerSigningBy(),
        equals([_kAccountContractId, _delegate.accountId]),
      );
      expect(() => assembled.sign(), _throwsMultipleSigners);
    });
  });

  group('sign() does not stop on a contract address', () {
    test('at the top level of a delegates entry decoded from XDR', () async {
      final built = SorobanAuthorizationEntry.withDelegates(
        _entry(
          SorobanCredentials.forAddressV2(
            _credentials(
              Address.forContractId(_kAccountContractId),
              _kExpiration,
              XdrSCVal.forVoid(),
            ),
          ),
        ),
        [SorobanDelegateDescriptor(_delegate.accountId)],
        _kExpiration,
      );
      built.sign(_delegate, Network.TESTNET, forAddress: _delegate.accountId);
      final entry = SorobanAuthorizationEntry.fromXdr(built.toXdr());
      final topContractId =
          entry.credentials.innerAddressCredentials!.address.contractId!;
      expect(
        topContractId,
        equals(Util.bytesToHex(StrKey.decodeContractId(_kAccountContractId))),
        reason: 'a contract id decoded from XDR is stored as hex',
      );
      final (assembled, _) = await _simulated([entry]);

      expect(assembled.needsNonInvokerSigningBy(), equals([topContractId]));
      assembled.sign();
      expect(assembled.signed, isNotNull);
    });

    test('in an unsigned delegate node', () async {
      final entry = SorobanAuthorizationEntry.withDelegates(_ownerV2Entry(), [
        SorobanDelegateDescriptor(_kAccountContractId),
      ], _kExpiration);
      entry.sign(_owner, Network.TESTNET);
      final (assembled, _) = await _simulated([entry]);

      expect(
        assembled.needsNonInvokerSigningBy(),
        equals([_kAccountContractId]),
      );
      assembled.sign();
      expect(assembled.signed, isNotNull);
    });

    test('in an unsigned delegate node nested under a signed account node, '
        'with the top level signed', () async {
      final entry = SorobanAuthorizationEntry.withDelegates(_ownerV2Entry(), [
        SorobanDelegateDescriptor(
          _delegate.accountId,
          nestedDelegates: [SorobanDelegateDescriptor(_kAccountContractId)],
        ),
      ], _kExpiration);
      entry.sign(_owner, Network.TESTNET);
      entry.sign(_delegate, Network.TESTNET, forAddress: _delegate.accountId);
      final (assembled, _) = await _simulated([entry]);

      expect(
        assembled.needsNonInvokerSigningBy(),
        equals([_kAccountContractId]),
      );
      assembled.sign();
      expect(assembled.signed, isNotNull);
    });
  });

  group('a stored signature value counts as a signature', () {
    final values = {
      'a one-element vector': XdrSCVal.forVec([
        XdrSCVal.forBytes(Uint8List(64)),
      ]),
      'a Bytes value': XdrSCVal.forBytes(Uint8List(64)),
    };

    for (final MapEntry(key: label, value: signature) in values.entries) {
      test('$label keeps the stored expiration', () async {
        final entry = _entry(
          SorobanCredentials.forAddressV2(
            _credentials(
              Address.forAccountId(_owner.accountId),
              _kExpiration,
              signature,
            ),
          ),
        );
        final (assembled, _) = await _simulated([entry]);

        expect(assembled.needsNonInvokerSigningBy(), isEmpty);
        await expectLater(
          assembled.signAuthEntries(
            signerKeyPair: KeyPair.fromAccountId(_owner.accountId),
            validUntilLedgerSeq: 500,
            authorizeEntryDelegate: (entry, network) async => entry,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('already carries a signature'),
            ),
          ),
        );
      });
    }
  });
}
