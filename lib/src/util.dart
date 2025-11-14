// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';

import "package:convert/convert.dart";
import 'package:crypto/crypto.dart';
import "dart:convert";
import "dart:io";
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'requests/request_builder.dart';
import 'soroban/soroban_auth.dart';
import 'xdr/xdr_type.dart';

/// Validates that a reference is not null.
///
/// Checks if the given [reference] is null and throws an exception
/// with the provided [errorMessage] if it is. Returns the reference
/// if it is not null.
///
/// Parameters:
/// - [reference]: The value to check for null
/// - [errorMessage]: Error message to include in the exception
///
/// Returns: The [reference] if it is not null
///
/// Throws:
/// - [Exception]: If the reference is null
///
/// Example:
/// ```dart
/// var accountId = checkNotNull(
///   maybeAccountId,
///   "Account ID cannot be null"
/// );
/// ```
checkNotNull(var reference, String errorMessage) {
  if (reference == null) {
    throw new Exception(errorMessage);
  }
  return reference;
}

/// Validates that an argument meets a required condition.
///
/// Checks if the given [expression] is true and throws an exception
/// with the provided [errorMessage] if it is false. Used for argument
/// validation in functions and methods.
///
/// Parameters:
/// - [expression]: Boolean condition that must be true
/// - [errorMessage]: Error message to include in the exception
///
/// Throws:
/// - [Exception]: If the expression is false
///
/// Example:
/// ```dart
/// checkArgument(
///   amount >= 0,
///   "Amount must be non-negative"
/// );
/// ```
checkArgument(bool expression, String errorMessage) {
  if (!expression) {
    throw new Exception(errorMessage);
  }
}

/// Removes trailing zeros from a numeric string.
///
/// Removes trailing zeros after the decimal point, and also removes
/// the decimal point itself if no significant digits remain after it.
///
/// Parameters:
/// - [src]: The numeric string to process
///
/// Returns: String with trailing zeros removed
///
/// Example:
/// ```dart
/// removeTailZero("123.4500"); // Returns "123.45"
/// removeTailZero("100.000");  // Returns "100"
/// removeTailZero("5.0");      // Returns "5"
/// ```
String removeTailZero(String src) {
  int pos = 0;
  for (int i = src.length - 1; i >= 0; i--) {
    if (src[i] == '0')
      pos++;
    else if (src[i] == '.') {
      pos++;
      break;
    } else
      break;
  }

  return src.substring(0, src.length - pos);
}

/// Checks if a string contains only hexadecimal characters.
///
/// Validates that the [input] string contains only valid hexadecimal
/// characters (0-9, a-f, A-F) with no other content.
///
/// Parameters:
/// - [input]: The string to validate
///
/// Returns: true if the string is valid hexadecimal, false otherwise
///
/// Example:
/// ```dart
/// isHexString("1a2b3c");    // Returns true
/// isHexString("ABCDEF");    // Returns true
/// isHexString("xyz123");    // Returns false
/// isHexString("12 34");     // Returns false
/// ```
bool isHexString(String input) {
  // Check if string contains only hex characters (0-9, a-f, A-F)
  final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
  return hexRegExp.hasMatch(input);
}

