import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:durt2/durt2.dart' show SafeEntity, SafeType;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/create_safe_placeholder.dart';

class SafeCarousel extends StatelessWidget {
  const SafeCarousel({
    super.key,
    required this.allSafes,
    required this.currentSafeIndex,
    required this.carouselController,
    required this.onPageChanged,
    required this.onSafeCreated,
    required this.onSafeImported,
    this.showCreatePlaceholder = true,
    this.height = 210,
    this.isCompact = false,
  });

  final List<SafeEntity> allSafes;
  final int currentSafeIndex;
  final CarouselSliderController carouselController;
  final Function(int, CarouselPageChangedReason) onPageChanged;
  final VoidCallback onSafeCreated;
  final VoidCallback onSafeImported;
  final bool showCreatePlaceholder;
  final double height;
  final bool isCompact; // For unlocking_wallet compact mode

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      carouselController: carouselController,
      options: CarouselOptions(
        height: height,
        onPageChanged: onPageChanged,
        enableInfiniteScroll: false,
        initialPage: currentSafeIndex,
        enlargeCenterPage: true,
        viewportFraction: 0.45,
        enlargeFactor: isCompact ? 0.6 : 0.6,
      ),
      items: [
        // Existing safes
        ...allSafes.asMap().entries.map((entry) {
          final index = entry.key;
          final safe = entry.value;
          return Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  if (index != currentSafeIndex) {
                    carouselController.animateToPage(index);
                  }
                },
                child: isCompact
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: safe.imagePath == null
                            ? (safe.safeType == SafeType.legacy
                                  ? SvgPicture.asset(
                                      'assets/cesium_bw2.svg',
                                      width: scaleSize(95),
                                      fit: BoxFit.contain,
                                      semanticsLabel: 'Cesium',
                                    )
                                  : Image.asset(
                                      'assets/safes/${safe.number % 4}.png',
                                      width: scaleSize(95),
                                      fit: BoxFit.contain,
                                    ))
                            : Image.file(File(safe.imagePath!), width: scaleSize(127), fit: BoxFit.contain),
                      )
                    : Column(
                        children: <Widget>[
                          safe.imagePath == null
                              ? (safe.safeType == SafeType.legacy
                                    ? SvgPicture.asset('assets/cesium_bw2.svg', height: 150, semanticsLabel: 'Cesium')
                                    : Image.asset('assets/safes/${safe.number % 4}.png', height: 150))
                              : Image.file(File(safe.imagePath!), height: 150),
                          const SizedBox(height: 30),
                          Text(WalletNameService.displayName(safe.name), style: const TextStyle(fontSize: 20)),
                        ],
                      ),
              );
            },
          );
        }),
        // Placeholder for creating/importing new safe
        if (showCreatePlaceholder)
          Builder(
            builder: (BuildContext context) {
              final placeholderIndex = allSafes.length;
              final isSelected = currentSafeIndex == placeholderIndex;

              return GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    // First tap: select the placeholder
                    carouselController.animateToPage(placeholderIndex);
                  } else {
                    // Already selected: show create/import dialog immediately
                    // This is handled by CreateSafePlaceholder internally when isSelected=true
                  }
                },
                child: isCompact
                    ? CreateSafePlaceholder(
                        onSafeCreated: onSafeCreated,
                        onSafeImported: onSafeImported,
                        isSelected: isSelected,
                      )
                    : Column(
                        children: [
                          CreateSafePlaceholder(
                            width: 150,
                            height: 150,
                            onSafeCreated: onSafeCreated,
                            onSafeImported: onSafeImported,
                            isSelected: isSelected,
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'createOrImportSafe'.tr(),
                            style: const TextStyle(fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              );
            },
          ),
      ],
    );
  }
}
