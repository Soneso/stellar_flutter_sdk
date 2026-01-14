// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import "dart:convert";
import "dart:typed_data";
import 'util.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_memo.dart';
import 'constants/stellar_protocol_constants.dart';

/// Represents optional extra information attached to Stellar transactions.
///
/// Memos provide a way to attach additional data to transactions for various
/// purposes like payment identification, notes, or references. The interpretation
/// of memo content is application-specific.
///
/// Memo Types:
/// - **MEMO_NONE**: No memo (default, saves space and fees)
/// - **MEMO_TEXT**: UTF-8 text up to 28 bytes (most human-readable)
/// - **MEMO_ID**: 64-bit unsigned integer (for numeric IDs)
/// - **MEMO_HASH**: 32-byte hash (for cryptographic references)
/// - **MEMO_RETURN**: 32-byte hash (for refund transaction references)
///
/// Common use cases:
/// - Customer identification for exchanges and anchors
/// - Invoice or reference numbers for payments
/// - Notes or descriptions for transaction purposes
/// - Refund references when returning payments
/// - Linking on-chain and off-chain data
///
/// Creating memos:
/// ```dart
/// // No memo (default)
/// Memo noMemo = Memo.none();
///
/// // Text memo (max 28 bytes UTF-8)
/// Memo textMemo = Memo.text("Payment for invoice 123");
///
/// // ID memo (numeric identifier)
/// Memo idMemo = Memo.id(BigInt.from(987654321));
///
/// // Hash memo (32 bytes)
/// Uint8List hash = Uint8List.fromList([/* 32 bytes */]);
/// Memo hashMemo = Memo.hash(hash);
///
/// // Hash from hex string
/// Memo hashMemo2 = Memo.hashString("a1b2c3d4e5f6...");
///
/// // Return hash (for refunds)
/// Memo returnMemo = Memo.returnHash(originalTxHash);
/// ```
///
/// Using in transactions:
/// ```dart
/// // Add memo to transaction
/// Transaction transaction = TransactionBuilder(sourceAccount)
///   .addOperation(paymentOp)
///   .addMemo(Memo.text("Invoice 12345"))
///   .build();
///
/// // Check memo type in received transaction
/// if (transaction.memo is MemoText) {
///   MemoText textMemo = transaction.memo as MemoText;
///   print("Memo: ${textMemo.text}");
/// }
/// ```
///
/// Length restrictions:
/// - **MEMO_NONE**: No data
/// - **MEMO_TEXT**: Maximum 28 bytes (UTF-8 encoded, not character count)
/// - **MEMO_ID**: 64-bit unsigned integer (0 to 2^64-1)
/// - **MEMO_HASH**: Exactly 32 bytes (padded if shorter)
/// - **MEMO_RETURN**: Exactly 32 bytes (padded if shorter)
///
/// Important notes:
/// - Text memos are limited by BYTES not characters (UTF-8 encoding)
/// - Multi-byte characters count as multiple bytes
/// - Hash memos are automatically padded to 32 bytes if shorter
/// - MEMO_ID must be positive (non-zero)
/// - Memos increase transaction size and fees slightly
/// - Some services require specific memo types (check their documentation)
///
/// Exchange best practices:
/// ```dart
/// // Exchanges typically use MEMO_ID for customer identification
/// Memo customerMemo = Memo.id(customerAccountNumber);
///
/// // Always include required memos when depositing to exchanges
/// Transaction deposit = TransactionBuilder(sourceAccount)
///   .addOperation(PaymentOperation(...))
///   .addMemo(customerMemo)
///   .build();
/// ```
///
/// Character encoding example:
/// ```dart
/// // ASCII text (1 byte per char) - OK for 28 chars
/// Memo ascii = Memo.text("Invoice 123"); // ~11 bytes, OK
///
/// // UTF-8 multi-byte characters count more
/// Memo emoji = Memo.text("Payment X"); // Multi-byte char example
/// // "Payment " = 8 bytes, X = variable bytes depending on character
///
/// // This will throw MemoTooLongException
/// // Memo tooLong = Memo.text("This is a very long text that exceeds 28 bytes");
/// ```
///
/// See also:
/// - [MemoNone] for no memo
/// - [MemoText] for text memos
/// - [MemoId] for numeric IDs
/// - [MemoHash] for hash references
/// - [MemoReturnHash] for refund references
/// - [TransactionBuilder.addMemo] for attaching memos to transactions
/// - [Stellar developer docs](https://developers.stellar.org)
abstract class Memo {
  /// Creates a MEMO_NONE instance (no memo).
  ///
  /// This is the default memo type when no additional data is needed.
  /// Using no memo saves transaction space and fees.
  ///
  /// Returns: [MemoNone] instance
  ///
  /// Example:
  /// ```dart
  /// Memo memo = Memo.none();
  /// ```
  static MemoNone none() {
    return MemoNone();
  }

