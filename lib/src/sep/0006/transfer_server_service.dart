import 'dart:convert';

import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';

/// Implements SEP-0006 Programmatic Deposit and Withdrawal API.
///
/// This service implements SEP-0006 version 4.3.0, which defines a non-interactive
/// protocol for deposits and withdrawals between Stellar assets and external systems
/// (fiat, crypto, etc.). Unlike SEP-0024's interactive flow, SEP-0006 is designed
/// for programmatic integration where all required information can be provided in
/// API requests.
///
/// Typical workflow:
/// 1. Authenticate with SEP-10 WebAuth to get JWT token
/// 2. Call /info to discover supported assets and required fields
/// 3. Call /deposit or /withdraw with required parameters
/// 4. Server returns deposit address or withdrawal details
/// 5. Poll /transactions or /transaction for status updates
///
/// Use SEP-0006 when:
/// - You can collect all required information programmatically
/// - You don't want to use webviews or popups
/// - You need full control over the user experience
///
/// Use SEP-0024 instead when:
/// - Anchors require interactive KYC/verification
/// - Complex multi-step workflows are needed
/// - Anchors prefer to control the user interface
///
/// Example - Programmatic deposit:
/// ```dart
/// final service = await TransferServerService.fromDomain('testanchor.stellar.org');
///
/// // 1. Get anchor capabilities
/// final info = await service.info(jwt: authToken);
/// print('Supported assets: ${info.deposit.keys}');
///
/// // 2. Initiate deposit
/// final request = DepositRequest()
///   ..assetCode = 'USD'
///   ..account = userAccountId
///   ..jwt = authToken;
///
/// final response = await service.deposit(request);
/// print('Deposit to: ${response.how}');
/// print('Minimum amount: ${response.minAmount}');
///
/// // 3. Poll for transaction status
/// final txResponse = await service.transaction(
///   id: response.id,
///   jwt: authToken,
/// );
/// print('Status: ${txResponse.transaction.status}');
/// ```
///
/// Example - Programmatic withdrawal:
/// ```dart
/// final request = WithdrawRequest()
///   ..assetCode = 'USD'
///   ..type = 'bank_account'
///   ..dest = 'account_number_here'
///   ..destExtra = 'routing_number_here'
///   ..jwt = authToken;
///
/// final response = await service.withdraw(request);
/// print('Withdrawal ID: ${response.id}');
/// print('Account to send from: ${response.accountId}');
/// ```
///
/// See also:
/// - [SEP-0006 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md)
/// - [TransferServerSEP24Service] for interactive deposits/withdrawals
/// - [WebAuth] for obtaining JWT tokens (SEP-10)
class TransferServerService {
  late String _transferServiceAddress;
  late http.Client httpClient;
  Map<String, String>? httpRequestHeaders;

  /// Creates a TransferServerService instance with the specified transfer server address.
  ///
  /// Use [fromDomain] instead if you want to automatically discover the transfer
  /// server URL from an anchor's stellar.toml file.
  ///
  /// Parameters:
  /// - [_transferServiceAddress] The base URL of the anchor's transfer server endpoint
  /// - [httpClient] Optional custom HTTP client for making requests
  /// - [httpRequestHeaders] Optional custom headers to include in all requests
  ///
  /// Example:
  /// ```dart
  /// final service = TransferServerService(
  ///   'https://api.example.com/transfer',
  ///   httpRequestHeaders: {'X-Custom-Header': 'value'}
  /// );
  /// ```
  TransferServerService(this._transferServiceAddress,
      {http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient == null ? http.Client() : httpClient;
  }

  /// Creates a TransferServerService by automatically discovering the transfer
  /// server URL from an anchor's stellar.toml file.
  ///
  /// This is the recommended way to create a TransferServerService instance. It
  /// fetches the anchor's stellar.toml file from the specified domain and extracts
  /// the TRANSFER_SERVER URL, then creates a service instance with that URL.
  ///
  /// Parameters:
  /// - [domain] The anchor's domain name (e.g., 'testanchor.stellar.org')
  /// - [httpClient] Optional custom HTTP client for making requests
  /// - [httpRequestHeaders] Optional custom headers to include in all requests
  ///
  /// Returns:
  /// A configured [TransferServerService] instance ready to use.
  ///
  /// Throws:
  /// - [Exception] if the stellar.toml file cannot be fetched
  /// - [Exception] if the TRANSFER_SERVER field is not found in stellar.toml
  ///
  /// Example:
  /// ```dart
  /// final service = await TransferServerService.fromDomain(
  ///   'testanchor.stellar.org'
  /// );
  /// final info = await service.info(jwt: authToken);
  /// ```
  static Future<TransferServerService> fromDomain(String domain,
      {http.Client? httpClient,
      Map<String, String>? httpRequestHeaders}) async {
    StellarToml toml = await StellarToml.fromDomain(domain,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
    String? transferServer = toml.generalInformation.transferServer;
    checkNotNull(transferServer,
        "transfer server not found in stellar toml of domain " + domain);
    return TransferServerService(transferServer!,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
  }

  /// Retrieves basic information about the anchor's transfer server capabilities.
  ///
  /// Queries the /info endpoint to discover which assets the anchor supports for
  /// deposit and withdrawal operations, along with required fields and fee structure
  /// for each asset.
  ///
  /// Parameters:
  /// - [language] Language code for error messages using RFC 4646 (defaults to 'en')
  /// - [jwt] JWT token from SEP-10 authentication
  ///
  /// Returns: Information about supported assets and their requirements
  Future<InfoResponse> info({String? language, String? jwt}) async {
    Uri serverURI = Util.appendEndpointToUrl(_transferServiceAddress, 'info');

    _InfoRequestBuilder requestBuilder = _InfoRequestBuilder(
        httpClient, serverURI,
        httpRequestHeaders: this.httpRequestHeaders);

    final Map<String, String> queryParams = {};

    if (language != null) {
      queryParams["lang"] = language;
    }

    InfoResponse response =
        await requestBuilder.forQueryParameters(queryParams).execute(jwt);

    return response;
  }

  /// Initiates a deposit of an external asset to receive the equivalent Stellar asset.
  ///
  /// A deposit occurs when a user sends an external asset (BTC, USD via bank transfer,
  /// etc.) to an address held by an anchor. The anchor then sends an equivalent amount
  /// of the Stellar asset (minus fees) to the user's Stellar account.
  ///
  /// For deposits involving asset conversion between non-equivalent tokens (e.g., ARS
  /// to USDC), use the depositExchange method instead.
  ///
  /// Parameters:
  /// - [request] Deposit request parameters including asset code, destination account, and optional fields
  ///
  /// Returns: Deposit instructions including how to send the external asset
  ///
  /// Throws:
  /// - [CustomerInformationNeededException] if additional KYC information is required
  /// - [CustomerInformationStatusException] if KYC status needs to be checked
  /// - [AuthenticationRequiredException] if authentication is missing or invalid
  Future<DepositResponse> deposit(DepositRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'deposit');

    _DepositRequestBuilder requestBuilder = _DepositRequestBuilder(
      httpClient,
      serverURI,
      httpRequestHeaders: this.httpRequestHeaders,
    );

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
    if (request.extraFields != null) {
      queryParams.addAll(request.extraFields!);
    }

    try {
      return await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }
  }

  /// Initiates a deposit with asset conversion between non-equivalent tokens.
  ///
  /// Used when the anchor supports SEP-38 quotes and the user wants to deposit one
  /// asset type and receive a different asset type on Stellar. For example, depositing
  /// BRL via bank transfer and receiving USDC on the Stellar network.
  ///
  /// Parameters:
  /// - [request] Deposit exchange request with source asset, destination asset, and amount
  ///
  /// Returns: Deposit instructions for the cross-asset deposit
  ///
  /// Throws:
  /// - [CustomerInformationNeededException] if additional KYC information is required
  /// - [CustomerInformationStatusException] if KYC status needs to be checked
  /// - [AuthenticationRequiredException] if authentication is missing or invalid
  Future<DepositResponse> depositExchange(
      DepositExchangeRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'deposit-exchange');

    _DepositRequestBuilder requestBuilder = _DepositRequestBuilder(
      httpClient,
      serverURI,
      httpRequestHeaders: this.httpRequestHeaders,
    );

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
    if (request.extraFields != null) {
      queryParams.addAll(request.extraFields!);
    }

    try {
      return await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }
  }

  /// Initiates a withdrawal to redeem a Stellar asset for its off-chain equivalent.
  ///
  /// A withdrawal occurs when a user redeems an asset on the Stellar network for its
  /// equivalent off-chain asset via the anchor. For example, redeeming NGNT on Stellar
  /// to receive fiat NGN in a bank account.
  ///
  /// For withdrawals involving asset conversion between non-equivalent tokens (e.g., USDC
  /// to NGN), use the withdrawExchange method instead.
  ///
  /// Parameters:
  /// - [request] Withdrawal request parameters including asset code, withdrawal type, and destination
  ///
  /// Returns: Withdrawal instructions including the Stellar account to send funds to
  ///
  /// Throws:
  /// - [CustomerInformationNeededException] if additional KYC information is required
  /// - [CustomerInformationStatusException] if KYC status needs to be checked
  /// - [AuthenticationRequiredException] if authentication is missing or invalid
  Future<WithdrawResponse> withdraw(WithdrawRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'withdraw');

    _WithdrawRequestBuilder requestBuilder = _WithdrawRequestBuilder(
      httpClient,
      serverURI,
      httpRequestHeaders: this.httpRequestHeaders,
    );

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
    if (request.extraFields != null) {
      queryParams.addAll(request.extraFields!);
    }

    try {
      return await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }
  }

