// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_contract_executable.dart';
import 'xdr_data_io.dart';
import 'xdr_sc_map_entry.dart';

class XdrSCContractInstance {
  XdrContractExecutable _executable;
  XdrContractExecutable get executable => this._executable;
  set executable(XdrContractExecutable value) => this._executable = value;

  List<XdrSCMapEntry>? _storage;
  List<XdrSCMapEntry>? get storage => this._storage;
  set storage(List<XdrSCMapEntry>? value) => this._storage = value;

  XdrSCContractInstance(this._executable, this._storage);

  static void encode(
      XdrDataOutputStream stream, XdrSCContractInstance encoded) {
    XdrContractExecutable.encode(stream, encoded.executable);
    if (encoded.storage == null) {
      stream.writeInt(0);
    } else {
      stream.writeInt(1);
      int mapSize = encoded.storage!.length;
      stream.writeInt(mapSize);
      for (int i = 0; i < mapSize; i++) {
        XdrSCMapEntry.encode(stream, encoded.storage![i]);
      }
    }
  }

  static XdrSCContractInstance decode(XdrDataInputStream stream) {
    XdrContractExecutable executable = XdrContractExecutable.decode(stream);
    List<XdrSCMapEntry>? storage;
    int mapPresent = stream.readInt();
    if (mapPresent != 0) {
      int mapSize = stream.readInt();
      storage = List<XdrSCMapEntry>.empty(growable: true);
      for (int i = 0; i < mapSize; i++) {
        storage.add(XdrSCMapEntry.decode(stream));
      }
    }
    return XdrSCContractInstance(executable, storage);
  }
}
