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
            child: Text('Substrate Sandbox'),
          ),
        ),
        body: SafeArea(
          child: Consumer<SubstrateSdk>(builder: (context, _sub, _) {
            return SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('js-api chargé ?: ${_sub.sdkReady}'),
                    InkWell(
                        onTap: !_sub.nodeConnected
                            ? () async {
                                await _sub.connectNode();
                              }
                            : null,
                        child: Text(
                            'Noeud connecté ?: ${_sub.nodeConnected} (${_sub.subNode})')),
                    if (_sub.nodeConnected)
                      Text(
                          'Noeud "${_sub.sdk.api.connectedNode!.name}", bloc N°${_sub.blocNumber}'),
                    const SizedBox(height: 20),
                    Row(children: [
                      const Text('Liste des trousseaux:'),
                      const Spacer(),
                      InkWell(
                        child: Image.asset(
                          'assets/walletOptions/trash.png',
                          height: 35,
                        ),
                        onTap: () async {
                          await _sub.deleteAllAccounts();
                          _sub.reload();
                        },
                      ),
                      const SizedBox(width: 10),
                    ]),
                    FutureBuilder(
                        future: _sub.getKeyStoreAddress(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<AddressInfo>> _data) {
                          return Column(children: [
                            for (final AddressInfo e in _data.data!)
                              Row(children: [
                                InkWell(
                                  onTap: () => _sub.keyring.setCurrent(_sub
                                      .keyring.keyPairs
                                      .firstWhere((element) =>
                                          element.address == e.address!)),
                                  child: Text(
                                    getShortPubkey(e.address!),
                                    style: const TextStyle(
                                        fontFamily: 'Monospace'),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                InkWell(
                                  onTap: () async => await _sub.pay(
                                      context,
                                      e.address!,
                                      10,
                                      _sub.keystorePassword.text),
                                  child: Text("${e.balance.toString()} ğdev"),
                                )
                              ])
                          ]);
                        }),
                    const SizedBox(height: 20),
                    const Text('Mot de passe du trousseau:'),
                    TextField(
                      controller: _sub.keystorePassword,
                      obscureText: true,
                      obscuringCharacter: '•',
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: (_) => _sub.reload(),
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
                            onPressed: _sub.keystorePassword.text.isNotEmpty
                                ? () async {
                                    final res = await _sub.importAccount();
                                    _sub.importIsLoading = false;
                                    _sub.reload();
                                    snack(
                                        context,
                                        res
                                            ? 'Portefeuille importé'
                                            : 'Le format de trousseau est invalide');
                                  }
                                : null,
                            child: const Text(
                              'Importer le trousseau depuis le presse-papier',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          if (_sub.importIsLoading)
                            const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: yellowC, // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: () async {
                              final res = await _sub.generateMnemonic();
                              _sub.importIsLoading = false;
                              _sub.reload();
                              snack(
                                  context,
                                  res
                                      ? 'Portefeuille importé'
                                      : 'Le format de trousseau est invalide');
                            },
                            child: const Text(
                              "Générer un mnemonic et l'importer",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 400,
                            child: Text(
                              _sub.generatedMnemonic,
                              textAlign: TextAlign.center,
                            ),
                          )
                        ])
                  ]),
            );
          }),
        ),
      ),
    );
  }
}
