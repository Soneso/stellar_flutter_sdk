import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';
import '../0009/standard_kyc_fields.dart';

/// Implements SEP-0012 KYC (Know Your Customer) API for Stellar services.
///
/// SEP-0012 standardizes how anchors collect customer information for regulatory
/// compliance. This service allows wallets and clients to:
/// - Register customers with required KYC information
/// - Check KYC status and requirements
/// - Upload verification documents
/// - Update customer information
/// - Verify customer data (phone, email, etc.)
/// - Manage customer callbacks for status updates
///
/// The KYC process typically follows this workflow:
/// 1. Client authenticates with SEP-10 WebAuth to get a JWT token
/// 2. Client calls GET /customer to check what information is required
/// 3. Server responds with required fields based on customer status:
///    - ACCEPTED: Customer is approved, no action needed
///    - PROCESSING: Information is being reviewed
///    - NEEDS_INFO: More information is required (returns required fields)
///    - REJECTED: Customer was rejected (returns reason)
/// 4. Client submits information via PUT /customer
/// 5. Client may need to verify fields (email, phone) via PUT /customer/verification
/// 6. Process repeats until status is ACCEPTED or REJECTED
///
/// Customer statuses:
/// - ACCEPTED: Customer has been approved
/// - PROCESSING: Customer information is being reviewed
/// - NEEDS_INFO: More information is required
/// - REJECTED: Customer was rejected
///
/// Security considerations:
/// - All requests must be authenticated with a SEP-10 JWT token
/// - Customer data should be transmitted over HTTPS only
/// - Uploaded files (IDs, proofs) contain sensitive information
/// - Implement proper access controls and audit logging
/// - Handle customer data according to privacy regulations (GDPR, CCPA, etc.)
///
/// Example - Basic KYC flow:
/// ```dart
/// // 1. Initialize KYC service from domain
/// final kycService = await KYCService.fromDomain('testanchor.stellar.org');
///
/// // 2. Get JWT token via WebAuth (SEP-10)
/// final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
/// final userKeyPair = KeyPair.fromSecretSeed('S...');
/// final jwt = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);
///
/// // 3. Check what information is required
/// final infoRequest = GetCustomerInfoRequest()..jwt = jwt;
/// final infoResponse = await kycService.getCustomerInfo(infoRequest);
///
/// print('Status: ${infoResponse.status}');
/// if (infoResponse.status == 'NEEDS_INFO') {
///   print('Required fields: ${infoResponse.fields?.keys}');
/// }
///
/// // 4. Submit customer information
/// final putRequest = PutCustomerInfoRequest()
///   ..jwt = jwt
///   ..kycFields = StandardKYCFields()
///     ..naturalPersonKYCFields = NaturalPersonKYCFields()
///       ..firstName = 'John'
///       ..lastName = 'Doe'
///       ..emailAddress = 'john@example.com';
///
/// final putResponse = await kycService.putCustomerInfo(putRequest);
/// print('Customer ID: ${putResponse.id}');
/// ```
///
/// Example - With document upload:
/// ```dart
/// final putRequest = PutCustomerInfoRequest()
///   ..jwt = jwt
///   ..kycFields = StandardKYCFields()
///     ..naturalPersonKYCFields = NaturalPersonKYCFields()
///       ..firstName = 'John'
///       ..lastName = 'Doe'
///       ..photoIdFront = idFrontImageBytes // Uint8List
///       ..photoIdBack = idBackImageBytes;
///
/// final response = await kycService.putCustomerInfo(putRequest);
/// ```
///
/// Example - Email/phone verification:
/// ```dart
/// // After submitting email/phone, verify with code sent by anchor
/// final verifyRequest = PutCustomerVerificationRequest()
///   ..jwt = jwt
///   ..id = customerId
///   ..verificationFields = {
///     'email_address_verification': '123456',
///     'mobile_number_verification': '654321',
///   };
///
/// final response = await kycService.putCustomerVerification(verifyRequest);
/// print('Verification status: ${response.status}');
/// ```
///
/// Example - Set up status callbacks:
/// ```dart
/// // Register a callback URL to receive KYC status updates
/// final callbackRequest = PutCustomerCallbackRequest()
///   ..jwt = jwt
///   ..url = 'https://myapp.com/kyc-webhook'
///   ..account = userKeyPair.accountId;
///
/// await kycService.putCustomerCallback(callbackRequest);
/// ```
///
/// See also:
/// - [SEP-0012 Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md)
/// - [WebAuth] for obtaining JWT tokens (SEP-10)
/// - [StandardKYCFields] for standard KYC field definitions (SEP-9)
/// - [fromDomain] for easy initialization from stellar.toml
class KYCService {
  String _serviceAddress;
  late http.Client httpClient;
  Map<String, String>? httpRequestHeaders;

