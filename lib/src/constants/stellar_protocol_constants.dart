// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Protocol-specific constants defined by the Stellar protocol and CAPs
/// (Core Advancement Proposals).
///
/// This file contains all Stellar protocol constants including strkey encoding
/// lengths, version bytes, cryptographic key sizes, asset code lengths, and
/// transaction limits. These constants are derived from the official Stellar
/// protocol specifications and should not be modified without corresponding
/// protocol changes.
///
/// References:
/// - Stellar Protocol: https://github.com/stellar/stellar-protocol
/// - SEP-0023 (Strkeys): https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md
/// - CAP specifications: https://github.com/stellar/stellar-protocol/tree/master/core
///
/// Note: This class cannot be instantiated. All constants are static and
/// should be accessed directly via the class name.
final class StellarProtocolConstants {
  // Private constructor to prevent instantiation
  StellarProtocolConstants._();

  // ============================================================================
  // STRKEY ENCODING LENGTHS
  // ============================================================================
  // Strkey is the base32 encoding format used for Stellar addresses and keys.
  // Format: version byte + payload + 2-byte CRC16 checksum, then base32 encoded
  // Reference: SEP-0023 https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md

  /// Length of a Stellar account ID in strkey format (G...).
  ///
  /// Format: 1 byte version + 32 bytes public key + 2 bytes checksum = 35 bytes
  /// Base32 encoded: ceil(35 * 8 / 5) = 56 characters
  ///
  /// Example: GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H
  static const int STRKEY_ACCOUNT_ID_LENGTH = 56;

  /// Length of a muxed account ID in strkey format (M...).
  ///
  /// Format: 1 byte version + 32 bytes public key + 8 bytes ID + 2 bytes checksum = 43 bytes
  /// Base32 encoded: ceil(43 * 8 / 5) = 69 characters
  ///
  /// Muxed accounts allow multiple virtual accounts to share the same underlying
  /// Stellar account. Defined in CAP-0027.
  ///
  /// Example: MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK
  static const int STRKEY_MUXED_ACCOUNT_ID_LENGTH = 69;

  /// Length of a secret seed in strkey format (S...).
  ///
  /// Format: 1 byte version + 32 bytes seed + 2 bytes checksum = 35 bytes
  /// Base32 encoded: ceil(35 * 8 / 5) = 56 characters
  ///
  /// Example: SBZVMB6XETHG5YZ6RZRJNVOQX4YQZ7XTTAEGVHQVBP2FQXVP4TWGIMSU
  static const int STRKEY_SECRET_SEED_LENGTH = 56;

  /// Length of a pre-authorized transaction hash in strkey format (T...).
  ///
  /// Format: 1 byte version + 32 bytes hash + 2 bytes checksum = 35 bytes
  /// Base32 encoded: ceil(35 * 8 / 5) = 56 characters
  ///
  /// Pre-auth transaction signers allow a transaction to be signed in advance.
  ///
  /// Example: TAQCSRX2RIDJNHFIFHWD63X7D7D6TRT5Y2S6E3TEMXTG5W3OECHZ2OG4
  static const int STRKEY_PRE_AUTH_TX_LENGTH = 56;

  /// Length of a SHA256 hash in strkey format (X...).
  ///
  /// Format: 1 byte version + 32 bytes hash + 2 bytes checksum = 35 bytes
  /// Base32 encoded: ceil(35 * 8 / 5) = 56 characters
  ///
  /// Example: XDNA2V62PVEFBZ74CDJKTUHLY4Y7PL5UAV2MAM4VWF6USFE3SH235FXL
  static const int STRKEY_SHA256_HASH_LENGTH = 56;

  /// Length of a contract ID in strkey format (C...).
  ///
  /// Format: 1 byte version + 32 bytes contract ID + 2 bytes checksum = 35 bytes
  /// Base32 encoded: ceil(35 * 8 / 5) = 56 characters
  ///
  /// Contract IDs are used in Soroban smart contracts. Defined in CAP-0046.
  ///
  /// Example: CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA
  static const int STRKEY_CONTRACT_ID_LENGTH = 56;

