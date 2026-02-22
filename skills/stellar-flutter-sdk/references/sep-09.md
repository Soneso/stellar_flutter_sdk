# SEP-09: Standard KYC Fields

**Purpose:** Standard vocabulary for KYC (Know Your Customer) and AML (Anti-Money Laundering) data fields.
**Prerequisites:** None
**Standard:** [SEP-0009 v1.18.0](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md)

SEP-09 fields are used by [SEP-12](sep-12.md) (`PutCustomerInfoRequest.kycFields`), SEP-24, and SEP-31.

## Table of Contents

- [Class overview](#class-overview)
- [StandardKYCFields container](#standardkycfields-container)
- [NaturalPersonKYCFields](#naturalpersonkycfields)
  - [All properties](#all-properties)
  - [File properties](#file-properties)
  - [fields() and files() output](#fields-and-files-output)
- [OrganizationKYCFields](#organizationkycfields)
  - [All properties](#all-properties-1)
  - [File properties](#file-properties-1)
  - [Organization prefix behavior](#organization-prefix-behavior)
- [FinancialAccountKYCFields](#financialaccountkycfields)
  - [All properties](#all-properties-2)
  - [keyPrefix parameter](#keyprefix-parameter)
- [CardKYCFields](#cardkycfields)
  - [All properties](#all-properties-3)
- [Field key constants](#field-key-constants)
- [Complete example: natural person with bank account](#complete-example-natural-person-with-bank-account)
- [Complete example: organization](#complete-example-organization)
- [Integration with SEP-12](#integration-with-sep-12)
- [Common pitfalls](#common-pitfalls)

---

## Class overview

| Class | Purpose | Prefix on `fields()` |
|-------|---------|----------------------|
| `StandardKYCFields` | Container for natural person + organization | n/a (no `fields()` method) |
| `NaturalPersonKYCFields` | Individual customer data | none |
| `OrganizationKYCFields` | Business/entity data | `organization.` |
| `FinancialAccountKYCFields` | Bank, mobile money, crypto | none (or prefix from parent) |
| `CardKYCFields` | Credit/debit card data | `card.` |

---

## StandardKYCFields container

`StandardKYCFields` is a simple container with two public properties. It does **not** have its own `fields()` method — call `fields()` on the nested objects directly, or pass the container to `PutCustomerInfoRequest.kycFields`.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

StandardKYCFields kyc = StandardKYCFields();

// Either or both may be set
kyc.naturalPersonKYCFields = NaturalPersonKYCFields();   // NaturalPersonKYCFields?
kyc.organizationKYCFields  = OrganizationKYCFields();    // OrganizationKYCFields?
```

---

## NaturalPersonKYCFields

### All properties

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

NaturalPersonKYCFields p = NaturalPersonKYCFields();

// Identity
p.lastName       = 'Doe';          // String?  → 'last_name'
p.firstName      = 'John';         // String?  → 'first_name'
p.additionalName = 'Michael';      // String?  → 'additional_name' (middle name)
p.sex            = 'male';         // String?  → 'sex' (male | female | other)

// Birth
p.birthDate        = DateTime(1990, 5, 15);  // DateTime?  → 'birth_date' (via toIso8601String())
p.birthPlace       = 'New York, NY';         // String?    → 'birth_place'
p.birthCountryCode = 'USA';                  // String?    → 'birth_country_code' (ISO 3166-1 alpha-3)

// Contact
p.emailAddress      = 'john@example.com';  // String? → 'email_address'
p.mobileNumber      = '+14155551234';      // String? → 'mobile_number' (E.164)
p.mobileNumberFormat = 'E.164';            // String? → 'mobile_number_format' (optional clarifier)

// Current address
p.address            = '123 Main St\nNew York, NY 10001'; // String? → 'address' (multi-line ok)
p.city               = 'New York';    // String? → 'city'
p.stateOrProvince    = 'NY';          // String? → 'state_or_province'
p.postalCode         = '10001';       // String? → 'postal_code'
p.addressCountryCode = 'USA';         // String? → 'address_country_code' (ISO 3166-1 alpha-3)

// Identity document (text fields only — images are file properties below)
p.idType          = 'passport';              // String?   → 'id_type' (passport | drivers_license | id_card | etc.)
p.idNumber        = 'AB123456';             // String?   → 'id_number'
p.idCountryCode   = 'USA';                  // String?   → 'id_country_code' (ISO 3166-1 alpha-3)
p.idIssueDate     = DateTime(2020, 1, 15);  // DateTime? → 'id_issue_date' (via toIso8601String())
p.idExpirationDate = DateTime(2030, 1, 15); // DateTime? → 'id_expiration_date' (via toIso8601String())

// Tax
p.taxId     = '123-45-6789';  // String? → 'tax_id'
p.taxIdName = 'SSN';          // String? → 'tax_id_name'

// Employment
p.occupation      = 2512;               // int?    → 'occupation' (ISCO-08 code; output as string in fields())
p.employerName    = 'Acme Corp';        // String? → 'employer_name'
p.employerAddress = '456 Business Ave'; // String? → 'employer_address'

// Other
p.languageCode = 'en';            // String? → 'language_code' (ISO 639-1)
p.ipAddress    = '192.168.1.1';   // String? → 'ip_address'
p.referralId   = 'REF123';        // String? → 'referral_id'

// Nested objects (merged into fields() output automatically)
p.financialAccountKYCFields = FinancialAccountKYCFields(); // FinancialAccountKYCFields?
p.cardKYCFields             = CardKYCFields();             // CardKYCFields?
```

### File properties

File properties are stored on the same object but returned **only** by `files()`, not by `fields()`. Assign raw `Uint8List` bytes; the SDK sends them as multipart/form-data when submitting via SEP-12 `putCustomerInfo()`.

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

NaturalPersonKYCFields p = NaturalPersonKYCFields();

p.photoIdFront            = await File('/path/to/id_front.jpg').readAsBytes();  // Uint8List? → 'photo_id_front'
p.photoIdBack             = await File('/path/to/id_back.jpg').readAsBytes();   // Uint8List? → 'photo_id_back'
p.notaryApprovalOfPhotoId = await File('/path/to/notary.pdf').readAsBytes();    // Uint8List? → 'notary_approval_of_photo_id'
p.photoProofResidence     = await File('/path/to/utility.pdf').readAsBytes();   // Uint8List? → 'photo_proof_residence'
p.proofOfIncome           = await File('/path/to/payslip.pdf').readAsBytes();   // Uint8List? → 'proof_of_income'
p.proofOfLiveness         = await File('/path/to/selfie.mp4').readAsBytes();    // Uint8List? → 'proof_of_liveness'
```

### fields() and files() output

```dart
// Text fields — omits all null fields, omits all file properties
Map<String, String> fields = p.fields();
// e.g. {'first_name': 'John', 'last_name': 'Doe', 'email_address': 'john@example.com', ...}

// Binary fields only — omits null file properties
Map<String, Uint8List> files = p.files();
// e.g. {'photo_id_front': Uint8List(...), 'photo_id_back': Uint8List(...)}

// occupation (int) is automatically converted to string in the output:
// p.occupation = 2512  →  fields['occupation'] == '2512'
//
// DateTime fields are serialized with toIso8601String():
// p.birthDate = DateTime(1990, 5, 15)  →  fields['birth_date'] == '1990-05-15T00:00:00.000'
// p.idIssueDate = DateTime(2020, 1, 1) →  fields['id_issue_date'] == '2020-01-01T00:00:00.000'
//
// financialAccountKYCFields and cardKYCFields are merged into fields() output automatically
```

---

## OrganizationKYCFields

### All properties

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

OrganizationKYCFields org = OrganizationKYCFields();

// Corporate identity
org.name               = 'Acme Corp S.L.';        // String? → 'organization.name'
org.VATNumber          = 'ESB12345678';            // String? → 'organization.VAT_number'  (mixed-case key)
org.registrationNumber = 'B-12345678';             // String? → 'organization.registration_number'
org.registrationDate   = '2015-06-01';             // String? → 'organization.registration_date' (ISO 8601 string)
org.registeredAddress  = '100 Gran Via, Madrid';   // String? → 'organization.registered_address'

// Corporate structure
org.numberOfShareholders = 3;             // int?    → 'organization.number_of_shareholders' (output as string)
org.shareholderName      = 'John Smith';  // String? → 'organization.shareholder_name'
org.directorName         = 'Jane Doe';   // String? → 'organization.director_name'

// Address / contact
org.addressCountryCode = 'ESP';                          // String? → 'organization.address_country_code'
org.stateOrProvince    = 'Madrid';                       // String? → 'organization.state_or_province'
org.city               = 'Madrid';                       // String? → 'organization.city'
org.postalCode         = '28013';                        // String? → 'organization.postal_code'
org.website            = 'https://acme.example.com';     // String? → 'organization.website'
org.email              = 'info@acme.example.com';        // String? → 'organization.email'
org.phone              = '+34911234567';                 // String? → 'organization.phone'

// Nested objects
org.financialAccountKYCFields = FinancialAccountKYCFields(); // keys get 'organization.' prefix
org.cardKYCFields             = CardKYCFields();             // keys stay 'card.*' (NO org prefix)
```

### File properties

```dart
import 'dart:typed_data';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

OrganizationKYCFields org = OrganizationKYCFields();

org.photoIncorporationDoc = await File('/path/to/cert.pdf').readAsBytes();   // Uint8List? → 'organization.photo_incorporation_doc'
org.photoProofAddress     = await File('/path/to/bill.pdf').readAsBytes();   // Uint8List? → 'organization.photo_proof_address'

Map<String, Uint8List> files = org.files();
// {'organization.photo_incorporation_doc': Uint8List(...), 'organization.photo_proof_address': Uint8List(...)}
```

### Organization prefix behavior

`OrganizationKYCFields.fields()` automatically applies the `'organization.'` prefix to all its own fields **and** to any nested `FinancialAccountKYCFields`. Card fields do NOT receive the `organization.` prefix — they always use the `card.` prefix regardless of nesting.

```dart
OrganizationKYCFields org = OrganizationKYCFields();
org.name = 'Acme Corp';

FinancialAccountKYCFields bank = FinancialAccountKYCFields();
bank.bankName = 'Chase';
org.financialAccountKYCFields = bank;

CardKYCFields card = CardKYCFields();
card.number = '4111111111111111';
org.cardKYCFields = card;

Map<String, String> fields = org.fields();
// 'organization.name'      => 'Acme Corp'         (org prefix applied)
// 'organization.bank_name' => 'Chase'             (financial gets org prefix)
// 'card.number'            => '4111111111111111'  (card prefix — NOT org prefix)
```

---

## FinancialAccountKYCFields

### All properties

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

FinancialAccountKYCFields fin = FinancialAccountKYCFields();

// Traditional banking
fin.bankName          = 'First National Bank';  // String? → 'bank_name'
fin.bankAccountType   = 'checking';             // String? → 'bank_account_type' (checking | savings)
fin.bankAccountNumber = '1234567890';           // String? → 'bank_account_number'
fin.bankNumber        = '021000021';            // String? → 'bank_number' (routing number in US)
fin.bankBranchNumber  = '001';                  // String? → 'bank_branch_number'
fin.bankPhoneNumber   = '+18005551234';         // String? → 'bank_phone_number' (E.164)

// Transfer memo / destination tag
fin.externalTransferMemo = 'WIRE-REF-12345';   // String? → 'external_transfer_memo'

// Regional banking formats
fin.clabeNumber = '032180000118359719';          // String? → 'clabe_number' (Mexico CLABE)
fin.cbuNumber   = '0110000000001234567890';      // String? → 'cbu_number'   (Argentina CBU/CVU)
fin.cbuAlias    = 'mi.cuenta.arg';               // String? → 'cbu_alias'    (Argentina alias)

// Mobile money
fin.mobileMoneyNumber   = '+254712345678';   // String? → 'mobile_money_number' (E.164; may differ from personal mobile)
fin.mobileMoneyProvider = 'M-Pesa';          // String? → 'mobile_money_provider'

// Crypto
fin.cryptoAddress = 'GABC...';           // String? → 'crypto_address'
// fin.cryptoMemo is @Deprecated — use externalTransferMemo instead
```

### keyPrefix parameter

`FinancialAccountKYCFields.fields()` accepts an optional named `keyPrefix` parameter (default `''`). You do not normally call this directly — `NaturalPersonKYCFields` calls it without a prefix, and `OrganizationKYCFields` calls it with `'organization.'`. You can call it directly if building custom field maps:

```dart
FinancialAccountKYCFields fin = FinancialAccountKYCFields();
fin.bankName = 'Chase';

// No prefix (when used with natural person)
Map<String, String> fields = fin.fields();
// {'bank_name': 'Chase'}

// With organization prefix (named parameter)
Map<String, String> orgFields = fin.fields(keyPrefix: 'organization.');
// {'organization.bank_name': 'Chase'}
```

Note: `FinancialAccountKYCFields` has **no** `files()` method — there are no binary fields for financial accounts.

---

## CardKYCFields

### All properties

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

CardKYCFields card = CardKYCFields();

card.number         = '4111111111111111';      // String? → 'card.number'
card.expirationDate = '29-11';                 // String? → 'card.expiration_date' (YY-MM format, e.g. November 2029)
card.cvc            = '123';                   // String? → 'card.cvc'
card.holderName     = 'JOHN DOE';              // String? → 'card.holder_name'
card.network        = 'Visa';                  // String? → 'card.network' (Visa, Mastercard, AmEx, etc.)
card.token          = 'tok_stripe_test_token'; // String? → 'card.token' (preferred over raw card data)

// Billing address
card.address         = '123 Main St, Apt 4B';  // String? → 'card.address'
card.city            = 'New York';              // String? → 'card.city'
card.stateOrProvince = 'NY';                   // String? → 'card.state_or_province' (ISO 3166-2)
card.postalCode      = '10001';                 // String? → 'card.postal_code'
card.countryCode     = 'US';                   // String? → 'card.country_code' (ISO 3166-1 alpha-2: 2-letter)

Map<String, String> fields = card.fields();
// Returns only non-null fields, all keys prefixed with 'card.'
```

Note: `CardKYCFields` has **no** `files()` method — there are no binary fields for cards.

---

## Field key constants

Every class exposes static `const String` constants for all its field and file keys. Use these instead of hardcoded strings to avoid typos.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

// NaturalPersonKYCFields — field key constants
NaturalPersonKYCFields.last_name_field_key;              // 'last_name'
NaturalPersonKYCFields.first_name_field_key;             // 'first_name'
NaturalPersonKYCFields.additional_name_field_key;        // 'additional_name'
NaturalPersonKYCFields.email_address_field_key;          // 'email_address'
NaturalPersonKYCFields.mobile_number_field_key;          // 'mobile_number'
NaturalPersonKYCFields.mobile_number_format_field_key;   // 'mobile_number_format'
NaturalPersonKYCFields.birth_date_field_key;             // 'birth_date'
NaturalPersonKYCFields.birth_place_field_key;            // 'birth_place'
NaturalPersonKYCFields.birth_country_code_field_key;     // 'birth_country_code'
NaturalPersonKYCFields.sex_field_key;                    // 'sex'
NaturalPersonKYCFields.address_field_key;                // 'address'
NaturalPersonKYCFields.city_field_key;                   // 'city'
NaturalPersonKYCFields.state_or_province_field_key;      // 'state_or_province'
NaturalPersonKYCFields.postal_code_field_key;            // 'postal_code'
NaturalPersonKYCFields.address_country_code_field_key;   // 'address_country_code'
NaturalPersonKYCFields.id_type_field_key;                // 'id_type'
NaturalPersonKYCFields.id_number_field_key;              // 'id_number'
NaturalPersonKYCFields.id_country_code_field_key;        // 'id_country_code'
NaturalPersonKYCFields.id_issue_date_field_key;          // 'id_issue_date'
NaturalPersonKYCFields.id_expiration_date_field_key;     // 'id_expiration_date'
NaturalPersonKYCFields.tax_id_field_key;                 // 'tax_id'
NaturalPersonKYCFields.tax_id_name_field_key;            // 'tax_id_name'
NaturalPersonKYCFields.occupation_field_key;             // 'occupation'
NaturalPersonKYCFields.employer_name_field_key;          // 'employer_name'
NaturalPersonKYCFields.employer_address_field_key;       // 'employer_address'
NaturalPersonKYCFields.language_code_field_key;          // 'language_code'
NaturalPersonKYCFields.ip_address_field_key;             // 'ip_address'
NaturalPersonKYCFields.referral_id_field_key;            // 'referral_id'
// File key constants:
NaturalPersonKYCFields.photo_id_front_file_key;                  // 'photo_id_front'
NaturalPersonKYCFields.photo_id_back_file_key;                   // 'photo_id_back'
NaturalPersonKYCFields.notary_approval_of_photo_id_file_key;     // 'notary_approval_of_photo_id'
NaturalPersonKYCFields.photo_proof_residence_file_key;           // 'photo_proof_residence'
NaturalPersonKYCFields.proof_of_income_file_key;                 // 'proof_of_income'
NaturalPersonKYCFields.proof_of_liveness_file_key;               // 'proof_of_liveness'

// OrganizationKYCFields — all keys include 'organization.' prefix
OrganizationKYCFields.key_prefix;                        // 'organization.'
OrganizationKYCFields.name_field_key;                    // 'organization.name'
OrganizationKYCFields.VAT_number_field_key;              // 'organization.VAT_number'   (mixed case)
OrganizationKYCFields.registration_number_field_key;     // 'organization.registration_number'
OrganizationKYCFields.registration_date_field_key;       // 'organization.registration_date'
OrganizationKYCFields.registered_address_field_key;      // 'organization.registered_address'
OrganizationKYCFields.number_of_shareholders_field_key;  // 'organization.number_of_shareholders'
OrganizationKYCFields.shareholder_name_field_key;        // 'organization.shareholder_name'
OrganizationKYCFields.director_name_field_key;           // 'organization.director_name'
OrganizationKYCFields.address_country_code_field_key;    // 'organization.address_country_code'
OrganizationKYCFields.state_or_province_field_key;       // 'organization.state_or_province'
OrganizationKYCFields.city_field_key;                    // 'organization.city'
OrganizationKYCFields.postal_code_field_key;             // 'organization.postal_code'
OrganizationKYCFields.website_field_key;                 // 'organization.website'
OrganizationKYCFields.email_field_key;                   // 'organization.email'
OrganizationKYCFields.phone_field_key;                   // 'organization.phone'
// File key constants:
OrganizationKYCFields.photo_incorporation_doc_file_key;  // 'organization.photo_incorporation_doc'
OrganizationKYCFields.photo_proof_address_file_key;      // 'organization.photo_proof_address'

// FinancialAccountKYCFields — bare names (no prefix)
FinancialAccountKYCFields.bank_name_field_key;           // 'bank_name'
FinancialAccountKYCFields.bank_account_type_field_key;   // 'bank_account_type'
FinancialAccountKYCFields.bank_account_number_field_key; // 'bank_account_number'
FinancialAccountKYCFields.bank_number_field_key;         // 'bank_number'
FinancialAccountKYCFields.bank_phone_number_field_key;   // 'bank_phone_number'
FinancialAccountKYCFields.bank_branch_number_field_key;  // 'bank_branch_number'
FinancialAccountKYCFields.external_transfer_memo_field_key; // 'external_transfer_memo'
FinancialAccountKYCFields.clabe_number_field_key;        // 'clabe_number'
FinancialAccountKYCFields.cbu_number_field_key;          // 'cbu_number'
FinancialAccountKYCFields.cbu_alias_field_key;           // 'cbu_alias'
FinancialAccountKYCFields.mobile_money_number_field_key; // 'mobile_money_number'
FinancialAccountKYCFields.mobile_money_provider_field_key; // 'mobile_money_provider'
FinancialAccountKYCFields.crypto_address_field_key;      // 'crypto_address'
FinancialAccountKYCFields.crypto_memo_field_key;         // 'crypto_memo' (deprecated)

// CardKYCFields — all keys include 'card.' prefix
CardKYCFields.key_prefix;               // 'card.'
CardKYCFields.number_field_key;         // 'card.number'
CardKYCFields.expiration_date_field_key; // 'card.expiration_date'
CardKYCFields.cvc_field_key;            // 'card.cvc'
CardKYCFields.holder_name_field_key;    // 'card.holder_name'
CardKYCFields.network_field_key;        // 'card.network'
CardKYCFields.token_field_key;          // 'card.token'
CardKYCFields.address_field_key;        // 'card.address'
CardKYCFields.city_field_key;           // 'card.city'
CardKYCFields.state_or_province_field_key; // 'card.state_or_province'
CardKYCFields.postal_code_field_key;    // 'card.postal_code'
CardKYCFields.country_code_field_key;   // 'card.country_code'
```

---

## Complete example: natural person with bank account

```dart
import 'dart:io';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> buildPersonKYC() async {
  NaturalPersonKYCFields person = NaturalPersonKYCFields();

  // Identity
  person.firstName        = 'Jane';
  person.lastName         = 'Doe';
  person.birthDate        = DateTime(1990, 5, 15);
  person.birthCountryCode = 'USA';
  person.sex              = 'female';

  // Address
  person.address            = '123 Main St, Apt 4B';
  person.city               = 'San Francisco';
  person.stateOrProvince    = 'CA';
  person.postalCode         = '94102';
  person.addressCountryCode = 'USA';

  // Contact
  person.emailAddress = 'jane@example.com';
  person.mobileNumber = '+14155551234';

  // Tax
  person.taxId     = '123-45-6789';
  person.taxIdName = 'SSN';

  // ID document (all text — images go on file properties)
  person.idType           = 'passport';
  person.idNumber         = 'AB123456';
  person.idCountryCode    = 'USA';
  person.idIssueDate      = DateTime(2020, 1, 15);
  person.idExpirationDate = DateTime(2030, 1, 15);

  // Bank account (nested, merged into fields() automatically)
  FinancialAccountKYCFields bank = FinancialAccountKYCFields();
  bank.bankName          = 'First National Bank';
  bank.bankAccountType   = 'checking';
  bank.bankAccountNumber = '1234567890';
  bank.bankNumber        = '021000021';  // routing number
  person.financialAccountKYCFields = bank;

  // Photo ID (binary — retrieved separately via files())
  person.photoIdFront = await File('/path/to/passport_front.jpg').readAsBytes();
  person.photoIdBack  = await File('/path/to/passport_back.jpg').readAsBytes();

  // Text fields for submission
  Map<String, String> textFields = person.fields();
  // {'first_name': 'Jane', 'last_name': 'Doe',
  //  'birth_date': '1990-05-15T00:00:00.000',
  //  'bank_name': 'First National Bank', 'bank_account_number': '1234567890', ...}

  // File fields for submission
  Map<String, Uint8List> fileFields = person.files();
  // {'photo_id_front': Uint8List(...), 'photo_id_back': Uint8List(...)}

  // Wrap in container and pass to SEP-12
  StandardKYCFields kyc = StandardKYCFields();
  kyc.naturalPersonKYCFields = person;
}
```

---

## Complete example: organization

```dart
import 'dart:io';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> buildOrgKYC() async {
  OrganizationKYCFields org = OrganizationKYCFields();

  org.name               = 'TechCorp International Ltd';
  org.VATNumber          = 'VAT123456789';
  org.registrationNumber = 'REG2010123456';
  org.registrationDate   = '2010-05-15';
  org.registeredAddress  = '50 Canary Wharf, London EC2';
  org.addressCountryCode = 'GBR';
  org.city               = 'London';
  org.postalCode         = 'EC2V 8AB';
  org.directorName       = 'James Anderson';
  org.website            = 'https://www.techcorp.com';
  org.email              = 'compliance@techcorp.com';
  org.phone              = '+442071234567';
  org.numberOfShareholders = 3;

  FinancialAccountKYCFields bank = FinancialAccountKYCFields();
  bank.bankName          = 'Barclays Bank';
  bank.bankAccountNumber = 'GB29NWBK60161331926819';
  org.financialAccountKYCFields = bank;

  org.photoIncorporationDoc = await File('/path/to/certificate.pdf').readAsBytes();

  Map<String, String> fields = org.fields();
  // {'organization.name'              => 'TechCorp International Ltd',
  //  'organization.VAT_number'        => 'VAT123456789',
  //  'organization.registered_address'=> '50 Canary Wharf, London EC2',
  //  'organization.bank_name'         => 'Barclays Bank',
  //  'organization.bank_account_number' => 'GB29NWBK60161331926819', ...}

  Map<String, Uint8List> files = org.files();
  // {'organization.photo_incorporation_doc': Uint8List(...)}

  StandardKYCFields kyc = StandardKYCFields();
  kyc.organizationKYCFields = org;
}
```

---

## Integration with SEP-12

Assign the `StandardKYCFields` container to `PutCustomerInfoRequest.kycFields`. The SEP-12 service calls `fields()` and `files()` on the nested objects internally when sending the request.

```dart
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> submitKYC(String jwtToken) async {
  KYCService kycService = KYCService('https://testanchor.stellar.org/kyc');

  NaturalPersonKYCFields person = NaturalPersonKYCFields();
  person.firstName    = 'John';
  person.lastName     = 'Doe';
  person.emailAddress = 'john@example.com';
  person.photoIdFront = await File('/path/to/id.jpg').readAsBytes();

  StandardKYCFields kyc = StandardKYCFields();
  kyc.naturalPersonKYCFields = person;

  PutCustomerInfoRequest request = PutCustomerInfoRequest();
  request.jwt       = jwtToken;   // from SEP-10 authentication
  request.kycFields = kyc;        // lowercase 'kycFields' — see pitfalls

  PutCustomerInfoResponse response = await kycService.putCustomerInfo(request);
  String customerId = response.id!;
}
```

For the full SEP-12 API (status polling, verification, file uploads, etc.) see [sep-12.md](sep-12.md).

---

## Common pitfalls

**WRONG: `request.KYCFields` (uppercase K) — property does not exist in Dart SDK**

```dart
// WRONG: PHP has uppercase KYCFields; Dart has lowercase kycFields
request.KYCFields = kyc;   // ignored / compile error

// CORRECT: Dart property is all-lowercase camelCase
request.kycFields = kyc;
```

**WRONG: `StandardKYCFields` has a `fields()` method**

```dart
// WRONG: the container has no fields() method
StandardKYCFields kyc = StandardKYCFields();
kyc.naturalPersonKYCFields = person;
Map<String, String> data = kyc.fields(); // compile error — method does not exist

// CORRECT: call fields() on the nested object
Map<String, String> data = kyc.naturalPersonKYCFields!.fields();

// Or pass the container to PutCustomerInfoRequest.kycFields — the SDK handles it
request.kycFields = kyc;
```

**WRONG: `occupation` expects `int`, not `String`**

```dart
// WRONG: string assignment
person.occupation = '2512';  // type mismatch — property is int?

// CORRECT: assign int (ISCO-08 code); fields() converts to string internally
person.occupation = 2512;
// person.fields()['occupation'] == '2512'
```

**WRONG: `birthDate`, `idIssueDate`, and `idExpirationDate` are all `DateTime?`**

```dart
// WRONG: string for any date field
person.birthDate        = '1990-05-15';        // type mismatch
person.idIssueDate      = '2020-01-15';        // type mismatch
person.idExpirationDate = '2030-01-15';        // type mismatch

// CORRECT: all three date fields accept DateTime?
person.birthDate        = DateTime(1990, 5, 15);
person.idIssueDate      = DateTime(2020, 1, 15);
person.idExpirationDate = DateTime(2030, 1, 15);
// In fields() output: DateTime.toIso8601String() → '1990-05-15T00:00:00.000'
```

Note: Unlike PHP where `birthDate` is a string and id dates are DateTime, in the Dart SDK **all three date fields are `DateTime?`**.

**WRONG: `OrganizationKYCFields.VAT_number_field_key` value is mixed-case**

```dart
// WRONG: assuming the key value is all-lowercase
String key = 'organization.vat_number';  // does not exist in SEP-09

// CORRECT: the key preserves the spec's mixed case
String key = OrganizationKYCFields.VAT_number_field_key; // 'organization.VAT_number'
// Property: org.VATNumber = 'ESB12345678';
```

**WRONG: card fields nested under an organization get the `organization.` prefix**

```dart
// WRONG: assuming org prefix applies to card fields too
Map<String, String> fields = org.fields();
fields['organization.card.number']; // does not exist

// CORRECT: card fields always use 'card.' prefix, even under an organization
fields['card.number']; // correct key
```

**WRONG: calling `files()` on `FinancialAccountKYCFields` or `CardKYCFields`**

```dart
// WRONG: neither class has a files() method
fin.files(); // compile error
card.files(); // compile error

// CORRECT: only NaturalPersonKYCFields and OrganizationKYCFields have files()
Map<String, Uint8List> personFiles = person.files();
Map<String, Uint8List> orgFiles    = org.files();
```

**WRONG: `FinancialAccountKYCFields.fields()` positional prefix parameter**

```dart
// WRONG: passing prefix as positional argument
fin.fields('organization.');  // compile error — it is a named parameter

// CORRECT: named parameter
fin.fields(keyPrefix: 'organization.');
```

**WRONG: `cryptoMemo` for new code**

```dart
// WRONG: deprecated — still works but discouraged
fin.cryptoMemo = '12345678';

// CORRECT: use the general external_transfer_memo field instead
fin.externalTransferMemo = '12345678';
```

---
