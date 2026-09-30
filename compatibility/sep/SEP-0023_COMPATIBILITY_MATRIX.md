# SEP-0023 (Strkeys) Compatibility Matrix

**Generated:** 2026-09-30 14:11:22  
**SDK Version:** 3.8.0  
**SEP Version:** 1.3.0  
**SEP Status:** Active  
**SEP URL:** https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md

## SEP Summary

Strkey is an ASCII format for representing Stellar account IDs and addresses.

## Overall Coverage

**Total Coverage:** 100.0% (32/32 fields)

- ✅ **Implemented:** 32/32
- ❌ **Not Implemented:** 0/32

**Required Fields:** 100.0% (32/32)

**Optional Fields:** 0% (0/0)

## Implementation Status

✅ **Implemented**

### Implementation Files

- `lib/src/key_pair.dart`
- `lib/src/constants/stellar_protocol_constants.dart`
- `test/unit/strkey_test.dart`

### Key Classes

- **`VersionByte`**: Version byte of each strkey type, bound to its value in StellarProtocolConstants
- **`StrKey`**: Strkey encoding and decoding: an encode, a decode, and a validity check per key type, plus encodeCheck and decodeCheck for any version byte

## Coverage by Section

| Section | Coverage | Required Coverage | Implemented | Not Implemented | Total |
|---------|----------|-------------------|-------------|-----------------|-------|
| Key types | 100.0% | 100.0% | 9 | 0 | 9 |
| Test vectors quoted in the StrKey unit test files | 100.0% | 100.0% | 23 | 0 | 23 |

## Detailed Field Comparison

### Key types

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `STRKEY_CLAIMABLE_BALANCE` | ✓ | ✅ | `StrKey.encodeClaimableBalanceId / decodeClaimableBalanceId` | Base value 1 << 3 (8), first character B |
| `STRKEY_CONTRACT` | ✓ | ✅ | `StrKey.encodeContractId / decodeContractId` | Base value 2 << 3 (16), first character C |
| `STRKEY_HASH_X` | ✓ | ✅ | `StrKey.encodeSha256Hash / decodeSha256Hash` | Base value 23 << 3 (184), first character X |
| `STRKEY_LIQUIDITY_POOL` | ✓ | ✅ | `StrKey.encodeLiquidityPoolId / decodeLiquidityPoolId` | Base value 11 << 3 (88), first character L |
| `STRKEY_MUXED` | ✓ | ✅ | `StrKey.encodeStellarMuxedAccountId / decodeStellarMuxedAccountId` | Base value 12 << 3 (96), first character M |
| `STRKEY_PRE_AUTH_TX` | ✓ | ✅ | `StrKey.encodePreAuthTx / decodePreAuthTx` | Base value 19 << 3 (152), first character T |
| `STRKEY_PRIVKEY` | ✓ | ✅ | `StrKey.encodeStellarSecretSeed / decodeStellarSecretSeed` | Base value 18 << 3 (144), first character S |
| `STRKEY_PUBKEY` | ✓ | ✅ | `StrKey.encodeStellarAccountId / decodeStellarAccountId` | Base value 6 << 3 (48), first character G |
| `STRKEY_SIGNED_PAYLOAD` | ✓ | ✅ | `StrKey.encodeSignedPayload / decodeSignedPayload` | Base value 15 << 3 (120), first character P |

### Test vectors quoted in the StrKey unit test files

| Field | Required | Status | SDK Property | Description |
|-------|----------|--------|--------------|-------------|
| `invalid_01` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid length (Ed25519 should be 32 bytes, not 5), quoted in `test/unit/strkey_test.dart` |
| `invalid_02` | ✓ | ✅ | `test/unit/strkey_test.dart` | The unused trailing bit must be zero in the encoding of the last three bytes (24 bits) as five base-32 symbols (25 bits), quoted in `test/unit/strkey_test.dart` |
| `invalid_03` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid length (congruent to 1 mod 8), quoted in `test/unit/strkey_test.dart` |
| `invalid_04` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid length (base-32 decoding should yield 35 bytes, not 36), quoted in `test/unit/strkey_test.dart` |
| `invalid_05` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid algorithm (low 3 bits of version byte are 7), quoted in `test/unit/strkey_test.dart` |
| `invalid_06` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid length (congruent to 6 mod 8), quoted in `test/unit/strkey_test.dart` |
| `invalid_07` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid length (base-32 decoding should yield 43 bytes, not 44), quoted in `test/unit/strkey_test.dart` |
| `invalid_08` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid algorithm (low 3 bits of version byte are 7), quoted in `test/unit/strkey_test.dart` |
| `invalid_09` | ✓ | ✅ | `test/unit/strkey_test.dart` | Padding bytes are not allowed, quoted in `test/unit/strkey_test.dart` |
| `invalid_10` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid checksum, quoted in `test/unit/strkey_test.dart` |
| `invalid_11` | ✓ | ✅ | `test/unit/strkey_test.dart` | Length prefix specifies length that is shorter than payload in signed payload, quoted in `test/unit/strkey_test.dart` |
| `invalid_12` | ✓ | ✅ | `test/unit/strkey_test.dart` | Length prefix specifies length that is longer than payload in signed payload, quoted in `test/unit/strkey_test.dart` |
| `invalid_13` | ✓ | ✅ | `test/unit/strkey_test.dart` | No zero padding in signed payload, quoted in `test/unit/strkey_test.dart` |
| `invalid_14` | ✓ | ✅ | `test/unit/strkey_test.dart` | The unused trailing 2-bits must be zero in the encoding of the last symbol, quoted in `test/unit/strkey_test.dart` |
| `invalid_15` | ✓ | ✅ | `test/unit/strkey_test.dart` | Invalid claimable balance type (first byte of binary key is not 0), quoted in `test/unit/strkey_test.dart` |
| `valid_01` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid non-multiplexed account, quoted in `test/unit/strkey_test.dart` |
| `valid_02` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid multiplexed account, quoted in `test/unit/strkey_test.dart` |
| `valid_03` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid multiplexed account in which unsigned id exceeds maximum signed 64-bit integer, quoted in `test/unit/strkey_test.dart` |
| `valid_04` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid signed payload with an ed25519 public key and a 32-byte payload, quoted in `test/unit/strkey_test.dart` |
| `valid_05` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid signed payload with an ed25519 public key and a 29-byte payload which becomes zero padded, quoted in `test/unit/strkey_test.dart` |
| `valid_06` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid contract, quoted in `test/unit/strkey_test.dart` |
| `valid_07` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid liquidity pool address, quoted in `test/unit/strkey_test.dart` |
| `valid_08` | ✓ | ✅ | `test/unit/strkey_test.dart` | Valid claimable balance address, quoted in `test/unit/strkey_test.dart` |

## Implementation Gaps

🎉 **No gaps found!** All fields are implemented.

## Recommendations

✅ The SDK has full compatibility with SEP-0023!

## Legend

- ✅ **Implemented**: Field is implemented in SDK
- ❌ **Not Implemented**: Field is missing from SDK
- ⚙️ **Server**: Server-side only feature (not applicable to client SDKs)
- ✓ **Required**: Field is required by SEP specification
- (blank) **Optional**: Field is optional