  /// Creates a KYCService with an explicit service address.
  ///
  /// Parameters:
  /// - serviceAddress: The base URL of the KYC server
  /// - httpClient: Optional custom HTTP client for testing
  /// - httpRequestHeaders: Optional custom headers for all requests
  ///
  /// For most use cases, prefer [fromDomain] which discovers the
  /// service address from stellar.toml automatically.
  KYCService(this._serviceAddress,
      {http.Client? httpClient, this.httpRequestHeaders}) {
    this.httpClient = httpClient ?? http.Client();
  }

  /// Creates a KYCService by discovering the endpoint from stellar.toml.
  ///
  /// Fetches the stellar.toml file from the specified domain and extracts the
  /// KYC server address. First checks for KYC_SERVER, falls back to TRANSFER_SERVER
  /// if not found (some anchors use the transfer server for KYC endpoints).
  ///
  /// Parameters:
  /// - domain: The domain name hosting the stellar.toml file
  /// - httpClient: Optional custom HTTP client for testing
  /// - httpRequestHeaders: Optional custom headers for requests
  ///
  /// Returns: Future<KYCService> configured with the domain's KYC endpoint
  ///
  /// Throws:
  /// - Exception: If neither KYC_SERVER nor TRANSFER_SERVER is found in stellar.toml
  ///
  /// Example:
  /// ```dart
  /// final kycService = await KYCService.fromDomain('testanchor.stellar.org');
  /// ```
  static Future<KYCService> fromDomain(
    String domain, {
    http.Client? httpClient,
    Map<String, String>? httpRequestHeaders,
  }) async {
    StellarToml toml = await StellarToml.fromDomain(domain,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);

    String? address = toml.generalInformation.kYCServer ??
        toml.generalInformation.transferServer;

    checkNotNull(
        address, "kyc or transfer server not available for domain " + domain);
    return KYCService(address!,
        httpClient: httpClient, httpRequestHeaders: httpRequestHeaders);
  }

  /// Retrieves customer information and KYC status from the anchor.
  ///
  /// This endpoint serves two primary purposes:
  /// 1. Discover required fields: If no customer exists for the given parameters,
  ///    returns the fields needed to register. Use this to build dynamic forms.
  /// 2. Check KYC status: For existing customers, returns current status
  ///    (ACCEPTED, PROCESSING, NEEDS_INFO, REJECTED) and any additional
  ///    information required.
  ///
  /// Customer identification:
  /// - Use `id` if you have a customer ID from a previous registration
  /// - Use `account` (and optionally `memo`/`memoType`) for new customers
  /// - Use `transactionId` when KYC requirements depend on transaction details
  ///
  /// Parameters:
  /// - request: GetCustomerInfoRequest containing authentication and identification
  ///
  /// Returns: Future<GetCustomerInfoResponse> with status and field requirements
  ///
  /// Response status values:
  /// - ACCEPTED: Customer approved, no action needed
  /// - PROCESSING: Under review, wait for status update
  /// - NEEDS_INFO: More information required (check `fields` property)
  /// - REJECTED: Customer rejected (check `message` for reason)
  ///
  /// Example - Check required fields:
  /// ```dart
  /// final request = GetCustomerInfoRequest()
  ///   ..jwt = authToken
  ///   ..account = userAccountId
  ///   ..type = 'sep31-sender'; // Optional: KYC type
  ///
  /// final response = await kycService.getCustomerInfo(request);
  ///
  /// if (response.status == 'NEEDS_INFO') {
  ///   response.fields?.forEach((fieldName, fieldInfo) {
  ///     print('Field: $fieldName');
  ///     print('  Type: ${fieldInfo.type}');
  ///     print('  Description: ${fieldInfo.description}');
  ///     print('  Optional: ${fieldInfo.optional}');
  ///     if (fieldInfo.choices != null) {
  ///       print('  Choices: ${fieldInfo.choices}');
  ///     }
  ///   });
  /// }
  /// ```
  ///
  /// Example - Check existing customer status:
  /// ```dart
  /// final request = GetCustomerInfoRequest()
  ///   ..jwt = authToken
  ///   ..id = customerId; // Use ID from previous registration
  ///
  /// final response = await kycService.getCustomerInfo(request);
  /// print('Status: ${response.status}');
  /// print('Message: ${response.message}');
  ///
  /// // Check which fields were provided and their status
  /// response.providedFields?.forEach((fieldName, fieldInfo) {
  ///   print('$fieldName: ${fieldInfo.status}');
  ///   if (fieldInfo.error != null) {
  ///     print('  Error: ${fieldInfo.error}');
  ///   }
  /// });
  /// ```
  Future<GetCustomerInfoResponse> getCustomerInfo(
      GetCustomerInfoRequest request) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer");

