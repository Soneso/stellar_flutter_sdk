import 'xdr_data_io.dart';
import "xdr_type.dart";
import "dart:typed_data";
import 'xdr_data_entry.dart';

class XdrSignerKeyType {
  final _value;
  const XdrSignerKeyType._internal(this._value);
  toString() => 'SignerKeyType.$_value';
  XdrSignerKeyType(this._value);
  get value => this._value;

  static const SIGNER_KEY_TYPE_ED25519 = const XdrSignerKeyType._internal(0);
  static const SIGNER_KEY_TYPE_PRE_AUTH_TX =
      const XdrSignerKeyType._internal(1);
  static const SIGNER_KEY_TYPE_HASH_X = const XdrSignerKeyType._internal(2);
  static const KEY_TYPE_ED25519_SIGNED_PAYLOAD =
      const XdrSignerKeyType._internal(3);
  static const KEY_TYPE_MUXED_ED25519 = const XdrSignerKeyType._internal(0x100);

  static XdrSignerKeyType decode(XdrDataInputStream stream) {
    int value = stream.readInt();
    switch (value) {
      case 0:
        return SIGNER_KEY_TYPE_ED25519;
      case 1:
        return SIGNER_KEY_TYPE_PRE_AUTH_TX;
      case 2:
        return SIGNER_KEY_TYPE_HASH_X;
      case 3:
        return KEY_TYPE_ED25519_SIGNED_PAYLOAD;
      case 0x100:
        return KEY_TYPE_MUXED_ED25519;
      default:
        throw Exception("Unknown enum value: $value");
    }
  }

  static void encode(XdrDataOutputStream stream, XdrSignerKeyType value) {
    stream.writeInt(value.value);
  }
}

class XdrSignerKey {
  XdrSignerKey(this._type);
  XdrSignerKeyType _type;
  XdrSignerKeyType get discriminant => this._type;
  set discriminant(XdrSignerKeyType value) => this._type = value;

  XdrUint256? _ed25519;
  XdrUint256? get ed25519 => this._ed25519;
  set ed25519(XdrUint256? value) => this._ed25519 = value;

  XdrUint256? _preAuthTx;
  XdrUint256? get preAuthTx => this._preAuthTx;
  set preAuthTx(XdrUint256? value) => this._preAuthTx = value;

  XdrUint256? _hashX;
  XdrUint256? get hashX => this._hashX;
  set hashX(XdrUint256? value) => this._hashX = value;

  XdrSignedPayload? _signedPayload;
  XdrSignedPayload? get signedPayload => this._signedPayload;
  set signedPayload(XdrSignedPayload? value) => this._signedPayload = value;

  static void encode(
      XdrDataOutputStream stream, XdrSignerKey encodedSignerKey) {
    stream.writeInt(encodedSignerKey.discriminant.value);
    switch (encodedSignerKey.discriminant) {
      case XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519:
        XdrUint256.encode(stream, encodedSignerKey.ed25519!);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX:
        XdrUint256.encode(stream, encodedSignerKey.preAuthTx!);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X:
        XdrUint256.encode(stream, encodedSignerKey.hashX!);
        break;
      case XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD:
        XdrSignedPayload.encode(stream, encodedSignerKey.signedPayload!);
        break;
    }
  }

  static XdrSignerKey decode(XdrDataInputStream stream) {
    XdrSignerKey decodedSignerKey =
        XdrSignerKey(XdrSignerKeyType.decode(stream));
    switch (decodedSignerKey.discriminant) {
      case XdrSignerKeyType.SIGNER_KEY_TYPE_ED25519:
        decodedSignerKey.ed25519 = XdrUint256.decode(stream);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_PRE_AUTH_TX:
        decodedSignerKey.preAuthTx = XdrUint256.decode(stream);
        break;
      case XdrSignerKeyType.SIGNER_KEY_TYPE_HASH_X:
        decodedSignerKey.hashX = XdrUint256.decode(stream);
        break;
      case XdrSignerKeyType.KEY_TYPE_ED25519_SIGNED_PAYLOAD:
        decodedSignerKey.signedPayload = XdrSignedPayload.decode(stream);
        break;
    }
    return decodedSignerKey;
  }
}