  /// Initiates a withdrawal with asset conversion between non-equivalent tokens.
  ///
  /// Used when the anchor supports SEP-38 quotes and the user wants to withdraw one
  /// asset type from Stellar and receive a different asset type off-chain. For example,
  /// sending USDC from Stellar and receiving NGN in a bank account.
  ///
  /// Parameters:
  /// - [request] Withdrawal exchange request with source asset, destination asset, and amount
  ///
  /// Returns: Withdrawal instructions for the cross-asset withdrawal
  ///
  /// Throws:
  /// - [CustomerInformationNeededException] if additional KYC information is required
  /// - [CustomerInformationStatusException] if KYC status needs to be checked
  /// - [AuthenticationRequiredException] if authentication is missing or invalid
  Future<WithdrawResponse> withdrawExchange(
      WithdrawExchangeRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'withdraw-exchange');

    _WithdrawRequestBuilder requestBuilder = _WithdrawRequestBuilder(
      httpClient,
      serverURI,
      httpRequestHeaders: this.httpRequestHeaders,
    );

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
    if (request.extraFields != null) {
      queryParams.addAll(request.extraFields!);
    }

    try {
      return await requestBuilder
          .forQueryParameters(queryParams)
          .execute(request.jwt);
    } on ErrorResponse catch (e) {
      if (e.code == 403) {
        _handleForbiddenResponse(e);
      }
      throw e;
    }
  }

  /// Handles HTTP 403 Forbidden responses by parsing error type and throwing appropriate exception.
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

  /// Retrieves the fee structure for deposit or withdrawal operations.
  ///
  /// This endpoint allows wallets to query the fee that would be charged for
  /// a given deposit or withdrawal operation before initiating it. Anchors can
  /// provide different fee structures based on the asset, operation type, and
  /// transaction amount.
  ///
  /// Parameters:
  /// - [request] A [FeeRequest] containing operation details including:
  ///   - operation: Either 'deposit' or 'withdraw'
  ///   - assetCode: The asset code for the transaction
  ///   - amount: The transaction amount
  ///   - type: Optional deposit/withdrawal type
  ///   - jwt: JWT token from SEP-10 authentication
  ///
  /// Returns:
  /// A [FeeResponse] containing the calculated fee amount.
  ///
  /// Example:
  /// ```dart
  /// final feeRequest = FeeRequest(
  ///   operation: 'withdraw',
  ///   assetCode: 'USD',
  ///   amount: 100,
  ///   jwt: authToken,
  /// );
  ///
  /// final feeResponse = await service.fee(feeRequest);
  /// print('Fee: ${feeResponse.fee} ${feeRequest.assetCode}');
  /// ```
  Future<FeeResponse> fee(FeeRequest request) async {
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

    FeeResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }

  /// Retrieves transaction history for an account with the anchor.
  ///
  /// Queries the /transactions endpoint to get the status of deposits and withdrawals
  /// while they process, as well as a history of past transactions. Only returns
  /// transactions that are deposits to or withdrawals from the anchor.
  ///
  /// Parameters:
  /// - [request] Transaction history request with account, asset code, and optional filters
  ///
  /// Returns: List of transactions with their current status and details
  Future<AnchorTransactionsResponse> transactions(
      AnchorTransactionsRequest request) async {
    Uri serverURI =
        Util.appendEndpointToUrl(_transferServiceAddress, 'transactions');

    _AnchorTransactionsRequestBuilder requestBuilder =
        _AnchorTransactionsRequestBuilder(
      httpClient,
      serverURI,
      httpRequestHeaders: this.httpRequestHeaders,
    );

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
      queryParams["lang"] = request.lang!;
    }

    AnchorTransactionsResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }

  /// Retrieves details for a specific transaction at the anchor.
  ///
  /// Queries the /transaction endpoint to get the current status and details of
  /// a specific deposit or withdrawal transaction. Can query by transaction ID,
  /// Stellar transaction ID, or external transaction ID.
  ///
  /// Parameters:
  /// - [request] Transaction query request with at least one identifier (id, stellarTransactionId, or externalTransactionId)
  ///
  /// Returns: Current status and details of the requested transaction
  Future<AnchorTransactionResponse> transaction(
      AnchorTransactionRequest request) async {
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
    AnchorTransactionResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt);

    return response;
  }

  /// Updates transaction information with additional fields requested by the anchor.
  ///
  /// This endpoint allows clients to update a transaction with additional information
  /// that the anchor has requested. This is typically used when the anchor needs
  /// extra details about the transaction after it has been initiated, such as
  /// additional KYC information or transaction-specific details.
  ///
  /// Parameters:
  /// - [request] A [PatchTransactionRequest] containing:
  ///   - id: The transaction ID to update
  ///   - fields: Map of field names to values being updated
  ///   - jwt: JWT token from SEP-10 authentication
  ///
  /// Returns:
  /// An HTTP response indicating success or failure of the update.
  ///
  /// Throws:
  /// - [Exception] if request.fields is null
  ///
  /// Example:
  /// ```dart
  /// final patchRequest = PatchTransactionRequest(
  ///   id: 'transaction-id-123',
  ///   fields: {
  ///     'dest': 'GB123...',
  ///     'dest_extra': 'memo-value',
  ///   },
  ///   jwt: authToken,
  /// );
  ///
  /// final response = await service.patchTransaction(patchRequest);
  /// if (response.statusCode == 200) {
  ///   print('Transaction updated successfully');
  /// }
  /// ```
  Future<http.Response> patchTransaction(
      PatchTransactionRequest request) async {
    checkNotNull(request.fields, "request.fields cannot be null");
    Uri serverURI = Util.appendEndpointToUrl(
        _transferServiceAddress, 'transactions/${request.id}');

    _PatchTransactionRequestBuilder requestBuilder =
        _PatchTransactionRequestBuilder(httpClient, serverURI,
            httpRequestHeaders: this.httpRequestHeaders);

    http.Response response =
        await requestBuilder.forFields(request.fields!).execute(request.jwt);
    return response;
  }
}

