import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<String> getValidEndpoint() async {
    List _listEndpoints = await rootBundle
        .loadString('config/gva_endpoints.json')
        .then((jsonStr) => jsonDecode(jsonStr));

    int i = 0;
    http.Response response;
    _listEndpoints.shuffle();
    String _endpoint;
    int statusCode = 0;

    final client = new HttpClient();
    client.connectionTimeout = const Duration(seconds: 1);

    do {
      i++;
      print(i.toString() + ' ème essai de recherche de endpoint GVA.');
      try {
        if (i > 5) {
          break;
        }
        if (i != 0) {
          await Future.delayed(Duration(milliseconds: 300));
        }
        response = await http
            .post(_listEndpoints[i])
            .timeout(const Duration(seconds: 1));
      } on TimeoutException catch (_) {
        print(_listEndpoints[i] + ' is timeout, next');
        statusCode = 50;

        continue;
      } on SocketException catch (_) {
        print(_listEndpoints[i] + ' is a bad endpoint, next');
        statusCode = 70;
        continue;
      }
      _endpoint = _listEndpoints[i];
      statusCode = response.statusCode;
      print('Endpoint statutcode: ' + statusCode.toString());
    } while (statusCode != 400);

    print('ENDPOINT: ' + _endpoint);
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

  Future createDefaultAvatar() async {
    File defaultAvatar = File(appPath.path + '/default_avatar.png');
    final bool isAvatarExist = await defaultAvatar.exists();
    if (!isAvatarExist) {
      final byteData = await rootBundle.load('assets/icon_user.png');
      await defaultAvatar.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
  }

  T getRandomElement<T>(List<T> list) {
    final random = new Random();
    var i = random.nextInt(list.length);
    return list[i];
  }
}
