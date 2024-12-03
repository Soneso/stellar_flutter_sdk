@Timeout(const Duration(seconds: 400))
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final serviceAddress = "http://api.stellar.org/kyc";
  final jwtToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJHQTZVSVhYUEVXWUZJTE5VSVdBQzM3WTRRUEVaTVFWREpIREtWV0ZaSjJLQ1dVQklVNUlYWk5EQSIsImp0aSI6IjE0NGQzNjdiY2IwZTcyY2FiZmRiZGU2MGVhZTBhZDczM2NjNjVkMmE2NTg3MDgzZGFiM2Q2MTZmODg1MTkwMjQiLCJpc3MiOiJodHRwczovL2ZsYXBweS1iaXJkLWRhcHAuZmlyZWJhc2VhcHAuY29tLyIsImlhdCI6MTUzNDI1Nzk5NCwiZXhwIjoxNTM0MzQ0Mzk0fQ.8nbB83Z6vGBgC1X9r3N6oQCFTBzDiITAfCJasRft0z0";
  final customerId = "d1ce2f48-3ff1-495d-9240-7a50d806cfed";
  final accountId = "GBWMCCC3NHSKLAOJDBKKYW7SSH2PFTTNVFKWSGLWGDLEBKLOVP5JLBBP";

  String requestGetCustomerSuccess() {
    return "{\"id\": \"d1ce2f48-3ff1-495d-9240-7a50d806cfed\",\"status\": \"ACCEPTED\",\"provided_fields\": {   \"first_name\": {      \"description\": \"The customer's first name\",      \"type\": \"string\",      \"status\": \"ACCEPTED\"   },   \"last_name\": {      \"description\": \"The customer's last name\",      \"type\": \"string\",      \"status\": \"ACCEPTED\"   },   \"email_address\": {      \"description\": \"The customer's email address\",      \"type\": \"string\",      \"status\": \"ACCEPTED\"   }}}";
  }

  String requestGetCustomerNotAllRequiredInfo() {
    return "{\"id\": \"d1ce2f48-3ff1-495d-9240-7a50d806cfed\",\"status\": \"NEEDS_INFO\",\"fields\": {   \"mobile_number\": {      \"description\": \"phone number of the customer\",      \"type\": \"string\"   },   \"email_address\": {      \"description\": \"email address of the customer\",      \"type\": \"string\",      \"optional\": true   }},\"provided_fields\": {   \"first_name\": {      \"description\": \"The customer's first name\",      \"type\": \"string\",      \"status\": \"ACCEPTED\"   },   \"last_name\": {      \"description\": \"The customer's last name\",      \"type\": \"string\",      \"status\": \"ACCEPTED\"   }}}";
  }

  String requestGetCustomerRequiresInfo() {
    return "{\"status\": \"NEEDS_INFO\",\"fields\": {   \"email_address\": {      \"description\": \"Email address of the customer\",      \"type\": \"string\",      \"optional\": true   },   \"id_type\": {      \"description\": \"Government issued ID\",      \"type\": \"string\",      \"choices\": [         \"Passport\",         \"Drivers License\",         \"State ID\"      ]   },   \"photo_id_front\": {      \"description\": \"A clear photo of the front of the government issued ID\",      \"type\": \"binary\"  }}}";
  }

  String requestGetCustomerProcessing() {
    return "{ \"id\": \"d1ce2f48-3ff1-495d-9240-7a50d806cfed\", \"status\": \"PROCESSING\", \"message\": \"Photo ID requires manual review. This process typically takes 1-2 business days.\", \"provided_fields\": {   \"photo_id_front\": {      \"description\": \"A clear photo of the front of the government issued ID\",      \"type\": \"binary\",      \"status\": \"PROCESSING\"   } }}";
  }

  String requestGetCustomerRejected() {
    return "{\"id\": \"d1ce2f48-3ff1-495d-9240-7a50d806cfed\",\"status\": \"REJECTED\",\"message\": \"This person is on a sanctions list\"}";
  }

  String requestGetCustomerRequiresVerification() {
    return "{\"id\": \"d1ce2f48-3ff1-495d-9240-7a50d806cfed\",\"status\": \"NEEDS_INFO\",\"provided_fields\": {   \"mobile_number\": {      \"description\": \"phone number of the customer\",      \"type\": \"string\",      \"status\": \"VERIFICATION_REQUIRED\"   }}}";
  }

  String requestPutCustomerInfo() {
    return "{\"id\": \"d1ce2f48-3ff1-495d-9240-7a50d806cfed\"}";
  }

  String requestPutCustomerVerification() {
    return "{\"id\": \"d1ce2f48-3ff1-495d-9240-7a50d806cfed\",\"status\": \"ACCEPTED\",\"provided_fields\": {   \"mobile_number\": {      \"description\": \"phone number of the customer\",      \"type\": \"string\",      \"status\": \"ACCEPTED\"   }}}";
  }

  String requestPostCustomerFile() {
    return "{\"file_id\": \"file_d3d54529-6683-4341-9b66-4ac7d7504238\", \"content_type\": \"image/jpeg\", \"size\": 4089371,\"customer_id\": \"2bf95490-db23-442d-a1bd-c6fd5efb584e\"}";
  }

  String requestGetCustomerFiles() {
    return "{\"files\": [{\"file_id\": \"file_d5c67b4c-173c-428c-baab-944f4b89a57f\", \"content_type\": \"image/png\",\"size\": 6134063,\"customer_id\": \"2bf95490-db23-442d-a1bd-c6fd5efb584e\"        },        {          \"file_id\": \"file_d3d54529-6683-4341-9b66-4ac7d7504238\",          \"content_type\": \"image/jpeg\",          \"size\": 4089371,          \"customer_id\": \"2bf95490-db23-442d-a1bd-c6fd5efb584e\"        }      ]}";
  }

  Uint8List randomUint8List(int length) {
    assert(length > 0);

    final random = Random();
    final ret = Uint8List(length);

    for (var i = 0; i < length; i++) {
      ret[i] = random.nextInt(256);
    }

    return ret;
  }

  test('test get customer info success', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestGetCustomerSuccess(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    GetCustomerInfoRequest request = new GetCustomerInfoRequest();
    request.id = customerId;
    request.account = accountId;
    request.jwt = jwtToken;

    GetCustomerInfoResponse infoResponse = await kycService.getCustomerInfo(request);

    assert(infoResponse.id == customerId);
    assert(infoResponse.status == "ACCEPTED");
    assert(infoResponse.providedFields != null);

    Map<String, GetCustomerInfoProvidedField?>? providedFields = infoResponse.providedFields;
    assert(providedFields!.length == 3);

    GetCustomerInfoProvidedField? firstName = providedFields!["first_name"];
    assert(firstName != null);
    assert(firstName!.description == "The customer's first name");
    assert(firstName!.type == "string");
    assert(firstName!.status == "ACCEPTED");

    GetCustomerInfoProvidedField? lastName = providedFields["last_name"];
    assert(lastName != null);
    assert(lastName!.description == "The customer's last name");
    assert(lastName!.type == "string");
    assert(lastName!.status == "ACCEPTED");

    GetCustomerInfoProvidedField? emailAddress = providedFields["email_address"];
    assert(emailAddress != null);
    assert(emailAddress!.description == "The customer's email address");
    assert(emailAddress!.type == "string");
    assert(emailAddress!.status == "ACCEPTED");
  });

  test('test get customer not all required info', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestGetCustomerNotAllRequiredInfo(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    GetCustomerInfoRequest request = new GetCustomerInfoRequest();
    request.id = customerId;
    request.account = accountId;
    request.jwt = jwtToken;

    GetCustomerInfoResponse infoResponse = await kycService.getCustomerInfo(request);

    assert(infoResponse.id == customerId);
    assert(infoResponse.status == "NEEDS_INFO");
    assert(infoResponse.fields != null);

    Map<String, GetCustomerInfoField?>? fields = infoResponse.fields;
    assert(fields!.length == 2);

    GetCustomerInfoField? mobileNr = fields!["mobile_number"];
    assert(mobileNr != null);
    assert(mobileNr!.description == "phone number of the customer");
    assert(mobileNr!.type == "string");

    GetCustomerInfoField? emailAddress = fields["email_address"];
    assert(emailAddress != null);
    assert(emailAddress!.description == "email address of the customer");
    assert(emailAddress!.type == "string");
    assert(emailAddress!.optional!);

    assert(infoResponse.providedFields != null);

    Map<String, GetCustomerInfoProvidedField?>? providedFields = infoResponse.providedFields;
    assert(providedFields!.length == 2);

    GetCustomerInfoProvidedField? firstName = providedFields!["first_name"];
    assert(firstName != null);
    assert(firstName!.description == "The customer's first name");
    assert(firstName!.type == "string");
    assert(firstName!.status == "ACCEPTED");

    GetCustomerInfoProvidedField? lastName = providedFields["last_name"];
    assert(lastName != null);
    assert(lastName!.description == "The customer's last name");
    assert(lastName!.type == "string");
    assert(lastName!.status == "ACCEPTED");
  });

  test('test get customer requires info', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      print(authHeader);
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestGetCustomerRequiresInfo(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    GetCustomerInfoRequest request = new GetCustomerInfoRequest();
    request.id = customerId;
    request.account = accountId;
    request.jwt = jwtToken;

    GetCustomerInfoResponse? infoResponse = await kycService.getCustomerInfo(request);

    assert(infoResponse.status == "NEEDS_INFO");
    assert(infoResponse.fields != null);

    Map<String, GetCustomerInfoField?>? fields = infoResponse.fields;
    assert(fields!.length == 3);

    GetCustomerInfoField? emailAddress = fields!["email_address"];
    assert(emailAddress != null);
    assert(emailAddress!.description == "Email address of the customer");
    assert(emailAddress!.type == "string");
    assert(emailAddress!.optional!);

    GetCustomerInfoField? idType = fields["id_type"];
    assert(idType != null);
    assert(idType!.description == "Government issued ID");
    assert(idType!.type == "string");
    assert(idType!.choices != null);
    List<String?>? idTypeChoices = idType!.choices;
    assert(idTypeChoices!.length == 3);
    assert(idTypeChoices!.contains("Passport"));
    assert(idTypeChoices!.contains("Drivers License"));
    assert(idTypeChoices!.contains("State ID"));

    GetCustomerInfoField? photoIdFront = fields["photo_id_front"];
    assert(photoIdFront != null);
    assert(photoIdFront!.description == "A clear photo of the front of the government issued ID");
    assert(photoIdFront!.type == "binary");
  });

  test('test get customer processing', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestGetCustomerProcessing(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    GetCustomerInfoRequest request = new GetCustomerInfoRequest();
    request.id = customerId;
    request.account = accountId;
    request.jwt = jwtToken;

    GetCustomerInfoResponse? infoResponse = await kycService.getCustomerInfo(request);

    assert(infoResponse.id == customerId);
    assert(infoResponse.status == "PROCESSING");
    assert(infoResponse.message ==
        "Photo ID requires manual review. This process typically takes 1-2 business days.");
    assert(infoResponse.providedFields != null);

    Map<String, GetCustomerInfoProvidedField?>? providedFields = infoResponse.providedFields;
    assert(providedFields!.length == 1);

    GetCustomerInfoProvidedField? photoIdFront = providedFields!["photo_id_front"];
    assert(photoIdFront != null);
    assert(photoIdFront!.description == "A clear photo of the front of the government issued ID");
    assert(photoIdFront!.type == "binary");
    assert(photoIdFront!.status == "PROCESSING");
  });

  test('test get customer rejected', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestGetCustomerRejected(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    GetCustomerInfoRequest request = new GetCustomerInfoRequest();
    request.id = customerId;
    request.account = accountId;
    request.jwt = jwtToken;

    GetCustomerInfoResponse? infoResponse = await kycService.getCustomerInfo(request);

    assert(infoResponse.id == customerId);
    assert(infoResponse.status == "REJECTED");
    assert(infoResponse.message == "This person is on a sanctions list");
  });

  test('test get customer requires verification', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestGetCustomerRequiresVerification(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    GetCustomerInfoRequest request = new GetCustomerInfoRequest();
    request.id = customerId;
    request.account = accountId;
    request.jwt = jwtToken;

    GetCustomerInfoResponse? infoResponse = await kycService.getCustomerInfo(request);

    assert(infoResponse.id == customerId);
    assert(infoResponse.status == "NEEDS_INFO");
    assert(infoResponse.providedFields != null);

    Map<String, GetCustomerInfoProvidedField?>? providedFields = infoResponse.providedFields;
    assert(providedFields!.length == 1);

    GetCustomerInfoProvidedField? mobileNr = providedFields!["mobile_number"];
    assert(mobileNr != null);
    assert(mobileNr!.description == "phone number of the customer");
    assert(mobileNr!.type == "string");
    assert(mobileNr!.status == "VERIFICATION_REQUIRED");
  });

  test('put customer info', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      String contentType = request.headers["content-type"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "PUT" &&
          request.url.toString().contains("customer") &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith("multipart/form-data;")) {

        // print(request.body);
        assert(request.body.contains('first_name'));
        assert(request.body.contains('George'));
        assert(request.body.contains('bank_account_number'));
        assert(request.body.contains('XX18981288373773'));
        assert(request.body.contains('name'));
        assert(request.body.contains('George Ltd.'));
        assert(request.body.contains('organization.bank_account_number'));
        assert(request.body.contains('YY76253437289616234'));
        return http.Response(requestPutCustomerInfo(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    PutCustomerInfoRequest request = new PutCustomerInfoRequest();
    request.id = customerId;
    request.account = accountId;
    request.jwt = jwtToken;

    var personFields = NaturalPersonKYCFields();
    personFields.firstName = 'George';
    var personFinancial = FinancialAccountKYCFields();
    personFinancial.bankAccountNumber = 'XX18981288373773';
    personFields.financialAccountKYCFields = personFinancial;

    var orgFields = OrganizationKYCFields();
    orgFields.name = 'George Ltd.';
    var orgFinancial = FinancialAccountKYCFields();
    orgFinancial.bankAccountNumber = 'YY76253437289616234';
    orgFields.financialAccountKYCFields = orgFinancial;

    var kycFields = new StandardKYCFields();
    kycFields.naturalPersonKYCFields = personFields;
    kycFields.organizationKYCFields = orgFields;

    request.kycFields = kycFields;

    PutCustomerInfoResponse? infoResponse = await kycService.putCustomerInfo(request);

    assert(infoResponse.id == customerId);
  });

  test('put customer verification', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      String contentType = request.headers["content-type"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "PUT" &&
          request.url.toString().contains("customer/verification") &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith("multipart/form-data;")) {
        return http.Response(requestPutCustomerVerification(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    PutCustomerVerificationRequest request = new PutCustomerVerificationRequest();
    request.id = customerId;
    Map<String, String> fields = {};
    fields["id"] = customerId;
    fields["mobile_number_verification"] = "2735021";
    request.verificationFields = fields;
    request.jwt = jwtToken;

    GetCustomerInfoResponse? infoResponse = await kycService.putCustomerVerification(request);

    assert(infoResponse.id == customerId);
    assert(infoResponse.status == "ACCEPTED");
    assert(infoResponse.providedFields != null);

    Map<String, GetCustomerInfoProvidedField?>? providedFields = infoResponse.providedFields;
    assert(providedFields!.length == 1);

    GetCustomerInfoProvidedField? mobileNr = providedFields!["mobile_number"];
    assert(mobileNr != null);
    assert(mobileNr!.description == "phone number of the customer");
    assert(mobileNr!.type == "string");
    assert(mobileNr!.status == "ACCEPTED");
  });

  test('delete customer', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      String contentType = request.headers["content-type"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "DELETE" &&
          request.url.toString().contains("customer/" + accountId) &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith("multipart/form-data;")) {
        return http.Response("", 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    http.Response? response =
        await kycService.deleteCustomer(accountId, "memo test", "text", jwtToken);

    assert(response.statusCode == 200);
  });

  test('post customer file', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      String contentType = request.headers["content-type"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "POST" &&
          request.url.toString().contains("customer/files") &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith("multipart/form-data;")) {

        return http.Response(requestPostCustomerFile(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });


    CustomerFileResponse response = await kycService.postCustomerFile(randomUint8List(20000), jwtToken);
    assert(response.fileId == "file_d3d54529-6683-4341-9b66-4ac7d7504238");
    assert(response.contentType == "image/jpeg");
    assert(response.size == 4089371);
    assert(response.customerId == "2bf95490-db23-442d-a1bd-c6fd5efb584e");

    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      String contentType = request.headers["content-type"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "POST" &&
          request.url.toString().contains("customer/files") &&
          authHeader.contains(jwtToken) &&
          contentType.startsWith("multipart/form-data;")) {

        return http.Response("", 413);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      response =
      await kycService.postCustomerFile(randomUint8List(20000), jwtToken);
      fail("should not pass without error");
    } on ErrorResponse catch (e) {
      assert(e.code == 413);
    }

    kycService.httpClient = MockClient((request) async {
      final mapJson = {'error':"file cannot be decoded. Must be jpg or png."};
      return http.Response(json.encode(mapJson), 400);
    });
    try {
      response =
      await kycService.postCustomerFile(randomUint8List(20000), jwtToken);
      fail("should not pass without error");
    } on ErrorResponse catch (e) {
      assert(e.code == 400);
      assert( e.body == '{"error":"file cannot be decoded. Must be jpg or png."}');
    }
  });

  test('test get customer files', () async {
    final kycService = KYCService(serviceAddress);
    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer/files") &&
          authHeader.contains(jwtToken)) {
        return http.Response(requestGetCustomerFiles(), 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    GetCustomerFilesResponse response = await kycService.getCustomerFiles(jwtToken);
    final files = response.files;
    assert(files.length == 2);
    final firstFile = response.files.first;
    assert("file_d5c67b4c-173c-428c-baab-944f4b89a57f" == firstFile.fileId);
    assert("image/png" == firstFile.contentType);
    assert(6134063 ==  firstFile.size);
    assert("2bf95490-db23-442d-a1bd-c6fd5efb584e" ==  firstFile.customerId);

    final secondFile = response.files.last;
    assert("file_d3d54529-6683-4341-9b66-4ac7d7504238" ==  secondFile.fileId);
    assert("image/jpeg" ==  secondFile.contentType);
    assert(4089371 == secondFile.size);
    assert("2bf95490-db23-442d-a1bd-c6fd5efb584e" ==  secondFile.customerId);

    kycService.httpClient = MockClient((request) async {
      String authHeader = request.headers["Authorization"]!;
      if (request.url.toString().startsWith(serviceAddress) &&
          request.method == "GET" &&
          request.url.toString().contains("customer/files") &&
          authHeader.contains(jwtToken)) {
        return http.Response('{"files": []}', 200);
      }

      final mapJson = {'error': "Bad request"};
      return http.Response(json.encode(mapJson), 400);
    });

    response = await kycService.getCustomerFiles(jwtToken);
    assert(response.files.isEmpty);
  });

}
