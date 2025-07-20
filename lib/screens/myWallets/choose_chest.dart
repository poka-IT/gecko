// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show SafeEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/widgets/safe_carousel.dart';
import 'package:provider/provider.dart' as old_provider;

class ChooseChest extends ConsumerStatefulWidget {
  const ChooseChest({super.key});

  @override
  ConsumerState<ChooseChest> createState() => _ChooseChestState();
}

class _ChooseChestState extends ConsumerState<ChooseChest> {
  final tplController = TextEditingController();
  final buttonCarouselController = CarouselSliderController();
  late int currentChest;
  late List<SafeEntity> allSafes;
  late int currentSafeIndex;

  @override
  void initState() {
    super.initState();
    // Get all safes and sort them by number for consistent ordering
    allSafes = ref.read(walletServiceProvider).safeBox.getAll();
    allSafes.sort((a, b) => a.number.compareTo(b.number));

    // Find the current safe and its index in the sorted list
    currentChest = ref.read(walletServiceProvider).defaultSafeBoxNumber;
    currentSafeIndex = allSafes.indexWhere((safe) => safe.number == currentChest);
    if (currentSafeIndex == -1 && allSafes.isNotEmpty) {
      currentSafeIndex = 0; // Fallback to first safe if default not found
      currentChest = allSafes[0].number;
    }
  }

  /// Reload safes after creation/import
  void _reloadSafes() {
    if (!mounted) return;

    setState(() {
      // Reload all safes
      allSafes = ref.read(walletServiceProvider).safeBox.getAll();
      allSafes.sort((a, b) => a.number.compareTo(b.number));

      // Update to the newest default safe (likely the newly created one)
      currentChest = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      currentSafeIndex = allSafes.indexWhere((safe) => safe.number == currentChest);

      if (currentSafeIndex >= 0) {
        // Move carousel to the new safe
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            buttonCarouselController.animateToPage(currentSafeIndex);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(toolbarHeight: scaleSize(57), title: Text('selectMyChest'.tr())),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 160),
            SafeCarousel(
              allSafes: allSafes,
              currentSafeIndex: currentSafeIndex,
              carouselController: buttonCarouselController,
              onPageChanged: (index, reason) {
                setState(() {
                  if (index < allSafes.length) {
                    // Regular safe selected
                    currentSafeIndex = index;
                    currentChest = allSafes[index].number;
                  } else {
                    // Placeholder selected - keep current safe but update index
                    currentSafeIndex = index;
                  }
                });
              },
              onSafeCreated: () => _reloadSafes(),
              onSafeImported: () => _reloadSafes(),
              showCreatePlaceholder: true,
              height: 210,
              isCompact: false,
            ),
            // Always show pagination dots if there are multiple items (safes + placeholder)
            if (allSafes.length + 1 > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(allSafes.length + 1, (index) {
                  return GestureDetector(
                    onTap: () => buttonCarouselController.animateToPage(index),
                    child: Container(
                      width: 12.0,
                      height: 12.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                            .withValues(alpha: currentSafeIndex == index ? 0.9 : 0.4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 60),
            // Only show button if a real safe is selected (not placeholder)
            if (currentSafeIndex < allSafes.length)
              Container(
                width: 300,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: context.colorScheme.primary,
                  ),
                  onPressed: () async {
                    ref.read(walletServiceProvider).setDefaultSafeBoxNumber(currentChest);
                    myWalletProvider.pinCode = '';
                    if (!await myWalletProvider.askPinCode(canSwitch: true)) return;

                    Navigator.popUntil(context, ModalRoute.withName('/'));
                    Navigator.pushNamed(context, '/mywallets');
                  },
                  child: Text(
                    'openThisChest'.tr(),
                    style: TextStyle(fontSize: 18, color: context.colorScheme.surface, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
