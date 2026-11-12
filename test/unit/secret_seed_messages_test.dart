// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'secret_seed_variants.dart';

/// Returns the error [call] throws, synchronously or through its future.
Future<Object> errorOf(Object? Function() call) async {
  try {
    await call();
  } catch (e) {
    return e;
  }
  fail('no error thrown');
}

/// Returns the [FormatException] message [call] throws.
String formatMessageOf(void Function() call) {
  try {
    call();
  } on FormatException catch (e) {
    return e.message;
  }
  fail('no FormatException thrown');
}

/// A server that answers every contract load with a contract that has no
/// functions, so no call reaches the network.
class _EmptyContractServer extends SorobanServer {
  _EmptyContractServer() : super('https://rpc.test');

  @override
  Future<SorobanContractInfo?> loadContractInfoForContractId(
    String contractId,
  ) async => SorobanContractInfo(0, 0, [], {});
}

void main() {
  final variants = SeedVariants();
  final String account = KeyPair.random().accountId;
  final String contract = StrKey.encodeContractId(Uint8List(32));

  /// Checks that [call] throws a [T] whose text is [expected] for every seed
  /// variant, where [expected] gets the wording the site gives the variant,
  /// and that the text leaves the variant out.
  Future<void> expectEveryVariant<T>(
    Object? Function(String value) call,
    String Function(String value) expected,
  ) async {
    for (final MapEntry(key: name, value: value) in variants.all.entries) {
      final Object error = await errorOf(() => call(value));
      expect(error, isA<T>(), reason: name);
      expect(error.toString(), expected(value), reason: name);
      expect(error.toString(), leavesOut(value), reason: name);
    }
  }

  group('amounts and prices name a seed by its kind', () {
    test('Util.decimalStringToStroops', () async {
      await expectEveryVariant<Exception>(
        Util.decimalStringToStroops,
        (_) => 'Exception: Not a decimal amount: $seedWording',
      );
      expect(
        (await errorOf(() => Util.decimalStringToStroops('12abc'))).toString(),
        'Exception: Not a decimal amount: 12abc',
      );
    });

    test('an operation amount', () async {
      await expectEveryVariant<Exception>(
        (value) => PaymentOperationBuilder(
          account,
          Asset.NATIVE,
          value,
        ).build().toXdr(),
        (_) => 'Exception: Not a decimal amount: $seedWording',
      );
    });

    test('Price.fromString', () async {
      await expectEveryVariant<Exception>(
        Price.fromString,
        (_) => 'Exception: Not a decimal price: $seedWording',
      );
      expect(
        (await errorOf(() => Price.fromString('1.2.3'))).toString(),
        'Exception: Not a decimal price: 1.2.3',
      );
    });
  });

  group('address positions name a seed by its kind', () {
    test('XdrSCAddress.forAccountId and Address.toXdr', () async {
      await expectEveryVariant<Exception>(
        XdrSCAddress.forAccountId,
        (value) =>
            'Exception: invalid account id: ${variants.keyWording(value)}',
      );
      await expectEveryVariant<Exception>(
        (value) => Address.forAccountId(value).toXdrSCVal(),
        (value) =>
            'Exception: invalid account id: ${variants.keyWording(value)}',
      );
      expect(
        (await errorOf(() => XdrSCAddress.forAccountId('XYZ'))).toString(),
        'Exception: invalid account id: XYZ',
      );
    });

    test('XdrSCVal.forAddressStrKey', () async {
      await expectEveryVariant<Exception>(
        XdrSCVal.forAddressStrKey,
        (value) =>
            'Exception: Unknown StrKey address type: '
            '${variants.keyWording(value)}',
      );
      expect(
        (await errorOf(() => XdrSCVal.forAddressStrKey('XYZ'))).toString(),
        'Exception: Unknown StrKey address type: XYZ',
      );
    });

    test('MuxedContract stores the kind as the invalid value', () {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          () => MuxedContract(value, BigInt.one),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', 'contractId')
                .having(
                  (e) => e.invalidValue,
                  'invalidValue',
                  variants.keyWording(value),
                )
                .having((e) => e.toString(), 'text', leavesOut(value)),
          ),
          reason: name,
        );
      }
      expect(
        () => MuxedContract('XYZ', BigInt.one),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.invalidValue, 'invalidValue', 'XYZ')
              .having(
                (e) => e.message,
                'message',
                'Invalid input length, must be even.',
              ),
        ),
      );
    });

    test('SorobanAuthorizationEntry.sign forAddress', () async {
      final KeyPair signer = KeyPair.random();
      SorobanAuthorizationEntry entry() => SorobanAuthorizationEntry(
        SorobanCredentials.forAddressV2(
          SorobanAddressCredentials(
            Address.forAccountId(signer.accountId),
            BigInt.one,
            100,
            XdrSCVal.forVoid(),
          ),
        ),
        SorobanAuthorizedInvocation(
          SorobanAuthorizedFunction.forContractFunction(
            Address.forContractId(contract),
            'hello',
            [],
          ),
        ),
      );
      await expectEveryVariant<Exception>(
        (value) => entry().sign(signer, Network.TESTNET, forAddress: value),
        (value) =>
            'Exception: No node with address ${variants.keyWording(value)} '
            'found in this authorization entry',
      );
      expect(
        (await errorOf(
          () => entry().sign(signer, Network.TESTNET, forAddress: account),
        )).toString(),
        'Exception: No node with address $account found in this '
        'authorization entry',
      );
    });

    test('a delegate address', () async {
      final SorobanAuthorizationEntry base = SorobanAuthorizationEntry(
        SorobanCredentials.forAddressV2(
          SorobanAddressCredentials(
            Address.forAccountId(account),
            BigInt.one,
            100,
            XdrSCVal.forVoid(),
          ),
        ),
        SorobanAuthorizedInvocation(
          SorobanAuthorizedFunction.forContractFunction(
            Address.forContractId(contract),
            'hello',
            [],
          ),
        ),
      );
      await expectEveryVariant<ArgumentError>(
        (value) => SorobanAuthorizationEntry.withDelegates(base, [
          SorobanDelegateDescriptor(value),
        ], 100),
        (value) =>
            'Invalid argument(s): Invalid delegate address strkey (must start '
            'with G or C): ${variants.keyWording(value)}',
      );
      expect(
        (await errorOf(
          () => SorobanAuthorizationEntry.withDelegates(base, [
            SorobanDelegateDescriptor('XYZ'),
          ], 100),
        )).toString(),
        'Invalid argument(s): Invalid delegate address strkey (must start '
        'with G or C): XYZ',
      );
    });
  });

  group('pool and balance ids name a seed by its kind', () {
    String reasonFor(void Function() decode) => formatMessageOf(decode);

    test('RequestBuilder.claimableBalanceIdHorizonHex', () async {
      await expectEveryVariant<ArgumentError>(
        RequestBuilder.claimableBalanceIdHorizonHex,
        (value) =>
            'Invalid argument(s): invalid claimable balance id: '
            '${variants.keyWording(value)} '
            '(${reasonFor(() => XdrClaimableBalanceID.forId(value))})',
      );
      expect(
        (await errorOf(
          () => RequestBuilder.claimableBalanceIdHorizonHex('XYZ'),
        )).toString(),
        'Invalid argument(s): invalid claimable balance id: XYZ '
        '(${reasonFor(() => XdrClaimableBalanceID.forId('XYZ'))})',
      );
    });

    test('RequestBuilder.liquidityPoolIdHorizonHex', () async {
      await expectEveryVariant<ArgumentError>(
        RequestBuilder.liquidityPoolIdHorizonHex,
        (value) =>
            'Invalid argument(s): invalid liquidity pool id: '
            '${variants.keyWording(value)} '
            '(${reasonFor(() => Util.liquidityPoolIdToXdrHash(value))})',
      );
      expect(
        (await errorOf(
          () => RequestBuilder.liquidityPoolIdHorizonHex('XYZ'),
        )).toString(),
        'Invalid argument(s): invalid liquidity pool id: XYZ '
        '(Invalid input length, must be even.)',
      );
    });

    test('the liquidity pool deposit and withdraw operations', () async {
      Object deposit(String id) => LiquidityPoolDepositOperationBuilder(
        liquidityPoolId: id,
        maxAmountA: '1',
        maxAmountB: '1',
        minPrice: '1',
        maxPrice: '1',
      ).build().toOperationBody();
      Object withdraw(String id) => LiquidityPoolWithdrawOperationBuilder(
        liquidityPoolId: id,
        amount: '1',
        minAmountA: '1',
        minAmountB: '1',
      ).build().toOperationBody();
      for (final build in [deposit, withdraw]) {
        await expectEveryVariant<ArgumentError>(
          build,
          (value) =>
              'Invalid argument(s): invalid liquidity pool id: '
              '${variants.keyWording(value)} '
              '(${reasonFor(() => Util.liquidityPoolIdToXdrHash(value))})',
        );
        expect(
          (await errorOf(() => build('XYZ'))).toString(),
          'Invalid argument(s): invalid liquidity pool id: XYZ '
          '(Invalid input length, must be even.)',
        );
      }
    });
  });

  group('hex positions keep a seed out of the exception', () {
    test('Util.hexToBytes and the id encoders and decoders', () {
      final List<void Function(String)> calls = [
        Util.hexToBytes,
        StrKey.encodeContractIdHex,
        StrKey.encodeClaimableBalanceIdHex,
        StrKey.encodeLiquidityPoolIdHex,
        XdrSCAddress.forContractId,
        XdrSCAddress.forLiquidityPoolId,
        (value) => Address.forContractId(value).toXdr(),
        (value) => Util.hexIdToXdrHash(value, 'Contract id'),
      ];
      for (final call in calls) {
        for (final MapEntry(key: name, value: value) in variants.all.entries) {
          expect(
            () => call(value),
            throwsA(
              isA<FormatException>()
                  .having((e) => e.source, 'source', variants.keyWording(value))
                  .having((e) => e.toString(), 'text', leavesOut(value)),
            ),
            reason: name,
          );
        }
      }
    });

    test('keeps the source of any other invalid hex', () {
      expect(
        () => Util.hexToBytes('abc'),
        throwsA(
          isA<FormatException>()
              .having((e) => e.source, 'source', 'abc')
              .having((e) => e.offset, 'offset', 3)
              .having(
                (e) => e.message,
                'message',
                'Invalid input length, must be even.',
              ),
        ),
      );
      expect(Util.hexToBytes('ff0080'), Uint8List.fromList([255, 0, 128]));
    });

    test('an offer id', () {
      final Asset selling = Asset.NATIVE;
      final Asset buying = AssetTypeCreditAlphaNum4('USD', account);
      final List<Operation Function(String)> builds = [
        (id) => ManageBuyOfferOperationBuilder(
          selling,
          buying,
          '1',
          '1',
        ).setOfferId(id).build(),
        (id) => ManageSellOfferOperationBuilder(
          selling,
          buying,
          '1',
          '1',
        ).setOfferId(id).build(),
      ];
      for (final build in builds) {
        for (final MapEntry(key: name, value: value) in variants.all.entries) {
          expect(
            () => build(value).toOperationBody(),
            throwsA(
              isA<FormatException>()
                  .having((e) => e.message, 'message', 'Could not parse BigInt')
                  .having((e) => e.source, 'source', variants.keyWording(value))
                  .having((e) => e.toString(), 'text', leavesOut(value)),
            ),
            reason: name,
          );
        }
        expect(
          () => build('abc').toOperationBody(),
          throwsA(
            isA<FormatException>().having((e) => e.source, 'source', 'abc'),
          ),
        );
      }
    });
  });

  group('wrapped texts replace a seed', () {
    test('TxRep integers', () {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          formatMessageOf(() => XdrInt32.fromTxRep({'value': value}, 'value')),
          'Invalid integer for value: $seedWording',
          reason: name,
        );
      }
      expect(
        formatMessageOf(() => XdrInt32.fromTxRep({'value': '0xZZ'}, 'value')),
        'Invalid integer for value: 0xZZ',
      );
    });

    test('ContractSpecException messages', () {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          ContractSpecException.conversionFailed('got "$value"').message,
          'Conversion failed: got "$seedWording"',
          reason: name,
        );
      }
    });

    test('Federation.resolveStellarAddress sends no request', () async {
      final List<http.BaseRequest> requests = [];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('', 404);
      });
      await expectEveryVariant<Exception>(
        (value) => Federation.resolveStellarAddress(value, httpClient: client),
        (_) => 'Exception: invalid federation address: $seedWording',
      );
      for (final String address in ['alice', 'sam.example.com']) {
        expect(
          (await errorOf(
            () => Federation.resolveStellarAddress(address, httpClient: client),
          )).toString(),
          'Exception: invalid federation address: $address',
        );
      }
      expect(requests, isEmpty);
    });

    test('the pool share asset order', () async {
      final String issuer = KeyPair.random().accountId;
      await expectEveryVariant<Exception>(
        (value) => AssetTypePoolShare(
          assetA: AssetTypeCreditAlphaNum4('USD', value),
          assetB: AssetTypeCreditAlphaNum4('EUR', issuer),
        ),
        (_) =>
            'Exception: Assets are in wrong order: assetA USD:$seedWording '
            'sorts after assetB EUR:$issuer. Sort by: Native < AlphaNum4 < '
            'AlphaNum12, then by Code, then by the Issuer\'s raw public key '
            'bytes.',
      );
      expect(
        (await errorOf(
          () => AssetTypePoolShare(
            assetA: AssetTypeCreditAlphaNum4('USD', issuer),
            assetB: AssetTypeCreditAlphaNum4('EUR', issuer),
          ),
        )).toString(),
        'Exception: Assets are in wrong order: assetA USD:$issuer sorts after '
        'assetB EUR:$issuer. Sort by: Native < AlphaNum4 < AlphaNum12, then by '
        'Code, then by the Issuer\'s raw public key bytes.',
      );
    });
  });

  group('memos, method names and map keys keep a seed out of the error', () {
    test('Memo.fromStrings with an id', () async {
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        final Object parseError = await errorOf(() => BigInt.parse(value));
        expect(
          await errorOf(() => Memo.fromStrings(value, 'id')),
          isA<FormatException>()
              .having(
                (e) => e.message,
                'message',
                (parseError as FormatException).message,
              )
              .having((e) => e.source, 'source', variants.keyWording(value))
              .having((e) => e.toString(), 'text', leavesOut(value)),
          reason: name,
        );
      }
      final Object error = await errorOf(() => Memo.fromStrings('12x', 'id'));
      final Object parseError = await errorOf(() => BigInt.parse('12x'));
      expect(error.toString(), parseError.toString());
      expect((error as FormatException).source, '12x');
    });

    test('Memo.fromStrings with a hash or a return hash', () async {
      for (final String type in ['hash', 'return']) {
        for (final MapEntry(key: name, value: value) in variants.all.entries) {
          final Object error = await errorOf(
            () => Memo.fromStrings(value, type),
          );
          expect(error.toString(), leavesOut(value), reason: '$type, $name');
          if (error is FormatException) {
            expect(error.source, seedWording, reason: '$type, $name');
          } else {
            expect(error, isA<MemoTooLongException>(), reason: '$type, $name');
          }
        }
        for (final String value in [variants.missing, variants.extra]) {
          expect(
            await errorOf(() => Memo.fromStrings(value, type)),
            isA<FormatException>()
                .having(
                  (e) => e.message,
                  'message',
                  'Invalid length, must be multiple of four',
                )
                .having((e) => e.source, 'source', seedWording)
                .having((e) => e.offset, 'offset', isNull),
            reason: type,
          );
        }
        for (final String value in ['abc', 'Sab!']) {
          final Object error = await errorOf(
            () => Memo.fromStrings(value, type),
          );
          final Object decodeError = await errorOf(() => base64.decode(value));
          expect(error.toString(), decodeError.toString(), reason: type);
          expect(
            [(error as FormatException).source, error.offset],
            [value, (decodeError as FormatException).offset],
            reason: type,
          );
        }
      }
    });

    test('SorobanClient.buildInvokeMethodTx with an unknown method', () async {
      final SorobanClient client = await SorobanClient.forClientOptions(
        options: ClientOptions(
          sourceAccountKeyPair: KeyPair.random(),
          contractId: contract,
          network: Network.TESTNET,
          rpcUrl: 'https://rpc.test',
          server: _EmptyContractServer(),
        ),
      );
      await expectEveryVariant<Exception>(
        (value) => client.buildInvokeMethodTx(name: value),
        (_) => "Exception: Method '$seedWording' does not exist",
      );
      for (final String name in ['transfer', 'swap']) {
        expect(
          (await errorOf(
            () => client.buildInvokeMethodTx(name: name),
          )).toString(),
          "Exception: Method '$name' does not exist",
        );
      }
    });

    test('sortedScMap with a duplicate key', () async {
      List<XdrSCMapEntry> twice(XdrSCVal key) => [
        XdrSCMapEntry(key, XdrSCVal.forVoid()),
        XdrSCMapEntry(key, XdrSCVal.forVoid()),
      ];
      for (final MapEntry(key: name, value: value) in variants.all.entries) {
        expect(
          await errorOf(() => sortedScMap(twice(XdrSCVal.forString(value)))),
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'entries')
              .having((e) => e.message, 'message', 'Duplicate ScMap key')
              .having(
                (e) => e.invalidValue,
                'invalidValue',
                '{"string":"$seedWording"}',
              )
              .having((e) => e.toString(), 'text', leavesOut(value)),
          reason: name,
        );
      }
      for (final XdrSCVal key in [
        XdrSCVal.forString('alice'),
        XdrSCVal.forSymbol('Sym'),
      ]) {
        expect(
          await errorOf(() => sortedScMap(twice(key))),
          isA<ArgumentError>().having(
            (e) => e.invalidValue,
            'invalidValue',
            key.toXdrJson(),
          ),
        );
      }
    });
  });

  group('valid inputs behave as before', () {
    test('every changed function accepts its valid inputs', () {
      final KeyPair keyPair = KeyPair.random();
      final String muxed = MuxedAccount(
        keyPair.accountId,
        BigInt.from(7),
      ).accountId;
      final String muxedContract = MuxedContract(
        contract,
        BigInt.from(7),
      ).muxedContractId;
      final String pool = StrKey.encodeLiquidityPoolId(Uint8List(32));
      final String balance = StrKey.encodeClaimableBalanceId(Uint8List(33));

      expect(Util.decimalStringToStroops('100.5'), BigInt.from(1005000000));
      final Uint8List hashBytes = Uint8List(32)..[0] = 0x4a;
      final String hash = base64.encode(hashBytes);
      expect(hash[0], 'S');
      for (final String type in ['hash', 'return']) {
        expect(
          (Memo.fromStrings(hash, type) as MemoHashAbstract).bytes,
          hashBytes,
        );
      }
      expect(
        (Memo.fromStrings('987654321', 'id') as MemoId).getId(),
        BigInt.from(987654321),
      );
      expect(
        sortedScMap([
          XdrSCMapEntry(XdrSCVal.forString('b'), XdrSCVal.forVoid()),
          XdrSCMapEntry(XdrSCVal.forString('a'), XdrSCVal.forVoid()),
        ]).map!.map((e) => e.key.str),
        ['a', 'b'],
      );
      final Price price = Price.fromString('1.5');
      expect([price.n, price.d], [3, 2]);
      expect(
        XdrSCAddress.forAccountId(keyPair.accountId).toStrKey(),
        keyPair.accountId,
      );
      expect(XdrSCAddress.forAccountId(muxed).toStrKey(), muxed);
      for (final address in [
        keyPair.accountId,
        muxed,
        contract,
        muxedContract,
        pool,
        balance,
      ]) {
        expect(XdrSCVal.forAddressStrKey(address).address!.toStrKey(), address);
      }
      expect(MuxedContract(contract, BigInt.one).contractId, contract);
      expect(RequestBuilder.liquidityPoolIdHorizonHex(pool), '00' * 32);
      expect(RequestBuilder.claimableBalanceIdHorizonHex(balance), '00' * 36);
      expect(Util.hexIdToXdrHash('00' * 32, 'Contract id').hash, Uint8List(32));
      expect(
        ManageBuyOfferOperationBuilder(
              Asset.NATIVE,
              AssetTypeCreditAlphaNum4('USD', keyPair.accountId),
              '1',
              '1',
            )
            .setOfferId('12345')
            .build()
            .toOperationBody()
            .manageBuyOfferOp!
            .offerID
            .uint64,
        BigInt.from(12345),
      );
    });
  });
}