/// Converts a Stellar identifier string to an Address object.
///
/// Attempts to parse the given [id] as any of the following Stellar
/// address types: contract ID, account ID, muxed account ID, claimable
/// balance ID, or liquidity pool ID. The function tries each type in
/// sequence until a valid match is found.
///
/// The [id] can be provided either as a hexadecimal string or as a
/// strkey-encoded address (G..., M..., C..., B..., L...).
///
/// Parameters:
/// - [id]: The identifier to convert (hex or strkey format)
///
/// Returns: An [Address] object if the ID is valid, null otherwise
///
/// Example:
/// ```dart
/// // From strkey account ID
/// var addr1 = addressFromId("GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H");
///
/// // From hex contract ID
/// var addr2 = addressFromId("a1b2c3d4...");
///
/// // From muxed account
/// var addr3 = addressFromId("MAAAAAAA...");
/// ```
///
/// See also:
/// - [Address] for working with Stellar addresses
/// - [StrKey] for encoding and decoding address types
Address? addressFromId(String id) {

  if (isHexString(id)) {
    try {
      final contractId = StrKey.encodeContractIdHex(id);
      if (StrKey.isValidContractId(contractId)) {
        return Address.forContractId(contractId);
      }
    } catch(e) {}

    try {
      final liquidityPoolId = StrKey.encodeLiquidityPoolIdHex(id);
      if (StrKey.isValidLiquidityPoolId(liquidityPoolId)) {
        return Address.forLiquidityPoolId(liquidityPoolId);
      }
    } catch(e) {}

    try {
      final claimableBalanceId = StrKey.encodeClaimableBalanceIdHex(id);
      if (StrKey.isValidClaimableBalanceId(claimableBalanceId)) {
        return Address.forClaimableBalanceId(claimableBalanceId);
      }
    } catch(e) {}
  } else {
    if (StrKey.isValidStellarAccountId(id)) {
      return Address.forAccountId(id);
    }
    if (StrKey.isValidStellarMuxedAccountId(id)) {
      return Address.forMuxedAccountId(id);
    }
    if (StrKey.isValidContractId(id)) {
      return Address.forContractId(id);
    }
    if (StrKey.isValidClaimableBalanceId(id)) {
      return Address.forClaimableBalanceId(id);
    }
    if (StrKey.isValidLiquidityPoolId(id)) {
      return Address.forLiquidityPoolId(id);
    }
  }
  return null;
}

/// Provides access to the Stellar testnet FriendBot for funding test accounts.
///
/// FriendBot is a service that funds accounts on the Stellar testnet with
/// test XLM, allowing developers to create and test transactions without
/// using real funds. Each account can be funded multiple times.
///
/// Example:
/// ```dart
/// // Create a new keypair for testnet
/// KeyPair keypair = KeyPair.random();
///
/// // Fund the account using FriendBot
/// bool success = await FriendBot.fundTestAccount(keypair.accountId);
/// if (success) {
///   print("Account funded successfully");
/// }
/// ```
///
/// See also:
/// - [FuturenetFriendBot] for funding Futurenet accounts
class FriendBot {
  FriendBot();

  /// Funds a testnet account with test XLM.
  ///
  /// Requests the FriendBot service to fund the account identified by
  /// [accountId] with test XLM on the Stellar testnet. This is used for
  /// development and testing purposes only.
  ///
  /// Parameters:
  /// - [accountId]: The Stellar account ID (G...) to fund
  ///
  /// Returns: true if funding was successful, false otherwise
  ///
  /// Example:
  /// ```dart
  /// String accountId = "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H";
  /// bool success = await FriendBot.fundTestAccount(accountId);
  /// ```
  static Future<bool> fundTestAccount(String accountId) async {
    var url = Uri.parse("https://friendbot.stellar.org/?addr=$accountId");
    return await http.get(url, headers: RequestBuilder.headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return true;
        default:
          return false;
      }
    });
  }
}

/// Provides access to the Stellar Futurenet FriendBot for funding test accounts.
///
/// FuturenetFriendBot is a service that funds accounts on the Stellar Futurenet
/// (a testing network for upcoming features) with test XLM. Futurenet is used
/// to test new protocol features before they are released to testnet and mainnet.
///
/// Example:
/// ```dart
/// // Create a new keypair for Futurenet
/// KeyPair keypair = KeyPair.random();
///
/// // Fund the account using FuturenetFriendBot
/// bool success = await FuturenetFriendBot.fundTestAccount(keypair.accountId);
/// if (success) {
///   print("Futurenet account funded successfully");
/// }
/// ```
///
/// See also:
/// - [FriendBot] for funding testnet accounts
class FuturenetFriendBot {
  FuturenetFriendBot();

