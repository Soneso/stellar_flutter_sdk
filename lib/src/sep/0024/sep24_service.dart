import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';
import '../0009/standard_kyc_fields.dart';
import 'dart:convert';

/// Implements SEP-0024 - Hosted Deposit and Withdrawal.
/// See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md" target="_blank">Hosted Deposit and Withdrawal</a>
class TransferServerSEP24Service {
  String _transferServiceAddress;
  late http.Client httpClient;

  TransferServerSEP24Service(this._transferServiceAddress, {http.Client? httpClient}) {
    if (httpClient != null) {
      this.httpClient = httpClient;
    } else {
      this.httpClient = http.Client();
    }
  }

  /// Creates an instance of this class by loading the transfer server sep 24 url from the given [domain] stellar toml file.
  static Future<TransferServerSEP24Service> fromDomain(String domain, {http.Client? httpClient}) async {
    StellarToml toml = await StellarToml.fromDomain(domain, httpClient: httpClient);
    String? addr = toml.generalInformation.transferServerSep24;
    checkNotNull(
        addr, "Transfer server SEP 24 not available for domain " + domain);
    return TransferServerSEP24Service(addr!, httpClient: httpClient);
  }

  /// Get the anchors basic info about what their TRANSFER_SERVER_SEP0024 support to wallets and clients.
  /// [lang] Language code specified using ISO 639-1. description fields in the response should be in this language. Defaults to en.
  Future<SEP24InfoResponse> info([String? lang]) async {
    Uri serverURI = Util.appendEndpointToUrl(_transferServiceAddress, 'info');

    _InfoRequestBuilder requestBuilder =
        _InfoRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {};

    if (lang != null) {
      queryParams["lang"] = lang;
    }

    SEP24InfoResponse response =
        await requestBuilder.forQueryParameters(queryParams).execute();

    return response;
  }

  /// Get the anchor's to reported fee that would be charged for a given deposit or withdraw operation.
  /// This is important to allow an anchor to accurately report fees to a user even when the fee schedule is complex.
  /// If a fee can be fully expressed with the fee_fixed, fee_percent or fee_minimum fields in the /info response,
  /// then an anchor will not implement this endpoint.
  ///
  /// Throws a [RequestErrorException] if the server responds with an error and corresponding error message.
  /// Throws a [SEP24AuthenticationRequiredException] if the server responds with an authentication_required error.
  Future<SEP24FeeResponse> fee(SEP24FeeRequest request) async {
    Uri serverURI = Util.appendEndpointToUrl(_transferServiceAddress, 'fee');

    _FeeRequestBuilder requestBuilder =
        _FeeRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "operation": request.operation,
      "asset_code": request.assetCode,
      "amount": request.amount.toString(),
    };

    if (request.type != null) {
      queryParams["type"] = request.type!;
    }