  /// Creates a MEMO_TEXT instance with the given text.
  ///
  /// Text memos can contain up to 28 bytes of UTF-8 encoded text.
  /// Note that bytes, not character count, is the limitation.
  ///
  /// Parameters:
  /// - [text] UTF-8 string up to 28 bytes
  ///
  /// Returns: [MemoText] instance
  ///
  /// Throws:
  /// - [MemoTooLongException] If text exceeds 28 bytes when UTF-8 encoded
  ///
  /// Example:
  /// ```dart
  /// Memo memo = Memo.text("Invoice 12345");
  /// ```
  static MemoText text(String text) {
    return MemoText(text);
  }

  /// Creates a MEMO_ID instance with the given numeric ID.
  ///
  /// ID memos are 64-bit unsigned integers commonly used by exchanges
  /// and anchors for customer or transaction identification.
  ///
  /// Parameters:
  /// - [id] Positive 64-bit unsigned integer as BigInt (must be non-zero)
  ///
  /// Returns: [MemoId] instance
  ///
  /// Throws:
  /// - [Exception] If id is zero
  ///
  /// Example:
  /// ```dart
  /// Memo memo = Memo.id(BigInt.from(987654321));
  /// ```
  static MemoId id(BigInt id) {
    return MemoId(id);
  }

  /// Creates a MEMO_HASH instance from a byte array.
  ///
  /// Hash memos contain 32 bytes of data, typically a hash or cryptographic
  /// reference. Arrays shorter than 32 bytes are automatically padded.
  ///
  /// Parameters:
  /// - [bytes] Byte array (max 32 bytes, will be padded if shorter)
  ///
  /// Returns: [MemoHash] instance
  ///
  /// Throws:
  /// - [MemoTooLongException] If bytes exceed 32 bytes
  ///
  /// Example:
  /// ```dart
  /// Uint8List hash = Uint8List(32); // 32-byte hash
  /// Memo memo = Memo.hash(hash);
  /// ```
  static MemoHash hash(Uint8List bytes) {
    return MemoHash(bytes);
  }

  /// Creates a MEMO_HASH instance from a hex-encoded string.
  ///
  /// Convenience method for creating hash memos from hexadecimal strings.
  /// The hex string is decoded to bytes (max 32 bytes).
  ///
  /// Parameters:
  /// - [hexString] Hexadecimal string (max 64 hex characters = 32 bytes)
  ///
  /// Returns: [MemoHash] instance
  ///
  /// Throws:
  /// - [MemoTooLongException] If decoded bytes exceed 32 bytes
  ///
  /// Example:
  /// ```dart
  /// Memo memo = Memo.hashString("a1b2c3d4e5f6...");
  /// ```
  static MemoHash hashString(String hexString) {
    return MemoHash.string(hexString);
  }

