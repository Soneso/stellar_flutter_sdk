// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Loads contract bytecode from the test/wasm directory.
///
/// Uses Flutter assets on web and file system on native platforms.
/// This allows the same test code to run on all platforms.
///
/// Parameters:
/// - [contractPath]: Path to the contract file (e.g., "test/wasm/hello.wasm")
///
/// Returns: Contract bytecode as Uint8List
///
/// Example:
/// ```dart
/// Uint8List code = await loadContractCode("test/wasm/soroban_hello_world_contract.wasm");
/// ```
Future<Uint8List> loadContractCode(String contractPath) async {
  if (kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();
    final ByteData data = await rootBundle.load(contractPath);
    return data.buffer.asUint8List();
  } else {
    return Util.readFile(contractPath);
  }
}

/// Funds [accountId] via the friendbot and then polls [server] until the
/// account is visible to that RPC instance.
///
/// Friendbot funds against Horizon; the Soroban RPC ingests the funding
/// ledger later, so the account can be invisible to the RPC immediately
/// after funding. The public testnet RPC is load-balanced across backend
/// nodes with different sync states, so the visibility poll and the
/// subsequent operations must run on the SAME [SorobanServer] instance
/// (same connection). Pass [server] into `ClientOptions`, `InstallRequest`
/// or `DeployRequest` via their `server` parameter, or use it directly for
/// RPC calls.
///
/// Set [useFuturenet] to fund via the futurenet friendbot instead of the
/// testnet one.
///
/// The friendbot returns a non-200 response both for accounts that already
/// exist (e.g. re-funding the same account in a per-test setUp) and for
/// transient failures such as rate limiting. An already existing account
/// needs no funding, so it is accepted as-is; transient failures are retried
/// up to [fundingAttempts] times with [fundingRetryDelay] between attempts.
///
/// Throws an [Exception] if the account cannot be funded, or if it is not
/// visible to [server] within [timeout] after funding.
Future<void> fundTestAccountAndWaitForRpc(
  SorobanServer server,
  String accountId, {
  bool useFuturenet = false,
  Duration pollInterval = const Duration(seconds: 2),
  Duration timeout = const Duration(seconds: 60),
  int fundingAttempts = 3,
  Duration fundingRetryDelay = const Duration(seconds: 5),
}) async {
  Future<bool> fund() => useFuturenet
      ? FuturenetFriendBot.fundTestAccount(accountId)
      : FriendBot.fundTestAccount(accountId);

  var funded = await fund();
  for (var attempt = 1; !funded && attempt < fundingAttempts; attempt++) {
    if (await server.getAccount(accountId) != null) {
      return;
    }
    await Future.delayed(fundingRetryDelay);
    funded = await fund();
  }
  if (!funded && await server.getAccount(accountId) == null) {
    throw Exception(
        'Friendbot funding failed for account $accountId after '
        '$fundingAttempts attempts');
  }

  final deadline = DateTime.now().add(timeout);
  while (true) {
    final account = await server.getAccount(accountId);
    if (account != null) {
      return;
    }
    if (DateTime.now().isAfter(deadline)) {
      throw Exception(
          'Account $accountId is not visible to the Soroban RPC after '
          'friendbot funding (waited ${timeout.inSeconds} seconds)');
    }
    await Future.delayed(pollInterval);
  }
}

class TestUtils {
  static void  resultDeAndEncodingTest(AbstractTransaction transaction, SubmitTransactionResponse response) {
    String? metaXdrStr = response.resultMetaXdr;
    if (metaXdrStr != null) {
      XdrTransactionMeta? meta = response.getTransactionMetaResultXdr();
      assert(meta != null);
      assert(metaXdrStr == meta!.toBase64EncodedXdrString());
    }

    String envelopeXdrStr = response.envelopeXdr!;
    XdrTransactionEnvelope envelope = XdrTransactionEnvelope.fromEnvelopeXdrString(envelopeXdrStr);
    assert(envelopeXdrStr == envelope.toEnvelopeXdrBase64());

    String resultXdrStr = response.resultXdr!;
    XdrTransactionResult result = XdrTransactionResult.fromBase64EncodedXdrString(resultXdrStr);
    assert(resultXdrStr == result.toBase64EncodedXdrString());

    String? feeMetaXdrStr = response.feeMetaXdr;
    if (feeMetaXdrStr != null) {
      XdrLedgerEntryChanges changes = response.getFeeMetaXdr()!;
      assert(feeMetaXdrStr == changes.toBase64EncodedXdrString());
    }
  }
}