    _GetCustomerInfoRequestBuilder requestBuilder =
        _GetCustomerInfoRequestBuilder(httpClient, serverURI,
            httpRequestHeaders: httpRequestHeaders);

    final Map<String, String> queryParams = {};

    if (request.id != null) {
      queryParams["id"] = request.id!;
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
    if (request.type != null) {
      queryParams["type"] = request.type!;
    }
    if (request.transactionId != null) {
      queryParams["transaction_id"] = request.transactionId!;
    }
    if (request.lang != null) {
      queryParams["lang"] = request.lang!;
    }

    GetCustomerInfoResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(request.jwt!);

    return response;
  }

  /// Uploads or updates customer information for KYC verification.
  ///
  /// Submits customer data to the anchor in an authenticated and idempotent manner.
  /// This endpoint is used both for initial registration and for updating existing
  /// customer information. Supports both form fields and file uploads (ID documents, etc.).
  ///
  /// The request is idempotent: multiple calls with the same data won't create
  /// duplicate customers. Use the customer `id` from the response for subsequent
  /// updates or status checks.
  ///
  /// Parameters:
  /// - request: PutCustomerInfoRequest containing customer data and authentication
  ///
  /// Returns: Future<PutCustomerInfoResponse> with the customer ID
  ///
  /// Supported data:
  /// - Standard SEP-9 KYC fields via `kycFields` property
  /// - Custom fields via `customFields` property
  /// - File uploads (ID photos, proofs) via `kycFields` or `customFiles`
  ///
  /// Example - Basic customer registration:
  /// ```dart
  /// final request = PutCustomerInfoRequest()
  ///   ..jwt = authToken
  ///   ..account = userAccountId
  ///   ..kycFields = StandardKYCFields()
  ///     ..naturalPersonKYCFields = NaturalPersonKYCFields()
  ///       ..firstName = 'John'
  ///       ..lastName = 'Doe'
  ///       ..dateOfBirth = '1990-01-15'
  ///       ..emailAddress = 'john@example.com'
  ///       ..mobileNumber = '+1-555-0123';
  ///
  /// final response = await kycService.putCustomerInfo(request);
  /// print('Customer ID: ${response.id}');
  /// // Save this ID for future requests
  /// ```
  ///
  /// Example - With document uploads:
  /// ```dart
  /// // Load image files as Uint8List
  /// final idFrontBytes = await File('id_front.jpg').readAsBytes();
  /// final idBackBytes = await File('id_back.jpg').readAsBytes();
  ///
  /// final request = PutCustomerInfoRequest()
  ///   ..jwt = authToken
  ///   ..id = customerId // Update existing customer
  ///   ..kycFields = StandardKYCFields()
  ///     ..naturalPersonKYCFields = NaturalPersonKYCFields()
  ///       ..photoIdFront = idFrontBytes
  ///       ..photoIdBack = idBackBytes;
  ///
  /// final response = await kycService.putCustomerInfo(request);
  /// ```
  ///
  /// Example - Organization KYC:
  /// ```dart
  /// final request = PutCustomerInfoRequest()
  ///   ..jwt = authToken
  ///   ..account = organizationAccountId
  ///   ..type = 'sep31-receiver'
  ///   ..kycFields = StandardKYCFields()
  ///     ..organizationKYCFields = OrganizationKYCFields()
  ///       ..organizationName = 'Acme Corp'
  ///       ..organizationRegistrationNumber = '123456789'
  ///       ..organizationCountry = 'US';
  ///
  /// final response = await kycService.putCustomerInfo(request);
  /// ```
  ///
  /// Example - Update specific fields:
  /// ```dart
  /// // Only update the email address
  /// final request = PutCustomerInfoRequest()
  ///   ..jwt = authToken
  ///   ..id = customerId
  ///   ..kycFields = StandardKYCFields()
  ///     ..naturalPersonKYCFields = NaturalPersonKYCFields()
  ///       ..emailAddress = 'newemail@example.com';
  ///
  /// final response = await kycService.putCustomerInfo(request);
  /// ```
  Future<PutCustomerInfoResponse> putCustomerInfo(
      PutCustomerInfoRequest request) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer");

