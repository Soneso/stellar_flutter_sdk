// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_signature.dart';
import 'xdr_signature_hint.dart';

class XdrDecoratedSignature {
  XdrSignatureHint _hint;
  XdrSignatureHint get hint => this._hint;
  set hint(XdrSignatureHint value) => this._hint = value;

  XdrSignature _signature;
  XdrSignature get signature => this._signature;
  set signature(XdrSignature value) => this._signature = value;

  XdrDecoratedSignature(this._hint, this._signature);

  static void encode(
    XdrDataOutputStream stream,
    XdrDecoratedSignature encodedDecoratedSignature,
  ) {
    XdrSignatureHint.encode(stream, encodedDecoratedSignature.hint);
    XdrSignature.encode(stream, encodedDecoratedSignature.signature);
  }

  static XdrDecoratedSignature decode(XdrDataInputStream stream) {
    return XdrDecoratedSignature(
      XdrSignatureHint.decode(stream),
      XdrSignature.decode(stream),
    );
  }
}
