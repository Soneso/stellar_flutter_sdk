// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

void main() {
  group('XDR Payment Types - Deep Branch Testing', () {
    test('XdrPathPaymentStrictReceiveOp encode/decode with empty path', () {
      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();

      var original = XdrPathPaymentStrictReceiveOp(
        sendAsset,
        XdrInt64(BigInt.from(200000000)),
        destination,
        destAsset,
        XdrInt64(BigInt.from(100000000)),
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictReceiveOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictReceiveOp.decode(input);

      expect(decoded.sendMax.int64, equals(original.sendMax.int64));
      expect(decoded.destAmount.int64, equals(original.destAmount.int64));
      expect(decoded.path, isEmpty);
    });

    test('XdrPathPaymentStrictSendOp encode/decode with empty path', () {
      var sendAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAsset = XdrAsset(XdrAssetType.ASSET_TYPE_NATIVE);
      var destAccount = XdrAccountID.forAccountId('GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H');
      var destination = XdrMuxedAccount(XdrCryptoKeyType.KEY_TYPE_ED25519);
      destination.ed25519 = destAccount.accountID.getEd25519();

      var original = XdrPathPaymentStrictSendOp(
        sendAsset,
        XdrInt64(BigInt.from(100000000)),
        destination,
        destAsset,
        XdrInt64(BigInt.from(90000000)),
        [],
      );

      XdrDataOutputStream output = XdrDataOutputStream();
      XdrPathPaymentStrictSendOp.encode(output, original);
      Uint8List encoded = Uint8List.fromList(output.bytes);

      XdrDataInputStream input = XdrDataInputStream(encoded);
      var decoded = XdrPathPaymentStrictSendOp.decode(input);

      expect(decoded.sendMax.int64, equals(original.sendMax.int64));
      expect(decoded.destAmount.int64, equals(original.destAmount.int64));
      expect(decoded.path, isEmpty);
    });
  });
}
