import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  // Helper function to generate valid contract ID
  String generateValidContractId() {
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = i + 1; // Deterministic test data
    }
    return StrKey.encodeContractId(bytes);
  }

  group('Address', () {
    final validAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
    final validContractId = generateValidContractId();
    final validMuxedId = 'MAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY';

    test('create account address', () {
      final address = Address.forAccountId(validAccountId);

      expect(address, isNotNull);
      expect(address.type, equals(Address.TYPE_ACCOUNT));
      expect(address.accountId, equals(validAccountId));
      expect(address.contractId, isNull);
    });

    test('create contract address', () {
      final address = Address.forContractId(validContractId);

      expect(address, isNotNull);
      expect(address.type, equals(Address.TYPE_CONTRACT));
      expect(address.contractId, equals(validContractId));
      expect(address.accountId, isNull);
    });

    test('create muxed account address', () {
      final address = Address.forMuxedAccountId(validMuxedId);

      expect(address, isNotNull);
      expect(address.type, equals(Address.TYPE_MUXED_ACCOUNT));
      expect(address.muxedAccountId, equals(validMuxedId));
    });

    test('create claimable balance address', () {
      final balanceId = '000000006d6f6e657900000000000000000000000000000000000000000000000000000000';
      final address = Address.forClaimableBalanceId(balanceId);

      expect(address, isNotNull);
      expect(address.type, equals(Address.TYPE_CLAIMABLE_BALANCE));
      expect(address.claimableBalanceId, equals(balanceId));
    });

    test('create liquidity pool address', () {
      final poolId = 'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
      final address = Address.forLiquidityPoolId(poolId);

      expect(address, isNotNull);
      expect(address.type, equals(Address.TYPE_LIQUIDITY_POOL));
      expect(address.liquidityPoolId, equals(poolId));
    });

    test('account address toXdr and fromXdr', () {
      final address = Address.forAccountId(validAccountId);

      final xdr = address.toXdr();
      final restored = Address.fromXdr(xdr);

      expect(restored.type, equals(Address.TYPE_ACCOUNT));
      expect(restored.accountId, equals(validAccountId));
    });

    test('contract address toXdr and fromXdr', () {
      final address = Address.forContractId(validContractId);

      final xdr = address.toXdr();
      final restored = Address.fromXdr(xdr);

      expect(restored.type, equals(Address.TYPE_CONTRACT));
      expect(restored.contractId, isNotNull);
      // Contract ID from XDR is in hex format
      expect(restored.contractId!.length, equals(64));
    });

    test('address toXdrSCVal and fromXdrSCVal', () {
      final address = Address.forAccountId(validAccountId);

      final scVal = address.toXdrSCVal();
      final restored = Address.fromXdrSCVal(scVal);

      expect(scVal.discriminant, equals(XdrSCValType.SCV_ADDRESS));
      expect(restored.type, equals(Address.TYPE_ACCOUNT));
      expect(restored.accountId, equals(validAccountId));
    });

    test('invalid type throws exception', () {
      expect(
        () => Address(999),
        throwsException,
      );
    });

    test('account type requires accountId', () {
      expect(
        () => Address(Address.TYPE_ACCOUNT),
        throwsException,
      );
    });

    test('contract type requires contractId', () {
      expect(
        () => Address(Address.TYPE_CONTRACT),
        throwsException,
      );
    });
  });

  group('SorobanAddressCredentials', () {
    final validAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
    final address = Address.forAccountId(validAccountId);
    final nonce = BigInt.from(123456789);
    final expirationLedger = 1000000;
    final signature = XdrSCVal.forVoid();

    test('create address credentials', () {
      final credentials = SorobanAddressCredentials(
        address,
        nonce,
        expirationLedger,
        signature,
      );

      expect(credentials, isNotNull);
      expect(credentials.address, equals(address));
      expect(credentials.nonce, equals(nonce));
      expect(credentials.signatureExpirationLedger, equals(expirationLedger));
      expect(credentials.signature, equals(signature));
    });

    test('address credentials toXdr and fromXdr', () {
      final credentials = SorobanAddressCredentials(
        address,
        nonce,
        expirationLedger,
        signature,
      );

      final xdr = credentials.toXdr();
      final restored = SorobanAddressCredentials.fromXdr(xdr);

      expect(restored.address.accountId, equals(validAccountId));
      expect(restored.nonce, equals(nonce));
      expect(restored.signatureExpirationLedger, equals(expirationLedger));
    });

    test('credentials with large nonce', () {
      final largeNonce = BigInt.parse('9223372036854775807');
      final credentials = SorobanAddressCredentials(
        address,
        largeNonce,
        expirationLedger,
        signature,
      );

      final xdr = credentials.toXdr();
      final restored = SorobanAddressCredentials.fromXdr(xdr);

      expect(restored.nonce, equals(largeNonce));
    });
  });

  group('SorobanCredentials', () {
    final validAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
    final address = Address.forAccountId(validAccountId);
    final nonce = BigInt.from(123456789);
    final expirationLedger = 1000000;
    final signature = XdrSCVal.forVoid();

    test('create source account credentials', () {
      final credentials = SorobanCredentials.forSourceAccount();

      expect(credentials, isNotNull);
      expect(credentials.addressCredentials, isNull);
    });

    test('source account credentials toXdr', () {
      final credentials = SorobanCredentials.forSourceAccount();

      final xdr = credentials.toXdr();

      expect(xdr.type, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT));
      expect(xdr.address, isNull);
    });

    test('create address credentials', () {
      final credentials = SorobanCredentials.forAddress(
        address,
        nonce,
        expirationLedger,
        signature,
      );

      expect(credentials, isNotNull);
      expect(credentials.addressCredentials, isNotNull);
      expect(credentials.addressCredentials!.address, equals(address));
      expect(credentials.addressCredentials!.nonce, equals(nonce));
    });

    test('address credentials toXdr', () {
      final credentials = SorobanCredentials.forAddress(
        address,
        nonce,
        expirationLedger,
        signature,
      );

      final xdr = credentials.toXdr();

      expect(xdr.type, equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS));
      expect(xdr.address, isNotNull);
    });

    test('credentials toXdr and fromXdr round-trip', () {
      final credentials = SorobanCredentials.forAddress(
        address,
        nonce,
        expirationLedger,
        signature,
      );

      final xdr = credentials.toXdr();
      final restored = SorobanCredentials.fromXdr(xdr);

      expect(restored.addressCredentials, isNotNull);
      expect(restored.addressCredentials!.nonce, equals(nonce));
      expect(restored.addressCredentials!.signatureExpirationLedger, equals(expirationLedger));
    });

    test('forAddressCredentials constructor', () {
      final addressCreds = SorobanAddressCredentials(
        address,
        nonce,
        expirationLedger,
        signature,
      );
      final credentials = SorobanCredentials.forAddressCredentials(addressCreds);

      expect(credentials.addressCredentials, equals(addressCreds));
    });
  });

  group('SorobanAuthorizedFunction', () {
    final validContractId = generateValidContractId();
    final contractAddress = Address.forContractId(validContractId);

    test('create contract function', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'transfer',
        [XdrSCVal.forI32(100)],
      );

      expect(function, isNotNull);
      expect(function.contractFn, isNotNull);
      expect(function.contractFn!.functionName, equals('transfer'));
      expect(function.contractFn!.args.length, equals(1));
      expect(function.createContractHostFn, isNull);
      expect(function.createContractV2HostFn, isNull);
    });

    test('contract function toXdr', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'approve',
        [XdrSCVal.forU64(BigInt.from(1000))],
      );

      final xdr = function.toXdr();

      expect(xdr.type, equals(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN));
      expect(xdr.contractFn, isNotNull);
      expect(xdr.contractFn!.functionName, equals('approve'));
    });

    test('contract function with empty args', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'initialize',
        [],
      );

      expect(function.contractFn!.args, isEmpty);
    });

    test('create contract host function', () {
      final createArgs = XdrCreateContractArgs(
        XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS),
        XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM),
      );

      final function = SorobanAuthorizedFunction.forCreateContractHostFunction(createArgs);

      expect(function, isNotNull);
      expect(function.createContractHostFn, equals(createArgs));
      expect(function.contractFn, isNull);
      expect(function.createContractV2HostFn, isNull);
    });

    test('create contract v2 host function', () {
      final createV2Args = XdrCreateContractArgsV2(
        XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS),
        XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM),
        [],
      );

      final function = SorobanAuthorizedFunction.forCreateContractV2HostFunction(createV2Args);

      expect(function, isNotNull);
      expect(function.createContractV2HostFn, equals(createV2Args));
      expect(function.contractFn, isNull);
      expect(function.createContractHostFn, isNull);
    });

    test('invalid construction without arguments throws', () {
      expect(
        () => SorobanAuthorizedFunction(),
        throwsArgumentError,
      );
    });

    test('authorized function toXdr and fromXdr', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'transfer',
        [XdrSCVal.forU32(100)],
      );

      final xdr = function.toXdr();
      final restored = SorobanAuthorizedFunction.fromXdr(xdr);

      expect(restored.contractFn, isNotNull);
      expect(restored.contractFn!.functionName, equals('transfer'));
      expect(restored.contractFn!.args.length, equals(1));
    });
  });

  group('SorobanAuthorizedInvocation', () {
    final validContractId = generateValidContractId();
    final contractAddress = Address.forContractId(validContractId);

    test('create invocation without sub-invocations', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'transfer',
        [XdrSCVal.forI32(100)],
      );
      final invocation = SorobanAuthorizedInvocation(function);

      expect(invocation, isNotNull);
      expect(invocation.function, equals(function));
      expect(invocation.subInvocations, isEmpty);
    });

    test('create invocation with sub-invocations', () {
      final mainFunction = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'transfer',
        [XdrSCVal.forI32(100)],
      );
      final subFunction = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'check_balance',
        [],
      );
      final subInvocation = SorobanAuthorizedInvocation(subFunction);

      final invocation = SorobanAuthorizedInvocation(
        mainFunction,
        subInvocations: [subInvocation],
      );

      expect(invocation.subInvocations.length, equals(1));
      expect(invocation.subInvocations[0].function, equals(subFunction));
    });

    test('invocation with multiple sub-invocations', () {
      final mainFunction = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'swap',
        [],
      );
      final sub1 = SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.forContractFunction(
          contractAddress,
          'approve',
          [],
        ),
      );
      final sub2 = SorobanAuthorizedInvocation(
        SorobanAuthorizedFunction.forContractFunction(
          contractAddress,
          'transfer',
          [],
        ),
      );

      final invocation = SorobanAuthorizedInvocation(
        mainFunction,
        subInvocations: [sub1, sub2],
      );

      expect(invocation.subInvocations.length, equals(2));
    });

    test('invocation toXdr and fromXdr', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'test_method',
        [XdrSCVal.forSymbol('test')],
      );
      final invocation = SorobanAuthorizedInvocation(function);

      final xdr = invocation.toXdr();
      final restored = SorobanAuthorizedInvocation.fromXdr(xdr);

      expect(restored.function.contractFn!.functionName, equals('test_method'));
      expect(restored.subInvocations, isEmpty);
    });

    test('nested invocation tree serialization', () {
      final rootFunction = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'root',
        [],
      );
      final childFunction = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'child',
        [],
      );
      final grandchildFunction = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'grandchild',
        [],
      );

      final grandchildInvocation = SorobanAuthorizedInvocation(grandchildFunction);
      final childInvocation = SorobanAuthorizedInvocation(
        childFunction,
        subInvocations: [grandchildInvocation],
      );
      final rootInvocation = SorobanAuthorizedInvocation(
        rootFunction,
        subInvocations: [childInvocation],
      );

      final xdr = rootInvocation.toXdr();
      final restored = SorobanAuthorizedInvocation.fromXdr(xdr);

      expect(restored.subInvocations.length, equals(1));
      expect(restored.subInvocations[0].subInvocations.length, equals(1));
      expect(
        restored.subInvocations[0].subInvocations[0].function.contractFn!.functionName,
        equals('grandchild'),
      );
    });
  });

  group('SorobanAuthorizationEntry', () {
    final validAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
    final validContractId = generateValidContractId();
    final address = Address.forAccountId(validAccountId);
    final contractAddress = Address.forContractId(validContractId);

    test('create authorization entry with source account credentials', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'transfer',
        [],
      );
      final invocation = SorobanAuthorizedInvocation(function);
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      expect(entry, isNotNull);
      expect(entry.credentials.addressCredentials, isNull);
      expect(entry.rootInvocation, equals(invocation));
    });

    test('create authorization entry with address credentials', () {
      final credentials = SorobanCredentials.forAddress(
        address,
        BigInt.from(123456),
        1000000,
        XdrSCVal.forVoid(),
      );
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'approve',
        [],
      );
      final invocation = SorobanAuthorizedInvocation(function);
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      expect(entry.credentials.addressCredentials, isNotNull);
      expect(entry.credentials.addressCredentials!.nonce, equals(BigInt.from(123456)));
    });

    test('authorization entry toXdr and fromXdr', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'test',
        [],
      );
      final invocation = SorobanAuthorizedInvocation(function);
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      final xdr = entry.toXdr();
      final restored = SorobanAuthorizationEntry.fromXdr(xdr);

      expect(restored.credentials.addressCredentials, isNull);
      expect(restored.rootInvocation.function.contractFn!.functionName, equals('test'));
    });

    test('authorization entry base64 encoding', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'method',
        [XdrSCVal.forU32(42)],
      );
      final invocation = SorobanAuthorizedInvocation(function);
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      final base64Xdr = entry.toBase64EncodedXdrString();
      final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(base64Xdr);

      expect(restored.rootInvocation.function.contractFn!.functionName, equals('method'));
    });

    test('sign authorization entry', () {
      final signer = KeyPair.random();
      final credentials = SorobanCredentials.forAddress(
        Address.forAccountId(signer.accountId),
        BigInt.from(999),
        2000000,
        XdrSCVal.forVoid(),
      );
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'transfer',
        [],
      );
      final invocation = SorobanAuthorizedInvocation(function);
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      entry.sign(signer, Network.TESTNET);

      expect(entry.credentials.addressCredentials!.signature.vec, isNotNull);
      expect(entry.credentials.addressCredentials!.signature.vec!.length, equals(1));
    });

    test('sign authorization entry throws without address credentials', () {
      final signer = KeyPair.random();
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'transfer',
        [],
      );
      final invocation = SorobanAuthorizedInvocation(function);
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      expect(
        () => entry.sign(signer, Network.TESTNET),
        throwsException,
      );
    });

    test('multiple signatures on entry', () {
      final signer1 = KeyPair.random();
      final signer2 = KeyPair.random();
      final credentials = SorobanCredentials.forAddress(
        Address.forAccountId(signer1.accountId),
        BigInt.from(111),
        3000000,
        XdrSCVal.forVoid(),
      );
      final function = SorobanAuthorizedFunction.forContractFunction(
        contractAddress,
        'multi_sig',
        [],
      );
      final invocation = SorobanAuthorizedInvocation(function);
      final entry = SorobanAuthorizationEntry(credentials, invocation);

      entry.sign(signer1, Network.TESTNET);
      entry.sign(signer2, Network.TESTNET);

      expect(entry.credentials.addressCredentials!.signature.vec!.length, equals(2));
    });
  });

  group('AccountEd25519Signature', () {
    test('create ed25519 signature', () {
      final keyPair = KeyPair.random();
      final payload = Uint8List(32);
      final signatureBytes = keyPair.sign(payload);

      final signature = AccountEd25519Signature(keyPair.xdrPublicKey, signatureBytes);

      expect(signature, isNotNull);
      expect(signature.publicKey, isA<XdrPublicKey>());
      expect(signature.signatureBytes, equals(signatureBytes));
    });

    test('signature toXdrSCVal creates map', () {
      final keyPair = KeyPair.random();
      final signatureBytes = Uint8List.fromList(List.filled(64, 0));
      final signature = AccountEd25519Signature(keyPair.xdrPublicKey, signatureBytes);

      final scVal = signature.toXdrSCVal();

      expect(scVal.discriminant, equals(XdrSCValType.SCV_MAP));
      expect(scVal.map, isNotNull);
      expect(scVal.map!.length, equals(2));
    });

    test('signature map contains public_key and signature entries', () {
      final keyPair = KeyPair.random();
      final signatureBytes = Uint8List.fromList(List.filled(64, 1));
      final signature = AccountEd25519Signature(keyPair.xdrPublicKey, signatureBytes);

      final scVal = signature.toXdrSCVal();
      final map = scVal.map!;

      final keys = map.map((entry) => entry.key.sym).toList();
      expect(keys, contains('public_key'));
      expect(keys, contains('signature'));
    });

    test('signature with actual keypair signing', () {
      final keyPair = KeyPair.random();
      final payload = Util.hash(Uint8List.fromList('test payload'.codeUnits));
      final signatureBytes = keyPair.sign(payload);

      final signature = AccountEd25519Signature(keyPair.xdrPublicKey, signatureBytes);
      final scVal = signature.toXdrSCVal();

      expect(scVal.map, isNotNull);
      expect(scVal.map!.length, equals(2));
      expect(signatureBytes.length, equals(64));
    });
  });
}
