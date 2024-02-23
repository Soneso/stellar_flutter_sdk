import 'dart:convert';

import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';

/// Implements SEP-0006 - Deposit and Withdrawal API
/// See <a href="https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md" target="_blank">Deposit and Withdrawal API</a>
class TransferServerService {
  late String _transferServiceAddress;
  http.Client httpClient = http.Client();

  TransferServerService(this._transferServiceAddress,
      {http.Client? httpClient}) {
    if (httpClient != null) {
      this.httpClient = httpClient;
    } else {
      this.httpClient = http.Client();
    }
  }

  static Future<TransferServerService> fromDomain(String domain,
      {http.Client? httpClient}) async {
    StellarToml toml =
        await StellarToml.fromDomain(domain, httpClient: httpClient);
    String? transferServer = toml.generalInformation.transferServer;
    checkNotNull(transferServer,
        "transfer server not found in stellar toml of domain " + domain);
    return TransferServerService(transferServer!, httpClient: httpClient);
  }

  /// Get basic info from the anchor about what their TRANSFER_SERVER supports.
  /// [language] (optional) Defaults to en if not specified or if the specified
  /// language is not supported. Language code specified using RFC 4646.
  /// Error fields and other human readable messages in the response should
  /// be in this language.
  /// [jwt] token previously received from the anchor via the SEP-10
  /// authentication flow
  Future<InfoResponse> info({String? language, String? jwt}) async {
    Uri serverURI = Util.appendEndpointToUrl(_transferServiceAddress, 'info');

    _InfoRequestBuilder requestBuilder =
        _InfoRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {};

    if (language != null) {
      queryParams["lang"] = language;
    }

    InfoResponse response =
        await requestBuilder.forQueryParameters(queryParams).execute(jwt);

    return response;
  }

  /// A deposit is when a user sends an external token (BTC via Bitcoin,
  /// USD via bank transfer, etc...) to an address held by an anchor. In turn,
  /// the anchor sends an equal amount of tokens on the Stellar network
  /// (minus fees) to the user's Stellar account.
  ///
  /// If the anchor supports SEP-38 quotes, it can also provide a bridge
  /// between non-equivalent tokens. For example, the anchor can receive ARS
  /// via bank transfer and in return send the equivalent value (minus fees)
  /// as USDC on the Stellar network to the user's Stellar account.
  /// That kind of deposit is covered in GET /deposit-exchange.
  ///
  /// The deposit endpoint allows a wallet to get deposit information from
  /// an anchor, so a user has all the information needed to initiate a deposit.
  /// It also lets the anchor specify additional information (if desired) that
  /// the user must submit via SEP-12 to be able to deposit.
  Future<DepositResponse> deposit(DepositRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'deposit');

    _DepositRequestBuilder requestBuilder =
        _DepositRequestBuilder(httpClient, serverURI);

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
      queryParams["claimable_balance_supported"] =
          request.claimableBalanceSupported!;
    }
    if (request.customerId != null) {
      queryParams["customer_id"] = request.customerId!;
    }
    if (request.locationId != null) {
      queryParams["location_id"] = request.locationId!;
    }

    DepositResponse response;
    try {
      response = await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }

    return response;
  }

  /// If the anchor supports SEP-38 quotes, it can provide a deposit that makes
  /// a bridge between non-equivalent tokens by receiving, for instance BRL
  /// via bank transfer and in return sending the equivalent value (minus fees)
  /// as USDC to the user's Stellar account.
  ///
  /// The /deposit-exchange endpoint allows a wallet to get deposit information
  /// from an anchor when the user intends to make a conversion between
  /// non-equivalent tokens. With this endpoint, a user has all the information
  /// needed to initiate a deposit and it also lets the anchor specify
  /// additional information (if desired) that the user must submit via SEP-12.
  Future<DepositResponse> depositExchange(
      DepositExchangeRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'deposit-exchange');

    _DepositRequestBuilder requestBuilder =
        _DepositRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "destination_asset": request.destinationAsset,
      "source_asset": request.sourceAsset,
      "amount": request.amount,
      "account": request.account,
    };

    if (request.quoteId != null) {
      queryParams["quote_id"] = request.quoteId!;
    }
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
    if (request.countryCode != null) {
      queryParams["country_code"] = request.countryCode!;
    }
    if (request.claimableBalanceSupported != null) {
      queryParams["claimable_balance_supported"] =
          request.claimableBalanceSupported!;
    }
    if (request.customerId != null) {
      queryParams["customer_id"] = request.customerId!;
    }
    if (request.locationId != null) {
      queryParams["location_id"] = request.locationId!;
    }

    return await requestBuilder.forQueryParameters(queryParams)
        .execute(request.jwt);
  }

  /// A withdraw is when a user redeems an asset currently on the
  /// Stellar network for its equivalent off-chain asset via the Anchor.
  /// For instance, a user redeeming their NGNT in exchange for fiat NGN.
  ///
  /// If the anchor supports SEP-38 quotes, it can also provide a bridge
  /// between non-equivalent tokens. For example, the anchor can receive USDC
  /// from the Stellar network and in return send the equivalent value
  /// (minus fees) as NGN to the user's bank account.
  /// That kind of withdrawal is covered in GET /withdraw-exchange.
  ///
  /// The /withdraw endpoint allows a wallet to get withdrawal information
  /// from an anchor, so a user has all the information needed to initiate
  /// a withdrawal. It also lets the anchor specify additional information
  /// (if desired) that the user must submit via SEP-12 to be able to withdraw.
  Future<WithdrawResponse> withdraw(WithdrawRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'withdraw');

    _WithdrawRequestBuilder requestBuilder =
        _WithdrawRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "asset_code": request.assetCode,
      "type": request.type,
    };

    if (request.dest != null) {
      queryParams["dest"] = request.dest!;
    }
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
    if (request.refundMemo != null) {
      queryParams["refund_memo"] = request.refundMemo!;
    }
    if (request.refundMemoType != null) {
      queryParams["refund_memo_type"] = request.refundMemoType!;
    }
    if (request.customerId != null) {
      queryParams["customer_id"] = request.customerId!;
    }
    if (request.locationId != null) {
      queryParams["location_id"] = request.locationId!;
    }

    WithdrawResponse response;
    try {
      response = await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }
    return response;
  }

  /// If the anchor supports SEP-38 quotes, it can provide a withdraw that makes
  /// a bridge between non-equivalent tokens by receiving, for instance USDC
  /// from the Stellar network and in return sending the equivalent value
  /// (minus fees) as NGN to the user's bank account.
  ///
  /// The /withdraw-exchange endpoint allows a wallet to get withdraw
  /// information from an anchor when the user intends to make a conversion
  /// between non-equivalent tokens. With this endpoint, a user has all the
  /// information needed to initiate a withdraw and it also lets the anchor
  /// specify additional information (if desired) that the user must submit
  /// via SEP-12.
  Future<WithdrawResponse> withdrawExchange(
      WithdrawExchangeRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'withdraw-exchange');

    _WithdrawRequestBuilder requestBuilder =
        _WithdrawRequestBuilder(httpClient, serverURI);

    final Map<String, String> queryParams = {
      "source_asset": request.sourceAsset,
      "destination_asset": request.destinationAsset,
      "amount": request.amount,
      "type": request.type,
    };

    if (request.quoteId != null) {
      queryParams["quote_id"] = request.quoteId!;
    }
    if (request.dest != null) {
      queryParams["dest"] = request.dest!;
    }
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
    if (request.countryCode != null) {
      queryParams["country_code"] = request.countryCode!;
    }
    if (request.refundMemo != null) {
      queryParams["refund_memo"] = request.refundMemo!;
    }
    if (request.refundMemoType != null) {
      queryParams["refund_memo_type"] = request.refundMemoType!;
    }
    if (request.customerId != null) {
      queryParams["customer_id"] = request.customerId!;
    }
    if (request.locationId != null) {
      queryParams["location_id"] = request.locationId!;
    }

    return await requestBuilder.forQueryParameters(queryParams)
        .execute(request.jwt);
  }

  _handleForbiddenResponse(ErrorResponse e) {
    Map<String, dynamic>? res = json.decode(e.body);
    if (res != null && res["type"] != null) {
      String type = res["type"];
      if ("non_interactive_customer_info_needed" == type) {
        throw CustomerInformationNeededException(
            CustomerInformationNeededResponse.fromJson(res));
      } else if ("customer_info_status" == type) {
        throw CustomerInformationStatusException(
            CustomerInformationStatusResponse.fromJson(res));
      } else if ("authentication_required" == type) {
        throw AuthenticationRequiredException();
      }
    }
  }

  Future<FeeResponse> fee(FeeRequest request) async {
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

    FeeResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }

  /// The transaction history endpoint helps anchors enable a better
  /// experience for users using an external wallet.
  /// With it, wallets can display the status of deposits and withdrawals
  /// while they process and a history of past transactions with the anchor.
  /// It's only for transactions that are deposits to or withdrawals from
  /// the anchor.
  Future<AnchorTransactionsResponse> transactions(
      AnchorTransactionsRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'transactions');

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

    if (request.lang != null) {
      queryParams["lang"] = request.kind!;
    }

    AnchorTransactionsResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }

  /// The transaction endpoint enables clients to query/validate a
  /// specific transaction at an anchor.
  Future<AnchorTransactionResponse> transaction(
      AnchorTransactionRequest request) async {
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
    AnchorTransactionResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }

  Future<http.Response> patchTransaction(
      PatchTransactionRequest request) async {
    checkNotNull(request.id, "request.id cannot be null");
    checkNotNull(request.fields, "request.fields cannot be null");
    Uri serverURI = Util.appendEndpointToUrl(
        _transferServiceAddress, 'transactions/${request.id}');

    _PatchTransactionRequestBuilder requestBuilder =
        _PatchTransactionRequestBuilder(httpClient, serverURI);

    http.Response response =
        await requestBuilder.forFields(request.fields!).execute(request.jwt);
    return response;
  }
}

