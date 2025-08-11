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

checkNotNull(var reference, String errorMessage) {
  if (reference == null) {
    throw new Exception(errorMessage);
  }
  return reference;
}

checkArgument(bool expression, String errorMessage) {
  if (!expression) {
    throw new Exception(errorMessage);
  }
}

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

bool isHexString(String input) {
  // Check if string contains only hex characters (0-9, a-f, A-F)
  final hexRegExp = RegExp(r'^[0-9a-fA-F]+$');
  return hexRegExp.hasMatch(input);
}

/// Tries to convert a given id to an Address. The given id can be a contract id,
/// an account id, a muxed account id, a claimable balance id, or a liquidity pool id.
/// If not, returns null.
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
      return Address.forContractId(id);
    }
    if (StrKey.isValidLiquidityPoolId(id)) {
      return Address.forLiquidityPoolId(id);
    }
  }
  return null;
}

class FriendBot {
  FriendBot();

  /// Ask the friendly bot to fund your testnet account given by [accountId].
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

class FuturenetFriendBot {
  FuturenetFriendBot();

  /// Ask the friendly bot to fund your testnet account given by [accountId].
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

class Util {
  /// Creates a hex string from bytes [raw].
  static String bytesToHex(Uint8List raw) {
    return hex.encode(raw);
  }

  /// Returns bytes from hex [s].
  static Uint8List hexToBytes(String s) {
    return Uint8List.fromList(hex.decode(s));
  }

  /// Returns SHA-256 hash of [data].
  static Uint8List hash(Uint8List data) {
    return Uint8List.fromList(sha256.convert(data).bytes);
  }

  ///Pads [bytes] array to [length] with zeros.
  static Uint8List paddedByteArray(Uint8List bytes, int length) {
    Uint8List finalBytes = Uint8List.fromList(List<int>.filled(length, 0x0));
    finalBytes.setAll(0, bytes);
    return finalBytes;
  }

  ///Pads [string] to [length] with zeros.
  static Uint8List paddedByteArrayString(String string, int length) {
    return Util.paddedByteArray(Uint8List.fromList(utf8.encode(string)), length);
  }

  ///Remove zeros from the end of [bytes] array.
  static String paddedByteArrayToString(Uint8List? bytes) {
    return String.fromCharCodes(bytes!).split('\x00')[0];
  }

  static XdrHash stringIdToXdrHash(String strId) {
    Uint8List bytes = Util.hexToBytes(strId.toUpperCase());
    if (bytes.length < 32) {
      bytes = Util.paddedByteArray(bytes, 32);
    } else if (bytes.length > 32) {
      bytes = bytes.sublist(bytes.length - 32, bytes.length);
    }

    return XdrHash(bytes);
  }

  static Future<Uint8List> readFile(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File theFile = new File.fromUri(myUri);
    return Uint8List.fromList(await theFile.readAsBytes());
  }

  static final Random _random = Random.secure();

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

class Base32 {
  static const _base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Takes in a list of [bytes] converts it to a Uint8List so that one can run
  /// bit operations on it, then outputs a base32 [String] representation.
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

  /// Takes in a [hex] string, converts the string to a byte list
  /// and runs a normal encode() on it. Returns a [String] representation
  /// of the base32.
  static String encodeHexString(String hex) {
    var bytes = _hexStringToBytes(hex);
    return encode(bytes);
  }

  /// Takes in a [base32] string and decodes it back to a [Uint8List] that can be
  /// converted to a hex string using Crypto.bytesToHex().
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

const Base16Codec base16codec = Base16Codec();

String base16encode(final List<int> bytes) => base16codec.encode(bytes);

List<int> base16decode(final String encoded)=> base16codec.decode(encoded);

class Base16Codec extends Codec<List<int>, String>{
  const Base16Codec();

  final Converter<String, List<int>> decoder = const Base16Decoder();

  final Converter<List<int>, String> encoder = const Base16Encoder();
}

const int _radix = 16;
const int _charactersPerByte = 2;

class Base16Encoder extends Converter<List<int>, String>{
  const Base16Encoder();

  @override
  String convert(final List<int> input){
    final StringBuffer buffer = StringBuffer();
    for(final int byte in input)
      buffer.write(byte.toRadixString(_radix).padLeft(_charactersPerByte, "0"));
    return buffer.toString();
  }
}

class Base16Decoder extends Converter<String, List<int>>{
  const Base16Decoder();

  @override
  List<int> convert(final String input) => [
    for(int i=0; i<input.length; i+=_charactersPerByte)
      int.parse(input.substring(i, i+_charactersPerByte), radix: _radix),
  ];
}

