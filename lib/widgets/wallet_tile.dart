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
import 'package:gecko/widgets/commons/smooth_transition.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class WalletTile extends StatelessWidget {
  const WalletTile({
    super.key,
    required this.repository,
  });

  final WalletData repository;

  @override
  Widget build(BuildContext context) {
    repository.getDatapodAvatar();

    return Padding(
      padding: EdgeInsets.all(scaleSize(11)),
      child: GestureDetector(
        key: keyOpenWallet(repository.address),
        onTap: () {
          Navigator.push(
            context,
            SmoothTransition(
              page: WalletOptions(
                wallet: repository,
              ),
            ),
          );
        },
        child: ScaledSizedBox(
          key: repository.number == 1 ? keyDragAndDrop : const Key('nothing'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
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
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFFFFF0),
                              yellowC.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: repository.imageCustomPath == null || repository.imageCustomPath == ''
                            ? Padding(
                                padding: EdgeInsets.all(scaleSize(16)),
                                child: Image.asset(
                                  'assets/avatars/${repository.imageDefaultPath}',
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
                                      File(repository.imageCustomPath!),
                                    ),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDefault ? orangeC.withOpacity(0.9) : yellowC.withOpacity(0.9),
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
                            color: isDefault ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          ScaledSizedBox(height: 4),
                          Balance(
                            address: repository.address,
                            size: 14,
                            color: isDefault ? Colors.white : Colors.black87,
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

  bool get isDefault => repository.address == Provider.of<MyWalletsProvider>(homeContext, listen: false).getDefaultWallet().address;
}
