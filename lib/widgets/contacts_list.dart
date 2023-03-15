import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class ContactsList extends StatelessWidget {
  const ContactsList({
    Key? key,
    required this.myContacts,
    required this.avatarSize,
  }) : super(key: key);

  final List<G1WalletsList> myContacts;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final walletsProfilesClass =
        Provider.of<WalletsProfilesProvider>(context, listen: true);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20, width: double.infinity),
            if (myContacts.isEmpty)
              Text('noContacts'.tr())
            else
              Expanded(
                child: ListView(children: <Widget>[
                  for (G1WalletsList g1Wallet in myContacts)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ListTile(
                          key: keySearchResult('keyID++'),
                          horizontalTitleGap: 40,
                          contentPadding: const EdgeInsets.all(5),
                          leading: defaultAvatar(avatarSize),
                          title: Row(children: <Widget>[
                            Text(getShortPubkey(g1Wallet.address),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Monospace',
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center),
                          ]),
                          trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Balance(
                                                  address: g1Wallet.address,
                                                  size: 16),
                                            ]),
                                      ]),
                                ),
                              ]),
                          subtitle: Row(children: <Widget>[
                            NameByAddress(
                                wallet: WalletData(address: g1Wallet.address))
                          ]),
                          dense: false,
                          isThreeLine: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                walletsProfilesClass.address = g1Wallet.address;
                                return WalletViewScreen(
                                  address: g1Wallet.address,
                                  username: duniterIndexer.walletNameIndexer[
                                          g1Wallet.address] ??
                                      '',
                                  avatar: g1WalletsBox
                                      .get(g1Wallet.address)
                                      ?.avatar,
                                );
                              }),
                            );
                          }),
                    ),
                ]),
              )
          ]),
    );
  }
}
