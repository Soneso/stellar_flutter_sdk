import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' show sha256;
import "package:unorm_dart/unorm_dart.dart" as unorm;
import "dart:convert";
import 'package:pointycastle/export.dart';
import '../../constants/mnemonic_constants.dart';

typedef Uint8List RandomBytes(int size);

/// Codec for converting between byte arrays and hexadecimal strings.
///
/// Provides bidirectional conversion used internally for entropy handling
/// in BIP-39 mnemonic generation and validation.
///
/// Example:
/// ```dart
/// const codec = HexCodec();
/// List<int> bytes = [0xDE, 0xAD, 0xBE, 0xEF];
/// String hex = codec.encode(bytes); // "deadbeef"
/// List<int> decoded = codec.decode(hex); // [222, 173, 190, 239]
/// ```
class HexCodec extends Codec<List<int>, String> {
  const HexCodec();

  @override
  Converter<List<int>, String> get encoder => const HexEncoder();

  @override
  Converter<String, List<int>> get decoder => const HexDecoder();
}

/// Encodes byte arrays to hexadecimal strings.
///
/// Converts binary data to hexadecimal string representation. Used internally
/// for entropy handling in BIP-39 mnemonic operations.
///
/// Example:
/// ```dart
/// const encoder = HexEncoder();
/// String hex = encoder.convert([255, 0, 128]); // "ff0080"
/// ```
class HexEncoder extends Converter<List<int>, String> {
  final bool upperCase;

  const HexEncoder({this.upperCase = false});

  /// Converts byte array to hexadecimal string representation.
  @override
  String convert(List<int> bytes) {
    StringBuffer buffer = new StringBuffer();
    for (int part in bytes) {
      if (part & 0xff != part) {
        throw new FormatException("Non-byte integer detected");
      }
      buffer.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }
    if (upperCase) {
      return buffer.toString().toUpperCase();
    } else {
      return buffer.toString();
    }
  }
}

/// Decodes hexadecimal strings to byte arrays.
///
/// Converts hexadecimal string representation to binary data. Used internally
/// for entropy handling in BIP-39 mnemonic operations. Handles both uppercase
/// and lowercase hex, and automatically pads odd-length strings.
///
/// Example:
/// ```dart
/// const decoder = HexDecoder();
/// List<int> bytes = decoder.convert("ff0080"); // [255, 0, 128]
/// ```
///
/// Throws:
/// - [FormatException]: If string contains non-hexadecimal characters
class HexDecoder extends Converter<String, List<int>> {
  const HexDecoder();

  /// Converts hexadecimal string to byte array.
  @override
  List<int> convert(String hex) {
    String str = hex.replaceAll(" ", "");
    str = str.toLowerCase();
    if (str.length % 2 != 0) {
      str = "0" + str;
    }
    Uint8List result = new Uint8List(str.length ~/ 2);
    String alphabet = "0123456789abcdef";
    for (int i = 0; i < result.length; i++) {
      int firstDigit = alphabet.indexOf(str[i * 2]);
      int secondDigit = alphabet.indexOf(str[i * 2 + 1]);
      if (firstDigit == -1 || secondDigit == -1) {
        throw new FormatException("Non-hex character detected in $hex");
      }
      result[i] = (firstDigit << 4) + secondDigit;
    }
    return result;
  }
}

/// PBKDF2 key derivation function implementation.
///
/// Implements PBKDF2-HMAC-SHA512 for deriving BIP-39 seeds from mnemonic phrases.
/// The seed derivation process combines the mnemonic with an optional passphrase
/// using 2048 iterations to produce a 512-bit (64-byte) seed.
///
/// Default parameters (from BIP-39):
/// - Hash function: HMAC-SHA512
/// - Block length: 128 bytes
/// - Iterations: 2048
/// - Output length: 64 bytes
///
/// Security considerations:
/// - The passphrase adds an additional security layer
/// - Using a passphrase creates a completely different wallet
/// - Lost passphrases cannot be recovered
///
/// Example:
/// ```dart
/// final pbkdf2 = PBKDF2(salt: 'mnemonic' + passphrase);
/// Uint8List seed = pbkdf2.process(mnemonic);
/// ```
///
/// See also:
/// - [mnemonicToSeed] for convenient seed generation
/// - [BIP-39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
class PBKDF2 {
  final int blockLength;
  final int iterationCount;
  final int desiredKeyLength;

