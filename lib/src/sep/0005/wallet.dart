import 'mnemonic_utils.dart';
import '../../key_pair.dart';
import 'dart:typed_data';
import "dart:convert";
import 'package:pointycastle/export.dart';
import 'word_list.dart';
import '../../constants/mnemonic_constants.dart';

/// Language option for English mnemonic word list.
const LANGUAGE_ENGLISH = 'english';

/// Language option for Chinese Simplified mnemonic word list.
const LANGUAGE_CHINESE_SIMPLIFIED = 'chinese simplified';

/// Language option for Chinese Traditional mnemonic word list.
const LANGUAGE_CHINESE_TRADITIONAL = 'chinese traditional';

/// Language option for French mnemonic word list.
const LANGUAGE_FRENCH = 'french';

/// Language option for Italian mnemonic word list.
const LANGUAGE_ITALIAN = 'italian';

/// Language option for Japanese mnemonic word list.
const LANGUAGE_JAPANESE = 'japanese';

/// Language option for Korean mnemonic word list.
const LANGUAGE_KOREAN = 'korean';

/// Language option for Spanish mnemonic word list.
const LANGUAGE_SPANISH = 'spanish';

/// Language option for Malay mnemonic word list.
const LANGUAGE_MALAY = 'malay';

/// Implements SEP-0005 Key Derivation Methods for Stellar Keys.
///
/// This implementation supports SEP-0005 as updated on 2020-06-16. It provides
/// a hierarchical deterministic wallet that generates Stellar keypairs from a
/// BIP-39 mnemonic phrase following the Stellar-specific derivation path
/// `m/44'/148'/x'` where:
/// - 44' is the BIP-44 purpose (hardened)
/// - 148' is the Stellar coin type (hardened)
/// - x' is the account index (hardened)
///
/// The wallet supports:
/// - BIP-39 mnemonic generation in multiple languages
/// - Mnemonic validation with checksum verification
/// - Hierarchical deterministic key derivation (SLIP-0010 for Ed25519)
/// - Ed25519 keypair generation for Stellar accounts
///
/// Protocol specification:
/// - [SEP-0005](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md)
///
/// Security considerations:
/// - Store mnemonics securely and never expose them
/// - Use strong random number generation for mnemonic creation
/// - Validate mnemonics before use to prevent invalid seed usage
/// - Consider using passphrases for additional security
///
/// Example:
/// ```dart
/// // Generate a new 24-word mnemonic
/// String mnemonic = await Wallet.generate24WordsMnemonic();
///
/// // Create wallet from mnemonic
/// Wallet wallet = await Wallet.from(mnemonic);
///
/// // Derive keypairs for multiple accounts
/// KeyPair account0 = await wallet.getKeyPair(index: 0);
/// KeyPair account1 = await wallet.getKeyPair(index: 1);
///
/// // Get account ID without full keypair
/// String accountId = await wallet.getAccountId(index: 0);
/// ```
///
/// See also:
/// - [KeyPair] for working with Stellar keypairs
/// - [BIP-39 Specification](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
/// - [BIP-32 Specification](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)
class Wallet {
  Uint8List _seed;
  Wallet._init(this._seed);

  /// Generates a 12-word BIP-39 mnemonic phrase.
  ///
  /// Creates a mnemonic with 128 bits of entropy, resulting in 12 words.
  /// This provides adequate security for most use cases.
  ///
  /// Parameters:
  /// - [language]: The language for the word list (default: [LANGUAGE_ENGLISH])
  ///
  /// Returns: A space-separated string of 12 mnemonic words
  ///
  /// Example:
  /// ```dart
  /// String mnemonic = await Wallet.generate12WordsMnemonic();
  /// // Output: "witch collapse practice feed shame open despair creek road again ice least"
  /// ```
  static Future<String> generate12WordsMnemonic(
      {String language = LANGUAGE_ENGLISH}) async {
    return generate(MnemonicConstants.MNEMONIC_ENTROPY_BITS_12_WORDS, language: language);
  }

  /// Generates an 18-word BIP-39 mnemonic phrase.
  ///
  /// Creates a mnemonic with 192 bits of entropy, resulting in 18 words.
  /// This provides higher security than 12 words.
  ///
  /// Parameters:
  /// - [language]: The language for the word list (default: [LANGUAGE_ENGLISH])
  ///
  /// Returns: A space-separated string of 18 mnemonic words
  static Future<String> generate18WordsMnemonic(
      {String language = LANGUAGE_ENGLISH}) async {
    return generate(MnemonicConstants.MNEMONIC_ENTROPY_BITS_18_WORDS, language: language);
  }

  /// Generates a 24-word BIP-39 mnemonic phrase.
  ///
  /// Creates a mnemonic with 256 bits of entropy, resulting in 24 words.
  /// This provides maximum security and is recommended for high-value accounts.
  ///
  /// Parameters:
  /// - [language]: The language for the word list (default: [LANGUAGE_ENGLISH])
  ///
  /// Returns: A space-separated string of 24 mnemonic words
  ///
  /// Example:
  /// ```dart
  /// String mnemonic = await Wallet.generate24WordsMnemonic();
  /// ```
  static Future<String> generate24WordsMnemonic(
      {String language = LANGUAGE_ENGLISH}) async {
    return generate(MnemonicConstants.MNEMONIC_ENTROPY_BITS_24_WORDS, language: language);
  }

