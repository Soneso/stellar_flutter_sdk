// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_ledger_footprint.dart';
import 'xdr_uint32.dart';

class XdrSorobanResources {
  // The ledger footprint of the transaction.
  XdrLedgerFootprint _footprint;
  XdrLedgerFootprint get footprint => this._footprint;
  set footprint(XdrLedgerFootprint value) => this._footprint = value;

  // The maximum number of instructions this transaction can use
  XdrUint32 _instructions;
  XdrUint32 get instructions => this._instructions;
  set instructions(XdrUint32 value) => this._instructions = value;

  // The maximum number of bytes this transaction can read from disk backed entries
  XdrUint32 _diskReadBytes;
  XdrUint32 get diskReadBytes => this._diskReadBytes;
  set diskReadBytes(XdrUint32 value) => this._diskReadBytes = value;

  // The maximum number of bytes this transaction can write to ledger
  XdrUint32 _writeBytes;
  XdrUint32 get writeBytes => this._writeBytes;
  set writeBytes(XdrUint32 value) => this._writeBytes = value;

  XdrSorobanResources(this._footprint, this._instructions, this._diskReadBytes,
      this._writeBytes);

  static void encode(XdrDataOutputStream stream, XdrSorobanResources encoded) {
    XdrLedgerFootprint.encode(stream, encoded.footprint);
    XdrUint32.encode(stream, encoded.instructions);
    XdrUint32.encode(stream, encoded.diskReadBytes);
    XdrUint32.encode(stream, encoded.writeBytes);
  }

  static XdrSorobanResources decode(XdrDataInputStream stream) {
    final footprint = XdrLedgerFootprint.decode(stream);
    final instructions = XdrUint32.decode(stream);
    final diskReadBytes = XdrUint32.decode(stream);
    final writeBytes = XdrUint32.decode(stream);
    return XdrSorobanResources(
        footprint, instructions, diskReadBytes, writeBytes);
  }
}
