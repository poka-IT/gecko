import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  void reload() {
    notifyListeners();
  }
}
