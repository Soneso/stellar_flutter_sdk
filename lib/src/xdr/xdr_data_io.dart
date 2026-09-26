// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.
// ignore_for_file: implementation_imports

import "dart:typed_data";
import "dart:convert";
import '../constants/bit_constants.dart';
import '../constants/stellar_protocol_constants.dart';

class DataInput {
  Uint8List? data;
  int? _fileLength;
  ByteData? view;
  int? _offset = 0;

  int? get offset => _offset;

  int? get fileLength => _fileLength;

  /// Reads from [data], which may be a view on part of a larger buffer; only
  /// the bytes of [data] itself are read.
  DataInput.fromUint8List(this.data) {
    this.view = ByteData.sublistView(data!);
    _fileLength = data!.lengthInBytes;
  }

  /// Returns the byte (-128 to 127) at [offset]. At the end of the input it
  /// returns -129 if [eofException] is false and throws a [RangeError]
  /// otherwise.
  int readByte([bool eofException = true]) {
    if (!eofException && offset! >= fileLength!) {
      return -129;
    }
    return view!.getInt8(_advance(1));
  }

  /// Reads [numBytes] bytes and skips the padding to the next multiple of
  /// four.
  ///
  /// XDR `string` and variable-length `opaque` values pass the length prefix
  /// read from the input as [numBytes], so the count is checked before the
  /// offset moves. Throws a [RangeError] naming the count if it is negative
  /// or exceeds the remaining bytes.
  Uint8List readBytes(int numBytes) {
    if (numBytes < 0) {
      throw RangeError("XDR byte count cannot be negative, got $numBytes");
    }
    int remaining = fileLength! - _offset!;
    if (numBytes > remaining) {
      throw RangeError(
        "XDR byte count $numBytes exceeds the $remaining remaining bytes",
      );
    }
    int oldOffset = _offset!;
    _offset = _offset! + numBytes;
    pad();
    return Uint8List.fromList(
      data!.getRange(oldOffset, oldOffset + numBytes).toList(),
    );
  }

  // add xdr
  void pad() {
    int pad = 0;
    int mod = _offset! % StellarProtocolConstants.XDR_ALIGNMENT_BYTES;
    if (mod > 0) {
      pad = StellarProtocolConstants.XDR_ALIGNMENT_BYTES - mod;
    }

    while (pad-- > 0) {
      int b = readByte(false);
      if (b == -129) {
        break;
      }
      if (b != 0) {
        throw Exception("non-zero padding");
      }
    }
  }

  /// Returns the byte (0 to 255) at [offset]. At the end of the input it
  /// returns -129 if [eofException] is false and throws a [RangeError]
  /// otherwise.
  int readUnsignedByte([bool eofException = true]) {
    if (!eofException && offset! >= fileLength!) {
      return -129;
    }
    return view!.getUint8(_advance(1));
  }

  /// Reserves the next [width] bytes for a fixed-width read and returns the
  /// offset they start at. Throws a [RangeError] naming the width and the
  /// remaining bytes when the input is too short; the offset does not move.
  int _advance(int width) {
    int remaining = fileLength! - _offset!;
    if (width > remaining) {
      throw RangeError(
        "XDR read of $width bytes exceeds the $remaining remaining bytes",
      );
    }
    int oldOffset = _offset!;
    _offset = oldOffset + width;
    return oldOffset;
  }

  int readShort([Endian endian = Endian.big]) {
    return view!.getInt16(_advance(2), endian);
  }

  int readUnsignedShort([Endian endian = Endian.big]) {
    return view!.getUint16(_advance(2), endian);
  }

  int readInt([Endian endian = Endian.big]) {
    return view!.getInt32(_advance(4), endian);
  }

  int readUint32([Endian endian = Endian.big]) {
    return view!.getUint32(_advance(4), endian);
  }

  BigInt readBigInt64([Endian endian = Endian.big]) {
    int oldOffset = _advance(8);

    // Read 8 bytes directly from the buffer (big-endian)
    BigInt result = BigInt.zero;
    for (int i = 0; i < 8; i++) {
      result = (result << 8) | BigInt.from(data![oldOffset + i] & 0xFF);
    }
    return result;
  }

  BigInt readBigInt64Signed([Endian endian = Endian.big]) {
    BigInt unsigned = readBigInt64(endian);
    return unsigned.toSigned(64);
  }

  double readFloat([Endian endian = Endian.big]) {
    return view!.getFloat32(_advance(4), endian);
  }

  double readDouble([Endian endian = Endian.big]) {
    return view!.getFloat64(_advance(8), endian);
  }

