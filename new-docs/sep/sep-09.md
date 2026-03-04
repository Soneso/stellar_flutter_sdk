# SEP-09: Standard KYC Fields

SEP-09 defines a standard vocabulary for KYC (Know Your Customer) and AML (Anti-Money Laundering) data fields. When different services need to exchange customer information (deposits, withdrawals, cross-border payments), they use these field names so everyone speaks the same language.

**Use SEP-09 when:**
- Submitting KYC data via SEP-12
- Providing customer info for SEP-24 interactive flows
- Building anchor services that collect customer information

**Spec:** [SEP-0009 v1.18.0](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md)

## Quick Example

This example shows how to create basic KYC fields for an individual customer and prepare them for API submission:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Build KYC fields for an individual
NaturalPersonKYCFields person = NaturalPersonKYCFields();
person.firstName = 'John';
person.lastName = 'Doe';
person.emailAddress = 'john@example.com';
person.birthDate = DateTime(1990, 5, 15);

// Wrap in container for complete KYC submission
StandardKYCFields kyc = StandardKYCFields();
kyc.naturalPersonKYCFields = person;

// Get fields as map for API submission
Map<String, String> fields = person.fields();
// Returns: {'first_name': 'John', 'last_name': 'Doe', ...}
```

## Detailed Usage

### Natural Person Fields

Use `NaturalPersonKYCFields` when collecting KYC data for individual customers. This class covers personal identification, contact information, address, employment, tax, and identity document fields. Note that the spec also accepts `family_name`/`given_name` as aliases for `last_name`/`first_name`, but the SDK uses the more common `lastName`/`firstName` property names:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

NaturalPersonKYCFields person = NaturalPersonKYCFields();

// Personal identification
person.firstName = 'Maria';       // Maps to 'first_name' (spec also accepts 'given_name')
person.lastName = 'Garcia';       // Maps to 'last_name' (spec also accepts 'family_name')
person.additionalName = 'Elena';  // Middle name
person.birthDate = DateTime(1985, 3, 20);  // Serialized as 'YYYY-MM-DD'
person.birthPlace = 'Madrid, Spain';
person.birthCountryCode = 'ESP';  // ISO 3166-1 alpha-3
person.sex = 'female';            // 'male', 'female', or 'other'

// Contact information
person.emailAddress = 'maria@example.com';
person.mobileNumber = '+34612345678';  // E.164 format
person.mobileNumberFormat = 'E.164';   // Specify expected format (optional, defaults to E.164)

// Current address
person.addressCountryCode = 'ESP';     // ISO 3166-1 alpha-3
person.stateOrProvince = 'Madrid';
person.city = 'Madrid';
person.postalCode = '28001';
person.address = 'Calle Mayor 10\n28001 Madrid\nSpain';  // Multi-line full address

// Employment
person.occupation = 2511;  // ISCO-08 code (Software developer)
person.employerName = 'Tech Corp';
person.employerAddress = 'Paseo de la Castellana 50, Madrid';

// Tax information
person.taxId = '12345678Z';
person.taxIdName = 'NIF';  // Name of tax ID type (SSN, ITIN, NIF, etc.)

// Identity document
person.idType = 'passport';                    // 'passport', 'drivers_license', 'id_card', etc.
person.idNumber = 'AB1234567';
person.idCountryCode = 'ESP';                  // ISO 3166-1 alpha-3
person.idIssueDate = DateTime(2020, 1, 15);    // Serialized as 'YYYY-MM-DD'
person.idExpirationDate = DateTime(2030, 1, 14);

// Other
person.languageCode = 'es';           // ISO 639-1
person.ipAddress = '192.168.1.1';
person.referralId = 'partner-12345';  // Origin or referral code

// Convert to map for API submission
Map<String, String> fieldData = person.fields();
```

### Document Uploads

Binary files (photos, documents) are handled separately via `files()`. This separation allows text fields and binary files to be submitted through different API endpoints or form parts as required:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

