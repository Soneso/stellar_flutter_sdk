import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'sep51_corpus_data.dart';

/// The three crossings one corpus entry pins, bound to one XDR type.
///
/// SEP-0051 fixes a single rendering per value, so each crossing is a
/// byte-for-byte comparison rather than a structural one.
class _Binding {
  const _Binding({
    required this.jsonToJson,
    required this.jsonToXdr,
    required this.xdrToJson,
  });

  /// Parses the corpus JSON and renders it again.
  final String Function(String json) jsonToJson;

  /// Parses the corpus JSON and encodes it as binary XDR.
  final String Function(String json) jsonToXdr;

  /// Decodes the corpus binary XDR and renders it as JSON.
  final String Function(String xdr) xdrToJson;
}

_Binding _bind<T>(
  T Function(String) fromXdrJson,
  T Function(String) fromXdr,
  String Function(T) toXdrJson,
  String Function(T) toXdr,
) => _Binding(
  jsonToJson: (String json) => toXdrJson(fromXdrJson(json)),
  jsonToXdr: (String json) => toXdr(fromXdrJson(json)),
  xdrToJson: (String xdr) => toXdrJson(fromXdr(xdr)),
);

/// Resolves the SDK class named by a corpus entry's `dartType`.
///
/// Dart does not inherit static members, so a type split into a base and a
/// wrapper is bound through the wrapper: that is the class a caller holds and
/// the class whose `fromXdrJson` must resolve. Fifteen wrappers narrow the
/// XDR-JSON statics but not `fromBase64EncodedXdrString`, which is not part of
/// this feature's surface, so their binary entry point is spelled out as the
/// `decode` call that method performs.
///
/// The default throws. A corpus entry naming a type nobody dispatches is a gap
/// in this suite, and silently skipping it would let the entry pass unchecked
/// forever.
_Binding _bindingFor(String dartType) => switch (dartType) {
  'XdrAccountEntryExt' => _bind<XdrAccountEntryExt>(
    XdrAccountEntryExt.fromXdrJson,
    XdrAccountEntryExt.fromBase64EncodedXdrString,
    (XdrAccountEntryExt v) => v.toXdrJson(),
    (XdrAccountEntryExt v) => v.toBase64EncodedXdrString(),
  ),
  'XdrAccountEntryV1Ext' => _bind<XdrAccountEntryV1Ext>(
    XdrAccountEntryV1Ext.fromXdrJson,
    XdrAccountEntryV1Ext.fromBase64EncodedXdrString,
    (XdrAccountEntryV1Ext v) => v.toXdrJson(),
    (XdrAccountEntryV1Ext v) => v.toBase64EncodedXdrString(),
  ),
  'XdrAccountEntryV2' => _bind<XdrAccountEntryV2>(
    XdrAccountEntryV2.fromXdrJson,
    XdrAccountEntryV2.fromBase64EncodedXdrString,
    (XdrAccountEntryV2 v) => v.toXdrJson(),
    (XdrAccountEntryV2 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrAccountID' => _bind<XdrAccountID>(
    XdrAccountID.fromXdrJson,
    (String xdr) => XdrAccountID.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrAccountID v) => v.toXdrJson(),
    (XdrAccountID v) => v.toBase64EncodedXdrString(),
  ),
  'XdrAllowTrustOpAsset' => _bind<XdrAllowTrustOpAsset>(
    XdrAllowTrustOpAsset.fromXdrJson,
    XdrAllowTrustOpAsset.fromBase64EncodedXdrString,
    (XdrAllowTrustOpAsset v) => v.toXdrJson(),
    (XdrAllowTrustOpAsset v) => v.toBase64EncodedXdrString(),
  ),
  'XdrAsset' => _bind<XdrAsset>(
    XdrAsset.fromXdrJson,
    XdrAsset.fromBase64EncodedXdrString,
    (XdrAsset v) => v.toXdrJson(),
    (XdrAsset v) => v.toBase64EncodedXdrString(),
  ),
  'XdrAssetAlphaNum12' => _bind<XdrAssetAlphaNum12>(
    XdrAssetAlphaNum12.fromXdrJson,
    XdrAssetAlphaNum12.fromBase64EncodedXdrString,
    (XdrAssetAlphaNum12 v) => v.toXdrJson(),
    (XdrAssetAlphaNum12 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrAssetAlphaNum4' => _bind<XdrAssetAlphaNum4>(
    XdrAssetAlphaNum4.fromXdrJson,
    XdrAssetAlphaNum4.fromBase64EncodedXdrString,
    (XdrAssetAlphaNum4 v) => v.toXdrJson(),
    (XdrAssetAlphaNum4 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrBinaryFuseFilterType' => _bind<XdrBinaryFuseFilterType>(
    XdrBinaryFuseFilterType.fromXdrJson,
    XdrBinaryFuseFilterType.fromBase64EncodedXdrString,
    (XdrBinaryFuseFilterType v) => v.toXdrJson(),
    (XdrBinaryFuseFilterType v) => v.toBase64EncodedXdrString(),
  ),
  'XdrBucketEntry' => _bind<XdrBucketEntry>(
    XdrBucketEntry.fromXdrJson,
    XdrBucketEntry.fromBase64EncodedXdrString,
    (XdrBucketEntry v) => v.toXdrJson(),
    (XdrBucketEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrChangeTrustAsset' => _bind<XdrChangeTrustAsset>(
    XdrChangeTrustAsset.fromXdrJson,
    (String xdr) =>
        XdrChangeTrustAsset.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrChangeTrustAsset v) => v.toXdrJson(),
    (XdrChangeTrustAsset v) => v.toBase64EncodedXdrString(),
  ),
  'XdrClaimAtom' => _bind<XdrClaimAtom>(
    XdrClaimAtom.fromXdrJson,
    XdrClaimAtom.fromBase64EncodedXdrString,
    (XdrClaimAtom v) => v.toXdrJson(),
    (XdrClaimAtom v) => v.toBase64EncodedXdrString(),
  ),
  'XdrClaimPredicate' => _bind<XdrClaimPredicate>(
    XdrClaimPredicate.fromXdrJson,
    XdrClaimPredicate.fromBase64EncodedXdrString,
    (XdrClaimPredicate v) => v.toXdrJson(),
    (XdrClaimPredicate v) => v.toBase64EncodedXdrString(),
  ),
  'XdrClaimableBalanceID' => _bind<XdrClaimableBalanceID>(
    XdrClaimableBalanceID.fromXdrJson,
    (String xdr) =>
        XdrClaimableBalanceID.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrClaimableBalanceID v) => v.toXdrJson(),
    (XdrClaimableBalanceID v) => v.toBase64EncodedXdrString(),
  ),
  'XdrClaimant' => _bind<XdrClaimant>(
    XdrClaimant.fromXdrJson,
    XdrClaimant.fromBase64EncodedXdrString,
    (XdrClaimant v) => v.toXdrJson(),
    (XdrClaimant v) => v.toBase64EncodedXdrString(),
  ),
  'XdrConfigSettingEntry' => _bind<XdrConfigSettingEntry>(
    XdrConfigSettingEntry.fromXdrJson,
    XdrConfigSettingEntry.fromBase64EncodedXdrString,
    (XdrConfigSettingEntry v) => v.toXdrJson(),
    (XdrConfigSettingEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrContractCostParams' => _bind<XdrContractCostParams>(
    XdrContractCostParams.fromXdrJson,
    XdrContractCostParams.fromBase64EncodedXdrString,
    (XdrContractCostParams v) => v.toXdrJson(),
    (XdrContractCostParams v) => v.toBase64EncodedXdrString(),
  ),
  'XdrContractCostType' => _bind<XdrContractCostType>(
    XdrContractCostType.fromXdrJson,
    XdrContractCostType.fromBase64EncodedXdrString,
    (XdrContractCostType v) => v.toXdrJson(),
    (XdrContractCostType v) => v.toBase64EncodedXdrString(),
  ),
  'XdrContractDataEntry' => _bind<XdrContractDataEntry>(
    XdrContractDataEntry.fromXdrJson,
    XdrContractDataEntry.fromBase64EncodedXdrString,
    (XdrContractDataEntry v) => v.toXdrJson(),
    (XdrContractDataEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrContractEvent' => _bind<XdrContractEvent>(
    XdrContractEvent.fromXdrJson,
    XdrContractEvent.fromBase64EncodedXdrString,
    (XdrContractEvent v) => v.toXdrJson(),
    (XdrContractEvent v) => v.toBase64EncodedXdrString(),
  ),
  'XdrContractExecutable' => _bind<XdrContractExecutable>(
    XdrContractExecutable.fromXdrJson,
    (String xdr) =>
        XdrContractExecutable.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrContractExecutable v) => v.toXdrJson(),
    (XdrContractExecutable v) => v.toBase64EncodedXdrString(),
  ),
  'XdrContractIDPreimage' => _bind<XdrContractIDPreimage>(
    XdrContractIDPreimage.fromXdrJson,
    (String xdr) =>
        XdrContractIDPreimage.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrContractIDPreimage v) => v.toXdrJson(),
    (XdrContractIDPreimage v) => v.toBase64EncodedXdrString(),
  ),
  'XdrCurve25519Public' => _bind<XdrCurve25519Public>(
    XdrCurve25519Public.fromXdrJson,
    XdrCurve25519Public.fromBase64EncodedXdrString,
    (XdrCurve25519Public v) => v.toXdrJson(),
    (XdrCurve25519Public v) => v.toBase64EncodedXdrString(),
  ),
  'XdrCurve25519Secret' => _bind<XdrCurve25519Secret>(
    XdrCurve25519Secret.fromXdrJson,
    XdrCurve25519Secret.fromBase64EncodedXdrString,
    (XdrCurve25519Secret v) => v.toXdrJson(),
    (XdrCurve25519Secret v) => v.toBase64EncodedXdrString(),
  ),
  'XdrDataValue' => _bind<XdrDataValue>(
    XdrDataValue.fromXdrJson,
    XdrDataValue.fromBase64EncodedXdrString,
    (XdrDataValue v) => v.toXdrJson(),
    (XdrDataValue v) => v.toBase64EncodedXdrString(),
  ),
  'XdrDecoratedSignature' => _bind<XdrDecoratedSignature>(
    XdrDecoratedSignature.fromXdrJson,
    XdrDecoratedSignature.fromBase64EncodedXdrString,
    (XdrDecoratedSignature v) => v.toXdrJson(),
    (XdrDecoratedSignature v) => v.toBase64EncodedXdrString(),
  ),
  'XdrDiagnosticEvent' => _bind<XdrDiagnosticEvent>(
    XdrDiagnosticEvent.fromXdrJson,
    XdrDiagnosticEvent.fromBase64EncodedXdrString,
    (XdrDiagnosticEvent v) => v.toXdrJson(),
    (XdrDiagnosticEvent v) => v.toBase64EncodedXdrString(),
  ),
  'XdrDontHave' => _bind<XdrDontHave>(
    XdrDontHave.fromXdrJson,
    XdrDontHave.fromBase64EncodedXdrString,
    (XdrDontHave v) => v.toXdrJson(),
    (XdrDontHave v) => v.toBase64EncodedXdrString(),
  ),
  'XdrEnvelopeType' => _bind<XdrEnvelopeType>(
    XdrEnvelopeType.fromXdrJson,
    XdrEnvelopeType.fromBase64EncodedXdrString,
    (XdrEnvelopeType v) => v.toXdrJson(),
    (XdrEnvelopeType v) => v.toBase64EncodedXdrString(),
  ),
  'XdrExtensionPoint' => _bind<XdrExtensionPoint>(
    XdrExtensionPoint.fromXdrJson,
    XdrExtensionPoint.fromBase64EncodedXdrString,
    (XdrExtensionPoint v) => v.toXdrJson(),
    (XdrExtensionPoint v) => v.toBase64EncodedXdrString(),
  ),
  'XdrHash' => _bind<XdrHash>(
    XdrHash.fromXdrJson,
    XdrHash.fromBase64EncodedXdrString,
    (XdrHash v) => v.toXdrJson(),
    (XdrHash v) => v.toBase64EncodedXdrString(),
  ),
  'XdrHmacSha256Key' => _bind<XdrHmacSha256Key>(
    XdrHmacSha256Key.fromXdrJson,
    XdrHmacSha256Key.fromBase64EncodedXdrString,
    (XdrHmacSha256Key v) => v.toXdrJson(),
    (XdrHmacSha256Key v) => v.toBase64EncodedXdrString(),
  ),
  'XdrHmacSha256Mac' => _bind<XdrHmacSha256Mac>(
    XdrHmacSha256Mac.fromXdrJson,
    XdrHmacSha256Mac.fromBase64EncodedXdrString,
    (XdrHmacSha256Mac v) => v.toXdrJson(),
    (XdrHmacSha256Mac v) => v.toBase64EncodedXdrString(),
  ),
  'XdrHostFunction' => _bind<XdrHostFunction>(
    XdrHostFunction.fromXdrJson,
    (String xdr) =>
        XdrHostFunction.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrHostFunction v) => v.toXdrJson(),
    (XdrHostFunction v) => v.toBase64EncodedXdrString(),
  ),
  'XdrHotArchiveBucketEntry' => _bind<XdrHotArchiveBucketEntry>(
    XdrHotArchiveBucketEntry.fromXdrJson,
    XdrHotArchiveBucketEntry.fromBase64EncodedXdrString,
    (XdrHotArchiveBucketEntry v) => v.toXdrJson(),
    (XdrHotArchiveBucketEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrInt128Parts' => _bind<XdrInt128Parts>(
    XdrInt128Parts.fromXdrJson,
    (String xdr) =>
        XdrInt128Parts.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrInt128Parts v) => v.toXdrJson(),
    (XdrInt128Parts v) => v.toBase64EncodedXdrString(),
  ),
  'XdrInt256Parts' => _bind<XdrInt256Parts>(
    XdrInt256Parts.fromXdrJson,
    (String xdr) =>
        XdrInt256Parts.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrInt256Parts v) => v.toXdrJson(),
    (XdrInt256Parts v) => v.toBase64EncodedXdrString(),
  ),
  'XdrInt32' => _bind<XdrInt32>(
    XdrInt32.fromXdrJson,
    XdrInt32.fromBase64EncodedXdrString,
    (XdrInt32 v) => v.toXdrJson(),
    (XdrInt32 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrInt64' => _bind<XdrInt64>(
    XdrInt64.fromXdrJson,
    XdrInt64.fromBase64EncodedXdrString,
    (XdrInt64 v) => v.toXdrJson(),
    (XdrInt64 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrInvokeContractArgs' => _bind<XdrInvokeContractArgs>(
    XdrInvokeContractArgs.fromXdrJson,
    XdrInvokeContractArgs.fromBase64EncodedXdrString,
    (XdrInvokeContractArgs v) => v.toXdrJson(),
    (XdrInvokeContractArgs v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerBounds' => _bind<XdrLedgerBounds>(
    XdrLedgerBounds.fromXdrJson,
    XdrLedgerBounds.fromBase64EncodedXdrString,
    (XdrLedgerBounds v) => v.toXdrJson(),
    (XdrLedgerBounds v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerCloseMetaExt' => _bind<XdrLedgerCloseMetaExt>(
    XdrLedgerCloseMetaExt.fromXdrJson,
    XdrLedgerCloseMetaExt.fromBase64EncodedXdrString,
    (XdrLedgerCloseMetaExt v) => v.toXdrJson(),
    (XdrLedgerCloseMetaExt v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerEntry' => _bind<XdrLedgerEntry>(
    XdrLedgerEntry.fromXdrJson,
    XdrLedgerEntry.fromBase64EncodedXdrString,
    (XdrLedgerEntry v) => v.toXdrJson(),
    (XdrLedgerEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerEntryChange' => _bind<XdrLedgerEntryChange>(
    XdrLedgerEntryChange.fromXdrJson,
    XdrLedgerEntryChange.fromBase64EncodedXdrString,
    (XdrLedgerEntryChange v) => v.toXdrJson(),
    (XdrLedgerEntryChange v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerEntryChanges' => _bind<XdrLedgerEntryChanges>(
    XdrLedgerEntryChanges.fromXdrJson,
    XdrLedgerEntryChanges.fromBase64EncodedXdrString,
    (XdrLedgerEntryChanges v) => v.toXdrJson(),
    (XdrLedgerEntryChanges v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerEntryData' => _bind<XdrLedgerEntryData>(
    XdrLedgerEntryData.fromXdrJson,
    XdrLedgerEntryData.fromBase64EncodedXdrString,
    (XdrLedgerEntryData v) => v.toXdrJson(),
    (XdrLedgerEntryData v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerEntryExt' => _bind<XdrLedgerEntryExt>(
    XdrLedgerEntryExt.fromXdrJson,
    XdrLedgerEntryExt.fromBase64EncodedXdrString,
    (XdrLedgerEntryExt v) => v.toXdrJson(),
    (XdrLedgerEntryExt v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerFootprint' => _bind<XdrLedgerFootprint>(
    XdrLedgerFootprint.fromXdrJson,
    XdrLedgerFootprint.fromBase64EncodedXdrString,
    (XdrLedgerFootprint v) => v.toXdrJson(),
    (XdrLedgerFootprint v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerHeader' => _bind<XdrLedgerHeader>(
    XdrLedgerHeader.fromXdrJson,
    XdrLedgerHeader.fromBase64EncodedXdrString,
    (XdrLedgerHeader v) => v.toXdrJson(),
    (XdrLedgerHeader v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerKey' => _bind<XdrLedgerKey>(
    XdrLedgerKey.fromXdrJson,
    XdrLedgerKey.fromBase64EncodedXdrString,
    (XdrLedgerKey v) => v.toXdrJson(),
    (XdrLedgerKey v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLedgerKeyLiquidityPool' => _bind<XdrLedgerKeyLiquidityPool>(
    XdrLedgerKeyLiquidityPool.fromXdrJson,
    XdrLedgerKeyLiquidityPool.fromBase64EncodedXdrString,
    (XdrLedgerKeyLiquidityPool v) => v.toXdrJson(),
    (XdrLedgerKeyLiquidityPool v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLiabilities' => _bind<XdrLiabilities>(
    XdrLiabilities.fromXdrJson,
    XdrLiabilities.fromBase64EncodedXdrString,
    (XdrLiabilities v) => v.toXdrJson(),
    (XdrLiabilities v) => v.toBase64EncodedXdrString(),
  ),
  'XdrLiquidityPoolParameters' => _bind<XdrLiquidityPoolParameters>(
    XdrLiquidityPoolParameters.fromXdrJson,
    XdrLiquidityPoolParameters.fromBase64EncodedXdrString,
    (XdrLiquidityPoolParameters v) => v.toXdrJson(),
    (XdrLiquidityPoolParameters v) => v.toBase64EncodedXdrString(),
  ),
  'XdrManageDataOp' => _bind<XdrManageDataOp>(
    XdrManageDataOp.fromXdrJson,
    XdrManageDataOp.fromBase64EncodedXdrString,
    (XdrManageDataOp v) => v.toXdrJson(),
    (XdrManageDataOp v) => v.toBase64EncodedXdrString(),
  ),
  'XdrMemo' => _bind<XdrMemo>(
    XdrMemo.fromXdrJson,
    XdrMemo.fromBase64EncodedXdrString,
    (XdrMemo v) => v.toXdrJson(),
    (XdrMemo v) => v.toBase64EncodedXdrString(),
  ),
  'XdrMuxedAccount' => _bind<XdrMuxedAccount>(
    XdrMuxedAccount.fromXdrJson,
    XdrMuxedAccount.fromBase64EncodedXdrString,
    (XdrMuxedAccount v) => v.toXdrJson(),
    (XdrMuxedAccount v) => v.toBase64EncodedXdrString(),
  ),
  'XdrNodeID' => _bind<XdrNodeID>(
    XdrNodeID.fromXdrJson,
    XdrNodeID.fromBase64EncodedXdrString,
    (XdrNodeID v) => v.toXdrJson(),
    (XdrNodeID v) => v.toBase64EncodedXdrString(),
  ),
  'XdrOperation' => _bind<XdrOperation>(
    XdrOperation.fromXdrJson,
    XdrOperation.fromBase64EncodedXdrString,
    (XdrOperation v) => v.toXdrJson(),
    (XdrOperation v) => v.toBase64EncodedXdrString(),
  ),
  'XdrOperationBody' => _bind<XdrOperationBody>(
    XdrOperationBody.fromXdrJson,
    XdrOperationBody.fromBase64EncodedXdrString,
    (XdrOperationBody v) => v.toXdrJson(),
    (XdrOperationBody v) => v.toBase64EncodedXdrString(),
  ),
  'XdrOperationResult' => _bind<XdrOperationResult>(
    XdrOperationResult.fromXdrJson,
    XdrOperationResult.fromBase64EncodedXdrString,
    (XdrOperationResult v) => v.toXdrJson(),
    (XdrOperationResult v) => v.toBase64EncodedXdrString(),
  ),
  'XdrPeerAddress' => _bind<XdrPeerAddress>(
    XdrPeerAddress.fromXdrJson,
    XdrPeerAddress.fromBase64EncodedXdrString,
    (XdrPeerAddress v) => v.toXdrJson(),
    (XdrPeerAddress v) => v.toBase64EncodedXdrString(),
  ),
  'XdrPreconditions' => _bind<XdrPreconditions>(
    XdrPreconditions.fromXdrJson,
    XdrPreconditions.fromBase64EncodedXdrString,
    (XdrPreconditions v) => v.toXdrJson(),
    (XdrPreconditions v) => v.toBase64EncodedXdrString(),
  ),
  'XdrPreconditionsV2' => _bind<XdrPreconditionsV2>(
    XdrPreconditionsV2.fromXdrJson,
    XdrPreconditionsV2.fromBase64EncodedXdrString,
    (XdrPreconditionsV2 v) => v.toXdrJson(),
    (XdrPreconditionsV2 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrPrice' => _bind<XdrPrice>(
    XdrPrice.fromXdrJson,
    XdrPrice.fromBase64EncodedXdrString,
    (XdrPrice v) => v.toXdrJson(),
    (XdrPrice v) => v.toBase64EncodedXdrString(),
  ),
  'XdrPublicKey' => _bind<XdrPublicKey>(
    XdrPublicKey.fromXdrJson,
    (String xdr) => XdrPublicKey.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrPublicKey v) => v.toXdrJson(),
    (XdrPublicKey v) => v.toBase64EncodedXdrString(),
  ),
  'XdrRevokeSponsorshipOp' => _bind<XdrRevokeSponsorshipOp>(
    XdrRevokeSponsorshipOp.fromXdrJson,
    XdrRevokeSponsorshipOp.fromBase64EncodedXdrString,
    (XdrRevokeSponsorshipOp v) => v.toXdrJson(),
    (XdrRevokeSponsorshipOp v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCAddress' => _bind<XdrSCAddress>(
    XdrSCAddress.fromXdrJson,
    (String xdr) => XdrSCAddress.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrSCAddress v) => v.toXdrJson(),
    (XdrSCAddress v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCBytes' => _bind<XdrSCBytes>(
    XdrSCBytes.fromXdrJson,
    XdrSCBytes.fromBase64EncodedXdrString,
    (XdrSCBytes v) => v.toXdrJson(),
    (XdrSCBytes v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCContractInstance' => _bind<XdrSCContractInstance>(
    XdrSCContractInstance.fromXdrJson,
    XdrSCContractInstance.fromBase64EncodedXdrString,
    (XdrSCContractInstance v) => v.toXdrJson(),
    (XdrSCContractInstance v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCEnvMetaEntry' => _bind<XdrSCEnvMetaEntry>(
    XdrSCEnvMetaEntry.fromXdrJson,
    XdrSCEnvMetaEntry.fromBase64EncodedXdrString,
    (XdrSCEnvMetaEntry v) => v.toXdrJson(),
    (XdrSCEnvMetaEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCError' => _bind<XdrSCError>(
    XdrSCError.fromXdrJson,
    XdrSCError.fromBase64EncodedXdrString,
    (XdrSCError v) => v.toXdrJson(),
    (XdrSCError v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCMapEntry' => _bind<XdrSCMapEntry>(
    XdrSCMapEntry.fromXdrJson,
    XdrSCMapEntry.fromBase64EncodedXdrString,
    (XdrSCMapEntry v) => v.toXdrJson(),
    (XdrSCMapEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCMetaEntry' => _bind<XdrSCMetaEntry>(
    XdrSCMetaEntry.fromXdrJson,
    XdrSCMetaEntry.fromBase64EncodedXdrString,
    (XdrSCMetaEntry v) => v.toXdrJson(),
    (XdrSCMetaEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCNonceKey' => _bind<XdrSCNonceKey>(
    XdrSCNonceKey.fromXdrJson,
    XdrSCNonceKey.fromBase64EncodedXdrString,
    (XdrSCNonceKey v) => v.toXdrJson(),
    (XdrSCNonceKey v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecEntry' => _bind<XdrSCSpecEntry>(
    XdrSCSpecEntry.fromXdrJson,
    XdrSCSpecEntry.fromBase64EncodedXdrString,
    (XdrSCSpecEntry v) => v.toXdrJson(),
    (XdrSCSpecEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecEventParamV0' => _bind<XdrSCSpecEventParamV0>(
    XdrSCSpecEventParamV0.fromXdrJson,
    XdrSCSpecEventParamV0.fromBase64EncodedXdrString,
    (XdrSCSpecEventParamV0 v) => v.toXdrJson(),
    (XdrSCSpecEventParamV0 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecFunctionInputV0' => _bind<XdrSCSpecFunctionInputV0>(
    XdrSCSpecFunctionInputV0.fromXdrJson,
    XdrSCSpecFunctionInputV0.fromBase64EncodedXdrString,
    (XdrSCSpecFunctionInputV0 v) => v.toXdrJson(),
    (XdrSCSpecFunctionInputV0 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecFunctionV0' => _bind<XdrSCSpecFunctionV0>(
    XdrSCSpecFunctionV0.fromXdrJson,
    XdrSCSpecFunctionV0.fromBase64EncodedXdrString,
    (XdrSCSpecFunctionV0 v) => v.toXdrJson(),
    (XdrSCSpecFunctionV0 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecTypeDef' => _bind<XdrSCSpecTypeDef>(
    XdrSCSpecTypeDef.fromXdrJson,
    (String xdr) =>
        XdrSCSpecTypeDef.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrSCSpecTypeDef v) => v.toXdrJson(),
    (XdrSCSpecTypeDef v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecUDTStructFieldV0' => _bind<XdrSCSpecUDTStructFieldV0>(
    XdrSCSpecUDTStructFieldV0.fromXdrJson,
    XdrSCSpecUDTStructFieldV0.fromBase64EncodedXdrString,
    (XdrSCSpecUDTStructFieldV0 v) => v.toXdrJson(),
    (XdrSCSpecUDTStructFieldV0 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecUDTUnionCaseTupleV0' => _bind<XdrSCSpecUDTUnionCaseTupleV0>(
    XdrSCSpecUDTUnionCaseTupleV0.fromXdrJson,
    XdrSCSpecUDTUnionCaseTupleV0.fromBase64EncodedXdrString,
    (XdrSCSpecUDTUnionCaseTupleV0 v) => v.toXdrJson(),
    (XdrSCSpecUDTUnionCaseTupleV0 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCSpecUDTUnionCaseV0' => _bind<XdrSCSpecUDTUnionCaseV0>(
    XdrSCSpecUDTUnionCaseV0.fromXdrJson,
    XdrSCSpecUDTUnionCaseV0.fromBase64EncodedXdrString,
    (XdrSCSpecUDTUnionCaseV0 v) => v.toXdrJson(),
    (XdrSCSpecUDTUnionCaseV0 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSCVal' => _bind<XdrSCVal>(
    XdrSCVal.fromXdrJson,
    XdrSCVal.fromBase64EncodedXdrString,
    (XdrSCVal v) => v.toXdrJson(),
    (XdrSCVal v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSequenceNumber' => _bind<XdrSequenceNumber>(
    XdrSequenceNumber.fromXdrJson,
    XdrSequenceNumber.fromBase64EncodedXdrString,
    (XdrSequenceNumber v) => v.toXdrJson(),
    (XdrSequenceNumber v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSerializedBinaryFuseFilter' => _bind<XdrSerializedBinaryFuseFilter>(
    XdrSerializedBinaryFuseFilter.fromXdrJson,
    XdrSerializedBinaryFuseFilter.fromBase64EncodedXdrString,
    (XdrSerializedBinaryFuseFilter v) => v.toXdrJson(),
    (XdrSerializedBinaryFuseFilter v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSetOptionsOp' => _bind<XdrSetOptionsOp>(
    XdrSetOptionsOp.fromXdrJson,
    XdrSetOptionsOp.fromBase64EncodedXdrString,
    (XdrSetOptionsOp v) => v.toXdrJson(),
    (XdrSetOptionsOp v) => v.toBase64EncodedXdrString(),
  ),
  'XdrShortHashSeed' => _bind<XdrShortHashSeed>(
    XdrShortHashSeed.fromXdrJson,
    XdrShortHashSeed.fromBase64EncodedXdrString,
    (XdrShortHashSeed v) => v.toXdrJson(),
    (XdrShortHashSeed v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSignerKey' => _bind<XdrSignerKey>(
    XdrSignerKey.fromXdrJson,
    XdrSignerKey.fromBase64EncodedXdrString,
    (XdrSignerKey v) => v.toXdrJson(),
    (XdrSignerKey v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSorobanAuthorizationEntry' => _bind<XdrSorobanAuthorizationEntry>(
    XdrSorobanAuthorizationEntry.fromXdrJson,
    XdrSorobanAuthorizationEntry.fromBase64EncodedXdrString,
    (XdrSorobanAuthorizationEntry v) => v.toXdrJson(),
    (XdrSorobanAuthorizationEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSorobanAuthorizedInvocation' => _bind<XdrSorobanAuthorizedInvocation>(
    XdrSorobanAuthorizedInvocation.fromXdrJson,
    XdrSorobanAuthorizedInvocation.fromBase64EncodedXdrString,
    (XdrSorobanAuthorizedInvocation v) => v.toXdrJson(),
    (XdrSorobanAuthorizedInvocation v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSorobanCredentials' => _bind<XdrSorobanCredentials>(
    XdrSorobanCredentials.fromXdrJson,
    (String xdr) =>
        XdrSorobanCredentials.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrSorobanCredentials v) => v.toXdrJson(),
    (XdrSorobanCredentials v) => v.toBase64EncodedXdrString(),
  ),
  'XdrSorobanTransactionMetaExt' => _bind<XdrSorobanTransactionMetaExt>(
    XdrSorobanTransactionMetaExt.fromXdrJson,
    XdrSorobanTransactionMetaExt.fromBase64EncodedXdrString,
    (XdrSorobanTransactionMetaExt v) => v.toXdrJson(),
    (XdrSorobanTransactionMetaExt v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTTLEntry' => _bind<XdrTTLEntry>(
    XdrTTLEntry.fromXdrJson,
    XdrTTLEntry.fromBase64EncodedXdrString,
    (XdrTTLEntry v) => v.toXdrJson(),
    (XdrTTLEntry v) => v.toBase64EncodedXdrString(),
  ),
  'XdrThresholdIndexes' => _bind<XdrThresholdIndexes>(
    XdrThresholdIndexes.fromXdrJson,
    XdrThresholdIndexes.fromBase64EncodedXdrString,
    (XdrThresholdIndexes v) => v.toXdrJson(),
    (XdrThresholdIndexes v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTimeBounds' => _bind<XdrTimeBounds>(
    XdrTimeBounds.fromXdrJson,
    XdrTimeBounds.fromBase64EncodedXdrString,
    (XdrTimeBounds v) => v.toXdrJson(),
    (XdrTimeBounds v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTransactionEnvelope' => _bind<XdrTransactionEnvelope>(
    XdrTransactionEnvelope.fromXdrJson,
    XdrTransactionEnvelope.fromBase64EncodedXdrString,
    (XdrTransactionEnvelope v) => v.toXdrJson(),
    (XdrTransactionEnvelope v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTransactionMeta' => _bind<XdrTransactionMeta>(
    XdrTransactionMeta.fromXdrJson,
    XdrTransactionMeta.fromBase64EncodedXdrString,
    (XdrTransactionMeta v) => v.toXdrJson(),
    (XdrTransactionMeta v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTransactionPhase' => _bind<XdrTransactionPhase>(
    XdrTransactionPhase.fromXdrJson,
    XdrTransactionPhase.fromBase64EncodedXdrString,
    (XdrTransactionPhase v) => v.toXdrJson(),
    (XdrTransactionPhase v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTransactionResult' => _bind<XdrTransactionResult>(
    XdrTransactionResult.fromXdrJson,
    XdrTransactionResult.fromBase64EncodedXdrString,
    (XdrTransactionResult v) => v.toXdrJson(),
    (XdrTransactionResult v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTrustLineEntryExt' => _bind<XdrTrustLineEntryExt>(
    XdrTrustLineEntryExt.fromXdrJson,
    XdrTrustLineEntryExt.fromBase64EncodedXdrString,
    (XdrTrustLineEntryExt v) => v.toXdrJson(),
    (XdrTrustLineEntryExt v) => v.toBase64EncodedXdrString(),
  ),
  'XdrTrustlineAsset' => _bind<XdrTrustlineAsset>(
    XdrTrustlineAsset.fromXdrJson,
    (String xdr) =>
        XdrTrustlineAsset.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrTrustlineAsset v) => v.toXdrJson(),
    (XdrTrustlineAsset v) => v.toBase64EncodedXdrString(),
  ),
  'XdrUInt128Parts' => _bind<XdrUInt128Parts>(
    XdrUInt128Parts.fromXdrJson,
    (String xdr) =>
        XdrUInt128Parts.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrUInt128Parts v) => v.toXdrJson(),
    (XdrUInt128Parts v) => v.toBase64EncodedXdrString(),
  ),
  'XdrUInt256Parts' => _bind<XdrUInt256Parts>(
    XdrUInt256Parts.fromXdrJson,
    (String xdr) =>
        XdrUInt256Parts.decode(XdrDataInputStream(base64Decode(xdr))),
    (XdrUInt256Parts v) => v.toXdrJson(),
    (XdrUInt256Parts v) => v.toBase64EncodedXdrString(),
  ),
  'XdrUint256' => _bind<XdrUint256>(
    XdrUint256.fromXdrJson,
    XdrUint256.fromBase64EncodedXdrString,
    (XdrUint256 v) => v.toXdrJson(),
    (XdrUint256 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrUint32' => _bind<XdrUint32>(
    XdrUint32.fromXdrJson,
    XdrUint32.fromBase64EncodedXdrString,
    (XdrUint32 v) => v.toXdrJson(),
    (XdrUint32 v) => v.toBase64EncodedXdrString(),
  ),
  'XdrUint64' => _bind<XdrUint64>(
    XdrUint64.fromXdrJson,
    XdrUint64.fromBase64EncodedXdrString,
    (XdrUint64 v) => v.toXdrJson(),
    (XdrUint64 v) => v.toBase64EncodedXdrString(),
  ),
  _ => throw StateError(
    'The SEP-0051 corpus names the XDR type $dartType, which this suite does '
    'not dispatch. Add it to _bindingFor rather than letting the entry go '
    'unchecked.',
  ),
};

void main() {
  group('SEP-0051 corpus provenance', () {
    test('records the reference build the expected values come from', () {
      expect(sep51CorpusMetadata['reference_tool'], 'stellar-xdr');
      expect(sep51CorpusMetadata['reference_version'], '28.0.0');
      expect(
        sep51CorpusMetadata['reference_xdr_commit'],
        '9c9c145953e80990d6ff1ae3a6a973a0ce6d0694',
      );
      expect(
        sep51CorpusMetadata['sdk_xdr_commit'],
        '911c9356277468cb588481bd90b5d4b6eda395a7',
      );
    });

    test('carries every entry its own metadata counts', () {
      expect(sep51CorpusMetadata['entry_count'], '${sep51Corpus.length}');
      expect(sep51Corpus, isNotEmpty);
    });

    test('leaves no type or member unresolved by the reference build', () {
      // A non-empty list means the reference could not address part of the
      // type set, so the affected expected values were never compared against
      // it and need spec-derived fixtures instead.
      expect(sep51CorpusMetadata['unresolvable_enum_members'], '');
      expect(sep51CorpusMetadata['unresolvable_struct_types'], '');
    });

    test('holds a live divergence for every incomparable entry', () {
      final Iterable<Sep51CorpusEntry> incomparable = sep51Corpus.where(
        (Sep51CorpusEntry e) => e.oracle == 'incomparable',
      );
      expect(incomparable, isNotEmpty);
      for (final Sep51CorpusEntry entry in incomparable) {
        final String where = '${entry.type} ${entry.xdr}';
        expect(entry.reason, isNotNull, reason: where);
        expect(entry.oracleJson, isNotNull, reason: where);
        // The exclusion states that this SDK and the reference disagree. If
        // they ever agree the exclusion has expired and the entry belongs back
        // in the compared set.
        expect(entry.oracleJson, isNot(entry.json), reason: where);
      }
    });

    test('records no reference text for a comparable entry', () {
      for (final Sep51CorpusEntry entry in sep51Corpus) {
        if (entry.oracle == 'reference') {
          expect(
            entry.oracleJson,
            isNull,
            reason: '${entry.type} ${entry.xdr}',
          );
        } else {
          expect(entry.oracle, 'incomparable', reason: entry.type);
        }
      }
    });
  });

  group('SEP-0051 corpus type dispatch', () {
    test('dispatches every type the corpus names', () {
      final Set<String> named = sep51Corpus
          .map((Sep51CorpusEntry e) => e.dartType)
          .toSet();
      expect(named, isNotEmpty);
      for (final String dartType in named) {
        expect(
          () => _bindingFor(dartType),
          returnsNormally,
          reason: 'no binding for $dartType',
        );
      }
    });

    test('refuses a type it does not dispatch rather than skipping it', () {
      expect(
        () => _bindingFor('XdrTypeThatIsNotDispatched'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // Every entry of the corpus is registered as its own test, so a failure
  // names the value that failed and never masks the entries after it.
  group('SEP-0051 corpus round trips', () {
    for (int i = 0; i < sep51Corpus.length; i++) {
      final Sep51CorpusEntry entry = sep51Corpus[i];
      final String label = entry.note == null
          ? '${entry.type} [$i]'
          : '${entry.type} [$i]: ${entry.note}';

      test(label, () {
        final _Binding binding = _bindingFor(entry.dartType);

        expect(
          binding.jsonToJson(entry.json),
          entry.json,
          reason: 'JSON rendering is not byte-identical after parsing',
        );
        expect(
          binding.jsonToXdr(entry.json),
          entry.xdr,
          reason: 'JSON parsed to a value that encodes to different XDR',
        );
        expect(
          binding.xdrToJson(entry.xdr),
          entry.json,
          reason: 'XDR decoded to a value that renders as different JSON',
        );
      });
    }
  });
}
