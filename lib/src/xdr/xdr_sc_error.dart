// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_error_code.dart';
import 'xdr_sc_error_type.dart';
import 'xdr_uint32.dart';

class XdrSCError {
  XdrSCErrorType _type;
  XdrSCErrorType get type => this._type;
  set type(XdrSCErrorType value) => this._type = value;

  XdrUint32? _contractCode;
  XdrUint32? get contractCode => this._contractCode;
  set contractCode(XdrUint32? value) => this._contractCode = value;

  XdrSCErrorCode? _code;
  XdrSCErrorCode? get code => this._code;
  set code(XdrSCErrorCode? value) => this._code = value;

  XdrSCError(this._type);

  static void encode(XdrDataOutputStream stream, XdrSCError encoded) {
    stream.writeInt(encoded.type.value);
    switch (encoded.type) {
      case XdrSCErrorType.SCE_CONTRACT:
        XdrUint32.encode(stream, encoded.contractCode!);
        break;
      case XdrSCErrorType.SCE_WASM_VM:
      case XdrSCErrorType.SCE_CONTEXT:
      case XdrSCErrorType.SCE_STORAGE:
      case XdrSCErrorType.SCE_OBJECT:
      case XdrSCErrorType.SCE_CRYPTO:
      case XdrSCErrorType.SCE_EVENTS:
      case XdrSCErrorType.SCE_BUDGET:
      case XdrSCErrorType.SCE_VALUE:
        break;
      case XdrSCErrorType.SCE_AUTH:
        XdrSCErrorCode.encode(stream, encoded.code!);
        break;
    }
  }

  static XdrSCError decode(XdrDataInputStream stream) {
    XdrSCError decoded = XdrSCError(XdrSCErrorType.decode(stream));
    switch (decoded.type) {
      case XdrSCErrorType.SCE_CONTRACT:
        decoded.contractCode = XdrUint32.decode(stream);
        break;
      case XdrSCErrorType.SCE_WASM_VM:
      case XdrSCErrorType.SCE_CONTEXT:
      case XdrSCErrorType.SCE_STORAGE:
      case XdrSCErrorType.SCE_OBJECT:
      case XdrSCErrorType.SCE_CRYPTO:
      case XdrSCErrorType.SCE_EVENTS:
      case XdrSCErrorType.SCE_BUDGET:
      case XdrSCErrorType.SCE_VALUE:
        break;
      case XdrSCErrorType.SCE_AUTH:
        decoded.code = XdrSCErrorCode.decode(stream);
        break;
    }
    return decoded;
  }
}
