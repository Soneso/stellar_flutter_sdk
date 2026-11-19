// Copyright 2026 The Stellar Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

// Tests for Asset.contractId(), the Stellar Asset Contract id of an asset on a
// network. The vectors are the ids of the native asset on testnet and on the
// public network, USDC on the public network, and TESTASSET on testnet. Each
// id derives from the network passphrase and, for an issued asset, its issuer.
// The USDC testnet id is a derivation check: the id that the testnet
// passphrase and the issuer derive, also rebuilt from the deployment preimage.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

const String _usdcIssuer =
    'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
const String _testAssetIssuer =
    'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

/// The contract id of [asset] on [network], derived from the preimage of the
/// asset deployment host function rather than from [Asset.contractId].
String _contractIdFromDeployment(Asset asset, Network network) {
  final preimage = DeploySACWithAssetHostFunction(
    asset,
  ).toXdr().createContract!.contractIDPreimage;
  final hashPreimage = XdrHashIDPreimage(
    XdrEnvelopeType.ENVELOPE_TYPE_CONTRACT_ID,
  );
  hashPreimage.contractID = XdrHashIDPreimageContractID(
    XdrHash(network.networkId),
    preimage,
  );
  final stream = XdrDataOutputStream();
  XdrHashIDPreimage.encode(stream, hashPreimage);
  return StrKey.encodeContractId(Util.hash(Uint8List.fromList(stream.bytes)));
}

void main() {
  group('Asset.contractId', () {
    test('XLM on testnet is the testnet id of the native asset', () {
      expect(
        Asset.NATIVE.contractId(Network.TESTNET),
        'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
      );
    });

    test('XLM on the public network is the public id of the native asset', () {
      expect(
        Asset.NATIVE.contractId(Network.PUBLIC),
        'CAS3J7GYLGXMF6TDJBBYYSE3HQ6BBSMLNUQ34T6TZMYMW2EVH34XOWMA',
      );
    });

    test('USDC on the public network has the public id', () {
      final usdc = Asset.createNonNativeAsset('USDC', _usdcIssuer);
      expect(
        usdc.contractId(Network.PUBLIC),
        'CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75',
      );
    });

    test('TESTASSET on testnet has the testnet id', () {
      final testAsset = Asset.createNonNativeAsset(
        'TESTASSET',
        _testAssetIssuer,
      );
      expect(
        testAsset.contractId(Network.TESTNET),
        'CBEFNXB7GMEO2PKBCOSKRUQBDWAH4PVA2RIREKPV335KM7MBK2HRLRGB',
      );
    });

    test(
      'one asset has a different id on testnet and on the public network',
      () {
        final usdc = Asset.createNonNativeAsset('USDC', _usdcIssuer);
        final onTestnet = usdc.contractId(Network.TESTNET);
        final onPublic = usdc.contractId(Network.PUBLIC);
        expect(onTestnet, isNot(onPublic));
        expect(onTestnet, startsWith('C'));
        expect(onPublic, startsWith('C'));
        expect(onTestnet, hasLength(56));
        expect(onPublic, hasLength(56));
      },
    );

    test('USDC on testnet matches its derivation check', () {
      final usdc = Asset.createNonNativeAsset('USDC', _usdcIssuer);
      expect(
        usdc.contractId(Network.TESTNET),
        'CA2E53VHFZ6YSWQIEIPBXJQGT6VW3VKWWZO555XKRQXYJ63GEBJJGHY7',
      );
      expect(
        _contractIdFromDeployment(usdc, Network.TESTNET),
        'CA2E53VHFZ6YSWQIEIPBXJQGT6VW3VKWWZO555XKRQXYJ63GEBJJGHY7',
      );
    });

    test(
      'XLM on testnet matches the id hashed from the deployment preimage',
      () {
        expect(
          _contractIdFromDeployment(Asset.NATIVE, Network.TESTNET),
          'CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC',
        );
        expect(
          Asset.NATIVE.contractId(Network.TESTNET),
          _contractIdFromDeployment(Asset.NATIVE, Network.TESTNET),
        );
      },
    );

    test(
      'USDC on the public network matches the id hashed from the deployment preimage',
      () {
        final usdc = Asset.createNonNativeAsset('USDC', _usdcIssuer);
        expect(
          _contractIdFromDeployment(usdc, Network.PUBLIC),
          'CCW67TSZV3SSS2HXMBQ5JFGCKJNXKZM7UQUWUZPUTHXSTZLEO7SJMI75',
        );
        expect(
          usdc.contractId(Network.PUBLIC),
          _contractIdFromDeployment(usdc, Network.PUBLIC),
        );
      },
    );

    test('a liquidity pool share throws the unsupported error', () {
      final pool = AssetTypePoolShare(
        assetA: Asset.NATIVE,
        assetB: Asset.createNonNativeAsset('USDC', _usdcIssuer),
      );
      expect(
        () => pool.contractId(Network.TESTNET),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            'A liquidity pool share has no Stellar Asset Contract; contractId() '
                'takes the native asset or an issued asset',
          ),
        ),
      );
    });
  });
}
