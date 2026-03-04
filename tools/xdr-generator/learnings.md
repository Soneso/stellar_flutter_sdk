# XDR Generator Learnings

## Dart Patterns
- Enums: class with `_internal` const constructor, static consts, decode switch, encode writeInt
- Structs: private fields `_name`, getters/setters, constructor takes `this._field`, static encode/decode
- Unions (enum disc): constructor takes discriminant type, `get discriminant`, nullable arm fields
- Unions (int disc): constructor takes int `_v`, `get discriminant`, nullable arm fields
- Typedefs: wrapper class with single field, static encode/decode
- Base wrapper unions: `decodeAs<T>` with constructor parameter
- Base wrapper structs: plain decode, wrapper uses super params

## Naming
- Default: XDR `FooBar` -> Dart `XdrFooBar` -> file `xdr_foo_bar.dart`
- Enum members preserved as-is (SCREAMING_SNAKE from XDR)
- Discriminant getter always named `discriminant` (not `type`)
- encode param: `encoded` + class name minus `Xdr` prefix

## Type Mapping
- int/uint -> int (readInt/writeInt)
- hyper -> BigInt (readBigInt64Signed/writeBigInt64)
- uhyper -> BigInt (readBigInt64/writeBigInt64)
- bool -> bool (readBoolean/writeBoolean)
- string -> String (readString/writeString)
- opaque[N] -> Uint8List (readBytes(N)/write)
- opaque<> -> XdrDataValue (encode/decode with length prefix)

## Import Rules
- `dart:typed_data` only when Uint8List is used
- Blank line between dart: and package imports
- All imports sorted alphabetically within groups

## Batch 1 Findings
- Enum renderer produces EXACT matches for all 5 types
- resolve_size for opaque: use `decl.size` not `decl.type.array_size`
- 87 XDR types exist in .x files but not in Dart SDK (added to SKIP_TYPES)
- file_name() correctly converts CamelCase to snake_case with xdr_ prefix
- %w[] in Ruby treats # as literal character, NOT a comment - must delete lines

## Batch 2 Findings
- Enum output is semantically identical; only diff is cosmetic formatting
- Some existing files have extra blank lines between class members (inconsistent)
- Long enum member names get line-wrapped by dart format
- Some files have /// doc comments not in generator (e.g., XdrBucketEntryType)
- Strategy: generate -> dart format -> verify semantically equivalent

## Batch 3-4 Findings
- Typedef renderer produces semantic matches for int/BigInt/opaque/string wrappers
- Struct renderer works: XdrPrice produced correct output with XdrInt32 fields
- dart_type_for_typespec must NOT resolve through typedefs to primitives
  - int32 fields → XdrInt32 (wrapper class), not int (primitive)
  - Existing SDK uses wrapper classes (XdrUint32, XdrInt32, etc.) for struct fields
  - Only resolve through for TYPE_OVERRIDES and optional typedefs
  - is_base_type?() helper exists but should NOT be used for typedef resolution
- XdrSignerKeyType has hand-modified enum members: KEY_TYPE_ED25519_SIGNED_PAYLOAD (shortened from SIGNER_KEY_TYPE_...) and KEY_TYPE_MUXED_ED25519 (hand-added, not in XDR)
- Some hand-written files have Dart-only extensions not in XDR (extra enum members, methods)

## Batch 5 Findings
- Struct renderer works correctly for simple structs with various field types
- TYPE_OVERRIDES needed for XdrTimePoint→XdrUint64, XdrDuration→XdrUint64 (no separate classes in SDK)
- Import rendering bug: sort_imports uses "" separator → must not wrap in import statement
- Encode param name differs in some hand-written files (e.g., `encoded` vs `encodedLedgerBounds`) - cosmetic
- Decode style differs: hand-written uses inline constructor, generator uses separate variables - semantic match
- Some originals missing `void` return type on encode (XdrCurve25519Public) - generator is more correct
- Running diff from wrong directory causes false "No such file" - always use repo root

