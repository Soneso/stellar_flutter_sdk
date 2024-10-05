import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/memo.dart';
import '../../sep/0001/stellar_toml.dart';
import '../../responses/submit_transaction_response.dart';
import '../../stellar_sdk.dart';
import '../../transaction.dart';
import '../../key_pair.dart';
import '../../network.dart';

/// Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing
/// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md
class URIScheme {
  static const String uriSchemeName = "web+stellar:";
  static const String operationTypeTx = "tx";
  static const String operationTypePay = "pay";
  static const String xdrParameterName = "xdr";
  static const String replaceParameterName = "replace";
  static const String callbackParameterName = "callback";
  static const String publicKeyParameterName = "pubkey";
  static const String chainParameterName = "chain";
  static const String messageParameterName = "msg";
  static const String networkPassphraseParameterName = "network_passphrase";
  static const String originDomainParameterName = "origin_domain";
  static const String signatureParameterName = "signature";
  static const String destinationParameterName = "destination";
  static const String amountParameterName = "amount";
  static const String assetCodeParameterName = "asset_code";
  static const String assetIssuerParameterName = "asset_issuer";
  static const String memoParameterName = "memo";
  static const String memoTypeParameterName = "memo_type";
  static const String uriSchemePrefix = "stellar.sep.7 - URI Scheme";
  static const String memoTextType = "MEMO_TEXT";
  static const String memoIdType = "MEMO_ID";
  static const String memoHashType = "MEMO_HASH";
  static const String memoReturnType = "MEMO_RETURN";
  static const List<String> allowedMemoTypes = [
    memoTextType,
    memoIdType,
    memoHashType,
    memoReturnType
  ];

  static int messageMaxLength = 300;
  static int maxAllowedChainingNestedLevels = 7;

  late http.Client httpClient;
  Map<String, String>? httpRequestHeaders;

