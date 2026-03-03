// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_data_io.dart';
import 'xdr_node_id.dart';
import 'xdr_uint64.dart';

class XdrPeerStats {
  XdrNodeID _id;
  XdrNodeID get id => this._id;
  set id(XdrNodeID value) => this._id = value;

  String _versionStr;
  String get versionStr => this._versionStr;
  set versionStr(String value) => this._versionStr = value;

  XdrUint64 _messagesRead;
  XdrUint64 get messagesRead => this._messagesRead;
  set messagesRead(XdrUint64 value) => this._messagesRead = value;

  XdrUint64 _messagesWritten;
  XdrUint64 get messagesWritten => this._messagesWritten;
  set messagesWritten(XdrUint64 value) => this._messagesWritten = value;

  XdrUint64 _bytesRead;
  XdrUint64 get bytesRead => this._bytesRead;
  set bytesRead(XdrUint64 value) => this._bytesRead = value;

  XdrUint64 _bytesWritten;
  XdrUint64 get bytesWritten => this._bytesWritten;
  set bytesWritten(XdrUint64 value) => this._bytesWritten = value;

  XdrUint64 _secondsConnected;
  XdrUint64 get secondsConnected => this._secondsConnected;
  set secondsConnected(XdrUint64 value) => this._secondsConnected = value;

  XdrUint64 _uniqueFloodBytesRecv;
  XdrUint64 get uniqueFloodBytesRecv => this._uniqueFloodBytesRecv;
  set uniqueFloodBytesRecv(XdrUint64 value) =>
      this._uniqueFloodBytesRecv = value;

  XdrUint64 _duplicateFloodBytesRecv;
  XdrUint64 get duplicateFloodBytesRecv => this._duplicateFloodBytesRecv;
  set duplicateFloodBytesRecv(XdrUint64 value) =>
      this._duplicateFloodBytesRecv = value;

  XdrUint64 _uniqueFetchBytesRecv;
  XdrUint64 get uniqueFetchBytesRecv => this._uniqueFetchBytesRecv;
  set uniqueFetchBytesRecv(XdrUint64 value) =>
      this._uniqueFetchBytesRecv = value;

  XdrUint64 _duplicateFetchBytesRecv;
  XdrUint64 get duplicateFetchBytesRecv => this._duplicateFetchBytesRecv;
  set duplicateFetchBytesRecv(XdrUint64 value) =>
      this._duplicateFetchBytesRecv = value;

  XdrUint64 _uniqueFloodMessageRecv;
  XdrUint64 get uniqueFloodMessageRecv => this._uniqueFloodMessageRecv;
  set uniqueFloodMessageRecv(XdrUint64 value) =>
      this._uniqueFloodMessageRecv = value;

  XdrUint64 _duplicateFloodMessageRecv;
  XdrUint64 get duplicateFloodMessageRecv => this._duplicateFloodMessageRecv;
  set duplicateFloodMessageRecv(XdrUint64 value) =>
      this._duplicateFloodMessageRecv = value;

  XdrUint64 _uniqueFetchMessageRecv;
  XdrUint64 get uniqueFetchMessageRecv => this._uniqueFetchMessageRecv;
  set uniqueFetchMessageRecv(XdrUint64 value) =>
      this._uniqueFetchMessageRecv = value;

  XdrUint64 _duplicateFetchMessageRecv;
  XdrUint64 get duplicateFetchMessageRecv => this._duplicateFetchMessageRecv;
  set duplicateFetchMessageRecv(XdrUint64 value) =>
      this._duplicateFetchMessageRecv = value;

  XdrPeerStats(
    this._id,
    this._versionStr,
    this._messagesRead,
    this._messagesWritten,
    this._bytesRead,
    this._bytesWritten,
    this._secondsConnected,
    this._uniqueFloodBytesRecv,
    this._duplicateFloodBytesRecv,
    this._uniqueFetchBytesRecv,
    this._duplicateFetchBytesRecv,
    this._uniqueFloodMessageRecv,
    this._duplicateFloodMessageRecv,
    this._uniqueFetchMessageRecv,
    this._duplicateFetchMessageRecv,
  );

  static void encode(
    XdrDataOutputStream stream,
    XdrPeerStats encodedPeerStats,
  ) {
    XdrNodeID.encode(stream, encodedPeerStats.id);
    stream.writeString(encodedPeerStats.versionStr);
    XdrUint64.encode(stream, encodedPeerStats.messagesRead);
    XdrUint64.encode(stream, encodedPeerStats.messagesWritten);
    XdrUint64.encode(stream, encodedPeerStats.bytesRead);
    XdrUint64.encode(stream, encodedPeerStats.bytesWritten);
    XdrUint64.encode(stream, encodedPeerStats.secondsConnected);
    XdrUint64.encode(stream, encodedPeerStats.uniqueFloodBytesRecv);
    XdrUint64.encode(stream, encodedPeerStats.duplicateFloodBytesRecv);
    XdrUint64.encode(stream, encodedPeerStats.uniqueFetchBytesRecv);
    XdrUint64.encode(stream, encodedPeerStats.duplicateFetchBytesRecv);
    XdrUint64.encode(stream, encodedPeerStats.uniqueFloodMessageRecv);
    XdrUint64.encode(stream, encodedPeerStats.duplicateFloodMessageRecv);
    XdrUint64.encode(stream, encodedPeerStats.uniqueFetchMessageRecv);
    XdrUint64.encode(stream, encodedPeerStats.duplicateFetchMessageRecv);
  }

  static XdrPeerStats decode(XdrDataInputStream stream) {
    XdrNodeID id = XdrNodeID.decode(stream);
    String versionStr = stream.readString();
    XdrUint64 messagesRead = XdrUint64.decode(stream);
    XdrUint64 messagesWritten = XdrUint64.decode(stream);
    XdrUint64 bytesRead = XdrUint64.decode(stream);
    XdrUint64 bytesWritten = XdrUint64.decode(stream);
    XdrUint64 secondsConnected = XdrUint64.decode(stream);
    XdrUint64 uniqueFloodBytesRecv = XdrUint64.decode(stream);
    XdrUint64 duplicateFloodBytesRecv = XdrUint64.decode(stream);
    XdrUint64 uniqueFetchBytesRecv = XdrUint64.decode(stream);
    XdrUint64 duplicateFetchBytesRecv = XdrUint64.decode(stream);
    XdrUint64 uniqueFloodMessageRecv = XdrUint64.decode(stream);
    XdrUint64 duplicateFloodMessageRecv = XdrUint64.decode(stream);
    XdrUint64 uniqueFetchMessageRecv = XdrUint64.decode(stream);
    XdrUint64 duplicateFetchMessageRecv = XdrUint64.decode(stream);
    return XdrPeerStats(
      id,
      versionStr,
      messagesRead,
      messagesWritten,
      bytesRead,
      bytesWritten,
      secondsConnected,
      uniqueFloodBytesRecv,
      duplicateFloodBytesRecv,
      uniqueFetchBytesRecv,
      duplicateFetchBytesRecv,
      uniqueFloodMessageRecv,
      duplicateFloodMessageRecv,
      uniqueFetchMessageRecv,
      duplicateFetchMessageRecv,
    );
  }
}
