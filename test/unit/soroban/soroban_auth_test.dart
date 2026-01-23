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

  group('Address - additional coverage', () {
    test('forClaimableBalanceId creates address with balance ID', () {
      final balanceId =
          '000000006d6f6e657900000000000000000000000000000000000000000000000000000000';
      final address = Address.forClaimableBalanceId(balanceId);

      expect(address.type, equals(Address.TYPE_CLAIMABLE_BALANCE));
      expect(address.claimableBalanceId, equals(balanceId));
      expect(address.accountId, isNull);
      expect(address.contractId, isNull);
    });

    test('forLiquidityPoolId creates address with pool ID', () {
      final poolId =
          'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
      final address = Address.forLiquidityPoolId(poolId);

      expect(address.type, equals(Address.TYPE_LIQUIDITY_POOL));
      expect(address.liquidityPoolId, equals(poolId));
      expect(address.accountId, isNull);
      expect(address.contractId, isNull);
    });

    test('claimable balance address toXdr and fromXdr', () {
      final balanceId =
          '000000006d6f6e657900000000000000000000000000000000000000000000000000000000';
      final address = Address.forClaimableBalanceId(balanceId);

      final xdr = address.toXdr();
      expect(xdr.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_CLAIMABLE_BALANCE));

      final restored = Address.fromXdr(xdr);
      expect(restored.type, equals(Address.TYPE_CLAIMABLE_BALANCE));
      expect(restored.claimableBalanceId, isNotNull);
    });

    test('liquidity pool address toXdr and fromXdr', () {
      final poolId =
          'dd7b1ab831c273310ddbec6f97870aa83c2fbd78ce22aded37ecbf4f3380fac7';
      final address = Address.forLiquidityPoolId(poolId);

      final xdr = address.toXdr();
      expect(xdr.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_LIQUIDITY_POOL));

      final restored = Address.fromXdr(xdr);
      expect(restored.type, equals(Address.TYPE_LIQUIDITY_POOL));
      expect(restored.liquidityPoolId, isNotNull);
    });

    test('muxed account address toXdr handles conversion', () {
      final muxedId =
          'MAAAAAAAAAAAJURAAB2X52XFQP6FBXLGT6LWOOWMEXWHEWBDVRZ7V5WH34Y22MPFBHUHY';
      final address = Address.forMuxedAccountId(muxedId);

      final xdr = address.toXdr();
      expect(xdr.discriminant,
          equals(XdrSCAddressType.SC_ADDRESS_TYPE_MUXED_ACCOUNT));
    });

  });

  group('SorobanAddressCredentials - deep', () {
    test('creates credentials with all fields', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final nonce = BigInt.from(12345);
      final expiration = 67890;
      final signature = XdrSCVal.forVoid();

      final credentials =
          SorobanAddressCredentials(address, nonce, expiration, signature);

      expect(credentials.address, equals(address));
      expect(credentials.nonce, equals(nonce));
      expect(credentials.signatureExpirationLedger, equals(expiration));
      expect(credentials.signature, equals(signature));
    });

    test('toXdr and fromXdr round trip', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final nonce = BigInt.from(98765);
      final expiration = 100000;
      final signature = XdrSCVal.forVoid();

      final credentials =
          SorobanAddressCredentials(address, nonce, expiration, signature);
      final xdr = credentials.toXdr();
      final restored = SorobanAddressCredentials.fromXdr(xdr);

      expect(restored.nonce, equals(nonce));
      expect(restored.signatureExpirationLedger, equals(expiration));
      expect(restored.address.accountId, equals(address.accountId));
    });

    test('fromXdr converts XDR correctly', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final nonce = BigInt.from(54321);
      final expiration = 90000;
      final signature = XdrSCVal.forVoid();

      final original =
          SorobanAddressCredentials(address, nonce, expiration, signature);
      final xdr = original.toXdr();

      expect(xdr.nonce.int64, equals(nonce));
      expect(xdr.signatureExpirationLedger.uint32, equals(expiration));
    });
  });

  group('SorobanCredentials - deep', () {
    test('forSourceAccount creates credentials without address', () {
      final credentials = SorobanCredentials.forSourceAccount();

      expect(credentials.addressCredentials, isNull);
    });

    test('forAddress creates credentials with address', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final nonce = BigInt.from(11111);
      final expiration = 22222;
      final signature = XdrSCVal.forVoid();

      final credentials =
          SorobanCredentials.forAddress(address, nonce, expiration, signature);

      expect(credentials.addressCredentials, isNotNull);
      expect(credentials.addressCredentials!.address, equals(address));
      expect(credentials.addressCredentials!.nonce, equals(nonce));
    });

    test('forAddressCredentials wraps address credentials', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final addressCreds = SorobanAddressCredentials(
          address, BigInt.from(333), 444, XdrSCVal.forVoid());

      final credentials =
          SorobanCredentials.forAddressCredentials(addressCreds);

      expect(credentials.addressCredentials, equals(addressCreds));
    });

    test('toXdr for source account credentials', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final xdr = credentials.toXdr();

      expect(xdr.type,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT));
      expect(xdr.address, isNull);
    });

    test('toXdr for address credentials', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final credentials = SorobanCredentials.forAddress(
          address, BigInt.from(555), 666, XdrSCVal.forVoid());

      final xdr = credentials.toXdr();

      expect(xdr.type,
          equals(XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS));
      expect(xdr.address, isNotNull);
    });

    test('fromXdr for source account', () {
      final xdr = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);

      final credentials = SorobanCredentials.fromXdr(xdr);

      expect(credentials.addressCredentials, isNull);
    });

    test('fromXdr for address credentials', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final addressCreds = SorobanAddressCredentials(
          address, BigInt.from(777), 888, XdrSCVal.forVoid());

      final xdr = XdrSorobanCredentials(
          XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
      xdr.address = addressCreds.toXdr();

      final credentials = SorobanCredentials.fromXdr(xdr);

      expect(credentials.addressCredentials, isNotNull);
      expect(credentials.addressCredentials!.nonce, equals(BigInt.from(777)));
    });
  });

  group('SorobanAuthorizedFunction - deep', () {
    test('forContractFunction creates function', () {
      final contractAddress =
          Address.forContractId(generateValidContractId());
      final functionName = 'transfer';
      final args = [
        XdrSCVal.forI32(100),
        XdrSCVal.forSymbol('test')
      ];

      final function = SorobanAuthorizedFunction.forContractFunction(
          contractAddress, functionName, args);

      expect(function.contractFn, isNotNull);
      expect(function.contractFn!.functionName, equals(functionName));
      expect(function.contractFn!.args.length, equals(2));
      expect(function.createContractHostFn, isNull);
      expect(function.createContractV2HostFn, isNull);
    });

    test('forCreateContractHostFunction creates function', () {
      final createArgs = XdrCreateContractArgs(
          XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS),
          XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM));

      final function =
          SorobanAuthorizedFunction.forCreateContractHostFunction(createArgs);

      expect(function.createContractHostFn, isNotNull);
      expect(function.contractFn, isNull);
      expect(function.createContractV2HostFn, isNull);
    });

    test('forCreateContractV2HostFunction creates function', () {
      final createArgs = XdrCreateContractArgsV2(
          XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS),
          XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM),
          []);

      final function =
          SorobanAuthorizedFunction.forCreateContractV2HostFunction(createArgs);

      expect(function.createContractV2HostFn, isNotNull);
      expect(function.contractFn, isNull);
      expect(function.createContractHostFn, isNull);
    });

    test('constructor throws when all parameters are null', () {
      expect(() => SorobanAuthorizedFunction(), throwsA(isA<ArgumentError>()));
    });

    test('toXdr for contract function', () {
      final contractAddress =
          Address.forContractId(generateValidContractId());
      final function = SorobanAuthorizedFunction.forContractFunction(
          contractAddress, 'approve', [XdrSCVal.forI32(1000)]);

      final xdr = function.toXdr();

      expect(xdr.type,
          equals(XdrSorobanAuthorizedFunctionType.SOROBAN_AUTHORIZED_FUNCTION_TYPE_CONTRACT_FN));
      expect(xdr.contractFn, isNotNull);
    });

    test('toXdr for create contract host function', () {
      final createArgs = XdrCreateContractArgs(
          XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS),
          XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM));

      final function =
          SorobanAuthorizedFunction.forCreateContractHostFunction(createArgs);
      final xdr = function.toXdr();

      expect(
          xdr.type,
          equals(XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_HOST_FN));
      expect(xdr.createContractHostFn, isNotNull);
    });

    test('toXdr for create contract v2 host function', () {
      final createArgs = XdrCreateContractArgsV2(
          XdrContractIDPreimage(XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS),
          XdrContractExecutable(XdrContractExecutableType.CONTRACT_EXECUTABLE_WASM),
          []);

      final function =
          SorobanAuthorizedFunction.forCreateContractV2HostFunction(createArgs);
      final xdr = function.toXdr();

      expect(
          xdr.type,
          equals(XdrSorobanAuthorizedFunctionType
              .SOROBAN_AUTHORIZED_FUNCTION_TYPE_CREATE_CONTRACT_V2_HOST_FN));
      expect(xdr.createContractV2HostFn, isNotNull);
    });

    test('fromXdr for contract function', () {
      final contractAddress =
          Address.forContractId(generateValidContractId());
      final original = SorobanAuthorizedFunction.forContractFunction(
          contractAddress, 'balance', []);

      final xdr = original.toXdr();
      final restored = SorobanAuthorizedFunction.fromXdr(xdr);

      expect(restored.contractFn, isNotNull);
      expect(restored.contractFn!.functionName, equals('balance'));
    });
  });

  group('SorobanAuthorizedInvocation - deep', () {
    test('creates invocation without sub-invocations', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'test_func',
          []);

      final invocation = SorobanAuthorizedInvocation(function);

      expect(invocation.function, equals(function));
      expect(invocation.subInvocations.length, equals(0));
    });

    test('creates invocation with sub-invocations', () {
      final mainFunction = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'main_func',
          []);

      final subFunction = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'sub_func',
          []);

      final subInvocation = SorobanAuthorizedInvocation(subFunction);
      final mainInvocation = SorobanAuthorizedInvocation(mainFunction,
          subInvocations: [subInvocation]);

      expect(mainInvocation.function, equals(mainFunction));
      expect(mainInvocation.subInvocations.length, equals(1));
      expect(mainInvocation.subInvocations[0], equals(subInvocation));
    });

    test('toXdr and fromXdr round trip', () {
      final function = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'round_trip',
          [XdrSCVal.forI32(42)]);

      final invocation = SorobanAuthorizedInvocation(function);
      final xdr = invocation.toXdr();
      final restored = SorobanAuthorizedInvocation.fromXdr(xdr);

      expect(restored.function.contractFn, isNotNull);
      expect(
          restored.function.contractFn!.functionName, equals('round_trip'));
      expect(restored.subInvocations.length, equals(0));
    });

    test('toXdr includes sub-invocations', () {
      final mainFunction = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()), 'main', []);

      final subFunction = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()), 'sub', []);

      final subInvocation = SorobanAuthorizedInvocation(subFunction);
      final mainInvocation = SorobanAuthorizedInvocation(mainFunction,
          subInvocations: [subInvocation]);

      final xdr = mainInvocation.toXdr();

      expect(xdr.subInvocations.length, equals(1));
    });

    test('fromXdr restores sub-invocations', () {
      final mainFunction = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()), 'parent', []);

      final subFunction1 = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()), 'child1', []);

      final subFunction2 = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()), 'child2', []);

      final subInv1 = SorobanAuthorizedInvocation(subFunction1);
      final subInv2 = SorobanAuthorizedInvocation(subFunction2);
      final mainInvocation = SorobanAuthorizedInvocation(mainFunction,
          subInvocations: [subInv1, subInv2]);

      final xdr = mainInvocation.toXdr();
      final restored = SorobanAuthorizedInvocation.fromXdr(xdr);

      expect(restored.subInvocations.length, equals(2));
      expect(restored.subInvocations[0].function.contractFn!.functionName,
          equals('child1'));
      expect(restored.subInvocations[1].function.contractFn!.functionName,
          equals('child2'));
    });
  });

  group('SorobanAuthorizationEntry - deep', () {
    test('creates authorization entry', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'authorize',
          []);
      final invocation = SorobanAuthorizedInvocation(function);

      final entry = SorobanAuthorizationEntry(credentials, invocation);

      expect(entry.credentials, equals(credentials));
      expect(entry.rootInvocation, equals(invocation));
    });

    test('toXdr and fromXdr round trip', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'execute',
          []);
      final invocation = SorobanAuthorizedInvocation(function);

      final entry = SorobanAuthorizationEntry(credentials, invocation);
      final xdr = entry.toXdr();
      final restored = SorobanAuthorizationEntry.fromXdr(xdr);

      expect(restored.credentials.addressCredentials, isNull);
      expect(restored.rootInvocation.function.contractFn, isNotNull);
    });

    test('toBase64EncodedXdrString and fromBase64EncodedXdr', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'base64_test',
          []);
      final invocation = SorobanAuthorizedInvocation(function);

      final entry = SorobanAuthorizationEntry(credentials, invocation);
      final base64 = entry.toBase64EncodedXdrString();
      final restored = SorobanAuthorizationEntry.fromBase64EncodedXdr(base64);

      expect(restored.rootInvocation.function.contractFn!.functionName,
          equals('base64_test'));
    });

    test('sign throws exception when no address credentials', () {
      final credentials = SorobanCredentials.forSourceAccount();
      final function = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'sign_test',
          []);
      final invocation = SorobanAuthorizedInvocation(function);

      final entry = SorobanAuthorizationEntry(credentials, invocation);
      final signer = KeyPair.random();
      final network = Network.TESTNET;

      expect(() => entry.sign(signer, network), throwsException);
    });

    test('sign works with address credentials', () {
      final address = Address.forAccountId(
          'GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      final credentials = SorobanCredentials.forAddress(
          address, BigInt.from(123), 456, XdrSCVal.forVoid());

      final function = SorobanAuthorizedFunction.forContractFunction(
          Address.forContractId(generateValidContractId()),
          'sign_test',
          []);
      final invocation = SorobanAuthorizedInvocation(function);

      final entry = SorobanAuthorizationEntry(credentials, invocation);
      final signer = KeyPair.random();
      final network = Network.TESTNET;

      entry.sign(signer, network);

      // After signing, the signature should be updated
      expect(entry.credentials.addressCredentials!.signature.vec, isNotNull);
      expect(
          entry.credentials.addressCredentials!.signature.vec!.length, greaterThan(0));
    });
  });

  group('AccountEd25519Signature - deep', () {
    test('creates signature with public key and bytes', () {
      final keyPair = KeyPair.random();
      final signatureBytes = Uint8List(64);
      for (int i = 0; i < 64; i++) {
        signatureBytes[i] = i;
      }

      final signature =
          AccountEd25519Signature(keyPair.xdrPublicKey, signatureBytes);

      expect(signature.publicKey, isNotNull);
      expect(signature.signatureBytes, equals(signatureBytes));
    });

    test('toXdrSCVal creates map with public_key and signature', () {
      final keyPair = KeyPair.random();
      final signatureBytes = Uint8List(64);

      final signature =
          AccountEd25519Signature(keyPair.xdrPublicKey, signatureBytes);
      final scVal = signature.toXdrSCVal();

      expect(scVal.discriminant, equals(XdrSCValType.SCV_MAP));
      expect(scVal.map, isNotNull);
      expect(scVal.map!.length, equals(2));

      // Check for public_key entry
      final pkEntry = scVal.map!.firstWhere(
          (entry) => entry.key.sym == 'public_key');
      expect(pkEntry, isNotNull);
      expect(pkEntry.val.discriminant, equals(XdrSCValType.SCV_BYTES));

      // Check for signature entry
      final sigEntry = scVal.map!.firstWhere(
          (entry) => entry.key.sym == 'signature');
      expect(sigEntry, isNotNull);
      expect(sigEntry.val.discriminant, equals(XdrSCValType.SCV_BYTES));
    });

    test('signature bytes are correctly included in XDR', () {
      final keyPair = KeyPair.random();
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final paddedBytes = Uint8List(64);
      paddedBytes.setRange(0, 5, testBytes);

      final signature =
          AccountEd25519Signature(keyPair.xdrPublicKey, paddedBytes);
      final scVal = signature.toXdrSCVal();

      final sigEntry = scVal.map!.firstWhere(
          (entry) => entry.key.sym == 'signature');

      expect(sigEntry.val.bytes!.dataValue, equals(paddedBytes));
    });
  });
}
