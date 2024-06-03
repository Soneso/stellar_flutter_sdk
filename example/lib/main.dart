import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import 'stellar_quest/series_1/series_1.dart' as s1;
import 'stellar_quest/series_2/series_2.dart' as s2;

void main() {
  runApp(StellarFlutterDemoApp());
}

class StellarFlutterDemoApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar Flutter SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final sdk = StellarSDK.TESTNET;
  final network = Network.TESTNET;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stellar Flutter SDK Demo'),
      ),
      body: CustomScrollView(
        slivers: [
          MultiSliver(
            pushPinnedChildren: true,
            children: [
              _SliverPinnedHeader(
                text: 'Serie 1',
              ),
              _SliverListTile(
                title: Text('Quest 1 - Create Account'),
                onTap: () => s1.createAccount(sdk: sdk, network: network),
              ),
              _SliverListTile(
                title: Text('Quest 2 - Send Payment'),
                onTap: () => s1.sendPayment(sdk: sdk, network: network),
              ),
              _SliverListTile(
                title: Text('Quest 3 - Manage Data'),
                onTap: () => s1.manageData(sdk: sdk, network: network),
              ),
              _SliverListTile(
                title: Text('Quest 4 - Multisign'),
                onTap: () => s1.multisign(sdk: sdk, network: network),
              ),
              _SliverListTile(
                title: Text('Quest 5 - Create And Send Custom Asset'),
                onTap: () =>
                    s1.createAndSendCustomAsset(sdk: sdk, network: network),
              ),
              _SliverListTile(
                title: Text('Quest 6 - Create Sell Offer Custom Asset'),
                onTap: () =>
                    s1.createSellOfferCustomAsset(sdk: sdk, network: network),
              ),
              _SliverListTile(
                title: Text('Quest 7 - Payment With Channel Account'),
                onTap: () =>
                    s1.paymentWithChannelAccount(sdk: sdk, network: network),
              ),
              _SliverListTile(
                title: Text('Quest 8 - Custom Path Payment'),
                onTap: () => s1.customPathPayment(sdk: sdk, network: network),
              ),
            ],
          ),
          _SliverPinnedHeader(
            text: 'Serie 2',
          ),
          _SliverListTile(
            title: Text('Quest 1 - Create And Fund Account'),
            onTap: () => s2.createAndFundAccount(sdk: sdk, network: network),
          ),
          _SliverListTile(
            title: Text('Quest 2 - Multi Operational Transaction'),
            onTap: () =>
                s2.multiOperationalTransaction(sdk: sdk, network: network),
          ),
          _SliverListTile(
            title: Text('Quest 3 - Fee Bump Transaction'),
            onTap: () => s2.feeBumpTransaction(sdk: sdk, network: network),
          ),
          _SliverListTile(
            title: Text('Quest 4 - Create Claimable Balance'),
            onTap: () => s2.createClaimableBalance(sdk: sdk, network: network),
          ),
          _SliverListTile(
            title: Text('Quest 5 - Claim Claimable Balance'),
            onTap: () => s2.claimClaimableBalance(sdk: sdk, network: network),
          ),
          _SliverListTile(
            title: Text('Quest 6 - Create Account Sponsored'),
            onTap: () => s2.createAccountSponsored(sdk: sdk, network: network),
          ),
          _SliverListTile(
            title: Text('Quest 7 - Revoke Sponsorship'),
            onTap: () => s2.revokeSponsorship(sdk: sdk, network: network),
          ),
          _SliverListTile(
            title: Text('Quest 8 - Host Stellar TOML File'),
            onTap: () => s2.hostStellarTomlFile(sdk: sdk, network: network),
          ),
        ],
      ),
    );
  }
}

class _SliverListTile extends StatelessWidget {
  const _SliverListTile({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  final Widget title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ListTile(
        title: title,
        onTap: onTap,
      ),
    );
  }
}

class _SliverPinnedHeader extends StatelessWidget {
  const _SliverPinnedHeader({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SliverPinnedHeader(
      child: Container(
        color: Colors.blueGrey,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }
}
