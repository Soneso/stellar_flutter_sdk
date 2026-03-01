// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_address_credentials.dart';
import 'xdr_soroban_credentials_base.dart';
import 'xdr_soroban_credentials_type.dart';

class XdrSorobanCredentials extends XdrSorobanCredentialsBase {
  XdrSorobanCredentials(super.type);

  static void encode(XdrDataOutputStream stream, XdrSorobanCredentials val) {
    XdrSorobanCredentialsBase.encode(stream, val);
  }

  static XdrSorobanCredentials decode(XdrDataInputStream stream) {
    return XdrSorobanCredentialsBase.decodeAs(
      stream,
      XdrSorobanCredentials.new,
    );
  }

  static XdrSorobanCredentials forSourceAccount() {
    return XdrSorobanCredentials(
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT,
    );
  }

  static XdrSorobanCredentials forAddressCredentials(
    XdrSorobanAddressCredentials addressCredentials,
  ) {
    var result = XdrSorobanCredentials(
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS,
    );
    result.address = addressCredentials;
    return result;
  }
}
