// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:collection/collection.dart';
import "dart:convert";
import "dart:typed_data";
import 'util.dart';
import 'xdr/xdr_type.dart';
import 'xdr/xdr_memo.dart';

///<p>The memo contains optional extra information. It is the responsibility of the client to interpret this value. Memos can be one of the following types:</p>
///<ul>
///<li><code>MEMO_NONE</code>: Empty memo.</li>
///<li><code>MEMO_TEXT</code>: A string up to 28-bytes long.</li>
///<li><code>MEMO_ID</code>: A 64 bit unsigned integer.</li>
///<li><code>MEMO_HASH</code>: A 32 byte hash.</li>
///<li><code>MEMO_RETURN</code>: A 32 byte hash intended to be interpreted as the hash of the transaction the sender is refunding.</li>
///</ul>
///<p>Use static methods to generate any of above types.</p>
abstract class Memo {
  ///Creates MemoNone instance.
  static MemoNone none() {
    return MemoNone();
  }

  ///Creates MemoText instance.
  static MemoText text(String text) {
    return MemoText(text);
  }

  ///Creates MemoId instance.
  static MemoId id(int id) {
    return MemoId(id);
  }

  ///Creates MemoHash instance from byte array.
  static MemoHash hash(Uint8List bytes) {
    return MemoHash(bytes);
  }

  ///Creates MemoHash instance from hex-encoded string
  static MemoHash hashString(String hexString) {
    return MemoHash.string(hexString);
  }

  ///Creates MemoReturnHash instance from byte array.
  static MemoReturnHash returnHash(Uint8List bytes) {
    return MemoReturnHash(bytes);
  }

  ///Creates MemoReturnHash instance from hex-encoded string.
  static MemoReturnHash returnHashString(String hexString) {
    // We change to lowercase because we want to decode both: upper cased and lower cased alphabets.
    return MemoReturnHash(Util.hexToBytes(hexString.toLowerCase()));
  }

  static Memo fromXdr(XdrMemo memo) {
    switch (memo.discriminant) {
      case XdrMemoType.MEMO_NONE:
        return none();
      case XdrMemoType.MEMO_ID:
        return id(memo.id.uint64);
      case XdrMemoType.MEMO_TEXT:
        return text(memo.text);
      case XdrMemoType.MEMO_HASH:
        return hash(memo.hash.hash);
      case XdrMemoType.MEMO_RETURN:
        return returnHash(memo.retHash.hash);
      default:
        throw Exception("Unknown memo type");
    }
  }

  Memo();

  XdrMemo toXdr();
  bool operator ==(Object o);

  factory Memo.fromJson(Map<String, dynamic> json) {
    String memoType = json["memo_type"] as String;
    Memo memo;
    if (memoType == "none") {
      memo = Memo.none();
    } else {
      if (memoType == "text") {
        memo = Memo.text(json["memo"] as String ?? "");
      } else {
        String memoValue = json["memo"] as String;
        if (memoType == "id") {
          memo = Memo.id(fixnum.Int64.parseInt(memoValue).toInt());
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
}

///Represents MEMO_HASH.
class MemoHash extends MemoHashAbstract {
  MemoHash(Uint8List bytes) : super(bytes);

  MemoHash.string(String hexString) : super.string(hexString);

  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo();
    memo.discriminant = XdrMemoType.MEMO_HASH;

    XdrHash hash = XdrHash();
    hash.hash = _bytes;

    memo.hash = hash;
    return memo;
  }
}

abstract class MemoHashAbstract extends Memo {
  Uint8List _bytes;

  MemoHashAbstract(Uint8List bytes) {
    if (bytes.length < 32) {
      bytes = Util.paddedByteArray(bytes, 32);
    } else if (bytes.length > 32) {
      throw MemoTooLongException("MEMO_HASH can contain 32 bytes at max.");
    }

    this._bytes = bytes;
  }

  MemoHashAbstract.string(String hexString) {
    Uint8List bytes = Util.hexToBytes(hexString.toUpperCase());
    if (bytes.length < 32) {
      bytes = Util.paddedByteArray(bytes, 32);
    } else if (bytes.length > 32) {
      throw MemoTooLongException("MEMO_HASH can contain 32 bytes at max.");
    }

    this._bytes = bytes;
  }

  ///Returns 32 bytes long array contained in this memo.
  Uint8List get bytes => _bytes;

  ///<p>Returns hex representation of bytes contained in this memo.</p>
  String get hexValue => Util.bytesToHex(this._bytes);

  ///<p>Returns hex representation of bytes contained in this memo until null byte (0x00) is found.</p>
  String get trimmedHexValue => this.hexValue.split("00")[0];

  @override
  XdrMemo toXdr();

  @override
  bool operator ==(Object o) {
    if (o == null || !(o is MemoHashAbstract)) return false;
    MemoHashAbstract that = o as MemoHashAbstract;
    return ListEquality().equals(_bytes, that.bytes);
  }
}

///Represents MEMO_NONE.
class MemoNone extends Memo {
  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo();
    memo.discriminant = XdrMemoType.MEMO_NONE;
    return memo;
  }

  @override
  bool operator ==(Object o) {
    if (o == null || !(o is MemoNone)) return false;
    return true;
  }
}

///Represents MEMO_ID.
class MemoId extends Memo {
  int _id;

  MemoId(int id) {
    if (fixnum.Int64(id).toRadixStringUnsigned(10) == "0") {
      throw Exception("id must be a positive number");
    }
    this._id = id;
  }

  int getId() => _id;

  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo();
    memo.discriminant = XdrMemoType.MEMO_ID;
    XdrUint64 idXdr = XdrUint64();
    idXdr.uint64 = _id;
    memo.id = idXdr;
    return memo;
  }

  @override
  bool operator ==(Object o) {
    if (o == null || !(o is MemoId)) return false;
    MemoId memoId = o as MemoId;
    return _id == memoId.getId();
  }
}

///Represents MEMO_RETURN.
class MemoReturnHash extends MemoHashAbstract {
  MemoReturnHash(Uint8List bytes) : super(bytes);
  MemoReturnHash.string(String hexString) : super.string(hexString);

  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo();
    memo.discriminant = XdrMemoType.MEMO_RETURN;

    XdrHash hash = XdrHash();
    hash.hash = _bytes;

    memo.retHash = hash;
    return memo;
  }
}

///Represents MEMO_TEXT.
class MemoText extends Memo {
  String _text;

  MemoText(String text) {
    this._text = checkNotNull(text, "text cannot be null");

    int length = utf8.encode(text).length;
    if (length > 28) {
      throw MemoTooLongException("text must be <= 28 bytes. length=$length");
    }
  }

  String get text => _text;

  @override
  XdrMemo toXdr() {
    XdrMemo memo = XdrMemo();
    memo.discriminant = XdrMemoType.MEMO_TEXT;
    memo.text = _text;
    return memo;
  }

  @override
  bool operator ==(Object o) {
    if (o == null || !(o is MemoText)) return false;
    MemoText memoText = o as MemoText;
    return _text == memoText.text;
  }
}

///Indicates that value passed to Memo
class MemoTooLongException implements Exception {
  final message;

  MemoTooLongException([this.message]);

  String toString() {
    if (message == null) return "MemoTooLongException";
    return "MemoTooLongException: $message";
  }
}
