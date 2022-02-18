import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/stateful_wrapper.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class SubstrateSandBox extends StatelessWidget {
  const SubstrateSandBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    return StatefulWrapper(
      onInit: () async {
        await _sub.initApi();
        await _sub.connectNode();
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
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('js-api chargé ?: ${_sub.sdkReady}'),
                  Text(
                      'Noeud connecté ?: ${_sub.nodeConnected} (${_sub.subNode})'),
                  if (_sub.nodeConnected)
                    Text('Numéro de bloc: ${_sub.blocNumber}'),
                  const SizedBox(height: 20),
                  const Text('List des trousseaux:'),
                  Text(keystoreBox.isEmpty
                      ? '-'
                      : keystoreBox.toMap().entries.toString()),
                  const SizedBox(height: 20),
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
                  ]),
                ]);
          }),
        ),
      ),
    );
  }
}
