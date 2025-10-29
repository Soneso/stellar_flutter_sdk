import 'mnemonic_utils.dart';
import '../../key_pair.dart';
import 'dart:typed_data';
import "dart:convert";
import 'package:pointycastle/export.dart';
import 'word_list.dart';
import '../../constants/mnemonic_constants.dart';

const LANGUAGE_ENGLISH = 'english';
const LANGUAGE_CHINESE_SIMPLIFIED = 'chinese simplified';
const LANGUAGE_CHINESE_TRADITIONAL = 'chinese traditional';
const LANGUAGE_FRENCH = 'french';
const LANGUAGE_ITALIAN = 'italian';
const LANGUAGE_JAPANESE = 'japanese';
const LANGUAGE_KOREAN = 'korean';
const LANGUAGE_SPANISH = 'spanish';
const LANGUAGE_MALAY = 'malay';

class Wallet {
  Uint8List _seed;
  Wallet._init(this._seed);

  /// Generates a 12-word mnemonic depending on [language], defaults to [LANGUAGE_ENGLISH].
  static Future<String> generate12WordsMnemonic(
      {String language = LANGUAGE_ENGLISH}) async {
    return generate(MnemonicConstants.MNEMONIC_ENTROPY_BITS_12_WORDS, language: language);
  }
  
  /// Generates an 18-word mnemonic depending on [language], defaults to [LANGUAGE_ENGLISH].
  static Future<String> generate18WordsMnemonic(
      {String language = LANGUAGE_ENGLISH}) async {
    return generate(MnemonicConstants.MNEMONIC_ENTROPY_BITS_18_WORDS, language: language);
  }

  /// Generates a 24-word mnemonic depending on [language], defaults to [LANGUAGE_ENGLISH].
  static Future<String> generate24WordsMnemonic(
      {String language = LANGUAGE_ENGLISH}) async {
    return generate(MnemonicConstants.MNEMONIC_ENTROPY_BITS_24_WORDS, language: language);
  }

  static Future<String> generate(int strength,
      {String language = LANGUAGE_ENGLISH}) async {
    return generateMnemonic(
        strength: strength, wordList: _wordListForLanguage(language));
  }

  /// Validates a mnemonic depending on [language], defaults to [LANGUAGE_ENGLISH].
  static Future<bool> validate(String mnemonic,
      {String language = LANGUAGE_ENGLISH}) async {
    return validateMnemonic(mnemonic, _wordListForLanguage(language));
  }

  static Future<Wallet> from(String mnemonic,
      {String language = LANGUAGE_ENGLISH, String passphrase = ''}) async {
    if (!(await validate(mnemonic, language: language))) {
      throw ArgumentError('Invalid mnemonic');
    }
    return Wallet._init(mnemonicToSeed(mnemonic, passphrase: passphrase));
  }

  static Future<Wallet> fromBip39HexSeed(String hex) async {
    HexDecoder decoder = HexDecoder();
    return Wallet._init(Uint8List.fromList(decoder.convert(hex)));
  }

  static Future<Wallet> fromBip39Seed(Uint8List seed) async {
    return Wallet._init(seed);
  }

  Future<KeyPair> getKeyPair({int index = 0}) async {
    final key = this._derivePath("m/44'/148'/$index'");
    return KeyPair.fromSecretSeedList(key.sublist(0, MnemonicConstants.WALLET_DERIVED_KEY_BYTES));
  }

  Future<String> getAccountId({int index = 0}) async {
    return (await this.getKeyPair(index: index)).accountId;
  }

  static List<String> _wordListForLanguage(String language) {
    switch (language) {
      case LANGUAGE_ENGLISH:
        return WordList.englishWords();
      case LANGUAGE_CHINESE_SIMPLIFIED:
        return WordList.chineseSimplifiedWords();
      case LANGUAGE_CHINESE_TRADITIONAL:
        return WordList.chineseTraditionalWords();
      case LANGUAGE_FRENCH:
        return WordList.frenchWords();
      case LANGUAGE_ITALIAN:
        return WordList.italianWords();
      case LANGUAGE_JAPANESE:
        return WordList.japaneseWords();
      case LANGUAGE_KOREAN:
        return WordList.koreanWords();
      case LANGUAGE_SPANISH:
        return WordList.spanishWords();
      case LANGUAGE_MALAY:
        return WordList.malayWords();
      default:
        return WordList.englishWords();
    }
  }

  Uint8List _derive(Uint8List seed, Uint8List chainCode, int index) {
    var y = MnemonicConstants.BIP32_HARDENED_OFFSET + index;
    Uint8List data = new Uint8List(MnemonicConstants.HD_DERIVATION_DATA_LENGTH);
    data[0] = 0x00;
    data.setRange(1, MnemonicConstants.WALLET_DERIVED_KEY_BYTES + 1, seed);
    data.buffer.asByteData().setUint32(MnemonicConstants.WALLET_DERIVED_KEY_BYTES + 1, y);
    var output = _hMacSHA512(chainCode, data);
    return output;
  }

  Uint8List _derivePath(String path) {
    final regex = new RegExp(r"^(m\/)?(\d+'?\/)*\d+'?$");
    if (!regex.hasMatch(path)) throw new ArgumentError("Expected BIP32 Path");
    List<String> splitPath = path.split("/");
    if (splitPath[0] == "m") {
      splitPath = splitPath.sublist(1);
    }
    final seed = _hMacSHA512(
        Uint8List.fromList(utf8.encode("ed25519 seed")), this._seed);
    Uint8List result = splitPath.fold(seed, (Uint8List prev, String indexStr) {
      int index;
      if (indexStr.substring(indexStr.length - 1) == "'") {
        index = int.parse(indexStr.substring(0, indexStr.length - 1));
      } else {
        index = int.parse(indexStr);
      }
      return _derive(
          prev.sublist(0, MnemonicConstants.WALLET_DERIVED_KEY_BYTES),
          prev.sublist(MnemonicConstants.WALLET_DERIVED_KEY_BYTES),
          index);
    });
    return result;
  }

  Uint8List _hMacSHA512(Uint8List key, Uint8List data) {
    final _tmp = new HMac(new SHA512Digest(), MnemonicConstants.PBKDF2_BLOCK_LENGTH_BYTES)..init(new KeyParameter(key));
    return _tmp.process(data);
  }
}
