# XDR Generator Progress

## Status: Batch 13 complete

## Batches
1. Enums (5): XdrAssetType, XdrMemoType, XdrPublicKeyType, XdrSignerKeyType, XdrCryptoKeyType -> EXACT MATCH
2. Enums (5): XdrOperationType, XdrEnvelopeType, XdrLedgerEntryType, XdrBucketEntryType, XdrClaimPredicateType -> SEMANTIC MATCH
3. Typedefs (5): XdrUint32, XdrInt32, XdrUint64, XdrInt64, XdrHash -> SEMANTIC MATCH
4. Typedefs+Struct (5): XdrString32, XdrString64, XdrDataValue, XdrSignature, XdrPrice -> SEMANTIC MATCH
5. Structs (5): XdrLiabilities, XdrTimeBounds, XdrLedgerBounds, XdrCurve25519Public, XdrSCPBallot -> SEMANTIC MATCH
6. Unions (5): XdrMemo, XdrExtensionPoint, XdrAccountEntryExt, XdrClaimAtom, XdrClaimPredicate -> SEMANTIC MATCH
7. Complex structs (5): XdrDecoratedSignature, XdrSigner, XdrCreateAccountOp, XdrOfferEntry, XdrAccountEntry -> SEMANTIC MATCH
8. Base wrapper + deps (5): XdrPublicKey(Base), XdrSignerKey, XdrMuxedAccount, XdrNodeID, XdrUint256 -> SEMANTIC MATCH
9. Bulk batch (54): ResultCodes, Ops, Results, Structs for AllowTrust, BeginSponsoring, BumpSequence, ChangeTrust, ClaimClaimableBalance, Claimant, Clawback, ClawbackClaimableBalance, CreateAccount, CreateClaimableBalance, CreatePassiveSellOffer, EndSponsoring, Inflation, ManageBuyOffer, ManageData, ManageSellOffer, ManageOfferEffect, Payment, SetOptions, AssetCode, AssetCode4, AssetCode12, ClaimantV0 -> 7 EXACT MATCH after `dart format`, rest SEMANTIC MATCH
10. All remaining enums (56): AccountFlags, BinaryFuseFilterType, BucketListType, ClaimAtomType, ClaimableBalanceFlags, ConfigSettingID, ContractCostType, ContractDataDurability, ContractEventType, ContractExecutableType, ContractIDPreimageType, ErrorCode, ExtendFootprintTTLResultCode, HostFunctionType, HotArchiveBucketEntryType, IPAddrType, InvokeHostFunctionResultCode, LedgerEntryChangeType, LedgerHeaderFlags, LedgerUpgradeType, LiquidityPoolDepositResultCode, LiquidityPoolType, LiquidityPoolWithdrawResultCode, ManageOfferResultCode, MessageType, OfferEntryFlags, OperationResultCode, PathPaymentStrictReceiveResultCode, PathPaymentStrictSendResultCode, PreconditionType, RestoreFootprintResultCode, RevokeSponsorshipResultCode, RevokeSponsorshipType, SCAddressType, SCEnvMetaKind, SCErrorCode, SCErrorType, SCMetaKind, SCPStatementType, SCSpecEntryKind, SCSpecEventDataFormat, SCSpecEventParamLocationV0, SCSpecType, SCSpecUDTUnionCaseV0Kind, SCValType, SetTrustLineFlagsResultCode, SorobanAuthorizedFunctionType, SorobanCredentialsType, StellarValueType, SurveyMessageCommandType, SurveyMessageResponseType, ThresholdIndexes, TransactionEventStage, TransactionResultCode, TrustLineFlags, TxSetComponentType -> SEMANTIC MATCH

## Style Improvements Applied
- Copyright header blank line (eliminates most enum diffs)
- Union discriminant field uses XDR name (e.g., `_code`, `_type`, `_v`)
- Union decode variable naming: `decodedTypeName` pattern
- Union encode/decode uses private field access (`._field!`)
- Multi-case void arms collapsed to `default: break;` (single-case kept explicit)
- Union constructor placement after disc getter/setter and arm getters
- Struct constructor placement after fields

## Field Type Overrides (FIELD_TYPE_OVERRIDES)
Added per-field type override mechanism in `field_overrides.rb` to preserve SDK API:
- int64 amount/balance fields → XdrBigInt64 (14 classes, unsigned BigInt reads)
- int64 offerID fields → XdrUint64 (3 classes: ManageBuyOfferOp, ManageSellOfferOp, OfferEntry)
Also added FIELD_OVERRIDES for field name mismatches:
- ManageBuyOfferOp: buyAmount → amount
- PathPaymentStrictSendOp: sendAmount → sendMax, destMin → destAmount

## Exact Matches After `dart format` (7/87)
- xdr_account_merge_result.dart
- xdr_create_account_result.dart
- xdr_envelope_type.dart
- xdr_manage_data_result.dart
- xdr_manage_offer_effect.dart
- xdr_public_key_type.dart
- xdr_set_options_result.dart

## Fixed-Opaque Typedef Resolution
- AssetCode4/AssetCode12 → Uint8List via TYPE_OVERRIDES (not broad dart_type_for_typespec change)
- Union arm import collection now adds `dart:typed_data` when arms use Uint8List
- Union arm `fixed_size` now propagated from resolve_dart_arm_info to arm hash
- XdrPublicKey wrapper: added getEd25519()/setEd25519() method aliases for backward compat
- AllowTrustOp.authorize: FIELD_TYPE_OVERRIDE → int (instead of XdrUint32)

