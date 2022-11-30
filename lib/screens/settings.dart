import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/globals.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  final MyWalletsProvider _myWallets = MyWalletsProvider();

  SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double buttonHigh = 50;
    const double buttonWidth = 240;
    const double fontSize = 16;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text('parameters'.tr()),
          )),
      body: Column(children: <Widget>[
        const SizedBox(height: 30),
        Text(
          'Connectivité réseau',
          style: TextStyle(color: Colors.grey[500], fontSize: 22),
        ),
        const SizedBox(height: 20),
        duniterEndpointSelection(context),
        const SizedBox(height: 30),
        indexerEndpointSelection(context),
        const SizedBox(height: 40),
        Text(
          'Affichage',
          style: TextStyle(color: Colors.grey[500], fontSize: 22),
        ),
        const SizedBox(height: 20),
        chooseCurrencyUnit(context),

        // SizedBox(height: isTall ? 80 : 120),
        const Spacer(),
        SizedBox(
          height: buttonHigh,
          width: buttonWidth,
          child: Center(
            child: InkWell(
              key: keyDeleteAllWallets,
              onTap: () async {
                log.i('Oublier tous mes coffres');
                await _myWallets.deleteAllWallet(context);
              },
              child: Text(
                'forgetAllMyChests'.tr(),
                style: const TextStyle(
                  fontSize: fontSize + 4,
                  color: Color(0xffD80000),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        // const Spacer(),
        SizedBox(height: isTall ? 90 : 60),
      ]),
    );
  }

  Widget chooseCurrencyUnit(BuildContext context) {
    HomeProvider homeProvider =
        Provider.of<HomeProvider>(context, listen: false);
    return InkWell(
      key: keyUdUnit,
      onTap: () async {
        await homeProvider.changeCurrencyUnit(context);
      },
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Text('showUdAmounts'.tr()),
            const Spacer(),
            Consumer<HomeProvider>(builder: (context, homeProvider, _) {
              final bool isUdUnit = configBox.get('isUdUnit') ?? false;
              return Icon(
                isUdUnit ? Icons.check_box : Icons.check_box_outline_blank,
                color: orangeC,
                size: 32,
              );
            }),
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  Widget duniterEndpointSelection(BuildContext context) {
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: false);
    String? selectedDuniterEndpoint;

    // List of items in our dropdown menu
    var duniterBootstrapNodes = sub.getDuniterBootstrap();
    selectedDuniterEndpoint =
        sub.getConnectedEndpoint() ?? duniterBootstrapNodes.first.endpoint;

    final customEndpoint = NetworkParams();
    customEndpoint.endpoint = 'Personnalisé';
    final localEndpoint = NetworkParams();
    localEndpoint.endpoint = 'ws://127.0.0.1:9944';
    final automaticEndpoint = NetworkParams();
    automaticEndpoint.endpoint = 'Auto';
    // duniterBootstrapNodes.add(_sub.getDuniterCustomEndpoint());
    duniterBootstrapNodes.insert(0, automaticEndpoint);
    duniterBootstrapNodes.add(localEndpoint);
    duniterBootstrapNodes.add(customEndpoint);

    if (configBox.get('autoEndpoint') == true) {
      selectedDuniterEndpoint = automaticEndpoint.endpoint;
    } else if (configBox.containsKey('customEndpoint')) {
      selectedDuniterEndpoint = customEndpoint.endpoint;
    }

    TextEditingController endpointController = TextEditingController(
        text: configBox.containsKey('customEndpoint')
            ? configBox.get('customEndpoint')
            : 'wss://');

    return Column(children: <Widget>[
      Row(children: [
        Consumer<SubstrateSdk>(builder: (context, sub, _) {
          log.d(sub.sdk.api.connectedNode?.endpoint);
          return Expanded(
            child: Row(children: [
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: Text(
                  'currencyNode'.tr(args: [currencyName]),
                ),
              ),
              const Spacer(),
              Icon(sub.nodeConnected && !sub.isLoadingEndpoint
                  ? Icons.check
                  : Icons.close),
              if (sub.nodeConnected && !sub.isLoadingEndpoint)
                const Icon(Icons.add_card_sharp, size: 0.01),
              const Spacer(),
              SizedBox(
                width: 265,
                child: Consumer<SettingsProvider>(builder: (context, set, _) {
                  return DropdownButtonHideUnderline(
                    key: keySelectDuniterNodeDropDown,
                    child: DropdownButton(
                      // alignment: AlignmentDirectional.topStart,
                      value: selectedDuniterEndpoint,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: duniterBootstrapNodes
                          .map((NetworkParams endpointParams) {
                        return DropdownMenuItem(
                          key: keySelectDuniterNode(endpointParams.endpoint!),
                          value: endpointParams.endpoint,
                          child: Text(endpointParams.endpoint!),
                        );
                      }).toList(),
                      onChanged: (String? newEndpoint) {
                        log.d(newEndpoint!);
                        selectedDuniterEndpoint = newEndpoint;
                        set.reload();
                      },
                    ),
                  );
                }),
              ),
              const Spacer(flex: 5),
              sub.isLoadingEndpoint
                  ? const CircularProgressIndicator(color: orangeC)
                  : Consumer<SettingsProvider>(builder: (context, set, _) {
                      return IconButton(
                          key: keyConnectToEndpoint,
                          icon: Icon(
                            Icons.send,
                            color: selectedDuniterEndpoint !=
                                    sub.getConnectedEndpoint()
                                ? orangeC
                                : Colors.grey[500],
                            size: 40,
                          ),
                          onPressed: selectedDuniterEndpoint !=
                                  sub.getConnectedEndpoint()
                              ? () async {
                                  if (selectedDuniterEndpoint == 'Auto') {
                                    configBox.delete('customEndpoint');
                                    configBox.put('autoEndpoint', true);
                                  } else {
                                    configBox.put('autoEndpoint', false);
                                    final finalEndpoint =
                                        selectedDuniterEndpoint ==
                                                'Personnalisé'
                                            ? endpointController.text
                                            : selectedDuniterEndpoint;
                                    configBox.put(
                                        'customEndpoint', finalEndpoint);
                                  }
                                  await sub.connectNode(context);
                                }
                              : null);
                    }),
              const Spacer(flex: 8),
            ]),
          );
        }),
      ]),
      Consumer<SettingsProvider>(builder: (context, set, _) {
        return Visibility(
          visible: selectedDuniterEndpoint == 'Personnalisé',
          child: SizedBox(
            width: 200,
            height: 50,
            child: TextField(
              key: keyCustomDuniterEndpoint,
              controller: endpointController,
              autocorrect: false,
            ),
          ),
        );
      }),
      Consumer<SubstrateSdk>(builder: (context, sub, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<SettingsProvider>(builder: (context, set, _) {
              return Visibility(
                visible: selectedDuniterEndpoint == 'Auto',
                child: SizedBox(
                  width: 250,
                  height: sub.getConnectedEndpoint() == null ? 60 : 20,
                  child: Text(
                    sub.getConnectedEndpoint() ??
                        "Un noeud sûr et valide sera choisi automatiquement parmis une liste aléatoire.",
                    style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700]),
                  ),
                ),
              );
            }),
            Text(
              'bloc N°${sub.blocNumber}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            )
          ],
        );
      }),
    ]);
  }

  Widget indexerEndpointSelection(BuildContext context) {
    DuniterIndexer indexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    String? selectedIndexerEndpoint;
    if (configBox.containsKey('customIndexer')) {
      selectedIndexerEndpoint = 'Personnalisé';
    } else {
      selectedIndexerEndpoint = indexerEndpoint;
    }

    if (selectedIndexerEndpoint == '') {
      selectedIndexerEndpoint = indexer.listIndexerEndpoints[0];
    }

    TextEditingController indexerEndpointController = TextEditingController(
        text: configBox.containsKey('customIndexer')
            ? configBox.get('customIndexer')
            : 'https://');

    return Column(children: <Widget>[
      Row(children: [
        Consumer<DuniterIndexer>(builder: (context, indexer, _) {
          log.d(selectedIndexerEndpoint);
          log.d(indexer.listIndexerEndpoints);
          return Expanded(
            child: Row(children: [
              const SizedBox(width: 10),
              const SizedBox(
                width: 100,
                child: Text('Indexer : '),
              ),
              const Spacer(),
              Icon(indexerEndpoint != '' ? Icons.check : Icons.close),
              const Spacer(),
              SizedBox(
                width: 265,
                child: Consumer<SettingsProvider>(builder: (context, set, _) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton(
                      // alignment: AlignmentDirectional.topStart,
                      value: selectedIndexerEndpoint,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items:
                          indexer.listIndexerEndpoints.map((indexerEndpoint) {
                        return DropdownMenuItem(
                          value: indexerEndpoint,
                          child: Text(indexerEndpoint),
                        );
                      }).toList(),
                      onChanged: (newEndpoint) {
                        log.d(newEndpoint!);
                        selectedIndexerEndpoint = newEndpoint.toString();
                        set.reload();
                      },
                    ),
                  );
                }),
              ),
              const Spacer(flex: 5),
              indexer.isLoadingIndexer
                  ? const CircularProgressIndicator(color: orangeC)
                  : Consumer<SettingsProvider>(builder: (context, set, _) {
                      return IconButton(
                          icon: Icon(
                            Icons.send,
                            color: selectedIndexerEndpoint != indexerEndpoint
                                ? orangeC
                                : Colors.grey[500],
                            size: 40,
                          ),
                          onPressed: selectedIndexerEndpoint != indexerEndpoint
                              ? () async {
                                  final finalEndpoint =
                                      selectedIndexerEndpoint == 'Personnalisé'
                                          ? indexerEndpointController.text
                                          : selectedIndexerEndpoint!;

                                  if (selectedIndexerEndpoint ==
                                      'Personnalisé') {
                                    configBox.put('customIndexer',
                                        indexerEndpointController.text);
                                  } else {
                                    configBox.delete('customIndexer');
                                  }
                                  log.d('connection to indexer $finalEndpoint');
                                  await indexer
                                      .checkIndexerEndpoint(finalEndpoint);
                                }
                              : null);
                    }),
              const Spacer(flex: 8),
            ]),
          );
        }),
      ]),
      Consumer<SettingsProvider>(builder: (context, set, _) {
        return Visibility(
          visible: selectedIndexerEndpoint == 'Personnalisé',
          child: SizedBox(
            width: 200,
            height: 50,
            child: TextField(
              controller: indexerEndpointController,
              autocorrect: false,
            ),
          ),
        );
      }),
      Consumer<SubstrateSdk>(builder: (context, sub, _) {
        return Consumer<SettingsProvider>(builder: (context, set, _) {
          return Visibility(
            visible: selectedIndexerEndpoint == 'Auto',
            child: SizedBox(
              width: 250,
              height: 60,
              child: Text(
                sub.getConnectedEndpoint() ??
                    "Un noeud sûr et valide sera choisi automatiquement parmis une liste aléatoire.",
                style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700]),
              ),
            ),
          );
        });
      }),
    ]);
  }
}
