import 'package:flutter/material.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/wallets_profiles.dart';

class SearchProvider with ChangeNotifier {
  final searchController = TextEditingController();
  List searchResult = [];
  int resultLenght = 0;

  void reload() {
    notifyListeners();
  }

  Future<List<G1WalletsList>> searchAddress() async {
    if (isAddress(searchController.text)) {
      G1WalletsList wallet = G1WalletsList(address: searchController.text);
      return [wallet];
    } else {
      return [];
    }
  }
}
