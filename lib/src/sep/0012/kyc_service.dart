import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';
import '../0009/standard_kyc_fields.dart';

/// Implements SEP-0012 v1.15.0 KYC (Know Your Customer) API for Stellar services.
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
/// 1. Client authenticates with SEP-10 WebAuth or SEP-45 Contract Auth to get a JWT token
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
/// - All requests must be authenticated with a SEP-10 or SEP-45 JWT token
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
/// // 2. Get JWT token via WebAuth (SEP-10) or ContractAuth (SEP-45)
/// // Option A: SEP-10 WebAuth
/// final webAuth = await WebAuth.fromDomain('testanchor.stellar.org', Network.TESTNET);
/// final userKeyPair = KeyPair.fromSecretSeed('S...');
/// final jwt = await webAuth.jwtToken(userKeyPair.accountId, [userKeyPair]);
///
/// // Option B: SEP-45 Contract Auth (for contract-based accounts)
/// // final jwt = await contractAuth.getJwtToken(...);
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
  /// - [serviceAddress] The base URL of the KYC server
  /// - [httpClient] Optional custom HTTP client for testing
  /// - [httpRequestHeaders] Optional custom headers for all requests
  ///
  /// For most use cases, prefer [fromDomain] which discovers the
  /// service address from stellar.toml automatically.
  /// Creates a KYCService with explicit KYC server address.
  ///
  /// Initializes the service with HTTP client for making KYC API requests.
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
  /// - [domain] The domain name hosting the stellar.toml file
  /// - [httpClient] Optional custom HTTP client for testing
  /// - [httpRequestHeaders] Optional custom headers for requests
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
  /// - [request] GetCustomerInfoRequest containing authentication and identification
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
  /// - [request] PutCustomerInfoRequest containing customer data and authentication
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
  /// - [request] PutCustomerVerificationRequest with customer ID and verification codes
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
  @Deprecated('Deprecated in SEP-12 v1.12.0 in favor of existing PUT /customer endpoint. Use putCustomerInfo instead.')
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
  /// - [account] The Stellar account ID (G...) of the customer to delete
  /// - [memo] Optional memo if account is shared (multiple customers per account)
  /// - [memoType] Type of memo (id, text, or hash)
  /// - [jwt] SEP-10 JWT token proving ownership of the account
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
      fields["memo_type"] = memoType;
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
  /// - [request] PutCustomerCallbackRequest with callback URL and customer identification
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

  /// Uploads a binary file separately from customer information.
  ///
  /// This endpoint decouples file uploads from PUT /customer requests, allowing
  /// clients to use application/json for nested data structures while uploading
  /// binary files separately. Once uploaded, the returned file_id can be used in
  /// subsequent PUT /customer requests.
  ///
  /// Use case:
  /// - When you need to send nested data structures (arrays, sub-objects) in PUT /customer
  /// - To avoid multipart/form-data limitations with complex JSON structures
  /// - To pre-upload large files before submitting customer information
  ///
  /// Parameters:
  /// - [file] Binary file data as Uint8List (e.g., photo ID, proof documents)
  /// - [jwt] SEP-10 or SEP-45 JWT token for authentication
  ///
  /// Returns: Future<CustomerFileResponse> containing the file_id and metadata
  ///
  /// Response properties:
  /// - fileId: Unique identifier for the uploaded file
  /// - contentType: MIME type of the uploaded file
  /// - size: File size in bytes
  /// - expiresAt: Optional expiration timestamp
  /// - customerId: Optional customer ID if file is associated with a customer
  ///
  /// Example - Upload file then use in PUT /customer:
  /// ```dart
  /// // 1. Upload the ID photo first
  /// final idFrontBytes = await File('id_front.jpg').readAsBytes();
  /// final fileResponse = await kycService.postCustomerFile(idFrontBytes, jwt);
  /// print('File uploaded: ${fileResponse.fileId}');
  ///
  /// // 2. Use the file_id in PUT /customer request
  /// final putRequest = PutCustomerInfoRequest()
  ///   ..jwt = jwt
  ///   ..customFields = {
  ///     'photo_id_front_file_id': fileResponse.fileId,
  ///   };
  ///
  /// final response = await kycService.putCustomerInfo(putRequest);
  /// ```
  ///
  /// Example - Upload multiple files:
  /// ```dart
  /// final idFront = await kycService.postCustomerFile(idFrontBytes, jwt);
  /// final idBack = await kycService.postCustomerFile(idBackBytes, jwt);
  /// final proofAddress = await kycService.postCustomerFile(proofBytes, jwt);
  ///
  /// final putRequest = PutCustomerInfoRequest()
  ///   ..jwt = jwt
  ///   ..customFields = {
  ///     'photo_id_front_file_id': idFront.fileId,
  ///     'photo_id_back_file_id': idBack.fileId,
  ///     'photo_proof_address_file_id': proofAddress.fileId,
  ///   };
  ///
  /// await kycService.putCustomerInfo(putRequest);
  /// ```
  ///
  /// See also:
  /// - [SEP-0012 Customer Files](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-files)
  /// - [getCustomerFiles] for retrieving information about uploaded files
  Future<CustomerFileResponse> postCustomerFile(Uint8List file, String jwt) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer/files");

    _PostCustomerFileRequestBuilder requestBuilder =
    _PostCustomerFileRequestBuilder(httpClient, serverURI,
        httpRequestHeaders: this.httpRequestHeaders);

    CustomerFileResponse response = await requestBuilder
        .execute(file, jwt);

    return response;
  }

  /// Retrieves information about files previously uploaded via postCustomerFile.
  ///
  /// This endpoint allows clients to query metadata about uploaded files by either
  /// file ID or customer ID. Use this to verify file uploads, check expiration times,
  /// or retrieve all files associated with a customer.
  ///
  /// Parameters:
  /// - [jwt] SEP-10 or SEP-45 JWT token for authentication
  /// - [fileId] (optional) Retrieve information about a specific file
  /// - [customerId] (optional) Retrieve all files associated with a customer
  ///
  /// Returns: Future<GetCustomerFilesResponse> containing a list of file metadata
  ///
  /// Query options:
  /// - Provide fileId to get information about a single file
  /// - Provide customerId to get all files for a customer
  /// - Provide neither to get all files for the authenticated account
  ///
  /// Example - Get info about a specific file:
  /// ```dart
  /// // After uploading a file
  /// final uploadResponse = await kycService.postCustomerFile(fileBytes, jwt);
  /// final fileId = uploadResponse.fileId;
  ///
  /// // Later, retrieve information about that file
  /// final filesResponse = await kycService.getCustomerFiles(jwt, fileId: fileId);
  ///
  /// for (var file in filesResponse.files) {
  ///   print('File ID: ${file.fileId}');
  ///   print('Content Type: ${file.contentType}');
  ///   print('Size: ${file.size} bytes');
  ///   print('Expires At: ${file.expiresAt}');
  /// }
  /// ```
  ///
  /// Example - Get all files for a customer:
  /// ```dart
  /// final filesResponse = await kycService.getCustomerFiles(
  ///   jwt,
  ///   customerId: 'd1ce2f48-3ff1-495d-9240-7a50d806cfed',
  /// );
  ///
  /// print('Customer has ${filesResponse.files.length} uploaded files');
  /// for (var file in filesResponse.files) {
  ///   print('- ${file.fileId}: ${file.contentType} (${file.size} bytes)');
  /// }
  /// ```
  ///
  /// Example - Check file expiration:
  /// ```dart
  /// final filesResponse = await kycService.getCustomerFiles(jwt, fileId: fileId);
  /// final file = filesResponse.files.first;
  ///
  /// if (file.expiresAt != null) {
  ///   final expiryDate = DateTime.parse(file.expiresAt!);
  ///   if (expiryDate.isBefore(DateTime.now())) {
  ///     print('File has expired, please re-upload');
  ///   } else {
  ///     print('File expires in ${expiryDate.difference(DateTime.now()).inDays} days');
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  /// - [SEP-0012 Customer Files](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-files)
  /// - [postCustomerFile] for uploading files
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