    SEP24FeeResponse response;
    try {
      response = await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      else if (e.code != 200) {
        _handleErrorResponse(e);
      }
      throw e;
    }
    return response;
  }

  _handleErrorResponse(ErrorResponse e) {
    Map<String, dynamic>? res = json.decode(e.body);
    if (res != null && res["error"] != null) {
      throw RequestErrorException(res["error"]);
    }
  }

  _handleForbiddenResponse(ErrorResponse e) {
    Map<String, dynamic>? res = json.decode(e.body);
    if (res != null && res["type"] != null) {
      String type = res["type"];
      if ("authentication_required" == type) {
        throw SEP24AuthenticationRequiredException();
      }
    }
  }

  /// A deposit is when a user sends an external token (BTC via Bitcoin, USD via bank transfer, etc...)
  /// to an address held by an anchor. In turn, the anchor sends an equal amount of tokens on the
  /// Stellar network (minus fees) to the user's Stellar account.
  /// The deposit endpoint allows a wallet to get deposit information from an anchor, so a user has
  /// all the information needed to initiate a deposit. It also lets the anchor specify additional
  /// information that the user must submit interactively via a popup or embedded browser
  /// window to be able to deposit.
  ///
  /// Throws a [RequestErrorException] if the server responds with an error and corresponding error message.
  /// Throws a [SEP24AuthenticationRequiredException] if the server responds with an authentication_required error.
  Future<SEP24InteractiveResponse> deposit(SEP24DepositRequest request) async {
    Uri serverURI = Util.appendEndpointToUrl(
        _transferServiceAddress, 'transactions/deposit/interactive');

    _PostRequestBuilder requestBuilder =
        _PostRequestBuilder(httpClient, serverURI);

    final Map<String, String> fields = {"asset_code": request.assetCode};
    final Map<String, Uint8List> files = {};

    if (request.assetIssuer != null) {
      fields["asset_issuer"] = request.assetIssuer!;
    }

    if (request.sourceAsset != null) {
      fields["source_asset"] = request.sourceAsset!;
    }

    if (request.amount != null) {
      fields["amount"] = request.amount!;
    }

    if (request.quoteId != null) {
      fields["quote_id"] = request.quoteId!;
    }

    if (request.account != null) {
      fields["account"] = request.account!;
    }

    if (request.memoType != null) {
      fields["memo_type"] = request.memoType!;
    }

    if (request.memo != null) {
      fields["memo"] = request.memo!;
    }

    if (request.walletName != null) {
      fields["wallet_name"] = request.walletName!;
    }
    if (request.walletUrl != null) {
      fields["wallet_url"] = request.walletUrl!;
    }
    if (request.lang != null) {
      fields["lang"] = request.lang!;
    }
    if (request.claimableBalanceSupported != null) {
      fields["claimable_balance_supported"] =
          request.claimableBalanceSupported!;
    }

    if (request.kycFields != null &&
        request.kycFields?.naturalPersonKYCFields != null) {
      fields.addAll(request.kycFields!.naturalPersonKYCFields!.fields());
    }
    if (request.kycFields != null &&
        request.kycFields?.organizationKYCFields != null) {
      fields.addAll(request.kycFields!.organizationKYCFields!.fields());
    }
    if (request.customFields != null) {
      fields.addAll(request.customFields!);
    }

    // files always at the end.
    if (request.kycFields != null &&
        request.kycFields?.naturalPersonKYCFields != null) {
      files.addAll(request.kycFields!.naturalPersonKYCFields!.files());
    }
    if (request.kycFields != null &&
        request.kycFields?.organizationKYCFields != null) {
      files.addAll(request.kycFields!.organizationKYCFields!.files());
    }
    if (request.customFiles != null) {
      files.addAll(request.customFiles!);
    }

    SEP24InteractiveResponse response;
    try {
      response = await requestBuilder
          .forFields(fields)
          .forFiles(files)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      } else if (e.code != 200) {
        _handleErrorResponse(e);
      }
      throw e;
    }
    return response;
  }

  /// This operation allows a user to redeem an asset currently on the Stellar network for the real asset (BTC, USD, stock, etc...) via the anchor of the Stellar asset.
  /// The withdraw endpoint allows a wallet to get withdrawal information from an anchor, so a user has all the information needed to initiate a withdrawal.
  /// It also lets the anchor specify the url for the interactive webapp to continue with the anchor's side of the withdraw.
  ///
  /// Throws a [RequestErrorException] if the server responds with an error and corresponding error message.
  /// Throws a [SEP24AuthenticationRequiredException] if the server responds with an authentication_required error.
  Future<SEP24InteractiveResponse> withdraw(
      SEP24WithdrawRequest request) async {
    Uri serverURI = Util.appendEndpointToUrl(
        _transferServiceAddress, 'transactions/withdraw/interactive');

    _PostRequestBuilder requestBuilder =
        _PostRequestBuilder(httpClient, serverURI);

    final Map<String, String> fields = {"asset_code": request.assetCode};
    final Map<String, Uint8List> files = {};

    if (request.destinationAsset != null) {
      fields["destination_asset"] = request.destinationAsset!;
    }

    if (request.assetIssuer != null) {
      fields["asset_issuer"] = request.assetIssuer!;
    }

    if (request.amount != null) {
      fields["amount"] = request.amount!;
    }

    if (request.quoteId != null) {
      fields["quote_id"] = request.quoteId!;
    }

    if (request.account != null) {
      fields["account"] = request.account!;
    }

    if (request.memo != null) {
      fields["memo"] = request.memo!;
    }

    if (request.memoType != null) {
      fields["memo_type"] = request.memoType!;
    }

    if (request.walletName != null) {
      fields["wallet_name"] = request.walletName!;
    }

    if (request.walletUrl != null) {
      fields["wallet_url"] = request.walletUrl!;
    }

    if (request.lang != null) {
      fields["lang"] = request.lang!;
    }

    if (request.refundMemo != null) {
      fields["refund_memo"] = request.refundMemo!;
    }

    if (request.refundMemoType != null) {
      fields["refund_memo_type"] = request.refundMemoType!;
    }

    if (request.kycFields != null &&
        request.kycFields?.naturalPersonKYCFields != null) {
      fields.addAll(request.kycFields!.naturalPersonKYCFields!.fields());
    }
    if (request.kycFields != null &&
        request.kycFields?.organizationKYCFields != null) {
      fields.addAll(request.kycFields!.organizationKYCFields!.fields());
    }
    if (request.customFields != null) {
      fields.addAll(request.customFields!);
    }

    // files always at the end.
    if (request.kycFields != null &&
        request.kycFields?.naturalPersonKYCFields != null) {
      files.addAll(request.kycFields!.naturalPersonKYCFields!.files());
    }
    if (request.kycFields != null &&
        request.kycFields?.organizationKYCFields != null) {
      files.addAll(request.kycFields!.organizationKYCFields!.files());
    }
    if (request.customFiles != null) {
      files.addAll(request.customFiles!);
    }

    SEP24InteractiveResponse response;
    try {
      response = await requestBuilder
          .forFields(fields)
          .forFiles(files)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      } else if (e.code != 200) {
        _handleErrorResponse(e);
      }
      throw e;
    }
    return response;
  }

  /// The transaction history endpoint helps anchors enable a better experience for users using an external wallet.
  /// With it, wallets can display the status of deposits and withdrawals while they process and a history of past transactions with the anchor.
  /// It's only for transactions that are deposits to or withdrawals from the anchor.
  /// It returns a list of transactions from the account encoded in the authenticated JWT.
  ///
  /// Throws a [RequestErrorException] if the server responds with an error and corresponding error message.
  /// Throws a [SEP24AuthenticationRequiredException] if the server responds with an authentication_required error.
  Future<SEP24TransactionsResponse> transactions(
      SEP24TransactionsRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'transactions');

    _AnchorTransactionsRequestBuilder requestBuilder =
        _AnchorTransactionsRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "asset_code": request.assetCode,
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

    if (request.lang != null) {
      queryParams["lang"] = request.lang!;
    }

    SEP24TransactionsResponse response;
    try {
      response = await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      } else if (e.code != 200) {
        _handleErrorResponse(e);
      }
      throw e;
    }
    return response;
  }

  /// The transaction endpoint enables clients to query/validate a specific transaction at an anchor.
  /// Anchors must ensure that the SEP-10 JWT included in the request contains the Stellar account
  /// and optional memo value used when making the original deposit or withdraw request
  /// that resulted in the transaction requested using this endpoint.
  /// Throws a [RequestErrorException] if the server responds with an error and corresponding error message.
  /// Throws a [SEP24AuthenticationRequiredException] if the server responds with an authentication_required error.
  /// Throws a [SEP24TransactionNotFoundException] if the server could not find the transaction.
  Future<SEP24TransactionResponse> transaction(
      SEP24TransactionRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'transaction');

    _AnchorTransactionRequestBuilder requestBuilder =
        _AnchorTransactionRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {};

    if (request.id != null) {
      queryParams["id"] = request.id!;
    }

    if (request.stellarTransactionId != null) {
      queryParams["stellar_transaction_id"] = request.stellarTransactionId!;
    }

    if (request.externalTransactionId != null) {
      queryParams["external_transaction_id"] = request.externalTransactionId!;
    }

    if (request.lang != null) {
      queryParams["lang"] = request.lang!;
    }

    SEP24TransactionResponse response;
    try {
      response = await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 404) {
        throw SEP24TransactionNotFoundException();
      } else if (e.code == 403) {
        _handleForbiddenResponse(e);
      } else if (e.code != 200) {
        _handleErrorResponse(e);
      }
      throw e;
    }
    return response;
  }
}

