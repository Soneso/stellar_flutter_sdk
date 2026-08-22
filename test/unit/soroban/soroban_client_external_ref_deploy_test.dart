// Tests for SorobanClient.deployFromExternalRef() and Address.deriveContractId().
//
// The deploy flow resolves the CAP-85 external reference before the
// transaction is built and loads the contract spec from the resolved wasm
// code entry. All RPC calls are served by a mocked Dio adapter; no network
// access. The submitted transaction envelope is decoded to verify the
// external-ref create host function it carries.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

class MockDioAdapter implements dio.HttpClientAdapter {
  final Function(dio.RequestOptions) onRequest;

  MockDioAdapter(this.onRequest);

  @override
  Future<dio.ResponseBody> fetch(
    dio.RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

dio.ResponseBody jsonRpcResponse(dynamic id, Map<String, dynamic> result) {
  return dio.ResponseBody.fromString(
    jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}),
    200,
    headers: {
      'content-type': [dio.Headers.jsonContentType]
    },
  );
}

dio.ResponseBody ledgerEntryResponse(
    Map<String, dynamic> requestBody, XdrLedgerEntryData entryData) {
  return jsonRpcResponse(requestBody['id'], {
    'entries': [
      {
        'key': (requestBody['params']['keys'] as List)[0],
        'xdr': entryData.toBase64EncodedXdrString(),
        'lastModifiedLedgerSeq': 99999,
      }
    ],
    'latestLedger': 100000,
  });
}

dio.ResponseBody emptyLedgerEntriesResponse(Map<String, dynamic> requestBody) {
  return jsonRpcResponse(requestBody['id'], {
    'entries': [],
    'latestLedger': 100000,
  });
}

XdrLedgerEntryData accountEntry(KeyPair keyPair) {
  final account = XdrAccountEntry(
    XdrAccountID(keyPair.xdrPublicKey),
    XdrInt64(BigInt.zero),
    XdrSequenceNumber(BigInt.from(1000)),
    XdrUint32(0),
    null,
    XdrUint32(0),
    XdrString32(''),
    XdrThresholds(Uint8List.fromList([1, 0, 0, 0])),
    [],
    XdrAccountEntryExt(0),
  );
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.ACCOUNT);
  entryData.account = account;
  return entryData;
}

XdrLedgerEntryData contractCodeEntry(Uint8List wasmHashBytes, Uint8List code) {
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_CODE);
  entryData.contractCode = XdrContractCodeEntry(
      XdrContractCodeEntryExt(0), XdrHash(wasmHashBytes), code);
  return entryData;
}

/// CONTRACT_DATA entry holding the wasm hash under the owner's executable
/// tag key, as served for a CAP-85 external reference resolution.
XdrLedgerEntryData executableTagEntry(
    String ownerContractIdHex, String tag, Uint8List wasmHashBytes) {
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
  entryData.contractData = XdrContractDataEntry(
    XdrExtensionPoint(0),
    Address.forContractId(ownerContractIdHex).toXdr(),
    XdrSCVal.forExecutableTag(tag),
    XdrContractDataDurability.PERSISTENT,
    XdrSCVal.forBytes(wasmHashBytes),
  );
  return entryData;
}

/// Transaction data with a non-empty read-write footprint, so that the
/// deploy transaction is not considered a read call.
XdrSorobanTransactionData transactionDataWithWrites(KeyPair keyPair) {
  final key = XdrLedgerKey(XdrLedgerEntryType.ACCOUNT);
  key.account = XdrLedgerKeyAccount(XdrAccountID(keyPair.xdrPublicKey));
  final resources = XdrSorobanResources(
      XdrLedgerFootprint([], [key]), XdrUint32(0), XdrUint32(0), XdrUint32(0));
  return XdrSorobanTransactionData(
      XdrSorobanTransactionDataExt(0), resources, XdrInt64(BigInt.zero));
}

