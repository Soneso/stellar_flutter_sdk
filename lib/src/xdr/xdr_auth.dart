// Copyright 2020 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'xdr_type.dart';
import 'xdr_data_io.dart';
import 'xdr_other.dart';
import 'xdr_signing.dart';

class XdrAuth {
  int _unused;
  int get unused => this._unused;
  set unused(int value) => this._unused = value;

  XdrAuth(this._unused);

  static void encode(XdrDataOutputStream stream, XdrAuth encodedAuth) {
    stream.writeInt(encodedAuth.unused);
  }

  static XdrAuth decode(XdrDataInputStream stream) {
    return XdrAuth(stream.readInt());
  }
}

class XdrAuthCert {
  XdrCurve25519Public _pubkey;
  XdrCurve25519Public get pubkey => this._pubkey;
  set pubkey(XdrCurve25519Public value) => this._pubkey = value;

  XdrUint64 _expiration;
  XdrUint64 get expiration => this._expiration;
  set expiration(XdrUint64 value) => this._expiration = value;

  XdrSignature _sig;
  XdrSignature get sig => this._sig;
  set sig(XdrSignature value) => this._sig = value;

  XdrAuthCert(this._pubkey, this._expiration, this._sig);

  static void encode(XdrDataOutputStream stream, XdrAuthCert encodedAuthCert) {
    XdrCurve25519Public.encode(stream, encodedAuthCert.pubkey);
    XdrUint64.encode(stream, encodedAuthCert.expiration);
    XdrSignature.encode(stream, encodedAuthCert.sig);
  }

  static XdrAuthCert decode(XdrDataInputStream stream) {
    return XdrAuthCert(XdrCurve25519Public.decode(stream),
        XdrUint64.decode(stream), XdrSignature.decode(stream));
  }
}

class XdrAuthenticatedMessage {
  XdrUint32 _v;
  XdrUint32 get discriminant => this._v;
  set discriminant(XdrUint32 value) => this._v = value;

  XdrAuthenticatedMessageV0? _v0;
  XdrAuthenticatedMessageV0? get v0 => this._v0;
  set v0(XdrAuthenticatedMessageV0? value) => this._v0 = value;

  XdrAuthenticatedMessage(this._v);

  static void encode(XdrDataOutputStream stream,
      XdrAuthenticatedMessage encodedAuthenticatedMessage) {
    stream.writeInt(encodedAuthenticatedMessage.discriminant.uint32);
    switch (encodedAuthenticatedMessage.discriminant.uint32) {
      case 0:
        XdrAuthenticatedMessageV0.encode(
            stream, encodedAuthenticatedMessage._v0!);
        break;
    }
  }

  static XdrAuthenticatedMessage decode(XdrDataInputStream stream) {
    XdrAuthenticatedMessage decodedAuthenticatedMessage =
        XdrAuthenticatedMessage(XdrUint32.decode(stream));
    switch (decodedAuthenticatedMessage.discriminant.uint32) {
      case 0:
        decodedAuthenticatedMessage._v0 =
            XdrAuthenticatedMessageV0.decode(stream);
        break;
    }
    return decodedAuthenticatedMessage;
  }
}

class XdrAuthenticatedMessageV0 {
  XdrUint64 _sequence;
  XdrUint64 get sequence => this._sequence;
  set sequence(XdrUint64 value) => this._sequence = value;

  XdrStellarMessage _message;
  XdrStellarMessage get message => this._message;
  set message(XdrStellarMessage value) => this._message = value;

  XdrHmacSha256Mac _mac;
  XdrHmacSha256Mac get mac => this._mac;
  set mac(XdrHmacSha256Mac value) => this._mac = value;

  XdrAuthenticatedMessageV0(this._sequence, this._message, this._mac);

  static void encode(XdrDataOutputStream stream,
      XdrAuthenticatedMessageV0 encodedAuthenticatedMessageV0) {
    XdrUint64.encode(stream, encodedAuthenticatedMessageV0.sequence);
    XdrStellarMessage.encode(stream, encodedAuthenticatedMessageV0.message);
    XdrHmacSha256Mac.encode(stream, encodedAuthenticatedMessageV0.mac);
  }

  static XdrAuthenticatedMessageV0 decode(XdrDataInputStream stream) {
    return XdrAuthenticatedMessageV0(XdrUint64.decode(stream),
        XdrStellarMessage.decode(stream), XdrHmacSha256Mac.decode(stream));
  }
}
