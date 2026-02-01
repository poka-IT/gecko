// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show SafeEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/biometric_provider.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/buttons/primary_button.dart';
import 'package:gecko/widgets/safe_carousel.dart';

class SwitchSafe extends ConsumerStatefulWidget {
  const SwitchSafe({super.key});

  @override
  ConsumerState<SwitchSafe> createState() => _ChooseSafeState();
}

class _ChooseSafeState extends ConsumerState<SwitchSafe> {
  final tplController = TextEditingController();
  final buttonCarouselController = CarouselSliderController();
  late int currentSafe;
  late List<SafeEntity> allSafes;
  late int currentSafeIndex;

  @override
  void initState() {
    super.initState();
    // Get all safes and sort them by number for consistent ordering
    allSafes = ref.read(walletServiceProvider).safeBox.getAll();
    allSafes.sort((a, b) => a.number.compareTo(b.number));

    // Find the current safe and its index in the sorted list
    currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;
    currentSafeIndex = allSafes.indexWhere((safe) => safe.number == currentSafe);
    if (currentSafeIndex == -1 && allSafes.isNotEmpty) {
      currentSafeIndex = 0; // Fallback to first safe if default not found
      currentSafe = allSafes[0].number;
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
      currentSafe = ref.read(walletServiceProvider).defaultSafeBoxNumber;
      currentSafeIndex = allSafes.indexWhere((safe) => safe.number == currentSafe);

      if (currentSafeIndex >= 0) {
        // Move carousel to the new safe
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            buttonCarouselController.animateToPage(currentSafeIndex);
          }
        });
      }
    });

    // Refresh biometric provider after safe creation/import to ensure correct state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(biometricProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(toolbarHeight: scaleSize(57), title: Text('selectMySafe'.tr())),
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
                    currentSafe = allSafes[index].number;
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
                child: PrimaryButton(
                  label: 'openThisSafe'.tr(),
                  onPressed: () async {
                    await ref.read(walletActionsProvider.notifier).switchSafe(currentSafe);
                    PinCodeService.pinCode = '';
                    await ref.read(biometricProvider.notifier).refresh();
                    if (!await PinCodeService.askPinCode(canSwitch: true)) return;

                    // Pop back to the existing WalletsHome which has already rebuilt
                    // with new safe data via switchSafe(). The fade animation in
                    // _WalletsHomeContent handles the visual transition.
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'openThisSafe'.tr(),
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
