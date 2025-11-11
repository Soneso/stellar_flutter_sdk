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

/// Implements utility methods for SEP-0007 - URI Scheme to facilitate delegated signing.
///
/// SEP-0007 defines a standardized URI scheme (`web+stellar:`) that enables applications
/// to request transaction signing from user wallets without handling secret keys directly.
/// This implementation supports both transaction (`tx`) and payment (`pay`) operations.
///
/// **Supported SEP-0007 Version**: 2.1.0
///
/// ## Security Considerations
///
/// **CRITICAL**: This implementation handles security-sensitive operations. Applications and
/// wallets using this class MUST follow SEP-0007 security best practices:
///
/// ### For URI Request Generators (Applications)
///
/// - Always include `origin_domain` and `signature` parameters for production URIs
/// - Store your `URI_REQUEST_SIGNING_KEY` in your domain's stellar.toml file
/// - Never expose private signing keys in client-side code
/// - Use HTTPS for callback URLs to prevent man-in-the-middle attacks
/// - Include clear transaction details in the `msg` parameter for user visibility
///
/// ### For URI Request Handlers (Wallets)
///
/// - **NEVER** automatically sign transactions without explicit user consent
/// - **ALWAYS** verify signatures before displaying `origin_domain` to users
/// - **ALWAYS** validate that `origin_domain` is a fully qualified domain name
/// - Fetch and verify stellar.toml from the origin domain before processing
/// - Display ALL transaction details to users before signing
/// - Alert users when signing URIs without `origin_domain` and `signature` (unsigned URIs)
/// - Cache `URI_REQUEST_SIGNING_KEY` per domain and alert users if it changes
/// - Maintain a denylist of known malicious addresses
/// - Use fonts that clearly distinguish similar characters to prevent homograph attacks
/// - Alert users when transacting with a new `origin_domain` for the first time
///
/// ### Common Security Threats
///
/// 1. **URI Request Modification**: Unsigned URIs can be modified by attackers.
///    Always verify signatures or warn users about unsigned requests.
///
/// 2. **URI Request Hijacking**: Valid signed URIs can be replaced entirely by attackers.
///    Display `origin_domain` prominently when signature verification succeeds.
///
/// 3. **Domain Compromise**: If a domain's signing key is compromised, attackers can
///    create valid signed URIs. Track signing key changes per domain.
///
/// 4. **Homograph Attacks**: Malicious domains can use similar-looking characters
///    (e.g., replacing 'l' with 'I'). Use clear fonts for domain display.
///
/// ## Usage Examples
///
/// ### Generating a Signed Transaction Request URI
///
/// ```dart
/// final uriScheme = URIScheme();
/// final sdk = StellarSDK.TESTNET;
///
/// // Build and sign the transaction
/// final sourceKeypair = KeyPair.fromSecretSeed('S...');
/// final transaction = TransactionBuilder(account)
///     .addOperation(PaymentOperationBuilder(destination, Asset.NATIVE, '10').build())
///     .build();
/// transaction.sign(sourceKeypair, Network.TESTNET);
///
/// // Generate the URI
/// final uri = uriScheme.generateSignTransactionURI(
///   transaction.toEnvelopeXdrBase64(),
///   callback: 'url:https://example.com/callback',
///   message: 'Payment for order #12345',
///   networkPassphrase: Network.TESTNET.networkPassphrase,
///   originDomain: 'example.com',
/// );
///
/// // Sign the URI with your domain's signing key
/// final signedUri = uriScheme.addSignature(uri, domainSigningKeypair);
/// ```
///
/// ### Parsing and Validating a URI Request
///
/// ```dart
/// final uriScheme = URIScheme();
/// final uri = 'web+stellar:tx?xdr=...&origin_domain=example.com&signature=...';
///
/// // Validate and verify signature against origin domain's stellar.toml
/// final validationResult = await uriScheme.isValidSep7SignedUrl(uri);
/// if (validationResult.result) {
///   // URI is valid and signature verified
///   final parsed = uriScheme.tryParseSep7Url(uri);
///   if (parsed != null) {
///     final xdr = parsed.queryParameters['xdr'];
///     final transaction = AbstractTransaction.fromEnvelopeXdrString(xdr);
///     // Display transaction details to user and request signature
///   }
/// } else {
///   // Invalid URI or signature verification failed
///   print('Validation failed: ${validationResult.reason}');
/// }
/// ```
///
/// ### Verifying Signature with Known Public Key
///
/// ```dart
/// final uriScheme = URIScheme();
/// final uri = 'web+stellar:tx?xdr=...&signature=...';
/// final signerPublicKey = 'GABC...'; // From stellar.toml
///
/// if (uriScheme.verifySignature(uri, signerPublicKey)) {
///   // Signature is valid
/// } else {
///   // Signature verification failed
/// }
/// ```
///
/// ### Generating a Payment Request URI
///
/// ```dart
/// final uriScheme = URIScheme();
///
/// final paymentUri = uriScheme.generatePayOperationURI(
///   'GABC...', // destination account
///   amount: '100.50',
///   assetCode: 'USD',
///   assetIssuer: 'GDEF...',
///   memo: 'Invoice #12345',
///   memoType: 'MEMO_TEXT',
///   message: 'Payment for premium subscription',
///   callback: 'url:https://example.com/payment-callback',
/// );
/// ```
///
/// ## Reference
///
/// See the full SEP-0007 specification at:
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

  static const replacementHintDelimiter = ";";
  static const replacementIdDelimiter = ":";
  static const replacementListDelimiter = ",";

  static int messageMaxLength = 300;
  static int maxAllowedChainingNestedLevels = 7;

  late http.Client httpClient;

  /// Optional HTTP request headers to include when fetching stellar.toml files.
  ///
  /// These headers will be included in HTTP requests made by [isValidSep7SignedUrl]
  /// when fetching the origin domain's stellar.toml file.
  Map<String, String>? httpRequestHeaders;

  /// Creates a new URIScheme instance.
  ///
  /// **Parameters:**
  ///
  /// - [httpClient]: Optional custom HTTP client for making requests. If not provided,
  ///   a default [http.Client] will be created. Useful for testing or custom HTTP
  ///   configurations (e.g., proxy settings, timeouts).
  ///
  /// - [httpRequestHeaders]: Optional HTTP headers to include in stellar.toml requests.
  ///   These headers will be used when [isValidSep7SignedUrl] fetches the origin domain's
  ///   stellar.toml file. Useful for adding custom headers like authentication tokens
  ///   or user agents.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// // Default configuration
  /// final uriScheme = URIScheme();
  ///
  /// // With custom headers
  /// final uriSchemeWithHeaders = URIScheme(
  ///   httpRequestHeaders: {
  ///     'User-Agent': 'MyWallet/1.0',
  ///     'Accept': 'text/plain',
  ///   },
  /// );
  ///
  /// // With custom HTTP client (for testing)
  /// final mockClient = MockClient((request) async {
  ///   return Response('...', 200);
  /// });
  /// final uriSchemeWithMock = URIScheme(httpClient: mockClient);
  /// ```
  URIScheme({http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient ?? http.Client();
  }

  /// Generates a SEP-0007 compliant URI for the `tx` operation to request transaction signing.
  ///
  /// Creates a `web+stellar:tx?...` URI that can be used to request a wallet to sign
  /// the provided transaction. The URI can optionally include callback URLs, replacement
  /// hints, and signing constraints.
  ///
  /// **Parameters:**
  ///
  /// - [transactionEnvelopeXdrBase64]: The transaction envelope in base64-encoded XDR format
  ///   (required). This should be the output of `transaction.toEnvelopeXdrBase64()`.
  ///   The transaction will be URL-encoded in the generated URI.
  ///
  /// - [replace]: Optional URL-decoded string identifying fields to be replaced in the XDR
  ///   using Txrep (SEP-0011) representation. Format:
  ///   `field1:id1,field2:id2;id1:hint1,id2:hint2`. Example:
  ///   `sourceAccount:X,operations[0].destination:Y;X:source account,Y:destination`.
  ///   This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [callback]: Optional callback URL (URL-decoded). If omitted, the wallet should submit
  ///   the signed transaction directly to the Stellar network. If present, must be prefixed
  ///   with `url:` (e.g., `url:https://example.com/callback`). The wallet will POST the
  ///   signed XDR to this URL with Content-Type `application/x-www-form-urlencoded`.
  ///   This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [publicKey]: Optional public key (Stellar account ID) specifying which key the wallet
  ///   should use for signing. Useful for multisig coordination. Must be a valid Stellar
  ///   account ID (G...). This parameter should NOT be URL-encoded.
  ///
  /// - [chain]: Optional SEP-0007 URI that spawned this request. Used to forward or wrap
  ///   existing SEP-0007 requests. Can be nested up to 7 levels deep. This parameter
  ///   should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [message]: Optional message (max 300 characters) to display to the user in their
  ///   wallet. Different from the transaction memo - this message is NOT recorded on-chain.
  ///   Use this to provide context about the transaction (e.g., "Payment for order #12345").
  ///   This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [networkPassphrase]: Optional network passphrase. Only required for networks other
  ///   than the public Stellar network. Use `Network.TESTNET.networkPassphrase` for testnet.
  ///   This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [originDomain]: Optional fully qualified domain name of the URI request originator
  ///   (e.g., "example.com"). When provided with [signature], wallets will verify the
  ///   signature and display this domain to users. This enables domain verification and
  ///   establishes trust. This parameter should NOT be URL-encoded.
  ///
  /// - [signature]: Optional base64-encoded signature of the URI request. Should be generated
  ///   using the private key corresponding to the `URI_REQUEST_SIGNING_KEY` in the domain's
  ///   stellar.toml file. Use [addSignature] to sign a URI. This parameter should NOT be
  ///   URL-encoded (encoding is handled automatically).
  ///
  /// **Returns:** A SEP-0007 compliant URI string starting with `web+stellar:tx?` with all
  /// parameters properly URL-encoded.
  ///
  /// **Security Note:** For production use, always include [originDomain] and [signature]
  /// parameters, or warn users that the URI is unsigned. Unsigned URIs are equivalent to
  /// using HTTP instead of HTTPS and can be modified by attackers.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uri = uriScheme.generateSignTransactionURI(
  ///   transaction.toEnvelopeXdrBase64(),
  ///   callback: 'url:https://example.com/callback',
  ///   publicKey: 'GAU2ZSYYEYO5S5ZQSMMUENJ2TANY4FPXYGGIMU6GMGKTNVDG5QYFW6JS',
  ///   message: 'Payment for order #24',
  ///   networkPassphrase: Network.TESTNET.networkPassphrase,
  ///   originDomain: 'example.com',
  /// );
  /// // Sign the URI before distributing
  /// final signedUri = uriScheme.addSignature(uri, domainSigningKeypair);
  /// ```
  ///
  /// See also:
  /// - [generatePayOperationURI] for payment-specific URIs
  /// - [addSignature] for signing generated URIs
  /// - [isValidSep7Url] for validating URIs
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

  /// Generates a SEP-0007 compliant URI for the `pay` operation to request a payment.
  ///
  /// Creates a `web+stellar:pay?...` URI that requests a payment to a specific destination
  /// with a specific asset, regardless of the source asset used by the payer. The wallet
  /// may use path payments if the payer wants to pay with a different asset.
  ///
  /// The `pay` operation is more flexible than `tx` with `replace` parameters because it
  /// specifies what the payee receives rather than the exact payment mechanism. The wallet
  /// can choose the optimal payment path.
  ///
  /// **Parameters:**
  ///
  /// - [destinationAccountId]: The destination Stellar address (required). Can be a standard
  ///   account ID (G...), a muxed account ID (M...), or a contract ID (C...). This is the
  ///   account that will receive the payment.
  ///
  /// - [amount]: Optional amount the destination will receive. If omitted, the wallet should
  ///   prompt the user to enter the amount. Useful for donation scenarios where the amount
  ///   is flexible. Format: decimal string (e.g., "100.50").
  ///
  /// - [assetCode]: Optional asset code the destination will receive. If omitted, defaults
  ///   to XLM (native asset). Maximum length is 12 characters. Examples: "USD", "EUR", "BTC".
  ///
  /// - [assetIssuer]: Optional account ID of the asset issuer. Required if [assetCode] is
  ///   provided (except for XLM). Must be a valid Stellar account ID (G...).
  ///
  /// - [memo]: Optional memo to include in the payment transaction. Memos of type `MEMO_HASH`
  ///   and `MEMO_RETURN` should be base64-encoded. Memos of type `MEMO_TEXT` should be plain
  ///   text. This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [memoType]: Optional memo type. Must be one of: `MEMO_TEXT`, `MEMO_ID`, `MEMO_HASH`,
  ///   or `MEMO_RETURN`. Required if [memo] is provided.
  ///
  /// - [callback]: Optional callback URL (URL-decoded). If omitted, the wallet should submit
  ///   the signed transaction directly to the Stellar network. If present, must be prefixed
  ///   with `url:` (e.g., `url:https://example.com/callback`). The wallet will POST the
  ///   signed XDR to this URL with Content-Type `application/x-www-form-urlencoded`.
  ///   This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [message]: Optional message (max 300 characters) to display to the user in their
  ///   wallet. Different from [memo] - this message is NOT recorded on-chain. Use this
  ///   to provide context about the payment (e.g., "Payment for premium subscription").
  ///   This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [networkPassphrase]: Optional network passphrase. Only required for networks other
  ///   than the public Stellar network. Use `Network.TESTNET.networkPassphrase` for testnet.
  ///   This parameter should NOT be URL-encoded (encoding is handled automatically).
  ///
  /// - [originDomain]: Optional fully qualified domain name of the URI request originator
  ///   (e.g., "example.com"). When provided with [signature], wallets will verify the
  ///   signature and display this domain to users. This enables domain verification and
  ///   establishes trust. This parameter should NOT be URL-encoded.
  ///
  /// - [signature]: Optional base64-encoded signature of the URI request. Should be generated
  ///   using the private key corresponding to the `URI_REQUEST_SIGNING_KEY` in the domain's
  ///   stellar.toml file. Use [addSignature] to sign a URI. This parameter should NOT be
  ///   URL-encoded (encoding is handled automatically).
  ///
  /// **Returns:** A SEP-0007 compliant URI string starting with `web+stellar:pay?` with all
  /// parameters properly URL-encoded.
  ///
  /// **Security Note:** For production use, always include [originDomain] and [signature]
  /// parameters to enable domain verification and establish trust with users.
  ///
  /// **Example 1 - Simple XLM payment request:**
  ///
  /// ```dart
  /// final uri = uriScheme.generatePayOperationURI(
  ///   'GCALNQQBXAPZ2WIRSDDBMSTAKCUH5SG6U76YBFLQLIXJTF7FE5AX7AOO',
  ///   amount: '120.1234567',
  ///   memo: 'Invoice payment',
  ///   memoType: 'MEMO_TEXT',
  ///   message: 'Pay with lumens',
  /// );
  /// ```
  ///
  /// **Example 2 - Asset payment with callback:**
  ///
  /// ```dart
  /// final uri = uriScheme.generatePayOperationURI(
  ///   'GCALNQQBXAPZ2WIRSDDBMSTAKCUH5SG6U76YBFLQLIXJTF7FE5AX7AOO',
  ///   amount: '120.50',
  ///   assetCode: 'USD',
  ///   assetIssuer: 'GCRCUE2C5TBNIPYHMEP7NK5RWTT2WBSZ75CMARH7GDOHDDCQH3XANFOB',
  ///   callback: 'url:https://example.com/payment-callback',
  ///   message: 'Payment for order #12345',
  /// );
  /// ```
  ///
  /// See also:
  /// - [generateSignTransactionURI] for transaction-specific URIs
  /// - [addSignature] for signing generated URIs
  /// - [isValidSep7Url] for validating URIs
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
      queryParams[amountParameterName] = Uri.encodeComponent(amount);
    }

    if (assetCode != null) {
      queryParams[assetCodeParameterName] = Uri.encodeComponent(assetCode);
    }

    if (assetIssuer != null) {
      queryParams[assetIssuerParameterName] =
          Uri.encodeComponent(assetIssuer);
    }

    if (memo != null) {
      queryParams[memoParameterName] = Uri.encodeComponent(memo);
    }

    if (memoType != null) {
      queryParams[memoTypeParameterName] = Uri.encodeComponent(memoType);
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

  /// Signs and submits a transaction from a SEP-0007 URI.
  ///
  /// Extracts the transaction from the provided [sep7TxUrl], signs it with [signerKeyPair],
  /// and submits it either to the callback URL (if specified in the URI) or directly to the
  /// Stellar network.
  ///
  /// **Parameters:**
  ///
  /// - [sep7TxUrl]: A valid SEP-0007 URI with operation type `tx` (required). Must include
  ///   a valid `xdr` query parameter containing a transaction envelope. The URI should be
  ///   validated before calling this method.
  ///
  /// - [signerKeyPair]: The keypair to use for signing the transaction (required). This should
  ///   be the user's keypair that they want to use to authorize the transaction.
  ///
  /// - [network]: Optional network to use for signing and submission. If omitted, defaults to
  ///   the public Stellar network. Use `Network.TESTNET` for testnet transactions.
  ///
  /// **Returns:** A [SubmitUriSchemeTransactionResponse] containing either:
  /// - `submitTransactionResponse`: If submitted directly to Stellar network
  /// - `response`: If submitted to a callback URL
  ///
  /// **Throws:**
  /// - [ArgumentError] if [sep7TxUrl] is not a valid SEP-0007 URI
  /// - [ArgumentError] if [sep7TxUrl] operation type is not `tx`
  /// - [ArgumentError] if [sep7TxUrl] does not contain a valid `xdr` parameter
  /// - [ArgumentError] if the XDR cannot be parsed as a valid transaction
  /// - [ArgumentError] if the transaction type is unsupported
  ///
  /// **Behavior:**
  ///
  /// 1. If the URI contains a `callback` parameter starting with `url:`, the signed transaction
  ///    is POSTed to that URL with Content-Type `application/x-www-form-urlencoded` and the
  ///    signed XDR in the `xdr` field.
  ///
  /// 2. If no `callback` parameter exists, the signed transaction is submitted directly to
  ///    the Stellar network using the appropriate SDK (PUBLIC or TESTNET).
  ///
  /// **Security Note:** This method does NOT verify the URI signature or origin domain.
  /// Wallets should validate the URI using [isValidSep7SignedUrl] before calling this method
  /// and display transaction details to the user for approval.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uriScheme = URIScheme();
  /// final uri = 'web+stellar:tx?xdr=...&callback=url:https://example.com/callback';
  ///
  /// // Validate URI first
  /// final validationResult = await uriScheme.isValidSep7SignedUrl(uri);
  /// if (!validationResult.result) {
  ///   print('Invalid URI: ${validationResult.reason}');
  ///   return;
  /// }
  ///
  /// // Display transaction details to user and get approval...
  ///
  /// // Sign and submit
  /// final userKeypair = KeyPair.fromSecretSeed('S...');
  /// final response = await uriScheme.signAndSubmitTransaction(
  ///   uri,
  ///   userKeypair,
  ///   network: Network.TESTNET,
  /// );
  ///
  /// if (response.submitTransactionResponse != null) {
  ///   print('Transaction hash: ${response.submitTransactionResponse!.hash}');
  /// } else if (response.response != null) {
  ///   print('Callback response: ${response.response!.statusCode}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [isValidSep7SignedUrl] for validating signed URIs
  /// - [tryParseSep7Url] for parsing URI parameters
  /// - [verifySignature] for signature verification
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

  /// Signs a SEP-0007 URI by adding a signature parameter.
  ///
  /// Takes an unsigned SEP-0007 URI, signs it with the provided [signerKeypair], and
  /// appends the `signature` parameter. This enables domain verification when the URI
  /// includes an `origin_domain` parameter.
  ///
  /// **Parameters:**
  ///
  /// - [sep7Url]: A valid SEP-0007 URI to sign (required). Must not already contain a
  ///   `signature` parameter. The URI should include an `origin_domain` parameter for
  ///   proper domain verification.
  ///
  /// - [signerKeypair]: The keypair to use for signing (required). This should be the
  ///   keypair corresponding to the `URI_REQUEST_SIGNING_KEY` in your domain's stellar.toml
  ///   file. The private key should be kept secure and never exposed in client-side code.
  ///
  /// **Returns:** The signed SEP-0007 URI with the `signature` parameter appended. The
  /// signature value is base64-encoded and URL-encoded.
  ///
  /// **Throws:**
  /// - [ArgumentError] if [sep7Url] is not a valid SEP-0007 URI
  /// - [ArgumentError] if [sep7Url] already contains a `signature` parameter
  ///
  /// **Signing Process:**
  ///
  /// 1. The URI (without the signature parameter) is prefixed with `stellar.sep.7 - URI Scheme`
  /// 2. A 36-byte header is prepended (35 zero bytes followed by 0x04)
  /// 3. The resulting payload is signed using the provided keypair
  /// 4. The signature is base64-encoded, then URL-encoded, and appended as the `signature` parameter
  ///
  /// **Security Requirements:**
  ///
  /// - Your domain's stellar.toml file MUST contain a `URI_REQUEST_SIGNING_KEY` field
  ///   with the public key corresponding to [signerKeypair]
  /// - The signing keypair's private key must be kept secure on your server
  /// - Never expose the private signing key in client-side code or version control
  /// - Use HTTPS for all stellar.toml file hosting
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uriScheme = URIScheme();
  ///
  /// // Generate an unsigned URI
  /// final unsignedUri = uriScheme.generatePayOperationURI(
  ///   'GCALNQQBXAPZ2WIRSDDBMSTAKCUH5SG6U76YBFLQLIXJTF7FE5AX7AOO',
  ///   amount: '100',
  ///   message: 'Payment for order #12345',
  ///   originDomain: 'example.com',
  /// );
  ///
  /// // Sign the URI with your domain's signing key
  /// // This key must match the URI_REQUEST_SIGNING_KEY in your stellar.toml
  /// final domainSigningKey = KeyPair.fromSecretSeed('S...');
  /// final signedUri = uriScheme.addSignature(unsignedUri, domainSigningKey);
  ///
  /// // The signedUri can now be distributed to users
  /// // Wallets will verify the signature and display 'example.com' as the origin
  /// ```
  ///
  /// **Stellar.toml Configuration:**
  ///
  /// Your domain's stellar.toml file should contain:
  ///
  /// ```toml
  /// URI_REQUEST_SIGNING_KEY = "GBCD..." # Public key of domainSigningKey
  /// ```
  ///
  /// See also:
  /// - [verifySignature] for verifying signatures with a known public key
  /// - [isValidSep7SignedUrl] for complete URI validation including signature verification
  /// - [generateSignTransactionURI] for creating transaction URIs
  /// - [generatePayOperationURI] for creating payment URIs
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

  /// Parses a SEP-0007 URI and extracts its components.
  ///
  /// Validates the provided [url] and extracts the operation type and query parameters
  /// if it is a valid SEP-0007 URI. This method does NOT verify signatures.
  ///
  /// **Parameters:**
  ///
  /// - [url]: The SEP-0007 URI to parse (required). Should start with `web+stellar:`.
  ///
  /// **Returns:**
  /// - [ParsedSep7UrlResult] containing the operation type and URL-decoded query parameters
  ///   if the URI is valid
  /// - `null` if the URI is invalid or malformed
  ///
  /// **Note:** This method validates the URI structure but does NOT verify:
  /// - The `signature` parameter (use [verifySignature] or [isValidSep7SignedUrl])
  /// - The `origin_domain` parameter
  /// - The contents of the XDR transaction
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uriScheme = URIScheme();
  /// final uri = 'web+stellar:pay?destination=GABC...&amount=100&asset_code=USD';
  ///
  /// final parsed = uriScheme.tryParseSep7Url(uri);
  /// if (parsed != null) {
  ///   print('Operation: ${parsed.operationType}'); // Output: pay
  ///   print('Destination: ${parsed.queryParameters['destination']}'); // Output: GABC...
  ///   print('Amount: ${parsed.queryParameters['amount']}'); // Output: 100
  /// } else {
  ///   print('Invalid URI');
  /// }
  /// ```
  ///
  /// See also:
  /// - [isValidSep7Url] for detailed validation with error reasons
  /// - [isValidSep7SignedUrl] for complete validation including signature verification
  /// - [verifySignature] for signature verification with a known public key
  ParsedSep7UrlResult? tryParseSep7Url(String url) {
    final validationResult = isValidSep7Url(url);
    if (!validationResult.result) {
      return null;
    }
    var uri = Uri.tryParse(url);
    if (uri != null) {
      // must be modifiable
      Map<String,String> queryParameters = {};
      uri.queryParameters.forEach((key, value) {
        queryParameters[key] = value;
      });
      return ParsedSep7UrlResult(uri.pathSegments.first, queryParameters);
    }
    return null;
  }

  /// Validates a SEP-0007 URI structure without verifying the signature.
  ///
  /// Performs comprehensive validation of the URI structure, parameter formats, and values
  /// according to SEP-0007 specifications. This method does NOT verify the `signature`
  /// parameter or fetch the origin domain's stellar.toml file.
  ///
  /// **Parameters:**
  ///
  /// - [url]: The SEP-0007 URI to validate (required).
  ///
  /// **Returns:** An [IsValidSep7UrlResult] containing:
  /// - `result`: `true` if the URI is valid, `false` otherwise
  /// - `reason`: A description of why the URI is invalid (only present if result is `false`)
  ///
  /// **Validation Checks:**
  ///
  /// - URI starts with `web+stellar:`
  /// - Contains exactly one path segment (operation type)
  /// - Operation type is either `tx` or `pay`
  /// - Required parameters are present for the operation type:
  ///   - `tx` operation: requires `xdr` parameter with valid transaction envelope
  ///   - `pay` operation: requires `destination` parameter with valid Stellar address
  /// - Parameter formats are correct:
  ///   - Asset codes are 12 characters or less
  ///   - Account IDs are valid Stellar addresses
  ///   - Memos match their specified types
  ///   - Message length is 300 characters or less
  ///   - Origin domain is a fully qualified domain name
  ///   - Chain parameter nesting is 7 levels or less
  /// - Operation-specific parameters match the operation type
  ///
  /// **Note:** This method does NOT verify:
  /// - The `signature` parameter (use [verifySignature] or [isValidSep7SignedUrl])
  /// - The stellar.toml file of the origin domain
  /// - Whether the signature matches the origin domain's signing key
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uriScheme = URIScheme();
  /// final uri = 'web+stellar:pay?destination=GABC...&amount=100';
  ///
  /// final result = uriScheme.isValidSep7Url(uri);
  /// if (result.result) {
  ///   print('URI is valid');
  ///   // Proceed with parsing or signature verification
  /// } else {
  ///   print('URI is invalid: ${result.reason}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [isValidSep7SignedUrl] for complete validation including signature verification
  /// - [verifySignature] for signature verification with a known public key
  /// - [tryParseSep7Url] for parsing valid URIs
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

  /// Validates a signed SEP-0007 URI including signature verification.
  ///
  /// Performs complete validation of a SEP-0007 URI including:
  /// 1. URI structure validation (via [isValidSep7Url])
  /// 2. Presence of required `origin_domain` and `signature` parameters
  /// 3. Fetching the origin domain's stellar.toml file
  /// 4. Extracting the `URI_REQUEST_SIGNING_KEY` from stellar.toml
  /// 5. Verifying the signature against the signing key
  ///
  /// **Parameters:**
  ///
  /// - [url]: The signed SEP-0007 URI to validate (required). Must include both
  ///   `origin_domain` and `signature` query parameters.
  ///
  /// **Returns:** An [IsValidSep7UrlResult] containing:
  /// - `result`: `true` if the URI is valid and properly signed, `false` otherwise
  /// - `reason`: A description of why the URI is invalid (only present if result is `false`)
  ///
  /// **Validation Process:**
  ///
  /// 1. Validates the URI structure using [isValidSep7Url]
  /// 2. Checks for `origin_domain` parameter (fully qualified domain name)
  /// 3. Checks for `signature` parameter
  /// 4. Fetches `https://<origin_domain>/.well-known/stellar.toml`
  /// 5. Extracts `URI_REQUEST_SIGNING_KEY` from the stellar.toml
  /// 6. Verifies the signature using the extracted public key
  ///
  /// **Security Note:** This method makes an HTTP request to fetch the stellar.toml file.
  /// Always use this method (or [verifySignature] with a cached key) before displaying
  /// the `origin_domain` to users or processing signed URIs.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uriScheme = URIScheme();
  /// final uri = 'web+stellar:pay?destination=GABC...&amount=100'
  ///     '&origin_domain=example.com&signature=...';
  ///
  /// final result = await uriScheme.isValidSep7SignedUrl(uri);
  /// if (result.result) {
  ///   // URI is valid and signature verified
  ///   // Safe to display origin_domain to user
  ///   print('Valid request from example.com');
  ///   // Parse and display transaction details
  /// } else {
  ///   // Signature verification failed or URI is invalid
  ///   print('Invalid or improperly signed URI: ${result.reason}');
  ///   // DO NOT display origin_domain to user
  ///   // DO NOT allow user to sign the transaction
  /// }
  /// ```
  ///
  /// **Wallet Implementation Requirements:**
  ///
  /// Per SEP-0007 security best practices, wallets MUST:
  /// - Call this method before displaying `origin_domain` to users
  /// - NOT display `origin_domain` if validation fails
  /// - NOT allow users to sign transactions if validation fails
  /// - Alert users if the `URI_REQUEST_SIGNING_KEY` has changed for a known domain
  /// - Cache signing keys per domain to detect key changes
  ///
  /// See also:
  /// - [verifySignature] for signature verification with a known public key
  /// - [isValidSep7Url] for structure validation without signature verification
  /// - [tryParseSep7Url] for parsing valid URIs
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

  /// Verifies the signature of a SEP-0007 URI using a known public key.
  ///
  /// Validates that the provided [sep7Url] was signed by the holder of the private key
  /// corresponding to [signerPublicKey]. This method is useful when you already know the
  /// signing key (e.g., from a cached stellar.toml) and don't need to fetch it.
  ///
  /// **Parameters:**
  ///
  /// - [sep7Url]: The signed SEP-0007 URI to verify (required). Must be a valid SEP-0007
  ///   URI that includes a `signature` parameter.
  ///
  /// - [signerPublicKey]: The expected signer's public key (required). Must be a valid
  ///   Stellar account ID (G...). This should be the `URI_REQUEST_SIGNING_KEY` from the
  ///   origin domain's stellar.toml file.
  ///
  /// **Returns:**
  /// - `true` if the signature is valid and was created by the holder of [signerPublicKey]
  /// - `false` if:
  ///   - [signerPublicKey] is not a valid Stellar account ID
  ///   - [sep7Url] is not a valid SEP-0007 URI
  ///   - [sep7Url] does not contain a `signature` parameter
  ///   - The signature verification fails (wrong signer or modified URI)
  ///
  /// **Verification Process:**
  ///
  /// 1. Validates the URI structure
  /// 2. Extracts the signature parameter
  /// 3. Removes the signature from the URI to get the signed payload
  /// 4. Verifies the signature using the provided public key
  ///
  /// **Use Cases:**
  ///
  /// - When you have a cached `URI_REQUEST_SIGNING_KEY` for a domain
  /// - When you want to avoid making an HTTP request to fetch stellar.toml
  /// - When implementing custom signing key management
  ///
  /// **Security Note:** This method does NOT fetch the stellar.toml file or validate the
  /// `origin_domain`. Callers are responsible for ensuring [signerPublicKey] comes from a
  /// trusted source (e.g., the domain's verified stellar.toml file).
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uriScheme = URIScheme();
  /// final uri = 'web+stellar:pay?destination=GABC...&amount=100&signature=...';
  ///
  /// // Use a cached or known signing key
  /// final signingKey = 'GBCD...'; // From stellar.toml
  ///
  /// if (uriScheme.verifySignature(uri, signingKey)) {
  ///   print('Signature is valid');
  ///   // URI was signed by the holder of signingKey
  /// } else {
  ///   print('Signature is invalid or URI is malformed');
  ///   // DO NOT trust this URI
  /// }
  /// ```
  ///
  /// **Wallet Implementation:**
  ///
  /// Wallets should cache `URI_REQUEST_SIGNING_KEY` values per domain and compare them
  /// to detect key changes:
  ///
  /// ```dart
  /// final cachedKey = cache.getSigningKey('example.com');
  /// final currentKey = await fetchSigningKeyFromToml('example.com');
  ///
  /// if (cachedKey != null && cachedKey != currentKey) {
  ///   // Alert user: signing key has changed!
  /// }
  ///
  /// if (uriScheme.verifySignature(uri, currentKey)) {
  ///   // Signature is valid with current key
  /// }
  /// ```
  ///
  /// See also:
  /// - [isValidSep7SignedUrl] for complete validation including stellar.toml fetching
  /// - [addSignature] for signing URIs
  /// - [isValidSep7Url] for structure validation without signature verification
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
        "&$signatureParameterName=${Uri.encodeComponent(signature)}", "");
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

  /// Converts a list of replacement objects to a SEP-0007 `replace` parameter string.
  ///
  /// Transforms a list of [UriSchemeReplacement] objects into a properly formatted string
  /// suitable for use as the `replace` query parameter in a SEP-0007 `tx` operation URI.
  ///
  /// **Parameters:**
  ///
  /// - [replacements]: List of replacement specifications (required). Each replacement
  ///   identifies a field in the transaction XDR that should be filled in by the wallet.
  ///
  /// **Returns:** A formatted string using the Txrep (SEP-0011) representation format:
  /// `field1:id1,field2:id2;id1:hint1,id2:hint2`
  ///
  /// The output string has two sections separated by a semicolon (;):
  /// 1. Field-to-ID mappings: Links Txrep field paths to reference identifiers
  /// 2. ID-to-Hint mappings: Provides user-friendly descriptions for each identifier
  ///
  /// **Format Details:**
  ///
  /// - Fields and IDs are separated by colons (:)
  /// - Multiple field:id pairs are separated by commas (,)
  /// - Field mappings and hint mappings are separated by a semicolon (;)
  /// - Duplicate hints are automatically deduplicated
  /// - The output is NOT URL-encoded (encoding should be done separately)
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final replacements = [
  ///   UriSchemeReplacement('X', 'sourceAccount', 'account from where you pay fees'),
  ///   UriSchemeReplacement('Y', 'operations[0].destination', 'account receiving tokens'),
  ///   UriSchemeReplacement('Y', 'operations[1].destination', 'account receiving tokens'),
  /// ];
  ///
  /// final replaceString = uriScheme.uriSchemeReplacementsToString(replacements);
  /// // Output: "sourceAccount:X,operations[0].destination:Y,operations[1].destination:Y;X:account from where you pay fees,Y:account receiving tokens"
  ///
  /// // Use in a URI (with URL encoding)
  /// final uri = uriScheme.generateSignTransactionURI(
  ///   xdr,
  ///   replace: replaceString, // Will be URL-encoded automatically
  /// );
  /// ```
  ///
  /// **Txrep Field Path Format:**
  ///
  /// - Use dot notation for nested fields: `operations[0].sourceAccount`
  /// - Array indices are specified in brackets: `operations[0]`, `operations[1]`
  /// - Do NOT include the `tx.` prefix
  /// - Do NOT include metadata fields like `_present` or `len`
  ///
  /// See also:
  /// - [uriSchemeReplacementsFromString] for parsing replacement strings
  /// - [generateSignTransactionURI] for using replacements in URIs
  /// - SEP-0011 (Txrep): https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md
  String uriSchemeReplacementsToString(
      List<UriSchemeReplacement> replacements) {
    if (replacements.isEmpty) {
      return "";
    }

    String fields = "";
    String hints = "";
    replacements.forEach((var item) {
      fields +=
          "${item.path}${replacementIdDelimiter}${item.id}${replacementListDelimiter}";
      final nextHint = "${item.id}${replacementIdDelimiter}${item.hint}${replacementListDelimiter}";
      if (!hints.contains(nextHint)) {
        hints += nextHint;
      }
    });

    return fields.substring(0, fields.length - 1) +
        replacementHintDelimiter +
        hints.substring(0, hints.length - 1);
  }

  /// Parses a SEP-0007 `replace` parameter string into replacement objects.
  ///
  /// Converts a URL-decoded `replace` parameter string from a SEP-0007 URI into a list
  /// of [UriSchemeReplacement] objects for easier programmatic access.
  ///
  /// **Parameters:**
  ///
  /// - [replace]: A URL-decoded `replace` parameter string (required). Should be in the
  ///   format: `field1:id1,field2:id2;id1:hint1,id2:hint2`
  ///
  /// **Returns:** A list of [UriSchemeReplacement] objects, each containing:
  /// - `id`: The reference identifier
  /// - `path`: The Txrep field path to replace
  /// - `hint`: A user-friendly description for the field
  ///
  /// Returns an empty list if the input string is empty.
  ///
  /// **Format Details:**
  ///
  /// The input string has two sections separated by a semicolon (;):
  /// 1. Field-to-ID mappings: `field1:id1,field2:id2,...`
  /// 2. ID-to-Hint mappings: `id1:hint1,id2:hint2,...`
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final uriScheme = URIScheme();
  /// final uri = 'web+stellar:tx?xdr=...&replace=sourceAccount%3AX%3B...';
  ///
  /// // Parse the URI
  /// final parsed = uriScheme.tryParseSep7Url(uri);
  /// if (parsed != null) {
  ///   final replaceParam = parsed.queryParameters['replace'];
  ///   if (replaceParam != null) {
  ///     // Parse replacement specifications
  ///     final replacements = uriScheme.uriSchemeReplacementsFromString(replaceParam);
  ///
  ///     for (var replacement in replacements) {
  ///       print('Field: ${replacement.path}');
  ///       print('ID: ${replacement.id}');
  ///       print('Hint: ${replacement.hint}');
  ///       // Prompt user to provide value for this field
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// **Use Case:**
  ///
  /// Wallets use this method to extract replacement specifications from a URI, then
  /// prompt the user to provide values for each field. The hints guide the user on
  /// what information is needed.
  ///
  /// ```dart
  /// // Input string (URL-decoded):
  /// // "sourceAccount:X,operations[0].destination:Y;X:account paying fees,Y:receiving account"
  ///
  /// final replacements = uriScheme.uriSchemeReplacementsFromString(replaceString);
  /// // Returns:
  /// // [
  /// //   UriSchemeReplacement('X', 'sourceAccount', 'account paying fees'),
  /// //   UriSchemeReplacement('Y', 'operations[0].destination', 'receiving account'),
  /// // ]
  /// ```
  ///
  /// See also:
  /// - [uriSchemeReplacementsToString] for converting replacement objects to strings
  /// - [tryParseSep7Url] for parsing complete URIs
  /// - SEP-0011 (Txrep): https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md
  List<UriSchemeReplacement> uriSchemeReplacementsFromString(String replace) {
    if (replace.length == 0) {
      return [];
    }

    final fieldsAndHints = replace.split(replacementHintDelimiter);
    var fieldsAndIds = List<String>.empty(growable: true);
    if (fieldsAndHints.isNotEmpty) {
      fieldsAndIds = fieldsAndHints.first.split(replacementListDelimiter);
    }
    var idsAndHints = List<String>.empty(growable: true);
    if (fieldsAndHints.length > 1) {
      idsAndHints = fieldsAndHints[1].split(replacementListDelimiter);
    }

    Map<String, String> fields = {};
    for (var item in fieldsAndIds) {
      final fieldAndId = item.split(replacementIdDelimiter);
      if (fieldAndId.length > 1) {
        fields[fieldAndId.first] = fieldAndId[1];
      }
    }

    Map<String, String> hints = {};
    for (var item in idsAndHints) {
      final idAndHint = item.split(replacementIdDelimiter);
      if (idAndHint.length > 1) {
        hints[idAndHint.first] = idAndHint[1];
      }
    }

    var result = List<UriSchemeReplacement>.empty(growable: true);
    fields.forEach((path, id) {
      String hint = hints[id] ?? "";
      result.add(UriSchemeReplacement(id, path, hint));
    });
    return result;
  }
}

