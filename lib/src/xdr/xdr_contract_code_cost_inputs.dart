// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_extension_point.dart';
import 'xdr_int32.dart';

class XdrContractCodeCostInputs {
  XdrExtensionPoint _ext;
  XdrExtensionPoint get ext => this._ext;
  set ext(XdrExtensionPoint value) => this._ext = value;

  XdrInt32 _nInstructions;
  XdrInt32 get nInstructions => this._nInstructions;
  set nInstructions(XdrInt32 value) => this._nInstructions = value;

  XdrInt32 _nFunctions;
  XdrInt32 get nFunctions => this._nFunctions;
  set nFunctions(XdrInt32 value) => this._nFunctions = value;

  XdrInt32 _nGlobals;
  XdrInt32 get nGlobals => this._nGlobals;
  set nGlobals(XdrInt32 value) => this._nGlobals = value;

  XdrInt32 _nTableEntries;
  XdrInt32 get nTableEntries => this._nTableEntries;
  set nTableEntries(XdrInt32 value) => this._nTableEntries = value;

  XdrInt32 _nTypes;
  XdrInt32 get nTypes => this._nTypes;
  set nTypes(XdrInt32 value) => this._nTypes = value;

  XdrInt32 _nDataSegments;
  XdrInt32 get nDataSegments => this._nDataSegments;
  set nDataSegments(XdrInt32 value) => this._nDataSegments = value;

  XdrInt32 _nElemSegments;
  XdrInt32 get nElemSegments => this._nElemSegments;
  set nElemSegments(XdrInt32 value) => this._nElemSegments = value;

  XdrInt32 _nImports;
  XdrInt32 get nImports => this._nImports;
  set nImports(XdrInt32 value) => this._nImports = value;

  XdrInt32 _nExports;
  XdrInt32 get nExports => this._nExports;
  set nExports(XdrInt32 value) => this._nExports = value;

  XdrInt32 _nDataSegmentBytes;
  XdrInt32 get nDataSegmentBytes => this._nDataSegmentBytes;
  set nDataSegmentBytes(XdrInt32 value) => this._nDataSegmentBytes = value;

  XdrContractCodeCostInputs(
    this._ext,
    this._nInstructions,
    this._nFunctions,
    this._nGlobals,
    this._nTableEntries,
    this._nTypes,
    this._nDataSegments,
    this._nElemSegments,
    this._nImports,
    this._nExports,
    this._nDataSegmentBytes,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrContractCodeCostInputs encoded,
  ) {
    XdrExtensionPoint.encode(stream, encoded.ext);
    XdrInt32.encode(stream, encoded.nInstructions);
    XdrInt32.encode(stream, encoded.nFunctions);
    XdrInt32.encode(stream, encoded.nGlobals);
    XdrInt32.encode(stream, encoded.nTableEntries);
    XdrInt32.encode(stream, encoded.nTypes);
    XdrInt32.encode(stream, encoded.nDataSegments);
    XdrInt32.encode(stream, encoded.nElemSegments);
    XdrInt32.encode(stream, encoded.nImports);
    XdrInt32.encode(stream, encoded.nExports);
    XdrInt32.encode(stream, encoded.nDataSegmentBytes);
  }

  static XdrContractCodeCostInputs decode(XdrDataInputStream stream) {
    XdrExtensionPoint ext = XdrExtensionPoint.decode(stream);
    XdrInt32 nInstructions = XdrInt32.decode(stream);
    XdrInt32 nFunctions = XdrInt32.decode(stream);
    XdrInt32 nGlobals = XdrInt32.decode(stream);
    XdrInt32 nTableEntries = XdrInt32.decode(stream);
    XdrInt32 nTypes = XdrInt32.decode(stream);
    XdrInt32 nDataSegments = XdrInt32.decode(stream);
    XdrInt32 nElemSegments = XdrInt32.decode(stream);
    XdrInt32 nImports = XdrInt32.decode(stream);
    XdrInt32 nExports = XdrInt32.decode(stream);
    XdrInt32 nDataSegmentBytes = XdrInt32.decode(stream);

    return XdrContractCodeCostInputs(
      ext,
      nInstructions,
      nFunctions,
      nGlobals,
      nTableEntries,
      nTypes,
      nDataSegments,
      nElemSegments,
      nImports,
      nExports,
      nDataSegmentBytes,
    );
  }
}