class DepositRequest {
  /// The code of the on-chain asset the user wants to get from the Anchor
  /// after doing an off-chain deposit. The value passed must match one of the
  /// codes listed in the /info response's deposit object.
  String assetCode;

  /// The stellar or muxed account ID of the user that wants to deposit.
  /// This is where the asset token will be sent. Note that the account
  /// specified in this request could differ from the account authenticated
  /// via SEP-10.
  String account;

  /// (optional) Type of memo that the anchor should attach to the Stellar
  /// payment transaction, one of text, id or hash.
  String? memoType;

  /// (optional) Value of memo to attach to transaction, for hash this should
  /// be base64-encoded. Because a memo can be specified in the SEP-10 JWT for
  /// Shared Accounts, this field as well as memoType can be different than the
  /// values included in the SEP-10 JWT. For example, a client application
  /// could use the value passed for this parameter as a reference number used
  /// to match payments made to account.
  String? memo;

  /// (optional) Email address of depositor. If desired, an anchor can use
  /// this to send email updates to the user about the deposit.
  String? emailAddress;

  /// (optional) Type of deposit. If the anchor supports multiple deposit
  /// methods (e.g. SEPA or SWIFT), the wallet should specify type. This field
  /// may be necessary for the anchor to determine which KYC fields to collect.
  String? type;

  /// (deprecated, optional) In communications / pages about the deposit,
  /// anchor should display the wallet name to the user to explain where funds
  /// are going. However, anchors should use client_domain (for non-custodial)
  /// and sub value of JWT (for custodial) to determine wallet information.
  String? walletName;

  /// (deprecated,optional) Anchor should link to this when notifying the user
  /// that the transaction has completed. However, anchors should use
  /// client_domain (for non-custodial) and sub value of JWT (for custodial)
  /// to determine wallet information.
  String? walletUrl;

  /// (optional) Defaults to en. Language code specified using ISO 639-1.
  /// error fields in the response should be in this language.
  String? lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the
  /// status property of the transaction created as a result of this request
  /// changes. The JSON message should be identical to the response format
  /// for the /transaction endpoint.
  String? onChangeCallback;

  /// (optional) The amount of the asset the user would like to deposit with
  /// the anchor. This field may be necessary for the anchor to determine
  /// what KYC information is necessary to collect.
  String? amount;

  ///  (optional) The ISO 3166-1 alpha-3 code of the user's current address.
  ///  This field may be necessary for the anchor to determine what KYC
  ///  information is necessary to collect.
  String? countryCode;

  /// (optional) true if the client supports receiving deposit transactions as
  /// a claimable balance, false otherwise.
  String? claimableBalanceSupported;

  /// (optional) id of an off-chain account (managed by the anchor) associated
  /// with this user's Stellar account (identified by the JWT's sub field).
  /// If the anchor supports SEP-12, the customerId field should match the
  /// SEP-12 customer's id. customerId should be passed only when the off-chain
  /// id is know to the client, but the relationship between this id and the
  /// user's Stellar account is not known to the Anchor.
  String? customerId;

  /// (optional) id of the chosen location to drop off cash
  String? locationId;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  DepositRequest(
      {required this.assetCode,
      required this.account,
      this.memoType,
      this.memo,
      this.emailAddress,
      this.type,
      this.walletName,
      this.walletUrl,
      this.lang,
      this.onChangeCallback,
      this.amount,
      this.countryCode,
      this.claimableBalanceSupported,
      this.customerId,
      this.locationId,
      this.jwt});
}

/// Represents an transfer service deposit response.
class DepositResponse extends Response {
  /// (deprecated, use instructions instead) Terse but complete instructions
  /// for how to deposit the asset. In the case of most cryptocurrencies it is
  /// just an address to which the deposit should be sent.
  String? how;

  /// (optional) The anchor's ID for this deposit. The wallet will use this ID
  /// to query the /transaction endpoint to check status of the request.
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

  /// (optional) Object with additional information about the deposit process.
  ExtraInfo? extraInfo;

  /// (optional) A Map containing details that describe how to complete
  /// the off-chain deposit. The map has SEP-9 financial account fields as keys
  /// and its values are DepositInstruction objects.
  Map<String, DepositInstruction>? instructions;

  DepositResponse(this.how, this.id, this.eta, this.minAmount, this.maxAmount,
      this.feeFixed, this.feePercent, this.extraInfo, this.instructions);

  factory DepositResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? instructionsJson =
        json['instructions'] == null ? null : json['instructions'];

    Map<String, DepositInstruction>? instructions;
    if (instructionsJson != null) {
      instructions = {};
      instructionsJson.forEach((key, value) {
        instructions![key] = DepositInstruction.fromJson(value);
      });
    }

    return DepositResponse(
        json['how'],
        json['id'],
        convertInt(json['eta']),
        convertDouble(json['min_amount']),
        convertDouble(json['max_amount']),
        convertDouble(json['fee_fixed']),
        convertDouble(json['fee_percent']),
        json['extra_info'] == null
            ? null
            : ExtraInfo.fromJson(json['extra_info']),
        instructions);
  }
}

class DepositInstruction {
  /// The value of the field.
  String value;

  /// A human-readable description of the field. This can be used by an anchor
  /// to provide any additional information about fields that are not defined
  /// in the SEP-9 standard.
  String description;

  DepositInstruction(this.value, this.description);