/// Response from signing and submitting a SEP-0007 transaction URI.
///
/// Contains either a response from the Stellar network or from a callback URL,
/// depending on whether the URI included a `callback` parameter.
///
/// **Properties:**
///
/// - [submitTransactionResponse]: Present when the transaction was submitted directly
///   to the Stellar network (no callback URL in the URI). Contains the standard
///   Stellar transaction submission response including transaction hash and result.
///
/// - [response]: Present when the transaction was POSTed to a callback URL specified
///   in the URI. Contains the raw HTTP response from the callback endpoint.
///
/// **Example:**
///
/// ```dart
/// final response = await uriScheme.signAndSubmitTransaction(uri, keypair);
///
/// if (response.submitTransactionResponse != null) {
///   // Submitted directly to Stellar network
///   if (response.submitTransactionResponse!.success) {
///     print('Transaction hash: ${response.submitTransactionResponse!.hash}');
///   } else {
///     print('Transaction failed: ${response.submitTransactionResponse!.error}');
///   }
/// } else if (response.response != null) {
///   // Submitted to callback URL
///   print('Callback status: ${response.response!.statusCode}');
///   print('Callback body: ${response.response!.body}');
/// }
/// ```
///
/// See also:
/// - [URIScheme.signAndSubmitTransaction] which returns this type
class SubmitUriSchemeTransactionResponse {
  /// Response from submitting the transaction to the Stellar network.
  ///
  /// This is present when the URI did not include a `callback` parameter,
  /// so the transaction was submitted directly to the network.
  SubmitTransactionResponse? submitTransactionResponse;

