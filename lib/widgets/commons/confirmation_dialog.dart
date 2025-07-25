import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/widgets/bottom_app_bar.dart';
import 'package:provider/provider.dart';

/// Type de message pour le dialogue de confirmation
enum ConfirmationDialogType { info, warning, success, error, question }

/// Extension pour obtenir l'icône correspondante au type de message
extension ConfirmationDialogTypeExtension on ConfirmationDialogType {
  IconData get icon => switch (this) {
    ConfirmationDialogType.info => Icons.info_rounded,
    ConfirmationDialogType.warning => Icons.warning_rounded,
    ConfirmationDialogType.success => Icons.task_alt_rounded,
    ConfirmationDialogType.error => Icons.cancel_rounded,
    ConfirmationDialogType.question => Icons.help_rounded,
  };

  Color get iconColor => switch (this) {
    ConfirmationDialogType.info => homeContext.colorScheme.primary,
    ConfirmationDialogType.warning => const Color(0xFFFF9800),
    ConfirmationDialogType.success => greenColor,
    ConfirmationDialogType.error => const Color(0xFFF44336),
    ConfirmationDialogType.question => const Color(0xFF673AB7),
  };

  String get title => switch (this) {
    ConfirmationDialogType.info => 'info'.tr(),
    ConfirmationDialogType.warning => 'warning'.tr(),
    ConfirmationDialogType.success => 'success'.tr(),
    ConfirmationDialogType.error => 'error'.tr(),
    ConfirmationDialogType.question => 'question'.tr(),
  };

  String get confirmText => switch (this) {
    ConfirmationDialogType.info => 'confirm'.tr(),
    ConfirmationDialogType.warning => 'confirm'.tr(),
    ConfirmationDialogType.success => 'confirm'.tr(),
    ConfirmationDialogType.error => 'close'.tr(),
    ConfirmationDialogType.question => 'confirm'.tr(),
  };
}

Future<bool> showConfirmationDialog({
  required BuildContext context,
  String? title,
  required String message,
  String? cancelText,
  String? confirmText,
  bool barrierDismissible = true,
  ConfirmationDialogType type = ConfirmationDialogType.info,
  Widget? customIcon,
  Color? customIconColor,
  bool hideCancelButton = false,
  bool hideConfirmButton = false,
}) async {
  final Color iconColorToShow = customIconColor ?? type.iconColor;
  final Widget iconToShow = customIcon ?? Icon(type.icon, color: iconColorToShow, size: 32);
  final String dialogTitle = title ?? type.title;
  final String confirmTextToShow = confirmText ?? type.confirmText;

  // Get bottom app bar provider to hide it while dialog is shown
  final bottomAppBarProvider = context.read<BottomAppBarProvider>();

  // Hide bottom app bar when dialog is shown
  bottomAppBarProvider.setDialogVisible(true);

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: iconColorToShow.withValues(alpha: 0.1), blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: iconColorToShow.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: iconToShow,
              ),
              SizedBox(height: 20),
              Text(
                dialogTitle,
                style: scaledTextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: message.split('\n\n').map((text) {
                  final bool isBold = text.startsWith('**') && text.endsWith('**');
                  final String cleanText = isBold ? text.substring(2, text.length - 2) : text;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      cleanText,
                      style: scaledTextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (type != ConfirmationDialogType.error && !hideCancelButton) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          cancelText ?? 'cancel'.tr(),
                          style: scaledTextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                  if (!hideConfirmButton) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconColorToShow,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          confirmTextToShow,
                          style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  // Show bottom app bar again when dialog is closed
  bottomAppBarProvider.setDialogVisible(false);

  return result ?? false;
}