    _PutCustomerInfoRequestBuilder requestBuilder =
        _PutCustomerInfoRequestBuilder(httpClient, serverURI,
            httpRequestHeaders: this.httpRequestHeaders);

    final Map<String, String> fields = {};
    final Map<String, Uint8List> files = {};

    if (request.id != null) {
      fields["id"] = request.id!;
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
    if (request.type != null) {
      fields["type"] = request.type!;
    }
    if (request.transactionId != null) {
      fields["transaction_id"] = request.transactionId!;
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

    PutCustomerInfoResponse response = await requestBuilder
        .forFields(fields)
        .forFiles(files)
        .execute(request.jwt!);

    return response;
  }

  /// Verifies customer information fields using confirmation codes.
  ///
  /// After submitting contact information (email, phone), anchors may send
  /// verification codes. Use this endpoint to submit those codes and complete
  /// the verification process.
  ///
  /// Common verification fields:
  /// - email_address_verification: Code sent to email
  /// - mobile_number_verification: Code sent via SMS
  ///
  /// Parameters:
  /// - request: PutCustomerVerificationRequest with customer ID and verification codes
  ///
  /// Returns: Future<GetCustomerInfoResponse> with updated customer status
  ///
  /// Example:
  /// ```dart
  /// // User receives code "123456" via email
  /// final request = PutCustomerVerificationRequest()
  ///   ..jwt = authToken
  ///   ..id = customerId
  ///   ..verificationFields = {
  ///     'email_address_verification': '123456',
  ///   };
  ///
  /// final response = await kycService.putCustomerVerification(request);
  /// print('Status: ${response.status}');
  /// ```
  ///
  /// See also:
  /// - [SEP-0012 Customer Verification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification)
  Future<GetCustomerInfoResponse> putCustomerVerification(
      PutCustomerVerificationRequest request) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer/verification");

    _PutCustomerVerificationRequestBuilder requestBuilder =
        _PutCustomerVerificationRequestBuilder(httpClient, serverURI,
            httpRequestHeaders: this.httpRequestHeaders);

    final Map<String, String> fields = {};

    if (request.id != null) {
      fields["id"] = request.id!;
    }

    if (request.verificationFields != null) {
      fields.addAll(request.verificationFields!);
    }

    GetCustomerInfoResponse response =
        await requestBuilder.forFields(fields).execute(request.jwt!);

    return response;
  }

  /// Deletes all personal information for a customer (GDPR compliance).
  ///
  /// Removes all customer data stored by the anchor. This is typically used
  /// to comply with privacy regulations like GDPR's "right to be forgotten".
  ///
  /// Parameters:
  /// - account: The Stellar account ID (G...) of the customer to delete
  /// - memo: Optional memo if account is shared (multiple customers per account)
  /// - memoType: Type of memo (id, text, or hash)
  /// - jwt: SEP-10 JWT token proving ownership of the account
  ///
  /// Returns: Future<http.Response> - 200 OK on successful deletion
  ///
  /// Security: Request must be authenticated as the account owner via SEP-10.
  ///
  /// Example:
  /// ```dart
  /// await kycService.deleteCustomer(
  ///   userAccountId,
  ///   null, // no memo
  ///   null, // no memo type
  ///   authToken,
  /// );
  /// print('Customer data deleted');
  /// ```
  Future<http.Response> deleteCustomer(
      String account, String? memo, String? memoType, String jwt) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer/" + account);

    _DeleteCustomerRequestBuilder requestBuilder =
        _DeleteCustomerRequestBuilder(
      httpClient,
      serverURI,
      httpRequestHeaders: this.httpRequestHeaders,
    );

    final Map<String, String> fields = {};

    if (memo != null) {
      fields["memo"] = memo;
    }
    if (memoType != null) {
      fields["memo_type"] = memo!;
    }

    http.Response response =
        await requestBuilder.forFields(fields).execute(jwt);

