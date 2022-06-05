import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:provider/provider.dart';

class ManageMembership extends StatelessWidget {
  const ManageMembership({Key? key, required this.address}) : super(key: key);
  final String address;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Gérer mon adhésion'),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 20),
            revokeMyIdentity(context),
            // const SizedBox(height: 20),
          ]),
        ));
  }

  Widget revokeMyIdentity(BuildContext context) {
    return InkWell(
      key: const Key('revokeIdty'),
      onTap: () async {
        final _answer = await confirmPopup(context,
                'Êtes-vous certains de vouloir révoquer définitivement cette identité ?') ??
            false;

        if (_answer) {
          MyWalletsProvider _myWalletProvider =
              Provider.of<MyWalletsProvider>(context, listen: false);
          SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

          MyWalletsProvider _mw = MyWalletsProvider();
          final _wallet = _mw.getWalletDataByAddress(address);
          await _sub.setCurrentWallet(_wallet!);

          WalletData? defaultWallet = _myWalletProvider.getDefaultWallet();
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
            _sub.revokeIdentity(address, _myWalletProvider.pinCode);
          }
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const TransactionInProgress(transType: 'revokeIdty');
            }),
          );
        }
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) {
        //     return ManageMembership(
        //       address: _walletOptions.address.text,
        //     );
        //   }),
        // );
      },
      child: SizedBox(
        height: 40,
        child: Row(children: const <Widget>[
          SizedBox(width: 32),
          // Image.asset(
          //   'assets/medal.png',
          //   height: 45,
          // ),
          Text('Révoquer mon adhésion', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }
}