  factory DepositInstruction.fromJson(Map<String, dynamic> json) =>
      DepositInstruction(json['value'], json['description']);
}

class ExtraInfo extends Response {
  String? message;

  ExtraInfo(this.message);

  factory ExtraInfo.fromJson(Map<String, dynamic> json) =>
      ExtraInfo(json['message']);
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
    ResponseHandler<DepositResponse> responseHandler =
        ResponseHandler<DepositResponse>(type);

    final Map<String, String> depositHeaders = RequestBuilder.headers;
    if (jwt != null) {
      depositHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: depositHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<DepositResponse> execute(String? jwt) {
    return _DepositRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class CustomerInformationNeededResponse {
  /// A list of field names that need to be transmitted via
  /// SEP-12 for the deposit to proceed.
  List<String>? fields;

  CustomerInformationNeededResponse(this.fields);

  factory CustomerInformationNeededResponse.fromJson(
          Map<String, dynamic> json) =>
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

class CustomerInformationStatusResponse {
  /// Status of customer information processing. One of: pending, denied.
  String? status;

  /// (optional) A URL the user can visit if they want more information
  /// about their account / status.
  String? moreInfoUrl;

  /// (optional) Estimated number of seconds until the customer information
  /// status will update.
  int? eta;

  CustomerInformationStatusResponse(this.status, this.moreInfoUrl, this.eta);

  factory CustomerInformationStatusResponse.fromJson(
          Map<String, dynamic> json) =>
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

class DepositExchangeRequest {
  /// The code of the on-chain asset the user wants to get from the Anchor
  /// after doing an off-chain deposit. The value passed must match one of the
  /// codes listed in the /info response's deposit-exchange object.
  String destinationAsset;

  /// The off-chain asset the Anchor will receive from the user. The value must
  /// match one of the asset values included in a SEP-38
  /// GET /prices?buy_asset=stellar:<destination_asset>:<asset_issuer> response
  /// using SEP-38 Asset Identification Format.
  String sourceAsset;

  /// The amount of the source_asset the user would like to deposit to the
  /// anchor's off-chain account. This field may be necessary for the anchor
  /// to determine what KYC information is necessary to collect. Should be
  /// equals to quote.sell_amount if a quote_id was used.
  String amount;

  /// The stellar or muxed account ID of the user that wants to deposit.
  /// This is where the asset token will be sent. Note that the account
  /// specified in this request could differ from the account authenticated
  /// via SEP-10.
  String account;

  /// (optional) The id returned from a SEP-38 POST /quote response.
  /// If this parameter is provided and the user delivers the deposit funds
  /// to the Anchor before the quote expiration, the Anchor should respect the
  /// conversion rate agreed in that quote. If the values of destination_asset,
  /// source_asset and amount conflict with the ones used to create the
  /// SEP-38 quote, this request should be rejected with a 400.
  String? quoteId;

  /// (optional) Type of memo that the anchor should attach to the
  /// Stellar payment transaction, one of text, id or hash.
  String? memoType;

  /// (optional) (optional) Value of memo to attach to transaction, for hash
  /// this should be base64-encoded. Because a memo can be specified in the
  /// SEP-10 JWT for Shared Accounts, this field as well as memo_type can
  /// be different than the values included in the SEP-10 JWT. For example,
  /// a client application could use the value passed for this parameter
  /// as a reference number used to match payments made to account.
  String? memo;

  /// (optional) Email address of depositor. If desired, an anchor can use
  /// this to send email updates to the user about the deposit.
  String? emailAddress;

  /// (optional) Type of deposit. If the anchor supports multiple deposit
  /// methods (e.g. SEPA or SWIFT), the wallet should specify type. This field
  /// may be necessary for the anchor to determine which KYC fields to collect.
  String? type;

  /// (deprecated, optional) In communications / pages about the deposit,
  /// anchor should display the wallet name to the user to explain where funds
  /// are going. However, anchors should use client_domain (for non-custodial)
  /// and sub value of JWT (for custodial) to determine wallet information.
  String? walletName;

  /// (deprecated, optional) Anchor should link to this when notifying the user
  /// that the transaction has completed. However, anchors should use
  /// client_domain (for non-custodial) and sub value of JWT (for custodial)
  /// to determine wallet information.
  String? walletUrl;

  /// (optional) Defaults to en if not specified or if the specified language
  /// is not supported. Language code specified using RFC 4646. error fields
  /// and other human readable messages in the response should be in
  /// this language.
  String? lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the
  /// status property of the transaction created as a result of this request
  /// changes. The JSON message should be identical to the response format for
  /// the /transaction endpoint. The callback needs to be signed by the anchor
  /// and the signature needs to be verified by the wallet according to
  /// the callback signature specification.
  String? onChangeCallback;

  /// (optional) The ISO 3166-1 alpha-3 code of the user's current address.
  /// This field may be necessary for the anchor to determine what KYC
  /// information is necessary to collect.
  String? countryCode;

  /// (optional) true if the client supports receiving deposit transactions
  /// as a claimable balance, false otherwise.
  String? claimableBalanceSupported;

  /// (optional) id of an off-chain account (managed by the anchor) associated
  /// with this user's Stellar account (identified by the JWT's sub field).
  /// If the anchor supports SEP-12, the customerId field should match the
  /// SEP-12 customer's id. customerId should be passed only when the off-chain
  /// id is know to the client, but the relationship between this id and the
  /// user's Stellar account is not known to the Anchor.
  String? customerId;

  /// (optional) id of the chosen location to drop off cash
  String? locationId;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  DepositExchangeRequest(
      {required this.destinationAsset,
      required this.sourceAsset,
      required this.amount,
      required this.account,
      this.quoteId,
      this.memoType,
      this.memo,
      this.emailAddress,
      this.type,
      this.walletName,
      this.walletUrl,
      this.lang,
      this.onChangeCallback,
      this.countryCode,
      this.claimableBalanceSupported,
      this.customerId,
      this.locationId,
      this.jwt});
}

class WithdrawRequest {
  /// Code of the on-chain asset the user wants to withdraw.
  /// The value passed must match one of the codes listed in the /info response's withdraw object.
  String assetCode;

  /// Type of withdrawal. Can be: crypto, bank_account, cash, mobile,
  /// bill_payment or other custom values. This field may be necessary
  /// for the anchor to determine what KYC information is necessary to collect.
  String type;

  /// (Deprecated) The account that the user wants to withdraw their funds to.
  /// This can be a crypto account, a bank account number, IBAN, mobile number,
  /// or email address.
  String? dest;

  /// (Deprecated, optional) Extra information to specify withdrawal location.
  /// For crypto it may be a memo in addition to the dest address.
  /// It can also be a routing number for a bank, a BIC, or the name of a
  /// partner handling the withdrawal.
  String? destExtra;

  /// (optional) The Stellar or muxed account the client will use as the source
  /// of the withdrawal payment to the anchor. If SEP-10 authentication is not
  /// used, the anchor can use account to look up the user's KYC information.
  /// Note that the account specified in this request could differ from the
  /// account authenticated via SEP-10.
  String? account;

  /// (optional) This field should only be used if SEP-10 authentication is not.
  /// It was originally intended to distinguish users of the same Stellar account.
  /// However if SEP-10 is supported, the anchor should use the sub value
  /// included in the decoded SEP-10 JWT instead.
  String? memo;

  /// (Deprecated, optional) Type of memo. One of text, id or hash.
  /// Deprecated because memos used to identify users of the same
  /// Stellar account should always be of type of id.
  String? memoType;

  /// (deprecated, optional) In communications / pages about the withdrawal,
  /// anchor should display the wallet name to the user to explain where funds
  /// are coming from. However, anchors should use client_domain
  /// (for non-custodial) and sub value of JWT (for custodial) to determine
  /// wallet information.
  String? walletName;

  /// (deprecated, optional) Anchor can show this to the user when referencing
  /// the wallet involved in the withdrawal (ex. in the anchor's transaction
  /// history). However, anchors should use client_domain (for non-custodial)
  /// and sub value of JWT (for custodial) to determine wallet information.
  String? walletUrl;

  /// (optional) (optional) Defaults to en if not specified or if the
  /// specified language is not supported. Language code specified using
  /// RFC 4646. error fields and other human readable messages in the
  /// response should be in this language.
  String? lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the
  /// status property of the transaction created as a result of this request
  /// changes. The JSON message should be identical to the response format
  /// for the /transaction endpoint.
  String? onChangeCallback;

  /// (optional) The amount of the asset the user would like to withdraw.
  /// This field may be necessary for the anchor to determine what KYC
  /// information is necessary to collect.
  String? amount;

  /// (optional) The ISO 3166-1 alpha-3 code of the user's current address.
  /// This field may be necessary for the anchor to determine what KYC
  /// information is necessary to collect.
  String? countryCode;

  /// (optional) The memo the anchor must use when sending refund payments back
  /// to the user. If not specified, the anchor should use the same memo used
  /// by the user to send the original payment. If specified, refundMemoType
  /// must also be specified.
  String? refundMemo;

  /// (optional) The type of the refund_memo. Can be id, text, or hash.
  /// If specified, refundMemo must also be specified.
  String? refundMemoType;

  /// (optional) id of an off-chain account (managed by the anchor) associated
  /// with this user's Stellar account (identified by the JWT's sub field).
  /// If the anchor supports SEP-12, the customer_id field should match the
  /// SEP-12 customer's id. customer_id should be passed only when the
  /// off-chain id is know to the client, but the relationship between this id
  /// and the user's Stellar account is not known to the Anchor.
  String? customerId;

  /// (optional) id of the chosen location to pick up cash
  String? locationId;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  WithdrawRequest(
      {required this.assetCode,
      required this.type,
      this.dest,
      this.destExtra,
      this.account,
      this.memo,
      this.memoType,
      this.walletName,
      this.walletUrl,
      this.lang,
      this.onChangeCallback,
      this.amount,
      this.countryCode,
      this.refundMemo,
      this.refundMemoType,
      this.customerId,
      this.locationId,
      this.jwt});
}

class WithdrawExchangeRequest {
  /// Code of the on-chain asset the user wants to withdraw. The value passed
  /// must match one of the codes listed in the /info response's
  /// withdraw-exchange object.
  String sourceAsset;

  /// The off-chain asset the Anchor will deliver to the user's account.
  /// The value must match one of the asset values included in a SEP-38
  /// GET /prices?sell_asset=stellar:<source_asset>:<asset_issuer> response
  /// using SEP-38 Asset Identification Format.
  String destinationAsset;

  /// The amount of the on-chain asset (source_asset) the user would like to
  /// send to the anchor's Stellar account. This field may be necessary for
  /// the anchor to determine what KYC information is necessary to collect.
  /// Should be equals to quote.sell_amount if a quote_id was used.
  String amount;

  /// Type of withdrawal. Can be: crypto, bank_account, cash, mobile,
  /// bill_payment or other custom values. This field may be necessary for the
  /// anchor to determine what KYC information is necessary to collect.
  String type;

  /// (Deprecated) The account that the user wants to withdraw their
  /// funds to. This can be a crypto account, a bank account number, IBAN,
  /// mobile number, or email address.
  String? dest;

  /// (Deprecated, optional) Extra information to specify withdrawal
  /// location. For crypto it may be a memo in addition to the dest address.
  /// It can also be a routing number for a bank, a BIC, or the name of a
  /// partner handling the withdrawal.
  String? destExtra;

  /// (optional) The id returned from a SEP-38 POST /quote response.
  /// If this parameter is provided and the Stellar transaction used to send
  /// the asset to the Anchor has a created_at timestamp earlier than the
  /// quote's expires_at attribute, the Anchor should respect the conversion
  /// rate agreed in that quote. If the values of destination_asset,
  /// source_asset and amount conflict with the ones used to create the
  /// SEP-38 quote, this request should be rejected with a 400.
  String? quoteId;

  /// (optional) The Stellar or muxed account of the user that wants to do the
  /// withdrawal. This is only needed if the anchor requires KYC information
  /// for withdrawal and SEP-10 authentication is not used. Instead, the anchor
  /// can use account to look up the user's KYC information. Note that the
  /// account specified in this request could differ from the account
  /// authenticated via SEP-10.
  String? account;

  /// (optional) This field should only be used if SEP-10 authentication is not.
  /// It was originally intended to distinguish users of the same Stellar
  /// account. However if SEP-10 is supported, the anchor should use the sub
  /// value included in the decoded SEP-10 JWT instead.
  String? memo;

  /// (Deprecated, optional) Type of memo. One of text, id or hash.
  /// Deprecated because memos used to identify users of the same
  /// Stellar account should always be of type of id.
  String? memoType;

  /// (deprecated, optional) In communications / pages about the withdrawal,
  /// anchor should display the wallet name to the user to explain where funds
  /// are coming from. However, anchors should use client_domain
  /// (for non-custodial) and sub value of JWT (for custodial) to determine
  /// wallet information.
  String? walletName;

  /// (deprecated,optional) Anchor can show this to the user when referencing
  /// the wallet involved in the withdrawal (ex. in the anchor's transaction
  /// history). However, anchors should use client_domain (for non-custodial)
  /// and sub value of JWT (for custodial) to determine wallet information.
  String? walletUrl;

  /// (optional) Defaults to en if not specified or if the specified language
  /// is not supported. Language code specified using RFC 4646. error fields
  /// and other human readable messages in the response should be in
  /// this language.
  String? lang;

  /// (optional) A URL that the anchor should POST a JSON message to when the
  /// status property of the transaction created as a result of this request
  /// changes. The JSON message should be identical to the response format for
  /// the /transaction endpoint. The callback needs to be signed by the anchor
  /// and the signature needs to be verified by the wallet according to
  /// the callback signature specification.
  String? onChangeCallback;

  /// (optional) The ISO 3166-1 alpha-3 code of the user's current address.
  /// This field may be necessary for the anchor to determine what KYC
  /// information is necessary to collect.
  String? countryCode;

  /// (optional) true if the client supports receiving deposit transactions
  /// as a claimable balance, false otherwise.
  String? claimableBalanceSupported;

  /// (optional) The memo the anchor must use when sending refund payments back
  /// to the user. If not specified, the anchor should use the same memo used
  /// by the user to send the original payment. If specified, refundMemoType
  /// must also be specified.
  String? refundMemo;

  /// (optional) The type of the refund_memo. Can be id, text, or hash.
  /// If specified, refundMemo must also be specified.
  String? refundMemoType;

  /// (optional) id of an off-chain account (managed by the anchor) associated
  /// with this user's Stellar account (identified by the JWT's sub field).
  /// If the anchor supports SEP-12, the customer_id field should match the
  /// SEP-12 customer's id. customer_id should be passed only when the
  /// off-chain id is know to the client, but the relationship between this id
  /// and the user's Stellar account is not known to the Anchor.
  String? customerId;

  /// (optional) id of the chosen location to pick up cash
  String? locationId;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  WithdrawExchangeRequest(
      {required this.sourceAsset,
      required this.destinationAsset,
      required this.amount,
      required this.type,
      this.dest,
      this.destExtra,
      this.quoteId,
      this.account,
      this.memo,
      this.memoType,
      this.walletName,
      this.walletUrl,
      this.lang,
      this.onChangeCallback,
      this.countryCode,
      this.claimableBalanceSupported,
      this.refundMemo,
      this.refundMemoType,
      this.customerId,
      this.locationId,
      this.jwt});
}

/// Represents an transfer service withdraw response.
class WithdrawResponse extends Response {
  /// (optional) The account the user should send its token back to.
  /// This field can be omitted if the anchor cannot provide this information
  /// at the time of the request.
  String? accountId;

  /// (optional) Type of memo to attach to transaction, one of text, id or hash.
  String? memoType;

  /// (optional) Value of memo to attach to transaction, for hash this should
  /// be base64-encoded. The anchor should use this memo to match the Stellar
  /// transaction with the database entry associated created to represent it.
  String? memo;

  /// (optional) The anchor's ID for this withdrawal. The wallet will use this
  /// ID to query the /transaction endpoint to check status of the request.
  String? id;

  /// (optional) Estimate of how long the withdrawal will take to credit
  /// in seconds.
  int? eta;

  /// (optional) Minimum amount of an asset that a user can withdraw.
  double? minAmount;

  /// (optional) Maximum amount of asset that a user can withdraw.
  double? maxAmount;

  /// (optional) If there is a fee for withdraw. In units of the withdrawn
  /// asset.
  double? feeFixed;

  /// (optional) If there is a percent fee for withdraw.
  double? feePercent;

  /// (optional) Any additional data needed as an input for this withdraw,
  /// example: Bank Name.
  ExtraInfo? extraInfo;

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
      WithdrawResponse(
          json['account_id'],
          json['memo_type'],
          json['memo'],
          json['id'],
          convertInt(json['eta']),
          convertDouble(json['min_amount']),
          convertDouble(json['max_amount']),
          convertDouble(json['fee_fixed']),
          convertDouble(json['fee_percent']),
          json['extra_info'] == null
              ? null
              : ExtraInfo.fromJson(json['extra_info']));
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
    ResponseHandler<WithdrawResponse> responseHandler =
        ResponseHandler<WithdrawResponse>(type);

    final Map<String, String> withdrawHeaders = RequestBuilder.headers;
    if (jwt != null) {
      withdrawHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: withdrawHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<WithdrawResponse> execute(String? jwt) {
    return _WithdrawRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class AnchorField {
  /// description of field to show to user.
  String? description;

  /// if field is optional. Defaults to false.
  bool? optional;

  /// list of possible values for the field.
  List<String>? choices;

  AnchorField(this.description, this.optional, this.choices);

  factory AnchorField.fromJson(Map<String, dynamic> json) => AnchorField(
      json['description'],
      json['optional'],
      json['choices'] == null ? null : List<String>.from(json['choices']));
}

class DepositAsset {
  /// true if SEP-6 deposit for this asset is supported
  bool enabled;

  /// Optional. true if client must be authenticated before accessing the
  /// deposit endpoint for this asset. false if not specified.
  bool? authenticationRequired;

  /// Optional fixed (flat) fee for deposit, in units of the Stellar asset.
  /// Null if there is no fee or the fee schedule is complex.
  double? feeFixed;

  /// Optional percentage fee for deposit, in percentage points of the Stellar
  /// asset. Null if there is no fee or the fee schedule is complex.
  double? feePercent;

  /// Optional minimum amount. No limit if not specified.
  double? minAmount;

  /// Optional maximum amount. No limit if not specified.
  double? maxAmount;

  /// (Deprecated) Accepting personally identifiable information through
  /// request parameters is a security risk due to web server request logging.
  /// KYC information should be supplied to the Anchor via SEP-12).
  Map<String, AnchorField>? fields;

  DepositAsset(this.enabled, this.authenticationRequired, this.feeFixed,
      this.feePercent, this.minAmount, this.maxAmount, this.fields);

  factory DepositAsset.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? fieldsDynamic =
        json['fields'] == null ? null : json['fields'];
    Map<String, AnchorField>? assetFields;
    if (fieldsDynamic != null) {
      assetFields = {};
      fieldsDynamic.forEach((key, value) {
        assetFields![key] = AnchorField.fromJson(value);
      });
    }

    bool enabled = false;
    if (json['enabled'] != null) {
      enabled = json['enabled'];
    }

    return DepositAsset(
        enabled,
        json['authentication_required'],
        convertDouble(json['fee_fixed']),
        convertDouble(json['fee_percent']),
        convertDouble(json['min_amount']),
        convertDouble(json['max_amount']),
        assetFields);
  }
}

class DepositExchangeAsset {
  /// true if SEP-6 deposit for this asset is supported
  bool enabled;

  /// Optional. true if client must be authenticated before accessing the
  /// deposit endpoint for this asset. false if not specified.
  bool? authenticationRequired;

  /// (Deprecated) Accepting personally identifiable information through
  /// request parameters is a security risk due to web server request logging.
  /// KYC information should be supplied to the Anchor via SEP-12).
  Map<String, AnchorField>? fields;

  DepositExchangeAsset(this.enabled, this.authenticationRequired, this.fields);

  factory DepositExchangeAsset.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? fieldsDynamic =
        json['fields'] == null ? null : json['fields'];
    Map<String, AnchorField>? assetFields = {};
    if (fieldsDynamic != null) {
      fieldsDynamic.forEach((key, value) {
        assetFields![key] = AnchorField.fromJson(value);
      });
    } else {
      assetFields = null;
    }

    bool enabled = false;
    if (json['enabled'] != null) {
      enabled = json['enabled'];
    }

    return DepositExchangeAsset(
        enabled, json['authentication_required'], assetFields);
  }
}

class WithdrawAsset {
  /// true if SEP-6 withdrawal for this asset is supported
  bool enabled;

  /// Optional. true if client must be authenticated before accessing
  /// the withdraw endpoint for this asset. false if not specified.
  bool? authenticationRequired;

  /// Optional fixed (flat) fee for withdraw, in units of the Stellar asset.
  /// Null if there is no fee or the fee schedule is complex.
  double? feeFixed;

  /// Optional percentage fee for withdraw, in percentage points of the
  /// Stellar asset. Null if there is no fee or the fee schedule is complex.
  double? feePercent;

  /// Optional minimum amount. No limit if not specified.
  double? minAmount;

  /// Optional maximum amount. No limit if not specified.
  double? maxAmount;

  /// A field with each type of withdrawal supported for that asset as a key.
  /// Each type can specify a fields object explaining what fields
  /// are needed and what they do. Anchors are encouraged to use SEP-9
  /// financial account fields, but can also define custom fields if necessary.
  /// If a fields object is not specified, the wallet should assume that no
  /// extra fields are needed for that type of withdrawal. In the case that
  /// the Anchor requires additional fields for a withdrawal, it should set the
  /// transaction status to pending_customer_info_update. The wallet can query
  /// the /transaction endpoint to get the fields needed to complete the
  /// transaction in required_customer_info_updates and then use SEP-12 to
  /// collect the information from the user.
  Map<String, Map<String, AnchorField>?>? types;

  WithdrawAsset(this.enabled, this.authenticationRequired, this.feeFixed,
      this.feePercent, this.minAmount, this.maxAmount, this.types);

  factory WithdrawAsset.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? typesDynamic =
        json['types'] == null ? null : json['types'];

    Map<String, Map<String, AnchorField>?>? assetTypes = {};
    if (typesDynamic != null) {
      typesDynamic.forEach((key, value) {
        Map<String, dynamic>? fieldsDynamic =
            typesDynamic[key]['fields'] == null
                ? null
                : typesDynamic[key]['fields'];
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

    bool enabled = false;
    if (json['enabled'] != null) {
      enabled = json['enabled'];
    }

    return WithdrawAsset(
        enabled,
        json['authentication_required'],
        convertDouble(json['fee_fixed']),
        convertDouble(json['fee_percent']),
        convertDouble(json['min_amount']),
        convertDouble(json['max_amount']),
        assetTypes);
  }
}

class WithdrawExchangeAsset {
  /// true if SEP-6 withdrawal for this asset is supported
  bool enabled;

  /// Optional. true if client must be authenticated before accessing
  /// the withdraw endpoint for this asset. false if not specified.
  bool? authenticationRequired;

  /// A field with each type of withdrawal supported for that asset as a key.
  /// Each type can specify a fields object explaining what fields
  /// are needed and what they do. Anchors are encouraged to use SEP-9
  /// financial account fields, but can also define custom fields if necessary.
  /// If a fields object is not specified, the wallet should assume that no
  /// extra fields are needed for that type of withdrawal. In the case that
  /// the Anchor requires additional fields for a withdrawal, it should set the
  /// transaction status to pending_customer_info_update. The wallet can query
  /// the /transaction endpoint to get the fields needed to complete the
  /// transaction in required_customer_info_updates and then use SEP-12 to
  /// collect the information from the user.
  Map<String, Map<String, AnchorField>?>? types;

  WithdrawExchangeAsset(this.enabled, this.authenticationRequired, this.types);

  factory WithdrawExchangeAsset.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? typesDynamic =
        json['types'] == null ? null : json['types'];

    Map<String, Map<String, AnchorField>?>? assetTypes = {};
    if (typesDynamic != null) {
      typesDynamic.forEach((key, value) {
        Map<String, dynamic>? fieldsDynamic =
            typesDynamic[key]['fields'] == null
                ? null
                : typesDynamic[key]['fields'];
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

    bool enabled = false;
    if (json['enabled'] != null) {
      enabled = json['enabled'];
    }

    return WithdrawExchangeAsset(
        enabled, json['authentication_required'], assetTypes);
  }
}

class AnchorFeeInfo {
  /// true if the endpoint is available.
  bool? enabled;

  /// true if client must be authenticated before accessing the endpoint.
  bool? authenticationRequired;

  /// Optional. Anchors are encouraged to add a description field to the
  /// fee object returned in GET /info containing a short explanation of
  /// how fees are calculated so client applications will be able to display
  /// this message to their users. This is especially important if the
  /// GET /fee endpoint is not supported and fees cannot be models using
  /// fixed and percentage values for each Stellar asset.
  String? description;

  AnchorFeeInfo(this.enabled, this.authenticationRequired, this.description);

  factory AnchorFeeInfo.fromJson(Map<String, dynamic> json) => AnchorFeeInfo(
      json['enabled'], json['authentication_required'], json['description']);
}

class AnchorTransactionInfo {
  /// true if the endpoint is available.
  bool? enabled;

  /// true if client must be authenticated before accessing the endpoint.
  bool? authenticationRequired;

  AnchorTransactionInfo(this.enabled, this.authenticationRequired);

  factory AnchorTransactionInfo.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionInfo(json['enabled'], json['authentication_required']);
}

class AnchorTransactionsInfo {
  /// true if the endpoint is available.
  bool? enabled;

  /// true if client must be authenticated before accessing the endpoint.
  bool? authenticationRequired;

  AnchorTransactionsInfo(this.enabled, this.authenticationRequired);

  factory AnchorTransactionsInfo.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionsInfo(json['enabled'], json['authentication_required']);
}

/// Part of the response of the info endpoint.
class AnchorFeatureFlags {
  /// Whether or not the anchor supports creating accounts for users requesting
  /// deposits. Defaults to true.
  bool accountCreation;

  /// Whether or not the anchor supports sending deposit funds as claimable
  /// balances. This is relevant for users of Stellar accounts without a
  /// trustline to the requested asset. Defaults to false.
  bool claimableBalances;

  AnchorFeatureFlags(this.accountCreation, this.claimableBalances);

  factory AnchorFeatureFlags.fromJson(Map<String, dynamic> json) {
    bool? accCreation = json['account_creation'];
    bool? claimableB = json['claimable_balances'];
    return AnchorFeatureFlags(accCreation != null ? accCreation : true,
        claimableB != null ? claimableB : false);
  }
}

class InfoResponse extends Response {
  Map<String, DepositAsset>? depositAssets;
  Map<String, DepositExchangeAsset>? depositExchangeAssets;
  Map<String, WithdrawAsset>? withdrawAssets;
  Map<String, WithdrawExchangeAsset>? withdrawExchangeAssets;
  AnchorFeeInfo? feeInfo;
  AnchorTransactionsInfo? transactionsInfo;
  AnchorTransactionInfo? transactionInfo;
  AnchorFeatureFlags? featureFlags;

  InfoResponse(
      this.depositAssets,
      this.depositExchangeAssets,
      this.withdrawAssets,
      this.withdrawExchangeAssets,
      this.feeInfo,
      this.transactionsInfo,
      this.transactionInfo,
      this.featureFlags);

  factory InfoResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? depositDynamic =
        json['deposit'] == null ? null : json['deposit'];

    Map<String, DepositAsset> depositMap = {};
    if (depositDynamic != null) {
      depositDynamic.forEach((key, value) {
        depositMap[key] = DepositAsset.fromJson(value);
      });
    }

    Map<String, dynamic>? depositExchangeDynamic =
        json['deposit-exchange'] == null ? null : json['deposit-exchange'];

    Map<String, DepositExchangeAsset> depositExchangeMap = {};
    if (depositExchangeDynamic != null) {
      depositExchangeDynamic.forEach((key, value) {
        depositExchangeMap[key] = DepositExchangeAsset.fromJson(value);
      });
    }

    Map<String, dynamic>? withdrawDynamic =
        json['withdraw'] == null ? null : json['withdraw'];

    Map<String, WithdrawAsset> withdrawMap = {};
    if (withdrawDynamic != null) {
      withdrawDynamic.forEach((key, value) {
        withdrawMap[key] = WithdrawAsset.fromJson(value);
      });
    }

    Map<String, dynamic>? withdrawExchangeDynamic =
        json['withdraw-exchange'] == null ? null : json['withdraw-exchange'];

    Map<String, WithdrawExchangeAsset> withdrawExchangeMap = {};
    if (withdrawExchangeDynamic != null) {
      withdrawExchangeDynamic.forEach((key, value) {
        withdrawExchangeMap[key] = WithdrawExchangeAsset.fromJson(value);
      });
    }

    return InfoResponse(
        depositMap,
        depositExchangeMap,
        withdrawMap,
        withdrawExchangeMap,
        json['fee'] == null ? null : AnchorFeeInfo.fromJson(json['fee']),
        json['transactions'] == null
            ? null
            : AnchorTransactionsInfo.fromJson(json['transactions']),
        json['transaction'] == null
            ? null
            : AnchorTransactionInfo.fromJson(json['transaction']),
        json['features'] == null
            ? null
            : AnchorFeatureFlags.fromJson(json['features']));
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
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<InfoResponse> type = TypeToken<InfoResponse>();
    ResponseHandler<InfoResponse> responseHandler =
        ResponseHandler<InfoResponse>(type);

    final Map<String, String> infoHeaders = RequestBuilder.headers;
    if (jwt != null) {
      infoHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: infoHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<InfoResponse> execute(String? jwt) {
    return _InfoRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class FeeRequest {
  /// Kind of operation (deposit or withdraw).
  String operation;

  /// (optional) Type of deposit or withdrawal
  /// (SEPA, bank_account, cash, etc...).
  String? type;

  /// Stellar asset code.
  String assetCode;

  /// Amount of the asset that will be deposited/withdrawn.
  double amount;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  FeeRequest(
      {required this.operation,
      required this.assetCode,
      required this.amount,
      this.type,
      this.jwt});
}

/// Represents an transfer service fee response.
class FeeResponse extends Response {
  /// The total fee (in units of the asset involved) that would be charged
  /// to deposit/withdraw the specified amount of asset_code.
  double fee;

  FeeResponse(this.fee);

  factory FeeResponse.fromJson(Map<String, dynamic> json) =>
      FeeResponse(convertDouble(json['fee'])!);
}

// Requests the fee data.
class _FeeRequestBuilder extends RequestBuilder {
  _FeeRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _FeeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<FeeResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<FeeResponse> type = TypeToken<FeeResponse>();
    ResponseHandler<FeeResponse> responseHandler =
        ResponseHandler<FeeResponse>(type);

    final Map<String, String> feeHeaders = RequestBuilder.headers;
    if (jwt != null) {
      feeHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: feeHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<FeeResponse> execute(String? jwt) {
    return _FeeRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class AnchorTransactionsRequest {
  /// The code of the asset of interest. E.g. BTC, ETH, USD, INR, etc.
  String assetCode;

  /// The stellar account ID involved in the transactions. If the service
  /// requires SEP-10 authentication, this parameter must match the
  /// authenticated account.
  String account;

  /// (optional) The response should contain transactions starting on or
  /// after this date & time.
  DateTime? noOlderThan;

  /// (optional) The response should contain at most limit transactions.
  int? limit;

  /// (optional) A list containing the desired transaction kinds.
  /// The possible values are deposit, deposit-exchange, withdrawal
  /// and withdrawal-exchange.
  String? kind;

  /// (optional) The response should contain transactions starting
  /// prior to this ID (exclusive).
  String? pagingId;

  /// (optional) Defaults to en if not specified or if the specified language
  /// is not supported. Language code specified using RFC 4646.
  /// Error fields and other human readable messages in the response
  /// should be in this language.
  String? lang;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  AnchorTransactionsRequest(
      {required this.assetCode,
      required this.account,
      this.noOlderThan,
      this.limit,
      this.kind,
      this.pagingId,
      this.lang,
      this.jwt});
}

class FeeDetails {
  /// The total amount of fee applied.
  String total;

  /// The asset in which the fee is applied, represented through the
  /// Asset Identification Format.
  String asset;

  /// (optional) An array of objects detailing the fees that were used to
  /// calculate the conversion price. This can be used to datail the price
  /// components for the end-user.
  List<FeeDetailsDetails>? details;

  FeeDetails(this.total, this.asset, {this.details});

  factory FeeDetails.fromJson(Map<String, dynamic> json) =>
      FeeDetails(json['name'], json['amount'],
          details: json['details'] == null
              ? null
              : List<FeeDetailsDetails>.from(
                  json['details'].map((e) => FeeDetailsDetails.fromJson(e))));
}

class FeeDetailsDetails {
  /// The name of the fee, for example ACH fee, Brazilian conciliation fee,
  /// Service fee, etc.
  String name;

  /// The amount of asset applied. If fee_details.details is provided,
  /// sum(fee_details.details.amount) should be equals fee_details.total.
  String amount;

  /// (optional) A text describing the fee.
  String? description;

  FeeDetailsDetails(this.name, this.amount, {this.description});

  factory FeeDetailsDetails.fromJson(Map<String, dynamic> json) =>
      FeeDetailsDetails(json['name'], json['amount'],
          description:
              json['description'] == null ? null : json['description']);
}

/// Part of the transaction result.
class TransactionRefunds {
  /// The total amount refunded to the user, in units of amount_in_asset.
  /// If a full refund was issued, this amount should match amount_in.
  String amountRefunded;

  /// The total amount charged in fees for processing all refund payments, in units of amount_in_asset.
  /// The sum of all fee values in the payments object list should equal this value.
  String amountFee;

  /// A list of objects containing information on the individual payments made back to the user as refunds.
  List<TransactionRefundPayment> payments;

  TransactionRefunds(this.amountRefunded, this.amountFee, this.payments);

  factory TransactionRefunds.fromJson(Map<String, dynamic> json) =>
      TransactionRefunds(
          json['amount_refunded'],
          json['amount_fee'],
          (json['payments'] as List)
              .map((e) => TransactionRefundPayment.fromJson(e))
              .toList());
}

/// Part of the transaction result.
class TransactionRefundPayment {
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

  TransactionRefundPayment(this.id, this.idType, this.amount, this.fee);

  factory TransactionRefundPayment.fromJson(Map<String, dynamic> json) =>
      TransactionRefundPayment(
          json['id'], json['id_type'], json['amount'], json['fee']);
}

/// Represents an anchor transaction
class AnchorTransaction {
  /// Unique, anchor-generated id for the deposit/withdrawal.
  String id;

  /// deposit, deposit-exchange, withdrawal or withdrawal-exchange.
  String kind;

  /// Processing status of deposit/withdrawal.
  String status;

  /// (optional) Estimated number of seconds until a status change is expected.
  int? statusEta;

  /// (optional) A URL the user can visit if they want more information
  /// about their account / status.
  String? moreInfoUrl;

  /// (optional) Amount received by anchor at start of transaction as a
  /// string with up to 7 decimals. Excludes any fees charged before the
  /// anchor received the funds. Should be equals to quote.sell_asset if
  /// a quote_id was used.
  String? amountIn;

  /// optional) The asset received or to be received by the Anchor.
  /// Must be present if the deposit/withdraw was made using quotes.
  /// The value must be in SEP-38 Asset Identification Format.
  String? amountInAsset;

  /// (optional) Amount sent by anchor to user at end of transaction as
  /// a string with up to 7 decimals. Excludes amount converted to XLM to
  /// fund account and any external fees. Should be equals to quote.buy_asset
  /// if a quote_id was used.
  String? amountOut;

  /// (optional) The asset delivered or to be delivered to the user.
  /// Must be present if the deposit/withdraw was made using quotes.
  /// The value must be in SEP-38 Asset Identification Format.
  String? amountOutAsset;

  /// (deprecated, optional) Amount of fee charged by anchor.
  /// Should be equals to quote.fee.total if a quote_id was used.
  String? amountFee;

  /// (deprecated, optional) The asset in which fees are calculated in.
  /// Must be present if the deposit/withdraw was made using quotes.
  /// The value must be in SEP-38 Asset Identification Format.
  /// Should be equals to quote.fee.asset if a quote_id was used.
  String? amountFeeAsset;

  /// Description of fee charged by the anchor.
  /// If quote_id is present, it should match the referenced quote's fee object.
  FeeDetails? feeDetails;

  /// (optional) The ID of the quote used to create this transaction.
  /// Should be present if a quote_id was included in the POST /transactions
  /// request. Clients should be aware though that the quote_id may not be
  /// present in older implementations.
  String? quoteId;

  /// (optional) Sent from address (perhaps BTC, IBAN, or bank account in
  /// the case of a deposit, Stellar address in the case of a withdrawal).
  String? from;

  /// (optional) Sent to address (perhaps BTC, IBAN, or bank account in
  /// the case of a withdrawal, Stellar address in the case of a deposit).
  String? to;

  /// (optional) Extra information for the external account involved.
  /// It could be a bank routing number, BIC, or store number for example.
  String? externalExtra;

  /// (optional) Text version of external_extra.
  /// This is the name of the bank or store
  String? externalExtraText;

  /// (optional) If this is a deposit, this is the memo (if any)
  /// used to transfer the asset to the to Stellar address
  String? depositMemo;

  /// (optional) Type for the depositMemo.
  String? depositMemoType;

  /// (optional) If this is a withdrawal, this is the anchor's Stellar account
  /// that the user transferred (or will transfer) their issued asset to.
  String? withdrawAnchorAccount;

  /// (optional) Memo used when the user transferred to withdrawAnchorAccount.
  String? withdrawMemo;

  /// (optional) Memo type for withdrawMemo.
  String? withdrawMemoType;

  /// (optional) Start date and time of transaction - UTC ISO 8601 string.
  String? startedAt;

  /// (optional) The date and time of transaction reaching the current status.
  String? updatedAt;

  /// (optional) Completion date and time of transaction - UTC ISO 8601 string.
  String? completedAt;

  /// (optional) transaction_id on Stellar network of the transfer that either
  /// completed the deposit or started the withdrawal.
  String? stellarTransactionId;

  /// (optional) ID of transaction on external network that either started
  /// the deposit or completed the withdrawal.
  String? externalTransactionId;

  /// (optional) Human readable explanation of transaction status, if needed.
  String? message;

  /// (deprecated, optional) This field is deprecated in favor of the refunds
  /// object. True if the transaction was refunded in full. False if the
  /// transaction was partially refunded or not refunded. For more details
  /// about any refunds, see the refunds object.
  bool? refunded;

  /// (optional) An object describing any on or off-chain refund associated
  /// with this transaction.
  TransactionRefunds? refunds;

  /// (optional) A human-readable message indicating any errors that require
  /// updated information from the user.
  String? requiredInfoMessage;

  /// (optional) A set of fields that require update from the user described in
  /// the same format as /info. This field is only relevant when status is
  /// pending_transaction_info_update.
  Map<String, AnchorField>? requiredInfoUpdates;

  /// (optional) JSON object containing the SEP-9 financial account fields that
  /// describe how to complete the off-chain deposit in the same format as
  /// the /deposit response. This field should be present if the instructions
  /// were provided in the /deposit response or if it could not have been
  /// previously provided synchronously. This field should only be present
  /// once the status becomes pending_user_transfer_start, not while the
  /// transaction has any statuses that precede it such as incomplete,
  /// pending_anchor, or pending_customer_info_update.
  Map<String, DepositInstruction>? instructions;

  /// (optional) ID of the Claimable Balance used to send the asset initially
  /// requested. Only relevant for deposit transactions.
  String? claimableBalanceId;

  AnchorTransaction(
      {required this.id,
      required this.kind,
      required this.status,
      this.statusEta,
      this.moreInfoUrl,
      this.amountIn,
      this.amountInAsset,
      this.amountOut,
      this.amountOutAsset,
      this.amountFee,
      this.amountFeeAsset,
      this.feeDetails,
      this.quoteId,
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
      this.updatedAt,
      this.completedAt,
      this.stellarTransactionId,
      this.externalTransactionId,
      this.message,
      this.refunded,
      this.refunds,
      this.requiredInfoMessage,
      this.requiredInfoUpdates,
      this.instructions,
      this.claimableBalanceId});

  factory AnchorTransaction.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? instructionsJson =
        json['instructions'] == null ? null : json['instructions'];

    Map<String, DepositInstruction>? instructions;
    if (instructionsJson != null) {
      instructions = {};
      instructionsJson.forEach((key, value) {
        instructions![key] = DepositInstruction.fromJson(value);
      });
    }

    Map<String, dynamic>? fieldsDynamic = json['required_info_updates'] == null
        ? null
        : json['required_info_updates'];

    // sometimes the fields are surrounded by another object 'transaction'
    if (fieldsDynamic != null &&
        fieldsDynamic.length == 1 &&
        fieldsDynamic['transaction'] != null) {
      fieldsDynamic = fieldsDynamic['transaction'];
    }

    Map<String, AnchorField>? infoUpFields;
    if (fieldsDynamic != null) {
      infoUpFields = {};
      fieldsDynamic.forEach((key, value) {
        infoUpFields![key] = AnchorField.fromJson(value);
      });
    }

    return AnchorTransaction(
        id: json['id'],
        kind: json['kind'],
        status: json['status'],
        statusEta: convertInt(json['status_eta']),
        moreInfoUrl: json['more_info_url'],
        amountIn: json['amount_in'],
        amountInAsset: json['amount_in_asset'],
        amountOut: json['amount_out'],
        amountOutAsset: json['amount_out_asset'],
        amountFee: json['amount_fee'],
        amountFeeAsset: json['amount_fee_asset'],
        feeDetails: json['fee_details'] == null
            ? null
            : FeeDetails.fromJson(json['fee_details']),
        quoteId: json['quote_id'],
        from: json['from'],
        to: json['to'],
        externalExtra: json['external_extra'],
        externalExtraText: json['external_extra_text'],
        depositMemo: json['deposit_memo'],
        depositMemoType: json['deposit_memo_type'],
        withdrawAnchorAccount: json['withdraw_anchor_account'],
        withdrawMemo: json['withdraw_memo'],
        withdrawMemoType: json['withdraw_memo_type'],
        startedAt: json['started_at'],
        updatedAt: json['updated_at'],
        completedAt: json['completed_at'],
        stellarTransactionId: json['stellar_transaction_id'],
        externalTransactionId: json['external_transaction_id'],
        message: json['message'],
        refunded: json['refunded'],
        refunds: json['refunds'] == null
            ? null
            : TransactionRefunds.fromJson(json['refunds']),
        requiredInfoMessage: json['required_info_message'],
        requiredInfoUpdates: infoUpFields,
        instructions: instructions,
        claimableBalanceId: json['claimable_balance_id']);
  }
}

class AnchorTransactionsResponse extends Response {
  List<AnchorTransaction> transactions;

  AnchorTransactionsResponse(this.transactions);

  factory AnchorTransactionsResponse.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionsResponse((json['transactions'] as List)
          .map((e) => AnchorTransaction.fromJson(e))
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

  static Future<AnchorTransactionsResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<AnchorTransactionsResponse> type =
        TypeToken<AnchorTransactionsResponse>();
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
    return _AnchorTransactionsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class AnchorTransactionRequest {
  /// (optional) The id of the transaction.
  String? id;

  /// (optional) The stellar transaction id of the transaction.
  String? stellarTransactionId;

  /// (optional) The external transaction id of the transaction.
  String? externalTransactionId;

  /// (optional) Defaults to en if not specified or if the specified language
  /// is not supported. Language code specified using RFC 4646. Error fields
  /// and other human readable messages in the response should
  /// be in this language.
  String? lang;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

class AnchorTransactionResponse extends Response {
  AnchorTransaction transaction;

  AnchorTransactionResponse(this.transaction);

  factory AnchorTransactionResponse.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionResponse(
          AnchorTransaction.fromJson(json['transaction']));
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

  static Future<AnchorTransactionResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<AnchorTransactionResponse> type =
        TypeToken<AnchorTransactionResponse>();
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
    return _AnchorTransactionRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class PatchTransactionRequest {
  /// Id of the transaction
  String id;

  /// An object containing the values requested to be updated by the anchor
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#pending-transaction-info-update
  Map<String, dynamic>? fields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  PatchTransactionRequest(this.id, {this.fields, this.jwt});
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

  static Future<http.Response> requestExecute(http.Client httpClient, Uri uri,
      Map<String, dynamic> fields, String? jwt) async {
    final Map<String, String> atHeaders = RequestBuilder.headers;
    if (jwt != null) {
      atHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.patch(uri,
        body: {"transaction": json.encode(fields)}, headers: atHeaders);
  }

  Future<http.Response> execute(String? jwt) {
    return _PatchTransactionRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt);
  }
}
