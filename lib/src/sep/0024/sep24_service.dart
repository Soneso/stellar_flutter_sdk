import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';
import '../0009/standard_kyc_fields.dart';
import 'dart:convert';

/// Implements SEP-0024 v3.8.0 - Hosted Deposit and Withdrawal for Stellar anchors.
///
/// SEP-0024 defines a standard protocol for anchors to facilitate deposits and
/// withdrawals using an interactive web interface. This allows users to convert
/// between Stellar assets and fiat currencies or other external assets.
///
/// The interactive flow works as follows:
/// 1. Client authenticates with SEP-10 WebAuth to get a JWT token
/// 2. Client calls the deposit or withdraw endpoint with asset and amount
/// 3. Server returns a URL for an interactive web interface
/// 4. Client displays the URL in a popup/webview where user completes KYC
/// 5. User provides additional details (bank account, amounts, etc.)
/// 6. Server processes the transaction and updates status
/// 7. Client polls the transaction status endpoint for updates
///
/// Transaction statuses:
/// - incomplete: Additional user action required via the interactive URL
/// - pending_user_transfer_start: Waiting for user to initiate transfer
/// - pending_anchor: Anchor is processing the transaction
/// - pending_stellar: Transaction submitted to Stellar network
/// - pending_external: Pending external payment system
/// - pending_trust: Waiting for user to establish trustline
/// - pending_user: Waiting for user action (e.g., provide payment details)
/// - completed: Transaction successfully completed
/// - error: Transaction failed with an error
///
/// Example - Interactive deposit flow:
/// ```dart
/// // 1. Initialize SEP-24 service
/// final sep24 = await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');
///
/// // 2. Get anchor capabilities
/// final info = await sep24.info();
/// print('Supported deposit assets: ${info.depositAssets.keys}');
///
/// // 3. Check fees (optional)
/// final feeRequest = SEP24FeeRequest()
///   ..operation = 'deposit'
///   ..assetCode = 'USD'
///   ..amount = 100.0
///   ..jwt = authToken;
/// final feeResponse = await sep24.fee(feeRequest);
/// print('Fee: ${feeResponse.fee}');
///
/// // 4. Initiate deposit
/// final depositRequest = SEP24DepositRequest()
///   ..assetCode = 'USD'
///   ..account = userAccountId
///   ..amount = '100.0'
///   ..jwt = authToken;
///
/// final response = await sep24.deposit(depositRequest);
///
/// // 5. Open interactive URL in webview/popup
/// print('Open URL: ${response.url}');
/// // Display response.url in webview with ID response.id
///
/// // 6. Poll for transaction status
/// Timer.periodic(Duration(seconds: 5), (timer) async {
///   final txRequest = SEP24TransactionRequest()
///     ..id = response.id
///     ..jwt = authToken;
///
///   final txResponse = await sep24.transaction(txRequest);
///   print('Status: ${txResponse.transaction.status}');
///
///   if (txResponse.transaction.status == 'completed') {
///     timer.cancel();
///     print('Deposit completed!');
///   } else if (txResponse.transaction.status == 'error') {
///     timer.cancel();
///     print('Error: ${txResponse.transaction.message}');
///   }
/// });
/// ```
///
/// Example - Interactive withdrawal flow:
/// ```dart
/// final sep24 = await TransferServerSEP24Service.fromDomain('testanchor.stellar.org');
///
/// final withdrawRequest = SEP24WithdrawRequest()
///   ..assetCode = 'USD'
///   ..account = userAccountId
///   ..amount = '50.0'
///   ..jwt = authToken;
///
/// final response = await sep24.withdraw(withdrawRequest);
///
/// // Open interactive URL for withdrawal details
/// print('Complete withdrawal at: ${response.url}');
/// // User provides bank details via interactive interface
/// ```
///
/// Authentication requirements:
/// - Most endpoints require SEP-10 authentication (JWT token)
/// - The /info endpoint does NOT require authentication
/// - The /fee endpoint may require authentication (check feeEndpointInfo.authenticationRequired)
/// - All deposit, withdraw, transaction, and transactions endpoints require authentication
/// - JWT tokens are obtained via the SEP-10 WebAuth flow
/// - Tokens should be included in request objects (jwt field)
/// - SEP-45 (Multi-Account Authentication) is supported for shared accounts
///
/// CORS considerations:
/// - The interactive URL flow requires proper CORS configuration on the anchor side
/// - When displaying the interactive URL in a browser-based environment (web apps),
///   ensure the anchor's domain allows cross-origin requests
/// - For native apps, display the URL in a secure webview or external browser
/// - The anchor must set appropriate CORS headers to allow wallet domains
///
/// Security considerations:
/// - All authenticated requests require SEP-10 JWT tokens
/// - Interactive URLs must be displayed in a secure webview/popup
/// - Never share JWT tokens with untrusted parties
/// - Validate transaction details before user confirmation
/// - Monitor transaction status for errors or unexpected changes
/// - Use HTTPS for all communication with the anchor
///
/// See also:
/// - [SEP-0024 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md)
/// - [WebAuth] for obtaining JWT tokens (SEP-10)
/// - [KYCService] for customer information (SEP-12)
/// - [fromDomain] for easy initialization from stellar.toml
class TransferServerSEP24Service {
  String _transferServiceAddress;
  late http.Client httpClient;
  Map<String, String>? httpRequestHeaders;