## Batch 6 Findings (Unions)
- Union renderer produces semantic matches for both enum-disc and int-disc unions
- Self-import bug: must exclude class's own file from imports (e.g., XdrClaimPredicate references itself)
- Optional/pointer encode: accessor must NOT have `!` for optional arms (check null without force unwrap)
- Generator correctly handles XDR `*` pointer as optional (presence flag + single value), hand-written code incorrectly treated as array
- Generator adds `default: break;` in int-disc switches (good practice, not in all originals)
- Variable naming in decode: generator uses `decoded`, hand-written uses `decodedTypeName` - cosmetic
- Encode param naming varies in originals: some use `encoded`, others `encodedTypeName` - generator is consistent

## Batch 7 Findings (Complex Structs)
- Struct renderer handles optionals (presence flag), arrays (size + loop), and mixed types correctly
- XdrBigInt64 vs XdrInt64: SDK has both; XdrBigInt64 uses unsigned read, XdrInt64 uses signed. Generator correctly uses XdrInt64 for int64 typedef.
- Some hand-written files use wrong type for int64 fields (XdrBigInt64 or XdrUint64 instead of XdrInt64)
- Optional field encode: generator correctly adds `!` force unwrap when passing to encode method
- Constructor placement: generator puts constructor before fields; some originals put constructor after fields - cosmetic

## Batch 8 Findings (Base Wrappers)
- XdrPublicKeyBase must be in BASE_WRAPPER_TYPES to generate _base.dart; was missing initially
- XdrPublicKeyBase is the ONLY base type that uses method-style accessors (getEd25519/setEd25519); all others use property-style (get ed25519, set ed25519). Generator produces property-style.
- The hand-written wrapper XdrPublicKey calls pk.setEd25519() which breaks with property-style base
- XdrSignerKey field override: XDR "ed25519SignedPayload" → SDK "signedPayload"
- Missing `void` on typedef encode methods: all 3 typedef renderers were affected (simple, fixed_opaque, string)
- XdrMuxedAccount, XdrNodeID, XdrUint256 all semantic match

## Batch 9 Findings (54 types - Bulk)
- Large batch of result codes, ops, results, structs verified successfully
- NAME_OVERRIDE needed: "AssetCode" => "XdrAllowTrustOpAsset" (SDK uses legacy name)
- XdrAssetCode4/XdrAssetCode12 must be un-skipped when XdrAllowTrustOpAsset is generated
- XdrClawbackResultCode: xdrgen uses CLAWBACK_NOT_CLAWBACK_ENABLED, SDK uses CLAWBACK_NOT_ENABLED (not referenced outside xdr/ so safe)
- Cross-boundary type differences confirmed:
  - XdrBigInt64 vs XdrInt64 for int64 fields (generator is more correct for signed int64)
  - Uint8List vs XdrAssetCode4/XdrAssetCode12 for fixed opaque (generator uses proper typedef)
  - int vs XdrUint32 for uint32 fields (generator uses typedef wrapper)
- Always run git commands from repo root, not from tools/xdr-generator/
- `dart analyze lib/src/xdr/` is the validation target; full `dart analyze lib/` shows expected cross-boundary mismatches

