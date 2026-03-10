# This code was automatically generated using xdrgen
# DO NOT EDIT or your changes may be overwritten

require 'xdr'

module Stellar
  include XDR::Namespace

  Value = XDR::VarOpaque[]
  autoload :SCPBallot
  autoload :SCPStatementType
  autoload :SCPNomination
  autoload :SCPStatement
  autoload :SCPEnvelope
  autoload :SCPQuorumSet
end
module Stellar
  include XDR::Namespace

  autoload :ConfigSettingContractExecutionLanesV0
  autoload :ConfigSettingContractComputeV0
  autoload :ConfigSettingContractParallelComputeV0
  autoload :ConfigSettingContractLedgerCostV0
  autoload :ConfigSettingContractLedgerCostExtV0
  autoload :ConfigSettingContractHistoricalDataV0
  autoload :ConfigSettingContractEventsV0
  autoload :ConfigSettingContractBandwidthV0
  autoload :ContractCostType
  autoload :ContractCostParamEntry
  autoload :StateArchivalSettings
  autoload :EvictionIterator
  autoload :ConfigSettingSCPTiming
  CONTRACT_COST_COUNT_LIMIT = 1024
  ContractCostParams = XDR::VarArray[ContractCostParamEntry, CONTRACT_COST_COUNT_LIMIT]
  autoload :ConfigSettingID
  autoload :ConfigSettingEntry
end
module Stellar
  include XDR::Namespace

  autoload :SCEnvMetaKind
  autoload :SCEnvMetaEntry
end
module Stellar
  include XDR::Namespace

  autoload :SCMetaV0
  autoload :SCMetaKind
  autoload :SCMetaEntry
end
module Stellar
  include XDR::Namespace

  SC_SPEC_DOC_LIMIT = 1024
  autoload :SCSpecType
  autoload :SCSpecTypeOption
  autoload :SCSpecTypeResult
  autoload :SCSpecTypeVec
  autoload :SCSpecTypeMap
  autoload :SCSpecTypeTuple
  autoload :SCSpecTypeBytesN
  autoload :SCSpecTypeUDT
  autoload :SCSpecTypeDef
  autoload :SCSpecUDTStructFieldV0
  autoload :SCSpecUDTStructV0
  autoload :SCSpecUDTUnionCaseVoidV0
  autoload :SCSpecUDTUnionCaseTupleV0
  autoload :SCSpecUDTUnionCaseV0Kind
  autoload :SCSpecUDTUnionCaseV0
  autoload :SCSpecUDTUnionV0
  autoload :SCSpecUDTEnumCaseV0
  autoload :SCSpecUDTEnumV0
  autoload :SCSpecUDTErrorEnumCaseV0
  autoload :SCSpecUDTErrorEnumV0
  autoload :SCSpecFunctionInputV0
  autoload :SCSpecFunctionV0
  autoload :SCSpecEventParamLocationV0
  autoload :SCSpecEventParamV0
  autoload :SCSpecEventDataFormat
  autoload :SCSpecEventV0
  autoload :SCSpecEntryKind
  autoload :SCSpecEntry
end
module Stellar
  include XDR::Namespace

  autoload :SCValType
  autoload :SCErrorType
  autoload :SCErrorCode
  autoload :SCError
  autoload :UInt128Parts
  autoload :Int128Parts
  autoload :UInt256Parts
  autoload :Int256Parts
  autoload :ContractExecutableType
  autoload :ContractExecutable
  autoload :SCAddressType
  autoload :MuxedEd25519Account
  autoload :SCAddress
  SCSYMBOL_LIMIT = 32
  SCVec = XDR::VarArray[SCVal]
  SCMap = XDR::VarArray[SCMapEntry]
  SCBytes = XDR::VarOpaque[]
  SCString = XDR::String[]
  SCSymbol = XDR::String[SCSYMBOL_LIMIT]
  autoload :SCNonceKey
  autoload :SCContractInstance
  autoload :SCVal
  autoload :SCMapEntry
end
module Stellar
  include XDR::Namespace

  autoload :LedgerCloseMetaBatch
end
module Stellar
  include XDR::Namespace

  autoload :StoredTransactionSet
  autoload :StoredDebugTransactionSet
  autoload :PersistedSCPStateV0
  autoload :PersistedSCPStateV1
  autoload :PersistedSCPState
