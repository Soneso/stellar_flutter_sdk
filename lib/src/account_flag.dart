// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr/xdr_account.dart';

/// Account Flags is the <code>enum</code> that can be used in [SetOptionsOperation].
/// See: <a href="https://www.stellar.org/developers/guides/concepts/accounts.html#flags" target="_blank">Account Flags</a>
class AccountFlag {
  /// Authorization required (0x1): Requires the issuing account to give other accounts permission before they can hold the issuing account’s credit.
  static final AUTH_REQUIRED_FLAG =
      AccountFlag._internal(XdrAccountFlags.AUTH_REQUIRED_FLAG.value);

  /// Authorization revocable (0x2): Allows the issuing account to revoke its credit held by other accounts.
  static final AUTH_REVOCABLE_FLAG =
      AccountFlag._internal(XdrAccountFlags.AUTH_REVOCABLE_FLAG.value);

  /// Authorization immutable (0x4): If this is set then none of the authorization flags can be set and the account can never be deleted.
  static final AUTH_IMMUTABLE_FLAG =
      AccountFlag._internal(XdrAccountFlags.AUTH_IMMUTABLE_FLAG.value);

  final _value;

  const AccountFlag._internal(this._value);

  toString() => 'AccountFlag.$_value';

  AccountFlag(this._value);

  get value => this._value;
}
