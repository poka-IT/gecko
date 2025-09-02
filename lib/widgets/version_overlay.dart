import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/home_providers.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:provider/provider.dart' as flutter_provider;
import 'package:gecko/globals.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers/theme_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'dart:convert';
import 'dart:io';

// Provider for copy state indication
final versionCopyStateProvider = StateNotifierProvider<CopyStateNotifier, bool>((ref) {
  return CopyStateNotifier();
});

class CopyStateNotifier extends StateNotifier<bool> {
  CopyStateNotifier() : super(false);

  void setCopied() {
    state = true;
    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) state = false;
    });
  }
}

class VersionOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const VersionOverlay({super.key, required this.child});

  @override
  ConsumerState<VersionOverlay> createState() => _VersionOverlayState();
}

class _VersionOverlayState extends ConsumerState<VersionOverlay> {
  Map<String, dynamic> _getProviderStates() {
    final providerStates = <String, dynamic>{};

    try {
      // Flutter Provider states
      final homeMessage = ref.read(homeMessageProvider);
      providerStates['home'] = {'message': homeMessage};

      final myWalletsProvider = flutter_provider.Provider.of<MyWalletsProvider>(context, listen: false);
      providerStates['wallets'] = {
        'count': myWalletsProvider.listWallets.length,
        'exists': myWalletsProvider.isWalletsExists,
        'current_safe': myWalletsProvider.getCurrentSafe,
        'pin_valid': myWalletsProvider.isPinValid,
        'pin_loading': myWalletsProvider.isPinLoading,
      };

      final connectionStatus = ref.read(connectionStatusProvider);
      providerStates['connection'] = {'status': connectionStatus.name};

      final currentThemeMode = ref.read(currentThemeModeProvider);
      providerStates['theme'] = {'mode': currentThemeMode.name};
    } catch (e) {
      providerStates['error'] = e.toString();
    }

    return providerStates;
  }

  Map<String, dynamic> _getRiverpodStates() {
    final riverpodStates = <String, dynamic>{};

    try {
      // Connection status providers
      final connectionStatus = ref.read(connectionStatusProvider);
      final duniterConnectionStatus = ref.read(duniterConnectionStatusProvider);
      final squidConnectionStatus = ref.read(squidConnectionStatusProvider);

      riverpodStates['connections'] = {
        'combined': connectionStatus.name,
        'duniter': duniterConnectionStatus.name,
        'squid': squidConnectionStatus.name,
      };

      // Services state
      final network = ref.read(networkProvider);
      final squidLoading = ref.read(squidLoadingProvider);
      final universalDividendsToggle = ref.read(universalDividendsToggleProvider);

      riverpodStates['services'] = {
        'network': network.name,
        'squid_loading': squidLoading,
        'universal_dividends': universalDividendsToggle,
      };

      // Wallet service state
      final walletService = ref.read(walletServiceProvider);
      riverpodStates['wallet_service'] = {
        'default_safe': walletService.defaultSafeBoxNumber,
        'safes_count': walletService.safeBox.count(),
        'is_empty': walletService.safeBox.isEmpty(),
      };
    } catch (e) {
      riverpodStates['error'] = e.toString();
    }

    return riverpodStates;
  }

  Map<String, dynamic> _getAuthenticationDebugInfo() {
    final authInfo = <String, dynamic>{};

    try {
      // PIN and authentication state
      final myWalletsProvider = flutter_provider.Provider.of<MyWalletsProvider>(context, listen: false);
      authInfo['pin_state'] = {
        'is_valid': myWalletsProvider.isPinValid,
        'is_loading': myWalletsProvider.isPinLoading,
        'pin_length': myWalletsProvider.pinLenght ?? 'null',
        'current_pin_code_empty': PinCodeService.pinCode.isEmpty,
      };

      // Safe and wallet state
      authInfo['safe_state'] = {
        'current_safe': myWalletsProvider.getCurrentSafe,
        'wallets_exist': myWalletsProvider.isWalletsExists,
        'wallets_count': myWalletsProvider.listWallets.length,
        'last_fly_by': myWalletsProvider.lastFlyBy?.address ?? 'null',
      };

      // Database state
      authInfo['database'] = {
        'config_box_keys': configBox.keys.length,
        'config_box_values': configBox.values.length,
        'config_box_is_open': configBox.isOpen,
      };
    } catch (e) {
      authInfo['error'] = e.toString();
    }

    return authInfo;
  }

