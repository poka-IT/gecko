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
                    const Text('Liste des trousseaux:'),
                    Text(keystoreBox.isEmpty
                        ? '-'
                        : _sub.getKeyStoreAddress().toString()),
                    const SizedBox(height: 40),
                    const Text('Trousseau:'),
                    TextField(
                      controller: _sub.jsonKeystore,
                      onChanged: (_) => _sub.reload(),
                      minLines: 5,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    const Text('Mot de passe:'),
                    TextField(
                      controller: _sub.keystorePassword,
                      obscureText: true,
                      obscuringCharacter: '•',
                      onChanged: (_) => _sub.reload(),
                    ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: yellowC, // background
                          onPrimary: Colors.black, // foreground
                        ),
                        onPressed: _sub.jsonKeystore.text.isNotEmpty &&
                                _sub.keystorePassword.text.isNotEmpty
                            ? () async => await _sub.importFromKeystore()
                            : null,
                        child: const Text(
                          'Importer la trousseau',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: yellowC, // background
                          onPrimary: Colors.black, // foreground
                        ),
                        onPressed: () async =>
                            print(await _sub.generateMnemonic()),
                        child: const Text(
                          'Générer un mnemonic',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ]),
                  ]),
            );
          }),
        ),
      ),
    );
  }
}