NaturalPersonKYCFields person = NaturalPersonKYCFields();
person.firstName = 'John';
person.lastName = 'Doe';

// Load raw file bytes - the SDK handles multipart encoding internally
person.photoIdFront = await File('/path/to/passport-front.jpg').readAsBytes();
person.photoIdBack = await File('/path/to/passport-back.jpg').readAsBytes();
person.notaryApprovalOfPhotoId = await File('/path/to/notary-approval.pdf').readAsBytes();
person.photoProofResidence = await File('/path/to/utility-bill.pdf').readAsBytes();
person.proofOfIncome = await File('/path/to/payslip.pdf').readAsBytes();
person.proofOfLiveness = await File('/path/to/selfie-video.mp4').readAsBytes();

// Get text fields and file fields separately
Map<String, String> textFields = person.fields();
Map<String, Uint8List> fileFields = person.files();
```

> **Note:** Do not base64-encode file contents. The SDK sends file data as raw bytes via multipart/form-data.

### Organization Fields

Use `OrganizationKYCFields` for business customers. All organization field keys are automatically prefixed with `organization.` when calling `fields()` to match the SEP-09 dot notation convention:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

OrganizationKYCFields org = OrganizationKYCFields();

// Corporate identity
org.name = 'Acme Corporation S.L.';
org.VATNumber = 'ESB12345678';
org.registrationNumber = 'B-12345678';
org.registrationDate = '2015-06-01';  // ISO 8601 date
org.registeredAddress = 'Calle Gran Via 100, 28013 Madrid, Spain';

// Corporate structure
org.numberOfShareholders = 3;
org.shareholderName = 'John Smith';  // Query recursively for all UBOs
org.directorName = 'Jane Doe';

// Contact details
org.addressCountryCode = 'ESP';  // ISO 3166-1 alpha-3
org.stateOrProvince = 'Madrid';
org.city = 'Madrid';
org.postalCode = '28013';
org.website = 'https://acme-corp.example.com';
org.email = 'compliance@acme-corp.example.com';
org.phone = '+34911234567';  // E.164 format

// Wrap in container
StandardKYCFields kyc = StandardKYCFields();
kyc.organizationKYCFields = org;

// Organization fields use 'organization.' prefix
Map<String, String> fieldData = org.fields();
// Returns: {'organization.name': 'Acme Corporation S.L.', ...}
```

Organization documents can also be uploaded via the `files()` method, which returns fields with the appropriate `organization.` prefix:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

OrganizationKYCFields org = OrganizationKYCFields();
org.name = 'Acme Corporation S.L.';

// Documents (raw bytes)
org.photoIncorporationDoc = await File('/path/to/incorporation.pdf').readAsBytes();
org.photoProofAddress = await File('/path/to/business-utility-bill.pdf').readAsBytes();

// Get text fields and file fields separately
Map<String, String> textFields = org.fields();
Map<String, Uint8List> fileFields = org.files();
// fileFields: {'organization.photo_incorporation_doc': ..., 'organization.photo_proof_address': ...}
```

### Financial Account Fields

`FinancialAccountKYCFields` supports bank accounts, crypto addresses, and mobile money for both individuals and organizations. It covers a wide variety of regional banking formats:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

NaturalPersonKYCFields person = NaturalPersonKYCFields();
person.firstName = 'John';
person.lastName = 'Doe';

// Add bank account details
FinancialAccountKYCFields bankAccount = FinancialAccountKYCFields();
bankAccount.bankName = 'First National Bank';      // Bank name (useful in regions without unified routing)
bankAccount.bankAccountType = 'checking';          // 'checking' or 'savings'
bankAccount.bankAccountNumber = '123456789012';
bankAccount.bankNumber = '021000021';              // Routing number (US)
bankAccount.bankBranchNumber = '001';
bankAccount.bankPhoneNumber = '+12025551234';      // Bank contact number (E.164)

// Regional bank formats
bankAccount.clabeNumber = '012345678901234567';          // Mexico (CLABE)
bankAccount.cbuNumber = '0123456789012345678901';        // Argentina (CBU or CVU)
bankAccount.cbuAlias = 'john.doe.acme';                  // Argentina (CBU/CVU alias)

// Mobile money (common in Africa and Asia)
bankAccount.mobileMoneyNumber = '+254712345678';         // May differ from personal mobile
bankAccount.mobileMoneyProvider = 'M-Pesa';

// Crypto
bankAccount.cryptoAddress = 'GBH4TZYZ4IRCPO44CBOLFUHULU2WGALXTAVESQA6432MBJMABBB4GIYI';
bankAccount.externalTransferMemo = 'user-12345';         // Destination tag/memo

// Note: cryptoMemo is deprecated - use externalTransferMemo instead

// Attach to person
person.financialAccountKYCFields = bankAccount;

// fields() includes nested financial account fields
Map<String, String> allFields = person.fields();
```

