import 'package:flutter/material.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

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
      home: MyHomePage(title: 'Stellar Flutter SDK Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = "";
  StellarSDK sdk = StellarSDK.TESTNET;
  void _btPress() {
    setState(() {
      KeyPair kp = KeyPair.random();
      _message = "ID:\n" +  kp.accountId + "\n\nSEED:\n" + kp.secretSeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              '\nGenerate new random keypar\n\n',
              style: Theme.of(context).textTheme.headline6,
            ),
            Text(
              '$_message',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _btPress,
        tooltip: 'Press',
        child: Icon(Icons.add_circle),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
