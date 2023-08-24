import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../0001/stellar_toml.dart';
import 'dart:async';
import '../../requests/request_builder.dart';
import '../../responses/response.dart';
import '../../util.dart';
import '../0009/standard_kyc_fields.dart';

/// Implements SEP-0012 - KYC API.
/// See <https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md" target="_blank">KYC API</a>
class KYCService {
  String _serviceAddress;
  late http.Client httpClient;

  KYCService(this._serviceAddress, {http.Client? httpClient}) {
    if (httpClient != null) {
      this.httpClient = httpClient;
    } else {
      this.httpClient = http.Client();
    }
  }

  static Future<KYCService> fromDomain(String domain, {
    http.Client? httpClient,
  }) async {

    StellarToml toml = await StellarToml.fromDomain(domain, httpClient: httpClient);
    String? addr = toml.generalInformation.kYCServer;
    if (addr == null) {
      addr = toml.generalInformation.transferServer;
    }
    checkNotNull(addr, "kyc or transfer server not available for domain " + domain);
    return KYCService(addr!, httpClient: httpClient);
  }

  /// Check the status of a customers info (customer GET)
  /// This endpoint allows clients to:
  // 1. Fetch the fields the server requires in order to register a  customer:
  // If the server does not have a customer registered for the parameters sent in the request, it will return the fields required in the response. The same response will be returned when no parameters are sent.
  // 2. Check the status of a customer that may already be registered
  // This allows clients to check whether the customers information was accepted, rejected, or still needs more info. If the server still needs more info, or the server needs updated information, it will return the fields required.
  Future<GetCustomerInfoResponse> getCustomerInfo(GetCustomerInfoRequest request) async {
    Uri serverURI = Uri.parse(_serviceAddress + "/customer");

    _GetCustomerInfoRequestBuilder requestBuilder =
        _GetCustomerInfoRequestBuilder(httpClient, serverURI);

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
    if (request.lang != null) {
      queryParams["lang"] = request.lang!;
    }

    GetCustomerInfoResponse response =
        await requestBuilder.forQueryParameters(queryParams).execute(request.jwt!);

    return response;
  }

  /// Upload customer information to an anchor in an authenticated and idempotent fashion.
  Future<PutCustomerInfoResponse> putCustomerInfo(PutCustomerInfoRequest request) async {

    Uri serverURI = Uri.parse(_serviceAddress + "/customer");

    _PutCustomerInfoRequestBuilder requestBuilder =
        _PutCustomerInfoRequestBuilder(httpClient, serverURI);

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
    if (request.kycFields != null && request.kycFields?.naturalPersonKYCFields != null) {
      fields.addAll(request.kycFields!.naturalPersonKYCFields!.fields());
    }
    if (request.kycFields != null && request.kycFields?.organizationKYCFields != null) {
      fields.addAll(request.kycFields!.organizationKYCFields!.fields());
    }
    if (request.customFields != null) {
      fields.addAll(request.customFields!);
    }

    // files always at the end.
    if (request.kycFields != null && request.kycFields?.naturalPersonKYCFields != null) {
      files.addAll(request.kycFields!.naturalPersonKYCFields!.files());
    }
    if (request.kycFields != null && request.kycFields?.organizationKYCFields != null) {
      files.addAll(request.kycFields!.organizationKYCFields!.files());
    }
    if (request.customFiles != null) {
      files.addAll(request.customFiles!);
    }

    PutCustomerInfoResponse response =
        await requestBuilder.forFields(fields).forFiles(files).execute(request.jwt!);

    return response;
  }