end
module Stellar
  include XDR::Namespace

  Thresholds = XDR::Opaque[4]
  String32 = XDR::String[32]
  String64 = XDR::String[64]
  SequenceNumber = Int64
  DataValue = XDR::VarOpaque[64]
  AssetCode4 = XDR::Opaque[4]
  AssetCode12 = XDR::Opaque[12]
  autoload :AssetType
  autoload :AssetCode
  autoload :AlphaNum4
  autoload :AlphaNum12
  autoload :Asset
  autoload :Price
  autoload :Liabilities
  autoload :ThresholdIndexes
  autoload :LedgerEntryType
  autoload :Signer
  autoload :AccountFlags
  MASK_ACCOUNT_FLAGS = 0x7
  MASK_ACCOUNT_FLAGS_V17 = 0xF
  MAX_SIGNERS = 20
  SponsorshipDescriptor = XDR::Option[AccountID]
  autoload :AccountEntryExtensionV3
  autoload :AccountEntryExtensionV2
  autoload :AccountEntryExtensionV1
  autoload :AccountEntry
  autoload :TrustLineFlags
  MASK_TRUSTLINE_FLAGS = 1
  MASK_TRUSTLINE_FLAGS_V13 = 3
  MASK_TRUSTLINE_FLAGS_V17 = 7
  autoload :LiquidityPoolType
  autoload :TrustLineAsset
  autoload :TrustLineEntryExtensionV2
  autoload :TrustLineEntry
  autoload :OfferEntryFlags
  MASK_OFFERENTRY_FLAGS = 1
  autoload :OfferEntry
  autoload :DataEntry
  autoload :ClaimPredicateType
  autoload :ClaimPredicate
  autoload :ClaimantType
  autoload :Claimant
  autoload :ClaimableBalanceFlags
  MASK_CLAIMABLE_BALANCE_FLAGS = 0x1
  autoload :ClaimableBalanceEntryExtensionV1
  autoload :ClaimableBalanceEntry
  autoload :LiquidityPoolConstantProductParameters
  autoload :LiquidityPoolEntry
  autoload :ContractDataDurability
  autoload :ContractDataEntry
  autoload :ContractCodeCostInputs
  autoload :ContractCodeEntry
  autoload :TTLEntry
  autoload :LedgerEntryExtensionV1
  autoload :LedgerEntry
  autoload :LedgerKey
  autoload :EnvelopeType
  autoload :BucketListType
  autoload :BucketEntryType
  autoload :HotArchiveBucketEntryType
  autoload :BucketMetadata
  autoload :BucketEntry
  autoload :HotArchiveBucketEntry
end
module Stellar
  include XDR::Namespace

  UpgradeType = XDR::VarOpaque[128]
  autoload :StellarValueType
  autoload :LedgerCloseValueSignature
  autoload :StellarValue
  MASK_LEDGER_HEADER_FLAGS = 0x7
  autoload :LedgerHeaderFlags
  autoload :LedgerHeaderExtensionV1
  autoload :LedgerHeader
  autoload :LedgerUpgradeType
  autoload :ConfigUpgradeSetKey
  autoload :LedgerUpgrade
  autoload :ConfigUpgradeSet
  autoload :TxSetComponentType
  DependentTxCluster = XDR::VarArray[TransactionEnvelope]
  ParallelTxExecutionStage = XDR::VarArray[DependentTxCluster]
  autoload :ParallelTxsComponent
  autoload :TxSetComponent
  autoload :TransactionPhase
  autoload :TransactionSet
  autoload :TransactionSetV1
  autoload :GeneralizedTransactionSet
  autoload :TransactionResultPair
  autoload :TransactionResultSet
  autoload :TransactionHistoryEntry
  autoload :TransactionHistoryResultEntry
  autoload :LedgerHeaderHistoryEntry
  autoload :LedgerSCPMessages
  autoload :SCPHistoryEntryV0
  autoload :SCPHistoryEntry
  autoload :LedgerEntryChangeType
  autoload :LedgerEntryChange
  LedgerEntryChanges = XDR::VarArray[LedgerEntryChange]
  autoload :OperationMeta
  autoload :TransactionMetaV1
  autoload :TransactionMetaV2
  autoload :ContractEventType
  autoload :ContractEvent
  autoload :DiagnosticEvent
  autoload :SorobanTransactionMetaExtV1
  autoload :SorobanTransactionMetaExt
  autoload :SorobanTransactionMeta
  autoload :TransactionMetaV3
  autoload :OperationMetaV2
  autoload :SorobanTransactionMetaV2
  autoload :TransactionEventStage
  autoload :TransactionEvent
  autoload :TransactionMetaV4
  autoload :InvokeHostFunctionSuccessPreImage
  autoload :TransactionMeta
  autoload :TransactionResultMeta
  autoload :TransactionResultMetaV1
  autoload :UpgradeEntryMeta
  autoload :LedgerCloseMetaV0
  autoload :LedgerCloseMetaExtV1
  autoload :LedgerCloseMetaExt
  autoload :LedgerCloseMetaV1
  autoload :LedgerCloseMetaV2
  autoload :LedgerCloseMeta