  /// Funds a Futurenet account with test XLM.
  ///
  /// Requests the Futurenet FriendBot service to fund the account identified
  /// by [accountId] with test XLM. This is used for testing new Stellar
  /// protocol features in development.
  ///
  /// Parameters:
  /// - [accountId]: The Stellar account ID (G...) to fund
  ///
  /// Returns: true if funding was successful, false otherwise
  ///
  /// Example:
  /// ```dart
  /// String accountId = "GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H";
  /// bool success = await FuturenetFriendBot.fundTestAccount(accountId);
  /// ```
  static Future<bool> fundTestAccount(String accountId) async {
    var url = Uri.parse("https://friendbot-futurenet.stellar.org?addr=$accountId");
    return await http.get(url, headers: RequestBuilder.headers).then((response) {
      switch (response.statusCode) {
        case 200:
          return true;
        default:
          return false;
      }
    });
  }
}

/// Provides utility methods for common operations in the Stellar SDK.
///
/// This class contains static helper methods for encoding, hashing,
/// padding, and converting data formats commonly used when working
/// with Stellar transactions and operations.
///
/// Example:
/// ```dart
/// // Convert bytes to hex
/// String hex = Util.bytesToHex(myBytes);
///
/// // Hash data with SHA-256
/// Uint8List hash = Util.hash(myData);
///
/// // Pad a byte array to specific length
/// Uint8List padded = Util.paddedByteArray(myBytes, 32);
/// ```
class Util {
  /// Converts a byte array to a hexadecimal string.
  ///
  /// Takes a [raw] byte array and returns its hexadecimal string
  /// representation using lowercase characters.
  ///
  /// Parameters:
  /// - [raw]: The byte array to convert
  ///
  /// Returns: Hexadecimal string representation
  ///
  /// Example:
  /// ```dart
  /// Uint8List bytes = Uint8List.fromList([255, 0, 128]);
  /// String hex = Util.bytesToHex(bytes); // Returns "ff0080"
  /// ```
  static String bytesToHex(Uint8List raw) {
    return hex.encode(raw);
  }

  /// Converts a hexadecimal string to a byte array.
  ///
  /// Takes a hexadecimal string [s] and returns the corresponding
  /// byte array. The string must contain only valid hex characters.
  ///
  /// Parameters:
  /// - [s]: The hexadecimal string to convert
  ///
  /// Returns: Byte array representation
  ///
  /// Throws:
  /// - [FormatException]: If the string is not valid hexadecimal
  ///
  /// Example:
  /// ```dart
  /// Uint8List bytes = Util.hexToBytes("ff0080");
  /// // Returns [255, 0, 128]
  /// ```
  static Uint8List hexToBytes(String s) {
    return Uint8List.fromList(hex.decode(s));
  }

  /// Computes the SHA-256 hash of data.
  ///
  /// Takes a byte array [data] and returns its SHA-256 hash.
  /// This is commonly used for transaction hashing and signature
  /// verification in Stellar.
  ///
  /// Parameters:
  /// - [data]: The data to hash
  ///
  /// Returns: 32-byte SHA-256 hash
  ///
  /// Example:
  /// ```dart
  /// Uint8List data = Uint8List.fromList([1, 2, 3, 4]);
  /// Uint8List hash = Util.hash(data);
  /// ```
  static Uint8List hash(Uint8List data) {
    return Uint8List.fromList(sha256.convert(data).bytes);
  }

  /// Pads a byte array to a specified length with zero bytes.
  ///
  /// Takes a [bytes] array and pads it with zeros at the end to reach
  /// the specified [length]. If the array is already longer than [length],
  /// it is returned unchanged.
  ///
  /// Parameters:
  /// - [bytes]: The byte array to pad
  /// - [length]: The desired final length
  ///
  /// Returns: Padded byte array of specified length
  ///
  /// Example:
  /// ```dart
  /// Uint8List bytes = Uint8List.fromList([1, 2, 3]);
  /// Uint8List padded = Util.paddedByteArray(bytes, 5);
  /// // Returns [1, 2, 3, 0, 0]
  /// ```
  static Uint8List paddedByteArray(Uint8List bytes, int length) {
    Uint8List finalBytes = Uint8List.fromList(List<int>.filled(length, 0x0));
    finalBytes.setAll(0, bytes);
    return finalBytes;
  }

