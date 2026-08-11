// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_json_helper.dart';
import 'xdr_soroban_address_credentials.dart';
import 'xdr_soroban_address_credentials_with_delegates.dart';
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

  static XdrSorobanCredentials fromTxRep(
    Map<String, String> map,
    String prefix,
  ) {
    var b = XdrSorobanCredentialsBase.fromTxRep(map, prefix);
    var result = XdrSorobanCredentials(b.discriminant);
    result.address = b.address;
    result.addressV2 = b.addressV2;
    result.addressWithDelegates = b.addressWithDelegates;
    return result;
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

  /// Creates credentials for the ADDRESS_V2 arm (protocol 27+).
  ///
  /// ADDRESS_V2 uses the same body as ADDRESS but a different preimage type
  /// (ENVELOPE_TYPE_SOROBAN_AUTHORIZATION_WITH_ADDRESS). Emitting this arm on
  /// a network below protocol 27 invalidates the transaction.
  static XdrSorobanCredentials forAddressV2Credentials(
    XdrSorobanAddressCredentials addressCredentials,
  ) {
    var result = XdrSorobanCredentials(
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_V2,
    );
    result.addressV2 = addressCredentials;
    return result;
  }

  /// Creates credentials for the ADDRESS_WITH_DELEGATES arm (protocol 27+).
  ///
  /// Emitting this arm on a network below protocol 27 invalidates the transaction.
  static XdrSorobanCredentials forAddressWithDelegatesCredentials(
    XdrSorobanAddressCredentialsWithDelegates addressWithDelegates,
  ) {
    var result = XdrSorobanCredentials(
      XdrSorobanCredentialsType.SOROBAN_CREDENTIALS_ADDRESS_WITH_DELEGATES,
    );
    result.addressWithDelegates = addressWithDelegates;
    return result;
  }

  /// Parses the SEP-0051 XDR-JSON rendering of a XdrSorobanCredentials.
  ///
  /// Dart does not inherit statics, so this narrows the base class rendering to
  /// this type rather than relying on the one the base declares.
  static XdrSorobanCredentials fromXdrJson(String json) => fromXdrJsonValue(
    XdrJsonHelper.decodeDocument(json, type: 'XdrSorobanCredentials'),
  );

  static XdrSorobanCredentials fromXdrJsonValue(Object? value) =>
      XdrSorobanCredentialsBase.fromXdrJsonValueAs(
        value,
        XdrSorobanCredentials.new,
      );
}
