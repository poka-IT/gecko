// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/search_provider.dart';
import 'package:gecko/screens/my_contacts.dart';
import 'package:gecko/screens/network_activity_screen.dart';
import 'package:gecko/screens/search_result.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late FocusNode _searchFocusNode;
  bool _isNavigating = false; // Add flag to prevent rebuilds during navigation

  @override
  void initState() {
    _searchFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start clipboard monitoring - this initializes the clipboard monitoring
    ref.read(startClipboardMonitoringProvider);

    final searchState = ref.watch(searchStateProvider);
    final searchController = ref.read(searchControllerProvider);
    final clearSearch = ref.read(clearSearchProvider);
    final canValidate = searchState.canValidate;

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        // Only clear text if we're not navigating to prevent unnecessary rebuilds
        if (!_isNavigating) {
          clearSearch();
        }
        _isNavigating = false; // Reset flag
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('search'.tr()),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              ScaledSizedBox(height: 20),
              _buttonsRow(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: TextField(
                  onSubmitted: canValidate
                      ? (_) {
                          _isNavigating = true; // Set flag before navigation
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const SearchResultScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                // Fast fade transition to reduce visual jarring
                                return FadeTransition(
                                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 200),
                            ),
                          );
                        }
                      : (value) {},
                  textInputAction: TextInputAction.search,
                  key: keySearchField,
                  controller: searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIconConstraints: const BoxConstraints(minHeight: 32),
                    suffixIcon: searchState.searchText == ''
                        ? null
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: IconButton(
                              onPressed: () {
                                clearSearch();
                                _searchFocusNode.requestFocus();
                              },
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
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: canValidate || searchState.canPasteAddress
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: canValidate
                        ? () {
                            _isNavigating = true; // Set flag before navigation
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const SearchResultScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  // Fast fade transition to reduce visual jarring
                                  return FadeTransition(
                                    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 200),
                              ),
                            );
                          }
                        : searchState.canPasteAddress
                        ? () async {
                            _isNavigating = true; // Set flag before navigation
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    WalletViewScreen(address: searchState.pastedAddress, username: null),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  // Fast fade transition to reduce visual jarring
                                  return FadeTransition(
                                    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                    child: child,
                                  );
                                },
                                transitionDuration: const Duration(milliseconds: 200),
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      canValidate
                          ? 'search'.tr()
                          : searchState.canPasteAddress
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
        ),
      ),
    );
  }

  Widget _buttonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _myContactsButton()),
            ScaledSizedBox(width: 12),
            Expanded(child: _networkActivityButton()),
          ],
        ),
      ),
    );
  }

  Widget _myContactsButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF607D8B).withValues(alpha: 0.85), const Color(0xFF607D8B).withValues(alpha: 0.65)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF607D8B).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: keyOpenWalletsHomme,
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const ContactsScreen();
              },
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: scaleSize(12),
              right: scaleSize(12),
              top: scaleSize(12),
              bottom: scaleSize(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.contacts_rounded, size: scaleSize(26), color: Colors.white),
                ScaledSizedBox(height: 3),
                SizedBox(
                  height: scaleSize(32),
                  child: Center(
                    child: Text(
                      'contactsManagement'.tr(),
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _networkActivityButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF8D6E63).withValues(alpha: 0.85), const Color(0xFF8D6E63).withValues(alpha: 0.65)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D6E63).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const NetworkActivityScreen();
              },
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: scaleSize(28), color: Colors.white),
                ScaledSizedBox(height: 3),
                SizedBox(
                  height: scaleSize(32),
                  child: Center(
                    child: Text(
                      'networkActivity'.tr(),
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