  /// Pads a string to a specified length with zero bytes.
  ///
  /// Converts the [string] to UTF-8 bytes and pads it with zeros to
  /// reach the specified [length]. Useful for fixed-length string fields.
  ///
  /// Parameters:
  /// - [string]: The string to pad
  /// - [length]: The desired final length in bytes
  ///
  /// Returns: Padded byte array of specified length
  ///
  /// Example:
  /// ```dart
  /// Uint8List padded = Util.paddedByteArrayString("XLM", 4);
  /// // Returns UTF-8 bytes of "XLM" plus one zero byte
  /// ```
  static Uint8List paddedByteArrayString(String string, int length) {
    return Util.paddedByteArray(Uint8List.fromList(utf8.encode(string)), length);
  }

  /// Converts a padded byte array back to a string.
  ///
  /// Removes trailing zero bytes from the [bytes] array and converts
  /// the result to a string. Used to decode fixed-length string fields.
  ///
  /// Parameters:
  /// - [bytes]: The padded byte array to convert
  ///
  /// Returns: String with trailing zeros removed
  ///
  /// Example:
  /// ```dart
  /// Uint8List bytes = Uint8List.fromList([88, 76, 77, 0, 0]);
  /// String str = Util.paddedByteArrayToString(bytes); // Returns "XLM"
  /// ```
  static String paddedByteArrayToString(Uint8List? bytes) {
    return String.fromCharCodes(bytes!).split('\x00')[0];
  }

  /// Converts a hex string ID to an XDR hash object.
  ///
  /// Takes a hexadecimal string [strId] and converts it to an XdrHash
  /// object used in Stellar XDR structures. The hash is padded or
  /// truncated to exactly 32 bytes.
  ///
  /// Parameters:
  /// - [strId]: The hex string ID to convert
  ///
  /// Returns: XdrHash object containing the 32-byte hash
  ///
  /// Example:
  /// ```dart
  /// String id = "a1b2c3...";
  /// XdrHash hash = Util.stringIdToXdrHash(id);
  /// ```
  static XdrHash stringIdToXdrHash(String strId) {
    Uint8List bytes = Util.hexToBytes(strId.toUpperCase());
    if (bytes.length < 32) {
      bytes = Util.paddedByteArray(bytes, 32);
    } else if (bytes.length > 32) {
      bytes = bytes.sublist(bytes.length - 32, bytes.length);
    }

    return XdrHash(bytes);
  }

  /// Reads a file from the filesystem and returns its contents as bytes.
  ///
  /// Takes a [filePath] (as a string or URI) and reads the file contents
  /// asynchronously, returning the data as a byte array.
  ///
  /// Parameters:
  /// - [filePath]: The path to the file to read
  ///
  /// Returns: The file contents as a byte array
  ///
  /// Throws:
  /// - [FileSystemException]: If the file cannot be read
  ///
  /// Example:
  /// ```dart
  /// Uint8List data = await Util.readFile("/path/to/file.bin");
  /// ```
  static Future<Uint8List> readFile(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File theFile = new File.fromUri(myUri);
    return Uint8List.fromList(await theFile.readAsBytes());
  }

  static final Random _random = Random.secure();

