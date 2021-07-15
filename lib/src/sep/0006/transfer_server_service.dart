import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';

/// Implements SEP-0006 - interaction with anchors.
/// See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md" target="_blank">Deposit and Withdrawal API</a>
class TransferServerService {
  String _transferServiceAddress;

  TransferServerService(String transferServiceAddress) {
    _transferServiceAddress = checkNotNull(
        transferServiceAddress, "transferServiceAddress cannot be null");
  }

  static Future<TransferServerService> fromDomain(String domain) async {
    checkNotNull(domain, "domain cannot be null");
    StellarToml toml = await StellarToml.fromDomain(domain);
    return new TransferServerService(toml.generalInformation.transferServer);
  }

  /// Get basic info from the anchor about what their TRANSFER_SERVER supports.
  /// [language] Language code specified using ISO 639-1. description fields in the response should be in this language. Defaults to en.
  /// [jwt] token previously received from the anchor via the SEP-10 authentication flow
  Future<InfoResponse> info(String language, String jwt) async {
    Uri serverURI = Uri.parse(_transferServiceAddress + "/info");
    http.Client httpClient = new http.Client();

    _InfoRequestBuilder requestBuilder =
    new _InfoRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {};

    if (language != null) {
      queryParams["lang"] = language;
    }

    InfoResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(jwt);

    return response;
  }

  /// A deposit is when a user sends an external token (BTC via Bitcoin, USD via bank transfer, etc...)
  /// to an address held by an anchor. In turn, the anchor sends an equal amount of tokens on the
  /// Stellar network (minus fees) to the user's Stellar account.
  /// The deposit endpoint allows a wallet to get deposit information from an anchor, so a user has
  /// all the information needed to initiate a deposit. It also lets the anchor specify
  /// additional information (if desired) that the user must submit via the /customer endpoint
  /// to be able to deposit.
  Future<DepositResponse> deposit(DepositRequest request) async {
    Uri serverURI = Uri.parse(_transferServiceAddress + "/deposit");
    http.Client httpClient = new http.Client();

    _DepositRequestBuilder requestBuilder =
        new _DepositRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "asset_code": request.assetCode,
      "account": request.account,
    };

    if (request.memoType != null) {
      queryParams["memo_type"] = request.memoType;
    }
    if (request.memo != null) {
      queryParams["memo"] = request.memo;
    }
    if (request.emailAddress != null) {
      queryParams["email_address"] = request.emailAddress;
    }
    if (request.type != null) {
      queryParams["type"] = request.type;
    }
    if (request.walletName != null) {
      queryParams["wallet_name"] = request.walletName;
    }
    if (request.walletUrl != null) {
      queryParams["wallet_url"] = request.walletUrl;
    }
    if (request.lang != null) {
      queryParams["lang"] = request.lang;
    }
    if (request.onChangeCallback != null) {
      queryParams["on_change_callback"] = request.onChangeCallback;
    }
    if (request.amount != null) {
      queryParams["amount"] = request.amount;
    }
    if (request.countryCode != null) {
      queryParams["country_code"] = request.countryCode;
    }
    if (request.claimableBalanceSupported != null) {
      queryParams["claimable_balance_supported"] =
          request.claimableBalanceSupported;
    }
    DepositResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }

  Future<WithdrawResponse> withdraw(WithdrawRequest request) async {
    Uri serverURI = Uri.parse(_transferServiceAddress + "/withdraw");
    http.Client httpClient = new http.Client();

    _WithdrawRequestBuilder requestBuilder =
        new _WithdrawRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "asset_code": request.assetCode,
      "type": request.type,
      "dest": request.dest,
    };

    if (request.destExtra != null) {
      queryParams["dest_extra"] = request.destExtra;
    }
    if (request.account != null) {
      queryParams["account"] = request.account;
    }
    if (request.memo != null) {
      queryParams["memo"] = request.memo;
    }
    if (request.memoType != null) {
      queryParams["memo_type"] = request.memoType;
    }
    if (request.walletName != null) {
      queryParams["wallet_name"] = request.walletName;
    }
    if (request.walletUrl != null) {
      queryParams["wallet_url"] = request.walletUrl;
    }
    if (request.lang != null) {
      queryParams["lang"] = request.lang;
    }
    if (request.onChangeCallback != null) {
      queryParams["on_change_callback"] = request.onChangeCallback;
    }
    if (request.amount != null) {
      queryParams["amount"] = request.amount;
    }
    if (request.countryCode != null) {
      queryParams["country_code"] = request.countryCode;
    }

    WithdrawResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }
}

