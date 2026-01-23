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
  });

  group('DeploySACWithSourceAccountHostFunction', () {
    test('deploy SAC with source account and generated salt', () {
      final address = Address.forAccountId(KeyPair.random().accountId);

      final deploySACFunction = DeploySACWithSourceAccountHostFunction(address);

      expect(deploySACFunction.address, equals(address));
      expect(deploySACFunction.salt, isNotNull);
      expect(deploySACFunction.salt.uint256.length, equals(32));
    });

    test('deploy SAC with source account and provided salt', () {
      final address = Address.forAccountId(KeyPair.random().accountId);
      final salt = XdrUint256(Uint8List.fromList(List.filled(32, 0xAB)));

      final deploySACFunction = DeploySACWithSourceAccountHostFunction(address, salt: salt);

      expect(deploySACFunction.address, equals(address));
      expect(deploySACFunction.salt, equals(salt));
    });

    test('convert deploy SAC source account to XDR and back', () {
      final accountId = KeyPair.random().accountId;
      final address = Address.forAccountId(accountId);
      final salt = XdrUint256(Uint8List.fromList(List.generate(32, (i) => i + 100)));

      final deploySACFunction = DeploySACWithSourceAccountHostFunction(address, salt: salt);

      final xdr = deploySACFunction.toXdr();
      expect(xdr.type, equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT));
      expect(xdr.createContract, isNotNull);

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<DeploySACWithSourceAccountHostFunction>());
      final decodedDeploy = decoded as DeploySACWithSourceAccountHostFunction;
      expect(decodedDeploy.address.accountId, equals(accountId));
      expect(decodedDeploy.salt.uint256, equals(salt.uint256));
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