  /// Creates a MEMO_RETURN instance from a byte array.
  ///
  /// Return hash memos contain 32 bytes representing the hash of a transaction
  /// being refunded. This helps track refund relationships.
  ///
  /// Parameters:
  /// - [bytes] Byte array (max 32 bytes, will be padded if shorter)
  ///
  /// Returns: [MemoReturnHash] instance
  ///
  /// Throws:
  /// - [MemoTooLongException] If bytes exceed 32 bytes
  ///
  /// Example:
  /// ```dart
  /// Uint8List originalTxHash = Uint8List(32);
  /// Memo memo = Memo.returnHash(originalTxHash);
  /// ```
  static MemoReturnHash returnHash(Uint8List bytes) {
    return MemoReturnHash(bytes);
  }

  /// Creates a MEMO_RETURN instance from a hex-encoded string.
  ///
  /// Convenience method for creating return hash memos from transaction
  /// hash strings. Accepts both uppercase and lowercase hex.
  ///
  /// Parameters:
  /// - [hexString] Hexadecimal string (max 64 hex characters = 32 bytes)
  ///
  /// Returns: [MemoReturnHash] instance
  ///
  /// Throws:
  /// - [MemoTooLongException] If decoded bytes exceed 32 bytes
  ///
  /// Example:
  /// ```dart
  /// String txHash = "a1b2c3d4e5f6..."; // Transaction hash being refunded
  /// Memo memo = Memo.returnHashString(txHash);
  /// ```
  static MemoReturnHash returnHashString(String hexString) {
    // We change to lowercase because we want to decode both: upper cased and lower cased alphabets.
    return MemoReturnHash(Util.hexToBytes(hexString.toLowerCase()));
  }

  /// Deserializes a Memo from its XDR (External Data Representation) format.
  ///
  /// This factory method converts XDR memo data back into the appropriate
  /// Memo subclass instance based on the memo type discriminant.
  ///
  /// Parameters:
  /// - [memo] XDR memo object to deserialize
  ///
  /// Returns: The appropriate Memo subclass instance:
  /// - [MemoNone] for MEMO_NONE
  /// - [MemoText] for MEMO_TEXT
  /// - [MemoId] for MEMO_ID
  /// - [MemoHash] for MEMO_HASH
  /// - [MemoReturnHash] for MEMO_RETURN
  ///
  /// Throws:
  /// - [Exception] If the XDR contains an unknown memo type
  ///
  /// Example:
  /// ```dart
  /// XdrMemo xdrMemo = ...; // From transaction XDR
  /// Memo memo = Memo.fromXdr(xdrMemo);
  ///
  /// // Check memo type
  /// if (memo is MemoText) {
  ///   print("Text memo: ${(memo as MemoText).text}");
  /// }
  /// ```
  ///
  /// See also:
  /// - [toXdr] for serializing memos to XDR format
  static Memo fromXdr(XdrMemo memo) {
    switch (memo.discriminant) {
      case XdrMemoType.MEMO_NONE:
        return none();
      case XdrMemoType.MEMO_ID:
        return id(memo.id!.uint64);
      case XdrMemoType.MEMO_TEXT:
        return text(memo.text!);
      case XdrMemoType.MEMO_HASH:
        return hash(memo.hash!.hash);
      case XdrMemoType.MEMO_RETURN:
        return returnHash(memo.retHash!.hash);
      default:
        throw Exception("Unknown memo type");
    }
  }

  /// Serializes this Memo to its XDR (External Data Representation) format.
  ///
  /// Each memo type implements this method to convert itself to the
  /// corresponding XDR structure used by the Stellar protocol.
  ///
  /// Returns: XdrMemo object representing this memo in binary format
  ///
  /// Example:
  /// ```dart
  /// Memo memo = Memo.text("Invoice 123");
  /// XdrMemo xdrMemo = memo.toXdr();
  /// // Used internally when building transactions
  /// ```
  ///
  /// See also:
  /// - [fromXdr] for deserializing memos from XDR format
  XdrMemo toXdr();

