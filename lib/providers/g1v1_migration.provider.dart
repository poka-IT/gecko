import 'package:durt2/durt2.dart';
import 'package:flutter/material.dart';

class G1v1MigrationProvider extends ChangeNotifier {
  String g1V1NewAddress = '';
  String g1V1OldPubkey = '';
  final csSalt = TextEditingController();
  final csPassword = TextEditingController();
  bool isCesiumIDVisible = false;
  bool isCesiumPasswordVisible = false;

  void cesiumIDisVisible() {
    isCesiumIDVisible = !isCesiumIDVisible;
    notifyListeners();
  }

  void cesiumPasswordisVisible() {
    isCesiumPasswordVisible = !isCesiumPasswordVisible;
    notifyListeners();
  }

  void reload() {
    notifyListeners();
  }

  Future<void> csToV2Address() async {
    final result = await Durt.i.utils.csToV2Address(csSalt.text, csPassword.text);
    g1V1NewAddress = result.address;
    g1V1OldPubkey = result.pubkey;
    notifyListeners();
  }
}
