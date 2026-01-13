// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
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
    final ByteData data = await rootBundle.load(contractPath);
    return data.buffer.asUint8List();
  } else {
    return Util.readFile(contractPath);
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