  /// Length of a claimable balance ID in strkey format (B...).
  ///
  /// Format: 1 byte version + 32 bytes balance ID + 2 bytes checksum = 35 bytes
  /// Base32 encoded: ceil(35 * 8 / 5) = 56 characters, but actual is 58 due to
  /// encoding specifics with the balance ID structure.
  ///
  /// Claimable balances are defined in CAP-0023.
  ///
  /// Example: 00000000178826fbfe339e1f5c53417c6fedfe2c05e8bec14303143ec46b38981b09c3f9
  static const int STRKEY_CLAIMABLE_BALANCE_LENGTH = 58;

  /// Length of a liquidity pool ID in strkey format (L...).
  ///
  /// Format: 1 byte version + 32 bytes pool ID + 2 bytes checksum = 35 bytes
  /// Base32 encoded: ceil(35 * 8 / 5) = 56 characters
  ///
  /// Liquidity pools are defined in CAP-0038.
  ///
  /// Example: LAQCSRX2RIDJNHFIFHWD63X7D7D6TRT5Y2S6E3TEMXTG5W3OECHZ2OG4
  static const int STRKEY_LIQUIDITY_POOL_LENGTH = 56;

  /// Minimum length of a signed payload in strkey format (P...).
  ///
  /// Format: 1 byte version + 32 bytes public key + 4 bytes length prefix + 4 bytes min payload + 2 bytes checksum = 43 bytes
  /// Base32 encoded minimum: ceil(43 * 8 / 5) = 69 characters
  ///
  /// Signed payloads are defined in CAP-0040.
  ///
  /// Example: PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM
  static const int STRKEY_SIGNED_PAYLOAD_MIN_LENGTH = 69;

  /// Maximum length of a signed payload in strkey format (P...).
  ///
  /// Format: 1 byte version + 32 bytes public key + 64 bytes max payload + 2 bytes checksum = 99 bytes
  /// Base32 encoded: ceil(99 * 8 / 5) = 159 characters (actual may vary slightly)
  ///
  /// The payload can be up to 64 bytes as defined in CAP-0040.
  static const int STRKEY_SIGNED_PAYLOAD_MAX_LENGTH = 165;

  // ============================================================================
  // VERSION BYTES FOR STRKEY ENCODING
  // ============================================================================
  // Version bytes determine the strkey prefix and type.
  // The byte value is calculated as: character_value << 3
  // This aligns with the base32 encoding scheme used by Stellar.
  //
  // Reference: SEP-0023 https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md

  /// Version byte for account ID (public key) strkey encoding.
  ///
  /// Results in 'G' prefix: 6 << 3 = 48 (0x30)
  ///
  /// Example: GBRPYHIL2CI3FNQ4BXLFMNDLFJUNPU2HY3ZMFSHONUCEOASW7QC7OX2H
  static const int VERSION_BYTE_ACCOUNT_ID = 6 << 3;

  /// Version byte for muxed account strkey encoding.
  ///
  /// Results in 'M' prefix: 12 << 3 = 96 (0x60)
  ///
  /// Example: MA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJVAAAAAAAAAAAAAJLK
  static const int VERSION_BYTE_MUXED_ACCOUNT = 12 << 3;

  /// Version byte for secret seed strkey encoding.
  ///
  /// Results in 'S' prefix: 18 << 3 = 144 (0x90)
  ///
  /// Example: SBZVMB6XETHG5YZ6RZRJNVOQX4YQZ7XTTAEGVHQVBP2FQXVP4TWGIMSU
  static const int VERSION_BYTE_SEED = 18 << 3;

  /// Version byte for pre-authorized transaction hash strkey encoding.
  ///
  /// Results in 'T' prefix: 19 << 3 = 152 (0x98)
  ///
  /// Example: TAQCSRX2RIDJNHFIFHWD63X7D7D6TRT5Y2S6E3TEMXTG5W3OECHZ2OG4
  static const int VERSION_BYTE_PRE_AUTH_TX = 19 << 3;

