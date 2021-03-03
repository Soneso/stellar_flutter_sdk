
### SEP-0010 - Stellar Web Authentication



Stellar Web Authentication is described in [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md). The SEP defines the standard way for clients such as wallets or exchanges to create authenticated web sessions on behalf of a user who holds a Stellar account. A wallet may want to authenticate with any web service which requires a Stellar account ownership verification, for example, to upload KYC information to an anchor in an authenticated way.

The following examples show how to use the flutter stellar sdk to create authenticated web sessions on behalf of a user who holds a Stellar account.




### Create a WebAuth instance by providing the domain hosting the stellar.toml file

```dart
final webauth = await WebAuth.fromDomain("place.domain.com", Network.TESTNET);
```


### Request the jwtToken for the web session by providing the KeyPair of the user to sign the challenge from the web auth server

```dart
String jwtToken = await webAuth.jwtToken(KeyPair.fromSecretSeed(clientSecretSeed));
```

That is all you need to do. The method ```jwtToken``` will request the challenge from the web auth server, validate it, sign it on behalf of the user and send it back to the web auth server. The web auth server will than respond with the jwt token.



### If multiple accounts need to sign the challenge  

If you need multiple accounts to sign the challenge you can do it similar to the ```jwtToken``` method:

```dart
// get the challenge transaction from the web auth server
String transaction = await webAuth.getChallenge(kp.accountId, homeDomain);

// validate the transaction received from the web auth server.
webAuth.validateChallenge(transaction, kp.accountId); // throws if not valid

// sign the transaction received from the web auth server using the provided user/client keypair by parameter.
String signedTransaction = webAuth.signTransaction(transaction, kp);

// sign again with another account ...
signedTransaction = webAuth.signTransaction(signedTransaction, kp2);

// request the jwt token by sending back the signed challenge transaction to the web auth server.
final String jwtToken = await webAuth.sendSignedChallengeTransaction(signedTransaction);

```



