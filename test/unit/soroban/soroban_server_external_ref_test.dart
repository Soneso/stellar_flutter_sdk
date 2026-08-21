import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// MockDioAdapter for mocking HTTP responses
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

void main() {
  const serverUrl = 'https://soroban-testnet.stellar.org';
  const contractId = 'CDCYWK73YTYFJZZSJ5V7EDFNHYBG4QN3VUNG2IGD27KJDDPNCZKBCBXK';
  final contractIdHash = StrKey.decodeContractIdHex(contractId);
  const ownerContractIdHex =
      'c0decafec0decafec0decafec0decafec0decafec0decafec0decafec0decafe';
  const wasmId =
      'f3b5c8a1d4e9b2f6c3d8e7a9b1c4d5e8f2a6b9c3d7e1a5b8c2d6e9a4b7c1d3e5';
  const executableTag = 'token-v1';
  const accountId = 'GAAZI4TCR3TY5OJHCTJC2A4QSY6CJWJH5IAJTGKIN2ER7LBNVKOCCWN7';

  XdrSCAddress ownerAddress() =>
      Address.forContractId(ownerContractIdHex).toXdr();

  XdrContractExecutable externalRefExecutable({String tag = executableTag}) =>
      XdrContractExecutable.forExternalRef(ownerAddress(), tag);

  XdrContractExecutable wasmExecutable() {
    final executable = XdrContractExecutable(
      XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM,
    );
    executable.wasmHash = XdrHash(Util.hexToBytes(wasmId));
    return executable;
  }

  XdrLedgerEntryData instanceEntryData(XdrContractExecutable executable) {
    final contractData = XdrContractDataEntry(
      XdrExtensionPoint(0),
      Address.forContractId(contractIdHash).toXdr(),
      XdrSCVal.forLedgerKeyContractInstance(),
      XdrContractDataDurability.PERSISTENT,
      XdrSCVal.forContractInstance(XdrSCContractInstance(executable, null)),
    );
    final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
    entryData.contractData = contractData;
    return entryData;
  }

  XdrLedgerEntryData tagEntryData(
    XdrSCVal value, {
    String tag = executableTag,
    XdrSCVal? tagValue,
  }) {
    final contractData = XdrContractDataEntry(
      XdrExtensionPoint(0),
      ownerAddress(),
      tagValue ?? XdrSCVal.forExecutableTag(tag),
      XdrContractDataDurability.PERSISTENT,
      value,
    );
    final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_DATA);
    entryData.contractData = contractData;
    return entryData;
  }

  XdrLedgerEntryData codeEntryData(Uint8List code) {
    final contractCode = XdrContractCodeEntry(
      XdrContractCodeEntryExt(0),
      XdrHash(Util.hexToBytes(wasmId)),
      code,
    );
    final entryData = XdrLedgerEntryData(XdrLedgerEntryType.CONTRACT_CODE);
    entryData.contractCode = contractCode;
    return entryData;
  }

  /// SorobanServer whose mocked transport serves [script] one response per
  /// getLedgerEntries call (an entry, or no entries for null) and records
  /// every requested ledger key into [capturedKeys].
  SorobanServer mockedServer(
    List<XdrLedgerEntryData?> script,
    List<String> capturedKeys,
  ) {
    var call = 0;
    final mockDio = dio.Dio();
    mockDio.httpClientAdapter = MockDioAdapter((options) {
      final requestBody = jsonDecode(options.data);
      expect(requestBody['method'], 'getLedgerEntries');
      capturedKeys.add((requestBody['params']['keys'] as List)[0]);
      expect(
        call,
        lessThan(script.length),
        reason: 'unexpected extra getLedgerEntries call',
      );
      final entryData = script[call++];
      final entries = entryData == null
          ? []
          : [
              {
                'key': (requestBody['params']['keys'] as List)[0],
                'xdr': entryData.toBase64EncodedXdrString(),
                'lastModifiedLedgerSeq': 99999,
              },
            ];
      return dio.ResponseBody.fromString(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': requestBody['id'],
          'result': {'entries': entries, 'latestLedger': 100000},
        }),
        200,
        headers: {
          'content-type': [dio.Headers.jsonContentType],
        },
      );
    });
    return SorobanServer(serverUrl, httpClient: mockDio);
  }

  group('external reference executables', () {
    test(
      'wasm arm still resolves through loadContractCodeForContractId',
      () async {
        final wasmCode = Uint8List.fromList([0, 97, 115, 109]);
        final capturedKeys = <String>[];
        final server = mockedServer([
          instanceEntryData(wasmExecutable()),
          codeEntryData(wasmCode),
        ], capturedKeys);

        final codeEntry = await server.loadContractCodeForContractId(
          contractIdHash,
        );

        expect(codeEntry, isNotNull);
        expect(codeEntry!.code, wasmCode);
        expect(capturedKeys.length, 2);

        final codeKey = XdrLedgerKey.fromBase64EncodedXdrString(
          capturedKeys[1],
        );
        expect(
          codeKey.discriminant.value,
          XdrLedgerEntryType.CONTRACT_CODE.value,
        );
        expect(Util.bytesToHex(codeKey.contractCode!.hash.hash), wasmId);
      },
    );

    test('getExternalRefWasmHash returns the hash the tag entry holds',
        () async {
      final server = mockedServer([
        tagEntryData(XdrSCVal.forBytes(Util.hexToBytes(wasmId))),
      ], <String>[]);
      final ref = externalRefExecutable().externalRef!;

      final wasmHash = await server.getExternalRefWasmHash(ref);

      expect(wasmHash, isNotNull);
      expect(wasmHash, Util.hexToBytes(wasmId));
    });

    test('a binary tag reaches the lookup key as its own bytes', () async {
      // The tag bytes spell no text, so any decode-and-reencode hop on the
      // resolution path would build the key of a different entry.
      final binaryTag = Uint8List.fromList([0xC0, 0x00, 0xFF, 0xFE]);
      final capturedKeys = <String>[];
      final server = mockedServer([
        tagEntryData(
          XdrSCVal.forBytes(Util.hexToBytes(wasmId)),
          tagValue: XdrSCVal.forExecutableTagBytes(binaryTag),
        ),
      ], capturedKeys);
      final ref = XdrContractExecutable.forExternalRefBytes(
        ownerAddress(),
        binaryTag,
      ).externalRef!;

      final wasmHash = await server.getExternalRefWasmHash(ref);

      expect(wasmHash, Util.hexToBytes(wasmId));
      expect(capturedKeys.length, 1);
      final tagKey = XdrLedgerKey.fromBase64EncodedXdrString(capturedKeys[0]);
      expect(tagKey.contractData!.key.executableTag, binaryTag);
    });

    test('external ref resolves through the owner tag entry', () async {
      final wasmCode = Uint8List.fromList([0, 97, 115, 109, 1]);
      final capturedKeys = <String>[];
      final server = mockedServer([
        instanceEntryData(externalRefExecutable()),
        tagEntryData(XdrSCVal.forBytes(Util.hexToBytes(wasmId))),
        codeEntryData(wasmCode),
      ], capturedKeys);

      final codeEntry = await server.loadContractCodeForContractId(
        contractIdHash,
      );

      expect(codeEntry, isNotNull);
      expect(codeEntry!.code, wasmCode);
      expect(capturedKeys.length, 3);

      final tagKey = XdrLedgerKey.fromBase64EncodedXdrString(capturedKeys[1]);
      expect(tagKey.discriminant.value, XdrLedgerEntryType.CONTRACT_DATA.value);
      final contractDataKey = tagKey.contractData!;
      expect(
        Util.bytesToHex(contractDataKey.contract.contractId!.hash),
        ownerContractIdHex,
      );
      expect(
        contractDataKey.key.discriminant.value,
        XdrSCValType.SCV_EXECUTABLE_TAG.value,
      );
      expect(contractDataKey.key.executableTagString, executableTag);
      expect(
        contractDataKey.durability.value,
        XdrContractDataDurability.PERSISTENT.value,
      );

      final codeKey = XdrLedgerKey.fromBase64EncodedXdrString(capturedKeys[2]);
      expect(
        codeKey.discriminant.value,
        XdrLedgerEntryType.CONTRACT_CODE.value,
      );
      expect(Util.bytesToHex(codeKey.contractCode!.hash.hash), wasmId);
    });

    test('missing tag entry yields null and stops the resolution', () async {
      final directKeys = <String>[];
      final directServer = mockedServer([null], directKeys);
      final ref = externalRefExecutable().externalRef!;
      expect(await directServer.getExternalRefWasmHash(ref), isNull);
      expect(directKeys.length, 1);

      final loaderKeys = <String>[];
      final loaderServer = mockedServer([
        instanceEntryData(externalRefExecutable()),
        null,
      ], loaderKeys);
      expect(
        await loaderServer.loadContractCodeForContractId(contractIdHash),
        isNull,
      );
      expect(loaderKeys.length, 2);
    });

    test('tag entry value that is not SCV_BYTES yields null', () async {
      final server = mockedServer([
        tagEntryData(XdrSCVal.forSymbol('not_a_hash')),
      ], <String>[]);
      final ref = externalRefExecutable().externalRef!;
      expect(await server.getExternalRefWasmHash(ref), isNull);
    });

    test('tag entry value of the wrong length yields null', () async {
      final ref = externalRefExecutable().externalRef!;

      final shortServer = mockedServer([
        tagEntryData(XdrSCVal.forBytes(Uint8List(31))),
      ], <String>[]);
      expect(await shortServer.getExternalRefWasmHash(ref), isNull);

      final longServer = mockedServer([
        tagEntryData(XdrSCVal.forBytes(Uint8List(33))),
      ], <String>[]);
      expect(await longServer.getExternalRefWasmHash(ref), isNull);
    });

    test(
      'owner that is not a contract yields null without any request',
      () async {
        final capturedKeys = <String>[];
        final server = mockedServer([], capturedKeys);
        final ref = XdrContractExecutable.forExternalRef(
          Address.forAccountId(accountId).toXdr(),
          executableTag,
        ).externalRef!;

        expect(await server.getExternalRefWasmHash(ref), isNull);
        expect(capturedKeys, isEmpty);
      },
    );

    test(
      'stellar asset contract yields null after the instance read',
      () async {
        final capturedKeys = <String>[];
        final sacExecutable = XdrContractExecutable(
          XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET,
        );
        final server = mockedServer([
          instanceEntryData(sacExecutable),
        ], capturedKeys);

        expect(
          await server.loadContractCodeForContractId(contractIdHash),
          isNull,
        );
        expect(capturedKeys.length, 1);
      },
    );

    test('tag survives the XDR round trip into the same ledger key', () {
      const tag = 'tøken-\u0000-火';
      final writtenKey = XdrSCVal.forExecutableTag(
        tag,
      ).toBase64EncodedXdrString();

      final encoded = XdrSCVal.forContractInstance(
        XdrSCContractInstance(externalRefExecutable(tag: tag), null),
      ).toBase64EncodedXdrString();
      final decodedTag = XdrSCVal.fromBase64EncodedXdrString(
        encoded,
      ).instance!.executable.externalRef!.tag;

      expect(decodedTag, utf8.encode(tag));
      expect(
        XdrSCVal.forExecutableTagBytes(decodedTag).toBase64EncodedXdrString(),
        writtenKey,
      );
    });

    test(
      'loadContractInfoForContractId parses code behind an external ref',
      () async {
        final wasm = File(
          'test/wasm/soroban_hello_world_contract.wasm',
        ).readAsBytesSync();
        final server = mockedServer([
          instanceEntryData(externalRefExecutable()),
          tagEntryData(XdrSCVal.forBytes(Util.hexToBytes(wasmId))),
          codeEntryData(wasm),
        ], <String>[]);

        final info = await server.loadContractInfoForContractId(contractIdHash);

        expect(info, isNotNull);
        expect(info!.specEntries, isNotEmpty);
      },
    );
  });

  group('create contract host functions with external ref', () {
    final fixedSalt = XdrUint256(
      Uint8List.fromList(List.generate(32, (i) => i)),
    );
    final deployer = Address.forAccountId(accountId);
    final owner = Address.forContractId(ownerContractIdHex);

    test('create contract round trips byte-identically', () {
      final hostFunction =
          CreateContractFromExternalRefHostFunction.forTagString(
            deployer,
            owner,
            executableTag,
            salt: fixedSalt,
          );
      final xdr = hostFunction.toXdr();

      final parsed = HostFunction.fromXdr(xdr);

      expect(parsed, isA<CreateContractFromExternalRefHostFunction>());
      final typed = parsed as CreateContractFromExternalRefHostFunction;
      expect(typed.tagString, executableTag);
      expect(typed.executableOwner.contractId, ownerContractIdHex);
      expect(typed.salt.uint256, fixedSalt.uint256);
      expect(
        typed.toXdr().toBase64EncodedXdrString(),
        xdr.toBase64EncodedXdrString(),
      );
    });

    test('create contract with constructor round trips byte-identically', () {
      final hostFunction =
          CreateContractFromExternalRefWithConstructorHostFunction.forTagString(
            deployer,
            owner,
            executableTag,
            [XdrSCVal.forU32(7)],
            salt: fixedSalt,
          );
      final xdr = hostFunction.toXdr();

      final parsed = HostFunction.fromXdr(xdr);

      expect(
        parsed,
        isA<CreateContractFromExternalRefWithConstructorHostFunction>(),
      );
      final typed =
          parsed as CreateContractFromExternalRefWithConstructorHostFunction;
      expect(typed.tagString, executableTag);
      expect(typed.executableOwner.contractId, ownerContractIdHex);
      expect(typed.constructorArgs.length, 1);
      expect(typed.constructorArgs[0].u32!.uint32, 7);
      expect(
        typed.toXdr().toBase64EncodedXdrString(),
        xdr.toBase64EncodedXdrString(),
      );
    });

    test('create contract generates a 32-byte salt when none is given', () {
      final hostFunction =
          CreateContractFromExternalRefHostFunction.forTagString(
            deployer,
            owner,
            executableTag,
          );

      expect(hostFunction.salt.uint256.length, 32);
      final xdr = hostFunction.toXdr();
      expect(
        xdr.createContract!.contractIDPreimage.salt!.uint256,
        hostFunction.salt.uint256,
      );
    });

    test(
      'create contract with constructor generates a 32-byte salt when none is given',
      () {
        final hostFunction =
            CreateContractFromExternalRefWithConstructorHostFunction.forTagString(
              deployer,
              owner,
              executableTag,
              [XdrSCVal.forU32(7)],
            );

        expect(hostFunction.salt.uint256.length, 32);
        final xdr = hostFunction.toXdr();
        expect(
          xdr.createContractV2!.contractIDPreimage.salt!.uint256,
          hostFunction.salt.uint256,
        );
      },
    );

    test('create contract setters replace every field before encoding', () {
      final otherDeployer = Address.forContractId(contractIdHash);
      final otherOwner = Address.forContractId(
        'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
      );
      final otherSalt = XdrUint256(
        Uint8List.fromList(List.generate(32, (i) => 255 - i)),
      );

      final hostFunction =
          CreateContractFromExternalRefHostFunction.forTagString(
            deployer,
            owner,
            executableTag,
            salt: fixedSalt,
          );
      hostFunction.address = otherDeployer;
      hostFunction.executableOwner = otherOwner;
      hostFunction.tag = Uint8List.fromList(utf8.encode('token-v2'));
      hostFunction.salt = otherSalt;

      final expected =
          CreateContractFromExternalRefHostFunction.forTagString(
            otherDeployer,
            otherOwner,
            'token-v2',
            salt: otherSalt,
          );
      expect(hostFunction.address.contractId, otherDeployer.contractId);
      expect(
        hostFunction.toXdr().toBase64EncodedXdrString(),
        expected.toXdr().toBase64EncodedXdrString(),
      );
    });

    test(
      'create contract with constructor setters replace every field before encoding',
      () {
        final otherDeployer = Address.forContractId(contractIdHash);
        final otherOwner = Address.forContractId(
          'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
        );
        final otherSalt = XdrUint256(
          Uint8List.fromList(List.generate(32, (i) => 255 - i)),
        );

        final hostFunction =
            CreateContractFromExternalRefWithConstructorHostFunction.forTagString(
              deployer,
              owner,
              executableTag,
              [XdrSCVal.forU32(7)],
              salt: fixedSalt,
            );
        hostFunction.address = otherDeployer;
        hostFunction.executableOwner = otherOwner;
        hostFunction.tag = Uint8List.fromList(utf8.encode('token-v2'));
        hostFunction.constructorArgs = [XdrSCVal.forU32(9)];
        hostFunction.salt = otherSalt;

        final expected =
            CreateContractFromExternalRefWithConstructorHostFunction.forTagString(
              otherDeployer,
              otherOwner,
              'token-v2',
              [XdrSCVal.forU32(9)],
              salt: otherSalt,
            );
        expect(hostFunction.address.contractId, otherDeployer.contractId);
        expect(
          hostFunction.toXdr().toBase64EncodedXdrString(),
          expected.toXdr().toBase64EncodedXdrString(),
        );
      },
    );
  });
}
