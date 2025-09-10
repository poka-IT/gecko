import 'package:durt2/durt2.dart' show SafeType;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/routes.dart';

/// Reusable widget for creating or importing a new safe
class CreateSafePlaceholder extends StatelessWidget {
  const CreateSafePlaceholder({
    super.key,
    required this.onSafeCreated,
    required this.onSafeImported,
    this.width,
    this.height,
    this.isSelected = false,
  });

  final VoidCallback onSafeCreated;
  final VoidCallback onSafeImported;
  final double? width;
  final double? height;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelected ? () => _showCreateImportDialog(context) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: width ?? scaleSize(isTall ? 95 : 75),
        height: height ?? scaleSize(isTall ? 95 : 75),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.colorScheme.primary.withValues(alpha: 0.05),
        ),
        child: CustomPaint(
          painter: DashedRectPainter(color: context.colorScheme.primary.withValues(alpha: 0.6), strokeWidth: 2, gap: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: scaleSize(isTall ? 32 : 24),
                color: context.colorScheme.primary.withValues(alpha: 0.8),
              ),
              ScaledSizedBox(height: 4),
              Text(
                '+',
                style: scaledTextStyle(
                  fontSize: isTall ? 20 : 16,
                  color: context.colorScheme.primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to choose between create or import safe
  void _showCreateImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: Text(
            'addNewSafe'.tr(),
            style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 320, // Fixed width to give more space
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'chooseAction'.tr(),
                  style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                ScaledSizedBox(height: 20),
                // Use Column instead of Row for better spacing
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToCreateSafe(context);
                        },
                        icon: Icon(Icons.add, size: scaleSize(20)),
                        label: Text(
                          'createSafe'.tr(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorScheme.primary,
                          foregroundColor: context.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    ScaledSizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToImportSafe(context);
                        },
                        icon: Icon(Icons.download, size: scaleSize(20)),
                        label: Text(
                          'importSafe'.tr(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorScheme.surfaceContainer,
                          foregroundColor: context.colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Navigate to create new safe screen
  void _navigateToCreateSafe(BuildContext context) async {
    // Check if we only have legacy safes - if so, start from the beginning
    final container = ProviderScope.containerOf(context);
    final walletService = container.read(walletServiceProvider);
    final allSafes = walletService.safeBox.getAll();
    final nonLegacySafes = allSafes.where((safe) => safe.safeType != SafeType.legacy).toList();

    if (nonLegacySafes.isEmpty) {
      // Only legacy safes exist - start from the beginning (step 1)
      await Navigator.pushNamed(context, RouteNames.onboardingStepOne);
    } else {
      // Normal case - skip intro and go to step 5
      await Navigator.pushNamed(
        context,
        RouteNames.onboardingStepFive,
        arguments: OnboardingStepFiveArguments(skipIntro: true),
      );
    }

    // Callback after creation
    onSafeCreated();
  }

  /// Navigate to import safe screen
  void _navigateToImportSafe(BuildContext context) async {
    await Navigator.pushNamed(context, RouteNames.restoreSafe, arguments: RestoreSafeArguments(skipIntro: true));

    // Callback after import
    onSafeImported();
  }
}

/// Custom painter for dashed rectangle border
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dashLength = gap * 2;
    final gapLength = gap;

    // Draw dashed border manually for each side
    _drawDashedLine(
      canvas,
      paint,
      Offset(12, strokeWidth / 2),
      Offset(size.width - 12, strokeWidth / 2),
      dashLength,
      gapLength,
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(size.width - strokeWidth / 2, 12),
      Offset(size.width - strokeWidth / 2, size.height - 12),
      dashLength,
      gapLength,
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(size.width - 12, size.height - strokeWidth / 2),
      Offset(12, size.height - strokeWidth / 2),
      dashLength,
      gapLength,
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(strokeWidth / 2, size.height - 12),
      Offset(strokeWidth / 2, 12),
      dashLength,
      gapLength,
    );
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end, double dashLength, double gapLength) {
    final totalLength = (end - start).distance;
    final unitVector = (end - start) / totalLength;

    double currentDistance = 0;
    bool isDash = true;

    while (currentDistance < totalLength) {
      final segmentLength = isDash ? dashLength : gapLength;
      final segmentEnd = (currentDistance + segmentLength).clamp(0.0, totalLength);

      if (isDash) {
        final segmentStart = start + unitVector * currentDistance;
        final segmentEndPoint = start + unitVector * segmentEnd;
        canvas.drawLine(segmentStart, segmentEndPoint, paint);
      }

      currentDistance = segmentEnd;
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