  /// Compares this Memo with another object for equality.
  ///
  /// Two memos are equal if they are of the same type and contain the
  /// same value. The comparison logic varies by memo type:
  /// - [MemoNone] Always equal to other MemoNone instances
  /// - [MemoText] Equal if text strings match
  /// - [MemoId] Equal if ID values match
  /// - [MemoHash] Equal if byte arrays match
  /// - [MemoReturnHash] Equal if byte arrays match
  ///
  /// Parameters:
  /// - [o] Object to compare with
  ///
  /// Returns: true if objects are equal, false otherwise
  ///
  /// Example:
  /// ```dart
  /// Memo memo1 = Memo.text("Invoice 123");
  /// Memo memo2 = Memo.text("Invoice 123");
  /// Memo memo3 = Memo.text("Invoice 456");
  ///
  /// print(memo1 == memo2); // true
  /// print(memo1 == memo3); // false
  /// ```
  bool operator ==(Object o);

  /// Deserializes a Memo from JSON data.
  ///
  /// This factory method creates the appropriate Memo subclass from a JSON
  /// map, typically received from Horizon API responses. The JSON must contain
  /// 'memo_type' and optionally 'memo' fields.
  ///
  /// Parameters:
  /// - [json]: Map containing memo data with keys:
  ///   - 'memo_type': String ('none', 'text', 'id', 'hash', or 'return')
  ///   - 'memo': String value (not required for 'none' type)
  ///
  /// Returns: The appropriate Memo subclass instance:
  /// - [MemoNone] for type 'none'
  /// - [MemoText] for type 'text' (memo contains text string)
  /// - [MemoId] for type 'id' (memo contains numeric string)
  /// - [MemoHash] for type 'hash' (memo contains base64-encoded bytes)
  /// - [MemoReturnHash] for type 'return' (memo contains base64-encoded bytes)
  ///
  /// Throws:
  /// - [Exception]: If memo_type is unknown or invalid
  ///
  /// Example:
  /// ```dart
  /// // From Horizon transaction response
  /// Map<String, dynamic> json = {
  ///   'memo_type': 'text',
  ///   'memo': 'Invoice 123'
  /// };
  /// Memo memo = Memo.fromJson(json);
  /// print(memo is MemoText); // true
  ///
  /// // ID memo
  /// Map<String, dynamic> idJson = {
  ///   'memo_type': 'id',
  ///   'memo': '987654321'
  /// };
  /// Memo idMemo = Memo.fromJson(idJson);
  /// print((idMemo as MemoId).getId()); // 987654321
  ///
  /// // Hash memo (base64-encoded)
  /// Map<String, dynamic> hashJson = {
  ///   'memo_type': 'hash',
  ///   'memo': 'YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY='
  /// };
  /// Memo hashMemo = Memo.fromJson(hashJson);
  /// ```
  ///
  /// See also:
  /// - [fromStrings] for creating memos from separate strings
  factory Memo.fromJson(Map<String, dynamic> json) {
    String memoType = json["memo_type"];
    Memo memo;
    if (memoType == "none") {
      memo = Memo.none();
    } else {
      if (memoType == "text") {
        memo = Memo.text(json["memo"] ?? "");
      } else {
        String memoValue = json["memo"];
        if (memoType == "id") {
          memo = Memo.id(BigInt.parse(memoValue));
        } else if (memoType == "hash") {
          memo = Memo.hash(base64.decode(memoValue));
        } else if (memoType == "return") {
          memo = Memo.returnHash(base64.decode(memoValue));
        } else {
          throw new Exception("Unknown memo type.");
        }
      }
    }
    return memo;
  }

