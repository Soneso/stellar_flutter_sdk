// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

/// Renders [payload] behind [versionByte] as a checksummed strkey without the
/// structural checks the SDK encoder applies, for building the vectors those
/// checks refuse.
String craftStrKey(int versionByte, Uint8List payload) {
  final Uint8List body = Uint8List.fromList([versionByte, ...payload]);
  final Uint8List checksum = StrKey.calculateChecksum(body);
  return Base32.encode(Uint8List.fromList([...body, ...checksum]));
}

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

/// Funds [accountId] via friendbot and polls until every provided endpoint
/// serves the account in [requiredConsecutiveSuccesses] consecutive rounds.
///
/// A single successful read is not enough on a load-balanced deployment:
/// later reads can hit replicas whose ingestion lags the one that answered
/// first, so a test read right after this helper would still miss the
/// account. Requiring consecutive rounds keeps polling until the account is
/// served consistently.
///
/// A friendbot failure is not fatal on its own: the account may already be
/// funded (HTTP 400) or the request rate limited (HTTP 429), and only the
/// visibility poll can tell. Funding is attempted up to [fundingAttempts]
/// times while the account stays invisible; the helper throws only when the
/// account is not consistently visible when [timeout] has elapsed.
///
/// Pass the endpoints the test reads the account from: [rpc], [horizon], or
/// both. At least one must be provided. The poll and the test's subsequent
/// operations must use the SAME instances (same connections): pass the same
/// [SorobanServer] the test hands to `ClientOptions`, `InstallRequest` or
/// `DeployRequest`, and the same [StellarSDK] the test reads and submits
/// through.
Future<void> fundTestAccountAndAwaitVisibility(
  String accountId, {
  SorobanServer? rpc,
  StellarSDK? horizon,
  bool useFuturenet = false,
  Duration pollInterval = const Duration(seconds: 2),
  Duration confirmationInterval = const Duration(seconds: 1),
  int requiredConsecutiveSuccesses = 3,
  Duration timeout = const Duration(seconds: 90),
  int fundingAttempts = 3,
  Duration fundingRetryDelay = const Duration(seconds: 5),
}) async {
  if (rpc == null && horizon == null) {
    throw ArgumentError('Provide at least one of rpc and horizon');
  }

  Future<bool> fund() async {
    try {
      return useFuturenet
          ? await FuturenetFriendBot.fundTestAccount(accountId)
          : await FriendBot.fundTestAccount(accountId);
    } catch (_) {
      return false; // transport failure: the visibility poll decides
    }
  }

  var rpcVisible = rpc == null;
  var horizonVisible = horizon == null;

  Future<bool> visibleEverywhere() async {
    if (rpc != null) {
      try {
        rpcVisible = await rpc.getAccount(accountId) != null;
      } catch (_) {
        rpcVisible = false;
      }
    }
    if (horizon != null) {
      try {
        await horizon.accounts.account(accountId);
        horizonVisible = true;
      } catch (_) {
        horizonVisible = false;
      }
    }
    return rpcVisible && horizonVisible;
  }

  var funded = await fund();
  for (var attempt = 1; !funded && attempt < fundingAttempts; attempt++) {
    if (await visibleEverywhere()) {
      break;
    }
    await Future.delayed(fundingRetryDelay);
    funded = await fund();
  }

  final deadline = DateTime.now().add(timeout);
  var consecutiveSuccesses = 0;
  while (true) {
    if (await visibleEverywhere()) {
      consecutiveSuccesses++;
      if (consecutiveSuccesses >= requiredConsecutiveSuccesses) {
        return;
      }
      await Future.delayed(confirmationInterval);
      continue;
    }
    consecutiveSuccesses = 0;
    if (DateTime.now().isAfter(deadline)) {
      final endpoints = [
        if (rpc != null) 'rpc visible: $rpcVisible',
        if (horizon != null) 'horizon visible: $horizonVisible',
      ].join(', ');
      throw Exception(
          'Account $accountId is not consistently visible after friendbot '
          'funding (friendbot success: $funded, $endpoints, waited '
          '${timeout.inSeconds} seconds)');
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