## Known Issues
- XdrClawbackResultCode: CLAWBACK_NOT_CLAWBACK_ENABLED vs CLAWBACK_NOT_ENABLED (not yet referenced outside xdr/)

## Cross-Boundary Errors: 0 (down from 28)

### Resolved
- XdrBigInt64 → XdrInt64: 12 errors → FIXED (FIELD_TYPE_OVERRIDES)
- XdrUint64 → XdrInt64: 3 errors → FIXED (FIELD_TYPE_OVERRIDES for offerID)
- int → XdrUint32: 3 errors → FIXED (FIELD_TYPE_OVERRIDES for AllowTrustOp.authorize)
- Uint8List → XdrAssetCode4/12: 4 errors → FIXED (TYPE_OVERRIDES for AssetCode4/12)
- XdrPublicKey getEd25519/setEd25519: 3 errors → FIXED (wrapper method aliases)
- Other field name/constructor: 3 errors → FIXED (FIELD_OVERRIDES)
- XdrSignerKeyType member name: 2 errors → FIXED (updated callers, breaking change)
- XdrSetOptionsOp constructor: 1 error → FIXED (callers pass nulls)

## Breaking Changes (for commit)
- XdrSignerKeyType: KEY_TYPE_ED25519_SIGNED_PAYLOAD → SIGNER_KEY_TYPE_ED25519_SIGNED_PAYLOAD
- XdrPreconditionType: NONE → PRECOND_NONE, TIME → PRECOND_TIME, V2 → PRECOND_V2
- XdrManageOfferResultCode: MANAGE_OFFER_SUCCESS → MANAGE_SELL_OFFER_SUCCESS
- XdrMessageType: GET_PEERS removed (not in XDR), SURVEY_REQUEST/SURVEY_RESPONSE removed (replaced by TIME_SLICED_*)

11. Typedefs (16 un-skipped, 8 new files, 6 modified): XdrAccountID(Base), XdrContractID, XdrDuration(TYPE_OVERRIDE skip), XdrEncryptedBody, XdrPoolID, XdrSCBytes, XdrSCString, XdrSCSymbol, XdrSequenceNumber, XdrSignatureHint, XdrThresholds, XdrTimePoint(TYPE_OVERRIDE skip), XdrTxAdvertVector, XdrTxDemandVector, XdrUpgradeType, XdrValue -> SEMANTIC MATCH

12. Mixed batch (39 un-skipped: 12 simple structs/unions, 5 typedefs, 22 complex structs/unions): XdrSendMore, XdrSendMoreExtended, XdrShortHashSeed, XdrLedgerCloseValueSignature, XdrLedgerHeaderExtensionV1Ext, XdrClaimableBalanceEntryExtV1Ext, XdrInnerTransactionResultExt, XdrBucketMetadataExt, XdrLedgerKeyClaimableBalance, XdrLedgerKeyConfigSetting, XdrLedgerKeyLiquidityPool, XdrSCEnvMetaEntryInterfaceVersion, XdrSCVec, XdrSCMap, XdrSponsorshipDescriptor, XdrSorobanAuthorizationEntries, XdrDependentTxCluster, XdrBucketMetadata, XdrLedgerHeaderExtensionV1, XdrFloodAdvert, XdrFloodDemand, XdrContractIDPreimageFromAddress, XdrContractEventV0, XdrContractCodeEntryV1, XdrLedgerCloseMetaExtV1, XdrTxSetComponentTxsMaybeDiscountedFee, XdrTimeSlicedSurveyStartCollectingMessage, XdrTimeSlicedSurveyStopCollectingMessage, XdrUpgradeEntryMeta, XdrTransactionResultMeta, XdrConfigUpgradeSet, XdrLiquidityPoolEntryConstantProduct, XdrTransactionResultMetaV1, XdrSurveyRequestMessage, XdrSurveyResponseMessage, XdrTimeSlicedNodeData, XdrPeerStats, XdrPersistedSCPStateV1, XdrLedgerCloseMetaExt -> SEMANTIC MATCH

13. Large mixed batch (84 un-skipped, 55 new files, 83 modified): Structs, unions, base wrappers including XdrInt128Parts(Base), XdrInt256Parts(Base), XdrUInt128Parts(Base), XdrUInt256Parts(Base), XdrContractEvent(Base), XdrContractExecutable(Base), XdrDiagnosticEvent(Base), XdrLedgerEntry(Base), XdrLedgerEntryChanges(Base), XdrLedgerFootprint(Base), XdrLedgerKeyData(Base), XdrLedgerKeyOffer(Base), XdrMuxedAccountMed25519(Base), XdrSorobanTransactionData(Base), XdrTransactionEvent(Base), XdrTransactionResult(Base), XdrLedgerEntryData(Base), plus many non-base types. Re-skipped XdrTransactionHistoryEntryExt (depends on XdrGeneralizedTransactionSet) and XdrTrustLineEntryV1Ext (depends on TrustLineEntryExtensionV2). -> SEMANTIC MATCH

## Stats
Types remaining in SKIP_TYPES: 176
Types generated: ~289 (40 from batches 1-8 + 54 from batch 9 + 56 from batch 10 + 16 from batch 11 + 39 from batch 12 + 84 from batch 13)
Cross-boundary errors: 0
