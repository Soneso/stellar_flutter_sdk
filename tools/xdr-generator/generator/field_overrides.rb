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
  # int64 fields using XdrBigInt64 instead of XdrInt64.
  # The hand-written SDK uses unsigned BigInt reads for amount/balance
  # fields. Amounts are always non-negative so this is safe in practice.
  # -----------------------------------------------------------------------
  "XdrChangeTrustOp" => { "limit" => "XdrBigInt64" },
  "XdrClawbackOp" => { "amount" => "XdrBigInt64" },
  "XdrCreateAccountOp" => { "startingBalance" => "XdrBigInt64" },
  "XdrCreateClaimableBalanceOp" => { "amount" => "XdrBigInt64" },
  "XdrCreatePassiveSellOfferOp" => { "amount" => "XdrBigInt64" },
  "XdrPaymentOp" => { "amount" => "XdrBigInt64" },

  # These also have offerID: int64 → XdrUint64 (SDK uses unsigned for IDs)
  "XdrManageBuyOfferOp" => {
    "buyAmount" => "XdrBigInt64",
    "offerID" => "XdrUint64",
  },
  "XdrManageSellOfferOp" => {
    "amount" => "XdrBigInt64",
    "offerID" => "XdrUint64",
  },

  # int64 offerID using XdrUint64 instead of XdrInt64
  "XdrOfferEntry" => { "offerID" => "XdrUint64" },

  # uint32 field using int instead of XdrUint32
  "XdrAllowTrustOp" => { "authorize" => "int" },

  # -----------------------------------------------------------------------
  # Future batches (not yet generated, but pre-populated for when they are)
  # -----------------------------------------------------------------------
  "XdrSequenceNumber" => { "sequenceNumber" => "XdrBigInt64" },
  "XdrLiquidityPoolDepositOp" => {
    "maxAmountA" => "XdrBigInt64",
    "maxAmountB" => "XdrBigInt64",
  },
  "XdrPreconditionsV2" => { "sequenceNumber" => "XdrBigInt64" },
  "XdrLiquidityPoolWithdrawOp" => {
    "amount" => "XdrBigInt64",
    "minAmountA" => "XdrBigInt64",
    "minAmountB" => "XdrBigInt64",
  },
  "XdrPathPaymentStrictReceiveOp" => {
    "sendMax" => "XdrBigInt64",
    "destAmount" => "XdrBigInt64",
  },
  "XdrPathPaymentStrictSendOp" => {
    "sendAmount" => "XdrBigInt64",
    "destMin" => "XdrBigInt64",
  },
}.freeze