  /// Creates a cryptographically secure random string.
  ///
  /// Generates a random string using a secure random number generator.
  /// The string is base64url-encoded and suitable for use in security
  /// contexts like nonces, tokens, or challenge strings.
  ///
  /// Parameters:
  /// - [length]: Number of random bytes to generate (default: 32)
  ///
  /// Returns: Base64url-encoded random string
  ///
  /// Example:
  /// ```dart
  /// String nonce = Util.createCryptoRandomString(32);
  /// String token = Util.createCryptoRandomString(16);
  /// ```
  static String createCryptoRandomString([int length = 32]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));

    return base64Url.encode(values);
  }

  /// Appends an [endpoint] to a [baseUrl] string in a way that handles the presence or absence of a trailing slash in the [baseUrl].
  ///
  /// The function ensures that the returned URL does not have a double slash "//" between the base URL and the endpoint.
  ///
  /// This method is particularly useful when working with base URLs returned from various API sources, where some may end with a trailing slash and some may not.
  ///
  /// Returns the resulting URL as a [Uri].
  ///
  /// Example:
  /// ```dart
  /// String serverUrl = "https://api.anchor.com/sep6";
  /// String endpoint = "info";
  /// Uri serverUri = Utils.appendEndpointToUrl(serverUrl, endpoint);
  /// // finalUrl will be a Uri for "https://api.anchor.com/sep6/info"
  /// ```
  static Uri appendEndpointToUrl(String baseUrl, String endpoint) {
    // Ensure there is no trailing slash
    if (baseUrl.endsWith("/")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // Now append the endpoint
    String completeUrl = "$baseUrl/$endpoint";
    return Uri.parse(completeUrl);
  }

  /// Converts a decimal amount string to XDR Int64 format.
  ///
  /// Stellar uses 7 decimal places of precision for amounts, storing them
  /// as integers (stroops). This method converts a decimal string like
  /// "123.45" to the XDR format: 1234500000.
  ///
  /// Parameters:
  /// - [value]: Decimal amount string (e.g., "123.45")
  ///
  /// Returns: Amount in stroops (1 XLM = 10000000 stroops)
  ///
  /// Throws:
  /// - [Exception]: If decimal places exceed 7 digits
  ///
  /// Example:
  /// ```dart
  /// BigInt stroops = Util.toXdrBigInt64Amount("100.5");
  /// // Returns 1005000000 (100.5 * 10000000)
  /// ```
  ///
  /// See also:
  /// - [fromXdrBigInt64Amount] for converting back to decimal format
  static BigInt toXdrBigInt64Amount(String value) {
    List<String> two = value.split(".");
    BigInt amount = BigInt.parse(two[0]) * BigInt.from(10000000);

    if (two.length == 2) {
      int pos = 0;
      String point = two[1];
      for (int i = point.length - 1; i >= 0; i--) {
        if (point[i] == '0')
          pos++;
        else
          break;
      }
      point = point.substring(0, point.length - pos);
      int length = 7 - point.length;
      if (length < 0)
        throw Exception("The decimal point cannot exceed seven digits.");
      for (; length > 0; length--) point += "0";
      amount += BigInt.parse(point);
    }

    return amount;
  }

  /// Converts an XDR Int64 amount to decimal string format.
  ///
  /// Converts an amount from XDR format (stroops) back to a human-readable
  /// decimal string. Removes trailing zeros from the result.
  ///
  /// Parameters:
  /// - [value]: Amount in stroops (1 XLM = 10000000 stroops)
  ///
  /// Returns: Decimal amount string with trailing zeros removed
  ///
  /// Example:
  /// ```dart
  /// String amount = Util.fromXdrBigInt64Amount(BigInt.from(1005000000));
  /// // Returns "100.5"
  /// ```
  ///
  /// See also:
  /// - [toXdrBigInt64Amount] for converting from decimal format
  static String fromXdrBigInt64Amount(BigInt value) {
    String amountString = value.toString();
    if (amountString.length > 7) {
      amountString = amountString.substring(0, amountString.length - 7) +
          "." +
          amountString.substring(amountString.length - 7, amountString.length);
    } else {
      int length = 7 - amountString.length;
      String point = "0.";
      for (; length > 0; length--) point += "0";
      amountString = point + amountString;
    }
    return removeTailZero(amountString);
  }

}