/// Request parameters for initiating a deposit transaction.
///
/// A deposit occurs when a user sends an external asset (fiat via bank transfer,
/// crypto from another blockchain, etc.) to an anchor, and the anchor sends an
/// equivalent amount of the corresponding Stellar asset to the user's account.
///
/// This class encapsulates all parameters needed to initiate a deposit via the
/// SEP-0006 /deposit endpoint. At minimum, the asset code and destination Stellar
/// account must be provided. Additional parameters allow for specifying memo values,
/// deposit type, amount, KYC identifiers, and localization preferences.
///
/// Example:
/// ```dart
/// final request = DepositRequest(
///   assetCode: 'USD',
///   account: 'GXXXXXXX...',
///   type: 'bank_account',
///   amount: '100.00',
///   jwt: authToken,
/// );
///
/// final response = await service.deposit(request);
/// print('Deposit instructions: ${response.how}');
/// ```
///
/// See also:
/// - [DepositExchangeRequest] for deposits involving asset conversion
/// - [TransferServerService.deposit] method that uses this request
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

  /// (optional) can be used to provide extra fields for the request.
  /// E.g. required fields from the /info endpoint that are not covered by
  /// the standard parameters.
  Map<String, String>? extraFields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  /// Creates a DepositRequest with asset code, destination account, and optional parameters.
  ///
  /// Parameters:
  /// - [assetCode] The on-chain asset code the user wants to receive after depositing
  /// - [account] The Stellar or muxed account ID where the asset will be sent
  /// - [memoType] Optional memo type to attach to the Stellar payment (text, id, or hash)
  /// - [memo] Optional memo value to attach to the transaction
  /// - [emailAddress] Optional email address for deposit updates from the anchor
  /// - [type] Optional deposit method type (e.g., SEPA, SWIFT) if anchor supports multiple
  /// - [walletName] Optional wallet name for display (deprecated, use client_domain instead)
  /// - [walletUrl] Optional wallet URL for notifications (deprecated, use client_domain instead)
  /// - [lang] Optional language code for error messages (defaults to 'en')
  /// - [onChangeCallback] Optional URL where anchor should POST transaction status updates
  /// - [amount] Optional deposit amount to help anchor determine KYC requirements
  /// - [countryCode] Optional ISO 3166-1 alpha-3 country code of user's address
  /// - [claimableBalanceSupported] Optional flag indicating if client supports claimable balances
  /// - [customerId] Optional SEP-12 customer ID for off-chain account association
  /// - [locationId] Optional location ID for cash drop-off
  /// - [extraFields] Optional additional fields required by the anchor
  /// - [jwt] JWT token from SEP-10 authentication flow
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
      this.extraFields,
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

  /// Creates a DepositResponse with deposit instructions, ID, fees, amount limits, and metadata.
  ///
  /// Parameters:
  /// - [how] Deprecated terse instructions for how to deposit the asset
  /// - [id] The anchor's transaction ID for tracking deposit status
  /// - [eta] Estimated time in seconds until deposit is credited
  /// - [minAmount] Minimum deposit amount accepted by the anchor
  /// - [maxAmount] Maximum deposit amount accepted by the anchor
  /// - [feeFixed] Fixed fee amount in units of the deposited asset
  /// - [feePercent] Percentage fee in percentage points
  /// - [extraInfo] Additional information about the deposit process
  /// - [instructions] Map of SEP-9 financial account fields to deposit instructions
  DepositResponse(this.how, this.id, this.eta, this.minAmount, this.maxAmount,
      this.feeFixed, this.feePercent, this.extraInfo, this.instructions);

  /// Constructs a DepositResponse from JSON returned by deposit or deposit-exchange endpoint.
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

/// Instructions for completing an off-chain deposit.
///
/// Provides specific details about how to complete a deposit, typically
/// containing account numbers, routing codes, or other payment identifiers
/// needed to send funds to the anchor.
///
/// See also:
/// - [DepositResponse] which contains a map of these instructions
class DepositInstruction {
  /// The value of the field.
  String value;

  /// A human-readable description of the field. This can be used by an anchor
  /// to provide any additional information about fields that are not defined
  /// in the SEP-9 standard.
  String description;

  /// Creates a deposit instruction with value and description.
  ///
  /// Parameters:
  /// - [value] The actual value for this deposit instruction field
  /// - [description] Human-readable description of what this field represents
  DepositInstruction(this.value, this.description);

  /// Creates a DepositInstruction from JSON returned by the anchor.
  factory DepositInstruction.fromJson(Map<String, dynamic> json) =>
      DepositInstruction(json['value'], json['description']);
}

/// Additional information from the anchor.
///
/// Contains optional messages or additional details that an anchor wants to
/// communicate to the user about their transaction.
///
/// See also:
/// - [DepositResponse], [WithdrawResponse] which may include extra info
class ExtraInfo extends Response {
  String? message;

  /// Creates ExtraInfo with an optional message from the anchor.
  ExtraInfo(this.message);

  /// Constructs ExtraInfo from JSON returned by deposit or withdraw response.
  factory ExtraInfo.fromJson(Map<String, dynamic> json) =>
      ExtraInfo(json['message']);
}

// Requests the deposit data.
class _DepositRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _DepositRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets query parameters for the deposit request.
  _DepositRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes deposit request with optional JWT authentication.
  static Future<DepositResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<DepositResponse> type = TypeToken<DepositResponse>();
    ResponseHandler<DepositResponse> responseHandler =
        ResponseHandler<DepositResponse>(type);

    final Map<String, String> depositHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };

    return await httpClient.get(uri, headers: depositHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Executes the deposit request using configured parameters and authentication.
  Future<DepositResponse> execute(String? jwt) {
    return _DepositRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Response indicating additional customer information is needed.
///
/// When an anchor needs more KYC information before processing a transaction,
/// this response specifies which fields must be provided via SEP-12.
///
/// See also:
/// - [CustomerInformationNeededException] which wraps this response
/// - SEP-12 for the customer information protocol
class CustomerInformationNeededResponse {
  /// A list of field names that need to be transmitted via
  /// SEP-12 for the deposit to proceed.
  List<String>? fields;

  /// Creates a CustomerInformationNeededResponse with required field names.
  CustomerInformationNeededResponse(this.fields);

  /// Constructs a CustomerInformationNeededResponse from JSON error response.
  factory CustomerInformationNeededResponse.fromJson(
          Map<String, dynamic> json) =>
      CustomerInformationNeededResponse(
          json['fields'] == null ? null : List<String>.from(json['fields']));
}

/// Exception thrown when the anchor requires additional customer information.
///
/// This exception is thrown when a deposit or withdrawal request requires
/// additional KYC fields to be submitted via SEP-12 before the transaction
/// can proceed.
///
/// See also:
/// - [CustomerInformationNeededResponse] for the details
/// - SEP-12 for submitting the required customer information
class CustomerInformationNeededException implements Exception {
  CustomerInformationNeededResponse _response;

  /// Creates a CustomerInformationNeededException with the response detailing required fields.
  CustomerInformationNeededException(this._response);

  /// Returns error message describing the required customer information fields.
  String toString() {
    List<String> fields = _response.fields!;
    return "The anchor needs more information about the customer and all the information can be received non-interactively via SEP-12. Fields: $fields";
  }

  CustomerInformationNeededResponse get response => _response;
}

/// Response indicating the status of customer information processing.
///
/// When customer information has been submitted but is still being reviewed
/// or has been rejected, this response provides the current status and
/// additional details.
///
/// See also:
/// - [CustomerInformationStatusException] which wraps this response
/// - SEP-12 for the customer information protocol
class CustomerInformationStatusResponse {
  /// Status of customer information processing. One of: pending, denied.
  String? status;

  /// (optional) A URL the user can visit if they want more information
  /// about their account / status.
  String? moreInfoUrl;

  /// (optional) Estimated number of seconds until the customer information
  /// status will update.
  int? eta;

  /// Creates a CustomerInformationStatusResponse with status, more info URL, and ETA.
  CustomerInformationStatusResponse(this.status, this.moreInfoUrl, this.eta);

  /// Constructs a CustomerInformationStatusResponse from JSON error response.
  factory CustomerInformationStatusResponse.fromJson(
          Map<String, dynamic> json) =>
      CustomerInformationStatusResponse(
          json['status'], json['more_info_url'], convertInt(json['eta']));
}

/// Exception thrown when customer information is pending or denied.
///
/// This exception indicates that customer information has been submitted but
/// is either still being processed (status: pending) or was not accepted
/// (status: denied).
///
/// See also:
/// - [CustomerInformationStatusResponse] for the status details
/// - SEP-12 for the customer information protocol
class CustomerInformationStatusException implements Exception {
  CustomerInformationStatusResponse _response;

  /// Creates a CustomerInformationStatusException with the response containing status details.
  CustomerInformationStatusException(this._response);

  /// Returns error message describing the customer information status and details.
  String toString() {
    String? status = _response.status;
    String? moreInfoUrl = _response.moreInfoUrl;
    int? eta = _response.eta;
    return "Customer information was submitted for the account, but the information is either still being processed or was not accepted. Status: $status - More info url: $moreInfoUrl - Eta: $eta";
  }

  CustomerInformationStatusResponse get response => _response;
}

/// Exception thrown when an endpoint requires authentication.
///
/// This exception indicates that the requested operation requires SEP-10
/// authentication but no valid JWT token was provided or the provided token
/// was invalid or expired.
///
/// See also:
/// - SEP-10 for the authentication protocol
class AuthenticationRequiredException implements Exception {
  /// Returns error message indicating authentication is required.
  String toString() {
    return "The endpoint requires authentication.";
  }
}

/// Request parameters for initiating a deposit with asset conversion.
///
/// A deposit exchange allows a user to send an off-chain asset to an anchor
/// and receive a different Stellar asset in return. For example, a user could
/// deposit EUR via bank transfer and receive USDC on Stellar. This leverages
/// SEP-38 quotes for the conversion rate.
///
/// This request requires coordination with SEP-38 for obtaining quotes. The
/// conversion rate is locked in via the quoteId parameter, ensuring the user
/// gets the agreed-upon rate if they complete the deposit before the quote expires.
///
/// Example:
/// ```dart
/// // First get a quote from SEP-38
/// final quote = await sep38Service.postQuote(...);
///
/// // Then initiate deposit with the quote
/// final request = DepositExchangeRequest(
///   destinationAsset: 'USDC:GXXXXXXX...',
///   sourceAsset: 'iso4217:EUR',
///   amount: '100.00',
///   account: 'GXXXXXXX...',
///   quoteId: quote.id,
///   jwt: authToken,
/// );
///
/// final response = await service.depositExchange(request);
/// ```
///
/// See also:
/// - [DepositRequest] for simple deposits without conversion
/// - SEP-38 Quote API for obtaining conversion quotes
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

  /// (optional) can be used to provide extra fields for the request.
  /// E.g. required fields from the /info endpoint that are not covered by
  /// the standard parameters.
  Map<String, String>? extraFields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  /// Creates a DepositExchangeRequest with source and destination assets, amount, account, and optional parameters.
  ///
  /// Parameters:
  /// - [destinationAsset] The on-chain asset code to receive after deposit and conversion
  /// - [sourceAsset] The off-chain asset to deposit (SEP-38 Asset Identification Format)
  /// - [amount] The amount of source asset to deposit
  /// - [account] The Stellar or muxed account ID where the destination asset will be sent
  /// - [quoteId] Optional SEP-38 quote ID to lock in the conversion rate
  /// - [memoType] Optional memo type to attach to the Stellar payment (text, id, or hash)
  /// - [memo] Optional memo value to attach to the transaction
  /// - [emailAddress] Optional email address for deposit updates from the anchor
  /// - [type] Optional deposit method type if anchor supports multiple methods
  /// - [walletName] Optional wallet name for display (deprecated)
  /// - [walletUrl] Optional wallet URL for notifications (deprecated)
  /// - [lang] Optional language code for error messages
  /// - [onChangeCallback] Optional URL where anchor should POST transaction status updates
  /// - [countryCode] Optional ISO 3166-1 alpha-3 country code of user's address
  /// - [claimableBalanceSupported] Optional flag indicating if client supports claimable balances
  /// - [customerId] Optional SEP-12 customer ID for off-chain account association
  /// - [locationId] Optional location ID for cash drop-off
  /// - [extraFields] Optional additional fields required by the anchor
  /// - [jwt] JWT token from SEP-10 authentication flow
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
      this.extraFields,
      this.jwt});
}

