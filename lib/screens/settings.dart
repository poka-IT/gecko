// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show Durt, Networks, DuniterEndpoints;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/theme_provider.dart' as theme_provider;
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final MyWalletsProvider _myWallets = MyWalletsProvider();
  final FocusNode _duniterFocusNode = FocusNode();
  final FocusNode _indexerFocusNode = FocusNode();
  late TextEditingController _endpointController;
  late TextEditingController _indexerEndpointController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    _endpointController = TextEditingController(
      text: configBox.containsKey('customEndpoint') ? configBox.get('customEndpoint') : Networks.duniterEndpoint,
    );

    _indexerEndpointController = TextEditingController(
      text: configBox.containsKey('customIndexer')
          ? configBox.get('customIndexer')
          : duniterIndexer.listIndexerEndpoints.isNotEmpty
              ? duniterIndexer.listIndexerEndpoints[0]
              : 'https://',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duniterIndexer = Provider.of<DuniterIndexer>(context);

    // Mise à jour du champ node quand le nœud est connecté
    if (Durt.i.isConnected && !configBox.containsKey('customEndpoint')) {
      final endpoint = Networks.duniterEndpoint;
      if (endpoint != _endpointController.text) {
        _endpointController.text = endpoint;
      }
    }

    // Mise à jour du champ indexer quand il devient disponible
    if (duniterIndexer.listIndexerEndpoints.isNotEmpty && !configBox.containsKey('customIndexer')) {
      final indexerEndpoint = duniterIndexer.listIndexerEndpoints[0];
      if (indexerEndpoint != _indexerEndpointController.text) {
        _indexerEndpointController.text = indexerEndpoint;
      }
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

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('clearCacheExplanation'.tr()),
                              duration: const Duration(seconds: 2),
                            ),
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
                          Text(
                            'clearCache'.tr(),
                            style: scaledTextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 20 : 24),

                // Section Réseau
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
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    return InkWell(
      key: keyUdUnit,
      onTap: () async {
        await homeProvider.changeCurrencyUnit(context);
      },
      child: Row(
        children: [
          Icon(
            Icons.calculate_rounded,
            color: context.colorScheme.primary,
            size: scaleSize(24),
          ),
          ScaledSizedBox(width: 12),
          Text(
            'showUdAmounts'.tr(),
            style: scaledTextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const Spacer(),
          Consumer<HomeProvider>(
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

  Future<void> _showNodeSelectionDialog(BuildContext context, List<String> nodes, String selectedEndpoint, TextEditingController controller) async {
    final set = Provider.of<SettingsProvider>(context, listen: false);

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
                    padding: EdgeInsets.symmetric(
                      vertical: scaleSize(12),
                      horizontal: scaleSize(16),
                    ),
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
                            style: scaledTextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );

    if (result != null) {
      controller.text = result;
      configBox.put('autoEndpoint', false);
      configBox.put('customEndpoint', result);
      await Durt.i.connect(
        customDuniterEndpoints: DuniterEndpoints(endpoints: {
          Durt.i.network: [result],
        }),
      );
      set.reload();
    }
  }

  Widget duniterEndpointSelection(BuildContext context) {
    String? selectedDuniterEndpoint;

    List<String> duniterBootstrapNodes = [];

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
                Icon(
                  Icons.dns_rounded,
                  color: context.colorScheme.primary,
                  size: scaleSize(24),
                ),
                ScaledSizedBox(width: 12),
                Text(
                  'currencyNode'.tr(),
                  style: scaledTextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                ScaledSizedBox(width: 12),
                Icon(
                  Durt.i.isConnected && !Durt.i.isDuniterLoading ? Icons.check_circle : Icons.error,
                  color: Durt.i.isConnected && !Durt.i.isDuniterLoading ? Colors.green : Colors.red,
                  size: scaleSize(16),
                ),
                const Spacer(),
                Consumer<SettingsProvider>(
                  builder: (context, set, _) {
                    return PopupMenuButton<String>(
                      key: keySelectDuniterNodeDropDown,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: scaleSize(12),
                          vertical: scaleSize(6),
                        ),
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
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey[600],
                              size: scaleSize(20),
                            ),
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
                                configBox.get('autoEndpoint') == true ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: configBox.get('autoEndpoint') == true ? context.colorScheme.primary : Colors.grey[400],
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
                                configBox.get('autoEndpoint') != true ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: configBox.get('autoEndpoint') != true ? context.colorScheme.primary : Colors.grey[400],
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
                              Icon(
                                Icons.list_alt,
                                color: Colors.grey[400],
                                size: scaleSize(20),
                              ),
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
                          await _showNodeSelectionDialog(
                            context,
                            duniterBootstrapNodes.where((node) => node != 'Auto' && node != 'Personnalisé' && node != 'ws://10.0.2.2:9944').toList(),
                            selectedDuniterEndpoint ?? '',
                            endpointController,
                          );
                        } else if (value == 'Auto') {
                          configBox.delete('customEndpoint');
                          configBox.put('autoEndpoint', true);
                          await Durt.i.connect();
                          set.reload();
                        } else {
                          configBox.put('autoEndpoint', false);
                          if (!configBox.containsKey('customEndpoint')) {
                            configBox.put('customEndpoint', _endpointController.text);
                          }
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
            if (Durt.i.isDuniterLoading)
              Padding(
                padding: EdgeInsets.only(top: scaleSize(16)),
                child: Center(child: Loading(size: scaleSize(24), stroke: 2)),
              ),
          ],
        ),
        Consumer<SettingsProvider>(
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: scaleSize(12),
                        vertical: scaleSize(8),
                      ),
                      border: InputBorder.none,
                      hintText: 'wss://',
                      hintStyle: scaledTextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    onSubmitted: (value) async {
                      configBox.put('customEndpoint', value);
                      await Durt.i.connect(
                        customDuniterEndpoints: DuniterEndpoints(endpoints: {
                          Durt.i.network: [value],
                        }),
                      );
                      set.reload();
                    },
                  ),
                ),
              ],
            );
          },
        ),
        Consumer<BlockHeightProvider>(
          builder: (context, blockHeightProvider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaledSizedBox(height: 8),
                Text(
                  'blockN'.tr(args: [blockHeightProvider.blockHeight.toString()]),
                  style: scaledTextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showIndexerSelectionDialog(BuildContext context, List<String> indexers, String selectedEndpoint, TextEditingController controller) async {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final set = Provider.of<SettingsProvider>(context, listen: false);

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
              children: indexers.map((endpoint) {
                final isSelected = endpoint == selectedEndpoint;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(endpoint);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: scaleSize(12),
                      horizontal: scaleSize(16),
                    ),
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
                            endpoint,
                            style: scaledTextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );

    if (result != null) {
      controller.text = result;
      configBox.put('customIndexer', result);
      await duniterIndexer.checkIndexerEndpoint(result);
      set.reload();
    }
  }

  Widget indexerEndpointSelection(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    String? selectedIndexerEndpoint;
    if (configBox.containsKey('customIndexer')) {
      selectedIndexerEndpoint = configBox.get('customIndexer');
    } else {
      selectedIndexerEndpoint = duniterIndexer.listIndexerEndpoints.isNotEmpty ? duniterIndexer.listIndexerEndpoints[0] : 'https://';
    }

    final indexerEndpointController = _indexerEndpointController;

    String getDisplayMode() {
      return configBox.containsKey('customIndexer') ? 'Manuel' : 'Auto';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer<DuniterIndexer>(
          builder: (context, indexer, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage_rounded,
                      color: context.colorScheme.primary,
                      size: scaleSize(24),
                    ),
                    ScaledSizedBox(width: 12),
                    Text(
                      'Indexer',
                      style: scaledTextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    ScaledSizedBox(width: 12),
                    Icon(
                      _indexerEndpointController.text.isNotEmpty && _indexerEndpointController.text != 'https://' ? Icons.check_circle : Icons.error,
                      color: _indexerEndpointController.text.isNotEmpty && _indexerEndpointController.text != 'https://' ? Colors.green : Colors.red,
                      size: scaleSize(16),
                    ),
                    const Spacer(),
                    Consumer<SettingsProvider>(
                      builder: (context, set, _) {
                        return PopupMenuButton<String>(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: scaleSize(12),
                              vertical: scaleSize(6),
                            ),
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
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                  size: scaleSize(20),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'Auto',
                              child: Row(
                                children: [
                                  Icon(
                                    !configBox.containsKey('customIndexer') ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: !configBox.containsKey('customIndexer') ? context.colorScheme.primary : Colors.grey[400],
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
                                    configBox.containsKey('customIndexer') ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                    color: configBox.containsKey('customIndexer') ? context.colorScheme.primary : Colors.grey[400],
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
                                  Icon(
                                    Icons.list_alt,
                                    color: Colors.grey[400],
                                    size: scaleSize(20),
                                  ),
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
                              await _showIndexerSelectionDialog(
                                context,
                                indexer.listIndexerEndpoints.cast<String>(),
                                selectedIndexerEndpoint ?? '',
                                indexerEndpointController,
                              );
                            } else if (value == 'Auto') {
                              configBox.delete('customIndexer');
                              final defaultEndpoint = duniterIndexer.listIndexerEndpoints.isNotEmpty ? duniterIndexer.listIndexerEndpoints[0] : 'https://';
                              selectedIndexerEndpoint = defaultEndpoint;
                              indexerEndpointController.text = defaultEndpoint;
                              await indexer.checkIndexerEndpoint(defaultEndpoint);
                              set.reload();
                            } else {
                              if (!configBox.containsKey('customIndexer')) {
                                configBox.put('customIndexer', _indexerEndpointController.text);
                              }
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
                if (indexer.isLoadingIndexer)
                  Padding(
                    padding: EdgeInsets.only(top: scaleSize(16)),
                    child: Center(child: Loading(size: scaleSize(24), stroke: 2)),
                  ),
              ],
            );
          },
        ),
        Consumer<SettingsProvider>(
          builder: (context, set, _) {
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
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: scaleSize(12),
                        vertical: scaleSize(8),
                      ),
                      border: InputBorder.none,
                      hintText: 'https://',
                      hintStyle: scaledTextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    onSubmitted: (value) async {
                      configBox.put('customIndexer', value);
                      await duniterIndexer.checkIndexerEndpoint(value);
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
    final themeProvider = Provider.of<theme_provider.ThemeProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'theme'.tr(),
          style: scaledTextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        ScaledSizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<theme_provider.ThemeProvider>(
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
}
