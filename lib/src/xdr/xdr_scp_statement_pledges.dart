// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_scp_nomination.dart';
import 'xdr_scp_statement_confirm.dart';
import 'xdr_scp_statement_externalize.dart';
import 'xdr_scp_statement_prepare.dart';
import 'xdr_scp_statement_type.dart';

class XdrSCPStatementPledges {
  XdrSCPStatementPledges(this._type);
  XdrSCPStatementType _type;
  XdrSCPStatementType get discriminant => this._type;
  set discriminant(XdrSCPStatementType value) => this._type = value;

  XdrSCPStatementPrepare? _prepare;
  XdrSCPStatementPrepare? get prepare => this._prepare;
  set prepare(XdrSCPStatementPrepare? value) => this._prepare = value;

  XdrSCPStatementConfirm? _confirm;
  XdrSCPStatementConfirm? get confirm => this._confirm;
  set confirm(XdrSCPStatementConfirm? value) => this._confirm = value;

  XdrSCPStatementExternalize? _externalize;
  XdrSCPStatementExternalize? get externalize => this._externalize;
  set externalize(XdrSCPStatementExternalize? value) =>
      this._externalize = value;

  XdrSCPNomination? _nominate;
  XdrSCPNomination? get nominate => this._nominate;
  set nominate(XdrSCPNomination? value) => this._nominate = value;

  static void encode(XdrDataOutputStream stream,
      XdrSCPStatementPledges encodedSCPStatementPledges) {
    stream.writeInt(encodedSCPStatementPledges.discriminant.value);
    switch (encodedSCPStatementPledges.discriminant) {
      case XdrSCPStatementType.SCP_ST_PREPARE:
        XdrSCPStatementPrepare.encode(
            stream, encodedSCPStatementPledges.prepare!);
        break;
      case XdrSCPStatementType.SCP_ST_CONFIRM:
        XdrSCPStatementConfirm.encode(
            stream, encodedSCPStatementPledges.confirm!);
        break;
      case XdrSCPStatementType.SCP_ST_EXTERNALIZE:
        XdrSCPStatementExternalize.encode(
            stream, encodedSCPStatementPledges.externalize!);
        break;
      case XdrSCPStatementType.SCP_ST_NOMINATE:
        XdrSCPNomination.encode(stream, encodedSCPStatementPledges.nominate!);
        break;
    }
  }

  static XdrSCPStatementPledges decode(XdrDataInputStream stream) {
    XdrSCPStatementPledges decodedSCPStatementPledges =
        XdrSCPStatementPledges(XdrSCPStatementType.decode(stream));
    switch (decodedSCPStatementPledges.discriminant) {
      case XdrSCPStatementType.SCP_ST_PREPARE:
        decodedSCPStatementPledges.prepare =
            XdrSCPStatementPrepare.decode(stream);
        break;
      case XdrSCPStatementType.SCP_ST_CONFIRM:
        decodedSCPStatementPledges.confirm =
            XdrSCPStatementConfirm.decode(stream);
        break;
      case XdrSCPStatementType.SCP_ST_EXTERNALIZE:
        decodedSCPStatementPledges.externalize =
            XdrSCPStatementExternalize.decode(stream);
        break;
      case XdrSCPStatementType.SCP_ST_NOMINATE:
        decodedSCPStatementPledges.nominate = XdrSCPNomination.decode(stream);
        break;
    }
    return decodedSCPStatementPledges;
  }
}
