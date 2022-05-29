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
  String homeMessage = "y'a pas de lézard ;-)";

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
    final oldMessage = homeMessage;
    homeMessage = newMessage;
    notifyListeners();
    await Future.delayed(Duration(seconds: seconds));
    homeMessage = oldMessage;
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

    // int i = 0;
    // String? _endpoint;
    // int _statusCode = 0;

    // final _client = HttpClient();
    // _client.connectionTimeout = const Duration(milliseconds: 1000);

    // do {
    //   i++;
    //   log.d(i.toString() + ' ème essai de recherche de endpoint GVA.');
    //   log.d('Try GVA endpoint: ${_listEndpoints[i - 1]}');
    //   int listLenght = _listEndpoints.length - 1;
    //   if (i > listLenght) {
    //     log.e('NO VALID GVA ENDPOINT FOUND');
    //     _endpoint = 'HS';
    //     break;
    //   }
    //   if (i != 0) {
    //     await Future.delayed(const Duration(milliseconds: 300));
    //   }

    //   try {
    //     final request = await _client.postUrl(Uri.parse(_listEndpoints[i]));
    //     final response = await request.close();

    //     _endpoint = _listEndpoints[i];
    //     _statusCode = response.statusCode;
    //   } on TimeoutException catch (_) {
    //     log.e('This endpoint is timeout, next');
    //     _statusCode = 50;
    //     continue;
    //   } on SocketException catch (_) {
    //     log.e('This endpoint is a bad endpoint, next');
    //     _statusCode = 70;
    //     continue;
    //   } on Exception {
    //     log.e('Unknown error');
    //     _statusCode = 60;
    //     continue;
    //   }
    // } while (_statusCode != 400);

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

    const bool _showBottomBar = true;

    return Visibility(
      visible: _showBottomBar,
      child: Container(
        color: yellowC,
        width: double.infinity,
        height: 80,
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Spacer(flex: 1),
            IconButton(
              iconSize: 40,
              icon: const Image(image: AssetImage('assets/loupe-noire.png')),
              onPressed: () {
                // Navigator.popUntil(
                //   context,
                //   ModalRoute.withName('/'),
                // );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return const SearchScreen();
                  }),
                );
              },
            ),
            // SizedBox(width: 0),
            const Spacer(flex: 2),
            IconButton(
              iconSize: 60,
              icon: const Image(image: AssetImage('assets/qrcode-scan.png')),
              onPressed: () async {
                // Navigator.popUntil(
                //   context,
                //   ModalRoute.withName('/'),
                // );
                await _historyProvider.scan(context);
              },
            ),
            const Spacer(flex: 2),
            IconButton(
              iconSize: 60,
              icon: const Image(image: AssetImage('assets/wallet.png')),
              onPressed: () {
                WalletData? defaultWallet =
                    _myWalletProvider.getDefaultWallet();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return UnlockingWallet(
                        wallet: defaultWallet,
                        action: "mywallets",
                      );
                    },
                  ),
                );
              },
            ),
            const Spacer(flex: 1),
          ],
        ),
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
