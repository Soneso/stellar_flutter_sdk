import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Health endpoint tests', () {
    test('test health response parsing with all fields true', () async {
      // Create mock response with all fields true (healthy state)
      String jsonData = '''
        {
          "database_connected": true,
          "core_up": true,
          "core_synced": true
        }
      ''';

      final response = HealthResponse.fromJson(json.decode(jsonData));

      expect(response.databaseConnected, true);
      expect(response.coreUp, true);
      expect(response.coreSynced, true);
      expect(response.isHealthy, true);
    });

    test('test health response parsing with degraded state', () async {
      // Create mock response with core not synced (degraded state)
      String jsonData = '''
        {
          "database_connected": true,
          "core_up": true,
          "core_synced": false
        }
      ''';

      final response = HealthResponse.fromJson(json.decode(jsonData));

      expect(response.databaseConnected, true);
      expect(response.coreUp, true);
      expect(response.coreSynced, false);
      expect(response.isHealthy, false);
    });

    test('test health response isHealthy property', () async {
      // Test various combinations
      String healthyJson = '{"database_connected": true, "core_up": true, "core_synced": true}';
      String dbDownJson = '{"database_connected": false, "core_up": true, "core_synced": true}';
      String coreDownJson = '{"database_connected": true, "core_up": false, "core_synced": true}';
      String notSyncedJson = '{"database_connected": true, "core_up": true, "core_synced": false}';

      final healthyResponse = HealthResponse.fromJson(json.decode(healthyJson));
      final dbDownResponse = HealthResponse.fromJson(json.decode(dbDownJson));
      final coreDownResponse = HealthResponse.fromJson(json.decode(coreDownJson));
      final notSyncedResponse = HealthResponse.fromJson(json.decode(notSyncedJson));

      expect(healthyResponse.isHealthy, true);
      expect(dbDownResponse.isHealthy, false);
      expect(coreDownResponse.isHealthy, false);
      expect(notSyncedResponse.isHealthy, false);
    });

    test('test health response toJson', () async {
      final response = HealthResponse(
        databaseConnected: true,
        coreUp: true,
        coreSynced: true,
      );

      final jsonOutput = response.toJson();

      expect(jsonOutput['database_connected'], true);
      expect(jsonOutput['core_up'], true);
      expect(jsonOutput['core_synced'], true);
    });

    test('test health response toJson with false values', () async {
      final response = HealthResponse(
        databaseConnected: false,
        coreUp: false,
        coreSynced: false,
      );

      final jsonOutput = response.toJson();

      expect(jsonOutput['database_connected'], false);
      expect(jsonOutput['core_up'], false);
      expect(jsonOutput['core_synced'], false);
    });

    test('test health request builder with mock client', () async {
      // Create mock HTTP client
      final mockClient = MockClient((request) async {
        // Verify the request is made to the correct endpoint
        expect(request.url.path, '/health');
        expect(request.method, 'GET');

        // Return mock response matching actual Horizon format
        String jsonData = '''
          {
            "database_connected": true,
            "core_up": true,
            "core_synced": true
          }
        ''';

        return http.Response(jsonData, 200);
      });

      // Create SDK with mock client
      final sdk = StellarSDK('https://horizon.stellar.org');
      sdk.httpClient = mockClient;

      // Execute health request
      final response = await sdk.health.execute();

      expect(response.databaseConnected, true);
      expect(response.coreUp, true);
      expect(response.coreSynced, true);
      expect(response.isHealthy, true);
    });

    test('test health request builder URL construction', () async {
      final serverURI = Uri.parse('https://horizon.stellar.org');
      final mockClient = MockClient((request) async {
        // Verify the complete URL
        expect(request.url.toString(), 'https://horizon.stellar.org/health');
        return http.Response('{"database_connected": true, "core_up": true, "core_synced": true}', 200);
      });

      final builder = HealthRequestBuilder(mockClient, serverURI);
      final response = await builder.execute();

      expect(response.isHealthy, true);
    });

    test('test health endpoint integration with StellarSDK', () async {
      // Test that the health getter is properly exposed in StellarSDK
      final mockClient = MockClient((request) async {
        return http.Response('{"database_connected": true, "core_up": true, "core_synced": true}', 200);
      });

      final sdk = StellarSDK.PUBLIC;
      sdk.httpClient = mockClient;

      // Verify that health getter returns a HealthRequestBuilder
      final healthBuilder = sdk.health;
      expect(healthBuilder, isA<HealthRequestBuilder>());

      // Execute request through the SDK
      final response = await sdk.health.execute();
      expect(response, isA<HealthResponse>());
      expect(response.isHealthy, true);
    });

    test('test health response with rate limit headers', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"database_connected": true, "core_up": true, "core_synced": true}',
          200,
          headers: {
            'X-Ratelimit-Limit': '100',
            'X-Ratelimit-Remaining': '50',
            'X-Ratelimit-Reset': '1234567890',
          },
        );
      });

      final sdk = StellarSDK.PUBLIC;
      sdk.httpClient = mockClient;

      final response = await sdk.health.execute();

      expect(response.rateLimitLimit, 100);
      expect(response.rateLimitRemaining, 50);
      expect(response.rateLimitReset, 1234567890);
    });

    test('test health response toString method', () async {
      final response = HealthResponse(
        databaseConnected: true,
        coreUp: true,
        coreSynced: false,
      );

      final stringRepresentation = response.toString();

      expect(stringRepresentation, contains('databaseConnected: true'));
      expect(stringRepresentation, contains('coreUp: true'));
      expect(stringRepresentation, contains('coreSynced: false'));
    });

    test('test health with degraded database', () async {
      String jsonData = '''
        {
          "database_connected": false,
          "core_up": true,
          "core_synced": true
        }
      ''';

      final response = HealthResponse.fromJson(json.decode(jsonData));

      expect(response.databaseConnected, false);
      expect(response.coreUp, true);
      expect(response.coreSynced, true);
      expect(response.isHealthy, false);
    });

    test('test health request with testnet', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'horizon-testnet.stellar.org');
        expect(request.url.path, '/health');

        return http.Response('''
          {
            "database_connected": true,
            "core_up": true,
            "core_synced": true
          }
        ''', 200);
      });

      final sdk = StellarSDK.TESTNET;
      sdk.httpClient = mockClient;

      final response = await sdk.health.execute();

      expect(response.isHealthy, true);
      expect(response.databaseConnected, true);
      expect(response.coreUp, true);
      expect(response.coreSynced, true);
    });

    test('test health request with futurenet', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'horizon-futurenet.stellar.org');
        expect(request.url.path, '/health');

        return http.Response('''
          {
            "database_connected": true,
            "core_up": true,
            "core_synced": false
          }
        ''', 200);
      });

      final sdk = StellarSDK.FUTURENET;
      sdk.httpClient = mockClient;

      final response = await sdk.health.execute();

      expect(response.databaseConnected, true);
      expect(response.coreUp, true);
      expect(response.coreSynced, false);
      expect(response.isHealthy, false);
    });

    test('test health request with custom server URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'custom-horizon.example.com');
        expect(request.url.path, '/health');

        return http.Response('{"database_connected": true, "core_up": true, "core_synced": true}', 200);
      });

      final sdk = StellarSDK('https://custom-horizon.example.com');
      sdk.httpClient = mockClient;

      final response = await sdk.health.execute();

      expect(response.isHealthy, true);
    });

    test('test health response edge cases - all false', () async {
      // Test with all systems down
      String jsonData = '''
        {
          "database_connected": false,
          "core_up": false,
          "core_synced": false
        }
      ''';

      final response = HealthResponse.fromJson(json.decode(jsonData));

      expect(response.databaseConnected, false);
      expect(response.coreUp, false);
      expect(response.coreSynced, false);
      expect(response.isHealthy, false);
    });
  });

  group('Health real server tests', () {
    test('test health endpoint with real PUBLIC network', skip: false, () async {
      final sdk = StellarSDK.PUBLIC;

      final response = await sdk.health.execute();

      expect(response, isNotNull);
      expect(response.databaseConnected, isA<bool>());
      expect(response.coreUp, isA<bool>());
      expect(response.coreSynced, isA<bool>());

      print('Health status: ${response.isHealthy}');
      print('Database connected: ${response.databaseConnected}');
      print('Core up: ${response.coreUp}');
      print('Core synced: ${response.coreSynced}');
    });

    test('test health endpoint with real TESTNET', skip: false, () async {
      final sdk = StellarSDK.TESTNET;

      final response = await sdk.health.execute();

      expect(response, isNotNull);
      expect(response.databaseConnected, isA<bool>());
      expect(response.coreUp, isA<bool>());
      expect(response.coreSynced, isA<bool>());

      print('Testnet health status: ${response}');
    });
  });
}
