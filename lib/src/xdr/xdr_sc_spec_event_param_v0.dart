// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_event_param_location_v0.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecEventParamV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name; // symbol
  String get name => this._name;
  set name(String value) => this._name = value;

  XdrSCSpecTypeDef _type;
  XdrSCSpecTypeDef get type => this._type;
  set type(XdrSCSpecTypeDef value) => this._type = value;

  XdrSCSpecEventParamLocationV0 _location;
  XdrSCSpecEventParamLocationV0 get location => this._location;
  set location(XdrSCSpecEventParamLocationV0 value) => this._location = value;

  XdrSCSpecEventParamV0(this._doc, this._name, this._type, this._location);

  static void encode(
    XdrDataOutputStream stream,
    XdrSCSpecEventParamV0 encoded,
  ) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);
    XdrSCSpecTypeDef.encode(stream, encoded.type);
    XdrSCSpecEventParamLocationV0.encode(stream, encoded.location);
  }

  static XdrSCSpecEventParamV0 decode(XdrDataInputStream stream) {
    final doc = stream.readString();
    final name = stream.readString();
    final type = XdrSCSpecTypeDef.decode(stream);
    final location = XdrSCSpecEventParamLocationV0.decode(stream);

    return XdrSCSpecEventParamV0(doc, name, type, location);
  }
}