/// CONTRACT_DATA entry holding the contract instance of the deployed
/// contract, as read by the forClientOptions fallback after deployment.
XdrLedgerEntryData contractInstanceEntry(
    Uint8List contractIdBytes, Uint8List wasmHashBytes) {
  final executable =
      XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM);
  executable.wasmHash = XdrHash(wasmHashBytes);
  final instance = XdrSCContractInstance(executable, null);
  final contractAddress =
      XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
  contractAddress.contractId = XdrHash(contractIdBytes);
  final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
  entryData.contractData = XdrContractDataEntry(
    XdrExtensionPoint(0),
    contractAddress,
    XdrSCVal.forLedgerKeyContractInstance(),
    XdrContractDataDurability.PERSISTENT,
    XdrSCVal.forContractInstance(instance),
  );
  return entryData;
}

/// A SUCCESS getTransaction result whose meta carries [returnValue].
Map<String, dynamic> deployResultWithReturnValue(XdrSCVal returnValue) {
  final sorobanMeta = XdrSorobanTransactionMeta(
      XdrSorobanTransactionMetaExt(0), [], returnValue, []);
  final meta = XdrTransactionMeta(3);
  meta.v3 = XdrTransactionMetaV3(XdrExtensionPoint(0),
      XdrLedgerEntryChanges([]), [], XdrLedgerEntryChanges([]), sorobanMeta);
  return {
    'status': 'SUCCESS',
    'ledger': 99999,
    'createdAt': '1234567890',
    'applicationOrder': 1,
    'feeBump': false,
    'resultMetaXdr': meta.toBase64EncodedXdrString(),
  };
}

/// A SUCCESS getTransaction result whose meta returns the created contract
/// address, as required by [GetTransactionResponse.getCreatedContractId].
Map<String, dynamic> deploySuccessResult(Uint8List createdContractIdBytes) {
  final createdAddress = XdrSCAddress(XdrSCAddressType.SC_ADDRESS_TYPE_CONTRACT);
  createdAddress.contractId = XdrHash(createdContractIdBytes);
  return deployResultWithReturnValue(XdrSCVal.forAddress(createdAddress));
}

