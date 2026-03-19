import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

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
      body: ResponsiveCenter(
        maxWidth: 500,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(scaleSize(20)),
          child: Column(
            children: [
              // Main recommended option - Recovery phrase
              _buildMainImportCard(context),

              ScaledSizedBox(height: 40),

              // Bottom info text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
                child: Text(
                  'importChoiceInfo'.tr(),
                  style: scaledTextStyle(fontSize: 13, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                  textAlign: TextAlign.center,
                ),
              ),

              if (enableLegacyLogin) ...[
                ScaledSizedBox(height: 30),

                // Divider with "or" text
                Row(
                  children: [
                    Expanded(child: Divider(color: context.colorScheme.onSurface.withValues(alpha: 0.2))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                      child: Text(
                        'or'.tr(),
                        style: scaledTextStyle(
                          fontSize: 12,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.colorScheme.onSurface.withValues(alpha: 0.2))),
                  ],
                ),

                ScaledSizedBox(height: 20),

                // Discrete legacy option - just a small text link
                _buildLegacyOption(context),
              ],

              ScaledSizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Main prominent card for recovery phrase import
  Widget _buildMainImportCard(BuildContext context) {
    final primaryColor = context.colorScheme.primary;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, RouteNames.restoreSafe),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(scaleSize(24)),
              child: Column(
                children: [
                  // Icon with background
                  Container(
                    width: scaleSize(70),
                    height: scaleSize(70),
                    decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.security, color: primaryColor, size: scaleSize(36)),
                  ),
                  ScaledSizedBox(height: 20),

                  // Title
                  Text(
                    'importMnemonic'.tr(),
                    style: scaledTextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  ScaledSizedBox(height: 8),

                  // Description
                  Text(
                    'importMnemonicDescription'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  ScaledSizedBox(height: 20),

                  // CTA Button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: scaleSize(14)),
                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'continue'.tr(),
                          style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        ScaledSizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: scaleSize(20)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recommended badge at bottom
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: scaleSize(10)),
              decoration: BoxDecoration(
                color: context.colorScheme.secondary.withValues(alpha: 0.4),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, color: primaryColor, size: scaleSize(16)),
                  ScaledSizedBox(width: 6),
                  Text(
                    'recommended'.tr(),
                    style: scaledTextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Discrete legacy option - small text link
  Widget _buildLegacyOption(BuildContext context) {
    return Column(
      children: [
        // Small Cesium icon
        Opacity(
          opacity: 0.5,
          child: SizedBox(
            width: scaleSize(24),
            height: scaleSize(24),
            child: SvgPicture.asset('assets/cesium_bw2.svg', semanticsLabel: 'Cesium', fit: BoxFit.contain),
          ),
        ),
        ScaledSizedBox(height: 8),

        // Small clickable text
        GestureDetector(
          onTap: () => _showLegacyWarningDialog(context),
          child: Text(
            'legacyImportLink'.tr(),
            style: scaledTextStyle(fontSize: 12, color: context.colorScheme.onSurface.withValues(alpha: 0.5)).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: context.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
        ScaledSizedBox(height: 4),
        Text(
          'notRecommended'.tr(),
          style: scaledTextStyle(
            fontSize: 10,
            color: context.geckoColors.warning.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Show warning dialog for legacy import
  void _showLegacyWarningDialog(BuildContext context) {
    showDialog(context: context, barrierDismissible: true, builder: (context) => const _LegacyWarningDialog());
  }
}

/// Dialog warning about legacy import with triple-click confirmation
class _LegacyWarningDialog extends StatefulWidget {
  const _LegacyWarningDialog();

  @override
  State<_LegacyWarningDialog> createState() => _LegacyWarningDialogState();
}

class _LegacyWarningDialogState extends State<_LegacyWarningDialog> {
  int _clicksRemaining = 3;
  bool _hasStartedClicking = false;

  void _handleIgnoreClick() {
    setState(() {
      _hasStartedClicking = true;
      _clicksRemaining--;
    });

    if (_clicksRemaining <= 0) {
      Navigator.pop(context);
      Navigator.pushNamed(context, RouteNames.legacyLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: AlertDialog(
          backgroundColor: context.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: context.geckoColors.warning, size: scaleSize(28)),
              ScaledSizedBox(width: 12),
              Expanded(
                child: Text(
                  'legacyWarningTitle'.tr(),
                  style: scaledTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(scaleSize(20), scaleSize(16), scaleSize(20), scaleSize(20)),
          insetPadding: EdgeInsets.symmetric(horizontal: scaleSize(24), vertical: scaleSize(24)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning message
                Container(
                  padding: EdgeInsets.all(scaleSize(14)),
                  decoration: BoxDecoration(
                    color: context.geckoColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.geckoColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'legacyWarningMessage'.tr(),
                    style: scaledTextStyle(
                      fontSize: 14,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ),

                ScaledSizedBox(height: 16),

                // Recommendation
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: context.colorScheme.primary, size: scaleSize(20)),
                    ScaledSizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'legacyRecommendation'.tr(),
                        style: scaledTextStyle(
                          fontSize: 13,
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                ScaledSizedBox(height: 20),

                // Main CTA - Create new safe
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      navigator.pop(); // Close the dialog
                      navigator.pushReplacementNamed(RouteNames.onboardingStepOne); // Replace with safe creation flow
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: scaleSize(14)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'legacyCreateNewSafe'.tr(),
                      style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),

                ScaledSizedBox(height: 16),

                // Ignore button with triple-click
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _handleIgnoreClick,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: scaleSize(16), vertical: scaleSize(10)),
                          decoration: BoxDecoration(
                            color: _hasStartedClicking
                                ? context.geckoColors.danger.withValues(alpha: 0.1)
                                : context.colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _hasStartedClicking
                                  ? context.geckoColors.danger.withValues(alpha: 0.3)
                                  : context.colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'legacyIgnoreRecommendation'.tr(),
                                style: scaledTextStyle(
                                  fontSize: 12,
                                  color: _hasStartedClicking
                                      ? context.geckoColors.danger.withValues(alpha: 0.8)
                                      : context.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              if (_hasStartedClicking) ...[
                                ScaledSizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: scaleSize(8), vertical: scaleSize(2)),
                                  decoration: BoxDecoration(
                                    color: context.geckoColors.danger.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$_clicksRemaining',
                                    style: scaledTextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: context.geckoColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_hasStartedClicking) ...[
                        ScaledSizedBox(height: 6),
                        Text(
                          'legacyClicksRemaining'.tr(args: [_clicksRemaining.toString()]),
                          style: scaledTextStyle(
                            fontSize: 10,
                            color: context.geckoColors.danger.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
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
