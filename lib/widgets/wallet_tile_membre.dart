import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/commons/smooth_transition.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:provider/provider.dart';

class WalletTileMembre extends StatelessWidget {
  const WalletTileMembre({Key? key, required this.repository})
      : super(key: key);

  final WalletData repository;

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final defaultWallet = myWalletProvider.getDefaultWallet();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
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
        child: SizedBox(
          key: repository.number == 1 ? keyDragAndDrop : const Key('nothing'),
          height: 240,
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

class BalanceBuilder extends StatelessWidget {
  const BalanceBuilder({
    Key? key,
    required this.address,
    required this.isDefault,
  }) : super(key: key);

  final String address;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isDefault ? orangeC : yellowC,
      child: Padding(
          padding:
              const EdgeInsets.only(left: 5, right: 5, top: 45, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0.7,
                child: Balance(
                    address: address,
                    size: 16,
                    color: isDefault ? Colors.white : Colors.black,
                    loadingColor: isDefault ? yellowC : orangeC),
              )
            ],
          )),
    );
  }
}

class ClipOvalShadow extends StatelessWidget {
  final Shadow shadow;
  final CustomClipper<Rect> clipper;
  final Widget child;

  const ClipOvalShadow({
    Key? key,
    required this.shadow,
    required this.clipper,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClipOvalShadowPainter(
        clipper: clipper,
        shadow: shadow,
      ),
      child: ClipRect(clipper: clipper, child: child),
    );
  }
}

class _ClipOvalShadowPainter extends CustomPainter {
  final Shadow shadow;
  final CustomClipper<Rect> clipper;

  _ClipOvalShadowPainter({required this.shadow, required this.clipper});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = shadow.toPaint();
    var clipRect = clipper.getClip(size).shift(const Offset(0, 0));
    canvas.drawOval(clipRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CustomClipperOval extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromCircle(
        center: Offset(size.width / 2, size.width / 2),
        radius: size.width / 2 + 3);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return false;
  }
}
