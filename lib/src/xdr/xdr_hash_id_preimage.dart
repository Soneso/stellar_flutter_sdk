// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_envelope_type.dart';
import 'xdr_hash_id_preimage_contract_id.dart';
import 'xdr_hash_id_preimage_operation_id.dart';
import 'xdr_hash_id_preimage_revoke_id.dart';
import 'xdr_hash_id_preimage_soroban_authorization.dart';

class XdrHashIDPreimage {
  XdrHashIDPreimage(this._type);
  XdrEnvelopeType _type;
  XdrEnvelopeType get discriminant => this._type;
  set discriminant(XdrEnvelopeType value) => this._type = value;

  XdrHashIDPreimageOperationID? _operationID;
  XdrHashIDPreimageOperationID? get operationID => this._operationID;
  set operationID(XdrHashIDPreimageOperationID? value) =>
      this._operationID = value;

  XdrHashIDPreimageRevokeID? _revokeID;
  XdrHashIDPreimageRevokeID? get revokeID => this._revokeID;
  set revokeID(XdrHashIDPreimageRevokeID? value) => this._revokeID = value;

  XdrHashIDPreimageContractID? _contractID;
  XdrHashIDPreimageContractID? get contractID => this._contractID;
  set contractID(XdrHashIDPreimageContractID? value) =>
      this._contractID = value;

  XdrHashIDPreimageSorobanAuthorization? _sorobanAuthorization;
  XdrHashIDPreimageSorobanAuthorization? get sorobanAuthorization =>
      this._sorobanAuthorization;
  set sorobanAuthorization(XdrHashIDPreimageSorobanAuthorization? value) =>
      this._sorobanAuthorization = value;

  static void encode(XdrDataOutputStream stream, XdrHashIDPreimage encoded) {
    stream.writeInt(encoded.discriminant.value);
    switch (encoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_OP_ID:
        XdrHashIDPreimageOperationID.encode(stream, encoded.operationID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID:
        XdrHashIDPreimageRevokeID.encode(stream, encoded.revokeID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID:
        XdrHashIDPreimageContractID.encode(stream, encoded.contractID!);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION:
        XdrHashIDPreimageSorobanAuthorization.encode(
            stream, encoded.sorobanAuthorization!);
        break;
    }
  }

  static XdrHashIDPreimage decode(XdrDataInputStream stream) {
    XdrHashIDPreimage decoded =
        XdrHashIDPreimage(XdrEnvelopeType.decode(stream));
    switch (decoded.discriminant) {
      case XdrEnvelopeType.ENVELOPE_TYPE_OP_ID:
        decoded.operationID = XdrHashIDPreimageOperationID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_POOL_REVOKE_OP_ID:
        decoded.revokeID = XdrHashIDPreimageRevokeID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID:
        decoded.contractID = XdrHashIDPreimageContractID.decode(stream);
        break;
      case XdrEnvelopeType.ENVELOPE_TYPE_SOROBAN_AUTHORIZATION:
        decoded.sorobanAuthorization =
            XdrHashIDPreimageSorobanAuthorization.decode(stream);
        break;
    }
    return decoded;
  }
}
