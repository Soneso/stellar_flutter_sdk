import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../sep/0001/stellar_toml.dart';
import '../../requests/request_builder.dart';
import '../../responses/submit_transaction_response.dart';
import '../../stellar_sdk.dart';
import '../../transaction.dart';
import '../../key_pair.dart';
import '../../network.dart';
import '../../xdr/xdr_transaction.dart';

/// Implements utility methods for SEP-007 - URI Scheme to facilitate delegated signing
/// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0007.md
class URIScheme {
  static const String uriSchemeName = "web+stellar:";
  static const String signOperation = "tx?";
  static const String payOperation = "pay?";
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
  static const String memoCodeParameterName = "memo";
  static const String memoTypeIssuerParameterName = "memo_type";
  static const String uriSchemePrefix = "stellar.sep.7 - URI Scheme";

  static int messageMaxLength = 300;

  http.Client httpClient = new http.Client();

  /// This function is used to generate a URIScheme compliant URL to serve
  /// as a request to sign a transaction.
  String generateSignTransactionURI(String transactionEnvelopeXdrBase64,
      {String? replace,
      String? callback,
      String? publicKey,
      String? chain,
      String? message,
      String? networkPassphrase,
      String? originDomain,
      String? signature}) {
    String result = uriSchemeName + signOperation;

    final Map<String, String> queryParams = {
      xdrParameterName: Uri.encodeComponent(transactionEnvelopeXdrBase64)
    };

    if (replace != null) {
      queryParams[replaceParameterName] = Uri.encodeComponent(replace);
    }

    if (callback != null) {
      queryParams[callbackParameterName] = Uri.encodeComponent(callback);
    }

    if (publicKey != null) {
      queryParams[publicKeyParameterName] = Uri.encodeComponent(publicKey);
    }

    if (chain != null) {
      queryParams[chainParameterName] = Uri.encodeComponent(chain);
    }

    if (message != null) {
      queryParams[publicKeyParameterName] = Uri.encodeComponent(message);
    }

    if (networkPassphrase != null) {
      queryParams[networkPassphraseParameterName] =
          Uri.encodeComponent(networkPassphrase);
    }

    if (originDomain != null) {
      queryParams[originDomainParameterName] =
          Uri.encodeComponent(originDomain);
    }

    if (signature != null) {
      queryParams[signatureParameterName] = Uri.encodeComponent(signature);
    }

    for (MapEntry e in queryParams.entries) {
      result += "${e.key}=${e.value}&";
    }

    if (queryParams.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// This function is used to generate a URIScheme compliant URL to serve as a
  /// request to pay a specific address with a specific asset, regardless of the
  /// source asset used by the payer.
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
    String result = uriSchemeName + payOperation;

    final Map<String, String> queryParams = {
      destinationParameterName: destinationAccountId
    };

    if (amount != null) {
      queryParams[amountParameterName] = Uri.encodeComponent(amount);
    }

    if (assetCode != null) {
      queryParams[assetCodeParameterName] = Uri.encodeComponent(assetCode);
    }

    if (assetIssuer != null) {
      queryParams[assetIssuerParameterName] = Uri.encodeComponent(assetIssuer);
    }

    if (memo != null) {
      queryParams[memoCodeParameterName] = Uri.encodeComponent(memo);
    }

    if (memoType != null) {
      queryParams[memoTypeIssuerParameterName] = Uri.encodeComponent(memoType);
    }

    if (callback != null) {
      queryParams[callbackParameterName] = Uri.encodeComponent(callback);
    }

    if (message != null) {
      queryParams[messageParameterName] = Uri.encodeComponent(message);
    }

    if (networkPassphrase != null) {
      queryParams[networkPassphraseParameterName] =
          Uri.encodeComponent(networkPassphrase);
    }

    if (originDomain != null) {
      queryParams[originDomainParameterName] =
          Uri.encodeComponent(originDomain);
    }

    if (signature != null) {
      queryParams[signatureParameterName] = Uri.encodeComponent(signature);
    }

    for (MapEntry e in queryParams.entries) {
      result += "${e.key}=${e.value}&";
    }

    if (queryParams.isNotEmpty) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// Signs the given transaction and submits it to the callback url if available,
  /// otherwise it submits it to the stellar network.
  Future<SubmitUriSchemeTransactionResponse> signAndSubmitTransaction(
      String url, KeyPair signerKeyPair,
      {Network? network}) async {
    Network net = Network.PUBLIC;
    if (network != null) {
      net = network;
    }

    final XdrTransactionEnvelope envelope = _getXdrTransactionEnvelope(url);

    AbstractTransaction absTransaction =
        AbstractTransaction.fromEnvelopeXdr(envelope);
    absTransaction.sign(signerKeyPair, net);

    final String? callback = getParameterValue(callbackParameterName, url);
    if (callback != null && callback.startsWith("url:")) {
      final Uri serverURI = Uri.parse(callback.substring(4));
      Map<String, String> headers = {...RequestBuilder.headers};
      headers.putIfAbsent(
          "Content-Type", () => "application/x-www-form-urlencoded");
      String bodyStr = xdrParameterName +
          "=" +
          Uri.encodeComponent(absTransaction.toEnvelopeXdrBase64());
      SubmitUriSchemeTransactionResponse result = await httpClient
          .post(serverURI, body: bodyStr, headers: headers)
          .then((response) {
        return SubmitUriSchemeTransactionResponse(null, response);
      }).catchError((onError) {
        throw onError;
      });
      return result;
    } else {
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
        throw ArgumentError("Unsupported transaction type");
      }
    }
  }

  /// Signs the URIScheme compliant URL with the signer's key pair.
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

  /// Checks if the URL is valid; signature and domain must be present and correct for the signer's keypair.
  /// returns true if valid, otherwise thrown the corresponding URISchemeError.
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
      toml = await StellarToml.fromDomain(originDomain, httpClient: httpClient);
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

  /// Verifies if the url is valid for the given signature to check if it's an authentic url.
  bool verify(
      String url, String urlEncodedBase64Signature, KeyPair signerPublicKey) {
    final String urlSignatureLess = url.replaceAll(
        "&" + signatureParameterName + "=" + urlEncodedBase64Signature, "");
    final Uint8List payloadBytes = _getPayload(urlSignatureLess);
    final String base64Signature =
        Uri.decodeComponent(urlEncodedBase64Signature);
    return signerPublicKey.verify(payloadBytes, base64Decode(base64Signature));
  }

  /// Returns the value of the given url parameter from the specified url if found.
  String? getParameterValue(String name, String url) {
    var uri = Uri.dataFromString(url);
    Map<String, String> params = uri.queryParameters;
    return params[name];
  }

  String _sign(String url, KeyPair signerKeypair) {
    final Uint8List payloadBytes = _getPayload(url);
    final Uint8List signatureBytes = signerKeypair.sign(payloadBytes);
    final String base64Signature = base64Encode(signatureBytes);
    return Uri.encodeComponent(base64Signature);
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

  XdrTransactionEnvelope _getXdrTransactionEnvelope(String url) {
    final String? base64UrlEncodedTransactionEnvelope =
    getParameterValue(xdrParameterName, url);
    if (base64UrlEncodedTransactionEnvelope != null) {
      final String base64TransactionEnvelope =
          Uri.decodeComponent(base64UrlEncodedTransactionEnvelope);
      return XdrTransactionEnvelope.fromEnvelopeXdrString(
          base64TransactionEnvelope);
    } else {
      throw new ArgumentError('Invalid url, tx parameter missing');
    }
  }
}

class SubmitUriSchemeTransactionResponse {
  SubmitTransactionResponse?
      submitTransactionResponse; // if submitted to stellar

  http.Response? response; // if submitted to callback

  SubmitUriSchemeTransactionResponse(
      this.submitTransactionResponse, this.response);
}

/// Errors thrown by the uri scheme
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
