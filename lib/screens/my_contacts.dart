import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/contacts_list.dart';
import 'package:provider/provider.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Provider.of<WalletsProfilesProvider>(context, listen: true);
    final myContacts = contactsBox.toMap().values.toList();

    // Order contacts by username
    myContacts.sort((p1, p2) {
      return Comparable.compare(p1.username?.toLowerCase() ?? 'zz',
          p2.username?.toLowerCase() ?? 'zz');
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: GeckoAppBar(
          'contactsManagementWithNbr'.tr(args: ['${myContacts.length}'])),
      bottomNavigationBar: const GeckoBottomAppBar(),
      body: SafeArea(
        child: Stack(children: [
          ContactsList(myContacts: myContacts),
          const OfflineInfo(),
        ]),
      ),
    );
  }
}
