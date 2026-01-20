// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.
// ignore_for_file: implementation_imports

import "dart:typed_data";
import "dart:convert";
import 'package:pointycastle/src/utils.dart';

import 'package:stellar_flutter_sdk/stub/non-web.dart'
    if (dart.library.html) 'package:stellar_flutter_sdk/stub/web.dart';
import '../constants/bit_constants.dart';
import '../constants/stellar_protocol_constants.dart';

class DataInput {
  Uint8List? data;
  int? _fileLength;
  ByteData? view;
  int? _offset = 0;

  int? get offset => _offset;

  int? get fileLength => _fileLength;

  DataInput.fromUint8List(this.data) {
    this.view = ByteData.view(data!.buffer);
    _fileLength = data!.lengthInBytes;
  }

  /// Returns the byte(-128 - 127) at [offset]. if [eofException] is false then
  /// if it reaches the end of the stream it will return -129.
  /// Otherwise it will throw an exception.
  int readByte([bool eofException = true]) {
    if (offset! + 1 < fileLength!) {
      return view!.getInt8(_offset = _offset! + 1);
    } else if (eofException)
      throw RangeError("Reached end of file");
    else
      return -129;
  }

  Uint8List readBytes(int numBytes) {
    if ((_offset! + numBytes) <= fileLength!) {
      int oldOffset = _offset!;
      _offset = _offset! + numBytes;
      pad();
      return Uint8List.fromList(
        data!.getRange(oldOffset, oldOffset + numBytes).toList(),
      );
    } else
      throw RangeError("Reached end of file");
  }