    return response;
  }

  /// Registers a callback URL to receive KYC status updates.
  ///
  /// Allows clients to receive webhook notifications when customer KYC status
  /// changes. The anchor will POST updates to the provided URL. This replaces
  /// any previously registered callback URL for the account.
  ///
  /// Parameters:
  /// - request: PutCustomerCallbackRequest with callback URL and customer identification
  ///
  /// Returns: Future<http.Response> - 200 OK on successful registration
  ///
  /// Callback payload: The anchor will POST JSON with customer status updates.
  ///
  /// Example:
  /// ```dart
  /// final request = PutCustomerCallbackRequest()
  ///   ..jwt = authToken
  ///   ..url = 'https://myapp.com/webhooks/kyc-status'
  ///   ..account = userAccountId;
  ///
  /// await kycService.putCustomerCallback(request);
  /// print('Callback registered');
  /// ```
  ///
  /// See also:
  /// - [SEP-0012 Callback](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-callback-put)
  Future<http.Response> putCustomerCallback(
      PutCustomerCallbackRequest request) async {
    checkNotNull(request.url, "request.url cannot be null");
    Uri serverURI = Uri.parse(_serviceAddress + "/customer/callback");

    _PutCustomerCallbackRequestBuilder requestBuilder =
        _PutCustomerCallbackRequestBuilder(httpClient, serverURI,
            httpRequestHeaders: this.httpRequestHeaders);

    final Map<String, String> fields = {};

    fields["url"] = request.url!;

    if (request.id != null) {
      fields["id"] = request.id!;
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

    http.Response response =
        await requestBuilder.forFields(fields).execute(request.jwt!);

    return response;
  }

  /// Passing binary fields such as photo_id_front or organization.photo_proof_address in PUT /customer requests must be done using the multipart/form-data content type. This is acceptable in most cases, but multipart/form-data does not support nested data structures such as arrays or sub-objects.
  /// This endpoint is intended to decouple requests containing binary fields from requests containing nested data structures, supported by content types such as application/json. This endpoint is optional and only needs to be supported if the use case requires accepting nested data structures in PUT /customer requests.
  /// Once a file has been uploaded using this endpoint, it's file_id can be used in subsequent PUT /customer requests. The field name for the file_id should be the appropriate SEP-9 field followed by _file_id. For example, if file_abc is returned as a file_id from POST /customer/files, it can be used in a PUT /customer
  /// See:  https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-files
  Future<CustomerFileResponse> postCustomerFile(Uint8List file, String jwt) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer/files");

    _PostCustomerFileRequestBuilder requestBuilder =
    _PostCustomerFileRequestBuilder(httpClient, serverURI,
        httpRequestHeaders: this.httpRequestHeaders);

    CustomerFileResponse response = await requestBuilder
        .execute(file, jwt);

    return response;
  }

  /// Requests info about the uploaded files via postCustomerFile
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-files
  Future<GetCustomerFilesResponse> getCustomerFiles(
      String jwt, {String? fileId = null, String? customerId = null}) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer/files");

    _GetCustomerFilesRequestBuilder requestBuilder =
    _GetCustomerFilesRequestBuilder(httpClient, serverURI,
        httpRequestHeaders: httpRequestHeaders);

    final Map<String, String> queryParams = {};

    if (fileId != null) {
      queryParams["file_id"] = fileId;
    }
    if (customerId != null) {
      queryParams["customer_id"] = customerId;
    }

    GetCustomerFilesResponse response = await requestBuilder
        .forQueryParameters(queryParams)
        .execute(jwt);

    return response;
  }
}

class GetCustomerInfoRequest {
  /// (optional) The ID of the customer as returned in the response of a previous PUT request. If the customer has not been registered, they do not yet have an id.
  String? id;

  /// (depricated optional) The server should infer the account from the sub value in the SEP-10 JWT to identify the customer. The account parameter is only used for backwards compatibility, and if explicitly provided in the request body it should match the sub value of the decoded SEP-10 JWT.
  String? account;

  /// (optional) a properly formatted memo that uniquely identifies a customer. This value is generated by the client making the request. This parameter and memo_type are identical to the PUT request parameters of the same name.
  String? memo;

  /// (deprecated, optional) type of memo. One of text, id or hash. Deprecated because memos should always be of type id, although anchors should continue to support this parameter for outdated clients. If hash, memo should be base64-encoded. If a memo is present in the decoded SEP-10 JWT's sub value, this parameter can be ignored. See the Shared Accounts section for more information.
  String? memoType;

