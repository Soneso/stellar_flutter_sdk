import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' show sha256;
import "package:unorm_dart/unorm_dart.dart" as unorm;
import "dart:convert";
import 'package:pointycastle/export.dart';
import '../../constants/mnemonic_constants.dart';

typedef Uint8List RandomBytes(int size);

class HexCodec extends Codec<List<int>, String> {
  const HexCodec();

  @override
  Converter<List<int>, String> get encoder => const HexEncoder();

  @override
  Converter<String, List<int>> get decoder => const HexDecoder();
}

/// Encodes byte arrays to hexadecimal strings.
///
/// Used internally for converting binary data to hex representation.
class HexEncoder extends Converter<List<int>, String> {
  final bool upperCase;

  const HexEncoder({this.upperCase = false});

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
/// Used internally for converting hex strings to binary data.
class HexDecoder extends Converter<String, List<int>> {
  const HexDecoder();

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
/// Used for deriving the BIP-39 seed from a mnemonic phrase and passphrase.
/// Implements PBKDF2-HMAC-SHA512 with configurable parameters.
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
    // BUG FIX: Changed from 255 to 256 to include full byte range (0-255)
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

List<int> stringNormalize(String stringToNormalize) {
  String normalizedString = unorm.nfkd(stringToNormalize);
  List<int> stringToBuffer = utf8.encode(normalizedString);
  return stringToBuffer;
}

/// Converts a BIP-39 mnemonic to a 64-byte seed using PBKDF2.
///
/// The seed is derived using PBKDF2-HMAC-SHA512 with 2048 iterations.
/// An optional passphrase can be provided for additional security.
///
/// Parameters:
/// - [mnemonic]: The BIP-39 mnemonic phrase
/// - [passphrase]: Optional passphrase (default: empty string)
///
/// Returns: 64-byte seed for key derivation
Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
  List<int> passBuffer = stringNormalize(passphrase);
  String normalizedPass = String.fromCharCodes(passBuffer);

  final pbkdf2 = new PBKDF2(salt: 'mnemonic' + normalizedPass);
  return pbkdf2.process(mnemonic);
}

/// Converts a mnemonic to a hex-encoded seed string.
///
/// Parameters:
/// - [mnemonic]: The BIP-39 mnemonic phrase
/// - [passphrase]: Optional passphrase (default: empty string)
///
/// Returns: 128-character hex string (64 bytes)
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