  /// Response from submitting the transaction to a callback URL.
  ///
  /// This is present when the URI included a `callback` parameter starting
  /// with `url:`. The signed transaction XDR was POSTed to this URL.
  http.Response? response;

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

/// Result of validating a SEP-0007 URI.
///
/// Contains the validation outcome and an optional error reason.
///
/// **Properties:**
///
/// - [result]: `true` if the URI is valid, `false` otherwise
/// - [reason]: Human-readable description of why the URI is invalid (only present if result is `false`)
///
/// **Example:**
///
/// ```dart
/// final validationResult = uriScheme.isValidSep7Url(uri);
/// if (validationResult.result) {
///   print('URI is valid');
/// } else {
///   print('URI is invalid: ${validationResult.reason}');
/// }
/// ```
///
/// See also:
/// - [URIScheme.isValidSep7Url] which returns this type
/// - [URIScheme.isValidSep7SignedUrl] which also returns this type
class IsValidSep7UrlResult {
  /// True if the URI is valid according to SEP-0007 specifications.
  bool result;

  /// Human-readable description of why the URI is invalid.
  ///
  /// Only present when [result] is `false`. Provides specific details about
  /// what validation check failed (e.g., missing required parameter, invalid
  /// format, unsupported operation type).
  String? reason;

  IsValidSep7UrlResult({required this.result, this.reason});
}

/// Result of parsing a SEP-0007 URI.
///
/// Contains the extracted operation type and URL-decoded query parameters.
///
/// **Properties:**
///
/// - [operationType]: The operation type from the URI path segment. Either `tx` or `pay`.
/// - [queryParameters]: All query parameters with values URL-decoded for easy access.
///
/// **Example:**
///
/// ```dart
/// final parsed = uriScheme.tryParseSep7Url(uri);
/// if (parsed != null) {
///   if (parsed.operationType == 'tx') {
///     final xdr = parsed.queryParameters['xdr'];
///     final callback = parsed.queryParameters['callback'];
///     final message = parsed.queryParameters['msg'];
///     // Process transaction request...
///   } else if (parsed.operationType == 'pay') {
///     final destination = parsed.queryParameters['destination'];
///     final amount = parsed.queryParameters['amount'];
///     final assetCode = parsed.queryParameters['asset_code'];
///     // Process payment request...
///   }
/// }
/// ```
///
/// See also:
/// - [URIScheme.tryParseSep7Url] which returns this type
class ParsedSep7UrlResult {
  /// The operation type extracted from the URI path segment.
  ///
  /// Possible values are:
  /// - `tx`: Transaction signing request
  /// - `pay`: Payment request
  String operationType;

