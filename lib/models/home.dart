import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class HomeProvider with ChangeNotifier {
  int _currentIndex = 0;

  get currentIndex => _currentIndex;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    notifyListeners();
    return version + '+' + buildNumber;
  }

  Future<String> getRandomEndpoint() async {
    // TODO: Improve implemention of getRandomEndpoint()
    // final _json = json.decode(await getJsonEndpoints());
    // print('JSON !! :');
    // print(_json);
    // final _list = _json[];

    // final _listEndpoints = ['https://g1.librelois.fr/gva'];
    final _listEndpoints = [
      'https://g1.librelois.fr/gva',
      'https://duniter-gva.axiom-team.fr/gva'
    ];
    final _endpoint = getRandomElement(_listEndpoints);
    print('ENDPOINT: ' + _endpoint);

    // http.post(_endpoint);
    final response = await http.post(_endpoint);
    if (response.statusCode != 400) {
      print('Endpoint statutcode: ' + response.statusCode.toString());
      return 'HS';
    }

    return _endpoint;
  }

  Future getAppPath() async {
    appPath = await getApplicationDocumentsDirectory();
    walletsDirectory = Directory('${appPath.path}/wallets');

    bool isWalletFolderExist = await walletsDirectory.exists();

    if (!isWalletFolderExist) {
      await Directory(walletsDirectory.path).create();
    }
  }

  T getRandomElement<T>(List<T> list) {
    final random = new Random();
    var i = random.nextInt(list.length);
    return list[i];
  }
}
