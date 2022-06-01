import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:provider/provider.dart';

class CustomDerivation extends StatefulWidget {
  const CustomDerivation({Key? key}) : super(key: key);

  @override
  State<CustomDerivation> createState() => _CustomDerivationState();
}

class _CustomDerivationState extends State<CustomDerivation> {
  String? dropdownValue;

  @override
  void initState() {
    dropdownValue = 'root';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    final derivationList = <String>[
      'root',
      for (var i = 0; i < 51; i += 1) i.toString()
    ];

    final listWallets = _myWalletProvider.readAllWallets();

    for (WalletData _wallet in listWallets) {
      derivationList.remove(_wallet.derivation.toString());
      if (_wallet.derivation == -1) {
        derivationList.remove('root');
      }
    }

    if (!derivationList.contains(dropdownValue)) {
      dropdownValue = derivationList.first;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: const SizedBox(
            height: 22,
            child: Text('Créer une dérivation personnalisé'),
          )),
      body: Center(
        child: SafeArea(
          child: Column(children: <Widget>[
            const Spacer(),
            const Text(
              'Choisissez une dérivation:',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 100,
              child: DropdownButton<String>(
                value: dropdownValue,
                menuMaxHeight: 300,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: TextStyle(color: orangeC),
                underline: Container(
                  height: 2,
                  color: orangeC,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
                items: derivationList
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                      value: value,
                      child: SizedBox(
                        width: 75,
                        child: Row(children: [
                          const Spacer(),
                          Text(
                            value,
                            style: const TextStyle(
                                fontSize: 20, color: Colors.black),
                          ),
                          const Spacer(),
                        ]),
                      ));
                }).toList(),
              ),
            ),
            const Spacer(flex: 1),
            SizedBox(
              width: 410,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  primary: orangeC, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () async {
                  WalletData? defaultWallet =
                      _myWalletProvider.getDefaultWallet();
                  String? _pin;
                  if (_myWalletProvider.pinCode == '') {
                    _pin = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (homeContext) {
                          return UnlockingWallet(wallet: defaultWallet);
                        },
                      ),
                    );
                  }

                  if (_pin != null || _myWalletProvider.pinCode != '') {
                    String _newDerivationName =
                        'Portefeuille ${_myWalletProvider.listWallets.last.number! + 2}';
                    if (dropdownValue == 'root') {
                      await _myWalletProvider.generateRootWallet(
                          context, 'Portefeuille racine');
                    } else {
                      await _myWalletProvider.generateNewDerivation(
                        context,
                        _newDerivationName,
                        int.parse(dropdownValue!),
                      );
                    }
                    Navigator.pop(context);
                    Navigator.pop(context);
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) {
                    //     return const WalletsHome();
                    //   }),
                    // );
                  }
                },
                child: const Text(
                  'Valider',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Spacer(),
          ]),
        ),
      ),
    );
  }
}