/// Request for retrieving customer KYC information and status.
///
/// Use this request to check what information an anchor requires for a customer,
/// or to verify the current status of a customer's KYC process.
class GetCustomerInfoRequest {
  /// (optional) The ID of the customer as returned in the response of a previous PUT request.
  /// If the customer has not been registered, they do not yet have an id.
  String? id;

  /// (deprecated, optional) The server should infer the account from the sub value in the SEP-10 or SEP-45 JWT to identify the customer.
  /// This parameter is only used for backwards compatibility, and if explicitly provided in the request body it should match the sub value of the decoded SEP-10 or SEP-45 JWT.
  /// Supported account formats: G... (standard), M... (muxed), or C... (contract) accounts.
  @Deprecated('Use JWT sub value instead. Maintained for backwards compatibility only.')
  String? account;

  /// (optional) A properly formatted memo that uniquely identifies a customer.
  /// This value is generated by the client making the request. This parameter and memo_type are identical to the PUT request parameters of the same name.
  String? memo;

  /// (deprecated, optional) Type of memo. One of text, id or hash.
  /// Deprecated because memos should always be of type id, although anchors should continue to support this parameter for outdated clients.
  /// If hash, memo should be base64-encoded. If a memo is present in the decoded SEP-10 JWT's sub value, this parameter can be ignored.
  @Deprecated('Memos should always be of type id. Maintained for backwards compatibility with outdated clients.')
  String? memoType;

