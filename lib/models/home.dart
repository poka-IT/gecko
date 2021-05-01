import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/history.dart';
import 'package:gecko/screens/myWallets/walletsHome.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';

class HomeProvider with ChangeNotifier {
  int _currentIndex = 0;
  bool isSearching;
  Icon searchIcon = Icon(Icons.search);
  final TextEditingController searchQuery = new TextEditingController();
  Widget appBarTitle = Text('Ğecko', style: TextStyle(color: Colors.grey[850]));
  Widget appBarExplorer =
      Text('Explorateur', style: TextStyle(color: Colors.grey[850]));

  List currentTab = [HistoryScreen(), WalletsHome()];
  AudioCache player = AudioCache(prefix: 'sounds/');

  get currentIndex => _currentIndex;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<String> getAppVersion() async {
    String version;
    String buildNumber;
    if (Platform.isLinux) {
      version = "undefined";
      buildNumber = "undefined";
    } else {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    }

    notifyListeners();
    return version + '+' + buildNumber;
  }

  Future<List<String>> scanNetwork() async {
    // TODO: return all known endpoints from current window
    // - Request all bootstrap endpoints to get theres current bloc number and hash (blockstamps), and theres known endpoinds
    // - Store them in an ordered Map (SplayTreeMap<Blockstamp, HashSet<String>>) (the HashSet is a endpoint)
    // - Request 5 randoms endpoints known by the last slave, only theses we don't even know
    // - Do it 3 times
    // - We iterate the Map to determinat the consensus with for loop, intinital consensus variable to null
    // - if consensus == null -> if blockstamp > (1/3 known endpoints) -> consensus = blockstamp
    // - elif blockstamp.number == consensus.number && blockstamp.endpointNumbers > consensus.endpointNumbers -> consensus = blockstamp
    // - else break;
    // - return map.get(key: consensus).toList

    var blockstampMap = SplayTreeMap<Blockstamp, String>();

    List _endpointsToScan = [];
    _endpointsToScan = await rootBundle
        .loadString('config/gva_endpoints.json')
        .then((jsonStr) => jsonDecode(jsonStr));

    // Loop on endpoints
    Future loopEndpoints(List _endpoints) async {
      for (String _endpoint in _endpoints) {
        print("Endpoint: $_endpoint");
        final HttpLink httpLink = HttpLink(
          _endpoint,
        );

        final GraphQLClient client = GraphQLClient(
          /// **NOTE** The default store is the InMemoryStore, which does NOT persist to disk
          cache: GraphQLCache(),
          link: httpLink,
        );

        // Get current blockstamp for this endpoint and get known endpoints of this node
        const String getBlockstampAndEndpoints = r'''
      query {
        network {
          endpoints (apiList: "GVA")
        }
        currentBlock {
          number
          hash
        }
      }
      ''';

        final QueryOptions options = QueryOptions(
          document: gql(getBlockstampAndEndpoints),
          variables: <String, dynamic>{},
        );

        final QueryResult result = await client.query(options);

        if (result.hasException) {
          print(result.exception.toString());
        }

        // Get current blockstamp
        int _blockNumber = result.data['currentBlock']['number'];
        String _hash = result.data['currentBlock']['hash'];

        Blockstamp _blockstamp = Blockstamp(_blockNumber, _hash);

        // Store Map blockstamp and endpoints
        print("$_blockstamp $_endpoint");
        blockstampMap.putIfAbsent(_blockstamp, () => _endpoint);

        // Get known endpoints
        _endpointsToScan.clear();
        for (String _brutEndPoint in result.data['network']['endpoints']) {
          String _httpEndPoint;
          int _port = int.parse(_brutEndPoint.split(' ')[3]);
          String _path = _brutEndPoint.split(' ')[4];
          if (_port == 443) {
            _httpEndPoint = "https://${_brutEndPoint.split(' ')[2]}/$_path";
          } else {
            _httpEndPoint =
                "http://${_brutEndPoint.split(' ')[2]}:$_port/$_path";
          }

          _endpointsToScan.add((_httpEndPoint));
        } // end of known endpoints by node loop
      } // end of endpoints loop
    }

    for (int i = 0; i < 3; i++) {
      await loopEndpoints(_endpointsToScan);
    }

    for (int i = 0; i < 5; i++) {
      endPointGVA.add(blockstampMap.values.toList()[i]);
      endPointGVA.shuffle();
    }

    return endPointGVA;
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
    _client.connectionTimeout = const Duration(milliseconds: 1000);

    do {
      i++;
      log.d(i.toString() + ' ème essai de recherche de endpoint GVA.');
      log.d('Try GVA endpoint: ${_listEndpoints[i - 1]}');
      int listLenght = _listEndpoints.length - 1;
      if (i > listLenght) {
        log.e('NO VALID GVA ENDPOINT FOUND');
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
        log.e('This endpoint is timeout, next');
        _statusCode = 50;
        continue;
      } on SocketException catch (_) {
        log.e('This endpoint is a bad endpoint, next');
        _statusCode = 70;
        continue;
      } on Exception {
        log.e('Unknown error');
        _statusCode = 60;
        continue;
      }
    } while (_statusCode != 400);

    log.i('ENDPOINT: ' + _endpoint);
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
    final random = Random();
    var i = random.nextInt(list.length);
    return list[i];
  }

  void handleSearchStart() {
    isSearching = true;
    notifyListeners();
  }

  void playSound(String customSound, double volume) async {
    await player.play('$customSound.wav',
        volume: volume, mode: PlayerMode.LOW_LATENCY, stayAwake: false);
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

class Blockstamp {
  int blockNumber;
  String hash;
  String blockstamp;
  Blockstamp(int _blockNumber, String _hash) {
    this.blockNumber = _blockNumber;
    this.hash = _hash;
    this.blockstamp = _blockNumber.toString() + _hash;
  }

  // representation of blockstamp when debugging
  @override
  String toString() {
    return this.blockstamp;
  }
}
