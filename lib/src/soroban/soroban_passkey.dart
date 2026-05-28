import 'dart:convert';
import 'dart:typed_data';

import 'package:stellar_flutter_sdk/src/key_pair.dart';
import 'package:stellar_flutter_sdk/src/network.dart';
import 'package:stellar_flutter_sdk/src/util.dart';
import 'package:stellar_flutter_sdk/src/xdr/xdr.dart';

import '../smartaccount/core/smart_account_utils.dart';

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
  /// - [response] Attestation response from WebAuthn registration
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
    Uint8List? decode(String? s) =>
        s != null ? base64Url.decode(base64Url.normalize(s)) : null;

    try {
      return SmartAccountUtils.extractPublicKeyFromRegistration(
        publicKey: decode(response.publicKey),
        authenticatorData: decode(response.authenticatorData),
        attestationObject: decode(response.attestationObject),
      );
    } catch (_) {
      return null;
    }
  }

  /// Generates deterministic contract salt from WebAuthn credentials ID.
  ///
  /// The salt is derived by hashing the credentials ID, ensuring the same
  /// credentials always produce the same contract address when deployed.
  ///
  /// Parameters:
  /// - [credentialsId] Base64URL-encoded credentials ID from WebAuthn response
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
    return SmartAccountUtils.getContractSalt(
      base64Url.decode(base64Url.normalize(credentialsId)),
    );
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
  /// - [contractSalt] Salt for contract creation (typically from getContractSalt)
  /// - [factoryContractId] Contract ID of the factory that will deploy the account
  /// - [network] Network where contracts will be deployed
  ///
  /// Returns: C-address strkey of the derived contract.
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
  /// print('Contract ID: $contractId');
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
  /// - [signature] ASN.1 DER-encoded ECDSA signature from WebAuthn
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
    return SmartAccountUtils.normalizeSignature(signature);
  }
}

/// https://w3c.github.io/webauthn/#dictdef-authenticatorattestationresponsejson
class AuthenticatorAttestationResponse {
  String? clientDataJSON;
  String? authenticatorData;
  String? attestationObject;
  List<String>? transports;
  String? publicKey;

  /// Creates an AuthenticatorAttestationResponse from WebAuthn registration.
  ///
  /// Parameters:
  /// - [clientDataJSON] Base64URL-encoded client data from WebAuthn
  /// - [authenticatorData] Base64URL-encoded authenticator data
  /// - [attestationObject] Base64URL-encoded attestation object
  /// - [transports] List of supported authenticator transports
  /// - [publicKey] Base64URL-encoded public key (if available)
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
  /// - [elements] The subsequence to find
  /// - [start] Starting index for search (default: 0)
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