  String? readLine([Endian endian = Endian.big]) {
    var byte = readUnsignedByte(false);
    if (byte == -1) return null;

    StringBuffer result = StringBuffer();
    while (byte != -1 && byte != BitConstants.ASCII_LF) {
      if (byte != BitConstants.ASCII_CR) {
        result.writeCharCode(byte);
      }
      byte = readUnsignedByte(false);
    }
    return result.toString();
  }

  String readChar([Endian endian = Endian.big]) {
    return String.fromCharCode(readShort(endian));
  }

  bool readBoolean() {
    return readInt() != 0;
  }

  void readFully(List bytes, {int? len, int? off, Endian endian = Endian.big}) {
    if (len != null || off != null) {
      if ((len != null && off == null) || (len == null && off != null))
        throw ArgumentError("You must supply both [len] and [off] values.");
      if (len! < 0 || off! < 0)
        throw RangeError("$off - $len is out of bounds");
      if (len == 0) return;
    }

    if (len != null) {
      bytes.addAll(data!.getRange(off!, len));
    } else {
      fillList(bytes, readBytes(bytes.length));
    }
  }

  String readUTF([Endian endian = Endian.big]) {
    int length = readShort(endian);
    List<int> bytes = readBytes(length);
    return utf8.decode(bytes);
  }

  int skipBytes(int n) {
    // _offset += n;
    _offset = _offset! + n;
    if (_offset! > fileLength!) {
      var change = _offset! - fileLength!;
      _offset = fileLength;
      return n - change;
    }
    return n;
  }

  void fillList(List one, List two) {
    for (int x = 0; x < one.length; x++) {
      if (x >= two.length) return;
      one[x] = two[x];
    }
  }
}

class DataOutput {
  List<int> data = [];
  int? offset = 0;

  int? get fileLength => data.length;

  Uint8List _buffer = Uint8List(8);
  ByteData? _view;

  DataOutput() {
    _view = ByteData.view(_buffer.buffer);
  }

  void write(List<int> bytes) {
    int blength = bytes.length;
    data.addAll(bytes);
    offset = offset! + blength;
    pad();
  }

  // add xdr
  void pad() {
    int pad = 0;
    int mod = offset! % StellarProtocolConstants.XDR_ALIGNMENT_BYTES;
    if (mod > 0) {
      pad = StellarProtocolConstants.XDR_ALIGNMENT_BYTES - mod;
    }
    while (pad-- > 0) {
      writeByte(0);
    }
  }

  void writeBoolean(bool v, [Endian endian = Endian.big]) {
    writeInt(v ? 1 : 0, endian);
  }

  void writeByte(int v, [Endian endian = Endian.big]) {
    data.add(v);
    // offset += 1;
    offset = offset! + 1;
  }

  void writeChar(int v, [Endian endian = Endian.big]) {
    writeShort(v, endian);
  }

  void writeChars(String s, [Endian endian = Endian.big]) {
    for (int x = 0; x <= s.length; x++) {
      writeChar(s.codeUnitAt(x), endian);
    }
  }

  void writeFloat(double v, [Endian endian = Endian.big]) {
    _view!.setFloat32(0, v, endian);
    write(_buffer.getRange(0, 4).toList());
  }

  void writeDouble(double v, [Endian endian = Endian.big]) {
    _view!.setFloat64(0, v, endian);
    write(_buffer.getRange(0, 8).toList());
  }

  void writeShort(int v, [Endian endian = Endian.big]) {
    _view!.setInt16(0, v, endian);
    write(_buffer.getRange(0, 2).toList());
  }

  void writeInt(int v, [Endian endian = Endian.big]) {
    _view!.setInt32(0, v, endian);
    write(_buffer.getRange(0, 4).toList());
  }

  void writeBigInt64(BigInt v, [Endian endian = Endian.big]) {
    // Both signed (XdrInt64, sequence numbers) and unsigned (XdrUint64)
    // callers encode through this method, so it accepts the union of both
    // ranges. A value outside it has no 64-bit rendering at all; encoding
    // would keep only its low 64 bits.
    if (v < BitConstants.int64MinValueBigInt ||
        v > BitConstants.uint64MaskBigInt) {
      throw ArgumentError.value(
        v,
        'v',
        'does not fit in a signed or unsigned 64-bit integer',
      );
    }
    BigInt unsigned = v.toUnsigned(64);
    List<int> bytes = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = (unsigned & BigInt.from(0xFF)).toInt();
      unsigned >>= 8;
    }
    write(bytes);
  }

  void writeUTF(String s, [Endian endian = Endian.big]) {
    List<int> bytesNeeded = utf8.encode(s);
    if (bytesNeeded.length > 65535)
      throw FormatException("Length cannot be greater than 65535");
    writeShort(bytesNeeded.length, endian);
    write(bytesNeeded);
  }

  List<int> get bytes => data;
}

