import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('StrictReceivePathsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with paths/strict-receive segments', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('paths'));
        expect(uri.pathSegments, contains('strict-receive'));
      });

      test('uses provided HTTP client', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('sourceAccount', () {
      final sourceAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds source_account query parameter', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        builder.sourceAccount(sourceAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_account'], equals(sourceAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final result = builder.sourceAccount(sourceAccountId);

        expect(result, same(builder));
      });

      test('throws exception when combined with sourceAssets', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        builder.sourceAssets([Asset.NATIVE]);

        expect(
          () => builder.sourceAccount(sourceAccountId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('sourceAssets', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds source_assets query parameter with single asset', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        builder.sourceAssets([Asset.NATIVE]);
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_assets'], equals('native'));
      });

      test('adds source_assets query parameter with multiple assets', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final assets = [
          Asset.NATIVE,
          AssetTypeCreditAlphaNum4('USD', issuerAccountId),
        ];
        builder.sourceAssets(assets);
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_assets'], contains('native'));
        expect(uri.queryParameters['source_assets'], contains('USD:'));
        expect(uri.queryParameters['source_assets'], contains(','));
      });

      test('throws exception when combined with sourceAccount', () {
        final sourceAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        builder.sourceAccount(sourceAccountId);

        expect(
          () => builder.sourceAssets([Asset.NATIVE]),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('destinationAmount', () {
      test('adds destination_amount query parameter', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        builder.destinationAmount('100.50');
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_amount'], equals('100.50'));
      });

      test('returns builder for method chaining', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final result = builder.destinationAmount('50.0');

        expect(result, same(builder));
      });
    });

    group('destinationAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds destination asset parameters for AlphaNum4', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.destinationAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['destination_asset_code'], equals('USD'));
        expect(uri.queryParameters['destination_asset_issuer'], equals(issuerAccountId));
      });

      test('adds destination asset parameters for native asset', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        builder.destinationAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_asset_type'], equals('native'));
        expect(uri.queryParameters.containsKey('destination_asset_code'), isFalse);
      });

      test('returns builder for method chaining', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final result = builder.destinationAsset(Asset.NATIVE);

        expect(result, same(builder));
      });
    });

    group('buildUri with combinations', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final sourceAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';

      test('builds complete URI with sourceAccount', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final destAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..sourceAccount(sourceAccountId)
          ..destinationAmount('100.0')
          ..destinationAsset(destAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_account'], equals(sourceAccountId));
        expect(uri.queryParameters['destination_amount'], equals('100.0'));
        expect(uri.queryParameters['destination_asset_code'], equals('USD'));
      });

      test('builds complete URI with sourceAssets', () {
        final builder = StrictReceivePathsRequestBuilder(mockClient, serverUri);
        final sourceAssets = [Asset.NATIVE, AssetTypeCreditAlphaNum4('EUR', issuerAccountId)];
        final destAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..sourceAssets(sourceAssets)
          ..destinationAmount('50.0')
          ..destinationAsset(destAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_assets'], contains('native'));
        expect(uri.queryParameters['destination_amount'], equals('50.0'));
        expect(uri.queryParameters['destination_asset_code'], equals('USD'));
      });
    });
  });

  group('StrictSendPathsRequestBuilder', () {
    late http.Client mockClient;
    late Uri serverUri;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('{"_embedded": {"records": []}}', 200);
      });
      serverUri = Uri.parse('https://horizon-testnet.stellar.org');
    });

    group('constructor', () {
      test('creates builder with paths/strict-send segments', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.pathSegments, contains('paths'));
        expect(uri.pathSegments, contains('strict-send'));
      });

      test('uses provided HTTP client', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);

        expect(builder.httpClient, same(mockClient));
      });

      test('uses provided server URI', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final uri = builder.buildUri();

        expect(uri.host, equals('horizon-testnet.stellar.org'));
        expect(uri.scheme, equals('https'));
      });
    });

    group('destinationAccount', () {
      final destAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds destination_account query parameter', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        builder.destinationAccount(destAccountId);
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_account'], equals(destAccountId));
      });

      test('returns builder for method chaining', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final result = builder.destinationAccount(destAccountId);

        expect(result, same(builder));
      });

      test('throws exception when combined with destinationAssets', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        builder.destinationAssets([Asset.NATIVE]);

        expect(
          () => builder.destinationAccount(destAccountId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('destinationAssets', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds destination_assets query parameter with single asset', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        builder.destinationAssets([Asset.NATIVE]);
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_assets'], equals('native'));
      });

      test('adds destination_assets query parameter with multiple assets', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final assets = [
          Asset.NATIVE,
          AssetTypeCreditAlphaNum4('USD', issuerAccountId),
        ];
        builder.destinationAssets(assets);
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_assets'], contains('native'));
        expect(uri.queryParameters['destination_assets'], contains('USD:'));
        expect(uri.queryParameters['destination_assets'], contains(','));
      });

      test('throws exception when combined with destinationAccount', () {
        final destAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        builder.destinationAccount(destAccountId);

        expect(
          () => builder.destinationAssets([Asset.NATIVE]),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('sourceAmount', () {
      test('adds source_amount query parameter', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        builder.sourceAmount('100.50');
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_amount'], equals('100.50'));
      });

      test('returns builder for method chaining', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final result = builder.sourceAmount('50.0');

        expect(result, same(builder));
      });
    });

    group('sourceAsset', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';

      test('adds source asset parameters for AlphaNum4', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final asset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder.sourceAsset(asset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_asset_type'], equals('credit_alphanum4'));
        expect(uri.queryParameters['source_asset_code'], equals('USD'));
        expect(uri.queryParameters['source_asset_issuer'], equals(issuerAccountId));
      });

      test('adds source asset parameters for native asset', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        builder.sourceAsset(Asset.NATIVE);
        final uri = builder.buildUri();

        expect(uri.queryParameters['source_asset_type'], equals('native'));
        expect(uri.queryParameters.containsKey('source_asset_code'), isFalse);
      });

      test('returns builder for method chaining', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final result = builder.sourceAsset(Asset.NATIVE);

        expect(result, same(builder));
      });
    });

    group('buildUri with combinations', () {
      final issuerAccountId = 'GDUKMGUGDZQK6YHYA5Z6AY2G4XDSZPSZ3SW5UN3ARVMO6QSRDWP5YLEX';
      final destAccountId = 'GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI';

      test('builds complete URI with destinationAccount', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final srcAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..destinationAccount(destAccountId)
          ..sourceAmount('100.0')
          ..sourceAsset(srcAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_account'], equals(destAccountId));
        expect(uri.queryParameters['source_amount'], equals('100.0'));
        expect(uri.queryParameters['source_asset_code'], equals('USD'));
      });

      test('builds complete URI with destinationAssets', () {
        final builder = StrictSendPathsRequestBuilder(mockClient, serverUri);
        final destAssets = [Asset.NATIVE, AssetTypeCreditAlphaNum4('EUR', issuerAccountId)];
        final srcAsset = AssetTypeCreditAlphaNum4('USD', issuerAccountId);
        builder
          ..destinationAssets(destAssets)
          ..sourceAmount('50.0')
          ..sourceAsset(srcAsset);
        final uri = builder.buildUri();

        expect(uri.queryParameters['destination_assets'], contains('native'));
        expect(uri.queryParameters['source_amount'], equals('50.0'));
        expect(uri.queryParameters['source_asset_code'], equals('USD'));
      });
    });
  });
}