/// Provides Base32 encoding and decoding functionality.
///
/// Base32 encoding is used by Stellar for encoding addresses and keys
/// in a human-readable format. This implementation uses the standard
/// Base32 alphabet (A-Z, 2-7) as specified in RFC 4648.
///
/// Example:
/// ```dart
/// // Encode bytes to Base32
/// Uint8List data = Uint8List.fromList([104, 101, 108, 108, 111]);
/// String encoded = Base32.encode(data);
///
/// // Decode Base32 back to bytes
/// Uint8List decoded = Base32.decode(encoded);
/// ```
///
/// See also:
/// - [StrKey] which uses Base32 for Stellar address encoding
class Base32 {
  static const _base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Encodes a byte array to a Base32 string.
  ///
  /// Takes a [bytes] array and converts it to a Base32 string using
  /// the standard Base32 alphabet. This encoding is used in Stellar
  /// addresses and key representations.
  ///
  /// Parameters:
  /// - [bytes]: The byte array to encode
  ///
  /// Returns: Base32 encoded string
  ///
  /// Example:
  /// ```dart
  /// Uint8List data = Uint8List.fromList([1, 2, 3, 4]);
  /// String encoded = Base32.encode(data);
  /// ```
  static String encode(Uint8List bytes) {
    int i = 0, index = 0, digit = 0;
    int currByte, nextByte;
    String base32 = '';

    while (i < bytes.length) {
      currByte = bytes[i];

      if (index > 3) {
        if ((i + 1) < bytes.length) {
          nextByte = bytes[i + 1];
        } else {
          nextByte = 0;
        }

        digit = currByte & (0xFF >> index);
        index = (index + 5) % 8;
        digit <<= index;
        digit |= nextByte >> (8 - index);
        i++;
      } else {
        digit = (currByte >> (8 - (index + 5)) & 0x1F);
        index = (index + 5) % 8;
        if (index == 0) {
          i++;
        }
      }
      base32 = base32 + _base32Chars[digit];
    }
    return base32;
  }

  /// Encodes a hexadecimal string to Base32.
  ///
  /// Converts the [hex] string to bytes and then encodes those bytes
  /// to Base32 format. This is a convenience method combining hex
  /// decoding and Base32 encoding.
  ///
  /// Parameters:
  /// - [hex]: Hexadecimal string to encode
  ///
  /// Returns: Base32 encoded string
  ///
  /// Example:
  /// ```dart
  /// String base32 = Base32.encodeHexString("48656c6c6f");
  /// ```
  static String encodeHexString(String hex) {
    var bytes = _hexStringToBytes(hex);
    return encode(bytes);
  }

  /// Decodes a Base32 string to a byte array.
  ///
  /// Takes a [base32] encoded string and decodes it back to its
  /// original byte array representation. The result can be converted
  /// to hexadecimal using Util.bytesToHex().
  ///
  /// Parameters:
  /// - [base32]: The Base32 string to decode
  ///
  /// Returns: Decoded byte array
  ///
  /// Example:
  /// ```dart
  /// Uint8List bytes = Base32.decode("JBSWY3DPEBLW64TMMQ");
  /// ```
  static Uint8List decode(String base32) {
    int index = 0, lookup, offset = 0, digit;
    Uint8List bytes = new Uint8List(base32.length * 5 ~/ 8);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }

    for (int i = 0; i < base32.length; i++) {
      lookup = base32.codeUnitAt(i) - '0'.codeUnitAt(0);
      if (lookup < 0 || lookup >= _base32Lookup.length) {
        continue;
      }

      digit = _base32Lookup[lookup];
      if (digit == 0xFF) {
        continue;
      }

      if (index <= 3) {
        index = (index + 5) % 8;
        if (index == 0) {
          bytes[offset] |= digit;
          offset++;
          if (offset >= bytes.length) {
            break;
          }
        } else {
          bytes[offset] |= digit << (8 - index);
        }
      } else {
        index = (index + 5) % 8;
        bytes[offset] |= (digit >> index);
        offset++;

        if (offset >= bytes.length) {
          break;
        }

        bytes[offset] |= digit << (8 - index);
      }
    }
    return bytes;
  }

  static Uint8List _hexStringToBytes(hex) {
    int i = 0;
    Uint8List bytes = new Uint8List(hex.length ~/ 2);
    final RegExp regex = new RegExp('[0-9a-f]{2}');
    for (Match match in regex.allMatches(hex.toLowerCase())) {
      bytes[i++] = int.parse(hex.toLowerCase().substring(match.start, match.end), radix: 16);
    }
    return bytes;
  }

  static const _base32Lookup = const [
    0xFF, 0xFF, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E,
    0x1F, // '0', '1', '2', '3', '4', '5', '6', '7'
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, // '8', '9', ':', ';', '<', '=', '>', '?'
    0xFF, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
    0x06, // '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G'
    0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
    0x0E, // 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'
    0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15,
    0x16, // 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W'
    0x17, 0x18, 0x19, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, // 'X', 'Y', 'Z', '[', '\', ']', '^', '_'
    0xFF, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
    0x06, // '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g'
    0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
    0x0E, // 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o'
    0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15,
    0x16, // 'p', 'q', 'r', 's', 't', 'u', 'v', 'w'
    0x17, 0x18, 0x19, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF // 'x', 'y', 'z', '{', '|', '}', '~', 'DEL'
  ];
}

