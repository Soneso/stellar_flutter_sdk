// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_address_credentials.dart';
import 'xdr_soroban_credentials_type.dart';

class XdrSorobanCredentialsBase {
  XdrSorobanCredentialsType _type;

  XdrSorobanCredentialsType get discriminant => this._type;

  set discriminant(XdrSorobanCredentialsType value) => this._type = value;

  XdrSorobanAddressCredentials? _address;

  XdrSorobanAddressCredentials? get address => this._address;

  XdrSorobanCredentialsBase(this._type);

  set address(XdrSorobanAddressCredentials? value) => this._address = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanCredentialsBase encodedSorobanCredentials,
  ) {
    stream.writeInt(encodedSorobanCredentials.discriminant.value);
    switch (encodedSorobanCredentials.discriminant) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        XdrSorobanAddressCredentials.encode(
          stream,
          encodedSorobanCredentials._address!,
        );
        break;
      default:
        break;
    }
  }

  static XdrSorobanCredentialsBase decode(XdrDataInputStream stream) {
    return decodeAs(stream, XdrSorobanCredentialsBase.new);
  }

  static T decodeAs<T extends XdrSorobanCredentialsBase>(
    XdrDataInputStream stream,
    T Function(XdrSorobanCredentialsType) constructor,
  ) {
    T decoded = constructor(XdrSorobanCredentialsType.decode(stream));
    switch (decoded.discriminant) {
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_SOURCE_ACCOUNT:
        break;
      case XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS:
        decoded._address = XdrSorobanAddressCredentials.decode(stream);
        break;
      default:
        break;
    }
    return decoded;
  }
}
