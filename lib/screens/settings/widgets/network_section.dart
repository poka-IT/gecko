import 'package:durt2/durt2.dart' show Networks, ConnectionStatus, Utils;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/currency_provider.dart';
import 'package:gecko/screens/settings/settings_card.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/loading.dart';

/// All network-related settings: network selector, Duniter endpoint,
/// and indexer endpoint.
///
/// Rendered as three [SettingsCard]s inside a [Column].
class NetworkSettingsSection extends ConsumerStatefulWidget {
  const NetworkSettingsSection({super.key});

  @override
  ConsumerState<NetworkSettingsSection> createState() => _NetworkSettingsSectionState();
}

class _NetworkSettingsSectionState extends ConsumerState<NetworkSettingsSection> {
  final FocusNode _duniterFocusNode = FocusNode();
  final FocusNode _indexerFocusNode = FocusNode();
  late TextEditingController _endpointController;
  late TextEditingController _indexerEndpointController;
  bool _duniterConnectionFailed = false;
  bool _indexerConnectionFailed = false;
  bool _isSwitchingNetwork = false;
  bool _isEditingDuniter = false;
  bool _isEditingIndexer = false;

  @override
  void initState() {
    super.initState();
    _initControllers();

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

  ConfigService get _config => ref.read(configServiceProvider);

  void _initControllers() {
    _endpointController = TextEditingController(
      text: _config.hasCustomEndpoint ? _config.customEndpoint! : Networks.duniterEndpoint,
    );

    String indexerEndpoint;
    if (_config.hasCustomIndexer) {
      indexerEndpoint = _config.customIndexer!;
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

  void _syncDuniterEndpointController() {
    // Don't sync if user is currently editing
    if (_isEditingDuniter) {
      return;
    }

    String correctEndpoint;
    if (_config.autoEndpoint == true) {
      correctEndpoint = Networks.duniterEndpoint;
    } else if (_config.hasCustomEndpoint) {
      correctEndpoint = _config.customEndpoint!;
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
    if (_config.hasCustomIndexer) {
      correctEndpoint = _config.customIndexer!;
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
      _config.customEndpoint = null;
      _config.customIndexer = null;
      _config.autoEndpoint = true;

      // 3. Switch network in durt2
      await ref.read(durtProvider).switchNetwork(newNetwork);

      // 4. Save selected network in config
      _config.selectedNetwork = newNetwork.name;

      // 5. Reconnect to the new network
      await ref.read(durtProvider).connect(verbose: true);

      // 6. Refresh controllers and UI
      _syncDuniterEndpointController();
      _syncIndexerEndpointController();
      _refreshBlockHeightProvider();

      // 7. Invalidate all providers that cache Durt.i properties, since Durt.i
      // is a singleton whose internal state changed (new orchestrator/storage).
      // Riverpod won't detect this because the Durt.i reference is unchanged.
      ref.invalidate(storageServiceProvider);
      ref.invalidate(currencyDataProvider);
      ref.invalidate(genesisTimeProvider);
      log.i('🔄 Invalidated storage, currency, and genesis providers after network switch');

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
        SnackbarService.showError(context, message: 'errorSwitchingNetwork'.tr(args: [newNetwork.name, e.toString()]));
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
      _config.customIndexer = fullEndpoint;

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
      _config.customEndpoint = endpoint;
      _config.autoEndpoint = false;

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
            if (!context.mounted) return;
            SnackbarService.showSuccess(context, message: 'duniterEndpointUpdated'.tr());
          }
        } else {
          log.e('❌ Failed to apply Duniter endpoint');
          if (mounted) {
            setState(() {
              _duniterConnectionFailed = true;
            });
          }
          if (mounted) {
            // ignore: use_build_context_synchronously
            SnackbarService.showError(context, message: 'connectionError'.tr());
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
          // ignore: use_build_context_synchronously
          SnackbarService.showError(context, message: 'invalidEndpointError'.tr());
        }
      }
    }
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
      final oldEndpoint = _config.hasCustomIndexer ? _config.customIndexer : null;

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
              if (!context.mounted) return;
              SnackbarService.showSuccess(context, message: 'indexerEndpointUpdated'.tr());
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
              _config.customIndexer = oldEndpoint;
            } else {
              _config.customIndexer = null;
            }
            _syncIndexerEndpointController();
            if (mounted) {
              setState(() {
                _indexerConnectionFailed = true;
              });
            }
            if (mounted) {
              // ignore: use_build_context_synchronously
              SnackbarService.showError(context, message: 'failedApplyIndexerEndpoint'.tr());
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
            _config.customIndexer = oldEndpoint;
          } else {
            _config.customIndexer = null;
          }
          _syncIndexerEndpointController();
          if (mounted) {
            setState(() {
              _indexerConnectionFailed = true;
            });
          }
          if (mounted) {
            // ignore: use_build_context_synchronously
            SnackbarService.showError(context, message: 'invalidIndexerError'.tr());
          }
        }
      }
    }
  }

  /// Check if currently on local network
  bool _isOnLocalNetwork() {
    // Check if local network is selected
    return _config.selectedNetwork == 'local';
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
    final colors = context.geckoColors;

    if (duniterConnectionStatus == ConnectionStatus.connecting) {
      return colors.connectionWarn;
    } else if (_duniterConnectionFailed) {
      return colors.connectionError;
    } else if (duniterConnectionStatus == ConnectionStatus.connected) {
      return colors.connectionOk;
    } else {
      return colors.connectionError;
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
    final colors = context.geckoColors;

    if (isLoadingSquid) {
      return colors.connectionWarn;
    } else if (_indexerConnectionFailed) {
      return colors.connectionError;
    } else if (squidConnectionStatus == ConnectionStatus.connected) {
      return colors.connectionOk;
    } else {
      return colors.connectionError;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SettingsCard(
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)), child: _networkSelection(context)),
            ],
          ),
        ),
        ScaledSizedBox(height: isSmallScreen ? 12 : 16),

        // Carte Nœud Duniter
        SettingsCard(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                child: _duniterEndpointSelection(context),
              ),
            ],
          ),
        ),
        ScaledSizedBox(height: isSmallScreen ? 12 : 16),

        // Carte Indexer
        SettingsCard(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                child: _indexerEndpointSelection(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _networkSelection(BuildContext context) {
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

  Widget _duniterEndpointSelection(BuildContext context) {
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

    if (_config.autoEndpoint == true) {
      selectedDuniterEndpoint = automaticEndpoint;
    } else if (_config.hasCustomEndpoint) {
      selectedDuniterEndpoint = _config.customEndpoint;
    }

    final endpointController = _endpointController;

    String getDisplayMode() {
      if (_config.autoEndpoint == true) return 'Auto';
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
                            _config.autoEndpoint == true ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: _config.autoEndpoint == true ? context.colorScheme.primary : Colors.grey[400],
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
                            _config.autoEndpoint != true ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: _config.autoEndpoint != true ? context.colorScheme.primary : Colors.grey[400],
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
                      if (!mounted) return;
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

                        _config.customEndpoint = null;
                        _config.autoEndpoint = true;

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
                          // ignore: use_build_context_synchronously
                          SnackbarService.showError(context, message: 'connectionError'.tr());
                        }
                      } finally {
                        // Connection attempt finished
                      }
                    } else {
                      // Manuel mode - prepare for user editing
                      _config.autoEndpoint = false;
                      if (!_config.hasCustomEndpoint) {
                        _config.customEndpoint = _endpointController.text;
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
        if (_config.autoEndpoint == true)
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
                          if (!context.mounted) return;
                          SnackbarService.showSuccess(context, message: 'duniterEndpointUpdated'.tr());
                        }
                      } else {
                        log.e('❌ Failed to apply Duniter endpoint');
                        if (mounted) {
                          setState(() {
                            _duniterConnectionFailed = true;
                          });
                        }
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          SnackbarService.showError(context, message: 'connectionError'.tr());
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
                        if (!context.mounted) return;
                        SnackbarService.showError(context, message: 'invalidEndpointError'.tr());
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

  Widget _indexerEndpointSelection(BuildContext context) {
    String? selectedIndexerEndpoint;
    if (_config.hasCustomIndexer) {
      String endpoint = _config.customIndexer!;
      // Clean endpoint for display (remove paths)
      if (endpoint.contains('/v1/graphql')) {
        endpoint = endpoint.split('/v1/graphql')[0];
      }
      selectedIndexerEndpoint = endpoint;
    } else {
      selectedIndexerEndpoint = Networks.squidEndpoint.isNotEmpty
          ? (() {
              String endpoint = Networks.squidEndpoint;
              // Clean endpoint for display (remove paths)
              if (endpoint.contains('/v1/graphql')) {
                endpoint = endpoint.split('/v1/graphql')[0];
              }
              return endpoint;
            })()
          : null;
    }

    final indexerEndpointController = _indexerEndpointController;

    String getDisplayMode() {
      return _config.hasCustomIndexer ? 'Manuel' : 'Auto';
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
                                !_config.hasCustomIndexer ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: !_config.hasCustomIndexer ? context.colorScheme.primary : Colors.grey[400],
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
                                _config.hasCustomIndexer ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: _config.hasCustomIndexer ? context.colorScheme.primary : Colors.grey[400],
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
                          if (!mounted) return;
                          await _showIndexerSelectionDialog(
                            context,
                            availableEndpoints,
                            selectedIndexerEndpoint ?? '',
                            indexerEndpointController,
                          );
                        } else if (value == 'Auto') {
                          _config.customIndexer = null;
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
                          if (!_config.hasCustomIndexer) {
                            // Initialize with current endpoint if no custom one exists
                            String currentEndpoint = Networks.listSquidEndpoints.isNotEmpty
                                ? Networks.listSquidEndpoints[0]
                                : 'https://';
                            _config.customIndexer = currentEndpoint;

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

        if (!_config.hasCustomIndexer && selectedIndexerEndpoint != null)
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
                    final oldEndpoint = _config.hasCustomIndexer ? _config.customIndexer : null;

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
                          if (!context.mounted) return;
                          SnackbarService.showSuccess(context, message: 'indexerEndpointUpdated'.tr());
                        }
                      } else {
                        log.e('❌ Failed to apply Squid endpoint');
                        // Restore old endpoint
                        if (oldEndpoint != null) {
                          _config.customIndexer = oldEndpoint;
                        } else {
                          _config.customIndexer = null;
                        }
                        _syncIndexerEndpointController();
                        if (mounted) {
                          setState(() {
                            _indexerConnectionFailed = true;
                          });
                        }
                        if (mounted) {
                          if (!context.mounted) return;
                          SnackbarService.showError(context, message: 'failedApplyIndexerEndpoint'.tr());
                        }
                      }
                    } else {
                      log.w('❌ Squid endpoint test failed');
                      // Test failed - restore old endpoint
                      if (oldEndpoint != null) {
                        _config.customIndexer = oldEndpoint;
                      } else {
                        _config.customIndexer = null;
                      }
                      _syncIndexerEndpointController();
                      if (mounted) {
                        setState(() {
                          _indexerConnectionFailed = true;
                        });
                      }
                      if (mounted) {
                        if (!context.mounted) return;
                        SnackbarService.showError(context, message: 'invalidIndexerError'.tr());
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
}
