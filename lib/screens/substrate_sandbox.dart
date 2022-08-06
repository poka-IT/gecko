// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/stateful_wrapper.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class SubstrateSandBox extends StatelessWidget {
  const SubstrateSandBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    return StatefulWrapper(
      onInit: () async {
        // if (!_sub.sdkReady && !_sub.sdkLoading) await _sub.initApi();
        // if (_sub.sdkReady && !_sub.nodeConnected) await _sub.connectNode();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text('⏳ Substrate Sandbox'),
          ),
        ),
        body: SafeArea(
          child: Consumer<SubstrateSdk>(builder: (context, sub, _) {
            return SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('js-api chargé ?: ${sub.sdkReady}'),
                    InkWell(
                        onTap: () async {
                          await sub.connectNode(context);
                        },
                        child: Text(
                            '🌐 Noeud connecté ?: ${sub.nodeConnected} (${sub.sdk.api.connectedNode?.endpoint})')),
                    if (sub.nodeConnected)
                      Text(
                          '🏆 Noeud "$currencyName", bloc N°${sub.blocNumber}'),
                    const SizedBox(height: 20),
                    Row(children: [
                      const Text('💳 Liste des coffres:'),
                      const Spacer(),
                      InkWell(
                        child: Image.asset(
                          'assets/walletOptions/trash.png',
                          height: 35,
                        ),
                        onTap: () async {
                          await sub.deleteAllAccounts();
                          sub.reload();
                        },
                      ),
                      const SizedBox(width: 10),
                    ]),
                    FutureBuilder(
                        future: sub.getKeyStoreAddress(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<AddressInfo>> data) {
                          return Column(children: [
                            if (data.data != null)
                              for (final AddressInfo addressInfo in data.data!)
                                Row(children: [
                                  InkWell(
                                    onTap: () => sub.keyring.setCurrent(sub
                                        .keyring.keyPairs
                                        .firstWhere((element) =>
                                            element.address ==
                                            addressInfo.address!)),
                                    child: Text(
                                      getShortPubkey(addressInfo.address!),
                                      style: const TextStyle(
                                          fontFamily: 'Monospace'),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // InkWell(
                                  //   onTap: () async => await _sub.pay(
                                  //       context,
                                  //       addressInfo.address!,
                                  //       10,
                                  //       _sub.keystorePassword.text),
                                  //   child:
                                  Text(
                                      "${addressInfo.balance.toString()} $currencyName"),
                                  // ),
                                  const SizedBox(width: 20),
                                  InkWell(
                                    onTap: () async => await sub.derive(
                                        context,
                                        addressInfo.address!,
                                        2,
                                        sub.keystorePassword.text),
                                    child: const Text("🏂 Dériver"),
                                  )
                                ])
                          ]);
                        }),
                    const SizedBox(height: 20),
                    const Text('🔒 Mot de passe du coffre:'),
                    TextField(
                      controller: sub.keystorePassword,
                      obscureText: true,
                      obscuringCharacter: '•',
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: (_) => sub.reload(),
                    ),
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20, width: double.infinity),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: yellowC, // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: sub.keystorePassword.text.isNotEmpty
                                ? () async {
                                    final res = await sub.importAccount();
                                    sub.importIsLoading = false;
                                    sub.reload();
                                    snack(
                                        context,
                                        res != ''
                                            ? 'Portefeuille importé'
                                            : 'Le format de coffre est invalide');
                                  }
                                : null,
                            child: const Text(
                              '📎 Importer depuis le presse-papier',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          if (sub.importIsLoading)
                            const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: yellowC, // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: () async {
                              await sub.generateMnemonic();
                              sub.importIsLoading = false;
                              sub.reload();
                              snack(context, 'Le mnemonic a été copié');
                            },
                            child: const Text(
                              "🏦 Générer un mnemonic et le copier",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 400,
                            child: Text(
                              sub.generatedMnemonic,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Text('-〰️---〰️---〰️-'),
                          const SizedBox(height: 10),
                          Text(sub.debugConnection)
                        ])
                  ]),
            );
          }),
        ),
      ),
    );
  }
}