  /// (optional) The type of action the customer is being KYC'd for.
  /// Examples: 'sep6-deposit', 'sep6-withdraw', 'sep31-sender', 'sep31-receiver'
  /// See the [Type Specification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#type-specification).
  String? type;

  /// (optional) The transaction id with which the customer's info is associated.
  /// Use when information from the customer depends on the transaction (e.g., more information is required for larger amounts).
  String? transactionId;

  /// (optional) Language code specified using ISO 639-1. Defaults to 'en'.
  /// Human readable descriptions, choices, and messages should be in this language.
  String? lang;

  /// JWT token previously received from the anchor via the SEP-10 or SEP-45 authentication flow.
  String? jwt;
}

/// Represents a field that the anchor needs from the customer.
///
/// This object defines pieces of information the anchor has not yet received for the customer.
/// It is required for the NEEDS_INFO status but may be included with any status.
/// Fields should be specified as an object with keys representing the SEP-9 field names required.
/// Customers in the ACCEPTED status should not have any required fields present in the object,
/// since all required fields should have already been provided.
class GetCustomerInfoField extends Response {
  /// The data type of the field value.
  /// Valid values: "string", "binary", "number", or "date".
  String type;

  /// A human-readable description of this field.
  /// Especially important if this is not a standard SEP-9 field.
  String? description;

  /// (optional) An array of valid values for this field.
  /// When present, the customer must select one of these choices.
  List<String>? choices;

  /// (optional) Whether this field is required to proceed or not.
  /// Defaults to false, meaning the field is required if not specified.
  bool? optional;

  /// Creates a GetCustomerInfoField from field requirements.
  ///
  /// Parameters:
  /// - [type] The data type of the field value
  /// - [description] Human-readable description of this field
  /// - [choices] Optional array of valid values for this field
  /// - [optional] Whether this field is optional (defaults to required if not specified)
  GetCustomerInfoField(
      this.type, this.description, this.choices, this.optional);

  /// Creates a GetCustomerInfoField from JSON response data.
  factory GetCustomerInfoField.fromJson(Map<String, dynamic> json) =>
      GetCustomerInfoField(
          json['type'],
          json['description'],
          json['choices'] == null ? null : List<String>.from(json['choices']),
          json['optional']);
}