  /// This endpoint allows servers to accept data values, usually confirmation codes, that verify a previously provided field via PUT /customer,
  /// such as mobile_number or email_address.
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-put-verification
  Future<GetCustomerInfoResponse> putCustomerVerification(
      PutCustomerVerificationRequest request) async {

    Uri serverURI = Uri.parse(_serviceAddress + "/customer/verification");

    _PutCustomerVerificationRequestBuilder requestBuilder =
        _PutCustomerVerificationRequestBuilder(httpClient, serverURI);

    final Map<String, String> fields = {};

    if (request.id != null) {
      fields["id"] = request.id!;
    }

    if (request.verificationFields != null) {
      fields.addAll(request.verificationFields!);
    }

    GetCustomerInfoResponse response = await requestBuilder.forFields(fields).execute(request.jwt!);

    return response;
  }

  /// Delete all personal information that the anchor has stored about a given customer.
  /// [account] is the Stellar account ID (G...) of the customer to delete.
  /// If account does not uniquely identify an individual customer (a shared account), the client should include the [memo] and [memoType] fields in the request.
  /// This request must be authenticated (via SEP-10) as coming from the owner of the account that will be deleted - [jwt].
  Future<http.Response> deleteCustomer(
      String account, String? memo, String? memoType, String jwt) async {

    Uri serverURI = Uri.parse(_serviceAddress + "/customer/" + account);

    _DeleteCustomerRequestBuilder requestBuilder =
        _DeleteCustomerRequestBuilder(httpClient, serverURI);

    final Map<String, String> fields = {};

    if (memo != null) {
      fields["memo"] = memo;
    }
    if (memoType != null) {
      fields["memo_type"] = memo!;
    }

    http.Response response = await requestBuilder.forFields(fields).execute(jwt);

    return response;
  }

