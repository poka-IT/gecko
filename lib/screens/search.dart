// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/search_result.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Timer? debounce;
  final int debouneTime = 50;
  bool canPasteAddress = false;
  String pastedAddress = '';
  Timer? clipboardPollingTimer;

  void getClipBoard() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    // Function to check clipboard and update if necessary
    Future<void> checkAndUpdateClipboard() async {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text != pastedAddress) {
        pastedAddress = clipboardData.text ?? '';
        canPasteAddress = await isAddress(pastedAddress);
        searchProvider.reload();
      }
    }

    // Check clipboard immediately
    checkAndUpdateClipboard();

    // Set up the periodic clipboard checking
    clipboardPollingTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) async {
      await checkAndUpdateClipboard();
    });
  }

  @override
  void initState() {
    getClipBoard();
    super.initState();
  }

  @override
  void dispose() {
    clipboardPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final canValidate = searchProvider.searchController.text.length >= 2;

    return PopScope(
      onPopInvoked: (_) {
        searchProvider.searchController.text = '';
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: GeckoAppBar('search'.tr()),
        body: SafeArea(
          child: Stack(children: [
            Column(children: <Widget>[
              ScaledSizedBox(height: isTall ? 165 : 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: TextField(
                  onSubmitted: searchProvider.searchController.text.length >= 2
                      ? (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return const SearchResultScreen();
                            }),
                          );
                        }
                      : (value) {},
                  textInputAction: TextInputAction.search,
                  key: keySearchField,
                  controller: searchProvider.searchController,
                  autofocus: true,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  onChanged: (v) => {
                    if (debounce?.isActive ?? false) {debounce!.cancel()},
                    debounce = Timer(Duration(milliseconds: debouneTime), () {
                      searchProvider.reload();
                    })
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIconConstraints: const BoxConstraints(
                      minHeight: 32,
                    ),
                    suffixIcon: searchProvider.searchController.text == ''
                        ? null
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: IconButton(
                              onPressed: (() async => {
                                    searchProvider.searchController.text = '',
                                    searchProvider.reload(),
                                  }),
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey[600],
                                size: scaleSize(28),
                              ),
                            ),
                          ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: Image.asset(
                        'assets/loupe-noire.png',
                        height: scaleSize(10),
                      ),
                    ),
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.grey[500]!, width: 2),
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.grey[500]!, width: 2.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(13),
                  ),
                  style: scaledTextStyle(
                    fontSize: 17,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(),
              ScaledSizedBox(
                width: 270,
                height: 70,
                child: ElevatedButton(
                  key: keyConfirmSearch,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    elevation: 4,
                    backgroundColor: orangeC,
                  ),
                  onPressed: canValidate
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return const SearchResultScreen();
                            }),
                          );
                        }
                      : canPasteAddress
                          ? () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return WalletViewScreen(
                                      address: pastedAddress, username: null);
                                }),
                              );
                            }
                          : null,
                  child: Text(
                    canValidate
                        ? 'search'.tr()
                        : canPasteAddress
                            ? 'pasteAddress'.tr()
                            : 'search'.tr(),
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
            ]),
            const OfflineInfo(),
          ]),
        ),
      ),
    );
  }
}