  URIScheme({http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient ?? http.Client();
  }

  /// This function is used to generate a SEP7 compliant URL to serve
  /// as a request to sign a transaction. The transaction must be
  /// passed a base64 encoded xdr transaction envelope by the parameter [transactionEnvelopeXdrBase64].
  /// The optional parameters [replace], [callback], [publicKey], [chain],
  /// [message], [networkPassphrase], [originDomain] and [signature] are used
  /// as query parameters of the generated sep7 url. All parameters should not be url encoded.
  String generateSignTransactionURI(String transactionEnvelopeXdrBase64,
      {String? replace,
      String? callback,
      String? publicKey,
      String? chain,
      String? message,
      String? networkPassphrase,
      String? originDomain,
      String? signature}) {
    String result = "${uriSchemeName}$operationTypeTx?";

    final Map<String, String> queryParams = {
      xdrParameterName: Uri.encodeQueryComponent(transactionEnvelopeXdrBase64)
    };

    if (replace != null) {
      queryParams[replaceParameterName] = Uri.encodeQueryComponent(replace);
    }

    if (callback != null) {
      queryParams[callbackParameterName] = Uri.encodeQueryComponent(callback);
    }

    if (publicKey != null) {
      queryParams[publicKeyParameterName] = Uri.encodeQueryComponent(publicKey);
    }

    if (chain != null) {
      queryParams[chainParameterName] = Uri.encodeQueryComponent(chain);
    }

    if (message != null) {
      queryParams[publicKeyParameterName] = Uri.encodeQueryComponent(message);
    }

    if (networkPassphrase != null) {
      queryParams[networkPassphraseParameterName] =
          Uri.encodeQueryComponent(networkPassphrase);
    }

    if (originDomain != null) {
      queryParams[originDomainParameterName] =
          Uri.encodeQueryComponent(originDomain);
    }

    if (signature != null) {
      queryParams[signatureParameterName] = Uri.encodeQueryComponent(signature);
    }

    for (MapEntry e in queryParams.entries) {
      result += "${e.key}=${e.value}&";
    }

    if (queryParams.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// This function is used to generate a SEP7 compliant URL to serve as a
  /// request to pay a specific address with a specific asset, regardless of the
  /// source asset used by the payer. The stellar address to receive the payment
  /// must be given by the parameter [destinationAccountId].
  /// The optional parameters [amount], [assetCode], [assetIssuer], [memo],
  /// [memoType], [callback], [message] and [networkPassphrase],
  /// [originDomain] and [signature], are used as query parameters of
  /// the generated sep7 url. All parameters should not be url encoded.
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
      String? signature}) {
    String result = "${uriSchemeName}$operationTypePay?";

    final Map<String, String> queryParams = {
      destinationParameterName: destinationAccountId
    };

    if (amount != null) {
      queryParams[amountParameterName] = Uri.encodeQueryComponent(amount);
    }

    if (assetCode != null) {
      queryParams[assetCodeParameterName] = Uri.encodeQueryComponent(assetCode);
    }

    if (assetIssuer != null) {
      queryParams[assetIssuerParameterName] =
          Uri.encodeQueryComponent(assetIssuer);
    }

    if (memo != null) {
      queryParams[memoParameterName] = Uri.encodeQueryComponent(memo);
    }

    if (memoType != null) {
      queryParams[memoTypeParameterName] = Uri.encodeQueryComponent(memoType);
    }

    if (callback != null) {
      queryParams[callbackParameterName] = Uri.encodeQueryComponent(callback);
    }

    if (message != null) {
      queryParams[messageParameterName] = Uri.encodeQueryComponent(message);
    }

    if (networkPassphrase != null) {
      queryParams[networkPassphraseParameterName] =
          Uri.encodeQueryComponent(networkPassphrase);
    }

    if (originDomain != null) {
      queryParams[originDomainParameterName] =
          Uri.encodeQueryComponent(originDomain);
    }

    if (signature != null) {
      queryParams[signatureParameterName] = Uri.encodeQueryComponent(signature);
    }

    for (MapEntry e in queryParams.entries) {
      result += "${e.key}=${e.value}&";
    }

    if (queryParams.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// Signs the transaction extracted from the given [sep7TxUrl] with the given [signerKeyPair]
  /// and submits it to the `callback` (url) query parameter value contained in the [sep7TxUrl].
  /// If there is no `callback` query parameter contained in the [sep7TxUrl], then it submits
  /// the signed transaction to the Stellar Network.
  /// The given [sep7TxUrl] must be a valid sep7 url having the operation type
  /// `tx` and must contain a valid stellar transaction, otherwise this function will throw an [ArgumentError].
  /// The optional parameter [network] is only required, if the transaction is NOT for the
  /// public Stellar Network (main net).
  Future<SubmitUriSchemeTransactionResponse> signAndSubmitTransaction(
      String sep7TxUrl, KeyPair signerKeyPair,
      {Network? network}) async {
    final parsedUrlResult = tryParseSep7Url(sep7TxUrl);
    if (parsedUrlResult == null ||
        parsedUrlResult.operationType != operationTypeTx ||
        !parsedUrlResult.queryParameters.containsKey(xdrParameterName)) {
      throw ArgumentError.value(
          sep7TxUrl, 'sep7TxUrl', 'invalid sep7 transaction url');
    }

    final envelopeXdr = parsedUrlResult.queryParameters[xdrParameterName]!;
    AbstractTransaction? absTransaction;

    try {
      absTransaction = AbstractTransaction.fromEnvelopeXdrString(envelopeXdr);
    } on Exception catch (_) {
    } on Error catch (_) {}

    if (absTransaction == null) {
      throw ArgumentError.value(sep7TxUrl, 'sep7TxUrl',
          'url contains invalid transaction envelope (xdr)');
    }

    absTransaction.sign(signerKeyPair, network ?? Network.PUBLIC);

    final String? callback =
        parsedUrlResult.queryParameters.containsKey(callbackParameterName)
            ? parsedUrlResult.queryParameters[callbackParameterName]
            : null;
    if (callback != null && callback.startsWith("url:")) {
      final Uri serverURI = Uri.parse(callback.substring(4));
      Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
      headers.putIfAbsent(
          "Content-Type", () => "application/x-www-form-urlencoded");
      String bodyStr = xdrParameterName +
          "=" +
          Uri.encodeQueryComponent(absTransaction.toEnvelopeXdrBase64());
      SubmitUriSchemeTransactionResponse result = await httpClient
          .post(serverURI, body: bodyStr, headers: headers)
          .then((response) {
        return SubmitUriSchemeTransactionResponse(null, response);
      }).catchError((onError) {
        throw onError;
      });
      return result;
    } else {
      Network net = network ?? Network.PUBLIC;
      StellarSDK sdk =
          net == Network.PUBLIC ? StellarSDK.PUBLIC : StellarSDK.TESTNET;
      if (absTransaction is Transaction) {
        SubmitTransactionResponse submitTransactionResponse =
            await sdk.submitTransaction(absTransaction);
        return SubmitUriSchemeTransactionResponse(
            submitTransactionResponse, null);
      } else if (absTransaction is FeeBumpTransaction) {
        SubmitTransactionResponse submitTransactionResponse =
            await sdk.submitFeeBumpTransaction(absTransaction);
        return SubmitUriSchemeTransactionResponse(
            submitTransactionResponse, null);
      } else {
        throw ArgumentError.value(
            sep7TxUrl, 'sep7TxUrl', 'Unsupported transaction type');
      }
    }
  }

  /// Signs an unsigned [sep7Url] url with the given [signerKeypair]
  /// and adds the 'signature' parameter. The given [sep7Url] must be
  /// a valid sep7 url.
  ///
  /// Returns the signed sep7 url with the attached 'signature' parameter.
  /// Throws [ArgumentError] if the given [sep7Url] is not valid or
  /// if the given [sep7Url] is already signed (contains the 'signature' parameter)
  String addSignature(String sep7Url, KeyPair signerKeypair) {
    final validationResult = isValidSep7Url(sep7Url);
    if (!validationResult.result) {
      throw ArgumentError.value(sep7Url, 'sep7Url', 'invalid sep7 url');
    }
    if (sep7Url.contains("&$signatureParameterName=")) {
      throw ArgumentError.value(sep7Url, 'sep7Url',
          "sep7 url already contains a '$signatureParameterName' parameter");
    }
    final String urlEncodedBase64Signature = _sign(sep7Url, signerKeypair);
    return sep7Url + "&$signatureParameterName=$urlEncodedBase64Signature";
  }

  @Deprecated('Use [addSignature]')
  String signURI(String url, KeyPair signerKeypair) {
    final String urlEncodedBase64Signature = _sign(url, signerKeypair);
    if (verify(url, urlEncodedBase64Signature, signerKeypair)) {
      return url +
          "&" +
          signatureParameterName +
          "=" +
          urlEncodedBase64Signature;
    } else {
      throw Exception("could not sign uri");
    }
  }

  /// Tries to parse a given sep7 compliant [url].
  /// Returns null if the given [url] is not a valid sep7 url.
  /// Otherwise it returns the [ParsedSep7UrlResult].
  ParsedSep7UrlResult? tryParseSep7Url(String url) {
    final validationResult = isValidSep7Url(url);
    if (!validationResult.result) {
      return null;
    }
    var uri = Uri.tryParse(url);
    if (uri != null) {
      return ParsedSep7UrlResult(uri.pathSegments.first, uri.queryParameters);
    }
    return null;
  }

  /// Checks if a given [url] is a valid sep7 url without verifying the signature.
  /// If you need to verifying the signature you can use [isValidSep7SignedUrl]
  /// or [verifySignature].
  IsValidSep7UrlResult isValidSep7Url(String url) {
    if (!url.startsWith(uriSchemeName)) {
      return IsValidSep7UrlResult(
          result: false, reason: 'It must start with $uriSchemeName');
    }
    final parsedUri = Uri.tryParse(url);
    if (parsedUri == null) {
      return IsValidSep7UrlResult(result: false, reason: 'Could not parse url');
    }
    final pathSegments = parsedUri.pathSegments;
    final queryParameters = parsedUri.queryParameters;

    if (pathSegments.length != 1) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              'Invalid number of path segments. Must only have one path segment');
    }

    final operationType = pathSegments.first;
    if (operationType != operationTypeTx && operationType != operationTypePay) {
      return IsValidSep7UrlResult(
          result: false,
          reason: 'Operation type $operationType is not supported');
    }

    if (operationType == operationTypeTx &&
        !queryParameters.containsKey(xdrParameterName)) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Operation type $operationType must have a '$xdrParameterName' parameter");
    }

    if (operationType == operationTypeTx &&
        queryParameters.containsKey(xdrParameterName)) {
      final xdr = queryParameters[xdrParameterName]!;
      try {
        AbstractTransaction.fromEnvelopeXdrString(xdr);
      } on Exception catch (_) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "The provided '$xdrParameterName' parameter is not a valid transaction envelope");
      }
    }

    if (queryParameters.containsKey(xdrParameterName) &&
        operationType != operationTypeTx) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$xdrParameterName' for operation type '$operationType'");
    }

    if (operationType == operationTypePay &&
        !queryParameters.containsKey(destinationParameterName)) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Operation type $operationType must have a '$destinationParameterName' parameter");
    }

    if (queryParameters.containsKey(destinationParameterName) &&
        operationType != operationTypePay) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$destinationParameterName' for operation type '$operationType'");
    }

    if (operationType == operationTypePay &&
        queryParameters.containsKey(destinationParameterName)) {
      final destination = queryParameters[destinationParameterName]!;
      bool validDestination = StrKey.isValidStellarAccountId(destination) ||
          StrKey.isValidStellarMuxedAccountId(destination) ||
          StrKey.isValidContractId(destination);
      if (!validDestination) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "The provided '$destinationParameterName' parameter is not a valid Stellar address");
      }
    }

    if (queryParameters.containsKey(replaceParameterName) &&
        operationType != operationTypeTx) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$replaceParameterName' for operation type '$operationType'");
    }

    if (queryParameters.containsKey(amountParameterName) &&
        operationType != operationTypePay) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$amountParameterName' for operation type '$operationType'");
    }

    if (queryParameters.containsKey(assetCodeParameterName) &&
        operationType != operationTypePay) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$assetCodeParameterName' for operation type '$operationType'");
    }

    if (queryParameters.containsKey(assetCodeParameterName)) {
      final code = queryParameters[assetCodeParameterName]!;
      if (code.length > 12) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "The provided '$assetCodeParameterName' parameter is not a valid Stellar asset code");
      }
    }

    if (queryParameters.containsKey(assetIssuerParameterName) &&
        operationType != operationTypePay) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$assetIssuerParameterName' for operation type '$operationType'");
    }

    if (queryParameters.containsKey(assetIssuerParameterName)) {
      final issuer = queryParameters[assetIssuerParameterName]!;
      if (!StrKey.isValidStellarAccountId(issuer)) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "The provided '$assetIssuerParameterName' parameter is not a valid Stellar address");
      }
    }

    if (queryParameters.containsKey(publicKeyParameterName) &&
        operationType != operationTypeTx) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$publicKeyParameterName' for operation type '$operationType'");
    }

    if (queryParameters.containsKey(publicKeyParameterName)) {
      final pubKey = queryParameters[publicKeyParameterName]!;
      if (!StrKey.isValidStellarAccountId(pubKey)) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "The provided '$publicKeyParameterName' parameter is not a valid Stellar public key");
      }
    }

    if (queryParameters.containsKey(messageParameterName)) {
      final msg = queryParameters[messageParameterName]!;
      if (msg.length > messageMaxLength) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "The '$messageParameterName' parameter should be no longer than $messageMaxLength characters");
      }
    }

    if (queryParameters.containsKey(memoTypeParameterName) &&
        operationType != operationTypePay) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$memoTypeParameterName' for operation type '$operationType'");
    }

    if (queryParameters.containsKey(memoParameterName) &&
        operationType != operationTypePay) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$memoParameterName' for operation type '$operationType'");
    }

    String? memoType;
    if (queryParameters.containsKey(memoTypeParameterName)) {
      memoType = queryParameters[memoTypeParameterName]!;
      if (!allowedMemoTypes.contains(memoType)) {
        return IsValidSep7UrlResult(
            result: false,
            reason: "Unsupported '$memoTypeParameterName' value '$memoType'");
      }
    }

    String? memo;
    if (queryParameters.containsKey(memoParameterName)) {
      memo = queryParameters[memoParameterName]!;
      if (memoType == null) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "Parameter '$memoParameterName' requires parameter '$memoTypeParameterName'");
      }
      if (memoType == memoTextType) {
        try {
          MemoText(memo);
        } on MemoTooLongException catch (_) {
          return IsValidSep7UrlResult(
              result: false,
              reason:
                  "Parameter '$memoParameterName' of type '$memoType' is too long");
        }
      } else if (memoType == memoIdType) {
        try {
          MemoId(int.parse(memo));
        } on Exception catch (_) {
          return IsValidSep7UrlResult(
              result: false,
              reason:
                  "Parameter '$memoParameterName' of type '$memoType' has an invalid value");
        }
      } else if (memoType == memoHashType || memoType == memoReturnType) {
        if (!_isBase64(memo)) {
          return IsValidSep7UrlResult(
              result: false,
              reason:
                  "Parameter '$memoParameterName' or type '$memoType' must be base64 encoded");
        }
        if (memoType == memoHashType) {
          try {
            MemoHash(base64Decode(memo));
          } on Exception catch (_) {
            return IsValidSep7UrlResult(
                result: false,
                reason:
                    "Parameter '$memoParameterName' of type '$memoType' has an invalid value");
          }
        } else if (memoType == memoReturnType) {
          try {
            MemoReturnHash(base64Decode(memo));
          } on Exception catch (_) {
            return IsValidSep7UrlResult(
                result: false,
                reason:
                    "Parameter '$memoParameterName' of type '$memoType' has an invalid value");
          }
        }
      }
    }

    if (queryParameters.containsKey(originDomainParameterName)) {
      final originDomain = queryParameters[originDomainParameterName]!;
      if (!_isFullyQualifiedDomainName(originDomain)) {
        return IsValidSep7UrlResult(
            result: false,
            reason:
                "The '$originDomainParameterName' parameter is not a fully qualified domain name");
      }
    }

    if (queryParameters.containsKey(chainParameterName) &&
        operationType != operationTypeTx) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Unsupported parameter '$chainParameterName' for operation type '$operationType'");
    }

    if (queryParameters.containsKey(chainParameterName)) {
      var chainValue = queryParameters[chainParameterName];
      var level = 1;
      while (chainValue != null) {
        final chainUri = Uri.tryParse(chainValue);
        if (chainUri == null) {
          return IsValidSep7UrlResult(
              result: false,
              reason: 'Could not parse chain url at nested level $level');
        }
        final chainUriQueryParameters = chainUri.queryParameters;
        if (chainUriQueryParameters.containsKey(chainParameterName)) {
          if (level > maxAllowedChainingNestedLevels) {
            return IsValidSep7UrlResult(
                result: false,
                reason:
                    'Chaining more then $maxAllowedChainingNestedLevels nested levels is not allowed');
          }
          chainValue = chainUriQueryParameters[chainParameterName];
          level++;
        } else {
          break;
        }
      }
    }

    return IsValidSep7UrlResult(result: true);
  }

  /// Checks if the given [url] is a valid an properly signed sep7 url.
  /// The 'origin_domain' and 'signature' query parameters in the url must be set,
  /// otherwise the given [url] will be considered as invalid. This function will make a http request
  /// to obtain the toml data from the 'origin_domain'. If the toml data could not be loaded
  /// or if it dose not contain the signer's public key, the given [url] will be
  /// considered as invalid. If the [url] has been signed by the signer from the
  /// 'origin_domain' toml data, the [url] will be considered as valid.
  Future<IsValidSep7UrlResult> isValidSep7SignedUrl(String url) async {
    final parsedUri = Uri.tryParse(url);
    if (parsedUri == null) {
      return IsValidSep7UrlResult(result: false, reason: 'Could not parse url');
    }

    // check if url is a valid sep 7 url
    final urlValidationResult = isValidSep7Url(url);
    if (!urlValidationResult.result) {
      // not valid
      return urlValidationResult;
    }

    final queryParameters = parsedUri.queryParameters;

    final String? originDomain =
        queryParameters.containsKey(originDomainParameterName)
            ? queryParameters[originDomainParameterName]!
            : null;
    if (originDomain == null) {
      return IsValidSep7UrlResult(
          result: false,
          reason: "Missing parameter '$originDomainParameterName'");
    }

    if (!_isFullyQualifiedDomainName(originDomain)) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "The '$originDomainParameterName' parameter is not a fully qualified domain name");
    }

    final String? signature =
        queryParameters.containsKey(signatureParameterName)
            ? queryParameters[signatureParameterName]!
            : null;
    if (signature == null) {
      return IsValidSep7UrlResult(
          result: false, reason: "Missing parameter '$signatureParameterName'");
    }

    StellarToml? toml;
    try {
      toml = await StellarToml.fromDomain(originDomain,
          httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
    } on Exception catch (_) {
      return IsValidSep7UrlResult(
          result: false,
          reason: "Toml not found or invalid for '$originDomain'");
    }

    final String? uriRequestSigningKey =
        toml.generalInformation.uriRequestSigningKey;
    if (uriRequestSigningKey == null) {
      return IsValidSep7UrlResult(
          result: false,
          reason: "No signing key found in toml from '$originDomain'");
    }

    KeyPair? signerPublicKey;
    try {
      signerPublicKey = KeyPair.fromAccountId(uriRequestSigningKey);
    } on Exception catch (_) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Signing key found in toml from '$originDomain' is not valid");
    }

    if (!verifySignature(url, signerPublicKey.accountId)) {
      return IsValidSep7UrlResult(
          result: false,
          reason:
              "Signature is not from the signing key '${signerPublicKey.accountId}' found in the toml data of '$originDomain");
    }

    return IsValidSep7UrlResult(result: true);
  }

  bool _isFullyQualifiedDomainName(String originDomain) {
    final isFullyQualifiedDomainNameRegExp = new RegExp(
        r"(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-).)+[a-zA-Z]{2,63}.?$)");
    if (isFullyQualifiedDomainNameRegExp.hasMatch(originDomain)) {
      return true;
    }
    return false;
  }

  bool _isBase64(String value) {
    final isBase64RegExp = new RegExp(
        r'^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{4})$');
    if (isBase64RegExp.hasMatch(value)) {
      return true;
    }
    return false;
  }

  @Deprecated('Use [isValidSep7SignedUrl]')
  Future<bool> checkUIRSchemeIsValid(String url) async {
    final String? originDomain =
        getParameterValue(originDomainParameterName, url);
    if (originDomain == null) {
      throw URISchemeError(URISchemeError.missingOriginDomain);
    }

    final isFullyQualifiedDomainNameRegExp = new RegExp(
        r"(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-).)+[a-zA-Z]{2,63}.?$)");
    if (!isFullyQualifiedDomainNameRegExp.hasMatch(originDomain)) {
      throw URISchemeError(URISchemeError.invalidOriginDomain);
    }

    final String? signature = getParameterValue(signatureParameterName, url);
    if (signature == null) {
      throw URISchemeError(URISchemeError.missingSignature);
    }

    StellarToml? toml;
    try {
      toml = await StellarToml.fromDomain(originDomain,
          httpClient: httpClient, httpRequestHeaders: this.httpRequestHeaders);
    } on Exception catch (_) {
      throw URISchemeError(URISchemeError.tomlNotFoundOrInvalid);
    }

    final String? uriRequestSigningKey =
        toml.generalInformation.uriRequestSigningKey;
    if (uriRequestSigningKey == null) {
      throw URISchemeError(URISchemeError.tomlSignatureMissing);
    }

    final KeyPair signerPublicKey = KeyPair.fromAccountId(uriRequestSigningKey);
    try {
      if (!verify(url, signature, signerPublicKey)) {
        throw URISchemeError(URISchemeError.invalidSignature);
      }
    } on Exception catch (_) {
      throw URISchemeError(URISchemeError.invalidSignature);
    }
    return true;
  }

  @Deprecated('Use [verifySignature]')
  bool verify(
      String url, String urlEncodedBase64Signature, KeyPair signerPublicKey) {
    final String urlSignatureLess = url.replaceAll(
        "&" + signatureParameterName + "=" + urlEncodedBase64Signature, "");
    final Uint8List payloadBytes = _getPayload(urlSignatureLess);
    final String base64Signature =
        Uri.decodeComponent(urlEncodedBase64Signature);
    return signerPublicKey.verify(payloadBytes, base64Decode(base64Signature));
  }

  /// Verifies if the given [sep7Url] was signed by the signer with the given [signerPublicKey].
  /// The [signerPublicKey] must be a valid stellar account id.
  /// The [sep7Url] must be a valid sep7 url and it must contain the parameter 'signature'.
  /// Returns true if the given [sep7Url] was signed by the signer with the given [signerPublicKey].
  /// Returns false if the given [signerPublicKey] is invalid or the given [sep7Url] is invalid or
  /// if the url was not signed by the signer with the given [signerPublicKey].
  /// Hint: If you don't know the [signerPublicKey], you can use [isValidSep7SignedUrl]
  bool verifySignature(String sep7Url, String signerPublicKey) {
    KeyPair? signerKeyPair;
    try {
      signerKeyPair = KeyPair.fromAccountId(signerPublicKey);
    } on Exception catch (_) {
      // invalid public key.
      return false;
    }

    // it needs to be parsable so that we can access the query parameters
    final parsedUri = Uri.tryParse(sep7Url);
    if (parsedUri == null) {
      return false;
    }

    // check if url is a valid sep 7 url
    final urlValidationResult = isValidSep7Url(sep7Url);
    if (!urlValidationResult.result) {
      // not valid
      return false;
    }

    final queryParameters = parsedUri.queryParameters;

    final String? signature =
        queryParameters.containsKey(signatureParameterName)
            ? queryParameters[signatureParameterName]!
            : null;
    if (signature == null) {
      return false;
    }

    final String urlSignatureLess = sep7Url.replaceAll(
        "&$signatureParameterName=${Uri.encodeQueryComponent(signature)}", "");
    final Uint8List payloadBytes = _getPayload(urlSignatureLess);
    return signerKeyPair.verify(payloadBytes, base64Decode(signature));
  }

  @Deprecated('Use [tryParseSep7Url]')
  String? getParameterValue(String name, String url) {
    var uri = Uri.dataFromString(url);
    Map<String, String> params = uri.queryParameters;
    return params[name];
  }

  String _sign(String url, KeyPair signerKeypair) {
    final Uint8List payloadBytes = _getPayload(url);
    final Uint8List signatureBytes = signerKeypair.sign(payloadBytes);
    final String base64Signature = base64Encode(signatureBytes);
    return Uri.encodeQueryComponent(base64Signature);
  }

  Uint8List _getPayload(String url) {
    Uint8List payloadStart = Uint8List(36);
    for (int i = 0; i < 36; i++) {
      payloadStart[i] = 0;
    }
    payloadStart[35] = 4;

    final List<int> codeUnits = (uriSchemePrefix + url).codeUnits;
    final Uint8List url8List = Uint8List.fromList(codeUnits);

    var b = BytesBuilder();
    b.add(payloadStart);
    b.add(url8List);
    return b.toBytes();
  }
}