class XdrSignedPayload {
  XdrSignedPayload(this._ed25519, this._payload);

  XdrUint256 _ed25519;
  XdrUint256 get ed25519 => this._ed25519;
  set ed25519(XdrUint256 value) => this._ed25519 = value;

  XdrDataValue _payload;
  XdrDataValue get payload => this._payload;
  set payload(XdrDataValue value) => this._payload = value;

  static void encode(XdrDataOutputStream stream, XdrSignedPayload encoded) {
    XdrUint256.encode(stream, encoded.ed25519);
    XdrDataValue.encode(stream, encoded.payload);
  }

  static XdrSignedPayload decode(XdrDataInputStream stream) {
    XdrSignedPayload decoded = XdrSignedPayload(
        XdrUint256.decode(stream), XdrDataValue.decode(stream));
    return decoded;
  }
}

class XdrSigner {
  XdrSignerKey _key;
  XdrSignerKey get key => this._key;
  set key(XdrSignerKey value) => this._key = value;

  XdrUint32 _weight;
  XdrUint32 get weight => this._weight;
  set weight(XdrUint32 value) => this._weight = value;

  XdrSigner(this._key, this._weight);

  static void encode(XdrDataOutputStream stream, XdrSigner encodedSigner) {
    XdrSignerKey.encode(stream, encodedSigner.key);
    XdrUint32.encode(stream, encodedSigner.weight);
  }

  static XdrSigner decode(XdrDataInputStream stream) {
    return XdrSigner(XdrSignerKey.decode(stream), XdrUint32.decode(stream));
  }
}

class XdrDecoratedSignature {
  XdrSignatureHint _hint;
  XdrSignatureHint get hint => this._hint;
  set hint(XdrSignatureHint value) => this._hint = value;

  XdrSignature _signature;
  XdrSignature get signature => this._signature;
  set signature(XdrSignature value) => this._signature = value;

  XdrDecoratedSignature(this._hint, this._signature);

  static void encode(XdrDataOutputStream stream,
      XdrDecoratedSignature encodedDecoratedSignature) {
    XdrSignatureHint.encode(stream, encodedDecoratedSignature.hint);
    XdrSignature.encode(stream, encodedDecoratedSignature.signature);
  }

  static XdrDecoratedSignature decode(XdrDataInputStream stream) {
    return XdrDecoratedSignature(
      XdrSignatureHint.decode(stream),
      XdrSignature.decode(stream),
    );
  }
}

class XdrSignatureHint {
  Uint8List _signatureHint;
  Uint8List get signatureHint => this._signatureHint;
  set signatureHint(Uint8List value) => this._signatureHint = value;

  XdrSignatureHint(this._signatureHint);

  static encode(
      XdrDataOutputStream stream, XdrSignatureHint encodedSignatureHint) {
    stream.write(encodedSignatureHint.signatureHint);
  }

  static XdrSignatureHint decode(XdrDataInputStream stream) {
    int signatureHintSize = 4;
    return XdrSignatureHint(stream.readBytes(signatureHintSize));
  }
}

class XdrSignature {
  Uint8List _signature;
  Uint8List get signature => this._signature;
  set signature(Uint8List value) => this._signature = value;

  XdrSignature(this._signature);

  static encode(XdrDataOutputStream stream, XdrSignature encodedSignature) {
    int signatureSize = encodedSignature.signature.length;
    stream.writeInt(signatureSize);
    stream.write(encodedSignature.signature);
  }

  static XdrSignature decode(XdrDataInputStream stream) {
    int signatureSize = stream.readInt();
    return XdrSignature(stream.readBytes(signatureSize));
  }
}
