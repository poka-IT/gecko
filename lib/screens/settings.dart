import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/settings_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/globals.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class SettingsScreen extends StatelessWidget {
  final MyWalletsProvider _myWallets = MyWalletsProvider();

  SettingsScreen({Key? key}) : super(key: key);

  // Initial Selected Value
  String dropdownvalue = 'Item 1';

  // List of items in our dropdown menu
  var items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    TextEditingController _endpointController = TextEditingController(
        text: _sub.sdk.api.connectedNode?.endpoint ??
            configBox.get('endpoint').first);

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
        const SizedBox(height: 60),
        Consumer<SettingsProvider>(builder: (context, _set, _) {
          return DropdownButton(
            value: dropdownvalue,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: items.map((String items) {
              return DropdownMenuItem(
                value: items,
                child: Text(items),
              );
            }).toList(),
            onChanged: (String? newValue) {
              log.d('coucoucoucouc');
              dropdownvalue = newValue!;
              _set.reload();
            },
          );
        }),
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
                SizedBox(
                  width: 200,
                  height: 50,
                  child: TextField(
                    controller: _endpointController,
                    autocorrect: false,
                  ),
                ),
                const Spacer(flex: 5),
                _sub.isLoadingEndpoint
                    ? CircularProgressIndicator(color: orangeC)
                    : IconButton(
                        icon: Icon(
                          Icons.send,
                          color: orangeC,
                          size: 40,
                        ),
                        onPressed: () async {
                          configBox.put('endpoint', [_endpointController.text]);
                          await _sub.connectNode(context);
                        }),
                const Spacer(flex: 8),
              ]),
            );
          }),
        ]),
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
}
