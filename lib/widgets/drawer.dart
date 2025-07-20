import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/debug_screen.dart';
import 'package:gecko/screens/my_contacts.dart';
import 'package:gecko/screens/settings.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key, required this.isWalletsExists});

  final bool isWalletsExists;

  @override
  Widget build(BuildContext context) {
    final listStyle = scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface);

    final appVersionShort = appVersion.split('+').first;

    return SafeArea(
      top: false,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.67,
        child: Drawer(
          backgroundColor: context.colorScheme.surface,
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      decoration: BoxDecoration(color: context.colorScheme.primary),
                      child: Column(
                        children: <Widget>[
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: scaleSize(100)),
                            child: Image(image: const AssetImage('assets/icon/gecko_final.png'), fit: BoxFit.contain),
                          ),
                        ],
                      ),
                    ),
                    ScaledSizedBox(height: scaleSize(10)),
                    ListTile(
                      key: keyParameters,
                      leading: Icon(Icons.settings, size: scaleSize(25)),
                      dense: !isTall,
                      // contentPadding:
                      //     EdgeInsets.symmetric(horizontal: scaleSize(12)),
                      title: Text('parameters'.tr(), style: listStyle),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return SettingsScreen();
                            },
                          ),
                        );
                      },
                    ),
                    ScaledSizedBox(height: scaleSize(4)),
                    if (isWalletsExists)
                      ListTile(
                        key: keyContacts,
                        leading: Icon(Icons.contacts_rounded, size: scaleSize(25)),
                        dense: !isTall,
                        title: Text('contactsManagement'.tr(), style: listStyle),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const ContactsScreen();
                              },
                            ),
                          );
                        },
                      ),
                    if (isWalletsExists) ScaledSizedBox(height: scaleSize(4)),
                    if (kDebugMode)
                      ListTile(
                        key: keyDebugScreen,
                        leading: Icon(Icons.developer_mode_rounded, size: scaleSize(25)),
                        dense: !isTall,
                        title: Text('Debug screen'.tr(), style: listStyle),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const DebugScreen();
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Align(
                alignment: FractionalOffset.bottomCenter,
                child: InkWell(
                  key: keyCopyAddress,
                  splashColor: context.colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Opacity(
                      opacity: 0.8,
                      child: Text('Ğecko v$appVersionShort', style: scaledTextStyle(fontSize: 12)),
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: 'Ğecko v$appVersion'));
                    snackMessage(
                      context,
                      message: 'Le numéro de version de Ğecko a été copié dans votre presse papier',
                      duration: 4,
                    );
                  },
                ),
              ),
              ScaledSizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
