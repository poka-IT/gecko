import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/bottom_app_bar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/widgets/commons/text_markdown.dart';

/// Type de message pour le dialogue de confirmation
enum ConfirmationDialogType { info, warning, success, error, question }

/// Pops the confirmation dialog only when a route is still poppable.
///
/// Rapid double-taps (or Enter + tap) on the dialog buttons could otherwise
/// call Navigator.pop after the dialog route was already removed, which throws
/// "Bad state: No element" inside NavigatorState.pop (was AXIOM-TEAM-PA).
void _safePopDialog(BuildContext context, bool result) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) navigator.pop(result);
}

/// Extension pour obtenir l'icône correspondante au type de message
extension ConfirmationDialogTypeExtension on ConfirmationDialogType {
  IconData get icon => switch (this) {
    ConfirmationDialogType.info => Icons.info_rounded,
    ConfirmationDialogType.warning => Icons.warning_rounded,
    ConfirmationDialogType.success => Icons.task_alt_rounded,
    ConfirmationDialogType.error => Icons.cancel_rounded,
    ConfirmationDialogType.question => Icons.help_rounded,
  };

  Color iconColor(BuildContext context) => switch (this) {
    ConfirmationDialogType.info => context.colorScheme.primary,
    ConfirmationDialogType.warning => context.geckoColors.warning,
    ConfirmationDialogType.success => context.geckoColors.success,
    ConfirmationDialogType.error => context.geckoColors.danger,
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
  String? checkboxLabel,
}) async {
  // Check if context is still mounted before showing dialog
  if (!context.mounted) {
    log.w('Context not mounted when trying to show confirmation dialog');
    return false;
  }

  final Color iconColorToShow = customIconColor ?? type.iconColor(context);
  final Widget iconToShow = customIcon ?? Icon(type.icon, color: iconColorToShow, size: 32);
  final String dialogTitle = title ?? type.title;
  final String confirmTextToShow = confirmText ?? type.confirmText;

  // Get bottom app bar provider to hide it while dialog is shown
  // Use try-catch to handle cases where ProviderScope is not available
  ProviderContainer? container;
  try {
    container = ProviderScope.containerOf(context);
    // Hide bottom app bar when dialog is shown
    container.read(bottomAppBarProvider.notifier).setDialogVisible(true);
  } catch (e) {
    // ProviderScope not found - dialog will work without bottom app bar management
    log.w('ProviderScope not found in showConfirmationDialog context: $e');
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      var isChecked = checkboxLabel == null;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.enter): () {
                if (isChecked && !hideConfirmButton) {
                  _safePopDialog(context, true);
                }
              },
            },
            child: Focus(
              autofocus: true,
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                          decoration: BoxDecoration(
                            color: iconColorToShow.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
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
                              child: TextMarkDown(
                                cleanText,
                                style: scaledTextStyle(
                                  fontSize: 15,
                                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: WrapAlignment.center,
                              ),
                            );
                          }).toList(),
                        ),
                        if (checkboxLabel != null) ...[
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setDialogState(() => isChecked = !isChecked),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isChecked,
                                    onChanged: (v) => setDialogState(() => isChecked = v ?? false),
                                    activeColor: iconColorToShow,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(child: Text(checkboxLabel, style: scaledTextStyle(fontSize: 13))),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (type != ConfirmationDialogType.error && !hideCancelButton) ...[
                              Expanded(
                                child: TextButton(
                                  onPressed: () => _safePopDialog(context, false),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    cancelText ?? 'cancel'.tr(),
                                    style: scaledTextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                            ],
                            if (!hideConfirmButton) ...[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isChecked ? () => _safePopDialog(context, true) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: iconColorToShow,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: iconColorToShow.withValues(alpha: 0.3),
                                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
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
                ),
              ),
            ),
          );
        },
      );
    },
  );

  // Show bottom app bar again when dialog is closed
  try {
    container?.read(bottomAppBarProvider.notifier).setDialogVisible(false);
  } catch (e) {
    // Ignore errors when restoring bottom app bar state
    log.w('Error restoring bottom app bar state: $e');
  }

  return result ?? false;
}
