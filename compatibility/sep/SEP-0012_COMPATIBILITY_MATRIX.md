# SEP-0012 (KYC API) Compatibility Matrix

**Generated:** 2026-02-03 17:26:56  
**SDK Version:** 3.0.1  
**SEP Version:** 1.15.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0012.md

## SEP Summary

This SEP defines a standard way for stellar clients to upload KYC (or other)
information to anchors and other services. [SEP-6](sep-0006.md) and
[SEP-31](sep-0031.md) use this protocol, but it can serve as a stand-alone
service as well.

This SEP was made with these goals in mind:

- interoperability
- Allow a customer to enter their KYC information to their wallet once and use
  it across many services without re-entering information manually
- handle the most common 80% of use cases
- handle image and binary data
- support the set of fields defined in [SEP-9](sep-0009.md)
- support authentication via [SEP-10](sep-0010.md)
- support the provision of data for [SEP-6](sep-0006.md),
  [SEP-24](sep-0024.md), [SEP-31](sep-0031.md), and others
- give customers control over their data by supporting complete data erasure

To support this protocol an anchor acts as a server and implements the
specified REST API endpoints, while a wallet implements a client that consumes
the API. The goal is interoperability, so a wallet implements a single client
according to the protocol, and will be able to interact with any compliant
anchor. Similarly, an anchor that implements the API endpoints according to the
protocol will work with any compliant wallet.

## Overall Coverage

**Total Coverage:** 100.0% (28/28 fields)

- ✅ **Implemented:** 28/28
- ❌ **Not Implemented:** 0/28

**Required Fields:** 100.0% (12/12)

**Optional Fields:** 100.0% (16/16)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/sep/0012/kyc_service.dart`

### Key Classes

- **`KYCService`**: Main service for SEP-12 KYC API operations
- **`GetCustomerInfoRequest`**: Request parameters for retrieving customer KYC info
- **`GetCustomerInfoField`**: Field definition for required KYC information
- **`GetCustomerInfoProvidedField`**: Field containing already provided KYC information
- **`GetCustomerInfoResponse`**: Response containing customer KYC status and fields
- **`PutCustomerInfoRequest`**: Request for submitting customer KYC information
- **`PutCustomerInfoResponse`**: Response after submitting customer KYC info
- **`GetCustomerFilesResponse`**: Response containing list of customer uploaded files
- **`PutCustomerVerificationRequest`**: Request for submitting verification codes
- **`PutCustomerCallbackRequest`**: Request for registering KYC status callback URL
- **`CustomerFileResponse`**: Individual file information in customer files response

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| API Endpoints | 100.0% | 100.0% | 7 | 0 | 7 |
| Authentication | 100.0% | 100.0% | 1 | 0 | 1 |
| Field Type Specifications | 100.0% | 100.0% | 6 | 0 | 6 |
| File Upload | 100.0% | 100.0% | 1 | 0 | 1 |
| Request Parameters | 100.0% | 100% | 7 | 0 | 7 |
| Response Fields | 100.0% | 100.0% | 5 | 0 | 5 |
| SEP-9 Integration | 100.0% | 100.0% | 1 | 0 | 1 |

## Detailed Field Comparison

### API Endpoints

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `delete_customer` | ✓ | ✅ | `deleteCustomer` | DELETE /customer/{account} - Delete all personal information about a customer |
| `get_customer` | ✓ | ✅ | `getCustomerInfo` | GET /customer - Check the status of a customers info |
| `get_customer_files` | ✓ | ✅ | `getCustomerFiles` | GET /customer/files - Get metadata about uploaded files |
| `post_customer_files` | ✓ | ✅ | `postCustomerFile` | POST /customer/files - Upload binary files for customer KYC |
| `put_customer` | ✓ | ✅ | `putCustomerInfo` | PUT /customer - Upload customer information to an anchor |
| `put_customer_callback` | ✓ | ✅ | `putCustomerCallback` | PUT /customer/callback - Register a callback URL for customer status updates |
| `put_customer_verification` | ✓ | ✅ | `putCustomerVerification` | PUT /customer/verification - Verify customer fields with confirmation codes |

### Authentication

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `jwt_authentication` | ✓ | ✅ | `JWT Token` | JWT Token via SEP-10 - All endpoints require SEP-10 JWT authentication via Authorization header |

### Field Type Specifications

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `choices` |  | ✅ | `choices` | Array of valid values for this field |
| `description` |  | ✅ | `description` | Human-readable description of the field |
| `error` |  | ✅ | `error` | Description of why field was rejected |
| `optional` |  | ✅ | `optional` | Whether this field is required to proceed |
| `status` |  | ✅ | `status` | Status of provided field |
| `type` | ✓ | ✅ | `type` | Data type of field value |

### File Upload

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `multipart_file_upload` | ✓ | ✅ | `multipart/form-data` | Binary files uploaded using multipart/form-data for photo_id, proof_of_address, etc. |

### Request Parameters

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account` |  | ✅ | `account` | Stellar account ID (G...) of the customer |
| `id` |  | ✅ | `id` | ID of the customer as returned in previous PUT request |
| `lang` |  | ✅ | `lang` | Language code (ISO 639-1) for human-readable responses |
| `memo` |  | ✅ | `memo` | Memo that uniquely identifies a customer in shared accounts |
| `memo_type` |  | ✅ | `memoType` | Type of memo: text, id, or hash |
| `transaction_id` |  | ✅ | `transactionId` | Transaction ID with which customer info is associated |
| `type` |  | ✅ | `type` | Type of action the customer is being KYCd for |

### Response Fields

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `fields` |  | ✅ | `fields` | Fields the anchor has not yet received |
| `id` |  | ✅ | `id` | ID of the customer |
| `message` |  | ✅ | `message` | Human readable message describing KYC status |
| `provided_fields` |  | ✅ | `providedFields` | Fields the anchor has received |
| `status` | ✓ | ✅ | `status` | Status of customer KYC process |

### SEP-9 Integration

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `standard_kyc_fields` | ✓ | ✅ | `StandardKYCFields` | Supports all SEP-9 standard KYC fields for natural persons and organizations |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0012!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
