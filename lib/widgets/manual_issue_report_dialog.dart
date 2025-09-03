import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/sentry_service.dart';
import 'package:gecko/services/snackbar_service.dart';

/// Dialog for collecting user input and sending manual issue reports to Sentry
class ManualIssueReportDialog extends ConsumerStatefulWidget {
  const ManualIssueReportDialog({super.key});

  @override
  ConsumerState<ManualIssueReportDialog> createState() => _ManualIssueReportDialogState();
}

class _ManualIssueReportDialogState extends ConsumerState<ManualIssueReportDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    if (_isSending) return;

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      SnackbarService.showMessage(context, message: 'reportIssueHint'.tr(), duration: 3);
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await SentryService.sendManualIssueReport(userDescription: description, context: context, ref: ref);

      if (mounted) {
        Navigator.of(context).pop();
        SnackbarService.showMessage(context, message: 'reportIssueSent'.tr(), duration: 5);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        // Show specific error message for rate limiting
        final errorMessage = e.toString().contains('wait at least 1 minute')
            ? 'reportIssueRateLimit'.tr()
            : 'reportIssueError'.tr();

        SnackbarService.showMessage(context, message: errorMessage, duration: 4);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: context.colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'reportIssueDialogTitle'.tr(),
                        style: scaledTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: 'reportIssueHint'.tr(),
                          hintStyle: scaledTextStyle(
                            fontSize: 14,
                            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: context.colorScheme.primary),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface),
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                            child: Text(
                              'reportIssueCancel'.tr(),
                              style: scaledTextStyle(
                                fontSize: 14,
                                color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isSending ? null : _sendReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colorScheme.primary,
                              foregroundColor: context.colorScheme.onPrimary,
                            ),
                            child: _isSending
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.onPrimary),
                                    ),
                                  )
                                : Text(
                                    'reportIssueSend'.tr(),
                                    style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
