// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_config_setting_entry.dart';
import 'xdr_data_io.dart';

class XdrConfigUpgradeSet {

  List<XdrConfigSettingEntry> _updatedEntry;
  List<XdrConfigSettingEntry> get updatedEntry => this._updatedEntry;
  set updatedEntry(List<XdrConfigSettingEntry> value) => this._updatedEntry = value;

  XdrConfigUpgradeSet(this._updatedEntry);

  static void encode(XdrDataOutputStream stream, XdrConfigUpgradeSet encodedConfigUpgradeSet) {
    int updatedEntrysize = encodedConfigUpgradeSet.updatedEntry.length;
    stream.writeInt(updatedEntrysize);
    for (int i = 0; i < updatedEntrysize; i++) {
      XdrConfigSettingEntry.encode(stream, encodedConfigUpgradeSet.updatedEntry[i]);
    }
  }

  static XdrConfigUpgradeSet decode(XdrDataInputStream stream) {
    int updatedEntrysize = stream.readInt();
    List<XdrConfigSettingEntry> updatedEntry = List<XdrConfigSettingEntry>.empty(growable: true);
    for (int i = 0; i < updatedEntrysize; i++) {
      updatedEntry.add(XdrConfigSettingEntry.decode(stream));
    }
    return XdrConfigUpgradeSet(updatedEntry);
  }
}
