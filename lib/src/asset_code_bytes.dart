// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'util.dart';

/// The highest byte value of an ASCII character.
const int _asciiMax = 0x7F;

/// Returns the asset code that the fixed-width XDR code field [bytes] holds.
///
/// The typed assets write a code as UTF-8, so only an ASCII byte is written
/// back as the byte it was read from; the network accepts only ASCII letters
/// and digits. A byte above 0x7F anywhere in [bytes], also after a zero byte,
/// throws a [FormatException] that names [bytes] as hex.
String readAssetCode(Uint8List bytes) {
  if (bytes.any((int byte) => byte > _asciiMax)) {
    throw FormatException(
      'Asset code bytes ${Util.bytesToHex(bytes)} hold a non-ASCII byte',
    );
  }
  return Util.paddedByteArrayToString(bytes);
}
