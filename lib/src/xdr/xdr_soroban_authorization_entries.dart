// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_authorization_entry.dart';

class XdrSorobanAuthorizationEntries {
  XdrSorobanAuthorizationEntries(this._sorobanAuthorizationEntries);

  List<XdrSorobanAuthorizationEntry> _sorobanAuthorizationEntries;
  List<XdrSorobanAuthorizationEntry> get sorobanAuthorizationEntries => this._sorobanAuthorizationEntries;
  set sorobanAuthorizationEntries(List<XdrSorobanAuthorizationEntry> value) => this._sorobanAuthorizationEntries = value;

  static void encode(XdrDataOutputStream stream, XdrSorobanAuthorizationEntries encodedSorobanAuthorizationEntries) {
    int size = encodedSorobanAuthorizationEntries.sorobanAuthorizationEntries.length;
    stream.writeInt(size);
    for (int i = 0; i < size; i++) {
      XdrSorobanAuthorizationEntry.encode(stream, encodedSorobanAuthorizationEntries.sorobanAuthorizationEntries[i]);
    }
  }

  static XdrSorobanAuthorizationEntries decode(XdrDataInputStream stream) {
    int size = stream.readInt();
    List<XdrSorobanAuthorizationEntry> items = List<XdrSorobanAuthorizationEntry>.empty(growable: true);
    for (int i = 0; i < size; i++) {
      items.add(XdrSorobanAuthorizationEntry.decode(stream));
    }
    return XdrSorobanAuthorizationEntries(items);
  }
}
