import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';

import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/qrcode_fullscreen.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:qr_flutter/qr_flutter.dart';

class WalletAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const WalletAppBar({super.key, required this.address, this.title, this.titleBuilder})
    : assert(title != null || titleBuilder != null);

  final String address;
  final String? title;
  final String Function(String? username)? titleBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the real-time balance stream instead of the static parameter
    final balanceStream = ref.watch(smartBalanceStreamProvider(address));

    return balanceStream.when(
      data: (walletBalance) {
        final balance = walletBalance.transferableBalance;
        final isEmptyWallet = balance == BigInt.zero;
        return _buildAppBar(context, ref, isEmptyWallet);
      },
      loading: () {
        // While loading, assume empty wallet (will show error color)
        return _buildAppBar(context, ref, true);
      },
      error: (error, stack) {
        // On error, assume empty wallet (will show error color)
        return _buildAppBar(context, ref, true);
      },
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, bool isEmptyWallet) {
    return AppBar(
      backgroundColor: isEmptyWallet ? context.colorScheme.error : context.colorScheme.tertiary,
      titleSpacing: 10,
      title: old_provider.Consumer<WalletOptionsProvider>(
        builder: (context, walletOptions, _) {
          return Text(title ?? titleBuilder!(ref.watch(squidServiceProvider).walletNameIndexer[address]));
        },
      ),
      actions: [
        Row(
          children: [
            // Contact Button
            old_provider.Consumer<WalletsProfilesProvider>(
              builder: (context, profile, _) {
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
                    color: context.colorScheme.onSecondaryContainer,
                  ),
                );
              },
            ),
            // QR Code
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => QrCodeFullscreen(address)));
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                child: QrImageView(
                  data: address,
                  version: QrVersions.auto,
                  size: scaleSize(45),
                  dataModuleStyle: QrDataModuleStyle(color: context.colorScheme.onSecondaryContainer),
                  eyeStyle: QrEyeStyle(color: context.colorScheme.onSecondaryContainer),
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