/// Request parameters for initiating a withdrawal transaction.
///
/// A withdrawal occurs when a user sends a Stellar asset to an anchor's account,
/// and the anchor delivers the equivalent amount in an off-chain asset (fiat to
/// bank account, crypto to external blockchain, cash pickup, etc.).
///
/// This class encapsulates all parameters needed to initiate a withdrawal via
/// the SEP-0006 /withdraw endpoint. At minimum, the asset code and withdrawal
/// type must be provided. Additional parameters specify destination details,
/// refund information, and transaction preferences.
///
/// Example:
/// ```dart
/// final request = WithdrawRequest(
///   assetCode: 'USD',
///   type: 'bank_account',
///   dest: '12345678',
///   destExtra: '987654321',  // routing number
///   amount: '100.00',
///   jwt: authToken,
/// );
///
/// final response = await service.withdraw(request);
/// print('Send ${response.amount} to account: ${response.accountId}');
/// ```
///
/// See also:
/// - [WithdrawExchangeRequest] for withdrawals involving asset conversion
/// - [TransferServerService.withdraw] method that uses this request
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

  /// (optional) can be used to provide extra fields for the request.
  /// E.g. required fields from the /info endpoint that are not covered by
  /// the standard parameters.
  Map<String, String>? extraFields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  /// Creates a WithdrawRequest with asset code, withdrawal type, and optional parameters.
  ///
  /// Parameters:
  /// - [assetCode] The on-chain asset code to withdraw from Stellar
  /// - [type] Withdrawal method type (crypto, bank_account, cash, mobile, bill_payment, etc.)
  /// - [dest] Optional destination account (crypto address, bank account, IBAN, mobile, email)
  /// - [destExtra] Optional extra withdrawal location info (memo, routing number, BIC, etc.)
  /// - [account] Optional Stellar or muxed account to use as the withdrawal source
  /// - [memo] Optional memo value for the Stellar transaction
  /// - [memoType] Optional memo type (text, id, or hash)
  /// - [walletName] Optional wallet name for display (deprecated)
  /// - [walletUrl] Optional wallet URL for notifications (deprecated)
  /// - [lang] Optional language code for error messages
  /// - [onChangeCallback] Optional URL where anchor should POST transaction status updates
  /// - [amount] Optional withdrawal amount to help anchor determine KYC requirements
  /// - [countryCode] Optional ISO 3166-1 alpha-3 country code for KYC
  /// - [refundMemo] Optional memo for refund payments if withdrawal fails
  /// - [refundMemoType] Optional memo type for refund (id, text, or hash)
  /// - [customerId] Optional SEP-12 customer ID for off-chain account association
  /// - [locationId] Optional location ID for cash pickup
  /// - [extraFields] Optional additional fields required by the anchor
  /// - [jwt] JWT token from SEP-10 authentication flow
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
      this.extraFields,
      this.jwt});
}