  /// Creates a TransferServerSEP24Service with explicit transfer server address.
  ///
  /// Initializes the service with HTTP client for making SEP-24 API requests.
  TransferServerSEP24Service(this._transferServiceAddress,
      {http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient ?? http.Client();
  }

  /// Creates an instance of this class by loading the transfer server sep 24 url from the given [domain] stellar toml file.
  static Future<TransferServerSEP24Service> fromDomain(String domain,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders}) async {
    StellarToml toml = await StellarToml.fromDomain(domain,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
    String? addr = toml.generalInformation.transferServerSep24;
    checkNotNull(
        addr, "Transfer server SEP 24 not available for domain " + domain);
    return TransferServerSEP24Service(addr!,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
  }

  /// Get the anchors basic info about what their TRANSFER_SERVER_SEP0024 support to wallets and clients.
  /// [lang] Language code specified using ISO 639-1. description fields in the response should be in this language. Defaults to en.
  Future<SEP24InfoResponse> info([String? lang]) async {
    Uri serverURI = Util.appendEndpointToUrl(_transferServiceAddress, 'info');

    _InfoRequestBuilder requestBuilder = _InfoRequestBuilder(
        httpClient, serverURI,
        httpRequestHeaders: this.httpRequestHeaders);

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

    _FeeRequestBuilder requestBuilder = _FeeRequestBuilder(
        httpClient, serverURI,
        httpRequestHeaders: this.httpRequestHeaders);

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
      } else if (e.code != 200) {
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

    _PostRequestBuilder requestBuilder = _PostRequestBuilder(
        httpClient, serverURI,
        httpRequestHeaders: this.httpRequestHeaders);

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

    _PostRequestBuilder requestBuilder = _PostRequestBuilder(
        httpClient, serverURI,
        httpRequestHeaders: this.httpRequestHeaders);

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
        _AnchorTransactionsRequestBuilder(httpClient, serverURI,
            httpRequestHeaders: this.httpRequestHeaders);

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
        _AnchorTransactionRequestBuilder(httpClient, serverURI,
            httpRequestHeaders: this.httpRequestHeaders);

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

/// Information about a specific asset available for deposit.
///
/// Contains configuration details for depositing an asset, including deposit
/// limits and fee structure. Returned as part of the /info endpoint response.
///
/// See: [SEP24InfoResponse]
class SEP24DepositAsset extends Response {
  /// True if deposit for this asset is supported by the anchor.
  bool enabled;

  /// Minimum amount that can be deposited.
  /// No limit if not specified.
  double? minAmount;

  /// Maximum amount that can be deposited.
  /// No limit if not specified.
  double? maxAmount;

  /// Fixed (base) fee for deposit in units of the deposited asset.
  /// This is in addition to any feePercent.
  /// Omitted if there is no fee or the fee schedule is complex (use /fee endpoint).
  double? feeFixed;

  /// Percentage fee for deposit in percentage points.
  /// This is in addition to any feeFixed.
  /// Omitted if there is no fee or the fee schedule is complex (use /fee endpoint).
  double? feePercent;

  /// Minimum fee in units of the deposited asset.
  double? feeMinimum;

  /// Creates a SEP24DepositAsset with deposit configuration.
  ///
  /// Contains limits and fee structure for depositing this asset.
  SEP24DepositAsset(this.enabled, this.minAmount, this.maxAmount, this.feeFixed,
      this.feePercent, this.feeMinimum);

  /// Creates a SEP24DepositAsset from JSON response data.
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

/// Information about a specific asset available for withdrawal.
///
/// Contains configuration details for withdrawing an asset, including withdrawal
/// limits and fee structure. Returned as part of the /info endpoint response.
///
/// See: [SEP24InfoResponse]
class SEP24WithdrawAsset extends Response {
  /// True if withdrawal for this asset is supported by the anchor.
  bool enabled;

  /// Minimum amount that can be withdrawn.
  /// No limit if not specified.
  double? minAmount;

  /// Maximum amount that can be withdrawn.
  /// No limit if not specified.
  double? maxAmount;

  /// Fixed (base) fee for withdrawal in units of the withdrawn asset.
  /// This is in addition to any feePercent.
  /// Omitted if there is no fee or the fee schedule is complex (use /fee endpoint).
  double? feeFixed;

  /// Percentage fee for withdrawal in percentage points.
  /// This is in addition to any feeFixed.
  /// Omitted if there is no fee or the fee schedule is complex (use /fee endpoint).
  double? feePercent;

  /// Minimum fee in units of the withdrawn asset.
  double? feeMinimum;

  /// Creates a SEP24WithdrawAsset with withdrawal configuration.
  ///
  /// Contains limits and fee structure for withdrawing this asset.
  SEP24WithdrawAsset(this.enabled, this.minAmount, this.maxAmount,
      this.feeFixed, this.feePercent, this.feeMinimum);

  /// Creates a SEP24WithdrawAsset from JSON response data.
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

/// Information about the /fee endpoint availability and requirements.
///
/// Indicates whether the anchor provides a separate fee endpoint for querying
/// fees, and whether authentication is required to access it.
///
/// See: [SEP24InfoResponse], [TransferServerSEP24Service.fee]
class FeeEndpointInfo extends Response {
  /// True if the /fee endpoint is available.
  /// If false, all fee information is provided in the deposit/withdraw asset objects.
  bool enabled;

  /// True if client must be authenticated (SEP-10 JWT) before accessing the fee endpoint.
  bool authenticationRequired;

  /// Creates a FeeEndpointInfo with fee endpoint configuration.
  ///
  /// Indicates fee endpoint availability and authentication requirements.
  FeeEndpointInfo(this.enabled, this.authenticationRequired);

  /// Creates a FeeEndpointInfo from JSON response data.
  factory FeeEndpointInfo.fromJson(Map<String, dynamic> json) {
    bool? auth = json['authentication_required'];
    return FeeEndpointInfo(json['enabled'], auth != null ? auth : false);
  }
}

/// Feature flags indicating optional capabilities supported by the anchor.
///
/// These flags help clients understand what advanced features the anchor supports
/// for deposits and withdrawals.
///
/// See: [SEP24InfoResponse]
class FeatureFlags extends Response {
  /// Whether the anchor supports creating accounts for users requesting deposits.
  /// When true, the anchor will create a Stellar account if one doesn't exist.
  /// Defaults to true.
  bool accountCreation;

  /// Whether the anchor supports sending deposit funds as claimable balances.
  /// This is relevant for users without a trustline to the requested asset.
  /// Defaults to false.
  bool claimableBalances;

  /// Creates a FeatureFlags with anchor capability flags.
  ///
  /// Indicates which optional features the anchor supports.
  FeatureFlags(this.accountCreation, this.claimableBalances);

  /// Creates a FeatureFlags from JSON response data.
  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    bool? accCreation = json['account_creation'];
    bool? claimableB = json['claimable_balances'];
    return FeatureFlags(accCreation != null ? accCreation : true,
        claimableB != null ? claimableB : false);
  }
}

/// Response from the /info endpoint containing anchor capabilities.
///
/// This response provides comprehensive information about which assets the anchor
/// supports for deposits and withdrawals, fee structures, and available features.
///
/// Authentication: Not required.
///
/// Example usage:
/// ```dart
/// final info = await sep24.info();
/// print('Supported deposit assets: ${info.depositAssets?.keys}');
/// if (info.depositAssets?['USD']?.enabled == true) {
///   print('USD deposits enabled');
/// }
/// ```
///
/// See: [TransferServerSEP24Service.info]
class SEP24InfoResponse extends Response {
  /// Map of asset codes to deposit configuration.
  /// Keys are asset codes (e.g., 'USD', 'BTC'), values contain deposit details.
  Map<String, SEP24DepositAsset>? depositAssets;

  /// Map of asset codes to withdrawal configuration.
  /// Keys are asset codes (e.g., 'USD', 'BTC'), values contain withdrawal details.
  Map<String, SEP24WithdrawAsset>? withdrawAssets;

  /// Information about the /fee endpoint if available.
  FeeEndpointInfo? feeEndpointInfo;

  /// Optional feature flags indicating advanced capabilities.
  FeatureFlags? featureFlags;

  /// Creates a SEP24InfoResponse with anchor capabilities.
  ///
  /// Contains supported assets and feature information from /info endpoint.
  SEP24InfoResponse(this.depositAssets, this.withdrawAssets,
      this.feeEndpointInfo, this.featureFlags);

  /// Creates a SEP24InfoResponse from JSON response data.
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
  Map<String, String>? httpRequestHeaders;
  _InfoRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _InfoRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24InfoResponse> requestExecute(
      http.Client httpClient, Uri uri,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<SEP24InfoResponse> type = TypeToken<SEP24InfoResponse>();
    ResponseHandler<SEP24InfoResponse> responseHandler =
        ResponseHandler<SEP24InfoResponse>(type);

    final Map<String, String> infoHeaders = {...(httpRequestHeaders ?? {})};
    return await httpClient.get(uri, headers: infoHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24InfoResponse> execute() {
    return _InfoRequestBuilder.requestExecute(this.httpClient, this.buildUri(),
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request to query the anchor's fee schedule for deposit or withdrawal operations.
///
/// This request allows clients to query the exact fee that would be charged for
/// a specific deposit or withdrawal operation. This endpoint is optional for anchors
/// that can fully express their fee structure in the /info response using fee_fixed,
/// fee_percent, and fee_minimum fields.
///
/// Authentication: Required if feeEndpointInfo.authenticationRequired is true in
/// the /info response. Provide a SEP-10 JWT token in the jwt field.
///
/// Example usage:
/// ```dart
/// final feeRequest = SEP24FeeRequest()
///   ..operation = 'deposit'
///   ..assetCode = 'USD'
///   ..amount = 100.0
///   ..jwt = authToken;
///
/// final feeResponse = await sep24.fee(feeRequest);
/// print('Fee: ${feeResponse.fee}');
/// ```
///
/// See: [TransferServerSEP24Service.fee]
class SEP24FeeRequest {
  /// Kind of operation (deposit or withdraw).
  late String operation;

  /// Type of deposit or withdrawal (SEPA, bank_account, cash, etc.).
  /// Optional. Used when the anchor supports multiple transfer methods for an asset.
  String? type;

  /// Asset code.
  late String assetCode;

  /// Amount of the asset that will be deposited/withdrawn.
  late double amount;

  /// JWT token previously received from the anchor via the SEP-10 authentication flow.
  /// Required if the fee endpoint requires authentication.
  String? jwt;
}

/// Response from the /fee endpoint containing the calculated fee.
///
/// Contains the exact fee that would be charged for a specific deposit or
/// withdrawal operation with the given parameters.
///
/// See: [TransferServerSEP24Service.fee], [SEP24FeeRequest]
class SEP24FeeResponse extends Response {
  /// The total fee (in units of the asset involved) that would be charged
  /// to deposit/withdraw the specified amount.
  double? fee;

  /// Creates a SEP24FeeResponse with calculated fee amount.
  ///
  /// Contains the fee that would be charged for the specified operation.
  SEP24FeeResponse(this.fee);

  /// Creates a SEP24FeeResponse from JSON response data.
  factory SEP24FeeResponse.fromJson(Map<String, dynamic> json) =>
      SEP24FeeResponse(convertDouble(json['fee']));
}

/// Requests the fee data if available.
class _FeeRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;
  _FeeRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _FeeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24FeeResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<SEP24FeeResponse> type = TypeToken<SEP24FeeResponse>();
    ResponseHandler<SEP24FeeResponse> responseHandler =
        ResponseHandler<SEP24FeeResponse>(type);

    final Map<String, String> feeHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };

    return await httpClient.get(uri, headers: feeHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24FeeResponse> execute(String? jwt) {
    return _FeeRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request to initiate an interactive deposit flow with an anchor.
///
/// A deposit allows a user to send external assets (fiat via bank transfer, BTC,
/// USD cash, etc.) to an anchor, which then sends an equivalent amount of the
/// Stellar asset (minus fees) to the user's Stellar account.
///
/// The deposit endpoint returns an interactive URL where the user completes KYC,
/// provides payment details, and receives instructions for sending their off-chain
/// assets to the anchor.
///
/// Authentication: Always required. Must provide a SEP-10 JWT token.
///
/// Example usage:
/// ```dart
/// final depositRequest = SEP24DepositRequest()
///   ..assetCode = 'USD'
///   ..account = userAccountId
///   ..amount = '100.0'
///   ..jwt = authToken;
///
/// final response = await sep24.deposit(depositRequest);
/// // Display response.url in a webview or popup
/// ```
///
/// See: [TransferServerSEP24Service.deposit]
class SEP24DepositRequest {
  /// JWT token previously received from the anchor via the SEP-10 authentication flow.
  /// Required for authentication.
  late String jwt;

  /// The code of the Stellar asset the user wants to receive for their deposit.
  /// Must match one of the codes listed in the /info response's deposit object.
  /// Use 'native' to represent the native XLM token.
  late String assetCode;

  /// The issuer of the Stellar asset the user wants to receive for their deposit.
  /// If not provided, the anchor will use the asset they issue (as described in their TOML file).
  /// Must not be set if assetCode is 'native'.
  String? assetIssuer;

  /// The off-chain asset user wants to send (Asset Identification Format).
  /// This is the asset the user initially holds (e.g., fiat asset, BTC).
  /// If not provided, it will be collected in the interactive flow.
  /// When quoteId is specified, this must match the quote's sell_asset or be omitted.
  String? sourceAsset;

  /// Amount of asset requested to deposit.
  /// If not provided, it will be collected in the interactive flow.
  String? amount;

  /// The id returned from a SEP-38 POST /quote response.
  /// When provided, the deposit uses the firm quote for the asset exchange.
  String? quoteId;

  /// The Stellar (G...) or muxed account (M...) that will receive the deposit.
  /// Defaults to the account authenticated via SEP-10 if not specified.
  String? account;

  /// Value of memo to attach to the Stellar payment transaction.
  /// For hash memos, this should be base64-encoded.
  /// Can be different from the memo in the SEP-10 JWT (e.g., as a reference number).
  String? memo;

  /// Type of memo that anchor should attach to the Stellar payment transaction.
  /// One of: text, id, or hash
  String? memoType;

  /// Wallet name that the anchor should display to explain where funds are going.
  /// Used in communications and pages about the deposit.
  String? walletName;

  /// URL the anchor should link to when notifying the user that the transaction has completed.
  String? walletUrl;

  /// Language code specified using RFC 4646 (e.g., en-US).
  /// Defaults to 'en' if not specified or if the specified language is not supported.
  /// Error fields, interactive flow UI, and user-facing strings will be in this language.
  String? lang;

  /// True if the client supports receiving deposit transactions as a claimable balance.
  /// This is relevant for users without a trustline to the requested asset.
  String? claimableBalanceSupported;

  /// SEP-9 KYC fields to make the onboarding experience simpler.
  /// These fields may be used to pre-fill the interactive form.
  StandardKYCFields? kycFields;

  /// Custom SEP-9 fields for transmission (fieldname, value).
  Map<String, String>? customFields;

  /// Custom SEP-9 files for transmission (fieldname, value).
  Map<String, Uint8List>? customFiles;
}

/// Response from deposit or withdraw endpoints containing interactive flow details.
///
/// This response provides the URL for the interactive web interface where the user
/// completes KYC, provides additional details, and receives instructions.
///
/// The URL should be displayed in a popup window or webview. The client should
/// poll the /transaction endpoint using the provided ID to monitor status changes.
///
/// Example usage:
/// ```dart
/// final response = await sep24.deposit(depositRequest);
/// // Display response.url in a webview
/// // Poll for updates using response.id
/// ```
///
/// See: [TransferServerSEP24Service.deposit], [TransferServerSEP24Service.withdraw]
class SEP24InteractiveResponse extends Response {
  /// Always set to 'interactive_customer_info_needed'.
  /// Indicates that user interaction is required via the provided URL.
  String type;

  /// URL hosted by the anchor for the interactive flow.
  /// Display this URL to the user in a popup window or webview.
  /// The user will complete KYC and provide necessary details here.
  String url;

  /// The anchor's internal ID for this deposit or withdrawal request.
  /// Use this ID to query the /transaction endpoint to check the status.
  String id;

  /// Creates a SEP24InteractiveResponse with interactive flow details.
  ///
  /// Contains URL and ID for the interactive deposit/withdrawal flow.
  SEP24InteractiveResponse(this.type, this.url, this.id);

  /// Creates a SEP24InteractiveResponse from JSON response data.
  factory SEP24InteractiveResponse.fromJson(Map<String, dynamic> json) =>
      SEP24InteractiveResponse(json['type'], json['url'], json['id']);
}

class _PostRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, Uint8List>? _files;
  Map<String, String>? httpRequestHeaders;

  _PostRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
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
      String jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<SEP24InteractiveResponse> type =
        TypeToken<SEP24InteractiveResponse>();
    ResponseHandler<SEP24InteractiveResponse> responseHandler =
        ResponseHandler<SEP24InteractiveResponse>(type);

    final Map<String, String> hHeaders = {
      ...(httpRequestHeaders ?? {}),
      "Authorization": "Bearer $jwt",
    };
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
        this.httpClient, this.buildUri(), _fields, _files, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request to initiate an interactive withdrawal flow with an anchor.
///
/// A withdrawal allows a user to redeem a Stellar asset for the real-world asset
/// (fiat via bank transfer, BTC, USD cash, etc.) via the anchor. The user sends
/// the Stellar asset to the anchor, and the anchor sends the equivalent off-chain
/// asset (minus fees) to the user.
///
/// The withdraw endpoint returns an interactive URL where the user completes KYC,
/// provides bank account or wallet details, and receives instructions for the withdrawal.
///
/// Authentication: Always required. Must provide a SEP-10 JWT token.
///
/// Example usage:
/// ```dart
/// final withdrawRequest = SEP24WithdrawRequest()
///   ..assetCode = 'USD'
///   ..account = userAccountId
///   ..amount = '50.0'
///   ..jwt = authToken;
///
/// final response = await sep24.withdraw(withdrawRequest);
/// // Display response.url in a webview or popup
/// ```
///
/// See: [TransferServerSEP24Service.withdraw]
class SEP24WithdrawRequest {
  /// JWT token previously received from the anchor via the SEP-10 authentication flow.
  /// Required for authentication.
  late String jwt;

  /// Code of the Stellar asset the user wants to withdraw.
  /// Must match one of the codes listed in the /info response's withdraw object.
  /// Use 'native' to represent the native XLM token.
  late String assetCode;

  /// The issuer of the Stellar asset the user wants to withdraw.
  /// If not provided, the anchor will use the asset they issue (as described in their TOML file).
  /// Must not be set if assetCode is 'native'.
  String? assetIssuer;

  /// The off-chain asset user wants to receive (Asset Identification Format).
  /// This is the destination asset (e.g., fiat asset, BTC).
  /// If not provided, it will be collected in the interactive flow.
  /// When quoteId is specified, this must match the quote's buy_asset or be omitted.
  String? destinationAsset;

  /// Amount of asset requested to withdraw.
  /// If not provided, it will be collected in the interactive flow.
  String? amount;

  /// The id returned from a SEP-38 POST /quote response.
  /// When provided, the withdrawal uses the firm quote for the asset exchange.
  String? quoteId;

  /// The Stellar (G...) or muxed account (M...) that will send the withdrawal payment.
  /// Defaults to the account authenticated via SEP-10 if not specified.
  String? account;

  @Deprecated('Use the sub value in the SEP-10 JWT instead. '
      'This field was originally intended to differentiate users of the same Stellar account. '
      'Anchors should use the sub value from the decoded SEP-10 JWT. '
      'See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md#shared-omnibus-or-pooled-accounts')
  /// This field was originally intended to differentiate users of the same Stellar account.
  /// However, anchors should use the sub value included in the decoded SEP-10 JWT instead.
  /// Anchors should still support this parameter to maintain backward compatibility.
  String? memo;

  @Deprecated('Use the sub value in the SEP-10 JWT instead. '
      'Memos for user identification should always be of type id.')
  /// Type of memo. One of: text, id, or hash.
  /// Deprecated because memos used to identify users should always be of type id.
  String? memoType;

  /// Wallet name that the anchor should display to explain where funds are coming from.
  /// Used in communications and pages about the withdrawal.
  String? walletName;

  /// URL the anchor can show when referencing the wallet involved in the withdrawal.
  /// For example, displayed in the anchor's transaction history.
  String? walletUrl;

  /// Language code specified using RFC 4646 (e.g., en-US).
  /// Defaults to 'en' if not specified or if the specified language is not supported.
  /// Error fields, interactive flow UI, and user-facing strings will be in this language.
  String? lang;

  /// The memo the anchor must use when sending refund payments back to the user.
  /// If not specified, the anchor should use the same memo from the original payment.
  /// If specified, refundMemoType must also be specified.
  String? refundMemo;

  /// The type of the refundMemo. One of: id, text, or hash.
  /// If specified, refundMemo must also be specified.
  /// See: [Stellar developer docs](https://developers.stellar.org)
  String? refundMemoType;

  /// SEP-9 KYC fields to make the onboarding experience simpler.
  /// These fields may be used to pre-fill the interactive form.
  StandardKYCFields? kycFields;

  /// Custom SEP-9 fields for transmission (fieldname, value).
  Map<String, String>? customFields;

  /// Custom SEP-9 files for transmission (fieldname, value).
  Map<String, Uint8List>? customFiles;
}

/// Request to query transaction history for deposits and withdrawals.
///
/// This endpoint allows clients to fetch the status and history of transactions
/// with the anchor. It returns transactions associated with the account encoded
/// in the authenticated SEP-10 JWT token.
///
/// Authentication: Always required. Must provide a SEP-10 JWT token.
///
/// Example usage:
/// ```dart
/// final txRequest = SEP24TransactionsRequest()
///   ..assetCode = 'USD'
///   ..kind = 'deposit'
///   ..limit = 10
///   ..jwt = authToken;
///
/// final response = await sep24.transactions(txRequest);
/// for (var tx in response.transactions) {
///   print('${tx.id}: ${tx.status}');
/// }
/// ```
///
/// See: [TransferServerSEP24Service.transactions]
class SEP24TransactionsRequest {
  /// JWT token previously received from the anchor via the SEP-10 authentication flow.
  /// Required for authentication.
  late String jwt;

  /// The code of the asset of interest (e.g., BTC, ETH, USD, INR).
  late String assetCode;

  /// The response should contain transactions starting on or after this date and time.
  /// UTC ISO 8601 string format.
  DateTime? noOlderThan;

  /// The maximum number of transactions to return.
  /// Used for pagination.
  int? limit;

  /// The kind of transaction that is desired.
  /// Should be either 'deposit' or 'withdrawal'.
  String? kind;

  /// The response should contain transactions starting prior to this ID (exclusive).
  /// Used for pagination with the transaction ID.
  String? pagingId;

  /// Language code specified using RFC 4646 (e.g., en-US).
  /// Defaults to 'en' if not specified or if the specified language is not supported.
  String? lang;
}

/// Represents a single deposit or withdrawal transaction with an anchor.
///
/// Contains comprehensive information about the transaction status, amounts,
/// fees, and relevant identifiers for tracking the transaction through its lifecycle.
///
/// Transaction statuses:
/// - incomplete: Additional user action required via the interactive URL
/// - pending_user_transfer_start: Waiting for user to initiate transfer
/// - pending_anchor: Anchor is processing the transaction
/// - pending_stellar: Transaction submitted to Stellar network
/// - pending_external: Pending external payment system
/// - pending_trust: Waiting for user to establish trustline
/// - pending_user: Waiting for user action
/// - completed: Transaction successfully completed
/// - refunded: Transaction was refunded
/// - expired: Transaction expired before completion
/// - error: Transaction failed with an error
///
/// See: [SEP24TransactionResponse], [SEP24TransactionsResponse]
class SEP24Transaction extends Response {
  /// Unique, anchor-generated ID for the deposit or withdrawal.
  String id;

  /// Type of transaction: 'deposit' or 'withdrawal'.
  String kind;

  /// Processing status of the deposit or withdrawal.
  /// See class documentation for list of possible statuses.
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

  /// (optional) The date and time by when the user action is required.
  /// In certain statuses, such as pending_user_transfer_start or incomplete,
  /// anchor waits for the user action and user_action_required_by field should
  /// be used to show the time anchors gives for the user to make an action
  /// before transaction will automatically be moved into a different status
  /// (such as expired or to be refunded). user_action_required_by should
  /// only be specified for statuses where user action is required,
  /// and omitted for all other. Anchor should specify the action waited on
  /// using message or more_info_url.
  String? userActionRequiredBy;

  /// (optional) transaction_id on Stellar network of the transfer that either completed the deposit or started the withdrawal.
  String? stellarTransactionId;

  /// (optional) ID of transaction on external network that either started the deposit or completed the withdrawal.
  String? externalTransactionId;

  /// Human readable explanation of transaction status, if needed.
  String? message;

  @Deprecated('Use the refunds object and refunded status instead. '
      'This field is deprecated in favor of the refunds object and the refunded status.')
  /// True if the transaction was refunded in full.
  /// False if the transaction was partially refunded or not refunded.
  /// For more details about refunds, use the refunds object instead.
  bool? refunded;

  /// An object describing any on-chain or off-chain refund associated with this transaction.
  /// Contains detailed information about refund amounts, fees, and individual payment records.
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

  /// Creates a SEP24Transaction with transaction details.
  ///
  /// Contains comprehensive information about a deposit or withdrawal transaction.
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
      this.userActionRequiredBy,
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

  /// Creates a SEP24Transaction from JSON response data.
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
        json['user_action_required_by'],
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

/// Response from the /transactions endpoint containing a list of transactions.
///
/// Returns transaction history for deposits and withdrawals associated with
/// the authenticated account. Supports pagination and filtering by asset,
/// transaction kind, and date range.
///
/// See: [TransferServerSEP24Service.transactions], [SEP24TransactionsRequest]
class SEP24TransactionsResponse extends Response {
  /// List of transactions matching the request criteria.
  /// May be empty if no transactions match the filters.
  List<SEP24Transaction> transactions;

  /// Creates a SEP24TransactionsResponse with transaction list.
  ///
  /// Contains a list of transactions matching the query criteria.
  SEP24TransactionsResponse(this.transactions);

  /// Creates a SEP24TransactionsResponse from JSON response data.
  factory SEP24TransactionsResponse.fromJson(Map<String, dynamic> json) =>
      SEP24TransactionsResponse((json['transactions'] as List)
          .map((e) => SEP24Transaction.fromJson(e))
          .toList());
}

// Requests the transaction history data.
class _AnchorTransactionsRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _AnchorTransactionsRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _AnchorTransactionsRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24TransactionsResponse> requestExecute(
      http.Client httpClient, Uri uri, String jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<SEP24TransactionsResponse> type =
        TypeToken<SEP24TransactionsResponse>();
    ResponseHandler<SEP24TransactionsResponse> responseHandler =
        ResponseHandler<SEP24TransactionsResponse>(type);

    final Map<String, String> atHeaders = {
      ...(httpRequestHeaders ?? {}),
      "Authorization": "Bearer $jwt",
    };
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24TransactionsResponse> execute(String jwt) {
    return _AnchorTransactionsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Information about refunds associated with a transaction.
///
/// Contains details about on-chain or off-chain refunds issued for a transaction,
/// including total amounts, fees, and individual payment records.
///
/// See: [SEP24Transaction], [RefundPayment]
class Refund extends Response {
  /// The total amount refunded to the user, in units of amountInAsset.
  /// If a full refund was issued, this amount should match the transaction's amountIn.
  String amountRefunded;

  /// The total amount charged in fees for processing all refund payments,
  /// in units of amountInAsset.
  /// The sum of all fee values in the payments list should equal this value.
  String amountFee;

  /// A list of individual refund payments made back to the user.
  /// Multiple payments may be issued for partial refunds or refund fee adjustments.
  List<RefundPayment> payments;

  /// Creates a Refund with refund details.
  ///
  /// Contains total refunded amounts and individual payment records.
  Refund(this.amountRefunded, this.amountFee, this.payments);

  /// Creates a Refund from JSON response data.
  factory Refund.fromJson(Map<String, dynamic> json) => Refund(
      json['amount_refunded'],
      json['amount_fee'],
      (json['payments'] as List)
          .map((e) => RefundPayment.fromJson(e))
          .toList());
}

/// Information about a single refund payment.
///
/// Represents an individual payment made back to the user as part of a refund.
/// Multiple refund payments may exist for a single transaction.
///
/// See: [Refund], [SEP24Transaction]
class RefundPayment extends Response {
  /// The payment ID that can be used to identify the refund payment.
  /// This is either a Stellar transaction hash or an off-chain payment identifier
  /// (such as a reference number provided when the refund was initiated).
  /// This ID is not guaranteed to be unique.
  String id;

  /// The type of refund payment: 'stellar' or 'external'.
  /// Indicates whether the refund was made on the Stellar network or via an external system.
  String idType;

  /// The amount sent back to the user for this payment, in units of amountInAsset.
  String amount;

  /// The fee charged for processing this refund payment, in units of amountInAsset.
  String fee;

  /// Creates a RefundPayment with payment information.
  ///
  /// Contains details about a single refund payment transaction.
  RefundPayment(this.id, this.idType, this.amount, this.fee);

  /// Creates a RefundPayment from JSON response data.
  factory RefundPayment.fromJson(Map<String, dynamic> json) =>
      RefundPayment(json['id'], json['id_type'], json['amount'], json['fee']);
}

/// Request to query or validate a specific transaction with the anchor.
///
/// This endpoint allows clients to retrieve detailed information about a single
/// transaction. The anchor must verify that the SEP-10 JWT includes the Stellar
/// account (and optional memo) used when making the original deposit/withdraw request.
///
/// At least one of id, stellarTransactionId, or externalTransactionId must be provided.
///
/// Authentication: Always required. Must provide a SEP-10 JWT token.
///
/// Example usage:
/// ```dart
/// final txRequest = SEP24TransactionRequest()
///   ..id = transactionId
///   ..jwt = authToken;
///
/// final response = await sep24.transaction(txRequest);
/// print('Status: ${response.transaction.status}');
/// ```
///
/// See: [TransferServerSEP24Service.transaction]
class SEP24TransactionRequest {
  /// JWT token previously received from the anchor via the SEP-10 authentication flow.
  /// Required for authentication.
  late String jwt;

  /// The anchor's internal ID for the transaction.
  /// This is the ID returned in the SEP24InteractiveResponse.
  String? id;

  /// The Stellar transaction hash of the transaction on the Stellar network.
  String? stellarTransactionId;

  /// The external transaction ID from the off-chain payment system.
  String? externalTransactionId;

  /// Language code specified using RFC 4646 (e.g., en-US).
  /// Defaults to 'en' if not specified or if the specified language is not supported.
  String? lang;
}

/// Response from the /transaction endpoint containing a single transaction.
///
/// Returns detailed information about a specific transaction identified by
/// its ID, Stellar transaction hash, or external transaction ID.
///
/// See: [TransferServerSEP24Service.transaction], [SEP24TransactionRequest]
class SEP24TransactionResponse extends Response {
  /// The transaction details.
  SEP24Transaction transaction;

  /// Creates a SEP24TransactionResponse with transaction details.
  ///
  /// Contains a single transaction queried by ID or hash.
  SEP24TransactionResponse(this.transaction);

  /// Creates a SEP24TransactionResponse from JSON response data.
  factory SEP24TransactionResponse.fromJson(Map<String, dynamic> json) =>
      SEP24TransactionResponse(SEP24Transaction.fromJson(json['transaction']));
}

// Requests the transaction data for a specific transaction.
class _AnchorTransactionRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _AnchorTransactionRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _AnchorTransactionRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<SEP24TransactionResponse> requestExecute(
      http.Client httpClient, Uri uri, String jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<SEP24TransactionResponse> type =
        TypeToken<SEP24TransactionResponse>();
    ResponseHandler<SEP24TransactionResponse> responseHandler =
        ResponseHandler<SEP24TransactionResponse>(type);

    final Map<String, String> atHeaders = {
      ...(httpRequestHeaders ?? {}),
      "Authorization": "Bearer $jwt",
    };
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<SEP24TransactionResponse> execute(String jwt) {
    return _AnchorTransactionRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Exception thrown when the anchor returns an error response.
///
/// This exception is thrown when the server responds with an error object
/// containing an error message. The error field contains the anchor's
/// error description.
///
/// See: [TransferServerSEP24Service]
class RequestErrorException implements Exception {
  /// The error message provided by the anchor.
  String error;

  /// Creates a RequestErrorException with error message.
  ///
  /// Contains the error message from the anchor.
  RequestErrorException(this.error);

  String toString() {
    return error;
  }
}

/// Exception thrown when authentication is required but not provided.
///
/// This exception is thrown when an endpoint requires SEP-10 authentication
/// (JWT token) but the request was made without authentication or with
/// invalid credentials.
///
/// To resolve: Obtain a valid JWT token using the SEP-10 WebAuth flow and
/// include it in the request.
///
/// See: [TransferServerSEP24Service]
class SEP24AuthenticationRequiredException implements Exception {
  String toString() {
    return "The endpoint requires authentication.";
  }
}

/// Exception thrown when the requested transaction cannot be found.
///
/// This exception is thrown when querying the /transaction endpoint with
/// an ID, stellar_transaction_id, or external_transaction_id that doesn't
/// exist or doesn't belong to the authenticated account.
///
/// See: [TransferServerSEP24Service.transaction]
class SEP24TransactionNotFoundException implements Exception {
  String toString() {
    return "The anchor could not find the transaction";
  }
}
