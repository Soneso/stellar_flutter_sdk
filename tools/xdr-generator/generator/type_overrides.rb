# Type resolution overrides for the Dart XDR generator.
#
# TYPE_OVERRIDES: Maps typedef-resolved class names to the actual Dart types
# the SDK uses. Applied in dart_type_for_typespec() when resolving Simple types.
#
# BASE_WRAPPER_TYPES: Types that generate *_base.dart files (union types get
# decodeAs<T>, struct types get plain decode). The wrapper file extends the base.
#
# SELF_REFERENCING_BASE_TYPES: Base types that reference their own wrapper type
# in field declarations (e.g., XdrSCValBase has List<XdrSCVal> fields).
#
# SKIP_TYPES: Types the generator must NOT produce. Initially all types;
# shrink by removing batches as generation is verified.

# Maps generated typedef names to the types the SDK actually uses.
TYPE_OVERRIDES = {
  # SequenceNumber is typedef int64 -> Dart wraps as XdrBigInt64
  # but the SDK uses XdrSequenceNumber directly (no override needed)

  # Duration/TimePoint are typedef uint64 but SDK has no separate classes.
  # Map to XdrUint64 which is the wrapper the SDK uses in struct fields.
  "XdrTimePoint" => "XdrUint64",
  "XdrDuration" => "XdrUint64",

  # Fixed-opaque typedefs that the SDK uses as raw Uint8List (no wrapper class).
  # AssetCode4/AssetCode12 are typedef opaque[4]/opaque[12]; the hand-written SDK
  # uses Uint8List directly in AllowTrustOpAsset union arms and struct fields.
  "XdrAssetCode4" => "Uint8List",
  "XdrAssetCode12" => "Uint8List",

  # String typedefs the SDK inlines as String (no wrapper class).
  "XdrSCSymbol" => "String",
  "XdrSCString" => "String",
}.freeze

# The 32 types whose generator output goes to *_base.dart files.
# The hand-maintained wrapper files extend these base classes.
BASE_WRAPPER_TYPES = %w[
  XdrAccountID
  XdrChangeTrustAsset
  XdrClaimableBalanceID
  XdrContractEvent
  XdrContractExecutable
  XdrContractIDPreimage
  XdrDiagnosticEvent
  XdrHostFunction
  XdrInt128Parts
  XdrInt256Parts
  XdrLedgerEntry
  XdrLedgerEntryChanges
  XdrLedgerEntryData
  XdrLedgerFootprint
  XdrLedgerKey
  XdrLedgerKeyData
  XdrLedgerKeyOffer
  XdrMuxedAccountMed25519
  XdrPublicKey
  XdrSCAddress
  XdrSCSpecTypeDef
  XdrSCVal
  XdrSorobanAuthorizedFunction
  XdrSorobanCredentials
  XdrSorobanTransactionData
  XdrTransactionEnvelope
  XdrTransactionEvent
  XdrTransactionMeta
  XdrTransactionResult
  XdrTrustlineAsset
  XdrUInt128Parts
  XdrUInt256Parts
].freeze

# Base types that import their own wrapper (circular dependency).
# XdrSCValBase has List<XdrSCVal> fields, so it imports xdr_sc_val.dart.
SELF_REFERENCING_BASE_TYPES = %w[
  XdrSCVal
].freeze

