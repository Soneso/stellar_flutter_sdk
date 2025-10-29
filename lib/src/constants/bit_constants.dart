// Copyright 2025 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

/// Bit manipulation and masking constants for binary operations.
///
/// This file contains constants used for low-level bit manipulation,
/// byte masking, and binary data processing operations throughout the SDK.
/// These constants are primarily used in XDR encoding/decoding and
/// cryptographic operations where precise bit-level control is required.
///
/// Note: This class cannot be instantiated. All constants are static and
/// should be accessed directly via the class name.
final class BitConstants {
  // Private constructor to prevent instantiation
  BitConstants._();

  // ============================================================================
  // BYTE MASKING CONSTANTS
  // ============================================================================
  // Constants used for extracting and manipulating byte values.

  /// Byte mask for extracting lower 8 bits.
  ///
  /// Used to isolate the least significant 8 bits (one byte) from an integer
  /// value. Common in byte extraction and bit manipulation operations.
  ///
  /// Binary: 0b11111111
  /// Hexadecimal: 0xFF
  /// Decimal: 255
  static const int BYTE_MASK = 0xFF;

  /// Sign bit mask for byte operations.
  ///
  /// Used to check or manipulate the most significant bit (sign bit) of a byte.
  /// This bit indicates whether a signed byte value is negative (1) or
  /// positive/zero (0).
  ///
  /// Binary: 0b10000000
  /// Hexadecimal: 0x80
  /// Decimal: 128
  static const int SIGN_BIT_MASK = 0x80;

  // ============================================================================
  // WORD AND MULTI-BYTE MASKING CONSTANTS
  // ============================================================================
  // Constants used for extracting larger bit ranges.

  /// 64-bit unsigned integer mask.
  ///
  /// Used to extract or mask the full range of a 64-bit unsigned integer.
  /// Commonly used when handling unsigned int64 values in Dart, which uses
  /// signed integers internally.
  ///
  /// Binary: 16 consecutive 'F's in hexadecimal
  /// Hexadecimal: 0xFFFFFFFFFFFFFFFF
  /// Decimal: 18446744073709551615
  static const int UINT64_MASK = 0xFFFFFFFFFFFFFFFF;

  // ============================================================================
  // BIT SHIFT CONSTANTS
  // ============================================================================
  // Constants defining common bit shift amounts.

  /// Number of bits in a byte.
  ///
  /// Used in shift operations when converting between bytes and larger
  /// integer types. Each shift by this amount moves to the next byte position.
  ///
  /// Default: 8 bits
  static const int BITS_PER_BYTE = 8;

  /// Number of bytes in a 64-bit integer.
  ///
  /// Used when converting between int64 values and byte arrays in
  /// big-endian or little-endian format.
  ///
  /// Default: 8 bytes
  static const int BYTES_PER_INT64 = 8;

  /// Number of bytes in a 128-bit integer.
  ///
  /// Used when working with 128-bit integers (i128/u128) in Soroban
  /// smart contracts, particularly in conversion operations.
  ///
  /// Default: 16 bytes
  static const int BYTES_PER_INT128 = 16;

  /// Number of bytes in a 256-bit integer.
  ///
  /// Used when working with 256-bit integers (i256/u256) in Soroban
  /// smart contracts, particularly in conversion operations.
  ///
  /// Default: 32 bytes
  static const int BYTES_PER_INT256 = 32;

  // ============================================================================
  // PADDING FILL VALUES
  // ============================================================================
  // Values used for padding and sign extension in binary operations.

  /// Zero byte fill value.
  ///
  /// Used for padding positive numbers or zero-filling byte arrays.
  ///
  /// Hexadecimal: 0x00
  /// Decimal: 0
  static const int ZERO_FILL = 0x00;
}
