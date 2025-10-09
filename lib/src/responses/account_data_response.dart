// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'response.dart';

/// Represents an account data response for a specific key.
/// See: <a href="https://developers.stellar.org/docs/data/apis/horizon/api-reference/get-data-by-account-id" target="_blank">Account Data</a>
class AccountDataResponse extends Response {
  /// The base64 encoded value of the data entry
  final String value;

  AccountDataResponse(this.value);

  /// Gets the decoded raw value as bytes
  Uint8List get decodedValue => base64Decode(value);

  /// Gets the decoded value as a UTF-8 string
  /// Throws if the value is not valid UTF-8
  String get decodedString => utf8.decode(decodedValue);

  /// Attempts to get the decoded value as a UTF-8 string
  /// Returns null if the value is not valid UTF-8
  String? get decodedStringOrNull {
    try {
      return utf8.decode(decodedValue);
    } catch (_) {
      return null;
    }
  }

  factory AccountDataResponse.fromJson(Map<String, dynamic> json) {
    return AccountDataResponse(json['value'] as String);
  }

  Map<String, dynamic> toJson() => {
    'value': value,
  };
}