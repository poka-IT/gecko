// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/search_result.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool canPasteAddress = false;
  String pastedAddress = '';
  Timer? debounce;
  final int debouneTime = 50;

  Future getClipBoard() async {
    final clipboard = await Clipboard.getData('text/plain');
    pastedAddress = clipboard?.text ?? '';
    canPasteAddress = isAddress(pastedAddress);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getClipBoard();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    final canValidate = searchProvider.searchController.text.length >= 2;
    // final canPasteAddress = false;

    return WillPopScope(
      onWillPop: () {
        searchProvider.searchController.text = '';
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text('search'.tr()),
          ),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                searchProvider.searchController.text = '';
                Navigator.of(context).pop();
              }),
        ),
        body: SafeArea(
          child: Stack(children: [
            Column(children: <Widget>[
              SizedBox(height: isTall ? 200 : 100),
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
                      getClipBoard();
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
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                            child: IconButton(
                              onPressed: (() async => {
                                    searchProvider.searchController.text = '',
                                    await getClipBoard(),
                                    searchProvider.reload(),
                                  }),
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey[600],
                                size: 30,
                              ),
                            ),
                          ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 17),
                      child: Image(
                          image: AssetImage('assets/loupe-noire.png'),
                          height: 35),
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
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              SizedBox(
                width: 320,
                height: 90,
                child: ElevatedButton(
                  key: keyConfirmSearch,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, elevation: 4,
                    backgroundColor: orangeC, // foreground
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
                                      address: pastedAddress, username: '');
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
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Spacer(flex: screenHeight <= 800 ? 1 : 2),
            ]),
            const OfflineInfo(),
          ]),
        ),
      ),
    );
  }
}
