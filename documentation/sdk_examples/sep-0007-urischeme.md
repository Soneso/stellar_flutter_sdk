
### SEP-0007 - URI Scheme to facilitate delegated signing



URI Scheme to facilitate delegated signing is described in [SEP-0007](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md). This Stellar Ecosystem Proposal introduces a URI Scheme that can be used to generate a URI that will serve as a request to sign a transaction. The URI (request) will typically be signed by the user’s trusted wallet where she stores her secret key(s).

This SDK provides utility features to facilitate the implementation of SEP-0007 in a Flutter Wallet. These features are implemented in the [URIScheme](https://github.com/Soneso/stellar_flutter_sdk/blob/master/lib/src/sep/0007/URIScheme.dart) class and are described below.

**Generate a transaction uri**

```dart
String generateSignTransactionURI(String transactionEnvelopeXdrBase64,
      {String? replace,
      String? callback,
      String? publicKey,
      String? chain,
      String? message,
      String? networkPassphrase,
      String? originDomain,
      String? signature})
```
This function can be used to generate a URIScheme compliant URL to serve as a request to sign a transaction.

Example:

```dart
AccountResponse sourceAccount = await sdk.accounts.account(accountId);
SetOptionsOperationBuilder setOp = SetOptionsOperationBuilder();
setOp.setSourceAccount(accountId);
setOp.setHomeDomain("www.soneso.com");

Transaction transaction =
    TransactionBuilder(sourceAccount).addOperation(setOp.build()).build();

URIScheme uriScheme = URIScheme();
String url =
    uriScheme.generateSignTransactionURI(transaction.toEnvelopeXdrBase64());

print(url);

// web+stellar:tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9ONBFmFGORBZkWAAAAGQABwWpAAAAKwAAAAAAAAAAAAAAAQAAAAEAAAAAzULyQmobEYo0RVzB4Mhl3Wq%2FeVsmvTjQRZhRjkQWZFgAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAOd3d3LnNvbmVzby5jb20AAAAAAAAAAAAAAAAAAA%3D%3D
```

**Generate a pay operation uri**

```dart
String generatePayOperationURI(String destinationAccountId,
      {String? amount,
      String? assetCode,
      String? assetIssuer,
      String? memo,
      String? memoType,
      String? callback,
      String? message,
      String? networkPassphrase,
      String? originDomain,
      String? signature})
```

This function can be used to generate a URIScheme compliant URL to serve as a request to pay a specific address with a specific asset, regardless of the source asset used by the payer.

Example:

```dart
URIScheme uriScheme = URIScheme();
String url = uriScheme.generatePayOperationURI(accountId,
    amount: "123.21",
    assetCode: "ANA",
    assetIssuer:
        "GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV");

print(url);
//web+stellar:pay?destination=GDGUF4SCNINRDCRUIVOMDYGIMXOWVP3ZLMTL2OGQIWMFDDSECZSFQMQV&amount=123.21&asset_code=ANA&asset_issuer=GC4HC3AXQDNAMURMHVGMLFGLQELEQBCE4GI7IOKEAWAKBXY7SXXWBTLV
```

**Check if URL is a valid sep7 URL**
```dart
final validationResult = uriScheme.isValidSep7Url(url);
```
Checks if the received SEP-0007 URL is valid; It does not check if it has been properly signed.

**Check if URL is a valid sep7 URL and if it has been properly signed**

```dart
final validationResult = await uriScheme.isValidSep7SignedUrl(url);
```

Checks if the received SEP-0007 URL is valid and properly signed. The url must contain the 
`origin_domain` and `signature` query parameters. This function will make a http request 
to load the toml data containing the signer's public key from the `origin_domain`.
The given signed url is considered as valid if it has been signed by the signer 
listed in the `origin_domain` toml data.

If you already know the signer's public key, you can check the signature by using:
```dart
bool verifySignature(String sep7Url, String signerPublicKey)
```

**Parse URL**

You can parse the url by using:

```dart
final parseResult = tryParseSep7Url(url);

if (parseResult != null) {
  final opType = parseResult.operationType;
  final message = parseResult.queryParameters[URIScheme.messageParameterName];
  //...
}
```

**Sign URI**

```dart
String addSignature(String sep7Url, KeyPair signerKeypair)
```
Signs the URIScheme compliant SEP-0007 url with the signer's key pair. Returns the signed url having the signature parameter attached.
Be careful with this function, you should validate the url and ask the user for permission before using this function.

Example:

```dart
print(url);
// web+stellar:tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9ONBFmFGORBZkWAAAAGQABwWpAAAAKwAAAAAAAAAAAAAAAQAAAAEAAAAAzULyQmobEYo0RVzB4Mhl3Wq%2FeVsmvTjQRZhRjkQWZFgAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAOd3d3LnNvbmVzby5jb20AAAAAAAAAAAAAAAAAAA%3D%3D&origin_domain=place.domain.com

URIScheme uriScheme = URIScheme();
url = uriScheme.addSignature(url, signerKeyPair);
print(url);
// web+stellar:tx?xdr=AAAAAgAAAADNQvJCahsRijRFXMHgyGXdar95Wya9ONBFmFGORBZkWAAAAGQABwWpAAAAKwAAAAAAAAAAAAAAAQAAAAEAAAAAzULyQmobEYo0RVzB4Mhl3Wq%2FeVsmvTjQRZhRjkQWZFgAAAAFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAOd3d3LnNvbmVzby5jb20AAAAAAAAAAAAAAAAAAA%3D%3D&origin_domain=place.domain.com&signature=bIZ53bPKkNe0OoNK8PGLTnzHS%2FBCMzXTvwv1mc4DWc0XC4%2Bp197AmUB%2FIPL1UZAega7cLYv7%2F%2FaflB7CLGqZCw%3D%3D
```

**Sign and submit transaction**

```dart
Future<SubmitUriSchemeTransactionResponse> signAndSubmitTransaction(
  String sep7TxUrl, KeyPair signerKeyPair,
  {Network? network}) async 
```
Signs the given transaction and submits it to the callback url if available, otherwise it submits it to the stellar network.
Be careful with this function, you should validate the url and ask the user for permission before using this function.

Example:

```dart
URIScheme uriScheme = URIScheme();
SubmitUriSchemeTransactionResponse response = await uriScheme
        .signAndSubmitTransaction(url, signerKeyPair, network: Network.TESTNET);
```

```SubmitUriSchemeTransactionResponse``` has two members: ```submitTransactionResponse``` and ```response```. ```submitTransactionResponse``` is filled if the transaction has been send to the stellar network. ```response``` is filled if the transaction has been sent to the callback.

```dart
class SubmitUriSchemeTransactionResponse {
  SubmitTransactionResponse?
      submitTransactionResponse; // if submitted to stellar

  http.Response? response; // if submitted to callback

  SubmitUriSchemeTransactionResponse(
      this.submitTransactionResponse, this.response);
}
```

**Get parameter value**

```dart
final parseResult = tryParseSep7Url(url);
if (parseResult != null) {
  final message = parseResult.queryParameters[URIScheme.messageParameterName];
}
```

**Get operation type**

```dart
final parseResult = tryParseSep7Url(url);
if (parseResult != null) {
  final opType = parseResult.operationType;
  if (opType == URIScheme.operationTypePay) {
    //...
  } 
}
```

**Compose and parse replace parameter**

Takes a list of `UriSchemeReplacement` objects and parses it to a string that
could be used as a Sep-7 URI 'replace' param.

```dart
String uriSchemeReplacementsToString(List<UriSchemeReplacement> replacements)
```

Takes a Sep-7 URL-decoded `replace` string param and parses it to a list of
`UriSchemeReplacement` objects for easy of use:

```dart
List<UriSchemeReplacement> uriSchemeReplacementsFromString(String replace) 
```

**More examples**

You can find more examples in the [SEP-0007 Test Cases](https://github.com/Soneso/stellar_flutter_sdk/blob/master/test/sep0007_test.dart)