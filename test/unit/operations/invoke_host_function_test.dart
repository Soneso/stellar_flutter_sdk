import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('UploadContractWasmHostFunction', () {
    test('create upload contract wasm host function', () {
      final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes);

      expect(uploadFunction.contractCode, equals(wasmBytes));
      expect(uploadFunction.contractCode.length, equals(4));
    });

    test('convert upload wasm to XDR and back', () {
      final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00]);
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes);

      final xdr = uploadFunction.toXdr();
      expect(xdr.type, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM));
      expect(xdr.wasm, isNotNull);
      expect(xdr.wasm!.dataValue, equals(wasmBytes));

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<UploadContractWasmHostFunction>());
      expect((decoded as UploadContractWasmHostFunction).contractCode, equals(wasmBytes));
    });

    test('modify contract code', () {
      final wasmBytes1 = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);
      final wasmBytes2 = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes1);

      expect(uploadFunction.contractCode, equals(wasmBytes1));

      uploadFunction.contractCode = wasmBytes2;
      expect(uploadFunction.contractCode, equals(wasmBytes2));
    });
  });

  group('CreateContractHostFunction', () {
    test('create contract with generated salt', () {
      final address = Address.forAccountId(KeyPair.random().accountId);
      final wasmId = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

      final createFunction = CreateContractHostFunction(address, wasmId);

      expect(createFunction.address, equals(address));
      expect(createFunction.wasmId, equals(wasmId));
      expect(createFunction.salt, isNotNull);
      expect(createFunction.salt.uint256.length, equals(32));
    });

    test('create contract with provided salt', () {
      final address = Address.forAccountId(KeyPair.random().accountId);
      final wasmId = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
      final salt = XdrUint256(Uint8List(32));

      final createFunction = CreateContractHostFunction(address, wasmId, salt: salt);

      expect(createFunction.address, equals(address));
      expect(createFunction.wasmId, equals(wasmId));
      expect(createFunction.salt, equals(salt));
    });

    test('convert create contract to XDR and back', () {
      final accountId = KeyPair.random().accountId;
      final address = Address.forAccountId(accountId);
      final wasmId = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
      final salt = XdrUint256(Uint8List.fromList(List.generate(32, (i) => i)));

      final createFunction = CreateContractHostFunction(address, wasmId, salt: salt);

      final xdr = createFunction.toXdr();
      expect(xdr.type, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT));
      expect(xdr.createContract, isNotNull);

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<CreateContractHostFunction>());
      final decodedCreate = decoded as CreateContractHostFunction;
      expect(decodedCreate.address.accountId, equals(accountId));
      expect(decodedCreate.wasmId, equals(wasmId));
      expect(decodedCreate.salt.uint256, equals(salt.uint256));
    });

    test('modify contract properties', () {
      final address1 = Address.forAccountId(KeyPair.random().accountId);
      final address2 = Address.forAccountId(KeyPair.random().accountId);
      final wasmId1 = 'aaaa';
      final wasmId2 = 'bbbb';

      final createFunction = CreateContractHostFunction(address1, wasmId1);
      expect(createFunction.address, equals(address1));
      expect(createFunction.wasmId, equals(wasmId1));

      createFunction.address = address2;
      createFunction.wasmId = wasmId2;

      expect(createFunction.address, equals(address2));
      expect(createFunction.wasmId, equals(wasmId2));
    });

    test('modifies salt', () {
      final address = Address.forAccountId(KeyPair.random().accountId);
      final wasmId =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final salt1 = XdrUint256(Uint8List.fromList(List.filled(32, 0x01)));
      final salt2 = XdrUint256(Uint8List.fromList(List.filled(32, 0x02)));

      final createFunction =
          CreateContractHostFunction(address, wasmId, salt: salt1);
      expect(createFunction.salt.uint256, equals(salt1.uint256));

      createFunction.salt = salt2;
      expect(createFunction.salt.uint256, equals(salt2.uint256));
    });
  });

  group('CreateContractWithConstructorHostFunction', () {
    test('create contract with constructor and generated salt', () {
      final address = Address.forAccountId(KeyPair.random().accountId);
      final wasmId = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final constructorArgs = <XdrSCVal>[
        XdrSCVal.forU32(42),
        XdrSCVal.forSymbol('test'),
      ];

      final createFunction = CreateContractWithConstructorHostFunction(
        address,
        wasmId,
        constructorArgs,
      );

      expect(createFunction.address, equals(address));
      expect(createFunction.wasmId, equals(wasmId));
      expect(createFunction.constructorArgs, equals(constructorArgs));
      expect(createFunction.salt, isNotNull);
      expect(createFunction.salt.uint256.length, equals(32));
    });

    test('create contract with constructor and provided salt', () {
      final address = Address.forAccountId(KeyPair.random().accountId);
      final wasmId = 'aabbccdd00112233aabbccdd00112233aabbccdd00112233aabbccdd00112233';
      final constructorArgs = <XdrSCVal>[XdrSCVal.forBool(true)];
      final salt = XdrUint256(Uint8List.fromList(List.filled(32, 0xFF)));

      final createFunction = CreateContractWithConstructorHostFunction(
        address,
        wasmId,
        constructorArgs,
        salt: salt,
      );

      expect(createFunction.salt, equals(salt));
    });

    test('convert create contract with constructor to XDR and back', () {
      final accountId = KeyPair.random().accountId;
      final address = Address.forAccountId(accountId);
      final wasmId = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
      final constructorArgs = <XdrSCVal>[
        XdrSCVal.forU64(BigInt.from(1000)),
        XdrSCVal.forSymbol('init'),
      ];
      final salt = XdrUint256(Uint8List.fromList(List.generate(32, (i) => i * 2)));

      final createFunction = CreateContractWithConstructorHostFunction(
        address,
        wasmId,
        constructorArgs,
        salt: salt,
      );

      final xdr = createFunction.toXdr();
      expect(xdr.type, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2));
      expect(xdr.createContractV2, isNotNull);

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<CreateContractWithConstructorHostFunction>());
      final decodedCreate = decoded as CreateContractWithConstructorHostFunction;
      expect(decodedCreate.address.accountId, equals(accountId));
      expect(decodedCreate.wasmId, equals(wasmId));
      expect(decodedCreate.constructorArgs.length, equals(2));
      expect(decodedCreate.salt.uint256, equals(salt.uint256));
    });

    test('create contract with empty constructor args', () {
      final address = Address.forAccountId(KeyPair.random().accountId);
      final wasmId = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
      final constructorArgs = <XdrSCVal>[];

      final createFunction = CreateContractWithConstructorHostFunction(
        address,
        wasmId,
        constructorArgs,
      );

      expect(createFunction.constructorArgs, isEmpty);
    });

    test('XDR roundtrip V2 with three constructor args', () {
      final accountId = KeyPair.random().accountId;
      final address = Address.forAccountId(accountId);
      final wasmId =
          'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
      final constructorArgs = <XdrSCVal>[
        XdrSCVal.forU64(BigInt.from(1000)),
        XdrSCVal.forSymbol('init'),
        XdrSCVal.forBool(true),
      ];
      final salt =
          XdrUint256(Uint8List.fromList(List.generate(32, (i) => i * 2)));

      final createFunction = CreateContractWithConstructorHostFunction(
        address,
        wasmId,
        constructorArgs,
        salt: salt,
      );

      final xdr = createFunction.toXdr();
      expect(xdr.type,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT_V2));
      expect(xdr.createContractV2, isNotNull);
      expect(xdr.createContractV2!.constructorArgs.length, equals(3));

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<CreateContractWithConstructorHostFunction>());
      final decodedCreate = decoded as CreateContractWithConstructorHostFunction;
      expect(decodedCreate.address.accountId, equals(accountId));
      expect(decodedCreate.wasmId, equals(wasmId));
      expect(decodedCreate.constructorArgs.length, equals(3));
      expect(decodedCreate.salt.uint256, equals(salt.uint256));
    });

    test('setters', () {
      final address1 = Address.forAccountId(KeyPair.random().accountId);
      final address2 = Address.forAccountId(KeyPair.random().accountId);
      final wasmId1 = 'aaaa';
      final wasmId2 = 'bbbb';
      final args1 = <XdrSCVal>[XdrSCVal.forU32(1)];
      final args2 = <XdrSCVal>[XdrSCVal.forU32(2)];

      final createFunction = CreateContractWithConstructorHostFunction(
        address1,
        wasmId1,
        args1,
      );

      expect(createFunction.address, equals(address1));
      expect(createFunction.wasmId, equals(wasmId1));
      expect(createFunction.constructorArgs, equals(args1));

      createFunction.address = address2;
      createFunction.wasmId = wasmId2;
      createFunction.constructorArgs = args2;

      expect(createFunction.address, equals(address2));
      expect(createFunction.wasmId, equals(wasmId2));
      expect(createFunction.constructorArgs, equals(args2));
    });
  });

  group('DeploySACWithAssetHostFunction', () {
    test('deploy SAC with native asset', () {
      final asset = AssetTypeNative();

      final deploySACFunction = DeploySACWithAssetHostFunction(asset);

      expect(deploySACFunction.asset, equals(asset));
      expect(deploySACFunction.asset, isA<AssetTypeNative>());
    });

    test('deploy SAC with AlphaNum4 asset', () {
      final issuerKeyPair = KeyPair.random();
      final asset = AssetTypeCreditAlphaNum4('USDC', issuerKeyPair.accountId);

      final deploySACFunction = DeploySACWithAssetHostFunction(asset);

      expect(deploySACFunction.asset, equals(asset));
      expect(deploySACFunction.asset, isA<AssetTypeCreditAlphaNum4>());
      final creditAsset = deploySACFunction.asset as AssetTypeCreditAlphaNum4;
      expect(creditAsset.code, equals('USDC'));
      expect(creditAsset.issuerId, equals(issuerKeyPair.accountId));
    });

    test('deploy SAC with AlphaNum12 asset', () {
      final issuerKeyPair = KeyPair.random();
      final asset = AssetTypeCreditAlphaNum12('LONGASSET', issuerKeyPair.accountId);

      final deploySACFunction = DeploySACWithAssetHostFunction(asset);

      expect(deploySACFunction.asset, equals(asset));
      expect(deploySACFunction.asset, isA<AssetTypeCreditAlphaNum12>());
      final creditAsset = deploySACFunction.asset as AssetTypeCreditAlphaNum12;
      expect(creditAsset.code, equals('LONGASSET'));
      expect(creditAsset.issuerId, equals(issuerKeyPair.accountId));
    });

    test('convert deploy SAC asset to XDR and back with native', () {
      final asset = AssetTypeNative();
      final deploySACFunction = DeploySACWithAssetHostFunction(asset);

      final xdr = deploySACFunction.toXdr();
      expect(xdr.type, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT));
      expect(xdr.createContract, isNotNull);

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<DeploySACWithAssetHostFunction>());
      final decodedDeploy = decoded as DeploySACWithAssetHostFunction;
      expect(decodedDeploy.asset, isA<AssetTypeNative>());
    });

    test('convert deploy SAC asset to XDR and back with credit asset', () {
      final issuerKeyPair = KeyPair.random();
      final asset = AssetTypeCreditAlphaNum4('EUR', issuerKeyPair.accountId);
      final deploySACFunction = DeploySACWithAssetHostFunction(asset);

      final xdr = deploySACFunction.toXdr();
      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<DeploySACWithAssetHostFunction>());
      final decodedDeploy = decoded as DeploySACWithAssetHostFunction;
      expect(decodedDeploy.asset, isA<AssetTypeCreditAlphaNum4>());
      final creditAsset = decodedDeploy.asset as AssetTypeCreditAlphaNum4;
      expect(creditAsset.code, equals('EUR'));
      expect(creditAsset.issuerId, equals(issuerKeyPair.accountId));
    });

    test('XDR roundtrip with AlphaNum12', () {
      final issuerKeyPair = KeyPair.random();
      final asset =
          AssetTypeCreditAlphaNum12('LONGASSET', issuerKeyPair.accountId);
      final deploySACFunction = DeploySACWithAssetHostFunction(asset);

      final xdr = deploySACFunction.toXdr();
      expect(xdr.type,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT));
      expect(xdr.createContract, isNotNull);
      expect(xdr.createContract!.contractIDPreimage.type,
          equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ASSET));

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<DeploySACWithAssetHostFunction>());
      final decodedDeploy = decoded as DeploySACWithAssetHostFunction;
      expect(decodedDeploy.asset, isA<AssetTypeCreditAlphaNum12>());
      final creditAsset = decodedDeploy.asset as AssetTypeCreditAlphaNum12;
      expect(creditAsset.code, equals('LONGASSET'));
      expect(creditAsset.issuerId, equals(issuerKeyPair.accountId));
    });

    test('asset setter', () {
      final asset1 = AssetTypeNative();
      final issuerKeyPair = KeyPair.random();
      final asset2 =
          AssetTypeCreditAlphaNum4('USDC', issuerKeyPair.accountId);

      final deploySACFunction = DeploySACWithAssetHostFunction(asset1);

      expect(deploySACFunction.asset, equals(asset1));

      deploySACFunction.asset = asset2;

      expect(deploySACFunction.asset, equals(asset2));
      expect(deploySACFunction.asset, isA<AssetTypeCreditAlphaNum4>());
    });
  });

  group('InvokeContractHostFunction', () {
    test('create invoke contract without arguments', () {
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final functionName = 'balance';

      final invokeFunction = InvokeContractHostFunction(contractId, functionName);

      expect(invokeFunction.contractID, equals(contractId));
      expect(invokeFunction.functionName, equals(functionName));
      expect(invokeFunction.arguments, isNull);
    });

    test('create invoke contract with arguments', () {
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final functionName = 'transfer';
      final args = <XdrSCVal>[
        XdrSCVal.forU32(100),
        XdrSCVal.forSymbol('recipient'),
      ];

      final invokeFunction = InvokeContractHostFunction(contractId, functionName, arguments: args);

      expect(invokeFunction.contractID, equals(contractId));
      expect(invokeFunction.functionName, equals(functionName));
      expect(invokeFunction.arguments, equals(args));
      expect(invokeFunction.arguments!.length, equals(2));
    });

    test('convert invoke contract to XDR and back without arguments', () {
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final functionName = 'get_count';

      final invokeFunction = InvokeContractHostFunction(contractId, functionName);

      final xdr = invokeFunction.toXdr();
      expect(xdr.type, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT));
      expect(xdr.invokeContract, isNotNull);
      expect(xdr.invokeContract!.functionName, equals(functionName));
      expect(xdr.invokeContract!.args, isEmpty);

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<InvokeContractHostFunction>());
      final decodedInvoke = decoded as InvokeContractHostFunction;
      expect(decodedInvoke.contractID, equals(contractId));
      expect(decodedInvoke.functionName, equals(functionName));
      expect(decodedInvoke.arguments, isEmpty);
    });

    test('convert invoke contract to XDR and back with arguments', () {
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final functionName = 'swap';
      final args = <XdrSCVal>[
        XdrSCVal.forU64(BigInt.from(5000)),
        XdrSCVal.forBool(true),
      ];

      final invokeFunction = InvokeContractHostFunction(contractId, functionName, arguments: args);

      final xdr = invokeFunction.toXdr();
      expect(xdr.invokeContract!.args.length, equals(2));

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<InvokeContractHostFunction>());
      final decodedInvoke = decoded as InvokeContractHostFunction;
      expect(decodedInvoke.arguments!.length, equals(2));
    });

    test('modify invoke contract properties', () {
      final contractId1 = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final contractId2 = Address.forContractId('CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD2KM').contractId!;
      final functionName1 = 'func1';
      final functionName2 = 'func2';

      final invokeFunction = InvokeContractHostFunction(contractId1, functionName1);
      expect(invokeFunction.contractID, equals(contractId1));
      expect(invokeFunction.functionName, equals(functionName1));

      invokeFunction.contractID = contractId2;
      invokeFunction.functionName = functionName2;

      expect(invokeFunction.contractID, equals(contractId2));
      expect(invokeFunction.functionName, equals(functionName2));
    });

    test('with complex arguments', () {
      final contractId = Address.forContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE')
          .contractId!;
      final functionName = 'complex_function';
      final args = <XdrSCVal>[
        XdrSCVal.forU32(100),
        XdrSCVal.forI32(-50),
        XdrSCVal.forU64(BigInt.from(5000)),
        XdrSCVal.forI64(BigInt.from(-3000)),
        XdrSCVal.forBool(true),
        XdrSCVal.forSymbol('test'),
      ];

      final invokeFunction =
          InvokeContractHostFunction(contractId, functionName, arguments: args);

      final xdr = invokeFunction.toXdr();
      expect(xdr.type,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT));
      expect(xdr.invokeContract, isNotNull);
      expect(xdr.invokeContract!.functionName, equals(functionName));
      expect(xdr.invokeContract!.args.length, equals(6));

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<InvokeContractHostFunction>());
      final decodedInvoke = decoded as InvokeContractHostFunction;
      expect(decodedInvoke.contractID, equals(contractId));
      expect(decodedInvoke.functionName, equals(functionName));
      expect(decodedInvoke.arguments!.length, equals(6));
    });

    test('modifies arguments', () {
      final contractId = Address.forContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE')
          .contractId!;
      final args1 = <XdrSCVal>[XdrSCVal.forU32(100)];
      final args2 = <XdrSCVal>[XdrSCVal.forU32(200), XdrSCVal.forBool(true)];

      final invokeFunction =
          InvokeContractHostFunction(contractId, 'test', arguments: args1);
      expect(invokeFunction.arguments!.length, equals(1));

      invokeFunction.arguments = args2;
      expect(invokeFunction.arguments!.length, equals(2));
    });
  });

  group('UploadContractWasmHostFunction Edge Cases', () {
    test('with empty WASM', () {
      final wasmBytes = Uint8List.fromList([]);
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes);

      expect(uploadFunction.contractCode, equals(wasmBytes));
      expect(uploadFunction.contractCode.length, equals(0));

      final xdr = uploadFunction.toXdr();
      expect(xdr.type,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_UPLOAD_CONTRACT_WASM));
      expect(xdr.wasm, isNotNull);
      expect(xdr.wasm!.dataValue.length, equals(0));
    });

    test('with large WASM', () {
      final wasmBytes = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes);

      expect(uploadFunction.contractCode.length, equals(1000));

      final xdr = uploadFunction.toXdr();
      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<UploadContractWasmHostFunction>());
      final decodedUpload = decoded as UploadContractWasmHostFunction;
      expect(decodedUpload.contractCode, equals(wasmBytes));
    });
  });

  group('InvokeHostFuncOpBuilder', () {
    test('build invoke host function operation without auth', () {
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final invokeFunction = InvokeContractHostFunction(contractId, 'test');

      final operation = InvokeHostFuncOpBuilder(invokeFunction).build();

      expect(operation, isA<InvokeHostFunctionOperation>());
      expect(operation.function, equals(invokeFunction));
      expect(operation.auth, isEmpty);
      expect(operation.sourceAccount, isNull);
    });

    test('build invoke host function operation with source account', () {
      final sourceKeyPair = KeyPair.random();
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final invokeFunction = InvokeContractHostFunction(contractId, 'test');

      final operation = InvokeHostFuncOpBuilder(invokeFunction)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      expect(operation.sourceAccount, isNotNull);
      expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('build with different host function types', () {
      final wasmBytes = Uint8List.fromList([0x00, 0x61, 0x73, 0x6d]);
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes);

      final operation = InvokeHostFuncOpBuilder(uploadFunction).build();

      expect(operation.function, isA<UploadContractWasmHostFunction>());
    });

    test('set host function via builder', () {
      final function1 = UploadContractWasmHostFunction(Uint8List(4));
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final function2 = InvokeContractHostFunction(contractId, 'test');

      final builder = InvokeHostFuncOpBuilder(function1);
      expect(builder.function, equals(function1));

      builder.setHostFunction(function2);
      expect(builder.function, equals(function2));

      final operation = builder.build();
      expect(operation.function, equals(function2));
    });

    test('builder method chaining', () {
      final sourceKeyPair = KeyPair.random();
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final invokeFunction = InvokeContractHostFunction(contractId, 'chain_test');

      final operation = InvokeHostFuncOpBuilder(invokeFunction)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
      expect(operation.function, equals(invokeFunction));
    });

    test('builds operation with muxed source account', () {
      final sourceKeyPair = KeyPair.random();
      final muxedAccount =
          MuxedAccount.fromAccountId(sourceKeyPair.accountId)!;
      final contractId = Address.forContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE')
          .contractId!;
      final invokeFunction =
          InvokeContractHostFunction(contractId, 'test');

      final operation = InvokeHostFuncOpBuilder(invokeFunction)
          .setMuxedSourceAccount(muxedAccount)
          .build();

      expect(operation.sourceAccount, equals(muxedAccount));
    });

    test('builds operation and verifies XDR output', () {
      final sourceKeyPair = KeyPair.random();
      final contractId = Address.forContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE')
          .contractId!;
      final invokeFunction =
          InvokeContractHostFunction(contractId, 'test_func');

      final operation = InvokeHostFuncOpBuilder(invokeFunction)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      final xdrBody = operation.toOperationBody();
      expect(xdrBody.discriminant, equals(XdrOperationType.INVOKE_HOST_FUNCTION));
      expect(xdrBody.invokeHostFunctionOp, isNotNull);
      expect(xdrBody.invokeHostFunctionOp!.function.type,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT));
    });

    test('operation with empty auth list', () {
      final contractId = Address.forContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE')
          .contractId!;
      final invokeFunction =
          InvokeContractHostFunction(contractId, 'test');
      final operation = InvokeHostFunctionOperation(invokeFunction);

      final xdrBody = operation.toOperationBody();
      expect(xdrBody.invokeHostFunctionOp!.auth, isEmpty);

      final builder =
          InvokeHostFunctionOperation.builder(xdrBody.invokeHostFunctionOp!);
      final rebuilt = builder.build();

      expect(rebuilt.auth, isEmpty);
    });

    test('function setter', () {
      final function1 =
          UploadContractWasmHostFunction(Uint8List.fromList([1, 2, 3, 4]));
      final contractId = Address.forContractId(
              'CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE')
          .contractId!;
      final function2 = InvokeContractHostFunction(contractId, 'test');

      final builder = InvokeHostFuncOpBuilder(function1);
      expect(builder.function, equals(function1));

      builder.function = function2;
      expect(builder.function, equals(function2));
    });
  });

  group('InvokeHostFunctionOperation', () {
    test('create operation and convert to XDR', () {
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final invokeFunction = InvokeContractHostFunction(contractId, 'test_func');
      final operation = InvokeHostFunctionOperation(invokeFunction);

      final xdrBody = operation.toOperationBody();

      expect(xdrBody.discriminant, equals(XdrOperationType.INVOKE_HOST_FUNCTION));
      expect(xdrBody.invokeHostFunctionOp, isNotNull);
      expect(xdrBody.invokeHostFunctionOp!.function.type,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_INVOKE_CONTRACT));
    });

    test('create operation from XDR builder', () {
      final contractId = Address.forContractId('CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE').contractId!;
      final invokeFunction = InvokeContractHostFunction(contractId, 'from_xdr');
      final operation = InvokeHostFunctionOperation(invokeFunction);
      final xdrBody = operation.toOperationBody();

      final builder = InvokeHostFunctionOperation.builder(xdrBody.invokeHostFunctionOp!);
      final rebuilt = builder.build();

      expect(rebuilt.function, isA<InvokeContractHostFunction>());
      expect(rebuilt.auth, isEmpty);
    });
  });

  group('ExtendFootprintTTLOperation', () {
    test('create extend footprint TTL operation', () {
      final extendTo = 100000;
      final operation = ExtendFootprintTTLOperation(extendTo);

      expect(operation.extendTo, equals(extendTo));
    });

    test('convert extend TTL to XDR', () {
      final extendTo = 50000;
      final operation = ExtendFootprintTTLOperation(extendTo);

      final xdrBody = operation.toOperationBody();

      expect(xdrBody.discriminant, equals(XdrOperationType.EXTEND_FOOTPRINT_TTL));
      expect(xdrBody.bumpExpirationOp, isNotNull);
      expect(xdrBody.bumpExpirationOp!.extendTo.uint32, equals(extendTo));
    });

    test('create from XDR builder', () {
      final extendTo = 75000;
      final operation = ExtendFootprintTTLOperation(extendTo);
      final xdrBody = operation.toOperationBody();

      final builder = ExtendFootprintTTLOperation.builder(xdrBody.bumpExpirationOp!);
      final rebuilt = builder.build();

      expect(rebuilt.extendTo, equals(extendTo));
    });

    test('extend with zero value', () {
      final operation = ExtendFootprintTTLOperation(0);
      expect(operation.extendTo, equals(0));

      final xdrBody = operation.toOperationBody();
      expect(xdrBody.bumpExpirationOp!.extendTo.uint32, equals(0));
    });

    test('extend with max uint32 value', () {
      final maxValue = 4294967295; // 2^32 - 1
      final operation = ExtendFootprintTTLOperation(maxValue);
      expect(operation.extendTo, equals(maxValue));

      final xdrBody = operation.toOperationBody();
      expect(xdrBody.bumpExpirationOp!.extendTo.uint32, equals(maxValue));
    });
  });

  group('ExtendFootprintTTLOperationBuilder', () {
    test('build extend footprint TTL operation', () {
      final extendTo = 200000;
      final operation = ExtendFootprintTTLOperationBuilder(extendTo).build();

      expect(operation.extendTo, equals(extendTo));
      expect(operation.sourceAccount, isNull);
    });

    test('build with source account', () {
      final sourceKeyPair = KeyPair.random();
      final extendTo = 150000;

      final operation = ExtendFootprintTTLOperationBuilder(extendTo)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      expect(operation.extendTo, equals(extendTo));
      expect(operation.sourceAccount, isNotNull);
      expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('build with muxed source account', () {
      final sourceKeyPair = KeyPair.random();
      final muxedAccount = MuxedAccount.fromAccountId(sourceKeyPair.accountId)!;
      final extendTo = 100000;

      final operation = ExtendFootprintTTLOperationBuilder(extendTo)
          .setMuxedSourceAccount(muxedAccount)
          .build();

      expect(operation.sourceAccount, equals(muxedAccount));
    });

    test('builder method chaining', () {
      final sourceKeyPair = KeyPair.random();
      final extendTo = 50000;

      final operation = ExtendFootprintTTLOperationBuilder(extendTo)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      expect(operation.extendTo, equals(extendTo));
      expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('extend with muxed source account edge case', () {
      final sourceKeyPair = KeyPair.random();
      final muxedAccount =
          MuxedAccount.fromAccountId(sourceKeyPair.accountId)!;
      final extendTo = 100000;

      final operation = ExtendFootprintTTLOperationBuilder(extendTo)
          .setMuxedSourceAccount(muxedAccount)
          .build();

      expect(operation.sourceAccount, equals(muxedAccount));
      expect(operation.extendTo, equals(extendTo));
    });
  });

  group('RestoreFootprintOperation', () {
    test('create restore footprint operation', () {
      final operation = RestoreFootprintOperation();

      expect(operation, isNotNull);
      expect(operation, isA<RestoreFootprintOperation>());
    });

    test('convert restore to XDR', () {
      final operation = RestoreFootprintOperation();

      final xdrBody = operation.toOperationBody();

      expect(xdrBody.discriminant, equals(XdrOperationType.RESTORE_FOOTPRINT));
      expect(xdrBody.restoreFootprintOp, isNotNull);
      expect(xdrBody.restoreFootprintOp!.ext.discriminant, equals(0));
    });

    test('create from XDR builder', () {
      final operation = RestoreFootprintOperation();
      final xdrBody = operation.toOperationBody();

      final builder = RestoreFootprintOperation.builder(xdrBody.restoreFootprintOp!);
      final rebuilt = builder.build();

      expect(rebuilt, isA<RestoreFootprintOperation>());
    });

    test('operation XDR has correct ext discriminant', () {
      final operation = RestoreFootprintOperation();
      final xdrBody = operation.toOperationBody();

      expect(xdrBody.restoreFootprintOp, isNotNull);
      expect(xdrBody.restoreFootprintOp!.ext.discriminant, equals(0));
    });
  });

  group('RestoreFootprintOperationBuilder', () {
    test('build restore footprint operation', () {
      final operation = RestoreFootprintOperationBuilder().build();

      expect(operation, isA<RestoreFootprintOperation>());
      expect(operation.sourceAccount, isNull);
    });

    test('build with source account', () {
      final sourceKeyPair = KeyPair.random();

      final operation = RestoreFootprintOperationBuilder()
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      expect(operation.sourceAccount, isNotNull);
      expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('build with muxed source account', () {
      final sourceKeyPair = KeyPair.random();
      final muxedAccount = MuxedAccount.fromAccountId(sourceKeyPair.accountId)!;

      final operation = RestoreFootprintOperationBuilder()
          .setMuxedSourceAccount(muxedAccount)
          .build();

      expect(operation.sourceAccount, equals(muxedAccount));
    });

    test('builder method chaining', () {
      final sourceKeyPair = KeyPair.random();

      final operation = RestoreFootprintOperationBuilder()
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      expect(operation.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('restore with muxed source account edge case', () {
      final sourceKeyPair = KeyPair.random();
      final muxedAccount =
          MuxedAccount.fromAccountId(sourceKeyPair.accountId)!;

      final operation = RestoreFootprintOperationBuilder()
          .setMuxedSourceAccount(muxedAccount)
          .build();

      expect(operation.sourceAccount, equals(muxedAccount));
    });
  });

  group('XDR Round-trip Tests', () {
    test('upload wasm complete round-trip', () {
      final sourceKeyPair = KeyPair.random();
      final wasmBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes);

      final operation = InvokeHostFuncOpBuilder(uploadFunction)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      final xdrBody = operation.toOperationBody();
      final builder = InvokeHostFunctionOperation.builder(xdrBody.invokeHostFunctionOp!);
      final rebuilt = builder.build();

      expect(rebuilt.function, isA<UploadContractWasmHostFunction>());
      final rebuiltFunc = rebuilt.function as UploadContractWasmHostFunction;
      expect(rebuiltFunc.contractCode, equals(wasmBytes));
    });

    test('create contract complete round-trip', () {
      final sourceKeyPair = KeyPair.random();
      final address = Address.forAccountId(KeyPair.random().accountId);
      final wasmId = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      final salt = XdrUint256(Uint8List.fromList(List.generate(32, (i) => i * 3)));

      final createFunction = CreateContractHostFunction(address, wasmId, salt: salt);
      final operation = InvokeHostFuncOpBuilder(createFunction)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      final xdrBody = operation.toOperationBody();
      final builder = InvokeHostFunctionOperation.builder(xdrBody.invokeHostFunctionOp!);
      final rebuilt = builder.build();

      expect(rebuilt.function, isA<CreateContractHostFunction>());
      final rebuiltFunc = rebuilt.function as CreateContractHostFunction;
      expect(rebuiltFunc.wasmId, equals(wasmId));
      expect(rebuiltFunc.salt.uint256, equals(salt.uint256));
    });

    test('extend footprint TTL complete round-trip', () {
      final sourceKeyPair = KeyPair.random();
      final extendTo = 123456;

      final operation = ExtendFootprintTTLOperationBuilder(extendTo)
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      final xdrBody = operation.toOperationBody();
      final builder = ExtendFootprintTTLOperation.builder(xdrBody.bumpExpirationOp!);
      final rebuilt = builder.setSourceAccount(sourceKeyPair.accountId).build();

      expect(rebuilt.extendTo, equals(extendTo));
      expect(rebuilt.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });

    test('restore footprint complete round-trip', () {
      final sourceKeyPair = KeyPair.random();

      final operation = RestoreFootprintOperationBuilder()
          .setSourceAccount(sourceKeyPair.accountId)
          .build();

      final xdrBody = operation.toOperationBody();
      final builder = RestoreFootprintOperation.builder(xdrBody.restoreFootprintOp!);
      final rebuilt = builder.setSourceAccount(sourceKeyPair.accountId).build();

      expect(rebuilt, isA<RestoreFootprintOperation>());
      expect(rebuilt.sourceAccount!.ed25519AccountId, equals(sourceKeyPair.accountId));
    });
  });
}
