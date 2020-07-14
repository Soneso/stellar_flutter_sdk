
### SEP-0002 - Federation

This examples shows how to resolve a stellar address, a stellar account id, a transaction id and a forward by using the federation protocol. For more details see: [SEP-0002 Federation](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0002.md).

#### Resolving a stellar address

To resolve a stellar address like for example ```bob*soneso.com``` we can use the static method  ```Federation.resolveStellarAddress ```  as shown below:

```dart
FederationResponse response = await Federation.resolveStellarAddress("bob*soneso.com");

print(response.stellarAddress);
// bob*soneso.com

print(response.accountId);
// GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI

print(response.memoType);
// text

print(response.memo);
// hello memo text
```

#### Resolving a stellar account id

To resolve a stellar account id like for example ```GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI``` we can use the static method  ```Federation.resolveStellarAccountId ```. We need to provide the account id and the federation server url as parameters:

```dart
FederationResponse response = await Federation.resolveStellarAccountId("GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI", "https://stellarid.io/federation/");

print(response.stellarAddress);
// bob*soneso.com

print(response.accountId);
// GBVPKXWMAB3FIUJB6T7LF66DABKKA2ZHRHDOQZ25GBAEFZVHTBPJNOJI

print(response.memoType);
// text

print(response.memo);
// hello memo text
```

#### Resolving a stellar transaction id

To resolve a stellar transaction id like for example ```c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a``` we can use the static method  ```Federation.resolveStellarTransactionId ```.  We need to provide the transaction id and the federation server url as parameters:

```dart
// Returns the federation record of the sender of the transaction if known by the server
FederationResponse response = await Federation.resolveStellarTransactionId("c1b368c00e9852351361e07cc58c54277e7a6366580044ab152b8db9cd8ec52a", "https://stellarid.io/federation/");
```

#### Resolving a forward 

Used for forwarding the payment on to a different network or different financial institution. Here we can use the static method  ```Federation.resolveForward``` . We need to provide the needed query parameters as ```Map<String, String>``` and the federation server url:

```dart
FederationResponse response = await Federation.resolveForward({
  "forward_type": "bank_account",
  "swift": "BOPBPHMM",
  "acct": "2382376"
}, "https://stellarid.io/federation/");

// resulting request url: 
// https://stellarid.io/federation/?type=forward&forward_type=bank_account&swift=BOPBPHMM&acct=2382376
```
