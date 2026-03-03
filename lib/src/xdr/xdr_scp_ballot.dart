// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_uint32.dart';
import 'xdr_value.dart';

class XdrSCPBallot {
  XdrUint32 _counter;
  XdrUint32 get counter => this._counter;
  set counter(XdrUint32 value) => this._counter = value;

  XdrValue _value;
  XdrValue get value => this._value;
  set value(XdrValue value) => this._value = value;

  XdrSCPBallot(this._counter, this._value);

  static void encode(
    XdrDataOutputStream stream,
    XdrSCPBallot encodedSCPBallot,
  ) {
    XdrUint32.encode(stream, encodedSCPBallot.counter);
    XdrValue.encode(stream, encodedSCPBallot.value);
  }

  static XdrSCPBallot decode(XdrDataInputStream stream) {
    XdrUint32 counter = XdrUint32.decode(stream);
    XdrValue value = XdrValue.decode(stream);
    return XdrSCPBallot(counter, value);
  }
}
