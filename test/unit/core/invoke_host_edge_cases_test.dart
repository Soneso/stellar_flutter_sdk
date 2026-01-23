import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'dart:typed_data';

void main() {
  group('HostFunction XDR Conversion Edge Cases', () {
    test('CreateContractWithConstructorHostFunction XDR roundtrip V2', () {
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

    test('DeploySACWithSourceAccountHostFunction XDR roundtrip V2', () {
      final accountId = KeyPair.random().accountId;
      final address = Address.forAccountId(accountId);
      final salt =
          XdrUint256(Uint8List.fromList(List.generate(32, (i) => i + 100)));

      final deploySACFunction =
          DeploySACWithSourceAccountHostFunction(address, salt: salt);

      final xdr = deploySACFunction.toXdr();
      expect(xdr.type,
          equals(XdrHostFunctionType.HOST_FUNCTION_TYPE_CREATE_CONTRACT));
      expect(xdr.createContract, isNotNull);
      expect(xdr.createContract!.contractIDPreimage.type,
          equals(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS));
      expect(xdr.createContract!.executable.type,
          equals(XdrContractExecutableType.CONTRACT_EXECUTABLE_STELLAR_ASSET));

      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<DeploySACWithSourceAccountHostFunction>());
      final decodedDeploy = decoded as DeploySACWithSourceAccountHostFunction;
      expect(decodedDeploy.address.accountId, equals(accountId));
      expect(decodedDeploy.salt.uint256, equals(salt.uint256));
    });

    test('DeploySACWithAssetHostFunction with AlphaNum12 XDR roundtrip', () {
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

    test('InvokeContractHostFunction with complex arguments', () {
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

    test('UploadContractWasmHostFunction with empty WASM', () {
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

    test('UploadContractWasmHostFunction with large WASM', () {
      final wasmBytes = Uint8List.fromList(List.generate(1000, (i) => i % 256));
      final uploadFunction = UploadContractWasmHostFunction(wasmBytes);

      expect(uploadFunction.contractCode.length, equals(1000));

      final xdr = uploadFunction.toXdr();
      final decoded = HostFunction.fromXdr(xdr);
      expect(decoded, isA<UploadContractWasmHostFunction>());
      final decodedUpload = decoded as UploadContractWasmHostFunction;
      expect(decodedUpload.contractCode, equals(wasmBytes));
    });

    test('CreateContractHostFunction modifies salt', () {
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

    test('InvokeContractHostFunction modifies arguments', () {
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

  group('InvokeHostFuncOpBuilder with Muxed Account', () {
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
  });

  group('ExtendFootprintTTLOperation Edge Cases', () {
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

    test('extend with muxed source account', () {
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

  group('RestoreFootprintOperation Edge Cases', () {
    test('restore with muxed source account', () {
      final sourceKeyPair = KeyPair.random();
      final muxedAccount =
          MuxedAccount.fromAccountId(sourceKeyPair.accountId)!;

      final operation = RestoreFootprintOperationBuilder()
          .setMuxedSourceAccount(muxedAccount)
          .build();

      expect(operation.sourceAccount, equals(muxedAccount));
    });

    test('restore operation XDR has correct ext discriminant', () {
      final operation = RestoreFootprintOperation();
      final xdrBody = operation.toOperationBody();

      expect(xdrBody.restoreFootprintOp, isNotNull);
      expect(xdrBody.restoreFootprintOp!.ext.discriminant, equals(0));
    });
  });

  group('Property Setters and Getters', () {
    test('CreateContractWithConstructorHostFunction setters', () {
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

    test('DeploySACWithSourceAccountHostFunction setters', () {
      final address1 = Address.forAccountId(KeyPair.random().accountId);
      final address2 = Address.forAccountId(KeyPair.random().accountId);
      final salt1 = XdrUint256(Uint8List.fromList(List.filled(32, 0x01)));
      final salt2 = XdrUint256(Uint8List.fromList(List.filled(32, 0x02)));

      final deploySACFunction =
          DeploySACWithSourceAccountHostFunction(address1, salt: salt1);

      expect(deploySACFunction.address, equals(address1));
      expect(deploySACFunction.salt.uint256, equals(salt1.uint256));

      deploySACFunction.address = address2;
      deploySACFunction.salt = salt2;

      expect(deploySACFunction.address, equals(address2));
      expect(deploySACFunction.salt.uint256, equals(salt2.uint256));
    });

    test('DeploySACWithAssetHostFunction setter', () {
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

    test('InvokeHostFuncOpBuilder function setter', () {
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
}
