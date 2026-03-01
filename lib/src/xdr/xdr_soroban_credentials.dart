// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_address_credentials.dart';
import 'xdr_soroban_credentials_type.dart';

class XdrSorobanCredentials {
  XdrSorobanCredentialsType _type;
  XdrSorobanCredentialsType get type => this._type;
  set type(XdrSorobanCredentialsType value) => this._type = value;

  XdrSorobanAddressCredentials? _address;
  XdrSorobanAddressCredentials? get address => this._address;
  set address(XdrSorobanAddressCredentials? value) => this._address = value;

  XdrSorobanCredentials(this._type);

  static void encode(
      XdrDataOutputStream stream, XdrSorobanCredentials encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        XdrSorobanAddressCredentials.encode(stream, encoded.address!);
        break;
    }
  }

  static XdrSorobanCredentials decode(XdrDataInputStream stream) {
    XdrSorobanCredentials decoded =
        XdrSorobanCredentials(XdrSorobanCredentialsType.decode(stream));
    switch (decoded.type) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        decoded.address = XdrSorobanAddressCredentials.decode(stream);
        break;
    }
    return decoded;
  }

  static XdrSorobanCredentials forSourceAccount() {
    return XdrSorobanCredentials(
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT);
  }

  static XdrSorobanCredentials forAddressCredentials(
      XdrSorobanAddressCredentials addressCredentials) {
    var result = XdrSorobanCredentials(
        XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS);
    result.address = addressCredentials;
    return result;
  }
}
