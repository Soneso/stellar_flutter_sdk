// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_signer_key.dart';
import 'xdr_uint32.dart';

class XdrSigner {

  XdrSignerKey _key;
  XdrSignerKey get key => this._key;
  set key(XdrSignerKey value) => this._key = value;

  XdrUint32 _weight;
  XdrUint32 get weight => this._weight;
  set weight(XdrUint32 value) => this._weight = value;

  XdrSigner(this._key, this._weight);

  static void encode(XdrDataOutputStream stream, XdrSigner encodedSigner) {
    XdrSignerKey.encode(stream, encodedSigner.key);
    XdrUint32.encode(stream, encodedSigner.weight);
  }

  static XdrSigner decode(XdrDataInputStream stream) {
    XdrSignerKey key = XdrSignerKey.decode(stream);
    XdrUint32 weight = XdrUint32.decode(stream);
    return XdrSigner(key, weight);
  }
}
