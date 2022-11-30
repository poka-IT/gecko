import 'package:flutter/material.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/wallets_profiles.dart';

class SearchProvider with ChangeNotifier {
  TextEditingController searchController = TextEditingController();
  List searchResult = [];
  final cacheDuring = 20 * 60 * 1000; //First number is minutes
  int cacheTime = 0;

  void reload() {
    notifyListeners();
  }

  // Future<List> searchBlockchain() async {
  //   searchResult.clear();
  //   int searchTime = DateTime.now().millisecondsSinceEpoch;
  //   WalletsProfilesProvider _walletProfiles = WalletsProfilesProvider('pubkey');

  //   if (cacheTime + cacheDuring <= searchTime) {
  //     g1WalletsBox.clear();
  //     // final url = Uri.parse('https://g1-stats.axiom-team.fr/data/forbes.json');
  //     // final response = await http.get(url);

  //     var dio = Dio();
  //     late Response response;
  //     try {
  //       response = await dio.get(
  //         'https://g1-stats.axiom-team.fr/data/forbes.json',
  //         options: Options(
  //           sendTimeout: 5000,
  //           receiveTimeout: 10000,
  //         ),
  //       );
  //       // response = await http.post((Uri.parse(queryOptions[0])),
  //       //     body: queryOptions[1], headers: queryOptions[2]);
  //     } catch (e) {
  //       log.e(e);
  //     }

  //     List<G1WalletsList> _listWallets = _parseG1Wallets(response.data)!;
  //     Map<String?, G1WalletsList> _mapWallets = {
  //       for (var e in _listWallets) e.pubkey: e
  //     };

  //     await g1WalletsBox.putAll(_mapWallets);
  //     cacheTime = DateTime.now().millisecondsSinceEpoch;
  //   }

  //   g1WalletsBox.toMap().forEach((key, value) {
  //     if ((value.id != null &&
  //             value.id!.username != null &&
  //             value.id!.username!
  //                 .toLowerCase()
  //                 .contains(searchController.text)) ||
  //         value.pubkey!.contains(searchController.text)) {
  //       searchResult.add(value);
  //       return;
  //     }
  //   });

  //   if (searchResult.isEmpty &&
  //       _walletProfiles.isPubkey(searchController.text)) {
  //     searchResult = [G1WalletsList(pubkey: searchController.text)];
  //   }

  //   return searchResult;
  // }

  Future<List<G1WalletsList>> searchAddress() async {
    final walletProfiles =
        WalletsProfilesProvider('pubkey');

    if (walletProfiles.isAddress(searchController.text)) {
      G1WalletsList wallet = G1WalletsList(address: searchController.text);
      return [wallet];
    } else {
      return [];
    }
  }
}

// List<G1WalletsList>? _parseG1Wallets(var responseBody) {
//   final parsed = responseBody.cast<Map<String, dynamic>>();

//   return parsed
//       .map<G1WalletsList>((json) => G1WalletsList.fromJson(json))
//       .toList();
// }