/// Represents a field that the anchor has already received from the customer.
///
/// This object defines pieces of information the anchor has received for the customer.
/// It is not required unless one or more of the provided fields require verification
/// via customerVerification.
class GetCustomerInfoProvidedField extends Response {
  /// The data type of the field value.
  /// Valid values: "string", "binary", "number", or "date".
  String type;

  /// A human-readable description of this field.
  /// Especially important if this is not a standard SEP-9 field.
  String? description;

  /// (optional) An array of valid values for this field.
  List<String>? choices;

  /// (optional) Whether this field is required to proceed or not.
  /// Defaults to false, meaning the field is required if not specified.
  bool? optional;

  /// (optional) The status of this field's verification.
  /// Possible values: ACCEPTED, PROCESSING, REJECTED, VERIFICATION_REQUIRED.
  /// If the server does not wish to expose which field(s) were accepted or rejected, this property will be omitted.
  /// See [Field Statuses](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#field-statuses).
  String? status;

  /// (optional) The human readable description of why the field is REJECTED.
  /// Only present when status is REJECTED.
  String? error;

  /// Creates a GetCustomerInfoProvidedField from field status information.
  ///
  /// Parameters:
  /// - [type] The data type of the field value
  /// - [description] Human-readable description of this field
  /// - [choices] Optional array of valid values for this field
  /// - [optional] Whether this field is optional
  /// - [status] Verification status of this field (ACCEPTED, PROCESSING, REJECTED, VERIFICATION_REQUIRED)
  /// - [error] Human-readable error description if field is REJECTED
  GetCustomerInfoProvidedField(this.type, this.description, this.choices,
      this.optional, this.status, this.error);

  /// Creates a GetCustomerInfoProvidedField from JSON response data.
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

/// Response from a GET /customer request containing customer KYC status and field requirements.
///
/// This response indicates the current state of the customer's KYC process and
/// what information (if any) is still required.
class GetCustomerInfoResponse extends Response {
  /// (optional) ID of the customer, if the customer has already been created via a PUT /customer request.
  /// Present when the customer has been registered.
  String? id;

  /// Status of the customer's KYC process.
  /// Possible values: ACCEPTED, PROCESSING, NEEDS_INFO, REJECTED.
  String status;

  /// (optional) An object containing the fields the anchor has not yet received for the given customer.
  /// Required for customers in the NEEDS_INFO status.
  /// Keys are SEP-9 field names, values are GetCustomerInfoField objects describing requirements.
  Map<String, GetCustomerInfoField>? fields;

  /// (optional) An object containing the fields the anchor has already received for the given customer.
  /// Required for customers whose information needs verification via customerVerification.
  /// Keys are SEP-9 field names, values are GetCustomerInfoProvidedField objects with status.
  Map<String, GetCustomerInfoProvidedField>? providedFields;

  /// (optional) Human readable message describing the current state of the customer's KYC process.
  /// Required when status is REJECTED to explain the reason.
  String? message;

  /// Creates a GetCustomerInfoResponse with customer KYC status.
  ///
  /// Contains the current KYC status and required field information.
  GetCustomerInfoResponse(
      this.id, this.status, this.fields, this.providedFields, this.message);

  /// Creates a GetCustomerInfoResponse from JSON response data.
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

  /// Sets query parameters for the customer info request.
  _GetCustomerInfoRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes customer info request with JWT authentication.
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

