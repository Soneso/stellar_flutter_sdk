import 'dart:convert';

import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';

/// Implements SEP-0006 - interaction with anchors.
/// See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md" target="_blank">Deposit and Withdrawal API</a>
class TransferServerService {
  late String _transferServiceAddress;
  http.Client httpClient = http.Client();

  TransferServerService(this._transferServiceAddress);

  static Future<TransferServerService> fromDomain(String domain) async {
    StellarToml toml = await StellarToml.fromDomain(domain);
    String? transferServer = toml.generalInformation.transferServer;
    checkNotNull(transferServer, "transfer server not found in stellar toml of domain " + domain);
    return TransferServerService(transferServer!);
  }

  /// Get basic info from the anchor about what their TRANSFER_SERVER supports.
  /// [language] Language code specified using ISO 639-1. description fields in the response should be in this language. Defaults to en.
  /// [jwt] token previously received from the anchor via the SEP-10 authentication flow
  Future<InfoResponse?> info(String? language, String? jwt) async {
    Uri serverURI = Uri.parse(_transferServiceAddress).resolve('info');

    _InfoRequestBuilder requestBuilder = _InfoRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {};

    if (language != null) {
      queryParams["lang"] = language;
    }

    InfoResponse response = await requestBuilder.forQueryParameters(queryParams).execute(jwt);

    return response;
  }

  /// A deposit is when a user sends an external token (BTC via Bitcoin, USD via bank transfer, etc...)
  /// to an address held by an anchor. In turn, the anchor sends an equal amount of tokens on the
  /// Stellar network (minus fees) to the user's Stellar account.
  /// The deposit endpoint allows a wallet to get deposit information from an anchor, so a user has
  /// all the information needed to initiate a deposit. It also lets the anchor specify
  /// additional information (if desired) that the user must submit via the /customer endpoint
  /// to be able to deposit.
  Future<DepositResponse?> deposit(DepositRequest request) async {
    Uri serverURI = Uri.parse(_transferServiceAddress).resolve('deposit');

    _DepositRequestBuilder requestBuilder = _DepositRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "asset_code": request.assetCode,
      "account": request.account,
    };

    if (request.memoType != null) {
      queryParams["memo_type"] = request.memoType!;
    }
    if (request.memo != null) {
      queryParams["memo"] = request.memo!;
    }
    if (request.emailAddress != null) {
      queryParams["email_address"] = request.emailAddress!;
    }
    if (request.type != null) {
      queryParams["type"] = request.type!;
    }
    if (request.walletName != null) {
      queryParams["wallet_name"] = request.walletName!;
    }
    if (request.walletUrl != null) {
      queryParams["wallet_url"] = request.walletUrl!;
    }
    if (request.lang != null) {
      queryParams["lang"] = request.lang!;
    }
    if (request.onChangeCallback != null) {
      queryParams["on_change_callback"] = request.onChangeCallback!;
    }
    if (request.amount != null) {
      queryParams["amount"] = request.amount!;
    }
    if (request.countryCode != null) {
      queryParams["country_code"] = request.countryCode!;
    }
    if (request.claimableBalanceSupported != null) {
      queryParams["claimable_balance_supported"] = request.claimableBalanceSupported!;
    }

    DepositResponse response;
    try {
      response = await requestBuilder.forQueryParameters(queryParams).execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }

    return response;
  }

  Future<WithdrawResponse?> withdraw(WithdrawRequest request) async {
    Uri serverURI = Uri.parse(_transferServiceAddress).resolve('withdraw');

    _WithdrawRequestBuilder requestBuilder = _WithdrawRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "asset_code": request.assetCode,
      "type": request.type,
      "dest": request.dest,
    };

    if (request.destExtra != null) {
      queryParams["dest_extra"] = request.destExtra!;
    }
    if (request.account != null) {
      queryParams["account"] = request.account!;
    }
    if (request.memo != null) {
      queryParams["memo"] = request.memo!;
    }
    if (request.memoType != null) {
      queryParams["memo_type"] = request.memoType!;
    }
    if (request.walletName != null) {
      queryParams["wallet_name"] = request.walletName!;
    }
    if (request.walletUrl != null) {
      queryParams["wallet_url"] = request.walletUrl!;
    }
    if (request.lang != null) {
      queryParams["lang"] = request.lang!;
    }
    if (request.onChangeCallback != null) {
      queryParams["on_change_callback"] = request.onChangeCallback!;
    }
    if (request.amount != null) {
      queryParams["amount"] = request.amount!;
    }
    if (request.countryCode != null) {
      queryParams["country_code"] = request.countryCode!;
    }

    WithdrawResponse response;
    try {
      response = await requestBuilder.forQueryParameters(queryParams).execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }
    return response;
  }

  _handleForbiddenResponse(ErrorResponse e) {
    Map<String, dynamic>? res = json.decode(e.body);
    if (res != null && res["type"] != null) {
      String type = res["type"];
      if ("non_interactive_customer_info_needed" == type) {
        throw CustomerInformationNeededException(CustomerInformationNeededResponse.fromJson(res));
      } else if ("customer_info_status" == type) {
        throw CustomerInformationStatusException(CustomerInformationStatusResponse.fromJson(res));
      } else if ("authentication_required" == type) {
        throw AuthenticationRequiredException();
      }
    }
  }

  Future<FeeResponse?> fee(FeeRequest request) async {
    Uri serverURI = Uri.parse(_transferServiceAddress).resolve('fee');

    _FeeRequestBuilder requestBuilder = _FeeRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "operation": request.operation,
      "asset_code": request.assetCode,
      "amount": request.amount.toString(),
    };

    if (request.type != null) {
      queryParams["type"] = request.type!;
    }

    FeeResponse response =
        await requestBuilder.forQueryParameters(queryParams).execute(request.jwt);

    return response;
  }

  /// The transaction history endpoint helps anchors enable a better experience for users using an external wallet.
  /// With it, wallets can display the status of deposits and withdrawals while they process and a history of
  /// past transactions with the anchor. It's only for transactions that are deposits to or withdrawals from the anchor.
  Future<AnchorTransactionsResponse?> transactions(AnchorTransactionsRequest request) async {
    Uri serverURI = Uri.parse(_transferServiceAddress).resolve('transactions');

    _AnchorTransactionsRequestBuilder requestBuilder =
        _AnchorTransactionsRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "asset_code": request.assetCode,
      "account": request.account
    };

    if (request.noOlderThan != null) {
      queryParams["no_older_than"] = request.noOlderThan!.toIso8601String();
    }

    if (request.limit != null) {
      queryParams["limit"] = request.limit.toString();
    }

    if (request.kind != null) {
      queryParams["kind"] = request.kind!;
    }

    if (request.pagingId != null) {
      queryParams["paging_id"] = request.pagingId!;
    }

    AnchorTransactionsResponse response =
        await requestBuilder.forQueryParameters(queryParams).execute(request.jwt);

    return response;
  }

  /// The transaction endpoint enables clients to query/validate a specific transaction at an anchor.
  Future<AnchorTransactionResponse?> transaction(AnchorTransactionRequest request) async {
    Uri serverURI = Uri.parse(_transferServiceAddress).resolve('transaction');

    _AnchorTransactionRequestBuilder requestBuilder =
        _AnchorTransactionRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {};

    if (request.id != null) {
      queryParams["id"] = request.id!;
    }
    if (request.stallarTransactionId != null) {
      queryParams["stellar_transaction_id"] = request.stallarTransactionId!;
    }
    if (request.externalTransactionId != null) {
      queryParams["external_transaction_id"] = request.externalTransactionId!;
    }

    AnchorTransactionResponse response =
        await requestBuilder.forQueryParameters(queryParams).execute(request.jwt);

    return response;
  }

  Future<http.Response?> patchTransaction(PatchTransactionRequest request) async {

    checkNotNull(request.id, "request.id cannot be null");
    checkNotNull(request.fields, "request.fields cannot be null");
    Uri serverURI = Uri.parse(_transferServiceAddress).resolve('transactions/${request.id!}');

    _PatchTransactionRequestBuilder requestBuilder =
        _PatchTransactionRequestBuilder(httpClient, serverURI);

    http.Response response = await requestBuilder.forFields(request.fields!).execute(request.jwt!);
    return response;
  }
}

class DepositRequest {
  /// The code of the asset the user is wanting to deposit with the anchor. Ex BTC,ETH,USD,INR,etc.
  late String assetCode;