  /// URL-decoded query parameters from the URI.
  ///
  /// All parameter values are URL-decoded for immediate use. Common parameters include:
  ///
  /// For `tx` operations:
  /// - `xdr`: Transaction envelope in base64-encoded XDR format
  /// - `callback`: Optional callback URL
  /// - `replace`: Optional replacement specifications
  /// - `pubkey`: Optional public key constraint
  /// - `msg`: Optional message to display
  /// - `origin_domain`: Optional domain of the request originator
  /// - `signature`: Optional signature for domain verification
  ///
  /// For `pay` operations:
  /// - `destination`: Recipient address
  /// - `amount`: Optional payment amount
  /// - `asset_code`: Optional asset code (defaults to XLM)
  /// - `asset_issuer`: Optional asset issuer
  /// - `memo`: Optional transaction memo
  /// - `memo_type`: Optional memo type
  /// - `callback`: Optional callback URL
  /// - `msg`: Optional message to display
  /// - `origin_domain`: Optional domain of the request originator
  /// - `signature`: Optional signature for domain verification
  Map<String, String> queryParameters;

  ParsedSep7UrlResult(this.operationType, this.queryParameters);
}

/// Represents a field replacement specification for SEP-0007 `replace` parameters.
///
/// Specifies a field in a transaction XDR that should be replaced by the wallet,
/// using Txrep (SEP-0011) field path notation.
///
/// **Properties:**
///
/// - [id]: A reference identifier used to link field paths with hints
/// - [path]: The Txrep field path in the transaction XDR to be replaced
/// - [hint]: A user-friendly description explaining what value is needed
///
/// **Example:**
///
/// ```dart
/// // Create replacement specifications
/// final replacements = [
///   UriSchemeReplacement(
///     'X',
///     'sourceAccount',
///     'account from where you want to pay fees',
///   ),
///   UriSchemeReplacement(
///     'Y',
///     'operations[0].destination',
///     'account that will receive the payment',
///   ),
/// ];
///
/// // Convert to replace parameter string
/// final replaceString = uriScheme.uriSchemeReplacementsToString(replacements);
///
/// // Use in a URI
/// final uri = uriScheme.generateSignTransactionURI(
///   xdr,
///   replace: replaceString,
/// );
/// ```
///
/// **Field Path Format:**
///
/// The [path] uses Txrep (SEP-0011) notation:
/// - Nested fields: `operations[0].sourceAccount`
/// - Array indices: `operations[0]`, `operations[1]`
/// - No `tx.` prefix
/// - No metadata fields (`_present`, `len`)
///
/// See also:
/// - [URIScheme.uriSchemeReplacementsToString] for converting to string format
/// - [URIScheme.uriSchemeReplacementsFromString] for parsing from string format
/// - SEP-0011 (Txrep): https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0011.md
class UriSchemeReplacement {
  /// Reference identifier linking this field to its hint.
  ///
  /// Multiple fields can share the same ID if they should be filled with
  /// the same value. For example, using 'Y' for both `operations[0].destination`
  /// and `operations[1].destination` means both operations will use the same
  /// destination account.
  String id;

  /// Txrep field path identifying which field in the transaction to replace.
  ///
  /// Uses SEP-0011 Txrep notation without the `tx.` prefix.
  /// Examples: `sourceAccount`, `operations[0].destination`, `memo.text`
  String path;

  /// User-friendly description explaining what value is needed for this field.
  ///
  /// Should be brief and clear to help users understand what information to provide.
  /// Examples: "account paying fees", "destination for payment", "your account ID"
  String hint;

  UriSchemeReplacement(this.id, this.path, this.hint);
}