  /// Executes the customer info request using configured parameters and authentication.
  Future<GetCustomerInfoResponse> execute(String jwt) {
    return _GetCustomerInfoRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

/// Request for uploading or updating customer KYC information.
class PutCustomerInfoRequest {
  /// (optional) The id value returned from a previous call to this endpoint. If specified, no other parameter is required.
  String? id;

  /// (deprecated, optional) The Stellar account ID to upload KYC data for.
  /// The server should infer the account from the sub value in the SEP-10 or SEP-45 JWT.
  /// This parameter is only used for backwards compatibility. If specified, id should not be specified.
  /// Supported account formats: G... (standard), M... (muxed), or C... (contract) accounts.
  @Deprecated('Use JWT sub value instead. Maintained for backwards compatibility only.')
  String? account;

  /// (optional) Uniquely identifies individual customers in schemes where multiple customers share one Stellar address (ex. SEP-31). If included, the KYC data will only apply to all requests that include this memo.
  String? memo;

  /// (deprecated, optional) type of memo. One of text, id or hash. If hash, memo should be base64-encoded.
  /// Deprecated because memos should always be of type id.
  @Deprecated('Memos should always be of type id. Maintained for backwards compatibility with outdated clients.')
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

/// Response from a PUT /customer request after uploading or updating customer information.
///
/// Contains the customer ID that should be used for future requests to check status
/// or update information for this customer.
class PutCustomerInfoResponse extends Response {
  /// An identifier for the updated or created customer.
  /// Save this ID to use in future GET /customer or PUT /customer requests.
  String id;

  /// Creates a PutCustomerInfoResponse from customer ID.
  ///
  /// Parameters:
  /// - [id] Unique identifier for the created or updated customer
  PutCustomerInfoResponse(this.id);

  /// Creates a PutCustomerInfoResponse from JSON response data.
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

  /// Sets fields to upload for the customer info request.
  _PutCustomerInfoRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  /// Sets files to upload for the customer info request.
  _PutCustomerInfoRequestBuilder forFiles(Map<String, Uint8List> files) {
    _files = files;
    return this;
  }

  /// Executes customer info update request with JWT authentication.
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

  /// Executes the customer info update request using configured fields, files, and authentication.
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

  /// Executes file upload request with JWT authentication.
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

  /// Executes the file upload request using configured file data and authentication.
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

  /// Sets query parameters for the customer files request.
  _GetCustomerFilesRequestBuilder forQueryParameters(
      Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  /// Executes customer files request with JWT authentication.
  static Future<GetCustomerFilesResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt,
      {Map<String, String>? httpRequestHeaders}) async{
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

  /// Executes the customer files request using configured parameters and authentication.
  Future<GetCustomerFilesResponse> execute(String jwt) {
    return _GetCustomerFilesRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), jwt);
  }
}

/// Response from a GET /customer/files request containing information about uploaded files.
///
/// Returns a list of file metadata for files uploaded via POST /customer/files.
class GetCustomerFilesResponse extends Response {
  /// List of files with their metadata.
  List<CustomerFileResponse> files;

  /// Creates a GetCustomerFilesResponse from file metadata list.
  ///
  /// Parameters:
  /// - [files] List of file metadata for uploaded customer documents
  GetCustomerFilesResponse(this.files);

  /// Creates a GetCustomerFilesResponse from JSON response data.
  factory GetCustomerFilesResponse.fromJson(Map<String, dynamic> json) =>
      GetCustomerFilesResponse((json['files'] as List)
          .map((e) => CustomerFileResponse.fromJson(e))
          .toList());
}

/// Request for verifying customer information fields using confirmation codes.
///
/// Used to submit verification codes sent by the anchor to confirm contact information
/// such as email addresses or phone numbers.
class PutCustomerVerificationRequest {
  /// The ID of the customer as returned in the response of a previous PUT request.
  String? id;

  /// One or more SEP-9 fields appended with _verification.
  /// For example: 'email_address_verification', 'mobile_number_verification'.
  /// Values should be the verification codes sent by the anchor.
  /// See [SEP-0012 Customer Verification](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification).
  Map<String, String>? verificationFields;

  /// JWT token previously received from the anchor via the SEP-10 or SEP-45 authentication flow.
  String? jwt;
}

// Puts the customer verification data.
class _PutCustomerVerificationRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, String>? httpRequestHeaders;

  _PutCustomerVerificationRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets verification fields for the customer verification request.
  _PutCustomerVerificationRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  /// Executes customer verification request with JWT authentication.
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

  /// Executes the customer verification request using configured fields and authentication.
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

  /// Sets fields for the customer deletion request.
  _DeleteCustomerRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  /// Executes customer deletion request with JWT authentication.
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

  /// Executes the customer deletion request using configured fields and authentication.
  Future<http.Response> execute(String jwt) {
    return _DeleteCustomerRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Request for registering a callback URL to receive KYC status updates.
///
/// Allows clients to receive webhook notifications when customer KYC status changes.
/// The anchor will POST updates to the provided URL.
class PutCustomerCallbackRequest {
  /// A callback URL that the SEP-12 server will POST to when the state of the customer changes.
  /// The anchor will send customer status updates to this URL as JSON webhooks.
  /// Callback payloads will be signed with Signature and X-Stellar-Signature headers.
  String? url;

  /// (optional) The ID of the customer as returned in the response of a previous PUT request.
  /// If the customer has not been registered, they do not yet have an id.
  String? id;

  /// (deprecated, optional) The Stellar account ID used to identify this customer.
  /// The server should infer the account from the sub value in the SEP-10 or SEP-45 JWT.
  /// If many customers share the same Stellar account, the memo and memoType parameters should be included as well.
  /// Supported account formats: G... (standard), M... (muxed), or C... (contract) accounts.
  @Deprecated('Use JWT sub value instead. Maintained for backwards compatibility only.')
  String? account;

  /// (optional) The memo used to create the customer record.
  String? memo;

  /// (deprecated, optional) The type of memo used to create the customer record.
  /// One of text, id or hash. Deprecated because memos should always be of type id.
  @Deprecated('Memos should always be of type id. Maintained for backwards compatibility with outdated clients.')
  String? memoType;

  /// JWT token previously received from the anchor via the SEP-10 or SEP-45 authentication flow.
  String? jwt;
}

// Put customer callback
class _PutCustomerCallbackRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;
  Map<String, String>? httpRequestHeaders;

  _PutCustomerCallbackRequestBuilder(http.Client httpClient, Uri serverURI,
      {this.httpRequestHeaders})
      : super(httpClient, serverURI, null);

  /// Sets fields for the callback registration request.
  _PutCustomerCallbackRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  /// Executes callback registration request with JWT authentication.
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

  /// Executes the callback registration request using configured fields and authentication.
  Future<http.Response> execute(String jwt) {
    return _PutCustomerCallbackRequestBuilder.requestExecute(
        this.httpClient, this.buildUri(), _fields, jwt,
        httpRequestHeaders: this.httpRequestHeaders);
  }
}

/// Response from a POST /customer/files request or part of GET /customer/files response.
///
/// Contains metadata about an uploaded file including its unique identifier
/// which can be used in subsequent PUT /customer requests.
class CustomerFileResponse extends Response {
  /// Unique identifier for the uploaded file.
  /// Use this ID with the pattern '{field_name}_file_id' in PUT /customer requests.
  /// For example, if uploading a photo ID front, use 'photo_id_front_file_id': '{this.fileId}'.
  String fileId;

  /// MIME type of the uploaded file.
  /// Common values: 'image/jpeg', 'image/png', 'application/pdf', etc.
  String contentType;

  /// Size of the uploaded file in bytes.
  int size;

  /// (optional) ISO 8601 timestamp indicating when the file will expire and need to be re-uploaded.
  /// Example: '2024-12-31T23:59:59Z'
  String? expiresAt;

  /// (optional) The customer ID this file is associated with, if any.
  String? customerId;

  /// Creates a CustomerFileResponse from file metadata.
  ///
  /// Parameters:
  /// - [fileId] Unique identifier for the uploaded file
  /// - [contentType] MIME type of the file
  /// - [size] File size in bytes
  /// - [expiresAt] Optional expiration timestamp
  /// - [customerId] Optional customer ID this file is associated with
  CustomerFileResponse(this.fileId, this.contentType, this.size, this.expiresAt,
      this.customerId);

  /// Creates a CustomerFileResponse from JSON response data.
  factory CustomerFileResponse.fromJson(Map<String, dynamic> json) =>
      CustomerFileResponse(
        json['file_id'],
        json['content_type'],
        json['size'],
        json['expires_at'],
        json['customer_id'],
      );
}