/// Response of the deposit endpoint.
class SEP24DepositAsset extends Response {
  /// true if deposit for this asset is supported
  bool enabled;

  /// Optional minimum amount. No limit if not specified.
  double? minAmount;

  /// Optional maximum amount. No limit if not specified.
  double? maxAmount;

  /// Optional fixed (base) fee for deposit. In units of the deposited asset. This is in addition to any fee_percent. Omitted if there is no fee or the fee schedule is complex.
  double? feeFixed;

  /// Optional percentage fee for deposit. In percentage points. This is in addition to any fee_fixed. Omitted if there is no fee or the fee schedule is complex.
  double? feePercent;

  /// Optional minimum fee in units of the deposited asset.
  double? feeMinimum;

  SEP24DepositAsset(this.enabled, this.minAmount, this.maxAmount, this.feeFixed,
      this.feePercent, this.feeMinimum);

  factory SEP24DepositAsset.fromJson(Map<String, dynamic> json) {
    return SEP24DepositAsset(
        json['enabled'],
        convertDouble(json['min_amount']),
        convertDouble(json['max_amount']),
        convertDouble(json['fee_fixed']),
        convertDouble(json['fee_percent']),
        convertDouble(json['fee_minimum']));
  }
}

/// Response of the withdraw endpoint.
class SEP24WithdrawAsset extends Response {
  /// true if withdrawal for this asset is supported
  bool enabled;

  /// Optional minimum amount. No limit if not specified.
  double? minAmount;

  /// Optional maximum amount. No limit if not specified.
  double? maxAmount;

  /// Optional fixed (base) fee for withdraw. In units of the withdrawn asset. This is in addition to any fee_percent.
  double? feeFixed;

  /// Optional percentage fee for withdraw in percentage points. This is in addition to any fee_fixed.
  double? feePercent;

  /// Optional minimum fee in units of the withdrawn asset.
  double? feeMinimum;

  SEP24WithdrawAsset(this.enabled, this.minAmount, this.maxAmount,
      this.feeFixed, this.feePercent, this.feeMinimum);