class DepositRequest {
  /// The code of the asset the user is wanting to deposit with the anchor. Ex BTC,ETH,USD,INR,etc.
  String assetCode;

  /// The stellar account ID of the user that wants to deposit. This is where the asset token will be sent.
  String account;

  /// (optional) type of memo that anchor should attach to the Stellar payment transaction, one of text, id or hash
  String memoType;

  /// (optional) value of memo to attach to transaction, for hash this should be base64-encoded
  String memo;

  /// (optional) Email address of depositor. If desired, an anchor can use this to send email updates to the user about the deposit.
  String emailAddress;

  /// (optional) Type of deposit. If the anchor supports multiple deposit methods (e.g. SEPA or SWIFT), the wallet should specify type. This field may be necessary for the anchor to determine which KYC fields to collect.
  String type;

  /// (optional) In communications / pages about the deposit, anchor should display the wallet name to the user to explain where funds are going.
  String walletName;

  /// (optional) Anchor should link to this when notifying the user that the transaction has completed.
  String walletUrl;

  /// (optional) Defaults to en. Language code specified using ISO 639-1. error fields in the response should be in this language.
  String lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint.
  String onChangeCallback;

  /// (optional) The amount of the asset the user would like to deposit with the anchor. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String amount;

  ///  (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String countryCode;

  /// (optional) true if the client supports receiving deposit transactions as a claimable balance, false otherwise.
  String claimableBalanceSupported;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String jwt;
}

/// Represents an transfer service deposit response.
class DepositResponse extends Response {
  /// Terse but complete instructions for how to deposit the asset. In the case of most cryptocurrencies it is just an address to which the deposit should be sent.
  String how;

  /// (optional) The anchor's ID for this deposit. The wallet will use this ID to query the /transaction endpoint to check status of the request.
  String id;

  /// (optional) Estimate of how long the deposit will take to credit in seconds.
  int eta;

  /// (optional) Minimum amount of an asset that a user can deposit.
  String minAmount;

  /// (optional) Maximum amount of asset that a user can deposit.
  String maxAmount;

  /// (optional) Fixed fee (if any). In units of the deposited asset.
  String feeFixed;

  /// (optional) Percentage fee (if any). In units of percentage points.
  String feePercent;

  /// (optional) JSON object with additional information about the deposit process.
  ExtraInfo extraInfo;

  DepositResponse(this.how, this.id, this.eta, this.minAmount, this.maxAmount,
      this.feeFixed, this.feePercent, this.extraInfo);

  factory DepositResponse.fromJson(Map<String, dynamic> json) =>
      new DepositResponse(
          json['how'] as String,
          json['id'] as String,
          convertInt(json['eta']),
          json['min_amount'] as String,
          json['max_amount'] as String,
          json['fee_fixed'] as String,
          json['fee_percent'] as String,
          json['extra_info'] == null
              ? null
              : new ExtraInfo.fromJson(
                  json['extra_info'] as Map<String, dynamic>));
}

class ExtraInfo extends Response {
  String message;

  ExtraInfo(this.message);

  factory ExtraInfo.fromJson(Map<String, dynamic> json) =>
      new ExtraInfo(json['message'] as String);
}

