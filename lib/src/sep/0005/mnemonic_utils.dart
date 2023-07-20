import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' show sha256;
import "package:unorm_dart/unorm_dart.dart" as unorm;
import "dart:convert";
import 'package:pointycastle/export.dart';

typedef Uint8List RandomBytes(int size);

class HexCodec extends Codec<List<int>, String> {
  const HexCodec();

  @override
  Converter<List<int>, String> get encoder => const HexEncoder();

  @override
  Converter<String, List<int>> get decoder => const HexDecoder();
}

/// Encodes byte arrays to hexadecimal strings.
class HexEncoder extends Converter<List<int>, String> {
  final bool upperCase;

  const HexEncoder({this.upperCase: false});

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

///Decodes hexadecimal strings to byte arrays.
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

class PBKDF2 {
  final int blockLength;
  final int iterationCount;
  final int desiredKeyLength;

  late PBKDF2KeyDerivator _derivator;
  late Uint8List _salt;

  PBKDF2(
      {this.blockLength = 128,
      this.iterationCount = 2048,
      this.desiredKeyLength = 64,
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
  final CS = ENT ~/ 32;
  // final hash = sha256.newInstance().convert(entropy);
  final hash = sha256.convert(entropy);
  return _bytesToBinary(Uint8List.fromList(hash.bytes)).substring(0, CS);
}

Uint8List _randomBytes(int size) {
  final rng = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = rng.nextInt(255);
  }
  return bytes;
}

String generateMnemonic(
    {int strength = 128, RandomBytes randomBytes = _randomBytes, required List<String> wordList}) {
  final entropy = randomBytes(strength ~/ 8);
  HexCodec hexCodec = HexCodec();
  return entropyToMnemonic(hexCodec.encode(entropy), wordList);
}

String entropyToMnemonic(String entropyString, List<String> wordlist) {
  HexCodec hexCodec = HexCodec();
  final entropy = hexCodec.decode(entropyString);
  if (entropy.length < 16 || entropy.length > 32 || entropy.length % 4 != 0) {
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

Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
  List<int> passBuffer = stringNormalize(passphrase);
  String normalizedPass = String.fromCharCodes(passBuffer);

  final pbkdf2 = new PBKDF2(salt: 'mnemonic' + normalizedPass);
  return pbkdf2.process(mnemonic);
}

String mnemonicToSeedHex(String mnemonic, {String passphrase = ''}) {
  return mnemonicToSeed(mnemonic, passphrase: passphrase).map((byte) {
    return byte.toRadixString(16).padLeft(2, '0');
  }).join('');
}

bool validateMnemonic(String mnemonic, List<String> wordList) {
  try {
    mnemonicToEntropy(mnemonic, wordList);
  } catch (e) {
    return false;
  }
  return true;
}

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
  final dividerIndex = (bits.length / 33).floor() * 32;
  final entropyBits = bits.substring(0, dividerIndex);
  final checksumBits = bits.substring(dividerIndex);

  // calculate the checksum and compare
  final regex = RegExp(r".{1,8}");
  final entropyBytes = Uint8List.fromList(regex
      .allMatches(entropyBits)
      .map((match) => _binaryToByte(match.group(0)!))
      .toList(growable: false));
  if (entropyBytes.length < 16 || entropyBytes.length > 32 || entropyBytes.length % 4 != 0) {
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