  factory SEP24WithdrawAsset.fromJson(Map<String, dynamic> json) {
    return SEP24WithdrawAsset(
        json['enabled'],
        convertDouble(json['min_amount']),
        convertDouble(json['max_amount']),
        convertDouble(json['fee_fixed']),
        convertDouble(json['fee_percent']),
        convertDouble(json['fee_minimum']));
  }
}

/// Part of the response of the info endpoint.
class FeeEndpointInfo extends Response {
  /// true if the endpoint is available.
  bool enabled;

  /// true if client must be authenticated before accessing the fee endpoint.
  bool authenticationRequired;

  FeeEndpointInfo(this.enabled, this.authenticationRequired);

  factory FeeEndpointInfo.fromJson(Map<String, dynamic> json) {
    bool? auth = json['authentication_required'];
    return FeeEndpointInfo(json['enabled'], auth != null ? auth : false);
  }
}

/// Part of the response of the info endpoint.
class FeatureFlags extends Response {
  /// Whether or not the anchor supports creating accounts for users requesting deposits. Defaults to true.
  bool accountCreation;

  /// Whether or not the anchor supports sending deposit funds as claimable balances. This is relevant for users of Stellar accounts without a trustline to the requested asset. Defaults to false.
  bool claimableBalances;

  FeatureFlags(this.accountCreation, this.claimableBalances);

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    bool? accCreation = json['account_creation'];
    bool? claimableB = json['claimable_balances'];
    return FeatureFlags(accCreation != null ? accCreation : true,
        claimableB != null ? claimableB : false);
  }
}

/// Response of the info endpoint.
class SEP24InfoResponse extends Response {
  Map<String, SEP24DepositAsset>? depositAssets;
  Map<String, SEP24WithdrawAsset>? withdrawAssets;
  FeeEndpointInfo? feeEndpointInfo;
  FeatureFlags? featureFlags;

  SEP24InfoResponse(this.depositAssets, this.withdrawAssets,
      this.feeEndpointInfo, this.featureFlags);

  factory SEP24InfoResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? depositDynamic =
        json['deposit'] == null ? null : json['deposit'];

    Map<String, SEP24DepositAsset> depositMap = {};
    if (depositDynamic != null) {
      depositDynamic.forEach((key, value) {
        depositMap[key] = SEP24DepositAsset.fromJson(value);
      });
    }
    Map<String, dynamic>? withdrawDynamic =
        json['withdraw'] == null ? null : json['withdraw'];

    Map<String, SEP24WithdrawAsset> withdrawMap = {};
    if (withdrawDynamic != null) {
      withdrawDynamic.forEach((key, value) {
        withdrawMap[key] = SEP24WithdrawAsset.fromJson(value);
      });
    }

    return SEP24InfoResponse(
        depositMap,
        withdrawMap,
        json['fee'] == null ? null : FeeEndpointInfo.fromJson(json['fee']),
        json['features'] == null
            ? null
            : FeatureFlags.fromJson(json['features']));
  }
}