/// Request parameters for initiating a withdrawal with asset conversion.
///
/// A withdrawal exchange allows a user to send a Stellar asset to an anchor
/// and receive a different off-chain asset in return. For example, a user could
/// send USDC on Stellar and receive EUR in their bank account. This leverages
/// SEP-38 quotes for the conversion rate.
///
/// This request type combines withdrawal with currency conversion, requiring
/// coordination with SEP-38 for obtaining quotes. The conversion rate is locked
/// in via the quoteId parameter, ensuring the user gets the agreed-upon rate if
/// they complete the withdrawal before the quote expires.
///
/// Example:
/// ```dart
/// // First get a quote from SEP-38
/// final quote = await sep38Service.postQuote(...);
///
/// // Then initiate withdrawal with the quote
/// final request = WithdrawExchangeRequest(
///   sourceAsset: 'USDC:GXXXXXXX...',
///   destinationAsset: 'iso4217:EUR',
///   amount: '100.00',
///   type: 'bank_account',
///   quoteId: quote.id,
///   jwt: authToken,
/// );
///
/// final response = await service.withdrawExchange(request);
/// ```
///
/// See also:
/// - [WithdrawRequest] for simple withdrawals without conversion
/// - SEP-38 Quote API for obtaining conversion quotes
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

  /// (optional) can be used to provide extra fields for the request.
  /// E.g. required fields from the /info endpoint that are not covered by
  /// the standard parameters.
  Map<String, String>? extraFields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  /// Creates a WithdrawExchangeRequest with source and destination assets, amount, type, and optional parameters.
  ///
  /// Parameters:
  /// - [sourceAsset] The on-chain asset code to withdraw and convert from Stellar
  /// - [destinationAsset] The off-chain asset to deliver (SEP-38 Asset Identification Format)
  /// - [amount] The amount of source asset to withdraw
  /// - [type] Withdrawal method type (crypto, bank_account, cash, mobile, bill_payment, etc.)
  /// - [dest] Optional destination account (crypto address, bank account, IBAN, etc.)
  /// - [destExtra] Optional extra withdrawal location info (memo, routing number, BIC, etc.)
  /// - [quoteId] Optional SEP-38 quote ID to lock in the conversion rate
  /// - [account] Optional Stellar or muxed account to use as the withdrawal source
  /// - [memo] Optional memo value for the Stellar transaction
  /// - [memoType] Optional memo type (text, id, or hash)
  /// - [walletName] Optional wallet name for display (deprecated)
  /// - [walletUrl] Optional wallet URL for notifications (deprecated)
  /// - [lang] Optional language code for error messages
  /// - [onChangeCallback] Optional URL where anchor should POST transaction status updates
  /// - [countryCode] Optional ISO 3166-1 alpha-3 country code for KYC
  /// - [claimableBalanceSupported] Optional flag indicating if client supports claimable balances
  /// - [refundMemo] Optional memo for refund payments if withdrawal fails
  /// - [refundMemoType] Optional memo type for refund (id, text, or hash)
  /// - [customerId] Optional SEP-12 customer ID for off-chain account association
  /// - [locationId] Optional location ID for cash pickup
  /// - [extraFields] Optional additional fields required by the anchor
  /// - [jwt] JWT token from SEP-10 authentication flow
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
      this.extraFields,
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

  /// Creates a WithdrawResponse with account details, memo, fee information, and optional extra info.
  ///
  /// Parameters:
  /// - [accountId] The Stellar account to send the asset to for withdrawal
  /// - [memoType] Type of memo to attach to the transaction (text, id, or hash)
  /// - [memo] Value of memo to attach to the transaction
  /// - [id] The anchor's transaction ID for tracking withdrawal status
  /// - [eta] Estimated time in seconds until withdrawal is processed
  /// - [minAmount] Minimum withdrawal amount accepted by the anchor
  /// - [maxAmount] Maximum withdrawal amount accepted by the anchor
  /// - [feeFixed] Fixed fee amount in units of the withdrawn asset
  /// - [feePercent] Percentage fee in percentage points
  /// - [extraInfo] Additional data needed for the withdrawal (e.g., bank name)
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

  /// Constructs a WithdrawResponse from JSON returned by transfer server.
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
  Map<String, String>? httpRequestHeaders;

  _WithdrawRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets query parameters for the withdrawal request.
  _WithdrawRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes withdrawal request with optional JWT authentication.
  static Future<WithdrawResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<WithdrawResponse> type = TypeToken<WithdrawResponse>();
    ResponseHandler<WithdrawResponse> responseHandler =
        ResponseHandler<WithdrawResponse>(type);

    final Map<String, String> withdrawHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    return await httpClient.get(uri, headers: withdrawHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Executes the withdrawal request using configured parameters and authentication.
  Future<WithdrawResponse> execute(String? jwt) {
    return _WithdrawRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Describes a field that needs to be provided for a transaction.
///
/// Anchors use this to specify additional fields required for deposits or
/// withdrawals beyond the standard parameters. Each field includes a
/// description and whether it's optional.
///
/// See also:
/// - [DepositAsset], [WithdrawAsset] which contain maps of required fields
class AnchorField {
  /// description of field to show to user.
  String? description;

  /// if field is optional. Defaults to false.
  bool? optional;

  /// list of possible values for the field.
  List<String>? choices;

  /// Creates a field definition for anchor deposit/withdrawal forms.
  ///
  /// Parameters:
  /// - [description] Description of field to show to user
  /// - [optional] Whether the field is optional (defaults to false if null)
  /// - [choices] List of possible values for the field (null if free-form input)
  AnchorField(this.description, this.optional, this.choices);

  /// Creates an AnchorField from JSON returned by the anchor.
  factory AnchorField.fromJson(Map<String, dynamic> json) => AnchorField(
      json['description'],
      json['optional'],
      json['choices'] == null ? null : List<String>.from(json['choices']));
}

/// Configuration for a deposit asset supported by the anchor.
///
/// Contains all the details about how deposits work for a specific asset,
/// including whether it's enabled, authentication requirements, fee structure,
/// transaction limits, and any additional fields required.
///
/// See also:
/// - [InfoResponse] which contains a map of these for all supported assets
/// - [DepositRequest] for initiating a deposit
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

  /// Creates a deposit asset configuration for SEP-6 transfer operations.
  ///
  /// Parameters:
  /// - [enabled] Whether SEP-6 deposits are supported for this asset
  /// - [authenticationRequired] Whether client must authenticate before deposits
  /// - [feeFixed] Fixed flat fee for deposits in units of the Stellar asset
  /// - [feePercent] Percentage fee for deposits in percentage points
  /// - [minAmount] Minimum deposit amount accepted by the anchor
  /// - [maxAmount] Maximum deposit amount accepted by the anchor
  /// - [fields] Custom fields required for the deposit transaction
  ///
  /// Specifies the capabilities and constraints for depositing this asset through the anchor.
  DepositAsset(this.enabled, this.authenticationRequired, this.feeFixed,
      this.feePercent, this.minAmount, this.maxAmount, this.fields);

  /// Creates a DepositAsset from JSON returned by the anchor's /info endpoint.
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

/// Configuration for a deposit-exchange asset supported by the anchor.
///
/// This class represents assets that can be deposited with simultaneous conversion
/// to another asset on the Stellar network. Unlike standard [DepositAsset], this
/// is used when the anchor supports deposit operations that include asset exchange
/// as part of the transaction flow.
///
/// Used in SEP-38 quote-assisted deposit operations where users deposit one asset
/// (e.g., USD) and receive a different asset (e.g., USDC) on Stellar.
///
/// See also:
/// - [InfoResponse.depositExchangeAssets] which contains a map of these assets
/// - [DepositAsset] for standard deposit configuration without exchange
/// - [WithdrawExchangeAsset] for withdraw-exchange configuration
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

  /// Creates a deposit-exchange asset configuration for SEP-6 and SEP-38 operations.
  ///
  /// Parameters:
  /// - [enabled] Whether SEP-6 deposit-exchange is supported for this asset
  /// - [authenticationRequired] Whether client must authenticate before deposit-exchange
  /// - [fields] Custom fields required for the deposit-exchange transaction
  ///
  /// Specifies capabilities for deposits that include asset conversion through quotes.
  DepositExchangeAsset(this.enabled, this.authenticationRequired, this.fields);

  /// Creates a DepositExchangeAsset from JSON returned by the anchor's /info endpoint.
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

/// Configuration for a withdrawal asset supported by the anchor.
///
/// Contains all the details about how withdrawals work for a specific asset,
/// including whether it's enabled, authentication requirements, fee structure,
/// transaction limits, and supported withdrawal types with their required fields.
///
/// See also:
/// - [InfoResponse] which contains a map of these for all supported assets
/// - [WithdrawRequest] for initiating a withdrawal
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

  /// Creates a withdrawal asset configuration for SEP-6 transfer operations.
  ///
  /// Parameters:
  /// - [enabled] Whether SEP-6 withdrawals are supported for this asset
  /// - [authenticationRequired] Whether client must authenticate before withdrawals
  /// - [feeFixed] Fixed flat fee for withdrawals in units of the Stellar asset
  /// - [feePercent] Percentage fee for withdrawals in percentage points
  /// - [minAmount] Minimum withdrawal amount accepted by the anchor
  /// - [maxAmount] Maximum withdrawal amount accepted by the anchor
  /// - [types] Map of supported withdrawal types with their required fields
  ///
  /// Specifies the capabilities, constraints, and supported withdrawal types for this asset.
  WithdrawAsset(this.enabled, this.authenticationRequired, this.feeFixed,
      this.feePercent, this.minAmount, this.maxAmount, this.types);

  /// Creates a WithdrawAsset from JSON returned by the anchor's /info endpoint.
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

/// Configuration for a withdrawal-exchange asset supported by the anchor.
///
/// This class represents assets that can be withdrawn with simultaneous conversion
/// from another asset on the Stellar network. Unlike standard [WithdrawAsset], this
/// is used when the anchor supports withdrawal operations that include asset exchange
/// as part of the transaction flow.
///
/// Used in SEP-38 quote-assisted withdrawal operations where users send one asset
/// (e.g., USDC) on Stellar and receive a different asset (e.g., USD) off-chain.
///
/// See also:
/// - [InfoResponse.withdrawExchangeAssets] which contains a map of these assets
/// - [WithdrawAsset] for standard withdrawal configuration without exchange
/// - [DepositExchangeAsset] for deposit-exchange configuration
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

  /// Creates a withdrawal-exchange asset configuration for SEP-6 and SEP-38 operations.
  ///
  /// Parameters:
  /// - [enabled] Whether SEP-6 withdrawal-exchange is supported for this asset
  /// - [authenticationRequired] Whether client must authenticate before withdrawal-exchange
  /// - [types] Map of supported withdrawal types with their required fields
  ///
  /// Specifies capabilities for withdrawals that include asset conversion through quotes.
  WithdrawExchangeAsset(this.enabled, this.authenticationRequired, this.types);

  /// Creates a WithdrawExchangeAsset from JSON returned by the anchor's /info endpoint.
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

/// Configuration for the anchor's fee endpoint availability.
///
/// Indicates whether the anchor provides a dedicated /fee endpoint for querying
/// transaction fees dynamically. If disabled, fee information must be obtained
/// from the fixed and percentage values in [DepositAsset] or [WithdrawAsset],
/// or fees may vary and cannot be determined in advance.
///
/// Returned as part of [InfoResponse.feeInfo] from the /info endpoint.
///
/// See also:
/// - [TransferServerService.fee] for querying dynamic fees when enabled
/// - [InfoResponse] which contains this fee endpoint configuration
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

  /// Creates fee endpoint configuration for SEP-6 transfer operations.
  ///
  /// Parameters:
  /// - [enabled] Whether the /fee endpoint is available
  /// - [authenticationRequired] Whether client must authenticate before accessing the endpoint
  /// - [description] Explanation of how fees are calculated for display to users
  AnchorFeeInfo(this.enabled, this.authenticationRequired, this.description);

  /// Creates an AnchorFeeInfo from JSON returned by the anchor's /info endpoint.
  factory AnchorFeeInfo.fromJson(Map<String, dynamic> json) => AnchorFeeInfo(
      json['enabled'], json['authentication_required'], json['description']);
}

/// Configuration for the anchor's single transaction query endpoint.
///
/// Indicates whether the anchor provides the /transaction endpoint for querying
/// details about a specific transaction by ID. This endpoint is used to poll
/// transaction status and retrieve updated information as the transaction progresses.
///
/// Returned as part of [InfoResponse.transactionInfo] from the /info endpoint.
///
/// See also:
/// - [TransferServerService.transaction] for querying a specific transaction
/// - [AnchorTransactionResponse] which is returned by the transaction endpoint
/// - [AnchorTransactionsInfo] for the multi-transaction query endpoint configuration
class AnchorTransactionInfo {
  /// true if the endpoint is available.
  bool? enabled;

  /// true if client must be authenticated before accessing the endpoint.
  bool? authenticationRequired;

  /// Creates a configuration for the anchor's single transaction query endpoint.
  ///
  /// Parameters:
  /// - [enabled] Whether the /transaction endpoint is available
  /// - [authenticationRequired] Whether client must authenticate before accessing this endpoint
  ///
  /// Indicates availability and authentication requirements for the /transaction endpoint.
  AnchorTransactionInfo(this.enabled, this.authenticationRequired);

  /// Creates an AnchorTransactionInfo from JSON returned by the anchor's /info endpoint.
  factory AnchorTransactionInfo.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionInfo(json['enabled'], json['authentication_required']);
}

/// Configuration for the anchor's transaction history endpoint.
///
/// Indicates whether the anchor provides the /transactions endpoint for querying
/// a list of transactions with filtering and pagination. This endpoint allows
/// retrieving transaction history for an authenticated user account.
///
/// Returned as part of [InfoResponse.transactionsInfo] from the /info endpoint.
///
/// See also:
/// - [TransferServerService.transactions] for querying transaction history
/// - [AnchorTransactionsResponse] which is returned by the transactions endpoint
/// - [AnchorTransactionInfo] for the single transaction query endpoint configuration
class AnchorTransactionsInfo {
  /// true if the endpoint is available.
  bool? enabled;

  /// true if client must be authenticated before accessing the endpoint.
  bool? authenticationRequired;

  /// Creates a configuration for the anchor's transaction history endpoint.
  ///
  /// Parameters:
  /// - [enabled] Whether the /transactions endpoint is available
  /// - [authenticationRequired] Whether client must authenticate before accessing this endpoint
  ///
  /// Indicates availability and authentication requirements for the /transactions endpoint.
  AnchorTransactionsInfo(this.enabled, this.authenticationRequired);

  /// Creates an AnchorTransactionsInfo from JSON returned by the anchor's /info endpoint.
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

  /// Creates feature flags indicating anchor capabilities for SEP-6 operations.
  ///
  /// Parameters:
  /// - [accountCreation] Whether anchor supports creating accounts for deposit users (defaults to true)
  /// - [claimableBalances] Whether anchor supports sending deposits as claimable balances (defaults to false)
  AnchorFeatureFlags(this.accountCreation, this.claimableBalances);

  /// Creates an AnchorFeatureFlags from JSON returned by the anchor's /info endpoint.
  factory AnchorFeatureFlags.fromJson(Map<String, dynamic> json) {
    bool? accCreation = json['account_creation'];
    bool? claimableB = json['claimable_balances'];
    return AnchorFeatureFlags(accCreation != null ? accCreation : true,
        claimableB != null ? claimableB : false);
  }
}

/// Response containing anchor capabilities and supported operations.
///
/// This response provides comprehensive information about what deposit and
/// withdrawal operations an anchor supports, including supported assets, fee
/// structures, transaction endpoints, and feature flags. It's the primary
/// discovery mechanism for clients to understand an anchor's capabilities.
///
/// The response includes separate maps for:
/// - Standard deposits (depositAssets)
/// - Deposit with conversion (depositExchangeAssets)
/// - Standard withdrawals (withdrawAssets)
/// - Withdrawal with conversion (withdrawExchangeAssets)
///
/// Each asset entry contains details about supported methods, fees, limits,
/// and required fields for that specific operation.
///
/// Example:
/// ```dart
/// final info = await service.info(jwt: authToken);
///
/// // Check if USD deposits are supported
/// if (info.depositAssets?.containsKey('USD') ?? false) {
///   final usdDeposit = info.depositAssets!['USD']!;
///   print('Min amount: ${usdDeposit.minAmount}');
///   print('Max amount: ${usdDeposit.maxAmount}');
///   print('Enabled: ${usdDeposit.enabled}');
/// }
///
/// // Check feature flags
/// print('Account creation: ${info.featureFlags?.accountCreation}');
/// print('Claimable balances: ${info.featureFlags?.claimableBalances}');
/// ```
///
/// See also:
/// - [TransferServerService.info] method that returns this response
/// - [DepositAsset], [WithdrawAsset] for asset-specific details
class InfoResponse extends Response {
  Map<String, DepositAsset>? depositAssets;
  Map<String, DepositExchangeAsset>? depositExchangeAssets;
  Map<String, WithdrawAsset>? withdrawAssets;
  Map<String, WithdrawExchangeAsset>? withdrawExchangeAssets;
  AnchorFeeInfo? feeInfo;
  AnchorTransactionsInfo? transactionsInfo;
  AnchorTransactionInfo? transactionInfo;
  AnchorFeatureFlags? featureFlags;

  /// Creates an anchor capabilities response for SEP-6 transfer operations.
  ///
  /// Parameters:
  /// - [depositAssets] Map of assets supporting standard deposits with their configurations
  /// - [depositExchangeAssets] Map of assets supporting deposits with conversion
  /// - [withdrawAssets] Map of assets supporting standard withdrawals with their configurations
  /// - [withdrawExchangeAssets] Map of assets supporting withdrawals with conversion
  /// - [feeInfo] Configuration for the /fee endpoint
  /// - [transactionsInfo] Configuration for the /transactions endpoint
  /// - [transactionInfo] Configuration for the /transaction endpoint
  /// - [featureFlags] Flags indicating supported anchor features
  InfoResponse(
      this.depositAssets,
      this.depositExchangeAssets,
      this.withdrawAssets,
      this.withdrawExchangeAssets,
      this.feeInfo,
      this.transactionsInfo,
      this.transactionInfo,
      this.featureFlags);

  /// Creates an InfoResponse from JSON returned by the anchor's /info endpoint.
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
  Map<String, String>? httpRequestHeaders;

  _InfoRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets query parameters for the info request.
  _InfoRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes info request with optional JWT authentication.
  static Future<InfoResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<InfoResponse> type = TypeToken<InfoResponse>();
    ResponseHandler<InfoResponse> responseHandler =
        ResponseHandler<InfoResponse>(type);

    final Map<String, String> infoHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    return await httpClient.get(uri, headers: infoHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Executes the info request using configured parameters and authentication.
  Future<InfoResponse> execute(String? jwt) {
    return _InfoRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request parameters for querying transaction fees.
///
/// This class encapsulates the parameters needed to query the fee that an anchor
/// would charge for a specific deposit or withdrawal operation. Fees can vary
/// based on the operation type, asset, amount, and specific transaction method
/// (e.g., SEPA vs SWIFT for bank transfers).
///
/// The fee endpoint helps wallets display accurate fee information to users before
/// they initiate a transaction, allowing users to make informed decisions.
///
/// Example:
/// ```dart
/// final feeRequest = FeeRequest(
///   operation: 'withdraw',
///   assetCode: 'USD',
///   amount: 500.00,
///   type: 'bank_account',
///   jwt: authToken,
/// );
///
/// final feeResponse = await service.fee(feeRequest);
/// print('Transaction fee: ${feeResponse.fee} USD');
/// ```
///
/// See also:
/// - [FeeResponse] for the response structure
/// - [TransferServerService.fee] method that uses this request
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

  /// Creates a FeeRequest with operation type, asset code, amount, optional type, and JWT.
  ///
  /// Parameters:
  /// - [operation] The operation type to query fees for (deposit or withdraw)
  /// - [assetCode] The Stellar asset code for the fee query
  /// - [amount] The amount that will be deposited or withdrawn
  /// - [type] Optional deposit or withdrawal type (SEPA, bank_account, cash, etc.)
  /// - [jwt] JWT token from SEP-10 authentication flow
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

  /// Creates a fee response for SEP-6 deposit or withdrawal operations.
  ///
  /// Parameters:
  /// - [fee] The total fee in units of the asset that would be charged for the operation
  FeeResponse(this.fee);

  /// Creates a FeeResponse from JSON returned by the anchor's /fee endpoint.
  factory FeeResponse.fromJson(Map<String, dynamic> json) =>
      FeeResponse(convertDouble(json['fee'])!);
}

// Requests the fee data.
class _FeeRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _FeeRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets query parameters for the fee request.
  _FeeRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes fee request with optional JWT authentication.
  static Future<FeeResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<FeeResponse> type = TypeToken<FeeResponse>();
    ResponseHandler<FeeResponse> responseHandler =
        ResponseHandler<FeeResponse>(type);

    final Map<String, String> feeHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    return await httpClient.get(uri, headers: feeHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Executes the fee request using configured parameters and authentication.
  Future<FeeResponse> execute(String? jwt) {
    return _FeeRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request parameters for querying a list of transactions.
///
/// This class encapsulates parameters for retrieving a filtered and paginated
/// list of deposit and withdrawal transactions associated with a specific account
/// and asset. It supports filtering by date, transaction type, and includes
/// pagination options for handling large result sets.
///
/// The transactions endpoint helps wallets display transaction history and
/// monitor the status of ongoing deposits and withdrawals.
///
/// Example:
/// ```dart
/// final request = AnchorTransactionsRequest(
///   assetCode: 'USD',
///   account: 'GXXXXXXX...',
///   noOlderThan: DateTime.now().subtract(Duration(days: 30)),
///   limit: 10,
///   kind: 'deposit',
///   jwt: authToken,
/// );
///
/// final response = await service.transactions(request);
/// for (var tx in response.transactions) {
///   print('${tx.kind}: ${tx.status} - ${tx.amountIn}');
/// }
/// ```
///
/// See also:
/// - [AnchorTransactionsResponse] for the response structure
/// - [AnchorTransactionRequest] for querying a single transaction
/// - [TransferServerService.transactions] method that uses this request
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

  /// Creates a request for querying transaction history from the anchor.
  ///
  /// Parameters:
  /// - [assetCode] The asset code for which to retrieve transactions
  /// - [account] The Stellar account ID involved in the transactions
  /// - [noOlderThan] Only return transactions on or after this date
  /// - [limit] Maximum number of transactions to return
  /// - [kind] Filter by transaction kind (deposit, deposit-exchange, withdrawal, withdrawal-exchange)
  /// - [pagingId] Return transactions starting prior to this ID for pagination
  /// - [lang] Language code for error messages (defaults to 'en')
  /// - [jwt] JWT token from SEP-10 authentication
  ///
  /// Specify required asset code and account, with optional filtering and pagination parameters.
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

/// Detailed breakdown of fees applied to a transaction.
///
/// Provides comprehensive fee information including the total fee amount, the asset
/// in which the fee is charged, and optionally a detailed breakdown of individual
/// fee components that make up the total.
///
/// Used within [AnchorTransaction] to show users exactly what fees were applied
/// to their deposit or withdrawal transaction.
///
/// See also:
/// - [FeeDetailsDetails] for individual fee component breakdown
/// - [AnchorTransaction.feeDetails] which contains this fee information
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

  /// Creates fee details with total amount and breakdown for SEP-6 transactions.
  ///
  /// Parameters:
  /// - [total] The total amount of fee applied
  /// - [asset] The asset in which the fee is applied (Asset Identification Format)
  /// - [details] Optional breakdown of individual fee components used to calculate the total
  FeeDetails(this.total, this.asset, {this.details});

  /// Creates a FeeDetails from JSON returned by the anchor in transaction responses.
  factory FeeDetails.fromJson(Map<String, dynamic> json) =>
      FeeDetails(json['total'], json['asset'],
          details: json['details'] == null
              ? null
              : List<FeeDetailsDetails>.from(
                  json['details'].map((e) => FeeDetailsDetails.fromJson(e))));
}

/// Individual fee component within a transaction's fee breakdown.
///
/// Represents a single named fee that contributes to the total transaction fee.
/// Multiple fee components can be combined to show users a transparent breakdown
/// of all fees applied (e.g., network fees, processing fees, currency conversion fees).
///
/// The sum of all [amount] values in the fee components should equal the
/// [FeeDetails.total] amount.
///
/// See also:
/// - [FeeDetails.details] which contains a list of these fee components
class FeeDetailsDetails {
  /// The name of the fee, for example ACH fee, Brazilian conciliation fee,
  /// Service fee, etc.
  String name;

  /// The amount of asset applied. If fee_details.details is provided,
  /// sum(fee_details.details.amount) should be equals fee_details.total.
  String amount;

  /// (optional) A text describing the fee.
  String? description;

  /// Creates an individual fee component for transaction fee breakdown.
  ///
  /// Parameters:
  /// - [name] The name of the fee (e.g., "ACH fee", "Service fee", "Network fee")
  /// - [amount] The amount of this fee component in the transaction's fee asset
  /// - [description] Optional text describing what this fee covers
  FeeDetailsDetails(this.name, this.amount, {this.description});

  /// Creates a FeeDetailsDetails from JSON returned by the anchor in transaction fee breakdown.
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

  /// Creates a refund summary for a transaction.
  ///
  /// Parameters:
  /// - [amountRefunded] The total amount refunded to the user
  /// - [amountFee] The total fees charged for processing all refund payments
  /// - [payments] List of individual refund payment records
  ///
  /// Contains the total refunded amount, fees, and a list of individual refund payments.
  TransactionRefunds(this.amountRefunded, this.amountFee, this.payments);

  /// Creates a TransactionRefunds from JSON returned by the anchor in transaction responses.
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

  /// Creates a refund payment record for a transaction.
  ///
  /// Parameters:
  /// - [id] The payment identifier for this refund (Stellar hash or off-chain reference)
  /// - [idType] The type of ID (stellar or external)
  /// - [amount] The amount sent back to the user in this payment
  /// - [fee] The fee charged for processing this refund payment
  ///
  /// Represents a single refund payment made back to the user, identified by payment ID.
  TransactionRefundPayment(this.id, this.idType, this.amount, this.fee);

  /// Creates a TransactionRefundPayment from JSON returned by the anchor in refund details.
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

  /// Creates an AnchorTransaction with deposit or withdrawal transaction details.
  ///
  /// Parameters:
  /// - [id] Unique anchor-generated transaction identifier
  /// - [kind] Transaction type (deposit, deposit-exchange, withdrawal, withdrawal-exchange)
  /// - [status] Current processing status of the transaction
  /// - [statusEta] Estimated seconds until status change
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
      this.userActionRequiredBy,
      this.stellarTransactionId,
      this.externalTransactionId,
      this.message,
      this.refunded,
      this.refunds,
      this.requiredInfoMessage,
      this.requiredInfoUpdates,
      this.instructions,
      this.claimableBalanceId});

  /// Creates an AnchorTransaction from JSON returned by the anchor's /transaction or /transactions endpoint.
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
        userActionRequiredBy: json['user_action_required_by'],
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

/// Response from the GET /transactions endpoint containing transaction history.
///
/// Returns a list of transactions matching the query criteria (asset, account, etc.)
/// with pagination support. Used to retrieve transaction history for an authenticated
/// user, allowing them to track all their deposit and withdrawal operations with the anchor.
///
/// Returned by [TransferServerService.transactions] when querying transaction history.
///
/// See also:
/// - [AnchorTransaction] for individual transaction details
/// - [AnchorTransactionResponse] for single transaction queries
/// - [AnchorTransactionsInfo] for endpoint availability configuration
class AnchorTransactionsResponse extends Response {
  List<AnchorTransaction> transactions;

  /// Creates an AnchorTransactionsResponse with a list of anchor transactions.
  AnchorTransactionsResponse(this.transactions);

  /// Constructs an AnchorTransactionsResponse from JSON returned by transactions endpoint.
  factory AnchorTransactionsResponse.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionsResponse((json['transactions'] as List)
          .map((e) => AnchorTransaction.fromJson(e))
          .toList());
}

// Requests the transaction history data.
class _AnchorTransactionsRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _AnchorTransactionsRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets query parameters for the transactions request.
  _AnchorTransactionsRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes transactions request with optional JWT authentication.
  static Future<AnchorTransactionsResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<AnchorTransactionsResponse> type =
        TypeToken<AnchorTransactionsResponse>();
    ResponseHandler<AnchorTransactionsResponse> responseHandler =
        ResponseHandler<AnchorTransactionsResponse>(type);

    final Map<String, String> atHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Executes the transactions request using configured parameters and authentication.
  Future<AnchorTransactionsResponse> execute(String? jwt) {
    return _AnchorTransactionsRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request parameters for querying a specific transaction.
///
/// This class encapsulates parameters for retrieving detailed information about
/// a single transaction. The transaction can be identified using one of three
/// possible identifiers: the anchor's transaction ID, the Stellar transaction ID,
/// or an external transaction ID.
///
/// At least one identifier must be provided. If multiple identifiers are provided,
/// the anchor will use them to locate the transaction, typically prioritizing in
/// the order: id, stellar_transaction_id, external_transaction_id.
///
/// Example:
/// ```dart
/// final request = AnchorTransactionRequest(
///   id: 'anchor-tx-123',
///   lang: 'en',
///   jwt: authToken,
/// );
///
/// final response = await service.transaction(request);
/// print('Status: ${response.transaction.status}');
/// print('Amount: ${response.transaction.amountIn}');
/// ```
///
/// See also:
/// - [AnchorTransactionResponse] for the response structure
/// - [AnchorTransactionsRequest] for querying multiple transactions
/// - [TransferServerService.transaction] method that uses this request
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

  /// Creates a request to fetch specific transaction details from an anchor.
  ///
  /// Parameters:
  /// - [id] The anchor's transaction ID
  /// - [stellarTransactionId] The Stellar network transaction ID
  /// - [externalTransactionId] The external network transaction ID
  /// - [lang] Language code for error messages (defaults to 'en')
  /// - [jwt] JWT token from SEP-10 authentication
  AnchorTransactionRequest(
      {this.id,
      this.stellarTransactionId,
      this.externalTransactionId,
      this.lang,
      this.jwt});
}

/// Response from the GET /transaction endpoint for a specific transaction.
///
/// Returns detailed information about a single transaction identified by its ID,
/// stellar transaction ID, or external transaction ID. Used for polling transaction
/// status and retrieving updated details as the transaction progresses through
/// various states (pending, completed, error, etc.).
///
/// Returned by [TransferServerService.transaction] when querying a specific transaction.
///
/// See also:
/// - [AnchorTransaction] for the transaction details structure
/// - [AnchorTransactionsResponse] for querying multiple transactions
/// - [AnchorTransactionInfo] for endpoint availability configuration
class AnchorTransactionResponse extends Response {
  AnchorTransaction transaction;

  /// Creates an AnchorTransactionResponse with a single anchor transaction.
  AnchorTransactionResponse(this.transaction);

  /// Constructs an AnchorTransactionResponse from JSON returned by transaction endpoint.
  factory AnchorTransactionResponse.fromJson(Map<String, dynamic> json) =>
      AnchorTransactionResponse(
          AnchorTransaction.fromJson(json['transaction']));
}

// Requests the transaction data for a specific transaction.
class _AnchorTransactionRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _AnchorTransactionRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets query parameters for the transaction request.
  _AnchorTransactionRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes transaction request with optional JWT authentication.
  static Future<AnchorTransactionResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async{
    TypeToken<AnchorTransactionResponse> type =
        TypeToken<AnchorTransactionResponse>();
    ResponseHandler<AnchorTransactionResponse> responseHandler =
        ResponseHandler<AnchorTransactionResponse>(type);

    final Map<String, String> atHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    return await httpClient.get(uri, headers: atHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  /// Executes the transaction request using configured parameters and authentication.
  Future<AnchorTransactionResponse> execute(String? jwt) {
    return _AnchorTransactionRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request parameters for updating transaction information.
///
/// This class encapsulates parameters for updating a transaction with additional
/// fields that the anchor has requested. This is typically used when an anchor
/// needs supplementary information after a transaction has been initiated, such
/// as updated destination details or additional KYC data.
///
/// The fields map should contain the specific field names and values that the
/// anchor has indicated are needed. The anchor will specify which fields can be
/// updated based on the transaction's current state.
///
/// Example:
/// ```dart
/// final request = PatchTransactionRequest(
///   'transaction-id-123',
///   fields: {
///     'dest': 'GB123...',
///     'dest_extra': 'updated-memo',
///   },
///   jwt: authToken,
/// );
///
/// final response = await service.patchTransaction(request);
/// if (response.statusCode == 200) {
///   print('Transaction updated successfully');
/// }
/// ```
///
/// See also:
/// - [TransferServerService.patchTransaction] method that uses this request
/// - SEP-6 specification section on pending transaction info updates
class PatchTransactionRequest {
  /// Id of the transaction
  String id;

  /// An object containing the values requested to be updated by the anchor
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md#pending-transaction-info-update
  Map<String, dynamic>? fields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;

  /// Creates a request to update pending transaction information at the anchor.
  ///
  /// Parameters:
  /// - [id] The transaction ID to update
  /// - [fields] Map of field names to values being updated
  /// - [jwt] JWT token from SEP-10 authentication
  PatchTransactionRequest(this.id, {this.fields, this.jwt});
}

// Pending Transaction Info Update.
class _PatchTransactionRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;
  late Map<String, dynamic> _fields;

  _PatchTransactionRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets fields to update for the transaction patch request.
  _PatchTransactionRequestBuilder forFields(Map<String, dynamic> fields) {
    _fields = fields;
    return this;
  }

  /// Executes patch transaction request with optional JWT authentication.
  static Future<http.Response> requestExecute(
      http.Client httpClient, Uri uri, Map<String, dynamic> fields, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    final Map<String, String> atHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    return await httpClient.patch(uri,
        body: {"transaction": json.encode(fields)}, headers: atHeaders);
  }

  /// Executes the patch transaction request using configured fields and authentication.
  Future<http.Response> execute(String? jwt) {
    return _PatchTransactionRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}
