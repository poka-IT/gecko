import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/screens/home/desktop/desktop_shared.dart';
import 'package:gecko/screens/home/test_wallet_button.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/desktop/modals/onboarding_modal.dart';
import 'package:gecko/widgets/desktop/modals/restore_modal.dart';

class DesktopWelcomeSection extends StatelessWidget {
  const DesktopWelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final imageCache = ImageCacheService();
    final primary = context.colorScheme.primary;

    return buildDesktopGlassCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gecko mascot with bubble -- gecko sits right on top of the button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gecko + bubble row -- bubble aligned with gecko's mouth
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image(image: imageCache.getImageProvider('assets/home/gecko-bienvenue.png'), height: 140),
                  Flexible(
                    child: Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 112),
                        child: BubbleSpeakWithTail(text: "noLizard".tr(), fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              // Create wallet button -- flush against gecko's feet
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: keyOnboardingNewSafe,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Colors.white),
                  label: Text(
                    'createWallet'.tr(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.3),
                  ),
                  onPressed: () => showDesktopOnboardingModal(context),
                ),
              ),
              const SizedBox(height: 14),
              // Restore / Import wallet button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: keyRestoreSafe,
                  icon: Icon(Icons.key_rounded, size: 20, color: primary),
                  label: Text(
                    'restoreWallet'.tr(),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(width: 2.5, color: primary.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: primary.withValues(alpha: 0.04),
                  ),
                  onPressed: () => showDesktopRestoreModal(context),
                ),
              ),
              const TestWalletButton(),
            ],
          ),
        ],
      ),
    );
  }
}