# Types the generator must NOT produce yet. Remove batches after verifying.
SKIP_TYPES = %w[
  TrustLineEntryExtensionV2
  TrustLineEntryExtensionV2Ext
  XdrAccountEntryV1
  XdrAccountEntryV1Ext
  XdrAccountEntryV2
  XdrAccountEntryV2Ext
  XdrAsset
  XdrAuthenticatedMessage
  XdrAuthenticatedMessageV0
  XdrBucketEntry
  XdrChangeTrustAsset
  XdrClaimLiquidityAtom
  XdrClaimOfferAtom
  XdrClaimOfferAtomV0
  XdrClaimableBalanceEntry
  XdrClaimableBalanceEntryExt
  XdrClaimableBalanceID
  XdrConfigSettingEntry
  XdrConfigSettingSCPTiming
  XdrConstantProduct
  XdrContractCodeEntry
  XdrContractCodeEntryExt
  XdrContractCodeEntryExtV1
  XdrContractCostParams
  XdrContractEventBody
  XdrContractIDPreimage
  XdrCreateContractArgs
  XdrCreateContractArgsV2
  XdrDataEntry
  XdrExtendFootprintTTLOp
  XdrExtendFootprintTTLResult
  XdrFeeBumpTransaction
  XdrFeeBumpTransactionEnvelope
  XdrFeeBumpTransactionInnerTx
  XdrGeneralizedTransactionSet
  XdrHashIDPreimage
  XdrHashIDPreimageContractID
  XdrHashIDPreimageOperationID
  XdrHashIDPreimageRevokeID
  XdrHashIDPreimageSorobanAuthorization
  XdrHello
  XdrHostFunction
  XdrInnerTransactionResult
  XdrInnerTransactionResultPair
  XdrInnerTransactionResultResult
  XdrInvokeHostFunctionOp
  XdrInvokeHostFunctionSuccessPreImage
  XdrLedgerCloseMeta
  XdrLedgerCloseMetaBatch
  XdrLedgerCloseMetaV1
  XdrLedgerCloseMetaV2
  XdrLedgerEntryChange
  XdrLedgerEntryExt
  XdrLedgerEntryV1
  XdrLedgerHeader
  XdrLedgerHeaderHistoryEntry
  XdrLedgerKey
  XdrLedgerKeyTTL
  XdrLedgerKeyTrustLine
  XdrLedgerSCPMessages
  XdrLedgerUpgrade
  XdrLiquidityPoolBody
  XdrLiquidityPoolConstantProductParameters
  XdrLiquidityPoolDepositOp
  XdrLiquidityPoolEntry
  XdrLiquidityPoolParameters
  XdrLiquidityPoolWithdrawOp
  XdrManageOfferResult
  XdrManageOfferSuccessResult
  XdrOperation
  XdrOperationBody
  XdrOperationMeta
  XdrOperationMetaV2
  XdrOperationResult
  XdrOperationResultTr
  XdrParallelTxsComponent
  XdrPathPaymentResultSuccess
  XdrPathPaymentStrictReceiveOp
  XdrPathPaymentStrictReceiveResult
  XdrPathPaymentStrictSendOp
  XdrPathPaymentStrictSendResult
  XdrPeerAddress
  XdrPersistedSCPState
  XdrPersistedSCPStateV0
  XdrPreconditions
  XdrPreconditionsV2
  XdrRevokeSponsorshipOp
  XdrSCAddress
  XdrSCContractInstance
  XdrSCEnvMetaEntry
  XdrSCError
  XdrSCMapEntry
  XdrSCMetaEntry
  XdrSCMetaV0
  XdrSCNonceKey
  XdrSCPEnvelope
  XdrSCPHistoryEntry
  XdrSCPHistoryEntryV0
  XdrSCPNomination
  XdrSCPQuorumSet
  XdrSCPStatement
  XdrSCPStatementConfirm
  XdrSCPStatementExternalize
  XdrSCPStatementPledges
  XdrSCPStatementPrepare
  XdrSCSpecEntry
  XdrSCSpecEventParamV0
  XdrSCSpecEventV0
  XdrSCSpecFunctionInputV0
  XdrSCSpecFunctionV0
  XdrSCSpecTypeBytesN
  XdrSCSpecTypeDef
  XdrSCSpecTypeMap
  XdrSCSpecTypeOption
  XdrSCSpecTypeResult
  XdrSCSpecTypeTuple
  XdrSCSpecTypeUDT
  XdrSCSpecTypeVec
  XdrSCSpecUDTEnumCaseV0
  XdrSCSpecUDTEnumV0
  XdrSCSpecUDTErrorEnumCaseV0
  XdrSCSpecUDTErrorEnumV0
  XdrSCSpecUDTStructFieldV0
  XdrSCSpecUDTStructV0
  XdrSCSpecUDTUnionCaseTupleV0
  XdrSCSpecUDTUnionCaseV0
  XdrSCSpecUDTUnionCaseVoidV0
  XdrSCSpecUDTUnionV0
  XdrSCVal
  XdrSetTrustLineFlagsOp
  XdrSignedTimeSlicedSurveyRequestMessage
  XdrSignedTimeSlicedSurveyResponseMessage
  XdrSimplePaymentResult
  XdrSorobanAuthorizationEntry
  XdrSorobanAuthorizedFunction
  XdrSorobanAuthorizedInvocation
  XdrSorobanCredentials
  XdrSorobanResources
  XdrSorobanTransactionDataExt
  XdrSorobanTransactionMeta
  XdrSorobanTransactionMetaExt
  XdrSorobanTransactionMetaV2
  XdrStellar
  XdrStellarMessage
  XdrStellarValue
  XdrStoredDebugTransactionSet
  XdrStoredTransactionSet
  XdrSurveyResponseBody
  XdrTTLEntry
  XdrTimeSlicedPeerDataList
  XdrTopologyResponseBodyV2
  XdrTransaction
  XdrTransactionExt
  XdrTransactionHistoryEntry
  XdrTransactionHistoryEntryExt
  XdrTransactionHistoryResultEntry
  XdrTransactionMetaV1
  XdrTransactionMetaV2
  XdrTransactionMetaV3
  XdrTransactionMetaV4
  XdrTransactionPhase
  XdrTransactionResultPair
  XdrTransactionResultResult
  XdrTransactionResultSet
  XdrTransactionSet
  XdrTransactionSetV1
  XdrTransactionSignaturePayload
  XdrTransactionSignaturePayloadTaggedTransaction
  XdrTransactionV0
  XdrTransactionV0Envelope
  XdrTransactionV1Envelope
  XdrTrustLineEntry
  XdrTrustLineEntryExt
  XdrTrustLineEntryV1
  XdrTrustLineEntryV1Ext
  XdrTrustlineAsset
].freeze