// Requests the deposit data.
class _DepositRequestBuilder extends RequestBuilder {
  _DepositRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _DepositRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<DepositResponse> requestExecute(
      http.Client httpClient, Uri uri, String jwt) async {
    TypeToken type = new TypeToken<DepositResponse>();
    ResponseHandler<DepositResponse> responseHandler =
        new ResponseHandler<DepositResponse>(type);

    final Map<String, String> depositHeaders = RequestBuilder.headers;
    if (jwt != null) {
      depositHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: depositHeaders).then((response) {
      if (response.statusCode == 403) {
        // handle forbidden
      }
      return responseHandler.handleResponse(response);
    });
  }

  Future<DepositResponse> execute(String jwt) {
    return _DepositRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class WithdrawRequest {
  /// Type of withdrawal. Can be: crypto, bank_account, cash, mobile, bill_payment or other custom values
  String type;

  /// Code of the asset the user wants to withdraw. The value passed must match one of the codes listed in the /info response's withdraw object.
  String assetCode;

  /// The account that the user wants to withdraw their funds to. This can be a crypto account, a bank account number, IBAN, mobile number, or email address.
  String dest;

  /// (optional) Extra information to specify withdrawal location. For crypto it may be a memo in addition to the dest address. It can also be a routing number for a bank, a BIC, or the name of a partner handling the withdrawal.
  String destExtra;

  /// (optional) The stellar account ID of the user that wants to do the withdrawal. This is only needed if the anchor requires KYC information for withdrawal. The anchor can use account to look up the user's KYC information.
  String account;

  /// (optional) A wallet will send this to uniquely identify a user if the wallet has multiple users sharing one Stellar account. The anchor can use this along with account to look up the user's KYC info.
  String memo;

  /// (optional) Type of memo. One of text, id or hash.
  String memoType;

  /// (optional) In communications / pages about the withdrawal, anchor should display the wallet name to the user to explain where funds are coming from.
  String walletName;

  /// (optional) Anchor can show this to the user when referencing the wallet involved in the withdrawal (ex. in the anchor's transaction history).
  String walletUrl;

  /// (optional) Defaults to en. Language code specified using ISO 639-1. error fields in the response should be in this language.
  String lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint.
  String onChangeCallback;

  /// (optional) The amount of the asset the user would like to deposit with the anchor. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String amount;

  /// (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String countryCode;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String jwt;
}

/// Represents an transfer service withdraw response.
class WithdrawResponse extends Response {
  /// The account the user should send its token back to.
  String accountId;

  /// (optional) Type of memo to attach to transaction, one of text, id or hash.
  String memoType;

  /// (optional) Value of memo to attach to transaction, for hash this should be base64-encoded.
  String memo;

  /// (optional) The anchor's ID for this withdrawal. The wallet will use this ID to query the /transaction endpoint to check status of the request.
  String id;

  /// (optional) Estimate of how long the withdrawal will take to credit in seconds.
  int eta;

  /// (optional) Minimum amount of an asset that a user can withdraw.
  String minAmount;

  /// (optional) Maximum amount of asset that a user can withdraw.
  String maxAmount;

  /// (optional) If there is a fee for withdraw. In units of the withdrawn asset.
  String feeFixed;

  /// (optional) If there is a percent fee for withdraw.
  String feePercent;

  /// (optional) Any additional data needed as an input for this withdraw, example: Bank Name.
  ExtraInfo extraInfo;

  WithdrawResponse(
      this.accountId,
      this.memoType,
      this.memo,
      this.id,
      this.eta,
      this.minAmount,
      this.maxAmount,
      this.feeFixed,
      this.feePercent,
      this.extraInfo);

  factory WithdrawResponse.fromJson(Map<String, dynamic> json) =>
      new WithdrawResponse(
          json['account_id'] as String,
          json['memo_type'] as String,
          json['memo'] as String,
          json['id'] as String,
          convertInt(json['eta']),
          json['min_amount'] as String,
          json['max_amount'] as String,
          json['fee_fixed'] as String,
          json['fee_percent'] as String,
          json['extra_info'] == null
              ? null
              : new ExtraInfo.fromJson(
                  json['extra_info'] as Map<String, dynamic>));
}

// Requests the withdraw data.
class _WithdrawRequestBuilder extends RequestBuilder {
  _WithdrawRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _WithdrawRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<WithdrawResponse> requestExecute(
      http.Client httpClient, Uri uri, String jwt) async {
    TypeToken type = new TypeToken<WithdrawResponse>();
    ResponseHandler<WithdrawResponse> responseHandler =
        new ResponseHandler<WithdrawResponse>(type);

    final Map<String, String> withdrawHeaders = RequestBuilder.headers;
    if (jwt != null) {
      withdrawHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: withdrawHeaders).then((response) {
      if (response.statusCode == 403) {
          // handle forbidden
      }
      return responseHandler.handleResponse(response);
    });
  }

  Future<WithdrawResponse> execute(String jwt) {
    return _WithdrawRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class AnchorField extends Response {

  String description;
  bool optional;
  List<String>choices;

  AnchorField(this.description,
      this.optional, this.choices);

  factory AnchorField.fromJson(Map<String, dynamic> json) =>
      new AnchorField(
          json['description'] as String,
          json['optional'] as bool,
          json['choices'] == null ? null : new List<String>.from(json['choices']));
}

class DepositAsset extends Response {

  bool enabled;
  bool authenticationRequired;
  String feeFixed;
  String feePercent;
  String minAmount;
  String maxAmount;
  Map<String, AnchorField> fields;

  DepositAsset(
      this.enabled,
      this.authenticationRequired,
      this.feeFixed,
      this.feePercent,
      this.minAmount,
      this.maxAmount,
      this.fields);

  factory DepositAsset.fromJson(Map<String, dynamic> json) {

    Map<String, dynamic> fieldsDynamic = json['fields'] == null
        ? null: json['fields'] as Map<String, dynamic>;
    Map<String, AnchorField> assetFields = {};
    if(fieldsDynamic != null) {
      fieldsDynamic.forEach((key, value) {
        assetFields[key] = new AnchorField.fromJson(
            value as Map<String, dynamic>);
      });
    } else {
      assetFields = null;
    }

    return new DepositAsset(
        json['enabled'] as bool,
        json['authentication_required'] as bool,
        json['fee_fixed'] as String,
        json['fee_percent'] as String,
        json['min_amount'] as String,
        json['max_amount'] as String,
        assetFields);
  }
}

class WithdrawAsset extends Response {

  bool enabled;
  bool authenticationRequired;
  String feeFixed;
  String feePercent;
  String minAmount;
  String maxAmount;
  Map<String, Map<String, AnchorField>> types;

  WithdrawAsset(
      this.enabled,
      this.authenticationRequired,
      this.feeFixed,
      this.feePercent,
      this.minAmount,
      this.maxAmount,
      this.types);

  factory WithdrawAsset.fromJson(Map<String, dynamic> json) {

    Map<String, dynamic> typesDynamic = json['types'] == null
        ? null: json['types'] as Map<String, dynamic>;

    Map<String, Map<String, AnchorField>> assetTypes = {};
    if(typesDynamic != null) {
      typesDynamic.forEach((key, value) {

        Map<String, dynamic> fieldsDynamic = json['fields'] == null
            ? null: json['fields'] as Map<String, dynamic>;
        Map<String, AnchorField> assetFields = {};
        if(fieldsDynamic != null) {
          fieldsDynamic.forEach((fkey, fvalue) {
            assetFields[fkey] = new AnchorField.fromJson(
                fvalue as Map<String, dynamic>);
          });
        } else {
          assetFields = null;
        }

        assetTypes[key] = assetFields;

      });
    } else {
      assetTypes = null;
    }

    return new WithdrawAsset(
        json['enabled'] as bool,
        json['authentication_required'] as bool,
        json['fee_fixed'] as String,
        json['fee_percent'] as String,
        json['min_amount'] as String,
        json['max_amount'] as String,
        assetTypes);
  }
}

class AnchorFeeInfo extends Response {

  bool enabled;
  bool authenticationRequired;

  AnchorFeeInfo(this.enabled, this.authenticationRequired);

  factory AnchorFeeInfo.fromJson(Map<String, dynamic> json) =>
      new AnchorFeeInfo(
        json['enabled'] as bool,
        json['authentication_required'] as bool);
}

class AnchorTransactionInfo extends Response {

  bool enabled;
  bool authenticationRequired;

  AnchorTransactionInfo(this.enabled, this.authenticationRequired);

  factory AnchorTransactionInfo.fromJson(Map<String, dynamic> json) =>
      new AnchorTransactionInfo(
          json['enabled'] as bool,
          json['authentication_required'] as bool);
}

class AnchorTransactionsInfo extends Response {

  bool enabled;
  bool authenticationRequired;

  AnchorTransactionsInfo(this.enabled, this.authenticationRequired);

  factory AnchorTransactionsInfo.fromJson(Map<String, dynamic> json) =>
      new AnchorTransactionsInfo(
          json['enabled'] as bool,
          json['authentication_required'] as bool);
}


class InfoResponse extends Response {

  Map<String, DepositAsset> depositAssets;
  Map<String, WithdrawAsset> withdrawAssets;
  AnchorFeeInfo feeInfo;
  AnchorTransactionInfo transactionInfo;
  AnchorTransactionsInfo transactionsInfo;

  InfoResponse(
      this.depositAssets, this.withdrawAssets, this.feeInfo, this.transactionInfo, this.transactionsInfo);

  factory InfoResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> depositDynamic = json['deposit'] == null
        ? null: json['deposit'] as Map<String, dynamic>;

    Map<String, DepositAsset> depositMap = {};
    if(depositDynamic != null) {
      depositDynamic.forEach((key, value) {
        depositMap[key] = new DepositAsset.fromJson(
            value as Map<String, dynamic>);
      });
    }
    Map<String, dynamic> withdrawDynamic = json['withdraw'] == null
        ? null: json['withdraw'] as Map<String, dynamic>;

    Map<String, WithdrawAsset> withdrawMap = {};
    if(withdrawDynamic != null) {
      withdrawDynamic.forEach((key, value) {
        withdrawMap[key] = new WithdrawAsset.fromJson(
            value as Map<String, dynamic>);
      });
    }

    return new InfoResponse(depositMap, withdrawMap,
        json['fee'] == null ? null : new AnchorFeeInfo.fromJson(json['fee'] as Map<String, dynamic>),
        json['transactions'] == null ? null : new AnchorTransactionInfo.fromJson(json['transactions'] as Map<String, dynamic>),
        json['transaction'] == null ? null : new AnchorTransactionsInfo.fromJson(json['transaction'] as Map<String, dynamic>));
  }

}

// Requests the info data.
class _InfoRequestBuilder extends RequestBuilder {
  _InfoRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _InfoRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<InfoResponse> requestExecute(
      http.Client httpClient, Uri uri, String jwt) async {
    TypeToken type = new TypeToken<InfoResponse>();
    ResponseHandler<InfoResponse> responseHandler =
    new ResponseHandler<InfoResponse>(type);

    final Map<String, String> infoHeaders = RequestBuilder.headers;
    if (jwt != null) {
      infoHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: infoHeaders).then((response) {
      if (response.statusCode == 403) {
        // handle forbidden
      }
      return responseHandler.handleResponse(response);
    });
  }

  Future<InfoResponse> execute(String jwt) {
    return _InfoRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}
