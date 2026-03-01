// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';

class XdrThresholdIndexes {
  final _value;

  const XdrThresholdIndexes._internal(this._value);

  toString() => 'ThresholdIndexes.$_value';

  XdrThresholdIndexes(this._value);

  get value => this._value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XdrThresholdIndexes && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  static const THRESHOLD_MASTER_WEIGHT = const XdrThresholdIndexes._internal(0);
  static const THRESHOLD_LOW = const XdrThresholdIndexes._internal(1);
  static const THRESHOLD_MED = const XdrThresholdIndexes._internal(2);
  static const THRESHOLD_HIGH = const XdrThresholdIndexes._internal(3);

  static XdrThresholdIndexes decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return THRESHOLD_MASTER_WEIGHT;
      case 1:
        return THRESHOLD_LOW;
      case 2:
        return THRESHOLD_MED;
      case 3:
        return THRESHOLD_HIGH;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrThresholdIndexes value) {
    stream.writeInt(value.value);
  }
}