  /// Creates a Memo from separate memo value and type strings.
  ///
  /// This convenience factory method accepts the memo value and type as separate
  /// strings, which is useful when parsing user input or API data that provides
  /// these fields separately.
  ///
  /// Parameters:
  /// - [memo]: The memo value as a string:
  ///   - For 'text': UTF-8 text string (max 28 bytes)
  ///   - For 'id': Numeric string representing 64-bit unsigned integer
  ///   - For 'hash': Base64-encoded 32-byte hash
  ///   - For 'return': Base64-encoded 32-byte hash
  /// - [memoType]: The memo type string:
  ///   - 'none': No memo (memo parameter ignored)
  ///   - 'text': Text memo
  ///   - 'id': Numeric ID memo
  ///   - 'hash': Hash memo
  ///   - 'return': Return hash memo
  ///
  /// Returns: The appropriate Memo subclass instance
  ///
  /// Throws:
  /// - [Exception]: If memoType is unknown or memo format is invalid
  /// - [MemoTooLongException]: If text or hash exceeds length limits
  ///
  /// Example:
  /// ```dart
  /// // Text memo
  /// Memo textMemo = Memo.fromStrings("Invoice 123", "text");
  ///
  /// // ID memo
  /// Memo idMemo = Memo.fromStrings("987654321", "id");
  ///
  /// // Hash memo (base64-encoded)
  /// String base64Hash = "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY=";
  /// Memo hashMemo = Memo.fromStrings(base64Hash, "hash");
  ///
  /// // Return hash memo (base64-encoded)
  /// Memo returnMemo = Memo.fromStrings(base64Hash, "return");
  ///
  /// // From user input
  /// String userMemoValue = getUserInput("Enter memo:");
  /// String userMemoType = getUserInput("Enter type (text/id/hash):");
  /// Memo userMemo = Memo.fromStrings(userMemoValue, userMemoType);
  /// ```
  ///
  /// See also:
  /// - [fromJson] for creating memos from JSON map
  factory Memo.fromStrings(String memo, String memoType) {
    return Memo.fromJson({'memo' : memo, 'memo_type': memoType});
  }

  /// Creates a Memo instance.
  ///
  /// This is an abstract base class constructor. Use factory methods to create
  /// concrete memo instances: [none], [text], [id], [hash], or [returnHash].
  Memo();
}

/// Represents a MEMO_HASH type memo containing a 32-byte hash.
///
/// Hash memos store 32 bytes of data, typically cryptographic hashes or
/// references. Common uses include referencing external data, linking to
/// documents, or storing commitment hashes.
///
/// The hash is automatically padded with zeros if shorter than 32 bytes.
/// Hashes longer than 32 bytes will throw an exception.
///
/// Example:
/// ```dart
/// // From byte array
/// Uint8List hash = Uint8List.fromList([/* 32 bytes */]);
/// MemoHash memo = MemoHash(hash);
///
/// // From hex string
/// MemoHash memo2 = MemoHash.string("a1b2c3d4...");
///
/// // Access hash data
/// Uint8List? data = memo.bytes;
/// String? hexValue = memo.hexValue;
/// ```
///
/// See also:
/// - [Memo.hash] factory method for creating hash memos
/// - [MemoReturnHash] for refund transaction references
class MemoHash extends MemoHashAbstract {
  /// Creates a MEMO_HASH from raw bytes.
  ///
  /// Parameters:
  /// - [bytes] Hash bytes (max 32 bytes, padded if shorter)
  ///
  /// Throws:
  /// - [MemoTooLongException] If bytes exceed 32 bytes
  MemoHash(Uint8List bytes) : super(bytes);

  /// Creates a MEMO_HASH from a hex-encoded string.
  ///
  /// Parameters:
  /// - [hexString] Hexadecimal string (max 64 hex characters)
  ///
  /// Throws:
  /// - [MemoTooLongException] If decoded bytes exceed 32 bytes
  MemoHash.string(String hexString) : super.string(hexString);

  /// Converts this memo to its XDR representation.
  ///
  /// Returns: XDR Memo for this hash-based memo.
  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo(XdrMemoType.MEMO_HASH);
    memo.hash = XdrHash(_bytes!);
    return memo;
  }
}

/// Abstract base class for hash-based memos (MEMO_HASH and MEMO_RETURN).
///
/// Provides common functionality for memo types that store 32-byte hash values.
/// This class handles the validation, padding, and encoding of hash data used
/// by both [MemoHash] and [MemoReturnHash].
///
/// Hash memos must be exactly 32 bytes (256 bits) in length. If a shorter hash
/// is provided, it is automatically padded with zeros to reach 32 bytes. Hashes
/// longer than 32 bytes will throw a [MemoTooLongException].
///
/// This class is not meant to be instantiated directly. Use [MemoHash] or
/// [MemoReturnHash] instead.
///
/// See also:
/// - [MemoHash] for general hash references
/// - [MemoReturnHash] for refund transaction references
abstract class MemoHashAbstract extends Memo {
  Uint8List? _bytes;

