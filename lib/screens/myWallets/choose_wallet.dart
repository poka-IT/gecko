import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChooseWalletScreen extends StatelessWidget {
  ChooseWalletScreen({Key? key, required this.chest, required this.pin})
      : super(key: key);
  final int chest;
  final String pin;
  int? _derivation;
  List<int?>? _selectedId;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    WalletsProfilesProvider _walletViewProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Choix du portefeuille source'),
            )),
        body: SafeArea(
          child: Stack(children: [
            myWalletsTiles(context, chest),
            Positioned.fill(
              bottom: 60,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 470,
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      primary: orangeC, // background
                      onPrimary: Colors.white, // foreground
                    ),
                    onPressed: () async {
                      final acc = _sub.getCurrentWallet();
                      log.d(
                          "fromAddress: ${acc.address!},destAddress: ${_walletViewProvider.outputPubkey.text}, amount: ${double.parse(_walletViewProvider.payAmount.text)},  password: $pin");
                      final resultPay = await _sub.pay(context,
                          fromAddress: acc.address!,
                          destAddress: _walletViewProvider.outputPubkey.text,
                          amount:
                              double.parse(_walletViewProvider.payAmount.text),
                          password: pin);
                      await paymentsResult(context, resultPay);
                    },
                    child: const Text(
                      'Valider le paiement',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
            // const SizedBox(height: 160),
          ]),
        ));
  }

  Widget myWalletsTiles(BuildContext context, int? currentChest) {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData? defaultWallet =
        _myWalletProvider.getDefaultWallet(currentChest);

    _selectedId ??= defaultWallet!.id();
    _derivation ??= defaultWallet!.derivation!;
    _sub.setCurrentWallet(defaultWallet!.address!);
    _myWalletProvider.readAllWallets(currentChest);

    if (!isWalletsExists) {
      return const Text('');
    }

    if (_myWalletProvider.listWallets.isEmpty) {
      return Column(children: const <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        )),
      ]);
    }

    List _listWallets = _myWalletProvider.listWallets;
    final double screenWidth = MediaQuery.of(context).size.width;
    int nTule = 2;

    if (screenWidth >= 900) {
      nTule = 4;
    } else if (screenWidth >= 650) {
      nTule = 3;
    }

    return CustomScrollView(slivers: <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      SliverGrid.count(
          key: const Key('listWallets'),
          crossAxisCount: nTule,
          childAspectRatio: 1,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          children: <Widget>[
            for (WalletData _repository in _listWallets as Iterable<WalletData>)
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () {
                      _derivation = _repository.derivation!;
                      _selectedId = _repository.id();
                      _sub.setCurrentWallet(_repository.address!);
                      _myWalletProvider.rebuildWidget();
                    },
                    child: ClipOvalShadow(
                      shadow: const Shadow(
                        color: Colors.transparent,
                        offset: Offset(0, 0),
                        blurRadius: 5,
                      ),
                      clipper: CustomClipperOval(),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        child: Column(children: <Widget>[
                          Expanded(
                              child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                                gradient: RadialGradient(
                              radius: 0.6,
                              colors: [
                                Colors.green[400]!,
                                const Color(0xFFE7E7A6),
                              ],
                            )),
                            child: _repository.imageFile == null
                                ? Image.asset(
                                    'assets/avatars/${_repository.imageName}',
                                    alignment: Alignment.bottomCenter,
                                    scale: 0.5,
                                  )
                                : Image.file(
                                    _repository.imageFile!,
                                    alignment: Alignment.bottomCenter,
                                    scale: 0.5,
                                  ),
                          )),
                          ListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            tileColor: _repository.id()[1] == _selectedId![1]
                                ? orangeC
                                : const Color(0xffFFD58D),
                            title: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  _repository.name!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 17.0,
                                      color:
                                          _repository.id()[1] == _selectedId![1]
                                              ? const Color(0xffF9F9F1)
                                              : Colors.black,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                            onTap: () {
                              _derivation = _repository.derivation!;
                              _selectedId = _repository.id();
                              _sub.setCurrentWallet(_repository.address!);
                              _myWalletProvider.rebuildWidget();
                            },
                          )
                        ]),
                      ),
                    ),
                  )),
          ]),
    ]);
  }
}

Future<bool?> paymentsResult(context, String resultPay) {
  final bool isValid = resultPay == "confirmed";
  if (!isValid) log.e(resultPay);

  return showDialog<bool>(
    context: context,
    barrierDismissible: true, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(isValid
            ? 'Paiement effecuté avec succès !'
            : "Une erreur s'est produite lors du paiement:\n$resultPay"),
        content: const SingleChildScrollView(child: Text('')),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () async {
              isValid
                  ? await Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      ModalRoute.withName('/'),
                    )
                  : Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}
