// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../xdr/xdr.dart';
import 'oz_internal_pipeline_interfaces.dart';
import 'oz_selected_signer.dart';
import 'oz_smart_account_types.dart';
import 'oz_transaction_operations.dart';

/// Routes a host-function submission to the single-signer or multi-signer
/// pipeline based on whether [selectedSigners] is empty.
///
/// Shared by the signer, policy, and context-rule managers so the
/// single-vs-multi dispatch lives in one place. An empty [selectedSigners]
/// list uses the connected-passkey single-signer path
/// ([OZTransactionOperations.submit]); a non-empty list routes to
/// [OZMultiSignerManagerInterface.submitWithMultipleSigners].
@internal
Future<TransactionResult> ozRouteSubmission(
  OZSmartAccountWalletKitInterface kit,
  XdrHostFunction hostFunction,
  List<SelectedSigner> selectedSigners,
  SubmissionMethod? forceMethod,
) {
  if (selectedSigners.isEmpty) {
    return kit.transactionOperations.submit(
      hostFunction: hostFunction,
      auth: const <XdrSorobanAuthorizationEntry>[],
      forceMethod: forceMethod,
    );
  }
  final manager = kit.multiSignerManager as OZMultiSignerManagerInterface;
  return manager.submitWithMultipleSigners(
    hostFunction: hostFunction,
    selectedSigners: selectedSigners,
    forceMethod: forceMethod,
  );
}

/// Resolves the submission method for a transaction: honours an explicit
/// [forceMethod], otherwise selects the relayer when one is configured on the
/// [kit] and falls back to direct RPC submission.
@internal
SubmissionMethod ozResolveSubmissionMethod(
  OZSmartAccountKitInterface kit,
  SubmissionMethod? forceMethod,
) {
  if (forceMethod != null) return forceMethod;
  return kit.relayerClient != null
      ? SubmissionMethod.relayer
      : SubmissionMethod.rpc;
}