class XdrDataInputStream extends DataInput {
  /// Maximum recursive XDR decode depth. Prevents stack exhaustion from
  /// deeply nested structures (e.g. SorobanDelegateSignature nestedDelegates).
  static const int maxRecursiveDecodeDepth = 128;

  int _recursiveDecodeDepth = 0;

  XdrDataInputStream(Uint8List data) : super.fromUint8List(data);

  /// Increments the recursive decode depth counter and throws if the limit
  /// is exceeded. Call before entering a recursive decode invocation.
  void enterRecursiveDecode() {
    _recursiveDecodeDepth++;
    if (_recursiveDecodeDepth > maxRecursiveDecodeDepth) {
      throw Exception(
        'XDR decode depth limit exceeded ($maxRecursiveDecodeDepth). '
        'The encoded data contains a recursion depth that exceeds the '
        'safety cap; decoding is aborted to prevent stack exhaustion.',
      );
    }
  }

  /// Decrements the recursive decode depth counter. Call after a recursive
  /// decode invocation completes (in a finally block).
  void exitRecursiveDecode() {
    if (_recursiveDecodeDepth > 0) {
      _recursiveDecodeDepth--;
    }
  }

  int read() {
    return readByte();
  }

  /// Reads an XDR `string` and returns its raw bytes.
  ///
  /// An XDR `string` carries arbitrary bytes, so the payload is returned
  /// unexamined; only a caller that wants text applies an encoding to it.
  /// Throws a [RangeError] if the length prefix is negative or exceeds the
  /// remaining bytes (see [readBytes]).
  Uint8List readStringBytes() {
    int length = readInt();
    return readBytes(length);
  }

  String readString() {
    return utf8.decode(readStringBytes());
  }

  /// Reads the element count of a variable-length XDR array and checks it
  /// against the remaining bytes before the caller decodes any element.
  ///
  /// Every XDR array element occupies at least 4 bytes (scalars, enum and
  /// union discriminants, optional flags and length prefixes are 4 bytes;
  /// fixed opaque data is padded to 4), so a count above a quarter of the
  /// remaining bytes cannot be satisfied by the input.
  ///
  /// Returns the count, between 0 and a quarter of the remaining bytes
  /// (inclusive). Throws a [RangeError] if the count is negative, exceeds a
  /// quarter of the remaining bytes or fewer than 4 bytes remain.
  int readArrayLength() {
    int count = readInt();
    if (count < 0) {
      throw RangeError("XDR array count cannot be negative, got $count");
    }
    int remaining = fileLength! - offset!;
    int maxCount = remaining ~/ 4;
    if (count > maxCount) {
      throw RangeError(
        "XDR array count $count exceeds the maximum of $maxCount for the "
        "$remaining remaining bytes",
      );
    }
    return count;
  }

  List<int?> readIntArray() {
    var l = readArrayLength();
    // var result = List<int>(l);
    List<int?> result = []..length = l;
    for (int i = 0; i < l; i++) {
      result[i] = readInt();
    }
    return result;
  }

  List<double?> readFloatArray() {
    var l = readArrayLength();
    // var result = List<double>(l);
    List<double?> result = []..length = l;
    for (int i = 0; i < l; i++) {
      result[i] = readFloat();
    }
    return result;
  }

  List<double?> readDoubleArray() {
    var l = readArrayLength();
    // var result = List<double>(l);
    List<double?> result = []..length = l;
    for (int i = 0; i < l; i++) {
      result[i] = readDouble();
    }
    return result;
  }
}

class XdrDataOutputStream extends DataOutput {
  /// Writes [bytes] in the XDR `string` wire form: a four-byte length,
  /// the bytes themselves, and padding to the next multiple of four.
  ///
  /// The length an XDR `string` may declare is bounded by its own four-byte
  /// length prefix, so no further limit applies here.
  void writeStringBytes(Uint8List bytes) {
    writeInt(bytes.length);
    write(bytes);
  }

  writeString(String s) {
    writeStringBytes(utf8.encode(s));
  }

  writeIntArray(List<int> a) {
    writeInt(a.length);
    for (int i = 0; i < a.length; i++) {
      writeInt(a[i]);
    }
  }

  writeFloatArray(List<double> a) {
    writeInt(a.length);
    for (int i = 0; i < a.length; i++) {
      writeFloat(a[i]);
    }
  }

  writeDoubleArray(List<double> a) {
    writeInt(a.length);
    for (int i = 0; i < a.length; i++) {
      writeDouble(a[i]);
    }
  }
}