### Card Fields

`CardKYCFields` handles credit and debit card information. All card field keys are prefixed with `card.` to distinguish them from other fields. When possible, prefer using tokenized card data to minimize PCI-DSS compliance scope:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

NaturalPersonKYCFields person = NaturalPersonKYCFields();
person.firstName = 'John';
person.lastName = 'Doe';

CardKYCFields card = CardKYCFields();

// Card details
card.number = '4111111111111111';
card.expirationDate = '29-11';  // YY-MM format (November 2029)
card.cvc = '123';
card.holderName = 'JOHN DOE';
card.network = 'Visa';          // Visa, Mastercard, AmEx, etc.

// Billing address
card.address = '123 Main St\nApt 4B';
card.city = 'New York';
card.stateOrProvince = 'NY';    // ISO 3166-2 format
card.postalCode = '10001';
card.countryCode = 'US';        // ISO 3166-1 alpha-2 (note: 2-letter for cards)

// Prefer tokens over raw card numbers for PCI-DSS compliance
card.token = 'tok_visa_4242';   // From Stripe, etc.

person.cardKYCFields = card;

// Card fields use 'card.' prefix
Map<String, String> allFields = person.fields();
// Includes: {'card.number': '4111...', 'card.expiration_date': '29-11', ...}
```

### Combining with Organizations

Organizations can also have financial accounts and cards. When nested under an organization, financial account fields automatically receive the `organization.` prefix via the internal prefix parameter:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

OrganizationKYCFields org = OrganizationKYCFields();
org.name = 'Acme Corp';
org.VATNumber = 'US12-3456789';

FinancialAccountKYCFields bankAccount = FinancialAccountKYCFields();
bankAccount.bankName = 'Business Bank';
bankAccount.bankAccountNumber = '9876543210';
bankAccount.bankNumber = '021000021';

org.financialAccountKYCFields = bankAccount;

// Organization financial fields get the 'organization.' prefix automatically
Map<String, String> fields = org.fields();
// Returns: {'organization.name': 'Acme Corp', 'organization.bank_name': 'Business Bank', ...}
```

### Using Field Key Constants

Each KYC class exposes field key constants, which is useful when you need to reference specific fields programmatically or build custom field mappings:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Natural person field keys
print(NaturalPersonKYCFields.first_name_field_key);              // 'first_name'
print(NaturalPersonKYCFields.last_name_field_key);               // 'last_name'
print(NaturalPersonKYCFields.email_address_field_key);           // 'email_address'
print(NaturalPersonKYCFields.birth_date_field_key);              // 'birth_date'
print(NaturalPersonKYCFields.mobile_number_format_field_key);    // 'mobile_number_format'
print(NaturalPersonKYCFields.photo_id_front_file_key);           // 'photo_id_front'
print(NaturalPersonKYCFields.referral_id_field_key);             // 'referral_id'

