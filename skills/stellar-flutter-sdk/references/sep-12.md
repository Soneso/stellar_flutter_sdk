# SEP-12: KYC API

**Purpose:** Submit and manage customer KYC information for Know Your Customer compliance with anchors.
**Prerequisites:** Requires JWT from SEP-10 (see [sep-10.md](sep-10.md)); for contract accounts requires SEP-45.
**Standard KYC Fields:** See [sep-09.md](sep-09.md) for all field classes, properties, constants, and prefix behavior

## Table of Contents

- [Service initialization](#service-initialization)
- [Get customer info](#get-customer-info)
- [Put customer info](#put-customer-info)
  - [Natural person fields](#natural-person-fields)
  - [Organization fields](#organization-fields)
  - [Financial account fields](#financial-account-fields)
  - [Card fields](#card-fields)
  - [File uploads (binary fields)](#file-uploads-binary-fields)
  - [Custom fields and files](#custom-fields-and-files)
- [Put customer verification (deprecated)](#put-customer-verification-deprecated)
- [Put customer callback](#put-customer-callback)
- [Post customer file](#post-customer-file)
- [Get customer files](#get-customer-files)
- [Delete customer](#delete-customer)
- [Error handling](#error-handling)
- [Response reference](#response-reference)
- [Common pitfalls](#common-pitfalls)

---

## Service initialization

### From domain (recommended)

`KYCService.fromDomain()` fetches the anchor's `stellar.toml`, reads `KYC_SERVER` (falls back to `TRANSFER_SERVER`), and returns a configured `KYCService`. Throws `Exception` if neither field is found.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

try {
  final kycService = await KYCService.fromDomain('testanchor.stellar.org');
  // ready to use
} catch (e) {
  print('No KYC service found: $e');
}

// With custom HTTP client (timeouts, proxies, etc.)
import 'package:http/http.dart' as http;

final client = http.Client();
final kycService = await KYCService.fromDomain(
  'testanchor.stellar.org',
  httpClient: client,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

### Manual construction

Use when you already know the KYC endpoint URL.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = KYCService('https://api.anchor.com/kyc');

// With optional custom client and headers
final kycService = KYCService(
  'https://api.anchor.com/kyc',
  httpClient: myClient,
  httpRequestHeaders: {'X-Custom': 'value'},
);
```

Constructor signature:
```
KYCService(String serviceAddress, {http.Client? httpClient, Map<String, String>? httpRequestHeaders})
```

---

## Get customer info

Retrieve a customer's current verification status and the fields the anchor needs.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final request = GetCustomerInfoRequest()
  ..jwt = jwtToken;       // required: JWT from SEP-10 or SEP-45

// Optional identification parameters:
// ..id = customerId      // anchor-assigned customer ID from a previous PUT
// ..account = 'GABC...' // Stellar account (deprecated, inferred from JWT sub)
// ..memo = '12345'       // integer memo for shared/omnibus accounts
// ..memoType = 'id'      // deprecated; memos should always be type id
// ..type = 'sep31-sender' // e.g. sep6-deposit, sep31-sender, sep31-receiver
// ..transactionId = 'tx_abc' // link to a specific transaction
// ..lang = 'en'          // ISO 639-1; defaults to "en"

final response = await kycService.getCustomerInfo(request);

// Customer status: ACCEPTED, PROCESSING, NEEDS_INFO, or REJECTED
print('Status: ${response.status}');   // String (non-null)
print('ID: ${response.id}');           // String? (null if no customer record yet)
print('Message: ${response.message}'); // String? (required when REJECTED)

// Fields the anchor still needs (null unless status is NEEDS_INFO or no customer yet)
if (response.fields != null) {
  response.fields!.forEach((fieldName, field) {
    // field.type        — "string", "binary", "number", or "date"
    // field.description — String? human-readable description
    // field.optional    — bool? false/null means required; true means optional
    // field.choices     — List<String>? valid values (empty list if unconstrained)
    // WRONG: if (field.choices != null) — choices is [] not null when unconstrained
    // CORRECT: if (field.choices != null && field.choices!.isNotEmpty)
    final required = (field.optional == true) ? 'optional' : 'required';
    print('$fieldName ($required): ${field.description}');
    if (field.choices != null && field.choices!.isNotEmpty) {
      print('  Choices: ${field.choices}');
    }
  });
}

// Fields already provided and their status
if (response.providedFields != null) {
  response.providedFields!.forEach((fieldName, field) {
    // field.status — String? ACCEPTED, PROCESSING, REJECTED, or VERIFICATION_REQUIRED
    // field.error  — String? set when status is REJECTED
    print('$fieldName: ${field.status}');
    if (field.status == 'REJECTED') {
      print('  Reason: ${field.error}');
    }
  });
}
```

---

## Put customer info

Submit or update customer data. Returns a `PutCustomerInfoResponse` with `id` — save this for future requests.

### Natural person fields

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final personFields = NaturalPersonKYCFields()
  // Name
  ..firstName = 'Jane'
  ..lastName = 'Doe'
  ..additionalName = 'Marie'            // middle name

  // Address
  ..address = '123 Main St, Apt 4B'
  ..city = 'San Francisco'
  ..stateOrProvince = 'CA'
  ..postalCode = '94102'
  ..addressCountryCode = 'USA'          // ISO 3166-1 alpha-3

  // Contact
  ..mobileNumber = '+14155551234'       // E.164 format
  ..mobileNumberFormat = 'E.164'        // optional; receiver assumes E.164 if absent
  ..emailAddress = 'jane@example.com'
  ..languageCode = 'en'                 // ISO 639-1

  // Birth — DateTime objects, NOT strings
  ..birthDate = DateTime(1990, 5, 15)   // DateTime? serialized as YYYY-MM-DD (date only)
  ..birthPlace = 'New York, NY'
  ..birthCountryCode = 'USA'            // ISO 3166-1 alpha-3

  // Tax
  ..taxId = '123-45-6789'
  ..taxIdName = 'SSN'

  // Employment
  ..occupation = 2512                   // int (ISCO-08 code) — NOT a string
  ..employerName = 'Acme Corp'
  ..employerAddress = '456 Business Ave'

  // ID document — date fields are DateTime objects, NOT strings
  ..idType = 'passport'                        // passport, drivers_license, id_card
  ..idNumber = 'AB123456'
  ..idCountryCode = 'USA'
  ..idIssueDate = DateTime(2020, 1, 15)        // DateTime? serialized as YYYY-MM-DD (date only)
  ..idExpirationDate = DateTime(2030, 1, 15)   // DateTime? serialized as YYYY-MM-DD (date only)

  // Other
  ..sex = 'female'                      // male, female, or other
  ..ipAddress = '192.168.1.1'
  ..referralId = 'REF123';

final kycFields = StandardKYCFields()
  ..naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest()
  ..jwt = jwtToken
  ..kycFields = kycFields
  ..type = 'sep31-sender';  // optional

// To update an existing customer, set their ID:
// ..id = customerId

final response = await kycService.putCustomerInfo(request);
final customerId = response.id; // String — save for future requests
print('Customer ID: $customerId');
```

### Organization fields

All organization fields are automatically sent with the `organization.` prefix per SEP-9.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final orgFields = OrganizationKYCFields()
  ..name = 'Acme Corporation'           // organization.name
  ..VATNumber = 'DE123456789'           // organization.VAT_number (VATNumber, not vatNumber)
  ..registrationNumber = 'HRB 12345'   // organization.registration_number
  ..registrationDate = '2010-06-15'    // String? (ISO 8601 date) — NOT a DateTime
  ..registeredAddress = '456 Business Ave'
  ..city = 'New York'
  ..stateOrProvince = 'NY'
  ..postalCode = '10001'
  ..addressCountryCode = 'USA'
  ..numberOfShareholders = 3           // int
  ..shareholderName = 'John Smith'
  ..directorName = 'Jane Doe'
  ..website = 'https://acme.example.com'
  ..email = 'contact@acme.example.com'
  ..phone = '+12125551234';            // E.164 format

final kycFields = StandardKYCFields()
  ..organizationKYCFields = orgFields;

final request = PutCustomerInfoRequest()
  ..jwt = jwtToken
  ..kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

### Financial account fields

Attach financial account details to a natural person or organization.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final financialFields = FinancialAccountKYCFields()
  // Traditional bank account
  ..bankName = 'First National Bank'
  ..bankAccountType = 'checking'           // checking or savings
  ..bankAccountNumber = '1234567890'
  ..bankNumber = '021000021'               // routing number (US)
  ..bankBranchNumber = '001'
  ..bankPhoneNumber = '+18005551234'       // E.164

  // Transfer memo / reference
  ..externalTransferMemo = 'WIRE-REF-12345'

  // Mexico CLABE
  ..clabeNumber = '032180000118359719'

  // Argentina CBU/CVU
  ..cbuNumber = '0110000000001234567890'
  ..cbuAlias = 'mi.cuenta.arg'

  // Mobile money
  ..mobileMoneyNumber = '+254712345678'
  ..mobileMoneyProvider = 'M-Pesa'

  // Crypto payout address
  ..cryptoAddress = 'GDJKZLTXCKVQYIGJQIYSNFJ3CEKIIZ6HIAZEDE2KBPCSEPBVH4GNDLTJ';

// Attach to natural person
final personFields = NaturalPersonKYCFields()
  ..firstName = 'Jane'
  ..lastName = 'Doe'
  ..financialAccountKYCFields = financialFields;

// OR attach to organization (fields get 'organization.' prefix automatically)
final orgFields = OrganizationKYCFields()
  ..name = 'Acme Corp'
  ..financialAccountKYCFields = financialFields;

final kycFields = StandardKYCFields()
  ..naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest()
  ..jwt = jwtToken
  ..kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

### Card fields

Attach payment card details to a natural person or organization. All card field keys have the `card.` prefix.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final cardFields = CardKYCFields()
  ..number = '4111111111111111'
  ..expirationDate = '29-11'       // YY-MM format (November 2029)
  ..cvc = '123'
  ..holderName = 'John Doe'
  ..network = 'Visa'               // card.network
  ..postalCode = '94102'           // card.postal_code
  ..countryCode = 'US'             // ISO 3166-1 alpha-2 (alpha-2, not alpha-3)
  ..stateOrProvince = 'CA'
  ..city = 'San Francisco'
  ..address = '123 Main St';
  // OR use tokenized card instead of raw number:
  // ..token = 'tok_visa_1234'

final personFields = NaturalPersonKYCFields()
  ..firstName = 'John'
  ..cardKYCFields = cardFields;

final kycFields = StandardKYCFields()
  ..naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest()
  ..jwt = jwtToken
  ..kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

### File uploads (binary fields)

Binary fields (photos, documents) are stored as `Uint8List` and sent via `multipart/form-data` automatically.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final idFrontBytes = await File('id_front.jpg').readAsBytes();
final idBackBytes = await File('id_back.jpg').readAsBytes();
final notaryBytes = await File('notary.pdf').readAsBytes();
final utilityBillBytes = await File('utility_bill.pdf').readAsBytes();
final bankStatementBytes = await File('bank_statement.pdf').readAsBytes();
final livenessBytes = await File('selfie.mp4').readAsBytes();

final personFields = NaturalPersonKYCFields()
  ..idType = 'passport'
  ..idNumber = 'AB123456'
  ..idCountryCode = 'USA'
  ..idIssueDate = DateTime(2020, 1, 15)
  ..idExpirationDate = DateTime(2030, 1, 15)
  ..photoIdFront = idFrontBytes               // Uint8List
  ..photoIdBack = idBackBytes                 // Uint8List
  ..notaryApprovalOfPhotoId = notaryBytes     // Uint8List
  ..photoProofResidence = utilityBillBytes    // Uint8List
  ..proofOfIncome = bankStatementBytes        // Uint8List
  ..proofOfLiveness = livenessBytes;          // Uint8List

final kycFields = StandardKYCFields()
  ..naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest()
  ..jwt = jwtToken
  ..id = customerId   // update existing customer
  ..kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

Available binary properties on `NaturalPersonKYCFields`:

| Dart property | Field key sent |
|---|---|
| `photoIdFront` | `photo_id_front` |
| `photoIdBack` | `photo_id_back` |
| `notaryApprovalOfPhotoId` | `notary_approval_of_photo_id` |
| `photoProofResidence` | `photo_proof_residence` |
| `proofOfIncome` | `proof_of_income` |
| `proofOfLiveness` | `proof_of_liveness` |

Available binary properties on `OrganizationKYCFields`:

| Dart property | Field key sent |
|---|---|
| `photoIncorporationDoc` | `organization.photo_incorporation_doc` |
| `photoProofAddress` | `organization.photo_proof_address` |

### Custom fields and files

For anchor-specific fields not covered by SEP-9, use `customFields` (text) and `customFiles` (binary).

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final request = PutCustomerInfoRequest()
  ..jwt = jwtToken
  ..id = customerId
  // Custom text fields — Map<String, String>
  ..customFields = {
    'custom_field_1': 'custom value',
    'anchor_specific_id': 'ABC123',
  }
  // Custom binary files — Map<String, Uint8List>
  ..customFiles = {
    'additional_document': await File('document.pdf').readAsBytes(),
  };

final response = await kycService.putCustomerInfo(request);
```

---

## Put customer verification (deprecated)

`PUT /customer/verification` is **deprecated in SEP-12 v1.12.0**. The preferred approach is to submit verification codes via `PUT /customer` using `customFields` with the `_verification` suffix.

The deprecated endpoint is supported for backwards compatibility:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// DEPRECATED: use PUT /customer with customFields instead
// ignore: deprecated_member_use
final request = PutCustomerVerificationRequest()
  ..jwt = jwtToken
  ..id = customerId
  ..verificationFields = {
    'mobile_number_verification': '2735021',
    'email_address_verification': 'ABC123',
  };

// Returns GetCustomerInfoResponse (same type as getCustomerInfo())
// NOT PutCustomerInfoResponse
// ignore: deprecated_member_use
final response = await kycService.putCustomerVerification(request);
print('Status: ${response.status}');  // ACCEPTED, NEEDS_INFO, etc.
```

Return type is `GetCustomerInfoResponse`, **not** `PutCustomerInfoResponse`.

---

## Put customer callback

Register a URL to receive POST notifications when a customer's status changes. The new URL replaces any previously registered callback.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final request = PutCustomerCallbackRequest()
  ..jwt = jwtToken
  ..url = 'https://myapp.com/kyc-callback'  // required
  ..id = customerId;                         // preferred: use anchor-assigned ID
  // OR identify by account:
  // ..account = 'GABC...'
  // ..memo = '12345'  // for shared accounts

// Returns http.Response directly — NOT GetCustomerInfoResponse
http.Response response = await kycService.putCustomerCallback(request);
print('HTTP ${response.statusCode}');  // 200 on success
```

The anchor POSTs to your callback URL with the same JSON body as `GET /customer` responses. The payload is signed with `Signature` and `X-Stellar-Signature` headers using the anchor's `SIGNING_KEY`.

---

## Post customer file

Upload a file and receive a `file_id` to reference in subsequent `PUT /customer` requests. Useful when the anchor requires `application/json` bodies (which don't support binary data directly).

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Upload the file — takes Uint8List and jwt string
final fileBytes = await File('passport_front.jpg').readAsBytes();
final fileResponse = await kycService.postCustomerFile(fileBytes, jwtToken);

// CustomerFileResponse has public properties (NOT getter methods)
print('File ID: ${fileResponse.fileId}');           // String
print('Content-Type: ${fileResponse.contentType}'); // String
print('Size: ${fileResponse.size} bytes');          // int
print('Customer ID: ${fileResponse.customerId}');   // String? (null if not yet linked)

if (fileResponse.expiresAt != null) {
  // String? ISO 8601 timestamp; file is discarded if not linked by this time
  print('Expires: ${fileResponse.expiresAt}');
}

// Reference the file in a customer PUT using field name + _file_id suffix
final request = PutCustomerInfoRequest()
  ..jwt = jwtToken
  ..id = customerId
  ..customFields = {
    'photo_id_front_file_id': fileResponse.fileId,
  };

final response = await kycService.putCustomerInfo(request);
```

Method signature:
```
Future<CustomerFileResponse> postCustomerFile(Uint8List file, String jwt)
```

Note: The file data is sent as a multipart field named `"file"` via `multipart/form-data`.

---

## Get customer files

Retrieve information about uploaded files, either by file ID or customer ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Get a specific file by ID (named parameter)
final response = await kycService.getCustomerFiles(jwtToken, fileId: 'file_abc123');

// Get all files for a customer (named parameter)
final response2 = await kycService.getCustomerFiles(jwtToken, customerId: customerId);

// Get all files for the authenticated account (no filter)
final response3 = await kycService.getCustomerFiles(jwtToken);

// response.files is List<CustomerFileResponse>
for (final file in response.files) {
  print('${file.fileId}: ${file.contentType} (${file.size} bytes)');
  if (file.customerId != null) {
    print('  Linked to customer: ${file.customerId}');
  }
  if (file.expiresAt != null) {
    print('  Expires: ${file.expiresAt}');
  }
}
```

Method signature:
```
Future<GetCustomerFilesResponse> getCustomerFiles(String jwt, {String? fileId, String? customerId})
```

`GetCustomerFilesResponse` has one property: `List<CustomerFileResponse> files` (empty list when no files found, never null).

---

## Delete customer

Delete all personal data stored by the anchor for a given Stellar account. Used for GDPR compliance or account closure.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// First argument is the Stellar account ID (G... address) — NOT the customer UUID
http.Response response = await kycService.deleteCustomer(
  accountId,   // String — Stellar G... address
  null,        // String? memo
  null,        // String? memoType
  jwtToken,    // String jwt
);

print('HTTP ${response.statusCode}');  // 200 on success

// For shared/omnibus accounts, include memo to identify the specific customer
http.Response response2 = await kycService.deleteCustomer(
  accountId,
  '12345',   // memo
  'id',      // memoType (deprecated but supported for compatibility)
  jwtToken,
);
```

Method signature:
```
Future<http.Response> deleteCustomer(String account, String? memo, String? memoType, String jwt)
```

---

## Error handling

`getCustomerInfo()` and `putCustomerInfo()` throw `ErrorResponse` on HTTP errors (4xx, 5xx). `putCustomerCallback()` and `deleteCustomer()` return `http.Response` directly — check `statusCode` manually.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

try {
  final request = GetCustomerInfoRequest()
    ..jwt = jwtToken
    ..id = customerId;
  final response = await kycService.getCustomerInfo(request);

  switch (response.status) {
    case 'ACCEPTED':
      print('Verified — proceed with transaction');
      break;
    case 'PROCESSING':
      print('Under review: ${response.message}');
      break;
    case 'NEEDS_INFO':
      response.fields?.forEach((name, field) {
        print('Required: $name — ${field.description}');
      });
      break;
    case 'REJECTED':
      print('Rejected: ${response.message}');
      break;
  }

} on ErrorResponse catch (e) {
  // e.code — int HTTP status code (400, 401, 403, 404, etc.)
  // e.body — String response body (JSON with "error" key typically)
  print('HTTP error ${e.code}: ${e.body}');
  switch (e.code) {
    case 400:
      print('Bad request — check parameters');
      break;
    case 401:
      print('Authentication failed — JWT may be expired or invalid');
      break;
    case 403:
      print('Forbidden — JWT account does not match requested customer');
      break;
    case 404:
      print('Customer not found');
      break;
    default:
      print('Unexpected error: ${e.code}');
  }
} catch (e) {
  print('Network or unexpected error: $e');
}
```

`postCustomerFile()` throws `ErrorResponse` on HTTP 413 (file too large) or 400 (invalid file format).

---

## Response reference

### GetCustomerInfoResponse

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String?` | Anchor-assigned customer ID (null if no record yet) |
| `status` | `String` | `ACCEPTED`, `PROCESSING`, `NEEDS_INFO`, or `REJECTED` |
| `message` | `String?` | Human-readable message; required when `REJECTED` |
| `fields` | `Map<String, GetCustomerInfoField>?` | Fields still needed (keyed by SEP-9 field name) |
| `providedFields` | `Map<String, GetCustomerInfoProvidedField>?` | Fields already received (keyed by SEP-9 field name) |

### GetCustomerInfoField

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | `"string"`, `"binary"`, `"number"`, or `"date"` |
| `description` | `String?` | Human-readable description |
| `optional` | `bool?` | `null`/`false` = required; `true` = optional |
| `choices` | `List<String>?` | Valid values; returns `[]` (not `null`) when unconstrained |

### GetCustomerInfoProvidedField

Same properties as `GetCustomerInfoField`, plus:

| Property | Type | Description |
|----------|------|-------------|
| `status` | `String?` | `ACCEPTED`, `PROCESSING`, `REJECTED`, or `VERIFICATION_REQUIRED` |
| `error` | `String?` | Rejection reason when status is `REJECTED` |

### PutCustomerInfoResponse

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Anchor-assigned customer ID (non-null) |

### CustomerFileResponse

Public properties (no getter methods):

| Property | Type | Description |
|----------|------|-------------|
| `fileId` | `String` | Unique file identifier |
| `contentType` | `String` | MIME type of the file |
| `size` | `int` | File size in bytes |
| `expiresAt` | `String?` | ISO 8601 expiry timestamp, or `null` |
| `customerId` | `String?` | Linked customer ID, or `null` |

### GetCustomerFilesResponse

| Property | Type | Description |
|----------|------|-------------|
| `files` | `List<CustomerFileResponse>` | List of files; empty list if none |

---

## Common pitfalls

**WRONG: birthDate, idIssueDate, idExpirationDate expect DateTime — not strings**

```dart
// WRONG: strings are not accepted for these typed DateTime? properties
personFields.birthDate = '1990-05-15';         // compile error
personFields.idIssueDate = '2020-01-15';       // compile error
personFields.idExpirationDate = '2030-01-15';  // compile error

// CORRECT: DateTime objects
personFields.birthDate = DateTime(1990, 5, 15);
personFields.idIssueDate = DateTime(2020, 1, 15);
personFields.idExpirationDate = DateTime(2030, 1, 15);
// The SDK serializes date fields as YYYY-MM-DD (date only) per the SEP-9 spec
```

**WRONG: occupation is int, not String**

```dart
// WRONG: string — occupation is typed int?
personFields.occupation = '2512';  // compile error

// CORRECT: int (ISCO-08 code)
personFields.occupation = 2512;
```

**WRONG: VATNumber is mixed-case — not vatNumber**

```dart
// WRONG: property does not exist
orgFields.vatNumber = 'DE123456789';  // compile error

// CORRECT: uppercase VAT
orgFields.VATNumber = 'DE123456789';
// Sent to the server as 'organization.VAT_number'
```

**WRONG: OrganizationKYCFields.registrationDate is String, not DateTime**

```dart
// WRONG: DateTime — registrationDate is typed String?, not DateTime?
orgFields.registrationDate = DateTime(2010, 6, 15);  // compile error

// CORRECT: ISO 8601 string
orgFields.registrationDate = '2010-06-15';
// (Unlike NaturalPersonKYCFields.birthDate which IS a DateTime)
```

**WRONG: accessing CustomerFileResponse via getter methods — it has public properties**

```dart
// WRONG: there are no getter methods on CustomerFileResponse
final id = fileResponse.getFileId();          // NoSuchMethodError at runtime
final ct = fileResponse.getContentType();     // NoSuchMethodError at runtime

// CORRECT: access public properties directly
final id = fileResponse.fileId;
final ct = fileResponse.contentType;
final sz = fileResponse.size;
final ex = fileResponse.expiresAt;
final cu = fileResponse.customerId;
```

**WRONG: accessing GetCustomerFilesResponse.files via a getter**

```dart
// WRONG: no getter method on GetCustomerFilesResponse
final files = response.getFiles();  // NoSuchMethodError at runtime

// CORRECT: public property
final files = response.files;  // List<CustomerFileResponse>
```

**WRONG: putCustomerVerification() returns GetCustomerInfoResponse, not PutCustomerInfoResponse**

```dart
// WRONG: treating the return value as PutCustomerInfoResponse
// ignore: deprecated_member_use
final response = await kycService.putCustomerVerification(request);
// response.id is available — but it's GetCustomerInfoResponse.id (String?)
// Use response.status to check verification result
print(response.status);  // ACCEPTED, NEEDS_INFO, etc.
```

**WRONG: deleteCustomer() first parameter is the Stellar account ID, not the customer UUID**

```dart
// WRONG: passing the anchor-assigned customer UUID
await kycService.deleteCustomer(customerId, null, null, jwtToken);  // 404

// CORRECT: first argument is the Stellar account G... address
await kycService.deleteCustomer('GABC...stellarAccountId', null, null, jwtToken);
```

**WRONG: deleteCustomer() and putCustomerCallback() don't throw on HTTP errors**

```dart
// These methods return http.Response directly — check statusCode manually
final response = await kycService.deleteCustomer(accountId, null, null, jwtToken);
if (response.statusCode != 200) {
  print('Delete failed: ${response.statusCode}');
}

// putCustomerCallback() is the same
final cbResponse = await kycService.putCustomerCallback(request);
if (cbResponse.statusCode != 200) {
  print('Callback registration failed: ${cbResponse.statusCode}');
}
```

---

## Customer statuses

| Status | Meaning |
|--------|---------|
| `ACCEPTED` | All required info verified. Customer may proceed. |
| `PROCESSING` | Info under review. Check back later. |
| `NEEDS_INFO` | Additional fields required. See `fields`. |
| `REJECTED` | Permanently rejected. See `message` for reason. |

## Field statuses

| Status | Meaning |
|--------|---------|
| `ACCEPTED` | Field validated. |
| `PROCESSING` | Field under review. |
| `REJECTED` | Field rejected. See `error` for reason. |
| `VERIFICATION_REQUIRED` | Code sent to customer (SMS/email); submit code with `_verification` suffix via `customFields`. |

---
