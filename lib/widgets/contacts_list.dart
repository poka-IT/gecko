import 'package:durt2/durt2.dart' show WalletEntity, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/providers.dart';

import 'package:gecko/providers/profile_view_providers.dart';
import 'package:gecko/services/navigation_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/providers/cert_alert_provider.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/name_by_address.dart';

class ContactsList extends ConsumerWidget {
  const ContactsList({super.key, required this.myContacts});

  final List<G1WalletsList> myContacts;

  void _showContactMenu(BuildContext context, WidgetRef ref, G1WalletsList contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: context.geckoColors.danger),
                title: Text('removeContact'.tr(), style: TextStyle(color: context.geckoColors.danger)),
                onTap: () async {
                  Navigator.pop(context);
                  final toggleContact = ref.read(toggleContactProvider);
                  await toggleContact(contact, context);
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  List<InlineSpan> _buildHintSpans(BuildContext context) {
    final hint = 'noContactsHint'.tr();
    final parts = hint.split('{}');
    return [
      TextSpan(text: parts[0]),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(Icons.add_reaction_outlined, size: scaleSize(18), color: Colors.grey[600]),
        ),
      ),
      if (parts.length > 1) TextSpan(text: parts[1]),
    ];
  }

  Widget _buildContactAlert(BuildContext context, WidgetRef ref, String contactAddress) {
    final alertStatus = ref.watch(contactCertAlertProvider(contactAddress));
    if (alertStatus == CertAlertStatus.none) return const SizedBox.shrink();
    final color = alertStatus == CertAlertStatus.expired ? context.geckoColors.danger : context.geckoColors.warning;
    return Padding(
      padding: EdgeInsets.only(right: scaleSize(8)),
      child: Container(
        width: scaleSize(8),
        height: scaleSize(8),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ScaledSizedBox(height: 10, width: double.infinity),
              if (myContacts.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: scaleSize(48), color: Colors.grey[400]),
                          ScaledSizedBox(height: 16),
                          Text(
                            'noContacts'.tr(),
                            style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          ScaledSizedBox(height: 12),
                          Text.rich(
                            TextSpan(children: _buildHintSpans(context)),
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      for (G1WalletsList g1Wallet in myContacts)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ListTile(
                            key: keySearchResult('keyID++'),
                            horizontalTitleGap: 7,
                            contentPadding: const EdgeInsets.all(5),
                            dense: !isTall,
                            leading: AspectRatio(
                              aspectRatio: 1,
                              child: DatapodAvatar(address: g1Wallet.address, size: 47, name: g1Wallet.username),
                            ),
                            title: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    getShortPubkey(g1Wallet.address),
                                    style: scaledTextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Monospace',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.left,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScaledSizedBox(
                                  width: 125,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _buildContactAlert(context, ref, g1Wallet.address),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [Balance(address: g1Wallet.address, size: scaleSize(13))],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: <Widget>[
                                Expanded(
                                  child: NameByAddress(
                                    size: scaleSize(14),
                                    wallet: WalletEntity.create(
                                      address: g1Wallet.address,
                                      name: g1Wallet.username,
                                      keyPairType: Durt.defaultKeyPairType,
                                    ),
                                    showCesiumPlusName: true,
                                    showSourceBadge: true,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: false,
                            onLongPress: () => _showContactMenu(context, ref, g1Wallet),
                            onTap: () {
                              NavigationService.openProfile(
                                context,
                                address: g1Wallet.address,
                                username: ref.read(squidServiceProvider).walletNameIndexer[g1Wallet.address],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
