import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  final MyWalletsProvider _myWallets = MyWalletsProvider();

  SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar('parameters'.tr()),
      body: Column(children: <Widget>[
        ScaledSizedBox(height: 30),
        Text(
          'networkSettings'.tr(),
          style: scaledTextStyle(color: Colors.grey[500]!, fontSize: 19),
        ),
        ScaledSizedBox(height: 20),
        duniterEndpointSelection(context),
        ScaledSizedBox(height: 30),
        indexerEndpointSelection(context),
        ScaledSizedBox(height: 35),
        Text(
          'displaySettings'.tr(),
          style: scaledTextStyle(color: Colors.grey[500]!, fontSize: 19),
        ),
        ScaledSizedBox(height: 20),
        chooseCurrencyUnit(context),

        const Spacer(),
        Center(
          child: InkWell(
            key: keyDeleteAllWallets,
            onTap: () async {
              log.w('Oublier tous mes coffres');
              await _myWallets.deleteAllWallet(context);
            },
            child: ScaledSizedBox(
              height: scaleSize(40),
              width: 220,
              child: Center(
                child: Text(
                  'forgetAllMyChests'.tr(),
                  style: scaledTextStyle(
                    fontSize: 17,
                    color: const Color(0xffD80000),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        // const Spacer(),
        ScaledSizedBox(height: 70),
      ]),
    );
  }

  Widget chooseCurrencyUnit(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    return InkWell(
      key: keyUdUnit,
      onTap: () async {
        await homeProvider.changeCurrencyUnit(context);
      },
      child: ScaledSizedBox(
        height: 50,
        child: Row(
          children: [
            ScaledSizedBox(width: 12),
            Text('showUdAmounts'.tr(), style: scaledTextStyle(fontSize: 15)),
            const Spacer(),
            Consumer<HomeProvider>(builder: (context, homeProvider, _) {
              final bool isUdUnit = configBox.get('isUdUnit') ?? false;
              return Icon(
                isUdUnit ? Icons.check_box : Icons.check_box_outline_blank,
                color: orangeC,
                size: scaleSize(27),
              );
            }),
            ScaledSizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  Widget duniterEndpointSelection(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    String? selectedDuniterEndpoint;

    // List of items in our dropdown menu
    var duniterBootstrapNodes = sub.getDuniterBootstrap();
    selectedDuniterEndpoint =
        sub.getConnectedEndpoint() ?? duniterBootstrapNodes.first.endpoint;

    final customEndpoint = NetworkParams();
    customEndpoint.endpoint = 'Personnalisé';
    final localEndpoint = NetworkParams();
    localEndpoint.endpoint = 'ws://10.0.2.2:9944';
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

    final endpointController = TextEditingController(
        text: configBox.containsKey('customEndpoint')
            ? configBox.get('customEndpoint')
            : 'wss://');

    return Column(children: <Widget>[
      Row(children: [
        Consumer<SubstrateSdk>(builder: (context, sub, _) {
          return Expanded(
            child: Row(children: [
              ScaledSizedBox(width: 2),
              ScaledSizedBox(
                width: 55,
                child: Text(
                  'currencyNode'.tr(),
                  style: scaledTextStyle(fontSize: 15),
                ),
              ),
              const Spacer(),
              ScaledSizedBox(
                width: 30,
                child: Icon(sub.nodeConnected && !sub.isLoadingEndpoint
                    ? Icons.check
                    : Icons.close),
              ),
              if (sub.nodeConnected && !sub.isLoadingEndpoint)
                const Icon(Icons.add_card_sharp, size: 0.01),
              const Spacer(),
              ScaledSizedBox(
                height: 52,
                width: 230,
                child: Consumer<SettingsProvider>(builder: (context, set, _) {
                  return DropdownButtonHideUnderline(
                    key: keySelectDuniterNodeDropDown,
                    child: DropdownButton(
                      style: scaledTextStyle(fontSize: 15, color: Colors.black),
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
                        selectedDuniterEndpoint = newEndpoint;
                        set.reload();
                      },
                    ),
                  );
                }),
              ),
              const Spacer(flex: 3),
              sub.isLoadingEndpoint
                  ? Loading(size: scaleSize(32), stroke: 2.5)
                  : Consumer<SettingsProvider>(builder: (context, set, _) {
                      return IconButton(
                          key: keyConnectToEndpoint,
                          icon: Icon(
                            Icons.send,
                            color: selectedDuniterEndpoint !=
                                    sub.getConnectedEndpoint()
                                ? orangeC
                                : Colors.grey[500],
                            size: scaleSize(35),
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
                                  await sub.connectNode();
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
          child: ScaledSizedBox(
            width: 200,
            height: 50,
            child: TextField(
              key: keyCustomDuniterEndpoint,
              controller: endpointController,
              autocorrect: false,
              style: scaledTextStyle(fontSize: 15),
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
                child: ScaledSizedBox(
                  width: 250,
                  height: sub.getConnectedEndpoint() == null ? 60 : 20,
                  child: Text(
                    sub.getConnectedEndpoint() ?? "anAutoNodeChoosed".tr(),
                    style: scaledTextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700]!),
                  ),
                ),
              );
            }),
            Text(
              'blockN'.tr(args: [
                sub.blocNumber.toString()
              ]), //'bloc N°${sub.blocNumber}',
              style: scaledTextStyle(fontSize: 14, color: Colors.grey[700]),
            )
          ],
        );
      }),
    ]);
  }

  Widget indexerEndpointSelection(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    String? selectedIndexerEndpoint;
    if (configBox.containsKey('customIndexer')) {
      selectedIndexerEndpoint = 'Personnalisé';
    } else {
      selectedIndexerEndpoint = indexerEndpoint;
    }

    if (selectedIndexerEndpoint == '') {
      selectedIndexerEndpoint = duniterIndexer.listIndexerEndpoints[0];
    }

    final indexerEndpointController = TextEditingController(
        text: configBox.containsKey('customIndexer')
            ? configBox.get('customIndexer')
            : 'https://');

    return Column(children: <Widget>[
      Row(children: [
        Consumer<DuniterIndexer>(builder: (context, indexer, _) {
          return Expanded(
            child: Row(children: [
              ScaledSizedBox(width: 5),
              ScaledSizedBox(
                width: 55,
                child: Text('Indexer', style: scaledTextStyle(fontSize: 15)),
              ),
              const Spacer(),
              Icon(indexerEndpoint != '' ? Icons.check : Icons.close),
              const Spacer(),
              ScaledSizedBox(
                width: 230,
                child: Consumer<SettingsProvider>(builder: (context, set, _) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton(
                      style: scaledTextStyle(fontSize: 15, color: Colors.black),
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
                        selectedIndexerEndpoint = newEndpoint.toString();
                        set.reload();
                      },
                    ),
                  );
                }),
              ),
              const Spacer(flex: 5),
              indexer.isLoadingIndexer
                  ? Loading(size: scaleSize(32), stroke: 2.5)
                  : Consumer<SettingsProvider>(builder: (context, set, _) {
                      return IconButton(
                          icon: Icon(
                            Icons.send,
                            color: selectedIndexerEndpoint != indexerEndpoint
                                ? orangeC
                                : Colors.grey[500],
                            size: scaleSize(35),
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
          child: ScaledSizedBox(
            width: 200,
            height: 50,
            child: TextField(
              controller: indexerEndpointController,
              autocorrect: false,
              style: scaledTextStyle(fontSize: 15),
            ),
          ),
        );
      }),
      Consumer<SubstrateSdk>(builder: (context, sub, _) {
        return Consumer<SettingsProvider>(builder: (context, set, _) {
          return Visibility(
            visible: selectedIndexerEndpoint == 'Auto',
            child: ScaledSizedBox(
              width: 250,
              height: 60,
              child: Text(
                sub.getConnectedEndpoint() ?? "anAutoNodeChoosed".tr(),
                style: scaledTextStyle(
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