  Map<String, dynamic> _getIndexerDebugInfo() {
    final indexerInfo = <String, dynamic>{};

    try {
      // Durt services state
      final durt = ref.read(durtProvider);
      indexerInfo['network'] = {'name': durt.network.name, 'genesis_hash': durt.network.genesisHash};

      // Connection states
      indexerInfo['connection_status'] = {
        'duniter': durt.duniterConnectionStatus.name,
        'squid': durt.squidConnectionStatus.name,
      };

      // Endpoint information would need to be added here
      // This requires access to the actual endpoints being used
    } catch (e) {
      indexerInfo['error'] = e.toString();
    }

    return indexerInfo;
  }

  Map<String, dynamic> _getSystemHealthInfo() {
    final healthInfo = <String, dynamic>{};

    try {
      // App state health
      healthInfo['app_state'] = {
        'widget_mounted': mounted,
        'has_context': context.mounted,
        'media_query_available': MediaQuery.maybeOf(context) != null,
        'theme_brightness': Theme.of(context).brightness.name,
      };

      // System info
      healthInfo['system'] = {
        'processors': Platform.numberOfProcessors,
        'locale': Platform.localeName,
        'timezone': DateTime.now().timeZoneName,
      };

      // Memory and storage
      healthInfo['resources'] = {
        'storage_keys': configBox.keys.length,
        'platform_env_keys': Platform.environment.keys.take(3).toList(),
      };
    } catch (e) {
      healthInfo['error'] = e.toString();
    }

    return healthInfo;
  }

  String _generateDiagnosticReport() {
    try {
      final diagnosticData = {
        'timestamp': DateTime.now().toIso8601String(),
        'app_info': {
          'version': appVersion,
          'platform': Platform.operatingSystem,
          'os_version': Platform.operatingSystemVersion,
          'locale': Platform.localeName,
          'dart_version': Platform.version,
        },
        'device_info': {
          'screen_size': '${MediaQuery.of(context).size.width}x${MediaQuery.of(context).size.height}',
          'device_pixel_ratio': MediaQuery.of(context).devicePixelRatio,
          'text_scale_factor': MediaQuery.of(context).textScaler.scale(14),
          'platform_brightness': MediaQuery.of(context).platformBrightness.name,
          'safe_area_bottom': MediaQuery.of(context).padding.bottom,
          'safe_area_top': MediaQuery.of(context).padding.top,
        },
        'debug_info': {
          'is_debug_mode': !const bool.fromEnvironment('dart.vm.product'),
          'build_mode': const String.fromEnvironment('flutter.mode', defaultValue: 'unknown'),
          'flutter_version': const String.fromEnvironment('flutter.version', defaultValue: 'unknown'),
        },
        'providers_state': _getProviderStates(),
        'riverpod_state': _getRiverpodStates(),
        'durt_storage_status': _getDurtStorageStatus(),
        'authentication_debug': _getAuthenticationDebugInfo(),
        'indexer_debug': _getIndexerDebugInfo(),
        'system_health': _getSystemHealthInfo(),
      };

      return const JsonEncoder.withIndent('  ').convert(diagnosticData);
    } catch (e) {
      return 'Error generating diagnostic report: $e';
    }
  }

  void _copyDiagnosticReport() {
    final jsonReport = _generateDiagnosticReport();
    Clipboard.setData(ClipboardData(text: jsonReport));

    // Change state to indicate success
    ref.read(versionCopyStateProvider.notifier).setCopied();

    // Show a brief snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostic report copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  Map<String, dynamic> _getDurtStorageStatus() {
    try {
      final durt = ref.read(durtProvider);
      return {
        'storage_available': true,
        'storage_mode': durt.isStorageOfflineMode ? 'offline' : 'online',
        'duniter_endpoint': durt.endpoint,
        'squid_endpoint': durt.squidEndpoint,
      };
    } catch (e) {
      return {'storage_available': false, 'storage_mode': 'error', 'duniter_endpoint': null, 'squid_endpoint': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to avoid system navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isCopied = ref.watch(versionCopyStateProvider);

    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 8 + bottomPadding,
          left: 16,
          child: GestureDetector(
            onTap: _copyDiagnosticReport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isCopied ? Colors.green.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'v$appVersion',
                style: TextStyle(
                  fontSize: 8,
                  color: isCopied ? Colors.green : Colors.grey.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