end
module Stellar
  include XDR::Namespace

  autoload :ErrorCode
  autoload :Error
  autoload :SendMore
  autoload :SendMoreExtended
  autoload :AuthCert
  autoload :Hello
  AUTH_MSG_FLAG_FLOW_CONTROL_BYTES_REQUESTED = 200
  autoload :Auth
  autoload :IPAddrType
  autoload :PeerAddress
  autoload :MessageType
  autoload :DontHave
  autoload :SurveyMessageCommandType
  autoload :SurveyMessageResponseType
  autoload :TimeSlicedSurveyStartCollectingMessage
  autoload :SignedTimeSlicedSurveyStartCollectingMessage
  autoload :TimeSlicedSurveyStopCollectingMessage
  autoload :SignedTimeSlicedSurveyStopCollectingMessage
  autoload :SurveyRequestMessage
  autoload :TimeSlicedSurveyRequestMessage
  autoload :SignedTimeSlicedSurveyRequestMessage
  EncryptedBody = XDR::VarOpaque[64000]
  autoload :SurveyResponseMessage
  autoload :TimeSlicedSurveyResponseMessage
  autoload :SignedTimeSlicedSurveyResponseMessage
  autoload :PeerStats
  autoload :TimeSlicedNodeData
  autoload :TimeSlicedPeerData
  TimeSlicedPeerDataList = XDR::VarArray[TimeSlicedPeerData, 25]
  autoload :TopologyResponseBodyV2
  autoload :SurveyResponseBody
  TX_ADVERT_VECTOR_MAX_SIZE = 1000
  TxAdvertVector = XDR::VarArray[Hash, TX_ADVERT_VECTOR_MAX_SIZE]
  autoload :FloodAdvert
  TX_DEMAND_VECTOR_MAX_SIZE = 1000
  TxDemandVector = XDR::VarArray[Hash, TX_DEMAND_VECTOR_MAX_SIZE]
  autoload :FloodDemand
  autoload :StellarMessage
  autoload :AuthenticatedMessage