  /// Version byte for SHA256 hash strkey encoding.
  ///
  /// Results in 'X' prefix: 23 << 3 = 184 (0xB8)
  ///
  /// Example: XDNA2V62PVEFBZ74CDJKTUHLY4Y7PL5UAV2MAM4VWF6USFE3SH235FXL
  static const int VERSION_BYTE_SHA256_HASH = 23 << 3;

  /// Version byte for signed payload strkey encoding.
  ///
  /// Results in 'P' prefix: 15 << 3 = 120 (0x78)
  ///
  /// Defined in CAP-0040 for Ed25519 signed payloads.
  ///
  /// Example: PA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUAAAAAOQCAQDAQCQMBYIBEFAWDANBYHRAEISCMKBKFQXDAMRUGY4DUPB6IBZGM
  static const int VERSION_BYTE_SIGNED_PAYLOAD = 15 << 3;

  /// Version byte for contract ID strkey encoding.
  ///
  /// Results in 'C' prefix: 2 << 3 = 16 (0x10)
  ///
  /// Used for Soroban smart contract addresses. Defined in CAP-0046.
  ///
  /// Example: CA7QYNF7SOWQ3GLR2BGMZEHXAVIRZA4KVWLTJJFC7MGXUA74P7UJUWDA
  static const int VERSION_BYTE_CONTRACT_ID = 2 << 3;

  /// Version byte for liquidity pool ID strkey encoding.
  ///
  /// Results in 'L' prefix: 11 << 3 = 88 (0x58)
  ///
  /// Used for AMM liquidity pool identifiers. Defined in CAP-0038.
  ///
  /// Example: LAQCSRX2RIDJNHFIFHWD63X7D7D6TRT5Y2S6E3TEMXTG5W3OECHZ2OG4
  static const int VERSION_BYTE_LIQUIDITY_POOL = 11 << 3;

  /// Version byte for claimable balance ID strkey encoding.
  ///
  /// Results in 'B' prefix: 1 << 3 = 8 (0x08)
  ///
  /// Used for claimable balance identifiers. Defined in CAP-0023.
  static const int VERSION_BYTE_CLAIMABLE_BALANCE = 1 << 3;

  // ============================================================================
  // CRYPTOGRAPHIC CONSTANTS
  // ============================================================================
  // Constants related to Ed25519 cryptography and hashing algorithms.
  //
  // Reference: Ed25519 specification https://ed25519.cr.yp.to/

  /// Length of an Ed25519 public key in bytes.
  ///
  /// Ed25519 public keys are always 32 bytes (256 bits).
  static const int ED25519_PUBLIC_KEY_LENGTH_BYTES = 32;

  /// Length of an Ed25519 private key (seed) in bytes.
  ///
  /// Ed25519 private keys (seeds) are always 32 bytes (256 bits).
  static const int ED25519_PRIVATE_KEY_LENGTH_BYTES = 32;

  /// Length of an Ed25519 signature in bytes.
  ///
  /// Ed25519 signatures are always 64 bytes (512 bits).
  static const int ED25519_SIGNATURE_LENGTH_BYTES = 64;

  /// Length of a SHA256 hash in bytes.
  ///
  /// SHA256 hashes are always 32 bytes (256 bits).
  static const int SHA256_HASH_LENGTH_BYTES = 32;

  /// Length of a signature hint in bytes.
  ///
  /// Signature hints are the last 4 bytes of the signer's public key,
  /// used to quickly identify which key was used for signing.
  static const int SIGNATURE_HINT_LENGTH_BYTES = 4;

  /// Length of the muxed account ID field in bytes.
  ///
  /// Muxed accounts include an 8-byte ID field for virtual account multiplexing.
  /// Defined in CAP-0027.
  static const int MUXED_ACCOUNT_ID_LENGTH_BYTES = 8;

  /// Length of decoded muxed account data in bytes.
  ///
  /// Consists of Ed25519 public key (32 bytes) + muxed ID (8 bytes) = 40 bytes total.
  /// Defined in CAP-0027.
  static const int MUXED_ACCOUNT_DECODED_LENGTH = ED25519_PUBLIC_KEY_LENGTH_BYTES + MUXED_ACCOUNT_ID_LENGTH_BYTES;

