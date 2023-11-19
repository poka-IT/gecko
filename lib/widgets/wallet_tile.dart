import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/widgets/commons/smooth_transition.dart';
import 'package:gecko/widgets/name_by_address.dart';

class WalletTile extends StatelessWidget {
  const WalletTile(
      {Key? key,
      required this.repository,
      required this.walletOptions,
      required this.defaultWallet,
      required this.currentChestNumber})
      : super(key: key);

  final WalletData repository;
  final WalletOptionsProvider walletOptions;
  final WalletData defaultWallet;
  final int currentChestNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        key: keyOpenWallet(repository.address),
        onTap: () {
          walletOptions.getAddress(currentChestNumber, repository.derivation!);
          Navigator.push(
            context,
            SmoothTransition(
              page: WalletOptions(
                wallet: repository,
              ),
            ),
          );
        },
        child: SizedBox(
          key: repository.number == 1 ? keyDragAndDrop : const Key('nothing'),
          child: ClipOvalShadow(
            shadow: const Shadow(
              color: Colors.transparent,
              offset: Offset(0, 0),
              blurRadius: 5,
            ),
            clipper: CustomClipperOval(),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Column(children: <Widget>[
                Expanded(
                    child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.8,
                      colors: [
                        Color.fromARGB(255, 255, 255, 211),
                        yellowC,
                      ],
                    ),
                  ),
                  child: repository.imageCustomPath == null ||
                          repository.imageCustomPath == ''
                      ? Image.asset(
                          'assets/avatars/${repository.imageDefaultPath}',
                          alignment: Alignment.bottomCenter,
                          scale: 0.5,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            image: DecorationImage(
                              fit: BoxFit.fitHeight,
                              image: FileImage(
                                File(repository.imageCustomPath!),
                              ),
                            ),
                          ),
                        ),
                )),
                Stack(children: <Widget>[
                  BalanceBuilder(
                      address: repository.address,
                      isDefault: repository.address == defaultWallet.address),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 7),
                          Opacity(
                              opacity: 0.7,
                              child: NameByAddress(
                                wallet: repository,
                                size: 20,
                                color:
                                    defaultWallet.address == repository.address
                                        ? Colors.white
                                        : Colors.black,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.normal,
                              ))
                        ],
                      ),
                    ],
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
