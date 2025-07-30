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

import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/theme_provider.dart';
import 'package:gecko/providers/trm_data_provider.dart';

import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

// Helper pour accéder aux services Riverpod depuis ce fichier
final _container = ProviderContainer();

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final MyWalletsProvider _myWallets = MyWalletsProvider();
  final FocusNode _duniterFocusNode = FocusNode();
  final FocusNode _indexerFocusNode = FocusNode();
  late TextEditingController _endpointController;
  late TextEditingController _indexerEndpointController;
  bool _duniterConnectionFailed = false;
  bool _indexerConnectionFailed = false;
  bool _expertMode = false;
  bool _isSwitchingNetwork = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _expertMode = configBox.get('expertMode') ?? false;
  }

  void _initControllers() {
    _endpointController = TextEditingController(
      text: configBox.containsKey('customEndpoint') ? configBox.get('customEndpoint') : Networks.duniterEndpoint,
    );

    String indexerEndpoint;
    if (configBox.containsKey('customIndexer')) {
      indexerEndpoint = configBox.get('customIndexer');
      // Clean endpoint for display (remove paths)
      if (indexerEndpoint.contains('/v1beta1/relay')) {
        indexerEndpoint = indexerEndpoint.split('/v1beta1/relay')[0];
      }
      if (indexerEndpoint.contains('/v1/graphql')) {
        indexerEndpoint = indexerEndpoint.split('/v1/graphql')[0];
      }
    } else {
      indexerEndpoint = Networks.listSquidEndpoints.isNotEmpty ? Networks.listSquidEndpoints[0] : 'https://';
      // Clean endpoint for display (remove paths)
      if (indexerEndpoint.contains('/v1beta1/relay')) {
        indexerEndpoint = indexerEndpoint.split('/v1beta1/relay')[0];
      }
      if (indexerEndpoint.contains('/v1/graphql')) {
        indexerEndpoint = indexerEndpoint.split('/v1/graphql')[0];
      }
    }

    _indexerEndpointController = TextEditingController(text: indexerEndpoint);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Synchronize Duniter endpoint controller with current state
    _syncDuniterEndpointController();

    // Synchronize Indexer endpoint controller with current state
    _syncIndexerEndpointController();
  }

  void _syncDuniterEndpointController() {
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
    String correctEndpoint;
    if (configBox.containsKey('customIndexer')) {
      correctEndpoint = configBox.get('customIndexer');
      // Clean endpoint for display (remove paths)
      if (correctEndpoint.contains('/v1beta1/relay')) {
        correctEndpoint = correctEndpoint.split('/v1beta1/relay')[0];
      }
      if (correctEndpoint.contains('/v1/graphql')) {
        correctEndpoint = correctEndpoint.split('/v1/graphql')[0];
      }
    } else {
      correctEndpoint = Networks.listSquidEndpoints.isNotEmpty ? Networks.listSquidEndpoints[0] : 'https://';
      // Clean endpoint for display (remove paths)
      if (correctEndpoint.contains('/v1beta1/relay')) {
        correctEndpoint = correctEndpoint.split('/v1beta1/relay')[0];
      }
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
      if (_container.read(durtProvider).isConnected) {
        await _container.read(storageServiceProvider).unsubscribeFromCurrentBlockNumber();
        await _container.read(storageServiceProvider).unsubscribeFromUniversalDividend();
      }

      // 2. Clear wallet header data cache (contains balance and identity info)
      await walletHeaderDataBox.clear();

      // 3. Clear G1WalletsList cache (search results)
      await g1WalletsBox.clear();

      //TODO: Ensure duniter storage provider is cleared, check with balance, certs and status wallet

      // ignore: avoid_print
      print('🔔 Cleaned up Duniter subscriptions and caches');
    } catch (e) {
      log.w('Error during subscription cleanup: $e');
    }
  }

  /// Switch to a different network
  Future<void> _switchToNetwork(Networks newNetwork) async {
    if (_container.read(durtProvider).network == newNetwork) {
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
      await _container.read(durtProvider).switchNetwork(newNetwork);

      // 4. Save selected network in config
      configBox.put('selectedNetwork', newNetwork.name);

      // 5. Reconnect to the new network
      await _container.read(durtProvider).connect(verbose: true);

      // 6. Refresh controllers and UI
      _syncDuniterEndpointController();
      _syncIndexerEndpointController();
      _refreshBlockHeightProvider();
      ref.invalidate(currencyDataProvider);

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
      _container.invalidate(blockHeightProvider);
      // ignore: avoid_print
      print('🔔 BlockHeightProvider refreshed after node change');
    } catch (e) {
      log.w('Error refreshing BlockHeightProvider: $e');
    }
  }

  /// Get available Duniter endpoints from durt2's discovery service
  Future<List<String>> _getAvailableDuniterEndpoints() async {
    try {
      final durt = _container.read(durtProvider);

      log.d('🔍 Checking Networks.listDuniterEndpoints: ${Networks.listDuniterEndpoints.length} endpoints available');
      if (Networks.listDuniterEndpoints.isNotEmpty) {
        log.d('✅ Using existing ${Networks.listDuniterEndpoints.length} Duniter endpoints');
        return Networks.listDuniterEndpoints;
      }

      // If no endpoints available, trigger refresh
      log.w('⚠️ Networks.listDuniterEndpoints is empty, triggering refresh...');
      await durt.refreshEndpoints();

      if (Networks.listDuniterEndpoints.isNotEmpty) {
        return Networks.listDuniterEndpoints;
      }

      throw Exception('No Duniter endpoints found');
    } catch (e) {
      log.e('Error getting Duniter endpoints: $e');
      throw Exception('Error getting Duniter endpoints: $e');
    }
  }

  /// Get available and working Squid endpoints
  Future<List<String>> _getAvailableSquidEndpoints() async {
    try {
      final durt = _container.read(durtProvider);

      // Use Networks.listSquidEndpoints directly (populated by discovery service)
      if (Networks.listSquidEndpoints.isNotEmpty) {
        return Networks.listSquidEndpoints;
      }

      // If no endpoints available, trigger refresh
      await durt.refreshEndpoints();

      if (Networks.listSquidEndpoints.isNotEmpty) {
        return Networks.listSquidEndpoints;
      }

      throw Exception('No Squid endpoints found');
    } catch (e) {
      log.e('Error getting Squid endpoints: $e');
      rethrow;
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
                          await _myWallets.deleteAllWallet(context);
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

      try {
        // Clean up existing subscriptions before changing nodes
        await _cleanupDuniterSubscriptions();

        // First test if the endpoint is valid
        final isWorking = await _container.read(durtProvider).testDuniterEndpoint(result);

        if (isWorking) {
          // If valid, update config and connect to this specific endpoint
          controller.text = result;
          configBox.put('autoEndpoint', false);
          configBox.put('customEndpoint', result);

          try {
            await _container.read(durtProvider).setFixedEndpoint(result);
            _syncDuniterEndpointController(); // Ensure controller is synchronized
            _refreshBlockHeightProvider(); // Refresh block height provider
            if (mounted) {
              setState(() {
                _duniterConnectionFailed = false;
              });
            }
          } catch (e) {
            // If connection fails after test passed, show error and mark as failed
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
      } finally {
        // Connection attempt finished
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
                Text(
                  'currencyNode'.tr(),
                  style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                ScaledSizedBox(width: 12),
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

                        await _container.read(durtProvider).connect(verbose: true);
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
                      configBox.put('autoEndpoint', false);
                      if (!configBox.containsKey('customEndpoint')) {
                        configBox.put('customEndpoint', _endpointController.text);
                      }
                      _syncDuniterEndpointController(); // Synchronize controller

                      _duniterFocusNode.requestFocus();
                      _endpointController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _endpointController.text.length),
                      );
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
                    setState(() {
                      _duniterConnectionFailed = false;
                    });

                    try {
                      // Clean up existing subscriptions before changing nodes
                      await _cleanupDuniterSubscriptions();

                      // First test if the endpoint is valid
                      final isWorking = await _container.read(durtProvider).testDuniterEndpoint(value);

                      if (isWorking) {
                        // If valid, update config and connect to this specific endpoint
                        configBox.put('customEndpoint', value);
                        try {
                          await _container.read(durtProvider).setFixedEndpoint(value);
                          _syncDuniterEndpointController(); // Synchronize controller
                          _refreshBlockHeightProvider(); // Refresh block height provider
                          if (mounted) {
                            setState(() {
                              _duniterConnectionFailed = false;
                            });
                          }
                        } catch (e) {
                          // If connection fails after test passed, show error and mark as failed
                          if (mounted) {
                            setState(() {
                              _duniterConnectionFailed = true;
                            });
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('connectionError'.tr()), backgroundColor: Colors.red),
                            );
                          }
                        }
                      } else {
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
                    } finally {
                      // Connection attempt finished
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
      if (displayEndpoint.contains('/v1beta1/relay')) {
        displayEndpoint = displayEndpoint.split('/v1beta1/relay')[0];
      }
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
      // Store old endpoint in case we need to restore it
      final oldEndpoint = configBox.containsKey('customIndexer') ? configBox.get('customIndexer') : null;

      // Get the full endpoint from the display name
      final fullEndpoint = displayToFull[result];
      if (fullEndpoint != null) {
        if (!mounted) return;
        setState(() {
          _indexerConnectionFailed = false;
        });

        // TEST FIRST before saving to configBox
        final isWorking = await ref.read(squidEndpointTesterProvider)(fullEndpoint);
        if (isWorking) {
          // Only save to configBox if the test passes
          controller.text = result; // Display the clean endpoint in the UI
          configBox.put('customIndexer', fullEndpoint); // Store the full endpoint
          _syncIndexerEndpointController(); // Synchronize controller

          // Force reconnection to ensure strict validation
          try {
            await _container.read(durtProvider).connect(initDuniter: false, verbose: true);
          } catch (e) {
            log.w('Error reconnecting to Squid after endpoint change: $e');
          }

          if (mounted) {
            setState(() {
              _indexerConnectionFailed = false;
            });
          }
        } else {
          // Test failed - keep old endpoint or go back to auto mode
          if (oldEndpoint != null) {
            // Keep old endpoint - extract display name for UI
            String displayOldEndpoint = oldEndpoint;
            if (displayOldEndpoint.contains('/v1beta1/relay')) {
              displayOldEndpoint = displayOldEndpoint.split('/v1beta1/relay')[0];
            }
            if (displayOldEndpoint.contains('/v1/graphql')) {
              displayOldEndpoint = displayOldEndpoint.split('/v1/graphql')[0];
            }
            controller.text = displayOldEndpoint;
            configBox.put('customIndexer', oldEndpoint);
          } else {
            // Go back to auto mode
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
      if (endpoint.contains('/v1beta1/relay')) {
        endpoint = endpoint.split('/v1beta1/relay')[0];
      }
      if (endpoint.contains('/v1/graphql')) {
        endpoint = endpoint.split('/v1/graphql')[0];
      }
      selectedIndexerEndpoint = endpoint;
    } else {
      selectedIndexerEndpoint = Networks.listSquidEndpoints.isNotEmpty
          ? (() {
              String endpoint = Networks.listSquidEndpoints[0];
              // Clean endpoint for display (remove paths)
              if (endpoint.contains('/v1beta1/relay')) {
                endpoint = endpoint.split('/v1beta1/relay')[0];
              }
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

                          // Force reconnection to use strict validation instead of just testing
                          try {
                            await _container.read(durtProvider).connect(initDuniter: false, verbose: true);
                          } catch (e) {
                            log.w('Error reconnecting to Squid in Auto mode: $e');
                            if (mounted) {
                              setState(() {
                                _indexerConnectionFailed = true;
                              });
                            }
                          }
                        } else {
                          if (!configBox.containsKey('customIndexer')) {
                            configBox.put('customIndexer', _indexerEndpointController.text);
                          }
                          _syncIndexerEndpointController(); // Synchronize controller

                          _indexerFocusNode.requestFocus();
                          _indexerEndpointController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _indexerEndpointController.text.length),
                          );
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
                  color: Colors.grey[100],
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
                    // Store old endpoint in case we need to restore it
                    final oldEndpoint = configBox.containsKey('customIndexer') ? configBox.get('customIndexer') : null;

                    // Ensure the endpoint has the correct format with path
                    String fullEndpoint = value;

                    // If the endpoint doesn't have a path, add the default v1beta1/relay path
                    if (!fullEndpoint.contains('/v1beta1/relay') && !fullEndpoint.contains('/v1/graphql')) {
                      if (fullEndpoint.startsWith('wss://') || fullEndpoint.startsWith('ws://')) {
                        fullEndpoint = '$fullEndpoint/v1beta1/relay';
                      } else if (fullEndpoint.startsWith('https://') || fullEndpoint.startsWith('http://')) {
                        fullEndpoint = '$fullEndpoint/v1beta1/relay';
                      } else {
                        // Add protocol and path
                        fullEndpoint = 'wss://$fullEndpoint/v1beta1/relay';
                      }
                    }

                    if (mounted) {
                      setState(() {
                        _indexerConnectionFailed = false;
                      });
                    }

                    // TEST FIRST before saving to configBox
                    final testEndpoint = ref.read(squidEndpointTesterProvider);

                    final isWorking = await testEndpoint(fullEndpoint);
                    if (isWorking) {
                      // Only save to configBox if the test passes
                      configBox.put('customIndexer', fullEndpoint);
                      _syncIndexerEndpointController(); // Synchronize controller

                      // Force reconnection to ensure strict validation
                      try {
                        await _container.read(durtProvider).connect(initDuniter: false, verbose: true);
                      } catch (e) {
                        log.w('Error reconnecting to Squid after endpoint change: $e');
                      }

                      if (mounted) {
                        setState(() {
                          _indexerConnectionFailed = false;
                        });
                      }
                    } else {
                      // Test failed - keep old endpoint or go back to auto mode
                      if (oldEndpoint != null) {
                        // Keep old endpoint
                        configBox.put('customIndexer', oldEndpoint);
                      } else {
                        // Go back to auto mode
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
              activeColor: context.colorScheme.primary,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
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
              activeColor: context.colorScheme.primary,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
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
    final Networks currentNetwork = _container.read(durtProvider).network;
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
                    ButtonSegment(value: 'gdev', label: Text('gdev'), icon: const Icon(Icons.bug_report_rounded)),
                    ButtonSegment(value: 'gtest', label: Text('gtest'), icon: const Icon(Icons.bug_report_rounded)),
                    ButtonSegment(value: 'g1', label: Text('g1'), icon: const Icon(Icons.account_balance_rounded)),
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