  /// Creates a hash-based memo from raw bytes.
  ///
  /// Parameters:
  /// - [bytes] Hash bytes (automatically padded to 32 bytes if shorter)
  ///
  /// Throws:
  /// - [MemoTooLongException] If bytes exceed 32 bytes
  MemoHashAbstract(Uint8List bytes) {
    if (bytes.length < StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      bytes = Util.paddedByteArray(bytes, StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES);
    } else if (bytes.length > StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      throw MemoTooLongException("MEMO_HASH can contain ${StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES} bytes at max.");
    }

    this._bytes = bytes;
  }

  /// Creates a hash-based memo from a hex-encoded string.
  ///
  /// Parameters:
  /// - [hexString] Hexadecimal string (automatically padded to 64 hex chars if shorter)
  ///
  /// Throws:
  /// - [MemoTooLongException] If decoded bytes exceed 32 bytes
  MemoHashAbstract.string(String hexString) {
    Uint8List bytes = Util.hexToBytes(hexString.toUpperCase());
    if (bytes.length < StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      bytes = Util.paddedByteArray(bytes, StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES);
    } else if (bytes.length > StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES) {
      throw MemoTooLongException("MEMO_HASH can contain ${StellarProtocolConstants.SHA256_HASH_LENGTH_BYTES} bytes at max.");
    }

    this._bytes = bytes;
  }

  ///Returns 32 bytes long array contained in this memo.
  Uint8List? get bytes => _bytes;

  /// Returns hex representation of bytes contained in this memo.
  String? get hexValue => Util.bytesToHex(this._bytes!);

  /// Returns hex representation of bytes contained in this memo until null byte (0x00) is found.
  String? get trimmedHexValue => this.hexValue!.split("00")[0];

  @override
  XdrMemo toXdr();

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [o] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object o) {
    if (!(o is MemoHashAbstract)) return false;

    return ListEquality().equals(_bytes, o.bytes);
  }
}

/// Represents a MEMO_NONE type memo (no additional data).
///
/// This is the default memo type when no additional information is needed.
/// Using MEMO_NONE saves transaction space and fees compared to other memo types.
///
/// Example:
/// ```dart
/// MemoNone memo = MemoNone();
/// // or
/// Memo memo = Memo.none();
/// ```
///
/// See also:
/// - [Memo.none] factory method for creating empty memos
class MemoNone extends Memo {
  /// Creates a MEMO_NONE instance representing an empty memo.
  MemoNone();

  /// Converts this memo to its XDR representation.
  ///
  /// Returns: XDR Memo for this empty memo.
  @override
  XdrMemo toXdr() {
    return XdrMemo(XdrMemoType.MEMO_NONE);
  }

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [o] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object o) {
    if (!(o is MemoNone)) return false;
    return true;
  }
}

/// Represents a MEMO_ID type memo containing a 64-bit unsigned integer.
///
/// ID memos are commonly used by exchanges and anchors to identify customers
/// or associate transactions with accounts. The ID must be a positive number
/// (non-zero).
///
/// ID range: 1 to 18,446,744,073,709,551,615 (2^64 - 1)
///
/// Example:
/// ```dart
/// // Create ID memo for customer identification
/// MemoId memo = MemoId(BigInt.from(987654321));
///
/// // Access the ID
/// int customerId = memo.getId();
/// print("Customer: $customerId");
/// ```
///
/// Common use case:
/// ```dart
/// // Exchange deposit with customer ID
/// Transaction deposit = TransactionBuilder(sourceAccount)
///   .addOperation(PaymentOperation(...))
///   .addMemo(Memo.id(customerAccountNumber))
///   .build();
/// ```
///
/// See also:
/// - [Memo.id] factory method for creating ID memos
class MemoId extends Memo {
  late BigInt _id;

