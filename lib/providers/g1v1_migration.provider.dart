import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:durt2/durt2.dart' show CsToV2AddressResult;
import 'package:gecko/providers/providers.dart';

/// State class for G1v1 migration data
class G1v1MigrationState {
  final String g1V1NewAddress;
  final String g1V1OldPubkey;
  final bool isCesiumIDVisible;
  final bool isCesiumPasswordVisible;

  const G1v1MigrationState({
    this.g1V1NewAddress = '',
    this.g1V1OldPubkey = '',
    this.isCesiumIDVisible = false,
    this.isCesiumPasswordVisible = false,
  });

  G1v1MigrationState copyWith({
    String? g1V1NewAddress,
    String? g1V1OldPubkey,
    bool? isCesiumIDVisible,
    bool? isCesiumPasswordVisible,
  }) {
    return G1v1MigrationState(
      g1V1NewAddress: g1V1NewAddress ?? this.g1V1NewAddress,
      g1V1OldPubkey: g1V1OldPubkey ?? this.g1V1OldPubkey,
      isCesiumIDVisible: isCesiumIDVisible ?? this.isCesiumIDVisible,
      isCesiumPasswordVisible: isCesiumPasswordVisible ?? this.isCesiumPasswordVisible,
    );
  }
}

/// State notifier for G1v1 migration
class G1v1MigrationNotifier extends StateNotifier<G1v1MigrationState> {
  final Ref _ref;

  G1v1MigrationNotifier(this._ref) : super(const G1v1MigrationState());

  /// Toggle visibility of Cesium ID field
  void toggleCesiumIDVisibility() {
    state = state.copyWith(isCesiumIDVisible: !state.isCesiumIDVisible);
  }

  /// Toggle visibility of Cesium password field
  void toggleCesiumPasswordVisibility() {
    state = state.copyWith(isCesiumPasswordVisible: !state.isCesiumPasswordVisible);
  }

  /// Convert Cesium salt and password to V2 address
  Future<void> convertCsToV2Address(String salt, String password) async {
    try {
      final utils = _ref.read(utilsProvider);
      final result = await utils.csToV2Address(salt, password);

      state = state.copyWith(g1V1NewAddress: result.address, g1V1OldPubkey: result.pubkey);
    } catch (e) {
      // Reset the values on error
      state = state.copyWith(g1V1NewAddress: '', g1V1OldPubkey: '');
      rethrow;
    }
  }

  /// Reset all state to initial values
  void reset() {
    state = const G1v1MigrationState();
  }
}

/// Text controller state notifier
class TextControllerNotifier extends StateNotifier<TextEditingController> {
  TextControllerNotifier() : super(TextEditingController());

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }
}

/// Main G1v1 migration state provider
final g1v1MigrationProvider = StateNotifierProvider<G1v1MigrationNotifier, G1v1MigrationState>((ref) {
  return G1v1MigrationNotifier(ref);
});

/// Provider for Cesium salt TextEditingController
final csSaltControllerProvider = StateNotifierProvider<TextControllerNotifier, TextEditingController>((ref) {
  return TextControllerNotifier();
});

/// Provider for Cesium password TextEditingController
final csPasswordControllerProvider = StateNotifierProvider<TextControllerNotifier, TextEditingController>((ref) {
  return TextControllerNotifier();
});

/// Helper provider to convert CS credentials to V2 address with the current controller values
final csToV2AddressWithControllersProvider = FutureProvider<CsToV2AddressResult?>((ref) async {
  final saltController = ref.watch(csSaltControllerProvider);
  final passwordController = ref.watch(csPasswordControllerProvider);

  final salt = saltController.text.trim();
  final password = passwordController.text.trim();

  if (salt.isEmpty || password.isEmpty) {
    return null;
  }

  try {
    final utils = ref.read(utilsProvider);
    return await utils.csToV2Address(salt, password);
  } catch (e) {
    return null;
  }
});

/// Legacy adapter class to maintain compatibility with existing code
/// This allows existing usage patterns to work while transitioning to Riverpod
class G1v1MigrationProvider extends ChangeNotifier {
  final ProviderContainer _container;

  G1v1MigrationProvider() : _container = ProviderContainer() {
    // Listen to state changes and notify legacy listeners
    _container.listen(g1v1MigrationProvider, (prev, next) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  // Getters that delegate to the Riverpod state
  String get g1V1NewAddress => _container.read(g1v1MigrationProvider).g1V1NewAddress;
  String get g1V1OldPubkey => _container.read(g1v1MigrationProvider).g1V1OldPubkey;
  bool get isCesiumIDVisible => _container.read(g1v1MigrationProvider).isCesiumIDVisible;
  bool get isCesiumPasswordVisible => _container.read(g1v1MigrationProvider).isCesiumPasswordVisible;

  TextEditingController get csSalt => _container.read(csSaltControllerProvider);
  TextEditingController get csPassword => _container.read(csPasswordControllerProvider);

  // Methods that delegate to the Riverpod notifier
  void cesiumIDisVisible() {
    _container.read(g1v1MigrationProvider.notifier).toggleCesiumIDVisibility();
  }

  void cesiumPasswordisVisible() {
    _container.read(g1v1MigrationProvider.notifier).toggleCesiumPasswordVisibility();
  }

  void reload() {
    notifyListeners();
  }

  Future<void> csToV2Address() async {
    final salt = csSalt.text;
    final password = csPassword.text;
    await _container.read(g1v1MigrationProvider.notifier).convertCsToV2Address(salt, password);
  }

  // Additional setter methods for direct assignment compatibility
  set g1V1NewAddress(String value) {
    if (value.isEmpty) {
      _container.read(g1v1MigrationProvider.notifier).reset();
    }
  }

  set g1V1OldPubkey(String value) {
    if (value.isEmpty) {
      _container.read(g1v1MigrationProvider.notifier).reset();
    }
  }
}

/// Convenience methods for backward compatibility with the legacy provider
extension G1v1MigrationProviderExtensions on WidgetRef {
  /// Get the migration state
  G1v1MigrationState get g1v1MigrationState => watch(g1v1MigrationProvider);

  /// Get the migration notifier
  G1v1MigrationNotifier get g1v1MigrationNotifier => read(g1v1MigrationProvider.notifier);

  /// Get the salt controller
  TextEditingController get csSaltController => watch(csSaltControllerProvider);

  /// Get the password controller
  TextEditingController get csPasswordController => watch(csPasswordControllerProvider);
}
