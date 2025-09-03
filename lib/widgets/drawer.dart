import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/debug_screen.dart';
import 'package:gecko/screens/settings.dart';
import 'package:gecko/screens/currency_page.dart';
import 'package:gecko/services/snackbar_service.dart';
import 'package:gecko/widgets/manual_issue_report_dialog.dart';
import 'package:gecko/providers/providers.dart';
import 'package:durt2/durt2.dart' show Networks;

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key, required this.isWalletsExists});

  final bool isWalletsExists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    ListTile(
                      leading: Icon(Icons.account_balance, size: scaleSize(25)),
                      dense: !isTall,
                      title: Text('currency'.tr(), style: listStyle),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const CurrencyPage();
                            },
                          ),
                        );
                      },
                    ),
                    ScaledSizedBox(height: scaleSize(4)),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manual issue report button - only show when not on G1 network
                  Consumer(
                    builder: (context, ref, child) {
                      final network = ref.watch(networkProvider);
                      final isG1Network = network == Networks.g1;

                      if (isG1Network) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: '',
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const ManualIssueReportDialog(),
                              );
                            },
                            icon: Icon(Icons.bug_report, size: scaleSize(18), color: context.colorScheme.onPrimary),
                            label: Text(
                              'reportIssue'.tr(),
                              style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onPrimary),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colorScheme.primary,
                              foregroundColor: context.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Version number
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
                        SnackbarService.showMessage(
                          context,
                          message: 'Le numéro de version de Ğecko a été copié dans votre presse papier',
                          duration: 4,
                        );
                      },
                    ),
                  ),
                ],
              ),
              ScaledSizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
