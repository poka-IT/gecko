import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/certifications.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/datapod_avatar.dart';
import 'package:gecko/widgets/idty_status.dart';
import 'package:gecko/widgets/page_route_no_transition.dart';
import 'package:provider/provider.dart';
import 'package:gecko/providers/wallet_options.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({
    super.key,
    required this.address,
    this.customImagePath,
    this.defaultImagePath,
  });

  final String address;
  final String? customImagePath;
  final String? defaultImagePath;

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 90;
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    final walletData = myWalletProvider.getWalletDataByAddress(address);
    final isOwner = walletData != null;

    bool isPickerOpen = false;
    String newCustomImagePath = '';

    return Container(
      color: headerColor,
      padding: EdgeInsets.only(
        left: scaleSize(16),
        right: scaleSize(16),
        bottom: scaleSize(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar section
          Container(
            width: scaleSize(90),
            height: scaleSize(90),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<WalletOptionsProvider>(
              builder: (context, walletOptionsProvider, child) {
                if (newCustomImagePath.isEmpty) {
                  newCustomImagePath = customImagePath ?? '';
                }
                return Stack(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isOwner && !isPickerOpen
                            ? () async {
                                isPickerOpen = true;
                                walletOptionsProvider.reload();
                                newCustomImagePath = await walletOptionsProvider.changeAvatar();
                                isPickerOpen = false;
                                walletOptionsProvider.reload();
                              }
                            : null,
                        customBorder: const CircleBorder(),
                        child: ClipOval(
                          child: newCustomImagePath.isEmpty
                              ? (defaultImagePath != null
                                  ? Image.asset(
                                      'assets/avatars/$defaultImagePath',
                                      fit: BoxFit.cover,
                                    )
                                  : DatapodAvatar(
                                      address: address,
                                      size: avatarSize,
                                    ))
                              : Image.file(
                                  File(newCustomImagePath),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    if (isOwner)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: avatarSize * 0.35,
                          height: avatarSize * 0.35,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: !isPickerOpen
                                  ? () async {
                                      isPickerOpen = true;
                                      walletOptionsProvider.reload();
                                      newCustomImagePath = await walletOptionsProvider.changeAvatar();
                                      isPickerOpen = false;
                                      walletOptionsProvider.reload();
                                    }
                                  : null,
                              customBorder: const CircleBorder(),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: avatarSize * 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SizedBox(width: scaleSize(20)),

          // Info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address row
                GestureDetector(
                  key: keyCopyAddress,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: address));
                    snackCopyKey(context);
                  },
                  child: Row(
                    children: [
                      Text(
                        getShortPubkey(address),
                        style: scaledTextStyle(
                          fontSize: 20,
                          fontFamily: 'Monospace',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: scaleSize(14)),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.copy,
                          size: scaleSize(20),
                          color: orangeC.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: address));
                          snackCopyKey(context);
                        },
                      ),
                    ],
                  ),
                ),
                ScaledSizedBox(height: 8),

                // Balance
                Balance(address: address, size: 18),

                // Certifications section
                ScaledSizedBox(height: 12),
                Visibility(
                  visible: walletData?.hasIdentity ?? false,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      PageNoTransit(
                        builder: (context) => CertificationsScreen(
                          address: address,
                          username: duniterIndexer.walletNameIndexer[address] ?? '',
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IdentityStatus(
                            address: address,
                            color: orangeC,
                          ),
                          SizedBox(width: scaleSize(8)),
                          Certifications(
                            address: address,
                            size: 13,
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: scaleSize(15),
                            color: orangeC.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