  /// Generates a mnemonic phrase with custom entropy strength.
  ///
  /// Parameters:
  /// - [strength]: The entropy bits (must be multiple of 32, between 128-256)
  /// - [language]: The language for the word list (default: [LANGUAGE_ENGLISH])
  ///
  /// Returns: A space-separated string of mnemonic words
  static Future<String> generate(int strength,
      {String language = LANGUAGE_ENGLISH}) async {
    return generateMnemonic(
        strength: strength, wordList: _wordListForLanguage(language));
  }

  /// Validates a BIP-39 mnemonic phrase.
  ///
  /// Checks if the mnemonic is valid by verifying:
  /// - All words are in the word list
  /// - The checksum is correct
  /// - The word count is valid (12, 15, 18, 21, or 24)
  ///
  /// Parameters:
  /// - [mnemonic]: The mnemonic phrase to validate
  /// - [language]: The language of the word list (default: [LANGUAGE_ENGLISH])
  ///
  /// Returns: true if the mnemonic is valid, false otherwise
  ///
  /// Example:
  /// ```dart
  /// bool isValid = await Wallet.validate(
  ///   "witch collapse practice feed shame open despair creek road again ice least"
  /// );
  /// ```
  static Future<bool> validate(String mnemonic,
      {String language = LANGUAGE_ENGLISH}) async {
    return validateMnemonic(mnemonic, _wordListForLanguage(language));
  }

  /// Creates a wallet from a BIP-39 mnemonic phrase.
  ///
  /// The mnemonic is validated before creating the wallet. An optional passphrase
  /// can be provided for additional security (BIP-39 passphrase extension).
  ///
  /// Parameters:
  /// - [mnemonic]: The BIP-39 mnemonic phrase
  /// - [language]: The language of the word list (default: [LANGUAGE_ENGLISH])
  /// - [passphrase]: Optional passphrase for additional security (default: empty)
  ///
  /// Returns: A [Wallet] instance for key derivation
  ///
  /// Throws:
  /// - [ArgumentError]: If the mnemonic is invalid
  ///
  /// Example:
  /// ```dart
  /// String mnemonic = "witch collapse practice feed shame open despair creek road again ice least";
  /// Wallet wallet = await Wallet.from(mnemonic);
  ///
  /// // With passphrase for additional security
  /// Wallet secureWallet = await Wallet.from(mnemonic, passphrase: "my secret phrase");
  /// ```
  static Future<Wallet> from(String mnemonic,
      {String language = LANGUAGE_ENGLISH, String passphrase = ''}) async {
    if (!(await validate(mnemonic, language: language))) {
      throw ArgumentError('Invalid mnemonic');
    }
    return Wallet._init(mnemonicToSeed(mnemonic, passphrase: passphrase));
  }

  /// Creates a wallet from a BIP-39 seed in hexadecimal format.
  ///
  /// This is useful when you have a pre-computed BIP-39 seed from another source.
  /// BIP-39 seeds are always 512 bits (64 bytes) regardless of mnemonic length.
  ///
  /// Parameters:
  /// - [hex]: The 64-byte seed in hexadecimal format (128 hex characters)
  ///
  /// Returns: A [Wallet] instance for key derivation
  ///
  /// Example:
  /// ```dart
  /// String hexSeed = "ba5ed0fd6c5875f41e61c8..."; // 128 hex chars
  /// Wallet wallet = await Wallet.fromBip39HexSeed(hexSeed);
  /// ```
  static Future<Wallet> fromBip39HexSeed(String hex) async {
    HexDecoder decoder = HexDecoder();
    return Wallet._init(Uint8List.fromList(decoder.convert(hex)));
  }

  /// Creates a wallet from a BIP-39 seed as a byte array.
  ///
  /// BIP-39 seeds are always 512 bits (64 bytes) regardless of the original
  /// mnemonic length (12, 18, or 24 words).
  ///
  /// Parameters:
  /// - [seed]: The 64-byte BIP-39 seed
  ///
  /// Returns: A [Wallet] instance for key derivation
  static Future<Wallet> fromBip39Seed(Uint8List seed) async {
    return Wallet._init(seed);
  }

  /// Derives a Stellar keypair at the specified account index.
  ///
  /// Uses the Stellar derivation path: m/44'/148'/index' where:
  /// - 44' is the BIP-44 purpose
  /// - 148' is the Stellar coin type
  /// - index' is the account index (hardened)
  ///
  /// Parameters:
  /// - [index]: The account index (default: 0)
  ///
  /// Returns: A [KeyPair] for the derived account
  ///
  /// Example:
  /// ```dart
  /// Wallet wallet = await Wallet.from(mnemonic);
  ///
  /// // Derive multiple accounts
  /// KeyPair account0 = await wallet.getKeyPair(index: 0);
  /// KeyPair account1 = await wallet.getKeyPair(index: 1);
  /// KeyPair account2 = await wallet.getKeyPair(index: 2);
  /// ```
  ///
  /// See also:
  /// - [BIP-44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki)
  Future<KeyPair> getKeyPair({int index = 0}) async {
    final key = this._derivePath("m/44'/148'/$index'");
    return KeyPair.fromSecretSeedList(key.sublist(0, MnemonicConstants.WALLET_DERIVED_KEY_BYTES));
  }

  /// Gets the Stellar account ID at the specified index without the full keypair.
  ///
  /// This is more efficient than [getKeyPair] when you only need the account ID.
  ///
  /// Parameters:
  /// - [index]: The account index (default: 0)
  ///
  /// Returns: The Stellar account ID (G... address)
  ///
  /// Example:
  /// ```dart
  /// String accountId = await wallet.getAccountId(index: 0);
  /// print(accountId); // "GDJK..."
  /// ```
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