  // ============================================================================
  // ASSET CODE LENGTHS
  // ============================================================================
  // Asset codes can be 1-4 characters (AlphaNum4) or 5-12 characters (AlphaNum12).
  //
  // Reference: Stellar Protocol - Asset specification

  /// Minimum length for any asset code.
  ///
  /// Asset codes must be at least 1 character long.
  static const int ASSET_CODE_MIN_LENGTH = 1;

  /// Maximum length for AlphaNum4 asset codes.
  ///
  /// AlphaNum4 assets can have codes from 1 to 4 characters.
  ///
  /// Example: USD, BTC, EUR
  static const int ASSET_CODE_ALPHANUMERIC_4_MAX_LENGTH = 4;

  /// Minimum length for AlphaNum12 asset codes.
  ///
  /// AlphaNum12 assets must have codes from 5 to 12 characters.
  /// Any asset code longer than 4 characters uses AlphaNum12 encoding.
  ///
  /// Example: USDC, EURT
  static const int ASSET_CODE_ALPHANUMERIC_12_MIN_LENGTH = 5;

  /// Maximum length for AlphaNum12 asset codes.
  ///
  /// AlphaNum12 assets can have codes from 5 to 12 characters.
  ///
  /// Example: LONGASSET12
  static const int ASSET_CODE_ALPHANUMERIC_12_MAX_LENGTH = 12;

  // ============================================================================
  // TRANSACTION LIMITS
  // ============================================================================
  // Limits on transaction structure as defined by the Stellar protocol.
  //
  // Reference: stellar-core source code and XDR definitions

  /// Maximum number of operations allowed in a single transaction.
  ///
  /// Stellar transactions can contain up to 100 operations. This limit is
  /// enforced by the protocol to prevent transactions from consuming too
  /// many resources during validation and execution.
  ///
  /// Reference: XDR Constants.MAX_OPS_PER_TX
  static const int MAX_OPERATIONS_PER_TRANSACTION = 100;

  /// Maximum length for an account's home domain string.
  ///
  /// The home domain is used for federation and can be up to 32 characters.
  /// This corresponds to the XDR string32 type.
  ///
  /// Reference: XDR type string32 and federation specification
  static const int HOME_DOMAIN_MAX_LENGTH = 32;

  // ============================================================================
  // LIQUIDITY POOL CONSTANTS
  // ============================================================================
  // Constants related to Automated Market Maker (AMM) liquidity pools.
  //
  // Reference: CAP-0038 (Automated Market Makers)

  /// Liquidity pool fee in basis points (protocol version 18+).
  ///
  /// Fee is 30 basis points (0.30%). This is the protocol-defined fee for
  /// liquidity pool trades.
  ///
  /// Reference: XDR Constants.LIQUIDITY_POOL_FEE_V18
  static const int LIQUIDITY_POOL_FEE_V18 = 30;

  // ============================================================================
  // SIGNED PAYLOAD CONSTANTS
  // ============================================================================
  // Constants related to signed payloads as defined in CAP-0040.
  //
  // Reference: CAP-0040 (Signed Payload Signer)

  /// Maximum length of a signed payload.
  ///
  /// Signed payloads in Soroban can be up to 64 bytes.
  ///
  /// Reference: CAP-0040
  static const int SIGNED_PAYLOAD_MAX_LENGTH_BYTES = 64;

  // ============================================================================
  // STRING FORMATTING CONSTANTS
  // ============================================================================
  // Constants related to string representation and formatting.

  /// Length of hexadecimal string representation for 256-bit values.
  ///
  /// A 256-bit value (32 bytes) requires 64 hexadecimal characters when
  /// represented as a hex string (2 hex chars per byte).
  ///
  /// Used for padding hex strings in XDR encoding/decoding operations.
  ///
  /// Formula: 256 bits / 8 bits per byte * 2 hex chars per byte = 64 chars
  static const int HEX_STRING_256BIT_LENGTH = 64;
}
