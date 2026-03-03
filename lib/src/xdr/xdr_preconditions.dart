// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_precondition_type.dart';
import 'xdr_preconditions_v2.dart';
import 'xdr_time_bounds.dart';

class XdrPreconditions {
  XdrPreconditions(this._type);

  XdrPreconditionType _type;
  XdrPreconditionType get discriminant => this._type;
  set discriminant(XdrPreconditionType value) => this._type = value;

  XdrTimeBounds? _timeBounds;
  XdrTimeBounds? get timeBounds => this._timeBounds;
  set timeBounds(XdrTimeBounds? value) => this._timeBounds = value;

  XdrPreconditionsV2? _v2;
  XdrPreconditionsV2? get v2 => this._v2;
  set v2(XdrPreconditionsV2? value) => this._v2 = value;

  static void encode(XdrDataOutputStream stream, XdrPreconditions encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrPreconditionType.PRECOND_NONE:
        break;
      case XdrPreconditionType.PRECOND_TIME:
        XdrTimeBounds.encode(stream, encoded.timeBounds!);
        break;
      case XdrPreconditionType.PRECOND_V2:
        XdrPreconditionsV2.encode(stream, encoded.v2!);
        break;
    }
  }

  static XdrPreconditions decode(XdrDataInputStream stream) {
    XdrPreconditions decoded = XdrPreconditions(
      XdrPreconditionType.decode(stream),
    );
    switch (decoded.discriminant) {
      case XdrPreconditionType.PRECOND_NONE:
        break;
      case XdrPreconditionType.PRECOND_TIME:
        decoded.timeBounds = XdrTimeBounds.decode(stream);
        break;
      case XdrPreconditionType.PRECOND_V2:
        decoded.v2 = XdrPreconditionsV2.decode(stream);
        break;
    }
    return decoded;
  }
}
