
## [Stellar SDK for Flutter](https://github.com/Soneso/stellar_flutter_sdk) 
## Soroban support

The following shows you how to use the Flutter SDK to start experimenting with Soroban smart contracts. 

**Please note, that both, Soroban itself and the Flutter SDK support for Soroban are still under development, so breaking changes may occur.**


### Quick Start

Flutter SDK Soroban support allows you to deploy and to invoke smart contracts on Futurenet. Futurenet is a special test network provided by Stellar.

To deploy and/or invoke smart contracts with the Flutter SDK use the ```SorobanServer``` class. It connects to a given local or remote Soroban-RPC Server.

Soroban-RPC can be simply described as a “live network gateway for Soroban”. It provides information that the network currently has in its view (i.e. current state). It also has the ability to send a transaction to the network and query the network for the status of previously sent transactions.

You can install your own instance of a Soroban-RPC Server as described [here](https://soroban.stellar.org/docs/tutorials/deploy-to-futurenet). Alternatively, you can use a public remote instance for testing.

The Soroban-RPC API is described [here](https://soroban.stellar.org/api/).

#### Initialize SorobanServer 

Provide the url to the endpoint of the Soroban-RPC server to connect to:

```dart
SorobanServer sorobanServer = SorobanServer("https://rpc-futurenet.stellar.org:443");
```

Set the experimental flag to true. Otherwise it will not work.

```dart
sorobanServer.acknowledgeExperimental = true;
```

#### General node health check
```dart
GetHealthResponse healthResponse = await sorobanServer.getHealth();

if (GetHealthResponse.HEALTHY == healthResponse.status) {
   //...
}
```

#### Get account data

You first need an account on Futurenet. For this one can use ```FuturenetFriendBot``` to fund it:

```dart
KeyPair accountKeyPair = KeyPair.random();
String accountId = accountKeyPair.accountId;
await FuturenetFriendBot.fundTestAccount(accountId);
```

Next you can fetch current information about your Stellar account using the SDK:

```dart
AccountResponse submitter = await sdk.accounts.account(submitterId);
```


#### Deploy your contract

If you want to create a smart contract for testing, you can easily build one with our [AssemblyScript Soroban SDK](https://github.com/Soneso/as-soroban-sdk) or with the [official Stellar Rust SDK](https://soroban.stellar.org/docs/examples/hello-world). Here you can find [examples](https://github.com/Soneso/as-soroban-examples) to be build with the AssemblyScript SDK.

There are two main steps involved in the process of deploying a contract. First you need to **upload** the **contract code** and then to **create** the **contract**.

To **upload** the **contract code**, first build a transaction containing the corresponding operation:

```dart
// Create the operation for uploading the contract code (*.wasm file content)
UploadContractWasmHostFunction uploadFunction =
    UploadContractWasmHostFunction(contractCode);

InvokeHostFunctionOperation operation =
    (InvokeHostFuncOpBuilder()).addFunction(uploadFunction).build();

// Build the transaction
Transaction transaction =
    new TransactionBuilder(account).addOperation(operation).build();
```

Next we need to **simulate** the transaction to obtain the **soroban transaction data** and the **resource fee** needed for final submission.

```dart
// Simulate first to obtain the footprint
SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);
```
On success, one can find the **soroban transaction data** and the  **resource fee** in the response. Next we need to set the **soroban transaction data** and the **resource fee** to our transaction, then **sign** the transaction and send it to the network using the ```SorobanServer```:

```dart
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(accountKeyPair, Network.FUTURENET);

// send transaction to soroban rpc server
SendTransactionResponse sendResponse =
    await sorobanServer.sendTransaction(transaction);
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
GetTransactionResponse transactionResponse =
    await sorobanServer.getTransaction(transactionId);

String status = transactionResponse.status;

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

If the transaction was successful, the status response contains the ```wasmId``` of the installed contract code. We need the ```wasmId``` in our next step to **create** the contract:

```dart
// Build the operation for creating the contract
InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
    .addFunction(CreateContractHostFunction(wasmId))
    .build();

// Build the transaction for creating the contract
Transaction transaction = new TransactionBuilder(account)
    .addOperation(operation).build();

// First simulate to obtain the transaction data + resource fee
SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);

// set transaction data, add resource fee and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(accountKeyPair, Network.FUTURENET);

// Send the transaction to the network.
SendTransactionResponse sendResponse =
    await sorobanServer.sendTransaction(transaction);

if (sendResponse.error == null) {
  print("Transaction Id: ${sendResponse.hash}");
  print("Status: ${sendResponse.status}"); // pending
}
```

As you can see, we use the ```wasmId``` to create the operation and the transaction for creating the contract. After simulating, we obtain the footprint to be set in the transaction. Next, sign the transaction and send it to the Soroban-RPC Server. The transaction status will be "pending", so we need to wait a bit and poll for the current status:

```dart
// Fetch transaction 
GetTransactionResponse transactionResponse =
    await sorobanServer.getTransaction(transactionId);

String status = transactionResponse.status;

if (GetTransactionResponse.STATUS_SUCCESS == status) {
  // contract successfully deployed!
  contractId = transactionResponse.getContractId();
}
```

Success!

#### Get Ledger Entry

The Soroban-RPC server also provides the possibility to request values of ledger entries directly. It will allow you to directly inspect the current state of a contract, a contract’s code, or any other ledger entry. 

For example, to fetch contract wasm byte-code, use the ContractCode ledger entry key:

```dart
String contractCodeKey = simulateResponse.footprint.getContractCodeLedgerKey();

GetLedgerEntryResponse contractCodeEntry =
    await sorobanServer.getLedgerEntry(contractCodeKey);
```

#### Invoking a contract

Now, that we successfully deployed our contract, we are going to invoke it using the Flutter SDK.

First let's have a look to a simple (hello word) contract created with the [AssemblyScript Soroban SDK](https://github.com/Soneso/as-soroban-sdk). The code and instructions on how to build it, can be found in this [example](https://github.com/Soneso/as-soroban-examples/tree/main/hello_word).

*Hello Word contract AssemblyScript code:*

```typescript
import {Symbol, VecObject, fromSmallSymbolStr} from 'as-soroban-sdk/lib/value';
import {Vec} from 'as-soroban-sdk/lib/vec';

export function hello(to: Symbol): VecObject {

  let vec = new Vec();
  vec.pushFront(fromSmallSymbolStr("Hello"));
  vec.pushBack(to);
  
  return vec.getHostObject();
}
```

It's only function is called ```hello``` and it accepts a ```symbol``` as an argument. It returns a ```vector``` containing two symbols.

To invoke the contract with the Flutter SDK, we first need to build the corresponding operation and transaction:


```dart
// Name of the method to be invoked
String method = "hello";

// Prepare the argument (Symbol)
XdrSCVal arg = XdrSCVal.forSymbol("friend");

// Prepare the "invoke" operation
InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
    contractId!, functionName,arguments: [arg]);

InvokeHostFunctionOperation operation =
    (InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

// Build the transaction
Transaction transaction =
    new TransactionBuilder(account).addOperation(operation).build();
```

Next we need to **simulate** the transaction to obtain the **soroban transaction data** and **resource fee** needed for final submission:

```dart
// Simulate first to obtain the footprint
SimulateTransactionResponse simulateResponse =
    await sorobanServer.simulateTransaction(transaction);
```
On success, one can find the **soroban transaction data** and the  **resource fee** in the response. Next we need to set it to our transaction, **sign** the transaction and send it to the network using the ```SorobanServer```:

```dart
// set transaction data, add resource fee and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(accountKeyPair, Network.FUTURENET);

// send transaction to soroban rpc server
SendTransactionResponse sendResponse =
    await sorobanServer.sendTransaction(transaction);
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
GetTransactionResponse transactionResponse =
    await sorobanServer.getTransaction(transactionId);

String status = transactionResponse.status;

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
XdrSCVal resVal = transactionResponse.getResultValue()!;

// Extract the Vector
List<XdrSCVal>? vec = resValO.vec;

// Print result
if (vec != null && vec.length > 1) {
  print("[${vec[0].sym}, ${vec[1].sym}]");
  // [Hello, friend]
}
```

Success!

#### Deploying Stellar Asset Contract (SAC)

The Flutter SDK also provides support for deploying the build-in [Stellar Asset Contract](https://soroban.stellar.org/docs/built-in-contracts/stellar-asset-contract) (SAC). The following operations are available for this purpose:

1. Deploy SAC with source account:

```dart
InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
    .addFunction(DeploySACWithSourceAccountHostFunction())
    .build();
```

2. Deploy SAC with asset:

```dart
InvokeHostFunctionOperation operation = (InvokeHostFuncOpBuilder())
    .addFunction(DeploySACWithAssetHostFunction(assetFsdk))
    .build();
```

#### Soroban Authorization

The Flutter SDK provides support for the [Soroban Authorization Framework](https://soroban.stellar.org/docs/learn/authorization).

For this purpose, it offers the `Address`, `AuthorizedInvocation` and `ContractAuth` classes as well as helper functions like `getNonce(...)`.

Here is a code fragment showing how they can be used:

```dart
Address invokerAddress = Address.forAccountId(invokerId);

String functionName = "auth";
List<XdrSCVal> args = [invokerAddress.toXdrSCVal(), XdrSCVal.forU32(3)];

AuthorizedInvocation rootInvocation =
          AuthorizedInvocation(contractId, functionName, args: args);

int nonce = await sorobanServer.getNonce(invokerId, contractId);

ContractAuth contractAuth =
          ContractAuth(rootInvocation, address: invokerAddress, nonce: nonce);

// sign
contractAuth.sign(invokerKeyPair, Network.FUTURENET);

InvokeContractHostFunction hostFunction = InvokeContractHostFunction(
          contractId, functionName,
          arguments: args, auth: [contractAuth]);

InvokeHostFunctionOperation operation =
(InvokeHostFuncOpBuilder()).addFunction(hostFunction).build();

// simulate first to obtain the transaction data + resource fee
GetAccountResponse submitter =
          await sorobanServer.getAccount(submitterId);

Transaction transaction =
          TransactionBuilder(submitter).addOperation(invokeOp).build();

SimulateTransactionResponse simulateResponse =
          await sorobanServer.simulateTransaction(transaction);
```

The example above invokes this assembly script [auth contract](https://github.com/Soneso/as-soroban-examples/tree/main/auth#code). In this example the submitter of the transaction is not the same as the "invoker" of the contract function.

One can find another example in the [Soroban Auth Test Cases](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_auth.dart) of the SDK where the submitter and invoker are the same, as well as an example where contract auth from the simulation response is used.

An advanced auth example can be found in the [flutter atomic swap](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_atomic_swap.dart) test.

Hint: Resource values and fees have been added in the new soroban preview 9 version. The calculation of the minimum resource values and fee by the simulation (preflight) is not always accurate, because it does not consider signatures. This may result in a failing transaction because of insufficient resources. In this case one can experiment and increase the resources values within the soroban transaction data before signing and submitting the transaction. E.g.:

```dart
int instructions = simulateResponse.transactionData!.resources.instructions.uint32;
instructions += (instructions / 4).round();
simulateResponse.transactionData!.resources.instructions = XdrUint32(instructions);
simulateResponse.minResourceFee = simulateResponse.minResourceFee! + 3000;

// set transaction data, add resource fee and sign transaction
transaction.sorobanTransactionData = simulateResponse.transactionData;
transaction.addResourceFee(simulateResponse.minResourceFee!);
transaction.sign(submitterKeypair, Network.FUTURENET);
```
See also: https://discord.com/channels/897514728459468821/1112853306881081354

#### Get Events

The Soroban-RPC server provides the possibility to request contract events. 

You can use the Flutter SDK to request events like this:

```dart
EventFilter eventFilter =
          EventFilter(type: "contract", contractIds: [contractId]);

GetEventsRequest eventsRequest =
          GetEventsRequest(startLedger, endLedger, filters: [eventFilter]);

GetEventsResponse eventsResponse =
          await sorobanServer.getEvents(eventsRequest);
```
Find the complete code [here](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test.dart#L488).

#### Hints and Tips

You can find the working code and more in the [Soroban Test Cases](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test.dart) and [Soroban Auth Test Cases](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/soroban_test_auth.dart) of the Flutter SDK. The used wasm byte-code files can be found in the [test/wasm](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/wasm/) folder.

Because Soroban and the Flutter SDK support for Soroban are in development, errors may occur. For a better understanding of an error you can enable the ```SorobanServer``` logging:

```dart
server.enableLogging = true;
```
This will log the responses received from the Soroban-RPC server.

If you find any issues please report them [here](https://github.com/Soneso/stellar_flutter_sdk/issues). It will help us to improve the SDK.