  /// The stellar account ID of the user that wants to deposit. This is where the asset token will be sent.
  late String account;

  /// (optional) type of memo that anchor should attach to the Stellar payment transaction, one of text, id or hash
  String? memoType;

  /// (optional) value of memo to attach to transaction, for hash this should be base64-encoded
  String? memo;

  /// (optional) Email address of depositor. If desired, an anchor can use this to send email updates to the user about the deposit.
  String? emailAddress;

  /// (optional) Type of deposit. If the anchor supports multiple deposit methods (e.g. SEPA or SWIFT), the wallet should specify type. This field may be necessary for the anchor to determine which KYC fields to collect.
  String? type;

  /// (optional) In communications / pages about the deposit, anchor should display the wallet name to the user to explain where funds are going.
  String? walletName;

  /// (optional) Anchor should link to this when notifying the user that the transaction has completed.
  String? walletUrl;

  /// (optional) Defaults to en. Language code specified using ISO 639-1. error fields in the response should be in this language.
  String? lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint.
  String? onChangeCallback;

  /// (optional) The amount of the asset the user would like to deposit with the anchor. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String? amount;

  ///  (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String? countryCode;

  /// (optional) true if the client supports receiving deposit transactions as a claimable balance, false otherwise.
  String? claimableBalanceSupported;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

/// Represents an transfer service deposit response.
class DepositResponse extends Response {
  /// Terse but complete instructions for how to deposit the asset. In the case of most cryptocurrencies it is just an address to which the deposit should be sent.
  String? how;

  /// (optional) The anchor's ID for this deposit. The wallet will use this ID to query the /transaction endpoint to check status of the request.
  String? id;

  /// (optional) Estimate of how long the deposit will take to credit in seconds.
  int? eta;

  /// (optional) Minimum amount of an asset that a user can deposit.
  double? minAmount;

  /// (optional) Maximum amount of asset that a user can deposit.
  double? maxAmount;

  /// (optional) Fixed fee (if any). In units of the deposited asset.
  double? feeFixed;

  /// (optional) Percentage fee (if any). In units of percentage points.
  double? feePercent;

  /// (optional) JSON object with additional information about the deposit process.
  ExtraInfo? extraInfo;

  DepositResponse(this.how, this.id, this.eta, this.minAmount, this.maxAmount, this.feeFixed,
      this.feePercent, this.extraInfo);

  factory DepositResponse.fromJson(Map<String, dynamic> json) => DepositResponse(
      json['how'],
      json['id'],
      convertInt(json['eta']),
      convertDouble(json['min_amount']),
      convertDouble(json['max_amount']),
      convertDouble(json['fee_fixed']),
      convertDouble(json['fee_percent']),
      json['extra_info'] == null ? null : ExtraInfo.fromJson(json['extra_info']));
}

class ExtraInfo extends Response {
  String? message;

  ExtraInfo(this.message);

  factory ExtraInfo.fromJson(Map<String, dynamic> json) => ExtraInfo(json['message']);
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
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<DepositResponse> type = TypeToken<DepositResponse>();
    ResponseHandler<DepositResponse> responseHandler = ResponseHandler<DepositResponse>(type);

    final Map<String, String> depositHeaders = RequestBuilder.headers;
    if (jwt != null) {
      depositHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: depositHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<DepositResponse> execute(String? jwt) {
    return _DepositRequestBuilder.requestExecute(this.httpClient, this.buildUri(), jwt);
  }
}

class CustomerInformationNeededResponse extends Response {
  /// A list of field names that need to be transmitted via SEP-12 for the deposit to proceed.
  List<String>? fields;

  CustomerInformationNeededResponse(this.fields);

  factory CustomerInformationNeededResponse.fromJson(Map<String, dynamic> json) =>
      CustomerInformationNeededResponse(
          json['fields'] == null ? null : List<String>.from(json['fields']));
}

class CustomerInformationNeededException implements Exception {
  CustomerInformationNeededResponse _response;

  CustomerInformationNeededException(this._response);

  String toString() {
    List<String> fields = _response.fields!;
    return "The anchor needs more information about the customer and all the information can be received non-interactively via SEP-12. Fields: $fields";
  }

  CustomerInformationNeededResponse get response => _response;
}

class CustomerInformationStatusResponse extends Response {
  /// Status of customer information processing. One of: pending, denied.
  String? status;

