import 'dart:convert';
import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/network.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_contract.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_data_io.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_transaction.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

class PasskeyUtils {

  /// Extracts the public key from the authenticator attestation [response] received
  /// from the webauthn registration.
  static Uint8List? getPublicKey(AuthenticatorAttestationResponse response) {
    final publicKeyStr = response.publicKey;

    Uint8List? publicKey = publicKeyStr != null
        ? base64Url.decode(base64Url.normalize(publicKeyStr))
        : null;

    if (publicKey == null ||
        publicKey.isEmpty ||
        publicKey.first != 0x04 ||
        publicKey.length != 65) {
      // see https://www.w3.org/TR/webauthn/#attestation-object
      final authenticatorDataStr = response.authenticatorData;
      if (authenticatorDataStr != null) {
        Uint8List authData =
            base64Url.decode(base64Url.normalize(authenticatorDataStr));
        // Get credentialIdLength, which is at offset 53 (and is big-endian)
        final credentialIdLength = (authData[53] << 8) + authData[54];
        final x =
            authData.sublist(65 + credentialIdLength, 97 + credentialIdLength);
        final y = authData.sublist(
            100 + credentialIdLength, 132 + credentialIdLength);
        return Uint8List.fromList([
          [0x04],
          x,
          y
        ].expand((x) => x).toList());
      }

      final attestationObjectStr = response.attestationObject;
      if (attestationObjectStr != null) {
        Uint8List attestationObject =
            base64Url.decode(base64Url.normalize(attestationObjectStr));
        final publicKeyPrefixSlice = Uint8List.fromList(
            [0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20]);
        var startIndex =
            attestationObject.indexOfElements(publicKeyPrefixSlice);
        if (startIndex != -1) {
          startIndex = startIndex + publicKeyPrefixSlice.length;
          final x = attestationObject.sublist(startIndex, 32 + startIndex);
          final y = attestationObject.sublist(35 + startIndex, 67 + startIndex);
          return Uint8List.fromList([
            [0x04],
            x,
            y
          ].expand((x) => x).toList());
        }
      }
    }
    return publicKey;
  }

  /// Generates the webauthn (account) contract salt from the webauthn registration response credentials id or
  /// authentication response credentials id.
  static Uint8List getContractSalt(String credentialsId) {
    return Util.hash(base64Url.decode(base64Url.normalize(credentialsId)));
  }

  /// Derives a contract id of the webauthn (account) contract that will be created from the [contractSalt],
  /// the contract id: [factoryContractId] of the factory contract that will be used to deploy the webauthn (account) contract
  /// and the stellar [network] where the webauthn and factory contracts are operation.
  static String deriveContractId(
      {required Uint8List contractSalt,
      required String factoryContractId,
      required Network network}) {
    final preimage =
        XdrHashIDPreimage(XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID);
    final contractIdPreimage = XdrContractIDPreimage(
        XdrContractIDPreimageType.CONTRACT_ID_PREIMAGE_FROM_ADDRESS);
    contractIdPreimage.address = XdrSCAddress.forContractId(factoryContractId);
    contractIdPreimage.salt = XdrUint256(contractSalt);
    final preimageCID = XdrHashIDPreimageContractID(
        XdrHash(network.networkId!), contractIdPreimage);
    preimage.contractID = preimageCID;
    XdrDataOutputStream xdrOutputStream = XdrDataOutputStream();
    XdrHashIDPreimage.encode(xdrOutputStream, preimage);
    return StrKey.encodeContractId(
        Util.hash(Uint8List.fromList(xdrOutputStream.bytes)));
  }

  /// Convert EcdsaSignatureAsn [signature] received from the webauthn authentication
  /// to compact. The resulting compact signature is to be used as authentication
  /// signature for the webauthn (account) contract __checkAuth invocation.
  static Uint8List compactSignature(Uint8List signature) {
    // Decode the DER signature
    var offset = 2;
    final rLength = signature[offset + 1];
    final r = signature.sublist(offset + 2, offset + 2 + rLength);

    offset += 2 + rLength;

    final sLength = signature[offset + 1];
    final s = signature.sublist(offset + 2, offset + 2 + sLength);

    // Convert r and s to BigInt
    final rHexStr = Util.bytesToHex(r);
    final sHexStr = Util.bytesToHex(s);
    final rBigInt = BigInt.parse('0x$rHexStr');
    var sBigInt = BigInt.parse('0x$sHexStr');

    // Ensure s is in the low-S form
    // https://github.com/stellar/stellar-protocol/discussions/1435#discussioncomment-8809175
    // https://discord.com/channels/897514728459468821/1233048618571927693
    // Define the order of the curve secp256r1
    // https://github.com/RustCrypto/elliptic-curves/blob/master/p256/src/lib.rs#L72
    final BigInt n = BigInt.parse('0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551');
    final BigInt halfN = n ~/ BigInt.from(2);

    if (sBigInt > halfN) {
      sBigInt = n - sBigInt;
    }

    // Convert back to buffers and ensure they are 32 bytes
    final rPadded = rBigInt.toRadixString(16).padLeft(64, '0');
    final sLowS = sBigInt.toRadixString(16).padLeft(64, '0');
    final rPaddedBytes = Util.hexToBytes(rPadded);
    final sLowSBytes = Util.hexToBytes(sLowS);

    // Concatenate r and low-s
    var b = BytesBuilder();
    b.add(rPaddedBytes);
    b.add(sLowSBytes);

    final concatSignature = b.toBytes();
    return concatSignature;
  }
}

/// https://w3c.github.io/webauthn/#dictdef-authenticatorattestationresponsejson
class AuthenticatorAttestationResponse {
  String? clientDataJSON;
  String? authenticatorData;
  String? attestationObject;
  List<String>? transports;
  String? publicKey;

  /// Constructor for AuthenticatorAttestationResponse.
  AuthenticatorAttestationResponse({
    this.clientDataJSON,
    this.authenticatorData,
    this.attestationObject,
    this.transports,
    this.publicKey,
  });

  /// Construct AuthenticatorAttestationResponse from JSON.
  factory AuthenticatorAttestationResponse.fromJson(Map<String, dynamic> json) {
    return AuthenticatorAttestationResponse(
      clientDataJSON: json['clientDataJSON'],
      attestationObject: json['attestationObject'],
      authenticatorData: json['authenticatorData'],
      publicKey: json['publicKey'],
      transports: json['transports'] != null
          ? List<String>.from(json['transports'])
          : null,
    );
  }

  /// Convert Response to JSON.
  Map<String, dynamic> toJson() {
    return {
      'clientDataJSON': clientDataJSON,
      'authenticatorData': authenticatorData,
      'attestationObject': attestationObject,
      'transports': transports,
      'publicKey': publicKey,
    };
  }
}

extension IndexOfElements<T> on List<T> {
  int indexOfElements(List<T> elements, [int start = 0]) {
    if (elements.isEmpty) return start;
    var end = length - elements.length;
    if (start > end) return -1;
    var first = elements.first;
    var pos = start;
    while (true) {
      pos = indexOf(first, pos);
      if (pos < 0 || pos > end) return -1;
      for (var i = 1; i < elements.length; i++) {
        if (this[pos + i] != elements[i]) {
          pos++;
          continue;
        }
      }
      return pos;
    }
  }
}
