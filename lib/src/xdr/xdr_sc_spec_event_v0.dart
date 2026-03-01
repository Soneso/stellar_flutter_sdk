// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_event_data_format.dart';
import 'xdr_sc_spec_event_param_v0.dart';

class XdrSCSpecEventV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _lib;
  String get lib => this._lib;
  set lib(String value) => this._lib = value;

  String _name; // symbol
  String get name => this._name;
  set name(String value) => this._name = value;

  List<String> _prefixTopics;
  List<String> get prefixTopics => this._prefixTopics;
  set prefixTopics(List<String> value) => this._prefixTopics = value;

  List<XdrSCSpecEventParamV0> _params;
  List<XdrSCSpecEventParamV0> get params => this._params;
  set inputs(List<XdrSCSpecEventParamV0> value) => this._params = value;

  XdrSCSpecEventDataFormat _dataFormat;
  XdrSCSpecEventDataFormat get dataFormat => this._dataFormat;
  set dataFormat(XdrSCSpecEventDataFormat value) => this._dataFormat = value;

  XdrSCSpecEventV0(
    this._doc,
    this._lib,
    this._name,
    this._prefixTopics,
    this._params,
    this._dataFormat,
  );

  static void encode(XdrDataOutputStream stream, XdrSCSpecEventV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.lib);
    stream.writeString(encoded.name);

    int prefixTopicsSize = encoded.prefixTopics.length;
    stream.writeInt(prefixTopicsSize);
    for (int i = 0; i < prefixTopicsSize; i++) {
      stream.writeString(encoded.prefixTopics[i]);
    }

    int paramsSize = encoded.params.length;
    stream.writeInt(paramsSize);
    for (int i = 0; i < paramsSize; i++) {
      XdrSCSpecEventParamV0.encode(stream, encoded.params[i]);
    }

    XdrSCSpecEventDataFormat.encode(stream, encoded.dataFormat);
  }

  static XdrSCSpecEventV0 decode(XdrDataInputStream stream) {
    final doc = stream.readString();
    final lib = stream.readString();
    final name = stream.readString();

    int prefixTopicsSize = stream.readInt();
    List<String> prefixTopics = List<String>.empty(growable: true);
    for (int i = 0; i < prefixTopicsSize; i++) {
      prefixTopics.add(stream.readString());
    }

    int paramsSize = stream.readInt();
    List<XdrSCSpecEventParamV0> params = List<XdrSCSpecEventParamV0>.empty(
      growable: true,
    );
    for (int i = 0; i < paramsSize; i++) {
      params.add(XdrSCSpecEventParamV0.decode(stream));
    }

    final dataFormat = XdrSCSpecEventDataFormat.decode(stream);

    return XdrSCSpecEventV0(doc, lib, name, prefixTopics, params, dataFormat);
  }
}
