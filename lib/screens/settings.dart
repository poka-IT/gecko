// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show Networks, ConnectionStatus, Durt, Utils;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/text_size_mode.dart';
import 'package:gecko/providers/text_scaling_provider.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/currency_provider.dart';

import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/providers/theme_provider.dart';
import 'package:gecko/providers/trm_data_provider.dart';

import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final FocusNode _duniterFocusNode = FocusNode();
  final FocusNode _indexerFocusNode = FocusNode();
  late TextEditingController _endpointController;
  late TextEditingController _indexerEndpointController;
  bool _duniterConnectionFailed = false;
  bool _indexerConnectionFailed = false;
  bool _expertMode = false;
  bool _isSwitchingNetwork = false;
  bool _isEditingDuniter = false;
  bool _isEditingIndexer = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _expertMode = configBox.get('expertMode') ?? false;

    // Listen to focus changes to track editing state
    _duniterFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isEditingDuniter = _duniterFocusNode.hasFocus;
        });
      }
    });

    _indexerFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isEditingIndexer = _indexerFocusNode.hasFocus;
        });
      }
    });
  }

  void _initControllers() {
    _endpointController = TextEditingController(
      text: configBox.containsKey('customEndpoint') ? configBox.get('customEndpoint') : Networks.duniterEndpoint,
    );

    String indexerEndpoint;
    if (configBox.containsKey('customIndexer')) {
      indexerEndpoint = configBox.get('customIndexer');
      // Clean endpoint for display (remove paths)
      if (indexerEndpoint.contains('/v1/graphql')) {
        indexerEndpoint = indexerEndpoint.split('/v1/graphql')[0];
      }
    } else {
      indexerEndpoint = Networks.listSquidEndpoints.isNotEmpty ? Networks.listSquidEndpoints[0] : 'https://';
      // Clean endpoint for display (remove paths)
      if (indexerEndpoint.contains('/v1/graphql')) {
        indexerEndpoint = indexerEndpoint.split('/v1/graphql')[0];
      }
    }

    _indexerEndpointController = TextEditingController(text: indexerEndpoint);
  }

  // Removed didChangeDependencies - controllers are now only synced when explicitly needed
  // (after applying new endpoints), not on every rebuild

  void _syncDuniterEndpointController() {
    // Don't sync if user is currently editing
    if (_isEditingDuniter) {
      return;
    }

    String correctEndpoint;
    if (configBox.get('autoEndpoint') == true) {
      correctEndpoint = Networks.duniterEndpoint;
    } else if (configBox.containsKey('customEndpoint')) {
      correctEndpoint = configBox.get('customEndpoint');
    } else {
      correctEndpoint = Networks.duniterEndpoint;
    }

    if (_endpointController.text != correctEndpoint) {
      _endpointController.text = correctEndpoint;
    }
  }

  void _syncIndexerEndpointController() {
    // Don't sync if user is currently editing
    if (_isEditingIndexer) {
      return;
    }

    String correctEndpoint;
    if (configBox.containsKey('customIndexer')) {
      correctEndpoint = configBox.get('customIndexer');
      // Clean endpoint for display (remove paths)
      if (correctEndpoint.contains('/v1/graphql')) {
        correctEndpoint = correctEndpoint.split('/v1/graphql')[0];
      }
    } else {
      correctEndpoint = Networks.listSquidEndpoints.isNotEmpty ? Networks.listSquidEndpoints[0] : 'https://';
      // Clean endpoint for display (remove paths)
      if (correctEndpoint.contains('/v1/graphql')) {
        correctEndpoint = correctEndpoint.split('/v1/graphql')[0];
      }
    }

    if (_indexerEndpointController.text != correctEndpoint) {
      _indexerEndpointController.text = correctEndpoint;
    }
  }

  /// Clean up all Duniter subscriptions and caches before changing nodes
  Future<void> _cleanupDuniterSubscriptions() async {
    try {
      // 1. Unsubscribe from Duniter subscriptions
      if (ref.read(durtProvider).isConnected) {
        await ref.read(storageServiceProvider).unsubscribeFromCurrentBlockNumber();
        await ref.read(storageServiceProvider).unsubscribeFromUniversalDividend();
      }

      // 2. Clear wallet header data cache (contains balance and identity info)
      await walletHeaderDataBox.clear();

      // 3. Clear G1WalletsList cache (search results)
      await g1WalletsBox.clear();

      log.d('🔔 Cleaned up Duniter subscriptions and caches');
    } catch (e) {
      log.w('Error during subscription cleanup: $e');
    }
  }

  /// Switch to a different network
  Future<void> _switchToNetwork(Networks newNetwork) async {
    if (ref.read(durtProvider).network == newNetwork) {
      return; // Already on this network
    }

    if (!mounted) return;
    setState(() {
      _isSwitchingNetwork = true;
      _duniterConnectionFailed = false;
      _indexerConnectionFailed = false;
    });

    try {
      // 1. Clean up current subscriptions and caches
      await _cleanupDuniterSubscriptions();

      // 2. Clear endpoint configurations to force auto-discovery
      configBox.delete('customEndpoint');
      configBox.delete('customIndexer');
      configBox.put('autoEndpoint', true);

      // 3. Switch network in durt2
      await ref.read(durtProvider).switchNetwork(newNetwork);

      // 4. Save selected network in config
      configBox.put('selectedNetwork', newNetwork.name);

      // 5. Reconnect to the new network
      await ref.read(durtProvider).connect(verbose: true);

      // 6. Refresh controllers and UI
      _syncDuniterEndpointController();
      _syncIndexerEndpointController();
      _refreshBlockHeightProvider();
      ref.invalidate(currencyDataProvider);

      // 7. Invalidate genesisTimeProvider to force recalculation with new network
      // This is critical because genesisTime is network-specific and must be recalculated
      // when switching networks to avoid incorrect date calculations (e.g., certification expiration dates)
      ref.invalidate(genesisTimeProvider);
      log.i('🔄 Invalidated genesisTimeProvider after network switch');

      log.i('Successfully switched to network: ${newNetwork.name}');
    } catch (e) {
      log.e('Error switching to network ${newNetwork.name}: $e');
      _refreshBlockHeightProvider();
      if (mounted) {
        setState(() {
          _duniterConnectionFailed = true;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching to ${newNetwork.name}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingNetwork = false;
        });
      }
    }
  }

  /// Refresh BlockHeightProvider after successful node change
  void _refreshBlockHeightProvider() {
    try {
      ref.invalidate(blockHeightProvider);
      log.d('🔔 BlockHeightProvider refreshed after node change');
    } catch (e) {
      log.w('Error refreshing BlockHeightProvider: $e');
    }
  }

  /// Get available Duniter endpoints from durt2's discovery service
  /// Returns only working endpoints for UI display
  Future<List<String>> _getAvailableDuniterEndpoints() async {
    try {
      final durt = ref.read(durtProvider);

      // Get only working endpoints for UI display
      final workingEndpoints = await durt.getWorkingDuniterEndpoints();

      log.d('🔍 Found ${workingEndpoints.length} working Duniter endpoints');

      if (workingEndpoints.isNotEmpty) {
        return workingEndpoints;
      }

      // If no working endpoints, trigger refresh
      log.w('⚠️ No working Duniter endpoints found, triggering refresh...');
      await durt.refreshEndpoints();

      final refreshedEndpoints = await durt.getWorkingDuniterEndpoints();
      if (refreshedEndpoints.isNotEmpty) {
        return refreshedEndpoints;
      }

      throw Exception('No working Duniter endpoints found');
    } catch (e) {
      log.e('Error getting Duniter endpoints: $e');
      throw Exception('Error getting Duniter endpoints: $e');
    }
  }

  /// Get available and working Squid endpoints
  Future<List<String>> _getAvailableSquidEndpoints() async {
    try {
      final durt = ref.read(durtProvider);

      // Get only working endpoints for UI display
      final workingEndpoints = await durt.getWorkingSquidEndpoints();

      if (workingEndpoints.isNotEmpty) {
        return workingEndpoints;
      }

      // If no working endpoints, trigger refresh
      await durt.refreshEndpoints();

      final refreshedEndpoints = await durt.getWorkingSquidEndpoints();
      if (refreshedEndpoints.isNotEmpty) {
        return refreshedEndpoints;
      }

      throw Exception('No working Squid endpoints found');
    } catch (e) {
      log.e('Error getting Squid endpoints: $e');
      rethrow;
    }
  }

  /// Apply a custom Squid endpoint
  /// Returns true if successful, false otherwise
  Future<bool> _applyCustomSquidEndpoint(String fullEndpoint) async {
    try {
      log.i('🔄 Applying custom Squid endpoint: $fullEndpoint');

      // Save to config first
      configBox.put('customIndexer', fullEndpoint);

      // Force reconnection with the new endpoint
      await ref.read(durtProvider).setFixedSquidEndpoint(fullEndpoint);

      log.i('✅ Successfully applied custom Squid endpoint');
      return true;
    } catch (e) {
      log.e('❌ Error applying custom Squid endpoint: $e');
      return false;
    }
  }

  /// Apply a custom Duniter endpoint
  /// Returns true if successful, false otherwise
  Future<bool> _applyCustomDuniterEndpoint(String endpoint) async {
    try {
      log.i('🔄 Applying custom Duniter endpoint: $endpoint');

      // Clean up subscriptions first
      await _cleanupDuniterSubscriptions();

      // Save to config
      configBox.put('customEndpoint', endpoint);
      configBox.put('autoEndpoint', false);

      // Force reconnection with the new endpoint
      await ref.read(durtProvider).setFixedEndpoint(endpoint);

      // Refresh UI providers
      _syncDuniterEndpointController();
      _refreshBlockHeightProvider();

      log.i('✅ Successfully applied custom Duniter endpoint');
      return true;
    } catch (e) {
      log.e('❌ Error applying custom Duniter endpoint: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _duniterFocusNode.dispose();
    _indexerFocusNode.dispose();
    _endpointController.dispose();
    _indexerEndpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GeckoAppBar('parameters'.tr()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaledSizedBox(height: isSmallScreen ? 12 : 20),

                // Section Général
                Text(
                  'generalSettings'.tr(),
                  style: scaledTextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 8 : 12),

                // Carte Unité de devise
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                        child: chooseCurrencyUnit(context),
                      ),
                    ],
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Sélection du thème
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: chooseThemeMode(context),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Language setting
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: chooseLanguage(context),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Text size setting
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: textSizeSelection(context),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Mode expert
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: expertModeToggle(context),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Rapports d'erreurs Sentry
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: sentryToggle(context),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Nettoyage du cache
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () async {
                      final confirm = await showConfirmationDialog(
                        context: context,
                        message: 'clearCacheConfirmMessage'.tr(),
                        type: ConfirmationDialogType.warning,
                      );

                      if (confirm) {
                        try {
                          // Clear cache
                          final settingsService = ref.read(settingsServiceProvider);
                          await settingsService.clearAllCaches();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('clearCacheExplanation'.tr()),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          log.e('Error clearing caches: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error clearing caches: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cleaning_services_rounded,
                            color: context.colorScheme.primary,
                            size: scaleSize(isSmallScreen ? 20 : 24),
                          ),
                          ScaledSizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'clearCache'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                Text(
                                  'clearCacheDescription'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 20 : 24),

                // Section Expert (visible seulement en mode expert)
                if (_expertMode) ...[
                  // Carte Génération de mnémoniques en anglais
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                      child: generateMnemonicsInEnglishToggle(context),
                    ),
                  ),
                  ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                  Text(
                    'networkSettings'.tr(),
                    style: scaledTextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  ScaledSizedBox(height: isSmallScreen ? 8 : 12),

                  // Carte Sélection du réseau
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                          child: networkSelection(context),
                        ),
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                  // Carte Nœud Duniter
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                          child: duniterEndpointSelection(context),
                        ),
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                  // Carte Indexer
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                          child: indexerEndpointSelection(context),
                        ),
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: isSmallScreen ? 20 : 24),
                ],

                // Section Danger
                ScaledSizedBox(height: isSmallScreen ? 8 : 12),

                // Carte Suppression des coffres
                Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    border: Border.all(color: const Color(0xffD80000).withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        key: keyDeleteAllWallets,
                        onTap: () async {
                          log.w('Oublier tous mes coffres');
                          final answer = await showConfirmationDialog(
                            context: context,
                            message: 'areYouSureForgetAllSafes'.tr(),
                            type: ConfirmationDialogType.warning,
                          );
                          if (answer) {
                            final success = await ref.read(walletActionsProvider.notifier).deleteAllWallets();
                            if (success && mounted) {
                              await Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil(RouteNames.home, (Route<dynamic> route) => false);
                            }
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_forever_rounded,
                                color: const Color(0xffD80000),
                                size: scaleSize(isSmallScreen ? 20 : 24),
                              ),
                              ScaledSizedBox(width: 12),
                              Text(
                                'forgetAllMySafes'.tr(),
                                style: scaledTextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  color: const Color(0xffD80000),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 20 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget chooseCurrencyUnit(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calculate_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Text(
              'currencyDisplayMode'.tr(),
              style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
        ScaledSizedBox(height: 12),
        Consumer(
          builder: (context, ref, _) {
            final currentMode = ref.watch(currencyDisplayModeProvider);
            final trmData = ref.watch(trmDataProvider);

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SegmentedButton<CurrencyDisplayMode>(
                        segments: <ButtonSegment<CurrencyDisplayMode>>[
                          ButtonSegment(
                            value: CurrencyDisplayMode.g1,
                            label: Text(Durt.i.network.symbol),
                            icon: const Icon(Icons.straighten),
                          ),
                          ButtonSegment(
                            value: CurrencyDisplayMode.du,
                            label: Text('DU'),
                            icon: const Icon(Icons.water_drop_rounded),
                          ),
                          ButtonSegment(
                            value: CurrencyDisplayMode.moneyOverMembers,
                            label: Text('M/N'),
                            icon: const Icon(Icons.trending_up_rounded),
                          ),
                        ],
                        selected: {currentMode},
                        onSelectionChanged: (Set<CurrencyDisplayMode> newSelection) {
                          ref.read(currencyDisplayModeProvider.notifier).setDisplayMode(newSelection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                          selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                ScaledSizedBox(height: 8),
                // Display current mode description
                Text(
                  _getDisplayModeDescription(currentMode, trmData),
                  style: scaledTextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _getDisplayModeDescription(CurrencyDisplayMode mode, AsyncValue<TrmData> trmData) {
    switch (mode) {
      case CurrencyDisplayMode.g1:
        return 'displayG1Description'.tr();
      case CurrencyDisplayMode.du:
        return 'displayDUDescription'.tr();
      case CurrencyDisplayMode.moneyOverMembers:
        return trmData.when(
          data: (data) => 'displayMNDescription'.tr(),
          loading: () => 'displayMNDescription'.tr(),
          error: (_, _) => 'displayMNDescriptionError'.tr(),
        );
    }
  }

  Future<void> _showNodeSelectionDialog(
    BuildContext context,
    List<String> nodes,
    String selectedEndpoint,
    TextEditingController controller,
  ) async {
    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'selectNode'.tr(),
            style: scaledTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: nodes.map((node) {
                final isSelected = node == selectedEndpoint;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(node);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? context.colorScheme.primary : Colors.grey[400],
                          size: scaleSize(20),
                        ),
                        ScaledSizedBox(width: 12),
                        Expanded(
                          child: Text(
                            node,
                            style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: scaleSize(16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );

    if (result != null) {
      if (!mounted) return;
      setState(() {
        _duniterConnectionFailed = false;
      });

      log.i('🔍 Testing selected Duniter endpoint: $result');

      // First test if the endpoint is valid
      final isWorking = await ref.read(durtProvider).testDuniterEndpoint(result);

      if (isWorking) {
        log.i('✅ Duniter endpoint test passed');

        // Apply the new endpoint
        final applied = await _applyCustomDuniterEndpoint(result);

        if (applied) {
          controller.text = result;
          if (mounted) {
            setState(() {
              _duniterConnectionFailed = false;
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Duniter endpoint updated successfully'), backgroundColor: Colors.green),
            );
          }
        } else {
          log.e('❌ Failed to apply Duniter endpoint');
          if (mounted) {
            setState(() {
              _duniterConnectionFailed = true;
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('connectionError'.tr()), backgroundColor: Colors.red));
          }
        }
      } else {
        log.w('❌ Duniter endpoint test failed');
        // If endpoint test fails, mark as failed and don't change config
        if (mounted) {
          setState(() {
            _duniterConnectionFailed = true;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('invalidEndpointError'.tr()), backgroundColor: Colors.red));
        }
      }
    }
  }

  Widget duniterEndpointSelection(BuildContext context) {
    String? selectedDuniterEndpoint;

    List<String> duniterBootstrapNodes = [];

    // Use the new method to get available endpoints
    for (String endpoint in Networks.listDuniterEndpoints) {
      duniterBootstrapNodes.add(endpoint);
    }

    selectedDuniterEndpoint = Networks.duniterEndpoint;

    final customEndpoint = 'Personnalisé';
    final localEndpoint = 'ws://10.0.2.2:9944';
    final automaticEndpoint = 'Auto';
    duniterBootstrapNodes.insert(0, automaticEndpoint);
    duniterBootstrapNodes.add(localEndpoint);
    duniterBootstrapNodes.add(customEndpoint);

    if (configBox.get('autoEndpoint') == true) {
      selectedDuniterEndpoint = automaticEndpoint;
    } else if (configBox.containsKey('customEndpoint')) {
      selectedDuniterEndpoint = configBox.get('customEndpoint');
    }

    final endpointController = _endpointController;

    String getDisplayMode() {
      if (configBox.get('autoEndpoint') == true) return 'Auto';
      if (selectedDuniterEndpoint == 'Personnalisé') return 'Manuel';
      return 'Manuel';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dns_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
                ScaledSizedBox(width: 12),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      // Watch connection status to rebuild when endpoint changes
                      final connectionStatus = ref.watch(duniterConnectionStatusProvider);
                      final endpoint = Networks.duniterEndpoint;
                      final displayName = endpoint.isEmpty
                          ? (connectionStatus == ConnectionStatus.connecting ? 'connecting'.tr() : 'currencyNode'.tr())
                          : _extractNodeHostname(endpoint);
                      return Text(
                        displayName,
                        style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                ScaledSizedBox(width: 8),
                Consumer(
                  builder: (context, ref, _) {
                    return Icon(
                      _getConnectionStatusIcon(ref),
                      color: _getConnectionStatusColor(ref),
                      size: scaleSize(16),
                    );
                  },
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  key: keySelectDuniterNodeDropDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(6)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getDisplayMode(),
                          style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        ScaledSizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: scaleSize(20)),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      key: keySelectDuniterNode('Auto'),
                      value: 'Auto',
                      child: Row(
                        children: [
                          Icon(
                            configBox.get('autoEndpoint') == true
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: configBox.get('autoEndpoint') == true
                                ? context.colorScheme.primary
                                : Colors.grey[400],
                            size: scaleSize(20),
                          ),
                          ScaledSizedBox(width: 12),
                          Text(
                            'Auto',
                            style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      key: keySelectDuniterNode('manual'.tr()),
                      value: 'manual'.tr(),
                      child: Row(
                        children: [
                          Icon(
                            configBox.get('autoEndpoint') != true
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: configBox.get('autoEndpoint') != true
                                ? context.colorScheme.primary
                                : Colors.grey[400],
                            size: scaleSize(20),
                          ),
                          ScaledSizedBox(width: 12),
                          Text(
                            'manual'.tr(),
                            style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      key: keySelectDuniterNode('select'.tr()),
                      value: 'select'.tr(),
                      child: Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.grey[400], size: scaleSize(20)),
                          ScaledSizedBox(width: 12),
                          Text(
                            'select'.tr(),
                            style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) async {
                    if (value == 'select'.tr()) {
                      // Get available endpoints dynamically
                      final availableEndpoints = await _getAvailableDuniterEndpoints();
                      await _showNodeSelectionDialog(
                        context,
                        availableEndpoints,
                        selectedDuniterEndpoint ?? '',
                        endpointController,
                      );
                    } else if (value == 'Auto') {
                      if (!mounted) return;
                      setState(() {
                        _duniterConnectionFailed = false;
                      });

                      try {
                        // Clean up existing subscriptions before changing nodes
                        await _cleanupDuniterSubscriptions();

                        configBox.delete('customEndpoint');
                        configBox.put('autoEndpoint', true);

                        await ref.read(durtProvider).connect(verbose: true);
                        _syncDuniterEndpointController(); // Synchronize controller
                        _refreshBlockHeightProvider(); // Refresh block height provider
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _duniterConnectionFailed = true;
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('connectionError'.tr()), backgroundColor: Colors.red));
                        }
                      } finally {
                        // Connection attempt finished
                      }
                    } else {
                      // Manuel mode - prepare for user editing
                      configBox.put('autoEndpoint', false);
                      if (!configBox.containsKey('customEndpoint')) {
                        configBox.put('customEndpoint', _endpointController.text);
                      }
                      // Don't sync here - we want to keep whatever is currently in the field

                      if (!mounted) return;
                      setState(() {
                        // Force UI refresh to show TextField
                      });

                      // Request focus after UI rebuild
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _duniterFocusNode.requestFocus();
                        _endpointController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _endpointController.text.length),
                        );
                      });
                    }
                  },
                ),
              ],
            ),
            Consumer(
              builder: (context, ref, _) {
                final duniterConnectionStatus = ref.watch(duniterConnectionStatusProvider);

                if (duniterConnectionStatus == ConnectionStatus.connecting) {
                  return Padding(
                    padding: EdgeInsets.only(top: scaleSize(16)),
                    child: Center(child: Loading(size: scaleSize(24), stroke: 2)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        if (configBox.get('autoEndpoint') == true)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaledSizedBox(height: 8),
              Text(
                Networks.duniterEndpoint,
                style: scaledTextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaledSizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  key: keyCustomDuniterEndpoint,
                  focusNode: _duniterFocusNode,
                  controller: endpointController,
                  autocorrect: false,
                  style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(8)),
                    border: InputBorder.none,
                    hintText: 'wss://',
                    hintStyle: scaledTextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  onSubmitted: (value) async {
                    if (!mounted) return;

                    // Unfocus to exit editing mode
                    _duniterFocusNode.unfocus();

                    setState(() {
                      _isEditingDuniter = false;
                      _duniterConnectionFailed = false;
                    });

                    log.i('🔍 Testing Duniter endpoint: $value');

                    // Test if the endpoint is valid
                    final isWorking = await ref.read(durtProvider).testDuniterEndpoint(value);

                    if (isWorking) {
                      log.i('✅ Duniter endpoint test passed');

                      // Apply the new endpoint
                      final applied = await _applyCustomDuniterEndpoint(value);

                      if (applied) {
                        if (mounted) {
                          setState(() {
                            _duniterConnectionFailed = false;
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Duniter endpoint updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        log.e('❌ Failed to apply Duniter endpoint');
                        if (mounted) {
                          setState(() {
                            _duniterConnectionFailed = true;
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('connectionError'.tr()), backgroundColor: Colors.red));
                        }
                      }
                    } else {
                      log.w('❌ Duniter endpoint test failed');
                      // If endpoint test fails, mark as failed and don't change config
                      if (mounted) {
                        setState(() {
                          _duniterConnectionFailed = true;
                        });
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('invalidEndpointError'.tr()), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        Consumer(
          builder: (context, ref, _) {
            final blockHeight = ref.watch(blockHeightProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaledSizedBox(height: 4),
                Text(
                  'blockN'.tr(args: [blockHeight.toString()]),
                  style: scaledTextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showIndexerSelectionDialog(
    BuildContext context,
    List<String> indexers,
    String selectedEndpoint,
    TextEditingController controller,
  ) async {
    // Create a map of display names to full endpoints
    final Map<String, String> displayToFull = {};
    for (final fullEndpoint in indexers) {
      String displayEndpoint = fullEndpoint;
      // Clean endpoint for display (remove paths)
      if (displayEndpoint.contains('/v1/graphql')) {
        displayEndpoint = displayEndpoint.split('/v1/graphql')[0];
      }
      displayToFull[displayEndpoint] = fullEndpoint;
    }

    final displayIndexers = displayToFull.keys.toList();

    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'selectIndexer'.tr(),
            style: scaledTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: displayIndexers.map((displayEndpoint) {
                final isSelected = displayEndpoint == selectedEndpoint;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(displayEndpoint);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? context.colorScheme.primary : Colors.grey[400],
                          size: scaleSize(20),
                        ),
                        ScaledSizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayEndpoint,
                            style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: scaleSize(16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );

    if (result != null) {
      if (!mounted) return;

      // Store old endpoint in case we need to restore it
      final oldEndpoint = configBox.containsKey('customIndexer') ? configBox.get('customIndexer') : null;

      // Get the full endpoint from the display name
      final fullEndpoint = displayToFull[result];
      if (fullEndpoint != null) {
        setState(() {
          _indexerConnectionFailed = false;
        });

        log.i('🔍 Testing selected Squid endpoint: $fullEndpoint');

        // TEST FIRST before applying
        final isWorking = await ref.read(squidEndpointTesterProvider)(fullEndpoint);

        if (isWorking) {
          log.i('✅ Squid endpoint test passed');

          // Apply the new endpoint
          final applied = await _applyCustomSquidEndpoint(fullEndpoint);

          if (applied) {
            controller.text = result; // Display the clean endpoint in the UI
            _syncIndexerEndpointController();
            if (mounted) {
              setState(() {
                _indexerConnectionFailed = false;
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Indexer endpoint updated successfully'), backgroundColor: Colors.green),
              );
            }
          } else {
            log.e('❌ Failed to apply Squid endpoint');
            // Restore old endpoint
            if (oldEndpoint != null) {
              String displayOldEndpoint = oldEndpoint;
              if (displayOldEndpoint.contains('/v1/graphql')) {
                displayOldEndpoint = displayOldEndpoint.split('/v1/graphql')[0];
              }
              controller.text = displayOldEndpoint;
              configBox.put('customIndexer', oldEndpoint);
            } else {
              configBox.delete('customIndexer');
            }
            _syncIndexerEndpointController();
            if (mounted) {
              setState(() {
                _indexerConnectionFailed = true;
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to apply indexer endpoint'), backgroundColor: Colors.red));
            }
          }
        } else {
          log.w('❌ Squid endpoint test failed');
          // Test failed - restore old endpoint
          if (oldEndpoint != null) {
            String displayOldEndpoint = oldEndpoint;
            if (displayOldEndpoint.contains('/v1/graphql')) {
              displayOldEndpoint = displayOldEndpoint.split('/v1/graphql')[0];
            }
            controller.text = displayOldEndpoint;
            configBox.put('customIndexer', oldEndpoint);
          } else {
            configBox.delete('customIndexer');
          }
          _syncIndexerEndpointController();
          if (mounted) {
            setState(() {
              _indexerConnectionFailed = true;
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('invalidIndexerError'.tr()), backgroundColor: Colors.red));
          }
        }
      }
    }
  }

  Widget indexerEndpointSelection(BuildContext context) {
    String? selectedIndexerEndpoint;
    if (configBox.containsKey('customIndexer')) {
      String endpoint = configBox.get('customIndexer');
      // Clean endpoint for display (remove paths)
      if (endpoint.contains('/v1/graphql')) {
        endpoint = endpoint.split('/v1/graphql')[0];
      }
      selectedIndexerEndpoint = endpoint;
    } else {
      selectedIndexerEndpoint = Networks.listSquidEndpoints.isNotEmpty
          ? (() {
              // Safe access to avoid race conditions
              final endpoints = Networks.listSquidEndpoints;
              if (endpoints.isEmpty) return 'wss://';

              String endpoint = endpoints[0];
              // Clean endpoint for display (remove paths)
              if (endpoint.contains('/v1/graphql')) {
                endpoint = endpoint.split('/v1/graphql')[0];
              }
              return endpoint;
            })()
          : 'wss://';
    }

    final indexerEndpointController = _indexerEndpointController;

    String getDisplayMode() {
      return configBox.containsKey('customIndexer') ? 'Manuel' : 'Auto';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(
          builder: (context, ref, _) {
            ref.watch(squidEndpointProvider);
            final isLoadingSquid = ref.watch(squidLoadingProvider);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
                    ScaledSizedBox(width: 12),
                    Text(
                      'Indexer',
                      style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    ScaledSizedBox(width: 12),
                    Icon(_getIndexerStatusIcon(ref), color: _getIndexerStatusColor(ref), size: scaleSize(16)),
                    const Spacer(),
                    PopupMenuButton<String>(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(6)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getDisplayMode(),
                              style: scaledTextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            ScaledSizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: scaleSize(20)),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'Auto',
                          child: Row(
                            children: [
                              Icon(
                                !configBox.containsKey('customIndexer')
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: !configBox.containsKey('customIndexer')
                                    ? context.colorScheme.primary
                                    : Colors.grey[400],
                                size: scaleSize(20),
                              ),
                              ScaledSizedBox(width: 12),
                              Text(
                                'Auto',
                                style: scaledTextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Manuel',
                          child: Row(
                            children: [
                              Icon(
                                configBox.containsKey('customIndexer')
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: configBox.containsKey('customIndexer')
                                    ? context.colorScheme.primary
                                    : Colors.grey[400],
                                size: scaleSize(20),
                              ),
                              ScaledSizedBox(width: 12),
                              Text(
                                'Manuel',
                                style: scaledTextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Sélectionner',
                          child: Row(
                            children: [
                              Icon(Icons.list_alt, color: Colors.grey[400], size: scaleSize(20)),
                              ScaledSizedBox(width: 12),
                              Text(
                                'Sélectionner',
                                style: scaledTextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) async {
                        if (value == 'Sélectionner') {
                          // Get available and working endpoints dynamically
                          final availableEndpoints = await _getAvailableSquidEndpoints();
                          await _showIndexerSelectionDialog(
                            context,
                            availableEndpoints,
                            selectedIndexerEndpoint ?? '',
                            indexerEndpointController,
                          );
                        } else if (value == 'Auto') {
                          configBox.delete('customIndexer');
                          _syncIndexerEndpointController(); // Synchronize controller
                          if (mounted) {
                            setState(() {
                              _indexerConnectionFailed = false;
                            });
                          }

                          // Clear fixed Squid endpoint and return to auto discovery mode
                          try {
                            await ref.read(durtProvider).clearFixedSquidEndpoint();
                          } catch (e) {
                            log.w('Error clearing fixed Squid endpoint: $e');
                            if (mounted) {
                              setState(() {
                                _indexerConnectionFailed = true;
                              });
                            }
                          }
                        } else {
                          // Manuel mode - prepare for user editing
                          if (!configBox.containsKey('customIndexer')) {
                            // Initialize with current endpoint if no custom one exists
                            String currentEndpoint = Networks.listSquidEndpoints.isNotEmpty
                                ? Networks.listSquidEndpoints[0]
                                : 'https://';
                            configBox.put('customIndexer', currentEndpoint);

                            // Only sync if we just initialized - otherwise keep existing value
                            String displayEndpoint = currentEndpoint;
                            if (displayEndpoint.contains('/v1/graphql')) {
                              displayEndpoint = displayEndpoint.split('/v1/graphql')[0];
                            }
                            _indexerEndpointController.text = displayEndpoint;
                          }
                          // Don't sync here - we want to keep whatever is currently in the field

                          if (!mounted) return;
                          setState(() {
                            _indexerConnectionFailed = false;
                          });

                          // Request focus after UI rebuild
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _indexerFocusNode.requestFocus();
                            _indexerEndpointController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _indexerEndpointController.text.length),
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (isLoadingSquid)
                  Padding(
                    padding: EdgeInsets.only(top: scaleSize(16)),
                    child: Center(child: Loading(size: scaleSize(24), stroke: 2)),
                  ),
              ],
            );
          },
        ),

        if (!configBox.containsKey('customIndexer'))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaledSizedBox(height: 8),
              Text(
                selectedIndexerEndpoint,
                style: scaledTextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaledSizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  focusNode: _indexerFocusNode,
                  controller: indexerEndpointController,
                  autocorrect: false,
                  style: scaledTextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(8)),
                    border: InputBorder.none,
                    hintText: 'https://',
                    hintStyle: scaledTextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                  onSubmitted: (value) async {
                    if (!mounted) return;

                    // Unfocus to exit editing mode
                    _indexerFocusNode.unfocus();

                    setState(() {
                      _isEditingIndexer = false;
                      _indexerConnectionFailed = false;
                    });

                    // Store old endpoint in case we need to restore it
                    final oldEndpoint = configBox.containsKey('customIndexer') ? configBox.get('customIndexer') : null;

                    // Ensure the endpoint has the correct format with path
                    String fullEndpoint = value;

                    // If the endpoint doesn't have a path, add the default /v1/graphql path
                    if (!fullEndpoint.contains('/v1/graphql')) {
                      if (fullEndpoint.startsWith('wss://') || fullEndpoint.startsWith('ws://')) {
                        fullEndpoint = '$fullEndpoint/v1/graphql';
                      } else if (fullEndpoint.startsWith('https://') || fullEndpoint.startsWith('http://')) {
                        fullEndpoint = '$fullEndpoint/v1/graphql';
                      } else {
                        // Add protocol and path
                        fullEndpoint = 'wss://$fullEndpoint/v1/graphql';
                      }
                    }

                    log.i('🔍 Testing Squid endpoint: $fullEndpoint');

                    // TEST FIRST before applying
                    final testEndpoint = ref.read(squidEndpointTesterProvider);
                    final isWorking = await testEndpoint(fullEndpoint);

                    if (isWorking) {
                      log.i('✅ Squid endpoint test passed');

                      // Apply the new endpoint
                      final applied = await _applyCustomSquidEndpoint(fullEndpoint);

                      if (applied) {
                        _syncIndexerEndpointController();
                        if (mounted) {
                          setState(() {
                            _indexerConnectionFailed = false;
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Indexer endpoint updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        log.e('❌ Failed to apply Squid endpoint');
                        // Restore old endpoint
                        if (oldEndpoint != null) {
                          configBox.put('customIndexer', oldEndpoint);
                        } else {
                          configBox.delete('customIndexer');
                        }
                        _syncIndexerEndpointController();
                        if (mounted) {
                          setState(() {
                            _indexerConnectionFailed = true;
                          });
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to apply indexer endpoint'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } else {
                      log.w('❌ Squid endpoint test failed');
                      // Test failed - restore old endpoint
                      if (oldEndpoint != null) {
                        configBox.put('customIndexer', oldEndpoint);
                      } else {
                        configBox.delete('customIndexer');
                      }
                      _syncIndexerEndpointController();
                      if (mounted) {
                        setState(() {
                          _indexerConnectionFailed = true;
                        });
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('invalidIndexerError'.tr()), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  static const _systemLocaleKey = 'system';

  Widget chooseLanguage(BuildContext context) {
    final currentLocale = context.locale;
    final isSystemLocale = configBox.get('localeOverride') == null;

    final languages = <String, (String, String)>{
      _systemLocaleKey: ('systemLanguage'.tr(), '🌐'),
      'en': ('English', '🇬🇧'),
      'fr': ('Français', '🇫🇷'),
      'es': ('Español', '🇪🇸'),
      'it': ('Italiano', '🇮🇹'),
      'eo': ('Esperanto', '🟢'),
      'de': ('Deutsch', '🇩🇪'),
    };

    final currentKey = isSystemLocale ? _systemLocaleKey : currentLocale.languageCode;
    final currentLabel = languages[currentKey]?.$1 ?? languages[_systemLocaleKey]!.$1;
    final currentFlag = languages[currentKey]?.$2 ?? languages[_systemLocaleKey]!.$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'language'.tr(),
          style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        ScaledSizedBox(height: 8),
        PopupMenuButton<String>(
          onSelected: (String langCode) {
            if (langCode == _systemLocaleKey) {
              configBox.delete('localeOverride');
              context.resetLocale();
            } else {
              configBox.put('localeOverride', langCode);
              context.setLocale(Locale(langCode));
            }
            setState(() {});
          },
          itemBuilder: (BuildContext ctx) {
            return languages.entries.map((entry) {
              final langCode = entry.key;
              final label = entry.value.$1;
              final flag = entry.value.$2;
              final isSelected = langCode == currentKey;
              return PopupMenuItem<String>(
                value: langCode,
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label)),
                    if (isSelected) Icon(Icons.check, color: context.colorScheme.primary, size: 20),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(10)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, color: context.colorScheme.primary, size: scaleSize(20)),
                SizedBox(width: scaleSize(8)),
                Text('$currentFlag $currentLabel', style: scaledTextStyle(fontSize: 14)),
                SizedBox(width: scaleSize(4)),
                Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyMedium?.color),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget chooseThemeMode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('theme'.tr(), style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ScaledSizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Consumer(
                builder: (context, ref, _) {
                  final currentThemeSetting = ref.watch(themeProvider);
                  return SegmentedButton<ThemeModeSetting>(
                    segments: <ButtonSegment<ThemeModeSetting>>[
                      ButtonSegment(
                        value: ThemeModeSetting.light,
                        label: Text('light'.tr()),
                        icon: const Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeModeSetting.system,
                        label: Text('system'.tr()),
                        icon: const Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeModeSetting.dark,
                        label: Text('dark'.tr()),
                        icon: const Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {currentThemeSetting},
                    onSelectionChanged: (Set<ThemeModeSetting> newSelection) {
                      ref.read(themeProvider.notifier).setThemeMode(newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                      selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(8)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget expertModeToggle(BuildContext context) {
    return InkWell(
      onTap: () {
        final newValue = !_expertMode;
        configBox.put('expertMode', newValue);
        if (mounted) {
          setState(() {
            _expertMode = newValue;
          });
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
        child: Row(
          children: [
            Icon(Icons.engineering_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'expertMode'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    'expertModeDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
            Switch(
              value: _expertMode,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colorScheme.primary;
                }
                return Colors.grey[400];
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (!states.contains(WidgetState.selected)) {
                  return Colors.grey[300];
                }
                return null;
              }),
              onChanged: (bool value) {
                configBox.put('expertMode', value);
                if (mounted) {
                  setState(() {
                    _expertMode = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget sentryToggle(BuildContext context) {
    final sentryEnabled = configBox.get('sentryEnabled') ?? true;

    return InkWell(
      onTap: () {
        final newValue = !sentryEnabled;
        configBox.put('sentryEnabled', newValue);
        if (mounted) {
          setState(() {});
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
        child: Row(
          children: [
            Icon(Icons.bug_report_outlined, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sendErrorReports'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    'sendErrorReportsDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  ScaledSizedBox(height: 2),
                  Text(
                    'requiresRestart'.tr(),
                    style: scaledTextStyle(
                      fontSize: 11,
                      color: context.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: sentryEnabled,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colorScheme.primary;
                }
                return Colors.grey[400];
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (!states.contains(WidgetState.selected)) {
                  return Colors.grey[300];
                }
                return null;
              }),
              onChanged: (bool value) {
                configBox.put('sentryEnabled', value);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget generateMnemonicsInEnglishToggle(BuildContext context) {
    final generateInEnglish = configBox.get('generateMnemonicsInEnglish') ?? false;

    return InkWell(
      onTap: () {
        final newValue = !generateInEnglish;
        configBox.put('generateMnemonicsInEnglish', newValue);
        if (mounted) {
          setState(() {});
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
        child: Row(
          children: [
            Icon(Icons.translate_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'generateMnemonicsInEnglish'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    'generateMnemonicsInEnglishDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
            Switch(
              value: generateInEnglish,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colorScheme.primary;
                }
                return Colors.grey[400];
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (!states.contains(WidgetState.selected)) {
                  return Colors.grey[300];
                }
                return null;
              }),
              onChanged: (bool value) {
                configBox.put('generateMnemonicsInEnglish', value);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Check if currently on local network
  bool _isOnLocalNetwork() {
    // Check if local network is selected
    final selectedNetwork = configBox.get('selectedNetwork');
    return selectedNetwork == 'local';
  }

  Widget networkSelection(BuildContext context) {
    final Networks currentNetwork = ref.read(durtProvider).network;
    final bool isLocalNetwork = _isOnLocalNetwork();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.public_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Text(
              'network'.tr(),
              style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const Spacer(),
            if (_isSwitchingNetwork)
              Padding(
                padding: EdgeInsets.only(right: scaleSize(8)),
                child: Loading(size: scaleSize(16), stroke: 2),
              ),
          ],
        ),
        ScaledSizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Builder(
                builder: (context) {
                  // Create dynamic segments list
                  final List<ButtonSegment<String>> segments = [
                    ButtonSegment(value: 'g1', label: Text('g1'), icon: const Icon(Icons.account_balance_rounded)),
                    ButtonSegment(value: 'gtest', label: Text('gtest'), icon: const Icon(Icons.bug_report_rounded)),
                    ButtonSegment(value: 'gdev', label: Text('gdev'), icon: const Icon(Icons.bug_report_rounded)),
                  ];

                  // Add local network in debug mode or if already selected
                  if (kDebugMode || isLocalNetwork) {
                    segments.add(
                      ButtonSegment(
                        value: 'local',
                        label: Text('local'),
                        icon: const Icon(Icons.developer_mode_rounded),
                      ),
                    );
                  }

                  // Determine current selection
                  String currentSelection;
                  if (isLocalNetwork) {
                    currentSelection = 'local';
                  } else {
                    currentSelection = currentNetwork.name;
                  }

                  return SegmentedButton<String>(
                    segments: segments,
                    selected: {currentSelection},
                    onSelectionChanged: _isSwitchingNetwork
                        ? null
                        : (Set<String> newSelection) async {
                            final selectedNetworkName = newSelection.first;

                            // Warn when switching away from g1
                            if (selectedNetworkName != 'g1') {
                              final confirmed = await showConfirmationDialog(
                                context: context,
                                title: 'switchToTestNetworkTitle'.tr(),
                                message: 'switchToTestNetworkMessage'.tr(args: [selectedNetworkName.toUpperCase()]),
                                confirmText: 'confirm'.tr(),
                                type: ConfirmationDialogType.warning,
                              );
                              if (!confirmed) return;
                            }

                            if (selectedNetworkName == 'local') {
                              // Switch to local network - treat it like any other network
                              final localNetwork = Networks.values.firstWhere((n) => n.name == 'local');
                              await _switchToNetwork(localNetwork);
                            } else {
                              // Switch to normal network
                              final selectedNetwork = Networks.values.firstWhere(
                                (network) => network.name == selectedNetworkName,
                              );
                              if (selectedNetwork != currentNetwork || isLocalNetwork) {
                                await _switchToNetwork(selectedNetwork);
                              }
                            }
                          },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                      selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ScaledSizedBox(height: 8),
        Center(
          child: Text(
            isLocalNetwork
                ? 'Local Development Network (${Utils.localEndpoint})'
                : 'currentNetwork'.tr(args: [currentNetwork.name.toUpperCase(), currentNetwork.ss58.toString()]),
            style: scaledTextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Extracts hostname from a WebSocket URL (e.g., "wss://node.example.com:9944" -> "node.example.com")
  String _extractNodeHostname(String endpoint) {
    try {
      // Remove protocol prefix
      String cleaned = endpoint;
      if (cleaned.startsWith('wss://')) {
        cleaned = cleaned.substring(6);
      } else if (cleaned.startsWith('ws://')) {
        cleaned = cleaned.substring(5);
      }
      // Remove port and path
      final colonIndex = cleaned.indexOf(':');
      final slashIndex = cleaned.indexOf('/');
      if (colonIndex > 0) {
        cleaned = cleaned.substring(0, colonIndex);
      } else if (slashIndex > 0) {
        cleaned = cleaned.substring(0, slashIndex);
      }
      return cleaned;
    } catch (e) {
      return endpoint;
    }
  }

  IconData _getConnectionStatusIcon(WidgetRef ref) {
    final duniterConnectionStatus = ref.watch(duniterConnectionStatusProvider);

    if (duniterConnectionStatus == ConnectionStatus.connecting) {
      return Icons.hourglass_bottom;
    } else if (_duniterConnectionFailed) {
      return Icons.error;
    } else if (duniterConnectionStatus == ConnectionStatus.connected) {
      return Icons.check_circle;
    } else {
      return Icons.error;
    }
  }

  Color _getConnectionStatusColor(WidgetRef ref) {
    final duniterConnectionStatus = ref.watch(duniterConnectionStatusProvider);

    if (duniterConnectionStatus == ConnectionStatus.connecting) {
      return Colors.orange;
    } else if (_duniterConnectionFailed) {
      return Colors.red;
    } else if (duniterConnectionStatus == ConnectionStatus.connected) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  IconData _getIndexerStatusIcon(WidgetRef ref) {
    final squidConnectionStatus = ref.watch(squidConnectionStatusProvider);
    final isLoadingSquid = ref.watch(squidLoadingProvider);

    if (isLoadingSquid) {
      return Icons.hourglass_bottom;
    } else if (_indexerConnectionFailed) {
      return Icons.error;
    } else if (squidConnectionStatus == ConnectionStatus.connected) {
      return Icons.check_circle;
    } else {
      return Icons.error;
    }
  }

  Color _getIndexerStatusColor(WidgetRef ref) {
    final squidConnectionStatus = ref.watch(squidConnectionStatusProvider);
    final isLoadingSquid = ref.watch(squidLoadingProvider);

    if (isLoadingSquid) {
      return Colors.orange;
    } else if (_indexerConnectionFailed) {
      return Colors.red;
    } else if (squidConnectionStatus == ConnectionStatus.connected) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  Widget _buildDot(double preset, double currentScale, WidgetRef ref) {
    final isSelected = (currentScale - preset).abs() < 0.01;
    return GestureDetector(
      onTap: () {
        ref.read(textScalingProvider.notifier).setTextScale(preset);
      },
      child: Container(
        width: scaleSize(12),
        height: scaleSize(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? context.colorScheme.primary : context.colorScheme.primary.withValues(alpha: 0.5),
          border: Border.all(color: context.colorScheme.primary, width: isSelected ? 2 : 1),
        ),
      ),
    );
  }

  Widget textSizeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_size_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Text(
              'textSize'.tr(),
              style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
        ScaledSizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final currentScale = ref.watch(textScalingProvider);

            return Column(
              children: [
                // Current size indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      TextScaling.getLabelKey(currentScale).tr(),
                      style: scaledTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                ScaledSizedBox(height: 16),

                // Slider with preset anchors
                Column(
                  children: [
                    GestureDetector(
                      onDoubleTap: () {
                        // Double tap to reset to normal size
                        ref.read(textScalingProvider.notifier).setTextScale(TextScaling.defaultScale);
                      },
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: context.colorScheme.primary,
                          inactiveTrackColor: context.colorScheme.primary.withValues(alpha: 0.3),
                          thumbColor: context.colorScheme.primary,
                          overlayColor: context.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: currentScale,
                          min: TextScaling.minScale,
                          max: TextScaling.maxScale,
                          divisions: 30, // Allows fine-grained control
                          onChanged: (double value) {
                            ref.read(textScalingProvider.notifier).setTextScale(value);
                          },
                          onChangeEnd: (double value) {
                            // Snap to nearest preset if close enough
                            final snapped = TextScaling.snapToPreset(value);
                            if ((value - snapped).abs() < 0.05) {
                              ref.read(textScalingProvider.notifier).setTextScale(snapped);
                            }
                          },
                        ),
                      ),
                    ),

                    // Points positioned exactly like slider values
                    SizedBox(
                      height: scaleSize(30),
                      child: Stack(
                        children: [
                          // 0.85 = 0% (tout à gauche)
                          Positioned(
                            left: scaleSize(24) - scaleSize(6), // Slider padding - half dot
                            top: scaleSize(9),
                            child: _buildDot(0.85, currentScale, ref),
                          ),
                          // 1.0 = 20% de la barre
                          Positioned(
                            left:
                                scaleSize(24) +
                                ((MediaQuery.of(context).size.width - scaleSize(96)) * 0.2) -
                                scaleSize(6),
                            top: scaleSize(9),
                            child: _buildDot(1.0, currentScale, ref),
                          ),
                          // 1.30 = 60% de la barre
                          Positioned(
                            left:
                                scaleSize(24) +
                                ((MediaQuery.of(context).size.width - scaleSize(96)) * 0.6) -
                                scaleSize(6),
                            top: scaleSize(9),
                            child: _buildDot(1.30, currentScale, ref),
                          ),
                          // 1.60 = 100% (tout à droite)
                          Positioned(
                            right: scaleSize(24) - scaleSize(6), // Slider padding - half dot
                            top: scaleSize(9),
                            child: _buildDot(1.60, currentScale, ref),
                          ),
                        ],
                      ),
                    ),

                    // Labels simples sous les points
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(18)),
                      child: Row(
                        children: [
                          Text(
                            'textSizeSmall'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Expanded(child: Container()),
                          Text(
                            'textSizeNormal'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Expanded(child: Container()),
                          Text(
                            'textSizeLarge'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          Expanded(child: Container()),
                          Text(
                            'textSizeExtraLarge'.tr(),
                            style: scaledTextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                ScaledSizedBox(height: 12),
                Text(
                  'textSizeDescription'.tr(),
                  style: scaledTextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
