
### SEP-0006 - TransferServerService

Helps clients to interact with anchors in a standard way defined by [SEP-0006: Deposit and Withdrawal API](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md).



### Create a TransferServerService instance 

**By providing the domain hosting the stellar.toml file**

```dart
final transferService = await TransferServerService.fromDomain("place.domain.com");
```

This will automatically load and parse the stellar.toml file. It will then create the TransferServerService instance by using the transfer server url provided in the stellar.toml file. 

**Or by providing the service url**

Alternatively one can create a TransferServerService instance by providing the transfer server url directly via the constructor:

```dart
final transferService = TransferServerService("http://api.stellar-anchor.org/transfer");
```



### Info

This endpoint (described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#info)) allows an anchor to communicate basic info about what their TRANSFER_SERVER supports to wallets and clients. With the flutter sdk you can use the ```info``` method of your ```TransferServerService``` instance to get the info:

```dart
InfoResponse response = await transferService.info(); 
print(response.feeInfo.enabled);
```



### Deposit

This endpoint (described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#deposit)) is used when a user sends an external token (BTC via Bitcoin, USD via bank transfer, etc...) to an address held by an anchor. With the flutter sdk you can use the ```deposit``` method of your ```TransferServerService``` instance to get the deposit information:

```dart
DepositRequest request = DepositRequest(
   jwt: jwtToken,
   assetCode: 'USD',
   account: accountId,
);

try {
   DepositResponse response = await transferService.deposit(request);
   print(response.how);
   print(response.feeFixed);
} on CustomerInformationNeededException catch (e) {
   print(e.response.fields);
} on CustomerInformationStatusException catch (e) {
   print(e.response.status);
} // ...
```

### Withdraw

This endpoint (described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#withdraw)) is used when a user redeems an asset currently on the Stellar network for it's equivalent off-chain asset via the Anchor. For instance, a user redeeming their NGNT in exchange for fiat NGN. With the flutter sdk you can use the ```withdraw``` method of your ```TransferServerService``` instance to get the withdrawal information:

```dart
WithdrawRequest request = WithdrawRequest(
   assetCode: 'NGNT',
   type: 'bank_account',
   jwt: jwtToken,
);

// ...

try {
   WithdrawResponse response = await transferService.withdraw(request);
   print(response.accountId);
   print(response.feeFixed);
} on CustomerInformationNeededException catch (e) {
   print(e.response.fields);
} on CustomerInformationStatusException catch (e) {
   print(e.response.status);
}  // ...
```

### Deposit-Exchange

If the anchor supports SEP-38 quotes, it can provide a deposit that makes a bridge between non-equivalent tokens by receiving, for instance BRL via bank transfer and in return sending the equivalent value (minus fees) as USDC to the user's Stellar account.

The /deposit-exchange endpoint allows a wallet to get deposit information from an anchor when the user intends to make a conversion between non-equivalent tokens. With this endpoint, described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#deposit-exchange), a user has all the information needed to initiate a deposit and it also lets the anchor specify additional information (if desired) that the user must submit via SEP-12.

```dart
DepositExchangeRequest request = DepositExchangeRequest(
   destinationAsset: 'USDC',
   sourceAsset: 'iso4217:BRA',
   amount: '480.00',
   account: accountId,
   jwt: jwtToken,
);

DepositResponse response = await transferService.depositExchange(request);
var instructions = response.instructions;
//...
```

### Withdraw-Exchange

If the anchor supports SEP-38 quotes, it can provide a withdraw that makes a bridge between non-equivalent tokens by receiving, for instance USDC from the Stellar network and in return sending the equivalent value (minus fees) as NGN to the user's bank account.

The /withdraw-exchange endpoint allows a wallet to get withdraw information from an anchor when the user intends to make a conversion between non-equivalent tokens. With this endpoint, a user has all the information needed to initiate a withdraw and it also lets the anchor specify additional information (if desired) that the user must submit via SEP-12.

```dart
WithdrawExchangeRequest request = WithdrawExchangeRequest(
   sourceAsset: 'USDC',
   destinationAsset: 'iso4217:NGN',
   amount: '700',
   type: 'bank_account',
   jwt: jwtToken,
);

WithdrawResponse response = await transferService.withdrawExchange(request);
print(response.accountId);
//...
```

### Fee

This endpoint (described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#fee)) allows an anchor to report the fee that would be charged for a given deposit or withdraw operation. With the flutter sdk you can use the ```fee``` method of your ```TransferServerService``` instance to get the info if supported by the anchor:

```dart
FeeRequest request = FeeRequest(
   operation: "deposit",
   assetCode: "NGN",
   amount: 123.09,
);

// ...

FeeResponse response = await transferService.fee(request);
print(response.fee);
```


### Transaction History

From this endpoint (described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#transaction-history)) wallets can receive the status of deposits and withdrawals while they process and a history of past transactions with the anchor. With the flutter sdk you can use the ```transactions``` method of your ```TransferServerService``` instance to get the transactions:

```dart
AnchorTransactionsRequest request = AnchorTransactionsRequest(
   assetCode: "XLM",
   account: "GCTTGO5ABSTHABXWL2FMHPZ2XFOZDXJYJN5CKFRKXMPAAWZW3Y3JZ3JK",
   jwt: jwtToken,
);

AnchorTransactionsResponse response = await transferService.transactions(request);
print(response.transactions.length);
print(response.transactions.first.id);
// ...
```


### Single Historical Transaction

This endpoint (described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#single-historical-transaction)) enables clients to query/validate a specific transaction at an anchor. With the flutter sdk you can use the ```transaction``` method of your ```TransferServerService``` instance to get the data:

```dart
AnchorTransactionRequest request = AnchorTransactionRequest();
request.jwt = jwtToken; // jwt token received from stellar web auth - sep-0010
request.id = "82fhs729f63dh0v4";

AnchorTransactionResponse response = await transferService.transaction(request);
print(response.transaction.kind);
print(response.transaction.status);
// ...
```

### Update Transaction

This endpoint (described [here](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#update)) is used when the anchor requests more info via the pending_transaction_info_update status. With the flutter sdk you can use the ```patchTransaction``` method of your ```TransferServerService``` instance to update the data:

```dart
PatchTransactionRequest request = PatchTransactionRequest();
request.jwt = jwtToken; // jwt token received from stellar web auth - sep-0010
request.id = "82fhs729f63dh0v4";
request.fields = {};
request.fields["dest"] = "12345678901234";
request.fields["dest_extra"] = "021000021";

http.Response response = await transferService.patchTransaction(request);
print(response.status);
// ...
```

### Further readings

For more info, see also the class documentation of  ```TransferServerService```  and the sdk's [SEP-0006 test cases](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/sep0006_test.dart).

