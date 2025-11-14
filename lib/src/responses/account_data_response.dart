// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'response.dart';

/// Represents a data entry attached to a Stellar account.
///
/// Account data entries allow storing arbitrary key-value pairs on-chain.
/// Each account can have up to 1000 data entries, with keys up to 64 bytes
/// and values up to 64 bytes. Data entries are commonly used for:
///
/// - Domain verification (stellar.toml validation)
/// - Application-specific state storage
/// - On-chain configuration and metadata
/// - Managing arbitrary binary or text data
///
/// Values are stored and returned as base64-encoded strings. The SDK provides
/// helper methods to decode values as bytes or UTF-8 strings.
///
/// Example - Querying and decoding account data:
/// ```dart
/// // Query a specific data entry by key
/// var dataResponse = await sdk.accounts.data(
///   accountId: 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B',
///   key: 'config',
/// );
///
/// // Decode as UTF-8 string (throws if not valid UTF-8)
/// String textValue = dataResponse.decodedString;
/// print('Config value: $textValue');
///
/// // Safely decode as string (returns null if not valid UTF-8)
/// String? safeValue = dataResponse.decodedStringOrNull;
/// if (safeValue != null) {
///   print('Text data: $safeValue');
/// } else {
///   print('Binary data detected');
/// }
///
/// // Get raw bytes for binary data
/// Uint8List bytes = dataResponse.decodedValue;
/// print('Data size: ${bytes.length} bytes');
/// ```
///
/// Example - Creating and updating data entries:
/// ```dart
/// // Create a data entry with text value
/// var transaction = TransactionBuilder(sourceAccount)
///   .addOperation(
///     ManageDataOperationBuilder('app.version', '1.0.0').build(),
///   )
///   .build();
///
/// // Create a data entry with binary data
/// var binaryData = Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]);
/// var transaction2 = TransactionBuilder(sourceAccount)
///   .addOperation(
///     ManageDataOperationBuilder.forData('binary.data', binaryData).build(),
///   )
///   .build();
///
/// // Delete a data entry (set value to null)
/// var transaction3 = TransactionBuilder(sourceAccount)
///   .addOperation(
///     ManageDataOperationBuilder('old.key', null).build(),
///   )
///   .build();
/// ```
///
/// Example - Domain verification:
/// ```dart
/// // Check if account has home_domain data entry
/// try {
///   var domainData = await sdk.accounts.data(
///     accountId: accountId,
///     key: 'home_domain',
///   );
///   String domain = domainData.decodedString;
///   print('Account home domain: $domain');
/// } catch (e) {
///   print('No home_domain set for this account');
/// }
/// ```
///
/// See also:
/// - [AccountResponse] for full account details including all data entries
/// - [ManageDataOperation] for creating/updating data entries
/// - [Stellar developer docs](https://developers.stellar.org)
class AccountDataResponse extends Response {
  /// The base64 encoded value of the data entry
  final String value;

  /// Creates an AccountDataResponse from Horizon API data.
  ///
  /// Parameters:
  /// - [value]: Base64-encoded data entry value
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