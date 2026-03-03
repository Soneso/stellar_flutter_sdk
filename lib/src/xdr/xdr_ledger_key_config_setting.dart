// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_config_setting_id.dart';
import 'xdr_data_io.dart';

class XdrLedgerKeyConfigSetting {
  XdrConfigSettingID _configSettingID;
  XdrConfigSettingID get configSettingID => this._configSettingID;
  set configSettingID(XdrConfigSettingID value) =>
      this._configSettingID = value;

  XdrLedgerKeyConfigSetting(this._configSettingID);

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerKeyConfigSetting encodedLedgerKeyConfigSetting,
  ) {
    XdrConfigSettingID.encode(
      stream,
      encodedLedgerKeyConfigSetting.configSettingID,
    );
  }

  static XdrLedgerKeyConfigSetting decode(XdrDataInputStream stream) {
    XdrConfigSettingID configSettingID = XdrConfigSettingID.decode(stream);
    return XdrLedgerKeyConfigSetting(configSettingID);
  }
}
