# Maps xdrgen canonical type names to existing Dart class names.
# Only includes types where the default "Xdr#{canonical_name}" convention
# does not produce the correct Dart class name.
#
# Convention: The generator prepends "Xdr" to every XDR type name by default.
# For nested types, the default is "{parent_dart_name}{field_camelize}".
# This map only records deviations from those conventions.
#
# Categories of overrides:
#   1. Renamed types (XDR name differs from Dart name minus "Xdr" prefix)
#   2. Shortened "Extension" names (e.g., AccountEntryExtensionV1 -> XdrAccountEntryV1)
#   3. Types whose Dart name lacks the "Xdr" prefix
#   4. Inline/nested types whose xdrgen qualified name differs from the Dart name
#   5. Multiple XDR types that share a single Dart class

NAME_OVERRIDES = {
  # ---------------------------------------------------------------------------
  # Stellar-ledger-entries.x -- top-level types
  # ---------------------------------------------------------------------------

  # AlphaNum4/12 -> XdrAssetAlphaNum4/12 (prefixed with "Asset")
  "AlphaNum4"                          => "XdrAssetAlphaNum4",
  "AlphaNum12"                         => "XdrAssetAlphaNum12",

  # TrustLineAsset -> XdrTrustlineAsset (lowercase 'l' in Dart)
  "TrustLineAsset"                     => "XdrTrustlineAsset",

  # AccountEntryExtensionV* -> XdrAccountEntryV* (shortened)
  "AccountEntryExtensionV1"            => "XdrAccountEntryV1",
  "AccountEntryExtensionV2"            => "XdrAccountEntryV2",
  "AccountEntryExtensionV3"            => "XdrAccountEntryV3",

  # ClaimableBalanceEntryExtensionV1 -> XdrClaimableBalanceEntryExtV1 (shortened)
  "ClaimableBalanceEntryExtensionV1"   => "XdrClaimableBalanceEntryExtV1",

  # TrustLineEntryExtensionV2: no Xdr prefix in Dart
  "TrustLineEntryExtensionV2"         => "TrustLineEntryExtensionV2",

  # LedgerEntryExtensionV1 -> XdrLedgerEntryV1 (shortened)
  "LedgerEntryExtensionV1"            => "XdrLedgerEntryV1",

  # ---------------------------------------------------------------------------
  # Stellar-ledger-entries.x -- inline/nested types
  # ---------------------------------------------------------------------------

  # TrustLineEntry.ext.v1 (anonymous struct) -- xdrgen raw name is
  # TrustLineEntryExtV1 but Dart class drops the "Ext" segment.
  "TrustLineEntryExtV1"               => "XdrTrustLineEntryV1",

  # LiquidityPoolEntry.body -> XdrLiquidityPoolBody (shortened)
  "LiquidityPoolEntryBody"            => "XdrLiquidityPoolBody",

  # LiquidityPoolEntry.body.constantProduct -> XdrConstantProduct (shortened)
  "LiquidityPoolEntryBodyConstantProduct" => "XdrConstantProduct",

  # LedgerKey.ttl inline struct -- casing: xdrgen produces "Ttl",
  # but Dart uses "TTL".
  "LedgerKeyTtl"                       => "XdrLedgerKeyTTL",

  # AssetCode -> XdrAllowTrustOpAsset (SDK uses legacy name for this union)
  "AssetCode"                          => "XdrAllowTrustOpAsset",

  # ---------------------------------------------------------------------------
  # Stellar-transaction.x -- top-level types
  # ---------------------------------------------------------------------------

  # MuxedEd25519Account -> XdrMuxedAccountMed25519 (renamed)
  "MuxedEd25519Account"                => "XdrMuxedAccountMed25519",

  # ManageSellOfferResult/Code -> XdrManageOfferResult/Code (renamed)
  "ManageSellOfferResult"              => "XdrManageOfferResult",
  "ManageSellOfferResultCode"          => "XdrManageOfferResultCode",

  # ManageBuyOfferResult/Code share the same Dart class as ManageSellOffer
  "ManageBuyOfferResult"               => "XdrManageOfferResult",
  "ManageBuyOfferResultCode"           => "XdrManageOfferResultCode",

  # ---------------------------------------------------------------------------
  # Stellar-transaction.x -- inline/nested types
  # ---------------------------------------------------------------------------

  # PathPaymentStrictReceiveResult.success -> XdrPathPaymentResultSuccess
  # (drops "StrictReceive" from the name)
  "PathPaymentStrictReceiveResultSuccess" => "XdrPathPaymentResultSuccess",

  # PathPaymentStrictSendResult.success shares the same Dart class
  "PathPaymentStrictSendResultSuccess" => "XdrPathPaymentResultSuccess",

  # RevokeSponsorshipOp.signer -> XdrRevokeSponsorshipSigner (drops "Op")
  "RevokeSponsorshipOpSigner"          => "XdrRevokeSponsorshipSigner",

  # ---------------------------------------------------------------------------
  # Stellar-types.x -- inline/nested types
  # ---------------------------------------------------------------------------

  # SignerKey.ed25519SignedPayload -> XdrSignedPayload (shortened)
  "SignerKeyEd25519SignedPayload"      => "XdrSignedPayload",

  # ---------------------------------------------------------------------------
  # Stellar-SCP.x -- inline/nested types
  # ---------------------------------------------------------------------------

  # SCPStatement.pledges.prepare/confirm/externalize -> drop "Pledges" segment
  "SCPStatementPledgesPrepare"         => "XdrSCPStatementPrepare",
  "SCPStatementPledgesConfirm"         => "XdrSCPStatementConfirm",
  "SCPStatementPledgesExternalize"     => "XdrSCPStatementExternalize",
}.freeze