class SubmitUriSchemeTransactionResponse {
  SubmitTransactionResponse?
      submitTransactionResponse; // if submitted to stellar

  http.Response? response; // if submitted to callback

  SubmitUriSchemeTransactionResponse(
      this.submitTransactionResponse, this.response);
}

@Deprecated(
    "Only thrown by [checkUIRSchemeIsValid] which is deprecated. Use [isValidSep7SignedUrl] instead.")
class URISchemeError implements Exception {
  int _type;
  static const int invalidSignature = 0;
  static const int invalidOriginDomain = 1;
  static const int missingOriginDomain = 2;
  static const int missingSignature = 3;
  static const int tomlNotFoundOrInvalid = 4;
  static const int tomlSignatureMissing = 5;

  URISchemeError(this._type);

  String toString() {
    switch (_type) {
      case invalidSignature:
        return "URISchemeError: invalid Signature";
      case invalidOriginDomain:
        return "URISchemeError: invalid Origin Domain";
      case missingOriginDomain:
        return "URISchemeError: missing Origin Domain";
      case missingSignature:
        return "URISchemeError: missing Signature";
      case tomlNotFoundOrInvalid:
        return "URISchemeError: toml not found or invalid";
      case tomlSignatureMissing:
        return "URISchemeError: Toml Signature Missing";
      default:
        return "URISchemeError: unknown error";
    }
  }

  int get type => _type;
}

class IsValidSep7UrlResult {
  /// true if valid.
  bool result;

  /// Description of the reason if not valid.
  String? reason;
  IsValidSep7UrlResult({required this.result, this.reason});
}

class ParsedSep7UrlResult {
  /// Possible values are 'tx' and 'pay'.
  String operationType;

  /// Url decoded query parameters.
  Map<String, String> queryParameters;

  ParsedSep7UrlResult(this.operationType, this.queryParameters);
}
