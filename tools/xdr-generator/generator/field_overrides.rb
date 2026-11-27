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
    "external_ref" => "externalRef",
  },
  # ContractExecutableExternalRef: XDR executable_owner → SDK camelCase
  "XdrContractExecutableExternalRef" => {
    "executable_owner" => "executableOwner",
  },
  # SCVal: XDR executable_tag → SDK camelCase
  "XdrSCVal" => {
    "executable_tag" => "executableTag",
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

# XDR `string` fields the SDK stores as raw bytes rather than as Dart text.
#
# An XDR `string` holds arbitrary bytes. A field listed here stores them as a
# Uint8List and keeps the `string` wire form -- a length prefix, the bytes, and
# padding to a multiple of four. Encoding, TxRep and XDR-JSON read and write
# the stored bytes, so a value that is not UTF-8 round-trips exactly. An entry
# takes one of two forms:
#
#   "xdrFieldName" => "utf8GetterName"
#     The field itself is a Uint8List. The named getter reads it as text.
#   "xdrFieldName" => { bytes: "bytesAccessorName" }
#     The field keeps its String getter, setter and constructor parameter,
#     which read the stored bytes as text and store the UTF-8 encoding of the
#     text they are given. The named getter and setter read and write the
#     bytes. A struct with such a field also gets a constructor that takes the
#     bytes.
#
# Text reads go through XdrUtf8.decode: every leading byte order mark is kept,
# and bytes that are not valid UTF-8 throw a FormatException.
#
# Key: DartClassName => { "xdrFieldName" => "utf8GetterName" or { bytes: "bytesAccessorName" } }
#
# The xdrFieldName is the name from the .x file, before any FIELD_OVERRIDES
# renaming.

BYTES_BACKED_STRING_FIELDS = {
  "XdrContractExecutableExternalRef" => { "tag" => "tagString" },
  "XdrInvokeContractArgs" => { "functionName" => { bytes: "functionNameBytes" } },
  "XdrMemo" => { "text" => { bytes: "textBytes" } },
  "XdrSCVal" => {
    "executable_tag" => "executableTagString",
    "str" => { bytes: "strBytes" },
    "sym" => { bytes: "symBytes" },
  },
}.freeze