  /// (optional) the type of action the customer is being KYCd for. See the Type Specification here:
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#type-specification
  String? type;

  /// (optional) The transaction id with which the customer's info is associated. When information
  /// from the customer depends on the transaction (e.g., more information is required for larger amounts)
  String? transactionId;

  /// (optional) Defaults to en. Language code specified using ISO 639-1. Human readable descriptions, choices, and messages should be in this language.
  String? lang;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

/// The CustomerInfoField object defines the pieces of information the anchor has not yet received for the customer. It is required for the NEEDS_INFO status but may be included with any status.
/// Fields should be specified as an object with keys representing the SEP-9 field names required.
/// Customers in the ACCEPTED status should not have any required fields present in the object, since all required fields should have already been provided.
class GetCustomerInfoField extends Response {
  /// The data type of the field value. Can be "string", "binary", "number", or "date".
  String type;

  /// A human-readable description of this field, especially important if this is not a SEP-9 field.
  String? description;

  /// (optional) An array of valid values for this field.
  List<String>? choices;

  /// (optional) A boolean whether this field is required to proceed or not. Defaults to false.
  bool? optional;

  GetCustomerInfoField(
      this.type, this.description, this.choices, this.optional);

  factory GetCustomerInfoField.fromJson(Map<String, dynamic> json) =>
      GetCustomerInfoField(
          json['type'],
          json['description'],
          json['choices'] == null ? null : List<String>.from(json['choices']),
          json['optional']);
}

/// The provided CustomerInfoProvidedField object defines the pieces of information the anchor has received for
/// the customer. It is not required unless one or more of provided fields require verification
/// via customerVerification.
class GetCustomerInfoProvidedField extends Response {
  /// The data type of the field value. Can be "string", "binary", "number", or "date".
  String type;

  /// A human-readable description of this field, especially important if this is not a SEP-9 field.
  String? description;

  /// (optional) An array of valid values for this field.
  List<String>? choices;

  /// (optional) A boolean whether this field is required to proceed or not. Defaults to false.
  bool? optional;

  /// (optional) One of the values described here: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#field-statuses
  /// If the server does not wish to expose which field(s) were accepted or rejected, this property will be omitted.
  String? status;

  /// (optional) The human readable description of why the field is REJECTED.
  String? error;

  GetCustomerInfoProvidedField(this.type, this.description, this.choices,
      this.optional, this.status, this.error);

  factory GetCustomerInfoProvidedField.fromJson(Map<String, dynamic> json) =>
      GetCustomerInfoProvidedField(
        json['type'],
        json['description'],
        json['choices'] == null ? null : List<String>.from(json['choices']),
        json['optional'],
        json['status'],
        json['error'],
      );
}

/// Represents a customer info request response.
class GetCustomerInfoResponse extends Response {
  /// (optional) ID of the customer, if the customer has already been created via a PUT /customer request.
  String? id;

  /// Status of the customers KYC process.
  String status;

  /// (optional) An object containing the fields the anchor has not yet received for the given customer of the type provided in the request. Required for customers in the NEEDS_INFO status. See Fields for more detailed information.
  Map<String, GetCustomerInfoField>? fields;

  /// (optional) An object containing the fields the anchor has received for the given customer. Required for customers whose information needs verification via customerVerification.
  Map<String, GetCustomerInfoProvidedField>? providedFields;

  /// (optional) Human readable message describing the current state of customer's KYC process.
  String? message;

  GetCustomerInfoResponse(
      this.id, this.status, this.fields, this.providedFields, this.message);

  factory GetCustomerInfoResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? fieldsDynamic =
        json['fields'] == null ? null : json['fields'] as Map<String, dynamic>;
    Map<String, GetCustomerInfoField>? fields = {};
    if (fieldsDynamic != null) {
      fieldsDynamic.forEach((key, value) {
        fields![key] =
            GetCustomerInfoField.fromJson(value as Map<String, dynamic>);
      });
    } else {
      fields = null;
    }
    fieldsDynamic = json['provided_fields'] == null
        ? null
        : json['provided_fields'] as Map<String, dynamic>;
    Map<String, GetCustomerInfoProvidedField>? providedFields = {};
    if (fieldsDynamic != null) {
      fieldsDynamic.forEach((key, value) {
        providedFields![key] = GetCustomerInfoProvidedField.fromJson(
            value as Map<String, dynamic>);
      });
    } else {
      providedFields = null;
    }

