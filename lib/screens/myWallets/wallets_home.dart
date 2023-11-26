// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/chest_options.dart';
import 'package:gecko/screens/myWallets/import_g1_v1.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/drag_tule_action.dart';
import 'package:gecko/widgets/wallet_tile.dart';
import 'package:gecko/widgets/wallet_tile_membre.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    final currentChestNumber = myWalletProvider.getCurrentChest();
    final ChestData currentChest = chestBox.get(currentChestNumber)!;

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
        bottomNavigationBar:
            Consumer<MyWalletsProvider>(builder: (context, _, __) {
          return myWalletProvider.lastFlyBy == ''
              ? const GeckoBottomAppBar(
                  actualRoute: 'safeHome',
                )
              : dragInfo(context);
        }),
        body: FutureBuilder(
            future: myWalletProvider.readAllWallets(currentChestNumber),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  snapshot.hasError) {
                return const Center(
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      color: orangeC,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }
              return SafeArea(
                child: Stack(children: [
                  myWalletsTiles(context, currentChestNumber),
                  const OfflineInfo(),
                ]),
              );
            }),
      ),
    );
  }

  Widget dragInfo(BuildContext context) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);

    final walletDataFrom =
        myWalletProvider.getWalletDataByAddress(myWalletProvider.dragAddress);
    final walletDataTo =
        myWalletProvider.getWalletDataByAddress(myWalletProvider.lastFlyBy);

    final bool isSameAddress =
        myWalletProvider.dragAddress == myWalletProvider.lastFlyBy;

    final screenWidth = MediaQuery.of(homeContext).size.width;

    final fromName =
        duniterIndexer.walletNameIndexer[walletDataFrom!.address] ??
            walletDataFrom.name;

    final toName = duniterIndexer.walletNameIndexer[walletDataTo!.address] ??
        walletDataTo.name;

    return Container(
      color: yellowC,
      width: screenWidth,
      height: 80,
      child: Center(
          child: Column(
        children: [
          const SizedBox(height: 5),
          Text('${'executeATransfer'.tr()}:'),
          MarkdownBody(data: '${'from'.tr()} **$fromName**'),
          if (isSameAddress) Text('chooseATargetWallet'.tr()),
          if (!isSameAddress) MarkdownBody(data: 'Vers: **$toName**'),
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
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

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

    // Get first wallet with identity
    final idtyWallet = listWallets.firstWhere(
      (w) => w.hasIdentity(),
      orElse: () => WalletData(address: ''),
    );

    List<WalletData> listWalletsWithoutIdty = listWallets.toList();
    listWalletsWithoutIdty.removeWhere((w) => w.address == idtyWallet.address);

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
      if (idtyWallet.address != '')
        SliverToBoxAdapter(
          child: DragTuleAction(
            wallet: idtyWallet,
            child: WalletTileMembre(repository: idtyWallet),
          ),
        ),
      SliverGrid.count(
          key: keyListWallets,
          crossAxisCount: nTule,
          childAspectRatio: 1,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          children: <Widget>[
            for (WalletData repository in listWalletsWithoutIdty)
              DragTuleAction(
                wallet: repository,
                child: WalletTile(repository: repository),
              ),
            Consumer<SubstrateSdk>(builder: (context, sub, _) {
              return sub.nodeConnected &&
                      myWalletProvider.listWallets.length < maxWalletsInSafe
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
        ]),
      ),
    );
  }
}