  /// Allow the wallet to provide a callback URL to the anchor. The provided callback URL will replace (and supercede) any previously-set callback URL for this account.
  /// See: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md#customer-callback-put
  Future<http.Response> putCustomerCallback(PutCustomerCallbackRequest request) async {

    checkNotNull(request.url, "request.url cannot be null");
    Uri serverURI = Uri.parse(_serviceAddress + "/customer/callback");

    _PutCustomerCallbackRequestBuilder requestBuilder =
        _PutCustomerCallbackRequestBuilder(httpClient, serverURI);

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

    http.Response response = await requestBuilder.forFields(fields).execute(request.jwt!);

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
  String? type;

  /// A human-readable description of this field, especially important if this is not a SEP-9 field.
  String? description;

  /// (optional) An array of valid values for this field.
  List<String>? choices;

  /// (optional) A boolean whether this field is required to proceed or not. Defaults to false.
  bool? optional;

  GetCustomerInfoField(this.type, this.description, this.choices, this.optional);

  factory GetCustomerInfoField.fromJson(Map<String, dynamic> json) => GetCustomerInfoField(
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
  String? type;

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

  GetCustomerInfoProvidedField(
      this.type, this.description, this.choices, this.optional, this.status, this.error);

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
  String? status;

  /// (optional) An object containing the fields the anchor has not yet received for the given customer of the type provided in the request. Required for customers in the NEEDS_INFO status. See Fields for more detailed information.
  Map<String, GetCustomerInfoField?>? fields;

  /// (optional) An object containing the fields the anchor has received for the given customer. Required for customers whose information needs verification via customerVerification.
  Map<String, GetCustomerInfoProvidedField?>? providedFields;

  /// (optional) Human readable message describing the current state of customer's KYC process.
  String? message;

  GetCustomerInfoResponse(this.id, this.status, this.fields, this.providedFields, this.message);

  factory GetCustomerInfoResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? fieldsDynamic =
        json['fields'] == null ? null : json['fields'] as Map<String, dynamic>;
    Map<String, GetCustomerInfoField>? fields = {};
    if (fieldsDynamic != null) {
      fieldsDynamic.forEach((key, value) {
        fields![key] = GetCustomerInfoField.fromJson(value as Map<String, dynamic>);
      });
    } else {
      fields = null;
    }
    fieldsDynamic =
        json['provided_fields'] == null ? null : json['provided_fields'] as Map<String, dynamic>;
    Map<String, GetCustomerInfoProvidedField>? providedFields = {};
    if (fieldsDynamic != null) {
      fieldsDynamic.forEach((key, value) {
        providedFields![key] = GetCustomerInfoProvidedField.fromJson(value as Map<String, dynamic>);
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
  _GetCustomerInfoRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _GetCustomerInfoRequestBuilder forQueryParameters(Map<String, String> queryParams) {
    queryParameters.addAll(queryParams);
    return this;
  }

  static Future<GetCustomerInfoResponse> requestExecute(
      http.Client httpClient, Uri uri, String? jwt) async {
    TypeToken<GetCustomerInfoResponse> type = TypeToken<GetCustomerInfoResponse>();
    ResponseHandler<GetCustomerInfoResponse> responseHandler =
        ResponseHandler<GetCustomerInfoResponse>(type);

    final Map<String, String> feeHeaders = {...RequestBuilder.headers};
    if (jwt != null) {
      feeHeaders["Authorization"] = "Bearer $jwt";
    }
    return await httpClient.get(uri, headers: feeHeaders).then((response) {
      return responseHandler.handleResponse(response);
    });
  }

  Future<GetCustomerInfoResponse> execute(String jwt) {
    return _GetCustomerInfoRequestBuilder.requestExecute(this.httpClient, this.buildUri(), jwt);
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

  _PutCustomerInfoRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _PutCustomerInfoRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  _PutCustomerInfoRequestBuilder forFiles(Map<String, Uint8List> files) {
    _files = files;
    return this;
  }

  static Future<PutCustomerInfoResponse> requestExecute(http.Client httpClient, Uri uri,
      Map<String, String>? fields, Map<String, Uint8List>? files, String? jwt) async {
    TypeToken<PutCustomerInfoResponse> type = TypeToken<PutCustomerInfoResponse>();
    ResponseHandler<PutCustomerInfoResponse> responseHandler =
        ResponseHandler<PutCustomerInfoResponse>(type);

    final Map<String, String> hHeaders = RequestBuilder.headers;
    if (jwt != null) {
      hHeaders["Authorization"] = "Bearer $jwt";
    }
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
        this.httpClient, this.buildUri(), _fields, _files, jwt);
  }
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

  _PutCustomerVerificationRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _PutCustomerVerificationRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  static Future<GetCustomerInfoResponse> requestExecute(
      http.Client httpClient, Uri uri, Map<String, String>? fields, String? jwt) async {
    TypeToken<GetCustomerInfoResponse> type = TypeToken<GetCustomerInfoResponse>();
    ResponseHandler<GetCustomerInfoResponse> responseHandler =
        ResponseHandler<GetCustomerInfoResponse>(type);

    final Map<String, String> hHeaders = RequestBuilder.headers;
    if (jwt != null) {
      hHeaders["Authorization"] = "Bearer $jwt";
    }
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
        this.httpClient, this.buildUri(), _fields, jwt);
  }
}

// Delete customer
class _DeleteCustomerRequestBuilder extends RequestBuilder {
  Map<String, String>? _fields;

  _DeleteCustomerRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _DeleteCustomerRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  static Future<http.Response> requestExecute(
      http.Client httpClient, Uri uri, Map<String, String>? fields, String? jwt) async {
    final Map<String, String> hHeaders = RequestBuilder.headers;
    if (jwt != null) {
      hHeaders["Authorization"] = "Bearer $jwt";
    }
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
        this.httpClient, this.buildUri(), _fields, jwt);
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

  _PutCustomerCallbackRequestBuilder(http.Client httpClient, Uri serverURI)
      : super(httpClient, serverURI, null);

  _PutCustomerCallbackRequestBuilder forFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  static Future<http.Response> requestExecute(
      http.Client httpClient, Uri uri, Map<String, String>? fields, String? jwt) async {
    final Map<String, String> hHeaders = RequestBuilder.headers;
    if (jwt != null) {
      hHeaders["Authorization"] = "Bearer $jwt";
    }
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
        this.httpClient, this.buildUri(), _fields, jwt);
  }
}