  /// (optional) A URL the user can visit if they want more information about their account / status.
  String? moreInfoUrl;

  /// (optional) Estimated number of seconds until the customer information status will update.
  int? eta;

  CustomerInformationStatusResponse(this.status, this.moreInfoUrl, this.eta);

  factory CustomerInformationStatusResponse.fromJson(Map<String, dynamic> json) =>
      CustomerInformationStatusResponse(
          json['status'], json['more_info_url'], convertInt(json['eta']));
}

class CustomerInformationStatusException implements Exception {
  CustomerInformationStatusResponse _response;

  CustomerInformationStatusException(this._response);

  String toString() {
    String? status = _response.status;
    String? moreInfoUrl = _response.moreInfoUrl;
    int? eta = _response.eta;
    return "Customer information was submitted for the account, but the information is either still being processed or was not accepted. Status: $status - More info url: $moreInfoUrl - Eta: $eta";
  }

  CustomerInformationStatusResponse get response => _response;
}

class AuthenticationRequiredException implements Exception {
  String toString() {
    return "The endpoint requires authentication.";
  }
}

class WithdrawRequest {
  /// Type of withdrawal. Can be: crypto, bank_account, cash, mobile, bill_payment or other custom values
  late String type;

  /// Code of the asset the user wants to withdraw. The value passed must match one of the codes listed in the /info response's withdraw object.
  late String assetCode;

  /// The account that the user wants to withdraw their funds to. This can be a crypto account, a bank account number, IBAN, mobile number, or email address.
  late String dest;

  /// (optional) Extra information to specify withdrawal location. For crypto it may be a memo in addition to the dest address. It can also be a routing number for a bank, a BIC, or the name of a partner handling the withdrawal.
  String? destExtra;

  /// (optional) The stellar account ID of the user that wants to do the withdrawal. This is only needed if the anchor requires KYC information for withdrawal. The anchor can use account to look up the user's KYC information.
  String? account;

  /// (optional) A wallet will send this to uniquely identify a user if the wallet has multiple users sharing one Stellar account. The anchor can use this along with account to look up the user's KYC info.
  String? memo;

  /// (optional) Type of memo. One of text, id or hash.
  String? memoType;

  /// (optional) In communications / pages about the withdrawal, anchor should display the wallet name to the user to explain where funds are coming from.
  String? walletName;

  /// (optional) Anchor can show this to the user when referencing the wallet involved in the withdrawal (ex. in the anchor's transaction history).
  String? walletUrl;

  /// (optional) Defaults to en. Language code specified using ISO 639-1. error fields in the response should be in this language.
  String? lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the status property of the transaction created as a result of this request changes. The JSON message should be identical to the response format for the /transaction endpoint.
  String? onChangeCallback;

  /// (optional) The amount of the asset the user would like to deposit with the anchor. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String? amount;

  /// (optional) The ISO 3166-1 alpha-3 code of the user's current address. This field may be necessary for the anchor to determine what KYC information is necessary to collect.
  String? countryCode;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

/// Represents an transfer service withdraw response.
class WithdrawResponse extends Response {
  /// The account the user should send its token back to.
  String? accountId;

  /// (optional) Type of memo to attach to transaction, one of text, id or hash.
  String? memoType;

  /// (optional) Value of memo to attach to transaction, for hash this should be base64-encoded.
  String? memo;

  /// (optional) The anchor's ID for this withdrawal. The wallet will use this ID to query the /transaction endpoint to check status of the request.
  String? id;

  /// (optional) Estimate of how long the withdrawal will take to credit in seconds.
  int? eta;

  /// (optional) Minimum amount of an asset that a user can withdraw.
  double? minAmount;

  /// (optional) Maximum amount of asset that a user can withdraw.
  double? maxAmount;

  /// (optional) If there is a fee for withdraw. In units of the withdrawn asset.
  double? feeFixed;

  /// (optional) If there is a percent fee for withdraw.
  double? feePercent;

  /// (optional) Any additional data needed as an input for this withdraw, example: Bank Name.
  ExtraInfo? extraInfo;

  WithdrawResponse(this.accountId, this.memoType, this.memo, this.id, this.eta, this.minAmount,
      this.maxAmount, this.feeFixed, this.feePercent, this.extraInfo);

