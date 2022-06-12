import 'dart:convert';
import 'dart:io';
import 'dart:math';
// import 'package:audioplayers/audio_cache.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/screens/search.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class HomeProvider with ChangeNotifier {
  bool? isSearching;
  Icon searchIcon = const Icon(Icons.search);
  final TextEditingController searchQuery = TextEditingController();
  Widget appBarTitle = Text('Ğecko', style: TextStyle(color: Colors.grey[850]));
  Widget appBarExplorer =
      Text('Explorateur', style: TextStyle(color: Colors.grey[850]));
  String homeMessage = "Chargement en cours ...";
  String defaultMessage = "y'a pas de lézard ;-)";

  Future<void> initHive() async {
    late Directory hivePath;

    if (!kIsWeb) {
      if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        hivePath = Directory('$home/.gecko/db');
      } else if (Platform.isWindows) {
        final home = Platform.environment['UserProfile'];
        hivePath = Directory('$home/.gecko/db');
      } else if (Platform.isAndroid || Platform.isIOS) {
        final home = await pp.getApplicationDocumentsDirectory();
        hivePath = Directory('${home.path}/db');
      }
      if (!await hivePath.exists()) {
        await hivePath.create(recursive: true);
      }
      await Hive.initFlutter(hivePath.path);
    } else {
      await Hive.initFlutter();
    }

    // Init app folders
    final documentDir = await getApplicationDocumentsDirectory();
    imageDirectory = Directory('${documentDir.path}/images');

    if (!await imageDirectory.exists()) {
      await imageDirectory.create();
    }
  }

  Future<String> getAppVersion() async {
    String version;
    String buildNumber;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    buildNumber = kDebugMode
        ? packageInfo.buildNumber
        : (int.parse(packageInfo.buildNumber) - 1000).toString();

    notifyListeners();
    return version + '+' + buildNumber;
  }

  Future changeMessage(String newMessage, int seconds) async {
    homeMessage = newMessage;
    notifyListeners();
    await Future.delayed(Duration(seconds: seconds));
    if (seconds != 0) homeMessage = defaultMessage;
    notifyListeners();
  }

  Future<List?> getValidEndpoints() async {
    await configBox.delete('endpoint');

    List _listEndpoints = [];
    if (!configBox.containsKey('endpoint') ||
        configBox.get('endpoint') == [] ||
        configBox.get('endpoint') == '') {
      _listEndpoints = await rootBundle
          .loadString('config/gdev_endpoints.json')
          .then((jsonStr) => jsonDecode(jsonStr));
      _listEndpoints.shuffle();
      configBox.put('endpoint', _listEndpoints);
    }

    log.i('ENDPOINT: ' + _listEndpoints.toString());
    return _listEndpoints;
  }

  T getRandomElement<T>(List<T> list) {
    final random = Random();
    var i = random.nextInt(list.length);
    return list[i];
  }

  void handleSearchStart() {
    isSearching = true;
    notifyListeners();
  }

  // void playSound(String customSound, double volume) async {
  //   await player.play('$customSound.wav',
  //       volume: volume, mode: PlayerMode.LOW_LATENCY, stayAwake: false);
  // }

  Widget bottomAppBar(BuildContext context) {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    WalletsProfilesProvider _historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);

    final size = MediaQuery.of(context).size;

    const bool _showBottomBar = true;

    return Visibility(
      visible: _showBottomBar,
      child: Container(
        color: yellowC,
        width: size.width,
        height: 80,
        child:
            // Stack(
            //   children: [
            //     // CustomPaint(
            //     //   size: Size(size.width, 110),
            //     //   painter: CustomRoundedButton(),
            //     // ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          // SizedBox(width: 0),
          const Spacer(),
          const SizedBox(width: 11),
          IconButton(
            iconSize: 40,
            icon: const Image(image: AssetImage('assets/loupe-noire.png')),
            onPressed: () {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (homeContext) {
                  return const SearchScreen();
                }),
              );
            },
          ),
          const SizedBox(width: 22),
          const Spacer(),
          IconButton(
            iconSize: 70,
            icon: const Image(image: AssetImage('assets/qrcode-scan.png')),
            onPressed: () async {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
              _historyProvider.scan(homeContext);
            },
          ),
          const Spacer(),
          const SizedBox(width: 15),
          IconButton(
            iconSize: 60,
            icon: const Image(image: AssetImage('assets/wallet.png')),
            onPressed: () async {
              WalletData? defaultWallet = _myWalletProvider.getDefaultWallet();
              String? _pin;
              if (_myWalletProvider.pinCode == '') {
                _pin = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (homeContext) {
                      return UnlockingWallet(wallet: defaultWallet);
                    },
                  ),
                );
              }

              if (_pin != null || _myWalletProvider.pinCode != '') {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return const WalletsHome();
                  }),
                );
              }
            },
          ),
          const Spacer(),
        ]),
      ),
    );
  }

  void handleSearchEnd() {
    searchIcon = Icon(
      Icons.search,
      color: Colors.grey[850],
    );
    appBarTitle = Text('Ğecko', style: TextStyle(color: Colors.grey[850]));
    appBarExplorer =
        Text('Explorateur', style: TextStyle(color: Colors.grey[850]));
    isSearching = false;
    searchQuery.clear();

    notifyListeners();
  }

  void rebuildWidget() {
    notifyListeners();
  }
}

class CustomRoundedButton extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = yellowC
      ..style = PaintingStyle.fill;
    Path path = Path();
    path.lineTo(size.width * 0.4, 0);
    path.quadraticBezierTo(size.width * 0.5, -40, size.width * 0.6, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
