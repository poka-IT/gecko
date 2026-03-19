import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/g1v1_migration.provider.dart';

class StepIntro extends ConsumerWidget {
  const StepIntro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(scaleSize(16)),
            child: Column(
              children: [
                // Header icon
                Container(
                  width: scaleSize(isSmallScreen ? 60 : 80),
                  height: scaleSize(isSmallScreen ? 60 : 80),
                  decoration: BoxDecoration(color: context.colorScheme.surfaceContainer, shape: BoxShape.circle),
                  child: Center(
                    child: SvgPicture.asset('assets/cesium_bw2.svg', height: scaleSize(isSmallScreen ? 35 : 50)),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 20),

                // Title
                Text(
                  'migration_intro_title'.tr(),
                  style: scaledTextStyle(fontSize: isSmallScreen ? 20 : 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                ScaledSizedBox(height: 6),

                // Subtitle
                Text(
                  'migration_intro_subtitle'.tr(),
                  style: scaledTextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                ScaledSizedBox(height: isSmallScreen ? 24 : 32),

                // "What will happen?" section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'migration_intro_what_happens'.tr(),
                    style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 8 : 12),

                // Bullet points
                _buildBulletPoint(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  text: 'migration_intro_balance_transfer'.tr(),
                  isSmallScreen: isSmallScreen,
                ),
                ScaledSizedBox(height: isSmallScreen ? 6 : 10),
                _buildBulletPoint(
                  context,
                  icon: Icons.person_outline,
                  text: 'migration_intro_identity_transfer'.tr(),
                  isSmallScreen: isSmallScreen,
                ),

                ScaledSizedBox(height: isSmallScreen ? 16 : 24),

                // Warning card
                Card(
                  color: context.geckoColors.warningContainer,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.geckoColors.warning.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: context.geckoColors.warning, size: scaleSize(22)),
                        ScaledSizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'migration_intro_irreversible'.tr(),
                                style: scaledTextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.geckoColors.warningText,
                                ),
                              ),
                              ScaledSizedBox(height: 2),
                              Text(
                                'migration_intro_irreversible_detail'.tr(),
                                style: scaledTextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: context.geckoColors.warningText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Continue button pinned at bottom
        Padding(
          padding: EdgeInsets.all(scaleSize(16)),
          child: SizedBox(
            width: double.infinity,
            height: scaleSize(isSmallScreen ? 44 : 50),
            child: ElevatedButton(
              key: keyMigrationIntroContinue,
              onPressed: () {
                ref.read(g1v1MigrationFlowProvider.notifier).nextStep();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'migration_intro_continue'.tr(),
                style: scaledTextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: scaleSize(2)),
          child: Icon(Icons.check_circle, color: context.colorScheme.primary, size: scaleSize(isSmallScreen ? 18 : 20)),
        ),
        ScaledSizedBox(width: isSmallScreen ? 8 : 10),
        Padding(
          padding: EdgeInsets.only(top: scaleSize(2)),
          child: Icon(icon, color: context.colorScheme.onSurfaceVariant, size: scaleSize(isSmallScreen ? 18 : 20)),
        ),
        ScaledSizedBox(width: 8),
        Expanded(
          child: Text(text, style: scaledTextStyle(fontSize: isSmallScreen ? 13 : 15)),
        ),
      ],
    );
  }
}