  late PBKDF2KeyDerivator _derivator;
  late Uint8List _salt;

  PBKDF2(
      {this.blockLength = MnemonicConstants.PBKDF2_BLOCK_LENGTH_BYTES,
      this.iterationCount = MnemonicConstants.PBKDF2_ITERATION_COUNT,
      this.desiredKeyLength = MnemonicConstants.PBKDF2_KEY_LENGTH_BYTES,
      String salt = "mnemonic"}) {
    _salt = Uint8List.fromList(utf8.encode(salt));
    _derivator = new PBKDF2KeyDerivator(new HMac(new SHA512Digest(), blockLength))
      ..init(new Pbkdf2Parameters(_salt, iterationCount, desiredKeyLength));
  }

  /// Derives 64-byte seed from mnemonic using PBKDF2-HMAC-SHA512.
  Uint8List process(String mnemonic) {
    return _derivator.process(new Uint8List.fromList(mnemonic.codeUnits));
  }
}

int _binaryToByte(String binary) {
  return int.parse(binary, radix: 2);
}

String _bytesToBinary(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
}

String _deriveChecksumBits(Uint8List entropy) {
  final ENT = entropy.length * 8;
  final CS = ENT ~/ MnemonicConstants.CHECKSUM_BITS_PER_32_ENT_BITS;
  // final hash = sha256.newInstance().convert(entropy);
  final hash = sha256.convert(entropy);
  return _bytesToBinary(Uint8List.fromList(hash.bytes)).substring(0, CS);
}

Uint8List _randomBytes(int size) {
  final rng = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    // Using 256 (not 255) ensures uniform distribution across full byte range.
    // nextInt(256) generates values 0-255 inclusive, avoiding modulo bias that
    // would occur if using nextInt(255) then adding 1 or similar approaches.
    bytes[i] = rng.nextInt(MnemonicConstants.RANDOM_BYTE_MAX_VALUE);
  }
  return bytes;
}

/// Generates a BIP-39 mnemonic from random entropy.
///
/// Parameters:
/// - [strength]: Entropy bits (128, 160, 192, 224, or 256)
/// - [randomBytes]: Custom random generator (default: secure random)
/// - [wordList]: Word list for the mnemonic language
///
/// Returns: Space-separated mnemonic phrase
String generateMnemonic(
    {int strength = MnemonicConstants.MNEMONIC_ENTROPY_BITS_12_WORDS, RandomBytes randomBytes = _randomBytes, required List<String> wordList}) {
  assert(strength % MnemonicConstants.MNEMONIC_ENTROPY_MULTIPLE_BITS == 0);
  final entropy = randomBytes(strength ~/ 8);
  HexCodec hexCodec = HexCodec();
  return entropyToMnemonic(hexCodec.encode(entropy), wordList);
}

/// Converts entropy bytes to a mnemonic phrase.
///
/// Parameters:
/// - [entropyString]: Hex-encoded entropy
/// - [wordlist]: Word list for the mnemonic
///
/// Returns: Space-separated mnemonic phrase
String entropyToMnemonic(String entropyString, List<String> wordlist) {
  HexCodec hexCodec = HexCodec();
  final entropy = hexCodec.decode(entropyString);
  if (entropy.length < MnemonicConstants.MNEMONIC_MIN_ENTROPY_BYTES ||
      entropy.length > MnemonicConstants.MNEMONIC_MAX_ENTROPY_BYTES ||
      entropy.length % MnemonicConstants.MNEMONIC_ENTROPY_MULTIPLE_BYTES != 0) {
    throw ArgumentError('Invalid entropy');
  }

  final entropyBits = _bytesToBinary(Uint8List.fromList(entropy));
  final checksumBits = _deriveChecksumBits(Uint8List.fromList(entropy));
  final bits = entropyBits + checksumBits;
  final regex = new RegExp(r".{1,11}", caseSensitive: false, multiLine: false);
  final chunks = regex.allMatches(bits).map((match) => match.group(0)).toList(growable: false);
  //List<String> wordlist = WordList.englishWords();
  String words = chunks.map((binary) => wordlist[_binaryToByte(binary!)]).join(' ');
  return words;
}