/// Constant instance of Base16Codec for convenient encoding/decoding.
const Base16Codec base16codec = Base16Codec();

/// Encodes a byte array to a Base16 (hexadecimal) string.
///
/// Convenience function that uses the default [base16codec] instance.
///
/// Parameters:
/// - [bytes]: The byte array to encode
///
/// Returns: Hexadecimal string representation
///
/// Example:
/// ```dart
/// List<int> data = [255, 0, 128];
/// String hex = base16encode(data); // Returns "ff0080"
/// ```
String base16encode(final List<int> bytes) => base16codec.encode(bytes);

/// Decodes a Base16 (hexadecimal) string to a byte array.
///
/// Convenience function that uses the default [base16codec] instance.
///
/// Parameters:
/// - [encoded]: The hexadecimal string to decode
///
/// Returns: Decoded byte array
///
/// Example:
/// ```dart
/// List<int> bytes = base16decode("ff0080"); // Returns [255, 0, 128]
/// ```
List<int> base16decode(final String encoded)=> base16codec.decode(encoded);

/// Codec for Base16 (hexadecimal) encoding and decoding.
///
/// Implements the Dart Codec interface to provide bidirectional conversion
/// between byte arrays and hexadecimal strings. Base16 encoding represents
/// each byte as two hexadecimal characters.
///
/// Example:
/// ```dart
/// const codec = Base16Codec();
/// String hex = codec.encode([255, 128, 0]);
/// List<int> bytes = codec.decode("ff8000");
/// ```
class Base16Codec extends Codec<List<int>, String>{
  const Base16Codec();

  final Converter<String, List<int>> decoder = const Base16Decoder();

  final Converter<List<int>, String> encoder = const Base16Encoder();
}

const int _radix = 16;
const int _charactersPerByte = 2;

/// Encoder for converting byte arrays to Base16 (hexadecimal) strings.
///
/// Converts each byte to two hexadecimal characters, padded with
/// leading zeros if necessary.
class Base16Encoder extends Converter<List<int>, String>{
  const Base16Encoder();

  /// Converts a byte array to a hexadecimal string.
  ///
  /// Parameters:
  /// - [input]: The byte array to encode
  ///
  /// Returns: Hexadecimal string representation
  @override
  String convert(final List<int> input){
    final StringBuffer buffer = StringBuffer();
    for(final int byte in input)
      buffer.write(byte.toRadixString(_radix).padLeft(_charactersPerByte, "0"));
    return buffer.toString();
  }
}

/// Decoder for converting Base16 (hexadecimal) strings to byte arrays.
///
/// Parses pairs of hexadecimal characters into individual bytes.
class Base16Decoder extends Converter<String, List<int>>{
  const Base16Decoder();

  /// Converts a hexadecimal string to a byte array.
  ///
  /// Parameters:
  /// - [input]: The hexadecimal string to decode
  ///
  /// Returns: Decoded byte array
  @override
  List<int> convert(final String input) => [
    for(int i=0; i<input.length; i+=_charactersPerByte)
      int.parse(input.substring(i, i+_charactersPerByte), radix: _radix),
  ];
}

