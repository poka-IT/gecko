import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WalletAppBar({
    super.key,
    required this.address,
    this.title,
    this.titleBuilder,
  }) : assert(title != null || titleBuilder != null);

  final String address;
  final String? title;
  final String Function(String? username)? titleBuilder;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    return AppBar(
      titleSpacing: 10,
      title: Text(
        title ?? titleBuilder!(duniterIndexer.walletNameIndexer[address]),
      ),
      actions: [
        Row(
          children: [
            Consumer<WalletsProfilesProvider>(builder: (context, profile, _) {
              return IconButton(
                onPressed: () async {
                  G1WalletsList? newContact;
                  g1WalletsBox.toMap().forEach((key, value) {
                    if (key == address) newContact = value;
                  });
                  await profile.addContact(newContact ?? G1WalletsList(address: address));
                },
                icon: Icon(
                  profile.isContact(address) ? Icons.add_reaction_rounded : Icons.add_reaction_outlined,
                  size: scaleSize(27),
                ),
              );
            }),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QrCodeFullscreen(address)),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                child: QrImageView(
                  data: address,
                  version: QrVersions.auto,
                  size: scaleSize(45),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
