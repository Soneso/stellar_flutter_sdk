// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Internal Base64URL helpers shared by the OZ smart-account managers.
///
/// The SDK encodes credential IDs as unpadded Base64URL throughout (storage
/// keys, connected-state values, session records, event payloads). These
/// helpers single-source that encoding so padded and unpadded spellings of the
/// same credential ID resolve consistently.

/// Encodes [bytes] as Base64URL with trailing `=` padding removed.
@internal
String ozBase64UrlEncode(Uint8List bytes) {
  return ozStripBase64UrlPadding(base64Url.encode(bytes));
}

/// Decodes a Base64URL string [s], tolerating missing `=` padding.
@internal
Uint8List ozBase64UrlDecode(String s) {
  return base64Url.decode(base64Url.normalize(s));
}

/// Strips trailing `=` padding from a Base64URL-encoded string.
///
/// The SDK encoder always emits unpadded output; this normalises
/// caller-supplied strings so padded and unpadded spellings resolve to the
/// same value.
@internal
String ozStripBase64UrlPadding(String encoded) {
  var s = encoded;
  while (s.isNotEmpty && s.endsWith('=')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
