import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/debug_screen.dart';
import 'package:gecko/screens/my_contacts.dart';
import 'package:gecko/screens/settings.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    Key? key,
    required this.isWalletsExists,
  }) : super(key: key);

  final bool isWalletsExists;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
              child: ListView(padding: EdgeInsets.zero, children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: orangeC,
              ),
              child: Column(children: const <Widget>[
                SizedBox(height: 0),
                Image(
                    image: AssetImage('assets/icon/gecko_final.png'),
                    height: 130),
              ]),
            ),
            ListTile(
              key: keyParameters,
              title: Text('parameters'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return SettingsScreen();
                  }),
                );
              },
            ),
            if (isWalletsExists)
              ListTile(
                key: keyContacts,
                title: Text('contactsManagement'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const ContactsScreen();
                    }),
                  );
                },
              ),
            if (kDebugMode)
              ListTile(
                key: keyParameters,
                title: Text('Debug screen'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const DebugScreen();
                    }),
                  );
                },
              ),
          ])),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: InkWell(
                key: keyCopyAddress,
                splashColor: orangeC,
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Ğecko v$appVersion')),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'Ğecko v$appVersion'));
                  snackMessage(context,
                      message:
                          'Le numéro de version de Ğecko a été copié dans votre presse papier',
                      duration: 4);
                }),
          ),
          const SizedBox(height: 20)
        ],
      ),
    );
  }
}
