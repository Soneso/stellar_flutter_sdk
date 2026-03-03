// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_crypto_key_type.dart';
import 'xdr_data_io.dart';
import 'xdr_muxed_account_med25519.dart';
import 'xdr_uint256.dart';

class XdrMuxedAccount {
  XdrCryptoKeyType _type;

  XdrCryptoKeyType get discriminant => this._type;

  set discriminant(XdrCryptoKeyType value) => this._type = value;

  XdrUint256? _ed25519;

  XdrUint256? get ed25519 => this._ed25519;

  XdrMuxedAccountMed25519? _med25519;

  XdrMuxedAccountMed25519? get med25519 => this._med25519;

  XdrMuxedAccount(this._type);

  set ed25519(XdrUint256? value) => this._ed25519 = value;

  set med25519(XdrMuxedAccountMed25519? value) => this._med25519 = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrMuxedAccount encodedMuxedAccount,
  ) {
    stream.writeInt(encodedMuxedAccount.discriminant.value);
    switch (encodedMuxedAccount.discriminant) {
      case XdrCryptoKeyType.KEY_TYPE_ED25519:
        XdrUint256.encode(stream, encodedMuxedAccount._ed25519!);
        break;
      case XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519:
        XdrMuxedAccountMed25519.encode(stream, encodedMuxedAccount._med25519!);
        break;
      default:
        break;
    }
  }

  static XdrMuxedAccount decode(XdrDataInputStream stream) {
    XdrMuxedAccount decodedMuxedAccount = XdrMuxedAccount(
      XdrCryptoKeyType.decode(stream),
    );
    switch (decodedMuxedAccount.discriminant) {
      case XdrCryptoKeyType.KEY_TYPE_ED25519:
        decodedMuxedAccount._ed25519 = XdrUint256.decode(stream);
        break;
      case XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519:
        decodedMuxedAccount._med25519 = XdrMuxedAccountMed25519.decode(stream);
        break;
      default:
        break;
    }
    return decodedMuxedAccount;
  }
}
