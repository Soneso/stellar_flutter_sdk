// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_sc_spec_function_input_v0.dart';
import 'xdr_sc_spec_type_def.dart';

class XdrSCSpecFunctionV0 {
  String _doc;
  String get doc => this._doc;
  set doc(String value) => this._doc = value;

  String _name; // symbol
  String get name => this._name;
  set name(String value) => this._name = value;

  List<XdrSCSpecFunctionInputV0> _inputs;
  List<XdrSCSpecFunctionInputV0> get inputs => this._inputs;
  set inputs(List<XdrSCSpecFunctionInputV0> value) => this._inputs = value;

  List<XdrSCSpecTypeDef> _outputs;
  List<XdrSCSpecTypeDef> get outputs => this._outputs;
  set outputs(List<XdrSCSpecTypeDef> value) => this._outputs = value;

  XdrSCSpecFunctionV0(this._doc, this._name, this._inputs, this._outputs);

  static void encode(XdrDataOutputStream stream, XdrSCSpecFunctionV0 encoded) {
    stream.writeString(encoded.doc);
    stream.writeString(encoded.name);

    int inputsSize = encoded.inputs.length;
    stream.writeInt(inputsSize);
    for (int i = 0; i < inputsSize; i++) {
      XdrSCSpecFunctionInputV0.encode(stream, encoded.inputs[i]);
    }

    int outputsSize = encoded.outputs.length;
    stream.writeInt(outputsSize);
    for (int i = 0; i < outputsSize; i++) {
      XdrSCSpecTypeDef.encode(stream, encoded.outputs[i]);
    }
  }

  static XdrSCSpecFunctionV0 decode(XdrDataInputStream stream) {
    String doc = stream.readString();
    String name = stream.readString();

    int inputsSize = stream.readInt();
    List<XdrSCSpecFunctionInputV0> inputs =
        List<XdrSCSpecFunctionInputV0>.empty(growable: true);
    for (int i = 0; i < inputsSize; i++) {
      inputs.add(XdrSCSpecFunctionInputV0.decode(stream));
    }

    int outputsSize = stream.readInt();
    List<XdrSCSpecTypeDef> outputs = List<XdrSCSpecTypeDef>.empty(
      growable: true,
    );
    for (int i = 0; i < outputsSize; i++) {
      outputs.add(XdrSCSpecTypeDef.decode(stream));
    }
    return XdrSCSpecFunctionV0(doc, name, inputs, outputs);
  }
}
