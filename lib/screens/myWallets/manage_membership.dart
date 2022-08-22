import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/myWallets/migrate_identity.dart';
// import 'package:gecko/models/wallet_data.dart';
// import 'package:gecko/providers/my_wallets.dart';
// import 'package:gecko/providers/substrate_sdk.dart';
// import 'package:gecko/screens/common_elements.dart';
// import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
// import 'package:gecko/screens/transaction_in_progress.dart';
// import 'package:provider/provider.dart';

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
            title: SizedBox(
              height: 22,
              child: const Text('manageMembership').tr(),
            )),
        body: SafeArea(
          child: Column(children: <Widget>[
            const SizedBox(height: 20),
            migrateIdentity(context),
            const SizedBox(height: 10),
            revokeMyIdentity(context)
            // const SizedBox(height: 20),
          ]),
        ));
  }

  Widget migrateIdentity(BuildContext context) {
    return InkWell(
      key: keyMigrateIdentity,
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return const MigrateIdentityScreen();
          }),
        );
      },
      child: SizedBox(
        height: 60,
        child: Row(children: const <Widget>[
          SizedBox(width: 16),
          Icon(Icons.change_circle_outlined, size: 35),
          SizedBox(width: 11.5),
          Text('Migrer mon identité', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }

  Widget revokeMyIdentity(BuildContext context) {
    return InkWell(
      key: keyRevokeIdty,
      onTap: () async {
        // TODOO: Generate revoke document, and understand extrinsic identity.revokeIdentity options
        // final _answer = await confirmPopup(context,
        //         'Êtes-vous certains de vouloir révoquer définitivement cette identité ?') ??
        //     false;

        // if (_answer) {
        //   MyWalletsProvider _myWalletProvider =
        //       Provider.of<MyWalletsProvider>(context, listen: false);
        //   SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

        //   MyWalletsProvider _mw = MyWalletsProvider();
        //   final _wallet = _mw.getWalletDataByAddress(address);
        //   await _sub.setCurrentWallet(_wallet!);

        //   WalletData? defaultWallet = _myWalletProvider.getDefaultWallet();
        //   String? _pin;
        //   if (_myWalletProvider.pinCode == '') {
        //     _pin = await Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (homeContext) {
        //           return UnlockingWallet(wallet: defaultWallet);
        //         },
        //       ),
        //     );
        //   }
        //   if (_pin != null || _myWalletProvider.pinCode != '') {
        //     _sub.revokeIdentity(address, _myWalletProvider.pinCode);
        //   }
        //   Navigator.pop(context);

        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) {
        //       return const TransactionInProgress(transType: 'revokeIdty');
        //     }),
        //   );
        // }
      },
      child: SizedBox(
        height: 60,
        child: Row(children: <Widget>[
          const SizedBox(width: 20),
          Image.asset(
            'assets/skull_Icon.png',
            height: 30,
          ),
          const SizedBox(width: 16),
          const Text('Révoquer mon adhésion', style: TextStyle(fontSize: 20)),
        ]),
      ),
    );
  }
}
