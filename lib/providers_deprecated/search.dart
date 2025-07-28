import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';

class SearchProvider with ChangeNotifier {
  final searchController = TextEditingController();
  bool canPasteAddress = false;
  String pastedAddress = '';

  void reload() {
    notifyListeners();
  }

  Future<List<G1WalletsList>> searchAddress() async {
    late String address;
    if (isAddress(searchController.text)) {
      address = isAddressValidToSs58(searchController.text);
    } else if (isPubkey(searchController.text)) {
      address = ProviderContainer().read(utilsProvider).pubkeyV1ToAddress(searchController.text);
    } else {
      return [];
    }
    G1WalletsList wallet = G1WalletsList(address: address);
    return [wallet];
  }
}
