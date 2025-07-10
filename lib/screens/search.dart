// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/search.dart';
import 'package:gecko/screens/my_contacts.dart';
import 'package:gecko/screens/search_result.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/clipboard_monitor.dart';
import 'package:gecko/widgets/commons/offline_info.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Timer? debounce;
  final int debouneTime = 50;

  @override
  void initState() {
    ClipboardMonitor().startMonitoring();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final canValidate = searchProvider.searchController.text.length >= 2;

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        searchProvider.searchController.text = '';
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('search'.tr()),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: <Widget>[
                  const Spacer(),
                  _myContactsButton(),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    child: TextField(
                      onSubmitted: searchProvider.searchController.text.length >= 2
                          ? (_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return const SearchResultScreen();
                                  },
                                ),
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
                        }),
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIconConstraints: const BoxConstraints(minHeight: 32),
                        suffixIcon: searchProvider.searchController.text == ''
                            ? null
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: IconButton(
                                  onPressed: (() async => {
                                    searchProvider.searchController.text = '',
                                    searchProvider.reload(),
                                  }),
                                  icon: Icon(Icons.close, color: Colors.grey[600], size: scaleSize(28)),
                                ),
                              ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: Image.asset('assets/loupe-noire.png', height: scaleSize(10)),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[500]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[500]!, width: 2.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(13),
                      ),
                      style: scaledTextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w400),
                    ),
                  ),
                  const Spacer(),
                  ScaledSizedBox(
                    width: 270,
                    height: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: canValidate || searchProvider.canPasteAddress
                            ? [
                                BoxShadow(
                                  color: context.colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -2,
                                ),
                                BoxShadow(
                                  color: context.colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        key: keyConfirmSearch,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: context.colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: canValidate
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const SearchResultScreen();
                                    },
                                  ),
                                );
                              }
                            : searchProvider.canPasteAddress
                            ? () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return WalletViewScreen(address: searchProvider.pastedAddress, username: null);
                                    },
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          canValidate
                              ? 'search'.tr()
                              : searchProvider.canPasteAddress
                              ? 'pasteAddress'.tr()
                              : 'search'.tr(),
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const OfflineInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myContactsButton() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const ContactsScreen();
          },
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipOval(
              key: keyOpenWalletsHomme,
              child: Material(
                color: context.colorScheme.secondary,
                child: Padding(
                  padding: EdgeInsets.all(scaleSize(14.5)),
                  child: Icon(Icons.contacts_rounded, size: scaleSize(25)),
                ),
              ),
            ),
          ),
          ScaledSizedBox(height: 7),
          Text('contactsManagement'.tr(), textAlign: TextAlign.center, style: scaledTextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
