// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_soroban_authorized_invocation.dart';
import 'xdr_soroban_credentials.dart';

class XdrSorobanAuthorizationEntry {
  XdrSorobanCredentials _credentials;
  XdrSorobanCredentials get credentials => this._credentials;
  set credentials(XdrSorobanCredentials value) => this._credentials = value;

  XdrSorobanAuthorizedInvocation _rootInvocation;
  XdrSorobanAuthorizedInvocation get rootInvocation => this._rootInvocation;
  set rootInvocation(XdrSorobanAuthorizedInvocation value) =>
      this._rootInvocation = value;

  XdrSorobanAuthorizationEntry(this._credentials, this._rootInvocation);

  static void encode(
    XdrDataOutputStream stream,
    XdrSorobanAuthorizationEntry encoded,
  ) {
    XdrSorobanCredentials.encode(stream, encoded.credentials);
    XdrSorobanAuthorizedInvocation.encode(stream, encoded.rootInvocation);
  }

  static XdrSorobanAuthorizationEntry decode(XdrDataInputStream stream) {
    XdrSorobanCredentials credentials = XdrSorobanCredentials.decode(stream);
    XdrSorobanAuthorizedInvocation rootInvocation =
        XdrSorobanAuthorizedInvocation.decode(stream);

    return XdrSorobanAuthorizationEntry(credentials, rootInvocation);
  }
}