  factory WithdrawResponse.fromJson(Map<String, dynamic> json) => WithdrawResponse(
      json['account_id'],
      json['memo_type'],
      json['memo'],
      json['id'],
      convertInt(json['eta']),
      convertDouble(json['min_amount']),
      convertDouble(json['max_amount']),
      convertDouble(json['fee_fixed']),
      convertDouble(json['fee_percent']),
      json['extra_info'] == null ? null : ExtraInfo.fromJson(json['extra_info']));
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
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<WithdrawResponse> type = TypeToken<WithdrawResponse>();
    ResponseHandler<WithdrawResponse> responseHandler = ResponseHandler<WithdrawResponse>(type);

    final Map<String, String> withdrawHeaders = RequestBuilder.headers;
    if (jwt != null) {
      withdrawHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: withdrawHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<WithdrawResponse> execute(String? jwt) {
    return _WithdrawRequestBuilder.requestExecute(this.httpClient, this.buildUri(), jwt);
  }
}

class AnchorField extends Response {
  String? description;
  bool? optional;
  List<String>? choices;

  AnchorField(this.description, this.optional, this.choices);

  factory AnchorField.fromJson(Map<String, dynamic> json) => AnchorField(json['description'],
      json['optional'], json['choices'] == null ? null : List<String>.from(json['choices']));
}

class DepositAsset extends Response {
  bool? enabled;
  bool? authenticationRequired;
  double? feeFixed;
  double? feePercent;
  double? minAmount;
  double? maxAmount;
  Map<String, AnchorField>? fields;

  DepositAsset(this.enabled, this.authenticationRequired, this.feeFixed, this.feePercent,
      this.minAmount, this.maxAmount, this.fields);

  factory DepositAsset.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? fieldsDynamic = json['fields'] == null ? null : json['fields'];
    Map<String, AnchorField>? assetFields = {};
    if (fieldsDynamic != null) {
      fieldsDynamic.forEach((key, value) {
        assetFields![key] = AnchorField.fromJson(value);
      });
    } else {
      assetFields = null;
    }

    return DepositAsset(
        json['enabled'],
        json['authentication_required'],
        convertDouble(json['fee_fixed']),
        convertDouble(json['fee_percent']),
        convertDouble(json['min_amount']),
        convertDouble(json['max_amount']),
        assetFields);
  }
}

class WithdrawAsset extends Response {
  bool? enabled;
  bool? authenticationRequired;
  double? feeFixed;
  double? feePercent;
  double? minAmount;
  double? maxAmount;
  Map<String, Map<String, AnchorField>?>? types;

  WithdrawAsset(this.enabled, this.authenticationRequired, this.feeFixed, this.feePercent,
      this.minAmount, this.maxAmount, this.types);

  factory WithdrawAsset.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? typesDynamic = json['types'] == null ? null : json['types'];

    Map<String, Map<String, AnchorField>?>? assetTypes = {};
    if (typesDynamic != null) {
      typesDynamic.forEach((key, value) {
        Map<String, dynamic>? fieldsDynamic =
            typesDynamic[key]['fields'] == null ? null : typesDynamic[key]['fields'];
        Map<String, AnchorField>? assetFields = {};
        if (fieldsDynamic != null) {
          fieldsDynamic.forEach((fkey, fvalue) {
            assetFields![fkey] = AnchorField.fromJson(fvalue);
          });
        } else {
          assetFields = null;
        }

        assetTypes![key] = assetFields;
      });
    } else {
      assetTypes = null;
    }

    return WithdrawAsset(
        json['enabled'],
        json['authentication_required'],
        convertDouble(json['fee_fixed']),
        convertDouble(json['fee_percent']),
        convertDouble(json['min_amount']),
        convertDouble(json['max_amount']),
        assetTypes);
  }
}

class AnchorFeeInfo extends Response {
  bool? enabled;
  bool? authenticationRequired;

  AnchorFeeInfo(this.enabled, this.authenticationRequired);

  factory AnchorFeeInfo.fromJson(Map<String, dynamic> json) =>
      AnchorFeeInfo(json['enabled'], json['authentication_required']);
}

class AnchorTransactionInfo extends Response {
  bool? enabled;
  bool? authenticationRequired;

  AnchorTransactionInfo(this.enabled, this.authenticationRequired);

