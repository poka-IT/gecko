// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show Networks;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/block_height_provider.dart';

import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/theme_provider.dart' as theme_provider;
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/transaction_in_progress_tile.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:durt2/durt2.dart' as d;

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
  bool _isManuallyConnectingDuniter = false;
  bool _duniterConnectionFailed = false;
  bool _indexerConnectionFailed = false;
  bool _expertMode = false;

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

      log.i('Cleaned up Duniter subscriptions and caches');
    } catch (e) {
      log.w('Error during subscription cleanup: $e');
    }
  }

  /// Refresh BlockHeightProvider after successful node change
  void _refreshBlockHeightProvider() {
    try {
      final blockHeightProvider = old_provider.Provider.of<BlockHeightProvider>(context, listen: false);
      blockHeightProvider.refresh();
      log.d('BlockHeightProvider refreshed after node change');
    } catch (e) {
      log.w('Error refreshing BlockHeightProvider: $e');
    }
  }

  /// Get available Duniter endpoints from durt2's discovery service
  Future<List<String>> _getAvailableDuniterEndpoints() async {
    try {
      final durt = _container.read(durtProvider);

      // Get cached working endpoints from endpointBox
      final rpcQuery = durt.endpointBox
          .query(
            CachedEndpoint_.networkIndex
                .equals(d.Networks.values.indexOf(durt.network))
                .and(CachedEndpoint_.type.equals('rpc'))
                .and(CachedEndpoint_.isWorking.equals(true)),
          )
          .order(CachedEndpoint_.priority, flags: Order.descending)
          .build();

      final cachedEndpoints = rpcQuery.find();
      rpcQuery.close();

      if (cachedEndpoints.isNotEmpty) {
        return cachedEndpoints.map((e) => e.url).toList();
      }

      // Fallback to Networks.listDuniterEndpoints if available
      if (Networks.listDuniterEndpoints.isNotEmpty) {
        return Networks.listDuniterEndpoints;
      }

      // Return hardcoded endpoints as last fallback
      return [
        'wss://gdev.p2p.legal/ws',
        'wss://gdev.coinduf.eu/ws',
        'wss://vit.fdn.org/ws',
        'wss://gdev.cgeek.fr/ws',
        'wss://gdev.pini.fr/ws',
      ];
    } catch (e) {
      log.e('Error getting Duniter endpoints: $e');
      // Return hardcoded endpoints as fallback
      return [
        'wss://gdev.p2p.legal/ws',
        'wss://gdev.coinduf.eu/ws',
        'wss://vit.fdn.org/ws',
        'wss://gdev.cgeek.fr/ws',
        'wss://gdev.pini.fr/ws',
      ];
    }
  }

  /// Get available and working Squid endpoints
  Future<List<String>> _getAvailableSquidEndpoints() async {
    try {
      final durt = _container.read(durtProvider);

      // Get cached working endpoints from endpointBox
      final squidQuery = durt.endpointBox
          .query(
            CachedEndpoint_.networkIndex
                .equals(d.Networks.values.indexOf(durt.network))
                .and(CachedEndpoint_.type.equals('squid'))
                .and(CachedEndpoint_.isWorking.equals(true)),
          )
          .order(CachedEndpoint_.priority, flags: Order.descending)
          .build();

      final cachedEndpoints = squidQuery.find();
      squidQuery.close();

      if (cachedEndpoints.isNotEmpty) {
        // Return complete endpoints with paths
        return cachedEndpoints.map((e) => e.url).toList();
      }

      // Fallback to Networks.listSquidEndpoints if available
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
                        // Clear WalletHeaderData cache
                        await walletHeaderDataBox.clear();

                        // Clear G1WalletsList cache
                        await g1WalletsBox.clear();

                        // Clear transaction status cache
                        TransactionStatusCache.clearCache();

                        // Clear Squid and Duniter endpoint caches
                        try {
                          // Clear Squid endpoint cache from durt2 configBox
                          final durt = _container.read(durtProvider);
                          final networks = ['gdev', 'gtest', 'g1'];

                          for (final network in networks) {
                            // Clear cached Squid endpoints - find and remove Config objects
                            final squidCacheKey = 'fast_squid_endpoint_$network';
                            final squidTimeKey = 'endpoint_cache_time_${network}_squid';

                            // Find and remove Squid endpoint cache
                            final squidQuery = durt.configBox.query(Config_.key.equals(squidCacheKey)).build();
                            final squidConfig = squidQuery.findFirst();
                            squidQuery.close();
                            if (squidConfig != null) {
                              durt.configBox.remove(squidConfig.id);
                            }

                            // Find and remove Squid time cache
                            final squidTimeQuery = durt.configBox.query(Config_.key.equals(squidTimeKey)).build();
                            final squidTimeConfig = squidTimeQuery.findFirst();
                            squidTimeQuery.close();
                            if (squidTimeConfig != null) {
                              durt.configBox.remove(squidTimeConfig.id);
                            }

                            // Clear cached Duniter endpoints if they exist
                            final duniterCacheKey = 'fast_duniter_endpoint_$network';
                            final duniterTimeKey = 'endpoint_cache_time_${network}_rpc';

                            // Find and remove Duniter endpoint cache
                            final duniterQuery = durt.configBox.query(Config_.key.equals(duniterCacheKey)).build();
                            final duniterConfig = duniterQuery.findFirst();
                            duniterQuery.close();
                            if (duniterConfig != null) {
                              durt.configBox.remove(duniterConfig.id);
                            }

                            // Find and remove Duniter time cache
                            final duniterTimeQuery = durt.configBox.query(Config_.key.equals(duniterTimeKey)).build();
                            final duniterTimeConfig = duniterTimeQuery.findFirst();
                            duniterTimeQuery.close();
                            if (duniterTimeConfig != null) {
                              durt.configBox.remove(duniterTimeConfig.id);
                            }
                          }

                          // Clear ObjectBox cached endpoints
                          durt.endpointBox.removeAll();

                          log.i('Cleared Squid and Duniter endpoint caches');
                        } catch (e) {
                          log.w('Error clearing endpoint caches: $e');
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('clearCacheExplanation'.tr()), duration: const Duration(seconds: 2)),
                          );
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

                // Section Réseau (visible seulement en mode expert)
                if (_expertMode) ...[
                  Text(
                    'networkSettings'.tr(),
                    style: scaledTextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  ScaledSizedBox(height: isSmallScreen ? 8 : 12),

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
                                'forgetAllMyChests'.tr(),
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
    final homeProvider = old_provider.Provider.of<HomeProvider>(context, listen: false);
    return InkWell(
      key: keyUdUnit,
      onTap: () async {
        await homeProvider.changeCurrencyUnit(context);
      },
      child: Row(
        children: [
          Icon(Icons.calculate_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
          ScaledSizedBox(width: 12),
          Text(
            'showUdAmounts'.tr(),
            style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          const Spacer(),
          old_provider.Consumer<HomeProvider>(
            builder: (context, homeProvider, _) {
              final bool isUdUnit = configBox.get('isUdUnit') ?? false;
              return Switch(
                value: isUdUnit,
                activeColor: context.colorScheme.primary,
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[300],
                onChanged: (bool value) async {
                  await homeProvider.changeCurrencyUnit(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showNodeSelectionDialog(
    BuildContext context,
    List<String> nodes,
    String selectedEndpoint,
    TextEditingController controller,
  ) async {
    final set = old_provider.Provider.of<SettingsProvider>(context, listen: false);

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
      setState(() {
        _isManuallyConnectingDuniter = true;
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
            setState(() {
              _duniterConnectionFailed = false;
            });
            set.reload();
          } catch (e) {
            // If connection fails after test passed, show error and mark as failed
            setState(() {
              _duniterConnectionFailed = true;
            });
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('connectionError'.tr()), backgroundColor: Colors.red));
            }
          }
        } else {
          // If endpoint test fails, mark as failed and don't change config
          setState(() {
            _duniterConnectionFailed = true;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('invalidEndpointError'.tr()), backgroundColor: Colors.red));
          }
        }
      } finally {
        setState(() {
          _isManuallyConnectingDuniter = false;
        });
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
                Icon(_getConnectionStatusIcon(), color: _getConnectionStatusColor(), size: scaleSize(16)),
                const Spacer(),
                old_provider.Consumer<SettingsProvider>(
                  builder: (context, set, _) {
                    return PopupMenuButton<String>(
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
                                style: scaledTextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
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
                                style: scaledTextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
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
                          // Clean up existing subscriptions before changing nodes
                          await _cleanupDuniterSubscriptions();

                          configBox.delete('customEndpoint');
                          configBox.put('autoEndpoint', true);
                          setState(() {
                            _duniterConnectionFailed = false;
                          });
                          await _container.read(durtProvider).connect();
                          _syncDuniterEndpointController(); // Synchronize controller
                          _refreshBlockHeightProvider(); // Refresh block height provider
                          set.reload();
                        } else {
                          configBox.put('autoEndpoint', false);
                          if (!configBox.containsKey('customEndpoint')) {
                            configBox.put('customEndpoint', _endpointController.text);
                          }
                          _syncDuniterEndpointController(); // Synchronize controller
                          set.reload();
                          _duniterFocusNode.requestFocus();
                          _endpointController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _endpointController.text.length),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            if (_container.read(durtProvider).isDuniterLoading || _isManuallyConnectingDuniter)
              Padding(
                padding: EdgeInsets.only(top: scaleSize(16)),
                child: Center(child: Loading(size: scaleSize(24), stroke: 2)),
              ),
          ],
        ),
        old_provider.Consumer<SettingsProvider>(
          builder: (context, set, _) {
            if (configBox.get('autoEndpoint') == true) {
              return Column(
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
              );
            }
            return Column(
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
                      setState(() {
                        _isManuallyConnectingDuniter = true;
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
                            setState(() {
                              _duniterConnectionFailed = false;
                            });
                            set.reload();
                          } catch (e) {
                            // If connection fails after test passed, show error and mark as failed
                            setState(() {
                              _duniterConnectionFailed = true;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('connectionError'.tr()), backgroundColor: Colors.red),
                              );
                            }
                          }
                        } else {
                          // If endpoint test fails, mark as failed and don't change config
                          setState(() {
                            _duniterConnectionFailed = true;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('invalidEndpointError'.tr()), backgroundColor: Colors.red),
                            );
                          }
                        }
                      } finally {
                        setState(() {
                          _isManuallyConnectingDuniter = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
        old_provider.Consumer<BlockHeightProvider>(
          builder: (context, blockHeightProvider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaledSizedBox(height: 4),
                Text(
                  'blockN'.tr(args: [blockHeightProvider.blockHeight.toString()]),
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
    final set = old_provider.Provider.of<SettingsProvider>(context, listen: false);

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
            await _container.read(durtProvider).connect(initDuniter: false, initSquid: true);
          } catch (e) {
            log.w('Error reconnecting to Squid after endpoint change: $e');
          }

          setState(() {
            _indexerConnectionFailed = false;
          });
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
          setState(() {
            _indexerConnectionFailed = true;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('invalidIndexerError'.tr()), backgroundColor: Colors.red));
          }
        }
        set.reload();
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
                    Icon(_getIndexerStatusIcon(), color: _getIndexerStatusColor(), size: scaleSize(16)),
                    const Spacer(),
                    old_provider.Consumer<SettingsProvider>(
                      builder: (context, set, _) {
                        return PopupMenuButton<String>(
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
                              setState(() {
                                _indexerConnectionFailed = false;
                              });

                              // Force reconnection to use strict validation instead of just testing
                              try {
                                await _container.read(durtProvider).connect(initDuniter: false, initSquid: true);
                              } catch (e) {
                                log.w('Error reconnecting to Squid in Auto mode: $e');
                                setState(() {
                                  _indexerConnectionFailed = true;
                                });
                              }

                              set.reload();
                            } else {
                              if (!configBox.containsKey('customIndexer')) {
                                configBox.put('customIndexer', _indexerEndpointController.text);
                              }
                              _syncIndexerEndpointController(); // Synchronize controller
                              set.reload();
                              _indexerFocusNode.requestFocus();
                              _indexerEndpointController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _indexerEndpointController.text.length),
                              );
                            }
                          },
                        );
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
        old_provider.Consumer<SettingsProvider>(
          builder: (context, set, _) {
            final testEndpoint = ref.read(squidEndpointTesterProvider);

            if (!configBox.containsKey('customIndexer')) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaledSizedBox(height: 8),
                  Text(
                    selectedIndexerEndpoint ?? '',
                    style: scaledTextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              );
            }
            return Column(
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
                      final oldEndpoint = configBox.containsKey('customIndexer')
                          ? configBox.get('customIndexer')
                          : null;

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

                      setState(() {
                        _indexerConnectionFailed = false;
                      });

                      // TEST FIRST before saving to configBox
                      final isWorking = await testEndpoint(fullEndpoint);
                      if (isWorking) {
                        // Only save to configBox if the test passes
                        configBox.put('customIndexer', fullEndpoint);
                        _syncIndexerEndpointController(); // Synchronize controller

                        // Force reconnection to ensure strict validation
                        try {
                          await _container.read(durtProvider).connect(initDuniter: false, initSquid: true);
                        } catch (e) {
                          log.w('Error reconnecting to Squid after endpoint change: $e');
                        }

                        setState(() {
                          _indexerConnectionFailed = false;
                        });
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
                        setState(() {
                          _indexerConnectionFailed = true;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('invalidIndexerError'.tr()), backgroundColor: Colors.red),
                          );
                        }
                      }
                      set.reload();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget chooseThemeMode(BuildContext context) {
    final themeProvider = old_provider.Provider.of<theme_provider.ThemeProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('theme'.tr(), style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ScaledSizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            old_provider.Consumer<theme_provider.ThemeProvider>(
              builder: (context, theme, _) {
                return SegmentedButton<theme_provider.ThemeModeSetting>(
                  segments: <ButtonSegment<theme_provider.ThemeModeSetting>>[
                    ButtonSegment(
                      value: theme_provider.ThemeModeSetting.light,
                      label: Text('light'.tr()),
                      icon: const Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: theme_provider.ThemeModeSetting.system,
                      label: Text('system'.tr()),
                      icon: const Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: theme_provider.ThemeModeSetting.dark,
                      label: Text('dark'.tr()),
                      icon: const Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {theme.themeModeSetting},
                  onSelectionChanged: (Set<theme_provider.ThemeModeSetting> newSelection) {
                    themeProvider.setThemeMode(newSelection.first);
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
        setState(() {
          _expertMode = newValue;
        });
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
                setState(() {
                  _expertMode = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConnectionStatusIcon() {
    if (_isManuallyConnectingDuniter || _container.read(durtProvider).isDuniterLoading) {
      return Icons.hourglass_bottom;
    } else if (_duniterConnectionFailed) {
      return Icons.error;
    } else if (_container.read(durtProvider).isConnected) {
      return Icons.check_circle;
    } else {
      return Icons.error;
    }
  }

  Color _getConnectionStatusColor() {
    if (_isManuallyConnectingDuniter || _container.read(durtProvider).isDuniterLoading) {
      return Colors.orange;
    } else if (_duniterConnectionFailed) {
      return Colors.red;
    } else if (_container.read(durtProvider).isConnected) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  IconData _getIndexerStatusIcon() {
    if (_indexerConnectionFailed) {
      return Icons.error;
    } else if (_indexerEndpointController.text.isNotEmpty && _indexerEndpointController.text != 'https://') {
      return Icons.check_circle;
    } else {
      return Icons.error;
    }
  }

  Color _getIndexerStatusColor() {
    if (_indexerConnectionFailed) {
      return Colors.red;
    } else if (_indexerEndpointController.text.isNotEmpty && _indexerEndpointController.text != 'https://') {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }
}
