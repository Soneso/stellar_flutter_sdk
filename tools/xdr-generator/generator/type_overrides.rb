# Type resolution overrides for the Dart XDR generator.
#
# TYPE_OVERRIDES: Maps typedef-resolved class names to the actual Dart types
# the SDK uses. Applied in dart_type_for_typespec() when resolving Simple types.
#
# BASE_WRAPPER_TYPES: Types that generate *_base.dart files (union types get
# decodeAs<T>, struct types get plain decode). The wrapper file extends the base.

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

  # ContractID is typedef Hash; SDK uses XdrHash directly (no wrapper class).
  "XdrContractID" => "XdrHash",

  # PoolID is typedef Hash; SDK uses XdrHash directly (no wrapper class).
  "XdrPoolID" => "XdrHash",

  # Variable-length array typedefs the SDK uses as raw collections.
  # SCVec is typedef SCVal SCVec<>; SDK uses List<XdrSCVal> directly.
  # SCMap is typedef SCMapEntry SCMap<>; SDK uses List<XdrSCMapEntry> directly.
  "XdrSCVec" => "List<XdrSCVal>",
  "XdrSCMap" => "List<XdrSCMapEntry>",
}.freeze

# The 22 types whose generator output goes to *_base.dart files.
# The hand-maintained wrapper files extend these base classes.
BASE_WRAPPER_TYPES = %w[
  XdrAccountID
  XdrChangeTrustAsset
  XdrClaimableBalanceID
  XdrContractExecutable
  XdrContractIDPreimage
  XdrHostFunction
  XdrInt128Parts
  XdrInt256Parts
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
  XdrTransactionEnvelope
  XdrTrustlineAsset
  XdrUInt128Parts
  XdrUInt256Parts
].freeze

