import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../contract_bindings/bindings_spec_test_contract_client.dart';
import '../tests_util.dart';

/// Testnet integration test for the full-surface contract binding
/// (BindingsSpecTestContract), generated from the community bindings generator's
/// reference contract. It exercises the type-conversion paths the smaller
/// fixtures do not cover: i32, u64, i64, u128, i128, u256, i256, timepoint,
/// duration, bytes, string, map, vec, tuple, option, struct, union (including
/// an Address payload arm, a nested-union payload arm, and the RoyalCard
/// integer-discriminant enum), address, and Dart-keyword-escaped
/// method/parameter names.
///
/// The contract is deployed in-test from the checked-in wasm
/// (test/wasm/soroban_bindings_spec_test_contract.wasm), mirroring
/// soroban_client_test.dart. Lives under test/integration/, which CI does not
/// run; execute manually against testnet with:
///   flutter test test/integration/soroban_client_bindings_spec_test.dart
void main() {
  String testOn = 'testnet'; //'futurenet';
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  final rpcUrl = testOn == 'testnet'
      ? "https://soroban-testnet.stellar.org"
      : "https://rpc-futurenet.stellar.org";
  final SPEC_TEST_CONTRACT_PATH = 'test/wasm/soroban_bindings_spec_test_contract.wasm';

  final sourceAccountKeyPair = KeyPair.random();

  setUp(() async {
    if (testOn == 'testnet') {
      await FriendBot.fundTestAccount(sourceAccountKeyPair.accountId);
    } else {
      await FuturenetFriendBot.fundTestAccount(sourceAccountKeyPair.accountId);
    }
  });

  Future<String> installContract(String path) async {
    final contractCode = await loadContractCode(path);
    final installRequest = InstallRequest(
        wasmBytes: contractCode,
        sourceAccountKeyPair: sourceAccountKeyPair,
        network: network,
        rpcUrl: rpcUrl,
        enableSorobanServerLogging: true);
    return await SorobanClient.install(installRequest: installRequest);
  }

  Future<SorobanClient> deployContract(String wasmHash) async {
    final deployRequest = DeployRequest(
        sourceAccountKeyPair: sourceAccountKeyPair,
        network: network,
        rpcUrl: rpcUrl,
        wasmHash: wasmHash,
        enableSorobanServerLogging: true);
    return await SorobanClient.deploy(deployRequest: deployRequest);
  }

  test('test bindings spec contract full-surface round-trips with contract binding',
      timeout: Timeout(Duration(minutes: 5)), () async {
    final wasmHash = await installContract(SPEC_TEST_CONTRACT_PATH);
    print("Installed bindings spec test contract wasm hash: $wasmHash");

    final deployedClient = await deployContract(wasmHash);
    final contractId = deployedClient.getContractId();
    print("Deployed bindings spec test contract contract id: $contractId");

    final client = await BindingsSpecTestContract.forContractId(
      sourceAccountKeyPair: sourceAccountKeyPair,
      contractId: contractId,
      network: network,
      rpcUrl: rpcUrl,
      enableServerLogging: true,
    );
    assert(client.getContractId() == contractId);

    // u64: value above 2^53 to prove the BigInt path (unrepresentable as a
    // safe Dart/JS int).
    final u64In = BigInt.parse('12345678901234567890');
    final u64Out = await client.u64(u64: u64In);
    assert(u64Out == u64In);
    print("u64 round-trip: $u64Out");

    // i64: large negative value.
    final i64In = BigInt.parse('-9223372036854775808');
    final i64Out = await client.i64(i64: i64In);
    assert(i64Out == i64In);
    print("i64 round-trip: $i64Out");

    // i32: minimum signed 32-bit value (-2^31), exercising the SCV_I32 path
    // at the negative extreme.
    final i32In = -2147483648;
    final i32Out = await client.i32(i32: i32In);
    assert(i32Out == i32In);
    print("i32 round-trip: $i32Out");

    // timepoint: u64 semantics, mapped to BigInt.
    final timepointIn = BigInt.from(1735689600);
    final timepointOut = await client.timepoint(timepoint: timepointIn);
    assert(timepointOut == timepointIn);
    print("timepoint round-trip: $timepointOut");

    // duration: u64 semantics, mapped to BigInt.
    final durationIn = BigInt.from(3600);
    final durationOut = await client.duration(duration: durationIn);
    assert(durationOut == durationIn);
    print("duration round-trip: $durationOut");

    // u128: maximum unsigned 128-bit value (2^128 - 1), exercising the full
    // BigInt width the native Dart int cannot hold.
    final u128In = (BigInt.one << 128) - BigInt.one;
    final u128Out = await client.u128(u128: u128In);
    assert(u128Out == u128In);
    print("u128 round-trip: $u128Out");

    // i128: minimum signed 128-bit value (-2^127), proving sign handling at
    // the negative extreme.
    final i128In = -(BigInt.one << 127);
    final i128Out = await client.i128(i128: i128In);
    assert(i128Out == i128In);
    print("i128 round-trip: $i128Out");

    // u256: maximum unsigned 256-bit value (2^256 - 1).
    final u256In = (BigInt.one << 256) - BigInt.one;
    final u256Out = await client.u256(u256: u256In);
    assert(u256Out == u256In);
    print("u256 round-trip: $u256Out");

    // i256: minimum signed 256-bit value (-2^255).
    final i256In = -(BigInt.one << 255);
    final i256Out = await client.i256(i256: i256In);
    assert(i256Out == i256In);
    print("i256 round-trip: $i256Out");

    // bytes: decoded via .sCBytes.
    final bytesIn = Uint8List.fromList([0, 1, 2, 3, 253, 254, 255]);
    final bytesOut = await client.bytes(bytes: bytesIn);
    assert(bytesOut.length == bytesIn.length);
    for (var i = 0; i < bytesIn.length; i++) {
      assert(bytesOut[i] == bytesIn[i]);
    }
    print("bytes round-trip: $bytesOut");

    // map: keys inserted OUT of ascending order to prove the generator sorts
    // the ScMap before encoding (Soroban rejects unsorted ScMap keys).
    final mapIn = {7: true, 1: true, 2: false};
    final mapOut = await client.map(map: mapIn);
    assert(mapOut.length == mapIn.length);
    mapIn.forEach((k, v) {
      assert(mapOut[k] == v);
    });
    print("map round-trip (unsorted input): $mapOut");

    // tuple: (Symbol, u32) mapped to a (String, int) record.
    final tupleIn = ("Sym", 42);
    final tupleOut = await client.tuple(tuple: tupleIn);
    assert(tupleOut.$1 == tupleIn.$1);
    assert(tupleOut.$2 == tupleIn.$2);
    print("tuple round-trip: (${tupleOut.$1}, ${tupleOut.$2})");

    // vec: Vec<u32> mapped to List<int>, preserving element order.
    // Includes 4294967295 (u32 max) to exercise unsigned decoding.
    final vecIn = [7, 0, 42, 4294967295];
    final vecOut = await client.vec(vec: vecIn);
    assert(vecOut.length == vecIn.length);
    for (var i = 0; i < vecIn.length; i++) {
      assert(vecOut[i] == vecIn[i]);
    }
    print("vec round-trip: $vecOut");

    // option: present and absent.
    final optionSomeOut = await client.option(option: 123);
    assert(optionSomeOut == 123);
    final optionNoneOut = await client.option(option: null);
    assert(optionNoneOut == null);
    print("option round-trip: some=$optionSomeOut none=$optionNoneOut");

    // string: SCV_STRING round-trip.
    final stringIn = "hello, soroban";
    final stringOut = await client.string(string: stringIn);
    assert(stringOut == stringIn);
    print("string round-trip: $stringOut");

    // struct: SimpleStruct with named fields (SCV_MAP) round-trip.
    final struktIn =
        BindingsSpecTestContractSimpleStruct(a: 5, b: true, c: "Hello");
    final struktOut = await client.strukt(strukt: struktIn);
    assert(struktOut == struktIn);
    print("struct round-trip: a=${struktOut.a} b=${struktOut.b} c=${struktOut.c}");

    // union: SimpleEnum (void case) round-trip.
    final simpleIn = BindingsSpecTestContractSimpleEnum.second();
    final simpleOut = await client.simple(simple: simpleIn);
    assert(simpleOut == simpleIn);
    print("union round-trip: ${simpleOut.kind}");

    // card: RoyalCard integer-discriminant enum (repr(u32), King = 13),
    // exercising its dedicated fromScVal(u32) decode path.
    final cardIn = BindingsSpecTestContractRoyalCard.King;
    final cardOut = await client.card(card: cardIn);
    assert(cardOut == cardIn);
    assert(cardOut.value == 13);
    print("card round-trip: ${cardOut.name} (${cardOut.value})");

    // union with payload: ComplexEnum.asset(Address, i128) round-trip.
    final assetAddress = Address.forAccountId(sourceAccountKeyPair.accountId);
    final complexIn = BindingsSpecTestContractComplexEnum.asset(
        (assetAddress, BigInt.from(1000000)));
    final complexOut = await client.complex(complex: complexIn);
    assert(complexOut.kind == BindingsSpecTestContractComplexEnumKind.Asset);
    assert(complexOut.asset!.$1.accountId == assetAddress.accountId);
    assert(complexOut.asset!.$2 == BigInt.from(1000000));
    print("complex union round-trip: ${complexOut.asset!.$2}");

    // union with nested union: ComplexEnum.enum_(SimpleEnum) round-trip,
    // exercising the payload arm whose value is itself a union.
    final complexEnumIn =
        BindingsSpecTestContractComplexEnum.enum_(BindingsSpecTestContractSimpleEnum.third());
    final complexEnumOut = await client.complex(complex: complexEnumIn);
    assert(complexEnumOut == complexEnumIn);
    assert(complexEnumOut.kind == BindingsSpecTestContractComplexEnumKind.Enum);
    assert(complexEnumOut.enum_ == BindingsSpecTestContractSimpleEnum.third());
    print("complex enum union round-trip: ${complexEnumOut.enum_!.kind}");

    // address: a method returning Address round-trips through toXdrSCVal /
    // Address.fromXdrSCVal.
    final addressIn = Address.forAccountId(sourceAccountKeyPair.accountId);
    final addressOut = await client.address(address: addressIn);
    assert(addressOut.accountId == addressIn.accountId);
    print("address round-trip: ${addressOut.accountId}");

    // Dart-keyword-escaped method and parameter names (method `void` -> void_,
    // parameter `finally` -> finally_); wire names stay unescaped.
    await client.void_();
    print("void_ invoked");

    final fromOut = await client.from(finally_: "Sym");
    assert(fromOut == "Sym");
    print("from(finally_) round-trip: $fromOut");
  });
}
