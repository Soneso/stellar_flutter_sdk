
## [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk) 
# Soroban support

The following shows you how to use the Flutter SDK to interact with Soroban. 

## Quick Start

To interact with a Soroban RPC Server, you can use the [`SorobanServer`](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/soroban/soroban_server.dart) class. It connects to a given local or remote Soroban-RPC Server.

Soroban-RPC can be simply described as a “live network gateway for Soroban”. It provides information that the network currently has in its view (i.e. current state). It also has the ability to send a transaction to the network and query the network for the status of previously sent transactions.

You can install your own instance of a Soroban-RPC Server as described [here](https://soroban.stellar.org/docs/tutorials/deploy-to-futurenet). Alternatively, you can use a public remote instance for testing. The Soroban-RPC API is described [here](https://developers.stellar.org/docs/data/rpc/api-reference).

The easiest way to interact with Soroban smart contract is by using the class [`SorobanClient`](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/soroban/soroban_client.dart). It helps you to install and deploy smart contracts and to invoke their methods. You can find a more detailed description below.

## SorobanServer

Provide the url to the endpoint of the Soroban-RPC server to connect to:

```dart
final server = SorobanServer("https://soroban-testnet.stellar.org");
```

Now you can use your `SorobanServer` instance to access the [API endpoints](https://developers.stellar.org/docs/data/rpc/api-reference/methods) provided by the Soroban RPC server.

### Examples

General node health check:

```dart
final healthResponse = await server.getHealth();

if (GetHealthResponse.HEALTHY == healthResponse.status) {
   //...
}
```

Fetch current information about your account:

```dart
final account = await server.getAccount(accountId);
print("Sequence: ${account.sequenceNumber}");
```

Fetch the latest ledger sequence:

```dart
final response = await server.getLatestLedger();
print("latest ledger sequence: ${response.sequence}");
```

## SorobanClient

The easiest way to interact with Soroban smart contracts is by using the class [`SorobanClient`](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/soroban/soroban_client.dart).
It helps you to install and deploy smart contracts and to invoke their methods.

If you want to create a smart contract for testing, you can find the official examples [here](https://github.com/stellar/soroban-examples).
You can also create smart contracts with our AssemblyScript Soroban SDK. Examples can be found [here](https://github.com/Soneso/as-soroban-examples).

The following chapters show examples of interaction with Soroban smart contracts. 
Please also take a look at the [`SorobanClientTest`](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_client_test.dart),
where you can try out this functionality right away.

### Install a contract

As soon as you have the wasm byte code of a compiled contract you can install it as follows:

```dart

final contractCode = await Util.readFile(path);

final installRequest = InstallRequest(
    wasmBytes: contractCode,
    sourceAccountKeyPair: sourceAccountKeyPair,
    network: Network.TESTNET,
    rpcUrl: "https://...");

final wasmHash = await SorobanClient.install(installRequest: installRequest);
```

It will return the wasm hash of the installed contract that you can now use to deploy the contract.

### Deploy a contract

As soon as you have the wasm hash of an installed contract, you can deploy an instance of the contract.

Deployment works as follows:

```dart
final deployRequest = DeployRequest(
    sourceAccountKeyPair: sourceAccountKeyPair,
    network: Network.TESTNET,
    rpcUrl: "https://...",
    wasmHash: wasmHash);

final client = await SorobanClient.deploy(deployRequest: deployRequest);
```
It returns an instance of `SorobanClient`, that you can now use to interact with the contract.

### Instance for contract

To create a new instance of `SorobanClient` for an existing contract, you must provide the contract id:


```dart
final client = await SorobanClient.forClientOptions(
    options: ClientOptions(
        sourceAccountKeyPair: sourceAccountKeyPair,
        contractId: "C...",
        network: Network.TESTNET,
        rpcUrl: "https://...")
);
```

Now you can use the new instance to interact with the contract.

### Invoking a method

As soon as a new instance is created, you can invoke the contract's methods:

```dart
final result = await client.invokeMethod(name: "hello", args: [XdrSCVal.forSymbol("friend")]);
```

It will return the result of the method invocation as a `XdrSCVal` object.

For more advanced use cases where you need to manipulate the transaction (e.g. add memo, additional signers, etc.) you can
obtain the `AssembledTransaction` before sending it to the Soroban RPC Server as follows:

```dart
final tx = await client.buildInvokeMethodTx(name: methodName, args: args);
```

In the following chapter we will discuss how you can use the obtained `AssembledTransaction`.

## AssembledTransaction

The main workhorse of `SorobanClient`. This class is used to wrap a
transaction-under-construction and provide high-level interfaces to the most
common workflows, while still providing access to low-level stellar-sdk
transaction manipulation.

Most of the time, you will not construct an `AssembledTransaction` directly,
but instead receive one as the return value of a `SorobanClient` method.

Let's look at examples of how to use `AssembledTransaction` for a variety of
use-cases:

### 1. Simple read call

Since these only require simulation, you can get the `result` of the call
right after constructing your `AssembledTransaction`:

```dart
final clientOptions = new ClientOptions(
    sourceAccountKeyPair: sourceAccountKeyPair, 
    contractId: "C123...", 
    network: Network.TESTNET, 
    rpcUrl: "https://...");

final txOptions = AssembledTransactionOptions(
    clientOptions: clientOptions,
    methodOptions: MethodOptions(), 
    method: "myReadMethod",
    arguments: args);

final tx = await AssembledTransaction.build(options: txOptions);
final result = await tx.getSimulationData().returnedValue;
```

While that looks pretty complicated, most of the time you will use this in
conjunction with `SorobanClient`, which simplifies it to:

```dart
final result = await client.invokeMethod(name: 'myReadMethod', args: args);
```

### 2. Simple write call

For write calls that will be simulated and then sent to the network without
further manipulation, only one more step is needed:

```dart
final tx = await AssembledTransaction.build(options: txOptions);

final response = await tx.signAndSend();
if (response.status == GetTransactionResponse.STATUS_SUCCESS) {
  final result = response.getResultValue();
}
```

If you are using it in conjunction with [SorobanClient]:

```dart
final result = await client.invokeMethod(name: "myReadMethod", args: args);
```

### 3. More fine-grained control over transaction construction

If you need more control over the transaction before simulating it, you can
set various `MethodOptions` when constructing your `AssembledTransaction`. With a
`SorobanClient`, this can be passed as an argument when calling `invokeMethod` 
or `buildInvokeMethodTx` :

```dart
final methodOptions = MethodOptions(fee: 1000, timeoutInSeconds: 20, simulate: false);

final tx = await client.buildInvokeMethodTx(name: "myWriteMethod",
  args: args, methodOptions: methodOptions);
```

Since we've skipped simulation, we can now edit the `raw` transaction builder and
then manually call `simulate`:

```dart
tx.raw!.addMemo(MemoText("Hello!"));
await tx.simulate();
```

If you need to inspect the simulation later, you can access it with
`tx.getSimulationData()`.

### 4. Multi-auth workflows

Soroban, and Stellar in general, allows multiple parties to sign a transaction.

Let's consider an Atomic Swap contract. Alice wants to give some of her Token A tokens
to Bob for some of his Token B tokens.

```dart
final swapMethodName = "swap";

// For small values, you can use forI128Parts directly
final amountA = XdrSCVal.forI128Parts(0, 1000);
final minBForA = XdrSCVal.forI128Parts(0, 4500);

final amountB = XdrSCVal.forI128Parts(0, 5000);
final minAForB = XdrSCVal.forI128Parts(0, 950);

// For large values, you can now use BigInt
final largeAmountA = XdrSCVal.forI128BigInt(BigInt.parse("1000000000000000000"));
final largeAmountB = XdrSCVal.forU128BigInt(BigInt.from(2).pow(100));

List<XdrSCVal> args = [
     Address.forAccountId(aliceId).toXdrSCVal(),
     Address.forAccountId(bobId).toXdrSCVal(),
     Address.forContractId(tokenAContractId).toXdrSCVal(),
     Address.forContractId(tokenBContractId).toXdrSCVal(),
     amountA,
     minBForA,
     amountB,
     minAForB];
```

Let's say Alice is also going to be the one signing the final transaction
envelope, meaning she is the invoker. So your app, she simulates the `swap` call:

```dart
final tx = await atomicSwapClient.buildInvokeMethodTx(name: swapMethodName, args: args);
 ```
But your app can't `signAndSend` this right away, because Bob needs to sign it first.
You can check this:

```dart
final whoElseNeedsToSign = tx.needsNonInvokerSigningBy()
 ```

You can verify that `whoElseNeedsToSign` is an array of length `1`, containing only Bob's public key.

If you have Bob's secret key, you can sign it right away with:

```dart
final bobsKeyPair = KeyPair.fromSecretSeed("S...");
await tx.signAuthEntries(signerKeyPair: bobsKeyPair);
```
But if you don't have Bob's private key, and e.g. need to send it to another server for signing,
you can provide a callback function for signing the auth entry:

```dart
final bobPublicKeyKeyPair = KeyPair.fromAccountId(bobId);
await tx.signAuthEntries(
  signerKeyPair: bobPublicKeyKeyPair,
  authorizeEntryDelegate: (entry, network) async {

    // You can send it to some other server for signing by encoding it as a base64xdr string
    final base64Entry = entry.toBase64EncodedXdrString();

    // send for signing ...
    // and on the other server you can decode it:
    final entryToSign =
    SorobanAuthorizationEntry.fromBase64EncodedXdr(base64Entry);

    // sign it
    entryToSign.sign(bobKeyPair, network);

    // encode as a base64xdr string and send it back
    final signedBase64Entry = entryToSign.toBase64EncodedXdrString();

    // here you can now decode it and return it
    return SorobanAuthorizationEntry.fromBase64EncodedXdr(signedBase64Entry);
});
 ```
To see an even more complicated example, where Alice swaps with Bob but the
transaction is invoked by yet another party, check out in the [SorobanClientTest atomic swap](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_client_test.dart)

## Contract Spec

The `ContractSpec` class offers a range of useful functions based on the contract spec entries of a contract. It can find specific entries from the contract specification and, more importantly, it can easily prepare arguments to invoke contract functions by converting native Dart values to the corresponding `XdrSCVal` objects based on the contract specification.

To use `ContractSpec`, you need to get it from your `SorobanClient`:

```dart
final spec = client.getContractSpec();
```

Once you have the `ContractSpec`, you can use it to find functions and entries:

```dart
final functions = spec.funcs();
final func = spec.getFunc(name: "swap");
final unionEntry = spec.findEntry(name: "myUnion");
```

### Argument Preparation

The main value of `ContractSpec` lies in simplifying argument preparation for contract function calls. Instead of manually constructing complex `XdrSCVal` objects, you can use native Dart values with named parameters.

**Manual approach (complex and error-prone):**

```dart
// Manually constructing arguments for atomic swap - verbose and complex!
final args = [
  Address.forAccountId(aliceId).toXdrSCVal(),                    // a
  Address.forAccountId(bobId).toXdrSCVal(),                      // b  
  Address.forContractId(tokenAContractId).toXdrSCVal(),          // token_a
  Address.forContractId(tokenBContractId).toXdrSCVal(),          // token_b
  XdrSCVal.forI128Parts(0, 1000),                               // amount_a
  XdrSCVal.forI128Parts(0, 4500),                               // min_b_for_a
  XdrSCVal.forI128Parts(0, 5000),                               // amount_b
  XdrSCVal.forI128Parts(0, 950),                                // min_a_for_b
];
final result = await client.invokeMethod(name: "swap", args: args);
```

**ContractSpec approach (clean and readable):**

```dart
// Using ContractSpec - much simpler and more readable!
final spec = client.getContractSpec();
final args = spec.funcArgsToXdrSCValues("swap", {
  "a": aliceId,                    // String -> Address (automatic)
  "b": bobId,                      // String -> Address (automatic)
  "token_a": tokenAContractId,     // String -> Address (automatic)
  "token_b": tokenBContractId,     // String -> Address (automatic)
  "amount_a": 1000,                // int -> i128 (automatic)
  "min_b_for_a": 4500,            // int -> i128 (automatic)
  "amount_b": 5000,                // int -> i128 (automatic)
  "min_a_for_b": 950               // int -> i128 (automatic)
});

// For large amounts, you can use BigInt
final largeAmountArgs = spec.funcArgsToXdrSCValues("swap", {
  "a": aliceId,
  "b": bobId,
  "token_a": tokenAContractId,
  "token_b": tokenBContractId,
  "amount_a": BigInt.parse("1000000000000000000"),    // BigInt -> i128 (automatic)
  "min_b_for_a": BigInt.parse("4500000000000000000"), // BigInt -> i128 (automatic)
  "amount_b": BigInt.parse("5000000000000000000"),    // BigInt -> i128 (automatic)
  "min_a_for_b": BigInt.parse("950000000000000000")   // BigInt -> i128 (automatic)
});
final result = await client.invokeMethod(name: "swap", args: args);
```

You can also use the convenience method directly on `SorobanClient`:

```dart
final args = client.funcArgsToXdrSCValues("hello", {"to": "World"});
final result = await client.invokeMethod(name: "hello", args: args);
```

For individual value conversion, you can use the `nativeToXdrSCVal` method:

```dart
final spec = client.getContractSpec();
final addressVal = spec.nativeToXdrSCVal("GCKFBEIYTKP6RTHEIX2BULKGADWXKUNST5IXJZJ5I4PQS63ASNK7TGOC", XdrSCSpecTypeDef.forAddress());
final numberVal = spec.nativeToXdrSCVal(42, XdrSCSpecTypeDef.forU32());
```

### Supported Value Types

The `ContractSpec` class supports automatic conversion for all Soroban types:

#### Basic Types

**Void:**
```dart
final voidVal = spec.nativeToXdrSCVal(null, XdrSCSpecTypeDef.forVoid());
```

**Bool:**
```dart
final boolVal = spec.nativeToXdrSCVal(true, XdrSCSpecTypeDef.forBool());
```

**Numbers:**
```dart
// Automatic range checking and conversion
final u32Val = spec.nativeToXdrSCVal(42, XdrSCSpecTypeDef.forU32());
final i64Val = spec.nativeToXdrSCVal(-1234567890, XdrSCSpecTypeDef.forI64());

// For 128-bit and 256-bit numbers, use BigInt for large values
final u128Val = spec.nativeToXdrSCVal(BigInt.from(2).pow(100), XdrSCSpecTypeDef.forU128());
final i128Val = spec.nativeToXdrSCVal(BigInt.parse('-123456789012345678901234567890'), XdrSCSpecTypeDef.forI128());
final u256Val = spec.nativeToXdrSCVal(BigInt.from(2).pow(200), XdrSCSpecTypeDef.forU256());
final i256Val = spec.nativeToXdrSCVal(-BigInt.from(2).pow(200), XdrSCSpecTypeDef.forI256());

// Small integers work for all types (automatically converted)
final u128Small = spec.nativeToXdrSCVal(42, XdrSCSpecTypeDef.forU128());
final i256Small = spec.nativeToXdrSCVal(-42, XdrSCSpecTypeDef.forI256());

// You can still use XdrParts directly if needed
final u128Parts = spec.nativeToXdrSCVal(XdrUInt128Parts(XdrUint64(0), XdrUint64(12345)), XdrSCSpecTypeDef.forU128());
```

**Strings:**
```dart
final stringVal = spec.nativeToXdrSCVal("hello world", XdrSCSpecTypeDef.forString());
final symbolVal = spec.nativeToXdrSCVal("XLM", XdrSCSpecTypeDef.forSymbol());
```

**Addresses:**
```dart
// Automatic detection of account vs contract addresses
final accountAddr = spec.nativeToXdrSCVal("GCKFBEIYTKP6RTHEIX2BULKGADWXKUNST5IXJZJ5I4PQS63ASNK7TGOC", XdrSCSpecTypeDef.forAddress());
final contractAddr = spec.nativeToXdrSCVal("CA3D5KRYM6CB7OWQ6TWYRR3Z4T7GNZLKERYNZGGA5SOAOPIFY6YQGAXE", XdrSCSpecTypeDef.forAddress());
```

**Bytes:**
```dart
// From Uint8List
final bytesVal = spec.nativeToXdrSCVal(Uint8List.fromList([1, 2, 3, 4]), XdrSCSpecTypeDef.forBytes());

// From hex string
final hexBytesVal = spec.nativeToXdrSCVal("01020304", XdrSCSpecTypeDef.forBytes());
```

#### Collection Types

**Vectors (Lists):**
```dart
var elementTypeDef = XdrSCSpecTypeDef.forU32();
final vecTypeDef = XdrSCSpecTypeDef.forVec(XdrSCSpecTypeVec(elementTypeDef));
final vecVal = spec.nativeToXdrSCVal([1, 2, 3, 4], vecTypeDef);

elementTypeDef = XdrSCSpecTypeDef.forString();
final stringVecTypeDef = XdrSCSpecTypeDef.forVec(XdrSCSpecTypeVec(elementTypeDef));
final stringVecVal = spec.nativeToXdrSCVal(["hello", "world"], stringVecTypeDef);
```

**Maps:**
```dart
 final mapTypeDef = XdrSCSpecTypeDef.forMap(XdrSCSpecTypeMap(
  XdrSCSpecTypeDef.forString(),
  XdrSCSpecTypeDef.forString(),
));

final mapVal = spec.nativeToXdrSCVal({
  "key1": "value1",
  "key2": "value2"
}, mapTypeDef);
```

**Tuples:**
```dart
final tupleSpec = XdrSCSpecTypeTuple([
  XdrSCSpecTypeDef.forString(),
  XdrSCSpecTypeDef.forU32(),
  XdrSCSpecTypeDef.forBool(),
]);
final tupleTypeDef = XdrSCSpecTypeDef.forTuple(tupleSpec);
final tupleVal = spec.nativeToXdrSCVal(["first", 42, true], tupleTypeDef);
```

**Options (Nullable Values):**
```dart
final someVal = spec.nativeToXdrSCVal(42, optionTypeDef);      // Some(42)
final noneVal = spec.nativeToXdrSCVal(null, optionTypeDef);    // None
```

#### User-Defined Types

**Enums:**
```dart
// By integer value
final enumByInt = spec.nativeToXdrSCVal(2, enumTypeDef);

// By name
final enumByName = spec.nativeToXdrSCVal("Success", enumTypeDef);
```

**Structs:**
```dart
// Named fields (converted to map)
final structVal = spec.nativeToXdrSCVal({
  "field1": "value1",
  "field2": 42,
  "field3": true
}, structTypeDef);

// Numeric fields (converted to vector)
final numericStructVal = spec.nativeToXdrSCVal([1, 2, 3], numericStructTypeDef);
```

**Unions:**
```dart
// Void case (no associated values)
final voidUnion = spec.nativeToXdrSCVal(
  NativeUnionVal.voidCase("Success"), 
  unionTypeDef
);

// Tuple case (with associated values)
final tupleUnion = spec.nativeToXdrSCVal(
  NativeUnionVal.tupleCase("Error", ["Something went wrong", 404]), 
  unionTypeDef
);
```

### Error Handling

The `ContractSpec` class provides comprehensive error handling with detailed messages:

```dart
try {
  final args = spec.funcArgsToXdrSCValues("nonExistent", {});
} catch (ContractSpecException e) {
  print("Error: ${e.message}");
  // Error: Function not found: nonExistent
}

try {
  final args = spec.funcArgsToXdrSCValues("hello", {}); // Missing "to" parameter
} catch (ContractSpecException e) {
  print("Error: ${e.message}");
  // Error: Required argument not found: to (function: hello)
}
```

### Complete Example

Here's a complete example showing how to use `ContractSpec` for a token contract:

```dart
// Deploy and get the contract client
final client = await SorobanClient.deploy(deployRequest: deployRequest);

// Initialize token using ContractSpec
final args = client.funcArgsToXdrSCValues("initialize", {
  "admin": adminKeyPair.accountId,  // String -> Address
  "decimal": 8,                     // int -> u32
  "name": "MyToken",               // String -> String
  "symbol": "MTK"                  // String -> String
});
await client.invokeMethod(name: "initialize", args: args);

// Mint tokens using ContractSpec
final mintArgs = client.funcArgsToXdrSCValues("mint", {
  "to": recipientId,               // String -> Address
  "amount": 1000000               // int -> i128
});
await client.invokeMethod(name: "mint", args: mintArgs);

// Check balance using ContractSpec
final balanceArgs = client.funcArgsToXdrSCValues("balance", {
  "id": recipientId               // String -> Address
});
final balance = await client.invokeMethod(name: "balance", args: balanceArgs);
print("Balance: ${balance.i128!.lo.uint64}");
```

The `ContractSpec` significantly improves the developer experience by automatically handling type conversions and providing a more intuitive interface for contract interaction. For more examples, see the [ContractSpec tests](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/contract_spec_test.dart) and [SorobanClient tests](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_client_test.dart).

## Contract Bindings

For an even more streamlined development experience, you can generate type-safe Dart contract bindings using the [stellar-contract-bindings](https://github.com/lightsail-network/stellar-contract-bindings) tool. This tool generates Dart classes from your contract specifications that provide:

- **Type-safe method calls** with proper Dart types for all parameters and return values
- **Automatic type conversion** between Dart and Soroban types
- **IDE support** with code completion, type checking, and documentation
- **Simplified API** that feels natural to Dart developers

### Generating Contract Bindings

You can use the Stellar Contract Bindings [Web Interface](https://stellar-contract-bindings.fly.dev).

Or, install the binding generator manually:
```bash
pip install stellar-contract-bindings
```

And generate flutter bindings for your contract:
```bash
stellar-contract-bindings flutter \
  --contract-id YOUR_CONTRACT_ID \
  --rpc-url https://soroban-testnet.stellar.org \
  --output my_contract_client.dart \
  --class-name MyContract
```

### Using Generated Bindings

The generated binding provides a clean, type-safe API:

```dart
// Create the contract client
final contract = await MyContract.forContractId(
  sourceAccountKeyPair: keyPair,
  contractId: contractId,
  network: Network.TESTNET,
  rpcUrl: "https://soroban-testnet.stellar.org",
);

// Call contract methods with proper types
final result = await contract.hello(to: "World");
final balance = await contract.getBalance(address: userAddress);
await contract.transfer(
  from: senderAddress,
  to: recipientAddress,
  amount: BigInt.from(1000),
);
```

### Handling Multiple Contract Bindings

When using multiple contract bindings in the same project, all user-defined types (UDTs) like structs, enums, and unions are automatically prefixed with the contract class name to avoid naming conflicts:

```dart
// Each contract's types are prefixed
final tokenData = TokenContractDataKey.balance(userAddress);
final authData = AuthContractDataKey.counter(userAddress);

// No conflicts even if both contracts define a "DataKey" type
final tokenMetadata = TokenContractTokenMetadata(
  decimal: 7,
  name: "Example Token",
  symbol: "EXT",
);
```

This prefixing ensures that you can safely use multiple generated contract bindings in the same project without type name collisions.

### Example with Generated Bindings

Here's a complete example using generated bindings for a token contract:

```dart
// Deploy and get the contract client
final tokenContract = await TokenContract.forContractId(
  sourceAccountKeyPair: adminKeyPair,
  contractId: tokenContractId,
  network: Network.TESTNET,
  rpcUrl: "https://soroban-testnet.stellar.org",
);

// Initialize the token
await tokenContract.initialize(
  admin: Address.forAccountId(adminId),
  decimal: 7,
  name: "Example Token",
  symbol: "EXT",
);

// Mint tokens
await tokenContract.mint(
  to: Address.forAccountId(recipientId),
  amount: BigInt.from(1000000),
);

// Check balance
final balance = await tokenContract.balance(
  id: Address.forAccountId(recipientId),
);
print("Balance: $balance");

// Transfer tokens
await tokenContract.transfer(
  from: Address.forAccountId(senderId),
  to: Address.forAccountId(recipientId),
  amount: BigInt.from(500000),
);
```

The generated bindings handle all the complexity of type conversion, making contract interaction as simple as calling regular Dart methods.

More examples can be found in the [SorobanClient tests](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_client_test.dart).

## Interacting with Soroban without using the SorobanClient

The [`SorobanClient`](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/soroban/soroban_client.dart) was introduced as a usability improvement, that allows you to easily
install and deploy smart contracts and to invoke their methods. 
It uses the underlying SDK functionality to facilitate this. If you want to learn more about the underlying functionality or need it, the following chapters are for you.

### Deploy your contract

If you want to create a smart contract for testing, you can find the official examples [here](https://github.com/stellar/soroban-examples).
You can also create smart contracts with our AssemblyScript Soroban SDK. Examples can be found [here](https://github.com/Soneso/as-soroban-examples).

There are two main steps involved in the process of deploying a contract. First you need to **upload** the **contract code** and then to **create** the **contract**.

To **upload** the **contract code**, first build a transaction containing the corresponding operation:

```dart
// Create the operation for uploading the contract code (*.wasm file content)
final uploadFunction = UploadContractWasmHostFunction(contractCode);
final operation = InvokeHostFuncOpBuilder(uploadFunction).build();

// Build the transaction
final transaction = TransactionBuilder(account).addOperation(operation).build();
```

Next we need to **simulate** the transaction to obtain the **soroban transaction data** and the **resource fee** needed for final submission.

```dart
// Simulate first to obtain the footprint
final request = SimulateTransactionRequest(transaction);
final simulateResponse = await sorobanServer.simulateTransaction(request);
```
On success, one can find the **soroban transaction data** and the  **resource fee** in the response. Next we need to set the **soroban transaction data** and the **resource fee** to our transaction, then **sign** the transaction and send it to the network using the ```SorobanServer```:

```dart
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(accountKeyPair, Network.TESTNET);

// send transaction to soroban rpc server
final sendResponse = await sorobanServer.sendTransaction(transaction);
```

On success, the response contains the id and status of the transaction:

```dart
if (sendResponse.error == null) {
  print("Transaction Id: ${sendResponse.hash}");
  print("Status: ${sendResponse.status}"); // PENDING
}
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransaction``` request:

```dart
// Fetch transaction 
final transactionResponse = await sorobanServer.getTransaction(transactionId);

var status = transactionResponse.status;

if (GetTransactionResponse.STATUS_NOT_FOUND == status) {
  // try again later ...
} else if (GetTransactionResponse.STATUS_SUCCESS == status) {
  // continue with creating the contract ...
  String contractWasmId = transactionResponse.getWasmId();
  // ...
} else if (GetTransactionResponse.STATUS_FAILED == status) {
  // handle error ...
}
```

Hint: If you experience an error with the transaction result ```txInternalError``` it is most likely that a ledger entry used in the transaction has expired. You can fix it by restoring the footprint (see this [example](https://github.com/Soneso/stellar_flutter_sdk/blob/9a15982ac862bdcab33713184c800065e573f39b/test/soroban_test.dart#L57) in the soroban test of the SDK).

If the transaction was successful, the status response contains the ```wasmId``` of the installed contract code. We need the ```wasmId``` in our next step to **create** the contract:

```dart
// Build the operation for creating the contract
final function = CreateContractHostFunction(Address.forAccountId(accountId), contractWasmId);
final operation = InvokeHostFuncOpBuilder(function).build();

// Build the transaction for creating the contract
final transaction = new TransactionBuilder(account).addOperation(operation).build();

// First simulate to obtain the transaction data + resource fee
final request = new SimulateTransactionRequest(transaction);
final simulateResponse = await sorobanServer.simulateTransaction(request);

// set transaction data, add resource fee & auth and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.setSorobanAuth(simulateResponse.sorobanAuth);
transaction.sign(accountKeyPair, Network.TESTNET);

// Send the transaction to the network.
final sendResponse = await sorobanServer.sendTransaction(transaction);

if (sendResponse.error == null) {
  print("Transaction Id: ${sendResponse.hash}");
  print("Status: ${sendResponse.status}"); // pending
}
```

As you can see, we use the ```wasmId``` to create the operation and the transaction for creating the contract. After simulating, we obtain the transaction data and auth to be set in the transaction. Next, sign the transaction and send it to the Soroban-RPC Server. The transaction status will be "pending", so we need to wait a bit and poll for the current status:

```dart
// Fetch transaction 
final transactionResponse = await sorobanServer.getTransaction(transactionId);

String status = transactionResponse.status;

if (GetTransactionResponse.STATUS_SUCCESS == status) {
  // contract successfully deployed!
  contractId = transactionResponse.getContractId();
}
```

Success!

With the introduction of Protocol 22, contracts with constructor can also be created. The `CreateContractWithConstructorHostFunction` object is used to build the operation.

### Get Ledger Entry

The Soroban-RPC server also provides the possibility to request values of ledger entries directly. It will allow you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry. 

For example, to fetch contract wasm byte-code, use the ContractCode ledger entry key:

```dart
final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_CODE);
ledgerKey.contractCode = XdrLedgerKeyContractCode(XdrHash(Util.hexToBytes(wasmId)),
    XdrContractEntryBodyType.DATA_ENTRY);

final ledgerEntriesResponse = await getLedgerEntries([ledgerKey.toBase64EncodedXdrString()]);
```

If you already have a contractId you can load the code as follows:

```dart
XdrContractCodeEntry? cCodeEntry = await sorobanServer.loadContractCodeForContractId(contractId);

if (cCodeEntry != null) {
    Uint8List sourceCode = cCodeEntry.body.code!.dataValue;
}
```

If you have a wasmId:

```dart
XdrContractCodeEntry? cCodeEntry = await sorobanServer.loadContractCodeForWasmId(wasmId);
```

### Invoking a contract

Now, that we successfully deployed our contract, we are going to invoke it using the Flutter SDK.

First let's have a look to a simple (hello word) contract created with the Rust Soroban SDK. The code and instructions on how to build it, can be found in the official [soroban docs](https://soroban.stellar.org/docs/getting-started/hello-world).

*Hello Word contract code:*

```rust
impl HelloContract {
    pub fn hello(env: Env, to: Symbol) -> Vec<Symbol> {
        vec![&env, symbol_short!("Hello"), to]
    }
}
```

It's only function is called ```hello``` and it accepts a ```symbol``` as an argument. It returns a ```vector``` containing two symbols.

To invoke the contract with the Flutter SDK, we first need to build the corresponding operation and transaction:


```dart
// Name of the function to be invoked
final functionName = "hello";

// Prepare the argument (Symbol)
final arg = XdrSCVal.forSymbol("friend");

// Prepare the "invoke" operation
final hostFunction = InvokeContractHostFunction(contractId!, functionName, arguments: [arg]);
final operation = InvokeHostFuncOpBuilder(hostFunction).build();

// Build the transaction
final transaction = TransactionBuilder(account).addOperation(operation).build();
```

Next we need to **simulate** the transaction to obtain the **soroban transaction data** and **resource fee** needed for final submission:

```dart
// Simulate first to obtain the footprint
final request = new SimulateTransactionRequest(transaction);
final simulateResponse = await sorobanServer.simulateTransaction(request);
```
On success, one can find the **soroban transaction data** and the  **resource fee** in the response. Next we need to set it to our transaction, **sign** the transaction and send it to the network using the ```SorobanServer```:

```dart
// set transaction data, add resource fee and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(accountKeyPair, Network.TESTNET);

// send transaction to soroban rpc server
final sendResponse = await sorobanServer.sendTransaction(transaction);
```

On success, the response contains the id and status of the transaction:

```dart
if (sendResponse.error == null) {
  print("Transaction Id: ${sendResponse.hash}");
  print("Status: ${sendResponse.status}"); // pending
}
```

The status is ```pending``` because the transaction needs to be processed by the Soroban-RPC Server first. Therefore we need to wait a bit and poll for the current transaction status by using the ```getTransactionStatus``` request:

```dart
// Fetch transaction 
final transactionResponse = await sorobanServer.getTransaction(transactionId);

var status = transactionResponse.status;

if (GetTransactionResponse.STATUS_NOT_FOUND == status) {
  // try again later ...
} else if (GetTransactionResponse.STATUS_SUCCESS == status) {
  // success
  // ...
} else if (GetTransactionResponse.STATUS_FAILED == status) {
  // handle error ...
}
```

If the transaction was successful, the status response contains the result:

```dart
// Get the result value
final resVal = transactionResponse.getResultValue()!;

// Extract the Vector
List<XdrSCVal>? vec = resValO.vec;

// Print result
if (vec != null && vec.length > 1) {
  print("[${vec[0].sym}, ${vec[1].sym}]");
  // [Hello, friend]
}
```

Success!

### Deploying Stellar Asset Contract (SAC)

The Flutter SDK also provides support for deploying the build-in [Stellar Asset Contract](https://soroban.stellar.org/docs/advanced-tutorials/stellar-asset-contract) (SAC). The following operations are available for this purpose:

1. Deploy SAC with source account:

```dart
final function = DeploySACWithSourceAccountHostFunction(Address.forAccountId(accountId));
final operation = InvokeHostFuncOpBuilder(function).build();

//...
// set transaction data, add resource fee & auth and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.setSorobanAuth(simulateResponse.sorobanAuth);
transaction.sign(accountKeyPair, Network.TESTNET);
```

2. Deploy SAC with asset:

```dart
final operation = InvokeHostFuncOpBuilder(DeploySACWithAssetHostFunction(asset)).build();
```

### Soroban Authorization

The Flutter SDK provides support for the [Soroban Authorization Framework](https://soroban.stellar.org/docs/fundamentals-and-concepts/authorization).
The SDK's implementation can be found [here](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/soroban/soroban_auth.dart).

To provide authorization you can add a list of `SorobanAuthorizationEntry` to the transaction before sending it.

```dart
transaction.setSorobanAuth(myAuthList);
```

The easiest way to do this is to use the auth data generated by the simulation.

```dart
transaction.setSorobanAuth(simulateResponse.sorobanAuth);
```
But you can also compose the authorization entries by yourself.

If the entries need to be signed you can do it as follows:
```dart
// sign auth
List<SorobanAuthorizationEntry>? auth = simulateResponse.sorobanAuth;
assert(auth != null);

final latestLedgerResponse = await sorobanServer.getLatestLedger();

for (SorobanAuthorizationEntry a in auth!) {
  // update signature expiration ledger
  a.credentials.addressCredentials!.signatureExpirationLedger =
      latestLedgerResponse.sequence! + 10;
  // sign
  a.sign(invokerKeypair, Network.TESTNET);
}

transaction.setSorobanAuth(auth);
```

One can find multiple examples in the [Soroban Auth Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_auth.dart) and [Soroban Atomic Swap Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_atomic_swap.dart) of the SDK.

### Get Events

The Soroban-RPC server provides the possibility to request contract events. 

You can use the Flutter SDK to request events like this:

```dart
final topicFilter = TopicFilter(
    ["*", XdrSCVal.forSymbol('increment').toBase64EncodedXdrString()]);

final eventFilter = EventFilter(
    type: "contract", contractIds: [contractId], topics: [topicFilter]);

final eventsRequest = GetEventsRequest(startLedger, filters: [eventFilter]);

final eventsResponse = await sorobanServer.getEvents(eventsRequest);
```

contractId must currently start with "C...". If you only have the hex value you can encode it with: `StrKey.encodeContractIdHex(contractId)`

Find the complete code in the [Soroban Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test.dart).

#### Hints and Tips

You can find the working code and more in the [SorobanClient Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_client_test.dart), [Soroban Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test.dart), [Soroban Auth Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_auth.dart) and [Soroban Atomic Swap Test](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_atomic_swap.dart) of the Flutter SDK. The used wasm byte-code files can be found in the [test/wasm](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/wasm/) folder.

Because Soroban and the Flutter SDK support for Soroban are in development, errors may occur. For a better understanding of an error you can enable the ```SorobanServer``` logging:

```dart
server.enableLogging = true;
```
This will log the responses received from the Soroban-RPC server.

If you find any issues please report them [here](https://github.com/Soneso/stellar_flutter_sdk/issues). It will help us to improve the SDK.

## Soroban contract parser

The soroban contract parser allows you to access the contract info stored in the contract bytecode.
You can access the environment metadata, contract spec and contract meta.

The environment metadata holds the interface version that should match the version of the soroban environment host functions supported.

The contract spec contains a `XdrSCSpecEntry` for every function, struct, and union exported by the contract.

In the contract meta, contracts may store any metadata in the entries that can be used by applications and tooling off-network.

You can access the parser directly if you have the contract bytecode:

```dart
final byteCode = await Util.readFile("path to .wasm file");
final contractInfo = SorobanContractParser.parseContractByteCode(byteCode);
```

Or you can use `SorobanServer` methods to load the contract code form the network and parse it.

By contract id:
```dart
final contractInfo = await sorobanServer.loadContractInfoForContractId(contractId);
```

By wasm id:
```dart
final contractInfo = await sorobanServer.loadContractInfoForWasmId(wasmId);
```

The parser returns a `SorobanContractInfo` object containing the parsed data.
In [soroban_test_parser.dart](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_parser.dart#L192) you can find a detailed example of how you can access the parsed data.