  /// Creates a MEMO_ID with the given BigInt identifier.
  ///
  /// Parameters:
  /// - [id] Positive 64-bit unsigned integer as BigInt
  ///
  /// Throws:
  /// - [Exception] If id is zero
  MemoId(BigInt id) {
    if (id == BigInt.zero) {
      throw Exception("id must be a positive number");
    }
    this._id = id;
  }

  /// Returns the numeric ID value of this memo as BigInt.
  BigInt getId() => _id;

  /// Converts this memo to its XDR representation.
  ///
  /// Returns: XDR Memo for this ID-based memo.
  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo(XdrMemoType.MEMO_ID);
    XdrUint64 idXdr = XdrUint64(_id);
    memo.id = idXdr;
    return memo;
  }

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [o] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object o) {
    if (!(o is MemoId)) return false;
    return _id == o.getId();
  }
}

/// Represents a MEMO_RETURN type memo containing a transaction hash reference.
///
/// Return hash memos contain the 32-byte hash of a transaction being refunded.
/// This creates an on-chain link between the original transaction and the refund,
/// making it easy to track refund relationships.
///
/// The hash is automatically padded with zeros if shorter than 32 bytes.
/// Hashes longer than 32 bytes will throw an exception.
///
/// Example:
/// ```dart
/// // Create refund with original transaction hash
/// Uint8List originalTxHash = Uint8List.fromList([/* 32 bytes */]);
/// MemoReturnHash memo = MemoReturnHash(originalTxHash);
///
/// // From hex string
/// String txHashHex = "a1b2c3d4...";
/// MemoReturnHash memo2 = MemoReturnHash.string(txHashHex);
///
/// // Access hash data
/// Uint8List? refundHash = memo.bytes;
/// String? hexValue = memo.hexValue;
/// ```
///
/// Refund workflow:
/// ```dart
/// // Original payment transaction
/// Transaction payment = TransactionBuilder(sourceAccount)
///   .addOperation(PaymentOperation(...))
///   .build();
/// payment.sign(keyPair, Network.PUBLIC);
/// SubmitTransactionResponse response = await sdk.submitTransaction(payment);
/// String paymentHash = response.hash!;
///
/// // Refund with MEMO_RETURN referencing original
/// Transaction refund = TransactionBuilder(sourceAccount)
///   .addOperation(PaymentOperation(...)) // Back to original sender
///   .addMemo(Memo.returnHashString(paymentHash))
///   .build();
/// ```
///
/// See also:
/// - [Memo.returnHash] factory method for creating return hash memos
/// - [MemoHash] for general hash memos
class MemoReturnHash extends MemoHashAbstract {
  /// Creates a MEMO_RETURN from raw bytes.
  ///
  /// Parameters:
  /// - [bytes] Transaction hash bytes (max 32 bytes, padded if shorter)
  ///
  /// Throws:
  /// - [MemoTooLongException] If bytes exceed 32 bytes
  MemoReturnHash(Uint8List bytes) : super(bytes);

  /// Creates a MEMO_RETURN from a hex-encoded transaction hash.
  ///
  /// Parameters:
  /// - [hexString] Hexadecimal transaction hash (max 64 hex characters)
  ///
  /// Throws:
  /// - [MemoTooLongException] If decoded bytes exceed 32 bytes
  MemoReturnHash.string(String hexString) : super.string(hexString);

  /// Converts this memo to its XDR representation.
  ///
  /// Returns: XDR Memo for this return hash memo.
  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo(XdrMemoType.MEMO_RETURN);
    memo.retHash = XdrHash(_bytes!);
    return memo;
  }
}