    return GetCustomerInfoResponse(
        json['id'], json['status'], fields, providedFields, json['message']);
  }
}

// Requests the customer info data.
class _GetCustomerInfoRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _GetCustomerInfoRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _GetCustomerInfoRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<GetCustomerInfoResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<GetCustomerInfoResponse> type =
        TypeToken<GetCustomerInfoResponse>();
    ResponseHandler<GetCustomerInfoResponse> responseHandler =
        ResponseHandler<GetCustomerInfoResponse>(type);

    final Map<String, String> requestHeaders = {...(httpRequestHeaders ?? {})};
    if (jwt != null) {
      requestHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: requestHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<GetCustomerInfoResponse> execute(String jwt) {
    return _GetCustomerInfoRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class PutCustomerInfoRequest {
  /// (optional) The id value returned from a previous call to this endpoint. If specified, no other parameter is required.
  String? id;

  /// (optional) The Stellar account ID to upload KYC data for. If specified, id should not be specified.
  String? account;

  /// (optional) Uniquely identifies individual customers in schemes where multiple customers share one Stellar address (ex. SEP-31). If included, the KYC data will only apply to all requests that include this memo.
  String? memo;

  /// (optional) type of memo. One of text, id or hash. If hash, memo should be base64-encoded.
  String? memoType;

  /// (optional) the type of action the customer is being KYCd for. See the Type Specification here:
  /// https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#type-specification
  String? type;

  /// (optional) The transaction id with which the customer's info is associated. When information from
  /// the customer depends on the transaction (e.g., more information is required for larger amounts)
  String? transactionId;

  StandardKYCFields? kycFields;

  /// Custom fields that you can use for transmission (fieldname,value)
  Map<String, String>? customFields;

  /// Custom files that you can use for transmission (fieldname, value)
  Map<String, Uint8List>? customFiles;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

/// Represents a put customer info request response.
class PutCustomerInfoResponse extends Response {
  /// An identifier for the updated or created customer.
  String id;

  PutCustomerInfoResponse(this.id);

  factory PutCustomerInfoResponse.fromJson(Map<String, dynamic> json) =>
      PutCustomerInfoResponse(json['id']);
}

// Puts the customer info data.
class _PutCustomerInfoRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, Uint8List>? _files;
  Map<String, String>? httpRequestHeaders;

  _PutCustomerInfoRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _PutCustomerInfoRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  _PutCustomerInfoRequestBuilder forFiles(Map<String, Uint8List> files) {
    _files = files;
    return this;
  }

  static Future<PutCustomerInfoResponse> requestExecute(
      http.Client httpClient,
      Uri uri,
      Map<String, String>? fields,
      Map<String, Uint8List>? files,
      String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<PutCustomerInfoResponse> type =
        TypeToken<PutCustomerInfoResponse>();
    ResponseHandler<PutCustomerInfoResponse> responseHandler =
        ResponseHandler<PutCustomerInfoResponse>(type);

    final Map<String, String> hHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    var request = http.MultipartRequest('PUT', uri);
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

  Future<PutCustomerInfoResponse> execute(String jwt) {
    return _PutCustomerInfoRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, _files, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

class _PostCustomerFileRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _PostCustomerFileRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  static Future<CustomerFileResponse> requestExecute(
      http.Client httpClient,
      Uri uri,
      Uint8List file,
      String jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<CustomerFileResponse> type =
    TypeToken<CustomerFileResponse>();
    ResponseHandler<CustomerFileResponse> responseHandler =
    ResponseHandler<CustomerFileResponse>(type);

    final Map<String, String> hHeaders = {
      ...(httpRequestHeaders ?? {}),
      "Authorization": "Bearer $jwt",
    };
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(hHeaders);
    request.files.add(http.MultipartFile.fromBytes("file", file));
    http.StreamedResponse str = await httpClient.send(request);
    http.Response res = await http.Response.fromStream(str);
    return responseHandler.handleResponse(res);
  }

  Future<CustomerFileResponse> execute(Uint8List file, String jwt) {
    return _PostCustomerFileRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), file, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

class _GetCustomerFilesRequestBuilder extends RequestBuilder {
  Map<String, String>? httpRequestHeaders;

  _GetCustomerFilesRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _GetCustomerFilesRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<GetCustomerFilesResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<GetCustomerFilesResponse> type =
    TypeToken<GetCustomerFilesResponse>();
    ResponseHandler<GetCustomerFilesResponse> responseHandler =
    ResponseHandler<GetCustomerFilesResponse>(type);

    final Map<String, String> requestHeaders = {...(httpRequestHeaders ?? {})};
    requestHeaders["Authorization"] = "Bearer $jwt";
    return await httpClient.get(uri, headers: requestHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<GetCustomerFilesResponse> execute(String jwt) {
    return _GetCustomerFilesRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

class GetCustomerFilesResponse extends Response {

  List<CustomerFileResponse> files;

  GetCustomerFilesResponse(this.files);

  factory GetCustomerFilesResponse.fromJson(Map<String, dynamic> json) =>
      GetCustomerFilesResponse((json['files'] as List)
          .map((e) => CustomerFileResponse.fromJson(e))
          .toList());
}

class PutCustomerVerificationRequest {
  /// The ID of the customer as returned in the response of a previous PUT request.
  String? id;

  /// One or more SEP-9 fields appended with _verification ( *_verification)
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification
  Map<String, String>? verificationFields;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

// Puts the customer verification data.
class _PutCustomerVerificationRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, String>? httpRequestHeaders;

  _PutCustomerVerificationRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _PutCustomerVerificationRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  static Future<GetCustomerInfoResponse> requestExecute(
      http.Client httpClient, Uri uri, Map<String, String>? fields, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    TypeToken<GetCustomerInfoResponse> type =
        TypeToken<GetCustomerInfoResponse>();
    ResponseHandler<GetCustomerInfoResponse> responseHandler =
        ResponseHandler<GetCustomerInfoResponse>(type);

    final Map<String, String> hHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    var request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(hHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    http.StreamedResponse str = await httpClient.send(request);
    http.Response res = await http.Response.fromStream(str);
    return responseHandler.handleResponse(res);
  }

  Future<GetCustomerInfoResponse> execute(String jwt) {
    return _PutCustomerVerificationRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

// Delete customer
class _DeleteCustomerRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, String>? httpRequestHeaders;

  _DeleteCustomerRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _DeleteCustomerRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  static Future<http.Response> requestExecute(
      http.Client httpClient, Uri uri, Map<String, String>? fields, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    final Map<String, String> hHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    var request = http.MultipartRequest('DELETE', uri);
    request.headers.addAll(hHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    http.StreamedResponse str = await httpClient.send(request);
    http.Response res = await http.Response.fromStream(str);
    return res;
  }

  Future<http.Response> execute(String jwt) {
    return _DeleteCustomerRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

class PutCustomerCallbackRequest {
  /// A callback URL that the SEP-12 server will POST to when the state of the account changes.
  String? url;

  /// (optional) The ID of the customer as returned in the response of a previous PUT request.
  /// If the customer has not been registered, they do not yet have an id.
  String? id;

  /// (optional) The Stellar account ID used to identify this customer.
  /// If many customers share the same Stellar account, the memo and memoType parameters should be included as well.
  String? account;

  /// (optional) The memo used to create the customer record.
  String? memo;

  /// (optional) The type of memo used to create the customer record.
  String? memoType;

  /// jwt previously received from the anchor via the SEP-10 authentication flow
  String? jwt;
}

// Put customer callback
class _PutCustomerCallbackRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, String>? httpRequestHeaders;

  _PutCustomerCallbackRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  _PutCustomerCallbackRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  static Future<http.Response> requestExecute(
      http.Client httpClient, Uri uri, Map<String, String>? fields, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async {
    final Map<String, String> hHeaders = {
      ...(httpRequestHeaders ?? {}),
      if (jwt != null) "Authorization": "Bearer $jwt",
    };
    var request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(hHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    http.StreamedResponse str = await httpClient.send(request);
    http.Response res = await http.Response.fromStream(str);
    return res;
  }

  Future<http.Response> execute(String jwt) {
    return _PutCustomerCallbackRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

class CustomerFileResponse extends Response {

  String fileId;
  String contentType;
  int size;
  String? expiresAt;
  String? customerId;

  CustomerFileResponse(this.fileId, this.contentType, this.size, this.expiresAt,
      this.customerId);

  factory CustomerFileResponse.fromJson(Map<String, dynamic> json) =>
      CustomerFileResponse(
        json['file_id'],
        json['content_type'],
        json['size'],
        json['expires_at'],
        json['customer_id'],
      );
}
