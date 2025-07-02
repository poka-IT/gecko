import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/v2s_datapod.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/smooth_transition.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class WalletTile extends StatelessWidget {
  const WalletTile({super.key, required this.repository});

  final WalletEntity repository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(scaleSize(11)),
      child: GestureDetector(
        key: keyOpenWallet(repository.address),
        onTap: () {
          Navigator.push(context, SmoothTransition(page: WalletOptions(wallet: repository)));
        },
        child: ScaledSizedBox(
          // key: repository.number == 1 ? keyDragAndDrop : const Key('nothing'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Consumer<V2sDatapodProvider>(
                    builder: (context, datapod, _) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          color: context.colorScheme.secondary.withValues(alpha: context.isDarkTheme ? 1 : 0.3),
                        ),
                        child: repository.imagePath == null || repository.imagePath == ''
                            ? Padding(
                                padding: EdgeInsets.all(scaleSize(16)),
                                child: Image.asset(
                                  'assets/avatars/${repository.number % 4}.png',
                                  alignment: Alignment.bottomCenter,
                                ),
                              )
                            : Container(
                                margin: EdgeInsets.all(scaleSize(16)),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    fit: BoxFit.fitHeight,
                                    image: AssetImage(repository.imagePath!),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDefault
                        ? context.colorScheme.primary.withValues(alpha: 0.9)
                        : context.colorScheme.secondary.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: scaleSize(6)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          NameByAddress(
                            wallet: repository,
                            size: 16,
                            color: isDefault ? Colors.white : context.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          ScaledSizedBox(height: 4),
                          Balance(
                            address: repository.address,
                            size: 14,
                            color: isDefault ? Colors.white : context.colorScheme.onSurface,
                          ),
                        ],
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

  bool get isDefault =>
      repository.address == Provider.of<MyWalletsProvider>(homeContext, listen: false).getDefaultWallet().address;
}
