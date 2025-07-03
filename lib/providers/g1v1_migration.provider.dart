import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';

class G1v1MigrationProvider extends ChangeNotifier {
  late ProviderContainer _container;

  G1v1MigrationProvider() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

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
    final result = await _container.read(utilsProvider).csToV2Address(csSalt.text, csPassword.text);
    g1V1NewAddress = result.address;
    g1V1OldPubkey = result.pubkey;
    notifyListeners();
  }
}