  factory AnchorTransactionInfo.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionInfo(json['enabled'], json['authentication_required']);
}

class AnchorTransactionsInfo extends Response {
  bool? enabled;
  bool? authenticationRequired;

  AnchorTransactionsInfo(this.enabled, this.authenticationRequired);

  factory AnchorTransactionsInfo.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionsInfo(json['enabled'], json['authentication_required']);
}

class InfoResponse extends Response {
  Map<String, DepositAsset>? depositAssets;
  Map<String, WithdrawAsset>? withdrawAssets;
  AnchorFeeInfo? feeInfo;
  AnchorTransactionsInfo? transactionsInfo;
  AnchorTransactionInfo? transactionInfo;

  InfoResponse(this.depositAssets, this.withdrawAssets, this.feeInfo, this.transactionsInfo,
      this.transactionInfo);

  factory InfoResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? depositDynamic = json['deposit'] == null ? null : json['deposit'];

    Map<String, DepositAsset> depositMap = {};
    if (depositDynamic != null) {
      depositDynamic.forEach((key, value) {
        depositMap[key] = DepositAsset.fromJson(value);
      });
    }
    Map<String, dynamic>? withdrawDynamic = json['withdraw'] == null ? null : json['withdraw'];

    Map<String, WithdrawAsset> withdrawMap = {};
    if (withdrawDynamic != null) {
      withdrawDynamic.forEach((key, value) {
        withdrawMap[key] = WithdrawAsset.fromJson(value);
      });
    }

    return InfoResponse(
        depositMap,
        withdrawMap,
        json['fee'] == null ? null : AnchorFeeInfo.fromJson(json['fee']),
        json['transactions'] == null ? null : AnchorTransactionsInfo.fromJson(json['transactions']),
        json['transaction'] == null ? null : AnchorTransactionInfo.fromJson(json['transaction']));
  }
}

// Requests the info data.
class _InfoRequestBuilder extends RequestBuilder {
  _InfoRequestBuilder(http.Client httpClient, Uri serverURI) : super(httpClient, serverURI, null);

