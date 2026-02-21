import 'package:http/http.dart' as http;
import '../../../stellar_flutter_sdk.dart';
import 'dart:async';
import 'dart:convert';

/// Service for interacting with SEP-0008 regulated assets.
///
/// Implements SEP-0008 version 1.7.4
///
/// SEP-0008 defines a protocol for regulated assets that require approval before
/// transactions can be submitted. This service handles the approval workflow including:
/// - Transaction submission to approval servers
/// - Action completions for KYC/AML requirements
/// - Authorization checks for regulated assets
///
/// Regulated assets workflow:
/// 1. Build and sign transaction normally
/// 2. Submit transaction to approval server
/// 3. Handle response (success, revised, pending, action_required, or rejected)
/// 4. Complete any required actions
/// 5. Resubmit if needed
/// 6. Submit approved transaction to Stellar network
///
/// Transaction Composition:
///
/// Compliant regulated asset transactions typically include authorization
/// and deauthorization operations to ensure accounts cannot perform
/// unapproved operations:
///
/// For operations allowing maintained offers:
/// 1. AllowTrust operation - fully authorize account A for asset X
/// 2. Account A manages offer to buy/sell X
/// 3. AllowTrust operation - set account A to AUTHORIZED_TO_MAINTAIN_LIABILITIES_FLAG
///
/// For operations without maintained offers:
/// 1. AllowTrust operation - fully authorize account A for asset X
/// 2. AllowTrust operation - fully authorize account B for asset X
/// 3. Payment from A to B
/// 4. AllowTrust operation - fully deauthorize account B for asset X
/// 5. AllowTrust operation - fully deauthorize account A for asset X
///
/// These patterns ensure transaction atomicity and prevent unauthorized operations.
///
/// Protocol Details:
///
/// The approval server must support CORS requests and accepts both
/// application/json and application/x-www-form-urlencoded content types.
/// Responses are always in application/json format.
///
/// Best Practices:
///
/// For Wallet Developers:
/// - Always inspect revised transactions and alert users if original operations
///   are changed
/// - Add upper time bounds to transactions to help issuers maintain consistency
/// - Expect any status response when resubmitting after completing actions
/// - Handle the possibility that approved transactions may still fail on submission
///
/// Understanding Revisions:
/// - Issuers may add authorization/deauthorization operations
/// - Issuers may add fee operations (e.g., 0.1 GOAT to issuer account)
/// - Core operations should never be modified (amounts, destinations, etc.)
/// - If a core operation cannot be made compliant, expect rejection instead
///
/// Example:
/// ```dart
/// import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
///
/// // Initialize from stellar.toml
/// var service = await RegulatedAssetsService.fromDomain('example.com');
///
/// // Check if asset requires authorization
/// bool required = await service.authorizationRequired(regulatedAsset);
///
/// // Build and sign transaction
/// var tx = TransactionBuilder(sourceAccount)
///   .addOperation(paymentOperation)
///   .build();
/// tx.sign(keyPair, Network.TESTNET);
///
/// // Submit for approval
/// var response = await service.postTransaction(
///   tx.toEnvelopeXdrBase64(),
///   regulatedAsset.approvalServer
/// );
///
/// // Handle all possible responses
/// if (response is PostTransactionSuccess) {
///   await sdk.submitTransactionEnvelopeXdrBase64(response.tx);
/// } else if (response is PostTransactionRevised) {
///   // Show user the changes in response.message
///   // Get user confirmation, then submit revised transaction
///   await sdk.submitTransactionEnvelopeXdrBase64(response.tx);
/// } else if (response is PostTransactionPending) {
///   // Wait for response.timeout milliseconds, then retry
///   await Future.delayed(Duration(milliseconds: response.timeout));
///   // Retry posting the same transaction
/// } else if (response is PostTransactionActionRequired) {
///   if (response.actionMethod == 'POST' && response.actionFields != null) {
///     // Post action fields programmatically
///     var actionResponse = await service.postAction(
///       response.actionUrl,
///       {'email_address': 'user@example.com'}
///     );
///     if (actionResponse is PostActionDone) {
///       // Retry posting original transaction
///     } else if (actionResponse is PostActionNextUrl) {
///       // Open actionResponse.nextUrl in browser
///     }
///   } else {
///     // Open response.actionUrl in browser
///   }
/// } else if (response is PostTransactionRejected) {
///   // Show response.error to user
/// }
/// ```
///
/// Related Standards:
/// - [SEP-1 stellar.toml](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md)
/// - [SEP-9 KYC/AML fields](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md)
/// - [CAP-18 Fine-Grained Control of Authorization](https://github.com/stellar/stellar-protocol/blob/master/core/cap-0018.md)
///
/// See also:
/// - [RegulatedAsset] for regulated asset details
/// - [PostTransactionResponse] for approval responses
/// - [SEP-0008 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md)
class RegulatedAssetsService {
  StellarToml tomlData;
  late http.Client httpClient;
  late Network network;
  late StellarSDK sdk;
  late List<RegulatedAsset> regulatedAssets;
  Map<String, String>? httpRequestHeaders;

