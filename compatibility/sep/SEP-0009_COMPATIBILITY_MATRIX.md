# SEP-0009 (Standard KYC Fields) Compatibility Matrix

**Generated:** 2026-03-10 19:47:47  
**SDK Version:** 3.0.4  
**SEP Version:** 1.17.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0009.md

## SEP Summary

This SEP defines a list of standard KYC, AML, and financial account-related
fields for use in Stellar ecosystem protocols. Applications on Stellar should
use these fields when sending or requesting KYC, AML, or financial
account-related information with other parties on Stellar. This is an evolving
list, so please suggest any missing fields that you use.

This is a list of possible fields that may be necessary to handle many
different use cases, there is no expectation that any particular fields be used
for a particular application. The best fields to use in a particular case is
determined by the needs of the application.

## Overall Coverage

**Total Coverage:** 100.0% (76/76 fields)

- ✅ **Implemented:** 76/76
- ❌ **Not Implemented:** 0/76

**Required Fields:** 0% (0/0)

**Optional Fields:** 100.0% (76/76)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0009/standard_kyc_fields.dart`

### Key Classes

- **`StandardKYCFields`**: Container for all standard KYC field types
- **`NaturalPersonKYCFields`**: KYC fields for individuals (name, address, ID documents, etc.)
- **`FinancialAccountKYCFields`**: KYC fields for financial accounts (bank name, account number, etc.)
- **`OrganizationKYCFields`**: KYC fields for organizations (legal name, registration, address, etc.)
- **`CardKYCFields`**: KYC fields for payment cards (card number, expiration, CVV, etc.)

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Card Fields | 100.0% | 100% | 11 | 0 | 11 |
| Financial Account Fields | 100.0% | 100% | 14 | 0 | 14 |
| Natural Person Fields | 100.0% | 100% | 34 | 0 | 34 |
| Organization Fields | 100.0% | 100% | 17 | 0 | 17 |

## Detailed Field Comparison

### Card Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `card.address` |  | ✅ | `address` | Entire address (country, state, postal code, street address, etc.) as a multi-line string |
| `card.city` |  | ✅ | `city` | Name of city/town |
| `card.country_code` |  | ✅ | `countryCode` | Billing address country code in ISO 3166-1 alpha-2 code (e.g., US) |
| `card.cvc` |  | ✅ | `cvc` | CVC number (Digits on the back of the card) |
| `card.expiration_date` |  | ✅ | `expirationDate` | Expiration month and year in YY-MM format (e.g., 29-11, November 2029) |
| `card.holder_name` |  | ✅ | `holderName` | Name of the card holder |
| `card.network` |  | ✅ | `network` | Brand of the card/network it operates within (e.g., Visa, Mastercard, AmEx, etc.) |
| `card.number` |  | ✅ | `number` | Card number |
| `card.postal_code` |  | ✅ | `postalCode` | Billing address postal code |
| `card.state_or_province` |  | ✅ | `stateOrProvince` | Name of state/province/region/prefecture in ISO 3166-2 format |
| `card.token` |  | ✅ | `token` | Token representation of the card in some external payment system (e.g., Stripe) |

### Financial Account Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `bank_account_number` |  | ✅ | `bankAccountNumber` | Number identifying bank account |
| `bank_account_type` |  | ✅ | `bankAccountType` | Type of bank account |
| `bank_branch_number` |  | ✅ | `bankBranchNumber` | Number identifying bank branch |
| `bank_name` |  | ✅ | `bankName` | Name of the bank |
| `bank_number` |  | ✅ | `bankNumber` | Number identifying bank in national banking system (routing number in US) |
| `bank_phone_number` |  | ✅ | `bankPhoneNumber` | Phone number with country code for bank |
| `cbu_alias` |  | ✅ | `cbuAlias` | The alias for a CBU or CVU |
| `cbu_number` |  | ✅ | `cbuNumber` | Clave Bancaria Uniforme (CBU) or Clave Virtual Uniforme (CVU) |
| `clabe_number` |  | ✅ | `clabeNumber` | Bank account number for Mexico |
| `crypto_address` |  | ✅ | `cryptoAddress` | Address for a cryptocurrency account |
| `crypto_memo` |  | ✅ | `cryptoMemo` | A destination tag/memo used to identify a transaction |
| `external_transfer_memo` |  | ✅ | `externalTransferMemo` | A destination tag/memo used to identify a transaction |
| `mobile_money_number` |  | ✅ | `mobileMoneyNumber` | Mobile phone number in E.164 format with which a mobile money account is associated |
| `mobile_money_provider` |  | ✅ | `mobileMoneyProvider` | Name of the mobile money service provider |

### Natural Person Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `additional_name` |  | ✅ | `additionalName` | Middle name or other additional name |
| `address` |  | ✅ | `address` | Entire address (country, state, postal code, street address, etc.) as a multi-line string |
| `address_country_code` |  | ✅ | `addressCountryCode` | Country code for current address |
| `birth_country_code` |  | ✅ | `birthCountryCode` | ISO Code of country of birth (ISO 3166-1 alpha-3) |
| `birth_date` |  | ✅ | `birthDate` | Date of birth (e.g., 1976-07-04) |
| `birth_place` |  | ✅ | `birthPlace` | Place of birth (city, state, country; as on passport) |
| `city` |  | ✅ | `city` | Name of city/town |
| `email_address` |  | ✅ | `emailAddress` | Email address |
| `employer_address` |  | ✅ | `employerAddress` | Address of employer |
| `employer_name` |  | ✅ | `employerName` | Name of employer |
| `first_name` |  | ✅ | `firstName` | Given or first name |
| `id_country_code` |  | ✅ | `idCountryCode` | Country issuing passport or photo ID (ISO 3166-1 alpha-3) |
| `id_expiration_date` |  | ✅ | `idExpirationDate` | ID expiration date |
| `id_issue_date` |  | ✅ | `idIssueDate` | ID issue date |
| `id_number` |  | ✅ | `idNumber` | Passport or ID number |
| `id_type` |  | ✅ | `idType` | Type of ID (passport, drivers_license, id_card, etc.) |
| `ip_address` |  | ✅ | `ipAddress` | IP address of customer's computer |
| `language_code` |  | ✅ | `languageCode` | Primary language (ISO 639-1) |
| `last_name` |  | ✅ | `lastName` | Family or last name |
| `mobile_number` |  | ✅ | `mobileNumber` | Mobile phone number with country code, in E.164 format |
| `mobile_number_format` |  | ✅ | `mobileNumberFormat` | Expected format of the mobile_number field (E.164, hash, etc.) |
| `notary_approval_of_photo_id` |  | ✅ | `notaryApprovalOfPhotoId` | Image of notary's approval of photo ID or passport |
| `occupation` |  | ✅ | `occupation` | Occupation ISCO code |
| `photo_id_back` |  | ✅ | `photoIdBack` | Image of back of user's photo ID or passport |
| `photo_id_front` |  | ✅ | `photoIdFront` | Image of front of user's photo ID or passport |
| `photo_proof_residence` |  | ✅ | `photoProofResidence` | Image of a utility bill, bank statement or similar with the user's name and address |
| `postal_code` |  | ✅ | `postalCode` | Postal or other code identifying user's locale |
| `proof_of_income` |  | ✅ | `proofOfIncome` | Image of user's proof of income document |
| `proof_of_liveness` |  | ✅ | `proofOfLiveness` | Video or image file of user as a liveness proof |
| `referral_id` |  | ✅ | `referralId` | User's origin (such as an id in another application) or a referral code |
| `sex` |  | ✅ | `sex` | Gender (male, female, or other) |
| `state_or_province` |  | ✅ | `stateOrProvince` | Name of state/province/region/prefecture |
| `tax_id` |  | ✅ | `taxId` | Tax identifier of user in their country (social security number in US) |
| `tax_id_name` |  | ✅ | `taxIdName` | Name of the tax ID (SSN or ITIN in the US) |

### Organization Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `organization.VAT_number` |  | ✅ | `VATNumber` | Organization VAT number |
| `organization.address_country_code` |  | ✅ | `addressCountryCode` | Country code for current address |
| `organization.city` |  | ✅ | `city` | Name of city/town |
| `organization.director_name` |  | ✅ | `directorName` | Organization registered managing director |
| `organization.email` |  | ✅ | `email` | Organization contact email |
| `organization.name` |  | ✅ | `name` | Full organization name as on the incorporation papers |
| `organization.number_of_shareholders` |  | ✅ | `numberOfShareholders` | Organization shareholder number |
| `organization.phone` |  | ✅ | `phone` | Organization contact phone |
| `organization.photo_incorporation_doc` |  | ✅ | `photoIncorporationDoc` | Image of incorporation documents |
| `organization.photo_proof_address` |  | ✅ | `photoProofAddress` | Image of a utility bill, bank statement with the organization's name and address |
| `organization.postal_code` |  | ✅ | `postalCode` | Postal or other code identifying organization's locale |
| `organization.registered_address` |  | ✅ | `registeredAddress` | Organization registered address |
| `organization.registration_date` |  | ✅ | `registrationDate` | Date the organization was registered |
| `organization.registration_number` |  | ✅ | `registrationNumber` | Organization registration number |
| `organization.shareholder_name` |  | ✅ | `shareholderName` | Name of shareholder (can be organization or person) |
| `organization.state_or_province` |  | ✅ | `stateOrProvince` | Name of state/province/region/prefecture |
| `organization.website` |  | ✅ | `website` | Organization website |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0009!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
