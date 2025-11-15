import 'dart:convert';
import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/network.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_contract.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_data_io.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_transaction.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr_type.dart';

/// Utilities for working with WebAuthn passkeys in Soroban smart contracts.
///
/// PasskeyUtils provides helper functions for integrating WebAuthn (passkeys) with
/// Soroban smart contracts, particularly for contract-based account abstraction.
///
/// Passkeys enable:
/// - Passwordless authentication using biometrics or device security
/// - Contract-based accounts controlled by WebAuthn credentials
/// - Secure transaction signing without exposing private keys
///
/// This is commonly used with factory contracts that deploy account contracts
/// controlled by passkey credentials instead of traditional Stellar keypairs.
///
/// Workflow:
/// 1. Register passkey with WebAuthn (browser/device)
/// 2. Extract public key from registration response
/// 3. Derive contract salt from credentials ID
/// 4. Deploy account contract with passkey public key
/// 5. Sign transactions using WebAuthn authentication
///
/// Example:
/// ```dart
/// // After WebAuthn registration in browser
/// final attestationResponse = AuthenticatorAttestationResponse.fromJson(json);
///
/// // Extract public key for contract initialization
/// final publicKey = PasskeyUtils.getPublicKey(attestationResponse);
///
/// // Generate contract salt
/// final salt = PasskeyUtils.getContractSalt(credentialsId);
///
/// // Derive contract address
/// final contractId = PasskeyUtils.deriveContractId(
///   contractSalt: salt,
///   factoryContractId: factoryId,
///   network: Network.TESTNET,
/// );
///
/// // When authenticating, convert signature to compact format
/// final compactSig = PasskeyUtils.compactSignature(ecdsaSignature);
/// ```
///
/// See also:
/// - [WebAuthn Specification](https://w3c.github.io/webauthn/)
/// - [Stellar Account Abstraction](https://developers.stellar.org/docs/smart-contracts/guides/account-abstraction)
class PasskeyUtils {

  /// Extracts the secp256r1 public key from WebAuthn registration response.
  ///
  /// Parses the authenticator attestation response to extract the public key
  /// that will be used to verify WebAuthn signatures in the contract.
  ///
  /// The public key is in uncompressed format (0x04 prefix + 64 bytes for X and Y coordinates).
  ///
  /// Parameters:
  /// - [response]: Attestation response from WebAuthn registration
  ///
  /// Returns: 65-byte public key (0x04 + X + Y) or null if extraction fails
  ///
  /// Example:
  /// ```dart
  /// // After WebAuthn navigator.credentials.create()
  /// final attestationJson = credential.response.toJson();
  /// final response = AuthenticatorAttestationResponse.fromJson(attestationJson);
  ///
  /// final publicKey = PasskeyUtils.getPublicKey(response);
  /// if (publicKey != null) {
  ///   print('Public key: ${Util.bytesToHex(publicKey)}');
  ///   // Use in contract initialization
  /// }
  /// ```
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

  /// Generates deterministic contract salt from WebAuthn credentials ID.
  ///
  /// The salt is derived by hashing the credentials ID, ensuring the same
  /// credentials always produce the same contract address when deployed.
  ///
  /// Parameters:
  /// - [credentialsId]: Base64URL-encoded credentials ID from WebAuthn response
  ///
  /// Returns: 32-byte salt for contract deployment
  ///
  /// Example:
  /// ```dart
  /// // From registration or authentication response
  /// final credentialsId = credential.id;  // Base64URL string
  ///
  /// final salt = PasskeyUtils.getContractSalt(credentialsId);
  /// // Salt will be same for this credentialsId every time
  /// ```
  static Uint8List getContractSalt(String credentialsId) {
    return Util.hash(base64Url.decode(base64Url.normalize(credentialsId)));
  }

  /// Derives the contract ID for a passkey-controlled account contract.
  ///
  /// Calculates the deterministic contract address that will be created when
  /// deploying through a factory contract using CREATE_CONTRACT_FROM_ADDRESS.
  ///
  /// This allows knowing the contract address before deployment, which is useful for:
  /// - Pre-funding the contract address
  /// - Displaying the address to users
  /// - Verifying deployment succeeded at expected address
  ///
  /// Parameters:
  /// - [contractSalt]: Salt for contract creation (typically from getContractSalt)
  /// - [factoryContractId]: Contract ID of the factory that will deploy the account
  /// - [network]: Network where contracts will be deployed
  ///
  /// Returns: Hex-encoded contract ID (C... when encoded with StrKey)
  ///
  /// Example:
  /// ```dart
  /// final credentialsId = credential.id;
  /// final salt = PasskeyUtils.getContractSalt(credentialsId);
  ///
  /// final contractId = PasskeyUtils.deriveContractId(
  ///   contractSalt: salt,
  ///   factoryContractId: 'CABC...',
  ///   network: Network.TESTNET,
  /// );
  ///
  /// // Contract will be deployed at this address
  /// print('Contract ID: ${StrKey.encodeContractIdHex(contractId)}');
  /// ```
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

  /// Converts WebAuthn ECDSA signature from ASN.1 DER to compact format.
  ///
  /// WebAuthn returns signatures in ASN.1 DER encoding, but Soroban contracts
  /// typically expect compact format (raw r and s concatenated).
  ///
  /// This also ensures the signature is in low-S form as required by secp256r1.
  ///
  /// Parameters:
  /// - [signature]: ASN.1 DER-encoded ECDSA signature from WebAuthn
  ///
  /// Returns: 64-byte compact signature (32 bytes r + 32 bytes s)
  ///
  /// Example:
  /// ```dart
  /// // After WebAuthn authentication
  /// final authResponse = credential.response as AuthenticatorAssertionResponse;
  /// final derSignature = authResponse.signature;  // ASN.1 DER format
  ///
  /// // Convert to compact for contract
  /// final compactSig = PasskeyUtils.compactSignature(derSignature);
  ///
  /// // Use in contract invocation as authentication signature
  /// final sigArg = XdrSCVal.forBytes(compactSig);
  /// ```
  ///
  /// See also:
  /// - [secp256r1 low-S requirement](https://github.com/stellar/stellar-protocol/discussions/1435)
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

/// Extension for finding subsequences within a list.
///
/// Provides efficient subsequence search similar to String.indexOf() but for lists.
/// Used internally by PasskeyUtils for parsing WebAuthn binary data structures.
extension IndexOfElements<T> on List<T> {
  /// Finds the starting index of a subsequence within this list.
  ///
  /// Searches for the first occurrence of [elements] in this list, starting at [start].
  /// Returns the starting index if found, or -1 if not found.
  ///
  /// Parameters:
  /// - [elements]: The subsequence to find
  /// - [start]: Starting index for search (default: 0)
  ///
  /// Returns: Index where subsequence starts, or -1 if not found
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
