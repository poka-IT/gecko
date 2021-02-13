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

class HomeProvider with ChangeNotifier {
  int _currentIndex = 0;

  get currentIndex => _currentIndex;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<String> getAppVersion() async {
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
    _listEndpoints.shuffle();

    int i = 0;
    String _endpoint;
    int _statusCode = 0;

    final _client = new HttpClient();
    _client.connectionTimeout = const Duration(milliseconds: 800);

    do {
      i++;
      print(i.toString() + ' ème essai de recherche de endpoint GVA.');
      print('Try GVA endpoint: ${_listEndpoints[i]}');
      if (i > 2) {
        print('NO VALID GVA ENDPOINT FOUND');
        _endpoint = 'HS';
        break;
      }
      if (i != 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      try {
        final request = await _client.postUrl(Uri.parse(_listEndpoints[i]));
        final response = await request.close();

        _endpoint = _listEndpoints[i];
        _statusCode = response.statusCode;
      } on TimeoutException catch (_) {
        print('This endpoint is timeout, next');
        _statusCode = 50;
        continue;
      } on SocketException catch (_) {
        print('This endpoint is a bad endpoint, next');
        _statusCode = 70;
        continue;
      } on Exception {
        print('Unknown error');
        _statusCode = 60;
        continue;
      }
    } while (_statusCode != 400);

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
