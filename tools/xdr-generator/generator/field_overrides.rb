# Maps XDR field names to Dart property names where they differ.
#
# The generator uses XDR field names as-is by default. This map records
# cases where the Dart SDK uses a different property name.
#
# Format:
#   "DartClassName" => {
#     "xdrFieldName" => "dartFieldName",
#   }

FIELD_OVERRIDES = {
  "XdrSignerKey" => {
    "ed25519SignedPayload" => "signedPayload",
  },
  "XdrManageBuyOfferOp" => {
    "buyAmount" => "amount",
  },
  "XdrPathPaymentStrictSendOp" => {
    "sendAmount" => "sendMax",
    "destMin" => "destAmount",
  },
  # ContractEvent: XDR contractID → SDK hash (type also differs: XdrContractID → XdrHash)
  "XdrContractEvent" => {
    "contractID" => "hash",
  },
  # ContractExecutable: XDR wasm_hash → SDK wasmHash (camelCase)
  "XdrContractExecutable" => {
    "wasm_hash" => "wasmHash",
  },
  # RevokeSponsorshipSigner: XDR accountID → SDK accountId (lowercase d)
  "XdrRevokeSponsorshipSigner" => {
    "accountID" => "accountId",
  },
  # 256-part types: XDR uses hi_hi/hi_lo/lo_hi/lo_lo, SDK uses camelCase
  "XdrUInt256Parts" => {
    "hi_hi" => "hiHi",
    "hi_lo" => "hiLo",
    "lo_hi" => "loHi",
    "lo_lo" => "loLo",
  },
  "XdrInt256Parts" => {
    "hi_hi" => "hiHi",
    "hi_lo" => "hiLo",
    "lo_hi" => "loHi",
    "lo_lo" => "loLo",
  },
  # InvokeHostFunctionOp: XDR hostFunction → SDK function
  "XdrInvokeHostFunctionOp" => {
    "hostFunction" => "function",
  },
  # SetTrustLineFlagsOp: XDR trustor → SDK accountID
  "XdrSetTrustLineFlagsOp" => {
    "trustor" => "accountID",
  },
}.freeze

# Maps XDR field names to Dart types where the hand-written SDK uses
# a different type than the generator would produce from the XDR spec.
#
# This avoids breaking changes to the user-facing SDK API.
# Key: DartClassName => { "xdrFieldName" => "DartTypeName" }
#
# The xdrFieldName is the name from the .x file, before any
# FIELD_OVERRIDES renaming.

FIELD_TYPE_OVERRIDES = {
  # -----------------------------------------------------------------------
  # int64 offerID fields using XdrUint64 (SDK uses unsigned for IDs).
  # The XDR spec declares these as int64 (signed) but offer IDs are
  # always positive, and the SDK historically uses unsigned decode.
  # -----------------------------------------------------------------------
  "XdrManageBuyOfferOp" => { "offerID" => "XdrUint64" },
  "XdrManageSellOfferOp" => { "offerID" => "XdrUint64" },
  "XdrOfferEntry" => { "offerID" => "XdrUint64" },
  "XdrLedgerKeyOffer" => { "offerID" => "XdrUint64" },
  "XdrClaimOfferAtom" => { "offerID" => "XdrUint64" },
  "XdrClaimOfferAtomV0" => { "offerID" => "XdrUint64" },

  # uint32 field using int instead of XdrUint32
  "XdrAllowTrustOp" => { "authorize" => "int" },

  # SignedPayload: inline opaque<64> → SDK uses XdrDataValue wrapper
  "XdrSignedPayload" => { "payload" => "XdrDataValue" },
  # ContractEvent: contractID field uses XdrHash instead of XdrContractID
  "XdrContractEvent" => { "contractID" => "XdrHash" },
  # SimplePaymentResult: XDR uses AccountID (→ XdrAccountID) but SDK uses XdrMuxedAccount
  "XdrSimplePaymentResult" => { "destination" => "XdrMuxedAccount" },
  # InnerTransactionResult: XDR has InnerTransactionResultExt but SDK reuses XdrTransactionResultExt
  "XdrInnerTransactionResult" => { "ext" => "XdrTransactionResultExt" },
}.freeze
