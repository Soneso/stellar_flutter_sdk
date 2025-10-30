// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// BIP39 mnemonic and wallet generation constants for SEP-0005 compliance.
///
/// This file contains constants used for mnemonic phrase generation,
/// validation, and wallet derivation according to BIP39 and SEP-0005
/// specifications. These constants define entropy sizes, checksum calculations,
/// PBKDF2 parameters, and other values required for deterministic wallet
/// generation.
///
/// References:
/// - BIP39: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
/// - SEP-0005: https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0005.md
///
/// Note: This class cannot be instantiated. All constants are static and
/// should be accessed directly via the class name.
final class MnemonicConstants {
  // Private constructor to prevent instantiation
  MnemonicConstants._();

  // ============================================================================
  // ENTROPY SIZE CONSTANTS (BIP39)
  // ============================================================================
  // Entropy is the random data used to generate mnemonic phrases.
  // The entropy size determines the number of words in the mnemonic.
  //
  // Formula: number_of_words = (entropy_bits + checksum_bits) / 11
  // Where: checksum_bits = entropy_bits / 32

  /// Entropy size in bits for a 12-word mnemonic phrase.
  ///
  /// 128 bits of entropy generates 4 bits of checksum, resulting in
  /// (128 + 4) / 11 = 12 words.
  ///
  /// Reference: BIP39 specification
  static const int MNEMONIC_ENTROPY_BITS_12_WORDS = 128;

  /// Entropy size in bits for an 18-word mnemonic phrase.
  ///
  /// 192 bits of entropy generates 6 bits of checksum, resulting in
  /// (192 + 6) / 11 = 18 words.
  ///
  /// Reference: BIP39 specification
  static const int MNEMONIC_ENTROPY_BITS_18_WORDS = 192;

  /// Entropy size in bits for a 24-word mnemonic phrase.
  ///
  /// 256 bits of entropy generates 8 bits of checksum, resulting in
  /// (256 + 8) / 11 = 24 words.
  ///
  /// Reference: BIP39 specification
  static const int MNEMONIC_ENTROPY_BITS_24_WORDS = 256;

  /// Minimum entropy size in bytes.
  ///
  /// Corresponds to 128 bits (16 bytes), the minimum for BIP39 mnemonics.
  ///
  /// Reference: BIP39 specification
  static const int MNEMONIC_MIN_ENTROPY_BYTES = 16;

  /// Maximum entropy size in bytes.
  ///
  /// Corresponds to 256 bits (32 bytes), the maximum for BIP39 mnemonics.
  ///
  /// Reference: BIP39 specification
  static const int MNEMONIC_MAX_ENTROPY_BYTES = 32;

  /// Entropy size must be a multiple of this value in bytes.
  ///
  /// BIP39 requires entropy to be a multiple of 4 bytes (32 bits) to ensure
  /// proper checksum generation and word count alignment.
  ///
  /// Reference: BIP39 specification
  static const int MNEMONIC_ENTROPY_MULTIPLE_BYTES = 4;

  /// Entropy size must be a multiple of this value in bits.
  ///
  /// BIP39 requires entropy to be a multiple of 32 bits to ensure
  /// proper checksum generation.
  ///
  /// Reference: BIP39 specification
  static const int MNEMONIC_ENTROPY_MULTIPLE_BITS = 32;

  // ============================================================================
  // CHECKSUM CONSTANTS
  // ============================================================================
  // Checksums are derived from the SHA256 hash of the entropy and appended
  // to create the final binary string that maps to mnemonic words.

  /// Divisor for calculating checksum bits from entropy bits.
  ///
  /// The checksum is calculated as: CS = ENT / 32
  /// Where ENT is the entropy size in bits.
  ///
  /// Example:
  /// - 128 bits entropy → 4 bits checksum
  /// - 256 bits entropy → 8 bits checksum
  ///
  /// Reference: BIP39 specification
  static const int CHECKSUM_BITS_PER_32_ENT_BITS = 32;

  /// Divisor for calculating the divider index in mnemonic validation.
  ///
  /// When validating a mnemonic, the binary representation is split at:
  /// divider_index = (total_bits / 33) * 32
  ///
  /// This separates the entropy bits from the checksum bits.
  ///
  /// Reference: BIP39 specification (ENT + CS = ENT + ENT/32 = ENT * 33/32)
  static const int MNEMONIC_DIVIDER_RATIO = 33;

  // ============================================================================
  // PBKDF2 KEY DERIVATION CONSTANTS
  // ============================================================================
  // PBKDF2 (Password-Based Key Derivation Function 2) is used to convert
  // the mnemonic phrase into a binary seed for wallet generation.

  /// PBKDF2 block length in bytes for HMAC-SHA512.
  ///
  /// SHA512 has a block size of 128 bytes (1024 bits). This is used by
  /// the PBKDF2 algorithm for key derivation from mnemonic phrases.
  ///
  /// Reference: RFC 2898 (PKCS #5), SHA512 specification
  static const int PBKDF2_BLOCK_LENGTH_BYTES = 128;

  /// PBKDF2 iteration count for mnemonic-to-seed derivation.
  ///
  /// BIP39 specifies 2048 iterations of PBKDF2-HMAC-SHA512 for deriving
  /// the 512-bit seed from the mnemonic phrase and optional passphrase.
  ///
  /// This provides a balance between security and performance.
  ///
  /// Reference: BIP39 specification
  static const int PBKDF2_ITERATION_COUNT = 2048;

  /// PBKDF2 desired key length in bytes.
  ///
  /// BIP39 produces a 512-bit (64-byte) seed from the mnemonic phrase.
  /// This seed is used as the master seed for BIP32 HD wallet generation.
  ///
  /// Reference: BIP39 specification
  static const int PBKDF2_KEY_LENGTH_BYTES = 64;

  // ============================================================================
  // WALLET DERIVATION CONSTANTS
  // ============================================================================
  // Constants related to HD wallet key derivation from BIP39 seeds.

  /// Number of bytes to extract from derived key for Ed25519 seed.
  ///
  /// When deriving a key pair from an HD wallet path, only the first
  /// 32 bytes of the derived key are used as the Ed25519 private key seed.
  ///
  /// Reference: SEP-0005, Ed25519 specification
  static const int WALLET_DERIVED_KEY_BYTES = 32;

  /// Offset added to create hardened derivation indices.
  ///
  /// In BIP32 HD wallets, indices >= 2^31 are "hardened". This constant
  /// is added to the index to create a hardened derivation path.
  ///
  /// Value: 2147483648 (2^31)
  ///
  /// Reference: BIP32 specification
  static const int BIP32_HARDENED_OFFSET = 2147483648;

  /// Length of data buffer for HD key derivation.
  ///
  /// Format: 1 byte (0x00) + 32 bytes seed + 4 bytes index = 37 bytes
  ///
  /// Reference: BIP32 specification for Ed25519
  static const int HD_DERIVATION_DATA_LENGTH = 37;

  // ============================================================================
  // RANDOM NUMBER GENERATION CONSTANTS
  // ============================================================================
  // Constants for secure random number generation.

  /// Maximum value for random byte generation (exclusive).
  ///
  /// When generating random bytes, this is the upper bound for the
  /// Random.nextInt() call. A full byte ranges from 0-255 (inclusive),
  /// so we use 256 as the exclusive upper bound.
  ///
  /// IMPORTANT: Using 255 instead of 256 would skip the value 255 and
  /// introduce bias into the random number generation.
  static const int RANDOM_BYTE_MAX_VALUE = 256;
}
