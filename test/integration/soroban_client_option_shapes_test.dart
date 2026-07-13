import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import '../contract_bindings/option_shapes_contract_client.dart';
import '../tests_util.dart';

/// Testnet integration test for the option-shapes contract binding
/// (OptionShapesContract). It exercises Option<T> in every nesting position
/// the generator supports: as a tuple element, a struct field, map values,
/// and a union payload, plus a Dart-keyword-escaped method name (`default`).
///
/// The contract is deployed in-test from the checked-in wasm
/// (test/wasm/soroban_bindings_option_shapes_contract.wasm), mirroring
/// soroban_client_bindings_spec_test.dart. Lives under test/integration/,
/// which CI does not run; execute manually against testnet with:
///   flutter test test/integration/soroban_client_option_shapes_test.dart
void main() {
  String testOn = 'testnet'; //'futurenet';
  Network network = testOn == 'testnet' ? Network.TESTNET : Network.FUTURENET;

  final rpcUrl = testOn == 'testnet'
      ? "https://soroban-testnet.stellar.org"
      : "https://rpc-futurenet.stellar.org";
  final sorobanServer = SorobanServer(rpcUrl);
  sorobanServer.enableLogging = true;
  final OPTION_SHAPES_CONTRACT_PATH =
      'test/wasm/soroban_bindings_option_shapes_contract.wasm';

  final sourceAccountKeyPair = KeyPair.random();

  setUp(() async {
    await fundTestAccountAndWaitForRpc(
        sorobanServer, sourceAccountKeyPair.accountId,
        useFuturenet: testOn != 'testnet');
  });

  Future<String> installContract(String path) async {
    final contractCode = await loadContractCode(path);
    final installRequest = InstallRequest(
        wasmBytes: contractCode,
        sourceAccountKeyPair: sourceAccountKeyPair,
        network: network,
        rpcUrl: rpcUrl,
        server: sorobanServer,
        enableSorobanServerLogging: true);
    return await SorobanClient.install(installRequest: installRequest);
  }

  Future<SorobanClient> deployContract(String wasmHash) async {
    final deployRequest = DeployRequest(
        sourceAccountKeyPair: sourceAccountKeyPair,
        network: network,
        rpcUrl: rpcUrl,
        wasmHash: wasmHash,
        server: sorobanServer,
        enableSorobanServerLogging: true);
    return await SorobanClient.deploy(deployRequest: deployRequest);
  }

  test('test option shapes contract round-trips with contract binding',
      timeout: Timeout(Duration(minutes: 5)), () async {
    final wasmHash = await installContract(OPTION_SHAPES_CONTRACT_PATH);
    print("Installed option shapes contract wasm hash: $wasmHash");

    final deployedClient = await deployContract(wasmHash);
    final contractId = deployedClient.getContractId();
    print("Deployed option shapes contract contract id: $contractId");

    final client = await OptionShapesContract.forContractId(
      sourceAccountKeyPair: sourceAccountKeyPair,
      contractId: contractId,
      network: network,
      rpcUrl: rpcUrl,
      enableServerLogging: true,
    );
    assert(client.getContractId() == contractId);

    // opt_tuple: (Option<u32>, u32) with the option element present and
    // absent (SCV_VOID in the vec slot).
    final optTupleSomeOut = await client.optTuple(tuple: (7, 42));
    assert(optTupleSomeOut.$1 == 7);
    assert(optTupleSomeOut.$2 == 42);
    final optTupleNoneOut = await client.optTuple(tuple: (null, 42));
    assert(optTupleNoneOut.$1 == null);
    assert(optTupleNoneOut.$2 == 42);
    print("opt_tuple round-trip: some=(${optTupleSomeOut.$1}, "
        "${optTupleSomeOut.$2}) none=(${optTupleNoneOut.$1}, "
        "${optTupleNoneOut.$2})");

    // opt_strukt: MaybeStruct with the optional field set and null
    // (SCV_VOID map value).
    final optStruktSomeIn = OptionShapesContractMaybeStruct(flag: 1, maybe: 99);
    final optStruktSomeOut = await client.optStrukt(strukt: optStruktSomeIn);
    assert(optStruktSomeOut == optStruktSomeIn);
    assert(optStruktSomeOut.flag == 1);
    assert(optStruktSomeOut.maybe == 99);
    final optStruktNoneIn =
        OptionShapesContractMaybeStruct(flag: 2, maybe: null);
    final optStruktNoneOut = await client.optStrukt(strukt: optStruktNoneIn);
    assert(optStruktNoneOut == optStruktNoneIn);
    assert(optStruktNoneOut.flag == 2);
    assert(optStruktNoneOut.maybe == null);
    print("opt_strukt round-trip: some.maybe=${optStruktSomeOut.maybe} "
        "none.maybe=${optStruktNoneOut.maybe}");

    // opt_map: Map<u32, Option<u32>> mixing set and null values; keys
    // inserted OUT of ascending order to prove the sort-before-encode path
    // also covers option-valued entries.
    final optMapIn = <int, int?>{9: null, 3: 30, 5: null, 1: 10};
    final optMapOut = await client.optMap(map: optMapIn);
    assert(optMapOut.length == 4);
    assert(optMapOut.containsKey(1) && optMapOut[1] == 10);
    assert(optMapOut.containsKey(3) && optMapOut[3] == 30);
    assert(optMapOut.containsKey(5) && optMapOut[5] == null);
    assert(optMapOut.containsKey(9) && optMapOut[9] == null);
    print("opt_map round-trip (unsorted input): $optMapOut");

    // opt_union: all three states - the void Nothing arm, Maybe carrying a
    // value, and Maybe(null) (payload arm with an absent option, which stays
    // distinct from Nothing because the discriminant symbol is preserved).
    final optUnionNothingOut =
        await client.optUnion(union: OptionShapesContractOptUnion.nothing());
    assert(optUnionNothingOut == OptionShapesContractOptUnion.nothing());
    assert(optUnionNothingOut.kind == OptionShapesContractOptUnionKind.Nothing);
    final optUnionMaybeOut =
        await client.optUnion(union: OptionShapesContractOptUnion.maybe(7));
    assert(optUnionMaybeOut == OptionShapesContractOptUnion.maybe(7));
    assert(optUnionMaybeOut.kind == OptionShapesContractOptUnionKind.Maybe);
    assert(optUnionMaybeOut.maybe == 7);
    final optUnionMaybeNullOut =
        await client.optUnion(union: OptionShapesContractOptUnion.maybe(null));
    assert(optUnionMaybeNullOut == OptionShapesContractOptUnion.maybe(null));
    assert(
        optUnionMaybeNullOut.kind == OptionShapesContractOptUnionKind.Maybe);
    assert(optUnionMaybeNullOut.maybe == null);
    assert(optUnionMaybeNullOut != OptionShapesContractOptUnion.nothing());
    print("opt_union round-trip: nothing=${optUnionNothingOut.kind} "
        "maybe=${optUnionMaybeOut.maybe} "
        "maybeNull=${optUnionMaybeNullOut.maybe}");

    // Dart-keyword-escaped method name: contract method `default` maps to
    // default_; the wire name stays `default`.
    final defaultOut = await client.default_(value: 11);
    assert(defaultOut == 11);
    print("default_ round-trip: $defaultOut");
  });
}