  /// Creates a RegulatedAssetsService with explicit configuration from stellar.toml data.
  ///
  /// Initializes the service with stellar.toml data, network configuration, and optional HTTP settings.
  /// Extracts regulated assets from the toml currencies section and configures Stellar SDK access.
  RegulatedAssetsService(this.tomlData,
      {http.Client? httpClient,
      this.httpRequestHeaders,
      String? horizonUrl,
      Network? network}) {
    this.httpClient = httpClient ?? http.Client();

    if (horizonUrl != null) {
      this.sdk = StellarSDK(horizonUrl);
    }

    if (network != null) {
      this.network = network;
    } else if (tomlData.generalInformation.networkPassphrase != null) {
      this.network = Network(tomlData.generalInformation.networkPassphrase!);
    } else {
      throw IncompleteInitData('could not find a network passphrase');
    }

    if (horizonUrl == null && tomlData.generalInformation.horizonUrl != null) {
      this.sdk = StellarSDK(tomlData.generalInformation.horizonUrl!);
    } else if (horizonUrl == null) {
      // try to init from known horizon urls
      if (this.network.networkPassphrase == Network.PUBLIC.networkPassphrase) {
        this.sdk = StellarSDK.PUBLIC;
      } else if (this.network.networkPassphrase ==
          Network.TESTNET.networkPassphrase) {
        this.sdk = StellarSDK.TESTNET;
      } else if (this.network.networkPassphrase ==
          Network.FUTURENET.networkPassphrase) {
        this.sdk = StellarSDK.FUTURENET;
      } else {
        throw IncompleteInitData("could not find a horizon url");
      }
    }

    this.regulatedAssets = List<RegulatedAsset>.empty(growable: true);
    this.tomlData.currencies?.forEach((element) {
      if (element.code != null &&
          element.issuer != null &&
          element.regulated != null &&
          element.regulated! == true &&
          element.approvalServer != null) {
        var regulatedAsset = RegulatedAsset(
            element.code!, element.issuer!, element.approvalServer!,
            approvalCriteria: element.approvalCriteria);
        this.regulatedAssets.add(regulatedAsset);
      }
    });
  }

