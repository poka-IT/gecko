import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durt2/durt2.dart' show CsToV2AddressResult;
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/g1v1_migration_service.dart';

/// State for G1v1 migration UI visibility flags
class G1v1MigrationUiState {
  final bool isCesiumIDVisible;
  final bool isCesiumPasswordVisible;

  const G1v1MigrationUiState({this.isCesiumIDVisible = false, this.isCesiumPasswordVisible = false});

  G1v1MigrationUiState copyWith({bool? isCesiumIDVisible, bool? isCesiumPasswordVisible}) {
    return G1v1MigrationUiState(
      isCesiumIDVisible: isCesiumIDVisible ?? this.isCesiumIDVisible,
      isCesiumPasswordVisible: isCesiumPasswordVisible ?? this.isCesiumPasswordVisible,
    );
  }
}

/// Notifier for G1v1 migration UI visibility
class G1v1MigrationUiNotifier extends Notifier<G1v1MigrationUiState> {
  @override
  G1v1MigrationUiState build() {
    return const G1v1MigrationUiState();
  }

  /// Toggle visibility of Cesium ID field
  void toggleCesiumIDVisibility() {
    state = state.copyWith(isCesiumIDVisible: !state.isCesiumIDVisible);
  }

  /// Toggle visibility of Cesium password field
  void toggleCesiumPasswordVisibility() {
    state = state.copyWith(isCesiumPasswordVisible: !state.isCesiumPasswordVisible);
  }

  /// Reset UI state
  void reset() {
    state = const G1v1MigrationUiState();
  }
}

/// Provider for G1v1 migration UI state
final g1v1MigrationUiProvider = NotifierProvider<G1v1MigrationUiNotifier, G1v1MigrationUiState>(G1v1MigrationUiNotifier.new);

/// Provider for Cesium salt TextEditingController
final csSaltControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Provider for Cesium password TextEditingController
final csPasswordControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Provider to convert CS credentials to V2 address with the current controller values
final csToV2AddressProvider = FutureProvider.autoDispose<CsToV2AddressResult?>((ref) async {
  final saltController = ref.watch(csSaltControllerProvider);
  final passwordController = ref.watch(csPasswordControllerProvider);

  final salt = saltController.text.trim();
  final password = passwordController.text.trim();

  if (!G1v1MigrationService.isValidCredentials(salt, password)) {
    return null;
  }

  try {
    final utils = ref.read(utilsProvider);
    return await G1v1MigrationService.convertCsToV2Address(utils: utils, salt: salt, password: password);
  } catch (e) {
    return null;
  }
});
