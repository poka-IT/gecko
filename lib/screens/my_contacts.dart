import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/contacts_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WalletsProfilesProvider walletsProfilesClass =
        Provider.of<WalletsProfilesProvider>(context, listen: true);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    double avatarSize = 55;
    final myContacts = contactsBox.toMap().values.toList();

    myContacts.sort((p1, p2) {
      return Comparable.compare(p1.username?.toLowerCase() ?? 'zz',
          p2.username?.toLowerCase() ?? 'zz');
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 1,
        toolbarHeight: 60 * ratio,
        title: SizedBox(
          height: 22,
          child: Text(
              'contactsManagementWithNbr'.tr(args: ['${myContacts.length}'])),
        ),
      ),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: SafeArea(
        child: Stack(children: [
          ContactsList(
              myContacts: myContacts,
              avatarSize: avatarSize,
              walletsProfilesClass: walletsProfilesClass,
              duniterIndexer: duniterIndexer),
          CommonElements().offlineInfo(context),
        ]),
      ),
    );
  }
}
