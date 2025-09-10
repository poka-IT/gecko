import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/globals.dart';

/// Screen allowing users to choose between importing a mnemonic or legacy Cesium wallet
class ImportChoiceScreen extends StatelessWidget {
  const ImportChoiceScreen({super.key});

  /// Flag to enable/disable legacy login option
  static const bool enableLegacyLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('importWallet'.tr()),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(scaleSize(20)),
        child: Column(
          children: [
            // Info card
            Container(
              padding: EdgeInsets.all(scaleSize(14)),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colorScheme.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: context.colorScheme.primary, size: scaleSize(20)),
                  ScaledSizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'importChoiceInfo'.tr(),
                      style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            ScaledSizedBox(height: 24),

            // Mnemonic import card (recommended)
            _buildImportCard(
              context: context,
              icon: Icons.security,
              iconColor: greenColor,
              backgroundColor: greenColor.withValues(alpha: 0.05),
              borderColor: greenColor.withValues(alpha: 0.2),
              title: 'importMnemonic'.tr(),
              subtitle: 'importMnemonicDescription'.tr(),
              badge: 'recommended'.tr(),
              badgeColor: greenColor,
              onTap: () => Navigator.pushNamed(context, RouteNames.restoreSafe),
            ),

            if (enableLegacyLogin) ...[
              ScaledSizedBox(height: 12),

              // Legacy import card (not recommended)
              _buildImportCard(
                context: context,
                iconWidget: SizedBox(
                  width: scaleSize(28),
                  height: scaleSize(28),
                  child: SvgPicture.asset('assets/cesium_bw2.svg', semanticsLabel: 'Cesium', fit: BoxFit.contain),
                ),
                backgroundColor: Colors.orange.withValues(alpha: 0.05),
                borderColor: Colors.orange.withValues(alpha: 0.3),
                title: 'importLegacyAccount'.tr(),
                subtitle: 'importLegacyDescription'.tr(),
                badge: 'notRecommended'.tr(),
                badgeColor: Colors.orange,
                onTap: () => Navigator.pushNamed(context, RouteNames.legacyLogin),
              ),
            ],

            ScaledSizedBox(height: 40),

            // Bottom warning area
            _buildBottomWarning(context),
            ScaledSizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImportCard({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    Color? iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            // Main content
            Padding(
              padding: EdgeInsets.all(scaleSize(16)),
              child: Row(
                children: [
                  if (icon != null)
                    Icon(icon, color: iconColor, size: scaleSize(28))
                  else if (iconWidget != null)
                    iconWidget,
                  ScaledSizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: scaledTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        ScaledSizedBox(height: 4),
                        Text(
                          subtitle,
                          style: scaledTextStyle(
                            fontSize: 13,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaledSizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: scaleSize(16),
                  ),
                ],
              ),
            ),
            // Badge at bottom
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  badge,
                  style: scaledTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badgeColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomWarning(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
      child: Text(
        'importChoiceBottomText'.tr(),
        style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
        textAlign: TextAlign.center,
      ),
    );
  }
}