// Organization field keys (includes prefix)
print(OrganizationKYCFields.key_prefix);                         // 'organization.'
print(OrganizationKYCFields.name_field_key);                     // 'organization.name'
print(OrganizationKYCFields.VAT_number_field_key);               // 'organization.VAT_number'
print(OrganizationKYCFields.registration_number_field_key);      // 'organization.registration_number'

// Financial account field keys
print(FinancialAccountKYCFields.bank_name_field_key);            // 'bank_name'
print(FinancialAccountKYCFields.bank_account_type_field_key);    // 'bank_account_type'
print(FinancialAccountKYCFields.clabe_number_field_key);         // 'clabe_number'
print(FinancialAccountKYCFields.cbu_number_field_key);           // 'cbu_number'
print(FinancialAccountKYCFields.mobile_money_number_field_key);  // 'mobile_money_number'
print(FinancialAccountKYCFields.external_transfer_memo_field_key); // 'external_transfer_memo'
print(FinancialAccountKYCFields.crypto_address_field_key);       // 'crypto_address'

// Card field keys (includes prefix)
print(CardKYCFields.number_field_key);                           // 'card.number'
print(CardKYCFields.expiration_date_field_key);                  // 'card.expiration_date'
print(CardKYCFields.token_field_key);                            // 'card.token'
print(CardKYCFields.holder_name_field_key);                      // 'card.holder_name'
```

### Integration with SEP-12

These KYC field classes work directly with the SEP-12 KYC service. Here's how to submit KYC data to an anchor:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// Build the KYC fields
NaturalPersonKYCFields person = NaturalPersonKYCFields();
person.firstName = 'John';
person.lastName = 'Doe';
person.emailAddress = 'john@example.com';

StandardKYCFields kyc = StandardKYCFields();
kyc.naturalPersonKYCFields = person;

// Create KYC service and submit
KYCService kycService = KYCService('https://anchor.example.com/kyc');

PutCustomerInfoRequest request = PutCustomerInfoRequest();
request.jwt = jwtToken;  // From SEP-10 authentication
request.kycFields = kyc;

try {
  PutCustomerInfoResponse response = await kycService.putCustomerInfo(request);
  print('Customer ID: ${response.id}');
} catch (e) {
  // Handle errors (network issues, validation failures, etc.)
  print('KYC submission failed: $e');
}
```

## Field Reference

### Natural Person Fields

| Field | Type | Description |
|-------|------|-------------|
| `first_name`, `last_name` | String | Name fields (spec also accepts `given_name`, `family_name`) |
| `additional_name` | String | Middle name or other additional name |
| `email_address` | String | Email (RFC 5322) |
| `mobile_number` | String | Phone (E.164 format by default) |
| `mobile_number_format` | String | Expected format of mobile_number (e.g., E.164, hash) |
| `birth_date` | DateTime | Date of birth (serialized as YYYY-MM-DD) |
| `birth_place` | String | Place of birth as on passport |
| `birth_country_code` | String | ISO 3166-1 alpha-3 |
| `sex` | String | male, female, other |
| `address` | String | Full address as multi-line string |
| `city`, `postal_code` | String | Address fields |
| `state_or_province` | String | State/province/region name |
| `address_country_code` | String | ISO 3166-1 alpha-3 |
| `id_type` | String | passport, drivers_license, id_card |
| `id_number`, `id_country_code` | String | Document details |
| `id_issue_date`, `id_expiration_date` | DateTime | Document dates (serialized as YYYY-MM-DD) |
| `tax_id`, `tax_id_name` | String | Tax information |
| `occupation` | int | ISCO-08 code |
| `employer_name`, `employer_address` | String | Employment details |
| `language_code` | String | ISO 639-1 code |
| `ip_address` | String | Customer's IP address |
| `referral_id` | String | Origin or referral code |

**File fields** (Uint8List):

| Field | Description |
|-------|-------------|
| `photo_id_front` | Front of photo ID or passport |
| `photo_id_back` | Back of photo ID or passport |
| `notary_approval_of_photo_id` | Notary approval of photo ID |
| `photo_proof_residence` | Utility bill, bank statement, etc. |
| `proof_of_income` | Income verification document |
| `proof_of_liveness` | Video or image as liveness proof |

