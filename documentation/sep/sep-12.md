# SEP-12: KYC API

The [SEP-12](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md) protocol defines how to submit and manage customer information for Know Your Customer (KYC) requirements. Anchors use this to collect identity documents, personal information, and verification data before processing deposits, withdrawals, or payments.

Use SEP-12 when:
- An anchor requires identity verification before deposit/withdrawal
- You need to check what KYC information an anchor requires
- You want to update previously submitted customer information
- You need to verify contact information (phone, email)

This SDK implements SEP-12 v1.15.0.

## Table of Contents

- [Quick example](#quick-example)
- [Creating the KYC service](#creating-the-kyc-service)
- [Checking customer status](#checking-customer-status)
- [Submitting customer information](#submitting-customer-information)
  - [Personal information](#personal-information)
  - [Complete natural person fields](#complete-natural-person-fields)
  - [Financial account information](#financial-account-information)
  - [Uploading ID documents](#uploading-id-documents)
  - [Organization KYC](#organization-kyc)
- [Verifying contact information](#verifying-contact-information)
- [File upload endpoint](#file-upload-endpoint)
- [Callback notifications](#callback-notifications)
- [Deleting customer data](#deleting-customer-data)
- [Shared/omnibus accounts](#sharedomnibus-accounts)
- [Contract accounts (C... addresses)](#contract-accounts-c-addresses)
- [Transaction-based KYC](#transaction-based-kyc)
- [Error handling](#error-handling)
- [Customer statuses](#customer-statuses)
- [Field statuses](#field-statuses)
- [Related specifications](#related-specifications)

## Quick example

This example shows the typical KYC workflow: create the service, check what information is needed, then submit customer data.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Create service from anchor's domain (discovers URL from stellar.toml)
final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Check what info the anchor needs (requires JWT token from SEP-10 or SEP-45)
final request = GetCustomerInfoRequest();
request.jwt = jwtToken;
final response = await kycService.getCustomerInfo(request);

print('Status: ${response.status}');

// Submit customer information
final personFields = NaturalPersonKYCFields();
personFields.firstName = 'Jane';
personFields.lastName = 'Doe';
personFields.emailAddress = 'jane@example.com';

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final putRequest = PutCustomerInfoRequest();
putRequest.jwt = jwtToken;
putRequest.kycFields = kycFields;

final putResponse = await kycService.putCustomerInfo(putRequest);
final customerId = putResponse.id; // Save for future requests
```

## Creating the KYC service

### From Domain (Recommended)

The recommended approach discovers the KYC service URL automatically from the anchor's `stellar.toml` file. This uses the `KYC_SERVER` or `TRANSFER_SERVER` endpoint.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

// Loads service URL from stellar.toml automatically
final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// With custom HTTP client (for timeouts, proxies, etc.)
final httpClient = http.Client();
final kycService2 = await KYCService.fromDomain(
  'testanchor.stellar.org',
  httpClient: httpClient,
  httpRequestHeaders: {'User-Agent': 'MyWallet/1.0'},
);
```

### From Direct URL

Use this when you already know the KYC service endpoint URL.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = KYCService('https://api.anchor.com/kyc');
```

## Checking customer status

Before submitting data, check what fields the anchor requires. The response includes the customer's current verification status and lists required fields.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final request = GetCustomerInfoRequest();
request.jwt = jwtToken; // Required: JWT from SEP-10 or SEP-45

// For existing customers, include their ID for faster lookup
request.id = customerId;

// Specify the type of operation (affects which fields are required)
request.type = 'sep6-deposit'; // or "sep6-deposit", etc.

// Request field descriptions in a specific language
request.lang = 'de'; // ISO 639-1 code, defaults to "en"

final response = await kycService.getCustomerInfo(request);

// Check customer status
final status = response.status;
print('Status: $status'); // ACCEPTED, PROCESSING, NEEDS_INFO, or REJECTED

// Get customer ID (if registered)
final id = response.id;

// Get human-readable status message
final message = response.message;

// Check which fields are still needed
final fieldsNeeded = response.fields;
if (fieldsNeeded != null) {
  fieldsNeeded.forEach((fieldName, field) {
    print('Field: $fieldName');
    print('  Type: ${field.type}'); // string, binary, number, date
    print('  Description: ${field.description}');
    final required = (field.optional == true) ? 'No' : 'Yes';
    print('  Required: $required');

    // Some fields have predefined valid values
    if (field.choices != null && field.choices!.isNotEmpty) {
      print('  Valid values: ${field.choices!.join(", ")}');
    }
  });
}

// Check fields already provided and their verification status
final providedFields = response.providedFields;
if (providedFields != null) {
  providedFields.forEach((fieldName, field) {
    print('Provided: $fieldName');
    print('  Status: ${field.status}'); // ACCEPTED, PROCESSING, REJECTED, VERIFICATION_REQUIRED

    // If rejected, get the reason
    if (field.status == 'REJECTED') {
      print('  Error: ${field.error}');
    }
  });
}
```

## Submitting customer information

### Personal information

Submit basic personal information for individual customers. The `StandardKYCFields` container holds `NaturalPersonKYCFields` for individuals or `OrganizationKYCFields` for businesses.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final personFields = NaturalPersonKYCFields();
personFields.firstName = 'Jane';
personFields.lastName = 'Doe';
personFields.emailAddress = 'jane@example.com';
personFields.mobileNumber = '+14155551234'; // E.164 format
personFields.birthDate = DateTime(1990, 5, 15); // DateTime object

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.kycFields = kycFields;
request.type = 'sep6-deposit';

final response = await kycService.putCustomerInfo(request);
final customerId = response.id; // Save this for future requests
```

### Complete natural person fields

The SDK supports all SEP-9 standard fields for natural persons. Here's a complete example showing all available fields.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final personFields = NaturalPersonKYCFields();

// Name fields
personFields.firstName = 'Jane';
personFields.lastName = 'Doe';
personFields.additionalName = 'Marie'; // Middle name

// Address fields
personFields.address = '123 Main St, Apt 4B';
personFields.city = 'San Francisco';
personFields.stateOrProvince = 'CA';
personFields.postalCode = '94102';
personFields.addressCountryCode = 'USA'; // ISO 3166-1 alpha-3

// Contact information
personFields.mobileNumber = '+14155551234'; // E.164 format
personFields.mobileNumberFormat = 'E.164'; // Optional: specify format
personFields.emailAddress = 'jane@example.com';
personFields.languageCode = 'en'; // ISO 639-1

// Birth information — DateTime objects, NOT strings
personFields.birthDate = DateTime(1990, 5, 15); // Serialized as YYYY-MM-DD
personFields.birthPlace = 'New York, NY, USA';
personFields.birthCountryCode = 'USA'; // ISO 3166-1 alpha-3

// Tax information
personFields.taxId = '123-45-6789';
personFields.taxIdName = 'SSN'; // or "ITIN", etc.

// Employment
personFields.occupation = 2512; // int (ISCO-08 code), NOT a string
personFields.employerName = 'Acme Corp';
personFields.employerAddress = '456 Business Ave, New York, NY 10001';

// Identity document — date fields are DateTime objects
personFields.idType = 'passport'; // or "drivers_license", "id_card"
personFields.idNumber = 'AB123456';
personFields.idCountryCode = 'USA'; // ISO 3166-1 alpha-3
personFields.idIssueDate = DateTime(2020, 1, 15);
personFields.idExpirationDate = DateTime(2030, 1, 15);

// Other fields
personFields.sex = 'female'; // or "male", "other"
personFields.ipAddress = '192.168.1.1';
personFields.referralId = 'REF123'; // Referral or origin code

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

### Financial account information

For deposits and withdrawals, anchors often require banking or payment account details. Use `FinancialAccountKYCFields` for this information.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Set up financial account details
final financialFields = FinancialAccountKYCFields();

// Traditional bank account
financialFields.bankName = 'First National Bank';
financialFields.bankAccountType = 'checking'; // or "savings"
financialFields.bankAccountNumber = '1234567890';
financialFields.bankNumber = '021000021'; // Routing number (US)
financialFields.bankBranchNumber = '001';
financialFields.bankPhoneNumber = '+18005551234'; // E.164 format

// International transfer memo
financialFields.externalTransferMemo = 'WIRE-REF-12345';

// Mexico CLABE
financialFields.clabeNumber = '032180000118359719';

// Argentina CBU/CVU
financialFields.cbuNumber = '0110000000001234567890';
financialFields.cbuAlias = 'mi.cuenta.arg';

// Mobile money (for regions using mobile payments)
financialFields.mobileMoneyNumber = '+254712345678';
financialFields.mobileMoneyProvider = 'M-Pesa';

// Cryptocurrency (if anchor supports crypto payouts)
financialFields.cryptoAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0AB12';

// Attach to person fields
final personFields = NaturalPersonKYCFields();
personFields.firstName = 'Jane';
personFields.lastName = 'Doe';
personFields.financialAccountKYCFields = financialFields;

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

### Uploading ID documents

Binary fields like photos and documents are stored as `Uint8List` and sent via `multipart/form-data` automatically.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Load ID document images as binary data
final idFrontBytes = await File('id_front.jpg').readAsBytes();
final idBackBytes = await File('id_back.jpg').readAsBytes();
final proofOfAddressBytes = await File('utility_bill.pdf').readAsBytes();
final proofOfIncomeBytes = await File('bank_statement.pdf').readAsBytes();
final selfieBytes = await File('selfie_video.mp4').readAsBytes();

final personFields = NaturalPersonKYCFields();

// ID document details
personFields.idType = 'passport';
personFields.idNumber = 'AB123456';
personFields.idCountryCode = 'USA';
personFields.idIssueDate = DateTime(2020, 1, 15);
personFields.idExpirationDate = DateTime(2030, 1, 15);

// Document images (Uint8List)
personFields.photoIdFront = idFrontBytes;
personFields.photoIdBack = idBackBytes;

// Proof of address (utility bill, bank statement)
personFields.photoProofResidence = proofOfAddressBytes;

// Proof of income (for high-value transactions)
personFields.proofOfIncome = proofOfIncomeBytes;

// Liveness proof (video selfie for identity verification)
personFields.proofOfLiveness = selfieBytes;

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.id = customerId; // Update existing customer
request.kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

### Organization KYC

For business/corporate customers, use `OrganizationKYCFields`. All organization fields are automatically prefixed with `organization.` as per SEP-9.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final orgFields = OrganizationKYCFields();

// Company identification
orgFields.name = 'Acme Corporation';
orgFields.VATNumber = 'DE123456789'; // Note: VATNumber, not vatNumber
orgFields.registrationNumber = 'HRB 12345';
orgFields.registrationDate = '2010-06-15'; // String (ISO 8601), NOT DateTime

// Registered address
orgFields.registeredAddress = '456 Business Ave, Suite 100';
orgFields.city = 'New York';
orgFields.stateOrProvince = 'NY';
orgFields.postalCode = '10001';
orgFields.addressCountryCode = 'USA'; // ISO 3166-1 alpha-3

// Corporate structure
orgFields.numberOfShareholders = 3;
orgFields.shareholderName = 'John Smith'; // Ultimate beneficial owner
orgFields.directorName = 'Jane Doe';

// Contact information
orgFields.website = 'https://acme-corp.example.com';
orgFields.email = 'contact@acme-corp.example.com';
orgFields.phone = '+12125551234'; // E.164 format

// Organization's bank account
final orgFinancialFields = FinancialAccountKYCFields();
orgFinancialFields.bankName = 'Business Bank';
orgFinancialFields.bankAccountNumber = '9876543210';
orgFinancialFields.bankNumber = '021000021';
orgFields.financialAccountKYCFields = orgFinancialFields;

final kycFields = StandardKYCFields();
kycFields.organizationKYCFields = orgFields;

final request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.kycFields = kycFields;

final response = await kycService.putCustomerInfo(request);
```

### Using custom fields

If an anchor requires non-standard fields, use `customFields` for text data and `customFiles` for binary data.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.id = customerId;

// Custom text fields
request.customFields = {
  'custom_field_1': 'custom value',
  'anchor_specific_id': 'ABC123',
};

// Custom binary files
request.customFiles = {
  'additional_document': await File('document.pdf').readAsBytes(),
};

final response = await kycService.putCustomerInfo(request);
```

## Verifying contact information

Some anchors require verification of contact information (phone or email) via a confirmation code. When a field has `VERIFICATION_REQUIRED` status, submit the code using the `PUT /customer` endpoint with `_verification` suffix.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// First, check if verification is required
final getRequest = GetCustomerInfoRequest();
getRequest.jwt = jwtToken;
getRequest.id = customerId;
final response = await kycService.getCustomerInfo(getRequest);

final providedFields = response.providedFields;
if (providedFields != null) {
  providedFields.forEach((fieldName, field) {
    if (field.status == 'VERIFICATION_REQUIRED') {
      print('Verification required for: $fieldName');
      // Anchor has sent a code to the customer via SMS or email
    }
  });
}

// Submit verification code via PUT /customer with _verification suffix
final putRequest = PutCustomerInfoRequest();
putRequest.jwt = jwtToken;
putRequest.id = customerId;
putRequest.customFields = {
  'mobile_number_verification': '123456', // Code sent via SMS
};

final verifyResponse = await kycService.putCustomerInfo(putRequest);
print('Customer ID: ${verifyResponse.id}');
```

### Deprecated verification endpoint

The SDK also supports the deprecated `PUT /customer/verification` endpoint for backwards compatibility. New implementations should use the method above instead.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Deprecated: Use PUT /customer with _verification suffix instead
final request = PutCustomerVerificationRequest();
request.jwt = jwtToken;
request.id = customerId;
request.verificationFields = {
  'mobile_number_verification': '123456',
  'email_address_verification': 'ABC123',
};

// Returns GetCustomerInfoResponse (NOT PutCustomerInfoResponse)
final response = await kycService.putCustomerVerification(request);
print('Status: ${response.status}');
```

## File upload endpoint

For complex data structures that require `application/json`, upload files separately using the files endpoint, then reference them by `file_id` in customer requests.

### Upload a file

Upload a file and receive a `file_id` that can be referenced in subsequent `PUT /customer` requests.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Upload file first
final fileBytes = await File('passport_front.jpg').readAsBytes();
final fileResponse = await kycService.postCustomerFile(fileBytes, jwtToken);

print('File ID: ${fileResponse.fileId}');
print('Content-Type: ${fileResponse.contentType}');
print('Size: ${fileResponse.size} bytes');

// Optional: File may expire if not linked to a customer
if (fileResponse.expiresAt != null) {
  print('Expires: ${fileResponse.expiresAt}');
}

// Reference the file in customer data using _file_id suffix
final request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.id = customerId;
request.customFields = {
  'photo_id_front_file_id': fileResponse.fileId,
};

final response = await kycService.putCustomerInfo(request);
```

### Retrieve file information

Get information about previously uploaded files by file ID or customer ID.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Get a specific file by ID
final response = await kycService.getCustomerFiles(jwtToken, fileId: 'file_abc123');
for (final file in response.files) {
  print('File: ${file.fileId}');
  print('  Type: ${file.contentType}');
  print('  Size: ${file.size} bytes');
  if (file.customerId != null) {
    print('  Customer: ${file.customerId}');
  }
}

// Get all files for a customer
final response2 = await kycService.getCustomerFiles(jwtToken, customerId: customerId);
for (final file in response2.files) {
  print('File: ${file.fileId} (${file.contentType})');
}
```

## Callback notifications

Register a callback URL to receive automatic notifications when customer status changes. This avoids polling the `GET /customer` endpoint.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

final request = PutCustomerCallbackRequest();
request.jwt = jwtToken;
request.id = customerId;
request.url = 'https://myapp.com/kyc-callback';

// Optional: identify customer without ID
// request.account = 'GXXXXX...'; // Stellar account
// request.memo = '12345'; // For shared accounts

// Returns http.Response directly
http.Response response = await kycService.putCustomerCallback(request);

if (response.statusCode == 200) {
  print('Callback registered successfully');
}

// Your callback endpoint will receive POST requests with the same
// structure as GET /customer responses, plus a cryptographic signature
// in the Signature header for verification.
```

## Deleting customer data

Request deletion of all stored customer data. This is useful for GDPR compliance or when a customer closes their account.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// First argument is the Stellar account ID (G... address), NOT the customer UUID
final accountId = 'GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

// Delete customer data — returns http.Response directly
http.Response response = await kycService.deleteCustomer(
  accountId, // Stellar G... address
  null,      // memo
  null,      // memoType
  jwtToken,  // JWT
);

if (response.statusCode == 200) {
  print('Customer data deleted successfully');
}

// For shared accounts, include memo
http.Response response2 = await kycService.deleteCustomer(
  accountId,
  '12345',   // memo
  'id',      // memoType (deprecated but supported for compatibility)
  jwtToken,
);
```

## Shared/omnibus accounts

When multiple customers share a single Stellar account (common for exchanges and custodians), use memos to distinguish them. The memo should match the one used during SEP-10 or SEP-45 authentication.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Get customer info with memo
final getRequest = GetCustomerInfoRequest();
getRequest.jwt = jwtToken; // JWT should contain account:memo in sub claim
getRequest.account = 'GXXXXXX...'; // Optional: inferred from JWT
getRequest.memo = '12345'; // Unique identifier for this customer
getRequest.memoType = 'id'; // Deprecated: should always be "id"

final response = await kycService.getCustomerInfo(getRequest);

// Submit customer info with memo
final personFields = NaturalPersonKYCFields();
personFields.firstName = 'Jane';
personFields.lastName = 'Doe';

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final putRequest = PutCustomerInfoRequest();
putRequest.jwt = jwtToken;
putRequest.kycFields = kycFields;
putRequest.memo = '12345'; // Must match JWT's sub value
putRequest.memoType = 'id'; // Deprecated but supported
```

## Contract accounts (C... addresses)

For Soroban contract accounts (addresses starting with `C...`), authenticate using [SEP-45](sep-45.md) instead of SEP-10. The JWT token will contain the contract address.

> **Important:** When using contract accounts (C... addresses), you must **NOT** specify a `memo`. Contract addresses are unique identifiers and do not support memo-based sub-accounts.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Contract account address (starts with C...)
final contractAccount = 'CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

// Get customer info for contract account
// JWT obtained via SEP-45 authentication
final getRequest = GetCustomerInfoRequest();
getRequest.jwt = sep45JwtToken; // From SEP-45 (not SEP-10)
getRequest.account = contractAccount;
// Do NOT set memo for contract accounts!

final response = await kycService.getCustomerInfo(getRequest);

// Submit customer info for contract account
final personFields = NaturalPersonKYCFields();
personFields.firstName = 'Jane';
personFields.lastName = 'Doe';
personFields.emailAddress = 'jane@example.com';

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final putRequest = PutCustomerInfoRequest();
putRequest.jwt = sep45JwtToken;
putRequest.account = contractAccount;
putRequest.kycFields = kycFields;
// Do NOT set memo for contract accounts!

final putResponse = await kycService.putCustomerInfo(putRequest);
```

## Transaction-based KYC

Some anchors require different KYC information based on transaction details (e.g., higher amounts require more verification). Use `transactionId` to link KYC to a specific transaction.

> **Important:** When using `transactionId`, the `type` parameter is **required**. Valid values include:
> - `sep6` - For SEP-6 deposit/withdrawal transactions

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

// Check KYC requirements for a specific transaction
final getRequest = GetCustomerInfoRequest();
getRequest.jwt = jwtToken;
getRequest.transactionId = 'tx_abc123'; // From SEP-6
getRequest.type = 'sep6'; // REQUIRED when using transactionId

final response = await kycService.getCustomerInfo(getRequest);

// For large transactions, anchor may require additional fields
final fieldsNeeded = response.fields;
if (fieldsNeeded != null && fieldsNeeded.containsKey('proof_of_income')) {
  print('Large transaction: proof of income required');
}

// Submit KYC for the transaction
final personFields = NaturalPersonKYCFields();
personFields.firstName = 'Jane';
personFields.lastName = 'Doe';

final kycFields = StandardKYCFields();
kycFields.naturalPersonKYCFields = personFields;

final putRequest = PutCustomerInfoRequest();
putRequest.jwt = jwtToken;
putRequest.kycFields = kycFields;
putRequest.transactionId = 'tx_abc123';
putRequest.type = 'sep6';

final putResponse = await kycService.putCustomerInfo(putRequest);
```

## Error handling

Handle various error conditions that may occur during KYC operations. `getCustomerInfo()` and `putCustomerInfo()` throw `ErrorResponse` on HTTP errors. `putCustomerCallback()` and `deleteCustomer()` return `http.Response` directly -- check `statusCode` manually.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

final kycService = await KYCService.fromDomain('testanchor.stellar.org');

try {
  final request = GetCustomerInfoRequest();
  request.jwt = jwtToken;
  request.id = customerId;

  final response = await kycService.getCustomerInfo(request);

  // Handle different statuses
  switch (response.status) {
    case 'ACCEPTED':
      print('Customer verified! Proceeding...');
      break;
    case 'PROCESSING':
      print('KYC under review. Check back later.');
      print('Message: ${response.message}');
      break;
    case 'NEEDS_INFO':
      print('Additional information required:');
      response.fields?.forEach((name, field) {
        final required = (field.optional == true) ? '(optional)' : '(required)';
        print('  - $name $required: ${field.description}');
      });
      break;
    case 'REJECTED':
      print('KYC rejected: ${response.message}');
      // Customer cannot proceed - may need to contact support
      break;
  }
} on ErrorResponse catch (e) {
  // e.code — HTTP status code (400, 401, 403, 404, etc.)
  // e.body — response body (JSON with "error" key typically)
  print('HTTP error ${e.code}: ${e.body}');
  switch (e.code) {
    case 400:
      print('Bad request — check parameters');
      break;
    case 401:
      print('Authentication failed — JWT may be expired');
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

## Customer statuses

The `status` field in `GetCustomerInfoResponse` indicates the customer's position in the KYC process:

| Status | Description |
|--------|-------------|
| `ACCEPTED` | All required KYC fields accepted. Customer can proceed with transactions. May revert if issues found later. |
| `PROCESSING` | KYC information is being reviewed. Check back later for updates. |
| `NEEDS_INFO` | Additional information required. Check `fields` map for what's needed. |
| `REJECTED` | KYC permanently rejected. Customer cannot use the service. Check `message` for reason. |

## Field statuses

The `status` field in `GetCustomerInfoProvidedField` indicates the verification state of individual fields:

| Status | Description |
|--------|-------------|
| `ACCEPTED` | Field has been validated and accepted. |
| `PROCESSING` | Field is being reviewed. Check back later. |
| `REJECTED` | Field was rejected. Check `error` for reason. May be resubmitted if customer status is `NEEDS_INFO`. |
| `VERIFICATION_REQUIRED` | Field needs verification (e.g., confirmation code). Submit code with `_verification` suffix. |

## Related specifications

- [SEP-10](sep-10.md) - Web Authentication (provides JWT for KYC requests)
- [SEP-45](sep-45.md) - Web Authentication for Contract Accounts (C... addresses)
- [SEP-9](sep-09.md) - Standard KYC Fields specification
- [SEP-6](sep-06.md) - Deposit and Withdrawal (often requires KYC)
- [SEP-24](sep-24.md) - Interactive Deposit/Withdrawal (often requires KYC)

---

[Back to SEP Overview](README.md)
