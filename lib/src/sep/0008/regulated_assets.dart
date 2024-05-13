import 'package:http/http.dart' as http;
import '../../../stellar_flutter_sdk.dart';
import 'dart:async';
import 'dart:convert';

class RegulatedAssetsService {
  StellarToml tomlData;
  late http.Client httpClient;
  late Network network;
  late StellarSDK sdk;
  late List<RegulatedAsset> regulatedAssets;

  RegulatedAssetsService(this.tomlData,
      {http.Client? httpClient, String? horizonUrl, Network? network}) {
    if (httpClient != null) {
      this.httpClient = httpClient;
    } else {
      this.httpClient = http.Client();
    }

    if (horizonUrl != null) {
      this.sdk = StellarSDK(horizonUrl);
    }

    if (network != null) {
      this.network = network;
    }

    if (network == null &&
        tomlData.generalInformation.networkPassphrase != null) {
      this.network = Network(tomlData.generalInformation.networkPassphrase!);
    } else {
      throw IncompleteInitData('could not find a network passphrase');
    }

    if (horizonUrl == null &&
        tomlData.generalInformation.horizonUrl != null) {
      this.sdk = StellarSDK(tomlData.generalInformation.horizonUrl!);
    } else if (horizonUrl == null) {
      // try to init from known horizon urls
      if (this.network.networkPassphrase ==
          Network.PUBLIC.networkPassphrase) {
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

  /// Creates an instance of this class by loading the toml data from the given [domain] stellar toml file.
  static Future<RegulatedAssetsService> fromDomain(String domain,
      {http.Client? httpClient, String? horizonUrl, Network? network}) async {
    StellarToml toml =
        await StellarToml.fromDomain(domain, httpClient: httpClient);
    return RegulatedAssetsService(toml, httpClient: httpClient);
  }

  /// Checks if authorization is required for the given asset.
  /// To do so, it loads the issuer account data from the stellar network
  /// and checks if the both flags 'authRequired' and 'authRevocable' are set.
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
    Map<String, String> headers = {...RequestBuilder.headers};
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

  Future<PostActionResponse> postAction(
      String url, Map<String, dynamic> actionFields) async {
    Uri requestURI = Uri.parse(url);

    Map<String, String> headers = {...RequestBuilder.headers};
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

/// Response of posting an action
abstract class PostActionResponse {
  PostActionResponse();

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

/// No further action required.
class PostActionDone extends PostActionResponse {
  PostActionDone();
}

/// Further action required
class PostActionNextUrl extends PostActionResponse {
  /// A URL where the user can complete the required actions with all the
  /// parameters included in the original POST pre-filled or already accepted.
  String nextUrl;

  /// (optional) A human readable string containing information
  /// regarding the further action required.
  String? message;

  PostActionNextUrl(this.nextUrl, {this.message});
}

abstract class PostTransactionResponse {
  PostTransactionResponse();

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

  PostTransactionRejected(this.error);
}

class RegulatedAsset extends AssetTypeCreditAlphaNum {
  String approvalServer;
  String? approvalCriteria;

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

class IssuerAccountNotFound implements Exception {
  String _message;

  IssuerAccountNotFound(this._message);

  String toString() {
    return _message;
  }
}

class IncompleteInitData implements Exception {
  String _message;

  IncompleteInitData(this._message);

  String toString() {
    return _message;
  }
}

class UnknownPostTransactionResponseStatus implements Exception {
  String _message;

  UnknownPostTransactionResponseStatus(this._message);

  String toString() {
    return _message;
  }
}

class UnknownPostTransactionResponse implements Exception {
  int code;
  String body;

  UnknownPostTransactionResponse(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}

class UnknownPostActionResponse implements Exception {
  int code;
  String body;

  UnknownPostActionResponse(this.code, this.body);

  String toString() {
    return "Unknown response - code: $code - body:$body";
  }
}

class UnknownPostActionResponseResult implements Exception {
  String _message;

  UnknownPostActionResponseResult(this._message);

  String toString() {
    return _message;
  }
}