end
module Stellar
  include XDR::Namespace

  MAX_OPS_PER_TX = 100
  autoload :LiquidityPoolParameters
  autoload :MuxedAccount
  autoload :DecoratedSignature
  autoload :OperationType
  autoload :CreateAccountOp
  autoload :PaymentOp
  autoload :PathPaymentStrictReceiveOp
  autoload :PathPaymentStrictSendOp
  autoload :ManageSellOfferOp
  autoload :ManageBuyOfferOp
  autoload :CreatePassiveSellOfferOp
  autoload :SetOptionsOp
  autoload :ChangeTrustAsset
  autoload :ChangeTrustOp
  autoload :AllowTrustOp
  autoload :ManageDataOp
  autoload :BumpSequenceOp
  autoload :CreateClaimableBalanceOp
  autoload :ClaimClaimableBalanceOp
  autoload :BeginSponsoringFutureReservesOp
  autoload :RevokeSponsorshipType
  autoload :RevokeSponsorshipOp
  autoload :ClawbackOp
  autoload :ClawbackClaimableBalanceOp
  autoload :SetTrustLineFlagsOp
  LIQUIDITY_POOL_FEE_V18 = 30
  autoload :LiquidityPoolDepositOp
  autoload :LiquidityPoolWithdrawOp
  autoload :HostFunctionType
  autoload :ContractIDPreimageType
  autoload :ContractIDPreimage
  autoload :CreateContractArgs
  autoload :CreateContractArgsV2
  autoload :InvokeContractArgs
  autoload :HostFunction
  autoload :SorobanAuthorizedFunctionType
  autoload :SorobanAuthorizedFunction
  autoload :SorobanAuthorizedInvocation
  autoload :SorobanAddressCredentials
  autoload :SorobanCredentialsType
  autoload :SorobanCredentials
  autoload :SorobanAuthorizationEntry
  SorobanAuthorizationEntries = XDR::VarArray[SorobanAuthorizationEntry]
  autoload :InvokeHostFunctionOp
  autoload :ExtendFootprintTTLOp
  autoload :RestoreFootprintOp
  autoload :Operation
  autoload :HashIDPreimage
  autoload :MemoType
  autoload :Memo
  autoload :TimeBounds
  autoload :LedgerBounds
  autoload :PreconditionsV2
  autoload :PreconditionType
  autoload :Preconditions
  autoload :LedgerFootprint
  autoload :SorobanResources
  autoload :SorobanResourcesExtV0
  autoload :SorobanTransactionData
  autoload :TransactionV0
  autoload :TransactionV0Envelope
  autoload :Transaction
  autoload :TransactionV1Envelope
  autoload :FeeBumpTransaction
  autoload :FeeBumpTransactionEnvelope
  autoload :TransactionEnvelope
  autoload :TransactionSignaturePayload
  autoload :ClaimAtomType
  autoload :ClaimOfferAtomV0
  autoload :ClaimOfferAtom
  autoload :ClaimLiquidityAtom
  autoload :ClaimAtom
  autoload :CreateAccountResultCode
  autoload :CreateAccountResult
  autoload :PaymentResultCode
  autoload :PaymentResult
  autoload :PathPaymentStrictReceiveResultCode
  autoload :SimplePaymentResult
  autoload :PathPaymentStrictReceiveResult
  autoload :PathPaymentStrictSendResultCode
  autoload :PathPaymentStrictSendResult
  autoload :ManageSellOfferResultCode
  autoload :ManageOfferEffect
  autoload :ManageOfferSuccessResult
  autoload :ManageSellOfferResult
  autoload :ManageBuyOfferResultCode
  autoload :ManageBuyOfferResult
  autoload :SetOptionsResultCode
  autoload :SetOptionsResult
  autoload :ChangeTrustResultCode
  autoload :ChangeTrustResult
  autoload :AllowTrustResultCode
  autoload :AllowTrustResult
  autoload :AccountMergeResultCode
  autoload :AccountMergeResult
  autoload :InflationResultCode
  autoload :InflationPayout
  autoload :InflationResult
  autoload :ManageDataResultCode
  autoload :ManageDataResult
  autoload :BumpSequenceResultCode
  autoload :BumpSequenceResult
  autoload :CreateClaimableBalanceResultCode
  autoload :CreateClaimableBalanceResult
  autoload :ClaimClaimableBalanceResultCode
  autoload :ClaimClaimableBalanceResult
  autoload :BeginSponsoringFutureReservesResultCode
  autoload :BeginSponsoringFutureReservesResult
  autoload :EndSponsoringFutureReservesResultCode
  autoload :EndSponsoringFutureReservesResult
  autoload :RevokeSponsorshipResultCode
  autoload :RevokeSponsorshipResult
  autoload :ClawbackResultCode
  autoload :ClawbackResult
  autoload :ClawbackClaimableBalanceResultCode
  autoload :ClawbackClaimableBalanceResult
  autoload :SetTrustLineFlagsResultCode
  autoload :SetTrustLineFlagsResult
  autoload :LiquidityPoolDepositResultCode
  autoload :LiquidityPoolDepositResult
  autoload :LiquidityPoolWithdrawResultCode
  autoload :LiquidityPoolWithdrawResult
  autoload :InvokeHostFunctionResultCode
  autoload :InvokeHostFunctionResult
  autoload :ExtendFootprintTTLResultCode
  autoload :ExtendFootprintTTLResult
  autoload :RestoreFootprintResultCode
  autoload :RestoreFootprintResult
  autoload :OperationResultCode
  autoload :OperationResult
  autoload :TransactionResultCode
  autoload :InnerTransactionResult
  autoload :InnerTransactionResultPair
  autoload :TransactionResult
end
module Stellar
  include XDR::Namespace

  Hash = XDR::Opaque[32]
  Uint256 = XDR::Opaque[32]
  Uint32 = XDR::UnsignedInt
  Int32 = XDR::Int
  Uint64 = XDR::UnsignedHyper
  Int64 = XDR::Hyper
  TimePoint = Uint64
  Duration = Uint64
  autoload :ExtensionPoint
  autoload :CryptoKeyType
  autoload :PublicKeyType
  autoload :SignerKeyType
  autoload :PublicKey
  autoload :SignerKey
  Signature = XDR::VarOpaque[64]
  SignatureHint = XDR::Opaque[4]
  NodeID = PublicKey
  AccountID = PublicKey
  ContractID = Hash
  autoload :Curve25519Secret
  autoload :Curve25519Public
  autoload :HmacSha256Key
  autoload :HmacSha256Mac
  autoload :ShortHashSeed
  autoload :BinaryFuseFilterType
  autoload :SerializedBinaryFuseFilter
  PoolID = Hash
  autoload :ClaimableBalanceIDType
  autoload :ClaimableBalanceID
end
