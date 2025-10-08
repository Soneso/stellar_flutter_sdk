import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

Future<void> main() async {
  // Example: Check the health of various Stellar networks

  print('Checking health of Stellar networks...\n');

  // Check PUBLIC network health
  await checkNetworkHealth('PUBLIC', StellarSDK.PUBLIC);

  // Check TESTNET health
  await checkNetworkHealth('TESTNET', StellarSDK.TESTNET);

  // Check FUTURENET health
  await checkNetworkHealth('FUTURENET', StellarSDK.FUTURENET);

  // Check custom Horizon server health
  final customSdk = StellarSDK('https://custom-horizon.example.com');
  await checkNetworkHealth('CUSTOM', customSdk);
}

Future<void> checkNetworkHealth(String networkName, StellarSDK sdk) async {
  print('--- $networkName Network ---');

  try {
    // Execute health check
    final health = await sdk.health.execute();

    // Display health status
    print('Is Healthy: ${health.isHealthy}');
    print('Database Connected: ${health.databaseConnected}');
    print('Core Up: ${health.coreUp}');
    print('Core Synced: ${health.coreSynced}');

    // Check if the server is healthy
    if (health.isHealthy) {
      print('✅ Server is fully operational');
    } else {
      print('⚠️ Server may be experiencing issues');

      if (!health.databaseConnected) {
        print('  - Database connection issue');
      }
      if (!health.coreUp) {
        print('  - Stellar Core is down');
      }
      if (!health.coreSynced) {
        print('  - Stellar Core is not synced');
      }
    }

    // Display rate limit information if available
    if (health.rateLimitLimit != null) {
      print('Rate Limit: ${health.rateLimitRemaining}/${health.rateLimitLimit}');
    }
  } catch (e) {
    print('❌ Error checking health: $e');
  }

  print('');
}

// Advanced example: Monitor server health periodically
class HealthMonitor {
  final StellarSDK sdk;
  final Duration checkInterval;
  final Function(HealthResponse)? onHealthy;
  final Function(HealthResponse)? onUnhealthy;
  final Function(dynamic)? onError;

  HealthMonitor({
    required this.sdk,
    this.checkInterval = const Duration(minutes: 1),
    this.onHealthy,
    this.onUnhealthy,
    this.onError,
  });

  Stream<HealthResponse> startMonitoring() async* {
    while (true) {
      try {
        final health = await sdk.health.execute();

        if (health.isHealthy) {
          onHealthy?.call(health);
        } else {
          onUnhealthy?.call(health);
        }

        yield health;
      } catch (e) {
        onError?.call(e);
      }

      await Future.delayed(checkInterval);
    }
  }
}

// Usage example for health monitoring
void healthMonitoringExample() {
  final monitor = HealthMonitor(
    sdk: StellarSDK.PUBLIC,
    checkInterval: Duration(seconds: 30),
    onHealthy: (health) {
      print('Server is healthy - DB: ${health.databaseConnected}, Core: ${health.coreUp}, Synced: ${health.coreSynced}');
    },
    onUnhealthy: (health) {
      print('Server unhealthy! DB: ${health.databaseConnected}, Core: ${health.coreUp}, Synced: ${health.coreSynced}');
    },
    onError: (error) {
      print('Failed to check health: $error');
    },
  );

  // Start monitoring
  monitor.startMonitoring().listen(
    (health) {
      // Process health updates
      print('Health update: ${health.isHealthy ? "healthy" : "unhealthy"}');
    },
    onError: (error) {
      print('Monitoring error: $error');
    },
  );
}