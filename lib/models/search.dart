import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SearchProvider with ChangeNotifier {
  TextEditingController searchController = TextEditingController();

  void rebuildWidget() {
    notifyListeners();
  }

  void searchPubkey() {}
}
