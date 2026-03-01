// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_account_entry_v2_ext.dart';
import 'xdr_account_id.dart';
import 'xdr_data_io.dart';
import 'xdr_uint32.dart';

class XdrAccountEntryV2 {
  XdrUint32 _numSponsored;

  XdrUint32 get numSponsored => this._numSponsored;

  set numSponsored(XdrUint32 value) => this._numSponsored = value;

  XdrUint32 _numSponsoring;

  XdrUint32 get numSponsoring => this._numSponsoring;

  set numSponsoring(XdrUint32 value) => this._numSponsoring = value;

  List<XdrAccountID?> _signerSponsoringIDs;

  List<XdrAccountID?> get signerSponsoringIDs => this._signerSponsoringIDs;

  set signerSponsoringIDs(List<XdrAccountID?> value) =>
      this._signerSponsoringIDs = value;

  XdrAccountEntryV2Ext _ext;

  XdrAccountEntryV2Ext get ext => this._ext;

  set ext(XdrAccountEntryV2Ext value) => this._ext = value;

  XdrAccountEntryV2(this._numSponsored, this._numSponsoring,
      this._signerSponsoringIDs, this._ext);

  static void encode(XdrDataOutputStream stream, XdrAccountEntryV2 encoded) {
    XdrUint32.encode(stream, encoded.numSponsored);
    XdrUint32.encode(stream, encoded.numSponsoring);

    int pSize = encoded.signerSponsoringIDs.length;
    stream.writeInt(pSize);
    for (int i = 0; i < pSize; i++) {
      if (encoded.signerSponsoringIDs[i] != null) {
        stream.writeInt(1);
        XdrAccountID.encode(stream, encoded.signerSponsoringIDs[i]);
      } else {
        stream.writeInt(0);
      }
    }

    XdrAccountEntryV2Ext.encode(stream, encoded.ext);
  }

  static XdrAccountEntryV2 decode(XdrDataInputStream stream) {
    XdrUint32 xNumSponsored = XdrUint32.decode(stream);
    XdrUint32 xNumSponsoring = XdrUint32.decode(stream);
    int pSize = stream.readInt();
    List<XdrAccountID?> xSignerSponsoringIDs =
        List<XdrAccountID?>.empty(growable: true);
    for (int i = 0; i < pSize; i++) {
      int sponsoringIDPresent = stream.readInt();
      if (sponsoringIDPresent != 0) {
        xSignerSponsoringIDs.add(XdrAccountID.decode(stream));
      } else {
        xSignerSponsoringIDs.add(null);
      }
    }
    XdrAccountEntryV2Ext xExt = XdrAccountEntryV2Ext.decode(stream);

    return XdrAccountEntryV2(
        xNumSponsored, xNumSponsoring, xSignerSponsoringIDs, xExt);
  }
}
