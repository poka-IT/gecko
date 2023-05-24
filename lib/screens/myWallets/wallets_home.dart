// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/myWallets/wallet_options.dart';
import 'package:gecko/widgets/balance.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/smooth_transition.dart';
import 'package:gecko/widgets/name_by_address.dart';
import 'package:gecko/widgets/payment_popup.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
// import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class WalletsHome extends StatefulWidget {
  const WalletsHome({Key? key}) : super(key: key);

  @override
  State<WalletsHome> createState() => _WalletsHomeState();
}

class _WalletsHomeState extends State<WalletsHome> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    final currentChestNumber = myWalletProvider.getCurrentChest();
    final ChestData currentChest = chestBox.get(currentChestNumber)!;
    myWalletProvider.listWallets =
        myWalletProvider.readAllWallets(currentChestNumber);

    return WillPopScope(
      onWillPop: () {
        Navigator.popUntil(
          context,
          ModalRoute.withName('/'),
        );
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
              }),
          title: Row(
            children: [
              Image.asset(
                'assets/chests/${currentChest.imageName}',
                height: 32,
              ),
              const SizedBox(width: 17),
              Text(currentChest.name!,
                  style: TextStyle(color: Colors.grey[850])),
            ],
          ),
          backgroundColor: const Color(0xffFFD58D),
        ),
        bottomNavigationBar: myWalletProvider.lastFlyBy == ''
            ? const GeckoBottomAppBar(
                actualRoute: 'safeHome',
              )
            : dragInfo(context),
        body: SafeArea(
          child: Stack(children: [
            myWalletsTiles(context, currentChestNumber),
            const OfflineInfo(),
          ]),
        ),
      ),
    );
  }

  Widget dragInfo(BuildContext context) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    final walletDataFrom =
        myWalletProvider.getWalletDataByAddress(myWalletProvider.dragAddress);
    final walletDataTo =
        myWalletProvider.getWalletDataByAddress(myWalletProvider.lastFlyBy);

    final bool isSameAddress =
        myWalletProvider.dragAddress == myWalletProvider.lastFlyBy;

    final screenWidth = MediaQuery.of(homeContext).size.width;
    return Container(
      color: yellowC,
      width: screenWidth,
      height: 80,
      child: Center(
          child: Column(
        children: [
          const SizedBox(height: 5),
          Text('${'executeATransfer'.tr()}:'),
          MarkdownBody(data: '${'from'.tr()} **${walletDataFrom!.name}**'),
          if (isSameAddress) Text('chooseATargetWallet'.tr()),
          if (!isSameAddress)
            MarkdownBody(data: 'Vers: **${walletDataTo!.name}**'),
        ],
      )),
    );
  }

  Widget chestOptions(BuildContext context, final myWalletProvider) {
    return Column(children: [
      const SizedBox(height: 50),
      SizedBox(
          height: 80,
          width: 420,
          child: ElevatedButton.icon(
            icon: Image.asset(
              'assets/chests/config.png',
              height: 60,
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black, elevation: 2,
              backgroundColor: floattingYellow, // foreground
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return ChestOptions(walletProvider: myWalletProvider);
              }),
            ),
            label: Text(
              "   ${"manageChest".tr()}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xff8a3c0f),
              ),
            ),
          )),
      const SizedBox(height: 30),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/cesium_bw2.svg',
            semanticsLabel: 'CS',
            height: 50,
          ),
          const SizedBox(width: 5),
          InkWell(
            key: keyImportG1v1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const ImportG1v1();
                }),
              );
            },
            child: SizedBox(
              width: 350,
              height: 60,
              child: Center(
                  child: Text('importG1v1'.tr(),
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500))),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      InkWell(
        key: keyChangeChest,
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) {
          //     return const ChooseChest();
          //   }),
          // );
        },
        child: SizedBox(
          width: 400,
          height: 60,
          child: Center(
              child: Text('changeChest'.tr(),
                  style: const TextStyle(
                      fontSize: 22,
                      color: Colors.grey, //orangeC
                      fontWeight: FontWeight.w500))),
        ),
      ),
      const SizedBox(height: 30)
    ]);
  }

  Widget myWalletsTiles(BuildContext context, int currentChestNumber) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    final walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    if (!isWalletsExists) {
      return const Text('');
    }

    if (myWalletProvider.listWallets.isEmpty) {
      return const Expanded(
          child: Column(children: <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        )),
      ]));
    }

    // Get wallet list and sort by derivation number
    List<WalletData> listWallets = myWalletProvider.listWallets;
    listWallets.sort((p1, p2) {
      return Comparable.compare(p1.number!, p2.number!);
    });

    WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
    final screenWidth = MediaQuery.of(context).size.width;
    int nTule;

    if (screenWidth >= 900) {
      nTule = 4;
    } else if (screenWidth >= 650) {
      nTule = 3;
    } else {
      nTule = 2;
    }

    final tutorialCoachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "drag_and_drop",
          keyTarget: keyDragAndDrop,
          contents: [
            TargetContent(
                child: Column(
              children: [
                Image.asset('assets/drag-and-drop.png', height: 140),
                const SizedBox(height: 15),
                Text(
                  'explainDraggableWallet'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w500),
                ),
              ],
            ))
          ],
          alignSkip: Alignment.bottomRight,
          enableOverlayTab: true,
        ),
      ],
      colorShadow: orangeC,
      textSkip: "skip".tr(),
      paddingFocus: 10,
      opacityShadow: 0.8,
    );

    // configBox.delete('showDraggableTutorial');
    final bool showDraggableTutorial =
        configBox.get('showDraggableTutorial') ?? true;

    if (listWallets.length > 1 && showDraggableTutorial) {
      tutorialCoachMark.show(context: context);
      configBox.put('showDraggableTutorial', false);
    }

    return CustomScrollView(slivers: <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
      SliverGrid.count(
          key: keyListWallets,
          crossAxisCount: nTule,
          childAspectRatio: 1,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          children: <Widget>[
            for (WalletData repository in listWallets)
              LongPressDraggable<String>(
                delay: const Duration(milliseconds: 200),
                data: repository.address,
                dragAnchorStrategy:
                    (Draggable<Object> _, BuildContext __, Offset ___) =>
                        const Offset(0, 0),
                // feedbackOffset: const Offset(-500, -500),
                // dragAnchorStrategy: childDragAnchorStrategy,
                onDragStarted: () =>
                    myWalletProvider.dragAddress = repository.address,
                onDragEnd: (_) {
                  myWalletProvider.lastFlyBy = '';
                  myWalletProvider.dragAddress = '';
                  myWalletProvider.reload();
                },
                feedback: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeC,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const SizedBox(
                    height: 35,
                    child: Image(image: AssetImage('assets/vector_white.png')),
                  ),
                ),
                child: DragTarget<String>(
                    onAccept: (senderAddress) async {
                      log.d(
                          'INTERPAY: sender: $senderAddress --- receiver: ${repository.address}');
                      final walletData = myWalletProvider
                          .getWalletDataByAddress(senderAddress);
                      await sub.setCurrentWallet(walletData!);
                      sub.reload();
                      paymentPopup(
                          context,
                          repository.address,
                          g1WalletsBox.get(repository.address)!.username ??
                              repository.name!);
                    },
                    onMove: (details) {
                      if (repository.address != myWalletProvider.lastFlyBy) {
                        myWalletProvider.lastFlyBy = repository.address;
                        myWalletProvider.reload();
                      }
                    },
                    onWillAccept: (senderAddress) =>
                        senderAddress != repository.address,
                    builder: (
                      BuildContext context,
                      List<dynamic> accepted,
                      List<dynamic> rejected,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: GestureDetector(
                          key: keyOpenWallet(repository.address),
                          onTap: () {
                            walletOptions.getAddress(
                                currentChestNumber, repository.derivation!);
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
                            key: repository.number == 1
                                ? keyDragAndDrop
                                : const Key('nothing'),
                            child: ClipOvalShadow(
                              shadow: const Shadow(
                                color: Colors.transparent,
                                offset: Offset(0, 0),
                                blurRadius: 5,
                              ),
                              clipper: CustomClipperOval(),
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
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
                                    child:
                                        // SvgPicture.asset('assets/chopp-gecko2.png',
                                        //         semanticsLabel: 'Gecko', height: 48),
                                        repository.imageCustomPath == null ||
                                                repository.imageCustomPath == ''
                                            ? Image.asset(
                                                'assets/avatars/${repository.imageDefaultPath}',
                                                alignment:
                                                    Alignment.bottomCenter,
                                                scale: 0.5,
                                              )
                                            : Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.transparent,
                                                  image: DecorationImage(
                                                    fit: BoxFit.fitHeight,
                                                    image: FileImage(
                                                      File(repository
                                                          .imageCustomPath!),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                  )),
                                  Stack(children: <Widget>[
                                    BalanceBuilder(
                                        address: repository.address,
                                        isDefault: repository.address ==
                                            defaultWallet.address),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                      defaultWallet.address ==
                                                              repository.address
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
                    }),
              ),
            Consumer<SubstrateSdk>(builder: (context, sub, _) {
              return sub.nodeConnected
                  ? addNewDerivation(context)
                  : const Text('');
            }),
          ]),
      SliverToBoxAdapter(child: chestOptions(context, myWalletProvider)),
    ]);
  }

  Widget addNewDerivation(context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    String newDerivationName =
        '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number! + 2}';
    return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Column(children: <Widget>[
              Expanded(
                child: InkWell(
                    key: keyAddDerivation,
                    onTap: () async {
                      if (!myWalletProvider.isNewDerivationLoading) {
                        WalletData? defaultWallet =
                            myWalletProvider.getDefaultWallet();
                        String? pin;
                        if (myWalletProvider.pinCode == '') {
                          pin = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (homeContext) {
                                return UnlockingWallet(wallet: defaultWallet);
                              },
                            ),
                          );
                        }
                        if (pin != null || myWalletProvider.pinCode != '') {
                          await myWalletProvider.generateNewDerivation(
                              context, newDerivationName);
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(color: floattingYellow),
                      child: Center(
                          child: myWalletProvider.isNewDerivationLoading
                              ? const SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: CircularProgressIndicator(
                                    color: orangeC,
                                    strokeWidth: 7,
                                  ),
                                )
                              : const Text(
                                  '+',
                                  style: TextStyle(
                                      fontSize: 150,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFCB437)),
                                )),
                    )),
              ),
            ])));
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
              const EdgeInsets.only(left: 5, right: 5, top: 38, bottom: 10),
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