## Field Type Overrides (FIELD_TYPE_OVERRIDES)
- Added per-field type override mechanism to field_overrides.rb
- Keys: DartClassName => { xdrFieldName => DartTypeName }
- Applied in render_struct after dart_type_string resolution, before imports
- Preserves optionality (? suffix) from original type resolution
- render_encode_field and render_decode_field now use field_info[:type] instead of re-resolving from AST
- This is necessary because dart_type_for_typespec is not context-aware (doesn't know which struct/field)
- XdrBigInt64 vs XdrInt64: both use BigInt internally, difference is signed vs unsigned read
  - XdrBigInt64: readBigInt64() (unsigned), .bigInt accessor
  - XdrInt64: readBigInt64Signed() (signed), .int64 accessor
  - SDK uses XdrBigInt64 for amount/balance fields (always positive), XdrInt64 for others
- XdrUint64 for offerID: XDR says int64 but SDK uses unsigned (offerIDs are always positive)
- FIELD_OVERRIDES additions:
  - ManageBuyOfferOp: buyAmount → amount (XDR field renamed in SDK)
  - PathPaymentStrictSendOp: sendAmount → sendMax, destMin → destAmount (SDK uses different field names)
- Cross-boundary errors dropped from 28 to 3 (all XdrPublicKey known issue)

## Fixed-Opaque Typedef Resolution
- Fixed-opaque typedefs (e.g., `typedef opaque AssetCode4[4]`) should NOT be broadly resolved
  in `dart_type_for_typespec` — that breaks XdrUint256, XdrHash, XdrSignatureHint which are
  also fixed-opaque typedefs but are proper wrapper classes used throughout the SDK
- Correct approach: use TYPE_OVERRIDES for specific types that should resolve to Uint8List
  (XdrAssetCode4 → Uint8List, XdrAssetCode12 → Uint8List)
- Union arm handling: `resolve_dart_arm_info` calls `dart_type_for_typespec` first, then
  checks `fixed_opaque_typedef_size` only when type resolves to "Uint8List" (for proper decode size)
- Struct field handling: `fixed_opaque_size` only detected when `type_str == "Uint8List"`
- Bug fix: `arms` hash in union rendering must propagate `fixed_size` from arm_info
- Bug fix: `collect_union_imports` must add `dart:typed_data` when arms use Uint8List
- XdrPublicKey wrapper: method-style aliases (getEd25519/setEd25519) bridge generated
  property-style base to existing SDK code that calls method-style

## Cross-Boundary Fix Patterns
- **Wrong enum constant names**: Accept the XDR-correct name from the generator, update
  callers outside xdr/. Note as breaking change for the commit. Example: XdrSignerKeyType
  KEY_TYPE_ED25519_SIGNED_PAYLOAD → SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD (updated
  key_pair.dart and txrep.dart). Apply this for all incorrect constant names.
- **All-optional struct constructors**: Generator emits constructor with all params required.
  Update callers to pass nulls instead of using no-arg constructor. Not a breaking API
  change (internal call site). Example: XdrSetOptionsOp() → XdrSetOptionsOp(null, null, ...).

## Batch 11 Findings (Typedefs)
- Variable opaque typedefs (`opaque<>` and `opaque<N>`) now render with length-prefixed read/write
- TYPE_OVERRIDES types (XdrDuration, XdrTimePoint → XdrUint64) skip file generation entirely
- BASE_WRAPPER_TYPES now works for typedefs too (XdrAccountID → xdr_account_id_base.dart)
- Typedef-of-typedef resolution: when inner typedef is a leaf type (opaque/string/array),
  use the named wrapper class instead of resolving through (e.g., ContractID → XdrHash, not Uint8List)
- FIELD_TYPE_OVERRIDES now applies to typedefs (e.g., XdrSequenceNumber inner type → XdrBigInt64)
  Override key uses computed field_name (via underscore_field), not xdrgen decl.name
- New file types generated: simple typedefs (ContractID/PoolID → XdrHash), variable opaque
  (EncryptedBody/SCBytes/UpgradeType/Value), string (SCString/SCSymbol), array (TxAdvertVector/TxDemandVector)
- XdrAccountIDBase encode signature changed from nullable to non-nullable (more correct);
  wrapper updated to pass `val!` instead of `val`

## Cross-Boundary Error Resolution Summary
- 28 → 3 errors via FIELD_TYPE_OVERRIDES + FIELD_OVERRIDES
- 3 → 0 errors for XdrPublicKey via wrapper method aliases
- 3 → 0 errors for XdrSignerKeyType (updated callers) + XdrSetOptionsOp (pass nulls)
- Final: 0 cross-boundary errors (`dart analyze lib/` clean)

## Batch 13 Findings (Large Mixed - 84 types)
- **render_struct BASE_WRAPPER_TYPES**: Struct renderer didn't check BASE_WRAPPER_TYPES, causing
  wrapper files to be overwritten. Fixed by adding `is_base` check and using `class_name` (with Base suffix)
  for class definition, constructor, encode/decode. Must restore overwritten wrappers from git.
- **render_array_typedef BASE_WRAPPER_TYPES**: Same issue for array typedefs (e.g., XdrLedgerEntryChanges).
  Fixed by adding same `is_base` pattern.
- **Wrapper file overwrite recovery**: When a BASE_WRAPPER_TYPE was generated without the _base check,
  `git checkout HEAD -- filename` restores the original wrapper. The base file is correctly generated separately.
- **FIELD_TYPE_OVERRIDES + type_overridden flag**: When FIELD_TYPE_OVERRIDES changes a field type,
  render_encode_field/render_decode_field must use simple `Type.encode()/Type.decode()` instead of
  AST-based dispatch (which would generate raw Opaque byte operations). Added `:type_overridden` flag
  to field_info hash and early-return in render_encode_field/render_decode_field.
- **needs_typed_data_import exclusion**: `dart:typed_data` import must be skipped when field type
  was overridden (e.g., opaque → XdrDataValue doesn't need Uint8List import).
- **New FIELD_OVERRIDES**:
  - XdrContractEvent: contractID → hash (SDK used different field name + type)
  - XdrContractExecutable: wasm_hash → wasmHash (underscore → camelCase)
  - XdrRevokeSponsorshipSigner: accountID → accountId (uppercase D → lowercase d)
  - XdrUInt256Parts/XdrInt256Parts: hi_hi→hiHi, hi_lo→hiLo, lo_hi→loHi, lo_lo→loLo
- **New FIELD_TYPE_OVERRIDES**:
  - XdrContractEvent: contractID → XdrHash (SDK uses XdrHash, not XdrContractID)
  - XdrLedgerKeyOffer: offerID → XdrUint64 (unsigned, not XdrInt64)
  - XdrSignedPayload: payload → XdrDataValue (inline opaque → wrapper class)
- **New TYPE_OVERRIDES**:
  - XdrSCSymbol → String (SDK inlines string typedefs)
  - XdrSCString → String
- **XdrContractExecutable wrapper**: Added `type` getter/setter alias for `discriminant` since
  callers use `.type` but generated base uses `.discriminant`.
- **Re-skipped types**: XdrTransactionHistoryEntryExt (depends on XdrGeneralizedTransactionSet),
  XdrTrustLineEntryV1Ext (depends on TrustLineEntryExtensionV2 which has no Xdr prefix)
- **Ruby script danger**: A Ruby script to remove SKIP_TYPES entries accidentally removed
  BASE_WRAPPER_TYPES entries too (matched lines in ANY %w[] block). Always verify the list
  after bulk operations.

## Batch 14 Findings (85 types - First Cross-Boundary Batch)
- **Dependency analysis**: Used Ruby script with xdrgen AST to identify which SKIP_TYPES have
  all dependencies satisfied. Of 176 remaining, 85 were ready and 91 blocked.
- **XdrPoolID TYPE_OVERRIDE**: Added `XdrPoolID => XdrHash` (same pattern as XdrContractID).
  Without this, XdrPoolID resolves to a separate wrapper class that doesn't exist in the SDK.
- **Re-skipped types**: XdrTransactionHistoryEntryExt depends on XdrGeneralizedTransactionSet
  (still skipped). Must check transitive dependencies, not just direct ones.
- **Field renames discovered**: The XDR spec uses different names than the hand-written SDK:
  - sorobanTransactionData → sorobanData (XdrTransactionExt)
  - sequenceNumber → minSeqNum (XdrPreconditionsV2)
  - bumpExpirationOp → extendFootprintTTLOp (XdrOperationBody - XDR renamed this field)
  - createPassiveOfferOp → createPassiveSellOfferOp (XdrOperationBody)
  - manageOfferResult → manageSellOfferResult/manageBuyOfferResult (XdrOperationResultTr - split by discriminant)
  - hashKey → keyHash (XdrLedgerKeyTTL)
  - value → val (XdrSCMetaV0)
- **Union constructor pattern**: Generated unions take only discriminant in constructor; arms set
  via setters. Hand-written code sometimes used multi-arg constructors. All callers (SDK code
  and tests) must be updated.
- **XdrSCError encode correctness**: Generated encode correctly requires `code` field for non-CONTRACT
  error types (WASM_VM, CONTEXT, STORAGE, etc.). Old hand-written code had empty switch arms
  for these cases. Tests needed updating to set `error.code = XdrSCErrorCode.SCEC_ARITH_DOMAIN`.
- **XdrSCEnvMetaEntryInterfaceVersion**: Hand-written SDK treated this as a single XdrUint64.
  XDR spec defines it as a struct with `protocol` (uint32) and `preRelease` (uint32).
  This is a genuine bug fix in the hand-written code.
- **Parallel agent strategy**: Used 6 parallel agents for cross-boundary fixes, then 3 for test
  fixes. Each agent handled a cluster of related changes. Effective for large batches.
- **62 → 0 cross-boundary errors**: Required updates to 8 SDK files outside xdr/.
  29 test compilation errors + 18 runtime failures all resolved.

## Batches 15-22 Findings (130 types - All Exact Match)
- After batch 14 fixed all the hand-written discrepancies, the remaining 130 types all
  produced EXACT MATCH output (no diff after dart format).
- This confirms the generator is fully compatible with the existing hand-written code.
- 3 types (XdrClaimableBalanceEntryExt, XdrTransactionHistoryEntryExt,
  XdrTransactionSignaturePayloadTaggedTransaction) are nested definitions not found as
  top-level xdrgen AST entries. They are generated via `render_nested_definitions()` when
  their parent type is processed.
- Mutually-recursive types (XdrSCSpecTypeDef ↔ XdrSCSpecTypeOption/Result/Vec/Map/Tuple)
  can be un-skipped together in a single batch since they only depend on each other.

## Validation Script Findings
- Script at `tools/xdr-generator/test/validate_generated_types.rb` validates generated Dart
  files against xdrgen AST. Uses GeneratorHelper class wrapping Generator's private methods.
- 434/451 types pass validation. 4 genuine failures (XDR spec compliance gaps in SDK).
  13 types in `.x` files have no Dart implementation (missing files).
- **Dart-specific regex patterns**:
  - Enum members: multi-line `static const NAME = const Class._internal(\n  VALUE,\n);`
    after dart format. Use `/m` flag.
  - Private fields: `Type _fieldName;` with generic types like `List<Foo>`
  - Union void arms: `default: break;` covers all unlisted enum cases
- **Missing FIELD_OVERRIDES discovered**:
  - XdrInvokeHostFunctionOp: hostFunction → function
  - XdrSetTrustLineFlagsOp: trustor → accountID
- **Missing FIELD_TYPE_OVERRIDES discovered**:
  - XdrClaimOfferAtom/V0: offerID → XdrUint64
  - XdrSimplePaymentResult: destination → XdrMuxedAccount
  - XdrInnerTransactionResult: ext → XdrTransactionResultExt
- **BASE_WRAPPER_TYPES extending parent classes**: Skip detailed arm validation
  (e.g., XdrChangeTrustAsset extends XdrAsset, only defines liquidityPool arm)
- **Int discriminant wrappers**: `uint32 v` in XDR can map to `XdrUint32 _v` or `int _v`
- **XDR spec compliance gaps** (genuine findings):
  - XdrBucketEntry: missing INITENTRY/METAENTRY arms
  - XdrStellarMessage: missing 10 newer message type arms
  - XdrTransactionHistoryEntryExt: missing generalizedTxSet arm
  - XdrTransactionSignaturePayloadTaggedTransaction: missing feeBump arm
  - 13 types not yet implemented in SDK