  /// Creates a RegulatedAssetsService by loading stellar.toml from the specified domain.
  ///
  /// Fetches the stellar.toml file from the domain and extracts regulated asset
  /// information and approval server URLs. This is the recommended way to create
  /// a service instance.
  ///
  /// Parameters:
  /// - [domain] The domain hosting the stellar.toml file
  /// - [httpClient] Optional custom HTTP client for requests
  /// - [httpRequestHeaders] Optional custom headers for HTTP requests
  /// - [horizonUrl] Optional Horizon server URL (falls back to toml or known networks)
  /// - [network] Optional network passphrase (falls back to toml value)
  ///
  /// Returns: Configured service instance with regulated assets from stellar.toml
  ///
  /// Throws:
  /// - [Exception] if stellar.toml cannot be fetched
  /// - [IncompleteInitData] if required network or Horizon information is missing
  static Future<RegulatedAssetsService> fromDomain(String domain,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders,
      String? horizonUrl,
      Network? network}) async {
    StellarToml toml = await StellarToml.fromDomain(domain,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
    return RegulatedAssetsService(toml,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders,
        horizonUrl: horizonUrl, network: network);
  }

  /// Checks if authorization is required for the given asset.
  ///
  /// Regulated asset issuers must have both AUTH_REQUIRED and AUTH_REVOCABLE
  /// flags set on their account according to SEP-8. This allows the issuer to
  /// grant and revoke authorization to transact the asset at will, which is
  /// necessary for enforcing transaction-level compliance.
  ///
  /// Returns `true` if both flags are set, indicating the asset requires
  /// authorization for each transaction.
  ///
  /// Throws [IssuerAccountNotFound] if the issuer account does not exist.
  Future<bool> authorizationRequired(RegulatedAsset asset) async {
    try {
      var issuerAccount = await this.sdk.accounts.account(asset.issuerId);
      return issuerAccount.flags.authRequired &&
          issuerAccount.flags.authRevocable;
    } catch (e) {
      throw IssuerAccountNotFound(
          'issuer account ' + asset.issuerId + ' not found');
    }
  }

  /// Sends a transaction to be evaluated and signed by the approval server.
  ///
  Future<PostTransactionResponse> postTransaction(
      String tx, String approvalServer) async {
    Uri requestURI = Uri.parse(approvalServer);
    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers.putIfAbsent("Content-Type", () => "application/json");

    PostTransactionResponse result = await httpClient
        .post(requestURI, body: json.encode({'tx': tx}), headers: headers)
        .then((response) {
      switch (response.statusCode) {
        case 200:
          return PostTransactionResponse.fromJson(json.decode(response.body));
        case 400:
          var jsonData = json.decode(response.body);
          if (jsonData['error'] != null) {
            return PostTransactionResponse.fromJson(json.decode(response.body));
          } else {
            throw new UnknownPostTransactionResponse(
                response.statusCode, response.body);
          }
        default:
          throw new UnknownPostTransactionResponse(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }

  /// Sends action fields to the approval server to complete a required action.
  ///
  /// This method is used when the approval server responds with an
  /// `action_required` status and provides an `action_url` with POST method.
  ///
  /// The [url] should be the `action_url` from the [PostTransactionActionRequired]
  /// response. The [actionFields] should contain the requested SEP-9 KYC/AML
  /// fields as a map.
  ///
  /// Returns a [PostActionResponse] indicating whether the action is complete
  /// or if further action is required.
  ///
  /// Example:
  /// ```dart
  /// var actionResponse = await service.postAction(
  ///   response.actionUrl,
  ///   {
  ///     'email_address': 'user@example.com',
  ///     'mobile_number': '+1234567890'
  ///   }
  /// );
  ///
  /// if (actionResponse is PostActionDone) {
  ///   // Resubmit the original transaction
  /// } else if (actionResponse is PostActionNextUrl) {
  ///   // Open next_url in browser
  /// }
  /// ```
  ///
  /// Throws [UnknownPostActionResponse] if the server returns an unexpected response.
  Future<PostActionResponse> postAction(
      String url, Map<String, dynamic> actionFields) async {
    Uri requestURI = Uri.parse(url);

    Map<String, String> headers = {...(this.httpRequestHeaders ?? {})};
    headers.putIfAbsent("Content-Type", () => "application/json");

    PostActionResponse result = await httpClient
        .post(requestURI, body: json.encode(actionFields), headers: headers)
        .then((response) {
      switch (response.statusCode) {
        case 200:
          return PostActionResponse.fromJson(json.decode(response.body));
        default:
          throw new UnknownPostActionResponse(
              response.statusCode, response.body);
      }
    }).catchError((onError) {
      throw onError;
    });

    return result;
  }
}

/// Response from posting action fields to complete a required action.
///
/// When an approval server returns `action_required` status with POST method,
/// clients should post the requested fields to the action_url and handle
/// this response type.
///
/// Two possible outcomes:
/// - [PostActionDone] No further action required, resubmit transaction
/// - [PostActionNextUrl] User must complete action at next_url in browser
abstract class PostActionResponse {
  /// Creates a base post-action response.
  ///
  /// This is an abstract base class. Use factory constructor or concrete subclasses.
  PostActionResponse();

  /// Creates a PostActionResponse from JSON response.
  factory PostActionResponse.fromJson(Map<String, dynamic> json) {
    String result = json['result'];
    if ('no_further_action_required' == result) {
      return PostActionDone();
    } else if ('follow_next_url' == result) {
      return PostActionNextUrl(json['next_url'], message: json['message']);
    } else {
      throw UnknownPostActionResponseResult("Unknown result '" +
          result +
          "' received in the post action response");
    }
  }
}

/// Indicates that the posted action was sufficient and no further action
/// is required from the user.
///
/// The client should now resubmit the original transaction to the approval
/// server for processing.
class PostActionDone extends PostActionResponse {
  /// Creates a PostActionDone response indicating no further action is required.
  ///
  /// No parameters required. Indicates the action was successful.
  PostActionDone();
}

/// Indicates that further action is required from the user.
///
/// The client should open [nextUrl] in a browser for the user to complete
/// the required actions. All parameters from the POST request should be
/// pre-filled or already accepted at this URL.
class PostActionNextUrl extends PostActionResponse {
  /// A URL where the user can complete the required actions with all the
  /// parameters included in the original POST pre-filled or already accepted.
  String nextUrl;

  /// (optional) A human readable string containing information
  /// regarding the further action required.
  String? message;

  /// Creates a PostActionNextUrl response with the next URL for user action.
  PostActionNextUrl(this.nextUrl, {this.message});
}

/// Response from submitting a transaction to the approval server.
///
/// The approval server will return one of five possible response types:
/// - [PostTransactionSuccess] Transaction approved without changes
/// - [PostTransactionRevised] Transaction modified to be compliant
/// - [PostTransactionPending] Approval decision delayed, retry later
/// - [PostTransactionActionRequired] User must complete an action
/// - [PostTransactionRejected] Transaction cannot be made compliant
///
/// Clients must handle each response type appropriately according to the
/// workflow described in the class-level documentation.
abstract class PostTransactionResponse {
  /// Creates a base post-transaction response for regulated asset transfers.
  ///
  /// This is an abstract base class. Use factory constructor or concrete subclasses.
  PostTransactionResponse();

  /// Creates a PostTransactionResponse from JSON response.
  factory PostTransactionResponse.fromJson(Map<String, dynamic> json) {
    String status = json['status'];

    if ('success' == status) {
      String? message = json['message'] == null ? null : json['message'];
      return PostTransactionSuccess(json['tx'], message: message);
    } else if ('revised' == status) {
      return PostTransactionRevised(json['tx'], json['message']);
    } else if ('pending' == status) {
      int? timeout = convertInt(json['timeout']);
      String? message = json['message'] == null ? null : json['message'];
      return PostTransactionPending(timeout: timeout, message: message);
    } else if ('action_required' == status) {
      return PostTransactionActionRequired(json['message'], json['action_url'],
          actionMethod: json['action_method'],
          actionFields: json['action_fields'] == null
              ? null
              : List<String>.from(json['action_fields'].map((e) => e)));
    } else if ('rejected' == status) {
      return PostTransactionRejected(json['error']);
    } else {
      throw UnknownPostTransactionResponseStatus("Unknown status '" +
          status +
          "' received in the post transaction response");
    }
  }
}

/// This response means that the transaction was found compliant and signed without being revised.
class PostTransactionSuccess extends PostTransactionResponse {
  /// Transaction envelope XDR, base64 encoded. This transaction will have both
  /// the original signature(s) from the request as well as one or multiple
  /// additional signatures from the issuer.
  String tx;

  /// (optional) A human readable string containing information to pass on to the user.
  String? message;

  /// Creates a success response with the approved and signed transaction envelope.
  ///
  /// Parameters:
  /// - [tx] Base64-encoded transaction envelope XDR with original and issuer signatures
  /// - [message] Human-readable information to display to the user
  PostTransactionSuccess(this.tx, {this.message});
}

/// This response means that the transaction was revised to be made compliant.
class PostTransactionRevised extends PostTransactionResponse {
  /// Transaction envelope XDR, base64 encoded. This transaction is a revised
  /// compliant version of the original request transaction, signed by the issuer.
  String tx;

  /// A human readable string explaining the modifications made to the
  /// transaction to make it compliant.
  String message;

  /// Creates a revised response with the modified compliant transaction and explanation.
  PostTransactionRevised(this.tx, this.message);
}

/// This response means that the issuer could not determine whether to approve
/// the transaction at the time of receiving it. Wallet can re-submit the
/// same transaction at a later point in time.
class PostTransactionPending extends PostTransactionResponse {
  /// Number of milliseconds to wait before submitting the same transaction again.
  int timeout = 0;

  /// (optional) A human readable string containing information to pass on to the user.
  String? message;

  /// Creates a pending response indicating approval decision is delayed.
  PostTransactionPending({int? timeout, this.message}) {
    if (timeout != null) {
      this.timeout = timeout;
    }
  }
}

/// This response means that the user must complete an action before this transaction can be approved.
/// The approval service will provide a URL that facilitates the action.
/// Upon completion, the user will resubmit the transaction.
class PostTransactionActionRequired extends PostTransactionResponse {
  /// A human readable string containing information regarding the action required.
  String message;

  /// A URL that allows the user to complete the actions required to have the transaction approved.
  String actionUrl;

  /// (optional) GET or POST, indicating the type of request that should be made to the action_url.
  String actionMethod = 'GET';

  /// (optional) An array of additional fields defined by SEP-9 Standard KYC / AML fields that the
  /// client may optionally provide to the approval service when sending the request to the
  /// action_url so as to circumvent the need for the user to enter the information manually.
  List<String>? actionFields;

  /// Creates an action required response with URL and optional fields for user completion.
  PostTransactionActionRequired(this.message, this.actionUrl,
      {String? actionMethod, this.actionFields}) {
    if (actionMethod != null) {
      this.actionMethod = actionMethod;
    }
  }
}

/// This response means that the transaction is not compliant and could not be revised to be made compliant.
class PostTransactionRejected extends PostTransactionResponse {
  /// A human readable string explaining why the transaction is not
  /// compliant and could not be made compliant.
  String error;

  /// Creates a rejection response with the reason why the transaction cannot be made compliant.
  PostTransactionRejected(this.error);
}

/// Represents a regulated asset that requires approval for transactions.
///
/// A regulated asset is identified by its [code] and [issuerId], and includes
/// an [approvalServer] URL where transactions must be submitted for compliance
/// checking before being submitted to the Stellar network.
///
/// Regulated assets are discovered from the issuer's stellar.toml file where
/// they are marked with `regulated=true` in the CURRENCIES section.
///
/// See also:
/// - [RegulatedAssetsService] for interacting with regulated assets
/// - [SEP-8 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0008.md)
class RegulatedAsset extends AssetTypeCreditAlphaNum {
  /// The URL of the approval server that validates and signs transactions.
  String approvalServer;

  /// Optional human-readable explanation of the issuer's approval criteria.
  String? approvalCriteria;

  /// Creates a regulated asset with asset code, issuer ID, and approval server URL.
  RegulatedAsset(String code, String issuerId, this.approvalServer,
      {this.approvalCriteria})
      : super(code, issuerId);

  @override
  XdrAsset toXdr() {
    return Asset.createNonNativeAsset(code, issuerId).toXdr();
  }

  @override
  String get type => Asset.createNonNativeAsset(code, issuerId).type;
}

/// Exception thrown when the issuer account for a regulated asset cannot
/// be found on the Stellar network.
class IssuerAccountNotFound implements Exception {
  String _message;

  /// Creates an exception for when the issuer account cannot be found.
  IssuerAccountNotFound(this._message);

  String toString() {
    return _message;
  }
}

/// Exception thrown when required initialization data is missing or invalid.
///
/// This typically occurs when the stellar.toml file does not contain a
/// network passphrase or horizon URL needed to initialize the service.
class IncompleteInitData implements Exception {
  String _message;

  /// Creates an exception for missing or invalid initialization data.
  IncompleteInitData(this._message);

  String toString() {
    return _message;
  }
}

/// Exception thrown when the approval server returns an unknown or invalid
/// status value in the response.
class UnknownPostTransactionResponseStatus implements Exception {
  String _message;

  /// Creates an exception for unknown status values in transaction responses.
  UnknownPostTransactionResponseStatus(this._message);

  String toString() {
    return _message;
  }
}

/// Exception thrown when the approval server returns an unexpected HTTP
/// response that cannot be parsed.
class UnknownPostTransactionResponse implements Exception {
  /// HTTP status code of the unexpected response.
  int code;

  /// Response body content.
  String body;

  /// Creates an exception for unexpected HTTP responses from the approval server.
  UnknownPostTransactionResponse(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}

/// Exception thrown when the action endpoint returns an unexpected HTTP
/// response that cannot be parsed.
class UnknownPostActionResponse implements Exception {
  /// HTTP status code of the unexpected response.
  int code;

  /// Response body content.
  String body;

  /// Creates an exception for unexpected HTTP responses from the action endpoint.
  UnknownPostActionResponse(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}

/// Exception thrown when the action endpoint returns an unknown result value.
///
/// Valid result values are: 'no_further_action_required' and 'follow_next_url'.
class UnknownPostActionResponseResult implements Exception {
  String _message;

  /// Creates an exception for unknown result values in action responses.
  UnknownPostActionResponseResult(this._message);

  String toString() {
    return _message;
  }
}