  _InfoRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<InfoResponse> requestExecute(http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<InfoResponse> type = TypeToken<InfoResponse>();
    ResponseHandler<InfoResponse> responseHandler = ResponseHandler<InfoResponse>(type);

    final Map<String, String> infoHeaders = RequestBuilder.headers;
    if (jwt != null) {
      infoHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: infoHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<InfoResponse> execute(String? jwt) {
    return _InfoRequestBuilder.requestExecute(this.httpClient, this.buildUri(), jwt);
  }
}

class FeeRequest {
  /// Kind of operation (deposit or withdraw).
  late String operation;

  /// (optional) Type of deposit or withdrawal (SEPA, bank_account, cash, etc...).
  String? type;

  /// Asset code.
  late String assetCode;

  /// Amount of the asset that will be deposited/withdrawn.
  late double amount;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

/// Represents an transfer service fee response.
class FeeResponse extends Response {
  /// The total fee (in units of the asset involved) that would be charged to deposit/withdraw the specified amount of asset_code.
  double? fee;

  FeeResponse(this.fee);

  factory FeeResponse.fromJson(Map<String, dynamic> json) =>
      FeeResponse(convertDouble(json['fee']));
}

// Requests the fee data.
class _FeeRequestBuilder extends RequestBuilder {
  _FeeRequestBuilder(http.Client httpClient, Uri serverURI) : super(httpClient, serverURI, null);

  _FeeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<FeeResponse> requestExecute(http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<FeeResponse> type = TypeToken<FeeResponse>();
    ResponseHandler<FeeResponse> responseHandler = ResponseHandler<FeeResponse>(type);

    final Map<String, String> feeHeaders = RequestBuilder.headers;
    if (jwt != null) {
      feeHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: feeHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<FeeResponse> execute(String? jwt) {
    return _FeeRequestBuilder.requestExecute(this.httpClient, this.buildUri(), jwt);
  }
}

class AnchorTransactionsRequest {
  /// The code of the asset of interest. E.g. BTC, ETH, USD, INR, etc.
  late String assetCode;

  /// The stellar account ID involved in the transactions.
  late String account;

  /// (optional) The response should contain transactions starting on or after this date & time.
  DateTime? noOlderThan;

  /// (optional) The response should contain at most limit transactions.
  int? limit;

  /// (optional) The kind of transaction that is desired. Should be either deposit or withdrawal.
  String? kind;

  /// (optional) The response should contain transactions starting prior to this ID (exclusive).
  String? pagingId;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

/// Represents an anchor transaction
class AnchorTransaction extends Response {
  /// Unique, anchor-generated id for the deposit/withdrawal.
  String? id;

  /// deposit or withdrawal.
  String? kind;

  /// Processing status of deposit/withdrawal.
  String? status;

  /// (optional) Estimated number of seconds until a status change is expected.
  int? statusEta;

  /// (optional) A URL the user can visit if they want more information about their account / status.
  String? moreInfoUrl;

  /// (optional) Amount received by anchor at start of transaction as a string with up to 7 decimals. Excludes any fees charged before the anchor received the funds.
  String? amountIn;

  /// (optional) Amount sent by anchor to user at end of transaction as a string with up to 7 decimals. Excludes amount converted to XLM to fund account and any external fees.
  String? amountOut;

  /// (optional) Amount of fee charged by anchor.
  String? amountFee;

  /// (optional) Sent from address (perhaps BTC, IBAN, or bank account in the case of a deposit, Stellar address in the case of a withdrawal).
  String? from;

  /// (optional) Sent to address (perhaps BTC, IBAN, or bank account in the case of a withdrawal, Stellar address in the case of a deposit).
  String? to;

  /// (optional) Extra information for the external account involved. It could be a bank routing number, BIC, or store number for example.
  String? externalExtra;

  /// (optional) Text version of external_extra. This is the name of the bank or store
  String? externalExtraText;

  /// (optional) If this is a deposit, this is the memo (if any) used to transfer the asset to the to Stellar address
  String? depositMemo;

  /// (optional) Type for the deposit_memo.
  String? depositMemoType;

  /// (optional) If this is a withdrawal, this is the anchor's Stellar account that the user transferred (or will transfer) their issued asset to.
  String? withdrawAnchorAccount;

  /// (optional) Memo used when the user transferred to withdraw_anchor_account.
  String? withdrawMemo;

  /// (optional) Memo type for withdraw_memo.
  String? withdrawMemoType;

  /// (optional) Start date and time of transaction - UTC ISO 8601 string.
  String? startedAt;

  /// (optional) Completion date and time of transaction - UTC ISO 8601 string.
  String? completedAt;

  /// (optional) transaction_id on Stellar network of the transfer that either completed the deposit or started the withdrawal.
  String? stellarTransactionId;

  /// (optional) ID of transaction on external network that either started the deposit or completed the withdrawal.
  String? externalTransactionId;

  /// (optional) Human readable explanation of transaction status, if needed.
  String? message;

  /// (optional) Should be true if the transaction was refunded. Not including this field means the transaction was not refunded.
  bool? refunded;

  /// (optional) A human-readable message indicating any errors that require updated information from the user.
  String? requiredInfoMessage;

  /// (optional) A set of fields that require update from the user described in the same format as /info. This field is only relevant when status is pending_transaction_info_update.
  Map<String, AnchorField>? requiredInfoUpdates;

  /// (optional) ID of the Claimable Balance used to send the asset initially requested. Only relevant for deposit transactions.
  String? claimableBalanceId;

  AnchorTransaction(
      this.id,
      this.kind,
      this.status,
      this.statusEta,
      this.moreInfoUrl,
      this.amountIn,
      this.amountOut,
      this.amountFee,
      this.from,
      this.to,
      this.externalExtra,
      this.externalExtraText,
      this.depositMemo,
      this.depositMemoType,
      this.withdrawAnchorAccount,
      this.withdrawMemo,
      this.withdrawMemoType,
      this.startedAt,
      this.completedAt,
      this.stellarTransactionId,
      this.externalTransactionId,
      this.message,
      this.refunded,
      this.requiredInfoMessage,
      this.requiredInfoUpdates,
      this.claimableBalanceId);

  factory AnchorTransaction.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? fieldsDynamic =
        json['required_info_updates'] == null ? null : json['required_info_updates'];
    Map<String, AnchorField>? requiredInfoUpdates = {};
    if (fieldsDynamic != null) {
      Map<String, dynamic>? valuesDynamic =
          fieldsDynamic['transaction'] == null ? null : fieldsDynamic['transaction'];
      if (valuesDynamic != null) {
        valuesDynamic.forEach((key, value) {
          requiredInfoUpdates![key] = AnchorField.fromJson(value);
        });
      }
    } else {
      requiredInfoUpdates = null;
    }

    return AnchorTransaction(
        json['id'],
        json['kind'],
        json['status'],
        convertInt(json['status_eta']),
        json['more_info_url'],
        json['amount_in'],
        json['amount_out'],
        json['amount_fee'],
        json['from'],
        json['to'],
        json['external_extra'],
        json['external_extra_text'],
        json['deposit_memo'],
        json['deposit_memo_type'],
        json['withdraw_anchor_account'],
        json['withdraw_memo'],
        json['withdraw_memo_type'],
        json['started_at'],
        json['completed_at'],
        json['stellar_transaction_id'],
        json['external_transaction_id'],
        json['message'],
        json['refunded'],
        json['required_info_message'],
        requiredInfoUpdates,
        json['claimable_balance_id']);
  }
}

class AnchorTransactionsResponse extends Response {
  List<AnchorTransaction?>? transactions;

  AnchorTransactionsResponse(this.transactions);

  factory AnchorTransactionsResponse.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionsResponse((json['transactions'] as List)
          .map((e) => e == null ? null : AnchorTransaction.fromJson(e))
          .toList());
}

// Requests the transaction history data.
class _AnchorTransactionsRequestBuilder extends RequestBuilder {
  _AnchorTransactionsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _AnchorTransactionsRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<AnchorTransactionsResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<AnchorTransactionsResponse> type = TypeToken<AnchorTransactionsResponse>();
    ResponseHandler<AnchorTransactionsResponse> responseHandler =
        ResponseHandler<AnchorTransactionsResponse>(type);

    final Map<String, String> atHeaders = RequestBuilder.headers;
    if (jwt != null) {
      atHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<AnchorTransactionsResponse> execute(String? jwt) {
    return _AnchorTransactionsRequestBuilder.requestExecute(this.httpClient, this.buildUri(), jwt);
  }
}

class AnchorTransactionRequest {
  /// (optional) The id of the transaction.
  String? id;

  /// (optional) The stellar transaction id of the transaction.
  String? stallarTransactionId;

  /// (optional) The external transaction id of the transaction.
  String? externalTransactionId;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

class AnchorTransactionResponse extends Response {
  AnchorTransaction? transaction;

  AnchorTransactionResponse(this.transaction);

  factory AnchorTransactionResponse.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionResponse(
          json['transaction'] == null ? null : AnchorTransaction.fromJson(json['transaction']));
}

// Requests the transaction data for a specific transaction.
class _AnchorTransactionRequestBuilder extends RequestBuilder {
  _AnchorTransactionRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _AnchorTransactionRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<AnchorTransactionResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<AnchorTransactionResponse> type = TypeToken<AnchorTransactionResponse>();
    ResponseHandler<AnchorTransactionResponse> responseHandler =
        ResponseHandler<AnchorTransactionResponse>(type);

    final Map<String, String> atHeaders = RequestBuilder.headers;
    if (jwt != null) {
      atHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<AnchorTransactionResponse> execute(String? jwt) {
    return _AnchorTransactionRequestBuilder.requestExecute(this.httpClient, this.buildUri(), jwt);
  }
}

class PatchTransactionRequest {
  /// Id of the transaction
  String? id;

  /// An object containing the values requested to be updated by the anchor
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#pending-transaction-info-update
  Map<String, dynamic>? fields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

// Pending Transaction Info Update.
class _PatchTransactionRequestBuilder extends RequestBuilder {
  late Map<String, dynamic> _fields;

  _PatchTransactionRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _PatchTransactionRequestBuilder forFields(Map<String, dynamic> fields) {
    _fields = fields;
    return this;
  }

  static Future<http.Response> requestExecute(
      http.Client httpClient, Uri uri, Map<String, dynamic> fields, String? jwt) async {
    final Map<String, String> atHeaders = RequestBuilder.headers;
    if (jwt != null) {
      atHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.patch(uri,
        body: {"transaction": json.encode(fields)}, headers: atHeaders);
  }

  Future<http.Response> execute(String jwt) {
    return _PatchTransactionRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt);
  }
}
