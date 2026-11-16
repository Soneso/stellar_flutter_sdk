// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../soroban/soroban_auth.dart';
import '../../soroban/soroban_server.dart';
import '../../util.dart';
import '../../xdr/xdr.dart';
import '../core/smart_account_errors.dart';
import 'oz_address_strkey.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_smart_account_auth.dart';
import 'oz_validation.dart';

// The auth digest internals of the signing pipelines: the stellar-accounts
// 0.8.0 preimage and the read of the wallet's code before any signer is
// asked. Not re-exported by the public barrel.

const int _signaturePayloadSize = 32;

/// Encodes the `AuthDigestPreimage` contract struct of stellar-accounts
/// 0.8.0: an `ScVal::Map` with the Symbol keys in name order, `account`,
/// `context_rule_ids` and `signature_payload`.
///
/// [account] is the smart account performing the authorization check,
/// [signaturePayload] the 32-byte payload the host passes to `__check_auth`
/// and [contextRuleIds] the context rule IDs, one per auth context, encoded
/// as `U32`; the caller passes u32 values.
///
/// Throws [ArgumentError] when [signaturePayload] is not 32 bytes.
@internal
XdrSCVal ozBuildAuthDigestPreimage(
  XdrSCAddress account,
  Uint8List signaturePayload,
  List<int> contextRuleIds,
) {
  if (signaturePayload.length != _signaturePayloadSize) {
    throw ArgumentError(
      'Signature payload must be $_signaturePayloadSize bytes, '
      'got ${signaturePayload.length}',
    );
  }
  return XdrSCVal.forMap(<XdrSCMapEntry>[
    XdrSCMapEntry(XdrSCVal.forSymbol('account'), XdrSCVal.forAddress(account)),
    XdrSCMapEntry(
      XdrSCVal.forSymbol('context_rule_ids'),
      XdrSCVal.forVec(
        contextRuleIds.map(XdrSCVal.forU32).toList(growable: false),
      ),
    ),
    XdrSCMapEntry(
      XdrSCVal.forSymbol('signature_payload'),
      XdrSCVal.forBytes(signaturePayload),
    ),
  ]);
}

/// The state one signing operation signs against, read before any signer is
/// asked.
@internal
class OZSigningOperationState {
  /// Constructs the state of one signing operation.
  const OZSigningOperationState({
    required this.authDigestScheme,
    required this.expirationLedger,
  });

  /// The digest scheme of the wallet's code, or `null` when no auth entry
  /// belongs to the wallet and no instance read was made.
  final OZAuthDigestScheme? authDigestScheme;

  /// The ledger at which the signatures expire.
  final int expirationLedger;
}

/// Prepares one signing operation over the simulated [authEntries] for the
/// smart account [contractId]. Both signing pipelines call it once, before
/// they ask any signer.
///
/// For each auth entry of the smart account, validates the signers its
/// invocation tree adds to the wallet ([requireValidAddedSigners]). With at
/// least one such entry, reads the wallet's instance once and takes the
/// signature expiration from the latest ledger of that response; otherwise
/// reads the latest ledger alone and makes no instance read.
///
/// Throws [SmartAccountValidationException] when an added signer is
/// refused, [SmartAccountTransactionSigningFailed] when an added signer is
/// malformed or the returned entry is not a contract instance, and
/// [SmartAccountTransactionSubmissionFailed] when the RPC reports an error
/// or no latest ledger.
@internal
Future<OZSigningOperationState> ozPrepareSigningOperation(
  OZSmartAccountKitInterface kit,
  String contractId,
  List<XdrSorobanAuthorizationEntry> authEntries,
) async {
  final walletEntries = authEntries
      .where((entry) => _belongsTo(entry, contractId))
      .toList(growable: false);
  for (final entry in walletEntries) {
    await requireValidAddedSigners(entry, contractId);
  }

  final expirationLedgers = kit.config.signatureExpirationLedgers;
  if (walletEntries.isEmpty) {
    final latestLedger = await kit.sorobanServer.getLatestLedger();
    final sequence = latestLedger.sequence;
    if (sequence == null) {
      throw SmartAccountTransactionException.submissionFailed(
        'Failed to fetch latest ledger sequence',
      );
    }
    return OZSigningOperationState(
      authDigestScheme: null,
      expirationLedger: sequence + expirationLedgers,
    );
  }

  final read = await _readAuthDigestScheme(kit, contractId);
  return OZSigningOperationState(
    authDigestScheme: read.scheme,
    expirationLedger: read.latestLedger + expirationLedgers,
  );
}

