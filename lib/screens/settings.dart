import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/globals.dart';
import 'package:polkawallet_sdk/api/types/networkParams.dart';
import 'package:provider/provider.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';

// ignore: must_be_immutable
class SettingsScreen extends StatelessWidget {
  final MyWalletsProvider _myWallets = MyWalletsProvider();

  SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
        duniterEndpointSelection(context),
        const SizedBox(height: 50),
        indexerEndpointSelection(context),

        // SizedBox(height: isTall ? 80 : 120),
        const Spacer(),
        SizedBox(
          height: buttonHigh,
          width: buttonWidth,
          child: Center(
            child: InkWell(
              key: const Key('deleteChest'),
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

  Widget duniterEndpointSelection(BuildContext context) {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    String? selectedDuniterEndpoint;

    // List of items in our dropdown menu
    var duniterBootstrapNodes = _sub.getDuniterBootstrap();
    selectedDuniterEndpoint =
        _sub.getConnectedEndpoint() ?? duniterBootstrapNodes.first.endpoint;

    final customEndpoint = NetworkParams();
    customEndpoint.name = currencyName;
    customEndpoint.endpoint = 'Personnalisé';
    customEndpoint.ss58 = ss58;

    final automaticEndpoint = NetworkParams();
    automaticEndpoint.name = currencyName;
    automaticEndpoint.endpoint = 'Auto';
    automaticEndpoint.ss58 = ss58;
    // duniterBootstrapNodes.add(_sub.getDuniterCustomEndpoint());
    duniterBootstrapNodes.insert(0, automaticEndpoint);
    duniterBootstrapNodes.add(customEndpoint);

    if (configBox.get('autoEndpoint') == true) {
      selectedDuniterEndpoint = automaticEndpoint.endpoint;
    } else if (configBox.containsKey('customEndpoint')) {
      selectedDuniterEndpoint = customEndpoint.endpoint;
    }

    TextEditingController _endpointController = TextEditingController(
        text: configBox.containsKey('customEndpoint')
            ? configBox.get('customEndpoint')
            : 'wss://');

    return Column(children: <Widget>[
      Row(children: [
        Consumer<SubstrateSdk>(builder: (context, _sub, _) {
          log.d(_sub.sdk.api.connectedNode?.endpoint);
          return Expanded(
            child: Row(children: [
              const SizedBox(width: 10),
              Text('currencyNode'.tr(args: [currencyName])),
              const Spacer(),
              Icon(_sub.nodeConnected && !_sub.isLoadingEndpoint
                  ? Icons.check
                  : Icons.close),
              const Spacer(),
              Consumer<SettingsProvider>(builder: (context, _set, _) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton(
                    // alignment: AlignmentDirectional.topStart,
                    value: selectedDuniterEndpoint,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: duniterBootstrapNodes
                        .map((NetworkParams _endpointParams) {
                      return DropdownMenuItem(
                        value: _endpointParams.endpoint,
                        child: Text(_endpointParams.endpoint!),
                      );
                    }).toList(),
                    onChanged: (String? _newEndpoint) {
                      log.d(_newEndpoint!);
                      selectedDuniterEndpoint = _newEndpoint;
                      _set.reload();
                    },
                  ),
                );
              }),
              const Spacer(flex: 5),
              _sub.isLoadingEndpoint
                  ? CircularProgressIndicator(color: orangeC)
                  : Consumer<SettingsProvider>(builder: (context, _set, _) {
                      return IconButton(
                          icon: Icon(
                            Icons.send,
                            color: selectedDuniterEndpoint !=
                                    _sub.getConnectedEndpoint()
                                ? orangeC
                                : Colors.grey[500],
                            size: 40,
                          ),
                          onPressed: selectedDuniterEndpoint !=
                                  _sub.getConnectedEndpoint()
                              ? () async {
                                  if (selectedDuniterEndpoint == 'Auto') {
                                    configBox.delete('customEndpoint');
                                    configBox.put('autoEndpoint', true);
                                  } else {
                                    configBox.put('autoEndpoint', false);
                                    final finalEndpoint =
                                        selectedDuniterEndpoint ==
                                                'Personnalisé'
                                            ? _endpointController.text
                                            : selectedDuniterEndpoint;
                                    configBox.put(
                                        'customEndpoint', finalEndpoint);
                                  }
                                  await _sub.connectNode(context);
                                }
                              : null);
                    }),
              const Spacer(flex: 8),
            ]),
          );
        }),
      ]),
      Consumer<SettingsProvider>(builder: (context, _set, _) {
        return Visibility(
          visible: selectedDuniterEndpoint == 'Personnalisé',
          child: SizedBox(
            width: 200,
            height: 50,
            child: TextField(
              controller: _endpointController,
              autocorrect: false,
            ),
          ),
        );
      }),
      Consumer<SubstrateSdk>(builder: (context, _sub, _) {
        return Consumer<SettingsProvider>(builder: (context, _set, _) {
          return Visibility(
            visible: selectedDuniterEndpoint == 'Auto',
            child: SizedBox(
              width: 250,
              height: _sub.getConnectedEndpoint() == null ? 60 : 20,
              child: Text(
                _sub.getConnectedEndpoint() ??
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

  Widget indexerEndpointSelection(BuildContext context) {
    DuniterIndexer _indexer =
        Provider.of<DuniterIndexer>(context, listen: false);

    String? selectedIndexerEndpoint;
    if (configBox.containsKey('customIndexer')) {
      selectedIndexerEndpoint = '';
    } else {
      selectedIndexerEndpoint = indexerEndpoint;
    }

    if (selectedIndexerEndpoint == '') {
      selectedIndexerEndpoint = _indexer.listIndexerEndpoints[0];
    }

    TextEditingController _endpointController = TextEditingController(
        text: configBox.containsKey('customIndexer')
            ? configBox.get('customIndexer')
            : 'https://');

    return Column(children: <Widget>[
      Row(children: [
        Consumer<DuniterIndexer>(builder: (context, _indexer, _) {
          log.d(selectedIndexerEndpoint);
          log.d(_indexer.listIndexerEndpoints);
          return Expanded(
            child: Row(children: [
              const SizedBox(width: 10),
              const Text('Indexer : '),
              const Spacer(),
              Icon(indexerEndpoint != '' ? Icons.check : Icons.close),
              const Spacer(),
              Consumer<SettingsProvider>(builder: (context, _set, _) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton(
                    // alignment: AlignmentDirectional.topStart,
                    value: selectedIndexerEndpoint,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items:
                        _indexer.listIndexerEndpoints.map((_indexerEndpoint) {
                      return DropdownMenuItem(
                        value: _indexerEndpoint,
                        child: Text(_indexerEndpoint),
                      );
                    }).toList(),
                    onChanged: (_newEndpoint) {
                      log.d(_newEndpoint!);
                      selectedIndexerEndpoint = _newEndpoint.toString();
                      _set.reload();
                    },
                  ),
                );
              }),
              const Spacer(flex: 5),
              _indexer.isLoadingIndexer
                  ? CircularProgressIndicator(color: orangeC)
                  : Consumer<SettingsProvider>(builder: (context, _set, _) {
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
                                  log.d(
                                      'connection to indexer $selectedIndexerEndpoint');
                                  await _indexer.checkIndexerEndpoint(
                                      selectedIndexerEndpoint!);
                                }
                              : null);
                    }),
              const Spacer(flex: 8),
            ]),
          );
        }),
      ]),
      Consumer<SettingsProvider>(builder: (context, _set, _) {
        return Visibility(
          visible: selectedIndexerEndpoint == 'Personnalisé',
          child: SizedBox(
            width: 200,
            height: 50,
            child: TextField(
              controller: _endpointController,
              autocorrect: false,
            ),
          ),
        );
      }),
      Consumer<SubstrateSdk>(builder: (context, _sub, _) {
        return Consumer<SettingsProvider>(builder: (context, _set, _) {
          return Visibility(
            visible: selectedIndexerEndpoint == 'Auto',
            child: SizedBox(
              width: 250,
              height: 60,
              child: Text(
                _sub.getConnectedEndpoint() ??
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
