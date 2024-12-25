import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/v2s_datapod.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/certifications.dart';
import 'package:gecko/widgets/commons/smooth_transition.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class WalletTileMembre extends StatelessWidget {
  const WalletTileMembre({super.key, required this.wallet});

  final WalletData wallet;

  @override
  Widget build(BuildContext context) {
    wallet.getDatapodAvatar();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(52), vertical: scaleSize(15)),
      child: GestureDetector(
        key: keyOpenWallet(wallet.address),
        onTap: () {
          Navigator.push(
            context,
            SmoothTransition(
              page: WalletOptions(
                wallet: wallet,
              ),
            ),
          );
        },
        child: ScaledSizedBox(
          // key: wallet.number == 1 ? keyDragAndDrop : const Key('nothing'),
          height: 180,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: [
                      Consumer<V2sDatapodProvider>(
                        builder: (context, datapod, _) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFFFFFFF0),
                                  yellowC.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                            child: wallet.imageCustomPath == null || wallet.imageCustomPath == ''
                                ? Padding(
                                    padding: EdgeInsets.all(scaleSize(16)),
                                    child: Image.asset(
                                      'assets/avatars/${wallet.imageDefaultPath}',
                                      alignment: Alignment.bottomCenter,
                                    ),
                                  )
                                : Container(
                                    margin: EdgeInsets.all(scaleSize(16)),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: FileImage(
                                          File(wallet.imageCustomPath!),
                                        ),
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
                      Positioned(
                        left: scaleSize(16),
                        top: scaleSize(16),
                        child: Image.asset(
                          'assets/medal.png',
                          color: orangeC.withValues(alpha: 0.8),
                          height: scaleSize(28),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDefault ? orangeC.withValues(alpha: 0.9) : yellowC.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: scaleSize(12),
                    horizontal: scaleSize(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NameByAddress(
                            wallet: wallet,
                            size: 16,
                            color: isDefault ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          ScaledSizedBox(height: 4),
                          Balance(
                            address: wallet.address,
                            size: 14,
                            color: isDefault ? Colors.white : Colors.black87,
                          ),
                        ],
                      ),
                      Certifications(
                        address: wallet.address,
                        color: isDefault ? Colors.white : Colors.black87,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get isDefault => wallet.address == Provider.of<MyWalletsProvider>(homeContext, listen: false).getDefaultWallet().address;
}
