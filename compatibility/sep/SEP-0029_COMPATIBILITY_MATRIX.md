# SEP-0029 (Account Memo Requirements) Compatibility Matrix

**Generated:** 2026-09-24 07:18:16  
**SDK Version:** 3.7.0  
**SEP Version:** 0.5.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0029.md

## SEP Summary

An account signals that incoming payments must carry a memo by setting the data entry "config.memo_required" to the value "1". Before submitting a transaction without a memo, the sender loads the destination account of every payment, path payment and account merge operation and refuses to submit when one of them requires a memo. Multiplexed destinations are exempt, because the multiplexing id already identifies the recipient.

## Overall Coverage

**Total Coverage:** 100.0% (18/18 fields)

- ✅ **Implemented:** 18/18
- ❌ **Not Implemented:** 0/18

**Required Fields:** 100.0% (18/18)

**Optional Fields:** 0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/stellar_sdk.dart`
- `lib/src/manage_data_operation.dart`

### Key Classes

- **`StellarSDK`**: Horizon client with the SEP-29 memo required check (checkMemoRequired) run by the submit methods unless skipMemoRequiredCheck is true
- **`AccountRequiresMemoException`**: Thrown when a destination account requires a memo and the transaction carries none; holds the account id and the index of the operation that names it

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Memo Required | 100.0% | 100.0% | 18 | 0 | 18 |

## Detailed Field Comparison

### Memo Required

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `account_merge_destination` | ✓ | ✅ | `checkMemoRequired (AccountMergeOperation)` | Checks the destination of an account merge operation |
| `account_requires_memo_exception` | ✓ | ✅ | `AccountRequiresMemoException` | Dedicated exception carrying the account id and the operation index |
| `check_memo_required_method` | ✓ | ✅ | `checkMemoRequired(AbstractTransaction)` | Public check without submitting |
| `fee_bump_inner_transaction` | ✓ | ✅ | `checkMemoRequired (FeeBumpTransaction.innerTransaction)` | Checks a fee bump transaction through its inner transaction |
| `memo_present_skips_lookup` | ✓ | ✅ | `checkMemoRequired (memo short-circuit)` | Performs no lookup when the transaction carries a memo |
| `memo_required_data_entry` | ✓ | ✅ | `checkMemoRequired (config.memo_required data entry)` | Reads the destination account's config.memo_required data entry and compares its decoded value with 1 |
| `muxed_destination_exempt` | ✓ | ✅ | `checkMemoRequired (muxed destination skipped)` | Skips multiplexed destinations |
| `path_payment_strict_receive_destination` | ✓ | ✅ | `checkMemoRequired (PathPaymentStrictReceiveOperation)` | Checks the destination of a path payment strict receive operation |
| `path_payment_strict_send_destination` | ✓ | ✅ | `checkMemoRequired (PathPaymentStrictSendOperation)` | Checks the destination of a path payment strict send operation |
| `payment_destination` | ✓ | ✅ | `checkMemoRequired (PaymentOperation)` | Checks the destination of a payment operation |
| `set_memo_required_flag` | ✓ | ✅ | `ManageDataOperationBuilder` | Sets or removes the data entry with a manage data operation |
| `submit_async_fee_bump_transaction_opt_out` | ✓ | ✅ | `submitAsyncFeeBumpTransaction(skipMemoRequiredCheck)` | submitAsyncFeeBumpTransaction runs the check unless skipMemoRequiredCheck is true |
| `submit_async_transaction_envelope_opt_out` | ✓ | ✅ | `submitAsyncTransactionEnvelopeXdrBase64(skipMemoRequiredCheck)` | submitAsyncTransactionEnvelopeXdrBase64 runs the check unless skipMemoRequiredCheck is true |
| `submit_async_transaction_opt_out` | ✓ | ✅ | `submitAsyncTransaction(skipMemoRequiredCheck)` | submitAsyncTransaction runs the check unless skipMemoRequiredCheck is true |
| `submit_fee_bump_transaction_opt_out` | ✓ | ✅ | `submitFeeBumpTransaction(skipMemoRequiredCheck)` | submitFeeBumpTransaction runs the check unless skipMemoRequiredCheck is true |
| `submit_transaction_envelope_opt_out` | ✓ | ✅ | `submitTransactionEnvelopeXdrBase64(skipMemoRequiredCheck)` | submitTransactionEnvelopeXdrBase64 runs the check unless skipMemoRequiredCheck is true |
| `submit_transaction_opt_out` | ✓ | ✅ | `submitTransaction(skipMemoRequiredCheck)` | submitTransaction runs the check unless skipMemoRequiredCheck is true |
| `unknown_destination_skipped` | ✓ | ✅ | `checkMemoRequired (HTTP 404 skipped)` | Skips a destination Horizon does not know and lets the network report it |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0029!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