/// Requests basic info about what the anchors TRANSFER_SERVER_SEP0024 supports to wallets and clients.
class _InfoRequestBuilder extends RequestBuilder {
  _InfoRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _InfoRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24InfoResponse> requestExecute(
      http.Client httpClient, Uri uri) async {
    TypeToken<SEP24InfoResponse> type = TypeToken<SEP24InfoResponse>();
    ResponseHandler<SEP24InfoResponse> responseHandler =
        ResponseHandler<SEP24InfoResponse>(type);

    final Map<String, String> infoHeaders = RequestBuilder.headers;
    return await httpClient.get(uri, headers: infoHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24InfoResponse> execute() {
    return _InfoRequestBuilder.requestExecute(this.httpClient, this.buildUri());
  }
}

/// Request of the fee endpoint.
class SEP24FeeRequest {
  /// Kind of operation (deposit or withdraw).
  late String operation;

  /// (optional) Type of deposit or withdrawal (SEPA, bank_account, cash, etc...).
  String? type;

  /// Asset code.
  late String assetCode;

  /// Amount of the asset that will be deposited/withdrawn.
  late double amount;

  /// (optional) jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

/// Response of the fee endpoint.
class SEP24FeeResponse extends Response {
  /// The total fee (in units of the asset involved) that would be charged to deposit/withdraw the specified amount of asset_code.
  double? fee;

  SEP24FeeResponse(this.fee);

  factory SEP24FeeResponse.fromJson(Map<String, dynamic> json) =>
      SEP24FeeResponse(convertDouble(json['fee']));
}

/// Requests the fee data if available.
class _FeeRequestBuilder extends RequestBuilder {
  _FeeRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _FeeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24FeeResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<SEP24FeeResponse> type = TypeToken<SEP24FeeResponse>();
    ResponseHandler<SEP24FeeResponse> responseHandler =
        ResponseHandler<SEP24FeeResponse>(type);

    final Map<String, String> feeHeaders = RequestBuilder.headers;
    if (jwt != null) {
      feeHeaders["Authorization"] = "Bearer $jwt";
    }

    return await httpClient.get(uri, headers: feeHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24FeeResponse> execute(String? jwt) {
    return _FeeRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

/// Request of the deposit endpoint.
class SEP24DepositRequest {
  /// jwt previously received from the anchor via the SEP-10 authentication flow
  late String jwt;

  /// The code of the stellar asset the user wants to receive for their deposit with the anchor.
  /// The value passed must match one of the codes listed in the /info response's deposit object.
  /// 'native' is a special asset_code that represents the native XLM token.
  late String assetCode;

  /// (optional) The issuer of the stellar asset the user wants to receive for their deposit with the anchor.
  /// If assetIssuer is not provided, the anchor will use the asset issued by themselves as described in their TOML file.
  /// If 'native' is specified as the assetCode, assetIssuer must be not be set.
  String? assetIssuer;

  /// (optional) - string in Asset Identification Format - The asset user wants to send. Note, that this is the asset user initially holds (off-chain or fiat asset).
  /// If this is not provided, it will be collected in the interactive flow.
  /// When quote_id is specified, this parameter must match the quote's sell_asset asset code or be omitted.
  String? sourceAsset;

  /// (optional) Amount of asset requested to deposit. If this is not provided it will be collected in the interactive flow.
  String? amount;

  /// (optional) The id returned from a SEP-38 POST /quote response.
  String? quoteId;

  /// (optional) The Stellar (G...) or muxed account (M...) the client will use as the source of the withdrawal payment to the anchor.
  /// Defaults to the account authenticated via SEP-10 if not specified.
  String? account;

  /// (optional) Value of memo to attach to transaction, for hash this should be base64-encoded.
  /// Because a memo can be specified in the SEP-10 JWT for Shared Accounts, this field can be different than the value included in the SEP-10 JWT.
  /// For example, a client application could use the value passed for this parameter as a reference number used to match payments made to account.
  String? memo;

  /// (optional) type of memo that anchor should attach to the Stellar payment transaction, one of text, id or hash
  String? memoType;

  /// (optional) In communications / pages about the deposit, anchor should display the wallet name to the user to explain where funds are going.
  String? walletName;

  /// (optional) Anchor should link to this when notifying the user that the transaction has completed.
  String? walletUrl;

  /// (optional) Defaults to en if not specified or if the specified language is not supported.
  /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
  /// error fields in the response, as well as the interactive flow UI and any other user-facing strings
  /// returned for this transaction should be in this language.
  String? lang;

  /// (optional) True if the client supports receiving deposit transactions as a claimable balance, false otherwise.
  String? claimableBalanceSupported;

  /// Additionally, any SEP-9 parameters may be passed as well to make the onboarding experience simpler.
  StandardKYCFields? kycFields;

  /// Custom SEP-9 fields that you can use for transmission (fieldname,value)
  Map<String, String>? customFields;

  /// Custom SEP-9 files that you can use for transmission (fieldname, value)
  Map<String, Uint8List>? customFiles;
}

/// Represents an transfer service deposit or withdraw response.
class SEP24InteractiveResponse extends Response {
  /// Always set to interactive_customer_info_needed.
  String type;

  /// URL hosted by the anchor. The wallet should show this URL to the user as a popup.
  String url;

  /// The anchor's internal ID for this deposit / withdrawal request. The wallet will use this ID to query the /transaction endpoint to check status of the request.
  String id;

  SEP24InteractiveResponse(this.type, this.url, this.id);

  factory SEP24InteractiveResponse.fromJson(Map<String, dynamic> json) =>
      SEP24InteractiveResponse(json['type'], json['url'], json['id']);
}

class _PostRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, Uint8List>? _files;

  _PostRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _PostRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  _PostRequestBuilder forFiles(Map<String, Uint8List> files) {
    _files = files;
    return this;
  }

  static Future<SEP24InteractiveResponse> requestExecute(
      http.Client httpClient,
      Uri uri,
      Map<String, String>? fields,
      Map<String, Uint8List>? files,
      String jwt) async {
    TypeToken<SEP24InteractiveResponse> type =
        TypeToken<SEP24InteractiveResponse>();
    ResponseHandler<SEP24InteractiveResponse> responseHandler =
        ResponseHandler<SEP24InteractiveResponse>(type);

    final Map<String, String> hHeaders = RequestBuilder.headers;
    hHeaders["Authorization"] = "Bearer $jwt";
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(hHeaders);
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (files != null) {
      files.forEach((key, value) {
        request.files.add(http.MultipartFile.fromBytes(key, value));
      });
    }
    http.StreamedResponse str = await httpClient.send(request);
    http.Response res = await http.Response.fromStream(str);
    return responseHandler.handleResponse(res);
  }

  Future<SEP24InteractiveResponse> execute(String jwt) {
    return _PostRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, _files, jwt);
  }
}

/// Request of the withdraw endpoint.
class SEP24WithdrawRequest {
  /// jwt previously received from the anchor via the SEP-10 authentication flow
  late String jwt;

  /// Code of the asset the user wants to withdraw. The value passed must match one of the codes listed in the /info response's withdraw object.
  /// 'native' is a special asset_code that represents the native XLM token.
  late String assetCode;

  /// (optional) The issuer of the stellar asset the user wants to withdraw with the anchor.
  /// If asset_issuer is not provided, the anchor should use the asset issued by themselves as described in their TOML file.
  /// If 'native' is specified as the asset_code, asset_issuer must be not be set.
  String? assetIssuer;

  /// (optional) string in Asset Identification Format - The asset user wants to receive. It's an off-chain or fiat asset.
  /// If this is not provided, it will be collected in the interactive flow.
  /// When quote_id is specified, this parameter must match the quote's buy_asset asset code or be omitted.
  String? destinationAsset;

  /// (optional) Amount of asset requested to withdraw. If this is not provided it will be collected in the interactive flow.
  String? amount;

  /// (optional) The id returned from a SEP-38 POST /quote response.
  String? quoteId;

  /// (optional) The Stellar (G...) or muxed account (M...) the client wants to use as the destination of the payment sent by the anchor.
  /// Defaults to the account authenticated via SEP-10 if not specified.
  String? account;

  /// (deprecated, optional) This field was originally intended to differentiate users of the same Stellar account.
  /// However, the anchor should use the sub value included in the decoded SEP-10 JWT instead.
  /// Anchors should still support this parameter to maintain support for outdated clients.
  /// See the Shared Account Authentication section for more information.
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#shared-omnibus-or-pooled-accounts
  String? memo;

  /// (deprecated, optional) Type of memo. One of text, id or hash. Deprecated because memos used to identify users of the same Stellar account should always be of type of id.
  String? memoType;

  /// (optional) In communications / pages about the withdrawal, anchor should display the wallet name to the user to explain where funds are coming from.
  String? walletName;

  /// (optional) Anchor can show this to the user when referencing the wallet involved in the withdrawal (ex. in the anchor's transaction history).
  String? walletUrl;

  /// (optional) Defaults to en if not specified or if the specified language is not supported.
  /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
  /// error fields in the response, as well as the interactive flow UI and any other user-facing
  /// strings returned for this transaction should be in this language.
  String? lang;

  /// (optional) The memo the anchor must use when sending refund payments back to the user.
  /// If not specified, the anchor should use the same memo used by the user to send the original payment.
  /// If specified, refund_memo_type must also be specified.
  String? refundMemo;

  /// (optional) The type of the refund_memo. Can be id, text, or hash.
  /// See the memos documentation for more information.
  /// If specified, refund_memo must also be specified.
  /// https://developers.stellar.org/docs/encyclopedia/memos
  String? refundMemoType;

  /// Additionally, any SEP-9 parameters may be passed as well to make the onboarding experience simpler.
  StandardKYCFields? kycFields;

  /// Custom SEP-9 fields that you can use for transmission (fieldname,value)
  Map<String, String>? customFields;

  /// Custom SEP-9 files that you can use for transmission (fieldname, value)
  Map<String, Uint8List>? customFiles;
}

/// Request of the transactions endpoint.
class SEP24TransactionsRequest {
  /// jwt previously received from the anchor via the SEP-10 authentication flow
  late String jwt;

  /// The code of the asset of interest. E.g. BTC, ETH, USD, INR, etc.
  late String assetCode;

  /// (optional) The response should contain transactions starting on or after this date & time. UTC ISO 8601 string.
  DateTime? noOlderThan;

  /// (optional) The response should contain at most limit transactions.
  int? limit;

  /// (optional) The kind of transaction that is desired. Should be either deposit or withdrawal.
  String? kind;

  /// (optional) The response should contain transactions starting prior to this ID (exclusive).
  String? pagingId;

  /// (optional) Defaults to en if not specified or if the specified language is not supported.
  /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
  String? lang;
}

/// Represents an anchor transaction
class SEP24Transaction extends Response {
  /// Unique, anchor-generated id for the deposit/withdrawal.
  String id;

  /// deposit or withdrawal.
  String kind;

  /// Processing status of deposit/withdrawal.
  String status;

  /// (optional) Estimated number of seconds until a status change is expected.
  int? statusEta;

  /// (optional) True if the anchor has verified the user's KYC information for this transaction.
  bool? kycVerified;

  /// (optional) A URL that is opened by wallets after the interactive flow is complete. It can include banking information for users to start deposits, the status of the transaction, or any other information the user might need to know about the transaction.
  String moreInfoUrl;

  /// (optional) 	Amount received by anchor at start of transaction as a string with up to 7 decimals. Excludes any fees charged before the anchor received the funds.
  String? amountIn;

  /// (optional)  The asset received or to be received by the Anchor. Must be present if the deposit/withdraw was made using non-equivalent assets.
  /// The value must be in SEP-38 Asset Identification Format.
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#asset-identification-format
  /// See also the Asset Exchanges section for more information.
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#asset-exchanges
  String? amountInAsset;

  /// (optional) Amount sent by anchor to user at end of transaction as a string with up to 7 decimals.
  /// Excludes amount converted to XLM to fund account and any external fees.
  String? amountOut;

  /// (optional) The asset delivered or to be delivered to the user. Must be present if the deposit/withdraw was made using non-equivalent assets.
  /// The value must be in SEP-38 Asset Identification Format.
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#asset-identification-format
  /// See also the Asset Exchanges section for more information.
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#asset-exchanges
  String? amountOutAsset;

  /// (optional) Amount of fee charged by anchor.
  String? amountFee;

  /// (optional) The asset in which fees are calculated in. Must be present if the deposit/withdraw was made using non-equivalent assets.
  /// The value must be in SEP-38 Asset Identification Format.
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0038.md#asset-identification-format
  /// See also the Asset Exchanges section for more information.
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#asset-exchanges
  String? amountFeeAsset;

  /// (optional) The ID of the quote used when creating this transaction. Should be present if a quote_id
  /// was included in the POST /transactions/deposit/interactive or POST /transactions/withdraw/interactive request.
  /// Clients should be aware that the quote_id may not be present in older implementations.
  String? quoteId;

  /// Start date and time of transaction. UTC ISO 8601 string
  String startedAt;

  /// (optional) The date and time of transaction reaching completed or refunded status. UTC ISO 8601 string
  String? completedAt;

  /// (optional) The date and time of transaction reaching the current status. UTC ISO 8601 string
  String? updatedAt;

  /// (optional) transaction_id on Stellar network of the transfer that either completed the deposit or started the withdrawal.
  String? stellarTransactionId;

  /// (optional) ID of transaction on external network that either started the deposit or completed the withdrawal.
  String? externalTransactionId;

  /// (optional) Human readable explanation of transaction status, if needed.
  String? message;

  /// (deprecated, optional) This field is deprecated in favor of the refunds object and the refunded status.
  /// True if the transaction was refunded in full. False if the transaction was partially refunded or not refunded.
  /// For more details about any refunds, see the refunds object.
  bool? refunded;

  /// (optional) An object describing any on or off-chain refund associated with this transaction.
  Refund? refunds;

  /// In case of deposit: Sent from address, perhaps BTC, IBAN, or bank account.
  /// In case of withdraw: Stellar address the assets were withdrawn from.
  String? from;

  /// In case of deposit: Stellar address the deposited assets were sent to.
  /// In case of withdraw: Sent to address (perhaps BTC, IBAN, or bank account in the case of a withdrawal, Stellar address in the case of a deposit).
  String? to;

  //Fields for deposit transactions
  /// (optional) This is the memo (if any) used to transfer the asset to the to Stellar address.
  String? depositMemo;

  /// (optional) Type for the deposit_memo.
  String? depositMemoType;

  /// (optional) ID of the Claimable Balance used to send the asset initially requested.
  String? claimableBalanceId;

  //Fields for withdraw transactions
  /// If this is a withdrawal, this is the anchor's Stellar account that the user transferred (or will transfer) their asset to.
  String? withdrawAnchorAccount;

  /// Memo used when the user transferred to withdraw_anchor_account.
  /// Assigned null if the withdraw is not ready to receive payment, for example if KYC is not completed.
  String? withdrawMemo;

  /// Memo type for withdraw_memo.
  String? withdrawMemoType;

  SEP24Transaction(
      this.id,
      this.kind,
      this.status,
      this.statusEta,
      this.kycVerified,
      this.moreInfoUrl,
      this.amountIn,
      this.amountInAsset,
      this.amountOut,
      this.amountOutAsset,
      this.amountFee,
      this.amountFeeAsset,
      this.quoteId,
      this.startedAt,
      this.completedAt,
      this.updatedAt,
      this.stellarTransactionId,
      this.externalTransactionId,
      this.message,
      this.refunded,
      this.refunds,
      this.from,
      this.to,
      this.depositMemo,
      this.depositMemoType,
      this.claimableBalanceId,
      this.withdrawAnchorAccount,
      this.withdrawMemo,
      this.withdrawMemoType);

  factory SEP24Transaction.fromJson(Map<String, dynamic> json) {
    Refund? refunds;
    if (json['refunds'] != null) {
      refunds = Refund.fromJson(json['refunds']);
    }
    return SEP24Transaction(
        json['id'],
        json['kind'],
        json['status'],
        convertInt(json['status_eta']),
        json['kyc_verified'],
        json['more_info_url'],
        json['amount_in'],
        json['amount_in_asset'],
        json['amount_out'],
        json['amount_out_asset'],
        json['amount_fee'],
        json['amount_fee_asset'],
        json['quote_id'],
        json['started_at'],
        json['completed_at'],
        json['updated_at'],
        json['stellar_transaction_id'],
        json['external_transaction_id'],
        json['message'],
        json['refunded'],
        refunds,
        json['from'],
        json['to'],
        json['deposit_memo'],
        json['deposit_memo_type'],
        json['claimable_balance_id'],
        json['withdraw_anchor_account'],
        json['withdraw_memo'],
        json['withdraw_memo_type']);
  }
}

class SEP24TransactionsResponse extends Response {
  List<SEP24Transaction> transactions;

  SEP24TransactionsResponse(this.transactions);

  factory SEP24TransactionsResponse.fromJson(Map<String, dynamic> json) =>
      SEP24TransactionsResponse((json['transactions'] as List)
          .map((e) => SEP24Transaction.fromJson(e))
          .toList());
}

// Requests the transaction history data.
class _AnchorTransactionsRequestBuilder extends RequestBuilder {
  _AnchorTransactionsRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _AnchorTransactionsRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24TransactionsResponse> requestExecute(
      http.Client httpClient, Uri uri, String jwt) async {
    TypeToken<SEP24TransactionsResponse> type =
        TypeToken<SEP24TransactionsResponse>();
    ResponseHandler<SEP24TransactionsResponse> responseHandler =
        ResponseHandler<SEP24TransactionsResponse>(type);

    final Map<String, String> atHeaders = RequestBuilder.headers;
    atHeaders["Authorization"] = "Bearer $jwt";
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24TransactionsResponse> execute(String jwt) {
    return _AnchorTransactionsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

/// Part of the transaction result.
class Refund extends Response {
  /// The total amount refunded to the user, in units of amount_in_asset.
  /// If a full refund was issued, this amount should match amount_in.
  String amountRefunded;

  /// The total amount charged in fees for processing all refund payments, in units of amount_in_asset.
  /// The sum of all fee values in the payments object list should equal this value.
  String amountFee;

  /// A list of objects containing information on the individual payments made back to the user as refunds.
  List<RefundPayment> payments;

  Refund(this.amountRefunded, this.amountFee, this.payments);

  factory Refund.fromJson(Map<String, dynamic> json) => Refund(
      json['amount_refunded'],
      json['amount_fee'],
      (json['payments'] as List)
          .map((e) => RefundPayment.fromJson(e))
          .toList());
}

/// Part of the transaction result.
class RefundPayment extends Response {
  /// The payment ID that can be used to identify the refund payment.
  /// This is either a Stellar transaction hash or an off-chain payment identifier,
  /// such as a reference number provided to the user when the refund was initiated.
  /// This id is not guaranteed to be unique.
  String id;

  /// stellar or external.
  String idType;

  /// The amount sent back to the user for the payment identified by id, in units of amount_in_asset.
  String amount;

  /// The amount charged as a fee for processing the refund, in units of amount_in_asset.
  String fee;

  RefundPayment(this.id, this.idType, this.amount, this.fee);

  factory RefundPayment.fromJson(Map<String, dynamic> json) =>
      RefundPayment(json['id'], json['id_type'], json['amount'], json['fee']);
}

/// Request for the transactions endpoint.
/// One of id, stellar_transaction_id or external_transaction_id is required.
class SEP24TransactionRequest {
  /// jwt previously received from the anchor via the SEP-10 authentication flow
  late String jwt;

  /// (optional) The id of the transaction.
  String? id;

  /// (optional) The stellar transaction id of the transaction.
  String? stellarTransactionId;

  /// (optional) The external transaction id of the transaction.
  String? externalTransactionId;

  /// (optional) Defaults to en if not specified or if the specified language is not supported.
  /// Language code specified using RFC 4646 which means it can also accept locale in the format en-US.
  String? lang;
}

class SEP24TransactionResponse extends Response {
  SEP24Transaction transaction;

  SEP24TransactionResponse(this.transaction);

  factory SEP24TransactionResponse.fromJson(Map<String, dynamic> json) =>
      SEP24TransactionResponse(SEP24Transaction.fromJson(json['transaction']));
}

// Requests the transaction data for a specific transaction.
class _AnchorTransactionRequestBuilder extends RequestBuilder {
  _AnchorTransactionRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _AnchorTransactionRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24TransactionResponse> requestExecute(
      http.Client httpClient, Uri uri, String jwt) async {
    TypeToken<SEP24TransactionResponse> type =
        TypeToken<SEP24TransactionResponse>();
    ResponseHandler<SEP24TransactionResponse> responseHandler =
        ResponseHandler<SEP24TransactionResponse>(type);

    final Map<String, String> atHeaders = RequestBuilder.headers;
    atHeaders["Authorization"] = "Bearer $jwt";
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24TransactionResponse> execute(String jwt) {
    return _AnchorTransactionRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class RequestErrorException implements Exception {
  String error;
  RequestErrorException(this.error);
  String toString() {
    return error;
  }
}

class SEP24AuthenticationRequiredException implements Exception {
  String toString() {
    return "The endpoint requires authentication.";
  }
}

class SEP24TransactionNotFoundException implements Exception {
  String toString() {
    return "The anchor could not find the transaction";
  }
}