/// Represents a MEMO_TEXT type memo containing UTF-8 text.
///
/// Text memos can contain up to 28 bytes of UTF-8 encoded text. This is the
/// most human-readable memo type, commonly used for notes, descriptions, or
/// simple identifiers.
///
/// Important: The 28-byte limit applies to the UTF-8 encoded bytes, not
/// character count. Multi-byte characters (emojis, non-ASCII) count as
/// multiple bytes.
///
/// Character encoding:
/// - ASCII characters: 1 byte each
/// - Latin extended characters: 2 bytes each
/// - Most emojis: 4 bytes each
/// - Some complex emojis: up to 11 bytes
///
/// Example:
/// ```dart
/// // Simple ASCII text (11 bytes)
/// MemoText memo1 = MemoText("Invoice 123");
///
/// // With emoji (Payment = 7 bytes, emoji = 4 bytes, total = 11 bytes)
/// MemoText memo2 = MemoText("Payment 💰");
///
/// // Maximum ASCII (28 bytes = 28 characters)
/// MemoText memo3 = MemoText("1234567890123456789012345678");
///
/// // Access text
/// String? message = memo1.text;
/// ```
///
/// Common use cases:
/// ```dart
/// // Invoice reference
/// Memo invoice = Memo.text("Invoice INV-12345");
///
/// // Payment note
/// Memo note = Memo.text("Salary payment");
///
/// // Order reference
/// Memo order = Memo.text("Order #987654");
/// ```
///
/// This will throw MemoTooLongException:
/// ```dart
/// // Too long - 29 bytes
/// // MemoText tooLong = MemoText("This text is 29 bytes long!");
///
/// // Multi-byte characters counted
/// // MemoText emojis = MemoText("😀😀😀😀😀😀😀"); // 7 emojis = 28 bytes, OK
/// // MemoText tooMany = MemoText("😀😀😀😀😀😀😀😀"); // 8 emojis = 32 bytes, FAIL
/// ```
///
/// See also:
/// - [Memo.text] factory method for creating text memos
/// - [MemoId] for numeric identifiers (recommended for exchanges)
class MemoText extends Memo {
  String? _text;

  /// Creates a MEMO_TEXT with the given text string.
  ///
  /// Parameters:
  /// - [text] UTF-8 string (max 28 bytes when encoded)
  ///
  /// Throws:
  /// - [MemoTooLongException] If text exceeds 28 bytes when UTF-8 encoded
  MemoText(String text) {
    this._text = text;

    int length = utf8.encode(text).length;
    if (length > 28) {
      throw MemoTooLongException("text must be <= 28 bytes. length=$length");
    }
  }

  /// Returns the text content of this memo.
  String? get text => _text;

  /// Converts this memo to its XDR representation.
  ///
  /// Returns: XDR Memo for this text-based memo.
  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo(XdrMemoType.MEMO_TEXT);
    memo.text = _text;
    return memo;
  }

  /// Compares this instance to another for equality.
  ///
  /// Returns `true` if [o] is of the same type and all fields are equal, `false` otherwise.
  @override
  bool operator ==(Object o) {
    if (!(o is MemoText)) return false;
    return _text == o.text;
  }
}

/// Exception thrown when a memo value exceeds maximum allowed length.
///
/// Memo length limits:
/// - [Memo.text]: Maximum 28 bytes (UTF-8 encoded)
/// - [Memo.hash]: Must be exactly 32 bytes
/// - [Memo.returnHash]: Must be exactly 32 bytes
///
/// This exception is thrown when attempting to create a memo with data
/// that exceeds these length restrictions.
///
/// Example:
/// ```dart
/// try {
///   // This will throw if text exceeds 28 bytes
///   Memo memo = Memo.text("This is a very long text that exceeds the 28 byte limit");
/// } catch (e) {
///   if (e is MemoTooLongException) {
///     print("Memo too long: ${e.message}");
///   }
/// }
/// ```
///
/// See also:
/// - [Memo] for memo creation and constraints
class MemoTooLongException implements Exception {
  final message;

  /// Creates an exception for memo content exceeding maximum length with an optional error message.
  MemoTooLongException([this.message]);

  /// Returns a string representation of this instance for debugging.
  @override
  String toString() {
    if (message == null) return "MemoTooLongException";
    return "MemoTooLongException: $message";
  }
}