### Organization Fields

All prefixed with `organization.`:

| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Legal name as on incorporation |
| `VAT_number`, `registration_number` | String | Corporate IDs |
| `registration_date` | String | Date registered (ISO 8601) |
| `registered_address` | String | Legal address |
| `number_of_shareholders` | int | Shareholder count |
| `shareholder_name`, `director_name` | String | Key persons |
| `address_country_code` | String | ISO 3166-1 alpha-3 |
| `state_or_province`, `city`, `postal_code` | String | Address fields |
| `website`, `email`, `phone` | String | Contact info |

**File fields** (Uint8List, prefixed with `organization.`):

| Field | Description |
|-------|-------------|
| `photo_incorporation_doc` | Incorporation documents |
| `photo_proof_address` | Business utility bill, bank statement |

### Financial Account Fields

| Field | Type | Description |
|-------|------|-------------|
| `bank_name` | String | Bank name (useful in regions without unified routing) |
| `bank_account_type` | String | checking, savings |
| `bank_account_number`, `bank_number` | String | Account/routing numbers |
| `bank_branch_number` | String | Branch identifier |
| `bank_phone_number` | String | Bank contact (E.164) |
| `clabe_number` | String | Mexico (CLABE) |
| `cbu_number`, `cbu_alias` | String | Argentina (CBU/CVU) |
| `mobile_money_number` | String | Mobile money phone (E.164) |
| `mobile_money_provider` | String | Mobile money service name |
| `crypto_address` | String | Cryptocurrency address |
| `external_transfer_memo` | String | Destination tag/memo |
| `crypto_memo` | String | **Deprecated** - use `external_transfer_memo` |

### Card Fields

All prefixed with `card.`:

| Field | Type | Description |
|-------|------|-------------|
| `number`, `cvc` | String | Card number and security code |
| `expiration_date` | String | YY-MM format (e.g., 29-11) |
| `holder_name`, `network` | String | Cardholder and brand |
| `token` | String | Payment processor token |
| `address`, `city`, `state_or_province` | String | Billing address |
| `postal_code` | String | Billing postal code |
| `country_code` | String | ISO 3166-1 alpha-2 (2-letter) |

## Error Handling

When submitting KYC data via SEP-12, various errors can occur. Here's how to handle common scenarios:

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

NaturalPersonKYCFields person = NaturalPersonKYCFields();
person.firstName = 'John';
person.lastName = 'Doe';

StandardKYCFields kyc = StandardKYCFields();
kyc.naturalPersonKYCFields = person;

KYCService kycService = KYCService('https://anchor.example.com/kyc');
PutCustomerInfoRequest request = PutCustomerInfoRequest();
request.jwt = jwtToken;
request.kycFields = kyc;

try {
  PutCustomerInfoResponse response = await kycService.putCustomerInfo(request);
  print('Success! Customer ID: ${response.id}');
} catch (e) {
  // The SDK throws exceptions for HTTP errors and network issues.
  // Check the exception message for details about the failure
  // (invalid fields, auth errors, customer not found, etc.)
  print('KYC submission failed: $e');
}
```

## Security Considerations

- **Transmit over HTTPS only** - KYC data contains sensitive PII
- **Encrypt at rest** - Store collected data encrypted
- **Card data requires PCI-DSS** - Prefer tokenization over raw card numbers
- **Minimize collection** - Only request fields you actually need
- **Respect data regulations** - GDPR, CCPA, and local privacy laws apply
- **Use secure file handling** - Validate and sanitize uploaded documents
- **Implement access controls** - Audit logging and proper authorization

## Related SEPs

- [SEP-12](sep-12.md) - KYC API (submits SEP-09 fields to anchors)
- [SEP-24](sep-24.md) - Interactive deposit/withdrawal (may collect SEP-09 data)

---

[Back to SEP Overview](README.md)
