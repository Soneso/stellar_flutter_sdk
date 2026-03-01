// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_entry.dart';
import 'xdr_ledger_entry_change_type.dart';
import 'xdr_ledger_key.dart';

class XdrLedgerEntryChange {
  XdrLedgerEntryChange(this._type);

  XdrLedgerEntryChangeType _type;
  XdrLedgerEntryChangeType get discriminant => this._type;
  set discriminant(XdrLedgerEntryChangeType value) => this._type = value;

  XdrLedgerEntry? _created;
  XdrLedgerEntry? get created => this._created;
  set created(XdrLedgerEntry? value) => this._created = value;

  XdrLedgerEntry? _updated;
  XdrLedgerEntry? get updated => this._updated;
  set updated(XdrLedgerEntry? value) => this._updated = value;

  XdrLedgerKey? _removed;
  XdrLedgerKey? get removed => this._removed;
  set removed(XdrLedgerKey? value) => this._removed = value;

  XdrLedgerEntry? _state;
  XdrLedgerEntry? get state => this._state;
  set state(XdrLedgerEntry? value) => this._state = value;

  XdrLedgerEntry? _restored;
  XdrLedgerEntry? get restored => this._restored;
  set restored(XdrLedgerEntry? value) => this._restored = value;

  static void encode(
    XdrDataOutputStream stream,
    XdrLedgerEntryChange encodedLedgerEntryChange,
  ) {
    stream.writeInt(encodedLedgerEntryChange.discriminant.value);
    switch (encodedLedgerEntryChange.discriminant) {
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.created!);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.updated!);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED:
        XdrLedgerKey.encode(stream, encodedLedgerEntryChange.removed!);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.state!);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED:
        XdrLedgerEntry.encode(stream, encodedLedgerEntryChange.restored!);
        break;
    }
  }

  static XdrLedgerEntryChange decode(XdrDataInputStream stream) {
    XdrLedgerEntryChange decodedLedgerEntryChange = XdrLedgerEntryChange(
      XdrLedgerEntryChangeType.decode(stream),
    );
    switch (decodedLedgerEntryChange.discriminant) {
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_CREATED:
        decodedLedgerEntryChange.created = XdrLedgerEntry.decode(stream);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_UPDATED:
        decodedLedgerEntryChange.updated = XdrLedgerEntry.decode(stream);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_REMOVED:
        decodedLedgerEntryChange.removed = XdrLedgerKey.decode(stream);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_STATE:
        decodedLedgerEntryChange.state = XdrLedgerEntry.decode(stream);
        break;
      case XdrLedgerEntryChangeType.LEDGER_ENTRY_RESTORED:
        decodedLedgerEntryChange.restored = XdrLedgerEntry.decode(stream);
        break;
    }
    return decodedLedgerEntryChange;
  }
}