/// Normalizes string to NFKD Unicode format for BIP-39 compatibility.
List<int> stringNormalize(String stringToNormalize) {
  String normalizedString = unorm.nfkd(stringToNormalize);
  List<int> stringToBuffer = utf8.encode(normalizedString);
  return stringToBuffer;
}

/// Converts a BIP-39 mnemonic to a 64-byte seed using PBKDF2.
///
/// The seed is derived using PBKDF2-HMAC-SHA512 with 2048 iterations.
/// An optional passphrase can be provided for additional security.
/// BIP-39 seeds are always 512 bits (64 bytes) regardless of mnemonic length.
///
/// Parameters:
/// - [mnemonic]: The BIP-39 mnemonic phrase
/// - [passphrase]: Optional passphrase (default: empty string)
///
/// Returns: 64-byte (512-bit) seed for key derivation
Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
  List<int> passBuffer = stringNormalize(passphrase);
  String normalizedPass = String.fromCharCodes(passBuffer);

  final pbkdf2 = new PBKDF2(salt: 'mnemonic' + normalizedPass);
  return pbkdf2.process(mnemonic);
}

/// Converts a mnemonic to a hex-encoded seed string.
///
/// BIP-39 seeds are always 512 bits (64 bytes) regardless of mnemonic length.
///
/// Parameters:
/// - [mnemonic]: The BIP-39 mnemonic phrase
/// - [passphrase]: Optional passphrase (default: empty string)
///
/// Returns: 128-character hex string (64 bytes / 512 bits)
String mnemonicToSeedHex(String mnemonic, {String passphrase = ''}) {
  return mnemonicToSeed(mnemonic, passphrase: passphrase).map((byte) {
    return byte.toRadixString(16).padLeft(2, '0');
  }).join('');
}

/// Validates a BIP-39 mnemonic phrase.
///
/// Checks word validity and checksum correctness.
///
/// Parameters:
/// - [mnemonic]: The mnemonic phrase to validate
/// - [wordList]: Word list for the mnemonic language
///
/// Returns: true if valid, false otherwise
bool validateMnemonic(String mnemonic, List<String> wordList) {
  try {
    mnemonicToEntropy(mnemonic, wordList);
  } catch (e) {
    return false;
  }
  return true;
}

/// Converts a mnemonic back to its original entropy.
///
/// Used internally for mnemonic validation.
///
/// Parameters:
/// - [mnemonic]: The mnemonic phrase
/// - [wordList]: Word list for the mnemonic language
///
/// Returns: Hex-encoded entropy
///
/// Throws: [ArgumentError] or [StateError] if mnemonic is invalid
String mnemonicToEntropy(mnemonic, List<String> wordList) {
  var words = mnemonic.split(' ');
  if (words.length % 3 != 0) {
    throw new ArgumentError('Invalid mnemonic');
  }
  //final wordlist = WordList.englishWords();
  // convert word indices to 11 bit binary strings
  final bits = words.map((word) {
    final index = wordList.indexOf(word);
    if (index == -1) {
      throw new ArgumentError('Invalid mnemonic');
    }
    return index.toRadixString(2).padLeft(11, '0');
  }).join('');
  // split the binary string into ENT/CS
  final dividerIndex = (bits.length / MnemonicConstants.MNEMONIC_DIVIDER_RATIO).floor() * MnemonicConstants.MNEMONIC_ENTROPY_MULTIPLE_BITS;
  final entropyBits = bits.substring(0, dividerIndex);
  final checksumBits = bits.substring(dividerIndex);

  // calculate the checksum and compare
  final regex = RegExp(r".{1,8}");
  final entropyBytes = Uint8List.fromList(regex
      .allMatches(entropyBits)
      .map((match) => _binaryToByte(match.group(0)!))
      .toList(growable: false));
  if (entropyBytes.length < MnemonicConstants.MNEMONIC_MIN_ENTROPY_BYTES ||
      entropyBytes.length > MnemonicConstants.MNEMONIC_MAX_ENTROPY_BYTES ||
      entropyBytes.length % MnemonicConstants.MNEMONIC_ENTROPY_MULTIPLE_BYTES != 0) {
    throw StateError('Invalid entropy');
  }
  final newChecksum = _deriveChecksumBits(entropyBytes);
  if (newChecksum != checksumBits) {
    throw StateError('Invalid mnemonic checksum');
  }
  return entropyBytes.map((byte) {
    return byte.toRadixString(16).padLeft(2, '0');
  }).join('');
}
