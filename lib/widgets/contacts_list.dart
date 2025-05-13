import 'package:durt2/durt2.dart' show WalletData;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class ContactsList extends StatelessWidget {
  const ContactsList({
    super.key,
    required this.myContacts,
  });

  final List<G1WalletsList> myContacts;

  void _showContactMenu(BuildContext context, G1WalletsList contact) {
    final walletsProfilesClass = Provider.of<WalletsProfilesProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'removeContact'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  walletsProfilesClass.addContact(contact);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletsProfilesClass = Provider.of<WalletsProfilesProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        ScaledSizedBox(height: 10, width: double.infinity),
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
                      horizontalTitleGap: 7,
                      contentPadding: const EdgeInsets.all(5),
                      dense: !isTall,
                      leading: DatapodAvatar(address: g1Wallet.address, size: 47),
                      title: Row(children: <Widget>[
                        Expanded(
                          child: Text(
                            getShortPubkey(g1Wallet.address),
                            style: scaledTextStyle(fontSize: 14, fontFamily: 'Monospace', fontWeight: FontWeight.w500),
                            textAlign: TextAlign.left,
                            softWrap: true,
                          ),
                        ),
                      ]),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ScaledSizedBox(
                          width: 110,
                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Balance(address: g1Wallet.address, size: scaleSize(13)),
                            ]),
                          ]),
                        ),
                      ]),
                      subtitle: Row(children: <Widget>[NameByAddress(size: scaleSize(14), wallet: WalletData(address: g1Wallet.address))]),
                      isThreeLine: false,
                      onLongPress: () => _showContactMenu(context, g1Wallet),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            walletsProfilesClass.address = g1Wallet.address;
                            return WalletViewScreen(address: g1Wallet.address, username: duniterIndexer.walletNameIndexer[g1Wallet.address]);
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
