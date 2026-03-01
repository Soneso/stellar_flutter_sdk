// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrSCSpecTypeUDT {
  String _name;
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecTypeUDT(this._name);

  static void encode(XdrDataOutputStream stream, XdrSCSpecTypeUDT encoded) {
    stream.writeString(encoded.name);
  }

  static XdrSCSpecTypeUDT decode(XdrDataInputStream stream) {
    return XdrSCSpecTypeUDT(stream.readString());
  }
}