/// Whether the signing pipelines sign [entry] for the smart account
/// [contractId]: ADDRESS or ADDRESS_V2 credentials of its address. The
/// pipelines refuse ADDRESS_WITH_DELEGATES entries without signing them.
bool _belongsTo(XdrSorobanAuthorizationEntry entry, String contractId) {
  final credentials = entry.credentials;
  final XdrSorobanAddressCredentials? inner;
  switch (credentials.discriminant) {
    case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
      inner = credentials.address;
    case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2:
      inner = credentials.addressV2;
    default:
      inner = null;
  }
  return inner != null && OZAddressStrKey.fromXdr(inner.address) == contractId;
}

/// Reads the WASM hash the smart account [contractId] runs and maps it to
/// its digest scheme with [OZSmartAccountConfig.authDigestSchemeFor].
///
/// One `getLedgerEntries` request for the persistent contract instance
/// entry. A WASM executable maps through the configured and built-in
/// tables; an external reference, a Stellar Asset executable or a missing
/// entry signs with [OZAuthDigestScheme.legacyConcat]. The RPC client
/// returns errors inside the response, so an error response throws here
/// and is never read as a missing entry.
Future<({OZAuthDigestScheme scheme, int latestLedger})> _readAuthDigestScheme(
  OZSmartAccountKitInterface kit,
  String contractId,
) async {
  final ledgerKey = XdrLedgerKey(XdrLedgerEntryType.CONTRACT_DATA)
    ..contractData = XdrLedgerKeyContractData(
      Address.forContractId(contractId).toXdr(),
      XdrSCVal.forLedgerKeyContractInstance(),
      XdrContractDataDurability.PERSISTENT,
    );
  final response = await kit.sorobanServer.getLedgerEntries(<String>[
    ledgerKey.toBase64EncodedXdrString(),
  ]);

  final error = response.error;
  if (error != null) {
    throw SmartAccountTransactionException.submissionFailed(
      'Failed to read the instance of $contractId to select its auth digest '
      'scheme: RPC error ${error.code}: ${error.message}',
    );
  }
  final latestLedger = response.latestLedger;
  if (latestLedger == null) {
    throw SmartAccountTransactionException.submissionFailed(
      'The instance read of $contractId reported no latest ledger',
    );
  }

  final entries = response.entries ?? const <LedgerEntry>[];
  if (entries.isEmpty) {
    return (
      scheme: OZAuthDigestScheme.legacyConcat,
      latestLedger: latestLedger,
    );
  }

  final XdrLedgerEntryData data;
  try {
    data = entries.first.ledgerEntryDataXdr;
  } catch (e) {
    throw SmartAccountTransactionException.signingFailed(
      'Failed to decode the instance entry of $contractId to read its code: '
      '$e',
      cause: e,
    );
  }
  final instance = data.contractData?.val.instance;
  if (instance == null) {
    throw SmartAccountTransactionException.signingFailed(
      'The instance entry of $contractId is not a contract instance '
      '(${data.discriminant.enumName()})',
    );
  }

  // Only a WASM executable carries a hash; an external reference and the
  // Stellar Asset executable do not.
  final wasmHash = instance.executable.wasmHash;
  final scheme = wasmHash == null
      ? OZAuthDigestScheme.legacyConcat
      : kit.config.authDigestSchemeFor(Util.bytesToHex(wasmHash.hash));
  return (scheme: scheme, latestLedger: latestLedger);
}