void main() {
  const rpcUrl = 'https://soroban-testnet.stellar.org';
  const txHash =
      'a7d8f6c5e9b1a3d2f4c8e7b9a5c3d1f2e8b6c4d7a9e1f3b5c2d8e6a4b7c9d1e2';
  const ownerContractIdHex =
      'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd';
  const executableTag = 'token-v1';

  final wasmHashBytes = Uint8List.fromList(List.generate(32, (i) => i + 1));
  final createdContractIdBytes = Uint8List(32);
  final createdContractId = StrKey.encodeContractId(createdContractIdBytes);
  final helloWasm =
      File('test/wasm/soroban_hello_world_contract.wasm').readAsBytesSync();
  final fixedSalt =
      XdrUint256(Uint8List.fromList(List.filled(32, 0x11)));

  /// Serves the full external-ref deploy flow: the executable tag entry for
  /// the resolution, the wasm code entry for the spec preload, the source
  /// account, simulate, send and getTransaction. When [tagEntryExists] is
  /// false, the resolution request is answered with no entries. Requests are
  /// appended to [requestLog] as 'tag', 'code', 'account', 'simulate',
  /// 'send' or 'getTx'; requested ledger keys and the submitted envelope are
  /// recorded into [capturedKeys] and [capturedEnvelopes].
  SorobanServer externalRefDeployFlowMockServer(
    KeyPair keyPair,
    List<String> requestLog,
    List<XdrLedgerKey> capturedKeys,
    List<String> capturedEnvelopes, {
    bool tagEntryExists = true,
    bool firstCodeLoadParseable = true,
    bool deployReturnsContractId = true,
  }) {
    final txData = transactionDataWithWrites(keyPair);
    final mockDio = dio.Dio();
    mockDio.httpClientAdapter = MockDioAdapter((options) {
      final requestBody = jsonDecode(options.data);
      switch (requestBody['method']) {
        case 'getLedgerEntries':
          final keyBase64 =
              (requestBody['params']['keys'] as List)[0] as String;
          final key = XdrLedgerKey.fromBase64EncodedXdrString(keyBase64);
          capturedKeys.add(key);
          if (key.discriminant == XdrLedgerEntryType.CONTRACT_DATA &&
              key.contractData?.key.discriminant ==
                  XdrSCValType.SCV_EXECUTABLE_TAG) {
            requestLog.add('tag');
            if (!tagEntryExists) {
              return emptyLedgerEntriesResponse(requestBody);
            }
            return ledgerEntryResponse(
                requestBody,
                executableTagEntry(
                    ownerContractIdHex, executableTag, wasmHashBytes));
          }
          if (key.discriminant == XdrLedgerEntryType.CONTRACT_CODE) {
            final firstCodeLoad = !requestLog.contains('code');
            requestLog.add('code');
            if (firstCodeLoad && !firstCodeLoadParseable) {
              return ledgerEntryResponse(
                  requestBody,
                  contractCodeEntry(wasmHashBytes,
                      Uint8List.fromList('not wasm'.codeUnits)));
            }
            return ledgerEntryResponse(
                requestBody, contractCodeEntry(wasmHashBytes, helloWasm));
          }
          if (key.discriminant == XdrLedgerEntryType.CONTRACT_DATA &&
              key.contractData?.key.discriminant ==
                  XdrSCValType.SCV_LEDGER_KEY_CONTRACT_INSTANCE) {
            requestLog.add('instance');
            return ledgerEntryResponse(requestBody,
                contractInstanceEntry(createdContractIdBytes, wasmHashBytes));
          }
          requestLog.add('account');
          return ledgerEntryResponse(requestBody, accountEntry(keyPair));
        case 'simulateTransaction':
          requestLog.add('simulate');
          return jsonRpcResponse(requestBody['id'], {
            'minResourceFee': '100000',
            'transactionData': txData.toBase64EncodedXdrString(),
            'results': [
              {
                'auth': [],
                'xdr': XdrSCVal.forU32(42).toBase64EncodedXdrString(),
              }
            ],
            'latestLedger': 100000,
          });
        case 'sendTransaction':
          requestLog.add('send');
          capturedEnvelopes
              .add(requestBody['params']['transaction'] as String);
          return jsonRpcResponse(requestBody['id'], {
            'status': 'PENDING',
            'hash': txHash,
            'latestLedger': 100000,
            'latestLedgerCloseTime': '1234567890',
          });
        case 'getTransaction':
          requestLog.add('getTx');
          return jsonRpcResponse(
              requestBody['id'],
              deployReturnsContractId
                  ? deploySuccessResult(createdContractIdBytes)
                  : deployResultWithReturnValue(XdrSCVal.forVoid()));
        default:
          fail('Unexpected RPC method: ${requestBody['method']}');
      }
    });
    return SorobanServer(rpcUrl, httpClient: mockDio);
  }

  /// The host function of the invoke host function operation in the
  /// submitted envelope.
  HostFunction submittedHostFunction(List<String> capturedEnvelopes) {
    expect(capturedEnvelopes, hasLength(1));
    final tx = AbstractTransaction.fromEnvelopeXdrString(capturedEnvelopes[0]);
    expect(tx, isA<Transaction>());
    final op = (tx as Transaction).operations[0];
    expect(op, isA<InvokeHostFunctionOperation>());
    return (op as InvokeHostFunctionOperation).function;
  }

  group('SorobanClient.deployFromExternalRef', () {
    test('resolves, deploys with constructor args and pins the envelope',
        () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final capturedKeys = <XdrLedgerKey>[];
      final capturedEnvelopes = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, capturedKeys, capturedEnvelopes);

      final client = await SorobanClient.deployFromExternalRef(
          deployRequest: DeployFromExternalRefRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: rpcUrl,
        executableOwner: Address.forContractId(ownerContractIdHex),
        tag: executableTag,
        constructorArgs: [XdrSCVal.forU32(7)],
        salt: fixedSalt,
        server: server,
      ));

      expect(client.getContractId(), createdContractId);
      expect(client.getMethodNames(), contains('hello'));
      // The reference resolves and the spec loads before submission; the
      // contract instance is never read.
      expect(requestLog.indexOf('tag'), lessThan(requestLog.indexOf('code')));
      expect(requestLog.indexOf('code'), lessThan(requestLog.indexOf('send')));

      // The resolution asked for the owner's tag entry and the preload for
      // the code entry under the resolved hash.
      final tagKey = capturedKeys[0];
      expect(Util.bytesToHex(tagKey.contractData!.contract.contractId!.hash),
          ownerContractIdHex);
      expect(tagKey.contractData!.key.executableTagString, executableTag);
      final codeKey = capturedKeys[1];
      expect(codeKey.contractCode!.hash.hash, wasmHashBytes);

      final hostFunction = submittedHostFunction(capturedEnvelopes);
      expect(hostFunction,
          isA<CreateContractFromExternalRefWithConstructorHostFunction>());
      final typed = hostFunction
          as CreateContractFromExternalRefWithConstructorHostFunction;
      expect(typed.executableOwner.contractId, ownerContractIdHex);
      expect(typed.tagString, executableTag);
      expect(typed.salt.uint256, fixedSalt.uint256);
      expect(typed.constructorArgs, hasLength(1));
      expect(typed.constructorArgs[0].u32!.uint32, 7);
    });

    test('uses the V2 host function with an empty vector when no constructor '
        'args are given', () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final capturedKeys = <XdrLedgerKey>[];
      final capturedEnvelopes = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, capturedKeys, capturedEnvelopes);

      final client = await SorobanClient.deployFromExternalRef(
          deployRequest: DeployFromExternalRefRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: rpcUrl,
        executableOwner: Address.forContractId(ownerContractIdHex),
        tag: executableTag,
        server: server,
      ));

      expect(client.getContractId(), createdContractId);

      final hostFunction = submittedHostFunction(capturedEnvelopes);
      expect(hostFunction,
          isA<CreateContractFromExternalRefWithConstructorHostFunction>());
      final typed = hostFunction
          as CreateContractFromExternalRefWithConstructorHostFunction;
      expect(typed.executableOwner.contractId, ownerContractIdHex);
      expect(typed.tagString, executableTag);
      expect(typed.salt.uint256, hasLength(32));
      expect(typed.constructorArgs, isEmpty);
    });

    test('uses the V2 host function with an empty vector for explicit empty '
        'constructor args', () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final capturedKeys = <XdrLedgerKey>[];
      final capturedEnvelopes = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, capturedKeys, capturedEnvelopes);

      final client = await SorobanClient.deployFromExternalRef(
          deployRequest: DeployFromExternalRefRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: rpcUrl,
        executableOwner: Address.forContractId(ownerContractIdHex),
        tag: executableTag,
        constructorArgs: [],
        salt: fixedSalt,
        server: server,
      ));

      expect(client.getContractId(), createdContractId);

      final hostFunction = submittedHostFunction(capturedEnvelopes);
      expect(hostFunction,
          isA<CreateContractFromExternalRefWithConstructorHostFunction>());
      final typed = hostFunction
          as CreateContractFromExternalRefWithConstructorHostFunction;
      expect(typed.executableOwner.contractId, ownerContractIdHex);
      expect(typed.tagString, executableTag);
      expect(typed.salt.uint256, fixedSalt.uint256);
      expect(typed.constructorArgs, isEmpty);
    });

    test('throws naming owner and tag when the reference does not resolve',
        () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, <XdrLedgerKey>[], <String>[],
          tagEntryExists: false);

      try {
        await SorobanClient.deployFromExternalRef(
            deployRequest: DeployFromExternalRefRequest(
          sourceAccountKeyPair: keyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          executableOwner: Address.forContractId(ownerContractIdHex),
          tag: executableTag,
          server: server,
        ));
        fail('expected an exception for an unresolvable reference');
      } on Exception catch (e) {
        expect(e.toString(), contains('does not resolve'));
        // A contract owner is spelled as its "C..." strkey.
        expect(e.toString(),
            contains(StrKey.encodeContractIdHex(ownerContractIdHex)));
        expect(e.toString(), contains(executableTag));
      }
      // The failure happened before anything was submitted.
      expect(requestLog, ['tag']);
    });

    test('throws naming an account owner without any request', () async {
      // The resolver answers null for a non-contract owner before issuing any
      // request, so the deploy error must name the account and nothing may
      // reach the server.
      final keyPair = KeyPair.random();
      final ownerKeyPair = KeyPair.random();
      final requestLog = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, <XdrLedgerKey>[], <String>[]);

      try {
        await SorobanClient.deployFromExternalRef(
            deployRequest: DeployFromExternalRefRequest(
          sourceAccountKeyPair: keyPair,
          network: Network.TESTNET,
          rpcUrl: rpcUrl,
          executableOwner: Address.forAccountId(ownerKeyPair.accountId),
          tag: executableTag,
          server: server,
        ));
        fail('expected an exception for a non-contract owner');
      } on Exception catch (e) {
        expect(e.toString(), contains('does not resolve'));
        expect(e.toString(), contains(ownerKeyPair.accountId));
        expect(e.toString(), contains(executableTag));
      }
      expect(requestLog, isEmpty);
    });

    test('spells muxed, claimable balance and liquidity pool owners', () async {
      // The resolver answers null for every non-contract owner before issuing
      // any request; the deploy error must name the owner as given.
      const muxedOwner =
          'MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK';
      const claimableBalanceOwner =
          '000000003f0918bf77f7e30fe942e4bc2ce903ffa2d80e7f3e1f82ba58877f0eb73df0b7';
      const liquidityPoolOwner =
          '3f0918bf77f7e30fe942e4bc2ce903ffa2d80e7f3e1f82ba58877f0eb73df0b7';
      final owners = [
        (Address.forMuxedAccountId(muxedOwner), muxedOwner),
        (Address.forClaimableBalanceId(claimableBalanceOwner),
            claimableBalanceOwner),
        (Address.forLiquidityPoolId(liquidityPoolOwner), liquidityPoolOwner),
      ];
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, <XdrLedgerKey>[], <String>[]);

      for (final (owner, spelling) in owners) {
        try {
          await SorobanClient.deployFromExternalRef(
              deployRequest: DeployFromExternalRefRequest(
            sourceAccountKeyPair: keyPair,
            network: Network.TESTNET,
            rpcUrl: rpcUrl,
            executableOwner: owner,
            tag: executableTag,
            server: server,
          ));
          fail('expected an exception for a non-contract owner');
        } on Exception catch (e) {
          expect(e.toString(), contains('does not resolve'));
          expect(e.toString(), contains(spelling));
        }
      }
      expect(requestLog, isEmpty);
    });

    test('falls back to forClientOptions when the code has no parseable spec',
        () async {
      // The spec preload throws SorobanContractParserFailed on the unparseable
      // code; the deployment proceeds anyway and the client is built through
      // the forClientOptions fallback, which reads the instance entry and the
      // code entry behind it after the deployment.
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, <XdrLedgerKey>[], <String>[],
          firstCodeLoadParseable: false);

      final client = await SorobanClient.deployFromExternalRef(
          deployRequest: DeployFromExternalRefRequest(
        sourceAccountKeyPair: keyPair,
        network: Network.TESTNET,
        rpcUrl: rpcUrl,
        executableOwner: Address.forContractId(ownerContractIdHex),
        tag: executableTag,
        server: server,
      ));

      expect(client.getContractId(), createdContractId);
      expect(client.getMethodNames(), contains('hello'));
      // The fallback read the instance after the deployment and loaded the
      // code a second time through it.
      expect(requestLog.indexOf('instance'),
          greaterThan(requestLog.indexOf('getTx')));
      expect(requestLog.where((r) => r == 'code'), hasLength(2));
    });

    test('throws when the transaction meta carries no created contract id',
        () async {
      final keyPair = KeyPair.random();
      final requestLog = <String>[];
      final server = externalRefDeployFlowMockServer(
          keyPair, requestLog, <XdrLedgerKey>[], <String>[],
          deployReturnsContractId: false);

      await expectLater(
          SorobanClient.deployFromExternalRef(
              deployRequest: DeployFromExternalRefRequest(
            sourceAccountKeyPair: keyPair,
            network: Network.TESTNET,
            rpcUrl: rpcUrl,
            executableOwner: Address.forContractId(ownerContractIdHex),
            tag: executableTag,
            server: server,
          )),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Could not get contract id for deployed contract'))));
    });

    test('constructs its own server from the rpc url when none is injected',
        () async {
      // No server is injected, so deployFromExternalRef builds one from the
      // rpc url and resolves against it; the unreachable port surfaces as the
      // transport error of that attempt.
      final keyPair = KeyPair.random();

      await expectLater(
          SorobanClient.deployFromExternalRef(
              deployRequest: DeployFromExternalRefRequest(
            sourceAccountKeyPair: keyPair,
            network: Network.TESTNET,
            rpcUrl: 'http://localhost:1',
            executableOwner: Address.forContractId(ownerContractIdHex),
            tag: executableTag,
          )),
          throwsA(isA<dio.DioException>()));
    });
  });

  group('Address.deriveContractId', () {
    // Shared vectors pinned across the Soneso SDKs; independently computed
    // (js-stellar-base and a hand-encoded preimage), never from this
    // implementation.
    final salt = Uint8List.fromList(List.filled(32, 0x11));

    test('matches the shared cross-SDK vector for an account deployer', () {
      final deployer = Address.forAccountId(
          'GABAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEJXA');

      expect(
          Address.deriveContractId(
              deployer: deployer, salt: salt, network: Network.TESTNET),
          'CADHEGA2PTPG6IJXYA62AY6JUQLQWOHRYX7A6FAZ4GL747OLBDQU7QXR');
      expect(
          Address.deriveContractId(
              deployer: deployer, salt: salt, network: Network.PUBLIC),
          'CC22JLXJCLGHDQDBHJXTOEAFRM7GIS3D7CBQXR7M22HMWYNPUUPH6GKV');
    });

    test('matches the pinned vector for a contract deployer', () {
      final deployer = Address.forContractId(
          '3f0918bf77f7e30fe942e4bc2ce903ffa2d80e7f3e1f82ba58877f0eb73df0b7');

      expect(
          Address.deriveContractId(
              deployer: deployer, salt: salt, network: Network.TESTNET),
          'CBU52TQFSCXOGX5OOE6QQKBRD3XNXAS2MRLI2XFKLGEODECDADE32QYU');
      expect(
          Address.deriveContractId(
              deployer: deployer, salt: salt, network: Network.PUBLIC),
          'CAXJ2CGFFIGYDFF55V64NWWUASL7IMAZTVVECYOKOVQWF4KQGXP2HH3U');
    });

    test('rejects a salt that is not exactly 32 bytes', () {
      final deployer = Address.forAccountId(
          'GABAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEAQCAIBAEJXA');

      // 31 for the off-by-one, 64 for the likeliest real mistake: a hex
      // string's byte length where raw bytes are expected.
      for (final length in [31, 64]) {
        expect(
            () => Address.deriveContractId(
                deployer: deployer,
                salt: Uint8List.fromList(List.filled(length, 0x11)),
                network: Network.TESTNET),
            throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
                contains('must be exactly 32 bytes, got $length'))));
      }
    });
  });
}