  // add xdr
  void pad() {
    int pad = 0;
    int mod = _offset! % 4;
    if (mod > 0) {
      pad = 4 - mod;
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

  /// Returns the byte(0-255) at [offset]. if [eofException] is false then
  /// if it reaches the end of the stream it will return -1, Otherwise it will
  /// throw an exception.
  int readUnsignedByte([bool eofException = true]) {
    if (offset! < fileLength!) {
      return view!.getUint8(_offset = _offset! + 1);
    } else if (eofException)
      throw RangeError("Reached end of file");
    else
      return -129;
  }

  int readShort([Endian endian = Endian.big]) {
    var oldOffset = _offset;
    // _offset += 2;
    _offset = _offset! + 2;
    return view!.getInt16(oldOffset!, endian);
  }

  int readUnsignedShort([Endian endian = Endian.big]) {
    var oldOffset = _offset;
    // _offset += 2;
    _offset = _offset! + 2;
    return view!.getUint16(oldOffset!, endian);
  }

  int readInt([Endian endian = Endian.big]) {
    var oldOffset = _offset;
    // _offset += 4;
    _offset = _offset! + 4;
    return view!.getInt32(oldOffset!, endian);
  }

  BigInt readBigInt64([Endian endian = Endian.big]) {
    var oldOffset = _offset;
    _offset = _offset! + 8;

    // Read 8 bytes directly from the buffer (big-endian)
    BigInt result = BigInt.zero;
    for (int i = 0; i < 8; i++) {
      result = (result << 8) | BigInt.from(data![oldOffset! + i] & 0xFF);
    }
    return result;
  }

  BigInt readBigInt64Signed([Endian endian = Endian.big]) {
    BigInt unsigned = readBigInt64(endian);
    return unsigned.toSigned(64);
  }

  int readLong([Endian endian = Endian.big]) {
    var oldOffset = _offset;
    // _offset += 8;
    _offset = _offset! + 8;

    if (kIsWeb) {
      List<int> buffer = view!.buffer.asUint8List(oldOffset!);
      if (buffer.length > 8) buffer = buffer.sublist(0, 8);
      BigInt bigInt = decodeBigInt(buffer);
      return bigInt.toInt();
    } else {
      return view!.getInt64(oldOffset!, endian);
    }
  }

  double readFloat([Endian endian = Endian.big]) {
    var oldOffset = _offset;
    // _offset += 4;
    _offset = _offset! + 4;
    return view!.getFloat32(oldOffset!, endian);
  }

  double readDouble([Endian endian = Endian.big]) {
    var oldOffset = _offset;
    // _offset += 8;
    _offset = _offset! + 8;
    return view!.getFloat64(oldOffset!, endian);
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
    int mod = offset! % 4;
    if (mod > 0) {
      pad = 4 - mod;
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

  void writeLong(int v, [Endian endian = Endian.big]) {
    if (kIsWeb) {
      Uint8List u64Buffer = u64BytesHelper(v);
      _view = ByteData.view(u64Buffer.buffer);
      _buffer = u64Buffer;
    } else {
      _view!.setInt64(0, v, endian);
    }
    write(_buffer.getRange(0, 8).toList());
  }

  void writeBigInt64(BigInt v, [Endian endian = Endian.big]) {
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

  Uint8List u64BigIntBytesHelper(BigInt x) {
    String radixString = x.toRadixString(2);
    while (radixString.length <
        StellarProtocolConstants.HEX_STRING_256BIT_LENGTH) {
      radixString = '0' + radixString;
    }
    List<int> bytes = [];
    for (int i = 0; i < BitConstants.BYTES_PER_INT64; i++) {
      bytes.add(
        int.parse(
          radixString.substring(
            i * BitConstants.BITS_PER_BYTE,
            i * BitConstants.BITS_PER_BYTE + BitConstants.BITS_PER_BYTE,
          ),
          radix: 2,
        ),
      );
    }
    return Uint8List.fromList(bytes);
  }

  // Fix int64 accessor not supported by dart2js
  // https://github.com/shamblett/cbor/commit/563954b02e883d3506069dd83ec98a6f4ab59447
  Uint8List u64BytesHelper(int x) {
    if (x.isInfinite) throw FormatException("Cannot process Infinite number");
    String radixString = x.toRadixString(2);
    while (radixString.length <
        StellarProtocolConstants.HEX_STRING_256BIT_LENGTH) {
      radixString = '0' + radixString;
    }
    List<int> bytes = [];
    for (int i = 0; i < BitConstants.BYTES_PER_INT64; i++) {
      bytes.add(
        int.parse(
          radixString.substring(
            i * BitConstants.BITS_PER_BYTE,
            i * BitConstants.BITS_PER_BYTE + BitConstants.BITS_PER_BYTE,
          ),
          radix: 2,
        ),
      );
    }
    return Uint8List.fromList(bytes);
  }

  List<int> get bytes => data;
}

class XdrDataInputStream extends DataInput {
  XdrDataInputStream(Uint8List data) : super.fromUint8List(data);

  int read() {
    return readByte();
  }

  String readString() {
    int length = readInt();
    List<int> bytes = readBytes(length);
    return utf8.decode(bytes);
  }

  List<int?> readIntArray() {
    var l = readInt();
    // var result = List<int>(l);
    List<int?> result = []..length = l;
    for (int i = 0; i < l; i++) {
      result[i] = readInt();
    }
    return result;
  }

  List<double?> readFloatArray() {
    var l = readInt();
    // var result = List<double>(l);
    List<double?> result = []..length = l;
    for (int i = 0; i < l; i++) {
      result[i] = readFloat();
    }
    return result;
  }

  List<double?> readDoubleArray() {
    var l = readInt();
    // var result = List<double>(l);
    List<double?> result = []..length = l;
    for (int i = 0; i < l; i++) {
      result[i] = readDouble();
    }
    return result;
  }
}

class XdrDataOutputStream extends DataOutput {
  writeString(String s) {
    List<int> bytesNeeded = utf8.encode(s);
    if (bytesNeeded.length > 65535)
      throw FormatException("Length cannot be greater than 65535");
    writeInt(bytesNeeded.length);
    write(bytesNeeded);
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
