// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'key_pair.dart';
import 'util.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_account.dart';

/// Represents a muxed account to be used in transactions sent to the stellar network.
class MuxedAccount {
  String _accountId;
  int _id;

  MuxedAccount(this._accountId, this._id) {
    checkNotNull(_accountId, "accountId cannot be null");
  }

  String get accountId => _accountId;
  int get id => _id;

  XdrMuxedAccount toXdr() {
    if (_id == null) {
      return KeyPair.fromAccountId(_accountId).xdrMuxedAccount;
    } else {
      XdrMuxedAccount xdrMuxAccount = XdrMuxedAccount();
      xdrMuxAccount.discriminant = XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519;
      XdrMuxedAccountMed25519 muxMed25519 = XdrMuxedAccountMed25519();
      XdrUint256 uint256 = new XdrUint256();
      uint256.uint256 = StrKey.decodeStellarAccountId(accountId);
      muxMed25519.ed25519 = uint256;
      XdrUint64 id64 = XdrUint64();
      id64.uint64 = _id;
      muxMed25519.id = id64;
      xdrMuxAccount.med25519 = muxMed25519;
      return xdrMuxAccount;
    }
  }

  static MuxedAccount fromXdr(XdrMuxedAccount xdrMuxedAccount) {
    checkNotNull(xdrMuxedAccount, "xdrMuxedAccount cannot be null");

    String accountId = KeyPair.fromXdrMuxedAccount(xdrMuxedAccount).accountId;
    int id;
    if (xdrMuxedAccount.discriminant ==
        XdrCryptoKeyType.KEY_TYPE_MUXED_ED25519) {
      id = xdrMuxedAccount.med25519.id.uint64;
    }
    return MuxedAccount(accountId, id);
  }
}
